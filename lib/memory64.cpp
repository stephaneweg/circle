//
// memory64.cpp
//
// Circle - A C++ bare metal environment for Raspberry Pi
// Copyright (C) 2014-2024  R. Stange <rsta2@o2online.de>
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
#include <circle/memory.h>
#include <circle/bcmpropertytags.h>
#include <circle/machineinfo.h>
#include <circle/devicetreeblob.h>		// Onyx: read /memory ranges to reclaim RAM >=4GB
#include <circle/alloc.h>
#include <circle/spinlock.h>
#include <circle/synchronize.h>
#include <circle/sysconfig.h>
#include <assert.h>

CMemorySystem *CMemorySystem::s_pThis = 0;

CMemorySystem::CMemorySystem (boolean bEnableMMU)
:	m_bEnableMMU (bEnableMMU),
	m_nMemSize (0),
	m_nMemSizeHigh (0),
#ifdef KASAN_SUPPORTED
	m_nShadowMemSize (0),
#endif
	m_HeapLow ("heaplow"),
#if RASPPI >= 4
	m_HeapHigh ("heaphigh"),
	m_nHighSeg (0),
	m_nMemSizeHigh4G (0),
	m_nHighZoneTotal (0),
#endif
	m_pTranslationTable (0)
{
	if (s_pThis != 0)	// ignore second instance
	{
		return;
	}
	s_pThis = this;

	CBcmPropertyTags Tags (TRUE);
	TPropertyTagMemory TagMemory;
	if (!Tags.GetTag (PROPTAG_GET_ARM_MEMORY, &TagMemory, sizeof TagMemory))
	{
		TagMemory.nBaseAddress = 0;
		TagMemory.nSize = ARM_MEM_SIZE;
	}

	assert (TagMemory.nBaseAddress == 0);
	m_nMemSize = TagMemory.nSize;

#ifndef KASAN_SUPPORTED
	uintptr ulHeapMemStart = MEM_HEAP_START;
#else
	unsigned nRAMSize = CMachineInfo::GetRAMSizeEarly ();
	if (nRAMSize > 4096)		// do not occupy more than 512 MB for shadow memory
	{
		nRAMSize = 4096;
	}
	m_nShadowMemSize = nRAMSize * MEGABYTE / 8;

	assert (MEM_SHADOW_START >= MEM_COHERENT_REGION + COHERENT_REGION_SIZE);
	uintptr ulHeapMemStart = MEM_SHADOW_START + m_nShadowMemSize;
#endif

	size_t nBlockReserve = m_nMemSize - ulHeapMemStart - PAGE_RESERVE;
	m_HeapLow.Setup (ulHeapMemStart, nBlockReserve, 0x40000);

	m_Pager.Setup (ulHeapMemStart + nBlockReserve, PAGE_RESERVE);

	if (m_bEnableMMU)
	{
		m_pTranslationTable = new CTranslationTable (m_nMemSize);
		assert (m_pTranslationTable != 0);

		EnableMMU ();

		InstructionSyncBarrier ();
	}
}

CMemorySystem::~CMemorySystem (void)
{
	Destructor ();
}

void CMemorySystem::Destructor (void)
{
	if (s_pThis != this)
	{
		return;
	}
	s_pThis = 0;

	if (m_bEnableMMU)
	{
		// disable MMU and data cache
		u64 nSCTLR_EL1;
		asm volatile ("mrs %0, sctlr_el1" : "=r" (nSCTLR_EL1));
		nSCTLR_EL1 &= ~(SCTLR_EL1_M | SCTLR_EL1_C);
		asm volatile ("msr sctlr_el1, %0" : : "r" (nSCTLR_EL1) : "memory");
		DataSyncBarrier ();
		InstructionSyncBarrier ();

		CleanDataCache ();
		InvalidateDataCache ();

		// invalidate TLB (if MMU is re-enabled later)
		asm volatile ("tlbi vmalle1" : : : "memory");
		DataSyncBarrier ();
		InstructionSyncBarrier ();
	}
}

