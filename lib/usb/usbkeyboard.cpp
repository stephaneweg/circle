//
// usbkeyboard.cpp
//
// Circle - A C++ bare metal environment for Raspberry Pi
// Copyright (C) 2014-2025  R. Stange <rsta2@o2online.de>
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
#include <circle/usb/usbkeyboard.h>
#include <circle/devicenameservice.h>
#include <circle/usb/usbhostcontroller.h>
#include <circle/synchronize.h>
#include <circle/logger.h>
#include <circle/util.h>
#include <circle/macros.h>
#include <assert.h>

CNumberPool CUSBKeyboardDevice::s_DeviceNumberPool (1);

static const char FromUSBKbd[] = "usbkbd";
static const char DevicePrefix[] = "ukbd";

CUSBKeyboardDevice::CUSBKeyboardDevice (CUSBFunction *pFunction)
:	CUSBHIDDevice (pFunction),
	m_nReportSize (USBKEYB_REPORT_SIZE),
	m_nKeyFields (0),
	m_bTranslateReports (FALSE),
	m_bReportIDs (FALSE),
	m_bHasLEDs (FALSE),
	m_ucLEDReportID (0),
	m_pKeyStatusHandlerRaw (0),
	m_pKeyStatusHandlerRawArg (0),
	m_bMixedMode (FALSE),
	m_ucLastLEDStatus (0),
	m_nDeviceNumber (0)		// not assigned
{
	memset (m_LastReport, 0, sizeof m_LastReport);
}

CUSBKeyboardDevice::~CUSBKeyboardDevice (void)
{
	m_pKeyStatusHandlerRaw = 0;

	if (m_nDeviceNumber != 0)
	{
		CDeviceNameService::Get ()->RemoveDevice (DevicePrefix, m_nDeviceNumber, FALSE);

		s_DeviceNumberPool.FreeNumber (m_nDeviceNumber);
	}
}

boolean CUSBKeyboardDevice::Configure (void)
{
	// (Onyx) not a boot keyboard (the factory's generic HID path): read its report descriptor
	if (   GetInterfaceSubClass () != 1
	    || GetInterfaceProtocol () != 1)
	{
		return ConfigureFromReportDescriptor ();
	}

	// The HideLink THEC64 keyboard sends the report ID in the first byte,
	// which has to be ignored.
	const TUSBDeviceDescriptor *pDeviceDesc = GetDevice ()->GetDeviceDescriptor ();
	assert (pDeviceDesc != 0);
	const TUSBHIDDescriptor *pHIDDesc =
		(const TUSBHIDDescriptor *) GetDescriptor (DESCRIPTOR_HID);
	if (   pDeviceDesc->idVendor == 0x1C59
	    && pDeviceDesc->idProduct == 0x99
	    && pHIDDesc != 0
	    && pHIDDesc->wReportDescriptorLength == 78)
	{
		m_nReportSize++;
	}

	return ConfigureKeyboard (m_nReportSize);
}

boolean CUSBKeyboardDevice::ConfigureKeyboard (unsigned nReportSize)
{
	if (!CUSBHIDDevice::ConfigureHID (nReportSize))
	{
		CLogger::Get ()->Write (FromUSBKbd, LogError, "Cannot configure HID device");

		return FALSE;
	}

	// setting the LED status forces some keyboard adapters to work
	SetLEDs (m_ucLastLEDStatus);

	m_nDeviceNumber = s_DeviceNumberPool.AllocateNumber (TRUE, FromUSBKbd);

	CDeviceNameService::Get ()->AddDevice (DevicePrefix, m_nDeviceNumber, this, FALSE);

	return StartRequest ();
}

void CUSBKeyboardDevice::RegisterKeyPressedHandler (TKeyPressedHandler *pKeyPressedHandler)
{
	m_Behaviour.RegisterKeyPressedHandler (pKeyPressedHandler);
}

void CUSBKeyboardDevice::RegisterSelectConsoleHandler (TSelectConsoleHandler *pSelectConsoleHandler)
{
	m_Behaviour.RegisterSelectConsoleHandler (pSelectConsoleHandler);
}

