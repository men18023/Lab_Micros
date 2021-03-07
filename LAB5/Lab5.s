;**************************
; Laboratorio 5 - Displays Simultaneos
;**************************
; Archivo:	Lab5.s
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

UP    EQU 0   ;asignacion de nombres para los pushbutton 
DOWN  EQU 1
 
reinicio_tmr0 macro ;macro para el reinicio del tmr 0
 banksel PORTA	    ;se llama al bank
 movlw  253	    ;valor inicial que sera colocado en el tmr0
 movwf  TMR0
 bcf	T0IF	    ;se resetea el T0IF
 endm
 
PSECT udata_bank0   ;common memory
  var:          DS 2	;cantidad de bytes en cada variable
  unidad:	DS 1
  decena:	DS 1
  centena:	DS 1
    
;variables
PSECT udata_shr
  W_TEMP:	DS 1	    ;variables a utilizar 
  STATUS_TEMP:  DS 1	    ;asignar cantidad de bytes a cada variable
  banderas:	DS 2
  nibble:	DS 2 
  display_var:  DS 5
    
    
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
    call    int_T0	    ;llamada a subrutina de timer0
    
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
    incf    var
    movf    var, W
    movwf   PORTA
    btfss   PORTB, DOWN
    decf    var
    movf    var, W
    movwf   PORTA
    bcf	    RBIF
    return
	
int_T0:		    ;subrutina de interrupcion del tmr0
    reinicio_tmr0           
    bcf	    PORTE, 0	    ;se limpian puertos de los transistores
    bcf	    PORTE, 1
    bcf	    PORTB, 5
    bcf	    PORTB, 6
    bcf	    PORTB, 7
    
    btfsc   banderas, 0	    ;se enciende la bandera de cada display
    goto    display1
    
    btfsc   banderas, 1
    goto    display2
    
    btfsc   banderas, 2
    goto    display3
    
    btfsc   banderas, 3
    goto    display4
   
display0:			;Primer display hexa
    movf    display_var, W	;se elige el byte de la varriable
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTE, 0		;transistor que se desea activar
    goto    siguiente0		;llamada a instruccion siguiente
    
display1:
    movf    display_var+1, W	;Segundo display hexa
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTE, 1		;transistor que se desea activar
    goto    siguiente1

display2:
    movf    display_var+2, W	;Primer display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTB, 5		;transistor que se desea activar
    goto    siguiente2
    
display3:
    movf    display_var+3, W	;Segundo display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTB, 6		;transistor que se desea activar
    goto    siguiente3

display4:
    movf    display_var+4, W	;Tercer display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTB, 7		;transistor que se desea activar
    goto    siguiente4
    
siguiente0:		;Intruccion de rotacion de displays 
    movlw   00000001B
    xorwf   banderas, 1	    ;XOR para hacer la rotacion
    return
siguiente1:
    movlw   00000011B
    xorwf   banderas, 1
    return
siguiente2:
    movlw   00000110B
    xorwf   banderas, 1
    return
siguiente3:
    movlw   00001100B
    xorwf   banderas, 1
    return
siguiente4:
    clrf    banderas
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
    
    banksel TRISA	;Se asignan los pines de salida del los leds
    movlw   00000000B
    movwf   TRISA
    
    bsf	    TRISB, UP	;se configuran los pines de entrada de los pushbuttons
    bsf	    TRISB, DOWN
    
    ;Se activan las salidas de los transistores
    bcf	    TRISE, 0
    bcf	    TRISE, 1
    bcf	    TRISB, 5
    bcf	    TRISB, 6
    bcf	    TRISB, 7
    
    bcf	    OPTION_REG, 7   ;configuracion del Pull-Up
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    movlw   00000000B   ;se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    
    call    reloj	;se llama al reloj 
    call    config_ioc	;se llama a nuestra configuracion de pull up
    call    timer0	;se llama a nuestro timer0
    call    int_enable	;se llama configuracion de interrupciones
    
    banksel PORTA	;se limpian los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    var

;**************************
;*********Loop************

loop:
    banksel PORTA	;llamada a la seleccion de nibbles para cada displays
    call    sep_nibbles
    call    prep_displays
    banksel PORTA
    call    division
    
    goto loop		; sigue en el loop
  
;****************************
;*******Sub-Rutinas**********
    
sep_nibbles:
    movf    var, W	;se mueve cada valor del PORTA a una parte del nibble
    andlw   0x0f
    movwf   nibble
    swapf   var, W
    andlw   0x0f
    movwf   nibble+1
    return
    
prep_displays:
    movf    nibble, W	    ;se asigna el valor del nibble para cada byte del display
    call    tabla
    movwf   display_var
    
    movf    nibble+1, W
    call    tabla
    movwf   display_var+1
    
    movf    centena, W
    call    tabla
    movwf   display_var+2
    
    movf    decena, W
    call    tabla
    movwf   display_var+3
    
    movf    unidad, W
    call    tabla
    movwf   display_var+4
    
    return
    
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

int_enable:	    ;se habilitan las interrupciones en el puerto B y tmr0
    bsf	    GIE     ;INTCON
    bsf	    RBIE
    bsf	    T0IE
    bcf	    RBIF
    bcf	    T0IF
    return

division: 
    clrf    centena	    ;primer valor a encontrar
    movf    PORTA, 0	    ;Se mueve valor de leds a W
    movwf   unidad	    ;Se mueve w a nuestra variable
    movlw   100		    ;valor de 100 a W
    subwf   unidad, 0	    ;Se resta 100 a variable
    btfsc   STATUS, 0	    ;Se verifica la bandera de status 0
    incf    centena	    ;Si la bandera es 1, se incrementa
    btfsc   STATUS, 0	    ;Se mueve valor restante a unidad para seguir division
    movwf   unidad
    btfsc   STATUS, 0
    goto    $-7
    
    clrf    decena	    ;mismo proceso que para centena
    movlw   10		    ;se utiliza valor de 10 para encontrar decena
    subwf   unidad, 0
    btfsc   STATUS, 0
    incf    decena
    btfsc   STATUS, 0
    movwf   unidad	    ;lo sobrante son nuestras unidades
    btfsc   STATUS, 0
    goto    $-7
    btfss   STATUS, 0	    
    return

END








