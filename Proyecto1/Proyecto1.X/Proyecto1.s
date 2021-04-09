;;**************************
; Proyecto 01 - Semáforo de 3 vías
;**************************
; Archivo:	Proyecto1.s
; Dispositivo:	PIC16F887
; Autor:       Jonathan Menendez, 18023
; Compilador:  pic-as (v2.30), MBPLABX v5.40
; Video: https://youtu.be/wbSrbtDuweg
; Enlace Github: https://github.com/men18023/Lab_Micros/tree/main/Proyecto1
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

MODO    EQU 0		; nombre para los pushbuttons
UP      EQU 1
DOWN    EQU 2

reinicio_tmr0 macro	; macro para reinicio del timer0
    banksel PORTA
    movlw   255		; valor de inicio para el timer0
    movwf   TMR0	; se mueve a nuestro TMR0
    bcf	    T0IF
    endm
  
reinicio_tmr1 macro
    banksel TMR1H	
    movlw   225		;valores iniciales en el tmr1
    movwf   TMR1H
    movlw   124
    movwf   TMR1L
    bcf	    TMR1IF
    endm

PSECT udata_bank0  ;common memory
    contador:	 DS 1	    ; variables utilizadas
    cont1:	 DS 1	    ; el # a la par de DS es la cantidad de bytes
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
    STATUS_temp: DS 1

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
    btfsc   RBIF	    ; revisar interrupcion en el puerto B
    call    int_PB	    ; llamada a subrutina de pushbuttons
    btfsc   T0IF	    ; revisar interrupcion en el timer0
    call    int_TMR0	    ; llamada a subrutina de timer0
    btfsc   TMR1IF	    ; revisar interrupcion en timer1
    call    int_TMR1	    ; llamada a subrutina de timer1
   
pop:
    swapf   STATUS_temp, W
    movwf   STATUS
    swapf   W_temp, F
    swapf   W_temp, W
    retfie
;----------------------sub rutinas de int--------------;
    
int_PB:
    banksel PORTB	    ; se coloca en puerto B
    btfss   PORTB, UP	    ; se revisa si se presiona el PB UP
    incf    carga, F	    ; se incrementa el valor en la variable
    movlw   21		    ; se mueve 21 a W
    subwf   carga, W	    ; se compara el valor y poder hacer el limite
    btfsc   ZERO
    goto    min		    ; llamada a limite inferior
    
    btfss   PORTB, DOWN	    ; se revisa si se presiona el PB DOWN
    decf    carga, F	    ; se decrement ael valor en la variable
    movlw   9		    ; mueve 9 a W
    subwf   carga, W	    ; se compara el valor y poder hacer el limite
    btfsc   ZERO	    ; revisa el ZERO
    goto    max		    ; llamada a nuestro limite superior
    bcf	    RBIF
    
    btfss   PORTB, MODO	    ; se revisa si se presiona el PB MODO
    incf    estado	    ; se incremente la variable de estado
    movlw   6		    ; mueve 6 a W
    subwf   estado, W	    ; comparacion para que estado no pase de 6
    btfss   ZERO	
    goto    $+3		    
    movlw   2
    movwf   estado
    return
  
min:
    movlw   10		; se mueve 10 a varaiable carga
    movwf   carga
    bcf	    RBIF	; se reinicia el interrupt
    return
max:
    movlw   20		; se mueve 20 a variable carga
    movwf   carga   
    bcf	    RBIF	; se reinicia el interrupt
    return

int_TMR0:		    ;subrutina de interrupcion del tmr0
    reinicio_tmr0           
    clrf    PORTA
    
    btfsc   banderas, 0	    ; se prueba la bandera de cada display
    goto    display1	    ; va al display siguiente
    
    btfsc   banderas, 1	    
    goto    display2
    
    btfsc   banderas, 2	   
    goto    display3
    
    btfsc   banderas, 3	    
    goto    display4
    
    btfsc   banderas, 4	    
    goto    display5
    
    btfsc   banderas, 5
    goto    display6
    
    btfsc   banderas, 6
    goto    display7
   
display0:			
    movf    display_var+1, W	;se elige el byte de la variable
    movwf   PORTC		;lugar donde esta el 7seg
    bsf	    PORTA, 0		;transistor que se desea activar
    goto    siguiente_0		;llamada a instruccion siguiente
    
