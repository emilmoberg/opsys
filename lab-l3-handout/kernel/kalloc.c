// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

uint64 MAX_PAGES = 0;
uint64 FREE_PAGES = 0;

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
    struct run *next;
};

struct
{
    struct spinlock lock;
    struct run *freelist;
} kmem;

void kinit()
{
    initlock(&kmem.lock, "kmem");
    freerange(end, (void *)PHYSTOP);
    MAX_PAGES = FREE_PAGES;
}

void freerange(void *pa_start, void *pa_end)
{
    char *p;
    p = (char *)PGROUNDUP((uint64)pa_start);
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    {
        kfree(p);
    }
}

int counter[(PHYSTOP-KERNBASE)/PGSIZE]; 

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    int i = ((uint64)pa-KERNBASE) /PGSIZE;
    counter[i]--;
    kfree(pa);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    void * pointer = kalloc();
    if(counter[((uint64)pointer-KERNBASE )/PGSIZE]==0 && (uint64)pointer!=0){
        counter[((uint64)pointer-KERNBASE )/ PGSIZE]++;
    }
    return pointer;
}

void refinc(void *pa){
    counter[((uint64)pa-KERNBASE )/ PGSIZE]++;
}

void refdec(void *pa){
    counter[((uint64)pa-KERNBASE )/ PGSIZE]--;
}