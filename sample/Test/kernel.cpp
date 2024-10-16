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
#include <circle/util.h>
#include "kernel.h"
#include <circle/string.h>
#include <circle/debug.h>
#include <assert.h>
#include "system.h"
#include "runtime.h"
#include "gui/gui.h"

#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  ((byte) & 0x80 ? '1' : '0'), \
  ((byte) & 0x40 ? '1' : '0'), \
  ((byte) & 0x20 ? '1' : '0'), \
  ((byte) & 0x10 ? '1' : '0'), \
  ((byte) & 0x08 ? '1' : '0'), \
  ((byte) & 0x04 ? '1' : '0'), \
  ((byte) & 0x02 ? '1' : '0'), \
  ((byte) & 0x01 ? '1' : '0') 
  
#define DRIVE		"SD:"
CKernel* KernelInstance;
static const char FromKernel[] = "kernel";
CKernel::CKernel() : CMultiCoreSupport(CMemorySystem::Get()),
	m_Screen (m_Options.GetWidth (), m_Options.GetHeight ()),
	m_Timer (&m_Interrupt),
	m_Logger (m_Options.GetLogLevel ()),
	m_USBHCI (&m_Interrupt, &m_Timer, TRUE),		// TRUE: enable plug-and-play
	m_EMMC (&m_Interrupt, &m_Timer, &m_ActLED),
	m_2DGraphics(m_Options.GetWidth (), m_Options.GetHeight (),atoi(m_Options.GetAppOptionString("usevsync"))==1),
	m_guiSpinLock(0),
	m_ShutdownMode (ShutdownNone),
	m_guiReady(0)
{
	for (unsigned i = 0; i < MAX_GAMEPADS; i++)
	{
		m_pGamePad[i] = 0;
		padd_button_all[i]=0;
		for(unsigned j = 0; j<MAX_BUTTONS;j++)
		{
			padd_button[i][j]=0;
		}
		for(unsigned j = 0; j<MAX_AXES;j++)
		{
			padd_axes[i][j]=0;
		}
		for(unsigned j = 0; j<MAX_HATS;j++)
		{
			padd_hats[i][j]=0;
		}
	}
	m_framecount=0;
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
	m_guiReady = 0;
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
	
	m_2DGraphics.Initialize ();
	m_2DGraphics.UpdateDisplay();
	
	
	gui_init(m_2DGraphics.GetBuffer (),m_2DGraphics.GetWidth (),m_2DGraphics.GetHeight (),atoi(m_Options.GetAppOptionString("rotate")));
	
	if ( gui_redraw()==1)
	{
		m_2DGraphics.UpdateDisplay();
		gui_set_lfb(m_2DGraphics.GetBuffer ());
	}
	m_guiReady = 1;
	
	
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
	//while (m_guiReady == 0){m_Timer.MsDelay (100);}
	kwriteLine("KERNEL : Core 0 ready");

	while (m_ShutdownMode == ShutdownNone)
	{
		if ( gui_redraw()==1)
		{
			m_2DGraphics.UpdateDisplay();
			gui_set_lfb(m_2DGraphics.GetBuffer ());
			m_framecount++;
		}
	}
}

