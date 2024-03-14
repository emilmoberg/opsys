
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3013103          	ld	sp,-1488(sp) # 80008a30 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	a5070713          	addi	a4,a4,-1456 # 80008aa0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	2ee78793          	addi	a5,a5,750 # 80006350 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffbc8ef>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f5878793          	addi	a5,a5,-168 # 80001004 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	7f6080e7          	jalr	2038(ra) # 80002920 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	796080e7          	jalr	1942(ra) # 800008d0 <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000186:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	a5650513          	addi	a0,a0,-1450 # 80010be0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	bd0080e7          	jalr	-1072(ra) # 80000d62 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	a4648493          	addi	s1,s1,-1466 # 80010be0 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	ad690913          	addi	s2,s2,-1322 # 80010c78 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D'))
    800001aa:	4b91                	li	s7,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
            break;

        dst++;
        --n;

        if (c == '\n')
    800001ae:	4ca9                	li	s9,10
    while (n > 0)
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
        while (cons.r == cons.w)
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
            if (killed(myproc()))
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	b54080e7          	jalr	-1196(ra) # 80001d14 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	5a2080e7          	jalr	1442(ra) # 8000276a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	2ec080e7          	jalr	748(ra) # 800024c2 <sleep>
        while (cons.r == cons.w)
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
        if (c == C('D'))
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
        cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	6b8080e7          	jalr	1720(ra) # 800028ca <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1
        if (c == '\n')
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	9ba50513          	addi	a0,a0,-1606 # 80010be0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	be8080e7          	jalr	-1048(ra) # 80000e16 <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	9a450513          	addi	a0,a0,-1628 # 80010be0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	bd2080e7          	jalr	-1070(ra) # 80000e16 <release>
                return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
            if (n < target)
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
                cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	a0f72323          	sw	a5,-1530(a4) # 80010c78 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
        uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	572080e7          	jalr	1394(ra) # 800007fe <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	560080e7          	jalr	1376(ra) # 800007fe <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	554080e7          	jalr	1364(ra) # 800007fe <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	54a080e7          	jalr	1354(ra) # 800007fe <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	91450513          	addi	a0,a0,-1772 # 80010be0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a8e080e7          	jalr	-1394(ra) # 80000d62 <acquire>

    switch (c)
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	684080e7          	jalr	1668(ra) # 80002976 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	8e650513          	addi	a0,a0,-1818 # 80010be0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b14080e7          	jalr	-1260(ra) # 80000e16 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
    switch (c)
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	8c270713          	addi	a4,a4,-1854 # 80010be0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
            consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	89878793          	addi	a5,a5,-1896 # 80010be0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	9027a783          	lw	a5,-1790(a5) # 80010c78 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	85670713          	addi	a4,a4,-1962 # 80010be0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	84648493          	addi	s1,s1,-1978 # 80010be0 <cons>
        while (cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
            cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
        while (cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	80a70713          	addi	a4,a4,-2038 # 80010be0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	88f72a23          	sw	a5,-1900(a4) # 80010c80 <cons+0xa0>
            consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
            consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	7ce78793          	addi	a5,a5,1998 # 80010be0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	84c7a323          	sw	a2,-1978(a5) # 80010c7c <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	83a50513          	addi	a0,a0,-1990 # 80010c78 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	0e0080e7          	jalr	224(ra) # 80002526 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bc858593          	addi	a1,a1,-1080 # 80008020 <__func__.1+0x18>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	78050513          	addi	a0,a0,1920 # 80010be0 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	86a080e7          	jalr	-1942(ra) # 80000cd2 <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	33e080e7          	jalr	830(ra) # 800007ae <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00041797          	auipc	a5,0x41
    8000047c:	90078793          	addi	a5,a5,-1792 # 80040d78 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
    char buf[16];
    int i;
    uint x;

    if (sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
        x = -xx;
    else
        x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

    i = 0;
    800004b6:	4701                	li	a4,0
    do
    {
        buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b9660613          	addi	a2,a2,-1130 # 80008050 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

    if (sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
        buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
        consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
    while (--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
        x = -xx;
    80000538:	40a0053b          	negw	a0,a0
    if (sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
        x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    80000540:	711d                	addi	sp,sp,-96
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
    8000054c:	e40c                	sd	a1,8(s0)
    8000054e:	e810                	sd	a2,16(s0)
    80000550:	ec14                	sd	a3,24(s0)
    80000552:	f018                	sd	a4,32(s0)
    80000554:	f41c                	sd	a5,40(s0)
    80000556:	03043823          	sd	a6,48(s0)
    8000055a:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    8000055e:	00010797          	auipc	a5,0x10
    80000562:	7407a123          	sw	zero,1858(a5) # 80010ca0 <pr+0x18>
    printf("panic: ");
    80000566:	00008517          	auipc	a0,0x8
    8000056a:	ac250513          	addi	a0,a0,-1342 # 80008028 <__func__.1+0x20>
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	02e080e7          	jalr	46(ra) # 8000059c <printf>
    printf(s);
    80000576:	8526                	mv	a0,s1
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	024080e7          	jalr	36(ra) # 8000059c <printf>
    printf("\n");
    80000580:	00008517          	auipc	a0,0x8
    80000584:	b0850513          	addi	a0,a0,-1272 # 80008088 <digits+0x38>
    80000588:	00000097          	auipc	ra,0x0
    8000058c:	014080e7          	jalr	20(ra) # 8000059c <printf>
    panicked = 1; // freeze uart output from other CPUs
    80000590:	4785                	li	a5,1
    80000592:	00008717          	auipc	a4,0x8
    80000596:	4af72f23          	sw	a5,1214(a4) # 80008a50 <panicked>
    for (;;)
    8000059a:	a001                	j	8000059a <panic+0x5a>

000000008000059c <printf>:
{
    8000059c:	7131                	addi	sp,sp,-192
    8000059e:	fc86                	sd	ra,120(sp)
    800005a0:	f8a2                	sd	s0,112(sp)
    800005a2:	f4a6                	sd	s1,104(sp)
    800005a4:	f0ca                	sd	s2,96(sp)
    800005a6:	ecce                	sd	s3,88(sp)
    800005a8:	e8d2                	sd	s4,80(sp)
    800005aa:	e4d6                	sd	s5,72(sp)
    800005ac:	e0da                	sd	s6,64(sp)
    800005ae:	fc5e                	sd	s7,56(sp)
    800005b0:	f862                	sd	s8,48(sp)
    800005b2:	f466                	sd	s9,40(sp)
    800005b4:	f06a                	sd	s10,32(sp)
    800005b6:	ec6e                	sd	s11,24(sp)
    800005b8:	0100                	addi	s0,sp,128
    800005ba:	8a2a                	mv	s4,a0
    800005bc:	e40c                	sd	a1,8(s0)
    800005be:	e810                	sd	a2,16(s0)
    800005c0:	ec14                	sd	a3,24(s0)
    800005c2:	f018                	sd	a4,32(s0)
    800005c4:	f41c                	sd	a5,40(s0)
    800005c6:	03043823          	sd	a6,48(s0)
    800005ca:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005ce:	00010d97          	auipc	s11,0x10
    800005d2:	6d2dad83          	lw	s11,1746(s11) # 80010ca0 <pr+0x18>
    if (locking)
    800005d6:	020d9b63          	bnez	s11,8000060c <printf+0x70>
    if (fmt == 0)
    800005da:	040a0263          	beqz	s4,8000061e <printf+0x82>
    va_start(ap, fmt);
    800005de:	00840793          	addi	a5,s0,8
    800005e2:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005e6:	000a4503          	lbu	a0,0(s4)
    800005ea:	14050f63          	beqz	a0,80000748 <printf+0x1ac>
    800005ee:	4981                	li	s3,0
        if (c != '%')
    800005f0:	02500a93          	li	s5,37
        switch (c)
    800005f4:	07000b93          	li	s7,112
    consputc('x');
    800005f8:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005fa:	00008b17          	auipc	s6,0x8
    800005fe:	a56b0b13          	addi	s6,s6,-1450 # 80008050 <digits>
        switch (c)
    80000602:	07300c93          	li	s9,115
    80000606:	06400c13          	li	s8,100
    8000060a:	a82d                	j	80000644 <printf+0xa8>
        acquire(&pr.lock);
    8000060c:	00010517          	auipc	a0,0x10
    80000610:	67c50513          	addi	a0,a0,1660 # 80010c88 <pr>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	74e080e7          	jalr	1870(ra) # 80000d62 <acquire>
    8000061c:	bf7d                	j	800005da <printf+0x3e>
        panic("null fmt");
    8000061e:	00008517          	auipc	a0,0x8
    80000622:	a1a50513          	addi	a0,a0,-1510 # 80008038 <__func__.1+0x30>
    80000626:	00000097          	auipc	ra,0x0
    8000062a:	f1a080e7          	jalr	-230(ra) # 80000540 <panic>
            consputc(c);
    8000062e:	00000097          	auipc	ra,0x0
    80000632:	c4e080e7          	jalr	-946(ra) # 8000027c <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c503          	lbu	a0,0(a5)
    80000640:	10050463          	beqz	a0,80000748 <printf+0x1ac>
        if (c != '%')
    80000644:	ff5515e3          	bne	a0,s5,8000062e <printf+0x92>
        c = fmt[++i] & 0xff;
    80000648:	2985                	addiw	s3,s3,1
    8000064a:	013a07b3          	add	a5,s4,s3
    8000064e:	0007c783          	lbu	a5,0(a5)
    80000652:	0007849b          	sext.w	s1,a5
        if (c == 0)
    80000656:	cbed                	beqz	a5,80000748 <printf+0x1ac>
        switch (c)
    80000658:	05778a63          	beq	a5,s7,800006ac <printf+0x110>
    8000065c:	02fbf663          	bgeu	s7,a5,80000688 <printf+0xec>
    80000660:	09978863          	beq	a5,s9,800006f0 <printf+0x154>
    80000664:	07800713          	li	a4,120
    80000668:	0ce79563          	bne	a5,a4,80000732 <printf+0x196>
            printint(va_arg(ap, int), 16, 1);
    8000066c:	f8843783          	ld	a5,-120(s0)
    80000670:	00878713          	addi	a4,a5,8
    80000674:	f8e43423          	sd	a4,-120(s0)
    80000678:	4605                	li	a2,1
    8000067a:	85ea                	mv	a1,s10
    8000067c:	4388                	lw	a0,0(a5)
    8000067e:	00000097          	auipc	ra,0x0
    80000682:	e1e080e7          	jalr	-482(ra) # 8000049c <printint>
            break;
    80000686:	bf45                	j	80000636 <printf+0x9a>
        switch (c)
    80000688:	09578f63          	beq	a5,s5,80000726 <printf+0x18a>
    8000068c:	0b879363          	bne	a5,s8,80000732 <printf+0x196>
            printint(va_arg(ap, int), 10, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	4605                	li	a2,1
    8000069e:	45a9                	li	a1,10
    800006a0:	4388                	lw	a0,0(a5)
    800006a2:	00000097          	auipc	ra,0x0
    800006a6:	dfa080e7          	jalr	-518(ra) # 8000049c <printint>
            break;
    800006aa:	b771                	j	80000636 <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006ac:	f8843783          	ld	a5,-120(s0)
    800006b0:	00878713          	addi	a4,a5,8
    800006b4:	f8e43423          	sd	a4,-120(s0)
    800006b8:	0007b903          	ld	s2,0(a5)
    consputc('0');
    800006bc:	03000513          	li	a0,48
    800006c0:	00000097          	auipc	ra,0x0
    800006c4:	bbc080e7          	jalr	-1092(ra) # 8000027c <consputc>
    consputc('x');
    800006c8:	07800513          	li	a0,120
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
    800006d4:	84ea                	mv	s1,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d6:	03c95793          	srli	a5,s2,0x3c
    800006da:	97da                	add	a5,a5,s6
    800006dc:	0007c503          	lbu	a0,0(a5)
    800006e0:	00000097          	auipc	ra,0x0
    800006e4:	b9c080e7          	jalr	-1124(ra) # 8000027c <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e8:	0912                	slli	s2,s2,0x4
    800006ea:	34fd                	addiw	s1,s1,-1
    800006ec:	f4ed                	bnez	s1,800006d6 <printf+0x13a>
    800006ee:	b7a1                	j	80000636 <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	6384                	ld	s1,0(a5)
    800006fe:	cc89                	beqz	s1,80000718 <printf+0x17c>
            for (; *s; s++)
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	d90d                	beqz	a0,80000636 <printf+0x9a>
                consputc(*s);
    80000706:	00000097          	auipc	ra,0x0
    8000070a:	b76080e7          	jalr	-1162(ra) # 8000027c <consputc>
            for (; *s; s++)
    8000070e:	0485                	addi	s1,s1,1
    80000710:	0004c503          	lbu	a0,0(s1)
    80000714:	f96d                	bnez	a0,80000706 <printf+0x16a>
    80000716:	b705                	j	80000636 <printf+0x9a>
                s = "(null)";
    80000718:	00008497          	auipc	s1,0x8
    8000071c:	91848493          	addi	s1,s1,-1768 # 80008030 <__func__.1+0x28>
            for (; *s; s++)
    80000720:	02800513          	li	a0,40
    80000724:	b7cd                	j	80000706 <printf+0x16a>
            consputc('%');
    80000726:	8556                	mv	a0,s5
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b54080e7          	jalr	-1196(ra) # 8000027c <consputc>
            break;
    80000730:	b719                	j	80000636 <printf+0x9a>
            consputc('%');
    80000732:	8556                	mv	a0,s5
    80000734:	00000097          	auipc	ra,0x0
    80000738:	b48080e7          	jalr	-1208(ra) # 8000027c <consputc>
            consputc(c);
    8000073c:	8526                	mv	a0,s1
    8000073e:	00000097          	auipc	ra,0x0
    80000742:	b3e080e7          	jalr	-1218(ra) # 8000027c <consputc>
            break;
    80000746:	bdc5                	j	80000636 <printf+0x9a>
    if (locking)
    80000748:	020d9163          	bnez	s11,8000076a <printf+0x1ce>
}
    8000074c:	70e6                	ld	ra,120(sp)
    8000074e:	7446                	ld	s0,112(sp)
    80000750:	74a6                	ld	s1,104(sp)
    80000752:	7906                	ld	s2,96(sp)
    80000754:	69e6                	ld	s3,88(sp)
    80000756:	6a46                	ld	s4,80(sp)
    80000758:	6aa6                	ld	s5,72(sp)
    8000075a:	6b06                	ld	s6,64(sp)
    8000075c:	7be2                	ld	s7,56(sp)
    8000075e:	7c42                	ld	s8,48(sp)
    80000760:	7ca2                	ld	s9,40(sp)
    80000762:	7d02                	ld	s10,32(sp)
    80000764:	6de2                	ld	s11,24(sp)
    80000766:	6129                	addi	sp,sp,192
    80000768:	8082                	ret
        release(&pr.lock);
    8000076a:	00010517          	auipc	a0,0x10
    8000076e:	51e50513          	addi	a0,a0,1310 # 80010c88 <pr>
    80000772:	00000097          	auipc	ra,0x0
    80000776:	6a4080e7          	jalr	1700(ra) # 80000e16 <release>
}
    8000077a:	bfc9                	j	8000074c <printf+0x1b0>

000000008000077c <printfinit>:
        ;
}

void printfinit(void)
{
    8000077c:	1101                	addi	sp,sp,-32
    8000077e:	ec06                	sd	ra,24(sp)
    80000780:	e822                	sd	s0,16(sp)
    80000782:	e426                	sd	s1,8(sp)
    80000784:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000786:	00010497          	auipc	s1,0x10
    8000078a:	50248493          	addi	s1,s1,1282 # 80010c88 <pr>
    8000078e:	00008597          	auipc	a1,0x8
    80000792:	8ba58593          	addi	a1,a1,-1862 # 80008048 <__func__.1+0x40>
    80000796:	8526                	mv	a0,s1
    80000798:	00000097          	auipc	ra,0x0
    8000079c:	53a080e7          	jalr	1338(ra) # 80000cd2 <initlock>
    pr.locking = 1;
    800007a0:	4785                	li	a5,1
    800007a2:	cc9c                	sw	a5,24(s1)
}
    800007a4:	60e2                	ld	ra,24(sp)
    800007a6:	6442                	ld	s0,16(sp)
    800007a8:	64a2                	ld	s1,8(sp)
    800007aa:	6105                	addi	sp,sp,32
    800007ac:	8082                	ret

00000000800007ae <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007ae:	1141                	addi	sp,sp,-16
    800007b0:	e406                	sd	ra,8(sp)
    800007b2:	e022                	sd	s0,0(sp)
    800007b4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b6:	100007b7          	lui	a5,0x10000
    800007ba:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007be:	f8000713          	li	a4,-128
    800007c2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c6:	470d                	li	a4,3
    800007c8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007cc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d4:	469d                	li	a3,7
    800007d6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007da:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007de:	00008597          	auipc	a1,0x8
    800007e2:	88a58593          	addi	a1,a1,-1910 # 80008068 <digits+0x18>
    800007e6:	00010517          	auipc	a0,0x10
    800007ea:	4c250513          	addi	a0,a0,1218 # 80010ca8 <uart_tx_lock>
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	4e4080e7          	jalr	1252(ra) # 80000cd2 <initlock>
}
    800007f6:	60a2                	ld	ra,8(sp)
    800007f8:	6402                	ld	s0,0(sp)
    800007fa:	0141                	addi	sp,sp,16
    800007fc:	8082                	ret

00000000800007fe <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fe:	1101                	addi	sp,sp,-32
    80000800:	ec06                	sd	ra,24(sp)
    80000802:	e822                	sd	s0,16(sp)
    80000804:	e426                	sd	s1,8(sp)
    80000806:	1000                	addi	s0,sp,32
    80000808:	84aa                	mv	s1,a0
  push_off();
    8000080a:	00000097          	auipc	ra,0x0
    8000080e:	50c080e7          	jalr	1292(ra) # 80000d16 <push_off>

  if(panicked){
    80000812:	00008797          	auipc	a5,0x8
    80000816:	23e7a783          	lw	a5,574(a5) # 80008a50 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081e:	c391                	beqz	a5,80000822 <uartputc_sync+0x24>
    for(;;)
    80000820:	a001                	j	80000820 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000822:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dfe5                	beqz	a5,80000822 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f513          	zext.b	a0,s1
    80000830:	100007b7          	lui	a5,0x10000
    80000834:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	57e080e7          	jalr	1406(ra) # 80000db6 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	20e7b783          	ld	a5,526(a5) # 80008a58 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	20e73703          	ld	a4,526(a4) # 80008a60 <uart_tx_w>
    8000085a:	06f70a63          	beq	a4,a5,800008ce <uartstart+0x84>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000874:	00010a17          	auipc	s4,0x10
    80000878:	434a0a13          	addi	s4,s4,1076 # 80010ca8 <uart_tx_lock>
    uart_tx_r += 1;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	1dc48493          	addi	s1,s1,476 # 80008a58 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	1dc98993          	addi	s3,s3,476 # 80008a60 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	02077713          	andi	a4,a4,32
    80000894:	c705                	beqz	a4,800008bc <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f7f713          	andi	a4,a5,31
    8000089a:	9752                	add	a4,a4,s4
    8000089c:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    800008a0:	0785                	addi	a5,a5,1
    800008a2:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	c80080e7          	jalr	-896(ra) # 80002526 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	609c                	ld	a5,0(s1)
    800008b4:	0009b703          	ld	a4,0(s3)
    800008b8:	fcf71ae3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	3c650513          	addi	a0,a0,966 # 80010ca8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	478080e7          	jalr	1144(ra) # 80000d62 <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	15e7a783          	lw	a5,350(a5) # 80008a50 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008717          	auipc	a4,0x8
    80000900:	16473703          	ld	a4,356(a4) # 80008a60 <uart_tx_w>
    80000904:	00008797          	auipc	a5,0x8
    80000908:	1547b783          	ld	a5,340(a5) # 80008a58 <uart_tx_r>
    8000090c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010997          	auipc	s3,0x10
    80000914:	39898993          	addi	s3,s3,920 # 80010ca8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	14048493          	addi	s1,s1,320 # 80008a58 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	14090913          	addi	s2,s2,320 # 80008a60 <uart_tx_w>
    80000928:	00e79f63          	bne	a5,a4,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85ce                	mv	a1,s3
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	b92080e7          	jalr	-1134(ra) # 800024c2 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093703          	ld	a4,0(s2)
    8000093c:	609c                	ld	a5,0(s1)
    8000093e:	02078793          	addi	a5,a5,32
    80000942:	fee785e3          	beq	a5,a4,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	36248493          	addi	s1,s1,866 # 80010ca8 <uart_tx_lock>
    8000094e:	01f77793          	andi	a5,a4,31
    80000952:	97a6                	add	a5,a5,s1
    80000954:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000958:	0705                	addi	a4,a4,1
    8000095a:	00008797          	auipc	a5,0x8
    8000095e:	10e7b323          	sd	a4,262(a5) # 80008a60 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee8080e7          	jalr	-280(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	4aa080e7          	jalr	1194(ra) # 80000e16 <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb81                	beqz	a5,800009a6 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a0:	6422                	ld	s0,8(sp)
    800009a2:	0141                	addi	sp,sp,16
    800009a4:	8082                	ret
    return -1;
    800009a6:	557d                	li	a0,-1
    800009a8:	bfe5                	j	800009a0 <uartgetc+0x1a>

00000000800009aa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009aa:	1101                	addi	sp,sp,-32
    800009ac:	ec06                	sd	ra,24(sp)
    800009ae:	e822                	sd	s0,16(sp)
    800009b0:	e426                	sd	s1,8(sp)
    800009b2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b4:	54fd                	li	s1,-1
    800009b6:	a029                	j	800009c0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009b8:	00000097          	auipc	ra,0x0
    800009bc:	906080e7          	jalr	-1786(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	fc6080e7          	jalr	-58(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c8:	fe9518e3          	bne	a0,s1,800009b8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009cc:	00010497          	auipc	s1,0x10
    800009d0:	2dc48493          	addi	s1,s1,732 # 80010ca8 <uart_tx_lock>
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	38c080e7          	jalr	908(ra) # 80000d62 <acquire>
  uartstart();
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	e6c080e7          	jalr	-404(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    800009e6:	8526                	mv	a0,s1
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	42e080e7          	jalr	1070(ra) # 80000e16 <release>
}
    800009f0:	60e2                	ld	ra,24(sp)
    800009f2:	6442                	ld	s0,16(sp)
    800009f4:	64a2                	ld	s1,8(sp)
    800009f6:	6105                	addi	sp,sp,32
    800009f8:	8082                	ret

00000000800009fa <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	e04a                	sd	s2,0(sp)
    80000a04:	1000                	addi	s0,sp,32
    80000a06:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0)
    80000a08:	00008797          	auipc	a5,0x8
    80000a0c:	0687b783          	ld	a5,104(a5) # 80008a70 <MAX_PAGES>
    80000a10:	c799                	beqz	a5,80000a1e <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a12:	00008717          	auipc	a4,0x8
    80000a16:	05673703          	ld	a4,86(a4) # 80008a68 <FREE_PAGES>
    80000a1a:	06f77663          	bgeu	a4,a5,80000a86 <kfree+0x8c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03449793          	slli	a5,s1,0x34
    80000a22:	efc1                	bnez	a5,80000aba <kfree+0xc0>
    80000a24:	00041797          	auipc	a5,0x41
    80000a28:	4ec78793          	addi	a5,a5,1260 # 80041f10 <end>
    80000a2c:	08f4e763          	bltu	s1,a5,80000aba <kfree+0xc0>
    80000a30:	47c5                	li	a5,17
    80000a32:	07ee                	slli	a5,a5,0x1b
    80000a34:	08f4f363          	bgeu	s1,a5,80000aba <kfree+0xc0>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a38:	6605                	lui	a2,0x1
    80000a3a:	4585                	li	a1,1
    80000a3c:	8526                	mv	a0,s1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	420080e7          	jalr	1056(ra) # 80000e5e <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a46:	00010917          	auipc	s2,0x10
    80000a4a:	29a90913          	addi	s2,s2,666 # 80010ce0 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	312080e7          	jalr	786(ra) # 80000d62 <acquire>
    r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a62:	00008717          	auipc	a4,0x8
    80000a66:	00670713          	addi	a4,a4,6 # 80008a68 <FREE_PAGES>
    80000a6a:	631c                	ld	a5,0(a4)
    80000a6c:	0785                	addi	a5,a5,1
    80000a6e:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000a70:	854a                	mv	a0,s2
    80000a72:	00000097          	auipc	ra,0x0
    80000a76:	3a4080e7          	jalr	932(ra) # 80000e16 <release>

}
    80000a7a:	60e2                	ld	ra,24(sp)
    80000a7c:	6442                	ld	s0,16(sp)
    80000a7e:	64a2                	ld	s1,8(sp)
    80000a80:	6902                	ld	s2,0(sp)
    80000a82:	6105                	addi	sp,sp,32
    80000a84:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000a86:	03700693          	li	a3,55
    80000a8a:	00007617          	auipc	a2,0x7
    80000a8e:	57e60613          	addi	a2,a2,1406 # 80008008 <__func__.1>
    80000a92:	00007597          	auipc	a1,0x7
    80000a96:	5de58593          	addi	a1,a1,1502 # 80008070 <digits+0x20>
    80000a9a:	00007517          	auipc	a0,0x7
    80000a9e:	5e650513          	addi	a0,a0,1510 # 80008080 <digits+0x30>
    80000aa2:	00000097          	auipc	ra,0x0
    80000aa6:	afa080e7          	jalr	-1286(ra) # 8000059c <printf>
    80000aaa:	00007517          	auipc	a0,0x7
    80000aae:	5e650513          	addi	a0,a0,1510 # 80008090 <digits+0x40>
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	a8e080e7          	jalr	-1394(ra) # 80000540 <panic>
        panic("kfree");
    80000aba:	00007517          	auipc	a0,0x7
    80000abe:	5e650513          	addi	a0,a0,1510 # 800080a0 <digits+0x50>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	a7e080e7          	jalr	-1410(ra) # 80000540 <panic>

0000000080000aca <freerange>:
{
    80000aca:	7179                	addi	sp,sp,-48
    80000acc:	f406                	sd	ra,40(sp)
    80000ace:	f022                	sd	s0,32(sp)
    80000ad0:	ec26                	sd	s1,24(sp)
    80000ad2:	e84a                	sd	s2,16(sp)
    80000ad4:	e44e                	sd	s3,8(sp)
    80000ad6:	e052                	sd	s4,0(sp)
    80000ad8:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000ada:	6785                	lui	a5,0x1
    80000adc:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae0:	00e504b3          	add	s1,a0,a4
    80000ae4:	777d                	lui	a4,0xfffff
    80000ae6:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ae8:	94be                	add	s1,s1,a5
    80000aea:	0095ee63          	bltu	a1,s1,80000b06 <freerange+0x3c>
    80000aee:	892e                	mv	s2,a1
        kfree(p);
    80000af0:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000af2:	6985                	lui	s3,0x1
        kfree(p);
    80000af4:	01448533          	add	a0,s1,s4
    80000af8:	00000097          	auipc	ra,0x0
    80000afc:	f02080e7          	jalr	-254(ra) # 800009fa <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b00:	94ce                	add	s1,s1,s3
    80000b02:	fe9979e3          	bgeu	s2,s1,80000af4 <freerange+0x2a>
}
    80000b06:	70a2                	ld	ra,40(sp)
    80000b08:	7402                	ld	s0,32(sp)
    80000b0a:	64e2                	ld	s1,24(sp)
    80000b0c:	6942                	ld	s2,16(sp)
    80000b0e:	69a2                	ld	s3,8(sp)
    80000b10:	6a02                	ld	s4,0(sp)
    80000b12:	6145                	addi	sp,sp,48
    80000b14:	8082                	ret

0000000080000b16 <kinit>:
{
    80000b16:	1141                	addi	sp,sp,-16
    80000b18:	e406                	sd	ra,8(sp)
    80000b1a:	e022                	sd	s0,0(sp)
    80000b1c:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b1e:	00007597          	auipc	a1,0x7
    80000b22:	58a58593          	addi	a1,a1,1418 # 800080a8 <digits+0x58>
    80000b26:	00010517          	auipc	a0,0x10
    80000b2a:	1ba50513          	addi	a0,a0,442 # 80010ce0 <kmem>
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1a4080e7          	jalr	420(ra) # 80000cd2 <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b36:	45c5                	li	a1,17
    80000b38:	05ee                	slli	a1,a1,0x1b
    80000b3a:	00041517          	auipc	a0,0x41
    80000b3e:	3d650513          	addi	a0,a0,982 # 80041f10 <end>
    80000b42:	00000097          	auipc	ra,0x0
    80000b46:	f88080e7          	jalr	-120(ra) # 80000aca <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b4a:	00008797          	auipc	a5,0x8
    80000b4e:	f1e7b783          	ld	a5,-226(a5) # 80008a68 <FREE_PAGES>
    80000b52:	00008717          	auipc	a4,0x8
    80000b56:	f0f73f23          	sd	a5,-226(a4) # 80008a70 <MAX_PAGES>
}
    80000b5a:	60a2                	ld	ra,8(sp)
    80000b5c:	6402                	ld	s0,0(sp)
    80000b5e:	0141                	addi	sp,sp,16
    80000b60:	8082                	ret

0000000080000b62 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b62:	1101                	addi	sp,sp,-32
    80000b64:	ec06                	sd	ra,24(sp)
    80000b66:	e822                	sd	s0,16(sp)
    80000b68:	e426                	sd	s1,8(sp)
    80000b6a:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000b6c:	00008797          	auipc	a5,0x8
    80000b70:	efc7b783          	ld	a5,-260(a5) # 80008a68 <FREE_PAGES>
    80000b74:	cbb1                	beqz	a5,80000bc8 <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000b76:	00010497          	auipc	s1,0x10
    80000b7a:	16a48493          	addi	s1,s1,362 # 80010ce0 <kmem>
    80000b7e:	8526                	mv	a0,s1
    80000b80:	00000097          	auipc	ra,0x0
    80000b84:	1e2080e7          	jalr	482(ra) # 80000d62 <acquire>
    r = kmem.freelist;
    80000b88:	6c84                	ld	s1,24(s1)
    if (r)
    80000b8a:	c8ad                	beqz	s1,80000bfc <kalloc+0x9a>
        kmem.freelist = r->next;
    80000b8c:	609c                	ld	a5,0(s1)
    80000b8e:	00010517          	auipc	a0,0x10
    80000b92:	15250513          	addi	a0,a0,338 # 80010ce0 <kmem>
    80000b96:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	27e080e7          	jalr	638(ra) # 80000e16 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000ba0:	6605                	lui	a2,0x1
    80000ba2:	4595                	li	a1,5
    80000ba4:	8526                	mv	a0,s1
    80000ba6:	00000097          	auipc	ra,0x0
    80000baa:	2b8080e7          	jalr	696(ra) # 80000e5e <memset>
    FREE_PAGES--;
    80000bae:	00008717          	auipc	a4,0x8
    80000bb2:	eba70713          	addi	a4,a4,-326 # 80008a68 <FREE_PAGES>
    80000bb6:	631c                	ld	a5,0(a4)
    80000bb8:	17fd                	addi	a5,a5,-1
    80000bba:	e31c                	sd	a5,0(a4)
    return (void *)r;

}
    80000bbc:	8526                	mv	a0,s1
    80000bbe:	60e2                	ld	ra,24(sp)
    80000bc0:	6442                	ld	s0,16(sp)
    80000bc2:	64a2                	ld	s1,8(sp)
    80000bc4:	6105                	addi	sp,sp,32
    80000bc6:	8082                	ret
    assert(FREE_PAGES > 0);
    80000bc8:	05000693          	li	a3,80
    80000bcc:	00007617          	auipc	a2,0x7
    80000bd0:	43460613          	addi	a2,a2,1076 # 80008000 <etext>
    80000bd4:	00007597          	auipc	a1,0x7
    80000bd8:	49c58593          	addi	a1,a1,1180 # 80008070 <digits+0x20>
    80000bdc:	00007517          	auipc	a0,0x7
    80000be0:	4a450513          	addi	a0,a0,1188 # 80008080 <digits+0x30>
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	9b8080e7          	jalr	-1608(ra) # 8000059c <printf>
    80000bec:	00007517          	auipc	a0,0x7
    80000bf0:	4a450513          	addi	a0,a0,1188 # 80008090 <digits+0x40>
    80000bf4:	00000097          	auipc	ra,0x0
    80000bf8:	94c080e7          	jalr	-1716(ra) # 80000540 <panic>
    release(&kmem.lock);
    80000bfc:	00010517          	auipc	a0,0x10
    80000c00:	0e450513          	addi	a0,a0,228 # 80010ce0 <kmem>
    80000c04:	00000097          	auipc	ra,0x0
    80000c08:	212080e7          	jalr	530(ra) # 80000e16 <release>
    if (r)
    80000c0c:	b74d                	j	80000bae <kalloc+0x4c>

0000000080000c0e <newkfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void newkfree(void *pa)
{
    80000c0e:	1141                	addi	sp,sp,-16
    80000c10:	e406                	sd	ra,8(sp)
    80000c12:	e022                	sd	s0,0(sp)
    80000c14:	0800                	addi	s0,sp,16
    int i = ((uint64)pa-KERNBASE) /PGSIZE;
    80000c16:	800007b7          	lui	a5,0x80000
    80000c1a:	97aa                	add	a5,a5,a0
    80000c1c:	83b1                	srli	a5,a5,0xc
    80000c1e:	2781                	sext.w	a5,a5
    counter[i]--;
    80000c20:	078a                	slli	a5,a5,0x2
    80000c22:	00010717          	auipc	a4,0x10
    80000c26:	0de70713          	addi	a4,a4,222 # 80010d00 <counter>
    80000c2a:	97ba                	add	a5,a5,a4
    80000c2c:	4398                	lw	a4,0(a5)
    80000c2e:	377d                	addiw	a4,a4,-1
    80000c30:	c398                	sw	a4,0(a5)
    kfree(pa);
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	dc8080e7          	jalr	-568(ra) # 800009fa <kfree>
}
    80000c3a:	60a2                	ld	ra,8(sp)
    80000c3c:	6402                	ld	s0,0(sp)
    80000c3e:	0141                	addi	sp,sp,16
    80000c40:	8082                	ret

0000000080000c42 <newkalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
newkalloc(void)
{
    80000c42:	1141                	addi	sp,sp,-16
    80000c44:	e406                	sd	ra,8(sp)
    80000c46:	e022                	sd	s0,0(sp)
    80000c48:	0800                	addi	s0,sp,16
    void * pointer = kalloc();
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	f18080e7          	jalr	-232(ra) # 80000b62 <kalloc>
    if(counter[((uint64)pointer-KERNBASE )/PGSIZE]==0 && (uint64)pointer!=0){
    80000c52:	800007b7          	lui	a5,0x80000
    80000c56:	97aa                	add	a5,a5,a0
    80000c58:	83b1                	srli	a5,a5,0xc
    80000c5a:	00279693          	slli	a3,a5,0x2
    80000c5e:	00010717          	auipc	a4,0x10
    80000c62:	0a270713          	addi	a4,a4,162 # 80010d00 <counter>
    80000c66:	9736                	add	a4,a4,a3
    80000c68:	4318                	lw	a4,0(a4)
    80000c6a:	eb11                	bnez	a4,80000c7e <newkalloc+0x3c>
    80000c6c:	c909                	beqz	a0,80000c7e <newkalloc+0x3c>
        counter[((uint64)pointer-KERNBASE )/ PGSIZE]++;
    80000c6e:	00010717          	auipc	a4,0x10
    80000c72:	09270713          	addi	a4,a4,146 # 80010d00 <counter>
    80000c76:	00d707b3          	add	a5,a4,a3
    80000c7a:	4705                	li	a4,1
    80000c7c:	c398                	sw	a4,0(a5)
    }
    return pointer;
}
    80000c7e:	60a2                	ld	ra,8(sp)
    80000c80:	6402                	ld	s0,0(sp)
    80000c82:	0141                	addi	sp,sp,16
    80000c84:	8082                	ret

0000000080000c86 <refinc>:

void refinc(void *pa){
    80000c86:	1141                	addi	sp,sp,-16
    80000c88:	e422                	sd	s0,8(sp)
    80000c8a:	0800                	addi	s0,sp,16
    counter[((uint64)pa-KERNBASE )/ PGSIZE]++;
    80000c8c:	800007b7          	lui	a5,0x80000
    80000c90:	953e                	add	a0,a0,a5
    80000c92:	8131                	srli	a0,a0,0xc
    80000c94:	050a                	slli	a0,a0,0x2
    80000c96:	00010797          	auipc	a5,0x10
    80000c9a:	06a78793          	addi	a5,a5,106 # 80010d00 <counter>
    80000c9e:	97aa                	add	a5,a5,a0
    80000ca0:	4398                	lw	a4,0(a5)
    80000ca2:	2705                	addiw	a4,a4,1
    80000ca4:	c398                	sw	a4,0(a5)
}
    80000ca6:	6422                	ld	s0,8(sp)
    80000ca8:	0141                	addi	sp,sp,16
    80000caa:	8082                	ret

0000000080000cac <refdec>:

void refdec(void *pa){
    80000cac:	1141                	addi	sp,sp,-16
    80000cae:	e422                	sd	s0,8(sp)
    80000cb0:	0800                	addi	s0,sp,16
    counter[((uint64)pa-KERNBASE )/ PGSIZE]--;
    80000cb2:	800007b7          	lui	a5,0x80000
    80000cb6:	953e                	add	a0,a0,a5
    80000cb8:	8131                	srli	a0,a0,0xc
    80000cba:	050a                	slli	a0,a0,0x2
    80000cbc:	00010797          	auipc	a5,0x10
    80000cc0:	04478793          	addi	a5,a5,68 # 80010d00 <counter>
    80000cc4:	97aa                	add	a5,a5,a0
    80000cc6:	4398                	lw	a4,0(a5)
    80000cc8:	377d                	addiw	a4,a4,-1
    80000cca:	c398                	sw	a4,0(a5)
    80000ccc:	6422                	ld	s0,8(sp)
    80000cce:	0141                	addi	sp,sp,16
    80000cd0:	8082                	ret

0000000080000cd2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cd8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cda:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cde:	00053823          	sd	zero,16(a0)
}
    80000ce2:	6422                	ld	s0,8(sp)
    80000ce4:	0141                	addi	sp,sp,16
    80000ce6:	8082                	ret

0000000080000ce8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ce8:	411c                	lw	a5,0(a0)
    80000cea:	e399                	bnez	a5,80000cf0 <holding+0x8>
    80000cec:	4501                	li	a0,0
  return r;
}
    80000cee:	8082                	ret
{
    80000cf0:	1101                	addi	sp,sp,-32
    80000cf2:	ec06                	sd	ra,24(sp)
    80000cf4:	e822                	sd	s0,16(sp)
    80000cf6:	e426                	sd	s1,8(sp)
    80000cf8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cfa:	6904                	ld	s1,16(a0)
    80000cfc:	00001097          	auipc	ra,0x1
    80000d00:	ffc080e7          	jalr	-4(ra) # 80001cf8 <mycpu>
    80000d04:	40a48533          	sub	a0,s1,a0
    80000d08:	00153513          	seqz	a0,a0
}
    80000d0c:	60e2                	ld	ra,24(sp)
    80000d0e:	6442                	ld	s0,16(sp)
    80000d10:	64a2                	ld	s1,8(sp)
    80000d12:	6105                	addi	sp,sp,32
    80000d14:	8082                	ret

0000000080000d16 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d16:	1101                	addi	sp,sp,-32
    80000d18:	ec06                	sd	ra,24(sp)
    80000d1a:	e822                	sd	s0,16(sp)
    80000d1c:	e426                	sd	s1,8(sp)
    80000d1e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d20:	100024f3          	csrr	s1,sstatus
    80000d24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d2a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d2e:	00001097          	auipc	ra,0x1
    80000d32:	fca080e7          	jalr	-54(ra) # 80001cf8 <mycpu>
    80000d36:	5d3c                	lw	a5,120(a0)
    80000d38:	cf89                	beqz	a5,80000d52 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d3a:	00001097          	auipc	ra,0x1
    80000d3e:	fbe080e7          	jalr	-66(ra) # 80001cf8 <mycpu>
    80000d42:	5d3c                	lw	a5,120(a0)
    80000d44:	2785                	addiw	a5,a5,1
    80000d46:	dd3c                	sw	a5,120(a0)
}
    80000d48:	60e2                	ld	ra,24(sp)
    80000d4a:	6442                	ld	s0,16(sp)
    80000d4c:	64a2                	ld	s1,8(sp)
    80000d4e:	6105                	addi	sp,sp,32
    80000d50:	8082                	ret
    mycpu()->intena = old;
    80000d52:	00001097          	auipc	ra,0x1
    80000d56:	fa6080e7          	jalr	-90(ra) # 80001cf8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d5a:	8085                	srli	s1,s1,0x1
    80000d5c:	8885                	andi	s1,s1,1
    80000d5e:	dd64                	sw	s1,124(a0)
    80000d60:	bfe9                	j	80000d3a <push_off+0x24>

0000000080000d62 <acquire>:
{
    80000d62:	1101                	addi	sp,sp,-32
    80000d64:	ec06                	sd	ra,24(sp)
    80000d66:	e822                	sd	s0,16(sp)
    80000d68:	e426                	sd	s1,8(sp)
    80000d6a:	1000                	addi	s0,sp,32
    80000d6c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d6e:	00000097          	auipc	ra,0x0
    80000d72:	fa8080e7          	jalr	-88(ra) # 80000d16 <push_off>
  if(holding(lk))
    80000d76:	8526                	mv	a0,s1
    80000d78:	00000097          	auipc	ra,0x0
    80000d7c:	f70080e7          	jalr	-144(ra) # 80000ce8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d80:	4705                	li	a4,1
  if(holding(lk))
    80000d82:	e115                	bnez	a0,80000da6 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d84:	87ba                	mv	a5,a4
    80000d86:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d8a:	2781                	sext.w	a5,a5
    80000d8c:	ffe5                	bnez	a5,80000d84 <acquire+0x22>
  __sync_synchronize();
    80000d8e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d92:	00001097          	auipc	ra,0x1
    80000d96:	f66080e7          	jalr	-154(ra) # 80001cf8 <mycpu>
    80000d9a:	e888                	sd	a0,16(s1)
}
    80000d9c:	60e2                	ld	ra,24(sp)
    80000d9e:	6442                	ld	s0,16(sp)
    80000da0:	64a2                	ld	s1,8(sp)
    80000da2:	6105                	addi	sp,sp,32
    80000da4:	8082                	ret
    panic("acquire");
    80000da6:	00007517          	auipc	a0,0x7
    80000daa:	30a50513          	addi	a0,a0,778 # 800080b0 <digits+0x60>
    80000dae:	fffff097          	auipc	ra,0xfffff
    80000db2:	792080e7          	jalr	1938(ra) # 80000540 <panic>

0000000080000db6 <pop_off>:

void
pop_off(void)
{
    80000db6:	1141                	addi	sp,sp,-16
    80000db8:	e406                	sd	ra,8(sp)
    80000dba:	e022                	sd	s0,0(sp)
    80000dbc:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dbe:	00001097          	auipc	ra,0x1
    80000dc2:	f3a080e7          	jalr	-198(ra) # 80001cf8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dc6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dca:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dcc:	e78d                	bnez	a5,80000df6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000dce:	5d3c                	lw	a5,120(a0)
    80000dd0:	02f05b63          	blez	a5,80000e06 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dd4:	37fd                	addiw	a5,a5,-1
    80000dd6:	0007871b          	sext.w	a4,a5
    80000dda:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000ddc:	eb09                	bnez	a4,80000dee <pop_off+0x38>
    80000dde:	5d7c                	lw	a5,124(a0)
    80000de0:	c799                	beqz	a5,80000dee <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000de2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000de6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000dea:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000dee:	60a2                	ld	ra,8(sp)
    80000df0:	6402                	ld	s0,0(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    panic("pop_off - interruptible");
    80000df6:	00007517          	auipc	a0,0x7
    80000dfa:	2c250513          	addi	a0,a0,706 # 800080b8 <digits+0x68>
    80000dfe:	fffff097          	auipc	ra,0xfffff
    80000e02:	742080e7          	jalr	1858(ra) # 80000540 <panic>
    panic("pop_off");
    80000e06:	00007517          	auipc	a0,0x7
    80000e0a:	2ca50513          	addi	a0,a0,714 # 800080d0 <digits+0x80>
    80000e0e:	fffff097          	auipc	ra,0xfffff
    80000e12:	732080e7          	jalr	1842(ra) # 80000540 <panic>

0000000080000e16 <release>:
{
    80000e16:	1101                	addi	sp,sp,-32
    80000e18:	ec06                	sd	ra,24(sp)
    80000e1a:	e822                	sd	s0,16(sp)
    80000e1c:	e426                	sd	s1,8(sp)
    80000e1e:	1000                	addi	s0,sp,32
    80000e20:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	ec6080e7          	jalr	-314(ra) # 80000ce8 <holding>
    80000e2a:	c115                	beqz	a0,80000e4e <release+0x38>
  lk->cpu = 0;
    80000e2c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e30:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e34:	0f50000f          	fence	iorw,ow
    80000e38:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e3c:	00000097          	auipc	ra,0x0
    80000e40:	f7a080e7          	jalr	-134(ra) # 80000db6 <pop_off>
}
    80000e44:	60e2                	ld	ra,24(sp)
    80000e46:	6442                	ld	s0,16(sp)
    80000e48:	64a2                	ld	s1,8(sp)
    80000e4a:	6105                	addi	sp,sp,32
    80000e4c:	8082                	ret
    panic("release");
    80000e4e:	00007517          	auipc	a0,0x7
    80000e52:	28a50513          	addi	a0,a0,650 # 800080d8 <digits+0x88>
    80000e56:	fffff097          	auipc	ra,0xfffff
    80000e5a:	6ea080e7          	jalr	1770(ra) # 80000540 <panic>

0000000080000e5e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e5e:	1141                	addi	sp,sp,-16
    80000e60:	e422                	sd	s0,8(sp)
    80000e62:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e64:	ca19                	beqz	a2,80000e7a <memset+0x1c>
    80000e66:	87aa                	mv	a5,a0
    80000e68:	1602                	slli	a2,a2,0x20
    80000e6a:	9201                	srli	a2,a2,0x20
    80000e6c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e70:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e74:	0785                	addi	a5,a5,1
    80000e76:	fee79de3          	bne	a5,a4,80000e70 <memset+0x12>
  }
  return dst;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret

0000000080000e80 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e80:	1141                	addi	sp,sp,-16
    80000e82:	e422                	sd	s0,8(sp)
    80000e84:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e86:	ca05                	beqz	a2,80000eb6 <memcmp+0x36>
    80000e88:	fff6069b          	addiw	a3,a2,-1
    80000e8c:	1682                	slli	a3,a3,0x20
    80000e8e:	9281                	srli	a3,a3,0x20
    80000e90:	0685                	addi	a3,a3,1
    80000e92:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e94:	00054783          	lbu	a5,0(a0)
    80000e98:	0005c703          	lbu	a4,0(a1)
    80000e9c:	00e79863          	bne	a5,a4,80000eac <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ea4:	fed518e3          	bne	a0,a3,80000e94 <memcmp+0x14>
  }

  return 0;
    80000ea8:	4501                	li	a0,0
    80000eaa:	a019                	j	80000eb0 <memcmp+0x30>
      return *s1 - *s2;
    80000eac:	40e7853b          	subw	a0,a5,a4
}
    80000eb0:	6422                	ld	s0,8(sp)
    80000eb2:	0141                	addi	sp,sp,16
    80000eb4:	8082                	ret
  return 0;
    80000eb6:	4501                	li	a0,0
    80000eb8:	bfe5                	j	80000eb0 <memcmp+0x30>

0000000080000eba <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000eba:	1141                	addi	sp,sp,-16
    80000ebc:	e422                	sd	s0,8(sp)
    80000ebe:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ec0:	c205                	beqz	a2,80000ee0 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ec2:	02a5e263          	bltu	a1,a0,80000ee6 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ec6:	1602                	slli	a2,a2,0x20
    80000ec8:	9201                	srli	a2,a2,0x20
    80000eca:	00c587b3          	add	a5,a1,a2
{
    80000ece:	872a                	mv	a4,a0
      *d++ = *s++;
    80000ed0:	0585                	addi	a1,a1,1
    80000ed2:	0705                	addi	a4,a4,1
    80000ed4:	fff5c683          	lbu	a3,-1(a1)
    80000ed8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000edc:	fef59ae3          	bne	a1,a5,80000ed0 <memmove+0x16>

  return dst;
}
    80000ee0:	6422                	ld	s0,8(sp)
    80000ee2:	0141                	addi	sp,sp,16
    80000ee4:	8082                	ret
  if(s < d && s + n > d){
    80000ee6:	02061693          	slli	a3,a2,0x20
    80000eea:	9281                	srli	a3,a3,0x20
    80000eec:	00d58733          	add	a4,a1,a3
    80000ef0:	fce57be3          	bgeu	a0,a4,80000ec6 <memmove+0xc>
    d += n;
    80000ef4:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ef6:	fff6079b          	addiw	a5,a2,-1
    80000efa:	1782                	slli	a5,a5,0x20
    80000efc:	9381                	srli	a5,a5,0x20
    80000efe:	fff7c793          	not	a5,a5
    80000f02:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f04:	177d                	addi	a4,a4,-1
    80000f06:	16fd                	addi	a3,a3,-1
    80000f08:	00074603          	lbu	a2,0(a4)
    80000f0c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f10:	fee79ae3          	bne	a5,a4,80000f04 <memmove+0x4a>
    80000f14:	b7f1                	j	80000ee0 <memmove+0x26>

0000000080000f16 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f16:	1141                	addi	sp,sp,-16
    80000f18:	e406                	sd	ra,8(sp)
    80000f1a:	e022                	sd	s0,0(sp)
    80000f1c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	f9c080e7          	jalr	-100(ra) # 80000eba <memmove>
}
    80000f26:	60a2                	ld	ra,8(sp)
    80000f28:	6402                	ld	s0,0(sp)
    80000f2a:	0141                	addi	sp,sp,16
    80000f2c:	8082                	ret

0000000080000f2e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f2e:	1141                	addi	sp,sp,-16
    80000f30:	e422                	sd	s0,8(sp)
    80000f32:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f34:	ce11                	beqz	a2,80000f50 <strncmp+0x22>
    80000f36:	00054783          	lbu	a5,0(a0)
    80000f3a:	cf89                	beqz	a5,80000f54 <strncmp+0x26>
    80000f3c:	0005c703          	lbu	a4,0(a1)
    80000f40:	00f71a63          	bne	a4,a5,80000f54 <strncmp+0x26>
    n--, p++, q++;
    80000f44:	367d                	addiw	a2,a2,-1
    80000f46:	0505                	addi	a0,a0,1
    80000f48:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f4a:	f675                	bnez	a2,80000f36 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f4c:	4501                	li	a0,0
    80000f4e:	a809                	j	80000f60 <strncmp+0x32>
    80000f50:	4501                	li	a0,0
    80000f52:	a039                	j	80000f60 <strncmp+0x32>
  if(n == 0)
    80000f54:	ca09                	beqz	a2,80000f66 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f56:	00054503          	lbu	a0,0(a0)
    80000f5a:	0005c783          	lbu	a5,0(a1)
    80000f5e:	9d1d                	subw	a0,a0,a5
}
    80000f60:	6422                	ld	s0,8(sp)
    80000f62:	0141                	addi	sp,sp,16
    80000f64:	8082                	ret
    return 0;
    80000f66:	4501                	li	a0,0
    80000f68:	bfe5                	j	80000f60 <strncmp+0x32>

0000000080000f6a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f6a:	1141                	addi	sp,sp,-16
    80000f6c:	e422                	sd	s0,8(sp)
    80000f6e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f70:	872a                	mv	a4,a0
    80000f72:	8832                	mv	a6,a2
    80000f74:	367d                	addiw	a2,a2,-1
    80000f76:	01005963          	blez	a6,80000f88 <strncpy+0x1e>
    80000f7a:	0705                	addi	a4,a4,1
    80000f7c:	0005c783          	lbu	a5,0(a1)
    80000f80:	fef70fa3          	sb	a5,-1(a4)
    80000f84:	0585                	addi	a1,a1,1
    80000f86:	f7f5                	bnez	a5,80000f72 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f88:	86ba                	mv	a3,a4
    80000f8a:	00c05c63          	blez	a2,80000fa2 <strncpy+0x38>
    *s++ = 0;
    80000f8e:	0685                	addi	a3,a3,1
    80000f90:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f94:	40d707bb          	subw	a5,a4,a3
    80000f98:	37fd                	addiw	a5,a5,-1
    80000f9a:	010787bb          	addw	a5,a5,a6
    80000f9e:	fef048e3          	bgtz	a5,80000f8e <strncpy+0x24>
  return os;
}
    80000fa2:	6422                	ld	s0,8(sp)
    80000fa4:	0141                	addi	sp,sp,16
    80000fa6:	8082                	ret

0000000080000fa8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fa8:	1141                	addi	sp,sp,-16
    80000faa:	e422                	sd	s0,8(sp)
    80000fac:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fae:	02c05363          	blez	a2,80000fd4 <safestrcpy+0x2c>
    80000fb2:	fff6069b          	addiw	a3,a2,-1
    80000fb6:	1682                	slli	a3,a3,0x20
    80000fb8:	9281                	srli	a3,a3,0x20
    80000fba:	96ae                	add	a3,a3,a1
    80000fbc:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fbe:	00d58963          	beq	a1,a3,80000fd0 <safestrcpy+0x28>
    80000fc2:	0585                	addi	a1,a1,1
    80000fc4:	0785                	addi	a5,a5,1
    80000fc6:	fff5c703          	lbu	a4,-1(a1)
    80000fca:	fee78fa3          	sb	a4,-1(a5)
    80000fce:	fb65                	bnez	a4,80000fbe <safestrcpy+0x16>
    ;
  *s = 0;
    80000fd0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fd4:	6422                	ld	s0,8(sp)
    80000fd6:	0141                	addi	sp,sp,16
    80000fd8:	8082                	ret

0000000080000fda <strlen>:

int
strlen(const char *s)
{
    80000fda:	1141                	addi	sp,sp,-16
    80000fdc:	e422                	sd	s0,8(sp)
    80000fde:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fe0:	00054783          	lbu	a5,0(a0)
    80000fe4:	cf91                	beqz	a5,80001000 <strlen+0x26>
    80000fe6:	0505                	addi	a0,a0,1
    80000fe8:	87aa                	mv	a5,a0
    80000fea:	4685                	li	a3,1
    80000fec:	9e89                	subw	a3,a3,a0
    80000fee:	00f6853b          	addw	a0,a3,a5
    80000ff2:	0785                	addi	a5,a5,1
    80000ff4:	fff7c703          	lbu	a4,-1(a5)
    80000ff8:	fb7d                	bnez	a4,80000fee <strlen+0x14>
    ;
  return n;
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret
  for(n = 0; s[n]; n++)
    80001000:	4501                	li	a0,0
    80001002:	bfe5                	j	80000ffa <strlen+0x20>

0000000080001004 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001004:	1141                	addi	sp,sp,-16
    80001006:	e406                	sd	ra,8(sp)
    80001008:	e022                	sd	s0,0(sp)
    8000100a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000100c:	00001097          	auipc	ra,0x1
    80001010:	cdc080e7          	jalr	-804(ra) # 80001ce8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001014:	00008717          	auipc	a4,0x8
    80001018:	a6470713          	addi	a4,a4,-1436 # 80008a78 <started>
  if(cpuid() == 0){
    8000101c:	c139                	beqz	a0,80001062 <main+0x5e>
    while(started == 0)
    8000101e:	431c                	lw	a5,0(a4)
    80001020:	2781                	sext.w	a5,a5
    80001022:	dff5                	beqz	a5,8000101e <main+0x1a>
      ;
    __sync_synchronize();
    80001024:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001028:	00001097          	auipc	ra,0x1
    8000102c:	cc0080e7          	jalr	-832(ra) # 80001ce8 <cpuid>
    80001030:	85aa                	mv	a1,a0
    80001032:	00007517          	auipc	a0,0x7
    80001036:	0c650513          	addi	a0,a0,198 # 800080f8 <digits+0xa8>
    8000103a:	fffff097          	auipc	ra,0xfffff
    8000103e:	562080e7          	jalr	1378(ra) # 8000059c <printf>
    kvminithart();    // turn on paging
    80001042:	00000097          	auipc	ra,0x0
    80001046:	0d8080e7          	jalr	216(ra) # 8000111a <kvminithart>
    trapinithart();   // install kernel trap vector
    8000104a:	00002097          	auipc	ra,0x2
    8000104e:	b50080e7          	jalr	-1200(ra) # 80002b9a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001052:	00005097          	auipc	ra,0x5
    80001056:	33e080e7          	jalr	830(ra) # 80006390 <plicinithart>
  }

  scheduler();        
    8000105a:	00001097          	auipc	ra,0x1
    8000105e:	346080e7          	jalr	838(ra) # 800023a0 <scheduler>
    consoleinit();
    80001062:	fffff097          	auipc	ra,0xfffff
    80001066:	3ee080e7          	jalr	1006(ra) # 80000450 <consoleinit>
    printfinit();
    8000106a:	fffff097          	auipc	ra,0xfffff
    8000106e:	712080e7          	jalr	1810(ra) # 8000077c <printfinit>
    printf("\n");
    80001072:	00007517          	auipc	a0,0x7
    80001076:	01650513          	addi	a0,a0,22 # 80008088 <digits+0x38>
    8000107a:	fffff097          	auipc	ra,0xfffff
    8000107e:	522080e7          	jalr	1314(ra) # 8000059c <printf>
    printf("xv6 kernel is booting\n");
    80001082:	00007517          	auipc	a0,0x7
    80001086:	05e50513          	addi	a0,a0,94 # 800080e0 <digits+0x90>
    8000108a:	fffff097          	auipc	ra,0xfffff
    8000108e:	512080e7          	jalr	1298(ra) # 8000059c <printf>
    printf("\n");
    80001092:	00007517          	auipc	a0,0x7
    80001096:	ff650513          	addi	a0,a0,-10 # 80008088 <digits+0x38>
    8000109a:	fffff097          	auipc	ra,0xfffff
    8000109e:	502080e7          	jalr	1282(ra) # 8000059c <printf>
    kinit();         // physical page allocator
    800010a2:	00000097          	auipc	ra,0x0
    800010a6:	a74080e7          	jalr	-1420(ra) # 80000b16 <kinit>
    kvminit();       // create kernel page table
    800010aa:	00000097          	auipc	ra,0x0
    800010ae:	326080e7          	jalr	806(ra) # 800013d0 <kvminit>
    kvminithart();   // turn on paging
    800010b2:	00000097          	auipc	ra,0x0
    800010b6:	068080e7          	jalr	104(ra) # 8000111a <kvminithart>
    procinit();      // process table
    800010ba:	00001097          	auipc	ra,0x1
    800010be:	b4c080e7          	jalr	-1204(ra) # 80001c06 <procinit>
    trapinit();      // trap vectors
    800010c2:	00002097          	auipc	ra,0x2
    800010c6:	ab0080e7          	jalr	-1360(ra) # 80002b72 <trapinit>
    trapinithart();  // install kernel trap vector
    800010ca:	00002097          	auipc	ra,0x2
    800010ce:	ad0080e7          	jalr	-1328(ra) # 80002b9a <trapinithart>
    plicinit();      // set up interrupt controller
    800010d2:	00005097          	auipc	ra,0x5
    800010d6:	2a8080e7          	jalr	680(ra) # 8000637a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010da:	00005097          	auipc	ra,0x5
    800010de:	2b6080e7          	jalr	694(ra) # 80006390 <plicinithart>
    binit();         // buffer cache
    800010e2:	00002097          	auipc	ra,0x2
    800010e6:	44c080e7          	jalr	1100(ra) # 8000352e <binit>
    iinit();         // inode table
    800010ea:	00003097          	auipc	ra,0x3
    800010ee:	aec080e7          	jalr	-1300(ra) # 80003bd6 <iinit>
    fileinit();      // file table
    800010f2:	00004097          	auipc	ra,0x4
    800010f6:	a92080e7          	jalr	-1390(ra) # 80004b84 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010fa:	00005097          	auipc	ra,0x5
    800010fe:	39e080e7          	jalr	926(ra) # 80006498 <virtio_disk_init>
    userinit();      // first user process
    80001102:	00001097          	auipc	ra,0x1
    80001106:	eea080e7          	jalr	-278(ra) # 80001fec <userinit>
    __sync_synchronize();
    8000110a:	0ff0000f          	fence
    started = 1;
    8000110e:	4785                	li	a5,1
    80001110:	00008717          	auipc	a4,0x8
    80001114:	96f72423          	sw	a5,-1688(a4) # 80008a78 <started>
    80001118:	b789                	j	8000105a <main+0x56>

000000008000111a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000111a:	1141                	addi	sp,sp,-16
    8000111c:	e422                	sd	s0,8(sp)
    8000111e:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001120:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001124:	00008797          	auipc	a5,0x8
    80001128:	95c7b783          	ld	a5,-1700(a5) # 80008a80 <kernel_pagetable>
    8000112c:	83b1                	srli	a5,a5,0xc
    8000112e:	577d                	li	a4,-1
    80001130:	177e                	slli	a4,a4,0x3f
    80001132:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001134:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001138:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000113c:	6422                	ld	s0,8(sp)
    8000113e:	0141                	addi	sp,sp,16
    80001140:	8082                	ret

0000000080001142 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001142:	7139                	addi	sp,sp,-64
    80001144:	fc06                	sd	ra,56(sp)
    80001146:	f822                	sd	s0,48(sp)
    80001148:	f426                	sd	s1,40(sp)
    8000114a:	f04a                	sd	s2,32(sp)
    8000114c:	ec4e                	sd	s3,24(sp)
    8000114e:	e852                	sd	s4,16(sp)
    80001150:	e456                	sd	s5,8(sp)
    80001152:	e05a                	sd	s6,0(sp)
    80001154:	0080                	addi	s0,sp,64
    80001156:	84aa                	mv	s1,a0
    80001158:	89ae                	mv	s3,a1
    8000115a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000115c:	57fd                	li	a5,-1
    8000115e:	83e9                	srli	a5,a5,0x1a
    80001160:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001162:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001164:	04b7f263          	bgeu	a5,a1,800011a8 <walk+0x66>
    panic("walk");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	fa850513          	addi	a0,a0,-88 # 80008110 <digits+0xc0>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d0080e7          	jalr	976(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001178:	060a8663          	beqz	s5,800011e4 <walk+0xa2>
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	9e6080e7          	jalr	-1562(ra) # 80000b62 <kalloc>
    80001184:	84aa                	mv	s1,a0
    80001186:	c529                	beqz	a0,800011d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001188:	6605                	lui	a2,0x1
    8000118a:	4581                	li	a1,0
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	cd2080e7          	jalr	-814(ra) # 80000e5e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001194:	00c4d793          	srli	a5,s1,0xc
    80001198:	07aa                	slli	a5,a5,0xa
    8000119a:	0017e793          	ori	a5,a5,1
    8000119e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011a2:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffbd0e7>
    800011a4:	036a0063          	beq	s4,s6,800011c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011a8:	0149d933          	srl	s2,s3,s4
    800011ac:	1ff97913          	andi	s2,s2,511
    800011b0:	090e                	slli	s2,s2,0x3
    800011b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011b4:	00093483          	ld	s1,0(s2)
    800011b8:	0014f793          	andi	a5,s1,1
    800011bc:	dfd5                	beqz	a5,80001178 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011be:	80a9                	srli	s1,s1,0xa
    800011c0:	04b2                	slli	s1,s1,0xc
    800011c2:	b7c5                	j	800011a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011c4:	00c9d513          	srli	a0,s3,0xc
    800011c8:	1ff57513          	andi	a0,a0,511
    800011cc:	050e                	slli	a0,a0,0x3
    800011ce:	9526                	add	a0,a0,s1
}
    800011d0:	70e2                	ld	ra,56(sp)
    800011d2:	7442                	ld	s0,48(sp)
    800011d4:	74a2                	ld	s1,40(sp)
    800011d6:	7902                	ld	s2,32(sp)
    800011d8:	69e2                	ld	s3,24(sp)
    800011da:	6a42                	ld	s4,16(sp)
    800011dc:	6aa2                	ld	s5,8(sp)
    800011de:	6b02                	ld	s6,0(sp)
    800011e0:	6121                	addi	sp,sp,64
    800011e2:	8082                	ret
        return 0;
    800011e4:	4501                	li	a0,0
    800011e6:	b7ed                	j	800011d0 <walk+0x8e>

00000000800011e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011e8:	57fd                	li	a5,-1
    800011ea:	83e9                	srli	a5,a5,0x1a
    800011ec:	00b7f463          	bgeu	a5,a1,800011f4 <walkaddr+0xc>
    return 0;
    800011f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011f2:	8082                	ret
{
    800011f4:	1141                	addi	sp,sp,-16
    800011f6:	e406                	sd	ra,8(sp)
    800011f8:	e022                	sd	s0,0(sp)
    800011fa:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011fc:	4601                	li	a2,0
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f44080e7          	jalr	-188(ra) # 80001142 <walk>
  if(pte == 0)
    80001206:	c105                	beqz	a0,80001226 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001208:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000120a:	0117f693          	andi	a3,a5,17
    8000120e:	4745                	li	a4,17
    return 0;
    80001210:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001212:	00e68663          	beq	a3,a4,8000121e <walkaddr+0x36>
}
    80001216:	60a2                	ld	ra,8(sp)
    80001218:	6402                	ld	s0,0(sp)
    8000121a:	0141                	addi	sp,sp,16
    8000121c:	8082                	ret
  pa = PTE2PA(*pte);
    8000121e:	83a9                	srli	a5,a5,0xa
    80001220:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001224:	bfcd                	j	80001216 <walkaddr+0x2e>
    return 0;
    80001226:	4501                	li	a0,0
    80001228:	b7fd                	j	80001216 <walkaddr+0x2e>

000000008000122a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000122a:	715d                	addi	sp,sp,-80
    8000122c:	e486                	sd	ra,72(sp)
    8000122e:	e0a2                	sd	s0,64(sp)
    80001230:	fc26                	sd	s1,56(sp)
    80001232:	f84a                	sd	s2,48(sp)
    80001234:	f44e                	sd	s3,40(sp)
    80001236:	f052                	sd	s4,32(sp)
    80001238:	ec56                	sd	s5,24(sp)
    8000123a:	e85a                	sd	s6,16(sp)
    8000123c:	e45e                	sd	s7,8(sp)
    8000123e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001240:	c639                	beqz	a2,8000128e <mappages+0x64>
    80001242:	8aaa                	mv	s5,a0
    80001244:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001246:	777d                	lui	a4,0xfffff
    80001248:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000124c:	fff58993          	addi	s3,a1,-1
    80001250:	99b2                	add	s3,s3,a2
    80001252:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001256:	893e                	mv	s2,a5
    80001258:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000125c:	6b85                	lui	s7,0x1
    8000125e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001262:	4605                	li	a2,1
    80001264:	85ca                	mv	a1,s2
    80001266:	8556                	mv	a0,s5
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	eda080e7          	jalr	-294(ra) # 80001142 <walk>
    80001270:	cd1d                	beqz	a0,800012ae <mappages+0x84>
    if(*pte & PTE_V)
    80001272:	611c                	ld	a5,0(a0)
    80001274:	8b85                	andi	a5,a5,1
    80001276:	e785                	bnez	a5,8000129e <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001278:	80b1                	srli	s1,s1,0xc
    8000127a:	04aa                	slli	s1,s1,0xa
    8000127c:	0164e4b3          	or	s1,s1,s6
    80001280:	0014e493          	ori	s1,s1,1
    80001284:	e104                	sd	s1,0(a0)
    if(a == last)
    80001286:	05390063          	beq	s2,s3,800012c6 <mappages+0x9c>
    a += PGSIZE;
    8000128a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000128c:	bfc9                	j	8000125e <mappages+0x34>
    panic("mappages: size");
    8000128e:	00007517          	auipc	a0,0x7
    80001292:	e8a50513          	addi	a0,a0,-374 # 80008118 <digits+0xc8>
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	2aa080e7          	jalr	682(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000129e:	00007517          	auipc	a0,0x7
    800012a2:	e8a50513          	addi	a0,a0,-374 # 80008128 <digits+0xd8>
    800012a6:	fffff097          	auipc	ra,0xfffff
    800012aa:	29a080e7          	jalr	666(ra) # 80000540 <panic>
      return -1;
    800012ae:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
  return 0;
    800012c6:	4501                	li	a0,0
    800012c8:	b7e5                	j	800012b0 <mappages+0x86>

00000000800012ca <kvmmap>:
{
    800012ca:	1141                	addi	sp,sp,-16
    800012cc:	e406                	sd	ra,8(sp)
    800012ce:	e022                	sd	s0,0(sp)
    800012d0:	0800                	addi	s0,sp,16
    800012d2:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012d4:	86b2                	mv	a3,a2
    800012d6:	863e                	mv	a2,a5
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	f52080e7          	jalr	-174(ra) # 8000122a <mappages>
    800012e0:	e509                	bnez	a0,800012ea <kvmmap+0x20>
}
    800012e2:	60a2                	ld	ra,8(sp)
    800012e4:	6402                	ld	s0,0(sp)
    800012e6:	0141                	addi	sp,sp,16
    800012e8:	8082                	ret
    panic("kvmmap");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e4e50513          	addi	a0,a0,-434 # 80008138 <digits+0xe8>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24e080e7          	jalr	590(ra) # 80000540 <panic>

00000000800012fa <kvmmake>:
{
    800012fa:	1101                	addi	sp,sp,-32
    800012fc:	ec06                	sd	ra,24(sp)
    800012fe:	e822                	sd	s0,16(sp)
    80001300:	e426                	sd	s1,8(sp)
    80001302:	e04a                	sd	s2,0(sp)
    80001304:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001306:	00000097          	auipc	ra,0x0
    8000130a:	85c080e7          	jalr	-1956(ra) # 80000b62 <kalloc>
    8000130e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001310:	6605                	lui	a2,0x1
    80001312:	4581                	li	a1,0
    80001314:	00000097          	auipc	ra,0x0
    80001318:	b4a080e7          	jalr	-1206(ra) # 80000e5e <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000131c:	4719                	li	a4,6
    8000131e:	6685                	lui	a3,0x1
    80001320:	10000637          	lui	a2,0x10000
    80001324:	100005b7          	lui	a1,0x10000
    80001328:	8526                	mv	a0,s1
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	fa0080e7          	jalr	-96(ra) # 800012ca <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001332:	4719                	li	a4,6
    80001334:	6685                	lui	a3,0x1
    80001336:	10001637          	lui	a2,0x10001
    8000133a:	100015b7          	lui	a1,0x10001
    8000133e:	8526                	mv	a0,s1
    80001340:	00000097          	auipc	ra,0x0
    80001344:	f8a080e7          	jalr	-118(ra) # 800012ca <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001348:	4719                	li	a4,6
    8000134a:	004006b7          	lui	a3,0x400
    8000134e:	0c000637          	lui	a2,0xc000
    80001352:	0c0005b7          	lui	a1,0xc000
    80001356:	8526                	mv	a0,s1
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	f72080e7          	jalr	-142(ra) # 800012ca <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001360:	00007917          	auipc	s2,0x7
    80001364:	ca090913          	addi	s2,s2,-864 # 80008000 <etext>
    80001368:	4729                	li	a4,10
    8000136a:	80007697          	auipc	a3,0x80007
    8000136e:	c9668693          	addi	a3,a3,-874 # 8000 <_entry-0x7fff8000>
    80001372:	4605                	li	a2,1
    80001374:	067e                	slli	a2,a2,0x1f
    80001376:	85b2                	mv	a1,a2
    80001378:	8526                	mv	a0,s1
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	f50080e7          	jalr	-176(ra) # 800012ca <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001382:	4719                	li	a4,6
    80001384:	46c5                	li	a3,17
    80001386:	06ee                	slli	a3,a3,0x1b
    80001388:	412686b3          	sub	a3,a3,s2
    8000138c:	864a                	mv	a2,s2
    8000138e:	85ca                	mv	a1,s2
    80001390:	8526                	mv	a0,s1
    80001392:	00000097          	auipc	ra,0x0
    80001396:	f38080e7          	jalr	-200(ra) # 800012ca <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000139a:	4729                	li	a4,10
    8000139c:	6685                	lui	a3,0x1
    8000139e:	00006617          	auipc	a2,0x6
    800013a2:	c6260613          	addi	a2,a2,-926 # 80007000 <_trampoline>
    800013a6:	040005b7          	lui	a1,0x4000
    800013aa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013ac:	05b2                	slli	a1,a1,0xc
    800013ae:	8526                	mv	a0,s1
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	f1a080e7          	jalr	-230(ra) # 800012ca <kvmmap>
  proc_mapstacks(kpgtbl);
    800013b8:	8526                	mv	a0,s1
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	7b6080e7          	jalr	1974(ra) # 80001b70 <proc_mapstacks>
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6902                	ld	s2,0(sp)
    800013cc:	6105                	addi	sp,sp,32
    800013ce:	8082                	ret

00000000800013d0 <kvminit>:
{
    800013d0:	1141                	addi	sp,sp,-16
    800013d2:	e406                	sd	ra,8(sp)
    800013d4:	e022                	sd	s0,0(sp)
    800013d6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013d8:	00000097          	auipc	ra,0x0
    800013dc:	f22080e7          	jalr	-222(ra) # 800012fa <kvmmake>
    800013e0:	00007797          	auipc	a5,0x7
    800013e4:	6aa7b023          	sd	a0,1696(a5) # 80008a80 <kernel_pagetable>
}
    800013e8:	60a2                	ld	ra,8(sp)
    800013ea:	6402                	ld	s0,0(sp)
    800013ec:	0141                	addi	sp,sp,16
    800013ee:	8082                	ret

00000000800013f0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013f0:	715d                	addi	sp,sp,-80
    800013f2:	e486                	sd	ra,72(sp)
    800013f4:	e0a2                	sd	s0,64(sp)
    800013f6:	fc26                	sd	s1,56(sp)
    800013f8:	f84a                	sd	s2,48(sp)
    800013fa:	f44e                	sd	s3,40(sp)
    800013fc:	f052                	sd	s4,32(sp)
    800013fe:	ec56                	sd	s5,24(sp)
    80001400:	e85a                	sd	s6,16(sp)
    80001402:	e45e                	sd	s7,8(sp)
    80001404:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001406:	03459793          	slli	a5,a1,0x34
    8000140a:	e795                	bnez	a5,80001436 <uvmunmap+0x46>
    8000140c:	8a2a                	mv	s4,a0
    8000140e:	892e                	mv	s2,a1
    80001410:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001412:	0632                	slli	a2,a2,0xc
    80001414:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001418:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000141a:	6b05                	lui	s6,0x1
    8000141c:	0735e263          	bltu	a1,s3,80001480 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001420:	60a6                	ld	ra,72(sp)
    80001422:	6406                	ld	s0,64(sp)
    80001424:	74e2                	ld	s1,56(sp)
    80001426:	7942                	ld	s2,48(sp)
    80001428:	79a2                	ld	s3,40(sp)
    8000142a:	7a02                	ld	s4,32(sp)
    8000142c:	6ae2                	ld	s5,24(sp)
    8000142e:	6b42                	ld	s6,16(sp)
    80001430:	6ba2                	ld	s7,8(sp)
    80001432:	6161                	addi	sp,sp,80
    80001434:	8082                	ret
    panic("uvmunmap: not aligned");
    80001436:	00007517          	auipc	a0,0x7
    8000143a:	d0a50513          	addi	a0,a0,-758 # 80008140 <digits+0xf0>
    8000143e:	fffff097          	auipc	ra,0xfffff
    80001442:	102080e7          	jalr	258(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001446:	00007517          	auipc	a0,0x7
    8000144a:	d1250513          	addi	a0,a0,-750 # 80008158 <digits+0x108>
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	0f2080e7          	jalr	242(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001456:	00007517          	auipc	a0,0x7
    8000145a:	d1250513          	addi	a0,a0,-750 # 80008168 <digits+0x118>
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	0e2080e7          	jalr	226(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001466:	00007517          	auipc	a0,0x7
    8000146a:	d1a50513          	addi	a0,a0,-742 # 80008180 <digits+0x130>
    8000146e:	fffff097          	auipc	ra,0xfffff
    80001472:	0d2080e7          	jalr	210(ra) # 80000540 <panic>
    *pte = 0;
    80001476:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000147a:	995a                	add	s2,s2,s6
    8000147c:	fb3972e3          	bgeu	s2,s3,80001420 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001480:	4601                	li	a2,0
    80001482:	85ca                	mv	a1,s2
    80001484:	8552                	mv	a0,s4
    80001486:	00000097          	auipc	ra,0x0
    8000148a:	cbc080e7          	jalr	-836(ra) # 80001142 <walk>
    8000148e:	84aa                	mv	s1,a0
    80001490:	d95d                	beqz	a0,80001446 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001492:	6108                	ld	a0,0(a0)
    80001494:	00157793          	andi	a5,a0,1
    80001498:	dfdd                	beqz	a5,80001456 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000149a:	3ff57793          	andi	a5,a0,1023
    8000149e:	fd7784e3          	beq	a5,s7,80001466 <uvmunmap+0x76>
    if(do_free){
    800014a2:	fc0a8ae3          	beqz	s5,80001476 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014a6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014a8:	0532                	slli	a0,a0,0xc
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	550080e7          	jalr	1360(ra) # 800009fa <kfree>
    800014b2:	b7d1                	j	80001476 <uvmunmap+0x86>

00000000800014b4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014b4:	1101                	addi	sp,sp,-32
    800014b6:	ec06                	sd	ra,24(sp)
    800014b8:	e822                	sd	s0,16(sp)
    800014ba:	e426                	sd	s1,8(sp)
    800014bc:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014be:	fffff097          	auipc	ra,0xfffff
    800014c2:	6a4080e7          	jalr	1700(ra) # 80000b62 <kalloc>
    800014c6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014c8:	c519                	beqz	a0,800014d6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014ca:	6605                	lui	a2,0x1
    800014cc:	4581                	li	a1,0
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	990080e7          	jalr	-1648(ra) # 80000e5e <memset>
  return pagetable;
}
    800014d6:	8526                	mv	a0,s1
    800014d8:	60e2                	ld	ra,24(sp)
    800014da:	6442                	ld	s0,16(sp)
    800014dc:	64a2                	ld	s1,8(sp)
    800014de:	6105                	addi	sp,sp,32
    800014e0:	8082                	ret

00000000800014e2 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014e2:	7179                	addi	sp,sp,-48
    800014e4:	f406                	sd	ra,40(sp)
    800014e6:	f022                	sd	s0,32(sp)
    800014e8:	ec26                	sd	s1,24(sp)
    800014ea:	e84a                	sd	s2,16(sp)
    800014ec:	e44e                	sd	s3,8(sp)
    800014ee:	e052                	sd	s4,0(sp)
    800014f0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014f2:	6785                	lui	a5,0x1
    800014f4:	04f67863          	bgeu	a2,a5,80001544 <uvmfirst+0x62>
    800014f8:	8a2a                	mv	s4,a0
    800014fa:	89ae                	mv	s3,a1
    800014fc:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014fe:	fffff097          	auipc	ra,0xfffff
    80001502:	664080e7          	jalr	1636(ra) # 80000b62 <kalloc>
    80001506:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001508:	6605                	lui	a2,0x1
    8000150a:	4581                	li	a1,0
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	952080e7          	jalr	-1710(ra) # 80000e5e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001514:	4779                	li	a4,30
    80001516:	86ca                	mv	a3,s2
    80001518:	6605                	lui	a2,0x1
    8000151a:	4581                	li	a1,0
    8000151c:	8552                	mv	a0,s4
    8000151e:	00000097          	auipc	ra,0x0
    80001522:	d0c080e7          	jalr	-756(ra) # 8000122a <mappages>
  memmove(mem, src, sz);
    80001526:	8626                	mv	a2,s1
    80001528:	85ce                	mv	a1,s3
    8000152a:	854a                	mv	a0,s2
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	98e080e7          	jalr	-1650(ra) # 80000eba <memmove>
}
    80001534:	70a2                	ld	ra,40(sp)
    80001536:	7402                	ld	s0,32(sp)
    80001538:	64e2                	ld	s1,24(sp)
    8000153a:	6942                	ld	s2,16(sp)
    8000153c:	69a2                	ld	s3,8(sp)
    8000153e:	6a02                	ld	s4,0(sp)
    80001540:	6145                	addi	sp,sp,48
    80001542:	8082                	ret
    panic("uvmfirst: more than a page");
    80001544:	00007517          	auipc	a0,0x7
    80001548:	c5450513          	addi	a0,a0,-940 # 80008198 <digits+0x148>
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	ff4080e7          	jalr	-12(ra) # 80000540 <panic>

0000000080001554 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001554:	1101                	addi	sp,sp,-32
    80001556:	ec06                	sd	ra,24(sp)
    80001558:	e822                	sd	s0,16(sp)
    8000155a:	e426                	sd	s1,8(sp)
    8000155c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000155e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001560:	00b67d63          	bgeu	a2,a1,8000157a <uvmdealloc+0x26>
    80001564:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001566:	6785                	lui	a5,0x1
    80001568:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000156a:	00f60733          	add	a4,a2,a5
    8000156e:	76fd                	lui	a3,0xfffff
    80001570:	8f75                	and	a4,a4,a3
    80001572:	97ae                	add	a5,a5,a1
    80001574:	8ff5                	and	a5,a5,a3
    80001576:	00f76863          	bltu	a4,a5,80001586 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000157a:	8526                	mv	a0,s1
    8000157c:	60e2                	ld	ra,24(sp)
    8000157e:	6442                	ld	s0,16(sp)
    80001580:	64a2                	ld	s1,8(sp)
    80001582:	6105                	addi	sp,sp,32
    80001584:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001586:	8f99                	sub	a5,a5,a4
    80001588:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000158a:	4685                	li	a3,1
    8000158c:	0007861b          	sext.w	a2,a5
    80001590:	85ba                	mv	a1,a4
    80001592:	00000097          	auipc	ra,0x0
    80001596:	e5e080e7          	jalr	-418(ra) # 800013f0 <uvmunmap>
    8000159a:	b7c5                	j	8000157a <uvmdealloc+0x26>

000000008000159c <uvmalloc>:
  if(newsz < oldsz)
    8000159c:	0ab66563          	bltu	a2,a1,80001646 <uvmalloc+0xaa>
{
    800015a0:	7139                	addi	sp,sp,-64
    800015a2:	fc06                	sd	ra,56(sp)
    800015a4:	f822                	sd	s0,48(sp)
    800015a6:	f426                	sd	s1,40(sp)
    800015a8:	f04a                	sd	s2,32(sp)
    800015aa:	ec4e                	sd	s3,24(sp)
    800015ac:	e852                	sd	s4,16(sp)
    800015ae:	e456                	sd	s5,8(sp)
    800015b0:	e05a                	sd	s6,0(sp)
    800015b2:	0080                	addi	s0,sp,64
    800015b4:	8aaa                	mv	s5,a0
    800015b6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015b8:	6785                	lui	a5,0x1
    800015ba:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015bc:	95be                	add	a1,a1,a5
    800015be:	77fd                	lui	a5,0xfffff
    800015c0:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015c4:	08c9f363          	bgeu	s3,a2,8000164a <uvmalloc+0xae>
    800015c8:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015ca:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015ce:	fffff097          	auipc	ra,0xfffff
    800015d2:	594080e7          	jalr	1428(ra) # 80000b62 <kalloc>
    800015d6:	84aa                	mv	s1,a0
    if(mem == 0){
    800015d8:	c51d                	beqz	a0,80001606 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015da:	6605                	lui	a2,0x1
    800015dc:	4581                	li	a1,0
    800015de:	00000097          	auipc	ra,0x0
    800015e2:	880080e7          	jalr	-1920(ra) # 80000e5e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015e6:	875a                	mv	a4,s6
    800015e8:	86a6                	mv	a3,s1
    800015ea:	6605                	lui	a2,0x1
    800015ec:	85ca                	mv	a1,s2
    800015ee:	8556                	mv	a0,s5
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	c3a080e7          	jalr	-966(ra) # 8000122a <mappages>
    800015f8:	e90d                	bnez	a0,8000162a <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015fa:	6785                	lui	a5,0x1
    800015fc:	993e                	add	s2,s2,a5
    800015fe:	fd4968e3          	bltu	s2,s4,800015ce <uvmalloc+0x32>
  return newsz;
    80001602:	8552                	mv	a0,s4
    80001604:	a809                	j	80001616 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001606:	864e                	mv	a2,s3
    80001608:	85ca                	mv	a1,s2
    8000160a:	8556                	mv	a0,s5
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	f48080e7          	jalr	-184(ra) # 80001554 <uvmdealloc>
      return 0;
    80001614:	4501                	li	a0,0
}
    80001616:	70e2                	ld	ra,56(sp)
    80001618:	7442                	ld	s0,48(sp)
    8000161a:	74a2                	ld	s1,40(sp)
    8000161c:	7902                	ld	s2,32(sp)
    8000161e:	69e2                	ld	s3,24(sp)
    80001620:	6a42                	ld	s4,16(sp)
    80001622:	6aa2                	ld	s5,8(sp)
    80001624:	6b02                	ld	s6,0(sp)
    80001626:	6121                	addi	sp,sp,64
    80001628:	8082                	ret
      kfree(mem);
    8000162a:	8526                	mv	a0,s1
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	3ce080e7          	jalr	974(ra) # 800009fa <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001634:	864e                	mv	a2,s3
    80001636:	85ca                	mv	a1,s2
    80001638:	8556                	mv	a0,s5
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	f1a080e7          	jalr	-230(ra) # 80001554 <uvmdealloc>
      return 0;
    80001642:	4501                	li	a0,0
    80001644:	bfc9                	j	80001616 <uvmalloc+0x7a>
    return oldsz;
    80001646:	852e                	mv	a0,a1
}
    80001648:	8082                	ret
  return newsz;
    8000164a:	8532                	mv	a0,a2
    8000164c:	b7e9                	j	80001616 <uvmalloc+0x7a>

000000008000164e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000164e:	7179                	addi	sp,sp,-48
    80001650:	f406                	sd	ra,40(sp)
    80001652:	f022                	sd	s0,32(sp)
    80001654:	ec26                	sd	s1,24(sp)
    80001656:	e84a                	sd	s2,16(sp)
    80001658:	e44e                	sd	s3,8(sp)
    8000165a:	e052                	sd	s4,0(sp)
    8000165c:	1800                	addi	s0,sp,48
    8000165e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001660:	84aa                	mv	s1,a0
    80001662:	6905                	lui	s2,0x1
    80001664:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001666:	4985                	li	s3,1
    80001668:	a829                	j	80001682 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000166a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000166c:	00c79513          	slli	a0,a5,0xc
    80001670:	00000097          	auipc	ra,0x0
    80001674:	fde080e7          	jalr	-34(ra) # 8000164e <freewalk>
      pagetable[i] = 0;
    80001678:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000167c:	04a1                	addi	s1,s1,8
    8000167e:	03248163          	beq	s1,s2,800016a0 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001682:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001684:	00f7f713          	andi	a4,a5,15
    80001688:	ff3701e3          	beq	a4,s3,8000166a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000168c:	8b85                	andi	a5,a5,1
    8000168e:	d7fd                	beqz	a5,8000167c <freewalk+0x2e>
      panic("freewalk: leaf");
    80001690:	00007517          	auipc	a0,0x7
    80001694:	b2850513          	addi	a0,a0,-1240 # 800081b8 <digits+0x168>
    80001698:	fffff097          	auipc	ra,0xfffff
    8000169c:	ea8080e7          	jalr	-344(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    800016a0:	8552                	mv	a0,s4
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	358080e7          	jalr	856(ra) # 800009fa <kfree>
}
    800016aa:	70a2                	ld	ra,40(sp)
    800016ac:	7402                	ld	s0,32(sp)
    800016ae:	64e2                	ld	s1,24(sp)
    800016b0:	6942                	ld	s2,16(sp)
    800016b2:	69a2                	ld	s3,8(sp)
    800016b4:	6a02                	ld	s4,0(sp)
    800016b6:	6145                	addi	sp,sp,48
    800016b8:	8082                	ret

00000000800016ba <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016ba:	1101                	addi	sp,sp,-32
    800016bc:	ec06                	sd	ra,24(sp)
    800016be:	e822                	sd	s0,16(sp)
    800016c0:	e426                	sd	s1,8(sp)
    800016c2:	1000                	addi	s0,sp,32
    800016c4:	84aa                	mv	s1,a0
  if(sz > 0)
    800016c6:	e999                	bnez	a1,800016dc <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016c8:	8526                	mv	a0,s1
    800016ca:	00000097          	auipc	ra,0x0
    800016ce:	f84080e7          	jalr	-124(ra) # 8000164e <freewalk>
}
    800016d2:	60e2                	ld	ra,24(sp)
    800016d4:	6442                	ld	s0,16(sp)
    800016d6:	64a2                	ld	s1,8(sp)
    800016d8:	6105                	addi	sp,sp,32
    800016da:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016dc:	6785                	lui	a5,0x1
    800016de:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016e0:	95be                	add	a1,a1,a5
    800016e2:	4685                	li	a3,1
    800016e4:	00c5d613          	srli	a2,a1,0xc
    800016e8:	4581                	li	a1,0
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	d06080e7          	jalr	-762(ra) # 800013f0 <uvmunmap>
    800016f2:	bfd9                	j	800016c8 <uvmfree+0xe>

00000000800016f4 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016f4:	c679                	beqz	a2,800017c2 <uvmcopy+0xce>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	0880                	addi	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8aae                	mv	s5,a1
    80001710:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001712:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001714:	4601                	li	a2,0
    80001716:	85ce                	mv	a1,s3
    80001718:	855a                	mv	a0,s6
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	a28080e7          	jalr	-1496(ra) # 80001142 <walk>
    80001722:	c531                	beqz	a0,8000176e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001724:	6118                	ld	a4,0(a0)
    80001726:	00177793          	andi	a5,a4,1
    8000172a:	cbb1                	beqz	a5,8000177e <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000172c:	00a75593          	srli	a1,a4,0xa
    80001730:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001734:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001738:	fffff097          	auipc	ra,0xfffff
    8000173c:	42a080e7          	jalr	1066(ra) # 80000b62 <kalloc>
    80001740:	892a                	mv	s2,a0
    80001742:	c939                	beqz	a0,80001798 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001744:	6605                	lui	a2,0x1
    80001746:	85de                	mv	a1,s7
    80001748:	fffff097          	auipc	ra,0xfffff
    8000174c:	772080e7          	jalr	1906(ra) # 80000eba <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001750:	8726                	mv	a4,s1
    80001752:	86ca                	mv	a3,s2
    80001754:	6605                	lui	a2,0x1
    80001756:	85ce                	mv	a1,s3
    80001758:	8556                	mv	a0,s5
    8000175a:	00000097          	auipc	ra,0x0
    8000175e:	ad0080e7          	jalr	-1328(ra) # 8000122a <mappages>
    80001762:	e515                	bnez	a0,8000178e <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001764:	6785                	lui	a5,0x1
    80001766:	99be                	add	s3,s3,a5
    80001768:	fb49e6e3          	bltu	s3,s4,80001714 <uvmcopy+0x20>
    8000176c:	a081                	j	800017ac <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000176e:	00007517          	auipc	a0,0x7
    80001772:	a5a50513          	addi	a0,a0,-1446 # 800081c8 <digits+0x178>
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	dca080e7          	jalr	-566(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000177e:	00007517          	auipc	a0,0x7
    80001782:	a6a50513          	addi	a0,a0,-1430 # 800081e8 <digits+0x198>
    80001786:	fffff097          	auipc	ra,0xfffff
    8000178a:	dba080e7          	jalr	-582(ra) # 80000540 <panic>
      kfree(mem);
    8000178e:	854a                	mv	a0,s2
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	26a080e7          	jalr	618(ra) # 800009fa <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001798:	4685                	li	a3,1
    8000179a:	00c9d613          	srli	a2,s3,0xc
    8000179e:	4581                	li	a1,0
    800017a0:	8556                	mv	a0,s5
    800017a2:	00000097          	auipc	ra,0x0
    800017a6:	c4e080e7          	jalr	-946(ra) # 800013f0 <uvmunmap>
  return -1;
    800017aa:	557d                	li	a0,-1
}
    800017ac:	60a6                	ld	ra,72(sp)
    800017ae:	6406                	ld	s0,64(sp)
    800017b0:	74e2                	ld	s1,56(sp)
    800017b2:	7942                	ld	s2,48(sp)
    800017b4:	79a2                	ld	s3,40(sp)
    800017b6:	7a02                	ld	s4,32(sp)
    800017b8:	6ae2                	ld	s5,24(sp)
    800017ba:	6b42                	ld	s6,16(sp)
    800017bc:	6ba2                	ld	s7,8(sp)
    800017be:	6161                	addi	sp,sp,80
    800017c0:	8082                	ret
  return 0;
    800017c2:	4501                	li	a0,0
}
    800017c4:	8082                	ret

00000000800017c6 <uvmcow>:

int uvmcow(pagetable_t old, pagetable_t new, uint64 sz) {
    800017c6:	715d                	addi	sp,sp,-80
    800017c8:	e486                	sd	ra,72(sp)
    800017ca:	e0a2                	sd	s0,64(sp)
    800017cc:	fc26                	sd	s1,56(sp)
    800017ce:	f84a                	sd	s2,48(sp)
    800017d0:	f44e                	sd	s3,40(sp)
    800017d2:	f052                	sd	s4,32(sp)
    800017d4:	ec56                	sd	s5,24(sp)
    800017d6:	e85a                	sd	s6,16(sp)
    800017d8:	e45e                	sd	s7,8(sp)
    800017da:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    800017dc:	c271                	beqz	a2,800018a0 <uvmcow+0xda>
    800017de:	8aaa                	mv	s5,a0
    800017e0:	8bae                	mv	s7,a1
    800017e2:	8b32                	mv	s6,a2
    800017e4:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    800017e6:	4601                	li	a2,0
    800017e8:	85ca                	mv	a1,s2
    800017ea:	8556                	mv	a0,s5
    800017ec:	00000097          	auipc	ra,0x0
    800017f0:	956080e7          	jalr	-1706(ra) # 80001142 <walk>
    800017f4:	c125                	beqz	a0,80001854 <uvmcow+0x8e>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800017f6:	6118                	ld	a4,0(a0)
    800017f8:	00177793          	andi	a5,a4,1
    800017fc:	c7a5                	beqz	a5,80001864 <uvmcow+0x9e>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017fe:	00a75993          	srli	s3,a4,0xa
    80001802:	09b2                	slli	s3,s3,0xc
    flags = PTE_FLAGS(*pte);
    flags &= ~PTE_W; 

    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001804:	3fb77493          	andi	s1,a4,1019
    80001808:	8726                	mv	a4,s1
    8000180a:	86ce                	mv	a3,s3
    8000180c:	6605                	lui	a2,0x1
    8000180e:	85ca                	mv	a1,s2
    80001810:	855e                	mv	a0,s7
    80001812:	00000097          	auipc	ra,0x0
    80001816:	a18080e7          	jalr	-1512(ra) # 8000122a <mappages>
    8000181a:	8a2a                	mv	s4,a0
    8000181c:	ed21                	bnez	a0,80001874 <uvmcow+0xae>
      goto err;
    }
    refinc((void *)pa);
    8000181e:	854e                	mv	a0,s3
    80001820:	fffff097          	auipc	ra,0xfffff
    80001824:	466080e7          	jalr	1126(ra) # 80000c86 <refinc>
    uvmunmap(old,i,1,0);
    80001828:	4681                	li	a3,0
    8000182a:	4605                	li	a2,1
    8000182c:	85ca                	mv	a1,s2
    8000182e:	8556                	mv	a0,s5
    80001830:	00000097          	auipc	ra,0x0
    80001834:	bc0080e7          	jalr	-1088(ra) # 800013f0 <uvmunmap>
    mappages(old,i,PGSIZE,pa,flags);
    80001838:	8726                	mv	a4,s1
    8000183a:	86ce                	mv	a3,s3
    8000183c:	6605                	lui	a2,0x1
    8000183e:	85ca                	mv	a1,s2
    80001840:	8556                	mv	a0,s5
    80001842:	00000097          	auipc	ra,0x0
    80001846:	9e8080e7          	jalr	-1560(ra) # 8000122a <mappages>
  for(i = 0; i < sz; i += PGSIZE){
    8000184a:	6785                	lui	a5,0x1
    8000184c:	993e                	add	s2,s2,a5
    8000184e:	f9696ce3          	bltu	s2,s6,800017e6 <uvmcow+0x20>
    80001852:	a81d                	j	80001888 <uvmcow+0xc2>
      panic("uvmcopy: pte should exist");
    80001854:	00007517          	auipc	a0,0x7
    80001858:	97450513          	addi	a0,a0,-1676 # 800081c8 <digits+0x178>
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	ce4080e7          	jalr	-796(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001864:	00007517          	auipc	a0,0x7
    80001868:	98450513          	addi	a0,a0,-1660 # 800081e8 <digits+0x198>
    8000186c:	fffff097          	auipc	ra,0xfffff
    80001870:	cd4080e7          	jalr	-812(ra) # 80000540 <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001874:	4685                	li	a3,1
    80001876:	00c95613          	srli	a2,s2,0xc
    8000187a:	4581                	li	a1,0
    8000187c:	855e                	mv	a0,s7
    8000187e:	00000097          	auipc	ra,0x0
    80001882:	b72080e7          	jalr	-1166(ra) # 800013f0 <uvmunmap>
  return -1;
    80001886:	5a7d                	li	s4,-1
}
    80001888:	8552                	mv	a0,s4
    8000188a:	60a6                	ld	ra,72(sp)
    8000188c:	6406                	ld	s0,64(sp)
    8000188e:	74e2                	ld	s1,56(sp)
    80001890:	7942                	ld	s2,48(sp)
    80001892:	79a2                	ld	s3,40(sp)
    80001894:	7a02                	ld	s4,32(sp)
    80001896:	6ae2                	ld	s5,24(sp)
    80001898:	6b42                	ld	s6,16(sp)
    8000189a:	6ba2                	ld	s7,8(sp)
    8000189c:	6161                	addi	sp,sp,80
    8000189e:	8082                	ret
  return 0;
    800018a0:	4a01                	li	s4,0
    800018a2:	b7dd                	j	80001888 <uvmcow+0xc2>

00000000800018a4 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800018a4:	1141                	addi	sp,sp,-16
    800018a6:	e406                	sd	ra,8(sp)
    800018a8:	e022                	sd	s0,0(sp)
    800018aa:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800018ac:	4601                	li	a2,0
    800018ae:	00000097          	auipc	ra,0x0
    800018b2:	894080e7          	jalr	-1900(ra) # 80001142 <walk>
  if(pte == 0)
    800018b6:	c901                	beqz	a0,800018c6 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800018b8:	611c                	ld	a5,0(a0)
    800018ba:	9bbd                	andi	a5,a5,-17
    800018bc:	e11c                	sd	a5,0(a0)
}
    800018be:	60a2                	ld	ra,8(sp)
    800018c0:	6402                	ld	s0,0(sp)
    800018c2:	0141                	addi	sp,sp,16
    800018c4:	8082                	ret
    panic("uvmclear");
    800018c6:	00007517          	auipc	a0,0x7
    800018ca:	94250513          	addi	a0,a0,-1726 # 80008208 <digits+0x1b8>
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	c72080e7          	jalr	-910(ra) # 80000540 <panic>

00000000800018d6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018d6:	c6bd                	beqz	a3,80001944 <copyout+0x6e>
{
    800018d8:	715d                	addi	sp,sp,-80
    800018da:	e486                	sd	ra,72(sp)
    800018dc:	e0a2                	sd	s0,64(sp)
    800018de:	fc26                	sd	s1,56(sp)
    800018e0:	f84a                	sd	s2,48(sp)
    800018e2:	f44e                	sd	s3,40(sp)
    800018e4:	f052                	sd	s4,32(sp)
    800018e6:	ec56                	sd	s5,24(sp)
    800018e8:	e85a                	sd	s6,16(sp)
    800018ea:	e45e                	sd	s7,8(sp)
    800018ec:	e062                	sd	s8,0(sp)
    800018ee:	0880                	addi	s0,sp,80
    800018f0:	8b2a                	mv	s6,a0
    800018f2:	8c2e                	mv	s8,a1
    800018f4:	8a32                	mv	s4,a2
    800018f6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800018f8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800018fa:	6a85                	lui	s5,0x1
    800018fc:	a015                	j	80001920 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018fe:	9562                	add	a0,a0,s8
    80001900:	0004861b          	sext.w	a2,s1
    80001904:	85d2                	mv	a1,s4
    80001906:	41250533          	sub	a0,a0,s2
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	5b0080e7          	jalr	1456(ra) # 80000eba <memmove>

    len -= n;
    80001912:	409989b3          	sub	s3,s3,s1
    src += n;
    80001916:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001918:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000191c:	02098263          	beqz	s3,80001940 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001920:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001924:	85ca                	mv	a1,s2
    80001926:	855a                	mv	a0,s6
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	8c0080e7          	jalr	-1856(ra) # 800011e8 <walkaddr>
    if(pa0 == 0)
    80001930:	cd01                	beqz	a0,80001948 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001932:	418904b3          	sub	s1,s2,s8
    80001936:	94d6                	add	s1,s1,s5
    80001938:	fc99f3e3          	bgeu	s3,s1,800018fe <copyout+0x28>
    8000193c:	84ce                	mv	s1,s3
    8000193e:	b7c1                	j	800018fe <copyout+0x28>
  }
  return 0;
    80001940:	4501                	li	a0,0
    80001942:	a021                	j	8000194a <copyout+0x74>
    80001944:	4501                	li	a0,0
}
    80001946:	8082                	ret
      return -1;
    80001948:	557d                	li	a0,-1
}
    8000194a:	60a6                	ld	ra,72(sp)
    8000194c:	6406                	ld	s0,64(sp)
    8000194e:	74e2                	ld	s1,56(sp)
    80001950:	7942                	ld	s2,48(sp)
    80001952:	79a2                	ld	s3,40(sp)
    80001954:	7a02                	ld	s4,32(sp)
    80001956:	6ae2                	ld	s5,24(sp)
    80001958:	6b42                	ld	s6,16(sp)
    8000195a:	6ba2                	ld	s7,8(sp)
    8000195c:	6c02                	ld	s8,0(sp)
    8000195e:	6161                	addi	sp,sp,80
    80001960:	8082                	ret

0000000080001962 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001962:	caa5                	beqz	a3,800019d2 <copyin+0x70>
{
    80001964:	715d                	addi	sp,sp,-80
    80001966:	e486                	sd	ra,72(sp)
    80001968:	e0a2                	sd	s0,64(sp)
    8000196a:	fc26                	sd	s1,56(sp)
    8000196c:	f84a                	sd	s2,48(sp)
    8000196e:	f44e                	sd	s3,40(sp)
    80001970:	f052                	sd	s4,32(sp)
    80001972:	ec56                	sd	s5,24(sp)
    80001974:	e85a                	sd	s6,16(sp)
    80001976:	e45e                	sd	s7,8(sp)
    80001978:	e062                	sd	s8,0(sp)
    8000197a:	0880                	addi	s0,sp,80
    8000197c:	8b2a                	mv	s6,a0
    8000197e:	8a2e                	mv	s4,a1
    80001980:	8c32                	mv	s8,a2
    80001982:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001984:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001986:	6a85                	lui	s5,0x1
    80001988:	a01d                	j	800019ae <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000198a:	018505b3          	add	a1,a0,s8
    8000198e:	0004861b          	sext.w	a2,s1
    80001992:	412585b3          	sub	a1,a1,s2
    80001996:	8552                	mv	a0,s4
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	522080e7          	jalr	1314(ra) # 80000eba <memmove>

    len -= n;
    800019a0:	409989b3          	sub	s3,s3,s1
    dst += n;
    800019a4:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800019a6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800019aa:	02098263          	beqz	s3,800019ce <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800019ae:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019b2:	85ca                	mv	a1,s2
    800019b4:	855a                	mv	a0,s6
    800019b6:	00000097          	auipc	ra,0x0
    800019ba:	832080e7          	jalr	-1998(ra) # 800011e8 <walkaddr>
    if(pa0 == 0)
    800019be:	cd01                	beqz	a0,800019d6 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800019c0:	418904b3          	sub	s1,s2,s8
    800019c4:	94d6                	add	s1,s1,s5
    800019c6:	fc99f2e3          	bgeu	s3,s1,8000198a <copyin+0x28>
    800019ca:	84ce                	mv	s1,s3
    800019cc:	bf7d                	j	8000198a <copyin+0x28>
  }
  return 0;
    800019ce:	4501                	li	a0,0
    800019d0:	a021                	j	800019d8 <copyin+0x76>
    800019d2:	4501                	li	a0,0
}
    800019d4:	8082                	ret
      return -1;
    800019d6:	557d                	li	a0,-1
}
    800019d8:	60a6                	ld	ra,72(sp)
    800019da:	6406                	ld	s0,64(sp)
    800019dc:	74e2                	ld	s1,56(sp)
    800019de:	7942                	ld	s2,48(sp)
    800019e0:	79a2                	ld	s3,40(sp)
    800019e2:	7a02                	ld	s4,32(sp)
    800019e4:	6ae2                	ld	s5,24(sp)
    800019e6:	6b42                	ld	s6,16(sp)
    800019e8:	6ba2                	ld	s7,8(sp)
    800019ea:	6c02                	ld	s8,0(sp)
    800019ec:	6161                	addi	sp,sp,80
    800019ee:	8082                	ret

00000000800019f0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800019f0:	c2dd                	beqz	a3,80001a96 <copyinstr+0xa6>
{
    800019f2:	715d                	addi	sp,sp,-80
    800019f4:	e486                	sd	ra,72(sp)
    800019f6:	e0a2                	sd	s0,64(sp)
    800019f8:	fc26                	sd	s1,56(sp)
    800019fa:	f84a                	sd	s2,48(sp)
    800019fc:	f44e                	sd	s3,40(sp)
    800019fe:	f052                	sd	s4,32(sp)
    80001a00:	ec56                	sd	s5,24(sp)
    80001a02:	e85a                	sd	s6,16(sp)
    80001a04:	e45e                	sd	s7,8(sp)
    80001a06:	0880                	addi	s0,sp,80
    80001a08:	8a2a                	mv	s4,a0
    80001a0a:	8b2e                	mv	s6,a1
    80001a0c:	8bb2                	mv	s7,a2
    80001a0e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001a10:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a12:	6985                	lui	s3,0x1
    80001a14:	a02d                	j	80001a3e <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001a16:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a1a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001a1c:	37fd                	addiw	a5,a5,-1
    80001a1e:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001a22:	60a6                	ld	ra,72(sp)
    80001a24:	6406                	ld	s0,64(sp)
    80001a26:	74e2                	ld	s1,56(sp)
    80001a28:	7942                	ld	s2,48(sp)
    80001a2a:	79a2                	ld	s3,40(sp)
    80001a2c:	7a02                	ld	s4,32(sp)
    80001a2e:	6ae2                	ld	s5,24(sp)
    80001a30:	6b42                	ld	s6,16(sp)
    80001a32:	6ba2                	ld	s7,8(sp)
    80001a34:	6161                	addi	sp,sp,80
    80001a36:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a38:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001a3c:	c8a9                	beqz	s1,80001a8e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001a3e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a42:	85ca                	mv	a1,s2
    80001a44:	8552                	mv	a0,s4
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	7a2080e7          	jalr	1954(ra) # 800011e8 <walkaddr>
    if(pa0 == 0)
    80001a4e:	c131                	beqz	a0,80001a92 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001a50:	417906b3          	sub	a3,s2,s7
    80001a54:	96ce                	add	a3,a3,s3
    80001a56:	00d4f363          	bgeu	s1,a3,80001a5c <copyinstr+0x6c>
    80001a5a:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001a5c:	955e                	add	a0,a0,s7
    80001a5e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a62:	daf9                	beqz	a3,80001a38 <copyinstr+0x48>
    80001a64:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001a66:	41650633          	sub	a2,a0,s6
    80001a6a:	fff48593          	addi	a1,s1,-1
    80001a6e:	95da                	add	a1,a1,s6
    while(n > 0){
    80001a70:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001a72:	00f60733          	add	a4,a2,a5
    80001a76:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbd0f0>
    80001a7a:	df51                	beqz	a4,80001a16 <copyinstr+0x26>
        *dst = *p;
    80001a7c:	00e78023          	sb	a4,0(a5)
      --max;
    80001a80:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001a84:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a86:	fed796e3          	bne	a5,a3,80001a72 <copyinstr+0x82>
      dst++;
    80001a8a:	8b3e                	mv	s6,a5
    80001a8c:	b775                	j	80001a38 <copyinstr+0x48>
    80001a8e:	4781                	li	a5,0
    80001a90:	b771                	j	80001a1c <copyinstr+0x2c>
      return -1;
    80001a92:	557d                	li	a0,-1
    80001a94:	b779                	j	80001a22 <copyinstr+0x32>
  int got_null = 0;
    80001a96:	4781                	li	a5,0
  if(got_null){
    80001a98:	37fd                	addiw	a5,a5,-1
    80001a9a:	0007851b          	sext.w	a0,a5
}
    80001a9e:	8082                	ret

0000000080001aa0 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001aa0:	715d                	addi	sp,sp,-80
    80001aa2:	e486                	sd	ra,72(sp)
    80001aa4:	e0a2                	sd	s0,64(sp)
    80001aa6:	fc26                	sd	s1,56(sp)
    80001aa8:	f84a                	sd	s2,48(sp)
    80001aaa:	f44e                	sd	s3,40(sp)
    80001aac:	f052                	sd	s4,32(sp)
    80001aae:	ec56                	sd	s5,24(sp)
    80001ab0:	e85a                	sd	s6,16(sp)
    80001ab2:	e45e                	sd	s7,8(sp)
    80001ab4:	e062                	sd	s8,0(sp)
    80001ab6:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ab8:	8792                	mv	a5,tp
    int id = r_tp();
    80001aba:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001abc:	0002fa97          	auipc	s5,0x2f
    80001ac0:	244a8a93          	addi	s5,s5,580 # 80030d00 <cpus>
    80001ac4:	00779713          	slli	a4,a5,0x7
    80001ac8:	00ea86b3          	add	a3,s5,a4
    80001acc:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffbd0f0>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001ad0:	0721                	addi	a4,a4,8
    80001ad2:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001ad4:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001ad6:	00007c17          	auipc	s8,0x7
    80001ada:	ee2c0c13          	addi	s8,s8,-286 # 800089b8 <sched_pointer>
    80001ade:	00000b97          	auipc	s7,0x0
    80001ae2:	fc2b8b93          	addi	s7,s7,-62 # 80001aa0 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ae6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001aea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001aee:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001af2:	0002f497          	auipc	s1,0x2f
    80001af6:	63e48493          	addi	s1,s1,1598 # 80031130 <proc>
            if (p->state == RUNNABLE)
    80001afa:	498d                	li	s3,3
                p->state = RUNNING;
    80001afc:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001afe:	00035a17          	auipc	s4,0x35
    80001b02:	032a0a13          	addi	s4,s4,50 # 80036b30 <tickslock>
    80001b06:	a81d                	j	80001b3c <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001b08:	8526                	mv	a0,s1
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	30c080e7          	jalr	780(ra) # 80000e16 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001b12:	60a6                	ld	ra,72(sp)
    80001b14:	6406                	ld	s0,64(sp)
    80001b16:	74e2                	ld	s1,56(sp)
    80001b18:	7942                	ld	s2,48(sp)
    80001b1a:	79a2                	ld	s3,40(sp)
    80001b1c:	7a02                	ld	s4,32(sp)
    80001b1e:	6ae2                	ld	s5,24(sp)
    80001b20:	6b42                	ld	s6,16(sp)
    80001b22:	6ba2                	ld	s7,8(sp)
    80001b24:	6c02                	ld	s8,0(sp)
    80001b26:	6161                	addi	sp,sp,80
    80001b28:	8082                	ret
            release(&p->lock);
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	2ea080e7          	jalr	746(ra) # 80000e16 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001b34:	16848493          	addi	s1,s1,360
    80001b38:	fb4487e3          	beq	s1,s4,80001ae6 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	224080e7          	jalr	548(ra) # 80000d62 <acquire>
            if (p->state == RUNNABLE)
    80001b46:	4c9c                	lw	a5,24(s1)
    80001b48:	ff3791e3          	bne	a5,s3,80001b2a <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001b4c:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001b50:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001b54:	06048593          	addi	a1,s1,96
    80001b58:	8556                	mv	a0,s5
    80001b5a:	00001097          	auipc	ra,0x1
    80001b5e:	fae080e7          	jalr	-82(ra) # 80002b08 <swtch>
                if (sched_pointer != &rr_scheduler)
    80001b62:	000c3783          	ld	a5,0(s8)
    80001b66:	fb7791e3          	bne	a5,s7,80001b08 <rr_scheduler+0x68>
                c->proc = 0;
    80001b6a:	00093023          	sd	zero,0(s2)
    80001b6e:	bf75                	j	80001b2a <rr_scheduler+0x8a>

0000000080001b70 <proc_mapstacks>:
{
    80001b70:	7139                	addi	sp,sp,-64
    80001b72:	fc06                	sd	ra,56(sp)
    80001b74:	f822                	sd	s0,48(sp)
    80001b76:	f426                	sd	s1,40(sp)
    80001b78:	f04a                	sd	s2,32(sp)
    80001b7a:	ec4e                	sd	s3,24(sp)
    80001b7c:	e852                	sd	s4,16(sp)
    80001b7e:	e456                	sd	s5,8(sp)
    80001b80:	e05a                	sd	s6,0(sp)
    80001b82:	0080                	addi	s0,sp,64
    80001b84:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001b86:	0002f497          	auipc	s1,0x2f
    80001b8a:	5aa48493          	addi	s1,s1,1450 # 80031130 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001b8e:	8b26                	mv	s6,s1
    80001b90:	00006a97          	auipc	s5,0x6
    80001b94:	480a8a93          	addi	s5,s5,1152 # 80008010 <__func__.1+0x8>
    80001b98:	04000937          	lui	s2,0x4000
    80001b9c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b9e:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001ba0:	00035a17          	auipc	s4,0x35
    80001ba4:	f90a0a13          	addi	s4,s4,-112 # 80036b30 <tickslock>
        char *pa = kalloc();
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	fba080e7          	jalr	-70(ra) # 80000b62 <kalloc>
    80001bb0:	862a                	mv	a2,a0
        if (pa == 0)
    80001bb2:	c131                	beqz	a0,80001bf6 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001bb4:	416485b3          	sub	a1,s1,s6
    80001bb8:	858d                	srai	a1,a1,0x3
    80001bba:	000ab783          	ld	a5,0(s5)
    80001bbe:	02f585b3          	mul	a1,a1,a5
    80001bc2:	2585                	addiw	a1,a1,1
    80001bc4:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bc8:	4719                	li	a4,6
    80001bca:	6685                	lui	a3,0x1
    80001bcc:	40b905b3          	sub	a1,s2,a1
    80001bd0:	854e                	mv	a0,s3
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	6f8080e7          	jalr	1784(ra) # 800012ca <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001bda:	16848493          	addi	s1,s1,360
    80001bde:	fd4495e3          	bne	s1,s4,80001ba8 <proc_mapstacks+0x38>
}
    80001be2:	70e2                	ld	ra,56(sp)
    80001be4:	7442                	ld	s0,48(sp)
    80001be6:	74a2                	ld	s1,40(sp)
    80001be8:	7902                	ld	s2,32(sp)
    80001bea:	69e2                	ld	s3,24(sp)
    80001bec:	6a42                	ld	s4,16(sp)
    80001bee:	6aa2                	ld	s5,8(sp)
    80001bf0:	6b02                	ld	s6,0(sp)
    80001bf2:	6121                	addi	sp,sp,64
    80001bf4:	8082                	ret
            panic("kalloc");
    80001bf6:	00006517          	auipc	a0,0x6
    80001bfa:	62250513          	addi	a0,a0,1570 # 80008218 <digits+0x1c8>
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	942080e7          	jalr	-1726(ra) # 80000540 <panic>

0000000080001c06 <procinit>:
{
    80001c06:	7139                	addi	sp,sp,-64
    80001c08:	fc06                	sd	ra,56(sp)
    80001c0a:	f822                	sd	s0,48(sp)
    80001c0c:	f426                	sd	s1,40(sp)
    80001c0e:	f04a                	sd	s2,32(sp)
    80001c10:	ec4e                	sd	s3,24(sp)
    80001c12:	e852                	sd	s4,16(sp)
    80001c14:	e456                	sd	s5,8(sp)
    80001c16:	e05a                	sd	s6,0(sp)
    80001c18:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001c1a:	00006597          	auipc	a1,0x6
    80001c1e:	60658593          	addi	a1,a1,1542 # 80008220 <digits+0x1d0>
    80001c22:	0002f517          	auipc	a0,0x2f
    80001c26:	4de50513          	addi	a0,a0,1246 # 80031100 <pid_lock>
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	0a8080e7          	jalr	168(ra) # 80000cd2 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001c32:	00006597          	auipc	a1,0x6
    80001c36:	5f658593          	addi	a1,a1,1526 # 80008228 <digits+0x1d8>
    80001c3a:	0002f517          	auipc	a0,0x2f
    80001c3e:	4de50513          	addi	a0,a0,1246 # 80031118 <wait_lock>
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	090080e7          	jalr	144(ra) # 80000cd2 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001c4a:	0002f497          	auipc	s1,0x2f
    80001c4e:	4e648493          	addi	s1,s1,1254 # 80031130 <proc>
        initlock(&p->lock, "proc");
    80001c52:	00006b17          	auipc	s6,0x6
    80001c56:	5e6b0b13          	addi	s6,s6,1510 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001c5a:	8aa6                	mv	s5,s1
    80001c5c:	00006a17          	auipc	s4,0x6
    80001c60:	3b4a0a13          	addi	s4,s4,948 # 80008010 <__func__.1+0x8>
    80001c64:	04000937          	lui	s2,0x4000
    80001c68:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001c6a:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001c6c:	00035997          	auipc	s3,0x35
    80001c70:	ec498993          	addi	s3,s3,-316 # 80036b30 <tickslock>
        initlock(&p->lock, "proc");
    80001c74:	85da                	mv	a1,s6
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	05a080e7          	jalr	90(ra) # 80000cd2 <initlock>
        p->state = UNUSED;
    80001c80:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001c84:	415487b3          	sub	a5,s1,s5
    80001c88:	878d                	srai	a5,a5,0x3
    80001c8a:	000a3703          	ld	a4,0(s4)
    80001c8e:	02e787b3          	mul	a5,a5,a4
    80001c92:	2785                	addiw	a5,a5,1
    80001c94:	00d7979b          	slliw	a5,a5,0xd
    80001c98:	40f907b3          	sub	a5,s2,a5
    80001c9c:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001c9e:	16848493          	addi	s1,s1,360
    80001ca2:	fd3499e3          	bne	s1,s3,80001c74 <procinit+0x6e>
}
    80001ca6:	70e2                	ld	ra,56(sp)
    80001ca8:	7442                	ld	s0,48(sp)
    80001caa:	74a2                	ld	s1,40(sp)
    80001cac:	7902                	ld	s2,32(sp)
    80001cae:	69e2                	ld	s3,24(sp)
    80001cb0:	6a42                	ld	s4,16(sp)
    80001cb2:	6aa2                	ld	s5,8(sp)
    80001cb4:	6b02                	ld	s6,0(sp)
    80001cb6:	6121                	addi	sp,sp,64
    80001cb8:	8082                	ret

0000000080001cba <copy_array>:
{
    80001cba:	1141                	addi	sp,sp,-16
    80001cbc:	e422                	sd	s0,8(sp)
    80001cbe:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001cc0:	02c05163          	blez	a2,80001ce2 <copy_array+0x28>
    80001cc4:	87aa                	mv	a5,a0
    80001cc6:	0505                	addi	a0,a0,1
    80001cc8:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001cca:	1602                	slli	a2,a2,0x20
    80001ccc:	9201                	srli	a2,a2,0x20
    80001cce:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001cd2:	0007c703          	lbu	a4,0(a5)
    80001cd6:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001cda:	0785                	addi	a5,a5,1
    80001cdc:	0585                	addi	a1,a1,1
    80001cde:	fed79ae3          	bne	a5,a3,80001cd2 <copy_array+0x18>
}
    80001ce2:	6422                	ld	s0,8(sp)
    80001ce4:	0141                	addi	sp,sp,16
    80001ce6:	8082                	ret

0000000080001ce8 <cpuid>:
{
    80001ce8:	1141                	addi	sp,sp,-16
    80001cea:	e422                	sd	s0,8(sp)
    80001cec:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cee:	8512                	mv	a0,tp
}
    80001cf0:	2501                	sext.w	a0,a0
    80001cf2:	6422                	ld	s0,8(sp)
    80001cf4:	0141                	addi	sp,sp,16
    80001cf6:	8082                	ret

0000000080001cf8 <mycpu>:
{
    80001cf8:	1141                	addi	sp,sp,-16
    80001cfa:	e422                	sd	s0,8(sp)
    80001cfc:	0800                	addi	s0,sp,16
    80001cfe:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001d00:	2781                	sext.w	a5,a5
    80001d02:	079e                	slli	a5,a5,0x7
}
    80001d04:	0002f517          	auipc	a0,0x2f
    80001d08:	ffc50513          	addi	a0,a0,-4 # 80030d00 <cpus>
    80001d0c:	953e                	add	a0,a0,a5
    80001d0e:	6422                	ld	s0,8(sp)
    80001d10:	0141                	addi	sp,sp,16
    80001d12:	8082                	ret

0000000080001d14 <myproc>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	1000                	addi	s0,sp,32
    push_off();
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	ff8080e7          	jalr	-8(ra) # 80000d16 <push_off>
    80001d26:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001d28:	2781                	sext.w	a5,a5
    80001d2a:	079e                	slli	a5,a5,0x7
    80001d2c:	0002f717          	auipc	a4,0x2f
    80001d30:	fd470713          	addi	a4,a4,-44 # 80030d00 <cpus>
    80001d34:	97ba                	add	a5,a5,a4
    80001d36:	6384                	ld	s1,0(a5)
    pop_off();
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	07e080e7          	jalr	126(ra) # 80000db6 <pop_off>
}
    80001d40:	8526                	mv	a0,s1
    80001d42:	60e2                	ld	ra,24(sp)
    80001d44:	6442                	ld	s0,16(sp)
    80001d46:	64a2                	ld	s1,8(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret

0000000080001d4c <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d4c:	1141                	addi	sp,sp,-16
    80001d4e:	e406                	sd	ra,8(sp)
    80001d50:	e022                	sd	s0,0(sp)
    80001d52:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001d54:	00000097          	auipc	ra,0x0
    80001d58:	fc0080e7          	jalr	-64(ra) # 80001d14 <myproc>
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	0ba080e7          	jalr	186(ra) # 80000e16 <release>

    if (first)
    80001d64:	00007797          	auipc	a5,0x7
    80001d68:	c4c7a783          	lw	a5,-948(a5) # 800089b0 <first.1>
    80001d6c:	eb89                	bnez	a5,80001d7e <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001d6e:	00001097          	auipc	ra,0x1
    80001d72:	e52080e7          	jalr	-430(ra) # 80002bc0 <usertrapret>
}
    80001d76:	60a2                	ld	ra,8(sp)
    80001d78:	6402                	ld	s0,0(sp)
    80001d7a:	0141                	addi	sp,sp,16
    80001d7c:	8082                	ret
        first = 0;
    80001d7e:	00007797          	auipc	a5,0x7
    80001d82:	c207a923          	sw	zero,-974(a5) # 800089b0 <first.1>
        fsinit(ROOTDEV);
    80001d86:	4505                	li	a0,1
    80001d88:	00002097          	auipc	ra,0x2
    80001d8c:	dce080e7          	jalr	-562(ra) # 80003b56 <fsinit>
    80001d90:	bff9                	j	80001d6e <forkret+0x22>

0000000080001d92 <allocpid>:
{
    80001d92:	1101                	addi	sp,sp,-32
    80001d94:	ec06                	sd	ra,24(sp)
    80001d96:	e822                	sd	s0,16(sp)
    80001d98:	e426                	sd	s1,8(sp)
    80001d9a:	e04a                	sd	s2,0(sp)
    80001d9c:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001d9e:	0002f917          	auipc	s2,0x2f
    80001da2:	36290913          	addi	s2,s2,866 # 80031100 <pid_lock>
    80001da6:	854a                	mv	a0,s2
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	fba080e7          	jalr	-70(ra) # 80000d62 <acquire>
    pid = nextpid;
    80001db0:	00007797          	auipc	a5,0x7
    80001db4:	c1078793          	addi	a5,a5,-1008 # 800089c0 <nextpid>
    80001db8:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001dba:	0014871b          	addiw	a4,s1,1
    80001dbe:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001dc0:	854a                	mv	a0,s2
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	054080e7          	jalr	84(ra) # 80000e16 <release>
}
    80001dca:	8526                	mv	a0,s1
    80001dcc:	60e2                	ld	ra,24(sp)
    80001dce:	6442                	ld	s0,16(sp)
    80001dd0:	64a2                	ld	s1,8(sp)
    80001dd2:	6902                	ld	s2,0(sp)
    80001dd4:	6105                	addi	sp,sp,32
    80001dd6:	8082                	ret

0000000080001dd8 <proc_pagetable>:
{
    80001dd8:	1101                	addi	sp,sp,-32
    80001dda:	ec06                	sd	ra,24(sp)
    80001ddc:	e822                	sd	s0,16(sp)
    80001dde:	e426                	sd	s1,8(sp)
    80001de0:	e04a                	sd	s2,0(sp)
    80001de2:	1000                	addi	s0,sp,32
    80001de4:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	6ce080e7          	jalr	1742(ra) # 800014b4 <uvmcreate>
    80001dee:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001df0:	c121                	beqz	a0,80001e30 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001df2:	4729                	li	a4,10
    80001df4:	00005697          	auipc	a3,0x5
    80001df8:	20c68693          	addi	a3,a3,524 # 80007000 <_trampoline>
    80001dfc:	6605                	lui	a2,0x1
    80001dfe:	040005b7          	lui	a1,0x4000
    80001e02:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e04:	05b2                	slli	a1,a1,0xc
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	424080e7          	jalr	1060(ra) # 8000122a <mappages>
    80001e0e:	02054863          	bltz	a0,80001e3e <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e12:	4719                	li	a4,6
    80001e14:	05893683          	ld	a3,88(s2)
    80001e18:	6605                	lui	a2,0x1
    80001e1a:	020005b7          	lui	a1,0x2000
    80001e1e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e20:	05b6                	slli	a1,a1,0xd
    80001e22:	8526                	mv	a0,s1
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	406080e7          	jalr	1030(ra) # 8000122a <mappages>
    80001e2c:	02054163          	bltz	a0,80001e4e <proc_pagetable+0x76>
}
    80001e30:	8526                	mv	a0,s1
    80001e32:	60e2                	ld	ra,24(sp)
    80001e34:	6442                	ld	s0,16(sp)
    80001e36:	64a2                	ld	s1,8(sp)
    80001e38:	6902                	ld	s2,0(sp)
    80001e3a:	6105                	addi	sp,sp,32
    80001e3c:	8082                	ret
        uvmfree(pagetable, 0);
    80001e3e:	4581                	li	a1,0
    80001e40:	8526                	mv	a0,s1
    80001e42:	00000097          	auipc	ra,0x0
    80001e46:	878080e7          	jalr	-1928(ra) # 800016ba <uvmfree>
        return 0;
    80001e4a:	4481                	li	s1,0
    80001e4c:	b7d5                	j	80001e30 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e4e:	4681                	li	a3,0
    80001e50:	4605                	li	a2,1
    80001e52:	040005b7          	lui	a1,0x4000
    80001e56:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e58:	05b2                	slli	a1,a1,0xc
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	594080e7          	jalr	1428(ra) # 800013f0 <uvmunmap>
        uvmfree(pagetable, 0);
    80001e64:	4581                	li	a1,0
    80001e66:	8526                	mv	a0,s1
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	852080e7          	jalr	-1966(ra) # 800016ba <uvmfree>
        return 0;
    80001e70:	4481                	li	s1,0
    80001e72:	bf7d                	j	80001e30 <proc_pagetable+0x58>

0000000080001e74 <proc_freepagetable>:
{
    80001e74:	1101                	addi	sp,sp,-32
    80001e76:	ec06                	sd	ra,24(sp)
    80001e78:	e822                	sd	s0,16(sp)
    80001e7a:	e426                	sd	s1,8(sp)
    80001e7c:	e04a                	sd	s2,0(sp)
    80001e7e:	1000                	addi	s0,sp,32
    80001e80:	84aa                	mv	s1,a0
    80001e82:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e84:	4681                	li	a3,0
    80001e86:	4605                	li	a2,1
    80001e88:	040005b7          	lui	a1,0x4000
    80001e8c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e8e:	05b2                	slli	a1,a1,0xc
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	560080e7          	jalr	1376(ra) # 800013f0 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e98:	4681                	li	a3,0
    80001e9a:	4605                	li	a2,1
    80001e9c:	020005b7          	lui	a1,0x2000
    80001ea0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ea2:	05b6                	slli	a1,a1,0xd
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	54a080e7          	jalr	1354(ra) # 800013f0 <uvmunmap>
    uvmfree(pagetable, sz);
    80001eae:	85ca                	mv	a1,s2
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	808080e7          	jalr	-2040(ra) # 800016ba <uvmfree>
}
    80001eba:	60e2                	ld	ra,24(sp)
    80001ebc:	6442                	ld	s0,16(sp)
    80001ebe:	64a2                	ld	s1,8(sp)
    80001ec0:	6902                	ld	s2,0(sp)
    80001ec2:	6105                	addi	sp,sp,32
    80001ec4:	8082                	ret

0000000080001ec6 <freeproc>:
{
    80001ec6:	1101                	addi	sp,sp,-32
    80001ec8:	ec06                	sd	ra,24(sp)
    80001eca:	e822                	sd	s0,16(sp)
    80001ecc:	e426                	sd	s1,8(sp)
    80001ece:	1000                	addi	s0,sp,32
    80001ed0:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001ed2:	6d28                	ld	a0,88(a0)
    80001ed4:	c509                	beqz	a0,80001ede <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	b24080e7          	jalr	-1244(ra) # 800009fa <kfree>
    p->trapframe = 0;
    80001ede:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001ee2:	68a8                	ld	a0,80(s1)
    80001ee4:	c511                	beqz	a0,80001ef0 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001ee6:	64ac                	ld	a1,72(s1)
    80001ee8:	00000097          	auipc	ra,0x0
    80001eec:	f8c080e7          	jalr	-116(ra) # 80001e74 <proc_freepagetable>
    p->pagetable = 0;
    80001ef0:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001ef4:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001ef8:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001efc:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001f00:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001f04:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001f08:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001f0c:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001f10:	0004ac23          	sw	zero,24(s1)
}
    80001f14:	60e2                	ld	ra,24(sp)
    80001f16:	6442                	ld	s0,16(sp)
    80001f18:	64a2                	ld	s1,8(sp)
    80001f1a:	6105                	addi	sp,sp,32
    80001f1c:	8082                	ret

0000000080001f1e <allocproc>:
{
    80001f1e:	1101                	addi	sp,sp,-32
    80001f20:	ec06                	sd	ra,24(sp)
    80001f22:	e822                	sd	s0,16(sp)
    80001f24:	e426                	sd	s1,8(sp)
    80001f26:	e04a                	sd	s2,0(sp)
    80001f28:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001f2a:	0002f497          	auipc	s1,0x2f
    80001f2e:	20648493          	addi	s1,s1,518 # 80031130 <proc>
    80001f32:	00035917          	auipc	s2,0x35
    80001f36:	bfe90913          	addi	s2,s2,-1026 # 80036b30 <tickslock>
        acquire(&p->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	e26080e7          	jalr	-474(ra) # 80000d62 <acquire>
        if (p->state == UNUSED)
    80001f44:	4c9c                	lw	a5,24(s1)
    80001f46:	cf81                	beqz	a5,80001f5e <allocproc+0x40>
            release(&p->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	ecc080e7          	jalr	-308(ra) # 80000e16 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f52:	16848493          	addi	s1,s1,360
    80001f56:	ff2492e3          	bne	s1,s2,80001f3a <allocproc+0x1c>
    return 0;
    80001f5a:	4481                	li	s1,0
    80001f5c:	a889                	j	80001fae <allocproc+0x90>
    p->pid = allocpid();
    80001f5e:	00000097          	auipc	ra,0x0
    80001f62:	e34080e7          	jalr	-460(ra) # 80001d92 <allocpid>
    80001f66:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001f68:	4785                	li	a5,1
    80001f6a:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	bf6080e7          	jalr	-1034(ra) # 80000b62 <kalloc>
    80001f74:	892a                	mv	s2,a0
    80001f76:	eca8                	sd	a0,88(s1)
    80001f78:	c131                	beqz	a0,80001fbc <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001f7a:	8526                	mv	a0,s1
    80001f7c:	00000097          	auipc	ra,0x0
    80001f80:	e5c080e7          	jalr	-420(ra) # 80001dd8 <proc_pagetable>
    80001f84:	892a                	mv	s2,a0
    80001f86:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001f88:	c531                	beqz	a0,80001fd4 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001f8a:	07000613          	li	a2,112
    80001f8e:	4581                	li	a1,0
    80001f90:	06048513          	addi	a0,s1,96
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	eca080e7          	jalr	-310(ra) # 80000e5e <memset>
    p->context.ra = (uint64)forkret;
    80001f9c:	00000797          	auipc	a5,0x0
    80001fa0:	db078793          	addi	a5,a5,-592 # 80001d4c <forkret>
    80001fa4:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001fa6:	60bc                	ld	a5,64(s1)
    80001fa8:	6705                	lui	a4,0x1
    80001faa:	97ba                	add	a5,a5,a4
    80001fac:	f4bc                	sd	a5,104(s1)
}
    80001fae:	8526                	mv	a0,s1
    80001fb0:	60e2                	ld	ra,24(sp)
    80001fb2:	6442                	ld	s0,16(sp)
    80001fb4:	64a2                	ld	s1,8(sp)
    80001fb6:	6902                	ld	s2,0(sp)
    80001fb8:	6105                	addi	sp,sp,32
    80001fba:	8082                	ret
        freeproc(p);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	f08080e7          	jalr	-248(ra) # 80001ec6 <freeproc>
        release(&p->lock);
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	e4e080e7          	jalr	-434(ra) # 80000e16 <release>
        return 0;
    80001fd0:	84ca                	mv	s1,s2
    80001fd2:	bff1                	j	80001fae <allocproc+0x90>
        freeproc(p);
    80001fd4:	8526                	mv	a0,s1
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	ef0080e7          	jalr	-272(ra) # 80001ec6 <freeproc>
        release(&p->lock);
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	e36080e7          	jalr	-458(ra) # 80000e16 <release>
        return 0;
    80001fe8:	84ca                	mv	s1,s2
    80001fea:	b7d1                	j	80001fae <allocproc+0x90>

0000000080001fec <userinit>:
{
    80001fec:	1101                	addi	sp,sp,-32
    80001fee:	ec06                	sd	ra,24(sp)
    80001ff0:	e822                	sd	s0,16(sp)
    80001ff2:	e426                	sd	s1,8(sp)
    80001ff4:	1000                	addi	s0,sp,32
    p = allocproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	f28080e7          	jalr	-216(ra) # 80001f1e <allocproc>
    80001ffe:	84aa                	mv	s1,a0
    initproc = p;
    80002000:	00007797          	auipc	a5,0x7
    80002004:	a8a7b423          	sd	a0,-1400(a5) # 80008a88 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80002008:	03400613          	li	a2,52
    8000200c:	00007597          	auipc	a1,0x7
    80002010:	9c458593          	addi	a1,a1,-1596 # 800089d0 <initcode>
    80002014:	6928                	ld	a0,80(a0)
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	4cc080e7          	jalr	1228(ra) # 800014e2 <uvmfirst>
    p->sz = PGSIZE;
    8000201e:	6785                	lui	a5,0x1
    80002020:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80002022:	6cb8                	ld	a4,88(s1)
    80002024:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80002028:	6cb8                	ld	a4,88(s1)
    8000202a:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    8000202c:	4641                	li	a2,16
    8000202e:	00006597          	auipc	a1,0x6
    80002032:	21258593          	addi	a1,a1,530 # 80008240 <digits+0x1f0>
    80002036:	15848513          	addi	a0,s1,344
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	f6e080e7          	jalr	-146(ra) # 80000fa8 <safestrcpy>
    p->cwd = namei("/");
    80002042:	00006517          	auipc	a0,0x6
    80002046:	20e50513          	addi	a0,a0,526 # 80008250 <digits+0x200>
    8000204a:	00002097          	auipc	ra,0x2
    8000204e:	536080e7          	jalr	1334(ra) # 80004580 <namei>
    80002052:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80002056:	478d                	li	a5,3
    80002058:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    8000205a:	8526                	mv	a0,s1
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	dba080e7          	jalr	-582(ra) # 80000e16 <release>
}
    80002064:	60e2                	ld	ra,24(sp)
    80002066:	6442                	ld	s0,16(sp)
    80002068:	64a2                	ld	s1,8(sp)
    8000206a:	6105                	addi	sp,sp,32
    8000206c:	8082                	ret

000000008000206e <growproc>:
{
    8000206e:	1101                	addi	sp,sp,-32
    80002070:	ec06                	sd	ra,24(sp)
    80002072:	e822                	sd	s0,16(sp)
    80002074:	e426                	sd	s1,8(sp)
    80002076:	e04a                	sd	s2,0(sp)
    80002078:	1000                	addi	s0,sp,32
    8000207a:	892a                	mv	s2,a0
    struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	c98080e7          	jalr	-872(ra) # 80001d14 <myproc>
    80002084:	84aa                	mv	s1,a0
    sz = p->sz;
    80002086:	652c                	ld	a1,72(a0)
    if (n > 0)
    80002088:	01204c63          	bgtz	s2,800020a0 <growproc+0x32>
    else if (n < 0)
    8000208c:	02094663          	bltz	s2,800020b8 <growproc+0x4a>
    p->sz = sz;
    80002090:	e4ac                	sd	a1,72(s1)
    return 0;
    80002092:	4501                	li	a0,0
}
    80002094:	60e2                	ld	ra,24(sp)
    80002096:	6442                	ld	s0,16(sp)
    80002098:	64a2                	ld	s1,8(sp)
    8000209a:	6902                	ld	s2,0(sp)
    8000209c:	6105                	addi	sp,sp,32
    8000209e:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    800020a0:	4691                	li	a3,4
    800020a2:	00b90633          	add	a2,s2,a1
    800020a6:	6928                	ld	a0,80(a0)
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	4f4080e7          	jalr	1268(ra) # 8000159c <uvmalloc>
    800020b0:	85aa                	mv	a1,a0
    800020b2:	fd79                	bnez	a0,80002090 <growproc+0x22>
            return -1;
    800020b4:	557d                	li	a0,-1
    800020b6:	bff9                	j	80002094 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020b8:	00b90633          	add	a2,s2,a1
    800020bc:	6928                	ld	a0,80(a0)
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	496080e7          	jalr	1174(ra) # 80001554 <uvmdealloc>
    800020c6:	85aa                	mv	a1,a0
    800020c8:	b7e1                	j	80002090 <growproc+0x22>

00000000800020ca <ps>:
{
    800020ca:	715d                	addi	sp,sp,-80
    800020cc:	e486                	sd	ra,72(sp)
    800020ce:	e0a2                	sd	s0,64(sp)
    800020d0:	fc26                	sd	s1,56(sp)
    800020d2:	f84a                	sd	s2,48(sp)
    800020d4:	f44e                	sd	s3,40(sp)
    800020d6:	f052                	sd	s4,32(sp)
    800020d8:	ec56                	sd	s5,24(sp)
    800020da:	e85a                	sd	s6,16(sp)
    800020dc:	e45e                	sd	s7,8(sp)
    800020de:	e062                	sd	s8,0(sp)
    800020e0:	0880                	addi	s0,sp,80
    800020e2:	84aa                	mv	s1,a0
    800020e4:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    800020e6:	00000097          	auipc	ra,0x0
    800020ea:	c2e080e7          	jalr	-978(ra) # 80001d14 <myproc>
        return result;
    800020ee:	4901                	li	s2,0
    if (count == 0)
    800020f0:	0c0b8563          	beqz	s7,800021ba <ps+0xf0>
    void *result = (void *)myproc()->sz;
    800020f4:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    800020f8:	003b951b          	slliw	a0,s7,0x3
    800020fc:	0175053b          	addw	a0,a0,s7
    80002100:	0025151b          	slliw	a0,a0,0x2
    80002104:	00000097          	auipc	ra,0x0
    80002108:	f6a080e7          	jalr	-150(ra) # 8000206e <growproc>
    8000210c:	12054f63          	bltz	a0,8000224a <ps+0x180>
    struct user_proc loc_result[count];
    80002110:	003b9a13          	slli	s4,s7,0x3
    80002114:	9a5e                	add	s4,s4,s7
    80002116:	0a0a                	slli	s4,s4,0x2
    80002118:	00fa0793          	addi	a5,s4,15
    8000211c:	8391                	srli	a5,a5,0x4
    8000211e:	0792                	slli	a5,a5,0x4
    80002120:	40f10133          	sub	sp,sp,a5
    80002124:	8a8a                	mv	s5,sp
    struct proc *p = proc + start;
    80002126:	16800793          	li	a5,360
    8000212a:	02f484b3          	mul	s1,s1,a5
    8000212e:	0002f797          	auipc	a5,0x2f
    80002132:	00278793          	addi	a5,a5,2 # 80031130 <proc>
    80002136:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80002138:	00035797          	auipc	a5,0x35
    8000213c:	9f878793          	addi	a5,a5,-1544 # 80036b30 <tickslock>
        return result;
    80002140:	4901                	li	s2,0
    if (p >= &proc[NPROC])
    80002142:	06f4fc63          	bgeu	s1,a5,800021ba <ps+0xf0>
    acquire(&wait_lock);
    80002146:	0002f517          	auipc	a0,0x2f
    8000214a:	fd250513          	addi	a0,a0,-46 # 80031118 <wait_lock>
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	c14080e7          	jalr	-1004(ra) # 80000d62 <acquire>
        if (localCount == count)
    80002156:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    8000215a:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    8000215c:	00035c17          	auipc	s8,0x35
    80002160:	9d4c0c13          	addi	s8,s8,-1580 # 80036b30 <tickslock>
    80002164:	a851                	j	800021f8 <ps+0x12e>
            loc_result[localCount].state = UNUSED;
    80002166:	00399793          	slli	a5,s3,0x3
    8000216a:	97ce                	add	a5,a5,s3
    8000216c:	078a                	slli	a5,a5,0x2
    8000216e:	97d6                	add	a5,a5,s5
    80002170:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	ca0080e7          	jalr	-864(ra) # 80000e16 <release>
    release(&wait_lock);
    8000217e:	0002f517          	auipc	a0,0x2f
    80002182:	f9a50513          	addi	a0,a0,-102 # 80031118 <wait_lock>
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	c90080e7          	jalr	-880(ra) # 80000e16 <release>
    if (localCount < count)
    8000218e:	0179f963          	bgeu	s3,s7,800021a0 <ps+0xd6>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80002192:	00399793          	slli	a5,s3,0x3
    80002196:	97ce                	add	a5,a5,s3
    80002198:	078a                	slli	a5,a5,0x2
    8000219a:	97d6                	add	a5,a5,s5
    8000219c:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800021a0:	895a                	mv	s2,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	b72080e7          	jalr	-1166(ra) # 80001d14 <myproc>
    800021aa:	86d2                	mv	a3,s4
    800021ac:	8656                	mv	a2,s5
    800021ae:	85da                	mv	a1,s6
    800021b0:	6928                	ld	a0,80(a0)
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	724080e7          	jalr	1828(ra) # 800018d6 <copyout>
}
    800021ba:	854a                	mv	a0,s2
    800021bc:	fb040113          	addi	sp,s0,-80
    800021c0:	60a6                	ld	ra,72(sp)
    800021c2:	6406                	ld	s0,64(sp)
    800021c4:	74e2                	ld	s1,56(sp)
    800021c6:	7942                	ld	s2,48(sp)
    800021c8:	79a2                	ld	s3,40(sp)
    800021ca:	7a02                	ld	s4,32(sp)
    800021cc:	6ae2                	ld	s5,24(sp)
    800021ce:	6b42                	ld	s6,16(sp)
    800021d0:	6ba2                	ld	s7,8(sp)
    800021d2:	6c02                	ld	s8,0(sp)
    800021d4:	6161                	addi	sp,sp,80
    800021d6:	8082                	ret
        release(&p->lock);
    800021d8:	8526                	mv	a0,s1
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	c3c080e7          	jalr	-964(ra) # 80000e16 <release>
        localCount++;
    800021e2:	2985                	addiw	s3,s3,1
    800021e4:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    800021e8:	16848493          	addi	s1,s1,360
    800021ec:	f984f9e3          	bgeu	s1,s8,8000217e <ps+0xb4>
        if (localCount == count)
    800021f0:	02490913          	addi	s2,s2,36
    800021f4:	053b8d63          	beq	s7,s3,8000224e <ps+0x184>
        acquire(&p->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	b68080e7          	jalr	-1176(ra) # 80000d62 <acquire>
        if (p->state == UNUSED)
    80002202:	4c9c                	lw	a5,24(s1)
    80002204:	d3ad                	beqz	a5,80002166 <ps+0x9c>
        loc_result[localCount].state = p->state;
    80002206:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000220a:	549c                	lw	a5,40(s1)
    8000220c:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002210:	54dc                	lw	a5,44(s1)
    80002212:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002216:	589c                	lw	a5,48(s1)
    80002218:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    8000221c:	4641                	li	a2,16
    8000221e:	85ca                	mv	a1,s2
    80002220:	15848513          	addi	a0,s1,344
    80002224:	00000097          	auipc	ra,0x0
    80002228:	a96080e7          	jalr	-1386(ra) # 80001cba <copy_array>
        if (p->parent != 0) // init
    8000222c:	7c88                	ld	a0,56(s1)
    8000222e:	d54d                	beqz	a0,800021d8 <ps+0x10e>
            acquire(&p->parent->lock);
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	b32080e7          	jalr	-1230(ra) # 80000d62 <acquire>
            loc_result[localCount].parent_id = p->parent->pid;
    80002238:	7c88                	ld	a0,56(s1)
    8000223a:	591c                	lw	a5,48(a0)
    8000223c:	fef92e23          	sw	a5,-4(s2)
            release(&p->parent->lock);
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	bd6080e7          	jalr	-1066(ra) # 80000e16 <release>
    80002248:	bf41                	j	800021d8 <ps+0x10e>
        return result;
    8000224a:	4901                	li	s2,0
    8000224c:	b7bd                	j	800021ba <ps+0xf0>
    release(&wait_lock);
    8000224e:	0002f517          	auipc	a0,0x2f
    80002252:	eca50513          	addi	a0,a0,-310 # 80031118 <wait_lock>
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	bc0080e7          	jalr	-1088(ra) # 80000e16 <release>
    if (localCount < count)
    8000225e:	b789                	j	800021a0 <ps+0xd6>

0000000080002260 <fork>:
{
    80002260:	7139                	addi	sp,sp,-64
    80002262:	fc06                	sd	ra,56(sp)
    80002264:	f822                	sd	s0,48(sp)
    80002266:	f426                	sd	s1,40(sp)
    80002268:	f04a                	sd	s2,32(sp)
    8000226a:	ec4e                	sd	s3,24(sp)
    8000226c:	e852                	sd	s4,16(sp)
    8000226e:	e456                	sd	s5,8(sp)
    80002270:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002272:	00000097          	auipc	ra,0x0
    80002276:	aa2080e7          	jalr	-1374(ra) # 80001d14 <myproc>
    8000227a:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	ca2080e7          	jalr	-862(ra) # 80001f1e <allocproc>
    80002284:	10050c63          	beqz	a0,8000239c <fork+0x13c>
    80002288:	8a2a                	mv	s4,a0
    if (uvmcow(p->pagetable, np->pagetable, p->sz) < 0) // Task, change from uvmcopy
    8000228a:	048ab603          	ld	a2,72(s5)
    8000228e:	692c                	ld	a1,80(a0)
    80002290:	050ab503          	ld	a0,80(s5)
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	532080e7          	jalr	1330(ra) # 800017c6 <uvmcow>
    8000229c:	04054863          	bltz	a0,800022ec <fork+0x8c>
    np->sz = p->sz;
    800022a0:	048ab783          	ld	a5,72(s5)
    800022a4:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800022a8:	058ab683          	ld	a3,88(s5)
    800022ac:	87b6                	mv	a5,a3
    800022ae:	058a3703          	ld	a4,88(s4)
    800022b2:	12068693          	addi	a3,a3,288
    800022b6:	0007b803          	ld	a6,0(a5)
    800022ba:	6788                	ld	a0,8(a5)
    800022bc:	6b8c                	ld	a1,16(a5)
    800022be:	6f90                	ld	a2,24(a5)
    800022c0:	01073023          	sd	a6,0(a4)
    800022c4:	e708                	sd	a0,8(a4)
    800022c6:	eb0c                	sd	a1,16(a4)
    800022c8:	ef10                	sd	a2,24(a4)
    800022ca:	02078793          	addi	a5,a5,32
    800022ce:	02070713          	addi	a4,a4,32
    800022d2:	fed792e3          	bne	a5,a3,800022b6 <fork+0x56>
    np->trapframe->a0 = 0;
    800022d6:	058a3783          	ld	a5,88(s4)
    800022da:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800022de:	0d0a8493          	addi	s1,s5,208
    800022e2:	0d0a0913          	addi	s2,s4,208
    800022e6:	150a8993          	addi	s3,s5,336
    800022ea:	a00d                	j	8000230c <fork+0xac>
        freeproc(np);
    800022ec:	8552                	mv	a0,s4
    800022ee:	00000097          	auipc	ra,0x0
    800022f2:	bd8080e7          	jalr	-1064(ra) # 80001ec6 <freeproc>
        release(&np->lock);
    800022f6:	8552                	mv	a0,s4
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	b1e080e7          	jalr	-1250(ra) # 80000e16 <release>
        return -1;
    80002300:	597d                	li	s2,-1
    80002302:	a059                	j	80002388 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002304:	04a1                	addi	s1,s1,8
    80002306:	0921                	addi	s2,s2,8
    80002308:	01348b63          	beq	s1,s3,8000231e <fork+0xbe>
        if (p->ofile[i])
    8000230c:	6088                	ld	a0,0(s1)
    8000230e:	d97d                	beqz	a0,80002304 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002310:	00003097          	auipc	ra,0x3
    80002314:	906080e7          	jalr	-1786(ra) # 80004c16 <filedup>
    80002318:	00a93023          	sd	a0,0(s2)
    8000231c:	b7e5                	j	80002304 <fork+0xa4>
    np->cwd = idup(p->cwd);
    8000231e:	150ab503          	ld	a0,336(s5)
    80002322:	00002097          	auipc	ra,0x2
    80002326:	a74080e7          	jalr	-1420(ra) # 80003d96 <idup>
    8000232a:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000232e:	4641                	li	a2,16
    80002330:	158a8593          	addi	a1,s5,344
    80002334:	158a0513          	addi	a0,s4,344
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	c70080e7          	jalr	-912(ra) # 80000fa8 <safestrcpy>
    pid = np->pid;
    80002340:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002344:	8552                	mv	a0,s4
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	ad0080e7          	jalr	-1328(ra) # 80000e16 <release>
    acquire(&wait_lock);
    8000234e:	0002f497          	auipc	s1,0x2f
    80002352:	dca48493          	addi	s1,s1,-566 # 80031118 <wait_lock>
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	a0a080e7          	jalr	-1526(ra) # 80000d62 <acquire>
    np->parent = p;
    80002360:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	ab0080e7          	jalr	-1360(ra) # 80000e16 <release>
    acquire(&np->lock);
    8000236e:	8552                	mv	a0,s4
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	9f2080e7          	jalr	-1550(ra) # 80000d62 <acquire>
    np->state = RUNNABLE;
    80002378:	478d                	li	a5,3
    8000237a:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    8000237e:	8552                	mv	a0,s4
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	a96080e7          	jalr	-1386(ra) # 80000e16 <release>
}
    80002388:	854a                	mv	a0,s2
    8000238a:	70e2                	ld	ra,56(sp)
    8000238c:	7442                	ld	s0,48(sp)
    8000238e:	74a2                	ld	s1,40(sp)
    80002390:	7902                	ld	s2,32(sp)
    80002392:	69e2                	ld	s3,24(sp)
    80002394:	6a42                	ld	s4,16(sp)
    80002396:	6aa2                	ld	s5,8(sp)
    80002398:	6121                	addi	sp,sp,64
    8000239a:	8082                	ret
        return -1;
    8000239c:	597d                	li	s2,-1
    8000239e:	b7ed                	j	80002388 <fork+0x128>

00000000800023a0 <scheduler>:
{
    800023a0:	1101                	addi	sp,sp,-32
    800023a2:	ec06                	sd	ra,24(sp)
    800023a4:	e822                	sd	s0,16(sp)
    800023a6:	e426                	sd	s1,8(sp)
    800023a8:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800023aa:	00006497          	auipc	s1,0x6
    800023ae:	60e48493          	addi	s1,s1,1550 # 800089b8 <sched_pointer>
    800023b2:	609c                	ld	a5,0(s1)
    800023b4:	9782                	jalr	a5
    while (1)
    800023b6:	bff5                	j	800023b2 <scheduler+0x12>

00000000800023b8 <sched>:
{
    800023b8:	7179                	addi	sp,sp,-48
    800023ba:	f406                	sd	ra,40(sp)
    800023bc:	f022                	sd	s0,32(sp)
    800023be:	ec26                	sd	s1,24(sp)
    800023c0:	e84a                	sd	s2,16(sp)
    800023c2:	e44e                	sd	s3,8(sp)
    800023c4:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800023c6:	00000097          	auipc	ra,0x0
    800023ca:	94e080e7          	jalr	-1714(ra) # 80001d14 <myproc>
    800023ce:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	918080e7          	jalr	-1768(ra) # 80000ce8 <holding>
    800023d8:	c53d                	beqz	a0,80002446 <sched+0x8e>
    800023da:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800023dc:	2781                	sext.w	a5,a5
    800023de:	079e                	slli	a5,a5,0x7
    800023e0:	0002f717          	auipc	a4,0x2f
    800023e4:	92070713          	addi	a4,a4,-1760 # 80030d00 <cpus>
    800023e8:	97ba                	add	a5,a5,a4
    800023ea:	5fb8                	lw	a4,120(a5)
    800023ec:	4785                	li	a5,1
    800023ee:	06f71463          	bne	a4,a5,80002456 <sched+0x9e>
    if (p->state == RUNNING)
    800023f2:	4c98                	lw	a4,24(s1)
    800023f4:	4791                	li	a5,4
    800023f6:	06f70863          	beq	a4,a5,80002466 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023fa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023fe:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002400:	ebbd                	bnez	a5,80002476 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002402:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002404:	0002f917          	auipc	s2,0x2f
    80002408:	8fc90913          	addi	s2,s2,-1796 # 80030d00 <cpus>
    8000240c:	2781                	sext.w	a5,a5
    8000240e:	079e                	slli	a5,a5,0x7
    80002410:	97ca                	add	a5,a5,s2
    80002412:	07c7a983          	lw	s3,124(a5)
    80002416:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002418:	2581                	sext.w	a1,a1
    8000241a:	059e                	slli	a1,a1,0x7
    8000241c:	05a1                	addi	a1,a1,8
    8000241e:	95ca                	add	a1,a1,s2
    80002420:	06048513          	addi	a0,s1,96
    80002424:	00000097          	auipc	ra,0x0
    80002428:	6e4080e7          	jalr	1764(ra) # 80002b08 <swtch>
    8000242c:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000242e:	2781                	sext.w	a5,a5
    80002430:	079e                	slli	a5,a5,0x7
    80002432:	993e                	add	s2,s2,a5
    80002434:	07392e23          	sw	s3,124(s2)
}
    80002438:	70a2                	ld	ra,40(sp)
    8000243a:	7402                	ld	s0,32(sp)
    8000243c:	64e2                	ld	s1,24(sp)
    8000243e:	6942                	ld	s2,16(sp)
    80002440:	69a2                	ld	s3,8(sp)
    80002442:	6145                	addi	sp,sp,48
    80002444:	8082                	ret
        panic("sched p->lock");
    80002446:	00006517          	auipc	a0,0x6
    8000244a:	e1250513          	addi	a0,a0,-494 # 80008258 <digits+0x208>
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	0f2080e7          	jalr	242(ra) # 80000540 <panic>
        panic("sched locks");
    80002456:	00006517          	auipc	a0,0x6
    8000245a:	e1250513          	addi	a0,a0,-494 # 80008268 <digits+0x218>
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	0e2080e7          	jalr	226(ra) # 80000540 <panic>
        panic("sched running");
    80002466:	00006517          	auipc	a0,0x6
    8000246a:	e1250513          	addi	a0,a0,-494 # 80008278 <digits+0x228>
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	0d2080e7          	jalr	210(ra) # 80000540 <panic>
        panic("sched interruptible");
    80002476:	00006517          	auipc	a0,0x6
    8000247a:	e1250513          	addi	a0,a0,-494 # 80008288 <digits+0x238>
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	0c2080e7          	jalr	194(ra) # 80000540 <panic>

0000000080002486 <yield>:
{
    80002486:	1101                	addi	sp,sp,-32
    80002488:	ec06                	sd	ra,24(sp)
    8000248a:	e822                	sd	s0,16(sp)
    8000248c:	e426                	sd	s1,8(sp)
    8000248e:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002490:	00000097          	auipc	ra,0x0
    80002494:	884080e7          	jalr	-1916(ra) # 80001d14 <myproc>
    80002498:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	8c8080e7          	jalr	-1848(ra) # 80000d62 <acquire>
    p->state = RUNNABLE;
    800024a2:	478d                	li	a5,3
    800024a4:	cc9c                	sw	a5,24(s1)
    sched();
    800024a6:	00000097          	auipc	ra,0x0
    800024aa:	f12080e7          	jalr	-238(ra) # 800023b8 <sched>
    release(&p->lock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	966080e7          	jalr	-1690(ra) # 80000e16 <release>
}
    800024b8:	60e2                	ld	ra,24(sp)
    800024ba:	6442                	ld	s0,16(sp)
    800024bc:	64a2                	ld	s1,8(sp)
    800024be:	6105                	addi	sp,sp,32
    800024c0:	8082                	ret

00000000800024c2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800024c2:	7179                	addi	sp,sp,-48
    800024c4:	f406                	sd	ra,40(sp)
    800024c6:	f022                	sd	s0,32(sp)
    800024c8:	ec26                	sd	s1,24(sp)
    800024ca:	e84a                	sd	s2,16(sp)
    800024cc:	e44e                	sd	s3,8(sp)
    800024ce:	1800                	addi	s0,sp,48
    800024d0:	89aa                	mv	s3,a0
    800024d2:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800024d4:	00000097          	auipc	ra,0x0
    800024d8:	840080e7          	jalr	-1984(ra) # 80001d14 <myproc>
    800024dc:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	884080e7          	jalr	-1916(ra) # 80000d62 <acquire>
    release(lk);
    800024e6:	854a                	mv	a0,s2
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	92e080e7          	jalr	-1746(ra) # 80000e16 <release>

    // Go to sleep.
    p->chan = chan;
    800024f0:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800024f4:	4789                	li	a5,2
    800024f6:	cc9c                	sw	a5,24(s1)

    sched();
    800024f8:	00000097          	auipc	ra,0x0
    800024fc:	ec0080e7          	jalr	-320(ra) # 800023b8 <sched>

    // Tidy up.
    p->chan = 0;
    80002500:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	910080e7          	jalr	-1776(ra) # 80000e16 <release>
    acquire(lk);
    8000250e:	854a                	mv	a0,s2
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	852080e7          	jalr	-1966(ra) # 80000d62 <acquire>
}
    80002518:	70a2                	ld	ra,40(sp)
    8000251a:	7402                	ld	s0,32(sp)
    8000251c:	64e2                	ld	s1,24(sp)
    8000251e:	6942                	ld	s2,16(sp)
    80002520:	69a2                	ld	s3,8(sp)
    80002522:	6145                	addi	sp,sp,48
    80002524:	8082                	ret

0000000080002526 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002526:	7139                	addi	sp,sp,-64
    80002528:	fc06                	sd	ra,56(sp)
    8000252a:	f822                	sd	s0,48(sp)
    8000252c:	f426                	sd	s1,40(sp)
    8000252e:	f04a                	sd	s2,32(sp)
    80002530:	ec4e                	sd	s3,24(sp)
    80002532:	e852                	sd	s4,16(sp)
    80002534:	e456                	sd	s5,8(sp)
    80002536:	0080                	addi	s0,sp,64
    80002538:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000253a:	0002f497          	auipc	s1,0x2f
    8000253e:	bf648493          	addi	s1,s1,-1034 # 80031130 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002542:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002544:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002546:	00034917          	auipc	s2,0x34
    8000254a:	5ea90913          	addi	s2,s2,1514 # 80036b30 <tickslock>
    8000254e:	a811                	j	80002562 <wakeup+0x3c>
            }
            release(&p->lock);
    80002550:	8526                	mv	a0,s1
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	8c4080e7          	jalr	-1852(ra) # 80000e16 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000255a:	16848493          	addi	s1,s1,360
    8000255e:	03248663          	beq	s1,s2,8000258a <wakeup+0x64>
        if (p != myproc())
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	7b2080e7          	jalr	1970(ra) # 80001d14 <myproc>
    8000256a:	fea488e3          	beq	s1,a0,8000255a <wakeup+0x34>
            acquire(&p->lock);
    8000256e:	8526                	mv	a0,s1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	7f2080e7          	jalr	2034(ra) # 80000d62 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002578:	4c9c                	lw	a5,24(s1)
    8000257a:	fd379be3          	bne	a5,s3,80002550 <wakeup+0x2a>
    8000257e:	709c                	ld	a5,32(s1)
    80002580:	fd4798e3          	bne	a5,s4,80002550 <wakeup+0x2a>
                p->state = RUNNABLE;
    80002584:	0154ac23          	sw	s5,24(s1)
    80002588:	b7e1                	j	80002550 <wakeup+0x2a>
        }
    }
}
    8000258a:	70e2                	ld	ra,56(sp)
    8000258c:	7442                	ld	s0,48(sp)
    8000258e:	74a2                	ld	s1,40(sp)
    80002590:	7902                	ld	s2,32(sp)
    80002592:	69e2                	ld	s3,24(sp)
    80002594:	6a42                	ld	s4,16(sp)
    80002596:	6aa2                	ld	s5,8(sp)
    80002598:	6121                	addi	sp,sp,64
    8000259a:	8082                	ret

000000008000259c <reparent>:
{
    8000259c:	7179                	addi	sp,sp,-48
    8000259e:	f406                	sd	ra,40(sp)
    800025a0:	f022                	sd	s0,32(sp)
    800025a2:	ec26                	sd	s1,24(sp)
    800025a4:	e84a                	sd	s2,16(sp)
    800025a6:	e44e                	sd	s3,8(sp)
    800025a8:	e052                	sd	s4,0(sp)
    800025aa:	1800                	addi	s0,sp,48
    800025ac:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025ae:	0002f497          	auipc	s1,0x2f
    800025b2:	b8248493          	addi	s1,s1,-1150 # 80031130 <proc>
            pp->parent = initproc;
    800025b6:	00006a17          	auipc	s4,0x6
    800025ba:	4d2a0a13          	addi	s4,s4,1234 # 80008a88 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025be:	00034997          	auipc	s3,0x34
    800025c2:	57298993          	addi	s3,s3,1394 # 80036b30 <tickslock>
    800025c6:	a029                	j	800025d0 <reparent+0x34>
    800025c8:	16848493          	addi	s1,s1,360
    800025cc:	01348d63          	beq	s1,s3,800025e6 <reparent+0x4a>
        if (pp->parent == p)
    800025d0:	7c9c                	ld	a5,56(s1)
    800025d2:	ff279be3          	bne	a5,s2,800025c8 <reparent+0x2c>
            pp->parent = initproc;
    800025d6:	000a3503          	ld	a0,0(s4)
    800025da:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800025dc:	00000097          	auipc	ra,0x0
    800025e0:	f4a080e7          	jalr	-182(ra) # 80002526 <wakeup>
    800025e4:	b7d5                	j	800025c8 <reparent+0x2c>
}
    800025e6:	70a2                	ld	ra,40(sp)
    800025e8:	7402                	ld	s0,32(sp)
    800025ea:	64e2                	ld	s1,24(sp)
    800025ec:	6942                	ld	s2,16(sp)
    800025ee:	69a2                	ld	s3,8(sp)
    800025f0:	6a02                	ld	s4,0(sp)
    800025f2:	6145                	addi	sp,sp,48
    800025f4:	8082                	ret

00000000800025f6 <exit>:
{
    800025f6:	7179                	addi	sp,sp,-48
    800025f8:	f406                	sd	ra,40(sp)
    800025fa:	f022                	sd	s0,32(sp)
    800025fc:	ec26                	sd	s1,24(sp)
    800025fe:	e84a                	sd	s2,16(sp)
    80002600:	e44e                	sd	s3,8(sp)
    80002602:	e052                	sd	s4,0(sp)
    80002604:	1800                	addi	s0,sp,48
    80002606:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	70c080e7          	jalr	1804(ra) # 80001d14 <myproc>
    80002610:	89aa                	mv	s3,a0
    if (p == initproc)
    80002612:	00006797          	auipc	a5,0x6
    80002616:	4767b783          	ld	a5,1142(a5) # 80008a88 <initproc>
    8000261a:	0d050493          	addi	s1,a0,208
    8000261e:	15050913          	addi	s2,a0,336
    80002622:	02a79363          	bne	a5,a0,80002648 <exit+0x52>
        panic("init exiting");
    80002626:	00006517          	auipc	a0,0x6
    8000262a:	c7a50513          	addi	a0,a0,-902 # 800082a0 <digits+0x250>
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	f12080e7          	jalr	-238(ra) # 80000540 <panic>
            fileclose(f);
    80002636:	00002097          	auipc	ra,0x2
    8000263a:	632080e7          	jalr	1586(ra) # 80004c68 <fileclose>
            p->ofile[fd] = 0;
    8000263e:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002642:	04a1                	addi	s1,s1,8
    80002644:	01248563          	beq	s1,s2,8000264e <exit+0x58>
        if (p->ofile[fd])
    80002648:	6088                	ld	a0,0(s1)
    8000264a:	f575                	bnez	a0,80002636 <exit+0x40>
    8000264c:	bfdd                	j	80002642 <exit+0x4c>
    begin_op();
    8000264e:	00002097          	auipc	ra,0x2
    80002652:	152080e7          	jalr	338(ra) # 800047a0 <begin_op>
    iput(p->cwd);
    80002656:	1509b503          	ld	a0,336(s3)
    8000265a:	00002097          	auipc	ra,0x2
    8000265e:	934080e7          	jalr	-1740(ra) # 80003f8e <iput>
    end_op();
    80002662:	00002097          	auipc	ra,0x2
    80002666:	1bc080e7          	jalr	444(ra) # 8000481e <end_op>
    p->cwd = 0;
    8000266a:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    8000266e:	0002f497          	auipc	s1,0x2f
    80002672:	aaa48493          	addi	s1,s1,-1366 # 80031118 <wait_lock>
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	6ea080e7          	jalr	1770(ra) # 80000d62 <acquire>
    reparent(p);
    80002680:	854e                	mv	a0,s3
    80002682:	00000097          	auipc	ra,0x0
    80002686:	f1a080e7          	jalr	-230(ra) # 8000259c <reparent>
    wakeup(p->parent);
    8000268a:	0389b503          	ld	a0,56(s3)
    8000268e:	00000097          	auipc	ra,0x0
    80002692:	e98080e7          	jalr	-360(ra) # 80002526 <wakeup>
    acquire(&p->lock);
    80002696:	854e                	mv	a0,s3
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	6ca080e7          	jalr	1738(ra) # 80000d62 <acquire>
    p->xstate = status;
    800026a0:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800026a4:	4795                	li	a5,5
    800026a6:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	76a080e7          	jalr	1898(ra) # 80000e16 <release>
    sched();
    800026b4:	00000097          	auipc	ra,0x0
    800026b8:	d04080e7          	jalr	-764(ra) # 800023b8 <sched>
    panic("zombie exit");
    800026bc:	00006517          	auipc	a0,0x6
    800026c0:	bf450513          	addi	a0,a0,-1036 # 800082b0 <digits+0x260>
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	e7c080e7          	jalr	-388(ra) # 80000540 <panic>

00000000800026cc <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026cc:	7179                	addi	sp,sp,-48
    800026ce:	f406                	sd	ra,40(sp)
    800026d0:	f022                	sd	s0,32(sp)
    800026d2:	ec26                	sd	s1,24(sp)
    800026d4:	e84a                	sd	s2,16(sp)
    800026d6:	e44e                	sd	s3,8(sp)
    800026d8:	1800                	addi	s0,sp,48
    800026da:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800026dc:	0002f497          	auipc	s1,0x2f
    800026e0:	a5448493          	addi	s1,s1,-1452 # 80031130 <proc>
    800026e4:	00034997          	auipc	s3,0x34
    800026e8:	44c98993          	addi	s3,s3,1100 # 80036b30 <tickslock>
    {
        acquire(&p->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	674080e7          	jalr	1652(ra) # 80000d62 <acquire>
        if (p->pid == pid)
    800026f6:	589c                	lw	a5,48(s1)
    800026f8:	01278d63          	beq	a5,s2,80002712 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	718080e7          	jalr	1816(ra) # 80000e16 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002706:	16848493          	addi	s1,s1,360
    8000270a:	ff3491e3          	bne	s1,s3,800026ec <kill+0x20>
    }
    return -1;
    8000270e:	557d                	li	a0,-1
    80002710:	a829                	j	8000272a <kill+0x5e>
            p->killed = 1;
    80002712:	4785                	li	a5,1
    80002714:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002716:	4c98                	lw	a4,24(s1)
    80002718:	4789                	li	a5,2
    8000271a:	00f70f63          	beq	a4,a5,80002738 <kill+0x6c>
            release(&p->lock);
    8000271e:	8526                	mv	a0,s1
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	6f6080e7          	jalr	1782(ra) # 80000e16 <release>
            return 0;
    80002728:	4501                	li	a0,0
}
    8000272a:	70a2                	ld	ra,40(sp)
    8000272c:	7402                	ld	s0,32(sp)
    8000272e:	64e2                	ld	s1,24(sp)
    80002730:	6942                	ld	s2,16(sp)
    80002732:	69a2                	ld	s3,8(sp)
    80002734:	6145                	addi	sp,sp,48
    80002736:	8082                	ret
                p->state = RUNNABLE;
    80002738:	478d                	li	a5,3
    8000273a:	cc9c                	sw	a5,24(s1)
    8000273c:	b7cd                	j	8000271e <kill+0x52>

000000008000273e <setkilled>:

void setkilled(struct proc *p)
{
    8000273e:	1101                	addi	sp,sp,-32
    80002740:	ec06                	sd	ra,24(sp)
    80002742:	e822                	sd	s0,16(sp)
    80002744:	e426                	sd	s1,8(sp)
    80002746:	1000                	addi	s0,sp,32
    80002748:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	618080e7          	jalr	1560(ra) # 80000d62 <acquire>
    p->killed = 1;
    80002752:	4785                	li	a5,1
    80002754:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002756:	8526                	mv	a0,s1
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	6be080e7          	jalr	1726(ra) # 80000e16 <release>
}
    80002760:	60e2                	ld	ra,24(sp)
    80002762:	6442                	ld	s0,16(sp)
    80002764:	64a2                	ld	s1,8(sp)
    80002766:	6105                	addi	sp,sp,32
    80002768:	8082                	ret

000000008000276a <killed>:

int killed(struct proc *p)
{
    8000276a:	1101                	addi	sp,sp,-32
    8000276c:	ec06                	sd	ra,24(sp)
    8000276e:	e822                	sd	s0,16(sp)
    80002770:	e426                	sd	s1,8(sp)
    80002772:	e04a                	sd	s2,0(sp)
    80002774:	1000                	addi	s0,sp,32
    80002776:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	5ea080e7          	jalr	1514(ra) # 80000d62 <acquire>
    k = p->killed;
    80002780:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	690080e7          	jalr	1680(ra) # 80000e16 <release>
    return k;
}
    8000278e:	854a                	mv	a0,s2
    80002790:	60e2                	ld	ra,24(sp)
    80002792:	6442                	ld	s0,16(sp)
    80002794:	64a2                	ld	s1,8(sp)
    80002796:	6902                	ld	s2,0(sp)
    80002798:	6105                	addi	sp,sp,32
    8000279a:	8082                	ret

000000008000279c <wait>:
{
    8000279c:	715d                	addi	sp,sp,-80
    8000279e:	e486                	sd	ra,72(sp)
    800027a0:	e0a2                	sd	s0,64(sp)
    800027a2:	fc26                	sd	s1,56(sp)
    800027a4:	f84a                	sd	s2,48(sp)
    800027a6:	f44e                	sd	s3,40(sp)
    800027a8:	f052                	sd	s4,32(sp)
    800027aa:	ec56                	sd	s5,24(sp)
    800027ac:	e85a                	sd	s6,16(sp)
    800027ae:	e45e                	sd	s7,8(sp)
    800027b0:	e062                	sd	s8,0(sp)
    800027b2:	0880                	addi	s0,sp,80
    800027b4:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800027b6:	fffff097          	auipc	ra,0xfffff
    800027ba:	55e080e7          	jalr	1374(ra) # 80001d14 <myproc>
    800027be:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800027c0:	0002f517          	auipc	a0,0x2f
    800027c4:	95850513          	addi	a0,a0,-1704 # 80031118 <wait_lock>
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	59a080e7          	jalr	1434(ra) # 80000d62 <acquire>
        havekids = 0;
    800027d0:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800027d2:	4a15                	li	s4,5
                havekids = 1;
    800027d4:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027d6:	00034997          	auipc	s3,0x34
    800027da:	35a98993          	addi	s3,s3,858 # 80036b30 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027de:	0002fc17          	auipc	s8,0x2f
    800027e2:	93ac0c13          	addi	s8,s8,-1734 # 80031118 <wait_lock>
        havekids = 0;
    800027e6:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027e8:	0002f497          	auipc	s1,0x2f
    800027ec:	94848493          	addi	s1,s1,-1720 # 80031130 <proc>
    800027f0:	a0bd                	j	8000285e <wait+0xc2>
                    pid = pp->pid;
    800027f2:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800027f6:	000b0e63          	beqz	s6,80002812 <wait+0x76>
    800027fa:	4691                	li	a3,4
    800027fc:	02c48613          	addi	a2,s1,44
    80002800:	85da                	mv	a1,s6
    80002802:	05093503          	ld	a0,80(s2)
    80002806:	fffff097          	auipc	ra,0xfffff
    8000280a:	0d0080e7          	jalr	208(ra) # 800018d6 <copyout>
    8000280e:	02054563          	bltz	a0,80002838 <wait+0x9c>
                    freeproc(pp);
    80002812:	8526                	mv	a0,s1
    80002814:	fffff097          	auipc	ra,0xfffff
    80002818:	6b2080e7          	jalr	1714(ra) # 80001ec6 <freeproc>
                    release(&pp->lock);
    8000281c:	8526                	mv	a0,s1
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	5f8080e7          	jalr	1528(ra) # 80000e16 <release>
                    release(&wait_lock);
    80002826:	0002f517          	auipc	a0,0x2f
    8000282a:	8f250513          	addi	a0,a0,-1806 # 80031118 <wait_lock>
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	5e8080e7          	jalr	1512(ra) # 80000e16 <release>
                    return pid;
    80002836:	a0b5                	j	800028a2 <wait+0x106>
                        release(&pp->lock);
    80002838:	8526                	mv	a0,s1
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	5dc080e7          	jalr	1500(ra) # 80000e16 <release>
                        release(&wait_lock);
    80002842:	0002f517          	auipc	a0,0x2f
    80002846:	8d650513          	addi	a0,a0,-1834 # 80031118 <wait_lock>
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	5cc080e7          	jalr	1484(ra) # 80000e16 <release>
                        return -1;
    80002852:	59fd                	li	s3,-1
    80002854:	a0b9                	j	800028a2 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002856:	16848493          	addi	s1,s1,360
    8000285a:	03348463          	beq	s1,s3,80002882 <wait+0xe6>
            if (pp->parent == p)
    8000285e:	7c9c                	ld	a5,56(s1)
    80002860:	ff279be3          	bne	a5,s2,80002856 <wait+0xba>
                acquire(&pp->lock);
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	4fc080e7          	jalr	1276(ra) # 80000d62 <acquire>
                if (pp->state == ZOMBIE)
    8000286e:	4c9c                	lw	a5,24(s1)
    80002870:	f94781e3          	beq	a5,s4,800027f2 <wait+0x56>
                release(&pp->lock);
    80002874:	8526                	mv	a0,s1
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	5a0080e7          	jalr	1440(ra) # 80000e16 <release>
                havekids = 1;
    8000287e:	8756                	mv	a4,s5
    80002880:	bfd9                	j	80002856 <wait+0xba>
        if (!havekids || killed(p))
    80002882:	c719                	beqz	a4,80002890 <wait+0xf4>
    80002884:	854a                	mv	a0,s2
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	ee4080e7          	jalr	-284(ra) # 8000276a <killed>
    8000288e:	c51d                	beqz	a0,800028bc <wait+0x120>
            release(&wait_lock);
    80002890:	0002f517          	auipc	a0,0x2f
    80002894:	88850513          	addi	a0,a0,-1912 # 80031118 <wait_lock>
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	57e080e7          	jalr	1406(ra) # 80000e16 <release>
            return -1;
    800028a0:	59fd                	li	s3,-1
}
    800028a2:	854e                	mv	a0,s3
    800028a4:	60a6                	ld	ra,72(sp)
    800028a6:	6406                	ld	s0,64(sp)
    800028a8:	74e2                	ld	s1,56(sp)
    800028aa:	7942                	ld	s2,48(sp)
    800028ac:	79a2                	ld	s3,40(sp)
    800028ae:	7a02                	ld	s4,32(sp)
    800028b0:	6ae2                	ld	s5,24(sp)
    800028b2:	6b42                	ld	s6,16(sp)
    800028b4:	6ba2                	ld	s7,8(sp)
    800028b6:	6c02                	ld	s8,0(sp)
    800028b8:	6161                	addi	sp,sp,80
    800028ba:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    800028bc:	85e2                	mv	a1,s8
    800028be:	854a                	mv	a0,s2
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	c02080e7          	jalr	-1022(ra) # 800024c2 <sleep>
        havekids = 0;
    800028c8:	bf39                	j	800027e6 <wait+0x4a>

00000000800028ca <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800028ca:	7179                	addi	sp,sp,-48
    800028cc:	f406                	sd	ra,40(sp)
    800028ce:	f022                	sd	s0,32(sp)
    800028d0:	ec26                	sd	s1,24(sp)
    800028d2:	e84a                	sd	s2,16(sp)
    800028d4:	e44e                	sd	s3,8(sp)
    800028d6:	e052                	sd	s4,0(sp)
    800028d8:	1800                	addi	s0,sp,48
    800028da:	84aa                	mv	s1,a0
    800028dc:	892e                	mv	s2,a1
    800028de:	89b2                	mv	s3,a2
    800028e0:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028e2:	fffff097          	auipc	ra,0xfffff
    800028e6:	432080e7          	jalr	1074(ra) # 80001d14 <myproc>
    if (user_dst)
    800028ea:	c08d                	beqz	s1,8000290c <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800028ec:	86d2                	mv	a3,s4
    800028ee:	864e                	mv	a2,s3
    800028f0:	85ca                	mv	a1,s2
    800028f2:	6928                	ld	a0,80(a0)
    800028f4:	fffff097          	auipc	ra,0xfffff
    800028f8:	fe2080e7          	jalr	-30(ra) # 800018d6 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    800028fc:	70a2                	ld	ra,40(sp)
    800028fe:	7402                	ld	s0,32(sp)
    80002900:	64e2                	ld	s1,24(sp)
    80002902:	6942                	ld	s2,16(sp)
    80002904:	69a2                	ld	s3,8(sp)
    80002906:	6a02                	ld	s4,0(sp)
    80002908:	6145                	addi	sp,sp,48
    8000290a:	8082                	ret
        memmove((char *)dst, src, len);
    8000290c:	000a061b          	sext.w	a2,s4
    80002910:	85ce                	mv	a1,s3
    80002912:	854a                	mv	a0,s2
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	5a6080e7          	jalr	1446(ra) # 80000eba <memmove>
        return 0;
    8000291c:	8526                	mv	a0,s1
    8000291e:	bff9                	j	800028fc <either_copyout+0x32>

0000000080002920 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002920:	7179                	addi	sp,sp,-48
    80002922:	f406                	sd	ra,40(sp)
    80002924:	f022                	sd	s0,32(sp)
    80002926:	ec26                	sd	s1,24(sp)
    80002928:	e84a                	sd	s2,16(sp)
    8000292a:	e44e                	sd	s3,8(sp)
    8000292c:	e052                	sd	s4,0(sp)
    8000292e:	1800                	addi	s0,sp,48
    80002930:	892a                	mv	s2,a0
    80002932:	84ae                	mv	s1,a1
    80002934:	89b2                	mv	s3,a2
    80002936:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002938:	fffff097          	auipc	ra,0xfffff
    8000293c:	3dc080e7          	jalr	988(ra) # 80001d14 <myproc>
    if (user_src)
    80002940:	c08d                	beqz	s1,80002962 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002942:	86d2                	mv	a3,s4
    80002944:	864e                	mv	a2,s3
    80002946:	85ca                	mv	a1,s2
    80002948:	6928                	ld	a0,80(a0)
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	018080e7          	jalr	24(ra) # 80001962 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002952:	70a2                	ld	ra,40(sp)
    80002954:	7402                	ld	s0,32(sp)
    80002956:	64e2                	ld	s1,24(sp)
    80002958:	6942                	ld	s2,16(sp)
    8000295a:	69a2                	ld	s3,8(sp)
    8000295c:	6a02                	ld	s4,0(sp)
    8000295e:	6145                	addi	sp,sp,48
    80002960:	8082                	ret
        memmove(dst, (char *)src, len);
    80002962:	000a061b          	sext.w	a2,s4
    80002966:	85ce                	mv	a1,s3
    80002968:	854a                	mv	a0,s2
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	550080e7          	jalr	1360(ra) # 80000eba <memmove>
        return 0;
    80002972:	8526                	mv	a0,s1
    80002974:	bff9                	j	80002952 <either_copyin+0x32>

0000000080002976 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002976:	715d                	addi	sp,sp,-80
    80002978:	e486                	sd	ra,72(sp)
    8000297a:	e0a2                	sd	s0,64(sp)
    8000297c:	fc26                	sd	s1,56(sp)
    8000297e:	f84a                	sd	s2,48(sp)
    80002980:	f44e                	sd	s3,40(sp)
    80002982:	f052                	sd	s4,32(sp)
    80002984:	ec56                	sd	s5,24(sp)
    80002986:	e85a                	sd	s6,16(sp)
    80002988:	e45e                	sd	s7,8(sp)
    8000298a:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    8000298c:	00005517          	auipc	a0,0x5
    80002990:	6fc50513          	addi	a0,a0,1788 # 80008088 <digits+0x38>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	c08080e7          	jalr	-1016(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000299c:	0002f497          	auipc	s1,0x2f
    800029a0:	8ec48493          	addi	s1,s1,-1812 # 80031288 <proc+0x158>
    800029a4:	00034917          	auipc	s2,0x34
    800029a8:	2e490913          	addi	s2,s2,740 # 80036c88 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ac:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800029ae:	00006997          	auipc	s3,0x6
    800029b2:	91298993          	addi	s3,s3,-1774 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    800029b6:	00006a97          	auipc	s5,0x6
    800029ba:	912a8a93          	addi	s5,s5,-1774 # 800082c8 <digits+0x278>
        printf("\n");
    800029be:	00005a17          	auipc	s4,0x5
    800029c2:	6caa0a13          	addi	s4,s4,1738 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029c6:	00006b97          	auipc	s7,0x6
    800029ca:	a12b8b93          	addi	s7,s7,-1518 # 800083d8 <states.0>
    800029ce:	a00d                	j	800029f0 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800029d0:	ed86a583          	lw	a1,-296(a3)
    800029d4:	8556                	mv	a0,s5
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	bc6080e7          	jalr	-1082(ra) # 8000059c <printf>
        printf("\n");
    800029de:	8552                	mv	a0,s4
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	bbc080e7          	jalr	-1092(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800029e8:	16848493          	addi	s1,s1,360
    800029ec:	03248263          	beq	s1,s2,80002a10 <procdump+0x9a>
        if (p->state == UNUSED)
    800029f0:	86a6                	mv	a3,s1
    800029f2:	ec04a783          	lw	a5,-320(s1)
    800029f6:	dbed                	beqz	a5,800029e8 <procdump+0x72>
            state = "???";
    800029f8:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029fa:	fcfb6be3          	bltu	s6,a5,800029d0 <procdump+0x5a>
    800029fe:	02079713          	slli	a4,a5,0x20
    80002a02:	01d75793          	srli	a5,a4,0x1d
    80002a06:	97de                	add	a5,a5,s7
    80002a08:	6390                	ld	a2,0(a5)
    80002a0a:	f279                	bnez	a2,800029d0 <procdump+0x5a>
            state = "???";
    80002a0c:	864e                	mv	a2,s3
    80002a0e:	b7c9                	j	800029d0 <procdump+0x5a>
    }
}
    80002a10:	60a6                	ld	ra,72(sp)
    80002a12:	6406                	ld	s0,64(sp)
    80002a14:	74e2                	ld	s1,56(sp)
    80002a16:	7942                	ld	s2,48(sp)
    80002a18:	79a2                	ld	s3,40(sp)
    80002a1a:	7a02                	ld	s4,32(sp)
    80002a1c:	6ae2                	ld	s5,24(sp)
    80002a1e:	6b42                	ld	s6,16(sp)
    80002a20:	6ba2                	ld	s7,8(sp)
    80002a22:	6161                	addi	sp,sp,80
    80002a24:	8082                	ret

0000000080002a26 <schedls>:

void schedls()
{
    80002a26:	1141                	addi	sp,sp,-16
    80002a28:	e406                	sd	ra,8(sp)
    80002a2a:	e022                	sd	s0,0(sp)
    80002a2c:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002a2e:	00006517          	auipc	a0,0x6
    80002a32:	8aa50513          	addi	a0,a0,-1878 # 800082d8 <digits+0x288>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b66080e7          	jalr	-1178(ra) # 8000059c <printf>
    printf("====================================\n");
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	8c250513          	addi	a0,a0,-1854 # 80008300 <digits+0x2b0>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	b56080e7          	jalr	-1194(ra) # 8000059c <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002a4e:	00006717          	auipc	a4,0x6
    80002a52:	fca73703          	ld	a4,-54(a4) # 80008a18 <available_schedulers+0x10>
    80002a56:	00006797          	auipc	a5,0x6
    80002a5a:	f627b783          	ld	a5,-158(a5) # 800089b8 <sched_pointer>
    80002a5e:	04f70663          	beq	a4,a5,80002aaa <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	8ce50513          	addi	a0,a0,-1842 # 80008330 <digits+0x2e0>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b32080e7          	jalr	-1230(ra) # 8000059c <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002a72:	00006617          	auipc	a2,0x6
    80002a76:	fae62603          	lw	a2,-82(a2) # 80008a20 <available_schedulers+0x18>
    80002a7a:	00006597          	auipc	a1,0x6
    80002a7e:	f8e58593          	addi	a1,a1,-114 # 80008a08 <available_schedulers>
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	8b650513          	addi	a0,a0,-1866 # 80008338 <digits+0x2e8>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	b12080e7          	jalr	-1262(ra) # 8000059c <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	8ae50513          	addi	a0,a0,-1874 # 80008340 <digits+0x2f0>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	b02080e7          	jalr	-1278(ra) # 8000059c <printf>
}
    80002aa2:	60a2                	ld	ra,8(sp)
    80002aa4:	6402                	ld	s0,0(sp)
    80002aa6:	0141                	addi	sp,sp,16
    80002aa8:	8082                	ret
            printf("[*]\t");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	87e50513          	addi	a0,a0,-1922 # 80008328 <digits+0x2d8>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	aea080e7          	jalr	-1302(ra) # 8000059c <printf>
    80002aba:	bf65                	j	80002a72 <schedls+0x4c>

0000000080002abc <schedset>:

void schedset(int id)
{
    80002abc:	1141                	addi	sp,sp,-16
    80002abe:	e406                	sd	ra,8(sp)
    80002ac0:	e022                	sd	s0,0(sp)
    80002ac2:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002ac4:	e90d                	bnez	a0,80002af6 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002ac6:	00006797          	auipc	a5,0x6
    80002aca:	f527b783          	ld	a5,-174(a5) # 80008a18 <available_schedulers+0x10>
    80002ace:	00006717          	auipc	a4,0x6
    80002ad2:	eef73523          	sd	a5,-278(a4) # 800089b8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002ad6:	00006597          	auipc	a1,0x6
    80002ada:	f3258593          	addi	a1,a1,-206 # 80008a08 <available_schedulers>
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	8a250513          	addi	a0,a0,-1886 # 80008380 <digits+0x330>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	ab6080e7          	jalr	-1354(ra) # 8000059c <printf>
    80002aee:	60a2                	ld	ra,8(sp)
    80002af0:	6402                	ld	s0,0(sp)
    80002af2:	0141                	addi	sp,sp,16
    80002af4:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002af6:	00006517          	auipc	a0,0x6
    80002afa:	86250513          	addi	a0,a0,-1950 # 80008358 <digits+0x308>
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a9e080e7          	jalr	-1378(ra) # 8000059c <printf>
        return;
    80002b06:	b7e5                	j	80002aee <schedset+0x32>

0000000080002b08 <swtch>:
    80002b08:	00153023          	sd	ra,0(a0)
    80002b0c:	00253423          	sd	sp,8(a0)
    80002b10:	e900                	sd	s0,16(a0)
    80002b12:	ed04                	sd	s1,24(a0)
    80002b14:	03253023          	sd	s2,32(a0)
    80002b18:	03353423          	sd	s3,40(a0)
    80002b1c:	03453823          	sd	s4,48(a0)
    80002b20:	03553c23          	sd	s5,56(a0)
    80002b24:	05653023          	sd	s6,64(a0)
    80002b28:	05753423          	sd	s7,72(a0)
    80002b2c:	05853823          	sd	s8,80(a0)
    80002b30:	05953c23          	sd	s9,88(a0)
    80002b34:	07a53023          	sd	s10,96(a0)
    80002b38:	07b53423          	sd	s11,104(a0)
    80002b3c:	0005b083          	ld	ra,0(a1)
    80002b40:	0085b103          	ld	sp,8(a1)
    80002b44:	6980                	ld	s0,16(a1)
    80002b46:	6d84                	ld	s1,24(a1)
    80002b48:	0205b903          	ld	s2,32(a1)
    80002b4c:	0285b983          	ld	s3,40(a1)
    80002b50:	0305ba03          	ld	s4,48(a1)
    80002b54:	0385ba83          	ld	s5,56(a1)
    80002b58:	0405bb03          	ld	s6,64(a1)
    80002b5c:	0485bb83          	ld	s7,72(a1)
    80002b60:	0505bc03          	ld	s8,80(a1)
    80002b64:	0585bc83          	ld	s9,88(a1)
    80002b68:	0605bd03          	ld	s10,96(a1)
    80002b6c:	0685bd83          	ld	s11,104(a1)
    80002b70:	8082                	ret

0000000080002b72 <trapinit>:

extern int counter[(PHYSTOP-KERNBASE)/PGSIZE];

void
trapinit(void)
{
    80002b72:	1141                	addi	sp,sp,-16
    80002b74:	e406                	sd	ra,8(sp)
    80002b76:	e022                	sd	s0,0(sp)
    80002b78:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b7a:	00006597          	auipc	a1,0x6
    80002b7e:	88e58593          	addi	a1,a1,-1906 # 80008408 <states.0+0x30>
    80002b82:	00034517          	auipc	a0,0x34
    80002b86:	fae50513          	addi	a0,a0,-82 # 80036b30 <tickslock>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	148080e7          	jalr	328(ra) # 80000cd2 <initlock>
}
    80002b92:	60a2                	ld	ra,8(sp)
    80002b94:	6402                	ld	s0,0(sp)
    80002b96:	0141                	addi	sp,sp,16
    80002b98:	8082                	ret

0000000080002b9a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b9a:	1141                	addi	sp,sp,-16
    80002b9c:	e422                	sd	s0,8(sp)
    80002b9e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ba0:	00003797          	auipc	a5,0x3
    80002ba4:	72078793          	addi	a5,a5,1824 # 800062c0 <kernelvec>
    80002ba8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bac:	6422                	ld	s0,8(sp)
    80002bae:	0141                	addi	sp,sp,16
    80002bb0:	8082                	ret

0000000080002bb2 <handle_cow>:

// COW handling function
int handle_cow(uint64 faulting_address) {
    80002bb2:	1141                	addi	sp,sp,-16
    80002bb4:	e422                	sd	s0,8(sp)
    80002bb6:	0800                	addi	s0,sp,16
  // 1. Allocate new page
  // 2. Copy contents from old to new
  // 3. Update page table entry
  // Ensure proper synchronization and error handling
  return 0; 
}
    80002bb8:	4501                	li	a0,0
    80002bba:	6422                	ld	s0,8(sp)
    80002bbc:	0141                	addi	sp,sp,16
    80002bbe:	8082                	ret

0000000080002bc0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bc0:	1141                	addi	sp,sp,-16
    80002bc2:	e406                	sd	ra,8(sp)
    80002bc4:	e022                	sd	s0,0(sp)
    80002bc6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	14c080e7          	jalr	332(ra) # 80001d14 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bd4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bda:	00004697          	auipc	a3,0x4
    80002bde:	42668693          	addi	a3,a3,1062 # 80007000 <_trampoline>
    80002be2:	00004717          	auipc	a4,0x4
    80002be6:	41e70713          	addi	a4,a4,1054 # 80007000 <_trampoline>
    80002bea:	8f15                	sub	a4,a4,a3
    80002bec:	040007b7          	lui	a5,0x4000
    80002bf0:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002bf2:	07b2                	slli	a5,a5,0xc
    80002bf4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bf6:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bfa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bfc:	18002673          	csrr	a2,satp
    80002c00:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c02:	6d30                	ld	a2,88(a0)
    80002c04:	6138                	ld	a4,64(a0)
    80002c06:	6585                	lui	a1,0x1
    80002c08:	972e                	add	a4,a4,a1
    80002c0a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c0c:	6d38                	ld	a4,88(a0)
    80002c0e:	00000617          	auipc	a2,0x0
    80002c12:	13060613          	addi	a2,a2,304 # 80002d3e <usertrap>
    80002c16:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c18:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c1a:	8612                	mv	a2,tp
    80002c1c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c22:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c26:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c2a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c2e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c30:	6f18                	ld	a4,24(a4)
    80002c32:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c36:	6928                	ld	a0,80(a0)
    80002c38:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c3a:	00004717          	auipc	a4,0x4
    80002c3e:	46270713          	addi	a4,a4,1122 # 8000709c <userret>
    80002c42:	8f15                	sub	a4,a4,a3
    80002c44:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c46:	577d                	li	a4,-1
    80002c48:	177e                	slli	a4,a4,0x3f
    80002c4a:	8d59                	or	a0,a0,a4
    80002c4c:	9782                	jalr	a5
}
    80002c4e:	60a2                	ld	ra,8(sp)
    80002c50:	6402                	ld	s0,0(sp)
    80002c52:	0141                	addi	sp,sp,16
    80002c54:	8082                	ret

0000000080002c56 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c60:	00034497          	auipc	s1,0x34
    80002c64:	ed048493          	addi	s1,s1,-304 # 80036b30 <tickslock>
    80002c68:	8526                	mv	a0,s1
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	0f8080e7          	jalr	248(ra) # 80000d62 <acquire>
  ticks++;
    80002c72:	00006517          	auipc	a0,0x6
    80002c76:	e1e50513          	addi	a0,a0,-482 # 80008a90 <ticks>
    80002c7a:	411c                	lw	a5,0(a0)
    80002c7c:	2785                	addiw	a5,a5,1
    80002c7e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	8a6080e7          	jalr	-1882(ra) # 80002526 <wakeup>
  release(&tickslock);
    80002c88:	8526                	mv	a0,s1
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	18c080e7          	jalr	396(ra) # 80000e16 <release>
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6105                	addi	sp,sp,32
    80002c9a:	8082                	ret

0000000080002c9c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c9c:	1101                	addi	sp,sp,-32
    80002c9e:	ec06                	sd	ra,24(sp)
    80002ca0:	e822                	sd	s0,16(sp)
    80002ca2:	e426                	sd	s1,8(sp)
    80002ca4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002caa:	00074d63          	bltz	a4,80002cc4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cae:	57fd                	li	a5,-1
    80002cb0:	17fe                	slli	a5,a5,0x3f
    80002cb2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cb4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cb6:	06f70363          	beq	a4,a5,80002d1c <devintr+0x80>
  }
}
    80002cba:	60e2                	ld	ra,24(sp)
    80002cbc:	6442                	ld	s0,16(sp)
    80002cbe:	64a2                	ld	s1,8(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret
     (scause & 0xff) == 9){
    80002cc4:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002cc8:	46a5                	li	a3,9
    80002cca:	fed792e3          	bne	a5,a3,80002cae <devintr+0x12>
    int irq = plic_claim();
    80002cce:	00003097          	auipc	ra,0x3
    80002cd2:	6fa080e7          	jalr	1786(ra) # 800063c8 <plic_claim>
    80002cd6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cd8:	47a9                	li	a5,10
    80002cda:	02f50763          	beq	a0,a5,80002d08 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cde:	4785                	li	a5,1
    80002ce0:	02f50963          	beq	a0,a5,80002d12 <devintr+0x76>
    return 1;
    80002ce4:	4505                	li	a0,1
    } else if(irq){
    80002ce6:	d8f1                	beqz	s1,80002cba <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ce8:	85a6                	mv	a1,s1
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	72650513          	addi	a0,a0,1830 # 80008410 <states.0+0x38>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	8aa080e7          	jalr	-1878(ra) # 8000059c <printf>
      plic_complete(irq);
    80002cfa:	8526                	mv	a0,s1
    80002cfc:	00003097          	auipc	ra,0x3
    80002d00:	6f0080e7          	jalr	1776(ra) # 800063ec <plic_complete>
    return 1;
    80002d04:	4505                	li	a0,1
    80002d06:	bf55                	j	80002cba <devintr+0x1e>
      uartintr();
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	ca2080e7          	jalr	-862(ra) # 800009aa <uartintr>
    80002d10:	b7ed                	j	80002cfa <devintr+0x5e>
      virtio_disk_intr();
    80002d12:	00004097          	auipc	ra,0x4
    80002d16:	ba2080e7          	jalr	-1118(ra) # 800068b4 <virtio_disk_intr>
    80002d1a:	b7c5                	j	80002cfa <devintr+0x5e>
    if(cpuid() == 0){
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	fcc080e7          	jalr	-52(ra) # 80001ce8 <cpuid>
    80002d24:	c901                	beqz	a0,80002d34 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d26:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d2a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d2c:	14479073          	csrw	sip,a5
    return 2;
    80002d30:	4509                	li	a0,2
    80002d32:	b761                	j	80002cba <devintr+0x1e>
      clockintr();
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	f22080e7          	jalr	-222(ra) # 80002c56 <clockintr>
    80002d3c:	b7ed                	j	80002d26 <devintr+0x8a>

0000000080002d3e <usertrap>:
{
    80002d3e:	7139                	addi	sp,sp,-64
    80002d40:	fc06                	sd	ra,56(sp)
    80002d42:	f822                	sd	s0,48(sp)
    80002d44:	f426                	sd	s1,40(sp)
    80002d46:	f04a                	sd	s2,32(sp)
    80002d48:	ec4e                	sd	s3,24(sp)
    80002d4a:	e852                	sd	s4,16(sp)
    80002d4c:	e456                	sd	s5,8(sp)
    80002d4e:	e05a                	sd	s6,0(sp)
    80002d50:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d52:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d56:	1007f793          	andi	a5,a5,256
    80002d5a:	efb5                	bnez	a5,80002dd6 <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d5c:	00003797          	auipc	a5,0x3
    80002d60:	56478793          	addi	a5,a5,1380 # 800062c0 <kernelvec>
    80002d64:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	fac080e7          	jalr	-84(ra) # 80001d14 <myproc>
    80002d70:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d72:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d74:	14102773          	csrr	a4,sepc
    80002d78:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d7a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d7e:	47a1                	li	a5,8
    80002d80:	06f70363          	beq	a4,a5,80002de6 <usertrap+0xa8>
  } else if((which_dev = devintr()) != 0){
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	f18080e7          	jalr	-232(ra) # 80002c9c <devintr>
    80002d8c:	892a                	mv	s2,a0
    80002d8e:	18051a63          	bnez	a0,80002f22 <usertrap+0x1e4>
    80002d92:	14202773          	csrr	a4,scause
  } else if(r_scause()==0x000000000000000fL){
    80002d96:	47bd                	li	a5,15
    80002d98:	0af70563          	beq	a4,a5,80002e42 <usertrap+0x104>
    80002d9c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002da0:	5890                	lw	a2,48(s1)
    80002da2:	00005517          	auipc	a0,0x5
    80002da6:	6de50513          	addi	a0,a0,1758 # 80008480 <states.0+0xa8>
    80002daa:	ffffd097          	auipc	ra,0xffffd
    80002dae:	7f2080e7          	jalr	2034(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002db2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002db6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dba:	00005517          	auipc	a0,0x5
    80002dbe:	6f650513          	addi	a0,a0,1782 # 800084b0 <states.0+0xd8>
    80002dc2:	ffffd097          	auipc	ra,0xffffd
    80002dc6:	7da080e7          	jalr	2010(ra) # 8000059c <printf>
    setkilled(p);
    80002dca:	8526                	mv	a0,s1
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	972080e7          	jalr	-1678(ra) # 8000273e <setkilled>
    80002dd4:	a825                	j	80002e0c <usertrap+0xce>
    panic("usertrap: not from user mode");
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	65a50513          	addi	a0,a0,1626 # 80008430 <states.0+0x58>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	762080e7          	jalr	1890(ra) # 80000540 <panic>
    if(killed(p))
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	984080e7          	jalr	-1660(ra) # 8000276a <killed>
    80002dee:	e521                	bnez	a0,80002e36 <usertrap+0xf8>
    p->trapframe->epc += 4;
    80002df0:	6cb8                	ld	a4,88(s1)
    80002df2:	6f1c                	ld	a5,24(a4)
    80002df4:	0791                	addi	a5,a5,4
    80002df6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dfc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e00:	10079073          	csrw	sstatus,a5
    syscall();
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	392080e7          	jalr	914(ra) # 80003196 <syscall>
  if(killed(p))
    80002e0c:	8526                	mv	a0,s1
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	95c080e7          	jalr	-1700(ra) # 8000276a <killed>
    80002e16:	10051d63          	bnez	a0,80002f30 <usertrap+0x1f2>
  usertrapret();
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	da6080e7          	jalr	-602(ra) # 80002bc0 <usertrapret>
}
    80002e22:	70e2                	ld	ra,56(sp)
    80002e24:	7442                	ld	s0,48(sp)
    80002e26:	74a2                	ld	s1,40(sp)
    80002e28:	7902                	ld	s2,32(sp)
    80002e2a:	69e2                	ld	s3,24(sp)
    80002e2c:	6a42                	ld	s4,16(sp)
    80002e2e:	6aa2                	ld	s5,8(sp)
    80002e30:	6b02                	ld	s6,0(sp)
    80002e32:	6121                	addi	sp,sp,64
    80002e34:	8082                	ret
      exit(-1);
    80002e36:	557d                	li	a0,-1
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	7be080e7          	jalr	1982(ra) # 800025f6 <exit>
    80002e40:	bf45                	j	80002df0 <usertrap+0xb2>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e42:	14302a73          	csrr	s4,stval
    uint64 base = PGROUNDDOWN(va);
    80002e46:	77fd                	lui	a5,0xfffff
    80002e48:	00fa7a33          	and	s4,s4,a5
    pagetable_t pagetable = p->pagetable;
    80002e4c:	0504bb03          	ld	s6,80(s1)
    pte = walk(pagetable,base,0);
    80002e50:	4601                	li	a2,0
    80002e52:	85d2                	mv	a1,s4
    80002e54:	855a                	mv	a0,s6
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	2ec080e7          	jalr	748(ra) # 80001142 <walk>
    80002e5e:	8aaa                	mv	s5,a0
    uint64 PA = PTE2PA(*pte);
    80002e60:	00053903          	ld	s2,0(a0)
    80002e64:	00a95913          	srli	s2,s2,0xa
    80002e68:	0932                	slli	s2,s2,0xc
    if (PA==0)
    80002e6a:	08090063          	beqz	s2,80002eea <usertrap+0x1ac>
    if ((new_page = newkalloc())==0){
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	dd4080e7          	jalr	-556(ra) # 80000c42 <newkalloc>
    80002e76:	89aa                	mv	s3,a0
    80002e78:	c149                	beqz	a0,80002efa <usertrap+0x1bc>
    flags = PTE_FLAGS(*pte);
    80002e7a:	000aba83          	ld	s5,0(s5)
    80002e7e:	3ffafa93          	andi	s5,s5,1023
    memmove(new_page,(void *)PA, PGSIZE);
    80002e82:	6605                	lui	a2,0x1
    80002e84:	85ca                	mv	a1,s2
    80002e86:	854e                	mv	a0,s3
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	032080e7          	jalr	50(ra) # 80000eba <memmove>
    uvmunmap(pagetable, base, 1, 1);
    80002e90:	4685                	li	a3,1
    80002e92:	4605                	li	a2,1
    80002e94:	85d2                	mv	a1,s4
    80002e96:	855a                	mv	a0,s6
    80002e98:	ffffe097          	auipc	ra,0xffffe
    80002e9c:	558080e7          	jalr	1368(ra) # 800013f0 <uvmunmap>
    if(mappages(pagetable, base, PGSIZE, (uint64)new_page, flags) != 0){
    80002ea0:	004ae713          	ori	a4,s5,4
    80002ea4:	86ce                	mv	a3,s3
    80002ea6:	6605                	lui	a2,0x1
    80002ea8:	85d2                	mv	a1,s4
    80002eaa:	855a                	mv	a0,s6
    80002eac:	ffffe097          	auipc	ra,0xffffe
    80002eb0:	37e080e7          	jalr	894(ra) # 8000122a <mappages>
    80002eb4:	dd21                	beqz	a0,80002e0c <usertrap+0xce>
      if (counter[((uint64)new_page-KERNBASE )/ PGSIZE]==0)
    80002eb6:	800007b7          	lui	a5,0x80000
    80002eba:	97ce                	add	a5,a5,s3
    80002ebc:	83b1                	srli	a5,a5,0xc
    80002ebe:	078a                	slli	a5,a5,0x2
    80002ec0:	0000e717          	auipc	a4,0xe
    80002ec4:	e4070713          	addi	a4,a4,-448 # 80010d00 <counter>
    80002ec8:	97ba                	add	a5,a5,a4
    80002eca:	439c                	lw	a5,0(a5)
    80002ecc:	e7a9                	bnez	a5,80002f16 <usertrap+0x1d8>
        newkfree(new_page);
    80002ece:	854e                	mv	a0,s3
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	d3e080e7          	jalr	-706(ra) # 80000c0e <newkfree>
      printf("SEAGFAULT\n");
    80002ed8:	00005517          	auipc	a0,0x5
    80002edc:	59850513          	addi	a0,a0,1432 # 80008470 <states.0+0x98>
    80002ee0:	ffffd097          	auipc	ra,0xffffd
    80002ee4:	6bc080e7          	jalr	1724(ra) # 8000059c <printf>
    80002ee8:	b715                	j	80002e0c <usertrap+0xce>
      panic("uvmcopy: walkaddr failed\n");
    80002eea:	00005517          	auipc	a0,0x5
    80002eee:	56650513          	addi	a0,a0,1382 # 80008450 <states.0+0x78>
    80002ef2:	ffffd097          	auipc	ra,0xffffd
    80002ef6:	64e080e7          	jalr	1614(ra) # 80000540 <panic>
          printf("SEAGFAULT\n");
    80002efa:	00005517          	auipc	a0,0x5
    80002efe:	57650513          	addi	a0,a0,1398 # 80008470 <states.0+0x98>
    80002f02:	ffffd097          	auipc	ra,0xffffd
    80002f06:	69a080e7          	jalr	1690(ra) # 8000059c <printf>
          setkilled(p);
    80002f0a:	8526                	mv	a0,s1
    80002f0c:	00000097          	auipc	ra,0x0
    80002f10:	832080e7          	jalr	-1998(ra) # 8000273e <setkilled>
    80002f14:	b79d                	j	80002e7a <usertrap+0x13c>
        refdec((void *)PA);
    80002f16:	854a                	mv	a0,s2
    80002f18:	ffffe097          	auipc	ra,0xffffe
    80002f1c:	d94080e7          	jalr	-620(ra) # 80000cac <refdec>
    80002f20:	bf65                	j	80002ed8 <usertrap+0x19a>
  if(killed(p))
    80002f22:	8526                	mv	a0,s1
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	846080e7          	jalr	-1978(ra) # 8000276a <killed>
    80002f2c:	c901                	beqz	a0,80002f3c <usertrap+0x1fe>
    80002f2e:	a011                	j	80002f32 <usertrap+0x1f4>
    80002f30:	4901                	li	s2,0
    exit(-1);
    80002f32:	557d                	li	a0,-1
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	6c2080e7          	jalr	1730(ra) # 800025f6 <exit>
  if(which_dev == 2)
    80002f3c:	4789                	li	a5,2
    80002f3e:	ecf91ee3          	bne	s2,a5,80002e1a <usertrap+0xdc>
    yield();
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	544080e7          	jalr	1348(ra) # 80002486 <yield>
    80002f4a:	bdc1                	j	80002e1a <usertrap+0xdc>

0000000080002f4c <kerneltrap>:
{
    80002f4c:	7179                	addi	sp,sp,-48
    80002f4e:	f406                	sd	ra,40(sp)
    80002f50:	f022                	sd	s0,32(sp)
    80002f52:	ec26                	sd	s1,24(sp)
    80002f54:	e84a                	sd	s2,16(sp)
    80002f56:	e44e                	sd	s3,8(sp)
    80002f58:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f5a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f5e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f62:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f66:	1004f793          	andi	a5,s1,256
    80002f6a:	cb85                	beqz	a5,80002f9a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f70:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f72:	ef85                	bnez	a5,80002faa <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	d28080e7          	jalr	-728(ra) # 80002c9c <devintr>
    80002f7c:	cd1d                	beqz	a0,80002fba <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f7e:	4789                	li	a5,2
    80002f80:	06f50a63          	beq	a0,a5,80002ff4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f84:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f88:	10049073          	csrw	sstatus,s1
}
    80002f8c:	70a2                	ld	ra,40(sp)
    80002f8e:	7402                	ld	s0,32(sp)
    80002f90:	64e2                	ld	s1,24(sp)
    80002f92:	6942                	ld	s2,16(sp)
    80002f94:	69a2                	ld	s3,8(sp)
    80002f96:	6145                	addi	sp,sp,48
    80002f98:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f9a:	00005517          	auipc	a0,0x5
    80002f9e:	53650513          	addi	a0,a0,1334 # 800084d0 <states.0+0xf8>
    80002fa2:	ffffd097          	auipc	ra,0xffffd
    80002fa6:	59e080e7          	jalr	1438(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002faa:	00005517          	auipc	a0,0x5
    80002fae:	54e50513          	addi	a0,a0,1358 # 800084f8 <states.0+0x120>
    80002fb2:	ffffd097          	auipc	ra,0xffffd
    80002fb6:	58e080e7          	jalr	1422(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002fba:	85ce                	mv	a1,s3
    80002fbc:	00005517          	auipc	a0,0x5
    80002fc0:	55c50513          	addi	a0,a0,1372 # 80008518 <states.0+0x140>
    80002fc4:	ffffd097          	auipc	ra,0xffffd
    80002fc8:	5d8080e7          	jalr	1496(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fcc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fd0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fd4:	00005517          	auipc	a0,0x5
    80002fd8:	55450513          	addi	a0,a0,1364 # 80008528 <states.0+0x150>
    80002fdc:	ffffd097          	auipc	ra,0xffffd
    80002fe0:	5c0080e7          	jalr	1472(ra) # 8000059c <printf>
    panic("kerneltrap");
    80002fe4:	00005517          	auipc	a0,0x5
    80002fe8:	55c50513          	addi	a0,a0,1372 # 80008540 <states.0+0x168>
    80002fec:	ffffd097          	auipc	ra,0xffffd
    80002ff0:	554080e7          	jalr	1364(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	d20080e7          	jalr	-736(ra) # 80001d14 <myproc>
    80002ffc:	d541                	beqz	a0,80002f84 <kerneltrap+0x38>
    80002ffe:	fffff097          	auipc	ra,0xfffff
    80003002:	d16080e7          	jalr	-746(ra) # 80001d14 <myproc>
    80003006:	4d18                	lw	a4,24(a0)
    80003008:	4791                	li	a5,4
    8000300a:	f6f71de3          	bne	a4,a5,80002f84 <kerneltrap+0x38>
    yield();
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	478080e7          	jalr	1144(ra) # 80002486 <yield>
    80003016:	b7bd                	j	80002f84 <kerneltrap+0x38>

0000000080003018 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80003018:	1101                	addi	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	cf0080e7          	jalr	-784(ra) # 80001d14 <myproc>
    switch (n)
    8000302c:	4795                	li	a5,5
    8000302e:	0497e163          	bltu	a5,s1,80003070 <argraw+0x58>
    80003032:	048a                	slli	s1,s1,0x2
    80003034:	00005717          	auipc	a4,0x5
    80003038:	54470713          	addi	a4,a4,1348 # 80008578 <states.0+0x1a0>
    8000303c:	94ba                	add	s1,s1,a4
    8000303e:	409c                	lw	a5,0(s1)
    80003040:	97ba                	add	a5,a5,a4
    80003042:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80003044:	6d3c                	ld	a5,88(a0)
    80003046:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret
        return p->trapframe->a1;
    80003052:	6d3c                	ld	a5,88(a0)
    80003054:	7fa8                	ld	a0,120(a5)
    80003056:	bfcd                	j	80003048 <argraw+0x30>
        return p->trapframe->a2;
    80003058:	6d3c                	ld	a5,88(a0)
    8000305a:	63c8                	ld	a0,128(a5)
    8000305c:	b7f5                	j	80003048 <argraw+0x30>
        return p->trapframe->a3;
    8000305e:	6d3c                	ld	a5,88(a0)
    80003060:	67c8                	ld	a0,136(a5)
    80003062:	b7dd                	j	80003048 <argraw+0x30>
        return p->trapframe->a4;
    80003064:	6d3c                	ld	a5,88(a0)
    80003066:	6bc8                	ld	a0,144(a5)
    80003068:	b7c5                	j	80003048 <argraw+0x30>
        return p->trapframe->a5;
    8000306a:	6d3c                	ld	a5,88(a0)
    8000306c:	6fc8                	ld	a0,152(a5)
    8000306e:	bfe9                	j	80003048 <argraw+0x30>
    panic("argraw");
    80003070:	00005517          	auipc	a0,0x5
    80003074:	4e050513          	addi	a0,a0,1248 # 80008550 <states.0+0x178>
    80003078:	ffffd097          	auipc	ra,0xffffd
    8000307c:	4c8080e7          	jalr	1224(ra) # 80000540 <panic>

0000000080003080 <fetchaddr>:
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	e426                	sd	s1,8(sp)
    80003088:	e04a                	sd	s2,0(sp)
    8000308a:	1000                	addi	s0,sp,32
    8000308c:	84aa                	mv	s1,a0
    8000308e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	c84080e7          	jalr	-892(ra) # 80001d14 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003098:	653c                	ld	a5,72(a0)
    8000309a:	02f4f863          	bgeu	s1,a5,800030ca <fetchaddr+0x4a>
    8000309e:	00848713          	addi	a4,s1,8
    800030a2:	02e7e663          	bltu	a5,a4,800030ce <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030a6:	46a1                	li	a3,8
    800030a8:	8626                	mv	a2,s1
    800030aa:	85ca                	mv	a1,s2
    800030ac:	6928                	ld	a0,80(a0)
    800030ae:	fffff097          	auipc	ra,0xfffff
    800030b2:	8b4080e7          	jalr	-1868(ra) # 80001962 <copyin>
    800030b6:	00a03533          	snez	a0,a0
    800030ba:	40a00533          	neg	a0,a0
}
    800030be:	60e2                	ld	ra,24(sp)
    800030c0:	6442                	ld	s0,16(sp)
    800030c2:	64a2                	ld	s1,8(sp)
    800030c4:	6902                	ld	s2,0(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret
        return -1;
    800030ca:	557d                	li	a0,-1
    800030cc:	bfcd                	j	800030be <fetchaddr+0x3e>
    800030ce:	557d                	li	a0,-1
    800030d0:	b7fd                	j	800030be <fetchaddr+0x3e>

00000000800030d2 <fetchstr>:
{
    800030d2:	7179                	addi	sp,sp,-48
    800030d4:	f406                	sd	ra,40(sp)
    800030d6:	f022                	sd	s0,32(sp)
    800030d8:	ec26                	sd	s1,24(sp)
    800030da:	e84a                	sd	s2,16(sp)
    800030dc:	e44e                	sd	s3,8(sp)
    800030de:	1800                	addi	s0,sp,48
    800030e0:	892a                	mv	s2,a0
    800030e2:	84ae                	mv	s1,a1
    800030e4:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	c2e080e7          	jalr	-978(ra) # 80001d14 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    800030ee:	86ce                	mv	a3,s3
    800030f0:	864a                	mv	a2,s2
    800030f2:	85a6                	mv	a1,s1
    800030f4:	6928                	ld	a0,80(a0)
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	8fa080e7          	jalr	-1798(ra) # 800019f0 <copyinstr>
    800030fe:	00054e63          	bltz	a0,8000311a <fetchstr+0x48>
    return strlen(buf);
    80003102:	8526                	mv	a0,s1
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	ed6080e7          	jalr	-298(ra) # 80000fda <strlen>
}
    8000310c:	70a2                	ld	ra,40(sp)
    8000310e:	7402                	ld	s0,32(sp)
    80003110:	64e2                	ld	s1,24(sp)
    80003112:	6942                	ld	s2,16(sp)
    80003114:	69a2                	ld	s3,8(sp)
    80003116:	6145                	addi	sp,sp,48
    80003118:	8082                	ret
        return -1;
    8000311a:	557d                	li	a0,-1
    8000311c:	bfc5                	j	8000310c <fetchstr+0x3a>

000000008000311e <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	eee080e7          	jalr	-274(ra) # 80003018 <argraw>
    80003132:	c088                	sw	a0,0(s1)
}
    80003134:	60e2                	ld	ra,24(sp)
    80003136:	6442                	ld	s0,16(sp)
    80003138:	64a2                	ld	s1,8(sp)
    8000313a:	6105                	addi	sp,sp,32
    8000313c:	8082                	ret

000000008000313e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000313e:	1101                	addi	sp,sp,-32
    80003140:	ec06                	sd	ra,24(sp)
    80003142:	e822                	sd	s0,16(sp)
    80003144:	e426                	sd	s1,8(sp)
    80003146:	1000                	addi	s0,sp,32
    80003148:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000314a:	00000097          	auipc	ra,0x0
    8000314e:	ece080e7          	jalr	-306(ra) # 80003018 <argraw>
    80003152:	e088                	sd	a0,0(s1)
}
    80003154:	60e2                	ld	ra,24(sp)
    80003156:	6442                	ld	s0,16(sp)
    80003158:	64a2                	ld	s1,8(sp)
    8000315a:	6105                	addi	sp,sp,32
    8000315c:	8082                	ret

000000008000315e <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000315e:	7179                	addi	sp,sp,-48
    80003160:	f406                	sd	ra,40(sp)
    80003162:	f022                	sd	s0,32(sp)
    80003164:	ec26                	sd	s1,24(sp)
    80003166:	e84a                	sd	s2,16(sp)
    80003168:	1800                	addi	s0,sp,48
    8000316a:	84ae                	mv	s1,a1
    8000316c:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    8000316e:	fd840593          	addi	a1,s0,-40
    80003172:	00000097          	auipc	ra,0x0
    80003176:	fcc080e7          	jalr	-52(ra) # 8000313e <argaddr>
    return fetchstr(addr, buf, max);
    8000317a:	864a                	mv	a2,s2
    8000317c:	85a6                	mv	a1,s1
    8000317e:	fd843503          	ld	a0,-40(s0)
    80003182:	00000097          	auipc	ra,0x0
    80003186:	f50080e7          	jalr	-176(ra) # 800030d2 <fetchstr>
}
    8000318a:	70a2                	ld	ra,40(sp)
    8000318c:	7402                	ld	s0,32(sp)
    8000318e:	64e2                	ld	s1,24(sp)
    80003190:	6942                	ld	s2,16(sp)
    80003192:	6145                	addi	sp,sp,48
    80003194:	8082                	ret

0000000080003196 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	e04a                	sd	s2,0(sp)
    800031a0:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800031a2:	fffff097          	auipc	ra,0xfffff
    800031a6:	b72080e7          	jalr	-1166(ra) # 80001d14 <myproc>
    800031aa:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800031ac:	05853903          	ld	s2,88(a0)
    800031b0:	0a893783          	ld	a5,168(s2)
    800031b4:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800031b8:	37fd                	addiw	a5,a5,-1 # 7fffffff <_entry-0x1>
    800031ba:	4765                	li	a4,25
    800031bc:	00f76f63          	bltu	a4,a5,800031da <syscall+0x44>
    800031c0:	00369713          	slli	a4,a3,0x3
    800031c4:	00005797          	auipc	a5,0x5
    800031c8:	3cc78793          	addi	a5,a5,972 # 80008590 <syscalls>
    800031cc:	97ba                	add	a5,a5,a4
    800031ce:	639c                	ld	a5,0(a5)
    800031d0:	c789                	beqz	a5,800031da <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800031d2:	9782                	jalr	a5
    800031d4:	06a93823          	sd	a0,112(s2)
    800031d8:	a839                	j	800031f6 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800031da:	15848613          	addi	a2,s1,344
    800031de:	588c                	lw	a1,48(s1)
    800031e0:	00005517          	auipc	a0,0x5
    800031e4:	37850513          	addi	a0,a0,888 # 80008558 <states.0+0x180>
    800031e8:	ffffd097          	auipc	ra,0xffffd
    800031ec:	3b4080e7          	jalr	948(ra) # 8000059c <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800031f0:	6cbc                	ld	a5,88(s1)
    800031f2:	577d                	li	a4,-1
    800031f4:	fbb8                	sd	a4,112(a5)
    }
}
    800031f6:	60e2                	ld	ra,24(sp)
    800031f8:	6442                	ld	s0,16(sp)
    800031fa:	64a2                	ld	s1,8(sp)
    800031fc:	6902                	ld	s2,0(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret

0000000080003202 <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    80003202:	1101                	addi	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    8000320a:	fec40593          	addi	a1,s0,-20
    8000320e:	4501                	li	a0,0
    80003210:	00000097          	auipc	ra,0x0
    80003214:	f0e080e7          	jalr	-242(ra) # 8000311e <argint>
    exit(n);
    80003218:	fec42503          	lw	a0,-20(s0)
    8000321c:	fffff097          	auipc	ra,0xfffff
    80003220:	3da080e7          	jalr	986(ra) # 800025f6 <exit>
    return 0; // not reached
}
    80003224:	4501                	li	a0,0
    80003226:	60e2                	ld	ra,24(sp)
    80003228:	6442                	ld	s0,16(sp)
    8000322a:	6105                	addi	sp,sp,32
    8000322c:	8082                	ret

000000008000322e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000322e:	1141                	addi	sp,sp,-16
    80003230:	e406                	sd	ra,8(sp)
    80003232:	e022                	sd	s0,0(sp)
    80003234:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003236:	fffff097          	auipc	ra,0xfffff
    8000323a:	ade080e7          	jalr	-1314(ra) # 80001d14 <myproc>
}
    8000323e:	5908                	lw	a0,48(a0)
    80003240:	60a2                	ld	ra,8(sp)
    80003242:	6402                	ld	s0,0(sp)
    80003244:	0141                	addi	sp,sp,16
    80003246:	8082                	ret

0000000080003248 <sys_fork>:

uint64
sys_fork(void)
{
    80003248:	1141                	addi	sp,sp,-16
    8000324a:	e406                	sd	ra,8(sp)
    8000324c:	e022                	sd	s0,0(sp)
    8000324e:	0800                	addi	s0,sp,16
    return fork();
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	010080e7          	jalr	16(ra) # 80002260 <fork>
}
    80003258:	60a2                	ld	ra,8(sp)
    8000325a:	6402                	ld	s0,0(sp)
    8000325c:	0141                	addi	sp,sp,16
    8000325e:	8082                	ret

0000000080003260 <sys_wait>:

uint64
sys_wait(void)
{
    80003260:	1101                	addi	sp,sp,-32
    80003262:	ec06                	sd	ra,24(sp)
    80003264:	e822                	sd	s0,16(sp)
    80003266:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003268:	fe840593          	addi	a1,s0,-24
    8000326c:	4501                	li	a0,0
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	ed0080e7          	jalr	-304(ra) # 8000313e <argaddr>
    return wait(p);
    80003276:	fe843503          	ld	a0,-24(s0)
    8000327a:	fffff097          	auipc	ra,0xfffff
    8000327e:	522080e7          	jalr	1314(ra) # 8000279c <wait>
}
    80003282:	60e2                	ld	ra,24(sp)
    80003284:	6442                	ld	s0,16(sp)
    80003286:	6105                	addi	sp,sp,32
    80003288:	8082                	ret

000000008000328a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000328a:	7179                	addi	sp,sp,-48
    8000328c:	f406                	sd	ra,40(sp)
    8000328e:	f022                	sd	s0,32(sp)
    80003290:	ec26                	sd	s1,24(sp)
    80003292:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003294:	fdc40593          	addi	a1,s0,-36
    80003298:	4501                	li	a0,0
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	e84080e7          	jalr	-380(ra) # 8000311e <argint>
    addr = myproc()->sz;
    800032a2:	fffff097          	auipc	ra,0xfffff
    800032a6:	a72080e7          	jalr	-1422(ra) # 80001d14 <myproc>
    800032aa:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800032ac:	fdc42503          	lw	a0,-36(s0)
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	dbe080e7          	jalr	-578(ra) # 8000206e <growproc>
    800032b8:	00054863          	bltz	a0,800032c8 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800032bc:	8526                	mv	a0,s1
    800032be:	70a2                	ld	ra,40(sp)
    800032c0:	7402                	ld	s0,32(sp)
    800032c2:	64e2                	ld	s1,24(sp)
    800032c4:	6145                	addi	sp,sp,48
    800032c6:	8082                	ret
        return -1;
    800032c8:	54fd                	li	s1,-1
    800032ca:	bfcd                	j	800032bc <sys_sbrk+0x32>

00000000800032cc <sys_sleep>:

uint64
sys_sleep(void)
{
    800032cc:	7139                	addi	sp,sp,-64
    800032ce:	fc06                	sd	ra,56(sp)
    800032d0:	f822                	sd	s0,48(sp)
    800032d2:	f426                	sd	s1,40(sp)
    800032d4:	f04a                	sd	s2,32(sp)
    800032d6:	ec4e                	sd	s3,24(sp)
    800032d8:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800032da:	fcc40593          	addi	a1,s0,-52
    800032de:	4501                	li	a0,0
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	e3e080e7          	jalr	-450(ra) # 8000311e <argint>
    acquire(&tickslock);
    800032e8:	00034517          	auipc	a0,0x34
    800032ec:	84850513          	addi	a0,a0,-1976 # 80036b30 <tickslock>
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	a72080e7          	jalr	-1422(ra) # 80000d62 <acquire>
    ticks0 = ticks;
    800032f8:	00005917          	auipc	s2,0x5
    800032fc:	79892903          	lw	s2,1944(s2) # 80008a90 <ticks>
    while (ticks - ticks0 < n)
    80003300:	fcc42783          	lw	a5,-52(s0)
    80003304:	cf9d                	beqz	a5,80003342 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003306:	00034997          	auipc	s3,0x34
    8000330a:	82a98993          	addi	s3,s3,-2006 # 80036b30 <tickslock>
    8000330e:	00005497          	auipc	s1,0x5
    80003312:	78248493          	addi	s1,s1,1922 # 80008a90 <ticks>
        if (killed(myproc()))
    80003316:	fffff097          	auipc	ra,0xfffff
    8000331a:	9fe080e7          	jalr	-1538(ra) # 80001d14 <myproc>
    8000331e:	fffff097          	auipc	ra,0xfffff
    80003322:	44c080e7          	jalr	1100(ra) # 8000276a <killed>
    80003326:	ed15                	bnez	a0,80003362 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003328:	85ce                	mv	a1,s3
    8000332a:	8526                	mv	a0,s1
    8000332c:	fffff097          	auipc	ra,0xfffff
    80003330:	196080e7          	jalr	406(ra) # 800024c2 <sleep>
    while (ticks - ticks0 < n)
    80003334:	409c                	lw	a5,0(s1)
    80003336:	412787bb          	subw	a5,a5,s2
    8000333a:	fcc42703          	lw	a4,-52(s0)
    8000333e:	fce7ece3          	bltu	a5,a4,80003316 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003342:	00033517          	auipc	a0,0x33
    80003346:	7ee50513          	addi	a0,a0,2030 # 80036b30 <tickslock>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	acc080e7          	jalr	-1332(ra) # 80000e16 <release>
    return 0;
    80003352:	4501                	li	a0,0
}
    80003354:	70e2                	ld	ra,56(sp)
    80003356:	7442                	ld	s0,48(sp)
    80003358:	74a2                	ld	s1,40(sp)
    8000335a:	7902                	ld	s2,32(sp)
    8000335c:	69e2                	ld	s3,24(sp)
    8000335e:	6121                	addi	sp,sp,64
    80003360:	8082                	ret
            release(&tickslock);
    80003362:	00033517          	auipc	a0,0x33
    80003366:	7ce50513          	addi	a0,a0,1998 # 80036b30 <tickslock>
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	aac080e7          	jalr	-1364(ra) # 80000e16 <release>
            return -1;
    80003372:	557d                	li	a0,-1
    80003374:	b7c5                	j	80003354 <sys_sleep+0x88>

0000000080003376 <sys_kill>:

uint64
sys_kill(void)
{
    80003376:	1101                	addi	sp,sp,-32
    80003378:	ec06                	sd	ra,24(sp)
    8000337a:	e822                	sd	s0,16(sp)
    8000337c:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000337e:	fec40593          	addi	a1,s0,-20
    80003382:	4501                	li	a0,0
    80003384:	00000097          	auipc	ra,0x0
    80003388:	d9a080e7          	jalr	-614(ra) # 8000311e <argint>
    return kill(pid);
    8000338c:	fec42503          	lw	a0,-20(s0)
    80003390:	fffff097          	auipc	ra,0xfffff
    80003394:	33c080e7          	jalr	828(ra) # 800026cc <kill>
}
    80003398:	60e2                	ld	ra,24(sp)
    8000339a:	6442                	ld	s0,16(sp)
    8000339c:	6105                	addi	sp,sp,32
    8000339e:	8082                	ret

00000000800033a0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800033aa:	00033517          	auipc	a0,0x33
    800033ae:	78650513          	addi	a0,a0,1926 # 80036b30 <tickslock>
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	9b0080e7          	jalr	-1616(ra) # 80000d62 <acquire>
    xticks = ticks;
    800033ba:	00005497          	auipc	s1,0x5
    800033be:	6d64a483          	lw	s1,1750(s1) # 80008a90 <ticks>
    release(&tickslock);
    800033c2:	00033517          	auipc	a0,0x33
    800033c6:	76e50513          	addi	a0,a0,1902 # 80036b30 <tickslock>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	a4c080e7          	jalr	-1460(ra) # 80000e16 <release>
    return xticks;
}
    800033d2:	02049513          	slli	a0,s1,0x20
    800033d6:	9101                	srli	a0,a0,0x20
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	64a2                	ld	s1,8(sp)
    800033de:	6105                	addi	sp,sp,32
    800033e0:	8082                	ret

00000000800033e2 <sys_ps>:

void *
sys_ps(void)
{
    800033e2:	1101                	addi	sp,sp,-32
    800033e4:	ec06                	sd	ra,24(sp)
    800033e6:	e822                	sd	s0,16(sp)
    800033e8:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800033ea:	fe042623          	sw	zero,-20(s0)
    800033ee:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800033f2:	fec40593          	addi	a1,s0,-20
    800033f6:	4501                	li	a0,0
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	d26080e7          	jalr	-730(ra) # 8000311e <argint>
    argint(1, &count);
    80003400:	fe840593          	addi	a1,s0,-24
    80003404:	4505                	li	a0,1
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	d18080e7          	jalr	-744(ra) # 8000311e <argint>
    return ps((uint8)start, (uint8)count);
    8000340e:	fe844583          	lbu	a1,-24(s0)
    80003412:	fec44503          	lbu	a0,-20(s0)
    80003416:	fffff097          	auipc	ra,0xfffff
    8000341a:	cb4080e7          	jalr	-844(ra) # 800020ca <ps>
}
    8000341e:	60e2                	ld	ra,24(sp)
    80003420:	6442                	ld	s0,16(sp)
    80003422:	6105                	addi	sp,sp,32
    80003424:	8082                	ret

0000000080003426 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003426:	1141                	addi	sp,sp,-16
    80003428:	e406                	sd	ra,8(sp)
    8000342a:	e022                	sd	s0,0(sp)
    8000342c:	0800                	addi	s0,sp,16
    schedls();
    8000342e:	fffff097          	auipc	ra,0xfffff
    80003432:	5f8080e7          	jalr	1528(ra) # 80002a26 <schedls>
    return 0;
}
    80003436:	4501                	li	a0,0
    80003438:	60a2                	ld	ra,8(sp)
    8000343a:	6402                	ld	s0,0(sp)
    8000343c:	0141                	addi	sp,sp,16
    8000343e:	8082                	ret

0000000080003440 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003440:	1101                	addi	sp,sp,-32
    80003442:	ec06                	sd	ra,24(sp)
    80003444:	e822                	sd	s0,16(sp)
    80003446:	1000                	addi	s0,sp,32
    int id = 0;
    80003448:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000344c:	fec40593          	addi	a1,s0,-20
    80003450:	4501                	li	a0,0
    80003452:	00000097          	auipc	ra,0x0
    80003456:	ccc080e7          	jalr	-820(ra) # 8000311e <argint>
    schedset(id - 1);
    8000345a:	fec42503          	lw	a0,-20(s0)
    8000345e:	357d                	addiw	a0,a0,-1
    80003460:	fffff097          	auipc	ra,0xfffff
    80003464:	65c080e7          	jalr	1628(ra) # 80002abc <schedset>
    return 0;
}
    80003468:	4501                	li	a0,0
    8000346a:	60e2                	ld	ra,24(sp)
    8000346c:	6442                	ld	s0,16(sp)
    8000346e:	6105                	addi	sp,sp,32
    80003470:	8082                	ret

0000000080003472 <sys_va2pa>:
}*/

extern struct proc proc[NPROC];

uint64 sys_va2pa(void)
{
    80003472:	1101                	addi	sp,sp,-32
    80003474:	ec06                	sd	ra,24(sp)
    80003476:	e822                	sd	s0,16(sp)
    80003478:	1000                	addi	s0,sp,32
    
    uint64 va; // Virtual address
    argaddr(0, &va);
    8000347a:	fe840593          	addi	a1,s0,-24
    8000347e:	4501                	li	a0,0
    80003480:	00000097          	auipc	ra,0x0
    80003484:	cbe080e7          	jalr	-834(ra) # 8000313e <argaddr>
    int pid = 0;   // Process ID get from args
    80003488:	fe042223          	sw	zero,-28(s0)
    argint(1, &pid);
    8000348c:	fe440593          	addi	a1,s0,-28
    80003490:	4505                	li	a0,1
    80003492:	00000097          	auipc	ra,0x0
    80003496:	c8c080e7          	jalr	-884(ra) # 8000311e <argint>

    struct proc *target_proc = myproc(); // Default to current process
    8000349a:	fffff097          	auipc	ra,0xfffff
    8000349e:	87a080e7          	jalr	-1926(ra) # 80001d14 <myproc>

    if (pid != 0) { // If a specific PID is requested
    800034a2:	fe442703          	lw	a4,-28(s0)
    800034a6:	c31d                	beqz	a4,800034cc <sys_va2pa+0x5a>
        int found = 0;
        for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800034a8:	0002e517          	auipc	a0,0x2e
    800034ac:	c8850513          	addi	a0,a0,-888 # 80031130 <proc>
    800034b0:	00033697          	auipc	a3,0x33
    800034b4:	68068693          	addi	a3,a3,1664 # 80036b30 <tickslock>
    800034b8:	a029                	j	800034c2 <sys_va2pa+0x50>
    800034ba:	16850513          	addi	a0,a0,360
    800034be:	02d50f63          	beq	a0,a3,800034fc <sys_va2pa+0x8a>
            if(p->pid == pid && p->state != UNUSED) {
    800034c2:	591c                	lw	a5,48(a0)
    800034c4:	fee79be3          	bne	a5,a4,800034ba <sys_va2pa+0x48>
    800034c8:	4d1c                	lw	a5,24(a0)
    800034ca:	dbe5                	beqz	a5,800034ba <sys_va2pa+0x48>
            return 0; // PID not found, return 0
        }
    }

    // Walk the page table to find the physical address corresponding to the given virtual address
    pte_t *pte = walk(target_proc->pagetable, va, 0); // 0 to not create
    800034cc:	4601                	li	a2,0
    800034ce:	fe843583          	ld	a1,-24(s0)
    800034d2:	6928                	ld	a0,80(a0)
    800034d4:	ffffe097          	auipc	ra,0xffffe
    800034d8:	c6e080e7          	jalr	-914(ra) # 80001142 <walk>
    if(pte == 0 || (*pte & PTE_V) == 0) {
    800034dc:	c115                	beqz	a0,80003500 <sys_va2pa+0x8e>
    800034de:	611c                	ld	a5,0(a0)
    800034e0:	0017f513          	andi	a0,a5,1
    800034e4:	c901                	beqz	a0,800034f4 <sys_va2pa+0x82>
        return 0; // Virtual address not mapped
    }

    uint64 pa = PTE2PA(*pte) | (va & 0xFFF); // Extract physical address and add offset
    800034e6:	83a9                	srli	a5,a5,0xa
    800034e8:	07b2                	slli	a5,a5,0xc
    800034ea:	fe843503          	ld	a0,-24(s0)
    800034ee:	1552                	slli	a0,a0,0x34
    800034f0:	9151                	srli	a0,a0,0x34
    800034f2:	8d5d                	or	a0,a0,a5
    
    return pa;
}
    800034f4:	60e2                	ld	ra,24(sp)
    800034f6:	6442                	ld	s0,16(sp)
    800034f8:	6105                	addi	sp,sp,32
    800034fa:	8082                	ret
            return 0; // PID not found, return 0
    800034fc:	4501                	li	a0,0
    800034fe:	bfdd                	j	800034f4 <sys_va2pa+0x82>
        return 0; // Virtual address not mapped
    80003500:	4501                	li	a0,0
    80003502:	bfcd                	j	800034f4 <sys_va2pa+0x82>

0000000080003504 <sys_pfreepages>:


uint64 sys_pfreepages(void)
{
    80003504:	1141                	addi	sp,sp,-16
    80003506:	e406                	sd	ra,8(sp)
    80003508:	e022                	sd	s0,0(sp)
    8000350a:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    8000350c:	00005597          	auipc	a1,0x5
    80003510:	55c5b583          	ld	a1,1372(a1) # 80008a68 <FREE_PAGES>
    80003514:	00005517          	auipc	a0,0x5
    80003518:	05c50513          	addi	a0,a0,92 # 80008570 <states.0+0x198>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	080080e7          	jalr	128(ra) # 8000059c <printf>
    return 0;
    80003524:	4501                	li	a0,0
    80003526:	60a2                	ld	ra,8(sp)
    80003528:	6402                	ld	s0,0(sp)
    8000352a:	0141                	addi	sp,sp,16
    8000352c:	8082                	ret

000000008000352e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000352e:	7179                	addi	sp,sp,-48
    80003530:	f406                	sd	ra,40(sp)
    80003532:	f022                	sd	s0,32(sp)
    80003534:	ec26                	sd	s1,24(sp)
    80003536:	e84a                	sd	s2,16(sp)
    80003538:	e44e                	sd	s3,8(sp)
    8000353a:	e052                	sd	s4,0(sp)
    8000353c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000353e:	00005597          	auipc	a1,0x5
    80003542:	12a58593          	addi	a1,a1,298 # 80008668 <syscalls+0xd8>
    80003546:	00033517          	auipc	a0,0x33
    8000354a:	60250513          	addi	a0,a0,1538 # 80036b48 <bcache>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	784080e7          	jalr	1924(ra) # 80000cd2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003556:	0003b797          	auipc	a5,0x3b
    8000355a:	5f278793          	addi	a5,a5,1522 # 8003eb48 <bcache+0x8000>
    8000355e:	0003c717          	auipc	a4,0x3c
    80003562:	85270713          	addi	a4,a4,-1966 # 8003edb0 <bcache+0x8268>
    80003566:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000356a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000356e:	00033497          	auipc	s1,0x33
    80003572:	5f248493          	addi	s1,s1,1522 # 80036b60 <bcache+0x18>
    b->next = bcache.head.next;
    80003576:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003578:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000357a:	00005a17          	auipc	s4,0x5
    8000357e:	0f6a0a13          	addi	s4,s4,246 # 80008670 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003582:	2b893783          	ld	a5,696(s2)
    80003586:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003588:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000358c:	85d2                	mv	a1,s4
    8000358e:	01048513          	addi	a0,s1,16
    80003592:	00001097          	auipc	ra,0x1
    80003596:	4c8080e7          	jalr	1224(ra) # 80004a5a <initsleeplock>
    bcache.head.next->prev = b;
    8000359a:	2b893783          	ld	a5,696(s2)
    8000359e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035a0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035a4:	45848493          	addi	s1,s1,1112
    800035a8:	fd349de3          	bne	s1,s3,80003582 <binit+0x54>
  }
}
    800035ac:	70a2                	ld	ra,40(sp)
    800035ae:	7402                	ld	s0,32(sp)
    800035b0:	64e2                	ld	s1,24(sp)
    800035b2:	6942                	ld	s2,16(sp)
    800035b4:	69a2                	ld	s3,8(sp)
    800035b6:	6a02                	ld	s4,0(sp)
    800035b8:	6145                	addi	sp,sp,48
    800035ba:	8082                	ret

00000000800035bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035bc:	7179                	addi	sp,sp,-48
    800035be:	f406                	sd	ra,40(sp)
    800035c0:	f022                	sd	s0,32(sp)
    800035c2:	ec26                	sd	s1,24(sp)
    800035c4:	e84a                	sd	s2,16(sp)
    800035c6:	e44e                	sd	s3,8(sp)
    800035c8:	1800                	addi	s0,sp,48
    800035ca:	892a                	mv	s2,a0
    800035cc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800035ce:	00033517          	auipc	a0,0x33
    800035d2:	57a50513          	addi	a0,a0,1402 # 80036b48 <bcache>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	78c080e7          	jalr	1932(ra) # 80000d62 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035de:	0003c497          	auipc	s1,0x3c
    800035e2:	8224b483          	ld	s1,-2014(s1) # 8003ee00 <bcache+0x82b8>
    800035e6:	0003b797          	auipc	a5,0x3b
    800035ea:	7ca78793          	addi	a5,a5,1994 # 8003edb0 <bcache+0x8268>
    800035ee:	02f48f63          	beq	s1,a5,8000362c <bread+0x70>
    800035f2:	873e                	mv	a4,a5
    800035f4:	a021                	j	800035fc <bread+0x40>
    800035f6:	68a4                	ld	s1,80(s1)
    800035f8:	02e48a63          	beq	s1,a4,8000362c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035fc:	449c                	lw	a5,8(s1)
    800035fe:	ff279ce3          	bne	a5,s2,800035f6 <bread+0x3a>
    80003602:	44dc                	lw	a5,12(s1)
    80003604:	ff3799e3          	bne	a5,s3,800035f6 <bread+0x3a>
      b->refcnt++;
    80003608:	40bc                	lw	a5,64(s1)
    8000360a:	2785                	addiw	a5,a5,1
    8000360c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000360e:	00033517          	auipc	a0,0x33
    80003612:	53a50513          	addi	a0,a0,1338 # 80036b48 <bcache>
    80003616:	ffffe097          	auipc	ra,0xffffe
    8000361a:	800080e7          	jalr	-2048(ra) # 80000e16 <release>
      acquiresleep(&b->lock);
    8000361e:	01048513          	addi	a0,s1,16
    80003622:	00001097          	auipc	ra,0x1
    80003626:	472080e7          	jalr	1138(ra) # 80004a94 <acquiresleep>
      return b;
    8000362a:	a8b9                	j	80003688 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000362c:	0003b497          	auipc	s1,0x3b
    80003630:	7cc4b483          	ld	s1,1996(s1) # 8003edf8 <bcache+0x82b0>
    80003634:	0003b797          	auipc	a5,0x3b
    80003638:	77c78793          	addi	a5,a5,1916 # 8003edb0 <bcache+0x8268>
    8000363c:	00f48863          	beq	s1,a5,8000364c <bread+0x90>
    80003640:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003642:	40bc                	lw	a5,64(s1)
    80003644:	cf81                	beqz	a5,8000365c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003646:	64a4                	ld	s1,72(s1)
    80003648:	fee49de3          	bne	s1,a4,80003642 <bread+0x86>
  panic("bget: no buffers");
    8000364c:	00005517          	auipc	a0,0x5
    80003650:	02c50513          	addi	a0,a0,44 # 80008678 <syscalls+0xe8>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	eec080e7          	jalr	-276(ra) # 80000540 <panic>
      b->dev = dev;
    8000365c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003660:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003664:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003668:	4785                	li	a5,1
    8000366a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000366c:	00033517          	auipc	a0,0x33
    80003670:	4dc50513          	addi	a0,a0,1244 # 80036b48 <bcache>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	7a2080e7          	jalr	1954(ra) # 80000e16 <release>
      acquiresleep(&b->lock);
    8000367c:	01048513          	addi	a0,s1,16
    80003680:	00001097          	auipc	ra,0x1
    80003684:	414080e7          	jalr	1044(ra) # 80004a94 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003688:	409c                	lw	a5,0(s1)
    8000368a:	cb89                	beqz	a5,8000369c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000368c:	8526                	mv	a0,s1
    8000368e:	70a2                	ld	ra,40(sp)
    80003690:	7402                	ld	s0,32(sp)
    80003692:	64e2                	ld	s1,24(sp)
    80003694:	6942                	ld	s2,16(sp)
    80003696:	69a2                	ld	s3,8(sp)
    80003698:	6145                	addi	sp,sp,48
    8000369a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000369c:	4581                	li	a1,0
    8000369e:	8526                	mv	a0,s1
    800036a0:	00003097          	auipc	ra,0x3
    800036a4:	fe2080e7          	jalr	-30(ra) # 80006682 <virtio_disk_rw>
    b->valid = 1;
    800036a8:	4785                	li	a5,1
    800036aa:	c09c                	sw	a5,0(s1)
  return b;
    800036ac:	b7c5                	j	8000368c <bread+0xd0>

00000000800036ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036ae:	1101                	addi	sp,sp,-32
    800036b0:	ec06                	sd	ra,24(sp)
    800036b2:	e822                	sd	s0,16(sp)
    800036b4:	e426                	sd	s1,8(sp)
    800036b6:	1000                	addi	s0,sp,32
    800036b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036ba:	0541                	addi	a0,a0,16
    800036bc:	00001097          	auipc	ra,0x1
    800036c0:	472080e7          	jalr	1138(ra) # 80004b2e <holdingsleep>
    800036c4:	cd01                	beqz	a0,800036dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036c6:	4585                	li	a1,1
    800036c8:	8526                	mv	a0,s1
    800036ca:	00003097          	auipc	ra,0x3
    800036ce:	fb8080e7          	jalr	-72(ra) # 80006682 <virtio_disk_rw>
}
    800036d2:	60e2                	ld	ra,24(sp)
    800036d4:	6442                	ld	s0,16(sp)
    800036d6:	64a2                	ld	s1,8(sp)
    800036d8:	6105                	addi	sp,sp,32
    800036da:	8082                	ret
    panic("bwrite");
    800036dc:	00005517          	auipc	a0,0x5
    800036e0:	fb450513          	addi	a0,a0,-76 # 80008690 <syscalls+0x100>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	e5c080e7          	jalr	-420(ra) # 80000540 <panic>

00000000800036ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036ec:	1101                	addi	sp,sp,-32
    800036ee:	ec06                	sd	ra,24(sp)
    800036f0:	e822                	sd	s0,16(sp)
    800036f2:	e426                	sd	s1,8(sp)
    800036f4:	e04a                	sd	s2,0(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036fa:	01050913          	addi	s2,a0,16
    800036fe:	854a                	mv	a0,s2
    80003700:	00001097          	auipc	ra,0x1
    80003704:	42e080e7          	jalr	1070(ra) # 80004b2e <holdingsleep>
    80003708:	c92d                	beqz	a0,8000377a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000370a:	854a                	mv	a0,s2
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	3de080e7          	jalr	990(ra) # 80004aea <releasesleep>

  acquire(&bcache.lock);
    80003714:	00033517          	auipc	a0,0x33
    80003718:	43450513          	addi	a0,a0,1076 # 80036b48 <bcache>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	646080e7          	jalr	1606(ra) # 80000d62 <acquire>
  b->refcnt--;
    80003724:	40bc                	lw	a5,64(s1)
    80003726:	37fd                	addiw	a5,a5,-1
    80003728:	0007871b          	sext.w	a4,a5
    8000372c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000372e:	eb05                	bnez	a4,8000375e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003730:	68bc                	ld	a5,80(s1)
    80003732:	64b8                	ld	a4,72(s1)
    80003734:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003736:	64bc                	ld	a5,72(s1)
    80003738:	68b8                	ld	a4,80(s1)
    8000373a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000373c:	0003b797          	auipc	a5,0x3b
    80003740:	40c78793          	addi	a5,a5,1036 # 8003eb48 <bcache+0x8000>
    80003744:	2b87b703          	ld	a4,696(a5)
    80003748:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000374a:	0003b717          	auipc	a4,0x3b
    8000374e:	66670713          	addi	a4,a4,1638 # 8003edb0 <bcache+0x8268>
    80003752:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003754:	2b87b703          	ld	a4,696(a5)
    80003758:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000375a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000375e:	00033517          	auipc	a0,0x33
    80003762:	3ea50513          	addi	a0,a0,1002 # 80036b48 <bcache>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	6b0080e7          	jalr	1712(ra) # 80000e16 <release>
}
    8000376e:	60e2                	ld	ra,24(sp)
    80003770:	6442                	ld	s0,16(sp)
    80003772:	64a2                	ld	s1,8(sp)
    80003774:	6902                	ld	s2,0(sp)
    80003776:	6105                	addi	sp,sp,32
    80003778:	8082                	ret
    panic("brelse");
    8000377a:	00005517          	auipc	a0,0x5
    8000377e:	f1e50513          	addi	a0,a0,-226 # 80008698 <syscalls+0x108>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	dbe080e7          	jalr	-578(ra) # 80000540 <panic>

000000008000378a <bpin>:

void
bpin(struct buf *b) {
    8000378a:	1101                	addi	sp,sp,-32
    8000378c:	ec06                	sd	ra,24(sp)
    8000378e:	e822                	sd	s0,16(sp)
    80003790:	e426                	sd	s1,8(sp)
    80003792:	1000                	addi	s0,sp,32
    80003794:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003796:	00033517          	auipc	a0,0x33
    8000379a:	3b250513          	addi	a0,a0,946 # 80036b48 <bcache>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	5c4080e7          	jalr	1476(ra) # 80000d62 <acquire>
  b->refcnt++;
    800037a6:	40bc                	lw	a5,64(s1)
    800037a8:	2785                	addiw	a5,a5,1
    800037aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037ac:	00033517          	auipc	a0,0x33
    800037b0:	39c50513          	addi	a0,a0,924 # 80036b48 <bcache>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	662080e7          	jalr	1634(ra) # 80000e16 <release>
}
    800037bc:	60e2                	ld	ra,24(sp)
    800037be:	6442                	ld	s0,16(sp)
    800037c0:	64a2                	ld	s1,8(sp)
    800037c2:	6105                	addi	sp,sp,32
    800037c4:	8082                	ret

00000000800037c6 <bunpin>:

void
bunpin(struct buf *b) {
    800037c6:	1101                	addi	sp,sp,-32
    800037c8:	ec06                	sd	ra,24(sp)
    800037ca:	e822                	sd	s0,16(sp)
    800037cc:	e426                	sd	s1,8(sp)
    800037ce:	1000                	addi	s0,sp,32
    800037d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037d2:	00033517          	auipc	a0,0x33
    800037d6:	37650513          	addi	a0,a0,886 # 80036b48 <bcache>
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	588080e7          	jalr	1416(ra) # 80000d62 <acquire>
  b->refcnt--;
    800037e2:	40bc                	lw	a5,64(s1)
    800037e4:	37fd                	addiw	a5,a5,-1
    800037e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037e8:	00033517          	auipc	a0,0x33
    800037ec:	36050513          	addi	a0,a0,864 # 80036b48 <bcache>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	626080e7          	jalr	1574(ra) # 80000e16 <release>
}
    800037f8:	60e2                	ld	ra,24(sp)
    800037fa:	6442                	ld	s0,16(sp)
    800037fc:	64a2                	ld	s1,8(sp)
    800037fe:	6105                	addi	sp,sp,32
    80003800:	8082                	ret

0000000080003802 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003802:	1101                	addi	sp,sp,-32
    80003804:	ec06                	sd	ra,24(sp)
    80003806:	e822                	sd	s0,16(sp)
    80003808:	e426                	sd	s1,8(sp)
    8000380a:	e04a                	sd	s2,0(sp)
    8000380c:	1000                	addi	s0,sp,32
    8000380e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003810:	00d5d59b          	srliw	a1,a1,0xd
    80003814:	0003c797          	auipc	a5,0x3c
    80003818:	a107a783          	lw	a5,-1520(a5) # 8003f224 <sb+0x1c>
    8000381c:	9dbd                	addw	a1,a1,a5
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	d9e080e7          	jalr	-610(ra) # 800035bc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003826:	0074f713          	andi	a4,s1,7
    8000382a:	4785                	li	a5,1
    8000382c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003830:	14ce                	slli	s1,s1,0x33
    80003832:	90d9                	srli	s1,s1,0x36
    80003834:	00950733          	add	a4,a0,s1
    80003838:	05874703          	lbu	a4,88(a4)
    8000383c:	00e7f6b3          	and	a3,a5,a4
    80003840:	c69d                	beqz	a3,8000386e <bfree+0x6c>
    80003842:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003844:	94aa                	add	s1,s1,a0
    80003846:	fff7c793          	not	a5,a5
    8000384a:	8f7d                	and	a4,a4,a5
    8000384c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003850:	00001097          	auipc	ra,0x1
    80003854:	126080e7          	jalr	294(ra) # 80004976 <log_write>
  brelse(bp);
    80003858:	854a                	mv	a0,s2
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	e92080e7          	jalr	-366(ra) # 800036ec <brelse>
}
    80003862:	60e2                	ld	ra,24(sp)
    80003864:	6442                	ld	s0,16(sp)
    80003866:	64a2                	ld	s1,8(sp)
    80003868:	6902                	ld	s2,0(sp)
    8000386a:	6105                	addi	sp,sp,32
    8000386c:	8082                	ret
    panic("freeing free block");
    8000386e:	00005517          	auipc	a0,0x5
    80003872:	e3250513          	addi	a0,a0,-462 # 800086a0 <syscalls+0x110>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	cca080e7          	jalr	-822(ra) # 80000540 <panic>

000000008000387e <balloc>:
{
    8000387e:	711d                	addi	sp,sp,-96
    80003880:	ec86                	sd	ra,88(sp)
    80003882:	e8a2                	sd	s0,80(sp)
    80003884:	e4a6                	sd	s1,72(sp)
    80003886:	e0ca                	sd	s2,64(sp)
    80003888:	fc4e                	sd	s3,56(sp)
    8000388a:	f852                	sd	s4,48(sp)
    8000388c:	f456                	sd	s5,40(sp)
    8000388e:	f05a                	sd	s6,32(sp)
    80003890:	ec5e                	sd	s7,24(sp)
    80003892:	e862                	sd	s8,16(sp)
    80003894:	e466                	sd	s9,8(sp)
    80003896:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003898:	0003c797          	auipc	a5,0x3c
    8000389c:	9747a783          	lw	a5,-1676(a5) # 8003f20c <sb+0x4>
    800038a0:	cff5                	beqz	a5,8000399c <balloc+0x11e>
    800038a2:	8baa                	mv	s7,a0
    800038a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038a6:	0003cb17          	auipc	s6,0x3c
    800038aa:	962b0b13          	addi	s6,s6,-1694 # 8003f208 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038b4:	6c89                	lui	s9,0x2
    800038b6:	a061                	j	8000393e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038b8:	97ca                	add	a5,a5,s2
    800038ba:	8e55                	or	a2,a2,a3
    800038bc:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800038c0:	854a                	mv	a0,s2
    800038c2:	00001097          	auipc	ra,0x1
    800038c6:	0b4080e7          	jalr	180(ra) # 80004976 <log_write>
        brelse(bp);
    800038ca:	854a                	mv	a0,s2
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	e20080e7          	jalr	-480(ra) # 800036ec <brelse>
  bp = bread(dev, bno);
    800038d4:	85a6                	mv	a1,s1
    800038d6:	855e                	mv	a0,s7
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	ce4080e7          	jalr	-796(ra) # 800035bc <bread>
    800038e0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038e2:	40000613          	li	a2,1024
    800038e6:	4581                	li	a1,0
    800038e8:	05850513          	addi	a0,a0,88
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	572080e7          	jalr	1394(ra) # 80000e5e <memset>
  log_write(bp);
    800038f4:	854a                	mv	a0,s2
    800038f6:	00001097          	auipc	ra,0x1
    800038fa:	080080e7          	jalr	128(ra) # 80004976 <log_write>
  brelse(bp);
    800038fe:	854a                	mv	a0,s2
    80003900:	00000097          	auipc	ra,0x0
    80003904:	dec080e7          	jalr	-532(ra) # 800036ec <brelse>
}
    80003908:	8526                	mv	a0,s1
    8000390a:	60e6                	ld	ra,88(sp)
    8000390c:	6446                	ld	s0,80(sp)
    8000390e:	64a6                	ld	s1,72(sp)
    80003910:	6906                	ld	s2,64(sp)
    80003912:	79e2                	ld	s3,56(sp)
    80003914:	7a42                	ld	s4,48(sp)
    80003916:	7aa2                	ld	s5,40(sp)
    80003918:	7b02                	ld	s6,32(sp)
    8000391a:	6be2                	ld	s7,24(sp)
    8000391c:	6c42                	ld	s8,16(sp)
    8000391e:	6ca2                	ld	s9,8(sp)
    80003920:	6125                	addi	sp,sp,96
    80003922:	8082                	ret
    brelse(bp);
    80003924:	854a                	mv	a0,s2
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	dc6080e7          	jalr	-570(ra) # 800036ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000392e:	015c87bb          	addw	a5,s9,s5
    80003932:	00078a9b          	sext.w	s5,a5
    80003936:	004b2703          	lw	a4,4(s6)
    8000393a:	06eaf163          	bgeu	s5,a4,8000399c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000393e:	41fad79b          	sraiw	a5,s5,0x1f
    80003942:	0137d79b          	srliw	a5,a5,0x13
    80003946:	015787bb          	addw	a5,a5,s5
    8000394a:	40d7d79b          	sraiw	a5,a5,0xd
    8000394e:	01cb2583          	lw	a1,28(s6)
    80003952:	9dbd                	addw	a1,a1,a5
    80003954:	855e                	mv	a0,s7
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	c66080e7          	jalr	-922(ra) # 800035bc <bread>
    8000395e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003960:	004b2503          	lw	a0,4(s6)
    80003964:	000a849b          	sext.w	s1,s5
    80003968:	8762                	mv	a4,s8
    8000396a:	faa4fde3          	bgeu	s1,a0,80003924 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000396e:	00777693          	andi	a3,a4,7
    80003972:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003976:	41f7579b          	sraiw	a5,a4,0x1f
    8000397a:	01d7d79b          	srliw	a5,a5,0x1d
    8000397e:	9fb9                	addw	a5,a5,a4
    80003980:	4037d79b          	sraiw	a5,a5,0x3
    80003984:	00f90633          	add	a2,s2,a5
    80003988:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000398c:	00c6f5b3          	and	a1,a3,a2
    80003990:	d585                	beqz	a1,800038b8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003992:	2705                	addiw	a4,a4,1
    80003994:	2485                	addiw	s1,s1,1
    80003996:	fd471ae3          	bne	a4,s4,8000396a <balloc+0xec>
    8000399a:	b769                	j	80003924 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000399c:	00005517          	auipc	a0,0x5
    800039a0:	d1c50513          	addi	a0,a0,-740 # 800086b8 <syscalls+0x128>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	bf8080e7          	jalr	-1032(ra) # 8000059c <printf>
  return 0;
    800039ac:	4481                	li	s1,0
    800039ae:	bfa9                	j	80003908 <balloc+0x8a>

00000000800039b0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800039b0:	7179                	addi	sp,sp,-48
    800039b2:	f406                	sd	ra,40(sp)
    800039b4:	f022                	sd	s0,32(sp)
    800039b6:	ec26                	sd	s1,24(sp)
    800039b8:	e84a                	sd	s2,16(sp)
    800039ba:	e44e                	sd	s3,8(sp)
    800039bc:	e052                	sd	s4,0(sp)
    800039be:	1800                	addi	s0,sp,48
    800039c0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039c2:	47ad                	li	a5,11
    800039c4:	02b7e863          	bltu	a5,a1,800039f4 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800039c8:	02059793          	slli	a5,a1,0x20
    800039cc:	01e7d593          	srli	a1,a5,0x1e
    800039d0:	00b504b3          	add	s1,a0,a1
    800039d4:	0504a903          	lw	s2,80(s1)
    800039d8:	06091e63          	bnez	s2,80003a54 <bmap+0xa4>
      addr = balloc(ip->dev);
    800039dc:	4108                	lw	a0,0(a0)
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	ea0080e7          	jalr	-352(ra) # 8000387e <balloc>
    800039e6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039ea:	06090563          	beqz	s2,80003a54 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800039ee:	0524a823          	sw	s2,80(s1)
    800039f2:	a08d                	j	80003a54 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039f4:	ff45849b          	addiw	s1,a1,-12
    800039f8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039fc:	0ff00793          	li	a5,255
    80003a00:	08e7e563          	bltu	a5,a4,80003a8a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a04:	08052903          	lw	s2,128(a0)
    80003a08:	00091d63          	bnez	s2,80003a22 <bmap+0x72>
      addr = balloc(ip->dev);
    80003a0c:	4108                	lw	a0,0(a0)
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	e70080e7          	jalr	-400(ra) # 8000387e <balloc>
    80003a16:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a1a:	02090d63          	beqz	s2,80003a54 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a1e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a22:	85ca                	mv	a1,s2
    80003a24:	0009a503          	lw	a0,0(s3)
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	b94080e7          	jalr	-1132(ra) # 800035bc <bread>
    80003a30:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a32:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a36:	02049713          	slli	a4,s1,0x20
    80003a3a:	01e75593          	srli	a1,a4,0x1e
    80003a3e:	00b784b3          	add	s1,a5,a1
    80003a42:	0004a903          	lw	s2,0(s1)
    80003a46:	02090063          	beqz	s2,80003a66 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a4a:	8552                	mv	a0,s4
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	ca0080e7          	jalr	-864(ra) # 800036ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a54:	854a                	mv	a0,s2
    80003a56:	70a2                	ld	ra,40(sp)
    80003a58:	7402                	ld	s0,32(sp)
    80003a5a:	64e2                	ld	s1,24(sp)
    80003a5c:	6942                	ld	s2,16(sp)
    80003a5e:	69a2                	ld	s3,8(sp)
    80003a60:	6a02                	ld	s4,0(sp)
    80003a62:	6145                	addi	sp,sp,48
    80003a64:	8082                	ret
      addr = balloc(ip->dev);
    80003a66:	0009a503          	lw	a0,0(s3)
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	e14080e7          	jalr	-492(ra) # 8000387e <balloc>
    80003a72:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a76:	fc090ae3          	beqz	s2,80003a4a <bmap+0x9a>
        a[bn] = addr;
    80003a7a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a7e:	8552                	mv	a0,s4
    80003a80:	00001097          	auipc	ra,0x1
    80003a84:	ef6080e7          	jalr	-266(ra) # 80004976 <log_write>
    80003a88:	b7c9                	j	80003a4a <bmap+0x9a>
  panic("bmap: out of range");
    80003a8a:	00005517          	auipc	a0,0x5
    80003a8e:	c4650513          	addi	a0,a0,-954 # 800086d0 <syscalls+0x140>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	aae080e7          	jalr	-1362(ra) # 80000540 <panic>

0000000080003a9a <iget>:
{
    80003a9a:	7179                	addi	sp,sp,-48
    80003a9c:	f406                	sd	ra,40(sp)
    80003a9e:	f022                	sd	s0,32(sp)
    80003aa0:	ec26                	sd	s1,24(sp)
    80003aa2:	e84a                	sd	s2,16(sp)
    80003aa4:	e44e                	sd	s3,8(sp)
    80003aa6:	e052                	sd	s4,0(sp)
    80003aa8:	1800                	addi	s0,sp,48
    80003aaa:	89aa                	mv	s3,a0
    80003aac:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003aae:	0003b517          	auipc	a0,0x3b
    80003ab2:	77a50513          	addi	a0,a0,1914 # 8003f228 <itable>
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	2ac080e7          	jalr	684(ra) # 80000d62 <acquire>
  empty = 0;
    80003abe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ac0:	0003b497          	auipc	s1,0x3b
    80003ac4:	78048493          	addi	s1,s1,1920 # 8003f240 <itable+0x18>
    80003ac8:	0003d697          	auipc	a3,0x3d
    80003acc:	20868693          	addi	a3,a3,520 # 80040cd0 <log>
    80003ad0:	a039                	j	80003ade <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ad2:	02090b63          	beqz	s2,80003b08 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ad6:	08848493          	addi	s1,s1,136
    80003ada:	02d48a63          	beq	s1,a3,80003b0e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ade:	449c                	lw	a5,8(s1)
    80003ae0:	fef059e3          	blez	a5,80003ad2 <iget+0x38>
    80003ae4:	4098                	lw	a4,0(s1)
    80003ae6:	ff3716e3          	bne	a4,s3,80003ad2 <iget+0x38>
    80003aea:	40d8                	lw	a4,4(s1)
    80003aec:	ff4713e3          	bne	a4,s4,80003ad2 <iget+0x38>
      ip->ref++;
    80003af0:	2785                	addiw	a5,a5,1
    80003af2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003af4:	0003b517          	auipc	a0,0x3b
    80003af8:	73450513          	addi	a0,a0,1844 # 8003f228 <itable>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	31a080e7          	jalr	794(ra) # 80000e16 <release>
      return ip;
    80003b04:	8926                	mv	s2,s1
    80003b06:	a03d                	j	80003b34 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b08:	f7f9                	bnez	a5,80003ad6 <iget+0x3c>
    80003b0a:	8926                	mv	s2,s1
    80003b0c:	b7e9                	j	80003ad6 <iget+0x3c>
  if(empty == 0)
    80003b0e:	02090c63          	beqz	s2,80003b46 <iget+0xac>
  ip->dev = dev;
    80003b12:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b16:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b1a:	4785                	li	a5,1
    80003b1c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b20:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b24:	0003b517          	auipc	a0,0x3b
    80003b28:	70450513          	addi	a0,a0,1796 # 8003f228 <itable>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	2ea080e7          	jalr	746(ra) # 80000e16 <release>
}
    80003b34:	854a                	mv	a0,s2
    80003b36:	70a2                	ld	ra,40(sp)
    80003b38:	7402                	ld	s0,32(sp)
    80003b3a:	64e2                	ld	s1,24(sp)
    80003b3c:	6942                	ld	s2,16(sp)
    80003b3e:	69a2                	ld	s3,8(sp)
    80003b40:	6a02                	ld	s4,0(sp)
    80003b42:	6145                	addi	sp,sp,48
    80003b44:	8082                	ret
    panic("iget: no inodes");
    80003b46:	00005517          	auipc	a0,0x5
    80003b4a:	ba250513          	addi	a0,a0,-1118 # 800086e8 <syscalls+0x158>
    80003b4e:	ffffd097          	auipc	ra,0xffffd
    80003b52:	9f2080e7          	jalr	-1550(ra) # 80000540 <panic>

0000000080003b56 <fsinit>:
fsinit(int dev) {
    80003b56:	7179                	addi	sp,sp,-48
    80003b58:	f406                	sd	ra,40(sp)
    80003b5a:	f022                	sd	s0,32(sp)
    80003b5c:	ec26                	sd	s1,24(sp)
    80003b5e:	e84a                	sd	s2,16(sp)
    80003b60:	e44e                	sd	s3,8(sp)
    80003b62:	1800                	addi	s0,sp,48
    80003b64:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b66:	4585                	li	a1,1
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	a54080e7          	jalr	-1452(ra) # 800035bc <bread>
    80003b70:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b72:	0003b997          	auipc	s3,0x3b
    80003b76:	69698993          	addi	s3,s3,1686 # 8003f208 <sb>
    80003b7a:	02000613          	li	a2,32
    80003b7e:	05850593          	addi	a1,a0,88
    80003b82:	854e                	mv	a0,s3
    80003b84:	ffffd097          	auipc	ra,0xffffd
    80003b88:	336080e7          	jalr	822(ra) # 80000eba <memmove>
  brelse(bp);
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	b5e080e7          	jalr	-1186(ra) # 800036ec <brelse>
  if(sb.magic != FSMAGIC)
    80003b96:	0009a703          	lw	a4,0(s3)
    80003b9a:	102037b7          	lui	a5,0x10203
    80003b9e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ba2:	02f71263          	bne	a4,a5,80003bc6 <fsinit+0x70>
  initlog(dev, &sb);
    80003ba6:	0003b597          	auipc	a1,0x3b
    80003baa:	66258593          	addi	a1,a1,1634 # 8003f208 <sb>
    80003bae:	854a                	mv	a0,s2
    80003bb0:	00001097          	auipc	ra,0x1
    80003bb4:	b4a080e7          	jalr	-1206(ra) # 800046fa <initlog>
}
    80003bb8:	70a2                	ld	ra,40(sp)
    80003bba:	7402                	ld	s0,32(sp)
    80003bbc:	64e2                	ld	s1,24(sp)
    80003bbe:	6942                	ld	s2,16(sp)
    80003bc0:	69a2                	ld	s3,8(sp)
    80003bc2:	6145                	addi	sp,sp,48
    80003bc4:	8082                	ret
    panic("invalid file system");
    80003bc6:	00005517          	auipc	a0,0x5
    80003bca:	b3250513          	addi	a0,a0,-1230 # 800086f8 <syscalls+0x168>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	972080e7          	jalr	-1678(ra) # 80000540 <panic>

0000000080003bd6 <iinit>:
{
    80003bd6:	7179                	addi	sp,sp,-48
    80003bd8:	f406                	sd	ra,40(sp)
    80003bda:	f022                	sd	s0,32(sp)
    80003bdc:	ec26                	sd	s1,24(sp)
    80003bde:	e84a                	sd	s2,16(sp)
    80003be0:	e44e                	sd	s3,8(sp)
    80003be2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003be4:	00005597          	auipc	a1,0x5
    80003be8:	b2c58593          	addi	a1,a1,-1236 # 80008710 <syscalls+0x180>
    80003bec:	0003b517          	auipc	a0,0x3b
    80003bf0:	63c50513          	addi	a0,a0,1596 # 8003f228 <itable>
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	0de080e7          	jalr	222(ra) # 80000cd2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bfc:	0003b497          	auipc	s1,0x3b
    80003c00:	65448493          	addi	s1,s1,1620 # 8003f250 <itable+0x28>
    80003c04:	0003d997          	auipc	s3,0x3d
    80003c08:	0dc98993          	addi	s3,s3,220 # 80040ce0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c0c:	00005917          	auipc	s2,0x5
    80003c10:	b0c90913          	addi	s2,s2,-1268 # 80008718 <syscalls+0x188>
    80003c14:	85ca                	mv	a1,s2
    80003c16:	8526                	mv	a0,s1
    80003c18:	00001097          	auipc	ra,0x1
    80003c1c:	e42080e7          	jalr	-446(ra) # 80004a5a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c20:	08848493          	addi	s1,s1,136
    80003c24:	ff3498e3          	bne	s1,s3,80003c14 <iinit+0x3e>
}
    80003c28:	70a2                	ld	ra,40(sp)
    80003c2a:	7402                	ld	s0,32(sp)
    80003c2c:	64e2                	ld	s1,24(sp)
    80003c2e:	6942                	ld	s2,16(sp)
    80003c30:	69a2                	ld	s3,8(sp)
    80003c32:	6145                	addi	sp,sp,48
    80003c34:	8082                	ret

0000000080003c36 <ialloc>:
{
    80003c36:	715d                	addi	sp,sp,-80
    80003c38:	e486                	sd	ra,72(sp)
    80003c3a:	e0a2                	sd	s0,64(sp)
    80003c3c:	fc26                	sd	s1,56(sp)
    80003c3e:	f84a                	sd	s2,48(sp)
    80003c40:	f44e                	sd	s3,40(sp)
    80003c42:	f052                	sd	s4,32(sp)
    80003c44:	ec56                	sd	s5,24(sp)
    80003c46:	e85a                	sd	s6,16(sp)
    80003c48:	e45e                	sd	s7,8(sp)
    80003c4a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c4c:	0003b717          	auipc	a4,0x3b
    80003c50:	5c872703          	lw	a4,1480(a4) # 8003f214 <sb+0xc>
    80003c54:	4785                	li	a5,1
    80003c56:	04e7fa63          	bgeu	a5,a4,80003caa <ialloc+0x74>
    80003c5a:	8aaa                	mv	s5,a0
    80003c5c:	8bae                	mv	s7,a1
    80003c5e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c60:	0003ba17          	auipc	s4,0x3b
    80003c64:	5a8a0a13          	addi	s4,s4,1448 # 8003f208 <sb>
    80003c68:	00048b1b          	sext.w	s6,s1
    80003c6c:	0044d593          	srli	a1,s1,0x4
    80003c70:	018a2783          	lw	a5,24(s4)
    80003c74:	9dbd                	addw	a1,a1,a5
    80003c76:	8556                	mv	a0,s5
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	944080e7          	jalr	-1724(ra) # 800035bc <bread>
    80003c80:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c82:	05850993          	addi	s3,a0,88
    80003c86:	00f4f793          	andi	a5,s1,15
    80003c8a:	079a                	slli	a5,a5,0x6
    80003c8c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c8e:	00099783          	lh	a5,0(s3)
    80003c92:	c3a1                	beqz	a5,80003cd2 <ialloc+0x9c>
    brelse(bp);
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	a58080e7          	jalr	-1448(ra) # 800036ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c9c:	0485                	addi	s1,s1,1
    80003c9e:	00ca2703          	lw	a4,12(s4)
    80003ca2:	0004879b          	sext.w	a5,s1
    80003ca6:	fce7e1e3          	bltu	a5,a4,80003c68 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003caa:	00005517          	auipc	a0,0x5
    80003cae:	a7650513          	addi	a0,a0,-1418 # 80008720 <syscalls+0x190>
    80003cb2:	ffffd097          	auipc	ra,0xffffd
    80003cb6:	8ea080e7          	jalr	-1814(ra) # 8000059c <printf>
  return 0;
    80003cba:	4501                	li	a0,0
}
    80003cbc:	60a6                	ld	ra,72(sp)
    80003cbe:	6406                	ld	s0,64(sp)
    80003cc0:	74e2                	ld	s1,56(sp)
    80003cc2:	7942                	ld	s2,48(sp)
    80003cc4:	79a2                	ld	s3,40(sp)
    80003cc6:	7a02                	ld	s4,32(sp)
    80003cc8:	6ae2                	ld	s5,24(sp)
    80003cca:	6b42                	ld	s6,16(sp)
    80003ccc:	6ba2                	ld	s7,8(sp)
    80003cce:	6161                	addi	sp,sp,80
    80003cd0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003cd2:	04000613          	li	a2,64
    80003cd6:	4581                	li	a1,0
    80003cd8:	854e                	mv	a0,s3
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	184080e7          	jalr	388(ra) # 80000e5e <memset>
      dip->type = type;
    80003ce2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00001097          	auipc	ra,0x1
    80003cec:	c8e080e7          	jalr	-882(ra) # 80004976 <log_write>
      brelse(bp);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	9fa080e7          	jalr	-1542(ra) # 800036ec <brelse>
      return iget(dev, inum);
    80003cfa:	85da                	mv	a1,s6
    80003cfc:	8556                	mv	a0,s5
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	d9c080e7          	jalr	-612(ra) # 80003a9a <iget>
    80003d06:	bf5d                	j	80003cbc <ialloc+0x86>

0000000080003d08 <iupdate>:
{
    80003d08:	1101                	addi	sp,sp,-32
    80003d0a:	ec06                	sd	ra,24(sp)
    80003d0c:	e822                	sd	s0,16(sp)
    80003d0e:	e426                	sd	s1,8(sp)
    80003d10:	e04a                	sd	s2,0(sp)
    80003d12:	1000                	addi	s0,sp,32
    80003d14:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d16:	415c                	lw	a5,4(a0)
    80003d18:	0047d79b          	srliw	a5,a5,0x4
    80003d1c:	0003b597          	auipc	a1,0x3b
    80003d20:	5045a583          	lw	a1,1284(a1) # 8003f220 <sb+0x18>
    80003d24:	9dbd                	addw	a1,a1,a5
    80003d26:	4108                	lw	a0,0(a0)
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	894080e7          	jalr	-1900(ra) # 800035bc <bread>
    80003d30:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d32:	05850793          	addi	a5,a0,88
    80003d36:	40d8                	lw	a4,4(s1)
    80003d38:	8b3d                	andi	a4,a4,15
    80003d3a:	071a                	slli	a4,a4,0x6
    80003d3c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003d3e:	04449703          	lh	a4,68(s1)
    80003d42:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003d46:	04649703          	lh	a4,70(s1)
    80003d4a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003d4e:	04849703          	lh	a4,72(s1)
    80003d52:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003d56:	04a49703          	lh	a4,74(s1)
    80003d5a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d5e:	44f8                	lw	a4,76(s1)
    80003d60:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d62:	03400613          	li	a2,52
    80003d66:	05048593          	addi	a1,s1,80
    80003d6a:	00c78513          	addi	a0,a5,12
    80003d6e:	ffffd097          	auipc	ra,0xffffd
    80003d72:	14c080e7          	jalr	332(ra) # 80000eba <memmove>
  log_write(bp);
    80003d76:	854a                	mv	a0,s2
    80003d78:	00001097          	auipc	ra,0x1
    80003d7c:	bfe080e7          	jalr	-1026(ra) # 80004976 <log_write>
  brelse(bp);
    80003d80:	854a                	mv	a0,s2
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	96a080e7          	jalr	-1686(ra) # 800036ec <brelse>
}
    80003d8a:	60e2                	ld	ra,24(sp)
    80003d8c:	6442                	ld	s0,16(sp)
    80003d8e:	64a2                	ld	s1,8(sp)
    80003d90:	6902                	ld	s2,0(sp)
    80003d92:	6105                	addi	sp,sp,32
    80003d94:	8082                	ret

0000000080003d96 <idup>:
{
    80003d96:	1101                	addi	sp,sp,-32
    80003d98:	ec06                	sd	ra,24(sp)
    80003d9a:	e822                	sd	s0,16(sp)
    80003d9c:	e426                	sd	s1,8(sp)
    80003d9e:	1000                	addi	s0,sp,32
    80003da0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003da2:	0003b517          	auipc	a0,0x3b
    80003da6:	48650513          	addi	a0,a0,1158 # 8003f228 <itable>
    80003daa:	ffffd097          	auipc	ra,0xffffd
    80003dae:	fb8080e7          	jalr	-72(ra) # 80000d62 <acquire>
  ip->ref++;
    80003db2:	449c                	lw	a5,8(s1)
    80003db4:	2785                	addiw	a5,a5,1
    80003db6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003db8:	0003b517          	auipc	a0,0x3b
    80003dbc:	47050513          	addi	a0,a0,1136 # 8003f228 <itable>
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	056080e7          	jalr	86(ra) # 80000e16 <release>
}
    80003dc8:	8526                	mv	a0,s1
    80003dca:	60e2                	ld	ra,24(sp)
    80003dcc:	6442                	ld	s0,16(sp)
    80003dce:	64a2                	ld	s1,8(sp)
    80003dd0:	6105                	addi	sp,sp,32
    80003dd2:	8082                	ret

0000000080003dd4 <ilock>:
{
    80003dd4:	1101                	addi	sp,sp,-32
    80003dd6:	ec06                	sd	ra,24(sp)
    80003dd8:	e822                	sd	s0,16(sp)
    80003dda:	e426                	sd	s1,8(sp)
    80003ddc:	e04a                	sd	s2,0(sp)
    80003dde:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003de0:	c115                	beqz	a0,80003e04 <ilock+0x30>
    80003de2:	84aa                	mv	s1,a0
    80003de4:	451c                	lw	a5,8(a0)
    80003de6:	00f05f63          	blez	a5,80003e04 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dea:	0541                	addi	a0,a0,16
    80003dec:	00001097          	auipc	ra,0x1
    80003df0:	ca8080e7          	jalr	-856(ra) # 80004a94 <acquiresleep>
  if(ip->valid == 0){
    80003df4:	40bc                	lw	a5,64(s1)
    80003df6:	cf99                	beqz	a5,80003e14 <ilock+0x40>
}
    80003df8:	60e2                	ld	ra,24(sp)
    80003dfa:	6442                	ld	s0,16(sp)
    80003dfc:	64a2                	ld	s1,8(sp)
    80003dfe:	6902                	ld	s2,0(sp)
    80003e00:	6105                	addi	sp,sp,32
    80003e02:	8082                	ret
    panic("ilock");
    80003e04:	00005517          	auipc	a0,0x5
    80003e08:	93450513          	addi	a0,a0,-1740 # 80008738 <syscalls+0x1a8>
    80003e0c:	ffffc097          	auipc	ra,0xffffc
    80003e10:	734080e7          	jalr	1844(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e14:	40dc                	lw	a5,4(s1)
    80003e16:	0047d79b          	srliw	a5,a5,0x4
    80003e1a:	0003b597          	auipc	a1,0x3b
    80003e1e:	4065a583          	lw	a1,1030(a1) # 8003f220 <sb+0x18>
    80003e22:	9dbd                	addw	a1,a1,a5
    80003e24:	4088                	lw	a0,0(s1)
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	796080e7          	jalr	1942(ra) # 800035bc <bread>
    80003e2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e30:	05850593          	addi	a1,a0,88
    80003e34:	40dc                	lw	a5,4(s1)
    80003e36:	8bbd                	andi	a5,a5,15
    80003e38:	079a                	slli	a5,a5,0x6
    80003e3a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e3c:	00059783          	lh	a5,0(a1)
    80003e40:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e44:	00259783          	lh	a5,2(a1)
    80003e48:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e4c:	00459783          	lh	a5,4(a1)
    80003e50:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e54:	00659783          	lh	a5,6(a1)
    80003e58:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e5c:	459c                	lw	a5,8(a1)
    80003e5e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e60:	03400613          	li	a2,52
    80003e64:	05b1                	addi	a1,a1,12
    80003e66:	05048513          	addi	a0,s1,80
    80003e6a:	ffffd097          	auipc	ra,0xffffd
    80003e6e:	050080e7          	jalr	80(ra) # 80000eba <memmove>
    brelse(bp);
    80003e72:	854a                	mv	a0,s2
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	878080e7          	jalr	-1928(ra) # 800036ec <brelse>
    ip->valid = 1;
    80003e7c:	4785                	li	a5,1
    80003e7e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e80:	04449783          	lh	a5,68(s1)
    80003e84:	fbb5                	bnez	a5,80003df8 <ilock+0x24>
      panic("ilock: no type");
    80003e86:	00005517          	auipc	a0,0x5
    80003e8a:	8ba50513          	addi	a0,a0,-1862 # 80008740 <syscalls+0x1b0>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	6b2080e7          	jalr	1714(ra) # 80000540 <panic>

0000000080003e96 <iunlock>:
{
    80003e96:	1101                	addi	sp,sp,-32
    80003e98:	ec06                	sd	ra,24(sp)
    80003e9a:	e822                	sd	s0,16(sp)
    80003e9c:	e426                	sd	s1,8(sp)
    80003e9e:	e04a                	sd	s2,0(sp)
    80003ea0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ea2:	c905                	beqz	a0,80003ed2 <iunlock+0x3c>
    80003ea4:	84aa                	mv	s1,a0
    80003ea6:	01050913          	addi	s2,a0,16
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00001097          	auipc	ra,0x1
    80003eb0:	c82080e7          	jalr	-894(ra) # 80004b2e <holdingsleep>
    80003eb4:	cd19                	beqz	a0,80003ed2 <iunlock+0x3c>
    80003eb6:	449c                	lw	a5,8(s1)
    80003eb8:	00f05d63          	blez	a5,80003ed2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00001097          	auipc	ra,0x1
    80003ec2:	c2c080e7          	jalr	-980(ra) # 80004aea <releasesleep>
}
    80003ec6:	60e2                	ld	ra,24(sp)
    80003ec8:	6442                	ld	s0,16(sp)
    80003eca:	64a2                	ld	s1,8(sp)
    80003ecc:	6902                	ld	s2,0(sp)
    80003ece:	6105                	addi	sp,sp,32
    80003ed0:	8082                	ret
    panic("iunlock");
    80003ed2:	00005517          	auipc	a0,0x5
    80003ed6:	87e50513          	addi	a0,a0,-1922 # 80008750 <syscalls+0x1c0>
    80003eda:	ffffc097          	auipc	ra,0xffffc
    80003ede:	666080e7          	jalr	1638(ra) # 80000540 <panic>

0000000080003ee2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ee2:	7179                	addi	sp,sp,-48
    80003ee4:	f406                	sd	ra,40(sp)
    80003ee6:	f022                	sd	s0,32(sp)
    80003ee8:	ec26                	sd	s1,24(sp)
    80003eea:	e84a                	sd	s2,16(sp)
    80003eec:	e44e                	sd	s3,8(sp)
    80003eee:	e052                	sd	s4,0(sp)
    80003ef0:	1800                	addi	s0,sp,48
    80003ef2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ef4:	05050493          	addi	s1,a0,80
    80003ef8:	08050913          	addi	s2,a0,128
    80003efc:	a021                	j	80003f04 <itrunc+0x22>
    80003efe:	0491                	addi	s1,s1,4
    80003f00:	01248d63          	beq	s1,s2,80003f1a <itrunc+0x38>
    if(ip->addrs[i]){
    80003f04:	408c                	lw	a1,0(s1)
    80003f06:	dde5                	beqz	a1,80003efe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f08:	0009a503          	lw	a0,0(s3)
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	8f6080e7          	jalr	-1802(ra) # 80003802 <bfree>
      ip->addrs[i] = 0;
    80003f14:	0004a023          	sw	zero,0(s1)
    80003f18:	b7dd                	j	80003efe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f1a:	0809a583          	lw	a1,128(s3)
    80003f1e:	e185                	bnez	a1,80003f3e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f20:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f24:	854e                	mv	a0,s3
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	de2080e7          	jalr	-542(ra) # 80003d08 <iupdate>
}
    80003f2e:	70a2                	ld	ra,40(sp)
    80003f30:	7402                	ld	s0,32(sp)
    80003f32:	64e2                	ld	s1,24(sp)
    80003f34:	6942                	ld	s2,16(sp)
    80003f36:	69a2                	ld	s3,8(sp)
    80003f38:	6a02                	ld	s4,0(sp)
    80003f3a:	6145                	addi	sp,sp,48
    80003f3c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f3e:	0009a503          	lw	a0,0(s3)
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	67a080e7          	jalr	1658(ra) # 800035bc <bread>
    80003f4a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f4c:	05850493          	addi	s1,a0,88
    80003f50:	45850913          	addi	s2,a0,1112
    80003f54:	a021                	j	80003f5c <itrunc+0x7a>
    80003f56:	0491                	addi	s1,s1,4
    80003f58:	01248b63          	beq	s1,s2,80003f6e <itrunc+0x8c>
      if(a[j])
    80003f5c:	408c                	lw	a1,0(s1)
    80003f5e:	dde5                	beqz	a1,80003f56 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f60:	0009a503          	lw	a0,0(s3)
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	89e080e7          	jalr	-1890(ra) # 80003802 <bfree>
    80003f6c:	b7ed                	j	80003f56 <itrunc+0x74>
    brelse(bp);
    80003f6e:	8552                	mv	a0,s4
    80003f70:	fffff097          	auipc	ra,0xfffff
    80003f74:	77c080e7          	jalr	1916(ra) # 800036ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f78:	0809a583          	lw	a1,128(s3)
    80003f7c:	0009a503          	lw	a0,0(s3)
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	882080e7          	jalr	-1918(ra) # 80003802 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f88:	0809a023          	sw	zero,128(s3)
    80003f8c:	bf51                	j	80003f20 <itrunc+0x3e>

0000000080003f8e <iput>:
{
    80003f8e:	1101                	addi	sp,sp,-32
    80003f90:	ec06                	sd	ra,24(sp)
    80003f92:	e822                	sd	s0,16(sp)
    80003f94:	e426                	sd	s1,8(sp)
    80003f96:	e04a                	sd	s2,0(sp)
    80003f98:	1000                	addi	s0,sp,32
    80003f9a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f9c:	0003b517          	auipc	a0,0x3b
    80003fa0:	28c50513          	addi	a0,a0,652 # 8003f228 <itable>
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	dbe080e7          	jalr	-578(ra) # 80000d62 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fac:	4498                	lw	a4,8(s1)
    80003fae:	4785                	li	a5,1
    80003fb0:	02f70363          	beq	a4,a5,80003fd6 <iput+0x48>
  ip->ref--;
    80003fb4:	449c                	lw	a5,8(s1)
    80003fb6:	37fd                	addiw	a5,a5,-1
    80003fb8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fba:	0003b517          	auipc	a0,0x3b
    80003fbe:	26e50513          	addi	a0,a0,622 # 8003f228 <itable>
    80003fc2:	ffffd097          	auipc	ra,0xffffd
    80003fc6:	e54080e7          	jalr	-428(ra) # 80000e16 <release>
}
    80003fca:	60e2                	ld	ra,24(sp)
    80003fcc:	6442                	ld	s0,16(sp)
    80003fce:	64a2                	ld	s1,8(sp)
    80003fd0:	6902                	ld	s2,0(sp)
    80003fd2:	6105                	addi	sp,sp,32
    80003fd4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fd6:	40bc                	lw	a5,64(s1)
    80003fd8:	dff1                	beqz	a5,80003fb4 <iput+0x26>
    80003fda:	04a49783          	lh	a5,74(s1)
    80003fde:	fbf9                	bnez	a5,80003fb4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003fe0:	01048913          	addi	s2,s1,16
    80003fe4:	854a                	mv	a0,s2
    80003fe6:	00001097          	auipc	ra,0x1
    80003fea:	aae080e7          	jalr	-1362(ra) # 80004a94 <acquiresleep>
    release(&itable.lock);
    80003fee:	0003b517          	auipc	a0,0x3b
    80003ff2:	23a50513          	addi	a0,a0,570 # 8003f228 <itable>
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	e20080e7          	jalr	-480(ra) # 80000e16 <release>
    itrunc(ip);
    80003ffe:	8526                	mv	a0,s1
    80004000:	00000097          	auipc	ra,0x0
    80004004:	ee2080e7          	jalr	-286(ra) # 80003ee2 <itrunc>
    ip->type = 0;
    80004008:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000400c:	8526                	mv	a0,s1
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	cfa080e7          	jalr	-774(ra) # 80003d08 <iupdate>
    ip->valid = 0;
    80004016:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000401a:	854a                	mv	a0,s2
    8000401c:	00001097          	auipc	ra,0x1
    80004020:	ace080e7          	jalr	-1330(ra) # 80004aea <releasesleep>
    acquire(&itable.lock);
    80004024:	0003b517          	auipc	a0,0x3b
    80004028:	20450513          	addi	a0,a0,516 # 8003f228 <itable>
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	d36080e7          	jalr	-714(ra) # 80000d62 <acquire>
    80004034:	b741                	j	80003fb4 <iput+0x26>

0000000080004036 <iunlockput>:
{
    80004036:	1101                	addi	sp,sp,-32
    80004038:	ec06                	sd	ra,24(sp)
    8000403a:	e822                	sd	s0,16(sp)
    8000403c:	e426                	sd	s1,8(sp)
    8000403e:	1000                	addi	s0,sp,32
    80004040:	84aa                	mv	s1,a0
  iunlock(ip);
    80004042:	00000097          	auipc	ra,0x0
    80004046:	e54080e7          	jalr	-428(ra) # 80003e96 <iunlock>
  iput(ip);
    8000404a:	8526                	mv	a0,s1
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	f42080e7          	jalr	-190(ra) # 80003f8e <iput>
}
    80004054:	60e2                	ld	ra,24(sp)
    80004056:	6442                	ld	s0,16(sp)
    80004058:	64a2                	ld	s1,8(sp)
    8000405a:	6105                	addi	sp,sp,32
    8000405c:	8082                	ret

000000008000405e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000405e:	1141                	addi	sp,sp,-16
    80004060:	e422                	sd	s0,8(sp)
    80004062:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004064:	411c                	lw	a5,0(a0)
    80004066:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004068:	415c                	lw	a5,4(a0)
    8000406a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000406c:	04451783          	lh	a5,68(a0)
    80004070:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004074:	04a51783          	lh	a5,74(a0)
    80004078:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000407c:	04c56783          	lwu	a5,76(a0)
    80004080:	e99c                	sd	a5,16(a1)
}
    80004082:	6422                	ld	s0,8(sp)
    80004084:	0141                	addi	sp,sp,16
    80004086:	8082                	ret

0000000080004088 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004088:	457c                	lw	a5,76(a0)
    8000408a:	0ed7e963          	bltu	a5,a3,8000417c <readi+0xf4>
{
    8000408e:	7159                	addi	sp,sp,-112
    80004090:	f486                	sd	ra,104(sp)
    80004092:	f0a2                	sd	s0,96(sp)
    80004094:	eca6                	sd	s1,88(sp)
    80004096:	e8ca                	sd	s2,80(sp)
    80004098:	e4ce                	sd	s3,72(sp)
    8000409a:	e0d2                	sd	s4,64(sp)
    8000409c:	fc56                	sd	s5,56(sp)
    8000409e:	f85a                	sd	s6,48(sp)
    800040a0:	f45e                	sd	s7,40(sp)
    800040a2:	f062                	sd	s8,32(sp)
    800040a4:	ec66                	sd	s9,24(sp)
    800040a6:	e86a                	sd	s10,16(sp)
    800040a8:	e46e                	sd	s11,8(sp)
    800040aa:	1880                	addi	s0,sp,112
    800040ac:	8b2a                	mv	s6,a0
    800040ae:	8bae                	mv	s7,a1
    800040b0:	8a32                	mv	s4,a2
    800040b2:	84b6                	mv	s1,a3
    800040b4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800040b6:	9f35                	addw	a4,a4,a3
    return 0;
    800040b8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040ba:	0ad76063          	bltu	a4,a3,8000415a <readi+0xd2>
  if(off + n > ip->size)
    800040be:	00e7f463          	bgeu	a5,a4,800040c6 <readi+0x3e>
    n = ip->size - off;
    800040c2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040c6:	0a0a8963          	beqz	s5,80004178 <readi+0xf0>
    800040ca:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040cc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040d0:	5c7d                	li	s8,-1
    800040d2:	a82d                	j	8000410c <readi+0x84>
    800040d4:	020d1d93          	slli	s11,s10,0x20
    800040d8:	020ddd93          	srli	s11,s11,0x20
    800040dc:	05890613          	addi	a2,s2,88
    800040e0:	86ee                	mv	a3,s11
    800040e2:	963a                	add	a2,a2,a4
    800040e4:	85d2                	mv	a1,s4
    800040e6:	855e                	mv	a0,s7
    800040e8:	ffffe097          	auipc	ra,0xffffe
    800040ec:	7e2080e7          	jalr	2018(ra) # 800028ca <either_copyout>
    800040f0:	05850d63          	beq	a0,s8,8000414a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040f4:	854a                	mv	a0,s2
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	5f6080e7          	jalr	1526(ra) # 800036ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040fe:	013d09bb          	addw	s3,s10,s3
    80004102:	009d04bb          	addw	s1,s10,s1
    80004106:	9a6e                	add	s4,s4,s11
    80004108:	0559f763          	bgeu	s3,s5,80004156 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000410c:	00a4d59b          	srliw	a1,s1,0xa
    80004110:	855a                	mv	a0,s6
    80004112:	00000097          	auipc	ra,0x0
    80004116:	89e080e7          	jalr	-1890(ra) # 800039b0 <bmap>
    8000411a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000411e:	cd85                	beqz	a1,80004156 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004120:	000b2503          	lw	a0,0(s6)
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	498080e7          	jalr	1176(ra) # 800035bc <bread>
    8000412c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000412e:	3ff4f713          	andi	a4,s1,1023
    80004132:	40ec87bb          	subw	a5,s9,a4
    80004136:	413a86bb          	subw	a3,s5,s3
    8000413a:	8d3e                	mv	s10,a5
    8000413c:	2781                	sext.w	a5,a5
    8000413e:	0006861b          	sext.w	a2,a3
    80004142:	f8f679e3          	bgeu	a2,a5,800040d4 <readi+0x4c>
    80004146:	8d36                	mv	s10,a3
    80004148:	b771                	j	800040d4 <readi+0x4c>
      brelse(bp);
    8000414a:	854a                	mv	a0,s2
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	5a0080e7          	jalr	1440(ra) # 800036ec <brelse>
      tot = -1;
    80004154:	59fd                	li	s3,-1
  }
  return tot;
    80004156:	0009851b          	sext.w	a0,s3
}
    8000415a:	70a6                	ld	ra,104(sp)
    8000415c:	7406                	ld	s0,96(sp)
    8000415e:	64e6                	ld	s1,88(sp)
    80004160:	6946                	ld	s2,80(sp)
    80004162:	69a6                	ld	s3,72(sp)
    80004164:	6a06                	ld	s4,64(sp)
    80004166:	7ae2                	ld	s5,56(sp)
    80004168:	7b42                	ld	s6,48(sp)
    8000416a:	7ba2                	ld	s7,40(sp)
    8000416c:	7c02                	ld	s8,32(sp)
    8000416e:	6ce2                	ld	s9,24(sp)
    80004170:	6d42                	ld	s10,16(sp)
    80004172:	6da2                	ld	s11,8(sp)
    80004174:	6165                	addi	sp,sp,112
    80004176:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004178:	89d6                	mv	s3,s5
    8000417a:	bff1                	j	80004156 <readi+0xce>
    return 0;
    8000417c:	4501                	li	a0,0
}
    8000417e:	8082                	ret

0000000080004180 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004180:	457c                	lw	a5,76(a0)
    80004182:	10d7e863          	bltu	a5,a3,80004292 <writei+0x112>
{
    80004186:	7159                	addi	sp,sp,-112
    80004188:	f486                	sd	ra,104(sp)
    8000418a:	f0a2                	sd	s0,96(sp)
    8000418c:	eca6                	sd	s1,88(sp)
    8000418e:	e8ca                	sd	s2,80(sp)
    80004190:	e4ce                	sd	s3,72(sp)
    80004192:	e0d2                	sd	s4,64(sp)
    80004194:	fc56                	sd	s5,56(sp)
    80004196:	f85a                	sd	s6,48(sp)
    80004198:	f45e                	sd	s7,40(sp)
    8000419a:	f062                	sd	s8,32(sp)
    8000419c:	ec66                	sd	s9,24(sp)
    8000419e:	e86a                	sd	s10,16(sp)
    800041a0:	e46e                	sd	s11,8(sp)
    800041a2:	1880                	addi	s0,sp,112
    800041a4:	8aaa                	mv	s5,a0
    800041a6:	8bae                	mv	s7,a1
    800041a8:	8a32                	mv	s4,a2
    800041aa:	8936                	mv	s2,a3
    800041ac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041ae:	00e687bb          	addw	a5,a3,a4
    800041b2:	0ed7e263          	bltu	a5,a3,80004296 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041b6:	00043737          	lui	a4,0x43
    800041ba:	0ef76063          	bltu	a4,a5,8000429a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041be:	0c0b0863          	beqz	s6,8000428e <writei+0x10e>
    800041c2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041c4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041c8:	5c7d                	li	s8,-1
    800041ca:	a091                	j	8000420e <writei+0x8e>
    800041cc:	020d1d93          	slli	s11,s10,0x20
    800041d0:	020ddd93          	srli	s11,s11,0x20
    800041d4:	05848513          	addi	a0,s1,88
    800041d8:	86ee                	mv	a3,s11
    800041da:	8652                	mv	a2,s4
    800041dc:	85de                	mv	a1,s7
    800041de:	953a                	add	a0,a0,a4
    800041e0:	ffffe097          	auipc	ra,0xffffe
    800041e4:	740080e7          	jalr	1856(ra) # 80002920 <either_copyin>
    800041e8:	07850263          	beq	a0,s8,8000424c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041ec:	8526                	mv	a0,s1
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	788080e7          	jalr	1928(ra) # 80004976 <log_write>
    brelse(bp);
    800041f6:	8526                	mv	a0,s1
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	4f4080e7          	jalr	1268(ra) # 800036ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004200:	013d09bb          	addw	s3,s10,s3
    80004204:	012d093b          	addw	s2,s10,s2
    80004208:	9a6e                	add	s4,s4,s11
    8000420a:	0569f663          	bgeu	s3,s6,80004256 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000420e:	00a9559b          	srliw	a1,s2,0xa
    80004212:	8556                	mv	a0,s5
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	79c080e7          	jalr	1948(ra) # 800039b0 <bmap>
    8000421c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004220:	c99d                	beqz	a1,80004256 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004222:	000aa503          	lw	a0,0(s5)
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	396080e7          	jalr	918(ra) # 800035bc <bread>
    8000422e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004230:	3ff97713          	andi	a4,s2,1023
    80004234:	40ec87bb          	subw	a5,s9,a4
    80004238:	413b06bb          	subw	a3,s6,s3
    8000423c:	8d3e                	mv	s10,a5
    8000423e:	2781                	sext.w	a5,a5
    80004240:	0006861b          	sext.w	a2,a3
    80004244:	f8f674e3          	bgeu	a2,a5,800041cc <writei+0x4c>
    80004248:	8d36                	mv	s10,a3
    8000424a:	b749                	j	800041cc <writei+0x4c>
      brelse(bp);
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	49e080e7          	jalr	1182(ra) # 800036ec <brelse>
  }

  if(off > ip->size)
    80004256:	04caa783          	lw	a5,76(s5)
    8000425a:	0127f463          	bgeu	a5,s2,80004262 <writei+0xe2>
    ip->size = off;
    8000425e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004262:	8556                	mv	a0,s5
    80004264:	00000097          	auipc	ra,0x0
    80004268:	aa4080e7          	jalr	-1372(ra) # 80003d08 <iupdate>

  return tot;
    8000426c:	0009851b          	sext.w	a0,s3
}
    80004270:	70a6                	ld	ra,104(sp)
    80004272:	7406                	ld	s0,96(sp)
    80004274:	64e6                	ld	s1,88(sp)
    80004276:	6946                	ld	s2,80(sp)
    80004278:	69a6                	ld	s3,72(sp)
    8000427a:	6a06                	ld	s4,64(sp)
    8000427c:	7ae2                	ld	s5,56(sp)
    8000427e:	7b42                	ld	s6,48(sp)
    80004280:	7ba2                	ld	s7,40(sp)
    80004282:	7c02                	ld	s8,32(sp)
    80004284:	6ce2                	ld	s9,24(sp)
    80004286:	6d42                	ld	s10,16(sp)
    80004288:	6da2                	ld	s11,8(sp)
    8000428a:	6165                	addi	sp,sp,112
    8000428c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000428e:	89da                	mv	s3,s6
    80004290:	bfc9                	j	80004262 <writei+0xe2>
    return -1;
    80004292:	557d                	li	a0,-1
}
    80004294:	8082                	ret
    return -1;
    80004296:	557d                	li	a0,-1
    80004298:	bfe1                	j	80004270 <writei+0xf0>
    return -1;
    8000429a:	557d                	li	a0,-1
    8000429c:	bfd1                	j	80004270 <writei+0xf0>

000000008000429e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000429e:	1141                	addi	sp,sp,-16
    800042a0:	e406                	sd	ra,8(sp)
    800042a2:	e022                	sd	s0,0(sp)
    800042a4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042a6:	4639                	li	a2,14
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	c86080e7          	jalr	-890(ra) # 80000f2e <strncmp>
}
    800042b0:	60a2                	ld	ra,8(sp)
    800042b2:	6402                	ld	s0,0(sp)
    800042b4:	0141                	addi	sp,sp,16
    800042b6:	8082                	ret

00000000800042b8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042b8:	7139                	addi	sp,sp,-64
    800042ba:	fc06                	sd	ra,56(sp)
    800042bc:	f822                	sd	s0,48(sp)
    800042be:	f426                	sd	s1,40(sp)
    800042c0:	f04a                	sd	s2,32(sp)
    800042c2:	ec4e                	sd	s3,24(sp)
    800042c4:	e852                	sd	s4,16(sp)
    800042c6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042c8:	04451703          	lh	a4,68(a0)
    800042cc:	4785                	li	a5,1
    800042ce:	00f71a63          	bne	a4,a5,800042e2 <dirlookup+0x2a>
    800042d2:	892a                	mv	s2,a0
    800042d4:	89ae                	mv	s3,a1
    800042d6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d8:	457c                	lw	a5,76(a0)
    800042da:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042dc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042de:	e79d                	bnez	a5,8000430c <dirlookup+0x54>
    800042e0:	a8a5                	j	80004358 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042e2:	00004517          	auipc	a0,0x4
    800042e6:	47650513          	addi	a0,a0,1142 # 80008758 <syscalls+0x1c8>
    800042ea:	ffffc097          	auipc	ra,0xffffc
    800042ee:	256080e7          	jalr	598(ra) # 80000540 <panic>
      panic("dirlookup read");
    800042f2:	00004517          	auipc	a0,0x4
    800042f6:	47e50513          	addi	a0,a0,1150 # 80008770 <syscalls+0x1e0>
    800042fa:	ffffc097          	auipc	ra,0xffffc
    800042fe:	246080e7          	jalr	582(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004302:	24c1                	addiw	s1,s1,16
    80004304:	04c92783          	lw	a5,76(s2)
    80004308:	04f4f763          	bgeu	s1,a5,80004356 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000430c:	4741                	li	a4,16
    8000430e:	86a6                	mv	a3,s1
    80004310:	fc040613          	addi	a2,s0,-64
    80004314:	4581                	li	a1,0
    80004316:	854a                	mv	a0,s2
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	d70080e7          	jalr	-656(ra) # 80004088 <readi>
    80004320:	47c1                	li	a5,16
    80004322:	fcf518e3          	bne	a0,a5,800042f2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004326:	fc045783          	lhu	a5,-64(s0)
    8000432a:	dfe1                	beqz	a5,80004302 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000432c:	fc240593          	addi	a1,s0,-62
    80004330:	854e                	mv	a0,s3
    80004332:	00000097          	auipc	ra,0x0
    80004336:	f6c080e7          	jalr	-148(ra) # 8000429e <namecmp>
    8000433a:	f561                	bnez	a0,80004302 <dirlookup+0x4a>
      if(poff)
    8000433c:	000a0463          	beqz	s4,80004344 <dirlookup+0x8c>
        *poff = off;
    80004340:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004344:	fc045583          	lhu	a1,-64(s0)
    80004348:	00092503          	lw	a0,0(s2)
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	74e080e7          	jalr	1870(ra) # 80003a9a <iget>
    80004354:	a011                	j	80004358 <dirlookup+0xa0>
  return 0;
    80004356:	4501                	li	a0,0
}
    80004358:	70e2                	ld	ra,56(sp)
    8000435a:	7442                	ld	s0,48(sp)
    8000435c:	74a2                	ld	s1,40(sp)
    8000435e:	7902                	ld	s2,32(sp)
    80004360:	69e2                	ld	s3,24(sp)
    80004362:	6a42                	ld	s4,16(sp)
    80004364:	6121                	addi	sp,sp,64
    80004366:	8082                	ret

0000000080004368 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004368:	711d                	addi	sp,sp,-96
    8000436a:	ec86                	sd	ra,88(sp)
    8000436c:	e8a2                	sd	s0,80(sp)
    8000436e:	e4a6                	sd	s1,72(sp)
    80004370:	e0ca                	sd	s2,64(sp)
    80004372:	fc4e                	sd	s3,56(sp)
    80004374:	f852                	sd	s4,48(sp)
    80004376:	f456                	sd	s5,40(sp)
    80004378:	f05a                	sd	s6,32(sp)
    8000437a:	ec5e                	sd	s7,24(sp)
    8000437c:	e862                	sd	s8,16(sp)
    8000437e:	e466                	sd	s9,8(sp)
    80004380:	e06a                	sd	s10,0(sp)
    80004382:	1080                	addi	s0,sp,96
    80004384:	84aa                	mv	s1,a0
    80004386:	8b2e                	mv	s6,a1
    80004388:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000438a:	00054703          	lbu	a4,0(a0)
    8000438e:	02f00793          	li	a5,47
    80004392:	02f70363          	beq	a4,a5,800043b8 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004396:	ffffe097          	auipc	ra,0xffffe
    8000439a:	97e080e7          	jalr	-1666(ra) # 80001d14 <myproc>
    8000439e:	15053503          	ld	a0,336(a0)
    800043a2:	00000097          	auipc	ra,0x0
    800043a6:	9f4080e7          	jalr	-1548(ra) # 80003d96 <idup>
    800043aa:	8a2a                	mv	s4,a0
  while(*path == '/')
    800043ac:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800043b0:	4cb5                	li	s9,13
  len = path - s;
    800043b2:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043b4:	4c05                	li	s8,1
    800043b6:	a87d                	j	80004474 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800043b8:	4585                	li	a1,1
    800043ba:	4505                	li	a0,1
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	6de080e7          	jalr	1758(ra) # 80003a9a <iget>
    800043c4:	8a2a                	mv	s4,a0
    800043c6:	b7dd                	j	800043ac <namex+0x44>
      iunlockput(ip);
    800043c8:	8552                	mv	a0,s4
    800043ca:	00000097          	auipc	ra,0x0
    800043ce:	c6c080e7          	jalr	-916(ra) # 80004036 <iunlockput>
      return 0;
    800043d2:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043d4:	8552                	mv	a0,s4
    800043d6:	60e6                	ld	ra,88(sp)
    800043d8:	6446                	ld	s0,80(sp)
    800043da:	64a6                	ld	s1,72(sp)
    800043dc:	6906                	ld	s2,64(sp)
    800043de:	79e2                	ld	s3,56(sp)
    800043e0:	7a42                	ld	s4,48(sp)
    800043e2:	7aa2                	ld	s5,40(sp)
    800043e4:	7b02                	ld	s6,32(sp)
    800043e6:	6be2                	ld	s7,24(sp)
    800043e8:	6c42                	ld	s8,16(sp)
    800043ea:	6ca2                	ld	s9,8(sp)
    800043ec:	6d02                	ld	s10,0(sp)
    800043ee:	6125                	addi	sp,sp,96
    800043f0:	8082                	ret
      iunlock(ip);
    800043f2:	8552                	mv	a0,s4
    800043f4:	00000097          	auipc	ra,0x0
    800043f8:	aa2080e7          	jalr	-1374(ra) # 80003e96 <iunlock>
      return ip;
    800043fc:	bfe1                	j	800043d4 <namex+0x6c>
      iunlockput(ip);
    800043fe:	8552                	mv	a0,s4
    80004400:	00000097          	auipc	ra,0x0
    80004404:	c36080e7          	jalr	-970(ra) # 80004036 <iunlockput>
      return 0;
    80004408:	8a4e                	mv	s4,s3
    8000440a:	b7e9                	j	800043d4 <namex+0x6c>
  len = path - s;
    8000440c:	40998633          	sub	a2,s3,s1
    80004410:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004414:	09acd863          	bge	s9,s10,800044a4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004418:	4639                	li	a2,14
    8000441a:	85a6                	mv	a1,s1
    8000441c:	8556                	mv	a0,s5
    8000441e:	ffffd097          	auipc	ra,0xffffd
    80004422:	a9c080e7          	jalr	-1380(ra) # 80000eba <memmove>
    80004426:	84ce                	mv	s1,s3
  while(*path == '/')
    80004428:	0004c783          	lbu	a5,0(s1)
    8000442c:	01279763          	bne	a5,s2,8000443a <namex+0xd2>
    path++;
    80004430:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004432:	0004c783          	lbu	a5,0(s1)
    80004436:	ff278de3          	beq	a5,s2,80004430 <namex+0xc8>
    ilock(ip);
    8000443a:	8552                	mv	a0,s4
    8000443c:	00000097          	auipc	ra,0x0
    80004440:	998080e7          	jalr	-1640(ra) # 80003dd4 <ilock>
    if(ip->type != T_DIR){
    80004444:	044a1783          	lh	a5,68(s4)
    80004448:	f98790e3          	bne	a5,s8,800043c8 <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000444c:	000b0563          	beqz	s6,80004456 <namex+0xee>
    80004450:	0004c783          	lbu	a5,0(s1)
    80004454:	dfd9                	beqz	a5,800043f2 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004456:	865e                	mv	a2,s7
    80004458:	85d6                	mv	a1,s5
    8000445a:	8552                	mv	a0,s4
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	e5c080e7          	jalr	-420(ra) # 800042b8 <dirlookup>
    80004464:	89aa                	mv	s3,a0
    80004466:	dd41                	beqz	a0,800043fe <namex+0x96>
    iunlockput(ip);
    80004468:	8552                	mv	a0,s4
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	bcc080e7          	jalr	-1076(ra) # 80004036 <iunlockput>
    ip = next;
    80004472:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004474:	0004c783          	lbu	a5,0(s1)
    80004478:	01279763          	bne	a5,s2,80004486 <namex+0x11e>
    path++;
    8000447c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000447e:	0004c783          	lbu	a5,0(s1)
    80004482:	ff278de3          	beq	a5,s2,8000447c <namex+0x114>
  if(*path == 0)
    80004486:	cb9d                	beqz	a5,800044bc <namex+0x154>
  while(*path != '/' && *path != 0)
    80004488:	0004c783          	lbu	a5,0(s1)
    8000448c:	89a6                	mv	s3,s1
  len = path - s;
    8000448e:	8d5e                	mv	s10,s7
    80004490:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004492:	01278963          	beq	a5,s2,800044a4 <namex+0x13c>
    80004496:	dbbd                	beqz	a5,8000440c <namex+0xa4>
    path++;
    80004498:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000449a:	0009c783          	lbu	a5,0(s3)
    8000449e:	ff279ce3          	bne	a5,s2,80004496 <namex+0x12e>
    800044a2:	b7ad                	j	8000440c <namex+0xa4>
    memmove(name, s, len);
    800044a4:	2601                	sext.w	a2,a2
    800044a6:	85a6                	mv	a1,s1
    800044a8:	8556                	mv	a0,s5
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	a10080e7          	jalr	-1520(ra) # 80000eba <memmove>
    name[len] = 0;
    800044b2:	9d56                	add	s10,s10,s5
    800044b4:	000d0023          	sb	zero,0(s10)
    800044b8:	84ce                	mv	s1,s3
    800044ba:	b7bd                	j	80004428 <namex+0xc0>
  if(nameiparent){
    800044bc:	f00b0ce3          	beqz	s6,800043d4 <namex+0x6c>
    iput(ip);
    800044c0:	8552                	mv	a0,s4
    800044c2:	00000097          	auipc	ra,0x0
    800044c6:	acc080e7          	jalr	-1332(ra) # 80003f8e <iput>
    return 0;
    800044ca:	4a01                	li	s4,0
    800044cc:	b721                	j	800043d4 <namex+0x6c>

00000000800044ce <dirlink>:
{
    800044ce:	7139                	addi	sp,sp,-64
    800044d0:	fc06                	sd	ra,56(sp)
    800044d2:	f822                	sd	s0,48(sp)
    800044d4:	f426                	sd	s1,40(sp)
    800044d6:	f04a                	sd	s2,32(sp)
    800044d8:	ec4e                	sd	s3,24(sp)
    800044da:	e852                	sd	s4,16(sp)
    800044dc:	0080                	addi	s0,sp,64
    800044de:	892a                	mv	s2,a0
    800044e0:	8a2e                	mv	s4,a1
    800044e2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044e4:	4601                	li	a2,0
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	dd2080e7          	jalr	-558(ra) # 800042b8 <dirlookup>
    800044ee:	e93d                	bnez	a0,80004564 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044f0:	04c92483          	lw	s1,76(s2)
    800044f4:	c49d                	beqz	s1,80004522 <dirlink+0x54>
    800044f6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044f8:	4741                	li	a4,16
    800044fa:	86a6                	mv	a3,s1
    800044fc:	fc040613          	addi	a2,s0,-64
    80004500:	4581                	li	a1,0
    80004502:	854a                	mv	a0,s2
    80004504:	00000097          	auipc	ra,0x0
    80004508:	b84080e7          	jalr	-1148(ra) # 80004088 <readi>
    8000450c:	47c1                	li	a5,16
    8000450e:	06f51163          	bne	a0,a5,80004570 <dirlink+0xa2>
    if(de.inum == 0)
    80004512:	fc045783          	lhu	a5,-64(s0)
    80004516:	c791                	beqz	a5,80004522 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004518:	24c1                	addiw	s1,s1,16
    8000451a:	04c92783          	lw	a5,76(s2)
    8000451e:	fcf4ede3          	bltu	s1,a5,800044f8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004522:	4639                	li	a2,14
    80004524:	85d2                	mv	a1,s4
    80004526:	fc240513          	addi	a0,s0,-62
    8000452a:	ffffd097          	auipc	ra,0xffffd
    8000452e:	a40080e7          	jalr	-1472(ra) # 80000f6a <strncpy>
  de.inum = inum;
    80004532:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004536:	4741                	li	a4,16
    80004538:	86a6                	mv	a3,s1
    8000453a:	fc040613          	addi	a2,s0,-64
    8000453e:	4581                	li	a1,0
    80004540:	854a                	mv	a0,s2
    80004542:	00000097          	auipc	ra,0x0
    80004546:	c3e080e7          	jalr	-962(ra) # 80004180 <writei>
    8000454a:	1541                	addi	a0,a0,-16
    8000454c:	00a03533          	snez	a0,a0
    80004550:	40a00533          	neg	a0,a0
}
    80004554:	70e2                	ld	ra,56(sp)
    80004556:	7442                	ld	s0,48(sp)
    80004558:	74a2                	ld	s1,40(sp)
    8000455a:	7902                	ld	s2,32(sp)
    8000455c:	69e2                	ld	s3,24(sp)
    8000455e:	6a42                	ld	s4,16(sp)
    80004560:	6121                	addi	sp,sp,64
    80004562:	8082                	ret
    iput(ip);
    80004564:	00000097          	auipc	ra,0x0
    80004568:	a2a080e7          	jalr	-1494(ra) # 80003f8e <iput>
    return -1;
    8000456c:	557d                	li	a0,-1
    8000456e:	b7dd                	j	80004554 <dirlink+0x86>
      panic("dirlink read");
    80004570:	00004517          	auipc	a0,0x4
    80004574:	21050513          	addi	a0,a0,528 # 80008780 <syscalls+0x1f0>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	fc8080e7          	jalr	-56(ra) # 80000540 <panic>

0000000080004580 <namei>:

struct inode*
namei(char *path)
{
    80004580:	1101                	addi	sp,sp,-32
    80004582:	ec06                	sd	ra,24(sp)
    80004584:	e822                	sd	s0,16(sp)
    80004586:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004588:	fe040613          	addi	a2,s0,-32
    8000458c:	4581                	li	a1,0
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	dda080e7          	jalr	-550(ra) # 80004368 <namex>
}
    80004596:	60e2                	ld	ra,24(sp)
    80004598:	6442                	ld	s0,16(sp)
    8000459a:	6105                	addi	sp,sp,32
    8000459c:	8082                	ret

000000008000459e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000459e:	1141                	addi	sp,sp,-16
    800045a0:	e406                	sd	ra,8(sp)
    800045a2:	e022                	sd	s0,0(sp)
    800045a4:	0800                	addi	s0,sp,16
    800045a6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045a8:	4585                	li	a1,1
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	dbe080e7          	jalr	-578(ra) # 80004368 <namex>
}
    800045b2:	60a2                	ld	ra,8(sp)
    800045b4:	6402                	ld	s0,0(sp)
    800045b6:	0141                	addi	sp,sp,16
    800045b8:	8082                	ret

00000000800045ba <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045ba:	1101                	addi	sp,sp,-32
    800045bc:	ec06                	sd	ra,24(sp)
    800045be:	e822                	sd	s0,16(sp)
    800045c0:	e426                	sd	s1,8(sp)
    800045c2:	e04a                	sd	s2,0(sp)
    800045c4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045c6:	0003c917          	auipc	s2,0x3c
    800045ca:	70a90913          	addi	s2,s2,1802 # 80040cd0 <log>
    800045ce:	01892583          	lw	a1,24(s2)
    800045d2:	02892503          	lw	a0,40(s2)
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	fe6080e7          	jalr	-26(ra) # 800035bc <bread>
    800045de:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045e0:	02c92683          	lw	a3,44(s2)
    800045e4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045e6:	02d05863          	blez	a3,80004616 <write_head+0x5c>
    800045ea:	0003c797          	auipc	a5,0x3c
    800045ee:	71678793          	addi	a5,a5,1814 # 80040d00 <log+0x30>
    800045f2:	05c50713          	addi	a4,a0,92
    800045f6:	36fd                	addiw	a3,a3,-1
    800045f8:	02069613          	slli	a2,a3,0x20
    800045fc:	01e65693          	srli	a3,a2,0x1e
    80004600:	0003c617          	auipc	a2,0x3c
    80004604:	70460613          	addi	a2,a2,1796 # 80040d04 <log+0x34>
    80004608:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000460a:	4390                	lw	a2,0(a5)
    8000460c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000460e:	0791                	addi	a5,a5,4
    80004610:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004612:	fed79ce3          	bne	a5,a3,8000460a <write_head+0x50>
  }
  bwrite(buf);
    80004616:	8526                	mv	a0,s1
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	096080e7          	jalr	150(ra) # 800036ae <bwrite>
  brelse(buf);
    80004620:	8526                	mv	a0,s1
    80004622:	fffff097          	auipc	ra,0xfffff
    80004626:	0ca080e7          	jalr	202(ra) # 800036ec <brelse>
}
    8000462a:	60e2                	ld	ra,24(sp)
    8000462c:	6442                	ld	s0,16(sp)
    8000462e:	64a2                	ld	s1,8(sp)
    80004630:	6902                	ld	s2,0(sp)
    80004632:	6105                	addi	sp,sp,32
    80004634:	8082                	ret

0000000080004636 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004636:	0003c797          	auipc	a5,0x3c
    8000463a:	6c67a783          	lw	a5,1734(a5) # 80040cfc <log+0x2c>
    8000463e:	0af05d63          	blez	a5,800046f8 <install_trans+0xc2>
{
    80004642:	7139                	addi	sp,sp,-64
    80004644:	fc06                	sd	ra,56(sp)
    80004646:	f822                	sd	s0,48(sp)
    80004648:	f426                	sd	s1,40(sp)
    8000464a:	f04a                	sd	s2,32(sp)
    8000464c:	ec4e                	sd	s3,24(sp)
    8000464e:	e852                	sd	s4,16(sp)
    80004650:	e456                	sd	s5,8(sp)
    80004652:	e05a                	sd	s6,0(sp)
    80004654:	0080                	addi	s0,sp,64
    80004656:	8b2a                	mv	s6,a0
    80004658:	0003ca97          	auipc	s5,0x3c
    8000465c:	6a8a8a93          	addi	s5,s5,1704 # 80040d00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004660:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004662:	0003c997          	auipc	s3,0x3c
    80004666:	66e98993          	addi	s3,s3,1646 # 80040cd0 <log>
    8000466a:	a00d                	j	8000468c <install_trans+0x56>
    brelse(lbuf);
    8000466c:	854a                	mv	a0,s2
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	07e080e7          	jalr	126(ra) # 800036ec <brelse>
    brelse(dbuf);
    80004676:	8526                	mv	a0,s1
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	074080e7          	jalr	116(ra) # 800036ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004680:	2a05                	addiw	s4,s4,1
    80004682:	0a91                	addi	s5,s5,4
    80004684:	02c9a783          	lw	a5,44(s3)
    80004688:	04fa5e63          	bge	s4,a5,800046e4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000468c:	0189a583          	lw	a1,24(s3)
    80004690:	014585bb          	addw	a1,a1,s4
    80004694:	2585                	addiw	a1,a1,1
    80004696:	0289a503          	lw	a0,40(s3)
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	f22080e7          	jalr	-222(ra) # 800035bc <bread>
    800046a2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046a4:	000aa583          	lw	a1,0(s5)
    800046a8:	0289a503          	lw	a0,40(s3)
    800046ac:	fffff097          	auipc	ra,0xfffff
    800046b0:	f10080e7          	jalr	-240(ra) # 800035bc <bread>
    800046b4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046b6:	40000613          	li	a2,1024
    800046ba:	05890593          	addi	a1,s2,88
    800046be:	05850513          	addi	a0,a0,88
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	7f8080e7          	jalr	2040(ra) # 80000eba <memmove>
    bwrite(dbuf);  // write dst to disk
    800046ca:	8526                	mv	a0,s1
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	fe2080e7          	jalr	-30(ra) # 800036ae <bwrite>
    if(recovering == 0)
    800046d4:	f80b1ce3          	bnez	s6,8000466c <install_trans+0x36>
      bunpin(dbuf);
    800046d8:	8526                	mv	a0,s1
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	0ec080e7          	jalr	236(ra) # 800037c6 <bunpin>
    800046e2:	b769                	j	8000466c <install_trans+0x36>
}
    800046e4:	70e2                	ld	ra,56(sp)
    800046e6:	7442                	ld	s0,48(sp)
    800046e8:	74a2                	ld	s1,40(sp)
    800046ea:	7902                	ld	s2,32(sp)
    800046ec:	69e2                	ld	s3,24(sp)
    800046ee:	6a42                	ld	s4,16(sp)
    800046f0:	6aa2                	ld	s5,8(sp)
    800046f2:	6b02                	ld	s6,0(sp)
    800046f4:	6121                	addi	sp,sp,64
    800046f6:	8082                	ret
    800046f8:	8082                	ret

00000000800046fa <initlog>:
{
    800046fa:	7179                	addi	sp,sp,-48
    800046fc:	f406                	sd	ra,40(sp)
    800046fe:	f022                	sd	s0,32(sp)
    80004700:	ec26                	sd	s1,24(sp)
    80004702:	e84a                	sd	s2,16(sp)
    80004704:	e44e                	sd	s3,8(sp)
    80004706:	1800                	addi	s0,sp,48
    80004708:	892a                	mv	s2,a0
    8000470a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000470c:	0003c497          	auipc	s1,0x3c
    80004710:	5c448493          	addi	s1,s1,1476 # 80040cd0 <log>
    80004714:	00004597          	auipc	a1,0x4
    80004718:	07c58593          	addi	a1,a1,124 # 80008790 <syscalls+0x200>
    8000471c:	8526                	mv	a0,s1
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	5b4080e7          	jalr	1460(ra) # 80000cd2 <initlock>
  log.start = sb->logstart;
    80004726:	0149a583          	lw	a1,20(s3)
    8000472a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000472c:	0109a783          	lw	a5,16(s3)
    80004730:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004732:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004736:	854a                	mv	a0,s2
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	e84080e7          	jalr	-380(ra) # 800035bc <bread>
  log.lh.n = lh->n;
    80004740:	4d34                	lw	a3,88(a0)
    80004742:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004744:	02d05663          	blez	a3,80004770 <initlog+0x76>
    80004748:	05c50793          	addi	a5,a0,92
    8000474c:	0003c717          	auipc	a4,0x3c
    80004750:	5b470713          	addi	a4,a4,1460 # 80040d00 <log+0x30>
    80004754:	36fd                	addiw	a3,a3,-1
    80004756:	02069613          	slli	a2,a3,0x20
    8000475a:	01e65693          	srli	a3,a2,0x1e
    8000475e:	06050613          	addi	a2,a0,96
    80004762:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004764:	4390                	lw	a2,0(a5)
    80004766:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004768:	0791                	addi	a5,a5,4
    8000476a:	0711                	addi	a4,a4,4
    8000476c:	fed79ce3          	bne	a5,a3,80004764 <initlog+0x6a>
  brelse(buf);
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	f7c080e7          	jalr	-132(ra) # 800036ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004778:	4505                	li	a0,1
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	ebc080e7          	jalr	-324(ra) # 80004636 <install_trans>
  log.lh.n = 0;
    80004782:	0003c797          	auipc	a5,0x3c
    80004786:	5607ad23          	sw	zero,1402(a5) # 80040cfc <log+0x2c>
  write_head(); // clear the log
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	e30080e7          	jalr	-464(ra) # 800045ba <write_head>
}
    80004792:	70a2                	ld	ra,40(sp)
    80004794:	7402                	ld	s0,32(sp)
    80004796:	64e2                	ld	s1,24(sp)
    80004798:	6942                	ld	s2,16(sp)
    8000479a:	69a2                	ld	s3,8(sp)
    8000479c:	6145                	addi	sp,sp,48
    8000479e:	8082                	ret

00000000800047a0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047a0:	1101                	addi	sp,sp,-32
    800047a2:	ec06                	sd	ra,24(sp)
    800047a4:	e822                	sd	s0,16(sp)
    800047a6:	e426                	sd	s1,8(sp)
    800047a8:	e04a                	sd	s2,0(sp)
    800047aa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047ac:	0003c517          	auipc	a0,0x3c
    800047b0:	52450513          	addi	a0,a0,1316 # 80040cd0 <log>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	5ae080e7          	jalr	1454(ra) # 80000d62 <acquire>
  while(1){
    if(log.committing){
    800047bc:	0003c497          	auipc	s1,0x3c
    800047c0:	51448493          	addi	s1,s1,1300 # 80040cd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047c4:	4979                	li	s2,30
    800047c6:	a039                	j	800047d4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047c8:	85a6                	mv	a1,s1
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffe097          	auipc	ra,0xffffe
    800047d0:	cf6080e7          	jalr	-778(ra) # 800024c2 <sleep>
    if(log.committing){
    800047d4:	50dc                	lw	a5,36(s1)
    800047d6:	fbed                	bnez	a5,800047c8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047d8:	5098                	lw	a4,32(s1)
    800047da:	2705                	addiw	a4,a4,1
    800047dc:	0007069b          	sext.w	a3,a4
    800047e0:	0027179b          	slliw	a5,a4,0x2
    800047e4:	9fb9                	addw	a5,a5,a4
    800047e6:	0017979b          	slliw	a5,a5,0x1
    800047ea:	54d8                	lw	a4,44(s1)
    800047ec:	9fb9                	addw	a5,a5,a4
    800047ee:	00f95963          	bge	s2,a5,80004800 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047f2:	85a6                	mv	a1,s1
    800047f4:	8526                	mv	a0,s1
    800047f6:	ffffe097          	auipc	ra,0xffffe
    800047fa:	ccc080e7          	jalr	-820(ra) # 800024c2 <sleep>
    800047fe:	bfd9                	j	800047d4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004800:	0003c517          	auipc	a0,0x3c
    80004804:	4d050513          	addi	a0,a0,1232 # 80040cd0 <log>
    80004808:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	60c080e7          	jalr	1548(ra) # 80000e16 <release>
      break;
    }
  }
}
    80004812:	60e2                	ld	ra,24(sp)
    80004814:	6442                	ld	s0,16(sp)
    80004816:	64a2                	ld	s1,8(sp)
    80004818:	6902                	ld	s2,0(sp)
    8000481a:	6105                	addi	sp,sp,32
    8000481c:	8082                	ret

000000008000481e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000481e:	7139                	addi	sp,sp,-64
    80004820:	fc06                	sd	ra,56(sp)
    80004822:	f822                	sd	s0,48(sp)
    80004824:	f426                	sd	s1,40(sp)
    80004826:	f04a                	sd	s2,32(sp)
    80004828:	ec4e                	sd	s3,24(sp)
    8000482a:	e852                	sd	s4,16(sp)
    8000482c:	e456                	sd	s5,8(sp)
    8000482e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004830:	0003c497          	auipc	s1,0x3c
    80004834:	4a048493          	addi	s1,s1,1184 # 80040cd0 <log>
    80004838:	8526                	mv	a0,s1
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	528080e7          	jalr	1320(ra) # 80000d62 <acquire>
  log.outstanding -= 1;
    80004842:	509c                	lw	a5,32(s1)
    80004844:	37fd                	addiw	a5,a5,-1
    80004846:	0007891b          	sext.w	s2,a5
    8000484a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000484c:	50dc                	lw	a5,36(s1)
    8000484e:	e7b9                	bnez	a5,8000489c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004850:	04091e63          	bnez	s2,800048ac <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004854:	0003c497          	auipc	s1,0x3c
    80004858:	47c48493          	addi	s1,s1,1148 # 80040cd0 <log>
    8000485c:	4785                	li	a5,1
    8000485e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004860:	8526                	mv	a0,s1
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	5b4080e7          	jalr	1460(ra) # 80000e16 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000486a:	54dc                	lw	a5,44(s1)
    8000486c:	06f04763          	bgtz	a5,800048da <end_op+0xbc>
    acquire(&log.lock);
    80004870:	0003c497          	auipc	s1,0x3c
    80004874:	46048493          	addi	s1,s1,1120 # 80040cd0 <log>
    80004878:	8526                	mv	a0,s1
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	4e8080e7          	jalr	1256(ra) # 80000d62 <acquire>
    log.committing = 0;
    80004882:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004886:	8526                	mv	a0,s1
    80004888:	ffffe097          	auipc	ra,0xffffe
    8000488c:	c9e080e7          	jalr	-866(ra) # 80002526 <wakeup>
    release(&log.lock);
    80004890:	8526                	mv	a0,s1
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	584080e7          	jalr	1412(ra) # 80000e16 <release>
}
    8000489a:	a03d                	j	800048c8 <end_op+0xaa>
    panic("log.committing");
    8000489c:	00004517          	auipc	a0,0x4
    800048a0:	efc50513          	addi	a0,a0,-260 # 80008798 <syscalls+0x208>
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	c9c080e7          	jalr	-868(ra) # 80000540 <panic>
    wakeup(&log);
    800048ac:	0003c497          	auipc	s1,0x3c
    800048b0:	42448493          	addi	s1,s1,1060 # 80040cd0 <log>
    800048b4:	8526                	mv	a0,s1
    800048b6:	ffffe097          	auipc	ra,0xffffe
    800048ba:	c70080e7          	jalr	-912(ra) # 80002526 <wakeup>
  release(&log.lock);
    800048be:	8526                	mv	a0,s1
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	556080e7          	jalr	1366(ra) # 80000e16 <release>
}
    800048c8:	70e2                	ld	ra,56(sp)
    800048ca:	7442                	ld	s0,48(sp)
    800048cc:	74a2                	ld	s1,40(sp)
    800048ce:	7902                	ld	s2,32(sp)
    800048d0:	69e2                	ld	s3,24(sp)
    800048d2:	6a42                	ld	s4,16(sp)
    800048d4:	6aa2                	ld	s5,8(sp)
    800048d6:	6121                	addi	sp,sp,64
    800048d8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800048da:	0003ca97          	auipc	s5,0x3c
    800048de:	426a8a93          	addi	s5,s5,1062 # 80040d00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048e2:	0003ca17          	auipc	s4,0x3c
    800048e6:	3eea0a13          	addi	s4,s4,1006 # 80040cd0 <log>
    800048ea:	018a2583          	lw	a1,24(s4)
    800048ee:	012585bb          	addw	a1,a1,s2
    800048f2:	2585                	addiw	a1,a1,1
    800048f4:	028a2503          	lw	a0,40(s4)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	cc4080e7          	jalr	-828(ra) # 800035bc <bread>
    80004900:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004902:	000aa583          	lw	a1,0(s5)
    80004906:	028a2503          	lw	a0,40(s4)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	cb2080e7          	jalr	-846(ra) # 800035bc <bread>
    80004912:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004914:	40000613          	li	a2,1024
    80004918:	05850593          	addi	a1,a0,88
    8000491c:	05848513          	addi	a0,s1,88
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	59a080e7          	jalr	1434(ra) # 80000eba <memmove>
    bwrite(to);  // write the log
    80004928:	8526                	mv	a0,s1
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	d84080e7          	jalr	-636(ra) # 800036ae <bwrite>
    brelse(from);
    80004932:	854e                	mv	a0,s3
    80004934:	fffff097          	auipc	ra,0xfffff
    80004938:	db8080e7          	jalr	-584(ra) # 800036ec <brelse>
    brelse(to);
    8000493c:	8526                	mv	a0,s1
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	dae080e7          	jalr	-594(ra) # 800036ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004946:	2905                	addiw	s2,s2,1
    80004948:	0a91                	addi	s5,s5,4
    8000494a:	02ca2783          	lw	a5,44(s4)
    8000494e:	f8f94ee3          	blt	s2,a5,800048ea <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004952:	00000097          	auipc	ra,0x0
    80004956:	c68080e7          	jalr	-920(ra) # 800045ba <write_head>
    install_trans(0); // Now install writes to home locations
    8000495a:	4501                	li	a0,0
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	cda080e7          	jalr	-806(ra) # 80004636 <install_trans>
    log.lh.n = 0;
    80004964:	0003c797          	auipc	a5,0x3c
    80004968:	3807ac23          	sw	zero,920(a5) # 80040cfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	c4e080e7          	jalr	-946(ra) # 800045ba <write_head>
    80004974:	bdf5                	j	80004870 <end_op+0x52>

0000000080004976 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004976:	1101                	addi	sp,sp,-32
    80004978:	ec06                	sd	ra,24(sp)
    8000497a:	e822                	sd	s0,16(sp)
    8000497c:	e426                	sd	s1,8(sp)
    8000497e:	e04a                	sd	s2,0(sp)
    80004980:	1000                	addi	s0,sp,32
    80004982:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004984:	0003c917          	auipc	s2,0x3c
    80004988:	34c90913          	addi	s2,s2,844 # 80040cd0 <log>
    8000498c:	854a                	mv	a0,s2
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	3d4080e7          	jalr	980(ra) # 80000d62 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004996:	02c92603          	lw	a2,44(s2)
    8000499a:	47f5                	li	a5,29
    8000499c:	06c7c563          	blt	a5,a2,80004a06 <log_write+0x90>
    800049a0:	0003c797          	auipc	a5,0x3c
    800049a4:	34c7a783          	lw	a5,844(a5) # 80040cec <log+0x1c>
    800049a8:	37fd                	addiw	a5,a5,-1
    800049aa:	04f65e63          	bge	a2,a5,80004a06 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049ae:	0003c797          	auipc	a5,0x3c
    800049b2:	3427a783          	lw	a5,834(a5) # 80040cf0 <log+0x20>
    800049b6:	06f05063          	blez	a5,80004a16 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049ba:	4781                	li	a5,0
    800049bc:	06c05563          	blez	a2,80004a26 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049c0:	44cc                	lw	a1,12(s1)
    800049c2:	0003c717          	auipc	a4,0x3c
    800049c6:	33e70713          	addi	a4,a4,830 # 80040d00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049ca:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049cc:	4314                	lw	a3,0(a4)
    800049ce:	04b68c63          	beq	a3,a1,80004a26 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049d2:	2785                	addiw	a5,a5,1
    800049d4:	0711                	addi	a4,a4,4
    800049d6:	fef61be3          	bne	a2,a5,800049cc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049da:	0621                	addi	a2,a2,8
    800049dc:	060a                	slli	a2,a2,0x2
    800049de:	0003c797          	auipc	a5,0x3c
    800049e2:	2f278793          	addi	a5,a5,754 # 80040cd0 <log>
    800049e6:	97b2                	add	a5,a5,a2
    800049e8:	44d8                	lw	a4,12(s1)
    800049ea:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049ec:	8526                	mv	a0,s1
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	d9c080e7          	jalr	-612(ra) # 8000378a <bpin>
    log.lh.n++;
    800049f6:	0003c717          	auipc	a4,0x3c
    800049fa:	2da70713          	addi	a4,a4,730 # 80040cd0 <log>
    800049fe:	575c                	lw	a5,44(a4)
    80004a00:	2785                	addiw	a5,a5,1
    80004a02:	d75c                	sw	a5,44(a4)
    80004a04:	a82d                	j	80004a3e <log_write+0xc8>
    panic("too big a transaction");
    80004a06:	00004517          	auipc	a0,0x4
    80004a0a:	da250513          	addi	a0,a0,-606 # 800087a8 <syscalls+0x218>
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	b32080e7          	jalr	-1230(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004a16:	00004517          	auipc	a0,0x4
    80004a1a:	daa50513          	addi	a0,a0,-598 # 800087c0 <syscalls+0x230>
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	b22080e7          	jalr	-1246(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004a26:	00878693          	addi	a3,a5,8
    80004a2a:	068a                	slli	a3,a3,0x2
    80004a2c:	0003c717          	auipc	a4,0x3c
    80004a30:	2a470713          	addi	a4,a4,676 # 80040cd0 <log>
    80004a34:	9736                	add	a4,a4,a3
    80004a36:	44d4                	lw	a3,12(s1)
    80004a38:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a3a:	faf609e3          	beq	a2,a5,800049ec <log_write+0x76>
  }
  release(&log.lock);
    80004a3e:	0003c517          	auipc	a0,0x3c
    80004a42:	29250513          	addi	a0,a0,658 # 80040cd0 <log>
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	3d0080e7          	jalr	976(ra) # 80000e16 <release>
}
    80004a4e:	60e2                	ld	ra,24(sp)
    80004a50:	6442                	ld	s0,16(sp)
    80004a52:	64a2                	ld	s1,8(sp)
    80004a54:	6902                	ld	s2,0(sp)
    80004a56:	6105                	addi	sp,sp,32
    80004a58:	8082                	ret

0000000080004a5a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a5a:	1101                	addi	sp,sp,-32
    80004a5c:	ec06                	sd	ra,24(sp)
    80004a5e:	e822                	sd	s0,16(sp)
    80004a60:	e426                	sd	s1,8(sp)
    80004a62:	e04a                	sd	s2,0(sp)
    80004a64:	1000                	addi	s0,sp,32
    80004a66:	84aa                	mv	s1,a0
    80004a68:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a6a:	00004597          	auipc	a1,0x4
    80004a6e:	d7658593          	addi	a1,a1,-650 # 800087e0 <syscalls+0x250>
    80004a72:	0521                	addi	a0,a0,8
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	25e080e7          	jalr	606(ra) # 80000cd2 <initlock>
  lk->name = name;
    80004a7c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a80:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a84:	0204a423          	sw	zero,40(s1)
}
    80004a88:	60e2                	ld	ra,24(sp)
    80004a8a:	6442                	ld	s0,16(sp)
    80004a8c:	64a2                	ld	s1,8(sp)
    80004a8e:	6902                	ld	s2,0(sp)
    80004a90:	6105                	addi	sp,sp,32
    80004a92:	8082                	ret

0000000080004a94 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a94:	1101                	addi	sp,sp,-32
    80004a96:	ec06                	sd	ra,24(sp)
    80004a98:	e822                	sd	s0,16(sp)
    80004a9a:	e426                	sd	s1,8(sp)
    80004a9c:	e04a                	sd	s2,0(sp)
    80004a9e:	1000                	addi	s0,sp,32
    80004aa0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004aa2:	00850913          	addi	s2,a0,8
    80004aa6:	854a                	mv	a0,s2
    80004aa8:	ffffc097          	auipc	ra,0xffffc
    80004aac:	2ba080e7          	jalr	698(ra) # 80000d62 <acquire>
  while (lk->locked) {
    80004ab0:	409c                	lw	a5,0(s1)
    80004ab2:	cb89                	beqz	a5,80004ac4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ab4:	85ca                	mv	a1,s2
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	ffffe097          	auipc	ra,0xffffe
    80004abc:	a0a080e7          	jalr	-1526(ra) # 800024c2 <sleep>
  while (lk->locked) {
    80004ac0:	409c                	lw	a5,0(s1)
    80004ac2:	fbed                	bnez	a5,80004ab4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ac4:	4785                	li	a5,1
    80004ac6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	24c080e7          	jalr	588(ra) # 80001d14 <myproc>
    80004ad0:	591c                	lw	a5,48(a0)
    80004ad2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ad4:	854a                	mv	a0,s2
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	340080e7          	jalr	832(ra) # 80000e16 <release>
}
    80004ade:	60e2                	ld	ra,24(sp)
    80004ae0:	6442                	ld	s0,16(sp)
    80004ae2:	64a2                	ld	s1,8(sp)
    80004ae4:	6902                	ld	s2,0(sp)
    80004ae6:	6105                	addi	sp,sp,32
    80004ae8:	8082                	ret

0000000080004aea <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004aea:	1101                	addi	sp,sp,-32
    80004aec:	ec06                	sd	ra,24(sp)
    80004aee:	e822                	sd	s0,16(sp)
    80004af0:	e426                	sd	s1,8(sp)
    80004af2:	e04a                	sd	s2,0(sp)
    80004af4:	1000                	addi	s0,sp,32
    80004af6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004af8:	00850913          	addi	s2,a0,8
    80004afc:	854a                	mv	a0,s2
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	264080e7          	jalr	612(ra) # 80000d62 <acquire>
  lk->locked = 0;
    80004b06:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b0a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b0e:	8526                	mv	a0,s1
    80004b10:	ffffe097          	auipc	ra,0xffffe
    80004b14:	a16080e7          	jalr	-1514(ra) # 80002526 <wakeup>
  release(&lk->lk);
    80004b18:	854a                	mv	a0,s2
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	2fc080e7          	jalr	764(ra) # 80000e16 <release>
}
    80004b22:	60e2                	ld	ra,24(sp)
    80004b24:	6442                	ld	s0,16(sp)
    80004b26:	64a2                	ld	s1,8(sp)
    80004b28:	6902                	ld	s2,0(sp)
    80004b2a:	6105                	addi	sp,sp,32
    80004b2c:	8082                	ret

0000000080004b2e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b2e:	7179                	addi	sp,sp,-48
    80004b30:	f406                	sd	ra,40(sp)
    80004b32:	f022                	sd	s0,32(sp)
    80004b34:	ec26                	sd	s1,24(sp)
    80004b36:	e84a                	sd	s2,16(sp)
    80004b38:	e44e                	sd	s3,8(sp)
    80004b3a:	1800                	addi	s0,sp,48
    80004b3c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b3e:	00850913          	addi	s2,a0,8
    80004b42:	854a                	mv	a0,s2
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	21e080e7          	jalr	542(ra) # 80000d62 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b4c:	409c                	lw	a5,0(s1)
    80004b4e:	ef99                	bnez	a5,80004b6c <holdingsleep+0x3e>
    80004b50:	4481                	li	s1,0
  release(&lk->lk);
    80004b52:	854a                	mv	a0,s2
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	2c2080e7          	jalr	706(ra) # 80000e16 <release>
  return r;
}
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	70a2                	ld	ra,40(sp)
    80004b60:	7402                	ld	s0,32(sp)
    80004b62:	64e2                	ld	s1,24(sp)
    80004b64:	6942                	ld	s2,16(sp)
    80004b66:	69a2                	ld	s3,8(sp)
    80004b68:	6145                	addi	sp,sp,48
    80004b6a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b6c:	0284a983          	lw	s3,40(s1)
    80004b70:	ffffd097          	auipc	ra,0xffffd
    80004b74:	1a4080e7          	jalr	420(ra) # 80001d14 <myproc>
    80004b78:	5904                	lw	s1,48(a0)
    80004b7a:	413484b3          	sub	s1,s1,s3
    80004b7e:	0014b493          	seqz	s1,s1
    80004b82:	bfc1                	j	80004b52 <holdingsleep+0x24>

0000000080004b84 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b84:	1141                	addi	sp,sp,-16
    80004b86:	e406                	sd	ra,8(sp)
    80004b88:	e022                	sd	s0,0(sp)
    80004b8a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b8c:	00004597          	auipc	a1,0x4
    80004b90:	c6458593          	addi	a1,a1,-924 # 800087f0 <syscalls+0x260>
    80004b94:	0003c517          	auipc	a0,0x3c
    80004b98:	28450513          	addi	a0,a0,644 # 80040e18 <ftable>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	136080e7          	jalr	310(ra) # 80000cd2 <initlock>
}
    80004ba4:	60a2                	ld	ra,8(sp)
    80004ba6:	6402                	ld	s0,0(sp)
    80004ba8:	0141                	addi	sp,sp,16
    80004baa:	8082                	ret

0000000080004bac <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bac:	1101                	addi	sp,sp,-32
    80004bae:	ec06                	sd	ra,24(sp)
    80004bb0:	e822                	sd	s0,16(sp)
    80004bb2:	e426                	sd	s1,8(sp)
    80004bb4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bb6:	0003c517          	auipc	a0,0x3c
    80004bba:	26250513          	addi	a0,a0,610 # 80040e18 <ftable>
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	1a4080e7          	jalr	420(ra) # 80000d62 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bc6:	0003c497          	auipc	s1,0x3c
    80004bca:	26a48493          	addi	s1,s1,618 # 80040e30 <ftable+0x18>
    80004bce:	0003d717          	auipc	a4,0x3d
    80004bd2:	20270713          	addi	a4,a4,514 # 80041dd0 <disk>
    if(f->ref == 0){
    80004bd6:	40dc                	lw	a5,4(s1)
    80004bd8:	cf99                	beqz	a5,80004bf6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bda:	02848493          	addi	s1,s1,40
    80004bde:	fee49ce3          	bne	s1,a4,80004bd6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004be2:	0003c517          	auipc	a0,0x3c
    80004be6:	23650513          	addi	a0,a0,566 # 80040e18 <ftable>
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	22c080e7          	jalr	556(ra) # 80000e16 <release>
  return 0;
    80004bf2:	4481                	li	s1,0
    80004bf4:	a819                	j	80004c0a <filealloc+0x5e>
      f->ref = 1;
    80004bf6:	4785                	li	a5,1
    80004bf8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004bfa:	0003c517          	auipc	a0,0x3c
    80004bfe:	21e50513          	addi	a0,a0,542 # 80040e18 <ftable>
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	214080e7          	jalr	532(ra) # 80000e16 <release>
}
    80004c0a:	8526                	mv	a0,s1
    80004c0c:	60e2                	ld	ra,24(sp)
    80004c0e:	6442                	ld	s0,16(sp)
    80004c10:	64a2                	ld	s1,8(sp)
    80004c12:	6105                	addi	sp,sp,32
    80004c14:	8082                	ret

0000000080004c16 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c16:	1101                	addi	sp,sp,-32
    80004c18:	ec06                	sd	ra,24(sp)
    80004c1a:	e822                	sd	s0,16(sp)
    80004c1c:	e426                	sd	s1,8(sp)
    80004c1e:	1000                	addi	s0,sp,32
    80004c20:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c22:	0003c517          	auipc	a0,0x3c
    80004c26:	1f650513          	addi	a0,a0,502 # 80040e18 <ftable>
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	138080e7          	jalr	312(ra) # 80000d62 <acquire>
  if(f->ref < 1)
    80004c32:	40dc                	lw	a5,4(s1)
    80004c34:	02f05263          	blez	a5,80004c58 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c38:	2785                	addiw	a5,a5,1
    80004c3a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c3c:	0003c517          	auipc	a0,0x3c
    80004c40:	1dc50513          	addi	a0,a0,476 # 80040e18 <ftable>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	1d2080e7          	jalr	466(ra) # 80000e16 <release>
  return f;
}
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	60e2                	ld	ra,24(sp)
    80004c50:	6442                	ld	s0,16(sp)
    80004c52:	64a2                	ld	s1,8(sp)
    80004c54:	6105                	addi	sp,sp,32
    80004c56:	8082                	ret
    panic("filedup");
    80004c58:	00004517          	auipc	a0,0x4
    80004c5c:	ba050513          	addi	a0,a0,-1120 # 800087f8 <syscalls+0x268>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	8e0080e7          	jalr	-1824(ra) # 80000540 <panic>

0000000080004c68 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c68:	7139                	addi	sp,sp,-64
    80004c6a:	fc06                	sd	ra,56(sp)
    80004c6c:	f822                	sd	s0,48(sp)
    80004c6e:	f426                	sd	s1,40(sp)
    80004c70:	f04a                	sd	s2,32(sp)
    80004c72:	ec4e                	sd	s3,24(sp)
    80004c74:	e852                	sd	s4,16(sp)
    80004c76:	e456                	sd	s5,8(sp)
    80004c78:	0080                	addi	s0,sp,64
    80004c7a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c7c:	0003c517          	auipc	a0,0x3c
    80004c80:	19c50513          	addi	a0,a0,412 # 80040e18 <ftable>
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	0de080e7          	jalr	222(ra) # 80000d62 <acquire>
  if(f->ref < 1)
    80004c8c:	40dc                	lw	a5,4(s1)
    80004c8e:	06f05163          	blez	a5,80004cf0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c92:	37fd                	addiw	a5,a5,-1
    80004c94:	0007871b          	sext.w	a4,a5
    80004c98:	c0dc                	sw	a5,4(s1)
    80004c9a:	06e04363          	bgtz	a4,80004d00 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c9e:	0004a903          	lw	s2,0(s1)
    80004ca2:	0094ca83          	lbu	s5,9(s1)
    80004ca6:	0104ba03          	ld	s4,16(s1)
    80004caa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cae:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cb2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cb6:	0003c517          	auipc	a0,0x3c
    80004cba:	16250513          	addi	a0,a0,354 # 80040e18 <ftable>
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	158080e7          	jalr	344(ra) # 80000e16 <release>

  if(ff.type == FD_PIPE){
    80004cc6:	4785                	li	a5,1
    80004cc8:	04f90d63          	beq	s2,a5,80004d22 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ccc:	3979                	addiw	s2,s2,-2
    80004cce:	4785                	li	a5,1
    80004cd0:	0527e063          	bltu	a5,s2,80004d10 <fileclose+0xa8>
    begin_op();
    80004cd4:	00000097          	auipc	ra,0x0
    80004cd8:	acc080e7          	jalr	-1332(ra) # 800047a0 <begin_op>
    iput(ff.ip);
    80004cdc:	854e                	mv	a0,s3
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	2b0080e7          	jalr	688(ra) # 80003f8e <iput>
    end_op();
    80004ce6:	00000097          	auipc	ra,0x0
    80004cea:	b38080e7          	jalr	-1224(ra) # 8000481e <end_op>
    80004cee:	a00d                	j	80004d10 <fileclose+0xa8>
    panic("fileclose");
    80004cf0:	00004517          	auipc	a0,0x4
    80004cf4:	b1050513          	addi	a0,a0,-1264 # 80008800 <syscalls+0x270>
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	848080e7          	jalr	-1976(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004d00:	0003c517          	auipc	a0,0x3c
    80004d04:	11850513          	addi	a0,a0,280 # 80040e18 <ftable>
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	10e080e7          	jalr	270(ra) # 80000e16 <release>
  }
}
    80004d10:	70e2                	ld	ra,56(sp)
    80004d12:	7442                	ld	s0,48(sp)
    80004d14:	74a2                	ld	s1,40(sp)
    80004d16:	7902                	ld	s2,32(sp)
    80004d18:	69e2                	ld	s3,24(sp)
    80004d1a:	6a42                	ld	s4,16(sp)
    80004d1c:	6aa2                	ld	s5,8(sp)
    80004d1e:	6121                	addi	sp,sp,64
    80004d20:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d22:	85d6                	mv	a1,s5
    80004d24:	8552                	mv	a0,s4
    80004d26:	00000097          	auipc	ra,0x0
    80004d2a:	34c080e7          	jalr	844(ra) # 80005072 <pipeclose>
    80004d2e:	b7cd                	j	80004d10 <fileclose+0xa8>

0000000080004d30 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d30:	715d                	addi	sp,sp,-80
    80004d32:	e486                	sd	ra,72(sp)
    80004d34:	e0a2                	sd	s0,64(sp)
    80004d36:	fc26                	sd	s1,56(sp)
    80004d38:	f84a                	sd	s2,48(sp)
    80004d3a:	f44e                	sd	s3,40(sp)
    80004d3c:	0880                	addi	s0,sp,80
    80004d3e:	84aa                	mv	s1,a0
    80004d40:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	fd2080e7          	jalr	-46(ra) # 80001d14 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d4a:	409c                	lw	a5,0(s1)
    80004d4c:	37f9                	addiw	a5,a5,-2
    80004d4e:	4705                	li	a4,1
    80004d50:	04f76763          	bltu	a4,a5,80004d9e <filestat+0x6e>
    80004d54:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d56:	6c88                	ld	a0,24(s1)
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	07c080e7          	jalr	124(ra) # 80003dd4 <ilock>
    stati(f->ip, &st);
    80004d60:	fb840593          	addi	a1,s0,-72
    80004d64:	6c88                	ld	a0,24(s1)
    80004d66:	fffff097          	auipc	ra,0xfffff
    80004d6a:	2f8080e7          	jalr	760(ra) # 8000405e <stati>
    iunlock(f->ip);
    80004d6e:	6c88                	ld	a0,24(s1)
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	126080e7          	jalr	294(ra) # 80003e96 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d78:	46e1                	li	a3,24
    80004d7a:	fb840613          	addi	a2,s0,-72
    80004d7e:	85ce                	mv	a1,s3
    80004d80:	05093503          	ld	a0,80(s2)
    80004d84:	ffffd097          	auipc	ra,0xffffd
    80004d88:	b52080e7          	jalr	-1198(ra) # 800018d6 <copyout>
    80004d8c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d90:	60a6                	ld	ra,72(sp)
    80004d92:	6406                	ld	s0,64(sp)
    80004d94:	74e2                	ld	s1,56(sp)
    80004d96:	7942                	ld	s2,48(sp)
    80004d98:	79a2                	ld	s3,40(sp)
    80004d9a:	6161                	addi	sp,sp,80
    80004d9c:	8082                	ret
  return -1;
    80004d9e:	557d                	li	a0,-1
    80004da0:	bfc5                	j	80004d90 <filestat+0x60>

0000000080004da2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004da2:	7179                	addi	sp,sp,-48
    80004da4:	f406                	sd	ra,40(sp)
    80004da6:	f022                	sd	s0,32(sp)
    80004da8:	ec26                	sd	s1,24(sp)
    80004daa:	e84a                	sd	s2,16(sp)
    80004dac:	e44e                	sd	s3,8(sp)
    80004dae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004db0:	00854783          	lbu	a5,8(a0)
    80004db4:	c3d5                	beqz	a5,80004e58 <fileread+0xb6>
    80004db6:	84aa                	mv	s1,a0
    80004db8:	89ae                	mv	s3,a1
    80004dba:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dbc:	411c                	lw	a5,0(a0)
    80004dbe:	4705                	li	a4,1
    80004dc0:	04e78963          	beq	a5,a4,80004e12 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dc4:	470d                	li	a4,3
    80004dc6:	04e78d63          	beq	a5,a4,80004e20 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dca:	4709                	li	a4,2
    80004dcc:	06e79e63          	bne	a5,a4,80004e48 <fileread+0xa6>
    ilock(f->ip);
    80004dd0:	6d08                	ld	a0,24(a0)
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	002080e7          	jalr	2(ra) # 80003dd4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004dda:	874a                	mv	a4,s2
    80004ddc:	5094                	lw	a3,32(s1)
    80004dde:	864e                	mv	a2,s3
    80004de0:	4585                	li	a1,1
    80004de2:	6c88                	ld	a0,24(s1)
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	2a4080e7          	jalr	676(ra) # 80004088 <readi>
    80004dec:	892a                	mv	s2,a0
    80004dee:	00a05563          	blez	a0,80004df8 <fileread+0x56>
      f->off += r;
    80004df2:	509c                	lw	a5,32(s1)
    80004df4:	9fa9                	addw	a5,a5,a0
    80004df6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004df8:	6c88                	ld	a0,24(s1)
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	09c080e7          	jalr	156(ra) # 80003e96 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e02:	854a                	mv	a0,s2
    80004e04:	70a2                	ld	ra,40(sp)
    80004e06:	7402                	ld	s0,32(sp)
    80004e08:	64e2                	ld	s1,24(sp)
    80004e0a:	6942                	ld	s2,16(sp)
    80004e0c:	69a2                	ld	s3,8(sp)
    80004e0e:	6145                	addi	sp,sp,48
    80004e10:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e12:	6908                	ld	a0,16(a0)
    80004e14:	00000097          	auipc	ra,0x0
    80004e18:	3c6080e7          	jalr	966(ra) # 800051da <piperead>
    80004e1c:	892a                	mv	s2,a0
    80004e1e:	b7d5                	j	80004e02 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e20:	02451783          	lh	a5,36(a0)
    80004e24:	03079693          	slli	a3,a5,0x30
    80004e28:	92c1                	srli	a3,a3,0x30
    80004e2a:	4725                	li	a4,9
    80004e2c:	02d76863          	bltu	a4,a3,80004e5c <fileread+0xba>
    80004e30:	0792                	slli	a5,a5,0x4
    80004e32:	0003c717          	auipc	a4,0x3c
    80004e36:	f4670713          	addi	a4,a4,-186 # 80040d78 <devsw>
    80004e3a:	97ba                	add	a5,a5,a4
    80004e3c:	639c                	ld	a5,0(a5)
    80004e3e:	c38d                	beqz	a5,80004e60 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e40:	4505                	li	a0,1
    80004e42:	9782                	jalr	a5
    80004e44:	892a                	mv	s2,a0
    80004e46:	bf75                	j	80004e02 <fileread+0x60>
    panic("fileread");
    80004e48:	00004517          	auipc	a0,0x4
    80004e4c:	9c850513          	addi	a0,a0,-1592 # 80008810 <syscalls+0x280>
    80004e50:	ffffb097          	auipc	ra,0xffffb
    80004e54:	6f0080e7          	jalr	1776(ra) # 80000540 <panic>
    return -1;
    80004e58:	597d                	li	s2,-1
    80004e5a:	b765                	j	80004e02 <fileread+0x60>
      return -1;
    80004e5c:	597d                	li	s2,-1
    80004e5e:	b755                	j	80004e02 <fileread+0x60>
    80004e60:	597d                	li	s2,-1
    80004e62:	b745                	j	80004e02 <fileread+0x60>

0000000080004e64 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e64:	715d                	addi	sp,sp,-80
    80004e66:	e486                	sd	ra,72(sp)
    80004e68:	e0a2                	sd	s0,64(sp)
    80004e6a:	fc26                	sd	s1,56(sp)
    80004e6c:	f84a                	sd	s2,48(sp)
    80004e6e:	f44e                	sd	s3,40(sp)
    80004e70:	f052                	sd	s4,32(sp)
    80004e72:	ec56                	sd	s5,24(sp)
    80004e74:	e85a                	sd	s6,16(sp)
    80004e76:	e45e                	sd	s7,8(sp)
    80004e78:	e062                	sd	s8,0(sp)
    80004e7a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e7c:	00954783          	lbu	a5,9(a0)
    80004e80:	10078663          	beqz	a5,80004f8c <filewrite+0x128>
    80004e84:	892a                	mv	s2,a0
    80004e86:	8b2e                	mv	s6,a1
    80004e88:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e8a:	411c                	lw	a5,0(a0)
    80004e8c:	4705                	li	a4,1
    80004e8e:	02e78263          	beq	a5,a4,80004eb2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e92:	470d                	li	a4,3
    80004e94:	02e78663          	beq	a5,a4,80004ec0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e98:	4709                	li	a4,2
    80004e9a:	0ee79163          	bne	a5,a4,80004f7c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e9e:	0ac05d63          	blez	a2,80004f58 <filewrite+0xf4>
    int i = 0;
    80004ea2:	4981                	li	s3,0
    80004ea4:	6b85                	lui	s7,0x1
    80004ea6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004eaa:	6c05                	lui	s8,0x1
    80004eac:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004eb0:	a861                	j	80004f48 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004eb2:	6908                	ld	a0,16(a0)
    80004eb4:	00000097          	auipc	ra,0x0
    80004eb8:	22e080e7          	jalr	558(ra) # 800050e2 <pipewrite>
    80004ebc:	8a2a                	mv	s4,a0
    80004ebe:	a045                	j	80004f5e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ec0:	02451783          	lh	a5,36(a0)
    80004ec4:	03079693          	slli	a3,a5,0x30
    80004ec8:	92c1                	srli	a3,a3,0x30
    80004eca:	4725                	li	a4,9
    80004ecc:	0cd76263          	bltu	a4,a3,80004f90 <filewrite+0x12c>
    80004ed0:	0792                	slli	a5,a5,0x4
    80004ed2:	0003c717          	auipc	a4,0x3c
    80004ed6:	ea670713          	addi	a4,a4,-346 # 80040d78 <devsw>
    80004eda:	97ba                	add	a5,a5,a4
    80004edc:	679c                	ld	a5,8(a5)
    80004ede:	cbdd                	beqz	a5,80004f94 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ee0:	4505                	li	a0,1
    80004ee2:	9782                	jalr	a5
    80004ee4:	8a2a                	mv	s4,a0
    80004ee6:	a8a5                	j	80004f5e <filewrite+0xfa>
    80004ee8:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004eec:	00000097          	auipc	ra,0x0
    80004ef0:	8b4080e7          	jalr	-1868(ra) # 800047a0 <begin_op>
      ilock(f->ip);
    80004ef4:	01893503          	ld	a0,24(s2)
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	edc080e7          	jalr	-292(ra) # 80003dd4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f00:	8756                	mv	a4,s5
    80004f02:	02092683          	lw	a3,32(s2)
    80004f06:	01698633          	add	a2,s3,s6
    80004f0a:	4585                	li	a1,1
    80004f0c:	01893503          	ld	a0,24(s2)
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	270080e7          	jalr	624(ra) # 80004180 <writei>
    80004f18:	84aa                	mv	s1,a0
    80004f1a:	00a05763          	blez	a0,80004f28 <filewrite+0xc4>
        f->off += r;
    80004f1e:	02092783          	lw	a5,32(s2)
    80004f22:	9fa9                	addw	a5,a5,a0
    80004f24:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f28:	01893503          	ld	a0,24(s2)
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	f6a080e7          	jalr	-150(ra) # 80003e96 <iunlock>
      end_op();
    80004f34:	00000097          	auipc	ra,0x0
    80004f38:	8ea080e7          	jalr	-1814(ra) # 8000481e <end_op>

      if(r != n1){
    80004f3c:	009a9f63          	bne	s5,s1,80004f5a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f40:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f44:	0149db63          	bge	s3,s4,80004f5a <filewrite+0xf6>
      int n1 = n - i;
    80004f48:	413a04bb          	subw	s1,s4,s3
    80004f4c:	0004879b          	sext.w	a5,s1
    80004f50:	f8fbdce3          	bge	s7,a5,80004ee8 <filewrite+0x84>
    80004f54:	84e2                	mv	s1,s8
    80004f56:	bf49                	j	80004ee8 <filewrite+0x84>
    int i = 0;
    80004f58:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f5a:	013a1f63          	bne	s4,s3,80004f78 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f5e:	8552                	mv	a0,s4
    80004f60:	60a6                	ld	ra,72(sp)
    80004f62:	6406                	ld	s0,64(sp)
    80004f64:	74e2                	ld	s1,56(sp)
    80004f66:	7942                	ld	s2,48(sp)
    80004f68:	79a2                	ld	s3,40(sp)
    80004f6a:	7a02                	ld	s4,32(sp)
    80004f6c:	6ae2                	ld	s5,24(sp)
    80004f6e:	6b42                	ld	s6,16(sp)
    80004f70:	6ba2                	ld	s7,8(sp)
    80004f72:	6c02                	ld	s8,0(sp)
    80004f74:	6161                	addi	sp,sp,80
    80004f76:	8082                	ret
    ret = (i == n ? n : -1);
    80004f78:	5a7d                	li	s4,-1
    80004f7a:	b7d5                	j	80004f5e <filewrite+0xfa>
    panic("filewrite");
    80004f7c:	00004517          	auipc	a0,0x4
    80004f80:	8a450513          	addi	a0,a0,-1884 # 80008820 <syscalls+0x290>
    80004f84:	ffffb097          	auipc	ra,0xffffb
    80004f88:	5bc080e7          	jalr	1468(ra) # 80000540 <panic>
    return -1;
    80004f8c:	5a7d                	li	s4,-1
    80004f8e:	bfc1                	j	80004f5e <filewrite+0xfa>
      return -1;
    80004f90:	5a7d                	li	s4,-1
    80004f92:	b7f1                	j	80004f5e <filewrite+0xfa>
    80004f94:	5a7d                	li	s4,-1
    80004f96:	b7e1                	j	80004f5e <filewrite+0xfa>

0000000080004f98 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f98:	7179                	addi	sp,sp,-48
    80004f9a:	f406                	sd	ra,40(sp)
    80004f9c:	f022                	sd	s0,32(sp)
    80004f9e:	ec26                	sd	s1,24(sp)
    80004fa0:	e84a                	sd	s2,16(sp)
    80004fa2:	e44e                	sd	s3,8(sp)
    80004fa4:	e052                	sd	s4,0(sp)
    80004fa6:	1800                	addi	s0,sp,48
    80004fa8:	84aa                	mv	s1,a0
    80004faa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fac:	0005b023          	sd	zero,0(a1)
    80004fb0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fb4:	00000097          	auipc	ra,0x0
    80004fb8:	bf8080e7          	jalr	-1032(ra) # 80004bac <filealloc>
    80004fbc:	e088                	sd	a0,0(s1)
    80004fbe:	c551                	beqz	a0,8000504a <pipealloc+0xb2>
    80004fc0:	00000097          	auipc	ra,0x0
    80004fc4:	bec080e7          	jalr	-1044(ra) # 80004bac <filealloc>
    80004fc8:	00aa3023          	sd	a0,0(s4)
    80004fcc:	c92d                	beqz	a0,8000503e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	b94080e7          	jalr	-1132(ra) # 80000b62 <kalloc>
    80004fd6:	892a                	mv	s2,a0
    80004fd8:	c125                	beqz	a0,80005038 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fda:	4985                	li	s3,1
    80004fdc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fe0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fe4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fe8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fec:	00004597          	auipc	a1,0x4
    80004ff0:	84458593          	addi	a1,a1,-1980 # 80008830 <syscalls+0x2a0>
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	cde080e7          	jalr	-802(ra) # 80000cd2 <initlock>
  (*f0)->type = FD_PIPE;
    80004ffc:	609c                	ld	a5,0(s1)
    80004ffe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005002:	609c                	ld	a5,0(s1)
    80005004:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005008:	609c                	ld	a5,0(s1)
    8000500a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000500e:	609c                	ld	a5,0(s1)
    80005010:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005014:	000a3783          	ld	a5,0(s4)
    80005018:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000501c:	000a3783          	ld	a5,0(s4)
    80005020:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005024:	000a3783          	ld	a5,0(s4)
    80005028:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000502c:	000a3783          	ld	a5,0(s4)
    80005030:	0127b823          	sd	s2,16(a5)
  return 0;
    80005034:	4501                	li	a0,0
    80005036:	a025                	j	8000505e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005038:	6088                	ld	a0,0(s1)
    8000503a:	e501                	bnez	a0,80005042 <pipealloc+0xaa>
    8000503c:	a039                	j	8000504a <pipealloc+0xb2>
    8000503e:	6088                	ld	a0,0(s1)
    80005040:	c51d                	beqz	a0,8000506e <pipealloc+0xd6>
    fileclose(*f0);
    80005042:	00000097          	auipc	ra,0x0
    80005046:	c26080e7          	jalr	-986(ra) # 80004c68 <fileclose>
  if(*f1)
    8000504a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000504e:	557d                	li	a0,-1
  if(*f1)
    80005050:	c799                	beqz	a5,8000505e <pipealloc+0xc6>
    fileclose(*f1);
    80005052:	853e                	mv	a0,a5
    80005054:	00000097          	auipc	ra,0x0
    80005058:	c14080e7          	jalr	-1004(ra) # 80004c68 <fileclose>
  return -1;
    8000505c:	557d                	li	a0,-1
}
    8000505e:	70a2                	ld	ra,40(sp)
    80005060:	7402                	ld	s0,32(sp)
    80005062:	64e2                	ld	s1,24(sp)
    80005064:	6942                	ld	s2,16(sp)
    80005066:	69a2                	ld	s3,8(sp)
    80005068:	6a02                	ld	s4,0(sp)
    8000506a:	6145                	addi	sp,sp,48
    8000506c:	8082                	ret
  return -1;
    8000506e:	557d                	li	a0,-1
    80005070:	b7fd                	j	8000505e <pipealloc+0xc6>

0000000080005072 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005072:	1101                	addi	sp,sp,-32
    80005074:	ec06                	sd	ra,24(sp)
    80005076:	e822                	sd	s0,16(sp)
    80005078:	e426                	sd	s1,8(sp)
    8000507a:	e04a                	sd	s2,0(sp)
    8000507c:	1000                	addi	s0,sp,32
    8000507e:	84aa                	mv	s1,a0
    80005080:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	ce0080e7          	jalr	-800(ra) # 80000d62 <acquire>
  if(writable){
    8000508a:	02090d63          	beqz	s2,800050c4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000508e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005092:	21848513          	addi	a0,s1,536
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	490080e7          	jalr	1168(ra) # 80002526 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000509e:	2204b783          	ld	a5,544(s1)
    800050a2:	eb95                	bnez	a5,800050d6 <pipeclose+0x64>
    release(&pi->lock);
    800050a4:	8526                	mv	a0,s1
    800050a6:	ffffc097          	auipc	ra,0xffffc
    800050aa:	d70080e7          	jalr	-656(ra) # 80000e16 <release>
    kfree((char*)pi);
    800050ae:	8526                	mv	a0,s1
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	94a080e7          	jalr	-1718(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    800050b8:	60e2                	ld	ra,24(sp)
    800050ba:	6442                	ld	s0,16(sp)
    800050bc:	64a2                	ld	s1,8(sp)
    800050be:	6902                	ld	s2,0(sp)
    800050c0:	6105                	addi	sp,sp,32
    800050c2:	8082                	ret
    pi->readopen = 0;
    800050c4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050c8:	21c48513          	addi	a0,s1,540
    800050cc:	ffffd097          	auipc	ra,0xffffd
    800050d0:	45a080e7          	jalr	1114(ra) # 80002526 <wakeup>
    800050d4:	b7e9                	j	8000509e <pipeclose+0x2c>
    release(&pi->lock);
    800050d6:	8526                	mv	a0,s1
    800050d8:	ffffc097          	auipc	ra,0xffffc
    800050dc:	d3e080e7          	jalr	-706(ra) # 80000e16 <release>
}
    800050e0:	bfe1                	j	800050b8 <pipeclose+0x46>

00000000800050e2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050e2:	711d                	addi	sp,sp,-96
    800050e4:	ec86                	sd	ra,88(sp)
    800050e6:	e8a2                	sd	s0,80(sp)
    800050e8:	e4a6                	sd	s1,72(sp)
    800050ea:	e0ca                	sd	s2,64(sp)
    800050ec:	fc4e                	sd	s3,56(sp)
    800050ee:	f852                	sd	s4,48(sp)
    800050f0:	f456                	sd	s5,40(sp)
    800050f2:	f05a                	sd	s6,32(sp)
    800050f4:	ec5e                	sd	s7,24(sp)
    800050f6:	e862                	sd	s8,16(sp)
    800050f8:	1080                	addi	s0,sp,96
    800050fa:	84aa                	mv	s1,a0
    800050fc:	8aae                	mv	s5,a1
    800050fe:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005100:	ffffd097          	auipc	ra,0xffffd
    80005104:	c14080e7          	jalr	-1004(ra) # 80001d14 <myproc>
    80005108:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000510a:	8526                	mv	a0,s1
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	c56080e7          	jalr	-938(ra) # 80000d62 <acquire>
  while(i < n){
    80005114:	0b405663          	blez	s4,800051c0 <pipewrite+0xde>
  int i = 0;
    80005118:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000511a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000511c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005120:	21c48b93          	addi	s7,s1,540
    80005124:	a089                	j	80005166 <pipewrite+0x84>
      release(&pi->lock);
    80005126:	8526                	mv	a0,s1
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	cee080e7          	jalr	-786(ra) # 80000e16 <release>
      return -1;
    80005130:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005132:	854a                	mv	a0,s2
    80005134:	60e6                	ld	ra,88(sp)
    80005136:	6446                	ld	s0,80(sp)
    80005138:	64a6                	ld	s1,72(sp)
    8000513a:	6906                	ld	s2,64(sp)
    8000513c:	79e2                	ld	s3,56(sp)
    8000513e:	7a42                	ld	s4,48(sp)
    80005140:	7aa2                	ld	s5,40(sp)
    80005142:	7b02                	ld	s6,32(sp)
    80005144:	6be2                	ld	s7,24(sp)
    80005146:	6c42                	ld	s8,16(sp)
    80005148:	6125                	addi	sp,sp,96
    8000514a:	8082                	ret
      wakeup(&pi->nread);
    8000514c:	8562                	mv	a0,s8
    8000514e:	ffffd097          	auipc	ra,0xffffd
    80005152:	3d8080e7          	jalr	984(ra) # 80002526 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005156:	85a6                	mv	a1,s1
    80005158:	855e                	mv	a0,s7
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	368080e7          	jalr	872(ra) # 800024c2 <sleep>
  while(i < n){
    80005162:	07495063          	bge	s2,s4,800051c2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005166:	2204a783          	lw	a5,544(s1)
    8000516a:	dfd5                	beqz	a5,80005126 <pipewrite+0x44>
    8000516c:	854e                	mv	a0,s3
    8000516e:	ffffd097          	auipc	ra,0xffffd
    80005172:	5fc080e7          	jalr	1532(ra) # 8000276a <killed>
    80005176:	f945                	bnez	a0,80005126 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005178:	2184a783          	lw	a5,536(s1)
    8000517c:	21c4a703          	lw	a4,540(s1)
    80005180:	2007879b          	addiw	a5,a5,512
    80005184:	fcf704e3          	beq	a4,a5,8000514c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005188:	4685                	li	a3,1
    8000518a:	01590633          	add	a2,s2,s5
    8000518e:	faf40593          	addi	a1,s0,-81
    80005192:	0509b503          	ld	a0,80(s3)
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	7cc080e7          	jalr	1996(ra) # 80001962 <copyin>
    8000519e:	03650263          	beq	a0,s6,800051c2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051a2:	21c4a783          	lw	a5,540(s1)
    800051a6:	0017871b          	addiw	a4,a5,1
    800051aa:	20e4ae23          	sw	a4,540(s1)
    800051ae:	1ff7f793          	andi	a5,a5,511
    800051b2:	97a6                	add	a5,a5,s1
    800051b4:	faf44703          	lbu	a4,-81(s0)
    800051b8:	00e78c23          	sb	a4,24(a5)
      i++;
    800051bc:	2905                	addiw	s2,s2,1
    800051be:	b755                	j	80005162 <pipewrite+0x80>
  int i = 0;
    800051c0:	4901                	li	s2,0
  wakeup(&pi->nread);
    800051c2:	21848513          	addi	a0,s1,536
    800051c6:	ffffd097          	auipc	ra,0xffffd
    800051ca:	360080e7          	jalr	864(ra) # 80002526 <wakeup>
  release(&pi->lock);
    800051ce:	8526                	mv	a0,s1
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	c46080e7          	jalr	-954(ra) # 80000e16 <release>
  return i;
    800051d8:	bfa9                	j	80005132 <pipewrite+0x50>

00000000800051da <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051da:	715d                	addi	sp,sp,-80
    800051dc:	e486                	sd	ra,72(sp)
    800051de:	e0a2                	sd	s0,64(sp)
    800051e0:	fc26                	sd	s1,56(sp)
    800051e2:	f84a                	sd	s2,48(sp)
    800051e4:	f44e                	sd	s3,40(sp)
    800051e6:	f052                	sd	s4,32(sp)
    800051e8:	ec56                	sd	s5,24(sp)
    800051ea:	e85a                	sd	s6,16(sp)
    800051ec:	0880                	addi	s0,sp,80
    800051ee:	84aa                	mv	s1,a0
    800051f0:	892e                	mv	s2,a1
    800051f2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051f4:	ffffd097          	auipc	ra,0xffffd
    800051f8:	b20080e7          	jalr	-1248(ra) # 80001d14 <myproc>
    800051fc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051fe:	8526                	mv	a0,s1
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	b62080e7          	jalr	-1182(ra) # 80000d62 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005208:	2184a703          	lw	a4,536(s1)
    8000520c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005210:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005214:	02f71763          	bne	a4,a5,80005242 <piperead+0x68>
    80005218:	2244a783          	lw	a5,548(s1)
    8000521c:	c39d                	beqz	a5,80005242 <piperead+0x68>
    if(killed(pr)){
    8000521e:	8552                	mv	a0,s4
    80005220:	ffffd097          	auipc	ra,0xffffd
    80005224:	54a080e7          	jalr	1354(ra) # 8000276a <killed>
    80005228:	e949                	bnez	a0,800052ba <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000522a:	85a6                	mv	a1,s1
    8000522c:	854e                	mv	a0,s3
    8000522e:	ffffd097          	auipc	ra,0xffffd
    80005232:	294080e7          	jalr	660(ra) # 800024c2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005236:	2184a703          	lw	a4,536(s1)
    8000523a:	21c4a783          	lw	a5,540(s1)
    8000523e:	fcf70de3          	beq	a4,a5,80005218 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005242:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005244:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005246:	05505463          	blez	s5,8000528e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000524a:	2184a783          	lw	a5,536(s1)
    8000524e:	21c4a703          	lw	a4,540(s1)
    80005252:	02f70e63          	beq	a4,a5,8000528e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005256:	0017871b          	addiw	a4,a5,1
    8000525a:	20e4ac23          	sw	a4,536(s1)
    8000525e:	1ff7f793          	andi	a5,a5,511
    80005262:	97a6                	add	a5,a5,s1
    80005264:	0187c783          	lbu	a5,24(a5)
    80005268:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000526c:	4685                	li	a3,1
    8000526e:	fbf40613          	addi	a2,s0,-65
    80005272:	85ca                	mv	a1,s2
    80005274:	050a3503          	ld	a0,80(s4)
    80005278:	ffffc097          	auipc	ra,0xffffc
    8000527c:	65e080e7          	jalr	1630(ra) # 800018d6 <copyout>
    80005280:	01650763          	beq	a0,s6,8000528e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005284:	2985                	addiw	s3,s3,1
    80005286:	0905                	addi	s2,s2,1
    80005288:	fd3a91e3          	bne	s5,s3,8000524a <piperead+0x70>
    8000528c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000528e:	21c48513          	addi	a0,s1,540
    80005292:	ffffd097          	auipc	ra,0xffffd
    80005296:	294080e7          	jalr	660(ra) # 80002526 <wakeup>
  release(&pi->lock);
    8000529a:	8526                	mv	a0,s1
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	b7a080e7          	jalr	-1158(ra) # 80000e16 <release>
  return i;
}
    800052a4:	854e                	mv	a0,s3
    800052a6:	60a6                	ld	ra,72(sp)
    800052a8:	6406                	ld	s0,64(sp)
    800052aa:	74e2                	ld	s1,56(sp)
    800052ac:	7942                	ld	s2,48(sp)
    800052ae:	79a2                	ld	s3,40(sp)
    800052b0:	7a02                	ld	s4,32(sp)
    800052b2:	6ae2                	ld	s5,24(sp)
    800052b4:	6b42                	ld	s6,16(sp)
    800052b6:	6161                	addi	sp,sp,80
    800052b8:	8082                	ret
      release(&pi->lock);
    800052ba:	8526                	mv	a0,s1
    800052bc:	ffffc097          	auipc	ra,0xffffc
    800052c0:	b5a080e7          	jalr	-1190(ra) # 80000e16 <release>
      return -1;
    800052c4:	59fd                	li	s3,-1
    800052c6:	bff9                	j	800052a4 <piperead+0xca>

00000000800052c8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800052c8:	1141                	addi	sp,sp,-16
    800052ca:	e422                	sd	s0,8(sp)
    800052cc:	0800                	addi	s0,sp,16
    800052ce:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800052d0:	8905                	andi	a0,a0,1
    800052d2:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800052d4:	8b89                	andi	a5,a5,2
    800052d6:	c399                	beqz	a5,800052dc <flags2perm+0x14>
      perm |= PTE_W;
    800052d8:	00456513          	ori	a0,a0,4
    return perm;
}
    800052dc:	6422                	ld	s0,8(sp)
    800052de:	0141                	addi	sp,sp,16
    800052e0:	8082                	ret

00000000800052e2 <exec>:

int
exec(char *path, char **argv)
{
    800052e2:	de010113          	addi	sp,sp,-544
    800052e6:	20113c23          	sd	ra,536(sp)
    800052ea:	20813823          	sd	s0,528(sp)
    800052ee:	20913423          	sd	s1,520(sp)
    800052f2:	21213023          	sd	s2,512(sp)
    800052f6:	ffce                	sd	s3,504(sp)
    800052f8:	fbd2                	sd	s4,496(sp)
    800052fa:	f7d6                	sd	s5,488(sp)
    800052fc:	f3da                	sd	s6,480(sp)
    800052fe:	efde                	sd	s7,472(sp)
    80005300:	ebe2                	sd	s8,464(sp)
    80005302:	e7e6                	sd	s9,456(sp)
    80005304:	e3ea                	sd	s10,448(sp)
    80005306:	ff6e                	sd	s11,440(sp)
    80005308:	1400                	addi	s0,sp,544
    8000530a:	892a                	mv	s2,a0
    8000530c:	dea43423          	sd	a0,-536(s0)
    80005310:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005314:	ffffd097          	auipc	ra,0xffffd
    80005318:	a00080e7          	jalr	-1536(ra) # 80001d14 <myproc>
    8000531c:	84aa                	mv	s1,a0

  begin_op();
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	482080e7          	jalr	1154(ra) # 800047a0 <begin_op>

  if((ip = namei(path)) == 0){
    80005326:	854a                	mv	a0,s2
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	258080e7          	jalr	600(ra) # 80004580 <namei>
    80005330:	c93d                	beqz	a0,800053a6 <exec+0xc4>
    80005332:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	aa0080e7          	jalr	-1376(ra) # 80003dd4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000533c:	04000713          	li	a4,64
    80005340:	4681                	li	a3,0
    80005342:	e5040613          	addi	a2,s0,-432
    80005346:	4581                	li	a1,0
    80005348:	8556                	mv	a0,s5
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	d3e080e7          	jalr	-706(ra) # 80004088 <readi>
    80005352:	04000793          	li	a5,64
    80005356:	00f51a63          	bne	a0,a5,8000536a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000535a:	e5042703          	lw	a4,-432(s0)
    8000535e:	464c47b7          	lui	a5,0x464c4
    80005362:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005366:	04f70663          	beq	a4,a5,800053b2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000536a:	8556                	mv	a0,s5
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	cca080e7          	jalr	-822(ra) # 80004036 <iunlockput>
    end_op();
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	4aa080e7          	jalr	1194(ra) # 8000481e <end_op>
  }
  return -1;
    8000537c:	557d                	li	a0,-1
}
    8000537e:	21813083          	ld	ra,536(sp)
    80005382:	21013403          	ld	s0,528(sp)
    80005386:	20813483          	ld	s1,520(sp)
    8000538a:	20013903          	ld	s2,512(sp)
    8000538e:	79fe                	ld	s3,504(sp)
    80005390:	7a5e                	ld	s4,496(sp)
    80005392:	7abe                	ld	s5,488(sp)
    80005394:	7b1e                	ld	s6,480(sp)
    80005396:	6bfe                	ld	s7,472(sp)
    80005398:	6c5e                	ld	s8,464(sp)
    8000539a:	6cbe                	ld	s9,456(sp)
    8000539c:	6d1e                	ld	s10,448(sp)
    8000539e:	7dfa                	ld	s11,440(sp)
    800053a0:	22010113          	addi	sp,sp,544
    800053a4:	8082                	ret
    end_op();
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	478080e7          	jalr	1144(ra) # 8000481e <end_op>
    return -1;
    800053ae:	557d                	li	a0,-1
    800053b0:	b7f9                	j	8000537e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800053b2:	8526                	mv	a0,s1
    800053b4:	ffffd097          	auipc	ra,0xffffd
    800053b8:	a24080e7          	jalr	-1500(ra) # 80001dd8 <proc_pagetable>
    800053bc:	8b2a                	mv	s6,a0
    800053be:	d555                	beqz	a0,8000536a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053c0:	e7042783          	lw	a5,-400(s0)
    800053c4:	e8845703          	lhu	a4,-376(s0)
    800053c8:	c735                	beqz	a4,80005434 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ca:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053cc:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800053d0:	6a05                	lui	s4,0x1
    800053d2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800053d6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800053da:	6d85                	lui	s11,0x1
    800053dc:	7d7d                	lui	s10,0xfffff
    800053de:	ac3d                	j	8000561c <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053e0:	00003517          	auipc	a0,0x3
    800053e4:	45850513          	addi	a0,a0,1112 # 80008838 <syscalls+0x2a8>
    800053e8:	ffffb097          	auipc	ra,0xffffb
    800053ec:	158080e7          	jalr	344(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053f0:	874a                	mv	a4,s2
    800053f2:	009c86bb          	addw	a3,s9,s1
    800053f6:	4581                	li	a1,0
    800053f8:	8556                	mv	a0,s5
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	c8e080e7          	jalr	-882(ra) # 80004088 <readi>
    80005402:	2501                	sext.w	a0,a0
    80005404:	1aa91963          	bne	s2,a0,800055b6 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005408:	009d84bb          	addw	s1,s11,s1
    8000540c:	013d09bb          	addw	s3,s10,s3
    80005410:	1f74f663          	bgeu	s1,s7,800055fc <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005414:	02049593          	slli	a1,s1,0x20
    80005418:	9181                	srli	a1,a1,0x20
    8000541a:	95e2                	add	a1,a1,s8
    8000541c:	855a                	mv	a0,s6
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	dca080e7          	jalr	-566(ra) # 800011e8 <walkaddr>
    80005426:	862a                	mv	a2,a0
    if(pa == 0)
    80005428:	dd45                	beqz	a0,800053e0 <exec+0xfe>
      n = PGSIZE;
    8000542a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000542c:	fd49f2e3          	bgeu	s3,s4,800053f0 <exec+0x10e>
      n = sz - i;
    80005430:	894e                	mv	s2,s3
    80005432:	bf7d                	j	800053f0 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005434:	4901                	li	s2,0
  iunlockput(ip);
    80005436:	8556                	mv	a0,s5
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	bfe080e7          	jalr	-1026(ra) # 80004036 <iunlockput>
  end_op();
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	3de080e7          	jalr	990(ra) # 8000481e <end_op>
  p = myproc();
    80005448:	ffffd097          	auipc	ra,0xffffd
    8000544c:	8cc080e7          	jalr	-1844(ra) # 80001d14 <myproc>
    80005450:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005452:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005456:	6785                	lui	a5,0x1
    80005458:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000545a:	97ca                	add	a5,a5,s2
    8000545c:	777d                	lui	a4,0xfffff
    8000545e:	8ff9                	and	a5,a5,a4
    80005460:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005464:	4691                	li	a3,4
    80005466:	6609                	lui	a2,0x2
    80005468:	963e                	add	a2,a2,a5
    8000546a:	85be                	mv	a1,a5
    8000546c:	855a                	mv	a0,s6
    8000546e:	ffffc097          	auipc	ra,0xffffc
    80005472:	12e080e7          	jalr	302(ra) # 8000159c <uvmalloc>
    80005476:	8c2a                	mv	s8,a0
  ip = 0;
    80005478:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000547a:	12050e63          	beqz	a0,800055b6 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000547e:	75f9                	lui	a1,0xffffe
    80005480:	95aa                	add	a1,a1,a0
    80005482:	855a                	mv	a0,s6
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	420080e7          	jalr	1056(ra) # 800018a4 <uvmclear>
  stackbase = sp - PGSIZE;
    8000548c:	7afd                	lui	s5,0xfffff
    8000548e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005490:	df043783          	ld	a5,-528(s0)
    80005494:	6388                	ld	a0,0(a5)
    80005496:	c925                	beqz	a0,80005506 <exec+0x224>
    80005498:	e9040993          	addi	s3,s0,-368
    8000549c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054a0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054a2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	b36080e7          	jalr	-1226(ra) # 80000fda <strlen>
    800054ac:	0015079b          	addiw	a5,a0,1
    800054b0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054b4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800054b8:	13596663          	bltu	s2,s5,800055e4 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054bc:	df043d83          	ld	s11,-528(s0)
    800054c0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800054c4:	8552                	mv	a0,s4
    800054c6:	ffffc097          	auipc	ra,0xffffc
    800054ca:	b14080e7          	jalr	-1260(ra) # 80000fda <strlen>
    800054ce:	0015069b          	addiw	a3,a0,1
    800054d2:	8652                	mv	a2,s4
    800054d4:	85ca                	mv	a1,s2
    800054d6:	855a                	mv	a0,s6
    800054d8:	ffffc097          	auipc	ra,0xffffc
    800054dc:	3fe080e7          	jalr	1022(ra) # 800018d6 <copyout>
    800054e0:	10054663          	bltz	a0,800055ec <exec+0x30a>
    ustack[argc] = sp;
    800054e4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054e8:	0485                	addi	s1,s1,1
    800054ea:	008d8793          	addi	a5,s11,8
    800054ee:	def43823          	sd	a5,-528(s0)
    800054f2:	008db503          	ld	a0,8(s11)
    800054f6:	c911                	beqz	a0,8000550a <exec+0x228>
    if(argc >= MAXARG)
    800054f8:	09a1                	addi	s3,s3,8
    800054fa:	fb3c95e3          	bne	s9,s3,800054a4 <exec+0x1c2>
  sz = sz1;
    800054fe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005502:	4a81                	li	s5,0
    80005504:	a84d                	j	800055b6 <exec+0x2d4>
  sp = sz;
    80005506:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005508:	4481                	li	s1,0
  ustack[argc] = 0;
    8000550a:	00349793          	slli	a5,s1,0x3
    8000550e:	f9078793          	addi	a5,a5,-112
    80005512:	97a2                	add	a5,a5,s0
    80005514:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005518:	00148693          	addi	a3,s1,1
    8000551c:	068e                	slli	a3,a3,0x3
    8000551e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005522:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005526:	01597663          	bgeu	s2,s5,80005532 <exec+0x250>
  sz = sz1;
    8000552a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000552e:	4a81                	li	s5,0
    80005530:	a059                	j	800055b6 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005532:	e9040613          	addi	a2,s0,-368
    80005536:	85ca                	mv	a1,s2
    80005538:	855a                	mv	a0,s6
    8000553a:	ffffc097          	auipc	ra,0xffffc
    8000553e:	39c080e7          	jalr	924(ra) # 800018d6 <copyout>
    80005542:	0a054963          	bltz	a0,800055f4 <exec+0x312>
  p->trapframe->a1 = sp;
    80005546:	058bb783          	ld	a5,88(s7)
    8000554a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000554e:	de843783          	ld	a5,-536(s0)
    80005552:	0007c703          	lbu	a4,0(a5)
    80005556:	cf11                	beqz	a4,80005572 <exec+0x290>
    80005558:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000555a:	02f00693          	li	a3,47
    8000555e:	a039                	j	8000556c <exec+0x28a>
      last = s+1;
    80005560:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005564:	0785                	addi	a5,a5,1
    80005566:	fff7c703          	lbu	a4,-1(a5)
    8000556a:	c701                	beqz	a4,80005572 <exec+0x290>
    if(*s == '/')
    8000556c:	fed71ce3          	bne	a4,a3,80005564 <exec+0x282>
    80005570:	bfc5                	j	80005560 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005572:	4641                	li	a2,16
    80005574:	de843583          	ld	a1,-536(s0)
    80005578:	158b8513          	addi	a0,s7,344
    8000557c:	ffffc097          	auipc	ra,0xffffc
    80005580:	a2c080e7          	jalr	-1492(ra) # 80000fa8 <safestrcpy>
  oldpagetable = p->pagetable;
    80005584:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005588:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000558c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005590:	058bb783          	ld	a5,88(s7)
    80005594:	e6843703          	ld	a4,-408(s0)
    80005598:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000559a:	058bb783          	ld	a5,88(s7)
    8000559e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055a2:	85ea                	mv	a1,s10
    800055a4:	ffffd097          	auipc	ra,0xffffd
    800055a8:	8d0080e7          	jalr	-1840(ra) # 80001e74 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055ac:	0004851b          	sext.w	a0,s1
    800055b0:	b3f9                	j	8000537e <exec+0x9c>
    800055b2:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800055b6:	df843583          	ld	a1,-520(s0)
    800055ba:	855a                	mv	a0,s6
    800055bc:	ffffd097          	auipc	ra,0xffffd
    800055c0:	8b8080e7          	jalr	-1864(ra) # 80001e74 <proc_freepagetable>
  if(ip){
    800055c4:	da0a93e3          	bnez	s5,8000536a <exec+0x88>
  return -1;
    800055c8:	557d                	li	a0,-1
    800055ca:	bb55                	j	8000537e <exec+0x9c>
    800055cc:	df243c23          	sd	s2,-520(s0)
    800055d0:	b7dd                	j	800055b6 <exec+0x2d4>
    800055d2:	df243c23          	sd	s2,-520(s0)
    800055d6:	b7c5                	j	800055b6 <exec+0x2d4>
    800055d8:	df243c23          	sd	s2,-520(s0)
    800055dc:	bfe9                	j	800055b6 <exec+0x2d4>
    800055de:	df243c23          	sd	s2,-520(s0)
    800055e2:	bfd1                	j	800055b6 <exec+0x2d4>
  sz = sz1;
    800055e4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055e8:	4a81                	li	s5,0
    800055ea:	b7f1                	j	800055b6 <exec+0x2d4>
  sz = sz1;
    800055ec:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055f0:	4a81                	li	s5,0
    800055f2:	b7d1                	j	800055b6 <exec+0x2d4>
  sz = sz1;
    800055f4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055f8:	4a81                	li	s5,0
    800055fa:	bf75                	j	800055b6 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055fc:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005600:	e0843783          	ld	a5,-504(s0)
    80005604:	0017869b          	addiw	a3,a5,1
    80005608:	e0d43423          	sd	a3,-504(s0)
    8000560c:	e0043783          	ld	a5,-512(s0)
    80005610:	0387879b          	addiw	a5,a5,56
    80005614:	e8845703          	lhu	a4,-376(s0)
    80005618:	e0e6dfe3          	bge	a3,a4,80005436 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000561c:	2781                	sext.w	a5,a5
    8000561e:	e0f43023          	sd	a5,-512(s0)
    80005622:	03800713          	li	a4,56
    80005626:	86be                	mv	a3,a5
    80005628:	e1840613          	addi	a2,s0,-488
    8000562c:	4581                	li	a1,0
    8000562e:	8556                	mv	a0,s5
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	a58080e7          	jalr	-1448(ra) # 80004088 <readi>
    80005638:	03800793          	li	a5,56
    8000563c:	f6f51be3          	bne	a0,a5,800055b2 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005640:	e1842783          	lw	a5,-488(s0)
    80005644:	4705                	li	a4,1
    80005646:	fae79de3          	bne	a5,a4,80005600 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000564a:	e4043483          	ld	s1,-448(s0)
    8000564e:	e3843783          	ld	a5,-456(s0)
    80005652:	f6f4ede3          	bltu	s1,a5,800055cc <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005656:	e2843783          	ld	a5,-472(s0)
    8000565a:	94be                	add	s1,s1,a5
    8000565c:	f6f4ebe3          	bltu	s1,a5,800055d2 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005660:	de043703          	ld	a4,-544(s0)
    80005664:	8ff9                	and	a5,a5,a4
    80005666:	fbad                	bnez	a5,800055d8 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005668:	e1c42503          	lw	a0,-484(s0)
    8000566c:	00000097          	auipc	ra,0x0
    80005670:	c5c080e7          	jalr	-932(ra) # 800052c8 <flags2perm>
    80005674:	86aa                	mv	a3,a0
    80005676:	8626                	mv	a2,s1
    80005678:	85ca                	mv	a1,s2
    8000567a:	855a                	mv	a0,s6
    8000567c:	ffffc097          	auipc	ra,0xffffc
    80005680:	f20080e7          	jalr	-224(ra) # 8000159c <uvmalloc>
    80005684:	dea43c23          	sd	a0,-520(s0)
    80005688:	d939                	beqz	a0,800055de <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000568a:	e2843c03          	ld	s8,-472(s0)
    8000568e:	e2042c83          	lw	s9,-480(s0)
    80005692:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005696:	f60b83e3          	beqz	s7,800055fc <exec+0x31a>
    8000569a:	89de                	mv	s3,s7
    8000569c:	4481                	li	s1,0
    8000569e:	bb9d                	j	80005414 <exec+0x132>

00000000800056a0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056a0:	7179                	addi	sp,sp,-48
    800056a2:	f406                	sd	ra,40(sp)
    800056a4:	f022                	sd	s0,32(sp)
    800056a6:	ec26                	sd	s1,24(sp)
    800056a8:	e84a                	sd	s2,16(sp)
    800056aa:	1800                	addi	s0,sp,48
    800056ac:	892e                	mv	s2,a1
    800056ae:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800056b0:	fdc40593          	addi	a1,s0,-36
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	a6a080e7          	jalr	-1430(ra) # 8000311e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056bc:	fdc42703          	lw	a4,-36(s0)
    800056c0:	47bd                	li	a5,15
    800056c2:	02e7eb63          	bltu	a5,a4,800056f8 <argfd+0x58>
    800056c6:	ffffc097          	auipc	ra,0xffffc
    800056ca:	64e080e7          	jalr	1614(ra) # 80001d14 <myproc>
    800056ce:	fdc42703          	lw	a4,-36(s0)
    800056d2:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffbd10a>
    800056d6:	078e                	slli	a5,a5,0x3
    800056d8:	953e                	add	a0,a0,a5
    800056da:	611c                	ld	a5,0(a0)
    800056dc:	c385                	beqz	a5,800056fc <argfd+0x5c>
    return -1;
  if(pfd)
    800056de:	00090463          	beqz	s2,800056e6 <argfd+0x46>
    *pfd = fd;
    800056e2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056e6:	4501                	li	a0,0
  if(pf)
    800056e8:	c091                	beqz	s1,800056ec <argfd+0x4c>
    *pf = f;
    800056ea:	e09c                	sd	a5,0(s1)
}
    800056ec:	70a2                	ld	ra,40(sp)
    800056ee:	7402                	ld	s0,32(sp)
    800056f0:	64e2                	ld	s1,24(sp)
    800056f2:	6942                	ld	s2,16(sp)
    800056f4:	6145                	addi	sp,sp,48
    800056f6:	8082                	ret
    return -1;
    800056f8:	557d                	li	a0,-1
    800056fa:	bfcd                	j	800056ec <argfd+0x4c>
    800056fc:	557d                	li	a0,-1
    800056fe:	b7fd                	j	800056ec <argfd+0x4c>

0000000080005700 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005700:	1101                	addi	sp,sp,-32
    80005702:	ec06                	sd	ra,24(sp)
    80005704:	e822                	sd	s0,16(sp)
    80005706:	e426                	sd	s1,8(sp)
    80005708:	1000                	addi	s0,sp,32
    8000570a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000570c:	ffffc097          	auipc	ra,0xffffc
    80005710:	608080e7          	jalr	1544(ra) # 80001d14 <myproc>
    80005714:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005716:	0d050793          	addi	a5,a0,208
    8000571a:	4501                	li	a0,0
    8000571c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000571e:	6398                	ld	a4,0(a5)
    80005720:	cb19                	beqz	a4,80005736 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005722:	2505                	addiw	a0,a0,1
    80005724:	07a1                	addi	a5,a5,8
    80005726:	fed51ce3          	bne	a0,a3,8000571e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000572a:	557d                	li	a0,-1
}
    8000572c:	60e2                	ld	ra,24(sp)
    8000572e:	6442                	ld	s0,16(sp)
    80005730:	64a2                	ld	s1,8(sp)
    80005732:	6105                	addi	sp,sp,32
    80005734:	8082                	ret
      p->ofile[fd] = f;
    80005736:	01a50793          	addi	a5,a0,26
    8000573a:	078e                	slli	a5,a5,0x3
    8000573c:	963e                	add	a2,a2,a5
    8000573e:	e204                	sd	s1,0(a2)
      return fd;
    80005740:	b7f5                	j	8000572c <fdalloc+0x2c>

0000000080005742 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005742:	715d                	addi	sp,sp,-80
    80005744:	e486                	sd	ra,72(sp)
    80005746:	e0a2                	sd	s0,64(sp)
    80005748:	fc26                	sd	s1,56(sp)
    8000574a:	f84a                	sd	s2,48(sp)
    8000574c:	f44e                	sd	s3,40(sp)
    8000574e:	f052                	sd	s4,32(sp)
    80005750:	ec56                	sd	s5,24(sp)
    80005752:	e85a                	sd	s6,16(sp)
    80005754:	0880                	addi	s0,sp,80
    80005756:	8b2e                	mv	s6,a1
    80005758:	89b2                	mv	s3,a2
    8000575a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000575c:	fb040593          	addi	a1,s0,-80
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	e3e080e7          	jalr	-450(ra) # 8000459e <nameiparent>
    80005768:	84aa                	mv	s1,a0
    8000576a:	14050f63          	beqz	a0,800058c8 <create+0x186>
    return 0;

  ilock(dp);
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	666080e7          	jalr	1638(ra) # 80003dd4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005776:	4601                	li	a2,0
    80005778:	fb040593          	addi	a1,s0,-80
    8000577c:	8526                	mv	a0,s1
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	b3a080e7          	jalr	-1222(ra) # 800042b8 <dirlookup>
    80005786:	8aaa                	mv	s5,a0
    80005788:	c931                	beqz	a0,800057dc <create+0x9a>
    iunlockput(dp);
    8000578a:	8526                	mv	a0,s1
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	8aa080e7          	jalr	-1878(ra) # 80004036 <iunlockput>
    ilock(ip);
    80005794:	8556                	mv	a0,s5
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	63e080e7          	jalr	1598(ra) # 80003dd4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000579e:	000b059b          	sext.w	a1,s6
    800057a2:	4789                	li	a5,2
    800057a4:	02f59563          	bne	a1,a5,800057ce <create+0x8c>
    800057a8:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffbd134>
    800057ac:	37f9                	addiw	a5,a5,-2
    800057ae:	17c2                	slli	a5,a5,0x30
    800057b0:	93c1                	srli	a5,a5,0x30
    800057b2:	4705                	li	a4,1
    800057b4:	00f76d63          	bltu	a4,a5,800057ce <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800057b8:	8556                	mv	a0,s5
    800057ba:	60a6                	ld	ra,72(sp)
    800057bc:	6406                	ld	s0,64(sp)
    800057be:	74e2                	ld	s1,56(sp)
    800057c0:	7942                	ld	s2,48(sp)
    800057c2:	79a2                	ld	s3,40(sp)
    800057c4:	7a02                	ld	s4,32(sp)
    800057c6:	6ae2                	ld	s5,24(sp)
    800057c8:	6b42                	ld	s6,16(sp)
    800057ca:	6161                	addi	sp,sp,80
    800057cc:	8082                	ret
    iunlockput(ip);
    800057ce:	8556                	mv	a0,s5
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	866080e7          	jalr	-1946(ra) # 80004036 <iunlockput>
    return 0;
    800057d8:	4a81                	li	s5,0
    800057da:	bff9                	j	800057b8 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800057dc:	85da                	mv	a1,s6
    800057de:	4088                	lw	a0,0(s1)
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	456080e7          	jalr	1110(ra) # 80003c36 <ialloc>
    800057e8:	8a2a                	mv	s4,a0
    800057ea:	c539                	beqz	a0,80005838 <create+0xf6>
  ilock(ip);
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	5e8080e7          	jalr	1512(ra) # 80003dd4 <ilock>
  ip->major = major;
    800057f4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800057f8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800057fc:	4905                	li	s2,1
    800057fe:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005802:	8552                	mv	a0,s4
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	504080e7          	jalr	1284(ra) # 80003d08 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000580c:	000b059b          	sext.w	a1,s6
    80005810:	03258b63          	beq	a1,s2,80005846 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005814:	004a2603          	lw	a2,4(s4)
    80005818:	fb040593          	addi	a1,s0,-80
    8000581c:	8526                	mv	a0,s1
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	cb0080e7          	jalr	-848(ra) # 800044ce <dirlink>
    80005826:	06054f63          	bltz	a0,800058a4 <create+0x162>
  iunlockput(dp);
    8000582a:	8526                	mv	a0,s1
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	80a080e7          	jalr	-2038(ra) # 80004036 <iunlockput>
  return ip;
    80005834:	8ad2                	mv	s5,s4
    80005836:	b749                	j	800057b8 <create+0x76>
    iunlockput(dp);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	7fc080e7          	jalr	2044(ra) # 80004036 <iunlockput>
    return 0;
    80005842:	8ad2                	mv	s5,s4
    80005844:	bf95                	j	800057b8 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005846:	004a2603          	lw	a2,4(s4)
    8000584a:	00003597          	auipc	a1,0x3
    8000584e:	00e58593          	addi	a1,a1,14 # 80008858 <syscalls+0x2c8>
    80005852:	8552                	mv	a0,s4
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	c7a080e7          	jalr	-902(ra) # 800044ce <dirlink>
    8000585c:	04054463          	bltz	a0,800058a4 <create+0x162>
    80005860:	40d0                	lw	a2,4(s1)
    80005862:	00003597          	auipc	a1,0x3
    80005866:	ffe58593          	addi	a1,a1,-2 # 80008860 <syscalls+0x2d0>
    8000586a:	8552                	mv	a0,s4
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	c62080e7          	jalr	-926(ra) # 800044ce <dirlink>
    80005874:	02054863          	bltz	a0,800058a4 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005878:	004a2603          	lw	a2,4(s4)
    8000587c:	fb040593          	addi	a1,s0,-80
    80005880:	8526                	mv	a0,s1
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	c4c080e7          	jalr	-948(ra) # 800044ce <dirlink>
    8000588a:	00054d63          	bltz	a0,800058a4 <create+0x162>
    dp->nlink++;  // for ".."
    8000588e:	04a4d783          	lhu	a5,74(s1)
    80005892:	2785                	addiw	a5,a5,1
    80005894:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	46e080e7          	jalr	1134(ra) # 80003d08 <iupdate>
    800058a2:	b761                	j	8000582a <create+0xe8>
  ip->nlink = 0;
    800058a4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800058a8:	8552                	mv	a0,s4
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	45e080e7          	jalr	1118(ra) # 80003d08 <iupdate>
  iunlockput(ip);
    800058b2:	8552                	mv	a0,s4
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	782080e7          	jalr	1922(ra) # 80004036 <iunlockput>
  iunlockput(dp);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	778080e7          	jalr	1912(ra) # 80004036 <iunlockput>
  return 0;
    800058c6:	bdcd                	j	800057b8 <create+0x76>
    return 0;
    800058c8:	8aaa                	mv	s5,a0
    800058ca:	b5fd                	j	800057b8 <create+0x76>

00000000800058cc <sys_dup>:
{
    800058cc:	7179                	addi	sp,sp,-48
    800058ce:	f406                	sd	ra,40(sp)
    800058d0:	f022                	sd	s0,32(sp)
    800058d2:	ec26                	sd	s1,24(sp)
    800058d4:	e84a                	sd	s2,16(sp)
    800058d6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058d8:	fd840613          	addi	a2,s0,-40
    800058dc:	4581                	li	a1,0
    800058de:	4501                	li	a0,0
    800058e0:	00000097          	auipc	ra,0x0
    800058e4:	dc0080e7          	jalr	-576(ra) # 800056a0 <argfd>
    return -1;
    800058e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058ea:	02054363          	bltz	a0,80005910 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800058ee:	fd843903          	ld	s2,-40(s0)
    800058f2:	854a                	mv	a0,s2
    800058f4:	00000097          	auipc	ra,0x0
    800058f8:	e0c080e7          	jalr	-500(ra) # 80005700 <fdalloc>
    800058fc:	84aa                	mv	s1,a0
    return -1;
    800058fe:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005900:	00054863          	bltz	a0,80005910 <sys_dup+0x44>
  filedup(f);
    80005904:	854a                	mv	a0,s2
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	310080e7          	jalr	784(ra) # 80004c16 <filedup>
  return fd;
    8000590e:	87a6                	mv	a5,s1
}
    80005910:	853e                	mv	a0,a5
    80005912:	70a2                	ld	ra,40(sp)
    80005914:	7402                	ld	s0,32(sp)
    80005916:	64e2                	ld	s1,24(sp)
    80005918:	6942                	ld	s2,16(sp)
    8000591a:	6145                	addi	sp,sp,48
    8000591c:	8082                	ret

000000008000591e <sys_read>:
{
    8000591e:	7179                	addi	sp,sp,-48
    80005920:	f406                	sd	ra,40(sp)
    80005922:	f022                	sd	s0,32(sp)
    80005924:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005926:	fd840593          	addi	a1,s0,-40
    8000592a:	4505                	li	a0,1
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	812080e7          	jalr	-2030(ra) # 8000313e <argaddr>
  argint(2, &n);
    80005934:	fe440593          	addi	a1,s0,-28
    80005938:	4509                	li	a0,2
    8000593a:	ffffd097          	auipc	ra,0xffffd
    8000593e:	7e4080e7          	jalr	2020(ra) # 8000311e <argint>
  if(argfd(0, 0, &f) < 0)
    80005942:	fe840613          	addi	a2,s0,-24
    80005946:	4581                	li	a1,0
    80005948:	4501                	li	a0,0
    8000594a:	00000097          	auipc	ra,0x0
    8000594e:	d56080e7          	jalr	-682(ra) # 800056a0 <argfd>
    80005952:	87aa                	mv	a5,a0
    return -1;
    80005954:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005956:	0007cc63          	bltz	a5,8000596e <sys_read+0x50>
  return fileread(f, p, n);
    8000595a:	fe442603          	lw	a2,-28(s0)
    8000595e:	fd843583          	ld	a1,-40(s0)
    80005962:	fe843503          	ld	a0,-24(s0)
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	43c080e7          	jalr	1084(ra) # 80004da2 <fileread>
}
    8000596e:	70a2                	ld	ra,40(sp)
    80005970:	7402                	ld	s0,32(sp)
    80005972:	6145                	addi	sp,sp,48
    80005974:	8082                	ret

0000000080005976 <sys_write>:
{
    80005976:	7179                	addi	sp,sp,-48
    80005978:	f406                	sd	ra,40(sp)
    8000597a:	f022                	sd	s0,32(sp)
    8000597c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000597e:	fd840593          	addi	a1,s0,-40
    80005982:	4505                	li	a0,1
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	7ba080e7          	jalr	1978(ra) # 8000313e <argaddr>
  argint(2, &n);
    8000598c:	fe440593          	addi	a1,s0,-28
    80005990:	4509                	li	a0,2
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	78c080e7          	jalr	1932(ra) # 8000311e <argint>
  if(argfd(0, 0, &f) < 0)
    8000599a:	fe840613          	addi	a2,s0,-24
    8000599e:	4581                	li	a1,0
    800059a0:	4501                	li	a0,0
    800059a2:	00000097          	auipc	ra,0x0
    800059a6:	cfe080e7          	jalr	-770(ra) # 800056a0 <argfd>
    800059aa:	87aa                	mv	a5,a0
    return -1;
    800059ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059ae:	0007cc63          	bltz	a5,800059c6 <sys_write+0x50>
  return filewrite(f, p, n);
    800059b2:	fe442603          	lw	a2,-28(s0)
    800059b6:	fd843583          	ld	a1,-40(s0)
    800059ba:	fe843503          	ld	a0,-24(s0)
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	4a6080e7          	jalr	1190(ra) # 80004e64 <filewrite>
}
    800059c6:	70a2                	ld	ra,40(sp)
    800059c8:	7402                	ld	s0,32(sp)
    800059ca:	6145                	addi	sp,sp,48
    800059cc:	8082                	ret

00000000800059ce <sys_close>:
{
    800059ce:	1101                	addi	sp,sp,-32
    800059d0:	ec06                	sd	ra,24(sp)
    800059d2:	e822                	sd	s0,16(sp)
    800059d4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059d6:	fe040613          	addi	a2,s0,-32
    800059da:	fec40593          	addi	a1,s0,-20
    800059de:	4501                	li	a0,0
    800059e0:	00000097          	auipc	ra,0x0
    800059e4:	cc0080e7          	jalr	-832(ra) # 800056a0 <argfd>
    return -1;
    800059e8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059ea:	02054463          	bltz	a0,80005a12 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059ee:	ffffc097          	auipc	ra,0xffffc
    800059f2:	326080e7          	jalr	806(ra) # 80001d14 <myproc>
    800059f6:	fec42783          	lw	a5,-20(s0)
    800059fa:	07e9                	addi	a5,a5,26
    800059fc:	078e                	slli	a5,a5,0x3
    800059fe:	953e                	add	a0,a0,a5
    80005a00:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005a04:	fe043503          	ld	a0,-32(s0)
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	260080e7          	jalr	608(ra) # 80004c68 <fileclose>
  return 0;
    80005a10:	4781                	li	a5,0
}
    80005a12:	853e                	mv	a0,a5
    80005a14:	60e2                	ld	ra,24(sp)
    80005a16:	6442                	ld	s0,16(sp)
    80005a18:	6105                	addi	sp,sp,32
    80005a1a:	8082                	ret

0000000080005a1c <sys_fstat>:
{
    80005a1c:	1101                	addi	sp,sp,-32
    80005a1e:	ec06                	sd	ra,24(sp)
    80005a20:	e822                	sd	s0,16(sp)
    80005a22:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005a24:	fe040593          	addi	a1,s0,-32
    80005a28:	4505                	li	a0,1
    80005a2a:	ffffd097          	auipc	ra,0xffffd
    80005a2e:	714080e7          	jalr	1812(ra) # 8000313e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005a32:	fe840613          	addi	a2,s0,-24
    80005a36:	4581                	li	a1,0
    80005a38:	4501                	li	a0,0
    80005a3a:	00000097          	auipc	ra,0x0
    80005a3e:	c66080e7          	jalr	-922(ra) # 800056a0 <argfd>
    80005a42:	87aa                	mv	a5,a0
    return -1;
    80005a44:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a46:	0007ca63          	bltz	a5,80005a5a <sys_fstat+0x3e>
  return filestat(f, st);
    80005a4a:	fe043583          	ld	a1,-32(s0)
    80005a4e:	fe843503          	ld	a0,-24(s0)
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	2de080e7          	jalr	734(ra) # 80004d30 <filestat>
}
    80005a5a:	60e2                	ld	ra,24(sp)
    80005a5c:	6442                	ld	s0,16(sp)
    80005a5e:	6105                	addi	sp,sp,32
    80005a60:	8082                	ret

0000000080005a62 <sys_link>:
{
    80005a62:	7169                	addi	sp,sp,-304
    80005a64:	f606                	sd	ra,296(sp)
    80005a66:	f222                	sd	s0,288(sp)
    80005a68:	ee26                	sd	s1,280(sp)
    80005a6a:	ea4a                	sd	s2,272(sp)
    80005a6c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a6e:	08000613          	li	a2,128
    80005a72:	ed040593          	addi	a1,s0,-304
    80005a76:	4501                	li	a0,0
    80005a78:	ffffd097          	auipc	ra,0xffffd
    80005a7c:	6e6080e7          	jalr	1766(ra) # 8000315e <argstr>
    return -1;
    80005a80:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a82:	10054e63          	bltz	a0,80005b9e <sys_link+0x13c>
    80005a86:	08000613          	li	a2,128
    80005a8a:	f5040593          	addi	a1,s0,-176
    80005a8e:	4505                	li	a0,1
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	6ce080e7          	jalr	1742(ra) # 8000315e <argstr>
    return -1;
    80005a98:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a9a:	10054263          	bltz	a0,80005b9e <sys_link+0x13c>
  begin_op();
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	d02080e7          	jalr	-766(ra) # 800047a0 <begin_op>
  if((ip = namei(old)) == 0){
    80005aa6:	ed040513          	addi	a0,s0,-304
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	ad6080e7          	jalr	-1322(ra) # 80004580 <namei>
    80005ab2:	84aa                	mv	s1,a0
    80005ab4:	c551                	beqz	a0,80005b40 <sys_link+0xde>
  ilock(ip);
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	31e080e7          	jalr	798(ra) # 80003dd4 <ilock>
  if(ip->type == T_DIR){
    80005abe:	04449703          	lh	a4,68(s1)
    80005ac2:	4785                	li	a5,1
    80005ac4:	08f70463          	beq	a4,a5,80005b4c <sys_link+0xea>
  ip->nlink++;
    80005ac8:	04a4d783          	lhu	a5,74(s1)
    80005acc:	2785                	addiw	a5,a5,1
    80005ace:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ad2:	8526                	mv	a0,s1
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	234080e7          	jalr	564(ra) # 80003d08 <iupdate>
  iunlock(ip);
    80005adc:	8526                	mv	a0,s1
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	3b8080e7          	jalr	952(ra) # 80003e96 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ae6:	fd040593          	addi	a1,s0,-48
    80005aea:	f5040513          	addi	a0,s0,-176
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	ab0080e7          	jalr	-1360(ra) # 8000459e <nameiparent>
    80005af6:	892a                	mv	s2,a0
    80005af8:	c935                	beqz	a0,80005b6c <sys_link+0x10a>
  ilock(dp);
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	2da080e7          	jalr	730(ra) # 80003dd4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b02:	00092703          	lw	a4,0(s2)
    80005b06:	409c                	lw	a5,0(s1)
    80005b08:	04f71d63          	bne	a4,a5,80005b62 <sys_link+0x100>
    80005b0c:	40d0                	lw	a2,4(s1)
    80005b0e:	fd040593          	addi	a1,s0,-48
    80005b12:	854a                	mv	a0,s2
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	9ba080e7          	jalr	-1606(ra) # 800044ce <dirlink>
    80005b1c:	04054363          	bltz	a0,80005b62 <sys_link+0x100>
  iunlockput(dp);
    80005b20:	854a                	mv	a0,s2
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	514080e7          	jalr	1300(ra) # 80004036 <iunlockput>
  iput(ip);
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	462080e7          	jalr	1122(ra) # 80003f8e <iput>
  end_op();
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	cea080e7          	jalr	-790(ra) # 8000481e <end_op>
  return 0;
    80005b3c:	4781                	li	a5,0
    80005b3e:	a085                	j	80005b9e <sys_link+0x13c>
    end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	cde080e7          	jalr	-802(ra) # 8000481e <end_op>
    return -1;
    80005b48:	57fd                	li	a5,-1
    80005b4a:	a891                	j	80005b9e <sys_link+0x13c>
    iunlockput(ip);
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	4e8080e7          	jalr	1256(ra) # 80004036 <iunlockput>
    end_op();
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	cc8080e7          	jalr	-824(ra) # 8000481e <end_op>
    return -1;
    80005b5e:	57fd                	li	a5,-1
    80005b60:	a83d                	j	80005b9e <sys_link+0x13c>
    iunlockput(dp);
    80005b62:	854a                	mv	a0,s2
    80005b64:	ffffe097          	auipc	ra,0xffffe
    80005b68:	4d2080e7          	jalr	1234(ra) # 80004036 <iunlockput>
  ilock(ip);
    80005b6c:	8526                	mv	a0,s1
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	266080e7          	jalr	614(ra) # 80003dd4 <ilock>
  ip->nlink--;
    80005b76:	04a4d783          	lhu	a5,74(s1)
    80005b7a:	37fd                	addiw	a5,a5,-1
    80005b7c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b80:	8526                	mv	a0,s1
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	186080e7          	jalr	390(ra) # 80003d08 <iupdate>
  iunlockput(ip);
    80005b8a:	8526                	mv	a0,s1
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	4aa080e7          	jalr	1194(ra) # 80004036 <iunlockput>
  end_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	c8a080e7          	jalr	-886(ra) # 8000481e <end_op>
  return -1;
    80005b9c:	57fd                	li	a5,-1
}
    80005b9e:	853e                	mv	a0,a5
    80005ba0:	70b2                	ld	ra,296(sp)
    80005ba2:	7412                	ld	s0,288(sp)
    80005ba4:	64f2                	ld	s1,280(sp)
    80005ba6:	6952                	ld	s2,272(sp)
    80005ba8:	6155                	addi	sp,sp,304
    80005baa:	8082                	ret

0000000080005bac <sys_unlink>:
{
    80005bac:	7151                	addi	sp,sp,-240
    80005bae:	f586                	sd	ra,232(sp)
    80005bb0:	f1a2                	sd	s0,224(sp)
    80005bb2:	eda6                	sd	s1,216(sp)
    80005bb4:	e9ca                	sd	s2,208(sp)
    80005bb6:	e5ce                	sd	s3,200(sp)
    80005bb8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bba:	08000613          	li	a2,128
    80005bbe:	f3040593          	addi	a1,s0,-208
    80005bc2:	4501                	li	a0,0
    80005bc4:	ffffd097          	auipc	ra,0xffffd
    80005bc8:	59a080e7          	jalr	1434(ra) # 8000315e <argstr>
    80005bcc:	18054163          	bltz	a0,80005d4e <sys_unlink+0x1a2>
  begin_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	bd0080e7          	jalr	-1072(ra) # 800047a0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bd8:	fb040593          	addi	a1,s0,-80
    80005bdc:	f3040513          	addi	a0,s0,-208
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	9be080e7          	jalr	-1602(ra) # 8000459e <nameiparent>
    80005be8:	84aa                	mv	s1,a0
    80005bea:	c979                	beqz	a0,80005cc0 <sys_unlink+0x114>
  ilock(dp);
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	1e8080e7          	jalr	488(ra) # 80003dd4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bf4:	00003597          	auipc	a1,0x3
    80005bf8:	c6458593          	addi	a1,a1,-924 # 80008858 <syscalls+0x2c8>
    80005bfc:	fb040513          	addi	a0,s0,-80
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	69e080e7          	jalr	1694(ra) # 8000429e <namecmp>
    80005c08:	14050a63          	beqz	a0,80005d5c <sys_unlink+0x1b0>
    80005c0c:	00003597          	auipc	a1,0x3
    80005c10:	c5458593          	addi	a1,a1,-940 # 80008860 <syscalls+0x2d0>
    80005c14:	fb040513          	addi	a0,s0,-80
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	686080e7          	jalr	1670(ra) # 8000429e <namecmp>
    80005c20:	12050e63          	beqz	a0,80005d5c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c24:	f2c40613          	addi	a2,s0,-212
    80005c28:	fb040593          	addi	a1,s0,-80
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	68a080e7          	jalr	1674(ra) # 800042b8 <dirlookup>
    80005c36:	892a                	mv	s2,a0
    80005c38:	12050263          	beqz	a0,80005d5c <sys_unlink+0x1b0>
  ilock(ip);
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	198080e7          	jalr	408(ra) # 80003dd4 <ilock>
  if(ip->nlink < 1)
    80005c44:	04a91783          	lh	a5,74(s2)
    80005c48:	08f05263          	blez	a5,80005ccc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c4c:	04491703          	lh	a4,68(s2)
    80005c50:	4785                	li	a5,1
    80005c52:	08f70563          	beq	a4,a5,80005cdc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c56:	4641                	li	a2,16
    80005c58:	4581                	li	a1,0
    80005c5a:	fc040513          	addi	a0,s0,-64
    80005c5e:	ffffb097          	auipc	ra,0xffffb
    80005c62:	200080e7          	jalr	512(ra) # 80000e5e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c66:	4741                	li	a4,16
    80005c68:	f2c42683          	lw	a3,-212(s0)
    80005c6c:	fc040613          	addi	a2,s0,-64
    80005c70:	4581                	li	a1,0
    80005c72:	8526                	mv	a0,s1
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	50c080e7          	jalr	1292(ra) # 80004180 <writei>
    80005c7c:	47c1                	li	a5,16
    80005c7e:	0af51563          	bne	a0,a5,80005d28 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c82:	04491703          	lh	a4,68(s2)
    80005c86:	4785                	li	a5,1
    80005c88:	0af70863          	beq	a4,a5,80005d38 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c8c:	8526                	mv	a0,s1
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	3a8080e7          	jalr	936(ra) # 80004036 <iunlockput>
  ip->nlink--;
    80005c96:	04a95783          	lhu	a5,74(s2)
    80005c9a:	37fd                	addiw	a5,a5,-1
    80005c9c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ca0:	854a                	mv	a0,s2
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	066080e7          	jalr	102(ra) # 80003d08 <iupdate>
  iunlockput(ip);
    80005caa:	854a                	mv	a0,s2
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	38a080e7          	jalr	906(ra) # 80004036 <iunlockput>
  end_op();
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	b6a080e7          	jalr	-1174(ra) # 8000481e <end_op>
  return 0;
    80005cbc:	4501                	li	a0,0
    80005cbe:	a84d                	j	80005d70 <sys_unlink+0x1c4>
    end_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	b5e080e7          	jalr	-1186(ra) # 8000481e <end_op>
    return -1;
    80005cc8:	557d                	li	a0,-1
    80005cca:	a05d                	j	80005d70 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ccc:	00003517          	auipc	a0,0x3
    80005cd0:	b9c50513          	addi	a0,a0,-1124 # 80008868 <syscalls+0x2d8>
    80005cd4:	ffffb097          	auipc	ra,0xffffb
    80005cd8:	86c080e7          	jalr	-1940(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cdc:	04c92703          	lw	a4,76(s2)
    80005ce0:	02000793          	li	a5,32
    80005ce4:	f6e7f9e3          	bgeu	a5,a4,80005c56 <sys_unlink+0xaa>
    80005ce8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cec:	4741                	li	a4,16
    80005cee:	86ce                	mv	a3,s3
    80005cf0:	f1840613          	addi	a2,s0,-232
    80005cf4:	4581                	li	a1,0
    80005cf6:	854a                	mv	a0,s2
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	390080e7          	jalr	912(ra) # 80004088 <readi>
    80005d00:	47c1                	li	a5,16
    80005d02:	00f51b63          	bne	a0,a5,80005d18 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d06:	f1845783          	lhu	a5,-232(s0)
    80005d0a:	e7a1                	bnez	a5,80005d52 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d0c:	29c1                	addiw	s3,s3,16
    80005d0e:	04c92783          	lw	a5,76(s2)
    80005d12:	fcf9ede3          	bltu	s3,a5,80005cec <sys_unlink+0x140>
    80005d16:	b781                	j	80005c56 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d18:	00003517          	auipc	a0,0x3
    80005d1c:	b6850513          	addi	a0,a0,-1176 # 80008880 <syscalls+0x2f0>
    80005d20:	ffffb097          	auipc	ra,0xffffb
    80005d24:	820080e7          	jalr	-2016(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005d28:	00003517          	auipc	a0,0x3
    80005d2c:	b7050513          	addi	a0,a0,-1168 # 80008898 <syscalls+0x308>
    80005d30:	ffffb097          	auipc	ra,0xffffb
    80005d34:	810080e7          	jalr	-2032(ra) # 80000540 <panic>
    dp->nlink--;
    80005d38:	04a4d783          	lhu	a5,74(s1)
    80005d3c:	37fd                	addiw	a5,a5,-1
    80005d3e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d42:	8526                	mv	a0,s1
    80005d44:	ffffe097          	auipc	ra,0xffffe
    80005d48:	fc4080e7          	jalr	-60(ra) # 80003d08 <iupdate>
    80005d4c:	b781                	j	80005c8c <sys_unlink+0xe0>
    return -1;
    80005d4e:	557d                	li	a0,-1
    80005d50:	a005                	j	80005d70 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d52:	854a                	mv	a0,s2
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	2e2080e7          	jalr	738(ra) # 80004036 <iunlockput>
  iunlockput(dp);
    80005d5c:	8526                	mv	a0,s1
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	2d8080e7          	jalr	728(ra) # 80004036 <iunlockput>
  end_op();
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	ab8080e7          	jalr	-1352(ra) # 8000481e <end_op>
  return -1;
    80005d6e:	557d                	li	a0,-1
}
    80005d70:	70ae                	ld	ra,232(sp)
    80005d72:	740e                	ld	s0,224(sp)
    80005d74:	64ee                	ld	s1,216(sp)
    80005d76:	694e                	ld	s2,208(sp)
    80005d78:	69ae                	ld	s3,200(sp)
    80005d7a:	616d                	addi	sp,sp,240
    80005d7c:	8082                	ret

0000000080005d7e <sys_open>:

uint64
sys_open(void)
{
    80005d7e:	7131                	addi	sp,sp,-192
    80005d80:	fd06                	sd	ra,184(sp)
    80005d82:	f922                	sd	s0,176(sp)
    80005d84:	f526                	sd	s1,168(sp)
    80005d86:	f14a                	sd	s2,160(sp)
    80005d88:	ed4e                	sd	s3,152(sp)
    80005d8a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d8c:	f4c40593          	addi	a1,s0,-180
    80005d90:	4505                	li	a0,1
    80005d92:	ffffd097          	auipc	ra,0xffffd
    80005d96:	38c080e7          	jalr	908(ra) # 8000311e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d9a:	08000613          	li	a2,128
    80005d9e:	f5040593          	addi	a1,s0,-176
    80005da2:	4501                	li	a0,0
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	3ba080e7          	jalr	954(ra) # 8000315e <argstr>
    80005dac:	87aa                	mv	a5,a0
    return -1;
    80005dae:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005db0:	0a07c963          	bltz	a5,80005e62 <sys_open+0xe4>

  begin_op();
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	9ec080e7          	jalr	-1556(ra) # 800047a0 <begin_op>

  if(omode & O_CREATE){
    80005dbc:	f4c42783          	lw	a5,-180(s0)
    80005dc0:	2007f793          	andi	a5,a5,512
    80005dc4:	cfc5                	beqz	a5,80005e7c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005dc6:	4681                	li	a3,0
    80005dc8:	4601                	li	a2,0
    80005dca:	4589                	li	a1,2
    80005dcc:	f5040513          	addi	a0,s0,-176
    80005dd0:	00000097          	auipc	ra,0x0
    80005dd4:	972080e7          	jalr	-1678(ra) # 80005742 <create>
    80005dd8:	84aa                	mv	s1,a0
    if(ip == 0){
    80005dda:	c959                	beqz	a0,80005e70 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ddc:	04449703          	lh	a4,68(s1)
    80005de0:	478d                	li	a5,3
    80005de2:	00f71763          	bne	a4,a5,80005df0 <sys_open+0x72>
    80005de6:	0464d703          	lhu	a4,70(s1)
    80005dea:	47a5                	li	a5,9
    80005dec:	0ce7ed63          	bltu	a5,a4,80005ec6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	dbc080e7          	jalr	-580(ra) # 80004bac <filealloc>
    80005df8:	89aa                	mv	s3,a0
    80005dfa:	10050363          	beqz	a0,80005f00 <sys_open+0x182>
    80005dfe:	00000097          	auipc	ra,0x0
    80005e02:	902080e7          	jalr	-1790(ra) # 80005700 <fdalloc>
    80005e06:	892a                	mv	s2,a0
    80005e08:	0e054763          	bltz	a0,80005ef6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e0c:	04449703          	lh	a4,68(s1)
    80005e10:	478d                	li	a5,3
    80005e12:	0cf70563          	beq	a4,a5,80005edc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e16:	4789                	li	a5,2
    80005e18:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e1c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e20:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e24:	f4c42783          	lw	a5,-180(s0)
    80005e28:	0017c713          	xori	a4,a5,1
    80005e2c:	8b05                	andi	a4,a4,1
    80005e2e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e32:	0037f713          	andi	a4,a5,3
    80005e36:	00e03733          	snez	a4,a4
    80005e3a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e3e:	4007f793          	andi	a5,a5,1024
    80005e42:	c791                	beqz	a5,80005e4e <sys_open+0xd0>
    80005e44:	04449703          	lh	a4,68(s1)
    80005e48:	4789                	li	a5,2
    80005e4a:	0af70063          	beq	a4,a5,80005eea <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e4e:	8526                	mv	a0,s1
    80005e50:	ffffe097          	auipc	ra,0xffffe
    80005e54:	046080e7          	jalr	70(ra) # 80003e96 <iunlock>
  end_op();
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	9c6080e7          	jalr	-1594(ra) # 8000481e <end_op>

  return fd;
    80005e60:	854a                	mv	a0,s2
}
    80005e62:	70ea                	ld	ra,184(sp)
    80005e64:	744a                	ld	s0,176(sp)
    80005e66:	74aa                	ld	s1,168(sp)
    80005e68:	790a                	ld	s2,160(sp)
    80005e6a:	69ea                	ld	s3,152(sp)
    80005e6c:	6129                	addi	sp,sp,192
    80005e6e:	8082                	ret
      end_op();
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	9ae080e7          	jalr	-1618(ra) # 8000481e <end_op>
      return -1;
    80005e78:	557d                	li	a0,-1
    80005e7a:	b7e5                	j	80005e62 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e7c:	f5040513          	addi	a0,s0,-176
    80005e80:	ffffe097          	auipc	ra,0xffffe
    80005e84:	700080e7          	jalr	1792(ra) # 80004580 <namei>
    80005e88:	84aa                	mv	s1,a0
    80005e8a:	c905                	beqz	a0,80005eba <sys_open+0x13c>
    ilock(ip);
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	f48080e7          	jalr	-184(ra) # 80003dd4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e94:	04449703          	lh	a4,68(s1)
    80005e98:	4785                	li	a5,1
    80005e9a:	f4f711e3          	bne	a4,a5,80005ddc <sys_open+0x5e>
    80005e9e:	f4c42783          	lw	a5,-180(s0)
    80005ea2:	d7b9                	beqz	a5,80005df0 <sys_open+0x72>
      iunlockput(ip);
    80005ea4:	8526                	mv	a0,s1
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	190080e7          	jalr	400(ra) # 80004036 <iunlockput>
      end_op();
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	970080e7          	jalr	-1680(ra) # 8000481e <end_op>
      return -1;
    80005eb6:	557d                	li	a0,-1
    80005eb8:	b76d                	j	80005e62 <sys_open+0xe4>
      end_op();
    80005eba:	fffff097          	auipc	ra,0xfffff
    80005ebe:	964080e7          	jalr	-1692(ra) # 8000481e <end_op>
      return -1;
    80005ec2:	557d                	li	a0,-1
    80005ec4:	bf79                	j	80005e62 <sys_open+0xe4>
    iunlockput(ip);
    80005ec6:	8526                	mv	a0,s1
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	16e080e7          	jalr	366(ra) # 80004036 <iunlockput>
    end_op();
    80005ed0:	fffff097          	auipc	ra,0xfffff
    80005ed4:	94e080e7          	jalr	-1714(ra) # 8000481e <end_op>
    return -1;
    80005ed8:	557d                	li	a0,-1
    80005eda:	b761                	j	80005e62 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005edc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ee0:	04649783          	lh	a5,70(s1)
    80005ee4:	02f99223          	sh	a5,36(s3)
    80005ee8:	bf25                	j	80005e20 <sys_open+0xa2>
    itrunc(ip);
    80005eea:	8526                	mv	a0,s1
    80005eec:	ffffe097          	auipc	ra,0xffffe
    80005ef0:	ff6080e7          	jalr	-10(ra) # 80003ee2 <itrunc>
    80005ef4:	bfa9                	j	80005e4e <sys_open+0xd0>
      fileclose(f);
    80005ef6:	854e                	mv	a0,s3
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	d70080e7          	jalr	-656(ra) # 80004c68 <fileclose>
    iunlockput(ip);
    80005f00:	8526                	mv	a0,s1
    80005f02:	ffffe097          	auipc	ra,0xffffe
    80005f06:	134080e7          	jalr	308(ra) # 80004036 <iunlockput>
    end_op();
    80005f0a:	fffff097          	auipc	ra,0xfffff
    80005f0e:	914080e7          	jalr	-1772(ra) # 8000481e <end_op>
    return -1;
    80005f12:	557d                	li	a0,-1
    80005f14:	b7b9                	j	80005e62 <sys_open+0xe4>

0000000080005f16 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f16:	7175                	addi	sp,sp,-144
    80005f18:	e506                	sd	ra,136(sp)
    80005f1a:	e122                	sd	s0,128(sp)
    80005f1c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	882080e7          	jalr	-1918(ra) # 800047a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f26:	08000613          	li	a2,128
    80005f2a:	f7040593          	addi	a1,s0,-144
    80005f2e:	4501                	li	a0,0
    80005f30:	ffffd097          	auipc	ra,0xffffd
    80005f34:	22e080e7          	jalr	558(ra) # 8000315e <argstr>
    80005f38:	02054963          	bltz	a0,80005f6a <sys_mkdir+0x54>
    80005f3c:	4681                	li	a3,0
    80005f3e:	4601                	li	a2,0
    80005f40:	4585                	li	a1,1
    80005f42:	f7040513          	addi	a0,s0,-144
    80005f46:	fffff097          	auipc	ra,0xfffff
    80005f4a:	7fc080e7          	jalr	2044(ra) # 80005742 <create>
    80005f4e:	cd11                	beqz	a0,80005f6a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	0e6080e7          	jalr	230(ra) # 80004036 <iunlockput>
  end_op();
    80005f58:	fffff097          	auipc	ra,0xfffff
    80005f5c:	8c6080e7          	jalr	-1850(ra) # 8000481e <end_op>
  return 0;
    80005f60:	4501                	li	a0,0
}
    80005f62:	60aa                	ld	ra,136(sp)
    80005f64:	640a                	ld	s0,128(sp)
    80005f66:	6149                	addi	sp,sp,144
    80005f68:	8082                	ret
    end_op();
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	8b4080e7          	jalr	-1868(ra) # 8000481e <end_op>
    return -1;
    80005f72:	557d                	li	a0,-1
    80005f74:	b7fd                	j	80005f62 <sys_mkdir+0x4c>

0000000080005f76 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f76:	7135                	addi	sp,sp,-160
    80005f78:	ed06                	sd	ra,152(sp)
    80005f7a:	e922                	sd	s0,144(sp)
    80005f7c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	822080e7          	jalr	-2014(ra) # 800047a0 <begin_op>
  argint(1, &major);
    80005f86:	f6c40593          	addi	a1,s0,-148
    80005f8a:	4505                	li	a0,1
    80005f8c:	ffffd097          	auipc	ra,0xffffd
    80005f90:	192080e7          	jalr	402(ra) # 8000311e <argint>
  argint(2, &minor);
    80005f94:	f6840593          	addi	a1,s0,-152
    80005f98:	4509                	li	a0,2
    80005f9a:	ffffd097          	auipc	ra,0xffffd
    80005f9e:	184080e7          	jalr	388(ra) # 8000311e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fa2:	08000613          	li	a2,128
    80005fa6:	f7040593          	addi	a1,s0,-144
    80005faa:	4501                	li	a0,0
    80005fac:	ffffd097          	auipc	ra,0xffffd
    80005fb0:	1b2080e7          	jalr	434(ra) # 8000315e <argstr>
    80005fb4:	02054b63          	bltz	a0,80005fea <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fb8:	f6841683          	lh	a3,-152(s0)
    80005fbc:	f6c41603          	lh	a2,-148(s0)
    80005fc0:	458d                	li	a1,3
    80005fc2:	f7040513          	addi	a0,s0,-144
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	77c080e7          	jalr	1916(ra) # 80005742 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fce:	cd11                	beqz	a0,80005fea <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fd0:	ffffe097          	auipc	ra,0xffffe
    80005fd4:	066080e7          	jalr	102(ra) # 80004036 <iunlockput>
  end_op();
    80005fd8:	fffff097          	auipc	ra,0xfffff
    80005fdc:	846080e7          	jalr	-1978(ra) # 8000481e <end_op>
  return 0;
    80005fe0:	4501                	li	a0,0
}
    80005fe2:	60ea                	ld	ra,152(sp)
    80005fe4:	644a                	ld	s0,144(sp)
    80005fe6:	610d                	addi	sp,sp,160
    80005fe8:	8082                	ret
    end_op();
    80005fea:	fffff097          	auipc	ra,0xfffff
    80005fee:	834080e7          	jalr	-1996(ra) # 8000481e <end_op>
    return -1;
    80005ff2:	557d                	li	a0,-1
    80005ff4:	b7fd                	j	80005fe2 <sys_mknod+0x6c>

0000000080005ff6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ff6:	7135                	addi	sp,sp,-160
    80005ff8:	ed06                	sd	ra,152(sp)
    80005ffa:	e922                	sd	s0,144(sp)
    80005ffc:	e526                	sd	s1,136(sp)
    80005ffe:	e14a                	sd	s2,128(sp)
    80006000:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006002:	ffffc097          	auipc	ra,0xffffc
    80006006:	d12080e7          	jalr	-750(ra) # 80001d14 <myproc>
    8000600a:	892a                	mv	s2,a0
  
  begin_op();
    8000600c:	ffffe097          	auipc	ra,0xffffe
    80006010:	794080e7          	jalr	1940(ra) # 800047a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006014:	08000613          	li	a2,128
    80006018:	f6040593          	addi	a1,s0,-160
    8000601c:	4501                	li	a0,0
    8000601e:	ffffd097          	auipc	ra,0xffffd
    80006022:	140080e7          	jalr	320(ra) # 8000315e <argstr>
    80006026:	04054b63          	bltz	a0,8000607c <sys_chdir+0x86>
    8000602a:	f6040513          	addi	a0,s0,-160
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	552080e7          	jalr	1362(ra) # 80004580 <namei>
    80006036:	84aa                	mv	s1,a0
    80006038:	c131                	beqz	a0,8000607c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000603a:	ffffe097          	auipc	ra,0xffffe
    8000603e:	d9a080e7          	jalr	-614(ra) # 80003dd4 <ilock>
  if(ip->type != T_DIR){
    80006042:	04449703          	lh	a4,68(s1)
    80006046:	4785                	li	a5,1
    80006048:	04f71063          	bne	a4,a5,80006088 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000604c:	8526                	mv	a0,s1
    8000604e:	ffffe097          	auipc	ra,0xffffe
    80006052:	e48080e7          	jalr	-440(ra) # 80003e96 <iunlock>
  iput(p->cwd);
    80006056:	15093503          	ld	a0,336(s2)
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	f34080e7          	jalr	-204(ra) # 80003f8e <iput>
  end_op();
    80006062:	ffffe097          	auipc	ra,0xffffe
    80006066:	7bc080e7          	jalr	1980(ra) # 8000481e <end_op>
  p->cwd = ip;
    8000606a:	14993823          	sd	s1,336(s2)
  return 0;
    8000606e:	4501                	li	a0,0
}
    80006070:	60ea                	ld	ra,152(sp)
    80006072:	644a                	ld	s0,144(sp)
    80006074:	64aa                	ld	s1,136(sp)
    80006076:	690a                	ld	s2,128(sp)
    80006078:	610d                	addi	sp,sp,160
    8000607a:	8082                	ret
    end_op();
    8000607c:	ffffe097          	auipc	ra,0xffffe
    80006080:	7a2080e7          	jalr	1954(ra) # 8000481e <end_op>
    return -1;
    80006084:	557d                	li	a0,-1
    80006086:	b7ed                	j	80006070 <sys_chdir+0x7a>
    iunlockput(ip);
    80006088:	8526                	mv	a0,s1
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	fac080e7          	jalr	-84(ra) # 80004036 <iunlockput>
    end_op();
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	78c080e7          	jalr	1932(ra) # 8000481e <end_op>
    return -1;
    8000609a:	557d                	li	a0,-1
    8000609c:	bfd1                	j	80006070 <sys_chdir+0x7a>

000000008000609e <sys_exec>:

uint64
sys_exec(void)
{
    8000609e:	7145                	addi	sp,sp,-464
    800060a0:	e786                	sd	ra,456(sp)
    800060a2:	e3a2                	sd	s0,448(sp)
    800060a4:	ff26                	sd	s1,440(sp)
    800060a6:	fb4a                	sd	s2,432(sp)
    800060a8:	f74e                	sd	s3,424(sp)
    800060aa:	f352                	sd	s4,416(sp)
    800060ac:	ef56                	sd	s5,408(sp)
    800060ae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800060b0:	e3840593          	addi	a1,s0,-456
    800060b4:	4505                	li	a0,1
    800060b6:	ffffd097          	auipc	ra,0xffffd
    800060ba:	088080e7          	jalr	136(ra) # 8000313e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800060be:	08000613          	li	a2,128
    800060c2:	f4040593          	addi	a1,s0,-192
    800060c6:	4501                	li	a0,0
    800060c8:	ffffd097          	auipc	ra,0xffffd
    800060cc:	096080e7          	jalr	150(ra) # 8000315e <argstr>
    800060d0:	87aa                	mv	a5,a0
    return -1;
    800060d2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800060d4:	0c07c363          	bltz	a5,8000619a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800060d8:	10000613          	li	a2,256
    800060dc:	4581                	li	a1,0
    800060de:	e4040513          	addi	a0,s0,-448
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	d7c080e7          	jalr	-644(ra) # 80000e5e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060ea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060ee:	89a6                	mv	s3,s1
    800060f0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060f2:	02000a13          	li	s4,32
    800060f6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060fa:	00391513          	slli	a0,s2,0x3
    800060fe:	e3040593          	addi	a1,s0,-464
    80006102:	e3843783          	ld	a5,-456(s0)
    80006106:	953e                	add	a0,a0,a5
    80006108:	ffffd097          	auipc	ra,0xffffd
    8000610c:	f78080e7          	jalr	-136(ra) # 80003080 <fetchaddr>
    80006110:	02054a63          	bltz	a0,80006144 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006114:	e3043783          	ld	a5,-464(s0)
    80006118:	c3b9                	beqz	a5,8000615e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000611a:	ffffb097          	auipc	ra,0xffffb
    8000611e:	a48080e7          	jalr	-1464(ra) # 80000b62 <kalloc>
    80006122:	85aa                	mv	a1,a0
    80006124:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006128:	cd11                	beqz	a0,80006144 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000612a:	6605                	lui	a2,0x1
    8000612c:	e3043503          	ld	a0,-464(s0)
    80006130:	ffffd097          	auipc	ra,0xffffd
    80006134:	fa2080e7          	jalr	-94(ra) # 800030d2 <fetchstr>
    80006138:	00054663          	bltz	a0,80006144 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000613c:	0905                	addi	s2,s2,1
    8000613e:	09a1                	addi	s3,s3,8
    80006140:	fb491be3          	bne	s2,s4,800060f6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006144:	f4040913          	addi	s2,s0,-192
    80006148:	6088                	ld	a0,0(s1)
    8000614a:	c539                	beqz	a0,80006198 <sys_exec+0xfa>
    kfree(argv[i]);
    8000614c:	ffffb097          	auipc	ra,0xffffb
    80006150:	8ae080e7          	jalr	-1874(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006154:	04a1                	addi	s1,s1,8
    80006156:	ff2499e3          	bne	s1,s2,80006148 <sys_exec+0xaa>
  return -1;
    8000615a:	557d                	li	a0,-1
    8000615c:	a83d                	j	8000619a <sys_exec+0xfc>
      argv[i] = 0;
    8000615e:	0a8e                	slli	s5,s5,0x3
    80006160:	fc0a8793          	addi	a5,s5,-64
    80006164:	00878ab3          	add	s5,a5,s0
    80006168:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000616c:	e4040593          	addi	a1,s0,-448
    80006170:	f4040513          	addi	a0,s0,-192
    80006174:	fffff097          	auipc	ra,0xfffff
    80006178:	16e080e7          	jalr	366(ra) # 800052e2 <exec>
    8000617c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000617e:	f4040993          	addi	s3,s0,-192
    80006182:	6088                	ld	a0,0(s1)
    80006184:	c901                	beqz	a0,80006194 <sys_exec+0xf6>
    kfree(argv[i]);
    80006186:	ffffb097          	auipc	ra,0xffffb
    8000618a:	874080e7          	jalr	-1932(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000618e:	04a1                	addi	s1,s1,8
    80006190:	ff3499e3          	bne	s1,s3,80006182 <sys_exec+0xe4>
  return ret;
    80006194:	854a                	mv	a0,s2
    80006196:	a011                	j	8000619a <sys_exec+0xfc>
  return -1;
    80006198:	557d                	li	a0,-1
}
    8000619a:	60be                	ld	ra,456(sp)
    8000619c:	641e                	ld	s0,448(sp)
    8000619e:	74fa                	ld	s1,440(sp)
    800061a0:	795a                	ld	s2,432(sp)
    800061a2:	79ba                	ld	s3,424(sp)
    800061a4:	7a1a                	ld	s4,416(sp)
    800061a6:	6afa                	ld	s5,408(sp)
    800061a8:	6179                	addi	sp,sp,464
    800061aa:	8082                	ret

00000000800061ac <sys_pipe>:

uint64
sys_pipe(void)
{
    800061ac:	7139                	addi	sp,sp,-64
    800061ae:	fc06                	sd	ra,56(sp)
    800061b0:	f822                	sd	s0,48(sp)
    800061b2:	f426                	sd	s1,40(sp)
    800061b4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061b6:	ffffc097          	auipc	ra,0xffffc
    800061ba:	b5e080e7          	jalr	-1186(ra) # 80001d14 <myproc>
    800061be:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800061c0:	fd840593          	addi	a1,s0,-40
    800061c4:	4501                	li	a0,0
    800061c6:	ffffd097          	auipc	ra,0xffffd
    800061ca:	f78080e7          	jalr	-136(ra) # 8000313e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800061ce:	fc840593          	addi	a1,s0,-56
    800061d2:	fd040513          	addi	a0,s0,-48
    800061d6:	fffff097          	auipc	ra,0xfffff
    800061da:	dc2080e7          	jalr	-574(ra) # 80004f98 <pipealloc>
    return -1;
    800061de:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061e0:	0c054463          	bltz	a0,800062a8 <sys_pipe+0xfc>
  fd0 = -1;
    800061e4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061e8:	fd043503          	ld	a0,-48(s0)
    800061ec:	fffff097          	auipc	ra,0xfffff
    800061f0:	514080e7          	jalr	1300(ra) # 80005700 <fdalloc>
    800061f4:	fca42223          	sw	a0,-60(s0)
    800061f8:	08054b63          	bltz	a0,8000628e <sys_pipe+0xe2>
    800061fc:	fc843503          	ld	a0,-56(s0)
    80006200:	fffff097          	auipc	ra,0xfffff
    80006204:	500080e7          	jalr	1280(ra) # 80005700 <fdalloc>
    80006208:	fca42023          	sw	a0,-64(s0)
    8000620c:	06054863          	bltz	a0,8000627c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006210:	4691                	li	a3,4
    80006212:	fc440613          	addi	a2,s0,-60
    80006216:	fd843583          	ld	a1,-40(s0)
    8000621a:	68a8                	ld	a0,80(s1)
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	6ba080e7          	jalr	1722(ra) # 800018d6 <copyout>
    80006224:	02054063          	bltz	a0,80006244 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006228:	4691                	li	a3,4
    8000622a:	fc040613          	addi	a2,s0,-64
    8000622e:	fd843583          	ld	a1,-40(s0)
    80006232:	0591                	addi	a1,a1,4
    80006234:	68a8                	ld	a0,80(s1)
    80006236:	ffffb097          	auipc	ra,0xffffb
    8000623a:	6a0080e7          	jalr	1696(ra) # 800018d6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000623e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006240:	06055463          	bgez	a0,800062a8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006244:	fc442783          	lw	a5,-60(s0)
    80006248:	07e9                	addi	a5,a5,26
    8000624a:	078e                	slli	a5,a5,0x3
    8000624c:	97a6                	add	a5,a5,s1
    8000624e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006252:	fc042783          	lw	a5,-64(s0)
    80006256:	07e9                	addi	a5,a5,26
    80006258:	078e                	slli	a5,a5,0x3
    8000625a:	94be                	add	s1,s1,a5
    8000625c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006260:	fd043503          	ld	a0,-48(s0)
    80006264:	fffff097          	auipc	ra,0xfffff
    80006268:	a04080e7          	jalr	-1532(ra) # 80004c68 <fileclose>
    fileclose(wf);
    8000626c:	fc843503          	ld	a0,-56(s0)
    80006270:	fffff097          	auipc	ra,0xfffff
    80006274:	9f8080e7          	jalr	-1544(ra) # 80004c68 <fileclose>
    return -1;
    80006278:	57fd                	li	a5,-1
    8000627a:	a03d                	j	800062a8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000627c:	fc442783          	lw	a5,-60(s0)
    80006280:	0007c763          	bltz	a5,8000628e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006284:	07e9                	addi	a5,a5,26
    80006286:	078e                	slli	a5,a5,0x3
    80006288:	97a6                	add	a5,a5,s1
    8000628a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000628e:	fd043503          	ld	a0,-48(s0)
    80006292:	fffff097          	auipc	ra,0xfffff
    80006296:	9d6080e7          	jalr	-1578(ra) # 80004c68 <fileclose>
    fileclose(wf);
    8000629a:	fc843503          	ld	a0,-56(s0)
    8000629e:	fffff097          	auipc	ra,0xfffff
    800062a2:	9ca080e7          	jalr	-1590(ra) # 80004c68 <fileclose>
    return -1;
    800062a6:	57fd                	li	a5,-1
}
    800062a8:	853e                	mv	a0,a5
    800062aa:	70e2                	ld	ra,56(sp)
    800062ac:	7442                	ld	s0,48(sp)
    800062ae:	74a2                	ld	s1,40(sp)
    800062b0:	6121                	addi	sp,sp,64
    800062b2:	8082                	ret
	...

00000000800062c0 <kernelvec>:
    800062c0:	7111                	addi	sp,sp,-256
    800062c2:	e006                	sd	ra,0(sp)
    800062c4:	e40a                	sd	sp,8(sp)
    800062c6:	e80e                	sd	gp,16(sp)
    800062c8:	ec12                	sd	tp,24(sp)
    800062ca:	f016                	sd	t0,32(sp)
    800062cc:	f41a                	sd	t1,40(sp)
    800062ce:	f81e                	sd	t2,48(sp)
    800062d0:	fc22                	sd	s0,56(sp)
    800062d2:	e0a6                	sd	s1,64(sp)
    800062d4:	e4aa                	sd	a0,72(sp)
    800062d6:	e8ae                	sd	a1,80(sp)
    800062d8:	ecb2                	sd	a2,88(sp)
    800062da:	f0b6                	sd	a3,96(sp)
    800062dc:	f4ba                	sd	a4,104(sp)
    800062de:	f8be                	sd	a5,112(sp)
    800062e0:	fcc2                	sd	a6,120(sp)
    800062e2:	e146                	sd	a7,128(sp)
    800062e4:	e54a                	sd	s2,136(sp)
    800062e6:	e94e                	sd	s3,144(sp)
    800062e8:	ed52                	sd	s4,152(sp)
    800062ea:	f156                	sd	s5,160(sp)
    800062ec:	f55a                	sd	s6,168(sp)
    800062ee:	f95e                	sd	s7,176(sp)
    800062f0:	fd62                	sd	s8,184(sp)
    800062f2:	e1e6                	sd	s9,192(sp)
    800062f4:	e5ea                	sd	s10,200(sp)
    800062f6:	e9ee                	sd	s11,208(sp)
    800062f8:	edf2                	sd	t3,216(sp)
    800062fa:	f1f6                	sd	t4,224(sp)
    800062fc:	f5fa                	sd	t5,232(sp)
    800062fe:	f9fe                	sd	t6,240(sp)
    80006300:	c4dfc0ef          	jal	ra,80002f4c <kerneltrap>
    80006304:	6082                	ld	ra,0(sp)
    80006306:	6122                	ld	sp,8(sp)
    80006308:	61c2                	ld	gp,16(sp)
    8000630a:	7282                	ld	t0,32(sp)
    8000630c:	7322                	ld	t1,40(sp)
    8000630e:	73c2                	ld	t2,48(sp)
    80006310:	7462                	ld	s0,56(sp)
    80006312:	6486                	ld	s1,64(sp)
    80006314:	6526                	ld	a0,72(sp)
    80006316:	65c6                	ld	a1,80(sp)
    80006318:	6666                	ld	a2,88(sp)
    8000631a:	7686                	ld	a3,96(sp)
    8000631c:	7726                	ld	a4,104(sp)
    8000631e:	77c6                	ld	a5,112(sp)
    80006320:	7866                	ld	a6,120(sp)
    80006322:	688a                	ld	a7,128(sp)
    80006324:	692a                	ld	s2,136(sp)
    80006326:	69ca                	ld	s3,144(sp)
    80006328:	6a6a                	ld	s4,152(sp)
    8000632a:	7a8a                	ld	s5,160(sp)
    8000632c:	7b2a                	ld	s6,168(sp)
    8000632e:	7bca                	ld	s7,176(sp)
    80006330:	7c6a                	ld	s8,184(sp)
    80006332:	6c8e                	ld	s9,192(sp)
    80006334:	6d2e                	ld	s10,200(sp)
    80006336:	6dce                	ld	s11,208(sp)
    80006338:	6e6e                	ld	t3,216(sp)
    8000633a:	7e8e                	ld	t4,224(sp)
    8000633c:	7f2e                	ld	t5,232(sp)
    8000633e:	7fce                	ld	t6,240(sp)
    80006340:	6111                	addi	sp,sp,256
    80006342:	10200073          	sret
    80006346:	00000013          	nop
    8000634a:	00000013          	nop
    8000634e:	0001                	nop

0000000080006350 <timervec>:
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	e10c                	sd	a1,0(a0)
    80006356:	e510                	sd	a2,8(a0)
    80006358:	e914                	sd	a3,16(a0)
    8000635a:	6d0c                	ld	a1,24(a0)
    8000635c:	7110                	ld	a2,32(a0)
    8000635e:	6194                	ld	a3,0(a1)
    80006360:	96b2                	add	a3,a3,a2
    80006362:	e194                	sd	a3,0(a1)
    80006364:	4589                	li	a1,2
    80006366:	14459073          	csrw	sip,a1
    8000636a:	6914                	ld	a3,16(a0)
    8000636c:	6510                	ld	a2,8(a0)
    8000636e:	610c                	ld	a1,0(a0)
    80006370:	34051573          	csrrw	a0,mscratch,a0
    80006374:	30200073          	mret
	...

000000008000637a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000637a:	1141                	addi	sp,sp,-16
    8000637c:	e422                	sd	s0,8(sp)
    8000637e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006380:	0c0007b7          	lui	a5,0xc000
    80006384:	4705                	li	a4,1
    80006386:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006388:	c3d8                	sw	a4,4(a5)
}
    8000638a:	6422                	ld	s0,8(sp)
    8000638c:	0141                	addi	sp,sp,16
    8000638e:	8082                	ret

0000000080006390 <plicinithart>:

void
plicinithart(void)
{
    80006390:	1141                	addi	sp,sp,-16
    80006392:	e406                	sd	ra,8(sp)
    80006394:	e022                	sd	s0,0(sp)
    80006396:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006398:	ffffc097          	auipc	ra,0xffffc
    8000639c:	950080e7          	jalr	-1712(ra) # 80001ce8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063a0:	0085171b          	slliw	a4,a0,0x8
    800063a4:	0c0027b7          	lui	a5,0xc002
    800063a8:	97ba                	add	a5,a5,a4
    800063aa:	40200713          	li	a4,1026
    800063ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063b2:	00d5151b          	slliw	a0,a0,0xd
    800063b6:	0c2017b7          	lui	a5,0xc201
    800063ba:	97aa                	add	a5,a5,a0
    800063bc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800063c0:	60a2                	ld	ra,8(sp)
    800063c2:	6402                	ld	s0,0(sp)
    800063c4:	0141                	addi	sp,sp,16
    800063c6:	8082                	ret

00000000800063c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063c8:	1141                	addi	sp,sp,-16
    800063ca:	e406                	sd	ra,8(sp)
    800063cc:	e022                	sd	s0,0(sp)
    800063ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063d0:	ffffc097          	auipc	ra,0xffffc
    800063d4:	918080e7          	jalr	-1768(ra) # 80001ce8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063d8:	00d5151b          	slliw	a0,a0,0xd
    800063dc:	0c2017b7          	lui	a5,0xc201
    800063e0:	97aa                	add	a5,a5,a0
  return irq;
}
    800063e2:	43c8                	lw	a0,4(a5)
    800063e4:	60a2                	ld	ra,8(sp)
    800063e6:	6402                	ld	s0,0(sp)
    800063e8:	0141                	addi	sp,sp,16
    800063ea:	8082                	ret

00000000800063ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063ec:	1101                	addi	sp,sp,-32
    800063ee:	ec06                	sd	ra,24(sp)
    800063f0:	e822                	sd	s0,16(sp)
    800063f2:	e426                	sd	s1,8(sp)
    800063f4:	1000                	addi	s0,sp,32
    800063f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063f8:	ffffc097          	auipc	ra,0xffffc
    800063fc:	8f0080e7          	jalr	-1808(ra) # 80001ce8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006400:	00d5151b          	slliw	a0,a0,0xd
    80006404:	0c2017b7          	lui	a5,0xc201
    80006408:	97aa                	add	a5,a5,a0
    8000640a:	c3c4                	sw	s1,4(a5)
}
    8000640c:	60e2                	ld	ra,24(sp)
    8000640e:	6442                	ld	s0,16(sp)
    80006410:	64a2                	ld	s1,8(sp)
    80006412:	6105                	addi	sp,sp,32
    80006414:	8082                	ret

0000000080006416 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006416:	1141                	addi	sp,sp,-16
    80006418:	e406                	sd	ra,8(sp)
    8000641a:	e022                	sd	s0,0(sp)
    8000641c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000641e:	479d                	li	a5,7
    80006420:	04a7cc63          	blt	a5,a0,80006478 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006424:	0003c797          	auipc	a5,0x3c
    80006428:	9ac78793          	addi	a5,a5,-1620 # 80041dd0 <disk>
    8000642c:	97aa                	add	a5,a5,a0
    8000642e:	0187c783          	lbu	a5,24(a5)
    80006432:	ebb9                	bnez	a5,80006488 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006434:	00451693          	slli	a3,a0,0x4
    80006438:	0003c797          	auipc	a5,0x3c
    8000643c:	99878793          	addi	a5,a5,-1640 # 80041dd0 <disk>
    80006440:	6398                	ld	a4,0(a5)
    80006442:	9736                	add	a4,a4,a3
    80006444:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006448:	6398                	ld	a4,0(a5)
    8000644a:	9736                	add	a4,a4,a3
    8000644c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006450:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006454:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006458:	97aa                	add	a5,a5,a0
    8000645a:	4705                	li	a4,1
    8000645c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006460:	0003c517          	auipc	a0,0x3c
    80006464:	98850513          	addi	a0,a0,-1656 # 80041de8 <disk+0x18>
    80006468:	ffffc097          	auipc	ra,0xffffc
    8000646c:	0be080e7          	jalr	190(ra) # 80002526 <wakeup>
}
    80006470:	60a2                	ld	ra,8(sp)
    80006472:	6402                	ld	s0,0(sp)
    80006474:	0141                	addi	sp,sp,16
    80006476:	8082                	ret
    panic("free_desc 1");
    80006478:	00002517          	auipc	a0,0x2
    8000647c:	43050513          	addi	a0,a0,1072 # 800088a8 <syscalls+0x318>
    80006480:	ffffa097          	auipc	ra,0xffffa
    80006484:	0c0080e7          	jalr	192(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006488:	00002517          	auipc	a0,0x2
    8000648c:	43050513          	addi	a0,a0,1072 # 800088b8 <syscalls+0x328>
    80006490:	ffffa097          	auipc	ra,0xffffa
    80006494:	0b0080e7          	jalr	176(ra) # 80000540 <panic>

0000000080006498 <virtio_disk_init>:
{
    80006498:	1101                	addi	sp,sp,-32
    8000649a:	ec06                	sd	ra,24(sp)
    8000649c:	e822                	sd	s0,16(sp)
    8000649e:	e426                	sd	s1,8(sp)
    800064a0:	e04a                	sd	s2,0(sp)
    800064a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064a4:	00002597          	auipc	a1,0x2
    800064a8:	42458593          	addi	a1,a1,1060 # 800088c8 <syscalls+0x338>
    800064ac:	0003c517          	auipc	a0,0x3c
    800064b0:	a4c50513          	addi	a0,a0,-1460 # 80041ef8 <disk+0x128>
    800064b4:	ffffb097          	auipc	ra,0xffffb
    800064b8:	81e080e7          	jalr	-2018(ra) # 80000cd2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064bc:	100017b7          	lui	a5,0x10001
    800064c0:	4398                	lw	a4,0(a5)
    800064c2:	2701                	sext.w	a4,a4
    800064c4:	747277b7          	lui	a5,0x74727
    800064c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064cc:	14f71b63          	bne	a4,a5,80006622 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064d0:	100017b7          	lui	a5,0x10001
    800064d4:	43dc                	lw	a5,4(a5)
    800064d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064d8:	4709                	li	a4,2
    800064da:	14e79463          	bne	a5,a4,80006622 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064de:	100017b7          	lui	a5,0x10001
    800064e2:	479c                	lw	a5,8(a5)
    800064e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064e6:	12e79e63          	bne	a5,a4,80006622 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064ea:	100017b7          	lui	a5,0x10001
    800064ee:	47d8                	lw	a4,12(a5)
    800064f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064f2:	554d47b7          	lui	a5,0x554d4
    800064f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064fa:	12f71463          	bne	a4,a5,80006622 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064fe:	100017b7          	lui	a5,0x10001
    80006502:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006506:	4705                	li	a4,1
    80006508:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000650a:	470d                	li	a4,3
    8000650c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000650e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006510:	c7ffe6b7          	lui	a3,0xc7ffe
    80006514:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fbc84f>
    80006518:	8f75                	and	a4,a4,a3
    8000651a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000651c:	472d                	li	a4,11
    8000651e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006520:	5bbc                	lw	a5,112(a5)
    80006522:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006526:	8ba1                	andi	a5,a5,8
    80006528:	10078563          	beqz	a5,80006632 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000652c:	100017b7          	lui	a5,0x10001
    80006530:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006534:	43fc                	lw	a5,68(a5)
    80006536:	2781                	sext.w	a5,a5
    80006538:	10079563          	bnez	a5,80006642 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000653c:	100017b7          	lui	a5,0x10001
    80006540:	5bdc                	lw	a5,52(a5)
    80006542:	2781                	sext.w	a5,a5
  if(max == 0)
    80006544:	10078763          	beqz	a5,80006652 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006548:	471d                	li	a4,7
    8000654a:	10f77c63          	bgeu	a4,a5,80006662 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000654e:	ffffa097          	auipc	ra,0xffffa
    80006552:	614080e7          	jalr	1556(ra) # 80000b62 <kalloc>
    80006556:	0003c497          	auipc	s1,0x3c
    8000655a:	87a48493          	addi	s1,s1,-1926 # 80041dd0 <disk>
    8000655e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006560:	ffffa097          	auipc	ra,0xffffa
    80006564:	602080e7          	jalr	1538(ra) # 80000b62 <kalloc>
    80006568:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	5f8080e7          	jalr	1528(ra) # 80000b62 <kalloc>
    80006572:	87aa                	mv	a5,a0
    80006574:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006576:	6088                	ld	a0,0(s1)
    80006578:	cd6d                	beqz	a0,80006672 <virtio_disk_init+0x1da>
    8000657a:	0003c717          	auipc	a4,0x3c
    8000657e:	85e73703          	ld	a4,-1954(a4) # 80041dd8 <disk+0x8>
    80006582:	cb65                	beqz	a4,80006672 <virtio_disk_init+0x1da>
    80006584:	c7fd                	beqz	a5,80006672 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006586:	6605                	lui	a2,0x1
    80006588:	4581                	li	a1,0
    8000658a:	ffffb097          	auipc	ra,0xffffb
    8000658e:	8d4080e7          	jalr	-1836(ra) # 80000e5e <memset>
  memset(disk.avail, 0, PGSIZE);
    80006592:	0003c497          	auipc	s1,0x3c
    80006596:	83e48493          	addi	s1,s1,-1986 # 80041dd0 <disk>
    8000659a:	6605                	lui	a2,0x1
    8000659c:	4581                	li	a1,0
    8000659e:	6488                	ld	a0,8(s1)
    800065a0:	ffffb097          	auipc	ra,0xffffb
    800065a4:	8be080e7          	jalr	-1858(ra) # 80000e5e <memset>
  memset(disk.used, 0, PGSIZE);
    800065a8:	6605                	lui	a2,0x1
    800065aa:	4581                	li	a1,0
    800065ac:	6888                	ld	a0,16(s1)
    800065ae:	ffffb097          	auipc	ra,0xffffb
    800065b2:	8b0080e7          	jalr	-1872(ra) # 80000e5e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065b6:	100017b7          	lui	a5,0x10001
    800065ba:	4721                	li	a4,8
    800065bc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800065be:	4098                	lw	a4,0(s1)
    800065c0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800065c4:	40d8                	lw	a4,4(s1)
    800065c6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800065ca:	6498                	ld	a4,8(s1)
    800065cc:	0007069b          	sext.w	a3,a4
    800065d0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800065d4:	9701                	srai	a4,a4,0x20
    800065d6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800065da:	6898                	ld	a4,16(s1)
    800065dc:	0007069b          	sext.w	a3,a4
    800065e0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800065e4:	9701                	srai	a4,a4,0x20
    800065e6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800065ea:	4705                	li	a4,1
    800065ec:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800065ee:	00e48c23          	sb	a4,24(s1)
    800065f2:	00e48ca3          	sb	a4,25(s1)
    800065f6:	00e48d23          	sb	a4,26(s1)
    800065fa:	00e48da3          	sb	a4,27(s1)
    800065fe:	00e48e23          	sb	a4,28(s1)
    80006602:	00e48ea3          	sb	a4,29(s1)
    80006606:	00e48f23          	sb	a4,30(s1)
    8000660a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000660e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006612:	0727a823          	sw	s2,112(a5)
}
    80006616:	60e2                	ld	ra,24(sp)
    80006618:	6442                	ld	s0,16(sp)
    8000661a:	64a2                	ld	s1,8(sp)
    8000661c:	6902                	ld	s2,0(sp)
    8000661e:	6105                	addi	sp,sp,32
    80006620:	8082                	ret
    panic("could not find virtio disk");
    80006622:	00002517          	auipc	a0,0x2
    80006626:	2b650513          	addi	a0,a0,694 # 800088d8 <syscalls+0x348>
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	f16080e7          	jalr	-234(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006632:	00002517          	auipc	a0,0x2
    80006636:	2c650513          	addi	a0,a0,710 # 800088f8 <syscalls+0x368>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	f06080e7          	jalr	-250(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006642:	00002517          	auipc	a0,0x2
    80006646:	2d650513          	addi	a0,a0,726 # 80008918 <syscalls+0x388>
    8000664a:	ffffa097          	auipc	ra,0xffffa
    8000664e:	ef6080e7          	jalr	-266(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006652:	00002517          	auipc	a0,0x2
    80006656:	2e650513          	addi	a0,a0,742 # 80008938 <syscalls+0x3a8>
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	ee6080e7          	jalr	-282(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006662:	00002517          	auipc	a0,0x2
    80006666:	2f650513          	addi	a0,a0,758 # 80008958 <syscalls+0x3c8>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	ed6080e7          	jalr	-298(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006672:	00002517          	auipc	a0,0x2
    80006676:	30650513          	addi	a0,a0,774 # 80008978 <syscalls+0x3e8>
    8000667a:	ffffa097          	auipc	ra,0xffffa
    8000667e:	ec6080e7          	jalr	-314(ra) # 80000540 <panic>

0000000080006682 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006682:	7119                	addi	sp,sp,-128
    80006684:	fc86                	sd	ra,120(sp)
    80006686:	f8a2                	sd	s0,112(sp)
    80006688:	f4a6                	sd	s1,104(sp)
    8000668a:	f0ca                	sd	s2,96(sp)
    8000668c:	ecce                	sd	s3,88(sp)
    8000668e:	e8d2                	sd	s4,80(sp)
    80006690:	e4d6                	sd	s5,72(sp)
    80006692:	e0da                	sd	s6,64(sp)
    80006694:	fc5e                	sd	s7,56(sp)
    80006696:	f862                	sd	s8,48(sp)
    80006698:	f466                	sd	s9,40(sp)
    8000669a:	f06a                	sd	s10,32(sp)
    8000669c:	ec6e                	sd	s11,24(sp)
    8000669e:	0100                	addi	s0,sp,128
    800066a0:	8aaa                	mv	s5,a0
    800066a2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066a4:	00c52d03          	lw	s10,12(a0)
    800066a8:	001d1d1b          	slliw	s10,s10,0x1
    800066ac:	1d02                	slli	s10,s10,0x20
    800066ae:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800066b2:	0003c517          	auipc	a0,0x3c
    800066b6:	84650513          	addi	a0,a0,-1978 # 80041ef8 <disk+0x128>
    800066ba:	ffffa097          	auipc	ra,0xffffa
    800066be:	6a8080e7          	jalr	1704(ra) # 80000d62 <acquire>
  for(int i = 0; i < 3; i++){
    800066c2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066c4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800066c6:	0003bb97          	auipc	s7,0x3b
    800066ca:	70ab8b93          	addi	s7,s7,1802 # 80041dd0 <disk>
  for(int i = 0; i < 3; i++){
    800066ce:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066d0:	0003cc97          	auipc	s9,0x3c
    800066d4:	828c8c93          	addi	s9,s9,-2008 # 80041ef8 <disk+0x128>
    800066d8:	a08d                	j	8000673a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800066da:	00fb8733          	add	a4,s7,a5
    800066de:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800066e2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800066e4:	0207c563          	bltz	a5,8000670e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800066e8:	2905                	addiw	s2,s2,1
    800066ea:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800066ec:	05690c63          	beq	s2,s6,80006744 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800066f0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800066f2:	0003b717          	auipc	a4,0x3b
    800066f6:	6de70713          	addi	a4,a4,1758 # 80041dd0 <disk>
    800066fa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800066fc:	01874683          	lbu	a3,24(a4)
    80006700:	fee9                	bnez	a3,800066da <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006702:	2785                	addiw	a5,a5,1
    80006704:	0705                	addi	a4,a4,1
    80006706:	fe979be3          	bne	a5,s1,800066fc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000670a:	57fd                	li	a5,-1
    8000670c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000670e:	01205d63          	blez	s2,80006728 <virtio_disk_rw+0xa6>
    80006712:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006714:	000a2503          	lw	a0,0(s4)
    80006718:	00000097          	auipc	ra,0x0
    8000671c:	cfe080e7          	jalr	-770(ra) # 80006416 <free_desc>
      for(int j = 0; j < i; j++)
    80006720:	2d85                	addiw	s11,s11,1
    80006722:	0a11                	addi	s4,s4,4
    80006724:	ff2d98e3          	bne	s11,s2,80006714 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006728:	85e6                	mv	a1,s9
    8000672a:	0003b517          	auipc	a0,0x3b
    8000672e:	6be50513          	addi	a0,a0,1726 # 80041de8 <disk+0x18>
    80006732:	ffffc097          	auipc	ra,0xffffc
    80006736:	d90080e7          	jalr	-624(ra) # 800024c2 <sleep>
  for(int i = 0; i < 3; i++){
    8000673a:	f8040a13          	addi	s4,s0,-128
{
    8000673e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006740:	894e                	mv	s2,s3
    80006742:	b77d                	j	800066f0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006744:	f8042503          	lw	a0,-128(s0)
    80006748:	00a50713          	addi	a4,a0,10
    8000674c:	0712                	slli	a4,a4,0x4

  if(write)
    8000674e:	0003b797          	auipc	a5,0x3b
    80006752:	68278793          	addi	a5,a5,1666 # 80041dd0 <disk>
    80006756:	00e786b3          	add	a3,a5,a4
    8000675a:	01803633          	snez	a2,s8
    8000675e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006760:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006764:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006768:	f6070613          	addi	a2,a4,-160
    8000676c:	6394                	ld	a3,0(a5)
    8000676e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006770:	00870593          	addi	a1,a4,8
    80006774:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006776:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006778:	0007b803          	ld	a6,0(a5)
    8000677c:	9642                	add	a2,a2,a6
    8000677e:	46c1                	li	a3,16
    80006780:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006782:	4585                	li	a1,1
    80006784:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006788:	f8442683          	lw	a3,-124(s0)
    8000678c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006790:	0692                	slli	a3,a3,0x4
    80006792:	9836                	add	a6,a6,a3
    80006794:	058a8613          	addi	a2,s5,88
    80006798:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000679c:	0007b803          	ld	a6,0(a5)
    800067a0:	96c2                	add	a3,a3,a6
    800067a2:	40000613          	li	a2,1024
    800067a6:	c690                	sw	a2,8(a3)
  if(write)
    800067a8:	001c3613          	seqz	a2,s8
    800067ac:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067b0:	00166613          	ori	a2,a2,1
    800067b4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067b8:	f8842603          	lw	a2,-120(s0)
    800067bc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067c0:	00250693          	addi	a3,a0,2
    800067c4:	0692                	slli	a3,a3,0x4
    800067c6:	96be                	add	a3,a3,a5
    800067c8:	58fd                	li	a7,-1
    800067ca:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067ce:	0612                	slli	a2,a2,0x4
    800067d0:	9832                	add	a6,a6,a2
    800067d2:	f9070713          	addi	a4,a4,-112
    800067d6:	973e                	add	a4,a4,a5
    800067d8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800067dc:	6398                	ld	a4,0(a5)
    800067de:	9732                	add	a4,a4,a2
    800067e0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067e2:	4609                	li	a2,2
    800067e4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800067e8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067ec:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800067f0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067f4:	6794                	ld	a3,8(a5)
    800067f6:	0026d703          	lhu	a4,2(a3)
    800067fa:	8b1d                	andi	a4,a4,7
    800067fc:	0706                	slli	a4,a4,0x1
    800067fe:	96ba                	add	a3,a3,a4
    80006800:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006804:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006808:	6798                	ld	a4,8(a5)
    8000680a:	00275783          	lhu	a5,2(a4)
    8000680e:	2785                	addiw	a5,a5,1
    80006810:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006814:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006818:	100017b7          	lui	a5,0x10001
    8000681c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006820:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006824:	0003b917          	auipc	s2,0x3b
    80006828:	6d490913          	addi	s2,s2,1748 # 80041ef8 <disk+0x128>
  while(b->disk == 1) {
    8000682c:	4485                	li	s1,1
    8000682e:	00b79c63          	bne	a5,a1,80006846 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006832:	85ca                	mv	a1,s2
    80006834:	8556                	mv	a0,s5
    80006836:	ffffc097          	auipc	ra,0xffffc
    8000683a:	c8c080e7          	jalr	-884(ra) # 800024c2 <sleep>
  while(b->disk == 1) {
    8000683e:	004aa783          	lw	a5,4(s5)
    80006842:	fe9788e3          	beq	a5,s1,80006832 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006846:	f8042903          	lw	s2,-128(s0)
    8000684a:	00290713          	addi	a4,s2,2
    8000684e:	0712                	slli	a4,a4,0x4
    80006850:	0003b797          	auipc	a5,0x3b
    80006854:	58078793          	addi	a5,a5,1408 # 80041dd0 <disk>
    80006858:	97ba                	add	a5,a5,a4
    8000685a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000685e:	0003b997          	auipc	s3,0x3b
    80006862:	57298993          	addi	s3,s3,1394 # 80041dd0 <disk>
    80006866:	00491713          	slli	a4,s2,0x4
    8000686a:	0009b783          	ld	a5,0(s3)
    8000686e:	97ba                	add	a5,a5,a4
    80006870:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006874:	854a                	mv	a0,s2
    80006876:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000687a:	00000097          	auipc	ra,0x0
    8000687e:	b9c080e7          	jalr	-1124(ra) # 80006416 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006882:	8885                	andi	s1,s1,1
    80006884:	f0ed                	bnez	s1,80006866 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006886:	0003b517          	auipc	a0,0x3b
    8000688a:	67250513          	addi	a0,a0,1650 # 80041ef8 <disk+0x128>
    8000688e:	ffffa097          	auipc	ra,0xffffa
    80006892:	588080e7          	jalr	1416(ra) # 80000e16 <release>
}
    80006896:	70e6                	ld	ra,120(sp)
    80006898:	7446                	ld	s0,112(sp)
    8000689a:	74a6                	ld	s1,104(sp)
    8000689c:	7906                	ld	s2,96(sp)
    8000689e:	69e6                	ld	s3,88(sp)
    800068a0:	6a46                	ld	s4,80(sp)
    800068a2:	6aa6                	ld	s5,72(sp)
    800068a4:	6b06                	ld	s6,64(sp)
    800068a6:	7be2                	ld	s7,56(sp)
    800068a8:	7c42                	ld	s8,48(sp)
    800068aa:	7ca2                	ld	s9,40(sp)
    800068ac:	7d02                	ld	s10,32(sp)
    800068ae:	6de2                	ld	s11,24(sp)
    800068b0:	6109                	addi	sp,sp,128
    800068b2:	8082                	ret

00000000800068b4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068b4:	1101                	addi	sp,sp,-32
    800068b6:	ec06                	sd	ra,24(sp)
    800068b8:	e822                	sd	s0,16(sp)
    800068ba:	e426                	sd	s1,8(sp)
    800068bc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068be:	0003b497          	auipc	s1,0x3b
    800068c2:	51248493          	addi	s1,s1,1298 # 80041dd0 <disk>
    800068c6:	0003b517          	auipc	a0,0x3b
    800068ca:	63250513          	addi	a0,a0,1586 # 80041ef8 <disk+0x128>
    800068ce:	ffffa097          	auipc	ra,0xffffa
    800068d2:	494080e7          	jalr	1172(ra) # 80000d62 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068d6:	10001737          	lui	a4,0x10001
    800068da:	533c                	lw	a5,96(a4)
    800068dc:	8b8d                	andi	a5,a5,3
    800068de:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068e0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068e4:	689c                	ld	a5,16(s1)
    800068e6:	0204d703          	lhu	a4,32(s1)
    800068ea:	0027d783          	lhu	a5,2(a5)
    800068ee:	04f70863          	beq	a4,a5,8000693e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800068f2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068f6:	6898                	ld	a4,16(s1)
    800068f8:	0204d783          	lhu	a5,32(s1)
    800068fc:	8b9d                	andi	a5,a5,7
    800068fe:	078e                	slli	a5,a5,0x3
    80006900:	97ba                	add	a5,a5,a4
    80006902:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006904:	00278713          	addi	a4,a5,2
    80006908:	0712                	slli	a4,a4,0x4
    8000690a:	9726                	add	a4,a4,s1
    8000690c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006910:	e721                	bnez	a4,80006958 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006912:	0789                	addi	a5,a5,2
    80006914:	0792                	slli	a5,a5,0x4
    80006916:	97a6                	add	a5,a5,s1
    80006918:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000691a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000691e:	ffffc097          	auipc	ra,0xffffc
    80006922:	c08080e7          	jalr	-1016(ra) # 80002526 <wakeup>

    disk.used_idx += 1;
    80006926:	0204d783          	lhu	a5,32(s1)
    8000692a:	2785                	addiw	a5,a5,1
    8000692c:	17c2                	slli	a5,a5,0x30
    8000692e:	93c1                	srli	a5,a5,0x30
    80006930:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006934:	6898                	ld	a4,16(s1)
    80006936:	00275703          	lhu	a4,2(a4)
    8000693a:	faf71ce3          	bne	a4,a5,800068f2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000693e:	0003b517          	auipc	a0,0x3b
    80006942:	5ba50513          	addi	a0,a0,1466 # 80041ef8 <disk+0x128>
    80006946:	ffffa097          	auipc	ra,0xffffa
    8000694a:	4d0080e7          	jalr	1232(ra) # 80000e16 <release>
}
    8000694e:	60e2                	ld	ra,24(sp)
    80006950:	6442                	ld	s0,16(sp)
    80006952:	64a2                	ld	s1,8(sp)
    80006954:	6105                	addi	sp,sp,32
    80006956:	8082                	ret
      panic("virtio_disk_intr status");
    80006958:	00002517          	auipc	a0,0x2
    8000695c:	03850513          	addi	a0,a0,56 # 80008990 <syscalls+0x400>
    80006960:	ffffa097          	auipc	ra,0xffffa
    80006964:	be0080e7          	jalr	-1056(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
