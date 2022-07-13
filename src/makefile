WLA-Z80 = wla-z80
WLALINK = wlalink
BMP2TILE = bmp2tile
GENERATED_FILES = *.sms *.o *.makefile *.aplib *.bin

default: sms-240-tester.sms

# We get WLA DX to generate the dependencies list for our source
auto.makefile: sms-240-tester.sms.asm
	$(WLA-Z80) -M -o sms-240-tester.sms.o $^ > $@

include auto.makefile

# Graphics conversion
%.tiles.aplib: %.png
	 bmp2tile "$<" -savetiles "$@"

%.tilemap.aplib: %.png
	 bmp2tile "$<" -savetilemap "$@"

%.palette.bin: %.png
	 bmp2tile "$<" -savepalette "$@"

sms-240-tester.sms.o: sms-240-tester.sms.asm
	$(WLA-Z80) -o $@ $<

sms-240-tester.sms: sms-240-tester.sms.o linkfile
	$(WLALINK) -d -r -v -S -A linkfile $@

clean:
	del $(GENERATED_FILES)