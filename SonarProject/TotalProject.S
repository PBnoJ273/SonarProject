// Purpose:   To capture the pulse form a US sensor 
// Date:      2017 01 06
// Author:    Andrew Elder & Puneet Bagga
#include <avr/io.h>
#include "ASCII.h"
#define trig PB1
#define echo PB0 //input capture
//ICR1 is input capture reg 
//(ICR1L) and then the high byte (ICR1H)
#define BAUD9600 103 //sets correct baud rate 
#define hi 0
#define lo 0
#define compare 0x18
#define counter 0x00
#define endMove 0x14
#define startMove 0x12

.global setup
setup: 
cli
//declare pins to output 
//setup the serial monitor 
//setup the ultsonic sensor 
sbi _SFR_IO_ADDR(DDRB), DDB1  //sets PB1 to output (not tested)
sbi _SFR_IO_ADDR(DDRB), DDB3

  ldi r25,BAUD9600 >> 8       //Serial monitor setup 
  ldi r24,BAUD9600            
  call initUART 

  //setup for normal mode and interupt
  ldi r16, 0                    ; prepare for Normal Mode //sets pin to toggle on 9
  sts TCCR1A, r16               ; set Normal Mode, now configure the prescaler...
  ldi r16, 1<<WGM22 | 1<<WGM21 | 1<<WGM20
  sts TCCR2A, r16
  ldi r16, 0b00000100           ; T1:2^24/2^10/2^16 (prescale) > 0.25 ovf/s > 0.125Hz
  sts TCCR1B, r16               ; Timer1 clock = system clock / prescale
  ldi r16, 1<<CS22
  sts TCCR2B, r16
  ldi r16,hi                    ; load TCNT1 (Timer1's 2-byte counter)
  sts TCNT1H,r16                ; T1:2^16-(2^24/2^8/120)=64989=0xFDDD->120ovf/s=60Hz
  ldi r16,lo                    ; LED flashing at 24Hz does not seem to produce PoV
  sts TCNT1L,r16                ; even at 60Hz there appears to be some noticeable flicker
//ldi r16, 1<<CS21 | 1<<CS20
ldi r16, counter
sts TCNT2, r16
ldi r16, 0xFA
sts OCR2A, r16
ldi r18, endMove
ldi r19, 0x04
//setup the toggle pin??
ldi r16, 1<<ICIE1 | 1<<TOIE1  //enable the input capture and OVF interupt
sts TIMSK1, r16
ldi r16, 1<<TOIE2
sts TIMSK2, r16 
sei

ret

.global loop
loop:
//main code will consist of trigger routine (below)
//then input capture stuff
//then send to serial monitor 
//then repeat 


//call readUlt

/*   
  digitalWrite(Trig_pin, LOW);
  delayMicroseconds(2);
  digitalWrite(Trig_pin, HIGH);
  delayMicroseconds(10); //setup for reciving a signal
    
  digitalWrite(Trig_pin, LOW); //uses pulse o echo pin to capture
    
  duration = pulseIn(Echo_pin,HIGH); //what is the pulse in funciton
*/


dec r19
breq reload
rjmp end2
reload:
ldi r19, 0x04
end2:
call delay2
rjmp loop      

.global TIMER1_CAPT_vect
TIMER1_CAPT_vect:
//input capture interup 
//  ldi r25, 'R
//  call printChar
//  call printLn

  lds r25, ICR1L
  call printByte
  ldi r25, ',
  call printChar
  lds r25, ICR1H
  call printByte
//  ldi r25, ',
//  call printChar
//  mov r25, r19
//  call printByte
  ldi r25, space
  call printChar
  
  
reti

.global TIMER1_OVF_vect
TIMER1_OVF_vect:        
  ldi r16,hi                    ; load TCNT1 (Timer1's 2-byte counter)
  sts TCNT1H,r16                ; T1:2^16-(2^24/2^8/120)=64989=0xFDDD->120ovf/s=60Hz
  ldi r16,lo                    ; LED flashing at 24Hz does not seem to produce PoV
  sts TCNT1L,r16                ; even at 60Hz there appears to be some noticeable flicker
  
  in r16,_SFR_IO_ADDR(PORTB)    ; read the port
  ldi r17,1<<trig               ; prepare the bit(s) to toggle
  eor r16,r17                   ; toggle the bit(s), leaving the others unaffected
  out _SFR_IO_ADDR(PORTB),r16   ; update the port
//
//  ldi r25, 'I
//  call printChar
//  call printLn
reti

.global TIMER2_OVF_vect
TIMER2_OVF_vect:
ldi r16, counter
sts TCNT2, r16
dec r18
tst r18
breq off
cp r18, r19
breq on
rjmp end
on:
ldi r17,1<<3                  ; prepare the bit(s) to toggle
out _SFR_IO_ADDR(PORTB),r17   ; update the port
rjmp end
off:
clr r17                       ; prepare the bit(s) to toggle
out _SFR_IO_ADDR(PORTB),r17   ; update the port
ldi r18, endMove
end:
reti

.global delay2
delay2:
   ldi  r21, 82
    ldi  r22, 43
    ldi  r23, 0
L1: dec  r23
    brne L1
    dec  r22
    brne L1
    dec  r21
    brne L1
    lpm
    nop
ret




