--*******************************************************************
--  File Name	  : TC1345.adb
--  Version	 	  : 1.0
--  Description  : AVR TIMER 1,3,4,5 Setup UI
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNAT GPL-2012 avr_cross
--  IDE          : Atmel AVR Studio 6.1
--  Programmer   : AVR STK-600 Bootloader
--  Last Updated : 07 July 2014
--*******************************************************************

with ATmega2560;
package body ATmega2560_Timers.TC1345 is


	package A2560  renames ATmega2560;
	package A2560T renames ATmega2560_Timers;
		
	use INTERFACES;

	-- Convert from INTERFACES.Unsigned_8 to TCCRnx Register representations
	function U8_To_TCCRnA_Reg_t is new Ada.Unchecked_Conversion
		(Source => INTERFACES.Unsigned_8, Target => TCCRnA_Reg_t);
		
	function U8_To_TCCRnB_Reg_t is new Ada.Unchecked_Conversion
		(Source => INTERFACES.Unsigned_8, Target => TCCRnB_Reg_t);
				
	-- Convert from TCCRnx Register representations to INTERFACES.Unsigned_8 	
	function TCCRnA_Reg_t_To_U8 is new Ada.Unchecked_Conversion
		(Source => TCCRnA_Reg_t, Target => INTERFACES.Unsigned_8);
		
	function TCCRnB_Reg_t_To_U8 is new Ada.Unchecked_Conversion
		(Source => TCCRnB_Reg_t, Target => INTERFACES.Unsigned_8);
		
	procedure Set_ClkIO_Prescaler(TCCRB : in out INTERFACES.Unsigned_8; 
											To : Clk_Prescale_Values) is
											
		TCCRB_Temp : TCCRnB_Reg_t := U8_To_TCCRnB_Reg_t(TCCRB);
	begin
		TCCRB_Temp.CS_Bits := To;
		TCCRB := (TCCRnB_Reg_t_To_U8(TCCRB_Temp));
	end Set_ClkIO_Prescaler;
	
	procedure Set_ClkIO_Prescaler(Timer_Counter : TC_Choices; 
											PS_Val : Clk_Prescale_Values) is
	begin
		case Timer_Counter is
			when TC1 =>
				Set_ClkIO_Prescaler(TCCRB => ATmega2560.TCCR1B, To => PS_Val);
				TC1_PS_Val := Natural(Clk_Prescale_Values'Pos(PS_Val));
			when TC3 =>
				Set_ClkIO_Prescaler(TCCRB => ATmega2560.TCCR3B, To => PS_Val);
				TC3_PS_Val := Natural(Clk_Prescale_Values'Pos(PS_Val));
			when TC4 =>
				Set_ClkIO_Prescaler(TCCRB => ATmega2560.TCCR4B, To => PS_Val);
				TC4_PS_Val := Natural(Clk_Prescale_Values'Pos(PS_Val));
			when TC5 =>
				Set_ClkIO_Prescaler(TCCRB => ATmega2560.TCCR5B, To => PS_Val);
				TC5_PS_Val := Natural(Clk_Prescale_Values'Pos(PS_Val));
			when others => 
				null;
		end case;
		
	exception
		when others => 
			null;
	
	end Set_ClkIo_Prescaler;

	
	procedure Set_WGM_Bits 
		(TCCRA : in out INTERFACES.Unsigned_8; 
		 TCCRB : in out INTERFACES.Unsigned_8;
		 WGM_Bits: WGM_Nibble)is
		 
		 TCCRA_Temp : TCCRnA_Reg_t := U8_To_TCCRnA_Reg_t(TCCRA);
		 TCCRB_Temp : TCCRnB_Reg_t := U8_To_TCCRnB_Reg_t(TCCRB);
		 
	begin
	
		TCCRA_Temp.WGMn1_0 := WGM_Bits.Bits_1_0;
		TCCRB_Temp.WGMn3_2 := WGM_Bits.Bits_3_2;
				
		TCCRA := (TCCRnA_Reg_t_To_U8(TCCRA_Temp));
		TCCRB := (TCCRnB_Reg_t_To_U8(TCCRB_Temp));

	end Set_WGM_Bits;
	
	
	procedure Set_WGM 
		(TCCRA : in out INTERFACES.Unsigned_8; 
		 TCCRB : in out INTERFACES.Unsigned_8; 
		 WGM_Setting : WGM_Values_t) is
		 
		 WGM_Bits_Value : WGM_Nibble;
		 
		 WGM_Temp_8 : Unsigned_8 := Unsigned_8(WGM_Setting);
		 WGM_Temp_2 : Unsigned_8;
		 
	begin
	
		WGM_Temp_2 := WGM_Temp_8 AND 2#0000_0011#;
		WGM_Bits_Value.Bits_1_0 := Two_Bits(WGM_Temp_2);
		
		WGM_Temp_2 := WGM_Temp_8 AND 2#0000_1100#;
		WGM_Bits_Value.Bits_3_2 := Two_Bits( Shift_Right(WGM_Temp_2,2) );
		Set_WGM_Bits (TCCRA => TCCRA, TCCRB => TCCRB, WGM_Bits =>
						  WGM_Bits_Value);
	exception
		when others => null;
						  
	end Set_WGM;
	
	
	procedure Set_WGM 
		(Timer_Counter : TC_Choices; WGM_Setting : WGM_Values_t) is
		
	begin

		case Timer_Counter is
			when TC1 =>
				Set_WGM (TCCRA => A2560.TCCR1A, TCCRB => A2560.TCCR1B, 
						   WGM_Setting => WGM_Setting);

			when TC3 =>
				Set_WGM (TCCRA => A2560.TCCR3A, TCCRB => A2560.TCCR3B, 
						   WGM_Setting => WGM_Setting);

			when TC4 =>
				Set_WGM (TCCRA => A2560.TCCR4A, TCCRB => A2560.TCCR4B, 
						   WGM_Setting => WGM_Setting);

			when TC5 =>
				Set_WGM (TCCRA => A2560.TCCR5A, TCCRB => A2560.TCCR5B, 
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
		elsif (COM_Mode_Selection = COMC) then
				TCCRA_Temp.COMnC1_0 := COM_Mode;
		end if;
				
		TCCRA := (TCCRnA_Reg_t_To_U8(TCCRA_Temp));
		
	end Set_COM_Mode;
		
		
	procedure Set_TC_Mode 
		(TC : TC_Choices; WGM_Setting : WGM_Descriptor_Values_t; 
	    COM_Mode_Selection : COM_Mode_Choices; COM_Mode : COM_Mode_t;
		 PS_Val : Clk_Prescale_Values) is
		 
		TCCRA : Unsigned_8;
		
	begin
	
		Set_WGM 
			(Timer_Counter => TC, WGM_Setting => WGM_Setting);
			
		Set_ClkIO_Prescaler(Timer_Counter => TC, PS_Val => PS_Val);
			
		case TC is
			when TC1 =>
				TCCRA := A2560.TCCR1A;
			when TC3 =>
				TCCRA := A2560.TCCR3A;
			when TC4 =>
				TCCRA := A2560.TCCR4A;
			when TC5 =>
				TCCRA := A2560.TCCR5A;
			when others =>
				null;
		end case;

		Set_COM_Mode (TCCRA => TCCRA, COM_Mode_Selection => COM_Mode_Selection,
			 COM_Mode => COM_Mode);
			
	exception
		when others =>
			null;

	end Set_TC_Mode;
			
		
end ATmega2560_Timers.TC1345;