display1:
    movf    display_var, W	
    movwf   PORTC		
    bsf	    PORTA, 1		
    goto    siguiente_1

display2:
    movf    display_var+3, W	
    movwf   PORTC		
    bsf	    PORTA, 2		
    goto    siguiente_2
    
display3:
    movf    display_var+2, W	
    movwf   PORTC		
    bsf	    PORTA, 3		
    goto    siguiente_3

display4:
    movf    display_var+5, W	
    movwf   PORTC		
    bsf	    PORTA, 4		
    goto    siguiente_4

display5:
    movf    display_var+4, W	
    movwf   PORTC		
    bsf	    PORTA, 5		
    goto    siguiente_5
    
display6:
    movf    display_var+7, W	
    movwf   PORTC		
    bsf	    PORTA, 6		
    goto    siguiente6
    
display7:
    movf    display_var+6, W	
    movwf   PORTC		
    bsf	    PORTA, 7		
    goto    siguiente7
    
siguiente_0:		    ; Intruccion de rotacion de displays 
    movlw   00000001B	    ; se mueve valor a W
    xorwf   banderas, 1	    ; XOR para hacer la rotacion
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
    reinicio_tmr1	    ; reincio del timer1 
    incf    contador	    ; se incrementa la variable
    movwf   contador, W	    ; se mueve a W
    sublw   1		    ; se hace el decremento en el contador
    btfss   ZERO	    ; se prueba ZERO esta apagado
    goto    return_tm1	    
    clrf    contador	    ; limpia el contador
    incf    tiempo	    ; incrementa variable tiempo
    
    btfss   sust, 0	    ; revisa bandera de cada contador
    decf    check1	    ; decrementa seguro de cada contador
    btfsc   ZERO	    ; revisa el ZERO
    bsf	    sust, 0	    ; enciende la bandera
    
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
    banksel ANSEL	    ; bank de ANSEL
    clrf    ANSEL	    ; se limpian puerto digitales
    clrf    ANSELH
    
    banksel TRISA	    ; bank de TRISA
    movlw   00000000B	    ; TRISA como salidas para transistores
    movwf   TRISA
    movlw   00000000B	    ; TRISC como salidas para 7 seg
    movwf   TRISC
    movlw   00000000B	    ; TRISD y TRISE salidas para semaforos
    movwf   TRISD
    movlw   00000000B
    movwf   TRISE
    clrf    TRISB	    ; salidas en todo TRISB	
    bsf	    TRISB, UP	    ; se habilitan los PB como entradas del TRISB
    bsf	    TRISB, DOWN
    bsf	    TRISB, MODO
    

    bcf	    OPTION_REG, 7   ;habilito pull-up
    bsf	    WPUB, UP	    ;selecciono pines
    bsf	    WPUB, DOWN
    bsf	    WPUB, MODO

    call    reloj	    ;llamada a config del reloj
    call    timer0	    ;llamada a config del timer0
    call    timer1	    ;llamada a config del timer1
    call    config_ioc	    ;llamada a config de pull-ups
    call    int_enable	    ;llamada a config de interrupciones
    call    config_inicial  ;config inicial del sistema de semaforos
    
    banksel PORTA	    ;se limpian todas las variables y puertos a utilizar
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

;-----------------------------------loop---------------------------------------;
 
loop:
    call    empezar		;subrutina de inicio automatico
    call    config_semaforos	;subrutina de configuracion manual de semaforo
    
    goto    loop		;seguir en el loop
    
;------------------------------------------------------------------------------;
;-----------------------------subrutinas generales-----------------------------; 
;------------------------------------------------------------------------------;
    
reloj:
    banksel OSCCON
    bcf	    IRCF2   ;250 KHz = 010
    bsf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS	    ;reloj interno 
    return
 
config_ioc:
    banksel TRISB	
    bsf	    IOCB, UP	  ;se enciende el pull-up en cada PB
    bsf	    IOCB, DOWN
    bsf	    IOCB, MODO
    
    banksel PORTA
    movf    PORTB, W	
    bcf	    RBIF
    return
 
