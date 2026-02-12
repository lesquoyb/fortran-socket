module socket_lib_constants
    use iso_c_binding
    implicit none


#define IS_WINDOWS (defined(_WIN32) || defined(__WIN32) || defined(WIN32) || defined(__WIN32__))

#if IS_WINDOWS
    ! Define socket constants for Windows systems

#elif defined(__linux__)
    ! Define socket constants for Linux systems

#else
    ! Define socket constants for macOS

#endif


end module socket_lib_constants