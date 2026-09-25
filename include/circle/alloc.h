//
// alloc.h
//
// Circle - A C++ bare metal environment for Raspberry Pi
// Copyright (C) 2014-2021  R. Stange <rsta2@o2online.de>
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
#ifndef _circle_alloc_h
#define _circle_alloc_h

#include <circle/types.h>

#ifdef __cplusplus
extern "C" {
#endif

void *malloc (size_t nSize);		// resulting block is always 16 bytes aligned
void *memalign (size_t nAlign, size_t nSize);
void free (void *pBlock);

void *calloc (size_t nBlocks, size_t nSize);
void *realloc (void *pBlock, size_t nSize);

void *palloc (void);			// returns aligned page (AArch32: 4K, AArch64: 64K)
void *palloc_high (void);		// Onyx: page from the HIGH zone (1-3GB) -- non-DMA, for
					// app frames/heaps; falls back to low if no high mem.
void pfree (void *pPage);		// frees a palloc OR palloc_high page (routed by address)

#ifdef __cplusplus
}
#endif

#endif
