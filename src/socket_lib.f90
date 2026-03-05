! MIT License
!
! Copyright (c) 2026 Baptiste Lesquoy
!
! Permission is hereby granted, free of charge, to any person obtaining a copy
! of this software and associated documentation files (the "Software"), to deal
! in the Software without restriction, including without limitation the rights
! to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
! copies of the Software, and to permit persons to whom the Software is
! furnished to do so, subject to the following conditions:
!
! The above copyright notice and this permission notice shall be included in all
! copies or substantial portions of the Software.
!
! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
! IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
! FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
! AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
! LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
! OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
! SOFTWARE.

module socket_lib

    use iso_c_binding
    use socket_lib_constants
    implicit none

#if defined(_WIN32) || defined(__WIN32) || defined(WIN32) || defined(__WIN32__)
#define IS_WINDOWS 1
#else
#define IS_WINDOWS 0
#endif

#if IS_WINDOWS
    logical, parameter :: is_windows = .true.
#else
    logical, parameter :: is_windows = .false.
#endif

    ! TYPES BINDING

    ! Windows-specific: WSADATA structure
    type WSADATA
        integer(c_int) :: wVersion
        integer(c_int) :: wHighVersion
        character(1) :: szDescription(256)
        character(1) :: szSystemStatus(128)
        integer(c_int) :: iMaxSockets
        integer(c_int) :: iMaxUdpDg
        character(1) :: lpVendorInfo
    end type WSADATA

    ! Address structure
    type, bind(C) :: sockaddr_in
        integer(c_int16_t) :: sin_family
        integer(c_int16_t) :: sin_port
        integer(c_int32_t) :: sin_addr
        character(kind=c_char) :: sin_zero(8)  ! Padding
    end type sockaddr_in

    type, bind(C) :: in_addr
        integer(c_int) :: s_addr
    end type in_addr

    ! Function prototypes
    interface
    
#if IS_WINDOWS
        ! Windows specific socket functions
        function WSAStartup(version, data) bind(C, name="WSAStartup")
            import :: c_int, c_ptr
            integer(c_int), value :: version
            type(c_ptr), value :: data
            integer(c_int) :: WSAStartup
        end function
        
        function WSACleanup() bind(C, name="WSACleanup")
            import :: c_int
            integer(c_int) :: WSACleanup
        end function

        function closesocket(sockfd) bind(C, name="closesocket")
            import :: c_int
            integer(c_int), value :: sockfd
            integer(c_int) :: closesocket
        end function

        function ioctlsocket(s, cmd, argp) bind(C, name="ioctlsocket")
            import :: c_int, c_long, c_ptr
            integer(c_int), value :: s
            integer(c_long), value :: cmd
            type(c_ptr), value :: argp
            integer(c_int) :: ioctlsocket
        end function
#endif

        function socket(domain, type, protocol) bind(C, name="socket")
            import :: c_int
            integer(c_int), value :: domain, type, protocol
            integer(c_int) :: socket
        end function

        function bind(sockfd, addr, addrlen) bind(C, name="bind")
            import :: c_int, c_ptr
            integer(c_int), value :: sockfd, addrlen
            type(c_ptr), value :: addr
            integer(c_int) :: bind
        end function

        function listen(sockfd, backlog) bind(C, name="listen")
            import :: c_int
            integer(c_int), value :: sockfd, backlog
            integer(c_int) :: listen
        end function

        function accept(sockfd, addr, addrlen) bind(C, name="accept")
            import :: c_int, c_ptr
            integer(c_int), value :: sockfd
            type(c_ptr), value :: addr
            integer(c_int), value :: addrlen
            integer(c_int) :: accept
        end function

        function send(sockfd, buf, len, flags) bind(C, name="send")
            import :: c_int, c_ptr
            integer(c_int), value :: sockfd, len, flags
            type(c_ptr), value :: buf
            integer(c_int) :: send
        end function

        function close(sockfd) bind(C, name="close")
            import :: c_int
            integer(c_int), value :: sockfd
            integer(c_int) :: close
        end function

        function htons(hostshort) bind(C, name="htons")
            import :: c_int16_t
            integer(c_int16_t), value :: hostshort
            integer(c_int16_t) :: htons
        end function

        function ntohs(n) bind(C, name="ntohs")
            use, intrinsic :: iso_c_binding
            integer(c_int16_t), value :: n
            integer(c_int16_t) :: ntohs
        end function

        function htonl(hostlong) bind(C, name="htonl")
            use iso_c_binding
            integer(c_int), value :: hostlong  ! Input: 32-bit integer in host byte order
            integer(c_int) :: htonl            ! Output: Converted 32-bit integer in network byte order
        end function

