--*******************************************************************
--  File Name	  : Timer3_Clock.ads
--  Version	 : 1.0
--  Description  : Uses Timer3 at 10msec period for Timeout controls
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 27 Sep 2014
--					  :	Added header to file.
--*******************************************************************
with INTERFACES; use INTERFACES;
package TIMER3_CLOCK is

	procedure Update; -- Call at 10msec period
	
	type Time_t is 
	 record
	  Tenth_Sec : Natural range 0..9  := 0;
	  Second    : Natural range 0..59 := 0;
	  Minute    : Natural range 0..59 := 0;
	  Hour      : Natural range 0..23 := 0;
	 end record;
	
	function Time return Time_t;
	
	function Elapsed_Minutes return INTERFACES.Unsigned_32;
	function Elapsed_Seconds return INTERFACES.Unsigned_32;
	function Current_Seconds return Natural;

end TIMER3_CLOCK;
