//
// translationtable64.h
//
// Circle - A C++ bare metal environment for Raspberry Pi
// Copyright (C) 2016-2018  R. Stange <rsta2@o2online.de>
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
#ifndef _circle_translationtable64_h
#define _circle_translationtable64_h

#include <circle/armv8mmu.h>
#include <circle/macros.h>
#include <circle/types.h>

// index into MAIR_EL1 register
#define ATTRINDX_NORMAL		0
#define ATTRINDX_DEVICE		1
#define ATTRINDX_COHERENT	2

class CTranslationTable
{
public:
	CTranslationTable (size_t nMemSize) NOOPT;
	~CTranslationTable (void);

	uintptr GetBaseAddress (void) const;

	// Onyx: identity-map [nBase, nBase+nSize) as NORMAL cacheable RAM, AFTER boot, into
	// the live (already-active) table. Used to add high RAM (>=4GB) that the ctor skips.
	// Creates L3 tables for any not-yet-mapped L2 entries it covers; assumes those L2
	// entries were invalid (high RAM region), never overwrites an existing mapping.
	// nBase/nSize must be 64KB-aligned. Returns FALSE on bad args or palloc failure.
	boolean MapRangeNormal (u64 nBase, u64 nSize) NOOPT;

private:
	TARMV8MMU_LEVEL3_DESCRIPTOR *CreateLevel3Table (uintptr nBaseAddress) NOOPT;

private:
	size_t m_nMemSize;

	TARMV8MMU_LEVEL2_DESCRIPTOR *m_pTable;
};

#endif
