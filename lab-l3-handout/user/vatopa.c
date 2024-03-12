#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
    if(argc < 2 || argc > 3) {
        printf("Usage: vatopa virtual_address [pid]\n");
        exit(0);
    }

    uint64 addr = atoi(argv[1]); // Convert the virtual address from string to int
    int pid = argc == 3 ? atoi(argv[2]) : getpid(); // If pid is not provided, use current process's pid

    uint64 pa = va2pa(addr, pid); // Call the va2pa system call

    printf("0x%x\n", pa);

    exit(0);
}
