
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
    80000066:	22e78793          	addi	a5,a5,558 # 80006290 <timervec>
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
    8000012e:	740080e7          	jalr	1856(ra) # 8000286a <either_copyin>
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
    800001c4:	ab0080e7          	jalr	-1360(ra) # 80001c70 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	4ec080e7          	jalr	1260(ra) # 800026b4 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	236080e7          	jalr	566(ra) # 8000240c <sleep>
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
    80000216:	602080e7          	jalr	1538(ra) # 80002814 <either_copyout>
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
    800002f6:	5ce080e7          	jalr	1486(ra) # 800028c0 <procdump>
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
    8000044a:	02a080e7          	jalr	42(ra) # 80002470 <wakeup>
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
    800008aa:	bca080e7          	jalr	-1078(ra) # 80002470 <wakeup>
    
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
    80000934:	adc080e7          	jalr	-1316(ra) # 8000240c <sleep>
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
    80000d00:	f58080e7          	jalr	-168(ra) # 80001c54 <mycpu>
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
    80000d32:	f26080e7          	jalr	-218(ra) # 80001c54 <mycpu>
    80000d36:	5d3c                	lw	a5,120(a0)
    80000d38:	cf89                	beqz	a5,80000d52 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d3a:	00001097          	auipc	ra,0x1
    80000d3e:	f1a080e7          	jalr	-230(ra) # 80001c54 <mycpu>
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
    80000d56:	f02080e7          	jalr	-254(ra) # 80001c54 <mycpu>
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
    80000d96:	ec2080e7          	jalr	-318(ra) # 80001c54 <mycpu>
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
    80000dc2:	e96080e7          	jalr	-362(ra) # 80001c54 <mycpu>
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
    80001010:	c38080e7          	jalr	-968(ra) # 80001c44 <cpuid>
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
    8000102c:	c1c080e7          	jalr	-996(ra) # 80001c44 <cpuid>
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
    8000104e:	a9a080e7          	jalr	-1382(ra) # 80002ae4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001052:	00005097          	auipc	ra,0x5
    80001056:	27e080e7          	jalr	638(ra) # 800062d0 <plicinithart>
  }

  scheduler();        
    8000105a:	00001097          	auipc	ra,0x1
    8000105e:	290080e7          	jalr	656(ra) # 800022ea <scheduler>
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
    800010be:	aa8080e7          	jalr	-1368(ra) # 80001b62 <procinit>
    trapinit();      // trap vectors
    800010c2:	00002097          	auipc	ra,0x2
    800010c6:	9fa080e7          	jalr	-1542(ra) # 80002abc <trapinit>
    trapinithart();  // install kernel trap vector
    800010ca:	00002097          	auipc	ra,0x2
    800010ce:	a1a080e7          	jalr	-1510(ra) # 80002ae4 <trapinithart>
    plicinit();      // set up interrupt controller
    800010d2:	00005097          	auipc	ra,0x5
    800010d6:	1e8080e7          	jalr	488(ra) # 800062ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010da:	00005097          	auipc	ra,0x5
    800010de:	1f6080e7          	jalr	502(ra) # 800062d0 <plicinithart>
    binit();         // buffer cache
    800010e2:	00002097          	auipc	ra,0x2
    800010e6:	396080e7          	jalr	918(ra) # 80003478 <binit>
    iinit();         // inode table
    800010ea:	00003097          	auipc	ra,0x3
    800010ee:	a36080e7          	jalr	-1482(ra) # 80003b20 <iinit>
    fileinit();      // file table
    800010f2:	00004097          	auipc	ra,0x4
    800010f6:	9dc080e7          	jalr	-1572(ra) # 80004ace <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010fa:	00005097          	auipc	ra,0x5
    800010fe:	2de080e7          	jalr	734(ra) # 800063d8 <virtio_disk_init>
    userinit();      // first user process
    80001102:	00001097          	auipc	ra,0x1
    80001106:	e46080e7          	jalr	-442(ra) # 80001f48 <userinit>
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
  kpgtbl = (pagetable_t) newkalloc();
    80001306:	00000097          	auipc	ra,0x0
    8000130a:	93c080e7          	jalr	-1732(ra) # 80000c42 <newkalloc>
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
    800013be:	712080e7          	jalr	1810(ra) # 80001acc <proc_mapstacks>
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
    800013f0:	711d                	addi	sp,sp,-96
    800013f2:	ec86                	sd	ra,88(sp)
    800013f4:	e8a2                	sd	s0,80(sp)
    800013f6:	e4a6                	sd	s1,72(sp)
    800013f8:	e0ca                	sd	s2,64(sp)
    800013fa:	fc4e                	sd	s3,56(sp)
    800013fc:	f852                	sd	s4,48(sp)
    800013fe:	f456                	sd	s5,40(sp)
    80001400:	f05a                	sd	s6,32(sp)
    80001402:	ec5e                	sd	s7,24(sp)
    80001404:	e862                	sd	s8,16(sp)
    80001406:	e466                	sd	s9,8(sp)
    80001408:	1080                	addi	s0,sp,96
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000140a:	03459793          	slli	a5,a1,0x34
    8000140e:	e395                	bnez	a5,80001432 <uvmunmap+0x42>
    80001410:	8aaa                	mv	s5,a0
    80001412:	892e                	mv	s2,a1
    80001414:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001416:	0632                	slli	a2,a2,0xc
    80001418:	00b60a33          	add	s4,a2,a1
    8000141c:	0b45f663          	bgeu	a1,s4,800014c8 <uvmunmap+0xd8>
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001420:	4985                	li	s3,1
      panic("uvmunmap: not a leaf");
    if(do_free){
      uint64 pa = PTE2PA(*pte);
    if (counter[((uint64)pa-KERNBASE )/ PGSIZE]==1){
    80001422:	00010c97          	auipc	s9,0x10
    80001426:	8dec8c93          	addi	s9,s9,-1826 # 80010d00 <counter>
    8000142a:	80000c37          	lui	s8,0x80000
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000142e:	6b85                	lui	s7,0x1
    80001430:	a891                	j	80001484 <uvmunmap+0x94>
    panic("uvmunmap: not aligned");
    80001432:	00007517          	auipc	a0,0x7
    80001436:	d0e50513          	addi	a0,a0,-754 # 80008140 <digits+0xf0>
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	106080e7          	jalr	262(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001442:	00007517          	auipc	a0,0x7
    80001446:	d1650513          	addi	a0,a0,-746 # 80008158 <digits+0x108>
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	0f6080e7          	jalr	246(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001452:	00007517          	auipc	a0,0x7
    80001456:	d1650513          	addi	a0,a0,-746 # 80008168 <digits+0x118>
    8000145a:	fffff097          	auipc	ra,0xfffff
    8000145e:	0e6080e7          	jalr	230(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001462:	00007517          	auipc	a0,0x7
    80001466:	d1e50513          	addi	a0,a0,-738 # 80008180 <digits+0x130>
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	0d6080e7          	jalr	214(ra) # 80000540 <panic>
      newkfree((void *)pa);
    80001472:	fffff097          	auipc	ra,0xfffff
    80001476:	79c080e7          	jalr	1948(ra) # 80000c0e <newkfree>
    }else{
      refdec((void *)pa);
    }
    }
    *pte = 0;
    8000147a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000147e:	995e                	add	s2,s2,s7
    80001480:	05497463          	bgeu	s2,s4,800014c8 <uvmunmap+0xd8>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001484:	4601                	li	a2,0
    80001486:	85ca                	mv	a1,s2
    80001488:	8556                	mv	a0,s5
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	cb8080e7          	jalr	-840(ra) # 80001142 <walk>
    80001492:	84aa                	mv	s1,a0
    80001494:	d55d                	beqz	a0,80001442 <uvmunmap+0x52>
    if((*pte & PTE_V) == 0)
    80001496:	611c                	ld	a5,0(a0)
    80001498:	0017f713          	andi	a4,a5,1
    8000149c:	db5d                	beqz	a4,80001452 <uvmunmap+0x62>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000149e:	3ff7f713          	andi	a4,a5,1023
    800014a2:	fd3700e3          	beq	a4,s3,80001462 <uvmunmap+0x72>
    if(do_free){
    800014a6:	fc0b0ae3          	beqz	s6,8000147a <uvmunmap+0x8a>
      uint64 pa = PTE2PA(*pte);
    800014aa:	00a7d513          	srli	a0,a5,0xa
    800014ae:	0532                	slli	a0,a0,0xc
    if (counter[((uint64)pa-KERNBASE )/ PGSIZE]==1){
    800014b0:	018507b3          	add	a5,a0,s8
    800014b4:	83a9                	srli	a5,a5,0xa
    800014b6:	97e6                	add	a5,a5,s9
    800014b8:	439c                	lw	a5,0(a5)
    800014ba:	fb378ce3          	beq	a5,s3,80001472 <uvmunmap+0x82>
      refdec((void *)pa);
    800014be:	fffff097          	auipc	ra,0xfffff
    800014c2:	7ee080e7          	jalr	2030(ra) # 80000cac <refdec>
    800014c6:	bf55                	j	8000147a <uvmunmap+0x8a>
  }
}
    800014c8:	60e6                	ld	ra,88(sp)
    800014ca:	6446                	ld	s0,80(sp)
    800014cc:	64a6                	ld	s1,72(sp)
    800014ce:	6906                	ld	s2,64(sp)
    800014d0:	79e2                	ld	s3,56(sp)
    800014d2:	7a42                	ld	s4,48(sp)
    800014d4:	7aa2                	ld	s5,40(sp)
    800014d6:	7b02                	ld	s6,32(sp)
    800014d8:	6be2                	ld	s7,24(sp)
    800014da:	6c42                	ld	s8,16(sp)
    800014dc:	6ca2                	ld	s9,8(sp)
    800014de:	6125                	addi	sp,sp,96
    800014e0:	8082                	ret

00000000800014e2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014e2:	1101                	addi	sp,sp,-32
    800014e4:	ec06                	sd	ra,24(sp)
    800014e6:	e822                	sd	s0,16(sp)
    800014e8:	e426                	sd	s1,8(sp)
    800014ea:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) newkalloc();
    800014ec:	fffff097          	auipc	ra,0xfffff
    800014f0:	756080e7          	jalr	1878(ra) # 80000c42 <newkalloc>
    800014f4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014f6:	c519                	beqz	a0,80001504 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014f8:	6605                	lui	a2,0x1
    800014fa:	4581                	li	a1,0
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	962080e7          	jalr	-1694(ra) # 80000e5e <memset>
  return pagetable;
}
    80001504:	8526                	mv	a0,s1
    80001506:	60e2                	ld	ra,24(sp)
    80001508:	6442                	ld	s0,16(sp)
    8000150a:	64a2                	ld	s1,8(sp)
    8000150c:	6105                	addi	sp,sp,32
    8000150e:	8082                	ret

0000000080001510 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001510:	7179                	addi	sp,sp,-48
    80001512:	f406                	sd	ra,40(sp)
    80001514:	f022                	sd	s0,32(sp)
    80001516:	ec26                	sd	s1,24(sp)
    80001518:	e84a                	sd	s2,16(sp)
    8000151a:	e44e                	sd	s3,8(sp)
    8000151c:	e052                	sd	s4,0(sp)
    8000151e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001520:	6785                	lui	a5,0x1
    80001522:	04f67863          	bgeu	a2,a5,80001572 <uvmfirst+0x62>
    80001526:	8a2a                	mv	s4,a0
    80001528:	89ae                	mv	s3,a1
    8000152a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = newkalloc();
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	716080e7          	jalr	1814(ra) # 80000c42 <newkalloc>
    80001534:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001536:	6605                	lui	a2,0x1
    80001538:	4581                	li	a1,0
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	924080e7          	jalr	-1756(ra) # 80000e5e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001542:	4779                	li	a4,30
    80001544:	86ca                	mv	a3,s2
    80001546:	6605                	lui	a2,0x1
    80001548:	4581                	li	a1,0
    8000154a:	8552                	mv	a0,s4
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	cde080e7          	jalr	-802(ra) # 8000122a <mappages>
  memmove(mem, src, sz);
    80001554:	8626                	mv	a2,s1
    80001556:	85ce                	mv	a1,s3
    80001558:	854a                	mv	a0,s2
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	960080e7          	jalr	-1696(ra) # 80000eba <memmove>
}
    80001562:	70a2                	ld	ra,40(sp)
    80001564:	7402                	ld	s0,32(sp)
    80001566:	64e2                	ld	s1,24(sp)
    80001568:	6942                	ld	s2,16(sp)
    8000156a:	69a2                	ld	s3,8(sp)
    8000156c:	6a02                	ld	s4,0(sp)
    8000156e:	6145                	addi	sp,sp,48
    80001570:	8082                	ret
    panic("uvmfirst: more than a page");
    80001572:	00007517          	auipc	a0,0x7
    80001576:	c2650513          	addi	a0,a0,-986 # 80008198 <digits+0x148>
    8000157a:	fffff097          	auipc	ra,0xfffff
    8000157e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>

0000000080001582 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001582:	1101                	addi	sp,sp,-32
    80001584:	ec06                	sd	ra,24(sp)
    80001586:	e822                	sd	s0,16(sp)
    80001588:	e426                	sd	s1,8(sp)
    8000158a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000158c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000158e:	00b67d63          	bgeu	a2,a1,800015a8 <uvmdealloc+0x26>
    80001592:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001594:	6785                	lui	a5,0x1
    80001596:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001598:	00f60733          	add	a4,a2,a5
    8000159c:	76fd                	lui	a3,0xfffff
    8000159e:	8f75                	and	a4,a4,a3
    800015a0:	97ae                	add	a5,a5,a1
    800015a2:	8ff5                	and	a5,a5,a3
    800015a4:	00f76863          	bltu	a4,a5,800015b4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015a8:	8526                	mv	a0,s1
    800015aa:	60e2                	ld	ra,24(sp)
    800015ac:	6442                	ld	s0,16(sp)
    800015ae:	64a2                	ld	s1,8(sp)
    800015b0:	6105                	addi	sp,sp,32
    800015b2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015b4:	8f99                	sub	a5,a5,a4
    800015b6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015b8:	4685                	li	a3,1
    800015ba:	0007861b          	sext.w	a2,a5
    800015be:	85ba                	mv	a1,a4
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	e30080e7          	jalr	-464(ra) # 800013f0 <uvmunmap>
    800015c8:	b7c5                	j	800015a8 <uvmdealloc+0x26>

00000000800015ca <uvmalloc>:
  if(newsz < oldsz)
    800015ca:	0ab66563          	bltu	a2,a1,80001674 <uvmalloc+0xaa>
{
    800015ce:	7139                	addi	sp,sp,-64
    800015d0:	fc06                	sd	ra,56(sp)
    800015d2:	f822                	sd	s0,48(sp)
    800015d4:	f426                	sd	s1,40(sp)
    800015d6:	f04a                	sd	s2,32(sp)
    800015d8:	ec4e                	sd	s3,24(sp)
    800015da:	e852                	sd	s4,16(sp)
    800015dc:	e456                	sd	s5,8(sp)
    800015de:	e05a                	sd	s6,0(sp)
    800015e0:	0080                	addi	s0,sp,64
    800015e2:	8aaa                	mv	s5,a0
    800015e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015e6:	6785                	lui	a5,0x1
    800015e8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015ea:	95be                	add	a1,a1,a5
    800015ec:	77fd                	lui	a5,0xfffff
    800015ee:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015f2:	08c9f363          	bgeu	s3,a2,80001678 <uvmalloc+0xae>
    800015f6:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015f8:	0126eb13          	ori	s6,a3,18
    mem = newkalloc();
    800015fc:	fffff097          	auipc	ra,0xfffff
    80001600:	646080e7          	jalr	1606(ra) # 80000c42 <newkalloc>
    80001604:	84aa                	mv	s1,a0
    if(mem == 0){
    80001606:	c51d                	beqz	a0,80001634 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001608:	6605                	lui	a2,0x1
    8000160a:	4581                	li	a1,0
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	852080e7          	jalr	-1966(ra) # 80000e5e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001614:	875a                	mv	a4,s6
    80001616:	86a6                	mv	a3,s1
    80001618:	6605                	lui	a2,0x1
    8000161a:	85ca                	mv	a1,s2
    8000161c:	8556                	mv	a0,s5
    8000161e:	00000097          	auipc	ra,0x0
    80001622:	c0c080e7          	jalr	-1012(ra) # 8000122a <mappages>
    80001626:	e90d                	bnez	a0,80001658 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001628:	6785                	lui	a5,0x1
    8000162a:	993e                	add	s2,s2,a5
    8000162c:	fd4968e3          	bltu	s2,s4,800015fc <uvmalloc+0x32>
  return newsz;
    80001630:	8552                	mv	a0,s4
    80001632:	a809                	j	80001644 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001634:	864e                	mv	a2,s3
    80001636:	85ca                	mv	a1,s2
    80001638:	8556                	mv	a0,s5
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	f48080e7          	jalr	-184(ra) # 80001582 <uvmdealloc>
      return 0;
    80001642:	4501                	li	a0,0
}
    80001644:	70e2                	ld	ra,56(sp)
    80001646:	7442                	ld	s0,48(sp)
    80001648:	74a2                	ld	s1,40(sp)
    8000164a:	7902                	ld	s2,32(sp)
    8000164c:	69e2                	ld	s3,24(sp)
    8000164e:	6a42                	ld	s4,16(sp)
    80001650:	6aa2                	ld	s5,8(sp)
    80001652:	6b02                	ld	s6,0(sp)
    80001654:	6121                	addi	sp,sp,64
    80001656:	8082                	ret
      newkfree(mem);
    80001658:	8526                	mv	a0,s1
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	5b4080e7          	jalr	1460(ra) # 80000c0e <newkfree>
      uvmdealloc(pagetable, a, oldsz);
    80001662:	864e                	mv	a2,s3
    80001664:	85ca                	mv	a1,s2
    80001666:	8556                	mv	a0,s5
    80001668:	00000097          	auipc	ra,0x0
    8000166c:	f1a080e7          	jalr	-230(ra) # 80001582 <uvmdealloc>
      return 0;
    80001670:	4501                	li	a0,0
    80001672:	bfc9                	j	80001644 <uvmalloc+0x7a>
    return oldsz;
    80001674:	852e                	mv	a0,a1
}
    80001676:	8082                	ret
  return newsz;
    80001678:	8532                	mv	a0,a2
    8000167a:	b7e9                	j	80001644 <uvmalloc+0x7a>

000000008000167c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000167c:	7179                	addi	sp,sp,-48
    8000167e:	f406                	sd	ra,40(sp)
    80001680:	f022                	sd	s0,32(sp)
    80001682:	ec26                	sd	s1,24(sp)
    80001684:	e84a                	sd	s2,16(sp)
    80001686:	e44e                	sd	s3,8(sp)
    80001688:	e052                	sd	s4,0(sp)
    8000168a:	1800                	addi	s0,sp,48
    8000168c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000168e:	84aa                	mv	s1,a0
    80001690:	6905                	lui	s2,0x1
    80001692:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001694:	4985                	li	s3,1
    80001696:	a829                	j	800016b0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001698:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000169a:	00c79513          	slli	a0,a5,0xc
    8000169e:	00000097          	auipc	ra,0x0
    800016a2:	fde080e7          	jalr	-34(ra) # 8000167c <freewalk>
      pagetable[i] = 0;
    800016a6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016aa:	04a1                	addi	s1,s1,8
    800016ac:	03248163          	beq	s1,s2,800016ce <freewalk+0x52>
    pte_t pte = pagetable[i];
    800016b0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016b2:	00f7f713          	andi	a4,a5,15
    800016b6:	ff3701e3          	beq	a4,s3,80001698 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016ba:	8b85                	andi	a5,a5,1
    800016bc:	d7fd                	beqz	a5,800016aa <freewalk+0x2e>
      panic("freewalk: leaf");
    800016be:	00007517          	auipc	a0,0x7
    800016c2:	afa50513          	addi	a0,a0,-1286 # 800081b8 <digits+0x168>
    800016c6:	fffff097          	auipc	ra,0xfffff
    800016ca:	e7a080e7          	jalr	-390(ra) # 80000540 <panic>
    }
  }
  newkfree((void *)pagetable);
    800016ce:	8552                	mv	a0,s4
    800016d0:	fffff097          	auipc	ra,0xfffff
    800016d4:	53e080e7          	jalr	1342(ra) # 80000c0e <newkfree>
}
    800016d8:	70a2                	ld	ra,40(sp)
    800016da:	7402                	ld	s0,32(sp)
    800016dc:	64e2                	ld	s1,24(sp)
    800016de:	6942                	ld	s2,16(sp)
    800016e0:	69a2                	ld	s3,8(sp)
    800016e2:	6a02                	ld	s4,0(sp)
    800016e4:	6145                	addi	sp,sp,48
    800016e6:	8082                	ret

00000000800016e8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016e8:	1101                	addi	sp,sp,-32
    800016ea:	ec06                	sd	ra,24(sp)
    800016ec:	e822                	sd	s0,16(sp)
    800016ee:	e426                	sd	s1,8(sp)
    800016f0:	1000                	addi	s0,sp,32
    800016f2:	84aa                	mv	s1,a0
  if(sz > 0)
    800016f4:	e999                	bnez	a1,8000170a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016f6:	8526                	mv	a0,s1
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	f84080e7          	jalr	-124(ra) # 8000167c <freewalk>
}
    80001700:	60e2                	ld	ra,24(sp)
    80001702:	6442                	ld	s0,16(sp)
    80001704:	64a2                	ld	s1,8(sp)
    80001706:	6105                	addi	sp,sp,32
    80001708:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000170a:	6785                	lui	a5,0x1
    8000170c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000170e:	95be                	add	a1,a1,a5
    80001710:	4685                	li	a3,1
    80001712:	00c5d613          	srli	a2,a1,0xc
    80001716:	4581                	li	a1,0
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	cd8080e7          	jalr	-808(ra) # 800013f0 <uvmunmap>
    80001720:	bfd9                	j	800016f6 <uvmfree+0xe>

0000000080001722 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001722:	715d                	addi	sp,sp,-80
    80001724:	e486                	sd	ra,72(sp)
    80001726:	e0a2                	sd	s0,64(sp)
    80001728:	fc26                	sd	s1,56(sp)
    8000172a:	f84a                	sd	s2,48(sp)
    8000172c:	f44e                	sd	s3,40(sp)
    8000172e:	f052                	sd	s4,32(sp)
    80001730:	ec56                	sd	s5,24(sp)
    80001732:	e85a                	sd	s6,16(sp)
    80001734:	e45e                	sd	s7,8(sp)
    80001736:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80001738:	c271                	beqz	a2,800017fc <uvmcopy+0xda>
    8000173a:	8aaa                	mv	s5,a0
    8000173c:	8bae                	mv	s7,a1
    8000173e:	8b32                	mv	s6,a2
    80001740:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    80001742:	4601                	li	a2,0
    80001744:	85ca                	mv	a1,s2
    80001746:	8556                	mv	a0,s5
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	9fa080e7          	jalr	-1542(ra) # 80001142 <walk>
    80001750:	c125                	beqz	a0,800017b0 <uvmcopy+0x8e>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001752:	6118                	ld	a4,0(a0)
    80001754:	00177793          	andi	a5,a4,1
    80001758:	c7a5                	beqz	a5,800017c0 <uvmcopy+0x9e>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000175a:	00a75993          	srli	s3,a4,0xa
    8000175e:	09b2                	slli	s3,s3,0xc
    flags = PTE_FLAGS(*pte);
    flags &= ~PTE_W; 

    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001760:	3fb77493          	andi	s1,a4,1019
    80001764:	8726                	mv	a4,s1
    80001766:	86ce                	mv	a3,s3
    80001768:	6605                	lui	a2,0x1
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855e                	mv	a0,s7
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	abc080e7          	jalr	-1348(ra) # 8000122a <mappages>
    80001776:	8a2a                	mv	s4,a0
    80001778:	ed21                	bnez	a0,800017d0 <uvmcopy+0xae>
      goto err;
    }
    refinc((void *)pa);
    8000177a:	854e                	mv	a0,s3
    8000177c:	fffff097          	auipc	ra,0xfffff
    80001780:	50a080e7          	jalr	1290(ra) # 80000c86 <refinc>
    uvmunmap(old,i,1,0);
    80001784:	4681                	li	a3,0
    80001786:	4605                	li	a2,1
    80001788:	85ca                	mv	a1,s2
    8000178a:	8556                	mv	a0,s5
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	c64080e7          	jalr	-924(ra) # 800013f0 <uvmunmap>
    mappages(old,i,PGSIZE,pa,flags);
    80001794:	8726                	mv	a4,s1
    80001796:	86ce                	mv	a3,s3
    80001798:	6605                	lui	a2,0x1
    8000179a:	85ca                	mv	a1,s2
    8000179c:	8556                	mv	a0,s5
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	a8c080e7          	jalr	-1396(ra) # 8000122a <mappages>
  for(i = 0; i < sz; i += PGSIZE){
    800017a6:	6785                	lui	a5,0x1
    800017a8:	993e                	add	s2,s2,a5
    800017aa:	f9696ce3          	bltu	s2,s6,80001742 <uvmcopy+0x20>
    800017ae:	a81d                	j	800017e4 <uvmcopy+0xc2>
      panic("uvmcopy: pte should exist");
    800017b0:	00007517          	auipc	a0,0x7
    800017b4:	a1850513          	addi	a0,a0,-1512 # 800081c8 <digits+0x178>
    800017b8:	fffff097          	auipc	ra,0xfffff
    800017bc:	d88080e7          	jalr	-632(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800017c0:	00007517          	auipc	a0,0x7
    800017c4:	a2850513          	addi	a0,a0,-1496 # 800081e8 <digits+0x198>
    800017c8:	fffff097          	auipc	ra,0xfffff
    800017cc:	d78080e7          	jalr	-648(ra) # 80000540 <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017d0:	4685                	li	a3,1
    800017d2:	00c95613          	srli	a2,s2,0xc
    800017d6:	4581                	li	a1,0
    800017d8:	855e                	mv	a0,s7
    800017da:	00000097          	auipc	ra,0x0
    800017de:	c16080e7          	jalr	-1002(ra) # 800013f0 <uvmunmap>
  return -1;
    800017e2:	5a7d                	li	s4,-1
}
    800017e4:	8552                	mv	a0,s4
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6161                	addi	sp,sp,80
    800017fa:	8082                	ret
  return 0;
    800017fc:	4a01                	li	s4,0
    800017fe:	b7dd                	j	800017e4 <uvmcopy+0xc2>

0000000080001800 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001800:	1141                	addi	sp,sp,-16
    80001802:	e406                	sd	ra,8(sp)
    80001804:	e022                	sd	s0,0(sp)
    80001806:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001808:	4601                	li	a2,0
    8000180a:	00000097          	auipc	ra,0x0
    8000180e:	938080e7          	jalr	-1736(ra) # 80001142 <walk>
  if(pte == 0)
    80001812:	c901                	beqz	a0,80001822 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001814:	611c                	ld	a5,0(a0)
    80001816:	9bbd                	andi	a5,a5,-17
    80001818:	e11c                	sd	a5,0(a0)
}
    8000181a:	60a2                	ld	ra,8(sp)
    8000181c:	6402                	ld	s0,0(sp)
    8000181e:	0141                	addi	sp,sp,16
    80001820:	8082                	ret
    panic("uvmclear");
    80001822:	00007517          	auipc	a0,0x7
    80001826:	9e650513          	addi	a0,a0,-1562 # 80008208 <digits+0x1b8>
    8000182a:	fffff097          	auipc	ra,0xfffff
    8000182e:	d16080e7          	jalr	-746(ra) # 80000540 <panic>

0000000080001832 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001832:	c6bd                	beqz	a3,800018a0 <copyout+0x6e>
{
    80001834:	715d                	addi	sp,sp,-80
    80001836:	e486                	sd	ra,72(sp)
    80001838:	e0a2                	sd	s0,64(sp)
    8000183a:	fc26                	sd	s1,56(sp)
    8000183c:	f84a                	sd	s2,48(sp)
    8000183e:	f44e                	sd	s3,40(sp)
    80001840:	f052                	sd	s4,32(sp)
    80001842:	ec56                	sd	s5,24(sp)
    80001844:	e85a                	sd	s6,16(sp)
    80001846:	e45e                	sd	s7,8(sp)
    80001848:	e062                	sd	s8,0(sp)
    8000184a:	0880                	addi	s0,sp,80
    8000184c:	8b2a                	mv	s6,a0
    8000184e:	8c2e                	mv	s8,a1
    80001850:	8a32                	mv	s4,a2
    80001852:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001854:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001856:	6a85                	lui	s5,0x1
    80001858:	a015                	j	8000187c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000185a:	9562                	add	a0,a0,s8
    8000185c:	0004861b          	sext.w	a2,s1
    80001860:	85d2                	mv	a1,s4
    80001862:	41250533          	sub	a0,a0,s2
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	654080e7          	jalr	1620(ra) # 80000eba <memmove>

    len -= n;
    8000186e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001872:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001874:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001878:	02098263          	beqz	s3,8000189c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000187c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001880:	85ca                	mv	a1,s2
    80001882:	855a                	mv	a0,s6
    80001884:	00000097          	auipc	ra,0x0
    80001888:	964080e7          	jalr	-1692(ra) # 800011e8 <walkaddr>
    if(pa0 == 0)
    8000188c:	cd01                	beqz	a0,800018a4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000188e:	418904b3          	sub	s1,s2,s8
    80001892:	94d6                	add	s1,s1,s5
    80001894:	fc99f3e3          	bgeu	s3,s1,8000185a <copyout+0x28>
    80001898:	84ce                	mv	s1,s3
    8000189a:	b7c1                	j	8000185a <copyout+0x28>
  }
  return 0;
    8000189c:	4501                	li	a0,0
    8000189e:	a021                	j	800018a6 <copyout+0x74>
    800018a0:	4501                	li	a0,0
}
    800018a2:	8082                	ret
      return -1;
    800018a4:	557d                	li	a0,-1
}
    800018a6:	60a6                	ld	ra,72(sp)
    800018a8:	6406                	ld	s0,64(sp)
    800018aa:	74e2                	ld	s1,56(sp)
    800018ac:	7942                	ld	s2,48(sp)
    800018ae:	79a2                	ld	s3,40(sp)
    800018b0:	7a02                	ld	s4,32(sp)
    800018b2:	6ae2                	ld	s5,24(sp)
    800018b4:	6b42                	ld	s6,16(sp)
    800018b6:	6ba2                	ld	s7,8(sp)
    800018b8:	6c02                	ld	s8,0(sp)
    800018ba:	6161                	addi	sp,sp,80
    800018bc:	8082                	ret

00000000800018be <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018be:	caa5                	beqz	a3,8000192e <copyin+0x70>
{
    800018c0:	715d                	addi	sp,sp,-80
    800018c2:	e486                	sd	ra,72(sp)
    800018c4:	e0a2                	sd	s0,64(sp)
    800018c6:	fc26                	sd	s1,56(sp)
    800018c8:	f84a                	sd	s2,48(sp)
    800018ca:	f44e                	sd	s3,40(sp)
    800018cc:	f052                	sd	s4,32(sp)
    800018ce:	ec56                	sd	s5,24(sp)
    800018d0:	e85a                	sd	s6,16(sp)
    800018d2:	e45e                	sd	s7,8(sp)
    800018d4:	e062                	sd	s8,0(sp)
    800018d6:	0880                	addi	s0,sp,80
    800018d8:	8b2a                	mv	s6,a0
    800018da:	8a2e                	mv	s4,a1
    800018dc:	8c32                	mv	s8,a2
    800018de:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018e0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018e2:	6a85                	lui	s5,0x1
    800018e4:	a01d                	j	8000190a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018e6:	018505b3          	add	a1,a0,s8
    800018ea:	0004861b          	sext.w	a2,s1
    800018ee:	412585b3          	sub	a1,a1,s2
    800018f2:	8552                	mv	a0,s4
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	5c6080e7          	jalr	1478(ra) # 80000eba <memmove>

    len -= n;
    800018fc:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001900:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001902:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001906:	02098263          	beqz	s3,8000192a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000190a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000190e:	85ca                	mv	a1,s2
    80001910:	855a                	mv	a0,s6
    80001912:	00000097          	auipc	ra,0x0
    80001916:	8d6080e7          	jalr	-1834(ra) # 800011e8 <walkaddr>
    if(pa0 == 0)
    8000191a:	cd01                	beqz	a0,80001932 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000191c:	418904b3          	sub	s1,s2,s8
    80001920:	94d6                	add	s1,s1,s5
    80001922:	fc99f2e3          	bgeu	s3,s1,800018e6 <copyin+0x28>
    80001926:	84ce                	mv	s1,s3
    80001928:	bf7d                	j	800018e6 <copyin+0x28>
  }
  return 0;
    8000192a:	4501                	li	a0,0
    8000192c:	a021                	j	80001934 <copyin+0x76>
    8000192e:	4501                	li	a0,0
}
    80001930:	8082                	ret
      return -1;
    80001932:	557d                	li	a0,-1
}
    80001934:	60a6                	ld	ra,72(sp)
    80001936:	6406                	ld	s0,64(sp)
    80001938:	74e2                	ld	s1,56(sp)
    8000193a:	7942                	ld	s2,48(sp)
    8000193c:	79a2                	ld	s3,40(sp)
    8000193e:	7a02                	ld	s4,32(sp)
    80001940:	6ae2                	ld	s5,24(sp)
    80001942:	6b42                	ld	s6,16(sp)
    80001944:	6ba2                	ld	s7,8(sp)
    80001946:	6c02                	ld	s8,0(sp)
    80001948:	6161                	addi	sp,sp,80
    8000194a:	8082                	ret

000000008000194c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000194c:	c2dd                	beqz	a3,800019f2 <copyinstr+0xa6>
{
    8000194e:	715d                	addi	sp,sp,-80
    80001950:	e486                	sd	ra,72(sp)
    80001952:	e0a2                	sd	s0,64(sp)
    80001954:	fc26                	sd	s1,56(sp)
    80001956:	f84a                	sd	s2,48(sp)
    80001958:	f44e                	sd	s3,40(sp)
    8000195a:	f052                	sd	s4,32(sp)
    8000195c:	ec56                	sd	s5,24(sp)
    8000195e:	e85a                	sd	s6,16(sp)
    80001960:	e45e                	sd	s7,8(sp)
    80001962:	0880                	addi	s0,sp,80
    80001964:	8a2a                	mv	s4,a0
    80001966:	8b2e                	mv	s6,a1
    80001968:	8bb2                	mv	s7,a2
    8000196a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000196c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000196e:	6985                	lui	s3,0x1
    80001970:	a02d                	j	8000199a <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001972:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001976:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001978:	37fd                	addiw	a5,a5,-1
    8000197a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000197e:	60a6                	ld	ra,72(sp)
    80001980:	6406                	ld	s0,64(sp)
    80001982:	74e2                	ld	s1,56(sp)
    80001984:	7942                	ld	s2,48(sp)
    80001986:	79a2                	ld	s3,40(sp)
    80001988:	7a02                	ld	s4,32(sp)
    8000198a:	6ae2                	ld	s5,24(sp)
    8000198c:	6b42                	ld	s6,16(sp)
    8000198e:	6ba2                	ld	s7,8(sp)
    80001990:	6161                	addi	sp,sp,80
    80001992:	8082                	ret
    srcva = va0 + PGSIZE;
    80001994:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001998:	c8a9                	beqz	s1,800019ea <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000199a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000199e:	85ca                	mv	a1,s2
    800019a0:	8552                	mv	a0,s4
    800019a2:	00000097          	auipc	ra,0x0
    800019a6:	846080e7          	jalr	-1978(ra) # 800011e8 <walkaddr>
    if(pa0 == 0)
    800019aa:	c131                	beqz	a0,800019ee <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800019ac:	417906b3          	sub	a3,s2,s7
    800019b0:	96ce                	add	a3,a3,s3
    800019b2:	00d4f363          	bgeu	s1,a3,800019b8 <copyinstr+0x6c>
    800019b6:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019b8:	955e                	add	a0,a0,s7
    800019ba:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019be:	daf9                	beqz	a3,80001994 <copyinstr+0x48>
    800019c0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019c2:	41650633          	sub	a2,a0,s6
    800019c6:	fff48593          	addi	a1,s1,-1
    800019ca:	95da                	add	a1,a1,s6
    while(n > 0){
    800019cc:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800019ce:	00f60733          	add	a4,a2,a5
    800019d2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbd0f0>
    800019d6:	df51                	beqz	a4,80001972 <copyinstr+0x26>
        *dst = *p;
    800019d8:	00e78023          	sb	a4,0(a5)
      --max;
    800019dc:	40f584b3          	sub	s1,a1,a5
      dst++;
    800019e0:	0785                	addi	a5,a5,1
    while(n > 0){
    800019e2:	fed796e3          	bne	a5,a3,800019ce <copyinstr+0x82>
      dst++;
    800019e6:	8b3e                	mv	s6,a5
    800019e8:	b775                	j	80001994 <copyinstr+0x48>
    800019ea:	4781                	li	a5,0
    800019ec:	b771                	j	80001978 <copyinstr+0x2c>
      return -1;
    800019ee:	557d                	li	a0,-1
    800019f0:	b779                	j	8000197e <copyinstr+0x32>
  int got_null = 0;
    800019f2:	4781                	li	a5,0
  if(got_null){
    800019f4:	37fd                	addiw	a5,a5,-1
    800019f6:	0007851b          	sext.w	a0,a5
}
    800019fa:	8082                	ret

00000000800019fc <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    800019fc:	715d                	addi	sp,sp,-80
    800019fe:	e486                	sd	ra,72(sp)
    80001a00:	e0a2                	sd	s0,64(sp)
    80001a02:	fc26                	sd	s1,56(sp)
    80001a04:	f84a                	sd	s2,48(sp)
    80001a06:	f44e                	sd	s3,40(sp)
    80001a08:	f052                	sd	s4,32(sp)
    80001a0a:	ec56                	sd	s5,24(sp)
    80001a0c:	e85a                	sd	s6,16(sp)
    80001a0e:	e45e                	sd	s7,8(sp)
    80001a10:	e062                	sd	s8,0(sp)
    80001a12:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a14:	8792                	mv	a5,tp
    int id = r_tp();
    80001a16:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001a18:	0002fa97          	auipc	s5,0x2f
    80001a1c:	2e8a8a93          	addi	s5,s5,744 # 80030d00 <cpus>
    80001a20:	00779713          	slli	a4,a5,0x7
    80001a24:	00ea86b3          	add	a3,s5,a4
    80001a28:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffbd0f0>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001a2c:	0721                	addi	a4,a4,8
    80001a2e:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001a30:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001a32:	00007c17          	auipc	s8,0x7
    80001a36:	f86c0c13          	addi	s8,s8,-122 # 800089b8 <sched_pointer>
    80001a3a:	00000b97          	auipc	s7,0x0
    80001a3e:	fc2b8b93          	addi	s7,s7,-62 # 800019fc <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001a42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001a46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001a4a:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001a4e:	0002f497          	auipc	s1,0x2f
    80001a52:	6e248493          	addi	s1,s1,1762 # 80031130 <proc>
            if (p->state == RUNNABLE)
    80001a56:	498d                	li	s3,3
                p->state = RUNNING;
    80001a58:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001a5a:	00035a17          	auipc	s4,0x35
    80001a5e:	0d6a0a13          	addi	s4,s4,214 # 80036b30 <tickslock>
    80001a62:	a81d                	j	80001a98 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001a64:	8526                	mv	a0,s1
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	3b0080e7          	jalr	944(ra) # 80000e16 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001a6e:	60a6                	ld	ra,72(sp)
    80001a70:	6406                	ld	s0,64(sp)
    80001a72:	74e2                	ld	s1,56(sp)
    80001a74:	7942                	ld	s2,48(sp)
    80001a76:	79a2                	ld	s3,40(sp)
    80001a78:	7a02                	ld	s4,32(sp)
    80001a7a:	6ae2                	ld	s5,24(sp)
    80001a7c:	6b42                	ld	s6,16(sp)
    80001a7e:	6ba2                	ld	s7,8(sp)
    80001a80:	6c02                	ld	s8,0(sp)
    80001a82:	6161                	addi	sp,sp,80
    80001a84:	8082                	ret
            release(&p->lock);
    80001a86:	8526                	mv	a0,s1
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	38e080e7          	jalr	910(ra) # 80000e16 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001a90:	16848493          	addi	s1,s1,360
    80001a94:	fb4487e3          	beq	s1,s4,80001a42 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001a98:	8526                	mv	a0,s1
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	2c8080e7          	jalr	712(ra) # 80000d62 <acquire>
            if (p->state == RUNNABLE)
    80001aa2:	4c9c                	lw	a5,24(s1)
    80001aa4:	ff3791e3          	bne	a5,s3,80001a86 <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001aa8:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001aac:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001ab0:	06048593          	addi	a1,s1,96
    80001ab4:	8556                	mv	a0,s5
    80001ab6:	00001097          	auipc	ra,0x1
    80001aba:	f9c080e7          	jalr	-100(ra) # 80002a52 <swtch>
                if (sched_pointer != &rr_scheduler)
    80001abe:	000c3783          	ld	a5,0(s8)
    80001ac2:	fb7791e3          	bne	a5,s7,80001a64 <rr_scheduler+0x68>
                c->proc = 0;
    80001ac6:	00093023          	sd	zero,0(s2)
    80001aca:	bf75                	j	80001a86 <rr_scheduler+0x8a>

0000000080001acc <proc_mapstacks>:
{
    80001acc:	7139                	addi	sp,sp,-64
    80001ace:	fc06                	sd	ra,56(sp)
    80001ad0:	f822                	sd	s0,48(sp)
    80001ad2:	f426                	sd	s1,40(sp)
    80001ad4:	f04a                	sd	s2,32(sp)
    80001ad6:	ec4e                	sd	s3,24(sp)
    80001ad8:	e852                	sd	s4,16(sp)
    80001ada:	e456                	sd	s5,8(sp)
    80001adc:	e05a                	sd	s6,0(sp)
    80001ade:	0080                	addi	s0,sp,64
    80001ae0:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001ae2:	0002f497          	auipc	s1,0x2f
    80001ae6:	64e48493          	addi	s1,s1,1614 # 80031130 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001aea:	8b26                	mv	s6,s1
    80001aec:	00006a97          	auipc	s5,0x6
    80001af0:	524a8a93          	addi	s5,s5,1316 # 80008010 <__func__.1+0x8>
    80001af4:	04000937          	lui	s2,0x4000
    80001af8:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001afa:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001afc:	00035a17          	auipc	s4,0x35
    80001b00:	034a0a13          	addi	s4,s4,52 # 80036b30 <tickslock>
        char *pa = newkalloc();
    80001b04:	fffff097          	auipc	ra,0xfffff
    80001b08:	13e080e7          	jalr	318(ra) # 80000c42 <newkalloc>
    80001b0c:	862a                	mv	a2,a0
        if (pa == 0)
    80001b0e:	c131                	beqz	a0,80001b52 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001b10:	416485b3          	sub	a1,s1,s6
    80001b14:	858d                	srai	a1,a1,0x3
    80001b16:	000ab783          	ld	a5,0(s5)
    80001b1a:	02f585b3          	mul	a1,a1,a5
    80001b1e:	2585                	addiw	a1,a1,1
    80001b20:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b24:	4719                	li	a4,6
    80001b26:	6685                	lui	a3,0x1
    80001b28:	40b905b3          	sub	a1,s2,a1
    80001b2c:	854e                	mv	a0,s3
    80001b2e:	fffff097          	auipc	ra,0xfffff
    80001b32:	79c080e7          	jalr	1948(ra) # 800012ca <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b36:	16848493          	addi	s1,s1,360
    80001b3a:	fd4495e3          	bne	s1,s4,80001b04 <proc_mapstacks+0x38>
}
    80001b3e:	70e2                	ld	ra,56(sp)
    80001b40:	7442                	ld	s0,48(sp)
    80001b42:	74a2                	ld	s1,40(sp)
    80001b44:	7902                	ld	s2,32(sp)
    80001b46:	69e2                	ld	s3,24(sp)
    80001b48:	6a42                	ld	s4,16(sp)
    80001b4a:	6aa2                	ld	s5,8(sp)
    80001b4c:	6b02                	ld	s6,0(sp)
    80001b4e:	6121                	addi	sp,sp,64
    80001b50:	8082                	ret
            panic("kalloc");
    80001b52:	00006517          	auipc	a0,0x6
    80001b56:	6c650513          	addi	a0,a0,1734 # 80008218 <digits+0x1c8>
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	9e6080e7          	jalr	-1562(ra) # 80000540 <panic>

0000000080001b62 <procinit>:
{
    80001b62:	7139                	addi	sp,sp,-64
    80001b64:	fc06                	sd	ra,56(sp)
    80001b66:	f822                	sd	s0,48(sp)
    80001b68:	f426                	sd	s1,40(sp)
    80001b6a:	f04a                	sd	s2,32(sp)
    80001b6c:	ec4e                	sd	s3,24(sp)
    80001b6e:	e852                	sd	s4,16(sp)
    80001b70:	e456                	sd	s5,8(sp)
    80001b72:	e05a                	sd	s6,0(sp)
    80001b74:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001b76:	00006597          	auipc	a1,0x6
    80001b7a:	6aa58593          	addi	a1,a1,1706 # 80008220 <digits+0x1d0>
    80001b7e:	0002f517          	auipc	a0,0x2f
    80001b82:	58250513          	addi	a0,a0,1410 # 80031100 <pid_lock>
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	14c080e7          	jalr	332(ra) # 80000cd2 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001b8e:	00006597          	auipc	a1,0x6
    80001b92:	69a58593          	addi	a1,a1,1690 # 80008228 <digits+0x1d8>
    80001b96:	0002f517          	auipc	a0,0x2f
    80001b9a:	58250513          	addi	a0,a0,1410 # 80031118 <wait_lock>
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	134080e7          	jalr	308(ra) # 80000cd2 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001ba6:	0002f497          	auipc	s1,0x2f
    80001baa:	58a48493          	addi	s1,s1,1418 # 80031130 <proc>
        initlock(&p->lock, "proc");
    80001bae:	00006b17          	auipc	s6,0x6
    80001bb2:	68ab0b13          	addi	s6,s6,1674 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001bb6:	8aa6                	mv	s5,s1
    80001bb8:	00006a17          	auipc	s4,0x6
    80001bbc:	458a0a13          	addi	s4,s4,1112 # 80008010 <__func__.1+0x8>
    80001bc0:	04000937          	lui	s2,0x4000
    80001bc4:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001bc6:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001bc8:	00035997          	auipc	s3,0x35
    80001bcc:	f6898993          	addi	s3,s3,-152 # 80036b30 <tickslock>
        initlock(&p->lock, "proc");
    80001bd0:	85da                	mv	a1,s6
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	0fe080e7          	jalr	254(ra) # 80000cd2 <initlock>
        p->state = UNUSED;
    80001bdc:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001be0:	415487b3          	sub	a5,s1,s5
    80001be4:	878d                	srai	a5,a5,0x3
    80001be6:	000a3703          	ld	a4,0(s4)
    80001bea:	02e787b3          	mul	a5,a5,a4
    80001bee:	2785                	addiw	a5,a5,1
    80001bf0:	00d7979b          	slliw	a5,a5,0xd
    80001bf4:	40f907b3          	sub	a5,s2,a5
    80001bf8:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001bfa:	16848493          	addi	s1,s1,360
    80001bfe:	fd3499e3          	bne	s1,s3,80001bd0 <procinit+0x6e>
}
    80001c02:	70e2                	ld	ra,56(sp)
    80001c04:	7442                	ld	s0,48(sp)
    80001c06:	74a2                	ld	s1,40(sp)
    80001c08:	7902                	ld	s2,32(sp)
    80001c0a:	69e2                	ld	s3,24(sp)
    80001c0c:	6a42                	ld	s4,16(sp)
    80001c0e:	6aa2                	ld	s5,8(sp)
    80001c10:	6b02                	ld	s6,0(sp)
    80001c12:	6121                	addi	sp,sp,64
    80001c14:	8082                	ret

0000000080001c16 <copy_array>:
{
    80001c16:	1141                	addi	sp,sp,-16
    80001c18:	e422                	sd	s0,8(sp)
    80001c1a:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001c1c:	02c05163          	blez	a2,80001c3e <copy_array+0x28>
    80001c20:	87aa                	mv	a5,a0
    80001c22:	0505                	addi	a0,a0,1
    80001c24:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001c26:	1602                	slli	a2,a2,0x20
    80001c28:	9201                	srli	a2,a2,0x20
    80001c2a:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001c2e:	0007c703          	lbu	a4,0(a5)
    80001c32:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001c36:	0785                	addi	a5,a5,1
    80001c38:	0585                	addi	a1,a1,1
    80001c3a:	fed79ae3          	bne	a5,a3,80001c2e <copy_array+0x18>
}
    80001c3e:	6422                	ld	s0,8(sp)
    80001c40:	0141                	addi	sp,sp,16
    80001c42:	8082                	ret

0000000080001c44 <cpuid>:
{
    80001c44:	1141                	addi	sp,sp,-16
    80001c46:	e422                	sd	s0,8(sp)
    80001c48:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c4a:	8512                	mv	a0,tp
}
    80001c4c:	2501                	sext.w	a0,a0
    80001c4e:	6422                	ld	s0,8(sp)
    80001c50:	0141                	addi	sp,sp,16
    80001c52:	8082                	ret

0000000080001c54 <mycpu>:
{
    80001c54:	1141                	addi	sp,sp,-16
    80001c56:	e422                	sd	s0,8(sp)
    80001c58:	0800                	addi	s0,sp,16
    80001c5a:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001c5c:	2781                	sext.w	a5,a5
    80001c5e:	079e                	slli	a5,a5,0x7
}
    80001c60:	0002f517          	auipc	a0,0x2f
    80001c64:	0a050513          	addi	a0,a0,160 # 80030d00 <cpus>
    80001c68:	953e                	add	a0,a0,a5
    80001c6a:	6422                	ld	s0,8(sp)
    80001c6c:	0141                	addi	sp,sp,16
    80001c6e:	8082                	ret

0000000080001c70 <myproc>:
{
    80001c70:	1101                	addi	sp,sp,-32
    80001c72:	ec06                	sd	ra,24(sp)
    80001c74:	e822                	sd	s0,16(sp)
    80001c76:	e426                	sd	s1,8(sp)
    80001c78:	1000                	addi	s0,sp,32
    push_off();
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	09c080e7          	jalr	156(ra) # 80000d16 <push_off>
    80001c82:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001c84:	2781                	sext.w	a5,a5
    80001c86:	079e                	slli	a5,a5,0x7
    80001c88:	0002f717          	auipc	a4,0x2f
    80001c8c:	07870713          	addi	a4,a4,120 # 80030d00 <cpus>
    80001c90:	97ba                	add	a5,a5,a4
    80001c92:	6384                	ld	s1,0(a5)
    pop_off();
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	122080e7          	jalr	290(ra) # 80000db6 <pop_off>
}
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6105                	addi	sp,sp,32
    80001ca6:	8082                	ret

0000000080001ca8 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ca8:	1141                	addi	sp,sp,-16
    80001caa:	e406                	sd	ra,8(sp)
    80001cac:	e022                	sd	s0,0(sp)
    80001cae:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	fc0080e7          	jalr	-64(ra) # 80001c70 <myproc>
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	15e080e7          	jalr	350(ra) # 80000e16 <release>

    if (first)
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	cf07a783          	lw	a5,-784(a5) # 800089b0 <first.1>
    80001cc8:	eb89                	bnez	a5,80001cda <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001cca:	00001097          	auipc	ra,0x1
    80001cce:	e40080e7          	jalr	-448(ra) # 80002b0a <usertrapret>
}
    80001cd2:	60a2                	ld	ra,8(sp)
    80001cd4:	6402                	ld	s0,0(sp)
    80001cd6:	0141                	addi	sp,sp,16
    80001cd8:	8082                	ret
        first = 0;
    80001cda:	00007797          	auipc	a5,0x7
    80001cde:	cc07ab23          	sw	zero,-810(a5) # 800089b0 <first.1>
        fsinit(ROOTDEV);
    80001ce2:	4505                	li	a0,1
    80001ce4:	00002097          	auipc	ra,0x2
    80001ce8:	dbc080e7          	jalr	-580(ra) # 80003aa0 <fsinit>
    80001cec:	bff9                	j	80001cca <forkret+0x22>

0000000080001cee <allocpid>:
{
    80001cee:	1101                	addi	sp,sp,-32
    80001cf0:	ec06                	sd	ra,24(sp)
    80001cf2:	e822                	sd	s0,16(sp)
    80001cf4:	e426                	sd	s1,8(sp)
    80001cf6:	e04a                	sd	s2,0(sp)
    80001cf8:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001cfa:	0002f917          	auipc	s2,0x2f
    80001cfe:	40690913          	addi	s2,s2,1030 # 80031100 <pid_lock>
    80001d02:	854a                	mv	a0,s2
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	05e080e7          	jalr	94(ra) # 80000d62 <acquire>
    pid = nextpid;
    80001d0c:	00007797          	auipc	a5,0x7
    80001d10:	cb478793          	addi	a5,a5,-844 # 800089c0 <nextpid>
    80001d14:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001d16:	0014871b          	addiw	a4,s1,1
    80001d1a:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001d1c:	854a                	mv	a0,s2
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	0f8080e7          	jalr	248(ra) # 80000e16 <release>
}
    80001d26:	8526                	mv	a0,s1
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6902                	ld	s2,0(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret

0000000080001d34 <proc_pagetable>:
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	e04a                	sd	s2,0(sp)
    80001d3e:	1000                	addi	s0,sp,32
    80001d40:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	7a0080e7          	jalr	1952(ra) # 800014e2 <uvmcreate>
    80001d4a:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001d4c:	c121                	beqz	a0,80001d8c <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d4e:	4729                	li	a4,10
    80001d50:	00005697          	auipc	a3,0x5
    80001d54:	2b068693          	addi	a3,a3,688 # 80007000 <_trampoline>
    80001d58:	6605                	lui	a2,0x1
    80001d5a:	040005b7          	lui	a1,0x4000
    80001d5e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d60:	05b2                	slli	a1,a1,0xc
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	4c8080e7          	jalr	1224(ra) # 8000122a <mappages>
    80001d6a:	02054863          	bltz	a0,80001d9a <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d6e:	4719                	li	a4,6
    80001d70:	05893683          	ld	a3,88(s2)
    80001d74:	6605                	lui	a2,0x1
    80001d76:	020005b7          	lui	a1,0x2000
    80001d7a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d7c:	05b6                	slli	a1,a1,0xd
    80001d7e:	8526                	mv	a0,s1
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	4aa080e7          	jalr	1194(ra) # 8000122a <mappages>
    80001d88:	02054163          	bltz	a0,80001daa <proc_pagetable+0x76>
}
    80001d8c:	8526                	mv	a0,s1
    80001d8e:	60e2                	ld	ra,24(sp)
    80001d90:	6442                	ld	s0,16(sp)
    80001d92:	64a2                	ld	s1,8(sp)
    80001d94:	6902                	ld	s2,0(sp)
    80001d96:	6105                	addi	sp,sp,32
    80001d98:	8082                	ret
        uvmfree(pagetable, 0);
    80001d9a:	4581                	li	a1,0
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	94a080e7          	jalr	-1718(ra) # 800016e8 <uvmfree>
        return 0;
    80001da6:	4481                	li	s1,0
    80001da8:	b7d5                	j	80001d8c <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001daa:	4681                	li	a3,0
    80001dac:	4605                	li	a2,1
    80001dae:	040005b7          	lui	a1,0x4000
    80001db2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001db4:	05b2                	slli	a1,a1,0xc
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	638080e7          	jalr	1592(ra) # 800013f0 <uvmunmap>
        uvmfree(pagetable, 0);
    80001dc0:	4581                	li	a1,0
    80001dc2:	8526                	mv	a0,s1
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	924080e7          	jalr	-1756(ra) # 800016e8 <uvmfree>
        return 0;
    80001dcc:	4481                	li	s1,0
    80001dce:	bf7d                	j	80001d8c <proc_pagetable+0x58>

0000000080001dd0 <proc_freepagetable>:
{
    80001dd0:	1101                	addi	sp,sp,-32
    80001dd2:	ec06                	sd	ra,24(sp)
    80001dd4:	e822                	sd	s0,16(sp)
    80001dd6:	e426                	sd	s1,8(sp)
    80001dd8:	e04a                	sd	s2,0(sp)
    80001dda:	1000                	addi	s0,sp,32
    80001ddc:	84aa                	mv	s1,a0
    80001dde:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001de0:	4681                	li	a3,0
    80001de2:	4605                	li	a2,1
    80001de4:	040005b7          	lui	a1,0x4000
    80001de8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dea:	05b2                	slli	a1,a1,0xc
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	604080e7          	jalr	1540(ra) # 800013f0 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001df4:	4681                	li	a3,0
    80001df6:	4605                	li	a2,1
    80001df8:	020005b7          	lui	a1,0x2000
    80001dfc:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001dfe:	05b6                	slli	a1,a1,0xd
    80001e00:	8526                	mv	a0,s1
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	5ee080e7          	jalr	1518(ra) # 800013f0 <uvmunmap>
    uvmfree(pagetable, sz);
    80001e0a:	85ca                	mv	a1,s2
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	8da080e7          	jalr	-1830(ra) # 800016e8 <uvmfree>
}
    80001e16:	60e2                	ld	ra,24(sp)
    80001e18:	6442                	ld	s0,16(sp)
    80001e1a:	64a2                	ld	s1,8(sp)
    80001e1c:	6902                	ld	s2,0(sp)
    80001e1e:	6105                	addi	sp,sp,32
    80001e20:	8082                	ret

0000000080001e22 <freeproc>:
{
    80001e22:	1101                	addi	sp,sp,-32
    80001e24:	ec06                	sd	ra,24(sp)
    80001e26:	e822                	sd	s0,16(sp)
    80001e28:	e426                	sd	s1,8(sp)
    80001e2a:	1000                	addi	s0,sp,32
    80001e2c:	84aa                	mv	s1,a0
    if (p->trapframe){
    80001e2e:	6d28                	ld	a0,88(a0)
    80001e30:	c509                	beqz	a0,80001e3a <freeproc+0x18>
        newkfree((void *)p->trapframe);
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	ddc080e7          	jalr	-548(ra) # 80000c0e <newkfree>
    p->trapframe = 0;
    80001e3a:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001e3e:	68a8                	ld	a0,80(s1)
    80001e40:	c511                	beqz	a0,80001e4c <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001e42:	64ac                	ld	a1,72(s1)
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	f8c080e7          	jalr	-116(ra) # 80001dd0 <proc_freepagetable>
    p->pagetable = 0;
    80001e4c:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001e50:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001e54:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001e58:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001e5c:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001e60:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001e64:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001e68:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001e6c:	0004ac23          	sw	zero,24(s1)
}
    80001e70:	60e2                	ld	ra,24(sp)
    80001e72:	6442                	ld	s0,16(sp)
    80001e74:	64a2                	ld	s1,8(sp)
    80001e76:	6105                	addi	sp,sp,32
    80001e78:	8082                	ret

0000000080001e7a <allocproc>:
{
    80001e7a:	1101                	addi	sp,sp,-32
    80001e7c:	ec06                	sd	ra,24(sp)
    80001e7e:	e822                	sd	s0,16(sp)
    80001e80:	e426                	sd	s1,8(sp)
    80001e82:	e04a                	sd	s2,0(sp)
    80001e84:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e86:	0002f497          	auipc	s1,0x2f
    80001e8a:	2aa48493          	addi	s1,s1,682 # 80031130 <proc>
    80001e8e:	00035917          	auipc	s2,0x35
    80001e92:	ca290913          	addi	s2,s2,-862 # 80036b30 <tickslock>
        acquire(&p->lock);
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	eca080e7          	jalr	-310(ra) # 80000d62 <acquire>
        if (p->state == UNUSED)
    80001ea0:	4c9c                	lw	a5,24(s1)
    80001ea2:	cf81                	beqz	a5,80001eba <allocproc+0x40>
            release(&p->lock);
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	f70080e7          	jalr	-144(ra) # 80000e16 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001eae:	16848493          	addi	s1,s1,360
    80001eb2:	ff2492e3          	bne	s1,s2,80001e96 <allocproc+0x1c>
    return 0;
    80001eb6:	4481                	li	s1,0
    80001eb8:	a889                	j	80001f0a <allocproc+0x90>
    p->pid = allocpid();
    80001eba:	00000097          	auipc	ra,0x0
    80001ebe:	e34080e7          	jalr	-460(ra) # 80001cee <allocpid>
    80001ec2:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001ec4:	4785                	li	a5,1
    80001ec6:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	c9a080e7          	jalr	-870(ra) # 80000b62 <kalloc>
    80001ed0:	892a                	mv	s2,a0
    80001ed2:	eca8                	sd	a0,88(s1)
    80001ed4:	c131                	beqz	a0,80001f18 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	e5c080e7          	jalr	-420(ra) # 80001d34 <proc_pagetable>
    80001ee0:	892a                	mv	s2,a0
    80001ee2:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001ee4:	c531                	beqz	a0,80001f30 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001ee6:	07000613          	li	a2,112
    80001eea:	4581                	li	a1,0
    80001eec:	06048513          	addi	a0,s1,96
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	f6e080e7          	jalr	-146(ra) # 80000e5e <memset>
    p->context.ra = (uint64)forkret;
    80001ef8:	00000797          	auipc	a5,0x0
    80001efc:	db078793          	addi	a5,a5,-592 # 80001ca8 <forkret>
    80001f00:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001f02:	60bc                	ld	a5,64(s1)
    80001f04:	6705                	lui	a4,0x1
    80001f06:	97ba                	add	a5,a5,a4
    80001f08:	f4bc                	sd	a5,104(s1)
}
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	60e2                	ld	ra,24(sp)
    80001f0e:	6442                	ld	s0,16(sp)
    80001f10:	64a2                	ld	s1,8(sp)
    80001f12:	6902                	ld	s2,0(sp)
    80001f14:	6105                	addi	sp,sp,32
    80001f16:	8082                	ret
        freeproc(p);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	00000097          	auipc	ra,0x0
    80001f1e:	f08080e7          	jalr	-248(ra) # 80001e22 <freeproc>
        release(&p->lock);
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	ef2080e7          	jalr	-270(ra) # 80000e16 <release>
        return 0;
    80001f2c:	84ca                	mv	s1,s2
    80001f2e:	bff1                	j	80001f0a <allocproc+0x90>
        freeproc(p);
    80001f30:	8526                	mv	a0,s1
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	ef0080e7          	jalr	-272(ra) # 80001e22 <freeproc>
        release(&p->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	eda080e7          	jalr	-294(ra) # 80000e16 <release>
        return 0;
    80001f44:	84ca                	mv	s1,s2
    80001f46:	b7d1                	j	80001f0a <allocproc+0x90>

0000000080001f48 <userinit>:
{
    80001f48:	1101                	addi	sp,sp,-32
    80001f4a:	ec06                	sd	ra,24(sp)
    80001f4c:	e822                	sd	s0,16(sp)
    80001f4e:	e426                	sd	s1,8(sp)
    80001f50:	1000                	addi	s0,sp,32
    p = allocproc();
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	f28080e7          	jalr	-216(ra) # 80001e7a <allocproc>
    80001f5a:	84aa                	mv	s1,a0
    initproc = p;
    80001f5c:	00007797          	auipc	a5,0x7
    80001f60:	b2a7b623          	sd	a0,-1236(a5) # 80008a88 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f64:	03400613          	li	a2,52
    80001f68:	00007597          	auipc	a1,0x7
    80001f6c:	a6858593          	addi	a1,a1,-1432 # 800089d0 <initcode>
    80001f70:	6928                	ld	a0,80(a0)
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	59e080e7          	jalr	1438(ra) # 80001510 <uvmfirst>
    p->sz = PGSIZE;
    80001f7a:	6785                	lui	a5,0x1
    80001f7c:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001f7e:	6cb8                	ld	a4,88(s1)
    80001f80:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f84:	6cb8                	ld	a4,88(s1)
    80001f86:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f88:	4641                	li	a2,16
    80001f8a:	00006597          	auipc	a1,0x6
    80001f8e:	2b658593          	addi	a1,a1,694 # 80008240 <digits+0x1f0>
    80001f92:	15848513          	addi	a0,s1,344
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	012080e7          	jalr	18(ra) # 80000fa8 <safestrcpy>
    p->cwd = namei("/");
    80001f9e:	00006517          	auipc	a0,0x6
    80001fa2:	2b250513          	addi	a0,a0,690 # 80008250 <digits+0x200>
    80001fa6:	00002097          	auipc	ra,0x2
    80001faa:	524080e7          	jalr	1316(ra) # 800044ca <namei>
    80001fae:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001fb2:	478d                	li	a5,3
    80001fb4:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	e5e080e7          	jalr	-418(ra) # 80000e16 <release>
}
    80001fc0:	60e2                	ld	ra,24(sp)
    80001fc2:	6442                	ld	s0,16(sp)
    80001fc4:	64a2                	ld	s1,8(sp)
    80001fc6:	6105                	addi	sp,sp,32
    80001fc8:	8082                	ret

0000000080001fca <growproc>:
{
    80001fca:	1101                	addi	sp,sp,-32
    80001fcc:	ec06                	sd	ra,24(sp)
    80001fce:	e822                	sd	s0,16(sp)
    80001fd0:	e426                	sd	s1,8(sp)
    80001fd2:	e04a                	sd	s2,0(sp)
    80001fd4:	1000                	addi	s0,sp,32
    80001fd6:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001fd8:	00000097          	auipc	ra,0x0
    80001fdc:	c98080e7          	jalr	-872(ra) # 80001c70 <myproc>
    80001fe0:	84aa                	mv	s1,a0
    sz = p->sz;
    80001fe2:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001fe4:	01204c63          	bgtz	s2,80001ffc <growproc+0x32>
    else if (n < 0)
    80001fe8:	02094663          	bltz	s2,80002014 <growproc+0x4a>
    p->sz = sz;
    80001fec:	e4ac                	sd	a1,72(s1)
    return 0;
    80001fee:	4501                	li	a0,0
}
    80001ff0:	60e2                	ld	ra,24(sp)
    80001ff2:	6442                	ld	s0,16(sp)
    80001ff4:	64a2                	ld	s1,8(sp)
    80001ff6:	6902                	ld	s2,0(sp)
    80001ff8:	6105                	addi	sp,sp,32
    80001ffa:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001ffc:	4691                	li	a3,4
    80001ffe:	00b90633          	add	a2,s2,a1
    80002002:	6928                	ld	a0,80(a0)
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	5c6080e7          	jalr	1478(ra) # 800015ca <uvmalloc>
    8000200c:	85aa                	mv	a1,a0
    8000200e:	fd79                	bnez	a0,80001fec <growproc+0x22>
            return -1;
    80002010:	557d                	li	a0,-1
    80002012:	bff9                	j	80001ff0 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002014:	00b90633          	add	a2,s2,a1
    80002018:	6928                	ld	a0,80(a0)
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	568080e7          	jalr	1384(ra) # 80001582 <uvmdealloc>
    80002022:	85aa                	mv	a1,a0
    80002024:	b7e1                	j	80001fec <growproc+0x22>

0000000080002026 <ps>:
{
    80002026:	715d                	addi	sp,sp,-80
    80002028:	e486                	sd	ra,72(sp)
    8000202a:	e0a2                	sd	s0,64(sp)
    8000202c:	fc26                	sd	s1,56(sp)
    8000202e:	f84a                	sd	s2,48(sp)
    80002030:	f44e                	sd	s3,40(sp)
    80002032:	f052                	sd	s4,32(sp)
    80002034:	ec56                	sd	s5,24(sp)
    80002036:	e85a                	sd	s6,16(sp)
    80002038:	e45e                	sd	s7,8(sp)
    8000203a:	e062                	sd	s8,0(sp)
    8000203c:	0880                	addi	s0,sp,80
    8000203e:	84aa                	mv	s1,a0
    80002040:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80002042:	00000097          	auipc	ra,0x0
    80002046:	c2e080e7          	jalr	-978(ra) # 80001c70 <myproc>
    if (count == 0)
    8000204a:	140b8163          	beqz	s7,8000218c <ps+0x166>
    void *result = (void *)myproc()->sz;
    8000204e:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80002052:	003b951b          	slliw	a0,s7,0x3
    80002056:	0175053b          	addw	a0,a0,s7
    8000205a:	0025151b          	slliw	a0,a0,0x2
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	f6c080e7          	jalr	-148(ra) # 80001fca <growproc>
    80002066:	12054563          	bltz	a0,80002190 <ps+0x16a>
    struct user_proc loc_result[count];
    8000206a:	003b9a13          	slli	s4,s7,0x3
    8000206e:	9a5e                	add	s4,s4,s7
    80002070:	0a0a                	slli	s4,s4,0x2
    80002072:	00fa0793          	addi	a5,s4,15
    80002076:	8391                	srli	a5,a5,0x4
    80002078:	0792                	slli	a5,a5,0x4
    8000207a:	40f10133          	sub	sp,sp,a5
    8000207e:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80002080:	007e97b7          	lui	a5,0x7e9
    80002084:	02f484b3          	mul	s1,s1,a5
    80002088:	0002f797          	auipc	a5,0x2f
    8000208c:	0a878793          	addi	a5,a5,168 # 80031130 <proc>
    80002090:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80002092:	00035797          	auipc	a5,0x35
    80002096:	a9e78793          	addi	a5,a5,-1378 # 80036b30 <tickslock>
    8000209a:	0ef4fd63          	bgeu	s1,a5,80002194 <ps+0x16e>
    8000209e:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    800020a2:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800020a4:	8c3e                	mv	s8,a5
    800020a6:	a851                	j	8000213a <ps+0x114>
            loc_result[localCount].state = UNUSED;
    800020a8:	00399793          	slli	a5,s3,0x3
    800020ac:	97ce                	add	a5,a5,s3
    800020ae:	078a                	slli	a5,a5,0x2
    800020b0:	97d6                	add	a5,a5,s5
    800020b2:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	d5e080e7          	jalr	-674(ra) # 80000e16 <release>
    release(&wait_lock);
    800020c0:	0002f517          	auipc	a0,0x2f
    800020c4:	05850513          	addi	a0,a0,88 # 80031118 <wait_lock>
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	d4e080e7          	jalr	-690(ra) # 80000e16 <release>
    if (localCount < count)
    800020d0:	0179f963          	bgeu	s3,s7,800020e2 <ps+0xbc>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    800020d4:	00399793          	slli	a5,s3,0x3
    800020d8:	97ce                	add	a5,a5,s3
    800020da:	078a                	slli	a5,a5,0x2
    800020dc:	97d6                	add	a5,a5,s5
    800020de:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800020e2:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	b8c080e7          	jalr	-1140(ra) # 80001c70 <myproc>
    800020ec:	86d2                	mv	a3,s4
    800020ee:	8656                	mv	a2,s5
    800020f0:	85da                	mv	a1,s6
    800020f2:	6928                	ld	a0,80(a0)
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	73e080e7          	jalr	1854(ra) # 80001832 <copyout>
}
    800020fc:	8526                	mv	a0,s1
    800020fe:	fb040113          	addi	sp,s0,-80
    80002102:	60a6                	ld	ra,72(sp)
    80002104:	6406                	ld	s0,64(sp)
    80002106:	74e2                	ld	s1,56(sp)
    80002108:	7942                	ld	s2,48(sp)
    8000210a:	79a2                	ld	s3,40(sp)
    8000210c:	7a02                	ld	s4,32(sp)
    8000210e:	6ae2                	ld	s5,24(sp)
    80002110:	6b42                	ld	s6,16(sp)
    80002112:	6ba2                	ld	s7,8(sp)
    80002114:	6c02                	ld	s8,0(sp)
    80002116:	6161                	addi	sp,sp,80
    80002118:	8082                	ret
        release(&p->lock);
    8000211a:	8526                	mv	a0,s1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	cfa080e7          	jalr	-774(ra) # 80000e16 <release>
        localCount++;
    80002124:	2985                	addiw	s3,s3,1
    80002126:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    8000212a:	16848493          	addi	s1,s1,360
    8000212e:	f984f9e3          	bgeu	s1,s8,800020c0 <ps+0x9a>
        if (localCount == count)
    80002132:	02490913          	addi	s2,s2,36
    80002136:	073b8163          	beq	s7,s3,80002198 <ps+0x172>
        acquire(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	c26080e7          	jalr	-986(ra) # 80000d62 <acquire>
        if (p->state == UNUSED)
    80002144:	4c9c                	lw	a5,24(s1)
    80002146:	d3ad                	beqz	a5,800020a8 <ps+0x82>
        loc_result[localCount].state = p->state;
    80002148:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000214c:	549c                	lw	a5,40(s1)
    8000214e:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002152:	54dc                	lw	a5,44(s1)
    80002154:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002158:	589c                	lw	a5,48(s1)
    8000215a:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    8000215e:	4641                	li	a2,16
    80002160:	85ca                	mv	a1,s2
    80002162:	15848513          	addi	a0,s1,344
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	ab0080e7          	jalr	-1360(ra) # 80001c16 <copy_array>
        if (p->parent != 0) // init
    8000216e:	7c88                	ld	a0,56(s1)
    80002170:	d54d                	beqz	a0,8000211a <ps+0xf4>
            acquire(&p->parent->lock);
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	bf0080e7          	jalr	-1040(ra) # 80000d62 <acquire>
            loc_result[localCount].parent_id = p->parent->pid;
    8000217a:	7c88                	ld	a0,56(s1)
    8000217c:	591c                	lw	a5,48(a0)
    8000217e:	fef92e23          	sw	a5,-4(s2)
            release(&p->parent->lock);
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	c94080e7          	jalr	-876(ra) # 80000e16 <release>
    8000218a:	bf41                	j	8000211a <ps+0xf4>
        return result;
    8000218c:	4481                	li	s1,0
    8000218e:	b7bd                	j	800020fc <ps+0xd6>
        return result;
    80002190:	4481                	li	s1,0
    80002192:	b7ad                	j	800020fc <ps+0xd6>
        return result;
    80002194:	4481                	li	s1,0
    80002196:	b79d                	j	800020fc <ps+0xd6>
    release(&wait_lock);
    80002198:	0002f517          	auipc	a0,0x2f
    8000219c:	f8050513          	addi	a0,a0,-128 # 80031118 <wait_lock>
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	c76080e7          	jalr	-906(ra) # 80000e16 <release>
    if (localCount < count)
    800021a8:	bf2d                	j	800020e2 <ps+0xbc>

00000000800021aa <fork>:
{
    800021aa:	7139                	addi	sp,sp,-64
    800021ac:	fc06                	sd	ra,56(sp)
    800021ae:	f822                	sd	s0,48(sp)
    800021b0:	f426                	sd	s1,40(sp)
    800021b2:	f04a                	sd	s2,32(sp)
    800021b4:	ec4e                	sd	s3,24(sp)
    800021b6:	e852                	sd	s4,16(sp)
    800021b8:	e456                	sd	s5,8(sp)
    800021ba:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	ab4080e7          	jalr	-1356(ra) # 80001c70 <myproc>
    800021c4:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800021c6:	00000097          	auipc	ra,0x0
    800021ca:	cb4080e7          	jalr	-844(ra) # 80001e7a <allocproc>
    800021ce:	10050c63          	beqz	a0,800022e6 <fork+0x13c>
    800021d2:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800021d4:	048ab603          	ld	a2,72(s5)
    800021d8:	692c                	ld	a1,80(a0)
    800021da:	050ab503          	ld	a0,80(s5)
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	544080e7          	jalr	1348(ra) # 80001722 <uvmcopy>
    800021e6:	04054863          	bltz	a0,80002236 <fork+0x8c>
    np->sz = p->sz;
    800021ea:	048ab783          	ld	a5,72(s5)
    800021ee:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800021f2:	058ab683          	ld	a3,88(s5)
    800021f6:	87b6                	mv	a5,a3
    800021f8:	058a3703          	ld	a4,88(s4)
    800021fc:	12068693          	addi	a3,a3,288
    80002200:	0007b803          	ld	a6,0(a5)
    80002204:	6788                	ld	a0,8(a5)
    80002206:	6b8c                	ld	a1,16(a5)
    80002208:	6f90                	ld	a2,24(a5)
    8000220a:	01073023          	sd	a6,0(a4)
    8000220e:	e708                	sd	a0,8(a4)
    80002210:	eb0c                	sd	a1,16(a4)
    80002212:	ef10                	sd	a2,24(a4)
    80002214:	02078793          	addi	a5,a5,32
    80002218:	02070713          	addi	a4,a4,32
    8000221c:	fed792e3          	bne	a5,a3,80002200 <fork+0x56>
    np->trapframe->a0 = 0;
    80002220:	058a3783          	ld	a5,88(s4)
    80002224:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002228:	0d0a8493          	addi	s1,s5,208
    8000222c:	0d0a0913          	addi	s2,s4,208
    80002230:	150a8993          	addi	s3,s5,336
    80002234:	a00d                	j	80002256 <fork+0xac>
        freeproc(np);
    80002236:	8552                	mv	a0,s4
    80002238:	00000097          	auipc	ra,0x0
    8000223c:	bea080e7          	jalr	-1046(ra) # 80001e22 <freeproc>
        release(&np->lock);
    80002240:	8552                	mv	a0,s4
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	bd4080e7          	jalr	-1068(ra) # 80000e16 <release>
        return -1;
    8000224a:	597d                	li	s2,-1
    8000224c:	a059                	j	800022d2 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    8000224e:	04a1                	addi	s1,s1,8
    80002250:	0921                	addi	s2,s2,8
    80002252:	01348b63          	beq	s1,s3,80002268 <fork+0xbe>
        if (p->ofile[i])
    80002256:	6088                	ld	a0,0(s1)
    80002258:	d97d                	beqz	a0,8000224e <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    8000225a:	00003097          	auipc	ra,0x3
    8000225e:	906080e7          	jalr	-1786(ra) # 80004b60 <filedup>
    80002262:	00a93023          	sd	a0,0(s2)
    80002266:	b7e5                	j	8000224e <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002268:	150ab503          	ld	a0,336(s5)
    8000226c:	00002097          	auipc	ra,0x2
    80002270:	a74080e7          	jalr	-1420(ra) # 80003ce0 <idup>
    80002274:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002278:	4641                	li	a2,16
    8000227a:	158a8593          	addi	a1,s5,344
    8000227e:	158a0513          	addi	a0,s4,344
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	d26080e7          	jalr	-730(ra) # 80000fa8 <safestrcpy>
    pid = np->pid;
    8000228a:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    8000228e:	8552                	mv	a0,s4
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	b86080e7          	jalr	-1146(ra) # 80000e16 <release>
    acquire(&wait_lock);
    80002298:	0002f497          	auipc	s1,0x2f
    8000229c:	e8048493          	addi	s1,s1,-384 # 80031118 <wait_lock>
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	ac0080e7          	jalr	-1344(ra) # 80000d62 <acquire>
    np->parent = p;
    800022aa:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	b66080e7          	jalr	-1178(ra) # 80000e16 <release>
    acquire(&np->lock);
    800022b8:	8552                	mv	a0,s4
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	aa8080e7          	jalr	-1368(ra) # 80000d62 <acquire>
    np->state = RUNNABLE;
    800022c2:	478d                	li	a5,3
    800022c4:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800022c8:	8552                	mv	a0,s4
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	b4c080e7          	jalr	-1204(ra) # 80000e16 <release>
}
    800022d2:	854a                	mv	a0,s2
    800022d4:	70e2                	ld	ra,56(sp)
    800022d6:	7442                	ld	s0,48(sp)
    800022d8:	74a2                	ld	s1,40(sp)
    800022da:	7902                	ld	s2,32(sp)
    800022dc:	69e2                	ld	s3,24(sp)
    800022de:	6a42                	ld	s4,16(sp)
    800022e0:	6aa2                	ld	s5,8(sp)
    800022e2:	6121                	addi	sp,sp,64
    800022e4:	8082                	ret
        return -1;
    800022e6:	597d                	li	s2,-1
    800022e8:	b7ed                	j	800022d2 <fork+0x128>

00000000800022ea <scheduler>:
{
    800022ea:	1101                	addi	sp,sp,-32
    800022ec:	ec06                	sd	ra,24(sp)
    800022ee:	e822                	sd	s0,16(sp)
    800022f0:	e426                	sd	s1,8(sp)
    800022f2:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800022f4:	00006497          	auipc	s1,0x6
    800022f8:	6c448493          	addi	s1,s1,1732 # 800089b8 <sched_pointer>
    800022fc:	609c                	ld	a5,0(s1)
    800022fe:	9782                	jalr	a5
    while (1)
    80002300:	bff5                	j	800022fc <scheduler+0x12>

0000000080002302 <sched>:
{
    80002302:	7179                	addi	sp,sp,-48
    80002304:	f406                	sd	ra,40(sp)
    80002306:	f022                	sd	s0,32(sp)
    80002308:	ec26                	sd	s1,24(sp)
    8000230a:	e84a                	sd	s2,16(sp)
    8000230c:	e44e                	sd	s3,8(sp)
    8000230e:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002310:	00000097          	auipc	ra,0x0
    80002314:	960080e7          	jalr	-1696(ra) # 80001c70 <myproc>
    80002318:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	9ce080e7          	jalr	-1586(ra) # 80000ce8 <holding>
    80002322:	c53d                	beqz	a0,80002390 <sched+0x8e>
    80002324:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002326:	2781                	sext.w	a5,a5
    80002328:	079e                	slli	a5,a5,0x7
    8000232a:	0002f717          	auipc	a4,0x2f
    8000232e:	9d670713          	addi	a4,a4,-1578 # 80030d00 <cpus>
    80002332:	97ba                	add	a5,a5,a4
    80002334:	5fb8                	lw	a4,120(a5)
    80002336:	4785                	li	a5,1
    80002338:	06f71463          	bne	a4,a5,800023a0 <sched+0x9e>
    if (p->state == RUNNING)
    8000233c:	4c98                	lw	a4,24(s1)
    8000233e:	4791                	li	a5,4
    80002340:	06f70863          	beq	a4,a5,800023b0 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002344:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002348:	8b89                	andi	a5,a5,2
    if (intr_get())
    8000234a:	ebbd                	bnez	a5,800023c0 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000234c:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    8000234e:	0002f917          	auipc	s2,0x2f
    80002352:	9b290913          	addi	s2,s2,-1614 # 80030d00 <cpus>
    80002356:	2781                	sext.w	a5,a5
    80002358:	079e                	slli	a5,a5,0x7
    8000235a:	97ca                	add	a5,a5,s2
    8000235c:	07c7a983          	lw	s3,124(a5)
    80002360:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002362:	2581                	sext.w	a1,a1
    80002364:	059e                	slli	a1,a1,0x7
    80002366:	05a1                	addi	a1,a1,8
    80002368:	95ca                	add	a1,a1,s2
    8000236a:	06048513          	addi	a0,s1,96
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	6e4080e7          	jalr	1764(ra) # 80002a52 <swtch>
    80002376:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002378:	2781                	sext.w	a5,a5
    8000237a:	079e                	slli	a5,a5,0x7
    8000237c:	993e                	add	s2,s2,a5
    8000237e:	07392e23          	sw	s3,124(s2)
}
    80002382:	70a2                	ld	ra,40(sp)
    80002384:	7402                	ld	s0,32(sp)
    80002386:	64e2                	ld	s1,24(sp)
    80002388:	6942                	ld	s2,16(sp)
    8000238a:	69a2                	ld	s3,8(sp)
    8000238c:	6145                	addi	sp,sp,48
    8000238e:	8082                	ret
        panic("sched p->lock");
    80002390:	00006517          	auipc	a0,0x6
    80002394:	ec850513          	addi	a0,a0,-312 # 80008258 <digits+0x208>
    80002398:	ffffe097          	auipc	ra,0xffffe
    8000239c:	1a8080e7          	jalr	424(ra) # 80000540 <panic>
        panic("sched locks");
    800023a0:	00006517          	auipc	a0,0x6
    800023a4:	ec850513          	addi	a0,a0,-312 # 80008268 <digits+0x218>
    800023a8:	ffffe097          	auipc	ra,0xffffe
    800023ac:	198080e7          	jalr	408(ra) # 80000540 <panic>
        panic("sched running");
    800023b0:	00006517          	auipc	a0,0x6
    800023b4:	ec850513          	addi	a0,a0,-312 # 80008278 <digits+0x228>
    800023b8:	ffffe097          	auipc	ra,0xffffe
    800023bc:	188080e7          	jalr	392(ra) # 80000540 <panic>
        panic("sched interruptible");
    800023c0:	00006517          	auipc	a0,0x6
    800023c4:	ec850513          	addi	a0,a0,-312 # 80008288 <digits+0x238>
    800023c8:	ffffe097          	auipc	ra,0xffffe
    800023cc:	178080e7          	jalr	376(ra) # 80000540 <panic>

00000000800023d0 <yield>:
{
    800023d0:	1101                	addi	sp,sp,-32
    800023d2:	ec06                	sd	ra,24(sp)
    800023d4:	e822                	sd	s0,16(sp)
    800023d6:	e426                	sd	s1,8(sp)
    800023d8:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800023da:	00000097          	auipc	ra,0x0
    800023de:	896080e7          	jalr	-1898(ra) # 80001c70 <myproc>
    800023e2:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	97e080e7          	jalr	-1666(ra) # 80000d62 <acquire>
    p->state = RUNNABLE;
    800023ec:	478d                	li	a5,3
    800023ee:	cc9c                	sw	a5,24(s1)
    sched();
    800023f0:	00000097          	auipc	ra,0x0
    800023f4:	f12080e7          	jalr	-238(ra) # 80002302 <sched>
    release(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	a1c080e7          	jalr	-1508(ra) # 80000e16 <release>
}
    80002402:	60e2                	ld	ra,24(sp)
    80002404:	6442                	ld	s0,16(sp)
    80002406:	64a2                	ld	s1,8(sp)
    80002408:	6105                	addi	sp,sp,32
    8000240a:	8082                	ret

000000008000240c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000240c:	7179                	addi	sp,sp,-48
    8000240e:	f406                	sd	ra,40(sp)
    80002410:	f022                	sd	s0,32(sp)
    80002412:	ec26                	sd	s1,24(sp)
    80002414:	e84a                	sd	s2,16(sp)
    80002416:	e44e                	sd	s3,8(sp)
    80002418:	1800                	addi	s0,sp,48
    8000241a:	89aa                	mv	s3,a0
    8000241c:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	852080e7          	jalr	-1966(ra) # 80001c70 <myproc>
    80002426:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	93a080e7          	jalr	-1734(ra) # 80000d62 <acquire>
    release(lk);
    80002430:	854a                	mv	a0,s2
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	9e4080e7          	jalr	-1564(ra) # 80000e16 <release>

    // Go to sleep.
    p->chan = chan;
    8000243a:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    8000243e:	4789                	li	a5,2
    80002440:	cc9c                	sw	a5,24(s1)

    sched();
    80002442:	00000097          	auipc	ra,0x0
    80002446:	ec0080e7          	jalr	-320(ra) # 80002302 <sched>

    // Tidy up.
    p->chan = 0;
    8000244a:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	9c6080e7          	jalr	-1594(ra) # 80000e16 <release>
    acquire(lk);
    80002458:	854a                	mv	a0,s2
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	908080e7          	jalr	-1784(ra) # 80000d62 <acquire>
}
    80002462:	70a2                	ld	ra,40(sp)
    80002464:	7402                	ld	s0,32(sp)
    80002466:	64e2                	ld	s1,24(sp)
    80002468:	6942                	ld	s2,16(sp)
    8000246a:	69a2                	ld	s3,8(sp)
    8000246c:	6145                	addi	sp,sp,48
    8000246e:	8082                	ret

0000000080002470 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002470:	7139                	addi	sp,sp,-64
    80002472:	fc06                	sd	ra,56(sp)
    80002474:	f822                	sd	s0,48(sp)
    80002476:	f426                	sd	s1,40(sp)
    80002478:	f04a                	sd	s2,32(sp)
    8000247a:	ec4e                	sd	s3,24(sp)
    8000247c:	e852                	sd	s4,16(sp)
    8000247e:	e456                	sd	s5,8(sp)
    80002480:	0080                	addi	s0,sp,64
    80002482:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002484:	0002f497          	auipc	s1,0x2f
    80002488:	cac48493          	addi	s1,s1,-852 # 80031130 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    8000248c:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    8000248e:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002490:	00034917          	auipc	s2,0x34
    80002494:	6a090913          	addi	s2,s2,1696 # 80036b30 <tickslock>
    80002498:	a811                	j	800024ac <wakeup+0x3c>
            }
            release(&p->lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	97a080e7          	jalr	-1670(ra) # 80000e16 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800024a4:	16848493          	addi	s1,s1,360
    800024a8:	03248663          	beq	s1,s2,800024d4 <wakeup+0x64>
        if (p != myproc())
    800024ac:	fffff097          	auipc	ra,0xfffff
    800024b0:	7c4080e7          	jalr	1988(ra) # 80001c70 <myproc>
    800024b4:	fea488e3          	beq	s1,a0,800024a4 <wakeup+0x34>
            acquire(&p->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	8a8080e7          	jalr	-1880(ra) # 80000d62 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800024c2:	4c9c                	lw	a5,24(s1)
    800024c4:	fd379be3          	bne	a5,s3,8000249a <wakeup+0x2a>
    800024c8:	709c                	ld	a5,32(s1)
    800024ca:	fd4798e3          	bne	a5,s4,8000249a <wakeup+0x2a>
                p->state = RUNNABLE;
    800024ce:	0154ac23          	sw	s5,24(s1)
    800024d2:	b7e1                	j	8000249a <wakeup+0x2a>
        }
    }
}
    800024d4:	70e2                	ld	ra,56(sp)
    800024d6:	7442                	ld	s0,48(sp)
    800024d8:	74a2                	ld	s1,40(sp)
    800024da:	7902                	ld	s2,32(sp)
    800024dc:	69e2                	ld	s3,24(sp)
    800024de:	6a42                	ld	s4,16(sp)
    800024e0:	6aa2                	ld	s5,8(sp)
    800024e2:	6121                	addi	sp,sp,64
    800024e4:	8082                	ret

00000000800024e6 <reparent>:
{
    800024e6:	7179                	addi	sp,sp,-48
    800024e8:	f406                	sd	ra,40(sp)
    800024ea:	f022                	sd	s0,32(sp)
    800024ec:	ec26                	sd	s1,24(sp)
    800024ee:	e84a                	sd	s2,16(sp)
    800024f0:	e44e                	sd	s3,8(sp)
    800024f2:	e052                	sd	s4,0(sp)
    800024f4:	1800                	addi	s0,sp,48
    800024f6:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024f8:	0002f497          	auipc	s1,0x2f
    800024fc:	c3848493          	addi	s1,s1,-968 # 80031130 <proc>
            pp->parent = initproc;
    80002500:	00006a17          	auipc	s4,0x6
    80002504:	588a0a13          	addi	s4,s4,1416 # 80008a88 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002508:	00034997          	auipc	s3,0x34
    8000250c:	62898993          	addi	s3,s3,1576 # 80036b30 <tickslock>
    80002510:	a029                	j	8000251a <reparent+0x34>
    80002512:	16848493          	addi	s1,s1,360
    80002516:	01348d63          	beq	s1,s3,80002530 <reparent+0x4a>
        if (pp->parent == p)
    8000251a:	7c9c                	ld	a5,56(s1)
    8000251c:	ff279be3          	bne	a5,s2,80002512 <reparent+0x2c>
            pp->parent = initproc;
    80002520:	000a3503          	ld	a0,0(s4)
    80002524:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80002526:	00000097          	auipc	ra,0x0
    8000252a:	f4a080e7          	jalr	-182(ra) # 80002470 <wakeup>
    8000252e:	b7d5                	j	80002512 <reparent+0x2c>
}
    80002530:	70a2                	ld	ra,40(sp)
    80002532:	7402                	ld	s0,32(sp)
    80002534:	64e2                	ld	s1,24(sp)
    80002536:	6942                	ld	s2,16(sp)
    80002538:	69a2                	ld	s3,8(sp)
    8000253a:	6a02                	ld	s4,0(sp)
    8000253c:	6145                	addi	sp,sp,48
    8000253e:	8082                	ret

0000000080002540 <exit>:
{
    80002540:	7179                	addi	sp,sp,-48
    80002542:	f406                	sd	ra,40(sp)
    80002544:	f022                	sd	s0,32(sp)
    80002546:	ec26                	sd	s1,24(sp)
    80002548:	e84a                	sd	s2,16(sp)
    8000254a:	e44e                	sd	s3,8(sp)
    8000254c:	e052                	sd	s4,0(sp)
    8000254e:	1800                	addi	s0,sp,48
    80002550:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	71e080e7          	jalr	1822(ra) # 80001c70 <myproc>
    8000255a:	89aa                	mv	s3,a0
    if (p == initproc)
    8000255c:	00006797          	auipc	a5,0x6
    80002560:	52c7b783          	ld	a5,1324(a5) # 80008a88 <initproc>
    80002564:	0d050493          	addi	s1,a0,208
    80002568:	15050913          	addi	s2,a0,336
    8000256c:	02a79363          	bne	a5,a0,80002592 <exit+0x52>
        panic("init exiting");
    80002570:	00006517          	auipc	a0,0x6
    80002574:	d3050513          	addi	a0,a0,-720 # 800082a0 <digits+0x250>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	fc8080e7          	jalr	-56(ra) # 80000540 <panic>
            fileclose(f);
    80002580:	00002097          	auipc	ra,0x2
    80002584:	632080e7          	jalr	1586(ra) # 80004bb2 <fileclose>
            p->ofile[fd] = 0;
    80002588:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    8000258c:	04a1                	addi	s1,s1,8
    8000258e:	01248563          	beq	s1,s2,80002598 <exit+0x58>
        if (p->ofile[fd])
    80002592:	6088                	ld	a0,0(s1)
    80002594:	f575                	bnez	a0,80002580 <exit+0x40>
    80002596:	bfdd                	j	8000258c <exit+0x4c>
    begin_op();
    80002598:	00002097          	auipc	ra,0x2
    8000259c:	152080e7          	jalr	338(ra) # 800046ea <begin_op>
    iput(p->cwd);
    800025a0:	1509b503          	ld	a0,336(s3)
    800025a4:	00002097          	auipc	ra,0x2
    800025a8:	934080e7          	jalr	-1740(ra) # 80003ed8 <iput>
    end_op();
    800025ac:	00002097          	auipc	ra,0x2
    800025b0:	1bc080e7          	jalr	444(ra) # 80004768 <end_op>
    p->cwd = 0;
    800025b4:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    800025b8:	0002f497          	auipc	s1,0x2f
    800025bc:	b6048493          	addi	s1,s1,-1184 # 80031118 <wait_lock>
    800025c0:	8526                	mv	a0,s1
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	7a0080e7          	jalr	1952(ra) # 80000d62 <acquire>
    reparent(p);
    800025ca:	854e                	mv	a0,s3
    800025cc:	00000097          	auipc	ra,0x0
    800025d0:	f1a080e7          	jalr	-230(ra) # 800024e6 <reparent>
    wakeup(p->parent);
    800025d4:	0389b503          	ld	a0,56(s3)
    800025d8:	00000097          	auipc	ra,0x0
    800025dc:	e98080e7          	jalr	-360(ra) # 80002470 <wakeup>
    acquire(&p->lock);
    800025e0:	854e                	mv	a0,s3
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	780080e7          	jalr	1920(ra) # 80000d62 <acquire>
    p->xstate = status;
    800025ea:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800025ee:	4795                	li	a5,5
    800025f0:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	fffff097          	auipc	ra,0xfffff
    800025fa:	820080e7          	jalr	-2016(ra) # 80000e16 <release>
    sched();
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	d04080e7          	jalr	-764(ra) # 80002302 <sched>
    panic("zombie exit");
    80002606:	00006517          	auipc	a0,0x6
    8000260a:	caa50513          	addi	a0,a0,-854 # 800082b0 <digits+0x260>
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f32080e7          	jalr	-206(ra) # 80000540 <panic>

0000000080002616 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002616:	7179                	addi	sp,sp,-48
    80002618:	f406                	sd	ra,40(sp)
    8000261a:	f022                	sd	s0,32(sp)
    8000261c:	ec26                	sd	s1,24(sp)
    8000261e:	e84a                	sd	s2,16(sp)
    80002620:	e44e                	sd	s3,8(sp)
    80002622:	1800                	addi	s0,sp,48
    80002624:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002626:	0002f497          	auipc	s1,0x2f
    8000262a:	b0a48493          	addi	s1,s1,-1270 # 80031130 <proc>
    8000262e:	00034997          	auipc	s3,0x34
    80002632:	50298993          	addi	s3,s3,1282 # 80036b30 <tickslock>
    {
        acquire(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	72a080e7          	jalr	1834(ra) # 80000d62 <acquire>
        if (p->pid == pid)
    80002640:	589c                	lw	a5,48(s1)
    80002642:	01278d63          	beq	a5,s2,8000265c <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002646:	8526                	mv	a0,s1
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	7ce080e7          	jalr	1998(ra) # 80000e16 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002650:	16848493          	addi	s1,s1,360
    80002654:	ff3491e3          	bne	s1,s3,80002636 <kill+0x20>
    }
    return -1;
    80002658:	557d                	li	a0,-1
    8000265a:	a829                	j	80002674 <kill+0x5e>
            p->killed = 1;
    8000265c:	4785                	li	a5,1
    8000265e:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002660:	4c98                	lw	a4,24(s1)
    80002662:	4789                	li	a5,2
    80002664:	00f70f63          	beq	a4,a5,80002682 <kill+0x6c>
            release(&p->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	7ac080e7          	jalr	1964(ra) # 80000e16 <release>
            return 0;
    80002672:	4501                	li	a0,0
}
    80002674:	70a2                	ld	ra,40(sp)
    80002676:	7402                	ld	s0,32(sp)
    80002678:	64e2                	ld	s1,24(sp)
    8000267a:	6942                	ld	s2,16(sp)
    8000267c:	69a2                	ld	s3,8(sp)
    8000267e:	6145                	addi	sp,sp,48
    80002680:	8082                	ret
                p->state = RUNNABLE;
    80002682:	478d                	li	a5,3
    80002684:	cc9c                	sw	a5,24(s1)
    80002686:	b7cd                	j	80002668 <kill+0x52>

0000000080002688 <setkilled>:

void setkilled(struct proc *p)
{
    80002688:	1101                	addi	sp,sp,-32
    8000268a:	ec06                	sd	ra,24(sp)
    8000268c:	e822                	sd	s0,16(sp)
    8000268e:	e426                	sd	s1,8(sp)
    80002690:	1000                	addi	s0,sp,32
    80002692:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	6ce080e7          	jalr	1742(ra) # 80000d62 <acquire>
    p->killed = 1;
    8000269c:	4785                	li	a5,1
    8000269e:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800026a0:	8526                	mv	a0,s1
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	774080e7          	jalr	1908(ra) # 80000e16 <release>
}
    800026aa:	60e2                	ld	ra,24(sp)
    800026ac:	6442                	ld	s0,16(sp)
    800026ae:	64a2                	ld	s1,8(sp)
    800026b0:	6105                	addi	sp,sp,32
    800026b2:	8082                	ret

00000000800026b4 <killed>:

int killed(struct proc *p)
{
    800026b4:	1101                	addi	sp,sp,-32
    800026b6:	ec06                	sd	ra,24(sp)
    800026b8:	e822                	sd	s0,16(sp)
    800026ba:	e426                	sd	s1,8(sp)
    800026bc:	e04a                	sd	s2,0(sp)
    800026be:	1000                	addi	s0,sp,32
    800026c0:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	6a0080e7          	jalr	1696(ra) # 80000d62 <acquire>
    k = p->killed;
    800026ca:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	746080e7          	jalr	1862(ra) # 80000e16 <release>
    return k;
}
    800026d8:	854a                	mv	a0,s2
    800026da:	60e2                	ld	ra,24(sp)
    800026dc:	6442                	ld	s0,16(sp)
    800026de:	64a2                	ld	s1,8(sp)
    800026e0:	6902                	ld	s2,0(sp)
    800026e2:	6105                	addi	sp,sp,32
    800026e4:	8082                	ret

00000000800026e6 <wait>:
{
    800026e6:	715d                	addi	sp,sp,-80
    800026e8:	e486                	sd	ra,72(sp)
    800026ea:	e0a2                	sd	s0,64(sp)
    800026ec:	fc26                	sd	s1,56(sp)
    800026ee:	f84a                	sd	s2,48(sp)
    800026f0:	f44e                	sd	s3,40(sp)
    800026f2:	f052                	sd	s4,32(sp)
    800026f4:	ec56                	sd	s5,24(sp)
    800026f6:	e85a                	sd	s6,16(sp)
    800026f8:	e45e                	sd	s7,8(sp)
    800026fa:	e062                	sd	s8,0(sp)
    800026fc:	0880                	addi	s0,sp,80
    800026fe:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	570080e7          	jalr	1392(ra) # 80001c70 <myproc>
    80002708:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000270a:	0002f517          	auipc	a0,0x2f
    8000270e:	a0e50513          	addi	a0,a0,-1522 # 80031118 <wait_lock>
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	650080e7          	jalr	1616(ra) # 80000d62 <acquire>
        havekids = 0;
    8000271a:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    8000271c:	4a15                	li	s4,5
                havekids = 1;
    8000271e:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002720:	00034997          	auipc	s3,0x34
    80002724:	41098993          	addi	s3,s3,1040 # 80036b30 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002728:	0002fc17          	auipc	s8,0x2f
    8000272c:	9f0c0c13          	addi	s8,s8,-1552 # 80031118 <wait_lock>
        havekids = 0;
    80002730:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002732:	0002f497          	auipc	s1,0x2f
    80002736:	9fe48493          	addi	s1,s1,-1538 # 80031130 <proc>
    8000273a:	a0bd                	j	800027a8 <wait+0xc2>
                    pid = pp->pid;
    8000273c:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002740:	000b0e63          	beqz	s6,8000275c <wait+0x76>
    80002744:	4691                	li	a3,4
    80002746:	02c48613          	addi	a2,s1,44
    8000274a:	85da                	mv	a1,s6
    8000274c:	05093503          	ld	a0,80(s2)
    80002750:	fffff097          	auipc	ra,0xfffff
    80002754:	0e2080e7          	jalr	226(ra) # 80001832 <copyout>
    80002758:	02054563          	bltz	a0,80002782 <wait+0x9c>
                    freeproc(pp);
    8000275c:	8526                	mv	a0,s1
    8000275e:	fffff097          	auipc	ra,0xfffff
    80002762:	6c4080e7          	jalr	1732(ra) # 80001e22 <freeproc>
                    release(&pp->lock);
    80002766:	8526                	mv	a0,s1
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	6ae080e7          	jalr	1710(ra) # 80000e16 <release>
                    release(&wait_lock);
    80002770:	0002f517          	auipc	a0,0x2f
    80002774:	9a850513          	addi	a0,a0,-1624 # 80031118 <wait_lock>
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	69e080e7          	jalr	1694(ra) # 80000e16 <release>
                    return pid;
    80002780:	a0b5                	j	800027ec <wait+0x106>
                        release(&pp->lock);
    80002782:	8526                	mv	a0,s1
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	692080e7          	jalr	1682(ra) # 80000e16 <release>
                        release(&wait_lock);
    8000278c:	0002f517          	auipc	a0,0x2f
    80002790:	98c50513          	addi	a0,a0,-1652 # 80031118 <wait_lock>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	682080e7          	jalr	1666(ra) # 80000e16 <release>
                        return -1;
    8000279c:	59fd                	li	s3,-1
    8000279e:	a0b9                	j	800027ec <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027a0:	16848493          	addi	s1,s1,360
    800027a4:	03348463          	beq	s1,s3,800027cc <wait+0xe6>
            if (pp->parent == p)
    800027a8:	7c9c                	ld	a5,56(s1)
    800027aa:	ff279be3          	bne	a5,s2,800027a0 <wait+0xba>
                acquire(&pp->lock);
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	5b2080e7          	jalr	1458(ra) # 80000d62 <acquire>
                if (pp->state == ZOMBIE)
    800027b8:	4c9c                	lw	a5,24(s1)
    800027ba:	f94781e3          	beq	a5,s4,8000273c <wait+0x56>
                release(&pp->lock);
    800027be:	8526                	mv	a0,s1
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	656080e7          	jalr	1622(ra) # 80000e16 <release>
                havekids = 1;
    800027c8:	8756                	mv	a4,s5
    800027ca:	bfd9                	j	800027a0 <wait+0xba>
        if (!havekids || killed(p))
    800027cc:	c719                	beqz	a4,800027da <wait+0xf4>
    800027ce:	854a                	mv	a0,s2
    800027d0:	00000097          	auipc	ra,0x0
    800027d4:	ee4080e7          	jalr	-284(ra) # 800026b4 <killed>
    800027d8:	c51d                	beqz	a0,80002806 <wait+0x120>
            release(&wait_lock);
    800027da:	0002f517          	auipc	a0,0x2f
    800027de:	93e50513          	addi	a0,a0,-1730 # 80031118 <wait_lock>
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	634080e7          	jalr	1588(ra) # 80000e16 <release>
            return -1;
    800027ea:	59fd                	li	s3,-1
}
    800027ec:	854e                	mv	a0,s3
    800027ee:	60a6                	ld	ra,72(sp)
    800027f0:	6406                	ld	s0,64(sp)
    800027f2:	74e2                	ld	s1,56(sp)
    800027f4:	7942                	ld	s2,48(sp)
    800027f6:	79a2                	ld	s3,40(sp)
    800027f8:	7a02                	ld	s4,32(sp)
    800027fa:	6ae2                	ld	s5,24(sp)
    800027fc:	6b42                	ld	s6,16(sp)
    800027fe:	6ba2                	ld	s7,8(sp)
    80002800:	6c02                	ld	s8,0(sp)
    80002802:	6161                	addi	sp,sp,80
    80002804:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002806:	85e2                	mv	a1,s8
    80002808:	854a                	mv	a0,s2
    8000280a:	00000097          	auipc	ra,0x0
    8000280e:	c02080e7          	jalr	-1022(ra) # 8000240c <sleep>
        havekids = 0;
    80002812:	bf39                	j	80002730 <wait+0x4a>

0000000080002814 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002814:	7179                	addi	sp,sp,-48
    80002816:	f406                	sd	ra,40(sp)
    80002818:	f022                	sd	s0,32(sp)
    8000281a:	ec26                	sd	s1,24(sp)
    8000281c:	e84a                	sd	s2,16(sp)
    8000281e:	e44e                	sd	s3,8(sp)
    80002820:	e052                	sd	s4,0(sp)
    80002822:	1800                	addi	s0,sp,48
    80002824:	84aa                	mv	s1,a0
    80002826:	892e                	mv	s2,a1
    80002828:	89b2                	mv	s3,a2
    8000282a:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000282c:	fffff097          	auipc	ra,0xfffff
    80002830:	444080e7          	jalr	1092(ra) # 80001c70 <myproc>
    if (user_dst)
    80002834:	c08d                	beqz	s1,80002856 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002836:	86d2                	mv	a3,s4
    80002838:	864e                	mv	a2,s3
    8000283a:	85ca                	mv	a1,s2
    8000283c:	6928                	ld	a0,80(a0)
    8000283e:	fffff097          	auipc	ra,0xfffff
    80002842:	ff4080e7          	jalr	-12(ra) # 80001832 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002846:	70a2                	ld	ra,40(sp)
    80002848:	7402                	ld	s0,32(sp)
    8000284a:	64e2                	ld	s1,24(sp)
    8000284c:	6942                	ld	s2,16(sp)
    8000284e:	69a2                	ld	s3,8(sp)
    80002850:	6a02                	ld	s4,0(sp)
    80002852:	6145                	addi	sp,sp,48
    80002854:	8082                	ret
        memmove((char *)dst, src, len);
    80002856:	000a061b          	sext.w	a2,s4
    8000285a:	85ce                	mv	a1,s3
    8000285c:	854a                	mv	a0,s2
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	65c080e7          	jalr	1628(ra) # 80000eba <memmove>
        return 0;
    80002866:	8526                	mv	a0,s1
    80002868:	bff9                	j	80002846 <either_copyout+0x32>

000000008000286a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000286a:	7179                	addi	sp,sp,-48
    8000286c:	f406                	sd	ra,40(sp)
    8000286e:	f022                	sd	s0,32(sp)
    80002870:	ec26                	sd	s1,24(sp)
    80002872:	e84a                	sd	s2,16(sp)
    80002874:	e44e                	sd	s3,8(sp)
    80002876:	e052                	sd	s4,0(sp)
    80002878:	1800                	addi	s0,sp,48
    8000287a:	892a                	mv	s2,a0
    8000287c:	84ae                	mv	s1,a1
    8000287e:	89b2                	mv	s3,a2
    80002880:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002882:	fffff097          	auipc	ra,0xfffff
    80002886:	3ee080e7          	jalr	1006(ra) # 80001c70 <myproc>
    if (user_src)
    8000288a:	c08d                	beqz	s1,800028ac <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    8000288c:	86d2                	mv	a3,s4
    8000288e:	864e                	mv	a2,s3
    80002890:	85ca                	mv	a1,s2
    80002892:	6928                	ld	a0,80(a0)
    80002894:	fffff097          	auipc	ra,0xfffff
    80002898:	02a080e7          	jalr	42(ra) # 800018be <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    8000289c:	70a2                	ld	ra,40(sp)
    8000289e:	7402                	ld	s0,32(sp)
    800028a0:	64e2                	ld	s1,24(sp)
    800028a2:	6942                	ld	s2,16(sp)
    800028a4:	69a2                	ld	s3,8(sp)
    800028a6:	6a02                	ld	s4,0(sp)
    800028a8:	6145                	addi	sp,sp,48
    800028aa:	8082                	ret
        memmove(dst, (char *)src, len);
    800028ac:	000a061b          	sext.w	a2,s4
    800028b0:	85ce                	mv	a1,s3
    800028b2:	854a                	mv	a0,s2
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	606080e7          	jalr	1542(ra) # 80000eba <memmove>
        return 0;
    800028bc:	8526                	mv	a0,s1
    800028be:	bff9                	j	8000289c <either_copyin+0x32>

00000000800028c0 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800028c0:	715d                	addi	sp,sp,-80
    800028c2:	e486                	sd	ra,72(sp)
    800028c4:	e0a2                	sd	s0,64(sp)
    800028c6:	fc26                	sd	s1,56(sp)
    800028c8:	f84a                	sd	s2,48(sp)
    800028ca:	f44e                	sd	s3,40(sp)
    800028cc:	f052                	sd	s4,32(sp)
    800028ce:	ec56                	sd	s5,24(sp)
    800028d0:	e85a                	sd	s6,16(sp)
    800028d2:	e45e                	sd	s7,8(sp)
    800028d4:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800028d6:	00005517          	auipc	a0,0x5
    800028da:	7b250513          	addi	a0,a0,1970 # 80008088 <digits+0x38>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	cbe080e7          	jalr	-834(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028e6:	0002f497          	auipc	s1,0x2f
    800028ea:	9a248493          	addi	s1,s1,-1630 # 80031288 <proc+0x158>
    800028ee:	00034917          	auipc	s2,0x34
    800028f2:	39a90913          	addi	s2,s2,922 # 80036c88 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f6:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800028f8:	00006997          	auipc	s3,0x6
    800028fc:	9c898993          	addi	s3,s3,-1592 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    80002900:	00006a97          	auipc	s5,0x6
    80002904:	9c8a8a93          	addi	s5,s5,-1592 # 800082c8 <digits+0x278>
        printf("\n");
    80002908:	00005a17          	auipc	s4,0x5
    8000290c:	780a0a13          	addi	s4,s4,1920 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002910:	00006b97          	auipc	s7,0x6
    80002914:	ac8b8b93          	addi	s7,s7,-1336 # 800083d8 <states.0>
    80002918:	a00d                	j	8000293a <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    8000291a:	ed86a583          	lw	a1,-296(a3)
    8000291e:	8556                	mv	a0,s5
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	c7c080e7          	jalr	-900(ra) # 8000059c <printf>
        printf("\n");
    80002928:	8552                	mv	a0,s4
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	c72080e7          	jalr	-910(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002932:	16848493          	addi	s1,s1,360
    80002936:	03248263          	beq	s1,s2,8000295a <procdump+0x9a>
        if (p->state == UNUSED)
    8000293a:	86a6                	mv	a3,s1
    8000293c:	ec04a783          	lw	a5,-320(s1)
    80002940:	dbed                	beqz	a5,80002932 <procdump+0x72>
            state = "???";
    80002942:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002944:	fcfb6be3          	bltu	s6,a5,8000291a <procdump+0x5a>
    80002948:	02079713          	slli	a4,a5,0x20
    8000294c:	01d75793          	srli	a5,a4,0x1d
    80002950:	97de                	add	a5,a5,s7
    80002952:	6390                	ld	a2,0(a5)
    80002954:	f279                	bnez	a2,8000291a <procdump+0x5a>
            state = "???";
    80002956:	864e                	mv	a2,s3
    80002958:	b7c9                	j	8000291a <procdump+0x5a>
    }
}
    8000295a:	60a6                	ld	ra,72(sp)
    8000295c:	6406                	ld	s0,64(sp)
    8000295e:	74e2                	ld	s1,56(sp)
    80002960:	7942                	ld	s2,48(sp)
    80002962:	79a2                	ld	s3,40(sp)
    80002964:	7a02                	ld	s4,32(sp)
    80002966:	6ae2                	ld	s5,24(sp)
    80002968:	6b42                	ld	s6,16(sp)
    8000296a:	6ba2                	ld	s7,8(sp)
    8000296c:	6161                	addi	sp,sp,80
    8000296e:	8082                	ret

0000000080002970 <schedls>:

void schedls()
{
    80002970:	1141                	addi	sp,sp,-16
    80002972:	e406                	sd	ra,8(sp)
    80002974:	e022                	sd	s0,0(sp)
    80002976:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	96050513          	addi	a0,a0,-1696 # 800082d8 <digits+0x288>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c1c080e7          	jalr	-996(ra) # 8000059c <printf>
    printf("====================================\n");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	97850513          	addi	a0,a0,-1672 # 80008300 <digits+0x2b0>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	c0c080e7          	jalr	-1012(ra) # 8000059c <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002998:	00006717          	auipc	a4,0x6
    8000299c:	08073703          	ld	a4,128(a4) # 80008a18 <available_schedulers+0x10>
    800029a0:	00006797          	auipc	a5,0x6
    800029a4:	0187b783          	ld	a5,24(a5) # 800089b8 <sched_pointer>
    800029a8:	04f70663          	beq	a4,a5,800029f4 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	98450513          	addi	a0,a0,-1660 # 80008330 <digits+0x2e0>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	be8080e7          	jalr	-1048(ra) # 8000059c <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800029bc:	00006617          	auipc	a2,0x6
    800029c0:	06462603          	lw	a2,100(a2) # 80008a20 <available_schedulers+0x18>
    800029c4:	00006597          	auipc	a1,0x6
    800029c8:	04458593          	addi	a1,a1,68 # 80008a08 <available_schedulers>
    800029cc:	00006517          	auipc	a0,0x6
    800029d0:	96c50513          	addi	a0,a0,-1684 # 80008338 <digits+0x2e8>
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	bc8080e7          	jalr	-1080(ra) # 8000059c <printf>
    }
    printf("\n*: current scheduler\n\n");
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	96450513          	addi	a0,a0,-1692 # 80008340 <digits+0x2f0>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	bb8080e7          	jalr	-1096(ra) # 8000059c <printf>
}
    800029ec:	60a2                	ld	ra,8(sp)
    800029ee:	6402                	ld	s0,0(sp)
    800029f0:	0141                	addi	sp,sp,16
    800029f2:	8082                	ret
            printf("[*]\t");
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	93450513          	addi	a0,a0,-1740 # 80008328 <digits+0x2d8>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	ba0080e7          	jalr	-1120(ra) # 8000059c <printf>
    80002a04:	bf65                	j	800029bc <schedls+0x4c>

0000000080002a06 <schedset>:

void schedset(int id)
{
    80002a06:	1141                	addi	sp,sp,-16
    80002a08:	e406                	sd	ra,8(sp)
    80002a0a:	e022                	sd	s0,0(sp)
    80002a0c:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002a0e:	e90d                	bnez	a0,80002a40 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002a10:	00006797          	auipc	a5,0x6
    80002a14:	0087b783          	ld	a5,8(a5) # 80008a18 <available_schedulers+0x10>
    80002a18:	00006717          	auipc	a4,0x6
    80002a1c:	faf73023          	sd	a5,-96(a4) # 800089b8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002a20:	00006597          	auipc	a1,0x6
    80002a24:	fe858593          	addi	a1,a1,-24 # 80008a08 <available_schedulers>
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	95850513          	addi	a0,a0,-1704 # 80008380 <digits+0x330>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b6c080e7          	jalr	-1172(ra) # 8000059c <printf>
    80002a38:	60a2                	ld	ra,8(sp)
    80002a3a:	6402                	ld	s0,0(sp)
    80002a3c:	0141                	addi	sp,sp,16
    80002a3e:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	91850513          	addi	a0,a0,-1768 # 80008358 <digits+0x308>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	b54080e7          	jalr	-1196(ra) # 8000059c <printf>
        return;
    80002a50:	b7e5                	j	80002a38 <schedset+0x32>

0000000080002a52 <swtch>:
    80002a52:	00153023          	sd	ra,0(a0)
    80002a56:	00253423          	sd	sp,8(a0)
    80002a5a:	e900                	sd	s0,16(a0)
    80002a5c:	ed04                	sd	s1,24(a0)
    80002a5e:	03253023          	sd	s2,32(a0)
    80002a62:	03353423          	sd	s3,40(a0)
    80002a66:	03453823          	sd	s4,48(a0)
    80002a6a:	03553c23          	sd	s5,56(a0)
    80002a6e:	05653023          	sd	s6,64(a0)
    80002a72:	05753423          	sd	s7,72(a0)
    80002a76:	05853823          	sd	s8,80(a0)
    80002a7a:	05953c23          	sd	s9,88(a0)
    80002a7e:	07a53023          	sd	s10,96(a0)
    80002a82:	07b53423          	sd	s11,104(a0)
    80002a86:	0005b083          	ld	ra,0(a1)
    80002a8a:	0085b103          	ld	sp,8(a1)
    80002a8e:	6980                	ld	s0,16(a1)
    80002a90:	6d84                	ld	s1,24(a1)
    80002a92:	0205b903          	ld	s2,32(a1)
    80002a96:	0285b983          	ld	s3,40(a1)
    80002a9a:	0305ba03          	ld	s4,48(a1)
    80002a9e:	0385ba83          	ld	s5,56(a1)
    80002aa2:	0405bb03          	ld	s6,64(a1)
    80002aa6:	0485bb83          	ld	s7,72(a1)
    80002aaa:	0505bc03          	ld	s8,80(a1)
    80002aae:	0585bc83          	ld	s9,88(a1)
    80002ab2:	0605bd03          	ld	s10,96(a1)
    80002ab6:	0685bd83          	ld	s11,104(a1)
    80002aba:	8082                	ret

0000000080002abc <trapinit>:

extern int counter[(PHYSTOP-KERNBASE)/PGSIZE];

void
trapinit(void)
{
    80002abc:	1141                	addi	sp,sp,-16
    80002abe:	e406                	sd	ra,8(sp)
    80002ac0:	e022                	sd	s0,0(sp)
    80002ac2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ac4:	00006597          	auipc	a1,0x6
    80002ac8:	94458593          	addi	a1,a1,-1724 # 80008408 <states.0+0x30>
    80002acc:	00034517          	auipc	a0,0x34
    80002ad0:	06450513          	addi	a0,a0,100 # 80036b30 <tickslock>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	1fe080e7          	jalr	510(ra) # 80000cd2 <initlock>
}
    80002adc:	60a2                	ld	ra,8(sp)
    80002ade:	6402                	ld	s0,0(sp)
    80002ae0:	0141                	addi	sp,sp,16
    80002ae2:	8082                	ret

0000000080002ae4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ae4:	1141                	addi	sp,sp,-16
    80002ae6:	e422                	sd	s0,8(sp)
    80002ae8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aea:	00003797          	auipc	a5,0x3
    80002aee:	71678793          	addi	a5,a5,1814 # 80006200 <kernelvec>
    80002af2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002af6:	6422                	ld	s0,8(sp)
    80002af8:	0141                	addi	sp,sp,16
    80002afa:	8082                	ret

0000000080002afc <handle_cow>:

// COW handling function
int handle_cow(uint64 faulting_address) {
    80002afc:	1141                	addi	sp,sp,-16
    80002afe:	e422                	sd	s0,8(sp)
    80002b00:	0800                	addi	s0,sp,16
  // 1. Allocate new page
  // 2. Copy contents from old to new
  // 3. Update page table entry
  // Ensure proper synchronization and error handling
  return 0; 
}
    80002b02:	4501                	li	a0,0
    80002b04:	6422                	ld	s0,8(sp)
    80002b06:	0141                	addi	sp,sp,16
    80002b08:	8082                	ret

0000000080002b0a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b0a:	1141                	addi	sp,sp,-16
    80002b0c:	e406                	sd	ra,8(sp)
    80002b0e:	e022                	sd	s0,0(sp)
    80002b10:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	15e080e7          	jalr	350(ra) # 80001c70 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b20:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b24:	00004697          	auipc	a3,0x4
    80002b28:	4dc68693          	addi	a3,a3,1244 # 80007000 <_trampoline>
    80002b2c:	00004717          	auipc	a4,0x4
    80002b30:	4d470713          	addi	a4,a4,1236 # 80007000 <_trampoline>
    80002b34:	8f15                	sub	a4,a4,a3
    80002b36:	040007b7          	lui	a5,0x4000
    80002b3a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b3c:	07b2                	slli	a5,a5,0xc
    80002b3e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b40:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b44:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b46:	18002673          	csrr	a2,satp
    80002b4a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b4c:	6d30                	ld	a2,88(a0)
    80002b4e:	6138                	ld	a4,64(a0)
    80002b50:	6585                	lui	a1,0x1
    80002b52:	972e                	add	a4,a4,a1
    80002b54:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b56:	6d38                	ld	a4,88(a0)
    80002b58:	00000617          	auipc	a2,0x0
    80002b5c:	13060613          	addi	a2,a2,304 # 80002c88 <usertrap>
    80002b60:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b62:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b64:	8612                	mv	a2,tp
    80002b66:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b68:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b6c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b70:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b74:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b78:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b7a:	6f18                	ld	a4,24(a4)
    80002b7c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b80:	6928                	ld	a0,80(a0)
    80002b82:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b84:	00004717          	auipc	a4,0x4
    80002b88:	51870713          	addi	a4,a4,1304 # 8000709c <userret>
    80002b8c:	8f15                	sub	a4,a4,a3
    80002b8e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b90:	577d                	li	a4,-1
    80002b92:	177e                	slli	a4,a4,0x3f
    80002b94:	8d59                	or	a0,a0,a4
    80002b96:	9782                	jalr	a5
}
    80002b98:	60a2                	ld	ra,8(sp)
    80002b9a:	6402                	ld	s0,0(sp)
    80002b9c:	0141                	addi	sp,sp,16
    80002b9e:	8082                	ret

0000000080002ba0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ba0:	1101                	addi	sp,sp,-32
    80002ba2:	ec06                	sd	ra,24(sp)
    80002ba4:	e822                	sd	s0,16(sp)
    80002ba6:	e426                	sd	s1,8(sp)
    80002ba8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002baa:	00034497          	auipc	s1,0x34
    80002bae:	f8648493          	addi	s1,s1,-122 # 80036b30 <tickslock>
    80002bb2:	8526                	mv	a0,s1
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	1ae080e7          	jalr	430(ra) # 80000d62 <acquire>
  ticks++;
    80002bbc:	00006517          	auipc	a0,0x6
    80002bc0:	ed450513          	addi	a0,a0,-300 # 80008a90 <ticks>
    80002bc4:	411c                	lw	a5,0(a0)
    80002bc6:	2785                	addiw	a5,a5,1
    80002bc8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	8a6080e7          	jalr	-1882(ra) # 80002470 <wakeup>
  release(&tickslock);
    80002bd2:	8526                	mv	a0,s1
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	242080e7          	jalr	578(ra) # 80000e16 <release>
}
    80002bdc:	60e2                	ld	ra,24(sp)
    80002bde:	6442                	ld	s0,16(sp)
    80002be0:	64a2                	ld	s1,8(sp)
    80002be2:	6105                	addi	sp,sp,32
    80002be4:	8082                	ret

0000000080002be6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002be6:	1101                	addi	sp,sp,-32
    80002be8:	ec06                	sd	ra,24(sp)
    80002bea:	e822                	sd	s0,16(sp)
    80002bec:	e426                	sd	s1,8(sp)
    80002bee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002bf4:	00074d63          	bltz	a4,80002c0e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002bf8:	57fd                	li	a5,-1
    80002bfa:	17fe                	slli	a5,a5,0x3f
    80002bfc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bfe:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c00:	06f70363          	beq	a4,a5,80002c66 <devintr+0x80>
  }
}
    80002c04:	60e2                	ld	ra,24(sp)
    80002c06:	6442                	ld	s0,16(sp)
    80002c08:	64a2                	ld	s1,8(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret
     (scause & 0xff) == 9){
    80002c0e:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002c12:	46a5                	li	a3,9
    80002c14:	fed792e3          	bne	a5,a3,80002bf8 <devintr+0x12>
    int irq = plic_claim();
    80002c18:	00003097          	auipc	ra,0x3
    80002c1c:	6f0080e7          	jalr	1776(ra) # 80006308 <plic_claim>
    80002c20:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c22:	47a9                	li	a5,10
    80002c24:	02f50763          	beq	a0,a5,80002c52 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c28:	4785                	li	a5,1
    80002c2a:	02f50963          	beq	a0,a5,80002c5c <devintr+0x76>
    return 1;
    80002c2e:	4505                	li	a0,1
    } else if(irq){
    80002c30:	d8f1                	beqz	s1,80002c04 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c32:	85a6                	mv	a1,s1
    80002c34:	00005517          	auipc	a0,0x5
    80002c38:	7dc50513          	addi	a0,a0,2012 # 80008410 <states.0+0x38>
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	960080e7          	jalr	-1696(ra) # 8000059c <printf>
      plic_complete(irq);
    80002c44:	8526                	mv	a0,s1
    80002c46:	00003097          	auipc	ra,0x3
    80002c4a:	6e6080e7          	jalr	1766(ra) # 8000632c <plic_complete>
    return 1;
    80002c4e:	4505                	li	a0,1
    80002c50:	bf55                	j	80002c04 <devintr+0x1e>
      uartintr();
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	d58080e7          	jalr	-680(ra) # 800009aa <uartintr>
    80002c5a:	b7ed                	j	80002c44 <devintr+0x5e>
      virtio_disk_intr();
    80002c5c:	00004097          	auipc	ra,0x4
    80002c60:	b98080e7          	jalr	-1128(ra) # 800067f4 <virtio_disk_intr>
    80002c64:	b7c5                	j	80002c44 <devintr+0x5e>
    if(cpuid() == 0){
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	fde080e7          	jalr	-34(ra) # 80001c44 <cpuid>
    80002c6e:	c901                	beqz	a0,80002c7e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c70:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c74:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c76:	14479073          	csrw	sip,a5
    return 2;
    80002c7a:	4509                	li	a0,2
    80002c7c:	b761                	j	80002c04 <devintr+0x1e>
      clockintr();
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	f22080e7          	jalr	-222(ra) # 80002ba0 <clockintr>
    80002c86:	b7ed                	j	80002c70 <devintr+0x8a>

0000000080002c88 <usertrap>:
{
    80002c88:	7139                	addi	sp,sp,-64
    80002c8a:	fc06                	sd	ra,56(sp)
    80002c8c:	f822                	sd	s0,48(sp)
    80002c8e:	f426                	sd	s1,40(sp)
    80002c90:	f04a                	sd	s2,32(sp)
    80002c92:	ec4e                	sd	s3,24(sp)
    80002c94:	e852                	sd	s4,16(sp)
    80002c96:	e456                	sd	s5,8(sp)
    80002c98:	e05a                	sd	s6,0(sp)
    80002c9a:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c9c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ca0:	1007f793          	andi	a5,a5,256
    80002ca4:	efb5                	bnez	a5,80002d20 <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ca6:	00003797          	auipc	a5,0x3
    80002caa:	55a78793          	addi	a5,a5,1370 # 80006200 <kernelvec>
    80002cae:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	fbe080e7          	jalr	-66(ra) # 80001c70 <myproc>
    80002cba:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002cbc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cbe:	14102773          	csrr	a4,sepc
    80002cc2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cc4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002cc8:	47a1                	li	a5,8
    80002cca:	06f70363          	beq	a4,a5,80002d30 <usertrap+0xa8>
  } else if((which_dev = devintr()) != 0){
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	f18080e7          	jalr	-232(ra) # 80002be6 <devintr>
    80002cd6:	892a                	mv	s2,a0
    80002cd8:	18051a63          	bnez	a0,80002e6c <usertrap+0x1e4>
    80002cdc:	14202773          	csrr	a4,scause
  } else if(r_scause()==0x000000000000000fL){
    80002ce0:	47bd                	li	a5,15
    80002ce2:	0af70563          	beq	a4,a5,80002d8c <usertrap+0x104>
    80002ce6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cea:	5890                	lw	a2,48(s1)
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	79450513          	addi	a0,a0,1940 # 80008480 <states.0+0xa8>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	8a8080e7          	jalr	-1880(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cfc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d00:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	7ac50513          	addi	a0,a0,1964 # 800084b0 <states.0+0xd8>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	890080e7          	jalr	-1904(ra) # 8000059c <printf>
    setkilled(p);
    80002d14:	8526                	mv	a0,s1
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	972080e7          	jalr	-1678(ra) # 80002688 <setkilled>
    80002d1e:	a825                	j	80002d56 <usertrap+0xce>
    panic("usertrap: not from user mode");
    80002d20:	00005517          	auipc	a0,0x5
    80002d24:	71050513          	addi	a0,a0,1808 # 80008430 <states.0+0x58>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	818080e7          	jalr	-2024(ra) # 80000540 <panic>
    if(killed(p))
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	984080e7          	jalr	-1660(ra) # 800026b4 <killed>
    80002d38:	e521                	bnez	a0,80002d80 <usertrap+0xf8>
    p->trapframe->epc += 4;
    80002d3a:	6cb8                	ld	a4,88(s1)
    80002d3c:	6f1c                	ld	a5,24(a4)
    80002d3e:	0791                	addi	a5,a5,4
    80002d40:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d4a:	10079073          	csrw	sstatus,a5
    syscall();
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	392080e7          	jalr	914(ra) # 800030e0 <syscall>
  if(killed(p))
    80002d56:	8526                	mv	a0,s1
    80002d58:	00000097          	auipc	ra,0x0
    80002d5c:	95c080e7          	jalr	-1700(ra) # 800026b4 <killed>
    80002d60:	10051d63          	bnez	a0,80002e7a <usertrap+0x1f2>
  usertrapret();
    80002d64:	00000097          	auipc	ra,0x0
    80002d68:	da6080e7          	jalr	-602(ra) # 80002b0a <usertrapret>
}
    80002d6c:	70e2                	ld	ra,56(sp)
    80002d6e:	7442                	ld	s0,48(sp)
    80002d70:	74a2                	ld	s1,40(sp)
    80002d72:	7902                	ld	s2,32(sp)
    80002d74:	69e2                	ld	s3,24(sp)
    80002d76:	6a42                	ld	s4,16(sp)
    80002d78:	6aa2                	ld	s5,8(sp)
    80002d7a:	6b02                	ld	s6,0(sp)
    80002d7c:	6121                	addi	sp,sp,64
    80002d7e:	8082                	ret
      exit(-1);
    80002d80:	557d                	li	a0,-1
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	7be080e7          	jalr	1982(ra) # 80002540 <exit>
    80002d8a:	bf45                	j	80002d3a <usertrap+0xb2>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d8c:	14302a73          	csrr	s4,stval
    uint64 base = PGROUNDDOWN(va);
    80002d90:	77fd                	lui	a5,0xfffff
    80002d92:	00fa7a33          	and	s4,s4,a5
    pagetable_t pagetable = p->pagetable;
    80002d96:	0504bb03          	ld	s6,80(s1)
    pte = walk(pagetable,base,0);
    80002d9a:	4601                	li	a2,0
    80002d9c:	85d2                	mv	a1,s4
    80002d9e:	855a                	mv	a0,s6
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	3a2080e7          	jalr	930(ra) # 80001142 <walk>
    80002da8:	8aaa                	mv	s5,a0
    uint64 PA = PTE2PA(*pte);
    80002daa:	00053903          	ld	s2,0(a0)
    80002dae:	00a95913          	srli	s2,s2,0xa
    80002db2:	0932                	slli	s2,s2,0xc
    if (PA==0)
    80002db4:	08090063          	beqz	s2,80002e34 <usertrap+0x1ac>
    if ((new_page = newkalloc())==0){
    80002db8:	ffffe097          	auipc	ra,0xffffe
    80002dbc:	e8a080e7          	jalr	-374(ra) # 80000c42 <newkalloc>
    80002dc0:	89aa                	mv	s3,a0
    80002dc2:	c149                	beqz	a0,80002e44 <usertrap+0x1bc>
    flags = PTE_FLAGS(*pte);
    80002dc4:	000aba83          	ld	s5,0(s5)
    80002dc8:	3ffafa93          	andi	s5,s5,1023
    memmove(new_page,(void *)PA, PGSIZE);
    80002dcc:	6605                	lui	a2,0x1
    80002dce:	85ca                	mv	a1,s2
    80002dd0:	854e                	mv	a0,s3
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	0e8080e7          	jalr	232(ra) # 80000eba <memmove>
    uvmunmap(pagetable, base, 1, 1);
    80002dda:	4685                	li	a3,1
    80002ddc:	4605                	li	a2,1
    80002dde:	85d2                	mv	a1,s4
    80002de0:	855a                	mv	a0,s6
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	60e080e7          	jalr	1550(ra) # 800013f0 <uvmunmap>
    if(mappages(pagetable, base, PGSIZE, (uint64)new_page, flags) != 0){
    80002dea:	004ae713          	ori	a4,s5,4
    80002dee:	86ce                	mv	a3,s3
    80002df0:	6605                	lui	a2,0x1
    80002df2:	85d2                	mv	a1,s4
    80002df4:	855a                	mv	a0,s6
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	434080e7          	jalr	1076(ra) # 8000122a <mappages>
    80002dfe:	dd21                	beqz	a0,80002d56 <usertrap+0xce>
      if (counter[((uint64)new_page-KERNBASE )/ PGSIZE]==0)
    80002e00:	800007b7          	lui	a5,0x80000
    80002e04:	97ce                	add	a5,a5,s3
    80002e06:	83b1                	srli	a5,a5,0xc
    80002e08:	078a                	slli	a5,a5,0x2
    80002e0a:	0000e717          	auipc	a4,0xe
    80002e0e:	ef670713          	addi	a4,a4,-266 # 80010d00 <counter>
    80002e12:	97ba                	add	a5,a5,a4
    80002e14:	439c                	lw	a5,0(a5)
    80002e16:	e7a9                	bnez	a5,80002e60 <usertrap+0x1d8>
        newkfree(new_page);
    80002e18:	854e                	mv	a0,s3
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	df4080e7          	jalr	-524(ra) # 80000c0e <newkfree>
      printf("SEAGFAULT\n");
    80002e22:	00005517          	auipc	a0,0x5
    80002e26:	64e50513          	addi	a0,a0,1614 # 80008470 <states.0+0x98>
    80002e2a:	ffffd097          	auipc	ra,0xffffd
    80002e2e:	772080e7          	jalr	1906(ra) # 8000059c <printf>
    80002e32:	b715                	j	80002d56 <usertrap+0xce>
      panic("uvmcopy: walkaddr failed\n");
    80002e34:	00005517          	auipc	a0,0x5
    80002e38:	61c50513          	addi	a0,a0,1564 # 80008450 <states.0+0x78>
    80002e3c:	ffffd097          	auipc	ra,0xffffd
    80002e40:	704080e7          	jalr	1796(ra) # 80000540 <panic>
          printf("SEAGFAULT\n");
    80002e44:	00005517          	auipc	a0,0x5
    80002e48:	62c50513          	addi	a0,a0,1580 # 80008470 <states.0+0x98>
    80002e4c:	ffffd097          	auipc	ra,0xffffd
    80002e50:	750080e7          	jalr	1872(ra) # 8000059c <printf>
          setkilled(p);
    80002e54:	8526                	mv	a0,s1
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	832080e7          	jalr	-1998(ra) # 80002688 <setkilled>
    80002e5e:	b79d                	j	80002dc4 <usertrap+0x13c>
        refdec((void *)PA);
    80002e60:	854a                	mv	a0,s2
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	e4a080e7          	jalr	-438(ra) # 80000cac <refdec>
    80002e6a:	bf65                	j	80002e22 <usertrap+0x19a>
  if(killed(p))
    80002e6c:	8526                	mv	a0,s1
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	846080e7          	jalr	-1978(ra) # 800026b4 <killed>
    80002e76:	c901                	beqz	a0,80002e86 <usertrap+0x1fe>
    80002e78:	a011                	j	80002e7c <usertrap+0x1f4>
    80002e7a:	4901                	li	s2,0
    exit(-1);
    80002e7c:	557d                	li	a0,-1
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	6c2080e7          	jalr	1730(ra) # 80002540 <exit>
  if(which_dev == 2)
    80002e86:	4789                	li	a5,2
    80002e88:	ecf91ee3          	bne	s2,a5,80002d64 <usertrap+0xdc>
    yield();
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	544080e7          	jalr	1348(ra) # 800023d0 <yield>
    80002e94:	bdc1                	j	80002d64 <usertrap+0xdc>

0000000080002e96 <kerneltrap>:
{
    80002e96:	7179                	addi	sp,sp,-48
    80002e98:	f406                	sd	ra,40(sp)
    80002e9a:	f022                	sd	s0,32(sp)
    80002e9c:	ec26                	sd	s1,24(sp)
    80002e9e:	e84a                	sd	s2,16(sp)
    80002ea0:	e44e                	sd	s3,8(sp)
    80002ea2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eac:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002eb0:	1004f793          	andi	a5,s1,256
    80002eb4:	cb85                	beqz	a5,80002ee4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eb6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002eba:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ebc:	ef85                	bnez	a5,80002ef4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	d28080e7          	jalr	-728(ra) # 80002be6 <devintr>
    80002ec6:	cd1d                	beqz	a0,80002f04 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ec8:	4789                	li	a5,2
    80002eca:	06f50a63          	beq	a0,a5,80002f3e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ece:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ed2:	10049073          	csrw	sstatus,s1
}
    80002ed6:	70a2                	ld	ra,40(sp)
    80002ed8:	7402                	ld	s0,32(sp)
    80002eda:	64e2                	ld	s1,24(sp)
    80002edc:	6942                	ld	s2,16(sp)
    80002ede:	69a2                	ld	s3,8(sp)
    80002ee0:	6145                	addi	sp,sp,48
    80002ee2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ee4:	00005517          	auipc	a0,0x5
    80002ee8:	5ec50513          	addi	a0,a0,1516 # 800084d0 <states.0+0xf8>
    80002eec:	ffffd097          	auipc	ra,0xffffd
    80002ef0:	654080e7          	jalr	1620(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ef4:	00005517          	auipc	a0,0x5
    80002ef8:	60450513          	addi	a0,a0,1540 # 800084f8 <states.0+0x120>
    80002efc:	ffffd097          	auipc	ra,0xffffd
    80002f00:	644080e7          	jalr	1604(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002f04:	85ce                	mv	a1,s3
    80002f06:	00005517          	auipc	a0,0x5
    80002f0a:	61250513          	addi	a0,a0,1554 # 80008518 <states.0+0x140>
    80002f0e:	ffffd097          	auipc	ra,0xffffd
    80002f12:	68e080e7          	jalr	1678(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f16:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f1a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f1e:	00005517          	auipc	a0,0x5
    80002f22:	60a50513          	addi	a0,a0,1546 # 80008528 <states.0+0x150>
    80002f26:	ffffd097          	auipc	ra,0xffffd
    80002f2a:	676080e7          	jalr	1654(ra) # 8000059c <printf>
    panic("kerneltrap");
    80002f2e:	00005517          	auipc	a0,0x5
    80002f32:	61250513          	addi	a0,a0,1554 # 80008540 <states.0+0x168>
    80002f36:	ffffd097          	auipc	ra,0xffffd
    80002f3a:	60a080e7          	jalr	1546(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	d32080e7          	jalr	-718(ra) # 80001c70 <myproc>
    80002f46:	d541                	beqz	a0,80002ece <kerneltrap+0x38>
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	d28080e7          	jalr	-728(ra) # 80001c70 <myproc>
    80002f50:	4d18                	lw	a4,24(a0)
    80002f52:	4791                	li	a5,4
    80002f54:	f6f71de3          	bne	a4,a5,80002ece <kerneltrap+0x38>
    yield();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	478080e7          	jalr	1144(ra) # 800023d0 <yield>
    80002f60:	b7bd                	j	80002ece <kerneltrap+0x38>

0000000080002f62 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f62:	1101                	addi	sp,sp,-32
    80002f64:	ec06                	sd	ra,24(sp)
    80002f66:	e822                	sd	s0,16(sp)
    80002f68:	e426                	sd	s1,8(sp)
    80002f6a:	1000                	addi	s0,sp,32
    80002f6c:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	d02080e7          	jalr	-766(ra) # 80001c70 <myproc>
    switch (n)
    80002f76:	4795                	li	a5,5
    80002f78:	0497e163          	bltu	a5,s1,80002fba <argraw+0x58>
    80002f7c:	048a                	slli	s1,s1,0x2
    80002f7e:	00005717          	auipc	a4,0x5
    80002f82:	5fa70713          	addi	a4,a4,1530 # 80008578 <states.0+0x1a0>
    80002f86:	94ba                	add	s1,s1,a4
    80002f88:	409c                	lw	a5,0(s1)
    80002f8a:	97ba                	add	a5,a5,a4
    80002f8c:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f8e:	6d3c                	ld	a5,88(a0)
    80002f90:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f92:	60e2                	ld	ra,24(sp)
    80002f94:	6442                	ld	s0,16(sp)
    80002f96:	64a2                	ld	s1,8(sp)
    80002f98:	6105                	addi	sp,sp,32
    80002f9a:	8082                	ret
        return p->trapframe->a1;
    80002f9c:	6d3c                	ld	a5,88(a0)
    80002f9e:	7fa8                	ld	a0,120(a5)
    80002fa0:	bfcd                	j	80002f92 <argraw+0x30>
        return p->trapframe->a2;
    80002fa2:	6d3c                	ld	a5,88(a0)
    80002fa4:	63c8                	ld	a0,128(a5)
    80002fa6:	b7f5                	j	80002f92 <argraw+0x30>
        return p->trapframe->a3;
    80002fa8:	6d3c                	ld	a5,88(a0)
    80002faa:	67c8                	ld	a0,136(a5)
    80002fac:	b7dd                	j	80002f92 <argraw+0x30>
        return p->trapframe->a4;
    80002fae:	6d3c                	ld	a5,88(a0)
    80002fb0:	6bc8                	ld	a0,144(a5)
    80002fb2:	b7c5                	j	80002f92 <argraw+0x30>
        return p->trapframe->a5;
    80002fb4:	6d3c                	ld	a5,88(a0)
    80002fb6:	6fc8                	ld	a0,152(a5)
    80002fb8:	bfe9                	j	80002f92 <argraw+0x30>
    panic("argraw");
    80002fba:	00005517          	auipc	a0,0x5
    80002fbe:	59650513          	addi	a0,a0,1430 # 80008550 <states.0+0x178>
    80002fc2:	ffffd097          	auipc	ra,0xffffd
    80002fc6:	57e080e7          	jalr	1406(ra) # 80000540 <panic>

0000000080002fca <fetchaddr>:
{
    80002fca:	1101                	addi	sp,sp,-32
    80002fcc:	ec06                	sd	ra,24(sp)
    80002fce:	e822                	sd	s0,16(sp)
    80002fd0:	e426                	sd	s1,8(sp)
    80002fd2:	e04a                	sd	s2,0(sp)
    80002fd4:	1000                	addi	s0,sp,32
    80002fd6:	84aa                	mv	s1,a0
    80002fd8:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	c96080e7          	jalr	-874(ra) # 80001c70 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002fe2:	653c                	ld	a5,72(a0)
    80002fe4:	02f4f863          	bgeu	s1,a5,80003014 <fetchaddr+0x4a>
    80002fe8:	00848713          	addi	a4,s1,8
    80002fec:	02e7e663          	bltu	a5,a4,80003018 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ff0:	46a1                	li	a3,8
    80002ff2:	8626                	mv	a2,s1
    80002ff4:	85ca                	mv	a1,s2
    80002ff6:	6928                	ld	a0,80(a0)
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	8c6080e7          	jalr	-1850(ra) # 800018be <copyin>
    80003000:	00a03533          	snez	a0,a0
    80003004:	40a00533          	neg	a0,a0
}
    80003008:	60e2                	ld	ra,24(sp)
    8000300a:	6442                	ld	s0,16(sp)
    8000300c:	64a2                	ld	s1,8(sp)
    8000300e:	6902                	ld	s2,0(sp)
    80003010:	6105                	addi	sp,sp,32
    80003012:	8082                	ret
        return -1;
    80003014:	557d                	li	a0,-1
    80003016:	bfcd                	j	80003008 <fetchaddr+0x3e>
    80003018:	557d                	li	a0,-1
    8000301a:	b7fd                	j	80003008 <fetchaddr+0x3e>

000000008000301c <fetchstr>:
{
    8000301c:	7179                	addi	sp,sp,-48
    8000301e:	f406                	sd	ra,40(sp)
    80003020:	f022                	sd	s0,32(sp)
    80003022:	ec26                	sd	s1,24(sp)
    80003024:	e84a                	sd	s2,16(sp)
    80003026:	e44e                	sd	s3,8(sp)
    80003028:	1800                	addi	s0,sp,48
    8000302a:	892a                	mv	s2,a0
    8000302c:	84ae                	mv	s1,a1
    8000302e:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	c40080e7          	jalr	-960(ra) # 80001c70 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003038:	86ce                	mv	a3,s3
    8000303a:	864a                	mv	a2,s2
    8000303c:	85a6                	mv	a1,s1
    8000303e:	6928                	ld	a0,80(a0)
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	90c080e7          	jalr	-1780(ra) # 8000194c <copyinstr>
    80003048:	00054e63          	bltz	a0,80003064 <fetchstr+0x48>
    return strlen(buf);
    8000304c:	8526                	mv	a0,s1
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	f8c080e7          	jalr	-116(ra) # 80000fda <strlen>
}
    80003056:	70a2                	ld	ra,40(sp)
    80003058:	7402                	ld	s0,32(sp)
    8000305a:	64e2                	ld	s1,24(sp)
    8000305c:	6942                	ld	s2,16(sp)
    8000305e:	69a2                	ld	s3,8(sp)
    80003060:	6145                	addi	sp,sp,48
    80003062:	8082                	ret
        return -1;
    80003064:	557d                	li	a0,-1
    80003066:	bfc5                	j	80003056 <fetchstr+0x3a>

0000000080003068 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	1000                	addi	s0,sp,32
    80003072:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003074:	00000097          	auipc	ra,0x0
    80003078:	eee080e7          	jalr	-274(ra) # 80002f62 <argraw>
    8000307c:	c088                	sw	a0,0(s1)
}
    8000307e:	60e2                	ld	ra,24(sp)
    80003080:	6442                	ld	s0,16(sp)
    80003082:	64a2                	ld	s1,8(sp)
    80003084:	6105                	addi	sp,sp,32
    80003086:	8082                	ret

0000000080003088 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
    80003092:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003094:	00000097          	auipc	ra,0x0
    80003098:	ece080e7          	jalr	-306(ra) # 80002f62 <argraw>
    8000309c:	e088                	sd	a0,0(s1)
}
    8000309e:	60e2                	ld	ra,24(sp)
    800030a0:	6442                	ld	s0,16(sp)
    800030a2:	64a2                	ld	s1,8(sp)
    800030a4:	6105                	addi	sp,sp,32
    800030a6:	8082                	ret

00000000800030a8 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800030a8:	7179                	addi	sp,sp,-48
    800030aa:	f406                	sd	ra,40(sp)
    800030ac:	f022                	sd	s0,32(sp)
    800030ae:	ec26                	sd	s1,24(sp)
    800030b0:	e84a                	sd	s2,16(sp)
    800030b2:	1800                	addi	s0,sp,48
    800030b4:	84ae                	mv	s1,a1
    800030b6:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    800030b8:	fd840593          	addi	a1,s0,-40
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	fcc080e7          	jalr	-52(ra) # 80003088 <argaddr>
    return fetchstr(addr, buf, max);
    800030c4:	864a                	mv	a2,s2
    800030c6:	85a6                	mv	a1,s1
    800030c8:	fd843503          	ld	a0,-40(s0)
    800030cc:	00000097          	auipc	ra,0x0
    800030d0:	f50080e7          	jalr	-176(ra) # 8000301c <fetchstr>
}
    800030d4:	70a2                	ld	ra,40(sp)
    800030d6:	7402                	ld	s0,32(sp)
    800030d8:	64e2                	ld	s1,24(sp)
    800030da:	6942                	ld	s2,16(sp)
    800030dc:	6145                	addi	sp,sp,48
    800030de:	8082                	ret

00000000800030e0 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    800030e0:	1101                	addi	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	e426                	sd	s1,8(sp)
    800030e8:	e04a                	sd	s2,0(sp)
    800030ea:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	b84080e7          	jalr	-1148(ra) # 80001c70 <myproc>
    800030f4:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800030f6:	05853903          	ld	s2,88(a0)
    800030fa:	0a893783          	ld	a5,168(s2)
    800030fe:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003102:	37fd                	addiw	a5,a5,-1 # 7fffffff <_entry-0x1>
    80003104:	4765                	li	a4,25
    80003106:	00f76f63          	bltu	a4,a5,80003124 <syscall+0x44>
    8000310a:	00369713          	slli	a4,a3,0x3
    8000310e:	00005797          	auipc	a5,0x5
    80003112:	48278793          	addi	a5,a5,1154 # 80008590 <syscalls>
    80003116:	97ba                	add	a5,a5,a4
    80003118:	639c                	ld	a5,0(a5)
    8000311a:	c789                	beqz	a5,80003124 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    8000311c:	9782                	jalr	a5
    8000311e:	06a93823          	sd	a0,112(s2)
    80003122:	a839                	j	80003140 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80003124:	15848613          	addi	a2,s1,344
    80003128:	588c                	lw	a1,48(s1)
    8000312a:	00005517          	auipc	a0,0x5
    8000312e:	42e50513          	addi	a0,a0,1070 # 80008558 <states.0+0x180>
    80003132:	ffffd097          	auipc	ra,0xffffd
    80003136:	46a080e7          	jalr	1130(ra) # 8000059c <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    8000313a:	6cbc                	ld	a5,88(s1)
    8000313c:	577d                	li	a4,-1
    8000313e:	fbb8                	sd	a4,112(a5)
    }
}
    80003140:	60e2                	ld	ra,24(sp)
    80003142:	6442                	ld	s0,16(sp)
    80003144:	64a2                	ld	s1,8(sp)
    80003146:	6902                	ld	s2,0(sp)
    80003148:	6105                	addi	sp,sp,32
    8000314a:	8082                	ret

000000008000314c <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    8000314c:	1101                	addi	sp,sp,-32
    8000314e:	ec06                	sd	ra,24(sp)
    80003150:	e822                	sd	s0,16(sp)
    80003152:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80003154:	fec40593          	addi	a1,s0,-20
    80003158:	4501                	li	a0,0
    8000315a:	00000097          	auipc	ra,0x0
    8000315e:	f0e080e7          	jalr	-242(ra) # 80003068 <argint>
    exit(n);
    80003162:	fec42503          	lw	a0,-20(s0)
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	3da080e7          	jalr	986(ra) # 80002540 <exit>
    return 0; // not reached
}
    8000316e:	4501                	li	a0,0
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret

0000000080003178 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003178:	1141                	addi	sp,sp,-16
    8000317a:	e406                	sd	ra,8(sp)
    8000317c:	e022                	sd	s0,0(sp)
    8000317e:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003180:	fffff097          	auipc	ra,0xfffff
    80003184:	af0080e7          	jalr	-1296(ra) # 80001c70 <myproc>
}
    80003188:	5908                	lw	a0,48(a0)
    8000318a:	60a2                	ld	ra,8(sp)
    8000318c:	6402                	ld	s0,0(sp)
    8000318e:	0141                	addi	sp,sp,16
    80003190:	8082                	ret

0000000080003192 <sys_fork>:

uint64
sys_fork(void)
{
    80003192:	1141                	addi	sp,sp,-16
    80003194:	e406                	sd	ra,8(sp)
    80003196:	e022                	sd	s0,0(sp)
    80003198:	0800                	addi	s0,sp,16
    return fork();
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	010080e7          	jalr	16(ra) # 800021aa <fork>
}
    800031a2:	60a2                	ld	ra,8(sp)
    800031a4:	6402                	ld	s0,0(sp)
    800031a6:	0141                	addi	sp,sp,16
    800031a8:	8082                	ret

00000000800031aa <sys_wait>:

uint64
sys_wait(void)
{
    800031aa:	1101                	addi	sp,sp,-32
    800031ac:	ec06                	sd	ra,24(sp)
    800031ae:	e822                	sd	s0,16(sp)
    800031b0:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    800031b2:	fe840593          	addi	a1,s0,-24
    800031b6:	4501                	li	a0,0
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	ed0080e7          	jalr	-304(ra) # 80003088 <argaddr>
    return wait(p);
    800031c0:	fe843503          	ld	a0,-24(s0)
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	522080e7          	jalr	1314(ra) # 800026e6 <wait>
}
    800031cc:	60e2                	ld	ra,24(sp)
    800031ce:	6442                	ld	s0,16(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret

00000000800031d4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031d4:	7179                	addi	sp,sp,-48
    800031d6:	f406                	sd	ra,40(sp)
    800031d8:	f022                	sd	s0,32(sp)
    800031da:	ec26                	sd	s1,24(sp)
    800031dc:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    800031de:	fdc40593          	addi	a1,s0,-36
    800031e2:	4501                	li	a0,0
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	e84080e7          	jalr	-380(ra) # 80003068 <argint>
    addr = myproc()->sz;
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	a84080e7          	jalr	-1404(ra) # 80001c70 <myproc>
    800031f4:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800031f6:	fdc42503          	lw	a0,-36(s0)
    800031fa:	fffff097          	auipc	ra,0xfffff
    800031fe:	dd0080e7          	jalr	-560(ra) # 80001fca <growproc>
    80003202:	00054863          	bltz	a0,80003212 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003206:	8526                	mv	a0,s1
    80003208:	70a2                	ld	ra,40(sp)
    8000320a:	7402                	ld	s0,32(sp)
    8000320c:	64e2                	ld	s1,24(sp)
    8000320e:	6145                	addi	sp,sp,48
    80003210:	8082                	ret
        return -1;
    80003212:	54fd                	li	s1,-1
    80003214:	bfcd                	j	80003206 <sys_sbrk+0x32>

0000000080003216 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003216:	7139                	addi	sp,sp,-64
    80003218:	fc06                	sd	ra,56(sp)
    8000321a:	f822                	sd	s0,48(sp)
    8000321c:	f426                	sd	s1,40(sp)
    8000321e:	f04a                	sd	s2,32(sp)
    80003220:	ec4e                	sd	s3,24(sp)
    80003222:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80003224:	fcc40593          	addi	a1,s0,-52
    80003228:	4501                	li	a0,0
    8000322a:	00000097          	auipc	ra,0x0
    8000322e:	e3e080e7          	jalr	-450(ra) # 80003068 <argint>
    acquire(&tickslock);
    80003232:	00034517          	auipc	a0,0x34
    80003236:	8fe50513          	addi	a0,a0,-1794 # 80036b30 <tickslock>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	b28080e7          	jalr	-1240(ra) # 80000d62 <acquire>
    ticks0 = ticks;
    80003242:	00006917          	auipc	s2,0x6
    80003246:	84e92903          	lw	s2,-1970(s2) # 80008a90 <ticks>
    while (ticks - ticks0 < n)
    8000324a:	fcc42783          	lw	a5,-52(s0)
    8000324e:	cf9d                	beqz	a5,8000328c <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003250:	00034997          	auipc	s3,0x34
    80003254:	8e098993          	addi	s3,s3,-1824 # 80036b30 <tickslock>
    80003258:	00006497          	auipc	s1,0x6
    8000325c:	83848493          	addi	s1,s1,-1992 # 80008a90 <ticks>
        if (killed(myproc()))
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	a10080e7          	jalr	-1520(ra) # 80001c70 <myproc>
    80003268:	fffff097          	auipc	ra,0xfffff
    8000326c:	44c080e7          	jalr	1100(ra) # 800026b4 <killed>
    80003270:	ed15                	bnez	a0,800032ac <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003272:	85ce                	mv	a1,s3
    80003274:	8526                	mv	a0,s1
    80003276:	fffff097          	auipc	ra,0xfffff
    8000327a:	196080e7          	jalr	406(ra) # 8000240c <sleep>
    while (ticks - ticks0 < n)
    8000327e:	409c                	lw	a5,0(s1)
    80003280:	412787bb          	subw	a5,a5,s2
    80003284:	fcc42703          	lw	a4,-52(s0)
    80003288:	fce7ece3          	bltu	a5,a4,80003260 <sys_sleep+0x4a>
    }
    release(&tickslock);
    8000328c:	00034517          	auipc	a0,0x34
    80003290:	8a450513          	addi	a0,a0,-1884 # 80036b30 <tickslock>
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	b82080e7          	jalr	-1150(ra) # 80000e16 <release>
    return 0;
    8000329c:	4501                	li	a0,0
}
    8000329e:	70e2                	ld	ra,56(sp)
    800032a0:	7442                	ld	s0,48(sp)
    800032a2:	74a2                	ld	s1,40(sp)
    800032a4:	7902                	ld	s2,32(sp)
    800032a6:	69e2                	ld	s3,24(sp)
    800032a8:	6121                	addi	sp,sp,64
    800032aa:	8082                	ret
            release(&tickslock);
    800032ac:	00034517          	auipc	a0,0x34
    800032b0:	88450513          	addi	a0,a0,-1916 # 80036b30 <tickslock>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	b62080e7          	jalr	-1182(ra) # 80000e16 <release>
            return -1;
    800032bc:	557d                	li	a0,-1
    800032be:	b7c5                	j	8000329e <sys_sleep+0x88>

00000000800032c0 <sys_kill>:

uint64
sys_kill(void)
{
    800032c0:	1101                	addi	sp,sp,-32
    800032c2:	ec06                	sd	ra,24(sp)
    800032c4:	e822                	sd	s0,16(sp)
    800032c6:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    800032c8:	fec40593          	addi	a1,s0,-20
    800032cc:	4501                	li	a0,0
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	d9a080e7          	jalr	-614(ra) # 80003068 <argint>
    return kill(pid);
    800032d6:	fec42503          	lw	a0,-20(s0)
    800032da:	fffff097          	auipc	ra,0xfffff
    800032de:	33c080e7          	jalr	828(ra) # 80002616 <kill>
}
    800032e2:	60e2                	ld	ra,24(sp)
    800032e4:	6442                	ld	s0,16(sp)
    800032e6:	6105                	addi	sp,sp,32
    800032e8:	8082                	ret

00000000800032ea <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	e426                	sd	s1,8(sp)
    800032f2:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800032f4:	00034517          	auipc	a0,0x34
    800032f8:	83c50513          	addi	a0,a0,-1988 # 80036b30 <tickslock>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	a66080e7          	jalr	-1434(ra) # 80000d62 <acquire>
    xticks = ticks;
    80003304:	00005497          	auipc	s1,0x5
    80003308:	78c4a483          	lw	s1,1932(s1) # 80008a90 <ticks>
    release(&tickslock);
    8000330c:	00034517          	auipc	a0,0x34
    80003310:	82450513          	addi	a0,a0,-2012 # 80036b30 <tickslock>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	b02080e7          	jalr	-1278(ra) # 80000e16 <release>
    return xticks;
}
    8000331c:	02049513          	slli	a0,s1,0x20
    80003320:	9101                	srli	a0,a0,0x20
    80003322:	60e2                	ld	ra,24(sp)
    80003324:	6442                	ld	s0,16(sp)
    80003326:	64a2                	ld	s1,8(sp)
    80003328:	6105                	addi	sp,sp,32
    8000332a:	8082                	ret

000000008000332c <sys_ps>:

void *
sys_ps(void)
{
    8000332c:	1101                	addi	sp,sp,-32
    8000332e:	ec06                	sd	ra,24(sp)
    80003330:	e822                	sd	s0,16(sp)
    80003332:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    80003334:	fe042623          	sw	zero,-20(s0)
    80003338:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    8000333c:	fec40593          	addi	a1,s0,-20
    80003340:	4501                	li	a0,0
    80003342:	00000097          	auipc	ra,0x0
    80003346:	d26080e7          	jalr	-730(ra) # 80003068 <argint>
    argint(1, &count);
    8000334a:	fe840593          	addi	a1,s0,-24
    8000334e:	4505                	li	a0,1
    80003350:	00000097          	auipc	ra,0x0
    80003354:	d18080e7          	jalr	-744(ra) # 80003068 <argint>
    return ps((uint8)start, (uint8)count);
    80003358:	fe844583          	lbu	a1,-24(s0)
    8000335c:	fec44503          	lbu	a0,-20(s0)
    80003360:	fffff097          	auipc	ra,0xfffff
    80003364:	cc6080e7          	jalr	-826(ra) # 80002026 <ps>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	6105                	addi	sp,sp,32
    8000336e:	8082                	ret

0000000080003370 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003370:	1141                	addi	sp,sp,-16
    80003372:	e406                	sd	ra,8(sp)
    80003374:	e022                	sd	s0,0(sp)
    80003376:	0800                	addi	s0,sp,16
    schedls();
    80003378:	fffff097          	auipc	ra,0xfffff
    8000337c:	5f8080e7          	jalr	1528(ra) # 80002970 <schedls>
    return 0;
}
    80003380:	4501                	li	a0,0
    80003382:	60a2                	ld	ra,8(sp)
    80003384:	6402                	ld	s0,0(sp)
    80003386:	0141                	addi	sp,sp,16
    80003388:	8082                	ret

000000008000338a <sys_schedset>:

uint64 sys_schedset(void)
{
    8000338a:	1101                	addi	sp,sp,-32
    8000338c:	ec06                	sd	ra,24(sp)
    8000338e:	e822                	sd	s0,16(sp)
    80003390:	1000                	addi	s0,sp,32
    int id = 0;
    80003392:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003396:	fec40593          	addi	a1,s0,-20
    8000339a:	4501                	li	a0,0
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	ccc080e7          	jalr	-820(ra) # 80003068 <argint>
    schedset(id - 1);
    800033a4:	fec42503          	lw	a0,-20(s0)
    800033a8:	357d                	addiw	a0,a0,-1
    800033aa:	fffff097          	auipc	ra,0xfffff
    800033ae:	65c080e7          	jalr	1628(ra) # 80002a06 <schedset>
    return 0;
}
    800033b2:	4501                	li	a0,0
    800033b4:	60e2                	ld	ra,24(sp)
    800033b6:	6442                	ld	s0,16(sp)
    800033b8:	6105                	addi	sp,sp,32
    800033ba:	8082                	ret

00000000800033bc <sys_va2pa>:
}*/

extern struct proc proc[NPROC];

uint64 sys_va2pa(void)
{
    800033bc:	1101                	addi	sp,sp,-32
    800033be:	ec06                	sd	ra,24(sp)
    800033c0:	e822                	sd	s0,16(sp)
    800033c2:	1000                	addi	s0,sp,32
    
    uint64 va; // Virtual address
    argaddr(0, &va);
    800033c4:	fe840593          	addi	a1,s0,-24
    800033c8:	4501                	li	a0,0
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	cbe080e7          	jalr	-834(ra) # 80003088 <argaddr>
    int pid = 0;   // Process ID get from args
    800033d2:	fe042223          	sw	zero,-28(s0)
    argint(1, &pid);
    800033d6:	fe440593          	addi	a1,s0,-28
    800033da:	4505                	li	a0,1
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	c8c080e7          	jalr	-884(ra) # 80003068 <argint>

    struct proc *target_proc = myproc(); // Default to current process
    800033e4:	fffff097          	auipc	ra,0xfffff
    800033e8:	88c080e7          	jalr	-1908(ra) # 80001c70 <myproc>

    if (pid != 0) { // If a specific PID is requested
    800033ec:	fe442703          	lw	a4,-28(s0)
    800033f0:	c31d                	beqz	a4,80003416 <sys_va2pa+0x5a>
        int found = 0;
        for(struct proc *p = proc; p < &proc[NPROC]; p++) {
    800033f2:	0002e517          	auipc	a0,0x2e
    800033f6:	d3e50513          	addi	a0,a0,-706 # 80031130 <proc>
    800033fa:	00033697          	auipc	a3,0x33
    800033fe:	73668693          	addi	a3,a3,1846 # 80036b30 <tickslock>
    80003402:	a029                	j	8000340c <sys_va2pa+0x50>
    80003404:	16850513          	addi	a0,a0,360
    80003408:	02d50f63          	beq	a0,a3,80003446 <sys_va2pa+0x8a>
            if(p->pid == pid && p->state != UNUSED) {
    8000340c:	591c                	lw	a5,48(a0)
    8000340e:	fee79be3          	bne	a5,a4,80003404 <sys_va2pa+0x48>
    80003412:	4d1c                	lw	a5,24(a0)
    80003414:	dbe5                	beqz	a5,80003404 <sys_va2pa+0x48>
            return 0; // PID not found, return 0
        }
    }

    // Walk the page table to find the physical address corresponding to the given virtual address
    pte_t *pte = walk(target_proc->pagetable, va, 0); // 0 to not create
    80003416:	4601                	li	a2,0
    80003418:	fe843583          	ld	a1,-24(s0)
    8000341c:	6928                	ld	a0,80(a0)
    8000341e:	ffffe097          	auipc	ra,0xffffe
    80003422:	d24080e7          	jalr	-732(ra) # 80001142 <walk>
    if(pte == 0 || (*pte & PTE_V) == 0) {
    80003426:	c115                	beqz	a0,8000344a <sys_va2pa+0x8e>
    80003428:	611c                	ld	a5,0(a0)
    8000342a:	0017f513          	andi	a0,a5,1
    8000342e:	c901                	beqz	a0,8000343e <sys_va2pa+0x82>
        return 0; // Virtual address not mapped
    }

    uint64 pa = PTE2PA(*pte) | (va & 0xFFF); // Extract physical address and add offset
    80003430:	83a9                	srli	a5,a5,0xa
    80003432:	07b2                	slli	a5,a5,0xc
    80003434:	fe843503          	ld	a0,-24(s0)
    80003438:	1552                	slli	a0,a0,0x34
    8000343a:	9151                	srli	a0,a0,0x34
    8000343c:	8d5d                	or	a0,a0,a5
    
    return pa;
}
    8000343e:	60e2                	ld	ra,24(sp)
    80003440:	6442                	ld	s0,16(sp)
    80003442:	6105                	addi	sp,sp,32
    80003444:	8082                	ret
            return 0; // PID not found, return 0
    80003446:	4501                	li	a0,0
    80003448:	bfdd                	j	8000343e <sys_va2pa+0x82>
        return 0; // Virtual address not mapped
    8000344a:	4501                	li	a0,0
    8000344c:	bfcd                	j	8000343e <sys_va2pa+0x82>

000000008000344e <sys_pfreepages>:


uint64 sys_pfreepages(void)
{
    8000344e:	1141                	addi	sp,sp,-16
    80003450:	e406                	sd	ra,8(sp)
    80003452:	e022                	sd	s0,0(sp)
    80003454:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    80003456:	00005597          	auipc	a1,0x5
    8000345a:	6125b583          	ld	a1,1554(a1) # 80008a68 <FREE_PAGES>
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	11250513          	addi	a0,a0,274 # 80008570 <states.0+0x198>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	136080e7          	jalr	310(ra) # 8000059c <printf>
    return 0;
    8000346e:	4501                	li	a0,0
    80003470:	60a2                	ld	ra,8(sp)
    80003472:	6402                	ld	s0,0(sp)
    80003474:	0141                	addi	sp,sp,16
    80003476:	8082                	ret

0000000080003478 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003478:	7179                	addi	sp,sp,-48
    8000347a:	f406                	sd	ra,40(sp)
    8000347c:	f022                	sd	s0,32(sp)
    8000347e:	ec26                	sd	s1,24(sp)
    80003480:	e84a                	sd	s2,16(sp)
    80003482:	e44e                	sd	s3,8(sp)
    80003484:	e052                	sd	s4,0(sp)
    80003486:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003488:	00005597          	auipc	a1,0x5
    8000348c:	1e058593          	addi	a1,a1,480 # 80008668 <syscalls+0xd8>
    80003490:	00033517          	auipc	a0,0x33
    80003494:	6b850513          	addi	a0,a0,1720 # 80036b48 <bcache>
    80003498:	ffffe097          	auipc	ra,0xffffe
    8000349c:	83a080e7          	jalr	-1990(ra) # 80000cd2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034a0:	0003b797          	auipc	a5,0x3b
    800034a4:	6a878793          	addi	a5,a5,1704 # 8003eb48 <bcache+0x8000>
    800034a8:	0003c717          	auipc	a4,0x3c
    800034ac:	90870713          	addi	a4,a4,-1784 # 8003edb0 <bcache+0x8268>
    800034b0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034b4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034b8:	00033497          	auipc	s1,0x33
    800034bc:	6a848493          	addi	s1,s1,1704 # 80036b60 <bcache+0x18>
    b->next = bcache.head.next;
    800034c0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034c2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034c4:	00005a17          	auipc	s4,0x5
    800034c8:	1aca0a13          	addi	s4,s4,428 # 80008670 <syscalls+0xe0>
    b->next = bcache.head.next;
    800034cc:	2b893783          	ld	a5,696(s2)
    800034d0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034d2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034d6:	85d2                	mv	a1,s4
    800034d8:	01048513          	addi	a0,s1,16
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	4c8080e7          	jalr	1224(ra) # 800049a4 <initsleeplock>
    bcache.head.next->prev = b;
    800034e4:	2b893783          	ld	a5,696(s2)
    800034e8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034ea:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ee:	45848493          	addi	s1,s1,1112
    800034f2:	fd349de3          	bne	s1,s3,800034cc <binit+0x54>
  }
}
    800034f6:	70a2                	ld	ra,40(sp)
    800034f8:	7402                	ld	s0,32(sp)
    800034fa:	64e2                	ld	s1,24(sp)
    800034fc:	6942                	ld	s2,16(sp)
    800034fe:	69a2                	ld	s3,8(sp)
    80003500:	6a02                	ld	s4,0(sp)
    80003502:	6145                	addi	sp,sp,48
    80003504:	8082                	ret

0000000080003506 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003506:	7179                	addi	sp,sp,-48
    80003508:	f406                	sd	ra,40(sp)
    8000350a:	f022                	sd	s0,32(sp)
    8000350c:	ec26                	sd	s1,24(sp)
    8000350e:	e84a                	sd	s2,16(sp)
    80003510:	e44e                	sd	s3,8(sp)
    80003512:	1800                	addi	s0,sp,48
    80003514:	892a                	mv	s2,a0
    80003516:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003518:	00033517          	auipc	a0,0x33
    8000351c:	63050513          	addi	a0,a0,1584 # 80036b48 <bcache>
    80003520:	ffffe097          	auipc	ra,0xffffe
    80003524:	842080e7          	jalr	-1982(ra) # 80000d62 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003528:	0003c497          	auipc	s1,0x3c
    8000352c:	8d84b483          	ld	s1,-1832(s1) # 8003ee00 <bcache+0x82b8>
    80003530:	0003c797          	auipc	a5,0x3c
    80003534:	88078793          	addi	a5,a5,-1920 # 8003edb0 <bcache+0x8268>
    80003538:	02f48f63          	beq	s1,a5,80003576 <bread+0x70>
    8000353c:	873e                	mv	a4,a5
    8000353e:	a021                	j	80003546 <bread+0x40>
    80003540:	68a4                	ld	s1,80(s1)
    80003542:	02e48a63          	beq	s1,a4,80003576 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003546:	449c                	lw	a5,8(s1)
    80003548:	ff279ce3          	bne	a5,s2,80003540 <bread+0x3a>
    8000354c:	44dc                	lw	a5,12(s1)
    8000354e:	ff3799e3          	bne	a5,s3,80003540 <bread+0x3a>
      b->refcnt++;
    80003552:	40bc                	lw	a5,64(s1)
    80003554:	2785                	addiw	a5,a5,1
    80003556:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003558:	00033517          	auipc	a0,0x33
    8000355c:	5f050513          	addi	a0,a0,1520 # 80036b48 <bcache>
    80003560:	ffffe097          	auipc	ra,0xffffe
    80003564:	8b6080e7          	jalr	-1866(ra) # 80000e16 <release>
      acquiresleep(&b->lock);
    80003568:	01048513          	addi	a0,s1,16
    8000356c:	00001097          	auipc	ra,0x1
    80003570:	472080e7          	jalr	1138(ra) # 800049de <acquiresleep>
      return b;
    80003574:	a8b9                	j	800035d2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003576:	0003c497          	auipc	s1,0x3c
    8000357a:	8824b483          	ld	s1,-1918(s1) # 8003edf8 <bcache+0x82b0>
    8000357e:	0003c797          	auipc	a5,0x3c
    80003582:	83278793          	addi	a5,a5,-1998 # 8003edb0 <bcache+0x8268>
    80003586:	00f48863          	beq	s1,a5,80003596 <bread+0x90>
    8000358a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000358c:	40bc                	lw	a5,64(s1)
    8000358e:	cf81                	beqz	a5,800035a6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003590:	64a4                	ld	s1,72(s1)
    80003592:	fee49de3          	bne	s1,a4,8000358c <bread+0x86>
  panic("bget: no buffers");
    80003596:	00005517          	auipc	a0,0x5
    8000359a:	0e250513          	addi	a0,a0,226 # 80008678 <syscalls+0xe8>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	fa2080e7          	jalr	-94(ra) # 80000540 <panic>
      b->dev = dev;
    800035a6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035aa:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035ae:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035b2:	4785                	li	a5,1
    800035b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035b6:	00033517          	auipc	a0,0x33
    800035ba:	59250513          	addi	a0,a0,1426 # 80036b48 <bcache>
    800035be:	ffffe097          	auipc	ra,0xffffe
    800035c2:	858080e7          	jalr	-1960(ra) # 80000e16 <release>
      acquiresleep(&b->lock);
    800035c6:	01048513          	addi	a0,s1,16
    800035ca:	00001097          	auipc	ra,0x1
    800035ce:	414080e7          	jalr	1044(ra) # 800049de <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035d2:	409c                	lw	a5,0(s1)
    800035d4:	cb89                	beqz	a5,800035e6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035d6:	8526                	mv	a0,s1
    800035d8:	70a2                	ld	ra,40(sp)
    800035da:	7402                	ld	s0,32(sp)
    800035dc:	64e2                	ld	s1,24(sp)
    800035de:	6942                	ld	s2,16(sp)
    800035e0:	69a2                	ld	s3,8(sp)
    800035e2:	6145                	addi	sp,sp,48
    800035e4:	8082                	ret
    virtio_disk_rw(b, 0);
    800035e6:	4581                	li	a1,0
    800035e8:	8526                	mv	a0,s1
    800035ea:	00003097          	auipc	ra,0x3
    800035ee:	fd8080e7          	jalr	-40(ra) # 800065c2 <virtio_disk_rw>
    b->valid = 1;
    800035f2:	4785                	li	a5,1
    800035f4:	c09c                	sw	a5,0(s1)
  return b;
    800035f6:	b7c5                	j	800035d6 <bread+0xd0>

00000000800035f8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035f8:	1101                	addi	sp,sp,-32
    800035fa:	ec06                	sd	ra,24(sp)
    800035fc:	e822                	sd	s0,16(sp)
    800035fe:	e426                	sd	s1,8(sp)
    80003600:	1000                	addi	s0,sp,32
    80003602:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003604:	0541                	addi	a0,a0,16
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	472080e7          	jalr	1138(ra) # 80004a78 <holdingsleep>
    8000360e:	cd01                	beqz	a0,80003626 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003610:	4585                	li	a1,1
    80003612:	8526                	mv	a0,s1
    80003614:	00003097          	auipc	ra,0x3
    80003618:	fae080e7          	jalr	-82(ra) # 800065c2 <virtio_disk_rw>
}
    8000361c:	60e2                	ld	ra,24(sp)
    8000361e:	6442                	ld	s0,16(sp)
    80003620:	64a2                	ld	s1,8(sp)
    80003622:	6105                	addi	sp,sp,32
    80003624:	8082                	ret
    panic("bwrite");
    80003626:	00005517          	auipc	a0,0x5
    8000362a:	06a50513          	addi	a0,a0,106 # 80008690 <syscalls+0x100>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	f12080e7          	jalr	-238(ra) # 80000540 <panic>

0000000080003636 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003636:	1101                	addi	sp,sp,-32
    80003638:	ec06                	sd	ra,24(sp)
    8000363a:	e822                	sd	s0,16(sp)
    8000363c:	e426                	sd	s1,8(sp)
    8000363e:	e04a                	sd	s2,0(sp)
    80003640:	1000                	addi	s0,sp,32
    80003642:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003644:	01050913          	addi	s2,a0,16
    80003648:	854a                	mv	a0,s2
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	42e080e7          	jalr	1070(ra) # 80004a78 <holdingsleep>
    80003652:	c92d                	beqz	a0,800036c4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003654:	854a                	mv	a0,s2
    80003656:	00001097          	auipc	ra,0x1
    8000365a:	3de080e7          	jalr	990(ra) # 80004a34 <releasesleep>

  acquire(&bcache.lock);
    8000365e:	00033517          	auipc	a0,0x33
    80003662:	4ea50513          	addi	a0,a0,1258 # 80036b48 <bcache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	6fc080e7          	jalr	1788(ra) # 80000d62 <acquire>
  b->refcnt--;
    8000366e:	40bc                	lw	a5,64(s1)
    80003670:	37fd                	addiw	a5,a5,-1
    80003672:	0007871b          	sext.w	a4,a5
    80003676:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003678:	eb05                	bnez	a4,800036a8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000367a:	68bc                	ld	a5,80(s1)
    8000367c:	64b8                	ld	a4,72(s1)
    8000367e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003680:	64bc                	ld	a5,72(s1)
    80003682:	68b8                	ld	a4,80(s1)
    80003684:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003686:	0003b797          	auipc	a5,0x3b
    8000368a:	4c278793          	addi	a5,a5,1218 # 8003eb48 <bcache+0x8000>
    8000368e:	2b87b703          	ld	a4,696(a5)
    80003692:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003694:	0003b717          	auipc	a4,0x3b
    80003698:	71c70713          	addi	a4,a4,1820 # 8003edb0 <bcache+0x8268>
    8000369c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000369e:	2b87b703          	ld	a4,696(a5)
    800036a2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036a4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036a8:	00033517          	auipc	a0,0x33
    800036ac:	4a050513          	addi	a0,a0,1184 # 80036b48 <bcache>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	766080e7          	jalr	1894(ra) # 80000e16 <release>
}
    800036b8:	60e2                	ld	ra,24(sp)
    800036ba:	6442                	ld	s0,16(sp)
    800036bc:	64a2                	ld	s1,8(sp)
    800036be:	6902                	ld	s2,0(sp)
    800036c0:	6105                	addi	sp,sp,32
    800036c2:	8082                	ret
    panic("brelse");
    800036c4:	00005517          	auipc	a0,0x5
    800036c8:	fd450513          	addi	a0,a0,-44 # 80008698 <syscalls+0x108>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	e74080e7          	jalr	-396(ra) # 80000540 <panic>

00000000800036d4 <bpin>:

void
bpin(struct buf *b) {
    800036d4:	1101                	addi	sp,sp,-32
    800036d6:	ec06                	sd	ra,24(sp)
    800036d8:	e822                	sd	s0,16(sp)
    800036da:	e426                	sd	s1,8(sp)
    800036dc:	1000                	addi	s0,sp,32
    800036de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e0:	00033517          	auipc	a0,0x33
    800036e4:	46850513          	addi	a0,a0,1128 # 80036b48 <bcache>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	67a080e7          	jalr	1658(ra) # 80000d62 <acquire>
  b->refcnt++;
    800036f0:	40bc                	lw	a5,64(s1)
    800036f2:	2785                	addiw	a5,a5,1
    800036f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036f6:	00033517          	auipc	a0,0x33
    800036fa:	45250513          	addi	a0,a0,1106 # 80036b48 <bcache>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	718080e7          	jalr	1816(ra) # 80000e16 <release>
}
    80003706:	60e2                	ld	ra,24(sp)
    80003708:	6442                	ld	s0,16(sp)
    8000370a:	64a2                	ld	s1,8(sp)
    8000370c:	6105                	addi	sp,sp,32
    8000370e:	8082                	ret

0000000080003710 <bunpin>:

void
bunpin(struct buf *b) {
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	1000                	addi	s0,sp,32
    8000371a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000371c:	00033517          	auipc	a0,0x33
    80003720:	42c50513          	addi	a0,a0,1068 # 80036b48 <bcache>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	63e080e7          	jalr	1598(ra) # 80000d62 <acquire>
  b->refcnt--;
    8000372c:	40bc                	lw	a5,64(s1)
    8000372e:	37fd                	addiw	a5,a5,-1
    80003730:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003732:	00033517          	auipc	a0,0x33
    80003736:	41650513          	addi	a0,a0,1046 # 80036b48 <bcache>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	6dc080e7          	jalr	1756(ra) # 80000e16 <release>
}
    80003742:	60e2                	ld	ra,24(sp)
    80003744:	6442                	ld	s0,16(sp)
    80003746:	64a2                	ld	s1,8(sp)
    80003748:	6105                	addi	sp,sp,32
    8000374a:	8082                	ret

000000008000374c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000374c:	1101                	addi	sp,sp,-32
    8000374e:	ec06                	sd	ra,24(sp)
    80003750:	e822                	sd	s0,16(sp)
    80003752:	e426                	sd	s1,8(sp)
    80003754:	e04a                	sd	s2,0(sp)
    80003756:	1000                	addi	s0,sp,32
    80003758:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000375a:	00d5d59b          	srliw	a1,a1,0xd
    8000375e:	0003c797          	auipc	a5,0x3c
    80003762:	ac67a783          	lw	a5,-1338(a5) # 8003f224 <sb+0x1c>
    80003766:	9dbd                	addw	a1,a1,a5
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	d9e080e7          	jalr	-610(ra) # 80003506 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003770:	0074f713          	andi	a4,s1,7
    80003774:	4785                	li	a5,1
    80003776:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000377a:	14ce                	slli	s1,s1,0x33
    8000377c:	90d9                	srli	s1,s1,0x36
    8000377e:	00950733          	add	a4,a0,s1
    80003782:	05874703          	lbu	a4,88(a4)
    80003786:	00e7f6b3          	and	a3,a5,a4
    8000378a:	c69d                	beqz	a3,800037b8 <bfree+0x6c>
    8000378c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000378e:	94aa                	add	s1,s1,a0
    80003790:	fff7c793          	not	a5,a5
    80003794:	8f7d                	and	a4,a4,a5
    80003796:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000379a:	00001097          	auipc	ra,0x1
    8000379e:	126080e7          	jalr	294(ra) # 800048c0 <log_write>
  brelse(bp);
    800037a2:	854a                	mv	a0,s2
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	e92080e7          	jalr	-366(ra) # 80003636 <brelse>
}
    800037ac:	60e2                	ld	ra,24(sp)
    800037ae:	6442                	ld	s0,16(sp)
    800037b0:	64a2                	ld	s1,8(sp)
    800037b2:	6902                	ld	s2,0(sp)
    800037b4:	6105                	addi	sp,sp,32
    800037b6:	8082                	ret
    panic("freeing free block");
    800037b8:	00005517          	auipc	a0,0x5
    800037bc:	ee850513          	addi	a0,a0,-280 # 800086a0 <syscalls+0x110>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	d80080e7          	jalr	-640(ra) # 80000540 <panic>

00000000800037c8 <balloc>:
{
    800037c8:	711d                	addi	sp,sp,-96
    800037ca:	ec86                	sd	ra,88(sp)
    800037cc:	e8a2                	sd	s0,80(sp)
    800037ce:	e4a6                	sd	s1,72(sp)
    800037d0:	e0ca                	sd	s2,64(sp)
    800037d2:	fc4e                	sd	s3,56(sp)
    800037d4:	f852                	sd	s4,48(sp)
    800037d6:	f456                	sd	s5,40(sp)
    800037d8:	f05a                	sd	s6,32(sp)
    800037da:	ec5e                	sd	s7,24(sp)
    800037dc:	e862                	sd	s8,16(sp)
    800037de:	e466                	sd	s9,8(sp)
    800037e0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037e2:	0003c797          	auipc	a5,0x3c
    800037e6:	a2a7a783          	lw	a5,-1494(a5) # 8003f20c <sb+0x4>
    800037ea:	cff5                	beqz	a5,800038e6 <balloc+0x11e>
    800037ec:	8baa                	mv	s7,a0
    800037ee:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037f0:	0003cb17          	auipc	s6,0x3c
    800037f4:	a18b0b13          	addi	s6,s6,-1512 # 8003f208 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037f8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037fa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037fc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037fe:	6c89                	lui	s9,0x2
    80003800:	a061                	j	80003888 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003802:	97ca                	add	a5,a5,s2
    80003804:	8e55                	or	a2,a2,a3
    80003806:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	0b4080e7          	jalr	180(ra) # 800048c0 <log_write>
        brelse(bp);
    80003814:	854a                	mv	a0,s2
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	e20080e7          	jalr	-480(ra) # 80003636 <brelse>
  bp = bread(dev, bno);
    8000381e:	85a6                	mv	a1,s1
    80003820:	855e                	mv	a0,s7
    80003822:	00000097          	auipc	ra,0x0
    80003826:	ce4080e7          	jalr	-796(ra) # 80003506 <bread>
    8000382a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000382c:	40000613          	li	a2,1024
    80003830:	4581                	li	a1,0
    80003832:	05850513          	addi	a0,a0,88
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	628080e7          	jalr	1576(ra) # 80000e5e <memset>
  log_write(bp);
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	080080e7          	jalr	128(ra) # 800048c0 <log_write>
  brelse(bp);
    80003848:	854a                	mv	a0,s2
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	dec080e7          	jalr	-532(ra) # 80003636 <brelse>
}
    80003852:	8526                	mv	a0,s1
    80003854:	60e6                	ld	ra,88(sp)
    80003856:	6446                	ld	s0,80(sp)
    80003858:	64a6                	ld	s1,72(sp)
    8000385a:	6906                	ld	s2,64(sp)
    8000385c:	79e2                	ld	s3,56(sp)
    8000385e:	7a42                	ld	s4,48(sp)
    80003860:	7aa2                	ld	s5,40(sp)
    80003862:	7b02                	ld	s6,32(sp)
    80003864:	6be2                	ld	s7,24(sp)
    80003866:	6c42                	ld	s8,16(sp)
    80003868:	6ca2                	ld	s9,8(sp)
    8000386a:	6125                	addi	sp,sp,96
    8000386c:	8082                	ret
    brelse(bp);
    8000386e:	854a                	mv	a0,s2
    80003870:	00000097          	auipc	ra,0x0
    80003874:	dc6080e7          	jalr	-570(ra) # 80003636 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003878:	015c87bb          	addw	a5,s9,s5
    8000387c:	00078a9b          	sext.w	s5,a5
    80003880:	004b2703          	lw	a4,4(s6)
    80003884:	06eaf163          	bgeu	s5,a4,800038e6 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003888:	41fad79b          	sraiw	a5,s5,0x1f
    8000388c:	0137d79b          	srliw	a5,a5,0x13
    80003890:	015787bb          	addw	a5,a5,s5
    80003894:	40d7d79b          	sraiw	a5,a5,0xd
    80003898:	01cb2583          	lw	a1,28(s6)
    8000389c:	9dbd                	addw	a1,a1,a5
    8000389e:	855e                	mv	a0,s7
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	c66080e7          	jalr	-922(ra) # 80003506 <bread>
    800038a8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038aa:	004b2503          	lw	a0,4(s6)
    800038ae:	000a849b          	sext.w	s1,s5
    800038b2:	8762                	mv	a4,s8
    800038b4:	faa4fde3          	bgeu	s1,a0,8000386e <balloc+0xa6>
      m = 1 << (bi % 8);
    800038b8:	00777693          	andi	a3,a4,7
    800038bc:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038c0:	41f7579b          	sraiw	a5,a4,0x1f
    800038c4:	01d7d79b          	srliw	a5,a5,0x1d
    800038c8:	9fb9                	addw	a5,a5,a4
    800038ca:	4037d79b          	sraiw	a5,a5,0x3
    800038ce:	00f90633          	add	a2,s2,a5
    800038d2:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800038d6:	00c6f5b3          	and	a1,a3,a2
    800038da:	d585                	beqz	a1,80003802 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038dc:	2705                	addiw	a4,a4,1
    800038de:	2485                	addiw	s1,s1,1
    800038e0:	fd471ae3          	bne	a4,s4,800038b4 <balloc+0xec>
    800038e4:	b769                	j	8000386e <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800038e6:	00005517          	auipc	a0,0x5
    800038ea:	dd250513          	addi	a0,a0,-558 # 800086b8 <syscalls+0x128>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	cae080e7          	jalr	-850(ra) # 8000059c <printf>
  return 0;
    800038f6:	4481                	li	s1,0
    800038f8:	bfa9                	j	80003852 <balloc+0x8a>

00000000800038fa <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800038fa:	7179                	addi	sp,sp,-48
    800038fc:	f406                	sd	ra,40(sp)
    800038fe:	f022                	sd	s0,32(sp)
    80003900:	ec26                	sd	s1,24(sp)
    80003902:	e84a                	sd	s2,16(sp)
    80003904:	e44e                	sd	s3,8(sp)
    80003906:	e052                	sd	s4,0(sp)
    80003908:	1800                	addi	s0,sp,48
    8000390a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000390c:	47ad                	li	a5,11
    8000390e:	02b7e863          	bltu	a5,a1,8000393e <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003912:	02059793          	slli	a5,a1,0x20
    80003916:	01e7d593          	srli	a1,a5,0x1e
    8000391a:	00b504b3          	add	s1,a0,a1
    8000391e:	0504a903          	lw	s2,80(s1)
    80003922:	06091e63          	bnez	s2,8000399e <bmap+0xa4>
      addr = balloc(ip->dev);
    80003926:	4108                	lw	a0,0(a0)
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	ea0080e7          	jalr	-352(ra) # 800037c8 <balloc>
    80003930:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003934:	06090563          	beqz	s2,8000399e <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003938:	0524a823          	sw	s2,80(s1)
    8000393c:	a08d                	j	8000399e <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000393e:	ff45849b          	addiw	s1,a1,-12
    80003942:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003946:	0ff00793          	li	a5,255
    8000394a:	08e7e563          	bltu	a5,a4,800039d4 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000394e:	08052903          	lw	s2,128(a0)
    80003952:	00091d63          	bnez	s2,8000396c <bmap+0x72>
      addr = balloc(ip->dev);
    80003956:	4108                	lw	a0,0(a0)
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	e70080e7          	jalr	-400(ra) # 800037c8 <balloc>
    80003960:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003964:	02090d63          	beqz	s2,8000399e <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003968:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000396c:	85ca                	mv	a1,s2
    8000396e:	0009a503          	lw	a0,0(s3)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	b94080e7          	jalr	-1132(ra) # 80003506 <bread>
    8000397a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000397c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003980:	02049713          	slli	a4,s1,0x20
    80003984:	01e75593          	srli	a1,a4,0x1e
    80003988:	00b784b3          	add	s1,a5,a1
    8000398c:	0004a903          	lw	s2,0(s1)
    80003990:	02090063          	beqz	s2,800039b0 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003994:	8552                	mv	a0,s4
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	ca0080e7          	jalr	-864(ra) # 80003636 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000399e:	854a                	mv	a0,s2
    800039a0:	70a2                	ld	ra,40(sp)
    800039a2:	7402                	ld	s0,32(sp)
    800039a4:	64e2                	ld	s1,24(sp)
    800039a6:	6942                	ld	s2,16(sp)
    800039a8:	69a2                	ld	s3,8(sp)
    800039aa:	6a02                	ld	s4,0(sp)
    800039ac:	6145                	addi	sp,sp,48
    800039ae:	8082                	ret
      addr = balloc(ip->dev);
    800039b0:	0009a503          	lw	a0,0(s3)
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	e14080e7          	jalr	-492(ra) # 800037c8 <balloc>
    800039bc:	0005091b          	sext.w	s2,a0
      if(addr){
    800039c0:	fc090ae3          	beqz	s2,80003994 <bmap+0x9a>
        a[bn] = addr;
    800039c4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039c8:	8552                	mv	a0,s4
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	ef6080e7          	jalr	-266(ra) # 800048c0 <log_write>
    800039d2:	b7c9                	j	80003994 <bmap+0x9a>
  panic("bmap: out of range");
    800039d4:	00005517          	auipc	a0,0x5
    800039d8:	cfc50513          	addi	a0,a0,-772 # 800086d0 <syscalls+0x140>
    800039dc:	ffffd097          	auipc	ra,0xffffd
    800039e0:	b64080e7          	jalr	-1180(ra) # 80000540 <panic>

00000000800039e4 <iget>:
{
    800039e4:	7179                	addi	sp,sp,-48
    800039e6:	f406                	sd	ra,40(sp)
    800039e8:	f022                	sd	s0,32(sp)
    800039ea:	ec26                	sd	s1,24(sp)
    800039ec:	e84a                	sd	s2,16(sp)
    800039ee:	e44e                	sd	s3,8(sp)
    800039f0:	e052                	sd	s4,0(sp)
    800039f2:	1800                	addi	s0,sp,48
    800039f4:	89aa                	mv	s3,a0
    800039f6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039f8:	0003c517          	auipc	a0,0x3c
    800039fc:	83050513          	addi	a0,a0,-2000 # 8003f228 <itable>
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	362080e7          	jalr	866(ra) # 80000d62 <acquire>
  empty = 0;
    80003a08:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a0a:	0003c497          	auipc	s1,0x3c
    80003a0e:	83648493          	addi	s1,s1,-1994 # 8003f240 <itable+0x18>
    80003a12:	0003d697          	auipc	a3,0x3d
    80003a16:	2be68693          	addi	a3,a3,702 # 80040cd0 <log>
    80003a1a:	a039                	j	80003a28 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a1c:	02090b63          	beqz	s2,80003a52 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a20:	08848493          	addi	s1,s1,136
    80003a24:	02d48a63          	beq	s1,a3,80003a58 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a28:	449c                	lw	a5,8(s1)
    80003a2a:	fef059e3          	blez	a5,80003a1c <iget+0x38>
    80003a2e:	4098                	lw	a4,0(s1)
    80003a30:	ff3716e3          	bne	a4,s3,80003a1c <iget+0x38>
    80003a34:	40d8                	lw	a4,4(s1)
    80003a36:	ff4713e3          	bne	a4,s4,80003a1c <iget+0x38>
      ip->ref++;
    80003a3a:	2785                	addiw	a5,a5,1
    80003a3c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a3e:	0003b517          	auipc	a0,0x3b
    80003a42:	7ea50513          	addi	a0,a0,2026 # 8003f228 <itable>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	3d0080e7          	jalr	976(ra) # 80000e16 <release>
      return ip;
    80003a4e:	8926                	mv	s2,s1
    80003a50:	a03d                	j	80003a7e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a52:	f7f9                	bnez	a5,80003a20 <iget+0x3c>
    80003a54:	8926                	mv	s2,s1
    80003a56:	b7e9                	j	80003a20 <iget+0x3c>
  if(empty == 0)
    80003a58:	02090c63          	beqz	s2,80003a90 <iget+0xac>
  ip->dev = dev;
    80003a5c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a60:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a64:	4785                	li	a5,1
    80003a66:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a6a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a6e:	0003b517          	auipc	a0,0x3b
    80003a72:	7ba50513          	addi	a0,a0,1978 # 8003f228 <itable>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	3a0080e7          	jalr	928(ra) # 80000e16 <release>
}
    80003a7e:	854a                	mv	a0,s2
    80003a80:	70a2                	ld	ra,40(sp)
    80003a82:	7402                	ld	s0,32(sp)
    80003a84:	64e2                	ld	s1,24(sp)
    80003a86:	6942                	ld	s2,16(sp)
    80003a88:	69a2                	ld	s3,8(sp)
    80003a8a:	6a02                	ld	s4,0(sp)
    80003a8c:	6145                	addi	sp,sp,48
    80003a8e:	8082                	ret
    panic("iget: no inodes");
    80003a90:	00005517          	auipc	a0,0x5
    80003a94:	c5850513          	addi	a0,a0,-936 # 800086e8 <syscalls+0x158>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	aa8080e7          	jalr	-1368(ra) # 80000540 <panic>

0000000080003aa0 <fsinit>:
fsinit(int dev) {
    80003aa0:	7179                	addi	sp,sp,-48
    80003aa2:	f406                	sd	ra,40(sp)
    80003aa4:	f022                	sd	s0,32(sp)
    80003aa6:	ec26                	sd	s1,24(sp)
    80003aa8:	e84a                	sd	s2,16(sp)
    80003aaa:	e44e                	sd	s3,8(sp)
    80003aac:	1800                	addi	s0,sp,48
    80003aae:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ab0:	4585                	li	a1,1
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	a54080e7          	jalr	-1452(ra) # 80003506 <bread>
    80003aba:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003abc:	0003b997          	auipc	s3,0x3b
    80003ac0:	74c98993          	addi	s3,s3,1868 # 8003f208 <sb>
    80003ac4:	02000613          	li	a2,32
    80003ac8:	05850593          	addi	a1,a0,88
    80003acc:	854e                	mv	a0,s3
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	3ec080e7          	jalr	1004(ra) # 80000eba <memmove>
  brelse(bp);
    80003ad6:	8526                	mv	a0,s1
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	b5e080e7          	jalr	-1186(ra) # 80003636 <brelse>
  if(sb.magic != FSMAGIC)
    80003ae0:	0009a703          	lw	a4,0(s3)
    80003ae4:	102037b7          	lui	a5,0x10203
    80003ae8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003aec:	02f71263          	bne	a4,a5,80003b10 <fsinit+0x70>
  initlog(dev, &sb);
    80003af0:	0003b597          	auipc	a1,0x3b
    80003af4:	71858593          	addi	a1,a1,1816 # 8003f208 <sb>
    80003af8:	854a                	mv	a0,s2
    80003afa:	00001097          	auipc	ra,0x1
    80003afe:	b4a080e7          	jalr	-1206(ra) # 80004644 <initlog>
}
    80003b02:	70a2                	ld	ra,40(sp)
    80003b04:	7402                	ld	s0,32(sp)
    80003b06:	64e2                	ld	s1,24(sp)
    80003b08:	6942                	ld	s2,16(sp)
    80003b0a:	69a2                	ld	s3,8(sp)
    80003b0c:	6145                	addi	sp,sp,48
    80003b0e:	8082                	ret
    panic("invalid file system");
    80003b10:	00005517          	auipc	a0,0x5
    80003b14:	be850513          	addi	a0,a0,-1048 # 800086f8 <syscalls+0x168>
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	a28080e7          	jalr	-1496(ra) # 80000540 <panic>

0000000080003b20 <iinit>:
{
    80003b20:	7179                	addi	sp,sp,-48
    80003b22:	f406                	sd	ra,40(sp)
    80003b24:	f022                	sd	s0,32(sp)
    80003b26:	ec26                	sd	s1,24(sp)
    80003b28:	e84a                	sd	s2,16(sp)
    80003b2a:	e44e                	sd	s3,8(sp)
    80003b2c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b2e:	00005597          	auipc	a1,0x5
    80003b32:	be258593          	addi	a1,a1,-1054 # 80008710 <syscalls+0x180>
    80003b36:	0003b517          	auipc	a0,0x3b
    80003b3a:	6f250513          	addi	a0,a0,1778 # 8003f228 <itable>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	194080e7          	jalr	404(ra) # 80000cd2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b46:	0003b497          	auipc	s1,0x3b
    80003b4a:	70a48493          	addi	s1,s1,1802 # 8003f250 <itable+0x28>
    80003b4e:	0003d997          	auipc	s3,0x3d
    80003b52:	19298993          	addi	s3,s3,402 # 80040ce0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b56:	00005917          	auipc	s2,0x5
    80003b5a:	bc290913          	addi	s2,s2,-1086 # 80008718 <syscalls+0x188>
    80003b5e:	85ca                	mv	a1,s2
    80003b60:	8526                	mv	a0,s1
    80003b62:	00001097          	auipc	ra,0x1
    80003b66:	e42080e7          	jalr	-446(ra) # 800049a4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b6a:	08848493          	addi	s1,s1,136
    80003b6e:	ff3498e3          	bne	s1,s3,80003b5e <iinit+0x3e>
}
    80003b72:	70a2                	ld	ra,40(sp)
    80003b74:	7402                	ld	s0,32(sp)
    80003b76:	64e2                	ld	s1,24(sp)
    80003b78:	6942                	ld	s2,16(sp)
    80003b7a:	69a2                	ld	s3,8(sp)
    80003b7c:	6145                	addi	sp,sp,48
    80003b7e:	8082                	ret

0000000080003b80 <ialloc>:
{
    80003b80:	715d                	addi	sp,sp,-80
    80003b82:	e486                	sd	ra,72(sp)
    80003b84:	e0a2                	sd	s0,64(sp)
    80003b86:	fc26                	sd	s1,56(sp)
    80003b88:	f84a                	sd	s2,48(sp)
    80003b8a:	f44e                	sd	s3,40(sp)
    80003b8c:	f052                	sd	s4,32(sp)
    80003b8e:	ec56                	sd	s5,24(sp)
    80003b90:	e85a                	sd	s6,16(sp)
    80003b92:	e45e                	sd	s7,8(sp)
    80003b94:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b96:	0003b717          	auipc	a4,0x3b
    80003b9a:	67e72703          	lw	a4,1662(a4) # 8003f214 <sb+0xc>
    80003b9e:	4785                	li	a5,1
    80003ba0:	04e7fa63          	bgeu	a5,a4,80003bf4 <ialloc+0x74>
    80003ba4:	8aaa                	mv	s5,a0
    80003ba6:	8bae                	mv	s7,a1
    80003ba8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003baa:	0003ba17          	auipc	s4,0x3b
    80003bae:	65ea0a13          	addi	s4,s4,1630 # 8003f208 <sb>
    80003bb2:	00048b1b          	sext.w	s6,s1
    80003bb6:	0044d593          	srli	a1,s1,0x4
    80003bba:	018a2783          	lw	a5,24(s4)
    80003bbe:	9dbd                	addw	a1,a1,a5
    80003bc0:	8556                	mv	a0,s5
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	944080e7          	jalr	-1724(ra) # 80003506 <bread>
    80003bca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bcc:	05850993          	addi	s3,a0,88
    80003bd0:	00f4f793          	andi	a5,s1,15
    80003bd4:	079a                	slli	a5,a5,0x6
    80003bd6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bd8:	00099783          	lh	a5,0(s3)
    80003bdc:	c3a1                	beqz	a5,80003c1c <ialloc+0x9c>
    brelse(bp);
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	a58080e7          	jalr	-1448(ra) # 80003636 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003be6:	0485                	addi	s1,s1,1
    80003be8:	00ca2703          	lw	a4,12(s4)
    80003bec:	0004879b          	sext.w	a5,s1
    80003bf0:	fce7e1e3          	bltu	a5,a4,80003bb2 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003bf4:	00005517          	auipc	a0,0x5
    80003bf8:	b2c50513          	addi	a0,a0,-1236 # 80008720 <syscalls+0x190>
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	9a0080e7          	jalr	-1632(ra) # 8000059c <printf>
  return 0;
    80003c04:	4501                	li	a0,0
}
    80003c06:	60a6                	ld	ra,72(sp)
    80003c08:	6406                	ld	s0,64(sp)
    80003c0a:	74e2                	ld	s1,56(sp)
    80003c0c:	7942                	ld	s2,48(sp)
    80003c0e:	79a2                	ld	s3,40(sp)
    80003c10:	7a02                	ld	s4,32(sp)
    80003c12:	6ae2                	ld	s5,24(sp)
    80003c14:	6b42                	ld	s6,16(sp)
    80003c16:	6ba2                	ld	s7,8(sp)
    80003c18:	6161                	addi	sp,sp,80
    80003c1a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c1c:	04000613          	li	a2,64
    80003c20:	4581                	li	a1,0
    80003c22:	854e                	mv	a0,s3
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	23a080e7          	jalr	570(ra) # 80000e5e <memset>
      dip->type = type;
    80003c2c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c30:	854a                	mv	a0,s2
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	c8e080e7          	jalr	-882(ra) # 800048c0 <log_write>
      brelse(bp);
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	9fa080e7          	jalr	-1542(ra) # 80003636 <brelse>
      return iget(dev, inum);
    80003c44:	85da                	mv	a1,s6
    80003c46:	8556                	mv	a0,s5
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	d9c080e7          	jalr	-612(ra) # 800039e4 <iget>
    80003c50:	bf5d                	j	80003c06 <ialloc+0x86>

0000000080003c52 <iupdate>:
{
    80003c52:	1101                	addi	sp,sp,-32
    80003c54:	ec06                	sd	ra,24(sp)
    80003c56:	e822                	sd	s0,16(sp)
    80003c58:	e426                	sd	s1,8(sp)
    80003c5a:	e04a                	sd	s2,0(sp)
    80003c5c:	1000                	addi	s0,sp,32
    80003c5e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c60:	415c                	lw	a5,4(a0)
    80003c62:	0047d79b          	srliw	a5,a5,0x4
    80003c66:	0003b597          	auipc	a1,0x3b
    80003c6a:	5ba5a583          	lw	a1,1466(a1) # 8003f220 <sb+0x18>
    80003c6e:	9dbd                	addw	a1,a1,a5
    80003c70:	4108                	lw	a0,0(a0)
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	894080e7          	jalr	-1900(ra) # 80003506 <bread>
    80003c7a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c7c:	05850793          	addi	a5,a0,88
    80003c80:	40d8                	lw	a4,4(s1)
    80003c82:	8b3d                	andi	a4,a4,15
    80003c84:	071a                	slli	a4,a4,0x6
    80003c86:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c88:	04449703          	lh	a4,68(s1)
    80003c8c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c90:	04649703          	lh	a4,70(s1)
    80003c94:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c98:	04849703          	lh	a4,72(s1)
    80003c9c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003ca0:	04a49703          	lh	a4,74(s1)
    80003ca4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003ca8:	44f8                	lw	a4,76(s1)
    80003caa:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cac:	03400613          	li	a2,52
    80003cb0:	05048593          	addi	a1,s1,80
    80003cb4:	00c78513          	addi	a0,a5,12
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	202080e7          	jalr	514(ra) # 80000eba <memmove>
  log_write(bp);
    80003cc0:	854a                	mv	a0,s2
    80003cc2:	00001097          	auipc	ra,0x1
    80003cc6:	bfe080e7          	jalr	-1026(ra) # 800048c0 <log_write>
  brelse(bp);
    80003cca:	854a                	mv	a0,s2
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	96a080e7          	jalr	-1686(ra) # 80003636 <brelse>
}
    80003cd4:	60e2                	ld	ra,24(sp)
    80003cd6:	6442                	ld	s0,16(sp)
    80003cd8:	64a2                	ld	s1,8(sp)
    80003cda:	6902                	ld	s2,0(sp)
    80003cdc:	6105                	addi	sp,sp,32
    80003cde:	8082                	ret

0000000080003ce0 <idup>:
{
    80003ce0:	1101                	addi	sp,sp,-32
    80003ce2:	ec06                	sd	ra,24(sp)
    80003ce4:	e822                	sd	s0,16(sp)
    80003ce6:	e426                	sd	s1,8(sp)
    80003ce8:	1000                	addi	s0,sp,32
    80003cea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cec:	0003b517          	auipc	a0,0x3b
    80003cf0:	53c50513          	addi	a0,a0,1340 # 8003f228 <itable>
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	06e080e7          	jalr	110(ra) # 80000d62 <acquire>
  ip->ref++;
    80003cfc:	449c                	lw	a5,8(s1)
    80003cfe:	2785                	addiw	a5,a5,1
    80003d00:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d02:	0003b517          	auipc	a0,0x3b
    80003d06:	52650513          	addi	a0,a0,1318 # 8003f228 <itable>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	10c080e7          	jalr	268(ra) # 80000e16 <release>
}
    80003d12:	8526                	mv	a0,s1
    80003d14:	60e2                	ld	ra,24(sp)
    80003d16:	6442                	ld	s0,16(sp)
    80003d18:	64a2                	ld	s1,8(sp)
    80003d1a:	6105                	addi	sp,sp,32
    80003d1c:	8082                	ret

0000000080003d1e <ilock>:
{
    80003d1e:	1101                	addi	sp,sp,-32
    80003d20:	ec06                	sd	ra,24(sp)
    80003d22:	e822                	sd	s0,16(sp)
    80003d24:	e426                	sd	s1,8(sp)
    80003d26:	e04a                	sd	s2,0(sp)
    80003d28:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d2a:	c115                	beqz	a0,80003d4e <ilock+0x30>
    80003d2c:	84aa                	mv	s1,a0
    80003d2e:	451c                	lw	a5,8(a0)
    80003d30:	00f05f63          	blez	a5,80003d4e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d34:	0541                	addi	a0,a0,16
    80003d36:	00001097          	auipc	ra,0x1
    80003d3a:	ca8080e7          	jalr	-856(ra) # 800049de <acquiresleep>
  if(ip->valid == 0){
    80003d3e:	40bc                	lw	a5,64(s1)
    80003d40:	cf99                	beqz	a5,80003d5e <ilock+0x40>
}
    80003d42:	60e2                	ld	ra,24(sp)
    80003d44:	6442                	ld	s0,16(sp)
    80003d46:	64a2                	ld	s1,8(sp)
    80003d48:	6902                	ld	s2,0(sp)
    80003d4a:	6105                	addi	sp,sp,32
    80003d4c:	8082                	ret
    panic("ilock");
    80003d4e:	00005517          	auipc	a0,0x5
    80003d52:	9ea50513          	addi	a0,a0,-1558 # 80008738 <syscalls+0x1a8>
    80003d56:	ffffc097          	auipc	ra,0xffffc
    80003d5a:	7ea080e7          	jalr	2026(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d5e:	40dc                	lw	a5,4(s1)
    80003d60:	0047d79b          	srliw	a5,a5,0x4
    80003d64:	0003b597          	auipc	a1,0x3b
    80003d68:	4bc5a583          	lw	a1,1212(a1) # 8003f220 <sb+0x18>
    80003d6c:	9dbd                	addw	a1,a1,a5
    80003d6e:	4088                	lw	a0,0(s1)
    80003d70:	fffff097          	auipc	ra,0xfffff
    80003d74:	796080e7          	jalr	1942(ra) # 80003506 <bread>
    80003d78:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d7a:	05850593          	addi	a1,a0,88
    80003d7e:	40dc                	lw	a5,4(s1)
    80003d80:	8bbd                	andi	a5,a5,15
    80003d82:	079a                	slli	a5,a5,0x6
    80003d84:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d86:	00059783          	lh	a5,0(a1)
    80003d8a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d8e:	00259783          	lh	a5,2(a1)
    80003d92:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d96:	00459783          	lh	a5,4(a1)
    80003d9a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d9e:	00659783          	lh	a5,6(a1)
    80003da2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003da6:	459c                	lw	a5,8(a1)
    80003da8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003daa:	03400613          	li	a2,52
    80003dae:	05b1                	addi	a1,a1,12
    80003db0:	05048513          	addi	a0,s1,80
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	106080e7          	jalr	262(ra) # 80000eba <memmove>
    brelse(bp);
    80003dbc:	854a                	mv	a0,s2
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	878080e7          	jalr	-1928(ra) # 80003636 <brelse>
    ip->valid = 1;
    80003dc6:	4785                	li	a5,1
    80003dc8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dca:	04449783          	lh	a5,68(s1)
    80003dce:	fbb5                	bnez	a5,80003d42 <ilock+0x24>
      panic("ilock: no type");
    80003dd0:	00005517          	auipc	a0,0x5
    80003dd4:	97050513          	addi	a0,a0,-1680 # 80008740 <syscalls+0x1b0>
    80003dd8:	ffffc097          	auipc	ra,0xffffc
    80003ddc:	768080e7          	jalr	1896(ra) # 80000540 <panic>

0000000080003de0 <iunlock>:
{
    80003de0:	1101                	addi	sp,sp,-32
    80003de2:	ec06                	sd	ra,24(sp)
    80003de4:	e822                	sd	s0,16(sp)
    80003de6:	e426                	sd	s1,8(sp)
    80003de8:	e04a                	sd	s2,0(sp)
    80003dea:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dec:	c905                	beqz	a0,80003e1c <iunlock+0x3c>
    80003dee:	84aa                	mv	s1,a0
    80003df0:	01050913          	addi	s2,a0,16
    80003df4:	854a                	mv	a0,s2
    80003df6:	00001097          	auipc	ra,0x1
    80003dfa:	c82080e7          	jalr	-894(ra) # 80004a78 <holdingsleep>
    80003dfe:	cd19                	beqz	a0,80003e1c <iunlock+0x3c>
    80003e00:	449c                	lw	a5,8(s1)
    80003e02:	00f05d63          	blez	a5,80003e1c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e06:	854a                	mv	a0,s2
    80003e08:	00001097          	auipc	ra,0x1
    80003e0c:	c2c080e7          	jalr	-980(ra) # 80004a34 <releasesleep>
}
    80003e10:	60e2                	ld	ra,24(sp)
    80003e12:	6442                	ld	s0,16(sp)
    80003e14:	64a2                	ld	s1,8(sp)
    80003e16:	6902                	ld	s2,0(sp)
    80003e18:	6105                	addi	sp,sp,32
    80003e1a:	8082                	ret
    panic("iunlock");
    80003e1c:	00005517          	auipc	a0,0x5
    80003e20:	93450513          	addi	a0,a0,-1740 # 80008750 <syscalls+0x1c0>
    80003e24:	ffffc097          	auipc	ra,0xffffc
    80003e28:	71c080e7          	jalr	1820(ra) # 80000540 <panic>

0000000080003e2c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e2c:	7179                	addi	sp,sp,-48
    80003e2e:	f406                	sd	ra,40(sp)
    80003e30:	f022                	sd	s0,32(sp)
    80003e32:	ec26                	sd	s1,24(sp)
    80003e34:	e84a                	sd	s2,16(sp)
    80003e36:	e44e                	sd	s3,8(sp)
    80003e38:	e052                	sd	s4,0(sp)
    80003e3a:	1800                	addi	s0,sp,48
    80003e3c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e3e:	05050493          	addi	s1,a0,80
    80003e42:	08050913          	addi	s2,a0,128
    80003e46:	a021                	j	80003e4e <itrunc+0x22>
    80003e48:	0491                	addi	s1,s1,4
    80003e4a:	01248d63          	beq	s1,s2,80003e64 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e4e:	408c                	lw	a1,0(s1)
    80003e50:	dde5                	beqz	a1,80003e48 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e52:	0009a503          	lw	a0,0(s3)
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	8f6080e7          	jalr	-1802(ra) # 8000374c <bfree>
      ip->addrs[i] = 0;
    80003e5e:	0004a023          	sw	zero,0(s1)
    80003e62:	b7dd                	j	80003e48 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e64:	0809a583          	lw	a1,128(s3)
    80003e68:	e185                	bnez	a1,80003e88 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e6a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e6e:	854e                	mv	a0,s3
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	de2080e7          	jalr	-542(ra) # 80003c52 <iupdate>
}
    80003e78:	70a2                	ld	ra,40(sp)
    80003e7a:	7402                	ld	s0,32(sp)
    80003e7c:	64e2                	ld	s1,24(sp)
    80003e7e:	6942                	ld	s2,16(sp)
    80003e80:	69a2                	ld	s3,8(sp)
    80003e82:	6a02                	ld	s4,0(sp)
    80003e84:	6145                	addi	sp,sp,48
    80003e86:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e88:	0009a503          	lw	a0,0(s3)
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	67a080e7          	jalr	1658(ra) # 80003506 <bread>
    80003e94:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e96:	05850493          	addi	s1,a0,88
    80003e9a:	45850913          	addi	s2,a0,1112
    80003e9e:	a021                	j	80003ea6 <itrunc+0x7a>
    80003ea0:	0491                	addi	s1,s1,4
    80003ea2:	01248b63          	beq	s1,s2,80003eb8 <itrunc+0x8c>
      if(a[j])
    80003ea6:	408c                	lw	a1,0(s1)
    80003ea8:	dde5                	beqz	a1,80003ea0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003eaa:	0009a503          	lw	a0,0(s3)
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	89e080e7          	jalr	-1890(ra) # 8000374c <bfree>
    80003eb6:	b7ed                	j	80003ea0 <itrunc+0x74>
    brelse(bp);
    80003eb8:	8552                	mv	a0,s4
    80003eba:	fffff097          	auipc	ra,0xfffff
    80003ebe:	77c080e7          	jalr	1916(ra) # 80003636 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ec2:	0809a583          	lw	a1,128(s3)
    80003ec6:	0009a503          	lw	a0,0(s3)
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	882080e7          	jalr	-1918(ra) # 8000374c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ed2:	0809a023          	sw	zero,128(s3)
    80003ed6:	bf51                	j	80003e6a <itrunc+0x3e>

0000000080003ed8 <iput>:
{
    80003ed8:	1101                	addi	sp,sp,-32
    80003eda:	ec06                	sd	ra,24(sp)
    80003edc:	e822                	sd	s0,16(sp)
    80003ede:	e426                	sd	s1,8(sp)
    80003ee0:	e04a                	sd	s2,0(sp)
    80003ee2:	1000                	addi	s0,sp,32
    80003ee4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ee6:	0003b517          	auipc	a0,0x3b
    80003eea:	34250513          	addi	a0,a0,834 # 8003f228 <itable>
    80003eee:	ffffd097          	auipc	ra,0xffffd
    80003ef2:	e74080e7          	jalr	-396(ra) # 80000d62 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ef6:	4498                	lw	a4,8(s1)
    80003ef8:	4785                	li	a5,1
    80003efa:	02f70363          	beq	a4,a5,80003f20 <iput+0x48>
  ip->ref--;
    80003efe:	449c                	lw	a5,8(s1)
    80003f00:	37fd                	addiw	a5,a5,-1
    80003f02:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f04:	0003b517          	auipc	a0,0x3b
    80003f08:	32450513          	addi	a0,a0,804 # 8003f228 <itable>
    80003f0c:	ffffd097          	auipc	ra,0xffffd
    80003f10:	f0a080e7          	jalr	-246(ra) # 80000e16 <release>
}
    80003f14:	60e2                	ld	ra,24(sp)
    80003f16:	6442                	ld	s0,16(sp)
    80003f18:	64a2                	ld	s1,8(sp)
    80003f1a:	6902                	ld	s2,0(sp)
    80003f1c:	6105                	addi	sp,sp,32
    80003f1e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f20:	40bc                	lw	a5,64(s1)
    80003f22:	dff1                	beqz	a5,80003efe <iput+0x26>
    80003f24:	04a49783          	lh	a5,74(s1)
    80003f28:	fbf9                	bnez	a5,80003efe <iput+0x26>
    acquiresleep(&ip->lock);
    80003f2a:	01048913          	addi	s2,s1,16
    80003f2e:	854a                	mv	a0,s2
    80003f30:	00001097          	auipc	ra,0x1
    80003f34:	aae080e7          	jalr	-1362(ra) # 800049de <acquiresleep>
    release(&itable.lock);
    80003f38:	0003b517          	auipc	a0,0x3b
    80003f3c:	2f050513          	addi	a0,a0,752 # 8003f228 <itable>
    80003f40:	ffffd097          	auipc	ra,0xffffd
    80003f44:	ed6080e7          	jalr	-298(ra) # 80000e16 <release>
    itrunc(ip);
    80003f48:	8526                	mv	a0,s1
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	ee2080e7          	jalr	-286(ra) # 80003e2c <itrunc>
    ip->type = 0;
    80003f52:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f56:	8526                	mv	a0,s1
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	cfa080e7          	jalr	-774(ra) # 80003c52 <iupdate>
    ip->valid = 0;
    80003f60:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f64:	854a                	mv	a0,s2
    80003f66:	00001097          	auipc	ra,0x1
    80003f6a:	ace080e7          	jalr	-1330(ra) # 80004a34 <releasesleep>
    acquire(&itable.lock);
    80003f6e:	0003b517          	auipc	a0,0x3b
    80003f72:	2ba50513          	addi	a0,a0,698 # 8003f228 <itable>
    80003f76:	ffffd097          	auipc	ra,0xffffd
    80003f7a:	dec080e7          	jalr	-532(ra) # 80000d62 <acquire>
    80003f7e:	b741                	j	80003efe <iput+0x26>

0000000080003f80 <iunlockput>:
{
    80003f80:	1101                	addi	sp,sp,-32
    80003f82:	ec06                	sd	ra,24(sp)
    80003f84:	e822                	sd	s0,16(sp)
    80003f86:	e426                	sd	s1,8(sp)
    80003f88:	1000                	addi	s0,sp,32
    80003f8a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	e54080e7          	jalr	-428(ra) # 80003de0 <iunlock>
  iput(ip);
    80003f94:	8526                	mv	a0,s1
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	f42080e7          	jalr	-190(ra) # 80003ed8 <iput>
}
    80003f9e:	60e2                	ld	ra,24(sp)
    80003fa0:	6442                	ld	s0,16(sp)
    80003fa2:	64a2                	ld	s1,8(sp)
    80003fa4:	6105                	addi	sp,sp,32
    80003fa6:	8082                	ret

0000000080003fa8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fa8:	1141                	addi	sp,sp,-16
    80003faa:	e422                	sd	s0,8(sp)
    80003fac:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fae:	411c                	lw	a5,0(a0)
    80003fb0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fb2:	415c                	lw	a5,4(a0)
    80003fb4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fb6:	04451783          	lh	a5,68(a0)
    80003fba:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fbe:	04a51783          	lh	a5,74(a0)
    80003fc2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fc6:	04c56783          	lwu	a5,76(a0)
    80003fca:	e99c                	sd	a5,16(a1)
}
    80003fcc:	6422                	ld	s0,8(sp)
    80003fce:	0141                	addi	sp,sp,16
    80003fd0:	8082                	ret

0000000080003fd2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fd2:	457c                	lw	a5,76(a0)
    80003fd4:	0ed7e963          	bltu	a5,a3,800040c6 <readi+0xf4>
{
    80003fd8:	7159                	addi	sp,sp,-112
    80003fda:	f486                	sd	ra,104(sp)
    80003fdc:	f0a2                	sd	s0,96(sp)
    80003fde:	eca6                	sd	s1,88(sp)
    80003fe0:	e8ca                	sd	s2,80(sp)
    80003fe2:	e4ce                	sd	s3,72(sp)
    80003fe4:	e0d2                	sd	s4,64(sp)
    80003fe6:	fc56                	sd	s5,56(sp)
    80003fe8:	f85a                	sd	s6,48(sp)
    80003fea:	f45e                	sd	s7,40(sp)
    80003fec:	f062                	sd	s8,32(sp)
    80003fee:	ec66                	sd	s9,24(sp)
    80003ff0:	e86a                	sd	s10,16(sp)
    80003ff2:	e46e                	sd	s11,8(sp)
    80003ff4:	1880                	addi	s0,sp,112
    80003ff6:	8b2a                	mv	s6,a0
    80003ff8:	8bae                	mv	s7,a1
    80003ffa:	8a32                	mv	s4,a2
    80003ffc:	84b6                	mv	s1,a3
    80003ffe:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004000:	9f35                	addw	a4,a4,a3
    return 0;
    80004002:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004004:	0ad76063          	bltu	a4,a3,800040a4 <readi+0xd2>
  if(off + n > ip->size)
    80004008:	00e7f463          	bgeu	a5,a4,80004010 <readi+0x3e>
    n = ip->size - off;
    8000400c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004010:	0a0a8963          	beqz	s5,800040c2 <readi+0xf0>
    80004014:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004016:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000401a:	5c7d                	li	s8,-1
    8000401c:	a82d                	j	80004056 <readi+0x84>
    8000401e:	020d1d93          	slli	s11,s10,0x20
    80004022:	020ddd93          	srli	s11,s11,0x20
    80004026:	05890613          	addi	a2,s2,88
    8000402a:	86ee                	mv	a3,s11
    8000402c:	963a                	add	a2,a2,a4
    8000402e:	85d2                	mv	a1,s4
    80004030:	855e                	mv	a0,s7
    80004032:	ffffe097          	auipc	ra,0xffffe
    80004036:	7e2080e7          	jalr	2018(ra) # 80002814 <either_copyout>
    8000403a:	05850d63          	beq	a0,s8,80004094 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000403e:	854a                	mv	a0,s2
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	5f6080e7          	jalr	1526(ra) # 80003636 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004048:	013d09bb          	addw	s3,s10,s3
    8000404c:	009d04bb          	addw	s1,s10,s1
    80004050:	9a6e                	add	s4,s4,s11
    80004052:	0559f763          	bgeu	s3,s5,800040a0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004056:	00a4d59b          	srliw	a1,s1,0xa
    8000405a:	855a                	mv	a0,s6
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	89e080e7          	jalr	-1890(ra) # 800038fa <bmap>
    80004064:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004068:	cd85                	beqz	a1,800040a0 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000406a:	000b2503          	lw	a0,0(s6)
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	498080e7          	jalr	1176(ra) # 80003506 <bread>
    80004076:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004078:	3ff4f713          	andi	a4,s1,1023
    8000407c:	40ec87bb          	subw	a5,s9,a4
    80004080:	413a86bb          	subw	a3,s5,s3
    80004084:	8d3e                	mv	s10,a5
    80004086:	2781                	sext.w	a5,a5
    80004088:	0006861b          	sext.w	a2,a3
    8000408c:	f8f679e3          	bgeu	a2,a5,8000401e <readi+0x4c>
    80004090:	8d36                	mv	s10,a3
    80004092:	b771                	j	8000401e <readi+0x4c>
      brelse(bp);
    80004094:	854a                	mv	a0,s2
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	5a0080e7          	jalr	1440(ra) # 80003636 <brelse>
      tot = -1;
    8000409e:	59fd                	li	s3,-1
  }
  return tot;
    800040a0:	0009851b          	sext.w	a0,s3
}
    800040a4:	70a6                	ld	ra,104(sp)
    800040a6:	7406                	ld	s0,96(sp)
    800040a8:	64e6                	ld	s1,88(sp)
    800040aa:	6946                	ld	s2,80(sp)
    800040ac:	69a6                	ld	s3,72(sp)
    800040ae:	6a06                	ld	s4,64(sp)
    800040b0:	7ae2                	ld	s5,56(sp)
    800040b2:	7b42                	ld	s6,48(sp)
    800040b4:	7ba2                	ld	s7,40(sp)
    800040b6:	7c02                	ld	s8,32(sp)
    800040b8:	6ce2                	ld	s9,24(sp)
    800040ba:	6d42                	ld	s10,16(sp)
    800040bc:	6da2                	ld	s11,8(sp)
    800040be:	6165                	addi	sp,sp,112
    800040c0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040c2:	89d6                	mv	s3,s5
    800040c4:	bff1                	j	800040a0 <readi+0xce>
    return 0;
    800040c6:	4501                	li	a0,0
}
    800040c8:	8082                	ret

00000000800040ca <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040ca:	457c                	lw	a5,76(a0)
    800040cc:	10d7e863          	bltu	a5,a3,800041dc <writei+0x112>
{
    800040d0:	7159                	addi	sp,sp,-112
    800040d2:	f486                	sd	ra,104(sp)
    800040d4:	f0a2                	sd	s0,96(sp)
    800040d6:	eca6                	sd	s1,88(sp)
    800040d8:	e8ca                	sd	s2,80(sp)
    800040da:	e4ce                	sd	s3,72(sp)
    800040dc:	e0d2                	sd	s4,64(sp)
    800040de:	fc56                	sd	s5,56(sp)
    800040e0:	f85a                	sd	s6,48(sp)
    800040e2:	f45e                	sd	s7,40(sp)
    800040e4:	f062                	sd	s8,32(sp)
    800040e6:	ec66                	sd	s9,24(sp)
    800040e8:	e86a                	sd	s10,16(sp)
    800040ea:	e46e                	sd	s11,8(sp)
    800040ec:	1880                	addi	s0,sp,112
    800040ee:	8aaa                	mv	s5,a0
    800040f0:	8bae                	mv	s7,a1
    800040f2:	8a32                	mv	s4,a2
    800040f4:	8936                	mv	s2,a3
    800040f6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040f8:	00e687bb          	addw	a5,a3,a4
    800040fc:	0ed7e263          	bltu	a5,a3,800041e0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004100:	00043737          	lui	a4,0x43
    80004104:	0ef76063          	bltu	a4,a5,800041e4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004108:	0c0b0863          	beqz	s6,800041d8 <writei+0x10e>
    8000410c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000410e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004112:	5c7d                	li	s8,-1
    80004114:	a091                	j	80004158 <writei+0x8e>
    80004116:	020d1d93          	slli	s11,s10,0x20
    8000411a:	020ddd93          	srli	s11,s11,0x20
    8000411e:	05848513          	addi	a0,s1,88
    80004122:	86ee                	mv	a3,s11
    80004124:	8652                	mv	a2,s4
    80004126:	85de                	mv	a1,s7
    80004128:	953a                	add	a0,a0,a4
    8000412a:	ffffe097          	auipc	ra,0xffffe
    8000412e:	740080e7          	jalr	1856(ra) # 8000286a <either_copyin>
    80004132:	07850263          	beq	a0,s8,80004196 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004136:	8526                	mv	a0,s1
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	788080e7          	jalr	1928(ra) # 800048c0 <log_write>
    brelse(bp);
    80004140:	8526                	mv	a0,s1
    80004142:	fffff097          	auipc	ra,0xfffff
    80004146:	4f4080e7          	jalr	1268(ra) # 80003636 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000414a:	013d09bb          	addw	s3,s10,s3
    8000414e:	012d093b          	addw	s2,s10,s2
    80004152:	9a6e                	add	s4,s4,s11
    80004154:	0569f663          	bgeu	s3,s6,800041a0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004158:	00a9559b          	srliw	a1,s2,0xa
    8000415c:	8556                	mv	a0,s5
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	79c080e7          	jalr	1948(ra) # 800038fa <bmap>
    80004166:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000416a:	c99d                	beqz	a1,800041a0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000416c:	000aa503          	lw	a0,0(s5)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	396080e7          	jalr	918(ra) # 80003506 <bread>
    80004178:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000417a:	3ff97713          	andi	a4,s2,1023
    8000417e:	40ec87bb          	subw	a5,s9,a4
    80004182:	413b06bb          	subw	a3,s6,s3
    80004186:	8d3e                	mv	s10,a5
    80004188:	2781                	sext.w	a5,a5
    8000418a:	0006861b          	sext.w	a2,a3
    8000418e:	f8f674e3          	bgeu	a2,a5,80004116 <writei+0x4c>
    80004192:	8d36                	mv	s10,a3
    80004194:	b749                	j	80004116 <writei+0x4c>
      brelse(bp);
    80004196:	8526                	mv	a0,s1
    80004198:	fffff097          	auipc	ra,0xfffff
    8000419c:	49e080e7          	jalr	1182(ra) # 80003636 <brelse>
  }

  if(off > ip->size)
    800041a0:	04caa783          	lw	a5,76(s5)
    800041a4:	0127f463          	bgeu	a5,s2,800041ac <writei+0xe2>
    ip->size = off;
    800041a8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041ac:	8556                	mv	a0,s5
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	aa4080e7          	jalr	-1372(ra) # 80003c52 <iupdate>

  return tot;
    800041b6:	0009851b          	sext.w	a0,s3
}
    800041ba:	70a6                	ld	ra,104(sp)
    800041bc:	7406                	ld	s0,96(sp)
    800041be:	64e6                	ld	s1,88(sp)
    800041c0:	6946                	ld	s2,80(sp)
    800041c2:	69a6                	ld	s3,72(sp)
    800041c4:	6a06                	ld	s4,64(sp)
    800041c6:	7ae2                	ld	s5,56(sp)
    800041c8:	7b42                	ld	s6,48(sp)
    800041ca:	7ba2                	ld	s7,40(sp)
    800041cc:	7c02                	ld	s8,32(sp)
    800041ce:	6ce2                	ld	s9,24(sp)
    800041d0:	6d42                	ld	s10,16(sp)
    800041d2:	6da2                	ld	s11,8(sp)
    800041d4:	6165                	addi	sp,sp,112
    800041d6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041d8:	89da                	mv	s3,s6
    800041da:	bfc9                	j	800041ac <writei+0xe2>
    return -1;
    800041dc:	557d                	li	a0,-1
}
    800041de:	8082                	ret
    return -1;
    800041e0:	557d                	li	a0,-1
    800041e2:	bfe1                	j	800041ba <writei+0xf0>
    return -1;
    800041e4:	557d                	li	a0,-1
    800041e6:	bfd1                	j	800041ba <writei+0xf0>

00000000800041e8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041e8:	1141                	addi	sp,sp,-16
    800041ea:	e406                	sd	ra,8(sp)
    800041ec:	e022                	sd	s0,0(sp)
    800041ee:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041f0:	4639                	li	a2,14
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	d3c080e7          	jalr	-708(ra) # 80000f2e <strncmp>
}
    800041fa:	60a2                	ld	ra,8(sp)
    800041fc:	6402                	ld	s0,0(sp)
    800041fe:	0141                	addi	sp,sp,16
    80004200:	8082                	ret

0000000080004202 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004202:	7139                	addi	sp,sp,-64
    80004204:	fc06                	sd	ra,56(sp)
    80004206:	f822                	sd	s0,48(sp)
    80004208:	f426                	sd	s1,40(sp)
    8000420a:	f04a                	sd	s2,32(sp)
    8000420c:	ec4e                	sd	s3,24(sp)
    8000420e:	e852                	sd	s4,16(sp)
    80004210:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004212:	04451703          	lh	a4,68(a0)
    80004216:	4785                	li	a5,1
    80004218:	00f71a63          	bne	a4,a5,8000422c <dirlookup+0x2a>
    8000421c:	892a                	mv	s2,a0
    8000421e:	89ae                	mv	s3,a1
    80004220:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004222:	457c                	lw	a5,76(a0)
    80004224:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004226:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004228:	e79d                	bnez	a5,80004256 <dirlookup+0x54>
    8000422a:	a8a5                	j	800042a2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000422c:	00004517          	auipc	a0,0x4
    80004230:	52c50513          	addi	a0,a0,1324 # 80008758 <syscalls+0x1c8>
    80004234:	ffffc097          	auipc	ra,0xffffc
    80004238:	30c080e7          	jalr	780(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000423c:	00004517          	auipc	a0,0x4
    80004240:	53450513          	addi	a0,a0,1332 # 80008770 <syscalls+0x1e0>
    80004244:	ffffc097          	auipc	ra,0xffffc
    80004248:	2fc080e7          	jalr	764(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000424c:	24c1                	addiw	s1,s1,16
    8000424e:	04c92783          	lw	a5,76(s2)
    80004252:	04f4f763          	bgeu	s1,a5,800042a0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004256:	4741                	li	a4,16
    80004258:	86a6                	mv	a3,s1
    8000425a:	fc040613          	addi	a2,s0,-64
    8000425e:	4581                	li	a1,0
    80004260:	854a                	mv	a0,s2
    80004262:	00000097          	auipc	ra,0x0
    80004266:	d70080e7          	jalr	-656(ra) # 80003fd2 <readi>
    8000426a:	47c1                	li	a5,16
    8000426c:	fcf518e3          	bne	a0,a5,8000423c <dirlookup+0x3a>
    if(de.inum == 0)
    80004270:	fc045783          	lhu	a5,-64(s0)
    80004274:	dfe1                	beqz	a5,8000424c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004276:	fc240593          	addi	a1,s0,-62
    8000427a:	854e                	mv	a0,s3
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	f6c080e7          	jalr	-148(ra) # 800041e8 <namecmp>
    80004284:	f561                	bnez	a0,8000424c <dirlookup+0x4a>
      if(poff)
    80004286:	000a0463          	beqz	s4,8000428e <dirlookup+0x8c>
        *poff = off;
    8000428a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000428e:	fc045583          	lhu	a1,-64(s0)
    80004292:	00092503          	lw	a0,0(s2)
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	74e080e7          	jalr	1870(ra) # 800039e4 <iget>
    8000429e:	a011                	j	800042a2 <dirlookup+0xa0>
  return 0;
    800042a0:	4501                	li	a0,0
}
    800042a2:	70e2                	ld	ra,56(sp)
    800042a4:	7442                	ld	s0,48(sp)
    800042a6:	74a2                	ld	s1,40(sp)
    800042a8:	7902                	ld	s2,32(sp)
    800042aa:	69e2                	ld	s3,24(sp)
    800042ac:	6a42                	ld	s4,16(sp)
    800042ae:	6121                	addi	sp,sp,64
    800042b0:	8082                	ret

00000000800042b2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042b2:	711d                	addi	sp,sp,-96
    800042b4:	ec86                	sd	ra,88(sp)
    800042b6:	e8a2                	sd	s0,80(sp)
    800042b8:	e4a6                	sd	s1,72(sp)
    800042ba:	e0ca                	sd	s2,64(sp)
    800042bc:	fc4e                	sd	s3,56(sp)
    800042be:	f852                	sd	s4,48(sp)
    800042c0:	f456                	sd	s5,40(sp)
    800042c2:	f05a                	sd	s6,32(sp)
    800042c4:	ec5e                	sd	s7,24(sp)
    800042c6:	e862                	sd	s8,16(sp)
    800042c8:	e466                	sd	s9,8(sp)
    800042ca:	e06a                	sd	s10,0(sp)
    800042cc:	1080                	addi	s0,sp,96
    800042ce:	84aa                	mv	s1,a0
    800042d0:	8b2e                	mv	s6,a1
    800042d2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042d4:	00054703          	lbu	a4,0(a0)
    800042d8:	02f00793          	li	a5,47
    800042dc:	02f70363          	beq	a4,a5,80004302 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042e0:	ffffe097          	auipc	ra,0xffffe
    800042e4:	990080e7          	jalr	-1648(ra) # 80001c70 <myproc>
    800042e8:	15053503          	ld	a0,336(a0)
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	9f4080e7          	jalr	-1548(ra) # 80003ce0 <idup>
    800042f4:	8a2a                	mv	s4,a0
  while(*path == '/')
    800042f6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800042fa:	4cb5                	li	s9,13
  len = path - s;
    800042fc:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042fe:	4c05                	li	s8,1
    80004300:	a87d                	j	800043be <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004302:	4585                	li	a1,1
    80004304:	4505                	li	a0,1
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	6de080e7          	jalr	1758(ra) # 800039e4 <iget>
    8000430e:	8a2a                	mv	s4,a0
    80004310:	b7dd                	j	800042f6 <namex+0x44>
      iunlockput(ip);
    80004312:	8552                	mv	a0,s4
    80004314:	00000097          	auipc	ra,0x0
    80004318:	c6c080e7          	jalr	-916(ra) # 80003f80 <iunlockput>
      return 0;
    8000431c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000431e:	8552                	mv	a0,s4
    80004320:	60e6                	ld	ra,88(sp)
    80004322:	6446                	ld	s0,80(sp)
    80004324:	64a6                	ld	s1,72(sp)
    80004326:	6906                	ld	s2,64(sp)
    80004328:	79e2                	ld	s3,56(sp)
    8000432a:	7a42                	ld	s4,48(sp)
    8000432c:	7aa2                	ld	s5,40(sp)
    8000432e:	7b02                	ld	s6,32(sp)
    80004330:	6be2                	ld	s7,24(sp)
    80004332:	6c42                	ld	s8,16(sp)
    80004334:	6ca2                	ld	s9,8(sp)
    80004336:	6d02                	ld	s10,0(sp)
    80004338:	6125                	addi	sp,sp,96
    8000433a:	8082                	ret
      iunlock(ip);
    8000433c:	8552                	mv	a0,s4
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	aa2080e7          	jalr	-1374(ra) # 80003de0 <iunlock>
      return ip;
    80004346:	bfe1                	j	8000431e <namex+0x6c>
      iunlockput(ip);
    80004348:	8552                	mv	a0,s4
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	c36080e7          	jalr	-970(ra) # 80003f80 <iunlockput>
      return 0;
    80004352:	8a4e                	mv	s4,s3
    80004354:	b7e9                	j	8000431e <namex+0x6c>
  len = path - s;
    80004356:	40998633          	sub	a2,s3,s1
    8000435a:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000435e:	09acd863          	bge	s9,s10,800043ee <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004362:	4639                	li	a2,14
    80004364:	85a6                	mv	a1,s1
    80004366:	8556                	mv	a0,s5
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	b52080e7          	jalr	-1198(ra) # 80000eba <memmove>
    80004370:	84ce                	mv	s1,s3
  while(*path == '/')
    80004372:	0004c783          	lbu	a5,0(s1)
    80004376:	01279763          	bne	a5,s2,80004384 <namex+0xd2>
    path++;
    8000437a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000437c:	0004c783          	lbu	a5,0(s1)
    80004380:	ff278de3          	beq	a5,s2,8000437a <namex+0xc8>
    ilock(ip);
    80004384:	8552                	mv	a0,s4
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	998080e7          	jalr	-1640(ra) # 80003d1e <ilock>
    if(ip->type != T_DIR){
    8000438e:	044a1783          	lh	a5,68(s4)
    80004392:	f98790e3          	bne	a5,s8,80004312 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004396:	000b0563          	beqz	s6,800043a0 <namex+0xee>
    8000439a:	0004c783          	lbu	a5,0(s1)
    8000439e:	dfd9                	beqz	a5,8000433c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043a0:	865e                	mv	a2,s7
    800043a2:	85d6                	mv	a1,s5
    800043a4:	8552                	mv	a0,s4
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	e5c080e7          	jalr	-420(ra) # 80004202 <dirlookup>
    800043ae:	89aa                	mv	s3,a0
    800043b0:	dd41                	beqz	a0,80004348 <namex+0x96>
    iunlockput(ip);
    800043b2:	8552                	mv	a0,s4
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	bcc080e7          	jalr	-1076(ra) # 80003f80 <iunlockput>
    ip = next;
    800043bc:	8a4e                	mv	s4,s3
  while(*path == '/')
    800043be:	0004c783          	lbu	a5,0(s1)
    800043c2:	01279763          	bne	a5,s2,800043d0 <namex+0x11e>
    path++;
    800043c6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043c8:	0004c783          	lbu	a5,0(s1)
    800043cc:	ff278de3          	beq	a5,s2,800043c6 <namex+0x114>
  if(*path == 0)
    800043d0:	cb9d                	beqz	a5,80004406 <namex+0x154>
  while(*path != '/' && *path != 0)
    800043d2:	0004c783          	lbu	a5,0(s1)
    800043d6:	89a6                	mv	s3,s1
  len = path - s;
    800043d8:	8d5e                	mv	s10,s7
    800043da:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043dc:	01278963          	beq	a5,s2,800043ee <namex+0x13c>
    800043e0:	dbbd                	beqz	a5,80004356 <namex+0xa4>
    path++;
    800043e2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800043e4:	0009c783          	lbu	a5,0(s3)
    800043e8:	ff279ce3          	bne	a5,s2,800043e0 <namex+0x12e>
    800043ec:	b7ad                	j	80004356 <namex+0xa4>
    memmove(name, s, len);
    800043ee:	2601                	sext.w	a2,a2
    800043f0:	85a6                	mv	a1,s1
    800043f2:	8556                	mv	a0,s5
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	ac6080e7          	jalr	-1338(ra) # 80000eba <memmove>
    name[len] = 0;
    800043fc:	9d56                	add	s10,s10,s5
    800043fe:	000d0023          	sb	zero,0(s10)
    80004402:	84ce                	mv	s1,s3
    80004404:	b7bd                	j	80004372 <namex+0xc0>
  if(nameiparent){
    80004406:	f00b0ce3          	beqz	s6,8000431e <namex+0x6c>
    iput(ip);
    8000440a:	8552                	mv	a0,s4
    8000440c:	00000097          	auipc	ra,0x0
    80004410:	acc080e7          	jalr	-1332(ra) # 80003ed8 <iput>
    return 0;
    80004414:	4a01                	li	s4,0
    80004416:	b721                	j	8000431e <namex+0x6c>

0000000080004418 <dirlink>:
{
    80004418:	7139                	addi	sp,sp,-64
    8000441a:	fc06                	sd	ra,56(sp)
    8000441c:	f822                	sd	s0,48(sp)
    8000441e:	f426                	sd	s1,40(sp)
    80004420:	f04a                	sd	s2,32(sp)
    80004422:	ec4e                	sd	s3,24(sp)
    80004424:	e852                	sd	s4,16(sp)
    80004426:	0080                	addi	s0,sp,64
    80004428:	892a                	mv	s2,a0
    8000442a:	8a2e                	mv	s4,a1
    8000442c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000442e:	4601                	li	a2,0
    80004430:	00000097          	auipc	ra,0x0
    80004434:	dd2080e7          	jalr	-558(ra) # 80004202 <dirlookup>
    80004438:	e93d                	bnez	a0,800044ae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000443a:	04c92483          	lw	s1,76(s2)
    8000443e:	c49d                	beqz	s1,8000446c <dirlink+0x54>
    80004440:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004442:	4741                	li	a4,16
    80004444:	86a6                	mv	a3,s1
    80004446:	fc040613          	addi	a2,s0,-64
    8000444a:	4581                	li	a1,0
    8000444c:	854a                	mv	a0,s2
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	b84080e7          	jalr	-1148(ra) # 80003fd2 <readi>
    80004456:	47c1                	li	a5,16
    80004458:	06f51163          	bne	a0,a5,800044ba <dirlink+0xa2>
    if(de.inum == 0)
    8000445c:	fc045783          	lhu	a5,-64(s0)
    80004460:	c791                	beqz	a5,8000446c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004462:	24c1                	addiw	s1,s1,16
    80004464:	04c92783          	lw	a5,76(s2)
    80004468:	fcf4ede3          	bltu	s1,a5,80004442 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000446c:	4639                	li	a2,14
    8000446e:	85d2                	mv	a1,s4
    80004470:	fc240513          	addi	a0,s0,-62
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	af6080e7          	jalr	-1290(ra) # 80000f6a <strncpy>
  de.inum = inum;
    8000447c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004480:	4741                	li	a4,16
    80004482:	86a6                	mv	a3,s1
    80004484:	fc040613          	addi	a2,s0,-64
    80004488:	4581                	li	a1,0
    8000448a:	854a                	mv	a0,s2
    8000448c:	00000097          	auipc	ra,0x0
    80004490:	c3e080e7          	jalr	-962(ra) # 800040ca <writei>
    80004494:	1541                	addi	a0,a0,-16
    80004496:	00a03533          	snez	a0,a0
    8000449a:	40a00533          	neg	a0,a0
}
    8000449e:	70e2                	ld	ra,56(sp)
    800044a0:	7442                	ld	s0,48(sp)
    800044a2:	74a2                	ld	s1,40(sp)
    800044a4:	7902                	ld	s2,32(sp)
    800044a6:	69e2                	ld	s3,24(sp)
    800044a8:	6a42                	ld	s4,16(sp)
    800044aa:	6121                	addi	sp,sp,64
    800044ac:	8082                	ret
    iput(ip);
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	a2a080e7          	jalr	-1494(ra) # 80003ed8 <iput>
    return -1;
    800044b6:	557d                	li	a0,-1
    800044b8:	b7dd                	j	8000449e <dirlink+0x86>
      panic("dirlink read");
    800044ba:	00004517          	auipc	a0,0x4
    800044be:	2c650513          	addi	a0,a0,710 # 80008780 <syscalls+0x1f0>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	07e080e7          	jalr	126(ra) # 80000540 <panic>

00000000800044ca <namei>:

struct inode*
namei(char *path)
{
    800044ca:	1101                	addi	sp,sp,-32
    800044cc:	ec06                	sd	ra,24(sp)
    800044ce:	e822                	sd	s0,16(sp)
    800044d0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044d2:	fe040613          	addi	a2,s0,-32
    800044d6:	4581                	li	a1,0
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	dda080e7          	jalr	-550(ra) # 800042b2 <namex>
}
    800044e0:	60e2                	ld	ra,24(sp)
    800044e2:	6442                	ld	s0,16(sp)
    800044e4:	6105                	addi	sp,sp,32
    800044e6:	8082                	ret

00000000800044e8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044e8:	1141                	addi	sp,sp,-16
    800044ea:	e406                	sd	ra,8(sp)
    800044ec:	e022                	sd	s0,0(sp)
    800044ee:	0800                	addi	s0,sp,16
    800044f0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044f2:	4585                	li	a1,1
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	dbe080e7          	jalr	-578(ra) # 800042b2 <namex>
}
    800044fc:	60a2                	ld	ra,8(sp)
    800044fe:	6402                	ld	s0,0(sp)
    80004500:	0141                	addi	sp,sp,16
    80004502:	8082                	ret

0000000080004504 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004504:	1101                	addi	sp,sp,-32
    80004506:	ec06                	sd	ra,24(sp)
    80004508:	e822                	sd	s0,16(sp)
    8000450a:	e426                	sd	s1,8(sp)
    8000450c:	e04a                	sd	s2,0(sp)
    8000450e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004510:	0003c917          	auipc	s2,0x3c
    80004514:	7c090913          	addi	s2,s2,1984 # 80040cd0 <log>
    80004518:	01892583          	lw	a1,24(s2)
    8000451c:	02892503          	lw	a0,40(s2)
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	fe6080e7          	jalr	-26(ra) # 80003506 <bread>
    80004528:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000452a:	02c92683          	lw	a3,44(s2)
    8000452e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004530:	02d05863          	blez	a3,80004560 <write_head+0x5c>
    80004534:	0003c797          	auipc	a5,0x3c
    80004538:	7cc78793          	addi	a5,a5,1996 # 80040d00 <log+0x30>
    8000453c:	05c50713          	addi	a4,a0,92
    80004540:	36fd                	addiw	a3,a3,-1
    80004542:	02069613          	slli	a2,a3,0x20
    80004546:	01e65693          	srli	a3,a2,0x1e
    8000454a:	0003c617          	auipc	a2,0x3c
    8000454e:	7ba60613          	addi	a2,a2,1978 # 80040d04 <log+0x34>
    80004552:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004554:	4390                	lw	a2,0(a5)
    80004556:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004558:	0791                	addi	a5,a5,4
    8000455a:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000455c:	fed79ce3          	bne	a5,a3,80004554 <write_head+0x50>
  }
  bwrite(buf);
    80004560:	8526                	mv	a0,s1
    80004562:	fffff097          	auipc	ra,0xfffff
    80004566:	096080e7          	jalr	150(ra) # 800035f8 <bwrite>
  brelse(buf);
    8000456a:	8526                	mv	a0,s1
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	0ca080e7          	jalr	202(ra) # 80003636 <brelse>
}
    80004574:	60e2                	ld	ra,24(sp)
    80004576:	6442                	ld	s0,16(sp)
    80004578:	64a2                	ld	s1,8(sp)
    8000457a:	6902                	ld	s2,0(sp)
    8000457c:	6105                	addi	sp,sp,32
    8000457e:	8082                	ret

0000000080004580 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004580:	0003c797          	auipc	a5,0x3c
    80004584:	77c7a783          	lw	a5,1916(a5) # 80040cfc <log+0x2c>
    80004588:	0af05d63          	blez	a5,80004642 <install_trans+0xc2>
{
    8000458c:	7139                	addi	sp,sp,-64
    8000458e:	fc06                	sd	ra,56(sp)
    80004590:	f822                	sd	s0,48(sp)
    80004592:	f426                	sd	s1,40(sp)
    80004594:	f04a                	sd	s2,32(sp)
    80004596:	ec4e                	sd	s3,24(sp)
    80004598:	e852                	sd	s4,16(sp)
    8000459a:	e456                	sd	s5,8(sp)
    8000459c:	e05a                	sd	s6,0(sp)
    8000459e:	0080                	addi	s0,sp,64
    800045a0:	8b2a                	mv	s6,a0
    800045a2:	0003ca97          	auipc	s5,0x3c
    800045a6:	75ea8a93          	addi	s5,s5,1886 # 80040d00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045aa:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045ac:	0003c997          	auipc	s3,0x3c
    800045b0:	72498993          	addi	s3,s3,1828 # 80040cd0 <log>
    800045b4:	a00d                	j	800045d6 <install_trans+0x56>
    brelse(lbuf);
    800045b6:	854a                	mv	a0,s2
    800045b8:	fffff097          	auipc	ra,0xfffff
    800045bc:	07e080e7          	jalr	126(ra) # 80003636 <brelse>
    brelse(dbuf);
    800045c0:	8526                	mv	a0,s1
    800045c2:	fffff097          	auipc	ra,0xfffff
    800045c6:	074080e7          	jalr	116(ra) # 80003636 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ca:	2a05                	addiw	s4,s4,1
    800045cc:	0a91                	addi	s5,s5,4
    800045ce:	02c9a783          	lw	a5,44(s3)
    800045d2:	04fa5e63          	bge	s4,a5,8000462e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d6:	0189a583          	lw	a1,24(s3)
    800045da:	014585bb          	addw	a1,a1,s4
    800045de:	2585                	addiw	a1,a1,1
    800045e0:	0289a503          	lw	a0,40(s3)
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	f22080e7          	jalr	-222(ra) # 80003506 <bread>
    800045ec:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045ee:	000aa583          	lw	a1,0(s5)
    800045f2:	0289a503          	lw	a0,40(s3)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	f10080e7          	jalr	-240(ra) # 80003506 <bread>
    800045fe:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004600:	40000613          	li	a2,1024
    80004604:	05890593          	addi	a1,s2,88
    80004608:	05850513          	addi	a0,a0,88
    8000460c:	ffffd097          	auipc	ra,0xffffd
    80004610:	8ae080e7          	jalr	-1874(ra) # 80000eba <memmove>
    bwrite(dbuf);  // write dst to disk
    80004614:	8526                	mv	a0,s1
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	fe2080e7          	jalr	-30(ra) # 800035f8 <bwrite>
    if(recovering == 0)
    8000461e:	f80b1ce3          	bnez	s6,800045b6 <install_trans+0x36>
      bunpin(dbuf);
    80004622:	8526                	mv	a0,s1
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	0ec080e7          	jalr	236(ra) # 80003710 <bunpin>
    8000462c:	b769                	j	800045b6 <install_trans+0x36>
}
    8000462e:	70e2                	ld	ra,56(sp)
    80004630:	7442                	ld	s0,48(sp)
    80004632:	74a2                	ld	s1,40(sp)
    80004634:	7902                	ld	s2,32(sp)
    80004636:	69e2                	ld	s3,24(sp)
    80004638:	6a42                	ld	s4,16(sp)
    8000463a:	6aa2                	ld	s5,8(sp)
    8000463c:	6b02                	ld	s6,0(sp)
    8000463e:	6121                	addi	sp,sp,64
    80004640:	8082                	ret
    80004642:	8082                	ret

0000000080004644 <initlog>:
{
    80004644:	7179                	addi	sp,sp,-48
    80004646:	f406                	sd	ra,40(sp)
    80004648:	f022                	sd	s0,32(sp)
    8000464a:	ec26                	sd	s1,24(sp)
    8000464c:	e84a                	sd	s2,16(sp)
    8000464e:	e44e                	sd	s3,8(sp)
    80004650:	1800                	addi	s0,sp,48
    80004652:	892a                	mv	s2,a0
    80004654:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004656:	0003c497          	auipc	s1,0x3c
    8000465a:	67a48493          	addi	s1,s1,1658 # 80040cd0 <log>
    8000465e:	00004597          	auipc	a1,0x4
    80004662:	13258593          	addi	a1,a1,306 # 80008790 <syscalls+0x200>
    80004666:	8526                	mv	a0,s1
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	66a080e7          	jalr	1642(ra) # 80000cd2 <initlock>
  log.start = sb->logstart;
    80004670:	0149a583          	lw	a1,20(s3)
    80004674:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004676:	0109a783          	lw	a5,16(s3)
    8000467a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000467c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004680:	854a                	mv	a0,s2
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	e84080e7          	jalr	-380(ra) # 80003506 <bread>
  log.lh.n = lh->n;
    8000468a:	4d34                	lw	a3,88(a0)
    8000468c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000468e:	02d05663          	blez	a3,800046ba <initlog+0x76>
    80004692:	05c50793          	addi	a5,a0,92
    80004696:	0003c717          	auipc	a4,0x3c
    8000469a:	66a70713          	addi	a4,a4,1642 # 80040d00 <log+0x30>
    8000469e:	36fd                	addiw	a3,a3,-1
    800046a0:	02069613          	slli	a2,a3,0x20
    800046a4:	01e65693          	srli	a3,a2,0x1e
    800046a8:	06050613          	addi	a2,a0,96
    800046ac:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800046ae:	4390                	lw	a2,0(a5)
    800046b0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046b2:	0791                	addi	a5,a5,4
    800046b4:	0711                	addi	a4,a4,4
    800046b6:	fed79ce3          	bne	a5,a3,800046ae <initlog+0x6a>
  brelse(buf);
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	f7c080e7          	jalr	-132(ra) # 80003636 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046c2:	4505                	li	a0,1
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	ebc080e7          	jalr	-324(ra) # 80004580 <install_trans>
  log.lh.n = 0;
    800046cc:	0003c797          	auipc	a5,0x3c
    800046d0:	6207a823          	sw	zero,1584(a5) # 80040cfc <log+0x2c>
  write_head(); // clear the log
    800046d4:	00000097          	auipc	ra,0x0
    800046d8:	e30080e7          	jalr	-464(ra) # 80004504 <write_head>
}
    800046dc:	70a2                	ld	ra,40(sp)
    800046de:	7402                	ld	s0,32(sp)
    800046e0:	64e2                	ld	s1,24(sp)
    800046e2:	6942                	ld	s2,16(sp)
    800046e4:	69a2                	ld	s3,8(sp)
    800046e6:	6145                	addi	sp,sp,48
    800046e8:	8082                	ret

00000000800046ea <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046ea:	1101                	addi	sp,sp,-32
    800046ec:	ec06                	sd	ra,24(sp)
    800046ee:	e822                	sd	s0,16(sp)
    800046f0:	e426                	sd	s1,8(sp)
    800046f2:	e04a                	sd	s2,0(sp)
    800046f4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046f6:	0003c517          	auipc	a0,0x3c
    800046fa:	5da50513          	addi	a0,a0,1498 # 80040cd0 <log>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	664080e7          	jalr	1636(ra) # 80000d62 <acquire>
  while(1){
    if(log.committing){
    80004706:	0003c497          	auipc	s1,0x3c
    8000470a:	5ca48493          	addi	s1,s1,1482 # 80040cd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000470e:	4979                	li	s2,30
    80004710:	a039                	j	8000471e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004712:	85a6                	mv	a1,s1
    80004714:	8526                	mv	a0,s1
    80004716:	ffffe097          	auipc	ra,0xffffe
    8000471a:	cf6080e7          	jalr	-778(ra) # 8000240c <sleep>
    if(log.committing){
    8000471e:	50dc                	lw	a5,36(s1)
    80004720:	fbed                	bnez	a5,80004712 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004722:	5098                	lw	a4,32(s1)
    80004724:	2705                	addiw	a4,a4,1
    80004726:	0007069b          	sext.w	a3,a4
    8000472a:	0027179b          	slliw	a5,a4,0x2
    8000472e:	9fb9                	addw	a5,a5,a4
    80004730:	0017979b          	slliw	a5,a5,0x1
    80004734:	54d8                	lw	a4,44(s1)
    80004736:	9fb9                	addw	a5,a5,a4
    80004738:	00f95963          	bge	s2,a5,8000474a <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000473c:	85a6                	mv	a1,s1
    8000473e:	8526                	mv	a0,s1
    80004740:	ffffe097          	auipc	ra,0xffffe
    80004744:	ccc080e7          	jalr	-820(ra) # 8000240c <sleep>
    80004748:	bfd9                	j	8000471e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000474a:	0003c517          	auipc	a0,0x3c
    8000474e:	58650513          	addi	a0,a0,1414 # 80040cd0 <log>
    80004752:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	6c2080e7          	jalr	1730(ra) # 80000e16 <release>
      break;
    }
  }
}
    8000475c:	60e2                	ld	ra,24(sp)
    8000475e:	6442                	ld	s0,16(sp)
    80004760:	64a2                	ld	s1,8(sp)
    80004762:	6902                	ld	s2,0(sp)
    80004764:	6105                	addi	sp,sp,32
    80004766:	8082                	ret

0000000080004768 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004768:	7139                	addi	sp,sp,-64
    8000476a:	fc06                	sd	ra,56(sp)
    8000476c:	f822                	sd	s0,48(sp)
    8000476e:	f426                	sd	s1,40(sp)
    80004770:	f04a                	sd	s2,32(sp)
    80004772:	ec4e                	sd	s3,24(sp)
    80004774:	e852                	sd	s4,16(sp)
    80004776:	e456                	sd	s5,8(sp)
    80004778:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000477a:	0003c497          	auipc	s1,0x3c
    8000477e:	55648493          	addi	s1,s1,1366 # 80040cd0 <log>
    80004782:	8526                	mv	a0,s1
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	5de080e7          	jalr	1502(ra) # 80000d62 <acquire>
  log.outstanding -= 1;
    8000478c:	509c                	lw	a5,32(s1)
    8000478e:	37fd                	addiw	a5,a5,-1
    80004790:	0007891b          	sext.w	s2,a5
    80004794:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004796:	50dc                	lw	a5,36(s1)
    80004798:	e7b9                	bnez	a5,800047e6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000479a:	04091e63          	bnez	s2,800047f6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000479e:	0003c497          	auipc	s1,0x3c
    800047a2:	53248493          	addi	s1,s1,1330 # 80040cd0 <log>
    800047a6:	4785                	li	a5,1
    800047a8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047aa:	8526                	mv	a0,s1
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	66a080e7          	jalr	1642(ra) # 80000e16 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047b4:	54dc                	lw	a5,44(s1)
    800047b6:	06f04763          	bgtz	a5,80004824 <end_op+0xbc>
    acquire(&log.lock);
    800047ba:	0003c497          	auipc	s1,0x3c
    800047be:	51648493          	addi	s1,s1,1302 # 80040cd0 <log>
    800047c2:	8526                	mv	a0,s1
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	59e080e7          	jalr	1438(ra) # 80000d62 <acquire>
    log.committing = 0;
    800047cc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047d0:	8526                	mv	a0,s1
    800047d2:	ffffe097          	auipc	ra,0xffffe
    800047d6:	c9e080e7          	jalr	-866(ra) # 80002470 <wakeup>
    release(&log.lock);
    800047da:	8526                	mv	a0,s1
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	63a080e7          	jalr	1594(ra) # 80000e16 <release>
}
    800047e4:	a03d                	j	80004812 <end_op+0xaa>
    panic("log.committing");
    800047e6:	00004517          	auipc	a0,0x4
    800047ea:	fb250513          	addi	a0,a0,-78 # 80008798 <syscalls+0x208>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	d52080e7          	jalr	-686(ra) # 80000540 <panic>
    wakeup(&log);
    800047f6:	0003c497          	auipc	s1,0x3c
    800047fa:	4da48493          	addi	s1,s1,1242 # 80040cd0 <log>
    800047fe:	8526                	mv	a0,s1
    80004800:	ffffe097          	auipc	ra,0xffffe
    80004804:	c70080e7          	jalr	-912(ra) # 80002470 <wakeup>
  release(&log.lock);
    80004808:	8526                	mv	a0,s1
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	60c080e7          	jalr	1548(ra) # 80000e16 <release>
}
    80004812:	70e2                	ld	ra,56(sp)
    80004814:	7442                	ld	s0,48(sp)
    80004816:	74a2                	ld	s1,40(sp)
    80004818:	7902                	ld	s2,32(sp)
    8000481a:	69e2                	ld	s3,24(sp)
    8000481c:	6a42                	ld	s4,16(sp)
    8000481e:	6aa2                	ld	s5,8(sp)
    80004820:	6121                	addi	sp,sp,64
    80004822:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004824:	0003ca97          	auipc	s5,0x3c
    80004828:	4dca8a93          	addi	s5,s5,1244 # 80040d00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000482c:	0003ca17          	auipc	s4,0x3c
    80004830:	4a4a0a13          	addi	s4,s4,1188 # 80040cd0 <log>
    80004834:	018a2583          	lw	a1,24(s4)
    80004838:	012585bb          	addw	a1,a1,s2
    8000483c:	2585                	addiw	a1,a1,1
    8000483e:	028a2503          	lw	a0,40(s4)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	cc4080e7          	jalr	-828(ra) # 80003506 <bread>
    8000484a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000484c:	000aa583          	lw	a1,0(s5)
    80004850:	028a2503          	lw	a0,40(s4)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	cb2080e7          	jalr	-846(ra) # 80003506 <bread>
    8000485c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000485e:	40000613          	li	a2,1024
    80004862:	05850593          	addi	a1,a0,88
    80004866:	05848513          	addi	a0,s1,88
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	650080e7          	jalr	1616(ra) # 80000eba <memmove>
    bwrite(to);  // write the log
    80004872:	8526                	mv	a0,s1
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	d84080e7          	jalr	-636(ra) # 800035f8 <bwrite>
    brelse(from);
    8000487c:	854e                	mv	a0,s3
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	db8080e7          	jalr	-584(ra) # 80003636 <brelse>
    brelse(to);
    80004886:	8526                	mv	a0,s1
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	dae080e7          	jalr	-594(ra) # 80003636 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004890:	2905                	addiw	s2,s2,1
    80004892:	0a91                	addi	s5,s5,4
    80004894:	02ca2783          	lw	a5,44(s4)
    80004898:	f8f94ee3          	blt	s2,a5,80004834 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	c68080e7          	jalr	-920(ra) # 80004504 <write_head>
    install_trans(0); // Now install writes to home locations
    800048a4:	4501                	li	a0,0
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	cda080e7          	jalr	-806(ra) # 80004580 <install_trans>
    log.lh.n = 0;
    800048ae:	0003c797          	auipc	a5,0x3c
    800048b2:	4407a723          	sw	zero,1102(a5) # 80040cfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048b6:	00000097          	auipc	ra,0x0
    800048ba:	c4e080e7          	jalr	-946(ra) # 80004504 <write_head>
    800048be:	bdf5                	j	800047ba <end_op+0x52>

00000000800048c0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048c0:	1101                	addi	sp,sp,-32
    800048c2:	ec06                	sd	ra,24(sp)
    800048c4:	e822                	sd	s0,16(sp)
    800048c6:	e426                	sd	s1,8(sp)
    800048c8:	e04a                	sd	s2,0(sp)
    800048ca:	1000                	addi	s0,sp,32
    800048cc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048ce:	0003c917          	auipc	s2,0x3c
    800048d2:	40290913          	addi	s2,s2,1026 # 80040cd0 <log>
    800048d6:	854a                	mv	a0,s2
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	48a080e7          	jalr	1162(ra) # 80000d62 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048e0:	02c92603          	lw	a2,44(s2)
    800048e4:	47f5                	li	a5,29
    800048e6:	06c7c563          	blt	a5,a2,80004950 <log_write+0x90>
    800048ea:	0003c797          	auipc	a5,0x3c
    800048ee:	4027a783          	lw	a5,1026(a5) # 80040cec <log+0x1c>
    800048f2:	37fd                	addiw	a5,a5,-1
    800048f4:	04f65e63          	bge	a2,a5,80004950 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048f8:	0003c797          	auipc	a5,0x3c
    800048fc:	3f87a783          	lw	a5,1016(a5) # 80040cf0 <log+0x20>
    80004900:	06f05063          	blez	a5,80004960 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004904:	4781                	li	a5,0
    80004906:	06c05563          	blez	a2,80004970 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000490a:	44cc                	lw	a1,12(s1)
    8000490c:	0003c717          	auipc	a4,0x3c
    80004910:	3f470713          	addi	a4,a4,1012 # 80040d00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004914:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004916:	4314                	lw	a3,0(a4)
    80004918:	04b68c63          	beq	a3,a1,80004970 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000491c:	2785                	addiw	a5,a5,1
    8000491e:	0711                	addi	a4,a4,4
    80004920:	fef61be3          	bne	a2,a5,80004916 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004924:	0621                	addi	a2,a2,8
    80004926:	060a                	slli	a2,a2,0x2
    80004928:	0003c797          	auipc	a5,0x3c
    8000492c:	3a878793          	addi	a5,a5,936 # 80040cd0 <log>
    80004930:	97b2                	add	a5,a5,a2
    80004932:	44d8                	lw	a4,12(s1)
    80004934:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004936:	8526                	mv	a0,s1
    80004938:	fffff097          	auipc	ra,0xfffff
    8000493c:	d9c080e7          	jalr	-612(ra) # 800036d4 <bpin>
    log.lh.n++;
    80004940:	0003c717          	auipc	a4,0x3c
    80004944:	39070713          	addi	a4,a4,912 # 80040cd0 <log>
    80004948:	575c                	lw	a5,44(a4)
    8000494a:	2785                	addiw	a5,a5,1
    8000494c:	d75c                	sw	a5,44(a4)
    8000494e:	a82d                	j	80004988 <log_write+0xc8>
    panic("too big a transaction");
    80004950:	00004517          	auipc	a0,0x4
    80004954:	e5850513          	addi	a0,a0,-424 # 800087a8 <syscalls+0x218>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	be8080e7          	jalr	-1048(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004960:	00004517          	auipc	a0,0x4
    80004964:	e6050513          	addi	a0,a0,-416 # 800087c0 <syscalls+0x230>
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	bd8080e7          	jalr	-1064(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004970:	00878693          	addi	a3,a5,8
    80004974:	068a                	slli	a3,a3,0x2
    80004976:	0003c717          	auipc	a4,0x3c
    8000497a:	35a70713          	addi	a4,a4,858 # 80040cd0 <log>
    8000497e:	9736                	add	a4,a4,a3
    80004980:	44d4                	lw	a3,12(s1)
    80004982:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004984:	faf609e3          	beq	a2,a5,80004936 <log_write+0x76>
  }
  release(&log.lock);
    80004988:	0003c517          	auipc	a0,0x3c
    8000498c:	34850513          	addi	a0,a0,840 # 80040cd0 <log>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	486080e7          	jalr	1158(ra) # 80000e16 <release>
}
    80004998:	60e2                	ld	ra,24(sp)
    8000499a:	6442                	ld	s0,16(sp)
    8000499c:	64a2                	ld	s1,8(sp)
    8000499e:	6902                	ld	s2,0(sp)
    800049a0:	6105                	addi	sp,sp,32
    800049a2:	8082                	ret

00000000800049a4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049a4:	1101                	addi	sp,sp,-32
    800049a6:	ec06                	sd	ra,24(sp)
    800049a8:	e822                	sd	s0,16(sp)
    800049aa:	e426                	sd	s1,8(sp)
    800049ac:	e04a                	sd	s2,0(sp)
    800049ae:	1000                	addi	s0,sp,32
    800049b0:	84aa                	mv	s1,a0
    800049b2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049b4:	00004597          	auipc	a1,0x4
    800049b8:	e2c58593          	addi	a1,a1,-468 # 800087e0 <syscalls+0x250>
    800049bc:	0521                	addi	a0,a0,8
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	314080e7          	jalr	788(ra) # 80000cd2 <initlock>
  lk->name = name;
    800049c6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049ce:	0204a423          	sw	zero,40(s1)
}
    800049d2:	60e2                	ld	ra,24(sp)
    800049d4:	6442                	ld	s0,16(sp)
    800049d6:	64a2                	ld	s1,8(sp)
    800049d8:	6902                	ld	s2,0(sp)
    800049da:	6105                	addi	sp,sp,32
    800049dc:	8082                	ret

00000000800049de <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049de:	1101                	addi	sp,sp,-32
    800049e0:	ec06                	sd	ra,24(sp)
    800049e2:	e822                	sd	s0,16(sp)
    800049e4:	e426                	sd	s1,8(sp)
    800049e6:	e04a                	sd	s2,0(sp)
    800049e8:	1000                	addi	s0,sp,32
    800049ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049ec:	00850913          	addi	s2,a0,8
    800049f0:	854a                	mv	a0,s2
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	370080e7          	jalr	880(ra) # 80000d62 <acquire>
  while (lk->locked) {
    800049fa:	409c                	lw	a5,0(s1)
    800049fc:	cb89                	beqz	a5,80004a0e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049fe:	85ca                	mv	a1,s2
    80004a00:	8526                	mv	a0,s1
    80004a02:	ffffe097          	auipc	ra,0xffffe
    80004a06:	a0a080e7          	jalr	-1526(ra) # 8000240c <sleep>
  while (lk->locked) {
    80004a0a:	409c                	lw	a5,0(s1)
    80004a0c:	fbed                	bnez	a5,800049fe <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a0e:	4785                	li	a5,1
    80004a10:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a12:	ffffd097          	auipc	ra,0xffffd
    80004a16:	25e080e7          	jalr	606(ra) # 80001c70 <myproc>
    80004a1a:	591c                	lw	a5,48(a0)
    80004a1c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a1e:	854a                	mv	a0,s2
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	3f6080e7          	jalr	1014(ra) # 80000e16 <release>
}
    80004a28:	60e2                	ld	ra,24(sp)
    80004a2a:	6442                	ld	s0,16(sp)
    80004a2c:	64a2                	ld	s1,8(sp)
    80004a2e:	6902                	ld	s2,0(sp)
    80004a30:	6105                	addi	sp,sp,32
    80004a32:	8082                	ret

0000000080004a34 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a34:	1101                	addi	sp,sp,-32
    80004a36:	ec06                	sd	ra,24(sp)
    80004a38:	e822                	sd	s0,16(sp)
    80004a3a:	e426                	sd	s1,8(sp)
    80004a3c:	e04a                	sd	s2,0(sp)
    80004a3e:	1000                	addi	s0,sp,32
    80004a40:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a42:	00850913          	addi	s2,a0,8
    80004a46:	854a                	mv	a0,s2
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	31a080e7          	jalr	794(ra) # 80000d62 <acquire>
  lk->locked = 0;
    80004a50:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a54:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a58:	8526                	mv	a0,s1
    80004a5a:	ffffe097          	auipc	ra,0xffffe
    80004a5e:	a16080e7          	jalr	-1514(ra) # 80002470 <wakeup>
  release(&lk->lk);
    80004a62:	854a                	mv	a0,s2
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	3b2080e7          	jalr	946(ra) # 80000e16 <release>
}
    80004a6c:	60e2                	ld	ra,24(sp)
    80004a6e:	6442                	ld	s0,16(sp)
    80004a70:	64a2                	ld	s1,8(sp)
    80004a72:	6902                	ld	s2,0(sp)
    80004a74:	6105                	addi	sp,sp,32
    80004a76:	8082                	ret

0000000080004a78 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a78:	7179                	addi	sp,sp,-48
    80004a7a:	f406                	sd	ra,40(sp)
    80004a7c:	f022                	sd	s0,32(sp)
    80004a7e:	ec26                	sd	s1,24(sp)
    80004a80:	e84a                	sd	s2,16(sp)
    80004a82:	e44e                	sd	s3,8(sp)
    80004a84:	1800                	addi	s0,sp,48
    80004a86:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a88:	00850913          	addi	s2,a0,8
    80004a8c:	854a                	mv	a0,s2
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	2d4080e7          	jalr	724(ra) # 80000d62 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a96:	409c                	lw	a5,0(s1)
    80004a98:	ef99                	bnez	a5,80004ab6 <holdingsleep+0x3e>
    80004a9a:	4481                	li	s1,0
  release(&lk->lk);
    80004a9c:	854a                	mv	a0,s2
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	378080e7          	jalr	888(ra) # 80000e16 <release>
  return r;
}
    80004aa6:	8526                	mv	a0,s1
    80004aa8:	70a2                	ld	ra,40(sp)
    80004aaa:	7402                	ld	s0,32(sp)
    80004aac:	64e2                	ld	s1,24(sp)
    80004aae:	6942                	ld	s2,16(sp)
    80004ab0:	69a2                	ld	s3,8(sp)
    80004ab2:	6145                	addi	sp,sp,48
    80004ab4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ab6:	0284a983          	lw	s3,40(s1)
    80004aba:	ffffd097          	auipc	ra,0xffffd
    80004abe:	1b6080e7          	jalr	438(ra) # 80001c70 <myproc>
    80004ac2:	5904                	lw	s1,48(a0)
    80004ac4:	413484b3          	sub	s1,s1,s3
    80004ac8:	0014b493          	seqz	s1,s1
    80004acc:	bfc1                	j	80004a9c <holdingsleep+0x24>

0000000080004ace <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ace:	1141                	addi	sp,sp,-16
    80004ad0:	e406                	sd	ra,8(sp)
    80004ad2:	e022                	sd	s0,0(sp)
    80004ad4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ad6:	00004597          	auipc	a1,0x4
    80004ada:	d1a58593          	addi	a1,a1,-742 # 800087f0 <syscalls+0x260>
    80004ade:	0003c517          	auipc	a0,0x3c
    80004ae2:	33a50513          	addi	a0,a0,826 # 80040e18 <ftable>
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	1ec080e7          	jalr	492(ra) # 80000cd2 <initlock>
}
    80004aee:	60a2                	ld	ra,8(sp)
    80004af0:	6402                	ld	s0,0(sp)
    80004af2:	0141                	addi	sp,sp,16
    80004af4:	8082                	ret

0000000080004af6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004af6:	1101                	addi	sp,sp,-32
    80004af8:	ec06                	sd	ra,24(sp)
    80004afa:	e822                	sd	s0,16(sp)
    80004afc:	e426                	sd	s1,8(sp)
    80004afe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b00:	0003c517          	auipc	a0,0x3c
    80004b04:	31850513          	addi	a0,a0,792 # 80040e18 <ftable>
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	25a080e7          	jalr	602(ra) # 80000d62 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b10:	0003c497          	auipc	s1,0x3c
    80004b14:	32048493          	addi	s1,s1,800 # 80040e30 <ftable+0x18>
    80004b18:	0003d717          	auipc	a4,0x3d
    80004b1c:	2b870713          	addi	a4,a4,696 # 80041dd0 <disk>
    if(f->ref == 0){
    80004b20:	40dc                	lw	a5,4(s1)
    80004b22:	cf99                	beqz	a5,80004b40 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b24:	02848493          	addi	s1,s1,40
    80004b28:	fee49ce3          	bne	s1,a4,80004b20 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b2c:	0003c517          	auipc	a0,0x3c
    80004b30:	2ec50513          	addi	a0,a0,748 # 80040e18 <ftable>
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	2e2080e7          	jalr	738(ra) # 80000e16 <release>
  return 0;
    80004b3c:	4481                	li	s1,0
    80004b3e:	a819                	j	80004b54 <filealloc+0x5e>
      f->ref = 1;
    80004b40:	4785                	li	a5,1
    80004b42:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b44:	0003c517          	auipc	a0,0x3c
    80004b48:	2d450513          	addi	a0,a0,724 # 80040e18 <ftable>
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	2ca080e7          	jalr	714(ra) # 80000e16 <release>
}
    80004b54:	8526                	mv	a0,s1
    80004b56:	60e2                	ld	ra,24(sp)
    80004b58:	6442                	ld	s0,16(sp)
    80004b5a:	64a2                	ld	s1,8(sp)
    80004b5c:	6105                	addi	sp,sp,32
    80004b5e:	8082                	ret

0000000080004b60 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b60:	1101                	addi	sp,sp,-32
    80004b62:	ec06                	sd	ra,24(sp)
    80004b64:	e822                	sd	s0,16(sp)
    80004b66:	e426                	sd	s1,8(sp)
    80004b68:	1000                	addi	s0,sp,32
    80004b6a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b6c:	0003c517          	auipc	a0,0x3c
    80004b70:	2ac50513          	addi	a0,a0,684 # 80040e18 <ftable>
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	1ee080e7          	jalr	494(ra) # 80000d62 <acquire>
  if(f->ref < 1)
    80004b7c:	40dc                	lw	a5,4(s1)
    80004b7e:	02f05263          	blez	a5,80004ba2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b82:	2785                	addiw	a5,a5,1
    80004b84:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b86:	0003c517          	auipc	a0,0x3c
    80004b8a:	29250513          	addi	a0,a0,658 # 80040e18 <ftable>
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	288080e7          	jalr	648(ra) # 80000e16 <release>
  return f;
}
    80004b96:	8526                	mv	a0,s1
    80004b98:	60e2                	ld	ra,24(sp)
    80004b9a:	6442                	ld	s0,16(sp)
    80004b9c:	64a2                	ld	s1,8(sp)
    80004b9e:	6105                	addi	sp,sp,32
    80004ba0:	8082                	ret
    panic("filedup");
    80004ba2:	00004517          	auipc	a0,0x4
    80004ba6:	c5650513          	addi	a0,a0,-938 # 800087f8 <syscalls+0x268>
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	996080e7          	jalr	-1642(ra) # 80000540 <panic>

0000000080004bb2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bb2:	7139                	addi	sp,sp,-64
    80004bb4:	fc06                	sd	ra,56(sp)
    80004bb6:	f822                	sd	s0,48(sp)
    80004bb8:	f426                	sd	s1,40(sp)
    80004bba:	f04a                	sd	s2,32(sp)
    80004bbc:	ec4e                	sd	s3,24(sp)
    80004bbe:	e852                	sd	s4,16(sp)
    80004bc0:	e456                	sd	s5,8(sp)
    80004bc2:	0080                	addi	s0,sp,64
    80004bc4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bc6:	0003c517          	auipc	a0,0x3c
    80004bca:	25250513          	addi	a0,a0,594 # 80040e18 <ftable>
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	194080e7          	jalr	404(ra) # 80000d62 <acquire>
  if(f->ref < 1)
    80004bd6:	40dc                	lw	a5,4(s1)
    80004bd8:	06f05163          	blez	a5,80004c3a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bdc:	37fd                	addiw	a5,a5,-1
    80004bde:	0007871b          	sext.w	a4,a5
    80004be2:	c0dc                	sw	a5,4(s1)
    80004be4:	06e04363          	bgtz	a4,80004c4a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004be8:	0004a903          	lw	s2,0(s1)
    80004bec:	0094ca83          	lbu	s5,9(s1)
    80004bf0:	0104ba03          	ld	s4,16(s1)
    80004bf4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bf8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bfc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c00:	0003c517          	auipc	a0,0x3c
    80004c04:	21850513          	addi	a0,a0,536 # 80040e18 <ftable>
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	20e080e7          	jalr	526(ra) # 80000e16 <release>

  if(ff.type == FD_PIPE){
    80004c10:	4785                	li	a5,1
    80004c12:	04f90d63          	beq	s2,a5,80004c6c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c16:	3979                	addiw	s2,s2,-2
    80004c18:	4785                	li	a5,1
    80004c1a:	0527e063          	bltu	a5,s2,80004c5a <fileclose+0xa8>
    begin_op();
    80004c1e:	00000097          	auipc	ra,0x0
    80004c22:	acc080e7          	jalr	-1332(ra) # 800046ea <begin_op>
    iput(ff.ip);
    80004c26:	854e                	mv	a0,s3
    80004c28:	fffff097          	auipc	ra,0xfffff
    80004c2c:	2b0080e7          	jalr	688(ra) # 80003ed8 <iput>
    end_op();
    80004c30:	00000097          	auipc	ra,0x0
    80004c34:	b38080e7          	jalr	-1224(ra) # 80004768 <end_op>
    80004c38:	a00d                	j	80004c5a <fileclose+0xa8>
    panic("fileclose");
    80004c3a:	00004517          	auipc	a0,0x4
    80004c3e:	bc650513          	addi	a0,a0,-1082 # 80008800 <syscalls+0x270>
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	8fe080e7          	jalr	-1794(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004c4a:	0003c517          	auipc	a0,0x3c
    80004c4e:	1ce50513          	addi	a0,a0,462 # 80040e18 <ftable>
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	1c4080e7          	jalr	452(ra) # 80000e16 <release>
  }
}
    80004c5a:	70e2                	ld	ra,56(sp)
    80004c5c:	7442                	ld	s0,48(sp)
    80004c5e:	74a2                	ld	s1,40(sp)
    80004c60:	7902                	ld	s2,32(sp)
    80004c62:	69e2                	ld	s3,24(sp)
    80004c64:	6a42                	ld	s4,16(sp)
    80004c66:	6aa2                	ld	s5,8(sp)
    80004c68:	6121                	addi	sp,sp,64
    80004c6a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c6c:	85d6                	mv	a1,s5
    80004c6e:	8552                	mv	a0,s4
    80004c70:	00000097          	auipc	ra,0x0
    80004c74:	34c080e7          	jalr	844(ra) # 80004fbc <pipeclose>
    80004c78:	b7cd                	j	80004c5a <fileclose+0xa8>

0000000080004c7a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c7a:	715d                	addi	sp,sp,-80
    80004c7c:	e486                	sd	ra,72(sp)
    80004c7e:	e0a2                	sd	s0,64(sp)
    80004c80:	fc26                	sd	s1,56(sp)
    80004c82:	f84a                	sd	s2,48(sp)
    80004c84:	f44e                	sd	s3,40(sp)
    80004c86:	0880                	addi	s0,sp,80
    80004c88:	84aa                	mv	s1,a0
    80004c8a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	fe4080e7          	jalr	-28(ra) # 80001c70 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c94:	409c                	lw	a5,0(s1)
    80004c96:	37f9                	addiw	a5,a5,-2
    80004c98:	4705                	li	a4,1
    80004c9a:	04f76763          	bltu	a4,a5,80004ce8 <filestat+0x6e>
    80004c9e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ca0:	6c88                	ld	a0,24(s1)
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	07c080e7          	jalr	124(ra) # 80003d1e <ilock>
    stati(f->ip, &st);
    80004caa:	fb840593          	addi	a1,s0,-72
    80004cae:	6c88                	ld	a0,24(s1)
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	2f8080e7          	jalr	760(ra) # 80003fa8 <stati>
    iunlock(f->ip);
    80004cb8:	6c88                	ld	a0,24(s1)
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	126080e7          	jalr	294(ra) # 80003de0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cc2:	46e1                	li	a3,24
    80004cc4:	fb840613          	addi	a2,s0,-72
    80004cc8:	85ce                	mv	a1,s3
    80004cca:	05093503          	ld	a0,80(s2)
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	b64080e7          	jalr	-1180(ra) # 80001832 <copyout>
    80004cd6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cda:	60a6                	ld	ra,72(sp)
    80004cdc:	6406                	ld	s0,64(sp)
    80004cde:	74e2                	ld	s1,56(sp)
    80004ce0:	7942                	ld	s2,48(sp)
    80004ce2:	79a2                	ld	s3,40(sp)
    80004ce4:	6161                	addi	sp,sp,80
    80004ce6:	8082                	ret
  return -1;
    80004ce8:	557d                	li	a0,-1
    80004cea:	bfc5                	j	80004cda <filestat+0x60>

0000000080004cec <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cec:	7179                	addi	sp,sp,-48
    80004cee:	f406                	sd	ra,40(sp)
    80004cf0:	f022                	sd	s0,32(sp)
    80004cf2:	ec26                	sd	s1,24(sp)
    80004cf4:	e84a                	sd	s2,16(sp)
    80004cf6:	e44e                	sd	s3,8(sp)
    80004cf8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cfa:	00854783          	lbu	a5,8(a0)
    80004cfe:	c3d5                	beqz	a5,80004da2 <fileread+0xb6>
    80004d00:	84aa                	mv	s1,a0
    80004d02:	89ae                	mv	s3,a1
    80004d04:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d06:	411c                	lw	a5,0(a0)
    80004d08:	4705                	li	a4,1
    80004d0a:	04e78963          	beq	a5,a4,80004d5c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d0e:	470d                	li	a4,3
    80004d10:	04e78d63          	beq	a5,a4,80004d6a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d14:	4709                	li	a4,2
    80004d16:	06e79e63          	bne	a5,a4,80004d92 <fileread+0xa6>
    ilock(f->ip);
    80004d1a:	6d08                	ld	a0,24(a0)
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	002080e7          	jalr	2(ra) # 80003d1e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d24:	874a                	mv	a4,s2
    80004d26:	5094                	lw	a3,32(s1)
    80004d28:	864e                	mv	a2,s3
    80004d2a:	4585                	li	a1,1
    80004d2c:	6c88                	ld	a0,24(s1)
    80004d2e:	fffff097          	auipc	ra,0xfffff
    80004d32:	2a4080e7          	jalr	676(ra) # 80003fd2 <readi>
    80004d36:	892a                	mv	s2,a0
    80004d38:	00a05563          	blez	a0,80004d42 <fileread+0x56>
      f->off += r;
    80004d3c:	509c                	lw	a5,32(s1)
    80004d3e:	9fa9                	addw	a5,a5,a0
    80004d40:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d42:	6c88                	ld	a0,24(s1)
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	09c080e7          	jalr	156(ra) # 80003de0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d4c:	854a                	mv	a0,s2
    80004d4e:	70a2                	ld	ra,40(sp)
    80004d50:	7402                	ld	s0,32(sp)
    80004d52:	64e2                	ld	s1,24(sp)
    80004d54:	6942                	ld	s2,16(sp)
    80004d56:	69a2                	ld	s3,8(sp)
    80004d58:	6145                	addi	sp,sp,48
    80004d5a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d5c:	6908                	ld	a0,16(a0)
    80004d5e:	00000097          	auipc	ra,0x0
    80004d62:	3c6080e7          	jalr	966(ra) # 80005124 <piperead>
    80004d66:	892a                	mv	s2,a0
    80004d68:	b7d5                	j	80004d4c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d6a:	02451783          	lh	a5,36(a0)
    80004d6e:	03079693          	slli	a3,a5,0x30
    80004d72:	92c1                	srli	a3,a3,0x30
    80004d74:	4725                	li	a4,9
    80004d76:	02d76863          	bltu	a4,a3,80004da6 <fileread+0xba>
    80004d7a:	0792                	slli	a5,a5,0x4
    80004d7c:	0003c717          	auipc	a4,0x3c
    80004d80:	ffc70713          	addi	a4,a4,-4 # 80040d78 <devsw>
    80004d84:	97ba                	add	a5,a5,a4
    80004d86:	639c                	ld	a5,0(a5)
    80004d88:	c38d                	beqz	a5,80004daa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d8a:	4505                	li	a0,1
    80004d8c:	9782                	jalr	a5
    80004d8e:	892a                	mv	s2,a0
    80004d90:	bf75                	j	80004d4c <fileread+0x60>
    panic("fileread");
    80004d92:	00004517          	auipc	a0,0x4
    80004d96:	a7e50513          	addi	a0,a0,-1410 # 80008810 <syscalls+0x280>
    80004d9a:	ffffb097          	auipc	ra,0xffffb
    80004d9e:	7a6080e7          	jalr	1958(ra) # 80000540 <panic>
    return -1;
    80004da2:	597d                	li	s2,-1
    80004da4:	b765                	j	80004d4c <fileread+0x60>
      return -1;
    80004da6:	597d                	li	s2,-1
    80004da8:	b755                	j	80004d4c <fileread+0x60>
    80004daa:	597d                	li	s2,-1
    80004dac:	b745                	j	80004d4c <fileread+0x60>

0000000080004dae <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004dae:	715d                	addi	sp,sp,-80
    80004db0:	e486                	sd	ra,72(sp)
    80004db2:	e0a2                	sd	s0,64(sp)
    80004db4:	fc26                	sd	s1,56(sp)
    80004db6:	f84a                	sd	s2,48(sp)
    80004db8:	f44e                	sd	s3,40(sp)
    80004dba:	f052                	sd	s4,32(sp)
    80004dbc:	ec56                	sd	s5,24(sp)
    80004dbe:	e85a                	sd	s6,16(sp)
    80004dc0:	e45e                	sd	s7,8(sp)
    80004dc2:	e062                	sd	s8,0(sp)
    80004dc4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dc6:	00954783          	lbu	a5,9(a0)
    80004dca:	10078663          	beqz	a5,80004ed6 <filewrite+0x128>
    80004dce:	892a                	mv	s2,a0
    80004dd0:	8b2e                	mv	s6,a1
    80004dd2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dd4:	411c                	lw	a5,0(a0)
    80004dd6:	4705                	li	a4,1
    80004dd8:	02e78263          	beq	a5,a4,80004dfc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ddc:	470d                	li	a4,3
    80004dde:	02e78663          	beq	a5,a4,80004e0a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004de2:	4709                	li	a4,2
    80004de4:	0ee79163          	bne	a5,a4,80004ec6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004de8:	0ac05d63          	blez	a2,80004ea2 <filewrite+0xf4>
    int i = 0;
    80004dec:	4981                	li	s3,0
    80004dee:	6b85                	lui	s7,0x1
    80004df0:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004df4:	6c05                	lui	s8,0x1
    80004df6:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004dfa:	a861                	j	80004e92 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004dfc:	6908                	ld	a0,16(a0)
    80004dfe:	00000097          	auipc	ra,0x0
    80004e02:	22e080e7          	jalr	558(ra) # 8000502c <pipewrite>
    80004e06:	8a2a                	mv	s4,a0
    80004e08:	a045                	j	80004ea8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e0a:	02451783          	lh	a5,36(a0)
    80004e0e:	03079693          	slli	a3,a5,0x30
    80004e12:	92c1                	srli	a3,a3,0x30
    80004e14:	4725                	li	a4,9
    80004e16:	0cd76263          	bltu	a4,a3,80004eda <filewrite+0x12c>
    80004e1a:	0792                	slli	a5,a5,0x4
    80004e1c:	0003c717          	auipc	a4,0x3c
    80004e20:	f5c70713          	addi	a4,a4,-164 # 80040d78 <devsw>
    80004e24:	97ba                	add	a5,a5,a4
    80004e26:	679c                	ld	a5,8(a5)
    80004e28:	cbdd                	beqz	a5,80004ede <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e2a:	4505                	li	a0,1
    80004e2c:	9782                	jalr	a5
    80004e2e:	8a2a                	mv	s4,a0
    80004e30:	a8a5                	j	80004ea8 <filewrite+0xfa>
    80004e32:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e36:	00000097          	auipc	ra,0x0
    80004e3a:	8b4080e7          	jalr	-1868(ra) # 800046ea <begin_op>
      ilock(f->ip);
    80004e3e:	01893503          	ld	a0,24(s2)
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	edc080e7          	jalr	-292(ra) # 80003d1e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e4a:	8756                	mv	a4,s5
    80004e4c:	02092683          	lw	a3,32(s2)
    80004e50:	01698633          	add	a2,s3,s6
    80004e54:	4585                	li	a1,1
    80004e56:	01893503          	ld	a0,24(s2)
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	270080e7          	jalr	624(ra) # 800040ca <writei>
    80004e62:	84aa                	mv	s1,a0
    80004e64:	00a05763          	blez	a0,80004e72 <filewrite+0xc4>
        f->off += r;
    80004e68:	02092783          	lw	a5,32(s2)
    80004e6c:	9fa9                	addw	a5,a5,a0
    80004e6e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e72:	01893503          	ld	a0,24(s2)
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	f6a080e7          	jalr	-150(ra) # 80003de0 <iunlock>
      end_op();
    80004e7e:	00000097          	auipc	ra,0x0
    80004e82:	8ea080e7          	jalr	-1814(ra) # 80004768 <end_op>

      if(r != n1){
    80004e86:	009a9f63          	bne	s5,s1,80004ea4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e8a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e8e:	0149db63          	bge	s3,s4,80004ea4 <filewrite+0xf6>
      int n1 = n - i;
    80004e92:	413a04bb          	subw	s1,s4,s3
    80004e96:	0004879b          	sext.w	a5,s1
    80004e9a:	f8fbdce3          	bge	s7,a5,80004e32 <filewrite+0x84>
    80004e9e:	84e2                	mv	s1,s8
    80004ea0:	bf49                	j	80004e32 <filewrite+0x84>
    int i = 0;
    80004ea2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ea4:	013a1f63          	bne	s4,s3,80004ec2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ea8:	8552                	mv	a0,s4
    80004eaa:	60a6                	ld	ra,72(sp)
    80004eac:	6406                	ld	s0,64(sp)
    80004eae:	74e2                	ld	s1,56(sp)
    80004eb0:	7942                	ld	s2,48(sp)
    80004eb2:	79a2                	ld	s3,40(sp)
    80004eb4:	7a02                	ld	s4,32(sp)
    80004eb6:	6ae2                	ld	s5,24(sp)
    80004eb8:	6b42                	ld	s6,16(sp)
    80004eba:	6ba2                	ld	s7,8(sp)
    80004ebc:	6c02                	ld	s8,0(sp)
    80004ebe:	6161                	addi	sp,sp,80
    80004ec0:	8082                	ret
    ret = (i == n ? n : -1);
    80004ec2:	5a7d                	li	s4,-1
    80004ec4:	b7d5                	j	80004ea8 <filewrite+0xfa>
    panic("filewrite");
    80004ec6:	00004517          	auipc	a0,0x4
    80004eca:	95a50513          	addi	a0,a0,-1702 # 80008820 <syscalls+0x290>
    80004ece:	ffffb097          	auipc	ra,0xffffb
    80004ed2:	672080e7          	jalr	1650(ra) # 80000540 <panic>
    return -1;
    80004ed6:	5a7d                	li	s4,-1
    80004ed8:	bfc1                	j	80004ea8 <filewrite+0xfa>
      return -1;
    80004eda:	5a7d                	li	s4,-1
    80004edc:	b7f1                	j	80004ea8 <filewrite+0xfa>
    80004ede:	5a7d                	li	s4,-1
    80004ee0:	b7e1                	j	80004ea8 <filewrite+0xfa>

0000000080004ee2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ee2:	7179                	addi	sp,sp,-48
    80004ee4:	f406                	sd	ra,40(sp)
    80004ee6:	f022                	sd	s0,32(sp)
    80004ee8:	ec26                	sd	s1,24(sp)
    80004eea:	e84a                	sd	s2,16(sp)
    80004eec:	e44e                	sd	s3,8(sp)
    80004eee:	e052                	sd	s4,0(sp)
    80004ef0:	1800                	addi	s0,sp,48
    80004ef2:	84aa                	mv	s1,a0
    80004ef4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ef6:	0005b023          	sd	zero,0(a1)
    80004efa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004efe:	00000097          	auipc	ra,0x0
    80004f02:	bf8080e7          	jalr	-1032(ra) # 80004af6 <filealloc>
    80004f06:	e088                	sd	a0,0(s1)
    80004f08:	c551                	beqz	a0,80004f94 <pipealloc+0xb2>
    80004f0a:	00000097          	auipc	ra,0x0
    80004f0e:	bec080e7          	jalr	-1044(ra) # 80004af6 <filealloc>
    80004f12:	00aa3023          	sd	a0,0(s4)
    80004f16:	c92d                	beqz	a0,80004f88 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	c4a080e7          	jalr	-950(ra) # 80000b62 <kalloc>
    80004f20:	892a                	mv	s2,a0
    80004f22:	c125                	beqz	a0,80004f82 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f24:	4985                	li	s3,1
    80004f26:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f2a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f2e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f32:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f36:	00004597          	auipc	a1,0x4
    80004f3a:	8fa58593          	addi	a1,a1,-1798 # 80008830 <syscalls+0x2a0>
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	d94080e7          	jalr	-620(ra) # 80000cd2 <initlock>
  (*f0)->type = FD_PIPE;
    80004f46:	609c                	ld	a5,0(s1)
    80004f48:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f4c:	609c                	ld	a5,0(s1)
    80004f4e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f52:	609c                	ld	a5,0(s1)
    80004f54:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f58:	609c                	ld	a5,0(s1)
    80004f5a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f5e:	000a3783          	ld	a5,0(s4)
    80004f62:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f66:	000a3783          	ld	a5,0(s4)
    80004f6a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f6e:	000a3783          	ld	a5,0(s4)
    80004f72:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f76:	000a3783          	ld	a5,0(s4)
    80004f7a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f7e:	4501                	li	a0,0
    80004f80:	a025                	j	80004fa8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f82:	6088                	ld	a0,0(s1)
    80004f84:	e501                	bnez	a0,80004f8c <pipealloc+0xaa>
    80004f86:	a039                	j	80004f94 <pipealloc+0xb2>
    80004f88:	6088                	ld	a0,0(s1)
    80004f8a:	c51d                	beqz	a0,80004fb8 <pipealloc+0xd6>
    fileclose(*f0);
    80004f8c:	00000097          	auipc	ra,0x0
    80004f90:	c26080e7          	jalr	-986(ra) # 80004bb2 <fileclose>
  if(*f1)
    80004f94:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f98:	557d                	li	a0,-1
  if(*f1)
    80004f9a:	c799                	beqz	a5,80004fa8 <pipealloc+0xc6>
    fileclose(*f1);
    80004f9c:	853e                	mv	a0,a5
    80004f9e:	00000097          	auipc	ra,0x0
    80004fa2:	c14080e7          	jalr	-1004(ra) # 80004bb2 <fileclose>
  return -1;
    80004fa6:	557d                	li	a0,-1
}
    80004fa8:	70a2                	ld	ra,40(sp)
    80004faa:	7402                	ld	s0,32(sp)
    80004fac:	64e2                	ld	s1,24(sp)
    80004fae:	6942                	ld	s2,16(sp)
    80004fb0:	69a2                	ld	s3,8(sp)
    80004fb2:	6a02                	ld	s4,0(sp)
    80004fb4:	6145                	addi	sp,sp,48
    80004fb6:	8082                	ret
  return -1;
    80004fb8:	557d                	li	a0,-1
    80004fba:	b7fd                	j	80004fa8 <pipealloc+0xc6>

0000000080004fbc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fbc:	1101                	addi	sp,sp,-32
    80004fbe:	ec06                	sd	ra,24(sp)
    80004fc0:	e822                	sd	s0,16(sp)
    80004fc2:	e426                	sd	s1,8(sp)
    80004fc4:	e04a                	sd	s2,0(sp)
    80004fc6:	1000                	addi	s0,sp,32
    80004fc8:	84aa                	mv	s1,a0
    80004fca:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	d96080e7          	jalr	-618(ra) # 80000d62 <acquire>
  if(writable){
    80004fd4:	02090d63          	beqz	s2,8000500e <pipeclose+0x52>
    pi->writeopen = 0;
    80004fd8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fdc:	21848513          	addi	a0,s1,536
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	490080e7          	jalr	1168(ra) # 80002470 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fe8:	2204b783          	ld	a5,544(s1)
    80004fec:	eb95                	bnez	a5,80005020 <pipeclose+0x64>
    release(&pi->lock);
    80004fee:	8526                	mv	a0,s1
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	e26080e7          	jalr	-474(ra) # 80000e16 <release>
    kfree((char*)pi);
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	a00080e7          	jalr	-1536(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80005002:	60e2                	ld	ra,24(sp)
    80005004:	6442                	ld	s0,16(sp)
    80005006:	64a2                	ld	s1,8(sp)
    80005008:	6902                	ld	s2,0(sp)
    8000500a:	6105                	addi	sp,sp,32
    8000500c:	8082                	ret
    pi->readopen = 0;
    8000500e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005012:	21c48513          	addi	a0,s1,540
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	45a080e7          	jalr	1114(ra) # 80002470 <wakeup>
    8000501e:	b7e9                	j	80004fe8 <pipeclose+0x2c>
    release(&pi->lock);
    80005020:	8526                	mv	a0,s1
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	df4080e7          	jalr	-524(ra) # 80000e16 <release>
}
    8000502a:	bfe1                	j	80005002 <pipeclose+0x46>

000000008000502c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000502c:	711d                	addi	sp,sp,-96
    8000502e:	ec86                	sd	ra,88(sp)
    80005030:	e8a2                	sd	s0,80(sp)
    80005032:	e4a6                	sd	s1,72(sp)
    80005034:	e0ca                	sd	s2,64(sp)
    80005036:	fc4e                	sd	s3,56(sp)
    80005038:	f852                	sd	s4,48(sp)
    8000503a:	f456                	sd	s5,40(sp)
    8000503c:	f05a                	sd	s6,32(sp)
    8000503e:	ec5e                	sd	s7,24(sp)
    80005040:	e862                	sd	s8,16(sp)
    80005042:	1080                	addi	s0,sp,96
    80005044:	84aa                	mv	s1,a0
    80005046:	8aae                	mv	s5,a1
    80005048:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000504a:	ffffd097          	auipc	ra,0xffffd
    8000504e:	c26080e7          	jalr	-986(ra) # 80001c70 <myproc>
    80005052:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005054:	8526                	mv	a0,s1
    80005056:	ffffc097          	auipc	ra,0xffffc
    8000505a:	d0c080e7          	jalr	-756(ra) # 80000d62 <acquire>
  while(i < n){
    8000505e:	0b405663          	blez	s4,8000510a <pipewrite+0xde>
  int i = 0;
    80005062:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005064:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005066:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000506a:	21c48b93          	addi	s7,s1,540
    8000506e:	a089                	j	800050b0 <pipewrite+0x84>
      release(&pi->lock);
    80005070:	8526                	mv	a0,s1
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	da4080e7          	jalr	-604(ra) # 80000e16 <release>
      return -1;
    8000507a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000507c:	854a                	mv	a0,s2
    8000507e:	60e6                	ld	ra,88(sp)
    80005080:	6446                	ld	s0,80(sp)
    80005082:	64a6                	ld	s1,72(sp)
    80005084:	6906                	ld	s2,64(sp)
    80005086:	79e2                	ld	s3,56(sp)
    80005088:	7a42                	ld	s4,48(sp)
    8000508a:	7aa2                	ld	s5,40(sp)
    8000508c:	7b02                	ld	s6,32(sp)
    8000508e:	6be2                	ld	s7,24(sp)
    80005090:	6c42                	ld	s8,16(sp)
    80005092:	6125                	addi	sp,sp,96
    80005094:	8082                	ret
      wakeup(&pi->nread);
    80005096:	8562                	mv	a0,s8
    80005098:	ffffd097          	auipc	ra,0xffffd
    8000509c:	3d8080e7          	jalr	984(ra) # 80002470 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050a0:	85a6                	mv	a1,s1
    800050a2:	855e                	mv	a0,s7
    800050a4:	ffffd097          	auipc	ra,0xffffd
    800050a8:	368080e7          	jalr	872(ra) # 8000240c <sleep>
  while(i < n){
    800050ac:	07495063          	bge	s2,s4,8000510c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800050b0:	2204a783          	lw	a5,544(s1)
    800050b4:	dfd5                	beqz	a5,80005070 <pipewrite+0x44>
    800050b6:	854e                	mv	a0,s3
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	5fc080e7          	jalr	1532(ra) # 800026b4 <killed>
    800050c0:	f945                	bnez	a0,80005070 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050c2:	2184a783          	lw	a5,536(s1)
    800050c6:	21c4a703          	lw	a4,540(s1)
    800050ca:	2007879b          	addiw	a5,a5,512
    800050ce:	fcf704e3          	beq	a4,a5,80005096 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050d2:	4685                	li	a3,1
    800050d4:	01590633          	add	a2,s2,s5
    800050d8:	faf40593          	addi	a1,s0,-81
    800050dc:	0509b503          	ld	a0,80(s3)
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	7de080e7          	jalr	2014(ra) # 800018be <copyin>
    800050e8:	03650263          	beq	a0,s6,8000510c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050ec:	21c4a783          	lw	a5,540(s1)
    800050f0:	0017871b          	addiw	a4,a5,1
    800050f4:	20e4ae23          	sw	a4,540(s1)
    800050f8:	1ff7f793          	andi	a5,a5,511
    800050fc:	97a6                	add	a5,a5,s1
    800050fe:	faf44703          	lbu	a4,-81(s0)
    80005102:	00e78c23          	sb	a4,24(a5)
      i++;
    80005106:	2905                	addiw	s2,s2,1
    80005108:	b755                	j	800050ac <pipewrite+0x80>
  int i = 0;
    8000510a:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000510c:	21848513          	addi	a0,s1,536
    80005110:	ffffd097          	auipc	ra,0xffffd
    80005114:	360080e7          	jalr	864(ra) # 80002470 <wakeup>
  release(&pi->lock);
    80005118:	8526                	mv	a0,s1
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	cfc080e7          	jalr	-772(ra) # 80000e16 <release>
  return i;
    80005122:	bfa9                	j	8000507c <pipewrite+0x50>

0000000080005124 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005124:	715d                	addi	sp,sp,-80
    80005126:	e486                	sd	ra,72(sp)
    80005128:	e0a2                	sd	s0,64(sp)
    8000512a:	fc26                	sd	s1,56(sp)
    8000512c:	f84a                	sd	s2,48(sp)
    8000512e:	f44e                	sd	s3,40(sp)
    80005130:	f052                	sd	s4,32(sp)
    80005132:	ec56                	sd	s5,24(sp)
    80005134:	e85a                	sd	s6,16(sp)
    80005136:	0880                	addi	s0,sp,80
    80005138:	84aa                	mv	s1,a0
    8000513a:	892e                	mv	s2,a1
    8000513c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	b32080e7          	jalr	-1230(ra) # 80001c70 <myproc>
    80005146:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005148:	8526                	mv	a0,s1
    8000514a:	ffffc097          	auipc	ra,0xffffc
    8000514e:	c18080e7          	jalr	-1000(ra) # 80000d62 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005152:	2184a703          	lw	a4,536(s1)
    80005156:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000515a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000515e:	02f71763          	bne	a4,a5,8000518c <piperead+0x68>
    80005162:	2244a783          	lw	a5,548(s1)
    80005166:	c39d                	beqz	a5,8000518c <piperead+0x68>
    if(killed(pr)){
    80005168:	8552                	mv	a0,s4
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	54a080e7          	jalr	1354(ra) # 800026b4 <killed>
    80005172:	e949                	bnez	a0,80005204 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005174:	85a6                	mv	a1,s1
    80005176:	854e                	mv	a0,s3
    80005178:	ffffd097          	auipc	ra,0xffffd
    8000517c:	294080e7          	jalr	660(ra) # 8000240c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005180:	2184a703          	lw	a4,536(s1)
    80005184:	21c4a783          	lw	a5,540(s1)
    80005188:	fcf70de3          	beq	a4,a5,80005162 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000518c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000518e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005190:	05505463          	blez	s5,800051d8 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005194:	2184a783          	lw	a5,536(s1)
    80005198:	21c4a703          	lw	a4,540(s1)
    8000519c:	02f70e63          	beq	a4,a5,800051d8 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051a0:	0017871b          	addiw	a4,a5,1
    800051a4:	20e4ac23          	sw	a4,536(s1)
    800051a8:	1ff7f793          	andi	a5,a5,511
    800051ac:	97a6                	add	a5,a5,s1
    800051ae:	0187c783          	lbu	a5,24(a5)
    800051b2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051b6:	4685                	li	a3,1
    800051b8:	fbf40613          	addi	a2,s0,-65
    800051bc:	85ca                	mv	a1,s2
    800051be:	050a3503          	ld	a0,80(s4)
    800051c2:	ffffc097          	auipc	ra,0xffffc
    800051c6:	670080e7          	jalr	1648(ra) # 80001832 <copyout>
    800051ca:	01650763          	beq	a0,s6,800051d8 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051ce:	2985                	addiw	s3,s3,1
    800051d0:	0905                	addi	s2,s2,1
    800051d2:	fd3a91e3          	bne	s5,s3,80005194 <piperead+0x70>
    800051d6:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051d8:	21c48513          	addi	a0,s1,540
    800051dc:	ffffd097          	auipc	ra,0xffffd
    800051e0:	294080e7          	jalr	660(ra) # 80002470 <wakeup>
  release(&pi->lock);
    800051e4:	8526                	mv	a0,s1
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	c30080e7          	jalr	-976(ra) # 80000e16 <release>
  return i;
}
    800051ee:	854e                	mv	a0,s3
    800051f0:	60a6                	ld	ra,72(sp)
    800051f2:	6406                	ld	s0,64(sp)
    800051f4:	74e2                	ld	s1,56(sp)
    800051f6:	7942                	ld	s2,48(sp)
    800051f8:	79a2                	ld	s3,40(sp)
    800051fa:	7a02                	ld	s4,32(sp)
    800051fc:	6ae2                	ld	s5,24(sp)
    800051fe:	6b42                	ld	s6,16(sp)
    80005200:	6161                	addi	sp,sp,80
    80005202:	8082                	ret
      release(&pi->lock);
    80005204:	8526                	mv	a0,s1
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	c10080e7          	jalr	-1008(ra) # 80000e16 <release>
      return -1;
    8000520e:	59fd                	li	s3,-1
    80005210:	bff9                	j	800051ee <piperead+0xca>

0000000080005212 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005212:	1141                	addi	sp,sp,-16
    80005214:	e422                	sd	s0,8(sp)
    80005216:	0800                	addi	s0,sp,16
    80005218:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000521a:	8905                	andi	a0,a0,1
    8000521c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000521e:	8b89                	andi	a5,a5,2
    80005220:	c399                	beqz	a5,80005226 <flags2perm+0x14>
      perm |= PTE_W;
    80005222:	00456513          	ori	a0,a0,4
    return perm;
}
    80005226:	6422                	ld	s0,8(sp)
    80005228:	0141                	addi	sp,sp,16
    8000522a:	8082                	ret

000000008000522c <exec>:

int
exec(char *path, char **argv)
{
    8000522c:	de010113          	addi	sp,sp,-544
    80005230:	20113c23          	sd	ra,536(sp)
    80005234:	20813823          	sd	s0,528(sp)
    80005238:	20913423          	sd	s1,520(sp)
    8000523c:	21213023          	sd	s2,512(sp)
    80005240:	ffce                	sd	s3,504(sp)
    80005242:	fbd2                	sd	s4,496(sp)
    80005244:	f7d6                	sd	s5,488(sp)
    80005246:	f3da                	sd	s6,480(sp)
    80005248:	efde                	sd	s7,472(sp)
    8000524a:	ebe2                	sd	s8,464(sp)
    8000524c:	e7e6                	sd	s9,456(sp)
    8000524e:	e3ea                	sd	s10,448(sp)
    80005250:	ff6e                	sd	s11,440(sp)
    80005252:	1400                	addi	s0,sp,544
    80005254:	892a                	mv	s2,a0
    80005256:	dea43423          	sd	a0,-536(s0)
    8000525a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000525e:	ffffd097          	auipc	ra,0xffffd
    80005262:	a12080e7          	jalr	-1518(ra) # 80001c70 <myproc>
    80005266:	84aa                	mv	s1,a0

  begin_op();
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	482080e7          	jalr	1154(ra) # 800046ea <begin_op>

  if((ip = namei(path)) == 0){
    80005270:	854a                	mv	a0,s2
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	258080e7          	jalr	600(ra) # 800044ca <namei>
    8000527a:	c93d                	beqz	a0,800052f0 <exec+0xc4>
    8000527c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	aa0080e7          	jalr	-1376(ra) # 80003d1e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005286:	04000713          	li	a4,64
    8000528a:	4681                	li	a3,0
    8000528c:	e5040613          	addi	a2,s0,-432
    80005290:	4581                	li	a1,0
    80005292:	8556                	mv	a0,s5
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	d3e080e7          	jalr	-706(ra) # 80003fd2 <readi>
    8000529c:	04000793          	li	a5,64
    800052a0:	00f51a63          	bne	a0,a5,800052b4 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052a4:	e5042703          	lw	a4,-432(s0)
    800052a8:	464c47b7          	lui	a5,0x464c4
    800052ac:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052b0:	04f70663          	beq	a4,a5,800052fc <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052b4:	8556                	mv	a0,s5
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	cca080e7          	jalr	-822(ra) # 80003f80 <iunlockput>
    end_op();
    800052be:	fffff097          	auipc	ra,0xfffff
    800052c2:	4aa080e7          	jalr	1194(ra) # 80004768 <end_op>
  }
  return -1;
    800052c6:	557d                	li	a0,-1
}
    800052c8:	21813083          	ld	ra,536(sp)
    800052cc:	21013403          	ld	s0,528(sp)
    800052d0:	20813483          	ld	s1,520(sp)
    800052d4:	20013903          	ld	s2,512(sp)
    800052d8:	79fe                	ld	s3,504(sp)
    800052da:	7a5e                	ld	s4,496(sp)
    800052dc:	7abe                	ld	s5,488(sp)
    800052de:	7b1e                	ld	s6,480(sp)
    800052e0:	6bfe                	ld	s7,472(sp)
    800052e2:	6c5e                	ld	s8,464(sp)
    800052e4:	6cbe                	ld	s9,456(sp)
    800052e6:	6d1e                	ld	s10,448(sp)
    800052e8:	7dfa                	ld	s11,440(sp)
    800052ea:	22010113          	addi	sp,sp,544
    800052ee:	8082                	ret
    end_op();
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	478080e7          	jalr	1144(ra) # 80004768 <end_op>
    return -1;
    800052f8:	557d                	li	a0,-1
    800052fa:	b7f9                	j	800052c8 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800052fc:	8526                	mv	a0,s1
    800052fe:	ffffd097          	auipc	ra,0xffffd
    80005302:	a36080e7          	jalr	-1482(ra) # 80001d34 <proc_pagetable>
    80005306:	8b2a                	mv	s6,a0
    80005308:	d555                	beqz	a0,800052b4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000530a:	e7042783          	lw	a5,-400(s0)
    8000530e:	e8845703          	lhu	a4,-376(s0)
    80005312:	c735                	beqz	a4,8000537e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005314:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005316:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000531a:	6a05                	lui	s4,0x1
    8000531c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005320:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005324:	6d85                	lui	s11,0x1
    80005326:	7d7d                	lui	s10,0xfffff
    80005328:	ac3d                	j	80005566 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000532a:	00003517          	auipc	a0,0x3
    8000532e:	50e50513          	addi	a0,a0,1294 # 80008838 <syscalls+0x2a8>
    80005332:	ffffb097          	auipc	ra,0xffffb
    80005336:	20e080e7          	jalr	526(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000533a:	874a                	mv	a4,s2
    8000533c:	009c86bb          	addw	a3,s9,s1
    80005340:	4581                	li	a1,0
    80005342:	8556                	mv	a0,s5
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	c8e080e7          	jalr	-882(ra) # 80003fd2 <readi>
    8000534c:	2501                	sext.w	a0,a0
    8000534e:	1aa91963          	bne	s2,a0,80005500 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005352:	009d84bb          	addw	s1,s11,s1
    80005356:	013d09bb          	addw	s3,s10,s3
    8000535a:	1f74f663          	bgeu	s1,s7,80005546 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    8000535e:	02049593          	slli	a1,s1,0x20
    80005362:	9181                	srli	a1,a1,0x20
    80005364:	95e2                	add	a1,a1,s8
    80005366:	855a                	mv	a0,s6
    80005368:	ffffc097          	auipc	ra,0xffffc
    8000536c:	e80080e7          	jalr	-384(ra) # 800011e8 <walkaddr>
    80005370:	862a                	mv	a2,a0
    if(pa == 0)
    80005372:	dd45                	beqz	a0,8000532a <exec+0xfe>
      n = PGSIZE;
    80005374:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005376:	fd49f2e3          	bgeu	s3,s4,8000533a <exec+0x10e>
      n = sz - i;
    8000537a:	894e                	mv	s2,s3
    8000537c:	bf7d                	j	8000533a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000537e:	4901                	li	s2,0
  iunlockput(ip);
    80005380:	8556                	mv	a0,s5
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	bfe080e7          	jalr	-1026(ra) # 80003f80 <iunlockput>
  end_op();
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	3de080e7          	jalr	990(ra) # 80004768 <end_op>
  p = myproc();
    80005392:	ffffd097          	auipc	ra,0xffffd
    80005396:	8de080e7          	jalr	-1826(ra) # 80001c70 <myproc>
    8000539a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000539c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800053a0:	6785                	lui	a5,0x1
    800053a2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800053a4:	97ca                	add	a5,a5,s2
    800053a6:	777d                	lui	a4,0xfffff
    800053a8:	8ff9                	and	a5,a5,a4
    800053aa:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053ae:	4691                	li	a3,4
    800053b0:	6609                	lui	a2,0x2
    800053b2:	963e                	add	a2,a2,a5
    800053b4:	85be                	mv	a1,a5
    800053b6:	855a                	mv	a0,s6
    800053b8:	ffffc097          	auipc	ra,0xffffc
    800053bc:	212080e7          	jalr	530(ra) # 800015ca <uvmalloc>
    800053c0:	8c2a                	mv	s8,a0
  ip = 0;
    800053c2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053c4:	12050e63          	beqz	a0,80005500 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053c8:	75f9                	lui	a1,0xffffe
    800053ca:	95aa                	add	a1,a1,a0
    800053cc:	855a                	mv	a0,s6
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	432080e7          	jalr	1074(ra) # 80001800 <uvmclear>
  stackbase = sp - PGSIZE;
    800053d6:	7afd                	lui	s5,0xfffff
    800053d8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800053da:	df043783          	ld	a5,-528(s0)
    800053de:	6388                	ld	a0,0(a5)
    800053e0:	c925                	beqz	a0,80005450 <exec+0x224>
    800053e2:	e9040993          	addi	s3,s0,-368
    800053e6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053ea:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053ec:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800053ee:	ffffc097          	auipc	ra,0xffffc
    800053f2:	bec080e7          	jalr	-1044(ra) # 80000fda <strlen>
    800053f6:	0015079b          	addiw	a5,a0,1
    800053fa:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053fe:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005402:	13596663          	bltu	s2,s5,8000552e <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005406:	df043d83          	ld	s11,-528(s0)
    8000540a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000540e:	8552                	mv	a0,s4
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	bca080e7          	jalr	-1078(ra) # 80000fda <strlen>
    80005418:	0015069b          	addiw	a3,a0,1
    8000541c:	8652                	mv	a2,s4
    8000541e:	85ca                	mv	a1,s2
    80005420:	855a                	mv	a0,s6
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	410080e7          	jalr	1040(ra) # 80001832 <copyout>
    8000542a:	10054663          	bltz	a0,80005536 <exec+0x30a>
    ustack[argc] = sp;
    8000542e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005432:	0485                	addi	s1,s1,1
    80005434:	008d8793          	addi	a5,s11,8
    80005438:	def43823          	sd	a5,-528(s0)
    8000543c:	008db503          	ld	a0,8(s11)
    80005440:	c911                	beqz	a0,80005454 <exec+0x228>
    if(argc >= MAXARG)
    80005442:	09a1                	addi	s3,s3,8
    80005444:	fb3c95e3          	bne	s9,s3,800053ee <exec+0x1c2>
  sz = sz1;
    80005448:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000544c:	4a81                	li	s5,0
    8000544e:	a84d                	j	80005500 <exec+0x2d4>
  sp = sz;
    80005450:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005452:	4481                	li	s1,0
  ustack[argc] = 0;
    80005454:	00349793          	slli	a5,s1,0x3
    80005458:	f9078793          	addi	a5,a5,-112
    8000545c:	97a2                	add	a5,a5,s0
    8000545e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005462:	00148693          	addi	a3,s1,1
    80005466:	068e                	slli	a3,a3,0x3
    80005468:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000546c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005470:	01597663          	bgeu	s2,s5,8000547c <exec+0x250>
  sz = sz1;
    80005474:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005478:	4a81                	li	s5,0
    8000547a:	a059                	j	80005500 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000547c:	e9040613          	addi	a2,s0,-368
    80005480:	85ca                	mv	a1,s2
    80005482:	855a                	mv	a0,s6
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	3ae080e7          	jalr	942(ra) # 80001832 <copyout>
    8000548c:	0a054963          	bltz	a0,8000553e <exec+0x312>
  p->trapframe->a1 = sp;
    80005490:	058bb783          	ld	a5,88(s7)
    80005494:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005498:	de843783          	ld	a5,-536(s0)
    8000549c:	0007c703          	lbu	a4,0(a5)
    800054a0:	cf11                	beqz	a4,800054bc <exec+0x290>
    800054a2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054a4:	02f00693          	li	a3,47
    800054a8:	a039                	j	800054b6 <exec+0x28a>
      last = s+1;
    800054aa:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800054ae:	0785                	addi	a5,a5,1
    800054b0:	fff7c703          	lbu	a4,-1(a5)
    800054b4:	c701                	beqz	a4,800054bc <exec+0x290>
    if(*s == '/')
    800054b6:	fed71ce3          	bne	a4,a3,800054ae <exec+0x282>
    800054ba:	bfc5                	j	800054aa <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800054bc:	4641                	li	a2,16
    800054be:	de843583          	ld	a1,-536(s0)
    800054c2:	158b8513          	addi	a0,s7,344
    800054c6:	ffffc097          	auipc	ra,0xffffc
    800054ca:	ae2080e7          	jalr	-1310(ra) # 80000fa8 <safestrcpy>
  oldpagetable = p->pagetable;
    800054ce:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800054d2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800054d6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054da:	058bb783          	ld	a5,88(s7)
    800054de:	e6843703          	ld	a4,-408(s0)
    800054e2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054e4:	058bb783          	ld	a5,88(s7)
    800054e8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054ec:	85ea                	mv	a1,s10
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	8e2080e7          	jalr	-1822(ra) # 80001dd0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054f6:	0004851b          	sext.w	a0,s1
    800054fa:	b3f9                	j	800052c8 <exec+0x9c>
    800054fc:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005500:	df843583          	ld	a1,-520(s0)
    80005504:	855a                	mv	a0,s6
    80005506:	ffffd097          	auipc	ra,0xffffd
    8000550a:	8ca080e7          	jalr	-1846(ra) # 80001dd0 <proc_freepagetable>
  if(ip){
    8000550e:	da0a93e3          	bnez	s5,800052b4 <exec+0x88>
  return -1;
    80005512:	557d                	li	a0,-1
    80005514:	bb55                	j	800052c8 <exec+0x9c>
    80005516:	df243c23          	sd	s2,-520(s0)
    8000551a:	b7dd                	j	80005500 <exec+0x2d4>
    8000551c:	df243c23          	sd	s2,-520(s0)
    80005520:	b7c5                	j	80005500 <exec+0x2d4>
    80005522:	df243c23          	sd	s2,-520(s0)
    80005526:	bfe9                	j	80005500 <exec+0x2d4>
    80005528:	df243c23          	sd	s2,-520(s0)
    8000552c:	bfd1                	j	80005500 <exec+0x2d4>
  sz = sz1;
    8000552e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005532:	4a81                	li	s5,0
    80005534:	b7f1                	j	80005500 <exec+0x2d4>
  sz = sz1;
    80005536:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000553a:	4a81                	li	s5,0
    8000553c:	b7d1                	j	80005500 <exec+0x2d4>
  sz = sz1;
    8000553e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005542:	4a81                	li	s5,0
    80005544:	bf75                	j	80005500 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005546:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000554a:	e0843783          	ld	a5,-504(s0)
    8000554e:	0017869b          	addiw	a3,a5,1
    80005552:	e0d43423          	sd	a3,-504(s0)
    80005556:	e0043783          	ld	a5,-512(s0)
    8000555a:	0387879b          	addiw	a5,a5,56
    8000555e:	e8845703          	lhu	a4,-376(s0)
    80005562:	e0e6dfe3          	bge	a3,a4,80005380 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005566:	2781                	sext.w	a5,a5
    80005568:	e0f43023          	sd	a5,-512(s0)
    8000556c:	03800713          	li	a4,56
    80005570:	86be                	mv	a3,a5
    80005572:	e1840613          	addi	a2,s0,-488
    80005576:	4581                	li	a1,0
    80005578:	8556                	mv	a0,s5
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	a58080e7          	jalr	-1448(ra) # 80003fd2 <readi>
    80005582:	03800793          	li	a5,56
    80005586:	f6f51be3          	bne	a0,a5,800054fc <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000558a:	e1842783          	lw	a5,-488(s0)
    8000558e:	4705                	li	a4,1
    80005590:	fae79de3          	bne	a5,a4,8000554a <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005594:	e4043483          	ld	s1,-448(s0)
    80005598:	e3843783          	ld	a5,-456(s0)
    8000559c:	f6f4ede3          	bltu	s1,a5,80005516 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055a0:	e2843783          	ld	a5,-472(s0)
    800055a4:	94be                	add	s1,s1,a5
    800055a6:	f6f4ebe3          	bltu	s1,a5,8000551c <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800055aa:	de043703          	ld	a4,-544(s0)
    800055ae:	8ff9                	and	a5,a5,a4
    800055b0:	fbad                	bnez	a5,80005522 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055b2:	e1c42503          	lw	a0,-484(s0)
    800055b6:	00000097          	auipc	ra,0x0
    800055ba:	c5c080e7          	jalr	-932(ra) # 80005212 <flags2perm>
    800055be:	86aa                	mv	a3,a0
    800055c0:	8626                	mv	a2,s1
    800055c2:	85ca                	mv	a1,s2
    800055c4:	855a                	mv	a0,s6
    800055c6:	ffffc097          	auipc	ra,0xffffc
    800055ca:	004080e7          	jalr	4(ra) # 800015ca <uvmalloc>
    800055ce:	dea43c23          	sd	a0,-520(s0)
    800055d2:	d939                	beqz	a0,80005528 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055d4:	e2843c03          	ld	s8,-472(s0)
    800055d8:	e2042c83          	lw	s9,-480(s0)
    800055dc:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055e0:	f60b83e3          	beqz	s7,80005546 <exec+0x31a>
    800055e4:	89de                	mv	s3,s7
    800055e6:	4481                	li	s1,0
    800055e8:	bb9d                	j	8000535e <exec+0x132>

00000000800055ea <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055ea:	7179                	addi	sp,sp,-48
    800055ec:	f406                	sd	ra,40(sp)
    800055ee:	f022                	sd	s0,32(sp)
    800055f0:	ec26                	sd	s1,24(sp)
    800055f2:	e84a                	sd	s2,16(sp)
    800055f4:	1800                	addi	s0,sp,48
    800055f6:	892e                	mv	s2,a1
    800055f8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055fa:	fdc40593          	addi	a1,s0,-36
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	a6a080e7          	jalr	-1430(ra) # 80003068 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005606:	fdc42703          	lw	a4,-36(s0)
    8000560a:	47bd                	li	a5,15
    8000560c:	02e7eb63          	bltu	a5,a4,80005642 <argfd+0x58>
    80005610:	ffffc097          	auipc	ra,0xffffc
    80005614:	660080e7          	jalr	1632(ra) # 80001c70 <myproc>
    80005618:	fdc42703          	lw	a4,-36(s0)
    8000561c:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffbd10a>
    80005620:	078e                	slli	a5,a5,0x3
    80005622:	953e                	add	a0,a0,a5
    80005624:	611c                	ld	a5,0(a0)
    80005626:	c385                	beqz	a5,80005646 <argfd+0x5c>
    return -1;
  if(pfd)
    80005628:	00090463          	beqz	s2,80005630 <argfd+0x46>
    *pfd = fd;
    8000562c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005630:	4501                	li	a0,0
  if(pf)
    80005632:	c091                	beqz	s1,80005636 <argfd+0x4c>
    *pf = f;
    80005634:	e09c                	sd	a5,0(s1)
}
    80005636:	70a2                	ld	ra,40(sp)
    80005638:	7402                	ld	s0,32(sp)
    8000563a:	64e2                	ld	s1,24(sp)
    8000563c:	6942                	ld	s2,16(sp)
    8000563e:	6145                	addi	sp,sp,48
    80005640:	8082                	ret
    return -1;
    80005642:	557d                	li	a0,-1
    80005644:	bfcd                	j	80005636 <argfd+0x4c>
    80005646:	557d                	li	a0,-1
    80005648:	b7fd                	j	80005636 <argfd+0x4c>

000000008000564a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000564a:	1101                	addi	sp,sp,-32
    8000564c:	ec06                	sd	ra,24(sp)
    8000564e:	e822                	sd	s0,16(sp)
    80005650:	e426                	sd	s1,8(sp)
    80005652:	1000                	addi	s0,sp,32
    80005654:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005656:	ffffc097          	auipc	ra,0xffffc
    8000565a:	61a080e7          	jalr	1562(ra) # 80001c70 <myproc>
    8000565e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005660:	0d050793          	addi	a5,a0,208
    80005664:	4501                	li	a0,0
    80005666:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005668:	6398                	ld	a4,0(a5)
    8000566a:	cb19                	beqz	a4,80005680 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000566c:	2505                	addiw	a0,a0,1
    8000566e:	07a1                	addi	a5,a5,8
    80005670:	fed51ce3          	bne	a0,a3,80005668 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005674:	557d                	li	a0,-1
}
    80005676:	60e2                	ld	ra,24(sp)
    80005678:	6442                	ld	s0,16(sp)
    8000567a:	64a2                	ld	s1,8(sp)
    8000567c:	6105                	addi	sp,sp,32
    8000567e:	8082                	ret
      p->ofile[fd] = f;
    80005680:	01a50793          	addi	a5,a0,26
    80005684:	078e                	slli	a5,a5,0x3
    80005686:	963e                	add	a2,a2,a5
    80005688:	e204                	sd	s1,0(a2)
      return fd;
    8000568a:	b7f5                	j	80005676 <fdalloc+0x2c>

000000008000568c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000568c:	715d                	addi	sp,sp,-80
    8000568e:	e486                	sd	ra,72(sp)
    80005690:	e0a2                	sd	s0,64(sp)
    80005692:	fc26                	sd	s1,56(sp)
    80005694:	f84a                	sd	s2,48(sp)
    80005696:	f44e                	sd	s3,40(sp)
    80005698:	f052                	sd	s4,32(sp)
    8000569a:	ec56                	sd	s5,24(sp)
    8000569c:	e85a                	sd	s6,16(sp)
    8000569e:	0880                	addi	s0,sp,80
    800056a0:	8b2e                	mv	s6,a1
    800056a2:	89b2                	mv	s3,a2
    800056a4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056a6:	fb040593          	addi	a1,s0,-80
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	e3e080e7          	jalr	-450(ra) # 800044e8 <nameiparent>
    800056b2:	84aa                	mv	s1,a0
    800056b4:	14050f63          	beqz	a0,80005812 <create+0x186>
    return 0;

  ilock(dp);
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	666080e7          	jalr	1638(ra) # 80003d1e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056c0:	4601                	li	a2,0
    800056c2:	fb040593          	addi	a1,s0,-80
    800056c6:	8526                	mv	a0,s1
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	b3a080e7          	jalr	-1222(ra) # 80004202 <dirlookup>
    800056d0:	8aaa                	mv	s5,a0
    800056d2:	c931                	beqz	a0,80005726 <create+0x9a>
    iunlockput(dp);
    800056d4:	8526                	mv	a0,s1
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	8aa080e7          	jalr	-1878(ra) # 80003f80 <iunlockput>
    ilock(ip);
    800056de:	8556                	mv	a0,s5
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	63e080e7          	jalr	1598(ra) # 80003d1e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056e8:	000b059b          	sext.w	a1,s6
    800056ec:	4789                	li	a5,2
    800056ee:	02f59563          	bne	a1,a5,80005718 <create+0x8c>
    800056f2:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffbd134>
    800056f6:	37f9                	addiw	a5,a5,-2
    800056f8:	17c2                	slli	a5,a5,0x30
    800056fa:	93c1                	srli	a5,a5,0x30
    800056fc:	4705                	li	a4,1
    800056fe:	00f76d63          	bltu	a4,a5,80005718 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005702:	8556                	mv	a0,s5
    80005704:	60a6                	ld	ra,72(sp)
    80005706:	6406                	ld	s0,64(sp)
    80005708:	74e2                	ld	s1,56(sp)
    8000570a:	7942                	ld	s2,48(sp)
    8000570c:	79a2                	ld	s3,40(sp)
    8000570e:	7a02                	ld	s4,32(sp)
    80005710:	6ae2                	ld	s5,24(sp)
    80005712:	6b42                	ld	s6,16(sp)
    80005714:	6161                	addi	sp,sp,80
    80005716:	8082                	ret
    iunlockput(ip);
    80005718:	8556                	mv	a0,s5
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	866080e7          	jalr	-1946(ra) # 80003f80 <iunlockput>
    return 0;
    80005722:	4a81                	li	s5,0
    80005724:	bff9                	j	80005702 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005726:	85da                	mv	a1,s6
    80005728:	4088                	lw	a0,0(s1)
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	456080e7          	jalr	1110(ra) # 80003b80 <ialloc>
    80005732:	8a2a                	mv	s4,a0
    80005734:	c539                	beqz	a0,80005782 <create+0xf6>
  ilock(ip);
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	5e8080e7          	jalr	1512(ra) # 80003d1e <ilock>
  ip->major = major;
    8000573e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005742:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005746:	4905                	li	s2,1
    80005748:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000574c:	8552                	mv	a0,s4
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	504080e7          	jalr	1284(ra) # 80003c52 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005756:	000b059b          	sext.w	a1,s6
    8000575a:	03258b63          	beq	a1,s2,80005790 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000575e:	004a2603          	lw	a2,4(s4)
    80005762:	fb040593          	addi	a1,s0,-80
    80005766:	8526                	mv	a0,s1
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	cb0080e7          	jalr	-848(ra) # 80004418 <dirlink>
    80005770:	06054f63          	bltz	a0,800057ee <create+0x162>
  iunlockput(dp);
    80005774:	8526                	mv	a0,s1
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	80a080e7          	jalr	-2038(ra) # 80003f80 <iunlockput>
  return ip;
    8000577e:	8ad2                	mv	s5,s4
    80005780:	b749                	j	80005702 <create+0x76>
    iunlockput(dp);
    80005782:	8526                	mv	a0,s1
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	7fc080e7          	jalr	2044(ra) # 80003f80 <iunlockput>
    return 0;
    8000578c:	8ad2                	mv	s5,s4
    8000578e:	bf95                	j	80005702 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005790:	004a2603          	lw	a2,4(s4)
    80005794:	00003597          	auipc	a1,0x3
    80005798:	0c458593          	addi	a1,a1,196 # 80008858 <syscalls+0x2c8>
    8000579c:	8552                	mv	a0,s4
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	c7a080e7          	jalr	-902(ra) # 80004418 <dirlink>
    800057a6:	04054463          	bltz	a0,800057ee <create+0x162>
    800057aa:	40d0                	lw	a2,4(s1)
    800057ac:	00003597          	auipc	a1,0x3
    800057b0:	0b458593          	addi	a1,a1,180 # 80008860 <syscalls+0x2d0>
    800057b4:	8552                	mv	a0,s4
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	c62080e7          	jalr	-926(ra) # 80004418 <dirlink>
    800057be:	02054863          	bltz	a0,800057ee <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800057c2:	004a2603          	lw	a2,4(s4)
    800057c6:	fb040593          	addi	a1,s0,-80
    800057ca:	8526                	mv	a0,s1
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	c4c080e7          	jalr	-948(ra) # 80004418 <dirlink>
    800057d4:	00054d63          	bltz	a0,800057ee <create+0x162>
    dp->nlink++;  // for ".."
    800057d8:	04a4d783          	lhu	a5,74(s1)
    800057dc:	2785                	addiw	a5,a5,1
    800057de:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057e2:	8526                	mv	a0,s1
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	46e080e7          	jalr	1134(ra) # 80003c52 <iupdate>
    800057ec:	b761                	j	80005774 <create+0xe8>
  ip->nlink = 0;
    800057ee:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057f2:	8552                	mv	a0,s4
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	45e080e7          	jalr	1118(ra) # 80003c52 <iupdate>
  iunlockput(ip);
    800057fc:	8552                	mv	a0,s4
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	782080e7          	jalr	1922(ra) # 80003f80 <iunlockput>
  iunlockput(dp);
    80005806:	8526                	mv	a0,s1
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	778080e7          	jalr	1912(ra) # 80003f80 <iunlockput>
  return 0;
    80005810:	bdcd                	j	80005702 <create+0x76>
    return 0;
    80005812:	8aaa                	mv	s5,a0
    80005814:	b5fd                	j	80005702 <create+0x76>

0000000080005816 <sys_dup>:
{
    80005816:	7179                	addi	sp,sp,-48
    80005818:	f406                	sd	ra,40(sp)
    8000581a:	f022                	sd	s0,32(sp)
    8000581c:	ec26                	sd	s1,24(sp)
    8000581e:	e84a                	sd	s2,16(sp)
    80005820:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005822:	fd840613          	addi	a2,s0,-40
    80005826:	4581                	li	a1,0
    80005828:	4501                	li	a0,0
    8000582a:	00000097          	auipc	ra,0x0
    8000582e:	dc0080e7          	jalr	-576(ra) # 800055ea <argfd>
    return -1;
    80005832:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005834:	02054363          	bltz	a0,8000585a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005838:	fd843903          	ld	s2,-40(s0)
    8000583c:	854a                	mv	a0,s2
    8000583e:	00000097          	auipc	ra,0x0
    80005842:	e0c080e7          	jalr	-500(ra) # 8000564a <fdalloc>
    80005846:	84aa                	mv	s1,a0
    return -1;
    80005848:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000584a:	00054863          	bltz	a0,8000585a <sys_dup+0x44>
  filedup(f);
    8000584e:	854a                	mv	a0,s2
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	310080e7          	jalr	784(ra) # 80004b60 <filedup>
  return fd;
    80005858:	87a6                	mv	a5,s1
}
    8000585a:	853e                	mv	a0,a5
    8000585c:	70a2                	ld	ra,40(sp)
    8000585e:	7402                	ld	s0,32(sp)
    80005860:	64e2                	ld	s1,24(sp)
    80005862:	6942                	ld	s2,16(sp)
    80005864:	6145                	addi	sp,sp,48
    80005866:	8082                	ret

0000000080005868 <sys_read>:
{
    80005868:	7179                	addi	sp,sp,-48
    8000586a:	f406                	sd	ra,40(sp)
    8000586c:	f022                	sd	s0,32(sp)
    8000586e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005870:	fd840593          	addi	a1,s0,-40
    80005874:	4505                	li	a0,1
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	812080e7          	jalr	-2030(ra) # 80003088 <argaddr>
  argint(2, &n);
    8000587e:	fe440593          	addi	a1,s0,-28
    80005882:	4509                	li	a0,2
    80005884:	ffffd097          	auipc	ra,0xffffd
    80005888:	7e4080e7          	jalr	2020(ra) # 80003068 <argint>
  if(argfd(0, 0, &f) < 0)
    8000588c:	fe840613          	addi	a2,s0,-24
    80005890:	4581                	li	a1,0
    80005892:	4501                	li	a0,0
    80005894:	00000097          	auipc	ra,0x0
    80005898:	d56080e7          	jalr	-682(ra) # 800055ea <argfd>
    8000589c:	87aa                	mv	a5,a0
    return -1;
    8000589e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058a0:	0007cc63          	bltz	a5,800058b8 <sys_read+0x50>
  return fileread(f, p, n);
    800058a4:	fe442603          	lw	a2,-28(s0)
    800058a8:	fd843583          	ld	a1,-40(s0)
    800058ac:	fe843503          	ld	a0,-24(s0)
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	43c080e7          	jalr	1084(ra) # 80004cec <fileread>
}
    800058b8:	70a2                	ld	ra,40(sp)
    800058ba:	7402                	ld	s0,32(sp)
    800058bc:	6145                	addi	sp,sp,48
    800058be:	8082                	ret

00000000800058c0 <sys_write>:
{
    800058c0:	7179                	addi	sp,sp,-48
    800058c2:	f406                	sd	ra,40(sp)
    800058c4:	f022                	sd	s0,32(sp)
    800058c6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058c8:	fd840593          	addi	a1,s0,-40
    800058cc:	4505                	li	a0,1
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	7ba080e7          	jalr	1978(ra) # 80003088 <argaddr>
  argint(2, &n);
    800058d6:	fe440593          	addi	a1,s0,-28
    800058da:	4509                	li	a0,2
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	78c080e7          	jalr	1932(ra) # 80003068 <argint>
  if(argfd(0, 0, &f) < 0)
    800058e4:	fe840613          	addi	a2,s0,-24
    800058e8:	4581                	li	a1,0
    800058ea:	4501                	li	a0,0
    800058ec:	00000097          	auipc	ra,0x0
    800058f0:	cfe080e7          	jalr	-770(ra) # 800055ea <argfd>
    800058f4:	87aa                	mv	a5,a0
    return -1;
    800058f6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058f8:	0007cc63          	bltz	a5,80005910 <sys_write+0x50>
  return filewrite(f, p, n);
    800058fc:	fe442603          	lw	a2,-28(s0)
    80005900:	fd843583          	ld	a1,-40(s0)
    80005904:	fe843503          	ld	a0,-24(s0)
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	4a6080e7          	jalr	1190(ra) # 80004dae <filewrite>
}
    80005910:	70a2                	ld	ra,40(sp)
    80005912:	7402                	ld	s0,32(sp)
    80005914:	6145                	addi	sp,sp,48
    80005916:	8082                	ret

0000000080005918 <sys_close>:
{
    80005918:	1101                	addi	sp,sp,-32
    8000591a:	ec06                	sd	ra,24(sp)
    8000591c:	e822                	sd	s0,16(sp)
    8000591e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005920:	fe040613          	addi	a2,s0,-32
    80005924:	fec40593          	addi	a1,s0,-20
    80005928:	4501                	li	a0,0
    8000592a:	00000097          	auipc	ra,0x0
    8000592e:	cc0080e7          	jalr	-832(ra) # 800055ea <argfd>
    return -1;
    80005932:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005934:	02054463          	bltz	a0,8000595c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005938:	ffffc097          	auipc	ra,0xffffc
    8000593c:	338080e7          	jalr	824(ra) # 80001c70 <myproc>
    80005940:	fec42783          	lw	a5,-20(s0)
    80005944:	07e9                	addi	a5,a5,26
    80005946:	078e                	slli	a5,a5,0x3
    80005948:	953e                	add	a0,a0,a5
    8000594a:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000594e:	fe043503          	ld	a0,-32(s0)
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	260080e7          	jalr	608(ra) # 80004bb2 <fileclose>
  return 0;
    8000595a:	4781                	li	a5,0
}
    8000595c:	853e                	mv	a0,a5
    8000595e:	60e2                	ld	ra,24(sp)
    80005960:	6442                	ld	s0,16(sp)
    80005962:	6105                	addi	sp,sp,32
    80005964:	8082                	ret

0000000080005966 <sys_fstat>:
{
    80005966:	1101                	addi	sp,sp,-32
    80005968:	ec06                	sd	ra,24(sp)
    8000596a:	e822                	sd	s0,16(sp)
    8000596c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000596e:	fe040593          	addi	a1,s0,-32
    80005972:	4505                	li	a0,1
    80005974:	ffffd097          	auipc	ra,0xffffd
    80005978:	714080e7          	jalr	1812(ra) # 80003088 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000597c:	fe840613          	addi	a2,s0,-24
    80005980:	4581                	li	a1,0
    80005982:	4501                	li	a0,0
    80005984:	00000097          	auipc	ra,0x0
    80005988:	c66080e7          	jalr	-922(ra) # 800055ea <argfd>
    8000598c:	87aa                	mv	a5,a0
    return -1;
    8000598e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005990:	0007ca63          	bltz	a5,800059a4 <sys_fstat+0x3e>
  return filestat(f, st);
    80005994:	fe043583          	ld	a1,-32(s0)
    80005998:	fe843503          	ld	a0,-24(s0)
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	2de080e7          	jalr	734(ra) # 80004c7a <filestat>
}
    800059a4:	60e2                	ld	ra,24(sp)
    800059a6:	6442                	ld	s0,16(sp)
    800059a8:	6105                	addi	sp,sp,32
    800059aa:	8082                	ret

00000000800059ac <sys_link>:
{
    800059ac:	7169                	addi	sp,sp,-304
    800059ae:	f606                	sd	ra,296(sp)
    800059b0:	f222                	sd	s0,288(sp)
    800059b2:	ee26                	sd	s1,280(sp)
    800059b4:	ea4a                	sd	s2,272(sp)
    800059b6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059b8:	08000613          	li	a2,128
    800059bc:	ed040593          	addi	a1,s0,-304
    800059c0:	4501                	li	a0,0
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	6e6080e7          	jalr	1766(ra) # 800030a8 <argstr>
    return -1;
    800059ca:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059cc:	10054e63          	bltz	a0,80005ae8 <sys_link+0x13c>
    800059d0:	08000613          	li	a2,128
    800059d4:	f5040593          	addi	a1,s0,-176
    800059d8:	4505                	li	a0,1
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	6ce080e7          	jalr	1742(ra) # 800030a8 <argstr>
    return -1;
    800059e2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059e4:	10054263          	bltz	a0,80005ae8 <sys_link+0x13c>
  begin_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	d02080e7          	jalr	-766(ra) # 800046ea <begin_op>
  if((ip = namei(old)) == 0){
    800059f0:	ed040513          	addi	a0,s0,-304
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	ad6080e7          	jalr	-1322(ra) # 800044ca <namei>
    800059fc:	84aa                	mv	s1,a0
    800059fe:	c551                	beqz	a0,80005a8a <sys_link+0xde>
  ilock(ip);
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	31e080e7          	jalr	798(ra) # 80003d1e <ilock>
  if(ip->type == T_DIR){
    80005a08:	04449703          	lh	a4,68(s1)
    80005a0c:	4785                	li	a5,1
    80005a0e:	08f70463          	beq	a4,a5,80005a96 <sys_link+0xea>
  ip->nlink++;
    80005a12:	04a4d783          	lhu	a5,74(s1)
    80005a16:	2785                	addiw	a5,a5,1
    80005a18:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	234080e7          	jalr	564(ra) # 80003c52 <iupdate>
  iunlock(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	3b8080e7          	jalr	952(ra) # 80003de0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a30:	fd040593          	addi	a1,s0,-48
    80005a34:	f5040513          	addi	a0,s0,-176
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	ab0080e7          	jalr	-1360(ra) # 800044e8 <nameiparent>
    80005a40:	892a                	mv	s2,a0
    80005a42:	c935                	beqz	a0,80005ab6 <sys_link+0x10a>
  ilock(dp);
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	2da080e7          	jalr	730(ra) # 80003d1e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a4c:	00092703          	lw	a4,0(s2)
    80005a50:	409c                	lw	a5,0(s1)
    80005a52:	04f71d63          	bne	a4,a5,80005aac <sys_link+0x100>
    80005a56:	40d0                	lw	a2,4(s1)
    80005a58:	fd040593          	addi	a1,s0,-48
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	9ba080e7          	jalr	-1606(ra) # 80004418 <dirlink>
    80005a66:	04054363          	bltz	a0,80005aac <sys_link+0x100>
  iunlockput(dp);
    80005a6a:	854a                	mv	a0,s2
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	514080e7          	jalr	1300(ra) # 80003f80 <iunlockput>
  iput(ip);
    80005a74:	8526                	mv	a0,s1
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	462080e7          	jalr	1122(ra) # 80003ed8 <iput>
  end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	cea080e7          	jalr	-790(ra) # 80004768 <end_op>
  return 0;
    80005a86:	4781                	li	a5,0
    80005a88:	a085                	j	80005ae8 <sys_link+0x13c>
    end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	cde080e7          	jalr	-802(ra) # 80004768 <end_op>
    return -1;
    80005a92:	57fd                	li	a5,-1
    80005a94:	a891                	j	80005ae8 <sys_link+0x13c>
    iunlockput(ip);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	4e8080e7          	jalr	1256(ra) # 80003f80 <iunlockput>
    end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	cc8080e7          	jalr	-824(ra) # 80004768 <end_op>
    return -1;
    80005aa8:	57fd                	li	a5,-1
    80005aaa:	a83d                	j	80005ae8 <sys_link+0x13c>
    iunlockput(dp);
    80005aac:	854a                	mv	a0,s2
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	4d2080e7          	jalr	1234(ra) # 80003f80 <iunlockput>
  ilock(ip);
    80005ab6:	8526                	mv	a0,s1
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	266080e7          	jalr	614(ra) # 80003d1e <ilock>
  ip->nlink--;
    80005ac0:	04a4d783          	lhu	a5,74(s1)
    80005ac4:	37fd                	addiw	a5,a5,-1
    80005ac6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aca:	8526                	mv	a0,s1
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	186080e7          	jalr	390(ra) # 80003c52 <iupdate>
  iunlockput(ip);
    80005ad4:	8526                	mv	a0,s1
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	4aa080e7          	jalr	1194(ra) # 80003f80 <iunlockput>
  end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	c8a080e7          	jalr	-886(ra) # 80004768 <end_op>
  return -1;
    80005ae6:	57fd                	li	a5,-1
}
    80005ae8:	853e                	mv	a0,a5
    80005aea:	70b2                	ld	ra,296(sp)
    80005aec:	7412                	ld	s0,288(sp)
    80005aee:	64f2                	ld	s1,280(sp)
    80005af0:	6952                	ld	s2,272(sp)
    80005af2:	6155                	addi	sp,sp,304
    80005af4:	8082                	ret

0000000080005af6 <sys_unlink>:
{
    80005af6:	7151                	addi	sp,sp,-240
    80005af8:	f586                	sd	ra,232(sp)
    80005afa:	f1a2                	sd	s0,224(sp)
    80005afc:	eda6                	sd	s1,216(sp)
    80005afe:	e9ca                	sd	s2,208(sp)
    80005b00:	e5ce                	sd	s3,200(sp)
    80005b02:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b04:	08000613          	li	a2,128
    80005b08:	f3040593          	addi	a1,s0,-208
    80005b0c:	4501                	li	a0,0
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	59a080e7          	jalr	1434(ra) # 800030a8 <argstr>
    80005b16:	18054163          	bltz	a0,80005c98 <sys_unlink+0x1a2>
  begin_op();
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	bd0080e7          	jalr	-1072(ra) # 800046ea <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b22:	fb040593          	addi	a1,s0,-80
    80005b26:	f3040513          	addi	a0,s0,-208
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	9be080e7          	jalr	-1602(ra) # 800044e8 <nameiparent>
    80005b32:	84aa                	mv	s1,a0
    80005b34:	c979                	beqz	a0,80005c0a <sys_unlink+0x114>
  ilock(dp);
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	1e8080e7          	jalr	488(ra) # 80003d1e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b3e:	00003597          	auipc	a1,0x3
    80005b42:	d1a58593          	addi	a1,a1,-742 # 80008858 <syscalls+0x2c8>
    80005b46:	fb040513          	addi	a0,s0,-80
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	69e080e7          	jalr	1694(ra) # 800041e8 <namecmp>
    80005b52:	14050a63          	beqz	a0,80005ca6 <sys_unlink+0x1b0>
    80005b56:	00003597          	auipc	a1,0x3
    80005b5a:	d0a58593          	addi	a1,a1,-758 # 80008860 <syscalls+0x2d0>
    80005b5e:	fb040513          	addi	a0,s0,-80
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	686080e7          	jalr	1670(ra) # 800041e8 <namecmp>
    80005b6a:	12050e63          	beqz	a0,80005ca6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b6e:	f2c40613          	addi	a2,s0,-212
    80005b72:	fb040593          	addi	a1,s0,-80
    80005b76:	8526                	mv	a0,s1
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	68a080e7          	jalr	1674(ra) # 80004202 <dirlookup>
    80005b80:	892a                	mv	s2,a0
    80005b82:	12050263          	beqz	a0,80005ca6 <sys_unlink+0x1b0>
  ilock(ip);
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	198080e7          	jalr	408(ra) # 80003d1e <ilock>
  if(ip->nlink < 1)
    80005b8e:	04a91783          	lh	a5,74(s2)
    80005b92:	08f05263          	blez	a5,80005c16 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b96:	04491703          	lh	a4,68(s2)
    80005b9a:	4785                	li	a5,1
    80005b9c:	08f70563          	beq	a4,a5,80005c26 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ba0:	4641                	li	a2,16
    80005ba2:	4581                	li	a1,0
    80005ba4:	fc040513          	addi	a0,s0,-64
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	2b6080e7          	jalr	694(ra) # 80000e5e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bb0:	4741                	li	a4,16
    80005bb2:	f2c42683          	lw	a3,-212(s0)
    80005bb6:	fc040613          	addi	a2,s0,-64
    80005bba:	4581                	li	a1,0
    80005bbc:	8526                	mv	a0,s1
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	50c080e7          	jalr	1292(ra) # 800040ca <writei>
    80005bc6:	47c1                	li	a5,16
    80005bc8:	0af51563          	bne	a0,a5,80005c72 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bcc:	04491703          	lh	a4,68(s2)
    80005bd0:	4785                	li	a5,1
    80005bd2:	0af70863          	beq	a4,a5,80005c82 <sys_unlink+0x18c>
  iunlockput(dp);
    80005bd6:	8526                	mv	a0,s1
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	3a8080e7          	jalr	936(ra) # 80003f80 <iunlockput>
  ip->nlink--;
    80005be0:	04a95783          	lhu	a5,74(s2)
    80005be4:	37fd                	addiw	a5,a5,-1
    80005be6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bea:	854a                	mv	a0,s2
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	066080e7          	jalr	102(ra) # 80003c52 <iupdate>
  iunlockput(ip);
    80005bf4:	854a                	mv	a0,s2
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	38a080e7          	jalr	906(ra) # 80003f80 <iunlockput>
  end_op();
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	b6a080e7          	jalr	-1174(ra) # 80004768 <end_op>
  return 0;
    80005c06:	4501                	li	a0,0
    80005c08:	a84d                	j	80005cba <sys_unlink+0x1c4>
    end_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	b5e080e7          	jalr	-1186(ra) # 80004768 <end_op>
    return -1;
    80005c12:	557d                	li	a0,-1
    80005c14:	a05d                	j	80005cba <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c16:	00003517          	auipc	a0,0x3
    80005c1a:	c5250513          	addi	a0,a0,-942 # 80008868 <syscalls+0x2d8>
    80005c1e:	ffffb097          	auipc	ra,0xffffb
    80005c22:	922080e7          	jalr	-1758(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c26:	04c92703          	lw	a4,76(s2)
    80005c2a:	02000793          	li	a5,32
    80005c2e:	f6e7f9e3          	bgeu	a5,a4,80005ba0 <sys_unlink+0xaa>
    80005c32:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c36:	4741                	li	a4,16
    80005c38:	86ce                	mv	a3,s3
    80005c3a:	f1840613          	addi	a2,s0,-232
    80005c3e:	4581                	li	a1,0
    80005c40:	854a                	mv	a0,s2
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	390080e7          	jalr	912(ra) # 80003fd2 <readi>
    80005c4a:	47c1                	li	a5,16
    80005c4c:	00f51b63          	bne	a0,a5,80005c62 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c50:	f1845783          	lhu	a5,-232(s0)
    80005c54:	e7a1                	bnez	a5,80005c9c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c56:	29c1                	addiw	s3,s3,16
    80005c58:	04c92783          	lw	a5,76(s2)
    80005c5c:	fcf9ede3          	bltu	s3,a5,80005c36 <sys_unlink+0x140>
    80005c60:	b781                	j	80005ba0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c62:	00003517          	auipc	a0,0x3
    80005c66:	c1e50513          	addi	a0,a0,-994 # 80008880 <syscalls+0x2f0>
    80005c6a:	ffffb097          	auipc	ra,0xffffb
    80005c6e:	8d6080e7          	jalr	-1834(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005c72:	00003517          	auipc	a0,0x3
    80005c76:	c2650513          	addi	a0,a0,-986 # 80008898 <syscalls+0x308>
    80005c7a:	ffffb097          	auipc	ra,0xffffb
    80005c7e:	8c6080e7          	jalr	-1850(ra) # 80000540 <panic>
    dp->nlink--;
    80005c82:	04a4d783          	lhu	a5,74(s1)
    80005c86:	37fd                	addiw	a5,a5,-1
    80005c88:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c8c:	8526                	mv	a0,s1
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	fc4080e7          	jalr	-60(ra) # 80003c52 <iupdate>
    80005c96:	b781                	j	80005bd6 <sys_unlink+0xe0>
    return -1;
    80005c98:	557d                	li	a0,-1
    80005c9a:	a005                	j	80005cba <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c9c:	854a                	mv	a0,s2
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	2e2080e7          	jalr	738(ra) # 80003f80 <iunlockput>
  iunlockput(dp);
    80005ca6:	8526                	mv	a0,s1
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	2d8080e7          	jalr	728(ra) # 80003f80 <iunlockput>
  end_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	ab8080e7          	jalr	-1352(ra) # 80004768 <end_op>
  return -1;
    80005cb8:	557d                	li	a0,-1
}
    80005cba:	70ae                	ld	ra,232(sp)
    80005cbc:	740e                	ld	s0,224(sp)
    80005cbe:	64ee                	ld	s1,216(sp)
    80005cc0:	694e                	ld	s2,208(sp)
    80005cc2:	69ae                	ld	s3,200(sp)
    80005cc4:	616d                	addi	sp,sp,240
    80005cc6:	8082                	ret

0000000080005cc8 <sys_open>:

uint64
sys_open(void)
{
    80005cc8:	7131                	addi	sp,sp,-192
    80005cca:	fd06                	sd	ra,184(sp)
    80005ccc:	f922                	sd	s0,176(sp)
    80005cce:	f526                	sd	s1,168(sp)
    80005cd0:	f14a                	sd	s2,160(sp)
    80005cd2:	ed4e                	sd	s3,152(sp)
    80005cd4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005cd6:	f4c40593          	addi	a1,s0,-180
    80005cda:	4505                	li	a0,1
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	38c080e7          	jalr	908(ra) # 80003068 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ce4:	08000613          	li	a2,128
    80005ce8:	f5040593          	addi	a1,s0,-176
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	3ba080e7          	jalr	954(ra) # 800030a8 <argstr>
    80005cf6:	87aa                	mv	a5,a0
    return -1;
    80005cf8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cfa:	0a07c963          	bltz	a5,80005dac <sys_open+0xe4>

  begin_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	9ec080e7          	jalr	-1556(ra) # 800046ea <begin_op>

  if(omode & O_CREATE){
    80005d06:	f4c42783          	lw	a5,-180(s0)
    80005d0a:	2007f793          	andi	a5,a5,512
    80005d0e:	cfc5                	beqz	a5,80005dc6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d10:	4681                	li	a3,0
    80005d12:	4601                	li	a2,0
    80005d14:	4589                	li	a1,2
    80005d16:	f5040513          	addi	a0,s0,-176
    80005d1a:	00000097          	auipc	ra,0x0
    80005d1e:	972080e7          	jalr	-1678(ra) # 8000568c <create>
    80005d22:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d24:	c959                	beqz	a0,80005dba <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d26:	04449703          	lh	a4,68(s1)
    80005d2a:	478d                	li	a5,3
    80005d2c:	00f71763          	bne	a4,a5,80005d3a <sys_open+0x72>
    80005d30:	0464d703          	lhu	a4,70(s1)
    80005d34:	47a5                	li	a5,9
    80005d36:	0ce7ed63          	bltu	a5,a4,80005e10 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	dbc080e7          	jalr	-580(ra) # 80004af6 <filealloc>
    80005d42:	89aa                	mv	s3,a0
    80005d44:	10050363          	beqz	a0,80005e4a <sys_open+0x182>
    80005d48:	00000097          	auipc	ra,0x0
    80005d4c:	902080e7          	jalr	-1790(ra) # 8000564a <fdalloc>
    80005d50:	892a                	mv	s2,a0
    80005d52:	0e054763          	bltz	a0,80005e40 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d56:	04449703          	lh	a4,68(s1)
    80005d5a:	478d                	li	a5,3
    80005d5c:	0cf70563          	beq	a4,a5,80005e26 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d60:	4789                	li	a5,2
    80005d62:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d66:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d6a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d6e:	f4c42783          	lw	a5,-180(s0)
    80005d72:	0017c713          	xori	a4,a5,1
    80005d76:	8b05                	andi	a4,a4,1
    80005d78:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d7c:	0037f713          	andi	a4,a5,3
    80005d80:	00e03733          	snez	a4,a4
    80005d84:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d88:	4007f793          	andi	a5,a5,1024
    80005d8c:	c791                	beqz	a5,80005d98 <sys_open+0xd0>
    80005d8e:	04449703          	lh	a4,68(s1)
    80005d92:	4789                	li	a5,2
    80005d94:	0af70063          	beq	a4,a5,80005e34 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d98:	8526                	mv	a0,s1
    80005d9a:	ffffe097          	auipc	ra,0xffffe
    80005d9e:	046080e7          	jalr	70(ra) # 80003de0 <iunlock>
  end_op();
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	9c6080e7          	jalr	-1594(ra) # 80004768 <end_op>

  return fd;
    80005daa:	854a                	mv	a0,s2
}
    80005dac:	70ea                	ld	ra,184(sp)
    80005dae:	744a                	ld	s0,176(sp)
    80005db0:	74aa                	ld	s1,168(sp)
    80005db2:	790a                	ld	s2,160(sp)
    80005db4:	69ea                	ld	s3,152(sp)
    80005db6:	6129                	addi	sp,sp,192
    80005db8:	8082                	ret
      end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	9ae080e7          	jalr	-1618(ra) # 80004768 <end_op>
      return -1;
    80005dc2:	557d                	li	a0,-1
    80005dc4:	b7e5                	j	80005dac <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005dc6:	f5040513          	addi	a0,s0,-176
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	700080e7          	jalr	1792(ra) # 800044ca <namei>
    80005dd2:	84aa                	mv	s1,a0
    80005dd4:	c905                	beqz	a0,80005e04 <sys_open+0x13c>
    ilock(ip);
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	f48080e7          	jalr	-184(ra) # 80003d1e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005dde:	04449703          	lh	a4,68(s1)
    80005de2:	4785                	li	a5,1
    80005de4:	f4f711e3          	bne	a4,a5,80005d26 <sys_open+0x5e>
    80005de8:	f4c42783          	lw	a5,-180(s0)
    80005dec:	d7b9                	beqz	a5,80005d3a <sys_open+0x72>
      iunlockput(ip);
    80005dee:	8526                	mv	a0,s1
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	190080e7          	jalr	400(ra) # 80003f80 <iunlockput>
      end_op();
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	970080e7          	jalr	-1680(ra) # 80004768 <end_op>
      return -1;
    80005e00:	557d                	li	a0,-1
    80005e02:	b76d                	j	80005dac <sys_open+0xe4>
      end_op();
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	964080e7          	jalr	-1692(ra) # 80004768 <end_op>
      return -1;
    80005e0c:	557d                	li	a0,-1
    80005e0e:	bf79                	j	80005dac <sys_open+0xe4>
    iunlockput(ip);
    80005e10:	8526                	mv	a0,s1
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	16e080e7          	jalr	366(ra) # 80003f80 <iunlockput>
    end_op();
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	94e080e7          	jalr	-1714(ra) # 80004768 <end_op>
    return -1;
    80005e22:	557d                	li	a0,-1
    80005e24:	b761                	j	80005dac <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e26:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e2a:	04649783          	lh	a5,70(s1)
    80005e2e:	02f99223          	sh	a5,36(s3)
    80005e32:	bf25                	j	80005d6a <sys_open+0xa2>
    itrunc(ip);
    80005e34:	8526                	mv	a0,s1
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	ff6080e7          	jalr	-10(ra) # 80003e2c <itrunc>
    80005e3e:	bfa9                	j	80005d98 <sys_open+0xd0>
      fileclose(f);
    80005e40:	854e                	mv	a0,s3
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	d70080e7          	jalr	-656(ra) # 80004bb2 <fileclose>
    iunlockput(ip);
    80005e4a:	8526                	mv	a0,s1
    80005e4c:	ffffe097          	auipc	ra,0xffffe
    80005e50:	134080e7          	jalr	308(ra) # 80003f80 <iunlockput>
    end_op();
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	914080e7          	jalr	-1772(ra) # 80004768 <end_op>
    return -1;
    80005e5c:	557d                	li	a0,-1
    80005e5e:	b7b9                	j	80005dac <sys_open+0xe4>

0000000080005e60 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e60:	7175                	addi	sp,sp,-144
    80005e62:	e506                	sd	ra,136(sp)
    80005e64:	e122                	sd	s0,128(sp)
    80005e66:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	882080e7          	jalr	-1918(ra) # 800046ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e70:	08000613          	li	a2,128
    80005e74:	f7040593          	addi	a1,s0,-144
    80005e78:	4501                	li	a0,0
    80005e7a:	ffffd097          	auipc	ra,0xffffd
    80005e7e:	22e080e7          	jalr	558(ra) # 800030a8 <argstr>
    80005e82:	02054963          	bltz	a0,80005eb4 <sys_mkdir+0x54>
    80005e86:	4681                	li	a3,0
    80005e88:	4601                	li	a2,0
    80005e8a:	4585                	li	a1,1
    80005e8c:	f7040513          	addi	a0,s0,-144
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	7fc080e7          	jalr	2044(ra) # 8000568c <create>
    80005e98:	cd11                	beqz	a0,80005eb4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	0e6080e7          	jalr	230(ra) # 80003f80 <iunlockput>
  end_op();
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	8c6080e7          	jalr	-1850(ra) # 80004768 <end_op>
  return 0;
    80005eaa:	4501                	li	a0,0
}
    80005eac:	60aa                	ld	ra,136(sp)
    80005eae:	640a                	ld	s0,128(sp)
    80005eb0:	6149                	addi	sp,sp,144
    80005eb2:	8082                	ret
    end_op();
    80005eb4:	fffff097          	auipc	ra,0xfffff
    80005eb8:	8b4080e7          	jalr	-1868(ra) # 80004768 <end_op>
    return -1;
    80005ebc:	557d                	li	a0,-1
    80005ebe:	b7fd                	j	80005eac <sys_mkdir+0x4c>

0000000080005ec0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ec0:	7135                	addi	sp,sp,-160
    80005ec2:	ed06                	sd	ra,152(sp)
    80005ec4:	e922                	sd	s0,144(sp)
    80005ec6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	822080e7          	jalr	-2014(ra) # 800046ea <begin_op>
  argint(1, &major);
    80005ed0:	f6c40593          	addi	a1,s0,-148
    80005ed4:	4505                	li	a0,1
    80005ed6:	ffffd097          	auipc	ra,0xffffd
    80005eda:	192080e7          	jalr	402(ra) # 80003068 <argint>
  argint(2, &minor);
    80005ede:	f6840593          	addi	a1,s0,-152
    80005ee2:	4509                	li	a0,2
    80005ee4:	ffffd097          	auipc	ra,0xffffd
    80005ee8:	184080e7          	jalr	388(ra) # 80003068 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005eec:	08000613          	li	a2,128
    80005ef0:	f7040593          	addi	a1,s0,-144
    80005ef4:	4501                	li	a0,0
    80005ef6:	ffffd097          	auipc	ra,0xffffd
    80005efa:	1b2080e7          	jalr	434(ra) # 800030a8 <argstr>
    80005efe:	02054b63          	bltz	a0,80005f34 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f02:	f6841683          	lh	a3,-152(s0)
    80005f06:	f6c41603          	lh	a2,-148(s0)
    80005f0a:	458d                	li	a1,3
    80005f0c:	f7040513          	addi	a0,s0,-144
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	77c080e7          	jalr	1916(ra) # 8000568c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f18:	cd11                	beqz	a0,80005f34 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	066080e7          	jalr	102(ra) # 80003f80 <iunlockput>
  end_op();
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	846080e7          	jalr	-1978(ra) # 80004768 <end_op>
  return 0;
    80005f2a:	4501                	li	a0,0
}
    80005f2c:	60ea                	ld	ra,152(sp)
    80005f2e:	644a                	ld	s0,144(sp)
    80005f30:	610d                	addi	sp,sp,160
    80005f32:	8082                	ret
    end_op();
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	834080e7          	jalr	-1996(ra) # 80004768 <end_op>
    return -1;
    80005f3c:	557d                	li	a0,-1
    80005f3e:	b7fd                	j	80005f2c <sys_mknod+0x6c>

0000000080005f40 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f40:	7135                	addi	sp,sp,-160
    80005f42:	ed06                	sd	ra,152(sp)
    80005f44:	e922                	sd	s0,144(sp)
    80005f46:	e526                	sd	s1,136(sp)
    80005f48:	e14a                	sd	s2,128(sp)
    80005f4a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f4c:	ffffc097          	auipc	ra,0xffffc
    80005f50:	d24080e7          	jalr	-732(ra) # 80001c70 <myproc>
    80005f54:	892a                	mv	s2,a0
  
  begin_op();
    80005f56:	ffffe097          	auipc	ra,0xffffe
    80005f5a:	794080e7          	jalr	1940(ra) # 800046ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f5e:	08000613          	li	a2,128
    80005f62:	f6040593          	addi	a1,s0,-160
    80005f66:	4501                	li	a0,0
    80005f68:	ffffd097          	auipc	ra,0xffffd
    80005f6c:	140080e7          	jalr	320(ra) # 800030a8 <argstr>
    80005f70:	04054b63          	bltz	a0,80005fc6 <sys_chdir+0x86>
    80005f74:	f6040513          	addi	a0,s0,-160
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	552080e7          	jalr	1362(ra) # 800044ca <namei>
    80005f80:	84aa                	mv	s1,a0
    80005f82:	c131                	beqz	a0,80005fc6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f84:	ffffe097          	auipc	ra,0xffffe
    80005f88:	d9a080e7          	jalr	-614(ra) # 80003d1e <ilock>
  if(ip->type != T_DIR){
    80005f8c:	04449703          	lh	a4,68(s1)
    80005f90:	4785                	li	a5,1
    80005f92:	04f71063          	bne	a4,a5,80005fd2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f96:	8526                	mv	a0,s1
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	e48080e7          	jalr	-440(ra) # 80003de0 <iunlock>
  iput(p->cwd);
    80005fa0:	15093503          	ld	a0,336(s2)
    80005fa4:	ffffe097          	auipc	ra,0xffffe
    80005fa8:	f34080e7          	jalr	-204(ra) # 80003ed8 <iput>
  end_op();
    80005fac:	ffffe097          	auipc	ra,0xffffe
    80005fb0:	7bc080e7          	jalr	1980(ra) # 80004768 <end_op>
  p->cwd = ip;
    80005fb4:	14993823          	sd	s1,336(s2)
  return 0;
    80005fb8:	4501                	li	a0,0
}
    80005fba:	60ea                	ld	ra,152(sp)
    80005fbc:	644a                	ld	s0,144(sp)
    80005fbe:	64aa                	ld	s1,136(sp)
    80005fc0:	690a                	ld	s2,128(sp)
    80005fc2:	610d                	addi	sp,sp,160
    80005fc4:	8082                	ret
    end_op();
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	7a2080e7          	jalr	1954(ra) # 80004768 <end_op>
    return -1;
    80005fce:	557d                	li	a0,-1
    80005fd0:	b7ed                	j	80005fba <sys_chdir+0x7a>
    iunlockput(ip);
    80005fd2:	8526                	mv	a0,s1
    80005fd4:	ffffe097          	auipc	ra,0xffffe
    80005fd8:	fac080e7          	jalr	-84(ra) # 80003f80 <iunlockput>
    end_op();
    80005fdc:	ffffe097          	auipc	ra,0xffffe
    80005fe0:	78c080e7          	jalr	1932(ra) # 80004768 <end_op>
    return -1;
    80005fe4:	557d                	li	a0,-1
    80005fe6:	bfd1                	j	80005fba <sys_chdir+0x7a>

0000000080005fe8 <sys_exec>:

uint64
sys_exec(void)
{
    80005fe8:	7145                	addi	sp,sp,-464
    80005fea:	e786                	sd	ra,456(sp)
    80005fec:	e3a2                	sd	s0,448(sp)
    80005fee:	ff26                	sd	s1,440(sp)
    80005ff0:	fb4a                	sd	s2,432(sp)
    80005ff2:	f74e                	sd	s3,424(sp)
    80005ff4:	f352                	sd	s4,416(sp)
    80005ff6:	ef56                	sd	s5,408(sp)
    80005ff8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ffa:	e3840593          	addi	a1,s0,-456
    80005ffe:	4505                	li	a0,1
    80006000:	ffffd097          	auipc	ra,0xffffd
    80006004:	088080e7          	jalr	136(ra) # 80003088 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006008:	08000613          	li	a2,128
    8000600c:	f4040593          	addi	a1,s0,-192
    80006010:	4501                	li	a0,0
    80006012:	ffffd097          	auipc	ra,0xffffd
    80006016:	096080e7          	jalr	150(ra) # 800030a8 <argstr>
    8000601a:	87aa                	mv	a5,a0
    return -1;
    8000601c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000601e:	0c07c363          	bltz	a5,800060e4 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006022:	10000613          	li	a2,256
    80006026:	4581                	li	a1,0
    80006028:	e4040513          	addi	a0,s0,-448
    8000602c:	ffffb097          	auipc	ra,0xffffb
    80006030:	e32080e7          	jalr	-462(ra) # 80000e5e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006034:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006038:	89a6                	mv	s3,s1
    8000603a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000603c:	02000a13          	li	s4,32
    80006040:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006044:	00391513          	slli	a0,s2,0x3
    80006048:	e3040593          	addi	a1,s0,-464
    8000604c:	e3843783          	ld	a5,-456(s0)
    80006050:	953e                	add	a0,a0,a5
    80006052:	ffffd097          	auipc	ra,0xffffd
    80006056:	f78080e7          	jalr	-136(ra) # 80002fca <fetchaddr>
    8000605a:	02054a63          	bltz	a0,8000608e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000605e:	e3043783          	ld	a5,-464(s0)
    80006062:	c3b9                	beqz	a5,800060a8 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006064:	ffffb097          	auipc	ra,0xffffb
    80006068:	afe080e7          	jalr	-1282(ra) # 80000b62 <kalloc>
    8000606c:	85aa                	mv	a1,a0
    8000606e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006072:	cd11                	beqz	a0,8000608e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006074:	6605                	lui	a2,0x1
    80006076:	e3043503          	ld	a0,-464(s0)
    8000607a:	ffffd097          	auipc	ra,0xffffd
    8000607e:	fa2080e7          	jalr	-94(ra) # 8000301c <fetchstr>
    80006082:	00054663          	bltz	a0,8000608e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006086:	0905                	addi	s2,s2,1
    80006088:	09a1                	addi	s3,s3,8
    8000608a:	fb491be3          	bne	s2,s4,80006040 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000608e:	f4040913          	addi	s2,s0,-192
    80006092:	6088                	ld	a0,0(s1)
    80006094:	c539                	beqz	a0,800060e2 <sys_exec+0xfa>
    kfree(argv[i]);
    80006096:	ffffb097          	auipc	ra,0xffffb
    8000609a:	964080e7          	jalr	-1692(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000609e:	04a1                	addi	s1,s1,8
    800060a0:	ff2499e3          	bne	s1,s2,80006092 <sys_exec+0xaa>
  return -1;
    800060a4:	557d                	li	a0,-1
    800060a6:	a83d                	j	800060e4 <sys_exec+0xfc>
      argv[i] = 0;
    800060a8:	0a8e                	slli	s5,s5,0x3
    800060aa:	fc0a8793          	addi	a5,s5,-64
    800060ae:	00878ab3          	add	s5,a5,s0
    800060b2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060b6:	e4040593          	addi	a1,s0,-448
    800060ba:	f4040513          	addi	a0,s0,-192
    800060be:	fffff097          	auipc	ra,0xfffff
    800060c2:	16e080e7          	jalr	366(ra) # 8000522c <exec>
    800060c6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060c8:	f4040993          	addi	s3,s0,-192
    800060cc:	6088                	ld	a0,0(s1)
    800060ce:	c901                	beqz	a0,800060de <sys_exec+0xf6>
    kfree(argv[i]);
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	92a080e7          	jalr	-1750(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060d8:	04a1                	addi	s1,s1,8
    800060da:	ff3499e3          	bne	s1,s3,800060cc <sys_exec+0xe4>
  return ret;
    800060de:	854a                	mv	a0,s2
    800060e0:	a011                	j	800060e4 <sys_exec+0xfc>
  return -1;
    800060e2:	557d                	li	a0,-1
}
    800060e4:	60be                	ld	ra,456(sp)
    800060e6:	641e                	ld	s0,448(sp)
    800060e8:	74fa                	ld	s1,440(sp)
    800060ea:	795a                	ld	s2,432(sp)
    800060ec:	79ba                	ld	s3,424(sp)
    800060ee:	7a1a                	ld	s4,416(sp)
    800060f0:	6afa                	ld	s5,408(sp)
    800060f2:	6179                	addi	sp,sp,464
    800060f4:	8082                	ret

00000000800060f6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060f6:	7139                	addi	sp,sp,-64
    800060f8:	fc06                	sd	ra,56(sp)
    800060fa:	f822                	sd	s0,48(sp)
    800060fc:	f426                	sd	s1,40(sp)
    800060fe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006100:	ffffc097          	auipc	ra,0xffffc
    80006104:	b70080e7          	jalr	-1168(ra) # 80001c70 <myproc>
    80006108:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000610a:	fd840593          	addi	a1,s0,-40
    8000610e:	4501                	li	a0,0
    80006110:	ffffd097          	auipc	ra,0xffffd
    80006114:	f78080e7          	jalr	-136(ra) # 80003088 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006118:	fc840593          	addi	a1,s0,-56
    8000611c:	fd040513          	addi	a0,s0,-48
    80006120:	fffff097          	auipc	ra,0xfffff
    80006124:	dc2080e7          	jalr	-574(ra) # 80004ee2 <pipealloc>
    return -1;
    80006128:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000612a:	0c054463          	bltz	a0,800061f2 <sys_pipe+0xfc>
  fd0 = -1;
    8000612e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006132:	fd043503          	ld	a0,-48(s0)
    80006136:	fffff097          	auipc	ra,0xfffff
    8000613a:	514080e7          	jalr	1300(ra) # 8000564a <fdalloc>
    8000613e:	fca42223          	sw	a0,-60(s0)
    80006142:	08054b63          	bltz	a0,800061d8 <sys_pipe+0xe2>
    80006146:	fc843503          	ld	a0,-56(s0)
    8000614a:	fffff097          	auipc	ra,0xfffff
    8000614e:	500080e7          	jalr	1280(ra) # 8000564a <fdalloc>
    80006152:	fca42023          	sw	a0,-64(s0)
    80006156:	06054863          	bltz	a0,800061c6 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000615a:	4691                	li	a3,4
    8000615c:	fc440613          	addi	a2,s0,-60
    80006160:	fd843583          	ld	a1,-40(s0)
    80006164:	68a8                	ld	a0,80(s1)
    80006166:	ffffb097          	auipc	ra,0xffffb
    8000616a:	6cc080e7          	jalr	1740(ra) # 80001832 <copyout>
    8000616e:	02054063          	bltz	a0,8000618e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006172:	4691                	li	a3,4
    80006174:	fc040613          	addi	a2,s0,-64
    80006178:	fd843583          	ld	a1,-40(s0)
    8000617c:	0591                	addi	a1,a1,4
    8000617e:	68a8                	ld	a0,80(s1)
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	6b2080e7          	jalr	1714(ra) # 80001832 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006188:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000618a:	06055463          	bgez	a0,800061f2 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000618e:	fc442783          	lw	a5,-60(s0)
    80006192:	07e9                	addi	a5,a5,26
    80006194:	078e                	slli	a5,a5,0x3
    80006196:	97a6                	add	a5,a5,s1
    80006198:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000619c:	fc042783          	lw	a5,-64(s0)
    800061a0:	07e9                	addi	a5,a5,26
    800061a2:	078e                	slli	a5,a5,0x3
    800061a4:	94be                	add	s1,s1,a5
    800061a6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061aa:	fd043503          	ld	a0,-48(s0)
    800061ae:	fffff097          	auipc	ra,0xfffff
    800061b2:	a04080e7          	jalr	-1532(ra) # 80004bb2 <fileclose>
    fileclose(wf);
    800061b6:	fc843503          	ld	a0,-56(s0)
    800061ba:	fffff097          	auipc	ra,0xfffff
    800061be:	9f8080e7          	jalr	-1544(ra) # 80004bb2 <fileclose>
    return -1;
    800061c2:	57fd                	li	a5,-1
    800061c4:	a03d                	j	800061f2 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800061c6:	fc442783          	lw	a5,-60(s0)
    800061ca:	0007c763          	bltz	a5,800061d8 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800061ce:	07e9                	addi	a5,a5,26
    800061d0:	078e                	slli	a5,a5,0x3
    800061d2:	97a6                	add	a5,a5,s1
    800061d4:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800061d8:	fd043503          	ld	a0,-48(s0)
    800061dc:	fffff097          	auipc	ra,0xfffff
    800061e0:	9d6080e7          	jalr	-1578(ra) # 80004bb2 <fileclose>
    fileclose(wf);
    800061e4:	fc843503          	ld	a0,-56(s0)
    800061e8:	fffff097          	auipc	ra,0xfffff
    800061ec:	9ca080e7          	jalr	-1590(ra) # 80004bb2 <fileclose>
    return -1;
    800061f0:	57fd                	li	a5,-1
}
    800061f2:	853e                	mv	a0,a5
    800061f4:	70e2                	ld	ra,56(sp)
    800061f6:	7442                	ld	s0,48(sp)
    800061f8:	74a2                	ld	s1,40(sp)
    800061fa:	6121                	addi	sp,sp,64
    800061fc:	8082                	ret
	...

0000000080006200 <kernelvec>:
    80006200:	7111                	addi	sp,sp,-256
    80006202:	e006                	sd	ra,0(sp)
    80006204:	e40a                	sd	sp,8(sp)
    80006206:	e80e                	sd	gp,16(sp)
    80006208:	ec12                	sd	tp,24(sp)
    8000620a:	f016                	sd	t0,32(sp)
    8000620c:	f41a                	sd	t1,40(sp)
    8000620e:	f81e                	sd	t2,48(sp)
    80006210:	fc22                	sd	s0,56(sp)
    80006212:	e0a6                	sd	s1,64(sp)
    80006214:	e4aa                	sd	a0,72(sp)
    80006216:	e8ae                	sd	a1,80(sp)
    80006218:	ecb2                	sd	a2,88(sp)
    8000621a:	f0b6                	sd	a3,96(sp)
    8000621c:	f4ba                	sd	a4,104(sp)
    8000621e:	f8be                	sd	a5,112(sp)
    80006220:	fcc2                	sd	a6,120(sp)
    80006222:	e146                	sd	a7,128(sp)
    80006224:	e54a                	sd	s2,136(sp)
    80006226:	e94e                	sd	s3,144(sp)
    80006228:	ed52                	sd	s4,152(sp)
    8000622a:	f156                	sd	s5,160(sp)
    8000622c:	f55a                	sd	s6,168(sp)
    8000622e:	f95e                	sd	s7,176(sp)
    80006230:	fd62                	sd	s8,184(sp)
    80006232:	e1e6                	sd	s9,192(sp)
    80006234:	e5ea                	sd	s10,200(sp)
    80006236:	e9ee                	sd	s11,208(sp)
    80006238:	edf2                	sd	t3,216(sp)
    8000623a:	f1f6                	sd	t4,224(sp)
    8000623c:	f5fa                	sd	t5,232(sp)
    8000623e:	f9fe                	sd	t6,240(sp)
    80006240:	c57fc0ef          	jal	ra,80002e96 <kerneltrap>
    80006244:	6082                	ld	ra,0(sp)
    80006246:	6122                	ld	sp,8(sp)
    80006248:	61c2                	ld	gp,16(sp)
    8000624a:	7282                	ld	t0,32(sp)
    8000624c:	7322                	ld	t1,40(sp)
    8000624e:	73c2                	ld	t2,48(sp)
    80006250:	7462                	ld	s0,56(sp)
    80006252:	6486                	ld	s1,64(sp)
    80006254:	6526                	ld	a0,72(sp)
    80006256:	65c6                	ld	a1,80(sp)
    80006258:	6666                	ld	a2,88(sp)
    8000625a:	7686                	ld	a3,96(sp)
    8000625c:	7726                	ld	a4,104(sp)
    8000625e:	77c6                	ld	a5,112(sp)
    80006260:	7866                	ld	a6,120(sp)
    80006262:	688a                	ld	a7,128(sp)
    80006264:	692a                	ld	s2,136(sp)
    80006266:	69ca                	ld	s3,144(sp)
    80006268:	6a6a                	ld	s4,152(sp)
    8000626a:	7a8a                	ld	s5,160(sp)
    8000626c:	7b2a                	ld	s6,168(sp)
    8000626e:	7bca                	ld	s7,176(sp)
    80006270:	7c6a                	ld	s8,184(sp)
    80006272:	6c8e                	ld	s9,192(sp)
    80006274:	6d2e                	ld	s10,200(sp)
    80006276:	6dce                	ld	s11,208(sp)
    80006278:	6e6e                	ld	t3,216(sp)
    8000627a:	7e8e                	ld	t4,224(sp)
    8000627c:	7f2e                	ld	t5,232(sp)
    8000627e:	7fce                	ld	t6,240(sp)
    80006280:	6111                	addi	sp,sp,256
    80006282:	10200073          	sret
    80006286:	00000013          	nop
    8000628a:	00000013          	nop
    8000628e:	0001                	nop

0000000080006290 <timervec>:
    80006290:	34051573          	csrrw	a0,mscratch,a0
    80006294:	e10c                	sd	a1,0(a0)
    80006296:	e510                	sd	a2,8(a0)
    80006298:	e914                	sd	a3,16(a0)
    8000629a:	6d0c                	ld	a1,24(a0)
    8000629c:	7110                	ld	a2,32(a0)
    8000629e:	6194                	ld	a3,0(a1)
    800062a0:	96b2                	add	a3,a3,a2
    800062a2:	e194                	sd	a3,0(a1)
    800062a4:	4589                	li	a1,2
    800062a6:	14459073          	csrw	sip,a1
    800062aa:	6914                	ld	a3,16(a0)
    800062ac:	6510                	ld	a2,8(a0)
    800062ae:	610c                	ld	a1,0(a0)
    800062b0:	34051573          	csrrw	a0,mscratch,a0
    800062b4:	30200073          	mret
	...

00000000800062ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ba:	1141                	addi	sp,sp,-16
    800062bc:	e422                	sd	s0,8(sp)
    800062be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062c0:	0c0007b7          	lui	a5,0xc000
    800062c4:	4705                	li	a4,1
    800062c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062c8:	c3d8                	sw	a4,4(a5)
}
    800062ca:	6422                	ld	s0,8(sp)
    800062cc:	0141                	addi	sp,sp,16
    800062ce:	8082                	ret

00000000800062d0 <plicinithart>:

void
plicinithart(void)
{
    800062d0:	1141                	addi	sp,sp,-16
    800062d2:	e406                	sd	ra,8(sp)
    800062d4:	e022                	sd	s0,0(sp)
    800062d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062d8:	ffffc097          	auipc	ra,0xffffc
    800062dc:	96c080e7          	jalr	-1684(ra) # 80001c44 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062e0:	0085171b          	slliw	a4,a0,0x8
    800062e4:	0c0027b7          	lui	a5,0xc002
    800062e8:	97ba                	add	a5,a5,a4
    800062ea:	40200713          	li	a4,1026
    800062ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062f2:	00d5151b          	slliw	a0,a0,0xd
    800062f6:	0c2017b7          	lui	a5,0xc201
    800062fa:	97aa                	add	a5,a5,a0
    800062fc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006300:	60a2                	ld	ra,8(sp)
    80006302:	6402                	ld	s0,0(sp)
    80006304:	0141                	addi	sp,sp,16
    80006306:	8082                	ret

0000000080006308 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006308:	1141                	addi	sp,sp,-16
    8000630a:	e406                	sd	ra,8(sp)
    8000630c:	e022                	sd	s0,0(sp)
    8000630e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006310:	ffffc097          	auipc	ra,0xffffc
    80006314:	934080e7          	jalr	-1740(ra) # 80001c44 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006318:	00d5151b          	slliw	a0,a0,0xd
    8000631c:	0c2017b7          	lui	a5,0xc201
    80006320:	97aa                	add	a5,a5,a0
  return irq;
}
    80006322:	43c8                	lw	a0,4(a5)
    80006324:	60a2                	ld	ra,8(sp)
    80006326:	6402                	ld	s0,0(sp)
    80006328:	0141                	addi	sp,sp,16
    8000632a:	8082                	ret

000000008000632c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000632c:	1101                	addi	sp,sp,-32
    8000632e:	ec06                	sd	ra,24(sp)
    80006330:	e822                	sd	s0,16(sp)
    80006332:	e426                	sd	s1,8(sp)
    80006334:	1000                	addi	s0,sp,32
    80006336:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006338:	ffffc097          	auipc	ra,0xffffc
    8000633c:	90c080e7          	jalr	-1780(ra) # 80001c44 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006340:	00d5151b          	slliw	a0,a0,0xd
    80006344:	0c2017b7          	lui	a5,0xc201
    80006348:	97aa                	add	a5,a5,a0
    8000634a:	c3c4                	sw	s1,4(a5)
}
    8000634c:	60e2                	ld	ra,24(sp)
    8000634e:	6442                	ld	s0,16(sp)
    80006350:	64a2                	ld	s1,8(sp)
    80006352:	6105                	addi	sp,sp,32
    80006354:	8082                	ret

0000000080006356 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006356:	1141                	addi	sp,sp,-16
    80006358:	e406                	sd	ra,8(sp)
    8000635a:	e022                	sd	s0,0(sp)
    8000635c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000635e:	479d                	li	a5,7
    80006360:	04a7cc63          	blt	a5,a0,800063b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006364:	0003c797          	auipc	a5,0x3c
    80006368:	a6c78793          	addi	a5,a5,-1428 # 80041dd0 <disk>
    8000636c:	97aa                	add	a5,a5,a0
    8000636e:	0187c783          	lbu	a5,24(a5)
    80006372:	ebb9                	bnez	a5,800063c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006374:	00451693          	slli	a3,a0,0x4
    80006378:	0003c797          	auipc	a5,0x3c
    8000637c:	a5878793          	addi	a5,a5,-1448 # 80041dd0 <disk>
    80006380:	6398                	ld	a4,0(a5)
    80006382:	9736                	add	a4,a4,a3
    80006384:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006388:	6398                	ld	a4,0(a5)
    8000638a:	9736                	add	a4,a4,a3
    8000638c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006390:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006394:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006398:	97aa                	add	a5,a5,a0
    8000639a:	4705                	li	a4,1
    8000639c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800063a0:	0003c517          	auipc	a0,0x3c
    800063a4:	a4850513          	addi	a0,a0,-1464 # 80041de8 <disk+0x18>
    800063a8:	ffffc097          	auipc	ra,0xffffc
    800063ac:	0c8080e7          	jalr	200(ra) # 80002470 <wakeup>
}
    800063b0:	60a2                	ld	ra,8(sp)
    800063b2:	6402                	ld	s0,0(sp)
    800063b4:	0141                	addi	sp,sp,16
    800063b6:	8082                	ret
    panic("free_desc 1");
    800063b8:	00002517          	auipc	a0,0x2
    800063bc:	4f050513          	addi	a0,a0,1264 # 800088a8 <syscalls+0x318>
    800063c0:	ffffa097          	auipc	ra,0xffffa
    800063c4:	180080e7          	jalr	384(ra) # 80000540 <panic>
    panic("free_desc 2");
    800063c8:	00002517          	auipc	a0,0x2
    800063cc:	4f050513          	addi	a0,a0,1264 # 800088b8 <syscalls+0x328>
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	170080e7          	jalr	368(ra) # 80000540 <panic>

00000000800063d8 <virtio_disk_init>:
{
    800063d8:	1101                	addi	sp,sp,-32
    800063da:	ec06                	sd	ra,24(sp)
    800063dc:	e822                	sd	s0,16(sp)
    800063de:	e426                	sd	s1,8(sp)
    800063e0:	e04a                	sd	s2,0(sp)
    800063e2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063e4:	00002597          	auipc	a1,0x2
    800063e8:	4e458593          	addi	a1,a1,1252 # 800088c8 <syscalls+0x338>
    800063ec:	0003c517          	auipc	a0,0x3c
    800063f0:	b0c50513          	addi	a0,a0,-1268 # 80041ef8 <disk+0x128>
    800063f4:	ffffb097          	auipc	ra,0xffffb
    800063f8:	8de080e7          	jalr	-1826(ra) # 80000cd2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063fc:	100017b7          	lui	a5,0x10001
    80006400:	4398                	lw	a4,0(a5)
    80006402:	2701                	sext.w	a4,a4
    80006404:	747277b7          	lui	a5,0x74727
    80006408:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000640c:	14f71b63          	bne	a4,a5,80006562 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006410:	100017b7          	lui	a5,0x10001
    80006414:	43dc                	lw	a5,4(a5)
    80006416:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006418:	4709                	li	a4,2
    8000641a:	14e79463          	bne	a5,a4,80006562 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000641e:	100017b7          	lui	a5,0x10001
    80006422:	479c                	lw	a5,8(a5)
    80006424:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006426:	12e79e63          	bne	a5,a4,80006562 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000642a:	100017b7          	lui	a5,0x10001
    8000642e:	47d8                	lw	a4,12(a5)
    80006430:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006432:	554d47b7          	lui	a5,0x554d4
    80006436:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000643a:	12f71463          	bne	a4,a5,80006562 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000643e:	100017b7          	lui	a5,0x10001
    80006442:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006446:	4705                	li	a4,1
    80006448:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000644a:	470d                	li	a4,3
    8000644c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000644e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006450:	c7ffe6b7          	lui	a3,0xc7ffe
    80006454:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fbc84f>
    80006458:	8f75                	and	a4,a4,a3
    8000645a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000645c:	472d                	li	a4,11
    8000645e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006460:	5bbc                	lw	a5,112(a5)
    80006462:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006466:	8ba1                	andi	a5,a5,8
    80006468:	10078563          	beqz	a5,80006572 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000646c:	100017b7          	lui	a5,0x10001
    80006470:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006474:	43fc                	lw	a5,68(a5)
    80006476:	2781                	sext.w	a5,a5
    80006478:	10079563          	bnez	a5,80006582 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000647c:	100017b7          	lui	a5,0x10001
    80006480:	5bdc                	lw	a5,52(a5)
    80006482:	2781                	sext.w	a5,a5
  if(max == 0)
    80006484:	10078763          	beqz	a5,80006592 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006488:	471d                	li	a4,7
    8000648a:	10f77c63          	bgeu	a4,a5,800065a2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	6d4080e7          	jalr	1748(ra) # 80000b62 <kalloc>
    80006496:	0003c497          	auipc	s1,0x3c
    8000649a:	93a48493          	addi	s1,s1,-1734 # 80041dd0 <disk>
    8000649e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064a0:	ffffa097          	auipc	ra,0xffffa
    800064a4:	6c2080e7          	jalr	1730(ra) # 80000b62 <kalloc>
    800064a8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	6b8080e7          	jalr	1720(ra) # 80000b62 <kalloc>
    800064b2:	87aa                	mv	a5,a0
    800064b4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064b6:	6088                	ld	a0,0(s1)
    800064b8:	cd6d                	beqz	a0,800065b2 <virtio_disk_init+0x1da>
    800064ba:	0003c717          	auipc	a4,0x3c
    800064be:	91e73703          	ld	a4,-1762(a4) # 80041dd8 <disk+0x8>
    800064c2:	cb65                	beqz	a4,800065b2 <virtio_disk_init+0x1da>
    800064c4:	c7fd                	beqz	a5,800065b2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800064c6:	6605                	lui	a2,0x1
    800064c8:	4581                	li	a1,0
    800064ca:	ffffb097          	auipc	ra,0xffffb
    800064ce:	994080e7          	jalr	-1644(ra) # 80000e5e <memset>
  memset(disk.avail, 0, PGSIZE);
    800064d2:	0003c497          	auipc	s1,0x3c
    800064d6:	8fe48493          	addi	s1,s1,-1794 # 80041dd0 <disk>
    800064da:	6605                	lui	a2,0x1
    800064dc:	4581                	li	a1,0
    800064de:	6488                	ld	a0,8(s1)
    800064e0:	ffffb097          	auipc	ra,0xffffb
    800064e4:	97e080e7          	jalr	-1666(ra) # 80000e5e <memset>
  memset(disk.used, 0, PGSIZE);
    800064e8:	6605                	lui	a2,0x1
    800064ea:	4581                	li	a1,0
    800064ec:	6888                	ld	a0,16(s1)
    800064ee:	ffffb097          	auipc	ra,0xffffb
    800064f2:	970080e7          	jalr	-1680(ra) # 80000e5e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800064f6:	100017b7          	lui	a5,0x10001
    800064fa:	4721                	li	a4,8
    800064fc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800064fe:	4098                	lw	a4,0(s1)
    80006500:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006504:	40d8                	lw	a4,4(s1)
    80006506:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000650a:	6498                	ld	a4,8(s1)
    8000650c:	0007069b          	sext.w	a3,a4
    80006510:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006514:	9701                	srai	a4,a4,0x20
    80006516:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000651a:	6898                	ld	a4,16(s1)
    8000651c:	0007069b          	sext.w	a3,a4
    80006520:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006524:	9701                	srai	a4,a4,0x20
    80006526:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000652a:	4705                	li	a4,1
    8000652c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000652e:	00e48c23          	sb	a4,24(s1)
    80006532:	00e48ca3          	sb	a4,25(s1)
    80006536:	00e48d23          	sb	a4,26(s1)
    8000653a:	00e48da3          	sb	a4,27(s1)
    8000653e:	00e48e23          	sb	a4,28(s1)
    80006542:	00e48ea3          	sb	a4,29(s1)
    80006546:	00e48f23          	sb	a4,30(s1)
    8000654a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000654e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006552:	0727a823          	sw	s2,112(a5)
}
    80006556:	60e2                	ld	ra,24(sp)
    80006558:	6442                	ld	s0,16(sp)
    8000655a:	64a2                	ld	s1,8(sp)
    8000655c:	6902                	ld	s2,0(sp)
    8000655e:	6105                	addi	sp,sp,32
    80006560:	8082                	ret
    panic("could not find virtio disk");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	37650513          	addi	a0,a0,886 # 800088d8 <syscalls+0x348>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd6080e7          	jalr	-42(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006572:	00002517          	auipc	a0,0x2
    80006576:	38650513          	addi	a0,a0,902 # 800088f8 <syscalls+0x368>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006582:	00002517          	auipc	a0,0x2
    80006586:	39650513          	addi	a0,a0,918 # 80008918 <syscalls+0x388>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	fb6080e7          	jalr	-74(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006592:	00002517          	auipc	a0,0x2
    80006596:	3a650513          	addi	a0,a0,934 # 80008938 <syscalls+0x3a8>
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	fa6080e7          	jalr	-90(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	3b650513          	addi	a0,a0,950 # 80008958 <syscalls+0x3c8>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f96080e7          	jalr	-106(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	3c650513          	addi	a0,a0,966 # 80008978 <syscalls+0x3e8>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f86080e7          	jalr	-122(ra) # 80000540 <panic>

00000000800065c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065c2:	7119                	addi	sp,sp,-128
    800065c4:	fc86                	sd	ra,120(sp)
    800065c6:	f8a2                	sd	s0,112(sp)
    800065c8:	f4a6                	sd	s1,104(sp)
    800065ca:	f0ca                	sd	s2,96(sp)
    800065cc:	ecce                	sd	s3,88(sp)
    800065ce:	e8d2                	sd	s4,80(sp)
    800065d0:	e4d6                	sd	s5,72(sp)
    800065d2:	e0da                	sd	s6,64(sp)
    800065d4:	fc5e                	sd	s7,56(sp)
    800065d6:	f862                	sd	s8,48(sp)
    800065d8:	f466                	sd	s9,40(sp)
    800065da:	f06a                	sd	s10,32(sp)
    800065dc:	ec6e                	sd	s11,24(sp)
    800065de:	0100                	addi	s0,sp,128
    800065e0:	8aaa                	mv	s5,a0
    800065e2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065e4:	00c52d03          	lw	s10,12(a0)
    800065e8:	001d1d1b          	slliw	s10,s10,0x1
    800065ec:	1d02                	slli	s10,s10,0x20
    800065ee:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800065f2:	0003c517          	auipc	a0,0x3c
    800065f6:	90650513          	addi	a0,a0,-1786 # 80041ef8 <disk+0x128>
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	768080e7          	jalr	1896(ra) # 80000d62 <acquire>
  for(int i = 0; i < 3; i++){
    80006602:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006604:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006606:	0003bb97          	auipc	s7,0x3b
    8000660a:	7cab8b93          	addi	s7,s7,1994 # 80041dd0 <disk>
  for(int i = 0; i < 3; i++){
    8000660e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006610:	0003cc97          	auipc	s9,0x3c
    80006614:	8e8c8c93          	addi	s9,s9,-1816 # 80041ef8 <disk+0x128>
    80006618:	a08d                	j	8000667a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000661a:	00fb8733          	add	a4,s7,a5
    8000661e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006622:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006624:	0207c563          	bltz	a5,8000664e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006628:	2905                	addiw	s2,s2,1
    8000662a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000662c:	05690c63          	beq	s2,s6,80006684 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006630:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006632:	0003b717          	auipc	a4,0x3b
    80006636:	79e70713          	addi	a4,a4,1950 # 80041dd0 <disk>
    8000663a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000663c:	01874683          	lbu	a3,24(a4)
    80006640:	fee9                	bnez	a3,8000661a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006642:	2785                	addiw	a5,a5,1
    80006644:	0705                	addi	a4,a4,1
    80006646:	fe979be3          	bne	a5,s1,8000663c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000664a:	57fd                	li	a5,-1
    8000664c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000664e:	01205d63          	blez	s2,80006668 <virtio_disk_rw+0xa6>
    80006652:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006654:	000a2503          	lw	a0,0(s4)
    80006658:	00000097          	auipc	ra,0x0
    8000665c:	cfe080e7          	jalr	-770(ra) # 80006356 <free_desc>
      for(int j = 0; j < i; j++)
    80006660:	2d85                	addiw	s11,s11,1
    80006662:	0a11                	addi	s4,s4,4
    80006664:	ff2d98e3          	bne	s11,s2,80006654 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006668:	85e6                	mv	a1,s9
    8000666a:	0003b517          	auipc	a0,0x3b
    8000666e:	77e50513          	addi	a0,a0,1918 # 80041de8 <disk+0x18>
    80006672:	ffffc097          	auipc	ra,0xffffc
    80006676:	d9a080e7          	jalr	-614(ra) # 8000240c <sleep>
  for(int i = 0; i < 3; i++){
    8000667a:	f8040a13          	addi	s4,s0,-128
{
    8000667e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006680:	894e                	mv	s2,s3
    80006682:	b77d                	j	80006630 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006684:	f8042503          	lw	a0,-128(s0)
    80006688:	00a50713          	addi	a4,a0,10
    8000668c:	0712                	slli	a4,a4,0x4

  if(write)
    8000668e:	0003b797          	auipc	a5,0x3b
    80006692:	74278793          	addi	a5,a5,1858 # 80041dd0 <disk>
    80006696:	00e786b3          	add	a3,a5,a4
    8000669a:	01803633          	snez	a2,s8
    8000669e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066a0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800066a4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066a8:	f6070613          	addi	a2,a4,-160
    800066ac:	6394                	ld	a3,0(a5)
    800066ae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066b0:	00870593          	addi	a1,a4,8
    800066b4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066b6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066b8:	0007b803          	ld	a6,0(a5)
    800066bc:	9642                	add	a2,a2,a6
    800066be:	46c1                	li	a3,16
    800066c0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066c2:	4585                	li	a1,1
    800066c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800066c8:	f8442683          	lw	a3,-124(s0)
    800066cc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066d0:	0692                	slli	a3,a3,0x4
    800066d2:	9836                	add	a6,a6,a3
    800066d4:	058a8613          	addi	a2,s5,88
    800066d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800066dc:	0007b803          	ld	a6,0(a5)
    800066e0:	96c2                	add	a3,a3,a6
    800066e2:	40000613          	li	a2,1024
    800066e6:	c690                	sw	a2,8(a3)
  if(write)
    800066e8:	001c3613          	seqz	a2,s8
    800066ec:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066f0:	00166613          	ori	a2,a2,1
    800066f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066f8:	f8842603          	lw	a2,-120(s0)
    800066fc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006700:	00250693          	addi	a3,a0,2
    80006704:	0692                	slli	a3,a3,0x4
    80006706:	96be                	add	a3,a3,a5
    80006708:	58fd                	li	a7,-1
    8000670a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000670e:	0612                	slli	a2,a2,0x4
    80006710:	9832                	add	a6,a6,a2
    80006712:	f9070713          	addi	a4,a4,-112
    80006716:	973e                	add	a4,a4,a5
    80006718:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000671c:	6398                	ld	a4,0(a5)
    8000671e:	9732                	add	a4,a4,a2
    80006720:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006722:	4609                	li	a2,2
    80006724:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006728:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000672c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006730:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006734:	6794                	ld	a3,8(a5)
    80006736:	0026d703          	lhu	a4,2(a3)
    8000673a:	8b1d                	andi	a4,a4,7
    8000673c:	0706                	slli	a4,a4,0x1
    8000673e:	96ba                	add	a3,a3,a4
    80006740:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006744:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006748:	6798                	ld	a4,8(a5)
    8000674a:	00275783          	lhu	a5,2(a4)
    8000674e:	2785                	addiw	a5,a5,1
    80006750:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006754:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006758:	100017b7          	lui	a5,0x10001
    8000675c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006760:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006764:	0003b917          	auipc	s2,0x3b
    80006768:	79490913          	addi	s2,s2,1940 # 80041ef8 <disk+0x128>
  while(b->disk == 1) {
    8000676c:	4485                	li	s1,1
    8000676e:	00b79c63          	bne	a5,a1,80006786 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006772:	85ca                	mv	a1,s2
    80006774:	8556                	mv	a0,s5
    80006776:	ffffc097          	auipc	ra,0xffffc
    8000677a:	c96080e7          	jalr	-874(ra) # 8000240c <sleep>
  while(b->disk == 1) {
    8000677e:	004aa783          	lw	a5,4(s5)
    80006782:	fe9788e3          	beq	a5,s1,80006772 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006786:	f8042903          	lw	s2,-128(s0)
    8000678a:	00290713          	addi	a4,s2,2
    8000678e:	0712                	slli	a4,a4,0x4
    80006790:	0003b797          	auipc	a5,0x3b
    80006794:	64078793          	addi	a5,a5,1600 # 80041dd0 <disk>
    80006798:	97ba                	add	a5,a5,a4
    8000679a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000679e:	0003b997          	auipc	s3,0x3b
    800067a2:	63298993          	addi	s3,s3,1586 # 80041dd0 <disk>
    800067a6:	00491713          	slli	a4,s2,0x4
    800067aa:	0009b783          	ld	a5,0(s3)
    800067ae:	97ba                	add	a5,a5,a4
    800067b0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067b4:	854a                	mv	a0,s2
    800067b6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067ba:	00000097          	auipc	ra,0x0
    800067be:	b9c080e7          	jalr	-1124(ra) # 80006356 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800067c2:	8885                	andi	s1,s1,1
    800067c4:	f0ed                	bnez	s1,800067a6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067c6:	0003b517          	auipc	a0,0x3b
    800067ca:	73250513          	addi	a0,a0,1842 # 80041ef8 <disk+0x128>
    800067ce:	ffffa097          	auipc	ra,0xffffa
    800067d2:	648080e7          	jalr	1608(ra) # 80000e16 <release>
}
    800067d6:	70e6                	ld	ra,120(sp)
    800067d8:	7446                	ld	s0,112(sp)
    800067da:	74a6                	ld	s1,104(sp)
    800067dc:	7906                	ld	s2,96(sp)
    800067de:	69e6                	ld	s3,88(sp)
    800067e0:	6a46                	ld	s4,80(sp)
    800067e2:	6aa6                	ld	s5,72(sp)
    800067e4:	6b06                	ld	s6,64(sp)
    800067e6:	7be2                	ld	s7,56(sp)
    800067e8:	7c42                	ld	s8,48(sp)
    800067ea:	7ca2                	ld	s9,40(sp)
    800067ec:	7d02                	ld	s10,32(sp)
    800067ee:	6de2                	ld	s11,24(sp)
    800067f0:	6109                	addi	sp,sp,128
    800067f2:	8082                	ret

00000000800067f4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067f4:	1101                	addi	sp,sp,-32
    800067f6:	ec06                	sd	ra,24(sp)
    800067f8:	e822                	sd	s0,16(sp)
    800067fa:	e426                	sd	s1,8(sp)
    800067fc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067fe:	0003b497          	auipc	s1,0x3b
    80006802:	5d248493          	addi	s1,s1,1490 # 80041dd0 <disk>
    80006806:	0003b517          	auipc	a0,0x3b
    8000680a:	6f250513          	addi	a0,a0,1778 # 80041ef8 <disk+0x128>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	554080e7          	jalr	1364(ra) # 80000d62 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006816:	10001737          	lui	a4,0x10001
    8000681a:	533c                	lw	a5,96(a4)
    8000681c:	8b8d                	andi	a5,a5,3
    8000681e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006820:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006824:	689c                	ld	a5,16(s1)
    80006826:	0204d703          	lhu	a4,32(s1)
    8000682a:	0027d783          	lhu	a5,2(a5)
    8000682e:	04f70863          	beq	a4,a5,8000687e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006832:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006836:	6898                	ld	a4,16(s1)
    80006838:	0204d783          	lhu	a5,32(s1)
    8000683c:	8b9d                	andi	a5,a5,7
    8000683e:	078e                	slli	a5,a5,0x3
    80006840:	97ba                	add	a5,a5,a4
    80006842:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006844:	00278713          	addi	a4,a5,2
    80006848:	0712                	slli	a4,a4,0x4
    8000684a:	9726                	add	a4,a4,s1
    8000684c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006850:	e721                	bnez	a4,80006898 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006852:	0789                	addi	a5,a5,2
    80006854:	0792                	slli	a5,a5,0x4
    80006856:	97a6                	add	a5,a5,s1
    80006858:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000685a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000685e:	ffffc097          	auipc	ra,0xffffc
    80006862:	c12080e7          	jalr	-1006(ra) # 80002470 <wakeup>

    disk.used_idx += 1;
    80006866:	0204d783          	lhu	a5,32(s1)
    8000686a:	2785                	addiw	a5,a5,1
    8000686c:	17c2                	slli	a5,a5,0x30
    8000686e:	93c1                	srli	a5,a5,0x30
    80006870:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006874:	6898                	ld	a4,16(s1)
    80006876:	00275703          	lhu	a4,2(a4)
    8000687a:	faf71ce3          	bne	a4,a5,80006832 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000687e:	0003b517          	auipc	a0,0x3b
    80006882:	67a50513          	addi	a0,a0,1658 # 80041ef8 <disk+0x128>
    80006886:	ffffa097          	auipc	ra,0xffffa
    8000688a:	590080e7          	jalr	1424(ra) # 80000e16 <release>
}
    8000688e:	60e2                	ld	ra,24(sp)
    80006890:	6442                	ld	s0,16(sp)
    80006892:	64a2                	ld	s1,8(sp)
    80006894:	6105                	addi	sp,sp,32
    80006896:	8082                	ret
      panic("virtio_disk_intr status");
    80006898:	00002517          	auipc	a0,0x2
    8000689c:	0f850513          	addi	a0,a0,248 # 80008990 <syscalls+0x400>
    800068a0:	ffffa097          	auipc	ra,0xffffa
    800068a4:	ca0080e7          	jalr	-864(ra) # 80000540 <panic>
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