#if RASPPI >= 4

void CMemorySystem::SetupHighMem (void)
{
#ifndef KASAN_SUPPORTED
	unsigned nRAMSize = CMachineInfo::Get ()->GetRAMSize ();
#else
	unsigned nRAMSize = CMachineInfo::GetRAMSizeEarly ();
	if (nRAMSize > 4096)
	{
		nRAMSize = 4096;
	}
#endif
	if (nRAMSize > 1024)
	{
		u64 nHighSize = (nRAMSize - 1024) * MEGABYTE;
		if (nHighSize > MEM_HIGHMEM_END+1 - MEM_HIGHMEM_START)
		{
			nHighSize = MEM_HIGHMEM_END+1 - MEM_HIGHMEM_START;
		}

		m_nMemSizeHigh = (size_t) nHighSize;

		// Onyx: the high region (1-3GB) backs the HIGH-zone page allocator (app
		// frames/heaps), NOT the bucket heap. m_HeapHigh is left un-Setup; new/malloc
		// stay in the low heap (DMA-safe), app pages draw from the high pager via
		// palloc_high(). This is identity-mapped Normal memory (see translationtable64),
		// so the kernel reaches these frames by identity for zeroing/ELF-load.
		AddHighSegment (MEM_HIGHMEM_START, (size_t) nHighSize);	// high segment 0
	}

	// Onyx: reclaim every RAM byte above seg0 that the boot table left unused -- the
	// [3GB, ~3.94GB) low-RAM top (mapped DEVICE by the ctor) AND any chunk relocated above
	// 4GB (which the ctor skips). Reads the real extents from the firmware device tree, so
	// it stops at real RAM (never the MMIO window). Safe no-op if the DTB is absent.
	SetupHighMemAbove4G ();
}

// Onyx: register a contiguous high-RAM segment with its own page allocator.
void CMemorySystem::AddHighSegment (uintptr nBase, size_t nSize)
{
	if (m_nHighSeg >= CMEM_HIGH_SEG_MAX || nSize == 0)
	{
		return;
	}

	m_HighBase[m_nHighSeg] = nBase;
	m_HighEnd[m_nHighSeg]  = nBase + nSize;
	m_PagerHigh[m_nHighSeg].Setup (nBase, nSize);
	m_nHighSeg++;
	m_nHighZoneTotal += nSize;		// running total across all high segments
}

// Onyx: map and register RAM above the [1GB,3GB] seg0. (A) Precise path: read the device
// tree /memory node -- recovers the [3GB,~3.94GB) low-RAM top (DEVICE->NORMAL) AND the
// relocated chunk >4GB, bounded to firmware-declared RAM (never the MMIO window). (B) If the
// DTB is unavailable (not captured) or yields nothing >4GB, fall back to GetRAMSize and map
// [4GB, totalRAM) -- provably real RAM (see below). Safe no-op on <=4GB boards.
u64 g_ulOnyxCrashArea = 0;

