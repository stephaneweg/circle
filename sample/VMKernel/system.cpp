#include "system.h"
#include <assert.h>
#include <circle/alloc.h>
#include <circle/util.h>
#include <circle/string.h>
#include "runtime.h"
#include "services.h"

#define DRIVE		"SD:"
CSystem *CSystem::Instance = 0;
static const char FromSystem[] = "System";
CSystem::CSystem() : CMultiCoreSupport(CMemorySystem::Get()),
	m_Screen (m_Options.GetWidth (), m_Options.GetHeight ()),
	m_Timer (&m_Interrupt),
	m_Logger (m_Options.GetLogLevel (), &m_Timer),
	m_USBHCI (&m_Interrupt, &m_Timer, TRUE),		// TRUE: enable plug-and-play
	m_EMMC (&m_Interrupt, &m_Timer, &m_ActLED),
	m_2DGraphics(m_Options.GetWidth (), m_Options.GetHeight (),true), //TRUE : enable vsync
	m_guiSpinLock(0),
	m_ShutdownMode (ShutdownNone),	
	m_pMouse(0),
	m_pKeyboard (0),
	m_mousePosX(0),
	m_mousePosY(0),
	m_mouseLeft(0),
	m_mouseRight(0),
	m_mouseMiddle(0),
	m_mouseWheel(0),
	m_guiReady(0)
{
	
	m_ActLED.Blink (5);	// show we are alive
	Instance = this;
}

CSystem::~CSystem(void)
{
	Instance = 0;
}

void CSystem::ShutdownHandler (void)
{
	assert (Instance != 0);
	Instance->m_ShutdownMode = ShutdownReboot;
}

boolean CSystem::PreInitialize(void)
{
	boolean bOK = TRUE;
	if (bOK)
	{
		bOK = m_Screen.Initialize ();
	}

	if (bOK)
	{
		bOK = m_Serial.Initialize (115200);
	}

	if (bOK)
	{
		CDevice *pTarget = m_DeviceNameService.GetDevice (m_Options.GetLogDevice (), FALSE);
		if (pTarget == 0)
		{
			pTarget = &m_Screen;
		}
		bOK = m_Logger.Initialize (pTarget);
	}

	if (bOK)
	{
		bOK = m_Interrupt.Initialize ();
	}

	if (bOK)
	{
		bOK = m_Timer.Initialize ();
	}

	if (bOK)
	{
		bOK = m_USBHCI.Initialize ();
	}
	
	
	if (bOK)
	{
		bOK = m_EMMC.Initialize ();
	}
	
	// Mount file system
	if (f_mount (&m_FileSystem, DRIVE, 1) != FR_OK)
	{
		m_Logger.Write (FromSystem, LogPanic, "Cannot mount drive: %s", DRIVE);
	}
	
	if (bOK)
	{
		bOK = Initialize();
	}
	
	return bOK;
}





void CSystem::KeyboardDetect()
{
	if (m_pKeyboard == 0)
	{
		m_pKeyboard = (CUSBKeyboardDevice *) m_DeviceNameService.GetDevice ("ukbd1", FALSE);
		if (m_pKeyboard != 0)
		{
			m_pKeyboard->RegisterRemovedHandler (KeyboardRemovedHandler);

#if 1	// set to 0 to test raw mode
			m_pKeyboard->RegisterShutdownHandler (ShutdownHandler);
			m_pKeyboard->RegisterKeyPressedHandler (KeyPressedHandler);
#else
			m_pKeyboard->RegisterKeyStatusHandlerRaw (KeyStatusHandlerRaw);
#endif

			CLogger::Get()->Write (FromSystem, LogNotice, "Keyboard Detected!");
		}
	}
}
void CSystem::MouseDetect()
{
	if (m_pMouse == 0)
	{
		m_pMouse = (CMouseDevice *) m_DeviceNameService.GetDevice ("mouse1", FALSE);
		if (m_pMouse != 0)
		{
			m_pMouse->RegisterRemovedHandler (MouseRemovedHandler);

			CLogger::Get()->Write (FromSystem, LogNotice, "USB mouse has %d buttons",
					m_pMouse->GetButtonCount());
			CLogger::Get()->Write (FromSystem, LogNotice, "USB mouse has %s wheel",
					m_pMouse->HasWheel() ? "a" : "no");

					
			unsigned mx = m_2DGraphics.GetWidth ();
			unsigned my = m_2DGraphics.GetHeight();
			if (!m_pMouse->Setup (mx, my))
			{
				CLogger::Get ()->Write (FromSystem, LogPanic, "Cannot setup mouse");
			}
			
			//CSystem::MouseEventStub(MouseEventMouseMove,0,mx/2,my/2,0);
			m_pMouse->SetCursor (mx/2, my/2);
			m_pMouse->ShowCursor (TRUE);
			m_pMouse->RegisterEventHandler (MouseEventStub);
		}
	}
}


