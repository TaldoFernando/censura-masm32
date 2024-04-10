.686
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\masm32.inc
include \masm32\include\gdi32.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\msvcrt.inc
include \masm32\macros\macros.asm

includelib \masm32\lib\msvcrt.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib

.DATA
    fileName DB 256 DUP(0)
    outputFile DB 256 DUP(0)
    hFileIn HANDLE ?
    hFileOut HANDLE ?
    bytesRead DWORD ?
    headerBytes DB 18 DUP(0)
    headerSize DWORD ?
    imageWidth DWORD ?
    headerRemainder DB 32 DUP(0)
    pixelDataBuffer DB 6480 DUP(0)
    prompt_in db "Digite o nome do arquivo de entrada: ", 0
    prompt_out db "Digite o nome do arquivo de saida: ", 0
    error db "Houve um erro.", 0
    x_inicial DWORD ?
    largura_censura DWORD ?
    y_inicial DWORD ?
    altura_censura DWORD ?
    x_inicial_str db 32 DUP(0) 
    y_inicial_str db 32 DUP(0) 
    largura_str db 32 DUP(0) 
    altura_str db 32 DUP(0) 
    pixel_largura_img dd 0 
    linha_atual dd 0
    hStdin HANDLE ?
    hStdout HANDLE ?
    


    prompt_x_inicial db "Digite o valor de x inicial: ", 0
    prompt_y_inicial db "Digite o valor de y inicial: ", 0
    prompt_largura_censura db "Digite a largura da censura: ", 0
    prompt_altura_censura db "Digite a altura da censura: ", 0

.CODE

start:
    ; pede nome do arquivo de entrada
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hStdout, eax

    invoke GetStdHandle, STD_INPUT_HANDLE
    mov hStdin, eax

   ; Obter os handles de entrada e saída padrão
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov hStdin, eax
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hStdout, eax
  
    invoke WriteConsole, hStdout, offset prompt_in, LENGTHOF prompt_in, offset bytesRead, NULL
    invoke ReadConsole, hStdin, offset fileName, 256, offset bytesRead, NULL

    mov esi, offset fileName
    call tratar_asc

    invoke WriteConsole, hStdout, offset prompt_out, LENGTHOF prompt_out, offset bytesRead, NULL
    invoke ReadConsole, hStdin, offset outputFile, 256, offset bytesRead, NULL

    mov esi, offset outputFile
    
    call tratar_asc

    invoke CreateFile, offset fileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov hFileIn, eax
    cmp hFileIn, INVALID_HANDLE_VALUE
    je error_occurred

    invoke CreateFile, offset outputFile, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov hFileOut, eax

    ; leitura do cabeçalho 
    invoke ReadFile, hFileIn, offset headerBytes, 18, offset bytesRead, NULL
    invoke WriteFile, hFileOut, offset headerBytes, 18, offset bytesRead, NULL

    invoke ReadFile, hFileIn, offset imageWidth, 4, offset bytesRead, NULL
    invoke WriteFile, hFileOut, offset imageWidth, 4, offset bytesRead, NULL

    invoke ReadFile, hFileIn, offset headerRemainder, 32, offset bytesRead, NULL
    invoke WriteFile, hFileOut, offset headerRemainder, 32, offset bytesRead, NULL

    ;obtem o valor de x inicial , mesma logia para os outros parametros
    invoke WriteConsole, hStdout, offset prompt_x_inicial, LENGTHOF prompt_x_inicial, offset bytesRead, NULL
    invoke ReadConsole, hStdin, offset x_inicial_str, sizeof x_inicial, offset bytesRead, NULL
    ;tratamento de string para x_inicial
    mov esi, offset x_inicial_str
    call tratar_asc

    invoke atodw, ADDR x_inicial_str
    mov x_inicial, eax
    

    invoke WriteConsole, hStdout, offset prompt_y_inicial, LENGTHOF prompt_y_inicial, offset bytesRead, NULL
    invoke ReadConsole, hStdin, offset y_inicial_str, sizeof y_inicial, offset bytesRead, NULL

    mov esi, offset y_inicial_str

    call tratar_asc


    invoke atodw, ADDR y_inicial_str
    mov y_inicial, eax
    
    invoke WriteConsole, hStdout, offset prompt_largura_censura,  LENGTHOF prompt_largura_censura, offset bytesRead, NULL
    invoke ReadConsole, hStdin, offset largura_str, sizeof largura_censura, offset bytesRead, NULL

    mov esi, offset largura_str
    call tratar_asc

    invoke atodw, ADDR largura_str
    mov largura_censura, eax
    
    invoke WriteConsole, hStdout, offset prompt_altura_censura, LENGTHOF prompt_altura_censura, offset bytesRead, NULL
    invoke ReadConsole, hStdin, offset altura_str, sizeof altura_censura, offset bytesRead, NULL

    mov esi, offset altura_str
    call tratar_asc
    
    invoke atodw, ADDR altura_str
    mov altura_censura, eax
    

    mov eax, imageWidth
    dec pixel_largura_img
    imul eax, 3
    mov pixel_largura_img, eax
   

   call meu_laco

    invoke CloseHandle, hFileIn
    invoke CloseHandle, hFileOut

    invoke ExitProcess, 0

censurar_linha:
    push ebp
    mov ebp, esp
    mov edi, [ebp + 16] 
    mov ecx, [ebp + 12] 
    imul ecx, 3
    mov ebx, [ebp + 8] 
    imul ebx, 3

    add ebx, ecx 

    preencher_loop:
        cmp ecx, ebx
        jg fim_preencher
        
        mov byte ptr[edi + ecx], 0 ;r       
        mov byte ptr[edi + ecx + 1], 0 ;g      
        mov byte ptr[edi + ecx + 2], 0 ;b
        add ecx, 3 
        jmp preencher_loop

    fim_preencher:
    mov esp, ebp
    pop ebp
    ret 0 

tratar_asc:
        mov al, [esi] 
        inc esi 
        cmp al, 13 
        jne tratar_asc
        dec esi 
        xor al, al 
        mov [esi], al 


meu_laco:
   
    invoke ReadFile, hFileIn, offset pixelDataBuffer, pixel_largura_img, offset bytesRead, NULL
    cmp bytesRead, 0
    je meu_sair

    mov esi, linha_atual ;indice da linha atual

    ;vê se a linha está dentro da área de censura
    cmp esi, y_inicial
    jl linha_inalterada

    mov eax, y_inicial
    add eax, altura_censura
    cmp esi, eax
    jge linha_inalterada

    push offset pixelDataBuffer 
    push x_inicial 
    push largura_censura
    call censurar_linha
    ; add esp, 12    

linha_inalterada:
    invoke WriteFile, hFileOut, offset pixelDataBuffer, bytesRead, offset bytesRead, NULL
    inc linha_atual
    jmp meu_laco

meu_sair:
    ret

error_occurred: 
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov ecx, eax
    invoke WriteConsole, ecx, offset error, LENGTHOF error, offset bytesRead, NULL
    invoke ExitProcess, -1
end start