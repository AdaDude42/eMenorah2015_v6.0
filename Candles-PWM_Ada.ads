--*******************************************************************
--  File Name	  : Candles-PWM_Ada.ads
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

with INTERFACES; use INTERFACES;

package Candles.PWM_Ada is

	-- Globals for PWM
	MAX_BRIGHT : constant Unsigned_8 := 20;

	subtype Duty_Cycle_Range is Unsigned_8 range 0..MAX_BRIGHT;
	type LED_Brightness_Array_t is array(Candle_Number_t) of Duty_Cycle_Range;

	LedTargetBrightness 	: LED_Brightness_Array_t := (others => 0);
	pragma VOLATILE (LedTargetBrightness);
	
	LedActualBrightness 	: LED_Brightness_Array_t := (others => 0);
	pragma VOLATILE (LedActualBrightness);
	
	MinLedTargetBrightness : Duty_Cycle_Range := 0; 
	-- Set to 0 at startup; modified to > 0 when flickering

	LED_Fader   : Candle_Array_t := (240,250,206,207,206,205,240,200);
	--one per LED; adjust randomly
	
	FadeCounter	: Candle_Array_t := (others => 0);
	pragma VOLATILE (FadeCounter);
		

-- Array of bit indicators for turning bits in PORTB On / Off
-- Output = 0 means LED is ON.

	LED_Off_Bits : constant Candle_Array_t :=
	
  (2#00000001#, 2#00000010#, 2#00000100#, 2#00001000#,
   2#00010000#, 2#00100000#, 2#01000000#, 2#10000000# );

	LED_On_Bits : constant Candle_Array_t :=
  (2#11111110#, 2#11111101#, 2#11111011#, 2#11110111#,
   2#11101111#, 2#11011111#, 2#10111111#, 2#01111111# );


	procedure doPWM;  -- to be called at 1.0 msec period


end Candles.PWM_Ada;