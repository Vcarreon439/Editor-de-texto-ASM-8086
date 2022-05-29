.MODEL SMALL
.DATA
    matrix      db 80*25 dup(?),'$' ;25 lineas de 80 caracteres cada una
    matrix_2    db 22 dup(?)        ;   
    row         db 2                ;para navegar columnas/caracteres con las flechas
    column      db 0                ;para navegar por las filas con las flechas
    curr_line   db 2                ;filas/lineas mientras se edita
    curr_char   db 0                ;columnas/caracteres mientras se edita
    
    ;Para el menu principal
    
    Titulo      db ' Editor de Texto $'
    deco1       db '**************************************************$'
    deco2       db '*                                                *$'

    CNTRLS1     db 'ESC = Salir || CTRL+S = Guardar$'
    CNTRLS2     db 'ARROW KEYS = Navigate$'
    
    INFO1     db 'Carreon Pulido Victor Hugo - 192310436$'
    INFO2     db 'Instituto Tecnologico Superior de Lerdo$'
    
    OPC1     db '1.-Crear Archivo$'
    OPC2     db '2.-Abrir Archivo$'
    OPC3     db '3.-Editar Archivo$'
    OPC4     db '4.-Eliminar Archivo$'    
    OPC5     db '5.-Salir$'    
    
    opcPrompt   db 'Eliga una opcion:$'
    docPrompt   db 'Ingrese el nombre del documento (.txt): $'
    
    docName     dw 50 dup(?),'$'
    docName2     dw 50 dup(?),'$'  
    
    
    
    openPrompt  db 'Ingrese el nombre del documento: $'

    delPrompt  db 'Ingrese el nombre del documento a eliminar: $'
    MSMDEL  db 'Archivo eliminado exitosamente $'
    ERRORDEL  db 'El archivo no pudo ser eliminado $'
    
    HANDLE      dw ? 
    header      db 80 dup('='),'$'    
    color       db 3*15+15
    
          
.CODE

;=========== MACROS ===========

CONFIGURAR MACRO
    
      MOV AX,0600H  ;Limpiar pantalla... AL = 00H limpia todos los renglones
      MOV BH,5BH    ;color de fondo yletra
      MOV CX,0000H  ;esquina sup.izquierda de la pantalla(0,0)
      MOV DX,184FH  ;esquina inf. derecha de la pantalla(24,79)
      INT 10H
      
      MOV AH,02H 
      MOV DX,00H    ;posiscion del cursor(0,0) despues de limpiar pantalla
      MOV BH,00H    ;Pagina 0
      INT 10H
    
ENDM

FLUSH MACRO
        
    mov ax, 0000h
    mov bx, 0000h
    mov cx, 0000h
    mov DX, 0000h
    
ENDM
 
newline macro
    
    mov dl, 10       ;nueva linea ASCII
    mov ah, 2
    int 21h   
    mov dl, 13       ;alimentamos la linea (return) ASCII
    mov ah, 2
    int 21h
    
endm
remove macro
    
    mov dx, 8        ;backspace para ir atras de un caracter 
    mov ah, 2
    int 21h
    mov dx, 32       ;Espacio que elimina el caracter
    mov ah, 2
    int 21h
    mov dx, 8        ;backspace para remover la posicion del caracter
    mov ah, 2
    int 21h
    
endm

goto_pos macro row, col
                      
    ;Macro para ubicar el curso en la posicion deseada
                          
    mov ah, 02h      ;Establece la posicion del texto
    mov dh, row
    mov dl, col
    int 10h
    
endm

clrScrn macro
    mov ah, 02h    ;Establece la posicion del cursor a la esquina superior izquierda
    mov dh, 0
    mov dl, 0
    int 10h            
    mov ah, 0Ah     ;Sobreescribe con caracter vacio y quita todos los caracteres
    mov al, 00h     ;Caracter
    mov cx, 2000    ;Cuantas veces a escribir
    int 10h         ;interrupcion grafica