void CMemorySystem::SetupHighMemAbove4G (void)
{
	if (m_pTranslationTable == 0)			// MMU disabled -> cannot add mappings
	{
		return;
	}

	CMachineInfo *pInfo = CMachineInfo::Get ();
	if (pInfo == 0)
	{
		return;
	}

	// (A) Precise reclaim from the device tree, when the firmware passed one. Any failure
	// here (no DTB, node/reg/cells unexpected) just yields nEntries==0 and falls through to
	// the GetRAMSize fallback below -- never an early return.
	const CDeviceTreeBlob *pDTB = pInfo->GetDTB ();
	const TDeviceTreeNode *pMem = pDTB != 0 ? pDTB->FindNode ("/memory@0") : 0;
	if (pDTB != 0 && pMem == 0)
	{
		pMem = pDTB->FindNode ("/memory");
	}
	// Pi4 root uses #address-cells=2, #size-cells=2 -> 4 words (16 bytes) per entry.
	const TDeviceTreeProperty *pReg = pMem != 0 ? pDTB->FindProperty (pMem, "reg") : 0;
	size_t nLen = pReg != 0 ? pDTB->GetPropertyValueLength (pReg) : 0;
	unsigned nEntries = (nLen != 0 && (nLen % 16) == 0) ? (unsigned) (nLen / 16) : 0;

	for (unsigned i = 0; i < nEntries; i++)
	{
		u64 nBase = ((u64) pDTB->GetPropertyValueWord (pReg, i*4 + 0) << 32)
			  |  (u64) pDTB->GetPropertyValueWord (pReg, i*4 + 1);
		u64 nSize = ((u64) pDTB->GetPropertyValueWord (pReg, i*4 + 2) << 32)
			  |  (u64) pDTB->GetPropertyValueWord (pReg, i*4 + 3);

		// Take the portion of this RAM segment at/above 3GB (= where seg0 ends). Below
		// that is already handled (low region + the [1GB,3GB] seg0). The >=3GB part is
		// the [3GB, RAMtop) low-RAM top (DEVICE->NORMAL) and/or a relocated chunk >4GB.
		// `end` comes from the firmware, so it stops at real RAM -- never the MMIO window.
		const u64 kReclaimStart = (u64) MEM_HIGHMEM_END + 1;		// 0xC0000000 = 3GB
		if (nBase < kReclaimStart)
		{
			if (nBase + nSize <= kReclaimStart)
			{
				continue;		// entirely below 3GB
			}
			nSize -= (size_t) (kReclaimStart - nBase);
			nBase  = kReclaimStart;
		}

		// Validate before mapping (a bad range could map MMIO as RAM -> hang).
		if (nSize == 0)					continue;
		if ((nBase & 0xFFFFULL) != 0 || (nSize & 0xFFFFULL) != 0)	continue;	// 64KB
		if (nBase + nSize <= nBase)			continue;	// overflow
		if (nBase + nSize > 0x1000000000ULL)		continue;	// >64GB -> bogus

		if (!m_pTranslationTable->MapRangeNormal (nBase, nSize))
		{
			continue;
		}
		// Onyx: the top 64 KB of the first segment above 3 GB stay out of the heap: the
		// kernel's crash record (kern/crashlog.h), read back after a watchdog reboot.
		if (nSize >= 0x100000 && g_ulOnyxCrashArea == 0)
		{
			nSize -= ONYX_CRASH_AREA_SIZE;
			g_ulOnyxCrashArea = nBase + nSize;
		}
		AddHighSegment ((uintptr) nBase, (size_t) nSize);
		if (nBase >= 0x100000000ULL)			// count only the genuine >4GB part
		{
			m_nMemSizeHigh4G += (size_t) nSize;
		}
	}

	// (B) Fallback: the DTB was absent (or gave no RAM above 4GB), but the firmware reports
	// a board larger than 4GB. Trust GetRAMSize and map [4GB, totalRAM). That range is
	// provably a SUBSET of the relocated high chunk (chunk = total - lowRAM, and lowRAM <=
	// 4GB because the <4GB MMIO window caps it), so every byte is real RAM -- no MMIO, no
	// layout assumption. Recovers the big >4GB chunk even when the device tree isn't captured.
	if (m_nMemSizeHigh4G == 0)
	{
		unsigned nRAMMB = pInfo->GetRAMSize ();			// firmware-reported, e.g. 8192
		if (nRAMMB > 4096)
		{
			u64 nBase = 0x100000000ULL;			// 4GB
			u64 nSize = (((u64) nRAMMB) * MEGABYTE) - nBase;	// [4GB, totalRAM)
			nSize &= ~0xFFFFULL;				// 64KB-align (defensive)
			if (nSize != 0 && m_pTranslationTable->MapRangeNormal (nBase, nSize))
			{
				if (g_ulOnyxCrashArea == 0 && nSize >= 0x100000)	// (Onyx: the crash area)
				{
					nSize -= ONYX_CRASH_AREA_SIZE;
					g_ulOnyxCrashArea = nBase + nSize;
				}
				AddHighSegment ((uintptr) nBase, (size_t) nSize);
				m_nMemSizeHigh4G += (size_t) nSize;
			}
		}
	}
}

