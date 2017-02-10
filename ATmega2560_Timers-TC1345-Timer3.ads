--*******************************************************************
--  File Name	  : ATmega2560_Timers-TC1345-TIMER3.ads
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

package ATmega2560_Timers.TC1345.TIMER3 is

	-- Interrupt handler for Timer3
	
	procedure Initialize;
	
	function Int_Count return Natural;
	
	procedure Reset_Int_Count;
	
end ATmega2560_Timers.TC1345.TIMER3;

