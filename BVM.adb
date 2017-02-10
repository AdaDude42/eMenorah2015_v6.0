--***************************************************************************
--  File Name	 : BVM.adb
--  Version	 : 1.0.1
--  Description  : Provides Battery Voltage Monitoring for eMenorah
--		 : In this program the’ initialize ()’ routine is used
--		 : to initialize the ADC module. The ‘convert ()’ routine
--		 : has to be called whenever the application needs an
--		 : ADC conversion.
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 01 Apr 2015 Created
--		 : 07 Apr 2015 Modified LED Range Limits
--		 : 11 Apr 2015 Add LP Filt, Spike rejection, Hyst.
--		 : 13 Apr 2015 Having problems with this working- noisy ADC
--               :   Increase Spike rej limit...
--
-- Test use of LP Filter + Spike Elimination
--   for eMenorah Battery Voltage Monitor.
--
-- 1. Using 10-bits from ADC; ADC_Max=1023
-- 2. VRef = AVcc ~= 3.3v nominally; have measured 3.2597 actual
-- 3. Take ADC voltage reading LSb value as = 3.3/1023 = 0.00322580645
-- 4. Define Fixed Pt Voltages as type Fx16 delta 0.001 range 0.000..3.300
--       This produces a 'Small = 0.000061035156250.
--       LSb/'Small = 0.00322580645 / 0.000061035156250 = 52.8516129
--
-- 10 Apr 2015:
-- 5. Add Spike Rejection. If new Meas <> Prev Meas by > .1v ignore it
--       if |Meas - Prev_Meas| > 0.045 ignore Meas. (0.045 = 15*LSb)
-- 6. Add Hysteresis for selecting LED Indicator state...
--    Hys_Val : Fx16 := 4.0*LSb; Applied to Filtered Measurement
--****************************************************************************
-- 13 Apr 2015:
-- 7.   New design flow for BVM.adb
--
--    BVM.Run_BVM called from main infinite loop as fast as possible- no
--   Time delays in call
--    Major modes of operation: Startup, Filter_Init, Monitoring.
--    Startup:
--       Wait for Startup_Interval sec for S/C to charge;
--         While waiting...
--          Flash_GRN LED; Show C3 on STK600 LEDs using PORTH;
--          After Startup_Delay_Interval sec, start taking ADC readings.
--             Start Interval for Filter_Init...
--             Read ADC conversions...
--             Display readings on PORTH;
--             Average them to use to initialize LP_Filter;
--          Once LP_Filter is primed, check the Filtered_Meas for
--             realistic value...>= 1.9 ?? and rate of change??
--             Filtered_Meas deltas < 0.1v/sample (< Spike_V)
--          if Filtered_Meas_OK then
--             Set_LED_GRN;
--             proceed to Monitoring...
--          else
--             Flash_LED_RED;
--           end if;
--
--       Intervals:
--          Startup :: SC_Charge (10.0sec) + Filter_Prep(2.0sec)
--          ADC Conversion Interval => Next_ADC for BV monitoring (5.0sec)
--          ADC_Result_Display ADCH...ADCL alternation interval 2.0 sec
--          PWR_LED flash interval (0.5sec)
--
--****************************************************************************
-- 10 Dec 2015:
--    Decided to eliminate the Flashing_Green State for initial low battery 
--    indication. User needs to have Flashing Green only during startup and 
--    charging Shamash. Then, BVM should Either stay solid green, or use 
--		Red- Flashing, then Solid.

--****************************************************************************

with ADC; use ADC;
with ATMega2560;
with CTRLS_AND_INDICATORS;
with INTERFACES; use INTERFACES; -- Unsigned_8, etc
with TIMED_INTERVAL_01s;
package body BVM is

	package A2560   renames ATMega2560;
	package C_and_I renames CTRLS_AND_INDICATORS;
	use C_and_I;
	package TI01s	renames	TIMED_INTERVAL_01s;