endm 
debug macro arg
    mov dx, arg    ;Con propositos de debugeo
    mov ah, 2
    int 21h
endm


IMPRIMIR MACRO F,C,texto
    
    ;FUNCION PARA IMPRIMIR UN TEXTO, DADAS UNAS COORDENADAS EN PANTALLA
    ;F es para la posicion en X
    ;C es para la posicion en Y
    MOV AH,02H
    MOV DH,F
    MOV DL,C
    INT 10H 
    MOV dx,offset texto
    MOV ah,09h
    INT 21h
    
ENDM

Macro MARCO
     
     Imprimir 3,12,deco1
     Imprimir 4,12,deco2
     Imprimir 5,12,deco2
     Imprimir 6,12,deco2
     Imprimir 7,12,deco2
     Imprimir 8,12,deco2
     Imprimir 9,12,deco2
     Imprimir 10,12,deco2
     
     Imprimir 11,12,deco2
     Imprimir 12,12,deco2
     Imprimir 13,12,deco2
     Imprimir 14,12,deco2
     Imprimir 15,12,deco2
     Imprimir 16,12,deco2
     
     Imprimir 17,12,deco1
                         
ENDM

;=============== Procedimientos ===============
start_menu proc
    
    
    CONFIGURAR
    MARCO
    FLUSH 
    
    Imprimir 3,27,Titulo
    
    Imprimir 14,15,CNTRLS1
    Imprimir 15,15,CNTRLS2
    Imprimir 5,15,INFO2
    Imprimir 6,15,INFO1
    
    Imprimir 8,15,OPC1
    Imprimir 9,15,OPC2
    Imprimir 10,15,OPC3
    Imprimir 11,15,OPC4
    Imprimir 12,15,OPC5
    
    Imprimir 19,12,opcPrompt
    
    FLUSH   

    MOV AH,01H
    INT 21H
       
    CMP AL,31H
    JE Crear
    
    CMP AL,32H
    JE OPEN
    
    CMP AL,33H
    JE OPEN
    
    CMP AL,34H
    JE Eliminar
    
    CMP AL,35H
    JE ENDPRG
    
    JMP EXIT 
    
start_menu endp    
    
Crear proc
    
    CONFIGURAR
    Imprimir 1,2,docPrompt

    ;Entrada de caracteres en el nombre del documento
    mov cx, 0  ;Contador del tamano del arreglo
    mov si, offset docName
    
    input_char: 
    mov ah, 1
    int 21h
    cmp al, 13          ;Verifica la tecla return
    je return
    cmp al, 8           ;Verifica la tecla backspace
    je remove_char
    inc cx              ;Incrementa el arreglo en 1
    mov [si], al
    inc si
    jmp input_char
    
    remove_char:
    cmp cx, 0
    je setPos_ret
    dec cx              ;Decrementa el arreglo en 1
    dec si
    mov [si], 00h
    
    mov dl, 32          ;Para eliminar el caracter
    mov ah, 2           ;
    int 21h             ;
    mov dl, 8           ;
    mov ah, 2           ;
    int 21h             ;
    jmp input_char
    
    setPos_ret:
    goto_pos 13, 40
    jmp input_char 
    
    return:    ;Regresa al procedimiento
    ret 
    
Crear endp


