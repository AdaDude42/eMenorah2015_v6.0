#
# 2014-07-10: Added OBJDIR and a few necessary path mods to support it.
#
#INCLUDE="C:\GNAT\2012\share\examples\gnat-cross\avr\atmega2560"
INCLUDE="/cygdrive/c/GNAT/2012/share/examples/gnat-cross/avr/atmega2560"
# for atmega2560.ads
# Using "" "xxx" makes it work for both CMD-MinGW and CygWin.
#
#OBJDIR="C:\GNAT\2012\MyAVR\Dev\v3\obj"
OBJDIR=../obj
#BINDIR="C:\GNAT\2012\MyAVR\Dev\v3\bin"
BINDIR=../bin
#
CRT1=crt1-atmega2560
#
all: main.hex

main.elf: $(CRT1).o rand8_16_32.o force
	avr-gnatmake -I$(INCLUDE) -D $(OBJDIR) main -o $@ -v -O2 -mmcu=avr6 --create-map-file \
	--RTS=zfp -largs $(OBJDIR)\/$(CRT1).o $(OBJDIR)\/rand8_16_32.o -nostdlib \
	-lgcc -Wl,-mavr6 -Tdata=0x00800200

main.hex: main.elf
	avr-objcopy -O ihex $< $@
	mv main.elf $(BINDIR)
	mv main.hex $(BINDIR)
	mv main.map $(BINDIR)

$(CRT1).o: $(CRT1).S
	avr-gcc -c -mmcu=avr6 -o $@ $<
	mv crt1-atmega2560.o $(OBJDIR)
	
rand8_16_32.o: rand8_16_32.c
	avr-gcc -c -mmcu=avr6 -o $@ $<
	mv rand8_16_32.o $(OBJDIR)
	
clean:
	$(RM) $(OBJDIR)\/*.o $(OBJDIR)\/*.ali 
	$(RM) $(BINDIR)\/*.hex $(BINDIR)\/*.elf $(BINDIR)\/*.map
	$(RM) 	       *.o 	         *.elf	          *.hex 	*.map        *.ali


force:
