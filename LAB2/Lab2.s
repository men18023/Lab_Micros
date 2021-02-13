;**************************
; Laboratorio 2 - Sumador de 4 bits
;**************************
; Archivo:	Lab2.s
; Dispositivo:	PIC16F887
; Autor:       Jonathan Menendez, 18023
; Compilador:  pic-as (v2.30), MBPLABX v5.40
; Video: 
;**************************

PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
  CONFIG FOSC=XT   // Oscilador externo
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
PSECT udata_bank0
  
PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset--------------;
ORG 00h     ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
 
PSECT code, delta=2, abs
ORG 100h    ; posicion para le codigo
;-----------configuracion--------------;

	
main:

    ; Configuracion de los puertos
    banksel ANSEL	; Se selecciona bank 3
    clrf    ANSEL	; Definir puertos digitales
    clrf    ANSELH
    
    banksel TRISA	; Se selecciona bank 1
    bsf     TRISA, 0    ; se establecen como inputs para los pushbuttons
    bsf     TRISA, 1
    bsf     TRISA, 2
    bsf     TRISA, 3
    bsf     TRISA, 4
    bsf     TRISA, 6
    bsf     TRISA, 7
    
    movlw   00000000B    ; se establecen como outputs
    movwf   TRISB
    movlw   00000000B
    movwf   TRISC
    movlw   00000000B
    movwf   TRISD
    
    banksel PORTA	; clear en los puertos
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD


;**************************
;*********Loop************

loop:
    
    btfsc   PORTA, 0	; Se asigna una entrada para cada pushbutton
    call    inc1	; Llamar al contador
    
    btfsc   PORTA, 1
    call    dec1
    
    btfsc   PORTA, 2
    call    inc2
    
    btfsc   PORTA, 3
    call    dec2
    
    btfsc   PORTA, 4
    call    suma
    
goto loop		
    
;****************************
;*******Sub-Rutinas**********

    
inc1: ; Incremento
    btfsc   PORTA, 0    ; Ubicacion del pushbutton
    goto    $-1         ; Regresa una instruccion
    incf    PORTB, 1	; Incrementa 1 y se muestra en los leds
    return              ; Regresa al main loop

dec1: ; Decremento
    btfsc   PORTA, 1	; Ubicacion del push button
    goto    $-1		; Regresa una instruccion
    decfsz  PORTB, 1	; Decrementa 1 y se muestra en los leds
    return		; Regresa al main loop
    
inc2:
    btfsc   PORTA, 2
    goto    $-1
    incf    PORTC, 1
    return
    
dec2:
    btfsc   PORTA, 3
    goto    $-1
    decfsz  PORTC, 1
    return

suma:
    btfsc   PORTA, 4       ;Ubicacion  del pushbutton
    goto    $-1            ;
    movf    PORTB, 0       ;Se selecciona el valor inicial
    addwf   PORTC, 0       ;Valor que se va a sumar
    movwf   PORTD          ;Asigna valor a los leds de salida del puerto D
    return
    
END