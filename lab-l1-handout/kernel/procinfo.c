#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "procinfo.h"

extern struct proc proc[NPROC];

uint64 sys_procinfo(void) {
    
    struct proc *p;

    printf("\n");
    for(p = proc; p < &proc[NPROC]; p++){
        if(p->state == UNUSED)
            continue;
        printf("%s (%d): %d", p->name, p->pid, p->state);
        printf("\n");
    }

    //procdump();
    return 0;
}
