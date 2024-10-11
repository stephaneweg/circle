//
// kernel.h
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
#ifndef _kernel_h
#define _kernel_h


#include <circle/2dgraphics.h>
#include <circle/actled.h>
#include <circle/koptions.h>
#include <circle/devicenameservice.h>
#include <circle/screen.h>
#include <circle/serial.h>
#include <circle/exceptionhandler.h>
#include <circle/interrupt.h>
#include <circle/timer.h>
#include <circle/logger.h>
#include <circle/usb/usbhcidevice.h>
#include <circle/usb/usbkeyboard.h>
#include <circle/input/mouse.h>
#include <circle/types.h>
#include <circle/memory.h>
#include <circle/multicore.h>
#include <circle/spinlock.h>
#include <SDCard/emmc.h>
#include <fatfs/ff.h>

enum TShutdownMode
{
	ShutdownNone,
	ShutdownHalt,
	ShutdownReboot
};

class CKernel : public CMultiCoreSupport
{
private:
	static const unsigned nShapes = 32;

public:
	CKernel ();
	~CKernel (void);
	
	
	boolean PreInitialize (void);
	TShutdownMode RunMain (void);

	void InitCore1();
	void Run(unsigned nCore);
	void IPIHandler(unsigned nCore,unsigned nIPI);
	
	void kwriteText(const char* txt);
	void kwriteFormatV(const char* txt,va_list args);
	void kwriteFormat(const char *txt, ...);


	static void ShutdownHandler (void);
private:
	// do not change this order
	CActLED				m_ActLED;
	CKernelOptions		m_Options;
	CDeviceNameService	m_DeviceNameService;
	CScreenDevice		m_Screen;
	CSerialDevice		m_Serial;
	CExceptionHandler	m_ExceptionHandler;
	CInterruptSystem	m_Interrupt;
	CTimer				m_Timer;
	CLogger				m_Logger;
	CUSBHCIDevice		m_USBHCI;
	CEMMCDevice			m_EMMC;
	FATFS				m_FileSystem;
	C2DGraphics			m_2DGraphics;
	CSpinLock			m_guiSpinLock;
	volatile TShutdownMode m_ShutdownMode;
	
	unsigned	m_guiReady;
private:
	void RunCore0(void);
	void RunCore1(void);
	void RunCore2(void);
	void RunCore3(void);
	
	void IPIHandlerCore0(unsigned nIPI);
	void IPIHandlerCore1(unsigned nIPI);
	void IPIHandlerCore2(unsigned nIPI);
	void IPIHandlerCore3(unsigned nIPI);
};

#endif
