#include Reg9s12.h
#include IntVec.h

                ORG $2000       ;Start at memory address 2000
                LDX #$0000      ;Register base is 0x00
                BRA MAIN        ;GOTO main
        
        
MAIN:           MOVB #$FF, DDRA         ;Port A is all output
                MOVB #$0F, DDRB         ;Upper nibble is output and lower nibble is input
                MOVB #$00, PORTA
                LDAA #$00
                PSHA
                JSR mMovClaw
                LEAS 1,SP
                SWI
                
                
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
                SWI
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
                SWI
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
                SWI
mMovClawEnd:    PULA
                RTS