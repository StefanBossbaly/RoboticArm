#include Reg9s12.h
#include IntVec.h

                ORG $2000       ;Start at memory address 2000
                LDX #$0000      ;Register base is 0x00
                BRA MAIN        ;GOTO main
                
COUNT:          RMB 2
SPACE:          RMB 1
KeyCount:       RMB 1
KeyValue:       RMB 1
KeyMode:        RMB 1

Target:         RMB 1
Moving:       	RMB 1

LOWTHHOLD:      EQU $0A
HIGHTHHOLD:     EQU $F0

PhotoThHold:    EQU $90
        
        
MAIN:           MOVB #$FF, DDRA         ;Port A is all output
                MOVB #$F0, DDRB         ;Upper nibble is output and lower nibble is input
                MOVB #$1F, DDRP         ;PP4 - PP0 are output
                
                MOVB #$00, PORTA
                MOVW #$0000, COUNT
                MOVB #$00, SPACE

                MOVB #$00, KeyCount
                MOVB #$00, KeyMode
                
                MOVB #$00, Target
                MOVB #$00, Moving

                JSR TimSet
                JSR ADSet
                CLI                     ;Enable interrupts

LOOP:           WAI
                BRA LOOP
                
                
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; Motor Control Subroutines
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; void mRotBase(int direction)
; Rotates the base in specified direciton
; 0 = counterclockwise
; 1 = clockwise
;-------------------------------------------------------------------------------
mRotBase:       PSHA
                LDAA 3,SP
                CMPA #$00
                BNE mRotBaseCW
                LDAA PORTA
                ORAA #%01000000
                STAA PORTA
                BRA mRotBaseEnd
mRotBaseCW:     LDAA PORTA
                ORAA #%10000000
                STAA PORTA
mRotBaseEnd:    PULA
                RTS
                
;-------------------------------------------------------------------------------
; void mMovBase(int direction)
; Moves the the base in specified direciton
; 0 = down
; 1 = up
;-------------------------------------------------------------------------------
mMovBase:       PSHA
                LDAA 3,SP
                CMPA #$00
                BNE mMovBaseUp
                LDAA PORTA
                ORAA #%00010000
                STAA PORTA
                BRA mMovBaseEnd
mMovBaseUp:     LDAA PORTA
                ORAA #%00100000
                STAA PORTA
mMovBaseEnd:    PULA
                RTS
                
                
;-------------------------------------------------------------------------------
; void mMovElbow(int direction)
; Moves the the elbow in specified direciton
; 0 = down
; 1 = up
;-------------------------------------------------------------------------------
mMovElbow:      PSHA
                LDAA 3,SP
                CMPA #$00
                BNE mMovElbowUp
                LDAA PORTA
                ORAA #%00000100
                STAA PORTA
                BRA mMovElbowEnd
mMovElbowUp:    LDAA PORTA
                ORAA #%00001000
                STAA PORTA
mMovElbowEnd:   PULA
                RTS
                
;-------------------------------------------------------------------------------
; void mMovClaw(int direction)
; Moves the the claw in specified direciton
; 0 = open
; 1 = close
;-------------------------------------------------------------------------------
mMovClaw:       PSHA
                LDAA 3,SP
                CMPA #$00
                BNE mMovClawOpen
                LDAA PORTA
                ORAA #%00000001
                STAA PORTA
                BRA mMovClawEnd
mMovClawOpen:   LDAA PORTA
                ORAA #%00000010
                STAA PORTA
mMovClawEnd:    PULA
                RTS
                
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; AtoD Subroutines
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; void ADset(void)
; Sets up the A to D converter
;-------------------------------------------------------------------------------
ADSet:          PSHY
                MOVB #$03, ATD0DIEN  ;Make only bits 0 and 1 of PortA digital
                MOVB #$80, ATD0CTL2  ;Turn on the A to D converter (bit 7 of ATD0CTL2)
                LDY #$ea00                 ; Brief delay to allow AtoD to power up
