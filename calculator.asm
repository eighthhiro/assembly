section .data
    ; Messages
    welcome_msg     db 'Simple 2-Digit Calculator', 0xa, '========================', 0xa, 0
    welcome_len     equ $ - welcome_msg
    
    menu_msg        db 0xa, 'Options:', 0xa, '1. Calculate', 0xa, '2. Exit', 0xa, 'Choose (1 or 2): ', 0
    menu_len        equ $ - menu_msg
    
    prompt1_msg     db 'Enter first number (0-99): ', 0
    prompt1_len     equ $ - prompt1_msg
    
    prompt2_msg     db 'Enter second number (0-99): ', 0
    prompt2_len     equ $ - prompt2_msg
    
    op_msg          db 'Enter operation (+, -, *, /): ', 0
    op_len          equ $ - op_msg
    
    result_msg      db 'Result: ', 0
    result_len      equ $ - result_msg
    
    continue_msg    db 0xa, 'Press Enter to continue...', 0
    continue_len    equ $ - continue_msg
    
    goodbye_msg     db 0xa, 'Thanks for using the calculator!', 0xa, 0
    goodbye_len     equ $ - goodbye_msg
    
    newline         db 0xa, 0
    newline_len     equ $ - newline
    
    error_msg       db 'Invalid operation!', 0xa, 0
    error_len       equ $ - error_msg
    
    div_zero_msg    db 'Error: Division by zero!', 0xa, 0
    div_zero_len    equ $ - div_zero_msg
    
    invalid_choice  db 'Invalid choice! Please enter 1 or 2.', 0xa, 0
    invalid_len     equ $ - invalid_choice

section .bss
    num1        resb 4      ; First number input buffer
    num2        resb 4      ; Second number input buffer
    operation   resb 2      ; Operation input buffer
    choice      resb 2      ; Menu choice buffer
    dummy       resb 2      ; For consuming Enter key
    result      resb 10     ; Result string buffer

section .text
    global _start

_start:
    ; Print welcome message once
    mov eax, 4
    mov ebx, 1
    mov ecx, welcome_msg
    mov edx, welcome_len
    int 0x80

main_loop:
    ; Show menu
    mov eax, 4
    mov ebx, 1
    mov ecx, menu_msg
    mov edx, menu_len
    int 0x80
    
    ; Get menu choice
    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 2
    int 0x80
    
    ; Check choice
    mov al, [choice]
    cmp al, '1'
    je do_calculation
    cmp al, '2'
    je exit_program
    
    ; Invalid choice
    mov eax, 4
    mov ebx, 1
    mov ecx, invalid_choice
    mov edx, invalid_len
    int 0x80
    jmp main_loop

do_calculation:
    ; Get first number
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt1_msg
    mov edx, prompt1_len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, num1
    mov edx, 4
    int 0x80
    
    ; Get second number
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt2_msg
    mov edx, prompt2_len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, num2
    mov edx, 4
    int 0x80
    
    ; Get operation
    mov eax, 4
    mov ebx, 1
    mov ecx, op_msg
    mov edx, op_len
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, operation
    mov edx, 2
    int 0x80
    
    ; Convert ASCII strings to numbers
    call convert_num1
    call convert_num2
    
    ; Perform operation
    mov al, [operation]     ; Load operation character
    cmp al, '+'
    je addition
    cmp al, '-'
    je subtraction
    cmp al, '*'
    je multiplication
    cmp al, '/'
    je division
    
    ; Invalid operation
    mov eax, 4
    mov ebx, 1
    mov ecx, error_msg
    mov edx, error_len
    int 0x80
    jmp wait_continue

addition:
    mov eax, [num1_val]
    add eax, [num2_val]
    mov [result_val], eax
    jmp print_result

subtraction:
    mov eax, [num1_val]
    sub eax, [num2_val]
    mov [result_val], eax
    jmp print_result

multiplication:
    mov eax, [num1_val]
    mul dword [num2_val]
    mov [result_val], eax
    jmp print_result