int_enable:
    bsf	    GIE	    ;interrupciones globales
    bsf	    T0IE    ;interrupcion de timer0
    bcf	    T0IF
    
    bsf	    TMR1IE  ;interrupcion de timer1
    bcf	    TMR1IF
    
    bsf	    RBIE    ;interrupcion de PORTB
    bcf	    RBIF
    return
    
timer0:
    banksel TRISA
    bcf	    T0CS     ;reloj interno
    bcf	    PSA	     ;prescaler
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0      ; PS = 111   rate 1:256
    banksel PORTA
    reinicio_tmr0    ;se reinicia el timer0
    return   
    
timer1:
    banksel T1CON     
    bsf	    T1CKPS1  ;prescaler de 11   rate 1:8
    bsf	    T1CKPS0
    bcf	    TMR1CS   ;reloj interno
    bsf	    TMR1ON   ;se activa timer1
    reinicio_tmr1
    return    

config_inicial:
    movlw   10		;se mueve 10 a W
    movwf   cont1	;se asigna como valor inicial para displays de semaforos
    movwf   cont2
    movwf   cont3
    movf    cont1, W
    movwf   check1
    movf    cont2, W
    movwf   check2
    movf    cont3, W
    movwf   check3
    movlw   1		;se inicia en el estado 1
    movwf   estado
    movlw   10
    movwf   carga	;valor inicial para el display de configuracion de sem
    movlw   11111110B
    movwf   sust	;valor incicial para nuestro variable
    return
    
;------------------------------------------------------------------------------;
;-----------------subrutinas de funcionamiento de semaforos--------------------; 
;------------------------------------------------------------------------------; 
    
empezar:    
    movf    check1, W	    ;se mueve el valor configurado a W	
    movwf   unidad1	    ;mueve W a variable para utilizar en division
    call    division1	    ;llamada a division1 
    call    prep_display1   ;llama a su respectiva preparacion del display
    
    movf    check2, W
    movwf   unidad2
    call    division2
    call    prep_display2
    
    movf    check3, W
    movwf   unidad3
    call    division3
    call    prep_display3
    
    btfss   tipo_sem, 0	    ;prueba para inciar funcionamiento normal del sem
    call    fun_normal	    ;llamada a subrutina de funcionamiento norm
    return
    
fun_normal:
    btfss   modo_sem, 0	    ;semaforo 1 en verde
    call    verde1	
    btfsc   modo_sem, 1	    ;semaforo 1 en amarillo
    call    amarillo1		
    btfsc   modo_sem, 2	    ;semaforo 2 en verde
    call    verde2	
    btfsc   modo_sem, 3	    ;semaforo 2 en amarillo
    call    amarillo2	
    btfsc   modo_sem, 4	    ;semaforo 3 en verde
    call    verde3	
    btfsc   modo_sem, 5	    ;semaforo 3 en amarillo
    call    amarillo3	
    return
    
config_semaforos:	    ;subrutina para cambiar valor en contador de sem
    movlw   2		    ;mueve 2 a W
    subwf   estado, W	    ;compara el valor de W y el estado actual
    btfsc   ZERO	
    call    cambio_S1	    ;llama configuracion del primer semaforo
    
    movlw   3		    ;mueve 3 a W
    subwf   estado, W
    btfsc   ZERO
    call    cambio_S2	
    
    movlw   4		    ;mueve 4 a W
    subwf   estado, W
    btfsc   ZERO
    call    cambio_S3	
    
    movlw   5		    ;mueve 5 a W
    subwf   estado, W
    btfsc   ZERO
    call    confirmacion    ;subrutina de confirmacion de configuracion de sem
    return
    
verde1:
    movlw   00000100B	;semaforo 1 en verde
    movwf   PORTE
    movlw   00001001B	;semaforo 2 y 3 en rojo
    movwf   PORTD
    movwf   tiempo, W
    addlw   5		;valor para iniciar el parpapedo
    subwf   cont1, W
    btfsc   ZERO	
    call    parpadeo1	;instruccion de parpadeo
    return
    
amarillo1:
    movlw   00000010B	;semaforo 1 en amarillo
    movwf   PORTE
    movlw   00001001B	;semaforo 2 y 3 en rojo
    movwf   PORTD   
    movlw   3		;valor para iniciar amarillo
    subwf   tiempo, W	;compara valor de tiempo con W
    btfsc   ZERO
    call    rojo1	;llama instruccion de rojo en sem1
    return
    
