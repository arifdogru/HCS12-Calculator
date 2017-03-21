;*****************************************************************
;* Created by Arif Dogru 141044014 19.03.2017                    *
;* This program parses the given expression and calculates result*
;* Result keeps the $1500 memory adress                          *
;* Warns if overflow occurs by writing $FF to PORTB              *
;* Otherwise wrtie $55 to PORTB                                  *
;*****************************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data
INPUT       EQU  $1200  ; given string address
FIRST       EQU  $1600  ; integer part of the first number
SECOND      EQU  $1800  ; integer part of the second number
FIRSTHALF   EQU  $1650  ; decimal part of the first number
SECONDHALF  EQU  $1850  ; decimal part of the second number
TEMP        EQU  $2200  ; temp for multiply 10
COUNT       EQU  $2500  ; count 
TEN         EQU  $2550  ; ten 
RESULT      EQU  $1500  ; absolute address to place result of expression
OPERATOR    EQU  $3000  ; operation (+,-)
; variable/data section

            ORG INPUT
 ;Inser string data
            FCC "20.20 - 4.50=" ;decimal parts of integer must be to digit (.00 or .??)

            ORG COUNT
            DC.B 9
            
            ORG TEMP
            DC.B 0
            
            ORG TEN
            DC.B 10

; code section
            ORG   ROMStart

            
_Startup
Entry:
            
            LDX #INPUT            ;first input load x registor
           
MainLoop:       

            CLRA                  ;clear accumulator A
            LDAA X                ;load first character of INPUT
            INX                   ;increas pointer of INPUT
            
            CMPA #$2B             ;compare for operator plus (+)
            BEQ PLUS              ;branch if plus 
            
            CMPA #$2D             ;compare for operator minus (-)
            LBEQ MINUS            ;branch if minus
            
            CMPA #$20             ;compare for " " or space character
            BEQ MainLoop
            
            CMPA #$3D             ;compare for operator "="
            LBEQ RESULTING        ;branch if need to result
            
            CMPA #$2E             ;compare for "." decimal part
            LBEQ DECIMALPART      ;branch if decimal part
            
            
            SUBA #$30             ; otherwise character is number
            
            LDY #TEMP             ;temp starts at 0 for multiply
            
            JSR CARPI_10          ;call subroutine for multiply 10 time 
            
            STAA TEMP
            LDAB #10
            STAB COUNT
             
            STAA FIRST            ;store first memory address 
            
            JMP MainLoop          ;then return other character
  

MINUS:
            LDAA #0               
            STAA TEMP
            
            CLRA
            LDAA #$2D             ;if character is plus store the "+" to OPERATOR address
            STAA OPERATOR
            
            CLRA
            LDAA #10
            STAA COUNT
    Loop3:                   
                               
            CLRA
            LDAA X
            INX
            
            CMPA #$3D             ;compare character "=" or not
            LBEQ RESULTING  
     
            CMPA #$2E             ;compare character "." or not
            LBEQ DECIMALPART2                   
            
            CMPA #$20             ;return begining loop3 if character is " " space
            LBEQ Loop2
            
            SUBA #$30             ;otherwise character is digit
            
            
            LDY #TEMP             ;then other character control
            
            JSR CARPI_10
            
            STAA TEMP
            LDAB #10
            STAB COUNT
             
            STAA SECOND
            
            
            JMP Loop3


PLUS: 

            LDAA #0
            STAA TEMP
            
            CLRA
            LDAA #$2B             ;compare for operator plus (+)
            STAA OPERATOR         ;branch if plus
            
            CLRA
            LDAA #10
            STAA COUNT
    Loop2:                      
                                     
            CLRA
            LDAA X
            INX
            
            CMPA #$3D
            BEQ RESULTING  
     
            CMPA #$2E             ;compare character "." or not
            BEQ DECIMALPART2      ;branch the decimal part
            
            CMPA #$20             ;return begining loop3 if character is " " space
            BEQ Loop2
            
            SUBA #$30             ;otherwise character is digit
            
            
            LDY #TEMP 
            
            JSR CARPI_10
            
            STAA TEMP
            LDAB #10
            STAB COUNT
             
            STAA SECOND
            
            
            JMP Loop2 

            
