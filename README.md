# fortran-socket
Use C sockets directly in your fortran programs with this simple and portable binding!

## What is `socket_lib`?
`socket_lib` is a fortran binding of the C socket library, this means that it makes available socket functions and structures in your fortran programs. 
The goal of this module is to provide a simple and portable way to use sockets in Fortran to build networked applications more easily.
This module supports both POSIX sockets (Linux, macOS) and Winsock (Windows) with the same API, the platform differences are handled internally which means you don't need to litter your code with `#ifdef` checks.


### Exposed items (high level)
- Constants: `AF_INET`, `SOCK_STREAM`, `IPPROTO_TCP`, `INADDR_ANY`, `SOMAXCONN`, `SOL_SOCKET`, `SO_REUSEADDR`, `SO_EXCLUSIVEADDRUSE`, `INET_ADDRSTRLEN`
- Types: `sockaddr_in`, `in_addr` (plus Windows `WSADATA` when relevant)
- Functions: `socket`, `bind`, `listen`, `accept`, `send`, `recv`, `close`, `setsockopt`, `htons`, `ntohs`, `htonl`, `inet_addr`, `inet_ntoa`, `getsockname`, `get_errno`, and Windows helpers `WSAStartup`, `WSACleanup`, `WSAGetLastError`

## Requirements
- A Fortran compiler with `iso_c_binding` support (gfortran, ifx, etc.)
- A C preprocessor pass enabled for platform detection
  - gfortran: `-cpp`
  - ifx/ifort: `/fpp` or `-fpp`

## Building
### Linux/macOS (POSIX sockets)
```
gfortran -cpp socket_lib.f90 my_program.f90 -o my_program
```

### Windows (Winsock)
```
gfortran -cpp -D_WIN32 socket_lib.f90 my_program.f90 -lws2_32 -o my_program.exe
```

> **Important:** gfortran's Fortran preprocessor does not automatically define `_WIN32` on Windows, so you must pass `-D_WIN32` explicitly. You also need `-lws2_32` to link against the Winsock library.

## Usage
Add the module to your program and call the C-style APIs. 

> On Windows you must call `WSAStartup` before creating sockets and `WSACleanup` when done. The module provides a `is_windows` logical constant you can use to conditionally call these functions.

> As Windows and Linux/macOS have different ways to get error codes, use the provided `get_errno` function to retrieve the last socket error code in a portable way.


### Minimal TCP server (blocking, single client)
Here is a minimal example of a TCP server using `socket_lib`, it opens a socket, binds to port 8181, listens for incoming connections, accepts a client, receives a message, and sends a response.:

```fortran
program tcp_server
    use iso_c_binding
    use socket_lib
    implicit none

    integer(c_int) :: socket_fd, client_fd, status
    type(sockaddr_in), target :: addr
    integer(c_int16_t) :: port = 8181
    character(len=128, kind=c_char), target :: msg
    integer(c_int) :: msg_len


    ! Windows-specific variables
    type(WSADATA), target :: wsa_data
    integer(c_int) :: wsastatus, cleanup_status


    ! Windows-specific: Initialize Winsock
    if (is_windows) then
        wsastatus = WSAStartup(int(Z'0202', c_int), c_loc(wsa_data))
        if (wsastatus /= 0) then
            print *, "Error: WSAStartup failed with error code:", wsastatus
            stop
        end if
    end if

    ! Create socket
    socket_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
    if (socket_fd < 0) stop "socket() failed"

    ! Configure socket binding
    addr%sin_family = AF_INET
    addr%sin_port = htons(port)
    addr%sin_addr = htonl(INADDR_ANY)
    addr%sin_zero = c_null_char

    ! Do the actual socket binding
    status = bind(socket_fd, c_loc(addr), int(c_sizeof(addr), c_int))
    if (status /= 0) stop "bind() failed"

    status = listen(socket_fd, SOMAXCONN)
    if (status /= 0) stop "listen() failed"
    
    client_fd = accept(socket_fd, c_null_ptr, 0_c_int)
    if (client_fd < 0) stop "accept() failed"

    msg = "hello from fortran" // c_null_char
    msg_len = len_trim(msg)
    status = send(client_fd, c_loc(msg), int(msg_len), 0)

    status = close(client_fd)
    status = close(socket_fd)

    ! Windows-specific: Cleanup Winsock
    if (is_windows) then
        cleanup_status = WSACleanup()
        if (cleanup_status /= 0) stop "WSACleanup failed"
    endif

end program tcp_server

```

## Notes & pitfalls
- This is a thin binding. You are responsible for error handling, byte order, and memory safety.
- Use `htons`/`htonl` and `ntohs` to handle network byte order.
- Functions that take pointers expect `c_loc`ed arguments and `target` variables.
- For Windows, do not forget to link against `ws2_32` and call `WSAStartup`/`WSACleanup`.
- Strings passed to C must be `kind=c_char` and null‑terminated.
- If you need additional socket functions (for example `connect`), add their C bindings in the module following the existing patterns.

## License
MIT. See [LICENSE](LICENSE).
