--*******************************************************************
--  File Name	  : main.adb
--  Version	 : 1.0
--  Description  : AVR TIMERs for PWM and Exec loop
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 5 July 2014
--					  :	Adding Ada.Numerics.Discrete_Random;
--					  : 6 Aug 2014
--               :	Moved PWM code to Do_PWM package
--					  : 27 Sep 2014
--               :	Added useage of Timer3 and T3_Clock pkgs
--*******************************************************************

with INTERFACES; use INTERFACES;
with INTERFACES.C; 
with SYSTEM.MACHINE_CODE; use SYSTEM.MACHINE_CODE;

with ATmega2560; use ATmega2560; -- This is supplied by GNAT-GPL2012
-- See dir=C:\GNAT\2012\share\examples\gnat-cross\avr\atmega2560
-- File= atmega2560.ads; Include or copy to local Dir...

-- These are my APIs for Timers
with ATmega2560_Timers;			-- Parent for all Timers
with ATmega2560_Timers.TC1345;-- Child for Timers 1,3,4 and 5
with ATmega2560_Timers.TC1345.TIMER1; -- Special Child for Timer 1
with ATmega2560_Timers.TC1345.TIMER3; -- Special Child for Timer 3

with RANDOM;-- This is derived from Internet Example- Not GNAT
with Ada.Unchecked_Conversion;

with BVM; -- BATT_VOLTAGE_MONITOR;
with CANDLES;

with TIMER3_CLOCK;

with CTRLS_and_INDICATORS;

with TIMED_INTERVAL_01s;

with ADC;

procedure main is

	package A2560		renames ATmega2560;
	package A2560T		renames ATmega2560_Timers;
	package TC1345		renames ATmega2560_Timers.TC1345;
	package TIMER1		renames ATmega2560_Timers.TC1345.TIMER1;
	package TIMER3		renames ATmega2560_Timers.TC1345.TIMER3;
	package T3_CLOCK  renames TIMER3_CLOCK;
	package TI01s		renames TIMED_INTERVAL_01s;
	package C_and_I 	renames CTRLS_and_INDICATORS;
	
-- Ada.Numerics not supported by GPL2012-avrCross.

--	subtype U16_Rand_t is Interfaces.Unsigned_16 range 32 .. TC1345.TC3_Top;

--	package Unsigned_16_Random is new 
--		Ada.Numerics.Discrete_Random((U16_Rand);
--	package U16_Rand renames Unsigned_16_Random;
	

-----------------------------------------------------------------------------

--pragma OPTIMIZE(Space);

begin

--TEST-RMV begin
		A2560.DDRE  := 16#FF#; -- Setup PORTE to all Outputs for Test Monitoring
		A2560.PORTE := 16#00#; -- Clear all outputs
--TEST_RMV end


----------------------------------- Initialize  -----------------------------


--------------------------------  Setup TC1 & TC3  --------------------------

	TIMER1.Initialize; -- will interrupt at  1msec intervals...
	TIMER3.Initialize; -- will interrupt at 10msec intervals...calls TI01s

-------------------------------  External Interfaces  -----------------------


	A2560.DDRB  := 16#FF#; --A2560.DDRB_DDB5; -- Set PB5 to output mode
	A2560.PORTB := A2560.PORTB_PORTB5 OR 2#1101_1111#;

	
	A2560.DDRH  := 16#FF#; -- PORTH Outputs for BVM Indicator on LEDs
	A2560.PORTH := NOT(16#C3#); -- Starting indicator
	
	-- Set unused PORTs' Weak Pullups to reduce current draw; 
	--  they have defaulted to Inputs at power up
	A2560.PORTA := 16#FF#;
	A2560.PORTF := 16#FE#; -- PF0 is used for ADC Input by BVM
	A2560.PORTG := 16#3F#; -- Pins PG0..PG5 (PG6, PG7 not present on device)
	A2560.PORTJ := 16#FF#;
	A2560.PORTK := 16#FF#;
	A2560.PORTL := 16#FF#;
	
	C_and_I.Initialize;
		
	ADC.Initialize;
	
	BVM.Initialize; -- Uses ADC functions and ADC0 input...

	CANDLES.Initialize; -- Reads NORM/DEMO switch too
	


----------------------------------  Start Main Loop  ------------------------
	

	Infinite: loop

-----------------------------------  Using TC1  -----------------------------

		if TIMER1.Int_Count >=1 then
		
			--ATmega2560.PORTB := 16#00#;  -- DBG turns all LEDs ON
	
			--ATmega2560.PORTB := ATmega2560.PORTB XOR ATmega2560.PORTB_PORTB5;

--TEST-RMV begin
		A2560.PORTE := A2560.PORTE OR 2#0000_0001#; -- Set PE0 for Main-Candles
--TEST_RMV end
	
			TIMER1.Reset_Int_Count;
			CANDLES.Process_All;
			
--TEST-RMV begin
		A2560.PORTE := A2560.PORTE AND 2#1111_1110#; --Clr PE0 for Main-Candles
--TEST_RMV end
		
		end if;
---------------------------------  Using T3_CLOCK  ---------------------------

		if (T3_CLOCK.Time.Second >= 15) and (T3_CLOCK.Time.Tenth_Sec > 5) then
		
			--ATmega2560.PORTB := 16#00#;  -- DBG turns all LEDs ON
	
			--ATmega2560.PORTB := ATmega2560.PORTB AND 2#1101_1111#; -- PB5 ON
			null;
			
		end if;

		if (T3_CLOCK.Time.Minute >= 5) and (T3_CLOCK.Time.Tenth_Sec > 5) then
		
			--ATmega2560.PORTB := 16#00#;  -- DBG turns all LEDs ON

			--ATmega2560.PORTB := ATmega2560.PORTB AND 2#1111_0111#; -- PB3 ON
			null;
			
		end if;

----------------------------  Using TIMED_INTERVAL_01s  ----------------------
-- Calls made from Timer3 Interrupt Handler to

		--TIMED_INTERVAL_01s.Increment;
		--CTRLS_and_INDICATORS.Update_Flashing_Outputs;
 
	
-------------------------  Batt_Voltage_Monitor Processing -------------------
	
		BVM.Run_BVM;
	
------------------------------------------------------------------------------	
		
	end loop Infinite;

  
end main;

