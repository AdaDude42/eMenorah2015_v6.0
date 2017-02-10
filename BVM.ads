--***************************************************************************
--  File Name	  : BVM.ads
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

package BVM is

	procedure Initialize;
	
	procedure Run_BVM;
	
end BVM;
