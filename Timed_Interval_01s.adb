--***************************************************************************
--  File Name	  : Timed_Interval_01s.ads                                    
--  Version	 	  : 1.0                                                        
--  Description  : Uses Timer3 at 10msec period for Timeout controls         
--   This package body contains intialization data and the                   
--   bodies of the routines which provide the timing functions.              
--                                                                           
--   Methodology :  The Main_Interval_Counter is initialized in the          
--   declarative part the Timer package body.  It is the variable used to    
--   count elapsed cycles.  The Increment routine contains a check to insure 
--   when the Main_Interval_Counter reaches its upper limit, that it will    
--   rollover.   When a time interval is to be measured, the Initialize      
--   routine  is called which returns a copy of the Main_Interval_Counter.   
--   However, since the Main_Interval_Counter could have rolled over since   
--   the call to the Intialize_Interval routine,  the Interval_Expired       
--   routine requires an additional check for the case in which the          
--   Main_Interval_Counter has rolled over since the call to the             
--   Initialize_Interval call.
--                                            
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNATMAKE GPL 2012 (20120509)
--  IDE          : Atmel AVR Studio 4.18
--  Programmer   : AVRJazz Mega168 STK500 v2.0 Bootloader
--               : AVR STK-600
--  Last Updated : 20 Mar 2015
--					  :	Created file.
--*******************************************************************
------------------------------------------------------------------------------
                       -- Generic Timer Package Body --
------------------------------------------------------------------------------
package body TIMED_INTERVAL_01s is

   Main_Interval_Counter : Start_Time := 1;

   Cycles  : constant Time_Interval_t :=                  -- Cycles per sec.
	  Time_Interval_t( 1.0 / (Counter_Time_Interval) ) ; 
	
------------------------------------------------------------------------------

   procedure Increment is

   begin 

      if Main_Interval_Counter = Start_Time'last then
         Main_Interval_Counter := 1;
      else
         Main_Interval_Counter := Main_Interval_Counter + 1;
      end if;

   end increment;
------------------------------------------------------------------------------

   function Initialize_Interval return Start_Time is
   
   begin

      return Main_Interval_Counter;

   end Initialize_Interval;
-----------------------------------------------------------------------------

   function Interval_Expired (Interval_Start_Time : in Start_Time ;
								    Elapsed_Time : in Time_Interval_t) return Boolean is
									 
		Result : Boolean;

   begin
	
		if Interval_Start_Time > Main_Interval_Counter then
		 Result :=
		
			( ( (Start_Time'last - Interval_Start_Time) 
				+ Main_Interval_Counter) >=
				 Start_Time (Cycles * Elapsed_Time) );
		
      else
		
         Result :=  ((Main_Interval_Counter - Interval_Start_Time) >= 
                     Start_Time (Cycles * Elapsed_Time) ) ;
							
      end if;
	
		return Result;
			

   end Interval_Expired;
------------------------------------------------------------------------------
		
end TIMED_INTERVAL_01s;