rojo1:
    bcf	    modo_sem, 1	;configuracion de banderas para siguiente semaforo
    bsf	    modo_sem, 2
    movf    cont2, W	;se mueve valor del contador al siguiente semaforo
    movwf   check2, F
    movlw   253		;se activa el contador del siguiente semaforo
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
    btfsc   ZERO	
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
    
parpadeo1:
    bcf	    PORTE, 2	;apaga led
    call    delay	;tiempo apagado
    bsf	    PORTE, 2	;enciende led
    call    delay	;tiempo encendido
    bcf	    PORTE, 2
    call    delay
    bsf	    PORTE, 2
    call    delay
    bcf	    PORTE, 2
    call    delay
    bsf	    PORTE, 2
    call    delay
    bcf	    PORTE, 2	;deja verde apagado para seguir en amarillo1
    bsf	    modo_sem, 0	;activa banderas de amarillo1 y apaga bandera de verde1
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
    movlw   198		    ;delay utilizado para cada parpadeo
    movwf   cont_big	    
    call    delay2	   
    decfsz  cont_big, 1	   
    goto    $-2		   
    return
    
delay2:
    movlw   30		    
    movwf   cont_small
    decfsz  cont_small, 1   
    goto    $-1		    
    return
    
;------------------------------------------------------------------------------;
;---------------------------subrutinas de proceso------------------------------; 
;------------------------------------------------------------------------------;
    
division1:	    
    clrf    decena	    ;se limpia la variable
    movlw   10		    ;valor de 10 a W
    subwf   unidad1, F	    ;a unidad del primer semaforo se le resta W
    btfsc   CARRY	    ;se revisa si tiene algo
    incf    decena	    ;se incrementa decena lo que sea necesario
    btfsc   CARRY   
    goto    $-5		    
    movlw   10		    ;se agrega el valor a nuestra variable de unidad
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

    
;------------------------------------------------------------------------------;
;-----------------------subrutinas de config de semaforo------------------------; 
;------------------------------------------------------------------------------;
    
confirmar:
    decf    carga	    ;decrementa el valor en display de config
    movf    c1_temp, W	    ;se mueven los nuevos valores a cada contador
    movwf   cont1, F
    movwf   check1
    movf    c2_temp, W
    movwf   cont2, F
    movwf   check2
    movf    c3_temp, W
    movwf   cont3, F
    movwf   check3
    movlw   00000001B	    ;se reinicia el funcionamiento 
    movwf   estado
    bcf	    tipo_sem, 0	    ;se apaga la bandera   
    movlw   0000110B	    ;valor para bandera
    movwf   sust
    clrf    modo_sem	    ;se limpian las variables, leds y displays de config
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
	
cambio_S1:
    bsf	    PORTB, 3	    ;encender el led del semaforo a editar
    bcf	    PORTB, 4
    bcf	    PORTB, 5
    movf    carga, W	    ;mover el valor de carga del display a W
    movwf   c1_temp	    ;mover W a nuestro valor temporal
    movf    c1_temp, W	    ;mover esta variable temporal a W
    movwf   unidad1	    ;moverla a nuestras unidades para operacion
    movwf   unidad4
    call    division1	    ;divisiones para los displays 
    call    division4
    call    prep_display4   ;mostrar nuestro valor en display de config
    clrf    unidad4	    ;vaciar nuestro display
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
    bsf	    tipo_sem, 0	    ;se inicia nuestro funcionamiento
    bsf	    PORTB, 3	    ;se enciende los tres leds de config
    bsf	    PORTB, 4	    ;para mostrar si acepta o rechaza la config actual
    bsf	    PORTB, 5
    movlw   000111111B	    ; Enciendo toda las luces de los semaforos
    movwf   PORTD	    ;para notificar que se reinicia 
    movlw   000000111B
    movwf   PORTE
    btfss   PORTB, UP	    ;se prueba si se preciona PB
    call    confirmar	    ;se llama nuestra funcion de confirmar
    btfss   PORTB, DOWN	    ;se prueba si se presiona PB
    call    rechazar	    ;se llama nuestra funcion de rechazar
    return

END

