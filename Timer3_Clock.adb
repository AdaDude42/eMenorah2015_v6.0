--*******************************************************************
--  File Name	  : Timer3_Clock.adb
--  Version	 : 1.0
--  Description  : Uses Timer3 at 10msec period for Timeout controls
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 27 Sep 2014
--					  :	Added header to file.
--*******************************************************************
with INTERFACES; use INTERFACES;
package body TIMER3_CLOCK is

	Time_Base  : Natural := 0;
	Tenth_Secs : Natural range 0..9  := 0;
	Seconds    : Natural range 0..59 := 0;
	Minutes    : Natural range 0..59 := 0;
	Hours      : Natural range 0..23 := 0;
	
	Local_Time : Time_t;
	
	EM : INTERFACES.Unsigned_32 := 0;  -- Elapsed Minutes
	ES : INTERFACES.Unsigned_32 := 0;  -- Elapsed Seconds
	
	pragma VOLATILE (Local_Time);
	pragma VOLATILE (Tenth_Secs);
	pragma VOLATILE (Seconds);
	pragma VOLATILE (Minutes);
	pragma VOLATILE (Hours);	
	pragma VOLATILE (EM);
	pragma VOLATILE (ES);		
	-- Updated in Timer3 Interrupt thread via call to Update;
	
	pragma OPTIMIZE(Time);
	
	procedure Update is  -- Call at 10msec period (0.01 sec)
	
	begin
	
		if Time_Base < Natural'Last then
			Time_Base := Time_Base + 1;
		else
			Time_Base := 0;
		end if;
	
		if (Time_Base mod 10 = 0) then -- .1 sec elapsed; update the time
		
		   if Tenth_Secs < 9 then
		      Tenth_Secs := Tenth_Secs + 1;
			else 
			   Tenth_Secs := 0;
			end if;
		
			if (Tenth_Secs = 0) then -- 10*0.1 = 1 sec passed
			
				if ES < (Unsigned_32'Last - 1) then
					ES := ES + 1;
				else
					ES := 0;
				end if;
			
				if Seconds < 59 then
					Seconds := Seconds + 1;
				else 
					Seconds := 0;
				end if;
		
				if (Seconds = 0) then -- 1 min passed
				
			
					if EM < (Unsigned_32'Last - 1) then
						EM := EM + 1;
					else
						EM := 0;
					end if;
					
					if Minutes < 59 then
						Minutes := Minutes + 1;
					else 
						Minutes := 0;
					end if;

				end if;
			
				if (Minutes = 0) then -- 1 hour passed
					if Hours < 23 then
						Hours := Hours + 1;
					else 
						Hours := 0;
					end if;
				end if;
				
			end if;
			
		end if;
		
		Local_Time := (Tenth_Secs,Seconds, Minutes, Hours);
		
	exception
	
		when others =>
		   null;
		
	end Update;
	
	function Time return Time_t is
	begin
	   return Local_Time;
	end Time;
	
	function Elapsed_Minutes return INTERFACES.Unsigned_32 is
	begin
		return EM;
	end Elapsed_Minutes;
	
	function Elapsed_Seconds return INTERFACES.Unsigned_32 is
	begin
		return ES;
	end Elapsed_Seconds;

	function Current_Seconds return Natural is
	begin
		return Seconds;
	end Current_Seconds;
	
end TIMER3_CLOCK;