DECIMALPART:                    ; Decimal part operaions
            
            LDAB #9             ; read first digit
            STAB COUNT
            
            CLRA
            LDAA X
            SUBA #$30
            STAA TEN
            LDY  #TEN
            
            JSR CARPI_10        ; multiply 10 for digit value
            
            STAA TEMP
            LDAB TEMP
            
            INX                 ;read second digit
            CLRA
            LDAA X
            SUBA #$30
            ABA 
            STAA FIRSTHALF      ;store first decimal part 
            
            INX
            JMP MainLoop        ;then jump main loop for other characters

DECIMALPART2:
            
            LDAB #9             ; Second number decimal part operations
            STAB COUNT          
           
            CLRA
            LDAA X              ; read first digit
            
            SUBA #$30
            
            STAA TEN
            LDY  #TEN
            
            JSR CARPI_10         ; multiply 10 for digit value
            
            STAA TEMP
            LDAB TEMP
            
            INX
            CLRA
            LDAA X               ;read second digit
            SUBA #$30
            ABA 
            STAA SECONDHALF      ;store second decimal part
            
            INX
            JMP MainLoop 
            

CARPI_10:                      ;subroutine for multiply 10

  CARPLOOP:
            ADDA Y
            DEC COUNT
            BNE CARPLOOP 
                     
            RTS                                  

RESULTING:                       ;calculates result label
                  
            CLRA
            LDAA OPERATOR
            CMPA #$2B            ;check operator +
            BEQ ADD              ;branch if add label
            
            CMPA #$2D            ;check operator -
            BEQ SUBSTRACT        ;branch if substract label

ADD:
            LDAA FIRSTHALF       ;get decimal part of first number
            ADDA SECONDHALF      ;add decimal part of second number to first decimal
            SUBA #100
            BPL  HELPERPLUS      ;if carry set branch helper
            CLRB
            LDAB FIRST           ;get first integer part of first number
            ADDB SECOND          ;add integer part of second number to first integer
            BCS  OVERFLOW        ;branch if there is overflow
            STAB RESULT          ;store result to $1500 address
            
            CLRA                 ;result store to portb
            LDAA #$FF
            STAA DDRB
            CLRA
            LDAA #$55
            STAA PORTB
                
            JMP ENDOF
HELPERPLUS:
            CLRA 
            LDAA FIRST           ;get first integer part of first number
            ADDA SECOND          ;add integer part of second number to first integer
            BCS OVERFLOW         ;branch if there is overflow
            ADDA #1              ;add 1 to integer part for carry out
            BCS OVERFLOW         ;branch if there is overflow
            STAA RESULT          ;store result to $1500 address
            
            CLRB
            LDAB #$FF
            STAB DDRB
            CLRA
            LDAA #$55
            STAA PORTB           ;result store to portb
            
            JMP ENDOF            ;end

SUBSTRACT:
            LDAA FIRSTHALF        ;get decimal part of first number
            SUBA SECONDHALF       ;substract decimal part of second number to first decimal
            BMI  HELPERMINUS      ;if carry set branch helper 
            CLRB
            LDAB FIRST            ;get first integer part of first number
            SUBB SECOND           ;substract integer part of second number to first integer
            BCS  OVERFLOW         ;branch if there is overflow
            STAB RESULT           ;store result to $1500 address
            
            CLRB
            LDAB #$FF
            STAB DDRB
            CLRA
            LDAA #$55
            STAA PORTB            ;result store to portb
            
            JMP ENDOF             ;end
                          
HELPERMINUS:
            CLRA
            LDAA FIRST            ;get first integer part of first number
            SUBA SECOND           ;subsinteger part of second number to first integer
            BCS OVERFLOW          ;branch if there is overflow
            SUBA #1               ;sub 1 to integer part for carry out
            
            STAA RESULT
            
            CLRB
            LDAB #$FF
            STAB DDRB
            CLRA
            LDAA #$55            
            STAA PORTB            ;result store to portb
            
            JMP ENDOF             ;end
OVERFLOW:
            CLRA                  ;any overflow occures store to portb FF
            LDAA #$FF
            STAA DDRB            
            STAA PORTB
            
ENDOF:
                        
            
            
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
