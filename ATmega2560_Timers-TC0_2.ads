--*******************************************************************
--  File Name	  : ATmega2560_Timers-TC0_2.ads
--  Version	 	  : 1.0
--  Description  : AVR TIMER/Counter Setup API for TC0 & TC2
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNAT GPL-2012 avr_cross
--  IDE          : Atmel AVR Studio 6.1
--  Programmer   : AVR STK-600 Bootloader
--  Last Updated : 16 Aug 2014
--*******************************************************************

with SYSTEM; use SYSTEM;
with INTERFACES; use INTERFACES;
with ATmega2560_Timers;
package ATmega2560_Timers.TC0_2 is  -- 8-Bit Timer

	package A2560T renames ATmega2560_Timers;

	subtype TC_Choices is A2560T.Timer_Counters range TC0..TC2;

	type COM_Mode_Choices is (COMA, COMB, COM_NOT_USED);
	for  COM_Mode_Choices use (0,1,2);
	
	-- COM Modes 
	type COM_Mode_t is new Natural range 0..3;
	for  COM_Mode_t'Size use 2;

-------------------------------------  TC0  ---------------------------------

	type TC0_Clk_Prescale_Values is 
		   (PS0, PS1, PS8, PS64, PS256, PS1024, EXT_FE, EXT_RE); 
	-- 0=Stopped, 1=No Scaling...EXT_FE=Ext Clk, Falling Edge; _RE=Rising Edge
	
	for TC0_Clk_Prescale_Values use (0,1,2,3,4,5,6,7);
	
   for TC0_Clk_Prescale_Values'size use 3;
	

-------------------------------------  TC2  ---------------------------------

	type TC2_Clk_Prescale_Values is (PS0, PS1, PS8, PS32, PS64);
	
	for TC2_Clk_Prescale_Values use (0,1,2,3,4);
	
   for TC2_Clk_Prescale_Values'size use 3;
	
