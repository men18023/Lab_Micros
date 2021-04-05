;;**************************
; Proyecto 01 - Semáforo de 3 vías
;**************************
; Archivo:	Proyecto1.s
; Dispositivo:	PIC16F887
; Autor:       Jonathan Menendez, 18023
; Compilador:  pic-as (v2.30), MBPLABX v5.40
; Video: 
;**************************

PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
  CONFIG FOSC=  INTRC_NOCLKOUT   // Oscilador interno
  CONFIG WDTE=  OFF  // WDT disabled (reinicio repetitivo del pic)
  CONFIG PWRTE= ON  // PWRT enabled (espera de 72ms al iniciar)
  CONFIG MCLRE= OFF // El pin MCLR se utiliza como I/0
  CONFIG CP=    OFF    // Sin proteccion de codigo
  CONFIG CPD=   OFF   // Sin proteccion de datos
    
  CONFIG BOREN= OFF // Sin reinicio cuando el voltaje de alimentacion baja de 4V
  CONFIG IESO=  OFF  // Reinicio sin cambio de reloj de interno a externo
  CONFIG FCMEN= OFF // Cambio de reloj externo a interno en caso de fallo
  CONFIG LVP=   ON    // Programacion en bajo voltaje permitida
    
;configuration word 2
  CONFIG WRT=OFF   // Proteccion de autoescritura por el programa desactivada
  CONFIG BOR4V=BOR40V  // Reinicio abajo de 4V, (BOR21V=2.1V)

MODO    EQU 0  
UP      EQU 1
DOWN    EQU 2

  reinicio_tmr0 macro
    banksel PORTA
    movlw   253
    movwf   TMR0    
    bcf	    T0IF
  endm
  
  reinicio_tmr1 macro
    banksel TMR1H	;se llama al bank del timer1
    movlw   225		;valor inicial que sera colocado en el tmr1
    movwf   TMR1H
    movlw   124
    movwf   TMR1L
    bcf	    TMR1IF
    endm

PSECT udata_bank0  ;common memory
    contador:	 DS 1
    cont1:	 DS 1
    cont2:	 DS 1
    cont3:	 DS 1
    cont_big:	 DS 1
    cont_small:	 DS 1  
    cont_nano:	 DS 1
    banderas:	 DS 1  
    modo_sem:	 DS 1   
    estado:	 DS 1
    tiempo:	 DS 1
    tiempo1:	 DS 1
    tiempo2:	 DS 1
    tiempo3:	 DS 1
    check1:	 DS 1  
    check2:	 DS 1
    check3:	 DS 1
    sust:	 DS 1
    unidad1:	 DS 1	
    unidad2:	 DS 1
    unidad3:	 DS 1
    unidad4:	 DS 1 
    decena:	 DS 1
    tipo_sem:	 DS 1  
    c1_temp:	 DS 1
    c2_temp:	 DS 1
    c3_temp:	 DS 1
    carga:	 DS 1  
    display_var: DS 8
 
 PSECT udata_shr  
    W_temp:	 DS 1 ;1 byte
    STATUS_temp: DS 1 ;1 byte

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
    movwf   W_temp
    swapf   STATUS, W
    movwf   STATUS_temp
    
isr:
    btfsc   RBIF	    ;revisar interrupciones en el puerto B
    call    int_PB	    ;llamada a subrutina de pushbuttons
    btfsc   T0IF	    
    call    int_TMR0	    ;llamada a subrutina de timer0
    btfsc   TMR1IF
    call    int_TMR1
   
pop:
    swapf   STATUS_temp, W
    movwf   STATUS
    swapf   W_temp, F
    swapf   W_temp, W
    retfie
;----------------------sub rutinas de int--------------;
    
int_PB:
    banksel PORTB
    btfss   PORTB, MODO
    incf    estado	
    movlw   6
    subwf   estado, W	;
    btfss   ZERO	
    goto    $+3
    movlw   2
    movwf   estado
    
    btfss   PORTB, UP
    incf    carga, F
    movlw   21		
    subwf   carga, W
    btfsc   ZERO
    goto    min
    
    btfss   PORTB, DOWN
    decf    carga, F
    movlw   9		
    subwf   carga, W
    btfsc   ZERO
    goto    max
    bcf	    RBIF
    return
    
min:
    movlw   10
    movwf   carga
    bcf	    RBIF
    return
max:
    movlw   20
    movwf   carga
    bcf	    RBIF
    return

int_TMR0:		    ;subrutina de interrupcion del tmr0
    reinicio_tmr0           
    clrf    PORTA
    
    btfsc   banderas, 0	    ;se enciende la bandera de cada display
    goto    display1
    
    btfsc   banderas, 1
    goto    display2
    
    btfsc   banderas, 2
    goto    display3
    
    btfsc   banderas, 3
    goto    display4
    
    btfsc   banderas, 4	    ;se enciende la bandera de cada display
    goto    display5
    
    btfsc   banderas, 5
    goto    display6
    
    btfsc   banderas, 6
    goto    display7
   
