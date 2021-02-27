;**************************
; Laboratorio 4 - Interrupt-on-change del PORTB
;**************************
; Archivo:	Lab4.s
; Dispositivo:	PIC16F887
; Autor:       Jonathan Menendez, 18023
; Compilador:  pic-as (v2.30), MBPLABX v5.40
; Video: https://www.youtube.com/watch?v=DzpCCrZqgrQ&feature=youtu.be
;**************************

PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
  CONFIG FOSC=INTRC_NOCLKOUT   // Oscilador interno
  CONFIG WDTE=OFF  // WDT disabled (reinicio repetitivo del pic)
  CONFIG PWRTE=ON  // PWRT enabled (espera de 72ms al iniciar)
  CONFIG MCLRE=OFF // El pin MCLR se utiliza como I/0
  CONFIG CP=OFF    // Sin proteccion de codigo
  CONFIG CPD=OFF   // Sin proteccion de datos
    
  CONFIG BOREN=OFF // Sin reinicio cuando el voltaje de alimentacion baja de 4V
  CONFIG IESO=OFF  // Reinicio sin cambio de reloj de interno a externo
  CONFIG FCMEN=OFF // Cambio de reloj externo a interno en caso de fallo
  CONFIG LVP=ON    // Programacion en bajo voltaje permitida
    
;configuration word 2
  CONFIG WRT=OFF   // Proteccion de autoescritura por el programa desactivada
  CONFIG BOR4V=BOR40V  // Reinicio abajo de 4V, (BOR21V=2.1V)

UP    EQU 0   ;asignacion de nombres para los pushbutton 
DOWN  EQU 1
 
reinicio_tmr0 macro ;macro para el reinicio del tmr 0
 banksel PORTA	    ;se llama al bank
 movlw  61	    ;valor inicial que sera colocado en el tmr0
 movwf  TMR0
 bcf	T0IF	    ;se resetea el T0IF
 endm
 
PSECT udata_bank0   ;common memory
  cont:         DS 2  ; dos bits
    
;variables
PSECT udata_shr
  W_TEMP:	DS 1	    ;variables a utilizar 
  STATUS_TEMP:  DS 1	    ;todas de 1 bit
  reg:          DS 1
  reg2:		DS 1

PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset--------------;
ORG 00h     ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main

PSECT intVect, class=CODE, abs, delta=2
;-----------vector interrupt--------------;
ORG 04h     ;posicion 0004h para las interrupciones
push:
    movwf   W_TEMP	    ;colocar las variables temporales a W
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:
    btfsc   RBIF	    ;revisar interrupciones en el puerto B
    call    int_iocb	    ;llamada a subrutina de pushbuttons
    btfsc   T0IF	    
    call    int_T0	    
    
pop:
    swapf   STATUS_TEMP, W  ;regresa a W al status
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
;--------------sub rutinas de int------:
int_iocb:
    banksel PORTA	    ;subrutina de interrupcion de los pushbutttons
    btfss   PORTB, UP
    incf    PORTA
    btfss   PORTB, DOWN
    decf    PORTA
    bcf	    RBIF
    return
	
int_T0:		    ;subrutina de interrupcion del tmr0
    reinicio_tmr0           ;50ms
    incf    cont
    movf    cont, W
    sublw   40
    btfss   ZERO       ; STATUS, 2
    goto    return_T0
    clrf    cont	;1000 ms
    incf    reg2
    movf    reg2, W
    call    tabla
    movwf   PORTD
    return

return_T0:
    return
    
PSECT code, delta=2, abs
ORG 100h    ; posicion para le codigo
 tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0   ;PCLATH = 01
    andlw   0x0f
    addwf   PCL         ;PC = PCLATH + PCL
    ; se configura la tabla para el siete segmentos
    retlw   00111111B  ;0
    retlw   00000110B  ;1
    retlw   01011011B  ;2
    retlw   01001111B  ;3
    retlw   01100110B  ;4
    retlw   01101101B  ;5
    retlw   01111101B  ;6
    retlw   00000111B  ;7
    retlw   01111111B  ;8
    retlw   01100111B  ;9
    retlw   01110111B  ;A
    retlw   01111100B  ;B
    retlw   00111001B  ;C
    retlw   01011110B  ;D
    retlw   01111001B  ;E
    retlw   01110001B  ;F
    
;--------------------------------------;    
;-----------configuracion--------------;
	
main:
   
    banksel ANSEL	; se escoge bank 3
    clrf    ANSEL	; limpiar puertos digitales
    clrf    ANSELH
    
    banksel TRISA	; se selecciona bank1
    bcf	    TRISA, 0	; se configura los pines de salida del contador
    bcf	    TRISA, 1
    bcf	    TRISA, 2
    bcf	    TRISA, 3
    
    bsf	    TRISB, UP	;se configuran los pines de entrada de los pushbuttons
    bsf	    TRISB, DOWN
    
    bcf	    OPTION_REG, 7
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    
    movlw   00000000B   ;se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    
    movlw   00000000B
    movwf   TRISD	;se configuran los pines del 7 segmentos con tmr0
    
    call    reloj	;se llama al reloj 
    call    config_ioc	;se llama a nuestra configuracion de pull up
    call    timer0	;se llama a nuestro timer0
    call    int_enable	;se llama configuracion de interrupciones
    
    banksel PORTA	;se limpian los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD

;**************************
;*********Loop************

loop:
    call    display_c	;llama la funcion del 7 segmentos del contador en binario
    
    goto loop		; sigue en el loop
  
;****************************
;*******Sub-Rutinas**********
config_ioc:
    banksel TRISA
    bsf	    IOCB, UP	   ;se colocan los pushbuttons como pull ups
    bsf	    IOCB, DOWN
    
    banksel PORTA
    movf    PORTB, W
    bcf	    RBIF
    return
    
reloj:
    banksel  OSCCON
    bsf      IRCF2      ; IRCF = 111 8MHz
    bsf	     IRCF1
    bsf	     IRCF0
    bsf	     SCS        ; reloj interno
    return
    
timer0:
    banksel TRISA
    bcf	    T0CS       ;reloj interno
    bcf	    PSA	       ;Prescaler
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0        ; PS = 111   rate 1:256
    banksel PORTA
    reinicio_tmr0
    return

int_enable:	    ;se habilitan las interrupciones en el puerto B y tmr0
    bsf	    GIE     ;INTCON
    bsf	    RBIE
    bsf	    T0IE
    bcf	    RBIF
    bcf	    T0IF
    return
    
display_c: 
    banksel PORTA 
    movf    PORTA, W	; Se mueve el valor del contador a w
    movwf   reg
    movf    reg, W
    call    tabla
    movwf   PORTC	; Se mueve valor de la tabla a 7 segmentos
    return		
    
END





