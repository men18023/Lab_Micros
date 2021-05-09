/* Laboratorio 10 - UART
 * File:   main10casa.c
 * Author: Jonathan Menendez, 18023
 * Enlace Video: https://youtu.be/3Mu6_7lo438
 * Enlace Github: https://github.com/men18023/Lab_Micros/tree/main/LAB10
 * Created on 5 de mayo de 2021, 11:25 AM
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

#define _XTAL_FREQ 8000000
#include <xc.h>
#include <stdint.h>
#include <stdio.h>  // para usar el printf

//Variables utilizadas

void config(void); // config de puertos
void texto(void);
void putch(char data);


void main(void) {   //instrucciones del main
    config();       //se llama a la configuracion general
    while(1){
        texto();
    }
}

void config(void){
    //PUERTOS DIGITALES
    ANSEL = 0x00;
    ANSELH = 0x00;
    //CONFIG I/O
    TRISA = 0x00; //se colocan los puertos como salidas 
    TRISB = 0x00;
    //se limpian los puertos
    PORTA = 0x00;
    PORTB = 0x00;
    //CONFIG RELOJ INTERNO
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;   //8 MHz
    OSCCONbits.SCS = 1;
    //CONFIG INTERRUPTS
    //INTCONbits.GIE = 1;
    //INTCONbits.PEIE = 1;
    //PIE1bits.TXIE = 1;
    //PIE1bits.RCIE = 1;
    // UART TX y RX
    TXSTAbits.SYNC = 0;
    TXSTAbits.BRGH = 1;
    BAUDCTLbits.BRG16 = 1;
    
    SPBRG = 208;
    SPBRGH = 0;
    
    RCSTAbits.SPEN = 1;
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;
    
    TXSTAbits.TXEN = 1;
    
    PIR1bits.RCIF = 0;
    PIR1bits.TXIF = 0;
}

void texto(void){
    __delay_ms(250); //Tiempo de delay
    printf("\r Eliga que accion desea ejecutar: \r");
    __delay_ms(250);
    printf(" 1. Desplegar cadena de caracteres \r");
    __delay_ms(250);
    printf(" 2. Cambiar PORTA \r");
    __delay_ms(250);
    printf(" 3. Cambiar PORTB \r");
    while (RCIF == 0);  // Avance a cada opcion
    if (RCREG == '1'){  // Opcion 1
        __delay_ms(500);
        printf("\r Cargando la cadena de caracteres...... \r");
    }
    if (RCREG == '2'){  //Opcion 2
        printf("\r Seleccionar el caracter a desplegar en PORTA: \r");
        while (RCIF == 0);
        PORTA = RCREG; //ingresar caracter
    }
    if (RCREG == '3'){ //Opcion 3
        printf("\r Seleccionar el caracter a desplegar en PORTB: \r");
        while (RCIF == 0);
        PORTB = RCREG; //ingresar caracter
    }
    else{ //para cuando no se ingresa algunas de las opciones posibles
        NULL;    
    }
    return;
}

void putch(char data){      // Funcion de stdio.h
    while(TXIF == 0);
    TXREG = data; // valor que se muestra
    return;
}