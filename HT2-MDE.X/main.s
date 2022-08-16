;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Pablo Mazariegos/Luis Pablo Carranza    
; Compilador: PIC-AS (v2.36), MPLAB X IDE (v6.00)
; Proyecto: HT2 Máquina de estados finitos
; Hardware: PIC16F887
; Creado: 21/07/22
; Última Modificación: 16/07/22 
;******************************************************************************* 
PROCESSOR 16F887
#include <xc.inc>
;******************************************************************************* 
; Palabra de configuración    
;******************************************************************************* 
 ; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator
				; : I/O function on RA6/OSC2/CLKOUT pin, I/O 
				; function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and 
				; can be enabled by SWDTEN bit of the WDTCON 
				; register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin 
				; function is digital input, MCLR internally 
				; tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code 
				; protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code 
				; protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/
				; External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe 
				; Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin 
				; has digital I/O, HV on MCLR must be used for 
				; programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out 
				; Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits 
				; (Write protection off)
;******************************************************************************* 
; Variables    
;******************************************************************************* 
PSECT udata_shr
 estado:	    ; Control de cambio de estado
    DS 1
 W_TEMP:	    ; Variable W temporal
    DS 1
 STATUS_TEMP:	    ; Variable STATUS temporal
    DS 1
 CONT20MS:	    ; Variable para el conteo de segundos en modo 2 y 3
    DS 1
;******************************************************************************* 
; Vector Reset    
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0000
    goto MAIN
;******************************************************************************* 
; Vector ISR Interrupciones    
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0004
 PUSH:			    ; Guarda el valor de STATUS y W temporalmente
    MOVWF W_TEMP
    SWAPF STATUS, W
    MOVWF STATUS_TEMP
    
ISRRBIF:
    BTFSS INTCON, 0	    ; RBIF = 1 ?
    GOTO RTMR0		    ; Si no, revisar TRM0
    MOVF estado, W	    ; Cargar estado a W
    SUBLW 0		    ; Si la resta con 0 es 0 ir a ESTADO0_ISR
    BTFSC STATUS, 2
    GOTO ESTADO0_ISR
    MOVF estado, W
    SUBLW 1		    ; Si la resta con 1 es 0 ir a ESTADO1_ISR
    BTFSC STATUS, 2
    GOTO ESTADO1_ISR
    MOVF estado, W
    SUBLW 2		    ; Si la resta con 2 es 0 ir a ESTADO2_ISR
    BTFSC STATUS, 2
    GOTO ESTADO2_ISR
    MOVF estado, W
    SUBLW 3		    ; Si la resta con 3 es 0 ir a ESTADO3_ISR
    BTFSC STATUS, 2
    GOTO ESTADO3_ISR
    GOTO POP

ESTADO0_ISR:
    BANKSEL PORTB
    BTFSS PORTB, 1	    ; Revisa si se presiona PORTB
    INCF PORTC, F	    ; Si se presiona incrementa puerto C
    BTFSS PORTB, 0	    ; Si no se presiona revisa si se presionó botón de 
			    ; cambio
    INCF estado, F	    ; Si se presionó incrementa valor de estado a 1
    BCF INTCON, 0	    ; RBIF = 0
    GOTO POP
    
 ESTADO1_ISR:
    BANKSEL PORTB
    BTFSS PORTB, 1
    DECF PORTC, F
    BTFSS PORTB, 0	    ; Si no se presiona revisa si se presionó botón de 
			    ; cambio
    INCF estado, F	    ; Si se presionó incrementa valor de estado a 2
    BCF INTCON, 0	    ; RBIF = 0
    GOTO POP
    
 ESTADO2_ISR:
    BANKSEL PORTB
    BTFSS PORTB, 0	    ; Revisa si se presionó botón de cambio
    INCF estado, F	    ; Si se presionó incrementa valor de estado a 3
    BCF INTCON, 0	    ; RBIF = 0
    GOTO POP
    
 ESTADO3_ISR:
    BANKSEL PORTB
    BTFSS PORTB, 0	    ; Revisa si se presionó el botón de cambio
    CLRF estado		    ; Si se presionó regresa el valor de estado a 0
    BCF INTCON, 0	    ; RBIF = 0
    GOTO POP
    
 RTMR0:
    BCF INTCON, 2	; Limpia la bandera de interrupción
    BANKSEL TMR0	
    INCF CONT20MS	; Incrementa la variable del TMR0
    MOVLW 179		; Carga el valor de n al TMR0
    MOVWF TMR0	
    GOTO POP
    
 POP:
    SWAPF STATUS_TEMP, W
    MOVWF STATUS
    SWAPF W_TEMP, F
    SWAPF W_TEMP, W
    RETFIE		; Regresa el valor de W y STATUS luego de interrupcion
    
;******************************************************************************* 
; Código Principal    
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0100
 ;******************************************************************************* 
