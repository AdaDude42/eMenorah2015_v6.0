--***************************************************************************
--  File Name	  : ATmega2560_Timers-TC1345-PWM.adb
--  Version	 	  : 1.0
--  Description  : AVR TIMER/Counter Setup API Top Unit
--  Author       : JMA
--  Target       : AVR STK-600-2560
--  Compiler     : GNAT GPL-2012 avr_cross
--  IDE          : Atmel AVR Studio 6.1
--  Programmer   : AVR STK-600 Bootloader
--  Last Updated : 11 July 2014
--***************************************************************************

with ATmega2560; use ATmega2560;
with Interfaces; use Interfaces;
package body ATmega2560_Timers.TC1345.PWM is

	package TC1345 renames ATmega2560_Timers.TC1345;

	type Port_TC_COM_Assns is
	  record
		  TC	: TC1345.TC_Choices;
		  COM : TC1345.COM_Mode_Choices;
		end record;
	

	type PWM_Port_Info_t is array(PWM_Ports_t) of Port_TC_COM_Assns;
	PWM_Port_Info : PWM_Port_Info_t :=
	   (OC1A_PB5 =>(TC1,COMA), OC1B_PB6 =>(TC1,COMB), OC1C_PB7 =>(TC1,COMC),
		 OC3A_PE3 =>(TC3,COMA), OC3B_PE4 =>(TC3,COMB), OC3C_PE5 =>(TC3,COMC),
		 OC4A_PH3 =>(TC4,COMA), OC4B_PH4 =>(TC4,COMB), OC4C_PH5 =>(TC4,COMC), 
		 OC5A_PL3 =>(TC5,COMA), OC5B_PL4 =>(TC5,COMB), OC5C_PL5 =>(TC4,COMC));

	procedure Enable_PWM
		(Port   : PWM_Ports_t; 
		 COM_Val: TC1345.COM_Mode_t; FPWM: Freq_t) is
		 
		PS_Val : Natural;
		Timer_Counter : TC1345.TC_Choices := PWM_Port_Info(Port).TC;
		
	begin
		
		case Timer_Counter is

			when TC1 =>
				PS_VAL := TC1_PS_Val;
				TC1_Top:= Unsigned_16( 40*( CLK_IO_Div_40/(2*PS_Val*FPWM) ) );
				ICR1H  := Unsigned_8(Low_Byte_Mask AND Shift_Right(TC1_Top,8));
				ICR1L  := Unsigned_8(Low_Byte_Mask AND TC1_Top);

				Set_COM_Mode
					(TCCRA => TCCR1A, 
					 COM_Mode_Selection => PWM_Port_Info(Port).COM,
					 COM_Mode => COM_Val);
				
				if Port = OC1A_PB5 then
					DDRB  := DDRB  + 2#00100000#; -- PB5 = output with Timer1
					PORTB := PORTB + 2#00100000#; -- Start with PB5 high => LED Off
					
				elsif Port = OC1B_PB6 then
					DDRB  := DDRB  + 2#01000000#; -- PB6 = output with Timer1
					PORTB := PORTB + 2#01000000#; -- Start with PB6 high => LED Off
				
				elsif Port = OC1C_PB7 then
					DDRB  := DDRB  + 2#10000000#; -- PB7 = output with Timer1
					PORTB := PORTB + 2#10000000#; -- Start with PB7 high => LED Off
					
			end if;


			when TC3 =>		
				PS_VAL := TC3_PS_Val;	
				TC3_Top:= Unsigned_16( 40*( CLK_IO_Div_40/(2*PS_Val*FPWM) ) );
				ICR3H  := Unsigned_8(Low_Byte_Mask AND Shift_Right(TC3_Top,8));
				ICR3L  := Unsigned_8(Low_Byte_Mask AND TC3_Top);
				
				Set_COM_Mode
					(TCCRA => TCCR3A, 
					 COM_Mode_Selection => PWM_Port_Info(Port).COM,
					 COM_Mode => COM_Val);				

				-- Reset TCNT3
				TCNT3H := 0;	TCNT3L := 0;
 
				if Port = OC3A_PE3 then

					OCR3AH := 0;	OCR3AL := 4;  -- Initialize the Output Compare register A
	
					DDRE  := DDRE  + 2#00001000#; -- PE3 = output with Timer3
					PORTE := PORTE + 2#00001000#; -- Start with PE3 high => LED Off
					
				elsif Port = OC3B_PE4 then

					OCR3BH := 0;	OCR3BL := 4;  -- Initialize the Output Compare register B

					DDRE  := DDRE  + 2#00010000#; -- PE4 = output with Timer3
					PORTE := PORTE + 2#00010000#; -- Start with PE4 high => LED Off
				
				elsif Port = OC3C_PE5 then

					OCR3CH := 0;	OCR3CL := 4;  -- Initialize the Output Compare register C

					DDRE  := DDRE  + 2#00100000#; -- PE5 = output with Timer3
					PORTE := PORTE + 2#00100000#; -- Start with PE5 high => LED Off
				end if;

		
			when TC4 =>
				PS_VAL := TC4_PS_Val;
				TC4_Top:= Unsigned_16( 40*( CLK_IO_Div_40/(2*PS_Val*FPWM) ) );
				ICR4H  := Unsigned_8(Low_Byte_Mask AND Shift_Right(TC4_Top,8));
				ICR4L  := Unsigned_8(Low_Byte_Mask AND TC4_Top);

				Set_COM_Mode
					(TCCRA => TCCR4A, 
					 COM_Mode_Selection => PWM_Port_Info(Port).COM,
					 COM_Mode => COM_Val);
			
				-- Reset TCNT4
				TCNT4H := 0;	TCNT4L := 0;
				
				if Port = OC4A_PH3 then
				
					OCR4AH := 0;	OCR4AL := 4;  -- Initialize the Output Compare register A
					
					DDRH  := DDRH  + 2#00001000#; -- PH3 = output with Timer4
					PORTH := PORTH + 2#00001000#; -- Start with PH3 high => LED Off
					
				elsif Port = OC4B_PH4 then
				
					OCR4BH := 0;	OCR4BL := 4;  -- Initialize the Output Compare register B
					
					DDRH  := DDRH  + 2#00010000#; -- PH4 = output with Timer4
					PORTH := PORTH + 2#00010000#; -- Start with PH4 high => LED Off
				
				elsif Port = OC4C_PH5 then
				
					OCR4CH := 0;	OCR4CL := 4;  -- Initialize the Output Compare register C
				
					DDRH  := DDRH  + 2#00100000#; -- PH5 = output with Timer4
					PORTH := PORTH + 2#00100000#; -- Start with PH5 high => LED Off
					
				end if;

	
			when TC5 =>
				PS_VAL := TC5_PS_Val;
				TC5_Top    := Unsigned_16( 40*( CLK_IO_Div_40/(2*PS_Val*FPWM) ) );
				ICR5H  := Unsigned_8(Low_Byte_Mask AND Shift_Right(TC5_Top,8));
				ICR5L  := Unsigned_8(Low_Byte_Mask AND TC5_Top);

				Set_COM_Mode
					(TCCRA => TCCR5A, 
					 COM_Mode_Selection => PWM_Port_Info(Port).COM,
					 COM_Mode => COM_Val);

				-- Reset TCNT5
				TCNT5H := 0;	TCNT5L := 0;	

				if Port = OC5A_PL3 then
				
					OCR5AH := 0;	OCR5AL := 4;  -- Initialize the Output Compare register A
					
					DDRL  := DDRL  + 2#00001000#; -- PL3 = output with Timer5
					PORTL := PORTL + 2#00001000#; -- Start with PL3 high => LED Off
					
				elsif Port = OC5B_PL4 then
				
					OCR5BH := 0;	OCR5BL := 4;  -- Initialize the Output Compare register B
					
					DDRL  := DDRL  + 2#00010000#; -- PL4 = output with Timer5
					PORTL := PORTL + 2#00010000#; -- Start with PL4 high => LED Off
				
				elsif Port = OC5C_PL5 then
				
					OCR5CH := 0;	OCR5CL := 4;  -- Initialize the Output Compare register C
				
					DDRL  := DDRL  + 2#00100000#; -- PL5 = output with Timer5
					PORTL := PORTL + 2#00100000#; -- Start with PL5 high => LED Off
					
				end if;
			
		end case;

	exception
	
		when others => null;
				

	end Enable_PWM;
	

--	procedure Set_Duty_Cyc(Port : PWM_Ports; Duty_Cyc : Percent_t) is
--	begin
	
		-- TBD
	
--	end Set_Duty_Cyc;
	
	
end ATmega2560_Timers.TC1345.PWM;
