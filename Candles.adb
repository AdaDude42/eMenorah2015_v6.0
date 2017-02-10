--*******************************************************************
--  File Name	  : CANDLES.adb
--  Version	 : 1.1
--  Description  : Implements Candle control operations
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 27 Sep 2014
--               :    Added header to file.
--               : 06 Aug 2015
--               :    Fixed Norm_Demo_SW init-added to Initialize proc
--               : 23 Nov 2015
--               :    Add Sleep_Power_Down call if no candles are lit
--               :    or still running after expected Burnout time.
--               : 08 Dec 2015
--               :    Fixed typo on line 346
--*******************************************************************

with ATmega2560;
with CANDLES.PWM_Ada;
with RANDOM; use RANDOM;
with TIMER3_CLOCK;
with SYSTEM.Machine_Code;

with Unchecked_Conversion;

with CTRLS_and_INDICATORS;

package body CANDLES is

	package A2560     renames ATmega2560;
	package C_and_I	renames CTRLS_and_INDICATORS;
	use     C_and_I;
	package PWM       renames CANDLES.PWM_Ada;
	package T3_CLOCK  renames TIMER3_CLOCK;
	package Mach_Code renames SYSTEM.Machine_Code;
	
	function U16_to_U32 is new 
		Unchecked_Conversion(Source => Unsigned_16, Target => Unsigned_32);
	
	-- Normal-Demo Switch Input
	type Norm_Demo_Sw_t is (Normal, Demo);
	Norm_Demo_SW : Norm_Demo_Sw_t := Normal; -- (TBD) PORTCbits.RC0 1 = NORMAL

	i    : Candle_Number_t := 1;
	LEDm : Candle_Number_t := 1;
	cycleCtr : Unsigned_16 := 1;
	T0IntCtr : Unsigned_16 := 0; -- for time testing...

	tOffDelay : Unsigned_16 := 16#0000#; -- max delay for TMR0 (0000..FFFF)
	
	--LEDLit   : array(Candle_Number_t) of Lit_State_t := ( others => UnLit);
	--pragma PACK (LEDLit);
	
	NextChan : Candle_Number_t := 1; -- 1..8

	-- Burnout Delay Data: Delay for each candle is set when lit.
	Rand_Delay   : Unsigned_32 := 0;
	Normal_Delay : constant Unsigned_32 := Unsigned_32'(60*40); -- 40 minutes
	Demo_Delay   : constant Unsigned_32 := Unsigned_32'(60*2);  --  2 minutes
	
	-- Vars to support determination of whether to terminate processing and 
	-- enter Sleep Power Down mode. If no candles have been lit after 5 minutes
	-- from startup, or if Shutdown time has been reached based on Norm-Demo 
	-- mode, turn of Power LED and Norm-Demo LED then enter Sleep_PWR_Down.
	
	Shutdown_Delay_Norm : constant Natural := 58; -- minutes
	Shutdown_Delay_Demo : constant Natural := 3;  -- minutes
	Shutdown_Delay      : Natural := Shutdown_Delay_Norm;
	
	No_Candles_Lit : Boolean := True; -- None have been lit after Startup Init...
	
	---------------------------------------------------------------------------
	function Read_LED_Enable(Chan : Candle_Number_t) return Lit_State_t is

		Lit_State : Lit_State_t := UnLit;
		
	begin
	
		if (A2560.PinD = NOT(PWM.LED_On_Bits(Chan)) ) then
			Lit_State := Lit;
		end if;
		
		return Lit_State;
		
	end Read_LED_Enable;
	
	
	---------------------------------------------------------------------------
	procedure Initialize is
		
	begin
	
		-- Initialize the LED States
		Init_State:
		for LEDm in Candle_Number_t'Range loop  -- All LEDs
		
			LED_States(LEDm).E_D_State 	:= Disabled;
			LED_States(LEDm).prev_LEDLit	:= UnLit;
			LED_States(LEDm).LEDLit			:= UnLit;
			LED_States(LEDm).CurState		:= 0;
			
		end loop Init_State;
		
		A2560.DDRD  := 16#00#; -- PortD Inputs for Candle enables
		--A2560.PORTD := 16#FF#; -- Write 1's to PortD to enable Pull-UPs
		-- Not required since Reed Switches in Candles are tied to Vcc and
		--  provide active high input across grounded resistors.
		
		if C_and_I.Input_Set_to_High  (Input => C_and_I.Norm_Demo_SW) then
		
		   C_and_I.Switch_C_and_I_Bit (Output => C_and_I.Output_Array(ND_Normal_Grn),
		      To => C_and_I.ON);
		   C_and_I.Switch_C_and_I_Bit (Output => C_and_I.Output_Array(ND_Demo_Amber),
		      To => C_and_I.OFF);
				
		   Norm_Demo_SW   := Normal;
						
		else
		   C_and_I.Switch_C_and_I_Bit (Output => C_and_I.Output_Array(ND_Demo_Amber),
		      To => C_and_I.ON);
		   C_and_I.Switch_C_and_I_Bit (Output => C_and_I.Output_Array(ND_Normal_Grn),
		      To => C_and_I.OFF);
				
		   Norm_Demo_SW   := Demo;
			
		end if;

	end Initialize;
	
	