display0:			;Primer display hexa
    movf    display_var+1, W	;se elige el byte de la varriable
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 0		;transistor que se desea activar
    goto    siguiente_0		;llamada a instruccion siguiente
    
display1:
    movf    display_var, W	;Segundo display hexa
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 1		;transistor que se desea activar
    goto    siguiente_1

display2:
    movf    display_var+3, W	;Primer display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 2		;transistor que se desea activar
    goto    siguiente_2
    
display3:
    movf    display_var+2, W	;Segundo display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 3		;transistor que se desea activar
    goto    siguiente_3

display4:
    movf    display_var+5, W	;Tercer display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 4		;transistor que se desea activar
    goto    siguiente_4

display5:
    movf    display_var+4, W	;Segundo display hexa
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 5		;transistor que se desea activar
    goto    siguiente_5
    
display6:
    movf    display_var+7, W	;Primer display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 6		;transistor que se desea activar
    goto    siguiente6
    
display7:
    movf    display_var+6, W	;Segundo display decimal
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 7		;transistor que se desea activar
    goto    siguiente7
    
siguiente_0:		;Intruccion de rotacion de displays 
    movlw   00000001B
    xorwf   banderas, 1	    ;XOR para hacer la rotacion
    return
siguiente_1:
    movlw   00000011B
    xorwf   banderas, 1
    return
siguiente_2:
    movlw   00000110B
    xorwf   banderas, 1
    return
siguiente_3:
    movlw   00001100B
    xorwf   banderas, 1
    return
siguiente_4:
    movlw   00011000B
    xorwf   banderas, 1
    return
siguiente_5:
    movlw   00110000B
    xorwf   banderas, 1
    return
siguiente6:
    movlw   01100000B
    xorwf   banderas, 1
    return
siguiente7:
    clrf    banderas
    return

int_TMR1: 
    reinicio_tmr1  ;50ms
    incf    contador
    movwf   contador, W
    sublw   2	    ;500ms * 2 = 1s
    btfss   ZERO
    goto    return_tm1
    clrf    contador	
    incf    tiempo	
    
    btfss   sust, 0	
    decf    check1		
    btfsc   ZERO
    bsf	    sust, 0
    
    btfss   sust, 1
    decf    check2
    btfsc   ZERO
    bsf	    sust, 1
    
    btfss   sust, 2
    decf    check3
    btfsc   ZERO
    bsf	    sust, 2
    
return_tm1:
    return
    
 PSECT code, delta=2, abs
 ORG 100h   
tabla: 
    clrf    PCLATH
    bsf	    PCLATH, 0	;PCLATH = 01
    addwf   PCL		
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
 
main:
    banksel ANSEL   
    clrf    ANSEL   
    clrf    ANSELH
    
    banksel TRISA
    clrf    TRISA
    clrf    TRISC
    clrf    TRISD
    clrf    TRISE
    clrf    TRISB
    bsf	    TRISB, UP
    bsf	    TRISB, DOWN
    bsf	    TRISB, MODO
    

    bcf	    OPTION_REG, 7   ;habilito pull-up
    bsf	    WPUB, UP	    ;selecciono pines
    bsf	    WPUB, DOWN
    bsf	    WPUB, MODO

    call    reloj
    call    timer0 
    call    timer1
    call    config_ioc
    call    int_enable
    call    config_inicial
    
    banksel PORTA   
    clrf    PORTA
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    clrf    PORTB
    clrf    tiempo
    clrf    modo_sem
    clrf    tipo_sem
    clrf    c1_temp
    clrf    c2_temp
    clrf    c3_temp

;---------------------------loop------------------------;
 
loop:
    movf    check1, W		
    movwf   unidad1		
    call    division1
    call    prep_display1
    
    movf    check2, W
    movwf   unidad2
    call    division2
    call    prep_display2
    
    movf    check3, W
    movwf   unidad3
    call    division3
    call    prep_display3
    
    btfss   tipo_sem, 0
    call    fun_normal	
    
    movlw   2
    subwf   estado, W
    btfsc   ZERO
    call    cambio_S1	
    
    movlw   3
    subwf   estado, W
    btfsc   ZERO
    call    cambio_S2	
    
    movlw   4
    subwf   estado, W
    btfsc   ZERO
    call    cambio_S3	
    
    movlw   5
    subwf   estado, W
    btfsc   ZERO
    call    confirmacion	
    
    goto    loop
    
reloj:
    banksel OSCCON
    bsf	    IRCF2   ;4MHZ = 110
    bsf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS	    ;reloj interno 
    return
 