; Tabla para obtener el valor del puerto a mostrar para el display 7 Seg  
;*******************************************************************************     

MAIN:
    BANKSEL OSCCON
    
    BSF OSCCON, 6	; IRCF2 Selección de 4MHz
    BSF OSCCON, 5	; IRCF1
    BCF OSCCON, 4	; IRCF0
    
    BSF OSCCON, 0	; SCS Reloj Interno
    
    BANKSEL TRISC
    CLRF TRISC		; Limpiar el registro TRISB
    
    BCF TRISA, 4
    BCF TRISA, 5
    BCF TRISA, 6
    BCF TRISA, 7	; LEDS PARA INDICAR MODO DE OPERACION
    
    BSF TRISB, 0
    BSF TRISB, 1	; Entradas para los botones
    
    BANKSEL IOCB
    
    BSF IOCB, 0
    BSF IOCB, 1		; Habilitando RB0 y RB1 para las ISR de RBIE
    
    BANKSEL WPUB
    BSF WPUB, 0
    BSF WPUB, 1		; Habilitando los Pullups en RB0 y RB1
    
    
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH		; Ninguna I/O analógica
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 7	; HABILITANDO PULLUPS PUERTO B
    BCF OPTION_REG, 5	; T0CS FOSC/4 modo temporizador
    BCF OPTION_REG, 3	; PSA asignar presscaler para TMR0
    
    BSF OPTION_REG, 2	
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0	; Prescaler 1:256
    
    BANKSEL PORTC
    CLRF PORTC		; Se limpia el puerto B
    CLRF PORTA		; Se limpia el puerto A
    CLRF estado
    CLRF CONT20MS	; Se limpian las variables
    
    BANKSEL INTCON
    BSF INTCON, 7   ; GIE Habilitar interrupciones globales
    BSF INTCON, 3   ; RBIE Habilitar interrupciones de PORTB
    BCF INTCON, 0   ; Bandera de interrupción de puerto B apagada
    
    BANKSEL TMR0
    MOVLW 179	    
    MOVWF TMR0	    ; Se carga el valor de TMR0
    
LOOP:
    MOVF estado, W
    SUBLW 0		; Resta estado a 0
    BTFSC STATUS, 2
    GOTO ESTADO0	; Si resultado es 0 ir a ESTADO0
    MOVF estado, W
    SUBLW 1		; Resta estado a 1
    BTFSC STATUS, 2
    GOTO ESTADO1	; Si resultado es 0 ir a ESTADO1
    MOVF estado, W
    SUBLW 2		; Resta estado a 2
    BTFSC STATUS, 2
    GOTO ESTADO2	; Si resultado es 0 ir a ESTADO2
    MOVF estado, W
    SUBLW 3		; Resta estado a 3
    BTFSC STATUS, 2
    GOTO ESTADO3	; Si resultado es 0 ir a ESTADO3
    
ESTADO0:
    BCF INTCON, 5   ; Deshabilitar interrupción de TMR0
    MOVLW 10000000B ; Cargar valor del estado al puerto A
    MOVWF PORTA
    GOTO LOOP
    
ESTADO1:
    BCF INTCON, 5   ; Deshabilitar interrupción de TMR0
    MOVLW 01000000B ; Cargar valor del estado al puerto A
    MOVWF PORTA
    GOTO LOOP
    
ESTADO2:
    BSF INTCON, 5   ; Habilitar interrupción de TMR0
    BCF INTCON, 2   ; Bandera T0IF apagada
    MOVLW 00100000B ; Cargar valor del estado al puerto A
    MOVWF PORTA
    INCF PORTC, F   ; Incrementa puerto C cada segundo
    
VERIFICACION:
    MOVF CONT20MS, W	; Carga el valor de la variable a W
    SUBLW 50		; Resta el valor a 50
    BTFSS STATUS, 2	; Revisa si el resultado es 0
    GOTO VERIFICACION	; Si no es 0 regresa a verificación
    CLRF CONT20MS	; Si es 0 limpia la variable y vuelve al loop
    GOTO LOOP
    
ESTADO3:
    BSF INTCON, 5   ; Habilitar interrupción de TMR0
    BCF INTCON, 2   ; Bandera T0IF apagada
    MOVLW 00010000B ; Cargar valor del estado al puerto A
    MOVWF PORTA
    DECF PORTC, F   ; Decrementa puerto C cada segundo
    
VERIFICACION2:
    MOVF CONT20MS, W	; Carga el valor de la variable a W
    SUBLW 50		; Resta el valor a 50
    BTFSS STATUS, 2	; Revisa si el resultado es 0
    GOTO VERIFICACION2	; Si no es 0 regresa a verificación
    CLRF CONT20MS	; Si es 0 limpia la variable y vuelve al loop
    GOTO LOOP
    
;******************************************************************************* 
; Fin de Código    
;******************************************************************************* 
END   