D1:             DEY                        ; decrements the y index register 65000 times
                BNE D1                 ; and then returns.
                MOVB #$80, ATD0CTL4   ; (ATDOCTL4 Bit 7 0=>10 bits, 1=>8 bits)
                PULY
                RTS

;-------------------------------------------------------------------------------
; void ConAtoD(int port_number)
; Uses the A to D converter to convert an analog value on port_number to a
; digital value in ADR00H register
;-------------------------------------------------------------------------------
ConAtoD:        PSHA
                PSHB
                LDAA 4,SP
                CMPA #$07
                BGT ConAtoDWaitEnd
                CMPA #$02
                BLT ConAtoDWaitEnd
                LDAB #$08        ; Start A to D conversion do a single channel conversion on
                STAB ATD0CTL3   ; Port A Bit 2 Least significant 4 bits are starting A to D Channel
                STAA ATD0CTL5
ConAtoDWait:    LDAA ATD0STAT
                ANDA #$80        ; Wait for conversion complete flag to set (bit 7 of atd0stat)
                BEQ ConAtoDWait
ConAtoDWaitEnd: PULB
                PULA
                RTS

;-------------------------------------------------------------------------------
; void TimSet(void)
; Sets up the timer for timeroverflow
;-------------------------------------------------------------------------------
TimSet:         MOVB #$80, TSCR         ;Turn on timer
                LDD #TimeIntHandler     ;Store the ISR in the vector table
                STD TOIvec
                LDAA TMSK2              ;Set timer overflow interrupt
                ORAA #$80
                STAA TMSK2
                LDAA TFLG2              ;Clear overflow bit
                ANDA #$80
                STAA TFLG2
                RTS
                
;-------------------------------------------------------------------------------
; void TimeIntHandler(void)
; Handles the timer overflow interrupt
;-------------------------------------------------------------------------------
TimeIntHandler: LDD COUNT
                ADDD #$0001
                STD COUNT
                CPD #$000C              ;See if we need to check the keypad
                BNE INTCLR
                MOVW #$0000, COUNT      ;Reset the value of count
                JSR KEYIO
                CMPA #14
                BEQ IntModeSwitch
                LDAA KeyMode
                CMPA #$00
                BNE IntAutoMode
                JSR HanOperMode
                BRA INTCLR
IntAutoMode:    JSR HanAuto
                BRA INTCLR
IntModeSwitch:  LDAA KeyMode
                CMPA #$01
                BEQ IntOp
                MOVB #$01, KeyMode
                BRA INTCLR
IntOp:          MOVB #$00, KeyMode
INTCLR:         LDAA TFLG2              ;Clear overflow bit
                ANDA #$80
                STAA TFLG2
                RTI                     ;Return

;-------------------------------------------------------------------------------
;void HanAuto(void)
;Handles the auto
;-------------------------------------------------------------------------------
HanAuto:        LDAA Moving             ;See if we are moving
                CMPA #$01
                BEQ HanAutoMoving       ;If we already are moving no keypad io
                JSR KEYIO               ;Get the keypad io
                CMPA #$05
                BHI HanAutoEnd          ;Make sure we have a valid number
                STAA Target             ;Store the target location
                MOVB #$01, Moving       ;We are going to move
                
HanAutoMoving:  JSR BaseLocate
                CMPA #$05       ;Compare to our magic value of 5 (not at a position)
                BEQ HanAutoEnd
                CMPA Target,d
                BEQ HanAutoTarget
                MOVB #$00, PORTA
                BHI HanAutoRotCCW
                LDAA #$01
                PSHA
                JSR mRotBase
                LEAS 1,SP
                BRA HanAutoEnd
HanAutoRotCCW:  LDAA #$00
                PSHA
                JSR mRotBase
                LEAS 1,SP
                BRA HanAutoEnd
HanAutoTarget:  MOVB #$00, PORTA
                MOVB #$00, Moving       ;We are no longer moving
HanAutoEnd:     RTS
                
