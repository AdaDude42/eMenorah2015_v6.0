--*******************************************************************
--  File Name	  : CTRLS_and_INDICATORS.adb
--  Version	 : 1.0
--  Description  : Menorah system controls and indicators:
--               :   Shamash_Enable, Power ON/Low, NORM/DEMO
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 15 Mar 2015 -- Created
--					  : 	Creat PORT Bits for C&I usage
--*******************************************************************

with Ada.Unchecked_Conversion;
with INTERFACES; use INTERFACES;

package body CTRLS_and_INDICATORS is

	C_and_I_Bits : BP.Bits_Bytes_Array_t;

------------------------------------------------------------------------------
	procedure Switch_C_and_I_Bit (Output  : in out C_and_I_Output_State_t; 
										   To           : OFF_ON_t) is
																					
	begin
	
		if (Output.Active_Low) then 
		
			if (To = OFF) then
				C_and_I_Bits(Output.Number) := 
					BP.High_Bits(Output.Number);
				Output.Port.all := 
					Output.Port.all OR C_and_I_Bits(Output.Number);
			else
				C_and_I_Bits(Output.Number) := 
					BP.Low_Bits(Output.Number);
				Output.Port.all := 
					Output.Port.all AND C_and_I_Bits(Output.Number);
				
			end if;
			
		else	-- Active High
		
			if (To = OFF) then
				C_and_I_Bits(Output.Number) := 
					BP.Low_Bits(Output.Number);
				Output.Port.all := 
					Output.Port.all AND C_and_I_Bits(Output.Number);
			else
				C_and_I_Bits(Output.Number) := 
					BP.High_Bits(Output.Number);
				Output.Port.all := 
					Output.Port.all OR C_and_I_Bits(Output.Number);
			end if;
			
		end if;
		
	exception
		when others =>
			null;
	
	end Switch_C_and_I_Bit;

------------------------------------------------------------------------------
	procedure Toggle_C_and_I_Bit (Output : in out C_and_I_Output_State_t) is
	
	begin
		-- Writing a logic one to PINxn toggles the value of PORTxn
		
		Output.PIN.all := BP.High_Bits (Output.Number);
		
	exception
		when others => null;
	
	end Toggle_C_and_I_Bit;
	
------------------------------------------------------------------------------
	procedure Flash_C_and_I_Bit  (Output : in out C_and_I_Output_State_t) is
	
		use TI01s; -- Operator visibility for /= below...
		
	begin
	
		if Output.Flash_Interval /= 0.0 then
		
			if TI01s.Interval_Expired(Output.Flash_Start_Time, 
												Output.Flash_Interval) then
				Toggle_C_and_I_Bit (Output);
				Output.Flash_Start_Time := TI01s.Initialize_Interval;
			end if;
			
		end if;
		
	end Flash_C_and_I_Bit;
	
------------------------------------------------------------------------------	
	procedure Update_Flashing_Outputs is
	
	begin
	
		for Output in CI_Outputs loop

			Flash_C_and_I_Bit(Output_Array(Output));
		
		end loop;
			
	end Update_Flashing_Outputs;
				
		

------------------------------------------------------------------------------
	function Input_Set_to_High (Input : in C_and_I_Input_State_t) 
																				return Boolean is	
		In_Byte : Unsigned_8;																		
																				
	begin
		In_Byte := Input.PIN.all;
		return ( ( In_Byte AND BP.High_Bits(Input.Number) ) /= Unsigned_8'(0) );
		
	exception
		when others => return False;
		
	end Input_Set_to_High;
	
	
	function  Input_Set_to_Low  (Input  : in C_and_I_Input_State_t) 
																				return Boolean is																			

	begin
	
		return ( ( Input.PIN.all AND BP.High_Bits(Input.Number) ) = 0);
		
	exception
		when others => return False;

	end Input_Set_to_Low;
																				
																					
------------------------------------------------------------------------------
	procedure Initialize is
	begin
	
		-- Using PORTC upper-level bits. These are alternate function
		--	Memory Address bits that are not used for this application.
		-- But using the upper bits incase lower bits are needed later 
		--	for Memory access.
	
		AT2560.DDRC := 2#1111_1000#;
		
		AT2560.PORTC := 2#0000_0000#; -- All C&I bits off
		
		--If PORTxn is written logic one when the pin is configured as an input pin, 
		--  the pull-up resistor is activated
		
		AT2560.PORTC := 2#0000_0110#; -- Set Weak Pullups for Inputs
		
		Output_Array(Shamash_Enable)	:= 
			(Number  => 7,  PORT => Address_to_Port_Access(AT2560.PORTC'Address),
								 PIN  => Address_to_PIN_Access(AT2560.PINC'Address), 
								 Active_Low => False, Flash_Interval => 0.0, 
								 Flash_Start_Time => TI01s.Initialize_Interval);
			
		Output_Array(Power_Grn)		 	:= 
			(Number  => 6,  PORT => Address_to_Port_Access(AT2560.PORTC'Address),
								 PIN  => Address_to_PIN_Access(AT2560.PINC'Address), 
								 Active_Low => False, Flash_Interval => 0.0, 
								 Flash_Start_Time => TI01s.Initialize_Interval);

		Output_Array(Power_RED)			:= 
			(Number  => 5,  PORT => Address_to_Port_Access(AT2560.PORTC'Address),
								 PIN  => Address_to_PIN_Access(AT2560.PINC'Address), 
								 Active_Low => False, Flash_Interval => 0.0, 
								 Flash_Start_Time => TI01s.Initialize_Interval);

		Output_Array(ND_Normal_Grn) 	:= 
			(Number  => 4,  PORT => Address_to_Port_Access(AT2560.PORTC'Address),
								 PIN  => Address_to_PIN_Access(AT2560.PINC'Address), 
								 Active_Low => False, Flash_Interval => 0.0, 
								 Flash_Start_Time => TI01s.Initialize_Interval);
			
		Output_Array(ND_Demo_Amber)	:= 
			(Number  => 3,  PORT => Address_to_Port_Access(AT2560.PORTC'Address),
								 PIN  => Address_to_PIN_Access(AT2560.PINC'Address),
								 Active_Low => False, Flash_Interval => 0.0, 
								 Flash_Start_Time => TI01s.Initialize_Interval);
			
		Norm_Demo_SW		:= 
			(Number  => 2,  PIN => Address_to_PIN_Access(AT2560.PINC'Address), Active_Low => False); -- NORM=1
								 
		ADC_Res_Select		:= 
			(Number  => 1,  PIN  => Address_to_PIN_Access(AT2560.PINC'Address), Active_Low => False);
								 
	
		Switch_C_and_I_Bit (Output_Array(Shamash_Enable), To => ON);
		Switch_C_and_I_Bit (Output_Array(Power_Grn),      To => ON);
		Switch_C_and_I_Bit (Output_Array(Power_Red),      To => OFF);
		Switch_C_and_I_Bit (Output_Array(ND_Normal_Grn),  To => ON);
		Switch_C_and_I_Bit (Output_Array(ND_Demo_Amber),  To => OFF);

	end Initialize;


end CTRLS_and_INDICATORS;
