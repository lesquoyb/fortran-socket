module socket_lib_constants
    use iso_c_binding
    implicit none


#if defined(_WIN32) || defined(__WIN32) || defined(WIN32) || defined(__WIN32__)
#define IS_WINDOWS 1
#else
#define IS_WINDOWS 0
#endif

#if IS_WINDOWS
    ! Define socket constants for Windows systems
    ! @CONSTANTS_WINDOWS

#elif defined(__linux__)
    ! Define socket constants for Linux systems
    ! @CONSTANTS_LINUX

#else
    ! Define socket constants for macOS
    ! @CONSTANTS_MACOS

#endif


end module socket_lib_constants