format ELF64 executable 3

include "import64.inc"
interpreter "/lib64/ld-linux-x86-64.so.2"
needed "libc.so.6"
import printf, close, fopen, listen, socket, bind, accept

segment readable
    PORT equ 8080
    AF_INET equ 2
    SOCK_STREAM equ 1
    SYS_CLOSE_CALL equ 3
    SYS_BIND_CALL equ 0x31
    SYS_LISTEN_CALL equ 50
    SYS_ACCEPT_CALL equ 43
    SYS_WRITE_CALL equ 1

segment readable writeable
    localhost_ip_addr db "0.0.0.0", 0

    struc sockaddr_in a, b, c, d {
      .sin_family dw a
      .sin_port dw b
      .sin_addr dd c
      .sin_zero dq d
    }

    srv_sockaddr_in sockaddr_in AF_INET, 0, 0, 0
    clt_sockaddr_in sockaddr_in ?, ?, ?, ?
    clt_sockaddr_in_len equ $ - clt_sockaddr_in

    clt_socket dq ?
    srv_socket dq ?

    html_page1_file_name db "web/page1.html", 0
    html_page1_file_handle dq ?
    
    html_page1_file_buff rb 1000
    html_page1_file_buff_len equ $ - html_page1_file_buff


  msg:
      .print_content_file_format db "content: ", 13, 10, 13, 10, "%s", 13, 10, 0
      .error_format db "something went wrong %d", 10, 0
      .error.len equ $ - msg.error
      .open_file db "opening file", 10, 0
      .read_file db "reading file", 13, 10, 0
      .server_hello db "server running on the port %d...", 10, 0

      .http_response_200_ok:
          db "HTTP/1.1 200 OK", 13, 10
          db "Content-Type: %s", 13, 10
          db "Content-Length: %d", 13, 10
          db 13, 10
          db "%s", 0


segment readable executable
entry $
    ; print hello message
    mov rdi, msg.server_hello
    mov rsi, PORT
    call [printf]
    jmp print_html_file


print_html_file:
    ; open html file
    mov rdi, msg.open_file
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
    mov rdi, msg.read_file
    call [printf]

    mov rax, 0
    mov rdi, [html_page1_file_handle]
    mov rsi, html_page1_file_buff
    mov rdx, html_page1_file_buff_len
    syscall

    mov rdi, msg.print_content_file_format
    mov rsi, html_page1_file_buff
    call [printf]

    ; close html file
    mov rax, 3
    mov rdi, [html_page1_file_handle]
    syscall

    ; todo
    jmp create_server_socket

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
    mov rdi, msg.error_format
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


    ;bind(sock, addr, sizeof sockaddr_in)
    mov rdi, [srv_socket]

    push AF_INET
    push 0x270f ;1988 or 8819
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

    ; accept
    mov rdi, [srv_socket]
    mov rsi, clt_sockaddr_in
    mov rdx, clt_sockaddr_in_len
    mov rax, SYS_ACCEPT_CALL
    syscall
    
    ; todo check error

    mov [clt_socket], rax

serve_client:
    ; todo
    mov rdi, [clt_socket]
    mov rax, SYS_WRITE_CALL
    syscall