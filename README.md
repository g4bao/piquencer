# piquencer
Initial test repository containing PIC code and eagle files for a TX/RX sequencer

Sequence controller for two PAs/masthead preamps using a common TX feeder and separate RX feeders  

9-23control/sch is the circuit diagram in eagle 5 format

9-23control/brd is the PCB layout in eagle 5 format

Notes: 
4MHz crystal clock
Loft controller, Based on dualbandTS2KV1 but using 12V failsafe relays throughout                                                   
For two band, separate TX-feeder use.                               
; Assumed (measured) relay timings are antenna 30ms PA 15ms         
; antenna relays are in transmit position when energised, TX feeder  
; relays in parallel with 23cm antenna relay                        
; relays failsafe to receive and 9cm TX position when not powered   
; Version where 23cm PA needs low to operate, and 9cms needs "low"  
; 
Sequence is                                                                                                   
;		Wait for PTT low (RA0=23cm, RA1=9cm)                          
;		9cms PTT low.                                                 
;		If 9cms select 9cm feeder by pulling RB0 low                  
;		Put 9cm relay to TX by pulling RB1 high                       
;		37mS delay                                                    
;		Apply PTT to 9cm PA by putting RB6 High                       
;       Wait for 9cm PTT High                                     
;       9cms PTT high                                             
;		Remove PTT from 9cm PA by putting RB6 low                     
;		Put 9cm relay to RX by pulling RB1 low                        
;		Goto Wait for PTT low                                          							
;		OR  IF 23cms PTT low.                                         
;		If 23cms select 23cm feeder by putting RB0 high               
;		This also Puts 23cm ant relay to TX                           
;		37mS delay                                                    
;		Apply PTT to 23cm PA by pulling RB7 High   (puts OV on PA)    
;       Wait for 23cm PTT High                                    
;       23cms PTT high                                          
;		Remove PTT from 23cm PA by pulling RB7 low                  
;		Put 23cm relay to RX by pulling RB0 low
;		Goto Wait for PTT low                                        
