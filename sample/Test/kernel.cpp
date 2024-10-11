//
// kernel.cpp
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
#include <circle/multicore.h>
#include "kernel.h"
#include <circle/string.h>
#include <circle/debug.h>
#include <assert.h>
#include "system.h"
#include "runtime.h"
#include "gui/gui.h"

#define DRIVE		"SD:"
CKernel* KernelInstance;
static const char FromKernel[] = "kernel";
CKernel::CKernel() : CMultiCoreSupport(CMemorySystem::Get()),
	m_Screen (m_Options.GetWidth (), m_Options.GetHeight ()),
	m_Timer (&m_Interrupt),
	m_Logger (m_Options.GetLogLevel ()),
	m_USBHCI (&m_Interrupt, &m_Timer, TRUE),		// TRUE: enable plug-and-play
	m_EMMC (&m_Interrupt, &m_Timer, &m_ActLED),
	m_2DGraphics(m_Options.GetWidth (), m_Options.GetHeight (),true),
	m_guiSpinLock(0),
	m_ShutdownMode (ShutdownNone),
	m_guiReady(0)
{
	m_ActLED.Blink (5);
	KernelInstance = this;
}

CKernel::~CKernel (void)
{
	KernelInstance = 0;
}

void CKernel::ShutdownHandler (void)
{
	assert (KernelInstance != 0);
	KernelInstance->m_ShutdownMode = ShutdownReboot;
}
boolean CKernel::PreInitialize(void)
{
	boolean bOK = TRUE;
	if (bOK)
	{
		bOK = m_Screen.Initialize ();
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
		m_Logger.Write (FromKernel, LogPanic, "Cannot mount drive: %s", DRIVE);
	}
	
	
	if (bOK)
	{
		bOK = Initialize();
	}
	
	return bOK;
}

TShutdownMode CKernel::RunMain (void)
{
	Run(0);
	return m_ShutdownMode;
}

void CKernel::Run(unsigned nCore)
{	

	switch(nCore)
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

//Core 0 is Gui
void CKernel::RunCore0()
{
	CLogger::Get ()->Write (FromKernel, LogNotice, "CORE 0 : Main Loop");
	
	
	m_2DGraphics.Initialize ();
	m_2DGraphics.UpdateDisplay();
	gui_init(m_2DGraphics.GetBuffer (),m_2DGraphics.GetWidth (),m_2DGraphics.GetHeight ());
	m_guiReady = 1;
	while (m_ShutdownMode == ShutdownNone)
	{
		if ( gui_redraw()==1)
		{
			m_2DGraphics.UpdateDisplay();
			gui_set_lfb(m_2DGraphics.GetBuffer ());
		}
	}
}

//Core is App Manager
void CKernel::RunCore1()
{
	while (m_guiReady == 0){}
	CLogger::Get ()->Write (FromKernel, LogNotice, "CORE 1 : Main Loop");
	runtime_init();
	while (m_ShutdownMode == ShutdownNone)
	{
	}
	
	/*
	vm_init();
	vm_services_init();
	while(1)
	{
		vm_taskscheduler_run();
	}
	*/
}

//Core 2 is usb
void CKernel::RunCore2()
{
	while (m_guiReady == 0){}
	CLogger::Get ()->Write (FromKernel, LogNotice, "CORE 2 : Main Loop");
	
	while (m_ShutdownMode == ShutdownNone)
	{
		/*
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
		*/
	}
	
	
}

void CKernel::RunCore3()
{
	while (m_guiReady == 0){
	}
	CLogger::Get ()->Write (FromKernel, LogNotice, "CORE 3 : Main Loop");
	while (m_ShutdownMode == ShutdownNone)
	{
	}
}

void CKernel::IPIHandler(unsigned nCore,unsigned nIPI)
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

void CKernel::IPIHandlerCore0(unsigned nIPI)
{
}

void CKernel::IPIHandlerCore1(unsigned nIPI)
{
}

void CKernel::IPIHandlerCore2(unsigned nIPI)
{
}
void CKernel::IPIHandlerCore3(unsigned nIPI)
{
}


void CKernel::kwriteText(const char* txt)
{
		CString Message = txt;
		m_Screen.Write ((const char *) Message, Message.GetLength ());
}

void CKernel::kwriteFormat(const char *txt, ...)
{
	va_list var;
	va_start (var, txt);

	kwriteFormatV (txt, var);

	va_end (var);
}

void CKernel::kwriteFormatV(const char* txt,va_list args)
{
		CString Message;
		Message.FormatV(txt,args);
		m_Screen.Write ((const char *) Message, Message.GetLength ());
}
