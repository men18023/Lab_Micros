/* Proyecto 2
 * File:   mainP2.c
 * Author: Jonathan Menendez, 18023
 * Enlace Video: 
 * Enlace Github: https://github.com/men18023/Lab_Micros/tree/main/Proyecto2/Commit%20Final
 * Created on 21 de mayo de 2021, 09:02 AM
 */

//-------------------------- Bits de configuraciÓn -----------------------------
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
#include <stdint.h>
#include <stdio.h>
#include <xc.h>

//VARIABLES
char valor;
char dato;
char localidad;
char lec1;
char lec2; 
char lec3;
char lec4; 
char lec5;
char lec_pwm1;
char lec_pwm2;

//PROTOTIPOS
void config(void); //llamada funcion de config
void bitb1(void);  //funciones para el bitbanging
void bitb2(void);
void bitb3(void);
void putch(char data);
void text(void);
void write_eeprom(char dato, char localidad);
char read_eeprom(char localidad);

//INTERRUPCIONES
void __interrupt() isr(void){ //funcion especial de int
    
    if(PIR1bits.ADIF == 1){
        if(ADCON0bits.CHS == 0){
            CCPR1L = (ADRESH >> 1) + 124;
        }    
        else if(ADCON0bits.CHS == 1){ 
            CCPR2L = (ADRESH >> 1) + 124;
        }
        else if (ADCON0bits.CHS == 2){
               valor = ADRESH;
            if (valor <= 85){
                bitb1();
                 }
           if ((valor <= 170)&&(valor >= 86)){
                bitb2();
                 }
            if (valor >= 171){
                bitb3();
                 }
        }   
           PIR1bits.ADIF = 0; 
    }
    
if (RBIF == 1){  // Bandera de puerto b
        if (PORTBbits.RB1 == 0)   //revisa PB1
        {
            PORTDbits.RD0 = 0;    
            PORTDbits.RD4 = 1;
            PORTDbits.RD5 = 1;
        }
        else if (PORTBbits.RB1 == 1) 
        {
            PORTDbits.RD0 = 1;
            PORTDbits.RD4 = 0;
            PORTDbits.RD5 = 0;
        }
        if (PORTBbits.RB2 == 0)  //revisa PB2
        {
            PORTDbits.RD1 = 0;     
            PORTDbits.RD6 = 1;
            PORTDbits.RD7 = 1;
        }
        else if (PORTBbits.RB2 == 1)
        {
            PORTDbits.RD1 = 1;
            PORTDbits.RD6 = 0;
            PORTDbits.RD7 = 0;
        } 
        INTCONbits.RBIF = 0;     // Se limpia la bandera
        
    }
 if (RCIF == 1) {
    if (RCREG == 'w'){ 
        bitb2();
        __delay_ms(500);
        printf("\r Avanzando \r");
        PORTDbits.RD0 = 1;
        PORTDbits.RD4 = 1;
        PORTDbits.RD5 = 1;
        PORTDbits.RD6 = 0;
        PORTDbits.RD7 = 0;
        printf("------------------------------------------");
        printf("\r Presione s para retroceder \r");
        printf("\r Presione a para girar a la izquierda \r");
        printf("\r Presione d para girar a la derecha \r");}
    if (RCREG == 's'){
        PORTDbits.RD0 = 1;
        PORTDbits.RD6 = 1;
        PORTDbits.RD7 = 1;
        PORTDbits.RD4 = 0;
        PORTDbits.RD5 = 0;
        printf("\r Retrocediendo \r");
        __delay_ms(100);
        printf("------------------------------------------");
        printf("\r Apache w para avanzar \r");
        printf("\r Apache a para girar a la izquierda \r");
        printf("\r Apache d para girar derecha \r");}
    if (RCREG == 'a'){
        bitb1();
        PORTDbits.RD5 = 0;
        PORTDbits.RD6 = 1;
        PORTDbits.RD4 = 1;
        PORTDbits.RD7 = 0;  
        printf("\r Girando a la izquierda \r");
        __delay_ms(300);
        printf("------------------------------------------");
        printf("\r Precione s para retroceder \r");
        printf("\r Presione a para girar a la izquierda \r");
        printf("\r Presione d para girar a la derecha \r");}
    if (RCREG == 'd'){
        bitb3();
        PORTDbits.RD5 = 1;
        PORTDbits.RD6 = 0;
        PORTDbits.RD4 = 0;
        PORTDbits.RD7 = 1; 
        printf("\r Girando a la derecha \r");
        __delay_ms(300);
        printf("------------------------------------------");         
        printf("\r Presione s para retroceder \r");
        printf("\r Presione a para girar a la izquierda \r");
        printf("\r Presione d para girar a la derecha \r");}  
    else{ 
        NULL;}  //seguridad para que el usuario no ponga otras opciones  
        }   
}
void main(void) 
{

    config();                                // Llamo a mi configuracion principal
    ADCON0bits.GO = 1;                      // Bit para que comience la conversion
    PORTDbits.RD1 = 1;
    printf("\r Presione w para avanzar \r");
    while(1)  
    {
        if (ADCON0bits.GO == 0)
        {
            if(ADCON0bits.CHS == 0){
                ADCON0bits.CHS =1;
            }
            else if (ADCON0bits.CHS == 1){
                ADCON0bits.CHS = 2;
            }
            else
                ADCON0bits.CHS = 0;
            __delay_us(50);
            ADCON0bits.GO = 1;
        }        
    }
}

