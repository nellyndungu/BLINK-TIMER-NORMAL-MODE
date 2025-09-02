; Include the ATmega328P definition file
.include "m328pdef.inc"

.cseg
.org 0x0000

start:
    ldi r16, 0xFF
    out DDRB, r16		; Set all bits of PORTD as output
    
loop:
    sbi PORTB, 0		; Set bit 0 of PORTD to high
    call delay_timer	; Call the delay_timer subroutine
    cbi PORTB, 0		; Clear bit 0 of PORTD to low
    call delay_timer	; Call the delay_timer subroutine again
    rjmp loop			; Jump back to the loop

delay_timer:	
    .equ Count = 65000	; Define the count for a 200ms delay
    ldi r17, High(Count) ; Load the higher bytes of Count into r17
    sts TCNT1H, r17		; Store the value in r17 into the higher bytes of TCNT1
    ldi r18, Low(Count)  ; Load the lower bytes of Count into r18
    sts TCNT1L, r18		; Store the value in r18 into the lower bytes of TCNT1
    ldi r19, 0x00		; Initialize r19 to 0x00
    sts TCCR1A, r19		 ; Set TCCR1A to normal mode
    ldi r19, (1<<CS12) | (1<<CS10)	
    sts TCCR1B, r19		; Set TCCR1B with a prescaler of 1024 (1<<CS12) | (1<<CS10)
    
lp:
    ; Wait for TOV1 flag to be set (overflow flag)
    sbis TIFR1, TOV1
    rjmp lp
    ; Clear TOV1 flag
    sbi TIFR1, TOV1
    ; Set TCCR1B to 0xFF to stop the timer
    ldi r20, 0xFF
    sts TCCR1B, r20
    ; Return from the subroutine
    ret
