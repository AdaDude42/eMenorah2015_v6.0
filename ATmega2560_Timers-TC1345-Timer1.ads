--
package ATmega2560_Timers.TC1345.TIMER1 is

	-- Interrupt handler for Timer1
	
	procedure Initialize;
	
	function Int_Count return Natural;
	
	procedure Reset_Int_Count;
	
end ATmega2560_Timers.TC1345.TIMER1;

