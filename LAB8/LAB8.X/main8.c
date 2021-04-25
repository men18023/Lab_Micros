/* Laboratorio 8 - Módulo ADC
 * File:   main7.c
 * Author: Jonathan Menendez, 18023
 * Enlace Video:
 * Enlace Github: 
 * Created on 21 de abril de 2021, 11:10 AM
 */

//CONFIG 1
#pragma config FOSC = INTRC_NOCLKOUT        // Oscillator Selection bits (LP oscillator: Low-power crystal on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = ON       // Power-up Timer Enable bit (PWRT enabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF          // Code Protection bit (Program memory code protection is enabled)
#pragma config CPD = OFF         // Data Code Protection bit (Data memory code protection is enabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 2.1V)
#pragma config WRT = OFF       // Flash Program Memory Self Write Enable bits (0000h to 0FFFh write protected, 1000h to 1FFFh may be modified by EECON control)

#define _XTAL_FREQ 4000000
#include <xc.h>
#include <stdint.h>

//Variables utilizadas
char cambio;    // variable de cambio canal
char valor;     // variable para division 7seg
int  multi;     // variable del multiplexado de displays
char centena;   // variable para display centena
char decena;    // variable para display decena
char unidad;    // variable para display unidad y se usa como residuo del resto

char display[10] = {0b00111111,0b00000110,0b01011011,0b01001111,0b01100110,
0b01101101,0b01111101,0b00000111,0b01111111,0b01101111}; 

void config(void); // config de ouertos
char division(void); //funcion de division

void __interrupt() isr(void){ 
    if (T0IF == 1) // Interrupcion por la bandera del timer0
    {   
        PORTEbits.RE2 = 0;  //Display de unidad apagado
        PORTEbits.RE0 = 1;  //Display de centena encendido
        PORTD = (display[centena]); //Se muestra valor en centena
        multi = 0b00000001;  //cambio de valor en bandera                      
        
        if (multi == 0b00000001) //se prueba bandera de display
        {                         
            PORTEbits.RE0 = 0;  //Display de centena apagado
            PORTEbits.RE1 = 1;  //Display de decena encendido
            PORTD = (display[decena]); //Se muestra valor de decena   
            multi = 0b00000010; //cambio de valor en bandera
        }        
        if (multi == 0b00000010)    //se prueba bandera de display
        {                             
            PORTEbits.RE1 = 0;  //Display de decena apagado
            PORTEbits.RE2 = 1;  //Display de unidad apagado
            PORTD = (display[unidad]);  //Se muestra el valor de unidad
            multi = 0x00; //se reinicia la bandera
        }
        INTCONbits.T0IF = 0;  
        TMR0 = 255;  //valor inicial del tmr0}
    // interrupcion de ADC
    if(PIR1bits.ADIF == 1){
        if(ADCON0bits.CHS == 0)
            PORTC = ADRESH;
        
        else
            valor = ADRESH;
            
        PIR1bits.ADIF = 0;
        }
    }
}

void main(void) {   //se pone el main
    config();       //se llama a la configuracion del TMR0 e interrupciones
    ADCON0bits.GO = 1;
    while(1){
        
        if (ADCON0bits.GO == 0){
            if (ADCON0bits.CHS == 1){
                ADCON0bits.CHS = 0;}
            else{
                ADCON0bits.CHS = 1;}
            __delay_us(100);
            ADCON0bits.GO = 1;
        }
        division();
    }
        //se pone la division en el loop
    }

void config(void){
    //PUERTOS DIGITALES
    ANSEL = 0b00000011;
    ANSELH = 0b11111111;
    //CONFIG I/O
    TRISA = 0b00000011; //pines del TRISA para entradas de PB
    //se colocan los puertos como salidas
    TRISC = 0x00;   
    TRISD = 0x00; 
    TRISE = 0x00;
    //SE LIMPIAN LOS PUERTOS
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
    //CONFIG RELOJ INTERNO
    OSCCONbits.IRCF2 = 0;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;   //250kHz
    OSCCONbits.SCS = 1;
    //CONFIG TIMER0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1;  // Prescaler 111   1:256
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;
    //CONFIG INTERRUPTS
    INTCONbits.GIE = 1;
    INTCONbits.T0IE = 1;    //interrupciones del TMR0
    INTCONbits.T0IF = 0;
    INTCONbits.PEIE = 1;
    PIE1bits.ADIE = 1;
    PIR1bits.ADIF = 0;
    // ADC
    ADCON1bits.ADFM = 0;   
    ADCON1bits.VCFG0 = 0;   
    ADCON1bits.VCFG1 = 0;
    ADCON0bits.ADCS0 = 1;  
    ADCON0bits.ADCS1 = 1;
    ADCON0bits.CHS = 0; 
    ADCON0bits.ADON = 1;    
  
}

char division(void){ //proceso de division para displays
    centena = valor/100; //centena = contador dividio 100
    unidad = valor%100;  //variable de unidad es utilizado como residuo
    decena = unidad/10; //decena = residuo(unidad) divido 10
    unidad = unidad%10; //se coloca el residuo en variable unidad para mostrar
}