config_ioc:
    banksel TRISB
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN
    bsf	    IOCB, MODO
    
    banksel PORTA
    movf    PORTB, W	
    bcf	    RBIF
    return
 
int_enable:
    bsf	    GIE
    bsf	    T0IE
    bcf	    T0IF
    
    bsf	    TMR1IE 
    bcf	    TMR1IF
    
    bsf	    RBIE
    bcf	    RBIF
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
    bcf	    TMR1CS     ; reloj interno
    bsf	    TMR1ON     ; Se activa timer1
    reinicio_tmr1
    return    
 
config_inicial:
    movlw   10
    movwf   cont1
    movwf   cont2
    movwf   cont3
    movf    cont1, W
    movwf   check1
    movf    cont2, W
    movwf   check2
    movf    cont3, W
    movwf   check3
    movlw   1
    movwf   estado
    movlw   10
    movwf   carga
    movlw   11111110B
    movwf   sust
    return
    
;---------------------------------------------------------------------;    
 
verde1:
    movlw   00000100B	;
    movwf   PORTE
    movlw   00001001B	;
    movwf   PORTD
    movwf   tiempo, W
    addlw   5
    subwf   cont1, W
    btfsc   ZERO	
    call    parpadeo1
    return
    
amarillo1:
    movlw   00000010B	
    movwf   PORTE
    movlw   00001001B
    movwf   PORTD   
    movlw   3
    subwf   tiempo, W
    btfsc   ZERO
    call    rojo1
    return
    
rojo1:
    bcf	    modo_sem, 1	
    bsf	    modo_sem, 2
    movf    cont2, W
    movwf   check2, F
    movlw   253
    movwf   sust
    clrf    tiempo
    return
    
verde2:
    movlw   00000001B	
    movwf   PORTE
    movlw   00001100B	
    movwf   PORTD
    movwf   tiempo, W	
    addlw   5
    subwf   cont2, W
    btfsc   ZERO	;
    call    parpadeo2
    return
    
amarillo2:
    movlw   00000001B	
    movwf   PORTE
    movlw   00001010B
    movwf   PORTD   
    movlw   3
    subwf   tiempo, W
    btfsc   ZERO
    call    rojo2
    return
    
rojo2:
    bcf	    modo_sem, 3
    bsf	    modo_sem, 4
    movf    cont3, W
    movwf   check3, F
    movlw   251
    movwf   sust
    clrf    tiempo
    return
 
verde3:
    movlw   00000001B
    movwf   PORTE
    movlw   00100001B
    movwf   PORTD
    movwf   tiempo, W
    addlw   5
    subwf   cont3, W
    btfsc   ZERO	
    call    parpadeo3
    return
    
amarillo3:
    movlw   00000001B
    movwf   PORTE
    movlw   00010001B
    movwf   PORTD   
    movlw   3
    subwf   tiempo, W
    btfsc   ZERO
    call    rojo3
    return
    
rojo3:
    bcf	    modo_sem, 5
    bcf	    modo_sem, 0
    movf    cont1, W
    movwf   check1, F
    movlw   254
    movwf   sust
    clrf    tiempo
    return

;--------------------------------------------------------;
    
parpadeo1:
    bcf	    PORTE, 2
    call    delay
    subwf   tiempo,W
    sublw   1
    bsf	    PORTE, 2
    call    delay
    bcf	    PORTE, 2
    call    delay
    bsf	    PORTE, 2
    call    delay
    bcf	    PORTE, 2
    call    delay
    bsf	    PORTE, 2
    call    delay
    bcf	    PORTE, 2
    bsf	    modo_sem, 0
    bsf	    modo_sem, 1
    clrf    tiempo
    return
    
parpadeo2:
    bcf	    PORTD, 2
    call    delay
    bsf	    PORTD, 2
    call    delay
    bcf	    PORTD, 2
    call    delay
    bsf	    PORTD, 2
    call    delay
    bcf	    PORTD, 2
    call    delay
    bsf	    PORTD, 2
    call    delay
    bcf	    PORTD, 2
    bcf	    modo_sem, 2
    bsf	    modo_sem, 3
    clrf    tiempo
    return
    
parpadeo3:
    bcf	    PORTD, 5
    call    delay
    bsf	    PORTD, 5
    call    delay
    bcf	    PORTD, 5
    call    delay
    bsf	    PORTD, 5
    call    delay
    bcf	    PORTD, 5
    call    delay
    bsf	    PORTD, 5
    call    delay
    bcf	    PORTD, 5
    bcf	    modo_sem, 4
    bsf	    modo_sem, 5
    clrf    tiempo
    return
    
delay:
    movlw   255		    
    movwf   cont_big	    
    call    delay2	   
    decfsz  cont_big, 1	   
    goto    $-2		   
    return
    
