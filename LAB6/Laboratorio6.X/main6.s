;**************************
; Laboratorio 6 - Temporizadores
;**************************
; Archivo:	main6.s
; Dispositivo:	PIC16F887
; Autor:       Jonathan Menendez, 18023
; Compilador:  pic-as (v2.30), MBPLABX v5.40
; Video:
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

reinicio_tmr0 macro ;macro para el reinicio del tmr 0
 banksel PORTA	    ;se llama al bank
 movlw  255	    ;valor inicial que sera colocado en el tmr0
 movwf  TMR0
 bcf	T0IF	    ;se resetea el T0IF
 endm
 
reinicio_tmr1 macro ;macro para el reinicio del tmr 1
 banksel TMR1H	    ;se llama al bank del timer1
 movlw  225	    ;valor inicial que sera colocado en el tmr1
 movwf  TMR1H
 movlw	124
 movwf	TMR1L
 incf	cont
 bcf	TMR1IF
 endm
 
reinicio_tmr2 macro ;macro del valor de PR2 del timer2
 banksel PR2
 movlw	100
 movwf	PR2
 endm
 
PSECT udata_bank0   ;common memory
  cont:         DS 1	;cantidad de bytes en cada variable
  cont2:	DS 1
  banderas_p:	DS 1

;variables
PSECT udata_shr
  W_TEMP:	DS 1	    ;variables a utilizar 
  STATUS_TEMP:  DS 1	    ;asignar cantidad de bytes a cada variable
  banderas:	DS 2
  nibble:	DS 2 
  display_var:  DS 5
  band_p:	DS 1	
  reg:		DS 1
    
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
    btfsc   T0IF	    
    call    int_T0	    ;llamada a subrutina de timer0
    btfsc   TMR1IF
    call    int_T1
    btfsc   TMR2IF
    call    int_T2
    bcf	    TMR2IF
    
pop:
    swapf   STATUS_TEMP, W  ;regresa a W al status
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
;--------------sub rutinas de int------:
	
int_T0:		    ;subrutina de interrupcion del tmr0
    reinicio_tmr0           
    bcf	    PORTA, 0	        ;se limpian puertos de los transistores
    bcf	    PORTA, 1
    btfsc   banderas, 0
    goto    display1
   
display0:			;Primer display hexa
    movf    display_var, W	;se elige el byte de la variable
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 0		;transistor que se desea activar
    goto    siguiente
    
display1:
    movf    display_var+1, W	;Segundo display hexa
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 1		;transistor que se desea activar

siguiente:  
    movlw   1                 ;xor para cambiar entre cada display
    xorwf   banderas, F
    return
    
int_T1:
    reinicio_tmr1           ; se llama nuestro macro del timer1
    return
 
int_T2:
    btfsc   band_p, 0   ; se prueba la bandera y se enciende si se cumple
    goto    apagar
    
encender:
    bsf	    band_p, 0
    return
    
apagar:
    bcf	    band_p, 0
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

    ;Se activan las salidas de los transistores
    banksel TRISA
    bcf	    TRISA, 0
    bcf	    TRISA, 1
    
    banksel TRISC
    movlw   00000000B   ;se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    bcf	    TRISD, 0
    
    call    reloj	;se llama al reloj 
    call    config_int	;se llama a nuestra configuracion de pull up
    call    timer0	;se llama a nuestro timer0
    call    timer1	;se llama a nuestro timer1
    call    timer2	;se llama a nuestro timer2
    
    banksel PORTA	;se limpian los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    cont
;**************************
;*********Loop************

loop:
    reinicio_tmr2
    banksel PORTA	;llamada a la seleccion de nibbles para cada displays
    call    div_displays
    
    btfss   band_p, 0
    call    prep_displays
    
    btfsc   band_p, 0
    call    parpadeo    ; se llama intruccion de parpadeo
    
    goto loop		; sigue en el loop
  
;****************************
;*******Sub-Rutinas**********

div_displays:
    movf    cont, W     ;se mueve cada valor de la variable a una parte del nibble
    andlw   0x0F
    movwf   nibble
    swapf   cont, W
    andlw   0x0F
    movwf   nibble+1
    
prep_displays:
    movf    nibble, W	    ;se asigna el valor del nibble para cada byte del display
    call    tabla
    movwf   display_var
    
    movf    nibble+1, W
    call    tabla
    movwf   display_var+1
    bsf	    PORTD, 0
    
reloj:
    banksel  OSCCON
    bcf      IRCF2      ; IRCF = 010 250 KHz
    bsf	     IRCF1
    bcf	     IRCF0
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
    
timer1:
    banksel T1CON     
    bsf	    T1CKPS1    ; Prescaler de 11   rate 1:8
    bsf	    T1CKPS0
    bcf	    TMR1CS     ; Se utiliza reloj interno
    bsf	    TMR1ON     ; Se activ timer1
    reinicio_tmr1
    return

timer2:
    banksel T2CON
    movlw   01001110B  ;se enciende timer2 y selecciona los Pre y Pos
    movwf   T2CON     ; Postcaler 10  y  prescaler de 16
    return
    
config_int:
    banksel INTCON   ; interrupciones de los 3 timers
    bsf	    GIE
    bsf	    T0IE
    bcf	    T0IF
    banksel PIE1
    bsf	    TMR1IE
    bcf	    TMR1IF
    bsf	    TMR2IE
    bcf	    TMR2IF
    return
 
parpadeo:
    movlw   0		   ;se mueve un valor al valor de display y led
    movwf   display_var	   ;para causar parpadeo
    movwf   display_var+1
    bcf	    PORTD, 0
    return
    
END