--------------------------------- ADC Data Related  -------------------------
	-- Computed in ADC
	BVM_Result : ADC.Result_Rec_t;

	-- Voltage monitoring range definitions:
	subtype ADC_V_t is ADC.Rdg_Volts_t;
   GRN_Low_Limit        : constant ADC_V_t := 2.250; -- Flash GRN if below
   Flash_GRN_Low_Limit  : constant ADC_V_t := 2.050; -- Flash RED if Below
   Flash_RED_Low_Limit  : constant ADC_V_t := 1.870; -- Solid RED if Below

   subtype GRN_Range       is ADC_V_t
           range GRN_Low_Limit       .. ADC_V_t'Last;
   subtype Flash_GRN_Range is ADC_V_t
           range Flash_GRN_Low_Limit .. ADC_V_t'Pred(GRN_Range'First);
   subtype Flash_RED_Range is ADC_V_t
           range Flash_RED_Low_Limit .. ADC_V_t'Pred(Flash_GRN_Range'First);
   subtype RED_Range       is ADC_V_t
           range 0.000               .. ADC_V_t'Pred(Flash_RED_Range'First);

   -- NOTE: If Battery voltage drops below the Dropout voltage (1.8v) of the
   --  LTC3127, there will no longer be power to the eMenorah main board
   --  and no LEDs will light at all. NiMH cells typically hold 1.2 each
   --  (2.4 for the 2 AA Batts) until nearly depleted.


-------------------------------- Processing States  -------------------------

	type BVM_States is (Startup, Filter_Init, Running);
	BVM_State : BVM_States;

-- Processing Time Intervals:
--          Startup :: SC_Charge (10.0sec) + Filter_Prep(2.0sec)
--          ADC_Conversion_Interval for BV monitoring (5.0sec)
--          ADC_Result ADCH...ADCL alternation interval 2.0 sec
--          PWR_LED flash interval (0.5sec)


	-- Allow time for Supercap in Shamash to charge and batts to recover
	Startup_Timer    : TI01s.Start_Time;
	Startup_Interval : constant TI01S.Time_Interval_t := 10.0;

	-- Allow time for LP_Filter Initialization
	Filter_Init_Timer    : TI01s.Start_Time;
	Filter_Init_Interval : constant TI01S.Time_Interval_t := 2.0;

	-- Conversion Interval timing:
	Next_ADC_Timer    : TI01s.Start_Time;
	Next_ADC_Interval : constant TI01s.Time_Interval_t := 0.1;

   ADC_Errors        : Unsigned_8 := 0;
	Conversion_Cycles : Unsigned_8 := 0;
	Do_First_Meas     : Boolean    := True;
   New_Meas_Ready    : Boolean    := False;

	-- Timed delay vars for displaying result...
	ADC_Result_Disp_Timer	: TI01s.Start_Time;
	ADC_Result_Disp_Interval: constant TI01S.Time_Interval_t := 2.0;

	Display_BVM_High : Boolean := True; -- Used to alternate ADCH:ADCL display

	-- Power LED States and Flash Timing:
	type PWR_LED_States is (Green, Flash_GRN, Flash_RED, RED);
	PWR_LED_State : PWR_LED_States;

	PWR_LED_Flash_Timer 	: TI01s.Start_Time;
	PWR_LED_Flash_Interval	: constant TI01s.Time_Interval_t := 0.5;

	BVM_Monitor_Delay_Interval : TI01S.Time_Interval_t := 0.5;

	-- Batt voltage measurement and filtering, spike rejection and hysteresis
    Initial_Meas	: ADC_V_t;
    Filtered_Meas	: ADC_V_t;
	 BV_Meas_Volts	: ADC_V_t;
    Spike_V_Tol	: ADC_V_t := 0.2048387097;  -- added 0.2000; works now!!
	 LED_Hyst_V	   : ADC_V_t := 0.05;
	 -- ADC_V_t LSb10 ~ 0.0031734
	 -- ADC_V_t'Small ~ 0.00048828

