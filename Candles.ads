--*******************************************************************
--  File Name	  : Candles.ads
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
package CANDLES is

	type Candle_Number_t is new Positive range 1..8;
	type Candle_Array_t is array (Candle_Number_t) of Unsigned_8;

	-- set by Timer ISR; pragma VOLATILE required...
	BlinkCtrs : array (Candle_Number_t) of Unsigned_16;
	pragma VOLATILE(BlinkCtrs);

	-- Candle Major Modes
	type Candle_Modes_t is (Disabled, Lighting, Burning, Burnout);
	
	-- Candle lit states
	type Lit_State_t is (UnLit, Lit);

   type LED_State_t is 
     record
      E_D_State 	    : Candle_Modes_t	:= Disabled; -- Disabled until "lit"
	   prev_LEDLit	    : Lit_State_t  	:= UnLit;
	   LEDLit    	    : Lit_State_t		:= UnLit;
      CurState  	    : Unsigned_8		:= 0;  --{varies for flicker profile}
      LED_Off_Seconds : Unsigned_32; --Set based on NORM/DEMO Switch
   end record ;

   LED_States : array(Candle_Number_t) of LED_State_t;

	procedure Initialize;
	
	procedure Process_All;
	
end CANDLES;