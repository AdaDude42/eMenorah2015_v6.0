--*******************************************************************
--  File Name	  : ATmega2560_Timers-TC1345-TIMER3.adb
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

with ATmega2560; use ATmega2560; -- This is supplied by GNAT
with ATmega2560_Timers;
with ATmega2560_Timers.TC1345;
with BIT_PARTS;
with System.Machine_Code; use System.Machine_Code;

with Timer3_Clock;

with TIMED_INTERVAL_01s;
with CTRLS_and_INDICATORS;

package body ATmega2560_Timers.TC1345.TIMER3 is

	package A2560  	 renames ATmega2560;
	package A2560T 	 renames ATmega2560_Timers;
	package BP 			 renames BIT_PARTS;
	package TC1345 	 renames ATmega2560_Timers.TC1345;
	package T3_Clock	 renames Timer3_Clock;

	PB5 : Unsigned_8 := 2#0010_0000#;
	
	
	Interrupt_Count : Natural := 0;
	pragma Volatile (Interrupt_Count);

	-- Interrupt handler for Timer3
	--  Declare an interrupt handler for timer3 capture event.
	
   procedure Timer3_Interrupt;
   pragma Machine_Attribute (Timer3_Interrupt, "signal");
   pragma Export (C, Timer3_Interrupt, "__vector_timer3_compa");
	-- text above in "" is CASE SENSITIVE!

   procedure Timer3_Interrupt is
   begin
--TEST-RMV begin
		A2560.PORTE := A2560.PORTE OR 2#0000_1000#; -- Set PE3 for Timer3
--TEST_RMV end

		T3_Clock.Update;
		
		TIMED_INTERVAL_01s.Increment;
		CTRLS_and_INDICATORS.Update_Flashing_Outputs;
		
--TEST-RMV begin
		A2560.PORTE := A2560.PORTE AND 2#1111_0111#; -- Clear PE3 for Timer3
--TEST_RMV end

   end Timer3_Interrupt;

	
	procedure Initialize is 
	begin	
	
		Set_TC_Mode -- Normal Port Operation on PB5; Int on COMPA
		(TC => A2560T.TC3, WGM_Setting => TC1345.CTC_OCRnA,  
	    COM_Mode_Selection => TC1345.COMA, COM_Mode => 0,
		 PS_Val => TC1345.PS1); -- 1 tick = 1-usec
		
		TC3_Top := Unsigned_16( 10_000); -- 10_000 ticks = 10 msec
		OCR3AH  := Unsigned_8(BP.Low_Byte_Mask AND Shift_Right(TC3_Top,8));
		OCR3AL  := Unsigned_8(BP.Low_Byte_Mask AND TC3_Top);
		 
		TIMSK3 := TIMSK3 + TIMSK3_OCIE3A;

      Asm ("sei", Volatile => True);
		
	exception
		when others =>
			null;
		
	end Initialize;
	
	procedure Reset_Int_Count is
	begin
		Interrupt_Count := 0;
	end Reset_Int_Count;
	
	function Int_Count return Natural is
	begin
		return Interrupt_Count;
	end Int_Count;
	

end ATmega2560_Timers.TC1345.TIMER3;