void CUSBKeyboardDevice::RegisterShutdownHandler (TShutdownHandler *pShutdownHandler)
{
	m_Behaviour.RegisterShutdownHandler (pShutdownHandler);
}

void CUSBKeyboardDevice::UpdateLEDs (void)
{
	if (   m_pKeyStatusHandlerRaw == 0
	    || m_bMixedMode)
	{
		u8 ucLEDStatus = GetLEDStatus ();
		if (ucLEDStatus != m_ucLastLEDStatus)
		{
			m_ucLastLEDStatus = ucLEDStatus;
			if (!SetLEDs (m_ucLastLEDStatus))
			{
				CLogger::Get ()->Write (FromUSBKbd, LogError, "Cannot set LED status");
			}
		}
	}
}

u8 CUSBKeyboardDevice::GetLEDStatus (void) const
{
	u8 ucStatus = m_Behaviour.GetLEDStatus ();

	u8 ucResult = 0;

	if (ucStatus & KEYB_LED_NUM_LOCK)
	{
		ucResult |= LED_NUM_LOCK;
	}

	if (ucStatus & KEYB_LED_CAPS_LOCK)
	{
		ucResult |= LED_CAPS_LOCK;
	}

	if (ucStatus & KEYB_LED_SCROLL_LOCK)
	{
		ucResult |= LED_SCROLL_LOCK;
	}

	return ucResult;
}

void CUSBKeyboardDevice::RegisterKeyStatusHandlerRaw (TKeyStatusHandlerRawEx *pKeyStatusHandlerRaw,
					boolean bMixedMode, void* pArg)
{
	assert (pKeyStatusHandlerRaw != 0);
	m_pKeyStatusHandlerRaw = pKeyStatusHandlerRaw;
	m_pKeyStatusHandlerRawArg = pArg;
	m_bMixedMode = bMixedMode;
}

static void proxy_handler(unsigned char ucModifiers, const unsigned char RawKeys[6], void* arg)
{
	((TKeyStatusHandlerRaw*)arg)(ucModifiers, RawKeys);
}

void CUSBKeyboardDevice::RegisterKeyStatusHandlerRaw (TKeyStatusHandlerRaw *pKeyStatusHandlerRaw,
						      boolean bMixedMode)
{
	RegisterKeyStatusHandlerRaw(proxy_handler, bMixedMode, (void*)pKeyStatusHandlerRaw);
}

void CUSBKeyboardDevice::UnregisterKeyStatusHandlerRaw (void)
{
	m_pKeyStatusHandlerRaw = 0;
	m_pKeyStatusHandlerRawArg = 0;
}

boolean CUSBKeyboardDevice::SetLEDs (u8 ucStatus)
{
	if (m_bTranslateReports)		// (Onyx) the output report its descriptor declares
	{
		if (!m_bHasLEDs)
		{
			return TRUE;
		}

		if (m_ucLEDReportID != 0)
		{
			DMA_BUFFER (u8, IDBuffer, 2) = {m_ucLEDReportID, ucStatus};

			return GetHost ()->ControlMessage (GetEndpoint0 (),
					REQUEST_OUT | REQUEST_CLASS | REQUEST_TO_INTERFACE,
					SET_REPORT, REPORT_TYPE_OUTPUT << 8 | m_ucLEDReportID,
					GetInterfaceNumber (), IDBuffer, 2) >= 0;
		}
	}

	DMA_BUFFER (u8, Buffer, 1) = {ucStatus};

	if (GetHost ()->ControlMessage (GetEndpoint0 (),
					REQUEST_OUT | REQUEST_CLASS | REQUEST_TO_INTERFACE,
					SET_REPORT, REPORT_TYPE_OUTPUT << 8,
					GetInterfaceNumber (), Buffer, 1) < 0)
	{
		return FALSE;
	}

	return TRUE;
}