void CSystem::MouseEventHandler (TMouseEvent Event, unsigned nButtons, unsigned nPosX, unsigned nPosY, int nWheelMove)
{
	boolean changed = false;
	switch (Event)
	{
	case MouseEventMouseMove:
		m_mousePosX = nPosX;
		m_mousePosY = nPosY;
		changed = true;
		break;

	case MouseEventMouseDown:
		if (nButtons & MOUSE_BUTTON_LEFT) m_mouseLeft=1;
		if (nButtons & MOUSE_BUTTON_RIGHT) m_mouseRight=1;
		if (nButtons & MOUSE_BUTTON_MIDDLE) m_mouseMiddle=1;
		changed = true;
		break;

	case MouseEventMouseUp:
		if (nButtons & MOUSE_BUTTON_LEFT) m_mouseLeft=0;
		if (nButtons & MOUSE_BUTTON_RIGHT) m_mouseRight=0;
		if (nButtons & MOUSE_BUTTON_MIDDLE) m_mouseMiddle=0;
		changed = true;
		break;

	case MouseEventMouseWheel:
		m_mouseWheel += nWheelMove;
		changed = true;
		break;

	default:
		break;
	}
	if (changed)
	{
		gui_mouse_update(m_mousePosX,m_mousePosY,m_mouseLeft,m_mouseRight,m_mouseMiddle,nWheelMove);
		//SendIPI(1,IPI_USER+1);
	}
}


void CSystem::MouseEventStub (TMouseEvent Event, unsigned nButtons, unsigned nPosX, unsigned nPosY, int nWheelMove)
{
	assert (Instance != 0);
	Instance->MouseEventHandler(Event, nButtons, nPosX, nPosY, nWheelMove);
}


void CSystem::MouseRemovedHandler (CDevice *pDevice, void *pContext)
{
	assert (Instance != 0);
	Instance->m_pMouse = 0;
}


void CSystem::KeyPressedHandler (const char *pString)
{
	gui_keypress(*pString);
}

void CSystem::KeyboardRemovedHandler (CDevice *pDevice, void *pContext)
{
	assert (Instance != 0);
	CLogger::Get()->Write (FromSystem, LogNotice, "USB keyboard removed");
	Instance->m_pKeyboard = 0;
}

void CSystem::KeyStatusHandlerRaw (unsigned char ucModifiers, const unsigned char RawKeys[6])
{
	/*
	assert (s_pThis != 0);

	CString Message;
	Message.Format ("Key status (modifiers %02X)", (unsigned) ucModifiers);

	for (unsigned i = 0; i < 6; i++)
	{
		if (RawKeys[i] != 0)
		{
			CString KeyCode;
			KeyCode.Format (" %02X", (unsigned) RawKeys[i]);

			Message.Append (KeyCode);
		}
	}

	s_pThis->m_Logger.Write (FromKernel, LogNotice, Message);
	*/
}



void CSystem::Run(unsigned nCore)
{	switch(nCore)
	{
		
		case 0:
			RunCore0();
			break;
		case 1:
			RunCore1();
			break;
		case 2:
			RunCore2();
			break;
		case 3:
			RunCore3();
			break;
	}
}

TShutdownMode CSystem::RunMain (void)
{
	Run(0);
	return m_ShutdownMode;
}

void CSystem::RunCore0()
{
	CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 0 : Starting GUI SubSystem");
	m_2DGraphics.Initialize ();
	m_2DGraphics.UpdateDisplay();
	gui_init(m_2DGraphics.GetBuffer (),m_2DGraphics.GetWidth (),m_2DGraphics.GetHeight ());
	
	m_guiReady = 1;
	while (m_ShutdownMode == ShutdownNone)
	{
		boolean bUpdated = m_USBHCI.UpdatePlugAndPlay ();
		if (bUpdated)
		{
			MouseDetect();
			KeyboardDetect();
		}
		
		if (m_pMouse != 0)
		{
			m_pMouse->UpdateCursor ();
		}
	}
}

void CSystem::RunCore1()
{
	CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 1 : Main Loop");
	CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 1 : Waiting GUI To be ready");
	while (m_guiReady == 0){
		CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 1 : Waiting GUI To be ready");
	}
	CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 1 : GUI Ready");
	vm_init();
	vm_services_init();
	while(1)
	{
		vm_taskscheduler_run();
	}
}

void CSystem::RunCore2()
{
	CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 2 : Main Loop");
	CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 2 : Waiting GUI To be ready");
	while (m_guiReady == 0){
		CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 2 : Waiting GUI To be ready");
	}
	CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 2 : GUI Ready");
	while(1)
	{
		if ( gui_redraw()==1)
		{
			m_2DGraphics.UpdateDisplay();
			gui_setl_fb(m_2DGraphics.GetBuffer ());
		}
	}
}

void CSystem::RunCore3()
{
	CLogger::Get ()->Write (FromSystem, LogNotice, "CORE 3 : Main Loop");
	while(1)
	{
	}
}



void CSystem::IPIHandler(unsigned nCore,unsigned nIPI)
{
	switch(nCore)
	{
		case 0:
			IPIHandlerCore0(nIPI);
			break;
		case 1:
			IPIHandlerCore1(nIPI);
			break;
		case 2:
			IPIHandlerCore2(nIPI);
			break;
		case 3:
			IPIHandlerCore3(nIPI);
			break;
	}
}

void CSystem::IPIHandlerCore0(unsigned nIPI)
{
}

void CSystem::IPIHandlerCore1(unsigned nIPI)
{
}

void CSystem::IPIHandlerCore2(unsigned nIPI)
{
}
void CSystem::IPIHandlerCore3(unsigned nIPI)
{
}



