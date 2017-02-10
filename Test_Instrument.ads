--*******************************************************************
--  File Name	  : Test_Instrument.ads
--  Version	 : 1.0
--  Description  : Provides access to test signals
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 6.12
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 01 Oct 2014
--					  :	Created for Menorah timing tests.
--*******************************************************************
with ATmega2560; -- This is supplied by GNAT
with INTERFACES;
package TEST_INSTRUMENT is

	package AT2560 renames ATmega2560;
	

	procedure Initialize_Output_Port
		(Port : INTERFACES.Unsigned_8; Value : INTERFACES.Unsigned_8);

	procedure Set_Output 
		(Port : INTERFACES.Unsigned_8 , Pin : INTERFACES.Unsigned_8);
		
	procedure Clear_Output
		(Port : INTERFACES.Unsigned_8 , Pin : INTERFACES.Unsigned_8);
	
	

end TEST_INSTRUMENT;