Eliminar proc
    
        mov ah,3eh ;Cierra el archivo
        int 21h 
    
        CONFIGURAR
        Imprimir 1,2,delPrompt
        
        ;Entrada de caracteres en el nombre del documento
        mov cx, 0  ;Contador del tamano del arreglo
        mov si, offset docName
        
        input_char3: 
        mov ah, 1
        int 21h
        cmp al, 13          ;Verifica la tecla return
        je enter3
        cmp al, 8           ;Verifica la tecla backspace
        je remove_char3
        inc cx              ;Incrementa el arreglo en 1
        mov [si], al
        inc si
        jmp input_char3
        
        remove_char3:
        cmp cx, 0
        je setPos_ret3
        dec cx              ;Decrementa el arreglo en 1
        dec si
        mov [si], 00h
        
        mov dl, 32          ;Para eliminar el caracter
        mov ah, 2           ;
        int 21h             ;
        mov dl, 8           ;
        mov ah, 2           ;
        int 21h             ;
        jmp input_char3
        
        setPos_ret3:
        goto_pos 13, 40
        jmp input_char3 
        
        
        enter3:    ;En caso de presionar enter
            CONFIGURAR
            
            mov ah,41h              ;modo de eliminacion
            mov dx, offset docName  ;nombre del documento
            int 21h 
            jc ERROREL ;Si hubo error
            Imprimir 1,2,MSMDEL
            JMP start_menu
        
        ERROREL:    
        
            Imprimir 1,2,ERRORDEL   ;Mensaje de error
            MOV AH,01H
            INT 21H       
            
            FLUSH                   ;Limpiamos los registros
            JMP start_menu
    
Eliminar endp


upper_bar proc
    
    goto_pos 0 0
    mov dx, offset docName  ;Muestra el nombre del documento en (0,0)
    mov ah, 9
    int 21h
    goto_pos 1 0
    mov dx, offset header   ;Muestra en separador
    mov ah, 9
    int 21h
    
    ret            
upper_bar endp

