#
# Makefile
#

CIRCLEHOME = ../..

OBJS	= main.o kernel.o system.o runtime.o gui/gui.o arch/stdlib.o

EXTRACLEAN = gui/gui.o gui/*.bak *.bak arch/*.o asm/*.o game/*/*.o

LIBS	= $(CIRCLEHOME)/addon/fatfs/libfatfs.a \
	  $(CIRCLEHOME)/addon/SDCard/libsdcard.a \
	  $(CIRCLEHOME)/lib/usb/libusb.a \
	  $(CIRCLEHOME)/lib/input/libinput.a \
	  $(CIRCLEHOME)/lib/fs/libfs.a \
	  $(CIRCLEHOME)/lib/libcircle.a

include ../Rules.mk

-include $(DEPS)
