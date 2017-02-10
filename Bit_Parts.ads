--***************************************************************************
--  File Name	  : Bit_Parts.ads
--  Version	 	  : 1.0
--  Description  : AVR TIMER/Counter Setup API Top Unit
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNAT GPL-2012 avr_cross
--  IDE          : Atmel AVR Studio 6.1
--  Programmer   : AVR STK-600 Bootloader
--  Last Updated : 16 Mar 2015
--***************************************************************************

with INTERFACES; use INTERFACES;

package BIT_PARTS is

	------------------  Bit-oriented declarations for Registers  -------------
	
	type Bit is new Unsigned_8 range 0..1;
	for  Bit'Size use 1;
	
	type Two_Bits is new Unsigned_8 range 0..3;
	for  Two_bits'Size use 2;
	
	type Triad is new Unsigned_8 range 0..7;
	for  Triad'Size use 3;
	
	type Nibble is new Unsigned_8 range 0..15;
	for  Nibble'Size use 4;
	
	High_Byte_Mask : constant Unsigned_16 := 16#FF00#;
	Low_Byte_Mask  : constant Unsigned_16 := 16#00FF#;
	Two_Bit_Mask   : constant Unsigned_16 := 16#0003#;

	-- Arrays of bit indicators for turning bits in PORTn On / Off
	-- Output = 1 means Bit is ON.
	
	type Bit_Number_t is new Natural range 0..7;
	
	type Bit_Array_t is array (Bit_Number_t) of Bit;
	pragma PACK (Bit_Array_t);
	Bit_Array : Bit_Array_t := (0,1,0,1,0,1,0,1);
	
	type Bits_Bytes_Array_t is array (Bit_Number_t) of Unsigned_8;

	High_Bits : constant Bits_Bytes_Array_t :=
	
  (2#00000001#, 2#00000010#, 2#00000100#, 2#00001000#,
   2#00010000#, 2#00100000#, 2#01000000#, 2#10000000# );

	Low_Bits : constant Bits_Bytes_Array_t :=
  (2#11111110#, 2#11111101#, 2#11111011#, 2#11110111#,
   2#11101111#, 2#11011111#, 2#10111111#, 2#01111111# );
	
end BIT_PARTS;
	