#include Reg9s12.h
#include IntVec.h

                ORG $2000       ;Start at memory address 2000
                LDX #$0000      ;Register base is 0x00
                BRA MAIN        ;GOTO main
                
COUNT:          RMB 2
SPACE:          RMB 1
KeyCount:       RMB 1
KeyValue:       RMB 1
        
        
MAIN:           MOVB #$FF, DDRA         ;Port A is all output
                MOVB #$F0, DDRB         ;Upper nibble is output and lower nibble is input
                MOVB #$00, PORTA
                MOVW #$0000, COUNT
                MOVB #$00, SPACE
                MOVB #$00, KeyCount
                
                JSR TimSet
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
                CPD #$001F              ;See if we need to check the keypad
                BNE INTCLR
                MOVW #$0000, COUNT      ;Reset the value of count
                JSR HANIO
INTCLR:         LDAA TFLG2              ;Clear overflow bit
                ANDA #$80
                STAA TFLG2
                RTI                     ;Return
                
;-------------------------------------------------------------------------------
;void HANIO(void)
;Handles the keypad input
;-------------------------------------------------------------------------------
HANIO:          JSR KEYIO
                CMPA #$11
                LBEQ HANIONOIO           ;We didn't have any input
                LDAB SPACE
                CMPB #$01               ;Make sure that was a space inbetween
                LBNE HANIOEND
                MOVB #$00,SPACE
                CMPA #$0F
                BEQ HANIOFLUSH          ;The flush key was pressed
                MOVB #$00, PORTA
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
                BRA HANIOEND
RotBaseCW:      LDAA #$01
                PSHA
                JSR mRotBase
                LEAS 1,SP
                BRA HANIOEND
MovBaseD:       LDAA #$00
                PSHA
                JSR mMovBase
                LEAS 1,SP
                BRA HANIOEND
MovBaseUp:      LDAA #$01
                PSHA
                JSR mMovBase
                LEAS 1,SP
                BRA HANIOEND
MovElbowD:      LDAA #$00
                PSHA
                JSR mMovElbow
                LEAS 1,SP
                BRA HANIOEND
MovElbowUp:     LDAA #$01
                PSHA
                JSR mMovElbow
                LEAS 1,SP
                BRA HANIOEND
OpenClaw:       LDAA #$00
                PSHA
                JSR mMovClaw
                LEAS 1,SP
                BRA HANIOEND
CloseClaw:      LDAA #$01
                PSHA
                JSR mMovClaw
                LEAS 1,SP
                BRA HANIOEND
HANIOFLUSH:     MOVB #$00, PORTA
                RTS
HANIONOIO:      MOVB #$01,SPACE
HANIOEND:       RTS

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