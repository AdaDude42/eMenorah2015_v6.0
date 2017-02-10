--*******************************************************************
--  File Name	  : ATmega2560_Timers-TC0_2.ads
--  Version	 	  : 1.0
--  Description  : AVR TIMER/Counter Setup API for TC0 & TC2
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNAT GPL-2012 avr_cross
--  IDE          : Atmel AVR Studio 6.1
--  Programmer   : AVR STK-600 Bootloader
--  Last Updated : 11 July 2014
--*******************************************************************

with ATmega2560;
with ATmega2560_Timers;
with Ada.Unchecked_Conversion;
package body ATmega2560_Timers.TC0_2 is


	package A2560  renames ATmega2560;
	use A2560;
	
	type WGM_Triad is
	 record
		Bits_1_0 : Two_Bits; -- in TCCRnA_Reg
		Bit_2    : Bit;		-- in TCCRnB_Reg
	end record;


	-- Convert from INTERFACES.Unsigned_8 to TCCRnx Register representations
	function U8_To_TCCRnA_Reg_t is new Ada.Unchecked_Conversion
		(Source => INTERFACES.Unsigned_8, Target => TCCRnA_Reg_t);
		
	function U8_To_TCCR0B_Reg_t is new Ada.Unchecked_Conversion
		(Source => INTERFACES.Unsigned_8, Target => TCCR0B_Reg_t);
				
	function U8_To_TCCR2B_Reg_t is new Ada.Unchecked_Conversion
		(Source => INTERFACES.Unsigned_8, Target => TCCR2B_Reg_t);
				
	-- Convert from TCCRnx Register representations to INTERFACES.Unsigned_8 	
	function TCCRnA_Reg_t_To_U8 is new Ada.Unchecked_Conversion
		(Source => TCCRnA_Reg_t, Target => INTERFACES.Unsigned_8);
		
	function TCCR0B_Reg_t_To_U8 is new Ada.Unchecked_Conversion
		(Source => TCCR0B_Reg_t, Target => INTERFACES.Unsigned_8);
		
	function TCCR2B_Reg_t_To_U8 is new Ada.Unchecked_Conversion
		(Source => TCCR2B_Reg_t, Target => INTERFACES.Unsigned_8);
		
	procedure Set_TC0_ClkIO_Prescaler(To : TC0_Clk_Prescale_Values) is
											
		TCCRB_Temp : TCCR0B_Reg_t := U8_To_TCCR0B_Reg_t(TCCR0B);
	begin
		TCCRB_Temp.CS_Bits := To;
		TCCR0B := (TCCR0B_Reg_t_To_U8(TCCRB_Temp));
		TC0_PS_Val := Natural(TC0_Clk_Prescale_Values'Pos(To));
	end Set_TC0_ClkIO_Prescaler;
	
	procedure Set_TC2_ClkIO_Prescaler(To : TC2_Clk_Prescale_Values) is
											
		TCCRB_Temp : TCCR2B_Reg_t := U8_To_TCCR2B_Reg_t(TCCR2B);
	begin
		TCCRB_Temp.CS_Bits := To;
		TCCR2B := (TCCR2B_Reg_t_To_U8(TCCRB_Temp));
		TC2_PS_Val := Natural(TC2_Clk_Prescale_Values'Pos(To));
	end Set_TC2_ClkIO_Prescaler;	
	
	-- Use TCCR0B_Reg_t Type to Set WGM; Same as TCCR2B for this operation
	procedure Set_WGM_Bits 
		(TCCRA : in out INTERFACES.Unsigned_8; 
		 TCCRB : in out INTERFACES.Unsigned_8;
		 WGM_Bits: WGM_Triad)is
		 
		 TCCRA_Temp : TCCRnA_Reg_t := U8_To_TCCRnA_Reg_t(TCCRA);
		 TCCRB_Temp : TCCR0B_Reg_t := U8_To_TCCR0B_Reg_t(TCCRB);
		 
	begin
	
		TCCRA_Temp.WGMn1_0 := WGM_Bits.Bits_1_0;
		TCCRB_Temp.WGMn2 	 := WGM_Bits.Bit_2;
				
		TCCRA := (TCCRnA_Reg_t_To_U8(TCCRA_Temp));
		TCCRB := (TCCR0B_Reg_t_To_U8(TCCRB_Temp));

	end Set_WGM_Bits;
	
	
	procedure Set_WGM 
		(TCCRA : in out INTERFACES.Unsigned_8; 
		 TCCRB : in out INTERFACES.Unsigned_8; 
		 WGM_Setting : WGM_Values_t) is
		 
		 WGM_Bits_Value : WGM_Triad;
		 
		 WGM_Temp_8 : Unsigned_8 := Unsigned_8(WGM_Setting);
		 WGM_Temp_2 : Unsigned_8;
		 WGM_Temp_1 : Unsigned_8;
		 
	begin
	
		WGM_Temp_2 := WGM_Temp_8 AND 2#0000_0011#;
		WGM_Bits_Value.Bits_1_0 := Two_Bits(WGM_Temp_2);
		
		WGM_Temp_1 := WGM_Temp_8 AND 2#0000_0100#;
		WGM_Bits_Value.Bit_2 := Bit( Shift_Right(WGM_Temp_1,2) );
		Set_WGM_Bits (TCCRA => TCCRA, TCCRB => TCCRB, WGM_Bits =>
						  WGM_Bits_Value);
	exception
		when others => null;
						  
	end Set_WGM;
	
	
	procedure Set_WGM 
		(Timer_Counter : TC_Choices; WGM_Setting : WGM_Values_t) is
		
	begin

		case Timer_Counter is
			when TC0 =>
				Set_WGM (TCCRA => A2560.TCCR1A, TCCRB => A2560.TCCR0B, 
						   WGM_Setting => WGM_Setting);

			when TC2 =>
				Set_WGM (TCCRA => A2560.TCCR3A, TCCRB => A2560.TCCR2B, 
						   WGM_Setting => WGM_Setting);
							
			when others => 
				null;
		end case;
		
	exception
		when others => null;
	
	end Set_WGM;


	procedure Set_WGM 
		(Timer_Counter : TC_Choices; WGM_Setting : WGM_Descriptor_Values_t) is
		
	begin
	
		Set_WGM (Timer_Counter => Timer_Counter, 
		         WGM_Setting   => WGM_Values_t
										 (WGM_Descriptor_Values_t'Pos(WGM_Setting) ) );
					
	end Set_WGM;
		 
	
	-- Set Compare Mode for Port operation
	procedure Set_COM_Mode 
		(TCCRA : in out INTERFACES.Unsigned_8; 
		 COM_Mode_Selection : COM_Mode_Choices;
		 COM_Mode : COM_Mode_t) is
		 
		TCCRA_Temp : TCCRnA_Reg_t:= U8_To_TCCRnA_Reg_t(TCCRA);
				
	begin
	
		if (COM_Mode_Selection = COMA) then
				TCCRA_Temp.COMnA1_0 := COM_Mode;
		elsif (COM_Mode_Selection = COMB) then
				TCCRA_Temp.COMnB1_0 := COM_Mode;
		end if;
				
		TCCRA := (TCCRnA_Reg_t_To_U8(TCCRA_Temp));
		
	end Set_COM_Mode;
		
		
	procedure Set_TC_Mode 
		(TC : TC_Choices; WGM_Setting : WGM_Descriptor_Values_t; 
	    COM_Mode_Selection : COM_Mode_Choices; COM_Mode : COM_Mode_t) is
		 
		TCCRA : Unsigned_8;
		
	begin
	
		Set_WGM 
			(Timer_Counter => TC, WGM_Setting => WGM_Setting);
			
		case TC is
			when TC0 =>
				TCCRA := A2560.TCCR0A;
			when TC2 =>
				TCCRA := A2560.TCCR2A;
			when others =>
				null;
		end case;

		Set_COM_Mode (TCCRA => TCCRA, COM_Mode_Selection => COM_Mode_Selection,
			 COM_Mode => COM_Mode);
			
	exception
		when others =>
			null;

	end Set_TC_Mode;
	

	

end ATmega2560_Timers.TC0_2;