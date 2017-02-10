--***************************************************************************
--  File Name	  : ADC.ads
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
--				 	  : 23 Apr 2015: Changed (with ADC) to use VRef=2.56	
--				 	  :	bandgap reference to isolate from AVcc noise.
--				 	  :	
--				 	  :	
--***************************************************************************

with INTERFACES; use INTERFACES;
package ADC is

	type ADC_Processes is 
		(Waiting, Converting, Conversions_Complete);
	-- Can this be used for any & all ADC inputs?
	ADC_Process : ADC_Processes;

	type Result_Rec_t is
	  record
		High_Byte : Unsigned_8 := 0; -- ADCH
		Low_Byte  : Unsigned_8 := 0; -- ADCL
		Completed : Boolean := False;
	 end record;

	-- 0.0002 is 1/5000 which requires 13 bits. 
	--  This allows 3 bits (unsigned) for range; 2.56=VREF
	type Rdg_Volts_t is delta 0.0001 range 0.0 .. 2.56; -- Was 3.3
	for  Rdg_Volts_t'Size use 16;
	
	LSB8 : constant Rdg_Volts_t := 2.56/(2**8-1);  -- 0.0088471v.
	LSB10: constant Rdg_Volts_t := 2.56/(2**10-1); -- 0.0025024v.
	
	
	type Res_Select_Options is (Res10, Res8);
	-- ADLAR=0 => Right-justified for Res10
	procedure Set_ADC_Res (To : in Res_Select_Options);
	
	-- *********** Add call to set Res selection via C_and_I pkg... ***********
	
	function ADC_Res_Select_Value return Res_Select_Options;
	
	procedure Update_Res_Select;
	-- Based on reading a "switch" input in C_and_I pkg...

	
	procedure Initialize;
	
	procedure Start_Conversion;
	
	function Conv_Complete return Boolean;
	
	function Get_Result return Result_Rec_t;
	
	function Compute_Volts_From_ADC return Rdg_Volts_t;

	
end ADC;
