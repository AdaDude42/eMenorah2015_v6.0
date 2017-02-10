--***************************************************************************
--  File Name	  : ADC.adb
--  Version	 	  : 1.0
--  Description  : Provides basic ADC-related support
--				  	  : In this program the’ initialize ()’ routine is used 
--				  	  : to initialize the ADC module. The ‘convert ()’ routine
--				  	  : has to be called whenever the application needs an 
--				  	  : ADC conversion.
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 01 Apr 2015 Created
--				 	  :	
--***************************************************************************
with ATMega2560;
with BIT_PARTS;
with CTRLS_and_INDICATORS;
package body ADC is

	--NOTE=> "DS:" in comments means ATmega2560 Datasheet.

	package A2560		renames ATmega2560;
	package BP 			renames BIT_PARTS;
	package C_and_I	renames CTRLS_and_INDICATORS;
	
	ADC_Res_Select : Res_Select_Options := Res10;
	pragma VOLATILE (ADC_Res_Select);
	
	Result : Result_Rec_t;

	ADIF_Bit : constant BP.Bit_Number_t := 4;

-----------------------------------------------------------------------------	
	procedure Set_ADC_Res (To : in Res_Select_Options) is
	begin
	
		ADC_Res_Select := To;
		
		if ADC_Res_Select = Res10 then 
		   --set ADLAR:5 in ADMUX to 0 to Right-Justify Reading
			A2560.ADMUX := A2560.ADMUX AND BP.Low_Bits(5);
		else
			A2560.ADMUX := A2560.ADMUX OR BP.High_Bits(5);
		end if;

	end Set_ADC_Res;
	
	function ADC_Res_Select_Value return Res_Select_Options is
	begin
		return ADC_Res_Select;
	end ADC_Res_Select_Value;
	
-----------------------------------------------------------------------------	
	procedure Update_Res_Select is
		-- Based on reading a "switch" input in C_and_I pkg...
	begin
		if C_and_I.Input_Set_to_High (Input => C_and_I.ADC_Res_Select) then
			Set_ADC_Res (To => Res10);
		else
			Set_ADC_Res (To => Res8);
		end if;
	
	end Update_Res_Select;
	
-----------------------------------------------------------------------------
	procedure Initialize is
		--Set_Mux_Channel := 0;
		--Enable_ADC (ADEN := 1);
		--Set ADC Clk Prescaler bits
		--Set_ADLAR(Res_Select_Input):= 0; -- Res10

	begin
		--Task: Single Conversion on ADC channel 0.
		--In this program the’ initialize ()’ routine is used to initialize
		--  the ADC module. 
		-- 1. Set the MUX bit fields (MUX3:0) in ADC’s MUX register (ADMUX)
		--    equal to 2#0000# to select ADC Channel 0.
	
		A2560.ADMUX := A2560.ADMUX AND 2#1111_0000#;
		
		-- 2. Set the ADC Enable bit (ADEN:7) in ADC Control and Status 
		--    Register A (ADCSRA) to enable the ADC module.

		-- A2560.ADCSRA := 2#1000_0000#; Combine with next step...
		
		-- 3. Set the ADC Pre-scalar bit fields (ADPS2:0) in ADCSRA equal
		--		to 2#100# to prescale the system clock by 16.
		
		A2560.ADCSRA := 2#1000_0100#;

	
		-- 4. Set the Voltage Reference bit fields (REFS1:0) in ADMUX equal
		--    to 01 to select Internal AVcc reference.
		-- A2560.ADMUX := A2560.ADMUX OR BP.High_Bits(6);
		--*** Set Bits 7..6 to 11 to select 2.56v Ref
		A2560.ADMUX := A2560.ADMUX OR 2#1100_0000#;

		
		
		-- Set ADLAR:5 in ADMUX based on Res_Select input...
		if (ADC_Res_Select = Res10) then
			A2560.ADMUX := A2560.ADMUX AND BP.Low_Bits(5);
		else
			A2560.ADMUX := A2560.ADMUX OR BP.High_Bits(5); 
			-- Set to Left-Justify	result and use ADCH only for Res8
		end if;
		
		-- Disable Digital Input for the ADC Pins:
		A2560.DIDR0 := 2#1111_1111#;
		
		ADC_Process := Waiting;
		Result.Completed := False;
		
	end Initialize;
	