//Core is App Manager
void CKernel::RunCore1()
{
	//while (m_guiReady == 0){m_Timer.MsDelay (100);}
	kwriteLine("KERNEL : Core 1 ready");
	runtime_init();
	
	
	
	while (m_ShutdownMode == ShutdownNone)
	{
		m_Timer.SimpleMsDelay(16);
		gui_update(0.016);
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
	//while (m_guiReady == 0){m_Timer.MsDelay (100);}
	kwriteLine("KERNEL : Core 2 ready");
	
	
	while (m_ShutdownMode == ShutdownNone)
	{
		boolean bUpdated = m_USBHCI.UpdatePlugAndPlay ();
		if (bUpdated)
		{
			detectGamePad();
		}
		
	}
	
	
}

//Core 3 is for audio
void CKernel::RunCore3()
{
	//while (m_guiReady == 0){m_Timer.MsDelay (100);}
	kwriteLine("KERNEL : Core 3 ready");
	while (m_ShutdownMode == ShutdownNone)
	{
		/*
		m_Timer.SimpleMsDelay(10000);
		
		kwriteFormatLine("FPS : %d frame per seconds",m_framecount/10);
		m_framecount = 0;
		*/
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

void CKernel::detectGamePad()
{
	for (unsigned nDevice = 1; nDevice <= MAX_GAMEPADS; nDevice++)
	{
		if (m_pGamePad[nDevice-1] != 0)
		{
			continue;
		}

		m_pGamePad[nDevice-1] = (CUSBGamePadDevice *) m_DeviceNameService.GetDevice ("upad", nDevice, FALSE);
		if (m_pGamePad[nDevice-1] == 0)
		{
			continue;
		}

		const TGamePadState *pState = m_pGamePad[nDevice-1]->GetInitialState ();
		assert (pState != 0);

		kwriteFormatLine("Gamepad %u: %d Button(s) %d Hat(s)", nDevice-1, pState->nbuttons, pState->nhats);

		for (int i = 0; i < pState->naxes; i++)
		{
			kwriteFormatLine("Gamepad %u: Axis %d: Minimum %d Maximum %d",nDevice, i+1, pState->axes[i].minimum,pState->axes[i].maximum);
		}

		m_pGamePad[nDevice-1]->RegisterRemovedHandler(GamePadRemovedHandler, this);
		m_pGamePad[nDevice-1]->RegisterStatusHandler(GamePadStatusHandler);

		kwriteFormatLine(FromKernel, LogNotice, "Use your gamepad controls!");
	}
}

void CKernel::LockGui()
{
	m_guiSpinLock.Acquire();
}

void CKernel::UnlockGui()
{
	m_guiSpinLock.Release();
}

void CKernel::k_write(const char* txt)
{
	if (m_guiReady == 0)
	{
		CString Message = txt;
		m_Screen.Write ((const char *) Message, Message.GetLength ());
	}
	else
	{
		gui_write(txt);
	}
}

void CKernel::k_writeLine(const char* txt)
{
	if (m_guiReady == 0)
	{
		CString Message = txt;
		m_Screen.Write ((const char *) Message, Message.GetLength ());
		m_Screen.NewLine();
	}
	else
	{
		gui_writeline(txt);
	}
}

void CKernel::k_writeFormat(const char *txt, ...)
{
	va_list var;
	va_start (var, txt);

	k_writeFormatV (txt, var);

	va_end (var);
}

void CKernel::k_writeFormatLine(const char *txt, ...)
{
	va_list var;
	va_start (var, txt);

	k_writeFormatVLine(txt, var);

	va_end (var);
}

void CKernel::k_writeFormatV(const char* txt,va_list args)
{
	CString Message;
	Message.FormatV(txt,args);
	if (m_guiReady == 0)
	{
		m_Screen.Write ((const char *) Message, Message.GetLength ());
	}
	else
	{
		gui_write(Message.GetBuffer());
	}
}

void CKernel::k_writeFormatVLine(const char* txt,va_list args)
{
	CString Message;
	Message.FormatV(txt,args);
	if (m_guiReady == 0)
	{
		m_Screen.Write ((const char *) Message, Message.GetLength ());
		m_Screen.NewLine();
	}
	else
	{
		gui_writeline(Message.GetBuffer());
	}
}


s32 CKernel::get_joypad_axis(u32 gamepad,u32 axis)
{
	s32 result = 0;
	if (gamepad<MAX_GAMEPADS && axis<MAX_AXES)
	{
		result = padd_axes[gamepad][axis];
		if (result<0) result=-1;
		if (result>0) result=1;
	}
	return result;
}

u32 CKernel::get_joypad_buttons(u32 gamepad)
{
	u32 result = 0;
	if (gamepad<MAX_GAMEPADS)
	{
		result = padd_button_all[gamepad];
	}
	return result;
}

void CKernel::GamePadStatusHandler (unsigned nDeviceIndex, const TGamePadState *pState)
{
	
	if (KernelInstance->padd_button_all[nDeviceIndex]!=pState->buttons)
	{
		KernelInstance->padd_button_all[nDeviceIndex] = pState->buttons;
		//unsigned v = pState->buttons;
		//kwriteFormatLine("Gamepad %d button " BYTE_TO_BINARY_PATTERN " " BYTE_TO_BINARY_PATTERN,nDeviceIndex,BYTE_TO_BINARY(v>>8), BYTE_TO_BINARY(v));
	}
	for(unsigned  i=0;i<MAX_BUTTONS;i++)
	{
		unsigned  v = (pState->buttons & (1<<i))>>i;
		if (KernelInstance->padd_button[nDeviceIndex][i] != v)
		{
			KernelInstance->padd_button[nDeviceIndex][i] = v;
			if(v)
			{
				//kwriteFormatLine("Gamepad %d button %d pressed",nDeviceIndex,i);
			}
			else
			{
				//kwriteFormatLine("Gamepad %d button %d released",nDeviceIndex,i);
			}
		}
		
	}

	
	if (pState->naxes > 0)
	{
		for (int i = 0; i < pState->naxes && i< MAX_AXES; i++)
		{
			int value = pState->axes[i].value;
			if (value==0) value=-1;
			else if (value==255) value=1;
			else value = 0;
			
			if (KernelInstance->padd_axes[nDeviceIndex][i] != value)
			{
				KernelInstance->padd_axes[nDeviceIndex][i] = value;
				//kwriteFormatLine("Gamepad %d axe %d %d",nDeviceIndex,i,KernelInstance->padd_axes[nDeviceIndex][i]);
			}
		}
	}

	if (pState->nhats > 0)
	{
		for (int i = 0; i < pState->nhats && i< MAX_HATS; i++)
		{
			if (KernelInstance->padd_hats[nDeviceIndex][i] != pState->hats[i])
			{
				KernelInstance->padd_hats[nDeviceIndex][i] = pState->hats[i];
				//kwriteFormatLine("Gamepad %d hat %d %d",nDeviceIndex,i,KernelInstance->padd_hats[nDeviceIndex][i]);
			}
		}
	}
}

void CKernel::GamePadRemovedHandler (CDevice *pDevice, void *pContext)
{
	CKernel *pThis = (CKernel *) pContext;
	assert (pThis != 0);

	for (unsigned i = 0; i < MAX_GAMEPADS; i++)
	{
		if (pThis->m_pGamePad[i] == (CUSBGamePadDevice *) pDevice)
		{
			kwriteFormatLine("Gamepad %u removed", i);

			pThis->m_pGamePad[i] = 0;
			for(unsigned j = 0; j<MAX_BUTTONS;j++)
			{
				pThis->padd_button[i][j]=0;
			}
			for(unsigned j = 0; j<MAX_AXES;j++)
			{
				pThis->padd_axes[i][j]=0;
			}
			for(unsigned j = 0; j<MAX_HATS;j++)
			{
				pThis->padd_hats[i][j]=0;
			}
			break;
		}
	}
}