-----------------------------------------------------------------------------
   procedure Initialize is
   begin

       --Initialize_Timers_Etc;

       BVM_State     := Startup;

       Startup_Timer := TI01s.Initialize_Interval;

       -- Display 0xC3 to show running but not doing BVM yet
       A2560.PORTH := NOT(16#C3#);

       ADC_Result_Disp_Timer  := TI01s.Initialize_Interval;

       PWR_LED_Flash_Timer 	:= TI01s.Initialize_Interval;

       PWR_LED_State  := Flash_GRN;

       ADC_Process    := Waiting;

		 Do_First_Meas  := False;

       New_Meas_Ready := False;

   end Initialize;

-----------------------------------------------------------------------------
   function Ready_For_New_Conversion return Boolean is

      Ready_For_New_Conv : Boolean := False;

   begin

      if (TI01S.Interval_Expired
         (Next_ADC_Timer, Next_ADC_Interval)) then

         Ready_For_New_Conv := True;

         Next_ADC_Timer := TI01s.Initialize_Interval;

      end if;

      return Ready_For_New_Conv;

   end Ready_For_New_Conversion;

---------------------------------- Reject_Spike -----------------------------
   function Spike_Detected (Noisy_Meas : in ADC_V_t) return Boolean is
   -- Return=True if a Spike is detected and rejected

      pragma SUPPRESS(All_Checks);

   begin

      return (abs(Noisy_Meas-Filtered_Meas) > Spike_V_Tol);

   end Spike_Detected;

---------------------------------- LP_Filter --------------------------------
   function LP_Filter (Noisy_Meas : in ADC_V_t) return ADC_V_t is

      pragma SUPPRESS(ALL_CHECKS);

   begin

      Filtered_Meas := (0.05*Noisy_Meas + 0.95*Filtered_Meas);

      return Filtered_Meas;

   end LP_Filter;

------------------------------  Power LED Controls  -------------------------
   procedure Set_LED_GRN is
   begin
   	C_and_I.Switch_C_and_I_Bit (Output_Array(Power_RED), OFF);
   	C_and_I.Switch_C_and_I_Bit (Output_Array(Power_GRN), ON);
   end Set_LED_GRN;

   procedure Flash_LED_GRN is
   begin
   	C_and_I.Switch_C_and_I_Bit (Output_Array(Power_Red), OFF);
   	C_and_I.Toggle_C_and_I_Bit (Output_Array(Power_Grn));
   end Flash_LED_GRN;

   procedure Set_LED_RED is
   begin
   	C_and_I.Switch_C_and_I_Bit (Output_Array(Power_Grn), OFF);
   	C_and_I.Switch_C_and_I_Bit (Output_Array(Power_RED), ON);
   end Set_LED_RED;

   procedure Flash_LED_RED is
   begin
   	C_and_I.Switch_C_and_I_Bit (Output_Array(Power_Grn), OFF);
   	C_and_I.Toggle_C_and_I_Bit (Output_Array(Power_RED));
   end Flash_LED_RED;

------------------------------  Display ADC Results  ------------------------
   procedure Display_Result is

		pragma SUPPRESS(ALL_CHECKS);
		
   	Hyst : ADC_V_t renames LED_Hyst_V ;

   begin
	
		case BVM_State is
		
			when Running =>

				if (ADC.ADC_Res_Select_Value = ADC.Res10) then -- High_Res
				-- Alternate display of ADCH--ADCL

					if TI01s.Interval_Expired
						(ADC_Result_Disp_Timer, ADC_Result_Disp_Interval) then

						ADC_Result_Disp_Timer := TI01s.Initialize_Interval;

						if (Display_BVM_High) then
							A2560.PORTH := NOT(BVM_Result.High_Byte); --STK600 LEDs active low.
							Display_BVM_High := False;
						else
							A2560.PORTH := NOT(BVM_Result.Low_Byte);  --STK600 LEDs active low.
							Display_BVM_High := True;
						end if;
			
					end if;
			
				else -- Display ADCH only

					A2560.PORTH := NOT(BVM_Result.High_Byte);

				end if;
				
			when others =>
				A2560.PORTH := NOT(16#C3#); --STK600 LEDs active low.
				
		end case;

   end Display_Result;

-----------------------------  Manage PWR LED State  ------------------------
   procedure Update_PWR_LED is
	begin

      if TI01s.Interval_Expired
        (PWR_LED_Flash_Timer, PWR_LED_Flash_Interval) then

         PWR_LED_Flash_Timer := TI01s.Initialize_Interval;

       	if (BVM_State = Startup) then

       	  C_and_I.Switch_C_and_I_Bit (Output_Array(Power_Red), OFF);
           C_and_I.Toggle_C_and_I_Bit (Output_Array(Power_Grn));

       	else

           -- Do live updates of the Battery Voltage LED
           -- BV_Measured   := ADC.Compute_Volts_From_ADC;

           --Filtered_Meas := LP_Filter(BV_Meas_Volts);
			  
			  --GRN_Range       = 2.250 .. ~3.300                -- Solid GRN
			  --Flash_GRN_Range = 2.050 ..  2.250-LSb (~2.2495)  -- Flash GRN
			  --Flash_RED_Range = 1.825 ..  2.050-LSb (~2.0495)  -- Flash RED 
			  --RED_Range       = 0.000 ..  1.825-LSb (~1.8245)  -- Solid RED

			  -->> means voltage increasing (unlikely) and <<-- means voltage
               -- decreasing (expected); if -->> Must rise above lim + Hyst and
					--  if <<-- Must fall below lim - Hyst
					--  Hyst ~ 0.0127v

			  -- Solid GRN: if
           -- Filtered_Meas  > 2.2627 = (2.2495 + ~0.0127) if -->>
			  
			  -- Flash GRN: if
           -- Filtered_Meas  < 2.2373 = (2.250 - ~0.0127)  if <<-- 
           -- Filtered_Meas  > 2.0627 = (2.050 + ~0.0127)  or if -->> 
			  
			  -- Flash RED: if		  
           -- Filtered_Meas  < 2.034  = (2.050 - ~0.0127)  if <<--  
           -- Filtered_Meas  > 1.8377 = (1.825 + ~0.0127)  or if -->> 
			  
			  -- Solid RED: if
           -- Filtered_Meas  < 1.812  = (1.825 - ~0.0127)  if <<--
			  

           -- Manage changes to PWR LED State; No Hyst when decreasing
           case PWR_LED_State is

           when Green =>

            Set_LED_GRN;

				if (Filtered_Meas < RED_Range'Last) then
					Set_LED_RED;
					PWR_LED_State := RED;
				elsif (Filtered_Meas < Flash_RED_Range'Last) then
					Flash_LED_RED;
					PWR_LED_State := Flash_RED;
				--elsif (Filtered_Meas < Flash_GRN_Range'Last) then
				-- Let is stay Green... 10Dec2015
				--	Flash_LED_GRN;
				--	PWR_LED_State := Flash_GRN;
				end if;

           when Flash_GRN => -- Should not ever be anymore- Remove this code

				Flash_LED_GRN;

				if (Filtered_Meas > GRN_Range'First + LED_Hyst_V) then
					Set_LED_GRN;
					PWR_LED_State := Green;
				elsif (Filtered_Meas < RED_Range'Last) then
					Set_LED_RED;
					PWR_LED_State := RED;
				elsif (Filtered_Meas < Flash_RED_Range'Last) then
					Flash_LED_RED;
					PWR_LED_State := Flash_RED;
				end if;


           when Flash_RED =>

				Flash_LED_RED;

				if (Filtered_Meas > GRN_Range'First + LED_Hyst_V) then
					Set_LED_GRN;
					PWR_LED_State := Green;
				elsif (Filtered_Meas > Flash_GRN_Range'First + LED_Hyst_V) then
					Set_LED_GRN;
					PWR_LED_State := Green;
					--Flash_LED_GRN;
					--PWR_LED_State := Flash_GRN;
				elsif (Filtered_Meas < RED_Range'Last) then
					Set_LED_RED;
					PWR_LED_State := RED;
				end if;


           when RED =>

				Set_LED_RED;

				if (Filtered_Meas > GRN_Range'First + LED_Hyst_V) then
					Set_LED_GRN;
					PWR_LED_State := Green;
				elsif (Filtered_Meas > Flash_GRN_Range'First + LED_Hyst_V) then
					Set_LED_GRN;
					PWR_LED_State := Green;
					--Flash_LED_GRN;
					--PWR_LED_State := Flash_GRN;
				elsif (Filtered_Meas > Flash_RED_Range'First + LED_Hyst_V) then
					Flash_LED_RED;
					PWR_LED_State := Flash_RED;
				end if;

           end case; -- PWR_LED_State

        end if; -- Startup Delay

      end if; -- Interval Expired

      exception
		when others =>
			null;

   end Update_PWR_LED;

-------------------------------  Get new ADC Measurement  -------------------
   procedure Update_ADC_Measurement is
	
		pragma SUPPRESS(ALL_CHECKS);
	begin
	
      case ADC_Process is

         when Waiting =>

            if Ready_For_New_Conversion then

               New_Meas_Ready := False;

               ADC.Start_Conversion;
               ADC_Process := Converting;

            end if;

         when Converting =>

            if TI01s.Interval_Expired
               (Next_ADC_Timer, Next_ADC_Interval) then

               if ADC.Conv_Complete then
               -- Do (n=2) conversions; Results within TBD_LSBs

                   if (Conversion_Cycles < 2) then
							ADC.Start_Conversion; -- clears ADIF....
							Conversion_Cycles := Conversion_Cycles + 1;
                   else
                      BVM_Result := ADC.Get_Result;
                      if BVM_Result.Completed then
                        Conversion_Cycles := 0;
                        ADC_Process := Conversions_Complete;
                      end if;
                   end if;

               else
                  -- Should have completed previous conversion...
                  if ADC_Errors < Unsigned_8'Last then
                     ADC_Errors := ADC_Errors + 1;
                  end if;

               end if;

            end if;


          when Conversions_Complete =>

             Update_Res_Select;
             BV_Meas_Volts := ADC.Compute_Volts_From_ADC;
             New_Meas_Ready := True;

             if Do_First_Meas then
                Do_First_Meas := False;
       	        Filtered_Meas := ADC.Compute_Volts_From_ADC;
       	     end if;

       	     ADC_Process := Waiting;
				  
			 when others =>
				 null;

      end case; -- ADC_Process

   end Update_ADC_Measurement;

-----------------------------------------------------------------------------
   procedure Run_BVM is
   begin
	
      --States: Startup, Filter_Init, Running

      case BVM_State is

          when Startup =>
			-- Allow time for Supercap in Shamash to charge and batts to recover

             Update_PWR_LED;

             if TI01s.Interval_Expired (Startup_Timer, Startup_Interval) then
                BVM_State         := Filter_Init;
					 Filter_Init_Timer := TI01s.Initialize_Interval;
                Do_First_Meas     := True;
					 PWR_LED_State 	 := Green; -- Added 10Dec2015
             end if;


          when Filter_Init =>

             Update_ADC_Measurement;

             if New_Meas_Ready then
                Filtered_Meas  := LP_Filter (Noisy_Meas => BV_Meas_Volts);
                New_Meas_Ready := False;
             elsif ADC_Errors > 0 then
                Set_LED_RED;
             end if;

             Update_PWR_LED;

             if TI01s.Interval_Expired
               (Filter_Init_Timer, Filter_Init_Interval) then
                BVM_State := Running;
             end if;


          when Running =>

             Update_ADC_Measurement; -- Interval timing inside

             if New_Meas_Ready then
                BVM_Result := ADC.Get_Result;

                BVM_Result.Completed := False;

                if True then --not Spike_Detected(BV_Meas_Volts) then

                   Filtered_Meas := LP_Filter(Noisy_Meas => BV_Meas_Volts);

                end if;

             end if;
				 
             Update_PWR_LED;
				 
				 
			 when others =>
				null;

      end case;

		Display_Result;

   	exception
   		when others =>
   			null;

   end Run_BVM;


end BVM;
