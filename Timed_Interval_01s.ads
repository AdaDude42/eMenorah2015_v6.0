--*******************************************************************
--  File Name	  : Timed_Interval_01s.ads
--  Version	 : 1.0
--  Description  : Uses Timer3 at 10msec period for Timeout controls
--   This package provides a method of timing intervals based on a 
--   10 msec timer.  Routines exported by the package are Increment,         
--   Initialize_Interval, and Interval_Expired.  Start_Time and  
--   Time_Interval are  private types exported  which are required for use   
--   of  these routines.                                                     
--                                                                           
-- Methodology:: The Increment procedure provides the mechanism for          
--   maintaining a reference cycle counter for use in determining elapsed    
--   time intervals.  The call to this routine should be located in a place  
--   known to be executed on every task cycle.  Automatic counter rollover   
--   is handled internally when the interval counter  reaches the upper      
--   limit.                                                                  
--                                                                           
--   Intervals are initialized with a call to the Initialize_Interval        
--   function which returns a Start_Time (copy of the current main interval  
--   counter value).   This  Start_Time is supplied to the Interval_Expired  
--   function to determine if the  desired time has elapsed.  A Start_Time   
--   variable should be created for each  timing interval to be measured.    
--                                                                           
--   Elapsed time is determined by the Interval_Expired function which       
--   returns a  boolean value of true when the desired time interval has     
--   passed.  It is supplied with the Interval_Start_Time (the Start_Time    
--   variable returned from the  Initialize_Interval function), and the      
--   Elapsed_Time (a Time_Interval variable  declared or visible to the      
--   unit issuing the Interval_Expired function call).                       
--                                                                           
-- Calling Sequences::  The Increment routine is called once at the start of 
--   each Interval.  The Intialize_Interval is called at the beginning of an 
--   interval to be measured,  and the Interval_Expired is called on         
--   each subsequent interval  to determine if the requested interval has    
--   elapsed.                                                                
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

package TIMED_INTERVAL_01s  is -- 10 msec time base

   type Time_Interval_t is delta 0.01 range 0.0 .. 864_000.0;
	for Time_Interval_t'Size use 32;

	Counter_Time_Interval : constant Time_Interval_t := 0.01;
 
   type Start_Time is private;

   Seconds_Per_Day : constant Time_Interval_t := 86400.00;
  
   procedure Increment;

   function Initialize_Interval return Start_Time;

   function Interval_Expired (Interval_Start_Time : in Start_Time ;
                           Elapsed_Time : in Time_Interval_t) return boolean ;

private 

   type Start_Time is new Long_Integer;  

end TIMED_INTERVAL_01s;
----------------------------------------------------------------------------