delay2:
    movlw   130		    
    movwf   cont_small
    call    delay3
    decfsz  cont_small, 1   
    goto    $-2		    
    return

delay3:
    movlw   1
    movwf   cont_nano
    decfsz  cont_nano, 1
    goto    $-1
    return
;-------------------------------------------------------;
    
division1:
    clrf    decena
    movlw   10
    subwf   unidad1, F
    btfsc   CARRY	
    incf    decena	
    btfsc   CARRY
    goto    $-5 
    movlw   10
    addwf   unidad1, F
    return

division2:
    clrf    decena
    movlw   10
    subwf   unidad2, F
    btfsc   CARRY	
    incf    decena	
    btfsc   CARRY
    goto    $-5 
    movlw   10
    addwf   unidad2, F
    return    

division3:
    clrf    decena
    movlw   10
    subwf   unidad3, F
    btfsc   CARRY	
    incf    decena	
    btfsc   CARRY
    goto    $-5 
    movlw   10
    addwf   unidad3, F
    return
    
division4:
    clrf    decena
    movlw   10
    subwf   unidad4, F
    btfsc   CARRY	
    incf    decena	
    btfsc   CARRY
    goto    $-5 
    movlw   10
    addwf   unidad4, F
    return
    
prep_display1:
    movf    decena, W	    
    call    tabla
    movwf   display_var+1
    
    movf    unidad1, W
    call    tabla
    movwf   display_var
    return
    
prep_display2:
    movf    decena, W	    ;
    call    tabla
    movwf   display_var+3
    
    movf    unidad2, W
    call    tabla
    movwf   display_var+2 
    return
    
prep_display3:
    movf    decena, W	    ;
    call    tabla
    movwf   display_var+5
    
    movf    unidad3, W
    call    tabla
    movwf   display_var+4 
    return   
    
prep_display4:
    movf    decena, W	;
    call    tabla
    movwf   display_var+6
    
    movf    unidad4, W
    call    tabla
    movwf   display_var+7
    return

;---------------------------------------------------------------------;    
confirmar:
    decf    carga	    ;
    movf    c1_temp, W
    movwf   cont1, F
    movwf   check1
    movf    c2_temp, W
    movwf   cont2, F
    movwf   check2
    movf    c3_temp, W
    movwf   cont3, F
    movwf   check3
    movlw   00000001B
    movwf   estado
    bcf	    tipo_sem, 0	;
    movlw   0000110B
    movwf   sust
    clrf    modo_sem
    clrf    tiempo
    clrf    PORTB
    clrf    display_var+7
    clrf    display_var+6
    return
    
rechazar:
    movlw   00000001B	
    movwf   estado
    incf    carga
    movf    cont1, W
    movwf   check1
    movf    cont2, W
    movwf   check2
    movf    cont3, W
    movwf   check3
    bcf	    tipo_sem, 0
    movlw   0000110B
    movwf   sust
    clrf    modo_sem
    clrf    tiempo
    clrf    PORTB
    clrf    display_var+7
    clrf    display_var+6
    return
    
fun_normal:
    btfss   modo_sem, 0 
    call    verde1	
    btfsc   modo_sem, 1 
    call    amarillo1		
    btfsc   modo_sem, 2 
    call    verde2	
    btfsc   modo_sem, 3 
    call    amarillo2	
    btfsc   modo_sem, 4 
    call    verde3	
    btfsc   modo_sem, 5 
    call    amarillo3	
    return
	
cambio_S1:
    bsf	    PORTB, 3
    bcf	    PORTB, 4
    bcf	    PORTB, 5
    movf    carga, W
    movwf   c1_temp	
    movf    c1_temp, W
    movwf   unidad1
    movwf   unidad4
    call    division1
    call    division4
    call    prep_display4
    return
    
cambio_S2:
    bcf	    PORTB, 3
    bsf	    PORTB, 4
    bcf	    PORTB, 5
    movf    carga, W
    movwf   c2_temp
    movf    c2_temp, W
    movwf   unidad2
    movwf   unidad4
    call    division2
    call    division4
    call    prep_display4
    return

cambio_S3:
    bcf	    PORTB, 3
    bcf	    PORTB, 4
    bsf	    PORTB, 5
    movf    carga, W
    movwf   c3_temp
    movf    c3_temp, W
    movwf   unidad3
    movwf   unidad4
    call    division3	
    call    division4
    call    prep_display4
    return

confirmacion:
    bsf	    tipo_sem, 0	    
    bsf	    PORTB, 3
    bsf	    PORTB, 4
    bsf	    PORTB, 5
    movlw   000111111B  
    movwf   PORTD
    movlw   000000111B
    movwf   PORTE
    btfss   PORTB, UP   
    call    confirmar
    btfss   PORTB, DOWN
    call    rechazar
    return
END
