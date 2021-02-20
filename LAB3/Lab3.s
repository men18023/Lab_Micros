;**************************
; Laboratorio 3 - Botones y Timer 0
;**************************
; Archivo:	Lab3.s
; Dispositivo:	PIC16F887
; Autor:       Jonathan Menendez, 18023
; Compilador:  pic-as (v2.30), MBPLABX v5.40
; Video: https://www.youtube.com/watch?v=09ineM5k9nA&feature=youtu.be
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

;variables
PSECT udata_shr
  reg:		    ;variable a utilizar en 7 segmentos y comparador
    DS 1

  
PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset--------------;
ORG 00h     ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
 
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
    
;-----------configuracion--------------;
	
main:
   
    banksel ANSEL	; se escoge banco 
    clrf    ANSEL	; limpiar puertos digitales
    clrf    ANSELH
    
    banksel TRISA	; se selecciona bank1
    bcf	    TRISA, 0	; se configura los pines de salida del contador
    bcf	    TRISA, 1
    bcf	    TRISA, 2
    bcf	    TRISA, 3
    
    bsf	    TRISB, 0	;se configuran los pines de entrada de los pushbuttons
    bsf	    TRISB, 1
    
    movlw   00000000B   ;se configuran los pines de salida del 7 segmentos
    movwf   TRISC
    
    bcf	    TRISD, 0	;se configura el pin de salida del led de alarma
    
    call    reloj	;se llama al reloj 
    call    timer0	;se llama a nuestro timer 9
  
    banksel PORTA	;se limpian los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD

;**************************
;*********Loop************

loop:
    btfss   PORTB, 0    ;primer pushbutton del puertoB
    call    incre	;se llama subrutina del contador
    
    btfss   PORTB, 1    ;segundo pushbutton del puertoB
    call    decre	;se llama subrutia del contador
    
    btfss   T0IF	;sumar cuando el timer0 llegue a overflow
    goto    $-1
    call    reinicio_tmr0 ;regresa el overflow a 0
    incf    PORTA, 1
    
    bcf	    PORTD, 0	
    call    comp	;llama a la subrutina del comparador
    
    goto loop		; sigue en el loop
  
;****************************
;*******Sub-Rutinas**********
reloj:
    banksel  OSCCON
    bcf      IRCF2      ; IRCF = 010 250kHz
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
    bcf	    PS0        ; PS = 110
    banksel PORTA
    call    reinicio_tmr0
    return

reinicio_tmr0:
    movlw   11	    ;valor incial del timer0
    movwf   TMR0    ;se mueve al timer0
    bcf	    T0IF    ;vuelve 0 al bit de overflow
    return

incre: ; Incremento
    btfss   PORTB, 0    ; Ubicacion del pushbutton
    goto    $-1         ; Regresa una instruccion
    incf    reg	; Incrementa 1 y se muestra en los leds
    movf    reg, W
    call    tabla
    movwf   PORTC
    return              ; Regresa al main loop

decre: ; Decremento
    btfsc   PORTB, 1	; Ubicacion del push button
    goto    $-1         ; Regresa una instruccion
    decfsz  reg	       ; Incrementa 1 y se muestra en los leds
    movf    reg, W
    call    tabla
    movwf   PORTC
    return              ; Regresa al main loop
    
comp:
    movf    PORTA, W	; Se mueve el valor del contador a w
    subwf   reg, W      ; Se compara el valor w con el de la variable reg
    btfsc   STATUS, 2   ; Si son iguales se levanta la bandera z
    call    alarma	; Se llama a la alarma
    return		
    
alarma:
    bsf	    PORTD, 0	; Se enciende el led de alarma
    clrf    PORTA	; Se reinicia el contador
    return
    
END