;=============== Codigo Principal ===============
MAIN PROC
    mov ax, @DATA
    mov ds, ax 
    
    mov ah, 01h        ;Define la forma del cursor
    mov cx, 07h        ;
    int 10h            ; 
    clrScrn
    call start_menu    ;Lama a start menu 
    clrScrn            ;Limpia la pantalla
    call upper_bar     ;Llama a upper_bar
    
    goto_pos 2, 0      ;Esablece la poscion del cursor
    
    mov si, offset matrix 
    mov di, offset matrix_2
    MAIN_LOOP:
    ; Leer caracter
    mov ah, 00h
    int 16h
    ; AH = BIOS scan code
    cmp ah, 01h            ;Si tecla escape
    je EXIT
    cmp al, 13h            ;Si CTRL+S
    je SAVE
    cmp al, 0Fh            ;Si CTRL+O
    je OPEN
    cmp ah, 48h            ;Si flecha arriba
    je UP
    cmp ah, 50h            ;Si flecha abajo
    je DOWN
    cmp ah, 4Bh            ;Si flecha izquierda
    je LEFT
    cmp ah, 4Dh            ;Si flecha derecha
    je RIGHT                             
    cmp ah, 1Ch            ;Si enter nueva linea
    je ENTER                                    
    cmp ah, 0Eh            ;Si backspace (quitar caracter)
    je BACKSPACE       
    
    cmp column, 79
    je ENTER
    mov dl, al             ;Si otra tecla entonces escribe el caracter en la pantalla
    mov ah, 2
    int 21h        
    mov [si], al           ;Anadir caracter a la matriz
    inc si
    inc curr_char          ;incrementa la posicion del caracter en la fila actual
    inc column             ;tambien incrementa el contador de caracteres
    goto_pos row, column
    jmp MAIN_LOOP
         
    EXIT:
        JMP start_menu

    ENDPRG:
        MOV AH, 4CH
        INT 21H
    
        
    SAVE:
    mov ah, 3Ch             ;Crear el archivo
    mov cx, 0               ;Archivo de solo lectura
    mov dx, offset docName  ;Darle el nombre que tomamos de Main Menu
    int 21h                 
    mov ah, 3Dh             ;Abre el archivo
    mov al, 1               ;Para modo de escritura
    mov dx, offset docName  ;Nombre del archivo
    int 21h
    mov HANDLE, ax          ;Establecemos el manejador
    mov ah, 40h             ;Funcion de escribir archivos
    mov bx, HANDLE          ;Busca el archivo para el manejador de archivos
    mov cx, 2000            ;Cuantos bytes es escribiran en el archivo
    mov dx, offset matrix   ;Que se va a escribir
    int 21h
    jmp MAIN_LOOP  
    
    OPEN:
    
    CONFIGURAR
    Imprimir 1,2,openPrompt
    
    
    ;Entrada de caracteres para el nombre del documento
    
    mov cx, 0           ;Contador del tamano del arreglo
    mov di, offset docName
    input_char2: 
    mov ah, 1
    int 21h
    cmp al, 13          ;Verifica la tecla return
    je return2
    cmp al, 8           ;Verifica la tecla backspace
    je remove_char2
    inc cx              ;Incremento del arreglo en 1
    mov [di], al
    inc di
    jmp input_char2
    remove_char2:
    cmp cx, 0
    je setPos_ret2
    dec cx              ;Decremento del arreglo en 1
    dec di
    mov [di], 00h
    mov dl, 32          ;Para eliminar el caracter
    mov ah, 2           ;
    int 21h             ;
    mov dl, 8           ;
    mov ah, 2           ;
    int 21h             ;
    jmp input_char2
    setPos_ret2:
    goto_pos 22, 29
    jmp input_char2
    return2:            ;Limpia la pantalla y regresa al procedimiento
    clrScrn
    call upper_bar 
    goto_pos 2, 0           ;Establece la posicion del cursor 
    mov ah, 0x3d             ;Para abir archivos
    mov al, 00               ;Manejador de archivos para leer archivos
    mov dx, offset docName
    int 21h
    mov HANDLE, ax           ;Estableciento en handler
    mov ah, 0x3f             ;Funcion para leer archivos
    mov bx, HANDLE
    mov cx, 1760             ;Cuantos bytes se van a escribir
    mov dx, offset matrix    ;Donde se guardara/leera la informacion
    int 21h      
    mov dx, offset matrix    ;Imprime el texto en pantalla
    mov ah, 9                ;
    int 21h
    FLUSH
    jmp MAIN_LOOP
           
    UP:
    cmp row, 2
    je MAIN_LOOP 
    dec curr_line
    dec row
    goto_pos row, column
    jmp MAIN_LOOP
         
    DOWN:
    inc curr_line
    inc row
    goto_pos row, column 
    jmp MAIN_LOOP
           
    LEFT:
    dec column
    goto_pos row, column
    jmp MAIN_LOOP
    
    RIGHT:
    inc column
    goto_pos row, column
    jmp MAIN_LOOP
    
    ENTER:      
    newline             ;Macro para nueva linea
    mov [si], 10        ;Mueve la nueva linea al arreglo
    inc si
    mov dl, curr_char
    mov [di], dl
    inc di
    inc curr_line
    mov curr_char, 0
    inc row             ;Incrementa el numero de filas
    mov column, 0       ;Se va  a la posicion 0 en columnas para la navegacion
    goto_pos row, 0     ;Va a la posicion 0 en columna
    jmp MAIN_LOOP
    
    BACKSPACE:
    ;Si verdadero
    cmp curr_line, 2    ;Ve si el cursor esta en la 1ra linea
    ;Entonces esto
    je rmv              ;Si verdadero, solo quita los caracteres de la matriz
    ;Si verdadero
    cmp curr_char, 0    ;Ve si el cursor esta en la posicion 0 a la izquierda
    ;Entonces esto
    je goBackLine       ;Si verdadero, entonces ve al principio de la fila
    
    ;Si no esto
    remove
    dec curr_char
    dec column
    dec si
    mov [si], 00h
    jmp MAIN_LOOP
    rmv:
    remove
    dec curr_char
    dec column
    dec si              ;Decrementa si
    mov [si], 00h       ;Llena de null cuando se quita un caracter del arreglo
    jmp MAIN_LOOP
    goBackLine:
    dec curr_line
    dec row
    dec di
    mov dl, [di]
    mov column, dl
    goto_pos curr_line, dl  ;Ir a la ultima posicion del ultimo caracter
    mov dl, [di]            ;Moverse a otro registro por que el tamano no corresponde
    mov curr_char, dl       ;Para reinicial el cursor a la ultima posicion
    jmp MAIN_LOOP
        
MAIN ENDP
END MAIN 