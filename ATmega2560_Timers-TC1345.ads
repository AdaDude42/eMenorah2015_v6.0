--*******************************************************************
--  File Name	  : TC1345.ads
--  Version	 	  : 1.0
--  Description  : AVR TIMER/Counter 1,3,4,5 Setup API
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNAT GPL-2012 avr_cross
--  IDE          : Atmel AVR Studio 6.1
--  Programmer   : AVR STK-600 Bootloader
--  Last Updated : 27 June 2014
--*******************************************************************

with Ada.Unchecked_Conversion;
with SYSTEM; use SYSTEM;
with INTERFACES; use INTERFACES;

package ATmega2560_Timers.TC1345 is 
	-- for ATmega2560 16-bit Timer/Counters 1,3,4 and 5
	
	subtype TC_Choices is ATmega2560_Timers.Timer_Counters range TC1..TC5;

	type COM_Mode_Choices is (COMA, COMB, COMC, COM_NOT_USED);
	for  COM_Mode_Choices use (0,1,2,3);
	
	-- COM Modes 
	type COM_Mode_t is new Natural range 0..3;
	for  COM_Mode_t'Size use 2;

	-- Clk_IO Prescaling for TC0 and TC1, 3, 4, 5. TC2 is different...
	type Clk_Prescale_Values is 
	   (PS0, PS1, PS8, PS64, PS256, PS1024, EXT_FE, EXT_RE); 
	-- 0=Stopped, 1=No Scaling...EXT_FE=Ext Clk, Falling Edge; _RE=Rising Edge
	
   for Clk_Prescale_Values'size use 3;
	
	-- T/C Top values for each Timer...
	TC1_Top : Unsigned_16;
	TC3_Top : Unsigned_16;
	TC4_Top : Unsigned_16;
	TC5_Top : Unsigned_16;
	
	
	subtype COM_Array_Index is Natural range 0..1;
	type COM_Bits_Array_t is array(COM_Array_Index) of Bit;
	
	-- For n=[1,3,4,5]
	type TCCRnA_Reg_t is 
	  record
		WGMn1_0  : Two_Bits;
		COMnC1_0 : COM_Mode_t;
		COMnB1_0 : COM_Mode_t;
		COMnA1_0 : COM_Mode_t;
	end record;
	
	for TCCRnA_Reg_t use
	  record
		WGMn1_0  at 0 range 0..1;
		COMnC1_0 at 0 range 2..3;
		COMnB1_0 at 0 range 4..5;
		COMnA1_0 at 0 range 6..7;
	end record;
	
	for TCCRnA_Reg_t'Size      use 8;
	for TCCRnA_Reg_t'Bit_Order use System.Low_Order_First;

	type TCCRnB_Reg_t is 
	  record
		CS_Bits : Clk_Prescale_Values;
		WGMn3_2 : Two_Bits;
		Unused  : Bit;
		ICESn   : Bit;
		ICNCn   : Bit;
	end record;
	
	for TCCRnB_Reg_t use
     record
		CS_Bits at 0 range 0..2;
		WGMn3_2 at 0 range 3..4;
		Unused  at 0 range 5..5;
		ICESn   at 0 range 6..6;
		ICNCn   at 0 range 7..7;
	end record;	
	
	for TCCRnB_Reg_t'Size      use 8;
	for TCCRnB_Reg_t'Bit_Order use System.Low_Order_First;
	
	
	---------------------  Interface procedures for setups  ---------------
	
	subtype WGM_Values_t is Nibble range 0..15; -- Different from TC0_2 
	
	-- Waveform Generation Modes (WGM)
		
	type WGM_Descriptor_Values_t is 
		(Normal, PC_8b, PC_9b, PC_10b,CTC_OCRnA, FP_8b, FP_9b, FP_10b, 
	    PFC_ICRn, PFC_OCRnA, PC_ICRn, PC_OCRnA, CTC_ICRn, RES, 
		 FP_ICRn, FP_OCRnA);
		 
	for WGM_Descriptor_Values_t use
		(0, 1,  2,  3,  4,  5, 6, 7,
		 8, 9, 10, 11, 12, 13,
		 14, 15);
	
	type WGM_Desc_Values_Ay_t is 
		array(WGM_Values_t) of WGM_Descriptor_Values_t;
	
	WGM_Desc_Values : constant WGM_Desc_Values_Ay_t :=
								-- Mode of Operation 			TOP	  Update		TOVn 
								--								 		Value  of OCRnx:	Flag	
								--															  Set On:
	(	 0 => Normal,		-- Normal 							0xFFFF Immediate	MAX
		 1 => PC_8b,		-- PWM, Phase Correct, 8-bit 	0x00FF   TOP		BOTTOM
		 2 => PC_9b,		-- PWM, Phase Correct, 9-bit	0x01FF 	TOP 		BOTTOM
		 3 => PC_10b,		-- PWM, Phase Correct, 10-bit 0x03FF 	TOP 		BOTTOM
		 4 => CTC_OCRnA,	-- CTC 								OCRnA  Immediate 	MAX
		 5 => FP_8b,		-- Fast PWM, 8-bit 				0x00FF 	BOTTOM 	TOP
		 6 => FP_9b,		-- Fast PWM, 9-bit 				0x01FF 	BOTTOM 	TOP
		 7 => FP_10b,		-- Fast PWM, 10-bit 				0x03FF 	BOTTOM 	TOP
		 8 => PFC_ICRn,	-- PWM, Phase and Frq Correct	ICRn 		BOTTOM 	BOTTOM
		 9 => PFC_OCRnA,	-- PWM, Phase and Frq Correct	OCRnA 	BOTTOM 	BOTTOM
		10 => PC_ICRn,		-- PWM, Phase Correct 			ICRn 		TOP 		BOTTOM
		11 => PC_OCRnA,	-- PWM, Phase Correct 			OCRnA 	TOP 		BOTTOM
		12 => CTC_ICRn,	--	CTC 								ICRn 	 Immediate	MAX
		13 => RES,			-- (Reserved) 						  – 		  – 		 –
		14 => FP_ICRn,		-- Fast PWM 						ICRn 		BOTTOM 	TOP
		15 => FP_OCRnA);	-- Fast PWM 						OCRnA 	BOTTOM 	TOP
		
		
	type WGM_Nibble is
	  record
		Bits_1_0 : Two_Bits;
		Bits_3_2 : Two_Bits;
	end record;
	
	procedure Set_ClkIO_Prescaler
		(Timer_Counter : TC_Choices; PS_Val : Clk_Prescale_Values);
		
	-- Three ways to set WGM:
							
	procedure Set_WGM -- by using registers and mode number
		(TCCRA : in out Interfaces.Unsigned_8; 
		 TCCRB : in out Interfaces.Unsigned_8; 
		 WGM_Setting : WGM_Values_t);
		 
	procedure Set_WGM -- by using the mode number
		(Timer_Counter : TC_Choices; WGM_Setting : WGM_Values_t);
		
	procedure Set_WGM -- by using the mode descriptor
		(Timer_Counter : TC_Choices; WGM_Setting : WGM_Descriptor_Values_t);
		 

	procedure Set_COM_Mode 
		(TCCRA : in out Interfaces.Unsigned_8; 
		 COM_Mode_Selection : COM_Mode_Choices;
		 COM_Mode : COM_Mode_t);
		 

	--Example TCCR1A: COM1A1 COM1A0 COM1B1 COM1B0 COM1C1 COM1C0 WGM11 WGM10
	-- For n=[1,3,4,5]
	
	-- EXAMPLE Calls: Just change Register-TC number to select a different T/C
	-- 	e.g, change TCCR3A to TCCR4A to use T/C 4. Change PS,WGM,COM as req'd
	--
	--TC1345.Set_ClkIO_Prescaler
	--	(Timer_Counter : TC_Choices; PS_Val : Clk_Prescale_Values);
	--	
	--TC1345.Set_WGM_Mode 
	--	(TCCRA => ATmega2560.TCCR3A, TCCRB => ATmega2560.TCCR3B, 
	--  WGM_Setting => 8);
	--
	--TC1345.Set_COM_Mode 
	--	(TCCRA => ATmega2560.TCCR3A, 
	--  COM_Mode_Selection => TC1345.COMA, COM_Mode => 2);
	--
	
	-- New All-in-One setup:
	procedure Set_TC_Mode
		(TC : TC_Choices; WGM_Setting : WGM_Descriptor_Values_t; 
	    COM_Mode_Selection : COM_Mode_Choices; COM_Mode : COM_Mode_t;
		 PS_Val : Clk_Prescale_Values);
								
private

	-- Set constant for Clk_IO value
	Clk_IO : constant 		:= 1_000_000; -- 1MHz clock
	Clk_IO_Div_40 : Natural := Natural(Clk_IO/40); -- support 16-bit comps

	-- Local copies of the Prescale Values for use in internal computations
	TC1_PS_Val : Natural;	
	TC3_PS_Val : Natural;	
	TC4_PS_Val : Natural;
	TC5_PS_Val : Natural;
	
	
end ATmega2560_Timers.TC1345;
	