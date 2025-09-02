# USING TIMER IN ATMEGA328P USING ASSEMBLY
This program blinks an LED on PB0 using Timer1 for delays:
* All PORTB pins are outputs.
* LED toggles ON and OFF with ~200 ms delay.
* Delay is generated via Timer1 overflow (16-bit, prescaler 1024).
* The program uses direct register manipulation, not Arduino libraries → faster and more efficient.

It demonstrates low-level AVR control of timers and I/O — a step above simple software loops since it leverages hardware timing.
## Code Explanation
```asm
.include "m328pdef.inc"   ; Include device definitions for ATmega328P

.cseg
.org 0x0000               ; Program memory starts at 0x0000

start:
    ldi r16, 0xFF
    out DDRB, r16         ; Set all bits of PORTB as output
```
* m328pdef.inc → This is the device definition file for ATmega328P. It defines register names (PORTB, DDRB, TCCR1A, etc.) and bit names.
* .cseg → Start code segment (program memory).
* .org 0x0000 → Reset vector location, execution begins here.
* ldi r16, 0xFF and out DDRB, r16 → Sets all pins of PORTB as outputs (PB0–PB7). In practice, we’ll use PB0 for the LED.
```asm
loop:
    sbi PORTB, 0        ; Set PB0 high → LED ON
    call delay_timer    ; Delay using Timer1
    cbi PORTB, 0        ; Clear PB0 → LED OFF
    call delay_timer    ; Delay again
    rjmp loop           ; Repeat forever
```
* sbi (Set Bit in I/O register) → Turns ON PB0.
* cbi (Clear Bit in I/O register) → Turns OFF PB0.
* The LED connected to PB0 blinks ON/OFF with each call to the delay_timer subroutine.
## Delay Subroutine
```asm
delay_timer:
    .equ Count = 65000

    ldi r17, High(Count)   ; Load high byte of 65000
    sts TCNT1H, r17        ; Initialize Timer1 high byte
    ldi r18, Low(Count)    ; Load low byte of 65000
    sts TCNT1L, r18        ; Initialize Timer1 low byte

    ldi r19, 0x00
    sts TCCR1A, r19        ; Normal mode (no compare, no PWM)

    ldi r19, (1<<CS12) | (1<<CS10)
    sts TCCR1B, r19        ; Start Timer1 with prescaler = 1024
```
* TCNT1H/TCNT1L → Timer/Counter1 registers (16-bit counter).
    - Loading 65000 ensures the timer overflows quickly (since max is 65535).
* TCCR1A → Set to 0x00 → normal mode (no PWM, just counting).
* TCCR1B → (1<<CS12) | (1<<CS10) → Timer1 clock = system clock / 1024.
    * At 16 MHz system clock, tick rate = 16 MHz / 1024 ≈ 15.6 kHz.
    * Overflow from 65000 → ~200 ms delay.
## Waiting for overflow

```asm
lp:
    sbis TIFR1, TOV1     ; Skip if overflow flag is set
    rjmp lp              ; Otherwise, keep waiting
    sbi TIFR1, TOV1      ; Clear overflow flag
    ldi r20, 0xFF
    sts TCCR1B, r20      ; Stop timer
    ret
```
* TIFR1 → Timer/Counter Interrupt Flag Register.
    - TOV1 is the overflow flag. It is set when Timer1 overflows.
* sbis TIFR1, TOV1 → Skips next instruction if the flag is set. Otherwise, loops.
* sbi TIFR1, TOV1 → Clears the overflow flag.
* Stopping Timer: Writing 0xFF to TCCR1B effectively disables the timer.
This ensures the delay finishes cleanly before returning.
## Protocols and ports
1. Microcontroller & ISA
    - ATmega328P, AVR 8-bit Harvard architecture, RISC instruction set.
2. I/O Ports
    - PORTB is used for LED output (PB0).
    - DDRB sets PORTB pins as outputs.
3. Timer Protocol
    - Uses Timer/Counter1 (16-bit) for precise delay.
    - Prescaler = 1024 for manageable timing at 16 MHz.
    - Overflow flag (TOV1) is polled in software.
4. Special Instructions
    - sbi / cbi for single-bit manipulation → efficient LED toggling.
    - sbis (skip if bit set) → lightweight polling of flags.
