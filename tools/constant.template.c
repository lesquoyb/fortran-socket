#include <winsock2.h>
#include <Ws2tcpip.h>
#include <stdio.h>
#include <stdlib.h>
#include <Wsrm.h>
#include <Wsnwlink.h>
#include <Mswsock.h>
#include <AF_Irda.h>

int main() {
    FILE* fptr;

    fptr = fopen("tmp_constants.windows.f90", "w");   
    if (fptr == NULL) {
        printf("Error opening file!");
        exit(1);
    }

    // Line to duplicate for every constant
    fprintf(fptr, "integer(c_int), parameter :: [var_name] = %d\n", [var_name]);

    printf("Constants file generated successfully.\n");

    fclose(fptr);
    return 0;

}