void CUSBKeyboardDevice::ReportHandler (const u8 *pReport, unsigned nReportSize)
{
	u8 BootReport[USBKEYB_REPORT_SIZE];
	if (m_bTranslateReports)		// (Onyx) a report of any layout, made a boot one
	{
		if (   pReport == 0
		    || !TranslateReport (pReport, nReportSize, BootReport))
		{
			return;			// another report of the interface (a mouse, consumer keys...)
		}

		pReport = BootReport;
		nReportSize = USBKEYB_REPORT_SIZE;
	}
	// Ignore report ID, if it is included.
	else if (   pReport != 0
		 && m_nReportSize > USBKEYB_REPORT_SIZE)
	{
		pReport++;
		nReportSize--;
	}

	if (   pReport == 0
	    || nReportSize != USBKEYB_REPORT_SIZE)
	{
		return;
	}

	if (m_pKeyStatusHandlerRaw != 0)
	{
		(*m_pKeyStatusHandlerRaw) (pReport[0], pReport+2, m_pKeyStatusHandlerRawArg);

		if (!m_bMixedMode)
		{
			return;
		}
	}

	// report modifier keys
	for (unsigned i = 0; i < 8; i++)
	{
		unsigned nMask = 1 << i;

		if (    (pReport[0] & nMask)
		    && !(m_LastReport[0] & nMask))
		{
			m_Behaviour.KeyPressed (0x80 + i);
		}
		else if (   !(pReport[0] & nMask)
			 &&  (m_LastReport[0] & nMask))
		{
			m_Behaviour.KeyReleased (0x80 + i);
		}
	}

	// report released keys
	for (unsigned i = 2; i < USBKEYB_REPORT_SIZE; i++)
	{
		u8 ucKeyCode = m_LastReport[i];
		if (   ucKeyCode != 0
		    && !FindByte (pReport+2, ucKeyCode, USBKEYB_REPORT_SIZE-2))
		{
			m_Behaviour.KeyReleased (ucKeyCode);
		}
	}

	// report pressed keys
	for (unsigned i = 2; i < USBKEYB_REPORT_SIZE; i++)
	{
		u8 ucKeyCode = pReport[i];
		if (   ucKeyCode != 0
		    && !FindByte (m_LastReport+2, ucKeyCode, USBKEYB_REPORT_SIZE-2))
		{
			m_Behaviour.KeyPressed (ucKeyCode);
		}
	}

	memcpy (m_LastReport, pReport, sizeof m_LastReport);
}

boolean CUSBKeyboardDevice::ConfigureFromReportDescriptor (void)	// (Onyx)
{
	const TUSBHIDDescriptor *pHIDDesc =
		(const TUSBHIDDescriptor *) GetDescriptor (DESCRIPTOR_HID);
	if (   pHIDDesc == 0
	    || pHIDDesc->wReportDescriptorLength == 0)
	{
		ConfigurationError (FromUSBKbd);

		return FALSE;
	}

	unsigned nLength = pHIDDesc->wReportDescriptorLength;
	DMA_BUFFER (u8, Desc, nLength);
	if (   GetHost ()->GetDescriptor (GetEndpoint0 (),
					  pHIDDesc->bReportDescriptorType, DESCRIPTOR_INDEX_DEFAULT,
					  Desc, nLength,
					  REQUEST_IN | REQUEST_TO_INTERFACE, GetInterfaceNumber ())
	    != (int) nLength)
	{
		CLogger::Get ()->Write (FromUSBKbd, LogError, "Cannot get HID report descriptor");

		return FALSE;
	}

	// the descriptor in the log: what a new keyboard sends can be checked from there
	static const char Hex[] = "0123456789ABCDEF";
	for (unsigned nLine = 0; nLine < nLength; nLine += 32)
	{
		char Buffer[32*3+1];
		unsigned nPos = 0;
		for (unsigned i = nLine; i < nLength && i < nLine+32; i++)
		{
			Buffer[nPos++] = Hex[Desc[i] >> 4];
			Buffer[nPos++] = Hex[Desc[i] & 0x0F];
			Buffer[nPos++] = ' ';
		}
		Buffer[nPos] = '\0';

		CLogger::Get ()->Write (FromUSBKbd, LogDebug, "report descriptor %03X: %s", nLine, Buffer);
	}

	unsigned nMaxReportSize = 0;
	if (!DecodeReportDescriptor (Desc, nLength))
	{
		CLogger::Get ()->Write (FromUSBKbd, LogWarning, "No keys in the HID report descriptor");

		return FALSE;
	}

	m_bTranslateReports = TRUE;
	nMaxReportSize = m_nReportSize;

	CLogger::Get ()->Write (FromUSBKbd, LogNotice,
				"Keyboard from its report descriptor: %u field(s), report IDs %s, "
				"reports up to %u bytes", m_nKeyFields, m_bReportIDs ? "yes" : "no",
				nMaxReportSize);

	return ConfigureKeyboard (nMaxReportSize);
}

