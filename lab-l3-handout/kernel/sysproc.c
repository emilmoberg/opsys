#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    int n;
    argint(0, &n);
    exit(n);
    return 0; // not reached
}

uint64
sys_getpid(void)
{
    return myproc()->pid;
}

uint64
sys_fork(void)
{
    return fork();
}

uint64
sys_wait(void)
{
    uint64 p;
    argaddr(0, &p);
    return wait(p);
}

uint64
sys_sbrk(void)
{
    uint64 addr;
    int n;

    argint(0, &n);
    addr = myproc()->sz;
    if (growproc(n) < 0)
        return -1;
    return addr;
}

uint64
sys_sleep(void)
{
    int n;
    uint ticks0;

    argint(0, &n);
    acquire(&tickslock);
    ticks0 = ticks;
    while (ticks - ticks0 < n)
    {
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    }
    release(&tickslock);
    return 0;
}

uint64
sys_kill(void)
{
    int pid;

    argint(0, &pid);
    return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    uint xticks;

    acquire(&tickslock);
    xticks = ticks;
    release(&tickslock);
    return xticks;
}

void *
sys_ps(void)
{
    int start = 0, count = 0;
    argint(0, &start);
    argint(1, &count);
    return ps((uint8)start, (uint8)count);
}

uint64 sys_schedls(void)
{
    schedls();
    return 0;
}

uint64 sys_schedset(void)
{
    int id = 0;
    argint(0, &id);
    schedset(id - 1);
    return 0;
}

/*uint64 sys_va2pa(void)
{
    printf("TODO: IMPLEMENT ME [%s@%s (line %d)]", __func__, __FILE__, __LINE__);
    return 0;
}*/

extern struct proc proc[NPROC];

uint64 sys_va2pa(void)
{
    
    uint64 va; // Virtual address
    argaddr(0, &va);
    int pid = 0;   // Process ID get from args
    argint(1, &pid);

    struct proc *target_proc = myproc(); // Default to current process

    if (pid != 0) { // If a specific PID is requested
        int found = 0;
        for(struct proc *p = proc; p < &proc[NPROC]; p++) {
            if(p->pid == pid && p->state != UNUSED) {
                target_proc = p;
                found = 1;
                break;
            }
        }
        if (!found) {
            return 0; // PID not found, return 0
        }
    }

    // Walk the page table to find the physical address corresponding to the given virtual address
    pte_t *pte = walk(target_proc->pagetable, va, 0); // 0 to not create
    if(pte == 0 || (*pte & PTE_V) == 0) {
        return 0; // Virtual address not mapped
    }

    uint64 pa = PTE2PA(*pte) | (va & 0xFFF); // Extract physical address and add offset
    
    return pa;
}


uint64 sys_pfreepages(void)
{
    printf("%d\n", FREE_PAGES);
    return 0;
}