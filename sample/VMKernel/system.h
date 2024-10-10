#define DEPTH	32
#ifndef _system_h
#define _system_h

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



class CSystem : public CMultiCoreSupport
{
public:
	CSystem();
	~CSystem (void);
	
	
	
	boolean PreInitialize (void);
	TShutdownMode RunMain (void);
	
	void InitCommon(CUSBHCIDevice* usbhci,CDeviceNameService *deviceNameService);
	
	void InitCore1();
	void Run(unsigned nCore);
	
	void IPIHandler(unsigned nCore,unsigned nIPI);
	void IPIHandlerCore0(unsigned nIPI);
	void IPIHandlerCore1(unsigned nIPI);
	void IPIHandlerCore2(unsigned nIPI);
	void IPIHandlerCore3(unsigned nIPI);
	
	
	
	void MouseDetect();
	void KeyboardDetect();
	
	void MouseEventHandler (TMouseEvent Event, unsigned nButtons, unsigned nPosX, unsigned nPosY, int nWheelMove);
	
	static void ShutdownHandler (void);
	static void MouseEventStub (TMouseEvent Event, unsigned nButtons, unsigned nPosX, unsigned nPosY, int nWheelMove);
	static void MouseRemovedHandler (CDevice *pDevice, void *pContext);
	static void KeyboardRemovedHandler (CDevice *pDevice, void *pContext);
	static void KeyPressedHandler (const char *pString);
	static void KeyStatusHandlerRaw (unsigned char ucModifiers, const unsigned char RawKeys[6]);

	
private:
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
	CMouseDevice 		* volatile m_pMouse;
	CUSBKeyboardDevice  * volatile m_pKeyboard;
	
	
	
	unsigned	m_mousePosX;
	unsigned	m_mousePosY;
	unsigned 	m_mouseLeft;
	unsigned	m_mouseRight;
	unsigned	m_mouseMiddle;
	unsigned 	m_mouseWheel;
	unsigned	m_guiReady;
	
	
	static CSystem *Instance;
private:
	void RunCore0(void);
	void RunCore1(void);
	void RunCore2(void);
	void RunCore3(void);
	
	
	
};
#endif