// The HID 1.11 short items: the keyboard page's input fields, the size of every input report
// (the transfer must hold the largest one of the interface), the LEDs' output report.
boolean CUSBKeyboardDevice::DecodeReportDescriptor (const u8 *pDesc, unsigned nLength)	// (Onyx)
{
	struct TGlobals
	{
		u32 nUsagePage;
		s32 nLogicalMin;
		u32 nReportSize;
		u32 nReportCount;
		u8  ucReportID;
	};
	TGlobals Globals = {0, 0, 0, 0, 0};
	TGlobals Stack[4];
	unsigned nStackDepth = 0;

	u32 nUsageMin = 0;
	boolean bUsageMin = FALSE;
	u32 nFirstUsage = 0;
	boolean bUsage = FALSE;

	u16 InputBits[256];			// by report ID
	memset (InputBits, 0, sizeof InputBits);

	m_nKeyFields = 0;
	m_bReportIDs = FALSE;
	m_bHasLEDs = FALSE;

	while (nLength > 0)
	{
		u8 ucItem = *pDesc++;
		nLength--;

		if (ucItem == 0xFE)		// a long item: skipped
		{
			if (nLength < 2 || nLength < 2u + pDesc[0])
			{
				break;
			}
			unsigned nSkip = 2 + pDesc[0];
			pDesc += nSkip;
			nLength -= nSkip;

			continue;
		}

		unsigned nSize = ucItem & 0x03;
		if (nSize == 3)
		{
			nSize = 4;
		}
		if (nSize > nLength)
		{
			break;
		}

		u32 nArg = 0;
		for (unsigned i = 0; i < nSize; i++)
		{
			nArg |= (u32) pDesc[i] << (8*i);
		}
		s32 nSignedArg = (s32) nArg;
		if (nSize == 1)
		{
			nSignedArg = (s8) nArg;
		}
		else if (nSize == 2)
		{
			nSignedArg = (s16) nArg;
		}

		pDesc += nSize;
		nLength -= nSize;

		boolean bClearLocals = FALSE;

		switch (ucItem & 0xFC)
		{
		case 0x04:	Globals.nUsagePage = nArg;		break;	// Usage Page
		case 0x14:	Globals.nLogicalMin = nSignedArg;	break;	// Logical Minimum
		case 0x74:	Globals.nReportSize = nArg;		break;	// Report Size
		case 0x94:	Globals.nReportCount = nArg;		break;	// Report Count

		case 0x84:							// Report ID
			Globals.ucReportID = (u8) nArg;
			m_bReportIDs = TRUE;
			break;

		case 0xA4:							// Push
			if (nStackDepth < sizeof Stack / sizeof Stack[0])
			{
				Stack[nStackDepth++] = Globals;
			}
			break;

		case 0xB4:							// Pop
			if (nStackDepth > 0)
			{
				Globals = Stack[--nStackDepth];
			}
			break;

		case 0x08:							// Usage
			if (!bUsage)
			{
				nFirstUsage = nSize == 4 ? nArg & 0xFFFF : nArg;
				bUsage = TRUE;
			}
			break;

		case 0x18:							// Usage Minimum
			nUsageMin = nArg;
			bUsageMin = TRUE;
			break;

		case 0x80:							// Input
			if (   Globals.nUsagePage == 0x07			// Keyboard/Keypad
			    && !(nArg & 0x01)					// data, not constant
			    && Globals.nReportSize > 0
			    && Globals.nReportSize <= 16
			    && Globals.nReportCount > 0
			    && Globals.nReportCount <= 255
			    && m_nKeyFields < MaxKeyFields)
			{
				TKeyField *pField = &m_KeyFields[m_nKeyFields++];

				pField->ucReportID = Globals.ucReportID;
				pField->bVariable = !!(nArg & 0x02);
				pField->usBitOffset = InputBits[Globals.ucReportID];
				pField->ucBitSize = (u8) Globals.nReportSize;
				pField->ucCount = (u8) Globals.nReportCount;
				pField->usUsageMin = (u16) (bUsageMin ? nUsageMin : nFirstUsage);
				pField->nLogicalMin = Globals.nLogicalMin;
			}
			InputBits[Globals.ucReportID] += Globals.nReportSize * Globals.nReportCount;
			bClearLocals = TRUE;
			break;

		case 0x90:							// Output
			if (   Globals.nUsagePage == 0x08			// LEDs
			    && !m_bHasLEDs)
			{
				m_bHasLEDs = TRUE;
				m_ucLEDReportID = Globals.ucReportID;
			}
			bClearLocals = TRUE;
			break;

		case 0xA0:							// Collection
		case 0xB0:							// Feature
		case 0xC0:							// End Collection
			bClearLocals = TRUE;
			break;

		default:
			break;
		}

		if (bClearLocals)
		{
			bUsageMin = FALSE;
			bUsage = FALSE;
		}
	}

	// the transfer must hold the largest input report of the interface
	unsigned nMaxBytes = 0;
	for (unsigned nID = 0; nID < 256; nID++)
	{
		unsigned nBytes = (InputBits[nID] + 7) / 8;
		if (nBytes > nMaxBytes)
		{
			nMaxBytes = nBytes;
		}
	}
	m_nReportSize = nMaxBytes + (m_bReportIDs ? 1 : 0);
	if (m_nReportSize < USBKEYB_REPORT_SIZE)
	{
		m_nReportSize = USBKEYB_REPORT_SIZE;
	}

	return m_nKeyFields > 0;
}