;-------------------------------------------------------------------------------
; void HanOperatorMode(void)
; Handles the keypad input
;-------------------------------------------------------------------------------
HanOperMode:    JSR KEYIO
                CMPA #$11
                LBEQ HanOperModeNoI     ;We didn't have any input
                LDAB SPACE
                CMPB #$01               ;Make sure that was a space inbetween
                LBNE HanOperModeEnd
                MOVB #$00,SPACE
                CMPA #$0F
                BEQ HanOperModeClr          ;The flush key was pressed
                ;MOVB #$00, PORTA
                CMPA #$00
                BEQ RotBaseCCW
                CMPA #$01
                BEQ RotBaseCW
                CMPA #$02
                BEQ MovBaseD
                CMPA #$03
                BEQ MovBaseUp
                CMPA #$04
                BEQ MovElbowD
                CMPA #$05
                BEQ MovElbowUp
                CMPA #$06
                BEQ OpenClaw
                BNE CloseClaw
RotBaseCCW:     LDAA #$00
                PSHA
                JSR mRotBase
                LEAS 1,SP
                BRA HanOperModeEnd
RotBaseCW:      LDAA #$01
                PSHA
                JSR mRotBase
                LEAS 1,SP
                BRA HanOperModeEnd
MovBaseD:       LDAA #$00
                PSHA
                JSR mMovBase
                LEAS 1,SP
                BRA HanOperModeEnd
MovBaseUp:      LDAA #$01
                PSHA
                JSR mMovBase
                LEAS 1,SP
                BRA HanOperModeEnd
MovElbowD:      LDAA #$00
                PSHA
                JSR mMovElbow
                LEAS 1,SP
                BRA HanOperModeEnd
MovElbowUp:     LDAA #$01
                PSHA
                JSR mMovElbow
                LEAS 1,SP
                BRA HanOperModeEnd
OpenClaw:       LDAA #$00
                PSHA
                JSR mMovClaw
                LEAS 1,SP
                BRA HanOperModeEnd
CloseClaw:      LDAA #$01
                PSHA
                JSR mMovClaw
                LEAS 1,SP
                BRA HanOperModeEnd
HanOperModeClr: MOVB #$00, PORTA
                RTS
HanOperModeNoI: MOVB #$01,SPACE
HanOperModeEnd: RTS

;-------------------------------------------------------------------------------
; int BaseLocate(void)
; Tells where the base is located by pulsing the IR LEDS
;-------------------------------------------------------------------------------
BaseLocate:     MOVB #$10, PTP  ;See if we are at the first LED
                JSR BWAIT
                LDAA #$02
                PSHA
                JSR ConAtoD
                LEAS 1,SP
                LDAA ADR00H
                CMPA LOWTHHOLD
                BLO BaseLocate0
                MOVB #$08, PTP  ;See if we are at the second LED
                JSR BWAIT
                LDAA #$02
                PSHA
                JSR ConAtoD
                LEAS 1,SP
                LDAA ADR00H
                CMPA LOWTHHOLD
                BLO BaseLocate1
                MOVB #$04, PTP  ;See if we are at the thrid LED
                JSR BWAIT
                LDAA #$02
                PSHA
                JSR ConAtoD
                LEAS 1,SP
                LDAA ADR00H
                CMPA LOWTHHOLD
                BLO BaseLocate2
                MOVB #$02, PTP  ;See if we are a the fourth LED
                JSR BWAIT
                LDAA #$02
                PSHA
                JSR ConAtoD
                LEAS 1,SP
                LDAA ADR00H
                CMPA LOWTHHOLD
                BLO BaseLocate3
                MOVB #$01, PTP  ;See if we are at the fifth LED
                JSR BWAIT
                LDAA #$02
                PSHA
                JSR ConAtoD
                LEAS 1,SP
                LDAA ADR00H
                CMPA LOWTHHOLD
                BLO BaseLocate4
                LDAA #$05
                BRA BaseLocateEnd

BaseLocate0:    LDAA #$00
                BRA BaseLocateEnd
BaseLocate1:    LDAA #$01
                BRA BaseLocateEnd
BaseLocate2:    LDAA #$02
                BRA BaseLocateEnd
BaseLocate3:    LDAA #$03
                BRA BaseLocateEnd
