#if defined(_WIN32) || defined(__WIN32) || defined(WIN32)

#include <winsock2.h>
#include <Ws2tcpip.h>
#include <Wsrm.h>
#include <Wsnwlink.h>
#include <Mswsock.h>
#include <AF_Irda.h>

#elif defined(__linux__)

#include <sys/types.h>
#include <sys/socket.h>   // socket API + AF_* SOCK_* SO_* MSG_* SHUT_*
#include <netinet/in.h>   // sockaddr_in, sockaddr_in6, IPPROTO_*, INADDR_*, IPV6_*
#include <netinet/tcp.h>  // TCP_* options (TCP_NODELAY, TCP_KEEPIDLE, etc.)
#include <arpa/inet.h>    // inet_pton, inet_ntop, htonl, htons, ...
#include <netdb.h>        // getaddrinfo, getnameinfo, AI_*, NI_*, EAI_*
#include <unistd.h>       // close, read, write
#include <errno.h>        // errno

#else 
#include <sys/types.h>
#include <sys/socket.h>     // socket API + AF_* SOCK_* SO_* MSG_* SHUT_*
#include <netinet/in.h>     // sockaddr_in, sockaddr_in6, IPPROTO_*, INADDR_*, IPV6_*
#include <netinet/tcp.h>    // TCP_* options (TCP_NODELAY, TCP_KEEPIDLE, etc.)
#include <arpa/inet.h>      // inet_pton, inet_ntop, htonl, htons, ...
#include <netdb.h>          // getaddrinfo, getnameinfo, AI_*, NI_*, EAI_*
#include <sys/un.h>         // sockaddr_un, AF_UNIX
#include <sys/event.h>      // kqueue
#include <unistd.h>         // close, read, write
#include <errno.h>          // errno
#endif


#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <output_file>\n", argv[0]);
        exit(1);
    }

    FILE* fptr;

    fptr = fopen(argv[1], "w");   
    if (fptr == NULL) {
        printf("Error opening file '%s'!\n", argv[1]);
        exit(1);
    }

    // Line to duplicate for every constant
    fprintf(fptr, "integer(c_int), parameter :: [var_name] = %d\n", [var_name]);

    printf("Constants file generated successfully.\n");

    fclose(fptr);
    return 0;

}