division:
    mov eax, [num2_val]
    cmp eax, 0
    je div_by_zero
    
    mov eax, [num1_val]
    xor edx, edx            ; Clear edx for division
    div dword [num2_val]
    mov [result_val], eax
    jmp print_result

div_by_zero:
    mov eax, 4
    mov ebx, 1
    mov ecx, div_zero_msg
    mov edx, div_zero_len
    int 0x80
    jmp wait_continue

print_result:
    ; Print "Result: " message
    mov eax, 4
    mov ebx, 1
    mov ecx, result_msg
    mov edx, result_len
    int 0x80
    
    ; Convert result to string and print
    mov eax, [result_val]
    call int_to_string
    
    ; Print newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, newline_len
    int 0x80

wait_continue:
    ; Ask user to press Enter to continue
    mov eax, 4
    mov ebx, 1
    mov ecx, continue_msg
    mov edx, continue_len
    int 0x80
    
    ; Wait for Enter key
    mov eax, 3
    mov ebx, 0
    mov ecx, dummy
    mov edx, 2
    int 0x80
    
    ; Jump back to main loop
    jmp main_loop

exit_program:
    ; Print goodbye message
    mov eax, 4
    mov ebx, 1
    mov ecx, goodbye_msg
    mov edx, goodbye_len
    int 0x80
    
    ; Exit program
    mov eax, 1
    mov ebx, 0
    int 0x80

; Convert first number from ASCII to integer
convert_num1:
    xor eax, eax            ; Clear result
    xor ebx, ebx            ; Clear working register
    mov esi, num1           ; Point to input string
    
convert1_loop:
    mov bl, [esi]           ; Load character
    cmp bl, 0xa             ; Check for newline
    je store_num1           ; End of number
    cmp bl, 0               ; Check for null terminator
    je store_num1           ; End of number
    cmp bl, '0'             ; Check if below '0'
    jb store_num1           ; Not a digit
    cmp bl, '9'             ; Check if above '9'
    ja store_num1           ; Not a digit
    
    sub bl, '0'             ; Convert ASCII to digit
    imul eax, 10            ; Multiply current result by 10
    add eax, ebx            ; Add new digit
    inc esi                 ; Move to next character
    jmp convert1_loop       ; Continue

store_num1:
    mov [num1_val], eax
    ret

; Convert second number from ASCII to integer
convert_num2:
    xor eax, eax            ; Clear result
    xor ebx, ebx            ; Clear working register
    mov esi, num2           ; Point to input string
    
convert2_loop:
    mov bl, [esi]           ; Load character
    cmp bl, 0xa             ; Check for newline
    je store_num2           ; End of number
    cmp bl, 0               ; Check for null terminator
    je store_num2           ; End of number
    cmp bl, '0'             ; Check if below '0'
    jb store_num2           ; Not a digit
    cmp bl, '9'             ; Check if above '9'
    ja store_num2           ; Not a digit
    
    sub bl, '0'             ; Convert ASCII to digit
    imul eax, 10            ; Multiply current result by 10
    add eax, ebx            ; Add new digit
    inc esi                 ; Move to next character
    jmp convert2_loop       ; Continue

store_num2:
    mov [num2_val], eax
    ret

; Convert integer in eax to string and print it
int_to_string:
    mov edi, result + 9     ; Point to end of buffer
    mov byte [edi], 0       ; Null terminator
    dec edi
    
    mov ebx, 10             ; Divisor
    
convert_loop:
    xor edx, edx            ; Clear edx
    div ebx                 ; Divide eax by 10
    add dl, '0'             ; Convert remainder to ASCII
    mov [edi], dl           ; Store digit
    dec edi
    test eax, eax           ; Check if quotient is 0
    jnz convert_loop
    
    ; Print the string
    inc edi                 ; Point to first digit
    mov eax, 4
    mov ebx, 1
    mov ecx, edi
    mov edx, result + 9
    sub edx, edi            ; Calculate length
    int 0x80
    ret

section .data
    ten         dd 10
    num1_val    dd 0
    num2_val    dd 0
    result_val  dd 0