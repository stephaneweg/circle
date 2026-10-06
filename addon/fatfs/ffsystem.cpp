/*------------------------------------------------------------------------*/
/* Sample code of OS dependent controls for FatFs                         */
/* (C)ChaN, 2014                                                          */
/* Implementation for Circle by R. Stange <rsta2@o2online.de>             */
/*------------------------------------------------------------------------*/


#include "ff.h"
#include <circle/genericlock.h>
#include <circle/alloc.h>
#include <circle/timer.h>
#include <assert.h>


#if FF_FS_REENTRANT	/* Mutal exclusion */
/*------------------------------------------------------------------------*/
/* Definitions of Mutex                                                   */
/*------------------------------------------------------------------------*/

static CGenericLock *s_pMutex[FF_VOLUMES + 1] = {0};

// Onyx: the kernel may supply the volume lock -- a sleeping lock whose waiters yield --
// by defining these (weak references: absent = the CGenericLock above). With it, the SD
// driver can yield while it waits for the card, the lock held, without deadlocking a
// second task that calls FatFs meanwhile.
void OnyxFsLockTake (int vol) __attribute__ ((weak));
void OnyxFsLockGive (int vol) __attribute__ ((weak));


/*------------------------------------------------------------------------*/
/* Create a Mutex                                                         */
/*------------------------------------------------------------------------*/
/* This function is called in f_mount function to create a new mutex
/  or semaphore for the volume. When a 0 is returned, the f_mount function
/  fails with FR_INT_ERR.
*/

int ff_mutex_create (	/* Returns 1:Function succeeded or 0:Could not create the mutex */
	int vol		/* Mutex ID: Volume mutex (0 to FF_VOLUMES - 1) or system mutex (FF_VOLUMES) */
)
{
	assert (vol <= FF_VOLUMES);
	if (s_pMutex[vol] != 0)		/* (Onyx) kept across an unmount when the kernel has its lock */
	{
		return 1;
	}

	s_pMutex[vol] = new CGenericLock ();
	assert (s_pMutex[vol] != 0);

	return 1;
}


/*------------------------------------------------------------------------*/
/* Delete a Mutex                                                         */
/*------------------------------------------------------------------------*/
/* This function is called in f_mount function to delete a mutex or
/  semaphore of the volume created with ff_mutex_create function.
*/

void ff_mutex_delete (
	int vol		/* Mutex ID: Volume mutex (0 to FF_VOLUMES - 1) or system mutex (FF_VOLUMES) */
)
{
	assert (vol <= FF_VOLUMES);
	assert (s_pMutex[vol] != 0);

	/* (Onyx) with the kernel's lock, the CGenericLock is never used: kept, so that a task
	   that took the volume lock before an unmount (a USB stick pulled out) can still give it */
	if (OnyxFsLockTake != 0)
	{
		return;
	}


	delete s_pMutex[vol];
	s_pMutex[vol] = 0;
}


/*------------------------------------------------------------------------*/
/* Request a Grant to Access the Volume                                   */
/*------------------------------------------------------------------------*/
/* This function is called on enter file functions to lock the volume.
/  When a 0 is returned, the file function fails with FR_TIMEOUT.
*/

int ff_mutex_take (	/* Returns 1:Succeeded or 0:Timeout */
	int vol		/* Mutex ID: Volume mutex (0 to FF_VOLUMES - 1) or system mutex (FF_VOLUMES) */
)
{
	assert (vol <= FF_VOLUMES);

	if (OnyxFsLockTake != 0)
	{
		OnyxFsLockTake (vol);

		return 1;
	}

	assert (s_pMutex[vol] != 0);
	s_pMutex[vol]->Acquire ();

	return 1;
}


/*------------------------------------------------------------------------*/
/* Release a Grant to Access the Volume                                   */
/*------------------------------------------------------------------------*/
/* This function is called on leave file functions to unlock the volume.
*/

void ff_mutex_give (
	int vol		/* Mutex ID: Volume mutex (0 to FF_VOLUMES - 1) or system mutex (FF_VOLUMES) */
)
{
	assert (vol <= FF_VOLUMES);

	if (OnyxFsLockGive != 0)
	{
		OnyxFsLockGive (vol);

		return;
	}

	assert (s_pMutex[vol] != 0);
	s_pMutex[vol]->Release ();
}

#endif	/* FF_FS_REENTRANT */




#if FF_USE_LFN == 3	/* LFN with a working buffer on the heap */
/*------------------------------------------------------------------------*/
/* Allocate a memory block                                                */
/*------------------------------------------------------------------------*/
/* If a NULL is returned, the file function fails with FR_NOT_ENOUGH_CORE.
*/

void* ff_memalloc (	/* Returns pointer to the allocated memory block */
	UINT msize		/* Number of bytes to allocate */
)
{
	return malloc(msize);	/* Allocate a new memory block with POSIX API */
}


/*------------------------------------------------------------------------*/
/* Free a memory block                                                    */
/*------------------------------------------------------------------------*/

void ff_memfree (
	void* mblock	/* Pointer to the memory block to free */
)
{
	free(mblock);	/* Discard the memory block with POSIX API */
}

#endif




#if !FF_FS_READONLY && !FF_FS_NORTC
/*------------------------------------------------------------------------*/
/* RTC function                                                           */
/*------------------------------------------------------------------------*/

DWORD get_fattime (void)
{
	unsigned nTime = CTimer::Get ()->GetLocalTime ();
	if (nTime == 0)
	{
		return 0;
	}

	unsigned nSecond = nTime % 60;
	nTime /= 60;
	unsigned nMinute = nTime % 60;
	nTime /= 60;
	unsigned nHour = nTime % 24;
	nTime /= 24;

	unsigned nYear = 1970;
	while (1)
	{
		unsigned nDaysOfYear = CTimer::IsLeapYear (nYear) ? 366 : 365;
		if (nTime < nDaysOfYear)
		{
			break;
		}

		nTime -= nDaysOfYear;
		nYear++;
	}

	if (nYear < 1980)
	{
		return 0;
	}

	unsigned nMonth = 0;
	while (1)
	{
		unsigned nDaysOfMonth = CTimer::GetDaysOfMonth (nMonth, nYear);
		if (nTime < nDaysOfMonth)
		{
			break;
		}

		nTime -= nDaysOfMonth;
		nMonth++;
	}

	unsigned nMonthDay = nTime + 1;

	unsigned nFATDate = (nYear-1980) << 9;
	nFATDate |= (nMonth+1) << 5;
	nFATDate |= nMonthDay;

	unsigned nFATTime = nHour << 11;
	nFATTime |= nMinute << 5;
	nFATTime |= nSecond / 2;

	return nFATDate << 16 | nFATTime;
}

#endif
