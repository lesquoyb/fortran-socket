# fortran-socket
Use C sockets directly in your fortran programs with this simple and portable binding!

## What is fortran-socket?
fortran-socket is a fortran binding of the C socket library, this means that it makes available socket functions and structures in your fortran programs.
It is composed of a single file: `socket_lib.f90` that you just have to add to your project to benefit from a simple and portable way to use sockets in Fortran to build networked applications more easily.
This module supports both POSIX sockets (Linux, macOS) and Winsock (Windows) with the same API, the platform differences are handled internally which means you don't need to litter your code with `#ifdef` checks.


### Exposed items (high level)
- Constants: `AF_INET`, `SOCK_STREAM`, `IPPROTO_TCP`, `INADDR_ANY`, `SOMAXCONN`, `SOL_SOCKET`, `SO_REUSEADDR`, `SO_EXCLUSIVEADDRUSE`, `INET_ADDRSTRLEN`, `TCP_NODELAY`
- Types: `sockaddr_in`, `in_addr` (plus Windows `WSADATA` when relevant)
- Functions: `socket`, `bind`, `listen`, `accept`, `send`, `recv`, `close`, `setsockopt`, `htons`, `ntohs`, `htonl`, `inet_addr`, `inet_ntoa`, `getsockname`, `get_errno`, and Windows helpers `WSAStartup`, `WSACleanup`, `WSAGetLastError`

## Requirements
A Fortran compiler with `iso_c_binding` support (gfortran, ifx, etc.)

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
Add the module to your program and call the API in the same way you would in C.

> On Windows you must call `WSAStartup` before creating sockets and `WSACleanup` when done. The module provides a `is_windows` logical constant you can use to conditionally call these functions.

> As Windows and Linux/macOS have different ways to get error codes, use the provided `get_errno` function to retrieve the last socket error code in a portable way.


### Minimal TCP server (blocking, single client)
You can find in the repository an example of a simple TCP server using `socket_lib`: [example-server.f90](example-server.f90).
This program creates a server on port 8081 then waits for a client to connect, when the first client is connected it will send a message to it, wait 5 seconds and close.
If everything works as expected you should see this in the console on Windows:
```
 Socket created successfully
 Socket options set successfully
 Socket bound successfully to port   8181
 Listening for incoming connections
 Client connected
 Message sent to client, waiting 5 seconds before closing
 Winsock cleaned up successfully
```
And the same on Linux/macOS without the Winsock lines.

## Notes & pitfalls
- This is a thin binding. You are responsible for error handling, byte order, and memory safety.
- Use `htons`/`htonl` and `ntohs` to handle network byte order.
- Functions that take pointers expect `c_loc`ed arguments and `target` variables.
- For Windows, do not forget to link against `ws2_32` and call `WSAStartup`/`WSACleanup`.
- Strings passed to C must be `kind=c_char` and null‑terminated.
- If you need additional socket functions (for example `connect`), add their C bindings in the module following the existing patterns.

## License
MIT. See [LICENSE](LICENSE).