void putch(char data){   //funcion de stdio.h
    while(TXIF == 0);
    TXREG = data;        //valor que se muestra
    return;
}
// Sub-rutina de configuraciones generales
void config(void){
    //PUERTOS DIGITALES
    ANSEL = 0b00000111;
    ANSELH = 0;
    //IN/OUT
    TRISA = 0x0F;
    //PUSHBUTTONS PORT B
    TRISBbits.TRISB1 = 1;
    TRISBbits.TRISB2 = 1;
    TRISBbits.TRISB3 = 1;
    TRISBbits.TRISB4 = 1;
    //SALIDA PARA SERVOS Y UART
    TRISCbits.TRISC0 = 0;
    TRISCbits.TRISC1 = 0;
    TRISCbits.TRISC2 = 0;
    TRISCbits.TRISC6 = 0;
    TRISCbits.TRISC7 = 1;
    //LEDS Y PUENTE H EN PORTD
    TRISDbits.TRISD0 = 0;
    TRISDbits.TRISD1 = 0;
    TRISDbits.TRISD4 = 0;
    TRISDbits.TRISD5 = 0;
    TRISDbits.TRISD6 = 0;
    TRISDbits.TRISD7 = 0;
    //SE LIMPIAN LOS PUERTOS
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
    //CONFIG RELOJ INTERNO
    OSCCONbits.IRCF2 = 1;
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;   //8 MHz
    OSCCONbits.SCS = 1;
    //PULL UPS PUERTO B
    OPTION_REGbits.nRBPU = 0;
    WPUB = 0b00011110;
    IOCBbits.IOCB1 = 1;
    IOCBbits.IOCB2 = 1;   
    IOCBbits.IOCB3 = 1;
    IOCBbits.IOCB4 = 1;
    //ADC  
    ADCON1bits.ADFM = 0;       // Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;      // Vref en VSS y VDD 
    ADCON1bits.VCFG1 = 0;   
    ADCON0bits.ADCS = 0b10;    //oscilador FOSC/32
    ADCON0bits.ADON = 1;       
    ADCON0bits.CHS = 0;        // Canal 0
    __delay_us(50); 
    //PWM
    TRISCbits.TRISC2 = 1;           // CCP como input
    TRISCbits.TRISC1 = 1; 
    PR2 = 249;                      // Periodo
    CCP1CONbits.P1M = 0;            // Modo de PWM
    CCP1CONbits.CCP1M = 0b1100;
    CCPR1L = 0x0f;                  // duty cycle
    CCP2CONbits.CCP2M = 0b1100;
    CCPR2L = 0x0f;
    
    CCP1CONbits.DC1B = 0;
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;
    // TMR2
    PIR1bits.TMR2IF = 0;       //apaga la bandera
    T2CONbits.T2CKPS = 0b11;   //prescaler 1:16
    T2CONbits.TMR2ON = 1;   
    while(PIR1bits.TMR2IF == 0);    
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;          
    TRISCbits.TRISC1 = 0;      
    //INTERRUPCIONES
    INTCONbits.GIE = 1;   //globales
    INTCONbits.PEIE = 1;  //perifericos
    PIE1bits.ADIE = 1;        
    PIR1bits.ADIF = 0;      
    INTCONbits.RBIF = 1;
    INTCONbits.RBIE = 1;
    //UART
    TXSTAbits.SYNC = 0;
    TXSTAbits.BRGH = 1;
    BAUDCTLbits.BRG16 = 1;
    
    SPBRG = 210;
    SPBRGH = 0;
    
    RCSTAbits.SPEN = 1;
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;
    
    TXSTAbits.TXEN = 1;
    
    PIR1bits.RCIF = 0; //bandera RX
    PIR1bits.TXIF = 0; //bandera TX
}
    
    void bitb1 (void)
    {
        PORTCbits.RC0 = 1;
        __delay_ms(1);
        PORTCbits.RC0 = 0;
        __delay_ms(19);
    }
    
    void bitb2 (void)
    {
        PORTCbits.RC0 = 1;
        __delay_ms(1.5);
        PORTCbits.RC0 = 0;
        __delay_ms(18.5);
    }

    void bitb3 (void)
    {
        PORTCbits.RC0 = 1;
        __delay_ms(2);
        PORTCbits.RC0 = 0;
        __delay_ms(18);
    }
    
    // Rutina de lectura para el EEPROM
    void write_eeprom (char dato, char localidad){
    EEADR = localidad;      // Lugar donde guarda el dato
    EEDAT = dato;           // Dato por guardar
    
    INTCONbits.GIE = 0;     
    EECON1bits.EEPGD = 0;   // DATA memory
    EECON1bits.WREN = 1;    // Habilita escritura
    EECON2 = 0x55;          
    EECON2 = 0xAA;          
    EECON1bits.WR = 1;      //Inicia la escritura
    
    while(PIR2bits.EEIF == 0);//Hasta que termine
    PIR2bits.EEIF = 0;
    EECON1bits.WREN = 0;    // revisa si se escribe
    }
    
    char read_eeprom (char localidad){
    EEADR = localidad;      // se lee
    EECON1bits.EEPGD = 0;   // Busca en el PM
    EECON1bits.RD = 1;      // Modo de lectura
    char dato = EEDATA;     // Pasa dato a la variable
    return dato;            // Operacion a la variale
}
