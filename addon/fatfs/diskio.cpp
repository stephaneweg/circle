/*-----------------------------------------------------------------------*/
/* Low level disk I/O module skeleton for FatFs     (C)ChaN, 2019        */
/* Implementation for Circle by R. Stange <rsta2@o2online.de>            */
/*-----------------------------------------------------------------------*/
/* If a working storage control module is available, it should be        */
/* attached to the FatFs via a glue function rather than modifying it.   */
/* This is an example of glue functions to attach various exsisting      */
/* storage control modules to the FatFs module with a defined API.       */
/*-----------------------------------------------------------------------*/

#include "ff.h"			/* Obtains integer types */
#include "diskio.h"		/* Declarations of disk functions */
#include <circle/device.h>
#include <circle/devicenameservice.h>
#include <circle/util.h>
#include <circle/types.h>
#include <assert.h>

#if FF_MIN_SS != FF_MAX_SS
	#error FF_MIN_SS != FF_MAX_SS is not supported!
#endif
#define SECTOR_SIZE		FF_MIN_SS

/*-----------------------------------------------------------------------*/
/* Static Data                                                           */
/*-----------------------------------------------------------------------*/

// (Onyx) the physical drives (FF_MULTI_PARTITION: the volumes SD, SD1..SD3 are partitions of
// emmc1, VolToPart below; the whole card is read as before, FatFs finding its partitions)
static const char *s_pVolumeName[FF_VOLUMES] =
{
	"emmc1",
	"umsd1",
	"umsd2",
	"umsd3",
	"ufd1",
	"nvme1"
};

// volume -> (physical drive, partition): SD = the first FAT volume of the card (as before),
// SD1..SD3 = MBR partitions 2..4; USBn = USB device n whole (its first FAT volume: a superfloppy or
// its only partition), USBnP1..USBnP4 = its MBR partitions 1..4 (a device with several: the kernel
// mounts one or the other, kernel/sys/volume.cpp); then one volume per other drive
PARTITION VolToPart[FF_VOLUMES] =
{
	{0, 0}, {0, 2}, {0, 3}, {0, 4},
	{1, 0}, {1, 1}, {1, 2}, {1, 3}, {1, 4},
	{2, 0}, {2, 1}, {2, 2}, {2, 3}, {2, 4},
	{3, 0}, {3, 1}, {3, 2}, {3, 3}, {3, 4},
	{4, 0}, {5, 0}
};

static CDevice *volume_device (BYTE pdrv)
{
	if (pdrv >= FF_VOLUMES || s_pVolumeName[pdrv] == 0) return 0;
	return CDeviceNameService::Get ()->GetDevice (s_pVolumeName[pdrv], TRUE);
}

static CDevice *s_pVolume[FF_VOLUMES] = {0};

/* (Onyx) the kernel's hook (kernel/sys/fslock.cpp): yields once the task has run 10 ms. Called
   after each transfer with a USB drive (pdrv != 0): its driver waits in a busy loop, and a long
   FatFs operation on a stick (a format, a big folder) kept the CPU for seconds. Between two
   transfers is a safe point: the volume lock is held, and a stick pulled out meanwhile only makes
   the next transfer fail (s_pVolume[] cleared by disk_removed). The SD card keeps its own hooks
   inside its driver. */
void OnyxDriverPoll (void) __attribute__ ((weak));

static inline void usb_poll (BYTE pdrv)
{
	if (pdrv != 0 && OnyxDriverPoll != 0)
	{
		OnyxDriverPoll ();
	}
}

/* (Onyx: one bounce buffer per volume -- the SD driver may yield in the middle of a
   transfer, so two volumes' transfers can now overlap; each volume has its own lock) */
static u8 *s_pBuffer[FF_VOLUMES] = {0};
static unsigned s_nBufferSize[FF_VOLUMES] = {0};

/*-----------------------------------------------------------------------*/
/* Onyx: a sector cache                                                  */
/*-----------------------------------------------------------------------*/
/* FatFs reads the FAT and the directories one sector at a time (through
/  its window), and each read is a whole SD command round trip: opening a
/  file deep in a big folder walked it sector by sector, every time. The
/  single-sector reads are kept here (direct-mapped, 2048 x 512 bytes);
/  every write goes to the device AND updates the cached copies (write-
/  through), so the cache never holds anything the card does not. The big
/  multi-sector reads of file data go straight to the device. */

#define DCACHE_SLOTS	2048			/* a power of two */

static u64 *s_pDCKey = 0;			/* ((sector << 4) | (drive + 1)), 0 = free */
static u8 *s_pDCData = 0;
static int s_bDCOn = 1;
static unsigned s_nDCHits = 0, s_nDCMisses = 0;

static inline unsigned dc_slot (BYTE pdrv, LBA_t sector)
{
	return (unsigned) ((sector ^ (sector >> 11) ^ ((LBA_t) pdrv << 7)) & (DCACHE_SLOTS - 1));
}

