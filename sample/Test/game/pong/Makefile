#
# Makefile
#

CIRCLEHOME = ../../../..
OBJS	= pong.o

EXTRACLEAN = pong.o pong.img pong.elf pong.lst pong.map

LIBS	= 


include ../Rules.mk

LOADADDR = 0x900000
-include $(DEPS)

pong : $(OBJS)  ../../app.ld
	@echo "    creating pong.img"

	@$(LD)  -o pong.elf \
		-Map pong.map \
		--section-start=.text=$(LOADADDR) \
		-T ../../app.ld \
		$(OBJS) \
		--just-symbols ../../kernel8-rpi4.elf 

	@echo "    DUMP pong.lst"
	@$(PREFIX)objdump -d pong.elf | $(PREFIX)c++filt > pong.lst

	@echo "    COPY pong.img"
	@$(PREFIX)objcopy pong.elf -O binary pong.img

	@echo  -n "    WC    pong.img => "
	@wc -c < pong.img
