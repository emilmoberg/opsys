
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9d013103          	ld	sp,-1584(sp) # 800089d0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	9e070713          	addi	a4,a4,-1568 # 80008a30 <timer_scratch>
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
    80000066:	05e78793          	addi	a5,a5,94 # 800060c0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc75f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
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
    8000012e:	6aa080e7          	jalr	1706(ra) # 800027d4 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
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
    8000018e:	9e650513          	addi	a0,a0,-1562 # 80010b70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	9d648493          	addi	s1,s1,-1578 # 80010b70 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a6690913          	addi	s2,s2,-1434 # 80010c08 <cons+0x98>
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
    800001c4:	9f6080e7          	jalr	-1546(ra) # 80001bb6 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	456080e7          	jalr	1110(ra) # 8000261e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1a0080e7          	jalr	416(ra) # 80002376 <sleep>
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
    80000216:	56c080e7          	jalr	1388(ra) # 8000277e <either_copyout>
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
    8000022a:	94a50513          	addi	a0,a0,-1718 # 80010b70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	93450513          	addi	a0,a0,-1740 # 80010b70 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
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
    80000276:	98f72b23          	sw	a5,-1642(a4) # 80010c08 <cons+0x98>
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
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
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
    800002d0:	8a450513          	addi	a0,a0,-1884 # 80010b70 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

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
    800002f6:	538080e7          	jalr	1336(ra) # 8000282a <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	87650513          	addi	a0,a0,-1930 # 80010b70 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
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
    80000322:	85270713          	addi	a4,a4,-1966 # 80010b70 <cons>
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
    8000034c:	82878793          	addi	a5,a5,-2008 # 80010b70 <cons>
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
    8000037a:	8927a783          	lw	a5,-1902(a5) # 80010c08 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	7e670713          	addi	a4,a4,2022 # 80010b70 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	7d648493          	addi	s1,s1,2006 # 80010b70 <cons>
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
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	79a70713          	addi	a4,a4,1946 # 80010b70 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	82f72223          	sw	a5,-2012(a4) # 80010c10 <cons+0xa0>
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
    80000416:	75e78793          	addi	a5,a5,1886 # 80010b70 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	7cc7ab23          	sw	a2,2006(a5) # 80010c0c <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7ca50513          	addi	a0,a0,1994 # 80010c08 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f94080e7          	jalr	-108(ra) # 800023da <wakeup>
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
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	71050513          	addi	a0,a0,1808 # 80010b70 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	a9078793          	addi	a5,a5,-1392 # 80020f08 <devsw>
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

  if(sign && (sign = xx < 0))
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
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
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
  while(--i >= 0)
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
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6e07a223          	sw	zero,1764(a5) # 80010c30 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	46f72823          	sw	a5,1136(a4) # 800089f0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	674dad83          	lw	s11,1652(s11) # 80010c30 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	61e50513          	addi	a0,a0,1566 # 80010c18 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	4c050513          	addi	a0,a0,1216 # 80010c18 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	4a448493          	addi	s1,s1,1188 # 80010c18 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	46450513          	addi	a0,a0,1124 # 80010c38 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1f07a783          	lw	a5,496(a5) # 800089f0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1c07b783          	ld	a5,448(a5) # 800089f8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	1c073703          	ld	a4,448(a4) # 80008a00 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	3d6a0a13          	addi	s4,s4,982 # 80010c38 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	18e48493          	addi	s1,s1,398 # 800089f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	18e98993          	addi	s3,s3,398 # 80008a00 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b46080e7          	jalr	-1210(ra) # 800023da <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	36850513          	addi	a0,a0,872 # 80010c38 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	1107a783          	lw	a5,272(a5) # 800089f0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	11673703          	ld	a4,278(a4) # 80008a00 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1067b783          	ld	a5,262(a5) # 800089f8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	33a98993          	addi	s3,s3,826 # 80010c38 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	0f248493          	addi	s1,s1,242 # 800089f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	0f290913          	addi	s2,s2,242 # 80008a00 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a58080e7          	jalr	-1448(ra) # 80002376 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	30448493          	addi	s1,s1,772 # 80010c38 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	0ae7bc23          	sd	a4,184(a5) # 80008a00 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	27e48493          	addi	s1,s1,638 # 80010c38 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	6a478793          	addi	a5,a5,1700 # 800220a0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	25490913          	addi	s2,s2,596 # 80010c70 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	1b650513          	addi	a0,a0,438 # 80010c70 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	5d250513          	addi	a0,a0,1490 # 800220a0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	18048493          	addi	s1,s1,384 # 80010c70 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	16850513          	addi	a0,a0,360 # 80010c70 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	13c50513          	addi	a0,a0,316 # 80010c70 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	02a080e7          	jalr	42(ra) # 80001b9a <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	ff8080e7          	jalr	-8(ra) # 80001b9a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	fec080e7          	jalr	-20(ra) # 80001b9a <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	fd4080e7          	jalr	-44(ra) # 80001b9a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	f94080e7          	jalr	-108(ra) # 80001b9a <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	f68080e7          	jalr	-152(ra) # 80001b9a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcf61>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	d0a080e7          	jalr	-758(ra) # 80001b8a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	b8070713          	addi	a4,a4,-1152 # 80008a08 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	cee080e7          	jalr	-786(ra) # 80001b8a <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	bf4080e7          	jalr	-1036(ra) # 80002ab2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	23a080e7          	jalr	570(ra) # 80006100 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	37c080e7          	jalr	892(ra) # 8000224a <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	b7a080e7          	jalr	-1158(ra) # 80001aa8 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	b54080e7          	jalr	-1196(ra) # 80002a8a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	b74080e7          	jalr	-1164(ra) # 80002ab2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	1a4080e7          	jalr	420(ra) # 800060ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	1b2080e7          	jalr	434(ra) # 80006100 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	348080e7          	jalr	840(ra) # 8000329e <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	9e8080e7          	jalr	-1560(ra) # 80003946 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	98e080e7          	jalr	-1650(ra) # 800048f4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	29a080e7          	jalr	666(ra) # 80006208 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	f20080e7          	jalr	-224(ra) # 80001e96 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	a8f72223          	sw	a5,-1404(a4) # 80008a08 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	a787b783          	ld	a5,-1416(a5) # 80008a10 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcf57>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	7e4080e7          	jalr	2020(ra) # 80001a12 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	7aa7be23          	sd	a0,1980(a5) # 80008a10 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcf60>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    8000184a:	8792                	mv	a5,tp
    int id = r_tp();
    8000184c:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    8000184e:	0000fa97          	auipc	s5,0xf
    80001852:	442a8a93          	addi	s5,s5,1090 # 80010c90 <cpus>
    80001856:	00779713          	slli	a4,a5,0x7
    8000185a:	00ea86b3          	add	a3,s5,a4
    8000185e:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdcf60>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001862:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001866:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000186a:	10069073          	csrw	sstatus,a3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    8000186e:	0721                	addi	a4,a4,8
    80001870:	9aba                	add	s5,s5,a4
    for (p = proc; p < &proc[NPROC]; p++)
    80001872:	00010497          	auipc	s1,0x10
    80001876:	84e48493          	addi	s1,s1,-1970 # 800110c0 <proc>
        if (p->state == RUNNABLE)
    8000187a:	498d                	li	s3,3
            p->state = RUNNING;
    8000187c:	4b11                	li	s6,4
            c->proc = p;
    8000187e:	079e                	slli	a5,a5,0x7
    80001880:	0000fa17          	auipc	s4,0xf
    80001884:	410a0a13          	addi	s4,s4,1040 # 80010c90 <cpus>
    80001888:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000188a:	00015917          	auipc	s2,0x15
    8000188e:	43690913          	addi	s2,s2,1078 # 80016cc0 <tickslock>
    80001892:	a811                	j	800018a6 <rr_scheduler+0x70>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
        }
        release(&p->lock);
    80001894:	8526                	mv	a0,s1
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	3f4080e7          	jalr	1012(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000189e:	17048493          	addi	s1,s1,368
    800018a2:	03248863          	beq	s1,s2,800018d2 <rr_scheduler+0x9c>
        acquire(&p->lock);
    800018a6:	8526                	mv	a0,s1
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	32e080e7          	jalr	814(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE)
    800018b0:	4c9c                	lw	a5,24(s1)
    800018b2:	ff3791e3          	bne	a5,s3,80001894 <rr_scheduler+0x5e>
            p->state = RUNNING;
    800018b6:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    800018ba:	009a3023          	sd	s1,0(s4)
            swtch(&c->context, &p->context);
    800018be:	06848593          	addi	a1,s1,104
    800018c2:	8556                	mv	a0,s5
    800018c4:	00001097          	auipc	ra,0x1
    800018c8:	15c080e7          	jalr	348(ra) # 80002a20 <swtch>
            c->proc = 0;
    800018cc:	000a3023          	sd	zero,0(s4)
    800018d0:	b7d1                	j	80001894 <rr_scheduler+0x5e>
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800018d2:	70e2                	ld	ra,56(sp)
    800018d4:	7442                	ld	s0,48(sp)
    800018d6:	74a2                	ld	s1,40(sp)
    800018d8:	7902                	ld	s2,32(sp)
    800018da:	69e2                	ld	s3,24(sp)
    800018dc:	6a42                	ld	s4,16(sp)
    800018de:	6aa2                	ld	s5,8(sp)
    800018e0:	6b02                	ld	s6,0(sp)
    800018e2:	6121                	addi	sp,sp,64
    800018e4:	8082                	ret

00000000800018e6 <mlfq_scheduler>:



void mlfq_scheduler(void)
{
    800018e6:	711d                	addi	sp,sp,-96
    800018e8:	ec86                	sd	ra,88(sp)
    800018ea:	e8a2                	sd	s0,80(sp)
    800018ec:	e4a6                	sd	s1,72(sp)
    800018ee:	e0ca                	sd	s2,64(sp)
    800018f0:	fc4e                	sd	s3,56(sp)
    800018f2:	f852                	sd	s4,48(sp)
    800018f4:	f456                	sd	s5,40(sp)
    800018f6:	f05a                	sd	s6,32(sp)
    800018f8:	ec5e                	sd	s7,24(sp)
    800018fa:	e862                	sd	s8,16(sp)
    800018fc:	e466                	sd	s9,8(sp)
    800018fe:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80001900:	8712                	mv	a4,tp
    int id = r_tp();
    80001902:	2701                	sext.w	a4,a4
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001904:	0000fb17          	auipc	s6,0xf
    80001908:	38cb0b13          	addi	s6,s6,908 # 80010c90 <cpus>
    8000190c:	00771793          	slli	a5,a4,0x7
    80001910:	00fb06b3          	add	a3,s6,a5
    80001914:	0006b023          	sd	zero,0(a3)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001918:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000191c:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001920:	10069073          	csrw	sstatus,a3
            // to release its lock and then reacquire it
            // before jumping back to us.

            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    80001924:	07a1                	addi	a5,a5,8
    80001926:	9b3e                	add	s6,s6,a5
    int hasHighPri = 1;
    80001928:	4785                	li	a5,1
        if (p->state == RUNNABLE)
    8000192a:	498d                	li	s3,3
            c->proc = p;
    8000192c:	071e                	slli	a4,a4,0x7
    8000192e:	0000fa97          	auipc	s5,0xf
    80001932:	362a8a93          	addi	s5,s5,866 # 80010c90 <cpus>
    80001936:	9aba                	add	s5,s5,a4
    for (p = proc; p < &proc[NPROC]; p++)
    80001938:	00015917          	auipc	s2,0x15
    8000193c:	38890913          	addi	s2,s2,904 # 80016cc0 <tickslock>
    80001940:	a8a1                	j	80001998 <mlfq_scheduler+0xb2>
        hasHighPri = 0;
    80001942:	4c01                	li	s8,0
        for (p = proc; p < &proc[NPROC]; p++)
    80001944:	0000f497          	auipc	s1,0xf
    80001948:	77c48493          	addi	s1,s1,1916 # 800110c0 <proc>
                p->state = RUNNING;
    8000194c:	4c91                	li	s9,4
                hasHighPri = 1;
    8000194e:	8a3e                	mv	s4,a5
    80001950:	a811                	j	80001964 <mlfq_scheduler+0x7e>
            release(&p->lock);
    80001952:	8526                	mv	a0,s1
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	336080e7          	jalr	822(ra) # 80000c8a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    8000195c:	17048493          	addi	s1,s1,368
    80001960:	03248b63          	beq	s1,s2,80001996 <mlfq_scheduler+0xb0>
            acquire(&p->lock);
    80001964:	8526                	mv	a0,s1
    80001966:	fffff097          	auipc	ra,0xfffff
    8000196a:	270080e7          	jalr	624(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE && p->priority == 0)
    8000196e:	4c9c                	lw	a5,24(s1)
    80001970:	ff3791e3          	bne	a5,s3,80001952 <mlfq_scheduler+0x6c>
    80001974:	58dc                	lw	a5,52(s1)
    80001976:	fff1                	bnez	a5,80001952 <mlfq_scheduler+0x6c>
                p->state = RUNNING;
    80001978:	0194ac23          	sw	s9,24(s1)
                c->proc = p;
    8000197c:	009ab023          	sd	s1,0(s5)
                swtch(&c->context, &p->context);
    80001980:	06848593          	addi	a1,s1,104
    80001984:	855a                	mv	a0,s6
    80001986:	00001097          	auipc	ra,0x1
    8000198a:	09a080e7          	jalr	154(ra) # 80002a20 <swtch>
                c->proc = 0;
    8000198e:	000ab023          	sd	zero,0(s5)
                hasHighPri = 1;
    80001992:	8c52                	mv	s8,s4
    80001994:	bf7d                	j	80001952 <mlfq_scheduler+0x6c>
    80001996:	87e2                	mv	a5,s8
    while (hasHighPri) {
    80001998:	f7cd                	bnez	a5,80001942 <mlfq_scheduler+0x5c>
    for (p = proc; p < &proc[NPROC]; p++)
    8000199a:	0000f497          	auipc	s1,0xf
    8000199e:	72648493          	addi	s1,s1,1830 # 800110c0 <proc>
            p->state = RUNNING;
    800019a2:	4a11                	li	s4,4
    800019a4:	a01d                	j	800019ca <mlfq_scheduler+0xe4>
    800019a6:	0144ac23          	sw	s4,24(s1)
            c->proc = p;
    800019aa:	009ab023          	sd	s1,0(s5)
            swtch(&c->context, &p->context);
    800019ae:	06848593          	addi	a1,s1,104
    800019b2:	855a                	mv	a0,s6
    800019b4:	00001097          	auipc	ra,0x1
    800019b8:	06c080e7          	jalr	108(ra) # 80002a20 <swtch>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
    800019bc:	000ab023          	sd	zero,0(s5)
    800019c0:	a839                	j	800019de <mlfq_scheduler+0xf8>
    for (p = proc; p < &proc[NPROC]; p++)
    800019c2:	17048493          	addi	s1,s1,368
    800019c6:	03248963          	beq	s1,s2,800019f8 <mlfq_scheduler+0x112>
        if (p->priority == 0) {
    800019ca:	58dc                	lw	a5,52(s1)
    800019cc:	d7f1                	beqz	a5,80001998 <mlfq_scheduler+0xb2>
        acquire(&p->lock);
    800019ce:	8526                	mv	a0,s1
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	206080e7          	jalr	518(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE)
    800019d8:	4c9c                	lw	a5,24(s1)
    800019da:	fd3786e3          	beq	a5,s3,800019a6 <mlfq_scheduler+0xc0>
        }
        release(&p->lock);
    800019de:	8526                	mv	a0,s1
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	2aa080e7          	jalr	682(ra) # 80000c8a <release>

        if (p->timesScheduled >= 5) {
    800019e8:	5c9c                	lw	a5,56(s1)
    800019ea:	fcfa5ce3          	bge	s4,a5,800019c2 <mlfq_scheduler+0xdc>
            p->timesScheduled = 0;
    800019ee:	0204ac23          	sw	zero,56(s1)
            p->priority = 0;
    800019f2:	0204aa23          	sw	zero,52(s1)
    800019f6:	b7f1                	j	800019c2 <mlfq_scheduler+0xdc>
        }
    }

    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800019f8:	60e6                	ld	ra,88(sp)
    800019fa:	6446                	ld	s0,80(sp)
    800019fc:	64a6                	ld	s1,72(sp)
    800019fe:	6906                	ld	s2,64(sp)
    80001a00:	79e2                	ld	s3,56(sp)
    80001a02:	7a42                	ld	s4,48(sp)
    80001a04:	7aa2                	ld	s5,40(sp)
    80001a06:	7b02                	ld	s6,32(sp)
    80001a08:	6be2                	ld	s7,24(sp)
    80001a0a:	6c42                	ld	s8,16(sp)
    80001a0c:	6ca2                	ld	s9,8(sp)
    80001a0e:	6125                	addi	sp,sp,96
    80001a10:	8082                	ret

0000000080001a12 <proc_mapstacks>:
{
    80001a12:	7139                	addi	sp,sp,-64
    80001a14:	fc06                	sd	ra,56(sp)
    80001a16:	f822                	sd	s0,48(sp)
    80001a18:	f426                	sd	s1,40(sp)
    80001a1a:	f04a                	sd	s2,32(sp)
    80001a1c:	ec4e                	sd	s3,24(sp)
    80001a1e:	e852                	sd	s4,16(sp)
    80001a20:	e456                	sd	s5,8(sp)
    80001a22:	e05a                	sd	s6,0(sp)
    80001a24:	0080                	addi	s0,sp,64
    80001a26:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001a28:	0000f497          	auipc	s1,0xf
    80001a2c:	69848493          	addi	s1,s1,1688 # 800110c0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001a30:	8b26                	mv	s6,s1
    80001a32:	00006a97          	auipc	s5,0x6
    80001a36:	5cea8a93          	addi	s5,s5,1486 # 80008000 <etext>
    80001a3a:	04000937          	lui	s2,0x4000
    80001a3e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a40:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a42:	00015a17          	auipc	s4,0x15
    80001a46:	27ea0a13          	addi	s4,s4,638 # 80016cc0 <tickslock>
        char *pa = kalloc();
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	09c080e7          	jalr	156(ra) # 80000ae6 <kalloc>
    80001a52:	862a                	mv	a2,a0
        if (pa == 0)
    80001a54:	c131                	beqz	a0,80001a98 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a56:	416485b3          	sub	a1,s1,s6
    80001a5a:	8591                	srai	a1,a1,0x4
    80001a5c:	000ab783          	ld	a5,0(s5)
    80001a60:	02f585b3          	mul	a1,a1,a5
    80001a64:	2585                	addiw	a1,a1,1
    80001a66:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a6a:	4719                	li	a4,6
    80001a6c:	6685                	lui	a3,0x1
    80001a6e:	40b905b3          	sub	a1,s2,a1
    80001a72:	854e                	mv	a0,s3
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	6ca080e7          	jalr	1738(ra) # 8000113e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a7c:	17048493          	addi	s1,s1,368
    80001a80:	fd4495e3          	bne	s1,s4,80001a4a <proc_mapstacks+0x38>
}
    80001a84:	70e2                	ld	ra,56(sp)
    80001a86:	7442                	ld	s0,48(sp)
    80001a88:	74a2                	ld	s1,40(sp)
    80001a8a:	7902                	ld	s2,32(sp)
    80001a8c:	69e2                	ld	s3,24(sp)
    80001a8e:	6a42                	ld	s4,16(sp)
    80001a90:	6aa2                	ld	s5,8(sp)
    80001a92:	6b02                	ld	s6,0(sp)
    80001a94:	6121                	addi	sp,sp,64
    80001a96:	8082                	ret
            panic("kalloc");
    80001a98:	00006517          	auipc	a0,0x6
    80001a9c:	74050513          	addi	a0,a0,1856 # 800081d8 <digits+0x198>
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	aa0080e7          	jalr	-1376(ra) # 80000540 <panic>

0000000080001aa8 <procinit>:
{
    80001aa8:	7139                	addi	sp,sp,-64
    80001aaa:	fc06                	sd	ra,56(sp)
    80001aac:	f822                	sd	s0,48(sp)
    80001aae:	f426                	sd	s1,40(sp)
    80001ab0:	f04a                	sd	s2,32(sp)
    80001ab2:	ec4e                	sd	s3,24(sp)
    80001ab4:	e852                	sd	s4,16(sp)
    80001ab6:	e456                	sd	s5,8(sp)
    80001ab8:	e05a                	sd	s6,0(sp)
    80001aba:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001abc:	00006597          	auipc	a1,0x6
    80001ac0:	72458593          	addi	a1,a1,1828 # 800081e0 <digits+0x1a0>
    80001ac4:	0000f517          	auipc	a0,0xf
    80001ac8:	5cc50513          	addi	a0,a0,1484 # 80011090 <pid_lock>
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	07a080e7          	jalr	122(ra) # 80000b46 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001ad4:	00006597          	auipc	a1,0x6
    80001ad8:	71458593          	addi	a1,a1,1812 # 800081e8 <digits+0x1a8>
    80001adc:	0000f517          	auipc	a0,0xf
    80001ae0:	5cc50513          	addi	a0,a0,1484 # 800110a8 <wait_lock>
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	062080e7          	jalr	98(ra) # 80000b46 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001aec:	0000f497          	auipc	s1,0xf
    80001af0:	5d448493          	addi	s1,s1,1492 # 800110c0 <proc>
        initlock(&p->lock, "proc");
    80001af4:	00006b17          	auipc	s6,0x6
    80001af8:	704b0b13          	addi	s6,s6,1796 # 800081f8 <digits+0x1b8>
        p->kstack = KSTACK((int)(p - proc));
    80001afc:	8aa6                	mv	s5,s1
    80001afe:	00006a17          	auipc	s4,0x6
    80001b02:	502a0a13          	addi	s4,s4,1282 # 80008000 <etext>
    80001b06:	04000937          	lui	s2,0x4000
    80001b0a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b0c:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b0e:	00015997          	auipc	s3,0x15
    80001b12:	1b298993          	addi	s3,s3,434 # 80016cc0 <tickslock>
        initlock(&p->lock, "proc");
    80001b16:	85da                	mv	a1,s6
    80001b18:	8526                	mv	a0,s1
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	02c080e7          	jalr	44(ra) # 80000b46 <initlock>
        p->state = UNUSED;
    80001b22:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001b26:	415487b3          	sub	a5,s1,s5
    80001b2a:	8791                	srai	a5,a5,0x4
    80001b2c:	000a3703          	ld	a4,0(s4)
    80001b30:	02e787b3          	mul	a5,a5,a4
    80001b34:	2785                	addiw	a5,a5,1
    80001b36:	00d7979b          	slliw	a5,a5,0xd
    80001b3a:	40f907b3          	sub	a5,s2,a5
    80001b3e:	e4bc                	sd	a5,72(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b40:	17048493          	addi	s1,s1,368
    80001b44:	fd3499e3          	bne	s1,s3,80001b16 <procinit+0x6e>
}
    80001b48:	70e2                	ld	ra,56(sp)
    80001b4a:	7442                	ld	s0,48(sp)
    80001b4c:	74a2                	ld	s1,40(sp)
    80001b4e:	7902                	ld	s2,32(sp)
    80001b50:	69e2                	ld	s3,24(sp)
    80001b52:	6a42                	ld	s4,16(sp)
    80001b54:	6aa2                	ld	s5,8(sp)
    80001b56:	6b02                	ld	s6,0(sp)
    80001b58:	6121                	addi	sp,sp,64
    80001b5a:	8082                	ret

0000000080001b5c <copy_array>:
{
    80001b5c:	1141                	addi	sp,sp,-16
    80001b5e:	e422                	sd	s0,8(sp)
    80001b60:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001b62:	02c05163          	blez	a2,80001b84 <copy_array+0x28>
    80001b66:	87aa                	mv	a5,a0
    80001b68:	0505                	addi	a0,a0,1
    80001b6a:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001b6c:	1602                	slli	a2,a2,0x20
    80001b6e:	9201                	srli	a2,a2,0x20
    80001b70:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001b74:	0007c703          	lbu	a4,0(a5)
    80001b78:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001b7c:	0785                	addi	a5,a5,1
    80001b7e:	0585                	addi	a1,a1,1
    80001b80:	fed79ae3          	bne	a5,a3,80001b74 <copy_array+0x18>
}
    80001b84:	6422                	ld	s0,8(sp)
    80001b86:	0141                	addi	sp,sp,16
    80001b88:	8082                	ret

0000000080001b8a <cpuid>:
{
    80001b8a:	1141                	addi	sp,sp,-16
    80001b8c:	e422                	sd	s0,8(sp)
    80001b8e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b90:	8512                	mv	a0,tp
}
    80001b92:	2501                	sext.w	a0,a0
    80001b94:	6422                	ld	s0,8(sp)
    80001b96:	0141                	addi	sp,sp,16
    80001b98:	8082                	ret

0000000080001b9a <mycpu>:
{
    80001b9a:	1141                	addi	sp,sp,-16
    80001b9c:	e422                	sd	s0,8(sp)
    80001b9e:	0800                	addi	s0,sp,16
    80001ba0:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001ba2:	2781                	sext.w	a5,a5
    80001ba4:	079e                	slli	a5,a5,0x7
}
    80001ba6:	0000f517          	auipc	a0,0xf
    80001baa:	0ea50513          	addi	a0,a0,234 # 80010c90 <cpus>
    80001bae:	953e                	add	a0,a0,a5
    80001bb0:	6422                	ld	s0,8(sp)
    80001bb2:	0141                	addi	sp,sp,16
    80001bb4:	8082                	ret

0000000080001bb6 <myproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	1000                	addi	s0,sp,32
    push_off();
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	fca080e7          	jalr	-54(ra) # 80000b8a <push_off>
    80001bc8:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001bca:	2781                	sext.w	a5,a5
    80001bcc:	079e                	slli	a5,a5,0x7
    80001bce:	0000f717          	auipc	a4,0xf
    80001bd2:	0c270713          	addi	a4,a4,194 # 80010c90 <cpus>
    80001bd6:	97ba                	add	a5,a5,a4
    80001bd8:	6384                	ld	s1,0(a5)
    pop_off();
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	050080e7          	jalr	80(ra) # 80000c2a <pop_off>
}
    80001be2:	8526                	mv	a0,s1
    80001be4:	60e2                	ld	ra,24(sp)
    80001be6:	6442                	ld	s0,16(sp)
    80001be8:	64a2                	ld	s1,8(sp)
    80001bea:	6105                	addi	sp,sp,32
    80001bec:	8082                	ret

0000000080001bee <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bee:	1141                	addi	sp,sp,-16
    80001bf0:	e406                	sd	ra,8(sp)
    80001bf2:	e022                	sd	s0,0(sp)
    80001bf4:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	fc0080e7          	jalr	-64(ra) # 80001bb6 <myproc>
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	08c080e7          	jalr	140(ra) # 80000c8a <release>

    if (first)
    80001c06:	00007797          	auipc	a5,0x7
    80001c0a:	d2a7a783          	lw	a5,-726(a5) # 80008930 <first.1>
    80001c0e:	eb89                	bnez	a5,80001c20 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001c10:	00001097          	auipc	ra,0x1
    80001c14:	eba080e7          	jalr	-326(ra) # 80002aca <usertrapret>
}
    80001c18:	60a2                	ld	ra,8(sp)
    80001c1a:	6402                	ld	s0,0(sp)
    80001c1c:	0141                	addi	sp,sp,16
    80001c1e:	8082                	ret
        first = 0;
    80001c20:	00007797          	auipc	a5,0x7
    80001c24:	d007a823          	sw	zero,-752(a5) # 80008930 <first.1>
        fsinit(ROOTDEV);
    80001c28:	4505                	li	a0,1
    80001c2a:	00002097          	auipc	ra,0x2
    80001c2e:	c9c080e7          	jalr	-868(ra) # 800038c6 <fsinit>
    80001c32:	bff9                	j	80001c10 <forkret+0x22>

0000000080001c34 <allocpid>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c40:	0000f917          	auipc	s2,0xf
    80001c44:	45090913          	addi	s2,s2,1104 # 80011090 <pid_lock>
    80001c48:	854a                	mv	a0,s2
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	f8c080e7          	jalr	-116(ra) # 80000bd6 <acquire>
    pid = nextpid;
    80001c52:	00007797          	auipc	a5,0x7
    80001c56:	cee78793          	addi	a5,a5,-786 # 80008940 <nextpid>
    80001c5a:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c5c:	0014871b          	addiw	a4,s1,1
    80001c60:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c62:	854a                	mv	a0,s2
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	026080e7          	jalr	38(ra) # 80000c8a <release>
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret

0000000080001c7a <proc_pagetable>:
{
    80001c7a:	1101                	addi	sp,sp,-32
    80001c7c:	ec06                	sd	ra,24(sp)
    80001c7e:	e822                	sd	s0,16(sp)
    80001c80:	e426                	sd	s1,8(sp)
    80001c82:	e04a                	sd	s2,0(sp)
    80001c84:	1000                	addi	s0,sp,32
    80001c86:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	6a0080e7          	jalr	1696(ra) # 80001328 <uvmcreate>
    80001c90:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c92:	c121                	beqz	a0,80001cd2 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c94:	4729                	li	a4,10
    80001c96:	00005697          	auipc	a3,0x5
    80001c9a:	36a68693          	addi	a3,a3,874 # 80007000 <_trampoline>
    80001c9e:	6605                	lui	a2,0x1
    80001ca0:	040005b7          	lui	a1,0x4000
    80001ca4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ca6:	05b2                	slli	a1,a1,0xc
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	3f6080e7          	jalr	1014(ra) # 8000109e <mappages>
    80001cb0:	02054863          	bltz	a0,80001ce0 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cb4:	4719                	li	a4,6
    80001cb6:	06093683          	ld	a3,96(s2)
    80001cba:	6605                	lui	a2,0x1
    80001cbc:	020005b7          	lui	a1,0x2000
    80001cc0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cc2:	05b6                	slli	a1,a1,0xd
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	3d8080e7          	jalr	984(ra) # 8000109e <mappages>
    80001cce:	02054163          	bltz	a0,80001cf0 <proc_pagetable+0x76>
}
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	60e2                	ld	ra,24(sp)
    80001cd6:	6442                	ld	s0,16(sp)
    80001cd8:	64a2                	ld	s1,8(sp)
    80001cda:	6902                	ld	s2,0(sp)
    80001cdc:	6105                	addi	sp,sp,32
    80001cde:	8082                	ret
        uvmfree(pagetable, 0);
    80001ce0:	4581                	li	a1,0
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	00000097          	auipc	ra,0x0
    80001ce8:	84a080e7          	jalr	-1974(ra) # 8000152e <uvmfree>
        return 0;
    80001cec:	4481                	li	s1,0
    80001cee:	b7d5                	j	80001cd2 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf0:	4681                	li	a3,0
    80001cf2:	4605                	li	a2,1
    80001cf4:	040005b7          	lui	a1,0x4000
    80001cf8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cfa:	05b2                	slli	a1,a1,0xc
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	566080e7          	jalr	1382(ra) # 80001264 <uvmunmap>
        uvmfree(pagetable, 0);
    80001d06:	4581                	li	a1,0
    80001d08:	8526                	mv	a0,s1
    80001d0a:	00000097          	auipc	ra,0x0
    80001d0e:	824080e7          	jalr	-2012(ra) # 8000152e <uvmfree>
        return 0;
    80001d12:	4481                	li	s1,0
    80001d14:	bf7d                	j	80001cd2 <proc_pagetable+0x58>

0000000080001d16 <proc_freepagetable>:
{
    80001d16:	1101                	addi	sp,sp,-32
    80001d18:	ec06                	sd	ra,24(sp)
    80001d1a:	e822                	sd	s0,16(sp)
    80001d1c:	e426                	sd	s1,8(sp)
    80001d1e:	e04a                	sd	s2,0(sp)
    80001d20:	1000                	addi	s0,sp,32
    80001d22:	84aa                	mv	s1,a0
    80001d24:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d26:	4681                	li	a3,0
    80001d28:	4605                	li	a2,1
    80001d2a:	040005b7          	lui	a1,0x4000
    80001d2e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d30:	05b2                	slli	a1,a1,0xc
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	532080e7          	jalr	1330(ra) # 80001264 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d3a:	4681                	li	a3,0
    80001d3c:	4605                	li	a2,1
    80001d3e:	020005b7          	lui	a1,0x2000
    80001d42:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d44:	05b6                	slli	a1,a1,0xd
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	51c080e7          	jalr	1308(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, sz);
    80001d50:	85ca                	mv	a1,s2
    80001d52:	8526                	mv	a0,s1
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	7da080e7          	jalr	2010(ra) # 8000152e <uvmfree>
}
    80001d5c:	60e2                	ld	ra,24(sp)
    80001d5e:	6442                	ld	s0,16(sp)
    80001d60:	64a2                	ld	s1,8(sp)
    80001d62:	6902                	ld	s2,0(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret

0000000080001d68 <freeproc>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	1000                	addi	s0,sp,32
    80001d72:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001d74:	7128                	ld	a0,96(a0)
    80001d76:	c509                	beqz	a0,80001d80 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	c70080e7          	jalr	-912(ra) # 800009e8 <kfree>
    p->trapframe = 0;
    80001d80:	0604b023          	sd	zero,96(s1)
    if (p->pagetable)
    80001d84:	6ca8                	ld	a0,88(s1)
    80001d86:	c511                	beqz	a0,80001d92 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d88:	68ac                	ld	a1,80(s1)
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	f8c080e7          	jalr	-116(ra) # 80001d16 <proc_freepagetable>
    p->pagetable = 0;
    80001d92:	0404bc23          	sd	zero,88(s1)
    p->sz = 0;
    80001d96:	0404b823          	sd	zero,80(s1)
    p->pid = 0;
    80001d9a:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001d9e:	0404b023          	sd	zero,64(s1)
    p->name[0] = 0;
    80001da2:	16048023          	sb	zero,352(s1)
    p->chan = 0;
    80001da6:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001daa:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001dae:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001db2:	0004ac23          	sw	zero,24(s1)
}
    80001db6:	60e2                	ld	ra,24(sp)
    80001db8:	6442                	ld	s0,16(sp)
    80001dba:	64a2                	ld	s1,8(sp)
    80001dbc:	6105                	addi	sp,sp,32
    80001dbe:	8082                	ret

0000000080001dc0 <allocproc>:
{
    80001dc0:	1101                	addi	sp,sp,-32
    80001dc2:	ec06                	sd	ra,24(sp)
    80001dc4:	e822                	sd	s0,16(sp)
    80001dc6:	e426                	sd	s1,8(sp)
    80001dc8:	e04a                	sd	s2,0(sp)
    80001dca:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001dcc:	0000f497          	auipc	s1,0xf
    80001dd0:	2f448493          	addi	s1,s1,756 # 800110c0 <proc>
    80001dd4:	00015917          	auipc	s2,0x15
    80001dd8:	eec90913          	addi	s2,s2,-276 # 80016cc0 <tickslock>
        acquire(&p->lock);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	df8080e7          	jalr	-520(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80001de6:	4c9c                	lw	a5,24(s1)
    80001de8:	cf81                	beqz	a5,80001e00 <allocproc+0x40>
            release(&p->lock);
    80001dea:	8526                	mv	a0,s1
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	e9e080e7          	jalr	-354(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001df4:	17048493          	addi	s1,s1,368
    80001df8:	ff2492e3          	bne	s1,s2,80001ddc <allocproc+0x1c>
    return 0;
    80001dfc:	4481                	li	s1,0
    80001dfe:	a8a9                	j	80001e58 <allocproc+0x98>
    p->pid = allocpid();
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	e34080e7          	jalr	-460(ra) # 80001c34 <allocpid>
    80001e08:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001e0a:	4785                	li	a5,1
    80001e0c:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	cd8080e7          	jalr	-808(ra) # 80000ae6 <kalloc>
    80001e16:	892a                	mv	s2,a0
    80001e18:	f0a8                	sd	a0,96(s1)
    80001e1a:	c531                	beqz	a0,80001e66 <allocproc+0xa6>
    p->pagetable = proc_pagetable(p);
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	e5c080e7          	jalr	-420(ra) # 80001c7a <proc_pagetable>
    80001e26:	892a                	mv	s2,a0
    80001e28:	eca8                	sd	a0,88(s1)
    if (p->pagetable == 0)
    80001e2a:	c931                	beqz	a0,80001e7e <allocproc+0xbe>
    memset(&p->context, 0, sizeof(p->context));
    80001e2c:	07000613          	li	a2,112
    80001e30:	4581                	li	a1,0
    80001e32:	06848513          	addi	a0,s1,104
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	e9c080e7          	jalr	-356(ra) # 80000cd2 <memset>
    p->context.ra = (uint64)forkret;
    80001e3e:	00000797          	auipc	a5,0x0
    80001e42:	db078793          	addi	a5,a5,-592 # 80001bee <forkret>
    80001e46:	f4bc                	sd	a5,104(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e48:	64bc                	ld	a5,72(s1)
    80001e4a:	6705                	lui	a4,0x1
    80001e4c:	97ba                	add	a5,a5,a4
    80001e4e:	f8bc                	sd	a5,112(s1)
    p->priority = 0;
    80001e50:	0204aa23          	sw	zero,52(s1)
    p->timesScheduled = 0;
    80001e54:	0204ac23          	sw	zero,56(s1)
}
    80001e58:	8526                	mv	a0,s1
    80001e5a:	60e2                	ld	ra,24(sp)
    80001e5c:	6442                	ld	s0,16(sp)
    80001e5e:	64a2                	ld	s1,8(sp)
    80001e60:	6902                	ld	s2,0(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret
        freeproc(p);
    80001e66:	8526                	mv	a0,s1
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	f00080e7          	jalr	-256(ra) # 80001d68 <freeproc>
        release(&p->lock);
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	e18080e7          	jalr	-488(ra) # 80000c8a <release>
        return 0;
    80001e7a:	84ca                	mv	s1,s2
    80001e7c:	bff1                	j	80001e58 <allocproc+0x98>
        freeproc(p);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	ee8080e7          	jalr	-280(ra) # 80001d68 <freeproc>
        release(&p->lock);
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e00080e7          	jalr	-512(ra) # 80000c8a <release>
        return 0;
    80001e92:	84ca                	mv	s1,s2
    80001e94:	b7d1                	j	80001e58 <allocproc+0x98>

0000000080001e96 <userinit>:
{
    80001e96:	1101                	addi	sp,sp,-32
    80001e98:	ec06                	sd	ra,24(sp)
    80001e9a:	e822                	sd	s0,16(sp)
    80001e9c:	e426                	sd	s1,8(sp)
    80001e9e:	1000                	addi	s0,sp,32
    p = allocproc();
    80001ea0:	00000097          	auipc	ra,0x0
    80001ea4:	f20080e7          	jalr	-224(ra) # 80001dc0 <allocproc>
    80001ea8:	84aa                	mv	s1,a0
    initproc = p;
    80001eaa:	00007797          	auipc	a5,0x7
    80001eae:	b6a7b723          	sd	a0,-1170(a5) # 80008a18 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001eb2:	03400613          	li	a2,52
    80001eb6:	00007597          	auipc	a1,0x7
    80001eba:	a9a58593          	addi	a1,a1,-1382 # 80008950 <initcode>
    80001ebe:	6d28                	ld	a0,88(a0)
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	496080e7          	jalr	1174(ra) # 80001356 <uvmfirst>
    p->sz = PGSIZE;
    80001ec8:	6785                	lui	a5,0x1
    80001eca:	e8bc                	sd	a5,80(s1)
    p->trapframe->epc = 0;     // user program counter
    80001ecc:	70b8                	ld	a4,96(s1)
    80001ece:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001ed2:	70b8                	ld	a4,96(s1)
    80001ed4:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	00006597          	auipc	a1,0x6
    80001edc:	32858593          	addi	a1,a1,808 # 80008200 <digits+0x1c0>
    80001ee0:	16048513          	addi	a0,s1,352
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	f38080e7          	jalr	-200(ra) # 80000e1c <safestrcpy>
    p->cwd = namei("/");
    80001eec:	00006517          	auipc	a0,0x6
    80001ef0:	32450513          	addi	a0,a0,804 # 80008210 <digits+0x1d0>
    80001ef4:	00002097          	auipc	ra,0x2
    80001ef8:	3fc080e7          	jalr	1020(ra) # 800042f0 <namei>
    80001efc:	14a4bc23          	sd	a0,344(s1)
    p->state = RUNNABLE;
    80001f00:	478d                	li	a5,3
    80001f02:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
}
    80001f0e:	60e2                	ld	ra,24(sp)
    80001f10:	6442                	ld	s0,16(sp)
    80001f12:	64a2                	ld	s1,8(sp)
    80001f14:	6105                	addi	sp,sp,32
    80001f16:	8082                	ret

0000000080001f18 <growproc>:
{
    80001f18:	1101                	addi	sp,sp,-32
    80001f1a:	ec06                	sd	ra,24(sp)
    80001f1c:	e822                	sd	s0,16(sp)
    80001f1e:	e426                	sd	s1,8(sp)
    80001f20:	e04a                	sd	s2,0(sp)
    80001f22:	1000                	addi	s0,sp,32
    80001f24:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	c90080e7          	jalr	-880(ra) # 80001bb6 <myproc>
    80001f2e:	84aa                	mv	s1,a0
    sz = p->sz;
    80001f30:	692c                	ld	a1,80(a0)
    if (n > 0)
    80001f32:	01204c63          	bgtz	s2,80001f4a <growproc+0x32>
    else if (n < 0)
    80001f36:	02094663          	bltz	s2,80001f62 <growproc+0x4a>
    p->sz = sz;
    80001f3a:	e8ac                	sd	a1,80(s1)
    return 0;
    80001f3c:	4501                	li	a0,0
}
    80001f3e:	60e2                	ld	ra,24(sp)
    80001f40:	6442                	ld	s0,16(sp)
    80001f42:	64a2                	ld	s1,8(sp)
    80001f44:	6902                	ld	s2,0(sp)
    80001f46:	6105                	addi	sp,sp,32
    80001f48:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f4a:	4691                	li	a3,4
    80001f4c:	00b90633          	add	a2,s2,a1
    80001f50:	6d28                	ld	a0,88(a0)
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	4be080e7          	jalr	1214(ra) # 80001410 <uvmalloc>
    80001f5a:	85aa                	mv	a1,a0
    80001f5c:	fd79                	bnez	a0,80001f3a <growproc+0x22>
            return -1;
    80001f5e:	557d                	li	a0,-1
    80001f60:	bff9                	j	80001f3e <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f62:	00b90633          	add	a2,s2,a1
    80001f66:	6d28                	ld	a0,88(a0)
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	460080e7          	jalr	1120(ra) # 800013c8 <uvmdealloc>
    80001f70:	85aa                	mv	a1,a0
    80001f72:	b7e1                	j	80001f3a <growproc+0x22>

0000000080001f74 <ps>:
{
    80001f74:	715d                	addi	sp,sp,-80
    80001f76:	e486                	sd	ra,72(sp)
    80001f78:	e0a2                	sd	s0,64(sp)
    80001f7a:	fc26                	sd	s1,56(sp)
    80001f7c:	f84a                	sd	s2,48(sp)
    80001f7e:	f44e                	sd	s3,40(sp)
    80001f80:	f052                	sd	s4,32(sp)
    80001f82:	ec56                	sd	s5,24(sp)
    80001f84:	e85a                	sd	s6,16(sp)
    80001f86:	e45e                	sd	s7,8(sp)
    80001f88:	e062                	sd	s8,0(sp)
    80001f8a:	0880                	addi	s0,sp,80
    80001f8c:	84aa                	mv	s1,a0
    80001f8e:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	c26080e7          	jalr	-986(ra) # 80001bb6 <myproc>
        return result;
    80001f98:	4901                	li	s2,0
    if (count == 0)
    80001f9a:	0c0b8563          	beqz	s7,80002064 <ps+0xf0>
    void *result = (void *)myproc()->sz;
    80001f9e:	05053b03          	ld	s6,80(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001fa2:	003b951b          	slliw	a0,s7,0x3
    80001fa6:	0175053b          	addw	a0,a0,s7
    80001faa:	0025151b          	slliw	a0,a0,0x2
    80001fae:	00000097          	auipc	ra,0x0
    80001fb2:	f6a080e7          	jalr	-150(ra) # 80001f18 <growproc>
    80001fb6:	12054f63          	bltz	a0,800020f4 <ps+0x180>
    struct user_proc loc_result[count];
    80001fba:	003b9a13          	slli	s4,s7,0x3
    80001fbe:	9a5e                	add	s4,s4,s7
    80001fc0:	0a0a                	slli	s4,s4,0x2
    80001fc2:	00fa0793          	addi	a5,s4,15
    80001fc6:	8391                	srli	a5,a5,0x4
    80001fc8:	0792                	slli	a5,a5,0x4
    80001fca:	40f10133          	sub	sp,sp,a5
    80001fce:	8a8a                	mv	s5,sp
    struct proc *p = proc + start;
    80001fd0:	17000793          	li	a5,368
    80001fd4:	02f484b3          	mul	s1,s1,a5
    80001fd8:	0000f797          	auipc	a5,0xf
    80001fdc:	0e878793          	addi	a5,a5,232 # 800110c0 <proc>
    80001fe0:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001fe2:	00015797          	auipc	a5,0x15
    80001fe6:	cde78793          	addi	a5,a5,-802 # 80016cc0 <tickslock>
        return result;
    80001fea:	4901                	li	s2,0
    if (p >= &proc[NPROC])
    80001fec:	06f4fc63          	bgeu	s1,a5,80002064 <ps+0xf0>
    acquire(&wait_lock);
    80001ff0:	0000f517          	auipc	a0,0xf
    80001ff4:	0b850513          	addi	a0,a0,184 # 800110a8 <wait_lock>
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	bde080e7          	jalr	-1058(ra) # 80000bd6 <acquire>
        if (localCount == count)
    80002000:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80002004:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80002006:	00015c17          	auipc	s8,0x15
    8000200a:	cbac0c13          	addi	s8,s8,-838 # 80016cc0 <tickslock>
    8000200e:	a851                	j	800020a2 <ps+0x12e>
            loc_result[localCount].state = UNUSED;
    80002010:	00399793          	slli	a5,s3,0x3
    80002014:	97ce                	add	a5,a5,s3
    80002016:	078a                	slli	a5,a5,0x2
    80002018:	97d6                	add	a5,a5,s5
    8000201a:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    8000201e:	8526                	mv	a0,s1
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	c6a080e7          	jalr	-918(ra) # 80000c8a <release>
    release(&wait_lock);
    80002028:	0000f517          	auipc	a0,0xf
    8000202c:	08050513          	addi	a0,a0,128 # 800110a8 <wait_lock>
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	c5a080e7          	jalr	-934(ra) # 80000c8a <release>
    if (localCount < count)
    80002038:	0179f963          	bgeu	s3,s7,8000204a <ps+0xd6>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    8000203c:	00399793          	slli	a5,s3,0x3
    80002040:	97ce                	add	a5,a5,s3
    80002042:	078a                	slli	a5,a5,0x2
    80002044:	97d6                	add	a5,a5,s5
    80002046:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    8000204a:	895a                	mv	s2,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	b6a080e7          	jalr	-1174(ra) # 80001bb6 <myproc>
    80002054:	86d2                	mv	a3,s4
    80002056:	8656                	mv	a2,s5
    80002058:	85da                	mv	a1,s6
    8000205a:	6d28                	ld	a0,88(a0)
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	610080e7          	jalr	1552(ra) # 8000166c <copyout>
}
    80002064:	854a                	mv	a0,s2
    80002066:	fb040113          	addi	sp,s0,-80
    8000206a:	60a6                	ld	ra,72(sp)
    8000206c:	6406                	ld	s0,64(sp)
    8000206e:	74e2                	ld	s1,56(sp)
    80002070:	7942                	ld	s2,48(sp)
    80002072:	79a2                	ld	s3,40(sp)
    80002074:	7a02                	ld	s4,32(sp)
    80002076:	6ae2                	ld	s5,24(sp)
    80002078:	6b42                	ld	s6,16(sp)
    8000207a:	6ba2                	ld	s7,8(sp)
    8000207c:	6c02                	ld	s8,0(sp)
    8000207e:	6161                	addi	sp,sp,80
    80002080:	8082                	ret
        release(&p->lock);
    80002082:	8526                	mv	a0,s1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	c06080e7          	jalr	-1018(ra) # 80000c8a <release>
        localCount++;
    8000208c:	2985                	addiw	s3,s3,1
    8000208e:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002092:	17048493          	addi	s1,s1,368
    80002096:	f984f9e3          	bgeu	s1,s8,80002028 <ps+0xb4>
        if (localCount == count)
    8000209a:	02490913          	addi	s2,s2,36
    8000209e:	053b8d63          	beq	s7,s3,800020f8 <ps+0x184>
        acquire(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b32080e7          	jalr	-1230(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    800020ac:	4c9c                	lw	a5,24(s1)
    800020ae:	d3ad                	beqz	a5,80002010 <ps+0x9c>
        loc_result[localCount].state = p->state;
    800020b0:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    800020b4:	549c                	lw	a5,40(s1)
    800020b6:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    800020ba:	54dc                	lw	a5,44(s1)
    800020bc:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    800020c0:	589c                	lw	a5,48(s1)
    800020c2:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    800020c6:	4641                	li	a2,16
    800020c8:	85ca                	mv	a1,s2
    800020ca:	16048513          	addi	a0,s1,352
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	a8e080e7          	jalr	-1394(ra) # 80001b5c <copy_array>
        if (p->parent != 0) // init
    800020d6:	60a8                	ld	a0,64(s1)
    800020d8:	d54d                	beqz	a0,80002082 <ps+0x10e>
            acquire(&p->parent->lock);
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	afc080e7          	jalr	-1284(ra) # 80000bd6 <acquire>
            loc_result[localCount].parent_id = p->parent->pid;
    800020e2:	60a8                	ld	a0,64(s1)
    800020e4:	591c                	lw	a5,48(a0)
    800020e6:	fef92e23          	sw	a5,-4(s2)
            release(&p->parent->lock);
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	ba0080e7          	jalr	-1120(ra) # 80000c8a <release>
    800020f2:	bf41                	j	80002082 <ps+0x10e>
        return result;
    800020f4:	4901                	li	s2,0
    800020f6:	b7bd                	j	80002064 <ps+0xf0>
    release(&wait_lock);
    800020f8:	0000f517          	auipc	a0,0xf
    800020fc:	fb050513          	addi	a0,a0,-80 # 800110a8 <wait_lock>
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	b8a080e7          	jalr	-1142(ra) # 80000c8a <release>
    if (localCount < count)
    80002108:	b789                	j	8000204a <ps+0xd6>

000000008000210a <fork>:
{
    8000210a:	7139                	addi	sp,sp,-64
    8000210c:	fc06                	sd	ra,56(sp)
    8000210e:	f822                	sd	s0,48(sp)
    80002110:	f426                	sd	s1,40(sp)
    80002112:	f04a                	sd	s2,32(sp)
    80002114:	ec4e                	sd	s3,24(sp)
    80002116:	e852                	sd	s4,16(sp)
    80002118:	e456                	sd	s5,8(sp)
    8000211a:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	a9a080e7          	jalr	-1382(ra) # 80001bb6 <myproc>
    80002124:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	c9a080e7          	jalr	-870(ra) # 80001dc0 <allocproc>
    8000212e:	10050c63          	beqz	a0,80002246 <fork+0x13c>
    80002132:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002134:	050ab603          	ld	a2,80(s5)
    80002138:	6d2c                	ld	a1,88(a0)
    8000213a:	058ab503          	ld	a0,88(s5)
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	42a080e7          	jalr	1066(ra) # 80001568 <uvmcopy>
    80002146:	04054863          	bltz	a0,80002196 <fork+0x8c>
    np->sz = p->sz;
    8000214a:	050ab783          	ld	a5,80(s5)
    8000214e:	04fa3823          	sd	a5,80(s4)
    *(np->trapframe) = *(p->trapframe);
    80002152:	060ab683          	ld	a3,96(s5)
    80002156:	87b6                	mv	a5,a3
    80002158:	060a3703          	ld	a4,96(s4)
    8000215c:	12068693          	addi	a3,a3,288
    80002160:	0007b803          	ld	a6,0(a5)
    80002164:	6788                	ld	a0,8(a5)
    80002166:	6b8c                	ld	a1,16(a5)
    80002168:	6f90                	ld	a2,24(a5)
    8000216a:	01073023          	sd	a6,0(a4)
    8000216e:	e708                	sd	a0,8(a4)
    80002170:	eb0c                	sd	a1,16(a4)
    80002172:	ef10                	sd	a2,24(a4)
    80002174:	02078793          	addi	a5,a5,32
    80002178:	02070713          	addi	a4,a4,32
    8000217c:	fed792e3          	bne	a5,a3,80002160 <fork+0x56>
    np->trapframe->a0 = 0;
    80002180:	060a3783          	ld	a5,96(s4)
    80002184:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002188:	0d8a8493          	addi	s1,s5,216
    8000218c:	0d8a0913          	addi	s2,s4,216
    80002190:	158a8993          	addi	s3,s5,344
    80002194:	a00d                	j	800021b6 <fork+0xac>
        freeproc(np);
    80002196:	8552                	mv	a0,s4
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	bd0080e7          	jalr	-1072(ra) # 80001d68 <freeproc>
        release(&np->lock);
    800021a0:	8552                	mv	a0,s4
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	ae8080e7          	jalr	-1304(ra) # 80000c8a <release>
        return -1;
    800021aa:	597d                	li	s2,-1
    800021ac:	a059                	j	80002232 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    800021ae:	04a1                	addi	s1,s1,8
    800021b0:	0921                	addi	s2,s2,8
    800021b2:	01348b63          	beq	s1,s3,800021c8 <fork+0xbe>
        if (p->ofile[i])
    800021b6:	6088                	ld	a0,0(s1)
    800021b8:	d97d                	beqz	a0,800021ae <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    800021ba:	00002097          	auipc	ra,0x2
    800021be:	7cc080e7          	jalr	1996(ra) # 80004986 <filedup>
    800021c2:	00a93023          	sd	a0,0(s2)
    800021c6:	b7e5                	j	800021ae <fork+0xa4>
    np->cwd = idup(p->cwd);
    800021c8:	158ab503          	ld	a0,344(s5)
    800021cc:	00002097          	auipc	ra,0x2
    800021d0:	93a080e7          	jalr	-1734(ra) # 80003b06 <idup>
    800021d4:	14aa3c23          	sd	a0,344(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    800021d8:	4641                	li	a2,16
    800021da:	160a8593          	addi	a1,s5,352
    800021de:	160a0513          	addi	a0,s4,352
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	c3a080e7          	jalr	-966(ra) # 80000e1c <safestrcpy>
    pid = np->pid;
    800021ea:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    800021ee:	8552                	mv	a0,s4
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	a9a080e7          	jalr	-1382(ra) # 80000c8a <release>
    acquire(&wait_lock);
    800021f8:	0000f497          	auipc	s1,0xf
    800021fc:	eb048493          	addi	s1,s1,-336 # 800110a8 <wait_lock>
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	9d4080e7          	jalr	-1580(ra) # 80000bd6 <acquire>
    np->parent = p;
    8000220a:	055a3023          	sd	s5,64(s4)
    release(&wait_lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	a7a080e7          	jalr	-1414(ra) # 80000c8a <release>
    acquire(&np->lock);
    80002218:	8552                	mv	a0,s4
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	9bc080e7          	jalr	-1604(ra) # 80000bd6 <acquire>
    np->state = RUNNABLE;
    80002222:	478d                	li	a5,3
    80002224:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002228:	8552                	mv	a0,s4
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	a60080e7          	jalr	-1440(ra) # 80000c8a <release>
}
    80002232:	854a                	mv	a0,s2
    80002234:	70e2                	ld	ra,56(sp)
    80002236:	7442                	ld	s0,48(sp)
    80002238:	74a2                	ld	s1,40(sp)
    8000223a:	7902                	ld	s2,32(sp)
    8000223c:	69e2                	ld	s3,24(sp)
    8000223e:	6a42                	ld	s4,16(sp)
    80002240:	6aa2                	ld	s5,8(sp)
    80002242:	6121                	addi	sp,sp,64
    80002244:	8082                	ret
        return -1;
    80002246:	597d                	li	s2,-1
    80002248:	b7ed                	j	80002232 <fork+0x128>

000000008000224a <scheduler>:
{
    8000224a:	1101                	addi	sp,sp,-32
    8000224c:	ec06                	sd	ra,24(sp)
    8000224e:	e822                	sd	s0,16(sp)
    80002250:	e426                	sd	s1,8(sp)
    80002252:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    80002254:	00006497          	auipc	s1,0x6
    80002258:	6e448493          	addi	s1,s1,1764 # 80008938 <sched_pointer>
    8000225c:	609c                	ld	a5,0(s1)
    8000225e:	9782                	jalr	a5
    while (1)
    80002260:	bff5                	j	8000225c <scheduler+0x12>

0000000080002262 <sched>:
{
    80002262:	7179                	addi	sp,sp,-48
    80002264:	f406                	sd	ra,40(sp)
    80002266:	f022                	sd	s0,32(sp)
    80002268:	ec26                	sd	s1,24(sp)
    8000226a:	e84a                	sd	s2,16(sp)
    8000226c:	e44e                	sd	s3,8(sp)
    8000226e:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002270:	00000097          	auipc	ra,0x0
    80002274:	946080e7          	jalr	-1722(ra) # 80001bb6 <myproc>
    80002278:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	8e2080e7          	jalr	-1822(ra) # 80000b5c <holding>
    80002282:	c53d                	beqz	a0,800022f0 <sched+0x8e>
    80002284:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002286:	2781                	sext.w	a5,a5
    80002288:	079e                	slli	a5,a5,0x7
    8000228a:	0000f717          	auipc	a4,0xf
    8000228e:	a0670713          	addi	a4,a4,-1530 # 80010c90 <cpus>
    80002292:	97ba                	add	a5,a5,a4
    80002294:	5fb8                	lw	a4,120(a5)
    80002296:	4785                	li	a5,1
    80002298:	06f71463          	bne	a4,a5,80002300 <sched+0x9e>
    if (p->state == RUNNING)
    8000229c:	4c98                	lw	a4,24(s1)
    8000229e:	4791                	li	a5,4
    800022a0:	06f70863          	beq	a4,a5,80002310 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022a8:	8b89                	andi	a5,a5,2
    if (intr_get())
    800022aa:	ebbd                	bnez	a5,80002320 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ac:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800022ae:	0000f917          	auipc	s2,0xf
    800022b2:	9e290913          	addi	s2,s2,-1566 # 80010c90 <cpus>
    800022b6:	2781                	sext.w	a5,a5
    800022b8:	079e                	slli	a5,a5,0x7
    800022ba:	97ca                	add	a5,a5,s2
    800022bc:	07c7a983          	lw	s3,124(a5)
    800022c0:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    800022c2:	2581                	sext.w	a1,a1
    800022c4:	059e                	slli	a1,a1,0x7
    800022c6:	05a1                	addi	a1,a1,8
    800022c8:	95ca                	add	a1,a1,s2
    800022ca:	06848513          	addi	a0,s1,104
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	752080e7          	jalr	1874(ra) # 80002a20 <swtch>
    800022d6:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800022d8:	2781                	sext.w	a5,a5
    800022da:	079e                	slli	a5,a5,0x7
    800022dc:	993e                	add	s2,s2,a5
    800022de:	07392e23          	sw	s3,124(s2)
}
    800022e2:	70a2                	ld	ra,40(sp)
    800022e4:	7402                	ld	s0,32(sp)
    800022e6:	64e2                	ld	s1,24(sp)
    800022e8:	6942                	ld	s2,16(sp)
    800022ea:	69a2                	ld	s3,8(sp)
    800022ec:	6145                	addi	sp,sp,48
    800022ee:	8082                	ret
        panic("sched p->lock");
    800022f0:	00006517          	auipc	a0,0x6
    800022f4:	f2850513          	addi	a0,a0,-216 # 80008218 <digits+0x1d8>
    800022f8:	ffffe097          	auipc	ra,0xffffe
    800022fc:	248080e7          	jalr	584(ra) # 80000540 <panic>
        panic("sched locks");
    80002300:	00006517          	auipc	a0,0x6
    80002304:	f2850513          	addi	a0,a0,-216 # 80008228 <digits+0x1e8>
    80002308:	ffffe097          	auipc	ra,0xffffe
    8000230c:	238080e7          	jalr	568(ra) # 80000540 <panic>
        panic("sched running");
    80002310:	00006517          	auipc	a0,0x6
    80002314:	f2850513          	addi	a0,a0,-216 # 80008238 <digits+0x1f8>
    80002318:	ffffe097          	auipc	ra,0xffffe
    8000231c:	228080e7          	jalr	552(ra) # 80000540 <panic>
        panic("sched interruptible");
    80002320:	00006517          	auipc	a0,0x6
    80002324:	f2850513          	addi	a0,a0,-216 # 80008248 <digits+0x208>
    80002328:	ffffe097          	auipc	ra,0xffffe
    8000232c:	218080e7          	jalr	536(ra) # 80000540 <panic>

0000000080002330 <yield>:
{
    80002330:	1101                	addi	sp,sp,-32
    80002332:	ec06                	sd	ra,24(sp)
    80002334:	e822                	sd	s0,16(sp)
    80002336:	e426                	sd	s1,8(sp)
    80002338:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	87c080e7          	jalr	-1924(ra) # 80001bb6 <myproc>
    80002342:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	892080e7          	jalr	-1902(ra) # 80000bd6 <acquire>
    p->state = RUNNABLE;
    8000234c:	478d                	li	a5,3
    8000234e:	cc9c                	sw	a5,24(s1)
    p->priority = 1;
    80002350:	4785                	li	a5,1
    80002352:	d8dc                	sw	a5,52(s1)
    p->timesScheduled++;
    80002354:	5c9c                	lw	a5,56(s1)
    80002356:	2785                	addiw	a5,a5,1
    80002358:	dc9c                	sw	a5,56(s1)
    sched();
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	f08080e7          	jalr	-248(ra) # 80002262 <sched>
    release(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	926080e7          	jalr	-1754(ra) # 80000c8a <release>
}
    8000236c:	60e2                	ld	ra,24(sp)
    8000236e:	6442                	ld	s0,16(sp)
    80002370:	64a2                	ld	s1,8(sp)
    80002372:	6105                	addi	sp,sp,32
    80002374:	8082                	ret

0000000080002376 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002376:	7179                	addi	sp,sp,-48
    80002378:	f406                	sd	ra,40(sp)
    8000237a:	f022                	sd	s0,32(sp)
    8000237c:	ec26                	sd	s1,24(sp)
    8000237e:	e84a                	sd	s2,16(sp)
    80002380:	e44e                	sd	s3,8(sp)
    80002382:	1800                	addi	s0,sp,48
    80002384:	89aa                	mv	s3,a0
    80002386:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002388:	00000097          	auipc	ra,0x0
    8000238c:	82e080e7          	jalr	-2002(ra) # 80001bb6 <myproc>
    80002390:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	844080e7          	jalr	-1980(ra) # 80000bd6 <acquire>
    release(lk);
    8000239a:	854a                	mv	a0,s2
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	8ee080e7          	jalr	-1810(ra) # 80000c8a <release>

    // Go to sleep.
    p->chan = chan;
    800023a4:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800023a8:	4789                	li	a5,2
    800023aa:	cc9c                	sw	a5,24(s1)

    sched();
    800023ac:	00000097          	auipc	ra,0x0
    800023b0:	eb6080e7          	jalr	-330(ra) # 80002262 <sched>

    // Tidy up.
    p->chan = 0;
    800023b4:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	8d0080e7          	jalr	-1840(ra) # 80000c8a <release>
    acquire(lk);
    800023c2:	854a                	mv	a0,s2
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	812080e7          	jalr	-2030(ra) # 80000bd6 <acquire>
}
    800023cc:	70a2                	ld	ra,40(sp)
    800023ce:	7402                	ld	s0,32(sp)
    800023d0:	64e2                	ld	s1,24(sp)
    800023d2:	6942                	ld	s2,16(sp)
    800023d4:	69a2                	ld	s3,8(sp)
    800023d6:	6145                	addi	sp,sp,48
    800023d8:	8082                	ret

00000000800023da <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023da:	7139                	addi	sp,sp,-64
    800023dc:	fc06                	sd	ra,56(sp)
    800023de:	f822                	sd	s0,48(sp)
    800023e0:	f426                	sd	s1,40(sp)
    800023e2:	f04a                	sd	s2,32(sp)
    800023e4:	ec4e                	sd	s3,24(sp)
    800023e6:	e852                	sd	s4,16(sp)
    800023e8:	e456                	sd	s5,8(sp)
    800023ea:	0080                	addi	s0,sp,64
    800023ec:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800023ee:	0000f497          	auipc	s1,0xf
    800023f2:	cd248493          	addi	s1,s1,-814 # 800110c0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800023f6:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800023f8:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800023fa:	00015917          	auipc	s2,0x15
    800023fe:	8c690913          	addi	s2,s2,-1850 # 80016cc0 <tickslock>
    80002402:	a811                	j	80002416 <wakeup+0x3c>
            }
            release(&p->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	884080e7          	jalr	-1916(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000240e:	17048493          	addi	s1,s1,368
    80002412:	03248663          	beq	s1,s2,8000243e <wakeup+0x64>
        if (p != myproc())
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	7a0080e7          	jalr	1952(ra) # 80001bb6 <myproc>
    8000241e:	fea488e3          	beq	s1,a0,8000240e <wakeup+0x34>
            acquire(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	7b2080e7          	jalr	1970(ra) # 80000bd6 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000242c:	4c9c                	lw	a5,24(s1)
    8000242e:	fd379be3          	bne	a5,s3,80002404 <wakeup+0x2a>
    80002432:	709c                	ld	a5,32(s1)
    80002434:	fd4798e3          	bne	a5,s4,80002404 <wakeup+0x2a>
                p->state = RUNNABLE;
    80002438:	0154ac23          	sw	s5,24(s1)
    8000243c:	b7e1                	j	80002404 <wakeup+0x2a>
        }
    }
}
    8000243e:	70e2                	ld	ra,56(sp)
    80002440:	7442                	ld	s0,48(sp)
    80002442:	74a2                	ld	s1,40(sp)
    80002444:	7902                	ld	s2,32(sp)
    80002446:	69e2                	ld	s3,24(sp)
    80002448:	6a42                	ld	s4,16(sp)
    8000244a:	6aa2                	ld	s5,8(sp)
    8000244c:	6121                	addi	sp,sp,64
    8000244e:	8082                	ret

0000000080002450 <reparent>:
{
    80002450:	7179                	addi	sp,sp,-48
    80002452:	f406                	sd	ra,40(sp)
    80002454:	f022                	sd	s0,32(sp)
    80002456:	ec26                	sd	s1,24(sp)
    80002458:	e84a                	sd	s2,16(sp)
    8000245a:	e44e                	sd	s3,8(sp)
    8000245c:	e052                	sd	s4,0(sp)
    8000245e:	1800                	addi	s0,sp,48
    80002460:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002462:	0000f497          	auipc	s1,0xf
    80002466:	c5e48493          	addi	s1,s1,-930 # 800110c0 <proc>
            pp->parent = initproc;
    8000246a:	00006a17          	auipc	s4,0x6
    8000246e:	5aea0a13          	addi	s4,s4,1454 # 80008a18 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002472:	00015997          	auipc	s3,0x15
    80002476:	84e98993          	addi	s3,s3,-1970 # 80016cc0 <tickslock>
    8000247a:	a029                	j	80002484 <reparent+0x34>
    8000247c:	17048493          	addi	s1,s1,368
    80002480:	01348d63          	beq	s1,s3,8000249a <reparent+0x4a>
        if (pp->parent == p)
    80002484:	60bc                	ld	a5,64(s1)
    80002486:	ff279be3          	bne	a5,s2,8000247c <reparent+0x2c>
            pp->parent = initproc;
    8000248a:	000a3503          	ld	a0,0(s4)
    8000248e:	e0a8                	sd	a0,64(s1)
            wakeup(initproc);
    80002490:	00000097          	auipc	ra,0x0
    80002494:	f4a080e7          	jalr	-182(ra) # 800023da <wakeup>
    80002498:	b7d5                	j	8000247c <reparent+0x2c>
}
    8000249a:	70a2                	ld	ra,40(sp)
    8000249c:	7402                	ld	s0,32(sp)
    8000249e:	64e2                	ld	s1,24(sp)
    800024a0:	6942                	ld	s2,16(sp)
    800024a2:	69a2                	ld	s3,8(sp)
    800024a4:	6a02                	ld	s4,0(sp)
    800024a6:	6145                	addi	sp,sp,48
    800024a8:	8082                	ret

00000000800024aa <exit>:
{
    800024aa:	7179                	addi	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	e052                	sd	s4,0(sp)
    800024b8:	1800                	addi	s0,sp,48
    800024ba:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	6fa080e7          	jalr	1786(ra) # 80001bb6 <myproc>
    800024c4:	89aa                	mv	s3,a0
    if (p == initproc)
    800024c6:	00006797          	auipc	a5,0x6
    800024ca:	5527b783          	ld	a5,1362(a5) # 80008a18 <initproc>
    800024ce:	0d850493          	addi	s1,a0,216
    800024d2:	15850913          	addi	s2,a0,344
    800024d6:	02a79363          	bne	a5,a0,800024fc <exit+0x52>
        panic("init exiting");
    800024da:	00006517          	auipc	a0,0x6
    800024de:	d8650513          	addi	a0,a0,-634 # 80008260 <digits+0x220>
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	05e080e7          	jalr	94(ra) # 80000540 <panic>
            fileclose(f);
    800024ea:	00002097          	auipc	ra,0x2
    800024ee:	4ee080e7          	jalr	1262(ra) # 800049d8 <fileclose>
            p->ofile[fd] = 0;
    800024f2:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800024f6:	04a1                	addi	s1,s1,8
    800024f8:	01248563          	beq	s1,s2,80002502 <exit+0x58>
        if (p->ofile[fd])
    800024fc:	6088                	ld	a0,0(s1)
    800024fe:	f575                	bnez	a0,800024ea <exit+0x40>
    80002500:	bfdd                	j	800024f6 <exit+0x4c>
    begin_op();
    80002502:	00002097          	auipc	ra,0x2
    80002506:	00e080e7          	jalr	14(ra) # 80004510 <begin_op>
    iput(p->cwd);
    8000250a:	1589b503          	ld	a0,344(s3)
    8000250e:	00001097          	auipc	ra,0x1
    80002512:	7f0080e7          	jalr	2032(ra) # 80003cfe <iput>
    end_op();
    80002516:	00002097          	auipc	ra,0x2
    8000251a:	078080e7          	jalr	120(ra) # 8000458e <end_op>
    p->cwd = 0;
    8000251e:	1409bc23          	sd	zero,344(s3)
    acquire(&wait_lock);
    80002522:	0000f497          	auipc	s1,0xf
    80002526:	b8648493          	addi	s1,s1,-1146 # 800110a8 <wait_lock>
    8000252a:	8526                	mv	a0,s1
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	6aa080e7          	jalr	1706(ra) # 80000bd6 <acquire>
    reparent(p);
    80002534:	854e                	mv	a0,s3
    80002536:	00000097          	auipc	ra,0x0
    8000253a:	f1a080e7          	jalr	-230(ra) # 80002450 <reparent>
    wakeup(p->parent);
    8000253e:	0409b503          	ld	a0,64(s3)
    80002542:	00000097          	auipc	ra,0x0
    80002546:	e98080e7          	jalr	-360(ra) # 800023da <wakeup>
    acquire(&p->lock);
    8000254a:	854e                	mv	a0,s3
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	68a080e7          	jalr	1674(ra) # 80000bd6 <acquire>
    p->xstate = status;
    80002554:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002558:	4795                	li	a5,5
    8000255a:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	72a080e7          	jalr	1834(ra) # 80000c8a <release>
    sched();
    80002568:	00000097          	auipc	ra,0x0
    8000256c:	cfa080e7          	jalr	-774(ra) # 80002262 <sched>
    panic("zombie exit");
    80002570:	00006517          	auipc	a0,0x6
    80002574:	d0050513          	addi	a0,a0,-768 # 80008270 <digits+0x230>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	fc8080e7          	jalr	-56(ra) # 80000540 <panic>

0000000080002580 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002580:	7179                	addi	sp,sp,-48
    80002582:	f406                	sd	ra,40(sp)
    80002584:	f022                	sd	s0,32(sp)
    80002586:	ec26                	sd	s1,24(sp)
    80002588:	e84a                	sd	s2,16(sp)
    8000258a:	e44e                	sd	s3,8(sp)
    8000258c:	1800                	addi	s0,sp,48
    8000258e:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002590:	0000f497          	auipc	s1,0xf
    80002594:	b3048493          	addi	s1,s1,-1232 # 800110c0 <proc>
    80002598:	00014997          	auipc	s3,0x14
    8000259c:	72898993          	addi	s3,s3,1832 # 80016cc0 <tickslock>
    {
        acquire(&p->lock);
    800025a0:	8526                	mv	a0,s1
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	634080e7          	jalr	1588(ra) # 80000bd6 <acquire>
        if (p->pid == pid)
    800025aa:	589c                	lw	a5,48(s1)
    800025ac:	01278d63          	beq	a5,s2,800025c6 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800025b0:	8526                	mv	a0,s1
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	6d8080e7          	jalr	1752(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800025ba:	17048493          	addi	s1,s1,368
    800025be:	ff3491e3          	bne	s1,s3,800025a0 <kill+0x20>
    }
    return -1;
    800025c2:	557d                	li	a0,-1
    800025c4:	a829                	j	800025de <kill+0x5e>
            p->killed = 1;
    800025c6:	4785                	li	a5,1
    800025c8:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    800025ca:	4c98                	lw	a4,24(s1)
    800025cc:	4789                	li	a5,2
    800025ce:	00f70f63          	beq	a4,a5,800025ec <kill+0x6c>
            release(&p->lock);
    800025d2:	8526                	mv	a0,s1
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6b6080e7          	jalr	1718(ra) # 80000c8a <release>
            return 0;
    800025dc:	4501                	li	a0,0
}
    800025de:	70a2                	ld	ra,40(sp)
    800025e0:	7402                	ld	s0,32(sp)
    800025e2:	64e2                	ld	s1,24(sp)
    800025e4:	6942                	ld	s2,16(sp)
    800025e6:	69a2                	ld	s3,8(sp)
    800025e8:	6145                	addi	sp,sp,48
    800025ea:	8082                	ret
                p->state = RUNNABLE;
    800025ec:	478d                	li	a5,3
    800025ee:	cc9c                	sw	a5,24(s1)
    800025f0:	b7cd                	j	800025d2 <kill+0x52>

00000000800025f2 <setkilled>:

void setkilled(struct proc *p)
{
    800025f2:	1101                	addi	sp,sp,-32
    800025f4:	ec06                	sd	ra,24(sp)
    800025f6:	e822                	sd	s0,16(sp)
    800025f8:	e426                	sd	s1,8(sp)
    800025fa:	1000                	addi	s0,sp,32
    800025fc:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	5d8080e7          	jalr	1496(ra) # 80000bd6 <acquire>
    p->killed = 1;
    80002606:	4785                	li	a5,1
    80002608:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    8000260a:	8526                	mv	a0,s1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	67e080e7          	jalr	1662(ra) # 80000c8a <release>
}
    80002614:	60e2                	ld	ra,24(sp)
    80002616:	6442                	ld	s0,16(sp)
    80002618:	64a2                	ld	s1,8(sp)
    8000261a:	6105                	addi	sp,sp,32
    8000261c:	8082                	ret

000000008000261e <killed>:

int killed(struct proc *p)
{
    8000261e:	1101                	addi	sp,sp,-32
    80002620:	ec06                	sd	ra,24(sp)
    80002622:	e822                	sd	s0,16(sp)
    80002624:	e426                	sd	s1,8(sp)
    80002626:	e04a                	sd	s2,0(sp)
    80002628:	1000                	addi	s0,sp,32
    8000262a:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	5aa080e7          	jalr	1450(ra) # 80000bd6 <acquire>
    k = p->killed;
    80002634:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	650080e7          	jalr	1616(ra) # 80000c8a <release>
    return k;
}
    80002642:	854a                	mv	a0,s2
    80002644:	60e2                	ld	ra,24(sp)
    80002646:	6442                	ld	s0,16(sp)
    80002648:	64a2                	ld	s1,8(sp)
    8000264a:	6902                	ld	s2,0(sp)
    8000264c:	6105                	addi	sp,sp,32
    8000264e:	8082                	ret

0000000080002650 <wait>:
{
    80002650:	715d                	addi	sp,sp,-80
    80002652:	e486                	sd	ra,72(sp)
    80002654:	e0a2                	sd	s0,64(sp)
    80002656:	fc26                	sd	s1,56(sp)
    80002658:	f84a                	sd	s2,48(sp)
    8000265a:	f44e                	sd	s3,40(sp)
    8000265c:	f052                	sd	s4,32(sp)
    8000265e:	ec56                	sd	s5,24(sp)
    80002660:	e85a                	sd	s6,16(sp)
    80002662:	e45e                	sd	s7,8(sp)
    80002664:	e062                	sd	s8,0(sp)
    80002666:	0880                	addi	s0,sp,80
    80002668:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	54c080e7          	jalr	1356(ra) # 80001bb6 <myproc>
    80002672:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002674:	0000f517          	auipc	a0,0xf
    80002678:	a3450513          	addi	a0,a0,-1484 # 800110a8 <wait_lock>
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	55a080e7          	jalr	1370(ra) # 80000bd6 <acquire>
        havekids = 0;
    80002684:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002686:	4a15                	li	s4,5
                havekids = 1;
    80002688:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000268a:	00014997          	auipc	s3,0x14
    8000268e:	63698993          	addi	s3,s3,1590 # 80016cc0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002692:	0000fc17          	auipc	s8,0xf
    80002696:	a16c0c13          	addi	s8,s8,-1514 # 800110a8 <wait_lock>
        havekids = 0;
    8000269a:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000269c:	0000f497          	auipc	s1,0xf
    800026a0:	a2448493          	addi	s1,s1,-1500 # 800110c0 <proc>
    800026a4:	a0bd                	j	80002712 <wait+0xc2>
                    pid = pp->pid;
    800026a6:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026aa:	000b0e63          	beqz	s6,800026c6 <wait+0x76>
    800026ae:	4691                	li	a3,4
    800026b0:	02c48613          	addi	a2,s1,44
    800026b4:	85da                	mv	a1,s6
    800026b6:	05893503          	ld	a0,88(s2)
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	fb2080e7          	jalr	-78(ra) # 8000166c <copyout>
    800026c2:	02054563          	bltz	a0,800026ec <wait+0x9c>
                    freeproc(pp);
    800026c6:	8526                	mv	a0,s1
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	6a0080e7          	jalr	1696(ra) # 80001d68 <freeproc>
                    release(&pp->lock);
    800026d0:	8526                	mv	a0,s1
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	5b8080e7          	jalr	1464(ra) # 80000c8a <release>
                    release(&wait_lock);
    800026da:	0000f517          	auipc	a0,0xf
    800026de:	9ce50513          	addi	a0,a0,-1586 # 800110a8 <wait_lock>
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	5a8080e7          	jalr	1448(ra) # 80000c8a <release>
                    return pid;
    800026ea:	a0b5                	j	80002756 <wait+0x106>
                        release(&pp->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	59c080e7          	jalr	1436(ra) # 80000c8a <release>
                        release(&wait_lock);
    800026f6:	0000f517          	auipc	a0,0xf
    800026fa:	9b250513          	addi	a0,a0,-1614 # 800110a8 <wait_lock>
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	58c080e7          	jalr	1420(ra) # 80000c8a <release>
                        return -1;
    80002706:	59fd                	li	s3,-1
    80002708:	a0b9                	j	80002756 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000270a:	17048493          	addi	s1,s1,368
    8000270e:	03348463          	beq	s1,s3,80002736 <wait+0xe6>
            if (pp->parent == p)
    80002712:	60bc                	ld	a5,64(s1)
    80002714:	ff279be3          	bne	a5,s2,8000270a <wait+0xba>
                acquire(&pp->lock);
    80002718:	8526                	mv	a0,s1
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	4bc080e7          	jalr	1212(ra) # 80000bd6 <acquire>
                if (pp->state == ZOMBIE)
    80002722:	4c9c                	lw	a5,24(s1)
    80002724:	f94781e3          	beq	a5,s4,800026a6 <wait+0x56>
                release(&pp->lock);
    80002728:	8526                	mv	a0,s1
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	560080e7          	jalr	1376(ra) # 80000c8a <release>
                havekids = 1;
    80002732:	8756                	mv	a4,s5
    80002734:	bfd9                	j	8000270a <wait+0xba>
        if (!havekids || killed(p))
    80002736:	c719                	beqz	a4,80002744 <wait+0xf4>
    80002738:	854a                	mv	a0,s2
    8000273a:	00000097          	auipc	ra,0x0
    8000273e:	ee4080e7          	jalr	-284(ra) # 8000261e <killed>
    80002742:	c51d                	beqz	a0,80002770 <wait+0x120>
            release(&wait_lock);
    80002744:	0000f517          	auipc	a0,0xf
    80002748:	96450513          	addi	a0,a0,-1692 # 800110a8 <wait_lock>
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	53e080e7          	jalr	1342(ra) # 80000c8a <release>
            return -1;
    80002754:	59fd                	li	s3,-1
}
    80002756:	854e                	mv	a0,s3
    80002758:	60a6                	ld	ra,72(sp)
    8000275a:	6406                	ld	s0,64(sp)
    8000275c:	74e2                	ld	s1,56(sp)
    8000275e:	7942                	ld	s2,48(sp)
    80002760:	79a2                	ld	s3,40(sp)
    80002762:	7a02                	ld	s4,32(sp)
    80002764:	6ae2                	ld	s5,24(sp)
    80002766:	6b42                	ld	s6,16(sp)
    80002768:	6ba2                	ld	s7,8(sp)
    8000276a:	6c02                	ld	s8,0(sp)
    8000276c:	6161                	addi	sp,sp,80
    8000276e:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002770:	85e2                	mv	a1,s8
    80002772:	854a                	mv	a0,s2
    80002774:	00000097          	auipc	ra,0x0
    80002778:	c02080e7          	jalr	-1022(ra) # 80002376 <sleep>
        havekids = 0;
    8000277c:	bf39                	j	8000269a <wait+0x4a>

000000008000277e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000277e:	7179                	addi	sp,sp,-48
    80002780:	f406                	sd	ra,40(sp)
    80002782:	f022                	sd	s0,32(sp)
    80002784:	ec26                	sd	s1,24(sp)
    80002786:	e84a                	sd	s2,16(sp)
    80002788:	e44e                	sd	s3,8(sp)
    8000278a:	e052                	sd	s4,0(sp)
    8000278c:	1800                	addi	s0,sp,48
    8000278e:	84aa                	mv	s1,a0
    80002790:	892e                	mv	s2,a1
    80002792:	89b2                	mv	s3,a2
    80002794:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	420080e7          	jalr	1056(ra) # 80001bb6 <myproc>
    if (user_dst)
    8000279e:	c08d                	beqz	s1,800027c0 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800027a0:	86d2                	mv	a3,s4
    800027a2:	864e                	mv	a2,s3
    800027a4:	85ca                	mv	a1,s2
    800027a6:	6d28                	ld	a0,88(a0)
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	ec4080e7          	jalr	-316(ra) # 8000166c <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    800027b0:	70a2                	ld	ra,40(sp)
    800027b2:	7402                	ld	s0,32(sp)
    800027b4:	64e2                	ld	s1,24(sp)
    800027b6:	6942                	ld	s2,16(sp)
    800027b8:	69a2                	ld	s3,8(sp)
    800027ba:	6a02                	ld	s4,0(sp)
    800027bc:	6145                	addi	sp,sp,48
    800027be:	8082                	ret
        memmove((char *)dst, src, len);
    800027c0:	000a061b          	sext.w	a2,s4
    800027c4:	85ce                	mv	a1,s3
    800027c6:	854a                	mv	a0,s2
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	566080e7          	jalr	1382(ra) # 80000d2e <memmove>
        return 0;
    800027d0:	8526                	mv	a0,s1
    800027d2:	bff9                	j	800027b0 <either_copyout+0x32>

00000000800027d4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027d4:	7179                	addi	sp,sp,-48
    800027d6:	f406                	sd	ra,40(sp)
    800027d8:	f022                	sd	s0,32(sp)
    800027da:	ec26                	sd	s1,24(sp)
    800027dc:	e84a                	sd	s2,16(sp)
    800027de:	e44e                	sd	s3,8(sp)
    800027e0:	e052                	sd	s4,0(sp)
    800027e2:	1800                	addi	s0,sp,48
    800027e4:	892a                	mv	s2,a0
    800027e6:	84ae                	mv	s1,a1
    800027e8:	89b2                	mv	s3,a2
    800027ea:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	3ca080e7          	jalr	970(ra) # 80001bb6 <myproc>
    if (user_src)
    800027f4:	c08d                	beqz	s1,80002816 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800027f6:	86d2                	mv	a3,s4
    800027f8:	864e                	mv	a2,s3
    800027fa:	85ca                	mv	a1,s2
    800027fc:	6d28                	ld	a0,88(a0)
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	efa080e7          	jalr	-262(ra) # 800016f8 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002806:	70a2                	ld	ra,40(sp)
    80002808:	7402                	ld	s0,32(sp)
    8000280a:	64e2                	ld	s1,24(sp)
    8000280c:	6942                	ld	s2,16(sp)
    8000280e:	69a2                	ld	s3,8(sp)
    80002810:	6a02                	ld	s4,0(sp)
    80002812:	6145                	addi	sp,sp,48
    80002814:	8082                	ret
        memmove(dst, (char *)src, len);
    80002816:	000a061b          	sext.w	a2,s4
    8000281a:	85ce                	mv	a1,s3
    8000281c:	854a                	mv	a0,s2
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	510080e7          	jalr	1296(ra) # 80000d2e <memmove>
        return 0;
    80002826:	8526                	mv	a0,s1
    80002828:	bff9                	j	80002806 <either_copyin+0x32>

000000008000282a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000282a:	715d                	addi	sp,sp,-80
    8000282c:	e486                	sd	ra,72(sp)
    8000282e:	e0a2                	sd	s0,64(sp)
    80002830:	fc26                	sd	s1,56(sp)
    80002832:	f84a                	sd	s2,48(sp)
    80002834:	f44e                	sd	s3,40(sp)
    80002836:	f052                	sd	s4,32(sp)
    80002838:	ec56                	sd	s5,24(sp)
    8000283a:	e85a                	sd	s6,16(sp)
    8000283c:	e45e                	sd	s7,8(sp)
    8000283e:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002840:	00006517          	auipc	a0,0x6
    80002844:	88850513          	addi	a0,a0,-1912 # 800080c8 <digits+0x88>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d42080e7          	jalr	-702(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002850:	0000f497          	auipc	s1,0xf
    80002854:	9d048493          	addi	s1,s1,-1584 # 80011220 <proc+0x160>
    80002858:	00014917          	auipc	s2,0x14
    8000285c:	5c890913          	addi	s2,s2,1480 # 80016e20 <bcache+0x148>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002860:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002862:	00006997          	auipc	s3,0x6
    80002866:	a1e98993          	addi	s3,s3,-1506 # 80008280 <digits+0x240>
        printf("%d <%s %s", p->pid, state, p->name);
    8000286a:	00006a97          	auipc	s5,0x6
    8000286e:	a1ea8a93          	addi	s5,s5,-1506 # 80008288 <digits+0x248>
        printf("\n");
    80002872:	00006a17          	auipc	s4,0x6
    80002876:	856a0a13          	addi	s4,s4,-1962 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287a:	00006b97          	auipc	s7,0x6
    8000287e:	b1eb8b93          	addi	s7,s7,-1250 # 80008398 <states.0>
    80002882:	a00d                	j	800028a4 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002884:	ed06a583          	lw	a1,-304(a3)
    80002888:	8556                	mv	a0,s5
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	d00080e7          	jalr	-768(ra) # 8000058a <printf>
        printf("\n");
    80002892:	8552                	mv	a0,s4
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	cf6080e7          	jalr	-778(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000289c:	17048493          	addi	s1,s1,368
    800028a0:	03248263          	beq	s1,s2,800028c4 <procdump+0x9a>
        if (p->state == UNUSED)
    800028a4:	86a6                	mv	a3,s1
    800028a6:	eb84a783          	lw	a5,-328(s1)
    800028aa:	dbed                	beqz	a5,8000289c <procdump+0x72>
            state = "???";
    800028ac:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ae:	fcfb6be3          	bltu	s6,a5,80002884 <procdump+0x5a>
    800028b2:	02079713          	slli	a4,a5,0x20
    800028b6:	01d75793          	srli	a5,a4,0x1d
    800028ba:	97de                	add	a5,a5,s7
    800028bc:	6390                	ld	a2,0(a5)
    800028be:	f279                	bnez	a2,80002884 <procdump+0x5a>
            state = "???";
    800028c0:	864e                	mv	a2,s3
    800028c2:	b7c9                	j	80002884 <procdump+0x5a>
    }
}
    800028c4:	60a6                	ld	ra,72(sp)
    800028c6:	6406                	ld	s0,64(sp)
    800028c8:	74e2                	ld	s1,56(sp)
    800028ca:	7942                	ld	s2,48(sp)
    800028cc:	79a2                	ld	s3,40(sp)
    800028ce:	7a02                	ld	s4,32(sp)
    800028d0:	6ae2                	ld	s5,24(sp)
    800028d2:	6b42                	ld	s6,16(sp)
    800028d4:	6ba2                	ld	s7,8(sp)
    800028d6:	6161                	addi	sp,sp,80
    800028d8:	8082                	ret

00000000800028da <schedls>:

void schedls()
{
    800028da:	1101                	addi	sp,sp,-32
    800028dc:	ec06                	sd	ra,24(sp)
    800028de:	e822                	sd	s0,16(sp)
    800028e0:	e426                	sd	s1,8(sp)
    800028e2:	1000                	addi	s0,sp,32
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    800028e4:	00006517          	auipc	a0,0x6
    800028e8:	9b450513          	addi	a0,a0,-1612 # 80008298 <digits+0x258>
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	c9e080e7          	jalr	-866(ra) # 8000058a <printf>
    printf("====================================\n");
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	9cc50513          	addi	a0,a0,-1588 # 800082c0 <digits+0x280>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	c8e080e7          	jalr	-882(ra) # 8000058a <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002904:	00006717          	auipc	a4,0x6
    80002908:	09473703          	ld	a4,148(a4) # 80008998 <available_schedulers+0x10>
    8000290c:	00006797          	auipc	a5,0x6
    80002910:	02c7b783          	ld	a5,44(a5) # 80008938 <sched_pointer>
    80002914:	08f70763          	beq	a4,a5,800029a2 <schedls+0xc8>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002918:	00006517          	auipc	a0,0x6
    8000291c:	9d050513          	addi	a0,a0,-1584 # 800082e8 <digits+0x2a8>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	c6a080e7          	jalr	-918(ra) # 8000058a <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002928:	00006497          	auipc	s1,0x6
    8000292c:	02848493          	addi	s1,s1,40 # 80008950 <initcode>
    80002930:	48b0                	lw	a2,80(s1)
    80002932:	00006597          	auipc	a1,0x6
    80002936:	05658593          	addi	a1,a1,86 # 80008988 <available_schedulers>
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	9be50513          	addi	a0,a0,-1602 # 800082f8 <digits+0x2b8>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	c48080e7          	jalr	-952(ra) # 8000058a <printf>
        if (available_schedulers[i].impl == sched_pointer)
    8000294a:	74b8                	ld	a4,104(s1)
    8000294c:	00006797          	auipc	a5,0x6
    80002950:	fec7b783          	ld	a5,-20(a5) # 80008938 <sched_pointer>
    80002954:	06f70063          	beq	a4,a5,800029b4 <schedls+0xda>
            printf("   \t");
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	99050513          	addi	a0,a0,-1648 # 800082e8 <digits+0x2a8>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c2a080e7          	jalr	-982(ra) # 8000058a <printf>
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002968:	00006617          	auipc	a2,0x6
    8000296c:	05862603          	lw	a2,88(a2) # 800089c0 <available_schedulers+0x38>
    80002970:	00006597          	auipc	a1,0x6
    80002974:	03858593          	addi	a1,a1,56 # 800089a8 <available_schedulers+0x20>
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	98050513          	addi	a0,a0,-1664 # 800082f8 <digits+0x2b8>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c0a080e7          	jalr	-1014(ra) # 8000058a <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	97850513          	addi	a0,a0,-1672 # 80008300 <digits+0x2c0>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	bfa080e7          	jalr	-1030(ra) # 8000058a <printf>
}
    80002998:	60e2                	ld	ra,24(sp)
    8000299a:	6442                	ld	s0,16(sp)
    8000299c:	64a2                	ld	s1,8(sp)
    8000299e:	6105                	addi	sp,sp,32
    800029a0:	8082                	ret
            printf("[*]\t");
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	94e50513          	addi	a0,a0,-1714 # 800082f0 <digits+0x2b0>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	be0080e7          	jalr	-1056(ra) # 8000058a <printf>
    800029b2:	bf9d                	j	80002928 <schedls+0x4e>
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	93c50513          	addi	a0,a0,-1732 # 800082f0 <digits+0x2b0>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bce080e7          	jalr	-1074(ra) # 8000058a <printf>
    800029c4:	b755                	j	80002968 <schedls+0x8e>

00000000800029c6 <schedset>:

void schedset(int id)
{
    800029c6:	1141                	addi	sp,sp,-16
    800029c8:	e406                	sd	ra,8(sp)
    800029ca:	e022                	sd	s0,0(sp)
    800029cc:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800029ce:	4705                	li	a4,1
    800029d0:	02a76f63          	bltu	a4,a0,80002a0e <schedset+0x48>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800029d4:	00551793          	slli	a5,a0,0x5
    800029d8:	00006717          	auipc	a4,0x6
    800029dc:	f7870713          	addi	a4,a4,-136 # 80008950 <initcode>
    800029e0:	973e                	add	a4,a4,a5
    800029e2:	6738                	ld	a4,72(a4)
    800029e4:	00006697          	auipc	a3,0x6
    800029e8:	f4e6ba23          	sd	a4,-172(a3) # 80008938 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800029ec:	00006597          	auipc	a1,0x6
    800029f0:	f9c58593          	addi	a1,a1,-100 # 80008988 <available_schedulers>
    800029f4:	95be                	add	a1,a1,a5
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	94a50513          	addi	a0,a0,-1718 # 80008340 <digits+0x300>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b8c080e7          	jalr	-1140(ra) # 8000058a <printf>
    80002a06:	60a2                	ld	ra,8(sp)
    80002a08:	6402                	ld	s0,0(sp)
    80002a0a:	0141                	addi	sp,sp,16
    80002a0c:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	90a50513          	addi	a0,a0,-1782 # 80008318 <digits+0x2d8>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b74080e7          	jalr	-1164(ra) # 8000058a <printf>
        return;
    80002a1e:	b7e5                	j	80002a06 <schedset+0x40>

0000000080002a20 <swtch>:
    80002a20:	00153023          	sd	ra,0(a0)
    80002a24:	00253423          	sd	sp,8(a0)
    80002a28:	e900                	sd	s0,16(a0)
    80002a2a:	ed04                	sd	s1,24(a0)
    80002a2c:	03253023          	sd	s2,32(a0)
    80002a30:	03353423          	sd	s3,40(a0)
    80002a34:	03453823          	sd	s4,48(a0)
    80002a38:	03553c23          	sd	s5,56(a0)
    80002a3c:	05653023          	sd	s6,64(a0)
    80002a40:	05753423          	sd	s7,72(a0)
    80002a44:	05853823          	sd	s8,80(a0)
    80002a48:	05953c23          	sd	s9,88(a0)
    80002a4c:	07a53023          	sd	s10,96(a0)
    80002a50:	07b53423          	sd	s11,104(a0)
    80002a54:	0005b083          	ld	ra,0(a1)
    80002a58:	0085b103          	ld	sp,8(a1)
    80002a5c:	6980                	ld	s0,16(a1)
    80002a5e:	6d84                	ld	s1,24(a1)
    80002a60:	0205b903          	ld	s2,32(a1)
    80002a64:	0285b983          	ld	s3,40(a1)
    80002a68:	0305ba03          	ld	s4,48(a1)
    80002a6c:	0385ba83          	ld	s5,56(a1)
    80002a70:	0405bb03          	ld	s6,64(a1)
    80002a74:	0485bb83          	ld	s7,72(a1)
    80002a78:	0505bc03          	ld	s8,80(a1)
    80002a7c:	0585bc83          	ld	s9,88(a1)
    80002a80:	0605bd03          	ld	s10,96(a1)
    80002a84:	0685bd83          	ld	s11,104(a1)
    80002a88:	8082                	ret

0000000080002a8a <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002a8a:	1141                	addi	sp,sp,-16
    80002a8c:	e406                	sd	ra,8(sp)
    80002a8e:	e022                	sd	s0,0(sp)
    80002a90:	0800                	addi	s0,sp,16
    initlock(&tickslock, "time");
    80002a92:	00006597          	auipc	a1,0x6
    80002a96:	93658593          	addi	a1,a1,-1738 # 800083c8 <states.0+0x30>
    80002a9a:	00014517          	auipc	a0,0x14
    80002a9e:	22650513          	addi	a0,a0,550 # 80016cc0 <tickslock>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	0a4080e7          	jalr	164(ra) # 80000b46 <initlock>
}
    80002aaa:	60a2                	ld	ra,8(sp)
    80002aac:	6402                	ld	s0,0(sp)
    80002aae:	0141                	addi	sp,sp,16
    80002ab0:	8082                	ret

0000000080002ab2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002ab2:	1141                	addi	sp,sp,-16
    80002ab4:	e422                	sd	s0,8(sp)
    80002ab6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ab8:	00003797          	auipc	a5,0x3
    80002abc:	57878793          	addi	a5,a5,1400 # 80006030 <kernelvec>
    80002ac0:	10579073          	csrw	stvec,a5
    w_stvec((uint64)kernelvec);
}
    80002ac4:	6422                	ld	s0,8(sp)
    80002ac6:	0141                	addi	sp,sp,16
    80002ac8:	8082                	ret

0000000080002aca <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002aca:	1141                	addi	sp,sp,-16
    80002acc:	e406                	sd	ra,8(sp)
    80002ace:	e022                	sd	s0,0(sp)
    80002ad0:	0800                	addi	s0,sp,16
    struct proc *p = myproc();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	0e4080e7          	jalr	228(ra) # 80001bb6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ada:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ade:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae0:	10079073          	csrw	sstatus,a5
    // kerneltrap() to usertrap(), so turn off interrupts until
    // we're back in user space, where usertrap() is correct.
    intr_off();

    // send syscalls, interrupts, and exceptions to uservec in trampoline.S
    uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ae4:	00004697          	auipc	a3,0x4
    80002ae8:	51c68693          	addi	a3,a3,1308 # 80007000 <_trampoline>
    80002aec:	00004717          	auipc	a4,0x4
    80002af0:	51470713          	addi	a4,a4,1300 # 80007000 <_trampoline>
    80002af4:	8f15                	sub	a4,a4,a3
    80002af6:	040007b7          	lui	a5,0x4000
    80002afa:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002afc:	07b2                	slli	a5,a5,0xc
    80002afe:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b00:	10571073          	csrw	stvec,a4
    w_stvec(trampoline_uservec);

    // set up trapframe values that uservec will need when
    // the process next traps into the kernel.
    p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b04:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b06:	18002673          	csrr	a2,satp
    80002b0a:	e310                	sd	a2,0(a4)
    p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b0c:	7130                	ld	a2,96(a0)
    80002b0e:	6538                	ld	a4,72(a0)
    80002b10:	6585                	lui	a1,0x1
    80002b12:	972e                	add	a4,a4,a1
    80002b14:	e618                	sd	a4,8(a2)
    p->trapframe->kernel_trap = (uint64)usertrap;
    80002b16:	7138                	ld	a4,96(a0)
    80002b18:	00000617          	auipc	a2,0x0
    80002b1c:	13060613          	addi	a2,a2,304 # 80002c48 <usertrap>
    80002b20:	eb10                	sd	a2,16(a4)
    p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b22:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b24:	8612                	mv	a2,tp
    80002b26:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b28:	10002773          	csrr	a4,sstatus
    // set up the registers that trampoline.S's sret will use
    // to get to user space.

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b2c:	eff77713          	andi	a4,a4,-257
    x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b30:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b34:	10071073          	csrw	sstatus,a4
    w_sstatus(x);

    // set S Exception Program Counter to the saved user pc.
    w_sepc(p->trapframe->epc);
    80002b38:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b3a:	6f18                	ld	a4,24(a4)
    80002b3c:	14171073          	csrw	sepc,a4

    // tell trampoline.S the user page table to switch to.
    uint64 satp = MAKE_SATP(p->pagetable);
    80002b40:	6d28                	ld	a0,88(a0)
    80002b42:	8131                	srli	a0,a0,0xc

    // jump to userret in trampoline.S at the top of memory, which
    // switches to the user page table, restores user registers,
    // and switches to user mode with sret.
    uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b44:	00004717          	auipc	a4,0x4
    80002b48:	55870713          	addi	a4,a4,1368 # 8000709c <userret>
    80002b4c:	8f15                	sub	a4,a4,a3
    80002b4e:	97ba                	add	a5,a5,a4
    ((void (*)(uint64))trampoline_userret)(satp);
    80002b50:	577d                	li	a4,-1
    80002b52:	177e                	slli	a4,a4,0x3f
    80002b54:	8d59                	or	a0,a0,a4
    80002b56:	9782                	jalr	a5
}
    80002b58:	60a2                	ld	ra,8(sp)
    80002b5a:	6402                	ld	s0,0(sp)
    80002b5c:	0141                	addi	sp,sp,16
    80002b5e:	8082                	ret

0000000080002b60 <clockintr>:
    w_sepc(sepc);
    w_sstatus(sstatus);
}

void clockintr()
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	1000                	addi	s0,sp,32
    acquire(&tickslock);
    80002b6a:	00014497          	auipc	s1,0x14
    80002b6e:	15648493          	addi	s1,s1,342 # 80016cc0 <tickslock>
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	062080e7          	jalr	98(ra) # 80000bd6 <acquire>
    ticks++;
    80002b7c:	00006517          	auipc	a0,0x6
    80002b80:	ea450513          	addi	a0,a0,-348 # 80008a20 <ticks>
    80002b84:	411c                	lw	a5,0(a0)
    80002b86:	2785                	addiw	a5,a5,1
    80002b88:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	850080e7          	jalr	-1968(ra) # 800023da <wakeup>
    release(&tickslock);
    80002b92:	8526                	mv	a0,s1
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	0f6080e7          	jalr	246(ra) # 80000c8a <release>
}
    80002b9c:	60e2                	ld	ra,24(sp)
    80002b9e:	6442                	ld	s0,16(sp)
    80002ba0:	64a2                	ld	s1,8(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret

0000000080002ba6 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002ba6:	1101                	addi	sp,sp,-32
    80002ba8:	ec06                	sd	ra,24(sp)
    80002baa:	e822                	sd	s0,16(sp)
    80002bac:	e426                	sd	s1,8(sp)
    80002bae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb0:	14202773          	csrr	a4,scause
    uint64 scause = r_scause();

    if ((scause & 0x8000000000000000L) &&
    80002bb4:	00074d63          	bltz	a4,80002bce <devintr+0x28>
        if (irq)
            plic_complete(irq);

        return 1;
    }
    else if (scause == 0x8000000000000001L)
    80002bb8:	57fd                	li	a5,-1
    80002bba:	17fe                	slli	a5,a5,0x3f
    80002bbc:	0785                	addi	a5,a5,1

        return 2;
    }
    else
    {
        return 0;
    80002bbe:	4501                	li	a0,0
    else if (scause == 0x8000000000000001L)
    80002bc0:	06f70363          	beq	a4,a5,80002c26 <devintr+0x80>
    }
}
    80002bc4:	60e2                	ld	ra,24(sp)
    80002bc6:	6442                	ld	s0,16(sp)
    80002bc8:	64a2                	ld	s1,8(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret
        (scause & 0xff) == 9)
    80002bce:	0ff77793          	zext.b	a5,a4
    if ((scause & 0x8000000000000000L) &&
    80002bd2:	46a5                	li	a3,9
    80002bd4:	fed792e3          	bne	a5,a3,80002bb8 <devintr+0x12>
        int irq = plic_claim();
    80002bd8:	00003097          	auipc	ra,0x3
    80002bdc:	560080e7          	jalr	1376(ra) # 80006138 <plic_claim>
    80002be0:	84aa                	mv	s1,a0
        if (irq == UART0_IRQ)
    80002be2:	47a9                	li	a5,10
    80002be4:	02f50763          	beq	a0,a5,80002c12 <devintr+0x6c>
        else if (irq == VIRTIO0_IRQ)
    80002be8:	4785                	li	a5,1
    80002bea:	02f50963          	beq	a0,a5,80002c1c <devintr+0x76>
        return 1;
    80002bee:	4505                	li	a0,1
        else if (irq)
    80002bf0:	d8f1                	beqz	s1,80002bc4 <devintr+0x1e>
            printf("unexpected interrupt irq=%d\n", irq);
    80002bf2:	85a6                	mv	a1,s1
    80002bf4:	00005517          	auipc	a0,0x5
    80002bf8:	7dc50513          	addi	a0,a0,2012 # 800083d0 <states.0+0x38>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	98e080e7          	jalr	-1650(ra) # 8000058a <printf>
            plic_complete(irq);
    80002c04:	8526                	mv	a0,s1
    80002c06:	00003097          	auipc	ra,0x3
    80002c0a:	556080e7          	jalr	1366(ra) # 8000615c <plic_complete>
        return 1;
    80002c0e:	4505                	li	a0,1
    80002c10:	bf55                	j	80002bc4 <devintr+0x1e>
            uartintr();
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	d86080e7          	jalr	-634(ra) # 80000998 <uartintr>
    80002c1a:	b7ed                	j	80002c04 <devintr+0x5e>
            virtio_disk_intr();
    80002c1c:	00004097          	auipc	ra,0x4
    80002c20:	a08080e7          	jalr	-1528(ra) # 80006624 <virtio_disk_intr>
    80002c24:	b7c5                	j	80002c04 <devintr+0x5e>
        if (cpuid() == 0)
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	f64080e7          	jalr	-156(ra) # 80001b8a <cpuid>
    80002c2e:	c901                	beqz	a0,80002c3e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c30:	144027f3          	csrr	a5,sip
        w_sip(r_sip() & ~2);
    80002c34:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c36:	14479073          	csrw	sip,a5
        return 2;
    80002c3a:	4509                	li	a0,2
    80002c3c:	b761                	j	80002bc4 <devintr+0x1e>
            clockintr();
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	f22080e7          	jalr	-222(ra) # 80002b60 <clockintr>
    80002c46:	b7ed                	j	80002c30 <devintr+0x8a>

0000000080002c48 <usertrap>:
{
    80002c48:	1101                	addi	sp,sp,-32
    80002c4a:	ec06                	sd	ra,24(sp)
    80002c4c:	e822                	sd	s0,16(sp)
    80002c4e:	e426                	sd	s1,8(sp)
    80002c50:	e04a                	sd	s2,0(sp)
    80002c52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c54:	100027f3          	csrr	a5,sstatus
    if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002c58:	1007f793          	andi	a5,a5,256
    80002c5c:	e3b1                	bnez	a5,80002ca0 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c5e:	00003797          	auipc	a5,0x3
    80002c62:	3d278793          	addi	a5,a5,978 # 80006030 <kernelvec>
    80002c66:	10579073          	csrw	stvec,a5
    struct proc *p = myproc();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	f4c080e7          	jalr	-180(ra) # 80001bb6 <myproc>
    80002c72:	84aa                	mv	s1,a0
    p->trapframe->epc = r_sepc();
    80002c74:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c76:	14102773          	csrr	a4,sepc
    80002c7a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c7c:	14202773          	csrr	a4,scause
    if (r_scause() == 8)
    80002c80:	47a1                	li	a5,8
    80002c82:	02f70763          	beq	a4,a5,80002cb0 <usertrap+0x68>
    else if ((which_dev = devintr()) != 0)
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	f20080e7          	jalr	-224(ra) # 80002ba6 <devintr>
    80002c8e:	892a                	mv	s2,a0
    80002c90:	c151                	beqz	a0,80002d14 <usertrap+0xcc>
    if (killed(p))
    80002c92:	8526                	mv	a0,s1
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	98a080e7          	jalr	-1654(ra) # 8000261e <killed>
    80002c9c:	c929                	beqz	a0,80002cee <usertrap+0xa6>
    80002c9e:	a099                	j	80002ce4 <usertrap+0x9c>
        panic("usertrap: not from user mode");
    80002ca0:	00005517          	auipc	a0,0x5
    80002ca4:	75050513          	addi	a0,a0,1872 # 800083f0 <states.0+0x58>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	898080e7          	jalr	-1896(ra) # 80000540 <panic>
        if (killed(p))
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	96e080e7          	jalr	-1682(ra) # 8000261e <killed>
    80002cb8:	e921                	bnez	a0,80002d08 <usertrap+0xc0>
        p->trapframe->epc += 4;
    80002cba:	70b8                	ld	a4,96(s1)
    80002cbc:	6f1c                	ld	a5,24(a4)
    80002cbe:	0791                	addi	a5,a5,4
    80002cc0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cc6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cca:	10079073          	csrw	sstatus,a5
        syscall();
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	2d8080e7          	jalr	728(ra) # 80002fa6 <syscall>
    if (killed(p))
    80002cd6:	8526                	mv	a0,s1
    80002cd8:	00000097          	auipc	ra,0x0
    80002cdc:	946080e7          	jalr	-1722(ra) # 8000261e <killed>
    80002ce0:	c911                	beqz	a0,80002cf4 <usertrap+0xac>
    80002ce2:	4901                	li	s2,0
        exit(-1);
    80002ce4:	557d                	li	a0,-1
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	7c4080e7          	jalr	1988(ra) # 800024aa <exit>
    if (which_dev == 2)
    80002cee:	4789                	li	a5,2
    80002cf0:	04f90f63          	beq	s2,a5,80002d4e <usertrap+0x106>
    usertrapret();
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	dd6080e7          	jalr	-554(ra) # 80002aca <usertrapret>
}
    80002cfc:	60e2                	ld	ra,24(sp)
    80002cfe:	6442                	ld	s0,16(sp)
    80002d00:	64a2                	ld	s1,8(sp)
    80002d02:	6902                	ld	s2,0(sp)
    80002d04:	6105                	addi	sp,sp,32
    80002d06:	8082                	ret
            exit(-1);
    80002d08:	557d                	li	a0,-1
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	7a0080e7          	jalr	1952(ra) # 800024aa <exit>
    80002d12:	b765                	j	80002cba <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d14:	142025f3          	csrr	a1,scause
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d18:	5890                	lw	a2,48(s1)
    80002d1a:	00005517          	auipc	a0,0x5
    80002d1e:	6f650513          	addi	a0,a0,1782 # 80008410 <states.0+0x78>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	868080e7          	jalr	-1944(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d2a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d2e:	14302673          	csrr	a2,stval
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d32:	00005517          	auipc	a0,0x5
    80002d36:	70e50513          	addi	a0,a0,1806 # 80008440 <states.0+0xa8>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	850080e7          	jalr	-1968(ra) # 8000058a <printf>
        setkilled(p);
    80002d42:	8526                	mv	a0,s1
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	8ae080e7          	jalr	-1874(ra) # 800025f2 <setkilled>
    80002d4c:	b769                	j	80002cd6 <usertrap+0x8e>
        yield(YIELD_TIMER);
    80002d4e:	4505                	li	a0,1
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	5e0080e7          	jalr	1504(ra) # 80002330 <yield>
    80002d58:	bf71                	j	80002cf4 <usertrap+0xac>

0000000080002d5a <kerneltrap>:
{
    80002d5a:	7179                	addi	sp,sp,-48
    80002d5c:	f406                	sd	ra,40(sp)
    80002d5e:	f022                	sd	s0,32(sp)
    80002d60:	ec26                	sd	s1,24(sp)
    80002d62:	e84a                	sd	s2,16(sp)
    80002d64:	e44e                	sd	s3,8(sp)
    80002d66:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d68:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d6c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d70:	142029f3          	csrr	s3,scause
    if ((sstatus & SSTATUS_SPP) == 0)
    80002d74:	1004f793          	andi	a5,s1,256
    80002d78:	cb85                	beqz	a5,80002da8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d7a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d7e:	8b89                	andi	a5,a5,2
    if (intr_get() != 0)
    80002d80:	ef85                	bnez	a5,80002db8 <kerneltrap+0x5e>
    if ((which_dev = devintr()) == 0)
    80002d82:	00000097          	auipc	ra,0x0
    80002d86:	e24080e7          	jalr	-476(ra) # 80002ba6 <devintr>
    80002d8a:	cd1d                	beqz	a0,80002dc8 <kerneltrap+0x6e>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d8c:	4789                	li	a5,2
    80002d8e:	06f50a63          	beq	a0,a5,80002e02 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d92:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d96:	10049073          	csrw	sstatus,s1
}
    80002d9a:	70a2                	ld	ra,40(sp)
    80002d9c:	7402                	ld	s0,32(sp)
    80002d9e:	64e2                	ld	s1,24(sp)
    80002da0:	6942                	ld	s2,16(sp)
    80002da2:	69a2                	ld	s3,8(sp)
    80002da4:	6145                	addi	sp,sp,48
    80002da6:	8082                	ret
        panic("kerneltrap: not from supervisor mode");
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	6b850513          	addi	a0,a0,1720 # 80008460 <states.0+0xc8>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	790080e7          	jalr	1936(ra) # 80000540 <panic>
        panic("kerneltrap: interrupts enabled");
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	6d050513          	addi	a0,a0,1744 # 80008488 <states.0+0xf0>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	780080e7          	jalr	1920(ra) # 80000540 <panic>
        printf("scause %p\n", scause);
    80002dc8:	85ce                	mv	a1,s3
    80002dca:	00005517          	auipc	a0,0x5
    80002dce:	6de50513          	addi	a0,a0,1758 # 800084a8 <states.0+0x110>
    80002dd2:	ffffd097          	auipc	ra,0xffffd
    80002dd6:	7b8080e7          	jalr	1976(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dda:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dde:	14302673          	csrr	a2,stval
        printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	6d650513          	addi	a0,a0,1750 # 800084b8 <states.0+0x120>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	7a0080e7          	jalr	1952(ra) # 8000058a <printf>
        panic("kerneltrap");
    80002df2:	00005517          	auipc	a0,0x5
    80002df6:	6de50513          	addi	a0,a0,1758 # 800084d0 <states.0+0x138>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	746080e7          	jalr	1862(ra) # 80000540 <panic>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	db4080e7          	jalr	-588(ra) # 80001bb6 <myproc>
    80002e0a:	d541                	beqz	a0,80002d92 <kerneltrap+0x38>
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	daa080e7          	jalr	-598(ra) # 80001bb6 <myproc>
    80002e14:	4d18                	lw	a4,24(a0)
    80002e16:	4791                	li	a5,4
    80002e18:	f6f71de3          	bne	a4,a5,80002d92 <kerneltrap+0x38>
        yield(YIELD_OTHER);
    80002e1c:	4509                	li	a0,2
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	512080e7          	jalr	1298(ra) # 80002330 <yield>
    80002e26:	b7b5                	j	80002d92 <kerneltrap+0x38>

0000000080002e28 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	e426                	sd	s1,8(sp)
    80002e30:	1000                	addi	s0,sp,32
    80002e32:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	d82080e7          	jalr	-638(ra) # 80001bb6 <myproc>
    switch (n)
    80002e3c:	4795                	li	a5,5
    80002e3e:	0497e163          	bltu	a5,s1,80002e80 <argraw+0x58>
    80002e42:	048a                	slli	s1,s1,0x2
    80002e44:	00005717          	auipc	a4,0x5
    80002e48:	6c470713          	addi	a4,a4,1732 # 80008508 <states.0+0x170>
    80002e4c:	94ba                	add	s1,s1,a4
    80002e4e:	409c                	lw	a5,0(s1)
    80002e50:	97ba                	add	a5,a5,a4
    80002e52:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002e54:	713c                	ld	a5,96(a0)
    80002e56:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	64a2                	ld	s1,8(sp)
    80002e5e:	6105                	addi	sp,sp,32
    80002e60:	8082                	ret
        return p->trapframe->a1;
    80002e62:	713c                	ld	a5,96(a0)
    80002e64:	7fa8                	ld	a0,120(a5)
    80002e66:	bfcd                	j	80002e58 <argraw+0x30>
        return p->trapframe->a2;
    80002e68:	713c                	ld	a5,96(a0)
    80002e6a:	63c8                	ld	a0,128(a5)
    80002e6c:	b7f5                	j	80002e58 <argraw+0x30>
        return p->trapframe->a3;
    80002e6e:	713c                	ld	a5,96(a0)
    80002e70:	67c8                	ld	a0,136(a5)
    80002e72:	b7dd                	j	80002e58 <argraw+0x30>
        return p->trapframe->a4;
    80002e74:	713c                	ld	a5,96(a0)
    80002e76:	6bc8                	ld	a0,144(a5)
    80002e78:	b7c5                	j	80002e58 <argraw+0x30>
        return p->trapframe->a5;
    80002e7a:	713c                	ld	a5,96(a0)
    80002e7c:	6fc8                	ld	a0,152(a5)
    80002e7e:	bfe9                	j	80002e58 <argraw+0x30>
    panic("argraw");
    80002e80:	00005517          	auipc	a0,0x5
    80002e84:	66050513          	addi	a0,a0,1632 # 800084e0 <states.0+0x148>
    80002e88:	ffffd097          	auipc	ra,0xffffd
    80002e8c:	6b8080e7          	jalr	1720(ra) # 80000540 <panic>

0000000080002e90 <fetchaddr>:
{
    80002e90:	1101                	addi	sp,sp,-32
    80002e92:	ec06                	sd	ra,24(sp)
    80002e94:	e822                	sd	s0,16(sp)
    80002e96:	e426                	sd	s1,8(sp)
    80002e98:	e04a                	sd	s2,0(sp)
    80002e9a:	1000                	addi	s0,sp,32
    80002e9c:	84aa                	mv	s1,a0
    80002e9e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	d16080e7          	jalr	-746(ra) # 80001bb6 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ea8:	693c                	ld	a5,80(a0)
    80002eaa:	02f4f863          	bgeu	s1,a5,80002eda <fetchaddr+0x4a>
    80002eae:	00848713          	addi	a4,s1,8
    80002eb2:	02e7e663          	bltu	a5,a4,80002ede <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002eb6:	46a1                	li	a3,8
    80002eb8:	8626                	mv	a2,s1
    80002eba:	85ca                	mv	a1,s2
    80002ebc:	6d28                	ld	a0,88(a0)
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	83a080e7          	jalr	-1990(ra) # 800016f8 <copyin>
    80002ec6:	00a03533          	snez	a0,a0
    80002eca:	40a00533          	neg	a0,a0
}
    80002ece:	60e2                	ld	ra,24(sp)
    80002ed0:	6442                	ld	s0,16(sp)
    80002ed2:	64a2                	ld	s1,8(sp)
    80002ed4:	6902                	ld	s2,0(sp)
    80002ed6:	6105                	addi	sp,sp,32
    80002ed8:	8082                	ret
        return -1;
    80002eda:	557d                	li	a0,-1
    80002edc:	bfcd                	j	80002ece <fetchaddr+0x3e>
    80002ede:	557d                	li	a0,-1
    80002ee0:	b7fd                	j	80002ece <fetchaddr+0x3e>

0000000080002ee2 <fetchstr>:
{
    80002ee2:	7179                	addi	sp,sp,-48
    80002ee4:	f406                	sd	ra,40(sp)
    80002ee6:	f022                	sd	s0,32(sp)
    80002ee8:	ec26                	sd	s1,24(sp)
    80002eea:	e84a                	sd	s2,16(sp)
    80002eec:	e44e                	sd	s3,8(sp)
    80002eee:	1800                	addi	s0,sp,48
    80002ef0:	892a                	mv	s2,a0
    80002ef2:	84ae                	mv	s1,a1
    80002ef4:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	cc0080e7          	jalr	-832(ra) # 80001bb6 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002efe:	86ce                	mv	a3,s3
    80002f00:	864a                	mv	a2,s2
    80002f02:	85a6                	mv	a1,s1
    80002f04:	6d28                	ld	a0,88(a0)
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	880080e7          	jalr	-1920(ra) # 80001786 <copyinstr>
    80002f0e:	00054e63          	bltz	a0,80002f2a <fetchstr+0x48>
    return strlen(buf);
    80002f12:	8526                	mv	a0,s1
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	f3a080e7          	jalr	-198(ra) # 80000e4e <strlen>
}
    80002f1c:	70a2                	ld	ra,40(sp)
    80002f1e:	7402                	ld	s0,32(sp)
    80002f20:	64e2                	ld	s1,24(sp)
    80002f22:	6942                	ld	s2,16(sp)
    80002f24:	69a2                	ld	s3,8(sp)
    80002f26:	6145                	addi	sp,sp,48
    80002f28:	8082                	ret
        return -1;
    80002f2a:	557d                	li	a0,-1
    80002f2c:	bfc5                	j	80002f1c <fetchstr+0x3a>

0000000080002f2e <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002f2e:	1101                	addi	sp,sp,-32
    80002f30:	ec06                	sd	ra,24(sp)
    80002f32:	e822                	sd	s0,16(sp)
    80002f34:	e426                	sd	s1,8(sp)
    80002f36:	1000                	addi	s0,sp,32
    80002f38:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002f3a:	00000097          	auipc	ra,0x0
    80002f3e:	eee080e7          	jalr	-274(ra) # 80002e28 <argraw>
    80002f42:	c088                	sw	a0,0(s1)
}
    80002f44:	60e2                	ld	ra,24(sp)
    80002f46:	6442                	ld	s0,16(sp)
    80002f48:	64a2                	ld	s1,8(sp)
    80002f4a:	6105                	addi	sp,sp,32
    80002f4c:	8082                	ret

0000000080002f4e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002f4e:	1101                	addi	sp,sp,-32
    80002f50:	ec06                	sd	ra,24(sp)
    80002f52:	e822                	sd	s0,16(sp)
    80002f54:	e426                	sd	s1,8(sp)
    80002f56:	1000                	addi	s0,sp,32
    80002f58:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	ece080e7          	jalr	-306(ra) # 80002e28 <argraw>
    80002f62:	e088                	sd	a0,0(s1)
}
    80002f64:	60e2                	ld	ra,24(sp)
    80002f66:	6442                	ld	s0,16(sp)
    80002f68:	64a2                	ld	s1,8(sp)
    80002f6a:	6105                	addi	sp,sp,32
    80002f6c:	8082                	ret

0000000080002f6e <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002f6e:	7179                	addi	sp,sp,-48
    80002f70:	f406                	sd	ra,40(sp)
    80002f72:	f022                	sd	s0,32(sp)
    80002f74:	ec26                	sd	s1,24(sp)
    80002f76:	e84a                	sd	s2,16(sp)
    80002f78:	1800                	addi	s0,sp,48
    80002f7a:	84ae                	mv	s1,a1
    80002f7c:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002f7e:	fd840593          	addi	a1,s0,-40
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	fcc080e7          	jalr	-52(ra) # 80002f4e <argaddr>
    return fetchstr(addr, buf, max);
    80002f8a:	864a                	mv	a2,s2
    80002f8c:	85a6                	mv	a1,s1
    80002f8e:	fd843503          	ld	a0,-40(s0)
    80002f92:	00000097          	auipc	ra,0x0
    80002f96:	f50080e7          	jalr	-176(ra) # 80002ee2 <fetchstr>
}
    80002f9a:	70a2                	ld	ra,40(sp)
    80002f9c:	7402                	ld	s0,32(sp)
    80002f9e:	64e2                	ld	s1,24(sp)
    80002fa0:	6942                	ld	s2,16(sp)
    80002fa2:	6145                	addi	sp,sp,48
    80002fa4:	8082                	ret

0000000080002fa6 <syscall>:
    [SYS_schedset] sys_schedset,
    [SYS_yield] sys_yield,
};

void syscall(void)
{
    80002fa6:	1101                	addi	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	e426                	sd	s1,8(sp)
    80002fae:	e04a                	sd	s2,0(sp)
    80002fb0:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	c04080e7          	jalr	-1020(ra) # 80001bb6 <myproc>
    80002fba:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80002fbc:	06053903          	ld	s2,96(a0)
    80002fc0:	0a893783          	ld	a5,168(s2)
    80002fc4:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002fc8:	37fd                	addiw	a5,a5,-1
    80002fca:	4761                	li	a4,24
    80002fcc:	00f76f63          	bltu	a4,a5,80002fea <syscall+0x44>
    80002fd0:	00369713          	slli	a4,a3,0x3
    80002fd4:	00005797          	auipc	a5,0x5
    80002fd8:	54c78793          	addi	a5,a5,1356 # 80008520 <syscalls>
    80002fdc:	97ba                	add	a5,a5,a4
    80002fde:	639c                	ld	a5,0(a5)
    80002fe0:	c789                	beqz	a5,80002fea <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80002fe2:	9782                	jalr	a5
    80002fe4:	06a93823          	sd	a0,112(s2)
    80002fe8:	a839                	j	80003006 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80002fea:	16048613          	addi	a2,s1,352
    80002fee:	588c                	lw	a1,48(s1)
    80002ff0:	00005517          	auipc	a0,0x5
    80002ff4:	4f850513          	addi	a0,a0,1272 # 800084e8 <states.0+0x150>
    80002ff8:	ffffd097          	auipc	ra,0xffffd
    80002ffc:	592080e7          	jalr	1426(ra) # 8000058a <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80003000:	70bc                	ld	a5,96(s1)
    80003002:	577d                	li	a4,-1
    80003004:	fbb8                	sd	a4,112(a5)
    }
}
    80003006:	60e2                	ld	ra,24(sp)
    80003008:	6442                	ld	s0,16(sp)
    8000300a:	64a2                	ld	s1,8(sp)
    8000300c:	6902                	ld	s2,0(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret

0000000080003012 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003012:	1101                	addi	sp,sp,-32
    80003014:	ec06                	sd	ra,24(sp)
    80003016:	e822                	sd	s0,16(sp)
    80003018:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    8000301a:	fec40593          	addi	a1,s0,-20
    8000301e:	4501                	li	a0,0
    80003020:	00000097          	auipc	ra,0x0
    80003024:	f0e080e7          	jalr	-242(ra) # 80002f2e <argint>
    exit(n);
    80003028:	fec42503          	lw	a0,-20(s0)
    8000302c:	fffff097          	auipc	ra,0xfffff
    80003030:	47e080e7          	jalr	1150(ra) # 800024aa <exit>
    return 0; // not reached
}
    80003034:	4501                	li	a0,0
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000303e:	1141                	addi	sp,sp,-16
    80003040:	e406                	sd	ra,8(sp)
    80003042:	e022                	sd	s0,0(sp)
    80003044:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003046:	fffff097          	auipc	ra,0xfffff
    8000304a:	b70080e7          	jalr	-1168(ra) # 80001bb6 <myproc>
}
    8000304e:	5908                	lw	a0,48(a0)
    80003050:	60a2                	ld	ra,8(sp)
    80003052:	6402                	ld	s0,0(sp)
    80003054:	0141                	addi	sp,sp,16
    80003056:	8082                	ret

0000000080003058 <sys_fork>:

uint64
sys_fork(void)
{
    80003058:	1141                	addi	sp,sp,-16
    8000305a:	e406                	sd	ra,8(sp)
    8000305c:	e022                	sd	s0,0(sp)
    8000305e:	0800                	addi	s0,sp,16
    return fork();
    80003060:	fffff097          	auipc	ra,0xfffff
    80003064:	0aa080e7          	jalr	170(ra) # 8000210a <fork>
}
    80003068:	60a2                	ld	ra,8(sp)
    8000306a:	6402                	ld	s0,0(sp)
    8000306c:	0141                	addi	sp,sp,16
    8000306e:	8082                	ret

0000000080003070 <sys_wait>:

uint64
sys_wait(void)
{
    80003070:	1101                	addi	sp,sp,-32
    80003072:	ec06                	sd	ra,24(sp)
    80003074:	e822                	sd	s0,16(sp)
    80003076:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003078:	fe840593          	addi	a1,s0,-24
    8000307c:	4501                	li	a0,0
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	ed0080e7          	jalr	-304(ra) # 80002f4e <argaddr>
    return wait(p);
    80003086:	fe843503          	ld	a0,-24(s0)
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	5c6080e7          	jalr	1478(ra) # 80002650 <wait>
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret

000000008000309a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000309a:	7179                	addi	sp,sp,-48
    8000309c:	f406                	sd	ra,40(sp)
    8000309e:	f022                	sd	s0,32(sp)
    800030a0:	ec26                	sd	s1,24(sp)
    800030a2:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    800030a4:	fdc40593          	addi	a1,s0,-36
    800030a8:	4501                	li	a0,0
    800030aa:	00000097          	auipc	ra,0x0
    800030ae:	e84080e7          	jalr	-380(ra) # 80002f2e <argint>
    addr = myproc()->sz;
    800030b2:	fffff097          	auipc	ra,0xfffff
    800030b6:	b04080e7          	jalr	-1276(ra) # 80001bb6 <myproc>
    800030ba:	6924                	ld	s1,80(a0)
    if (growproc(n) < 0)
    800030bc:	fdc42503          	lw	a0,-36(s0)
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	e58080e7          	jalr	-424(ra) # 80001f18 <growproc>
    800030c8:	00054863          	bltz	a0,800030d8 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800030cc:	8526                	mv	a0,s1
    800030ce:	70a2                	ld	ra,40(sp)
    800030d0:	7402                	ld	s0,32(sp)
    800030d2:	64e2                	ld	s1,24(sp)
    800030d4:	6145                	addi	sp,sp,48
    800030d6:	8082                	ret
        return -1;
    800030d8:	54fd                	li	s1,-1
    800030da:	bfcd                	j	800030cc <sys_sbrk+0x32>

00000000800030dc <sys_sleep>:

uint64
sys_sleep(void)
{
    800030dc:	7139                	addi	sp,sp,-64
    800030de:	fc06                	sd	ra,56(sp)
    800030e0:	f822                	sd	s0,48(sp)
    800030e2:	f426                	sd	s1,40(sp)
    800030e4:	f04a                	sd	s2,32(sp)
    800030e6:	ec4e                	sd	s3,24(sp)
    800030e8:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800030ea:	fcc40593          	addi	a1,s0,-52
    800030ee:	4501                	li	a0,0
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	e3e080e7          	jalr	-450(ra) # 80002f2e <argint>
    acquire(&tickslock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	bc850513          	addi	a0,a0,-1080 # 80016cc0 <tickslock>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	ad6080e7          	jalr	-1322(ra) # 80000bd6 <acquire>
    ticks0 = ticks;
    80003108:	00006917          	auipc	s2,0x6
    8000310c:	91892903          	lw	s2,-1768(s2) # 80008a20 <ticks>
    while (ticks - ticks0 < n)
    80003110:	fcc42783          	lw	a5,-52(s0)
    80003114:	cf9d                	beqz	a5,80003152 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003116:	00014997          	auipc	s3,0x14
    8000311a:	baa98993          	addi	s3,s3,-1110 # 80016cc0 <tickslock>
    8000311e:	00006497          	auipc	s1,0x6
    80003122:	90248493          	addi	s1,s1,-1790 # 80008a20 <ticks>
        if (killed(myproc()))
    80003126:	fffff097          	auipc	ra,0xfffff
    8000312a:	a90080e7          	jalr	-1392(ra) # 80001bb6 <myproc>
    8000312e:	fffff097          	auipc	ra,0xfffff
    80003132:	4f0080e7          	jalr	1264(ra) # 8000261e <killed>
    80003136:	ed15                	bnez	a0,80003172 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003138:	85ce                	mv	a1,s3
    8000313a:	8526                	mv	a0,s1
    8000313c:	fffff097          	auipc	ra,0xfffff
    80003140:	23a080e7          	jalr	570(ra) # 80002376 <sleep>
    while (ticks - ticks0 < n)
    80003144:	409c                	lw	a5,0(s1)
    80003146:	412787bb          	subw	a5,a5,s2
    8000314a:	fcc42703          	lw	a4,-52(s0)
    8000314e:	fce7ece3          	bltu	a5,a4,80003126 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003152:	00014517          	auipc	a0,0x14
    80003156:	b6e50513          	addi	a0,a0,-1170 # 80016cc0 <tickslock>
    8000315a:	ffffe097          	auipc	ra,0xffffe
    8000315e:	b30080e7          	jalr	-1232(ra) # 80000c8a <release>
    return 0;
    80003162:	4501                	li	a0,0
}
    80003164:	70e2                	ld	ra,56(sp)
    80003166:	7442                	ld	s0,48(sp)
    80003168:	74a2                	ld	s1,40(sp)
    8000316a:	7902                	ld	s2,32(sp)
    8000316c:	69e2                	ld	s3,24(sp)
    8000316e:	6121                	addi	sp,sp,64
    80003170:	8082                	ret
            release(&tickslock);
    80003172:	00014517          	auipc	a0,0x14
    80003176:	b4e50513          	addi	a0,a0,-1202 # 80016cc0 <tickslock>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	b10080e7          	jalr	-1264(ra) # 80000c8a <release>
            return -1;
    80003182:	557d                	li	a0,-1
    80003184:	b7c5                	j	80003164 <sys_sleep+0x88>

0000000080003186 <sys_kill>:

uint64
sys_kill(void)
{
    80003186:	1101                	addi	sp,sp,-32
    80003188:	ec06                	sd	ra,24(sp)
    8000318a:	e822                	sd	s0,16(sp)
    8000318c:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000318e:	fec40593          	addi	a1,s0,-20
    80003192:	4501                	li	a0,0
    80003194:	00000097          	auipc	ra,0x0
    80003198:	d9a080e7          	jalr	-614(ra) # 80002f2e <argint>
    return kill(pid);
    8000319c:	fec42503          	lw	a0,-20(s0)
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	3e0080e7          	jalr	992(ra) # 80002580 <kill>
}
    800031a8:	60e2                	ld	ra,24(sp)
    800031aa:	6442                	ld	s0,16(sp)
    800031ac:	6105                	addi	sp,sp,32
    800031ae:	8082                	ret

00000000800031b0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031b0:	1101                	addi	sp,sp,-32
    800031b2:	ec06                	sd	ra,24(sp)
    800031b4:	e822                	sd	s0,16(sp)
    800031b6:	e426                	sd	s1,8(sp)
    800031b8:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800031ba:	00014517          	auipc	a0,0x14
    800031be:	b0650513          	addi	a0,a0,-1274 # 80016cc0 <tickslock>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	a14080e7          	jalr	-1516(ra) # 80000bd6 <acquire>
    xticks = ticks;
    800031ca:	00006497          	auipc	s1,0x6
    800031ce:	8564a483          	lw	s1,-1962(s1) # 80008a20 <ticks>
    release(&tickslock);
    800031d2:	00014517          	auipc	a0,0x14
    800031d6:	aee50513          	addi	a0,a0,-1298 # 80016cc0 <tickslock>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	ab0080e7          	jalr	-1360(ra) # 80000c8a <release>
    return xticks;
}
    800031e2:	02049513          	slli	a0,s1,0x20
    800031e6:	9101                	srli	a0,a0,0x20
    800031e8:	60e2                	ld	ra,24(sp)
    800031ea:	6442                	ld	s0,16(sp)
    800031ec:	64a2                	ld	s1,8(sp)
    800031ee:	6105                	addi	sp,sp,32
    800031f0:	8082                	ret

00000000800031f2 <sys_ps>:

void *
sys_ps(void)
{
    800031f2:	1101                	addi	sp,sp,-32
    800031f4:	ec06                	sd	ra,24(sp)
    800031f6:	e822                	sd	s0,16(sp)
    800031f8:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800031fa:	fe042623          	sw	zero,-20(s0)
    800031fe:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    80003202:	fec40593          	addi	a1,s0,-20
    80003206:	4501                	li	a0,0
    80003208:	00000097          	auipc	ra,0x0
    8000320c:	d26080e7          	jalr	-730(ra) # 80002f2e <argint>
    argint(1, &count);
    80003210:	fe840593          	addi	a1,s0,-24
    80003214:	4505                	li	a0,1
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	d18080e7          	jalr	-744(ra) # 80002f2e <argint>
    return ps((uint8)start, (uint8)count);
    8000321e:	fe844583          	lbu	a1,-24(s0)
    80003222:	fec44503          	lbu	a0,-20(s0)
    80003226:	fffff097          	auipc	ra,0xfffff
    8000322a:	d4e080e7          	jalr	-690(ra) # 80001f74 <ps>
}
    8000322e:	60e2                	ld	ra,24(sp)
    80003230:	6442                	ld	s0,16(sp)
    80003232:	6105                	addi	sp,sp,32
    80003234:	8082                	ret

0000000080003236 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003236:	1141                	addi	sp,sp,-16
    80003238:	e406                	sd	ra,8(sp)
    8000323a:	e022                	sd	s0,0(sp)
    8000323c:	0800                	addi	s0,sp,16
    schedls();
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	69c080e7          	jalr	1692(ra) # 800028da <schedls>
    return 0;
}
    80003246:	4501                	li	a0,0
    80003248:	60a2                	ld	ra,8(sp)
    8000324a:	6402                	ld	s0,0(sp)
    8000324c:	0141                	addi	sp,sp,16
    8000324e:	8082                	ret

0000000080003250 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003250:	1101                	addi	sp,sp,-32
    80003252:	ec06                	sd	ra,24(sp)
    80003254:	e822                	sd	s0,16(sp)
    80003256:	1000                	addi	s0,sp,32
    int id = 0;
    80003258:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000325c:	fec40593          	addi	a1,s0,-20
    80003260:	4501                	li	a0,0
    80003262:	00000097          	auipc	ra,0x0
    80003266:	ccc080e7          	jalr	-820(ra) # 80002f2e <argint>
    schedset(id - 1);
    8000326a:	fec42503          	lw	a0,-20(s0)
    8000326e:	357d                	addiw	a0,a0,-1
    80003270:	fffff097          	auipc	ra,0xfffff
    80003274:	756080e7          	jalr	1878(ra) # 800029c6 <schedset>
    return 0;
}
    80003278:	4501                	li	a0,0
    8000327a:	60e2                	ld	ra,24(sp)
    8000327c:	6442                	ld	s0,16(sp)
    8000327e:	6105                	addi	sp,sp,32
    80003280:	8082                	ret

0000000080003282 <sys_yield>:

uint64 sys_yield(void)
{
    80003282:	1141                	addi	sp,sp,-16
    80003284:	e406                	sd	ra,8(sp)
    80003286:	e022                	sd	s0,0(sp)
    80003288:	0800                	addi	s0,sp,16
    yield(YIELD_OTHER);
    8000328a:	4509                	li	a0,2
    8000328c:	fffff097          	auipc	ra,0xfffff
    80003290:	0a4080e7          	jalr	164(ra) # 80002330 <yield>
    return 0;
    80003294:	4501                	li	a0,0
    80003296:	60a2                	ld	ra,8(sp)
    80003298:	6402                	ld	s0,0(sp)
    8000329a:	0141                	addi	sp,sp,16
    8000329c:	8082                	ret

000000008000329e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000329e:	7179                	addi	sp,sp,-48
    800032a0:	f406                	sd	ra,40(sp)
    800032a2:	f022                	sd	s0,32(sp)
    800032a4:	ec26                	sd	s1,24(sp)
    800032a6:	e84a                	sd	s2,16(sp)
    800032a8:	e44e                	sd	s3,8(sp)
    800032aa:	e052                	sd	s4,0(sp)
    800032ac:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032ae:	00005597          	auipc	a1,0x5
    800032b2:	34258593          	addi	a1,a1,834 # 800085f0 <syscalls+0xd0>
    800032b6:	00014517          	auipc	a0,0x14
    800032ba:	a2250513          	addi	a0,a0,-1502 # 80016cd8 <bcache>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	888080e7          	jalr	-1912(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032c6:	0001c797          	auipc	a5,0x1c
    800032ca:	a1278793          	addi	a5,a5,-1518 # 8001ecd8 <bcache+0x8000>
    800032ce:	0001c717          	auipc	a4,0x1c
    800032d2:	c7270713          	addi	a4,a4,-910 # 8001ef40 <bcache+0x8268>
    800032d6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032da:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032de:	00014497          	auipc	s1,0x14
    800032e2:	a1248493          	addi	s1,s1,-1518 # 80016cf0 <bcache+0x18>
    b->next = bcache.head.next;
    800032e6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032e8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032ea:	00005a17          	auipc	s4,0x5
    800032ee:	30ea0a13          	addi	s4,s4,782 # 800085f8 <syscalls+0xd8>
    b->next = bcache.head.next;
    800032f2:	2b893783          	ld	a5,696(s2)
    800032f6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032f8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032fc:	85d2                	mv	a1,s4
    800032fe:	01048513          	addi	a0,s1,16
    80003302:	00001097          	auipc	ra,0x1
    80003306:	4c8080e7          	jalr	1224(ra) # 800047ca <initsleeplock>
    bcache.head.next->prev = b;
    8000330a:	2b893783          	ld	a5,696(s2)
    8000330e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003310:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003314:	45848493          	addi	s1,s1,1112
    80003318:	fd349de3          	bne	s1,s3,800032f2 <binit+0x54>
  }
}
    8000331c:	70a2                	ld	ra,40(sp)
    8000331e:	7402                	ld	s0,32(sp)
    80003320:	64e2                	ld	s1,24(sp)
    80003322:	6942                	ld	s2,16(sp)
    80003324:	69a2                	ld	s3,8(sp)
    80003326:	6a02                	ld	s4,0(sp)
    80003328:	6145                	addi	sp,sp,48
    8000332a:	8082                	ret

000000008000332c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000332c:	7179                	addi	sp,sp,-48
    8000332e:	f406                	sd	ra,40(sp)
    80003330:	f022                	sd	s0,32(sp)
    80003332:	ec26                	sd	s1,24(sp)
    80003334:	e84a                	sd	s2,16(sp)
    80003336:	e44e                	sd	s3,8(sp)
    80003338:	1800                	addi	s0,sp,48
    8000333a:	892a                	mv	s2,a0
    8000333c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000333e:	00014517          	auipc	a0,0x14
    80003342:	99a50513          	addi	a0,a0,-1638 # 80016cd8 <bcache>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	890080e7          	jalr	-1904(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000334e:	0001c497          	auipc	s1,0x1c
    80003352:	c424b483          	ld	s1,-958(s1) # 8001ef90 <bcache+0x82b8>
    80003356:	0001c797          	auipc	a5,0x1c
    8000335a:	bea78793          	addi	a5,a5,-1046 # 8001ef40 <bcache+0x8268>
    8000335e:	02f48f63          	beq	s1,a5,8000339c <bread+0x70>
    80003362:	873e                	mv	a4,a5
    80003364:	a021                	j	8000336c <bread+0x40>
    80003366:	68a4                	ld	s1,80(s1)
    80003368:	02e48a63          	beq	s1,a4,8000339c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000336c:	449c                	lw	a5,8(s1)
    8000336e:	ff279ce3          	bne	a5,s2,80003366 <bread+0x3a>
    80003372:	44dc                	lw	a5,12(s1)
    80003374:	ff3799e3          	bne	a5,s3,80003366 <bread+0x3a>
      b->refcnt++;
    80003378:	40bc                	lw	a5,64(s1)
    8000337a:	2785                	addiw	a5,a5,1
    8000337c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000337e:	00014517          	auipc	a0,0x14
    80003382:	95a50513          	addi	a0,a0,-1702 # 80016cd8 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	904080e7          	jalr	-1788(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000338e:	01048513          	addi	a0,s1,16
    80003392:	00001097          	auipc	ra,0x1
    80003396:	472080e7          	jalr	1138(ra) # 80004804 <acquiresleep>
      return b;
    8000339a:	a8b9                	j	800033f8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000339c:	0001c497          	auipc	s1,0x1c
    800033a0:	bec4b483          	ld	s1,-1044(s1) # 8001ef88 <bcache+0x82b0>
    800033a4:	0001c797          	auipc	a5,0x1c
    800033a8:	b9c78793          	addi	a5,a5,-1124 # 8001ef40 <bcache+0x8268>
    800033ac:	00f48863          	beq	s1,a5,800033bc <bread+0x90>
    800033b0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033b2:	40bc                	lw	a5,64(s1)
    800033b4:	cf81                	beqz	a5,800033cc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033b6:	64a4                	ld	s1,72(s1)
    800033b8:	fee49de3          	bne	s1,a4,800033b2 <bread+0x86>
  panic("bget: no buffers");
    800033bc:	00005517          	auipc	a0,0x5
    800033c0:	24450513          	addi	a0,a0,580 # 80008600 <syscalls+0xe0>
    800033c4:	ffffd097          	auipc	ra,0xffffd
    800033c8:	17c080e7          	jalr	380(ra) # 80000540 <panic>
      b->dev = dev;
    800033cc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800033d0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800033d4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033d8:	4785                	li	a5,1
    800033da:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033dc:	00014517          	auipc	a0,0x14
    800033e0:	8fc50513          	addi	a0,a0,-1796 # 80016cd8 <bcache>
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800033ec:	01048513          	addi	a0,s1,16
    800033f0:	00001097          	auipc	ra,0x1
    800033f4:	414080e7          	jalr	1044(ra) # 80004804 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033f8:	409c                	lw	a5,0(s1)
    800033fa:	cb89                	beqz	a5,8000340c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033fc:	8526                	mv	a0,s1
    800033fe:	70a2                	ld	ra,40(sp)
    80003400:	7402                	ld	s0,32(sp)
    80003402:	64e2                	ld	s1,24(sp)
    80003404:	6942                	ld	s2,16(sp)
    80003406:	69a2                	ld	s3,8(sp)
    80003408:	6145                	addi	sp,sp,48
    8000340a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000340c:	4581                	li	a1,0
    8000340e:	8526                	mv	a0,s1
    80003410:	00003097          	auipc	ra,0x3
    80003414:	fe2080e7          	jalr	-30(ra) # 800063f2 <virtio_disk_rw>
    b->valid = 1;
    80003418:	4785                	li	a5,1
    8000341a:	c09c                	sw	a5,0(s1)
  return b;
    8000341c:	b7c5                	j	800033fc <bread+0xd0>

000000008000341e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000341e:	1101                	addi	sp,sp,-32
    80003420:	ec06                	sd	ra,24(sp)
    80003422:	e822                	sd	s0,16(sp)
    80003424:	e426                	sd	s1,8(sp)
    80003426:	1000                	addi	s0,sp,32
    80003428:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000342a:	0541                	addi	a0,a0,16
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	472080e7          	jalr	1138(ra) # 8000489e <holdingsleep>
    80003434:	cd01                	beqz	a0,8000344c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003436:	4585                	li	a1,1
    80003438:	8526                	mv	a0,s1
    8000343a:	00003097          	auipc	ra,0x3
    8000343e:	fb8080e7          	jalr	-72(ra) # 800063f2 <virtio_disk_rw>
}
    80003442:	60e2                	ld	ra,24(sp)
    80003444:	6442                	ld	s0,16(sp)
    80003446:	64a2                	ld	s1,8(sp)
    80003448:	6105                	addi	sp,sp,32
    8000344a:	8082                	ret
    panic("bwrite");
    8000344c:	00005517          	auipc	a0,0x5
    80003450:	1cc50513          	addi	a0,a0,460 # 80008618 <syscalls+0xf8>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	0ec080e7          	jalr	236(ra) # 80000540 <panic>

000000008000345c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000345c:	1101                	addi	sp,sp,-32
    8000345e:	ec06                	sd	ra,24(sp)
    80003460:	e822                	sd	s0,16(sp)
    80003462:	e426                	sd	s1,8(sp)
    80003464:	e04a                	sd	s2,0(sp)
    80003466:	1000                	addi	s0,sp,32
    80003468:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000346a:	01050913          	addi	s2,a0,16
    8000346e:	854a                	mv	a0,s2
    80003470:	00001097          	auipc	ra,0x1
    80003474:	42e080e7          	jalr	1070(ra) # 8000489e <holdingsleep>
    80003478:	c92d                	beqz	a0,800034ea <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000347a:	854a                	mv	a0,s2
    8000347c:	00001097          	auipc	ra,0x1
    80003480:	3de080e7          	jalr	990(ra) # 8000485a <releasesleep>

  acquire(&bcache.lock);
    80003484:	00014517          	auipc	a0,0x14
    80003488:	85450513          	addi	a0,a0,-1964 # 80016cd8 <bcache>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	74a080e7          	jalr	1866(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003494:	40bc                	lw	a5,64(s1)
    80003496:	37fd                	addiw	a5,a5,-1
    80003498:	0007871b          	sext.w	a4,a5
    8000349c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000349e:	eb05                	bnez	a4,800034ce <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034a0:	68bc                	ld	a5,80(s1)
    800034a2:	64b8                	ld	a4,72(s1)
    800034a4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034a6:	64bc                	ld	a5,72(s1)
    800034a8:	68b8                	ld	a4,80(s1)
    800034aa:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034ac:	0001c797          	auipc	a5,0x1c
    800034b0:	82c78793          	addi	a5,a5,-2004 # 8001ecd8 <bcache+0x8000>
    800034b4:	2b87b703          	ld	a4,696(a5)
    800034b8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034ba:	0001c717          	auipc	a4,0x1c
    800034be:	a8670713          	addi	a4,a4,-1402 # 8001ef40 <bcache+0x8268>
    800034c2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034c4:	2b87b703          	ld	a4,696(a5)
    800034c8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034ca:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034ce:	00014517          	auipc	a0,0x14
    800034d2:	80a50513          	addi	a0,a0,-2038 # 80016cd8 <bcache>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
}
    800034de:	60e2                	ld	ra,24(sp)
    800034e0:	6442                	ld	s0,16(sp)
    800034e2:	64a2                	ld	s1,8(sp)
    800034e4:	6902                	ld	s2,0(sp)
    800034e6:	6105                	addi	sp,sp,32
    800034e8:	8082                	ret
    panic("brelse");
    800034ea:	00005517          	auipc	a0,0x5
    800034ee:	13650513          	addi	a0,a0,310 # 80008620 <syscalls+0x100>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	04e080e7          	jalr	78(ra) # 80000540 <panic>

00000000800034fa <bpin>:

void
bpin(struct buf *b) {
    800034fa:	1101                	addi	sp,sp,-32
    800034fc:	ec06                	sd	ra,24(sp)
    800034fe:	e822                	sd	s0,16(sp)
    80003500:	e426                	sd	s1,8(sp)
    80003502:	1000                	addi	s0,sp,32
    80003504:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003506:	00013517          	auipc	a0,0x13
    8000350a:	7d250513          	addi	a0,a0,2002 # 80016cd8 <bcache>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	6c8080e7          	jalr	1736(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003516:	40bc                	lw	a5,64(s1)
    80003518:	2785                	addiw	a5,a5,1
    8000351a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000351c:	00013517          	auipc	a0,0x13
    80003520:	7bc50513          	addi	a0,a0,1980 # 80016cd8 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	766080e7          	jalr	1894(ra) # 80000c8a <release>
}
    8000352c:	60e2                	ld	ra,24(sp)
    8000352e:	6442                	ld	s0,16(sp)
    80003530:	64a2                	ld	s1,8(sp)
    80003532:	6105                	addi	sp,sp,32
    80003534:	8082                	ret

0000000080003536 <bunpin>:

void
bunpin(struct buf *b) {
    80003536:	1101                	addi	sp,sp,-32
    80003538:	ec06                	sd	ra,24(sp)
    8000353a:	e822                	sd	s0,16(sp)
    8000353c:	e426                	sd	s1,8(sp)
    8000353e:	1000                	addi	s0,sp,32
    80003540:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003542:	00013517          	auipc	a0,0x13
    80003546:	79650513          	addi	a0,a0,1942 # 80016cd8 <bcache>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	68c080e7          	jalr	1676(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003552:	40bc                	lw	a5,64(s1)
    80003554:	37fd                	addiw	a5,a5,-1
    80003556:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003558:	00013517          	auipc	a0,0x13
    8000355c:	78050513          	addi	a0,a0,1920 # 80016cd8 <bcache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	72a080e7          	jalr	1834(ra) # 80000c8a <release>
}
    80003568:	60e2                	ld	ra,24(sp)
    8000356a:	6442                	ld	s0,16(sp)
    8000356c:	64a2                	ld	s1,8(sp)
    8000356e:	6105                	addi	sp,sp,32
    80003570:	8082                	ret

0000000080003572 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003572:	1101                	addi	sp,sp,-32
    80003574:	ec06                	sd	ra,24(sp)
    80003576:	e822                	sd	s0,16(sp)
    80003578:	e426                	sd	s1,8(sp)
    8000357a:	e04a                	sd	s2,0(sp)
    8000357c:	1000                	addi	s0,sp,32
    8000357e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003580:	00d5d59b          	srliw	a1,a1,0xd
    80003584:	0001c797          	auipc	a5,0x1c
    80003588:	e307a783          	lw	a5,-464(a5) # 8001f3b4 <sb+0x1c>
    8000358c:	9dbd                	addw	a1,a1,a5
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	d9e080e7          	jalr	-610(ra) # 8000332c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003596:	0074f713          	andi	a4,s1,7
    8000359a:	4785                	li	a5,1
    8000359c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035a0:	14ce                	slli	s1,s1,0x33
    800035a2:	90d9                	srli	s1,s1,0x36
    800035a4:	00950733          	add	a4,a0,s1
    800035a8:	05874703          	lbu	a4,88(a4)
    800035ac:	00e7f6b3          	and	a3,a5,a4
    800035b0:	c69d                	beqz	a3,800035de <bfree+0x6c>
    800035b2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035b4:	94aa                	add	s1,s1,a0
    800035b6:	fff7c793          	not	a5,a5
    800035ba:	8f7d                	and	a4,a4,a5
    800035bc:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	126080e7          	jalr	294(ra) # 800046e6 <log_write>
  brelse(bp);
    800035c8:	854a                	mv	a0,s2
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	e92080e7          	jalr	-366(ra) # 8000345c <brelse>
}
    800035d2:	60e2                	ld	ra,24(sp)
    800035d4:	6442                	ld	s0,16(sp)
    800035d6:	64a2                	ld	s1,8(sp)
    800035d8:	6902                	ld	s2,0(sp)
    800035da:	6105                	addi	sp,sp,32
    800035dc:	8082                	ret
    panic("freeing free block");
    800035de:	00005517          	auipc	a0,0x5
    800035e2:	04a50513          	addi	a0,a0,74 # 80008628 <syscalls+0x108>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	f5a080e7          	jalr	-166(ra) # 80000540 <panic>

00000000800035ee <balloc>:
{
    800035ee:	711d                	addi	sp,sp,-96
    800035f0:	ec86                	sd	ra,88(sp)
    800035f2:	e8a2                	sd	s0,80(sp)
    800035f4:	e4a6                	sd	s1,72(sp)
    800035f6:	e0ca                	sd	s2,64(sp)
    800035f8:	fc4e                	sd	s3,56(sp)
    800035fa:	f852                	sd	s4,48(sp)
    800035fc:	f456                	sd	s5,40(sp)
    800035fe:	f05a                	sd	s6,32(sp)
    80003600:	ec5e                	sd	s7,24(sp)
    80003602:	e862                	sd	s8,16(sp)
    80003604:	e466                	sd	s9,8(sp)
    80003606:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003608:	0001c797          	auipc	a5,0x1c
    8000360c:	d947a783          	lw	a5,-620(a5) # 8001f39c <sb+0x4>
    80003610:	cff5                	beqz	a5,8000370c <balloc+0x11e>
    80003612:	8baa                	mv	s7,a0
    80003614:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003616:	0001cb17          	auipc	s6,0x1c
    8000361a:	d82b0b13          	addi	s6,s6,-638 # 8001f398 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000361e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003620:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003622:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003624:	6c89                	lui	s9,0x2
    80003626:	a061                	j	800036ae <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003628:	97ca                	add	a5,a5,s2
    8000362a:	8e55                	or	a2,a2,a3
    8000362c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003630:	854a                	mv	a0,s2
    80003632:	00001097          	auipc	ra,0x1
    80003636:	0b4080e7          	jalr	180(ra) # 800046e6 <log_write>
        brelse(bp);
    8000363a:	854a                	mv	a0,s2
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	e20080e7          	jalr	-480(ra) # 8000345c <brelse>
  bp = bread(dev, bno);
    80003644:	85a6                	mv	a1,s1
    80003646:	855e                	mv	a0,s7
    80003648:	00000097          	auipc	ra,0x0
    8000364c:	ce4080e7          	jalr	-796(ra) # 8000332c <bread>
    80003650:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003652:	40000613          	li	a2,1024
    80003656:	4581                	li	a1,0
    80003658:	05850513          	addi	a0,a0,88
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	676080e7          	jalr	1654(ra) # 80000cd2 <memset>
  log_write(bp);
    80003664:	854a                	mv	a0,s2
    80003666:	00001097          	auipc	ra,0x1
    8000366a:	080080e7          	jalr	128(ra) # 800046e6 <log_write>
  brelse(bp);
    8000366e:	854a                	mv	a0,s2
    80003670:	00000097          	auipc	ra,0x0
    80003674:	dec080e7          	jalr	-532(ra) # 8000345c <brelse>
}
    80003678:	8526                	mv	a0,s1
    8000367a:	60e6                	ld	ra,88(sp)
    8000367c:	6446                	ld	s0,80(sp)
    8000367e:	64a6                	ld	s1,72(sp)
    80003680:	6906                	ld	s2,64(sp)
    80003682:	79e2                	ld	s3,56(sp)
    80003684:	7a42                	ld	s4,48(sp)
    80003686:	7aa2                	ld	s5,40(sp)
    80003688:	7b02                	ld	s6,32(sp)
    8000368a:	6be2                	ld	s7,24(sp)
    8000368c:	6c42                	ld	s8,16(sp)
    8000368e:	6ca2                	ld	s9,8(sp)
    80003690:	6125                	addi	sp,sp,96
    80003692:	8082                	ret
    brelse(bp);
    80003694:	854a                	mv	a0,s2
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	dc6080e7          	jalr	-570(ra) # 8000345c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000369e:	015c87bb          	addw	a5,s9,s5
    800036a2:	00078a9b          	sext.w	s5,a5
    800036a6:	004b2703          	lw	a4,4(s6)
    800036aa:	06eaf163          	bgeu	s5,a4,8000370c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800036ae:	41fad79b          	sraiw	a5,s5,0x1f
    800036b2:	0137d79b          	srliw	a5,a5,0x13
    800036b6:	015787bb          	addw	a5,a5,s5
    800036ba:	40d7d79b          	sraiw	a5,a5,0xd
    800036be:	01cb2583          	lw	a1,28(s6)
    800036c2:	9dbd                	addw	a1,a1,a5
    800036c4:	855e                	mv	a0,s7
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	c66080e7          	jalr	-922(ra) # 8000332c <bread>
    800036ce:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036d0:	004b2503          	lw	a0,4(s6)
    800036d4:	000a849b          	sext.w	s1,s5
    800036d8:	8762                	mv	a4,s8
    800036da:	faa4fde3          	bgeu	s1,a0,80003694 <balloc+0xa6>
      m = 1 << (bi % 8);
    800036de:	00777693          	andi	a3,a4,7
    800036e2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036e6:	41f7579b          	sraiw	a5,a4,0x1f
    800036ea:	01d7d79b          	srliw	a5,a5,0x1d
    800036ee:	9fb9                	addw	a5,a5,a4
    800036f0:	4037d79b          	sraiw	a5,a5,0x3
    800036f4:	00f90633          	add	a2,s2,a5
    800036f8:	05864603          	lbu	a2,88(a2)
    800036fc:	00c6f5b3          	and	a1,a3,a2
    80003700:	d585                	beqz	a1,80003628 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003702:	2705                	addiw	a4,a4,1
    80003704:	2485                	addiw	s1,s1,1
    80003706:	fd471ae3          	bne	a4,s4,800036da <balloc+0xec>
    8000370a:	b769                	j	80003694 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000370c:	00005517          	auipc	a0,0x5
    80003710:	f3450513          	addi	a0,a0,-204 # 80008640 <syscalls+0x120>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	e76080e7          	jalr	-394(ra) # 8000058a <printf>
  return 0;
    8000371c:	4481                	li	s1,0
    8000371e:	bfa9                	j	80003678 <balloc+0x8a>

0000000080003720 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003720:	7179                	addi	sp,sp,-48
    80003722:	f406                	sd	ra,40(sp)
    80003724:	f022                	sd	s0,32(sp)
    80003726:	ec26                	sd	s1,24(sp)
    80003728:	e84a                	sd	s2,16(sp)
    8000372a:	e44e                	sd	s3,8(sp)
    8000372c:	e052                	sd	s4,0(sp)
    8000372e:	1800                	addi	s0,sp,48
    80003730:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003732:	47ad                	li	a5,11
    80003734:	02b7e863          	bltu	a5,a1,80003764 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003738:	02059793          	slli	a5,a1,0x20
    8000373c:	01e7d593          	srli	a1,a5,0x1e
    80003740:	00b504b3          	add	s1,a0,a1
    80003744:	0504a903          	lw	s2,80(s1)
    80003748:	06091e63          	bnez	s2,800037c4 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000374c:	4108                	lw	a0,0(a0)
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	ea0080e7          	jalr	-352(ra) # 800035ee <balloc>
    80003756:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000375a:	06090563          	beqz	s2,800037c4 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000375e:	0524a823          	sw	s2,80(s1)
    80003762:	a08d                	j	800037c4 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003764:	ff45849b          	addiw	s1,a1,-12
    80003768:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000376c:	0ff00793          	li	a5,255
    80003770:	08e7e563          	bltu	a5,a4,800037fa <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003774:	08052903          	lw	s2,128(a0)
    80003778:	00091d63          	bnez	s2,80003792 <bmap+0x72>
      addr = balloc(ip->dev);
    8000377c:	4108                	lw	a0,0(a0)
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	e70080e7          	jalr	-400(ra) # 800035ee <balloc>
    80003786:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000378a:	02090d63          	beqz	s2,800037c4 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000378e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003792:	85ca                	mv	a1,s2
    80003794:	0009a503          	lw	a0,0(s3)
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	b94080e7          	jalr	-1132(ra) # 8000332c <bread>
    800037a0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037a2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037a6:	02049713          	slli	a4,s1,0x20
    800037aa:	01e75593          	srli	a1,a4,0x1e
    800037ae:	00b784b3          	add	s1,a5,a1
    800037b2:	0004a903          	lw	s2,0(s1)
    800037b6:	02090063          	beqz	s2,800037d6 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800037ba:	8552                	mv	a0,s4
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	ca0080e7          	jalr	-864(ra) # 8000345c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037c4:	854a                	mv	a0,s2
    800037c6:	70a2                	ld	ra,40(sp)
    800037c8:	7402                	ld	s0,32(sp)
    800037ca:	64e2                	ld	s1,24(sp)
    800037cc:	6942                	ld	s2,16(sp)
    800037ce:	69a2                	ld	s3,8(sp)
    800037d0:	6a02                	ld	s4,0(sp)
    800037d2:	6145                	addi	sp,sp,48
    800037d4:	8082                	ret
      addr = balloc(ip->dev);
    800037d6:	0009a503          	lw	a0,0(s3)
    800037da:	00000097          	auipc	ra,0x0
    800037de:	e14080e7          	jalr	-492(ra) # 800035ee <balloc>
    800037e2:	0005091b          	sext.w	s2,a0
      if(addr){
    800037e6:	fc090ae3          	beqz	s2,800037ba <bmap+0x9a>
        a[bn] = addr;
    800037ea:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800037ee:	8552                	mv	a0,s4
    800037f0:	00001097          	auipc	ra,0x1
    800037f4:	ef6080e7          	jalr	-266(ra) # 800046e6 <log_write>
    800037f8:	b7c9                	j	800037ba <bmap+0x9a>
  panic("bmap: out of range");
    800037fa:	00005517          	auipc	a0,0x5
    800037fe:	e5e50513          	addi	a0,a0,-418 # 80008658 <syscalls+0x138>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	d3e080e7          	jalr	-706(ra) # 80000540 <panic>

000000008000380a <iget>:
{
    8000380a:	7179                	addi	sp,sp,-48
    8000380c:	f406                	sd	ra,40(sp)
    8000380e:	f022                	sd	s0,32(sp)
    80003810:	ec26                	sd	s1,24(sp)
    80003812:	e84a                	sd	s2,16(sp)
    80003814:	e44e                	sd	s3,8(sp)
    80003816:	e052                	sd	s4,0(sp)
    80003818:	1800                	addi	s0,sp,48
    8000381a:	89aa                	mv	s3,a0
    8000381c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000381e:	0001c517          	auipc	a0,0x1c
    80003822:	b9a50513          	addi	a0,a0,-1126 # 8001f3b8 <itable>
    80003826:	ffffd097          	auipc	ra,0xffffd
    8000382a:	3b0080e7          	jalr	944(ra) # 80000bd6 <acquire>
  empty = 0;
    8000382e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003830:	0001c497          	auipc	s1,0x1c
    80003834:	ba048493          	addi	s1,s1,-1120 # 8001f3d0 <itable+0x18>
    80003838:	0001d697          	auipc	a3,0x1d
    8000383c:	62868693          	addi	a3,a3,1576 # 80020e60 <log>
    80003840:	a039                	j	8000384e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003842:	02090b63          	beqz	s2,80003878 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003846:	08848493          	addi	s1,s1,136
    8000384a:	02d48a63          	beq	s1,a3,8000387e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000384e:	449c                	lw	a5,8(s1)
    80003850:	fef059e3          	blez	a5,80003842 <iget+0x38>
    80003854:	4098                	lw	a4,0(s1)
    80003856:	ff3716e3          	bne	a4,s3,80003842 <iget+0x38>
    8000385a:	40d8                	lw	a4,4(s1)
    8000385c:	ff4713e3          	bne	a4,s4,80003842 <iget+0x38>
      ip->ref++;
    80003860:	2785                	addiw	a5,a5,1
    80003862:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003864:	0001c517          	auipc	a0,0x1c
    80003868:	b5450513          	addi	a0,a0,-1196 # 8001f3b8 <itable>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	41e080e7          	jalr	1054(ra) # 80000c8a <release>
      return ip;
    80003874:	8926                	mv	s2,s1
    80003876:	a03d                	j	800038a4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003878:	f7f9                	bnez	a5,80003846 <iget+0x3c>
    8000387a:	8926                	mv	s2,s1
    8000387c:	b7e9                	j	80003846 <iget+0x3c>
  if(empty == 0)
    8000387e:	02090c63          	beqz	s2,800038b6 <iget+0xac>
  ip->dev = dev;
    80003882:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003886:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000388a:	4785                	li	a5,1
    8000388c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003890:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003894:	0001c517          	auipc	a0,0x1c
    80003898:	b2450513          	addi	a0,a0,-1244 # 8001f3b8 <itable>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	3ee080e7          	jalr	1006(ra) # 80000c8a <release>
}
    800038a4:	854a                	mv	a0,s2
    800038a6:	70a2                	ld	ra,40(sp)
    800038a8:	7402                	ld	s0,32(sp)
    800038aa:	64e2                	ld	s1,24(sp)
    800038ac:	6942                	ld	s2,16(sp)
    800038ae:	69a2                	ld	s3,8(sp)
    800038b0:	6a02                	ld	s4,0(sp)
    800038b2:	6145                	addi	sp,sp,48
    800038b4:	8082                	ret
    panic("iget: no inodes");
    800038b6:	00005517          	auipc	a0,0x5
    800038ba:	dba50513          	addi	a0,a0,-582 # 80008670 <syscalls+0x150>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	c82080e7          	jalr	-894(ra) # 80000540 <panic>

00000000800038c6 <fsinit>:
fsinit(int dev) {
    800038c6:	7179                	addi	sp,sp,-48
    800038c8:	f406                	sd	ra,40(sp)
    800038ca:	f022                	sd	s0,32(sp)
    800038cc:	ec26                	sd	s1,24(sp)
    800038ce:	e84a                	sd	s2,16(sp)
    800038d0:	e44e                	sd	s3,8(sp)
    800038d2:	1800                	addi	s0,sp,48
    800038d4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038d6:	4585                	li	a1,1
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	a54080e7          	jalr	-1452(ra) # 8000332c <bread>
    800038e0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038e2:	0001c997          	auipc	s3,0x1c
    800038e6:	ab698993          	addi	s3,s3,-1354 # 8001f398 <sb>
    800038ea:	02000613          	li	a2,32
    800038ee:	05850593          	addi	a1,a0,88
    800038f2:	854e                	mv	a0,s3
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	43a080e7          	jalr	1082(ra) # 80000d2e <memmove>
  brelse(bp);
    800038fc:	8526                	mv	a0,s1
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	b5e080e7          	jalr	-1186(ra) # 8000345c <brelse>
  if(sb.magic != FSMAGIC)
    80003906:	0009a703          	lw	a4,0(s3)
    8000390a:	102037b7          	lui	a5,0x10203
    8000390e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003912:	02f71263          	bne	a4,a5,80003936 <fsinit+0x70>
  initlog(dev, &sb);
    80003916:	0001c597          	auipc	a1,0x1c
    8000391a:	a8258593          	addi	a1,a1,-1406 # 8001f398 <sb>
    8000391e:	854a                	mv	a0,s2
    80003920:	00001097          	auipc	ra,0x1
    80003924:	b4a080e7          	jalr	-1206(ra) # 8000446a <initlog>
}
    80003928:	70a2                	ld	ra,40(sp)
    8000392a:	7402                	ld	s0,32(sp)
    8000392c:	64e2                	ld	s1,24(sp)
    8000392e:	6942                	ld	s2,16(sp)
    80003930:	69a2                	ld	s3,8(sp)
    80003932:	6145                	addi	sp,sp,48
    80003934:	8082                	ret
    panic("invalid file system");
    80003936:	00005517          	auipc	a0,0x5
    8000393a:	d4a50513          	addi	a0,a0,-694 # 80008680 <syscalls+0x160>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	c02080e7          	jalr	-1022(ra) # 80000540 <panic>

0000000080003946 <iinit>:
{
    80003946:	7179                	addi	sp,sp,-48
    80003948:	f406                	sd	ra,40(sp)
    8000394a:	f022                	sd	s0,32(sp)
    8000394c:	ec26                	sd	s1,24(sp)
    8000394e:	e84a                	sd	s2,16(sp)
    80003950:	e44e                	sd	s3,8(sp)
    80003952:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003954:	00005597          	auipc	a1,0x5
    80003958:	d4458593          	addi	a1,a1,-700 # 80008698 <syscalls+0x178>
    8000395c:	0001c517          	auipc	a0,0x1c
    80003960:	a5c50513          	addi	a0,a0,-1444 # 8001f3b8 <itable>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	1e2080e7          	jalr	482(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000396c:	0001c497          	auipc	s1,0x1c
    80003970:	a7448493          	addi	s1,s1,-1420 # 8001f3e0 <itable+0x28>
    80003974:	0001d997          	auipc	s3,0x1d
    80003978:	4fc98993          	addi	s3,s3,1276 # 80020e70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000397c:	00005917          	auipc	s2,0x5
    80003980:	d2490913          	addi	s2,s2,-732 # 800086a0 <syscalls+0x180>
    80003984:	85ca                	mv	a1,s2
    80003986:	8526                	mv	a0,s1
    80003988:	00001097          	auipc	ra,0x1
    8000398c:	e42080e7          	jalr	-446(ra) # 800047ca <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003990:	08848493          	addi	s1,s1,136
    80003994:	ff3498e3          	bne	s1,s3,80003984 <iinit+0x3e>
}
    80003998:	70a2                	ld	ra,40(sp)
    8000399a:	7402                	ld	s0,32(sp)
    8000399c:	64e2                	ld	s1,24(sp)
    8000399e:	6942                	ld	s2,16(sp)
    800039a0:	69a2                	ld	s3,8(sp)
    800039a2:	6145                	addi	sp,sp,48
    800039a4:	8082                	ret

00000000800039a6 <ialloc>:
{
    800039a6:	715d                	addi	sp,sp,-80
    800039a8:	e486                	sd	ra,72(sp)
    800039aa:	e0a2                	sd	s0,64(sp)
    800039ac:	fc26                	sd	s1,56(sp)
    800039ae:	f84a                	sd	s2,48(sp)
    800039b0:	f44e                	sd	s3,40(sp)
    800039b2:	f052                	sd	s4,32(sp)
    800039b4:	ec56                	sd	s5,24(sp)
    800039b6:	e85a                	sd	s6,16(sp)
    800039b8:	e45e                	sd	s7,8(sp)
    800039ba:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039bc:	0001c717          	auipc	a4,0x1c
    800039c0:	9e872703          	lw	a4,-1560(a4) # 8001f3a4 <sb+0xc>
    800039c4:	4785                	li	a5,1
    800039c6:	04e7fa63          	bgeu	a5,a4,80003a1a <ialloc+0x74>
    800039ca:	8aaa                	mv	s5,a0
    800039cc:	8bae                	mv	s7,a1
    800039ce:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039d0:	0001ca17          	auipc	s4,0x1c
    800039d4:	9c8a0a13          	addi	s4,s4,-1592 # 8001f398 <sb>
    800039d8:	00048b1b          	sext.w	s6,s1
    800039dc:	0044d593          	srli	a1,s1,0x4
    800039e0:	018a2783          	lw	a5,24(s4)
    800039e4:	9dbd                	addw	a1,a1,a5
    800039e6:	8556                	mv	a0,s5
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	944080e7          	jalr	-1724(ra) # 8000332c <bread>
    800039f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039f2:	05850993          	addi	s3,a0,88
    800039f6:	00f4f793          	andi	a5,s1,15
    800039fa:	079a                	slli	a5,a5,0x6
    800039fc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039fe:	00099783          	lh	a5,0(s3)
    80003a02:	c3a1                	beqz	a5,80003a42 <ialloc+0x9c>
    brelse(bp);
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	a58080e7          	jalr	-1448(ra) # 8000345c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a0c:	0485                	addi	s1,s1,1
    80003a0e:	00ca2703          	lw	a4,12(s4)
    80003a12:	0004879b          	sext.w	a5,s1
    80003a16:	fce7e1e3          	bltu	a5,a4,800039d8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003a1a:	00005517          	auipc	a0,0x5
    80003a1e:	c8e50513          	addi	a0,a0,-882 # 800086a8 <syscalls+0x188>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	b68080e7          	jalr	-1176(ra) # 8000058a <printf>
  return 0;
    80003a2a:	4501                	li	a0,0
}
    80003a2c:	60a6                	ld	ra,72(sp)
    80003a2e:	6406                	ld	s0,64(sp)
    80003a30:	74e2                	ld	s1,56(sp)
    80003a32:	7942                	ld	s2,48(sp)
    80003a34:	79a2                	ld	s3,40(sp)
    80003a36:	7a02                	ld	s4,32(sp)
    80003a38:	6ae2                	ld	s5,24(sp)
    80003a3a:	6b42                	ld	s6,16(sp)
    80003a3c:	6ba2                	ld	s7,8(sp)
    80003a3e:	6161                	addi	sp,sp,80
    80003a40:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a42:	04000613          	li	a2,64
    80003a46:	4581                	li	a1,0
    80003a48:	854e                	mv	a0,s3
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	288080e7          	jalr	648(ra) # 80000cd2 <memset>
      dip->type = type;
    80003a52:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a56:	854a                	mv	a0,s2
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	c8e080e7          	jalr	-882(ra) # 800046e6 <log_write>
      brelse(bp);
    80003a60:	854a                	mv	a0,s2
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	9fa080e7          	jalr	-1542(ra) # 8000345c <brelse>
      return iget(dev, inum);
    80003a6a:	85da                	mv	a1,s6
    80003a6c:	8556                	mv	a0,s5
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	d9c080e7          	jalr	-612(ra) # 8000380a <iget>
    80003a76:	bf5d                	j	80003a2c <ialloc+0x86>

0000000080003a78 <iupdate>:
{
    80003a78:	1101                	addi	sp,sp,-32
    80003a7a:	ec06                	sd	ra,24(sp)
    80003a7c:	e822                	sd	s0,16(sp)
    80003a7e:	e426                	sd	s1,8(sp)
    80003a80:	e04a                	sd	s2,0(sp)
    80003a82:	1000                	addi	s0,sp,32
    80003a84:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a86:	415c                	lw	a5,4(a0)
    80003a88:	0047d79b          	srliw	a5,a5,0x4
    80003a8c:	0001c597          	auipc	a1,0x1c
    80003a90:	9245a583          	lw	a1,-1756(a1) # 8001f3b0 <sb+0x18>
    80003a94:	9dbd                	addw	a1,a1,a5
    80003a96:	4108                	lw	a0,0(a0)
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	894080e7          	jalr	-1900(ra) # 8000332c <bread>
    80003aa0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aa2:	05850793          	addi	a5,a0,88
    80003aa6:	40d8                	lw	a4,4(s1)
    80003aa8:	8b3d                	andi	a4,a4,15
    80003aaa:	071a                	slli	a4,a4,0x6
    80003aac:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003aae:	04449703          	lh	a4,68(s1)
    80003ab2:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003ab6:	04649703          	lh	a4,70(s1)
    80003aba:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003abe:	04849703          	lh	a4,72(s1)
    80003ac2:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003ac6:	04a49703          	lh	a4,74(s1)
    80003aca:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003ace:	44f8                	lw	a4,76(s1)
    80003ad0:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ad2:	03400613          	li	a2,52
    80003ad6:	05048593          	addi	a1,s1,80
    80003ada:	00c78513          	addi	a0,a5,12
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	250080e7          	jalr	592(ra) # 80000d2e <memmove>
  log_write(bp);
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	00001097          	auipc	ra,0x1
    80003aec:	bfe080e7          	jalr	-1026(ra) # 800046e6 <log_write>
  brelse(bp);
    80003af0:	854a                	mv	a0,s2
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	96a080e7          	jalr	-1686(ra) # 8000345c <brelse>
}
    80003afa:	60e2                	ld	ra,24(sp)
    80003afc:	6442                	ld	s0,16(sp)
    80003afe:	64a2                	ld	s1,8(sp)
    80003b00:	6902                	ld	s2,0(sp)
    80003b02:	6105                	addi	sp,sp,32
    80003b04:	8082                	ret

0000000080003b06 <idup>:
{
    80003b06:	1101                	addi	sp,sp,-32
    80003b08:	ec06                	sd	ra,24(sp)
    80003b0a:	e822                	sd	s0,16(sp)
    80003b0c:	e426                	sd	s1,8(sp)
    80003b0e:	1000                	addi	s0,sp,32
    80003b10:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b12:	0001c517          	auipc	a0,0x1c
    80003b16:	8a650513          	addi	a0,a0,-1882 # 8001f3b8 <itable>
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	0bc080e7          	jalr	188(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003b22:	449c                	lw	a5,8(s1)
    80003b24:	2785                	addiw	a5,a5,1
    80003b26:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b28:	0001c517          	auipc	a0,0x1c
    80003b2c:	89050513          	addi	a0,a0,-1904 # 8001f3b8 <itable>
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	15a080e7          	jalr	346(ra) # 80000c8a <release>
}
    80003b38:	8526                	mv	a0,s1
    80003b3a:	60e2                	ld	ra,24(sp)
    80003b3c:	6442                	ld	s0,16(sp)
    80003b3e:	64a2                	ld	s1,8(sp)
    80003b40:	6105                	addi	sp,sp,32
    80003b42:	8082                	ret

0000000080003b44 <ilock>:
{
    80003b44:	1101                	addi	sp,sp,-32
    80003b46:	ec06                	sd	ra,24(sp)
    80003b48:	e822                	sd	s0,16(sp)
    80003b4a:	e426                	sd	s1,8(sp)
    80003b4c:	e04a                	sd	s2,0(sp)
    80003b4e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b50:	c115                	beqz	a0,80003b74 <ilock+0x30>
    80003b52:	84aa                	mv	s1,a0
    80003b54:	451c                	lw	a5,8(a0)
    80003b56:	00f05f63          	blez	a5,80003b74 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b5a:	0541                	addi	a0,a0,16
    80003b5c:	00001097          	auipc	ra,0x1
    80003b60:	ca8080e7          	jalr	-856(ra) # 80004804 <acquiresleep>
  if(ip->valid == 0){
    80003b64:	40bc                	lw	a5,64(s1)
    80003b66:	cf99                	beqz	a5,80003b84 <ilock+0x40>
}
    80003b68:	60e2                	ld	ra,24(sp)
    80003b6a:	6442                	ld	s0,16(sp)
    80003b6c:	64a2                	ld	s1,8(sp)
    80003b6e:	6902                	ld	s2,0(sp)
    80003b70:	6105                	addi	sp,sp,32
    80003b72:	8082                	ret
    panic("ilock");
    80003b74:	00005517          	auipc	a0,0x5
    80003b78:	b4c50513          	addi	a0,a0,-1204 # 800086c0 <syscalls+0x1a0>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	9c4080e7          	jalr	-1596(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b84:	40dc                	lw	a5,4(s1)
    80003b86:	0047d79b          	srliw	a5,a5,0x4
    80003b8a:	0001c597          	auipc	a1,0x1c
    80003b8e:	8265a583          	lw	a1,-2010(a1) # 8001f3b0 <sb+0x18>
    80003b92:	9dbd                	addw	a1,a1,a5
    80003b94:	4088                	lw	a0,0(s1)
    80003b96:	fffff097          	auipc	ra,0xfffff
    80003b9a:	796080e7          	jalr	1942(ra) # 8000332c <bread>
    80003b9e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ba0:	05850593          	addi	a1,a0,88
    80003ba4:	40dc                	lw	a5,4(s1)
    80003ba6:	8bbd                	andi	a5,a5,15
    80003ba8:	079a                	slli	a5,a5,0x6
    80003baa:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bac:	00059783          	lh	a5,0(a1)
    80003bb0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bb4:	00259783          	lh	a5,2(a1)
    80003bb8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bbc:	00459783          	lh	a5,4(a1)
    80003bc0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bc4:	00659783          	lh	a5,6(a1)
    80003bc8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bcc:	459c                	lw	a5,8(a1)
    80003bce:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bd0:	03400613          	li	a2,52
    80003bd4:	05b1                	addi	a1,a1,12
    80003bd6:	05048513          	addi	a0,s1,80
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	154080e7          	jalr	340(ra) # 80000d2e <memmove>
    brelse(bp);
    80003be2:	854a                	mv	a0,s2
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	878080e7          	jalr	-1928(ra) # 8000345c <brelse>
    ip->valid = 1;
    80003bec:	4785                	li	a5,1
    80003bee:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bf0:	04449783          	lh	a5,68(s1)
    80003bf4:	fbb5                	bnez	a5,80003b68 <ilock+0x24>
      panic("ilock: no type");
    80003bf6:	00005517          	auipc	a0,0x5
    80003bfa:	ad250513          	addi	a0,a0,-1326 # 800086c8 <syscalls+0x1a8>
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	942080e7          	jalr	-1726(ra) # 80000540 <panic>

0000000080003c06 <iunlock>:
{
    80003c06:	1101                	addi	sp,sp,-32
    80003c08:	ec06                	sd	ra,24(sp)
    80003c0a:	e822                	sd	s0,16(sp)
    80003c0c:	e426                	sd	s1,8(sp)
    80003c0e:	e04a                	sd	s2,0(sp)
    80003c10:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c12:	c905                	beqz	a0,80003c42 <iunlock+0x3c>
    80003c14:	84aa                	mv	s1,a0
    80003c16:	01050913          	addi	s2,a0,16
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	00001097          	auipc	ra,0x1
    80003c20:	c82080e7          	jalr	-894(ra) # 8000489e <holdingsleep>
    80003c24:	cd19                	beqz	a0,80003c42 <iunlock+0x3c>
    80003c26:	449c                	lw	a5,8(s1)
    80003c28:	00f05d63          	blez	a5,80003c42 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c2c:	854a                	mv	a0,s2
    80003c2e:	00001097          	auipc	ra,0x1
    80003c32:	c2c080e7          	jalr	-980(ra) # 8000485a <releasesleep>
}
    80003c36:	60e2                	ld	ra,24(sp)
    80003c38:	6442                	ld	s0,16(sp)
    80003c3a:	64a2                	ld	s1,8(sp)
    80003c3c:	6902                	ld	s2,0(sp)
    80003c3e:	6105                	addi	sp,sp,32
    80003c40:	8082                	ret
    panic("iunlock");
    80003c42:	00005517          	auipc	a0,0x5
    80003c46:	a9650513          	addi	a0,a0,-1386 # 800086d8 <syscalls+0x1b8>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	8f6080e7          	jalr	-1802(ra) # 80000540 <panic>

0000000080003c52 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c52:	7179                	addi	sp,sp,-48
    80003c54:	f406                	sd	ra,40(sp)
    80003c56:	f022                	sd	s0,32(sp)
    80003c58:	ec26                	sd	s1,24(sp)
    80003c5a:	e84a                	sd	s2,16(sp)
    80003c5c:	e44e                	sd	s3,8(sp)
    80003c5e:	e052                	sd	s4,0(sp)
    80003c60:	1800                	addi	s0,sp,48
    80003c62:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c64:	05050493          	addi	s1,a0,80
    80003c68:	08050913          	addi	s2,a0,128
    80003c6c:	a021                	j	80003c74 <itrunc+0x22>
    80003c6e:	0491                	addi	s1,s1,4
    80003c70:	01248d63          	beq	s1,s2,80003c8a <itrunc+0x38>
    if(ip->addrs[i]){
    80003c74:	408c                	lw	a1,0(s1)
    80003c76:	dde5                	beqz	a1,80003c6e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c78:	0009a503          	lw	a0,0(s3)
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	8f6080e7          	jalr	-1802(ra) # 80003572 <bfree>
      ip->addrs[i] = 0;
    80003c84:	0004a023          	sw	zero,0(s1)
    80003c88:	b7dd                	j	80003c6e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c8a:	0809a583          	lw	a1,128(s3)
    80003c8e:	e185                	bnez	a1,80003cae <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c90:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c94:	854e                	mv	a0,s3
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	de2080e7          	jalr	-542(ra) # 80003a78 <iupdate>
}
    80003c9e:	70a2                	ld	ra,40(sp)
    80003ca0:	7402                	ld	s0,32(sp)
    80003ca2:	64e2                	ld	s1,24(sp)
    80003ca4:	6942                	ld	s2,16(sp)
    80003ca6:	69a2                	ld	s3,8(sp)
    80003ca8:	6a02                	ld	s4,0(sp)
    80003caa:	6145                	addi	sp,sp,48
    80003cac:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cae:	0009a503          	lw	a0,0(s3)
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	67a080e7          	jalr	1658(ra) # 8000332c <bread>
    80003cba:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cbc:	05850493          	addi	s1,a0,88
    80003cc0:	45850913          	addi	s2,a0,1112
    80003cc4:	a021                	j	80003ccc <itrunc+0x7a>
    80003cc6:	0491                	addi	s1,s1,4
    80003cc8:	01248b63          	beq	s1,s2,80003cde <itrunc+0x8c>
      if(a[j])
    80003ccc:	408c                	lw	a1,0(s1)
    80003cce:	dde5                	beqz	a1,80003cc6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003cd0:	0009a503          	lw	a0,0(s3)
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	89e080e7          	jalr	-1890(ra) # 80003572 <bfree>
    80003cdc:	b7ed                	j	80003cc6 <itrunc+0x74>
    brelse(bp);
    80003cde:	8552                	mv	a0,s4
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	77c080e7          	jalr	1916(ra) # 8000345c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ce8:	0809a583          	lw	a1,128(s3)
    80003cec:	0009a503          	lw	a0,0(s3)
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	882080e7          	jalr	-1918(ra) # 80003572 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cf8:	0809a023          	sw	zero,128(s3)
    80003cfc:	bf51                	j	80003c90 <itrunc+0x3e>

0000000080003cfe <iput>:
{
    80003cfe:	1101                	addi	sp,sp,-32
    80003d00:	ec06                	sd	ra,24(sp)
    80003d02:	e822                	sd	s0,16(sp)
    80003d04:	e426                	sd	s1,8(sp)
    80003d06:	e04a                	sd	s2,0(sp)
    80003d08:	1000                	addi	s0,sp,32
    80003d0a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d0c:	0001b517          	auipc	a0,0x1b
    80003d10:	6ac50513          	addi	a0,a0,1708 # 8001f3b8 <itable>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	ec2080e7          	jalr	-318(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d1c:	4498                	lw	a4,8(s1)
    80003d1e:	4785                	li	a5,1
    80003d20:	02f70363          	beq	a4,a5,80003d46 <iput+0x48>
  ip->ref--;
    80003d24:	449c                	lw	a5,8(s1)
    80003d26:	37fd                	addiw	a5,a5,-1
    80003d28:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d2a:	0001b517          	auipc	a0,0x1b
    80003d2e:	68e50513          	addi	a0,a0,1678 # 8001f3b8 <itable>
    80003d32:	ffffd097          	auipc	ra,0xffffd
    80003d36:	f58080e7          	jalr	-168(ra) # 80000c8a <release>
}
    80003d3a:	60e2                	ld	ra,24(sp)
    80003d3c:	6442                	ld	s0,16(sp)
    80003d3e:	64a2                	ld	s1,8(sp)
    80003d40:	6902                	ld	s2,0(sp)
    80003d42:	6105                	addi	sp,sp,32
    80003d44:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d46:	40bc                	lw	a5,64(s1)
    80003d48:	dff1                	beqz	a5,80003d24 <iput+0x26>
    80003d4a:	04a49783          	lh	a5,74(s1)
    80003d4e:	fbf9                	bnez	a5,80003d24 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d50:	01048913          	addi	s2,s1,16
    80003d54:	854a                	mv	a0,s2
    80003d56:	00001097          	auipc	ra,0x1
    80003d5a:	aae080e7          	jalr	-1362(ra) # 80004804 <acquiresleep>
    release(&itable.lock);
    80003d5e:	0001b517          	auipc	a0,0x1b
    80003d62:	65a50513          	addi	a0,a0,1626 # 8001f3b8 <itable>
    80003d66:	ffffd097          	auipc	ra,0xffffd
    80003d6a:	f24080e7          	jalr	-220(ra) # 80000c8a <release>
    itrunc(ip);
    80003d6e:	8526                	mv	a0,s1
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	ee2080e7          	jalr	-286(ra) # 80003c52 <itrunc>
    ip->type = 0;
    80003d78:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d7c:	8526                	mv	a0,s1
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	cfa080e7          	jalr	-774(ra) # 80003a78 <iupdate>
    ip->valid = 0;
    80003d86:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	00001097          	auipc	ra,0x1
    80003d90:	ace080e7          	jalr	-1330(ra) # 8000485a <releasesleep>
    acquire(&itable.lock);
    80003d94:	0001b517          	auipc	a0,0x1b
    80003d98:	62450513          	addi	a0,a0,1572 # 8001f3b8 <itable>
    80003d9c:	ffffd097          	auipc	ra,0xffffd
    80003da0:	e3a080e7          	jalr	-454(ra) # 80000bd6 <acquire>
    80003da4:	b741                	j	80003d24 <iput+0x26>

0000000080003da6 <iunlockput>:
{
    80003da6:	1101                	addi	sp,sp,-32
    80003da8:	ec06                	sd	ra,24(sp)
    80003daa:	e822                	sd	s0,16(sp)
    80003dac:	e426                	sd	s1,8(sp)
    80003dae:	1000                	addi	s0,sp,32
    80003db0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	e54080e7          	jalr	-428(ra) # 80003c06 <iunlock>
  iput(ip);
    80003dba:	8526                	mv	a0,s1
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	f42080e7          	jalr	-190(ra) # 80003cfe <iput>
}
    80003dc4:	60e2                	ld	ra,24(sp)
    80003dc6:	6442                	ld	s0,16(sp)
    80003dc8:	64a2                	ld	s1,8(sp)
    80003dca:	6105                	addi	sp,sp,32
    80003dcc:	8082                	ret

0000000080003dce <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003dce:	1141                	addi	sp,sp,-16
    80003dd0:	e422                	sd	s0,8(sp)
    80003dd2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003dd4:	411c                	lw	a5,0(a0)
    80003dd6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dd8:	415c                	lw	a5,4(a0)
    80003dda:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ddc:	04451783          	lh	a5,68(a0)
    80003de0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003de4:	04a51783          	lh	a5,74(a0)
    80003de8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003dec:	04c56783          	lwu	a5,76(a0)
    80003df0:	e99c                	sd	a5,16(a1)
}
    80003df2:	6422                	ld	s0,8(sp)
    80003df4:	0141                	addi	sp,sp,16
    80003df6:	8082                	ret

0000000080003df8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003df8:	457c                	lw	a5,76(a0)
    80003dfa:	0ed7e963          	bltu	a5,a3,80003eec <readi+0xf4>
{
    80003dfe:	7159                	addi	sp,sp,-112
    80003e00:	f486                	sd	ra,104(sp)
    80003e02:	f0a2                	sd	s0,96(sp)
    80003e04:	eca6                	sd	s1,88(sp)
    80003e06:	e8ca                	sd	s2,80(sp)
    80003e08:	e4ce                	sd	s3,72(sp)
    80003e0a:	e0d2                	sd	s4,64(sp)
    80003e0c:	fc56                	sd	s5,56(sp)
    80003e0e:	f85a                	sd	s6,48(sp)
    80003e10:	f45e                	sd	s7,40(sp)
    80003e12:	f062                	sd	s8,32(sp)
    80003e14:	ec66                	sd	s9,24(sp)
    80003e16:	e86a                	sd	s10,16(sp)
    80003e18:	e46e                	sd	s11,8(sp)
    80003e1a:	1880                	addi	s0,sp,112
    80003e1c:	8b2a                	mv	s6,a0
    80003e1e:	8bae                	mv	s7,a1
    80003e20:	8a32                	mv	s4,a2
    80003e22:	84b6                	mv	s1,a3
    80003e24:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e26:	9f35                	addw	a4,a4,a3
    return 0;
    80003e28:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e2a:	0ad76063          	bltu	a4,a3,80003eca <readi+0xd2>
  if(off + n > ip->size)
    80003e2e:	00e7f463          	bgeu	a5,a4,80003e36 <readi+0x3e>
    n = ip->size - off;
    80003e32:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e36:	0a0a8963          	beqz	s5,80003ee8 <readi+0xf0>
    80003e3a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e3c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e40:	5c7d                	li	s8,-1
    80003e42:	a82d                	j	80003e7c <readi+0x84>
    80003e44:	020d1d93          	slli	s11,s10,0x20
    80003e48:	020ddd93          	srli	s11,s11,0x20
    80003e4c:	05890613          	addi	a2,s2,88
    80003e50:	86ee                	mv	a3,s11
    80003e52:	963a                	add	a2,a2,a4
    80003e54:	85d2                	mv	a1,s4
    80003e56:	855e                	mv	a0,s7
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	926080e7          	jalr	-1754(ra) # 8000277e <either_copyout>
    80003e60:	05850d63          	beq	a0,s8,80003eba <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e64:	854a                	mv	a0,s2
    80003e66:	fffff097          	auipc	ra,0xfffff
    80003e6a:	5f6080e7          	jalr	1526(ra) # 8000345c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e6e:	013d09bb          	addw	s3,s10,s3
    80003e72:	009d04bb          	addw	s1,s10,s1
    80003e76:	9a6e                	add	s4,s4,s11
    80003e78:	0559f763          	bgeu	s3,s5,80003ec6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e7c:	00a4d59b          	srliw	a1,s1,0xa
    80003e80:	855a                	mv	a0,s6
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	89e080e7          	jalr	-1890(ra) # 80003720 <bmap>
    80003e8a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e8e:	cd85                	beqz	a1,80003ec6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e90:	000b2503          	lw	a0,0(s6)
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	498080e7          	jalr	1176(ra) # 8000332c <bread>
    80003e9c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e9e:	3ff4f713          	andi	a4,s1,1023
    80003ea2:	40ec87bb          	subw	a5,s9,a4
    80003ea6:	413a86bb          	subw	a3,s5,s3
    80003eaa:	8d3e                	mv	s10,a5
    80003eac:	2781                	sext.w	a5,a5
    80003eae:	0006861b          	sext.w	a2,a3
    80003eb2:	f8f679e3          	bgeu	a2,a5,80003e44 <readi+0x4c>
    80003eb6:	8d36                	mv	s10,a3
    80003eb8:	b771                	j	80003e44 <readi+0x4c>
      brelse(bp);
    80003eba:	854a                	mv	a0,s2
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	5a0080e7          	jalr	1440(ra) # 8000345c <brelse>
      tot = -1;
    80003ec4:	59fd                	li	s3,-1
  }
  return tot;
    80003ec6:	0009851b          	sext.w	a0,s3
}
    80003eca:	70a6                	ld	ra,104(sp)
    80003ecc:	7406                	ld	s0,96(sp)
    80003ece:	64e6                	ld	s1,88(sp)
    80003ed0:	6946                	ld	s2,80(sp)
    80003ed2:	69a6                	ld	s3,72(sp)
    80003ed4:	6a06                	ld	s4,64(sp)
    80003ed6:	7ae2                	ld	s5,56(sp)
    80003ed8:	7b42                	ld	s6,48(sp)
    80003eda:	7ba2                	ld	s7,40(sp)
    80003edc:	7c02                	ld	s8,32(sp)
    80003ede:	6ce2                	ld	s9,24(sp)
    80003ee0:	6d42                	ld	s10,16(sp)
    80003ee2:	6da2                	ld	s11,8(sp)
    80003ee4:	6165                	addi	sp,sp,112
    80003ee6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ee8:	89d6                	mv	s3,s5
    80003eea:	bff1                	j	80003ec6 <readi+0xce>
    return 0;
    80003eec:	4501                	li	a0,0
}
    80003eee:	8082                	ret

0000000080003ef0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ef0:	457c                	lw	a5,76(a0)
    80003ef2:	10d7e863          	bltu	a5,a3,80004002 <writei+0x112>
{
    80003ef6:	7159                	addi	sp,sp,-112
    80003ef8:	f486                	sd	ra,104(sp)
    80003efa:	f0a2                	sd	s0,96(sp)
    80003efc:	eca6                	sd	s1,88(sp)
    80003efe:	e8ca                	sd	s2,80(sp)
    80003f00:	e4ce                	sd	s3,72(sp)
    80003f02:	e0d2                	sd	s4,64(sp)
    80003f04:	fc56                	sd	s5,56(sp)
    80003f06:	f85a                	sd	s6,48(sp)
    80003f08:	f45e                	sd	s7,40(sp)
    80003f0a:	f062                	sd	s8,32(sp)
    80003f0c:	ec66                	sd	s9,24(sp)
    80003f0e:	e86a                	sd	s10,16(sp)
    80003f10:	e46e                	sd	s11,8(sp)
    80003f12:	1880                	addi	s0,sp,112
    80003f14:	8aaa                	mv	s5,a0
    80003f16:	8bae                	mv	s7,a1
    80003f18:	8a32                	mv	s4,a2
    80003f1a:	8936                	mv	s2,a3
    80003f1c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f1e:	00e687bb          	addw	a5,a3,a4
    80003f22:	0ed7e263          	bltu	a5,a3,80004006 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f26:	00043737          	lui	a4,0x43
    80003f2a:	0ef76063          	bltu	a4,a5,8000400a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f2e:	0c0b0863          	beqz	s6,80003ffe <writei+0x10e>
    80003f32:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f34:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f38:	5c7d                	li	s8,-1
    80003f3a:	a091                	j	80003f7e <writei+0x8e>
    80003f3c:	020d1d93          	slli	s11,s10,0x20
    80003f40:	020ddd93          	srli	s11,s11,0x20
    80003f44:	05848513          	addi	a0,s1,88
    80003f48:	86ee                	mv	a3,s11
    80003f4a:	8652                	mv	a2,s4
    80003f4c:	85de                	mv	a1,s7
    80003f4e:	953a                	add	a0,a0,a4
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	884080e7          	jalr	-1916(ra) # 800027d4 <either_copyin>
    80003f58:	07850263          	beq	a0,s8,80003fbc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	788080e7          	jalr	1928(ra) # 800046e6 <log_write>
    brelse(bp);
    80003f66:	8526                	mv	a0,s1
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	4f4080e7          	jalr	1268(ra) # 8000345c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f70:	013d09bb          	addw	s3,s10,s3
    80003f74:	012d093b          	addw	s2,s10,s2
    80003f78:	9a6e                	add	s4,s4,s11
    80003f7a:	0569f663          	bgeu	s3,s6,80003fc6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f7e:	00a9559b          	srliw	a1,s2,0xa
    80003f82:	8556                	mv	a0,s5
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	79c080e7          	jalr	1948(ra) # 80003720 <bmap>
    80003f8c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f90:	c99d                	beqz	a1,80003fc6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f92:	000aa503          	lw	a0,0(s5)
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	396080e7          	jalr	918(ra) # 8000332c <bread>
    80003f9e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fa0:	3ff97713          	andi	a4,s2,1023
    80003fa4:	40ec87bb          	subw	a5,s9,a4
    80003fa8:	413b06bb          	subw	a3,s6,s3
    80003fac:	8d3e                	mv	s10,a5
    80003fae:	2781                	sext.w	a5,a5
    80003fb0:	0006861b          	sext.w	a2,a3
    80003fb4:	f8f674e3          	bgeu	a2,a5,80003f3c <writei+0x4c>
    80003fb8:	8d36                	mv	s10,a3
    80003fba:	b749                	j	80003f3c <writei+0x4c>
      brelse(bp);
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	49e080e7          	jalr	1182(ra) # 8000345c <brelse>
  }

  if(off > ip->size)
    80003fc6:	04caa783          	lw	a5,76(s5)
    80003fca:	0127f463          	bgeu	a5,s2,80003fd2 <writei+0xe2>
    ip->size = off;
    80003fce:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003fd2:	8556                	mv	a0,s5
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	aa4080e7          	jalr	-1372(ra) # 80003a78 <iupdate>

  return tot;
    80003fdc:	0009851b          	sext.w	a0,s3
}
    80003fe0:	70a6                	ld	ra,104(sp)
    80003fe2:	7406                	ld	s0,96(sp)
    80003fe4:	64e6                	ld	s1,88(sp)
    80003fe6:	6946                	ld	s2,80(sp)
    80003fe8:	69a6                	ld	s3,72(sp)
    80003fea:	6a06                	ld	s4,64(sp)
    80003fec:	7ae2                	ld	s5,56(sp)
    80003fee:	7b42                	ld	s6,48(sp)
    80003ff0:	7ba2                	ld	s7,40(sp)
    80003ff2:	7c02                	ld	s8,32(sp)
    80003ff4:	6ce2                	ld	s9,24(sp)
    80003ff6:	6d42                	ld	s10,16(sp)
    80003ff8:	6da2                	ld	s11,8(sp)
    80003ffa:	6165                	addi	sp,sp,112
    80003ffc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ffe:	89da                	mv	s3,s6
    80004000:	bfc9                	j	80003fd2 <writei+0xe2>
    return -1;
    80004002:	557d                	li	a0,-1
}
    80004004:	8082                	ret
    return -1;
    80004006:	557d                	li	a0,-1
    80004008:	bfe1                	j	80003fe0 <writei+0xf0>
    return -1;
    8000400a:	557d                	li	a0,-1
    8000400c:	bfd1                	j	80003fe0 <writei+0xf0>

000000008000400e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000400e:	1141                	addi	sp,sp,-16
    80004010:	e406                	sd	ra,8(sp)
    80004012:	e022                	sd	s0,0(sp)
    80004014:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004016:	4639                	li	a2,14
    80004018:	ffffd097          	auipc	ra,0xffffd
    8000401c:	d8a080e7          	jalr	-630(ra) # 80000da2 <strncmp>
}
    80004020:	60a2                	ld	ra,8(sp)
    80004022:	6402                	ld	s0,0(sp)
    80004024:	0141                	addi	sp,sp,16
    80004026:	8082                	ret

0000000080004028 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004028:	7139                	addi	sp,sp,-64
    8000402a:	fc06                	sd	ra,56(sp)
    8000402c:	f822                	sd	s0,48(sp)
    8000402e:	f426                	sd	s1,40(sp)
    80004030:	f04a                	sd	s2,32(sp)
    80004032:	ec4e                	sd	s3,24(sp)
    80004034:	e852                	sd	s4,16(sp)
    80004036:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004038:	04451703          	lh	a4,68(a0)
    8000403c:	4785                	li	a5,1
    8000403e:	00f71a63          	bne	a4,a5,80004052 <dirlookup+0x2a>
    80004042:	892a                	mv	s2,a0
    80004044:	89ae                	mv	s3,a1
    80004046:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004048:	457c                	lw	a5,76(a0)
    8000404a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000404c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000404e:	e79d                	bnez	a5,8000407c <dirlookup+0x54>
    80004050:	a8a5                	j	800040c8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004052:	00004517          	auipc	a0,0x4
    80004056:	68e50513          	addi	a0,a0,1678 # 800086e0 <syscalls+0x1c0>
    8000405a:	ffffc097          	auipc	ra,0xffffc
    8000405e:	4e6080e7          	jalr	1254(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004062:	00004517          	auipc	a0,0x4
    80004066:	69650513          	addi	a0,a0,1686 # 800086f8 <syscalls+0x1d8>
    8000406a:	ffffc097          	auipc	ra,0xffffc
    8000406e:	4d6080e7          	jalr	1238(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004072:	24c1                	addiw	s1,s1,16
    80004074:	04c92783          	lw	a5,76(s2)
    80004078:	04f4f763          	bgeu	s1,a5,800040c6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000407c:	4741                	li	a4,16
    8000407e:	86a6                	mv	a3,s1
    80004080:	fc040613          	addi	a2,s0,-64
    80004084:	4581                	li	a1,0
    80004086:	854a                	mv	a0,s2
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	d70080e7          	jalr	-656(ra) # 80003df8 <readi>
    80004090:	47c1                	li	a5,16
    80004092:	fcf518e3          	bne	a0,a5,80004062 <dirlookup+0x3a>
    if(de.inum == 0)
    80004096:	fc045783          	lhu	a5,-64(s0)
    8000409a:	dfe1                	beqz	a5,80004072 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000409c:	fc240593          	addi	a1,s0,-62
    800040a0:	854e                	mv	a0,s3
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	f6c080e7          	jalr	-148(ra) # 8000400e <namecmp>
    800040aa:	f561                	bnez	a0,80004072 <dirlookup+0x4a>
      if(poff)
    800040ac:	000a0463          	beqz	s4,800040b4 <dirlookup+0x8c>
        *poff = off;
    800040b0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040b4:	fc045583          	lhu	a1,-64(s0)
    800040b8:	00092503          	lw	a0,0(s2)
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	74e080e7          	jalr	1870(ra) # 8000380a <iget>
    800040c4:	a011                	j	800040c8 <dirlookup+0xa0>
  return 0;
    800040c6:	4501                	li	a0,0
}
    800040c8:	70e2                	ld	ra,56(sp)
    800040ca:	7442                	ld	s0,48(sp)
    800040cc:	74a2                	ld	s1,40(sp)
    800040ce:	7902                	ld	s2,32(sp)
    800040d0:	69e2                	ld	s3,24(sp)
    800040d2:	6a42                	ld	s4,16(sp)
    800040d4:	6121                	addi	sp,sp,64
    800040d6:	8082                	ret

00000000800040d8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040d8:	711d                	addi	sp,sp,-96
    800040da:	ec86                	sd	ra,88(sp)
    800040dc:	e8a2                	sd	s0,80(sp)
    800040de:	e4a6                	sd	s1,72(sp)
    800040e0:	e0ca                	sd	s2,64(sp)
    800040e2:	fc4e                	sd	s3,56(sp)
    800040e4:	f852                	sd	s4,48(sp)
    800040e6:	f456                	sd	s5,40(sp)
    800040e8:	f05a                	sd	s6,32(sp)
    800040ea:	ec5e                	sd	s7,24(sp)
    800040ec:	e862                	sd	s8,16(sp)
    800040ee:	e466                	sd	s9,8(sp)
    800040f0:	e06a                	sd	s10,0(sp)
    800040f2:	1080                	addi	s0,sp,96
    800040f4:	84aa                	mv	s1,a0
    800040f6:	8b2e                	mv	s6,a1
    800040f8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040fa:	00054703          	lbu	a4,0(a0)
    800040fe:	02f00793          	li	a5,47
    80004102:	02f70363          	beq	a4,a5,80004128 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004106:	ffffe097          	auipc	ra,0xffffe
    8000410a:	ab0080e7          	jalr	-1360(ra) # 80001bb6 <myproc>
    8000410e:	15853503          	ld	a0,344(a0)
    80004112:	00000097          	auipc	ra,0x0
    80004116:	9f4080e7          	jalr	-1548(ra) # 80003b06 <idup>
    8000411a:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000411c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004120:	4cb5                	li	s9,13
  len = path - s;
    80004122:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004124:	4c05                	li	s8,1
    80004126:	a87d                	j	800041e4 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004128:	4585                	li	a1,1
    8000412a:	4505                	li	a0,1
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	6de080e7          	jalr	1758(ra) # 8000380a <iget>
    80004134:	8a2a                	mv	s4,a0
    80004136:	b7dd                	j	8000411c <namex+0x44>
      iunlockput(ip);
    80004138:	8552                	mv	a0,s4
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	c6c080e7          	jalr	-916(ra) # 80003da6 <iunlockput>
      return 0;
    80004142:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004144:	8552                	mv	a0,s4
    80004146:	60e6                	ld	ra,88(sp)
    80004148:	6446                	ld	s0,80(sp)
    8000414a:	64a6                	ld	s1,72(sp)
    8000414c:	6906                	ld	s2,64(sp)
    8000414e:	79e2                	ld	s3,56(sp)
    80004150:	7a42                	ld	s4,48(sp)
    80004152:	7aa2                	ld	s5,40(sp)
    80004154:	7b02                	ld	s6,32(sp)
    80004156:	6be2                	ld	s7,24(sp)
    80004158:	6c42                	ld	s8,16(sp)
    8000415a:	6ca2                	ld	s9,8(sp)
    8000415c:	6d02                	ld	s10,0(sp)
    8000415e:	6125                	addi	sp,sp,96
    80004160:	8082                	ret
      iunlock(ip);
    80004162:	8552                	mv	a0,s4
    80004164:	00000097          	auipc	ra,0x0
    80004168:	aa2080e7          	jalr	-1374(ra) # 80003c06 <iunlock>
      return ip;
    8000416c:	bfe1                	j	80004144 <namex+0x6c>
      iunlockput(ip);
    8000416e:	8552                	mv	a0,s4
    80004170:	00000097          	auipc	ra,0x0
    80004174:	c36080e7          	jalr	-970(ra) # 80003da6 <iunlockput>
      return 0;
    80004178:	8a4e                	mv	s4,s3
    8000417a:	b7e9                	j	80004144 <namex+0x6c>
  len = path - s;
    8000417c:	40998633          	sub	a2,s3,s1
    80004180:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004184:	09acd863          	bge	s9,s10,80004214 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004188:	4639                	li	a2,14
    8000418a:	85a6                	mv	a1,s1
    8000418c:	8556                	mv	a0,s5
    8000418e:	ffffd097          	auipc	ra,0xffffd
    80004192:	ba0080e7          	jalr	-1120(ra) # 80000d2e <memmove>
    80004196:	84ce                	mv	s1,s3
  while(*path == '/')
    80004198:	0004c783          	lbu	a5,0(s1)
    8000419c:	01279763          	bne	a5,s2,800041aa <namex+0xd2>
    path++;
    800041a0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041a2:	0004c783          	lbu	a5,0(s1)
    800041a6:	ff278de3          	beq	a5,s2,800041a0 <namex+0xc8>
    ilock(ip);
    800041aa:	8552                	mv	a0,s4
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	998080e7          	jalr	-1640(ra) # 80003b44 <ilock>
    if(ip->type != T_DIR){
    800041b4:	044a1783          	lh	a5,68(s4)
    800041b8:	f98790e3          	bne	a5,s8,80004138 <namex+0x60>
    if(nameiparent && *path == '\0'){
    800041bc:	000b0563          	beqz	s6,800041c6 <namex+0xee>
    800041c0:	0004c783          	lbu	a5,0(s1)
    800041c4:	dfd9                	beqz	a5,80004162 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041c6:	865e                	mv	a2,s7
    800041c8:	85d6                	mv	a1,s5
    800041ca:	8552                	mv	a0,s4
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	e5c080e7          	jalr	-420(ra) # 80004028 <dirlookup>
    800041d4:	89aa                	mv	s3,a0
    800041d6:	dd41                	beqz	a0,8000416e <namex+0x96>
    iunlockput(ip);
    800041d8:	8552                	mv	a0,s4
    800041da:	00000097          	auipc	ra,0x0
    800041de:	bcc080e7          	jalr	-1076(ra) # 80003da6 <iunlockput>
    ip = next;
    800041e2:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041e4:	0004c783          	lbu	a5,0(s1)
    800041e8:	01279763          	bne	a5,s2,800041f6 <namex+0x11e>
    path++;
    800041ec:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ee:	0004c783          	lbu	a5,0(s1)
    800041f2:	ff278de3          	beq	a5,s2,800041ec <namex+0x114>
  if(*path == 0)
    800041f6:	cb9d                	beqz	a5,8000422c <namex+0x154>
  while(*path != '/' && *path != 0)
    800041f8:	0004c783          	lbu	a5,0(s1)
    800041fc:	89a6                	mv	s3,s1
  len = path - s;
    800041fe:	8d5e                	mv	s10,s7
    80004200:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004202:	01278963          	beq	a5,s2,80004214 <namex+0x13c>
    80004206:	dbbd                	beqz	a5,8000417c <namex+0xa4>
    path++;
    80004208:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000420a:	0009c783          	lbu	a5,0(s3)
    8000420e:	ff279ce3          	bne	a5,s2,80004206 <namex+0x12e>
    80004212:	b7ad                	j	8000417c <namex+0xa4>
    memmove(name, s, len);
    80004214:	2601                	sext.w	a2,a2
    80004216:	85a6                	mv	a1,s1
    80004218:	8556                	mv	a0,s5
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	b14080e7          	jalr	-1260(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004222:	9d56                	add	s10,s10,s5
    80004224:	000d0023          	sb	zero,0(s10)
    80004228:	84ce                	mv	s1,s3
    8000422a:	b7bd                	j	80004198 <namex+0xc0>
  if(nameiparent){
    8000422c:	f00b0ce3          	beqz	s6,80004144 <namex+0x6c>
    iput(ip);
    80004230:	8552                	mv	a0,s4
    80004232:	00000097          	auipc	ra,0x0
    80004236:	acc080e7          	jalr	-1332(ra) # 80003cfe <iput>
    return 0;
    8000423a:	4a01                	li	s4,0
    8000423c:	b721                	j	80004144 <namex+0x6c>

000000008000423e <dirlink>:
{
    8000423e:	7139                	addi	sp,sp,-64
    80004240:	fc06                	sd	ra,56(sp)
    80004242:	f822                	sd	s0,48(sp)
    80004244:	f426                	sd	s1,40(sp)
    80004246:	f04a                	sd	s2,32(sp)
    80004248:	ec4e                	sd	s3,24(sp)
    8000424a:	e852                	sd	s4,16(sp)
    8000424c:	0080                	addi	s0,sp,64
    8000424e:	892a                	mv	s2,a0
    80004250:	8a2e                	mv	s4,a1
    80004252:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004254:	4601                	li	a2,0
    80004256:	00000097          	auipc	ra,0x0
    8000425a:	dd2080e7          	jalr	-558(ra) # 80004028 <dirlookup>
    8000425e:	e93d                	bnez	a0,800042d4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004260:	04c92483          	lw	s1,76(s2)
    80004264:	c49d                	beqz	s1,80004292 <dirlink+0x54>
    80004266:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004268:	4741                	li	a4,16
    8000426a:	86a6                	mv	a3,s1
    8000426c:	fc040613          	addi	a2,s0,-64
    80004270:	4581                	li	a1,0
    80004272:	854a                	mv	a0,s2
    80004274:	00000097          	auipc	ra,0x0
    80004278:	b84080e7          	jalr	-1148(ra) # 80003df8 <readi>
    8000427c:	47c1                	li	a5,16
    8000427e:	06f51163          	bne	a0,a5,800042e0 <dirlink+0xa2>
    if(de.inum == 0)
    80004282:	fc045783          	lhu	a5,-64(s0)
    80004286:	c791                	beqz	a5,80004292 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004288:	24c1                	addiw	s1,s1,16
    8000428a:	04c92783          	lw	a5,76(s2)
    8000428e:	fcf4ede3          	bltu	s1,a5,80004268 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004292:	4639                	li	a2,14
    80004294:	85d2                	mv	a1,s4
    80004296:	fc240513          	addi	a0,s0,-62
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	b44080e7          	jalr	-1212(ra) # 80000dde <strncpy>
  de.inum = inum;
    800042a2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042a6:	4741                	li	a4,16
    800042a8:	86a6                	mv	a3,s1
    800042aa:	fc040613          	addi	a2,s0,-64
    800042ae:	4581                	li	a1,0
    800042b0:	854a                	mv	a0,s2
    800042b2:	00000097          	auipc	ra,0x0
    800042b6:	c3e080e7          	jalr	-962(ra) # 80003ef0 <writei>
    800042ba:	1541                	addi	a0,a0,-16
    800042bc:	00a03533          	snez	a0,a0
    800042c0:	40a00533          	neg	a0,a0
}
    800042c4:	70e2                	ld	ra,56(sp)
    800042c6:	7442                	ld	s0,48(sp)
    800042c8:	74a2                	ld	s1,40(sp)
    800042ca:	7902                	ld	s2,32(sp)
    800042cc:	69e2                	ld	s3,24(sp)
    800042ce:	6a42                	ld	s4,16(sp)
    800042d0:	6121                	addi	sp,sp,64
    800042d2:	8082                	ret
    iput(ip);
    800042d4:	00000097          	auipc	ra,0x0
    800042d8:	a2a080e7          	jalr	-1494(ra) # 80003cfe <iput>
    return -1;
    800042dc:	557d                	li	a0,-1
    800042de:	b7dd                	j	800042c4 <dirlink+0x86>
      panic("dirlink read");
    800042e0:	00004517          	auipc	a0,0x4
    800042e4:	42850513          	addi	a0,a0,1064 # 80008708 <syscalls+0x1e8>
    800042e8:	ffffc097          	auipc	ra,0xffffc
    800042ec:	258080e7          	jalr	600(ra) # 80000540 <panic>

00000000800042f0 <namei>:

struct inode*
namei(char *path)
{
    800042f0:	1101                	addi	sp,sp,-32
    800042f2:	ec06                	sd	ra,24(sp)
    800042f4:	e822                	sd	s0,16(sp)
    800042f6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042f8:	fe040613          	addi	a2,s0,-32
    800042fc:	4581                	li	a1,0
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	dda080e7          	jalr	-550(ra) # 800040d8 <namex>
}
    80004306:	60e2                	ld	ra,24(sp)
    80004308:	6442                	ld	s0,16(sp)
    8000430a:	6105                	addi	sp,sp,32
    8000430c:	8082                	ret

000000008000430e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000430e:	1141                	addi	sp,sp,-16
    80004310:	e406                	sd	ra,8(sp)
    80004312:	e022                	sd	s0,0(sp)
    80004314:	0800                	addi	s0,sp,16
    80004316:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004318:	4585                	li	a1,1
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	dbe080e7          	jalr	-578(ra) # 800040d8 <namex>
}
    80004322:	60a2                	ld	ra,8(sp)
    80004324:	6402                	ld	s0,0(sp)
    80004326:	0141                	addi	sp,sp,16
    80004328:	8082                	ret

000000008000432a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000432a:	1101                	addi	sp,sp,-32
    8000432c:	ec06                	sd	ra,24(sp)
    8000432e:	e822                	sd	s0,16(sp)
    80004330:	e426                	sd	s1,8(sp)
    80004332:	e04a                	sd	s2,0(sp)
    80004334:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004336:	0001d917          	auipc	s2,0x1d
    8000433a:	b2a90913          	addi	s2,s2,-1238 # 80020e60 <log>
    8000433e:	01892583          	lw	a1,24(s2)
    80004342:	02892503          	lw	a0,40(s2)
    80004346:	fffff097          	auipc	ra,0xfffff
    8000434a:	fe6080e7          	jalr	-26(ra) # 8000332c <bread>
    8000434e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004350:	02c92683          	lw	a3,44(s2)
    80004354:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004356:	02d05863          	blez	a3,80004386 <write_head+0x5c>
    8000435a:	0001d797          	auipc	a5,0x1d
    8000435e:	b3678793          	addi	a5,a5,-1226 # 80020e90 <log+0x30>
    80004362:	05c50713          	addi	a4,a0,92
    80004366:	36fd                	addiw	a3,a3,-1
    80004368:	02069613          	slli	a2,a3,0x20
    8000436c:	01e65693          	srli	a3,a2,0x1e
    80004370:	0001d617          	auipc	a2,0x1d
    80004374:	b2460613          	addi	a2,a2,-1244 # 80020e94 <log+0x34>
    80004378:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000437a:	4390                	lw	a2,0(a5)
    8000437c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000437e:	0791                	addi	a5,a5,4
    80004380:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004382:	fed79ce3          	bne	a5,a3,8000437a <write_head+0x50>
  }
  bwrite(buf);
    80004386:	8526                	mv	a0,s1
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	096080e7          	jalr	150(ra) # 8000341e <bwrite>
  brelse(buf);
    80004390:	8526                	mv	a0,s1
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	0ca080e7          	jalr	202(ra) # 8000345c <brelse>
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	64a2                	ld	s1,8(sp)
    800043a0:	6902                	ld	s2,0(sp)
    800043a2:	6105                	addi	sp,sp,32
    800043a4:	8082                	ret

00000000800043a6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a6:	0001d797          	auipc	a5,0x1d
    800043aa:	ae67a783          	lw	a5,-1306(a5) # 80020e8c <log+0x2c>
    800043ae:	0af05d63          	blez	a5,80004468 <install_trans+0xc2>
{
    800043b2:	7139                	addi	sp,sp,-64
    800043b4:	fc06                	sd	ra,56(sp)
    800043b6:	f822                	sd	s0,48(sp)
    800043b8:	f426                	sd	s1,40(sp)
    800043ba:	f04a                	sd	s2,32(sp)
    800043bc:	ec4e                	sd	s3,24(sp)
    800043be:	e852                	sd	s4,16(sp)
    800043c0:	e456                	sd	s5,8(sp)
    800043c2:	e05a                	sd	s6,0(sp)
    800043c4:	0080                	addi	s0,sp,64
    800043c6:	8b2a                	mv	s6,a0
    800043c8:	0001da97          	auipc	s5,0x1d
    800043cc:	ac8a8a93          	addi	s5,s5,-1336 # 80020e90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043d2:	0001d997          	auipc	s3,0x1d
    800043d6:	a8e98993          	addi	s3,s3,-1394 # 80020e60 <log>
    800043da:	a00d                	j	800043fc <install_trans+0x56>
    brelse(lbuf);
    800043dc:	854a                	mv	a0,s2
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	07e080e7          	jalr	126(ra) # 8000345c <brelse>
    brelse(dbuf);
    800043e6:	8526                	mv	a0,s1
    800043e8:	fffff097          	auipc	ra,0xfffff
    800043ec:	074080e7          	jalr	116(ra) # 8000345c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f0:	2a05                	addiw	s4,s4,1
    800043f2:	0a91                	addi	s5,s5,4
    800043f4:	02c9a783          	lw	a5,44(s3)
    800043f8:	04fa5e63          	bge	s4,a5,80004454 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043fc:	0189a583          	lw	a1,24(s3)
    80004400:	014585bb          	addw	a1,a1,s4
    80004404:	2585                	addiw	a1,a1,1
    80004406:	0289a503          	lw	a0,40(s3)
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	f22080e7          	jalr	-222(ra) # 8000332c <bread>
    80004412:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004414:	000aa583          	lw	a1,0(s5)
    80004418:	0289a503          	lw	a0,40(s3)
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	f10080e7          	jalr	-240(ra) # 8000332c <bread>
    80004424:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004426:	40000613          	li	a2,1024
    8000442a:	05890593          	addi	a1,s2,88
    8000442e:	05850513          	addi	a0,a0,88
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	8fc080e7          	jalr	-1796(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000443a:	8526                	mv	a0,s1
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	fe2080e7          	jalr	-30(ra) # 8000341e <bwrite>
    if(recovering == 0)
    80004444:	f80b1ce3          	bnez	s6,800043dc <install_trans+0x36>
      bunpin(dbuf);
    80004448:	8526                	mv	a0,s1
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	0ec080e7          	jalr	236(ra) # 80003536 <bunpin>
    80004452:	b769                	j	800043dc <install_trans+0x36>
}
    80004454:	70e2                	ld	ra,56(sp)
    80004456:	7442                	ld	s0,48(sp)
    80004458:	74a2                	ld	s1,40(sp)
    8000445a:	7902                	ld	s2,32(sp)
    8000445c:	69e2                	ld	s3,24(sp)
    8000445e:	6a42                	ld	s4,16(sp)
    80004460:	6aa2                	ld	s5,8(sp)
    80004462:	6b02                	ld	s6,0(sp)
    80004464:	6121                	addi	sp,sp,64
    80004466:	8082                	ret
    80004468:	8082                	ret

000000008000446a <initlog>:
{
    8000446a:	7179                	addi	sp,sp,-48
    8000446c:	f406                	sd	ra,40(sp)
    8000446e:	f022                	sd	s0,32(sp)
    80004470:	ec26                	sd	s1,24(sp)
    80004472:	e84a                	sd	s2,16(sp)
    80004474:	e44e                	sd	s3,8(sp)
    80004476:	1800                	addi	s0,sp,48
    80004478:	892a                	mv	s2,a0
    8000447a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000447c:	0001d497          	auipc	s1,0x1d
    80004480:	9e448493          	addi	s1,s1,-1564 # 80020e60 <log>
    80004484:	00004597          	auipc	a1,0x4
    80004488:	29458593          	addi	a1,a1,660 # 80008718 <syscalls+0x1f8>
    8000448c:	8526                	mv	a0,s1
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	6b8080e7          	jalr	1720(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004496:	0149a583          	lw	a1,20(s3)
    8000449a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000449c:	0109a783          	lw	a5,16(s3)
    800044a0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044a2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044a6:	854a                	mv	a0,s2
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	e84080e7          	jalr	-380(ra) # 8000332c <bread>
  log.lh.n = lh->n;
    800044b0:	4d34                	lw	a3,88(a0)
    800044b2:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044b4:	02d05663          	blez	a3,800044e0 <initlog+0x76>
    800044b8:	05c50793          	addi	a5,a0,92
    800044bc:	0001d717          	auipc	a4,0x1d
    800044c0:	9d470713          	addi	a4,a4,-1580 # 80020e90 <log+0x30>
    800044c4:	36fd                	addiw	a3,a3,-1
    800044c6:	02069613          	slli	a2,a3,0x20
    800044ca:	01e65693          	srli	a3,a2,0x1e
    800044ce:	06050613          	addi	a2,a0,96
    800044d2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800044d4:	4390                	lw	a2,0(a5)
    800044d6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044d8:	0791                	addi	a5,a5,4
    800044da:	0711                	addi	a4,a4,4
    800044dc:	fed79ce3          	bne	a5,a3,800044d4 <initlog+0x6a>
  brelse(buf);
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	f7c080e7          	jalr	-132(ra) # 8000345c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044e8:	4505                	li	a0,1
    800044ea:	00000097          	auipc	ra,0x0
    800044ee:	ebc080e7          	jalr	-324(ra) # 800043a6 <install_trans>
  log.lh.n = 0;
    800044f2:	0001d797          	auipc	a5,0x1d
    800044f6:	9807ad23          	sw	zero,-1638(a5) # 80020e8c <log+0x2c>
  write_head(); // clear the log
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	e30080e7          	jalr	-464(ra) # 8000432a <write_head>
}
    80004502:	70a2                	ld	ra,40(sp)
    80004504:	7402                	ld	s0,32(sp)
    80004506:	64e2                	ld	s1,24(sp)
    80004508:	6942                	ld	s2,16(sp)
    8000450a:	69a2                	ld	s3,8(sp)
    8000450c:	6145                	addi	sp,sp,48
    8000450e:	8082                	ret

0000000080004510 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004510:	1101                	addi	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	e04a                	sd	s2,0(sp)
    8000451a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000451c:	0001d517          	auipc	a0,0x1d
    80004520:	94450513          	addi	a0,a0,-1724 # 80020e60 <log>
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	6b2080e7          	jalr	1714(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000452c:	0001d497          	auipc	s1,0x1d
    80004530:	93448493          	addi	s1,s1,-1740 # 80020e60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004534:	4979                	li	s2,30
    80004536:	a039                	j	80004544 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004538:	85a6                	mv	a1,s1
    8000453a:	8526                	mv	a0,s1
    8000453c:	ffffe097          	auipc	ra,0xffffe
    80004540:	e3a080e7          	jalr	-454(ra) # 80002376 <sleep>
    if(log.committing){
    80004544:	50dc                	lw	a5,36(s1)
    80004546:	fbed                	bnez	a5,80004538 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004548:	5098                	lw	a4,32(s1)
    8000454a:	2705                	addiw	a4,a4,1
    8000454c:	0007069b          	sext.w	a3,a4
    80004550:	0027179b          	slliw	a5,a4,0x2
    80004554:	9fb9                	addw	a5,a5,a4
    80004556:	0017979b          	slliw	a5,a5,0x1
    8000455a:	54d8                	lw	a4,44(s1)
    8000455c:	9fb9                	addw	a5,a5,a4
    8000455e:	00f95963          	bge	s2,a5,80004570 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004562:	85a6                	mv	a1,s1
    80004564:	8526                	mv	a0,s1
    80004566:	ffffe097          	auipc	ra,0xffffe
    8000456a:	e10080e7          	jalr	-496(ra) # 80002376 <sleep>
    8000456e:	bfd9                	j	80004544 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004570:	0001d517          	auipc	a0,0x1d
    80004574:	8f050513          	addi	a0,a0,-1808 # 80020e60 <log>
    80004578:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	710080e7          	jalr	1808(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6902                	ld	s2,0(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret

000000008000458e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000458e:	7139                	addi	sp,sp,-64
    80004590:	fc06                	sd	ra,56(sp)
    80004592:	f822                	sd	s0,48(sp)
    80004594:	f426                	sd	s1,40(sp)
    80004596:	f04a                	sd	s2,32(sp)
    80004598:	ec4e                	sd	s3,24(sp)
    8000459a:	e852                	sd	s4,16(sp)
    8000459c:	e456                	sd	s5,8(sp)
    8000459e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045a0:	0001d497          	auipc	s1,0x1d
    800045a4:	8c048493          	addi	s1,s1,-1856 # 80020e60 <log>
    800045a8:	8526                	mv	a0,s1
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	62c080e7          	jalr	1580(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800045b2:	509c                	lw	a5,32(s1)
    800045b4:	37fd                	addiw	a5,a5,-1
    800045b6:	0007891b          	sext.w	s2,a5
    800045ba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045bc:	50dc                	lw	a5,36(s1)
    800045be:	e7b9                	bnez	a5,8000460c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045c0:	04091e63          	bnez	s2,8000461c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800045c4:	0001d497          	auipc	s1,0x1d
    800045c8:	89c48493          	addi	s1,s1,-1892 # 80020e60 <log>
    800045cc:	4785                	li	a5,1
    800045ce:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045d0:	8526                	mv	a0,s1
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	6b8080e7          	jalr	1720(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045da:	54dc                	lw	a5,44(s1)
    800045dc:	06f04763          	bgtz	a5,8000464a <end_op+0xbc>
    acquire(&log.lock);
    800045e0:	0001d497          	auipc	s1,0x1d
    800045e4:	88048493          	addi	s1,s1,-1920 # 80020e60 <log>
    800045e8:	8526                	mv	a0,s1
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	5ec080e7          	jalr	1516(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800045f2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045f6:	8526                	mv	a0,s1
    800045f8:	ffffe097          	auipc	ra,0xffffe
    800045fc:	de2080e7          	jalr	-542(ra) # 800023da <wakeup>
    release(&log.lock);
    80004600:	8526                	mv	a0,s1
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	688080e7          	jalr	1672(ra) # 80000c8a <release>
}
    8000460a:	a03d                	j	80004638 <end_op+0xaa>
    panic("log.committing");
    8000460c:	00004517          	auipc	a0,0x4
    80004610:	11450513          	addi	a0,a0,276 # 80008720 <syscalls+0x200>
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
    wakeup(&log);
    8000461c:	0001d497          	auipc	s1,0x1d
    80004620:	84448493          	addi	s1,s1,-1980 # 80020e60 <log>
    80004624:	8526                	mv	a0,s1
    80004626:	ffffe097          	auipc	ra,0xffffe
    8000462a:	db4080e7          	jalr	-588(ra) # 800023da <wakeup>
  release(&log.lock);
    8000462e:	8526                	mv	a0,s1
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	65a080e7          	jalr	1626(ra) # 80000c8a <release>
}
    80004638:	70e2                	ld	ra,56(sp)
    8000463a:	7442                	ld	s0,48(sp)
    8000463c:	74a2                	ld	s1,40(sp)
    8000463e:	7902                	ld	s2,32(sp)
    80004640:	69e2                	ld	s3,24(sp)
    80004642:	6a42                	ld	s4,16(sp)
    80004644:	6aa2                	ld	s5,8(sp)
    80004646:	6121                	addi	sp,sp,64
    80004648:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000464a:	0001da97          	auipc	s5,0x1d
    8000464e:	846a8a93          	addi	s5,s5,-1978 # 80020e90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004652:	0001da17          	auipc	s4,0x1d
    80004656:	80ea0a13          	addi	s4,s4,-2034 # 80020e60 <log>
    8000465a:	018a2583          	lw	a1,24(s4)
    8000465e:	012585bb          	addw	a1,a1,s2
    80004662:	2585                	addiw	a1,a1,1
    80004664:	028a2503          	lw	a0,40(s4)
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	cc4080e7          	jalr	-828(ra) # 8000332c <bread>
    80004670:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004672:	000aa583          	lw	a1,0(s5)
    80004676:	028a2503          	lw	a0,40(s4)
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	cb2080e7          	jalr	-846(ra) # 8000332c <bread>
    80004682:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004684:	40000613          	li	a2,1024
    80004688:	05850593          	addi	a1,a0,88
    8000468c:	05848513          	addi	a0,s1,88
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	69e080e7          	jalr	1694(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004698:	8526                	mv	a0,s1
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	d84080e7          	jalr	-636(ra) # 8000341e <bwrite>
    brelse(from);
    800046a2:	854e                	mv	a0,s3
    800046a4:	fffff097          	auipc	ra,0xfffff
    800046a8:	db8080e7          	jalr	-584(ra) # 8000345c <brelse>
    brelse(to);
    800046ac:	8526                	mv	a0,s1
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	dae080e7          	jalr	-594(ra) # 8000345c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046b6:	2905                	addiw	s2,s2,1
    800046b8:	0a91                	addi	s5,s5,4
    800046ba:	02ca2783          	lw	a5,44(s4)
    800046be:	f8f94ee3          	blt	s2,a5,8000465a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	c68080e7          	jalr	-920(ra) # 8000432a <write_head>
    install_trans(0); // Now install writes to home locations
    800046ca:	4501                	li	a0,0
    800046cc:	00000097          	auipc	ra,0x0
    800046d0:	cda080e7          	jalr	-806(ra) # 800043a6 <install_trans>
    log.lh.n = 0;
    800046d4:	0001c797          	auipc	a5,0x1c
    800046d8:	7a07ac23          	sw	zero,1976(a5) # 80020e8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	c4e080e7          	jalr	-946(ra) # 8000432a <write_head>
    800046e4:	bdf5                	j	800045e0 <end_op+0x52>

00000000800046e6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046e6:	1101                	addi	sp,sp,-32
    800046e8:	ec06                	sd	ra,24(sp)
    800046ea:	e822                	sd	s0,16(sp)
    800046ec:	e426                	sd	s1,8(sp)
    800046ee:	e04a                	sd	s2,0(sp)
    800046f0:	1000                	addi	s0,sp,32
    800046f2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046f4:	0001c917          	auipc	s2,0x1c
    800046f8:	76c90913          	addi	s2,s2,1900 # 80020e60 <log>
    800046fc:	854a                	mv	a0,s2
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	4d8080e7          	jalr	1240(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004706:	02c92603          	lw	a2,44(s2)
    8000470a:	47f5                	li	a5,29
    8000470c:	06c7c563          	blt	a5,a2,80004776 <log_write+0x90>
    80004710:	0001c797          	auipc	a5,0x1c
    80004714:	76c7a783          	lw	a5,1900(a5) # 80020e7c <log+0x1c>
    80004718:	37fd                	addiw	a5,a5,-1
    8000471a:	04f65e63          	bge	a2,a5,80004776 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000471e:	0001c797          	auipc	a5,0x1c
    80004722:	7627a783          	lw	a5,1890(a5) # 80020e80 <log+0x20>
    80004726:	06f05063          	blez	a5,80004786 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000472a:	4781                	li	a5,0
    8000472c:	06c05563          	blez	a2,80004796 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004730:	44cc                	lw	a1,12(s1)
    80004732:	0001c717          	auipc	a4,0x1c
    80004736:	75e70713          	addi	a4,a4,1886 # 80020e90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000473a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000473c:	4314                	lw	a3,0(a4)
    8000473e:	04b68c63          	beq	a3,a1,80004796 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004742:	2785                	addiw	a5,a5,1
    80004744:	0711                	addi	a4,a4,4
    80004746:	fef61be3          	bne	a2,a5,8000473c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000474a:	0621                	addi	a2,a2,8
    8000474c:	060a                	slli	a2,a2,0x2
    8000474e:	0001c797          	auipc	a5,0x1c
    80004752:	71278793          	addi	a5,a5,1810 # 80020e60 <log>
    80004756:	97b2                	add	a5,a5,a2
    80004758:	44d8                	lw	a4,12(s1)
    8000475a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000475c:	8526                	mv	a0,s1
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	d9c080e7          	jalr	-612(ra) # 800034fa <bpin>
    log.lh.n++;
    80004766:	0001c717          	auipc	a4,0x1c
    8000476a:	6fa70713          	addi	a4,a4,1786 # 80020e60 <log>
    8000476e:	575c                	lw	a5,44(a4)
    80004770:	2785                	addiw	a5,a5,1
    80004772:	d75c                	sw	a5,44(a4)
    80004774:	a82d                	j	800047ae <log_write+0xc8>
    panic("too big a transaction");
    80004776:	00004517          	auipc	a0,0x4
    8000477a:	fba50513          	addi	a0,a0,-70 # 80008730 <syscalls+0x210>
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	dc2080e7          	jalr	-574(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004786:	00004517          	auipc	a0,0x4
    8000478a:	fc250513          	addi	a0,a0,-62 # 80008748 <syscalls+0x228>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	db2080e7          	jalr	-590(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004796:	00878693          	addi	a3,a5,8
    8000479a:	068a                	slli	a3,a3,0x2
    8000479c:	0001c717          	auipc	a4,0x1c
    800047a0:	6c470713          	addi	a4,a4,1732 # 80020e60 <log>
    800047a4:	9736                	add	a4,a4,a3
    800047a6:	44d4                	lw	a3,12(s1)
    800047a8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047aa:	faf609e3          	beq	a2,a5,8000475c <log_write+0x76>
  }
  release(&log.lock);
    800047ae:	0001c517          	auipc	a0,0x1c
    800047b2:	6b250513          	addi	a0,a0,1714 # 80020e60 <log>
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	4d4080e7          	jalr	1236(ra) # 80000c8a <release>
}
    800047be:	60e2                	ld	ra,24(sp)
    800047c0:	6442                	ld	s0,16(sp)
    800047c2:	64a2                	ld	s1,8(sp)
    800047c4:	6902                	ld	s2,0(sp)
    800047c6:	6105                	addi	sp,sp,32
    800047c8:	8082                	ret

00000000800047ca <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047ca:	1101                	addi	sp,sp,-32
    800047cc:	ec06                	sd	ra,24(sp)
    800047ce:	e822                	sd	s0,16(sp)
    800047d0:	e426                	sd	s1,8(sp)
    800047d2:	e04a                	sd	s2,0(sp)
    800047d4:	1000                	addi	s0,sp,32
    800047d6:	84aa                	mv	s1,a0
    800047d8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047da:	00004597          	auipc	a1,0x4
    800047de:	f8e58593          	addi	a1,a1,-114 # 80008768 <syscalls+0x248>
    800047e2:	0521                	addi	a0,a0,8
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	362080e7          	jalr	866(ra) # 80000b46 <initlock>
  lk->name = name;
    800047ec:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047f4:	0204a423          	sw	zero,40(s1)
}
    800047f8:	60e2                	ld	ra,24(sp)
    800047fa:	6442                	ld	s0,16(sp)
    800047fc:	64a2                	ld	s1,8(sp)
    800047fe:	6902                	ld	s2,0(sp)
    80004800:	6105                	addi	sp,sp,32
    80004802:	8082                	ret

0000000080004804 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004804:	1101                	addi	sp,sp,-32
    80004806:	ec06                	sd	ra,24(sp)
    80004808:	e822                	sd	s0,16(sp)
    8000480a:	e426                	sd	s1,8(sp)
    8000480c:	e04a                	sd	s2,0(sp)
    8000480e:	1000                	addi	s0,sp,32
    80004810:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004812:	00850913          	addi	s2,a0,8
    80004816:	854a                	mv	a0,s2
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	3be080e7          	jalr	958(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004820:	409c                	lw	a5,0(s1)
    80004822:	cb89                	beqz	a5,80004834 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004824:	85ca                	mv	a1,s2
    80004826:	8526                	mv	a0,s1
    80004828:	ffffe097          	auipc	ra,0xffffe
    8000482c:	b4e080e7          	jalr	-1202(ra) # 80002376 <sleep>
  while (lk->locked) {
    80004830:	409c                	lw	a5,0(s1)
    80004832:	fbed                	bnez	a5,80004824 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004834:	4785                	li	a5,1
    80004836:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004838:	ffffd097          	auipc	ra,0xffffd
    8000483c:	37e080e7          	jalr	894(ra) # 80001bb6 <myproc>
    80004840:	591c                	lw	a5,48(a0)
    80004842:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	444080e7          	jalr	1092(ra) # 80000c8a <release>
}
    8000484e:	60e2                	ld	ra,24(sp)
    80004850:	6442                	ld	s0,16(sp)
    80004852:	64a2                	ld	s1,8(sp)
    80004854:	6902                	ld	s2,0(sp)
    80004856:	6105                	addi	sp,sp,32
    80004858:	8082                	ret

000000008000485a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000485a:	1101                	addi	sp,sp,-32
    8000485c:	ec06                	sd	ra,24(sp)
    8000485e:	e822                	sd	s0,16(sp)
    80004860:	e426                	sd	s1,8(sp)
    80004862:	e04a                	sd	s2,0(sp)
    80004864:	1000                	addi	s0,sp,32
    80004866:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004868:	00850913          	addi	s2,a0,8
    8000486c:	854a                	mv	a0,s2
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	368080e7          	jalr	872(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004876:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000487a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000487e:	8526                	mv	a0,s1
    80004880:	ffffe097          	auipc	ra,0xffffe
    80004884:	b5a080e7          	jalr	-1190(ra) # 800023da <wakeup>
  release(&lk->lk);
    80004888:	854a                	mv	a0,s2
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	400080e7          	jalr	1024(ra) # 80000c8a <release>
}
    80004892:	60e2                	ld	ra,24(sp)
    80004894:	6442                	ld	s0,16(sp)
    80004896:	64a2                	ld	s1,8(sp)
    80004898:	6902                	ld	s2,0(sp)
    8000489a:	6105                	addi	sp,sp,32
    8000489c:	8082                	ret

000000008000489e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000489e:	7179                	addi	sp,sp,-48
    800048a0:	f406                	sd	ra,40(sp)
    800048a2:	f022                	sd	s0,32(sp)
    800048a4:	ec26                	sd	s1,24(sp)
    800048a6:	e84a                	sd	s2,16(sp)
    800048a8:	e44e                	sd	s3,8(sp)
    800048aa:	1800                	addi	s0,sp,48
    800048ac:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048ae:	00850913          	addi	s2,a0,8
    800048b2:	854a                	mv	a0,s2
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	322080e7          	jalr	802(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048bc:	409c                	lw	a5,0(s1)
    800048be:	ef99                	bnez	a5,800048dc <holdingsleep+0x3e>
    800048c0:	4481                	li	s1,0
  release(&lk->lk);
    800048c2:	854a                	mv	a0,s2
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	3c6080e7          	jalr	966(ra) # 80000c8a <release>
  return r;
}
    800048cc:	8526                	mv	a0,s1
    800048ce:	70a2                	ld	ra,40(sp)
    800048d0:	7402                	ld	s0,32(sp)
    800048d2:	64e2                	ld	s1,24(sp)
    800048d4:	6942                	ld	s2,16(sp)
    800048d6:	69a2                	ld	s3,8(sp)
    800048d8:	6145                	addi	sp,sp,48
    800048da:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048dc:	0284a983          	lw	s3,40(s1)
    800048e0:	ffffd097          	auipc	ra,0xffffd
    800048e4:	2d6080e7          	jalr	726(ra) # 80001bb6 <myproc>
    800048e8:	5904                	lw	s1,48(a0)
    800048ea:	413484b3          	sub	s1,s1,s3
    800048ee:	0014b493          	seqz	s1,s1
    800048f2:	bfc1                	j	800048c2 <holdingsleep+0x24>

00000000800048f4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048f4:	1141                	addi	sp,sp,-16
    800048f6:	e406                	sd	ra,8(sp)
    800048f8:	e022                	sd	s0,0(sp)
    800048fa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048fc:	00004597          	auipc	a1,0x4
    80004900:	e7c58593          	addi	a1,a1,-388 # 80008778 <syscalls+0x258>
    80004904:	0001c517          	auipc	a0,0x1c
    80004908:	6a450513          	addi	a0,a0,1700 # 80020fa8 <ftable>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	23a080e7          	jalr	570(ra) # 80000b46 <initlock>
}
    80004914:	60a2                	ld	ra,8(sp)
    80004916:	6402                	ld	s0,0(sp)
    80004918:	0141                	addi	sp,sp,16
    8000491a:	8082                	ret

000000008000491c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000491c:	1101                	addi	sp,sp,-32
    8000491e:	ec06                	sd	ra,24(sp)
    80004920:	e822                	sd	s0,16(sp)
    80004922:	e426                	sd	s1,8(sp)
    80004924:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004926:	0001c517          	auipc	a0,0x1c
    8000492a:	68250513          	addi	a0,a0,1666 # 80020fa8 <ftable>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	2a8080e7          	jalr	680(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004936:	0001c497          	auipc	s1,0x1c
    8000493a:	68a48493          	addi	s1,s1,1674 # 80020fc0 <ftable+0x18>
    8000493e:	0001d717          	auipc	a4,0x1d
    80004942:	62270713          	addi	a4,a4,1570 # 80021f60 <disk>
    if(f->ref == 0){
    80004946:	40dc                	lw	a5,4(s1)
    80004948:	cf99                	beqz	a5,80004966 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000494a:	02848493          	addi	s1,s1,40
    8000494e:	fee49ce3          	bne	s1,a4,80004946 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004952:	0001c517          	auipc	a0,0x1c
    80004956:	65650513          	addi	a0,a0,1622 # 80020fa8 <ftable>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	330080e7          	jalr	816(ra) # 80000c8a <release>
  return 0;
    80004962:	4481                	li	s1,0
    80004964:	a819                	j	8000497a <filealloc+0x5e>
      f->ref = 1;
    80004966:	4785                	li	a5,1
    80004968:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000496a:	0001c517          	auipc	a0,0x1c
    8000496e:	63e50513          	addi	a0,a0,1598 # 80020fa8 <ftable>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	318080e7          	jalr	792(ra) # 80000c8a <release>
}
    8000497a:	8526                	mv	a0,s1
    8000497c:	60e2                	ld	ra,24(sp)
    8000497e:	6442                	ld	s0,16(sp)
    80004980:	64a2                	ld	s1,8(sp)
    80004982:	6105                	addi	sp,sp,32
    80004984:	8082                	ret

0000000080004986 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004986:	1101                	addi	sp,sp,-32
    80004988:	ec06                	sd	ra,24(sp)
    8000498a:	e822                	sd	s0,16(sp)
    8000498c:	e426                	sd	s1,8(sp)
    8000498e:	1000                	addi	s0,sp,32
    80004990:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004992:	0001c517          	auipc	a0,0x1c
    80004996:	61650513          	addi	a0,a0,1558 # 80020fa8 <ftable>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	23c080e7          	jalr	572(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800049a2:	40dc                	lw	a5,4(s1)
    800049a4:	02f05263          	blez	a5,800049c8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049a8:	2785                	addiw	a5,a5,1
    800049aa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049ac:	0001c517          	auipc	a0,0x1c
    800049b0:	5fc50513          	addi	a0,a0,1532 # 80020fa8 <ftable>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2d6080e7          	jalr	726(ra) # 80000c8a <release>
  return f;
}
    800049bc:	8526                	mv	a0,s1
    800049be:	60e2                	ld	ra,24(sp)
    800049c0:	6442                	ld	s0,16(sp)
    800049c2:	64a2                	ld	s1,8(sp)
    800049c4:	6105                	addi	sp,sp,32
    800049c6:	8082                	ret
    panic("filedup");
    800049c8:	00004517          	auipc	a0,0x4
    800049cc:	db850513          	addi	a0,a0,-584 # 80008780 <syscalls+0x260>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	b70080e7          	jalr	-1168(ra) # 80000540 <panic>

00000000800049d8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049d8:	7139                	addi	sp,sp,-64
    800049da:	fc06                	sd	ra,56(sp)
    800049dc:	f822                	sd	s0,48(sp)
    800049de:	f426                	sd	s1,40(sp)
    800049e0:	f04a                	sd	s2,32(sp)
    800049e2:	ec4e                	sd	s3,24(sp)
    800049e4:	e852                	sd	s4,16(sp)
    800049e6:	e456                	sd	s5,8(sp)
    800049e8:	0080                	addi	s0,sp,64
    800049ea:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049ec:	0001c517          	auipc	a0,0x1c
    800049f0:	5bc50513          	addi	a0,a0,1468 # 80020fa8 <ftable>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	1e2080e7          	jalr	482(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800049fc:	40dc                	lw	a5,4(s1)
    800049fe:	06f05163          	blez	a5,80004a60 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a02:	37fd                	addiw	a5,a5,-1
    80004a04:	0007871b          	sext.w	a4,a5
    80004a08:	c0dc                	sw	a5,4(s1)
    80004a0a:	06e04363          	bgtz	a4,80004a70 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a0e:	0004a903          	lw	s2,0(s1)
    80004a12:	0094ca83          	lbu	s5,9(s1)
    80004a16:	0104ba03          	ld	s4,16(s1)
    80004a1a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a1e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a22:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a26:	0001c517          	auipc	a0,0x1c
    80004a2a:	58250513          	addi	a0,a0,1410 # 80020fa8 <ftable>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	25c080e7          	jalr	604(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004a36:	4785                	li	a5,1
    80004a38:	04f90d63          	beq	s2,a5,80004a92 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a3c:	3979                	addiw	s2,s2,-2
    80004a3e:	4785                	li	a5,1
    80004a40:	0527e063          	bltu	a5,s2,80004a80 <fileclose+0xa8>
    begin_op();
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	acc080e7          	jalr	-1332(ra) # 80004510 <begin_op>
    iput(ff.ip);
    80004a4c:	854e                	mv	a0,s3
    80004a4e:	fffff097          	auipc	ra,0xfffff
    80004a52:	2b0080e7          	jalr	688(ra) # 80003cfe <iput>
    end_op();
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	b38080e7          	jalr	-1224(ra) # 8000458e <end_op>
    80004a5e:	a00d                	j	80004a80 <fileclose+0xa8>
    panic("fileclose");
    80004a60:	00004517          	auipc	a0,0x4
    80004a64:	d2850513          	addi	a0,a0,-728 # 80008788 <syscalls+0x268>
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	ad8080e7          	jalr	-1320(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004a70:	0001c517          	auipc	a0,0x1c
    80004a74:	53850513          	addi	a0,a0,1336 # 80020fa8 <ftable>
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	212080e7          	jalr	530(ra) # 80000c8a <release>
  }
}
    80004a80:	70e2                	ld	ra,56(sp)
    80004a82:	7442                	ld	s0,48(sp)
    80004a84:	74a2                	ld	s1,40(sp)
    80004a86:	7902                	ld	s2,32(sp)
    80004a88:	69e2                	ld	s3,24(sp)
    80004a8a:	6a42                	ld	s4,16(sp)
    80004a8c:	6aa2                	ld	s5,8(sp)
    80004a8e:	6121                	addi	sp,sp,64
    80004a90:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a92:	85d6                	mv	a1,s5
    80004a94:	8552                	mv	a0,s4
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	34c080e7          	jalr	844(ra) # 80004de2 <pipeclose>
    80004a9e:	b7cd                	j	80004a80 <fileclose+0xa8>

0000000080004aa0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004aa0:	715d                	addi	sp,sp,-80
    80004aa2:	e486                	sd	ra,72(sp)
    80004aa4:	e0a2                	sd	s0,64(sp)
    80004aa6:	fc26                	sd	s1,56(sp)
    80004aa8:	f84a                	sd	s2,48(sp)
    80004aaa:	f44e                	sd	s3,40(sp)
    80004aac:	0880                	addi	s0,sp,80
    80004aae:	84aa                	mv	s1,a0
    80004ab0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ab2:	ffffd097          	auipc	ra,0xffffd
    80004ab6:	104080e7          	jalr	260(ra) # 80001bb6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004aba:	409c                	lw	a5,0(s1)
    80004abc:	37f9                	addiw	a5,a5,-2
    80004abe:	4705                	li	a4,1
    80004ac0:	04f76763          	bltu	a4,a5,80004b0e <filestat+0x6e>
    80004ac4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ac6:	6c88                	ld	a0,24(s1)
    80004ac8:	fffff097          	auipc	ra,0xfffff
    80004acc:	07c080e7          	jalr	124(ra) # 80003b44 <ilock>
    stati(f->ip, &st);
    80004ad0:	fb840593          	addi	a1,s0,-72
    80004ad4:	6c88                	ld	a0,24(s1)
    80004ad6:	fffff097          	auipc	ra,0xfffff
    80004ada:	2f8080e7          	jalr	760(ra) # 80003dce <stati>
    iunlock(f->ip);
    80004ade:	6c88                	ld	a0,24(s1)
    80004ae0:	fffff097          	auipc	ra,0xfffff
    80004ae4:	126080e7          	jalr	294(ra) # 80003c06 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ae8:	46e1                	li	a3,24
    80004aea:	fb840613          	addi	a2,s0,-72
    80004aee:	85ce                	mv	a1,s3
    80004af0:	05893503          	ld	a0,88(s2)
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	b78080e7          	jalr	-1160(ra) # 8000166c <copyout>
    80004afc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b00:	60a6                	ld	ra,72(sp)
    80004b02:	6406                	ld	s0,64(sp)
    80004b04:	74e2                	ld	s1,56(sp)
    80004b06:	7942                	ld	s2,48(sp)
    80004b08:	79a2                	ld	s3,40(sp)
    80004b0a:	6161                	addi	sp,sp,80
    80004b0c:	8082                	ret
  return -1;
    80004b0e:	557d                	li	a0,-1
    80004b10:	bfc5                	j	80004b00 <filestat+0x60>

0000000080004b12 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b12:	7179                	addi	sp,sp,-48
    80004b14:	f406                	sd	ra,40(sp)
    80004b16:	f022                	sd	s0,32(sp)
    80004b18:	ec26                	sd	s1,24(sp)
    80004b1a:	e84a                	sd	s2,16(sp)
    80004b1c:	e44e                	sd	s3,8(sp)
    80004b1e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b20:	00854783          	lbu	a5,8(a0)
    80004b24:	c3d5                	beqz	a5,80004bc8 <fileread+0xb6>
    80004b26:	84aa                	mv	s1,a0
    80004b28:	89ae                	mv	s3,a1
    80004b2a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b2c:	411c                	lw	a5,0(a0)
    80004b2e:	4705                	li	a4,1
    80004b30:	04e78963          	beq	a5,a4,80004b82 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b34:	470d                	li	a4,3
    80004b36:	04e78d63          	beq	a5,a4,80004b90 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b3a:	4709                	li	a4,2
    80004b3c:	06e79e63          	bne	a5,a4,80004bb8 <fileread+0xa6>
    ilock(f->ip);
    80004b40:	6d08                	ld	a0,24(a0)
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	002080e7          	jalr	2(ra) # 80003b44 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b4a:	874a                	mv	a4,s2
    80004b4c:	5094                	lw	a3,32(s1)
    80004b4e:	864e                	mv	a2,s3
    80004b50:	4585                	li	a1,1
    80004b52:	6c88                	ld	a0,24(s1)
    80004b54:	fffff097          	auipc	ra,0xfffff
    80004b58:	2a4080e7          	jalr	676(ra) # 80003df8 <readi>
    80004b5c:	892a                	mv	s2,a0
    80004b5e:	00a05563          	blez	a0,80004b68 <fileread+0x56>
      f->off += r;
    80004b62:	509c                	lw	a5,32(s1)
    80004b64:	9fa9                	addw	a5,a5,a0
    80004b66:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b68:	6c88                	ld	a0,24(s1)
    80004b6a:	fffff097          	auipc	ra,0xfffff
    80004b6e:	09c080e7          	jalr	156(ra) # 80003c06 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b72:	854a                	mv	a0,s2
    80004b74:	70a2                	ld	ra,40(sp)
    80004b76:	7402                	ld	s0,32(sp)
    80004b78:	64e2                	ld	s1,24(sp)
    80004b7a:	6942                	ld	s2,16(sp)
    80004b7c:	69a2                	ld	s3,8(sp)
    80004b7e:	6145                	addi	sp,sp,48
    80004b80:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b82:	6908                	ld	a0,16(a0)
    80004b84:	00000097          	auipc	ra,0x0
    80004b88:	3c6080e7          	jalr	966(ra) # 80004f4a <piperead>
    80004b8c:	892a                	mv	s2,a0
    80004b8e:	b7d5                	j	80004b72 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b90:	02451783          	lh	a5,36(a0)
    80004b94:	03079693          	slli	a3,a5,0x30
    80004b98:	92c1                	srli	a3,a3,0x30
    80004b9a:	4725                	li	a4,9
    80004b9c:	02d76863          	bltu	a4,a3,80004bcc <fileread+0xba>
    80004ba0:	0792                	slli	a5,a5,0x4
    80004ba2:	0001c717          	auipc	a4,0x1c
    80004ba6:	36670713          	addi	a4,a4,870 # 80020f08 <devsw>
    80004baa:	97ba                	add	a5,a5,a4
    80004bac:	639c                	ld	a5,0(a5)
    80004bae:	c38d                	beqz	a5,80004bd0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bb0:	4505                	li	a0,1
    80004bb2:	9782                	jalr	a5
    80004bb4:	892a                	mv	s2,a0
    80004bb6:	bf75                	j	80004b72 <fileread+0x60>
    panic("fileread");
    80004bb8:	00004517          	auipc	a0,0x4
    80004bbc:	be050513          	addi	a0,a0,-1056 # 80008798 <syscalls+0x278>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	980080e7          	jalr	-1664(ra) # 80000540 <panic>
    return -1;
    80004bc8:	597d                	li	s2,-1
    80004bca:	b765                	j	80004b72 <fileread+0x60>
      return -1;
    80004bcc:	597d                	li	s2,-1
    80004bce:	b755                	j	80004b72 <fileread+0x60>
    80004bd0:	597d                	li	s2,-1
    80004bd2:	b745                	j	80004b72 <fileread+0x60>

0000000080004bd4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bd4:	715d                	addi	sp,sp,-80
    80004bd6:	e486                	sd	ra,72(sp)
    80004bd8:	e0a2                	sd	s0,64(sp)
    80004bda:	fc26                	sd	s1,56(sp)
    80004bdc:	f84a                	sd	s2,48(sp)
    80004bde:	f44e                	sd	s3,40(sp)
    80004be0:	f052                	sd	s4,32(sp)
    80004be2:	ec56                	sd	s5,24(sp)
    80004be4:	e85a                	sd	s6,16(sp)
    80004be6:	e45e                	sd	s7,8(sp)
    80004be8:	e062                	sd	s8,0(sp)
    80004bea:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bec:	00954783          	lbu	a5,9(a0)
    80004bf0:	10078663          	beqz	a5,80004cfc <filewrite+0x128>
    80004bf4:	892a                	mv	s2,a0
    80004bf6:	8b2e                	mv	s6,a1
    80004bf8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bfa:	411c                	lw	a5,0(a0)
    80004bfc:	4705                	li	a4,1
    80004bfe:	02e78263          	beq	a5,a4,80004c22 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c02:	470d                	li	a4,3
    80004c04:	02e78663          	beq	a5,a4,80004c30 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c08:	4709                	li	a4,2
    80004c0a:	0ee79163          	bne	a5,a4,80004cec <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c0e:	0ac05d63          	blez	a2,80004cc8 <filewrite+0xf4>
    int i = 0;
    80004c12:	4981                	li	s3,0
    80004c14:	6b85                	lui	s7,0x1
    80004c16:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c1a:	6c05                	lui	s8,0x1
    80004c1c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c20:	a861                	j	80004cb8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c22:	6908                	ld	a0,16(a0)
    80004c24:	00000097          	auipc	ra,0x0
    80004c28:	22e080e7          	jalr	558(ra) # 80004e52 <pipewrite>
    80004c2c:	8a2a                	mv	s4,a0
    80004c2e:	a045                	j	80004cce <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c30:	02451783          	lh	a5,36(a0)
    80004c34:	03079693          	slli	a3,a5,0x30
    80004c38:	92c1                	srli	a3,a3,0x30
    80004c3a:	4725                	li	a4,9
    80004c3c:	0cd76263          	bltu	a4,a3,80004d00 <filewrite+0x12c>
    80004c40:	0792                	slli	a5,a5,0x4
    80004c42:	0001c717          	auipc	a4,0x1c
    80004c46:	2c670713          	addi	a4,a4,710 # 80020f08 <devsw>
    80004c4a:	97ba                	add	a5,a5,a4
    80004c4c:	679c                	ld	a5,8(a5)
    80004c4e:	cbdd                	beqz	a5,80004d04 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c50:	4505                	li	a0,1
    80004c52:	9782                	jalr	a5
    80004c54:	8a2a                	mv	s4,a0
    80004c56:	a8a5                	j	80004cce <filewrite+0xfa>
    80004c58:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c5c:	00000097          	auipc	ra,0x0
    80004c60:	8b4080e7          	jalr	-1868(ra) # 80004510 <begin_op>
      ilock(f->ip);
    80004c64:	01893503          	ld	a0,24(s2)
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	edc080e7          	jalr	-292(ra) # 80003b44 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c70:	8756                	mv	a4,s5
    80004c72:	02092683          	lw	a3,32(s2)
    80004c76:	01698633          	add	a2,s3,s6
    80004c7a:	4585                	li	a1,1
    80004c7c:	01893503          	ld	a0,24(s2)
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	270080e7          	jalr	624(ra) # 80003ef0 <writei>
    80004c88:	84aa                	mv	s1,a0
    80004c8a:	00a05763          	blez	a0,80004c98 <filewrite+0xc4>
        f->off += r;
    80004c8e:	02092783          	lw	a5,32(s2)
    80004c92:	9fa9                	addw	a5,a5,a0
    80004c94:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c98:	01893503          	ld	a0,24(s2)
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	f6a080e7          	jalr	-150(ra) # 80003c06 <iunlock>
      end_op();
    80004ca4:	00000097          	auipc	ra,0x0
    80004ca8:	8ea080e7          	jalr	-1814(ra) # 8000458e <end_op>

      if(r != n1){
    80004cac:	009a9f63          	bne	s5,s1,80004cca <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cb0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cb4:	0149db63          	bge	s3,s4,80004cca <filewrite+0xf6>
      int n1 = n - i;
    80004cb8:	413a04bb          	subw	s1,s4,s3
    80004cbc:	0004879b          	sext.w	a5,s1
    80004cc0:	f8fbdce3          	bge	s7,a5,80004c58 <filewrite+0x84>
    80004cc4:	84e2                	mv	s1,s8
    80004cc6:	bf49                	j	80004c58 <filewrite+0x84>
    int i = 0;
    80004cc8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004cca:	013a1f63          	bne	s4,s3,80004ce8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cce:	8552                	mv	a0,s4
    80004cd0:	60a6                	ld	ra,72(sp)
    80004cd2:	6406                	ld	s0,64(sp)
    80004cd4:	74e2                	ld	s1,56(sp)
    80004cd6:	7942                	ld	s2,48(sp)
    80004cd8:	79a2                	ld	s3,40(sp)
    80004cda:	7a02                	ld	s4,32(sp)
    80004cdc:	6ae2                	ld	s5,24(sp)
    80004cde:	6b42                	ld	s6,16(sp)
    80004ce0:	6ba2                	ld	s7,8(sp)
    80004ce2:	6c02                	ld	s8,0(sp)
    80004ce4:	6161                	addi	sp,sp,80
    80004ce6:	8082                	ret
    ret = (i == n ? n : -1);
    80004ce8:	5a7d                	li	s4,-1
    80004cea:	b7d5                	j	80004cce <filewrite+0xfa>
    panic("filewrite");
    80004cec:	00004517          	auipc	a0,0x4
    80004cf0:	abc50513          	addi	a0,a0,-1348 # 800087a8 <syscalls+0x288>
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>
    return -1;
    80004cfc:	5a7d                	li	s4,-1
    80004cfe:	bfc1                	j	80004cce <filewrite+0xfa>
      return -1;
    80004d00:	5a7d                	li	s4,-1
    80004d02:	b7f1                	j	80004cce <filewrite+0xfa>
    80004d04:	5a7d                	li	s4,-1
    80004d06:	b7e1                	j	80004cce <filewrite+0xfa>

0000000080004d08 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d08:	7179                	addi	sp,sp,-48
    80004d0a:	f406                	sd	ra,40(sp)
    80004d0c:	f022                	sd	s0,32(sp)
    80004d0e:	ec26                	sd	s1,24(sp)
    80004d10:	e84a                	sd	s2,16(sp)
    80004d12:	e44e                	sd	s3,8(sp)
    80004d14:	e052                	sd	s4,0(sp)
    80004d16:	1800                	addi	s0,sp,48
    80004d18:	84aa                	mv	s1,a0
    80004d1a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d1c:	0005b023          	sd	zero,0(a1)
    80004d20:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d24:	00000097          	auipc	ra,0x0
    80004d28:	bf8080e7          	jalr	-1032(ra) # 8000491c <filealloc>
    80004d2c:	e088                	sd	a0,0(s1)
    80004d2e:	c551                	beqz	a0,80004dba <pipealloc+0xb2>
    80004d30:	00000097          	auipc	ra,0x0
    80004d34:	bec080e7          	jalr	-1044(ra) # 8000491c <filealloc>
    80004d38:	00aa3023          	sd	a0,0(s4)
    80004d3c:	c92d                	beqz	a0,80004dae <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	da8080e7          	jalr	-600(ra) # 80000ae6 <kalloc>
    80004d46:	892a                	mv	s2,a0
    80004d48:	c125                	beqz	a0,80004da8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d4a:	4985                	li	s3,1
    80004d4c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d50:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d54:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d58:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d5c:	00004597          	auipc	a1,0x4
    80004d60:	a5c58593          	addi	a1,a1,-1444 # 800087b8 <syscalls+0x298>
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	de2080e7          	jalr	-542(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004d6c:	609c                	ld	a5,0(s1)
    80004d6e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d72:	609c                	ld	a5,0(s1)
    80004d74:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d78:	609c                	ld	a5,0(s1)
    80004d7a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d7e:	609c                	ld	a5,0(s1)
    80004d80:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d84:	000a3783          	ld	a5,0(s4)
    80004d88:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d8c:	000a3783          	ld	a5,0(s4)
    80004d90:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d94:	000a3783          	ld	a5,0(s4)
    80004d98:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d9c:	000a3783          	ld	a5,0(s4)
    80004da0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004da4:	4501                	li	a0,0
    80004da6:	a025                	j	80004dce <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004da8:	6088                	ld	a0,0(s1)
    80004daa:	e501                	bnez	a0,80004db2 <pipealloc+0xaa>
    80004dac:	a039                	j	80004dba <pipealloc+0xb2>
    80004dae:	6088                	ld	a0,0(s1)
    80004db0:	c51d                	beqz	a0,80004dde <pipealloc+0xd6>
    fileclose(*f0);
    80004db2:	00000097          	auipc	ra,0x0
    80004db6:	c26080e7          	jalr	-986(ra) # 800049d8 <fileclose>
  if(*f1)
    80004dba:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dbe:	557d                	li	a0,-1
  if(*f1)
    80004dc0:	c799                	beqz	a5,80004dce <pipealloc+0xc6>
    fileclose(*f1);
    80004dc2:	853e                	mv	a0,a5
    80004dc4:	00000097          	auipc	ra,0x0
    80004dc8:	c14080e7          	jalr	-1004(ra) # 800049d8 <fileclose>
  return -1;
    80004dcc:	557d                	li	a0,-1
}
    80004dce:	70a2                	ld	ra,40(sp)
    80004dd0:	7402                	ld	s0,32(sp)
    80004dd2:	64e2                	ld	s1,24(sp)
    80004dd4:	6942                	ld	s2,16(sp)
    80004dd6:	69a2                	ld	s3,8(sp)
    80004dd8:	6a02                	ld	s4,0(sp)
    80004dda:	6145                	addi	sp,sp,48
    80004ddc:	8082                	ret
  return -1;
    80004dde:	557d                	li	a0,-1
    80004de0:	b7fd                	j	80004dce <pipealloc+0xc6>

0000000080004de2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004de2:	1101                	addi	sp,sp,-32
    80004de4:	ec06                	sd	ra,24(sp)
    80004de6:	e822                	sd	s0,16(sp)
    80004de8:	e426                	sd	s1,8(sp)
    80004dea:	e04a                	sd	s2,0(sp)
    80004dec:	1000                	addi	s0,sp,32
    80004dee:	84aa                	mv	s1,a0
    80004df0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004df2:	ffffc097          	auipc	ra,0xffffc
    80004df6:	de4080e7          	jalr	-540(ra) # 80000bd6 <acquire>
  if(writable){
    80004dfa:	02090d63          	beqz	s2,80004e34 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dfe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e02:	21848513          	addi	a0,s1,536
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	5d4080e7          	jalr	1492(ra) # 800023da <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e0e:	2204b783          	ld	a5,544(s1)
    80004e12:	eb95                	bnez	a5,80004e46 <pipeclose+0x64>
    release(&pi->lock);
    80004e14:	8526                	mv	a0,s1
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	e74080e7          	jalr	-396(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004e1e:	8526                	mv	a0,s1
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	bc8080e7          	jalr	-1080(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004e28:	60e2                	ld	ra,24(sp)
    80004e2a:	6442                	ld	s0,16(sp)
    80004e2c:	64a2                	ld	s1,8(sp)
    80004e2e:	6902                	ld	s2,0(sp)
    80004e30:	6105                	addi	sp,sp,32
    80004e32:	8082                	ret
    pi->readopen = 0;
    80004e34:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e38:	21c48513          	addi	a0,s1,540
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	59e080e7          	jalr	1438(ra) # 800023da <wakeup>
    80004e44:	b7e9                	j	80004e0e <pipeclose+0x2c>
    release(&pi->lock);
    80004e46:	8526                	mv	a0,s1
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
}
    80004e50:	bfe1                	j	80004e28 <pipeclose+0x46>

0000000080004e52 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e52:	711d                	addi	sp,sp,-96
    80004e54:	ec86                	sd	ra,88(sp)
    80004e56:	e8a2                	sd	s0,80(sp)
    80004e58:	e4a6                	sd	s1,72(sp)
    80004e5a:	e0ca                	sd	s2,64(sp)
    80004e5c:	fc4e                	sd	s3,56(sp)
    80004e5e:	f852                	sd	s4,48(sp)
    80004e60:	f456                	sd	s5,40(sp)
    80004e62:	f05a                	sd	s6,32(sp)
    80004e64:	ec5e                	sd	s7,24(sp)
    80004e66:	e862                	sd	s8,16(sp)
    80004e68:	1080                	addi	s0,sp,96
    80004e6a:	84aa                	mv	s1,a0
    80004e6c:	8aae                	mv	s5,a1
    80004e6e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	d46080e7          	jalr	-698(ra) # 80001bb6 <myproc>
    80004e78:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e7a:	8526                	mv	a0,s1
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	d5a080e7          	jalr	-678(ra) # 80000bd6 <acquire>
  while(i < n){
    80004e84:	0b405663          	blez	s4,80004f30 <pipewrite+0xde>
  int i = 0;
    80004e88:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e8a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e8c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e90:	21c48b93          	addi	s7,s1,540
    80004e94:	a089                	j	80004ed6 <pipewrite+0x84>
      release(&pi->lock);
    80004e96:	8526                	mv	a0,s1
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	df2080e7          	jalr	-526(ra) # 80000c8a <release>
      return -1;
    80004ea0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ea2:	854a                	mv	a0,s2
    80004ea4:	60e6                	ld	ra,88(sp)
    80004ea6:	6446                	ld	s0,80(sp)
    80004ea8:	64a6                	ld	s1,72(sp)
    80004eaa:	6906                	ld	s2,64(sp)
    80004eac:	79e2                	ld	s3,56(sp)
    80004eae:	7a42                	ld	s4,48(sp)
    80004eb0:	7aa2                	ld	s5,40(sp)
    80004eb2:	7b02                	ld	s6,32(sp)
    80004eb4:	6be2                	ld	s7,24(sp)
    80004eb6:	6c42                	ld	s8,16(sp)
    80004eb8:	6125                	addi	sp,sp,96
    80004eba:	8082                	ret
      wakeup(&pi->nread);
    80004ebc:	8562                	mv	a0,s8
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	51c080e7          	jalr	1308(ra) # 800023da <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ec6:	85a6                	mv	a1,s1
    80004ec8:	855e                	mv	a0,s7
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	4ac080e7          	jalr	1196(ra) # 80002376 <sleep>
  while(i < n){
    80004ed2:	07495063          	bge	s2,s4,80004f32 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ed6:	2204a783          	lw	a5,544(s1)
    80004eda:	dfd5                	beqz	a5,80004e96 <pipewrite+0x44>
    80004edc:	854e                	mv	a0,s3
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	740080e7          	jalr	1856(ra) # 8000261e <killed>
    80004ee6:	f945                	bnez	a0,80004e96 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ee8:	2184a783          	lw	a5,536(s1)
    80004eec:	21c4a703          	lw	a4,540(s1)
    80004ef0:	2007879b          	addiw	a5,a5,512
    80004ef4:	fcf704e3          	beq	a4,a5,80004ebc <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ef8:	4685                	li	a3,1
    80004efa:	01590633          	add	a2,s2,s5
    80004efe:	faf40593          	addi	a1,s0,-81
    80004f02:	0589b503          	ld	a0,88(s3)
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	7f2080e7          	jalr	2034(ra) # 800016f8 <copyin>
    80004f0e:	03650263          	beq	a0,s6,80004f32 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f12:	21c4a783          	lw	a5,540(s1)
    80004f16:	0017871b          	addiw	a4,a5,1
    80004f1a:	20e4ae23          	sw	a4,540(s1)
    80004f1e:	1ff7f793          	andi	a5,a5,511
    80004f22:	97a6                	add	a5,a5,s1
    80004f24:	faf44703          	lbu	a4,-81(s0)
    80004f28:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f2c:	2905                	addiw	s2,s2,1
    80004f2e:	b755                	j	80004ed2 <pipewrite+0x80>
  int i = 0;
    80004f30:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f32:	21848513          	addi	a0,s1,536
    80004f36:	ffffd097          	auipc	ra,0xffffd
    80004f3a:	4a4080e7          	jalr	1188(ra) # 800023da <wakeup>
  release(&pi->lock);
    80004f3e:	8526                	mv	a0,s1
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	d4a080e7          	jalr	-694(ra) # 80000c8a <release>
  return i;
    80004f48:	bfa9                	j	80004ea2 <pipewrite+0x50>

0000000080004f4a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f4a:	715d                	addi	sp,sp,-80
    80004f4c:	e486                	sd	ra,72(sp)
    80004f4e:	e0a2                	sd	s0,64(sp)
    80004f50:	fc26                	sd	s1,56(sp)
    80004f52:	f84a                	sd	s2,48(sp)
    80004f54:	f44e                	sd	s3,40(sp)
    80004f56:	f052                	sd	s4,32(sp)
    80004f58:	ec56                	sd	s5,24(sp)
    80004f5a:	e85a                	sd	s6,16(sp)
    80004f5c:	0880                	addi	s0,sp,80
    80004f5e:	84aa                	mv	s1,a0
    80004f60:	892e                	mv	s2,a1
    80004f62:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f64:	ffffd097          	auipc	ra,0xffffd
    80004f68:	c52080e7          	jalr	-942(ra) # 80001bb6 <myproc>
    80004f6c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f6e:	8526                	mv	a0,s1
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	c66080e7          	jalr	-922(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f78:	2184a703          	lw	a4,536(s1)
    80004f7c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f80:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f84:	02f71763          	bne	a4,a5,80004fb2 <piperead+0x68>
    80004f88:	2244a783          	lw	a5,548(s1)
    80004f8c:	c39d                	beqz	a5,80004fb2 <piperead+0x68>
    if(killed(pr)){
    80004f8e:	8552                	mv	a0,s4
    80004f90:	ffffd097          	auipc	ra,0xffffd
    80004f94:	68e080e7          	jalr	1678(ra) # 8000261e <killed>
    80004f98:	e949                	bnez	a0,8000502a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f9a:	85a6                	mv	a1,s1
    80004f9c:	854e                	mv	a0,s3
    80004f9e:	ffffd097          	auipc	ra,0xffffd
    80004fa2:	3d8080e7          	jalr	984(ra) # 80002376 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fa6:	2184a703          	lw	a4,536(s1)
    80004faa:	21c4a783          	lw	a5,540(s1)
    80004fae:	fcf70de3          	beq	a4,a5,80004f88 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fb2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fb4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fb6:	05505463          	blez	s5,80004ffe <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004fba:	2184a783          	lw	a5,536(s1)
    80004fbe:	21c4a703          	lw	a4,540(s1)
    80004fc2:	02f70e63          	beq	a4,a5,80004ffe <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fc6:	0017871b          	addiw	a4,a5,1
    80004fca:	20e4ac23          	sw	a4,536(s1)
    80004fce:	1ff7f793          	andi	a5,a5,511
    80004fd2:	97a6                	add	a5,a5,s1
    80004fd4:	0187c783          	lbu	a5,24(a5)
    80004fd8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fdc:	4685                	li	a3,1
    80004fde:	fbf40613          	addi	a2,s0,-65
    80004fe2:	85ca                	mv	a1,s2
    80004fe4:	058a3503          	ld	a0,88(s4)
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	684080e7          	jalr	1668(ra) # 8000166c <copyout>
    80004ff0:	01650763          	beq	a0,s6,80004ffe <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ff4:	2985                	addiw	s3,s3,1
    80004ff6:	0905                	addi	s2,s2,1
    80004ff8:	fd3a91e3          	bne	s5,s3,80004fba <piperead+0x70>
    80004ffc:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ffe:	21c48513          	addi	a0,s1,540
    80005002:	ffffd097          	auipc	ra,0xffffd
    80005006:	3d8080e7          	jalr	984(ra) # 800023da <wakeup>
  release(&pi->lock);
    8000500a:	8526                	mv	a0,s1
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	c7e080e7          	jalr	-898(ra) # 80000c8a <release>
  return i;
}
    80005014:	854e                	mv	a0,s3
    80005016:	60a6                	ld	ra,72(sp)
    80005018:	6406                	ld	s0,64(sp)
    8000501a:	74e2                	ld	s1,56(sp)
    8000501c:	7942                	ld	s2,48(sp)
    8000501e:	79a2                	ld	s3,40(sp)
    80005020:	7a02                	ld	s4,32(sp)
    80005022:	6ae2                	ld	s5,24(sp)
    80005024:	6b42                	ld	s6,16(sp)
    80005026:	6161                	addi	sp,sp,80
    80005028:	8082                	ret
      release(&pi->lock);
    8000502a:	8526                	mv	a0,s1
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	c5e080e7          	jalr	-930(ra) # 80000c8a <release>
      return -1;
    80005034:	59fd                	li	s3,-1
    80005036:	bff9                	j	80005014 <piperead+0xca>

0000000080005038 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005038:	1141                	addi	sp,sp,-16
    8000503a:	e422                	sd	s0,8(sp)
    8000503c:	0800                	addi	s0,sp,16
    8000503e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005040:	8905                	andi	a0,a0,1
    80005042:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005044:	8b89                	andi	a5,a5,2
    80005046:	c399                	beqz	a5,8000504c <flags2perm+0x14>
      perm |= PTE_W;
    80005048:	00456513          	ori	a0,a0,4
    return perm;
}
    8000504c:	6422                	ld	s0,8(sp)
    8000504e:	0141                	addi	sp,sp,16
    80005050:	8082                	ret

0000000080005052 <exec>:

int
exec(char *path, char **argv)
{
    80005052:	de010113          	addi	sp,sp,-544
    80005056:	20113c23          	sd	ra,536(sp)
    8000505a:	20813823          	sd	s0,528(sp)
    8000505e:	20913423          	sd	s1,520(sp)
    80005062:	21213023          	sd	s2,512(sp)
    80005066:	ffce                	sd	s3,504(sp)
    80005068:	fbd2                	sd	s4,496(sp)
    8000506a:	f7d6                	sd	s5,488(sp)
    8000506c:	f3da                	sd	s6,480(sp)
    8000506e:	efde                	sd	s7,472(sp)
    80005070:	ebe2                	sd	s8,464(sp)
    80005072:	e7e6                	sd	s9,456(sp)
    80005074:	e3ea                	sd	s10,448(sp)
    80005076:	ff6e                	sd	s11,440(sp)
    80005078:	1400                	addi	s0,sp,544
    8000507a:	892a                	mv	s2,a0
    8000507c:	dea43423          	sd	a0,-536(s0)
    80005080:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	b32080e7          	jalr	-1230(ra) # 80001bb6 <myproc>
    8000508c:	84aa                	mv	s1,a0

  begin_op();
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	482080e7          	jalr	1154(ra) # 80004510 <begin_op>

  if((ip = namei(path)) == 0){
    80005096:	854a                	mv	a0,s2
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	258080e7          	jalr	600(ra) # 800042f0 <namei>
    800050a0:	c93d                	beqz	a0,80005116 <exec+0xc4>
    800050a2:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	aa0080e7          	jalr	-1376(ra) # 80003b44 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050ac:	04000713          	li	a4,64
    800050b0:	4681                	li	a3,0
    800050b2:	e5040613          	addi	a2,s0,-432
    800050b6:	4581                	li	a1,0
    800050b8:	8556                	mv	a0,s5
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	d3e080e7          	jalr	-706(ra) # 80003df8 <readi>
    800050c2:	04000793          	li	a5,64
    800050c6:	00f51a63          	bne	a0,a5,800050da <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800050ca:	e5042703          	lw	a4,-432(s0)
    800050ce:	464c47b7          	lui	a5,0x464c4
    800050d2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050d6:	04f70663          	beq	a4,a5,80005122 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050da:	8556                	mv	a0,s5
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	cca080e7          	jalr	-822(ra) # 80003da6 <iunlockput>
    end_op();
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	4aa080e7          	jalr	1194(ra) # 8000458e <end_op>
  }
  return -1;
    800050ec:	557d                	li	a0,-1
}
    800050ee:	21813083          	ld	ra,536(sp)
    800050f2:	21013403          	ld	s0,528(sp)
    800050f6:	20813483          	ld	s1,520(sp)
    800050fa:	20013903          	ld	s2,512(sp)
    800050fe:	79fe                	ld	s3,504(sp)
    80005100:	7a5e                	ld	s4,496(sp)
    80005102:	7abe                	ld	s5,488(sp)
    80005104:	7b1e                	ld	s6,480(sp)
    80005106:	6bfe                	ld	s7,472(sp)
    80005108:	6c5e                	ld	s8,464(sp)
    8000510a:	6cbe                	ld	s9,456(sp)
    8000510c:	6d1e                	ld	s10,448(sp)
    8000510e:	7dfa                	ld	s11,440(sp)
    80005110:	22010113          	addi	sp,sp,544
    80005114:	8082                	ret
    end_op();
    80005116:	fffff097          	auipc	ra,0xfffff
    8000511a:	478080e7          	jalr	1144(ra) # 8000458e <end_op>
    return -1;
    8000511e:	557d                	li	a0,-1
    80005120:	b7f9                	j	800050ee <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005122:	8526                	mv	a0,s1
    80005124:	ffffd097          	auipc	ra,0xffffd
    80005128:	b56080e7          	jalr	-1194(ra) # 80001c7a <proc_pagetable>
    8000512c:	8b2a                	mv	s6,a0
    8000512e:	d555                	beqz	a0,800050da <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005130:	e7042783          	lw	a5,-400(s0)
    80005134:	e8845703          	lhu	a4,-376(s0)
    80005138:	c735                	beqz	a4,800051a4 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000513a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000513c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005140:	6a05                	lui	s4,0x1
    80005142:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005146:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000514a:	6d85                	lui	s11,0x1
    8000514c:	7d7d                	lui	s10,0xfffff
    8000514e:	ac3d                	j	8000538c <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005150:	00003517          	auipc	a0,0x3
    80005154:	67050513          	addi	a0,a0,1648 # 800087c0 <syscalls+0x2a0>
    80005158:	ffffb097          	auipc	ra,0xffffb
    8000515c:	3e8080e7          	jalr	1000(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005160:	874a                	mv	a4,s2
    80005162:	009c86bb          	addw	a3,s9,s1
    80005166:	4581                	li	a1,0
    80005168:	8556                	mv	a0,s5
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	c8e080e7          	jalr	-882(ra) # 80003df8 <readi>
    80005172:	2501                	sext.w	a0,a0
    80005174:	1aa91963          	bne	s2,a0,80005326 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005178:	009d84bb          	addw	s1,s11,s1
    8000517c:	013d09bb          	addw	s3,s10,s3
    80005180:	1f74f663          	bgeu	s1,s7,8000536c <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005184:	02049593          	slli	a1,s1,0x20
    80005188:	9181                	srli	a1,a1,0x20
    8000518a:	95e2                	add	a1,a1,s8
    8000518c:	855a                	mv	a0,s6
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	ece080e7          	jalr	-306(ra) # 8000105c <walkaddr>
    80005196:	862a                	mv	a2,a0
    if(pa == 0)
    80005198:	dd45                	beqz	a0,80005150 <exec+0xfe>
      n = PGSIZE;
    8000519a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000519c:	fd49f2e3          	bgeu	s3,s4,80005160 <exec+0x10e>
      n = sz - i;
    800051a0:	894e                	mv	s2,s3
    800051a2:	bf7d                	j	80005160 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051a4:	4901                	li	s2,0
  iunlockput(ip);
    800051a6:	8556                	mv	a0,s5
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	bfe080e7          	jalr	-1026(ra) # 80003da6 <iunlockput>
  end_op();
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	3de080e7          	jalr	990(ra) # 8000458e <end_op>
  p = myproc();
    800051b8:	ffffd097          	auipc	ra,0xffffd
    800051bc:	9fe080e7          	jalr	-1538(ra) # 80001bb6 <myproc>
    800051c0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800051c2:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    800051c6:	6785                	lui	a5,0x1
    800051c8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800051ca:	97ca                	add	a5,a5,s2
    800051cc:	777d                	lui	a4,0xfffff
    800051ce:	8ff9                	and	a5,a5,a4
    800051d0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051d4:	4691                	li	a3,4
    800051d6:	6609                	lui	a2,0x2
    800051d8:	963e                	add	a2,a2,a5
    800051da:	85be                	mv	a1,a5
    800051dc:	855a                	mv	a0,s6
    800051de:	ffffc097          	auipc	ra,0xffffc
    800051e2:	232080e7          	jalr	562(ra) # 80001410 <uvmalloc>
    800051e6:	8c2a                	mv	s8,a0
  ip = 0;
    800051e8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051ea:	12050e63          	beqz	a0,80005326 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051ee:	75f9                	lui	a1,0xffffe
    800051f0:	95aa                	add	a1,a1,a0
    800051f2:	855a                	mv	a0,s6
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	446080e7          	jalr	1094(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800051fc:	7afd                	lui	s5,0xfffff
    800051fe:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005200:	df043783          	ld	a5,-528(s0)
    80005204:	6388                	ld	a0,0(a5)
    80005206:	c925                	beqz	a0,80005276 <exec+0x224>
    80005208:	e9040993          	addi	s3,s0,-368
    8000520c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005210:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005212:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	c3a080e7          	jalr	-966(ra) # 80000e4e <strlen>
    8000521c:	0015079b          	addiw	a5,a0,1
    80005220:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005224:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005228:	13596663          	bltu	s2,s5,80005354 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000522c:	df043d83          	ld	s11,-528(s0)
    80005230:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005234:	8552                	mv	a0,s4
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	c18080e7          	jalr	-1000(ra) # 80000e4e <strlen>
    8000523e:	0015069b          	addiw	a3,a0,1
    80005242:	8652                	mv	a2,s4
    80005244:	85ca                	mv	a1,s2
    80005246:	855a                	mv	a0,s6
    80005248:	ffffc097          	auipc	ra,0xffffc
    8000524c:	424080e7          	jalr	1060(ra) # 8000166c <copyout>
    80005250:	10054663          	bltz	a0,8000535c <exec+0x30a>
    ustack[argc] = sp;
    80005254:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005258:	0485                	addi	s1,s1,1
    8000525a:	008d8793          	addi	a5,s11,8
    8000525e:	def43823          	sd	a5,-528(s0)
    80005262:	008db503          	ld	a0,8(s11)
    80005266:	c911                	beqz	a0,8000527a <exec+0x228>
    if(argc >= MAXARG)
    80005268:	09a1                	addi	s3,s3,8
    8000526a:	fb3c95e3          	bne	s9,s3,80005214 <exec+0x1c2>
  sz = sz1;
    8000526e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005272:	4a81                	li	s5,0
    80005274:	a84d                	j	80005326 <exec+0x2d4>
  sp = sz;
    80005276:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005278:	4481                	li	s1,0
  ustack[argc] = 0;
    8000527a:	00349793          	slli	a5,s1,0x3
    8000527e:	f9078793          	addi	a5,a5,-112
    80005282:	97a2                	add	a5,a5,s0
    80005284:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005288:	00148693          	addi	a3,s1,1
    8000528c:	068e                	slli	a3,a3,0x3
    8000528e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005292:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005296:	01597663          	bgeu	s2,s5,800052a2 <exec+0x250>
  sz = sz1;
    8000529a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000529e:	4a81                	li	s5,0
    800052a0:	a059                	j	80005326 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052a2:	e9040613          	addi	a2,s0,-368
    800052a6:	85ca                	mv	a1,s2
    800052a8:	855a                	mv	a0,s6
    800052aa:	ffffc097          	auipc	ra,0xffffc
    800052ae:	3c2080e7          	jalr	962(ra) # 8000166c <copyout>
    800052b2:	0a054963          	bltz	a0,80005364 <exec+0x312>
  p->trapframe->a1 = sp;
    800052b6:	060bb783          	ld	a5,96(s7)
    800052ba:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052be:	de843783          	ld	a5,-536(s0)
    800052c2:	0007c703          	lbu	a4,0(a5)
    800052c6:	cf11                	beqz	a4,800052e2 <exec+0x290>
    800052c8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052ca:	02f00693          	li	a3,47
    800052ce:	a039                	j	800052dc <exec+0x28a>
      last = s+1;
    800052d0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800052d4:	0785                	addi	a5,a5,1
    800052d6:	fff7c703          	lbu	a4,-1(a5)
    800052da:	c701                	beqz	a4,800052e2 <exec+0x290>
    if(*s == '/')
    800052dc:	fed71ce3          	bne	a4,a3,800052d4 <exec+0x282>
    800052e0:	bfc5                	j	800052d0 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800052e2:	4641                	li	a2,16
    800052e4:	de843583          	ld	a1,-536(s0)
    800052e8:	160b8513          	addi	a0,s7,352
    800052ec:	ffffc097          	auipc	ra,0xffffc
    800052f0:	b30080e7          	jalr	-1232(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800052f4:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800052f8:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800052fc:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005300:	060bb783          	ld	a5,96(s7)
    80005304:	e6843703          	ld	a4,-408(s0)
    80005308:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000530a:	060bb783          	ld	a5,96(s7)
    8000530e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005312:	85ea                	mv	a1,s10
    80005314:	ffffd097          	auipc	ra,0xffffd
    80005318:	a02080e7          	jalr	-1534(ra) # 80001d16 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000531c:	0004851b          	sext.w	a0,s1
    80005320:	b3f9                	j	800050ee <exec+0x9c>
    80005322:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005326:	df843583          	ld	a1,-520(s0)
    8000532a:	855a                	mv	a0,s6
    8000532c:	ffffd097          	auipc	ra,0xffffd
    80005330:	9ea080e7          	jalr	-1558(ra) # 80001d16 <proc_freepagetable>
  if(ip){
    80005334:	da0a93e3          	bnez	s5,800050da <exec+0x88>
  return -1;
    80005338:	557d                	li	a0,-1
    8000533a:	bb55                	j	800050ee <exec+0x9c>
    8000533c:	df243c23          	sd	s2,-520(s0)
    80005340:	b7dd                	j	80005326 <exec+0x2d4>
    80005342:	df243c23          	sd	s2,-520(s0)
    80005346:	b7c5                	j	80005326 <exec+0x2d4>
    80005348:	df243c23          	sd	s2,-520(s0)
    8000534c:	bfe9                	j	80005326 <exec+0x2d4>
    8000534e:	df243c23          	sd	s2,-520(s0)
    80005352:	bfd1                	j	80005326 <exec+0x2d4>
  sz = sz1;
    80005354:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005358:	4a81                	li	s5,0
    8000535a:	b7f1                	j	80005326 <exec+0x2d4>
  sz = sz1;
    8000535c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005360:	4a81                	li	s5,0
    80005362:	b7d1                	j	80005326 <exec+0x2d4>
  sz = sz1;
    80005364:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005368:	4a81                	li	s5,0
    8000536a:	bf75                	j	80005326 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000536c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005370:	e0843783          	ld	a5,-504(s0)
    80005374:	0017869b          	addiw	a3,a5,1
    80005378:	e0d43423          	sd	a3,-504(s0)
    8000537c:	e0043783          	ld	a5,-512(s0)
    80005380:	0387879b          	addiw	a5,a5,56
    80005384:	e8845703          	lhu	a4,-376(s0)
    80005388:	e0e6dfe3          	bge	a3,a4,800051a6 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000538c:	2781                	sext.w	a5,a5
    8000538e:	e0f43023          	sd	a5,-512(s0)
    80005392:	03800713          	li	a4,56
    80005396:	86be                	mv	a3,a5
    80005398:	e1840613          	addi	a2,s0,-488
    8000539c:	4581                	li	a1,0
    8000539e:	8556                	mv	a0,s5
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	a58080e7          	jalr	-1448(ra) # 80003df8 <readi>
    800053a8:	03800793          	li	a5,56
    800053ac:	f6f51be3          	bne	a0,a5,80005322 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800053b0:	e1842783          	lw	a5,-488(s0)
    800053b4:	4705                	li	a4,1
    800053b6:	fae79de3          	bne	a5,a4,80005370 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800053ba:	e4043483          	ld	s1,-448(s0)
    800053be:	e3843783          	ld	a5,-456(s0)
    800053c2:	f6f4ede3          	bltu	s1,a5,8000533c <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053c6:	e2843783          	ld	a5,-472(s0)
    800053ca:	94be                	add	s1,s1,a5
    800053cc:	f6f4ebe3          	bltu	s1,a5,80005342 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800053d0:	de043703          	ld	a4,-544(s0)
    800053d4:	8ff9                	and	a5,a5,a4
    800053d6:	fbad                	bnez	a5,80005348 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053d8:	e1c42503          	lw	a0,-484(s0)
    800053dc:	00000097          	auipc	ra,0x0
    800053e0:	c5c080e7          	jalr	-932(ra) # 80005038 <flags2perm>
    800053e4:	86aa                	mv	a3,a0
    800053e6:	8626                	mv	a2,s1
    800053e8:	85ca                	mv	a1,s2
    800053ea:	855a                	mv	a0,s6
    800053ec:	ffffc097          	auipc	ra,0xffffc
    800053f0:	024080e7          	jalr	36(ra) # 80001410 <uvmalloc>
    800053f4:	dea43c23          	sd	a0,-520(s0)
    800053f8:	d939                	beqz	a0,8000534e <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053fa:	e2843c03          	ld	s8,-472(s0)
    800053fe:	e2042c83          	lw	s9,-480(s0)
    80005402:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005406:	f60b83e3          	beqz	s7,8000536c <exec+0x31a>
    8000540a:	89de                	mv	s3,s7
    8000540c:	4481                	li	s1,0
    8000540e:	bb9d                	j	80005184 <exec+0x132>

0000000080005410 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005410:	7179                	addi	sp,sp,-48
    80005412:	f406                	sd	ra,40(sp)
    80005414:	f022                	sd	s0,32(sp)
    80005416:	ec26                	sd	s1,24(sp)
    80005418:	e84a                	sd	s2,16(sp)
    8000541a:	1800                	addi	s0,sp,48
    8000541c:	892e                	mv	s2,a1
    8000541e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005420:	fdc40593          	addi	a1,s0,-36
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	b0a080e7          	jalr	-1270(ra) # 80002f2e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000542c:	fdc42703          	lw	a4,-36(s0)
    80005430:	47bd                	li	a5,15
    80005432:	02e7eb63          	bltu	a5,a4,80005468 <argfd+0x58>
    80005436:	ffffc097          	auipc	ra,0xffffc
    8000543a:	780080e7          	jalr	1920(ra) # 80001bb6 <myproc>
    8000543e:	fdc42703          	lw	a4,-36(s0)
    80005442:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdcf7a>
    80005446:	078e                	slli	a5,a5,0x3
    80005448:	953e                	add	a0,a0,a5
    8000544a:	651c                	ld	a5,8(a0)
    8000544c:	c385                	beqz	a5,8000546c <argfd+0x5c>
    return -1;
  if(pfd)
    8000544e:	00090463          	beqz	s2,80005456 <argfd+0x46>
    *pfd = fd;
    80005452:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005456:	4501                	li	a0,0
  if(pf)
    80005458:	c091                	beqz	s1,8000545c <argfd+0x4c>
    *pf = f;
    8000545a:	e09c                	sd	a5,0(s1)
}
    8000545c:	70a2                	ld	ra,40(sp)
    8000545e:	7402                	ld	s0,32(sp)
    80005460:	64e2                	ld	s1,24(sp)
    80005462:	6942                	ld	s2,16(sp)
    80005464:	6145                	addi	sp,sp,48
    80005466:	8082                	ret
    return -1;
    80005468:	557d                	li	a0,-1
    8000546a:	bfcd                	j	8000545c <argfd+0x4c>
    8000546c:	557d                	li	a0,-1
    8000546e:	b7fd                	j	8000545c <argfd+0x4c>

0000000080005470 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005470:	1101                	addi	sp,sp,-32
    80005472:	ec06                	sd	ra,24(sp)
    80005474:	e822                	sd	s0,16(sp)
    80005476:	e426                	sd	s1,8(sp)
    80005478:	1000                	addi	s0,sp,32
    8000547a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000547c:	ffffc097          	auipc	ra,0xffffc
    80005480:	73a080e7          	jalr	1850(ra) # 80001bb6 <myproc>
    80005484:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005486:	0d850793          	addi	a5,a0,216
    8000548a:	4501                	li	a0,0
    8000548c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000548e:	6398                	ld	a4,0(a5)
    80005490:	cb19                	beqz	a4,800054a6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005492:	2505                	addiw	a0,a0,1
    80005494:	07a1                	addi	a5,a5,8
    80005496:	fed51ce3          	bne	a0,a3,8000548e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000549a:	557d                	li	a0,-1
}
    8000549c:	60e2                	ld	ra,24(sp)
    8000549e:	6442                	ld	s0,16(sp)
    800054a0:	64a2                	ld	s1,8(sp)
    800054a2:	6105                	addi	sp,sp,32
    800054a4:	8082                	ret
      p->ofile[fd] = f;
    800054a6:	01a50793          	addi	a5,a0,26
    800054aa:	078e                	slli	a5,a5,0x3
    800054ac:	963e                	add	a2,a2,a5
    800054ae:	e604                	sd	s1,8(a2)
      return fd;
    800054b0:	b7f5                	j	8000549c <fdalloc+0x2c>

00000000800054b2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054b2:	715d                	addi	sp,sp,-80
    800054b4:	e486                	sd	ra,72(sp)
    800054b6:	e0a2                	sd	s0,64(sp)
    800054b8:	fc26                	sd	s1,56(sp)
    800054ba:	f84a                	sd	s2,48(sp)
    800054bc:	f44e                	sd	s3,40(sp)
    800054be:	f052                	sd	s4,32(sp)
    800054c0:	ec56                	sd	s5,24(sp)
    800054c2:	e85a                	sd	s6,16(sp)
    800054c4:	0880                	addi	s0,sp,80
    800054c6:	8b2e                	mv	s6,a1
    800054c8:	89b2                	mv	s3,a2
    800054ca:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054cc:	fb040593          	addi	a1,s0,-80
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	e3e080e7          	jalr	-450(ra) # 8000430e <nameiparent>
    800054d8:	84aa                	mv	s1,a0
    800054da:	14050f63          	beqz	a0,80005638 <create+0x186>
    return 0;

  ilock(dp);
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	666080e7          	jalr	1638(ra) # 80003b44 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054e6:	4601                	li	a2,0
    800054e8:	fb040593          	addi	a1,s0,-80
    800054ec:	8526                	mv	a0,s1
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	b3a080e7          	jalr	-1222(ra) # 80004028 <dirlookup>
    800054f6:	8aaa                	mv	s5,a0
    800054f8:	c931                	beqz	a0,8000554c <create+0x9a>
    iunlockput(dp);
    800054fa:	8526                	mv	a0,s1
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	8aa080e7          	jalr	-1878(ra) # 80003da6 <iunlockput>
    ilock(ip);
    80005504:	8556                	mv	a0,s5
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	63e080e7          	jalr	1598(ra) # 80003b44 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000550e:	000b059b          	sext.w	a1,s6
    80005512:	4789                	li	a5,2
    80005514:	02f59563          	bne	a1,a5,8000553e <create+0x8c>
    80005518:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdcfa4>
    8000551c:	37f9                	addiw	a5,a5,-2
    8000551e:	17c2                	slli	a5,a5,0x30
    80005520:	93c1                	srli	a5,a5,0x30
    80005522:	4705                	li	a4,1
    80005524:	00f76d63          	bltu	a4,a5,8000553e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005528:	8556                	mv	a0,s5
    8000552a:	60a6                	ld	ra,72(sp)
    8000552c:	6406                	ld	s0,64(sp)
    8000552e:	74e2                	ld	s1,56(sp)
    80005530:	7942                	ld	s2,48(sp)
    80005532:	79a2                	ld	s3,40(sp)
    80005534:	7a02                	ld	s4,32(sp)
    80005536:	6ae2                	ld	s5,24(sp)
    80005538:	6b42                	ld	s6,16(sp)
    8000553a:	6161                	addi	sp,sp,80
    8000553c:	8082                	ret
    iunlockput(ip);
    8000553e:	8556                	mv	a0,s5
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	866080e7          	jalr	-1946(ra) # 80003da6 <iunlockput>
    return 0;
    80005548:	4a81                	li	s5,0
    8000554a:	bff9                	j	80005528 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000554c:	85da                	mv	a1,s6
    8000554e:	4088                	lw	a0,0(s1)
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	456080e7          	jalr	1110(ra) # 800039a6 <ialloc>
    80005558:	8a2a                	mv	s4,a0
    8000555a:	c539                	beqz	a0,800055a8 <create+0xf6>
  ilock(ip);
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	5e8080e7          	jalr	1512(ra) # 80003b44 <ilock>
  ip->major = major;
    80005564:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005568:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000556c:	4905                	li	s2,1
    8000556e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005572:	8552                	mv	a0,s4
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	504080e7          	jalr	1284(ra) # 80003a78 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000557c:	000b059b          	sext.w	a1,s6
    80005580:	03258b63          	beq	a1,s2,800055b6 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005584:	004a2603          	lw	a2,4(s4)
    80005588:	fb040593          	addi	a1,s0,-80
    8000558c:	8526                	mv	a0,s1
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	cb0080e7          	jalr	-848(ra) # 8000423e <dirlink>
    80005596:	06054f63          	bltz	a0,80005614 <create+0x162>
  iunlockput(dp);
    8000559a:	8526                	mv	a0,s1
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	80a080e7          	jalr	-2038(ra) # 80003da6 <iunlockput>
  return ip;
    800055a4:	8ad2                	mv	s5,s4
    800055a6:	b749                	j	80005528 <create+0x76>
    iunlockput(dp);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	7fc080e7          	jalr	2044(ra) # 80003da6 <iunlockput>
    return 0;
    800055b2:	8ad2                	mv	s5,s4
    800055b4:	bf95                	j	80005528 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055b6:	004a2603          	lw	a2,4(s4)
    800055ba:	00003597          	auipc	a1,0x3
    800055be:	22658593          	addi	a1,a1,550 # 800087e0 <syscalls+0x2c0>
    800055c2:	8552                	mv	a0,s4
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	c7a080e7          	jalr	-902(ra) # 8000423e <dirlink>
    800055cc:	04054463          	bltz	a0,80005614 <create+0x162>
    800055d0:	40d0                	lw	a2,4(s1)
    800055d2:	00003597          	auipc	a1,0x3
    800055d6:	21658593          	addi	a1,a1,534 # 800087e8 <syscalls+0x2c8>
    800055da:	8552                	mv	a0,s4
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	c62080e7          	jalr	-926(ra) # 8000423e <dirlink>
    800055e4:	02054863          	bltz	a0,80005614 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800055e8:	004a2603          	lw	a2,4(s4)
    800055ec:	fb040593          	addi	a1,s0,-80
    800055f0:	8526                	mv	a0,s1
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	c4c080e7          	jalr	-948(ra) # 8000423e <dirlink>
    800055fa:	00054d63          	bltz	a0,80005614 <create+0x162>
    dp->nlink++;  // for ".."
    800055fe:	04a4d783          	lhu	a5,74(s1)
    80005602:	2785                	addiw	a5,a5,1
    80005604:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005608:	8526                	mv	a0,s1
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	46e080e7          	jalr	1134(ra) # 80003a78 <iupdate>
    80005612:	b761                	j	8000559a <create+0xe8>
  ip->nlink = 0;
    80005614:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005618:	8552                	mv	a0,s4
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	45e080e7          	jalr	1118(ra) # 80003a78 <iupdate>
  iunlockput(ip);
    80005622:	8552                	mv	a0,s4
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	782080e7          	jalr	1922(ra) # 80003da6 <iunlockput>
  iunlockput(dp);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	778080e7          	jalr	1912(ra) # 80003da6 <iunlockput>
  return 0;
    80005636:	bdcd                	j	80005528 <create+0x76>
    return 0;
    80005638:	8aaa                	mv	s5,a0
    8000563a:	b5fd                	j	80005528 <create+0x76>

000000008000563c <sys_dup>:
{
    8000563c:	7179                	addi	sp,sp,-48
    8000563e:	f406                	sd	ra,40(sp)
    80005640:	f022                	sd	s0,32(sp)
    80005642:	ec26                	sd	s1,24(sp)
    80005644:	e84a                	sd	s2,16(sp)
    80005646:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005648:	fd840613          	addi	a2,s0,-40
    8000564c:	4581                	li	a1,0
    8000564e:	4501                	li	a0,0
    80005650:	00000097          	auipc	ra,0x0
    80005654:	dc0080e7          	jalr	-576(ra) # 80005410 <argfd>
    return -1;
    80005658:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000565a:	02054363          	bltz	a0,80005680 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000565e:	fd843903          	ld	s2,-40(s0)
    80005662:	854a                	mv	a0,s2
    80005664:	00000097          	auipc	ra,0x0
    80005668:	e0c080e7          	jalr	-500(ra) # 80005470 <fdalloc>
    8000566c:	84aa                	mv	s1,a0
    return -1;
    8000566e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005670:	00054863          	bltz	a0,80005680 <sys_dup+0x44>
  filedup(f);
    80005674:	854a                	mv	a0,s2
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	310080e7          	jalr	784(ra) # 80004986 <filedup>
  return fd;
    8000567e:	87a6                	mv	a5,s1
}
    80005680:	853e                	mv	a0,a5
    80005682:	70a2                	ld	ra,40(sp)
    80005684:	7402                	ld	s0,32(sp)
    80005686:	64e2                	ld	s1,24(sp)
    80005688:	6942                	ld	s2,16(sp)
    8000568a:	6145                	addi	sp,sp,48
    8000568c:	8082                	ret

000000008000568e <sys_read>:
{
    8000568e:	7179                	addi	sp,sp,-48
    80005690:	f406                	sd	ra,40(sp)
    80005692:	f022                	sd	s0,32(sp)
    80005694:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005696:	fd840593          	addi	a1,s0,-40
    8000569a:	4505                	li	a0,1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	8b2080e7          	jalr	-1870(ra) # 80002f4e <argaddr>
  argint(2, &n);
    800056a4:	fe440593          	addi	a1,s0,-28
    800056a8:	4509                	li	a0,2
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	884080e7          	jalr	-1916(ra) # 80002f2e <argint>
  if(argfd(0, 0, &f) < 0)
    800056b2:	fe840613          	addi	a2,s0,-24
    800056b6:	4581                	li	a1,0
    800056b8:	4501                	li	a0,0
    800056ba:	00000097          	auipc	ra,0x0
    800056be:	d56080e7          	jalr	-682(ra) # 80005410 <argfd>
    800056c2:	87aa                	mv	a5,a0
    return -1;
    800056c4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056c6:	0007cc63          	bltz	a5,800056de <sys_read+0x50>
  return fileread(f, p, n);
    800056ca:	fe442603          	lw	a2,-28(s0)
    800056ce:	fd843583          	ld	a1,-40(s0)
    800056d2:	fe843503          	ld	a0,-24(s0)
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	43c080e7          	jalr	1084(ra) # 80004b12 <fileread>
}
    800056de:	70a2                	ld	ra,40(sp)
    800056e0:	7402                	ld	s0,32(sp)
    800056e2:	6145                	addi	sp,sp,48
    800056e4:	8082                	ret

00000000800056e6 <sys_write>:
{
    800056e6:	7179                	addi	sp,sp,-48
    800056e8:	f406                	sd	ra,40(sp)
    800056ea:	f022                	sd	s0,32(sp)
    800056ec:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056ee:	fd840593          	addi	a1,s0,-40
    800056f2:	4505                	li	a0,1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	85a080e7          	jalr	-1958(ra) # 80002f4e <argaddr>
  argint(2, &n);
    800056fc:	fe440593          	addi	a1,s0,-28
    80005700:	4509                	li	a0,2
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	82c080e7          	jalr	-2004(ra) # 80002f2e <argint>
  if(argfd(0, 0, &f) < 0)
    8000570a:	fe840613          	addi	a2,s0,-24
    8000570e:	4581                	li	a1,0
    80005710:	4501                	li	a0,0
    80005712:	00000097          	auipc	ra,0x0
    80005716:	cfe080e7          	jalr	-770(ra) # 80005410 <argfd>
    8000571a:	87aa                	mv	a5,a0
    return -1;
    8000571c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000571e:	0007cc63          	bltz	a5,80005736 <sys_write+0x50>
  return filewrite(f, p, n);
    80005722:	fe442603          	lw	a2,-28(s0)
    80005726:	fd843583          	ld	a1,-40(s0)
    8000572a:	fe843503          	ld	a0,-24(s0)
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	4a6080e7          	jalr	1190(ra) # 80004bd4 <filewrite>
}
    80005736:	70a2                	ld	ra,40(sp)
    80005738:	7402                	ld	s0,32(sp)
    8000573a:	6145                	addi	sp,sp,48
    8000573c:	8082                	ret

000000008000573e <sys_close>:
{
    8000573e:	1101                	addi	sp,sp,-32
    80005740:	ec06                	sd	ra,24(sp)
    80005742:	e822                	sd	s0,16(sp)
    80005744:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005746:	fe040613          	addi	a2,s0,-32
    8000574a:	fec40593          	addi	a1,s0,-20
    8000574e:	4501                	li	a0,0
    80005750:	00000097          	auipc	ra,0x0
    80005754:	cc0080e7          	jalr	-832(ra) # 80005410 <argfd>
    return -1;
    80005758:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000575a:	02054463          	bltz	a0,80005782 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000575e:	ffffc097          	auipc	ra,0xffffc
    80005762:	458080e7          	jalr	1112(ra) # 80001bb6 <myproc>
    80005766:	fec42783          	lw	a5,-20(s0)
    8000576a:	07e9                	addi	a5,a5,26
    8000576c:	078e                	slli	a5,a5,0x3
    8000576e:	953e                	add	a0,a0,a5
    80005770:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005774:	fe043503          	ld	a0,-32(s0)
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	260080e7          	jalr	608(ra) # 800049d8 <fileclose>
  return 0;
    80005780:	4781                	li	a5,0
}
    80005782:	853e                	mv	a0,a5
    80005784:	60e2                	ld	ra,24(sp)
    80005786:	6442                	ld	s0,16(sp)
    80005788:	6105                	addi	sp,sp,32
    8000578a:	8082                	ret

000000008000578c <sys_fstat>:
{
    8000578c:	1101                	addi	sp,sp,-32
    8000578e:	ec06                	sd	ra,24(sp)
    80005790:	e822                	sd	s0,16(sp)
    80005792:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005794:	fe040593          	addi	a1,s0,-32
    80005798:	4505                	li	a0,1
    8000579a:	ffffd097          	auipc	ra,0xffffd
    8000579e:	7b4080e7          	jalr	1972(ra) # 80002f4e <argaddr>
  if(argfd(0, 0, &f) < 0)
    800057a2:	fe840613          	addi	a2,s0,-24
    800057a6:	4581                	li	a1,0
    800057a8:	4501                	li	a0,0
    800057aa:	00000097          	auipc	ra,0x0
    800057ae:	c66080e7          	jalr	-922(ra) # 80005410 <argfd>
    800057b2:	87aa                	mv	a5,a0
    return -1;
    800057b4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057b6:	0007ca63          	bltz	a5,800057ca <sys_fstat+0x3e>
  return filestat(f, st);
    800057ba:	fe043583          	ld	a1,-32(s0)
    800057be:	fe843503          	ld	a0,-24(s0)
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	2de080e7          	jalr	734(ra) # 80004aa0 <filestat>
}
    800057ca:	60e2                	ld	ra,24(sp)
    800057cc:	6442                	ld	s0,16(sp)
    800057ce:	6105                	addi	sp,sp,32
    800057d0:	8082                	ret

00000000800057d2 <sys_link>:
{
    800057d2:	7169                	addi	sp,sp,-304
    800057d4:	f606                	sd	ra,296(sp)
    800057d6:	f222                	sd	s0,288(sp)
    800057d8:	ee26                	sd	s1,280(sp)
    800057da:	ea4a                	sd	s2,272(sp)
    800057dc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057de:	08000613          	li	a2,128
    800057e2:	ed040593          	addi	a1,s0,-304
    800057e6:	4501                	li	a0,0
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	786080e7          	jalr	1926(ra) # 80002f6e <argstr>
    return -1;
    800057f0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f2:	10054e63          	bltz	a0,8000590e <sys_link+0x13c>
    800057f6:	08000613          	li	a2,128
    800057fa:	f5040593          	addi	a1,s0,-176
    800057fe:	4505                	li	a0,1
    80005800:	ffffd097          	auipc	ra,0xffffd
    80005804:	76e080e7          	jalr	1902(ra) # 80002f6e <argstr>
    return -1;
    80005808:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000580a:	10054263          	bltz	a0,8000590e <sys_link+0x13c>
  begin_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	d02080e7          	jalr	-766(ra) # 80004510 <begin_op>
  if((ip = namei(old)) == 0){
    80005816:	ed040513          	addi	a0,s0,-304
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	ad6080e7          	jalr	-1322(ra) # 800042f0 <namei>
    80005822:	84aa                	mv	s1,a0
    80005824:	c551                	beqz	a0,800058b0 <sys_link+0xde>
  ilock(ip);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	31e080e7          	jalr	798(ra) # 80003b44 <ilock>
  if(ip->type == T_DIR){
    8000582e:	04449703          	lh	a4,68(s1)
    80005832:	4785                	li	a5,1
    80005834:	08f70463          	beq	a4,a5,800058bc <sys_link+0xea>
  ip->nlink++;
    80005838:	04a4d783          	lhu	a5,74(s1)
    8000583c:	2785                	addiw	a5,a5,1
    8000583e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	234080e7          	jalr	564(ra) # 80003a78 <iupdate>
  iunlock(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	3b8080e7          	jalr	952(ra) # 80003c06 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005856:	fd040593          	addi	a1,s0,-48
    8000585a:	f5040513          	addi	a0,s0,-176
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	ab0080e7          	jalr	-1360(ra) # 8000430e <nameiparent>
    80005866:	892a                	mv	s2,a0
    80005868:	c935                	beqz	a0,800058dc <sys_link+0x10a>
  ilock(dp);
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	2da080e7          	jalr	730(ra) # 80003b44 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005872:	00092703          	lw	a4,0(s2)
    80005876:	409c                	lw	a5,0(s1)
    80005878:	04f71d63          	bne	a4,a5,800058d2 <sys_link+0x100>
    8000587c:	40d0                	lw	a2,4(s1)
    8000587e:	fd040593          	addi	a1,s0,-48
    80005882:	854a                	mv	a0,s2
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	9ba080e7          	jalr	-1606(ra) # 8000423e <dirlink>
    8000588c:	04054363          	bltz	a0,800058d2 <sys_link+0x100>
  iunlockput(dp);
    80005890:	854a                	mv	a0,s2
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	514080e7          	jalr	1300(ra) # 80003da6 <iunlockput>
  iput(ip);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	462080e7          	jalr	1122(ra) # 80003cfe <iput>
  end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	cea080e7          	jalr	-790(ra) # 8000458e <end_op>
  return 0;
    800058ac:	4781                	li	a5,0
    800058ae:	a085                	j	8000590e <sys_link+0x13c>
    end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	cde080e7          	jalr	-802(ra) # 8000458e <end_op>
    return -1;
    800058b8:	57fd                	li	a5,-1
    800058ba:	a891                	j	8000590e <sys_link+0x13c>
    iunlockput(ip);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	4e8080e7          	jalr	1256(ra) # 80003da6 <iunlockput>
    end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	cc8080e7          	jalr	-824(ra) # 8000458e <end_op>
    return -1;
    800058ce:	57fd                	li	a5,-1
    800058d0:	a83d                	j	8000590e <sys_link+0x13c>
    iunlockput(dp);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	4d2080e7          	jalr	1234(ra) # 80003da6 <iunlockput>
  ilock(ip);
    800058dc:	8526                	mv	a0,s1
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	266080e7          	jalr	614(ra) # 80003b44 <ilock>
  ip->nlink--;
    800058e6:	04a4d783          	lhu	a5,74(s1)
    800058ea:	37fd                	addiw	a5,a5,-1
    800058ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058f0:	8526                	mv	a0,s1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	186080e7          	jalr	390(ra) # 80003a78 <iupdate>
  iunlockput(ip);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	4aa080e7          	jalr	1194(ra) # 80003da6 <iunlockput>
  end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	c8a080e7          	jalr	-886(ra) # 8000458e <end_op>
  return -1;
    8000590c:	57fd                	li	a5,-1
}
    8000590e:	853e                	mv	a0,a5
    80005910:	70b2                	ld	ra,296(sp)
    80005912:	7412                	ld	s0,288(sp)
    80005914:	64f2                	ld	s1,280(sp)
    80005916:	6952                	ld	s2,272(sp)
    80005918:	6155                	addi	sp,sp,304
    8000591a:	8082                	ret

000000008000591c <sys_unlink>:
{
    8000591c:	7151                	addi	sp,sp,-240
    8000591e:	f586                	sd	ra,232(sp)
    80005920:	f1a2                	sd	s0,224(sp)
    80005922:	eda6                	sd	s1,216(sp)
    80005924:	e9ca                	sd	s2,208(sp)
    80005926:	e5ce                	sd	s3,200(sp)
    80005928:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000592a:	08000613          	li	a2,128
    8000592e:	f3040593          	addi	a1,s0,-208
    80005932:	4501                	li	a0,0
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	63a080e7          	jalr	1594(ra) # 80002f6e <argstr>
    8000593c:	18054163          	bltz	a0,80005abe <sys_unlink+0x1a2>
  begin_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	bd0080e7          	jalr	-1072(ra) # 80004510 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005948:	fb040593          	addi	a1,s0,-80
    8000594c:	f3040513          	addi	a0,s0,-208
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	9be080e7          	jalr	-1602(ra) # 8000430e <nameiparent>
    80005958:	84aa                	mv	s1,a0
    8000595a:	c979                	beqz	a0,80005a30 <sys_unlink+0x114>
  ilock(dp);
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	1e8080e7          	jalr	488(ra) # 80003b44 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005964:	00003597          	auipc	a1,0x3
    80005968:	e7c58593          	addi	a1,a1,-388 # 800087e0 <syscalls+0x2c0>
    8000596c:	fb040513          	addi	a0,s0,-80
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	69e080e7          	jalr	1694(ra) # 8000400e <namecmp>
    80005978:	14050a63          	beqz	a0,80005acc <sys_unlink+0x1b0>
    8000597c:	00003597          	auipc	a1,0x3
    80005980:	e6c58593          	addi	a1,a1,-404 # 800087e8 <syscalls+0x2c8>
    80005984:	fb040513          	addi	a0,s0,-80
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	686080e7          	jalr	1670(ra) # 8000400e <namecmp>
    80005990:	12050e63          	beqz	a0,80005acc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005994:	f2c40613          	addi	a2,s0,-212
    80005998:	fb040593          	addi	a1,s0,-80
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	68a080e7          	jalr	1674(ra) # 80004028 <dirlookup>
    800059a6:	892a                	mv	s2,a0
    800059a8:	12050263          	beqz	a0,80005acc <sys_unlink+0x1b0>
  ilock(ip);
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	198080e7          	jalr	408(ra) # 80003b44 <ilock>
  if(ip->nlink < 1)
    800059b4:	04a91783          	lh	a5,74(s2)
    800059b8:	08f05263          	blez	a5,80005a3c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059bc:	04491703          	lh	a4,68(s2)
    800059c0:	4785                	li	a5,1
    800059c2:	08f70563          	beq	a4,a5,80005a4c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059c6:	4641                	li	a2,16
    800059c8:	4581                	li	a1,0
    800059ca:	fc040513          	addi	a0,s0,-64
    800059ce:	ffffb097          	auipc	ra,0xffffb
    800059d2:	304080e7          	jalr	772(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059d6:	4741                	li	a4,16
    800059d8:	f2c42683          	lw	a3,-212(s0)
    800059dc:	fc040613          	addi	a2,s0,-64
    800059e0:	4581                	li	a1,0
    800059e2:	8526                	mv	a0,s1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	50c080e7          	jalr	1292(ra) # 80003ef0 <writei>
    800059ec:	47c1                	li	a5,16
    800059ee:	0af51563          	bne	a0,a5,80005a98 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059f2:	04491703          	lh	a4,68(s2)
    800059f6:	4785                	li	a5,1
    800059f8:	0af70863          	beq	a4,a5,80005aa8 <sys_unlink+0x18c>
  iunlockput(dp);
    800059fc:	8526                	mv	a0,s1
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	3a8080e7          	jalr	936(ra) # 80003da6 <iunlockput>
  ip->nlink--;
    80005a06:	04a95783          	lhu	a5,74(s2)
    80005a0a:	37fd                	addiw	a5,a5,-1
    80005a0c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a10:	854a                	mv	a0,s2
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	066080e7          	jalr	102(ra) # 80003a78 <iupdate>
  iunlockput(ip);
    80005a1a:	854a                	mv	a0,s2
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	38a080e7          	jalr	906(ra) # 80003da6 <iunlockput>
  end_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	b6a080e7          	jalr	-1174(ra) # 8000458e <end_op>
  return 0;
    80005a2c:	4501                	li	a0,0
    80005a2e:	a84d                	j	80005ae0 <sys_unlink+0x1c4>
    end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	b5e080e7          	jalr	-1186(ra) # 8000458e <end_op>
    return -1;
    80005a38:	557d                	li	a0,-1
    80005a3a:	a05d                	j	80005ae0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a3c:	00003517          	auipc	a0,0x3
    80005a40:	db450513          	addi	a0,a0,-588 # 800087f0 <syscalls+0x2d0>
    80005a44:	ffffb097          	auipc	ra,0xffffb
    80005a48:	afc080e7          	jalr	-1284(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a4c:	04c92703          	lw	a4,76(s2)
    80005a50:	02000793          	li	a5,32
    80005a54:	f6e7f9e3          	bgeu	a5,a4,800059c6 <sys_unlink+0xaa>
    80005a58:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a5c:	4741                	li	a4,16
    80005a5e:	86ce                	mv	a3,s3
    80005a60:	f1840613          	addi	a2,s0,-232
    80005a64:	4581                	li	a1,0
    80005a66:	854a                	mv	a0,s2
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	390080e7          	jalr	912(ra) # 80003df8 <readi>
    80005a70:	47c1                	li	a5,16
    80005a72:	00f51b63          	bne	a0,a5,80005a88 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a76:	f1845783          	lhu	a5,-232(s0)
    80005a7a:	e7a1                	bnez	a5,80005ac2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a7c:	29c1                	addiw	s3,s3,16
    80005a7e:	04c92783          	lw	a5,76(s2)
    80005a82:	fcf9ede3          	bltu	s3,a5,80005a5c <sys_unlink+0x140>
    80005a86:	b781                	j	800059c6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a88:	00003517          	auipc	a0,0x3
    80005a8c:	d8050513          	addi	a0,a0,-640 # 80008808 <syscalls+0x2e8>
    80005a90:	ffffb097          	auipc	ra,0xffffb
    80005a94:	ab0080e7          	jalr	-1360(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005a98:	00003517          	auipc	a0,0x3
    80005a9c:	d8850513          	addi	a0,a0,-632 # 80008820 <syscalls+0x300>
    80005aa0:	ffffb097          	auipc	ra,0xffffb
    80005aa4:	aa0080e7          	jalr	-1376(ra) # 80000540 <panic>
    dp->nlink--;
    80005aa8:	04a4d783          	lhu	a5,74(s1)
    80005aac:	37fd                	addiw	a5,a5,-1
    80005aae:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	fc4080e7          	jalr	-60(ra) # 80003a78 <iupdate>
    80005abc:	b781                	j	800059fc <sys_unlink+0xe0>
    return -1;
    80005abe:	557d                	li	a0,-1
    80005ac0:	a005                	j	80005ae0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ac2:	854a                	mv	a0,s2
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	2e2080e7          	jalr	738(ra) # 80003da6 <iunlockput>
  iunlockput(dp);
    80005acc:	8526                	mv	a0,s1
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	2d8080e7          	jalr	728(ra) # 80003da6 <iunlockput>
  end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	ab8080e7          	jalr	-1352(ra) # 8000458e <end_op>
  return -1;
    80005ade:	557d                	li	a0,-1
}
    80005ae0:	70ae                	ld	ra,232(sp)
    80005ae2:	740e                	ld	s0,224(sp)
    80005ae4:	64ee                	ld	s1,216(sp)
    80005ae6:	694e                	ld	s2,208(sp)
    80005ae8:	69ae                	ld	s3,200(sp)
    80005aea:	616d                	addi	sp,sp,240
    80005aec:	8082                	ret

0000000080005aee <sys_open>:

uint64
sys_open(void)
{
    80005aee:	7131                	addi	sp,sp,-192
    80005af0:	fd06                	sd	ra,184(sp)
    80005af2:	f922                	sd	s0,176(sp)
    80005af4:	f526                	sd	s1,168(sp)
    80005af6:	f14a                	sd	s2,160(sp)
    80005af8:	ed4e                	sd	s3,152(sp)
    80005afa:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005afc:	f4c40593          	addi	a1,s0,-180
    80005b00:	4505                	li	a0,1
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	42c080e7          	jalr	1068(ra) # 80002f2e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b0a:	08000613          	li	a2,128
    80005b0e:	f5040593          	addi	a1,s0,-176
    80005b12:	4501                	li	a0,0
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	45a080e7          	jalr	1114(ra) # 80002f6e <argstr>
    80005b1c:	87aa                	mv	a5,a0
    return -1;
    80005b1e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b20:	0a07c963          	bltz	a5,80005bd2 <sys_open+0xe4>

  begin_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	9ec080e7          	jalr	-1556(ra) # 80004510 <begin_op>

  if(omode & O_CREATE){
    80005b2c:	f4c42783          	lw	a5,-180(s0)
    80005b30:	2007f793          	andi	a5,a5,512
    80005b34:	cfc5                	beqz	a5,80005bec <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b36:	4681                	li	a3,0
    80005b38:	4601                	li	a2,0
    80005b3a:	4589                	li	a1,2
    80005b3c:	f5040513          	addi	a0,s0,-176
    80005b40:	00000097          	auipc	ra,0x0
    80005b44:	972080e7          	jalr	-1678(ra) # 800054b2 <create>
    80005b48:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b4a:	c959                	beqz	a0,80005be0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b4c:	04449703          	lh	a4,68(s1)
    80005b50:	478d                	li	a5,3
    80005b52:	00f71763          	bne	a4,a5,80005b60 <sys_open+0x72>
    80005b56:	0464d703          	lhu	a4,70(s1)
    80005b5a:	47a5                	li	a5,9
    80005b5c:	0ce7ed63          	bltu	a5,a4,80005c36 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	dbc080e7          	jalr	-580(ra) # 8000491c <filealloc>
    80005b68:	89aa                	mv	s3,a0
    80005b6a:	10050363          	beqz	a0,80005c70 <sys_open+0x182>
    80005b6e:	00000097          	auipc	ra,0x0
    80005b72:	902080e7          	jalr	-1790(ra) # 80005470 <fdalloc>
    80005b76:	892a                	mv	s2,a0
    80005b78:	0e054763          	bltz	a0,80005c66 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b7c:	04449703          	lh	a4,68(s1)
    80005b80:	478d                	li	a5,3
    80005b82:	0cf70563          	beq	a4,a5,80005c4c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b86:	4789                	li	a5,2
    80005b88:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b8c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b90:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b94:	f4c42783          	lw	a5,-180(s0)
    80005b98:	0017c713          	xori	a4,a5,1
    80005b9c:	8b05                	andi	a4,a4,1
    80005b9e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ba2:	0037f713          	andi	a4,a5,3
    80005ba6:	00e03733          	snez	a4,a4
    80005baa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bae:	4007f793          	andi	a5,a5,1024
    80005bb2:	c791                	beqz	a5,80005bbe <sys_open+0xd0>
    80005bb4:	04449703          	lh	a4,68(s1)
    80005bb8:	4789                	li	a5,2
    80005bba:	0af70063          	beq	a4,a5,80005c5a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bbe:	8526                	mv	a0,s1
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	046080e7          	jalr	70(ra) # 80003c06 <iunlock>
  end_op();
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	9c6080e7          	jalr	-1594(ra) # 8000458e <end_op>

  return fd;
    80005bd0:	854a                	mv	a0,s2
}
    80005bd2:	70ea                	ld	ra,184(sp)
    80005bd4:	744a                	ld	s0,176(sp)
    80005bd6:	74aa                	ld	s1,168(sp)
    80005bd8:	790a                	ld	s2,160(sp)
    80005bda:	69ea                	ld	s3,152(sp)
    80005bdc:	6129                	addi	sp,sp,192
    80005bde:	8082                	ret
      end_op();
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	9ae080e7          	jalr	-1618(ra) # 8000458e <end_op>
      return -1;
    80005be8:	557d                	li	a0,-1
    80005bea:	b7e5                	j	80005bd2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bec:	f5040513          	addi	a0,s0,-176
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	700080e7          	jalr	1792(ra) # 800042f0 <namei>
    80005bf8:	84aa                	mv	s1,a0
    80005bfa:	c905                	beqz	a0,80005c2a <sys_open+0x13c>
    ilock(ip);
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	f48080e7          	jalr	-184(ra) # 80003b44 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c04:	04449703          	lh	a4,68(s1)
    80005c08:	4785                	li	a5,1
    80005c0a:	f4f711e3          	bne	a4,a5,80005b4c <sys_open+0x5e>
    80005c0e:	f4c42783          	lw	a5,-180(s0)
    80005c12:	d7b9                	beqz	a5,80005b60 <sys_open+0x72>
      iunlockput(ip);
    80005c14:	8526                	mv	a0,s1
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	190080e7          	jalr	400(ra) # 80003da6 <iunlockput>
      end_op();
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	970080e7          	jalr	-1680(ra) # 8000458e <end_op>
      return -1;
    80005c26:	557d                	li	a0,-1
    80005c28:	b76d                	j	80005bd2 <sys_open+0xe4>
      end_op();
    80005c2a:	fffff097          	auipc	ra,0xfffff
    80005c2e:	964080e7          	jalr	-1692(ra) # 8000458e <end_op>
      return -1;
    80005c32:	557d                	li	a0,-1
    80005c34:	bf79                	j	80005bd2 <sys_open+0xe4>
    iunlockput(ip);
    80005c36:	8526                	mv	a0,s1
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	16e080e7          	jalr	366(ra) # 80003da6 <iunlockput>
    end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	94e080e7          	jalr	-1714(ra) # 8000458e <end_op>
    return -1;
    80005c48:	557d                	li	a0,-1
    80005c4a:	b761                	j	80005bd2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c4c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c50:	04649783          	lh	a5,70(s1)
    80005c54:	02f99223          	sh	a5,36(s3)
    80005c58:	bf25                	j	80005b90 <sys_open+0xa2>
    itrunc(ip);
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	ff6080e7          	jalr	-10(ra) # 80003c52 <itrunc>
    80005c64:	bfa9                	j	80005bbe <sys_open+0xd0>
      fileclose(f);
    80005c66:	854e                	mv	a0,s3
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	d70080e7          	jalr	-656(ra) # 800049d8 <fileclose>
    iunlockput(ip);
    80005c70:	8526                	mv	a0,s1
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	134080e7          	jalr	308(ra) # 80003da6 <iunlockput>
    end_op();
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	914080e7          	jalr	-1772(ra) # 8000458e <end_op>
    return -1;
    80005c82:	557d                	li	a0,-1
    80005c84:	b7b9                	j	80005bd2 <sys_open+0xe4>

0000000080005c86 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c86:	7175                	addi	sp,sp,-144
    80005c88:	e506                	sd	ra,136(sp)
    80005c8a:	e122                	sd	s0,128(sp)
    80005c8c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	882080e7          	jalr	-1918(ra) # 80004510 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c96:	08000613          	li	a2,128
    80005c9a:	f7040593          	addi	a1,s0,-144
    80005c9e:	4501                	li	a0,0
    80005ca0:	ffffd097          	auipc	ra,0xffffd
    80005ca4:	2ce080e7          	jalr	718(ra) # 80002f6e <argstr>
    80005ca8:	02054963          	bltz	a0,80005cda <sys_mkdir+0x54>
    80005cac:	4681                	li	a3,0
    80005cae:	4601                	li	a2,0
    80005cb0:	4585                	li	a1,1
    80005cb2:	f7040513          	addi	a0,s0,-144
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	7fc080e7          	jalr	2044(ra) # 800054b2 <create>
    80005cbe:	cd11                	beqz	a0,80005cda <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	0e6080e7          	jalr	230(ra) # 80003da6 <iunlockput>
  end_op();
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	8c6080e7          	jalr	-1850(ra) # 8000458e <end_op>
  return 0;
    80005cd0:	4501                	li	a0,0
}
    80005cd2:	60aa                	ld	ra,136(sp)
    80005cd4:	640a                	ld	s0,128(sp)
    80005cd6:	6149                	addi	sp,sp,144
    80005cd8:	8082                	ret
    end_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	8b4080e7          	jalr	-1868(ra) # 8000458e <end_op>
    return -1;
    80005ce2:	557d                	li	a0,-1
    80005ce4:	b7fd                	j	80005cd2 <sys_mkdir+0x4c>

0000000080005ce6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ce6:	7135                	addi	sp,sp,-160
    80005ce8:	ed06                	sd	ra,152(sp)
    80005cea:	e922                	sd	s0,144(sp)
    80005cec:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	822080e7          	jalr	-2014(ra) # 80004510 <begin_op>
  argint(1, &major);
    80005cf6:	f6c40593          	addi	a1,s0,-148
    80005cfa:	4505                	li	a0,1
    80005cfc:	ffffd097          	auipc	ra,0xffffd
    80005d00:	232080e7          	jalr	562(ra) # 80002f2e <argint>
  argint(2, &minor);
    80005d04:	f6840593          	addi	a1,s0,-152
    80005d08:	4509                	li	a0,2
    80005d0a:	ffffd097          	auipc	ra,0xffffd
    80005d0e:	224080e7          	jalr	548(ra) # 80002f2e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d12:	08000613          	li	a2,128
    80005d16:	f7040593          	addi	a1,s0,-144
    80005d1a:	4501                	li	a0,0
    80005d1c:	ffffd097          	auipc	ra,0xffffd
    80005d20:	252080e7          	jalr	594(ra) # 80002f6e <argstr>
    80005d24:	02054b63          	bltz	a0,80005d5a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d28:	f6841683          	lh	a3,-152(s0)
    80005d2c:	f6c41603          	lh	a2,-148(s0)
    80005d30:	458d                	li	a1,3
    80005d32:	f7040513          	addi	a0,s0,-144
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	77c080e7          	jalr	1916(ra) # 800054b2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d3e:	cd11                	beqz	a0,80005d5a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	066080e7          	jalr	102(ra) # 80003da6 <iunlockput>
  end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	846080e7          	jalr	-1978(ra) # 8000458e <end_op>
  return 0;
    80005d50:	4501                	li	a0,0
}
    80005d52:	60ea                	ld	ra,152(sp)
    80005d54:	644a                	ld	s0,144(sp)
    80005d56:	610d                	addi	sp,sp,160
    80005d58:	8082                	ret
    end_op();
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	834080e7          	jalr	-1996(ra) # 8000458e <end_op>
    return -1;
    80005d62:	557d                	li	a0,-1
    80005d64:	b7fd                	j	80005d52 <sys_mknod+0x6c>

0000000080005d66 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d66:	7135                	addi	sp,sp,-160
    80005d68:	ed06                	sd	ra,152(sp)
    80005d6a:	e922                	sd	s0,144(sp)
    80005d6c:	e526                	sd	s1,136(sp)
    80005d6e:	e14a                	sd	s2,128(sp)
    80005d70:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d72:	ffffc097          	auipc	ra,0xffffc
    80005d76:	e44080e7          	jalr	-444(ra) # 80001bb6 <myproc>
    80005d7a:	892a                	mv	s2,a0
  
  begin_op();
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	794080e7          	jalr	1940(ra) # 80004510 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d84:	08000613          	li	a2,128
    80005d88:	f6040593          	addi	a1,s0,-160
    80005d8c:	4501                	li	a0,0
    80005d8e:	ffffd097          	auipc	ra,0xffffd
    80005d92:	1e0080e7          	jalr	480(ra) # 80002f6e <argstr>
    80005d96:	04054b63          	bltz	a0,80005dec <sys_chdir+0x86>
    80005d9a:	f6040513          	addi	a0,s0,-160
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	552080e7          	jalr	1362(ra) # 800042f0 <namei>
    80005da6:	84aa                	mv	s1,a0
    80005da8:	c131                	beqz	a0,80005dec <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	d9a080e7          	jalr	-614(ra) # 80003b44 <ilock>
  if(ip->type != T_DIR){
    80005db2:	04449703          	lh	a4,68(s1)
    80005db6:	4785                	li	a5,1
    80005db8:	04f71063          	bne	a4,a5,80005df8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dbc:	8526                	mv	a0,s1
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	e48080e7          	jalr	-440(ra) # 80003c06 <iunlock>
  iput(p->cwd);
    80005dc6:	15893503          	ld	a0,344(s2)
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	f34080e7          	jalr	-204(ra) # 80003cfe <iput>
  end_op();
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	7bc080e7          	jalr	1980(ra) # 8000458e <end_op>
  p->cwd = ip;
    80005dda:	14993c23          	sd	s1,344(s2)
  return 0;
    80005dde:	4501                	li	a0,0
}
    80005de0:	60ea                	ld	ra,152(sp)
    80005de2:	644a                	ld	s0,144(sp)
    80005de4:	64aa                	ld	s1,136(sp)
    80005de6:	690a                	ld	s2,128(sp)
    80005de8:	610d                	addi	sp,sp,160
    80005dea:	8082                	ret
    end_op();
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	7a2080e7          	jalr	1954(ra) # 8000458e <end_op>
    return -1;
    80005df4:	557d                	li	a0,-1
    80005df6:	b7ed                	j	80005de0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005df8:	8526                	mv	a0,s1
    80005dfa:	ffffe097          	auipc	ra,0xffffe
    80005dfe:	fac080e7          	jalr	-84(ra) # 80003da6 <iunlockput>
    end_op();
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	78c080e7          	jalr	1932(ra) # 8000458e <end_op>
    return -1;
    80005e0a:	557d                	li	a0,-1
    80005e0c:	bfd1                	j	80005de0 <sys_chdir+0x7a>

0000000080005e0e <sys_exec>:

uint64
sys_exec(void)
{
    80005e0e:	7145                	addi	sp,sp,-464
    80005e10:	e786                	sd	ra,456(sp)
    80005e12:	e3a2                	sd	s0,448(sp)
    80005e14:	ff26                	sd	s1,440(sp)
    80005e16:	fb4a                	sd	s2,432(sp)
    80005e18:	f74e                	sd	s3,424(sp)
    80005e1a:	f352                	sd	s4,416(sp)
    80005e1c:	ef56                	sd	s5,408(sp)
    80005e1e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e20:	e3840593          	addi	a1,s0,-456
    80005e24:	4505                	li	a0,1
    80005e26:	ffffd097          	auipc	ra,0xffffd
    80005e2a:	128080e7          	jalr	296(ra) # 80002f4e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e2e:	08000613          	li	a2,128
    80005e32:	f4040593          	addi	a1,s0,-192
    80005e36:	4501                	li	a0,0
    80005e38:	ffffd097          	auipc	ra,0xffffd
    80005e3c:	136080e7          	jalr	310(ra) # 80002f6e <argstr>
    80005e40:	87aa                	mv	a5,a0
    return -1;
    80005e42:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e44:	0c07c363          	bltz	a5,80005f0a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e48:	10000613          	li	a2,256
    80005e4c:	4581                	li	a1,0
    80005e4e:	e4040513          	addi	a0,s0,-448
    80005e52:	ffffb097          	auipc	ra,0xffffb
    80005e56:	e80080e7          	jalr	-384(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e5a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e5e:	89a6                	mv	s3,s1
    80005e60:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e62:	02000a13          	li	s4,32
    80005e66:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e6a:	00391513          	slli	a0,s2,0x3
    80005e6e:	e3040593          	addi	a1,s0,-464
    80005e72:	e3843783          	ld	a5,-456(s0)
    80005e76:	953e                	add	a0,a0,a5
    80005e78:	ffffd097          	auipc	ra,0xffffd
    80005e7c:	018080e7          	jalr	24(ra) # 80002e90 <fetchaddr>
    80005e80:	02054a63          	bltz	a0,80005eb4 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e84:	e3043783          	ld	a5,-464(s0)
    80005e88:	c3b9                	beqz	a5,80005ece <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e8a:	ffffb097          	auipc	ra,0xffffb
    80005e8e:	c5c080e7          	jalr	-932(ra) # 80000ae6 <kalloc>
    80005e92:	85aa                	mv	a1,a0
    80005e94:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e98:	cd11                	beqz	a0,80005eb4 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e9a:	6605                	lui	a2,0x1
    80005e9c:	e3043503          	ld	a0,-464(s0)
    80005ea0:	ffffd097          	auipc	ra,0xffffd
    80005ea4:	042080e7          	jalr	66(ra) # 80002ee2 <fetchstr>
    80005ea8:	00054663          	bltz	a0,80005eb4 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005eac:	0905                	addi	s2,s2,1
    80005eae:	09a1                	addi	s3,s3,8
    80005eb0:	fb491be3          	bne	s2,s4,80005e66 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eb4:	f4040913          	addi	s2,s0,-192
    80005eb8:	6088                	ld	a0,0(s1)
    80005eba:	c539                	beqz	a0,80005f08 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ebc:	ffffb097          	auipc	ra,0xffffb
    80005ec0:	b2c080e7          	jalr	-1236(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec4:	04a1                	addi	s1,s1,8
    80005ec6:	ff2499e3          	bne	s1,s2,80005eb8 <sys_exec+0xaa>
  return -1;
    80005eca:	557d                	li	a0,-1
    80005ecc:	a83d                	j	80005f0a <sys_exec+0xfc>
      argv[i] = 0;
    80005ece:	0a8e                	slli	s5,s5,0x3
    80005ed0:	fc0a8793          	addi	a5,s5,-64
    80005ed4:	00878ab3          	add	s5,a5,s0
    80005ed8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005edc:	e4040593          	addi	a1,s0,-448
    80005ee0:	f4040513          	addi	a0,s0,-192
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	16e080e7          	jalr	366(ra) # 80005052 <exec>
    80005eec:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eee:	f4040993          	addi	s3,s0,-192
    80005ef2:	6088                	ld	a0,0(s1)
    80005ef4:	c901                	beqz	a0,80005f04 <sys_exec+0xf6>
    kfree(argv[i]);
    80005ef6:	ffffb097          	auipc	ra,0xffffb
    80005efa:	af2080e7          	jalr	-1294(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005efe:	04a1                	addi	s1,s1,8
    80005f00:	ff3499e3          	bne	s1,s3,80005ef2 <sys_exec+0xe4>
  return ret;
    80005f04:	854a                	mv	a0,s2
    80005f06:	a011                	j	80005f0a <sys_exec+0xfc>
  return -1;
    80005f08:	557d                	li	a0,-1
}
    80005f0a:	60be                	ld	ra,456(sp)
    80005f0c:	641e                	ld	s0,448(sp)
    80005f0e:	74fa                	ld	s1,440(sp)
    80005f10:	795a                	ld	s2,432(sp)
    80005f12:	79ba                	ld	s3,424(sp)
    80005f14:	7a1a                	ld	s4,416(sp)
    80005f16:	6afa                	ld	s5,408(sp)
    80005f18:	6179                	addi	sp,sp,464
    80005f1a:	8082                	ret

0000000080005f1c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f1c:	7139                	addi	sp,sp,-64
    80005f1e:	fc06                	sd	ra,56(sp)
    80005f20:	f822                	sd	s0,48(sp)
    80005f22:	f426                	sd	s1,40(sp)
    80005f24:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f26:	ffffc097          	auipc	ra,0xffffc
    80005f2a:	c90080e7          	jalr	-880(ra) # 80001bb6 <myproc>
    80005f2e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f30:	fd840593          	addi	a1,s0,-40
    80005f34:	4501                	li	a0,0
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	018080e7          	jalr	24(ra) # 80002f4e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f3e:	fc840593          	addi	a1,s0,-56
    80005f42:	fd040513          	addi	a0,s0,-48
    80005f46:	fffff097          	auipc	ra,0xfffff
    80005f4a:	dc2080e7          	jalr	-574(ra) # 80004d08 <pipealloc>
    return -1;
    80005f4e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f50:	0c054463          	bltz	a0,80006018 <sys_pipe+0xfc>
  fd0 = -1;
    80005f54:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f58:	fd043503          	ld	a0,-48(s0)
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	514080e7          	jalr	1300(ra) # 80005470 <fdalloc>
    80005f64:	fca42223          	sw	a0,-60(s0)
    80005f68:	08054b63          	bltz	a0,80005ffe <sys_pipe+0xe2>
    80005f6c:	fc843503          	ld	a0,-56(s0)
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	500080e7          	jalr	1280(ra) # 80005470 <fdalloc>
    80005f78:	fca42023          	sw	a0,-64(s0)
    80005f7c:	06054863          	bltz	a0,80005fec <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f80:	4691                	li	a3,4
    80005f82:	fc440613          	addi	a2,s0,-60
    80005f86:	fd843583          	ld	a1,-40(s0)
    80005f8a:	6ca8                	ld	a0,88(s1)
    80005f8c:	ffffb097          	auipc	ra,0xffffb
    80005f90:	6e0080e7          	jalr	1760(ra) # 8000166c <copyout>
    80005f94:	02054063          	bltz	a0,80005fb4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f98:	4691                	li	a3,4
    80005f9a:	fc040613          	addi	a2,s0,-64
    80005f9e:	fd843583          	ld	a1,-40(s0)
    80005fa2:	0591                	addi	a1,a1,4
    80005fa4:	6ca8                	ld	a0,88(s1)
    80005fa6:	ffffb097          	auipc	ra,0xffffb
    80005faa:	6c6080e7          	jalr	1734(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fae:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fb0:	06055463          	bgez	a0,80006018 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005fb4:	fc442783          	lw	a5,-60(s0)
    80005fb8:	07e9                	addi	a5,a5,26
    80005fba:	078e                	slli	a5,a5,0x3
    80005fbc:	97a6                	add	a5,a5,s1
    80005fbe:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005fc2:	fc042783          	lw	a5,-64(s0)
    80005fc6:	07e9                	addi	a5,a5,26
    80005fc8:	078e                	slli	a5,a5,0x3
    80005fca:	94be                	add	s1,s1,a5
    80005fcc:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005fd0:	fd043503          	ld	a0,-48(s0)
    80005fd4:	fffff097          	auipc	ra,0xfffff
    80005fd8:	a04080e7          	jalr	-1532(ra) # 800049d8 <fileclose>
    fileclose(wf);
    80005fdc:	fc843503          	ld	a0,-56(s0)
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	9f8080e7          	jalr	-1544(ra) # 800049d8 <fileclose>
    return -1;
    80005fe8:	57fd                	li	a5,-1
    80005fea:	a03d                	j	80006018 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005fec:	fc442783          	lw	a5,-60(s0)
    80005ff0:	0007c763          	bltz	a5,80005ffe <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ff4:	07e9                	addi	a5,a5,26
    80005ff6:	078e                	slli	a5,a5,0x3
    80005ff8:	97a6                	add	a5,a5,s1
    80005ffa:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005ffe:	fd043503          	ld	a0,-48(s0)
    80006002:	fffff097          	auipc	ra,0xfffff
    80006006:	9d6080e7          	jalr	-1578(ra) # 800049d8 <fileclose>
    fileclose(wf);
    8000600a:	fc843503          	ld	a0,-56(s0)
    8000600e:	fffff097          	auipc	ra,0xfffff
    80006012:	9ca080e7          	jalr	-1590(ra) # 800049d8 <fileclose>
    return -1;
    80006016:	57fd                	li	a5,-1
}
    80006018:	853e                	mv	a0,a5
    8000601a:	70e2                	ld	ra,56(sp)
    8000601c:	7442                	ld	s0,48(sp)
    8000601e:	74a2                	ld	s1,40(sp)
    80006020:	6121                	addi	sp,sp,64
    80006022:	8082                	ret
	...

0000000080006030 <kernelvec>:
    80006030:	7111                	addi	sp,sp,-256
    80006032:	e006                	sd	ra,0(sp)
    80006034:	e40a                	sd	sp,8(sp)
    80006036:	e80e                	sd	gp,16(sp)
    80006038:	ec12                	sd	tp,24(sp)
    8000603a:	f016                	sd	t0,32(sp)
    8000603c:	f41a                	sd	t1,40(sp)
    8000603e:	f81e                	sd	t2,48(sp)
    80006040:	fc22                	sd	s0,56(sp)
    80006042:	e0a6                	sd	s1,64(sp)
    80006044:	e4aa                	sd	a0,72(sp)
    80006046:	e8ae                	sd	a1,80(sp)
    80006048:	ecb2                	sd	a2,88(sp)
    8000604a:	f0b6                	sd	a3,96(sp)
    8000604c:	f4ba                	sd	a4,104(sp)
    8000604e:	f8be                	sd	a5,112(sp)
    80006050:	fcc2                	sd	a6,120(sp)
    80006052:	e146                	sd	a7,128(sp)
    80006054:	e54a                	sd	s2,136(sp)
    80006056:	e94e                	sd	s3,144(sp)
    80006058:	ed52                	sd	s4,152(sp)
    8000605a:	f156                	sd	s5,160(sp)
    8000605c:	f55a                	sd	s6,168(sp)
    8000605e:	f95e                	sd	s7,176(sp)
    80006060:	fd62                	sd	s8,184(sp)
    80006062:	e1e6                	sd	s9,192(sp)
    80006064:	e5ea                	sd	s10,200(sp)
    80006066:	e9ee                	sd	s11,208(sp)
    80006068:	edf2                	sd	t3,216(sp)
    8000606a:	f1f6                	sd	t4,224(sp)
    8000606c:	f5fa                	sd	t5,232(sp)
    8000606e:	f9fe                	sd	t6,240(sp)
    80006070:	cebfc0ef          	jal	ra,80002d5a <kerneltrap>
    80006074:	6082                	ld	ra,0(sp)
    80006076:	6122                	ld	sp,8(sp)
    80006078:	61c2                	ld	gp,16(sp)
    8000607a:	7282                	ld	t0,32(sp)
    8000607c:	7322                	ld	t1,40(sp)
    8000607e:	73c2                	ld	t2,48(sp)
    80006080:	7462                	ld	s0,56(sp)
    80006082:	6486                	ld	s1,64(sp)
    80006084:	6526                	ld	a0,72(sp)
    80006086:	65c6                	ld	a1,80(sp)
    80006088:	6666                	ld	a2,88(sp)
    8000608a:	7686                	ld	a3,96(sp)
    8000608c:	7726                	ld	a4,104(sp)
    8000608e:	77c6                	ld	a5,112(sp)
    80006090:	7866                	ld	a6,120(sp)
    80006092:	688a                	ld	a7,128(sp)
    80006094:	692a                	ld	s2,136(sp)
    80006096:	69ca                	ld	s3,144(sp)
    80006098:	6a6a                	ld	s4,152(sp)
    8000609a:	7a8a                	ld	s5,160(sp)
    8000609c:	7b2a                	ld	s6,168(sp)
    8000609e:	7bca                	ld	s7,176(sp)
    800060a0:	7c6a                	ld	s8,184(sp)
    800060a2:	6c8e                	ld	s9,192(sp)
    800060a4:	6d2e                	ld	s10,200(sp)
    800060a6:	6dce                	ld	s11,208(sp)
    800060a8:	6e6e                	ld	t3,216(sp)
    800060aa:	7e8e                	ld	t4,224(sp)
    800060ac:	7f2e                	ld	t5,232(sp)
    800060ae:	7fce                	ld	t6,240(sp)
    800060b0:	6111                	addi	sp,sp,256
    800060b2:	10200073          	sret
    800060b6:	00000013          	nop
    800060ba:	00000013          	nop
    800060be:	0001                	nop

00000000800060c0 <timervec>:
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	e10c                	sd	a1,0(a0)
    800060c6:	e510                	sd	a2,8(a0)
    800060c8:	e914                	sd	a3,16(a0)
    800060ca:	6d0c                	ld	a1,24(a0)
    800060cc:	7110                	ld	a2,32(a0)
    800060ce:	6194                	ld	a3,0(a1)
    800060d0:	96b2                	add	a3,a3,a2
    800060d2:	e194                	sd	a3,0(a1)
    800060d4:	4589                	li	a1,2
    800060d6:	14459073          	csrw	sip,a1
    800060da:	6914                	ld	a3,16(a0)
    800060dc:	6510                	ld	a2,8(a0)
    800060de:	610c                	ld	a1,0(a0)
    800060e0:	34051573          	csrrw	a0,mscratch,a0
    800060e4:	30200073          	mret
	...

00000000800060ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ea:	1141                	addi	sp,sp,-16
    800060ec:	e422                	sd	s0,8(sp)
    800060ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060f0:	0c0007b7          	lui	a5,0xc000
    800060f4:	4705                	li	a4,1
    800060f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060f8:	c3d8                	sw	a4,4(a5)
}
    800060fa:	6422                	ld	s0,8(sp)
    800060fc:	0141                	addi	sp,sp,16
    800060fe:	8082                	ret

0000000080006100 <plicinithart>:

void
plicinithart(void)
{
    80006100:	1141                	addi	sp,sp,-16
    80006102:	e406                	sd	ra,8(sp)
    80006104:	e022                	sd	s0,0(sp)
    80006106:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	a82080e7          	jalr	-1406(ra) # 80001b8a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006110:	0085171b          	slliw	a4,a0,0x8
    80006114:	0c0027b7          	lui	a5,0xc002
    80006118:	97ba                	add	a5,a5,a4
    8000611a:	40200713          	li	a4,1026
    8000611e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006122:	00d5151b          	slliw	a0,a0,0xd
    80006126:	0c2017b7          	lui	a5,0xc201
    8000612a:	97aa                	add	a5,a5,a0
    8000612c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006130:	60a2                	ld	ra,8(sp)
    80006132:	6402                	ld	s0,0(sp)
    80006134:	0141                	addi	sp,sp,16
    80006136:	8082                	ret

0000000080006138 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006138:	1141                	addi	sp,sp,-16
    8000613a:	e406                	sd	ra,8(sp)
    8000613c:	e022                	sd	s0,0(sp)
    8000613e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006140:	ffffc097          	auipc	ra,0xffffc
    80006144:	a4a080e7          	jalr	-1462(ra) # 80001b8a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006148:	00d5151b          	slliw	a0,a0,0xd
    8000614c:	0c2017b7          	lui	a5,0xc201
    80006150:	97aa                	add	a5,a5,a0
  return irq;
}
    80006152:	43c8                	lw	a0,4(a5)
    80006154:	60a2                	ld	ra,8(sp)
    80006156:	6402                	ld	s0,0(sp)
    80006158:	0141                	addi	sp,sp,16
    8000615a:	8082                	ret

000000008000615c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000615c:	1101                	addi	sp,sp,-32
    8000615e:	ec06                	sd	ra,24(sp)
    80006160:	e822                	sd	s0,16(sp)
    80006162:	e426                	sd	s1,8(sp)
    80006164:	1000                	addi	s0,sp,32
    80006166:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006168:	ffffc097          	auipc	ra,0xffffc
    8000616c:	a22080e7          	jalr	-1502(ra) # 80001b8a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006170:	00d5151b          	slliw	a0,a0,0xd
    80006174:	0c2017b7          	lui	a5,0xc201
    80006178:	97aa                	add	a5,a5,a0
    8000617a:	c3c4                	sw	s1,4(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6105                	addi	sp,sp,32
    80006184:	8082                	ret

0000000080006186 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006186:	1141                	addi	sp,sp,-16
    80006188:	e406                	sd	ra,8(sp)
    8000618a:	e022                	sd	s0,0(sp)
    8000618c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000618e:	479d                	li	a5,7
    80006190:	04a7cc63          	blt	a5,a0,800061e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006194:	0001c797          	auipc	a5,0x1c
    80006198:	dcc78793          	addi	a5,a5,-564 # 80021f60 <disk>
    8000619c:	97aa                	add	a5,a5,a0
    8000619e:	0187c783          	lbu	a5,24(a5)
    800061a2:	ebb9                	bnez	a5,800061f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061a4:	00451693          	slli	a3,a0,0x4
    800061a8:	0001c797          	auipc	a5,0x1c
    800061ac:	db878793          	addi	a5,a5,-584 # 80021f60 <disk>
    800061b0:	6398                	ld	a4,0(a5)
    800061b2:	9736                	add	a4,a4,a3
    800061b4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800061b8:	6398                	ld	a4,0(a5)
    800061ba:	9736                	add	a4,a4,a3
    800061bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800061c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800061c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800061c8:	97aa                	add	a5,a5,a0
    800061ca:	4705                	li	a4,1
    800061cc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800061d0:	0001c517          	auipc	a0,0x1c
    800061d4:	da850513          	addi	a0,a0,-600 # 80021f78 <disk+0x18>
    800061d8:	ffffc097          	auipc	ra,0xffffc
    800061dc:	202080e7          	jalr	514(ra) # 800023da <wakeup>
}
    800061e0:	60a2                	ld	ra,8(sp)
    800061e2:	6402                	ld	s0,0(sp)
    800061e4:	0141                	addi	sp,sp,16
    800061e6:	8082                	ret
    panic("free_desc 1");
    800061e8:	00002517          	auipc	a0,0x2
    800061ec:	64850513          	addi	a0,a0,1608 # 80008830 <syscalls+0x310>
    800061f0:	ffffa097          	auipc	ra,0xffffa
    800061f4:	350080e7          	jalr	848(ra) # 80000540 <panic>
    panic("free_desc 2");
    800061f8:	00002517          	auipc	a0,0x2
    800061fc:	64850513          	addi	a0,a0,1608 # 80008840 <syscalls+0x320>
    80006200:	ffffa097          	auipc	ra,0xffffa
    80006204:	340080e7          	jalr	832(ra) # 80000540 <panic>

0000000080006208 <virtio_disk_init>:
{
    80006208:	1101                	addi	sp,sp,-32
    8000620a:	ec06                	sd	ra,24(sp)
    8000620c:	e822                	sd	s0,16(sp)
    8000620e:	e426                	sd	s1,8(sp)
    80006210:	e04a                	sd	s2,0(sp)
    80006212:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006214:	00002597          	auipc	a1,0x2
    80006218:	63c58593          	addi	a1,a1,1596 # 80008850 <syscalls+0x330>
    8000621c:	0001c517          	auipc	a0,0x1c
    80006220:	e6c50513          	addi	a0,a0,-404 # 80022088 <disk+0x128>
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	922080e7          	jalr	-1758(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000622c:	100017b7          	lui	a5,0x10001
    80006230:	4398                	lw	a4,0(a5)
    80006232:	2701                	sext.w	a4,a4
    80006234:	747277b7          	lui	a5,0x74727
    80006238:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000623c:	14f71b63          	bne	a4,a5,80006392 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006240:	100017b7          	lui	a5,0x10001
    80006244:	43dc                	lw	a5,4(a5)
    80006246:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006248:	4709                	li	a4,2
    8000624a:	14e79463          	bne	a5,a4,80006392 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000624e:	100017b7          	lui	a5,0x10001
    80006252:	479c                	lw	a5,8(a5)
    80006254:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006256:	12e79e63          	bne	a5,a4,80006392 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000625a:	100017b7          	lui	a5,0x10001
    8000625e:	47d8                	lw	a4,12(a5)
    80006260:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006262:	554d47b7          	lui	a5,0x554d4
    80006266:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000626a:	12f71463          	bne	a4,a5,80006392 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000626e:	100017b7          	lui	a5,0x10001
    80006272:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006276:	4705                	li	a4,1
    80006278:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000627a:	470d                	li	a4,3
    8000627c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000627e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006280:	c7ffe6b7          	lui	a3,0xc7ffe
    80006284:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc6bf>
    80006288:	8f75                	and	a4,a4,a3
    8000628a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000628c:	472d                	li	a4,11
    8000628e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006290:	5bbc                	lw	a5,112(a5)
    80006292:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006296:	8ba1                	andi	a5,a5,8
    80006298:	10078563          	beqz	a5,800063a2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000629c:	100017b7          	lui	a5,0x10001
    800062a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800062a4:	43fc                	lw	a5,68(a5)
    800062a6:	2781                	sext.w	a5,a5
    800062a8:	10079563          	bnez	a5,800063b2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062ac:	100017b7          	lui	a5,0x10001
    800062b0:	5bdc                	lw	a5,52(a5)
    800062b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062b4:	10078763          	beqz	a5,800063c2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800062b8:	471d                	li	a4,7
    800062ba:	10f77c63          	bgeu	a4,a5,800063d2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800062be:	ffffb097          	auipc	ra,0xffffb
    800062c2:	828080e7          	jalr	-2008(ra) # 80000ae6 <kalloc>
    800062c6:	0001c497          	auipc	s1,0x1c
    800062ca:	c9a48493          	addi	s1,s1,-870 # 80021f60 <disk>
    800062ce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	816080e7          	jalr	-2026(ra) # 80000ae6 <kalloc>
    800062d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800062da:	ffffb097          	auipc	ra,0xffffb
    800062de:	80c080e7          	jalr	-2036(ra) # 80000ae6 <kalloc>
    800062e2:	87aa                	mv	a5,a0
    800062e4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062e6:	6088                	ld	a0,0(s1)
    800062e8:	cd6d                	beqz	a0,800063e2 <virtio_disk_init+0x1da>
    800062ea:	0001c717          	auipc	a4,0x1c
    800062ee:	c7e73703          	ld	a4,-898(a4) # 80021f68 <disk+0x8>
    800062f2:	cb65                	beqz	a4,800063e2 <virtio_disk_init+0x1da>
    800062f4:	c7fd                	beqz	a5,800063e2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800062f6:	6605                	lui	a2,0x1
    800062f8:	4581                	li	a1,0
    800062fa:	ffffb097          	auipc	ra,0xffffb
    800062fe:	9d8080e7          	jalr	-1576(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006302:	0001c497          	auipc	s1,0x1c
    80006306:	c5e48493          	addi	s1,s1,-930 # 80021f60 <disk>
    8000630a:	6605                	lui	a2,0x1
    8000630c:	4581                	li	a1,0
    8000630e:	6488                	ld	a0,8(s1)
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	9c2080e7          	jalr	-1598(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006318:	6605                	lui	a2,0x1
    8000631a:	4581                	li	a1,0
    8000631c:	6888                	ld	a0,16(s1)
    8000631e:	ffffb097          	auipc	ra,0xffffb
    80006322:	9b4080e7          	jalr	-1612(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006326:	100017b7          	lui	a5,0x10001
    8000632a:	4721                	li	a4,8
    8000632c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000632e:	4098                	lw	a4,0(s1)
    80006330:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006334:	40d8                	lw	a4,4(s1)
    80006336:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000633a:	6498                	ld	a4,8(s1)
    8000633c:	0007069b          	sext.w	a3,a4
    80006340:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006344:	9701                	srai	a4,a4,0x20
    80006346:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000634a:	6898                	ld	a4,16(s1)
    8000634c:	0007069b          	sext.w	a3,a4
    80006350:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006354:	9701                	srai	a4,a4,0x20
    80006356:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000635a:	4705                	li	a4,1
    8000635c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000635e:	00e48c23          	sb	a4,24(s1)
    80006362:	00e48ca3          	sb	a4,25(s1)
    80006366:	00e48d23          	sb	a4,26(s1)
    8000636a:	00e48da3          	sb	a4,27(s1)
    8000636e:	00e48e23          	sb	a4,28(s1)
    80006372:	00e48ea3          	sb	a4,29(s1)
    80006376:	00e48f23          	sb	a4,30(s1)
    8000637a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000637e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006382:	0727a823          	sw	s2,112(a5)
}
    80006386:	60e2                	ld	ra,24(sp)
    80006388:	6442                	ld	s0,16(sp)
    8000638a:	64a2                	ld	s1,8(sp)
    8000638c:	6902                	ld	s2,0(sp)
    8000638e:	6105                	addi	sp,sp,32
    80006390:	8082                	ret
    panic("could not find virtio disk");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	4ce50513          	addi	a0,a0,1230 # 80008860 <syscalls+0x340>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a6080e7          	jalr	422(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	4de50513          	addi	a0,a0,1246 # 80008880 <syscalls+0x360>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	196080e7          	jalr	406(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	4ee50513          	addi	a0,a0,1262 # 800088a0 <syscalls+0x380>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	186080e7          	jalr	390(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	4fe50513          	addi	a0,a0,1278 # 800088c0 <syscalls+0x3a0>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	176080e7          	jalr	374(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	50e50513          	addi	a0,a0,1294 # 800088e0 <syscalls+0x3c0>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	166080e7          	jalr	358(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	51e50513          	addi	a0,a0,1310 # 80008900 <syscalls+0x3e0>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	156080e7          	jalr	342(ra) # 80000540 <panic>

00000000800063f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063f2:	7119                	addi	sp,sp,-128
    800063f4:	fc86                	sd	ra,120(sp)
    800063f6:	f8a2                	sd	s0,112(sp)
    800063f8:	f4a6                	sd	s1,104(sp)
    800063fa:	f0ca                	sd	s2,96(sp)
    800063fc:	ecce                	sd	s3,88(sp)
    800063fe:	e8d2                	sd	s4,80(sp)
    80006400:	e4d6                	sd	s5,72(sp)
    80006402:	e0da                	sd	s6,64(sp)
    80006404:	fc5e                	sd	s7,56(sp)
    80006406:	f862                	sd	s8,48(sp)
    80006408:	f466                	sd	s9,40(sp)
    8000640a:	f06a                	sd	s10,32(sp)
    8000640c:	ec6e                	sd	s11,24(sp)
    8000640e:	0100                	addi	s0,sp,128
    80006410:	8aaa                	mv	s5,a0
    80006412:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006414:	00c52d03          	lw	s10,12(a0)
    80006418:	001d1d1b          	slliw	s10,s10,0x1
    8000641c:	1d02                	slli	s10,s10,0x20
    8000641e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006422:	0001c517          	auipc	a0,0x1c
    80006426:	c6650513          	addi	a0,a0,-922 # 80022088 <disk+0x128>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	7ac080e7          	jalr	1964(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006432:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006434:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006436:	0001cb97          	auipc	s7,0x1c
    8000643a:	b2ab8b93          	addi	s7,s7,-1238 # 80021f60 <disk>
  for(int i = 0; i < 3; i++){
    8000643e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006440:	0001cc97          	auipc	s9,0x1c
    80006444:	c48c8c93          	addi	s9,s9,-952 # 80022088 <disk+0x128>
    80006448:	a08d                	j	800064aa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000644a:	00fb8733          	add	a4,s7,a5
    8000644e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006452:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006454:	0207c563          	bltz	a5,8000647e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006458:	2905                	addiw	s2,s2,1
    8000645a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000645c:	05690c63          	beq	s2,s6,800064b4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006460:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006462:	0001c717          	auipc	a4,0x1c
    80006466:	afe70713          	addi	a4,a4,-1282 # 80021f60 <disk>
    8000646a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000646c:	01874683          	lbu	a3,24(a4)
    80006470:	fee9                	bnez	a3,8000644a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006472:	2785                	addiw	a5,a5,1
    80006474:	0705                	addi	a4,a4,1
    80006476:	fe979be3          	bne	a5,s1,8000646c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000647a:	57fd                	li	a5,-1
    8000647c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000647e:	01205d63          	blez	s2,80006498 <virtio_disk_rw+0xa6>
    80006482:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006484:	000a2503          	lw	a0,0(s4)
    80006488:	00000097          	auipc	ra,0x0
    8000648c:	cfe080e7          	jalr	-770(ra) # 80006186 <free_desc>
      for(int j = 0; j < i; j++)
    80006490:	2d85                	addiw	s11,s11,1
    80006492:	0a11                	addi	s4,s4,4
    80006494:	ff2d98e3          	bne	s11,s2,80006484 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006498:	85e6                	mv	a1,s9
    8000649a:	0001c517          	auipc	a0,0x1c
    8000649e:	ade50513          	addi	a0,a0,-1314 # 80021f78 <disk+0x18>
    800064a2:	ffffc097          	auipc	ra,0xffffc
    800064a6:	ed4080e7          	jalr	-300(ra) # 80002376 <sleep>
  for(int i = 0; i < 3; i++){
    800064aa:	f8040a13          	addi	s4,s0,-128
{
    800064ae:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800064b0:	894e                	mv	s2,s3
    800064b2:	b77d                	j	80006460 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064b4:	f8042503          	lw	a0,-128(s0)
    800064b8:	00a50713          	addi	a4,a0,10
    800064bc:	0712                	slli	a4,a4,0x4

  if(write)
    800064be:	0001c797          	auipc	a5,0x1c
    800064c2:	aa278793          	addi	a5,a5,-1374 # 80021f60 <disk>
    800064c6:	00e786b3          	add	a3,a5,a4
    800064ca:	01803633          	snez	a2,s8
    800064ce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064d0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800064d4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064d8:	f6070613          	addi	a2,a4,-160
    800064dc:	6394                	ld	a3,0(a5)
    800064de:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064e0:	00870593          	addi	a1,a4,8
    800064e4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064e6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064e8:	0007b803          	ld	a6,0(a5)
    800064ec:	9642                	add	a2,a2,a6
    800064ee:	46c1                	li	a3,16
    800064f0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064f2:	4585                	li	a1,1
    800064f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800064f8:	f8442683          	lw	a3,-124(s0)
    800064fc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006500:	0692                	slli	a3,a3,0x4
    80006502:	9836                	add	a6,a6,a3
    80006504:	058a8613          	addi	a2,s5,88
    80006508:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000650c:	0007b803          	ld	a6,0(a5)
    80006510:	96c2                	add	a3,a3,a6
    80006512:	40000613          	li	a2,1024
    80006516:	c690                	sw	a2,8(a3)
  if(write)
    80006518:	001c3613          	seqz	a2,s8
    8000651c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006520:	00166613          	ori	a2,a2,1
    80006524:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006528:	f8842603          	lw	a2,-120(s0)
    8000652c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006530:	00250693          	addi	a3,a0,2
    80006534:	0692                	slli	a3,a3,0x4
    80006536:	96be                	add	a3,a3,a5
    80006538:	58fd                	li	a7,-1
    8000653a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000653e:	0612                	slli	a2,a2,0x4
    80006540:	9832                	add	a6,a6,a2
    80006542:	f9070713          	addi	a4,a4,-112
    80006546:	973e                	add	a4,a4,a5
    80006548:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000654c:	6398                	ld	a4,0(a5)
    8000654e:	9732                	add	a4,a4,a2
    80006550:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006552:	4609                	li	a2,2
    80006554:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006558:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000655c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006560:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006564:	6794                	ld	a3,8(a5)
    80006566:	0026d703          	lhu	a4,2(a3)
    8000656a:	8b1d                	andi	a4,a4,7
    8000656c:	0706                	slli	a4,a4,0x1
    8000656e:	96ba                	add	a3,a3,a4
    80006570:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006574:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006578:	6798                	ld	a4,8(a5)
    8000657a:	00275783          	lhu	a5,2(a4)
    8000657e:	2785                	addiw	a5,a5,1
    80006580:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006584:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006588:	100017b7          	lui	a5,0x10001
    8000658c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006590:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006594:	0001c917          	auipc	s2,0x1c
    80006598:	af490913          	addi	s2,s2,-1292 # 80022088 <disk+0x128>
  while(b->disk == 1) {
    8000659c:	4485                	li	s1,1
    8000659e:	00b79c63          	bne	a5,a1,800065b6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800065a2:	85ca                	mv	a1,s2
    800065a4:	8556                	mv	a0,s5
    800065a6:	ffffc097          	auipc	ra,0xffffc
    800065aa:	dd0080e7          	jalr	-560(ra) # 80002376 <sleep>
  while(b->disk == 1) {
    800065ae:	004aa783          	lw	a5,4(s5)
    800065b2:	fe9788e3          	beq	a5,s1,800065a2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065b6:	f8042903          	lw	s2,-128(s0)
    800065ba:	00290713          	addi	a4,s2,2
    800065be:	0712                	slli	a4,a4,0x4
    800065c0:	0001c797          	auipc	a5,0x1c
    800065c4:	9a078793          	addi	a5,a5,-1632 # 80021f60 <disk>
    800065c8:	97ba                	add	a5,a5,a4
    800065ca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065ce:	0001c997          	auipc	s3,0x1c
    800065d2:	99298993          	addi	s3,s3,-1646 # 80021f60 <disk>
    800065d6:	00491713          	slli	a4,s2,0x4
    800065da:	0009b783          	ld	a5,0(s3)
    800065de:	97ba                	add	a5,a5,a4
    800065e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065e4:	854a                	mv	a0,s2
    800065e6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065ea:	00000097          	auipc	ra,0x0
    800065ee:	b9c080e7          	jalr	-1124(ra) # 80006186 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065f2:	8885                	andi	s1,s1,1
    800065f4:	f0ed                	bnez	s1,800065d6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065f6:	0001c517          	auipc	a0,0x1c
    800065fa:	a9250513          	addi	a0,a0,-1390 # 80022088 <disk+0x128>
    800065fe:	ffffa097          	auipc	ra,0xffffa
    80006602:	68c080e7          	jalr	1676(ra) # 80000c8a <release>
}
    80006606:	70e6                	ld	ra,120(sp)
    80006608:	7446                	ld	s0,112(sp)
    8000660a:	74a6                	ld	s1,104(sp)
    8000660c:	7906                	ld	s2,96(sp)
    8000660e:	69e6                	ld	s3,88(sp)
    80006610:	6a46                	ld	s4,80(sp)
    80006612:	6aa6                	ld	s5,72(sp)
    80006614:	6b06                	ld	s6,64(sp)
    80006616:	7be2                	ld	s7,56(sp)
    80006618:	7c42                	ld	s8,48(sp)
    8000661a:	7ca2                	ld	s9,40(sp)
    8000661c:	7d02                	ld	s10,32(sp)
    8000661e:	6de2                	ld	s11,24(sp)
    80006620:	6109                	addi	sp,sp,128
    80006622:	8082                	ret

0000000080006624 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006624:	1101                	addi	sp,sp,-32
    80006626:	ec06                	sd	ra,24(sp)
    80006628:	e822                	sd	s0,16(sp)
    8000662a:	e426                	sd	s1,8(sp)
    8000662c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000662e:	0001c497          	auipc	s1,0x1c
    80006632:	93248493          	addi	s1,s1,-1742 # 80021f60 <disk>
    80006636:	0001c517          	auipc	a0,0x1c
    8000663a:	a5250513          	addi	a0,a0,-1454 # 80022088 <disk+0x128>
    8000663e:	ffffa097          	auipc	ra,0xffffa
    80006642:	598080e7          	jalr	1432(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006646:	10001737          	lui	a4,0x10001
    8000664a:	533c                	lw	a5,96(a4)
    8000664c:	8b8d                	andi	a5,a5,3
    8000664e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006650:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006654:	689c                	ld	a5,16(s1)
    80006656:	0204d703          	lhu	a4,32(s1)
    8000665a:	0027d783          	lhu	a5,2(a5)
    8000665e:	04f70863          	beq	a4,a5,800066ae <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006662:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006666:	6898                	ld	a4,16(s1)
    80006668:	0204d783          	lhu	a5,32(s1)
    8000666c:	8b9d                	andi	a5,a5,7
    8000666e:	078e                	slli	a5,a5,0x3
    80006670:	97ba                	add	a5,a5,a4
    80006672:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006674:	00278713          	addi	a4,a5,2
    80006678:	0712                	slli	a4,a4,0x4
    8000667a:	9726                	add	a4,a4,s1
    8000667c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006680:	e721                	bnez	a4,800066c8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006682:	0789                	addi	a5,a5,2
    80006684:	0792                	slli	a5,a5,0x4
    80006686:	97a6                	add	a5,a5,s1
    80006688:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000668a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000668e:	ffffc097          	auipc	ra,0xffffc
    80006692:	d4c080e7          	jalr	-692(ra) # 800023da <wakeup>

    disk.used_idx += 1;
    80006696:	0204d783          	lhu	a5,32(s1)
    8000669a:	2785                	addiw	a5,a5,1
    8000669c:	17c2                	slli	a5,a5,0x30
    8000669e:	93c1                	srli	a5,a5,0x30
    800066a0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066a4:	6898                	ld	a4,16(s1)
    800066a6:	00275703          	lhu	a4,2(a4)
    800066aa:	faf71ce3          	bne	a4,a5,80006662 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800066ae:	0001c517          	auipc	a0,0x1c
    800066b2:	9da50513          	addi	a0,a0,-1574 # 80022088 <disk+0x128>
    800066b6:	ffffa097          	auipc	ra,0xffffa
    800066ba:	5d4080e7          	jalr	1492(ra) # 80000c8a <release>
}
    800066be:	60e2                	ld	ra,24(sp)
    800066c0:	6442                	ld	s0,16(sp)
    800066c2:	64a2                	ld	s1,8(sp)
    800066c4:	6105                	addi	sp,sp,32
    800066c6:	8082                	ret
      panic("virtio_disk_intr status");
    800066c8:	00002517          	auipc	a0,0x2
    800066cc:	25050513          	addi	a0,a0,592 # 80008918 <syscalls+0x3f8>
    800066d0:	ffffa097          	auipc	ra,0xffffa
    800066d4:	e70080e7          	jalr	-400(ra) # 80000540 <panic>
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