#endif

#ifdef ARM_ALLOW_MULTI_CORE

void CMemorySystem::InitializeSecondary (void)
{
	assert (s_pThis != 0);
	assert (s_pThis->m_bEnableMMU);		// required to use spin locks

	s_pThis->EnableMMU ();

	InstructionSyncBarrier ();
}

#endif

size_t CMemorySystem::GetMemSize (void) const
{
	assert (s_pThis != 0);
	return s_pThis->m_nMemSize + s_pThis->m_nMemSizeHigh;
}

CMemorySystem *CMemorySystem::Get (void)
{
	assert (s_pThis != 0);
	return s_pThis;
}

void CMemorySystem::EnableMMU (void)
{
	assert (m_bEnableMMU);

	u64 nMAIR_EL1 =   0xFF << ATTRINDX_NORMAL*8	// inner/outer write-back non-transient, allocating
	                | 0x04 << ATTRINDX_DEVICE*8	// Device-nGnRE
	                | 0x00 << ATTRINDX_COHERENT*8;	// Device-nGnRnE
	asm volatile ("msr mair_el1, %0" : : "r" (nMAIR_EL1));

	assert (m_pTranslationTable != 0);
	asm volatile ("msr ttbr0_el1, %0" : : "r" (m_pTranslationTable->GetBaseAddress ()));

	u64 nTCR_EL1;
	asm volatile ("mrs %0, tcr_el1" : "=r" (nTCR_EL1));
	nTCR_EL1 &= ~(  TCR_EL1_IPS__MASK
		      | TCR_EL1_A1
		      | TCR_EL1_TG0__MASK
		      | TCR_EL1_SH0__MASK
		      | TCR_EL1_ORGN0__MASK
		      | TCR_EL1_IRGN0__MASK
		      | TCR_EL1_EPD0
		      | TCR_EL1_T0SZ__MASK);
	nTCR_EL1 |=   TCR_EL1_EPD1
		    | TCR_EL1_TG0_64KB	    << TCR_EL1_TG0__SHIFT
		    | TCR_EL1_SH0_INNER     << TCR_EL1_SH0__SHIFT
		    | TCR_EL1_ORGN0_WR_BACK_ALLOCATE << TCR_EL1_ORGN0__SHIFT
		    | TCR_EL1_IRGN0_WR_BACK_ALLOCATE << TCR_EL1_IRGN0__SHIFT
#if RASPPI == 3
		    | TCR_EL1_IPS_4GB	    << TCR_EL1_IPS__SHIFT
		    | TCR_EL1_T0SZ_4GB	    << TCR_EL1_T0SZ__SHIFT;
#elif RASPPI == 4
		    | TCR_EL1_IPS_64GB	    << TCR_EL1_IPS__SHIFT
		    | TCR_EL1_T0SZ_64GB	    << TCR_EL1_T0SZ__SHIFT;
#else
		    | TCR_EL1_IPS_1TB	    << TCR_EL1_IPS__SHIFT
		    | TCR_EL1_T0SZ_128GB    << TCR_EL1_T0SZ__SHIFT;
#endif
	asm volatile ("msr tcr_el1, %0" : : "r" (nTCR_EL1));

	u64 nSCTLR_EL1;
	asm volatile ("mrs %0, sctlr_el1" : "=r" (nSCTLR_EL1));
	nSCTLR_EL1 &= ~(  SCTLR_EL1_WXN
			| SCTLR_EL1_A);
	nSCTLR_EL1 |=   SCTLR_EL1_I
		      | SCTLR_EL1_C
		      | SCTLR_EL1_M;
	asm volatile ("msr sctlr_el1, %0" : : "r" (nSCTLR_EL1) : "memory");
}

uintptr CMemorySystem::GetCoherentPage (unsigned nSlot)
{
	u64 nPageAddress = MEM_COHERENT_REGION;

	nPageAddress += nSlot * PAGE_SIZE;

	return nPageAddress;
}