-----------------------------  TC0_2  Control Regs --------------------------

	-- For n=[0,2]
	
	subtype COM_Array_Index is Natural range 0..1;
	type COM_Bits_Array_t is array(COM_Array_Index) of Bit;
	
	type TCCRnA_Reg_t is -- n= 0, 2
	  record
		WGMn1_0  : Two_Bits;
		Unused   : Two_Bits;
		COMnB1_0 : COM_Mode_t;
		COMnA1_0 : COM_Mode_t;
	end record;
	
	for TCCRnA_Reg_t use
	  record
		WGMn1_0  at 0 range 0..1;
		Unused	at 0 range 2..3;
		COMnB1_0 at 0 range 4..5;
		COMnA1_0 at 0 range 6..7;
	end record;
	
	for TCCRnA_Reg_t'Size      use 8;
	for TCCRnA_Reg_t'Bit_Order use SYSTEM.Low_Order_First;
	
	
	type TCCR0B_Reg_t is 
	  record
		CS_Bits : TC0_Clk_Prescale_Values;
		WGMn2   : Bit;
		Unused  : Two_Bits;
		FOCnB   : Bit;
		FOCnA   : Bit;
	end record;
	
	for TCCR0B_Reg_t use
     record
		CS_Bits at 0 range 0..2;
		WGMn2   at 0 range 3..3;
		Unused  at 0 range 4..5;
		FOCnB   at 0 range 6..6;
		FOCnA   at 0 range 7..7;
	end record;	
	
	for TCCR0B_Reg_t'Size      use 8;
	for TCCR0B_Reg_t'Bit_Order use System.Low_Order_First;
	
	type TCCR2B_Reg_t is 
	  record
		CS_Bits : TC2_Clk_Prescale_Values;
		WGMn2   : Bit;
		Unused  : Two_Bits;
		FOCnB   : Bit;
		FOCnA   : Bit;
	end record;
	
	for TCCR2B_Reg_t use
     record
		CS_Bits at 0 range 0..2;
		WGMn2   at 0 range 3..3;
		Unused  at 0 range 4..5;
		FOCnB   at 0 range 6..6;
		FOCnA   at 0 range 7..7;
	end record;	
	
	for TCCR2B_Reg_t'Size      use 8;
	for TCCR2B_Reg_t'Bit_Order use System.Low_Order_First;
	

	---------------------  Interface procedures for setups  ---------------
	
	subtype WGM_Values_t is Triad range 0..7; -- Different from TC1345 
	
	-- Waveform Generation Modes (WGM)
		
	type WGM_Descriptor_Values_t is 
		(Normal, PC_FF, CTC_OCRnA, FP_FF, RES_4, PC_OCRnA, RES_6, FP_OCRnA);
		 
	for WGM_Descriptor_Values_t use (0, 1,  2,  3,  4,  5, 6, 7);
	
	type WGM_Desc_Values_Ay_t is 
		array(WGM_Values_t) of WGM_Descriptor_Values_t;
	
	WGM_Desc_Values : constant WGM_Desc_Values_Ay_t :=
								-- Mode of Operation 			TOP	  Update		TOVn 
								--								 		Value  of OCRnx:	Flag	
								--															  Set On:
	(	 0 => Normal,		-- Normal 							0xFF 	 Immediate	MAX
		 1 => PC_FF,		-- PWM, Phase Correct,		 	0xFF     TOP		BOTTOM
		 2 => CTC_OCRnA,	-- CTC 								OCRnA  Immediate 	MAX
		 3 => FP_FF,		-- Fast PWM, 8-bit 				0xFF 	  BOTTOM 	TOP
		 4 => RES_4,		-- Reserved							 --		 -- 		 -- 
		 5 => PC_OCRnA,	-- PWM, Phase Correct			OCRnA 	BOTTOM 	BOTTOM
		 6 => RES_6,		-- Reserved							 --		 -- 		 -- 
		 7 => FP_OCRnA);	-- Fast PWM 						OCRnA 	BOTTOM 	TOP	
		
	procedure Set_TC0_ClkIO_Prescaler(To : TC0_Clk_Prescale_Values);

	procedure Set_TC2_ClkIO_Prescaler(To : TC2_Clk_Prescale_Values);
		
	-- Three ways to set WGM:
							
	procedure Set_WGM -- by using registers and mode number
		(TCCRA : in out Interfaces.Unsigned_8; 
		 TCCRB : in out Interfaces.Unsigned_8; 
		 WGM_Setting : WGM_Values_t);
		 
	procedure Set_WGM -- by using the Timer and mode number
		(Timer_Counter : TC_Choices; WGM_Setting : WGM_Values_t);
		
	procedure Set_WGM -- by using the mode descriptor
		(Timer_Counter : TC_Choices; WGM_Setting : WGM_Descriptor_Values_t);
		 

	procedure Set_COM_Mode 
		(TCCRA : in out Interfaces.Unsigned_8; 
		 COM_Mode_Selection : COM_Mode_Choices;
		 COM_Mode : COM_Mode_t);
		 

	--Example TCCR2A: COM1A1 COM1A0 COM1B1 COM1B0 -- --  WGM11 WGM10
	-- For n=[1,3,4,5]
	
	-- EXAMPLE Calls: Just change Register-TC number to select a different T/C
	-- 	e.g, change TCCR3A to TCCR4A to use T/C 4. Change PS,WGM,COM as req'd
	--
	--TC0_2.Set_TC0_ClkIO_Prescaler
	--	(Timer_Counter => TC_0, PS_Val => PS1024 );
	--	
	--TC0_2.Set_WGM
	--	(TCCRA => ATmega2560.TCCR0A, TCCRB => ATmega2560.TCCR0B, 
	--  WGM_Setting => 2);
	--
	--TC0_2.Set_COM_Mode 
	--	(TCCRA => ATmega2560.TCCR0A, 
	--  COM_Mode_Selection => TC0_2.COMA, COM_Mode => 2);
	--
	
	procedure Set_TC_Mode 
		(TC : TC_Choices; WGM_Setting : WGM_Descriptor_Values_t; 
	    COM_Mode_Selection : COM_Mode_Choices; COM_Mode : COM_Mode_t);
								
private

	-- Set constant for Clk_IO value
	Clk_IO : constant 		:= 1_000_000; -- 1MHz clock
	Clk_IO_Div_40 : Natural := Natural(Clk_IO/40); -- support 16-bit comps
	
	-- T/C Top values for each Timer...
	TC0_Top : Unsigned_8;
	TC2_Top : Unsigned_8;

	-- Local copies of the Prescale Values for use in internal computations
	TC0_PS_Val : Natural;	
	TC2_PS_Val : Natural;	

end ATmega2560_Timers.TC0_2;