static inline u64 dc_key (BYTE pdrv, LBA_t sector)
{
	return ((u64) sector << 4) | (u64) (pdrv + 1);
}

static int dc_ready (void)
{
	if (!s_bDCOn)
	{
		return 0;
	}
	if (s_pDCKey == 0)
	{
		s_pDCKey = new u64[DCACHE_SLOTS];
		s_pDCData = new u8[DCACHE_SLOTS * SECTOR_SIZE];
		if (s_pDCKey == 0 || s_pDCData == 0)
		{
			s_bDCOn = 0;
			return 0;
		}
		for (unsigned i = 0; i < DCACHE_SLOTS; i++)
		{
			s_pDCKey[i] = 0;
		}
	}
	return 1;
}

static void dc_forget_drive (BYTE pdrv)		/* (mounted again, or removed) */
{
	if (s_pDCKey == 0)
	{
		return;
	}
	for (unsigned i = 0; i < DCACHE_SLOTS; i++)
	{
		if ((s_pDCKey[i] & 15) == (u64) (pdrv + 1))
		{
			s_pDCKey[i] = 0;
		}
	}
}

void disk_cache_enable (int bOn)
{
	s_bDCOn = bOn;
	if (!bOn && s_pDCKey != 0)
	{
		for (unsigned i = 0; i < DCACHE_SLOTS; i++)
		{
			s_pDCKey[i] = 0;
		}
	}
}

void disk_cache_stats (unsigned *pHits, unsigned *pMisses)
{
	*pHits = s_nDCHits;
	*pMisses = s_nDCMisses;
}



/*-----------------------------------------------------------------------*/
/* Callbacks                                                             */
/*-----------------------------------------------------------------------*/

static void disk_removed (
	CDevice *pDevice,	/* device removed */
	void *pContext
)
{
	*((CDevice **) pContext) = 0;

	for (BYTE pdrv = 0; pdrv < FF_VOLUMES; pdrv++)		/* (Onyx) its cached sectors */
	{
		if ((CDevice **) pContext == &s_pVolume[pdrv])
		{
			dc_forget_drive (pdrv);
		}
	}
}



/*-----------------------------------------------------------------------*/
/* Get Drive Status                                                      */
/*-----------------------------------------------------------------------*/

DSTATUS disk_status (
	BYTE pdrv		/* Physical drive nmuber to identify the drive */
)
{
	if (   pdrv < FF_VOLUMES
	    && s_pVolume[pdrv] != 0)
	{
		return 0;
	}

	return STA_NOINIT;
}



/*-----------------------------------------------------------------------*/
/* Inidialize a Drive                                                    */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (
	BYTE pdrv				/* Physical drive nmuber to identify the drive */
)
{
	if (pdrv >= FF_VOLUMES)
	{
		return STA_NOINIT;
	}

	if (s_pVolume[pdrv] != 0 && s_pVolume[pdrv] == volume_device (pdrv))
	{
		return 0;				/* (Onyx) already: another partition of the drive */
	}
	dc_forget_drive (pdrv);				/* (Onyx) maybe another medium */
	s_pVolume[pdrv] = volume_device (pdrv);
	if (s_pVolume[pdrv] != 0)
	{
		s_pVolume[pdrv]->RegisterRemovedHandler (disk_removed, &s_pVolume[pdrv]);

		return 0;
	}

	return STA_NOINIT;
}



/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */
/*-----------------------------------------------------------------------*/

DRESULT disk_read (
	BYTE pdrv,		/* Physical drive nmuber to identify the drive */
	BYTE *buff,		/* Data buffer to store read data */
	LBA_t sector,	/* Start sector in LBA */
	UINT count		/* Number of sectors to read */
)
{
	if (pdrv >= FF_VOLUMES)
	{
		return RES_PARERR;
	}

	CDevice *pDevice = s_pVolume[pdrv];
	if (pDevice == 0)
	{
		return RES_NOTRDY;
	}

	/* Ensure that the transfer buffer is word aligned */
	BYTE *pBuffer = buff;
	unsigned nSize = count * SECTOR_SIZE;
	if (((uintptr) pBuffer & 3) != 0)
	{
		if (s_nBufferSize[pdrv] < nSize)
		{
			delete [] s_pBuffer[pdrv];

			s_nBufferSize[pdrv] = nSize;

			s_pBuffer[pdrv] = new u8[s_nBufferSize[pdrv]];
			assert (s_pBuffer[pdrv] != 0);
		}

		pBuffer = s_pBuffer[pdrv];
	}

	/* (Onyx) a single sector: from the cache if it is there */
	unsigned nSlot = 0;
	int bCache = count == 1 && dc_ready ();
	if (bCache)
	{
		nSlot = dc_slot (pdrv, sector);
		if (s_pDCKey[nSlot] == dc_key (pdrv, sector))
		{
			memcpy (buff, s_pDCData + nSlot * SECTOR_SIZE, SECTOR_SIZE);
			s_nDCHits++;

			return RES_OK;
		}
		s_nDCMisses++;
	}

	QWORD offset = sector;
	offset *= SECTOR_SIZE;
	pDevice->Seek (offset);

	if (pDevice->Read (pBuffer, nSize) < 0)
	{
		usb_poll (pdrv);
		return RES_ERROR;
	}

	if (pBuffer != buff)
	{
		memcpy (buff, pBuffer, nSize);
	}

	if (bCache)
	{
		memcpy (s_pDCData + nSlot * SECTOR_SIZE, buff, SECTOR_SIZE);
		s_pDCKey[nSlot] = dc_key (pdrv, sector);
	}

	usb_poll (pdrv);			/* (last: the bounce buffer and the cache are done with) */
	return RES_OK;
}



