/* Laboratorio 7 - Programacion en C
 * File:   main7.c
 * Author: Jonathan Menendez, 18023
 * Enlace Video: https://youtu.be/hxIIvXcpTNI
 * Enlace Github:  https://github.com/men18023/Lab_Micros/tree/main/LAB7
 * Created on 13 de abril de 2021, 11:10 AM
 */

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF       // Power-up Timer Enable bit (PWRT enabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

#include <xc.h>
//#include <stdint.h>

//Variables utilizadas

char cont;      // variable de contador
int  multi;     // variable del multiplexado de displays
char centena;   // variable para display centena
char decena;    // variable para display decena
char unidad;    // variable para display unidad y se usa como residuo del resto

char display[10] = {0b00111111,0b00000110,0b01011011,0b01001111,0b01100110,
0b01101101,0b01111101,0b00000111,0b01111111,0b01101111}; 

void setup(void);
char division(void);

//Interrupciones
void __interrupt() isr(void) {
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
        TMR0 = 255;  //valor inicial del tmr0
    }
    if (RBIF == 1)
    {
        if (PORTBbits.RB0 == 0) //Se prueba el PB de subir
        {
            PORTA = PORTA + 1;  //se aumenta el valor en contador leds
        }
        if  (PORTBbits.RB1 == 0) //se prueba el PB de bajar
        {
            PORTA = PORTA - 1;  //se disminuye el valor en contador leds
        }
        INTCONbits.RBIF = 0;
    }
}

void main(void) {
    setup();
    while(1)
    {
        cont= PORTA; //se asigna el valor del contador de leds a variable
        division();  //llamada a division para displays
    }
}

//Configuraciones

void setup(void){
    //PUERTOS DIGITALES
    ANSEL = 0x00;
    ANSELH = 0x00;
    //CONFIG I/O
    TRISBbits.TRISB0 = 1; //pines del TRISB para entradas de PB
    TRISBbits.TRISB1 = 1;
    TRISA = 0x00;   //se colocan los puertos como salidas
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
    INTCONbits.RBIE = 1;    //interrupcion del puerto B
    INTCONbits.RBIF = 0;
    INTCONbits.T0IE = 1;    //interrupciones del TMR0
    INTCONbits.T0IF = 0;
    //CONFIG PULL-UPS
    OPTION_REGbits.nRBPU = 0;
    WPUB = 0b00000011;
    IOCBbits.IOCB0 = 1;     //pull-ups para pines en puerto B
    IOCBbits.IOCB1 = 1;
  
}

char division(void){ //proceso de division para displays
    centena = cont/100; //centena = contador dividio 100
    unidad = cont%100;  //variable de unidad es utilizado como residuo
    decena = unidad/10; //decena = residuo(unidad) divido 10
    unidad = unidad%10; //se coloca el residuo en variable unidad para mostrar
}
