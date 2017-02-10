--*******************************************************************
--  File Name	  : Candles-PWM_Ada.adb
--  Version	 : 1.0
--  Description  : Implements Candle control operations
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 27 Sep 2014
--					  :	Added header to file.
--	  				  : 07-Aug-2014
--					  :   Derived from Proto1f-PCB\pwm.c
--*******************************************************************


--#include "..\h\p18f4520.h"
--#include "..\h\pwm.h"

with ATmega2560;
package body Candles.PWM_Ada is

	package A2560 renames ATmega2560;
	
	faderEnabled : Boolean := TRUE;

	pwmCounter : Duty_Cycle_Range := 0;
	pragma VOLATILE(pwmCounter);

	PORTBTemp : Unsigned_8;
	pragma VOLATILE(PORTBTemp);

----------------------------------  doPWM  ----------------------------------
pragma OPTIMIZE(Time);
procedure doPWM is -- to be called at 1.0 msec period

begin

	pwmCounter:= pwmCounter+1; 
	if (pwmCounter = 19) then 
     pwmCounter := 0; -- 20*1.0 msec => 50Hz PWM period
	end if;

  for i in Candle_Number_t'Range loop

   fadeCounter(i) := fadeCounter(i) + 1;
	
	if (fadeCounter(i) = LED_Fader(i)) then 	
		fadeCounter(i) := 0;
	 end if;	
	
   if (fadeCounter(i) = 0) then

      if (ledActualBrightness(i)  > ledTargetBrightness(i) ) then
          ledActualBrightness(i) := ledActualBrightness(i) - 1; 
      elsif
         (ledActualBrightness(i)  < ledTargetBrightness(i) ) then
          ledActualBrightness(i) := ledActualBrightness(i) + 1;
		end if;
		
		if (LED_States(i).LEDLit = Lit) and then 
		   (ledActualBrightness(i)  < MinLedTargetBrightness ) then
		    ledActualBrightness(i)  := MinLedTargetBrightness; 
		end if;
		
	end if;

     -- Perform the PWM brightness control
     if (ledActualBrightness(i) > pwmCounter) then
       PORTBTemp := PORTBTemp AND LED_On_Bits(i); --Clr bit if it should be on
     else
       PORTBTemp := PORTBTemp OR LED_Off_Bits(i);--Set bit if it should be Off
	  end if;

	end loop; -- i=1..8
	
   A2560.PORTB := PORTBTemp; -- Set the output port bits
	--DBG: A2560.PORTB := 16#00#;  -- DBG; turns all LEDs ON
	
exception
	when others =>
		null;

end doPWM;


end Candles.PWM_Ada;