BaseLocate4:    LDAA #$04
                BRA BaseLocateEnd
BaseLocateEnd:  RTS


;-------------------------------------------------------------------------------
; int ArmLocate(void)
; Tells where the arm is located
;-------------------------------------------------------------------------------
ArmLocate:      LDAA #$03
                PSHA
                JSR ConAtoD
                LEAS 1,SP
                LDAA adr00h
                SWI
                CMPA PhotoThHold
                RTS

;-------------------------------------------------------------------------------
;void BWAIT(void)
;Busy waits by counting down from 0xFFFF
;-------------------------------------------------------------------------------
BWAIT:          PSHD
                LDD #$FFFF      ;Load 0xFFFF into register D
BLP:            CPD #$0000      ;Compare it with 0x0000
                BEQ BEND        ;End the loop if they are equal
                SUBD #$0001     ;Decrement 1 from D
                BRA BLP         ;Loop
BEND:           PULD
                RTS             ;Return to sub routine

;-------------------------------------------------------------------------------
;int CINPUT(int column)
;Sees if there is any input on the column and returns it in the A register
;If there is no input then it returns 17
;-------------------------------------------------------------------------------
CINPUT:         LDAA PORTB      ;Load port b into
                ANDA #$0F       ;Get the lower nibble
                CMPA #$00       ;See if there is any input
                BEQ CNOIN       ;There is no input
                CMPA #$08       ;Compare to the bit pattern 0x10 (first row)
                BEQ  CINR0
                CMPA #$04        ;Compare to the bit pattern 0x20 (second row)
                BEQ  CINR1
                CMPA #$02        ;Compare to the bit pattern 0x40 (thrid row)
                BEQ  CINR2
                CMPA #$01       ;Compare to the bit pattern 0x80 (fourth row)
                BEQ  CINR3
                LDAA #$11       ;Should never  get here
                RTS
CINR0:          LDAA #$00
                ADDA 2,SP
                RTS
CINR1:          LDAA #$04
                ADDA 2,SP
                RTS
CINR2:          LDAA #$08
                ADDA 2,SP
                RTS
CINR3:          LDAA #$0C
                ADDA 2,SP
                RTS
CNOIN:          LDAA #$11        ;Load 17 into A register
                RTS

;-------------------------------------------------------------------------------
;int KEYIO(void)
;Sees if there is any input on keypad and returns it in the A register
;If there is no input then it returns 17
;-------------------------------------------------------------------------------
KEYIO:          LDAA #$80       ;Set 0x80 into Port B
                STAA PORTB      ;This sets PB3 as HIGH all other are LOW
                LDAA #$00       ;Load 0 into A
                PSHA            ;Push it onto the stack
                JSR CINPUT      ;Jump to the subroutine
                LEAS 1,SP       ;Put the stack back to normal
                CMPA #$11
                BNE HASIN
                LDAA #$40       ;Set 0x40 into Port B
                STAA PORTB      ;This sets PB2 as HIGH all other are LOW
                LDAA #$01       ;Load 1 as column parameter
                PSHA
                JSR CINPUT      ;Jump to the subroutine
                LEAS 1,SP       ;Put the stack back to normal
                CMPA #$11
                BNE HASIN
                LDAA #$20       ;Set 0x02 into Port B
                STAA PORTB      ;This sets PB1 as HIGH all other are LOW
                LDAA #$02       ;Load 2 into A
                PSHA            ;Push it onto the stack
                JSR CINPUT      ;Jump to the subroutine
                LEAS 1,SP       ;Put the stack back to normal
                CMPA #$11
                BNE HASIN
                LDAA #$10       ;Set 0x01 into Port B
                STAA PORTB      ;This sets PB0 as HIGH all other are LOW
                LDAA #$03       ;Load 2 into A
                PSHA            ;Push it onto the stack
                JSR CINPUT      ;Jump to the subroutine
                LEAS 1,SP       ;Put the stack back to normal
                CMPA #$11
                BNE HASIN
                LDAA #$11
HASIN:          RTS