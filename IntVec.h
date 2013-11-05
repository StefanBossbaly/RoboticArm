; Interrupt Vectors for D-Bug 4 Monitor
; Compiled by Dr. Robert A. Spalletta
; for use in EE449 and EE454
;
;    Place vector label in the first field as shown below for Timer Overflow (TOIvec)
; 
        ORG     $3E00
        RMB     2     ; Reserved $FF80
        RMB     2     ; Reserved $FF82
        RMB     2     ; Reserved $FF84
        RMB     2     ; Reserved $FF86
        RMB     2     ; Reserved $FF88
        RMB     2     ; Reserved $FF8A
        RMB     2     ; PWM Emergency Shutdown
        RMB     2     ; Port P Interrupt
        RMB     2     ; MSCN4 Transimit
        RMB     2     ; MSCN4 Recieve
        RMB     2     ; MSCN4 Errors
        RMB     2     ; MSCN4 Wake-Up
        RMB     2     ; MSCN3 Transimit
        RMB     2     ; MSCN3 Recieve
        RMB     2     ; MSCN3 Errors
        RMB     2     ; MSCN3 Wake-Up
        RMB     2     ; MSCN2 Transimit
        RMB     2     ; MSCN2 Recieve
        RMB     2     ; MSCN2 Errors
        RMB     2     ; MSCN2 Wake-Up
        RMB     2     ; MSCN1 Transimit
        RMB     2     ; MSCN1 Recieve
        RMB     2     ; MSCN1 Errors
        RMB     2     ; MSCN1 Wake-Up
        RMB     2     ; MSCN0 Transimit
        RMB     2     ; MSCN0 Recieve
        RMB     2     ; MSCN0 Errors
        RMB     2     ; MSCN0 Wake-Up
        RMB     2     ; Flash
        RMB     2     ; EEPROM
        RMB     2     ; SPI2
        RMB     2     ; SPI1
        RMB     2     ; IIC Bus
        RMB     2     ; DLC
        RMB     2     ; SCME
        RMB     2     ; CRG Lock
        RMB     2     ; Pulse Accumulator B Overflow
        RMB     2     ; Modulus Down Counter Underflow
        RMB     2     ; Port H Interrupt
        RMB     2     ; Port J Interrupt
        RMB     2     ; ATD1
        RMB     2     ; ATD0
        RMB     2     ; SCI1
        RMB     2     ; SCI0
        RMB     2     ; SPI0
        RMB     2     ; Pulse Accumulator A Input Edge
        RMB     2     ; Pulse Accumulator A Overflow
TOIvec  RMB     2     ; Timer Overflow
        RMB     2     ; Timer Channel 7
        RMB     2     ; Timer Channel 6
        RMB     2     ; Timer Channel 5
        RMB     2     ; Timer Channel 4
        RMB     2     ; Timer Channel 3
        RMB     2     ; Timer Channel 2
        RMB     2     ; Timer Channel 1
        RMB     2     ; Timer Channel 0
        RMB     2     ; Real Time Interrupt
        RMB     2     ; IRQ
        RMB     2     ; XIRQ
        RMB     2     ; SWI
        RMB     2     ; Unimplemented Instruction Trap
        RMB     2     ; N/A
        RMB     2     ; N/A
        RMB     2     ; N/A