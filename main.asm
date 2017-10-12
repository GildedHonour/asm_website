format ELF64 executable 3

include "import64.inc"
interpreter "/lib64/ld-linux-x86-64.so.2"
needed "libc.so.6"
import printf, close, fopen, listen, socket, bind, accept

segment readable writeable
    server_hello_msg db "server running on the port %d...", 10, 0
    localhost_ip_addr db "0.0.0.0", 0

    struc sockaddr_in sin_family, sin_port, sin_addr, sin_zero {
      .sin_family dw,
      .sin_port dw,
      .sin_addr dd,
      .sin_zero dq,
    }

    http_response_200_ok:
        db "HTTP/1.1 200 OK", 13, 10
        db "Content-Type: %s", 13, 10
        db "Content-Length: %d", 13, 10
        db 13, 10
        db "%s", 0

    clt_socket dq ?
    srv_socket dq ?

    html_page1_file_name db "web/page1.html", 0
    html_page1_file_handle dq ?
    
    html_page1_file_buff rb 1000
    html_page1_file_buff_len equ $ - html_page1_file_buff

    error_msg_format db "something went wrong %d", 10, 0
    error_msg_len equ $ - error_msg
    open_file_msg db "opening file", 10, 0
    read_file_msg db "reading file", 13, 10, 0
    print_content_file_msg_format db "content: ", 13, 10, 13, 10, "%s", 13, 10, 0

segment readable
    PORT equ 8080
    AF_INET equ 2
    SOCK_STREAM equ 1
    SYS_CLOSE_CALL equ 3
    SYS_BIND_CALL equ 0x31
    SYS_LISTEN_CALL equ 50

segment readable executable
entry $
    ; print hello message
    mov rdi, server_hello_msg
    mov rsi, PORT
    call [printf]
    jmp print_html_file


print_html_file:
    ; open html file
    mov rdi, open_file_msg
    call [printf]
    mov rax, 2
    mov rdi, html_page1_file_name
    mov rsi, 0
    syscall

    ; check if success
    test rax, rax
    jz error
    mov [html_page1_file_handle], rax
    xor rax, rax

    ; read
    mov rdi, read_file_msg
    call [printf]

    mov rax, 0
    mov rdi, [html_page1_file_handle]
    mov rsi, html_page1_file_buff
    mov rdx, html_page1_file_buff_len
    syscall

    mov rdi, print_content_file_msg_format
    mov rsi, html_page1_file_buff
    call [printf]

    ; close html file
    mov rax, 3
    mov rdi, [html_page1_file_handle]
    syscall

cleanup:
    ; close sockets
    mov rax, SYS_CLOSE_CALL
    mov rdi, [clt_socket]
    syscall

    mov rax, SYS_CLOSE_CALL
    mov rdi, [srv_socket]
    syscall

exit:
    xor rdi, rdi
    mov rax, 60
    syscall
    ret

error:
    mov rdi, error_msg_format
    mov rsi, rax
    call [printf]
    jmp exit


create_server_socket:
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    call [socket]

    cmp rax, 0
    je error
    mov [srv_socket], rax
    xor rax, rax



    ; todo

    ;bind(sock, addr, sizeof sockaddr_in)
    mov rdi, [srv_socket]

    push AF_INET
    push 0xc308 ;1988
    push 0
    mov rsi, rsp

    mov rdx, 0x10 ; size of sockaddr_in: 2 + 2 + 4 + 8
    mov rax, SYS_BIND_CALL
    syscall
    cmp rax, 0

    ; listen
    mov rdi, [srv_socket]
    mov rsi, 0
    mov rax, SYS_LISTEN_CALL
    syscall





accept_client_connection:
    