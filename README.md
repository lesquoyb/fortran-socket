# fortran-socket

A minimal, portable Fortran binding for C sockets. Use POSIX sockets and Winsock directly in your Fortran programs with a unified API.

## What is fortran-socket?

fortran-socket makes C socket functions and structures available in Fortran through `iso_c_binding`. It supports both POSIX sockets (Linux, macOS) and Winsock (Windows) behind the same API — platform differences are handled internally so you don't need `#ifdef` checks in your application code.

The binding is designed primarily for TCP but exposes a wide enough API for other protocols, and adding new bindings is straightforward by following the existing patterns.

## Repository structure

```
fortran-socket/
├── src/
│   ├── socket_lib.f90          # Main module: type definitions, function bindings, helpers
│   ├── constants.f90           # Platform-specific socket constants (generated)
│   └── platform.h              # Shared platform detection header (IS_WINDOWS macro)
├── examples/
│   └── example_tcp_server.f90  # Minimal TCP server demo
├── tools/
│   ├── constant_generator.py   # Script to regenerate constants for the current platform
│   ├── constant.template.c     # C template used by the generator
│   ├── constants.template.f90  # Fortran template used by the generator
│   ├── constants.txt           # List of C constants to extract
│   └── README.md               # Documentation for the tools
├── LICENSE
└── README.md
```

### `src/`

- **`socket_lib.f90`** — The core module. Contains type definitions (`sockaddr_in`, `in_addr`, `WSADATA`), C function bindings (`socket`, `bind`, `listen`, `accept`, `send`, `recv`, `close`, etc.), and portable helper functions (`get_errno`, stub `WSA*` functions on non-Windows).
- **`constants.f90`** — A generated module (`socket_lib_constants`) that provides a large set of platform-specific socket option constants (e.g. `SOL_SOCKET`, `TCP_NODELAY`, `SO_REUSEADDR`, error codes, etc.) with separate values for Windows, Linux, and macOS. This file is produced by the tooling in `tools/` and should be regenerated on each target platform.
- **`platform.h`** — A shared preprocessor header that defines the `IS_WINDOWS` macro based on platform detection. Both `socket_lib.f90` and `constants.f90` include this header via `#include "platform.h"`, avoiding duplicated platform checks.

### `examples/`

Contains example programs that demonstrate how to use the binding.

### `tools/`

Scripts and templates for regenerating `constants.f90` on your platform. See [tools/README.md](tools/README.md) for details.

## Exposed API


- **Extended constants** (via `socket_lib_constants`): 200+ platform-specific socket options, protocol-level constants, and error codes. See `constants.f90` for the full list.
- **Types**: `sockaddr_in`, `in_addr`, `WSADATA` (Windows)
- **Functions**: `socket`, `bind`, `listen`, `accept`, `send`, `recv`, `close`, `setsockopt`, `htons`, `ntohs`, `htonl`, `inet_addr`, `inet_ntoa`, `getsockname`, `get_errno`
- **Windows helpers**: `WSAStartup`, `WSACleanup`, `WSAGetLastError` (stubbed as no-ops on non-Windows)

## Requirements

- A Fortran compiler with `iso_c_binding` support (gfortran, ifx, etc.)
- Python 3 (only needed for the constant generator script)
- A C compiler in the case you need to regenerate the constants for your platform or toolchain

## Building

Copy the `src/` directory into your project. Compile with the `-cpp` flag to enable preprocessor directives and `-Isrc` (or the path to `src/platform.h`) so the preprocessor can find `platform.h`.

### Linux/macOS

```bash
gfortran -cpp -Isrc src/constants.f90 src/socket_lib.f90 my_program.f90 -o my_program
```

**OR**

```bash
gfortran -cpp src/platform.h src/constants.f90 src/socket_lib.f90 my_program.f90 -o my_program
```

### Windows

```bash
gfortran -cpp -D_WIN32 -Isrc src/constants.f90 src/socket_lib.f90 my_program.f90 -lws2_32 -o my_program.exe
```

**OR**

```bash
gfortran -cpp -D_WIN32 src/platform.h src/constants.f90 src/socket_lib.f90 my_program.f90 -lws2_32 -o my_program.exe
```


> **Note:** On Windows, the `-D_WIN32` flag is required because gfortran's preprocessor does not define Windows platform macros (`_WIN32`, etc.) unlike the C compiler. This flag enables the correct platform-specific code paths.

> **Note:** If you are using a different Fortran compiler that doesn't use gcc as a C compiler, or targeting a different platform than those already in `constants.f90`, you may need to regenerate `constants.f90` using the script in the `tools/` directory. See the [Regenerating constants](#regenerating-constants) section below.

## Usage

Add `use socket_lib` (and optionally `use socket_lib_constants` for extended constants) to your program, then call the API in the same way you would in C.

> On Windows you must call `WSAStartup` before creating sockets and `WSACleanup` when done. The module provides an `is_windows` logical constant you can use to conditionally call these functions. Those functions have been implemented as no-ops on non-Windows platforms so you can safely call them unconditionally if you prefer.

> Use the provided `get_errno` function to retrieve the last socket error code in a portable way, as Windows and POSIX systems expose it differently.

### Minimal TCP server (blocking, single client)

A complete example is available at [examples/example_tcp_server.f90](examples/example_tcp_server.f90). It creates a server on port 8181, waits for a single client to connect, sends a message, waits 5 seconds, and shuts down.

Expected console output on Windows:

```
 Socket created successfully
 Socket options set successfully
 Socket bound successfully to port   8181
 Listening for incoming connections
 Client connected
 Message sent to client, waiting 5 seconds before closing
 Winsock cleaned up successfully
```

On Linux/macOS the output is the same without the Winsock line.

## Regenerating constants

The constants in `constants.f90` are extracted from system headers using GCC. If you use a Fortran compiler that relies on a different C compiler (could be the case for ifx depending on your system) or target a different platform, you will need to regenerate the constant file for your setup and replace the existing `constants.f90`.

### Setting up a different compiler
- Navigate to the `tools/` directory.
- Edit the script `constant_generator.py` to change `gcc` with your compiler name and flags or paths.
- Run the script
- replace the generated `generated_constants.f90` into `src/constants.f90`.

### Targeting a new platform
If you are targeting a new platform, you will need to modify the templates in `tools/` to add the necessary `#include` directives at the beginning of `constant.template.c`, and the platform checks in both `constants.template.c` and `constants.template.f90`. Then you will need to modify the python script to detect the point of insertion of variables in the Fortran template.
Finally you will need to run the script on that platform to generate the correct values and replace the existing `constants.f90` with it.




## Notes & pitfalls

- This is a thin binding. You are responsible for error handling, byte order, and memory safety.
- Use `htons`/`htonl` and `ntohs` to handle network byte order.
- Functions that take pointers expect `c_loc`ed arguments and `target` variables.
- On Windows, link against `ws2_32` and call `WSAStartup`/`WSACleanup`.
- Strings passed to C must be `kind=c_char` and null-terminated.
- To add more socket functions (e.g. `connect`), add their C bindings in the module following the existing patterns.

## Not supported (yet)

- IOCTL / WSAIoctl functions and constants
- Non-blocking sockets and related functions (`select`, `poll`)
- IPv6 structures (`sockaddr_in6`)
- Advanced socket types (`sockaddr_un` for Unix domain sockets)
- Windows-specific features (IOCP)
- Network interface enumeration (`interfaceinfo`)
- Legacy protocols (IPX/SPX, Appletalk)
- all the constants for parameters and return values of most functions are not implemented/unified yet.

## License

MIT. See [LICENSE](LICENSE).