boolean CUSBKeyboardDevice::TranslateReport (const u8 *pReport, unsigned nReportSize,
					     u8 *pBootReport) const	// (Onyx)
{
	assert (pReport != 0);
	assert (pBootReport != 0);

	u8 ucReportID = 0;
	if (m_bReportIDs)
	{
		if (nReportSize < 1)
		{
			return FALSE;
		}

		ucReportID = *pReport++;
		nReportSize--;
	}

	memset (pBootReport, 0, USBKEYB_REPORT_SIZE);
	unsigned nKeys = 0;
	boolean bFound = FALSE;

	for (unsigned nField = 0; nField < m_nKeyFields; nField++)
	{
		const TKeyField *pField = &m_KeyFields[nField];
		if (pField->ucReportID != ucReportID)
		{
			continue;
		}

		bFound = TRUE;

		for (unsigned i = 0; i < pField->ucCount; i++)
		{
			unsigned nBit = pField->usBitOffset + i * pField->ucBitSize;
			if (nBit + pField->ucBitSize > nReportSize * 8)
			{
				break;
			}

			u32 nValue = 0;
			for (unsigned j = 0; j < pField->ucBitSize; j++)
			{
				unsigned nPos = nBit + j;
				if (pReport[nPos / 8] & (1 << (nPos % 8)))
				{
					nValue |= 1 << j;
				}
			}

			unsigned nUsage;
			if (pField->bVariable)
			{
				if (nValue == 0)
				{
					continue;
				}

				nUsage = pField->usUsageMin + i;
			}
			else
			{
				nUsage = pField->usUsageMin + (s32) nValue - pField->nLogicalMin;
			}

			if (0xE0 <= nUsage && nUsage <= 0xE7)		// a modifier
			{
				pBootReport[0] |= 1 << (nUsage - 0xE0);
			}
			else if (   nUsage > 0x03			// not none, not an error
				 && nUsage <= 0xFF
				 && nKeys < USBKEYB_REPORT_SIZE-2)
			{
				pBootReport[2 + nKeys++] = (u8) nUsage;
			}
		}
	}

	return bFound;
}

boolean CUSBKeyboardDevice::FindByte (const u8 *pBuffer, u8 ucByte, unsigned nLength)
{
	while (nLength-- > 0)
	{
		if (*pBuffer++ == ucByte)
		{
			return TRUE;
		}
	}

	return FALSE;
}
