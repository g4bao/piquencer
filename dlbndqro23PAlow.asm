
;**********************************************************************
;                                                                     *
;    Filename:	    dlbndTS2Kqro23PAlow.asm                       	    	  *
;    Date:          25th July 2016                                  *
;    File Version:  1.00                                              *
;                                                                     *
;    Author: John Worsnop                                             *     
;    (c) G4BAO 2009                                                   *
;                                                                     * 
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files required:                                                  *
;    PC16F84A.inc	-  processor specific variable definitions        *
;                                                                     *
;                                                                     *
;**********************************************************************
;                                                                     *
;   Notes:                                                            *
; 4MHz crystal clock                                                  *  
; Loft controller, Based on dualbandTS2KV1 but using 12V failsafe     * 
; relays throughout                                                   *
; For two band, separate TX-feeder use.                               *
; Assumed (measured) relay timings are antenna 30ms PA 15ms           *
; antenna relays are in transmit position when energised, TX feeder   * 
; relays in parallel with 23cm antenna relay                          *
; relays failsafe to receive and 9cm TX position when not powered     *
; Version where 23cm PA needs low to operate, and 9cms needs "low"    *
; Sequence is                                                         *                                           
;		Wait for PTT low (RA0=23cm, RA1=9cm)                          *
;		9cms PTT low.                                                 *
;		If 9cms select 9cm feeder by pulling RB0 low                  *
;		Put 9cm relay to TX by pulling RB1 high                       *
;		37mS delay                                                    *
;		Apply PTT to 9cm PA by putting RB6 High                       *
;       Wait for 9cm PTT High                                         *
;       9cms PTT high                                                 *
;		Remove PTT from 9cm PA by putting RB6 low                     *
;		Put 9cm relay to RX by pulling RB1 low                        *
;		Goto Wait for PTT low                                         * 							
;		OR  IF 23cms PTT low.                                         *
;		If 23cms select 23cm feeder by putting RB0 high               *
;		This also Puts 23cm ant relay to TX                           *
;		37mS delay                                                    *
;		Apply PTT to 23cm PA by pulling RB7 High   (puts OV on PA)    *
;       Wait for 23cm PTT High                                        *
;       23cms PTT high                                                *
;		Remove PTT from 23cm PA by pulling RB7 low                    *
;		Put 23cm relay to RX by pulling RB0 low                       *
;		Goto Wait for PTT low                                         * 
;**********************************************************************

	PROCESSOR		pic16F84A		; list directive to define processor
	#include	"p16F84A.inc"	; processor specific variable definitions

	__CONFIG    _CP_OFF & _PWRTE_ON & _WDT_OFF & _XT_OSC 


;***** VARIABLE DEFINITIONS
delay_count	EQU		0x22		;delay counter for timing loops
msd0		EQU		0x20
msd1		EQU		0x23
msd2		EQU		0x24
msd3		EQU		0x25
;************************************************************
;           RA IO port bit definitions
;************************************************************
ptt23		EQU 0   ;23cm PTT input
ptt9		EQU 1   ;9cm PTT input 
;************************************************************
;           RB IO port bit definitions
;************************************************************
ANT23		EQU 0   ;23cm antenna changeover and select 23cm feeder
ANT9 		EQU 1   ;9cm antenna changeover 
PA9			EQU 6	;9cm PA enable
PA23        EQU 7   ;23cm PA enable
;*********************************************************************************************
	ORG		0x000	; processor reset vector
	bsf     STATUS, RP0 ;*****************bank 1********************
   	goto	main	; go to beginning of program
;*********************************************************************************************
main
;configure the IO ports
;PORTA 
	bcf		STATUS,RP0  ;*****************bank 0 ********************
	clrf	PORTA	

	bsf     STATUS, RP0 ;*****************bank 1********************
	movlw 80h	
	movwf OPTION_REG ;enable weak pull ups

	movlw 1Fh		;Set up PORTA 0-4 as inputs  
					
	movwf TRISA		;RA0 is 23cm PTT
					;RA1 is 9cm PTT
					
;PORTB 
	bcf		STATUS,RP0  ;*****************bank 0 ********************
	clrf	PORTB	

	bsf     STATUS, RP0 ;*****************bank 1********************

	movlw 00h		;Set up PORTB 0-7 as outputs  
					
	movwf TRISB		;RB0 is 23cm antenna changeover and select 23cm TX feeder
					;RB1 is  9cm antenna changeover 
					;RB6 is enable 9cm PA
					;RB7 is enable 23cm PA
					

;enable global interrupt
	movlw 	80h
	movwf	INTCON

	bcf STATUS,RP0	;*****************bank 0********************

;Power up - make sure we're in receive and preamp is in circuit by disabling the PAs
;and de-energising all the relays.
	
	bcf	PORTB,PA9
    bcf	PORTB,PA23      ;change this to bsf if PA requires "High"
	bcf PORTB, ANT9
    bcf PORTB, ANT23
;-------------------------------------------------------------------
;Start of main Operating loop- wait for either PORTA0 or PORTA1 to go low, these are PTT on signals
waitforPTTlow
    btfss	PORTA,ptt23			;skip the next instruction as long as the 23cm PTT is high
	goto    PTT23low
	btfss	PORTA,ptt9			;skip the next instruction as long as the 9cm PTT is high
	goto    PTT9low
	goto	waitforPTTlow

PTT23low	
;put the 23cm antenna relay in to the transmit position (this also selects antenna feeder)
	bsf PORTB, ANT23
; wait for 37.5ms
	call ms125delay
    call ms125delay
    call ms125delay
;enable the 23cm PA
    bsf	PORTB,PA23	;change this to bcf if PA needs "high"
	goto	waitforPTT23high

PTT9low
;select the 9cm feeder by pulling RB0 low
	bcf PORTB, ANT23
;put the 9cm antenna relay in to the transmit position
	bsf PORTB, ANT9
; wait for 37.5ms
	call ms125delay
    call ms125delay
    call ms125delay
;enable the 9cm PA
    bsf		PORTB,PA9	
	goto	waitforPTT9high
  
;Wait for relevant PTT line to go high, this is PTToff
waitforPTT23high
	btfsc	PORTA,ptt23
	goto    PTT23high
	goto	waitforPTT23high	

;Wait for relevant PTT line to go high, this is PTToff
waitforPTT9high
	btfsc	PORTA,ptt9
	goto    PTT9high
	goto	waitforPTT9high	

PTT23high
;disable the 23cm PA
    bcf	PORTB,PA23	;change this to bsf if PA needs "high"
; put the 23cm antenna relay in to the receive position (this also deselects antenna feeder)
	bcf PORTB, ANT23  
 	goto waitforPTTlow	

PTT9high
;disable the 9cm PA
	bcf	PORTB,PA9	
; put the 9cm antenna relay in to the receive position
	bcf PORTB, ANT9
	goto waitforPTTlow	

;End of main operating loop

;Subroutines for doing the delays
;
;Subroutine-----------------------------------------------------------------------------
;		50us delay 
delay
	movlw 0x14
	movwf delay_count
delay_loop
	decfsz delay_count,1
	goto delay_loop
	return
;Subroutine-----------------------------------------------------------------------------
;		12.75ms delay
ms125delay
    movlw 0xFF    ; was FF for 12.75ms
    movwf msd2
msloop125
    call delay              ;50us delay
    decfsz msd2,1
    goto msloop125
    return	

	END                       ; directive 'end of program'

