//
// memory.h
//
// Circle - A C++ bare metal environment for Raspberry Pi
// Copyright (C) 2014-2025  R. Stange <rsta2@gmx.net>
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
#ifndef _circle_memory_h
#define _circle_memory_h

#if AARCH == 32
	#include <circle/pagetable.h>
#else
	#include <circle/translationtable64.h>
#endif

#include <circle/heapallocator.h>
#include <circle/pageallocator.h>
#include <circle/sysconfig.h>
#include <circle/types.h>

class CMemorySystem
{
public:
	CMemorySystem (boolean bEnableMMU = TRUE);
	~CMemorySystem (void);

	void Destructor (void);		// explicit callable

#if RASPPI >= 4
	void SetupHighMem (void);
#endif

#ifdef ARM_ALLOW_MULTI_CORE
	void InitializeSecondary (void);
#endif

	size_t GetMemSize (void) const;

	static uintptr GetCoherentPage (unsigned nSlot);
#define COHERENT_SLOT_PROP_MAILBOX	0
#define COHERENT_SLOT_GPIO_VIRTBUF	1
#define COHERENT_SLOT_TOUCHBUF		2
#if RASPPI >= 5
#define COHERENT_SLOT_NVME		3
#endif

#define COHERENT_SLOT_MACB_START	4
#define COHERENT_SLOT_MACB_END		(4 + 256*1024 / PAGE_SIZE - 1)

#define COHERENT_SLOT_VCHIQ_START	(MEGABYTE / PAGE_SIZE / 2)
#define COHERENT_SLOT_VCHIQ_END		(MEGABYTE / PAGE_SIZE - 1)

#if RASPPI >= 4
#define COHERENT_SLOT_XHCI_START	(MEGABYTE / PAGE_SIZE)
#define COHERENT_SLOT_XHCI_END		(4*MEGABYTE / PAGE_SIZE - 1)
#endif

	static CMemorySystem *Get (void);

public:
	static void *HeapAllocate (size_t nSize, int nType)
#define HEAP_LOW	0		// memory below 1 GB
#define HEAP_HIGH	1		// memory above 1 GB
#define HEAP_ANY	2		// high memory (if available) or low memory (otherwise)
#define HEAP_DMA30	HEAP_LOW	// 30-bit DMA-able memory
	{
#if RASPPI >= 4
		void *pBlock;

		switch (nType)
		{
		case HEAP_LOW:	return s_pThis->m_HeapLow.Allocate (nSize);
		case HEAP_HIGH: return s_pThis->m_HeapHigh.Allocate (nSize);
		case HEAP_ANY:	return   (pBlock = s_pThis->m_HeapHigh.Allocate (nSize)) != 0
				       ? pBlock
				       : s_pThis->m_HeapLow.Allocate (nSize);
		default:	return 0;
		}
#else
		switch (nType)
		{
		case HEAP_LOW:
		case HEAP_ANY:	return s_pThis->m_HeapLow.Allocate (nSize);
		default:	return 0;
		}
#endif
	}

	static void *HeapReAllocate (void *pBlock, size_t nSize)	// pBlock may be 0
	{
#if RASPPI >= 4
		if ((uintptr) pBlock < MEM_HIGHMEM_START)
		{
			return s_pThis->m_HeapLow.ReAllocate (pBlock, nSize);
		}
		else
		{
			return s_pThis->m_HeapHigh.ReAllocate (pBlock, nSize);
		}
#else
		return s_pThis->m_HeapLow.ReAllocate (pBlock, nSize);
#endif
	}

	static void HeapFree (void *pBlock)
	{
#if RASPPI >= 4
		if ((uintptr) pBlock < MEM_HIGHMEM_START)
		{
			s_pThis->m_HeapLow.Free (pBlock);
		}
		else
		{
			s_pThis->m_HeapHigh.Free (pBlock);
		}
#else
		s_pThis->m_HeapLow.Free (pBlock);
#endif
	}

	size_t GetHeapFreeSpace (int nType) const
	{
#if RASPPI >= 4
		switch (nType)
		{
		case HEAP_LOW:	return s_pThis->m_HeapLow.GetFreeSpace ();
		case HEAP_HIGH: return s_pThis->m_HeapHigh.GetFreeSpace ();
		case HEAP_ANY:	return   s_pThis->m_HeapLow.GetFreeSpace ()
				       + s_pThis->m_HeapHigh.GetFreeSpace ();
		default:	return 0;
		}
#else
		switch (nType)
		{
		case HEAP_LOW:
		case HEAP_ANY:	return s_pThis->m_HeapLow.GetFreeSpace ();
		default:	return 0;
		}
#endif
	}

	static void *PageAllocate (void)	{ return s_pThis->m_Pager.Allocate (); }

	// Onyx: allocate a page from the HIGH zone (non-DMA). App frames/heaps go here so
	// they use the big high region instead of the small low pager. Tries each high
	// segment in turn; falls back to the low pager when there is no high memory (e.g.
	// 1GB board) or all high segments are exhausted.
	static void *PageAllocateHigh (void)
	{
#if RASPPI >= 4
		for (unsigned i = 0; i < s_pThis->m_nHighSeg; i++)
		{
			void *pPage = s_pThis->m_PagerHigh[i].Allocate ();
			if (pPage != 0) return pPage;
		}
#endif
		return s_pThis->m_Pager.Allocate ();
	}