/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */
/*-----------------------------------------------------------------------*/

#if FF_FS_READONLY == 0

DRESULT disk_write (
	BYTE pdrv,			/* Physical drive nmuber to identify the drive */
	const BYTE *buff,	/* Data to be written */
	LBA_t sector,		/* Start sector in LBA */
	UINT count			/* Number of sectors to write */
)
{
	if (pdrv >= FF_VOLUMES)
	{
		return RES_PARERR;
	}

	CDevice *pDevice = s_pVolume[pdrv];
	if (pDevice == 0)
	{
		return RES_NOTRDY;
	}

	/* Ensure that the transfer buffer is word aligned */
	const BYTE *pBuffer = buff;
	unsigned nSize = count * SECTOR_SIZE;
	if (((uintptr) pBuffer & 3) != 0)
	{
		if (s_nBufferSize[pdrv] < nSize)
		{
			delete [] s_pBuffer[pdrv];

			s_nBufferSize[pdrv] = nSize;

			s_pBuffer[pdrv] = new u8[s_nBufferSize[pdrv]];
			assert (s_pBuffer[pdrv] != 0);
		}

		memcpy (s_pBuffer[pdrv], buff, nSize);

		pBuffer = s_pBuffer[pdrv];
	}

	QWORD offset = sector;
	offset *= SECTOR_SIZE;
	pDevice->Seek (offset);

	int nResult = pDevice->Write (pBuffer, nSize);

	/* (Onyx) write-through: the cached copies of these sectors follow the card (or are
	   dropped if the write failed: what the card holds is unknown then) */
	if (s_pDCKey != 0)
	{
		for (UINT i = 0; i < count; i++)
		{
			unsigned nSlot = dc_slot (pdrv, sector + i);
			if (s_pDCKey[nSlot] != dc_key (pdrv, sector + i))
			{
				continue;
			}
			if (nResult < 0)
			{
				s_pDCKey[nSlot] = 0;
			}
			else
			{
				memcpy (s_pDCData + nSlot * SECTOR_SIZE, buff + i * SECTOR_SIZE, SECTOR_SIZE);
			}
		}
	}

	usb_poll (pdrv);			/* (last: the cache follows the device already) */

	if (nResult < 0)
	{
		return RES_ERROR;
	}

	return RES_OK;
}

#endif


/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */
/*-----------------------------------------------------------------------*/

DRESULT disk_ioctl (
	BYTE pdrv,		/* Physical drive nmuber (0..) */
	BYTE cmd,		/* Control code */
	void *buff		/* Buffer to send/receive control data */
)
{
	switch (cmd)
	{
	case GET_SECTOR_COUNT:
		{
			if (pdrv >= FF_VOLUMES)
			{
				return RES_PARERR;
			}

			CDevice *pDevice =
				volume_device (pdrv);
			if (pDevice != 0)
			{
				u64 ullSize = pDevice->GetSize ();
				if (ullSize == (u64) -1)
				{
					return RES_PARERR;
				}

				*(LBA_t *) buff = (LBA_t) (ullSize / SECTOR_SIZE);
			}
			else
			{
				return RES_NOTRDY;
			}
		}
		return RES_OK;

	case CTRL_SYNC:
		{
			if (pdrv >= FF_VOLUMES)
			{
				return RES_PARERR;
			}

			CDevice *pDevice =
				volume_device (pdrv);
			if (pDevice != 0)
			{
				/* This fails, if unsupported, so ignore eventual errors. */
				pDevice->IOCtl (DEVICE_IOCTL_SYNC, 0);
			}
			else
			{
				return RES_NOTRDY;
			}
		}
		return RES_OK;

	case GET_SECTOR_SIZE:
		assert (buff != 0);
		*(WORD *) buff = SECTOR_SIZE;
		return RES_OK;

	case CTRL_EJECT:
		if (pdrv >= FF_VOLUMES)
		{
			return RES_PARERR;
		}

		if (s_pVolume[pdrv] == 0)
		{
			s_pVolume[pdrv] = volume_device (pdrv);
			if (s_pVolume[pdrv] == 0)
			{
				return RES_NOTRDY;
			}
		}

		if (!s_pVolume[pdrv]->RemoveDevice ())
		{
			return RES_ERROR;
		}

		s_pVolume[pdrv] = 0;

		return RES_OK;
	}

	return RES_PARERR;
}

