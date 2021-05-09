/* Laboratorio 10 - UART
 * File:   main10lab.c
 * Author: Jonathan Menendez, 18023
 * Enlace Video:
 * Enlace Github: 
 * Created on 5 de mayo de 2021, 10:10 AM
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

//Variables utilizadas
const char variable = 45;    // variable de cambio canal

void config(void); // config de puertos


void __interrupt() isr(void){ 
    
    if(PIR1bits.RCIF == 1){
        PORTB = RCREG;
    }
    if (PIR1bits.TXIF == 1){
        TXREG = variable;
    }
    __delay_us(100);
}

void main(void) {   //se pone el main
    config();       //se llama a la configuracion del TMR0 e interrupciones
    //ADCON0bits.GO = 1;
    while(1){
    }
        //se pone la division en el loop
    }

void config(void){
    //PUERTOS DIGITALES
    ANSEL = 0x00;
    ANSELH = 0x00;
    //CONFIG I/O
    TRISB = 0x00;
    TRISD = 0x00;
    //se colocan los puertos como salidas 
    //TRISD = 0x00; 
    //TRISE = 0x00;
    //SE LIMPIAN LOS PUERTOS
    PORTB = 0x00;
    PORTD = 0x00;
    //CONFIG RELOJ INTERNO
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;   //8 MHz
    OSCCONbits.SCS = 1;
    //CONFIG INTERRUPTS
    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;
    PIE1bits.TXIE = 1;
    PIE1bits.RCIE = 1;
    // UART TX y RX
    TXSTAbits.SYNC = 0;
    TXSTAbits.BRGH = 1;
    BAUDCTLbits.BRG16 = 1;
    
    SPBRG = 207;
    SPBRGH = 0;
    
    RCSTAbits.SPEN = 1;
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;
    
    TXSTAbits.TXEN = 1;
    
    PIR1bits.RCIF = 0;
    PIR1bits.TXIF = 0;
}