	// Frees a page from ANY pager: routed by address (which high segment contains it).
	static void PageFree (void *pPage)
	{
#if RASPPI >= 4
		uintptr ulAddr = (uintptr) pPage;
		for (unsigned i = 0; i < s_pThis->m_nHighSeg; i++)
		{
			if (ulAddr >= s_pThis->m_HighBase[i] && ulAddr < s_pThis->m_HighEnd[i])
			{
				s_pThis->m_PagerHigh[i].Free (pPage);
				return;
			}
		}
#endif
		s_pThis->m_Pager.Free (pPage);
	}

	// Onyx: free space (bytes) of the page allocator region not yet handed out (freed
	// pages on its free list are reused but not counted here). Used by the memory
	// monitor / meminfo kapi. Header-only -> no libcircle rebuild.
	static size_t GetPagerFreeSpace (void)	{ return s_pThis->m_Pager.GetFreeSpace (); }
	// Onyx: + freed pages on the pager free list (reusable). Total pager free =
	// GetPagerFreeSpace() + GetPagerFreeListSpace().
	static size_t GetPagerFreeListSpace (void) { return s_pThis->m_Pager.GetFreeListSpace (); }

	// Onyx: same, for the HIGH-zone pagers (where app frames live), summed over all
	// high segments. 0 if no high mem.
	static size_t GetPagerHighFreeSpace (void)
	{
		size_t nSpace = 0;
#if RASPPI >= 4
		for (unsigned i = 0; i < s_pThis->m_nHighSeg; i++)
			nSpace += s_pThis->m_PagerHigh[i].GetFreeSpace ();
#endif
		return nSpace;
	}
	static size_t GetPagerHighFreeListSpace (void)
	{
		size_t nSpace = 0;
#if RASPPI >= 4
		for (unsigned i = 0; i < s_pThis->m_nHighSeg; i++)
			nSpace += s_pThis->m_PagerHigh[i].GetFreeListSpace ();
#endif
		return nSpace;
	}

	// Onyx: number of high-RAM segments, and bytes of RAM reclaimed above 4GB (for the
	// boot log -- SetupHighMem runs before the logger exists, so report it from Initialize).
	static unsigned GetHighSegCount (void)
	{
#if RASPPI >= 4
		return s_pThis->m_nHighSeg;
#else
		return 0;
#endif
	}
	static size_t GetHighMem4GSize (void)
	{
#if RASPPI >= 4
		return s_pThis->m_nMemSizeHigh4G;
#else
		return 0;
#endif
	}
	// Onyx: total bytes of the HIGH page zone (all segments) -- the app page pool size.
	static size_t GetHighZoneTotal (void)
	{
#if RASPPI >= 4
		return s_pThis->m_nHighZoneTotal;
#else
		return 0;
#endif
	}

	// Onyx: freed heap blocks on the bucket/large free lists (reusable). Add to
	// GetHeapFreeSpace(HEAP_ANY) for the true free heap.
	size_t GetHeapFreeListSpace (void) const
	{
#if RASPPI >= 4
		return s_pThis->m_HeapLow.GetFreeListSpace () + s_pThis->m_HeapHigh.GetFreeListSpace ();
#else
		return s_pThis->m_HeapLow.GetFreeListSpace ();
#endif
	}

	static void DumpStatus (void)
	{
#ifdef HEAP_DEBUG
		s_pThis->m_HeapLow.DumpStatus ();
#if RASPPI >= 4
		s_pThis->m_HeapHigh.DumpStatus ();
#endif
#endif

#ifdef PAGE_DEBUG
		s_pThis->m_Pager.DumpStatus ();
#endif
	}

	static size_t GetLowMemSize (void)	{ return s_pThis->m_nMemSize; }
	static size_t GetHighMemSize (void)	{ return s_pThis->m_nMemSizeHigh; }

#ifdef KASAN_SUPPORTED
	static size_t GetShadowMemSize (void)	{ return s_pThis->m_nShadowMemSize; }
#endif

private:
	void EnableMMU (void);

#if RASPPI >= 4
	// Onyx: register a contiguous high-RAM segment [nBase, nBase+nSize) with its own
	// page allocator (PageAllocateHigh draws from these; PageFree routes back by address).
	void AddHighSegment (uintptr nBase, size_t nSize);
	// Onyx: reclaim RAM >=4GB (relocated high chunk on >4GB boards) from the device tree.
	void SetupHighMemAbove4G (void);
#endif

private:
	boolean m_bEnableMMU;
	size_t m_nMemSize;
	size_t m_nMemSizeHigh;
#ifdef KASAN_SUPPORTED
	size_t m_nShadowMemSize;
#endif

	CHeapAllocator m_HeapLow;
#if RASPPI >= 4
	CHeapAllocator m_HeapHigh;	// Onyx: left un-Setup -- the high region now backs m_PagerHigh
#endif
	CPageAllocator m_Pager;		// LOW zone (<1GB): kernel page tables, DMA-critical
#if RASPPI >= 4
	// HIGH zone: one page allocator per contiguous high-RAM segment. seg 0 = [1GB,3GB];
	// further segments are RAM >=4GB reclaimed from the device tree (SetupHighMemAbove4G).
#define CMEM_HIGH_SEG_MAX	8
	CPageAllocator m_PagerHigh[CMEM_HIGH_SEG_MAX];
	uintptr	       m_HighBase[CMEM_HIGH_SEG_MAX];
	uintptr	       m_HighEnd[CMEM_HIGH_SEG_MAX];		// exclusive
	unsigned       m_nHighSeg;
	size_t	       m_nMemSizeHigh4G;			// RAM mapped above 4GB (bytes)
	size_t	       m_nHighZoneTotal;			// total of all high segments (app pool)
#endif

#if AARCH == 32
	CPageTable *m_pPageTable;
#else
	CTranslationTable *m_pTranslationTable;
#endif

	static CMemorySystem *s_pThis;
};

#endif
