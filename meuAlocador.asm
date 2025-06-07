.section .data
    topoInicialHeap: .quad 0
    inicioLista: .quad 0
    fimHeapAtual: .quad 0
    TAMANHO_CABECALHO: .quad 16  # Assuming sizeof(Bloco) is 16 bytes

.section .text
    .global iniciaAlocador
    .global finalizaAlocador
    .global alocaMem
    .global liberaMem
    .global imprimeMapa

iniciaAlocador:
    mov rax, 12          # SYS_brk
    xor rdi, rdi        # Pass 0 to get current top of heap
    syscall
    mov [topoInicialHeap], rax
    mov [fimHeapAtual], rax
    cmp rax, -1
    je .error_heap_start
    ret

.error_heap_start:
    mov rdi, msg_error_heap_start
    call perror
    ret

finalizaAlocador:
    cmp [topoInicialHeap], 0
    je .error_heap_not_initialized
    mov rax, 12          # SYS_brk
    mov rdi, [topoInicialHeap]
    syscall
    cmp rax, [topoInicialHeap]
    jne .error_restore_heap
    ret

.error_heap_not_initialized:
    mov rdi, msg_error_heap_not_initialized
    call fprintf
    ret

.error_restore_heap:
    mov rdi, msg_error_restore_heap
    call perror
    ret

alocaMem:
    cmp rdi, 0
    jle .return_null

    mov rsi, [inicioLista]
    .find_free_block:
        test rsi, rsi
        jz .no_free_block
        mov rax, [rsi + 4]  # Load livre
        test rax, rax
        jz .next_block
        mov rax, [rsi]      # Load tamanho
        cmp rax, rdi
        jl .next_block
        mov dword [rsi + 4], 0  # Set livre to 0
        lea rax, [rsi + 16]      # Return pointer to data
        ret
    .next_block:
        mov rsi, [rsi + 8]  # Load prox
        jmp .find_free_block

.no_free_block:
    lea rax, [fimHeapAtual + TAMANHO_CABECALHO + rdi]
    mov rax, 12          # SYS_brk
    syscall
    cmp rax, -1
    je .error_expand_heap

    mov rsi, [fimHeapAtual]
    mov [rsi], rdi      # Set tamanho
    mov dword [rsi + 4], 0  # Set livre to 0
    mov qword [rsi + 8], 0  # Set prox to NULL

    mov [fimHeapAtual], rax
    test [inicioLista], inicioLista
    jnz .add_to_list
    mov [inicioLista], rsi
    jmp .return_data

.add_to_list:
    mov rdi, [inicioLista]
    .traverse_list:
        mov rsi, [rdi + 8]  # Load prox
        test rsi, rsi
        jnz .traverse_list
        mov [rdi + 8], rsi  # Set prox to novo bloco

.return_data:
    lea rax, [rsi + 16]  # Return pointer to data
    ret

.error_expand_heap:
    mov rdi, msg_error_expand_heap
    call perror
    ret

liberaMem:
    test rdi, rdi
    jz .return_error

    lea rsi, [rdi - 16]  # Get header
    mov rax, [rsi + 4]   # Load livre
    test rax, rax
    jnz .return_error

    mov dword [rsi + 4], 1  # Set livre to 1
    xor rax, rax
    ret

.return_error:
    mov rax, -1
    ret

imprimeMapa:
    mov rsi, [inicioLista]
    .print_loop:
        test rsi, rsi
        jz .end_print
        mov rdi, sizeof(Bloco)
        .print_header:
            mov rax, 1
            mov rdi, 1
            lea rsi, [char_hash]
            syscall
            dec rdi
            jnz .print_header

        mov rax, [rsi + 4]  # Load livre
        test rax, rax
        jz .occupied
        mov rdi, char_free
        jmp .print_data

    .occupied:
        mov rdi, char_occupied

    .print_data:
        mov rax, [rsi]      # Load tamanho
        .print_data_loop:
            mov rax, 1
            mov rdi, 1
            lea rsi, [char_data]
            syscall
            dec rax
            jnz .print_data_loop

        mov rsi, [rsi + 8]  # Load prox
        jmp .print_loop

.end_print:
    mov rax, 1
    mov rdi, 1
    lea rsi, [char_newline]
    syscall
    ret

.section .rodata
msg_error_heap_start: .asciz "Erro ao obter topo inicial da heap\n"
msg_error_heap_not_initialized: .asciz "Erro: topoInicialHeap não foi inicializado.\n"
msg_error_restore_heap: .asciz "Erro ao restaurar topo da heap\n"
msg_error_expand_heap: .asciz "Erro ao expandir heap\n"
char_hash: .asciz "#"
char_free: .asciz "-"
char_occupied: .asciz "+"
char_data: .asciz " "
char_newline: .asciz "\n"
