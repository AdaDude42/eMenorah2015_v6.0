--*******************************************************************
--  File Name	  : ATmega2560_Timers-TC1345-PWM.ads
--  Version	 	  : 1.0
--  Description  : AVR TIMER/Counter Setup API Top Unit
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNAT GPL-2012 avr_cross
--  IDE          : Atmel AVR Studio 6.1
--  Programmer   : AVR STK-600 Bootloader
--  Last Updated : 11 July 2014
--*******************************************************************

with ATmega2560_Timers;
package ATmega2560_Timers.TC1345.PWM is

	-- Min Freq = .5Hz; Max T=2 Sec  Max Possible T with F_Clk_IO=1 Mhz is 
	--   1/F_PFC_PWM_Max corresponds to TOP min=3
	-- F_PFC_PWM_Max = 1_000_000/(2*8*3) => 1_000_000 / 48 => 20_833 Hz; Prescale=N=8
	-- Period_Min = 1/20_833 => 48 usec
	-- These are not really meaningful for PWM...use F_PFC_PWM delta 0.1 range 32..600;
	-- Period_Sec range is reverse 0.00167..0.03125;
	
	subtype Freq_t is Integer range 32..600;
	
	type Percent_t is delta 0.01 range 0.00..100.00;
	
	type PWM_Ports_t is 
		(OC1A_PB5, OC1B_PB6, OC1C_PB7, OC3A_PE3, OC3B_PE4, OC3C_PE5, 
		 OC4A_PH3, OC4B_PH4, OC4C_PH5, OC5A_PL3, OC5B_PL4, OC5C_PL5);
							 
	procedure Enable_PWM
		(Port : PWM_Ports_t; COM_Val : COM_Mode_t; FPWM : Freq_t); 
	-- Sets "TOP" for TC in ICRn or OCRnA as required by Mode
	-- Example of useage:
	-- package A2560T_1345_PWM renames ATmega2560_Timers.TC1345.PWM;
	--	A2560T_1345_PWM.Enable_PWM(Port => A2560T_1345_PWM.OC3A_PE3, FPWM => 300);
	
--	procedure Set_Duty_Cyc(Port : PWM_Ports; Duty_Cyc : Percent_t);

	
end ATmega2560_Timers.TC1345.PWM;
