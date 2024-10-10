#
# Makefile
#

converttool: converttool.c
	@echo "  TOOL  $@"
	@x86_64-linux-gnu-gcc-11 -o converttool converttool.c -B/usr/bin/x86_64-linux-gnu-gcc/

clean:
	@echo "  CLEAN " `pwd`
	@rm -rf converttool
