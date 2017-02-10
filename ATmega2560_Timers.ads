--***************************************************************************
--  File Name	  : ATmega2560_Timers.ads
--  Version	 	  : 1.0
--  Description  : AVR TIMER/Counter Setup API Top Unit
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNAT GPL-2012 avr_cross
--  IDE          : Atmel AVR Studio 6.1
--  Programmer   : AVR STK-600 Bootloader
--  Last Updated : 11 July 2014
--					  : 21 Mar 2015 -- Switch to BIT_PARTS for types.
--***************************************************************************

with INTERFACES; use INTERFACES;
with BIT_PARTS; use BIT_PARTS;

package ATmega2560_Timers is -- for ATmega2560 Timer/Counters

	type Timer_Counters is (TC0, TC2, TC1, TC3, TC4, TC5);

-- Child package TC1345 is for those Timer/Counters.
-- Child package TC0-2  
--		is for TC0 and TC2, which have different register structures.


end ATmega2560_Timers;