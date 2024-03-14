
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a7013103          	ld	sp,-1424(sp) # 80008a70 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	a9070713          	addi	a4,a4,-1392 # 80008ae0 <timer_scratch>
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
    80000066:	1ee78793          	addi	a5,a5,494 # 80006250 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc8af>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e9478793          	addi	a5,a5,-364 # 80000f40 <main>
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
    8000012e:	6f4080e7          	jalr	1780(ra) # 8000281e <either_copyin>
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
    8000018e:	a9650513          	addi	a0,a0,-1386 # 80010c20 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b0c080e7          	jalr	-1268(ra) # 80000c9e <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	a8648493          	addi	s1,s1,-1402 # 80010c20 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	b1690913          	addi	s2,s2,-1258 # 80010cb8 <cons+0x98>
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
    800001c4:	a52080e7          	jalr	-1454(ra) # 80001c12 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	4a0080e7          	jalr	1184(ra) # 80002668 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1ea080e7          	jalr	490(ra) # 800023c0 <sleep>
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
    80000216:	5b6080e7          	jalr	1462(ra) # 800027c8 <either_copyout>
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
    8000022a:	9fa50513          	addi	a0,a0,-1542 # 80010c20 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b24080e7          	jalr	-1244(ra) # 80000d52 <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	9e450513          	addi	a0,a0,-1564 # 80010c20 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b0e080e7          	jalr	-1266(ra) # 80000d52 <release>
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
    80000276:	a4f72323          	sw	a5,-1466(a4) # 80010cb8 <cons+0x98>
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
    800002d0:	95450513          	addi	a0,a0,-1708 # 80010c20 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	9ca080e7          	jalr	-1590(ra) # 80000c9e <acquire>

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
    800002f6:	582080e7          	jalr	1410(ra) # 80002874 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	92650513          	addi	a0,a0,-1754 # 80010c20 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	a50080e7          	jalr	-1456(ra) # 80000d52 <release>
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
    80000322:	90270713          	addi	a4,a4,-1790 # 80010c20 <cons>
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
    8000034c:	8d878793          	addi	a5,a5,-1832 # 80010c20 <cons>
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
    8000037a:	9427a783          	lw	a5,-1726(a5) # 80010cb8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	89670713          	addi	a4,a4,-1898 # 80010c20 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	88648493          	addi	s1,s1,-1914 # 80010c20 <cons>
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
    800003da:	84a70713          	addi	a4,a4,-1974 # 80010c20 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	8cf72a23          	sw	a5,-1836(a4) # 80010cc0 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	80e78793          	addi	a5,a5,-2034 # 80010c20 <cons>
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
    8000043a:	88c7a323          	sw	a2,-1914(a5) # 80010cbc <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	87a50513          	addi	a0,a0,-1926 # 80010cb8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fde080e7          	jalr	-34(ra) # 80002424 <wakeup>
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
    80000464:	7c050513          	addi	a0,a0,1984 # 80010c20 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	7a6080e7          	jalr	1958(ra) # 80000c0e <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	33e080e7          	jalr	830(ra) # 800007ae <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	94078793          	addi	a5,a5,-1728 # 80020db8 <devsw>
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
    80000562:	7807a123          	sw	zero,1922(a5) # 80010ce0 <pr+0x18>
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
    80000596:	4ef72f23          	sw	a5,1278(a4) # 80008a90 <panicked>
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
    800005d2:	712dad83          	lw	s11,1810(s11) # 80010ce0 <pr+0x18>
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
    80000610:	6bc50513          	addi	a0,a0,1724 # 80010cc8 <pr>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	68a080e7          	jalr	1674(ra) # 80000c9e <acquire>
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
    8000076e:	55e50513          	addi	a0,a0,1374 # 80010cc8 <pr>
    80000772:	00000097          	auipc	ra,0x0
    80000776:	5e0080e7          	jalr	1504(ra) # 80000d52 <release>
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
    8000078a:	54248493          	addi	s1,s1,1346 # 80010cc8 <pr>
    8000078e:	00008597          	auipc	a1,0x8
    80000792:	8ba58593          	addi	a1,a1,-1862 # 80008048 <__func__.1+0x40>
    80000796:	8526                	mv	a0,s1
    80000798:	00000097          	auipc	ra,0x0
    8000079c:	476080e7          	jalr	1142(ra) # 80000c0e <initlock>
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
    800007ea:	50250513          	addi	a0,a0,1282 # 80010ce8 <uart_tx_lock>
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	420080e7          	jalr	1056(ra) # 80000c0e <initlock>
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
    8000080e:	448080e7          	jalr	1096(ra) # 80000c52 <push_off>

  if(panicked){
    80000812:	00008797          	auipc	a5,0x8
    80000816:	27e7a783          	lw	a5,638(a5) # 80008a90 <panicked>
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
    8000083c:	4ba080e7          	jalr	1210(ra) # 80000cf2 <pop_off>
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
    8000084e:	24e7b783          	ld	a5,590(a5) # 80008a98 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	24e73703          	ld	a4,590(a4) # 80008aa0 <uart_tx_w>
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
    80000878:	474a0a13          	addi	s4,s4,1140 # 80010ce8 <uart_tx_lock>
    uart_tx_r += 1;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	21c48493          	addi	s1,s1,540 # 80008a98 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	21c98993          	addi	s3,s3,540 # 80008aa0 <uart_tx_w>
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
    800008aa:	b7e080e7          	jalr	-1154(ra) # 80002424 <wakeup>
    
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
    800008e6:	40650513          	addi	a0,a0,1030 # 80010ce8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	3b4080e7          	jalr	948(ra) # 80000c9e <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	19e7a783          	lw	a5,414(a5) # 80008a90 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008717          	auipc	a4,0x8
    80000900:	1a473703          	ld	a4,420(a4) # 80008aa0 <uart_tx_w>
    80000904:	00008797          	auipc	a5,0x8
    80000908:	1947b783          	ld	a5,404(a5) # 80008a98 <uart_tx_r>
    8000090c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010997          	auipc	s3,0x10
    80000914:	3d898993          	addi	s3,s3,984 # 80010ce8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	18048493          	addi	s1,s1,384 # 80008a98 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	18090913          	addi	s2,s2,384 # 80008aa0 <uart_tx_w>
    80000928:	00e79f63          	bne	a5,a4,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85ce                	mv	a1,s3
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	a90080e7          	jalr	-1392(ra) # 800023c0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093703          	ld	a4,0(s2)
    8000093c:	609c                	ld	a5,0(s1)
    8000093e:	02078793          	addi	a5,a5,32
    80000942:	fee785e3          	beq	a5,a4,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	3a248493          	addi	s1,s1,930 # 80010ce8 <uart_tx_lock>
    8000094e:	01f77793          	andi	a5,a4,31
    80000952:	97a6                	add	a5,a5,s1
    80000954:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000958:	0705                	addi	a4,a4,1
    8000095a:	00008797          	auipc	a5,0x8
    8000095e:	14e7b323          	sd	a4,326(a5) # 80008aa0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee8080e7          	jalr	-280(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	3e6080e7          	jalr	998(ra) # 80000d52 <release>
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
    800009d0:	31c48493          	addi	s1,s1,796 # 80010ce8 <uart_tx_lock>
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2c8080e7          	jalr	712(ra) # 80000c9e <acquire>
  uartstart();
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	e6c080e7          	jalr	-404(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    800009e6:	8526                	mv	a0,s1
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	36a080e7          	jalr	874(ra) # 80000d52 <release>
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
    80000a0c:	0a87b783          	ld	a5,168(a5) # 80008ab0 <MAX_PAGES>
    80000a10:	c799                	beqz	a5,80000a1e <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a12:	00008717          	auipc	a4,0x8
    80000a16:	09673703          	ld	a4,150(a4) # 80008aa8 <FREE_PAGES>
    80000a1a:	06f77663          	bgeu	a4,a5,80000a86 <kfree+0x8c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03449793          	slli	a5,s1,0x34
    80000a22:	efc1                	bnez	a5,80000aba <kfree+0xc0>
    80000a24:	00021797          	auipc	a5,0x21
    80000a28:	52c78793          	addi	a5,a5,1324 # 80021f50 <end>
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
    80000a42:	35c080e7          	jalr	860(ra) # 80000d9a <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a46:	00010917          	auipc	s2,0x10
    80000a4a:	2da90913          	addi	s2,s2,730 # 80010d20 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <acquire>
    r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a62:	00008717          	auipc	a4,0x8
    80000a66:	04670713          	addi	a4,a4,70 # 80008aa8 <FREE_PAGES>
    80000a6a:	631c                	ld	a5,0(a4)
    80000a6c:	0785                	addi	a5,a5,1
    80000a6e:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000a70:	854a                	mv	a0,s2
    80000a72:	00000097          	auipc	ra,0x0
    80000a76:	2e0080e7          	jalr	736(ra) # 80000d52 <release>
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
    80000b2a:	1fa50513          	addi	a0,a0,506 # 80010d20 <kmem>
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	0e0080e7          	jalr	224(ra) # 80000c0e <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b36:	45c5                	li	a1,17
    80000b38:	05ee                	slli	a1,a1,0x1b
    80000b3a:	00021517          	auipc	a0,0x21
    80000b3e:	41650513          	addi	a0,a0,1046 # 80021f50 <end>
    80000b42:	00000097          	auipc	ra,0x0
    80000b46:	f88080e7          	jalr	-120(ra) # 80000aca <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b4a:	00008797          	auipc	a5,0x8
    80000b4e:	f5e7b783          	ld	a5,-162(a5) # 80008aa8 <FREE_PAGES>
    80000b52:	00008717          	auipc	a4,0x8
    80000b56:	f4f73f23          	sd	a5,-162(a4) # 80008ab0 <MAX_PAGES>
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
    80000b70:	f3c7b783          	ld	a5,-196(a5) # 80008aa8 <FREE_PAGES>
    80000b74:	cbb1                	beqz	a5,80000bc8 <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000b76:	00010497          	auipc	s1,0x10
    80000b7a:	1aa48493          	addi	s1,s1,426 # 80010d20 <kmem>
    80000b7e:	8526                	mv	a0,s1
    80000b80:	00000097          	auipc	ra,0x0
    80000b84:	11e080e7          	jalr	286(ra) # 80000c9e <acquire>
    r = kmem.freelist;
    80000b88:	6c84                	ld	s1,24(s1)
    if (r)
    80000b8a:	c8ad                	beqz	s1,80000bfc <kalloc+0x9a>
        kmem.freelist = r->next;
    80000b8c:	609c                	ld	a5,0(s1)
    80000b8e:	00010517          	auipc	a0,0x10
    80000b92:	19250513          	addi	a0,a0,402 # 80010d20 <kmem>
    80000b96:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	1ba080e7          	jalr	442(ra) # 80000d52 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000ba0:	6605                	lui	a2,0x1
    80000ba2:	4595                	li	a1,5
    80000ba4:	8526                	mv	a0,s1
    80000ba6:	00000097          	auipc	ra,0x0
    80000baa:	1f4080e7          	jalr	500(ra) # 80000d9a <memset>
    FREE_PAGES--;
    80000bae:	00008717          	auipc	a4,0x8
    80000bb2:	efa70713          	addi	a4,a4,-262 # 80008aa8 <FREE_PAGES>
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
    80000bc8:	04f00693          	li	a3,79
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
    80000c00:	12450513          	addi	a0,a0,292 # 80010d20 <kmem>
    80000c04:	00000097          	auipc	ra,0x0
    80000c08:	14e080e7          	jalr	334(ra) # 80000d52 <release>
    if (r)
    80000c0c:	b74d                	j	80000bae <kalloc+0x4c>

0000000080000c0e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c0e:	1141                	addi	sp,sp,-16
    80000c10:	e422                	sd	s0,8(sp)
    80000c12:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c14:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c16:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c1a:	00053823          	sd	zero,16(a0)
}
    80000c1e:	6422                	ld	s0,8(sp)
    80000c20:	0141                	addi	sp,sp,16
    80000c22:	8082                	ret

0000000080000c24 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c24:	411c                	lw	a5,0(a0)
    80000c26:	e399                	bnez	a5,80000c2c <holding+0x8>
    80000c28:	4501                	li	a0,0
  return r;
}
    80000c2a:	8082                	ret
{
    80000c2c:	1101                	addi	sp,sp,-32
    80000c2e:	ec06                	sd	ra,24(sp)
    80000c30:	e822                	sd	s0,16(sp)
    80000c32:	e426                	sd	s1,8(sp)
    80000c34:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c36:	6904                	ld	s1,16(a0)
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	fbe080e7          	jalr	-66(ra) # 80001bf6 <mycpu>
    80000c40:	40a48533          	sub	a0,s1,a0
    80000c44:	00153513          	seqz	a0,a0
}
    80000c48:	60e2                	ld	ra,24(sp)
    80000c4a:	6442                	ld	s0,16(sp)
    80000c4c:	64a2                	ld	s1,8(sp)
    80000c4e:	6105                	addi	sp,sp,32
    80000c50:	8082                	ret

0000000080000c52 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c52:	1101                	addi	sp,sp,-32
    80000c54:	ec06                	sd	ra,24(sp)
    80000c56:	e822                	sd	s0,16(sp)
    80000c58:	e426                	sd	s1,8(sp)
    80000c5a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c5c:	100024f3          	csrr	s1,sstatus
    80000c60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c64:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c66:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c6a:	00001097          	auipc	ra,0x1
    80000c6e:	f8c080e7          	jalr	-116(ra) # 80001bf6 <mycpu>
    80000c72:	5d3c                	lw	a5,120(a0)
    80000c74:	cf89                	beqz	a5,80000c8e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c76:	00001097          	auipc	ra,0x1
    80000c7a:	f80080e7          	jalr	-128(ra) # 80001bf6 <mycpu>
    80000c7e:	5d3c                	lw	a5,120(a0)
    80000c80:	2785                	addiw	a5,a5,1
    80000c82:	dd3c                	sw	a5,120(a0)
}
    80000c84:	60e2                	ld	ra,24(sp)
    80000c86:	6442                	ld	s0,16(sp)
    80000c88:	64a2                	ld	s1,8(sp)
    80000c8a:	6105                	addi	sp,sp,32
    80000c8c:	8082                	ret
    mycpu()->intena = old;
    80000c8e:	00001097          	auipc	ra,0x1
    80000c92:	f68080e7          	jalr	-152(ra) # 80001bf6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c96:	8085                	srli	s1,s1,0x1
    80000c98:	8885                	andi	s1,s1,1
    80000c9a:	dd64                	sw	s1,124(a0)
    80000c9c:	bfe9                	j	80000c76 <push_off+0x24>

0000000080000c9e <acquire>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	fa8080e7          	jalr	-88(ra) # 80000c52 <push_off>
  if(holding(lk))
    80000cb2:	8526                	mv	a0,s1
    80000cb4:	00000097          	auipc	ra,0x0
    80000cb8:	f70080e7          	jalr	-144(ra) # 80000c24 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cbc:	4705                	li	a4,1
  if(holding(lk))
    80000cbe:	e115                	bnez	a0,80000ce2 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cc0:	87ba                	mv	a5,a4
    80000cc2:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cc6:	2781                	sext.w	a5,a5
    80000cc8:	ffe5                	bnez	a5,80000cc0 <acquire+0x22>
  __sync_synchronize();
    80000cca:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cce:	00001097          	auipc	ra,0x1
    80000cd2:	f28080e7          	jalr	-216(ra) # 80001bf6 <mycpu>
    80000cd6:	e888                	sd	a0,16(s1)
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
    panic("acquire");
    80000ce2:	00007517          	auipc	a0,0x7
    80000ce6:	3ce50513          	addi	a0,a0,974 # 800080b0 <digits+0x60>
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	856080e7          	jalr	-1962(ra) # 80000540 <panic>

0000000080000cf2 <pop_off>:

void
pop_off(void)
{
    80000cf2:	1141                	addi	sp,sp,-16
    80000cf4:	e406                	sd	ra,8(sp)
    80000cf6:	e022                	sd	s0,0(sp)
    80000cf8:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cfa:	00001097          	auipc	ra,0x1
    80000cfe:	efc080e7          	jalr	-260(ra) # 80001bf6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d06:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d08:	e78d                	bnez	a5,80000d32 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d0a:	5d3c                	lw	a5,120(a0)
    80000d0c:	02f05b63          	blez	a5,80000d42 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d10:	37fd                	addiw	a5,a5,-1
    80000d12:	0007871b          	sext.w	a4,a5
    80000d16:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d18:	eb09                	bnez	a4,80000d2a <pop_off+0x38>
    80000d1a:	5d7c                	lw	a5,124(a0)
    80000d1c:	c799                	beqz	a5,80000d2a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d26:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d2a:	60a2                	ld	ra,8(sp)
    80000d2c:	6402                	ld	s0,0(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret
    panic("pop_off - interruptible");
    80000d32:	00007517          	auipc	a0,0x7
    80000d36:	38650513          	addi	a0,a0,902 # 800080b8 <digits+0x68>
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	806080e7          	jalr	-2042(ra) # 80000540 <panic>
    panic("pop_off");
    80000d42:	00007517          	auipc	a0,0x7
    80000d46:	38e50513          	addi	a0,a0,910 # 800080d0 <digits+0x80>
    80000d4a:	fffff097          	auipc	ra,0xfffff
    80000d4e:	7f6080e7          	jalr	2038(ra) # 80000540 <panic>

0000000080000d52 <release>:
{
    80000d52:	1101                	addi	sp,sp,-32
    80000d54:	ec06                	sd	ra,24(sp)
    80000d56:	e822                	sd	s0,16(sp)
    80000d58:	e426                	sd	s1,8(sp)
    80000d5a:	1000                	addi	s0,sp,32
    80000d5c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d5e:	00000097          	auipc	ra,0x0
    80000d62:	ec6080e7          	jalr	-314(ra) # 80000c24 <holding>
    80000d66:	c115                	beqz	a0,80000d8a <release+0x38>
  lk->cpu = 0;
    80000d68:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d6c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d70:	0f50000f          	fence	iorw,ow
    80000d74:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d78:	00000097          	auipc	ra,0x0
    80000d7c:	f7a080e7          	jalr	-134(ra) # 80000cf2 <pop_off>
}
    80000d80:	60e2                	ld	ra,24(sp)
    80000d82:	6442                	ld	s0,16(sp)
    80000d84:	64a2                	ld	s1,8(sp)
    80000d86:	6105                	addi	sp,sp,32
    80000d88:	8082                	ret
    panic("release");
    80000d8a:	00007517          	auipc	a0,0x7
    80000d8e:	34e50513          	addi	a0,a0,846 # 800080d8 <digits+0x88>
    80000d92:	fffff097          	auipc	ra,0xfffff
    80000d96:	7ae080e7          	jalr	1966(ra) # 80000540 <panic>

0000000080000d9a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d9a:	1141                	addi	sp,sp,-16
    80000d9c:	e422                	sd	s0,8(sp)
    80000d9e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000da0:	ca19                	beqz	a2,80000db6 <memset+0x1c>
    80000da2:	87aa                	mv	a5,a0
    80000da4:	1602                	slli	a2,a2,0x20
    80000da6:	9201                	srli	a2,a2,0x20
    80000da8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000dac:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000db0:	0785                	addi	a5,a5,1
    80000db2:	fee79de3          	bne	a5,a4,80000dac <memset+0x12>
  }
  return dst;
}
    80000db6:	6422                	ld	s0,8(sp)
    80000db8:	0141                	addi	sp,sp,16
    80000dba:	8082                	ret

0000000080000dbc <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000dbc:	1141                	addi	sp,sp,-16
    80000dbe:	e422                	sd	s0,8(sp)
    80000dc0:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dc2:	ca05                	beqz	a2,80000df2 <memcmp+0x36>
    80000dc4:	fff6069b          	addiw	a3,a2,-1
    80000dc8:	1682                	slli	a3,a3,0x20
    80000dca:	9281                	srli	a3,a3,0x20
    80000dcc:	0685                	addi	a3,a3,1
    80000dce:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dd0:	00054783          	lbu	a5,0(a0)
    80000dd4:	0005c703          	lbu	a4,0(a1)
    80000dd8:	00e79863          	bne	a5,a4,80000de8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ddc:	0505                	addi	a0,a0,1
    80000dde:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000de0:	fed518e3          	bne	a0,a3,80000dd0 <memcmp+0x14>
  }

  return 0;
    80000de4:	4501                	li	a0,0
    80000de6:	a019                	j	80000dec <memcmp+0x30>
      return *s1 - *s2;
    80000de8:	40e7853b          	subw	a0,a5,a4
}
    80000dec:	6422                	ld	s0,8(sp)
    80000dee:	0141                	addi	sp,sp,16
    80000df0:	8082                	ret
  return 0;
    80000df2:	4501                	li	a0,0
    80000df4:	bfe5                	j	80000dec <memcmp+0x30>

0000000080000df6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e422                	sd	s0,8(sp)
    80000dfa:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dfc:	c205                	beqz	a2,80000e1c <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dfe:	02a5e263          	bltu	a1,a0,80000e22 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e02:	1602                	slli	a2,a2,0x20
    80000e04:	9201                	srli	a2,a2,0x20
    80000e06:	00c587b3          	add	a5,a1,a2
{
    80000e0a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e0c:	0585                	addi	a1,a1,1
    80000e0e:	0705                	addi	a4,a4,1
    80000e10:	fff5c683          	lbu	a3,-1(a1)
    80000e14:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e18:	fef59ae3          	bne	a1,a5,80000e0c <memmove+0x16>

  return dst;
}
    80000e1c:	6422                	ld	s0,8(sp)
    80000e1e:	0141                	addi	sp,sp,16
    80000e20:	8082                	ret
  if(s < d && s + n > d){
    80000e22:	02061693          	slli	a3,a2,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	00d58733          	add	a4,a1,a3
    80000e2c:	fce57be3          	bgeu	a0,a4,80000e02 <memmove+0xc>
    d += n;
    80000e30:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e32:	fff6079b          	addiw	a5,a2,-1
    80000e36:	1782                	slli	a5,a5,0x20
    80000e38:	9381                	srli	a5,a5,0x20
    80000e3a:	fff7c793          	not	a5,a5
    80000e3e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e40:	177d                	addi	a4,a4,-1
    80000e42:	16fd                	addi	a3,a3,-1
    80000e44:	00074603          	lbu	a2,0(a4)
    80000e48:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e4c:	fee79ae3          	bne	a5,a4,80000e40 <memmove+0x4a>
    80000e50:	b7f1                	j	80000e1c <memmove+0x26>

0000000080000e52 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e52:	1141                	addi	sp,sp,-16
    80000e54:	e406                	sd	ra,8(sp)
    80000e56:	e022                	sd	s0,0(sp)
    80000e58:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e5a:	00000097          	auipc	ra,0x0
    80000e5e:	f9c080e7          	jalr	-100(ra) # 80000df6 <memmove>
}
    80000e62:	60a2                	ld	ra,8(sp)
    80000e64:	6402                	ld	s0,0(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e70:	ce11                	beqz	a2,80000e8c <strncmp+0x22>
    80000e72:	00054783          	lbu	a5,0(a0)
    80000e76:	cf89                	beqz	a5,80000e90 <strncmp+0x26>
    80000e78:	0005c703          	lbu	a4,0(a1)
    80000e7c:	00f71a63          	bne	a4,a5,80000e90 <strncmp+0x26>
    n--, p++, q++;
    80000e80:	367d                	addiw	a2,a2,-1
    80000e82:	0505                	addi	a0,a0,1
    80000e84:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e86:	f675                	bnez	a2,80000e72 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e88:	4501                	li	a0,0
    80000e8a:	a809                	j	80000e9c <strncmp+0x32>
    80000e8c:	4501                	li	a0,0
    80000e8e:	a039                	j	80000e9c <strncmp+0x32>
  if(n == 0)
    80000e90:	ca09                	beqz	a2,80000ea2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e92:	00054503          	lbu	a0,0(a0)
    80000e96:	0005c783          	lbu	a5,0(a1)
    80000e9a:	9d1d                	subw	a0,a0,a5
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret
    return 0;
    80000ea2:	4501                	li	a0,0
    80000ea4:	bfe5                	j	80000e9c <strncmp+0x32>

0000000080000ea6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ea6:	1141                	addi	sp,sp,-16
    80000ea8:	e422                	sd	s0,8(sp)
    80000eaa:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000eac:	872a                	mv	a4,a0
    80000eae:	8832                	mv	a6,a2
    80000eb0:	367d                	addiw	a2,a2,-1
    80000eb2:	01005963          	blez	a6,80000ec4 <strncpy+0x1e>
    80000eb6:	0705                	addi	a4,a4,1
    80000eb8:	0005c783          	lbu	a5,0(a1)
    80000ebc:	fef70fa3          	sb	a5,-1(a4)
    80000ec0:	0585                	addi	a1,a1,1
    80000ec2:	f7f5                	bnez	a5,80000eae <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ec4:	86ba                	mv	a3,a4
    80000ec6:	00c05c63          	blez	a2,80000ede <strncpy+0x38>
    *s++ = 0;
    80000eca:	0685                	addi	a3,a3,1
    80000ecc:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ed0:	40d707bb          	subw	a5,a4,a3
    80000ed4:	37fd                	addiw	a5,a5,-1
    80000ed6:	010787bb          	addw	a5,a5,a6
    80000eda:	fef048e3          	bgtz	a5,80000eca <strncpy+0x24>
  return os;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret

0000000080000ee4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ee4:	1141                	addi	sp,sp,-16
    80000ee6:	e422                	sd	s0,8(sp)
    80000ee8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eea:	02c05363          	blez	a2,80000f10 <safestrcpy+0x2c>
    80000eee:	fff6069b          	addiw	a3,a2,-1
    80000ef2:	1682                	slli	a3,a3,0x20
    80000ef4:	9281                	srli	a3,a3,0x20
    80000ef6:	96ae                	add	a3,a3,a1
    80000ef8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000efa:	00d58963          	beq	a1,a3,80000f0c <safestrcpy+0x28>
    80000efe:	0585                	addi	a1,a1,1
    80000f00:	0785                	addi	a5,a5,1
    80000f02:	fff5c703          	lbu	a4,-1(a1)
    80000f06:	fee78fa3          	sb	a4,-1(a5)
    80000f0a:	fb65                	bnez	a4,80000efa <safestrcpy+0x16>
    ;
  *s = 0;
    80000f0c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret

0000000080000f16 <strlen>:

int
strlen(const char *s)
{
    80000f16:	1141                	addi	sp,sp,-16
    80000f18:	e422                	sd	s0,8(sp)
    80000f1a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f1c:	00054783          	lbu	a5,0(a0)
    80000f20:	cf91                	beqz	a5,80000f3c <strlen+0x26>
    80000f22:	0505                	addi	a0,a0,1
    80000f24:	87aa                	mv	a5,a0
    80000f26:	4685                	li	a3,1
    80000f28:	9e89                	subw	a3,a3,a0
    80000f2a:	00f6853b          	addw	a0,a3,a5
    80000f2e:	0785                	addi	a5,a5,1
    80000f30:	fff7c703          	lbu	a4,-1(a5)
    80000f34:	fb7d                	bnez	a4,80000f2a <strlen+0x14>
    ;
  return n;
}
    80000f36:	6422                	ld	s0,8(sp)
    80000f38:	0141                	addi	sp,sp,16
    80000f3a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f3c:	4501                	li	a0,0
    80000f3e:	bfe5                	j	80000f36 <strlen+0x20>

0000000080000f40 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f40:	1141                	addi	sp,sp,-16
    80000f42:	e406                	sd	ra,8(sp)
    80000f44:	e022                	sd	s0,0(sp)
    80000f46:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f48:	00001097          	auipc	ra,0x1
    80000f4c:	c9e080e7          	jalr	-866(ra) # 80001be6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f50:	00008717          	auipc	a4,0x8
    80000f54:	b6870713          	addi	a4,a4,-1176 # 80008ab8 <started>
  if(cpuid() == 0){
    80000f58:	c139                	beqz	a0,80000f9e <main+0x5e>
    while(started == 0)
    80000f5a:	431c                	lw	a5,0(a4)
    80000f5c:	2781                	sext.w	a5,a5
    80000f5e:	dff5                	beqz	a5,80000f5a <main+0x1a>
      ;
    __sync_synchronize();
    80000f60:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f64:	00001097          	auipc	ra,0x1
    80000f68:	c82080e7          	jalr	-894(ra) # 80001be6 <cpuid>
    80000f6c:	85aa                	mv	a1,a0
    80000f6e:	00007517          	auipc	a0,0x7
    80000f72:	18a50513          	addi	a0,a0,394 # 800080f8 <digits+0xa8>
    80000f76:	fffff097          	auipc	ra,0xfffff
    80000f7a:	626080e7          	jalr	1574(ra) # 8000059c <printf>
    kvminithart();    // turn on paging
    80000f7e:	00000097          	auipc	ra,0x0
    80000f82:	0d8080e7          	jalr	216(ra) # 80001056 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f86:	00002097          	auipc	ra,0x2
    80000f8a:	b12080e7          	jalr	-1262(ra) # 80002a98 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f8e:	00005097          	auipc	ra,0x5
    80000f92:	302080e7          	jalr	770(ra) # 80006290 <plicinithart>
  }

  scheduler();        
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	308080e7          	jalr	776(ra) # 8000229e <scheduler>
    consoleinit();
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	4b2080e7          	jalr	1202(ra) # 80000450 <consoleinit>
    printfinit();
    80000fa6:	fffff097          	auipc	ra,0xfffff
    80000faa:	7d6080e7          	jalr	2006(ra) # 8000077c <printfinit>
    printf("\n");
    80000fae:	00007517          	auipc	a0,0x7
    80000fb2:	0da50513          	addi	a0,a0,218 # 80008088 <digits+0x38>
    80000fb6:	fffff097          	auipc	ra,0xfffff
    80000fba:	5e6080e7          	jalr	1510(ra) # 8000059c <printf>
    printf("xv6 kernel is booting\n");
    80000fbe:	00007517          	auipc	a0,0x7
    80000fc2:	12250513          	addi	a0,a0,290 # 800080e0 <digits+0x90>
    80000fc6:	fffff097          	auipc	ra,0xfffff
    80000fca:	5d6080e7          	jalr	1494(ra) # 8000059c <printf>
    printf("\n");
    80000fce:	00007517          	auipc	a0,0x7
    80000fd2:	0ba50513          	addi	a0,a0,186 # 80008088 <digits+0x38>
    80000fd6:	fffff097          	auipc	ra,0xfffff
    80000fda:	5c6080e7          	jalr	1478(ra) # 8000059c <printf>
    kinit();         // physical page allocator
    80000fde:	00000097          	auipc	ra,0x0
    80000fe2:	b38080e7          	jalr	-1224(ra) # 80000b16 <kinit>
    kvminit();       // create kernel page table
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	326080e7          	jalr	806(ra) # 8000130c <kvminit>
    kvminithart();   // turn on paging
    80000fee:	00000097          	auipc	ra,0x0
    80000ff2:	068080e7          	jalr	104(ra) # 80001056 <kvminithart>
    procinit();      // process table
    80000ff6:	00001097          	auipc	ra,0x1
    80000ffa:	b0e080e7          	jalr	-1266(ra) # 80001b04 <procinit>
    trapinit();      // trap vectors
    80000ffe:	00002097          	auipc	ra,0x2
    80001002:	a72080e7          	jalr	-1422(ra) # 80002a70 <trapinit>
    trapinithart();  // install kernel trap vector
    80001006:	00002097          	auipc	ra,0x2
    8000100a:	a92080e7          	jalr	-1390(ra) # 80002a98 <trapinithart>
    plicinit();      // set up interrupt controller
    8000100e:	00005097          	auipc	ra,0x5
    80001012:	26c080e7          	jalr	620(ra) # 8000627a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001016:	00005097          	auipc	ra,0x5
    8000101a:	27a080e7          	jalr	634(ra) # 80006290 <plicinithart>
    binit();         // buffer cache
    8000101e:	00002097          	auipc	ra,0x2
    80001022:	412080e7          	jalr	1042(ra) # 80003430 <binit>
    iinit();         // inode table
    80001026:	00003097          	auipc	ra,0x3
    8000102a:	ab2080e7          	jalr	-1358(ra) # 80003ad8 <iinit>
    fileinit();      // file table
    8000102e:	00004097          	auipc	ra,0x4
    80001032:	a58080e7          	jalr	-1448(ra) # 80004a86 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001036:	00005097          	auipc	ra,0x5
    8000103a:	362080e7          	jalr	866(ra) # 80006398 <virtio_disk_init>
    userinit();      // first user process
    8000103e:	00001097          	auipc	ra,0x1
    80001042:	eac080e7          	jalr	-340(ra) # 80001eea <userinit>
    __sync_synchronize();
    80001046:	0ff0000f          	fence
    started = 1;
    8000104a:	4785                	li	a5,1
    8000104c:	00008717          	auipc	a4,0x8
    80001050:	a6f72623          	sw	a5,-1428(a4) # 80008ab8 <started>
    80001054:	b789                	j	80000f96 <main+0x56>

0000000080001056 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001056:	1141                	addi	sp,sp,-16
    80001058:	e422                	sd	s0,8(sp)
    8000105a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000105c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001060:	00008797          	auipc	a5,0x8
    80001064:	a607b783          	ld	a5,-1440(a5) # 80008ac0 <kernel_pagetable>
    80001068:	83b1                	srli	a5,a5,0xc
    8000106a:	577d                	li	a4,-1
    8000106c:	177e                	slli	a4,a4,0x3f
    8000106e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001070:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001074:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001078:	6422                	ld	s0,8(sp)
    8000107a:	0141                	addi	sp,sp,16
    8000107c:	8082                	ret

000000008000107e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000107e:	7139                	addi	sp,sp,-64
    80001080:	fc06                	sd	ra,56(sp)
    80001082:	f822                	sd	s0,48(sp)
    80001084:	f426                	sd	s1,40(sp)
    80001086:	f04a                	sd	s2,32(sp)
    80001088:	ec4e                	sd	s3,24(sp)
    8000108a:	e852                	sd	s4,16(sp)
    8000108c:	e456                	sd	s5,8(sp)
    8000108e:	e05a                	sd	s6,0(sp)
    80001090:	0080                	addi	s0,sp,64
    80001092:	84aa                	mv	s1,a0
    80001094:	89ae                	mv	s3,a1
    80001096:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001098:	57fd                	li	a5,-1
    8000109a:	83e9                	srli	a5,a5,0x1a
    8000109c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000109e:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010a0:	04b7f263          	bgeu	a5,a1,800010e4 <walk+0x66>
    panic("walk");
    800010a4:	00007517          	auipc	a0,0x7
    800010a8:	06c50513          	addi	a0,a0,108 # 80008110 <digits+0xc0>
    800010ac:	fffff097          	auipc	ra,0xfffff
    800010b0:	494080e7          	jalr	1172(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010b4:	060a8663          	beqz	s5,80001120 <walk+0xa2>
    800010b8:	00000097          	auipc	ra,0x0
    800010bc:	aaa080e7          	jalr	-1366(ra) # 80000b62 <kalloc>
    800010c0:	84aa                	mv	s1,a0
    800010c2:	c529                	beqz	a0,8000110c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010c4:	6605                	lui	a2,0x1
    800010c6:	4581                	li	a1,0
    800010c8:	00000097          	auipc	ra,0x0
    800010cc:	cd2080e7          	jalr	-814(ra) # 80000d9a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010d0:	00c4d793          	srli	a5,s1,0xc
    800010d4:	07aa                	slli	a5,a5,0xa
    800010d6:	0017e793          	ori	a5,a5,1
    800010da:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010de:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd0a7>
    800010e0:	036a0063          	beq	s4,s6,80001100 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010e4:	0149d933          	srl	s2,s3,s4
    800010e8:	1ff97913          	andi	s2,s2,511
    800010ec:	090e                	slli	s2,s2,0x3
    800010ee:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010f0:	00093483          	ld	s1,0(s2)
    800010f4:	0014f793          	andi	a5,s1,1
    800010f8:	dfd5                	beqz	a5,800010b4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010fa:	80a9                	srli	s1,s1,0xa
    800010fc:	04b2                	slli	s1,s1,0xc
    800010fe:	b7c5                	j	800010de <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001100:	00c9d513          	srli	a0,s3,0xc
    80001104:	1ff57513          	andi	a0,a0,511
    80001108:	050e                	slli	a0,a0,0x3
    8000110a:	9526                	add	a0,a0,s1
}
    8000110c:	70e2                	ld	ra,56(sp)
    8000110e:	7442                	ld	s0,48(sp)
    80001110:	74a2                	ld	s1,40(sp)
    80001112:	7902                	ld	s2,32(sp)
    80001114:	69e2                	ld	s3,24(sp)
    80001116:	6a42                	ld	s4,16(sp)
    80001118:	6aa2                	ld	s5,8(sp)
    8000111a:	6b02                	ld	s6,0(sp)
    8000111c:	6121                	addi	sp,sp,64
    8000111e:	8082                	ret
        return 0;
    80001120:	4501                	li	a0,0
    80001122:	b7ed                	j	8000110c <walk+0x8e>

0000000080001124 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001124:	57fd                	li	a5,-1
    80001126:	83e9                	srli	a5,a5,0x1a
    80001128:	00b7f463          	bgeu	a5,a1,80001130 <walkaddr+0xc>
    return 0;
    8000112c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000112e:	8082                	ret
{
    80001130:	1141                	addi	sp,sp,-16
    80001132:	e406                	sd	ra,8(sp)
    80001134:	e022                	sd	s0,0(sp)
    80001136:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001138:	4601                	li	a2,0
    8000113a:	00000097          	auipc	ra,0x0
    8000113e:	f44080e7          	jalr	-188(ra) # 8000107e <walk>
  if(pte == 0)
    80001142:	c105                	beqz	a0,80001162 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001144:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001146:	0117f693          	andi	a3,a5,17
    8000114a:	4745                	li	a4,17
    return 0;
    8000114c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000114e:	00e68663          	beq	a3,a4,8000115a <walkaddr+0x36>
}
    80001152:	60a2                	ld	ra,8(sp)
    80001154:	6402                	ld	s0,0(sp)
    80001156:	0141                	addi	sp,sp,16
    80001158:	8082                	ret
  pa = PTE2PA(*pte);
    8000115a:	83a9                	srli	a5,a5,0xa
    8000115c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001160:	bfcd                	j	80001152 <walkaddr+0x2e>
    return 0;
    80001162:	4501                	li	a0,0
    80001164:	b7fd                	j	80001152 <walkaddr+0x2e>

0000000080001166 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001166:	715d                	addi	sp,sp,-80
    80001168:	e486                	sd	ra,72(sp)
    8000116a:	e0a2                	sd	s0,64(sp)
    8000116c:	fc26                	sd	s1,56(sp)
    8000116e:	f84a                	sd	s2,48(sp)
    80001170:	f44e                	sd	s3,40(sp)
    80001172:	f052                	sd	s4,32(sp)
    80001174:	ec56                	sd	s5,24(sp)
    80001176:	e85a                	sd	s6,16(sp)
    80001178:	e45e                	sd	s7,8(sp)
    8000117a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000117c:	c639                	beqz	a2,800011ca <mappages+0x64>
    8000117e:	8aaa                	mv	s5,a0
    80001180:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001182:	777d                	lui	a4,0xfffff
    80001184:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001188:	fff58993          	addi	s3,a1,-1
    8000118c:	99b2                	add	s3,s3,a2
    8000118e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001192:	893e                	mv	s2,a5
    80001194:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001198:	6b85                	lui	s7,0x1
    8000119a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	4605                	li	a2,1
    800011a0:	85ca                	mv	a1,s2
    800011a2:	8556                	mv	a0,s5
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	eda080e7          	jalr	-294(ra) # 8000107e <walk>
    800011ac:	cd1d                	beqz	a0,800011ea <mappages+0x84>
    if(*pte & PTE_V)
    800011ae:	611c                	ld	a5,0(a0)
    800011b0:	8b85                	andi	a5,a5,1
    800011b2:	e785                	bnez	a5,800011da <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011b4:	80b1                	srli	s1,s1,0xc
    800011b6:	04aa                	slli	s1,s1,0xa
    800011b8:	0164e4b3          	or	s1,s1,s6
    800011bc:	0014e493          	ori	s1,s1,1
    800011c0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011c2:	05390063          	beq	s2,s3,80001202 <mappages+0x9c>
    a += PGSIZE;
    800011c6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c8:	bfc9                	j	8000119a <mappages+0x34>
    panic("mappages: size");
    800011ca:	00007517          	auipc	a0,0x7
    800011ce:	f4e50513          	addi	a0,a0,-178 # 80008118 <digits+0xc8>
    800011d2:	fffff097          	auipc	ra,0xfffff
    800011d6:	36e080e7          	jalr	878(ra) # 80000540 <panic>
      panic("mappages: remap");
    800011da:	00007517          	auipc	a0,0x7
    800011de:	f4e50513          	addi	a0,a0,-178 # 80008128 <digits+0xd8>
    800011e2:	fffff097          	auipc	ra,0xfffff
    800011e6:	35e080e7          	jalr	862(ra) # 80000540 <panic>
      return -1;
    800011ea:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011ec:	60a6                	ld	ra,72(sp)
    800011ee:	6406                	ld	s0,64(sp)
    800011f0:	74e2                	ld	s1,56(sp)
    800011f2:	7942                	ld	s2,48(sp)
    800011f4:	79a2                	ld	s3,40(sp)
    800011f6:	7a02                	ld	s4,32(sp)
    800011f8:	6ae2                	ld	s5,24(sp)
    800011fa:	6b42                	ld	s6,16(sp)
    800011fc:	6ba2                	ld	s7,8(sp)
    800011fe:	6161                	addi	sp,sp,80
    80001200:	8082                	ret
  return 0;
    80001202:	4501                	li	a0,0
    80001204:	b7e5                	j	800011ec <mappages+0x86>

0000000080001206 <kvmmap>:
{
    80001206:	1141                	addi	sp,sp,-16
    80001208:	e406                	sd	ra,8(sp)
    8000120a:	e022                	sd	s0,0(sp)
    8000120c:	0800                	addi	s0,sp,16
    8000120e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001210:	86b2                	mv	a3,a2
    80001212:	863e                	mv	a2,a5
    80001214:	00000097          	auipc	ra,0x0
    80001218:	f52080e7          	jalr	-174(ra) # 80001166 <mappages>
    8000121c:	e509                	bnez	a0,80001226 <kvmmap+0x20>
}
    8000121e:	60a2                	ld	ra,8(sp)
    80001220:	6402                	ld	s0,0(sp)
    80001222:	0141                	addi	sp,sp,16
    80001224:	8082                	ret
    panic("kvmmap");
    80001226:	00007517          	auipc	a0,0x7
    8000122a:	f1250513          	addi	a0,a0,-238 # 80008138 <digits+0xe8>
    8000122e:	fffff097          	auipc	ra,0xfffff
    80001232:	312080e7          	jalr	786(ra) # 80000540 <panic>

0000000080001236 <kvmmake>:
{
    80001236:	1101                	addi	sp,sp,-32
    80001238:	ec06                	sd	ra,24(sp)
    8000123a:	e822                	sd	s0,16(sp)
    8000123c:	e426                	sd	s1,8(sp)
    8000123e:	e04a                	sd	s2,0(sp)
    80001240:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	920080e7          	jalr	-1760(ra) # 80000b62 <kalloc>
    8000124a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000124c:	6605                	lui	a2,0x1
    8000124e:	4581                	li	a1,0
    80001250:	00000097          	auipc	ra,0x0
    80001254:	b4a080e7          	jalr	-1206(ra) # 80000d9a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001258:	4719                	li	a4,6
    8000125a:	6685                	lui	a3,0x1
    8000125c:	10000637          	lui	a2,0x10000
    80001260:	100005b7          	lui	a1,0x10000
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	fa0080e7          	jalr	-96(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	6685                	lui	a3,0x1
    80001272:	10001637          	lui	a2,0x10001
    80001276:	100015b7          	lui	a1,0x10001
    8000127a:	8526                	mv	a0,s1
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f8a080e7          	jalr	-118(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001284:	4719                	li	a4,6
    80001286:	004006b7          	lui	a3,0x400
    8000128a:	0c000637          	lui	a2,0xc000
    8000128e:	0c0005b7          	lui	a1,0xc000
    80001292:	8526                	mv	a0,s1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f72080e7          	jalr	-142(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000129c:	00007917          	auipc	s2,0x7
    800012a0:	d6490913          	addi	s2,s2,-668 # 80008000 <etext>
    800012a4:	4729                	li	a4,10
    800012a6:	80007697          	auipc	a3,0x80007
    800012aa:	d5a68693          	addi	a3,a3,-678 # 8000 <_entry-0x7fff8000>
    800012ae:	4605                	li	a2,1
    800012b0:	067e                	slli	a2,a2,0x1f
    800012b2:	85b2                	mv	a1,a2
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f50080e7          	jalr	-176(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012be:	4719                	li	a4,6
    800012c0:	46c5                	li	a3,17
    800012c2:	06ee                	slli	a3,a3,0x1b
    800012c4:	412686b3          	sub	a3,a3,s2
    800012c8:	864a                	mv	a2,s2
    800012ca:	85ca                	mv	a1,s2
    800012cc:	8526                	mv	a0,s1
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	f38080e7          	jalr	-200(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012d6:	4729                	li	a4,10
    800012d8:	6685                	lui	a3,0x1
    800012da:	00006617          	auipc	a2,0x6
    800012de:	d2660613          	addi	a2,a2,-730 # 80007000 <_trampoline>
    800012e2:	040005b7          	lui	a1,0x4000
    800012e6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012e8:	05b2                	slli	a1,a1,0xc
    800012ea:	8526                	mv	a0,s1
    800012ec:	00000097          	auipc	ra,0x0
    800012f0:	f1a080e7          	jalr	-230(ra) # 80001206 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012f4:	8526                	mv	a0,s1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	778080e7          	jalr	1912(ra) # 80001a6e <proc_mapstacks>
}
    800012fe:	8526                	mv	a0,s1
    80001300:	60e2                	ld	ra,24(sp)
    80001302:	6442                	ld	s0,16(sp)
    80001304:	64a2                	ld	s1,8(sp)
    80001306:	6902                	ld	s2,0(sp)
    80001308:	6105                	addi	sp,sp,32
    8000130a:	8082                	ret

000000008000130c <kvminit>:
{
    8000130c:	1141                	addi	sp,sp,-16
    8000130e:	e406                	sd	ra,8(sp)
    80001310:	e022                	sd	s0,0(sp)
    80001312:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001314:	00000097          	auipc	ra,0x0
    80001318:	f22080e7          	jalr	-222(ra) # 80001236 <kvmmake>
    8000131c:	00007797          	auipc	a5,0x7
    80001320:	7aa7b223          	sd	a0,1956(a5) # 80008ac0 <kernel_pagetable>
}
    80001324:	60a2                	ld	ra,8(sp)
    80001326:	6402                	ld	s0,0(sp)
    80001328:	0141                	addi	sp,sp,16
    8000132a:	8082                	ret

000000008000132c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000132c:	715d                	addi	sp,sp,-80
    8000132e:	e486                	sd	ra,72(sp)
    80001330:	e0a2                	sd	s0,64(sp)
    80001332:	fc26                	sd	s1,56(sp)
    80001334:	f84a                	sd	s2,48(sp)
    80001336:	f44e                	sd	s3,40(sp)
    80001338:	f052                	sd	s4,32(sp)
    8000133a:	ec56                	sd	s5,24(sp)
    8000133c:	e85a                	sd	s6,16(sp)
    8000133e:	e45e                	sd	s7,8(sp)
    80001340:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001342:	03459793          	slli	a5,a1,0x34
    80001346:	e795                	bnez	a5,80001372 <uvmunmap+0x46>
    80001348:	8a2a                	mv	s4,a0
    8000134a:	892e                	mv	s2,a1
    8000134c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134e:	0632                	slli	a2,a2,0xc
    80001350:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001354:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001356:	6b05                	lui	s6,0x1
    80001358:	0735e263          	bltu	a1,s3,800013bc <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000135c:	60a6                	ld	ra,72(sp)
    8000135e:	6406                	ld	s0,64(sp)
    80001360:	74e2                	ld	s1,56(sp)
    80001362:	7942                	ld	s2,48(sp)
    80001364:	79a2                	ld	s3,40(sp)
    80001366:	7a02                	ld	s4,32(sp)
    80001368:	6ae2                	ld	s5,24(sp)
    8000136a:	6b42                	ld	s6,16(sp)
    8000136c:	6ba2                	ld	s7,8(sp)
    8000136e:	6161                	addi	sp,sp,80
    80001370:	8082                	ret
    panic("uvmunmap: not aligned");
    80001372:	00007517          	auipc	a0,0x7
    80001376:	dce50513          	addi	a0,a0,-562 # 80008140 <digits+0xf0>
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001382:	00007517          	auipc	a0,0x7
    80001386:	dd650513          	addi	a0,a0,-554 # 80008158 <digits+0x108>
    8000138a:	fffff097          	auipc	ra,0xfffff
    8000138e:	1b6080e7          	jalr	438(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001392:	00007517          	auipc	a0,0x7
    80001396:	dd650513          	addi	a0,a0,-554 # 80008168 <digits+0x118>
    8000139a:	fffff097          	auipc	ra,0xfffff
    8000139e:	1a6080e7          	jalr	422(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800013a2:	00007517          	auipc	a0,0x7
    800013a6:	dde50513          	addi	a0,a0,-546 # 80008180 <digits+0x130>
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	196080e7          	jalr	406(ra) # 80000540 <panic>
    *pte = 0;
    800013b2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b6:	995a                	add	s2,s2,s6
    800013b8:	fb3972e3          	bgeu	s2,s3,8000135c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013bc:	4601                	li	a2,0
    800013be:	85ca                	mv	a1,s2
    800013c0:	8552                	mv	a0,s4
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	cbc080e7          	jalr	-836(ra) # 8000107e <walk>
    800013ca:	84aa                	mv	s1,a0
    800013cc:	d95d                	beqz	a0,80001382 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ce:	6108                	ld	a0,0(a0)
    800013d0:	00157793          	andi	a5,a0,1
    800013d4:	dfdd                	beqz	a5,80001392 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d6:	3ff57793          	andi	a5,a0,1023
    800013da:	fd7784e3          	beq	a5,s7,800013a2 <uvmunmap+0x76>
    if(do_free){
    800013de:	fc0a8ae3          	beqz	s5,800013b2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013e2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013e4:	0532                	slli	a0,a0,0xc
    800013e6:	fffff097          	auipc	ra,0xfffff
    800013ea:	614080e7          	jalr	1556(ra) # 800009fa <kfree>
    800013ee:	b7d1                	j	800013b2 <uvmunmap+0x86>

00000000800013f0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013f0:	1101                	addi	sp,sp,-32
    800013f2:	ec06                	sd	ra,24(sp)
    800013f4:	e822                	sd	s0,16(sp)
    800013f6:	e426                	sd	s1,8(sp)
    800013f8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013fa:	fffff097          	auipc	ra,0xfffff
    800013fe:	768080e7          	jalr	1896(ra) # 80000b62 <kalloc>
    80001402:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001404:	c519                	beqz	a0,80001412 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001406:	6605                	lui	a2,0x1
    80001408:	4581                	li	a1,0
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	990080e7          	jalr	-1648(ra) # 80000d9a <memset>
  return pagetable;
}
    80001412:	8526                	mv	a0,s1
    80001414:	60e2                	ld	ra,24(sp)
    80001416:	6442                	ld	s0,16(sp)
    80001418:	64a2                	ld	s1,8(sp)
    8000141a:	6105                	addi	sp,sp,32
    8000141c:	8082                	ret

000000008000141e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000141e:	7179                	addi	sp,sp,-48
    80001420:	f406                	sd	ra,40(sp)
    80001422:	f022                	sd	s0,32(sp)
    80001424:	ec26                	sd	s1,24(sp)
    80001426:	e84a                	sd	s2,16(sp)
    80001428:	e44e                	sd	s3,8(sp)
    8000142a:	e052                	sd	s4,0(sp)
    8000142c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000142e:	6785                	lui	a5,0x1
    80001430:	04f67863          	bgeu	a2,a5,80001480 <uvmfirst+0x62>
    80001434:	8a2a                	mv	s4,a0
    80001436:	89ae                	mv	s3,a1
    80001438:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	728080e7          	jalr	1832(ra) # 80000b62 <kalloc>
    80001442:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001444:	6605                	lui	a2,0x1
    80001446:	4581                	li	a1,0
    80001448:	00000097          	auipc	ra,0x0
    8000144c:	952080e7          	jalr	-1710(ra) # 80000d9a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001450:	4779                	li	a4,30
    80001452:	86ca                	mv	a3,s2
    80001454:	6605                	lui	a2,0x1
    80001456:	4581                	li	a1,0
    80001458:	8552                	mv	a0,s4
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	d0c080e7          	jalr	-756(ra) # 80001166 <mappages>
  memmove(mem, src, sz);
    80001462:	8626                	mv	a2,s1
    80001464:	85ce                	mv	a1,s3
    80001466:	854a                	mv	a0,s2
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	98e080e7          	jalr	-1650(ra) # 80000df6 <memmove>
}
    80001470:	70a2                	ld	ra,40(sp)
    80001472:	7402                	ld	s0,32(sp)
    80001474:	64e2                	ld	s1,24(sp)
    80001476:	6942                	ld	s2,16(sp)
    80001478:	69a2                	ld	s3,8(sp)
    8000147a:	6a02                	ld	s4,0(sp)
    8000147c:	6145                	addi	sp,sp,48
    8000147e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001480:	00007517          	auipc	a0,0x7
    80001484:	d1850513          	addi	a0,a0,-744 # 80008198 <digits+0x148>
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	0b8080e7          	jalr	184(ra) # 80000540 <panic>

0000000080001490 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001490:	1101                	addi	sp,sp,-32
    80001492:	ec06                	sd	ra,24(sp)
    80001494:	e822                	sd	s0,16(sp)
    80001496:	e426                	sd	s1,8(sp)
    80001498:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000149a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000149c:	00b67d63          	bgeu	a2,a1,800014b6 <uvmdealloc+0x26>
    800014a0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014a2:	6785                	lui	a5,0x1
    800014a4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a6:	00f60733          	add	a4,a2,a5
    800014aa:	76fd                	lui	a3,0xfffff
    800014ac:	8f75                	and	a4,a4,a3
    800014ae:	97ae                	add	a5,a5,a1
    800014b0:	8ff5                	and	a5,a5,a3
    800014b2:	00f76863          	bltu	a4,a5,800014c2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b6:	8526                	mv	a0,s1
    800014b8:	60e2                	ld	ra,24(sp)
    800014ba:	6442                	ld	s0,16(sp)
    800014bc:	64a2                	ld	s1,8(sp)
    800014be:	6105                	addi	sp,sp,32
    800014c0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014c2:	8f99                	sub	a5,a5,a4
    800014c4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c6:	4685                	li	a3,1
    800014c8:	0007861b          	sext.w	a2,a5
    800014cc:	85ba                	mv	a1,a4
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	e5e080e7          	jalr	-418(ra) # 8000132c <uvmunmap>
    800014d6:	b7c5                	j	800014b6 <uvmdealloc+0x26>

00000000800014d8 <uvmalloc>:
  if(newsz < oldsz)
    800014d8:	0ab66563          	bltu	a2,a1,80001582 <uvmalloc+0xaa>
{
    800014dc:	7139                	addi	sp,sp,-64
    800014de:	fc06                	sd	ra,56(sp)
    800014e0:	f822                	sd	s0,48(sp)
    800014e2:	f426                	sd	s1,40(sp)
    800014e4:	f04a                	sd	s2,32(sp)
    800014e6:	ec4e                	sd	s3,24(sp)
    800014e8:	e852                	sd	s4,16(sp)
    800014ea:	e456                	sd	s5,8(sp)
    800014ec:	e05a                	sd	s6,0(sp)
    800014ee:	0080                	addi	s0,sp,64
    800014f0:	8aaa                	mv	s5,a0
    800014f2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014f4:	6785                	lui	a5,0x1
    800014f6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014f8:	95be                	add	a1,a1,a5
    800014fa:	77fd                	lui	a5,0xfffff
    800014fc:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001500:	08c9f363          	bgeu	s3,a2,80001586 <uvmalloc+0xae>
    80001504:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001506:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	658080e7          	jalr	1624(ra) # 80000b62 <kalloc>
    80001512:	84aa                	mv	s1,a0
    if(mem == 0){
    80001514:	c51d                	beqz	a0,80001542 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001516:	6605                	lui	a2,0x1
    80001518:	4581                	li	a1,0
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	880080e7          	jalr	-1920(ra) # 80000d9a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001522:	875a                	mv	a4,s6
    80001524:	86a6                	mv	a3,s1
    80001526:	6605                	lui	a2,0x1
    80001528:	85ca                	mv	a1,s2
    8000152a:	8556                	mv	a0,s5
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	c3a080e7          	jalr	-966(ra) # 80001166 <mappages>
    80001534:	e90d                	bnez	a0,80001566 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001536:	6785                	lui	a5,0x1
    80001538:	993e                	add	s2,s2,a5
    8000153a:	fd4968e3          	bltu	s2,s4,8000150a <uvmalloc+0x32>
  return newsz;
    8000153e:	8552                	mv	a0,s4
    80001540:	a809                	j	80001552 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001542:	864e                	mv	a2,s3
    80001544:	85ca                	mv	a1,s2
    80001546:	8556                	mv	a0,s5
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	f48080e7          	jalr	-184(ra) # 80001490 <uvmdealloc>
      return 0;
    80001550:	4501                	li	a0,0
}
    80001552:	70e2                	ld	ra,56(sp)
    80001554:	7442                	ld	s0,48(sp)
    80001556:	74a2                	ld	s1,40(sp)
    80001558:	7902                	ld	s2,32(sp)
    8000155a:	69e2                	ld	s3,24(sp)
    8000155c:	6a42                	ld	s4,16(sp)
    8000155e:	6aa2                	ld	s5,8(sp)
    80001560:	6b02                	ld	s6,0(sp)
    80001562:	6121                	addi	sp,sp,64
    80001564:	8082                	ret
      kfree(mem);
    80001566:	8526                	mv	a0,s1
    80001568:	fffff097          	auipc	ra,0xfffff
    8000156c:	492080e7          	jalr	1170(ra) # 800009fa <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001570:	864e                	mv	a2,s3
    80001572:	85ca                	mv	a1,s2
    80001574:	8556                	mv	a0,s5
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	f1a080e7          	jalr	-230(ra) # 80001490 <uvmdealloc>
      return 0;
    8000157e:	4501                	li	a0,0
    80001580:	bfc9                	j	80001552 <uvmalloc+0x7a>
    return oldsz;
    80001582:	852e                	mv	a0,a1
}
    80001584:	8082                	ret
  return newsz;
    80001586:	8532                	mv	a0,a2
    80001588:	b7e9                	j	80001552 <uvmalloc+0x7a>

000000008000158a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000158a:	7179                	addi	sp,sp,-48
    8000158c:	f406                	sd	ra,40(sp)
    8000158e:	f022                	sd	s0,32(sp)
    80001590:	ec26                	sd	s1,24(sp)
    80001592:	e84a                	sd	s2,16(sp)
    80001594:	e44e                	sd	s3,8(sp)
    80001596:	e052                	sd	s4,0(sp)
    80001598:	1800                	addi	s0,sp,48
    8000159a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000159c:	84aa                	mv	s1,a0
    8000159e:	6905                	lui	s2,0x1
    800015a0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a2:	4985                	li	s3,1
    800015a4:	a829                	j	800015be <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015a6:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015a8:	00c79513          	slli	a0,a5,0xc
    800015ac:	00000097          	auipc	ra,0x0
    800015b0:	fde080e7          	jalr	-34(ra) # 8000158a <freewalk>
      pagetable[i] = 0;
    800015b4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015b8:	04a1                	addi	s1,s1,8
    800015ba:	03248163          	beq	s1,s2,800015dc <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015be:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015c0:	00f7f713          	andi	a4,a5,15
    800015c4:	ff3701e3          	beq	a4,s3,800015a6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015c8:	8b85                	andi	a5,a5,1
    800015ca:	d7fd                	beqz	a5,800015b8 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bec50513          	addi	a0,a0,-1044 # 800081b8 <digits+0x168>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f6c080e7          	jalr	-148(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    800015dc:	8552                	mv	a0,s4
    800015de:	fffff097          	auipc	ra,0xfffff
    800015e2:	41c080e7          	jalr	1052(ra) # 800009fa <kfree>
}
    800015e6:	70a2                	ld	ra,40(sp)
    800015e8:	7402                	ld	s0,32(sp)
    800015ea:	64e2                	ld	s1,24(sp)
    800015ec:	6942                	ld	s2,16(sp)
    800015ee:	69a2                	ld	s3,8(sp)
    800015f0:	6a02                	ld	s4,0(sp)
    800015f2:	6145                	addi	sp,sp,48
    800015f4:	8082                	ret

00000000800015f6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015f6:	1101                	addi	sp,sp,-32
    800015f8:	ec06                	sd	ra,24(sp)
    800015fa:	e822                	sd	s0,16(sp)
    800015fc:	e426                	sd	s1,8(sp)
    800015fe:	1000                	addi	s0,sp,32
    80001600:	84aa                	mv	s1,a0
  if(sz > 0)
    80001602:	e999                	bnez	a1,80001618 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001604:	8526                	mv	a0,s1
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	f84080e7          	jalr	-124(ra) # 8000158a <freewalk>
}
    8000160e:	60e2                	ld	ra,24(sp)
    80001610:	6442                	ld	s0,16(sp)
    80001612:	64a2                	ld	s1,8(sp)
    80001614:	6105                	addi	sp,sp,32
    80001616:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001618:	6785                	lui	a5,0x1
    8000161a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000161c:	95be                	add	a1,a1,a5
    8000161e:	4685                	li	a3,1
    80001620:	00c5d613          	srli	a2,a1,0xc
    80001624:	4581                	li	a1,0
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	d06080e7          	jalr	-762(ra) # 8000132c <uvmunmap>
    8000162e:	bfd9                	j	80001604 <uvmfree+0xe>

0000000080001630 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001630:	c679                	beqz	a2,800016fe <uvmcopy+0xce>
{
    80001632:	715d                	addi	sp,sp,-80
    80001634:	e486                	sd	ra,72(sp)
    80001636:	e0a2                	sd	s0,64(sp)
    80001638:	fc26                	sd	s1,56(sp)
    8000163a:	f84a                	sd	s2,48(sp)
    8000163c:	f44e                	sd	s3,40(sp)
    8000163e:	f052                	sd	s4,32(sp)
    80001640:	ec56                	sd	s5,24(sp)
    80001642:	e85a                	sd	s6,16(sp)
    80001644:	e45e                	sd	s7,8(sp)
    80001646:	0880                	addi	s0,sp,80
    80001648:	8b2a                	mv	s6,a0
    8000164a:	8aae                	mv	s5,a1
    8000164c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001650:	4601                	li	a2,0
    80001652:	85ce                	mv	a1,s3
    80001654:	855a                	mv	a0,s6
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	a28080e7          	jalr	-1496(ra) # 8000107e <walk>
    8000165e:	c531                	beqz	a0,800016aa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001660:	6118                	ld	a4,0(a0)
    80001662:	00177793          	andi	a5,a4,1
    80001666:	cbb1                	beqz	a5,800016ba <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001668:	00a75593          	srli	a1,a4,0xa
    8000166c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001670:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	4ee080e7          	jalr	1262(ra) # 80000b62 <kalloc>
    8000167c:	892a                	mv	s2,a0
    8000167e:	c939                	beqz	a0,800016d4 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001680:	6605                	lui	a2,0x1
    80001682:	85de                	mv	a1,s7
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	772080e7          	jalr	1906(ra) # 80000df6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000168c:	8726                	mv	a4,s1
    8000168e:	86ca                	mv	a3,s2
    80001690:	6605                	lui	a2,0x1
    80001692:	85ce                	mv	a1,s3
    80001694:	8556                	mv	a0,s5
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	ad0080e7          	jalr	-1328(ra) # 80001166 <mappages>
    8000169e:	e515                	bnez	a0,800016ca <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016a0:	6785                	lui	a5,0x1
    800016a2:	99be                	add	s3,s3,a5
    800016a4:	fb49e6e3          	bltu	s3,s4,80001650 <uvmcopy+0x20>
    800016a8:	a081                	j	800016e8 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016aa:	00007517          	auipc	a0,0x7
    800016ae:	b1e50513          	addi	a0,a0,-1250 # 800081c8 <digits+0x178>
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	e8e080e7          	jalr	-370(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800016ba:	00007517          	auipc	a0,0x7
    800016be:	b2e50513          	addi	a0,a0,-1234 # 800081e8 <digits+0x198>
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	e7e080e7          	jalr	-386(ra) # 80000540 <panic>
      kfree(mem);
    800016ca:	854a                	mv	a0,s2
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	32e080e7          	jalr	814(ra) # 800009fa <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016d4:	4685                	li	a3,1
    800016d6:	00c9d613          	srli	a2,s3,0xc
    800016da:	4581                	li	a1,0
    800016dc:	8556                	mv	a0,s5
    800016de:	00000097          	auipc	ra,0x0
    800016e2:	c4e080e7          	jalr	-946(ra) # 8000132c <uvmunmap>
  return -1;
    800016e6:	557d                	li	a0,-1
}
    800016e8:	60a6                	ld	ra,72(sp)
    800016ea:	6406                	ld	s0,64(sp)
    800016ec:	74e2                	ld	s1,56(sp)
    800016ee:	7942                	ld	s2,48(sp)
    800016f0:	79a2                	ld	s3,40(sp)
    800016f2:	7a02                	ld	s4,32(sp)
    800016f4:	6ae2                	ld	s5,24(sp)
    800016f6:	6b42                	ld	s6,16(sp)
    800016f8:	6ba2                	ld	s7,8(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret
  return 0;
    800016fe:	4501                	li	a0,0
}
    80001700:	8082                	ret

0000000080001702 <uvmcow>:
int uvmcow(pagetable_t old, pagetable_t new, uint64 sz) {
    pte_t *pte;
    uint64 i;
    uint flags;

    for(i = 0; i < sz; i += PGSIZE){
    80001702:	ce51                	beqz	a2,8000179e <uvmcow+0x9c>
int uvmcow(pagetable_t old, pagetable_t new, uint64 sz) {
    80001704:	7179                	addi	sp,sp,-48
    80001706:	f406                	sd	ra,40(sp)
    80001708:	f022                	sd	s0,32(sp)
    8000170a:	ec26                	sd	s1,24(sp)
    8000170c:	e84a                	sd	s2,16(sp)
    8000170e:	e44e                	sd	s3,8(sp)
    80001710:	e052                	sd	s4,0(sp)
    80001712:	1800                	addi	s0,sp,48
    80001714:	8a2a                	mv	s4,a0
    80001716:	89ae                	mv	s3,a1
    80001718:	8932                	mv	s2,a2
    for(i = 0; i < sz; i += PGSIZE){
    8000171a:	4481                	li	s1,0
        if((pte = walk(old, i, 0)) == 0)
    8000171c:	4601                	li	a2,0
    8000171e:	85a6                	mv	a1,s1
    80001720:	8552                	mv	a0,s4
    80001722:	00000097          	auipc	ra,0x0
    80001726:	95c080e7          	jalr	-1700(ra) # 8000107e <walk>
    8000172a:	c905                	beqz	a0,8000175a <uvmcow+0x58>
            panic("uvmcow: pte should exist");
        if((*pte & PTE_V) == 0)
    8000172c:	6114                	ld	a3,0(a0)
    8000172e:	0016f793          	andi	a5,a3,1
    80001732:	cf85                	beqz	a5,8000176a <uvmcow+0x68>
            panic("uvmcow: page not present");

        // Adjust flags to be read-only
        flags = PTE_FLAGS(*pte) & ~PTE_W;
    80001734:	3fb6f713          	andi	a4,a3,1019
        flags |= PTE_COW; // Ensure read permission is set

        // Map the page as read-only in the child's page table
        if(mappages(new, i, PGSIZE, PTE2PA(*pte), flags) != 0){
    80001738:	82a9                	srli	a3,a3,0xa
    8000173a:	02076713          	ori	a4,a4,32
    8000173e:	06b2                	slli	a3,a3,0xc
    80001740:	6605                	lui	a2,0x1
    80001742:	85a6                	mv	a1,s1
    80001744:	854e                	mv	a0,s3
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	a20080e7          	jalr	-1504(ra) # 80001166 <mappages>
    8000174e:	e515                	bnez	a0,8000177a <uvmcow+0x78>
    for(i = 0; i < sz; i += PGSIZE){
    80001750:	6785                	lui	a5,0x1
    80001752:	94be                	add	s1,s1,a5
    80001754:	fd24e4e3          	bltu	s1,s2,8000171c <uvmcow+0x1a>
    80001758:	a81d                	j	8000178e <uvmcow+0x8c>
            panic("uvmcow: pte should exist");
    8000175a:	00007517          	auipc	a0,0x7
    8000175e:	aae50513          	addi	a0,a0,-1362 # 80008208 <digits+0x1b8>
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	dde080e7          	jalr	-546(ra) # 80000540 <panic>
            panic("uvmcow: page not present");
    8000176a:	00007517          	auipc	a0,0x7
    8000176e:	abe50513          	addi	a0,a0,-1346 # 80008228 <digits+0x1d8>
    80001772:	fffff097          	auipc	ra,0xfffff
    80001776:	dce080e7          	jalr	-562(ra) # 80000540 <panic>
        // Increment the reference count for the physical page if needed
    }
    return 0;

err:
    uvmunmap(new, 0, i / PGSIZE, 1);
    8000177a:	4685                	li	a3,1
    8000177c:	00c4d613          	srli	a2,s1,0xc
    80001780:	4581                	li	a1,0
    80001782:	854e                	mv	a0,s3
    80001784:	00000097          	auipc	ra,0x0
    80001788:	ba8080e7          	jalr	-1112(ra) # 8000132c <uvmunmap>
    return -1;
    8000178c:	557d                	li	a0,-1
}
    8000178e:	70a2                	ld	ra,40(sp)
    80001790:	7402                	ld	s0,32(sp)
    80001792:	64e2                	ld	s1,24(sp)
    80001794:	6942                	ld	s2,16(sp)
    80001796:	69a2                	ld	s3,8(sp)
    80001798:	6a02                	ld	s4,0(sp)
    8000179a:	6145                	addi	sp,sp,48
    8000179c:	8082                	ret
    return 0;
    8000179e:	4501                	li	a0,0
}
    800017a0:	8082                	ret

00000000800017a2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017a2:	1141                	addi	sp,sp,-16
    800017a4:	e406                	sd	ra,8(sp)
    800017a6:	e022                	sd	s0,0(sp)
    800017a8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017aa:	4601                	li	a2,0
    800017ac:	00000097          	auipc	ra,0x0
    800017b0:	8d2080e7          	jalr	-1838(ra) # 8000107e <walk>
  if(pte == 0)
    800017b4:	c901                	beqz	a0,800017c4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017b6:	611c                	ld	a5,0(a0)
    800017b8:	9bbd                	andi	a5,a5,-17
    800017ba:	e11c                	sd	a5,0(a0)
}
    800017bc:	60a2                	ld	ra,8(sp)
    800017be:	6402                	ld	s0,0(sp)
    800017c0:	0141                	addi	sp,sp,16
    800017c2:	8082                	ret
    panic("uvmclear");
    800017c4:	00007517          	auipc	a0,0x7
    800017c8:	a8450513          	addi	a0,a0,-1404 # 80008248 <digits+0x1f8>
    800017cc:	fffff097          	auipc	ra,0xfffff
    800017d0:	d74080e7          	jalr	-652(ra) # 80000540 <panic>

00000000800017d4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017d4:	c6bd                	beqz	a3,80001842 <copyout+0x6e>
{
    800017d6:	715d                	addi	sp,sp,-80
    800017d8:	e486                	sd	ra,72(sp)
    800017da:	e0a2                	sd	s0,64(sp)
    800017dc:	fc26                	sd	s1,56(sp)
    800017de:	f84a                	sd	s2,48(sp)
    800017e0:	f44e                	sd	s3,40(sp)
    800017e2:	f052                	sd	s4,32(sp)
    800017e4:	ec56                	sd	s5,24(sp)
    800017e6:	e85a                	sd	s6,16(sp)
    800017e8:	e45e                	sd	s7,8(sp)
    800017ea:	e062                	sd	s8,0(sp)
    800017ec:	0880                	addi	s0,sp,80
    800017ee:	8b2a                	mv	s6,a0
    800017f0:	8c2e                	mv	s8,a1
    800017f2:	8a32                	mv	s4,a2
    800017f4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017f6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017f8:	6a85                	lui	s5,0x1
    800017fa:	a015                	j	8000181e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017fc:	9562                	add	a0,a0,s8
    800017fe:	0004861b          	sext.w	a2,s1
    80001802:	85d2                	mv	a1,s4
    80001804:	41250533          	sub	a0,a0,s2
    80001808:	fffff097          	auipc	ra,0xfffff
    8000180c:	5ee080e7          	jalr	1518(ra) # 80000df6 <memmove>

    len -= n;
    80001810:	409989b3          	sub	s3,s3,s1
    src += n;
    80001814:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001816:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000181a:	02098263          	beqz	s3,8000183e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000181e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001822:	85ca                	mv	a1,s2
    80001824:	855a                	mv	a0,s6
    80001826:	00000097          	auipc	ra,0x0
    8000182a:	8fe080e7          	jalr	-1794(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    8000182e:	cd01                	beqz	a0,80001846 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001830:	418904b3          	sub	s1,s2,s8
    80001834:	94d6                	add	s1,s1,s5
    80001836:	fc99f3e3          	bgeu	s3,s1,800017fc <copyout+0x28>
    8000183a:	84ce                	mv	s1,s3
    8000183c:	b7c1                	j	800017fc <copyout+0x28>
  }
  return 0;
    8000183e:	4501                	li	a0,0
    80001840:	a021                	j	80001848 <copyout+0x74>
    80001842:	4501                	li	a0,0
}
    80001844:	8082                	ret
      return -1;
    80001846:	557d                	li	a0,-1
}
    80001848:	60a6                	ld	ra,72(sp)
    8000184a:	6406                	ld	s0,64(sp)
    8000184c:	74e2                	ld	s1,56(sp)
    8000184e:	7942                	ld	s2,48(sp)
    80001850:	79a2                	ld	s3,40(sp)
    80001852:	7a02                	ld	s4,32(sp)
    80001854:	6ae2                	ld	s5,24(sp)
    80001856:	6b42                	ld	s6,16(sp)
    80001858:	6ba2                	ld	s7,8(sp)
    8000185a:	6c02                	ld	s8,0(sp)
    8000185c:	6161                	addi	sp,sp,80
    8000185e:	8082                	ret

0000000080001860 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001860:	caa5                	beqz	a3,800018d0 <copyin+0x70>
{
    80001862:	715d                	addi	sp,sp,-80
    80001864:	e486                	sd	ra,72(sp)
    80001866:	e0a2                	sd	s0,64(sp)
    80001868:	fc26                	sd	s1,56(sp)
    8000186a:	f84a                	sd	s2,48(sp)
    8000186c:	f44e                	sd	s3,40(sp)
    8000186e:	f052                	sd	s4,32(sp)
    80001870:	ec56                	sd	s5,24(sp)
    80001872:	e85a                	sd	s6,16(sp)
    80001874:	e45e                	sd	s7,8(sp)
    80001876:	e062                	sd	s8,0(sp)
    80001878:	0880                	addi	s0,sp,80
    8000187a:	8b2a                	mv	s6,a0
    8000187c:	8a2e                	mv	s4,a1
    8000187e:	8c32                	mv	s8,a2
    80001880:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001882:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001884:	6a85                	lui	s5,0x1
    80001886:	a01d                	j	800018ac <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001888:	018505b3          	add	a1,a0,s8
    8000188c:	0004861b          	sext.w	a2,s1
    80001890:	412585b3          	sub	a1,a1,s2
    80001894:	8552                	mv	a0,s4
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	560080e7          	jalr	1376(ra) # 80000df6 <memmove>

    len -= n;
    8000189e:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018a2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018a4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018a8:	02098263          	beqz	s3,800018cc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800018ac:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018b0:	85ca                	mv	a1,s2
    800018b2:	855a                	mv	a0,s6
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	870080e7          	jalr	-1936(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    800018bc:	cd01                	beqz	a0,800018d4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018be:	418904b3          	sub	s1,s2,s8
    800018c2:	94d6                	add	s1,s1,s5
    800018c4:	fc99f2e3          	bgeu	s3,s1,80001888 <copyin+0x28>
    800018c8:	84ce                	mv	s1,s3
    800018ca:	bf7d                	j	80001888 <copyin+0x28>
  }
  return 0;
    800018cc:	4501                	li	a0,0
    800018ce:	a021                	j	800018d6 <copyin+0x76>
    800018d0:	4501                	li	a0,0
}
    800018d2:	8082                	ret
      return -1;
    800018d4:	557d                	li	a0,-1
}
    800018d6:	60a6                	ld	ra,72(sp)
    800018d8:	6406                	ld	s0,64(sp)
    800018da:	74e2                	ld	s1,56(sp)
    800018dc:	7942                	ld	s2,48(sp)
    800018de:	79a2                	ld	s3,40(sp)
    800018e0:	7a02                	ld	s4,32(sp)
    800018e2:	6ae2                	ld	s5,24(sp)
    800018e4:	6b42                	ld	s6,16(sp)
    800018e6:	6ba2                	ld	s7,8(sp)
    800018e8:	6c02                	ld	s8,0(sp)
    800018ea:	6161                	addi	sp,sp,80
    800018ec:	8082                	ret

00000000800018ee <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ee:	c2dd                	beqz	a3,80001994 <copyinstr+0xa6>
{
    800018f0:	715d                	addi	sp,sp,-80
    800018f2:	e486                	sd	ra,72(sp)
    800018f4:	e0a2                	sd	s0,64(sp)
    800018f6:	fc26                	sd	s1,56(sp)
    800018f8:	f84a                	sd	s2,48(sp)
    800018fa:	f44e                	sd	s3,40(sp)
    800018fc:	f052                	sd	s4,32(sp)
    800018fe:	ec56                	sd	s5,24(sp)
    80001900:	e85a                	sd	s6,16(sp)
    80001902:	e45e                	sd	s7,8(sp)
    80001904:	0880                	addi	s0,sp,80
    80001906:	8a2a                	mv	s4,a0
    80001908:	8b2e                	mv	s6,a1
    8000190a:	8bb2                	mv	s7,a2
    8000190c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000190e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001910:	6985                	lui	s3,0x1
    80001912:	a02d                	j	8000193c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001914:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001918:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000191a:	37fd                	addiw	a5,a5,-1
    8000191c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001920:	60a6                	ld	ra,72(sp)
    80001922:	6406                	ld	s0,64(sp)
    80001924:	74e2                	ld	s1,56(sp)
    80001926:	7942                	ld	s2,48(sp)
    80001928:	79a2                	ld	s3,40(sp)
    8000192a:	7a02                	ld	s4,32(sp)
    8000192c:	6ae2                	ld	s5,24(sp)
    8000192e:	6b42                	ld	s6,16(sp)
    80001930:	6ba2                	ld	s7,8(sp)
    80001932:	6161                	addi	sp,sp,80
    80001934:	8082                	ret
    srcva = va0 + PGSIZE;
    80001936:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000193a:	c8a9                	beqz	s1,8000198c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000193c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001940:	85ca                	mv	a1,s2
    80001942:	8552                	mv	a0,s4
    80001944:	fffff097          	auipc	ra,0xfffff
    80001948:	7e0080e7          	jalr	2016(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    8000194c:	c131                	beqz	a0,80001990 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000194e:	417906b3          	sub	a3,s2,s7
    80001952:	96ce                	add	a3,a3,s3
    80001954:	00d4f363          	bgeu	s1,a3,8000195a <copyinstr+0x6c>
    80001958:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000195a:	955e                	add	a0,a0,s7
    8000195c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001960:	daf9                	beqz	a3,80001936 <copyinstr+0x48>
    80001962:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001964:	41650633          	sub	a2,a0,s6
    80001968:	fff48593          	addi	a1,s1,-1
    8000196c:	95da                	add	a1,a1,s6
    while(n > 0){
    8000196e:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001970:	00f60733          	add	a4,a2,a5
    80001974:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd0b0>
    80001978:	df51                	beqz	a4,80001914 <copyinstr+0x26>
        *dst = *p;
    8000197a:	00e78023          	sb	a4,0(a5)
      --max;
    8000197e:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001982:	0785                	addi	a5,a5,1
    while(n > 0){
    80001984:	fed796e3          	bne	a5,a3,80001970 <copyinstr+0x82>
      dst++;
    80001988:	8b3e                	mv	s6,a5
    8000198a:	b775                	j	80001936 <copyinstr+0x48>
    8000198c:	4781                	li	a5,0
    8000198e:	b771                	j	8000191a <copyinstr+0x2c>
      return -1;
    80001990:	557d                	li	a0,-1
    80001992:	b779                	j	80001920 <copyinstr+0x32>
  int got_null = 0;
    80001994:	4781                	li	a5,0
  if(got_null){
    80001996:	37fd                	addiw	a5,a5,-1
    80001998:	0007851b          	sext.w	a0,a5
}
    8000199c:	8082                	ret

000000008000199e <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    8000199e:	715d                	addi	sp,sp,-80
    800019a0:	e486                	sd	ra,72(sp)
    800019a2:	e0a2                	sd	s0,64(sp)
    800019a4:	fc26                	sd	s1,56(sp)
    800019a6:	f84a                	sd	s2,48(sp)
    800019a8:	f44e                	sd	s3,40(sp)
    800019aa:	f052                	sd	s4,32(sp)
    800019ac:	ec56                	sd	s5,24(sp)
    800019ae:	e85a                	sd	s6,16(sp)
    800019b0:	e45e                	sd	s7,8(sp)
    800019b2:	e062                	sd	s8,0(sp)
    800019b4:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    800019b6:	8792                	mv	a5,tp
    int id = r_tp();
    800019b8:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    800019ba:	0000fa97          	auipc	s5,0xf
    800019be:	386a8a93          	addi	s5,s5,902 # 80010d40 <cpus>
    800019c2:	00779713          	slli	a4,a5,0x7
    800019c6:	00ea86b3          	add	a3,s5,a4
    800019ca:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdd0b0>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    800019ce:	0721                	addi	a4,a4,8
    800019d0:	9aba                	add	s5,s5,a4
                c->proc = p;
    800019d2:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    800019d4:	00007c17          	auipc	s8,0x7
    800019d8:	024c0c13          	addi	s8,s8,36 # 800089f8 <sched_pointer>
    800019dc:	00000b97          	auipc	s7,0x0
    800019e0:	fc2b8b93          	addi	s7,s7,-62 # 8000199e <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800019e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800019e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800019ec:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    800019f0:	0000f497          	auipc	s1,0xf
    800019f4:	78048493          	addi	s1,s1,1920 # 80011170 <proc>
            if (p->state == RUNNABLE)
    800019f8:	498d                	li	s3,3
                p->state = RUNNING;
    800019fa:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    800019fc:	00015a17          	auipc	s4,0x15
    80001a00:	174a0a13          	addi	s4,s4,372 # 80016b70 <tickslock>
    80001a04:	a81d                	j	80001a3a <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001a06:	8526                	mv	a0,s1
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	34a080e7          	jalr	842(ra) # 80000d52 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001a10:	60a6                	ld	ra,72(sp)
    80001a12:	6406                	ld	s0,64(sp)
    80001a14:	74e2                	ld	s1,56(sp)
    80001a16:	7942                	ld	s2,48(sp)
    80001a18:	79a2                	ld	s3,40(sp)
    80001a1a:	7a02                	ld	s4,32(sp)
    80001a1c:	6ae2                	ld	s5,24(sp)
    80001a1e:	6b42                	ld	s6,16(sp)
    80001a20:	6ba2                	ld	s7,8(sp)
    80001a22:	6c02                	ld	s8,0(sp)
    80001a24:	6161                	addi	sp,sp,80
    80001a26:	8082                	ret
            release(&p->lock);
    80001a28:	8526                	mv	a0,s1
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	328080e7          	jalr	808(ra) # 80000d52 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001a32:	16848493          	addi	s1,s1,360
    80001a36:	fb4487e3          	beq	s1,s4,800019e4 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001a3a:	8526                	mv	a0,s1
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	262080e7          	jalr	610(ra) # 80000c9e <acquire>
            if (p->state == RUNNABLE)
    80001a44:	4c9c                	lw	a5,24(s1)
    80001a46:	ff3791e3          	bne	a5,s3,80001a28 <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001a4a:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001a4e:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001a52:	06048593          	addi	a1,s1,96
    80001a56:	8556                	mv	a0,s5
    80001a58:	00001097          	auipc	ra,0x1
    80001a5c:	fae080e7          	jalr	-82(ra) # 80002a06 <swtch>
                if (sched_pointer != &rr_scheduler)
    80001a60:	000c3783          	ld	a5,0(s8)
    80001a64:	fb7791e3          	bne	a5,s7,80001a06 <rr_scheduler+0x68>
                c->proc = 0;
    80001a68:	00093023          	sd	zero,0(s2)
    80001a6c:	bf75                	j	80001a28 <rr_scheduler+0x8a>

0000000080001a6e <proc_mapstacks>:
{
    80001a6e:	7139                	addi	sp,sp,-64
    80001a70:	fc06                	sd	ra,56(sp)
    80001a72:	f822                	sd	s0,48(sp)
    80001a74:	f426                	sd	s1,40(sp)
    80001a76:	f04a                	sd	s2,32(sp)
    80001a78:	ec4e                	sd	s3,24(sp)
    80001a7a:	e852                	sd	s4,16(sp)
    80001a7c:	e456                	sd	s5,8(sp)
    80001a7e:	e05a                	sd	s6,0(sp)
    80001a80:	0080                	addi	s0,sp,64
    80001a82:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001a84:	0000f497          	auipc	s1,0xf
    80001a88:	6ec48493          	addi	s1,s1,1772 # 80011170 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001a8c:	8b26                	mv	s6,s1
    80001a8e:	00006a97          	auipc	s5,0x6
    80001a92:	582a8a93          	addi	s5,s5,1410 # 80008010 <__func__.1+0x8>
    80001a96:	04000937          	lui	s2,0x4000
    80001a9a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a9e:	00015a17          	auipc	s4,0x15
    80001aa2:	0d2a0a13          	addi	s4,s4,210 # 80016b70 <tickslock>
        char *pa = kalloc();
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	0bc080e7          	jalr	188(ra) # 80000b62 <kalloc>
    80001aae:	862a                	mv	a2,a0
        if (pa == 0)
    80001ab0:	c131                	beqz	a0,80001af4 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001ab2:	416485b3          	sub	a1,s1,s6
    80001ab6:	858d                	srai	a1,a1,0x3
    80001ab8:	000ab783          	ld	a5,0(s5)
    80001abc:	02f585b3          	mul	a1,a1,a5
    80001ac0:	2585                	addiw	a1,a1,1
    80001ac2:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ac6:	4719                	li	a4,6
    80001ac8:	6685                	lui	a3,0x1
    80001aca:	40b905b3          	sub	a1,s2,a1
    80001ace:	854e                	mv	a0,s3
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	736080e7          	jalr	1846(ra) # 80001206 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001ad8:	16848493          	addi	s1,s1,360
    80001adc:	fd4495e3          	bne	s1,s4,80001aa6 <proc_mapstacks+0x38>
}
    80001ae0:	70e2                	ld	ra,56(sp)
    80001ae2:	7442                	ld	s0,48(sp)
    80001ae4:	74a2                	ld	s1,40(sp)
    80001ae6:	7902                	ld	s2,32(sp)
    80001ae8:	69e2                	ld	s3,24(sp)
    80001aea:	6a42                	ld	s4,16(sp)
    80001aec:	6aa2                	ld	s5,8(sp)
    80001aee:	6b02                	ld	s6,0(sp)
    80001af0:	6121                	addi	sp,sp,64
    80001af2:	8082                	ret
            panic("kalloc");
    80001af4:	00006517          	auipc	a0,0x6
    80001af8:	76450513          	addi	a0,a0,1892 # 80008258 <digits+0x208>
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	a44080e7          	jalr	-1468(ra) # 80000540 <panic>

0000000080001b04 <procinit>:
{
    80001b04:	7139                	addi	sp,sp,-64
    80001b06:	fc06                	sd	ra,56(sp)
    80001b08:	f822                	sd	s0,48(sp)
    80001b0a:	f426                	sd	s1,40(sp)
    80001b0c:	f04a                	sd	s2,32(sp)
    80001b0e:	ec4e                	sd	s3,24(sp)
    80001b10:	e852                	sd	s4,16(sp)
    80001b12:	e456                	sd	s5,8(sp)
    80001b14:	e05a                	sd	s6,0(sp)
    80001b16:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001b18:	00006597          	auipc	a1,0x6
    80001b1c:	74858593          	addi	a1,a1,1864 # 80008260 <digits+0x210>
    80001b20:	0000f517          	auipc	a0,0xf
    80001b24:	62050513          	addi	a0,a0,1568 # 80011140 <pid_lock>
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	0e6080e7          	jalr	230(ra) # 80000c0e <initlock>
    initlock(&wait_lock, "wait_lock");
    80001b30:	00006597          	auipc	a1,0x6
    80001b34:	73858593          	addi	a1,a1,1848 # 80008268 <digits+0x218>
    80001b38:	0000f517          	auipc	a0,0xf
    80001b3c:	62050513          	addi	a0,a0,1568 # 80011158 <wait_lock>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	0ce080e7          	jalr	206(ra) # 80000c0e <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b48:	0000f497          	auipc	s1,0xf
    80001b4c:	62848493          	addi	s1,s1,1576 # 80011170 <proc>
        initlock(&p->lock, "proc");
    80001b50:	00006b17          	auipc	s6,0x6
    80001b54:	728b0b13          	addi	s6,s6,1832 # 80008278 <digits+0x228>
        p->kstack = KSTACK((int)(p - proc));
    80001b58:	8aa6                	mv	s5,s1
    80001b5a:	00006a17          	auipc	s4,0x6
    80001b5e:	4b6a0a13          	addi	s4,s4,1206 # 80008010 <__func__.1+0x8>
    80001b62:	04000937          	lui	s2,0x4000
    80001b66:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b68:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b6a:	00015997          	auipc	s3,0x15
    80001b6e:	00698993          	addi	s3,s3,6 # 80016b70 <tickslock>
        initlock(&p->lock, "proc");
    80001b72:	85da                	mv	a1,s6
    80001b74:	8526                	mv	a0,s1
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	098080e7          	jalr	152(ra) # 80000c0e <initlock>
        p->state = UNUSED;
    80001b7e:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001b82:	415487b3          	sub	a5,s1,s5
    80001b86:	878d                	srai	a5,a5,0x3
    80001b88:	000a3703          	ld	a4,0(s4)
    80001b8c:	02e787b3          	mul	a5,a5,a4
    80001b90:	2785                	addiw	a5,a5,1
    80001b92:	00d7979b          	slliw	a5,a5,0xd
    80001b96:	40f907b3          	sub	a5,s2,a5
    80001b9a:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b9c:	16848493          	addi	s1,s1,360
    80001ba0:	fd3499e3          	bne	s1,s3,80001b72 <procinit+0x6e>
}
    80001ba4:	70e2                	ld	ra,56(sp)
    80001ba6:	7442                	ld	s0,48(sp)
    80001ba8:	74a2                	ld	s1,40(sp)
    80001baa:	7902                	ld	s2,32(sp)
    80001bac:	69e2                	ld	s3,24(sp)
    80001bae:	6a42                	ld	s4,16(sp)
    80001bb0:	6aa2                	ld	s5,8(sp)
    80001bb2:	6b02                	ld	s6,0(sp)
    80001bb4:	6121                	addi	sp,sp,64
    80001bb6:	8082                	ret

0000000080001bb8 <copy_array>:
{
    80001bb8:	1141                	addi	sp,sp,-16
    80001bba:	e422                	sd	s0,8(sp)
    80001bbc:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001bbe:	02c05163          	blez	a2,80001be0 <copy_array+0x28>
    80001bc2:	87aa                	mv	a5,a0
    80001bc4:	0505                	addi	a0,a0,1
    80001bc6:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001bc8:	1602                	slli	a2,a2,0x20
    80001bca:	9201                	srli	a2,a2,0x20
    80001bcc:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001bd0:	0007c703          	lbu	a4,0(a5)
    80001bd4:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001bd8:	0785                	addi	a5,a5,1
    80001bda:	0585                	addi	a1,a1,1
    80001bdc:	fed79ae3          	bne	a5,a3,80001bd0 <copy_array+0x18>
}
    80001be0:	6422                	ld	s0,8(sp)
    80001be2:	0141                	addi	sp,sp,16
    80001be4:	8082                	ret

0000000080001be6 <cpuid>:
{
    80001be6:	1141                	addi	sp,sp,-16
    80001be8:	e422                	sd	s0,8(sp)
    80001bea:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bec:	8512                	mv	a0,tp
}
    80001bee:	2501                	sext.w	a0,a0
    80001bf0:	6422                	ld	s0,8(sp)
    80001bf2:	0141                	addi	sp,sp,16
    80001bf4:	8082                	ret

0000000080001bf6 <mycpu>:
{
    80001bf6:	1141                	addi	sp,sp,-16
    80001bf8:	e422                	sd	s0,8(sp)
    80001bfa:	0800                	addi	s0,sp,16
    80001bfc:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001bfe:	2781                	sext.w	a5,a5
    80001c00:	079e                	slli	a5,a5,0x7
}
    80001c02:	0000f517          	auipc	a0,0xf
    80001c06:	13e50513          	addi	a0,a0,318 # 80010d40 <cpus>
    80001c0a:	953e                	add	a0,a0,a5
    80001c0c:	6422                	ld	s0,8(sp)
    80001c0e:	0141                	addi	sp,sp,16
    80001c10:	8082                	ret

0000000080001c12 <myproc>:
{
    80001c12:	1101                	addi	sp,sp,-32
    80001c14:	ec06                	sd	ra,24(sp)
    80001c16:	e822                	sd	s0,16(sp)
    80001c18:	e426                	sd	s1,8(sp)
    80001c1a:	1000                	addi	s0,sp,32
    push_off();
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	036080e7          	jalr	54(ra) # 80000c52 <push_off>
    80001c24:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001c26:	2781                	sext.w	a5,a5
    80001c28:	079e                	slli	a5,a5,0x7
    80001c2a:	0000f717          	auipc	a4,0xf
    80001c2e:	11670713          	addi	a4,a4,278 # 80010d40 <cpus>
    80001c32:	97ba                	add	a5,a5,a4
    80001c34:	6384                	ld	s1,0(a5)
    pop_off();
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	0bc080e7          	jalr	188(ra) # 80000cf2 <pop_off>
}
    80001c3e:	8526                	mv	a0,s1
    80001c40:	60e2                	ld	ra,24(sp)
    80001c42:	6442                	ld	s0,16(sp)
    80001c44:	64a2                	ld	s1,8(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret

0000000080001c4a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c4a:	1141                	addi	sp,sp,-16
    80001c4c:	e406                	sd	ra,8(sp)
    80001c4e:	e022                	sd	s0,0(sp)
    80001c50:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	fc0080e7          	jalr	-64(ra) # 80001c12 <myproc>
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	0f8080e7          	jalr	248(ra) # 80000d52 <release>

    if (first)
    80001c62:	00007797          	auipc	a5,0x7
    80001c66:	d8e7a783          	lw	a5,-626(a5) # 800089f0 <first.1>
    80001c6a:	eb89                	bnez	a5,80001c7c <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001c6c:	00001097          	auipc	ra,0x1
    80001c70:	e52080e7          	jalr	-430(ra) # 80002abe <usertrapret>
}
    80001c74:	60a2                	ld	ra,8(sp)
    80001c76:	6402                	ld	s0,0(sp)
    80001c78:	0141                	addi	sp,sp,16
    80001c7a:	8082                	ret
        first = 0;
    80001c7c:	00007797          	auipc	a5,0x7
    80001c80:	d607aa23          	sw	zero,-652(a5) # 800089f0 <first.1>
        fsinit(ROOTDEV);
    80001c84:	4505                	li	a0,1
    80001c86:	00002097          	auipc	ra,0x2
    80001c8a:	dd2080e7          	jalr	-558(ra) # 80003a58 <fsinit>
    80001c8e:	bff9                	j	80001c6c <forkret+0x22>

0000000080001c90 <allocpid>:
{
    80001c90:	1101                	addi	sp,sp,-32
    80001c92:	ec06                	sd	ra,24(sp)
    80001c94:	e822                	sd	s0,16(sp)
    80001c96:	e426                	sd	s1,8(sp)
    80001c98:	e04a                	sd	s2,0(sp)
    80001c9a:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c9c:	0000f917          	auipc	s2,0xf
    80001ca0:	4a490913          	addi	s2,s2,1188 # 80011140 <pid_lock>
    80001ca4:	854a                	mv	a0,s2
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	ff8080e7          	jalr	-8(ra) # 80000c9e <acquire>
    pid = nextpid;
    80001cae:	00007797          	auipc	a5,0x7
    80001cb2:	d5278793          	addi	a5,a5,-686 # 80008a00 <nextpid>
    80001cb6:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001cb8:	0014871b          	addiw	a4,s1,1
    80001cbc:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001cbe:	854a                	mv	a0,s2
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	092080e7          	jalr	146(ra) # 80000d52 <release>
}
    80001cc8:	8526                	mv	a0,s1
    80001cca:	60e2                	ld	ra,24(sp)
    80001ccc:	6442                	ld	s0,16(sp)
    80001cce:	64a2                	ld	s1,8(sp)
    80001cd0:	6902                	ld	s2,0(sp)
    80001cd2:	6105                	addi	sp,sp,32
    80001cd4:	8082                	ret

0000000080001cd6 <proc_pagetable>:
{
    80001cd6:	1101                	addi	sp,sp,-32
    80001cd8:	ec06                	sd	ra,24(sp)
    80001cda:	e822                	sd	s0,16(sp)
    80001cdc:	e426                	sd	s1,8(sp)
    80001cde:	e04a                	sd	s2,0(sp)
    80001ce0:	1000                	addi	s0,sp,32
    80001ce2:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	70c080e7          	jalr	1804(ra) # 800013f0 <uvmcreate>
    80001cec:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001cee:	c121                	beqz	a0,80001d2e <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cf0:	4729                	li	a4,10
    80001cf2:	00005697          	auipc	a3,0x5
    80001cf6:	30e68693          	addi	a3,a3,782 # 80007000 <_trampoline>
    80001cfa:	6605                	lui	a2,0x1
    80001cfc:	040005b7          	lui	a1,0x4000
    80001d00:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d02:	05b2                	slli	a1,a1,0xc
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	462080e7          	jalr	1122(ra) # 80001166 <mappages>
    80001d0c:	02054863          	bltz	a0,80001d3c <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d10:	4719                	li	a4,6
    80001d12:	05893683          	ld	a3,88(s2)
    80001d16:	6605                	lui	a2,0x1
    80001d18:	020005b7          	lui	a1,0x2000
    80001d1c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d1e:	05b6                	slli	a1,a1,0xd
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	444080e7          	jalr	1092(ra) # 80001166 <mappages>
    80001d2a:	02054163          	bltz	a0,80001d4c <proc_pagetable+0x76>
}
    80001d2e:	8526                	mv	a0,s1
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6902                	ld	s2,0(sp)
    80001d38:	6105                	addi	sp,sp,32
    80001d3a:	8082                	ret
        uvmfree(pagetable, 0);
    80001d3c:	4581                	li	a1,0
    80001d3e:	8526                	mv	a0,s1
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	8b6080e7          	jalr	-1866(ra) # 800015f6 <uvmfree>
        return 0;
    80001d48:	4481                	li	s1,0
    80001d4a:	b7d5                	j	80001d2e <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d4c:	4681                	li	a3,0
    80001d4e:	4605                	li	a2,1
    80001d50:	040005b7          	lui	a1,0x4000
    80001d54:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d56:	05b2                	slli	a1,a1,0xc
    80001d58:	8526                	mv	a0,s1
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	5d2080e7          	jalr	1490(ra) # 8000132c <uvmunmap>
        uvmfree(pagetable, 0);
    80001d62:	4581                	li	a1,0
    80001d64:	8526                	mv	a0,s1
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	890080e7          	jalr	-1904(ra) # 800015f6 <uvmfree>
        return 0;
    80001d6e:	4481                	li	s1,0
    80001d70:	bf7d                	j	80001d2e <proc_pagetable+0x58>

0000000080001d72 <proc_freepagetable>:
{
    80001d72:	1101                	addi	sp,sp,-32
    80001d74:	ec06                	sd	ra,24(sp)
    80001d76:	e822                	sd	s0,16(sp)
    80001d78:	e426                	sd	s1,8(sp)
    80001d7a:	e04a                	sd	s2,0(sp)
    80001d7c:	1000                	addi	s0,sp,32
    80001d7e:	84aa                	mv	s1,a0
    80001d80:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d82:	4681                	li	a3,0
    80001d84:	4605                	li	a2,1
    80001d86:	040005b7          	lui	a1,0x4000
    80001d8a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d8c:	05b2                	slli	a1,a1,0xc
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	59e080e7          	jalr	1438(ra) # 8000132c <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d96:	4681                	li	a3,0
    80001d98:	4605                	li	a2,1
    80001d9a:	020005b7          	lui	a1,0x2000
    80001d9e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001da0:	05b6                	slli	a1,a1,0xd
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	588080e7          	jalr	1416(ra) # 8000132c <uvmunmap>
    uvmfree(pagetable, sz);
    80001dac:	85ca                	mv	a1,s2
    80001dae:	8526                	mv	a0,s1
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	846080e7          	jalr	-1978(ra) # 800015f6 <uvmfree>
}
    80001db8:	60e2                	ld	ra,24(sp)
    80001dba:	6442                	ld	s0,16(sp)
    80001dbc:	64a2                	ld	s1,8(sp)
    80001dbe:	6902                	ld	s2,0(sp)
    80001dc0:	6105                	addi	sp,sp,32
    80001dc2:	8082                	ret

0000000080001dc4 <freeproc>:
{
    80001dc4:	1101                	addi	sp,sp,-32
    80001dc6:	ec06                	sd	ra,24(sp)
    80001dc8:	e822                	sd	s0,16(sp)
    80001dca:	e426                	sd	s1,8(sp)
    80001dcc:	1000                	addi	s0,sp,32
    80001dce:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001dd0:	6d28                	ld	a0,88(a0)
    80001dd2:	c509                	beqz	a0,80001ddc <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	c26080e7          	jalr	-986(ra) # 800009fa <kfree>
    p->trapframe = 0;
    80001ddc:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001de0:	68a8                	ld	a0,80(s1)
    80001de2:	c511                	beqz	a0,80001dee <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001de4:	64ac                	ld	a1,72(s1)
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	f8c080e7          	jalr	-116(ra) # 80001d72 <proc_freepagetable>
    p->pagetable = 0;
    80001dee:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001df2:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001df6:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001dfa:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001dfe:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001e02:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001e06:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001e0a:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001e0e:	0004ac23          	sw	zero,24(s1)
}
    80001e12:	60e2                	ld	ra,24(sp)
    80001e14:	6442                	ld	s0,16(sp)
    80001e16:	64a2                	ld	s1,8(sp)
    80001e18:	6105                	addi	sp,sp,32
    80001e1a:	8082                	ret

0000000080001e1c <allocproc>:
{
    80001e1c:	1101                	addi	sp,sp,-32
    80001e1e:	ec06                	sd	ra,24(sp)
    80001e20:	e822                	sd	s0,16(sp)
    80001e22:	e426                	sd	s1,8(sp)
    80001e24:	e04a                	sd	s2,0(sp)
    80001e26:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e28:	0000f497          	auipc	s1,0xf
    80001e2c:	34848493          	addi	s1,s1,840 # 80011170 <proc>
    80001e30:	00015917          	auipc	s2,0x15
    80001e34:	d4090913          	addi	s2,s2,-704 # 80016b70 <tickslock>
        acquire(&p->lock);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e64080e7          	jalr	-412(ra) # 80000c9e <acquire>
        if (p->state == UNUSED)
    80001e42:	4c9c                	lw	a5,24(s1)
    80001e44:	cf81                	beqz	a5,80001e5c <allocproc+0x40>
            release(&p->lock);
    80001e46:	8526                	mv	a0,s1
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	f0a080e7          	jalr	-246(ra) # 80000d52 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001e50:	16848493          	addi	s1,s1,360
    80001e54:	ff2492e3          	bne	s1,s2,80001e38 <allocproc+0x1c>
    return 0;
    80001e58:	4481                	li	s1,0
    80001e5a:	a889                	j	80001eac <allocproc+0x90>
    p->pid = allocpid();
    80001e5c:	00000097          	auipc	ra,0x0
    80001e60:	e34080e7          	jalr	-460(ra) # 80001c90 <allocpid>
    80001e64:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001e66:	4785                	li	a5,1
    80001e68:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	cf8080e7          	jalr	-776(ra) # 80000b62 <kalloc>
    80001e72:	892a                	mv	s2,a0
    80001e74:	eca8                	sd	a0,88(s1)
    80001e76:	c131                	beqz	a0,80001eba <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001e78:	8526                	mv	a0,s1
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	e5c080e7          	jalr	-420(ra) # 80001cd6 <proc_pagetable>
    80001e82:	892a                	mv	s2,a0
    80001e84:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001e86:	c531                	beqz	a0,80001ed2 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001e88:	07000613          	li	a2,112
    80001e8c:	4581                	li	a1,0
    80001e8e:	06048513          	addi	a0,s1,96
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	f08080e7          	jalr	-248(ra) # 80000d9a <memset>
    p->context.ra = (uint64)forkret;
    80001e9a:	00000797          	auipc	a5,0x0
    80001e9e:	db078793          	addi	a5,a5,-592 # 80001c4a <forkret>
    80001ea2:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001ea4:	60bc                	ld	a5,64(s1)
    80001ea6:	6705                	lui	a4,0x1
    80001ea8:	97ba                	add	a5,a5,a4
    80001eaa:	f4bc                	sd	a5,104(s1)
}
    80001eac:	8526                	mv	a0,s1
    80001eae:	60e2                	ld	ra,24(sp)
    80001eb0:	6442                	ld	s0,16(sp)
    80001eb2:	64a2                	ld	s1,8(sp)
    80001eb4:	6902                	ld	s2,0(sp)
    80001eb6:	6105                	addi	sp,sp,32
    80001eb8:	8082                	ret
        freeproc(p);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	00000097          	auipc	ra,0x0
    80001ec0:	f08080e7          	jalr	-248(ra) # 80001dc4 <freeproc>
        release(&p->lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	e8c080e7          	jalr	-372(ra) # 80000d52 <release>
        return 0;
    80001ece:	84ca                	mv	s1,s2
    80001ed0:	bff1                	j	80001eac <allocproc+0x90>
        freeproc(p);
    80001ed2:	8526                	mv	a0,s1
    80001ed4:	00000097          	auipc	ra,0x0
    80001ed8:	ef0080e7          	jalr	-272(ra) # 80001dc4 <freeproc>
        release(&p->lock);
    80001edc:	8526                	mv	a0,s1
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	e74080e7          	jalr	-396(ra) # 80000d52 <release>
        return 0;
    80001ee6:	84ca                	mv	s1,s2
    80001ee8:	b7d1                	j	80001eac <allocproc+0x90>

0000000080001eea <userinit>:
{
    80001eea:	1101                	addi	sp,sp,-32
    80001eec:	ec06                	sd	ra,24(sp)
    80001eee:	e822                	sd	s0,16(sp)
    80001ef0:	e426                	sd	s1,8(sp)
    80001ef2:	1000                	addi	s0,sp,32
    p = allocproc();
    80001ef4:	00000097          	auipc	ra,0x0
    80001ef8:	f28080e7          	jalr	-216(ra) # 80001e1c <allocproc>
    80001efc:	84aa                	mv	s1,a0
    initproc = p;
    80001efe:	00007797          	auipc	a5,0x7
    80001f02:	bca7b523          	sd	a0,-1078(a5) # 80008ac8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f06:	03400613          	li	a2,52
    80001f0a:	00007597          	auipc	a1,0x7
    80001f0e:	b0658593          	addi	a1,a1,-1274 # 80008a10 <initcode>
    80001f12:	6928                	ld	a0,80(a0)
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	50a080e7          	jalr	1290(ra) # 8000141e <uvmfirst>
    p->sz = PGSIZE;
    80001f1c:	6785                	lui	a5,0x1
    80001f1e:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001f20:	6cb8                	ld	a4,88(s1)
    80001f22:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f26:	6cb8                	ld	a4,88(s1)
    80001f28:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f2a:	4641                	li	a2,16
    80001f2c:	00006597          	auipc	a1,0x6
    80001f30:	35458593          	addi	a1,a1,852 # 80008280 <digits+0x230>
    80001f34:	15848513          	addi	a0,s1,344
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	fac080e7          	jalr	-84(ra) # 80000ee4 <safestrcpy>
    p->cwd = namei("/");
    80001f40:	00006517          	auipc	a0,0x6
    80001f44:	35050513          	addi	a0,a0,848 # 80008290 <digits+0x240>
    80001f48:	00002097          	auipc	ra,0x2
    80001f4c:	53a080e7          	jalr	1338(ra) # 80004482 <namei>
    80001f50:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001f54:	478d                	li	a5,3
    80001f56:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	df8080e7          	jalr	-520(ra) # 80000d52 <release>
}
    80001f62:	60e2                	ld	ra,24(sp)
    80001f64:	6442                	ld	s0,16(sp)
    80001f66:	64a2                	ld	s1,8(sp)
    80001f68:	6105                	addi	sp,sp,32
    80001f6a:	8082                	ret

0000000080001f6c <growproc>:
{
    80001f6c:	1101                	addi	sp,sp,-32
    80001f6e:	ec06                	sd	ra,24(sp)
    80001f70:	e822                	sd	s0,16(sp)
    80001f72:	e426                	sd	s1,8(sp)
    80001f74:	e04a                	sd	s2,0(sp)
    80001f76:	1000                	addi	s0,sp,32
    80001f78:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	c98080e7          	jalr	-872(ra) # 80001c12 <myproc>
    80001f82:	84aa                	mv	s1,a0
    sz = p->sz;
    80001f84:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001f86:	01204c63          	bgtz	s2,80001f9e <growproc+0x32>
    else if (n < 0)
    80001f8a:	02094663          	bltz	s2,80001fb6 <growproc+0x4a>
    p->sz = sz;
    80001f8e:	e4ac                	sd	a1,72(s1)
    return 0;
    80001f90:	4501                	li	a0,0
}
    80001f92:	60e2                	ld	ra,24(sp)
    80001f94:	6442                	ld	s0,16(sp)
    80001f96:	64a2                	ld	s1,8(sp)
    80001f98:	6902                	ld	s2,0(sp)
    80001f9a:	6105                	addi	sp,sp,32
    80001f9c:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f9e:	4691                	li	a3,4
    80001fa0:	00b90633          	add	a2,s2,a1
    80001fa4:	6928                	ld	a0,80(a0)
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	532080e7          	jalr	1330(ra) # 800014d8 <uvmalloc>
    80001fae:	85aa                	mv	a1,a0
    80001fb0:	fd79                	bnez	a0,80001f8e <growproc+0x22>
            return -1;
    80001fb2:	557d                	li	a0,-1
    80001fb4:	bff9                	j	80001f92 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fb6:	00b90633          	add	a2,s2,a1
    80001fba:	6928                	ld	a0,80(a0)
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	4d4080e7          	jalr	1236(ra) # 80001490 <uvmdealloc>
    80001fc4:	85aa                	mv	a1,a0
    80001fc6:	b7e1                	j	80001f8e <growproc+0x22>

0000000080001fc8 <ps>:
{
    80001fc8:	715d                	addi	sp,sp,-80
    80001fca:	e486                	sd	ra,72(sp)
    80001fcc:	e0a2                	sd	s0,64(sp)
    80001fce:	fc26                	sd	s1,56(sp)
    80001fd0:	f84a                	sd	s2,48(sp)
    80001fd2:	f44e                	sd	s3,40(sp)
    80001fd4:	f052                	sd	s4,32(sp)
    80001fd6:	ec56                	sd	s5,24(sp)
    80001fd8:	e85a                	sd	s6,16(sp)
    80001fda:	e45e                	sd	s7,8(sp)
    80001fdc:	e062                	sd	s8,0(sp)
    80001fde:	0880                	addi	s0,sp,80
    80001fe0:	84aa                	mv	s1,a0
    80001fe2:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	c2e080e7          	jalr	-978(ra) # 80001c12 <myproc>
        return result;
    80001fec:	4901                	li	s2,0
    if (count == 0)
    80001fee:	0c0b8563          	beqz	s7,800020b8 <ps+0xf0>
    void *result = (void *)myproc()->sz;
    80001ff2:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001ff6:	003b951b          	slliw	a0,s7,0x3
    80001ffa:	0175053b          	addw	a0,a0,s7
    80001ffe:	0025151b          	slliw	a0,a0,0x2
    80002002:	00000097          	auipc	ra,0x0
    80002006:	f6a080e7          	jalr	-150(ra) # 80001f6c <growproc>
    8000200a:	12054f63          	bltz	a0,80002148 <ps+0x180>
    struct user_proc loc_result[count];
    8000200e:	003b9a13          	slli	s4,s7,0x3
    80002012:	9a5e                	add	s4,s4,s7
    80002014:	0a0a                	slli	s4,s4,0x2
    80002016:	00fa0793          	addi	a5,s4,15
    8000201a:	8391                	srli	a5,a5,0x4
    8000201c:	0792                	slli	a5,a5,0x4
    8000201e:	40f10133          	sub	sp,sp,a5
    80002022:	8a8a                	mv	s5,sp
    struct proc *p = proc + start;
    80002024:	16800793          	li	a5,360
    80002028:	02f484b3          	mul	s1,s1,a5
    8000202c:	0000f797          	auipc	a5,0xf
    80002030:	14478793          	addi	a5,a5,324 # 80011170 <proc>
    80002034:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80002036:	00015797          	auipc	a5,0x15
    8000203a:	b3a78793          	addi	a5,a5,-1222 # 80016b70 <tickslock>
        return result;
    8000203e:	4901                	li	s2,0
    if (p >= &proc[NPROC])
    80002040:	06f4fc63          	bgeu	s1,a5,800020b8 <ps+0xf0>
    acquire(&wait_lock);
    80002044:	0000f517          	auipc	a0,0xf
    80002048:	11450513          	addi	a0,a0,276 # 80011158 <wait_lock>
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c52080e7          	jalr	-942(ra) # 80000c9e <acquire>
        if (localCount == count)
    80002054:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80002058:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    8000205a:	00015c17          	auipc	s8,0x15
    8000205e:	b16c0c13          	addi	s8,s8,-1258 # 80016b70 <tickslock>
    80002062:	a851                	j	800020f6 <ps+0x12e>
            loc_result[localCount].state = UNUSED;
    80002064:	00399793          	slli	a5,s3,0x3
    80002068:	97ce                	add	a5,a5,s3
    8000206a:	078a                	slli	a5,a5,0x2
    8000206c:	97d6                	add	a5,a5,s5
    8000206e:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	cde080e7          	jalr	-802(ra) # 80000d52 <release>
    release(&wait_lock);
    8000207c:	0000f517          	auipc	a0,0xf
    80002080:	0dc50513          	addi	a0,a0,220 # 80011158 <wait_lock>
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	cce080e7          	jalr	-818(ra) # 80000d52 <release>
    if (localCount < count)
    8000208c:	0179f963          	bgeu	s3,s7,8000209e <ps+0xd6>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80002090:	00399793          	slli	a5,s3,0x3
    80002094:	97ce                	add	a5,a5,s3
    80002096:	078a                	slli	a5,a5,0x2
    80002098:	97d6                	add	a5,a5,s5
    8000209a:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    8000209e:	895a                	mv	s2,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	b72080e7          	jalr	-1166(ra) # 80001c12 <myproc>
    800020a8:	86d2                	mv	a3,s4
    800020aa:	8656                	mv	a2,s5
    800020ac:	85da                	mv	a1,s6
    800020ae:	6928                	ld	a0,80(a0)
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	724080e7          	jalr	1828(ra) # 800017d4 <copyout>
}
    800020b8:	854a                	mv	a0,s2
    800020ba:	fb040113          	addi	sp,s0,-80
    800020be:	60a6                	ld	ra,72(sp)
    800020c0:	6406                	ld	s0,64(sp)
    800020c2:	74e2                	ld	s1,56(sp)
    800020c4:	7942                	ld	s2,48(sp)
    800020c6:	79a2                	ld	s3,40(sp)
    800020c8:	7a02                	ld	s4,32(sp)
    800020ca:	6ae2                	ld	s5,24(sp)
    800020cc:	6b42                	ld	s6,16(sp)
    800020ce:	6ba2                	ld	s7,8(sp)
    800020d0:	6c02                	ld	s8,0(sp)
    800020d2:	6161                	addi	sp,sp,80
    800020d4:	8082                	ret
        release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	c7a080e7          	jalr	-902(ra) # 80000d52 <release>
        localCount++;
    800020e0:	2985                	addiw	s3,s3,1
    800020e2:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    800020e6:	16848493          	addi	s1,s1,360
    800020ea:	f984f9e3          	bgeu	s1,s8,8000207c <ps+0xb4>
        if (localCount == count)
    800020ee:	02490913          	addi	s2,s2,36
    800020f2:	053b8d63          	beq	s7,s3,8000214c <ps+0x184>
        acquire(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ba6080e7          	jalr	-1114(ra) # 80000c9e <acquire>
        if (p->state == UNUSED)
    80002100:	4c9c                	lw	a5,24(s1)
    80002102:	d3ad                	beqz	a5,80002064 <ps+0x9c>
        loc_result[localCount].state = p->state;
    80002104:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002108:	549c                	lw	a5,40(s1)
    8000210a:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    8000210e:	54dc                	lw	a5,44(s1)
    80002110:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002114:	589c                	lw	a5,48(s1)
    80002116:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    8000211a:	4641                	li	a2,16
    8000211c:	85ca                	mv	a1,s2
    8000211e:	15848513          	addi	a0,s1,344
    80002122:	00000097          	auipc	ra,0x0
    80002126:	a96080e7          	jalr	-1386(ra) # 80001bb8 <copy_array>
        if (p->parent != 0) // init
    8000212a:	7c88                	ld	a0,56(s1)
    8000212c:	d54d                	beqz	a0,800020d6 <ps+0x10e>
            acquire(&p->parent->lock);
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b70080e7          	jalr	-1168(ra) # 80000c9e <acquire>
            loc_result[localCount].parent_id = p->parent->pid;
    80002136:	7c88                	ld	a0,56(s1)
    80002138:	591c                	lw	a5,48(a0)
    8000213a:	fef92e23          	sw	a5,-4(s2)
            release(&p->parent->lock);
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	c14080e7          	jalr	-1004(ra) # 80000d52 <release>
    80002146:	bf41                	j	800020d6 <ps+0x10e>
        return result;
    80002148:	4901                	li	s2,0
    8000214a:	b7bd                	j	800020b8 <ps+0xf0>
    release(&wait_lock);
    8000214c:	0000f517          	auipc	a0,0xf
    80002150:	00c50513          	addi	a0,a0,12 # 80011158 <wait_lock>
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	bfe080e7          	jalr	-1026(ra) # 80000d52 <release>
    if (localCount < count)
    8000215c:	b789                	j	8000209e <ps+0xd6>

000000008000215e <fork>:
{
    8000215e:	7139                	addi	sp,sp,-64
    80002160:	fc06                	sd	ra,56(sp)
    80002162:	f822                	sd	s0,48(sp)
    80002164:	f426                	sd	s1,40(sp)
    80002166:	f04a                	sd	s2,32(sp)
    80002168:	ec4e                	sd	s3,24(sp)
    8000216a:	e852                	sd	s4,16(sp)
    8000216c:	e456                	sd	s5,8(sp)
    8000216e:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002170:	00000097          	auipc	ra,0x0
    80002174:	aa2080e7          	jalr	-1374(ra) # 80001c12 <myproc>
    80002178:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	ca2080e7          	jalr	-862(ra) # 80001e1c <allocproc>
    80002182:	10050c63          	beqz	a0,8000229a <fork+0x13c>
    80002186:	8a2a                	mv	s4,a0
    if (uvmcow(p->pagetable, np->pagetable, p->sz) < 0) // Task, change from uvmcopy
    80002188:	048ab603          	ld	a2,72(s5)
    8000218c:	692c                	ld	a1,80(a0)
    8000218e:	050ab503          	ld	a0,80(s5)
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	570080e7          	jalr	1392(ra) # 80001702 <uvmcow>
    8000219a:	04054863          	bltz	a0,800021ea <fork+0x8c>
    np->sz = p->sz;
    8000219e:	048ab783          	ld	a5,72(s5)
    800021a2:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800021a6:	058ab683          	ld	a3,88(s5)
    800021aa:	87b6                	mv	a5,a3
    800021ac:	058a3703          	ld	a4,88(s4)
    800021b0:	12068693          	addi	a3,a3,288
    800021b4:	0007b803          	ld	a6,0(a5)
    800021b8:	6788                	ld	a0,8(a5)
    800021ba:	6b8c                	ld	a1,16(a5)
    800021bc:	6f90                	ld	a2,24(a5)
    800021be:	01073023          	sd	a6,0(a4)
    800021c2:	e708                	sd	a0,8(a4)
    800021c4:	eb0c                	sd	a1,16(a4)
    800021c6:	ef10                	sd	a2,24(a4)
    800021c8:	02078793          	addi	a5,a5,32
    800021cc:	02070713          	addi	a4,a4,32
    800021d0:	fed792e3          	bne	a5,a3,800021b4 <fork+0x56>
    np->trapframe->a0 = 0;
    800021d4:	058a3783          	ld	a5,88(s4)
    800021d8:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800021dc:	0d0a8493          	addi	s1,s5,208
    800021e0:	0d0a0913          	addi	s2,s4,208
    800021e4:	150a8993          	addi	s3,s5,336
    800021e8:	a00d                	j	8000220a <fork+0xac>
        freeproc(np);
    800021ea:	8552                	mv	a0,s4
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	bd8080e7          	jalr	-1064(ra) # 80001dc4 <freeproc>
        release(&np->lock);
    800021f4:	8552                	mv	a0,s4
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	b5c080e7          	jalr	-1188(ra) # 80000d52 <release>
        return -1;
    800021fe:	597d                	li	s2,-1
    80002200:	a059                	j	80002286 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002202:	04a1                	addi	s1,s1,8
    80002204:	0921                	addi	s2,s2,8
    80002206:	01348b63          	beq	s1,s3,8000221c <fork+0xbe>
        if (p->ofile[i])
    8000220a:	6088                	ld	a0,0(s1)
    8000220c:	d97d                	beqz	a0,80002202 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    8000220e:	00003097          	auipc	ra,0x3
    80002212:	90a080e7          	jalr	-1782(ra) # 80004b18 <filedup>
    80002216:	00a93023          	sd	a0,0(s2)
    8000221a:	b7e5                	j	80002202 <fork+0xa4>
    np->cwd = idup(p->cwd);
    8000221c:	150ab503          	ld	a0,336(s5)
    80002220:	00002097          	auipc	ra,0x2
    80002224:	a78080e7          	jalr	-1416(ra) # 80003c98 <idup>
    80002228:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000222c:	4641                	li	a2,16
    8000222e:	158a8593          	addi	a1,s5,344
    80002232:	158a0513          	addi	a0,s4,344
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	cae080e7          	jalr	-850(ra) # 80000ee4 <safestrcpy>
    pid = np->pid;
    8000223e:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002242:	8552                	mv	a0,s4
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	b0e080e7          	jalr	-1266(ra) # 80000d52 <release>
    acquire(&wait_lock);
    8000224c:	0000f497          	auipc	s1,0xf
    80002250:	f0c48493          	addi	s1,s1,-244 # 80011158 <wait_lock>
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	a48080e7          	jalr	-1464(ra) # 80000c9e <acquire>
    np->parent = p;
    8000225e:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	aee080e7          	jalr	-1298(ra) # 80000d52 <release>
    acquire(&np->lock);
    8000226c:	8552                	mv	a0,s4
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	a30080e7          	jalr	-1488(ra) # 80000c9e <acquire>
    np->state = RUNNABLE;
    80002276:	478d                	li	a5,3
    80002278:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    8000227c:	8552                	mv	a0,s4
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	ad4080e7          	jalr	-1324(ra) # 80000d52 <release>
}
    80002286:	854a                	mv	a0,s2
    80002288:	70e2                	ld	ra,56(sp)
    8000228a:	7442                	ld	s0,48(sp)
    8000228c:	74a2                	ld	s1,40(sp)
    8000228e:	7902                	ld	s2,32(sp)
    80002290:	69e2                	ld	s3,24(sp)
    80002292:	6a42                	ld	s4,16(sp)
    80002294:	6aa2                	ld	s5,8(sp)
    80002296:	6121                	addi	sp,sp,64
    80002298:	8082                	ret
        return -1;
    8000229a:	597d                	li	s2,-1
    8000229c:	b7ed                	j	80002286 <fork+0x128>

000000008000229e <scheduler>:
{
    8000229e:	1101                	addi	sp,sp,-32
    800022a0:	ec06                	sd	ra,24(sp)
    800022a2:	e822                	sd	s0,16(sp)
    800022a4:	e426                	sd	s1,8(sp)
    800022a6:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800022a8:	00006497          	auipc	s1,0x6
    800022ac:	75048493          	addi	s1,s1,1872 # 800089f8 <sched_pointer>
    800022b0:	609c                	ld	a5,0(s1)
    800022b2:	9782                	jalr	a5
    while (1)
    800022b4:	bff5                	j	800022b0 <scheduler+0x12>

00000000800022b6 <sched>:
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	94e080e7          	jalr	-1714(ra) # 80001c12 <myproc>
    800022cc:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	956080e7          	jalr	-1706(ra) # 80000c24 <holding>
    800022d6:	c53d                	beqz	a0,80002344 <sched+0x8e>
    800022d8:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800022da:	2781                	sext.w	a5,a5
    800022dc:	079e                	slli	a5,a5,0x7
    800022de:	0000f717          	auipc	a4,0xf
    800022e2:	a6270713          	addi	a4,a4,-1438 # 80010d40 <cpus>
    800022e6:	97ba                	add	a5,a5,a4
    800022e8:	5fb8                	lw	a4,120(a5)
    800022ea:	4785                	li	a5,1
    800022ec:	06f71463          	bne	a4,a5,80002354 <sched+0x9e>
    if (p->state == RUNNING)
    800022f0:	4c98                	lw	a4,24(s1)
    800022f2:	4791                	li	a5,4
    800022f4:	06f70863          	beq	a4,a5,80002364 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022f8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022fc:	8b89                	andi	a5,a5,2
    if (intr_get())
    800022fe:	ebbd                	bnez	a5,80002374 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002300:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002302:	0000f917          	auipc	s2,0xf
    80002306:	a3e90913          	addi	s2,s2,-1474 # 80010d40 <cpus>
    8000230a:	2781                	sext.w	a5,a5
    8000230c:	079e                	slli	a5,a5,0x7
    8000230e:	97ca                	add	a5,a5,s2
    80002310:	07c7a983          	lw	s3,124(a5)
    80002314:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002316:	2581                	sext.w	a1,a1
    80002318:	059e                	slli	a1,a1,0x7
    8000231a:	05a1                	addi	a1,a1,8
    8000231c:	95ca                	add	a1,a1,s2
    8000231e:	06048513          	addi	a0,s1,96
    80002322:	00000097          	auipc	ra,0x0
    80002326:	6e4080e7          	jalr	1764(ra) # 80002a06 <swtch>
    8000232a:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000232c:	2781                	sext.w	a5,a5
    8000232e:	079e                	slli	a5,a5,0x7
    80002330:	993e                	add	s2,s2,a5
    80002332:	07392e23          	sw	s3,124(s2)
}
    80002336:	70a2                	ld	ra,40(sp)
    80002338:	7402                	ld	s0,32(sp)
    8000233a:	64e2                	ld	s1,24(sp)
    8000233c:	6942                	ld	s2,16(sp)
    8000233e:	69a2                	ld	s3,8(sp)
    80002340:	6145                	addi	sp,sp,48
    80002342:	8082                	ret
        panic("sched p->lock");
    80002344:	00006517          	auipc	a0,0x6
    80002348:	f5450513          	addi	a0,a0,-172 # 80008298 <digits+0x248>
    8000234c:	ffffe097          	auipc	ra,0xffffe
    80002350:	1f4080e7          	jalr	500(ra) # 80000540 <panic>
        panic("sched locks");
    80002354:	00006517          	auipc	a0,0x6
    80002358:	f5450513          	addi	a0,a0,-172 # 800082a8 <digits+0x258>
    8000235c:	ffffe097          	auipc	ra,0xffffe
    80002360:	1e4080e7          	jalr	484(ra) # 80000540 <panic>
        panic("sched running");
    80002364:	00006517          	auipc	a0,0x6
    80002368:	f5450513          	addi	a0,a0,-172 # 800082b8 <digits+0x268>
    8000236c:	ffffe097          	auipc	ra,0xffffe
    80002370:	1d4080e7          	jalr	468(ra) # 80000540 <panic>
        panic("sched interruptible");
    80002374:	00006517          	auipc	a0,0x6
    80002378:	f5450513          	addi	a0,a0,-172 # 800082c8 <digits+0x278>
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	1c4080e7          	jalr	452(ra) # 80000540 <panic>

0000000080002384 <yield>:
{
    80002384:	1101                	addi	sp,sp,-32
    80002386:	ec06                	sd	ra,24(sp)
    80002388:	e822                	sd	s0,16(sp)
    8000238a:	e426                	sd	s1,8(sp)
    8000238c:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    8000238e:	00000097          	auipc	ra,0x0
    80002392:	884080e7          	jalr	-1916(ra) # 80001c12 <myproc>
    80002396:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	906080e7          	jalr	-1786(ra) # 80000c9e <acquire>
    p->state = RUNNABLE;
    800023a0:	478d                	li	a5,3
    800023a2:	cc9c                	sw	a5,24(s1)
    sched();
    800023a4:	00000097          	auipc	ra,0x0
    800023a8:	f12080e7          	jalr	-238(ra) # 800022b6 <sched>
    release(&p->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	9a4080e7          	jalr	-1628(ra) # 80000d52 <release>
}
    800023b6:	60e2                	ld	ra,24(sp)
    800023b8:	6442                	ld	s0,16(sp)
    800023ba:	64a2                	ld	s1,8(sp)
    800023bc:	6105                	addi	sp,sp,32
    800023be:	8082                	ret

00000000800023c0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023c0:	7179                	addi	sp,sp,-48
    800023c2:	f406                	sd	ra,40(sp)
    800023c4:	f022                	sd	s0,32(sp)
    800023c6:	ec26                	sd	s1,24(sp)
    800023c8:	e84a                	sd	s2,16(sp)
    800023ca:	e44e                	sd	s3,8(sp)
    800023cc:	1800                	addi	s0,sp,48
    800023ce:	89aa                	mv	s3,a0
    800023d0:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800023d2:	00000097          	auipc	ra,0x0
    800023d6:	840080e7          	jalr	-1984(ra) # 80001c12 <myproc>
    800023da:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8c2080e7          	jalr	-1854(ra) # 80000c9e <acquire>
    release(lk);
    800023e4:	854a                	mv	a0,s2
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	96c080e7          	jalr	-1684(ra) # 80000d52 <release>

    // Go to sleep.
    p->chan = chan;
    800023ee:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800023f2:	4789                	li	a5,2
    800023f4:	cc9c                	sw	a5,24(s1)

    sched();
    800023f6:	00000097          	auipc	ra,0x0
    800023fa:	ec0080e7          	jalr	-320(ra) # 800022b6 <sched>

    // Tidy up.
    p->chan = 0;
    800023fe:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	94e080e7          	jalr	-1714(ra) # 80000d52 <release>
    acquire(lk);
    8000240c:	854a                	mv	a0,s2
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	890080e7          	jalr	-1904(ra) # 80000c9e <acquire>
}
    80002416:	70a2                	ld	ra,40(sp)
    80002418:	7402                	ld	s0,32(sp)
    8000241a:	64e2                	ld	s1,24(sp)
    8000241c:	6942                	ld	s2,16(sp)
    8000241e:	69a2                	ld	s3,8(sp)
    80002420:	6145                	addi	sp,sp,48
    80002422:	8082                	ret

0000000080002424 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002424:	7139                	addi	sp,sp,-64
    80002426:	fc06                	sd	ra,56(sp)
    80002428:	f822                	sd	s0,48(sp)
    8000242a:	f426                	sd	s1,40(sp)
    8000242c:	f04a                	sd	s2,32(sp)
    8000242e:	ec4e                	sd	s3,24(sp)
    80002430:	e852                	sd	s4,16(sp)
    80002432:	e456                	sd	s5,8(sp)
    80002434:	0080                	addi	s0,sp,64
    80002436:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002438:	0000f497          	auipc	s1,0xf
    8000243c:	d3848493          	addi	s1,s1,-712 # 80011170 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002440:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002442:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002444:	00014917          	auipc	s2,0x14
    80002448:	72c90913          	addi	s2,s2,1836 # 80016b70 <tickslock>
    8000244c:	a811                	j	80002460 <wakeup+0x3c>
            }
            release(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	902080e7          	jalr	-1790(ra) # 80000d52 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002458:	16848493          	addi	s1,s1,360
    8000245c:	03248663          	beq	s1,s2,80002488 <wakeup+0x64>
        if (p != myproc())
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	7b2080e7          	jalr	1970(ra) # 80001c12 <myproc>
    80002468:	fea488e3          	beq	s1,a0,80002458 <wakeup+0x34>
            acquire(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	830080e7          	jalr	-2000(ra) # 80000c9e <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002476:	4c9c                	lw	a5,24(s1)
    80002478:	fd379be3          	bne	a5,s3,8000244e <wakeup+0x2a>
    8000247c:	709c                	ld	a5,32(s1)
    8000247e:	fd4798e3          	bne	a5,s4,8000244e <wakeup+0x2a>
                p->state = RUNNABLE;
    80002482:	0154ac23          	sw	s5,24(s1)
    80002486:	b7e1                	j	8000244e <wakeup+0x2a>
        }
    }
}
    80002488:	70e2                	ld	ra,56(sp)
    8000248a:	7442                	ld	s0,48(sp)
    8000248c:	74a2                	ld	s1,40(sp)
    8000248e:	7902                	ld	s2,32(sp)
    80002490:	69e2                	ld	s3,24(sp)
    80002492:	6a42                	ld	s4,16(sp)
    80002494:	6aa2                	ld	s5,8(sp)
    80002496:	6121                	addi	sp,sp,64
    80002498:	8082                	ret

000000008000249a <reparent>:
{
    8000249a:	7179                	addi	sp,sp,-48
    8000249c:	f406                	sd	ra,40(sp)
    8000249e:	f022                	sd	s0,32(sp)
    800024a0:	ec26                	sd	s1,24(sp)
    800024a2:	e84a                	sd	s2,16(sp)
    800024a4:	e44e                	sd	s3,8(sp)
    800024a6:	e052                	sd	s4,0(sp)
    800024a8:	1800                	addi	s0,sp,48
    800024aa:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024ac:	0000f497          	auipc	s1,0xf
    800024b0:	cc448493          	addi	s1,s1,-828 # 80011170 <proc>
            pp->parent = initproc;
    800024b4:	00006a17          	auipc	s4,0x6
    800024b8:	614a0a13          	addi	s4,s4,1556 # 80008ac8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024bc:	00014997          	auipc	s3,0x14
    800024c0:	6b498993          	addi	s3,s3,1716 # 80016b70 <tickslock>
    800024c4:	a029                	j	800024ce <reparent+0x34>
    800024c6:	16848493          	addi	s1,s1,360
    800024ca:	01348d63          	beq	s1,s3,800024e4 <reparent+0x4a>
        if (pp->parent == p)
    800024ce:	7c9c                	ld	a5,56(s1)
    800024d0:	ff279be3          	bne	a5,s2,800024c6 <reparent+0x2c>
            pp->parent = initproc;
    800024d4:	000a3503          	ld	a0,0(s4)
    800024d8:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800024da:	00000097          	auipc	ra,0x0
    800024de:	f4a080e7          	jalr	-182(ra) # 80002424 <wakeup>
    800024e2:	b7d5                	j	800024c6 <reparent+0x2c>
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret

00000000800024f4 <exit>:
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	70c080e7          	jalr	1804(ra) # 80001c12 <myproc>
    8000250e:	89aa                	mv	s3,a0
    if (p == initproc)
    80002510:	00006797          	auipc	a5,0x6
    80002514:	5b87b783          	ld	a5,1464(a5) # 80008ac8 <initproc>
    80002518:	0d050493          	addi	s1,a0,208
    8000251c:	15050913          	addi	s2,a0,336
    80002520:	02a79363          	bne	a5,a0,80002546 <exit+0x52>
        panic("init exiting");
    80002524:	00006517          	auipc	a0,0x6
    80002528:	dbc50513          	addi	a0,a0,-580 # 800082e0 <digits+0x290>
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	014080e7          	jalr	20(ra) # 80000540 <panic>
            fileclose(f);
    80002534:	00002097          	auipc	ra,0x2
    80002538:	636080e7          	jalr	1590(ra) # 80004b6a <fileclose>
            p->ofile[fd] = 0;
    8000253c:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002540:	04a1                	addi	s1,s1,8
    80002542:	01248563          	beq	s1,s2,8000254c <exit+0x58>
        if (p->ofile[fd])
    80002546:	6088                	ld	a0,0(s1)
    80002548:	f575                	bnez	a0,80002534 <exit+0x40>
    8000254a:	bfdd                	j	80002540 <exit+0x4c>
    begin_op();
    8000254c:	00002097          	auipc	ra,0x2
    80002550:	156080e7          	jalr	342(ra) # 800046a2 <begin_op>
    iput(p->cwd);
    80002554:	1509b503          	ld	a0,336(s3)
    80002558:	00002097          	auipc	ra,0x2
    8000255c:	938080e7          	jalr	-1736(ra) # 80003e90 <iput>
    end_op();
    80002560:	00002097          	auipc	ra,0x2
    80002564:	1c0080e7          	jalr	448(ra) # 80004720 <end_op>
    p->cwd = 0;
    80002568:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    8000256c:	0000f497          	auipc	s1,0xf
    80002570:	bec48493          	addi	s1,s1,-1044 # 80011158 <wait_lock>
    80002574:	8526                	mv	a0,s1
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	728080e7          	jalr	1832(ra) # 80000c9e <acquire>
    reparent(p);
    8000257e:	854e                	mv	a0,s3
    80002580:	00000097          	auipc	ra,0x0
    80002584:	f1a080e7          	jalr	-230(ra) # 8000249a <reparent>
    wakeup(p->parent);
    80002588:	0389b503          	ld	a0,56(s3)
    8000258c:	00000097          	auipc	ra,0x0
    80002590:	e98080e7          	jalr	-360(ra) # 80002424 <wakeup>
    acquire(&p->lock);
    80002594:	854e                	mv	a0,s3
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	708080e7          	jalr	1800(ra) # 80000c9e <acquire>
    p->xstate = status;
    8000259e:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800025a2:	4795                	li	a5,5
    800025a4:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800025a8:	8526                	mv	a0,s1
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	7a8080e7          	jalr	1960(ra) # 80000d52 <release>
    sched();
    800025b2:	00000097          	auipc	ra,0x0
    800025b6:	d04080e7          	jalr	-764(ra) # 800022b6 <sched>
    panic("zombie exit");
    800025ba:	00006517          	auipc	a0,0x6
    800025be:	d3650513          	addi	a0,a0,-714 # 800082f0 <digits+0x2a0>
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	f7e080e7          	jalr	-130(ra) # 80000540 <panic>

00000000800025ca <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025ca:	7179                	addi	sp,sp,-48
    800025cc:	f406                	sd	ra,40(sp)
    800025ce:	f022                	sd	s0,32(sp)
    800025d0:	ec26                	sd	s1,24(sp)
    800025d2:	e84a                	sd	s2,16(sp)
    800025d4:	e44e                	sd	s3,8(sp)
    800025d6:	1800                	addi	s0,sp,48
    800025d8:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800025da:	0000f497          	auipc	s1,0xf
    800025de:	b9648493          	addi	s1,s1,-1130 # 80011170 <proc>
    800025e2:	00014997          	auipc	s3,0x14
    800025e6:	58e98993          	addi	s3,s3,1422 # 80016b70 <tickslock>
    {
        acquire(&p->lock);
    800025ea:	8526                	mv	a0,s1
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	6b2080e7          	jalr	1714(ra) # 80000c9e <acquire>
        if (p->pid == pid)
    800025f4:	589c                	lw	a5,48(s1)
    800025f6:	01278d63          	beq	a5,s2,80002610 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800025fa:	8526                	mv	a0,s1
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	756080e7          	jalr	1878(ra) # 80000d52 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002604:	16848493          	addi	s1,s1,360
    80002608:	ff3491e3          	bne	s1,s3,800025ea <kill+0x20>
    }
    return -1;
    8000260c:	557d                	li	a0,-1
    8000260e:	a829                	j	80002628 <kill+0x5e>
            p->killed = 1;
    80002610:	4785                	li	a5,1
    80002612:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002614:	4c98                	lw	a4,24(s1)
    80002616:	4789                	li	a5,2
    80002618:	00f70f63          	beq	a4,a5,80002636 <kill+0x6c>
            release(&p->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	734080e7          	jalr	1844(ra) # 80000d52 <release>
            return 0;
    80002626:	4501                	li	a0,0
}
    80002628:	70a2                	ld	ra,40(sp)
    8000262a:	7402                	ld	s0,32(sp)
    8000262c:	64e2                	ld	s1,24(sp)
    8000262e:	6942                	ld	s2,16(sp)
    80002630:	69a2                	ld	s3,8(sp)
    80002632:	6145                	addi	sp,sp,48
    80002634:	8082                	ret
                p->state = RUNNABLE;
    80002636:	478d                	li	a5,3
    80002638:	cc9c                	sw	a5,24(s1)
    8000263a:	b7cd                	j	8000261c <kill+0x52>

000000008000263c <setkilled>:

void setkilled(struct proc *p)
{
    8000263c:	1101                	addi	sp,sp,-32
    8000263e:	ec06                	sd	ra,24(sp)
    80002640:	e822                	sd	s0,16(sp)
    80002642:	e426                	sd	s1,8(sp)
    80002644:	1000                	addi	s0,sp,32
    80002646:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	656080e7          	jalr	1622(ra) # 80000c9e <acquire>
    p->killed = 1;
    80002650:	4785                	li	a5,1
    80002652:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	6fc080e7          	jalr	1788(ra) # 80000d52 <release>
}
    8000265e:	60e2                	ld	ra,24(sp)
    80002660:	6442                	ld	s0,16(sp)
    80002662:	64a2                	ld	s1,8(sp)
    80002664:	6105                	addi	sp,sp,32
    80002666:	8082                	ret

0000000080002668 <killed>:

int killed(struct proc *p)
{
    80002668:	1101                	addi	sp,sp,-32
    8000266a:	ec06                	sd	ra,24(sp)
    8000266c:	e822                	sd	s0,16(sp)
    8000266e:	e426                	sd	s1,8(sp)
    80002670:	e04a                	sd	s2,0(sp)
    80002672:	1000                	addi	s0,sp,32
    80002674:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	628080e7          	jalr	1576(ra) # 80000c9e <acquire>
    k = p->killed;
    8000267e:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002682:	8526                	mv	a0,s1
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	6ce080e7          	jalr	1742(ra) # 80000d52 <release>
    return k;
}
    8000268c:	854a                	mv	a0,s2
    8000268e:	60e2                	ld	ra,24(sp)
    80002690:	6442                	ld	s0,16(sp)
    80002692:	64a2                	ld	s1,8(sp)
    80002694:	6902                	ld	s2,0(sp)
    80002696:	6105                	addi	sp,sp,32
    80002698:	8082                	ret

000000008000269a <wait>:
{
    8000269a:	715d                	addi	sp,sp,-80
    8000269c:	e486                	sd	ra,72(sp)
    8000269e:	e0a2                	sd	s0,64(sp)
    800026a0:	fc26                	sd	s1,56(sp)
    800026a2:	f84a                	sd	s2,48(sp)
    800026a4:	f44e                	sd	s3,40(sp)
    800026a6:	f052                	sd	s4,32(sp)
    800026a8:	ec56                	sd	s5,24(sp)
    800026aa:	e85a                	sd	s6,16(sp)
    800026ac:	e45e                	sd	s7,8(sp)
    800026ae:	e062                	sd	s8,0(sp)
    800026b0:	0880                	addi	s0,sp,80
    800026b2:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800026b4:	fffff097          	auipc	ra,0xfffff
    800026b8:	55e080e7          	jalr	1374(ra) # 80001c12 <myproc>
    800026bc:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800026be:	0000f517          	auipc	a0,0xf
    800026c2:	a9a50513          	addi	a0,a0,-1382 # 80011158 <wait_lock>
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	5d8080e7          	jalr	1496(ra) # 80000c9e <acquire>
        havekids = 0;
    800026ce:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800026d0:	4a15                	li	s4,5
                havekids = 1;
    800026d2:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026d4:	00014997          	auipc	s3,0x14
    800026d8:	49c98993          	addi	s3,s3,1180 # 80016b70 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026dc:	0000fc17          	auipc	s8,0xf
    800026e0:	a7cc0c13          	addi	s8,s8,-1412 # 80011158 <wait_lock>
        havekids = 0;
    800026e4:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026e6:	0000f497          	auipc	s1,0xf
    800026ea:	a8a48493          	addi	s1,s1,-1398 # 80011170 <proc>
    800026ee:	a0bd                	j	8000275c <wait+0xc2>
                    pid = pp->pid;
    800026f0:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026f4:	000b0e63          	beqz	s6,80002710 <wait+0x76>
    800026f8:	4691                	li	a3,4
    800026fa:	02c48613          	addi	a2,s1,44
    800026fe:	85da                	mv	a1,s6
    80002700:	05093503          	ld	a0,80(s2)
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	0d0080e7          	jalr	208(ra) # 800017d4 <copyout>
    8000270c:	02054563          	bltz	a0,80002736 <wait+0x9c>
                    freeproc(pp);
    80002710:	8526                	mv	a0,s1
    80002712:	fffff097          	auipc	ra,0xfffff
    80002716:	6b2080e7          	jalr	1714(ra) # 80001dc4 <freeproc>
                    release(&pp->lock);
    8000271a:	8526                	mv	a0,s1
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	636080e7          	jalr	1590(ra) # 80000d52 <release>
                    release(&wait_lock);
    80002724:	0000f517          	auipc	a0,0xf
    80002728:	a3450513          	addi	a0,a0,-1484 # 80011158 <wait_lock>
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	626080e7          	jalr	1574(ra) # 80000d52 <release>
                    return pid;
    80002734:	a0b5                	j	800027a0 <wait+0x106>
                        release(&pp->lock);
    80002736:	8526                	mv	a0,s1
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	61a080e7          	jalr	1562(ra) # 80000d52 <release>
                        release(&wait_lock);
    80002740:	0000f517          	auipc	a0,0xf
    80002744:	a1850513          	addi	a0,a0,-1512 # 80011158 <wait_lock>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	60a080e7          	jalr	1546(ra) # 80000d52 <release>
                        return -1;
    80002750:	59fd                	li	s3,-1
    80002752:	a0b9                	j	800027a0 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002754:	16848493          	addi	s1,s1,360
    80002758:	03348463          	beq	s1,s3,80002780 <wait+0xe6>
            if (pp->parent == p)
    8000275c:	7c9c                	ld	a5,56(s1)
    8000275e:	ff279be3          	bne	a5,s2,80002754 <wait+0xba>
                acquire(&pp->lock);
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	53a080e7          	jalr	1338(ra) # 80000c9e <acquire>
                if (pp->state == ZOMBIE)
    8000276c:	4c9c                	lw	a5,24(s1)
    8000276e:	f94781e3          	beq	a5,s4,800026f0 <wait+0x56>
                release(&pp->lock);
    80002772:	8526                	mv	a0,s1
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	5de080e7          	jalr	1502(ra) # 80000d52 <release>
                havekids = 1;
    8000277c:	8756                	mv	a4,s5
    8000277e:	bfd9                	j	80002754 <wait+0xba>
        if (!havekids || killed(p))
    80002780:	c719                	beqz	a4,8000278e <wait+0xf4>
    80002782:	854a                	mv	a0,s2
    80002784:	00000097          	auipc	ra,0x0
    80002788:	ee4080e7          	jalr	-284(ra) # 80002668 <killed>
    8000278c:	c51d                	beqz	a0,800027ba <wait+0x120>
            release(&wait_lock);
    8000278e:	0000f517          	auipc	a0,0xf
    80002792:	9ca50513          	addi	a0,a0,-1590 # 80011158 <wait_lock>
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	5bc080e7          	jalr	1468(ra) # 80000d52 <release>
            return -1;
    8000279e:	59fd                	li	s3,-1
}
    800027a0:	854e                	mv	a0,s3
    800027a2:	60a6                	ld	ra,72(sp)
    800027a4:	6406                	ld	s0,64(sp)
    800027a6:	74e2                	ld	s1,56(sp)
    800027a8:	7942                	ld	s2,48(sp)
    800027aa:	79a2                	ld	s3,40(sp)
    800027ac:	7a02                	ld	s4,32(sp)
    800027ae:	6ae2                	ld	s5,24(sp)
    800027b0:	6b42                	ld	s6,16(sp)
    800027b2:	6ba2                	ld	s7,8(sp)
    800027b4:	6c02                	ld	s8,0(sp)
    800027b6:	6161                	addi	sp,sp,80
    800027b8:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027ba:	85e2                	mv	a1,s8
    800027bc:	854a                	mv	a0,s2
    800027be:	00000097          	auipc	ra,0x0
    800027c2:	c02080e7          	jalr	-1022(ra) # 800023c0 <sleep>
        havekids = 0;
    800027c6:	bf39                	j	800026e4 <wait+0x4a>

00000000800027c8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027c8:	7179                	addi	sp,sp,-48
    800027ca:	f406                	sd	ra,40(sp)
    800027cc:	f022                	sd	s0,32(sp)
    800027ce:	ec26                	sd	s1,24(sp)
    800027d0:	e84a                	sd	s2,16(sp)
    800027d2:	e44e                	sd	s3,8(sp)
    800027d4:	e052                	sd	s4,0(sp)
    800027d6:	1800                	addi	s0,sp,48
    800027d8:	84aa                	mv	s1,a0
    800027da:	892e                	mv	s2,a1
    800027dc:	89b2                	mv	s3,a2
    800027de:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	432080e7          	jalr	1074(ra) # 80001c12 <myproc>
    if (user_dst)
    800027e8:	c08d                	beqz	s1,8000280a <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800027ea:	86d2                	mv	a3,s4
    800027ec:	864e                	mv	a2,s3
    800027ee:	85ca                	mv	a1,s2
    800027f0:	6928                	ld	a0,80(a0)
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	fe2080e7          	jalr	-30(ra) # 800017d4 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    800027fa:	70a2                	ld	ra,40(sp)
    800027fc:	7402                	ld	s0,32(sp)
    800027fe:	64e2                	ld	s1,24(sp)
    80002800:	6942                	ld	s2,16(sp)
    80002802:	69a2                	ld	s3,8(sp)
    80002804:	6a02                	ld	s4,0(sp)
    80002806:	6145                	addi	sp,sp,48
    80002808:	8082                	ret
        memmove((char *)dst, src, len);
    8000280a:	000a061b          	sext.w	a2,s4
    8000280e:	85ce                	mv	a1,s3
    80002810:	854a                	mv	a0,s2
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	5e4080e7          	jalr	1508(ra) # 80000df6 <memmove>
        return 0;
    8000281a:	8526                	mv	a0,s1
    8000281c:	bff9                	j	800027fa <either_copyout+0x32>

000000008000281e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000281e:	7179                	addi	sp,sp,-48
    80002820:	f406                	sd	ra,40(sp)
    80002822:	f022                	sd	s0,32(sp)
    80002824:	ec26                	sd	s1,24(sp)
    80002826:	e84a                	sd	s2,16(sp)
    80002828:	e44e                	sd	s3,8(sp)
    8000282a:	e052                	sd	s4,0(sp)
    8000282c:	1800                	addi	s0,sp,48
    8000282e:	892a                	mv	s2,a0
    80002830:	84ae                	mv	s1,a1
    80002832:	89b2                	mv	s3,a2
    80002834:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002836:	fffff097          	auipc	ra,0xfffff
    8000283a:	3dc080e7          	jalr	988(ra) # 80001c12 <myproc>
    if (user_src)
    8000283e:	c08d                	beqz	s1,80002860 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002840:	86d2                	mv	a3,s4
    80002842:	864e                	mv	a2,s3
    80002844:	85ca                	mv	a1,s2
    80002846:	6928                	ld	a0,80(a0)
    80002848:	fffff097          	auipc	ra,0xfffff
    8000284c:	018080e7          	jalr	24(ra) # 80001860 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002850:	70a2                	ld	ra,40(sp)
    80002852:	7402                	ld	s0,32(sp)
    80002854:	64e2                	ld	s1,24(sp)
    80002856:	6942                	ld	s2,16(sp)
    80002858:	69a2                	ld	s3,8(sp)
    8000285a:	6a02                	ld	s4,0(sp)
    8000285c:	6145                	addi	sp,sp,48
    8000285e:	8082                	ret
        memmove(dst, (char *)src, len);
    80002860:	000a061b          	sext.w	a2,s4
    80002864:	85ce                	mv	a1,s3
    80002866:	854a                	mv	a0,s2
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	58e080e7          	jalr	1422(ra) # 80000df6 <memmove>
        return 0;
    80002870:	8526                	mv	a0,s1
    80002872:	bff9                	j	80002850 <either_copyin+0x32>

0000000080002874 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002874:	715d                	addi	sp,sp,-80
    80002876:	e486                	sd	ra,72(sp)
    80002878:	e0a2                	sd	s0,64(sp)
    8000287a:	fc26                	sd	s1,56(sp)
    8000287c:	f84a                	sd	s2,48(sp)
    8000287e:	f44e                	sd	s3,40(sp)
    80002880:	f052                	sd	s4,32(sp)
    80002882:	ec56                	sd	s5,24(sp)
    80002884:	e85a                	sd	s6,16(sp)
    80002886:	e45e                	sd	s7,8(sp)
    80002888:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    8000288a:	00005517          	auipc	a0,0x5
    8000288e:	7fe50513          	addi	a0,a0,2046 # 80008088 <digits+0x38>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	d0a080e7          	jalr	-758(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000289a:	0000f497          	auipc	s1,0xf
    8000289e:	a2e48493          	addi	s1,s1,-1490 # 800112c8 <proc+0x158>
    800028a2:	00014917          	auipc	s2,0x14
    800028a6:	42690913          	addi	s2,s2,1062 # 80016cc8 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028aa:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800028ac:	00006997          	auipc	s3,0x6
    800028b0:	a5498993          	addi	s3,s3,-1452 # 80008300 <digits+0x2b0>
        printf("%d <%s %s", p->pid, state, p->name);
    800028b4:	00006a97          	auipc	s5,0x6
    800028b8:	a54a8a93          	addi	s5,s5,-1452 # 80008308 <digits+0x2b8>
        printf("\n");
    800028bc:	00005a17          	auipc	s4,0x5
    800028c0:	7cca0a13          	addi	s4,s4,1996 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c4:	00006b97          	auipc	s7,0x6
    800028c8:	b54b8b93          	addi	s7,s7,-1196 # 80008418 <states.0>
    800028cc:	a00d                	j	800028ee <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800028ce:	ed86a583          	lw	a1,-296(a3)
    800028d2:	8556                	mv	a0,s5
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	cc8080e7          	jalr	-824(ra) # 8000059c <printf>
        printf("\n");
    800028dc:	8552                	mv	a0,s4
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	cbe080e7          	jalr	-834(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028e6:	16848493          	addi	s1,s1,360
    800028ea:	03248263          	beq	s1,s2,8000290e <procdump+0x9a>
        if (p->state == UNUSED)
    800028ee:	86a6                	mv	a3,s1
    800028f0:	ec04a783          	lw	a5,-320(s1)
    800028f4:	dbed                	beqz	a5,800028e6 <procdump+0x72>
            state = "???";
    800028f6:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f8:	fcfb6be3          	bltu	s6,a5,800028ce <procdump+0x5a>
    800028fc:	02079713          	slli	a4,a5,0x20
    80002900:	01d75793          	srli	a5,a4,0x1d
    80002904:	97de                	add	a5,a5,s7
    80002906:	6390                	ld	a2,0(a5)
    80002908:	f279                	bnez	a2,800028ce <procdump+0x5a>
            state = "???";
    8000290a:	864e                	mv	a2,s3
    8000290c:	b7c9                	j	800028ce <procdump+0x5a>
    }
}
    8000290e:	60a6                	ld	ra,72(sp)
    80002910:	6406                	ld	s0,64(sp)
    80002912:	74e2                	ld	s1,56(sp)
    80002914:	7942                	ld	s2,48(sp)
    80002916:	79a2                	ld	s3,40(sp)
    80002918:	7a02                	ld	s4,32(sp)
    8000291a:	6ae2                	ld	s5,24(sp)
    8000291c:	6b42                	ld	s6,16(sp)
    8000291e:	6ba2                	ld	s7,8(sp)
    80002920:	6161                	addi	sp,sp,80
    80002922:	8082                	ret

0000000080002924 <schedls>:

void schedls()
{
    80002924:	1141                	addi	sp,sp,-16
    80002926:	e406                	sd	ra,8(sp)
    80002928:	e022                	sd	s0,0(sp)
    8000292a:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	9ec50513          	addi	a0,a0,-1556 # 80008318 <digits+0x2c8>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	c68080e7          	jalr	-920(ra) # 8000059c <printf>
    printf("====================================\n");
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	a0450513          	addi	a0,a0,-1532 # 80008340 <digits+0x2f0>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c58080e7          	jalr	-936(ra) # 8000059c <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    8000294c:	00006717          	auipc	a4,0x6
    80002950:	10c73703          	ld	a4,268(a4) # 80008a58 <available_schedulers+0x10>
    80002954:	00006797          	auipc	a5,0x6
    80002958:	0a47b783          	ld	a5,164(a5) # 800089f8 <sched_pointer>
    8000295c:	04f70663          	beq	a4,a5,800029a8 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a1050513          	addi	a0,a0,-1520 # 80008370 <digits+0x320>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c34080e7          	jalr	-972(ra) # 8000059c <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002970:	00006617          	auipc	a2,0x6
    80002974:	0f062603          	lw	a2,240(a2) # 80008a60 <available_schedulers+0x18>
    80002978:	00006597          	auipc	a1,0x6
    8000297c:	0d058593          	addi	a1,a1,208 # 80008a48 <available_schedulers>
    80002980:	00006517          	auipc	a0,0x6
    80002984:	9f850513          	addi	a0,a0,-1544 # 80008378 <digits+0x328>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	c14080e7          	jalr	-1004(ra) # 8000059c <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002990:	00006517          	auipc	a0,0x6
    80002994:	9f050513          	addi	a0,a0,-1552 # 80008380 <digits+0x330>
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	c04080e7          	jalr	-1020(ra) # 8000059c <printf>
}
    800029a0:	60a2                	ld	ra,8(sp)
    800029a2:	6402                	ld	s0,0(sp)
    800029a4:	0141                	addi	sp,sp,16
    800029a6:	8082                	ret
            printf("[*]\t");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	9c050513          	addi	a0,a0,-1600 # 80008368 <digits+0x318>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	bec080e7          	jalr	-1044(ra) # 8000059c <printf>
    800029b8:	bf65                	j	80002970 <schedls+0x4c>

00000000800029ba <schedset>:

void schedset(int id)
{
    800029ba:	1141                	addi	sp,sp,-16
    800029bc:	e406                	sd	ra,8(sp)
    800029be:	e022                	sd	s0,0(sp)
    800029c0:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800029c2:	e90d                	bnez	a0,800029f4 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800029c4:	00006797          	auipc	a5,0x6
    800029c8:	0947b783          	ld	a5,148(a5) # 80008a58 <available_schedulers+0x10>
    800029cc:	00006717          	auipc	a4,0x6
    800029d0:	02f73623          	sd	a5,44(a4) # 800089f8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800029d4:	00006597          	auipc	a1,0x6
    800029d8:	07458593          	addi	a1,a1,116 # 80008a48 <available_schedulers>
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	9e450513          	addi	a0,a0,-1564 # 800083c0 <digits+0x370>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	bb8080e7          	jalr	-1096(ra) # 8000059c <printf>
    800029ec:	60a2                	ld	ra,8(sp)
    800029ee:	6402                	ld	s0,0(sp)
    800029f0:	0141                	addi	sp,sp,16
    800029f2:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	9a450513          	addi	a0,a0,-1628 # 80008398 <digits+0x348>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	ba0080e7          	jalr	-1120(ra) # 8000059c <printf>
        return;
    80002a04:	b7e5                	j	800029ec <schedset+0x32>

0000000080002a06 <swtch>:
    80002a06:	00153023          	sd	ra,0(a0)
    80002a0a:	00253423          	sd	sp,8(a0)
    80002a0e:	e900                	sd	s0,16(a0)
    80002a10:	ed04                	sd	s1,24(a0)
    80002a12:	03253023          	sd	s2,32(a0)
    80002a16:	03353423          	sd	s3,40(a0)
    80002a1a:	03453823          	sd	s4,48(a0)
    80002a1e:	03553c23          	sd	s5,56(a0)
    80002a22:	05653023          	sd	s6,64(a0)
    80002a26:	05753423          	sd	s7,72(a0)
    80002a2a:	05853823          	sd	s8,80(a0)
    80002a2e:	05953c23          	sd	s9,88(a0)
    80002a32:	07a53023          	sd	s10,96(a0)
    80002a36:	07b53423          	sd	s11,104(a0)
    80002a3a:	0005b083          	ld	ra,0(a1)
    80002a3e:	0085b103          	ld	sp,8(a1)
    80002a42:	6980                	ld	s0,16(a1)
    80002a44:	6d84                	ld	s1,24(a1)
    80002a46:	0205b903          	ld	s2,32(a1)
    80002a4a:	0285b983          	ld	s3,40(a1)
    80002a4e:	0305ba03          	ld	s4,48(a1)
    80002a52:	0385ba83          	ld	s5,56(a1)
    80002a56:	0405bb03          	ld	s6,64(a1)
    80002a5a:	0485bb83          	ld	s7,72(a1)
    80002a5e:	0505bc03          	ld	s8,80(a1)
    80002a62:	0585bc83          	ld	s9,88(a1)
    80002a66:	0605bd03          	ld	s10,96(a1)
    80002a6a:	0685bd83          	ld	s11,104(a1)
    80002a6e:	8082                	ret

0000000080002a70 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a70:	1141                	addi	sp,sp,-16
    80002a72:	e406                	sd	ra,8(sp)
    80002a74:	e022                	sd	s0,0(sp)
    80002a76:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a78:	00006597          	auipc	a1,0x6
    80002a7c:	9d058593          	addi	a1,a1,-1584 # 80008448 <states.0+0x30>
    80002a80:	00014517          	auipc	a0,0x14
    80002a84:	0f050513          	addi	a0,a0,240 # 80016b70 <tickslock>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	186080e7          	jalr	390(ra) # 80000c0e <initlock>
}
    80002a90:	60a2                	ld	ra,8(sp)
    80002a92:	6402                	ld	s0,0(sp)
    80002a94:	0141                	addi	sp,sp,16
    80002a96:	8082                	ret

0000000080002a98 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a98:	1141                	addi	sp,sp,-16
    80002a9a:	e422                	sd	s0,8(sp)
    80002a9c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a9e:	00003797          	auipc	a5,0x3
    80002aa2:	72278793          	addi	a5,a5,1826 # 800061c0 <kernelvec>
    80002aa6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002aaa:	6422                	ld	s0,8(sp)
    80002aac:	0141                	addi	sp,sp,16
    80002aae:	8082                	ret

0000000080002ab0 <handle_cow>:

// COW handling function
int handle_cow(uint64 faulting_address) {
    80002ab0:	1141                	addi	sp,sp,-16
    80002ab2:	e422                	sd	s0,8(sp)
    80002ab4:	0800                	addi	s0,sp,16
  // 1. Allocate new page
  // 2. Copy contents from old to new
  // 3. Update page table entry
  // Ensure proper synchronization and error handling
  return 0; 
}
    80002ab6:	4501                	li	a0,0
    80002ab8:	6422                	ld	s0,8(sp)
    80002aba:	0141                	addi	sp,sp,16
    80002abc:	8082                	ret

0000000080002abe <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002abe:	1141                	addi	sp,sp,-16
    80002ac0:	e406                	sd	ra,8(sp)
    80002ac2:	e022                	sd	s0,0(sp)
    80002ac4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	14c080e7          	jalr	332(ra) # 80001c12 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ace:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ad2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ad4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ad8:	00004697          	auipc	a3,0x4
    80002adc:	52868693          	addi	a3,a3,1320 # 80007000 <_trampoline>
    80002ae0:	00004717          	auipc	a4,0x4
    80002ae4:	52070713          	addi	a4,a4,1312 # 80007000 <_trampoline>
    80002ae8:	8f15                	sub	a4,a4,a3
    80002aea:	040007b7          	lui	a5,0x4000
    80002aee:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002af0:	07b2                	slli	a5,a5,0xc
    80002af2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af4:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002af8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002afa:	18002673          	csrr	a2,satp
    80002afe:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b00:	6d30                	ld	a2,88(a0)
    80002b02:	6138                	ld	a4,64(a0)
    80002b04:	6585                	lui	a1,0x1
    80002b06:	972e                	add	a4,a4,a1
    80002b08:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b0a:	6d38                	ld	a4,88(a0)
    80002b0c:	00000617          	auipc	a2,0x0
    80002b10:	13060613          	addi	a2,a2,304 # 80002c3c <usertrap>
    80002b14:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b16:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b18:	8612                	mv	a2,tp
    80002b1a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b20:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b24:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b28:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b2c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b2e:	6f18                	ld	a4,24(a4)
    80002b30:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b34:	6928                	ld	a0,80(a0)
    80002b36:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b38:	00004717          	auipc	a4,0x4
    80002b3c:	56470713          	addi	a4,a4,1380 # 8000709c <userret>
    80002b40:	8f15                	sub	a4,a4,a3
    80002b42:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b44:	577d                	li	a4,-1
    80002b46:	177e                	slli	a4,a4,0x3f
    80002b48:	8d59                	or	a0,a0,a4
    80002b4a:	9782                	jalr	a5
}
    80002b4c:	60a2                	ld	ra,8(sp)
    80002b4e:	6402                	ld	s0,0(sp)
    80002b50:	0141                	addi	sp,sp,16
    80002b52:	8082                	ret

0000000080002b54 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b54:	1101                	addi	sp,sp,-32
    80002b56:	ec06                	sd	ra,24(sp)
    80002b58:	e822                	sd	s0,16(sp)
    80002b5a:	e426                	sd	s1,8(sp)
    80002b5c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b5e:	00014497          	auipc	s1,0x14
    80002b62:	01248493          	addi	s1,s1,18 # 80016b70 <tickslock>
    80002b66:	8526                	mv	a0,s1
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	136080e7          	jalr	310(ra) # 80000c9e <acquire>
  ticks++;
    80002b70:	00006517          	auipc	a0,0x6
    80002b74:	f6050513          	addi	a0,a0,-160 # 80008ad0 <ticks>
    80002b78:	411c                	lw	a5,0(a0)
    80002b7a:	2785                	addiw	a5,a5,1
    80002b7c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	8a6080e7          	jalr	-1882(ra) # 80002424 <wakeup>
  release(&tickslock);
    80002b86:	8526                	mv	a0,s1
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	1ca080e7          	jalr	458(ra) # 80000d52 <release>
}
    80002b90:	60e2                	ld	ra,24(sp)
    80002b92:	6442                	ld	s0,16(sp)
    80002b94:	64a2                	ld	s1,8(sp)
    80002b96:	6105                	addi	sp,sp,32
    80002b98:	8082                	ret

0000000080002b9a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b9a:	1101                	addi	sp,sp,-32
    80002b9c:	ec06                	sd	ra,24(sp)
    80002b9e:	e822                	sd	s0,16(sp)
    80002ba0:	e426                	sd	s1,8(sp)
    80002ba2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ba4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ba8:	00074d63          	bltz	a4,80002bc2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002bac:	57fd                	li	a5,-1
    80002bae:	17fe                	slli	a5,a5,0x3f
    80002bb0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bb2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002bb4:	06f70363          	beq	a4,a5,80002c1a <devintr+0x80>
  }
}
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	64a2                	ld	s1,8(sp)
    80002bbe:	6105                	addi	sp,sp,32
    80002bc0:	8082                	ret
     (scause & 0xff) == 9){
    80002bc2:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002bc6:	46a5                	li	a3,9
    80002bc8:	fed792e3          	bne	a5,a3,80002bac <devintr+0x12>
    int irq = plic_claim();
    80002bcc:	00003097          	auipc	ra,0x3
    80002bd0:	6fc080e7          	jalr	1788(ra) # 800062c8 <plic_claim>
    80002bd4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bd6:	47a9                	li	a5,10
    80002bd8:	02f50763          	beq	a0,a5,80002c06 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002bdc:	4785                	li	a5,1
    80002bde:	02f50963          	beq	a0,a5,80002c10 <devintr+0x76>
    return 1;
    80002be2:	4505                	li	a0,1
    } else if(irq){
    80002be4:	d8f1                	beqz	s1,80002bb8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002be6:	85a6                	mv	a1,s1
    80002be8:	00006517          	auipc	a0,0x6
    80002bec:	86850513          	addi	a0,a0,-1944 # 80008450 <states.0+0x38>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	9ac080e7          	jalr	-1620(ra) # 8000059c <printf>
      plic_complete(irq);
    80002bf8:	8526                	mv	a0,s1
    80002bfa:	00003097          	auipc	ra,0x3
    80002bfe:	6f2080e7          	jalr	1778(ra) # 800062ec <plic_complete>
    return 1;
    80002c02:	4505                	li	a0,1
    80002c04:	bf55                	j	80002bb8 <devintr+0x1e>
      uartintr();
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	da4080e7          	jalr	-604(ra) # 800009aa <uartintr>
    80002c0e:	b7ed                	j	80002bf8 <devintr+0x5e>
      virtio_disk_intr();
    80002c10:	00004097          	auipc	ra,0x4
    80002c14:	ba4080e7          	jalr	-1116(ra) # 800067b4 <virtio_disk_intr>
    80002c18:	b7c5                	j	80002bf8 <devintr+0x5e>
    if(cpuid() == 0){
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	fcc080e7          	jalr	-52(ra) # 80001be6 <cpuid>
    80002c22:	c901                	beqz	a0,80002c32 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c24:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c2a:	14479073          	csrw	sip,a5
    return 2;
    80002c2e:	4509                	li	a0,2
    80002c30:	b761                	j	80002bb8 <devintr+0x1e>
      clockintr();
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	f22080e7          	jalr	-222(ra) # 80002b54 <clockintr>
    80002c3a:	b7ed                	j	80002c24 <devintr+0x8a>

0000000080002c3c <usertrap>:
{
    80002c3c:	7139                	addi	sp,sp,-64
    80002c3e:	fc06                	sd	ra,56(sp)
    80002c40:	f822                	sd	s0,48(sp)
    80002c42:	f426                	sd	s1,40(sp)
    80002c44:	f04a                	sd	s2,32(sp)
    80002c46:	ec4e                	sd	s3,24(sp)
    80002c48:	e852                	sd	s4,16(sp)
    80002c4a:	e456                	sd	s5,8(sp)
    80002c4c:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c52:	1007f793          	andi	a5,a5,256
    80002c56:	efb5                	bnez	a5,80002cd2 <usertrap+0x96>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c58:	00003797          	auipc	a5,0x3
    80002c5c:	56878793          	addi	a5,a5,1384 # 800061c0 <kernelvec>
    80002c60:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	fae080e7          	jalr	-82(ra) # 80001c12 <myproc>
    80002c6c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c6e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c70:	14102773          	csrr	a4,sepc
    80002c74:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c76:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c7a:	47a1                	li	a5,8
    80002c7c:	06f70363          	beq	a4,a5,80002ce2 <usertrap+0xa6>
  } else if((which_dev = devintr()) != 0){
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	f1a080e7          	jalr	-230(ra) # 80002b9a <devintr>
    80002c88:	892a                	mv	s2,a0
    80002c8a:	18051d63          	bnez	a0,80002e24 <usertrap+0x1e8>
    80002c8e:	14202773          	csrr	a4,scause
  } else if(r_scause() == 15) { // Check for a page fault due to write attempt
    80002c92:	47bd                	li	a5,15
    80002c94:	0af70463          	beq	a4,a5,80002d3c <usertrap+0x100>
    80002c98:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c9c:	5890                	lw	a2,48(s1)
    80002c9e:	00006517          	auipc	a0,0x6
    80002ca2:	82250513          	addi	a0,a0,-2014 # 800084c0 <states.0+0xa8>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	8f6080e7          	jalr	-1802(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cb2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cb6:	00006517          	auipc	a0,0x6
    80002cba:	83a50513          	addi	a0,a0,-1990 # 800084f0 <states.0+0xd8>
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	8de080e7          	jalr	-1826(ra) # 8000059c <printf>
    setkilled(p);
    80002cc6:	8526                	mv	a0,s1
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	974080e7          	jalr	-1676(ra) # 8000263c <setkilled>
    80002cd0:	a825                	j	80002d08 <usertrap+0xcc>
    panic("usertrap: not from user mode");
    80002cd2:	00005517          	auipc	a0,0x5
    80002cd6:	79e50513          	addi	a0,a0,1950 # 80008470 <states.0+0x58>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	866080e7          	jalr	-1946(ra) # 80000540 <panic>
    if(killed(p))
    80002ce2:	00000097          	auipc	ra,0x0
    80002ce6:	986080e7          	jalr	-1658(ra) # 80002668 <killed>
    80002cea:	e139                	bnez	a0,80002d30 <usertrap+0xf4>
    p->trapframe->epc += 4;
    80002cec:	6cb8                	ld	a4,88(s1)
    80002cee:	6f1c                	ld	a5,24(a4)
    80002cf0:	0791                	addi	a5,a5,4
    80002cf2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cf4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cf8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cfc:	10079073          	csrw	sstatus,a5
    syscall();
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	398080e7          	jalr	920(ra) # 80003098 <syscall>
  if(killed(p))
    80002d08:	8526                	mv	a0,s1
    80002d0a:	00000097          	auipc	ra,0x0
    80002d0e:	95e080e7          	jalr	-1698(ra) # 80002668 <killed>
    80002d12:	12051063          	bnez	a0,80002e32 <usertrap+0x1f6>
  usertrapret();
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	da8080e7          	jalr	-600(ra) # 80002abe <usertrapret>
}
    80002d1e:	70e2                	ld	ra,56(sp)
    80002d20:	7442                	ld	s0,48(sp)
    80002d22:	74a2                	ld	s1,40(sp)
    80002d24:	7902                	ld	s2,32(sp)
    80002d26:	69e2                	ld	s3,24(sp)
    80002d28:	6a42                	ld	s4,16(sp)
    80002d2a:	6aa2                	ld	s5,8(sp)
    80002d2c:	6121                	addi	sp,sp,64
    80002d2e:	8082                	ret
      exit(-1);
    80002d30:	557d                	li	a0,-1
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	7c2080e7          	jalr	1986(ra) # 800024f4 <exit>
    80002d3a:	bf4d                	j	80002cec <usertrap+0xb0>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d3c:	14302a73          	csrr	s4,stval
struct proc *p = myproc();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	ed2080e7          	jalr	-302(ra) # 80001c12 <myproc>
    80002d48:	892a                	mv	s2,a0
 pte = walk(p->pagetable, faulting_va, 0);
    80002d4a:	4601                	li	a2,0
    80002d4c:	85d2                	mv	a1,s4
    80002d4e:	6928                	ld	a0,80(a0)
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	32e080e7          	jalr	814(ra) # 8000107e <walk>
    80002d58:	89aa                	mv	s3,a0
 if(pte == 0 || (*pte & PTE_V) == 0 || !(*pte & PTE_R) || (*pte & PTE_W) || !(*pte & PTE_COW)) {
    80002d5a:	c901                	beqz	a0,80002d6a <usertrap+0x12e>
    80002d5c:	611c                	ld	a5,0(a0)
    80002d5e:	0277f793          	andi	a5,a5,39
    80002d62:	02300713          	li	a4,35
    80002d66:	00e78663          	beq	a5,a4,80002d72 <usertrap+0x136>
p->killed = 1;
    80002d6a:	4785                	li	a5,1
    80002d6c:	02f92423          	sw	a5,40(s2)
    80002d70:	bf61                	j	80002d08 <usertrap+0xcc>
mem = kalloc();
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	df0080e7          	jalr	-528(ra) # 80000b62 <kalloc>
    80002d7a:	8aaa                	mv	s5,a0
if(mem == 0) {
    80002d7c:	cd3d                	beqz	a0,80002dfa <usertrap+0x1be>
pa = PTE2PA(*pte);
    80002d7e:	0009b583          	ld	a1,0(s3)
    80002d82:	81a9                	srli	a1,a1,0xa
memmove(mem, (char*)pa, PGSIZE);
    80002d84:	6605                	lui	a2,0x1
    80002d86:	05b2                	slli	a1,a1,0xc
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	06e080e7          	jalr	110(ra) # 80000df6 <memmove>
 printf("did move mem\n");
    80002d90:	00005517          	auipc	a0,0x5
    80002d94:	70050513          	addi	a0,a0,1792 # 80008490 <states.0+0x78>
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	804080e7          	jalr	-2044(ra) # 8000059c <printf>
 uvmunmap(p->pagetable, PGROUNDDOWN(faulting_va), 1, 0);
    80002da0:	77fd                	lui	a5,0xfffff
    80002da2:	00fa7a33          	and	s4,s4,a5
    80002da6:	4681                	li	a3,0
    80002da8:	4605                	li	a2,1
    80002daa:	85d2                	mv	a1,s4
    80002dac:	05093503          	ld	a0,80(s2)
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	57c080e7          	jalr	1404(ra) # 8000132c <uvmunmap>
printf("unmapped\n");
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	6e850513          	addi	a0,a0,1768 # 800084a0 <states.0+0x88>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	7dc080e7          	jalr	2012(ra) # 8000059c <printf>
if(mappages(p->pagetable, PGROUNDDOWN(faulting_va), PGSIZE, (uint64)mem, PTE_FLAGS(*pte) | PTE_W) != 0) {
    80002dc8:	0009b703          	ld	a4,0(s3)
    80002dcc:	3fb77713          	andi	a4,a4,1019
    80002dd0:	00476713          	ori	a4,a4,4
    80002dd4:	86d6                	mv	a3,s5
    80002dd6:	6605                	lui	a2,0x1
    80002dd8:	85d2                	mv	a1,s4
    80002dda:	05093503          	ld	a0,80(s2)
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	388080e7          	jalr	904(ra) # 80001166 <mappages>
    80002de6:	ed11                	bnez	a0,80002e02 <usertrap+0x1c6>
         printf("mapped\n");
    80002de8:	00005517          	auipc	a0,0x5
    80002dec:	6d050513          	addi	a0,a0,1744 # 800084b8 <states.0+0xa0>
    80002df0:	ffffd097          	auipc	ra,0xffffd
    80002df4:	7ac080e7          	jalr	1964(ra) # 8000059c <printf>
    80002df8:	bf01                	j	80002d08 <usertrap+0xcc>
 p->killed = 1;
    80002dfa:	4785                	li	a5,1
    80002dfc:	02f92423          	sw	a5,40(s2)
    80002e00:	b721                	j	80002d08 <usertrap+0xcc>
printf("failed\n");
    80002e02:	00005517          	auipc	a0,0x5
    80002e06:	6ae50513          	addi	a0,a0,1710 # 800084b0 <states.0+0x98>
    80002e0a:	ffffd097          	auipc	ra,0xffffd
    80002e0e:	792080e7          	jalr	1938(ra) # 8000059c <printf>
kfree(mem);
    80002e12:	8556                	mv	a0,s5
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	be6080e7          	jalr	-1050(ra) # 800009fa <kfree>
 p->killed = 1;
    80002e1c:	4785                	li	a5,1
    80002e1e:	02f92423          	sw	a5,40(s2)
    80002e22:	b7d9                	j	80002de8 <usertrap+0x1ac>
  if(killed(p))
    80002e24:	8526                	mv	a0,s1
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	842080e7          	jalr	-1982(ra) # 80002668 <killed>
    80002e2e:	c901                	beqz	a0,80002e3e <usertrap+0x202>
    80002e30:	a011                	j	80002e34 <usertrap+0x1f8>
    80002e32:	4901                	li	s2,0
    exit(-1);
    80002e34:	557d                	li	a0,-1
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	6be080e7          	jalr	1726(ra) # 800024f4 <exit>
  if(which_dev == 2)
    80002e3e:	4789                	li	a5,2
    80002e40:	ecf91be3          	bne	s2,a5,80002d16 <usertrap+0xda>
    yield();
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	540080e7          	jalr	1344(ra) # 80002384 <yield>
    80002e4c:	b5e9                	j	80002d16 <usertrap+0xda>

0000000080002e4e <kerneltrap>:
{
    80002e4e:	7179                	addi	sp,sp,-48
    80002e50:	f406                	sd	ra,40(sp)
    80002e52:	f022                	sd	s0,32(sp)
    80002e54:	ec26                	sd	s1,24(sp)
    80002e56:	e84a                	sd	s2,16(sp)
    80002e58:	e44e                	sd	s3,8(sp)
    80002e5a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e5c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e60:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e64:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e68:	1004f793          	andi	a5,s1,256
    80002e6c:	cb85                	beqz	a5,80002e9c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e72:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e74:	ef85                	bnez	a5,80002eac <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	d24080e7          	jalr	-732(ra) # 80002b9a <devintr>
    80002e7e:	cd1d                	beqz	a0,80002ebc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e80:	4789                	li	a5,2
    80002e82:	06f50a63          	beq	a0,a5,80002ef6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e86:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e8a:	10049073          	csrw	sstatus,s1
}
    80002e8e:	70a2                	ld	ra,40(sp)
    80002e90:	7402                	ld	s0,32(sp)
    80002e92:	64e2                	ld	s1,24(sp)
    80002e94:	6942                	ld	s2,16(sp)
    80002e96:	69a2                	ld	s3,8(sp)
    80002e98:	6145                	addi	sp,sp,48
    80002e9a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e9c:	00005517          	auipc	a0,0x5
    80002ea0:	67450513          	addi	a0,a0,1652 # 80008510 <states.0+0xf8>
    80002ea4:	ffffd097          	auipc	ra,0xffffd
    80002ea8:	69c080e7          	jalr	1692(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002eac:	00005517          	auipc	a0,0x5
    80002eb0:	68c50513          	addi	a0,a0,1676 # 80008538 <states.0+0x120>
    80002eb4:	ffffd097          	auipc	ra,0xffffd
    80002eb8:	68c080e7          	jalr	1676(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002ebc:	85ce                	mv	a1,s3
    80002ebe:	00005517          	auipc	a0,0x5
    80002ec2:	69a50513          	addi	a0,a0,1690 # 80008558 <states.0+0x140>
    80002ec6:	ffffd097          	auipc	ra,0xffffd
    80002eca:	6d6080e7          	jalr	1750(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ece:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ed2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ed6:	00005517          	auipc	a0,0x5
    80002eda:	69250513          	addi	a0,a0,1682 # 80008568 <states.0+0x150>
    80002ede:	ffffd097          	auipc	ra,0xffffd
    80002ee2:	6be080e7          	jalr	1726(ra) # 8000059c <printf>
    panic("kerneltrap");
    80002ee6:	00005517          	auipc	a0,0x5
    80002eea:	69a50513          	addi	a0,a0,1690 # 80008580 <states.0+0x168>
    80002eee:	ffffd097          	auipc	ra,0xffffd
    80002ef2:	652080e7          	jalr	1618(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	d1c080e7          	jalr	-740(ra) # 80001c12 <myproc>
    80002efe:	d541                	beqz	a0,80002e86 <kerneltrap+0x38>
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	d12080e7          	jalr	-750(ra) # 80001c12 <myproc>
    80002f08:	4d18                	lw	a4,24(a0)
    80002f0a:	4791                	li	a5,4
    80002f0c:	f6f71de3          	bne	a4,a5,80002e86 <kerneltrap+0x38>
    yield();
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	474080e7          	jalr	1140(ra) # 80002384 <yield>
    80002f18:	b7bd                	j	80002e86 <kerneltrap+0x38>

0000000080002f1a <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	e426                	sd	s1,8(sp)
    80002f22:	1000                	addi	s0,sp,32
    80002f24:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	cec080e7          	jalr	-788(ra) # 80001c12 <myproc>
    switch (n)
    80002f2e:	4795                	li	a5,5
    80002f30:	0497e163          	bltu	a5,s1,80002f72 <argraw+0x58>
    80002f34:	048a                	slli	s1,s1,0x2
    80002f36:	00005717          	auipc	a4,0x5
    80002f3a:	68270713          	addi	a4,a4,1666 # 800085b8 <states.0+0x1a0>
    80002f3e:	94ba                	add	s1,s1,a4
    80002f40:	409c                	lw	a5,0(s1)
    80002f42:	97ba                	add	a5,a5,a4
    80002f44:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f46:	6d3c                	ld	a5,88(a0)
    80002f48:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	64a2                	ld	s1,8(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret
        return p->trapframe->a1;
    80002f54:	6d3c                	ld	a5,88(a0)
    80002f56:	7fa8                	ld	a0,120(a5)
    80002f58:	bfcd                	j	80002f4a <argraw+0x30>
        return p->trapframe->a2;
    80002f5a:	6d3c                	ld	a5,88(a0)
    80002f5c:	63c8                	ld	a0,128(a5)
    80002f5e:	b7f5                	j	80002f4a <argraw+0x30>
        return p->trapframe->a3;
    80002f60:	6d3c                	ld	a5,88(a0)
    80002f62:	67c8                	ld	a0,136(a5)
    80002f64:	b7dd                	j	80002f4a <argraw+0x30>
        return p->trapframe->a4;
    80002f66:	6d3c                	ld	a5,88(a0)
    80002f68:	6bc8                	ld	a0,144(a5)
    80002f6a:	b7c5                	j	80002f4a <argraw+0x30>
        return p->trapframe->a5;
    80002f6c:	6d3c                	ld	a5,88(a0)
    80002f6e:	6fc8                	ld	a0,152(a5)
    80002f70:	bfe9                	j	80002f4a <argraw+0x30>
    panic("argraw");
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	61e50513          	addi	a0,a0,1566 # 80008590 <states.0+0x178>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	5c6080e7          	jalr	1478(ra) # 80000540 <panic>

0000000080002f82 <fetchaddr>:
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	e426                	sd	s1,8(sp)
    80002f8a:	e04a                	sd	s2,0(sp)
    80002f8c:	1000                	addi	s0,sp,32
    80002f8e:	84aa                	mv	s1,a0
    80002f90:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	c80080e7          	jalr	-896(ra) # 80001c12 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f9a:	653c                	ld	a5,72(a0)
    80002f9c:	02f4f863          	bgeu	s1,a5,80002fcc <fetchaddr+0x4a>
    80002fa0:	00848713          	addi	a4,s1,8
    80002fa4:	02e7e663          	bltu	a5,a4,80002fd0 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fa8:	46a1                	li	a3,8
    80002faa:	8626                	mv	a2,s1
    80002fac:	85ca                	mv	a1,s2
    80002fae:	6928                	ld	a0,80(a0)
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	8b0080e7          	jalr	-1872(ra) # 80001860 <copyin>
    80002fb8:	00a03533          	snez	a0,a0
    80002fbc:	40a00533          	neg	a0,a0
}
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	64a2                	ld	s1,8(sp)
    80002fc6:	6902                	ld	s2,0(sp)
    80002fc8:	6105                	addi	sp,sp,32
    80002fca:	8082                	ret
        return -1;
    80002fcc:	557d                	li	a0,-1
    80002fce:	bfcd                	j	80002fc0 <fetchaddr+0x3e>
    80002fd0:	557d                	li	a0,-1
    80002fd2:	b7fd                	j	80002fc0 <fetchaddr+0x3e>

0000000080002fd4 <fetchstr>:
{
    80002fd4:	7179                	addi	sp,sp,-48
    80002fd6:	f406                	sd	ra,40(sp)
    80002fd8:	f022                	sd	s0,32(sp)
    80002fda:	ec26                	sd	s1,24(sp)
    80002fdc:	e84a                	sd	s2,16(sp)
    80002fde:	e44e                	sd	s3,8(sp)
    80002fe0:	1800                	addi	s0,sp,48
    80002fe2:	892a                	mv	s2,a0
    80002fe4:	84ae                	mv	s1,a1
    80002fe6:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	c2a080e7          	jalr	-982(ra) # 80001c12 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ff0:	86ce                	mv	a3,s3
    80002ff2:	864a                	mv	a2,s2
    80002ff4:	85a6                	mv	a1,s1
    80002ff6:	6928                	ld	a0,80(a0)
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	8f6080e7          	jalr	-1802(ra) # 800018ee <copyinstr>
    80003000:	00054e63          	bltz	a0,8000301c <fetchstr+0x48>
    return strlen(buf);
    80003004:	8526                	mv	a0,s1
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	f10080e7          	jalr	-240(ra) # 80000f16 <strlen>
}
    8000300e:	70a2                	ld	ra,40(sp)
    80003010:	7402                	ld	s0,32(sp)
    80003012:	64e2                	ld	s1,24(sp)
    80003014:	6942                	ld	s2,16(sp)
    80003016:	69a2                	ld	s3,8(sp)
    80003018:	6145                	addi	sp,sp,48
    8000301a:	8082                	ret
        return -1;
    8000301c:	557d                	li	a0,-1
    8000301e:	bfc5                	j	8000300e <fetchstr+0x3a>

0000000080003020 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	e426                	sd	s1,8(sp)
    80003028:	1000                	addi	s0,sp,32
    8000302a:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000302c:	00000097          	auipc	ra,0x0
    80003030:	eee080e7          	jalr	-274(ra) # 80002f1a <argraw>
    80003034:	c088                	sw	a0,0(s1)
}
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	64a2                	ld	s1,8(sp)
    8000303c:	6105                	addi	sp,sp,32
    8000303e:	8082                	ret

0000000080003040 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	1000                	addi	s0,sp,32
    8000304a:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	ece080e7          	jalr	-306(ra) # 80002f1a <argraw>
    80003054:	e088                	sd	a0,0(s1)
}
    80003056:	60e2                	ld	ra,24(sp)
    80003058:	6442                	ld	s0,16(sp)
    8000305a:	64a2                	ld	s1,8(sp)
    8000305c:	6105                	addi	sp,sp,32
    8000305e:	8082                	ret

0000000080003060 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003060:	7179                	addi	sp,sp,-48
    80003062:	f406                	sd	ra,40(sp)
    80003064:	f022                	sd	s0,32(sp)
    80003066:	ec26                	sd	s1,24(sp)
    80003068:	e84a                	sd	s2,16(sp)
    8000306a:	1800                	addi	s0,sp,48
    8000306c:	84ae                	mv	s1,a1
    8000306e:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003070:	fd840593          	addi	a1,s0,-40
    80003074:	00000097          	auipc	ra,0x0
    80003078:	fcc080e7          	jalr	-52(ra) # 80003040 <argaddr>
    return fetchstr(addr, buf, max);
    8000307c:	864a                	mv	a2,s2
    8000307e:	85a6                	mv	a1,s1
    80003080:	fd843503          	ld	a0,-40(s0)
    80003084:	00000097          	auipc	ra,0x0
    80003088:	f50080e7          	jalr	-176(ra) # 80002fd4 <fetchstr>
}
    8000308c:	70a2                	ld	ra,40(sp)
    8000308e:	7402                	ld	s0,32(sp)
    80003090:	64e2                	ld	s1,24(sp)
    80003092:	6942                	ld	s2,16(sp)
    80003094:	6145                	addi	sp,sp,48
    80003096:	8082                	ret

0000000080003098 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	e04a                	sd	s2,0(sp)
    800030a2:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	b6e080e7          	jalr	-1170(ra) # 80001c12 <myproc>
    800030ac:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800030ae:	05853903          	ld	s2,88(a0)
    800030b2:	0a893783          	ld	a5,168(s2)
    800030b6:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800030ba:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <end+0xffffffff7ffdd0af>
    800030bc:	4765                	li	a4,25
    800030be:	00f76f63          	bltu	a4,a5,800030dc <syscall+0x44>
    800030c2:	00369713          	slli	a4,a3,0x3
    800030c6:	00005797          	auipc	a5,0x5
    800030ca:	50a78793          	addi	a5,a5,1290 # 800085d0 <syscalls>
    800030ce:	97ba                	add	a5,a5,a4
    800030d0:	639c                	ld	a5,0(a5)
    800030d2:	c789                	beqz	a5,800030dc <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800030d4:	9782                	jalr	a5
    800030d6:	06a93823          	sd	a0,112(s2)
    800030da:	a839                	j	800030f8 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800030dc:	15848613          	addi	a2,s1,344
    800030e0:	588c                	lw	a1,48(s1)
    800030e2:	00005517          	auipc	a0,0x5
    800030e6:	4b650513          	addi	a0,a0,1206 # 80008598 <states.0+0x180>
    800030ea:	ffffd097          	auipc	ra,0xffffd
    800030ee:	4b2080e7          	jalr	1202(ra) # 8000059c <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030f2:	6cbc                	ld	a5,88(s1)
    800030f4:	577d                	li	a4,-1
    800030f6:	fbb8                	sd	a4,112(a5)
    }
}
    800030f8:	60e2                	ld	ra,24(sp)
    800030fa:	6442                	ld	s0,16(sp)
    800030fc:	64a2                	ld	s1,8(sp)
    800030fe:	6902                	ld	s2,0(sp)
    80003100:	6105                	addi	sp,sp,32
    80003102:	8082                	ret

0000000080003104 <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    8000310c:	fec40593          	addi	a1,s0,-20
    80003110:	4501                	li	a0,0
    80003112:	00000097          	auipc	ra,0x0
    80003116:	f0e080e7          	jalr	-242(ra) # 80003020 <argint>
    exit(n);
    8000311a:	fec42503          	lw	a0,-20(s0)
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	3d6080e7          	jalr	982(ra) # 800024f4 <exit>
    return 0; // not reached
}
    80003126:	4501                	li	a0,0
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	6105                	addi	sp,sp,32
    8000312e:	8082                	ret

0000000080003130 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003130:	1141                	addi	sp,sp,-16
    80003132:	e406                	sd	ra,8(sp)
    80003134:	e022                	sd	s0,0(sp)
    80003136:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	ada080e7          	jalr	-1318(ra) # 80001c12 <myproc>
}
    80003140:	5908                	lw	a0,48(a0)
    80003142:	60a2                	ld	ra,8(sp)
    80003144:	6402                	ld	s0,0(sp)
    80003146:	0141                	addi	sp,sp,16
    80003148:	8082                	ret

000000008000314a <sys_fork>:

uint64
sys_fork(void)
{
    8000314a:	1141                	addi	sp,sp,-16
    8000314c:	e406                	sd	ra,8(sp)
    8000314e:	e022                	sd	s0,0(sp)
    80003150:	0800                	addi	s0,sp,16
    return fork();
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	00c080e7          	jalr	12(ra) # 8000215e <fork>
}
    8000315a:	60a2                	ld	ra,8(sp)
    8000315c:	6402                	ld	s0,0(sp)
    8000315e:	0141                	addi	sp,sp,16
    80003160:	8082                	ret

0000000080003162 <sys_wait>:

uint64
sys_wait(void)
{
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    8000316a:	fe840593          	addi	a1,s0,-24
    8000316e:	4501                	li	a0,0
    80003170:	00000097          	auipc	ra,0x0
    80003174:	ed0080e7          	jalr	-304(ra) # 80003040 <argaddr>
    return wait(p);
    80003178:	fe843503          	ld	a0,-24(s0)
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	51e080e7          	jalr	1310(ra) # 8000269a <wait>
}
    80003184:	60e2                	ld	ra,24(sp)
    80003186:	6442                	ld	s0,16(sp)
    80003188:	6105                	addi	sp,sp,32
    8000318a:	8082                	ret

000000008000318c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000318c:	7179                	addi	sp,sp,-48
    8000318e:	f406                	sd	ra,40(sp)
    80003190:	f022                	sd	s0,32(sp)
    80003192:	ec26                	sd	s1,24(sp)
    80003194:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003196:	fdc40593          	addi	a1,s0,-36
    8000319a:	4501                	li	a0,0
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	e84080e7          	jalr	-380(ra) # 80003020 <argint>
    addr = myproc()->sz;
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	a6e080e7          	jalr	-1426(ra) # 80001c12 <myproc>
    800031ac:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800031ae:	fdc42503          	lw	a0,-36(s0)
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	dba080e7          	jalr	-582(ra) # 80001f6c <growproc>
    800031ba:	00054863          	bltz	a0,800031ca <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800031be:	8526                	mv	a0,s1
    800031c0:	70a2                	ld	ra,40(sp)
    800031c2:	7402                	ld	s0,32(sp)
    800031c4:	64e2                	ld	s1,24(sp)
    800031c6:	6145                	addi	sp,sp,48
    800031c8:	8082                	ret
        return -1;
    800031ca:	54fd                	li	s1,-1
    800031cc:	bfcd                	j	800031be <sys_sbrk+0x32>

00000000800031ce <sys_sleep>:

uint64
sys_sleep(void)
{
    800031ce:	7139                	addi	sp,sp,-64
    800031d0:	fc06                	sd	ra,56(sp)
    800031d2:	f822                	sd	s0,48(sp)
    800031d4:	f426                	sd	s1,40(sp)
    800031d6:	f04a                	sd	s2,32(sp)
    800031d8:	ec4e                	sd	s3,24(sp)
    800031da:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800031dc:	fcc40593          	addi	a1,s0,-52
    800031e0:	4501                	li	a0,0
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	e3e080e7          	jalr	-450(ra) # 80003020 <argint>
    acquire(&tickslock);
    800031ea:	00014517          	auipc	a0,0x14
    800031ee:	98650513          	addi	a0,a0,-1658 # 80016b70 <tickslock>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	aac080e7          	jalr	-1364(ra) # 80000c9e <acquire>
    ticks0 = ticks;
    800031fa:	00006917          	auipc	s2,0x6
    800031fe:	8d692903          	lw	s2,-1834(s2) # 80008ad0 <ticks>
    while (ticks - ticks0 < n)
    80003202:	fcc42783          	lw	a5,-52(s0)
    80003206:	cf9d                	beqz	a5,80003244 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003208:	00014997          	auipc	s3,0x14
    8000320c:	96898993          	addi	s3,s3,-1688 # 80016b70 <tickslock>
    80003210:	00006497          	auipc	s1,0x6
    80003214:	8c048493          	addi	s1,s1,-1856 # 80008ad0 <ticks>
        if (killed(myproc()))
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	9fa080e7          	jalr	-1542(ra) # 80001c12 <myproc>
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	448080e7          	jalr	1096(ra) # 80002668 <killed>
    80003228:	ed15                	bnez	a0,80003264 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    8000322a:	85ce                	mv	a1,s3
    8000322c:	8526                	mv	a0,s1
    8000322e:	fffff097          	auipc	ra,0xfffff
    80003232:	192080e7          	jalr	402(ra) # 800023c0 <sleep>
    while (ticks - ticks0 < n)
    80003236:	409c                	lw	a5,0(s1)
    80003238:	412787bb          	subw	a5,a5,s2
    8000323c:	fcc42703          	lw	a4,-52(s0)
    80003240:	fce7ece3          	bltu	a5,a4,80003218 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003244:	00014517          	auipc	a0,0x14
    80003248:	92c50513          	addi	a0,a0,-1748 # 80016b70 <tickslock>
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	b06080e7          	jalr	-1274(ra) # 80000d52 <release>
    return 0;
    80003254:	4501                	li	a0,0
}
    80003256:	70e2                	ld	ra,56(sp)
    80003258:	7442                	ld	s0,48(sp)
    8000325a:	74a2                	ld	s1,40(sp)
    8000325c:	7902                	ld	s2,32(sp)
    8000325e:	69e2                	ld	s3,24(sp)
    80003260:	6121                	addi	sp,sp,64
    80003262:	8082                	ret
            release(&tickslock);
    80003264:	00014517          	auipc	a0,0x14
    80003268:	90c50513          	addi	a0,a0,-1780 # 80016b70 <tickslock>
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	ae6080e7          	jalr	-1306(ra) # 80000d52 <release>
            return -1;
    80003274:	557d                	li	a0,-1
    80003276:	b7c5                	j	80003256 <sys_sleep+0x88>

0000000080003278 <sys_kill>:

uint64
sys_kill(void)
{
    80003278:	1101                	addi	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003280:	fec40593          	addi	a1,s0,-20
    80003284:	4501                	li	a0,0
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	d9a080e7          	jalr	-614(ra) # 80003020 <argint>
    return kill(pid);
    8000328e:	fec42503          	lw	a0,-20(s0)
    80003292:	fffff097          	auipc	ra,0xfffff
    80003296:	338080e7          	jalr	824(ra) # 800025ca <kill>
}
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	e426                	sd	s1,8(sp)
    800032aa:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800032ac:	00014517          	auipc	a0,0x14
    800032b0:	8c450513          	addi	a0,a0,-1852 # 80016b70 <tickslock>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	9ea080e7          	jalr	-1558(ra) # 80000c9e <acquire>
    xticks = ticks;
    800032bc:	00006497          	auipc	s1,0x6
    800032c0:	8144a483          	lw	s1,-2028(s1) # 80008ad0 <ticks>
    release(&tickslock);
    800032c4:	00014517          	auipc	a0,0x14
    800032c8:	8ac50513          	addi	a0,a0,-1876 # 80016b70 <tickslock>
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	a86080e7          	jalr	-1402(ra) # 80000d52 <release>
    return xticks;
}
    800032d4:	02049513          	slli	a0,s1,0x20
    800032d8:	9101                	srli	a0,a0,0x20
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	64a2                	ld	s1,8(sp)
    800032e0:	6105                	addi	sp,sp,32
    800032e2:	8082                	ret

00000000800032e4 <sys_ps>:

void *
sys_ps(void)
{
    800032e4:	1101                	addi	sp,sp,-32
    800032e6:	ec06                	sd	ra,24(sp)
    800032e8:	e822                	sd	s0,16(sp)
    800032ea:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032ec:	fe042623          	sw	zero,-20(s0)
    800032f0:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032f4:	fec40593          	addi	a1,s0,-20
    800032f8:	4501                	li	a0,0
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	d26080e7          	jalr	-730(ra) # 80003020 <argint>
    argint(1, &count);
    80003302:	fe840593          	addi	a1,s0,-24
    80003306:	4505                	li	a0,1
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	d18080e7          	jalr	-744(ra) # 80003020 <argint>
    return ps((uint8)start, (uint8)count);
    80003310:	fe844583          	lbu	a1,-24(s0)
    80003314:	fec44503          	lbu	a0,-20(s0)
    80003318:	fffff097          	auipc	ra,0xfffff
    8000331c:	cb0080e7          	jalr	-848(ra) # 80001fc8 <ps>
}
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret

0000000080003328 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003328:	1141                	addi	sp,sp,-16
    8000332a:	e406                	sd	ra,8(sp)
    8000332c:	e022                	sd	s0,0(sp)
    8000332e:	0800                	addi	s0,sp,16
    schedls();
    80003330:	fffff097          	auipc	ra,0xfffff
    80003334:	5f4080e7          	jalr	1524(ra) # 80002924 <schedls>
    return 0;
}
    80003338:	4501                	li	a0,0
    8000333a:	60a2                	ld	ra,8(sp)
    8000333c:	6402                	ld	s0,0(sp)
    8000333e:	0141                	addi	sp,sp,16
    80003340:	8082                	ret

0000000080003342 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003342:	1101                	addi	sp,sp,-32
    80003344:	ec06                	sd	ra,24(sp)
    80003346:	e822                	sd	s0,16(sp)
    80003348:	1000                	addi	s0,sp,32
    int id = 0;
    8000334a:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000334e:	fec40593          	addi	a1,s0,-20
    80003352:	4501                	li	a0,0
    80003354:	00000097          	auipc	ra,0x0
    80003358:	ccc080e7          	jalr	-820(ra) # 80003020 <argint>
    schedset(id - 1);
    8000335c:	fec42503          	lw	a0,-20(s0)
    80003360:	357d                	addiw	a0,a0,-1
    80003362:	fffff097          	auipc	ra,0xfffff
    80003366:	658080e7          	jalr	1624(ra) # 800029ba <schedset>
    return 0;
}
    8000336a:	4501                	li	a0,0
    8000336c:	60e2                	ld	ra,24(sp)
    8000336e:	6442                	ld	s0,16(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret

0000000080003374 <sys_va2pa>:
}*/

extern struct proc proc[NPROC];

uint64 sys_va2pa(void)
{
    80003374:	1101                	addi	sp,sp,-32
    80003376:	ec06                	sd	ra,24(sp)
    80003378:	e822                	sd	s0,16(sp)
    8000337a:	1000                	addi	s0,sp,32
    
    uint64 va; // Virtual address
    argaddr(0, &va);
    8000337c:	fe840593          	addi	a1,s0,-24
    80003380:	4501                	li	a0,0
    80003382:	00000097          	auipc	ra,0x0
    80003386:	cbe080e7          	jalr	-834(ra) # 80003040 <argaddr>
    int pid = 0;   // Process ID get from args
    8000338a:	fe042223          	sw	zero,-28(s0)
    argint(1, &pid);
    8000338e:	fe440593          	addi	a1,s0,-28
    80003392:	4505                	li	a0,1
    80003394:	00000097          	auipc	ra,0x0
    80003398:	c8c080e7          	jalr	-884(ra) # 80003020 <argint>

    struct proc *target_proc = myproc(); // Default to current process
    8000339c:	fffff097          	auipc	ra,0xfffff
    800033a0:	876080e7          	jalr	-1930(ra) # 80001c12 <myproc>

    if (pid != 0) { // If a specific PID is requested
    800033a4:	fe442703          	lw	a4,-28(s0)
    800033a8:	c31d                	beqz	a4,800033ce <sys_va2pa+0x5a>
        int found = 0;
        for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800033aa:	0000e517          	auipc	a0,0xe
    800033ae:	dc650513          	addi	a0,a0,-570 # 80011170 <proc>
    800033b2:	00013697          	auipc	a3,0x13
    800033b6:	7be68693          	addi	a3,a3,1982 # 80016b70 <tickslock>
    800033ba:	a029                	j	800033c4 <sys_va2pa+0x50>
    800033bc:	16850513          	addi	a0,a0,360
    800033c0:	02d50f63          	beq	a0,a3,800033fe <sys_va2pa+0x8a>
            if(p->pid == pid && p->state != UNUSED) {
    800033c4:	591c                	lw	a5,48(a0)
    800033c6:	fee79be3          	bne	a5,a4,800033bc <sys_va2pa+0x48>
    800033ca:	4d1c                	lw	a5,24(a0)
    800033cc:	dbe5                	beqz	a5,800033bc <sys_va2pa+0x48>
            return 0; // PID not found, return 0
        }
    }

    // Walk the page table to find the physical address corresponding to the given virtual address
    pte_t *pte = walk(target_proc->pagetable, va, 0); // 0 to not create
    800033ce:	4601                	li	a2,0
    800033d0:	fe843583          	ld	a1,-24(s0)
    800033d4:	6928                	ld	a0,80(a0)
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	ca8080e7          	jalr	-856(ra) # 8000107e <walk>
    if(pte == 0 || (*pte & PTE_V) == 0) {
    800033de:	c115                	beqz	a0,80003402 <sys_va2pa+0x8e>
    800033e0:	611c                	ld	a5,0(a0)
    800033e2:	0017f513          	andi	a0,a5,1
    800033e6:	c901                	beqz	a0,800033f6 <sys_va2pa+0x82>
        return 0; // Virtual address not mapped
    }

    uint64 pa = PTE2PA(*pte) | (va & 0xFFF); // Extract physical address and add offset
    800033e8:	83a9                	srli	a5,a5,0xa
    800033ea:	07b2                	slli	a5,a5,0xc
    800033ec:	fe843503          	ld	a0,-24(s0)
    800033f0:	1552                	slli	a0,a0,0x34
    800033f2:	9151                	srli	a0,a0,0x34
    800033f4:	8d5d                	or	a0,a0,a5
    
    return pa;
}
    800033f6:	60e2                	ld	ra,24(sp)
    800033f8:	6442                	ld	s0,16(sp)
    800033fa:	6105                	addi	sp,sp,32
    800033fc:	8082                	ret
            return 0; // PID not found, return 0
    800033fe:	4501                	li	a0,0
    80003400:	bfdd                	j	800033f6 <sys_va2pa+0x82>
        return 0; // Virtual address not mapped
    80003402:	4501                	li	a0,0
    80003404:	bfcd                	j	800033f6 <sys_va2pa+0x82>

0000000080003406 <sys_pfreepages>:


uint64 sys_pfreepages(void)
{
    80003406:	1141                	addi	sp,sp,-16
    80003408:	e406                	sd	ra,8(sp)
    8000340a:	e022                	sd	s0,0(sp)
    8000340c:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    8000340e:	00005597          	auipc	a1,0x5
    80003412:	69a5b583          	ld	a1,1690(a1) # 80008aa8 <FREE_PAGES>
    80003416:	00005517          	auipc	a0,0x5
    8000341a:	19a50513          	addi	a0,a0,410 # 800085b0 <states.0+0x198>
    8000341e:	ffffd097          	auipc	ra,0xffffd
    80003422:	17e080e7          	jalr	382(ra) # 8000059c <printf>
    return 0;
    80003426:	4501                	li	a0,0
    80003428:	60a2                	ld	ra,8(sp)
    8000342a:	6402                	ld	s0,0(sp)
    8000342c:	0141                	addi	sp,sp,16
    8000342e:	8082                	ret

0000000080003430 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003430:	7179                	addi	sp,sp,-48
    80003432:	f406                	sd	ra,40(sp)
    80003434:	f022                	sd	s0,32(sp)
    80003436:	ec26                	sd	s1,24(sp)
    80003438:	e84a                	sd	s2,16(sp)
    8000343a:	e44e                	sd	s3,8(sp)
    8000343c:	e052                	sd	s4,0(sp)
    8000343e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003440:	00005597          	auipc	a1,0x5
    80003444:	26858593          	addi	a1,a1,616 # 800086a8 <syscalls+0xd8>
    80003448:	00013517          	auipc	a0,0x13
    8000344c:	74050513          	addi	a0,a0,1856 # 80016b88 <bcache>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	7be080e7          	jalr	1982(ra) # 80000c0e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003458:	0001b797          	auipc	a5,0x1b
    8000345c:	73078793          	addi	a5,a5,1840 # 8001eb88 <bcache+0x8000>
    80003460:	0001c717          	auipc	a4,0x1c
    80003464:	99070713          	addi	a4,a4,-1648 # 8001edf0 <bcache+0x8268>
    80003468:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000346c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003470:	00013497          	auipc	s1,0x13
    80003474:	73048493          	addi	s1,s1,1840 # 80016ba0 <bcache+0x18>
    b->next = bcache.head.next;
    80003478:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000347a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000347c:	00005a17          	auipc	s4,0x5
    80003480:	234a0a13          	addi	s4,s4,564 # 800086b0 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003484:	2b893783          	ld	a5,696(s2)
    80003488:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000348a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000348e:	85d2                	mv	a1,s4
    80003490:	01048513          	addi	a0,s1,16
    80003494:	00001097          	auipc	ra,0x1
    80003498:	4c8080e7          	jalr	1224(ra) # 8000495c <initsleeplock>
    bcache.head.next->prev = b;
    8000349c:	2b893783          	ld	a5,696(s2)
    800034a0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034a2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034a6:	45848493          	addi	s1,s1,1112
    800034aa:	fd349de3          	bne	s1,s3,80003484 <binit+0x54>
  }
}
    800034ae:	70a2                	ld	ra,40(sp)
    800034b0:	7402                	ld	s0,32(sp)
    800034b2:	64e2                	ld	s1,24(sp)
    800034b4:	6942                	ld	s2,16(sp)
    800034b6:	69a2                	ld	s3,8(sp)
    800034b8:	6a02                	ld	s4,0(sp)
    800034ba:	6145                	addi	sp,sp,48
    800034bc:	8082                	ret

00000000800034be <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034be:	7179                	addi	sp,sp,-48
    800034c0:	f406                	sd	ra,40(sp)
    800034c2:	f022                	sd	s0,32(sp)
    800034c4:	ec26                	sd	s1,24(sp)
    800034c6:	e84a                	sd	s2,16(sp)
    800034c8:	e44e                	sd	s3,8(sp)
    800034ca:	1800                	addi	s0,sp,48
    800034cc:	892a                	mv	s2,a0
    800034ce:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034d0:	00013517          	auipc	a0,0x13
    800034d4:	6b850513          	addi	a0,a0,1720 # 80016b88 <bcache>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	7c6080e7          	jalr	1990(ra) # 80000c9e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034e0:	0001c497          	auipc	s1,0x1c
    800034e4:	9604b483          	ld	s1,-1696(s1) # 8001ee40 <bcache+0x82b8>
    800034e8:	0001c797          	auipc	a5,0x1c
    800034ec:	90878793          	addi	a5,a5,-1784 # 8001edf0 <bcache+0x8268>
    800034f0:	02f48f63          	beq	s1,a5,8000352e <bread+0x70>
    800034f4:	873e                	mv	a4,a5
    800034f6:	a021                	j	800034fe <bread+0x40>
    800034f8:	68a4                	ld	s1,80(s1)
    800034fa:	02e48a63          	beq	s1,a4,8000352e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034fe:	449c                	lw	a5,8(s1)
    80003500:	ff279ce3          	bne	a5,s2,800034f8 <bread+0x3a>
    80003504:	44dc                	lw	a5,12(s1)
    80003506:	ff3799e3          	bne	a5,s3,800034f8 <bread+0x3a>
      b->refcnt++;
    8000350a:	40bc                	lw	a5,64(s1)
    8000350c:	2785                	addiw	a5,a5,1
    8000350e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003510:	00013517          	auipc	a0,0x13
    80003514:	67850513          	addi	a0,a0,1656 # 80016b88 <bcache>
    80003518:	ffffe097          	auipc	ra,0xffffe
    8000351c:	83a080e7          	jalr	-1990(ra) # 80000d52 <release>
      acquiresleep(&b->lock);
    80003520:	01048513          	addi	a0,s1,16
    80003524:	00001097          	auipc	ra,0x1
    80003528:	472080e7          	jalr	1138(ra) # 80004996 <acquiresleep>
      return b;
    8000352c:	a8b9                	j	8000358a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000352e:	0001c497          	auipc	s1,0x1c
    80003532:	90a4b483          	ld	s1,-1782(s1) # 8001ee38 <bcache+0x82b0>
    80003536:	0001c797          	auipc	a5,0x1c
    8000353a:	8ba78793          	addi	a5,a5,-1862 # 8001edf0 <bcache+0x8268>
    8000353e:	00f48863          	beq	s1,a5,8000354e <bread+0x90>
    80003542:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003544:	40bc                	lw	a5,64(s1)
    80003546:	cf81                	beqz	a5,8000355e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003548:	64a4                	ld	s1,72(s1)
    8000354a:	fee49de3          	bne	s1,a4,80003544 <bread+0x86>
  panic("bget: no buffers");
    8000354e:	00005517          	auipc	a0,0x5
    80003552:	16a50513          	addi	a0,a0,362 # 800086b8 <syscalls+0xe8>
    80003556:	ffffd097          	auipc	ra,0xffffd
    8000355a:	fea080e7          	jalr	-22(ra) # 80000540 <panic>
      b->dev = dev;
    8000355e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003562:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003566:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000356a:	4785                	li	a5,1
    8000356c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000356e:	00013517          	auipc	a0,0x13
    80003572:	61a50513          	addi	a0,a0,1562 # 80016b88 <bcache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	7dc080e7          	jalr	2012(ra) # 80000d52 <release>
      acquiresleep(&b->lock);
    8000357e:	01048513          	addi	a0,s1,16
    80003582:	00001097          	auipc	ra,0x1
    80003586:	414080e7          	jalr	1044(ra) # 80004996 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000358a:	409c                	lw	a5,0(s1)
    8000358c:	cb89                	beqz	a5,8000359e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000358e:	8526                	mv	a0,s1
    80003590:	70a2                	ld	ra,40(sp)
    80003592:	7402                	ld	s0,32(sp)
    80003594:	64e2                	ld	s1,24(sp)
    80003596:	6942                	ld	s2,16(sp)
    80003598:	69a2                	ld	s3,8(sp)
    8000359a:	6145                	addi	sp,sp,48
    8000359c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000359e:	4581                	li	a1,0
    800035a0:	8526                	mv	a0,s1
    800035a2:	00003097          	auipc	ra,0x3
    800035a6:	fe0080e7          	jalr	-32(ra) # 80006582 <virtio_disk_rw>
    b->valid = 1;
    800035aa:	4785                	li	a5,1
    800035ac:	c09c                	sw	a5,0(s1)
  return b;
    800035ae:	b7c5                	j	8000358e <bread+0xd0>

00000000800035b0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035b0:	1101                	addi	sp,sp,-32
    800035b2:	ec06                	sd	ra,24(sp)
    800035b4:	e822                	sd	s0,16(sp)
    800035b6:	e426                	sd	s1,8(sp)
    800035b8:	1000                	addi	s0,sp,32
    800035ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035bc:	0541                	addi	a0,a0,16
    800035be:	00001097          	auipc	ra,0x1
    800035c2:	472080e7          	jalr	1138(ra) # 80004a30 <holdingsleep>
    800035c6:	cd01                	beqz	a0,800035de <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035c8:	4585                	li	a1,1
    800035ca:	8526                	mv	a0,s1
    800035cc:	00003097          	auipc	ra,0x3
    800035d0:	fb6080e7          	jalr	-74(ra) # 80006582 <virtio_disk_rw>
}
    800035d4:	60e2                	ld	ra,24(sp)
    800035d6:	6442                	ld	s0,16(sp)
    800035d8:	64a2                	ld	s1,8(sp)
    800035da:	6105                	addi	sp,sp,32
    800035dc:	8082                	ret
    panic("bwrite");
    800035de:	00005517          	auipc	a0,0x5
    800035e2:	0f250513          	addi	a0,a0,242 # 800086d0 <syscalls+0x100>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	f5a080e7          	jalr	-166(ra) # 80000540 <panic>

00000000800035ee <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035ee:	1101                	addi	sp,sp,-32
    800035f0:	ec06                	sd	ra,24(sp)
    800035f2:	e822                	sd	s0,16(sp)
    800035f4:	e426                	sd	s1,8(sp)
    800035f6:	e04a                	sd	s2,0(sp)
    800035f8:	1000                	addi	s0,sp,32
    800035fa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035fc:	01050913          	addi	s2,a0,16
    80003600:	854a                	mv	a0,s2
    80003602:	00001097          	auipc	ra,0x1
    80003606:	42e080e7          	jalr	1070(ra) # 80004a30 <holdingsleep>
    8000360a:	c92d                	beqz	a0,8000367c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000360c:	854a                	mv	a0,s2
    8000360e:	00001097          	auipc	ra,0x1
    80003612:	3de080e7          	jalr	990(ra) # 800049ec <releasesleep>

  acquire(&bcache.lock);
    80003616:	00013517          	auipc	a0,0x13
    8000361a:	57250513          	addi	a0,a0,1394 # 80016b88 <bcache>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	680080e7          	jalr	1664(ra) # 80000c9e <acquire>
  b->refcnt--;
    80003626:	40bc                	lw	a5,64(s1)
    80003628:	37fd                	addiw	a5,a5,-1
    8000362a:	0007871b          	sext.w	a4,a5
    8000362e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003630:	eb05                	bnez	a4,80003660 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003632:	68bc                	ld	a5,80(s1)
    80003634:	64b8                	ld	a4,72(s1)
    80003636:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003638:	64bc                	ld	a5,72(s1)
    8000363a:	68b8                	ld	a4,80(s1)
    8000363c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000363e:	0001b797          	auipc	a5,0x1b
    80003642:	54a78793          	addi	a5,a5,1354 # 8001eb88 <bcache+0x8000>
    80003646:	2b87b703          	ld	a4,696(a5)
    8000364a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000364c:	0001b717          	auipc	a4,0x1b
    80003650:	7a470713          	addi	a4,a4,1956 # 8001edf0 <bcache+0x8268>
    80003654:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003656:	2b87b703          	ld	a4,696(a5)
    8000365a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000365c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003660:	00013517          	auipc	a0,0x13
    80003664:	52850513          	addi	a0,a0,1320 # 80016b88 <bcache>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	6ea080e7          	jalr	1770(ra) # 80000d52 <release>
}
    80003670:	60e2                	ld	ra,24(sp)
    80003672:	6442                	ld	s0,16(sp)
    80003674:	64a2                	ld	s1,8(sp)
    80003676:	6902                	ld	s2,0(sp)
    80003678:	6105                	addi	sp,sp,32
    8000367a:	8082                	ret
    panic("brelse");
    8000367c:	00005517          	auipc	a0,0x5
    80003680:	05c50513          	addi	a0,a0,92 # 800086d8 <syscalls+0x108>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	ebc080e7          	jalr	-324(ra) # 80000540 <panic>

000000008000368c <bpin>:

void
bpin(struct buf *b) {
    8000368c:	1101                	addi	sp,sp,-32
    8000368e:	ec06                	sd	ra,24(sp)
    80003690:	e822                	sd	s0,16(sp)
    80003692:	e426                	sd	s1,8(sp)
    80003694:	1000                	addi	s0,sp,32
    80003696:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003698:	00013517          	auipc	a0,0x13
    8000369c:	4f050513          	addi	a0,a0,1264 # 80016b88 <bcache>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	5fe080e7          	jalr	1534(ra) # 80000c9e <acquire>
  b->refcnt++;
    800036a8:	40bc                	lw	a5,64(s1)
    800036aa:	2785                	addiw	a5,a5,1
    800036ac:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036ae:	00013517          	auipc	a0,0x13
    800036b2:	4da50513          	addi	a0,a0,1242 # 80016b88 <bcache>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	69c080e7          	jalr	1692(ra) # 80000d52 <release>
}
    800036be:	60e2                	ld	ra,24(sp)
    800036c0:	6442                	ld	s0,16(sp)
    800036c2:	64a2                	ld	s1,8(sp)
    800036c4:	6105                	addi	sp,sp,32
    800036c6:	8082                	ret

00000000800036c8 <bunpin>:

void
bunpin(struct buf *b) {
    800036c8:	1101                	addi	sp,sp,-32
    800036ca:	ec06                	sd	ra,24(sp)
    800036cc:	e822                	sd	s0,16(sp)
    800036ce:	e426                	sd	s1,8(sp)
    800036d0:	1000                	addi	s0,sp,32
    800036d2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036d4:	00013517          	auipc	a0,0x13
    800036d8:	4b450513          	addi	a0,a0,1204 # 80016b88 <bcache>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	5c2080e7          	jalr	1474(ra) # 80000c9e <acquire>
  b->refcnt--;
    800036e4:	40bc                	lw	a5,64(s1)
    800036e6:	37fd                	addiw	a5,a5,-1
    800036e8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036ea:	00013517          	auipc	a0,0x13
    800036ee:	49e50513          	addi	a0,a0,1182 # 80016b88 <bcache>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	660080e7          	jalr	1632(ra) # 80000d52 <release>
}
    800036fa:	60e2                	ld	ra,24(sp)
    800036fc:	6442                	ld	s0,16(sp)
    800036fe:	64a2                	ld	s1,8(sp)
    80003700:	6105                	addi	sp,sp,32
    80003702:	8082                	ret

0000000080003704 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003704:	1101                	addi	sp,sp,-32
    80003706:	ec06                	sd	ra,24(sp)
    80003708:	e822                	sd	s0,16(sp)
    8000370a:	e426                	sd	s1,8(sp)
    8000370c:	e04a                	sd	s2,0(sp)
    8000370e:	1000                	addi	s0,sp,32
    80003710:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003712:	00d5d59b          	srliw	a1,a1,0xd
    80003716:	0001c797          	auipc	a5,0x1c
    8000371a:	b4e7a783          	lw	a5,-1202(a5) # 8001f264 <sb+0x1c>
    8000371e:	9dbd                	addw	a1,a1,a5
    80003720:	00000097          	auipc	ra,0x0
    80003724:	d9e080e7          	jalr	-610(ra) # 800034be <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003728:	0074f713          	andi	a4,s1,7
    8000372c:	4785                	li	a5,1
    8000372e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003732:	14ce                	slli	s1,s1,0x33
    80003734:	90d9                	srli	s1,s1,0x36
    80003736:	00950733          	add	a4,a0,s1
    8000373a:	05874703          	lbu	a4,88(a4)
    8000373e:	00e7f6b3          	and	a3,a5,a4
    80003742:	c69d                	beqz	a3,80003770 <bfree+0x6c>
    80003744:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003746:	94aa                	add	s1,s1,a0
    80003748:	fff7c793          	not	a5,a5
    8000374c:	8f7d                	and	a4,a4,a5
    8000374e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003752:	00001097          	auipc	ra,0x1
    80003756:	126080e7          	jalr	294(ra) # 80004878 <log_write>
  brelse(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	e92080e7          	jalr	-366(ra) # 800035ee <brelse>
}
    80003764:	60e2                	ld	ra,24(sp)
    80003766:	6442                	ld	s0,16(sp)
    80003768:	64a2                	ld	s1,8(sp)
    8000376a:	6902                	ld	s2,0(sp)
    8000376c:	6105                	addi	sp,sp,32
    8000376e:	8082                	ret
    panic("freeing free block");
    80003770:	00005517          	auipc	a0,0x5
    80003774:	f7050513          	addi	a0,a0,-144 # 800086e0 <syscalls+0x110>
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	dc8080e7          	jalr	-568(ra) # 80000540 <panic>

0000000080003780 <balloc>:
{
    80003780:	711d                	addi	sp,sp,-96
    80003782:	ec86                	sd	ra,88(sp)
    80003784:	e8a2                	sd	s0,80(sp)
    80003786:	e4a6                	sd	s1,72(sp)
    80003788:	e0ca                	sd	s2,64(sp)
    8000378a:	fc4e                	sd	s3,56(sp)
    8000378c:	f852                	sd	s4,48(sp)
    8000378e:	f456                	sd	s5,40(sp)
    80003790:	f05a                	sd	s6,32(sp)
    80003792:	ec5e                	sd	s7,24(sp)
    80003794:	e862                	sd	s8,16(sp)
    80003796:	e466                	sd	s9,8(sp)
    80003798:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000379a:	0001c797          	auipc	a5,0x1c
    8000379e:	ab27a783          	lw	a5,-1358(a5) # 8001f24c <sb+0x4>
    800037a2:	cff5                	beqz	a5,8000389e <balloc+0x11e>
    800037a4:	8baa                	mv	s7,a0
    800037a6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037a8:	0001cb17          	auipc	s6,0x1c
    800037ac:	aa0b0b13          	addi	s6,s6,-1376 # 8001f248 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037b0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037b2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037b4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037b6:	6c89                	lui	s9,0x2
    800037b8:	a061                	j	80003840 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037ba:	97ca                	add	a5,a5,s2
    800037bc:	8e55                	or	a2,a2,a3
    800037be:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00001097          	auipc	ra,0x1
    800037c8:	0b4080e7          	jalr	180(ra) # 80004878 <log_write>
        brelse(bp);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	e20080e7          	jalr	-480(ra) # 800035ee <brelse>
  bp = bread(dev, bno);
    800037d6:	85a6                	mv	a1,s1
    800037d8:	855e                	mv	a0,s7
    800037da:	00000097          	auipc	ra,0x0
    800037de:	ce4080e7          	jalr	-796(ra) # 800034be <bread>
    800037e2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037e4:	40000613          	li	a2,1024
    800037e8:	4581                	li	a1,0
    800037ea:	05850513          	addi	a0,a0,88
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	5ac080e7          	jalr	1452(ra) # 80000d9a <memset>
  log_write(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	080080e7          	jalr	128(ra) # 80004878 <log_write>
  brelse(bp);
    80003800:	854a                	mv	a0,s2
    80003802:	00000097          	auipc	ra,0x0
    80003806:	dec080e7          	jalr	-532(ra) # 800035ee <brelse>
}
    8000380a:	8526                	mv	a0,s1
    8000380c:	60e6                	ld	ra,88(sp)
    8000380e:	6446                	ld	s0,80(sp)
    80003810:	64a6                	ld	s1,72(sp)
    80003812:	6906                	ld	s2,64(sp)
    80003814:	79e2                	ld	s3,56(sp)
    80003816:	7a42                	ld	s4,48(sp)
    80003818:	7aa2                	ld	s5,40(sp)
    8000381a:	7b02                	ld	s6,32(sp)
    8000381c:	6be2                	ld	s7,24(sp)
    8000381e:	6c42                	ld	s8,16(sp)
    80003820:	6ca2                	ld	s9,8(sp)
    80003822:	6125                	addi	sp,sp,96
    80003824:	8082                	ret
    brelse(bp);
    80003826:	854a                	mv	a0,s2
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	dc6080e7          	jalr	-570(ra) # 800035ee <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003830:	015c87bb          	addw	a5,s9,s5
    80003834:	00078a9b          	sext.w	s5,a5
    80003838:	004b2703          	lw	a4,4(s6)
    8000383c:	06eaf163          	bgeu	s5,a4,8000389e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003840:	41fad79b          	sraiw	a5,s5,0x1f
    80003844:	0137d79b          	srliw	a5,a5,0x13
    80003848:	015787bb          	addw	a5,a5,s5
    8000384c:	40d7d79b          	sraiw	a5,a5,0xd
    80003850:	01cb2583          	lw	a1,28(s6)
    80003854:	9dbd                	addw	a1,a1,a5
    80003856:	855e                	mv	a0,s7
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	c66080e7          	jalr	-922(ra) # 800034be <bread>
    80003860:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003862:	004b2503          	lw	a0,4(s6)
    80003866:	000a849b          	sext.w	s1,s5
    8000386a:	8762                	mv	a4,s8
    8000386c:	faa4fde3          	bgeu	s1,a0,80003826 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003870:	00777693          	andi	a3,a4,7
    80003874:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003878:	41f7579b          	sraiw	a5,a4,0x1f
    8000387c:	01d7d79b          	srliw	a5,a5,0x1d
    80003880:	9fb9                	addw	a5,a5,a4
    80003882:	4037d79b          	sraiw	a5,a5,0x3
    80003886:	00f90633          	add	a2,s2,a5
    8000388a:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000388e:	00c6f5b3          	and	a1,a3,a2
    80003892:	d585                	beqz	a1,800037ba <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003894:	2705                	addiw	a4,a4,1
    80003896:	2485                	addiw	s1,s1,1
    80003898:	fd471ae3          	bne	a4,s4,8000386c <balloc+0xec>
    8000389c:	b769                	j	80003826 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000389e:	00005517          	auipc	a0,0x5
    800038a2:	e5a50513          	addi	a0,a0,-422 # 800086f8 <syscalls+0x128>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	cf6080e7          	jalr	-778(ra) # 8000059c <printf>
  return 0;
    800038ae:	4481                	li	s1,0
    800038b0:	bfa9                	j	8000380a <balloc+0x8a>

00000000800038b2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800038b2:	7179                	addi	sp,sp,-48
    800038b4:	f406                	sd	ra,40(sp)
    800038b6:	f022                	sd	s0,32(sp)
    800038b8:	ec26                	sd	s1,24(sp)
    800038ba:	e84a                	sd	s2,16(sp)
    800038bc:	e44e                	sd	s3,8(sp)
    800038be:	e052                	sd	s4,0(sp)
    800038c0:	1800                	addi	s0,sp,48
    800038c2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038c4:	47ad                	li	a5,11
    800038c6:	02b7e863          	bltu	a5,a1,800038f6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800038ca:	02059793          	slli	a5,a1,0x20
    800038ce:	01e7d593          	srli	a1,a5,0x1e
    800038d2:	00b504b3          	add	s1,a0,a1
    800038d6:	0504a903          	lw	s2,80(s1)
    800038da:	06091e63          	bnez	s2,80003956 <bmap+0xa4>
      addr = balloc(ip->dev);
    800038de:	4108                	lw	a0,0(a0)
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	ea0080e7          	jalr	-352(ra) # 80003780 <balloc>
    800038e8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038ec:	06090563          	beqz	s2,80003956 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800038f0:	0524a823          	sw	s2,80(s1)
    800038f4:	a08d                	j	80003956 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800038f6:	ff45849b          	addiw	s1,a1,-12
    800038fa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038fe:	0ff00793          	li	a5,255
    80003902:	08e7e563          	bltu	a5,a4,8000398c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003906:	08052903          	lw	s2,128(a0)
    8000390a:	00091d63          	bnez	s2,80003924 <bmap+0x72>
      addr = balloc(ip->dev);
    8000390e:	4108                	lw	a0,0(a0)
    80003910:	00000097          	auipc	ra,0x0
    80003914:	e70080e7          	jalr	-400(ra) # 80003780 <balloc>
    80003918:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000391c:	02090d63          	beqz	s2,80003956 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003920:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003924:	85ca                	mv	a1,s2
    80003926:	0009a503          	lw	a0,0(s3)
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	b94080e7          	jalr	-1132(ra) # 800034be <bread>
    80003932:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003934:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003938:	02049713          	slli	a4,s1,0x20
    8000393c:	01e75593          	srli	a1,a4,0x1e
    80003940:	00b784b3          	add	s1,a5,a1
    80003944:	0004a903          	lw	s2,0(s1)
    80003948:	02090063          	beqz	s2,80003968 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000394c:	8552                	mv	a0,s4
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	ca0080e7          	jalr	-864(ra) # 800035ee <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003956:	854a                	mv	a0,s2
    80003958:	70a2                	ld	ra,40(sp)
    8000395a:	7402                	ld	s0,32(sp)
    8000395c:	64e2                	ld	s1,24(sp)
    8000395e:	6942                	ld	s2,16(sp)
    80003960:	69a2                	ld	s3,8(sp)
    80003962:	6a02                	ld	s4,0(sp)
    80003964:	6145                	addi	sp,sp,48
    80003966:	8082                	ret
      addr = balloc(ip->dev);
    80003968:	0009a503          	lw	a0,0(s3)
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	e14080e7          	jalr	-492(ra) # 80003780 <balloc>
    80003974:	0005091b          	sext.w	s2,a0
      if(addr){
    80003978:	fc090ae3          	beqz	s2,8000394c <bmap+0x9a>
        a[bn] = addr;
    8000397c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003980:	8552                	mv	a0,s4
    80003982:	00001097          	auipc	ra,0x1
    80003986:	ef6080e7          	jalr	-266(ra) # 80004878 <log_write>
    8000398a:	b7c9                	j	8000394c <bmap+0x9a>
  panic("bmap: out of range");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	d8450513          	addi	a0,a0,-636 # 80008710 <syscalls+0x140>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	bac080e7          	jalr	-1108(ra) # 80000540 <panic>

000000008000399c <iget>:
{
    8000399c:	7179                	addi	sp,sp,-48
    8000399e:	f406                	sd	ra,40(sp)
    800039a0:	f022                	sd	s0,32(sp)
    800039a2:	ec26                	sd	s1,24(sp)
    800039a4:	e84a                	sd	s2,16(sp)
    800039a6:	e44e                	sd	s3,8(sp)
    800039a8:	e052                	sd	s4,0(sp)
    800039aa:	1800                	addi	s0,sp,48
    800039ac:	89aa                	mv	s3,a0
    800039ae:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039b0:	0001c517          	auipc	a0,0x1c
    800039b4:	8b850513          	addi	a0,a0,-1864 # 8001f268 <itable>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	2e6080e7          	jalr	742(ra) # 80000c9e <acquire>
  empty = 0;
    800039c0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039c2:	0001c497          	auipc	s1,0x1c
    800039c6:	8be48493          	addi	s1,s1,-1858 # 8001f280 <itable+0x18>
    800039ca:	0001d697          	auipc	a3,0x1d
    800039ce:	34668693          	addi	a3,a3,838 # 80020d10 <log>
    800039d2:	a039                	j	800039e0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039d4:	02090b63          	beqz	s2,80003a0a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039d8:	08848493          	addi	s1,s1,136
    800039dc:	02d48a63          	beq	s1,a3,80003a10 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039e0:	449c                	lw	a5,8(s1)
    800039e2:	fef059e3          	blez	a5,800039d4 <iget+0x38>
    800039e6:	4098                	lw	a4,0(s1)
    800039e8:	ff3716e3          	bne	a4,s3,800039d4 <iget+0x38>
    800039ec:	40d8                	lw	a4,4(s1)
    800039ee:	ff4713e3          	bne	a4,s4,800039d4 <iget+0x38>
      ip->ref++;
    800039f2:	2785                	addiw	a5,a5,1
    800039f4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039f6:	0001c517          	auipc	a0,0x1c
    800039fa:	87250513          	addi	a0,a0,-1934 # 8001f268 <itable>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	354080e7          	jalr	852(ra) # 80000d52 <release>
      return ip;
    80003a06:	8926                	mv	s2,s1
    80003a08:	a03d                	j	80003a36 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a0a:	f7f9                	bnez	a5,800039d8 <iget+0x3c>
    80003a0c:	8926                	mv	s2,s1
    80003a0e:	b7e9                	j	800039d8 <iget+0x3c>
  if(empty == 0)
    80003a10:	02090c63          	beqz	s2,80003a48 <iget+0xac>
  ip->dev = dev;
    80003a14:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a18:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a1c:	4785                	li	a5,1
    80003a1e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a22:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a26:	0001c517          	auipc	a0,0x1c
    80003a2a:	84250513          	addi	a0,a0,-1982 # 8001f268 <itable>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	324080e7          	jalr	804(ra) # 80000d52 <release>
}
    80003a36:	854a                	mv	a0,s2
    80003a38:	70a2                	ld	ra,40(sp)
    80003a3a:	7402                	ld	s0,32(sp)
    80003a3c:	64e2                	ld	s1,24(sp)
    80003a3e:	6942                	ld	s2,16(sp)
    80003a40:	69a2                	ld	s3,8(sp)
    80003a42:	6a02                	ld	s4,0(sp)
    80003a44:	6145                	addi	sp,sp,48
    80003a46:	8082                	ret
    panic("iget: no inodes");
    80003a48:	00005517          	auipc	a0,0x5
    80003a4c:	ce050513          	addi	a0,a0,-800 # 80008728 <syscalls+0x158>
    80003a50:	ffffd097          	auipc	ra,0xffffd
    80003a54:	af0080e7          	jalr	-1296(ra) # 80000540 <panic>

0000000080003a58 <fsinit>:
fsinit(int dev) {
    80003a58:	7179                	addi	sp,sp,-48
    80003a5a:	f406                	sd	ra,40(sp)
    80003a5c:	f022                	sd	s0,32(sp)
    80003a5e:	ec26                	sd	s1,24(sp)
    80003a60:	e84a                	sd	s2,16(sp)
    80003a62:	e44e                	sd	s3,8(sp)
    80003a64:	1800                	addi	s0,sp,48
    80003a66:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a68:	4585                	li	a1,1
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	a54080e7          	jalr	-1452(ra) # 800034be <bread>
    80003a72:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a74:	0001b997          	auipc	s3,0x1b
    80003a78:	7d498993          	addi	s3,s3,2004 # 8001f248 <sb>
    80003a7c:	02000613          	li	a2,32
    80003a80:	05850593          	addi	a1,a0,88
    80003a84:	854e                	mv	a0,s3
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	370080e7          	jalr	880(ra) # 80000df6 <memmove>
  brelse(bp);
    80003a8e:	8526                	mv	a0,s1
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	b5e080e7          	jalr	-1186(ra) # 800035ee <brelse>
  if(sb.magic != FSMAGIC)
    80003a98:	0009a703          	lw	a4,0(s3)
    80003a9c:	102037b7          	lui	a5,0x10203
    80003aa0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003aa4:	02f71263          	bne	a4,a5,80003ac8 <fsinit+0x70>
  initlog(dev, &sb);
    80003aa8:	0001b597          	auipc	a1,0x1b
    80003aac:	7a058593          	addi	a1,a1,1952 # 8001f248 <sb>
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	00001097          	auipc	ra,0x1
    80003ab6:	b4a080e7          	jalr	-1206(ra) # 800045fc <initlog>
}
    80003aba:	70a2                	ld	ra,40(sp)
    80003abc:	7402                	ld	s0,32(sp)
    80003abe:	64e2                	ld	s1,24(sp)
    80003ac0:	6942                	ld	s2,16(sp)
    80003ac2:	69a2                	ld	s3,8(sp)
    80003ac4:	6145                	addi	sp,sp,48
    80003ac6:	8082                	ret
    panic("invalid file system");
    80003ac8:	00005517          	auipc	a0,0x5
    80003acc:	c7050513          	addi	a0,a0,-912 # 80008738 <syscalls+0x168>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	a70080e7          	jalr	-1424(ra) # 80000540 <panic>

0000000080003ad8 <iinit>:
{
    80003ad8:	7179                	addi	sp,sp,-48
    80003ada:	f406                	sd	ra,40(sp)
    80003adc:	f022                	sd	s0,32(sp)
    80003ade:	ec26                	sd	s1,24(sp)
    80003ae0:	e84a                	sd	s2,16(sp)
    80003ae2:	e44e                	sd	s3,8(sp)
    80003ae4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ae6:	00005597          	auipc	a1,0x5
    80003aea:	c6a58593          	addi	a1,a1,-918 # 80008750 <syscalls+0x180>
    80003aee:	0001b517          	auipc	a0,0x1b
    80003af2:	77a50513          	addi	a0,a0,1914 # 8001f268 <itable>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	118080e7          	jalr	280(ra) # 80000c0e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003afe:	0001b497          	auipc	s1,0x1b
    80003b02:	79248493          	addi	s1,s1,1938 # 8001f290 <itable+0x28>
    80003b06:	0001d997          	auipc	s3,0x1d
    80003b0a:	21a98993          	addi	s3,s3,538 # 80020d20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b0e:	00005917          	auipc	s2,0x5
    80003b12:	c4a90913          	addi	s2,s2,-950 # 80008758 <syscalls+0x188>
    80003b16:	85ca                	mv	a1,s2
    80003b18:	8526                	mv	a0,s1
    80003b1a:	00001097          	auipc	ra,0x1
    80003b1e:	e42080e7          	jalr	-446(ra) # 8000495c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b22:	08848493          	addi	s1,s1,136
    80003b26:	ff3498e3          	bne	s1,s3,80003b16 <iinit+0x3e>
}
    80003b2a:	70a2                	ld	ra,40(sp)
    80003b2c:	7402                	ld	s0,32(sp)
    80003b2e:	64e2                	ld	s1,24(sp)
    80003b30:	6942                	ld	s2,16(sp)
    80003b32:	69a2                	ld	s3,8(sp)
    80003b34:	6145                	addi	sp,sp,48
    80003b36:	8082                	ret

0000000080003b38 <ialloc>:
{
    80003b38:	715d                	addi	sp,sp,-80
    80003b3a:	e486                	sd	ra,72(sp)
    80003b3c:	e0a2                	sd	s0,64(sp)
    80003b3e:	fc26                	sd	s1,56(sp)
    80003b40:	f84a                	sd	s2,48(sp)
    80003b42:	f44e                	sd	s3,40(sp)
    80003b44:	f052                	sd	s4,32(sp)
    80003b46:	ec56                	sd	s5,24(sp)
    80003b48:	e85a                	sd	s6,16(sp)
    80003b4a:	e45e                	sd	s7,8(sp)
    80003b4c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b4e:	0001b717          	auipc	a4,0x1b
    80003b52:	70672703          	lw	a4,1798(a4) # 8001f254 <sb+0xc>
    80003b56:	4785                	li	a5,1
    80003b58:	04e7fa63          	bgeu	a5,a4,80003bac <ialloc+0x74>
    80003b5c:	8aaa                	mv	s5,a0
    80003b5e:	8bae                	mv	s7,a1
    80003b60:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b62:	0001ba17          	auipc	s4,0x1b
    80003b66:	6e6a0a13          	addi	s4,s4,1766 # 8001f248 <sb>
    80003b6a:	00048b1b          	sext.w	s6,s1
    80003b6e:	0044d593          	srli	a1,s1,0x4
    80003b72:	018a2783          	lw	a5,24(s4)
    80003b76:	9dbd                	addw	a1,a1,a5
    80003b78:	8556                	mv	a0,s5
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	944080e7          	jalr	-1724(ra) # 800034be <bread>
    80003b82:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b84:	05850993          	addi	s3,a0,88
    80003b88:	00f4f793          	andi	a5,s1,15
    80003b8c:	079a                	slli	a5,a5,0x6
    80003b8e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b90:	00099783          	lh	a5,0(s3)
    80003b94:	c3a1                	beqz	a5,80003bd4 <ialloc+0x9c>
    brelse(bp);
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	a58080e7          	jalr	-1448(ra) # 800035ee <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b9e:	0485                	addi	s1,s1,1
    80003ba0:	00ca2703          	lw	a4,12(s4)
    80003ba4:	0004879b          	sext.w	a5,s1
    80003ba8:	fce7e1e3          	bltu	a5,a4,80003b6a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003bac:	00005517          	auipc	a0,0x5
    80003bb0:	bb450513          	addi	a0,a0,-1100 # 80008760 <syscalls+0x190>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	9e8080e7          	jalr	-1560(ra) # 8000059c <printf>
  return 0;
    80003bbc:	4501                	li	a0,0
}
    80003bbe:	60a6                	ld	ra,72(sp)
    80003bc0:	6406                	ld	s0,64(sp)
    80003bc2:	74e2                	ld	s1,56(sp)
    80003bc4:	7942                	ld	s2,48(sp)
    80003bc6:	79a2                	ld	s3,40(sp)
    80003bc8:	7a02                	ld	s4,32(sp)
    80003bca:	6ae2                	ld	s5,24(sp)
    80003bcc:	6b42                	ld	s6,16(sp)
    80003bce:	6ba2                	ld	s7,8(sp)
    80003bd0:	6161                	addi	sp,sp,80
    80003bd2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003bd4:	04000613          	li	a2,64
    80003bd8:	4581                	li	a1,0
    80003bda:	854e                	mv	a0,s3
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	1be080e7          	jalr	446(ra) # 80000d9a <memset>
      dip->type = type;
    80003be4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003be8:	854a                	mv	a0,s2
    80003bea:	00001097          	auipc	ra,0x1
    80003bee:	c8e080e7          	jalr	-882(ra) # 80004878 <log_write>
      brelse(bp);
    80003bf2:	854a                	mv	a0,s2
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	9fa080e7          	jalr	-1542(ra) # 800035ee <brelse>
      return iget(dev, inum);
    80003bfc:	85da                	mv	a1,s6
    80003bfe:	8556                	mv	a0,s5
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	d9c080e7          	jalr	-612(ra) # 8000399c <iget>
    80003c08:	bf5d                	j	80003bbe <ialloc+0x86>

0000000080003c0a <iupdate>:
{
    80003c0a:	1101                	addi	sp,sp,-32
    80003c0c:	ec06                	sd	ra,24(sp)
    80003c0e:	e822                	sd	s0,16(sp)
    80003c10:	e426                	sd	s1,8(sp)
    80003c12:	e04a                	sd	s2,0(sp)
    80003c14:	1000                	addi	s0,sp,32
    80003c16:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c18:	415c                	lw	a5,4(a0)
    80003c1a:	0047d79b          	srliw	a5,a5,0x4
    80003c1e:	0001b597          	auipc	a1,0x1b
    80003c22:	6425a583          	lw	a1,1602(a1) # 8001f260 <sb+0x18>
    80003c26:	9dbd                	addw	a1,a1,a5
    80003c28:	4108                	lw	a0,0(a0)
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	894080e7          	jalr	-1900(ra) # 800034be <bread>
    80003c32:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c34:	05850793          	addi	a5,a0,88
    80003c38:	40d8                	lw	a4,4(s1)
    80003c3a:	8b3d                	andi	a4,a4,15
    80003c3c:	071a                	slli	a4,a4,0x6
    80003c3e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c40:	04449703          	lh	a4,68(s1)
    80003c44:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c48:	04649703          	lh	a4,70(s1)
    80003c4c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c50:	04849703          	lh	a4,72(s1)
    80003c54:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c58:	04a49703          	lh	a4,74(s1)
    80003c5c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c60:	44f8                	lw	a4,76(s1)
    80003c62:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c64:	03400613          	li	a2,52
    80003c68:	05048593          	addi	a1,s1,80
    80003c6c:	00c78513          	addi	a0,a5,12
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	186080e7          	jalr	390(ra) # 80000df6 <memmove>
  log_write(bp);
    80003c78:	854a                	mv	a0,s2
    80003c7a:	00001097          	auipc	ra,0x1
    80003c7e:	bfe080e7          	jalr	-1026(ra) # 80004878 <log_write>
  brelse(bp);
    80003c82:	854a                	mv	a0,s2
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	96a080e7          	jalr	-1686(ra) # 800035ee <brelse>
}
    80003c8c:	60e2                	ld	ra,24(sp)
    80003c8e:	6442                	ld	s0,16(sp)
    80003c90:	64a2                	ld	s1,8(sp)
    80003c92:	6902                	ld	s2,0(sp)
    80003c94:	6105                	addi	sp,sp,32
    80003c96:	8082                	ret

0000000080003c98 <idup>:
{
    80003c98:	1101                	addi	sp,sp,-32
    80003c9a:	ec06                	sd	ra,24(sp)
    80003c9c:	e822                	sd	s0,16(sp)
    80003c9e:	e426                	sd	s1,8(sp)
    80003ca0:	1000                	addi	s0,sp,32
    80003ca2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ca4:	0001b517          	auipc	a0,0x1b
    80003ca8:	5c450513          	addi	a0,a0,1476 # 8001f268 <itable>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	ff2080e7          	jalr	-14(ra) # 80000c9e <acquire>
  ip->ref++;
    80003cb4:	449c                	lw	a5,8(s1)
    80003cb6:	2785                	addiw	a5,a5,1
    80003cb8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cba:	0001b517          	auipc	a0,0x1b
    80003cbe:	5ae50513          	addi	a0,a0,1454 # 8001f268 <itable>
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	090080e7          	jalr	144(ra) # 80000d52 <release>
}
    80003cca:	8526                	mv	a0,s1
    80003ccc:	60e2                	ld	ra,24(sp)
    80003cce:	6442                	ld	s0,16(sp)
    80003cd0:	64a2                	ld	s1,8(sp)
    80003cd2:	6105                	addi	sp,sp,32
    80003cd4:	8082                	ret

0000000080003cd6 <ilock>:
{
    80003cd6:	1101                	addi	sp,sp,-32
    80003cd8:	ec06                	sd	ra,24(sp)
    80003cda:	e822                	sd	s0,16(sp)
    80003cdc:	e426                	sd	s1,8(sp)
    80003cde:	e04a                	sd	s2,0(sp)
    80003ce0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ce2:	c115                	beqz	a0,80003d06 <ilock+0x30>
    80003ce4:	84aa                	mv	s1,a0
    80003ce6:	451c                	lw	a5,8(a0)
    80003ce8:	00f05f63          	blez	a5,80003d06 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cec:	0541                	addi	a0,a0,16
    80003cee:	00001097          	auipc	ra,0x1
    80003cf2:	ca8080e7          	jalr	-856(ra) # 80004996 <acquiresleep>
  if(ip->valid == 0){
    80003cf6:	40bc                	lw	a5,64(s1)
    80003cf8:	cf99                	beqz	a5,80003d16 <ilock+0x40>
}
    80003cfa:	60e2                	ld	ra,24(sp)
    80003cfc:	6442                	ld	s0,16(sp)
    80003cfe:	64a2                	ld	s1,8(sp)
    80003d00:	6902                	ld	s2,0(sp)
    80003d02:	6105                	addi	sp,sp,32
    80003d04:	8082                	ret
    panic("ilock");
    80003d06:	00005517          	auipc	a0,0x5
    80003d0a:	a7250513          	addi	a0,a0,-1422 # 80008778 <syscalls+0x1a8>
    80003d0e:	ffffd097          	auipc	ra,0xffffd
    80003d12:	832080e7          	jalr	-1998(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d16:	40dc                	lw	a5,4(s1)
    80003d18:	0047d79b          	srliw	a5,a5,0x4
    80003d1c:	0001b597          	auipc	a1,0x1b
    80003d20:	5445a583          	lw	a1,1348(a1) # 8001f260 <sb+0x18>
    80003d24:	9dbd                	addw	a1,a1,a5
    80003d26:	4088                	lw	a0,0(s1)
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	796080e7          	jalr	1942(ra) # 800034be <bread>
    80003d30:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d32:	05850593          	addi	a1,a0,88
    80003d36:	40dc                	lw	a5,4(s1)
    80003d38:	8bbd                	andi	a5,a5,15
    80003d3a:	079a                	slli	a5,a5,0x6
    80003d3c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d3e:	00059783          	lh	a5,0(a1)
    80003d42:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d46:	00259783          	lh	a5,2(a1)
    80003d4a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d4e:	00459783          	lh	a5,4(a1)
    80003d52:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d56:	00659783          	lh	a5,6(a1)
    80003d5a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d5e:	459c                	lw	a5,8(a1)
    80003d60:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d62:	03400613          	li	a2,52
    80003d66:	05b1                	addi	a1,a1,12
    80003d68:	05048513          	addi	a0,s1,80
    80003d6c:	ffffd097          	auipc	ra,0xffffd
    80003d70:	08a080e7          	jalr	138(ra) # 80000df6 <memmove>
    brelse(bp);
    80003d74:	854a                	mv	a0,s2
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	878080e7          	jalr	-1928(ra) # 800035ee <brelse>
    ip->valid = 1;
    80003d7e:	4785                	li	a5,1
    80003d80:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d82:	04449783          	lh	a5,68(s1)
    80003d86:	fbb5                	bnez	a5,80003cfa <ilock+0x24>
      panic("ilock: no type");
    80003d88:	00005517          	auipc	a0,0x5
    80003d8c:	9f850513          	addi	a0,a0,-1544 # 80008780 <syscalls+0x1b0>
    80003d90:	ffffc097          	auipc	ra,0xffffc
    80003d94:	7b0080e7          	jalr	1968(ra) # 80000540 <panic>

0000000080003d98 <iunlock>:
{
    80003d98:	1101                	addi	sp,sp,-32
    80003d9a:	ec06                	sd	ra,24(sp)
    80003d9c:	e822                	sd	s0,16(sp)
    80003d9e:	e426                	sd	s1,8(sp)
    80003da0:	e04a                	sd	s2,0(sp)
    80003da2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003da4:	c905                	beqz	a0,80003dd4 <iunlock+0x3c>
    80003da6:	84aa                	mv	s1,a0
    80003da8:	01050913          	addi	s2,a0,16
    80003dac:	854a                	mv	a0,s2
    80003dae:	00001097          	auipc	ra,0x1
    80003db2:	c82080e7          	jalr	-894(ra) # 80004a30 <holdingsleep>
    80003db6:	cd19                	beqz	a0,80003dd4 <iunlock+0x3c>
    80003db8:	449c                	lw	a5,8(s1)
    80003dba:	00f05d63          	blez	a5,80003dd4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00001097          	auipc	ra,0x1
    80003dc4:	c2c080e7          	jalr	-980(ra) # 800049ec <releasesleep>
}
    80003dc8:	60e2                	ld	ra,24(sp)
    80003dca:	6442                	ld	s0,16(sp)
    80003dcc:	64a2                	ld	s1,8(sp)
    80003dce:	6902                	ld	s2,0(sp)
    80003dd0:	6105                	addi	sp,sp,32
    80003dd2:	8082                	ret
    panic("iunlock");
    80003dd4:	00005517          	auipc	a0,0x5
    80003dd8:	9bc50513          	addi	a0,a0,-1604 # 80008790 <syscalls+0x1c0>
    80003ddc:	ffffc097          	auipc	ra,0xffffc
    80003de0:	764080e7          	jalr	1892(ra) # 80000540 <panic>

0000000080003de4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003de4:	7179                	addi	sp,sp,-48
    80003de6:	f406                	sd	ra,40(sp)
    80003de8:	f022                	sd	s0,32(sp)
    80003dea:	ec26                	sd	s1,24(sp)
    80003dec:	e84a                	sd	s2,16(sp)
    80003dee:	e44e                	sd	s3,8(sp)
    80003df0:	e052                	sd	s4,0(sp)
    80003df2:	1800                	addi	s0,sp,48
    80003df4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003df6:	05050493          	addi	s1,a0,80
    80003dfa:	08050913          	addi	s2,a0,128
    80003dfe:	a021                	j	80003e06 <itrunc+0x22>
    80003e00:	0491                	addi	s1,s1,4
    80003e02:	01248d63          	beq	s1,s2,80003e1c <itrunc+0x38>
    if(ip->addrs[i]){
    80003e06:	408c                	lw	a1,0(s1)
    80003e08:	dde5                	beqz	a1,80003e00 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e0a:	0009a503          	lw	a0,0(s3)
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	8f6080e7          	jalr	-1802(ra) # 80003704 <bfree>
      ip->addrs[i] = 0;
    80003e16:	0004a023          	sw	zero,0(s1)
    80003e1a:	b7dd                	j	80003e00 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e1c:	0809a583          	lw	a1,128(s3)
    80003e20:	e185                	bnez	a1,80003e40 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e22:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	de2080e7          	jalr	-542(ra) # 80003c0a <iupdate>
}
    80003e30:	70a2                	ld	ra,40(sp)
    80003e32:	7402                	ld	s0,32(sp)
    80003e34:	64e2                	ld	s1,24(sp)
    80003e36:	6942                	ld	s2,16(sp)
    80003e38:	69a2                	ld	s3,8(sp)
    80003e3a:	6a02                	ld	s4,0(sp)
    80003e3c:	6145                	addi	sp,sp,48
    80003e3e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e40:	0009a503          	lw	a0,0(s3)
    80003e44:	fffff097          	auipc	ra,0xfffff
    80003e48:	67a080e7          	jalr	1658(ra) # 800034be <bread>
    80003e4c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e4e:	05850493          	addi	s1,a0,88
    80003e52:	45850913          	addi	s2,a0,1112
    80003e56:	a021                	j	80003e5e <itrunc+0x7a>
    80003e58:	0491                	addi	s1,s1,4
    80003e5a:	01248b63          	beq	s1,s2,80003e70 <itrunc+0x8c>
      if(a[j])
    80003e5e:	408c                	lw	a1,0(s1)
    80003e60:	dde5                	beqz	a1,80003e58 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e62:	0009a503          	lw	a0,0(s3)
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	89e080e7          	jalr	-1890(ra) # 80003704 <bfree>
    80003e6e:	b7ed                	j	80003e58 <itrunc+0x74>
    brelse(bp);
    80003e70:	8552                	mv	a0,s4
    80003e72:	fffff097          	auipc	ra,0xfffff
    80003e76:	77c080e7          	jalr	1916(ra) # 800035ee <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e7a:	0809a583          	lw	a1,128(s3)
    80003e7e:	0009a503          	lw	a0,0(s3)
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	882080e7          	jalr	-1918(ra) # 80003704 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e8a:	0809a023          	sw	zero,128(s3)
    80003e8e:	bf51                	j	80003e22 <itrunc+0x3e>

0000000080003e90 <iput>:
{
    80003e90:	1101                	addi	sp,sp,-32
    80003e92:	ec06                	sd	ra,24(sp)
    80003e94:	e822                	sd	s0,16(sp)
    80003e96:	e426                	sd	s1,8(sp)
    80003e98:	e04a                	sd	s2,0(sp)
    80003e9a:	1000                	addi	s0,sp,32
    80003e9c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e9e:	0001b517          	auipc	a0,0x1b
    80003ea2:	3ca50513          	addi	a0,a0,970 # 8001f268 <itable>
    80003ea6:	ffffd097          	auipc	ra,0xffffd
    80003eaa:	df8080e7          	jalr	-520(ra) # 80000c9e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eae:	4498                	lw	a4,8(s1)
    80003eb0:	4785                	li	a5,1
    80003eb2:	02f70363          	beq	a4,a5,80003ed8 <iput+0x48>
  ip->ref--;
    80003eb6:	449c                	lw	a5,8(s1)
    80003eb8:	37fd                	addiw	a5,a5,-1
    80003eba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ebc:	0001b517          	auipc	a0,0x1b
    80003ec0:	3ac50513          	addi	a0,a0,940 # 8001f268 <itable>
    80003ec4:	ffffd097          	auipc	ra,0xffffd
    80003ec8:	e8e080e7          	jalr	-370(ra) # 80000d52 <release>
}
    80003ecc:	60e2                	ld	ra,24(sp)
    80003ece:	6442                	ld	s0,16(sp)
    80003ed0:	64a2                	ld	s1,8(sp)
    80003ed2:	6902                	ld	s2,0(sp)
    80003ed4:	6105                	addi	sp,sp,32
    80003ed6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ed8:	40bc                	lw	a5,64(s1)
    80003eda:	dff1                	beqz	a5,80003eb6 <iput+0x26>
    80003edc:	04a49783          	lh	a5,74(s1)
    80003ee0:	fbf9                	bnez	a5,80003eb6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ee2:	01048913          	addi	s2,s1,16
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	00001097          	auipc	ra,0x1
    80003eec:	aae080e7          	jalr	-1362(ra) # 80004996 <acquiresleep>
    release(&itable.lock);
    80003ef0:	0001b517          	auipc	a0,0x1b
    80003ef4:	37850513          	addi	a0,a0,888 # 8001f268 <itable>
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	e5a080e7          	jalr	-422(ra) # 80000d52 <release>
    itrunc(ip);
    80003f00:	8526                	mv	a0,s1
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	ee2080e7          	jalr	-286(ra) # 80003de4 <itrunc>
    ip->type = 0;
    80003f0a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f0e:	8526                	mv	a0,s1
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	cfa080e7          	jalr	-774(ra) # 80003c0a <iupdate>
    ip->valid = 0;
    80003f18:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	00001097          	auipc	ra,0x1
    80003f22:	ace080e7          	jalr	-1330(ra) # 800049ec <releasesleep>
    acquire(&itable.lock);
    80003f26:	0001b517          	auipc	a0,0x1b
    80003f2a:	34250513          	addi	a0,a0,834 # 8001f268 <itable>
    80003f2e:	ffffd097          	auipc	ra,0xffffd
    80003f32:	d70080e7          	jalr	-656(ra) # 80000c9e <acquire>
    80003f36:	b741                	j	80003eb6 <iput+0x26>

0000000080003f38 <iunlockput>:
{
    80003f38:	1101                	addi	sp,sp,-32
    80003f3a:	ec06                	sd	ra,24(sp)
    80003f3c:	e822                	sd	s0,16(sp)
    80003f3e:	e426                	sd	s1,8(sp)
    80003f40:	1000                	addi	s0,sp,32
    80003f42:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	e54080e7          	jalr	-428(ra) # 80003d98 <iunlock>
  iput(ip);
    80003f4c:	8526                	mv	a0,s1
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	f42080e7          	jalr	-190(ra) # 80003e90 <iput>
}
    80003f56:	60e2                	ld	ra,24(sp)
    80003f58:	6442                	ld	s0,16(sp)
    80003f5a:	64a2                	ld	s1,8(sp)
    80003f5c:	6105                	addi	sp,sp,32
    80003f5e:	8082                	ret

0000000080003f60 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f60:	1141                	addi	sp,sp,-16
    80003f62:	e422                	sd	s0,8(sp)
    80003f64:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f66:	411c                	lw	a5,0(a0)
    80003f68:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f6a:	415c                	lw	a5,4(a0)
    80003f6c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f6e:	04451783          	lh	a5,68(a0)
    80003f72:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f76:	04a51783          	lh	a5,74(a0)
    80003f7a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f7e:	04c56783          	lwu	a5,76(a0)
    80003f82:	e99c                	sd	a5,16(a1)
}
    80003f84:	6422                	ld	s0,8(sp)
    80003f86:	0141                	addi	sp,sp,16
    80003f88:	8082                	ret

0000000080003f8a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f8a:	457c                	lw	a5,76(a0)
    80003f8c:	0ed7e963          	bltu	a5,a3,8000407e <readi+0xf4>
{
    80003f90:	7159                	addi	sp,sp,-112
    80003f92:	f486                	sd	ra,104(sp)
    80003f94:	f0a2                	sd	s0,96(sp)
    80003f96:	eca6                	sd	s1,88(sp)
    80003f98:	e8ca                	sd	s2,80(sp)
    80003f9a:	e4ce                	sd	s3,72(sp)
    80003f9c:	e0d2                	sd	s4,64(sp)
    80003f9e:	fc56                	sd	s5,56(sp)
    80003fa0:	f85a                	sd	s6,48(sp)
    80003fa2:	f45e                	sd	s7,40(sp)
    80003fa4:	f062                	sd	s8,32(sp)
    80003fa6:	ec66                	sd	s9,24(sp)
    80003fa8:	e86a                	sd	s10,16(sp)
    80003faa:	e46e                	sd	s11,8(sp)
    80003fac:	1880                	addi	s0,sp,112
    80003fae:	8b2a                	mv	s6,a0
    80003fb0:	8bae                	mv	s7,a1
    80003fb2:	8a32                	mv	s4,a2
    80003fb4:	84b6                	mv	s1,a3
    80003fb6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003fb8:	9f35                	addw	a4,a4,a3
    return 0;
    80003fba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fbc:	0ad76063          	bltu	a4,a3,8000405c <readi+0xd2>
  if(off + n > ip->size)
    80003fc0:	00e7f463          	bgeu	a5,a4,80003fc8 <readi+0x3e>
    n = ip->size - off;
    80003fc4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fc8:	0a0a8963          	beqz	s5,8000407a <readi+0xf0>
    80003fcc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fce:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fd2:	5c7d                	li	s8,-1
    80003fd4:	a82d                	j	8000400e <readi+0x84>
    80003fd6:	020d1d93          	slli	s11,s10,0x20
    80003fda:	020ddd93          	srli	s11,s11,0x20
    80003fde:	05890613          	addi	a2,s2,88
    80003fe2:	86ee                	mv	a3,s11
    80003fe4:	963a                	add	a2,a2,a4
    80003fe6:	85d2                	mv	a1,s4
    80003fe8:	855e                	mv	a0,s7
    80003fea:	ffffe097          	auipc	ra,0xffffe
    80003fee:	7de080e7          	jalr	2014(ra) # 800027c8 <either_copyout>
    80003ff2:	05850d63          	beq	a0,s8,8000404c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	5f6080e7          	jalr	1526(ra) # 800035ee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004000:	013d09bb          	addw	s3,s10,s3
    80004004:	009d04bb          	addw	s1,s10,s1
    80004008:	9a6e                	add	s4,s4,s11
    8000400a:	0559f763          	bgeu	s3,s5,80004058 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000400e:	00a4d59b          	srliw	a1,s1,0xa
    80004012:	855a                	mv	a0,s6
    80004014:	00000097          	auipc	ra,0x0
    80004018:	89e080e7          	jalr	-1890(ra) # 800038b2 <bmap>
    8000401c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004020:	cd85                	beqz	a1,80004058 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004022:	000b2503          	lw	a0,0(s6)
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	498080e7          	jalr	1176(ra) # 800034be <bread>
    8000402e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004030:	3ff4f713          	andi	a4,s1,1023
    80004034:	40ec87bb          	subw	a5,s9,a4
    80004038:	413a86bb          	subw	a3,s5,s3
    8000403c:	8d3e                	mv	s10,a5
    8000403e:	2781                	sext.w	a5,a5
    80004040:	0006861b          	sext.w	a2,a3
    80004044:	f8f679e3          	bgeu	a2,a5,80003fd6 <readi+0x4c>
    80004048:	8d36                	mv	s10,a3
    8000404a:	b771                	j	80003fd6 <readi+0x4c>
      brelse(bp);
    8000404c:	854a                	mv	a0,s2
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	5a0080e7          	jalr	1440(ra) # 800035ee <brelse>
      tot = -1;
    80004056:	59fd                	li	s3,-1
  }
  return tot;
    80004058:	0009851b          	sext.w	a0,s3
}
    8000405c:	70a6                	ld	ra,104(sp)
    8000405e:	7406                	ld	s0,96(sp)
    80004060:	64e6                	ld	s1,88(sp)
    80004062:	6946                	ld	s2,80(sp)
    80004064:	69a6                	ld	s3,72(sp)
    80004066:	6a06                	ld	s4,64(sp)
    80004068:	7ae2                	ld	s5,56(sp)
    8000406a:	7b42                	ld	s6,48(sp)
    8000406c:	7ba2                	ld	s7,40(sp)
    8000406e:	7c02                	ld	s8,32(sp)
    80004070:	6ce2                	ld	s9,24(sp)
    80004072:	6d42                	ld	s10,16(sp)
    80004074:	6da2                	ld	s11,8(sp)
    80004076:	6165                	addi	sp,sp,112
    80004078:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000407a:	89d6                	mv	s3,s5
    8000407c:	bff1                	j	80004058 <readi+0xce>
    return 0;
    8000407e:	4501                	li	a0,0
}
    80004080:	8082                	ret

0000000080004082 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004082:	457c                	lw	a5,76(a0)
    80004084:	10d7e863          	bltu	a5,a3,80004194 <writei+0x112>
{
    80004088:	7159                	addi	sp,sp,-112
    8000408a:	f486                	sd	ra,104(sp)
    8000408c:	f0a2                	sd	s0,96(sp)
    8000408e:	eca6                	sd	s1,88(sp)
    80004090:	e8ca                	sd	s2,80(sp)
    80004092:	e4ce                	sd	s3,72(sp)
    80004094:	e0d2                	sd	s4,64(sp)
    80004096:	fc56                	sd	s5,56(sp)
    80004098:	f85a                	sd	s6,48(sp)
    8000409a:	f45e                	sd	s7,40(sp)
    8000409c:	f062                	sd	s8,32(sp)
    8000409e:	ec66                	sd	s9,24(sp)
    800040a0:	e86a                	sd	s10,16(sp)
    800040a2:	e46e                	sd	s11,8(sp)
    800040a4:	1880                	addi	s0,sp,112
    800040a6:	8aaa                	mv	s5,a0
    800040a8:	8bae                	mv	s7,a1
    800040aa:	8a32                	mv	s4,a2
    800040ac:	8936                	mv	s2,a3
    800040ae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040b0:	00e687bb          	addw	a5,a3,a4
    800040b4:	0ed7e263          	bltu	a5,a3,80004198 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040b8:	00043737          	lui	a4,0x43
    800040bc:	0ef76063          	bltu	a4,a5,8000419c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040c0:	0c0b0863          	beqz	s6,80004190 <writei+0x10e>
    800040c4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040c6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040ca:	5c7d                	li	s8,-1
    800040cc:	a091                	j	80004110 <writei+0x8e>
    800040ce:	020d1d93          	slli	s11,s10,0x20
    800040d2:	020ddd93          	srli	s11,s11,0x20
    800040d6:	05848513          	addi	a0,s1,88
    800040da:	86ee                	mv	a3,s11
    800040dc:	8652                	mv	a2,s4
    800040de:	85de                	mv	a1,s7
    800040e0:	953a                	add	a0,a0,a4
    800040e2:	ffffe097          	auipc	ra,0xffffe
    800040e6:	73c080e7          	jalr	1852(ra) # 8000281e <either_copyin>
    800040ea:	07850263          	beq	a0,s8,8000414e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040ee:	8526                	mv	a0,s1
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	788080e7          	jalr	1928(ra) # 80004878 <log_write>
    brelse(bp);
    800040f8:	8526                	mv	a0,s1
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	4f4080e7          	jalr	1268(ra) # 800035ee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004102:	013d09bb          	addw	s3,s10,s3
    80004106:	012d093b          	addw	s2,s10,s2
    8000410a:	9a6e                	add	s4,s4,s11
    8000410c:	0569f663          	bgeu	s3,s6,80004158 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004110:	00a9559b          	srliw	a1,s2,0xa
    80004114:	8556                	mv	a0,s5
    80004116:	fffff097          	auipc	ra,0xfffff
    8000411a:	79c080e7          	jalr	1948(ra) # 800038b2 <bmap>
    8000411e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004122:	c99d                	beqz	a1,80004158 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004124:	000aa503          	lw	a0,0(s5)
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	396080e7          	jalr	918(ra) # 800034be <bread>
    80004130:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004132:	3ff97713          	andi	a4,s2,1023
    80004136:	40ec87bb          	subw	a5,s9,a4
    8000413a:	413b06bb          	subw	a3,s6,s3
    8000413e:	8d3e                	mv	s10,a5
    80004140:	2781                	sext.w	a5,a5
    80004142:	0006861b          	sext.w	a2,a3
    80004146:	f8f674e3          	bgeu	a2,a5,800040ce <writei+0x4c>
    8000414a:	8d36                	mv	s10,a3
    8000414c:	b749                	j	800040ce <writei+0x4c>
      brelse(bp);
    8000414e:	8526                	mv	a0,s1
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	49e080e7          	jalr	1182(ra) # 800035ee <brelse>
  }

  if(off > ip->size)
    80004158:	04caa783          	lw	a5,76(s5)
    8000415c:	0127f463          	bgeu	a5,s2,80004164 <writei+0xe2>
    ip->size = off;
    80004160:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004164:	8556                	mv	a0,s5
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	aa4080e7          	jalr	-1372(ra) # 80003c0a <iupdate>

  return tot;
    8000416e:	0009851b          	sext.w	a0,s3
}
    80004172:	70a6                	ld	ra,104(sp)
    80004174:	7406                	ld	s0,96(sp)
    80004176:	64e6                	ld	s1,88(sp)
    80004178:	6946                	ld	s2,80(sp)
    8000417a:	69a6                	ld	s3,72(sp)
    8000417c:	6a06                	ld	s4,64(sp)
    8000417e:	7ae2                	ld	s5,56(sp)
    80004180:	7b42                	ld	s6,48(sp)
    80004182:	7ba2                	ld	s7,40(sp)
    80004184:	7c02                	ld	s8,32(sp)
    80004186:	6ce2                	ld	s9,24(sp)
    80004188:	6d42                	ld	s10,16(sp)
    8000418a:	6da2                	ld	s11,8(sp)
    8000418c:	6165                	addi	sp,sp,112
    8000418e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004190:	89da                	mv	s3,s6
    80004192:	bfc9                	j	80004164 <writei+0xe2>
    return -1;
    80004194:	557d                	li	a0,-1
}
    80004196:	8082                	ret
    return -1;
    80004198:	557d                	li	a0,-1
    8000419a:	bfe1                	j	80004172 <writei+0xf0>
    return -1;
    8000419c:	557d                	li	a0,-1
    8000419e:	bfd1                	j	80004172 <writei+0xf0>

00000000800041a0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041a0:	1141                	addi	sp,sp,-16
    800041a2:	e406                	sd	ra,8(sp)
    800041a4:	e022                	sd	s0,0(sp)
    800041a6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041a8:	4639                	li	a2,14
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	cc0080e7          	jalr	-832(ra) # 80000e6a <strncmp>
}
    800041b2:	60a2                	ld	ra,8(sp)
    800041b4:	6402                	ld	s0,0(sp)
    800041b6:	0141                	addi	sp,sp,16
    800041b8:	8082                	ret

00000000800041ba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041ba:	7139                	addi	sp,sp,-64
    800041bc:	fc06                	sd	ra,56(sp)
    800041be:	f822                	sd	s0,48(sp)
    800041c0:	f426                	sd	s1,40(sp)
    800041c2:	f04a                	sd	s2,32(sp)
    800041c4:	ec4e                	sd	s3,24(sp)
    800041c6:	e852                	sd	s4,16(sp)
    800041c8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041ca:	04451703          	lh	a4,68(a0)
    800041ce:	4785                	li	a5,1
    800041d0:	00f71a63          	bne	a4,a5,800041e4 <dirlookup+0x2a>
    800041d4:	892a                	mv	s2,a0
    800041d6:	89ae                	mv	s3,a1
    800041d8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041da:	457c                	lw	a5,76(a0)
    800041dc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041de:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041e0:	e79d                	bnez	a5,8000420e <dirlookup+0x54>
    800041e2:	a8a5                	j	8000425a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041e4:	00004517          	auipc	a0,0x4
    800041e8:	5b450513          	addi	a0,a0,1460 # 80008798 <syscalls+0x1c8>
    800041ec:	ffffc097          	auipc	ra,0xffffc
    800041f0:	354080e7          	jalr	852(ra) # 80000540 <panic>
      panic("dirlookup read");
    800041f4:	00004517          	auipc	a0,0x4
    800041f8:	5bc50513          	addi	a0,a0,1468 # 800087b0 <syscalls+0x1e0>
    800041fc:	ffffc097          	auipc	ra,0xffffc
    80004200:	344080e7          	jalr	836(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004204:	24c1                	addiw	s1,s1,16
    80004206:	04c92783          	lw	a5,76(s2)
    8000420a:	04f4f763          	bgeu	s1,a5,80004258 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000420e:	4741                	li	a4,16
    80004210:	86a6                	mv	a3,s1
    80004212:	fc040613          	addi	a2,s0,-64
    80004216:	4581                	li	a1,0
    80004218:	854a                	mv	a0,s2
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	d70080e7          	jalr	-656(ra) # 80003f8a <readi>
    80004222:	47c1                	li	a5,16
    80004224:	fcf518e3          	bne	a0,a5,800041f4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004228:	fc045783          	lhu	a5,-64(s0)
    8000422c:	dfe1                	beqz	a5,80004204 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000422e:	fc240593          	addi	a1,s0,-62
    80004232:	854e                	mv	a0,s3
    80004234:	00000097          	auipc	ra,0x0
    80004238:	f6c080e7          	jalr	-148(ra) # 800041a0 <namecmp>
    8000423c:	f561                	bnez	a0,80004204 <dirlookup+0x4a>
      if(poff)
    8000423e:	000a0463          	beqz	s4,80004246 <dirlookup+0x8c>
        *poff = off;
    80004242:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004246:	fc045583          	lhu	a1,-64(s0)
    8000424a:	00092503          	lw	a0,0(s2)
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	74e080e7          	jalr	1870(ra) # 8000399c <iget>
    80004256:	a011                	j	8000425a <dirlookup+0xa0>
  return 0;
    80004258:	4501                	li	a0,0
}
    8000425a:	70e2                	ld	ra,56(sp)
    8000425c:	7442                	ld	s0,48(sp)
    8000425e:	74a2                	ld	s1,40(sp)
    80004260:	7902                	ld	s2,32(sp)
    80004262:	69e2                	ld	s3,24(sp)
    80004264:	6a42                	ld	s4,16(sp)
    80004266:	6121                	addi	sp,sp,64
    80004268:	8082                	ret

000000008000426a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000426a:	711d                	addi	sp,sp,-96
    8000426c:	ec86                	sd	ra,88(sp)
    8000426e:	e8a2                	sd	s0,80(sp)
    80004270:	e4a6                	sd	s1,72(sp)
    80004272:	e0ca                	sd	s2,64(sp)
    80004274:	fc4e                	sd	s3,56(sp)
    80004276:	f852                	sd	s4,48(sp)
    80004278:	f456                	sd	s5,40(sp)
    8000427a:	f05a                	sd	s6,32(sp)
    8000427c:	ec5e                	sd	s7,24(sp)
    8000427e:	e862                	sd	s8,16(sp)
    80004280:	e466                	sd	s9,8(sp)
    80004282:	e06a                	sd	s10,0(sp)
    80004284:	1080                	addi	s0,sp,96
    80004286:	84aa                	mv	s1,a0
    80004288:	8b2e                	mv	s6,a1
    8000428a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000428c:	00054703          	lbu	a4,0(a0)
    80004290:	02f00793          	li	a5,47
    80004294:	02f70363          	beq	a4,a5,800042ba <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004298:	ffffe097          	auipc	ra,0xffffe
    8000429c:	97a080e7          	jalr	-1670(ra) # 80001c12 <myproc>
    800042a0:	15053503          	ld	a0,336(a0)
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	9f4080e7          	jalr	-1548(ra) # 80003c98 <idup>
    800042ac:	8a2a                	mv	s4,a0
  while(*path == '/')
    800042ae:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800042b2:	4cb5                	li	s9,13
  len = path - s;
    800042b4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042b6:	4c05                	li	s8,1
    800042b8:	a87d                	j	80004376 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800042ba:	4585                	li	a1,1
    800042bc:	4505                	li	a0,1
    800042be:	fffff097          	auipc	ra,0xfffff
    800042c2:	6de080e7          	jalr	1758(ra) # 8000399c <iget>
    800042c6:	8a2a                	mv	s4,a0
    800042c8:	b7dd                	j	800042ae <namex+0x44>
      iunlockput(ip);
    800042ca:	8552                	mv	a0,s4
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	c6c080e7          	jalr	-916(ra) # 80003f38 <iunlockput>
      return 0;
    800042d4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042d6:	8552                	mv	a0,s4
    800042d8:	60e6                	ld	ra,88(sp)
    800042da:	6446                	ld	s0,80(sp)
    800042dc:	64a6                	ld	s1,72(sp)
    800042de:	6906                	ld	s2,64(sp)
    800042e0:	79e2                	ld	s3,56(sp)
    800042e2:	7a42                	ld	s4,48(sp)
    800042e4:	7aa2                	ld	s5,40(sp)
    800042e6:	7b02                	ld	s6,32(sp)
    800042e8:	6be2                	ld	s7,24(sp)
    800042ea:	6c42                	ld	s8,16(sp)
    800042ec:	6ca2                	ld	s9,8(sp)
    800042ee:	6d02                	ld	s10,0(sp)
    800042f0:	6125                	addi	sp,sp,96
    800042f2:	8082                	ret
      iunlock(ip);
    800042f4:	8552                	mv	a0,s4
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	aa2080e7          	jalr	-1374(ra) # 80003d98 <iunlock>
      return ip;
    800042fe:	bfe1                	j	800042d6 <namex+0x6c>
      iunlockput(ip);
    80004300:	8552                	mv	a0,s4
    80004302:	00000097          	auipc	ra,0x0
    80004306:	c36080e7          	jalr	-970(ra) # 80003f38 <iunlockput>
      return 0;
    8000430a:	8a4e                	mv	s4,s3
    8000430c:	b7e9                	j	800042d6 <namex+0x6c>
  len = path - s;
    8000430e:	40998633          	sub	a2,s3,s1
    80004312:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004316:	09acd863          	bge	s9,s10,800043a6 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000431a:	4639                	li	a2,14
    8000431c:	85a6                	mv	a1,s1
    8000431e:	8556                	mv	a0,s5
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	ad6080e7          	jalr	-1322(ra) # 80000df6 <memmove>
    80004328:	84ce                	mv	s1,s3
  while(*path == '/')
    8000432a:	0004c783          	lbu	a5,0(s1)
    8000432e:	01279763          	bne	a5,s2,8000433c <namex+0xd2>
    path++;
    80004332:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004334:	0004c783          	lbu	a5,0(s1)
    80004338:	ff278de3          	beq	a5,s2,80004332 <namex+0xc8>
    ilock(ip);
    8000433c:	8552                	mv	a0,s4
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	998080e7          	jalr	-1640(ra) # 80003cd6 <ilock>
    if(ip->type != T_DIR){
    80004346:	044a1783          	lh	a5,68(s4)
    8000434a:	f98790e3          	bne	a5,s8,800042ca <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000434e:	000b0563          	beqz	s6,80004358 <namex+0xee>
    80004352:	0004c783          	lbu	a5,0(s1)
    80004356:	dfd9                	beqz	a5,800042f4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004358:	865e                	mv	a2,s7
    8000435a:	85d6                	mv	a1,s5
    8000435c:	8552                	mv	a0,s4
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	e5c080e7          	jalr	-420(ra) # 800041ba <dirlookup>
    80004366:	89aa                	mv	s3,a0
    80004368:	dd41                	beqz	a0,80004300 <namex+0x96>
    iunlockput(ip);
    8000436a:	8552                	mv	a0,s4
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	bcc080e7          	jalr	-1076(ra) # 80003f38 <iunlockput>
    ip = next;
    80004374:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004376:	0004c783          	lbu	a5,0(s1)
    8000437a:	01279763          	bne	a5,s2,80004388 <namex+0x11e>
    path++;
    8000437e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004380:	0004c783          	lbu	a5,0(s1)
    80004384:	ff278de3          	beq	a5,s2,8000437e <namex+0x114>
  if(*path == 0)
    80004388:	cb9d                	beqz	a5,800043be <namex+0x154>
  while(*path != '/' && *path != 0)
    8000438a:	0004c783          	lbu	a5,0(s1)
    8000438e:	89a6                	mv	s3,s1
  len = path - s;
    80004390:	8d5e                	mv	s10,s7
    80004392:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004394:	01278963          	beq	a5,s2,800043a6 <namex+0x13c>
    80004398:	dbbd                	beqz	a5,8000430e <namex+0xa4>
    path++;
    8000439a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000439c:	0009c783          	lbu	a5,0(s3)
    800043a0:	ff279ce3          	bne	a5,s2,80004398 <namex+0x12e>
    800043a4:	b7ad                	j	8000430e <namex+0xa4>
    memmove(name, s, len);
    800043a6:	2601                	sext.w	a2,a2
    800043a8:	85a6                	mv	a1,s1
    800043aa:	8556                	mv	a0,s5
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	a4a080e7          	jalr	-1462(ra) # 80000df6 <memmove>
    name[len] = 0;
    800043b4:	9d56                	add	s10,s10,s5
    800043b6:	000d0023          	sb	zero,0(s10)
    800043ba:	84ce                	mv	s1,s3
    800043bc:	b7bd                	j	8000432a <namex+0xc0>
  if(nameiparent){
    800043be:	f00b0ce3          	beqz	s6,800042d6 <namex+0x6c>
    iput(ip);
    800043c2:	8552                	mv	a0,s4
    800043c4:	00000097          	auipc	ra,0x0
    800043c8:	acc080e7          	jalr	-1332(ra) # 80003e90 <iput>
    return 0;
    800043cc:	4a01                	li	s4,0
    800043ce:	b721                	j	800042d6 <namex+0x6c>

00000000800043d0 <dirlink>:
{
    800043d0:	7139                	addi	sp,sp,-64
    800043d2:	fc06                	sd	ra,56(sp)
    800043d4:	f822                	sd	s0,48(sp)
    800043d6:	f426                	sd	s1,40(sp)
    800043d8:	f04a                	sd	s2,32(sp)
    800043da:	ec4e                	sd	s3,24(sp)
    800043dc:	e852                	sd	s4,16(sp)
    800043de:	0080                	addi	s0,sp,64
    800043e0:	892a                	mv	s2,a0
    800043e2:	8a2e                	mv	s4,a1
    800043e4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043e6:	4601                	li	a2,0
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	dd2080e7          	jalr	-558(ra) # 800041ba <dirlookup>
    800043f0:	e93d                	bnez	a0,80004466 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043f2:	04c92483          	lw	s1,76(s2)
    800043f6:	c49d                	beqz	s1,80004424 <dirlink+0x54>
    800043f8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043fa:	4741                	li	a4,16
    800043fc:	86a6                	mv	a3,s1
    800043fe:	fc040613          	addi	a2,s0,-64
    80004402:	4581                	li	a1,0
    80004404:	854a                	mv	a0,s2
    80004406:	00000097          	auipc	ra,0x0
    8000440a:	b84080e7          	jalr	-1148(ra) # 80003f8a <readi>
    8000440e:	47c1                	li	a5,16
    80004410:	06f51163          	bne	a0,a5,80004472 <dirlink+0xa2>
    if(de.inum == 0)
    80004414:	fc045783          	lhu	a5,-64(s0)
    80004418:	c791                	beqz	a5,80004424 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000441a:	24c1                	addiw	s1,s1,16
    8000441c:	04c92783          	lw	a5,76(s2)
    80004420:	fcf4ede3          	bltu	s1,a5,800043fa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004424:	4639                	li	a2,14
    80004426:	85d2                	mv	a1,s4
    80004428:	fc240513          	addi	a0,s0,-62
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	a7a080e7          	jalr	-1414(ra) # 80000ea6 <strncpy>
  de.inum = inum;
    80004434:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004438:	4741                	li	a4,16
    8000443a:	86a6                	mv	a3,s1
    8000443c:	fc040613          	addi	a2,s0,-64
    80004440:	4581                	li	a1,0
    80004442:	854a                	mv	a0,s2
    80004444:	00000097          	auipc	ra,0x0
    80004448:	c3e080e7          	jalr	-962(ra) # 80004082 <writei>
    8000444c:	1541                	addi	a0,a0,-16
    8000444e:	00a03533          	snez	a0,a0
    80004452:	40a00533          	neg	a0,a0
}
    80004456:	70e2                	ld	ra,56(sp)
    80004458:	7442                	ld	s0,48(sp)
    8000445a:	74a2                	ld	s1,40(sp)
    8000445c:	7902                	ld	s2,32(sp)
    8000445e:	69e2                	ld	s3,24(sp)
    80004460:	6a42                	ld	s4,16(sp)
    80004462:	6121                	addi	sp,sp,64
    80004464:	8082                	ret
    iput(ip);
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	a2a080e7          	jalr	-1494(ra) # 80003e90 <iput>
    return -1;
    8000446e:	557d                	li	a0,-1
    80004470:	b7dd                	j	80004456 <dirlink+0x86>
      panic("dirlink read");
    80004472:	00004517          	auipc	a0,0x4
    80004476:	34e50513          	addi	a0,a0,846 # 800087c0 <syscalls+0x1f0>
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	0c6080e7          	jalr	198(ra) # 80000540 <panic>

0000000080004482 <namei>:

struct inode*
namei(char *path)
{
    80004482:	1101                	addi	sp,sp,-32
    80004484:	ec06                	sd	ra,24(sp)
    80004486:	e822                	sd	s0,16(sp)
    80004488:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000448a:	fe040613          	addi	a2,s0,-32
    8000448e:	4581                	li	a1,0
    80004490:	00000097          	auipc	ra,0x0
    80004494:	dda080e7          	jalr	-550(ra) # 8000426a <namex>
}
    80004498:	60e2                	ld	ra,24(sp)
    8000449a:	6442                	ld	s0,16(sp)
    8000449c:	6105                	addi	sp,sp,32
    8000449e:	8082                	ret

00000000800044a0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044a0:	1141                	addi	sp,sp,-16
    800044a2:	e406                	sd	ra,8(sp)
    800044a4:	e022                	sd	s0,0(sp)
    800044a6:	0800                	addi	s0,sp,16
    800044a8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044aa:	4585                	li	a1,1
    800044ac:	00000097          	auipc	ra,0x0
    800044b0:	dbe080e7          	jalr	-578(ra) # 8000426a <namex>
}
    800044b4:	60a2                	ld	ra,8(sp)
    800044b6:	6402                	ld	s0,0(sp)
    800044b8:	0141                	addi	sp,sp,16
    800044ba:	8082                	ret

00000000800044bc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044bc:	1101                	addi	sp,sp,-32
    800044be:	ec06                	sd	ra,24(sp)
    800044c0:	e822                	sd	s0,16(sp)
    800044c2:	e426                	sd	s1,8(sp)
    800044c4:	e04a                	sd	s2,0(sp)
    800044c6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044c8:	0001d917          	auipc	s2,0x1d
    800044cc:	84890913          	addi	s2,s2,-1976 # 80020d10 <log>
    800044d0:	01892583          	lw	a1,24(s2)
    800044d4:	02892503          	lw	a0,40(s2)
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	fe6080e7          	jalr	-26(ra) # 800034be <bread>
    800044e0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044e2:	02c92683          	lw	a3,44(s2)
    800044e6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044e8:	02d05863          	blez	a3,80004518 <write_head+0x5c>
    800044ec:	0001d797          	auipc	a5,0x1d
    800044f0:	85478793          	addi	a5,a5,-1964 # 80020d40 <log+0x30>
    800044f4:	05c50713          	addi	a4,a0,92
    800044f8:	36fd                	addiw	a3,a3,-1
    800044fa:	02069613          	slli	a2,a3,0x20
    800044fe:	01e65693          	srli	a3,a2,0x1e
    80004502:	0001d617          	auipc	a2,0x1d
    80004506:	84260613          	addi	a2,a2,-1982 # 80020d44 <log+0x34>
    8000450a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000450c:	4390                	lw	a2,0(a5)
    8000450e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004510:	0791                	addi	a5,a5,4
    80004512:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004514:	fed79ce3          	bne	a5,a3,8000450c <write_head+0x50>
  }
  bwrite(buf);
    80004518:	8526                	mv	a0,s1
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	096080e7          	jalr	150(ra) # 800035b0 <bwrite>
  brelse(buf);
    80004522:	8526                	mv	a0,s1
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	0ca080e7          	jalr	202(ra) # 800035ee <brelse>
}
    8000452c:	60e2                	ld	ra,24(sp)
    8000452e:	6442                	ld	s0,16(sp)
    80004530:	64a2                	ld	s1,8(sp)
    80004532:	6902                	ld	s2,0(sp)
    80004534:	6105                	addi	sp,sp,32
    80004536:	8082                	ret

0000000080004538 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004538:	0001d797          	auipc	a5,0x1d
    8000453c:	8047a783          	lw	a5,-2044(a5) # 80020d3c <log+0x2c>
    80004540:	0af05d63          	blez	a5,800045fa <install_trans+0xc2>
{
    80004544:	7139                	addi	sp,sp,-64
    80004546:	fc06                	sd	ra,56(sp)
    80004548:	f822                	sd	s0,48(sp)
    8000454a:	f426                	sd	s1,40(sp)
    8000454c:	f04a                	sd	s2,32(sp)
    8000454e:	ec4e                	sd	s3,24(sp)
    80004550:	e852                	sd	s4,16(sp)
    80004552:	e456                	sd	s5,8(sp)
    80004554:	e05a                	sd	s6,0(sp)
    80004556:	0080                	addi	s0,sp,64
    80004558:	8b2a                	mv	s6,a0
    8000455a:	0001ca97          	auipc	s5,0x1c
    8000455e:	7e6a8a93          	addi	s5,s5,2022 # 80020d40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004562:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004564:	0001c997          	auipc	s3,0x1c
    80004568:	7ac98993          	addi	s3,s3,1964 # 80020d10 <log>
    8000456c:	a00d                	j	8000458e <install_trans+0x56>
    brelse(lbuf);
    8000456e:	854a                	mv	a0,s2
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	07e080e7          	jalr	126(ra) # 800035ee <brelse>
    brelse(dbuf);
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	074080e7          	jalr	116(ra) # 800035ee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004582:	2a05                	addiw	s4,s4,1
    80004584:	0a91                	addi	s5,s5,4
    80004586:	02c9a783          	lw	a5,44(s3)
    8000458a:	04fa5e63          	bge	s4,a5,800045e6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000458e:	0189a583          	lw	a1,24(s3)
    80004592:	014585bb          	addw	a1,a1,s4
    80004596:	2585                	addiw	a1,a1,1
    80004598:	0289a503          	lw	a0,40(s3)
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	f22080e7          	jalr	-222(ra) # 800034be <bread>
    800045a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045a6:	000aa583          	lw	a1,0(s5)
    800045aa:	0289a503          	lw	a0,40(s3)
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	f10080e7          	jalr	-240(ra) # 800034be <bread>
    800045b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045b8:	40000613          	li	a2,1024
    800045bc:	05890593          	addi	a1,s2,88
    800045c0:	05850513          	addi	a0,a0,88
    800045c4:	ffffd097          	auipc	ra,0xffffd
    800045c8:	832080e7          	jalr	-1998(ra) # 80000df6 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045cc:	8526                	mv	a0,s1
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	fe2080e7          	jalr	-30(ra) # 800035b0 <bwrite>
    if(recovering == 0)
    800045d6:	f80b1ce3          	bnez	s6,8000456e <install_trans+0x36>
      bunpin(dbuf);
    800045da:	8526                	mv	a0,s1
    800045dc:	fffff097          	auipc	ra,0xfffff
    800045e0:	0ec080e7          	jalr	236(ra) # 800036c8 <bunpin>
    800045e4:	b769                	j	8000456e <install_trans+0x36>
}
    800045e6:	70e2                	ld	ra,56(sp)
    800045e8:	7442                	ld	s0,48(sp)
    800045ea:	74a2                	ld	s1,40(sp)
    800045ec:	7902                	ld	s2,32(sp)
    800045ee:	69e2                	ld	s3,24(sp)
    800045f0:	6a42                	ld	s4,16(sp)
    800045f2:	6aa2                	ld	s5,8(sp)
    800045f4:	6b02                	ld	s6,0(sp)
    800045f6:	6121                	addi	sp,sp,64
    800045f8:	8082                	ret
    800045fa:	8082                	ret

00000000800045fc <initlog>:
{
    800045fc:	7179                	addi	sp,sp,-48
    800045fe:	f406                	sd	ra,40(sp)
    80004600:	f022                	sd	s0,32(sp)
    80004602:	ec26                	sd	s1,24(sp)
    80004604:	e84a                	sd	s2,16(sp)
    80004606:	e44e                	sd	s3,8(sp)
    80004608:	1800                	addi	s0,sp,48
    8000460a:	892a                	mv	s2,a0
    8000460c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000460e:	0001c497          	auipc	s1,0x1c
    80004612:	70248493          	addi	s1,s1,1794 # 80020d10 <log>
    80004616:	00004597          	auipc	a1,0x4
    8000461a:	1ba58593          	addi	a1,a1,442 # 800087d0 <syscalls+0x200>
    8000461e:	8526                	mv	a0,s1
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	5ee080e7          	jalr	1518(ra) # 80000c0e <initlock>
  log.start = sb->logstart;
    80004628:	0149a583          	lw	a1,20(s3)
    8000462c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000462e:	0109a783          	lw	a5,16(s3)
    80004632:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004634:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004638:	854a                	mv	a0,s2
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	e84080e7          	jalr	-380(ra) # 800034be <bread>
  log.lh.n = lh->n;
    80004642:	4d34                	lw	a3,88(a0)
    80004644:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004646:	02d05663          	blez	a3,80004672 <initlog+0x76>
    8000464a:	05c50793          	addi	a5,a0,92
    8000464e:	0001c717          	auipc	a4,0x1c
    80004652:	6f270713          	addi	a4,a4,1778 # 80020d40 <log+0x30>
    80004656:	36fd                	addiw	a3,a3,-1
    80004658:	02069613          	slli	a2,a3,0x20
    8000465c:	01e65693          	srli	a3,a2,0x1e
    80004660:	06050613          	addi	a2,a0,96
    80004664:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004666:	4390                	lw	a2,0(a5)
    80004668:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000466a:	0791                	addi	a5,a5,4
    8000466c:	0711                	addi	a4,a4,4
    8000466e:	fed79ce3          	bne	a5,a3,80004666 <initlog+0x6a>
  brelse(buf);
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	f7c080e7          	jalr	-132(ra) # 800035ee <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000467a:	4505                	li	a0,1
    8000467c:	00000097          	auipc	ra,0x0
    80004680:	ebc080e7          	jalr	-324(ra) # 80004538 <install_trans>
  log.lh.n = 0;
    80004684:	0001c797          	auipc	a5,0x1c
    80004688:	6a07ac23          	sw	zero,1720(a5) # 80020d3c <log+0x2c>
  write_head(); // clear the log
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	e30080e7          	jalr	-464(ra) # 800044bc <write_head>
}
    80004694:	70a2                	ld	ra,40(sp)
    80004696:	7402                	ld	s0,32(sp)
    80004698:	64e2                	ld	s1,24(sp)
    8000469a:	6942                	ld	s2,16(sp)
    8000469c:	69a2                	ld	s3,8(sp)
    8000469e:	6145                	addi	sp,sp,48
    800046a0:	8082                	ret

00000000800046a2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046a2:	1101                	addi	sp,sp,-32
    800046a4:	ec06                	sd	ra,24(sp)
    800046a6:	e822                	sd	s0,16(sp)
    800046a8:	e426                	sd	s1,8(sp)
    800046aa:	e04a                	sd	s2,0(sp)
    800046ac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046ae:	0001c517          	auipc	a0,0x1c
    800046b2:	66250513          	addi	a0,a0,1634 # 80020d10 <log>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	5e8080e7          	jalr	1512(ra) # 80000c9e <acquire>
  while(1){
    if(log.committing){
    800046be:	0001c497          	auipc	s1,0x1c
    800046c2:	65248493          	addi	s1,s1,1618 # 80020d10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046c6:	4979                	li	s2,30
    800046c8:	a039                	j	800046d6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046ca:	85a6                	mv	a1,s1
    800046cc:	8526                	mv	a0,s1
    800046ce:	ffffe097          	auipc	ra,0xffffe
    800046d2:	cf2080e7          	jalr	-782(ra) # 800023c0 <sleep>
    if(log.committing){
    800046d6:	50dc                	lw	a5,36(s1)
    800046d8:	fbed                	bnez	a5,800046ca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046da:	5098                	lw	a4,32(s1)
    800046dc:	2705                	addiw	a4,a4,1
    800046de:	0007069b          	sext.w	a3,a4
    800046e2:	0027179b          	slliw	a5,a4,0x2
    800046e6:	9fb9                	addw	a5,a5,a4
    800046e8:	0017979b          	slliw	a5,a5,0x1
    800046ec:	54d8                	lw	a4,44(s1)
    800046ee:	9fb9                	addw	a5,a5,a4
    800046f0:	00f95963          	bge	s2,a5,80004702 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046f4:	85a6                	mv	a1,s1
    800046f6:	8526                	mv	a0,s1
    800046f8:	ffffe097          	auipc	ra,0xffffe
    800046fc:	cc8080e7          	jalr	-824(ra) # 800023c0 <sleep>
    80004700:	bfd9                	j	800046d6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004702:	0001c517          	auipc	a0,0x1c
    80004706:	60e50513          	addi	a0,a0,1550 # 80020d10 <log>
    8000470a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	646080e7          	jalr	1606(ra) # 80000d52 <release>
      break;
    }
  }
}
    80004714:	60e2                	ld	ra,24(sp)
    80004716:	6442                	ld	s0,16(sp)
    80004718:	64a2                	ld	s1,8(sp)
    8000471a:	6902                	ld	s2,0(sp)
    8000471c:	6105                	addi	sp,sp,32
    8000471e:	8082                	ret

0000000080004720 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004720:	7139                	addi	sp,sp,-64
    80004722:	fc06                	sd	ra,56(sp)
    80004724:	f822                	sd	s0,48(sp)
    80004726:	f426                	sd	s1,40(sp)
    80004728:	f04a                	sd	s2,32(sp)
    8000472a:	ec4e                	sd	s3,24(sp)
    8000472c:	e852                	sd	s4,16(sp)
    8000472e:	e456                	sd	s5,8(sp)
    80004730:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004732:	0001c497          	auipc	s1,0x1c
    80004736:	5de48493          	addi	s1,s1,1502 # 80020d10 <log>
    8000473a:	8526                	mv	a0,s1
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	562080e7          	jalr	1378(ra) # 80000c9e <acquire>
  log.outstanding -= 1;
    80004744:	509c                	lw	a5,32(s1)
    80004746:	37fd                	addiw	a5,a5,-1
    80004748:	0007891b          	sext.w	s2,a5
    8000474c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000474e:	50dc                	lw	a5,36(s1)
    80004750:	e7b9                	bnez	a5,8000479e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004752:	04091e63          	bnez	s2,800047ae <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004756:	0001c497          	auipc	s1,0x1c
    8000475a:	5ba48493          	addi	s1,s1,1466 # 80020d10 <log>
    8000475e:	4785                	li	a5,1
    80004760:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004762:	8526                	mv	a0,s1
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	5ee080e7          	jalr	1518(ra) # 80000d52 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000476c:	54dc                	lw	a5,44(s1)
    8000476e:	06f04763          	bgtz	a5,800047dc <end_op+0xbc>
    acquire(&log.lock);
    80004772:	0001c497          	auipc	s1,0x1c
    80004776:	59e48493          	addi	s1,s1,1438 # 80020d10 <log>
    8000477a:	8526                	mv	a0,s1
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	522080e7          	jalr	1314(ra) # 80000c9e <acquire>
    log.committing = 0;
    80004784:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004788:	8526                	mv	a0,s1
    8000478a:	ffffe097          	auipc	ra,0xffffe
    8000478e:	c9a080e7          	jalr	-870(ra) # 80002424 <wakeup>
    release(&log.lock);
    80004792:	8526                	mv	a0,s1
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	5be080e7          	jalr	1470(ra) # 80000d52 <release>
}
    8000479c:	a03d                	j	800047ca <end_op+0xaa>
    panic("log.committing");
    8000479e:	00004517          	auipc	a0,0x4
    800047a2:	03a50513          	addi	a0,a0,58 # 800087d8 <syscalls+0x208>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	d9a080e7          	jalr	-614(ra) # 80000540 <panic>
    wakeup(&log);
    800047ae:	0001c497          	auipc	s1,0x1c
    800047b2:	56248493          	addi	s1,s1,1378 # 80020d10 <log>
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffe097          	auipc	ra,0xffffe
    800047bc:	c6c080e7          	jalr	-916(ra) # 80002424 <wakeup>
  release(&log.lock);
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	590080e7          	jalr	1424(ra) # 80000d52 <release>
}
    800047ca:	70e2                	ld	ra,56(sp)
    800047cc:	7442                	ld	s0,48(sp)
    800047ce:	74a2                	ld	s1,40(sp)
    800047d0:	7902                	ld	s2,32(sp)
    800047d2:	69e2                	ld	s3,24(sp)
    800047d4:	6a42                	ld	s4,16(sp)
    800047d6:	6aa2                	ld	s5,8(sp)
    800047d8:	6121                	addi	sp,sp,64
    800047da:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800047dc:	0001ca97          	auipc	s5,0x1c
    800047e0:	564a8a93          	addi	s5,s5,1380 # 80020d40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047e4:	0001ca17          	auipc	s4,0x1c
    800047e8:	52ca0a13          	addi	s4,s4,1324 # 80020d10 <log>
    800047ec:	018a2583          	lw	a1,24(s4)
    800047f0:	012585bb          	addw	a1,a1,s2
    800047f4:	2585                	addiw	a1,a1,1
    800047f6:	028a2503          	lw	a0,40(s4)
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	cc4080e7          	jalr	-828(ra) # 800034be <bread>
    80004802:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004804:	000aa583          	lw	a1,0(s5)
    80004808:	028a2503          	lw	a0,40(s4)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	cb2080e7          	jalr	-846(ra) # 800034be <bread>
    80004814:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004816:	40000613          	li	a2,1024
    8000481a:	05850593          	addi	a1,a0,88
    8000481e:	05848513          	addi	a0,s1,88
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	5d4080e7          	jalr	1492(ra) # 80000df6 <memmove>
    bwrite(to);  // write the log
    8000482a:	8526                	mv	a0,s1
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	d84080e7          	jalr	-636(ra) # 800035b0 <bwrite>
    brelse(from);
    80004834:	854e                	mv	a0,s3
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	db8080e7          	jalr	-584(ra) # 800035ee <brelse>
    brelse(to);
    8000483e:	8526                	mv	a0,s1
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	dae080e7          	jalr	-594(ra) # 800035ee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004848:	2905                	addiw	s2,s2,1
    8000484a:	0a91                	addi	s5,s5,4
    8000484c:	02ca2783          	lw	a5,44(s4)
    80004850:	f8f94ee3          	blt	s2,a5,800047ec <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004854:	00000097          	auipc	ra,0x0
    80004858:	c68080e7          	jalr	-920(ra) # 800044bc <write_head>
    install_trans(0); // Now install writes to home locations
    8000485c:	4501                	li	a0,0
    8000485e:	00000097          	auipc	ra,0x0
    80004862:	cda080e7          	jalr	-806(ra) # 80004538 <install_trans>
    log.lh.n = 0;
    80004866:	0001c797          	auipc	a5,0x1c
    8000486a:	4c07ab23          	sw	zero,1238(a5) # 80020d3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000486e:	00000097          	auipc	ra,0x0
    80004872:	c4e080e7          	jalr	-946(ra) # 800044bc <write_head>
    80004876:	bdf5                	j	80004772 <end_op+0x52>

0000000080004878 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004878:	1101                	addi	sp,sp,-32
    8000487a:	ec06                	sd	ra,24(sp)
    8000487c:	e822                	sd	s0,16(sp)
    8000487e:	e426                	sd	s1,8(sp)
    80004880:	e04a                	sd	s2,0(sp)
    80004882:	1000                	addi	s0,sp,32
    80004884:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004886:	0001c917          	auipc	s2,0x1c
    8000488a:	48a90913          	addi	s2,s2,1162 # 80020d10 <log>
    8000488e:	854a                	mv	a0,s2
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	40e080e7          	jalr	1038(ra) # 80000c9e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004898:	02c92603          	lw	a2,44(s2)
    8000489c:	47f5                	li	a5,29
    8000489e:	06c7c563          	blt	a5,a2,80004908 <log_write+0x90>
    800048a2:	0001c797          	auipc	a5,0x1c
    800048a6:	48a7a783          	lw	a5,1162(a5) # 80020d2c <log+0x1c>
    800048aa:	37fd                	addiw	a5,a5,-1
    800048ac:	04f65e63          	bge	a2,a5,80004908 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048b0:	0001c797          	auipc	a5,0x1c
    800048b4:	4807a783          	lw	a5,1152(a5) # 80020d30 <log+0x20>
    800048b8:	06f05063          	blez	a5,80004918 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048bc:	4781                	li	a5,0
    800048be:	06c05563          	blez	a2,80004928 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048c2:	44cc                	lw	a1,12(s1)
    800048c4:	0001c717          	auipc	a4,0x1c
    800048c8:	47c70713          	addi	a4,a4,1148 # 80020d40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048cc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048ce:	4314                	lw	a3,0(a4)
    800048d0:	04b68c63          	beq	a3,a1,80004928 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048d4:	2785                	addiw	a5,a5,1
    800048d6:	0711                	addi	a4,a4,4
    800048d8:	fef61be3          	bne	a2,a5,800048ce <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048dc:	0621                	addi	a2,a2,8
    800048de:	060a                	slli	a2,a2,0x2
    800048e0:	0001c797          	auipc	a5,0x1c
    800048e4:	43078793          	addi	a5,a5,1072 # 80020d10 <log>
    800048e8:	97b2                	add	a5,a5,a2
    800048ea:	44d8                	lw	a4,12(s1)
    800048ec:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048ee:	8526                	mv	a0,s1
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	d9c080e7          	jalr	-612(ra) # 8000368c <bpin>
    log.lh.n++;
    800048f8:	0001c717          	auipc	a4,0x1c
    800048fc:	41870713          	addi	a4,a4,1048 # 80020d10 <log>
    80004900:	575c                	lw	a5,44(a4)
    80004902:	2785                	addiw	a5,a5,1
    80004904:	d75c                	sw	a5,44(a4)
    80004906:	a82d                	j	80004940 <log_write+0xc8>
    panic("too big a transaction");
    80004908:	00004517          	auipc	a0,0x4
    8000490c:	ee050513          	addi	a0,a0,-288 # 800087e8 <syscalls+0x218>
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	c30080e7          	jalr	-976(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004918:	00004517          	auipc	a0,0x4
    8000491c:	ee850513          	addi	a0,a0,-280 # 80008800 <syscalls+0x230>
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	c20080e7          	jalr	-992(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004928:	00878693          	addi	a3,a5,8
    8000492c:	068a                	slli	a3,a3,0x2
    8000492e:	0001c717          	auipc	a4,0x1c
    80004932:	3e270713          	addi	a4,a4,994 # 80020d10 <log>
    80004936:	9736                	add	a4,a4,a3
    80004938:	44d4                	lw	a3,12(s1)
    8000493a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000493c:	faf609e3          	beq	a2,a5,800048ee <log_write+0x76>
  }
  release(&log.lock);
    80004940:	0001c517          	auipc	a0,0x1c
    80004944:	3d050513          	addi	a0,a0,976 # 80020d10 <log>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	40a080e7          	jalr	1034(ra) # 80000d52 <release>
}
    80004950:	60e2                	ld	ra,24(sp)
    80004952:	6442                	ld	s0,16(sp)
    80004954:	64a2                	ld	s1,8(sp)
    80004956:	6902                	ld	s2,0(sp)
    80004958:	6105                	addi	sp,sp,32
    8000495a:	8082                	ret

000000008000495c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000495c:	1101                	addi	sp,sp,-32
    8000495e:	ec06                	sd	ra,24(sp)
    80004960:	e822                	sd	s0,16(sp)
    80004962:	e426                	sd	s1,8(sp)
    80004964:	e04a                	sd	s2,0(sp)
    80004966:	1000                	addi	s0,sp,32
    80004968:	84aa                	mv	s1,a0
    8000496a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000496c:	00004597          	auipc	a1,0x4
    80004970:	eb458593          	addi	a1,a1,-332 # 80008820 <syscalls+0x250>
    80004974:	0521                	addi	a0,a0,8
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	298080e7          	jalr	664(ra) # 80000c0e <initlock>
  lk->name = name;
    8000497e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004982:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004986:	0204a423          	sw	zero,40(s1)
}
    8000498a:	60e2                	ld	ra,24(sp)
    8000498c:	6442                	ld	s0,16(sp)
    8000498e:	64a2                	ld	s1,8(sp)
    80004990:	6902                	ld	s2,0(sp)
    80004992:	6105                	addi	sp,sp,32
    80004994:	8082                	ret

0000000080004996 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004996:	1101                	addi	sp,sp,-32
    80004998:	ec06                	sd	ra,24(sp)
    8000499a:	e822                	sd	s0,16(sp)
    8000499c:	e426                	sd	s1,8(sp)
    8000499e:	e04a                	sd	s2,0(sp)
    800049a0:	1000                	addi	s0,sp,32
    800049a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049a4:	00850913          	addi	s2,a0,8
    800049a8:	854a                	mv	a0,s2
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	2f4080e7          	jalr	756(ra) # 80000c9e <acquire>
  while (lk->locked) {
    800049b2:	409c                	lw	a5,0(s1)
    800049b4:	cb89                	beqz	a5,800049c6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049b6:	85ca                	mv	a1,s2
    800049b8:	8526                	mv	a0,s1
    800049ba:	ffffe097          	auipc	ra,0xffffe
    800049be:	a06080e7          	jalr	-1530(ra) # 800023c0 <sleep>
  while (lk->locked) {
    800049c2:	409c                	lw	a5,0(s1)
    800049c4:	fbed                	bnez	a5,800049b6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049c6:	4785                	li	a5,1
    800049c8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049ca:	ffffd097          	auipc	ra,0xffffd
    800049ce:	248080e7          	jalr	584(ra) # 80001c12 <myproc>
    800049d2:	591c                	lw	a5,48(a0)
    800049d4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049d6:	854a                	mv	a0,s2
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	37a080e7          	jalr	890(ra) # 80000d52 <release>
}
    800049e0:	60e2                	ld	ra,24(sp)
    800049e2:	6442                	ld	s0,16(sp)
    800049e4:	64a2                	ld	s1,8(sp)
    800049e6:	6902                	ld	s2,0(sp)
    800049e8:	6105                	addi	sp,sp,32
    800049ea:	8082                	ret

00000000800049ec <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049ec:	1101                	addi	sp,sp,-32
    800049ee:	ec06                	sd	ra,24(sp)
    800049f0:	e822                	sd	s0,16(sp)
    800049f2:	e426                	sd	s1,8(sp)
    800049f4:	e04a                	sd	s2,0(sp)
    800049f6:	1000                	addi	s0,sp,32
    800049f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049fa:	00850913          	addi	s2,a0,8
    800049fe:	854a                	mv	a0,s2
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	29e080e7          	jalr	670(ra) # 80000c9e <acquire>
  lk->locked = 0;
    80004a08:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a0c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a10:	8526                	mv	a0,s1
    80004a12:	ffffe097          	auipc	ra,0xffffe
    80004a16:	a12080e7          	jalr	-1518(ra) # 80002424 <wakeup>
  release(&lk->lk);
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	336080e7          	jalr	822(ra) # 80000d52 <release>
}
    80004a24:	60e2                	ld	ra,24(sp)
    80004a26:	6442                	ld	s0,16(sp)
    80004a28:	64a2                	ld	s1,8(sp)
    80004a2a:	6902                	ld	s2,0(sp)
    80004a2c:	6105                	addi	sp,sp,32
    80004a2e:	8082                	ret

0000000080004a30 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a30:	7179                	addi	sp,sp,-48
    80004a32:	f406                	sd	ra,40(sp)
    80004a34:	f022                	sd	s0,32(sp)
    80004a36:	ec26                	sd	s1,24(sp)
    80004a38:	e84a                	sd	s2,16(sp)
    80004a3a:	e44e                	sd	s3,8(sp)
    80004a3c:	1800                	addi	s0,sp,48
    80004a3e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a40:	00850913          	addi	s2,a0,8
    80004a44:	854a                	mv	a0,s2
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	258080e7          	jalr	600(ra) # 80000c9e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a4e:	409c                	lw	a5,0(s1)
    80004a50:	ef99                	bnez	a5,80004a6e <holdingsleep+0x3e>
    80004a52:	4481                	li	s1,0
  release(&lk->lk);
    80004a54:	854a                	mv	a0,s2
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	2fc080e7          	jalr	764(ra) # 80000d52 <release>
  return r;
}
    80004a5e:	8526                	mv	a0,s1
    80004a60:	70a2                	ld	ra,40(sp)
    80004a62:	7402                	ld	s0,32(sp)
    80004a64:	64e2                	ld	s1,24(sp)
    80004a66:	6942                	ld	s2,16(sp)
    80004a68:	69a2                	ld	s3,8(sp)
    80004a6a:	6145                	addi	sp,sp,48
    80004a6c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a6e:	0284a983          	lw	s3,40(s1)
    80004a72:	ffffd097          	auipc	ra,0xffffd
    80004a76:	1a0080e7          	jalr	416(ra) # 80001c12 <myproc>
    80004a7a:	5904                	lw	s1,48(a0)
    80004a7c:	413484b3          	sub	s1,s1,s3
    80004a80:	0014b493          	seqz	s1,s1
    80004a84:	bfc1                	j	80004a54 <holdingsleep+0x24>

0000000080004a86 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a86:	1141                	addi	sp,sp,-16
    80004a88:	e406                	sd	ra,8(sp)
    80004a8a:	e022                	sd	s0,0(sp)
    80004a8c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a8e:	00004597          	auipc	a1,0x4
    80004a92:	da258593          	addi	a1,a1,-606 # 80008830 <syscalls+0x260>
    80004a96:	0001c517          	auipc	a0,0x1c
    80004a9a:	3c250513          	addi	a0,a0,962 # 80020e58 <ftable>
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	170080e7          	jalr	368(ra) # 80000c0e <initlock>
}
    80004aa6:	60a2                	ld	ra,8(sp)
    80004aa8:	6402                	ld	s0,0(sp)
    80004aaa:	0141                	addi	sp,sp,16
    80004aac:	8082                	ret

0000000080004aae <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004aae:	1101                	addi	sp,sp,-32
    80004ab0:	ec06                	sd	ra,24(sp)
    80004ab2:	e822                	sd	s0,16(sp)
    80004ab4:	e426                	sd	s1,8(sp)
    80004ab6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ab8:	0001c517          	auipc	a0,0x1c
    80004abc:	3a050513          	addi	a0,a0,928 # 80020e58 <ftable>
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	1de080e7          	jalr	478(ra) # 80000c9e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ac8:	0001c497          	auipc	s1,0x1c
    80004acc:	3a848493          	addi	s1,s1,936 # 80020e70 <ftable+0x18>
    80004ad0:	0001d717          	auipc	a4,0x1d
    80004ad4:	34070713          	addi	a4,a4,832 # 80021e10 <disk>
    if(f->ref == 0){
    80004ad8:	40dc                	lw	a5,4(s1)
    80004ada:	cf99                	beqz	a5,80004af8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004adc:	02848493          	addi	s1,s1,40
    80004ae0:	fee49ce3          	bne	s1,a4,80004ad8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ae4:	0001c517          	auipc	a0,0x1c
    80004ae8:	37450513          	addi	a0,a0,884 # 80020e58 <ftable>
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	266080e7          	jalr	614(ra) # 80000d52 <release>
  return 0;
    80004af4:	4481                	li	s1,0
    80004af6:	a819                	j	80004b0c <filealloc+0x5e>
      f->ref = 1;
    80004af8:	4785                	li	a5,1
    80004afa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004afc:	0001c517          	auipc	a0,0x1c
    80004b00:	35c50513          	addi	a0,a0,860 # 80020e58 <ftable>
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	24e080e7          	jalr	590(ra) # 80000d52 <release>
}
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	60e2                	ld	ra,24(sp)
    80004b10:	6442                	ld	s0,16(sp)
    80004b12:	64a2                	ld	s1,8(sp)
    80004b14:	6105                	addi	sp,sp,32
    80004b16:	8082                	ret

0000000080004b18 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b18:	1101                	addi	sp,sp,-32
    80004b1a:	ec06                	sd	ra,24(sp)
    80004b1c:	e822                	sd	s0,16(sp)
    80004b1e:	e426                	sd	s1,8(sp)
    80004b20:	1000                	addi	s0,sp,32
    80004b22:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b24:	0001c517          	auipc	a0,0x1c
    80004b28:	33450513          	addi	a0,a0,820 # 80020e58 <ftable>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	172080e7          	jalr	370(ra) # 80000c9e <acquire>
  if(f->ref < 1)
    80004b34:	40dc                	lw	a5,4(s1)
    80004b36:	02f05263          	blez	a5,80004b5a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b3a:	2785                	addiw	a5,a5,1
    80004b3c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b3e:	0001c517          	auipc	a0,0x1c
    80004b42:	31a50513          	addi	a0,a0,794 # 80020e58 <ftable>
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	20c080e7          	jalr	524(ra) # 80000d52 <release>
  return f;
}
    80004b4e:	8526                	mv	a0,s1
    80004b50:	60e2                	ld	ra,24(sp)
    80004b52:	6442                	ld	s0,16(sp)
    80004b54:	64a2                	ld	s1,8(sp)
    80004b56:	6105                	addi	sp,sp,32
    80004b58:	8082                	ret
    panic("filedup");
    80004b5a:	00004517          	auipc	a0,0x4
    80004b5e:	cde50513          	addi	a0,a0,-802 # 80008838 <syscalls+0x268>
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	9de080e7          	jalr	-1570(ra) # 80000540 <panic>

0000000080004b6a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b6a:	7139                	addi	sp,sp,-64
    80004b6c:	fc06                	sd	ra,56(sp)
    80004b6e:	f822                	sd	s0,48(sp)
    80004b70:	f426                	sd	s1,40(sp)
    80004b72:	f04a                	sd	s2,32(sp)
    80004b74:	ec4e                	sd	s3,24(sp)
    80004b76:	e852                	sd	s4,16(sp)
    80004b78:	e456                	sd	s5,8(sp)
    80004b7a:	0080                	addi	s0,sp,64
    80004b7c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b7e:	0001c517          	auipc	a0,0x1c
    80004b82:	2da50513          	addi	a0,a0,730 # 80020e58 <ftable>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	118080e7          	jalr	280(ra) # 80000c9e <acquire>
  if(f->ref < 1)
    80004b8e:	40dc                	lw	a5,4(s1)
    80004b90:	06f05163          	blez	a5,80004bf2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b94:	37fd                	addiw	a5,a5,-1
    80004b96:	0007871b          	sext.w	a4,a5
    80004b9a:	c0dc                	sw	a5,4(s1)
    80004b9c:	06e04363          	bgtz	a4,80004c02 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ba0:	0004a903          	lw	s2,0(s1)
    80004ba4:	0094ca83          	lbu	s5,9(s1)
    80004ba8:	0104ba03          	ld	s4,16(s1)
    80004bac:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bb0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bb4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bb8:	0001c517          	auipc	a0,0x1c
    80004bbc:	2a050513          	addi	a0,a0,672 # 80020e58 <ftable>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	192080e7          	jalr	402(ra) # 80000d52 <release>

  if(ff.type == FD_PIPE){
    80004bc8:	4785                	li	a5,1
    80004bca:	04f90d63          	beq	s2,a5,80004c24 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bce:	3979                	addiw	s2,s2,-2
    80004bd0:	4785                	li	a5,1
    80004bd2:	0527e063          	bltu	a5,s2,80004c12 <fileclose+0xa8>
    begin_op();
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	acc080e7          	jalr	-1332(ra) # 800046a2 <begin_op>
    iput(ff.ip);
    80004bde:	854e                	mv	a0,s3
    80004be0:	fffff097          	auipc	ra,0xfffff
    80004be4:	2b0080e7          	jalr	688(ra) # 80003e90 <iput>
    end_op();
    80004be8:	00000097          	auipc	ra,0x0
    80004bec:	b38080e7          	jalr	-1224(ra) # 80004720 <end_op>
    80004bf0:	a00d                	j	80004c12 <fileclose+0xa8>
    panic("fileclose");
    80004bf2:	00004517          	auipc	a0,0x4
    80004bf6:	c4e50513          	addi	a0,a0,-946 # 80008840 <syscalls+0x270>
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	946080e7          	jalr	-1722(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004c02:	0001c517          	auipc	a0,0x1c
    80004c06:	25650513          	addi	a0,a0,598 # 80020e58 <ftable>
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	148080e7          	jalr	328(ra) # 80000d52 <release>
  }
}
    80004c12:	70e2                	ld	ra,56(sp)
    80004c14:	7442                	ld	s0,48(sp)
    80004c16:	74a2                	ld	s1,40(sp)
    80004c18:	7902                	ld	s2,32(sp)
    80004c1a:	69e2                	ld	s3,24(sp)
    80004c1c:	6a42                	ld	s4,16(sp)
    80004c1e:	6aa2                	ld	s5,8(sp)
    80004c20:	6121                	addi	sp,sp,64
    80004c22:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c24:	85d6                	mv	a1,s5
    80004c26:	8552                	mv	a0,s4
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	34c080e7          	jalr	844(ra) # 80004f74 <pipeclose>
    80004c30:	b7cd                	j	80004c12 <fileclose+0xa8>

0000000080004c32 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c32:	715d                	addi	sp,sp,-80
    80004c34:	e486                	sd	ra,72(sp)
    80004c36:	e0a2                	sd	s0,64(sp)
    80004c38:	fc26                	sd	s1,56(sp)
    80004c3a:	f84a                	sd	s2,48(sp)
    80004c3c:	f44e                	sd	s3,40(sp)
    80004c3e:	0880                	addi	s0,sp,80
    80004c40:	84aa                	mv	s1,a0
    80004c42:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	fce080e7          	jalr	-50(ra) # 80001c12 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c4c:	409c                	lw	a5,0(s1)
    80004c4e:	37f9                	addiw	a5,a5,-2
    80004c50:	4705                	li	a4,1
    80004c52:	04f76763          	bltu	a4,a5,80004ca0 <filestat+0x6e>
    80004c56:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c58:	6c88                	ld	a0,24(s1)
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	07c080e7          	jalr	124(ra) # 80003cd6 <ilock>
    stati(f->ip, &st);
    80004c62:	fb840593          	addi	a1,s0,-72
    80004c66:	6c88                	ld	a0,24(s1)
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	2f8080e7          	jalr	760(ra) # 80003f60 <stati>
    iunlock(f->ip);
    80004c70:	6c88                	ld	a0,24(s1)
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	126080e7          	jalr	294(ra) # 80003d98 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c7a:	46e1                	li	a3,24
    80004c7c:	fb840613          	addi	a2,s0,-72
    80004c80:	85ce                	mv	a1,s3
    80004c82:	05093503          	ld	a0,80(s2)
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	b4e080e7          	jalr	-1202(ra) # 800017d4 <copyout>
    80004c8e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c92:	60a6                	ld	ra,72(sp)
    80004c94:	6406                	ld	s0,64(sp)
    80004c96:	74e2                	ld	s1,56(sp)
    80004c98:	7942                	ld	s2,48(sp)
    80004c9a:	79a2                	ld	s3,40(sp)
    80004c9c:	6161                	addi	sp,sp,80
    80004c9e:	8082                	ret
  return -1;
    80004ca0:	557d                	li	a0,-1
    80004ca2:	bfc5                	j	80004c92 <filestat+0x60>

0000000080004ca4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ca4:	7179                	addi	sp,sp,-48
    80004ca6:	f406                	sd	ra,40(sp)
    80004ca8:	f022                	sd	s0,32(sp)
    80004caa:	ec26                	sd	s1,24(sp)
    80004cac:	e84a                	sd	s2,16(sp)
    80004cae:	e44e                	sd	s3,8(sp)
    80004cb0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cb2:	00854783          	lbu	a5,8(a0)
    80004cb6:	c3d5                	beqz	a5,80004d5a <fileread+0xb6>
    80004cb8:	84aa                	mv	s1,a0
    80004cba:	89ae                	mv	s3,a1
    80004cbc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cbe:	411c                	lw	a5,0(a0)
    80004cc0:	4705                	li	a4,1
    80004cc2:	04e78963          	beq	a5,a4,80004d14 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cc6:	470d                	li	a4,3
    80004cc8:	04e78d63          	beq	a5,a4,80004d22 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ccc:	4709                	li	a4,2
    80004cce:	06e79e63          	bne	a5,a4,80004d4a <fileread+0xa6>
    ilock(f->ip);
    80004cd2:	6d08                	ld	a0,24(a0)
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	002080e7          	jalr	2(ra) # 80003cd6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cdc:	874a                	mv	a4,s2
    80004cde:	5094                	lw	a3,32(s1)
    80004ce0:	864e                	mv	a2,s3
    80004ce2:	4585                	li	a1,1
    80004ce4:	6c88                	ld	a0,24(s1)
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	2a4080e7          	jalr	676(ra) # 80003f8a <readi>
    80004cee:	892a                	mv	s2,a0
    80004cf0:	00a05563          	blez	a0,80004cfa <fileread+0x56>
      f->off += r;
    80004cf4:	509c                	lw	a5,32(s1)
    80004cf6:	9fa9                	addw	a5,a5,a0
    80004cf8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cfa:	6c88                	ld	a0,24(s1)
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	09c080e7          	jalr	156(ra) # 80003d98 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d04:	854a                	mv	a0,s2
    80004d06:	70a2                	ld	ra,40(sp)
    80004d08:	7402                	ld	s0,32(sp)
    80004d0a:	64e2                	ld	s1,24(sp)
    80004d0c:	6942                	ld	s2,16(sp)
    80004d0e:	69a2                	ld	s3,8(sp)
    80004d10:	6145                	addi	sp,sp,48
    80004d12:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d14:	6908                	ld	a0,16(a0)
    80004d16:	00000097          	auipc	ra,0x0
    80004d1a:	3c6080e7          	jalr	966(ra) # 800050dc <piperead>
    80004d1e:	892a                	mv	s2,a0
    80004d20:	b7d5                	j	80004d04 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d22:	02451783          	lh	a5,36(a0)
    80004d26:	03079693          	slli	a3,a5,0x30
    80004d2a:	92c1                	srli	a3,a3,0x30
    80004d2c:	4725                	li	a4,9
    80004d2e:	02d76863          	bltu	a4,a3,80004d5e <fileread+0xba>
    80004d32:	0792                	slli	a5,a5,0x4
    80004d34:	0001c717          	auipc	a4,0x1c
    80004d38:	08470713          	addi	a4,a4,132 # 80020db8 <devsw>
    80004d3c:	97ba                	add	a5,a5,a4
    80004d3e:	639c                	ld	a5,0(a5)
    80004d40:	c38d                	beqz	a5,80004d62 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d42:	4505                	li	a0,1
    80004d44:	9782                	jalr	a5
    80004d46:	892a                	mv	s2,a0
    80004d48:	bf75                	j	80004d04 <fileread+0x60>
    panic("fileread");
    80004d4a:	00004517          	auipc	a0,0x4
    80004d4e:	b0650513          	addi	a0,a0,-1274 # 80008850 <syscalls+0x280>
    80004d52:	ffffb097          	auipc	ra,0xffffb
    80004d56:	7ee080e7          	jalr	2030(ra) # 80000540 <panic>
    return -1;
    80004d5a:	597d                	li	s2,-1
    80004d5c:	b765                	j	80004d04 <fileread+0x60>
      return -1;
    80004d5e:	597d                	li	s2,-1
    80004d60:	b755                	j	80004d04 <fileread+0x60>
    80004d62:	597d                	li	s2,-1
    80004d64:	b745                	j	80004d04 <fileread+0x60>

0000000080004d66 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d66:	715d                	addi	sp,sp,-80
    80004d68:	e486                	sd	ra,72(sp)
    80004d6a:	e0a2                	sd	s0,64(sp)
    80004d6c:	fc26                	sd	s1,56(sp)
    80004d6e:	f84a                	sd	s2,48(sp)
    80004d70:	f44e                	sd	s3,40(sp)
    80004d72:	f052                	sd	s4,32(sp)
    80004d74:	ec56                	sd	s5,24(sp)
    80004d76:	e85a                	sd	s6,16(sp)
    80004d78:	e45e                	sd	s7,8(sp)
    80004d7a:	e062                	sd	s8,0(sp)
    80004d7c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d7e:	00954783          	lbu	a5,9(a0)
    80004d82:	10078663          	beqz	a5,80004e8e <filewrite+0x128>
    80004d86:	892a                	mv	s2,a0
    80004d88:	8b2e                	mv	s6,a1
    80004d8a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d8c:	411c                	lw	a5,0(a0)
    80004d8e:	4705                	li	a4,1
    80004d90:	02e78263          	beq	a5,a4,80004db4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d94:	470d                	li	a4,3
    80004d96:	02e78663          	beq	a5,a4,80004dc2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d9a:	4709                	li	a4,2
    80004d9c:	0ee79163          	bne	a5,a4,80004e7e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004da0:	0ac05d63          	blez	a2,80004e5a <filewrite+0xf4>
    int i = 0;
    80004da4:	4981                	li	s3,0
    80004da6:	6b85                	lui	s7,0x1
    80004da8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004dac:	6c05                	lui	s8,0x1
    80004dae:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004db2:	a861                	j	80004e4a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004db4:	6908                	ld	a0,16(a0)
    80004db6:	00000097          	auipc	ra,0x0
    80004dba:	22e080e7          	jalr	558(ra) # 80004fe4 <pipewrite>
    80004dbe:	8a2a                	mv	s4,a0
    80004dc0:	a045                	j	80004e60 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004dc2:	02451783          	lh	a5,36(a0)
    80004dc6:	03079693          	slli	a3,a5,0x30
    80004dca:	92c1                	srli	a3,a3,0x30
    80004dcc:	4725                	li	a4,9
    80004dce:	0cd76263          	bltu	a4,a3,80004e92 <filewrite+0x12c>
    80004dd2:	0792                	slli	a5,a5,0x4
    80004dd4:	0001c717          	auipc	a4,0x1c
    80004dd8:	fe470713          	addi	a4,a4,-28 # 80020db8 <devsw>
    80004ddc:	97ba                	add	a5,a5,a4
    80004dde:	679c                	ld	a5,8(a5)
    80004de0:	cbdd                	beqz	a5,80004e96 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004de2:	4505                	li	a0,1
    80004de4:	9782                	jalr	a5
    80004de6:	8a2a                	mv	s4,a0
    80004de8:	a8a5                	j	80004e60 <filewrite+0xfa>
    80004dea:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004dee:	00000097          	auipc	ra,0x0
    80004df2:	8b4080e7          	jalr	-1868(ra) # 800046a2 <begin_op>
      ilock(f->ip);
    80004df6:	01893503          	ld	a0,24(s2)
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	edc080e7          	jalr	-292(ra) # 80003cd6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e02:	8756                	mv	a4,s5
    80004e04:	02092683          	lw	a3,32(s2)
    80004e08:	01698633          	add	a2,s3,s6
    80004e0c:	4585                	li	a1,1
    80004e0e:	01893503          	ld	a0,24(s2)
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	270080e7          	jalr	624(ra) # 80004082 <writei>
    80004e1a:	84aa                	mv	s1,a0
    80004e1c:	00a05763          	blez	a0,80004e2a <filewrite+0xc4>
        f->off += r;
    80004e20:	02092783          	lw	a5,32(s2)
    80004e24:	9fa9                	addw	a5,a5,a0
    80004e26:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e2a:	01893503          	ld	a0,24(s2)
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	f6a080e7          	jalr	-150(ra) # 80003d98 <iunlock>
      end_op();
    80004e36:	00000097          	auipc	ra,0x0
    80004e3a:	8ea080e7          	jalr	-1814(ra) # 80004720 <end_op>

      if(r != n1){
    80004e3e:	009a9f63          	bne	s5,s1,80004e5c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e42:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e46:	0149db63          	bge	s3,s4,80004e5c <filewrite+0xf6>
      int n1 = n - i;
    80004e4a:	413a04bb          	subw	s1,s4,s3
    80004e4e:	0004879b          	sext.w	a5,s1
    80004e52:	f8fbdce3          	bge	s7,a5,80004dea <filewrite+0x84>
    80004e56:	84e2                	mv	s1,s8
    80004e58:	bf49                	j	80004dea <filewrite+0x84>
    int i = 0;
    80004e5a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e5c:	013a1f63          	bne	s4,s3,80004e7a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e60:	8552                	mv	a0,s4
    80004e62:	60a6                	ld	ra,72(sp)
    80004e64:	6406                	ld	s0,64(sp)
    80004e66:	74e2                	ld	s1,56(sp)
    80004e68:	7942                	ld	s2,48(sp)
    80004e6a:	79a2                	ld	s3,40(sp)
    80004e6c:	7a02                	ld	s4,32(sp)
    80004e6e:	6ae2                	ld	s5,24(sp)
    80004e70:	6b42                	ld	s6,16(sp)
    80004e72:	6ba2                	ld	s7,8(sp)
    80004e74:	6c02                	ld	s8,0(sp)
    80004e76:	6161                	addi	sp,sp,80
    80004e78:	8082                	ret
    ret = (i == n ? n : -1);
    80004e7a:	5a7d                	li	s4,-1
    80004e7c:	b7d5                	j	80004e60 <filewrite+0xfa>
    panic("filewrite");
    80004e7e:	00004517          	auipc	a0,0x4
    80004e82:	9e250513          	addi	a0,a0,-1566 # 80008860 <syscalls+0x290>
    80004e86:	ffffb097          	auipc	ra,0xffffb
    80004e8a:	6ba080e7          	jalr	1722(ra) # 80000540 <panic>
    return -1;
    80004e8e:	5a7d                	li	s4,-1
    80004e90:	bfc1                	j	80004e60 <filewrite+0xfa>
      return -1;
    80004e92:	5a7d                	li	s4,-1
    80004e94:	b7f1                	j	80004e60 <filewrite+0xfa>
    80004e96:	5a7d                	li	s4,-1
    80004e98:	b7e1                	j	80004e60 <filewrite+0xfa>

0000000080004e9a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e9a:	7179                	addi	sp,sp,-48
    80004e9c:	f406                	sd	ra,40(sp)
    80004e9e:	f022                	sd	s0,32(sp)
    80004ea0:	ec26                	sd	s1,24(sp)
    80004ea2:	e84a                	sd	s2,16(sp)
    80004ea4:	e44e                	sd	s3,8(sp)
    80004ea6:	e052                	sd	s4,0(sp)
    80004ea8:	1800                	addi	s0,sp,48
    80004eaa:	84aa                	mv	s1,a0
    80004eac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004eae:	0005b023          	sd	zero,0(a1)
    80004eb2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004eb6:	00000097          	auipc	ra,0x0
    80004eba:	bf8080e7          	jalr	-1032(ra) # 80004aae <filealloc>
    80004ebe:	e088                	sd	a0,0(s1)
    80004ec0:	c551                	beqz	a0,80004f4c <pipealloc+0xb2>
    80004ec2:	00000097          	auipc	ra,0x0
    80004ec6:	bec080e7          	jalr	-1044(ra) # 80004aae <filealloc>
    80004eca:	00aa3023          	sd	a0,0(s4)
    80004ece:	c92d                	beqz	a0,80004f40 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	c92080e7          	jalr	-878(ra) # 80000b62 <kalloc>
    80004ed8:	892a                	mv	s2,a0
    80004eda:	c125                	beqz	a0,80004f3a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004edc:	4985                	li	s3,1
    80004ede:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ee2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ee6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004eea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004eee:	00004597          	auipc	a1,0x4
    80004ef2:	98258593          	addi	a1,a1,-1662 # 80008870 <syscalls+0x2a0>
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	d18080e7          	jalr	-744(ra) # 80000c0e <initlock>
  (*f0)->type = FD_PIPE;
    80004efe:	609c                	ld	a5,0(s1)
    80004f00:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f04:	609c                	ld	a5,0(s1)
    80004f06:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f0a:	609c                	ld	a5,0(s1)
    80004f0c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f10:	609c                	ld	a5,0(s1)
    80004f12:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f16:	000a3783          	ld	a5,0(s4)
    80004f1a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f1e:	000a3783          	ld	a5,0(s4)
    80004f22:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f26:	000a3783          	ld	a5,0(s4)
    80004f2a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f2e:	000a3783          	ld	a5,0(s4)
    80004f32:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f36:	4501                	li	a0,0
    80004f38:	a025                	j	80004f60 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f3a:	6088                	ld	a0,0(s1)
    80004f3c:	e501                	bnez	a0,80004f44 <pipealloc+0xaa>
    80004f3e:	a039                	j	80004f4c <pipealloc+0xb2>
    80004f40:	6088                	ld	a0,0(s1)
    80004f42:	c51d                	beqz	a0,80004f70 <pipealloc+0xd6>
    fileclose(*f0);
    80004f44:	00000097          	auipc	ra,0x0
    80004f48:	c26080e7          	jalr	-986(ra) # 80004b6a <fileclose>
  if(*f1)
    80004f4c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f50:	557d                	li	a0,-1
  if(*f1)
    80004f52:	c799                	beqz	a5,80004f60 <pipealloc+0xc6>
    fileclose(*f1);
    80004f54:	853e                	mv	a0,a5
    80004f56:	00000097          	auipc	ra,0x0
    80004f5a:	c14080e7          	jalr	-1004(ra) # 80004b6a <fileclose>
  return -1;
    80004f5e:	557d                	li	a0,-1
}
    80004f60:	70a2                	ld	ra,40(sp)
    80004f62:	7402                	ld	s0,32(sp)
    80004f64:	64e2                	ld	s1,24(sp)
    80004f66:	6942                	ld	s2,16(sp)
    80004f68:	69a2                	ld	s3,8(sp)
    80004f6a:	6a02                	ld	s4,0(sp)
    80004f6c:	6145                	addi	sp,sp,48
    80004f6e:	8082                	ret
  return -1;
    80004f70:	557d                	li	a0,-1
    80004f72:	b7fd                	j	80004f60 <pipealloc+0xc6>

0000000080004f74 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f74:	1101                	addi	sp,sp,-32
    80004f76:	ec06                	sd	ra,24(sp)
    80004f78:	e822                	sd	s0,16(sp)
    80004f7a:	e426                	sd	s1,8(sp)
    80004f7c:	e04a                	sd	s2,0(sp)
    80004f7e:	1000                	addi	s0,sp,32
    80004f80:	84aa                	mv	s1,a0
    80004f82:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	d1a080e7          	jalr	-742(ra) # 80000c9e <acquire>
  if(writable){
    80004f8c:	02090d63          	beqz	s2,80004fc6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f90:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f94:	21848513          	addi	a0,s1,536
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	48c080e7          	jalr	1164(ra) # 80002424 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fa0:	2204b783          	ld	a5,544(s1)
    80004fa4:	eb95                	bnez	a5,80004fd8 <pipeclose+0x64>
    release(&pi->lock);
    80004fa6:	8526                	mv	a0,s1
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	daa080e7          	jalr	-598(ra) # 80000d52 <release>
    kfree((char*)pi);
    80004fb0:	8526                	mv	a0,s1
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	a48080e7          	jalr	-1464(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80004fba:	60e2                	ld	ra,24(sp)
    80004fbc:	6442                	ld	s0,16(sp)
    80004fbe:	64a2                	ld	s1,8(sp)
    80004fc0:	6902                	ld	s2,0(sp)
    80004fc2:	6105                	addi	sp,sp,32
    80004fc4:	8082                	ret
    pi->readopen = 0;
    80004fc6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fca:	21c48513          	addi	a0,s1,540
    80004fce:	ffffd097          	auipc	ra,0xffffd
    80004fd2:	456080e7          	jalr	1110(ra) # 80002424 <wakeup>
    80004fd6:	b7e9                	j	80004fa0 <pipeclose+0x2c>
    release(&pi->lock);
    80004fd8:	8526                	mv	a0,s1
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	d78080e7          	jalr	-648(ra) # 80000d52 <release>
}
    80004fe2:	bfe1                	j	80004fba <pipeclose+0x46>

0000000080004fe4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004fe4:	711d                	addi	sp,sp,-96
    80004fe6:	ec86                	sd	ra,88(sp)
    80004fe8:	e8a2                	sd	s0,80(sp)
    80004fea:	e4a6                	sd	s1,72(sp)
    80004fec:	e0ca                	sd	s2,64(sp)
    80004fee:	fc4e                	sd	s3,56(sp)
    80004ff0:	f852                	sd	s4,48(sp)
    80004ff2:	f456                	sd	s5,40(sp)
    80004ff4:	f05a                	sd	s6,32(sp)
    80004ff6:	ec5e                	sd	s7,24(sp)
    80004ff8:	e862                	sd	s8,16(sp)
    80004ffa:	1080                	addi	s0,sp,96
    80004ffc:	84aa                	mv	s1,a0
    80004ffe:	8aae                	mv	s5,a1
    80005000:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005002:	ffffd097          	auipc	ra,0xffffd
    80005006:	c10080e7          	jalr	-1008(ra) # 80001c12 <myproc>
    8000500a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000500c:	8526                	mv	a0,s1
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	c90080e7          	jalr	-880(ra) # 80000c9e <acquire>
  while(i < n){
    80005016:	0b405663          	blez	s4,800050c2 <pipewrite+0xde>
  int i = 0;
    8000501a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000501c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000501e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005022:	21c48b93          	addi	s7,s1,540
    80005026:	a089                	j	80005068 <pipewrite+0x84>
      release(&pi->lock);
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	d28080e7          	jalr	-728(ra) # 80000d52 <release>
      return -1;
    80005032:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005034:	854a                	mv	a0,s2
    80005036:	60e6                	ld	ra,88(sp)
    80005038:	6446                	ld	s0,80(sp)
    8000503a:	64a6                	ld	s1,72(sp)
    8000503c:	6906                	ld	s2,64(sp)
    8000503e:	79e2                	ld	s3,56(sp)
    80005040:	7a42                	ld	s4,48(sp)
    80005042:	7aa2                	ld	s5,40(sp)
    80005044:	7b02                	ld	s6,32(sp)
    80005046:	6be2                	ld	s7,24(sp)
    80005048:	6c42                	ld	s8,16(sp)
    8000504a:	6125                	addi	sp,sp,96
    8000504c:	8082                	ret
      wakeup(&pi->nread);
    8000504e:	8562                	mv	a0,s8
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	3d4080e7          	jalr	980(ra) # 80002424 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005058:	85a6                	mv	a1,s1
    8000505a:	855e                	mv	a0,s7
    8000505c:	ffffd097          	auipc	ra,0xffffd
    80005060:	364080e7          	jalr	868(ra) # 800023c0 <sleep>
  while(i < n){
    80005064:	07495063          	bge	s2,s4,800050c4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005068:	2204a783          	lw	a5,544(s1)
    8000506c:	dfd5                	beqz	a5,80005028 <pipewrite+0x44>
    8000506e:	854e                	mv	a0,s3
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	5f8080e7          	jalr	1528(ra) # 80002668 <killed>
    80005078:	f945                	bnez	a0,80005028 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000507a:	2184a783          	lw	a5,536(s1)
    8000507e:	21c4a703          	lw	a4,540(s1)
    80005082:	2007879b          	addiw	a5,a5,512
    80005086:	fcf704e3          	beq	a4,a5,8000504e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000508a:	4685                	li	a3,1
    8000508c:	01590633          	add	a2,s2,s5
    80005090:	faf40593          	addi	a1,s0,-81
    80005094:	0509b503          	ld	a0,80(s3)
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	7c8080e7          	jalr	1992(ra) # 80001860 <copyin>
    800050a0:	03650263          	beq	a0,s6,800050c4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050a4:	21c4a783          	lw	a5,540(s1)
    800050a8:	0017871b          	addiw	a4,a5,1
    800050ac:	20e4ae23          	sw	a4,540(s1)
    800050b0:	1ff7f793          	andi	a5,a5,511
    800050b4:	97a6                	add	a5,a5,s1
    800050b6:	faf44703          	lbu	a4,-81(s0)
    800050ba:	00e78c23          	sb	a4,24(a5)
      i++;
    800050be:	2905                	addiw	s2,s2,1
    800050c0:	b755                	j	80005064 <pipewrite+0x80>
  int i = 0;
    800050c2:	4901                	li	s2,0
  wakeup(&pi->nread);
    800050c4:	21848513          	addi	a0,s1,536
    800050c8:	ffffd097          	auipc	ra,0xffffd
    800050cc:	35c080e7          	jalr	860(ra) # 80002424 <wakeup>
  release(&pi->lock);
    800050d0:	8526                	mv	a0,s1
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	c80080e7          	jalr	-896(ra) # 80000d52 <release>
  return i;
    800050da:	bfa9                	j	80005034 <pipewrite+0x50>

00000000800050dc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050dc:	715d                	addi	sp,sp,-80
    800050de:	e486                	sd	ra,72(sp)
    800050e0:	e0a2                	sd	s0,64(sp)
    800050e2:	fc26                	sd	s1,56(sp)
    800050e4:	f84a                	sd	s2,48(sp)
    800050e6:	f44e                	sd	s3,40(sp)
    800050e8:	f052                	sd	s4,32(sp)
    800050ea:	ec56                	sd	s5,24(sp)
    800050ec:	e85a                	sd	s6,16(sp)
    800050ee:	0880                	addi	s0,sp,80
    800050f0:	84aa                	mv	s1,a0
    800050f2:	892e                	mv	s2,a1
    800050f4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050f6:	ffffd097          	auipc	ra,0xffffd
    800050fa:	b1c080e7          	jalr	-1252(ra) # 80001c12 <myproc>
    800050fe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005100:	8526                	mv	a0,s1
    80005102:	ffffc097          	auipc	ra,0xffffc
    80005106:	b9c080e7          	jalr	-1124(ra) # 80000c9e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000510a:	2184a703          	lw	a4,536(s1)
    8000510e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005112:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005116:	02f71763          	bne	a4,a5,80005144 <piperead+0x68>
    8000511a:	2244a783          	lw	a5,548(s1)
    8000511e:	c39d                	beqz	a5,80005144 <piperead+0x68>
    if(killed(pr)){
    80005120:	8552                	mv	a0,s4
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	546080e7          	jalr	1350(ra) # 80002668 <killed>
    8000512a:	e949                	bnez	a0,800051bc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000512c:	85a6                	mv	a1,s1
    8000512e:	854e                	mv	a0,s3
    80005130:	ffffd097          	auipc	ra,0xffffd
    80005134:	290080e7          	jalr	656(ra) # 800023c0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005138:	2184a703          	lw	a4,536(s1)
    8000513c:	21c4a783          	lw	a5,540(s1)
    80005140:	fcf70de3          	beq	a4,a5,8000511a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005144:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005146:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005148:	05505463          	blez	s5,80005190 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000514c:	2184a783          	lw	a5,536(s1)
    80005150:	21c4a703          	lw	a4,540(s1)
    80005154:	02f70e63          	beq	a4,a5,80005190 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005158:	0017871b          	addiw	a4,a5,1
    8000515c:	20e4ac23          	sw	a4,536(s1)
    80005160:	1ff7f793          	andi	a5,a5,511
    80005164:	97a6                	add	a5,a5,s1
    80005166:	0187c783          	lbu	a5,24(a5)
    8000516a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000516e:	4685                	li	a3,1
    80005170:	fbf40613          	addi	a2,s0,-65
    80005174:	85ca                	mv	a1,s2
    80005176:	050a3503          	ld	a0,80(s4)
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	65a080e7          	jalr	1626(ra) # 800017d4 <copyout>
    80005182:	01650763          	beq	a0,s6,80005190 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005186:	2985                	addiw	s3,s3,1
    80005188:	0905                	addi	s2,s2,1
    8000518a:	fd3a91e3          	bne	s5,s3,8000514c <piperead+0x70>
    8000518e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005190:	21c48513          	addi	a0,s1,540
    80005194:	ffffd097          	auipc	ra,0xffffd
    80005198:	290080e7          	jalr	656(ra) # 80002424 <wakeup>
  release(&pi->lock);
    8000519c:	8526                	mv	a0,s1
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	bb4080e7          	jalr	-1100(ra) # 80000d52 <release>
  return i;
}
    800051a6:	854e                	mv	a0,s3
    800051a8:	60a6                	ld	ra,72(sp)
    800051aa:	6406                	ld	s0,64(sp)
    800051ac:	74e2                	ld	s1,56(sp)
    800051ae:	7942                	ld	s2,48(sp)
    800051b0:	79a2                	ld	s3,40(sp)
    800051b2:	7a02                	ld	s4,32(sp)
    800051b4:	6ae2                	ld	s5,24(sp)
    800051b6:	6b42                	ld	s6,16(sp)
    800051b8:	6161                	addi	sp,sp,80
    800051ba:	8082                	ret
      release(&pi->lock);
    800051bc:	8526                	mv	a0,s1
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	b94080e7          	jalr	-1132(ra) # 80000d52 <release>
      return -1;
    800051c6:	59fd                	li	s3,-1
    800051c8:	bff9                	j	800051a6 <piperead+0xca>

00000000800051ca <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800051ca:	1141                	addi	sp,sp,-16
    800051cc:	e422                	sd	s0,8(sp)
    800051ce:	0800                	addi	s0,sp,16
    800051d0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800051d2:	8905                	andi	a0,a0,1
    800051d4:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800051d6:	8b89                	andi	a5,a5,2
    800051d8:	c399                	beqz	a5,800051de <flags2perm+0x14>
      perm |= PTE_W;
    800051da:	00456513          	ori	a0,a0,4
    return perm;
}
    800051de:	6422                	ld	s0,8(sp)
    800051e0:	0141                	addi	sp,sp,16
    800051e2:	8082                	ret

00000000800051e4 <exec>:

int
exec(char *path, char **argv)
{
    800051e4:	de010113          	addi	sp,sp,-544
    800051e8:	20113c23          	sd	ra,536(sp)
    800051ec:	20813823          	sd	s0,528(sp)
    800051f0:	20913423          	sd	s1,520(sp)
    800051f4:	21213023          	sd	s2,512(sp)
    800051f8:	ffce                	sd	s3,504(sp)
    800051fa:	fbd2                	sd	s4,496(sp)
    800051fc:	f7d6                	sd	s5,488(sp)
    800051fe:	f3da                	sd	s6,480(sp)
    80005200:	efde                	sd	s7,472(sp)
    80005202:	ebe2                	sd	s8,464(sp)
    80005204:	e7e6                	sd	s9,456(sp)
    80005206:	e3ea                	sd	s10,448(sp)
    80005208:	ff6e                	sd	s11,440(sp)
    8000520a:	1400                	addi	s0,sp,544
    8000520c:	892a                	mv	s2,a0
    8000520e:	dea43423          	sd	a0,-536(s0)
    80005212:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005216:	ffffd097          	auipc	ra,0xffffd
    8000521a:	9fc080e7          	jalr	-1540(ra) # 80001c12 <myproc>
    8000521e:	84aa                	mv	s1,a0

  begin_op();
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	482080e7          	jalr	1154(ra) # 800046a2 <begin_op>

  if((ip = namei(path)) == 0){
    80005228:	854a                	mv	a0,s2
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	258080e7          	jalr	600(ra) # 80004482 <namei>
    80005232:	c93d                	beqz	a0,800052a8 <exec+0xc4>
    80005234:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	aa0080e7          	jalr	-1376(ra) # 80003cd6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000523e:	04000713          	li	a4,64
    80005242:	4681                	li	a3,0
    80005244:	e5040613          	addi	a2,s0,-432
    80005248:	4581                	li	a1,0
    8000524a:	8556                	mv	a0,s5
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	d3e080e7          	jalr	-706(ra) # 80003f8a <readi>
    80005254:	04000793          	li	a5,64
    80005258:	00f51a63          	bne	a0,a5,8000526c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000525c:	e5042703          	lw	a4,-432(s0)
    80005260:	464c47b7          	lui	a5,0x464c4
    80005264:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005268:	04f70663          	beq	a4,a5,800052b4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000526c:	8556                	mv	a0,s5
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	cca080e7          	jalr	-822(ra) # 80003f38 <iunlockput>
    end_op();
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	4aa080e7          	jalr	1194(ra) # 80004720 <end_op>
  }
  return -1;
    8000527e:	557d                	li	a0,-1
}
    80005280:	21813083          	ld	ra,536(sp)
    80005284:	21013403          	ld	s0,528(sp)
    80005288:	20813483          	ld	s1,520(sp)
    8000528c:	20013903          	ld	s2,512(sp)
    80005290:	79fe                	ld	s3,504(sp)
    80005292:	7a5e                	ld	s4,496(sp)
    80005294:	7abe                	ld	s5,488(sp)
    80005296:	7b1e                	ld	s6,480(sp)
    80005298:	6bfe                	ld	s7,472(sp)
    8000529a:	6c5e                	ld	s8,464(sp)
    8000529c:	6cbe                	ld	s9,456(sp)
    8000529e:	6d1e                	ld	s10,448(sp)
    800052a0:	7dfa                	ld	s11,440(sp)
    800052a2:	22010113          	addi	sp,sp,544
    800052a6:	8082                	ret
    end_op();
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	478080e7          	jalr	1144(ra) # 80004720 <end_op>
    return -1;
    800052b0:	557d                	li	a0,-1
    800052b2:	b7f9                	j	80005280 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800052b4:	8526                	mv	a0,s1
    800052b6:	ffffd097          	auipc	ra,0xffffd
    800052ba:	a20080e7          	jalr	-1504(ra) # 80001cd6 <proc_pagetable>
    800052be:	8b2a                	mv	s6,a0
    800052c0:	d555                	beqz	a0,8000526c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052c2:	e7042783          	lw	a5,-400(s0)
    800052c6:	e8845703          	lhu	a4,-376(s0)
    800052ca:	c735                	beqz	a4,80005336 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052cc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ce:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800052d2:	6a05                	lui	s4,0x1
    800052d4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800052d8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800052dc:	6d85                	lui	s11,0x1
    800052de:	7d7d                	lui	s10,0xfffff
    800052e0:	ac3d                	j	8000551e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052e2:	00003517          	auipc	a0,0x3
    800052e6:	59650513          	addi	a0,a0,1430 # 80008878 <syscalls+0x2a8>
    800052ea:	ffffb097          	auipc	ra,0xffffb
    800052ee:	256080e7          	jalr	598(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052f2:	874a                	mv	a4,s2
    800052f4:	009c86bb          	addw	a3,s9,s1
    800052f8:	4581                	li	a1,0
    800052fa:	8556                	mv	a0,s5
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	c8e080e7          	jalr	-882(ra) # 80003f8a <readi>
    80005304:	2501                	sext.w	a0,a0
    80005306:	1aa91963          	bne	s2,a0,800054b8 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000530a:	009d84bb          	addw	s1,s11,s1
    8000530e:	013d09bb          	addw	s3,s10,s3
    80005312:	1f74f663          	bgeu	s1,s7,800054fe <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005316:	02049593          	slli	a1,s1,0x20
    8000531a:	9181                	srli	a1,a1,0x20
    8000531c:	95e2                	add	a1,a1,s8
    8000531e:	855a                	mv	a0,s6
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	e04080e7          	jalr	-508(ra) # 80001124 <walkaddr>
    80005328:	862a                	mv	a2,a0
    if(pa == 0)
    8000532a:	dd45                	beqz	a0,800052e2 <exec+0xfe>
      n = PGSIZE;
    8000532c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000532e:	fd49f2e3          	bgeu	s3,s4,800052f2 <exec+0x10e>
      n = sz - i;
    80005332:	894e                	mv	s2,s3
    80005334:	bf7d                	j	800052f2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005336:	4901                	li	s2,0
  iunlockput(ip);
    80005338:	8556                	mv	a0,s5
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	bfe080e7          	jalr	-1026(ra) # 80003f38 <iunlockput>
  end_op();
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	3de080e7          	jalr	990(ra) # 80004720 <end_op>
  p = myproc();
    8000534a:	ffffd097          	auipc	ra,0xffffd
    8000534e:	8c8080e7          	jalr	-1848(ra) # 80001c12 <myproc>
    80005352:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005354:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005358:	6785                	lui	a5,0x1
    8000535a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000535c:	97ca                	add	a5,a5,s2
    8000535e:	777d                	lui	a4,0xfffff
    80005360:	8ff9                	and	a5,a5,a4
    80005362:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005366:	4691                	li	a3,4
    80005368:	6609                	lui	a2,0x2
    8000536a:	963e                	add	a2,a2,a5
    8000536c:	85be                	mv	a1,a5
    8000536e:	855a                	mv	a0,s6
    80005370:	ffffc097          	auipc	ra,0xffffc
    80005374:	168080e7          	jalr	360(ra) # 800014d8 <uvmalloc>
    80005378:	8c2a                	mv	s8,a0
  ip = 0;
    8000537a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000537c:	12050e63          	beqz	a0,800054b8 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005380:	75f9                	lui	a1,0xffffe
    80005382:	95aa                	add	a1,a1,a0
    80005384:	855a                	mv	a0,s6
    80005386:	ffffc097          	auipc	ra,0xffffc
    8000538a:	41c080e7          	jalr	1052(ra) # 800017a2 <uvmclear>
  stackbase = sp - PGSIZE;
    8000538e:	7afd                	lui	s5,0xfffff
    80005390:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005392:	df043783          	ld	a5,-528(s0)
    80005396:	6388                	ld	a0,0(a5)
    80005398:	c925                	beqz	a0,80005408 <exec+0x224>
    8000539a:	e9040993          	addi	s3,s0,-368
    8000539e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053a2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053a4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	b70080e7          	jalr	-1168(ra) # 80000f16 <strlen>
    800053ae:	0015079b          	addiw	a5,a0,1
    800053b2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053b6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800053ba:	13596663          	bltu	s2,s5,800054e6 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053be:	df043d83          	ld	s11,-528(s0)
    800053c2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800053c6:	8552                	mv	a0,s4
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	b4e080e7          	jalr	-1202(ra) # 80000f16 <strlen>
    800053d0:	0015069b          	addiw	a3,a0,1
    800053d4:	8652                	mv	a2,s4
    800053d6:	85ca                	mv	a1,s2
    800053d8:	855a                	mv	a0,s6
    800053da:	ffffc097          	auipc	ra,0xffffc
    800053de:	3fa080e7          	jalr	1018(ra) # 800017d4 <copyout>
    800053e2:	10054663          	bltz	a0,800054ee <exec+0x30a>
    ustack[argc] = sp;
    800053e6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053ea:	0485                	addi	s1,s1,1
    800053ec:	008d8793          	addi	a5,s11,8
    800053f0:	def43823          	sd	a5,-528(s0)
    800053f4:	008db503          	ld	a0,8(s11)
    800053f8:	c911                	beqz	a0,8000540c <exec+0x228>
    if(argc >= MAXARG)
    800053fa:	09a1                	addi	s3,s3,8
    800053fc:	fb3c95e3          	bne	s9,s3,800053a6 <exec+0x1c2>
  sz = sz1;
    80005400:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005404:	4a81                	li	s5,0
    80005406:	a84d                	j	800054b8 <exec+0x2d4>
  sp = sz;
    80005408:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000540a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000540c:	00349793          	slli	a5,s1,0x3
    80005410:	f9078793          	addi	a5,a5,-112
    80005414:	97a2                	add	a5,a5,s0
    80005416:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000541a:	00148693          	addi	a3,s1,1
    8000541e:	068e                	slli	a3,a3,0x3
    80005420:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005424:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005428:	01597663          	bgeu	s2,s5,80005434 <exec+0x250>
  sz = sz1;
    8000542c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005430:	4a81                	li	s5,0
    80005432:	a059                	j	800054b8 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005434:	e9040613          	addi	a2,s0,-368
    80005438:	85ca                	mv	a1,s2
    8000543a:	855a                	mv	a0,s6
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	398080e7          	jalr	920(ra) # 800017d4 <copyout>
    80005444:	0a054963          	bltz	a0,800054f6 <exec+0x312>
  p->trapframe->a1 = sp;
    80005448:	058bb783          	ld	a5,88(s7)
    8000544c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005450:	de843783          	ld	a5,-536(s0)
    80005454:	0007c703          	lbu	a4,0(a5)
    80005458:	cf11                	beqz	a4,80005474 <exec+0x290>
    8000545a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000545c:	02f00693          	li	a3,47
    80005460:	a039                	j	8000546e <exec+0x28a>
      last = s+1;
    80005462:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005466:	0785                	addi	a5,a5,1
    80005468:	fff7c703          	lbu	a4,-1(a5)
    8000546c:	c701                	beqz	a4,80005474 <exec+0x290>
    if(*s == '/')
    8000546e:	fed71ce3          	bne	a4,a3,80005466 <exec+0x282>
    80005472:	bfc5                	j	80005462 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005474:	4641                	li	a2,16
    80005476:	de843583          	ld	a1,-536(s0)
    8000547a:	158b8513          	addi	a0,s7,344
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	a66080e7          	jalr	-1434(ra) # 80000ee4 <safestrcpy>
  oldpagetable = p->pagetable;
    80005486:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000548a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000548e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005492:	058bb783          	ld	a5,88(s7)
    80005496:	e6843703          	ld	a4,-408(s0)
    8000549a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000549c:	058bb783          	ld	a5,88(s7)
    800054a0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054a4:	85ea                	mv	a1,s10
    800054a6:	ffffd097          	auipc	ra,0xffffd
    800054aa:	8cc080e7          	jalr	-1844(ra) # 80001d72 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054ae:	0004851b          	sext.w	a0,s1
    800054b2:	b3f9                	j	80005280 <exec+0x9c>
    800054b4:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800054b8:	df843583          	ld	a1,-520(s0)
    800054bc:	855a                	mv	a0,s6
    800054be:	ffffd097          	auipc	ra,0xffffd
    800054c2:	8b4080e7          	jalr	-1868(ra) # 80001d72 <proc_freepagetable>
  if(ip){
    800054c6:	da0a93e3          	bnez	s5,8000526c <exec+0x88>
  return -1;
    800054ca:	557d                	li	a0,-1
    800054cc:	bb55                	j	80005280 <exec+0x9c>
    800054ce:	df243c23          	sd	s2,-520(s0)
    800054d2:	b7dd                	j	800054b8 <exec+0x2d4>
    800054d4:	df243c23          	sd	s2,-520(s0)
    800054d8:	b7c5                	j	800054b8 <exec+0x2d4>
    800054da:	df243c23          	sd	s2,-520(s0)
    800054de:	bfe9                	j	800054b8 <exec+0x2d4>
    800054e0:	df243c23          	sd	s2,-520(s0)
    800054e4:	bfd1                	j	800054b8 <exec+0x2d4>
  sz = sz1;
    800054e6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054ea:	4a81                	li	s5,0
    800054ec:	b7f1                	j	800054b8 <exec+0x2d4>
  sz = sz1;
    800054ee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054f2:	4a81                	li	s5,0
    800054f4:	b7d1                	j	800054b8 <exec+0x2d4>
  sz = sz1;
    800054f6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054fa:	4a81                	li	s5,0
    800054fc:	bf75                	j	800054b8 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054fe:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005502:	e0843783          	ld	a5,-504(s0)
    80005506:	0017869b          	addiw	a3,a5,1
    8000550a:	e0d43423          	sd	a3,-504(s0)
    8000550e:	e0043783          	ld	a5,-512(s0)
    80005512:	0387879b          	addiw	a5,a5,56
    80005516:	e8845703          	lhu	a4,-376(s0)
    8000551a:	e0e6dfe3          	bge	a3,a4,80005338 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000551e:	2781                	sext.w	a5,a5
    80005520:	e0f43023          	sd	a5,-512(s0)
    80005524:	03800713          	li	a4,56
    80005528:	86be                	mv	a3,a5
    8000552a:	e1840613          	addi	a2,s0,-488
    8000552e:	4581                	li	a1,0
    80005530:	8556                	mv	a0,s5
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	a58080e7          	jalr	-1448(ra) # 80003f8a <readi>
    8000553a:	03800793          	li	a5,56
    8000553e:	f6f51be3          	bne	a0,a5,800054b4 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005542:	e1842783          	lw	a5,-488(s0)
    80005546:	4705                	li	a4,1
    80005548:	fae79de3          	bne	a5,a4,80005502 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000554c:	e4043483          	ld	s1,-448(s0)
    80005550:	e3843783          	ld	a5,-456(s0)
    80005554:	f6f4ede3          	bltu	s1,a5,800054ce <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005558:	e2843783          	ld	a5,-472(s0)
    8000555c:	94be                	add	s1,s1,a5
    8000555e:	f6f4ebe3          	bltu	s1,a5,800054d4 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005562:	de043703          	ld	a4,-544(s0)
    80005566:	8ff9                	and	a5,a5,a4
    80005568:	fbad                	bnez	a5,800054da <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000556a:	e1c42503          	lw	a0,-484(s0)
    8000556e:	00000097          	auipc	ra,0x0
    80005572:	c5c080e7          	jalr	-932(ra) # 800051ca <flags2perm>
    80005576:	86aa                	mv	a3,a0
    80005578:	8626                	mv	a2,s1
    8000557a:	85ca                	mv	a1,s2
    8000557c:	855a                	mv	a0,s6
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	f5a080e7          	jalr	-166(ra) # 800014d8 <uvmalloc>
    80005586:	dea43c23          	sd	a0,-520(s0)
    8000558a:	d939                	beqz	a0,800054e0 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000558c:	e2843c03          	ld	s8,-472(s0)
    80005590:	e2042c83          	lw	s9,-480(s0)
    80005594:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005598:	f60b83e3          	beqz	s7,800054fe <exec+0x31a>
    8000559c:	89de                	mv	s3,s7
    8000559e:	4481                	li	s1,0
    800055a0:	bb9d                	j	80005316 <exec+0x132>

00000000800055a2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055a2:	7179                	addi	sp,sp,-48
    800055a4:	f406                	sd	ra,40(sp)
    800055a6:	f022                	sd	s0,32(sp)
    800055a8:	ec26                	sd	s1,24(sp)
    800055aa:	e84a                	sd	s2,16(sp)
    800055ac:	1800                	addi	s0,sp,48
    800055ae:	892e                	mv	s2,a1
    800055b0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055b2:	fdc40593          	addi	a1,s0,-36
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	a6a080e7          	jalr	-1430(ra) # 80003020 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055be:	fdc42703          	lw	a4,-36(s0)
    800055c2:	47bd                	li	a5,15
    800055c4:	02e7eb63          	bltu	a5,a4,800055fa <argfd+0x58>
    800055c8:	ffffc097          	auipc	ra,0xffffc
    800055cc:	64a080e7          	jalr	1610(ra) # 80001c12 <myproc>
    800055d0:	fdc42703          	lw	a4,-36(s0)
    800055d4:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd0ca>
    800055d8:	078e                	slli	a5,a5,0x3
    800055da:	953e                	add	a0,a0,a5
    800055dc:	611c                	ld	a5,0(a0)
    800055de:	c385                	beqz	a5,800055fe <argfd+0x5c>
    return -1;
  if(pfd)
    800055e0:	00090463          	beqz	s2,800055e8 <argfd+0x46>
    *pfd = fd;
    800055e4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055e8:	4501                	li	a0,0
  if(pf)
    800055ea:	c091                	beqz	s1,800055ee <argfd+0x4c>
    *pf = f;
    800055ec:	e09c                	sd	a5,0(s1)
}
    800055ee:	70a2                	ld	ra,40(sp)
    800055f0:	7402                	ld	s0,32(sp)
    800055f2:	64e2                	ld	s1,24(sp)
    800055f4:	6942                	ld	s2,16(sp)
    800055f6:	6145                	addi	sp,sp,48
    800055f8:	8082                	ret
    return -1;
    800055fa:	557d                	li	a0,-1
    800055fc:	bfcd                	j	800055ee <argfd+0x4c>
    800055fe:	557d                	li	a0,-1
    80005600:	b7fd                	j	800055ee <argfd+0x4c>

0000000080005602 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005602:	1101                	addi	sp,sp,-32
    80005604:	ec06                	sd	ra,24(sp)
    80005606:	e822                	sd	s0,16(sp)
    80005608:	e426                	sd	s1,8(sp)
    8000560a:	1000                	addi	s0,sp,32
    8000560c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000560e:	ffffc097          	auipc	ra,0xffffc
    80005612:	604080e7          	jalr	1540(ra) # 80001c12 <myproc>
    80005616:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005618:	0d050793          	addi	a5,a0,208
    8000561c:	4501                	li	a0,0
    8000561e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005620:	6398                	ld	a4,0(a5)
    80005622:	cb19                	beqz	a4,80005638 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005624:	2505                	addiw	a0,a0,1
    80005626:	07a1                	addi	a5,a5,8
    80005628:	fed51ce3          	bne	a0,a3,80005620 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000562c:	557d                	li	a0,-1
}
    8000562e:	60e2                	ld	ra,24(sp)
    80005630:	6442                	ld	s0,16(sp)
    80005632:	64a2                	ld	s1,8(sp)
    80005634:	6105                	addi	sp,sp,32
    80005636:	8082                	ret
      p->ofile[fd] = f;
    80005638:	01a50793          	addi	a5,a0,26
    8000563c:	078e                	slli	a5,a5,0x3
    8000563e:	963e                	add	a2,a2,a5
    80005640:	e204                	sd	s1,0(a2)
      return fd;
    80005642:	b7f5                	j	8000562e <fdalloc+0x2c>

0000000080005644 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005644:	715d                	addi	sp,sp,-80
    80005646:	e486                	sd	ra,72(sp)
    80005648:	e0a2                	sd	s0,64(sp)
    8000564a:	fc26                	sd	s1,56(sp)
    8000564c:	f84a                	sd	s2,48(sp)
    8000564e:	f44e                	sd	s3,40(sp)
    80005650:	f052                	sd	s4,32(sp)
    80005652:	ec56                	sd	s5,24(sp)
    80005654:	e85a                	sd	s6,16(sp)
    80005656:	0880                	addi	s0,sp,80
    80005658:	8b2e                	mv	s6,a1
    8000565a:	89b2                	mv	s3,a2
    8000565c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000565e:	fb040593          	addi	a1,s0,-80
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	e3e080e7          	jalr	-450(ra) # 800044a0 <nameiparent>
    8000566a:	84aa                	mv	s1,a0
    8000566c:	14050f63          	beqz	a0,800057ca <create+0x186>
    return 0;

  ilock(dp);
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	666080e7          	jalr	1638(ra) # 80003cd6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005678:	4601                	li	a2,0
    8000567a:	fb040593          	addi	a1,s0,-80
    8000567e:	8526                	mv	a0,s1
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	b3a080e7          	jalr	-1222(ra) # 800041ba <dirlookup>
    80005688:	8aaa                	mv	s5,a0
    8000568a:	c931                	beqz	a0,800056de <create+0x9a>
    iunlockput(dp);
    8000568c:	8526                	mv	a0,s1
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	8aa080e7          	jalr	-1878(ra) # 80003f38 <iunlockput>
    ilock(ip);
    80005696:	8556                	mv	a0,s5
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	63e080e7          	jalr	1598(ra) # 80003cd6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056a0:	000b059b          	sext.w	a1,s6
    800056a4:	4789                	li	a5,2
    800056a6:	02f59563          	bne	a1,a5,800056d0 <create+0x8c>
    800056aa:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0f4>
    800056ae:	37f9                	addiw	a5,a5,-2
    800056b0:	17c2                	slli	a5,a5,0x30
    800056b2:	93c1                	srli	a5,a5,0x30
    800056b4:	4705                	li	a4,1
    800056b6:	00f76d63          	bltu	a4,a5,800056d0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800056ba:	8556                	mv	a0,s5
    800056bc:	60a6                	ld	ra,72(sp)
    800056be:	6406                	ld	s0,64(sp)
    800056c0:	74e2                	ld	s1,56(sp)
    800056c2:	7942                	ld	s2,48(sp)
    800056c4:	79a2                	ld	s3,40(sp)
    800056c6:	7a02                	ld	s4,32(sp)
    800056c8:	6ae2                	ld	s5,24(sp)
    800056ca:	6b42                	ld	s6,16(sp)
    800056cc:	6161                	addi	sp,sp,80
    800056ce:	8082                	ret
    iunlockput(ip);
    800056d0:	8556                	mv	a0,s5
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	866080e7          	jalr	-1946(ra) # 80003f38 <iunlockput>
    return 0;
    800056da:	4a81                	li	s5,0
    800056dc:	bff9                	j	800056ba <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800056de:	85da                	mv	a1,s6
    800056e0:	4088                	lw	a0,0(s1)
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	456080e7          	jalr	1110(ra) # 80003b38 <ialloc>
    800056ea:	8a2a                	mv	s4,a0
    800056ec:	c539                	beqz	a0,8000573a <create+0xf6>
  ilock(ip);
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	5e8080e7          	jalr	1512(ra) # 80003cd6 <ilock>
  ip->major = major;
    800056f6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800056fa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800056fe:	4905                	li	s2,1
    80005700:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005704:	8552                	mv	a0,s4
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	504080e7          	jalr	1284(ra) # 80003c0a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000570e:	000b059b          	sext.w	a1,s6
    80005712:	03258b63          	beq	a1,s2,80005748 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005716:	004a2603          	lw	a2,4(s4)
    8000571a:	fb040593          	addi	a1,s0,-80
    8000571e:	8526                	mv	a0,s1
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	cb0080e7          	jalr	-848(ra) # 800043d0 <dirlink>
    80005728:	06054f63          	bltz	a0,800057a6 <create+0x162>
  iunlockput(dp);
    8000572c:	8526                	mv	a0,s1
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	80a080e7          	jalr	-2038(ra) # 80003f38 <iunlockput>
  return ip;
    80005736:	8ad2                	mv	s5,s4
    80005738:	b749                	j	800056ba <create+0x76>
    iunlockput(dp);
    8000573a:	8526                	mv	a0,s1
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	7fc080e7          	jalr	2044(ra) # 80003f38 <iunlockput>
    return 0;
    80005744:	8ad2                	mv	s5,s4
    80005746:	bf95                	j	800056ba <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005748:	004a2603          	lw	a2,4(s4)
    8000574c:	00003597          	auipc	a1,0x3
    80005750:	14c58593          	addi	a1,a1,332 # 80008898 <syscalls+0x2c8>
    80005754:	8552                	mv	a0,s4
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	c7a080e7          	jalr	-902(ra) # 800043d0 <dirlink>
    8000575e:	04054463          	bltz	a0,800057a6 <create+0x162>
    80005762:	40d0                	lw	a2,4(s1)
    80005764:	00003597          	auipc	a1,0x3
    80005768:	13c58593          	addi	a1,a1,316 # 800088a0 <syscalls+0x2d0>
    8000576c:	8552                	mv	a0,s4
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	c62080e7          	jalr	-926(ra) # 800043d0 <dirlink>
    80005776:	02054863          	bltz	a0,800057a6 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000577a:	004a2603          	lw	a2,4(s4)
    8000577e:	fb040593          	addi	a1,s0,-80
    80005782:	8526                	mv	a0,s1
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	c4c080e7          	jalr	-948(ra) # 800043d0 <dirlink>
    8000578c:	00054d63          	bltz	a0,800057a6 <create+0x162>
    dp->nlink++;  // for ".."
    80005790:	04a4d783          	lhu	a5,74(s1)
    80005794:	2785                	addiw	a5,a5,1
    80005796:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	46e080e7          	jalr	1134(ra) # 80003c0a <iupdate>
    800057a4:	b761                	j	8000572c <create+0xe8>
  ip->nlink = 0;
    800057a6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057aa:	8552                	mv	a0,s4
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	45e080e7          	jalr	1118(ra) # 80003c0a <iupdate>
  iunlockput(ip);
    800057b4:	8552                	mv	a0,s4
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	782080e7          	jalr	1922(ra) # 80003f38 <iunlockput>
  iunlockput(dp);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	778080e7          	jalr	1912(ra) # 80003f38 <iunlockput>
  return 0;
    800057c8:	bdcd                	j	800056ba <create+0x76>
    return 0;
    800057ca:	8aaa                	mv	s5,a0
    800057cc:	b5fd                	j	800056ba <create+0x76>

00000000800057ce <sys_dup>:
{
    800057ce:	7179                	addi	sp,sp,-48
    800057d0:	f406                	sd	ra,40(sp)
    800057d2:	f022                	sd	s0,32(sp)
    800057d4:	ec26                	sd	s1,24(sp)
    800057d6:	e84a                	sd	s2,16(sp)
    800057d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057da:	fd840613          	addi	a2,s0,-40
    800057de:	4581                	li	a1,0
    800057e0:	4501                	li	a0,0
    800057e2:	00000097          	auipc	ra,0x0
    800057e6:	dc0080e7          	jalr	-576(ra) # 800055a2 <argfd>
    return -1;
    800057ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057ec:	02054363          	bltz	a0,80005812 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800057f0:	fd843903          	ld	s2,-40(s0)
    800057f4:	854a                	mv	a0,s2
    800057f6:	00000097          	auipc	ra,0x0
    800057fa:	e0c080e7          	jalr	-500(ra) # 80005602 <fdalloc>
    800057fe:	84aa                	mv	s1,a0
    return -1;
    80005800:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005802:	00054863          	bltz	a0,80005812 <sys_dup+0x44>
  filedup(f);
    80005806:	854a                	mv	a0,s2
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	310080e7          	jalr	784(ra) # 80004b18 <filedup>
  return fd;
    80005810:	87a6                	mv	a5,s1
}
    80005812:	853e                	mv	a0,a5
    80005814:	70a2                	ld	ra,40(sp)
    80005816:	7402                	ld	s0,32(sp)
    80005818:	64e2                	ld	s1,24(sp)
    8000581a:	6942                	ld	s2,16(sp)
    8000581c:	6145                	addi	sp,sp,48
    8000581e:	8082                	ret

0000000080005820 <sys_read>:
{
    80005820:	7179                	addi	sp,sp,-48
    80005822:	f406                	sd	ra,40(sp)
    80005824:	f022                	sd	s0,32(sp)
    80005826:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005828:	fd840593          	addi	a1,s0,-40
    8000582c:	4505                	li	a0,1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	812080e7          	jalr	-2030(ra) # 80003040 <argaddr>
  argint(2, &n);
    80005836:	fe440593          	addi	a1,s0,-28
    8000583a:	4509                	li	a0,2
    8000583c:	ffffd097          	auipc	ra,0xffffd
    80005840:	7e4080e7          	jalr	2020(ra) # 80003020 <argint>
  if(argfd(0, 0, &f) < 0)
    80005844:	fe840613          	addi	a2,s0,-24
    80005848:	4581                	li	a1,0
    8000584a:	4501                	li	a0,0
    8000584c:	00000097          	auipc	ra,0x0
    80005850:	d56080e7          	jalr	-682(ra) # 800055a2 <argfd>
    80005854:	87aa                	mv	a5,a0
    return -1;
    80005856:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005858:	0007cc63          	bltz	a5,80005870 <sys_read+0x50>
  return fileread(f, p, n);
    8000585c:	fe442603          	lw	a2,-28(s0)
    80005860:	fd843583          	ld	a1,-40(s0)
    80005864:	fe843503          	ld	a0,-24(s0)
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	43c080e7          	jalr	1084(ra) # 80004ca4 <fileread>
}
    80005870:	70a2                	ld	ra,40(sp)
    80005872:	7402                	ld	s0,32(sp)
    80005874:	6145                	addi	sp,sp,48
    80005876:	8082                	ret

0000000080005878 <sys_write>:
{
    80005878:	7179                	addi	sp,sp,-48
    8000587a:	f406                	sd	ra,40(sp)
    8000587c:	f022                	sd	s0,32(sp)
    8000587e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005880:	fd840593          	addi	a1,s0,-40
    80005884:	4505                	li	a0,1
    80005886:	ffffd097          	auipc	ra,0xffffd
    8000588a:	7ba080e7          	jalr	1978(ra) # 80003040 <argaddr>
  argint(2, &n);
    8000588e:	fe440593          	addi	a1,s0,-28
    80005892:	4509                	li	a0,2
    80005894:	ffffd097          	auipc	ra,0xffffd
    80005898:	78c080e7          	jalr	1932(ra) # 80003020 <argint>
  if(argfd(0, 0, &f) < 0)
    8000589c:	fe840613          	addi	a2,s0,-24
    800058a0:	4581                	li	a1,0
    800058a2:	4501                	li	a0,0
    800058a4:	00000097          	auipc	ra,0x0
    800058a8:	cfe080e7          	jalr	-770(ra) # 800055a2 <argfd>
    800058ac:	87aa                	mv	a5,a0
    return -1;
    800058ae:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058b0:	0007cc63          	bltz	a5,800058c8 <sys_write+0x50>
  return filewrite(f, p, n);
    800058b4:	fe442603          	lw	a2,-28(s0)
    800058b8:	fd843583          	ld	a1,-40(s0)
    800058bc:	fe843503          	ld	a0,-24(s0)
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	4a6080e7          	jalr	1190(ra) # 80004d66 <filewrite>
}
    800058c8:	70a2                	ld	ra,40(sp)
    800058ca:	7402                	ld	s0,32(sp)
    800058cc:	6145                	addi	sp,sp,48
    800058ce:	8082                	ret

00000000800058d0 <sys_close>:
{
    800058d0:	1101                	addi	sp,sp,-32
    800058d2:	ec06                	sd	ra,24(sp)
    800058d4:	e822                	sd	s0,16(sp)
    800058d6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058d8:	fe040613          	addi	a2,s0,-32
    800058dc:	fec40593          	addi	a1,s0,-20
    800058e0:	4501                	li	a0,0
    800058e2:	00000097          	auipc	ra,0x0
    800058e6:	cc0080e7          	jalr	-832(ra) # 800055a2 <argfd>
    return -1;
    800058ea:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058ec:	02054463          	bltz	a0,80005914 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058f0:	ffffc097          	auipc	ra,0xffffc
    800058f4:	322080e7          	jalr	802(ra) # 80001c12 <myproc>
    800058f8:	fec42783          	lw	a5,-20(s0)
    800058fc:	07e9                	addi	a5,a5,26
    800058fe:	078e                	slli	a5,a5,0x3
    80005900:	953e                	add	a0,a0,a5
    80005902:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005906:	fe043503          	ld	a0,-32(s0)
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	260080e7          	jalr	608(ra) # 80004b6a <fileclose>
  return 0;
    80005912:	4781                	li	a5,0
}
    80005914:	853e                	mv	a0,a5
    80005916:	60e2                	ld	ra,24(sp)
    80005918:	6442                	ld	s0,16(sp)
    8000591a:	6105                	addi	sp,sp,32
    8000591c:	8082                	ret

000000008000591e <sys_fstat>:
{
    8000591e:	1101                	addi	sp,sp,-32
    80005920:	ec06                	sd	ra,24(sp)
    80005922:	e822                	sd	s0,16(sp)
    80005924:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005926:	fe040593          	addi	a1,s0,-32
    8000592a:	4505                	li	a0,1
    8000592c:	ffffd097          	auipc	ra,0xffffd
    80005930:	714080e7          	jalr	1812(ra) # 80003040 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005934:	fe840613          	addi	a2,s0,-24
    80005938:	4581                	li	a1,0
    8000593a:	4501                	li	a0,0
    8000593c:	00000097          	auipc	ra,0x0
    80005940:	c66080e7          	jalr	-922(ra) # 800055a2 <argfd>
    80005944:	87aa                	mv	a5,a0
    return -1;
    80005946:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005948:	0007ca63          	bltz	a5,8000595c <sys_fstat+0x3e>
  return filestat(f, st);
    8000594c:	fe043583          	ld	a1,-32(s0)
    80005950:	fe843503          	ld	a0,-24(s0)
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	2de080e7          	jalr	734(ra) # 80004c32 <filestat>
}
    8000595c:	60e2                	ld	ra,24(sp)
    8000595e:	6442                	ld	s0,16(sp)
    80005960:	6105                	addi	sp,sp,32
    80005962:	8082                	ret

0000000080005964 <sys_link>:
{
    80005964:	7169                	addi	sp,sp,-304
    80005966:	f606                	sd	ra,296(sp)
    80005968:	f222                	sd	s0,288(sp)
    8000596a:	ee26                	sd	s1,280(sp)
    8000596c:	ea4a                	sd	s2,272(sp)
    8000596e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005970:	08000613          	li	a2,128
    80005974:	ed040593          	addi	a1,s0,-304
    80005978:	4501                	li	a0,0
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	6e6080e7          	jalr	1766(ra) # 80003060 <argstr>
    return -1;
    80005982:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005984:	10054e63          	bltz	a0,80005aa0 <sys_link+0x13c>
    80005988:	08000613          	li	a2,128
    8000598c:	f5040593          	addi	a1,s0,-176
    80005990:	4505                	li	a0,1
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	6ce080e7          	jalr	1742(ra) # 80003060 <argstr>
    return -1;
    8000599a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000599c:	10054263          	bltz	a0,80005aa0 <sys_link+0x13c>
  begin_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	d02080e7          	jalr	-766(ra) # 800046a2 <begin_op>
  if((ip = namei(old)) == 0){
    800059a8:	ed040513          	addi	a0,s0,-304
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	ad6080e7          	jalr	-1322(ra) # 80004482 <namei>
    800059b4:	84aa                	mv	s1,a0
    800059b6:	c551                	beqz	a0,80005a42 <sys_link+0xde>
  ilock(ip);
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	31e080e7          	jalr	798(ra) # 80003cd6 <ilock>
  if(ip->type == T_DIR){
    800059c0:	04449703          	lh	a4,68(s1)
    800059c4:	4785                	li	a5,1
    800059c6:	08f70463          	beq	a4,a5,80005a4e <sys_link+0xea>
  ip->nlink++;
    800059ca:	04a4d783          	lhu	a5,74(s1)
    800059ce:	2785                	addiw	a5,a5,1
    800059d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059d4:	8526                	mv	a0,s1
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	234080e7          	jalr	564(ra) # 80003c0a <iupdate>
  iunlock(ip);
    800059de:	8526                	mv	a0,s1
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	3b8080e7          	jalr	952(ra) # 80003d98 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059e8:	fd040593          	addi	a1,s0,-48
    800059ec:	f5040513          	addi	a0,s0,-176
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	ab0080e7          	jalr	-1360(ra) # 800044a0 <nameiparent>
    800059f8:	892a                	mv	s2,a0
    800059fa:	c935                	beqz	a0,80005a6e <sys_link+0x10a>
  ilock(dp);
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	2da080e7          	jalr	730(ra) # 80003cd6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a04:	00092703          	lw	a4,0(s2)
    80005a08:	409c                	lw	a5,0(s1)
    80005a0a:	04f71d63          	bne	a4,a5,80005a64 <sys_link+0x100>
    80005a0e:	40d0                	lw	a2,4(s1)
    80005a10:	fd040593          	addi	a1,s0,-48
    80005a14:	854a                	mv	a0,s2
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	9ba080e7          	jalr	-1606(ra) # 800043d0 <dirlink>
    80005a1e:	04054363          	bltz	a0,80005a64 <sys_link+0x100>
  iunlockput(dp);
    80005a22:	854a                	mv	a0,s2
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	514080e7          	jalr	1300(ra) # 80003f38 <iunlockput>
  iput(ip);
    80005a2c:	8526                	mv	a0,s1
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	462080e7          	jalr	1122(ra) # 80003e90 <iput>
  end_op();
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	cea080e7          	jalr	-790(ra) # 80004720 <end_op>
  return 0;
    80005a3e:	4781                	li	a5,0
    80005a40:	a085                	j	80005aa0 <sys_link+0x13c>
    end_op();
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	cde080e7          	jalr	-802(ra) # 80004720 <end_op>
    return -1;
    80005a4a:	57fd                	li	a5,-1
    80005a4c:	a891                	j	80005aa0 <sys_link+0x13c>
    iunlockput(ip);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	4e8080e7          	jalr	1256(ra) # 80003f38 <iunlockput>
    end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	cc8080e7          	jalr	-824(ra) # 80004720 <end_op>
    return -1;
    80005a60:	57fd                	li	a5,-1
    80005a62:	a83d                	j	80005aa0 <sys_link+0x13c>
    iunlockput(dp);
    80005a64:	854a                	mv	a0,s2
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	4d2080e7          	jalr	1234(ra) # 80003f38 <iunlockput>
  ilock(ip);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	266080e7          	jalr	614(ra) # 80003cd6 <ilock>
  ip->nlink--;
    80005a78:	04a4d783          	lhu	a5,74(s1)
    80005a7c:	37fd                	addiw	a5,a5,-1
    80005a7e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a82:	8526                	mv	a0,s1
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	186080e7          	jalr	390(ra) # 80003c0a <iupdate>
  iunlockput(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	4aa080e7          	jalr	1194(ra) # 80003f38 <iunlockput>
  end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	c8a080e7          	jalr	-886(ra) # 80004720 <end_op>
  return -1;
    80005a9e:	57fd                	li	a5,-1
}
    80005aa0:	853e                	mv	a0,a5
    80005aa2:	70b2                	ld	ra,296(sp)
    80005aa4:	7412                	ld	s0,288(sp)
    80005aa6:	64f2                	ld	s1,280(sp)
    80005aa8:	6952                	ld	s2,272(sp)
    80005aaa:	6155                	addi	sp,sp,304
    80005aac:	8082                	ret

0000000080005aae <sys_unlink>:
{
    80005aae:	7151                	addi	sp,sp,-240
    80005ab0:	f586                	sd	ra,232(sp)
    80005ab2:	f1a2                	sd	s0,224(sp)
    80005ab4:	eda6                	sd	s1,216(sp)
    80005ab6:	e9ca                	sd	s2,208(sp)
    80005ab8:	e5ce                	sd	s3,200(sp)
    80005aba:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005abc:	08000613          	li	a2,128
    80005ac0:	f3040593          	addi	a1,s0,-208
    80005ac4:	4501                	li	a0,0
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	59a080e7          	jalr	1434(ra) # 80003060 <argstr>
    80005ace:	18054163          	bltz	a0,80005c50 <sys_unlink+0x1a2>
  begin_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	bd0080e7          	jalr	-1072(ra) # 800046a2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ada:	fb040593          	addi	a1,s0,-80
    80005ade:	f3040513          	addi	a0,s0,-208
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	9be080e7          	jalr	-1602(ra) # 800044a0 <nameiparent>
    80005aea:	84aa                	mv	s1,a0
    80005aec:	c979                	beqz	a0,80005bc2 <sys_unlink+0x114>
  ilock(dp);
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	1e8080e7          	jalr	488(ra) # 80003cd6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005af6:	00003597          	auipc	a1,0x3
    80005afa:	da258593          	addi	a1,a1,-606 # 80008898 <syscalls+0x2c8>
    80005afe:	fb040513          	addi	a0,s0,-80
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	69e080e7          	jalr	1694(ra) # 800041a0 <namecmp>
    80005b0a:	14050a63          	beqz	a0,80005c5e <sys_unlink+0x1b0>
    80005b0e:	00003597          	auipc	a1,0x3
    80005b12:	d9258593          	addi	a1,a1,-622 # 800088a0 <syscalls+0x2d0>
    80005b16:	fb040513          	addi	a0,s0,-80
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	686080e7          	jalr	1670(ra) # 800041a0 <namecmp>
    80005b22:	12050e63          	beqz	a0,80005c5e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b26:	f2c40613          	addi	a2,s0,-212
    80005b2a:	fb040593          	addi	a1,s0,-80
    80005b2e:	8526                	mv	a0,s1
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	68a080e7          	jalr	1674(ra) # 800041ba <dirlookup>
    80005b38:	892a                	mv	s2,a0
    80005b3a:	12050263          	beqz	a0,80005c5e <sys_unlink+0x1b0>
  ilock(ip);
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	198080e7          	jalr	408(ra) # 80003cd6 <ilock>
  if(ip->nlink < 1)
    80005b46:	04a91783          	lh	a5,74(s2)
    80005b4a:	08f05263          	blez	a5,80005bce <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b4e:	04491703          	lh	a4,68(s2)
    80005b52:	4785                	li	a5,1
    80005b54:	08f70563          	beq	a4,a5,80005bde <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b58:	4641                	li	a2,16
    80005b5a:	4581                	li	a1,0
    80005b5c:	fc040513          	addi	a0,s0,-64
    80005b60:	ffffb097          	auipc	ra,0xffffb
    80005b64:	23a080e7          	jalr	570(ra) # 80000d9a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b68:	4741                	li	a4,16
    80005b6a:	f2c42683          	lw	a3,-212(s0)
    80005b6e:	fc040613          	addi	a2,s0,-64
    80005b72:	4581                	li	a1,0
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	50c080e7          	jalr	1292(ra) # 80004082 <writei>
    80005b7e:	47c1                	li	a5,16
    80005b80:	0af51563          	bne	a0,a5,80005c2a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b84:	04491703          	lh	a4,68(s2)
    80005b88:	4785                	li	a5,1
    80005b8a:	0af70863          	beq	a4,a5,80005c3a <sys_unlink+0x18c>
  iunlockput(dp);
    80005b8e:	8526                	mv	a0,s1
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	3a8080e7          	jalr	936(ra) # 80003f38 <iunlockput>
  ip->nlink--;
    80005b98:	04a95783          	lhu	a5,74(s2)
    80005b9c:	37fd                	addiw	a5,a5,-1
    80005b9e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ba2:	854a                	mv	a0,s2
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	066080e7          	jalr	102(ra) # 80003c0a <iupdate>
  iunlockput(ip);
    80005bac:	854a                	mv	a0,s2
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	38a080e7          	jalr	906(ra) # 80003f38 <iunlockput>
  end_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	b6a080e7          	jalr	-1174(ra) # 80004720 <end_op>
  return 0;
    80005bbe:	4501                	li	a0,0
    80005bc0:	a84d                	j	80005c72 <sys_unlink+0x1c4>
    end_op();
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	b5e080e7          	jalr	-1186(ra) # 80004720 <end_op>
    return -1;
    80005bca:	557d                	li	a0,-1
    80005bcc:	a05d                	j	80005c72 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bce:	00003517          	auipc	a0,0x3
    80005bd2:	cda50513          	addi	a0,a0,-806 # 800088a8 <syscalls+0x2d8>
    80005bd6:	ffffb097          	auipc	ra,0xffffb
    80005bda:	96a080e7          	jalr	-1686(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bde:	04c92703          	lw	a4,76(s2)
    80005be2:	02000793          	li	a5,32
    80005be6:	f6e7f9e3          	bgeu	a5,a4,80005b58 <sys_unlink+0xaa>
    80005bea:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bee:	4741                	li	a4,16
    80005bf0:	86ce                	mv	a3,s3
    80005bf2:	f1840613          	addi	a2,s0,-232
    80005bf6:	4581                	li	a1,0
    80005bf8:	854a                	mv	a0,s2
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	390080e7          	jalr	912(ra) # 80003f8a <readi>
    80005c02:	47c1                	li	a5,16
    80005c04:	00f51b63          	bne	a0,a5,80005c1a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c08:	f1845783          	lhu	a5,-232(s0)
    80005c0c:	e7a1                	bnez	a5,80005c54 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c0e:	29c1                	addiw	s3,s3,16
    80005c10:	04c92783          	lw	a5,76(s2)
    80005c14:	fcf9ede3          	bltu	s3,a5,80005bee <sys_unlink+0x140>
    80005c18:	b781                	j	80005b58 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c1a:	00003517          	auipc	a0,0x3
    80005c1e:	ca650513          	addi	a0,a0,-858 # 800088c0 <syscalls+0x2f0>
    80005c22:	ffffb097          	auipc	ra,0xffffb
    80005c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005c2a:	00003517          	auipc	a0,0x3
    80005c2e:	cae50513          	addi	a0,a0,-850 # 800088d8 <syscalls+0x308>
    80005c32:	ffffb097          	auipc	ra,0xffffb
    80005c36:	90e080e7          	jalr	-1778(ra) # 80000540 <panic>
    dp->nlink--;
    80005c3a:	04a4d783          	lhu	a5,74(s1)
    80005c3e:	37fd                	addiw	a5,a5,-1
    80005c40:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c44:	8526                	mv	a0,s1
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	fc4080e7          	jalr	-60(ra) # 80003c0a <iupdate>
    80005c4e:	b781                	j	80005b8e <sys_unlink+0xe0>
    return -1;
    80005c50:	557d                	li	a0,-1
    80005c52:	a005                	j	80005c72 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c54:	854a                	mv	a0,s2
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	2e2080e7          	jalr	738(ra) # 80003f38 <iunlockput>
  iunlockput(dp);
    80005c5e:	8526                	mv	a0,s1
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	2d8080e7          	jalr	728(ra) # 80003f38 <iunlockput>
  end_op();
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	ab8080e7          	jalr	-1352(ra) # 80004720 <end_op>
  return -1;
    80005c70:	557d                	li	a0,-1
}
    80005c72:	70ae                	ld	ra,232(sp)
    80005c74:	740e                	ld	s0,224(sp)
    80005c76:	64ee                	ld	s1,216(sp)
    80005c78:	694e                	ld	s2,208(sp)
    80005c7a:	69ae                	ld	s3,200(sp)
    80005c7c:	616d                	addi	sp,sp,240
    80005c7e:	8082                	ret

0000000080005c80 <sys_open>:

uint64
sys_open(void)
{
    80005c80:	7131                	addi	sp,sp,-192
    80005c82:	fd06                	sd	ra,184(sp)
    80005c84:	f922                	sd	s0,176(sp)
    80005c86:	f526                	sd	s1,168(sp)
    80005c88:	f14a                	sd	s2,160(sp)
    80005c8a:	ed4e                	sd	s3,152(sp)
    80005c8c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c8e:	f4c40593          	addi	a1,s0,-180
    80005c92:	4505                	li	a0,1
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	38c080e7          	jalr	908(ra) # 80003020 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c9c:	08000613          	li	a2,128
    80005ca0:	f5040593          	addi	a1,s0,-176
    80005ca4:	4501                	li	a0,0
    80005ca6:	ffffd097          	auipc	ra,0xffffd
    80005caa:	3ba080e7          	jalr	954(ra) # 80003060 <argstr>
    80005cae:	87aa                	mv	a5,a0
    return -1;
    80005cb0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cb2:	0a07c963          	bltz	a5,80005d64 <sys_open+0xe4>

  begin_op();
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	9ec080e7          	jalr	-1556(ra) # 800046a2 <begin_op>

  if(omode & O_CREATE){
    80005cbe:	f4c42783          	lw	a5,-180(s0)
    80005cc2:	2007f793          	andi	a5,a5,512
    80005cc6:	cfc5                	beqz	a5,80005d7e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cc8:	4681                	li	a3,0
    80005cca:	4601                	li	a2,0
    80005ccc:	4589                	li	a1,2
    80005cce:	f5040513          	addi	a0,s0,-176
    80005cd2:	00000097          	auipc	ra,0x0
    80005cd6:	972080e7          	jalr	-1678(ra) # 80005644 <create>
    80005cda:	84aa                	mv	s1,a0
    if(ip == 0){
    80005cdc:	c959                	beqz	a0,80005d72 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cde:	04449703          	lh	a4,68(s1)
    80005ce2:	478d                	li	a5,3
    80005ce4:	00f71763          	bne	a4,a5,80005cf2 <sys_open+0x72>
    80005ce8:	0464d703          	lhu	a4,70(s1)
    80005cec:	47a5                	li	a5,9
    80005cee:	0ce7ed63          	bltu	a5,a4,80005dc8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	dbc080e7          	jalr	-580(ra) # 80004aae <filealloc>
    80005cfa:	89aa                	mv	s3,a0
    80005cfc:	10050363          	beqz	a0,80005e02 <sys_open+0x182>
    80005d00:	00000097          	auipc	ra,0x0
    80005d04:	902080e7          	jalr	-1790(ra) # 80005602 <fdalloc>
    80005d08:	892a                	mv	s2,a0
    80005d0a:	0e054763          	bltz	a0,80005df8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d0e:	04449703          	lh	a4,68(s1)
    80005d12:	478d                	li	a5,3
    80005d14:	0cf70563          	beq	a4,a5,80005dde <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d18:	4789                	li	a5,2
    80005d1a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d1e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d22:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d26:	f4c42783          	lw	a5,-180(s0)
    80005d2a:	0017c713          	xori	a4,a5,1
    80005d2e:	8b05                	andi	a4,a4,1
    80005d30:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d34:	0037f713          	andi	a4,a5,3
    80005d38:	00e03733          	snez	a4,a4
    80005d3c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d40:	4007f793          	andi	a5,a5,1024
    80005d44:	c791                	beqz	a5,80005d50 <sys_open+0xd0>
    80005d46:	04449703          	lh	a4,68(s1)
    80005d4a:	4789                	li	a5,2
    80005d4c:	0af70063          	beq	a4,a5,80005dec <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d50:	8526                	mv	a0,s1
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	046080e7          	jalr	70(ra) # 80003d98 <iunlock>
  end_op();
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	9c6080e7          	jalr	-1594(ra) # 80004720 <end_op>

  return fd;
    80005d62:	854a                	mv	a0,s2
}
    80005d64:	70ea                	ld	ra,184(sp)
    80005d66:	744a                	ld	s0,176(sp)
    80005d68:	74aa                	ld	s1,168(sp)
    80005d6a:	790a                	ld	s2,160(sp)
    80005d6c:	69ea                	ld	s3,152(sp)
    80005d6e:	6129                	addi	sp,sp,192
    80005d70:	8082                	ret
      end_op();
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	9ae080e7          	jalr	-1618(ra) # 80004720 <end_op>
      return -1;
    80005d7a:	557d                	li	a0,-1
    80005d7c:	b7e5                	j	80005d64 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d7e:	f5040513          	addi	a0,s0,-176
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	700080e7          	jalr	1792(ra) # 80004482 <namei>
    80005d8a:	84aa                	mv	s1,a0
    80005d8c:	c905                	beqz	a0,80005dbc <sys_open+0x13c>
    ilock(ip);
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	f48080e7          	jalr	-184(ra) # 80003cd6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d96:	04449703          	lh	a4,68(s1)
    80005d9a:	4785                	li	a5,1
    80005d9c:	f4f711e3          	bne	a4,a5,80005cde <sys_open+0x5e>
    80005da0:	f4c42783          	lw	a5,-180(s0)
    80005da4:	d7b9                	beqz	a5,80005cf2 <sys_open+0x72>
      iunlockput(ip);
    80005da6:	8526                	mv	a0,s1
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	190080e7          	jalr	400(ra) # 80003f38 <iunlockput>
      end_op();
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	970080e7          	jalr	-1680(ra) # 80004720 <end_op>
      return -1;
    80005db8:	557d                	li	a0,-1
    80005dba:	b76d                	j	80005d64 <sys_open+0xe4>
      end_op();
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	964080e7          	jalr	-1692(ra) # 80004720 <end_op>
      return -1;
    80005dc4:	557d                	li	a0,-1
    80005dc6:	bf79                	j	80005d64 <sys_open+0xe4>
    iunlockput(ip);
    80005dc8:	8526                	mv	a0,s1
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	16e080e7          	jalr	366(ra) # 80003f38 <iunlockput>
    end_op();
    80005dd2:	fffff097          	auipc	ra,0xfffff
    80005dd6:	94e080e7          	jalr	-1714(ra) # 80004720 <end_op>
    return -1;
    80005dda:	557d                	li	a0,-1
    80005ddc:	b761                	j	80005d64 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dde:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005de2:	04649783          	lh	a5,70(s1)
    80005de6:	02f99223          	sh	a5,36(s3)
    80005dea:	bf25                	j	80005d22 <sys_open+0xa2>
    itrunc(ip);
    80005dec:	8526                	mv	a0,s1
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	ff6080e7          	jalr	-10(ra) # 80003de4 <itrunc>
    80005df6:	bfa9                	j	80005d50 <sys_open+0xd0>
      fileclose(f);
    80005df8:	854e                	mv	a0,s3
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	d70080e7          	jalr	-656(ra) # 80004b6a <fileclose>
    iunlockput(ip);
    80005e02:	8526                	mv	a0,s1
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	134080e7          	jalr	308(ra) # 80003f38 <iunlockput>
    end_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	914080e7          	jalr	-1772(ra) # 80004720 <end_op>
    return -1;
    80005e14:	557d                	li	a0,-1
    80005e16:	b7b9                	j	80005d64 <sys_open+0xe4>

0000000080005e18 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e18:	7175                	addi	sp,sp,-144
    80005e1a:	e506                	sd	ra,136(sp)
    80005e1c:	e122                	sd	s0,128(sp)
    80005e1e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	882080e7          	jalr	-1918(ra) # 800046a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e28:	08000613          	li	a2,128
    80005e2c:	f7040593          	addi	a1,s0,-144
    80005e30:	4501                	li	a0,0
    80005e32:	ffffd097          	auipc	ra,0xffffd
    80005e36:	22e080e7          	jalr	558(ra) # 80003060 <argstr>
    80005e3a:	02054963          	bltz	a0,80005e6c <sys_mkdir+0x54>
    80005e3e:	4681                	li	a3,0
    80005e40:	4601                	li	a2,0
    80005e42:	4585                	li	a1,1
    80005e44:	f7040513          	addi	a0,s0,-144
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	7fc080e7          	jalr	2044(ra) # 80005644 <create>
    80005e50:	cd11                	beqz	a0,80005e6c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	0e6080e7          	jalr	230(ra) # 80003f38 <iunlockput>
  end_op();
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	8c6080e7          	jalr	-1850(ra) # 80004720 <end_op>
  return 0;
    80005e62:	4501                	li	a0,0
}
    80005e64:	60aa                	ld	ra,136(sp)
    80005e66:	640a                	ld	s0,128(sp)
    80005e68:	6149                	addi	sp,sp,144
    80005e6a:	8082                	ret
    end_op();
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	8b4080e7          	jalr	-1868(ra) # 80004720 <end_op>
    return -1;
    80005e74:	557d                	li	a0,-1
    80005e76:	b7fd                	j	80005e64 <sys_mkdir+0x4c>

0000000080005e78 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e78:	7135                	addi	sp,sp,-160
    80005e7a:	ed06                	sd	ra,152(sp)
    80005e7c:	e922                	sd	s0,144(sp)
    80005e7e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	822080e7          	jalr	-2014(ra) # 800046a2 <begin_op>
  argint(1, &major);
    80005e88:	f6c40593          	addi	a1,s0,-148
    80005e8c:	4505                	li	a0,1
    80005e8e:	ffffd097          	auipc	ra,0xffffd
    80005e92:	192080e7          	jalr	402(ra) # 80003020 <argint>
  argint(2, &minor);
    80005e96:	f6840593          	addi	a1,s0,-152
    80005e9a:	4509                	li	a0,2
    80005e9c:	ffffd097          	auipc	ra,0xffffd
    80005ea0:	184080e7          	jalr	388(ra) # 80003020 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ea4:	08000613          	li	a2,128
    80005ea8:	f7040593          	addi	a1,s0,-144
    80005eac:	4501                	li	a0,0
    80005eae:	ffffd097          	auipc	ra,0xffffd
    80005eb2:	1b2080e7          	jalr	434(ra) # 80003060 <argstr>
    80005eb6:	02054b63          	bltz	a0,80005eec <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005eba:	f6841683          	lh	a3,-152(s0)
    80005ebe:	f6c41603          	lh	a2,-148(s0)
    80005ec2:	458d                	li	a1,3
    80005ec4:	f7040513          	addi	a0,s0,-144
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	77c080e7          	jalr	1916(ra) # 80005644 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ed0:	cd11                	beqz	a0,80005eec <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ed2:	ffffe097          	auipc	ra,0xffffe
    80005ed6:	066080e7          	jalr	102(ra) # 80003f38 <iunlockput>
  end_op();
    80005eda:	fffff097          	auipc	ra,0xfffff
    80005ede:	846080e7          	jalr	-1978(ra) # 80004720 <end_op>
  return 0;
    80005ee2:	4501                	li	a0,0
}
    80005ee4:	60ea                	ld	ra,152(sp)
    80005ee6:	644a                	ld	s0,144(sp)
    80005ee8:	610d                	addi	sp,sp,160
    80005eea:	8082                	ret
    end_op();
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	834080e7          	jalr	-1996(ra) # 80004720 <end_op>
    return -1;
    80005ef4:	557d                	li	a0,-1
    80005ef6:	b7fd                	j	80005ee4 <sys_mknod+0x6c>

0000000080005ef8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ef8:	7135                	addi	sp,sp,-160
    80005efa:	ed06                	sd	ra,152(sp)
    80005efc:	e922                	sd	s0,144(sp)
    80005efe:	e526                	sd	s1,136(sp)
    80005f00:	e14a                	sd	s2,128(sp)
    80005f02:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f04:	ffffc097          	auipc	ra,0xffffc
    80005f08:	d0e080e7          	jalr	-754(ra) # 80001c12 <myproc>
    80005f0c:	892a                	mv	s2,a0
  
  begin_op();
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	794080e7          	jalr	1940(ra) # 800046a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f16:	08000613          	li	a2,128
    80005f1a:	f6040593          	addi	a1,s0,-160
    80005f1e:	4501                	li	a0,0
    80005f20:	ffffd097          	auipc	ra,0xffffd
    80005f24:	140080e7          	jalr	320(ra) # 80003060 <argstr>
    80005f28:	04054b63          	bltz	a0,80005f7e <sys_chdir+0x86>
    80005f2c:	f6040513          	addi	a0,s0,-160
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	552080e7          	jalr	1362(ra) # 80004482 <namei>
    80005f38:	84aa                	mv	s1,a0
    80005f3a:	c131                	beqz	a0,80005f7e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f3c:	ffffe097          	auipc	ra,0xffffe
    80005f40:	d9a080e7          	jalr	-614(ra) # 80003cd6 <ilock>
  if(ip->type != T_DIR){
    80005f44:	04449703          	lh	a4,68(s1)
    80005f48:	4785                	li	a5,1
    80005f4a:	04f71063          	bne	a4,a5,80005f8a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f4e:	8526                	mv	a0,s1
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	e48080e7          	jalr	-440(ra) # 80003d98 <iunlock>
  iput(p->cwd);
    80005f58:	15093503          	ld	a0,336(s2)
    80005f5c:	ffffe097          	auipc	ra,0xffffe
    80005f60:	f34080e7          	jalr	-204(ra) # 80003e90 <iput>
  end_op();
    80005f64:	ffffe097          	auipc	ra,0xffffe
    80005f68:	7bc080e7          	jalr	1980(ra) # 80004720 <end_op>
  p->cwd = ip;
    80005f6c:	14993823          	sd	s1,336(s2)
  return 0;
    80005f70:	4501                	li	a0,0
}
    80005f72:	60ea                	ld	ra,152(sp)
    80005f74:	644a                	ld	s0,144(sp)
    80005f76:	64aa                	ld	s1,136(sp)
    80005f78:	690a                	ld	s2,128(sp)
    80005f7a:	610d                	addi	sp,sp,160
    80005f7c:	8082                	ret
    end_op();
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	7a2080e7          	jalr	1954(ra) # 80004720 <end_op>
    return -1;
    80005f86:	557d                	li	a0,-1
    80005f88:	b7ed                	j	80005f72 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f8a:	8526                	mv	a0,s1
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	fac080e7          	jalr	-84(ra) # 80003f38 <iunlockput>
    end_op();
    80005f94:	ffffe097          	auipc	ra,0xffffe
    80005f98:	78c080e7          	jalr	1932(ra) # 80004720 <end_op>
    return -1;
    80005f9c:	557d                	li	a0,-1
    80005f9e:	bfd1                	j	80005f72 <sys_chdir+0x7a>

0000000080005fa0 <sys_exec>:

uint64
sys_exec(void)
{
    80005fa0:	7145                	addi	sp,sp,-464
    80005fa2:	e786                	sd	ra,456(sp)
    80005fa4:	e3a2                	sd	s0,448(sp)
    80005fa6:	ff26                	sd	s1,440(sp)
    80005fa8:	fb4a                	sd	s2,432(sp)
    80005faa:	f74e                	sd	s3,424(sp)
    80005fac:	f352                	sd	s4,416(sp)
    80005fae:	ef56                	sd	s5,408(sp)
    80005fb0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005fb2:	e3840593          	addi	a1,s0,-456
    80005fb6:	4505                	li	a0,1
    80005fb8:	ffffd097          	auipc	ra,0xffffd
    80005fbc:	088080e7          	jalr	136(ra) # 80003040 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005fc0:	08000613          	li	a2,128
    80005fc4:	f4040593          	addi	a1,s0,-192
    80005fc8:	4501                	li	a0,0
    80005fca:	ffffd097          	auipc	ra,0xffffd
    80005fce:	096080e7          	jalr	150(ra) # 80003060 <argstr>
    80005fd2:	87aa                	mv	a5,a0
    return -1;
    80005fd4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005fd6:	0c07c363          	bltz	a5,8000609c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005fda:	10000613          	li	a2,256
    80005fde:	4581                	li	a1,0
    80005fe0:	e4040513          	addi	a0,s0,-448
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	db6080e7          	jalr	-586(ra) # 80000d9a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ff0:	89a6                	mv	s3,s1
    80005ff2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ff4:	02000a13          	li	s4,32
    80005ff8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ffc:	00391513          	slli	a0,s2,0x3
    80006000:	e3040593          	addi	a1,s0,-464
    80006004:	e3843783          	ld	a5,-456(s0)
    80006008:	953e                	add	a0,a0,a5
    8000600a:	ffffd097          	auipc	ra,0xffffd
    8000600e:	f78080e7          	jalr	-136(ra) # 80002f82 <fetchaddr>
    80006012:	02054a63          	bltz	a0,80006046 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006016:	e3043783          	ld	a5,-464(s0)
    8000601a:	c3b9                	beqz	a5,80006060 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	b46080e7          	jalr	-1210(ra) # 80000b62 <kalloc>
    80006024:	85aa                	mv	a1,a0
    80006026:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000602a:	cd11                	beqz	a0,80006046 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000602c:	6605                	lui	a2,0x1
    8000602e:	e3043503          	ld	a0,-464(s0)
    80006032:	ffffd097          	auipc	ra,0xffffd
    80006036:	fa2080e7          	jalr	-94(ra) # 80002fd4 <fetchstr>
    8000603a:	00054663          	bltz	a0,80006046 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000603e:	0905                	addi	s2,s2,1
    80006040:	09a1                	addi	s3,s3,8
    80006042:	fb491be3          	bne	s2,s4,80005ff8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006046:	f4040913          	addi	s2,s0,-192
    8000604a:	6088                	ld	a0,0(s1)
    8000604c:	c539                	beqz	a0,8000609a <sys_exec+0xfa>
    kfree(argv[i]);
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	9ac080e7          	jalr	-1620(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006056:	04a1                	addi	s1,s1,8
    80006058:	ff2499e3          	bne	s1,s2,8000604a <sys_exec+0xaa>
  return -1;
    8000605c:	557d                	li	a0,-1
    8000605e:	a83d                	j	8000609c <sys_exec+0xfc>
      argv[i] = 0;
    80006060:	0a8e                	slli	s5,s5,0x3
    80006062:	fc0a8793          	addi	a5,s5,-64
    80006066:	00878ab3          	add	s5,a5,s0
    8000606a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000606e:	e4040593          	addi	a1,s0,-448
    80006072:	f4040513          	addi	a0,s0,-192
    80006076:	fffff097          	auipc	ra,0xfffff
    8000607a:	16e080e7          	jalr	366(ra) # 800051e4 <exec>
    8000607e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006080:	f4040993          	addi	s3,s0,-192
    80006084:	6088                	ld	a0,0(s1)
    80006086:	c901                	beqz	a0,80006096 <sys_exec+0xf6>
    kfree(argv[i]);
    80006088:	ffffb097          	auipc	ra,0xffffb
    8000608c:	972080e7          	jalr	-1678(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006090:	04a1                	addi	s1,s1,8
    80006092:	ff3499e3          	bne	s1,s3,80006084 <sys_exec+0xe4>
  return ret;
    80006096:	854a                	mv	a0,s2
    80006098:	a011                	j	8000609c <sys_exec+0xfc>
  return -1;
    8000609a:	557d                	li	a0,-1
}
    8000609c:	60be                	ld	ra,456(sp)
    8000609e:	641e                	ld	s0,448(sp)
    800060a0:	74fa                	ld	s1,440(sp)
    800060a2:	795a                	ld	s2,432(sp)
    800060a4:	79ba                	ld	s3,424(sp)
    800060a6:	7a1a                	ld	s4,416(sp)
    800060a8:	6afa                	ld	s5,408(sp)
    800060aa:	6179                	addi	sp,sp,464
    800060ac:	8082                	ret

00000000800060ae <sys_pipe>:

uint64
sys_pipe(void)
{
    800060ae:	7139                	addi	sp,sp,-64
    800060b0:	fc06                	sd	ra,56(sp)
    800060b2:	f822                	sd	s0,48(sp)
    800060b4:	f426                	sd	s1,40(sp)
    800060b6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	b5a080e7          	jalr	-1190(ra) # 80001c12 <myproc>
    800060c0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800060c2:	fd840593          	addi	a1,s0,-40
    800060c6:	4501                	li	a0,0
    800060c8:	ffffd097          	auipc	ra,0xffffd
    800060cc:	f78080e7          	jalr	-136(ra) # 80003040 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800060d0:	fc840593          	addi	a1,s0,-56
    800060d4:	fd040513          	addi	a0,s0,-48
    800060d8:	fffff097          	auipc	ra,0xfffff
    800060dc:	dc2080e7          	jalr	-574(ra) # 80004e9a <pipealloc>
    return -1;
    800060e0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060e2:	0c054463          	bltz	a0,800061aa <sys_pipe+0xfc>
  fd0 = -1;
    800060e6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060ea:	fd043503          	ld	a0,-48(s0)
    800060ee:	fffff097          	auipc	ra,0xfffff
    800060f2:	514080e7          	jalr	1300(ra) # 80005602 <fdalloc>
    800060f6:	fca42223          	sw	a0,-60(s0)
    800060fa:	08054b63          	bltz	a0,80006190 <sys_pipe+0xe2>
    800060fe:	fc843503          	ld	a0,-56(s0)
    80006102:	fffff097          	auipc	ra,0xfffff
    80006106:	500080e7          	jalr	1280(ra) # 80005602 <fdalloc>
    8000610a:	fca42023          	sw	a0,-64(s0)
    8000610e:	06054863          	bltz	a0,8000617e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006112:	4691                	li	a3,4
    80006114:	fc440613          	addi	a2,s0,-60
    80006118:	fd843583          	ld	a1,-40(s0)
    8000611c:	68a8                	ld	a0,80(s1)
    8000611e:	ffffb097          	auipc	ra,0xffffb
    80006122:	6b6080e7          	jalr	1718(ra) # 800017d4 <copyout>
    80006126:	02054063          	bltz	a0,80006146 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000612a:	4691                	li	a3,4
    8000612c:	fc040613          	addi	a2,s0,-64
    80006130:	fd843583          	ld	a1,-40(s0)
    80006134:	0591                	addi	a1,a1,4
    80006136:	68a8                	ld	a0,80(s1)
    80006138:	ffffb097          	auipc	ra,0xffffb
    8000613c:	69c080e7          	jalr	1692(ra) # 800017d4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006140:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006142:	06055463          	bgez	a0,800061aa <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006146:	fc442783          	lw	a5,-60(s0)
    8000614a:	07e9                	addi	a5,a5,26
    8000614c:	078e                	slli	a5,a5,0x3
    8000614e:	97a6                	add	a5,a5,s1
    80006150:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006154:	fc042783          	lw	a5,-64(s0)
    80006158:	07e9                	addi	a5,a5,26
    8000615a:	078e                	slli	a5,a5,0x3
    8000615c:	94be                	add	s1,s1,a5
    8000615e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006162:	fd043503          	ld	a0,-48(s0)
    80006166:	fffff097          	auipc	ra,0xfffff
    8000616a:	a04080e7          	jalr	-1532(ra) # 80004b6a <fileclose>
    fileclose(wf);
    8000616e:	fc843503          	ld	a0,-56(s0)
    80006172:	fffff097          	auipc	ra,0xfffff
    80006176:	9f8080e7          	jalr	-1544(ra) # 80004b6a <fileclose>
    return -1;
    8000617a:	57fd                	li	a5,-1
    8000617c:	a03d                	j	800061aa <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000617e:	fc442783          	lw	a5,-60(s0)
    80006182:	0007c763          	bltz	a5,80006190 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006186:	07e9                	addi	a5,a5,26
    80006188:	078e                	slli	a5,a5,0x3
    8000618a:	97a6                	add	a5,a5,s1
    8000618c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006190:	fd043503          	ld	a0,-48(s0)
    80006194:	fffff097          	auipc	ra,0xfffff
    80006198:	9d6080e7          	jalr	-1578(ra) # 80004b6a <fileclose>
    fileclose(wf);
    8000619c:	fc843503          	ld	a0,-56(s0)
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	9ca080e7          	jalr	-1590(ra) # 80004b6a <fileclose>
    return -1;
    800061a8:	57fd                	li	a5,-1
}
    800061aa:	853e                	mv	a0,a5
    800061ac:	70e2                	ld	ra,56(sp)
    800061ae:	7442                	ld	s0,48(sp)
    800061b0:	74a2                	ld	s1,40(sp)
    800061b2:	6121                	addi	sp,sp,64
    800061b4:	8082                	ret
	...

00000000800061c0 <kernelvec>:
    800061c0:	7111                	addi	sp,sp,-256
    800061c2:	e006                	sd	ra,0(sp)
    800061c4:	e40a                	sd	sp,8(sp)
    800061c6:	e80e                	sd	gp,16(sp)
    800061c8:	ec12                	sd	tp,24(sp)
    800061ca:	f016                	sd	t0,32(sp)
    800061cc:	f41a                	sd	t1,40(sp)
    800061ce:	f81e                	sd	t2,48(sp)
    800061d0:	fc22                	sd	s0,56(sp)
    800061d2:	e0a6                	sd	s1,64(sp)
    800061d4:	e4aa                	sd	a0,72(sp)
    800061d6:	e8ae                	sd	a1,80(sp)
    800061d8:	ecb2                	sd	a2,88(sp)
    800061da:	f0b6                	sd	a3,96(sp)
    800061dc:	f4ba                	sd	a4,104(sp)
    800061de:	f8be                	sd	a5,112(sp)
    800061e0:	fcc2                	sd	a6,120(sp)
    800061e2:	e146                	sd	a7,128(sp)
    800061e4:	e54a                	sd	s2,136(sp)
    800061e6:	e94e                	sd	s3,144(sp)
    800061e8:	ed52                	sd	s4,152(sp)
    800061ea:	f156                	sd	s5,160(sp)
    800061ec:	f55a                	sd	s6,168(sp)
    800061ee:	f95e                	sd	s7,176(sp)
    800061f0:	fd62                	sd	s8,184(sp)
    800061f2:	e1e6                	sd	s9,192(sp)
    800061f4:	e5ea                	sd	s10,200(sp)
    800061f6:	e9ee                	sd	s11,208(sp)
    800061f8:	edf2                	sd	t3,216(sp)
    800061fa:	f1f6                	sd	t4,224(sp)
    800061fc:	f5fa                	sd	t5,232(sp)
    800061fe:	f9fe                	sd	t6,240(sp)
    80006200:	c4ffc0ef          	jal	ra,80002e4e <kerneltrap>
    80006204:	6082                	ld	ra,0(sp)
    80006206:	6122                	ld	sp,8(sp)
    80006208:	61c2                	ld	gp,16(sp)
    8000620a:	7282                	ld	t0,32(sp)
    8000620c:	7322                	ld	t1,40(sp)
    8000620e:	73c2                	ld	t2,48(sp)
    80006210:	7462                	ld	s0,56(sp)
    80006212:	6486                	ld	s1,64(sp)
    80006214:	6526                	ld	a0,72(sp)
    80006216:	65c6                	ld	a1,80(sp)
    80006218:	6666                	ld	a2,88(sp)
    8000621a:	7686                	ld	a3,96(sp)
    8000621c:	7726                	ld	a4,104(sp)
    8000621e:	77c6                	ld	a5,112(sp)
    80006220:	7866                	ld	a6,120(sp)
    80006222:	688a                	ld	a7,128(sp)
    80006224:	692a                	ld	s2,136(sp)
    80006226:	69ca                	ld	s3,144(sp)
    80006228:	6a6a                	ld	s4,152(sp)
    8000622a:	7a8a                	ld	s5,160(sp)
    8000622c:	7b2a                	ld	s6,168(sp)
    8000622e:	7bca                	ld	s7,176(sp)
    80006230:	7c6a                	ld	s8,184(sp)
    80006232:	6c8e                	ld	s9,192(sp)
    80006234:	6d2e                	ld	s10,200(sp)
    80006236:	6dce                	ld	s11,208(sp)
    80006238:	6e6e                	ld	t3,216(sp)
    8000623a:	7e8e                	ld	t4,224(sp)
    8000623c:	7f2e                	ld	t5,232(sp)
    8000623e:	7fce                	ld	t6,240(sp)
    80006240:	6111                	addi	sp,sp,256
    80006242:	10200073          	sret
    80006246:	00000013          	nop
    8000624a:	00000013          	nop
    8000624e:	0001                	nop

0000000080006250 <timervec>:
    80006250:	34051573          	csrrw	a0,mscratch,a0
    80006254:	e10c                	sd	a1,0(a0)
    80006256:	e510                	sd	a2,8(a0)
    80006258:	e914                	sd	a3,16(a0)
    8000625a:	6d0c                	ld	a1,24(a0)
    8000625c:	7110                	ld	a2,32(a0)
    8000625e:	6194                	ld	a3,0(a1)
    80006260:	96b2                	add	a3,a3,a2
    80006262:	e194                	sd	a3,0(a1)
    80006264:	4589                	li	a1,2
    80006266:	14459073          	csrw	sip,a1
    8000626a:	6914                	ld	a3,16(a0)
    8000626c:	6510                	ld	a2,8(a0)
    8000626e:	610c                	ld	a1,0(a0)
    80006270:	34051573          	csrrw	a0,mscratch,a0
    80006274:	30200073          	mret
	...

000000008000627a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000627a:	1141                	addi	sp,sp,-16
    8000627c:	e422                	sd	s0,8(sp)
    8000627e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006280:	0c0007b7          	lui	a5,0xc000
    80006284:	4705                	li	a4,1
    80006286:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006288:	c3d8                	sw	a4,4(a5)
}
    8000628a:	6422                	ld	s0,8(sp)
    8000628c:	0141                	addi	sp,sp,16
    8000628e:	8082                	ret

0000000080006290 <plicinithart>:

void
plicinithart(void)
{
    80006290:	1141                	addi	sp,sp,-16
    80006292:	e406                	sd	ra,8(sp)
    80006294:	e022                	sd	s0,0(sp)
    80006296:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006298:	ffffc097          	auipc	ra,0xffffc
    8000629c:	94e080e7          	jalr	-1714(ra) # 80001be6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062a0:	0085171b          	slliw	a4,a0,0x8
    800062a4:	0c0027b7          	lui	a5,0xc002
    800062a8:	97ba                	add	a5,a5,a4
    800062aa:	40200713          	li	a4,1026
    800062ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062b2:	00d5151b          	slliw	a0,a0,0xd
    800062b6:	0c2017b7          	lui	a5,0xc201
    800062ba:	97aa                	add	a5,a5,a0
    800062bc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800062c0:	60a2                	ld	ra,8(sp)
    800062c2:	6402                	ld	s0,0(sp)
    800062c4:	0141                	addi	sp,sp,16
    800062c6:	8082                	ret

00000000800062c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062c8:	1141                	addi	sp,sp,-16
    800062ca:	e406                	sd	ra,8(sp)
    800062cc:	e022                	sd	s0,0(sp)
    800062ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062d0:	ffffc097          	auipc	ra,0xffffc
    800062d4:	916080e7          	jalr	-1770(ra) # 80001be6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062d8:	00d5151b          	slliw	a0,a0,0xd
    800062dc:	0c2017b7          	lui	a5,0xc201
    800062e0:	97aa                	add	a5,a5,a0
  return irq;
}
    800062e2:	43c8                	lw	a0,4(a5)
    800062e4:	60a2                	ld	ra,8(sp)
    800062e6:	6402                	ld	s0,0(sp)
    800062e8:	0141                	addi	sp,sp,16
    800062ea:	8082                	ret

00000000800062ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062ec:	1101                	addi	sp,sp,-32
    800062ee:	ec06                	sd	ra,24(sp)
    800062f0:	e822                	sd	s0,16(sp)
    800062f2:	e426                	sd	s1,8(sp)
    800062f4:	1000                	addi	s0,sp,32
    800062f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062f8:	ffffc097          	auipc	ra,0xffffc
    800062fc:	8ee080e7          	jalr	-1810(ra) # 80001be6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006300:	00d5151b          	slliw	a0,a0,0xd
    80006304:	0c2017b7          	lui	a5,0xc201
    80006308:	97aa                	add	a5,a5,a0
    8000630a:	c3c4                	sw	s1,4(a5)
}
    8000630c:	60e2                	ld	ra,24(sp)
    8000630e:	6442                	ld	s0,16(sp)
    80006310:	64a2                	ld	s1,8(sp)
    80006312:	6105                	addi	sp,sp,32
    80006314:	8082                	ret

0000000080006316 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006316:	1141                	addi	sp,sp,-16
    80006318:	e406                	sd	ra,8(sp)
    8000631a:	e022                	sd	s0,0(sp)
    8000631c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000631e:	479d                	li	a5,7
    80006320:	04a7cc63          	blt	a5,a0,80006378 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006324:	0001c797          	auipc	a5,0x1c
    80006328:	aec78793          	addi	a5,a5,-1300 # 80021e10 <disk>
    8000632c:	97aa                	add	a5,a5,a0
    8000632e:	0187c783          	lbu	a5,24(a5)
    80006332:	ebb9                	bnez	a5,80006388 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006334:	00451693          	slli	a3,a0,0x4
    80006338:	0001c797          	auipc	a5,0x1c
    8000633c:	ad878793          	addi	a5,a5,-1320 # 80021e10 <disk>
    80006340:	6398                	ld	a4,0(a5)
    80006342:	9736                	add	a4,a4,a3
    80006344:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006348:	6398                	ld	a4,0(a5)
    8000634a:	9736                	add	a4,a4,a3
    8000634c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006350:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006354:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006358:	97aa                	add	a5,a5,a0
    8000635a:	4705                	li	a4,1
    8000635c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006360:	0001c517          	auipc	a0,0x1c
    80006364:	ac850513          	addi	a0,a0,-1336 # 80021e28 <disk+0x18>
    80006368:	ffffc097          	auipc	ra,0xffffc
    8000636c:	0bc080e7          	jalr	188(ra) # 80002424 <wakeup>
}
    80006370:	60a2                	ld	ra,8(sp)
    80006372:	6402                	ld	s0,0(sp)
    80006374:	0141                	addi	sp,sp,16
    80006376:	8082                	ret
    panic("free_desc 1");
    80006378:	00002517          	auipc	a0,0x2
    8000637c:	57050513          	addi	a0,a0,1392 # 800088e8 <syscalls+0x318>
    80006380:	ffffa097          	auipc	ra,0xffffa
    80006384:	1c0080e7          	jalr	448(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006388:	00002517          	auipc	a0,0x2
    8000638c:	57050513          	addi	a0,a0,1392 # 800088f8 <syscalls+0x328>
    80006390:	ffffa097          	auipc	ra,0xffffa
    80006394:	1b0080e7          	jalr	432(ra) # 80000540 <panic>

0000000080006398 <virtio_disk_init>:
{
    80006398:	1101                	addi	sp,sp,-32
    8000639a:	ec06                	sd	ra,24(sp)
    8000639c:	e822                	sd	s0,16(sp)
    8000639e:	e426                	sd	s1,8(sp)
    800063a0:	e04a                	sd	s2,0(sp)
    800063a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063a4:	00002597          	auipc	a1,0x2
    800063a8:	56458593          	addi	a1,a1,1380 # 80008908 <syscalls+0x338>
    800063ac:	0001c517          	auipc	a0,0x1c
    800063b0:	b8c50513          	addi	a0,a0,-1140 # 80021f38 <disk+0x128>
    800063b4:	ffffb097          	auipc	ra,0xffffb
    800063b8:	85a080e7          	jalr	-1958(ra) # 80000c0e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063bc:	100017b7          	lui	a5,0x10001
    800063c0:	4398                	lw	a4,0(a5)
    800063c2:	2701                	sext.w	a4,a4
    800063c4:	747277b7          	lui	a5,0x74727
    800063c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063cc:	14f71b63          	bne	a4,a5,80006522 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800063d0:	100017b7          	lui	a5,0x10001
    800063d4:	43dc                	lw	a5,4(a5)
    800063d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063d8:	4709                	li	a4,2
    800063da:	14e79463          	bne	a5,a4,80006522 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063de:	100017b7          	lui	a5,0x10001
    800063e2:	479c                	lw	a5,8(a5)
    800063e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800063e6:	12e79e63          	bne	a5,a4,80006522 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063ea:	100017b7          	lui	a5,0x10001
    800063ee:	47d8                	lw	a4,12(a5)
    800063f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063f2:	554d47b7          	lui	a5,0x554d4
    800063f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063fa:	12f71463          	bne	a4,a5,80006522 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063fe:	100017b7          	lui	a5,0x10001
    80006402:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006406:	4705                	li	a4,1
    80006408:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000640a:	470d                	li	a4,3
    8000640c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000640e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006410:	c7ffe6b7          	lui	a3,0xc7ffe
    80006414:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc80f>
    80006418:	8f75                	and	a4,a4,a3
    8000641a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000641c:	472d                	li	a4,11
    8000641e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006420:	5bbc                	lw	a5,112(a5)
    80006422:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006426:	8ba1                	andi	a5,a5,8
    80006428:	10078563          	beqz	a5,80006532 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000642c:	100017b7          	lui	a5,0x10001
    80006430:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006434:	43fc                	lw	a5,68(a5)
    80006436:	2781                	sext.w	a5,a5
    80006438:	10079563          	bnez	a5,80006542 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000643c:	100017b7          	lui	a5,0x10001
    80006440:	5bdc                	lw	a5,52(a5)
    80006442:	2781                	sext.w	a5,a5
  if(max == 0)
    80006444:	10078763          	beqz	a5,80006552 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006448:	471d                	li	a4,7
    8000644a:	10f77c63          	bgeu	a4,a5,80006562 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000644e:	ffffa097          	auipc	ra,0xffffa
    80006452:	714080e7          	jalr	1812(ra) # 80000b62 <kalloc>
    80006456:	0001c497          	auipc	s1,0x1c
    8000645a:	9ba48493          	addi	s1,s1,-1606 # 80021e10 <disk>
    8000645e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	702080e7          	jalr	1794(ra) # 80000b62 <kalloc>
    80006468:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	6f8080e7          	jalr	1784(ra) # 80000b62 <kalloc>
    80006472:	87aa                	mv	a5,a0
    80006474:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006476:	6088                	ld	a0,0(s1)
    80006478:	cd6d                	beqz	a0,80006572 <virtio_disk_init+0x1da>
    8000647a:	0001c717          	auipc	a4,0x1c
    8000647e:	99e73703          	ld	a4,-1634(a4) # 80021e18 <disk+0x8>
    80006482:	cb65                	beqz	a4,80006572 <virtio_disk_init+0x1da>
    80006484:	c7fd                	beqz	a5,80006572 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006486:	6605                	lui	a2,0x1
    80006488:	4581                	li	a1,0
    8000648a:	ffffb097          	auipc	ra,0xffffb
    8000648e:	910080e7          	jalr	-1776(ra) # 80000d9a <memset>
  memset(disk.avail, 0, PGSIZE);
    80006492:	0001c497          	auipc	s1,0x1c
    80006496:	97e48493          	addi	s1,s1,-1666 # 80021e10 <disk>
    8000649a:	6605                	lui	a2,0x1
    8000649c:	4581                	li	a1,0
    8000649e:	6488                	ld	a0,8(s1)
    800064a0:	ffffb097          	auipc	ra,0xffffb
    800064a4:	8fa080e7          	jalr	-1798(ra) # 80000d9a <memset>
  memset(disk.used, 0, PGSIZE);
    800064a8:	6605                	lui	a2,0x1
    800064aa:	4581                	li	a1,0
    800064ac:	6888                	ld	a0,16(s1)
    800064ae:	ffffb097          	auipc	ra,0xffffb
    800064b2:	8ec080e7          	jalr	-1812(ra) # 80000d9a <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800064b6:	100017b7          	lui	a5,0x10001
    800064ba:	4721                	li	a4,8
    800064bc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800064be:	4098                	lw	a4,0(s1)
    800064c0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800064c4:	40d8                	lw	a4,4(s1)
    800064c6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800064ca:	6498                	ld	a4,8(s1)
    800064cc:	0007069b          	sext.w	a3,a4
    800064d0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800064d4:	9701                	srai	a4,a4,0x20
    800064d6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800064da:	6898                	ld	a4,16(s1)
    800064dc:	0007069b          	sext.w	a3,a4
    800064e0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800064e4:	9701                	srai	a4,a4,0x20
    800064e6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800064ea:	4705                	li	a4,1
    800064ec:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800064ee:	00e48c23          	sb	a4,24(s1)
    800064f2:	00e48ca3          	sb	a4,25(s1)
    800064f6:	00e48d23          	sb	a4,26(s1)
    800064fa:	00e48da3          	sb	a4,27(s1)
    800064fe:	00e48e23          	sb	a4,28(s1)
    80006502:	00e48ea3          	sb	a4,29(s1)
    80006506:	00e48f23          	sb	a4,30(s1)
    8000650a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000650e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006512:	0727a823          	sw	s2,112(a5)
}
    80006516:	60e2                	ld	ra,24(sp)
    80006518:	6442                	ld	s0,16(sp)
    8000651a:	64a2                	ld	s1,8(sp)
    8000651c:	6902                	ld	s2,0(sp)
    8000651e:	6105                	addi	sp,sp,32
    80006520:	8082                	ret
    panic("could not find virtio disk");
    80006522:	00002517          	auipc	a0,0x2
    80006526:	3f650513          	addi	a0,a0,1014 # 80008918 <syscalls+0x348>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	016080e7          	jalr	22(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006532:	00002517          	auipc	a0,0x2
    80006536:	40650513          	addi	a0,a0,1030 # 80008938 <syscalls+0x368>
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	006080e7          	jalr	6(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006542:	00002517          	auipc	a0,0x2
    80006546:	41650513          	addi	a0,a0,1046 # 80008958 <syscalls+0x388>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	ff6080e7          	jalr	-10(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006552:	00002517          	auipc	a0,0x2
    80006556:	42650513          	addi	a0,a0,1062 # 80008978 <syscalls+0x3a8>
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	fe6080e7          	jalr	-26(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	43650513          	addi	a0,a0,1078 # 80008998 <syscalls+0x3c8>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd6080e7          	jalr	-42(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006572:	00002517          	auipc	a0,0x2
    80006576:	44650513          	addi	a0,a0,1094 # 800089b8 <syscalls+0x3e8>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>

0000000080006582 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006582:	7119                	addi	sp,sp,-128
    80006584:	fc86                	sd	ra,120(sp)
    80006586:	f8a2                	sd	s0,112(sp)
    80006588:	f4a6                	sd	s1,104(sp)
    8000658a:	f0ca                	sd	s2,96(sp)
    8000658c:	ecce                	sd	s3,88(sp)
    8000658e:	e8d2                	sd	s4,80(sp)
    80006590:	e4d6                	sd	s5,72(sp)
    80006592:	e0da                	sd	s6,64(sp)
    80006594:	fc5e                	sd	s7,56(sp)
    80006596:	f862                	sd	s8,48(sp)
    80006598:	f466                	sd	s9,40(sp)
    8000659a:	f06a                	sd	s10,32(sp)
    8000659c:	ec6e                	sd	s11,24(sp)
    8000659e:	0100                	addi	s0,sp,128
    800065a0:	8aaa                	mv	s5,a0
    800065a2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065a4:	00c52d03          	lw	s10,12(a0)
    800065a8:	001d1d1b          	slliw	s10,s10,0x1
    800065ac:	1d02                	slli	s10,s10,0x20
    800065ae:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800065b2:	0001c517          	auipc	a0,0x1c
    800065b6:	98650513          	addi	a0,a0,-1658 # 80021f38 <disk+0x128>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	6e4080e7          	jalr	1764(ra) # 80000c9e <acquire>
  for(int i = 0; i < 3; i++){
    800065c2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800065c4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800065c6:	0001cb97          	auipc	s7,0x1c
    800065ca:	84ab8b93          	addi	s7,s7,-1974 # 80021e10 <disk>
  for(int i = 0; i < 3; i++){
    800065ce:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065d0:	0001cc97          	auipc	s9,0x1c
    800065d4:	968c8c93          	addi	s9,s9,-1688 # 80021f38 <disk+0x128>
    800065d8:	a08d                	j	8000663a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800065da:	00fb8733          	add	a4,s7,a5
    800065de:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800065e2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800065e4:	0207c563          	bltz	a5,8000660e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800065e8:	2905                	addiw	s2,s2,1
    800065ea:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800065ec:	05690c63          	beq	s2,s6,80006644 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800065f0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800065f2:	0001c717          	auipc	a4,0x1c
    800065f6:	81e70713          	addi	a4,a4,-2018 # 80021e10 <disk>
    800065fa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800065fc:	01874683          	lbu	a3,24(a4)
    80006600:	fee9                	bnez	a3,800065da <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006602:	2785                	addiw	a5,a5,1
    80006604:	0705                	addi	a4,a4,1
    80006606:	fe979be3          	bne	a5,s1,800065fc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000660a:	57fd                	li	a5,-1
    8000660c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000660e:	01205d63          	blez	s2,80006628 <virtio_disk_rw+0xa6>
    80006612:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006614:	000a2503          	lw	a0,0(s4)
    80006618:	00000097          	auipc	ra,0x0
    8000661c:	cfe080e7          	jalr	-770(ra) # 80006316 <free_desc>
      for(int j = 0; j < i; j++)
    80006620:	2d85                	addiw	s11,s11,1
    80006622:	0a11                	addi	s4,s4,4
    80006624:	ff2d98e3          	bne	s11,s2,80006614 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006628:	85e6                	mv	a1,s9
    8000662a:	0001b517          	auipc	a0,0x1b
    8000662e:	7fe50513          	addi	a0,a0,2046 # 80021e28 <disk+0x18>
    80006632:	ffffc097          	auipc	ra,0xffffc
    80006636:	d8e080e7          	jalr	-626(ra) # 800023c0 <sleep>
  for(int i = 0; i < 3; i++){
    8000663a:	f8040a13          	addi	s4,s0,-128
{
    8000663e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006640:	894e                	mv	s2,s3
    80006642:	b77d                	j	800065f0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006644:	f8042503          	lw	a0,-128(s0)
    80006648:	00a50713          	addi	a4,a0,10
    8000664c:	0712                	slli	a4,a4,0x4

  if(write)
    8000664e:	0001b797          	auipc	a5,0x1b
    80006652:	7c278793          	addi	a5,a5,1986 # 80021e10 <disk>
    80006656:	00e786b3          	add	a3,a5,a4
    8000665a:	01803633          	snez	a2,s8
    8000665e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006660:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006664:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006668:	f6070613          	addi	a2,a4,-160
    8000666c:	6394                	ld	a3,0(a5)
    8000666e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006670:	00870593          	addi	a1,a4,8
    80006674:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006676:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006678:	0007b803          	ld	a6,0(a5)
    8000667c:	9642                	add	a2,a2,a6
    8000667e:	46c1                	li	a3,16
    80006680:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006682:	4585                	li	a1,1
    80006684:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006688:	f8442683          	lw	a3,-124(s0)
    8000668c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006690:	0692                	slli	a3,a3,0x4
    80006692:	9836                	add	a6,a6,a3
    80006694:	058a8613          	addi	a2,s5,88
    80006698:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000669c:	0007b803          	ld	a6,0(a5)
    800066a0:	96c2                	add	a3,a3,a6
    800066a2:	40000613          	li	a2,1024
    800066a6:	c690                	sw	a2,8(a3)
  if(write)
    800066a8:	001c3613          	seqz	a2,s8
    800066ac:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066b0:	00166613          	ori	a2,a2,1
    800066b4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066b8:	f8842603          	lw	a2,-120(s0)
    800066bc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066c0:	00250693          	addi	a3,a0,2
    800066c4:	0692                	slli	a3,a3,0x4
    800066c6:	96be                	add	a3,a3,a5
    800066c8:	58fd                	li	a7,-1
    800066ca:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066ce:	0612                	slli	a2,a2,0x4
    800066d0:	9832                	add	a6,a6,a2
    800066d2:	f9070713          	addi	a4,a4,-112
    800066d6:	973e                	add	a4,a4,a5
    800066d8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800066dc:	6398                	ld	a4,0(a5)
    800066de:	9732                	add	a4,a4,a2
    800066e0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066e2:	4609                	li	a2,2
    800066e4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800066e8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066ec:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800066f0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066f4:	6794                	ld	a3,8(a5)
    800066f6:	0026d703          	lhu	a4,2(a3)
    800066fa:	8b1d                	andi	a4,a4,7
    800066fc:	0706                	slli	a4,a4,0x1
    800066fe:	96ba                	add	a3,a3,a4
    80006700:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006704:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006708:	6798                	ld	a4,8(a5)
    8000670a:	00275783          	lhu	a5,2(a4)
    8000670e:	2785                	addiw	a5,a5,1
    80006710:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006714:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006718:	100017b7          	lui	a5,0x10001
    8000671c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006720:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006724:	0001c917          	auipc	s2,0x1c
    80006728:	81490913          	addi	s2,s2,-2028 # 80021f38 <disk+0x128>
  while(b->disk == 1) {
    8000672c:	4485                	li	s1,1
    8000672e:	00b79c63          	bne	a5,a1,80006746 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006732:	85ca                	mv	a1,s2
    80006734:	8556                	mv	a0,s5
    80006736:	ffffc097          	auipc	ra,0xffffc
    8000673a:	c8a080e7          	jalr	-886(ra) # 800023c0 <sleep>
  while(b->disk == 1) {
    8000673e:	004aa783          	lw	a5,4(s5)
    80006742:	fe9788e3          	beq	a5,s1,80006732 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006746:	f8042903          	lw	s2,-128(s0)
    8000674a:	00290713          	addi	a4,s2,2
    8000674e:	0712                	slli	a4,a4,0x4
    80006750:	0001b797          	auipc	a5,0x1b
    80006754:	6c078793          	addi	a5,a5,1728 # 80021e10 <disk>
    80006758:	97ba                	add	a5,a5,a4
    8000675a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000675e:	0001b997          	auipc	s3,0x1b
    80006762:	6b298993          	addi	s3,s3,1714 # 80021e10 <disk>
    80006766:	00491713          	slli	a4,s2,0x4
    8000676a:	0009b783          	ld	a5,0(s3)
    8000676e:	97ba                	add	a5,a5,a4
    80006770:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006774:	854a                	mv	a0,s2
    80006776:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000677a:	00000097          	auipc	ra,0x0
    8000677e:	b9c080e7          	jalr	-1124(ra) # 80006316 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006782:	8885                	andi	s1,s1,1
    80006784:	f0ed                	bnez	s1,80006766 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006786:	0001b517          	auipc	a0,0x1b
    8000678a:	7b250513          	addi	a0,a0,1970 # 80021f38 <disk+0x128>
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	5c4080e7          	jalr	1476(ra) # 80000d52 <release>
}
    80006796:	70e6                	ld	ra,120(sp)
    80006798:	7446                	ld	s0,112(sp)
    8000679a:	74a6                	ld	s1,104(sp)
    8000679c:	7906                	ld	s2,96(sp)
    8000679e:	69e6                	ld	s3,88(sp)
    800067a0:	6a46                	ld	s4,80(sp)
    800067a2:	6aa6                	ld	s5,72(sp)
    800067a4:	6b06                	ld	s6,64(sp)
    800067a6:	7be2                	ld	s7,56(sp)
    800067a8:	7c42                	ld	s8,48(sp)
    800067aa:	7ca2                	ld	s9,40(sp)
    800067ac:	7d02                	ld	s10,32(sp)
    800067ae:	6de2                	ld	s11,24(sp)
    800067b0:	6109                	addi	sp,sp,128
    800067b2:	8082                	ret

00000000800067b4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067b4:	1101                	addi	sp,sp,-32
    800067b6:	ec06                	sd	ra,24(sp)
    800067b8:	e822                	sd	s0,16(sp)
    800067ba:	e426                	sd	s1,8(sp)
    800067bc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067be:	0001b497          	auipc	s1,0x1b
    800067c2:	65248493          	addi	s1,s1,1618 # 80021e10 <disk>
    800067c6:	0001b517          	auipc	a0,0x1b
    800067ca:	77250513          	addi	a0,a0,1906 # 80021f38 <disk+0x128>
    800067ce:	ffffa097          	auipc	ra,0xffffa
    800067d2:	4d0080e7          	jalr	1232(ra) # 80000c9e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067d6:	10001737          	lui	a4,0x10001
    800067da:	533c                	lw	a5,96(a4)
    800067dc:	8b8d                	andi	a5,a5,3
    800067de:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067e0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067e4:	689c                	ld	a5,16(s1)
    800067e6:	0204d703          	lhu	a4,32(s1)
    800067ea:	0027d783          	lhu	a5,2(a5)
    800067ee:	04f70863          	beq	a4,a5,8000683e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800067f2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067f6:	6898                	ld	a4,16(s1)
    800067f8:	0204d783          	lhu	a5,32(s1)
    800067fc:	8b9d                	andi	a5,a5,7
    800067fe:	078e                	slli	a5,a5,0x3
    80006800:	97ba                	add	a5,a5,a4
    80006802:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006804:	00278713          	addi	a4,a5,2
    80006808:	0712                	slli	a4,a4,0x4
    8000680a:	9726                	add	a4,a4,s1
    8000680c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006810:	e721                	bnez	a4,80006858 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006812:	0789                	addi	a5,a5,2
    80006814:	0792                	slli	a5,a5,0x4
    80006816:	97a6                	add	a5,a5,s1
    80006818:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000681a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000681e:	ffffc097          	auipc	ra,0xffffc
    80006822:	c06080e7          	jalr	-1018(ra) # 80002424 <wakeup>

    disk.used_idx += 1;
    80006826:	0204d783          	lhu	a5,32(s1)
    8000682a:	2785                	addiw	a5,a5,1
    8000682c:	17c2                	slli	a5,a5,0x30
    8000682e:	93c1                	srli	a5,a5,0x30
    80006830:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006834:	6898                	ld	a4,16(s1)
    80006836:	00275703          	lhu	a4,2(a4)
    8000683a:	faf71ce3          	bne	a4,a5,800067f2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000683e:	0001b517          	auipc	a0,0x1b
    80006842:	6fa50513          	addi	a0,a0,1786 # 80021f38 <disk+0x128>
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	50c080e7          	jalr	1292(ra) # 80000d52 <release>
}
    8000684e:	60e2                	ld	ra,24(sp)
    80006850:	6442                	ld	s0,16(sp)
    80006852:	64a2                	ld	s1,8(sp)
    80006854:	6105                	addi	sp,sp,32
    80006856:	8082                	ret
      panic("virtio_disk_intr status");
    80006858:	00002517          	auipc	a0,0x2
    8000685c:	17850513          	addi	a0,a0,376 # 800089d0 <syscalls+0x400>
    80006860:	ffffa097          	auipc	ra,0xffffa
    80006864:	ce0080e7          	jalr	-800(ra) # 80000540 <panic>
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
