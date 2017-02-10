--*******************************************************************
--  File Name	  : CTRLS_and_INDICATORS
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
--						: 3 Apr 2015 
--						:   Adding inputs and flashing for outputs
--*******************************************************************

with ATMEGA2560;
with BIT_PARTS;
with INTERFACES; use INTERFACES;
with SYSTEM; use SYSTEM;
with Unchecked_Conversion;
with TIMED_INTERVAL_01S;

package CTRLS_and_INDICATORS is

	package AT2560 renames	ATMEGA2560; 
	package BP 		renames	BIT_PARTS;
	package TI01s	renames	TIMED_INTERVAL_01s; 
		
	type OFF_ON_t is (OFF, ON);
	
	type PORT_Access is access Unsigned_8;
	type PIN_Access  is access Unsigned_8;
	
	function Address_to_PORT_Access is new Unchecked_Conversion
		(Source => System.Address, Target => PORT_Access);
		
	function Address_to_PIN_Access is new Unchecked_Conversion
		(Source => System.Address, Target => PIN_Access);

	type C_and_I_Input_State_t is
	 record
	  Number  	 : BP.Bit_Number_t;
	  PIN 		 : PIN_Access;
	  Active_Low : Boolean := False;
	 end record;

	Norm_Demo_SW	: C_and_I_Input_State_t;
	ADC_Res_Select	: C_and_I_Input_State_t;

	type CI_Outputs is 
		(Shamash_Enable, Power_Grn, Power_RED, ND_Normal_Grn, ND_Demo_Amber);
	
	type C_and_I_Output_State_t is
	 record
	  Number  			 : BP.Bit_Number_t;
	  PORT 				 : Port_Access;
	  PIN					 : PIN_Access;		-- to support toggling 
	  Active_Low   	 : Boolean := False;
	  Flash_Interval	 : TI01s.Time_Interval_t := 0.0; --/=0.0 enables flashing
	  Flash_Start_Time : TI01s.Start_Time := TI01s.Initialize_Interval;
	 end record;
	 
	type Output_Array_t is array ( CI_Outputs) of C_and_I_Output_State_t;
	Output_Array : Output_Array_t;


	procedure Initialize;

	procedure Switch_C_and_I_Bit (Output : in out C_and_I_Output_State_t; 
										   To     : OFF_ON_t);
										  
	procedure Toggle_C_and_I_Bit (Output : in out C_and_I_Output_State_t);
	
	procedure Flash_C_and_I_Bit  (Output : in out C_and_I_Output_State_t); 
	
	procedure Update_Flashing_Outputs; -- Call at same rate as TI01s
	

	function  Input_Set_to_High  (Input  : in C_and_I_Input_State_t) 
																					return Boolean;
																					
	function  Input_Set_to_Low  (Input  : in C_and_I_Input_State_t) 
																					return Boolean;
																					
	
end CTRLS_and_INDICATORS;