-----------------------------------------------------------------------------	
	procedure Start_Conversion is
	begin
	
		--The
		-- ‘convert ()’ routine is called whenever the application needs an ADC
		--	conversion.
		
		-- 5. Set the Start Conversion bit (ADSC:6) in ADCSRA to start a 
		--		single conversion.
		
		A2560.ADCSRA := A2560.ADCSRA OR BP.High_Bits (6);
			
		-- 6. Poll (wait) for the Interrupt Flag (ADIF) bit in the ADCSRA 
		--		register to be set,indicating that a new conversion is completed.
		 
		Result.Completed := False;
		
		--A2560.PORTH := 16#FF#; -- LEDs are active LOW; keep them OFF here
		
	end Start_Conversion;
	
	
-----------------------------------------------------------------------------	
	function Conv_Complete return Boolean is
	
		-- 7. Once the conversion is over (ADIF bit ADCSRA:4) becomes high, 
		--		then read the ADC data register pair (ADCL/ADCH) to get 
		--		 the 10-bit result.
		
	begin
		
		return ((A2560.ADCSRA AND BP.High_Bits(ADIF_Bit)) /= 0); -- ADIF is set
	
	end Conv_Complete;
	

-----------------------------------------------------------------------------	
	function Get_Result return Result_Rec_t is
			
	begin
		
		if Conv_Complete then -- ADIF is set
		
			--DS:ADIF is cleared by writing a logical one to the flag.
			A2560.ADCSRA 		:= 
							A2560.ADCSRA OR BP.High_Bits(ADIF_Bit); -- clear ADIF
			
			-- Test Value 16#0283# = 643 decimal = 2.04077v which Flashes PWR LED RED as expected.
			Result.Low_Byte	:= A2560.ADCL; --16#83#; -- ADC Data Register Low Byte
			Result.High_Byte	:= A2560.ADCH; --16#02#; -- ADC Data Register High Byte
			Result.Completed	:= True;
			
		end if;
		
		return Result;
		
	end Get_Result;
	
-----------------------------------------------------------------------------	
	function Compute_Volts_From_ADC return ADC.Rdg_Volts_t is
	
		ADC_Reading 		: ADC.Result_Rec_t;
		Reading_in_Volts	: ADC.Rdg_Volts_t;

	begin
	
		ADC_Reading := ADC.Get_Result;
	
		if (ADC.ADC_Res_Select_Value = ADC.Res10) then
			declare
				Integer_Reading_10 :  Unsigned_16;
			begin
				Integer_Reading_10 := Unsigned_16(ADC_Reading.High_Byte);
				
				Integer_Reading_10 := Shift_Left(Integer_Reading_10,8)
				                     + Unsigned_16(ADC_Reading.Low_Byte);
				
				Calculate_Reading_10:							
				declare
				
					pragma SUPPRESS(ALL_CHECKS);
					
				begin
				
					Reading_in_Volts   := ADC.Rdg_Volts_t(ADC.LSB10 * Integer(Integer_Reading_10));
					
				end Calculate_Reading_10;
				
			end;
			
		else
		
			declare
				Integer_Reading_8 : Unsigned_16;
			begin
				Integer_Reading_8 := Unsigned_16(ADC_Reading.High_Byte);
				
				Calculate_Reading_8:							
				declare
				
					pragma SUPPRESS(ALL_CHECKS);
					
				begin	
				
					Reading_in_Volts  := ADC.Rdg_Volts_t(ADC.LSB8 * Integer(Integer_Reading_8));

				end Calculate_Reading_8;

			end;
							
		end if;	
				
		--Reading_in_Volts  := 2.0;		
		return Reading_in_Volts;
		
	end Compute_Volts_From_ADC;

-----------------------------------------------------------------------------	

end ADC;