#if IS_WINDOWS
        function errno() bind(C, name="_errno")
            import :: c_int
            integer(c_int) :: errno
        end function errno

        function WSAGetLastError() bind(C, name="WSAGetLastError")
            import :: c_int
            integer(c_int) :: WSAGetLastError
        end function
#else
        ! Linux: get errno via __errno_location
        function get_errno_location() bind(C, name="__errno_location")
            import :: c_ptr
            type(c_ptr) :: get_errno_location
        end function get_errno_location
#endif



        function setsockopt(sockfd, level, optname, optval, optlen) bind(C, name="setsockopt")
            use, intrinsic :: iso_c_binding
            integer(c_int), value :: sockfd, level, optname
            type(c_ptr), value :: optval
            integer(c_int), value :: optlen
            integer(c_int) :: setsockopt
        end function

        function inet_addr(cp) bind(C, name="inet_addr")
            use iso_c_binding
            character(kind=c_char), intent(in) :: cp(*)  ! C string (null-terminated)
            integer(c_int) :: inet_addr
        end function

        function recv(sockfd, buf, len, flags) bind(C, name="recv")
            use iso_c_binding
            integer(c_int) :: recv
            integer(c_int), value :: sockfd
            type(c_ptr), value :: buf
            integer(c_int), value :: len
            integer(c_int), value :: flags
        end function recv

        function getsockname(sockfd, addr, addrlen) bind(C, name="getsockname")
            use iso_c_binding
            integer(c_int), value :: sockfd
            type(c_ptr), value :: addr
            integer(c_int), value :: addrlen
            integer(c_int) :: getsockname
        end function getsockname

        type(c_ptr) function inet_ntoa(addr) bind(C, name="inet_ntoa")
            use iso_c_binding
            import :: in_addr
            type(in_addr), intent(in) :: addr 
        end function inet_ntoa

        function connect(sockfd, addr, addrlen) bind(C, name="connect")
            import :: c_int, c_ptr
            integer(c_int), value :: sockfd
            type(c_ptr), value :: addr
            integer(c_int), value :: addrlen
            integer(c_int) :: connect
        end function

        function getpeername(sockfd, addr, addrlen) bind(C, name="getpeername")
            import :: c_int, c_ptr
            integer(c_int), value :: sockfd
            type(c_ptr), value :: addr
            type(c_ptr), value :: addrlen
            integer(c_int) :: getpeername
        end function

        function gethostname(name, namelen) bind(C, name="gethostname")
            import :: c_int, c_char
            character(kind=c_char), intent(out) :: name(*)
            integer(c_int), value :: namelen
            integer(c_int) :: gethostname
        end function

        
    end interface

contains

    ! Get errno in a portable way
    function get_errno() result(err)
        integer(c_int) :: err
#if IS_WINDOWS
        err = errno()
#else
        integer(c_int), pointer :: errno_ptr
        call c_f_pointer(get_errno_location(), errno_ptr)
        err = errno_ptr
#endif
    end function get_errno

#if ! IS_WINDOWS

    ! Stub functions for non-Windows platforms
    function WSAStartup(version, data) result(res)
        integer(c_int), intent(in) :: version
        type(c_ptr), intent(in) :: data
        integer(c_int) :: res
        ! Suppress unused parameter warnings
        if (.false.) then
            print *, version
            print *, transfer(data, 0_c_intptr_t)
        end if
        res = 0  ! Success
    end function WSAStartup
    
    function WSACleanup() result(res)
        integer(c_int) :: res
        res = 0  ! Success
    end function WSACleanup
    
    function WSAGetLastError() result(res)
        integer(c_int) :: res
        res = 0
    end function WSAGetLastError

    function closesocket(sockfd) result(res)
        integer(c_int), intent(in) :: sockfd
        integer(c_int) :: res
        res = close(sockfd)
    end function closesocket

    function ioctlsocket(s, cmd, argp) result(res)
        integer(c_int), intent(in) :: s
        integer(c_long), intent(in) :: cmd
        type(c_ptr), intent(in) :: argp
        integer(c_int) :: res
        ! Stub for non-Windows (use fcntl on POSIX if needed)
        if (.false.) then
            print *, s, cmd
            print *, transfer(argp, 0_c_intptr_t)
        end if
        res = 0
    end function ioctlsocket
#endif


end module socket_lib
