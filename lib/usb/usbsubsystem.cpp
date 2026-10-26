//
// usbsubsystem.h
//
// Circle - A C++ bare metal environment for Raspberry Pi
// Copyright (C) 2023  R. Stange <rsta2@o2online.de>
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
#include <circle/usb/usbsubsystem.h>
#include <circle/usb/xhciconfig.h>
#include <circle/memory.h>
#include <circle/logger.h>
#include <assert.h>

LOGMODULE ("usb");

CUSBSubSystem *CUSBSubSystem::s_pThis = nullptr;

CUSBSubSystem::CUSBSubSystem (CInterruptSystem *pInterruptSystem, CTimer *pTimer,
			      boolean bPlugAndPlay)
:	m_bPlugAndPlay (bPlugAndPlay),
#if RASPPI >= 5
	m_Southbridge (pInterruptSystem),
#else
	m_pInterruptSystem (pInterruptSystem),
	m_pTimer (pTimer),
	m_bInternalController (FALSE),
#endif
	m_SharedMemAllocator (
		CMemorySystem::GetCoherentPage (COHERENT_SLOT_XHCI_START),
		CMemorySystem::GetCoherentPage (COHERENT_SLOT_XHCI_END) + PAGE_SIZE - 1)
{
	assert (!s_pThis);
	s_pThis = this;

#if RASPPI == 4
	// (Onyx) the VL805 (the USB-A sockets) now, the SoC's controller (USB-C) if requested
	m_pXHCIDevice[0] = new CXHCIDevice (pInterruptSystem, pTimer, bPlugAndPlay,
					    0, &m_SharedMemAllocator);
	assert (m_pXHCIDevice[0]);
	m_pXHCIDevice[1] = nullptr;
#else
	for (unsigned i = 0; i < NumDevices; i++)
	{
		m_pXHCIDevice[i] = new CXHCIDevice (pInterruptSystem, pTimer, bPlugAndPlay,
						    i, &m_SharedMemAllocator);
		assert (m_pXHCIDevice[i]);
	}
#endif
}

#if RASPPI == 4

void CUSBSubSystem::EnableInternalController (void)
{
	m_bInternalController = TRUE;
}

#endif

CUSBSubSystem::~CUSBSubSystem (void)
{
	for (int i = NumDevices-1; i >= 0; i--)
	{
		delete m_pXHCIDevice[i];
		m_pXHCIDevice[i] = nullptr;
	}

	s_pThis = nullptr;
}

boolean CUSBSubSystem::Initialize (boolean bScanDevices)
{
#if RASPPI == 4
	// (Onyx) the VL805 first, as before; the USB-C socket's controller is an extra: its failure
	// (otg_mode=1 missing, nothing behind it) leaves the USB-A sockets working
	assert (m_pXHCIDevice[0]);
	if (!m_pXHCIDevice[0]->Initialize (bScanDevices))
	{
		LOGERR ("Cannot initialize xHCI device #0");

		return FALSE;
	}

	if (m_bInternalController)
	{
		m_pXHCIDevice[1] = new CXHCIDevice (m_pInterruptSystem, m_pTimer, m_bPlugAndPlay,
						    1, &m_SharedMemAllocator);
		assert (m_pXHCIDevice[1]);
		if (m_pXHCIDevice[1]->Initialize (bScanDevices))
		{
			LOGNOTE ("USB-C socket: xHCI device #1 running");
		}
		else
		{
			LOGWARN ("Cannot initialize xHCI device #1 (USB-C socket; config.txt otg_mode=1?)");

			delete m_pXHCIDevice[1];
			m_pXHCIDevice[1] = nullptr;
		}
	}
#else
	if (!m_Southbridge.Initialize ())
	{
		LOGERR ("Cannot initialize RP1 device");

		return FALSE;
	}

	for (unsigned i = 0; i < NumDevices; i++)
	{
		assert (m_pXHCIDevice[i]);
		if (!m_pXHCIDevice[i]->Initialize (bScanDevices))
		{
			LOGERR ("Cannot initialize xHCI device #%d", i);

			return FALSE;
		}
	}
#endif

#if !defined (NDEBUG) && defined (XHCI_DEBUG2)
	DumpStatus ();
#endif

	return TRUE;
}


boolean CUSBSubSystem::UpdatePlugAndPlay (void)
{
	boolean bResult = FALSE;

	for (unsigned i = 0; i < NumDevices; i++)
	{
		if (!m_pXHCIDevice[i])		// (Onyx) the Pi 4's USB-C controller, not enabled
		{
			continue;
		}

		if (m_pXHCIDevice[i]->UpdatePlugAndPlay ())
		{
			bResult = TRUE;
		}
	}

	return bResult;
}

int CUSBSubSystem::GetDescriptor (CUSBEndpoint *pEndpoint,
				  unsigned char ucType, unsigned char ucIndex,
				  void *pBuffer, unsigned nBufSize,
				  unsigned char ucRequestType,
				  unsigned short wIndex)
{
	assert (pEndpoint);
	CUSBDevice *pUSBDevice = pEndpoint->GetDevice ();

	assert (pUSBDevice);
	CUSBHostController *pHost = pUSBDevice->GetHost ();

	assert (pHost);
	return pHost->GetDescriptor (pEndpoint, ucType, ucIndex,
				     pBuffer, nBufSize, ucRequestType, wIndex);
}

boolean CUSBSubSystem::IsPlugAndPlay (void) const
{
	return m_bPlugAndPlay;
}

boolean CUSBSubSystem::IsActive (void)
{
	return !!s_pThis;
}

CUSBSubSystem *CUSBSubSystem::Get (void)
{
	assert (s_pThis);
	return s_pThis;
}

#ifndef NDEBUG

void CUSBSubSystem::DumpStatus (void)
{
	for (unsigned i = 0; i < NumDevices; i++)
	{
		if (m_pXHCIDevice[i])
		{
			m_pXHCIDevice[i]->DumpStatus ();
		}
	}

#if RASPPI >= 5
	m_Southbridge.DumpStatus ();
#endif

	LOGDBG ("%u KB shared memory free",
		(unsigned) (m_SharedMemAllocator.GetFreeSpace () / 1024));
}

#endif