-----------------------------------------------------------------------------
procedure Enter_Power_Down_Mode is
begin

	-- Turn Off Indicator LEDs for PWR and Norm-Demo mode:
	-- (Power_Grn, Power_RED, ND_Normal_Grn, ND_Demo_Amber)
	C_and_I.Switch_C_and_I_Bit (Output => C_and_I.Output_Array(ND_Normal_Grn),
		To => C_and_I.OFF);
	C_and_I.Switch_C_and_I_Bit (Output => C_and_I.Output_Array(ND_Demo_Amber),
		To => C_and_I.OFF);
   C_and_I.Switch_C_and_I_Bit (Output => C_and_I.Output_Array(Power_RED), 
		To => C_and_I.OFF);
   C_and_I.Switch_C_and_I_Bit (Output => C_and_I.Output_Array(Power_GRN), 
		To => C_and_I.OFF);
		
	A2560.SMCR := 2#00000101#; -- Set SM1 and SE bits in SMCR

	Mach_Code.ASM("Sleep");

end Enter_Power_Down_Mode;	
	
-----------------------------------------------------------------------------
pragma OPTIMIZE(Time);
	procedure Process_Flicker (Candle_Num : in Candle_Number_t) is
	
		DC_Adjust : Unsigned_8;
		
	begin

			if (LED_States(Candle_Num).CurState = 0) then --=> -- Start lighting

				PWM.ledTargetBrightness(Candle_Num) := 2;
				LED_States(Candle_Num).CurState := 1;
				BlinkCtrs(Candle_Num) := 0;
				
				PWM.MinLedTargetBrightness := 2; -- Inserted 8Aug2015
 
			elsif (LED_States(Candle_Num).CurState = 1) then --=>

				if (BlinkCtrs(Candle_Num) >= 1000) then

					PWM.ledTargetBrightness(Candle_Num) := 10;
					LED_States(Candle_Num).CurState := 2;
					BlinkCtrs(Candle_Num) := 0;

				end if;
 
          
			elsif (LED_States(Candle_Num).CurState = 2) then -- =>

				if (BlinkCtrs(Candle_Num) >= 1000) then

					PWM.ledTargetBrightness(Candle_Num) := 3;
					LED_States(Candle_Num).CurState := 3;
					BlinkCtrs(Candle_Num) := 0;
				
				end if;
      
			elsif (LED_States(Candle_Num).CurState = 3) then -- =>

				if (BlinkCtrs(Candle_Num) >= 500) then

					PWM.ledTargetBrightness(Candle_Num) := 8;
					LED_States(Candle_Num).CurState := 4;
					BlinkCtrs(Candle_Num) := 0;
			
				end if;
  
			elsif (LED_States(Candle_Num).CurState = 4) then -- =>

				if (BlinkCtrs(Candle_Num) >= 1000) then

					PWM.ledTargetBrightness(Candle_Num) := 10;
					LED_States(Candle_Num).CurState := 5;
					BlinkCtrs(Candle_Num) := 0;

				end if;

			elsif (LED_States(Candle_Num).CurState = 5) then -- =>

				if (BlinkCtrs(Candle_Num) >= 1000) then

					PWM.ledTargetBrightness(Candle_Num) := 17;
					LED_States(Candle_Num).CurState := 6;
					BlinkCtrs(Candle_Num) := 0;
			
				end if;
 
			elsif (LED_States(Candle_Num).CurState = 6) then -- =>
     
				if (BlinkCtrs(Candle_Num) >= 100) then
		 
					DC_Adjust := (Shift_Right(Rand_U8,4));
					
					if DC_Adjust > PWM.MAX_Bright then
						DC_Adjust := PWM.MAX_Bright-15;
					end if;
		 
					PWM.ledTargetBrightness(Candle_Num)  := DC_Adjust;

					LED_States(Candle_Num).E_D_State := Burning;
					BlinkCtrs(Candle_Num) := 0;
					LED_States(Candle_Num).CurState := 6;
					
				end if;
				
			else
				
				null;
				
			end if;
 
	exception
		when others =>
		
			null;
         
	end Process_Flicker;


	procedure Process_All is
	
	begin
	
      if (LED_States(nextChan).E_D_State = Disabled) then

 		--read_LED_Enable(LEDLit) obtains the states of the "Lit" indicators
			
			if (LED_States(nextChan).prev_LEDLit = UnLit) and then
				(read_LED_Enable(nextChan) = Lit) then
				
				LED_States(nextChan).prev_LEDLit := Lit;
				LED_States(nextChan).LEDLit := Lit;
				LED_States(nextChan).E_D_State := Lighting;
				
				-- Initialize the TurnOff Timeouts
				Rand_Delay := U16_to_U32((Rand_U16 AND 16#003F#));
				
				-- Reset the Shutdown trigger based on no candles lit.
				No_Candles_Lit := False;

				if (Norm_Demo_SW = Normal) then
					LED_States(nextChan).LED_Off_Seconds := -- 40 Minutes
						Normal_Delay + Rand_Delay;
					
				else -- DEMO => 2 Minutes timeout...
					LED_States(nextChan).LED_Off_Seconds := 
						Demo_Delay + Rand_Delay;
				end if;
				
			end if;
				 
      end if;
		
		-- don't try to light them all at once
      if nextChan < Candle_Number_t'Last then
			NextChan := nextChan + 1;
		else
			nextChan := Candle_Number_t'First;
		end if;

		-- Process based on Candle state
      for LEDm in Candle_Number_t'Range loop  -- All LEDs
      
         case (LED_States(LEDm).E_D_State) is
	 	  
            when Disabled =>
				
					PWM.ledTargetBrightness(LEDm) := 0;

				when Lighting =>
				
					Process_Flicker(LEDm); -- includes transition to "Burning"
                             
				when Burning =>
				
					Process_Flicker (LEDm);
					
					if T3_CLOCK.Elapsed_Seconds > 
						LED_States(LEDm).LED_Off_Seconds then
              
						LED_States(LEDm).E_D_State := Burnout;
						LED_States(LEDm).curState  := 0;
					 
						C_and_I.Switch_C_and_I_Bit 
						 (Output  => C_and_I.Output_Array(Shamash_Enable), To => C_and_I.OFF);

					end if;

				when Burnout =>
           
					PWM.MinLedTargetBrightness    := 0; -- Inserted 8Aug2015
					PWM.ledTargetBrightness(LEDm) := 0;
					
         end case;
			
			BlinkCtrs(LEDm) := BlinkCtrs(LEDm) + 1;
		
		end loop;
		
		
		-- Check to enter Sleep Power Down if no activity and power still on (we are running)
		
		if No_Candles_Lit and then (T3_CLOCK.Time.Minute >= 5) then
		
			Enter_Power_Down_Mode;
		
		else

		   if ((Norm_Demo_SW = Normal) and (T3_CLOCK.Time.Minute >= Shutdown_Delay_Norm)) or
			   ((Norm_Demo_SW = Demo)   and (T3_CLOCK.Time.Minute >= Shutdown_Delay_Demo)) then
		   -- We're still running after all lit Candles should have expired so 
			--  shutdown to save power
			   Enter_Power_Down_Mode;
			end if;
				
		end if;


	exception
		when others =>
			null;
         
   end Process_All;


end CANDLES;