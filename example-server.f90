program tcp_server
    use iso_c_binding
    use socket_lib
    implicit none

    integer(c_int) :: socket_fd, client_fd, status
    type(sockaddr_in), target :: addr
    integer(c_int16_t) :: port = 8181
    character(len=128, kind=c_char), target :: msg
    integer(c_int) :: msg_len
    integer(c_int), target :: optyes = 1_c_int


    ! Windows-specific variables
    type(WSADATA), target :: wsa_data
    integer(c_int) :: wsastatus, cleanup_status


    ! Windows-specific: Initialize Winsock
    if (is_windows) then
        wsastatus = WSAStartup(int(Z'0202', c_int), c_loc(wsa_data))
        if (wsastatus /= 0) then
            print *, "Error: WSAStartup failed with error code:", wsastatus
            call exit(1)
        end if
    end if

    ! Create socket
    socket_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
    if (socket_fd < 0) then
        print *, "socket() failed", socket_fd
        call exit(1)
    end if
    print *, "Socket created successfully"

    ! Set socket options (e.g., TCP_NODELAY)
    status = setsockopt(socket_fd, IPPROTO_TCP, TCP_NODELAY, c_loc(optyes), int(c_sizeof(optyes), c_int))
    if (status /= 0) then
        print *, "setsockopt() failed", status
        call exit(1)
    end if
    print *, "Socket options set successfully"

    ! Configure socket binding
    addr%sin_family = AF_INET
    addr%sin_port = htons(port)
    addr%sin_addr = htonl(INADDR_ANY)
    addr%sin_zero = c_null_char

    ! Do the actual socket binding
    status = bind(socket_fd, c_loc(addr), int(c_sizeof(addr), c_int))
    if (status /= 0) then
        print *, "bind() failed", status
        call exit(1)
    end if
    print *, "Socket bound successfully to port", port

    status = listen(socket_fd, SOMAXCONN)
    if (status /= 0) then
        print *, "listen() failed", status
        call exit(1)
    end if
    print *, "Listening for incoming connections"
    
    client_fd = accept(socket_fd, c_null_ptr, 0_c_int)
    if (client_fd < 0) then
        print *, "accept() failed", client_fd
        call exit(1)
    end if
    print *, "Client connected"

    msg = "hello from fortran server" // achar(10) // achar(13) // c_null_char
    msg_len = len_trim(msg)
    status = send(client_fd, c_loc(msg), int(msg_len), 0)
    if (status < 0) then
        print *, "send() failed", status
        call exit(1)
    end if
    print *, "Message sent to client, waiting 5 seconds before closing"

    call sleep(5)
    status = close(client_fd)
    status = close(socket_fd)

    ! Windows-specific: Cleanup Winsock
    if (is_windows) then
        cleanup_status = WSACleanup()
        if (cleanup_status /= 0) then
            print *, "WSACleanup failed", cleanup_status
            call exit(1)
        end if
        print *, "Winsock cleaned up successfully"
    endif

end program tcp_server