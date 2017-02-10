--*******************************************************************
--  File Name	  : ATmega2560_Timers-TC1345-TIMER1.adb
--  Version	 : 1.0
--  Description  : Uses Timer1 at 1msec period for Candle processing
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

with CANDLES.PWM_Ada;

package body ATmega2560_Timers.TC1345.TIMER1 is

	package A2560  	 renames ATmega2560;
	package A2560T 	 renames ATmega2560_Timers;
	package BP renames BIT_PARTS;
	package TC1345 	 renames ATmega2560_Timers.TC1345;
	
	package PWM renames CANDLES.PWM_Ada;

--	PB5 : Unsigned_8 := 2#0010_0000#;
	
	Interrupt_Count : Natural := 0;
	pragma Volatile (Interrupt_Count);

	-- Interrupt handler for Timer1
	-- Declare an interrupt handler for Timer1 capture event.
	
   procedure Timer1_Interrupt;
   pragma Machine_Attribute (Timer1_Interrupt, "signal");
   pragma Export (C, Timer1_Interrupt, "__vector_timer1_compa");
	-- text above in "" is CASE SENSITIVE!

   procedure Timer1_Interrupt is
   begin

--TEST-RMV begin
		A2560.PORTE := A2560.PORTE OR 2#0000_0010#; -- Set PE1 for Timer1
--TEST_RMV end


		if Interrupt_Count < Natural'Last then
		   Interrupt_Count := Interrupt_Count + 1;
		else
			Interrupt_Count := 0;
		end if;
		
		PWM.doPWM;
		
--TEST-RMV begin
		A2560.PORTE := A2560.PORTE AND 2#1111_1101#; -- Clear PE1 for Timer1
--TEST_RMV end

   end Timer1_Interrupt;

	
	procedure Initialize is 
	begin	
	
		Set_TC_Mode -- Normal Port Operation on PB5; Int on COMPA
		(TC => A2560T.TC1, WGM_Setting => TC1345.CTC_OCRnA,  
	    COM_Mode_Selection => TC1345.COMA, COM_Mode => 0, -- Normal PORT5 mode.
		 PS_Val => TC1345.PS1); -- 1 tick = 1-usec
		
		TC1_Top := Unsigned_16( 1000); -- 1000 ticks = 1 msec
		OCR1AH  := Unsigned_8(BP.Low_Byte_Mask AND Shift_Right(TC1_Top,8));
		OCR1AL  := Unsigned_8(BP.Low_Byte_Mask AND TC1_Top);
		 
		TIMSK1 := TIMSK1 + TIMSK1_OCIE1A;

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
	

end ATmega2560_Timers.TC1345.TIMER1;

