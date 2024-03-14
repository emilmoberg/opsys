
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
    80000066:	1fe78793          	addi	a5,a5,510 # 80006260 <timervec>
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
    8000012e:	70c080e7          	jalr	1804(ra) # 80002836 <either_copyin>
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
    800001cc:	4b8080e7          	jalr	1208(ra) # 80002680 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	202080e7          	jalr	514(ra) # 800023d8 <sleep>
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
    80000216:	5ce080e7          	jalr	1486(ra) # 800027e0 <either_copyout>
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
    800002f6:	59a080e7          	jalr	1434(ra) # 8000288c <procdump>
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
    8000044a:	ff6080e7          	jalr	-10(ra) # 8000243c <wakeup>
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
    800007ae:	1141                	addi	sp,sp,-16
    800007b0:	e406                	sd	ra,8(sp)
    800007b2:	e022                	sd	s0,0(sp)
    800007b4:	0800                	addi	s0,sp,16
    800007b6:	100007b7          	lui	a5,0x10000
    800007ba:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>
    800007be:	f8000713          	li	a4,-128
    800007c2:	00e781a3          	sb	a4,3(a5)
    800007c6:	470d                	li	a4,3
    800007c8:	00e78023          	sb	a4,0(a5)
    800007cc:	000780a3          	sb	zero,1(a5)
    800007d0:	00e781a3          	sb	a4,3(a5)
    800007d4:	469d                	li	a3,7
    800007d6:	00d78123          	sb	a3,2(a5)
    800007da:	00e780a3          	sb	a4,1(a5)
    800007de:	00008597          	auipc	a1,0x8
    800007e2:	88a58593          	addi	a1,a1,-1910 # 80008068 <digits+0x18>
    800007e6:	00010517          	auipc	a0,0x10
    800007ea:	4c250513          	addi	a0,a0,1218 # 80010ca8 <uart_tx_lock>
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	4e4080e7          	jalr	1252(ra) # 80000cd2 <initlock>
    800007f6:	60a2                	ld	ra,8(sp)
    800007f8:	6402                	ld	s0,0(sp)
    800007fa:	0141                	addi	sp,sp,16
    800007fc:	8082                	ret

00000000800007fe <uartputc_sync>:
    800007fe:	1101                	addi	sp,sp,-32
    80000800:	ec06                	sd	ra,24(sp)
    80000802:	e822                	sd	s0,16(sp)
    80000804:	e426                	sd	s1,8(sp)
    80000806:	1000                	addi	s0,sp,32
    80000808:	84aa                	mv	s1,a0
    8000080a:	00000097          	auipc	ra,0x0
    8000080e:	50c080e7          	jalr	1292(ra) # 80000d16 <push_off>
    80000812:	00008797          	auipc	a5,0x8
    80000816:	23e7a783          	lw	a5,574(a5) # 80008a50 <panicked>
    8000081a:	10000737          	lui	a4,0x10000
    8000081e:	c391                	beqz	a5,80000822 <uartputc_sync+0x24>
    80000820:	a001                	j	80000820 <uartputc_sync+0x22>
    80000822:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dfe5                	beqz	a5,80000822 <uartputc_sync+0x24>
    8000082c:	0ff4f513          	zext.b	a0,s1
    80000830:	100007b7          	lui	a5,0x10000
    80000834:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	57e080e7          	jalr	1406(ra) # 80000db6 <pop_off>
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	20e7b783          	ld	a5,526(a5) # 80008a58 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	20e73703          	ld	a4,526(a4) # 80008a60 <uart_tx_w>
    8000085a:	06f70a63          	beq	a4,a5,800008ce <uartstart+0x84>
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
    80000870:	10000937          	lui	s2,0x10000
    80000874:	00010a17          	auipc	s4,0x10
    80000878:	434a0a13          	addi	s4,s4,1076 # 80010ca8 <uart_tx_lock>
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	1dc48493          	addi	s1,s1,476 # 80008a58 <uart_tx_r>
    80000884:	00008997          	auipc	s3,0x8
    80000888:	1dc98993          	addi	s3,s3,476 # 80008a60 <uart_tx_w>
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	02077713          	andi	a4,a4,32
    80000894:	c705                	beqz	a4,800008bc <uartstart+0x72>
    80000896:	01f7f713          	andi	a4,a5,31
    8000089a:	9752                	add	a4,a4,s4
    8000089c:	01874a83          	lbu	s5,24(a4)
    800008a0:	0785                	addi	a5,a5,1
    800008a2:	e09c                	sd	a5,0(s1)
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	b96080e7          	jalr	-1130(ra) # 8000243c <wakeup>
    800008ae:	01590023          	sb	s5,0(s2)
    800008b2:	609c                	ld	a5,0(s1)
    800008b4:	0009b703          	ld	a4,0(s3)
    800008b8:	fcf71ae3          	bne	a4,a5,8000088c <uartstart+0x42>
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
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	8a2a                	mv	s4,a0
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	3c650513          	addi	a0,a0,966 # 80010ca8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	478080e7          	jalr	1144(ra) # 80000d62 <acquire>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	15e7a783          	lw	a5,350(a5) # 80008a50 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
    800008fc:	00008717          	auipc	a4,0x8
    80000900:	16473703          	ld	a4,356(a4) # 80008a60 <uart_tx_w>
    80000904:	00008797          	auipc	a5,0x8
    80000908:	1547b783          	ld	a5,340(a5) # 80008a58 <uart_tx_r>
    8000090c:	02078793          	addi	a5,a5,32
    80000910:	00010997          	auipc	s3,0x10
    80000914:	39898993          	addi	s3,s3,920 # 80010ca8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	14048493          	addi	s1,s1,320 # 80008a58 <uart_tx_r>
    80000920:	00008917          	auipc	s2,0x8
    80000924:	14090913          	addi	s2,s2,320 # 80008a60 <uart_tx_w>
    80000928:	00e79f63          	bne	a5,a4,80000946 <uartputc+0x76>
    8000092c:	85ce                	mv	a1,s3
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	aa8080e7          	jalr	-1368(ra) # 800023d8 <sleep>
    80000938:	00093703          	ld	a4,0(s2)
    8000093c:	609c                	ld	a5,0(s1)
    8000093e:	02078793          	addi	a5,a5,32
    80000942:	fee785e3          	beq	a5,a4,8000092c <uartputc+0x5c>
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	36248493          	addi	s1,s1,866 # 80010ca8 <uart_tx_lock>
    8000094e:	01f77793          	andi	a5,a4,31
    80000952:	97a6                	add	a5,a5,s1
    80000954:	01478c23          	sb	s4,24(a5)
    80000958:	0705                	addi	a4,a4,1
    8000095a:	00008797          	auipc	a5,0x8
    8000095e:	10e7b323          	sd	a4,262(a5) # 80008a60 <uart_tx_w>
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee8080e7          	jalr	-280(ra) # 8000084a <uartstart>
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	4aa080e7          	jalr	1194(ra) # 80000e16 <release>
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb81                	beqz	a5,800009a6 <uartgetc+0x20>
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	6422                	ld	s0,8(sp)
    800009a2:	0141                	addi	sp,sp,16
    800009a4:	8082                	ret
    800009a6:	557d                	li	a0,-1
    800009a8:	bfe5                	j	800009a0 <uartgetc+0x1a>

00000000800009aa <uartintr>:
    800009aa:	1101                	addi	sp,sp,-32
    800009ac:	ec06                	sd	ra,24(sp)
    800009ae:	e822                	sd	s0,16(sp)
    800009b0:	e426                	sd	s1,8(sp)
    800009b2:	1000                	addi	s0,sp,32
    800009b4:	54fd                	li	s1,-1
    800009b6:	a029                	j	800009c0 <uartintr+0x16>
    800009b8:	00000097          	auipc	ra,0x0
    800009bc:	906080e7          	jalr	-1786(ra) # 800002be <consoleintr>
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	fc6080e7          	jalr	-58(ra) # 80000986 <uartgetc>
    800009c8:	fe9518e3          	bne	a0,s1,800009b8 <uartintr+0xe>
    800009cc:	00010497          	auipc	s1,0x10
    800009d0:	2dc48493          	addi	s1,s1,732 # 80010ca8 <uart_tx_lock>
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	38c080e7          	jalr	908(ra) # 80000d62 <acquire>
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	e6c080e7          	jalr	-404(ra) # 8000084a <uartstart>
    800009e6:	8526                	mv	a0,s1
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	42e080e7          	jalr	1070(ra) # 80000e16 <release>
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
    80000a86:	03900693          	li	a3,57
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
    80000bc8:	05200693          	li	a3,82
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

0000000080000c0e <n_kfree>:

void n_kfree(void *pa){
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

0000000080000c42 <n_kallock>:

void * n_kallock(void){
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
    80000c6a:	eb11                	bnez	a4,80000c7e <n_kallock+0x3c>
    80000c6c:	c909                	beqz	a0,80000c7e <n_kallock+0x3c>
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

0000000080000c86 <ref_increment>:

void ref_increment(void *pa){
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

0000000080000cac <ref_decrement>:

void ref_decrement(void *pa){
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
    8000104e:	a66080e7          	jalr	-1434(ra) # 80002ab0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001052:	00005097          	auipc	ra,0x5
    80001056:	24e080e7          	jalr	590(ra) # 800062a0 <plicinithart>
  }

  scheduler();        
    8000105a:	00001097          	auipc	ra,0x1
    8000105e:	25c080e7          	jalr	604(ra) # 800022b6 <scheduler>
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
    800010c6:	9c6080e7          	jalr	-1594(ra) # 80002a88 <trapinit>
    trapinithart();  // install kernel trap vector
    800010ca:	00002097          	auipc	ra,0x2
    800010ce:	9e6080e7          	jalr	-1562(ra) # 80002ab0 <trapinithart>
    plicinit();      // set up interrupt controller
    800010d2:	00005097          	auipc	ra,0x5
    800010d6:	1b8080e7          	jalr	440(ra) # 8000628a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010da:	00005097          	auipc	ra,0x5
    800010de:	1c6080e7          	jalr	454(ra) # 800062a0 <plicinithart>
    binit();         // buffer cache
    800010e2:	00002097          	auipc	ra,0x2
    800010e6:	360080e7          	jalr	864(ra) # 80003442 <binit>
    iinit();         // inode table
    800010ea:	00003097          	auipc	ra,0x3
    800010ee:	a00080e7          	jalr	-1536(ra) # 80003aea <iinit>
    fileinit();      // file table
    800010f2:	00004097          	auipc	ra,0x4
    800010f6:	9a6080e7          	jalr	-1626(ra) # 80004a98 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010fa:	00005097          	auipc	ra,0x5
    800010fe:	2ae080e7          	jalr	686(ra) # 800063a8 <virtio_disk_init>
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
    8000111a:	1141                	addi	sp,sp,-16
    8000111c:	e422                	sd	s0,8(sp)
    8000111e:	0800                	addi	s0,sp,16
    80001120:	12000073          	sfence.vma
    80001124:	00008797          	auipc	a5,0x8
    80001128:	95c7b783          	ld	a5,-1700(a5) # 80008a80 <kernel_pagetable>
    8000112c:	83b1                	srli	a5,a5,0xc
    8000112e:	577d                	li	a4,-1
    80001130:	177e                	slli	a4,a4,0x3f
    80001132:	8fd9                	or	a5,a5,a4
    80001134:	18079073          	csrw	satp,a5
    80001138:	12000073          	sfence.vma
    8000113c:	6422                	ld	s0,8(sp)
    8000113e:	0141                	addi	sp,sp,16
    80001140:	8082                	ret

0000000080001142 <walk>:
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
    8000115c:	57fd                	li	a5,-1
    8000115e:	83e9                	srli	a5,a5,0x1a
    80001160:	4a79                	li	s4,30
    80001162:	4b31                	li	s6,12
    80001164:	04b7f263          	bgeu	a5,a1,800011a8 <walk+0x66>
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	fa850513          	addi	a0,a0,-88 # 80008110 <digits+0xc0>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d0080e7          	jalr	976(ra) # 80000540 <panic>
    80001178:	060a8663          	beqz	s5,800011e4 <walk+0xa2>
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	9e6080e7          	jalr	-1562(ra) # 80000b62 <kalloc>
    80001184:	84aa                	mv	s1,a0
    80001186:	c529                	beqz	a0,800011d0 <walk+0x8e>
    80001188:	6605                	lui	a2,0x1
    8000118a:	4581                	li	a1,0
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	cd2080e7          	jalr	-814(ra) # 80000e5e <memset>
    80001194:	00c4d793          	srli	a5,s1,0xc
    80001198:	07aa                	slli	a5,a5,0xa
    8000119a:	0017e793          	ori	a5,a5,1
    8000119e:	00f93023          	sd	a5,0(s2)
    800011a2:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffbd0e7>
    800011a4:	036a0063          	beq	s4,s6,800011c4 <walk+0x82>
    800011a8:	0149d933          	srl	s2,s3,s4
    800011ac:	1ff97913          	andi	s2,s2,511
    800011b0:	090e                	slli	s2,s2,0x3
    800011b2:	9926                	add	s2,s2,s1
    800011b4:	00093483          	ld	s1,0(s2)
    800011b8:	0014f793          	andi	a5,s1,1
    800011bc:	dfd5                	beqz	a5,80001178 <walk+0x36>
    800011be:	80a9                	srli	s1,s1,0xa
    800011c0:	04b2                	slli	s1,s1,0xc
    800011c2:	b7c5                	j	800011a2 <walk+0x60>
    800011c4:	00c9d513          	srli	a0,s3,0xc
    800011c8:	1ff57513          	andi	a0,a0,511
    800011cc:	050e                	slli	a0,a0,0x3
    800011ce:	9526                	add	a0,a0,s1
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
    800011e4:	4501                	li	a0,0
    800011e6:	b7ed                	j	800011d0 <walk+0x8e>

00000000800011e8 <walkaddr>:
    800011e8:	57fd                	li	a5,-1
    800011ea:	83e9                	srli	a5,a5,0x1a
    800011ec:	00b7f463          	bgeu	a5,a1,800011f4 <walkaddr+0xc>
    800011f0:	4501                	li	a0,0
    800011f2:	8082                	ret
    800011f4:	1141                	addi	sp,sp,-16
    800011f6:	e406                	sd	ra,8(sp)
    800011f8:	e022                	sd	s0,0(sp)
    800011fa:	0800                	addi	s0,sp,16
    800011fc:	4601                	li	a2,0
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f44080e7          	jalr	-188(ra) # 80001142 <walk>
    80001206:	c105                	beqz	a0,80001226 <walkaddr+0x3e>
    80001208:	611c                	ld	a5,0(a0)
    8000120a:	0117f693          	andi	a3,a5,17
    8000120e:	4745                	li	a4,17
    80001210:	4501                	li	a0,0
    80001212:	00e68663          	beq	a3,a4,8000121e <walkaddr+0x36>
    80001216:	60a2                	ld	ra,8(sp)
    80001218:	6402                	ld	s0,0(sp)
    8000121a:	0141                	addi	sp,sp,16
    8000121c:	8082                	ret
    8000121e:	83a9                	srli	a5,a5,0xa
    80001220:	00c79513          	slli	a0,a5,0xc
    80001224:	bfcd                	j	80001216 <walkaddr+0x2e>
    80001226:	4501                	li	a0,0
    80001228:	b7fd                	j	80001216 <walkaddr+0x2e>

000000008000122a <mappages>:
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
    80001240:	c639                	beqz	a2,8000128e <mappages+0x64>
    80001242:	8aaa                	mv	s5,a0
    80001244:	8b3a                	mv	s6,a4
    80001246:	777d                	lui	a4,0xfffff
    80001248:	00e5f7b3          	and	a5,a1,a4
    8000124c:	fff58993          	addi	s3,a1,-1
    80001250:	99b2                	add	s3,s3,a2
    80001252:	00e9f9b3          	and	s3,s3,a4
    80001256:	893e                	mv	s2,a5
    80001258:	40f68a33          	sub	s4,a3,a5
    8000125c:	6b85                	lui	s7,0x1
    8000125e:	012a04b3          	add	s1,s4,s2
    80001262:	4605                	li	a2,1
    80001264:	85ca                	mv	a1,s2
    80001266:	8556                	mv	a0,s5
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	eda080e7          	jalr	-294(ra) # 80001142 <walk>
    80001270:	cd1d                	beqz	a0,800012ae <mappages+0x84>
    80001272:	611c                	ld	a5,0(a0)
    80001274:	8b85                	andi	a5,a5,1
    80001276:	e785                	bnez	a5,8000129e <mappages+0x74>
    80001278:	80b1                	srli	s1,s1,0xc
    8000127a:	04aa                	slli	s1,s1,0xa
    8000127c:	0164e4b3          	or	s1,s1,s6
    80001280:	0014e493          	ori	s1,s1,1
    80001284:	e104                	sd	s1,0(a0)
    80001286:	05390063          	beq	s2,s3,800012c6 <mappages+0x9c>
    8000128a:	995e                	add	s2,s2,s7
    8000128c:	bfc9                	j	8000125e <mappages+0x34>
    8000128e:	00007517          	auipc	a0,0x7
    80001292:	e8a50513          	addi	a0,a0,-374 # 80008118 <digits+0xc8>
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	2aa080e7          	jalr	682(ra) # 80000540 <panic>
    8000129e:	00007517          	auipc	a0,0x7
    800012a2:	e8a50513          	addi	a0,a0,-374 # 80008128 <digits+0xd8>
    800012a6:	fffff097          	auipc	ra,0xfffff
    800012aa:	29a080e7          	jalr	666(ra) # 80000540 <panic>
    800012ae:	557d                	li	a0,-1
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
    800012c6:	4501                	li	a0,0
    800012c8:	b7e5                	j	800012b0 <mappages+0x86>

00000000800012ca <kvmmap>:
    800012ca:	1141                	addi	sp,sp,-16
    800012cc:	e406                	sd	ra,8(sp)
    800012ce:	e022                	sd	s0,0(sp)
    800012d0:	0800                	addi	s0,sp,16
    800012d2:	87b6                	mv	a5,a3
    800012d4:	86b2                	mv	a3,a2
    800012d6:	863e                	mv	a2,a5
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	f52080e7          	jalr	-174(ra) # 8000122a <mappages>
    800012e0:	e509                	bnez	a0,800012ea <kvmmap+0x20>
    800012e2:	60a2                	ld	ra,8(sp)
    800012e4:	6402                	ld	s0,0(sp)
    800012e6:	0141                	addi	sp,sp,16
    800012e8:	8082                	ret
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e4e50513          	addi	a0,a0,-434 # 80008138 <digits+0xe8>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24e080e7          	jalr	590(ra) # 80000540 <panic>

00000000800012fa <kvmmake>:
    800012fa:	1101                	addi	sp,sp,-32
    800012fc:	ec06                	sd	ra,24(sp)
    800012fe:	e822                	sd	s0,16(sp)
    80001300:	e426                	sd	s1,8(sp)
    80001302:	e04a                	sd	s2,0(sp)
    80001304:	1000                	addi	s0,sp,32
    80001306:	00000097          	auipc	ra,0x0
    8000130a:	93c080e7          	jalr	-1732(ra) # 80000c42 <n_kallock>
    8000130e:	84aa                	mv	s1,a0
    80001310:	6605                	lui	a2,0x1
    80001312:	4581                	li	a1,0
    80001314:	00000097          	auipc	ra,0x0
    80001318:	b4a080e7          	jalr	-1206(ra) # 80000e5e <memset>
    8000131c:	4719                	li	a4,6
    8000131e:	6685                	lui	a3,0x1
    80001320:	10000637          	lui	a2,0x10000
    80001324:	100005b7          	lui	a1,0x10000
    80001328:	8526                	mv	a0,s1
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	fa0080e7          	jalr	-96(ra) # 800012ca <kvmmap>
    80001332:	4719                	li	a4,6
    80001334:	6685                	lui	a3,0x1
    80001336:	10001637          	lui	a2,0x10001
    8000133a:	100015b7          	lui	a1,0x10001
    8000133e:	8526                	mv	a0,s1
    80001340:	00000097          	auipc	ra,0x0
    80001344:	f8a080e7          	jalr	-118(ra) # 800012ca <kvmmap>
    80001348:	4719                	li	a4,6
    8000134a:	004006b7          	lui	a3,0x400
    8000134e:	0c000637          	lui	a2,0xc000
    80001352:	0c0005b7          	lui	a1,0xc000
    80001356:	8526                	mv	a0,s1
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	f72080e7          	jalr	-142(ra) # 800012ca <kvmmap>
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
    80001382:	4719                	li	a4,6
    80001384:	46c5                	li	a3,17
    80001386:	06ee                	slli	a3,a3,0x1b
    80001388:	412686b3          	sub	a3,a3,s2
    8000138c:	864a                	mv	a2,s2
    8000138e:	85ca                	mv	a1,s2
    80001390:	8526                	mv	a0,s1
    80001392:	00000097          	auipc	ra,0x0
    80001396:	f38080e7          	jalr	-200(ra) # 800012ca <kvmmap>
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
    800013b8:	8526                	mv	a0,s1
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	712080e7          	jalr	1810(ra) # 80001acc <proc_mapstacks>
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6902                	ld	s2,0(sp)
    800013cc:	6105                	addi	sp,sp,32
    800013ce:	8082                	ret

00000000800013d0 <kvminit>:
    800013d0:	1141                	addi	sp,sp,-16
    800013d2:	e406                	sd	ra,8(sp)
    800013d4:	e022                	sd	s0,0(sp)
    800013d6:	0800                	addi	s0,sp,16
    800013d8:	00000097          	auipc	ra,0x0
    800013dc:	f22080e7          	jalr	-222(ra) # 800012fa <kvmmake>
    800013e0:	00007797          	auipc	a5,0x7
    800013e4:	6aa7b023          	sd	a0,1696(a5) # 80008a80 <kernel_pagetable>
    800013e8:	60a2                	ld	ra,8(sp)
    800013ea:	6402                	ld	s0,0(sp)
    800013ec:	0141                	addi	sp,sp,16
    800013ee:	8082                	ret

00000000800013f0 <uvmunmap>:
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
    8000140a:	03459793          	slli	a5,a1,0x34
    8000140e:	e395                	bnez	a5,80001432 <uvmunmap+0x42>
    80001410:	8aaa                	mv	s5,a0
    80001412:	892e                	mv	s2,a1
    80001414:	8b36                	mv	s6,a3
    80001416:	0632                	slli	a2,a2,0xc
    80001418:	00b60a33          	add	s4,a2,a1
    8000141c:	0b45f663          	bgeu	a1,s4,800014c8 <uvmunmap+0xd8>
    80001420:	4985                	li	s3,1
    80001422:	00010c97          	auipc	s9,0x10
    80001426:	8dec8c93          	addi	s9,s9,-1826 # 80010d00 <counter>
    8000142a:	80000c37          	lui	s8,0x80000
    8000142e:	6b85                	lui	s7,0x1
    80001430:	a891                	j	80001484 <uvmunmap+0x94>
    80001432:	00007517          	auipc	a0,0x7
    80001436:	d0e50513          	addi	a0,a0,-754 # 80008140 <digits+0xf0>
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	106080e7          	jalr	262(ra) # 80000540 <panic>
    80001442:	00007517          	auipc	a0,0x7
    80001446:	d1650513          	addi	a0,a0,-746 # 80008158 <digits+0x108>
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	0f6080e7          	jalr	246(ra) # 80000540 <panic>
    80001452:	00007517          	auipc	a0,0x7
    80001456:	d1650513          	addi	a0,a0,-746 # 80008168 <digits+0x118>
    8000145a:	fffff097          	auipc	ra,0xfffff
    8000145e:	0e6080e7          	jalr	230(ra) # 80000540 <panic>
    80001462:	00007517          	auipc	a0,0x7
    80001466:	d1e50513          	addi	a0,a0,-738 # 80008180 <digits+0x130>
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	0d6080e7          	jalr	214(ra) # 80000540 <panic>
    80001472:	fffff097          	auipc	ra,0xfffff
    80001476:	79c080e7          	jalr	1948(ra) # 80000c0e <n_kfree>
    8000147a:	0004b023          	sd	zero,0(s1)
    8000147e:	995e                	add	s2,s2,s7
    80001480:	05497463          	bgeu	s2,s4,800014c8 <uvmunmap+0xd8>
    80001484:	4601                	li	a2,0
    80001486:	85ca                	mv	a1,s2
    80001488:	8556                	mv	a0,s5
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	cb8080e7          	jalr	-840(ra) # 80001142 <walk>
    80001492:	84aa                	mv	s1,a0
    80001494:	d55d                	beqz	a0,80001442 <uvmunmap+0x52>
    80001496:	611c                	ld	a5,0(a0)
    80001498:	0017f713          	andi	a4,a5,1
    8000149c:	db5d                	beqz	a4,80001452 <uvmunmap+0x62>
    8000149e:	3ff7f713          	andi	a4,a5,1023
    800014a2:	fd3700e3          	beq	a4,s3,80001462 <uvmunmap+0x72>
    800014a6:	fc0b0ae3          	beqz	s6,8000147a <uvmunmap+0x8a>
    800014aa:	00a7d513          	srli	a0,a5,0xa
    800014ae:	0532                	slli	a0,a0,0xc
    800014b0:	018507b3          	add	a5,a0,s8
    800014b4:	83a9                	srli	a5,a5,0xa
    800014b6:	97e6                	add	a5,a5,s9
    800014b8:	439c                	lw	a5,0(a5)
    800014ba:	fb378ce3          	beq	a5,s3,80001472 <uvmunmap+0x82>
    800014be:	fffff097          	auipc	ra,0xfffff
    800014c2:	7ee080e7          	jalr	2030(ra) # 80000cac <ref_decrement>
    800014c6:	bf55                	j	8000147a <uvmunmap+0x8a>
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
    800014e2:	1101                	addi	sp,sp,-32
    800014e4:	ec06                	sd	ra,24(sp)
    800014e6:	e822                	sd	s0,16(sp)
    800014e8:	e426                	sd	s1,8(sp)
    800014ea:	1000                	addi	s0,sp,32
    800014ec:	fffff097          	auipc	ra,0xfffff
    800014f0:	756080e7          	jalr	1878(ra) # 80000c42 <n_kallock>
    800014f4:	84aa                	mv	s1,a0
    800014f6:	c519                	beqz	a0,80001504 <uvmcreate+0x22>
    800014f8:	6605                	lui	a2,0x1
    800014fa:	4581                	li	a1,0
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	962080e7          	jalr	-1694(ra) # 80000e5e <memset>
    80001504:	8526                	mv	a0,s1
    80001506:	60e2                	ld	ra,24(sp)
    80001508:	6442                	ld	s0,16(sp)
    8000150a:	64a2                	ld	s1,8(sp)
    8000150c:	6105                	addi	sp,sp,32
    8000150e:	8082                	ret

0000000080001510 <uvmfirst>:
    80001510:	7179                	addi	sp,sp,-48
    80001512:	f406                	sd	ra,40(sp)
    80001514:	f022                	sd	s0,32(sp)
    80001516:	ec26                	sd	s1,24(sp)
    80001518:	e84a                	sd	s2,16(sp)
    8000151a:	e44e                	sd	s3,8(sp)
    8000151c:	e052                	sd	s4,0(sp)
    8000151e:	1800                	addi	s0,sp,48
    80001520:	6785                	lui	a5,0x1
    80001522:	04f67863          	bgeu	a2,a5,80001572 <uvmfirst+0x62>
    80001526:	8a2a                	mv	s4,a0
    80001528:	89ae                	mv	s3,a1
    8000152a:	84b2                	mv	s1,a2
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	716080e7          	jalr	1814(ra) # 80000c42 <n_kallock>
    80001534:	892a                	mv	s2,a0
    80001536:	6605                	lui	a2,0x1
    80001538:	4581                	li	a1,0
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	924080e7          	jalr	-1756(ra) # 80000e5e <memset>
    80001542:	4779                	li	a4,30
    80001544:	86ca                	mv	a3,s2
    80001546:	6605                	lui	a2,0x1
    80001548:	4581                	li	a1,0
    8000154a:	8552                	mv	a0,s4
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	cde080e7          	jalr	-802(ra) # 8000122a <mappages>
    80001554:	8626                	mv	a2,s1
    80001556:	85ce                	mv	a1,s3
    80001558:	854a                	mv	a0,s2
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	960080e7          	jalr	-1696(ra) # 80000eba <memmove>
    80001562:	70a2                	ld	ra,40(sp)
    80001564:	7402                	ld	s0,32(sp)
    80001566:	64e2                	ld	s1,24(sp)
    80001568:	6942                	ld	s2,16(sp)
    8000156a:	69a2                	ld	s3,8(sp)
    8000156c:	6a02                	ld	s4,0(sp)
    8000156e:	6145                	addi	sp,sp,48
    80001570:	8082                	ret
    80001572:	00007517          	auipc	a0,0x7
    80001576:	c2650513          	addi	a0,a0,-986 # 80008198 <digits+0x148>
    8000157a:	fffff097          	auipc	ra,0xfffff
    8000157e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>

0000000080001582 <uvmdealloc>:
    80001582:	1101                	addi	sp,sp,-32
    80001584:	ec06                	sd	ra,24(sp)
    80001586:	e822                	sd	s0,16(sp)
    80001588:	e426                	sd	s1,8(sp)
    8000158a:	1000                	addi	s0,sp,32
    8000158c:	84ae                	mv	s1,a1
    8000158e:	00b67d63          	bgeu	a2,a1,800015a8 <uvmdealloc+0x26>
    80001592:	84b2                	mv	s1,a2
    80001594:	6785                	lui	a5,0x1
    80001596:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001598:	00f60733          	add	a4,a2,a5
    8000159c:	76fd                	lui	a3,0xfffff
    8000159e:	8f75                	and	a4,a4,a3
    800015a0:	97ae                	add	a5,a5,a1
    800015a2:	8ff5                	and	a5,a5,a3
    800015a4:	00f76863          	bltu	a4,a5,800015b4 <uvmdealloc+0x32>
    800015a8:	8526                	mv	a0,s1
    800015aa:	60e2                	ld	ra,24(sp)
    800015ac:	6442                	ld	s0,16(sp)
    800015ae:	64a2                	ld	s1,8(sp)
    800015b0:	6105                	addi	sp,sp,32
    800015b2:	8082                	ret
    800015b4:	8f99                	sub	a5,a5,a4
    800015b6:	83b1                	srli	a5,a5,0xc
    800015b8:	4685                	li	a3,1
    800015ba:	0007861b          	sext.w	a2,a5
    800015be:	85ba                	mv	a1,a4
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	e30080e7          	jalr	-464(ra) # 800013f0 <uvmunmap>
    800015c8:	b7c5                	j	800015a8 <uvmdealloc+0x26>

00000000800015ca <uvmalloc>:
    800015ca:	0ab66563          	bltu	a2,a1,80001674 <uvmalloc+0xaa>
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
    800015e6:	6785                	lui	a5,0x1
    800015e8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015ea:	95be                	add	a1,a1,a5
    800015ec:	77fd                	lui	a5,0xfffff
    800015ee:	00f5f9b3          	and	s3,a1,a5
    800015f2:	08c9f363          	bgeu	s3,a2,80001678 <uvmalloc+0xae>
    800015f6:	894e                	mv	s2,s3
    800015f8:	0126eb13          	ori	s6,a3,18
    800015fc:	fffff097          	auipc	ra,0xfffff
    80001600:	646080e7          	jalr	1606(ra) # 80000c42 <n_kallock>
    80001604:	84aa                	mv	s1,a0
    80001606:	c51d                	beqz	a0,80001634 <uvmalloc+0x6a>
    80001608:	6605                	lui	a2,0x1
    8000160a:	4581                	li	a1,0
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	852080e7          	jalr	-1966(ra) # 80000e5e <memset>
    80001614:	875a                	mv	a4,s6
    80001616:	86a6                	mv	a3,s1
    80001618:	6605                	lui	a2,0x1
    8000161a:	85ca                	mv	a1,s2
    8000161c:	8556                	mv	a0,s5
    8000161e:	00000097          	auipc	ra,0x0
    80001622:	c0c080e7          	jalr	-1012(ra) # 8000122a <mappages>
    80001626:	e90d                	bnez	a0,80001658 <uvmalloc+0x8e>
    80001628:	6785                	lui	a5,0x1
    8000162a:	993e                	add	s2,s2,a5
    8000162c:	fd4968e3          	bltu	s2,s4,800015fc <uvmalloc+0x32>
    80001630:	8552                	mv	a0,s4
    80001632:	a809                	j	80001644 <uvmalloc+0x7a>
    80001634:	864e                	mv	a2,s3
    80001636:	85ca                	mv	a1,s2
    80001638:	8556                	mv	a0,s5
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	f48080e7          	jalr	-184(ra) # 80001582 <uvmdealloc>
    80001642:	4501                	li	a0,0
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
    80001658:	8526                	mv	a0,s1
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	5b4080e7          	jalr	1460(ra) # 80000c0e <n_kfree>
    80001662:	864e                	mv	a2,s3
    80001664:	85ca                	mv	a1,s2
    80001666:	8556                	mv	a0,s5
    80001668:	00000097          	auipc	ra,0x0
    8000166c:	f1a080e7          	jalr	-230(ra) # 80001582 <uvmdealloc>
    80001670:	4501                	li	a0,0
    80001672:	bfc9                	j	80001644 <uvmalloc+0x7a>
    80001674:	852e                	mv	a0,a1
    80001676:	8082                	ret
    80001678:	8532                	mv	a0,a2
    8000167a:	b7e9                	j	80001644 <uvmalloc+0x7a>

000000008000167c <freewalk>:
    8000167c:	7179                	addi	sp,sp,-48
    8000167e:	f406                	sd	ra,40(sp)
    80001680:	f022                	sd	s0,32(sp)
    80001682:	ec26                	sd	s1,24(sp)
    80001684:	e84a                	sd	s2,16(sp)
    80001686:	e44e                	sd	s3,8(sp)
    80001688:	e052                	sd	s4,0(sp)
    8000168a:	1800                	addi	s0,sp,48
    8000168c:	8a2a                	mv	s4,a0
    8000168e:	84aa                	mv	s1,a0
    80001690:	6905                	lui	s2,0x1
    80001692:	992a                	add	s2,s2,a0
    80001694:	4985                	li	s3,1
    80001696:	a829                	j	800016b0 <freewalk+0x34>
    80001698:	83a9                	srli	a5,a5,0xa
    8000169a:	00c79513          	slli	a0,a5,0xc
    8000169e:	00000097          	auipc	ra,0x0
    800016a2:	fde080e7          	jalr	-34(ra) # 8000167c <freewalk>
    800016a6:	0004b023          	sd	zero,0(s1)
    800016aa:	04a1                	addi	s1,s1,8
    800016ac:	03248163          	beq	s1,s2,800016ce <freewalk+0x52>
    800016b0:	609c                	ld	a5,0(s1)
    800016b2:	00f7f713          	andi	a4,a5,15
    800016b6:	ff3701e3          	beq	a4,s3,80001698 <freewalk+0x1c>
    800016ba:	8b85                	andi	a5,a5,1
    800016bc:	d7fd                	beqz	a5,800016aa <freewalk+0x2e>
    800016be:	00007517          	auipc	a0,0x7
    800016c2:	afa50513          	addi	a0,a0,-1286 # 800081b8 <digits+0x168>
    800016c6:	fffff097          	auipc	ra,0xfffff
    800016ca:	e7a080e7          	jalr	-390(ra) # 80000540 <panic>
    800016ce:	8552                	mv	a0,s4
    800016d0:	fffff097          	auipc	ra,0xfffff
    800016d4:	53e080e7          	jalr	1342(ra) # 80000c0e <n_kfree>
    800016d8:	70a2                	ld	ra,40(sp)
    800016da:	7402                	ld	s0,32(sp)
    800016dc:	64e2                	ld	s1,24(sp)
    800016de:	6942                	ld	s2,16(sp)
    800016e0:	69a2                	ld	s3,8(sp)
    800016e2:	6a02                	ld	s4,0(sp)
    800016e4:	6145                	addi	sp,sp,48
    800016e6:	8082                	ret

00000000800016e8 <uvmfree>:
    800016e8:	1101                	addi	sp,sp,-32
    800016ea:	ec06                	sd	ra,24(sp)
    800016ec:	e822                	sd	s0,16(sp)
    800016ee:	e426                	sd	s1,8(sp)
    800016f0:	1000                	addi	s0,sp,32
    800016f2:	84aa                	mv	s1,a0
    800016f4:	e999                	bnez	a1,8000170a <uvmfree+0x22>
    800016f6:	8526                	mv	a0,s1
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	f84080e7          	jalr	-124(ra) # 8000167c <freewalk>
    80001700:	60e2                	ld	ra,24(sp)
    80001702:	6442                	ld	s0,16(sp)
    80001704:	64a2                	ld	s1,8(sp)
    80001706:	6105                	addi	sp,sp,32
    80001708:	8082                	ret
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
    80001738:	c271                	beqz	a2,800017fc <uvmcopy+0xda>
    8000173a:	8aaa                	mv	s5,a0
    8000173c:	8bae                	mv	s7,a1
    8000173e:	8b32                	mv	s6,a2
    80001740:	4901                	li	s2,0
    80001742:	4601                	li	a2,0
    80001744:	85ca                	mv	a1,s2
    80001746:	8556                	mv	a0,s5
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	9fa080e7          	jalr	-1542(ra) # 80001142 <walk>
    80001750:	c125                	beqz	a0,800017b0 <uvmcopy+0x8e>
    80001752:	6118                	ld	a4,0(a0)
    80001754:	00177793          	andi	a5,a4,1
    80001758:	c7a5                	beqz	a5,800017c0 <uvmcopy+0x9e>
    8000175a:	00a75993          	srli	s3,a4,0xa
    8000175e:	09b2                	slli	s3,s3,0xc
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
    8000177a:	854e                	mv	a0,s3
    8000177c:	fffff097          	auipc	ra,0xfffff
    80001780:	50a080e7          	jalr	1290(ra) # 80000c86 <ref_increment>
    80001784:	4681                	li	a3,0
    80001786:	4605                	li	a2,1
    80001788:	85ca                	mv	a1,s2
    8000178a:	8556                	mv	a0,s5
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	c64080e7          	jalr	-924(ra) # 800013f0 <uvmunmap>
    80001794:	8726                	mv	a4,s1
    80001796:	86ce                	mv	a3,s3
    80001798:	6605                	lui	a2,0x1
    8000179a:	85ca                	mv	a1,s2
    8000179c:	8556                	mv	a0,s5
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	a8c080e7          	jalr	-1396(ra) # 8000122a <mappages>
    800017a6:	6785                	lui	a5,0x1
    800017a8:	993e                	add	s2,s2,a5
    800017aa:	f9696ce3          	bltu	s2,s6,80001742 <uvmcopy+0x20>
    800017ae:	a81d                	j	800017e4 <uvmcopy+0xc2>
    800017b0:	00007517          	auipc	a0,0x7
    800017b4:	a1850513          	addi	a0,a0,-1512 # 800081c8 <digits+0x178>
    800017b8:	fffff097          	auipc	ra,0xfffff
    800017bc:	d88080e7          	jalr	-632(ra) # 80000540 <panic>
    800017c0:	00007517          	auipc	a0,0x7
    800017c4:	a2850513          	addi	a0,a0,-1496 # 800081e8 <digits+0x198>
    800017c8:	fffff097          	auipc	ra,0xfffff
    800017cc:	d78080e7          	jalr	-648(ra) # 80000540 <panic>
    800017d0:	4685                	li	a3,1
    800017d2:	00c95613          	srli	a2,s2,0xc
    800017d6:	4581                	li	a1,0
    800017d8:	855e                	mv	a0,s7
    800017da:	00000097          	auipc	ra,0x0
    800017de:	c16080e7          	jalr	-1002(ra) # 800013f0 <uvmunmap>
    800017e2:	5a7d                	li	s4,-1
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
    800017fc:	4a01                	li	s4,0
    800017fe:	b7dd                	j	800017e4 <uvmcopy+0xc2>

0000000080001800 <uvmclear>:
    80001800:	1141                	addi	sp,sp,-16
    80001802:	e406                	sd	ra,8(sp)
    80001804:	e022                	sd	s0,0(sp)
    80001806:	0800                	addi	s0,sp,16
    80001808:	4601                	li	a2,0
    8000180a:	00000097          	auipc	ra,0x0
    8000180e:	938080e7          	jalr	-1736(ra) # 80001142 <walk>
    80001812:	c901                	beqz	a0,80001822 <uvmclear+0x22>
    80001814:	611c                	ld	a5,0(a0)
    80001816:	9bbd                	andi	a5,a5,-17
    80001818:	e11c                	sd	a5,0(a0)
    8000181a:	60a2                	ld	ra,8(sp)
    8000181c:	6402                	ld	s0,0(sp)
    8000181e:	0141                	addi	sp,sp,16
    80001820:	8082                	ret
    80001822:	00007517          	auipc	a0,0x7
    80001826:	9e650513          	addi	a0,a0,-1562 # 80008208 <digits+0x1b8>
    8000182a:	fffff097          	auipc	ra,0xfffff
    8000182e:	d16080e7          	jalr	-746(ra) # 80000540 <panic>

0000000080001832 <copyout>:
    80001832:	c6bd                	beqz	a3,800018a0 <copyout+0x6e>
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
    80001854:	7bfd                	lui	s7,0xfffff
    80001856:	6a85                	lui	s5,0x1
    80001858:	a015                	j	8000187c <copyout+0x4a>
    8000185a:	9562                	add	a0,a0,s8
    8000185c:	0004861b          	sext.w	a2,s1
    80001860:	85d2                	mv	a1,s4
    80001862:	41250533          	sub	a0,a0,s2
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	654080e7          	jalr	1620(ra) # 80000eba <memmove>
    8000186e:	409989b3          	sub	s3,s3,s1
    80001872:	9a26                	add	s4,s4,s1
    80001874:	01590c33          	add	s8,s2,s5
    80001878:	02098263          	beqz	s3,8000189c <copyout+0x6a>
    8000187c:	017c7933          	and	s2,s8,s7
    80001880:	85ca                	mv	a1,s2
    80001882:	855a                	mv	a0,s6
    80001884:	00000097          	auipc	ra,0x0
    80001888:	964080e7          	jalr	-1692(ra) # 800011e8 <walkaddr>
    8000188c:	cd01                	beqz	a0,800018a4 <copyout+0x72>
    8000188e:	418904b3          	sub	s1,s2,s8
    80001892:	94d6                	add	s1,s1,s5
    80001894:	fc99f3e3          	bgeu	s3,s1,8000185a <copyout+0x28>
    80001898:	84ce                	mv	s1,s3
    8000189a:	b7c1                	j	8000185a <copyout+0x28>
    8000189c:	4501                	li	a0,0
    8000189e:	a021                	j	800018a6 <copyout+0x74>
    800018a0:	4501                	li	a0,0
    800018a2:	8082                	ret
    800018a4:	557d                	li	a0,-1
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
    800018be:	caa5                	beqz	a3,8000192e <copyin+0x70>
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
    800018e0:	7bfd                	lui	s7,0xfffff
    800018e2:	6a85                	lui	s5,0x1
    800018e4:	a01d                	j	8000190a <copyin+0x4c>
    800018e6:	018505b3          	add	a1,a0,s8
    800018ea:	0004861b          	sext.w	a2,s1
    800018ee:	412585b3          	sub	a1,a1,s2
    800018f2:	8552                	mv	a0,s4
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	5c6080e7          	jalr	1478(ra) # 80000eba <memmove>
    800018fc:	409989b3          	sub	s3,s3,s1
    80001900:	9a26                	add	s4,s4,s1
    80001902:	01590c33          	add	s8,s2,s5
    80001906:	02098263          	beqz	s3,8000192a <copyin+0x6c>
    8000190a:	017c7933          	and	s2,s8,s7
    8000190e:	85ca                	mv	a1,s2
    80001910:	855a                	mv	a0,s6
    80001912:	00000097          	auipc	ra,0x0
    80001916:	8d6080e7          	jalr	-1834(ra) # 800011e8 <walkaddr>
    8000191a:	cd01                	beqz	a0,80001932 <copyin+0x74>
    8000191c:	418904b3          	sub	s1,s2,s8
    80001920:	94d6                	add	s1,s1,s5
    80001922:	fc99f2e3          	bgeu	s3,s1,800018e6 <copyin+0x28>
    80001926:	84ce                	mv	s1,s3
    80001928:	bf7d                	j	800018e6 <copyin+0x28>
    8000192a:	4501                	li	a0,0
    8000192c:	a021                	j	80001934 <copyin+0x76>
    8000192e:	4501                	li	a0,0
    80001930:	8082                	ret
    80001932:	557d                	li	a0,-1
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
    8000194c:	c2dd                	beqz	a3,800019f2 <copyinstr+0xa6>
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
    8000196c:	7afd                	lui	s5,0xfffff
    8000196e:	6985                	lui	s3,0x1
    80001970:	a02d                	j	8000199a <copyinstr+0x4e>
    80001972:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001976:	4785                	li	a5,1
    80001978:	37fd                	addiw	a5,a5,-1
    8000197a:	0007851b          	sext.w	a0,a5
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
    80001994:	01390bb3          	add	s7,s2,s3
    80001998:	c8a9                	beqz	s1,800019ea <copyinstr+0x9e>
    8000199a:	015bf933          	and	s2,s7,s5
    8000199e:	85ca                	mv	a1,s2
    800019a0:	8552                	mv	a0,s4
    800019a2:	00000097          	auipc	ra,0x0
    800019a6:	846080e7          	jalr	-1978(ra) # 800011e8 <walkaddr>
    800019aa:	c131                	beqz	a0,800019ee <copyinstr+0xa2>
    800019ac:	417906b3          	sub	a3,s2,s7
    800019b0:	96ce                	add	a3,a3,s3
    800019b2:	00d4f363          	bgeu	s1,a3,800019b8 <copyinstr+0x6c>
    800019b6:	86a6                	mv	a3,s1
    800019b8:	955e                	add	a0,a0,s7
    800019ba:	41250533          	sub	a0,a0,s2
    800019be:	daf9                	beqz	a3,80001994 <copyinstr+0x48>
    800019c0:	87da                	mv	a5,s6
    800019c2:	41650633          	sub	a2,a0,s6
    800019c6:	fff48593          	addi	a1,s1,-1
    800019ca:	95da                	add	a1,a1,s6
    800019cc:	96da                	add	a3,a3,s6
    800019ce:	00f60733          	add	a4,a2,a5
    800019d2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbd0f0>
    800019d6:	df51                	beqz	a4,80001972 <copyinstr+0x26>
    800019d8:	00e78023          	sb	a4,0(a5)
    800019dc:	40f584b3          	sub	s1,a1,a5
    800019e0:	0785                	addi	a5,a5,1
    800019e2:	fed796e3          	bne	a5,a3,800019ce <copyinstr+0x82>
    800019e6:	8b3e                	mv	s6,a5
    800019e8:	b775                	j	80001994 <copyinstr+0x48>
    800019ea:	4781                	li	a5,0
    800019ec:	b771                	j	80001978 <copyinstr+0x2c>
    800019ee:	557d                	li	a0,-1
    800019f0:	b779                	j	8000197e <copyinstr+0x32>
    800019f2:	4781                	li	a5,0
    800019f4:	37fd                	addiw	a5,a5,-1
    800019f6:	0007851b          	sext.w	a0,a5
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
    80001aba:	f68080e7          	jalr	-152(ra) # 80002a1e <swtch>
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
        char *pa = n_kallock();
    80001b04:	fffff097          	auipc	ra,0xfffff
    80001b08:	13e080e7          	jalr	318(ra) # 80000c42 <n_kallock>
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
    80001cce:	dfe080e7          	jalr	-514(ra) # 80002ac8 <usertrapret>
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
    80001ce8:	d86080e7          	jalr	-634(ra) # 80003a6a <fsinit>
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
        n_kfree((void *)p->trapframe);
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	ddc080e7          	jalr	-548(ra) # 80000c0e <n_kfree>
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
    80001faa:	4ee080e7          	jalr	1262(ra) # 80004494 <namei>
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
    8000204a:	120b8063          	beqz	s7,8000216a <ps+0x144>
    void *result = (void *)myproc()->sz;
    8000204e:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80002052:	003b951b          	slliw	a0,s7,0x3
    80002056:	0175053b          	addw	a0,a0,s7
    8000205a:	0025151b          	slliw	a0,a0,0x2
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	f6c080e7          	jalr	-148(ra) # 80001fca <growproc>
    80002066:	10054463          	bltz	a0,8000216e <ps+0x148>
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
    8000209a:	0cf4fc63          	bgeu	s1,a5,80002172 <ps+0x14c>
    8000209e:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    800020a2:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800020a4:	8c3e                	mv	s8,a5
    800020a6:	a069                	j	80002130 <ps+0x10a>
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
    if (localCount < count)
    800020c0:	0179f963          	bgeu	s3,s7,800020d2 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    800020c4:	00399793          	slli	a5,s3,0x3
    800020c8:	97ce                	add	a5,a5,s3
    800020ca:	078a                	slli	a5,a5,0x2
    800020cc:	97d6                	add	a5,a5,s5
    800020ce:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800020d2:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	b9c080e7          	jalr	-1124(ra) # 80001c70 <myproc>
    800020dc:	86d2                	mv	a3,s4
    800020de:	8656                	mv	a2,s5
    800020e0:	85da                	mv	a1,s6
    800020e2:	6928                	ld	a0,80(a0)
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	74e080e7          	jalr	1870(ra) # 80001832 <copyout>
}
    800020ec:	8526                	mv	a0,s1
    800020ee:	fb040113          	addi	sp,s0,-80
    800020f2:	60a6                	ld	ra,72(sp)
    800020f4:	6406                	ld	s0,64(sp)
    800020f6:	74e2                	ld	s1,56(sp)
    800020f8:	7942                	ld	s2,48(sp)
    800020fa:	79a2                	ld	s3,40(sp)
    800020fc:	7a02                	ld	s4,32(sp)
    800020fe:	6ae2                	ld	s5,24(sp)
    80002100:	6b42                	ld	s6,16(sp)
    80002102:	6ba2                	ld	s7,8(sp)
    80002104:	6c02                	ld	s8,0(sp)
    80002106:	6161                	addi	sp,sp,80
    80002108:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    8000210a:	5b9c                	lw	a5,48(a5)
    8000210c:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	d04080e7          	jalr	-764(ra) # 80000e16 <release>
        localCount++;
    8000211a:	2985                	addiw	s3,s3,1
    8000211c:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002120:	16848493          	addi	s1,s1,360
    80002124:	f984fee3          	bgeu	s1,s8,800020c0 <ps+0x9a>
        if (localCount == count)
    80002128:	02490913          	addi	s2,s2,36
    8000212c:	fb3b83e3          	beq	s7,s3,800020d2 <ps+0xac>
        acquire(&p->lock);
    80002130:	8526                	mv	a0,s1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	c30080e7          	jalr	-976(ra) # 80000d62 <acquire>
        if (p->state == UNUSED)
    8000213a:	4c9c                	lw	a5,24(s1)
    8000213c:	d7b5                	beqz	a5,800020a8 <ps+0x82>
        loc_result[localCount].state = p->state;
    8000213e:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002142:	549c                	lw	a5,40(s1)
    80002144:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002148:	54dc                	lw	a5,44(s1)
    8000214a:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    8000214e:	589c                	lw	a5,48(s1)
    80002150:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002154:	4641                	li	a2,16
    80002156:	85ca                	mv	a1,s2
    80002158:	15848513          	addi	a0,s1,344
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	aba080e7          	jalr	-1350(ra) # 80001c16 <copy_array>
        if (p->parent != 0) // init
    80002164:	7c9c                	ld	a5,56(s1)
    80002166:	f3d5                	bnez	a5,8000210a <ps+0xe4>
    80002168:	b765                	j	80002110 <ps+0xea>
        return result;
    8000216a:	4481                	li	s1,0
    8000216c:	b741                	j	800020ec <ps+0xc6>
        return result;
    8000216e:	4481                	li	s1,0
    80002170:	bfb5                	j	800020ec <ps+0xc6>
        return result;
    80002172:	4481                	li	s1,0
    80002174:	bfa5                	j	800020ec <ps+0xc6>

0000000080002176 <fork>:
{
    80002176:	7139                	addi	sp,sp,-64
    80002178:	fc06                	sd	ra,56(sp)
    8000217a:	f822                	sd	s0,48(sp)
    8000217c:	f426                	sd	s1,40(sp)
    8000217e:	f04a                	sd	s2,32(sp)
    80002180:	ec4e                	sd	s3,24(sp)
    80002182:	e852                	sd	s4,16(sp)
    80002184:	e456                	sd	s5,8(sp)
    80002186:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	ae8080e7          	jalr	-1304(ra) # 80001c70 <myproc>
    80002190:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80002192:	00000097          	auipc	ra,0x0
    80002196:	ce8080e7          	jalr	-792(ra) # 80001e7a <allocproc>
    8000219a:	10050c63          	beqz	a0,800022b2 <fork+0x13c>
    8000219e:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800021a0:	048ab603          	ld	a2,72(s5)
    800021a4:	692c                	ld	a1,80(a0)
    800021a6:	050ab503          	ld	a0,80(s5)
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	578080e7          	jalr	1400(ra) # 80001722 <uvmcopy>
    800021b2:	04054863          	bltz	a0,80002202 <fork+0x8c>
    np->sz = p->sz;
    800021b6:	048ab783          	ld	a5,72(s5)
    800021ba:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800021be:	058ab683          	ld	a3,88(s5)
    800021c2:	87b6                	mv	a5,a3
    800021c4:	058a3703          	ld	a4,88(s4)
    800021c8:	12068693          	addi	a3,a3,288
    800021cc:	0007b803          	ld	a6,0(a5)
    800021d0:	6788                	ld	a0,8(a5)
    800021d2:	6b8c                	ld	a1,16(a5)
    800021d4:	6f90                	ld	a2,24(a5)
    800021d6:	01073023          	sd	a6,0(a4)
    800021da:	e708                	sd	a0,8(a4)
    800021dc:	eb0c                	sd	a1,16(a4)
    800021de:	ef10                	sd	a2,24(a4)
    800021e0:	02078793          	addi	a5,a5,32
    800021e4:	02070713          	addi	a4,a4,32
    800021e8:	fed792e3          	bne	a5,a3,800021cc <fork+0x56>
    np->trapframe->a0 = 0;
    800021ec:	058a3783          	ld	a5,88(s4)
    800021f0:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800021f4:	0d0a8493          	addi	s1,s5,208
    800021f8:	0d0a0913          	addi	s2,s4,208
    800021fc:	150a8993          	addi	s3,s5,336
    80002200:	a00d                	j	80002222 <fork+0xac>
        freeproc(np);
    80002202:	8552                	mv	a0,s4
    80002204:	00000097          	auipc	ra,0x0
    80002208:	c1e080e7          	jalr	-994(ra) # 80001e22 <freeproc>
        release(&np->lock);
    8000220c:	8552                	mv	a0,s4
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	c08080e7          	jalr	-1016(ra) # 80000e16 <release>
        return -1;
    80002216:	597d                	li	s2,-1
    80002218:	a059                	j	8000229e <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    8000221a:	04a1                	addi	s1,s1,8
    8000221c:	0921                	addi	s2,s2,8
    8000221e:	01348b63          	beq	s1,s3,80002234 <fork+0xbe>
        if (p->ofile[i])
    80002222:	6088                	ld	a0,0(s1)
    80002224:	d97d                	beqz	a0,8000221a <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002226:	00003097          	auipc	ra,0x3
    8000222a:	904080e7          	jalr	-1788(ra) # 80004b2a <filedup>
    8000222e:	00a93023          	sd	a0,0(s2)
    80002232:	b7e5                	j	8000221a <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002234:	150ab503          	ld	a0,336(s5)
    80002238:	00002097          	auipc	ra,0x2
    8000223c:	a72080e7          	jalr	-1422(ra) # 80003caa <idup>
    80002240:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002244:	4641                	li	a2,16
    80002246:	158a8593          	addi	a1,s5,344
    8000224a:	158a0513          	addi	a0,s4,344
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	d5a080e7          	jalr	-678(ra) # 80000fa8 <safestrcpy>
    pid = np->pid;
    80002256:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    8000225a:	8552                	mv	a0,s4
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	bba080e7          	jalr	-1094(ra) # 80000e16 <release>
    acquire(&wait_lock);
    80002264:	0002f497          	auipc	s1,0x2f
    80002268:	eb448493          	addi	s1,s1,-332 # 80031118 <wait_lock>
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	af4080e7          	jalr	-1292(ra) # 80000d62 <acquire>
    np->parent = p;
    80002276:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    8000227a:	8526                	mv	a0,s1
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	b9a080e7          	jalr	-1126(ra) # 80000e16 <release>
    acquire(&np->lock);
    80002284:	8552                	mv	a0,s4
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	adc080e7          	jalr	-1316(ra) # 80000d62 <acquire>
    np->state = RUNNABLE;
    8000228e:	478d                	li	a5,3
    80002290:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002294:	8552                	mv	a0,s4
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	b80080e7          	jalr	-1152(ra) # 80000e16 <release>
}
    8000229e:	854a                	mv	a0,s2
    800022a0:	70e2                	ld	ra,56(sp)
    800022a2:	7442                	ld	s0,48(sp)
    800022a4:	74a2                	ld	s1,40(sp)
    800022a6:	7902                	ld	s2,32(sp)
    800022a8:	69e2                	ld	s3,24(sp)
    800022aa:	6a42                	ld	s4,16(sp)
    800022ac:	6aa2                	ld	s5,8(sp)
    800022ae:	6121                	addi	sp,sp,64
    800022b0:	8082                	ret
        return -1;
    800022b2:	597d                	li	s2,-1
    800022b4:	b7ed                	j	8000229e <fork+0x128>

00000000800022b6 <scheduler>:
{
    800022b6:	1101                	addi	sp,sp,-32
    800022b8:	ec06                	sd	ra,24(sp)
    800022ba:	e822                	sd	s0,16(sp)
    800022bc:	e426                	sd	s1,8(sp)
    800022be:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800022c0:	00006497          	auipc	s1,0x6
    800022c4:	6f848493          	addi	s1,s1,1784 # 800089b8 <sched_pointer>
    800022c8:	609c                	ld	a5,0(s1)
    800022ca:	9782                	jalr	a5
    while (1)
    800022cc:	bff5                	j	800022c8 <scheduler+0x12>

00000000800022ce <sched>:
{
    800022ce:	7179                	addi	sp,sp,-48
    800022d0:	f406                	sd	ra,40(sp)
    800022d2:	f022                	sd	s0,32(sp)
    800022d4:	ec26                	sd	s1,24(sp)
    800022d6:	e84a                	sd	s2,16(sp)
    800022d8:	e44e                	sd	s3,8(sp)
    800022da:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	994080e7          	jalr	-1644(ra) # 80001c70 <myproc>
    800022e4:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	a02080e7          	jalr	-1534(ra) # 80000ce8 <holding>
    800022ee:	c53d                	beqz	a0,8000235c <sched+0x8e>
    800022f0:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800022f2:	2781                	sext.w	a5,a5
    800022f4:	079e                	slli	a5,a5,0x7
    800022f6:	0002f717          	auipc	a4,0x2f
    800022fa:	a0a70713          	addi	a4,a4,-1526 # 80030d00 <cpus>
    800022fe:	97ba                	add	a5,a5,a4
    80002300:	5fb8                	lw	a4,120(a5)
    80002302:	4785                	li	a5,1
    80002304:	06f71463          	bne	a4,a5,8000236c <sched+0x9e>
    if (p->state == RUNNING)
    80002308:	4c98                	lw	a4,24(s1)
    8000230a:	4791                	li	a5,4
    8000230c:	06f70863          	beq	a4,a5,8000237c <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002310:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002314:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002316:	ebbd                	bnez	a5,8000238c <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002318:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    8000231a:	0002f917          	auipc	s2,0x2f
    8000231e:	9e690913          	addi	s2,s2,-1562 # 80030d00 <cpus>
    80002322:	2781                	sext.w	a5,a5
    80002324:	079e                	slli	a5,a5,0x7
    80002326:	97ca                	add	a5,a5,s2
    80002328:	07c7a983          	lw	s3,124(a5)
    8000232c:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    8000232e:	2581                	sext.w	a1,a1
    80002330:	059e                	slli	a1,a1,0x7
    80002332:	05a1                	addi	a1,a1,8
    80002334:	95ca                	add	a1,a1,s2
    80002336:	06048513          	addi	a0,s1,96
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	6e4080e7          	jalr	1764(ra) # 80002a1e <swtch>
    80002342:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002344:	2781                	sext.w	a5,a5
    80002346:	079e                	slli	a5,a5,0x7
    80002348:	993e                	add	s2,s2,a5
    8000234a:	07392e23          	sw	s3,124(s2)
}
    8000234e:	70a2                	ld	ra,40(sp)
    80002350:	7402                	ld	s0,32(sp)
    80002352:	64e2                	ld	s1,24(sp)
    80002354:	6942                	ld	s2,16(sp)
    80002356:	69a2                	ld	s3,8(sp)
    80002358:	6145                	addi	sp,sp,48
    8000235a:	8082                	ret
        panic("sched p->lock");
    8000235c:	00006517          	auipc	a0,0x6
    80002360:	efc50513          	addi	a0,a0,-260 # 80008258 <digits+0x208>
    80002364:	ffffe097          	auipc	ra,0xffffe
    80002368:	1dc080e7          	jalr	476(ra) # 80000540 <panic>
        panic("sched locks");
    8000236c:	00006517          	auipc	a0,0x6
    80002370:	efc50513          	addi	a0,a0,-260 # 80008268 <digits+0x218>
    80002374:	ffffe097          	auipc	ra,0xffffe
    80002378:	1cc080e7          	jalr	460(ra) # 80000540 <panic>
        panic("sched running");
    8000237c:	00006517          	auipc	a0,0x6
    80002380:	efc50513          	addi	a0,a0,-260 # 80008278 <digits+0x228>
    80002384:	ffffe097          	auipc	ra,0xffffe
    80002388:	1bc080e7          	jalr	444(ra) # 80000540 <panic>
        panic("sched interruptible");
    8000238c:	00006517          	auipc	a0,0x6
    80002390:	efc50513          	addi	a0,a0,-260 # 80008288 <digits+0x238>
    80002394:	ffffe097          	auipc	ra,0xffffe
    80002398:	1ac080e7          	jalr	428(ra) # 80000540 <panic>

000000008000239c <yield>:
{
    8000239c:	1101                	addi	sp,sp,-32
    8000239e:	ec06                	sd	ra,24(sp)
    800023a0:	e822                	sd	s0,16(sp)
    800023a2:	e426                	sd	s1,8(sp)
    800023a4:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	8ca080e7          	jalr	-1846(ra) # 80001c70 <myproc>
    800023ae:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	9b2080e7          	jalr	-1614(ra) # 80000d62 <acquire>
    p->state = RUNNABLE;
    800023b8:	478d                	li	a5,3
    800023ba:	cc9c                	sw	a5,24(s1)
    sched();
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	f12080e7          	jalr	-238(ra) # 800022ce <sched>
    release(&p->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	a50080e7          	jalr	-1456(ra) # 80000e16 <release>
}
    800023ce:	60e2                	ld	ra,24(sp)
    800023d0:	6442                	ld	s0,16(sp)
    800023d2:	64a2                	ld	s1,8(sp)
    800023d4:	6105                	addi	sp,sp,32
    800023d6:	8082                	ret

00000000800023d8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023d8:	7179                	addi	sp,sp,-48
    800023da:	f406                	sd	ra,40(sp)
    800023dc:	f022                	sd	s0,32(sp)
    800023de:	ec26                	sd	s1,24(sp)
    800023e0:	e84a                	sd	s2,16(sp)
    800023e2:	e44e                	sd	s3,8(sp)
    800023e4:	1800                	addi	s0,sp,48
    800023e6:	89aa                	mv	s3,a0
    800023e8:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800023ea:	00000097          	auipc	ra,0x0
    800023ee:	886080e7          	jalr	-1914(ra) # 80001c70 <myproc>
    800023f2:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	96e080e7          	jalr	-1682(ra) # 80000d62 <acquire>
    release(lk);
    800023fc:	854a                	mv	a0,s2
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	a18080e7          	jalr	-1512(ra) # 80000e16 <release>

    // Go to sleep.
    p->chan = chan;
    80002406:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    8000240a:	4789                	li	a5,2
    8000240c:	cc9c                	sw	a5,24(s1)

    sched();
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	ec0080e7          	jalr	-320(ra) # 800022ce <sched>

    // Tidy up.
    p->chan = 0;
    80002416:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	9fa080e7          	jalr	-1542(ra) # 80000e16 <release>
    acquire(lk);
    80002424:	854a                	mv	a0,s2
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	93c080e7          	jalr	-1732(ra) # 80000d62 <acquire>
}
    8000242e:	70a2                	ld	ra,40(sp)
    80002430:	7402                	ld	s0,32(sp)
    80002432:	64e2                	ld	s1,24(sp)
    80002434:	6942                	ld	s2,16(sp)
    80002436:	69a2                	ld	s3,8(sp)
    80002438:	6145                	addi	sp,sp,48
    8000243a:	8082                	ret

000000008000243c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000243c:	7139                	addi	sp,sp,-64
    8000243e:	fc06                	sd	ra,56(sp)
    80002440:	f822                	sd	s0,48(sp)
    80002442:	f426                	sd	s1,40(sp)
    80002444:	f04a                	sd	s2,32(sp)
    80002446:	ec4e                	sd	s3,24(sp)
    80002448:	e852                	sd	s4,16(sp)
    8000244a:	e456                	sd	s5,8(sp)
    8000244c:	0080                	addi	s0,sp,64
    8000244e:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002450:	0002f497          	auipc	s1,0x2f
    80002454:	ce048493          	addi	s1,s1,-800 # 80031130 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002458:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    8000245a:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000245c:	00034917          	auipc	s2,0x34
    80002460:	6d490913          	addi	s2,s2,1748 # 80036b30 <tickslock>
    80002464:	a811                	j	80002478 <wakeup+0x3c>
            }
            release(&p->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	9ae080e7          	jalr	-1618(ra) # 80000e16 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002470:	16848493          	addi	s1,s1,360
    80002474:	03248663          	beq	s1,s2,800024a0 <wakeup+0x64>
        if (p != myproc())
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	7f8080e7          	jalr	2040(ra) # 80001c70 <myproc>
    80002480:	fea488e3          	beq	s1,a0,80002470 <wakeup+0x34>
            acquire(&p->lock);
    80002484:	8526                	mv	a0,s1
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	8dc080e7          	jalr	-1828(ra) # 80000d62 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000248e:	4c9c                	lw	a5,24(s1)
    80002490:	fd379be3          	bne	a5,s3,80002466 <wakeup+0x2a>
    80002494:	709c                	ld	a5,32(s1)
    80002496:	fd4798e3          	bne	a5,s4,80002466 <wakeup+0x2a>
                p->state = RUNNABLE;
    8000249a:	0154ac23          	sw	s5,24(s1)
    8000249e:	b7e1                	j	80002466 <wakeup+0x2a>
        }
    }
}
    800024a0:	70e2                	ld	ra,56(sp)
    800024a2:	7442                	ld	s0,48(sp)
    800024a4:	74a2                	ld	s1,40(sp)
    800024a6:	7902                	ld	s2,32(sp)
    800024a8:	69e2                	ld	s3,24(sp)
    800024aa:	6a42                	ld	s4,16(sp)
    800024ac:	6aa2                	ld	s5,8(sp)
    800024ae:	6121                	addi	sp,sp,64
    800024b0:	8082                	ret

00000000800024b2 <reparent>:
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024c4:	0002f497          	auipc	s1,0x2f
    800024c8:	c6c48493          	addi	s1,s1,-916 # 80031130 <proc>
            pp->parent = initproc;
    800024cc:	00006a17          	auipc	s4,0x6
    800024d0:	5bca0a13          	addi	s4,s4,1468 # 80008a88 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024d4:	00034997          	auipc	s3,0x34
    800024d8:	65c98993          	addi	s3,s3,1628 # 80036b30 <tickslock>
    800024dc:	a029                	j	800024e6 <reparent+0x34>
    800024de:	16848493          	addi	s1,s1,360
    800024e2:	01348d63          	beq	s1,s3,800024fc <reparent+0x4a>
        if (pp->parent == p)
    800024e6:	7c9c                	ld	a5,56(s1)
    800024e8:	ff279be3          	bne	a5,s2,800024de <reparent+0x2c>
            pp->parent = initproc;
    800024ec:	000a3503          	ld	a0,0(s4)
    800024f0:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800024f2:	00000097          	auipc	ra,0x0
    800024f6:	f4a080e7          	jalr	-182(ra) # 8000243c <wakeup>
    800024fa:	b7d5                	j	800024de <reparent+0x2c>
}
    800024fc:	70a2                	ld	ra,40(sp)
    800024fe:	7402                	ld	s0,32(sp)
    80002500:	64e2                	ld	s1,24(sp)
    80002502:	6942                	ld	s2,16(sp)
    80002504:	69a2                	ld	s3,8(sp)
    80002506:	6a02                	ld	s4,0(sp)
    80002508:	6145                	addi	sp,sp,48
    8000250a:	8082                	ret

000000008000250c <exit>:
{
    8000250c:	7179                	addi	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	e052                	sd	s4,0(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	752080e7          	jalr	1874(ra) # 80001c70 <myproc>
    80002526:	89aa                	mv	s3,a0
    if (p == initproc)
    80002528:	00006797          	auipc	a5,0x6
    8000252c:	5607b783          	ld	a5,1376(a5) # 80008a88 <initproc>
    80002530:	0d050493          	addi	s1,a0,208
    80002534:	15050913          	addi	s2,a0,336
    80002538:	02a79363          	bne	a5,a0,8000255e <exit+0x52>
        panic("init exiting");
    8000253c:	00006517          	auipc	a0,0x6
    80002540:	d6450513          	addi	a0,a0,-668 # 800082a0 <digits+0x250>
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	ffc080e7          	jalr	-4(ra) # 80000540 <panic>
            fileclose(f);
    8000254c:	00002097          	auipc	ra,0x2
    80002550:	630080e7          	jalr	1584(ra) # 80004b7c <fileclose>
            p->ofile[fd] = 0;
    80002554:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002558:	04a1                	addi	s1,s1,8
    8000255a:	01248563          	beq	s1,s2,80002564 <exit+0x58>
        if (p->ofile[fd])
    8000255e:	6088                	ld	a0,0(s1)
    80002560:	f575                	bnez	a0,8000254c <exit+0x40>
    80002562:	bfdd                	j	80002558 <exit+0x4c>
    begin_op();
    80002564:	00002097          	auipc	ra,0x2
    80002568:	150080e7          	jalr	336(ra) # 800046b4 <begin_op>
    iput(p->cwd);
    8000256c:	1509b503          	ld	a0,336(s3)
    80002570:	00002097          	auipc	ra,0x2
    80002574:	932080e7          	jalr	-1742(ra) # 80003ea2 <iput>
    end_op();
    80002578:	00002097          	auipc	ra,0x2
    8000257c:	1ba080e7          	jalr	442(ra) # 80004732 <end_op>
    p->cwd = 0;
    80002580:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002584:	0002f497          	auipc	s1,0x2f
    80002588:	b9448493          	addi	s1,s1,-1132 # 80031118 <wait_lock>
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	7d4080e7          	jalr	2004(ra) # 80000d62 <acquire>
    reparent(p);
    80002596:	854e                	mv	a0,s3
    80002598:	00000097          	auipc	ra,0x0
    8000259c:	f1a080e7          	jalr	-230(ra) # 800024b2 <reparent>
    wakeup(p->parent);
    800025a0:	0389b503          	ld	a0,56(s3)
    800025a4:	00000097          	auipc	ra,0x0
    800025a8:	e98080e7          	jalr	-360(ra) # 8000243c <wakeup>
    acquire(&p->lock);
    800025ac:	854e                	mv	a0,s3
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	7b4080e7          	jalr	1972(ra) # 80000d62 <acquire>
    p->xstate = status;
    800025b6:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800025ba:	4795                	li	a5,5
    800025bc:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	fffff097          	auipc	ra,0xfffff
    800025c6:	854080e7          	jalr	-1964(ra) # 80000e16 <release>
    sched();
    800025ca:	00000097          	auipc	ra,0x0
    800025ce:	d04080e7          	jalr	-764(ra) # 800022ce <sched>
    panic("zombie exit");
    800025d2:	00006517          	auipc	a0,0x6
    800025d6:	cde50513          	addi	a0,a0,-802 # 800082b0 <digits+0x260>
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	f66080e7          	jalr	-154(ra) # 80000540 <panic>

00000000800025e2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025e2:	7179                	addi	sp,sp,-48
    800025e4:	f406                	sd	ra,40(sp)
    800025e6:	f022                	sd	s0,32(sp)
    800025e8:	ec26                	sd	s1,24(sp)
    800025ea:	e84a                	sd	s2,16(sp)
    800025ec:	e44e                	sd	s3,8(sp)
    800025ee:	1800                	addi	s0,sp,48
    800025f0:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800025f2:	0002f497          	auipc	s1,0x2f
    800025f6:	b3e48493          	addi	s1,s1,-1218 # 80031130 <proc>
    800025fa:	00034997          	auipc	s3,0x34
    800025fe:	53698993          	addi	s3,s3,1334 # 80036b30 <tickslock>
    {
        acquire(&p->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	75e080e7          	jalr	1886(ra) # 80000d62 <acquire>
        if (p->pid == pid)
    8000260c:	589c                	lw	a5,48(s1)
    8000260e:	01278d63          	beq	a5,s2,80002628 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	fffff097          	auipc	ra,0xfffff
    80002618:	802080e7          	jalr	-2046(ra) # 80000e16 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000261c:	16848493          	addi	s1,s1,360
    80002620:	ff3491e3          	bne	s1,s3,80002602 <kill+0x20>
    }
    return -1;
    80002624:	557d                	li	a0,-1
    80002626:	a829                	j	80002640 <kill+0x5e>
            p->killed = 1;
    80002628:	4785                	li	a5,1
    8000262a:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    8000262c:	4c98                	lw	a4,24(s1)
    8000262e:	4789                	li	a5,2
    80002630:	00f70f63          	beq	a4,a5,8000264e <kill+0x6c>
            release(&p->lock);
    80002634:	8526                	mv	a0,s1
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	7e0080e7          	jalr	2016(ra) # 80000e16 <release>
            return 0;
    8000263e:	4501                	li	a0,0
}
    80002640:	70a2                	ld	ra,40(sp)
    80002642:	7402                	ld	s0,32(sp)
    80002644:	64e2                	ld	s1,24(sp)
    80002646:	6942                	ld	s2,16(sp)
    80002648:	69a2                	ld	s3,8(sp)
    8000264a:	6145                	addi	sp,sp,48
    8000264c:	8082                	ret
                p->state = RUNNABLE;
    8000264e:	478d                	li	a5,3
    80002650:	cc9c                	sw	a5,24(s1)
    80002652:	b7cd                	j	80002634 <kill+0x52>

0000000080002654 <setkilled>:

void setkilled(struct proc *p)
{
    80002654:	1101                	addi	sp,sp,-32
    80002656:	ec06                	sd	ra,24(sp)
    80002658:	e822                	sd	s0,16(sp)
    8000265a:	e426                	sd	s1,8(sp)
    8000265c:	1000                	addi	s0,sp,32
    8000265e:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	702080e7          	jalr	1794(ra) # 80000d62 <acquire>
    p->killed = 1;
    80002668:	4785                	li	a5,1
    8000266a:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	7a8080e7          	jalr	1960(ra) # 80000e16 <release>
}
    80002676:	60e2                	ld	ra,24(sp)
    80002678:	6442                	ld	s0,16(sp)
    8000267a:	64a2                	ld	s1,8(sp)
    8000267c:	6105                	addi	sp,sp,32
    8000267e:	8082                	ret

0000000080002680 <killed>:

int killed(struct proc *p)
{
    80002680:	1101                	addi	sp,sp,-32
    80002682:	ec06                	sd	ra,24(sp)
    80002684:	e822                	sd	s0,16(sp)
    80002686:	e426                	sd	s1,8(sp)
    80002688:	e04a                	sd	s2,0(sp)
    8000268a:	1000                	addi	s0,sp,32
    8000268c:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	6d4080e7          	jalr	1748(ra) # 80000d62 <acquire>
    k = p->killed;
    80002696:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    8000269a:	8526                	mv	a0,s1
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	77a080e7          	jalr	1914(ra) # 80000e16 <release>
    return k;
}
    800026a4:	854a                	mv	a0,s2
    800026a6:	60e2                	ld	ra,24(sp)
    800026a8:	6442                	ld	s0,16(sp)
    800026aa:	64a2                	ld	s1,8(sp)
    800026ac:	6902                	ld	s2,0(sp)
    800026ae:	6105                	addi	sp,sp,32
    800026b0:	8082                	ret

00000000800026b2 <wait>:
{
    800026b2:	715d                	addi	sp,sp,-80
    800026b4:	e486                	sd	ra,72(sp)
    800026b6:	e0a2                	sd	s0,64(sp)
    800026b8:	fc26                	sd	s1,56(sp)
    800026ba:	f84a                	sd	s2,48(sp)
    800026bc:	f44e                	sd	s3,40(sp)
    800026be:	f052                	sd	s4,32(sp)
    800026c0:	ec56                	sd	s5,24(sp)
    800026c2:	e85a                	sd	s6,16(sp)
    800026c4:	e45e                	sd	s7,8(sp)
    800026c6:	e062                	sd	s8,0(sp)
    800026c8:	0880                	addi	s0,sp,80
    800026ca:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800026cc:	fffff097          	auipc	ra,0xfffff
    800026d0:	5a4080e7          	jalr	1444(ra) # 80001c70 <myproc>
    800026d4:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800026d6:	0002f517          	auipc	a0,0x2f
    800026da:	a4250513          	addi	a0,a0,-1470 # 80031118 <wait_lock>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	684080e7          	jalr	1668(ra) # 80000d62 <acquire>
        havekids = 0;
    800026e6:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800026e8:	4a15                	li	s4,5
                havekids = 1;
    800026ea:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026ec:	00034997          	auipc	s3,0x34
    800026f0:	44498993          	addi	s3,s3,1092 # 80036b30 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026f4:	0002fc17          	auipc	s8,0x2f
    800026f8:	a24c0c13          	addi	s8,s8,-1500 # 80031118 <wait_lock>
        havekids = 0;
    800026fc:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026fe:	0002f497          	auipc	s1,0x2f
    80002702:	a3248493          	addi	s1,s1,-1486 # 80031130 <proc>
    80002706:	a0bd                	j	80002774 <wait+0xc2>
                    pid = pp->pid;
    80002708:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000270c:	000b0e63          	beqz	s6,80002728 <wait+0x76>
    80002710:	4691                	li	a3,4
    80002712:	02c48613          	addi	a2,s1,44
    80002716:	85da                	mv	a1,s6
    80002718:	05093503          	ld	a0,80(s2)
    8000271c:	fffff097          	auipc	ra,0xfffff
    80002720:	116080e7          	jalr	278(ra) # 80001832 <copyout>
    80002724:	02054563          	bltz	a0,8000274e <wait+0x9c>
                    freeproc(pp);
    80002728:	8526                	mv	a0,s1
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	6f8080e7          	jalr	1784(ra) # 80001e22 <freeproc>
                    release(&pp->lock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	6e2080e7          	jalr	1762(ra) # 80000e16 <release>
                    release(&wait_lock);
    8000273c:	0002f517          	auipc	a0,0x2f
    80002740:	9dc50513          	addi	a0,a0,-1572 # 80031118 <wait_lock>
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	6d2080e7          	jalr	1746(ra) # 80000e16 <release>
                    return pid;
    8000274c:	a0b5                	j	800027b8 <wait+0x106>
                        release(&pp->lock);
    8000274e:	8526                	mv	a0,s1
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	6c6080e7          	jalr	1734(ra) # 80000e16 <release>
                        release(&wait_lock);
    80002758:	0002f517          	auipc	a0,0x2f
    8000275c:	9c050513          	addi	a0,a0,-1600 # 80031118 <wait_lock>
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	6b6080e7          	jalr	1718(ra) # 80000e16 <release>
                        return -1;
    80002768:	59fd                	li	s3,-1
    8000276a:	a0b9                	j	800027b8 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000276c:	16848493          	addi	s1,s1,360
    80002770:	03348463          	beq	s1,s3,80002798 <wait+0xe6>
            if (pp->parent == p)
    80002774:	7c9c                	ld	a5,56(s1)
    80002776:	ff279be3          	bne	a5,s2,8000276c <wait+0xba>
                acquire(&pp->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	5e6080e7          	jalr	1510(ra) # 80000d62 <acquire>
                if (pp->state == ZOMBIE)
    80002784:	4c9c                	lw	a5,24(s1)
    80002786:	f94781e3          	beq	a5,s4,80002708 <wait+0x56>
                release(&pp->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	68a080e7          	jalr	1674(ra) # 80000e16 <release>
                havekids = 1;
    80002794:	8756                	mv	a4,s5
    80002796:	bfd9                	j	8000276c <wait+0xba>
        if (!havekids || killed(p))
    80002798:	c719                	beqz	a4,800027a6 <wait+0xf4>
    8000279a:	854a                	mv	a0,s2
    8000279c:	00000097          	auipc	ra,0x0
    800027a0:	ee4080e7          	jalr	-284(ra) # 80002680 <killed>
    800027a4:	c51d                	beqz	a0,800027d2 <wait+0x120>
            release(&wait_lock);
    800027a6:	0002f517          	auipc	a0,0x2f
    800027aa:	97250513          	addi	a0,a0,-1678 # 80031118 <wait_lock>
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	668080e7          	jalr	1640(ra) # 80000e16 <release>
            return -1;
    800027b6:	59fd                	li	s3,-1
}
    800027b8:	854e                	mv	a0,s3
    800027ba:	60a6                	ld	ra,72(sp)
    800027bc:	6406                	ld	s0,64(sp)
    800027be:	74e2                	ld	s1,56(sp)
    800027c0:	7942                	ld	s2,48(sp)
    800027c2:	79a2                	ld	s3,40(sp)
    800027c4:	7a02                	ld	s4,32(sp)
    800027c6:	6ae2                	ld	s5,24(sp)
    800027c8:	6b42                	ld	s6,16(sp)
    800027ca:	6ba2                	ld	s7,8(sp)
    800027cc:	6c02                	ld	s8,0(sp)
    800027ce:	6161                	addi	sp,sp,80
    800027d0:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027d2:	85e2                	mv	a1,s8
    800027d4:	854a                	mv	a0,s2
    800027d6:	00000097          	auipc	ra,0x0
    800027da:	c02080e7          	jalr	-1022(ra) # 800023d8 <sleep>
        havekids = 0;
    800027de:	bf39                	j	800026fc <wait+0x4a>

00000000800027e0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027e0:	7179                	addi	sp,sp,-48
    800027e2:	f406                	sd	ra,40(sp)
    800027e4:	f022                	sd	s0,32(sp)
    800027e6:	ec26                	sd	s1,24(sp)
    800027e8:	e84a                	sd	s2,16(sp)
    800027ea:	e44e                	sd	s3,8(sp)
    800027ec:	e052                	sd	s4,0(sp)
    800027ee:	1800                	addi	s0,sp,48
    800027f0:	84aa                	mv	s1,a0
    800027f2:	892e                	mv	s2,a1
    800027f4:	89b2                	mv	s3,a2
    800027f6:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027f8:	fffff097          	auipc	ra,0xfffff
    800027fc:	478080e7          	jalr	1144(ra) # 80001c70 <myproc>
    if (user_dst)
    80002800:	c08d                	beqz	s1,80002822 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002802:	86d2                	mv	a3,s4
    80002804:	864e                	mv	a2,s3
    80002806:	85ca                	mv	a1,s2
    80002808:	6928                	ld	a0,80(a0)
    8000280a:	fffff097          	auipc	ra,0xfffff
    8000280e:	028080e7          	jalr	40(ra) # 80001832 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002812:	70a2                	ld	ra,40(sp)
    80002814:	7402                	ld	s0,32(sp)
    80002816:	64e2                	ld	s1,24(sp)
    80002818:	6942                	ld	s2,16(sp)
    8000281a:	69a2                	ld	s3,8(sp)
    8000281c:	6a02                	ld	s4,0(sp)
    8000281e:	6145                	addi	sp,sp,48
    80002820:	8082                	ret
        memmove((char *)dst, src, len);
    80002822:	000a061b          	sext.w	a2,s4
    80002826:	85ce                	mv	a1,s3
    80002828:	854a                	mv	a0,s2
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	690080e7          	jalr	1680(ra) # 80000eba <memmove>
        return 0;
    80002832:	8526                	mv	a0,s1
    80002834:	bff9                	j	80002812 <either_copyout+0x32>

0000000080002836 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002836:	7179                	addi	sp,sp,-48
    80002838:	f406                	sd	ra,40(sp)
    8000283a:	f022                	sd	s0,32(sp)
    8000283c:	ec26                	sd	s1,24(sp)
    8000283e:	e84a                	sd	s2,16(sp)
    80002840:	e44e                	sd	s3,8(sp)
    80002842:	e052                	sd	s4,0(sp)
    80002844:	1800                	addi	s0,sp,48
    80002846:	892a                	mv	s2,a0
    80002848:	84ae                	mv	s1,a1
    8000284a:	89b2                	mv	s3,a2
    8000284c:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	422080e7          	jalr	1058(ra) # 80001c70 <myproc>
    if (user_src)
    80002856:	c08d                	beqz	s1,80002878 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002858:	86d2                	mv	a3,s4
    8000285a:	864e                	mv	a2,s3
    8000285c:	85ca                	mv	a1,s2
    8000285e:	6928                	ld	a0,80(a0)
    80002860:	fffff097          	auipc	ra,0xfffff
    80002864:	05e080e7          	jalr	94(ra) # 800018be <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002868:	70a2                	ld	ra,40(sp)
    8000286a:	7402                	ld	s0,32(sp)
    8000286c:	64e2                	ld	s1,24(sp)
    8000286e:	6942                	ld	s2,16(sp)
    80002870:	69a2                	ld	s3,8(sp)
    80002872:	6a02                	ld	s4,0(sp)
    80002874:	6145                	addi	sp,sp,48
    80002876:	8082                	ret
        memmove(dst, (char *)src, len);
    80002878:	000a061b          	sext.w	a2,s4
    8000287c:	85ce                	mv	a1,s3
    8000287e:	854a                	mv	a0,s2
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	63a080e7          	jalr	1594(ra) # 80000eba <memmove>
        return 0;
    80002888:	8526                	mv	a0,s1
    8000288a:	bff9                	j	80002868 <either_copyin+0x32>

000000008000288c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000288c:	715d                	addi	sp,sp,-80
    8000288e:	e486                	sd	ra,72(sp)
    80002890:	e0a2                	sd	s0,64(sp)
    80002892:	fc26                	sd	s1,56(sp)
    80002894:	f84a                	sd	s2,48(sp)
    80002896:	f44e                	sd	s3,40(sp)
    80002898:	f052                	sd	s4,32(sp)
    8000289a:	ec56                	sd	s5,24(sp)
    8000289c:	e85a                	sd	s6,16(sp)
    8000289e:	e45e                	sd	s7,8(sp)
    800028a0:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800028a2:	00005517          	auipc	a0,0x5
    800028a6:	7e650513          	addi	a0,a0,2022 # 80008088 <digits+0x38>
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	cf2080e7          	jalr	-782(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028b2:	0002f497          	auipc	s1,0x2f
    800028b6:	9d648493          	addi	s1,s1,-1578 # 80031288 <proc+0x158>
    800028ba:	00034917          	auipc	s2,0x34
    800028be:	3ce90913          	addi	s2,s2,974 # 80036c88 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c2:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800028c4:	00006997          	auipc	s3,0x6
    800028c8:	9fc98993          	addi	s3,s3,-1540 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    800028cc:	00006a97          	auipc	s5,0x6
    800028d0:	9fca8a93          	addi	s5,s5,-1540 # 800082c8 <digits+0x278>
        printf("\n");
    800028d4:	00005a17          	auipc	s4,0x5
    800028d8:	7b4a0a13          	addi	s4,s4,1972 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028dc:	00006b97          	auipc	s7,0x6
    800028e0:	afcb8b93          	addi	s7,s7,-1284 # 800083d8 <states.0>
    800028e4:	a00d                	j	80002906 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800028e6:	ed86a583          	lw	a1,-296(a3)
    800028ea:	8556                	mv	a0,s5
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	cb0080e7          	jalr	-848(ra) # 8000059c <printf>
        printf("\n");
    800028f4:	8552                	mv	a0,s4
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	ca6080e7          	jalr	-858(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028fe:	16848493          	addi	s1,s1,360
    80002902:	03248263          	beq	s1,s2,80002926 <procdump+0x9a>
        if (p->state == UNUSED)
    80002906:	86a6                	mv	a3,s1
    80002908:	ec04a783          	lw	a5,-320(s1)
    8000290c:	dbed                	beqz	a5,800028fe <procdump+0x72>
            state = "???";
    8000290e:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002910:	fcfb6be3          	bltu	s6,a5,800028e6 <procdump+0x5a>
    80002914:	02079713          	slli	a4,a5,0x20
    80002918:	01d75793          	srli	a5,a4,0x1d
    8000291c:	97de                	add	a5,a5,s7
    8000291e:	6390                	ld	a2,0(a5)
    80002920:	f279                	bnez	a2,800028e6 <procdump+0x5a>
            state = "???";
    80002922:	864e                	mv	a2,s3
    80002924:	b7c9                	j	800028e6 <procdump+0x5a>
    }
}
    80002926:	60a6                	ld	ra,72(sp)
    80002928:	6406                	ld	s0,64(sp)
    8000292a:	74e2                	ld	s1,56(sp)
    8000292c:	7942                	ld	s2,48(sp)
    8000292e:	79a2                	ld	s3,40(sp)
    80002930:	7a02                	ld	s4,32(sp)
    80002932:	6ae2                	ld	s5,24(sp)
    80002934:	6b42                	ld	s6,16(sp)
    80002936:	6ba2                	ld	s7,8(sp)
    80002938:	6161                	addi	sp,sp,80
    8000293a:	8082                	ret

000000008000293c <schedls>:

void schedls()
{
    8000293c:	1141                	addi	sp,sp,-16
    8000293e:	e406                	sd	ra,8(sp)
    80002940:	e022                	sd	s0,0(sp)
    80002942:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002944:	00006517          	auipc	a0,0x6
    80002948:	99450513          	addi	a0,a0,-1644 # 800082d8 <digits+0x288>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	c50080e7          	jalr	-944(ra) # 8000059c <printf>
    printf("====================================\n");
    80002954:	00006517          	auipc	a0,0x6
    80002958:	9ac50513          	addi	a0,a0,-1620 # 80008300 <digits+0x2b0>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	c40080e7          	jalr	-960(ra) # 8000059c <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002964:	00006717          	auipc	a4,0x6
    80002968:	0b473703          	ld	a4,180(a4) # 80008a18 <available_schedulers+0x10>
    8000296c:	00006797          	auipc	a5,0x6
    80002970:	04c7b783          	ld	a5,76(a5) # 800089b8 <sched_pointer>
    80002974:	04f70663          	beq	a4,a5,800029c0 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	9b850513          	addi	a0,a0,-1608 # 80008330 <digits+0x2e0>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c1c080e7          	jalr	-996(ra) # 8000059c <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002988:	00006617          	auipc	a2,0x6
    8000298c:	09862603          	lw	a2,152(a2) # 80008a20 <available_schedulers+0x18>
    80002990:	00006597          	auipc	a1,0x6
    80002994:	07858593          	addi	a1,a1,120 # 80008a08 <available_schedulers>
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	9a050513          	addi	a0,a0,-1632 # 80008338 <digits+0x2e8>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	bfc080e7          	jalr	-1028(ra) # 8000059c <printf>
    }
    printf("\n*: current scheduler\n\n");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	99850513          	addi	a0,a0,-1640 # 80008340 <digits+0x2f0>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	bec080e7          	jalr	-1044(ra) # 8000059c <printf>
}
    800029b8:	60a2                	ld	ra,8(sp)
    800029ba:	6402                	ld	s0,0(sp)
    800029bc:	0141                	addi	sp,sp,16
    800029be:	8082                	ret
            printf("[*]\t");
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	96850513          	addi	a0,a0,-1688 # 80008328 <digits+0x2d8>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	bd4080e7          	jalr	-1068(ra) # 8000059c <printf>
    800029d0:	bf65                	j	80002988 <schedls+0x4c>

00000000800029d2 <schedset>:

void schedset(int id)
{
    800029d2:	1141                	addi	sp,sp,-16
    800029d4:	e406                	sd	ra,8(sp)
    800029d6:	e022                	sd	s0,0(sp)
    800029d8:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800029da:	e90d                	bnez	a0,80002a0c <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800029dc:	00006797          	auipc	a5,0x6
    800029e0:	03c7b783          	ld	a5,60(a5) # 80008a18 <available_schedulers+0x10>
    800029e4:	00006717          	auipc	a4,0x6
    800029e8:	fcf73a23          	sd	a5,-44(a4) # 800089b8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800029ec:	00006597          	auipc	a1,0x6
    800029f0:	01c58593          	addi	a1,a1,28 # 80008a08 <available_schedulers>
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	98c50513          	addi	a0,a0,-1652 # 80008380 <digits+0x330>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	ba0080e7          	jalr	-1120(ra) # 8000059c <printf>
    80002a04:	60a2                	ld	ra,8(sp)
    80002a06:	6402                	ld	s0,0(sp)
    80002a08:	0141                	addi	sp,sp,16
    80002a0a:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	94c50513          	addi	a0,a0,-1716 # 80008358 <digits+0x308>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b88080e7          	jalr	-1144(ra) # 8000059c <printf>
        return;
    80002a1c:	b7e5                	j	80002a04 <schedset+0x32>

0000000080002a1e <swtch>:
    80002a1e:	00153023          	sd	ra,0(a0)
    80002a22:	00253423          	sd	sp,8(a0)
    80002a26:	e900                	sd	s0,16(a0)
    80002a28:	ed04                	sd	s1,24(a0)
    80002a2a:	03253023          	sd	s2,32(a0)
    80002a2e:	03353423          	sd	s3,40(a0)
    80002a32:	03453823          	sd	s4,48(a0)
    80002a36:	03553c23          	sd	s5,56(a0)
    80002a3a:	05653023          	sd	s6,64(a0)
    80002a3e:	05753423          	sd	s7,72(a0)
    80002a42:	05853823          	sd	s8,80(a0)
    80002a46:	05953c23          	sd	s9,88(a0)
    80002a4a:	07a53023          	sd	s10,96(a0)
    80002a4e:	07b53423          	sd	s11,104(a0)
    80002a52:	0005b083          	ld	ra,0(a1)
    80002a56:	0085b103          	ld	sp,8(a1)
    80002a5a:	6980                	ld	s0,16(a1)
    80002a5c:	6d84                	ld	s1,24(a1)
    80002a5e:	0205b903          	ld	s2,32(a1)
    80002a62:	0285b983          	ld	s3,40(a1)
    80002a66:	0305ba03          	ld	s4,48(a1)
    80002a6a:	0385ba83          	ld	s5,56(a1)
    80002a6e:	0405bb03          	ld	s6,64(a1)
    80002a72:	0485bb83          	ld	s7,72(a1)
    80002a76:	0505bc03          	ld	s8,80(a1)
    80002a7a:	0585bc83          	ld	s9,88(a1)
    80002a7e:	0605bd03          	ld	s10,96(a1)
    80002a82:	0685bd83          	ld	s11,104(a1)
    80002a86:	8082                	ret

0000000080002a88 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a88:	1141                	addi	sp,sp,-16
    80002a8a:	e406                	sd	ra,8(sp)
    80002a8c:	e022                	sd	s0,0(sp)
    80002a8e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a90:	00006597          	auipc	a1,0x6
    80002a94:	97858593          	addi	a1,a1,-1672 # 80008408 <states.0+0x30>
    80002a98:	00034517          	auipc	a0,0x34
    80002a9c:	09850513          	addi	a0,a0,152 # 80036b30 <tickslock>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	232080e7          	jalr	562(ra) # 80000cd2 <initlock>
}
    80002aa8:	60a2                	ld	ra,8(sp)
    80002aaa:	6402                	ld	s0,0(sp)
    80002aac:	0141                	addi	sp,sp,16
    80002aae:	8082                	ret

0000000080002ab0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ab0:	1141                	addi	sp,sp,-16
    80002ab2:	e422                	sd	s0,8(sp)
    80002ab4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ab6:	00003797          	auipc	a5,0x3
    80002aba:	71a78793          	addi	a5,a5,1818 # 800061d0 <kernelvec>
    80002abe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ac2:	6422                	ld	s0,8(sp)
    80002ac4:	0141                	addi	sp,sp,16
    80002ac6:	8082                	ret

0000000080002ac8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ac8:	1141                	addi	sp,sp,-16
    80002aca:	e406                	sd	ra,8(sp)
    80002acc:	e022                	sd	s0,0(sp)
    80002ace:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	1a0080e7          	jalr	416(ra) # 80001c70 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002adc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ade:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ae2:	00004697          	auipc	a3,0x4
    80002ae6:	51e68693          	addi	a3,a3,1310 # 80007000 <_trampoline>
    80002aea:	00004717          	auipc	a4,0x4
    80002aee:	51670713          	addi	a4,a4,1302 # 80007000 <_trampoline>
    80002af2:	8f15                	sub	a4,a4,a3
    80002af4:	040007b7          	lui	a5,0x4000
    80002af8:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002afa:	07b2                	slli	a5,a5,0xc
    80002afc:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002afe:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b02:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b04:	18002673          	csrr	a2,satp
    80002b08:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b0a:	6d30                	ld	a2,88(a0)
    80002b0c:	6138                	ld	a4,64(a0)
    80002b0e:	6585                	lui	a1,0x1
    80002b10:	972e                	add	a4,a4,a1
    80002b12:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b14:	6d38                	ld	a4,88(a0)
    80002b16:	00000617          	auipc	a2,0x0
    80002b1a:	13060613          	addi	a2,a2,304 # 80002c46 <usertrap>
    80002b1e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b20:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b22:	8612                	mv	a2,tp
    80002b24:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b26:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b2a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b2e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b32:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b36:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b38:	6f18                	ld	a4,24(a4)
    80002b3a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b3e:	6928                	ld	a0,80(a0)
    80002b40:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b42:	00004717          	auipc	a4,0x4
    80002b46:	55a70713          	addi	a4,a4,1370 # 8000709c <userret>
    80002b4a:	8f15                	sub	a4,a4,a3
    80002b4c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b4e:	577d                	li	a4,-1
    80002b50:	177e                	slli	a4,a4,0x3f
    80002b52:	8d59                	or	a0,a0,a4
    80002b54:	9782                	jalr	a5
}
    80002b56:	60a2                	ld	ra,8(sp)
    80002b58:	6402                	ld	s0,0(sp)
    80002b5a:	0141                	addi	sp,sp,16
    80002b5c:	8082                	ret

0000000080002b5e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b5e:	1101                	addi	sp,sp,-32
    80002b60:	ec06                	sd	ra,24(sp)
    80002b62:	e822                	sd	s0,16(sp)
    80002b64:	e426                	sd	s1,8(sp)
    80002b66:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b68:	00034497          	auipc	s1,0x34
    80002b6c:	fc848493          	addi	s1,s1,-56 # 80036b30 <tickslock>
    80002b70:	8526                	mv	a0,s1
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	1f0080e7          	jalr	496(ra) # 80000d62 <acquire>
  ticks++;
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	f1650513          	addi	a0,a0,-234 # 80008a90 <ticks>
    80002b82:	411c                	lw	a5,0(a0)
    80002b84:	2785                	addiw	a5,a5,1
    80002b86:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b88:	00000097          	auipc	ra,0x0
    80002b8c:	8b4080e7          	jalr	-1868(ra) # 8000243c <wakeup>
  release(&tickslock);
    80002b90:	8526                	mv	a0,s1
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	284080e7          	jalr	644(ra) # 80000e16 <release>
}
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret

0000000080002ba4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	e426                	sd	s1,8(sp)
    80002bac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002bb2:	00074d63          	bltz	a4,80002bcc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002bb6:	57fd                	li	a5,-1
    80002bb8:	17fe                	slli	a5,a5,0x3f
    80002bba:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bbc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002bbe:	06f70363          	beq	a4,a5,80002c24 <devintr+0x80>
  }
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6105                	addi	sp,sp,32
    80002bca:	8082                	ret
     (scause & 0xff) == 9){
    80002bcc:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002bd0:	46a5                	li	a3,9
    80002bd2:	fed792e3          	bne	a5,a3,80002bb6 <devintr+0x12>
    int irq = plic_claim();
    80002bd6:	00003097          	auipc	ra,0x3
    80002bda:	702080e7          	jalr	1794(ra) # 800062d8 <plic_claim>
    80002bde:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002be0:	47a9                	li	a5,10
    80002be2:	02f50763          	beq	a0,a5,80002c10 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002be6:	4785                	li	a5,1
    80002be8:	02f50963          	beq	a0,a5,80002c1a <devintr+0x76>
    return 1;
    80002bec:	4505                	li	a0,1
    } else if(irq){
    80002bee:	d8f1                	beqz	s1,80002bc2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bf0:	85a6                	mv	a1,s1
    80002bf2:	00006517          	auipc	a0,0x6
    80002bf6:	81e50513          	addi	a0,a0,-2018 # 80008410 <states.0+0x38>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	9a2080e7          	jalr	-1630(ra) # 8000059c <printf>
      plic_complete(irq);
    80002c02:	8526                	mv	a0,s1
    80002c04:	00003097          	auipc	ra,0x3
    80002c08:	6f8080e7          	jalr	1784(ra) # 800062fc <plic_complete>
    return 1;
    80002c0c:	4505                	li	a0,1
    80002c0e:	bf55                	j	80002bc2 <devintr+0x1e>
      uartintr();
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	d9a080e7          	jalr	-614(ra) # 800009aa <uartintr>
    80002c18:	b7ed                	j	80002c02 <devintr+0x5e>
      virtio_disk_intr();
    80002c1a:	00004097          	auipc	ra,0x4
    80002c1e:	baa080e7          	jalr	-1110(ra) # 800067c4 <virtio_disk_intr>
    80002c22:	b7c5                	j	80002c02 <devintr+0x5e>
    if(cpuid() == 0){
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	020080e7          	jalr	32(ra) # 80001c44 <cpuid>
    80002c2c:	c901                	beqz	a0,80002c3c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c2e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c34:	14479073          	csrw	sip,a5
    return 2;
    80002c38:	4509                	li	a0,2
    80002c3a:	b761                	j	80002bc2 <devintr+0x1e>
      clockintr();
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	f22080e7          	jalr	-222(ra) # 80002b5e <clockintr>
    80002c44:	b7ed                	j	80002c2e <devintr+0x8a>

0000000080002c46 <usertrap>:
{
    80002c46:	7139                	addi	sp,sp,-64
    80002c48:	fc06                	sd	ra,56(sp)
    80002c4a:	f822                	sd	s0,48(sp)
    80002c4c:	f426                	sd	s1,40(sp)
    80002c4e:	f04a                	sd	s2,32(sp)
    80002c50:	ec4e                	sd	s3,24(sp)
    80002c52:	e852                	sd	s4,16(sp)
    80002c54:	e456                	sd	s5,8(sp)
    80002c56:	e05a                	sd	s6,0(sp)
    80002c58:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c5e:	1007f793          	andi	a5,a5,256
    80002c62:	efb5                	bnez	a5,80002cde <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c64:	00003797          	auipc	a5,0x3
    80002c68:	56c78793          	addi	a5,a5,1388 # 800061d0 <kernelvec>
    80002c6c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	000080e7          	jalr	ra # 80001c70 <myproc>
    80002c78:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c7a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7c:	14102773          	csrr	a4,sepc
    80002c80:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c82:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c86:	47a1                	li	a5,8
    80002c88:	06f70363          	beq	a4,a5,80002cee <usertrap+0xa8>
  } else if((which_dev = devintr()) != 0){
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	f18080e7          	jalr	-232(ra) # 80002ba4 <devintr>
    80002c94:	892a                	mv	s2,a0
    80002c96:	18051a63          	bnez	a0,80002e2a <usertrap+0x1e4>
    80002c9a:	14202773          	csrr	a4,scause
  } else if(r_scause()==0x000000000000000fL){
    80002c9e:	47bd                	li	a5,15
    80002ca0:	0af70563          	beq	a4,a5,80002d4a <usertrap+0x104>
    80002ca4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ca8:	5890                	lw	a2,48(s1)
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	7d650513          	addi	a0,a0,2006 # 80008480 <states.0+0xa8>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8ea080e7          	jalr	-1814(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cbe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cc2:	00005517          	auipc	a0,0x5
    80002cc6:	7ee50513          	addi	a0,a0,2030 # 800084b0 <states.0+0xd8>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	8d2080e7          	jalr	-1838(ra) # 8000059c <printf>
    setkilled(p);
    80002cd2:	8526                	mv	a0,s1
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	980080e7          	jalr	-1664(ra) # 80002654 <setkilled>
    80002cdc:	a825                	j	80002d14 <usertrap+0xce>
    panic("usertrap: not from user mode");
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	75250513          	addi	a0,a0,1874 # 80008430 <states.0+0x58>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	85a080e7          	jalr	-1958(ra) # 80000540 <panic>
    if(killed(p))
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	992080e7          	jalr	-1646(ra) # 80002680 <killed>
    80002cf6:	e521                	bnez	a0,80002d3e <usertrap+0xf8>
    p->trapframe->epc += 4;
    80002cf8:	6cb8                	ld	a4,88(s1)
    80002cfa:	6f1c                	ld	a5,24(a4)
    80002cfc:	0791                	addi	a5,a5,4
    80002cfe:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d00:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d04:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d08:	10079073          	csrw	sstatus,a5
    syscall();
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	392080e7          	jalr	914(ra) # 8000309e <syscall>
  if(killed(p))
    80002d14:	8526                	mv	a0,s1
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	96a080e7          	jalr	-1686(ra) # 80002680 <killed>
    80002d1e:	10051d63          	bnez	a0,80002e38 <usertrap+0x1f2>
  usertrapret();
    80002d22:	00000097          	auipc	ra,0x0
    80002d26:	da6080e7          	jalr	-602(ra) # 80002ac8 <usertrapret>
}
    80002d2a:	70e2                	ld	ra,56(sp)
    80002d2c:	7442                	ld	s0,48(sp)
    80002d2e:	74a2                	ld	s1,40(sp)
    80002d30:	7902                	ld	s2,32(sp)
    80002d32:	69e2                	ld	s3,24(sp)
    80002d34:	6a42                	ld	s4,16(sp)
    80002d36:	6aa2                	ld	s5,8(sp)
    80002d38:	6b02                	ld	s6,0(sp)
    80002d3a:	6121                	addi	sp,sp,64
    80002d3c:	8082                	ret
      exit(-1);
    80002d3e:	557d                	li	a0,-1
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	7cc080e7          	jalr	1996(ra) # 8000250c <exit>
    80002d48:	bf45                	j	80002cf8 <usertrap+0xb2>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d4a:	14302a73          	csrr	s4,stval
  uint64 base = PGROUNDDOWN(va);
    80002d4e:	77fd                	lui	a5,0xfffff
    80002d50:	00fa7a33          	and	s4,s4,a5
  pagetable_t pagetable = p->pagetable;
    80002d54:	0504bb03          	ld	s6,80(s1)
  pte = walk(pagetable,base,0);
    80002d58:	4601                	li	a2,0
    80002d5a:	85d2                	mv	a1,s4
    80002d5c:	855a                	mv	a0,s6
    80002d5e:	ffffe097          	auipc	ra,0xffffe
    80002d62:	3e4080e7          	jalr	996(ra) # 80001142 <walk>
    80002d66:	8aaa                	mv	s5,a0
  uint64 PA = PTE2PA(*pte);
    80002d68:	00053903          	ld	s2,0(a0)
    80002d6c:	00a95913          	srli	s2,s2,0xa
    80002d70:	0932                	slli	s2,s2,0xc
  if (PA==0)
    80002d72:	08090063          	beqz	s2,80002df2 <usertrap+0x1ac>
  if ((new_page = n_kallock())==0){
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	ecc080e7          	jalr	-308(ra) # 80000c42 <n_kallock>
    80002d7e:	89aa                	mv	s3,a0
    80002d80:	c149                	beqz	a0,80002e02 <usertrap+0x1bc>
  flags = PTE_FLAGS(*pte);
    80002d82:	000aba83          	ld	s5,0(s5)
    80002d86:	3ffafa93          	andi	s5,s5,1023
  memmove(new_page,(void *)PA, PGSIZE);
    80002d8a:	6605                	lui	a2,0x1
    80002d8c:	85ca                	mv	a1,s2
    80002d8e:	854e                	mv	a0,s3
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	12a080e7          	jalr	298(ra) # 80000eba <memmove>
  uvmunmap(pagetable, base, 1, 1);
    80002d98:	4685                	li	a3,1
    80002d9a:	4605                	li	a2,1
    80002d9c:	85d2                	mv	a1,s4
    80002d9e:	855a                	mv	a0,s6
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	650080e7          	jalr	1616(ra) # 800013f0 <uvmunmap>
  if(mappages(pagetable, base, PGSIZE, (uint64)new_page, flags) != 0){
    80002da8:	004ae713          	ori	a4,s5,4
    80002dac:	86ce                	mv	a3,s3
    80002dae:	6605                	lui	a2,0x1
    80002db0:	85d2                	mv	a1,s4
    80002db2:	855a                	mv	a0,s6
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	476080e7          	jalr	1142(ra) # 8000122a <mappages>
    80002dbc:	dd21                	beqz	a0,80002d14 <usertrap+0xce>
    if (counter[((uint64)new_page-KERNBASE )/ PGSIZE]==0)
    80002dbe:	800007b7          	lui	a5,0x80000
    80002dc2:	97ce                	add	a5,a5,s3
    80002dc4:	83b1                	srli	a5,a5,0xc
    80002dc6:	078a                	slli	a5,a5,0x2
    80002dc8:	0000e717          	auipc	a4,0xe
    80002dcc:	f3870713          	addi	a4,a4,-200 # 80010d00 <counter>
    80002dd0:	97ba                	add	a5,a5,a4
    80002dd2:	439c                	lw	a5,0(a5)
    80002dd4:	e7a9                	bnez	a5,80002e1e <usertrap+0x1d8>
      n_kfree(new_page);
    80002dd6:	854e                	mv	a0,s3
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	e36080e7          	jalr	-458(ra) # 80000c0e <n_kfree>
    printf("SEAGFAULT\n");
    80002de0:	00005517          	auipc	a0,0x5
    80002de4:	69050513          	addi	a0,a0,1680 # 80008470 <states.0+0x98>
    80002de8:	ffffd097          	auipc	ra,0xffffd
    80002dec:	7b4080e7          	jalr	1972(ra) # 8000059c <printf>
    80002df0:	b715                	j	80002d14 <usertrap+0xce>
    panic("uvmcopy: walkaddr failed\n");
    80002df2:	00005517          	auipc	a0,0x5
    80002df6:	65e50513          	addi	a0,a0,1630 # 80008450 <states.0+0x78>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	746080e7          	jalr	1862(ra) # 80000540 <panic>
        printf("SEAGFAULT\n");
    80002e02:	00005517          	auipc	a0,0x5
    80002e06:	66e50513          	addi	a0,a0,1646 # 80008470 <states.0+0x98>
    80002e0a:	ffffd097          	auipc	ra,0xffffd
    80002e0e:	792080e7          	jalr	1938(ra) # 8000059c <printf>
        setkilled(p);
    80002e12:	8526                	mv	a0,s1
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	840080e7          	jalr	-1984(ra) # 80002654 <setkilled>
    80002e1c:	b79d                	j	80002d82 <usertrap+0x13c>
      ref_decrement((void *)PA);
    80002e1e:	854a                	mv	a0,s2
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	e8c080e7          	jalr	-372(ra) # 80000cac <ref_decrement>
    80002e28:	bf65                	j	80002de0 <usertrap+0x19a>
  if(killed(p))
    80002e2a:	8526                	mv	a0,s1
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	854080e7          	jalr	-1964(ra) # 80002680 <killed>
    80002e34:	c901                	beqz	a0,80002e44 <usertrap+0x1fe>
    80002e36:	a011                	j	80002e3a <usertrap+0x1f4>
    80002e38:	4901                	li	s2,0
    exit(-1);
    80002e3a:	557d                	li	a0,-1
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	6d0080e7          	jalr	1744(ra) # 8000250c <exit>
  if(which_dev == 2)
    80002e44:	4789                	li	a5,2
    80002e46:	ecf91ee3          	bne	s2,a5,80002d22 <usertrap+0xdc>
    yield();
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	552080e7          	jalr	1362(ra) # 8000239c <yield>
    80002e52:	bdc1                	j	80002d22 <usertrap+0xdc>

0000000080002e54 <kerneltrap>:
{
    80002e54:	7179                	addi	sp,sp,-48
    80002e56:	f406                	sd	ra,40(sp)
    80002e58:	f022                	sd	s0,32(sp)
    80002e5a:	ec26                	sd	s1,24(sp)
    80002e5c:	e84a                	sd	s2,16(sp)
    80002e5e:	e44e                	sd	s3,8(sp)
    80002e60:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e62:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e66:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e6a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e6e:	1004f793          	andi	a5,s1,256
    80002e72:	cb85                	beqz	a5,80002ea2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e78:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e7a:	ef85                	bnez	a5,80002eb2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	d28080e7          	jalr	-728(ra) # 80002ba4 <devintr>
    80002e84:	cd1d                	beqz	a0,80002ec2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e86:	4789                	li	a5,2
    80002e88:	06f50a63          	beq	a0,a5,80002efc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e8c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e90:	10049073          	csrw	sstatus,s1
}
    80002e94:	70a2                	ld	ra,40(sp)
    80002e96:	7402                	ld	s0,32(sp)
    80002e98:	64e2                	ld	s1,24(sp)
    80002e9a:	6942                	ld	s2,16(sp)
    80002e9c:	69a2                	ld	s3,8(sp)
    80002e9e:	6145                	addi	sp,sp,48
    80002ea0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ea2:	00005517          	auipc	a0,0x5
    80002ea6:	62e50513          	addi	a0,a0,1582 # 800084d0 <states.0+0xf8>
    80002eaa:	ffffd097          	auipc	ra,0xffffd
    80002eae:	696080e7          	jalr	1686(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002eb2:	00005517          	auipc	a0,0x5
    80002eb6:	64650513          	addi	a0,a0,1606 # 800084f8 <states.0+0x120>
    80002eba:	ffffd097          	auipc	ra,0xffffd
    80002ebe:	686080e7          	jalr	1670(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002ec2:	85ce                	mv	a1,s3
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	65450513          	addi	a0,a0,1620 # 80008518 <states.0+0x140>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	6d0080e7          	jalr	1744(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ed4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ed8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002edc:	00005517          	auipc	a0,0x5
    80002ee0:	64c50513          	addi	a0,a0,1612 # 80008528 <states.0+0x150>
    80002ee4:	ffffd097          	auipc	ra,0xffffd
    80002ee8:	6b8080e7          	jalr	1720(ra) # 8000059c <printf>
    panic("kerneltrap");
    80002eec:	00005517          	auipc	a0,0x5
    80002ef0:	65450513          	addi	a0,a0,1620 # 80008540 <states.0+0x168>
    80002ef4:	ffffd097          	auipc	ra,0xffffd
    80002ef8:	64c080e7          	jalr	1612(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	d74080e7          	jalr	-652(ra) # 80001c70 <myproc>
    80002f04:	d541                	beqz	a0,80002e8c <kerneltrap+0x38>
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	d6a080e7          	jalr	-662(ra) # 80001c70 <myproc>
    80002f0e:	4d18                	lw	a4,24(a0)
    80002f10:	4791                	li	a5,4
    80002f12:	f6f71de3          	bne	a4,a5,80002e8c <kerneltrap+0x38>
    yield();
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	486080e7          	jalr	1158(ra) # 8000239c <yield>
    80002f1e:	b7bd                	j	80002e8c <kerneltrap+0x38>

0000000080002f20 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f20:	1101                	addi	sp,sp,-32
    80002f22:	ec06                	sd	ra,24(sp)
    80002f24:	e822                	sd	s0,16(sp)
    80002f26:	e426                	sd	s1,8(sp)
    80002f28:	1000                	addi	s0,sp,32
    80002f2a:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	d44080e7          	jalr	-700(ra) # 80001c70 <myproc>
    switch (n)
    80002f34:	4795                	li	a5,5
    80002f36:	0497e163          	bltu	a5,s1,80002f78 <argraw+0x58>
    80002f3a:	048a                	slli	s1,s1,0x2
    80002f3c:	00005717          	auipc	a4,0x5
    80002f40:	63c70713          	addi	a4,a4,1596 # 80008578 <states.0+0x1a0>
    80002f44:	94ba                	add	s1,s1,a4
    80002f46:	409c                	lw	a5,0(s1)
    80002f48:	97ba                	add	a5,a5,a4
    80002f4a:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f4c:	6d3c                	ld	a5,88(a0)
    80002f4e:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f50:	60e2                	ld	ra,24(sp)
    80002f52:	6442                	ld	s0,16(sp)
    80002f54:	64a2                	ld	s1,8(sp)
    80002f56:	6105                	addi	sp,sp,32
    80002f58:	8082                	ret
        return p->trapframe->a1;
    80002f5a:	6d3c                	ld	a5,88(a0)
    80002f5c:	7fa8                	ld	a0,120(a5)
    80002f5e:	bfcd                	j	80002f50 <argraw+0x30>
        return p->trapframe->a2;
    80002f60:	6d3c                	ld	a5,88(a0)
    80002f62:	63c8                	ld	a0,128(a5)
    80002f64:	b7f5                	j	80002f50 <argraw+0x30>
        return p->trapframe->a3;
    80002f66:	6d3c                	ld	a5,88(a0)
    80002f68:	67c8                	ld	a0,136(a5)
    80002f6a:	b7dd                	j	80002f50 <argraw+0x30>
        return p->trapframe->a4;
    80002f6c:	6d3c                	ld	a5,88(a0)
    80002f6e:	6bc8                	ld	a0,144(a5)
    80002f70:	b7c5                	j	80002f50 <argraw+0x30>
        return p->trapframe->a5;
    80002f72:	6d3c                	ld	a5,88(a0)
    80002f74:	6fc8                	ld	a0,152(a5)
    80002f76:	bfe9                	j	80002f50 <argraw+0x30>
    panic("argraw");
    80002f78:	00005517          	auipc	a0,0x5
    80002f7c:	5d850513          	addi	a0,a0,1496 # 80008550 <states.0+0x178>
    80002f80:	ffffd097          	auipc	ra,0xffffd
    80002f84:	5c0080e7          	jalr	1472(ra) # 80000540 <panic>

0000000080002f88 <fetchaddr>:
{
    80002f88:	1101                	addi	sp,sp,-32
    80002f8a:	ec06                	sd	ra,24(sp)
    80002f8c:	e822                	sd	s0,16(sp)
    80002f8e:	e426                	sd	s1,8(sp)
    80002f90:	e04a                	sd	s2,0(sp)
    80002f92:	1000                	addi	s0,sp,32
    80002f94:	84aa                	mv	s1,a0
    80002f96:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	cd8080e7          	jalr	-808(ra) # 80001c70 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002fa0:	653c                	ld	a5,72(a0)
    80002fa2:	02f4f863          	bgeu	s1,a5,80002fd2 <fetchaddr+0x4a>
    80002fa6:	00848713          	addi	a4,s1,8
    80002faa:	02e7e663          	bltu	a5,a4,80002fd6 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fae:	46a1                	li	a3,8
    80002fb0:	8626                	mv	a2,s1
    80002fb2:	85ca                	mv	a1,s2
    80002fb4:	6928                	ld	a0,80(a0)
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	908080e7          	jalr	-1784(ra) # 800018be <copyin>
    80002fbe:	00a03533          	snez	a0,a0
    80002fc2:	40a00533          	neg	a0,a0
}
    80002fc6:	60e2                	ld	ra,24(sp)
    80002fc8:	6442                	ld	s0,16(sp)
    80002fca:	64a2                	ld	s1,8(sp)
    80002fcc:	6902                	ld	s2,0(sp)
    80002fce:	6105                	addi	sp,sp,32
    80002fd0:	8082                	ret
        return -1;
    80002fd2:	557d                	li	a0,-1
    80002fd4:	bfcd                	j	80002fc6 <fetchaddr+0x3e>
    80002fd6:	557d                	li	a0,-1
    80002fd8:	b7fd                	j	80002fc6 <fetchaddr+0x3e>

0000000080002fda <fetchstr>:
{
    80002fda:	7179                	addi	sp,sp,-48
    80002fdc:	f406                	sd	ra,40(sp)
    80002fde:	f022                	sd	s0,32(sp)
    80002fe0:	ec26                	sd	s1,24(sp)
    80002fe2:	e84a                	sd	s2,16(sp)
    80002fe4:	e44e                	sd	s3,8(sp)
    80002fe6:	1800                	addi	s0,sp,48
    80002fe8:	892a                	mv	s2,a0
    80002fea:	84ae                	mv	s1,a1
    80002fec:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	c82080e7          	jalr	-894(ra) # 80001c70 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ff6:	86ce                	mv	a3,s3
    80002ff8:	864a                	mv	a2,s2
    80002ffa:	85a6                	mv	a1,s1
    80002ffc:	6928                	ld	a0,80(a0)
    80002ffe:	fffff097          	auipc	ra,0xfffff
    80003002:	94e080e7          	jalr	-1714(ra) # 8000194c <copyinstr>
    80003006:	00054e63          	bltz	a0,80003022 <fetchstr+0x48>
    return strlen(buf);
    8000300a:	8526                	mv	a0,s1
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	fce080e7          	jalr	-50(ra) # 80000fda <strlen>
}
    80003014:	70a2                	ld	ra,40(sp)
    80003016:	7402                	ld	s0,32(sp)
    80003018:	64e2                	ld	s1,24(sp)
    8000301a:	6942                	ld	s2,16(sp)
    8000301c:	69a2                	ld	s3,8(sp)
    8000301e:	6145                	addi	sp,sp,48
    80003020:	8082                	ret
        return -1;
    80003022:	557d                	li	a0,-1
    80003024:	bfc5                	j	80003014 <fetchstr+0x3a>

0000000080003026 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003026:	1101                	addi	sp,sp,-32
    80003028:	ec06                	sd	ra,24(sp)
    8000302a:	e822                	sd	s0,16(sp)
    8000302c:	e426                	sd	s1,8(sp)
    8000302e:	1000                	addi	s0,sp,32
    80003030:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003032:	00000097          	auipc	ra,0x0
    80003036:	eee080e7          	jalr	-274(ra) # 80002f20 <argraw>
    8000303a:	c088                	sw	a0,0(s1)
}
    8000303c:	60e2                	ld	ra,24(sp)
    8000303e:	6442                	ld	s0,16(sp)
    80003040:	64a2                	ld	s1,8(sp)
    80003042:	6105                	addi	sp,sp,32
    80003044:	8082                	ret

0000000080003046 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003046:	1101                	addi	sp,sp,-32
    80003048:	ec06                	sd	ra,24(sp)
    8000304a:	e822                	sd	s0,16(sp)
    8000304c:	e426                	sd	s1,8(sp)
    8000304e:	1000                	addi	s0,sp,32
    80003050:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003052:	00000097          	auipc	ra,0x0
    80003056:	ece080e7          	jalr	-306(ra) # 80002f20 <argraw>
    8000305a:	e088                	sd	a0,0(s1)
}
    8000305c:	60e2                	ld	ra,24(sp)
    8000305e:	6442                	ld	s0,16(sp)
    80003060:	64a2                	ld	s1,8(sp)
    80003062:	6105                	addi	sp,sp,32
    80003064:	8082                	ret

0000000080003066 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003066:	7179                	addi	sp,sp,-48
    80003068:	f406                	sd	ra,40(sp)
    8000306a:	f022                	sd	s0,32(sp)
    8000306c:	ec26                	sd	s1,24(sp)
    8000306e:	e84a                	sd	s2,16(sp)
    80003070:	1800                	addi	s0,sp,48
    80003072:	84ae                	mv	s1,a1
    80003074:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003076:	fd840593          	addi	a1,s0,-40
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	fcc080e7          	jalr	-52(ra) # 80003046 <argaddr>
    return fetchstr(addr, buf, max);
    80003082:	864a                	mv	a2,s2
    80003084:	85a6                	mv	a1,s1
    80003086:	fd843503          	ld	a0,-40(s0)
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	f50080e7          	jalr	-176(ra) # 80002fda <fetchstr>
}
    80003092:	70a2                	ld	ra,40(sp)
    80003094:	7402                	ld	s0,32(sp)
    80003096:	64e2                	ld	s1,24(sp)
    80003098:	6942                	ld	s2,16(sp)
    8000309a:	6145                	addi	sp,sp,48
    8000309c:	8082                	ret

000000008000309e <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    8000309e:	1101                	addi	sp,sp,-32
    800030a0:	ec06                	sd	ra,24(sp)
    800030a2:	e822                	sd	s0,16(sp)
    800030a4:	e426                	sd	s1,8(sp)
    800030a6:	e04a                	sd	s2,0(sp)
    800030a8:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	bc6080e7          	jalr	-1082(ra) # 80001c70 <myproc>
    800030b2:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800030b4:	05853903          	ld	s2,88(a0)
    800030b8:	0a893783          	ld	a5,168(s2)
    800030bc:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800030c0:	37fd                	addiw	a5,a5,-1 # 7fffffff <_entry-0x1>
    800030c2:	4765                	li	a4,25
    800030c4:	00f76f63          	bltu	a4,a5,800030e2 <syscall+0x44>
    800030c8:	00369713          	slli	a4,a3,0x3
    800030cc:	00005797          	auipc	a5,0x5
    800030d0:	4c478793          	addi	a5,a5,1220 # 80008590 <syscalls>
    800030d4:	97ba                	add	a5,a5,a4
    800030d6:	639c                	ld	a5,0(a5)
    800030d8:	c789                	beqz	a5,800030e2 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800030da:	9782                	jalr	a5
    800030dc:	06a93823          	sd	a0,112(s2)
    800030e0:	a839                	j	800030fe <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800030e2:	15848613          	addi	a2,s1,344
    800030e6:	588c                	lw	a1,48(s1)
    800030e8:	00005517          	auipc	a0,0x5
    800030ec:	47050513          	addi	a0,a0,1136 # 80008558 <states.0+0x180>
    800030f0:	ffffd097          	auipc	ra,0xffffd
    800030f4:	4ac080e7          	jalr	1196(ra) # 8000059c <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030f8:	6cbc                	ld	a5,88(s1)
    800030fa:	577d                	li	a4,-1
    800030fc:	fbb8                	sd	a4,112(a5)
    }
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6902                	ld	s2,0(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret

000000008000310a <sys_exit>:

extern struct proc proc[NPROC];

uint64
sys_exit(void)
{
    8000310a:	1101                	addi	sp,sp,-32
    8000310c:	ec06                	sd	ra,24(sp)
    8000310e:	e822                	sd	s0,16(sp)
    80003110:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80003112:	fec40593          	addi	a1,s0,-20
    80003116:	4501                	li	a0,0
    80003118:	00000097          	auipc	ra,0x0
    8000311c:	f0e080e7          	jalr	-242(ra) # 80003026 <argint>
    exit(n);
    80003120:	fec42503          	lw	a0,-20(s0)
    80003124:	fffff097          	auipc	ra,0xfffff
    80003128:	3e8080e7          	jalr	1000(ra) # 8000250c <exit>
    return 0; // not reached
}
    8000312c:	4501                	li	a0,0
    8000312e:	60e2                	ld	ra,24(sp)
    80003130:	6442                	ld	s0,16(sp)
    80003132:	6105                	addi	sp,sp,32
    80003134:	8082                	ret

0000000080003136 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003136:	1141                	addi	sp,sp,-16
    80003138:	e406                	sd	ra,8(sp)
    8000313a:	e022                	sd	s0,0(sp)
    8000313c:	0800                	addi	s0,sp,16
    return myproc()->pid;
    8000313e:	fffff097          	auipc	ra,0xfffff
    80003142:	b32080e7          	jalr	-1230(ra) # 80001c70 <myproc>
}
    80003146:	5908                	lw	a0,48(a0)
    80003148:	60a2                	ld	ra,8(sp)
    8000314a:	6402                	ld	s0,0(sp)
    8000314c:	0141                	addi	sp,sp,16
    8000314e:	8082                	ret

0000000080003150 <sys_fork>:

uint64
sys_fork(void)
{
    80003150:	1141                	addi	sp,sp,-16
    80003152:	e406                	sd	ra,8(sp)
    80003154:	e022                	sd	s0,0(sp)
    80003156:	0800                	addi	s0,sp,16
    return fork();
    80003158:	fffff097          	auipc	ra,0xfffff
    8000315c:	01e080e7          	jalr	30(ra) # 80002176 <fork>
}
    80003160:	60a2                	ld	ra,8(sp)
    80003162:	6402                	ld	s0,0(sp)
    80003164:	0141                	addi	sp,sp,16
    80003166:	8082                	ret

0000000080003168 <sys_wait>:

uint64
sys_wait(void)
{
    80003168:	1101                	addi	sp,sp,-32
    8000316a:	ec06                	sd	ra,24(sp)
    8000316c:	e822                	sd	s0,16(sp)
    8000316e:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003170:	fe840593          	addi	a1,s0,-24
    80003174:	4501                	li	a0,0
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	ed0080e7          	jalr	-304(ra) # 80003046 <argaddr>
    return wait(p);
    8000317e:	fe843503          	ld	a0,-24(s0)
    80003182:	fffff097          	auipc	ra,0xfffff
    80003186:	530080e7          	jalr	1328(ra) # 800026b2 <wait>
}
    8000318a:	60e2                	ld	ra,24(sp)
    8000318c:	6442                	ld	s0,16(sp)
    8000318e:	6105                	addi	sp,sp,32
    80003190:	8082                	ret

0000000080003192 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003192:	7179                	addi	sp,sp,-48
    80003194:	f406                	sd	ra,40(sp)
    80003196:	f022                	sd	s0,32(sp)
    80003198:	ec26                	sd	s1,24(sp)
    8000319a:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    8000319c:	fdc40593          	addi	a1,s0,-36
    800031a0:	4501                	li	a0,0
    800031a2:	00000097          	auipc	ra,0x0
    800031a6:	e84080e7          	jalr	-380(ra) # 80003026 <argint>
    addr = myproc()->sz;
    800031aa:	fffff097          	auipc	ra,0xfffff
    800031ae:	ac6080e7          	jalr	-1338(ra) # 80001c70 <myproc>
    800031b2:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800031b4:	fdc42503          	lw	a0,-36(s0)
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	e12080e7          	jalr	-494(ra) # 80001fca <growproc>
    800031c0:	00054863          	bltz	a0,800031d0 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800031c4:	8526                	mv	a0,s1
    800031c6:	70a2                	ld	ra,40(sp)
    800031c8:	7402                	ld	s0,32(sp)
    800031ca:	64e2                	ld	s1,24(sp)
    800031cc:	6145                	addi	sp,sp,48
    800031ce:	8082                	ret
        return -1;
    800031d0:	54fd                	li	s1,-1
    800031d2:	bfcd                	j	800031c4 <sys_sbrk+0x32>

00000000800031d4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031d4:	7139                	addi	sp,sp,-64
    800031d6:	fc06                	sd	ra,56(sp)
    800031d8:	f822                	sd	s0,48(sp)
    800031da:	f426                	sd	s1,40(sp)
    800031dc:	f04a                	sd	s2,32(sp)
    800031de:	ec4e                	sd	s3,24(sp)
    800031e0:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800031e2:	fcc40593          	addi	a1,s0,-52
    800031e6:	4501                	li	a0,0
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	e3e080e7          	jalr	-450(ra) # 80003026 <argint>
    acquire(&tickslock);
    800031f0:	00034517          	auipc	a0,0x34
    800031f4:	94050513          	addi	a0,a0,-1728 # 80036b30 <tickslock>
    800031f8:	ffffe097          	auipc	ra,0xffffe
    800031fc:	b6a080e7          	jalr	-1174(ra) # 80000d62 <acquire>
    ticks0 = ticks;
    80003200:	00006917          	auipc	s2,0x6
    80003204:	89092903          	lw	s2,-1904(s2) # 80008a90 <ticks>
    while (ticks - ticks0 < n)
    80003208:	fcc42783          	lw	a5,-52(s0)
    8000320c:	cf9d                	beqz	a5,8000324a <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    8000320e:	00034997          	auipc	s3,0x34
    80003212:	92298993          	addi	s3,s3,-1758 # 80036b30 <tickslock>
    80003216:	00006497          	auipc	s1,0x6
    8000321a:	87a48493          	addi	s1,s1,-1926 # 80008a90 <ticks>
        if (killed(myproc()))
    8000321e:	fffff097          	auipc	ra,0xfffff
    80003222:	a52080e7          	jalr	-1454(ra) # 80001c70 <myproc>
    80003226:	fffff097          	auipc	ra,0xfffff
    8000322a:	45a080e7          	jalr	1114(ra) # 80002680 <killed>
    8000322e:	ed15                	bnez	a0,8000326a <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003230:	85ce                	mv	a1,s3
    80003232:	8526                	mv	a0,s1
    80003234:	fffff097          	auipc	ra,0xfffff
    80003238:	1a4080e7          	jalr	420(ra) # 800023d8 <sleep>
    while (ticks - ticks0 < n)
    8000323c:	409c                	lw	a5,0(s1)
    8000323e:	412787bb          	subw	a5,a5,s2
    80003242:	fcc42703          	lw	a4,-52(s0)
    80003246:	fce7ece3          	bltu	a5,a4,8000321e <sys_sleep+0x4a>
    }
    release(&tickslock);
    8000324a:	00034517          	auipc	a0,0x34
    8000324e:	8e650513          	addi	a0,a0,-1818 # 80036b30 <tickslock>
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	bc4080e7          	jalr	-1084(ra) # 80000e16 <release>
    return 0;
    8000325a:	4501                	li	a0,0
}
    8000325c:	70e2                	ld	ra,56(sp)
    8000325e:	7442                	ld	s0,48(sp)
    80003260:	74a2                	ld	s1,40(sp)
    80003262:	7902                	ld	s2,32(sp)
    80003264:	69e2                	ld	s3,24(sp)
    80003266:	6121                	addi	sp,sp,64
    80003268:	8082                	ret
            release(&tickslock);
    8000326a:	00034517          	auipc	a0,0x34
    8000326e:	8c650513          	addi	a0,a0,-1850 # 80036b30 <tickslock>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	ba4080e7          	jalr	-1116(ra) # 80000e16 <release>
            return -1;
    8000327a:	557d                	li	a0,-1
    8000327c:	b7c5                	j	8000325c <sys_sleep+0x88>

000000008000327e <sys_kill>:

uint64
sys_kill(void)
{
    8000327e:	1101                	addi	sp,sp,-32
    80003280:	ec06                	sd	ra,24(sp)
    80003282:	e822                	sd	s0,16(sp)
    80003284:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003286:	fec40593          	addi	a1,s0,-20
    8000328a:	4501                	li	a0,0
    8000328c:	00000097          	auipc	ra,0x0
    80003290:	d9a080e7          	jalr	-614(ra) # 80003026 <argint>
    return kill(pid);
    80003294:	fec42503          	lw	a0,-20(s0)
    80003298:	fffff097          	auipc	ra,0xfffff
    8000329c:	34a080e7          	jalr	842(ra) # 800025e2 <kill>
}
    800032a0:	60e2                	ld	ra,24(sp)
    800032a2:	6442                	ld	s0,16(sp)
    800032a4:	6105                	addi	sp,sp,32
    800032a6:	8082                	ret

00000000800032a8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032a8:	1101                	addi	sp,sp,-32
    800032aa:	ec06                	sd	ra,24(sp)
    800032ac:	e822                	sd	s0,16(sp)
    800032ae:	e426                	sd	s1,8(sp)
    800032b0:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800032b2:	00034517          	auipc	a0,0x34
    800032b6:	87e50513          	addi	a0,a0,-1922 # 80036b30 <tickslock>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	aa8080e7          	jalr	-1368(ra) # 80000d62 <acquire>
    xticks = ticks;
    800032c2:	00005497          	auipc	s1,0x5
    800032c6:	7ce4a483          	lw	s1,1998(s1) # 80008a90 <ticks>
    release(&tickslock);
    800032ca:	00034517          	auipc	a0,0x34
    800032ce:	86650513          	addi	a0,a0,-1946 # 80036b30 <tickslock>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	b44080e7          	jalr	-1212(ra) # 80000e16 <release>
    return xticks;
}
    800032da:	02049513          	slli	a0,s1,0x20
    800032de:	9101                	srli	a0,a0,0x20
    800032e0:	60e2                	ld	ra,24(sp)
    800032e2:	6442                	ld	s0,16(sp)
    800032e4:	64a2                	ld	s1,8(sp)
    800032e6:	6105                	addi	sp,sp,32
    800032e8:	8082                	ret

00000000800032ea <sys_ps>:

void *
sys_ps(void)
{
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032f2:	fe042623          	sw	zero,-20(s0)
    800032f6:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032fa:	fec40593          	addi	a1,s0,-20
    800032fe:	4501                	li	a0,0
    80003300:	00000097          	auipc	ra,0x0
    80003304:	d26080e7          	jalr	-730(ra) # 80003026 <argint>
    argint(1, &count);
    80003308:	fe840593          	addi	a1,s0,-24
    8000330c:	4505                	li	a0,1
    8000330e:	00000097          	auipc	ra,0x0
    80003312:	d18080e7          	jalr	-744(ra) # 80003026 <argint>
    return ps((uint8)start, (uint8)count);
    80003316:	fe844583          	lbu	a1,-24(s0)
    8000331a:	fec44503          	lbu	a0,-20(s0)
    8000331e:	fffff097          	auipc	ra,0xfffff
    80003322:	d08080e7          	jalr	-760(ra) # 80002026 <ps>
}
    80003326:	60e2                	ld	ra,24(sp)
    80003328:	6442                	ld	s0,16(sp)
    8000332a:	6105                	addi	sp,sp,32
    8000332c:	8082                	ret

000000008000332e <sys_schedls>:

uint64 sys_schedls(void)
{
    8000332e:	1141                	addi	sp,sp,-16
    80003330:	e406                	sd	ra,8(sp)
    80003332:	e022                	sd	s0,0(sp)
    80003334:	0800                	addi	s0,sp,16
    schedls();
    80003336:	fffff097          	auipc	ra,0xfffff
    8000333a:	606080e7          	jalr	1542(ra) # 8000293c <schedls>
    return 0;
}
    8000333e:	4501                	li	a0,0
    80003340:	60a2                	ld	ra,8(sp)
    80003342:	6402                	ld	s0,0(sp)
    80003344:	0141                	addi	sp,sp,16
    80003346:	8082                	ret

0000000080003348 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003348:	1101                	addi	sp,sp,-32
    8000334a:	ec06                	sd	ra,24(sp)
    8000334c:	e822                	sd	s0,16(sp)
    8000334e:	1000                	addi	s0,sp,32
    int id = 0;
    80003350:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003354:	fec40593          	addi	a1,s0,-20
    80003358:	4501                	li	a0,0
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	ccc080e7          	jalr	-820(ra) # 80003026 <argint>
    schedset(id - 1);
    80003362:	fec42503          	lw	a0,-20(s0)
    80003366:	357d                	addiw	a0,a0,-1
    80003368:	fffff097          	auipc	ra,0xfffff
    8000336c:	66a080e7          	jalr	1642(ra) # 800029d2 <schedset>
    return 0;
}
    80003370:	4501                	li	a0,0
    80003372:	60e2                	ld	ra,24(sp)
    80003374:	6442                	ld	s0,16(sp)
    80003376:	6105                	addi	sp,sp,32
    80003378:	8082                	ret

000000008000337a <sys_va2pa>:

uint64 sys_va2pa(void)
{
    8000337a:	7179                	addi	sp,sp,-48
    8000337c:	f406                	sd	ra,40(sp)
    8000337e:	f022                	sd	s0,32(sp)
    80003380:	ec26                	sd	s1,24(sp)
    80003382:	e84a                	sd	s2,16(sp)
    80003384:	1800                	addi	s0,sp,48
    uint64 VA;
    int PID;
    argaddr(0, &VA);
    80003386:	fd840593          	addi	a1,s0,-40
    8000338a:	4501                	li	a0,0
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	cba080e7          	jalr	-838(ra) # 80003046 <argaddr>
    argint(1, &PID);
    80003394:	fd440593          	addi	a1,s0,-44
    80003398:	4505                	li	a0,1
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	c8c080e7          	jalr	-884(ra) # 80003026 <argint>

    struct proc *p;
    int validPID = 0;
    if (PID != 0)
    800033a2:	fd442783          	lw	a5,-44(s0)
    800033a6:	cf85                	beqz	a5,800033de <sys_va2pa+0x64>
    {
        // Checking if the PID given is valid
        for (p = proc; p < &proc[NPROC]; p++)
    800033a8:	0002e497          	auipc	s1,0x2e
    800033ac:	d8848493          	addi	s1,s1,-632 # 80031130 <proc>
    800033b0:	00033917          	auipc	s2,0x33
    800033b4:	78090913          	addi	s2,s2,1920 # 80036b30 <tickslock>
        {
            acquire(&p->lock);
    800033b8:	8526                	mv	a0,s1
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	9a8080e7          	jalr	-1624(ra) # 80000d62 <acquire>
            if (p->pid == PID)
    800033c2:	5898                	lw	a4,48(s1)
    800033c4:	fd442783          	lw	a5,-44(s0)
    800033c8:	02f70163          	beq	a4,a5,800033ea <sys_va2pa+0x70>
            {
                validPID = 1;
                release(&p->lock);
                break;
            }
            release(&p->lock);
    800033cc:	8526                	mv	a0,s1
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	a48080e7          	jalr	-1464(ra) # 80000e16 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    800033d6:	16848493          	addi	s1,s1,360
    800033da:	fd249fe3          	bne	s1,s2,800033b8 <sys_va2pa+0x3e>
        }
    }

    if (!validPID)
    {
        p = myproc();
    800033de:	fffff097          	auipc	ra,0xfffff
    800033e2:	892080e7          	jalr	-1902(ra) # 80001c70 <myproc>
    800033e6:	84aa                	mv	s1,a0
    800033e8:	a031                	j	800033f4 <sys_va2pa+0x7a>
                release(&p->lock);
    800033ea:	8526                	mv	a0,s1
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	a2a080e7          	jalr	-1494(ra) # 80000e16 <release>
    }

    pagetable_t pagetable = p->pagetable;
    uint64 PA = walkaddr(pagetable, VA);
    800033f4:	fd843583          	ld	a1,-40(s0)
    800033f8:	68a8                	ld	a0,80(s1)
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	dee080e7          	jalr	-530(ra) # 800011e8 <walkaddr>
    PA |= (0xFFF & VA);
    80003402:	fd843783          	ld	a5,-40(s0)
    80003406:	17d2                	slli	a5,a5,0x34
    80003408:	93d1                	srli	a5,a5,0x34
    }
    else 
    {
        return PA; 
    }
}
    8000340a:	8d5d                	or	a0,a0,a5
    8000340c:	70a2                	ld	ra,40(sp)
    8000340e:	7402                	ld	s0,32(sp)
    80003410:	64e2                	ld	s1,24(sp)
    80003412:	6942                	ld	s2,16(sp)
    80003414:	6145                	addi	sp,sp,48
    80003416:	8082                	ret

0000000080003418 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    80003418:	1141                	addi	sp,sp,-16
    8000341a:	e406                	sd	ra,8(sp)
    8000341c:	e022                	sd	s0,0(sp)
    8000341e:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    80003420:	00005597          	auipc	a1,0x5
    80003424:	6485b583          	ld	a1,1608(a1) # 80008a68 <FREE_PAGES>
    80003428:	00005517          	auipc	a0,0x5
    8000342c:	14850513          	addi	a0,a0,328 # 80008570 <states.0+0x198>
    80003430:	ffffd097          	auipc	ra,0xffffd
    80003434:	16c080e7          	jalr	364(ra) # 8000059c <printf>
    return 0;
    80003438:	4501                	li	a0,0
    8000343a:	60a2                	ld	ra,8(sp)
    8000343c:	6402                	ld	s0,0(sp)
    8000343e:	0141                	addi	sp,sp,16
    80003440:	8082                	ret

0000000080003442 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003442:	7179                	addi	sp,sp,-48
    80003444:	f406                	sd	ra,40(sp)
    80003446:	f022                	sd	s0,32(sp)
    80003448:	ec26                	sd	s1,24(sp)
    8000344a:	e84a                	sd	s2,16(sp)
    8000344c:	e44e                	sd	s3,8(sp)
    8000344e:	e052                	sd	s4,0(sp)
    80003450:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003452:	00005597          	auipc	a1,0x5
    80003456:	21658593          	addi	a1,a1,534 # 80008668 <syscalls+0xd8>
    8000345a:	00033517          	auipc	a0,0x33
    8000345e:	6ee50513          	addi	a0,a0,1774 # 80036b48 <bcache>
    80003462:	ffffe097          	auipc	ra,0xffffe
    80003466:	870080e7          	jalr	-1936(ra) # 80000cd2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000346a:	0003b797          	auipc	a5,0x3b
    8000346e:	6de78793          	addi	a5,a5,1758 # 8003eb48 <bcache+0x8000>
    80003472:	0003c717          	auipc	a4,0x3c
    80003476:	93e70713          	addi	a4,a4,-1730 # 8003edb0 <bcache+0x8268>
    8000347a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000347e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003482:	00033497          	auipc	s1,0x33
    80003486:	6de48493          	addi	s1,s1,1758 # 80036b60 <bcache+0x18>
    b->next = bcache.head.next;
    8000348a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000348c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000348e:	00005a17          	auipc	s4,0x5
    80003492:	1e2a0a13          	addi	s4,s4,482 # 80008670 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003496:	2b893783          	ld	a5,696(s2)
    8000349a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000349c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034a0:	85d2                	mv	a1,s4
    800034a2:	01048513          	addi	a0,s1,16
    800034a6:	00001097          	auipc	ra,0x1
    800034aa:	4c8080e7          	jalr	1224(ra) # 8000496e <initsleeplock>
    bcache.head.next->prev = b;
    800034ae:	2b893783          	ld	a5,696(s2)
    800034b2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034b4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034b8:	45848493          	addi	s1,s1,1112
    800034bc:	fd349de3          	bne	s1,s3,80003496 <binit+0x54>
  }
}
    800034c0:	70a2                	ld	ra,40(sp)
    800034c2:	7402                	ld	s0,32(sp)
    800034c4:	64e2                	ld	s1,24(sp)
    800034c6:	6942                	ld	s2,16(sp)
    800034c8:	69a2                	ld	s3,8(sp)
    800034ca:	6a02                	ld	s4,0(sp)
    800034cc:	6145                	addi	sp,sp,48
    800034ce:	8082                	ret

00000000800034d0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034d0:	7179                	addi	sp,sp,-48
    800034d2:	f406                	sd	ra,40(sp)
    800034d4:	f022                	sd	s0,32(sp)
    800034d6:	ec26                	sd	s1,24(sp)
    800034d8:	e84a                	sd	s2,16(sp)
    800034da:	e44e                	sd	s3,8(sp)
    800034dc:	1800                	addi	s0,sp,48
    800034de:	892a                	mv	s2,a0
    800034e0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034e2:	00033517          	auipc	a0,0x33
    800034e6:	66650513          	addi	a0,a0,1638 # 80036b48 <bcache>
    800034ea:	ffffe097          	auipc	ra,0xffffe
    800034ee:	878080e7          	jalr	-1928(ra) # 80000d62 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034f2:	0003c497          	auipc	s1,0x3c
    800034f6:	90e4b483          	ld	s1,-1778(s1) # 8003ee00 <bcache+0x82b8>
    800034fa:	0003c797          	auipc	a5,0x3c
    800034fe:	8b678793          	addi	a5,a5,-1866 # 8003edb0 <bcache+0x8268>
    80003502:	02f48f63          	beq	s1,a5,80003540 <bread+0x70>
    80003506:	873e                	mv	a4,a5
    80003508:	a021                	j	80003510 <bread+0x40>
    8000350a:	68a4                	ld	s1,80(s1)
    8000350c:	02e48a63          	beq	s1,a4,80003540 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003510:	449c                	lw	a5,8(s1)
    80003512:	ff279ce3          	bne	a5,s2,8000350a <bread+0x3a>
    80003516:	44dc                	lw	a5,12(s1)
    80003518:	ff3799e3          	bne	a5,s3,8000350a <bread+0x3a>
      b->refcnt++;
    8000351c:	40bc                	lw	a5,64(s1)
    8000351e:	2785                	addiw	a5,a5,1
    80003520:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003522:	00033517          	auipc	a0,0x33
    80003526:	62650513          	addi	a0,a0,1574 # 80036b48 <bcache>
    8000352a:	ffffe097          	auipc	ra,0xffffe
    8000352e:	8ec080e7          	jalr	-1812(ra) # 80000e16 <release>
      acquiresleep(&b->lock);
    80003532:	01048513          	addi	a0,s1,16
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	472080e7          	jalr	1138(ra) # 800049a8 <acquiresleep>
      return b;
    8000353e:	a8b9                	j	8000359c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003540:	0003c497          	auipc	s1,0x3c
    80003544:	8b84b483          	ld	s1,-1864(s1) # 8003edf8 <bcache+0x82b0>
    80003548:	0003c797          	auipc	a5,0x3c
    8000354c:	86878793          	addi	a5,a5,-1944 # 8003edb0 <bcache+0x8268>
    80003550:	00f48863          	beq	s1,a5,80003560 <bread+0x90>
    80003554:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003556:	40bc                	lw	a5,64(s1)
    80003558:	cf81                	beqz	a5,80003570 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000355a:	64a4                	ld	s1,72(s1)
    8000355c:	fee49de3          	bne	s1,a4,80003556 <bread+0x86>
  panic("bget: no buffers");
    80003560:	00005517          	auipc	a0,0x5
    80003564:	11850513          	addi	a0,a0,280 # 80008678 <syscalls+0xe8>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	fd8080e7          	jalr	-40(ra) # 80000540 <panic>
      b->dev = dev;
    80003570:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003574:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003578:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000357c:	4785                	li	a5,1
    8000357e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003580:	00033517          	auipc	a0,0x33
    80003584:	5c850513          	addi	a0,a0,1480 # 80036b48 <bcache>
    80003588:	ffffe097          	auipc	ra,0xffffe
    8000358c:	88e080e7          	jalr	-1906(ra) # 80000e16 <release>
      acquiresleep(&b->lock);
    80003590:	01048513          	addi	a0,s1,16
    80003594:	00001097          	auipc	ra,0x1
    80003598:	414080e7          	jalr	1044(ra) # 800049a8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000359c:	409c                	lw	a5,0(s1)
    8000359e:	cb89                	beqz	a5,800035b0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035a0:	8526                	mv	a0,s1
    800035a2:	70a2                	ld	ra,40(sp)
    800035a4:	7402                	ld	s0,32(sp)
    800035a6:	64e2                	ld	s1,24(sp)
    800035a8:	6942                	ld	s2,16(sp)
    800035aa:	69a2                	ld	s3,8(sp)
    800035ac:	6145                	addi	sp,sp,48
    800035ae:	8082                	ret
    virtio_disk_rw(b, 0);
    800035b0:	4581                	li	a1,0
    800035b2:	8526                	mv	a0,s1
    800035b4:	00003097          	auipc	ra,0x3
    800035b8:	fde080e7          	jalr	-34(ra) # 80006592 <virtio_disk_rw>
    b->valid = 1;
    800035bc:	4785                	li	a5,1
    800035be:	c09c                	sw	a5,0(s1)
  return b;
    800035c0:	b7c5                	j	800035a0 <bread+0xd0>

00000000800035c2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035c2:	1101                	addi	sp,sp,-32
    800035c4:	ec06                	sd	ra,24(sp)
    800035c6:	e822                	sd	s0,16(sp)
    800035c8:	e426                	sd	s1,8(sp)
    800035ca:	1000                	addi	s0,sp,32
    800035cc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035ce:	0541                	addi	a0,a0,16
    800035d0:	00001097          	auipc	ra,0x1
    800035d4:	472080e7          	jalr	1138(ra) # 80004a42 <holdingsleep>
    800035d8:	cd01                	beqz	a0,800035f0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035da:	4585                	li	a1,1
    800035dc:	8526                	mv	a0,s1
    800035de:	00003097          	auipc	ra,0x3
    800035e2:	fb4080e7          	jalr	-76(ra) # 80006592 <virtio_disk_rw>
}
    800035e6:	60e2                	ld	ra,24(sp)
    800035e8:	6442                	ld	s0,16(sp)
    800035ea:	64a2                	ld	s1,8(sp)
    800035ec:	6105                	addi	sp,sp,32
    800035ee:	8082                	ret
    panic("bwrite");
    800035f0:	00005517          	auipc	a0,0x5
    800035f4:	0a050513          	addi	a0,a0,160 # 80008690 <syscalls+0x100>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	f48080e7          	jalr	-184(ra) # 80000540 <panic>

0000000080003600 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003600:	1101                	addi	sp,sp,-32
    80003602:	ec06                	sd	ra,24(sp)
    80003604:	e822                	sd	s0,16(sp)
    80003606:	e426                	sd	s1,8(sp)
    80003608:	e04a                	sd	s2,0(sp)
    8000360a:	1000                	addi	s0,sp,32
    8000360c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000360e:	01050913          	addi	s2,a0,16
    80003612:	854a                	mv	a0,s2
    80003614:	00001097          	auipc	ra,0x1
    80003618:	42e080e7          	jalr	1070(ra) # 80004a42 <holdingsleep>
    8000361c:	c92d                	beqz	a0,8000368e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000361e:	854a                	mv	a0,s2
    80003620:	00001097          	auipc	ra,0x1
    80003624:	3de080e7          	jalr	990(ra) # 800049fe <releasesleep>

  acquire(&bcache.lock);
    80003628:	00033517          	auipc	a0,0x33
    8000362c:	52050513          	addi	a0,a0,1312 # 80036b48 <bcache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	732080e7          	jalr	1842(ra) # 80000d62 <acquire>
  b->refcnt--;
    80003638:	40bc                	lw	a5,64(s1)
    8000363a:	37fd                	addiw	a5,a5,-1
    8000363c:	0007871b          	sext.w	a4,a5
    80003640:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003642:	eb05                	bnez	a4,80003672 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003644:	68bc                	ld	a5,80(s1)
    80003646:	64b8                	ld	a4,72(s1)
    80003648:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000364a:	64bc                	ld	a5,72(s1)
    8000364c:	68b8                	ld	a4,80(s1)
    8000364e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003650:	0003b797          	auipc	a5,0x3b
    80003654:	4f878793          	addi	a5,a5,1272 # 8003eb48 <bcache+0x8000>
    80003658:	2b87b703          	ld	a4,696(a5)
    8000365c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000365e:	0003b717          	auipc	a4,0x3b
    80003662:	75270713          	addi	a4,a4,1874 # 8003edb0 <bcache+0x8268>
    80003666:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003668:	2b87b703          	ld	a4,696(a5)
    8000366c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000366e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003672:	00033517          	auipc	a0,0x33
    80003676:	4d650513          	addi	a0,a0,1238 # 80036b48 <bcache>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	79c080e7          	jalr	1948(ra) # 80000e16 <release>
}
    80003682:	60e2                	ld	ra,24(sp)
    80003684:	6442                	ld	s0,16(sp)
    80003686:	64a2                	ld	s1,8(sp)
    80003688:	6902                	ld	s2,0(sp)
    8000368a:	6105                	addi	sp,sp,32
    8000368c:	8082                	ret
    panic("brelse");
    8000368e:	00005517          	auipc	a0,0x5
    80003692:	00a50513          	addi	a0,a0,10 # 80008698 <syscalls+0x108>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	eaa080e7          	jalr	-342(ra) # 80000540 <panic>

000000008000369e <bpin>:

void
bpin(struct buf *b) {
    8000369e:	1101                	addi	sp,sp,-32
    800036a0:	ec06                	sd	ra,24(sp)
    800036a2:	e822                	sd	s0,16(sp)
    800036a4:	e426                	sd	s1,8(sp)
    800036a6:	1000                	addi	s0,sp,32
    800036a8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036aa:	00033517          	auipc	a0,0x33
    800036ae:	49e50513          	addi	a0,a0,1182 # 80036b48 <bcache>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	6b0080e7          	jalr	1712(ra) # 80000d62 <acquire>
  b->refcnt++;
    800036ba:	40bc                	lw	a5,64(s1)
    800036bc:	2785                	addiw	a5,a5,1
    800036be:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036c0:	00033517          	auipc	a0,0x33
    800036c4:	48850513          	addi	a0,a0,1160 # 80036b48 <bcache>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	74e080e7          	jalr	1870(ra) # 80000e16 <release>
}
    800036d0:	60e2                	ld	ra,24(sp)
    800036d2:	6442                	ld	s0,16(sp)
    800036d4:	64a2                	ld	s1,8(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret

00000000800036da <bunpin>:

void
bunpin(struct buf *b) {
    800036da:	1101                	addi	sp,sp,-32
    800036dc:	ec06                	sd	ra,24(sp)
    800036de:	e822                	sd	s0,16(sp)
    800036e0:	e426                	sd	s1,8(sp)
    800036e2:	1000                	addi	s0,sp,32
    800036e4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e6:	00033517          	auipc	a0,0x33
    800036ea:	46250513          	addi	a0,a0,1122 # 80036b48 <bcache>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	674080e7          	jalr	1652(ra) # 80000d62 <acquire>
  b->refcnt--;
    800036f6:	40bc                	lw	a5,64(s1)
    800036f8:	37fd                	addiw	a5,a5,-1
    800036fa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036fc:	00033517          	auipc	a0,0x33
    80003700:	44c50513          	addi	a0,a0,1100 # 80036b48 <bcache>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	712080e7          	jalr	1810(ra) # 80000e16 <release>
}
    8000370c:	60e2                	ld	ra,24(sp)
    8000370e:	6442                	ld	s0,16(sp)
    80003710:	64a2                	ld	s1,8(sp)
    80003712:	6105                	addi	sp,sp,32
    80003714:	8082                	ret

0000000080003716 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003716:	1101                	addi	sp,sp,-32
    80003718:	ec06                	sd	ra,24(sp)
    8000371a:	e822                	sd	s0,16(sp)
    8000371c:	e426                	sd	s1,8(sp)
    8000371e:	e04a                	sd	s2,0(sp)
    80003720:	1000                	addi	s0,sp,32
    80003722:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003724:	00d5d59b          	srliw	a1,a1,0xd
    80003728:	0003c797          	auipc	a5,0x3c
    8000372c:	afc7a783          	lw	a5,-1284(a5) # 8003f224 <sb+0x1c>
    80003730:	9dbd                	addw	a1,a1,a5
    80003732:	00000097          	auipc	ra,0x0
    80003736:	d9e080e7          	jalr	-610(ra) # 800034d0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000373a:	0074f713          	andi	a4,s1,7
    8000373e:	4785                	li	a5,1
    80003740:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003744:	14ce                	slli	s1,s1,0x33
    80003746:	90d9                	srli	s1,s1,0x36
    80003748:	00950733          	add	a4,a0,s1
    8000374c:	05874703          	lbu	a4,88(a4)
    80003750:	00e7f6b3          	and	a3,a5,a4
    80003754:	c69d                	beqz	a3,80003782 <bfree+0x6c>
    80003756:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003758:	94aa                	add	s1,s1,a0
    8000375a:	fff7c793          	not	a5,a5
    8000375e:	8f7d                	and	a4,a4,a5
    80003760:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003764:	00001097          	auipc	ra,0x1
    80003768:	126080e7          	jalr	294(ra) # 8000488a <log_write>
  brelse(bp);
    8000376c:	854a                	mv	a0,s2
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	e92080e7          	jalr	-366(ra) # 80003600 <brelse>
}
    80003776:	60e2                	ld	ra,24(sp)
    80003778:	6442                	ld	s0,16(sp)
    8000377a:	64a2                	ld	s1,8(sp)
    8000377c:	6902                	ld	s2,0(sp)
    8000377e:	6105                	addi	sp,sp,32
    80003780:	8082                	ret
    panic("freeing free block");
    80003782:	00005517          	auipc	a0,0x5
    80003786:	f1e50513          	addi	a0,a0,-226 # 800086a0 <syscalls+0x110>
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	db6080e7          	jalr	-586(ra) # 80000540 <panic>

0000000080003792 <balloc>:
{
    80003792:	711d                	addi	sp,sp,-96
    80003794:	ec86                	sd	ra,88(sp)
    80003796:	e8a2                	sd	s0,80(sp)
    80003798:	e4a6                	sd	s1,72(sp)
    8000379a:	e0ca                	sd	s2,64(sp)
    8000379c:	fc4e                	sd	s3,56(sp)
    8000379e:	f852                	sd	s4,48(sp)
    800037a0:	f456                	sd	s5,40(sp)
    800037a2:	f05a                	sd	s6,32(sp)
    800037a4:	ec5e                	sd	s7,24(sp)
    800037a6:	e862                	sd	s8,16(sp)
    800037a8:	e466                	sd	s9,8(sp)
    800037aa:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037ac:	0003c797          	auipc	a5,0x3c
    800037b0:	a607a783          	lw	a5,-1440(a5) # 8003f20c <sb+0x4>
    800037b4:	cff5                	beqz	a5,800038b0 <balloc+0x11e>
    800037b6:	8baa                	mv	s7,a0
    800037b8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037ba:	0003cb17          	auipc	s6,0x3c
    800037be:	a4eb0b13          	addi	s6,s6,-1458 # 8003f208 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037c4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037c8:	6c89                	lui	s9,0x2
    800037ca:	a061                	j	80003852 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037cc:	97ca                	add	a5,a5,s2
    800037ce:	8e55                	or	a2,a2,a3
    800037d0:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800037d4:	854a                	mv	a0,s2
    800037d6:	00001097          	auipc	ra,0x1
    800037da:	0b4080e7          	jalr	180(ra) # 8000488a <log_write>
        brelse(bp);
    800037de:	854a                	mv	a0,s2
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	e20080e7          	jalr	-480(ra) # 80003600 <brelse>
  bp = bread(dev, bno);
    800037e8:	85a6                	mv	a1,s1
    800037ea:	855e                	mv	a0,s7
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	ce4080e7          	jalr	-796(ra) # 800034d0 <bread>
    800037f4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037f6:	40000613          	li	a2,1024
    800037fa:	4581                	li	a1,0
    800037fc:	05850513          	addi	a0,a0,88
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	65e080e7          	jalr	1630(ra) # 80000e5e <memset>
  log_write(bp);
    80003808:	854a                	mv	a0,s2
    8000380a:	00001097          	auipc	ra,0x1
    8000380e:	080080e7          	jalr	128(ra) # 8000488a <log_write>
  brelse(bp);
    80003812:	854a                	mv	a0,s2
    80003814:	00000097          	auipc	ra,0x0
    80003818:	dec080e7          	jalr	-532(ra) # 80003600 <brelse>
}
    8000381c:	8526                	mv	a0,s1
    8000381e:	60e6                	ld	ra,88(sp)
    80003820:	6446                	ld	s0,80(sp)
    80003822:	64a6                	ld	s1,72(sp)
    80003824:	6906                	ld	s2,64(sp)
    80003826:	79e2                	ld	s3,56(sp)
    80003828:	7a42                	ld	s4,48(sp)
    8000382a:	7aa2                	ld	s5,40(sp)
    8000382c:	7b02                	ld	s6,32(sp)
    8000382e:	6be2                	ld	s7,24(sp)
    80003830:	6c42                	ld	s8,16(sp)
    80003832:	6ca2                	ld	s9,8(sp)
    80003834:	6125                	addi	sp,sp,96
    80003836:	8082                	ret
    brelse(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	dc6080e7          	jalr	-570(ra) # 80003600 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003842:	015c87bb          	addw	a5,s9,s5
    80003846:	00078a9b          	sext.w	s5,a5
    8000384a:	004b2703          	lw	a4,4(s6)
    8000384e:	06eaf163          	bgeu	s5,a4,800038b0 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003852:	41fad79b          	sraiw	a5,s5,0x1f
    80003856:	0137d79b          	srliw	a5,a5,0x13
    8000385a:	015787bb          	addw	a5,a5,s5
    8000385e:	40d7d79b          	sraiw	a5,a5,0xd
    80003862:	01cb2583          	lw	a1,28(s6)
    80003866:	9dbd                	addw	a1,a1,a5
    80003868:	855e                	mv	a0,s7
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	c66080e7          	jalr	-922(ra) # 800034d0 <bread>
    80003872:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003874:	004b2503          	lw	a0,4(s6)
    80003878:	000a849b          	sext.w	s1,s5
    8000387c:	8762                	mv	a4,s8
    8000387e:	faa4fde3          	bgeu	s1,a0,80003838 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003882:	00777693          	andi	a3,a4,7
    80003886:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000388a:	41f7579b          	sraiw	a5,a4,0x1f
    8000388e:	01d7d79b          	srliw	a5,a5,0x1d
    80003892:	9fb9                	addw	a5,a5,a4
    80003894:	4037d79b          	sraiw	a5,a5,0x3
    80003898:	00f90633          	add	a2,s2,a5
    8000389c:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800038a0:	00c6f5b3          	and	a1,a3,a2
    800038a4:	d585                	beqz	a1,800037cc <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038a6:	2705                	addiw	a4,a4,1
    800038a8:	2485                	addiw	s1,s1,1
    800038aa:	fd471ae3          	bne	a4,s4,8000387e <balloc+0xec>
    800038ae:	b769                	j	80003838 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800038b0:	00005517          	auipc	a0,0x5
    800038b4:	e0850513          	addi	a0,a0,-504 # 800086b8 <syscalls+0x128>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	ce4080e7          	jalr	-796(ra) # 8000059c <printf>
  return 0;
    800038c0:	4481                	li	s1,0
    800038c2:	bfa9                	j	8000381c <balloc+0x8a>

00000000800038c4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800038c4:	7179                	addi	sp,sp,-48
    800038c6:	f406                	sd	ra,40(sp)
    800038c8:	f022                	sd	s0,32(sp)
    800038ca:	ec26                	sd	s1,24(sp)
    800038cc:	e84a                	sd	s2,16(sp)
    800038ce:	e44e                	sd	s3,8(sp)
    800038d0:	e052                	sd	s4,0(sp)
    800038d2:	1800                	addi	s0,sp,48
    800038d4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038d6:	47ad                	li	a5,11
    800038d8:	02b7e863          	bltu	a5,a1,80003908 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800038dc:	02059793          	slli	a5,a1,0x20
    800038e0:	01e7d593          	srli	a1,a5,0x1e
    800038e4:	00b504b3          	add	s1,a0,a1
    800038e8:	0504a903          	lw	s2,80(s1)
    800038ec:	06091e63          	bnez	s2,80003968 <bmap+0xa4>
      addr = balloc(ip->dev);
    800038f0:	4108                	lw	a0,0(a0)
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	ea0080e7          	jalr	-352(ra) # 80003792 <balloc>
    800038fa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038fe:	06090563          	beqz	s2,80003968 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003902:	0524a823          	sw	s2,80(s1)
    80003906:	a08d                	j	80003968 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003908:	ff45849b          	addiw	s1,a1,-12
    8000390c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003910:	0ff00793          	li	a5,255
    80003914:	08e7e563          	bltu	a5,a4,8000399e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003918:	08052903          	lw	s2,128(a0)
    8000391c:	00091d63          	bnez	s2,80003936 <bmap+0x72>
      addr = balloc(ip->dev);
    80003920:	4108                	lw	a0,0(a0)
    80003922:	00000097          	auipc	ra,0x0
    80003926:	e70080e7          	jalr	-400(ra) # 80003792 <balloc>
    8000392a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000392e:	02090d63          	beqz	s2,80003968 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003932:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003936:	85ca                	mv	a1,s2
    80003938:	0009a503          	lw	a0,0(s3)
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	b94080e7          	jalr	-1132(ra) # 800034d0 <bread>
    80003944:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003946:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000394a:	02049713          	slli	a4,s1,0x20
    8000394e:	01e75593          	srli	a1,a4,0x1e
    80003952:	00b784b3          	add	s1,a5,a1
    80003956:	0004a903          	lw	s2,0(s1)
    8000395a:	02090063          	beqz	s2,8000397a <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000395e:	8552                	mv	a0,s4
    80003960:	00000097          	auipc	ra,0x0
    80003964:	ca0080e7          	jalr	-864(ra) # 80003600 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003968:	854a                	mv	a0,s2
    8000396a:	70a2                	ld	ra,40(sp)
    8000396c:	7402                	ld	s0,32(sp)
    8000396e:	64e2                	ld	s1,24(sp)
    80003970:	6942                	ld	s2,16(sp)
    80003972:	69a2                	ld	s3,8(sp)
    80003974:	6a02                	ld	s4,0(sp)
    80003976:	6145                	addi	sp,sp,48
    80003978:	8082                	ret
      addr = balloc(ip->dev);
    8000397a:	0009a503          	lw	a0,0(s3)
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	e14080e7          	jalr	-492(ra) # 80003792 <balloc>
    80003986:	0005091b          	sext.w	s2,a0
      if(addr){
    8000398a:	fc090ae3          	beqz	s2,8000395e <bmap+0x9a>
        a[bn] = addr;
    8000398e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003992:	8552                	mv	a0,s4
    80003994:	00001097          	auipc	ra,0x1
    80003998:	ef6080e7          	jalr	-266(ra) # 8000488a <log_write>
    8000399c:	b7c9                	j	8000395e <bmap+0x9a>
  panic("bmap: out of range");
    8000399e:	00005517          	auipc	a0,0x5
    800039a2:	d3250513          	addi	a0,a0,-718 # 800086d0 <syscalls+0x140>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	b9a080e7          	jalr	-1126(ra) # 80000540 <panic>

00000000800039ae <iget>:
{
    800039ae:	7179                	addi	sp,sp,-48
    800039b0:	f406                	sd	ra,40(sp)
    800039b2:	f022                	sd	s0,32(sp)
    800039b4:	ec26                	sd	s1,24(sp)
    800039b6:	e84a                	sd	s2,16(sp)
    800039b8:	e44e                	sd	s3,8(sp)
    800039ba:	e052                	sd	s4,0(sp)
    800039bc:	1800                	addi	s0,sp,48
    800039be:	89aa                	mv	s3,a0
    800039c0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039c2:	0003c517          	auipc	a0,0x3c
    800039c6:	86650513          	addi	a0,a0,-1946 # 8003f228 <itable>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	398080e7          	jalr	920(ra) # 80000d62 <acquire>
  empty = 0;
    800039d2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039d4:	0003c497          	auipc	s1,0x3c
    800039d8:	86c48493          	addi	s1,s1,-1940 # 8003f240 <itable+0x18>
    800039dc:	0003d697          	auipc	a3,0x3d
    800039e0:	2f468693          	addi	a3,a3,756 # 80040cd0 <log>
    800039e4:	a039                	j	800039f2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039e6:	02090b63          	beqz	s2,80003a1c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039ea:	08848493          	addi	s1,s1,136
    800039ee:	02d48a63          	beq	s1,a3,80003a22 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039f2:	449c                	lw	a5,8(s1)
    800039f4:	fef059e3          	blez	a5,800039e6 <iget+0x38>
    800039f8:	4098                	lw	a4,0(s1)
    800039fa:	ff3716e3          	bne	a4,s3,800039e6 <iget+0x38>
    800039fe:	40d8                	lw	a4,4(s1)
    80003a00:	ff4713e3          	bne	a4,s4,800039e6 <iget+0x38>
      ip->ref++;
    80003a04:	2785                	addiw	a5,a5,1
    80003a06:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a08:	0003c517          	auipc	a0,0x3c
    80003a0c:	82050513          	addi	a0,a0,-2016 # 8003f228 <itable>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	406080e7          	jalr	1030(ra) # 80000e16 <release>
      return ip;
    80003a18:	8926                	mv	s2,s1
    80003a1a:	a03d                	j	80003a48 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a1c:	f7f9                	bnez	a5,800039ea <iget+0x3c>
    80003a1e:	8926                	mv	s2,s1
    80003a20:	b7e9                	j	800039ea <iget+0x3c>
  if(empty == 0)
    80003a22:	02090c63          	beqz	s2,80003a5a <iget+0xac>
  ip->dev = dev;
    80003a26:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a2a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a2e:	4785                	li	a5,1
    80003a30:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a34:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a38:	0003b517          	auipc	a0,0x3b
    80003a3c:	7f050513          	addi	a0,a0,2032 # 8003f228 <itable>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	3d6080e7          	jalr	982(ra) # 80000e16 <release>
}
    80003a48:	854a                	mv	a0,s2
    80003a4a:	70a2                	ld	ra,40(sp)
    80003a4c:	7402                	ld	s0,32(sp)
    80003a4e:	64e2                	ld	s1,24(sp)
    80003a50:	6942                	ld	s2,16(sp)
    80003a52:	69a2                	ld	s3,8(sp)
    80003a54:	6a02                	ld	s4,0(sp)
    80003a56:	6145                	addi	sp,sp,48
    80003a58:	8082                	ret
    panic("iget: no inodes");
    80003a5a:	00005517          	auipc	a0,0x5
    80003a5e:	c8e50513          	addi	a0,a0,-882 # 800086e8 <syscalls+0x158>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	ade080e7          	jalr	-1314(ra) # 80000540 <panic>

0000000080003a6a <fsinit>:
fsinit(int dev) {
    80003a6a:	7179                	addi	sp,sp,-48
    80003a6c:	f406                	sd	ra,40(sp)
    80003a6e:	f022                	sd	s0,32(sp)
    80003a70:	ec26                	sd	s1,24(sp)
    80003a72:	e84a                	sd	s2,16(sp)
    80003a74:	e44e                	sd	s3,8(sp)
    80003a76:	1800                	addi	s0,sp,48
    80003a78:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a7a:	4585                	li	a1,1
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	a54080e7          	jalr	-1452(ra) # 800034d0 <bread>
    80003a84:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a86:	0003b997          	auipc	s3,0x3b
    80003a8a:	78298993          	addi	s3,s3,1922 # 8003f208 <sb>
    80003a8e:	02000613          	li	a2,32
    80003a92:	05850593          	addi	a1,a0,88
    80003a96:	854e                	mv	a0,s3
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	422080e7          	jalr	1058(ra) # 80000eba <memmove>
  brelse(bp);
    80003aa0:	8526                	mv	a0,s1
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	b5e080e7          	jalr	-1186(ra) # 80003600 <brelse>
  if(sb.magic != FSMAGIC)
    80003aaa:	0009a703          	lw	a4,0(s3)
    80003aae:	102037b7          	lui	a5,0x10203
    80003ab2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ab6:	02f71263          	bne	a4,a5,80003ada <fsinit+0x70>
  initlog(dev, &sb);
    80003aba:	0003b597          	auipc	a1,0x3b
    80003abe:	74e58593          	addi	a1,a1,1870 # 8003f208 <sb>
    80003ac2:	854a                	mv	a0,s2
    80003ac4:	00001097          	auipc	ra,0x1
    80003ac8:	b4a080e7          	jalr	-1206(ra) # 8000460e <initlog>
}
    80003acc:	70a2                	ld	ra,40(sp)
    80003ace:	7402                	ld	s0,32(sp)
    80003ad0:	64e2                	ld	s1,24(sp)
    80003ad2:	6942                	ld	s2,16(sp)
    80003ad4:	69a2                	ld	s3,8(sp)
    80003ad6:	6145                	addi	sp,sp,48
    80003ad8:	8082                	ret
    panic("invalid file system");
    80003ada:	00005517          	auipc	a0,0x5
    80003ade:	c1e50513          	addi	a0,a0,-994 # 800086f8 <syscalls+0x168>
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	a5e080e7          	jalr	-1442(ra) # 80000540 <panic>

0000000080003aea <iinit>:
{
    80003aea:	7179                	addi	sp,sp,-48
    80003aec:	f406                	sd	ra,40(sp)
    80003aee:	f022                	sd	s0,32(sp)
    80003af0:	ec26                	sd	s1,24(sp)
    80003af2:	e84a                	sd	s2,16(sp)
    80003af4:	e44e                	sd	s3,8(sp)
    80003af6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003af8:	00005597          	auipc	a1,0x5
    80003afc:	c1858593          	addi	a1,a1,-1000 # 80008710 <syscalls+0x180>
    80003b00:	0003b517          	auipc	a0,0x3b
    80003b04:	72850513          	addi	a0,a0,1832 # 8003f228 <itable>
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	1ca080e7          	jalr	458(ra) # 80000cd2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b10:	0003b497          	auipc	s1,0x3b
    80003b14:	74048493          	addi	s1,s1,1856 # 8003f250 <itable+0x28>
    80003b18:	0003d997          	auipc	s3,0x3d
    80003b1c:	1c898993          	addi	s3,s3,456 # 80040ce0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b20:	00005917          	auipc	s2,0x5
    80003b24:	bf890913          	addi	s2,s2,-1032 # 80008718 <syscalls+0x188>
    80003b28:	85ca                	mv	a1,s2
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	e42080e7          	jalr	-446(ra) # 8000496e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b34:	08848493          	addi	s1,s1,136
    80003b38:	ff3498e3          	bne	s1,s3,80003b28 <iinit+0x3e>
}
    80003b3c:	70a2                	ld	ra,40(sp)
    80003b3e:	7402                	ld	s0,32(sp)
    80003b40:	64e2                	ld	s1,24(sp)
    80003b42:	6942                	ld	s2,16(sp)
    80003b44:	69a2                	ld	s3,8(sp)
    80003b46:	6145                	addi	sp,sp,48
    80003b48:	8082                	ret

0000000080003b4a <ialloc>:
{
    80003b4a:	715d                	addi	sp,sp,-80
    80003b4c:	e486                	sd	ra,72(sp)
    80003b4e:	e0a2                	sd	s0,64(sp)
    80003b50:	fc26                	sd	s1,56(sp)
    80003b52:	f84a                	sd	s2,48(sp)
    80003b54:	f44e                	sd	s3,40(sp)
    80003b56:	f052                	sd	s4,32(sp)
    80003b58:	ec56                	sd	s5,24(sp)
    80003b5a:	e85a                	sd	s6,16(sp)
    80003b5c:	e45e                	sd	s7,8(sp)
    80003b5e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b60:	0003b717          	auipc	a4,0x3b
    80003b64:	6b472703          	lw	a4,1716(a4) # 8003f214 <sb+0xc>
    80003b68:	4785                	li	a5,1
    80003b6a:	04e7fa63          	bgeu	a5,a4,80003bbe <ialloc+0x74>
    80003b6e:	8aaa                	mv	s5,a0
    80003b70:	8bae                	mv	s7,a1
    80003b72:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b74:	0003ba17          	auipc	s4,0x3b
    80003b78:	694a0a13          	addi	s4,s4,1684 # 8003f208 <sb>
    80003b7c:	00048b1b          	sext.w	s6,s1
    80003b80:	0044d593          	srli	a1,s1,0x4
    80003b84:	018a2783          	lw	a5,24(s4)
    80003b88:	9dbd                	addw	a1,a1,a5
    80003b8a:	8556                	mv	a0,s5
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	944080e7          	jalr	-1724(ra) # 800034d0 <bread>
    80003b94:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b96:	05850993          	addi	s3,a0,88
    80003b9a:	00f4f793          	andi	a5,s1,15
    80003b9e:	079a                	slli	a5,a5,0x6
    80003ba0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ba2:	00099783          	lh	a5,0(s3)
    80003ba6:	c3a1                	beqz	a5,80003be6 <ialloc+0x9c>
    brelse(bp);
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	a58080e7          	jalr	-1448(ra) # 80003600 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bb0:	0485                	addi	s1,s1,1
    80003bb2:	00ca2703          	lw	a4,12(s4)
    80003bb6:	0004879b          	sext.w	a5,s1
    80003bba:	fce7e1e3          	bltu	a5,a4,80003b7c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003bbe:	00005517          	auipc	a0,0x5
    80003bc2:	b6250513          	addi	a0,a0,-1182 # 80008720 <syscalls+0x190>
    80003bc6:	ffffd097          	auipc	ra,0xffffd
    80003bca:	9d6080e7          	jalr	-1578(ra) # 8000059c <printf>
  return 0;
    80003bce:	4501                	li	a0,0
}
    80003bd0:	60a6                	ld	ra,72(sp)
    80003bd2:	6406                	ld	s0,64(sp)
    80003bd4:	74e2                	ld	s1,56(sp)
    80003bd6:	7942                	ld	s2,48(sp)
    80003bd8:	79a2                	ld	s3,40(sp)
    80003bda:	7a02                	ld	s4,32(sp)
    80003bdc:	6ae2                	ld	s5,24(sp)
    80003bde:	6b42                	ld	s6,16(sp)
    80003be0:	6ba2                	ld	s7,8(sp)
    80003be2:	6161                	addi	sp,sp,80
    80003be4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003be6:	04000613          	li	a2,64
    80003bea:	4581                	li	a1,0
    80003bec:	854e                	mv	a0,s3
    80003bee:	ffffd097          	auipc	ra,0xffffd
    80003bf2:	270080e7          	jalr	624(ra) # 80000e5e <memset>
      dip->type = type;
    80003bf6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bfa:	854a                	mv	a0,s2
    80003bfc:	00001097          	auipc	ra,0x1
    80003c00:	c8e080e7          	jalr	-882(ra) # 8000488a <log_write>
      brelse(bp);
    80003c04:	854a                	mv	a0,s2
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	9fa080e7          	jalr	-1542(ra) # 80003600 <brelse>
      return iget(dev, inum);
    80003c0e:	85da                	mv	a1,s6
    80003c10:	8556                	mv	a0,s5
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	d9c080e7          	jalr	-612(ra) # 800039ae <iget>
    80003c1a:	bf5d                	j	80003bd0 <ialloc+0x86>

0000000080003c1c <iupdate>:
{
    80003c1c:	1101                	addi	sp,sp,-32
    80003c1e:	ec06                	sd	ra,24(sp)
    80003c20:	e822                	sd	s0,16(sp)
    80003c22:	e426                	sd	s1,8(sp)
    80003c24:	e04a                	sd	s2,0(sp)
    80003c26:	1000                	addi	s0,sp,32
    80003c28:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c2a:	415c                	lw	a5,4(a0)
    80003c2c:	0047d79b          	srliw	a5,a5,0x4
    80003c30:	0003b597          	auipc	a1,0x3b
    80003c34:	5f05a583          	lw	a1,1520(a1) # 8003f220 <sb+0x18>
    80003c38:	9dbd                	addw	a1,a1,a5
    80003c3a:	4108                	lw	a0,0(a0)
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	894080e7          	jalr	-1900(ra) # 800034d0 <bread>
    80003c44:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c46:	05850793          	addi	a5,a0,88
    80003c4a:	40d8                	lw	a4,4(s1)
    80003c4c:	8b3d                	andi	a4,a4,15
    80003c4e:	071a                	slli	a4,a4,0x6
    80003c50:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c52:	04449703          	lh	a4,68(s1)
    80003c56:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c5a:	04649703          	lh	a4,70(s1)
    80003c5e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c62:	04849703          	lh	a4,72(s1)
    80003c66:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c6a:	04a49703          	lh	a4,74(s1)
    80003c6e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c72:	44f8                	lw	a4,76(s1)
    80003c74:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c76:	03400613          	li	a2,52
    80003c7a:	05048593          	addi	a1,s1,80
    80003c7e:	00c78513          	addi	a0,a5,12
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	238080e7          	jalr	568(ra) # 80000eba <memmove>
  log_write(bp);
    80003c8a:	854a                	mv	a0,s2
    80003c8c:	00001097          	auipc	ra,0x1
    80003c90:	bfe080e7          	jalr	-1026(ra) # 8000488a <log_write>
  brelse(bp);
    80003c94:	854a                	mv	a0,s2
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	96a080e7          	jalr	-1686(ra) # 80003600 <brelse>
}
    80003c9e:	60e2                	ld	ra,24(sp)
    80003ca0:	6442                	ld	s0,16(sp)
    80003ca2:	64a2                	ld	s1,8(sp)
    80003ca4:	6902                	ld	s2,0(sp)
    80003ca6:	6105                	addi	sp,sp,32
    80003ca8:	8082                	ret

0000000080003caa <idup>:
{
    80003caa:	1101                	addi	sp,sp,-32
    80003cac:	ec06                	sd	ra,24(sp)
    80003cae:	e822                	sd	s0,16(sp)
    80003cb0:	e426                	sd	s1,8(sp)
    80003cb2:	1000                	addi	s0,sp,32
    80003cb4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cb6:	0003b517          	auipc	a0,0x3b
    80003cba:	57250513          	addi	a0,a0,1394 # 8003f228 <itable>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	0a4080e7          	jalr	164(ra) # 80000d62 <acquire>
  ip->ref++;
    80003cc6:	449c                	lw	a5,8(s1)
    80003cc8:	2785                	addiw	a5,a5,1
    80003cca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ccc:	0003b517          	auipc	a0,0x3b
    80003cd0:	55c50513          	addi	a0,a0,1372 # 8003f228 <itable>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	142080e7          	jalr	322(ra) # 80000e16 <release>
}
    80003cdc:	8526                	mv	a0,s1
    80003cde:	60e2                	ld	ra,24(sp)
    80003ce0:	6442                	ld	s0,16(sp)
    80003ce2:	64a2                	ld	s1,8(sp)
    80003ce4:	6105                	addi	sp,sp,32
    80003ce6:	8082                	ret

0000000080003ce8 <ilock>:
{
    80003ce8:	1101                	addi	sp,sp,-32
    80003cea:	ec06                	sd	ra,24(sp)
    80003cec:	e822                	sd	s0,16(sp)
    80003cee:	e426                	sd	s1,8(sp)
    80003cf0:	e04a                	sd	s2,0(sp)
    80003cf2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cf4:	c115                	beqz	a0,80003d18 <ilock+0x30>
    80003cf6:	84aa                	mv	s1,a0
    80003cf8:	451c                	lw	a5,8(a0)
    80003cfa:	00f05f63          	blez	a5,80003d18 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cfe:	0541                	addi	a0,a0,16
    80003d00:	00001097          	auipc	ra,0x1
    80003d04:	ca8080e7          	jalr	-856(ra) # 800049a8 <acquiresleep>
  if(ip->valid == 0){
    80003d08:	40bc                	lw	a5,64(s1)
    80003d0a:	cf99                	beqz	a5,80003d28 <ilock+0x40>
}
    80003d0c:	60e2                	ld	ra,24(sp)
    80003d0e:	6442                	ld	s0,16(sp)
    80003d10:	64a2                	ld	s1,8(sp)
    80003d12:	6902                	ld	s2,0(sp)
    80003d14:	6105                	addi	sp,sp,32
    80003d16:	8082                	ret
    panic("ilock");
    80003d18:	00005517          	auipc	a0,0x5
    80003d1c:	a2050513          	addi	a0,a0,-1504 # 80008738 <syscalls+0x1a8>
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	820080e7          	jalr	-2016(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d28:	40dc                	lw	a5,4(s1)
    80003d2a:	0047d79b          	srliw	a5,a5,0x4
    80003d2e:	0003b597          	auipc	a1,0x3b
    80003d32:	4f25a583          	lw	a1,1266(a1) # 8003f220 <sb+0x18>
    80003d36:	9dbd                	addw	a1,a1,a5
    80003d38:	4088                	lw	a0,0(s1)
    80003d3a:	fffff097          	auipc	ra,0xfffff
    80003d3e:	796080e7          	jalr	1942(ra) # 800034d0 <bread>
    80003d42:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d44:	05850593          	addi	a1,a0,88
    80003d48:	40dc                	lw	a5,4(s1)
    80003d4a:	8bbd                	andi	a5,a5,15
    80003d4c:	079a                	slli	a5,a5,0x6
    80003d4e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d50:	00059783          	lh	a5,0(a1)
    80003d54:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d58:	00259783          	lh	a5,2(a1)
    80003d5c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d60:	00459783          	lh	a5,4(a1)
    80003d64:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d68:	00659783          	lh	a5,6(a1)
    80003d6c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d70:	459c                	lw	a5,8(a1)
    80003d72:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d74:	03400613          	li	a2,52
    80003d78:	05b1                	addi	a1,a1,12
    80003d7a:	05048513          	addi	a0,s1,80
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	13c080e7          	jalr	316(ra) # 80000eba <memmove>
    brelse(bp);
    80003d86:	854a                	mv	a0,s2
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	878080e7          	jalr	-1928(ra) # 80003600 <brelse>
    ip->valid = 1;
    80003d90:	4785                	li	a5,1
    80003d92:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d94:	04449783          	lh	a5,68(s1)
    80003d98:	fbb5                	bnez	a5,80003d0c <ilock+0x24>
      panic("ilock: no type");
    80003d9a:	00005517          	auipc	a0,0x5
    80003d9e:	9a650513          	addi	a0,a0,-1626 # 80008740 <syscalls+0x1b0>
    80003da2:	ffffc097          	auipc	ra,0xffffc
    80003da6:	79e080e7          	jalr	1950(ra) # 80000540 <panic>

0000000080003daa <iunlock>:
{
    80003daa:	1101                	addi	sp,sp,-32
    80003dac:	ec06                	sd	ra,24(sp)
    80003dae:	e822                	sd	s0,16(sp)
    80003db0:	e426                	sd	s1,8(sp)
    80003db2:	e04a                	sd	s2,0(sp)
    80003db4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003db6:	c905                	beqz	a0,80003de6 <iunlock+0x3c>
    80003db8:	84aa                	mv	s1,a0
    80003dba:	01050913          	addi	s2,a0,16
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00001097          	auipc	ra,0x1
    80003dc4:	c82080e7          	jalr	-894(ra) # 80004a42 <holdingsleep>
    80003dc8:	cd19                	beqz	a0,80003de6 <iunlock+0x3c>
    80003dca:	449c                	lw	a5,8(s1)
    80003dcc:	00f05d63          	blez	a5,80003de6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dd0:	854a                	mv	a0,s2
    80003dd2:	00001097          	auipc	ra,0x1
    80003dd6:	c2c080e7          	jalr	-980(ra) # 800049fe <releasesleep>
}
    80003dda:	60e2                	ld	ra,24(sp)
    80003ddc:	6442                	ld	s0,16(sp)
    80003dde:	64a2                	ld	s1,8(sp)
    80003de0:	6902                	ld	s2,0(sp)
    80003de2:	6105                	addi	sp,sp,32
    80003de4:	8082                	ret
    panic("iunlock");
    80003de6:	00005517          	auipc	a0,0x5
    80003dea:	96a50513          	addi	a0,a0,-1686 # 80008750 <syscalls+0x1c0>
    80003dee:	ffffc097          	auipc	ra,0xffffc
    80003df2:	752080e7          	jalr	1874(ra) # 80000540 <panic>

0000000080003df6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003df6:	7179                	addi	sp,sp,-48
    80003df8:	f406                	sd	ra,40(sp)
    80003dfa:	f022                	sd	s0,32(sp)
    80003dfc:	ec26                	sd	s1,24(sp)
    80003dfe:	e84a                	sd	s2,16(sp)
    80003e00:	e44e                	sd	s3,8(sp)
    80003e02:	e052                	sd	s4,0(sp)
    80003e04:	1800                	addi	s0,sp,48
    80003e06:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e08:	05050493          	addi	s1,a0,80
    80003e0c:	08050913          	addi	s2,a0,128
    80003e10:	a021                	j	80003e18 <itrunc+0x22>
    80003e12:	0491                	addi	s1,s1,4
    80003e14:	01248d63          	beq	s1,s2,80003e2e <itrunc+0x38>
    if(ip->addrs[i]){
    80003e18:	408c                	lw	a1,0(s1)
    80003e1a:	dde5                	beqz	a1,80003e12 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e1c:	0009a503          	lw	a0,0(s3)
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	8f6080e7          	jalr	-1802(ra) # 80003716 <bfree>
      ip->addrs[i] = 0;
    80003e28:	0004a023          	sw	zero,0(s1)
    80003e2c:	b7dd                	j	80003e12 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e2e:	0809a583          	lw	a1,128(s3)
    80003e32:	e185                	bnez	a1,80003e52 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e34:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e38:	854e                	mv	a0,s3
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	de2080e7          	jalr	-542(ra) # 80003c1c <iupdate>
}
    80003e42:	70a2                	ld	ra,40(sp)
    80003e44:	7402                	ld	s0,32(sp)
    80003e46:	64e2                	ld	s1,24(sp)
    80003e48:	6942                	ld	s2,16(sp)
    80003e4a:	69a2                	ld	s3,8(sp)
    80003e4c:	6a02                	ld	s4,0(sp)
    80003e4e:	6145                	addi	sp,sp,48
    80003e50:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e52:	0009a503          	lw	a0,0(s3)
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	67a080e7          	jalr	1658(ra) # 800034d0 <bread>
    80003e5e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e60:	05850493          	addi	s1,a0,88
    80003e64:	45850913          	addi	s2,a0,1112
    80003e68:	a021                	j	80003e70 <itrunc+0x7a>
    80003e6a:	0491                	addi	s1,s1,4
    80003e6c:	01248b63          	beq	s1,s2,80003e82 <itrunc+0x8c>
      if(a[j])
    80003e70:	408c                	lw	a1,0(s1)
    80003e72:	dde5                	beqz	a1,80003e6a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e74:	0009a503          	lw	a0,0(s3)
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	89e080e7          	jalr	-1890(ra) # 80003716 <bfree>
    80003e80:	b7ed                	j	80003e6a <itrunc+0x74>
    brelse(bp);
    80003e82:	8552                	mv	a0,s4
    80003e84:	fffff097          	auipc	ra,0xfffff
    80003e88:	77c080e7          	jalr	1916(ra) # 80003600 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e8c:	0809a583          	lw	a1,128(s3)
    80003e90:	0009a503          	lw	a0,0(s3)
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	882080e7          	jalr	-1918(ra) # 80003716 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e9c:	0809a023          	sw	zero,128(s3)
    80003ea0:	bf51                	j	80003e34 <itrunc+0x3e>

0000000080003ea2 <iput>:
{
    80003ea2:	1101                	addi	sp,sp,-32
    80003ea4:	ec06                	sd	ra,24(sp)
    80003ea6:	e822                	sd	s0,16(sp)
    80003ea8:	e426                	sd	s1,8(sp)
    80003eaa:	e04a                	sd	s2,0(sp)
    80003eac:	1000                	addi	s0,sp,32
    80003eae:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eb0:	0003b517          	auipc	a0,0x3b
    80003eb4:	37850513          	addi	a0,a0,888 # 8003f228 <itable>
    80003eb8:	ffffd097          	auipc	ra,0xffffd
    80003ebc:	eaa080e7          	jalr	-342(ra) # 80000d62 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ec0:	4498                	lw	a4,8(s1)
    80003ec2:	4785                	li	a5,1
    80003ec4:	02f70363          	beq	a4,a5,80003eea <iput+0x48>
  ip->ref--;
    80003ec8:	449c                	lw	a5,8(s1)
    80003eca:	37fd                	addiw	a5,a5,-1
    80003ecc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ece:	0003b517          	auipc	a0,0x3b
    80003ed2:	35a50513          	addi	a0,a0,858 # 8003f228 <itable>
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	f40080e7          	jalr	-192(ra) # 80000e16 <release>
}
    80003ede:	60e2                	ld	ra,24(sp)
    80003ee0:	6442                	ld	s0,16(sp)
    80003ee2:	64a2                	ld	s1,8(sp)
    80003ee4:	6902                	ld	s2,0(sp)
    80003ee6:	6105                	addi	sp,sp,32
    80003ee8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eea:	40bc                	lw	a5,64(s1)
    80003eec:	dff1                	beqz	a5,80003ec8 <iput+0x26>
    80003eee:	04a49783          	lh	a5,74(s1)
    80003ef2:	fbf9                	bnez	a5,80003ec8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ef4:	01048913          	addi	s2,s1,16
    80003ef8:	854a                	mv	a0,s2
    80003efa:	00001097          	auipc	ra,0x1
    80003efe:	aae080e7          	jalr	-1362(ra) # 800049a8 <acquiresleep>
    release(&itable.lock);
    80003f02:	0003b517          	auipc	a0,0x3b
    80003f06:	32650513          	addi	a0,a0,806 # 8003f228 <itable>
    80003f0a:	ffffd097          	auipc	ra,0xffffd
    80003f0e:	f0c080e7          	jalr	-244(ra) # 80000e16 <release>
    itrunc(ip);
    80003f12:	8526                	mv	a0,s1
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	ee2080e7          	jalr	-286(ra) # 80003df6 <itrunc>
    ip->type = 0;
    80003f1c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f20:	8526                	mv	a0,s1
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	cfa080e7          	jalr	-774(ra) # 80003c1c <iupdate>
    ip->valid = 0;
    80003f2a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f2e:	854a                	mv	a0,s2
    80003f30:	00001097          	auipc	ra,0x1
    80003f34:	ace080e7          	jalr	-1330(ra) # 800049fe <releasesleep>
    acquire(&itable.lock);
    80003f38:	0003b517          	auipc	a0,0x3b
    80003f3c:	2f050513          	addi	a0,a0,752 # 8003f228 <itable>
    80003f40:	ffffd097          	auipc	ra,0xffffd
    80003f44:	e22080e7          	jalr	-478(ra) # 80000d62 <acquire>
    80003f48:	b741                	j	80003ec8 <iput+0x26>

0000000080003f4a <iunlockput>:
{
    80003f4a:	1101                	addi	sp,sp,-32
    80003f4c:	ec06                	sd	ra,24(sp)
    80003f4e:	e822                	sd	s0,16(sp)
    80003f50:	e426                	sd	s1,8(sp)
    80003f52:	1000                	addi	s0,sp,32
    80003f54:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	e54080e7          	jalr	-428(ra) # 80003daa <iunlock>
  iput(ip);
    80003f5e:	8526                	mv	a0,s1
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	f42080e7          	jalr	-190(ra) # 80003ea2 <iput>
}
    80003f68:	60e2                	ld	ra,24(sp)
    80003f6a:	6442                	ld	s0,16(sp)
    80003f6c:	64a2                	ld	s1,8(sp)
    80003f6e:	6105                	addi	sp,sp,32
    80003f70:	8082                	ret

0000000080003f72 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f72:	1141                	addi	sp,sp,-16
    80003f74:	e422                	sd	s0,8(sp)
    80003f76:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f78:	411c                	lw	a5,0(a0)
    80003f7a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f7c:	415c                	lw	a5,4(a0)
    80003f7e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f80:	04451783          	lh	a5,68(a0)
    80003f84:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f88:	04a51783          	lh	a5,74(a0)
    80003f8c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f90:	04c56783          	lwu	a5,76(a0)
    80003f94:	e99c                	sd	a5,16(a1)
}
    80003f96:	6422                	ld	s0,8(sp)
    80003f98:	0141                	addi	sp,sp,16
    80003f9a:	8082                	ret

0000000080003f9c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f9c:	457c                	lw	a5,76(a0)
    80003f9e:	0ed7e963          	bltu	a5,a3,80004090 <readi+0xf4>
{
    80003fa2:	7159                	addi	sp,sp,-112
    80003fa4:	f486                	sd	ra,104(sp)
    80003fa6:	f0a2                	sd	s0,96(sp)
    80003fa8:	eca6                	sd	s1,88(sp)
    80003faa:	e8ca                	sd	s2,80(sp)
    80003fac:	e4ce                	sd	s3,72(sp)
    80003fae:	e0d2                	sd	s4,64(sp)
    80003fb0:	fc56                	sd	s5,56(sp)
    80003fb2:	f85a                	sd	s6,48(sp)
    80003fb4:	f45e                	sd	s7,40(sp)
    80003fb6:	f062                	sd	s8,32(sp)
    80003fb8:	ec66                	sd	s9,24(sp)
    80003fba:	e86a                	sd	s10,16(sp)
    80003fbc:	e46e                	sd	s11,8(sp)
    80003fbe:	1880                	addi	s0,sp,112
    80003fc0:	8b2a                	mv	s6,a0
    80003fc2:	8bae                	mv	s7,a1
    80003fc4:	8a32                	mv	s4,a2
    80003fc6:	84b6                	mv	s1,a3
    80003fc8:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003fca:	9f35                	addw	a4,a4,a3
    return 0;
    80003fcc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fce:	0ad76063          	bltu	a4,a3,8000406e <readi+0xd2>
  if(off + n > ip->size)
    80003fd2:	00e7f463          	bgeu	a5,a4,80003fda <readi+0x3e>
    n = ip->size - off;
    80003fd6:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fda:	0a0a8963          	beqz	s5,8000408c <readi+0xf0>
    80003fde:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fe4:	5c7d                	li	s8,-1
    80003fe6:	a82d                	j	80004020 <readi+0x84>
    80003fe8:	020d1d93          	slli	s11,s10,0x20
    80003fec:	020ddd93          	srli	s11,s11,0x20
    80003ff0:	05890613          	addi	a2,s2,88
    80003ff4:	86ee                	mv	a3,s11
    80003ff6:	963a                	add	a2,a2,a4
    80003ff8:	85d2                	mv	a1,s4
    80003ffa:	855e                	mv	a0,s7
    80003ffc:	ffffe097          	auipc	ra,0xffffe
    80004000:	7e4080e7          	jalr	2020(ra) # 800027e0 <either_copyout>
    80004004:	05850d63          	beq	a0,s8,8000405e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004008:	854a                	mv	a0,s2
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	5f6080e7          	jalr	1526(ra) # 80003600 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004012:	013d09bb          	addw	s3,s10,s3
    80004016:	009d04bb          	addw	s1,s10,s1
    8000401a:	9a6e                	add	s4,s4,s11
    8000401c:	0559f763          	bgeu	s3,s5,8000406a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004020:	00a4d59b          	srliw	a1,s1,0xa
    80004024:	855a                	mv	a0,s6
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	89e080e7          	jalr	-1890(ra) # 800038c4 <bmap>
    8000402e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004032:	cd85                	beqz	a1,8000406a <readi+0xce>
    bp = bread(ip->dev, addr);
    80004034:	000b2503          	lw	a0,0(s6)
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	498080e7          	jalr	1176(ra) # 800034d0 <bread>
    80004040:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004042:	3ff4f713          	andi	a4,s1,1023
    80004046:	40ec87bb          	subw	a5,s9,a4
    8000404a:	413a86bb          	subw	a3,s5,s3
    8000404e:	8d3e                	mv	s10,a5
    80004050:	2781                	sext.w	a5,a5
    80004052:	0006861b          	sext.w	a2,a3
    80004056:	f8f679e3          	bgeu	a2,a5,80003fe8 <readi+0x4c>
    8000405a:	8d36                	mv	s10,a3
    8000405c:	b771                	j	80003fe8 <readi+0x4c>
      brelse(bp);
    8000405e:	854a                	mv	a0,s2
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	5a0080e7          	jalr	1440(ra) # 80003600 <brelse>
      tot = -1;
    80004068:	59fd                	li	s3,-1
  }
  return tot;
    8000406a:	0009851b          	sext.w	a0,s3
}
    8000406e:	70a6                	ld	ra,104(sp)
    80004070:	7406                	ld	s0,96(sp)
    80004072:	64e6                	ld	s1,88(sp)
    80004074:	6946                	ld	s2,80(sp)
    80004076:	69a6                	ld	s3,72(sp)
    80004078:	6a06                	ld	s4,64(sp)
    8000407a:	7ae2                	ld	s5,56(sp)
    8000407c:	7b42                	ld	s6,48(sp)
    8000407e:	7ba2                	ld	s7,40(sp)
    80004080:	7c02                	ld	s8,32(sp)
    80004082:	6ce2                	ld	s9,24(sp)
    80004084:	6d42                	ld	s10,16(sp)
    80004086:	6da2                	ld	s11,8(sp)
    80004088:	6165                	addi	sp,sp,112
    8000408a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000408c:	89d6                	mv	s3,s5
    8000408e:	bff1                	j	8000406a <readi+0xce>
    return 0;
    80004090:	4501                	li	a0,0
}
    80004092:	8082                	ret

0000000080004094 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004094:	457c                	lw	a5,76(a0)
    80004096:	10d7e863          	bltu	a5,a3,800041a6 <writei+0x112>
{
    8000409a:	7159                	addi	sp,sp,-112
    8000409c:	f486                	sd	ra,104(sp)
    8000409e:	f0a2                	sd	s0,96(sp)
    800040a0:	eca6                	sd	s1,88(sp)
    800040a2:	e8ca                	sd	s2,80(sp)
    800040a4:	e4ce                	sd	s3,72(sp)
    800040a6:	e0d2                	sd	s4,64(sp)
    800040a8:	fc56                	sd	s5,56(sp)
    800040aa:	f85a                	sd	s6,48(sp)
    800040ac:	f45e                	sd	s7,40(sp)
    800040ae:	f062                	sd	s8,32(sp)
    800040b0:	ec66                	sd	s9,24(sp)
    800040b2:	e86a                	sd	s10,16(sp)
    800040b4:	e46e                	sd	s11,8(sp)
    800040b6:	1880                	addi	s0,sp,112
    800040b8:	8aaa                	mv	s5,a0
    800040ba:	8bae                	mv	s7,a1
    800040bc:	8a32                	mv	s4,a2
    800040be:	8936                	mv	s2,a3
    800040c0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040c2:	00e687bb          	addw	a5,a3,a4
    800040c6:	0ed7e263          	bltu	a5,a3,800041aa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040ca:	00043737          	lui	a4,0x43
    800040ce:	0ef76063          	bltu	a4,a5,800041ae <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d2:	0c0b0863          	beqz	s6,800041a2 <writei+0x10e>
    800040d6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040d8:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040dc:	5c7d                	li	s8,-1
    800040de:	a091                	j	80004122 <writei+0x8e>
    800040e0:	020d1d93          	slli	s11,s10,0x20
    800040e4:	020ddd93          	srli	s11,s11,0x20
    800040e8:	05848513          	addi	a0,s1,88
    800040ec:	86ee                	mv	a3,s11
    800040ee:	8652                	mv	a2,s4
    800040f0:	85de                	mv	a1,s7
    800040f2:	953a                	add	a0,a0,a4
    800040f4:	ffffe097          	auipc	ra,0xffffe
    800040f8:	742080e7          	jalr	1858(ra) # 80002836 <either_copyin>
    800040fc:	07850263          	beq	a0,s8,80004160 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004100:	8526                	mv	a0,s1
    80004102:	00000097          	auipc	ra,0x0
    80004106:	788080e7          	jalr	1928(ra) # 8000488a <log_write>
    brelse(bp);
    8000410a:	8526                	mv	a0,s1
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	4f4080e7          	jalr	1268(ra) # 80003600 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004114:	013d09bb          	addw	s3,s10,s3
    80004118:	012d093b          	addw	s2,s10,s2
    8000411c:	9a6e                	add	s4,s4,s11
    8000411e:	0569f663          	bgeu	s3,s6,8000416a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004122:	00a9559b          	srliw	a1,s2,0xa
    80004126:	8556                	mv	a0,s5
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	79c080e7          	jalr	1948(ra) # 800038c4 <bmap>
    80004130:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004134:	c99d                	beqz	a1,8000416a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004136:	000aa503          	lw	a0,0(s5)
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	396080e7          	jalr	918(ra) # 800034d0 <bread>
    80004142:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004144:	3ff97713          	andi	a4,s2,1023
    80004148:	40ec87bb          	subw	a5,s9,a4
    8000414c:	413b06bb          	subw	a3,s6,s3
    80004150:	8d3e                	mv	s10,a5
    80004152:	2781                	sext.w	a5,a5
    80004154:	0006861b          	sext.w	a2,a3
    80004158:	f8f674e3          	bgeu	a2,a5,800040e0 <writei+0x4c>
    8000415c:	8d36                	mv	s10,a3
    8000415e:	b749                	j	800040e0 <writei+0x4c>
      brelse(bp);
    80004160:	8526                	mv	a0,s1
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	49e080e7          	jalr	1182(ra) # 80003600 <brelse>
  }

  if(off > ip->size)
    8000416a:	04caa783          	lw	a5,76(s5)
    8000416e:	0127f463          	bgeu	a5,s2,80004176 <writei+0xe2>
    ip->size = off;
    80004172:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004176:	8556                	mv	a0,s5
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	aa4080e7          	jalr	-1372(ra) # 80003c1c <iupdate>

  return tot;
    80004180:	0009851b          	sext.w	a0,s3
}
    80004184:	70a6                	ld	ra,104(sp)
    80004186:	7406                	ld	s0,96(sp)
    80004188:	64e6                	ld	s1,88(sp)
    8000418a:	6946                	ld	s2,80(sp)
    8000418c:	69a6                	ld	s3,72(sp)
    8000418e:	6a06                	ld	s4,64(sp)
    80004190:	7ae2                	ld	s5,56(sp)
    80004192:	7b42                	ld	s6,48(sp)
    80004194:	7ba2                	ld	s7,40(sp)
    80004196:	7c02                	ld	s8,32(sp)
    80004198:	6ce2                	ld	s9,24(sp)
    8000419a:	6d42                	ld	s10,16(sp)
    8000419c:	6da2                	ld	s11,8(sp)
    8000419e:	6165                	addi	sp,sp,112
    800041a0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a2:	89da                	mv	s3,s6
    800041a4:	bfc9                	j	80004176 <writei+0xe2>
    return -1;
    800041a6:	557d                	li	a0,-1
}
    800041a8:	8082                	ret
    return -1;
    800041aa:	557d                	li	a0,-1
    800041ac:	bfe1                	j	80004184 <writei+0xf0>
    return -1;
    800041ae:	557d                	li	a0,-1
    800041b0:	bfd1                	j	80004184 <writei+0xf0>

00000000800041b2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041b2:	1141                	addi	sp,sp,-16
    800041b4:	e406                	sd	ra,8(sp)
    800041b6:	e022                	sd	s0,0(sp)
    800041b8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041ba:	4639                	li	a2,14
    800041bc:	ffffd097          	auipc	ra,0xffffd
    800041c0:	d72080e7          	jalr	-654(ra) # 80000f2e <strncmp>
}
    800041c4:	60a2                	ld	ra,8(sp)
    800041c6:	6402                	ld	s0,0(sp)
    800041c8:	0141                	addi	sp,sp,16
    800041ca:	8082                	ret

00000000800041cc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041cc:	7139                	addi	sp,sp,-64
    800041ce:	fc06                	sd	ra,56(sp)
    800041d0:	f822                	sd	s0,48(sp)
    800041d2:	f426                	sd	s1,40(sp)
    800041d4:	f04a                	sd	s2,32(sp)
    800041d6:	ec4e                	sd	s3,24(sp)
    800041d8:	e852                	sd	s4,16(sp)
    800041da:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041dc:	04451703          	lh	a4,68(a0)
    800041e0:	4785                	li	a5,1
    800041e2:	00f71a63          	bne	a4,a5,800041f6 <dirlookup+0x2a>
    800041e6:	892a                	mv	s2,a0
    800041e8:	89ae                	mv	s3,a1
    800041ea:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ec:	457c                	lw	a5,76(a0)
    800041ee:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041f0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f2:	e79d                	bnez	a5,80004220 <dirlookup+0x54>
    800041f4:	a8a5                	j	8000426c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041f6:	00004517          	auipc	a0,0x4
    800041fa:	56250513          	addi	a0,a0,1378 # 80008758 <syscalls+0x1c8>
    800041fe:	ffffc097          	auipc	ra,0xffffc
    80004202:	342080e7          	jalr	834(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004206:	00004517          	auipc	a0,0x4
    8000420a:	56a50513          	addi	a0,a0,1386 # 80008770 <syscalls+0x1e0>
    8000420e:	ffffc097          	auipc	ra,0xffffc
    80004212:	332080e7          	jalr	818(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004216:	24c1                	addiw	s1,s1,16
    80004218:	04c92783          	lw	a5,76(s2)
    8000421c:	04f4f763          	bgeu	s1,a5,8000426a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004220:	4741                	li	a4,16
    80004222:	86a6                	mv	a3,s1
    80004224:	fc040613          	addi	a2,s0,-64
    80004228:	4581                	li	a1,0
    8000422a:	854a                	mv	a0,s2
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	d70080e7          	jalr	-656(ra) # 80003f9c <readi>
    80004234:	47c1                	li	a5,16
    80004236:	fcf518e3          	bne	a0,a5,80004206 <dirlookup+0x3a>
    if(de.inum == 0)
    8000423a:	fc045783          	lhu	a5,-64(s0)
    8000423e:	dfe1                	beqz	a5,80004216 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004240:	fc240593          	addi	a1,s0,-62
    80004244:	854e                	mv	a0,s3
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	f6c080e7          	jalr	-148(ra) # 800041b2 <namecmp>
    8000424e:	f561                	bnez	a0,80004216 <dirlookup+0x4a>
      if(poff)
    80004250:	000a0463          	beqz	s4,80004258 <dirlookup+0x8c>
        *poff = off;
    80004254:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004258:	fc045583          	lhu	a1,-64(s0)
    8000425c:	00092503          	lw	a0,0(s2)
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	74e080e7          	jalr	1870(ra) # 800039ae <iget>
    80004268:	a011                	j	8000426c <dirlookup+0xa0>
  return 0;
    8000426a:	4501                	li	a0,0
}
    8000426c:	70e2                	ld	ra,56(sp)
    8000426e:	7442                	ld	s0,48(sp)
    80004270:	74a2                	ld	s1,40(sp)
    80004272:	7902                	ld	s2,32(sp)
    80004274:	69e2                	ld	s3,24(sp)
    80004276:	6a42                	ld	s4,16(sp)
    80004278:	6121                	addi	sp,sp,64
    8000427a:	8082                	ret

000000008000427c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000427c:	711d                	addi	sp,sp,-96
    8000427e:	ec86                	sd	ra,88(sp)
    80004280:	e8a2                	sd	s0,80(sp)
    80004282:	e4a6                	sd	s1,72(sp)
    80004284:	e0ca                	sd	s2,64(sp)
    80004286:	fc4e                	sd	s3,56(sp)
    80004288:	f852                	sd	s4,48(sp)
    8000428a:	f456                	sd	s5,40(sp)
    8000428c:	f05a                	sd	s6,32(sp)
    8000428e:	ec5e                	sd	s7,24(sp)
    80004290:	e862                	sd	s8,16(sp)
    80004292:	e466                	sd	s9,8(sp)
    80004294:	e06a                	sd	s10,0(sp)
    80004296:	1080                	addi	s0,sp,96
    80004298:	84aa                	mv	s1,a0
    8000429a:	8b2e                	mv	s6,a1
    8000429c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000429e:	00054703          	lbu	a4,0(a0)
    800042a2:	02f00793          	li	a5,47
    800042a6:	02f70363          	beq	a4,a5,800042cc <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042aa:	ffffe097          	auipc	ra,0xffffe
    800042ae:	9c6080e7          	jalr	-1594(ra) # 80001c70 <myproc>
    800042b2:	15053503          	ld	a0,336(a0)
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	9f4080e7          	jalr	-1548(ra) # 80003caa <idup>
    800042be:	8a2a                	mv	s4,a0
  while(*path == '/')
    800042c0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800042c4:	4cb5                	li	s9,13
  len = path - s;
    800042c6:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042c8:	4c05                	li	s8,1
    800042ca:	a87d                	j	80004388 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800042cc:	4585                	li	a1,1
    800042ce:	4505                	li	a0,1
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	6de080e7          	jalr	1758(ra) # 800039ae <iget>
    800042d8:	8a2a                	mv	s4,a0
    800042da:	b7dd                	j	800042c0 <namex+0x44>
      iunlockput(ip);
    800042dc:	8552                	mv	a0,s4
    800042de:	00000097          	auipc	ra,0x0
    800042e2:	c6c080e7          	jalr	-916(ra) # 80003f4a <iunlockput>
      return 0;
    800042e6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042e8:	8552                	mv	a0,s4
    800042ea:	60e6                	ld	ra,88(sp)
    800042ec:	6446                	ld	s0,80(sp)
    800042ee:	64a6                	ld	s1,72(sp)
    800042f0:	6906                	ld	s2,64(sp)
    800042f2:	79e2                	ld	s3,56(sp)
    800042f4:	7a42                	ld	s4,48(sp)
    800042f6:	7aa2                	ld	s5,40(sp)
    800042f8:	7b02                	ld	s6,32(sp)
    800042fa:	6be2                	ld	s7,24(sp)
    800042fc:	6c42                	ld	s8,16(sp)
    800042fe:	6ca2                	ld	s9,8(sp)
    80004300:	6d02                	ld	s10,0(sp)
    80004302:	6125                	addi	sp,sp,96
    80004304:	8082                	ret
      iunlock(ip);
    80004306:	8552                	mv	a0,s4
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	aa2080e7          	jalr	-1374(ra) # 80003daa <iunlock>
      return ip;
    80004310:	bfe1                	j	800042e8 <namex+0x6c>
      iunlockput(ip);
    80004312:	8552                	mv	a0,s4
    80004314:	00000097          	auipc	ra,0x0
    80004318:	c36080e7          	jalr	-970(ra) # 80003f4a <iunlockput>
      return 0;
    8000431c:	8a4e                	mv	s4,s3
    8000431e:	b7e9                	j	800042e8 <namex+0x6c>
  len = path - s;
    80004320:	40998633          	sub	a2,s3,s1
    80004324:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004328:	09acd863          	bge	s9,s10,800043b8 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000432c:	4639                	li	a2,14
    8000432e:	85a6                	mv	a1,s1
    80004330:	8556                	mv	a0,s5
    80004332:	ffffd097          	auipc	ra,0xffffd
    80004336:	b88080e7          	jalr	-1144(ra) # 80000eba <memmove>
    8000433a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000433c:	0004c783          	lbu	a5,0(s1)
    80004340:	01279763          	bne	a5,s2,8000434e <namex+0xd2>
    path++;
    80004344:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004346:	0004c783          	lbu	a5,0(s1)
    8000434a:	ff278de3          	beq	a5,s2,80004344 <namex+0xc8>
    ilock(ip);
    8000434e:	8552                	mv	a0,s4
    80004350:	00000097          	auipc	ra,0x0
    80004354:	998080e7          	jalr	-1640(ra) # 80003ce8 <ilock>
    if(ip->type != T_DIR){
    80004358:	044a1783          	lh	a5,68(s4)
    8000435c:	f98790e3          	bne	a5,s8,800042dc <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004360:	000b0563          	beqz	s6,8000436a <namex+0xee>
    80004364:	0004c783          	lbu	a5,0(s1)
    80004368:	dfd9                	beqz	a5,80004306 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000436a:	865e                	mv	a2,s7
    8000436c:	85d6                	mv	a1,s5
    8000436e:	8552                	mv	a0,s4
    80004370:	00000097          	auipc	ra,0x0
    80004374:	e5c080e7          	jalr	-420(ra) # 800041cc <dirlookup>
    80004378:	89aa                	mv	s3,a0
    8000437a:	dd41                	beqz	a0,80004312 <namex+0x96>
    iunlockput(ip);
    8000437c:	8552                	mv	a0,s4
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	bcc080e7          	jalr	-1076(ra) # 80003f4a <iunlockput>
    ip = next;
    80004386:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004388:	0004c783          	lbu	a5,0(s1)
    8000438c:	01279763          	bne	a5,s2,8000439a <namex+0x11e>
    path++;
    80004390:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004392:	0004c783          	lbu	a5,0(s1)
    80004396:	ff278de3          	beq	a5,s2,80004390 <namex+0x114>
  if(*path == 0)
    8000439a:	cb9d                	beqz	a5,800043d0 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000439c:	0004c783          	lbu	a5,0(s1)
    800043a0:	89a6                	mv	s3,s1
  len = path - s;
    800043a2:	8d5e                	mv	s10,s7
    800043a4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043a6:	01278963          	beq	a5,s2,800043b8 <namex+0x13c>
    800043aa:	dbbd                	beqz	a5,80004320 <namex+0xa4>
    path++;
    800043ac:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800043ae:	0009c783          	lbu	a5,0(s3)
    800043b2:	ff279ce3          	bne	a5,s2,800043aa <namex+0x12e>
    800043b6:	b7ad                	j	80004320 <namex+0xa4>
    memmove(name, s, len);
    800043b8:	2601                	sext.w	a2,a2
    800043ba:	85a6                	mv	a1,s1
    800043bc:	8556                	mv	a0,s5
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	afc080e7          	jalr	-1284(ra) # 80000eba <memmove>
    name[len] = 0;
    800043c6:	9d56                	add	s10,s10,s5
    800043c8:	000d0023          	sb	zero,0(s10)
    800043cc:	84ce                	mv	s1,s3
    800043ce:	b7bd                	j	8000433c <namex+0xc0>
  if(nameiparent){
    800043d0:	f00b0ce3          	beqz	s6,800042e8 <namex+0x6c>
    iput(ip);
    800043d4:	8552                	mv	a0,s4
    800043d6:	00000097          	auipc	ra,0x0
    800043da:	acc080e7          	jalr	-1332(ra) # 80003ea2 <iput>
    return 0;
    800043de:	4a01                	li	s4,0
    800043e0:	b721                	j	800042e8 <namex+0x6c>

00000000800043e2 <dirlink>:
{
    800043e2:	7139                	addi	sp,sp,-64
    800043e4:	fc06                	sd	ra,56(sp)
    800043e6:	f822                	sd	s0,48(sp)
    800043e8:	f426                	sd	s1,40(sp)
    800043ea:	f04a                	sd	s2,32(sp)
    800043ec:	ec4e                	sd	s3,24(sp)
    800043ee:	e852                	sd	s4,16(sp)
    800043f0:	0080                	addi	s0,sp,64
    800043f2:	892a                	mv	s2,a0
    800043f4:	8a2e                	mv	s4,a1
    800043f6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043f8:	4601                	li	a2,0
    800043fa:	00000097          	auipc	ra,0x0
    800043fe:	dd2080e7          	jalr	-558(ra) # 800041cc <dirlookup>
    80004402:	e93d                	bnez	a0,80004478 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004404:	04c92483          	lw	s1,76(s2)
    80004408:	c49d                	beqz	s1,80004436 <dirlink+0x54>
    8000440a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440c:	4741                	li	a4,16
    8000440e:	86a6                	mv	a3,s1
    80004410:	fc040613          	addi	a2,s0,-64
    80004414:	4581                	li	a1,0
    80004416:	854a                	mv	a0,s2
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	b84080e7          	jalr	-1148(ra) # 80003f9c <readi>
    80004420:	47c1                	li	a5,16
    80004422:	06f51163          	bne	a0,a5,80004484 <dirlink+0xa2>
    if(de.inum == 0)
    80004426:	fc045783          	lhu	a5,-64(s0)
    8000442a:	c791                	beqz	a5,80004436 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442c:	24c1                	addiw	s1,s1,16
    8000442e:	04c92783          	lw	a5,76(s2)
    80004432:	fcf4ede3          	bltu	s1,a5,8000440c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004436:	4639                	li	a2,14
    80004438:	85d2                	mv	a1,s4
    8000443a:	fc240513          	addi	a0,s0,-62
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	b2c080e7          	jalr	-1236(ra) # 80000f6a <strncpy>
  de.inum = inum;
    80004446:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000444a:	4741                	li	a4,16
    8000444c:	86a6                	mv	a3,s1
    8000444e:	fc040613          	addi	a2,s0,-64
    80004452:	4581                	li	a1,0
    80004454:	854a                	mv	a0,s2
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	c3e080e7          	jalr	-962(ra) # 80004094 <writei>
    8000445e:	1541                	addi	a0,a0,-16
    80004460:	00a03533          	snez	a0,a0
    80004464:	40a00533          	neg	a0,a0
}
    80004468:	70e2                	ld	ra,56(sp)
    8000446a:	7442                	ld	s0,48(sp)
    8000446c:	74a2                	ld	s1,40(sp)
    8000446e:	7902                	ld	s2,32(sp)
    80004470:	69e2                	ld	s3,24(sp)
    80004472:	6a42                	ld	s4,16(sp)
    80004474:	6121                	addi	sp,sp,64
    80004476:	8082                	ret
    iput(ip);
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	a2a080e7          	jalr	-1494(ra) # 80003ea2 <iput>
    return -1;
    80004480:	557d                	li	a0,-1
    80004482:	b7dd                	j	80004468 <dirlink+0x86>
      panic("dirlink read");
    80004484:	00004517          	auipc	a0,0x4
    80004488:	2fc50513          	addi	a0,a0,764 # 80008780 <syscalls+0x1f0>
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	0b4080e7          	jalr	180(ra) # 80000540 <panic>

0000000080004494 <namei>:

struct inode*
namei(char *path)
{
    80004494:	1101                	addi	sp,sp,-32
    80004496:	ec06                	sd	ra,24(sp)
    80004498:	e822                	sd	s0,16(sp)
    8000449a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000449c:	fe040613          	addi	a2,s0,-32
    800044a0:	4581                	li	a1,0
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	dda080e7          	jalr	-550(ra) # 8000427c <namex>
}
    800044aa:	60e2                	ld	ra,24(sp)
    800044ac:	6442                	ld	s0,16(sp)
    800044ae:	6105                	addi	sp,sp,32
    800044b0:	8082                	ret

00000000800044b2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044b2:	1141                	addi	sp,sp,-16
    800044b4:	e406                	sd	ra,8(sp)
    800044b6:	e022                	sd	s0,0(sp)
    800044b8:	0800                	addi	s0,sp,16
    800044ba:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044bc:	4585                	li	a1,1
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	dbe080e7          	jalr	-578(ra) # 8000427c <namex>
}
    800044c6:	60a2                	ld	ra,8(sp)
    800044c8:	6402                	ld	s0,0(sp)
    800044ca:	0141                	addi	sp,sp,16
    800044cc:	8082                	ret

00000000800044ce <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044ce:	1101                	addi	sp,sp,-32
    800044d0:	ec06                	sd	ra,24(sp)
    800044d2:	e822                	sd	s0,16(sp)
    800044d4:	e426                	sd	s1,8(sp)
    800044d6:	e04a                	sd	s2,0(sp)
    800044d8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044da:	0003c917          	auipc	s2,0x3c
    800044de:	7f690913          	addi	s2,s2,2038 # 80040cd0 <log>
    800044e2:	01892583          	lw	a1,24(s2)
    800044e6:	02892503          	lw	a0,40(s2)
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	fe6080e7          	jalr	-26(ra) # 800034d0 <bread>
    800044f2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044f4:	02c92683          	lw	a3,44(s2)
    800044f8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044fa:	02d05863          	blez	a3,8000452a <write_head+0x5c>
    800044fe:	0003d797          	auipc	a5,0x3d
    80004502:	80278793          	addi	a5,a5,-2046 # 80040d00 <log+0x30>
    80004506:	05c50713          	addi	a4,a0,92
    8000450a:	36fd                	addiw	a3,a3,-1
    8000450c:	02069613          	slli	a2,a3,0x20
    80004510:	01e65693          	srli	a3,a2,0x1e
    80004514:	0003c617          	auipc	a2,0x3c
    80004518:	7f060613          	addi	a2,a2,2032 # 80040d04 <log+0x34>
    8000451c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000451e:	4390                	lw	a2,0(a5)
    80004520:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004522:	0791                	addi	a5,a5,4
    80004524:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004526:	fed79ce3          	bne	a5,a3,8000451e <write_head+0x50>
  }
  bwrite(buf);
    8000452a:	8526                	mv	a0,s1
    8000452c:	fffff097          	auipc	ra,0xfffff
    80004530:	096080e7          	jalr	150(ra) # 800035c2 <bwrite>
  brelse(buf);
    80004534:	8526                	mv	a0,s1
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	0ca080e7          	jalr	202(ra) # 80003600 <brelse>
}
    8000453e:	60e2                	ld	ra,24(sp)
    80004540:	6442                	ld	s0,16(sp)
    80004542:	64a2                	ld	s1,8(sp)
    80004544:	6902                	ld	s2,0(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret

000000008000454a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000454a:	0003c797          	auipc	a5,0x3c
    8000454e:	7b27a783          	lw	a5,1970(a5) # 80040cfc <log+0x2c>
    80004552:	0af05d63          	blez	a5,8000460c <install_trans+0xc2>
{
    80004556:	7139                	addi	sp,sp,-64
    80004558:	fc06                	sd	ra,56(sp)
    8000455a:	f822                	sd	s0,48(sp)
    8000455c:	f426                	sd	s1,40(sp)
    8000455e:	f04a                	sd	s2,32(sp)
    80004560:	ec4e                	sd	s3,24(sp)
    80004562:	e852                	sd	s4,16(sp)
    80004564:	e456                	sd	s5,8(sp)
    80004566:	e05a                	sd	s6,0(sp)
    80004568:	0080                	addi	s0,sp,64
    8000456a:	8b2a                	mv	s6,a0
    8000456c:	0003ca97          	auipc	s5,0x3c
    80004570:	794a8a93          	addi	s5,s5,1940 # 80040d00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004574:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004576:	0003c997          	auipc	s3,0x3c
    8000457a:	75a98993          	addi	s3,s3,1882 # 80040cd0 <log>
    8000457e:	a00d                	j	800045a0 <install_trans+0x56>
    brelse(lbuf);
    80004580:	854a                	mv	a0,s2
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	07e080e7          	jalr	126(ra) # 80003600 <brelse>
    brelse(dbuf);
    8000458a:	8526                	mv	a0,s1
    8000458c:	fffff097          	auipc	ra,0xfffff
    80004590:	074080e7          	jalr	116(ra) # 80003600 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004594:	2a05                	addiw	s4,s4,1
    80004596:	0a91                	addi	s5,s5,4
    80004598:	02c9a783          	lw	a5,44(s3)
    8000459c:	04fa5e63          	bge	s4,a5,800045f8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045a0:	0189a583          	lw	a1,24(s3)
    800045a4:	014585bb          	addw	a1,a1,s4
    800045a8:	2585                	addiw	a1,a1,1
    800045aa:	0289a503          	lw	a0,40(s3)
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	f22080e7          	jalr	-222(ra) # 800034d0 <bread>
    800045b6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045b8:	000aa583          	lw	a1,0(s5)
    800045bc:	0289a503          	lw	a0,40(s3)
    800045c0:	fffff097          	auipc	ra,0xfffff
    800045c4:	f10080e7          	jalr	-240(ra) # 800034d0 <bread>
    800045c8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045ca:	40000613          	li	a2,1024
    800045ce:	05890593          	addi	a1,s2,88
    800045d2:	05850513          	addi	a0,a0,88
    800045d6:	ffffd097          	auipc	ra,0xffffd
    800045da:	8e4080e7          	jalr	-1820(ra) # 80000eba <memmove>
    bwrite(dbuf);  // write dst to disk
    800045de:	8526                	mv	a0,s1
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	fe2080e7          	jalr	-30(ra) # 800035c2 <bwrite>
    if(recovering == 0)
    800045e8:	f80b1ce3          	bnez	s6,80004580 <install_trans+0x36>
      bunpin(dbuf);
    800045ec:	8526                	mv	a0,s1
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	0ec080e7          	jalr	236(ra) # 800036da <bunpin>
    800045f6:	b769                	j	80004580 <install_trans+0x36>
}
    800045f8:	70e2                	ld	ra,56(sp)
    800045fa:	7442                	ld	s0,48(sp)
    800045fc:	74a2                	ld	s1,40(sp)
    800045fe:	7902                	ld	s2,32(sp)
    80004600:	69e2                	ld	s3,24(sp)
    80004602:	6a42                	ld	s4,16(sp)
    80004604:	6aa2                	ld	s5,8(sp)
    80004606:	6b02                	ld	s6,0(sp)
    80004608:	6121                	addi	sp,sp,64
    8000460a:	8082                	ret
    8000460c:	8082                	ret

000000008000460e <initlog>:
{
    8000460e:	7179                	addi	sp,sp,-48
    80004610:	f406                	sd	ra,40(sp)
    80004612:	f022                	sd	s0,32(sp)
    80004614:	ec26                	sd	s1,24(sp)
    80004616:	e84a                	sd	s2,16(sp)
    80004618:	e44e                	sd	s3,8(sp)
    8000461a:	1800                	addi	s0,sp,48
    8000461c:	892a                	mv	s2,a0
    8000461e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004620:	0003c497          	auipc	s1,0x3c
    80004624:	6b048493          	addi	s1,s1,1712 # 80040cd0 <log>
    80004628:	00004597          	auipc	a1,0x4
    8000462c:	16858593          	addi	a1,a1,360 # 80008790 <syscalls+0x200>
    80004630:	8526                	mv	a0,s1
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	6a0080e7          	jalr	1696(ra) # 80000cd2 <initlock>
  log.start = sb->logstart;
    8000463a:	0149a583          	lw	a1,20(s3)
    8000463e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004640:	0109a783          	lw	a5,16(s3)
    80004644:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004646:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000464a:	854a                	mv	a0,s2
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	e84080e7          	jalr	-380(ra) # 800034d0 <bread>
  log.lh.n = lh->n;
    80004654:	4d34                	lw	a3,88(a0)
    80004656:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004658:	02d05663          	blez	a3,80004684 <initlog+0x76>
    8000465c:	05c50793          	addi	a5,a0,92
    80004660:	0003c717          	auipc	a4,0x3c
    80004664:	6a070713          	addi	a4,a4,1696 # 80040d00 <log+0x30>
    80004668:	36fd                	addiw	a3,a3,-1
    8000466a:	02069613          	slli	a2,a3,0x20
    8000466e:	01e65693          	srli	a3,a2,0x1e
    80004672:	06050613          	addi	a2,a0,96
    80004676:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004678:	4390                	lw	a2,0(a5)
    8000467a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000467c:	0791                	addi	a5,a5,4
    8000467e:	0711                	addi	a4,a4,4
    80004680:	fed79ce3          	bne	a5,a3,80004678 <initlog+0x6a>
  brelse(buf);
    80004684:	fffff097          	auipc	ra,0xfffff
    80004688:	f7c080e7          	jalr	-132(ra) # 80003600 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000468c:	4505                	li	a0,1
    8000468e:	00000097          	auipc	ra,0x0
    80004692:	ebc080e7          	jalr	-324(ra) # 8000454a <install_trans>
  log.lh.n = 0;
    80004696:	0003c797          	auipc	a5,0x3c
    8000469a:	6607a323          	sw	zero,1638(a5) # 80040cfc <log+0x2c>
  write_head(); // clear the log
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	e30080e7          	jalr	-464(ra) # 800044ce <write_head>
}
    800046a6:	70a2                	ld	ra,40(sp)
    800046a8:	7402                	ld	s0,32(sp)
    800046aa:	64e2                	ld	s1,24(sp)
    800046ac:	6942                	ld	s2,16(sp)
    800046ae:	69a2                	ld	s3,8(sp)
    800046b0:	6145                	addi	sp,sp,48
    800046b2:	8082                	ret

00000000800046b4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046b4:	1101                	addi	sp,sp,-32
    800046b6:	ec06                	sd	ra,24(sp)
    800046b8:	e822                	sd	s0,16(sp)
    800046ba:	e426                	sd	s1,8(sp)
    800046bc:	e04a                	sd	s2,0(sp)
    800046be:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046c0:	0003c517          	auipc	a0,0x3c
    800046c4:	61050513          	addi	a0,a0,1552 # 80040cd0 <log>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	69a080e7          	jalr	1690(ra) # 80000d62 <acquire>
  while(1){
    if(log.committing){
    800046d0:	0003c497          	auipc	s1,0x3c
    800046d4:	60048493          	addi	s1,s1,1536 # 80040cd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046d8:	4979                	li	s2,30
    800046da:	a039                	j	800046e8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046dc:	85a6                	mv	a1,s1
    800046de:	8526                	mv	a0,s1
    800046e0:	ffffe097          	auipc	ra,0xffffe
    800046e4:	cf8080e7          	jalr	-776(ra) # 800023d8 <sleep>
    if(log.committing){
    800046e8:	50dc                	lw	a5,36(s1)
    800046ea:	fbed                	bnez	a5,800046dc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046ec:	5098                	lw	a4,32(s1)
    800046ee:	2705                	addiw	a4,a4,1
    800046f0:	0007069b          	sext.w	a3,a4
    800046f4:	0027179b          	slliw	a5,a4,0x2
    800046f8:	9fb9                	addw	a5,a5,a4
    800046fa:	0017979b          	slliw	a5,a5,0x1
    800046fe:	54d8                	lw	a4,44(s1)
    80004700:	9fb9                	addw	a5,a5,a4
    80004702:	00f95963          	bge	s2,a5,80004714 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004706:	85a6                	mv	a1,s1
    80004708:	8526                	mv	a0,s1
    8000470a:	ffffe097          	auipc	ra,0xffffe
    8000470e:	cce080e7          	jalr	-818(ra) # 800023d8 <sleep>
    80004712:	bfd9                	j	800046e8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004714:	0003c517          	auipc	a0,0x3c
    80004718:	5bc50513          	addi	a0,a0,1468 # 80040cd0 <log>
    8000471c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	6f8080e7          	jalr	1784(ra) # 80000e16 <release>
      break;
    }
  }
}
    80004726:	60e2                	ld	ra,24(sp)
    80004728:	6442                	ld	s0,16(sp)
    8000472a:	64a2                	ld	s1,8(sp)
    8000472c:	6902                	ld	s2,0(sp)
    8000472e:	6105                	addi	sp,sp,32
    80004730:	8082                	ret

0000000080004732 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004732:	7139                	addi	sp,sp,-64
    80004734:	fc06                	sd	ra,56(sp)
    80004736:	f822                	sd	s0,48(sp)
    80004738:	f426                	sd	s1,40(sp)
    8000473a:	f04a                	sd	s2,32(sp)
    8000473c:	ec4e                	sd	s3,24(sp)
    8000473e:	e852                	sd	s4,16(sp)
    80004740:	e456                	sd	s5,8(sp)
    80004742:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004744:	0003c497          	auipc	s1,0x3c
    80004748:	58c48493          	addi	s1,s1,1420 # 80040cd0 <log>
    8000474c:	8526                	mv	a0,s1
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	614080e7          	jalr	1556(ra) # 80000d62 <acquire>
  log.outstanding -= 1;
    80004756:	509c                	lw	a5,32(s1)
    80004758:	37fd                	addiw	a5,a5,-1
    8000475a:	0007891b          	sext.w	s2,a5
    8000475e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004760:	50dc                	lw	a5,36(s1)
    80004762:	e7b9                	bnez	a5,800047b0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004764:	04091e63          	bnez	s2,800047c0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004768:	0003c497          	auipc	s1,0x3c
    8000476c:	56848493          	addi	s1,s1,1384 # 80040cd0 <log>
    80004770:	4785                	li	a5,1
    80004772:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004774:	8526                	mv	a0,s1
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	6a0080e7          	jalr	1696(ra) # 80000e16 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000477e:	54dc                	lw	a5,44(s1)
    80004780:	06f04763          	bgtz	a5,800047ee <end_op+0xbc>
    acquire(&log.lock);
    80004784:	0003c497          	auipc	s1,0x3c
    80004788:	54c48493          	addi	s1,s1,1356 # 80040cd0 <log>
    8000478c:	8526                	mv	a0,s1
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	5d4080e7          	jalr	1492(ra) # 80000d62 <acquire>
    log.committing = 0;
    80004796:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000479a:	8526                	mv	a0,s1
    8000479c:	ffffe097          	auipc	ra,0xffffe
    800047a0:	ca0080e7          	jalr	-864(ra) # 8000243c <wakeup>
    release(&log.lock);
    800047a4:	8526                	mv	a0,s1
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	670080e7          	jalr	1648(ra) # 80000e16 <release>
}
    800047ae:	a03d                	j	800047dc <end_op+0xaa>
    panic("log.committing");
    800047b0:	00004517          	auipc	a0,0x4
    800047b4:	fe850513          	addi	a0,a0,-24 # 80008798 <syscalls+0x208>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	d88080e7          	jalr	-632(ra) # 80000540 <panic>
    wakeup(&log);
    800047c0:	0003c497          	auipc	s1,0x3c
    800047c4:	51048493          	addi	s1,s1,1296 # 80040cd0 <log>
    800047c8:	8526                	mv	a0,s1
    800047ca:	ffffe097          	auipc	ra,0xffffe
    800047ce:	c72080e7          	jalr	-910(ra) # 8000243c <wakeup>
  release(&log.lock);
    800047d2:	8526                	mv	a0,s1
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	642080e7          	jalr	1602(ra) # 80000e16 <release>
}
    800047dc:	70e2                	ld	ra,56(sp)
    800047de:	7442                	ld	s0,48(sp)
    800047e0:	74a2                	ld	s1,40(sp)
    800047e2:	7902                	ld	s2,32(sp)
    800047e4:	69e2                	ld	s3,24(sp)
    800047e6:	6a42                	ld	s4,16(sp)
    800047e8:	6aa2                	ld	s5,8(sp)
    800047ea:	6121                	addi	sp,sp,64
    800047ec:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800047ee:	0003ca97          	auipc	s5,0x3c
    800047f2:	512a8a93          	addi	s5,s5,1298 # 80040d00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047f6:	0003ca17          	auipc	s4,0x3c
    800047fa:	4daa0a13          	addi	s4,s4,1242 # 80040cd0 <log>
    800047fe:	018a2583          	lw	a1,24(s4)
    80004802:	012585bb          	addw	a1,a1,s2
    80004806:	2585                	addiw	a1,a1,1
    80004808:	028a2503          	lw	a0,40(s4)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	cc4080e7          	jalr	-828(ra) # 800034d0 <bread>
    80004814:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004816:	000aa583          	lw	a1,0(s5)
    8000481a:	028a2503          	lw	a0,40(s4)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	cb2080e7          	jalr	-846(ra) # 800034d0 <bread>
    80004826:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004828:	40000613          	li	a2,1024
    8000482c:	05850593          	addi	a1,a0,88
    80004830:	05848513          	addi	a0,s1,88
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	686080e7          	jalr	1670(ra) # 80000eba <memmove>
    bwrite(to);  // write the log
    8000483c:	8526                	mv	a0,s1
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	d84080e7          	jalr	-636(ra) # 800035c2 <bwrite>
    brelse(from);
    80004846:	854e                	mv	a0,s3
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	db8080e7          	jalr	-584(ra) # 80003600 <brelse>
    brelse(to);
    80004850:	8526                	mv	a0,s1
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	dae080e7          	jalr	-594(ra) # 80003600 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000485a:	2905                	addiw	s2,s2,1
    8000485c:	0a91                	addi	s5,s5,4
    8000485e:	02ca2783          	lw	a5,44(s4)
    80004862:	f8f94ee3          	blt	s2,a5,800047fe <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	c68080e7          	jalr	-920(ra) # 800044ce <write_head>
    install_trans(0); // Now install writes to home locations
    8000486e:	4501                	li	a0,0
    80004870:	00000097          	auipc	ra,0x0
    80004874:	cda080e7          	jalr	-806(ra) # 8000454a <install_trans>
    log.lh.n = 0;
    80004878:	0003c797          	auipc	a5,0x3c
    8000487c:	4807a223          	sw	zero,1156(a5) # 80040cfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004880:	00000097          	auipc	ra,0x0
    80004884:	c4e080e7          	jalr	-946(ra) # 800044ce <write_head>
    80004888:	bdf5                	j	80004784 <end_op+0x52>

000000008000488a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000488a:	1101                	addi	sp,sp,-32
    8000488c:	ec06                	sd	ra,24(sp)
    8000488e:	e822                	sd	s0,16(sp)
    80004890:	e426                	sd	s1,8(sp)
    80004892:	e04a                	sd	s2,0(sp)
    80004894:	1000                	addi	s0,sp,32
    80004896:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004898:	0003c917          	auipc	s2,0x3c
    8000489c:	43890913          	addi	s2,s2,1080 # 80040cd0 <log>
    800048a0:	854a                	mv	a0,s2
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	4c0080e7          	jalr	1216(ra) # 80000d62 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048aa:	02c92603          	lw	a2,44(s2)
    800048ae:	47f5                	li	a5,29
    800048b0:	06c7c563          	blt	a5,a2,8000491a <log_write+0x90>
    800048b4:	0003c797          	auipc	a5,0x3c
    800048b8:	4387a783          	lw	a5,1080(a5) # 80040cec <log+0x1c>
    800048bc:	37fd                	addiw	a5,a5,-1
    800048be:	04f65e63          	bge	a2,a5,8000491a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048c2:	0003c797          	auipc	a5,0x3c
    800048c6:	42e7a783          	lw	a5,1070(a5) # 80040cf0 <log+0x20>
    800048ca:	06f05063          	blez	a5,8000492a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048ce:	4781                	li	a5,0
    800048d0:	06c05563          	blez	a2,8000493a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048d4:	44cc                	lw	a1,12(s1)
    800048d6:	0003c717          	auipc	a4,0x3c
    800048da:	42a70713          	addi	a4,a4,1066 # 80040d00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048de:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048e0:	4314                	lw	a3,0(a4)
    800048e2:	04b68c63          	beq	a3,a1,8000493a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048e6:	2785                	addiw	a5,a5,1
    800048e8:	0711                	addi	a4,a4,4
    800048ea:	fef61be3          	bne	a2,a5,800048e0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048ee:	0621                	addi	a2,a2,8
    800048f0:	060a                	slli	a2,a2,0x2
    800048f2:	0003c797          	auipc	a5,0x3c
    800048f6:	3de78793          	addi	a5,a5,990 # 80040cd0 <log>
    800048fa:	97b2                	add	a5,a5,a2
    800048fc:	44d8                	lw	a4,12(s1)
    800048fe:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004900:	8526                	mv	a0,s1
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	d9c080e7          	jalr	-612(ra) # 8000369e <bpin>
    log.lh.n++;
    8000490a:	0003c717          	auipc	a4,0x3c
    8000490e:	3c670713          	addi	a4,a4,966 # 80040cd0 <log>
    80004912:	575c                	lw	a5,44(a4)
    80004914:	2785                	addiw	a5,a5,1
    80004916:	d75c                	sw	a5,44(a4)
    80004918:	a82d                	j	80004952 <log_write+0xc8>
    panic("too big a transaction");
    8000491a:	00004517          	auipc	a0,0x4
    8000491e:	e8e50513          	addi	a0,a0,-370 # 800087a8 <syscalls+0x218>
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	c1e080e7          	jalr	-994(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000492a:	00004517          	auipc	a0,0x4
    8000492e:	e9650513          	addi	a0,a0,-362 # 800087c0 <syscalls+0x230>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	c0e080e7          	jalr	-1010(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000493a:	00878693          	addi	a3,a5,8
    8000493e:	068a                	slli	a3,a3,0x2
    80004940:	0003c717          	auipc	a4,0x3c
    80004944:	39070713          	addi	a4,a4,912 # 80040cd0 <log>
    80004948:	9736                	add	a4,a4,a3
    8000494a:	44d4                	lw	a3,12(s1)
    8000494c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000494e:	faf609e3          	beq	a2,a5,80004900 <log_write+0x76>
  }
  release(&log.lock);
    80004952:	0003c517          	auipc	a0,0x3c
    80004956:	37e50513          	addi	a0,a0,894 # 80040cd0 <log>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	4bc080e7          	jalr	1212(ra) # 80000e16 <release>
}
    80004962:	60e2                	ld	ra,24(sp)
    80004964:	6442                	ld	s0,16(sp)
    80004966:	64a2                	ld	s1,8(sp)
    80004968:	6902                	ld	s2,0(sp)
    8000496a:	6105                	addi	sp,sp,32
    8000496c:	8082                	ret

000000008000496e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000496e:	1101                	addi	sp,sp,-32
    80004970:	ec06                	sd	ra,24(sp)
    80004972:	e822                	sd	s0,16(sp)
    80004974:	e426                	sd	s1,8(sp)
    80004976:	e04a                	sd	s2,0(sp)
    80004978:	1000                	addi	s0,sp,32
    8000497a:	84aa                	mv	s1,a0
    8000497c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000497e:	00004597          	auipc	a1,0x4
    80004982:	e6258593          	addi	a1,a1,-414 # 800087e0 <syscalls+0x250>
    80004986:	0521                	addi	a0,a0,8
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	34a080e7          	jalr	842(ra) # 80000cd2 <initlock>
  lk->name = name;
    80004990:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004994:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004998:	0204a423          	sw	zero,40(s1)
}
    8000499c:	60e2                	ld	ra,24(sp)
    8000499e:	6442                	ld	s0,16(sp)
    800049a0:	64a2                	ld	s1,8(sp)
    800049a2:	6902                	ld	s2,0(sp)
    800049a4:	6105                	addi	sp,sp,32
    800049a6:	8082                	ret

00000000800049a8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049a8:	1101                	addi	sp,sp,-32
    800049aa:	ec06                	sd	ra,24(sp)
    800049ac:	e822                	sd	s0,16(sp)
    800049ae:	e426                	sd	s1,8(sp)
    800049b0:	e04a                	sd	s2,0(sp)
    800049b2:	1000                	addi	s0,sp,32
    800049b4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049b6:	00850913          	addi	s2,a0,8
    800049ba:	854a                	mv	a0,s2
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	3a6080e7          	jalr	934(ra) # 80000d62 <acquire>
  while (lk->locked) {
    800049c4:	409c                	lw	a5,0(s1)
    800049c6:	cb89                	beqz	a5,800049d8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049c8:	85ca                	mv	a1,s2
    800049ca:	8526                	mv	a0,s1
    800049cc:	ffffe097          	auipc	ra,0xffffe
    800049d0:	a0c080e7          	jalr	-1524(ra) # 800023d8 <sleep>
  while (lk->locked) {
    800049d4:	409c                	lw	a5,0(s1)
    800049d6:	fbed                	bnez	a5,800049c8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049d8:	4785                	li	a5,1
    800049da:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049dc:	ffffd097          	auipc	ra,0xffffd
    800049e0:	294080e7          	jalr	660(ra) # 80001c70 <myproc>
    800049e4:	591c                	lw	a5,48(a0)
    800049e6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049e8:	854a                	mv	a0,s2
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	42c080e7          	jalr	1068(ra) # 80000e16 <release>
}
    800049f2:	60e2                	ld	ra,24(sp)
    800049f4:	6442                	ld	s0,16(sp)
    800049f6:	64a2                	ld	s1,8(sp)
    800049f8:	6902                	ld	s2,0(sp)
    800049fa:	6105                	addi	sp,sp,32
    800049fc:	8082                	ret

00000000800049fe <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049fe:	1101                	addi	sp,sp,-32
    80004a00:	ec06                	sd	ra,24(sp)
    80004a02:	e822                	sd	s0,16(sp)
    80004a04:	e426                	sd	s1,8(sp)
    80004a06:	e04a                	sd	s2,0(sp)
    80004a08:	1000                	addi	s0,sp,32
    80004a0a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a0c:	00850913          	addi	s2,a0,8
    80004a10:	854a                	mv	a0,s2
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	350080e7          	jalr	848(ra) # 80000d62 <acquire>
  lk->locked = 0;
    80004a1a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a1e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffe097          	auipc	ra,0xffffe
    80004a28:	a18080e7          	jalr	-1512(ra) # 8000243c <wakeup>
  release(&lk->lk);
    80004a2c:	854a                	mv	a0,s2
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	3e8080e7          	jalr	1000(ra) # 80000e16 <release>
}
    80004a36:	60e2                	ld	ra,24(sp)
    80004a38:	6442                	ld	s0,16(sp)
    80004a3a:	64a2                	ld	s1,8(sp)
    80004a3c:	6902                	ld	s2,0(sp)
    80004a3e:	6105                	addi	sp,sp,32
    80004a40:	8082                	ret

0000000080004a42 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a42:	7179                	addi	sp,sp,-48
    80004a44:	f406                	sd	ra,40(sp)
    80004a46:	f022                	sd	s0,32(sp)
    80004a48:	ec26                	sd	s1,24(sp)
    80004a4a:	e84a                	sd	s2,16(sp)
    80004a4c:	e44e                	sd	s3,8(sp)
    80004a4e:	1800                	addi	s0,sp,48
    80004a50:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a52:	00850913          	addi	s2,a0,8
    80004a56:	854a                	mv	a0,s2
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	30a080e7          	jalr	778(ra) # 80000d62 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a60:	409c                	lw	a5,0(s1)
    80004a62:	ef99                	bnez	a5,80004a80 <holdingsleep+0x3e>
    80004a64:	4481                	li	s1,0
  release(&lk->lk);
    80004a66:	854a                	mv	a0,s2
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	3ae080e7          	jalr	942(ra) # 80000e16 <release>
  return r;
}
    80004a70:	8526                	mv	a0,s1
    80004a72:	70a2                	ld	ra,40(sp)
    80004a74:	7402                	ld	s0,32(sp)
    80004a76:	64e2                	ld	s1,24(sp)
    80004a78:	6942                	ld	s2,16(sp)
    80004a7a:	69a2                	ld	s3,8(sp)
    80004a7c:	6145                	addi	sp,sp,48
    80004a7e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a80:	0284a983          	lw	s3,40(s1)
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	1ec080e7          	jalr	492(ra) # 80001c70 <myproc>
    80004a8c:	5904                	lw	s1,48(a0)
    80004a8e:	413484b3          	sub	s1,s1,s3
    80004a92:	0014b493          	seqz	s1,s1
    80004a96:	bfc1                	j	80004a66 <holdingsleep+0x24>

0000000080004a98 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a98:	1141                	addi	sp,sp,-16
    80004a9a:	e406                	sd	ra,8(sp)
    80004a9c:	e022                	sd	s0,0(sp)
    80004a9e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004aa0:	00004597          	auipc	a1,0x4
    80004aa4:	d5058593          	addi	a1,a1,-688 # 800087f0 <syscalls+0x260>
    80004aa8:	0003c517          	auipc	a0,0x3c
    80004aac:	37050513          	addi	a0,a0,880 # 80040e18 <ftable>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	222080e7          	jalr	546(ra) # 80000cd2 <initlock>
}
    80004ab8:	60a2                	ld	ra,8(sp)
    80004aba:	6402                	ld	s0,0(sp)
    80004abc:	0141                	addi	sp,sp,16
    80004abe:	8082                	ret

0000000080004ac0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ac0:	1101                	addi	sp,sp,-32
    80004ac2:	ec06                	sd	ra,24(sp)
    80004ac4:	e822                	sd	s0,16(sp)
    80004ac6:	e426                	sd	s1,8(sp)
    80004ac8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004aca:	0003c517          	auipc	a0,0x3c
    80004ace:	34e50513          	addi	a0,a0,846 # 80040e18 <ftable>
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	290080e7          	jalr	656(ra) # 80000d62 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ada:	0003c497          	auipc	s1,0x3c
    80004ade:	35648493          	addi	s1,s1,854 # 80040e30 <ftable+0x18>
    80004ae2:	0003d717          	auipc	a4,0x3d
    80004ae6:	2ee70713          	addi	a4,a4,750 # 80041dd0 <disk>
    if(f->ref == 0){
    80004aea:	40dc                	lw	a5,4(s1)
    80004aec:	cf99                	beqz	a5,80004b0a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004aee:	02848493          	addi	s1,s1,40
    80004af2:	fee49ce3          	bne	s1,a4,80004aea <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004af6:	0003c517          	auipc	a0,0x3c
    80004afa:	32250513          	addi	a0,a0,802 # 80040e18 <ftable>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	318080e7          	jalr	792(ra) # 80000e16 <release>
  return 0;
    80004b06:	4481                	li	s1,0
    80004b08:	a819                	j	80004b1e <filealloc+0x5e>
      f->ref = 1;
    80004b0a:	4785                	li	a5,1
    80004b0c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b0e:	0003c517          	auipc	a0,0x3c
    80004b12:	30a50513          	addi	a0,a0,778 # 80040e18 <ftable>
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	300080e7          	jalr	768(ra) # 80000e16 <release>
}
    80004b1e:	8526                	mv	a0,s1
    80004b20:	60e2                	ld	ra,24(sp)
    80004b22:	6442                	ld	s0,16(sp)
    80004b24:	64a2                	ld	s1,8(sp)
    80004b26:	6105                	addi	sp,sp,32
    80004b28:	8082                	ret

0000000080004b2a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b2a:	1101                	addi	sp,sp,-32
    80004b2c:	ec06                	sd	ra,24(sp)
    80004b2e:	e822                	sd	s0,16(sp)
    80004b30:	e426                	sd	s1,8(sp)
    80004b32:	1000                	addi	s0,sp,32
    80004b34:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b36:	0003c517          	auipc	a0,0x3c
    80004b3a:	2e250513          	addi	a0,a0,738 # 80040e18 <ftable>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	224080e7          	jalr	548(ra) # 80000d62 <acquire>
  if(f->ref < 1)
    80004b46:	40dc                	lw	a5,4(s1)
    80004b48:	02f05263          	blez	a5,80004b6c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b4c:	2785                	addiw	a5,a5,1
    80004b4e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b50:	0003c517          	auipc	a0,0x3c
    80004b54:	2c850513          	addi	a0,a0,712 # 80040e18 <ftable>
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	2be080e7          	jalr	702(ra) # 80000e16 <release>
  return f;
}
    80004b60:	8526                	mv	a0,s1
    80004b62:	60e2                	ld	ra,24(sp)
    80004b64:	6442                	ld	s0,16(sp)
    80004b66:	64a2                	ld	s1,8(sp)
    80004b68:	6105                	addi	sp,sp,32
    80004b6a:	8082                	ret
    panic("filedup");
    80004b6c:	00004517          	auipc	a0,0x4
    80004b70:	c8c50513          	addi	a0,a0,-884 # 800087f8 <syscalls+0x268>
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	9cc080e7          	jalr	-1588(ra) # 80000540 <panic>

0000000080004b7c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b7c:	7139                	addi	sp,sp,-64
    80004b7e:	fc06                	sd	ra,56(sp)
    80004b80:	f822                	sd	s0,48(sp)
    80004b82:	f426                	sd	s1,40(sp)
    80004b84:	f04a                	sd	s2,32(sp)
    80004b86:	ec4e                	sd	s3,24(sp)
    80004b88:	e852                	sd	s4,16(sp)
    80004b8a:	e456                	sd	s5,8(sp)
    80004b8c:	0080                	addi	s0,sp,64
    80004b8e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b90:	0003c517          	auipc	a0,0x3c
    80004b94:	28850513          	addi	a0,a0,648 # 80040e18 <ftable>
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	1ca080e7          	jalr	458(ra) # 80000d62 <acquire>
  if(f->ref < 1)
    80004ba0:	40dc                	lw	a5,4(s1)
    80004ba2:	06f05163          	blez	a5,80004c04 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ba6:	37fd                	addiw	a5,a5,-1
    80004ba8:	0007871b          	sext.w	a4,a5
    80004bac:	c0dc                	sw	a5,4(s1)
    80004bae:	06e04363          	bgtz	a4,80004c14 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bb2:	0004a903          	lw	s2,0(s1)
    80004bb6:	0094ca83          	lbu	s5,9(s1)
    80004bba:	0104ba03          	ld	s4,16(s1)
    80004bbe:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bc2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bc6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bca:	0003c517          	auipc	a0,0x3c
    80004bce:	24e50513          	addi	a0,a0,590 # 80040e18 <ftable>
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	244080e7          	jalr	580(ra) # 80000e16 <release>

  if(ff.type == FD_PIPE){
    80004bda:	4785                	li	a5,1
    80004bdc:	04f90d63          	beq	s2,a5,80004c36 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004be0:	3979                	addiw	s2,s2,-2
    80004be2:	4785                	li	a5,1
    80004be4:	0527e063          	bltu	a5,s2,80004c24 <fileclose+0xa8>
    begin_op();
    80004be8:	00000097          	auipc	ra,0x0
    80004bec:	acc080e7          	jalr	-1332(ra) # 800046b4 <begin_op>
    iput(ff.ip);
    80004bf0:	854e                	mv	a0,s3
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	2b0080e7          	jalr	688(ra) # 80003ea2 <iput>
    end_op();
    80004bfa:	00000097          	auipc	ra,0x0
    80004bfe:	b38080e7          	jalr	-1224(ra) # 80004732 <end_op>
    80004c02:	a00d                	j	80004c24 <fileclose+0xa8>
    panic("fileclose");
    80004c04:	00004517          	auipc	a0,0x4
    80004c08:	bfc50513          	addi	a0,a0,-1028 # 80008800 <syscalls+0x270>
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	934080e7          	jalr	-1740(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004c14:	0003c517          	auipc	a0,0x3c
    80004c18:	20450513          	addi	a0,a0,516 # 80040e18 <ftable>
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	1fa080e7          	jalr	506(ra) # 80000e16 <release>
  }
}
    80004c24:	70e2                	ld	ra,56(sp)
    80004c26:	7442                	ld	s0,48(sp)
    80004c28:	74a2                	ld	s1,40(sp)
    80004c2a:	7902                	ld	s2,32(sp)
    80004c2c:	69e2                	ld	s3,24(sp)
    80004c2e:	6a42                	ld	s4,16(sp)
    80004c30:	6aa2                	ld	s5,8(sp)
    80004c32:	6121                	addi	sp,sp,64
    80004c34:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c36:	85d6                	mv	a1,s5
    80004c38:	8552                	mv	a0,s4
    80004c3a:	00000097          	auipc	ra,0x0
    80004c3e:	34c080e7          	jalr	844(ra) # 80004f86 <pipeclose>
    80004c42:	b7cd                	j	80004c24 <fileclose+0xa8>

0000000080004c44 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c44:	715d                	addi	sp,sp,-80
    80004c46:	e486                	sd	ra,72(sp)
    80004c48:	e0a2                	sd	s0,64(sp)
    80004c4a:	fc26                	sd	s1,56(sp)
    80004c4c:	f84a                	sd	s2,48(sp)
    80004c4e:	f44e                	sd	s3,40(sp)
    80004c50:	0880                	addi	s0,sp,80
    80004c52:	84aa                	mv	s1,a0
    80004c54:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c56:	ffffd097          	auipc	ra,0xffffd
    80004c5a:	01a080e7          	jalr	26(ra) # 80001c70 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c5e:	409c                	lw	a5,0(s1)
    80004c60:	37f9                	addiw	a5,a5,-2
    80004c62:	4705                	li	a4,1
    80004c64:	04f76763          	bltu	a4,a5,80004cb2 <filestat+0x6e>
    80004c68:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c6a:	6c88                	ld	a0,24(s1)
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	07c080e7          	jalr	124(ra) # 80003ce8 <ilock>
    stati(f->ip, &st);
    80004c74:	fb840593          	addi	a1,s0,-72
    80004c78:	6c88                	ld	a0,24(s1)
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	2f8080e7          	jalr	760(ra) # 80003f72 <stati>
    iunlock(f->ip);
    80004c82:	6c88                	ld	a0,24(s1)
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	126080e7          	jalr	294(ra) # 80003daa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c8c:	46e1                	li	a3,24
    80004c8e:	fb840613          	addi	a2,s0,-72
    80004c92:	85ce                	mv	a1,s3
    80004c94:	05093503          	ld	a0,80(s2)
    80004c98:	ffffd097          	auipc	ra,0xffffd
    80004c9c:	b9a080e7          	jalr	-1126(ra) # 80001832 <copyout>
    80004ca0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ca4:	60a6                	ld	ra,72(sp)
    80004ca6:	6406                	ld	s0,64(sp)
    80004ca8:	74e2                	ld	s1,56(sp)
    80004caa:	7942                	ld	s2,48(sp)
    80004cac:	79a2                	ld	s3,40(sp)
    80004cae:	6161                	addi	sp,sp,80
    80004cb0:	8082                	ret
  return -1;
    80004cb2:	557d                	li	a0,-1
    80004cb4:	bfc5                	j	80004ca4 <filestat+0x60>

0000000080004cb6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cb6:	7179                	addi	sp,sp,-48
    80004cb8:	f406                	sd	ra,40(sp)
    80004cba:	f022                	sd	s0,32(sp)
    80004cbc:	ec26                	sd	s1,24(sp)
    80004cbe:	e84a                	sd	s2,16(sp)
    80004cc0:	e44e                	sd	s3,8(sp)
    80004cc2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cc4:	00854783          	lbu	a5,8(a0)
    80004cc8:	c3d5                	beqz	a5,80004d6c <fileread+0xb6>
    80004cca:	84aa                	mv	s1,a0
    80004ccc:	89ae                	mv	s3,a1
    80004cce:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cd0:	411c                	lw	a5,0(a0)
    80004cd2:	4705                	li	a4,1
    80004cd4:	04e78963          	beq	a5,a4,80004d26 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cd8:	470d                	li	a4,3
    80004cda:	04e78d63          	beq	a5,a4,80004d34 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cde:	4709                	li	a4,2
    80004ce0:	06e79e63          	bne	a5,a4,80004d5c <fileread+0xa6>
    ilock(f->ip);
    80004ce4:	6d08                	ld	a0,24(a0)
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	002080e7          	jalr	2(ra) # 80003ce8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cee:	874a                	mv	a4,s2
    80004cf0:	5094                	lw	a3,32(s1)
    80004cf2:	864e                	mv	a2,s3
    80004cf4:	4585                	li	a1,1
    80004cf6:	6c88                	ld	a0,24(s1)
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	2a4080e7          	jalr	676(ra) # 80003f9c <readi>
    80004d00:	892a                	mv	s2,a0
    80004d02:	00a05563          	blez	a0,80004d0c <fileread+0x56>
      f->off += r;
    80004d06:	509c                	lw	a5,32(s1)
    80004d08:	9fa9                	addw	a5,a5,a0
    80004d0a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d0c:	6c88                	ld	a0,24(s1)
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	09c080e7          	jalr	156(ra) # 80003daa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d16:	854a                	mv	a0,s2
    80004d18:	70a2                	ld	ra,40(sp)
    80004d1a:	7402                	ld	s0,32(sp)
    80004d1c:	64e2                	ld	s1,24(sp)
    80004d1e:	6942                	ld	s2,16(sp)
    80004d20:	69a2                	ld	s3,8(sp)
    80004d22:	6145                	addi	sp,sp,48
    80004d24:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d26:	6908                	ld	a0,16(a0)
    80004d28:	00000097          	auipc	ra,0x0
    80004d2c:	3c6080e7          	jalr	966(ra) # 800050ee <piperead>
    80004d30:	892a                	mv	s2,a0
    80004d32:	b7d5                	j	80004d16 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d34:	02451783          	lh	a5,36(a0)
    80004d38:	03079693          	slli	a3,a5,0x30
    80004d3c:	92c1                	srli	a3,a3,0x30
    80004d3e:	4725                	li	a4,9
    80004d40:	02d76863          	bltu	a4,a3,80004d70 <fileread+0xba>
    80004d44:	0792                	slli	a5,a5,0x4
    80004d46:	0003c717          	auipc	a4,0x3c
    80004d4a:	03270713          	addi	a4,a4,50 # 80040d78 <devsw>
    80004d4e:	97ba                	add	a5,a5,a4
    80004d50:	639c                	ld	a5,0(a5)
    80004d52:	c38d                	beqz	a5,80004d74 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d54:	4505                	li	a0,1
    80004d56:	9782                	jalr	a5
    80004d58:	892a                	mv	s2,a0
    80004d5a:	bf75                	j	80004d16 <fileread+0x60>
    panic("fileread");
    80004d5c:	00004517          	auipc	a0,0x4
    80004d60:	ab450513          	addi	a0,a0,-1356 # 80008810 <syscalls+0x280>
    80004d64:	ffffb097          	auipc	ra,0xffffb
    80004d68:	7dc080e7          	jalr	2012(ra) # 80000540 <panic>
    return -1;
    80004d6c:	597d                	li	s2,-1
    80004d6e:	b765                	j	80004d16 <fileread+0x60>
      return -1;
    80004d70:	597d                	li	s2,-1
    80004d72:	b755                	j	80004d16 <fileread+0x60>
    80004d74:	597d                	li	s2,-1
    80004d76:	b745                	j	80004d16 <fileread+0x60>

0000000080004d78 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d78:	715d                	addi	sp,sp,-80
    80004d7a:	e486                	sd	ra,72(sp)
    80004d7c:	e0a2                	sd	s0,64(sp)
    80004d7e:	fc26                	sd	s1,56(sp)
    80004d80:	f84a                	sd	s2,48(sp)
    80004d82:	f44e                	sd	s3,40(sp)
    80004d84:	f052                	sd	s4,32(sp)
    80004d86:	ec56                	sd	s5,24(sp)
    80004d88:	e85a                	sd	s6,16(sp)
    80004d8a:	e45e                	sd	s7,8(sp)
    80004d8c:	e062                	sd	s8,0(sp)
    80004d8e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d90:	00954783          	lbu	a5,9(a0)
    80004d94:	10078663          	beqz	a5,80004ea0 <filewrite+0x128>
    80004d98:	892a                	mv	s2,a0
    80004d9a:	8b2e                	mv	s6,a1
    80004d9c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d9e:	411c                	lw	a5,0(a0)
    80004da0:	4705                	li	a4,1
    80004da2:	02e78263          	beq	a5,a4,80004dc6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004da6:	470d                	li	a4,3
    80004da8:	02e78663          	beq	a5,a4,80004dd4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dac:	4709                	li	a4,2
    80004dae:	0ee79163          	bne	a5,a4,80004e90 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004db2:	0ac05d63          	blez	a2,80004e6c <filewrite+0xf4>
    int i = 0;
    80004db6:	4981                	li	s3,0
    80004db8:	6b85                	lui	s7,0x1
    80004dba:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004dbe:	6c05                	lui	s8,0x1
    80004dc0:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004dc4:	a861                	j	80004e5c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004dc6:	6908                	ld	a0,16(a0)
    80004dc8:	00000097          	auipc	ra,0x0
    80004dcc:	22e080e7          	jalr	558(ra) # 80004ff6 <pipewrite>
    80004dd0:	8a2a                	mv	s4,a0
    80004dd2:	a045                	j	80004e72 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004dd4:	02451783          	lh	a5,36(a0)
    80004dd8:	03079693          	slli	a3,a5,0x30
    80004ddc:	92c1                	srli	a3,a3,0x30
    80004dde:	4725                	li	a4,9
    80004de0:	0cd76263          	bltu	a4,a3,80004ea4 <filewrite+0x12c>
    80004de4:	0792                	slli	a5,a5,0x4
    80004de6:	0003c717          	auipc	a4,0x3c
    80004dea:	f9270713          	addi	a4,a4,-110 # 80040d78 <devsw>
    80004dee:	97ba                	add	a5,a5,a4
    80004df0:	679c                	ld	a5,8(a5)
    80004df2:	cbdd                	beqz	a5,80004ea8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004df4:	4505                	li	a0,1
    80004df6:	9782                	jalr	a5
    80004df8:	8a2a                	mv	s4,a0
    80004dfa:	a8a5                	j	80004e72 <filewrite+0xfa>
    80004dfc:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e00:	00000097          	auipc	ra,0x0
    80004e04:	8b4080e7          	jalr	-1868(ra) # 800046b4 <begin_op>
      ilock(f->ip);
    80004e08:	01893503          	ld	a0,24(s2)
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	edc080e7          	jalr	-292(ra) # 80003ce8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e14:	8756                	mv	a4,s5
    80004e16:	02092683          	lw	a3,32(s2)
    80004e1a:	01698633          	add	a2,s3,s6
    80004e1e:	4585                	li	a1,1
    80004e20:	01893503          	ld	a0,24(s2)
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	270080e7          	jalr	624(ra) # 80004094 <writei>
    80004e2c:	84aa                	mv	s1,a0
    80004e2e:	00a05763          	blez	a0,80004e3c <filewrite+0xc4>
        f->off += r;
    80004e32:	02092783          	lw	a5,32(s2)
    80004e36:	9fa9                	addw	a5,a5,a0
    80004e38:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e3c:	01893503          	ld	a0,24(s2)
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	f6a080e7          	jalr	-150(ra) # 80003daa <iunlock>
      end_op();
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	8ea080e7          	jalr	-1814(ra) # 80004732 <end_op>

      if(r != n1){
    80004e50:	009a9f63          	bne	s5,s1,80004e6e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e54:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e58:	0149db63          	bge	s3,s4,80004e6e <filewrite+0xf6>
      int n1 = n - i;
    80004e5c:	413a04bb          	subw	s1,s4,s3
    80004e60:	0004879b          	sext.w	a5,s1
    80004e64:	f8fbdce3          	bge	s7,a5,80004dfc <filewrite+0x84>
    80004e68:	84e2                	mv	s1,s8
    80004e6a:	bf49                	j	80004dfc <filewrite+0x84>
    int i = 0;
    80004e6c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e6e:	013a1f63          	bne	s4,s3,80004e8c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e72:	8552                	mv	a0,s4
    80004e74:	60a6                	ld	ra,72(sp)
    80004e76:	6406                	ld	s0,64(sp)
    80004e78:	74e2                	ld	s1,56(sp)
    80004e7a:	7942                	ld	s2,48(sp)
    80004e7c:	79a2                	ld	s3,40(sp)
    80004e7e:	7a02                	ld	s4,32(sp)
    80004e80:	6ae2                	ld	s5,24(sp)
    80004e82:	6b42                	ld	s6,16(sp)
    80004e84:	6ba2                	ld	s7,8(sp)
    80004e86:	6c02                	ld	s8,0(sp)
    80004e88:	6161                	addi	sp,sp,80
    80004e8a:	8082                	ret
    ret = (i == n ? n : -1);
    80004e8c:	5a7d                	li	s4,-1
    80004e8e:	b7d5                	j	80004e72 <filewrite+0xfa>
    panic("filewrite");
    80004e90:	00004517          	auipc	a0,0x4
    80004e94:	99050513          	addi	a0,a0,-1648 # 80008820 <syscalls+0x290>
    80004e98:	ffffb097          	auipc	ra,0xffffb
    80004e9c:	6a8080e7          	jalr	1704(ra) # 80000540 <panic>
    return -1;
    80004ea0:	5a7d                	li	s4,-1
    80004ea2:	bfc1                	j	80004e72 <filewrite+0xfa>
      return -1;
    80004ea4:	5a7d                	li	s4,-1
    80004ea6:	b7f1                	j	80004e72 <filewrite+0xfa>
    80004ea8:	5a7d                	li	s4,-1
    80004eaa:	b7e1                	j	80004e72 <filewrite+0xfa>

0000000080004eac <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004eac:	7179                	addi	sp,sp,-48
    80004eae:	f406                	sd	ra,40(sp)
    80004eb0:	f022                	sd	s0,32(sp)
    80004eb2:	ec26                	sd	s1,24(sp)
    80004eb4:	e84a                	sd	s2,16(sp)
    80004eb6:	e44e                	sd	s3,8(sp)
    80004eb8:	e052                	sd	s4,0(sp)
    80004eba:	1800                	addi	s0,sp,48
    80004ebc:	84aa                	mv	s1,a0
    80004ebe:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ec0:	0005b023          	sd	zero,0(a1)
    80004ec4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ec8:	00000097          	auipc	ra,0x0
    80004ecc:	bf8080e7          	jalr	-1032(ra) # 80004ac0 <filealloc>
    80004ed0:	e088                	sd	a0,0(s1)
    80004ed2:	c551                	beqz	a0,80004f5e <pipealloc+0xb2>
    80004ed4:	00000097          	auipc	ra,0x0
    80004ed8:	bec080e7          	jalr	-1044(ra) # 80004ac0 <filealloc>
    80004edc:	00aa3023          	sd	a0,0(s4)
    80004ee0:	c92d                	beqz	a0,80004f52 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	c80080e7          	jalr	-896(ra) # 80000b62 <kalloc>
    80004eea:	892a                	mv	s2,a0
    80004eec:	c125                	beqz	a0,80004f4c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004eee:	4985                	li	s3,1
    80004ef0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ef4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ef8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004efc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f00:	00004597          	auipc	a1,0x4
    80004f04:	93058593          	addi	a1,a1,-1744 # 80008830 <syscalls+0x2a0>
    80004f08:	ffffc097          	auipc	ra,0xffffc
    80004f0c:	dca080e7          	jalr	-566(ra) # 80000cd2 <initlock>
  (*f0)->type = FD_PIPE;
    80004f10:	609c                	ld	a5,0(s1)
    80004f12:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f16:	609c                	ld	a5,0(s1)
    80004f18:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f1c:	609c                	ld	a5,0(s1)
    80004f1e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f22:	609c                	ld	a5,0(s1)
    80004f24:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f28:	000a3783          	ld	a5,0(s4)
    80004f2c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f30:	000a3783          	ld	a5,0(s4)
    80004f34:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f38:	000a3783          	ld	a5,0(s4)
    80004f3c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f40:	000a3783          	ld	a5,0(s4)
    80004f44:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f48:	4501                	li	a0,0
    80004f4a:	a025                	j	80004f72 <pipealloc+0xc6>
  if(pi){
    //kfree((char*)pi);
  n_kfree((char *)pi);
  }

  if(*f0)
    80004f4c:	6088                	ld	a0,0(s1)
    80004f4e:	e501                	bnez	a0,80004f56 <pipealloc+0xaa>
    80004f50:	a039                	j	80004f5e <pipealloc+0xb2>
    80004f52:	6088                	ld	a0,0(s1)
    80004f54:	c51d                	beqz	a0,80004f82 <pipealloc+0xd6>
    fileclose(*f0);
    80004f56:	00000097          	auipc	ra,0x0
    80004f5a:	c26080e7          	jalr	-986(ra) # 80004b7c <fileclose>
  if(*f1)
    80004f5e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f62:	557d                	li	a0,-1
  if(*f1)
    80004f64:	c799                	beqz	a5,80004f72 <pipealloc+0xc6>
    fileclose(*f1);
    80004f66:	853e                	mv	a0,a5
    80004f68:	00000097          	auipc	ra,0x0
    80004f6c:	c14080e7          	jalr	-1004(ra) # 80004b7c <fileclose>
  return -1;
    80004f70:	557d                	li	a0,-1
}
    80004f72:	70a2                	ld	ra,40(sp)
    80004f74:	7402                	ld	s0,32(sp)
    80004f76:	64e2                	ld	s1,24(sp)
    80004f78:	6942                	ld	s2,16(sp)
    80004f7a:	69a2                	ld	s3,8(sp)
    80004f7c:	6a02                	ld	s4,0(sp)
    80004f7e:	6145                	addi	sp,sp,48
    80004f80:	8082                	ret
  return -1;
    80004f82:	557d                	li	a0,-1
    80004f84:	b7fd                	j	80004f72 <pipealloc+0xc6>

0000000080004f86 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f86:	1101                	addi	sp,sp,-32
    80004f88:	ec06                	sd	ra,24(sp)
    80004f8a:	e822                	sd	s0,16(sp)
    80004f8c:	e426                	sd	s1,8(sp)
    80004f8e:	e04a                	sd	s2,0(sp)
    80004f90:	1000                	addi	s0,sp,32
    80004f92:	84aa                	mv	s1,a0
    80004f94:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	dcc080e7          	jalr	-564(ra) # 80000d62 <acquire>
  if(writable){
    80004f9e:	02090d63          	beqz	s2,80004fd8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fa2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fa6:	21848513          	addi	a0,s1,536
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	492080e7          	jalr	1170(ra) # 8000243c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fb2:	2204b783          	ld	a5,544(s1)
    80004fb6:	eb95                	bnez	a5,80004fea <pipeclose+0x64>
    release(&pi->lock);
    80004fb8:	8526                	mv	a0,s1
    80004fba:	ffffc097          	auipc	ra,0xffffc
    80004fbe:	e5c080e7          	jalr	-420(ra) # 80000e16 <release>
    //kfree((char*)pi);
    n_kfree((char *)pi);
    80004fc2:	8526                	mv	a0,s1
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	c4a080e7          	jalr	-950(ra) # 80000c0e <n_kfree>
    } else
    release(&pi->lock);
}
    80004fcc:	60e2                	ld	ra,24(sp)
    80004fce:	6442                	ld	s0,16(sp)
    80004fd0:	64a2                	ld	s1,8(sp)
    80004fd2:	6902                	ld	s2,0(sp)
    80004fd4:	6105                	addi	sp,sp,32
    80004fd6:	8082                	ret
    pi->readopen = 0;
    80004fd8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fdc:	21c48513          	addi	a0,s1,540
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	45c080e7          	jalr	1116(ra) # 8000243c <wakeup>
    80004fe8:	b7e9                	j	80004fb2 <pipeclose+0x2c>
    release(&pi->lock);
    80004fea:	8526                	mv	a0,s1
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	e2a080e7          	jalr	-470(ra) # 80000e16 <release>
}
    80004ff4:	bfe1                	j	80004fcc <pipeclose+0x46>

0000000080004ff6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ff6:	711d                	addi	sp,sp,-96
    80004ff8:	ec86                	sd	ra,88(sp)
    80004ffa:	e8a2                	sd	s0,80(sp)
    80004ffc:	e4a6                	sd	s1,72(sp)
    80004ffe:	e0ca                	sd	s2,64(sp)
    80005000:	fc4e                	sd	s3,56(sp)
    80005002:	f852                	sd	s4,48(sp)
    80005004:	f456                	sd	s5,40(sp)
    80005006:	f05a                	sd	s6,32(sp)
    80005008:	ec5e                	sd	s7,24(sp)
    8000500a:	e862                	sd	s8,16(sp)
    8000500c:	1080                	addi	s0,sp,96
    8000500e:	84aa                	mv	s1,a0
    80005010:	8aae                	mv	s5,a1
    80005012:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005014:	ffffd097          	auipc	ra,0xffffd
    80005018:	c5c080e7          	jalr	-932(ra) # 80001c70 <myproc>
    8000501c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000501e:	8526                	mv	a0,s1
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	d42080e7          	jalr	-702(ra) # 80000d62 <acquire>
  while(i < n){
    80005028:	0b405663          	blez	s4,800050d4 <pipewrite+0xde>
  int i = 0;
    8000502c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000502e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005030:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005034:	21c48b93          	addi	s7,s1,540
    80005038:	a089                	j	8000507a <pipewrite+0x84>
      release(&pi->lock);
    8000503a:	8526                	mv	a0,s1
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	dda080e7          	jalr	-550(ra) # 80000e16 <release>
      return -1;
    80005044:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005046:	854a                	mv	a0,s2
    80005048:	60e6                	ld	ra,88(sp)
    8000504a:	6446                	ld	s0,80(sp)
    8000504c:	64a6                	ld	s1,72(sp)
    8000504e:	6906                	ld	s2,64(sp)
    80005050:	79e2                	ld	s3,56(sp)
    80005052:	7a42                	ld	s4,48(sp)
    80005054:	7aa2                	ld	s5,40(sp)
    80005056:	7b02                	ld	s6,32(sp)
    80005058:	6be2                	ld	s7,24(sp)
    8000505a:	6c42                	ld	s8,16(sp)
    8000505c:	6125                	addi	sp,sp,96
    8000505e:	8082                	ret
      wakeup(&pi->nread);
    80005060:	8562                	mv	a0,s8
    80005062:	ffffd097          	auipc	ra,0xffffd
    80005066:	3da080e7          	jalr	986(ra) # 8000243c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000506a:	85a6                	mv	a1,s1
    8000506c:	855e                	mv	a0,s7
    8000506e:	ffffd097          	auipc	ra,0xffffd
    80005072:	36a080e7          	jalr	874(ra) # 800023d8 <sleep>
  while(i < n){
    80005076:	07495063          	bge	s2,s4,800050d6 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000507a:	2204a783          	lw	a5,544(s1)
    8000507e:	dfd5                	beqz	a5,8000503a <pipewrite+0x44>
    80005080:	854e                	mv	a0,s3
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	5fe080e7          	jalr	1534(ra) # 80002680 <killed>
    8000508a:	f945                	bnez	a0,8000503a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000508c:	2184a783          	lw	a5,536(s1)
    80005090:	21c4a703          	lw	a4,540(s1)
    80005094:	2007879b          	addiw	a5,a5,512
    80005098:	fcf704e3          	beq	a4,a5,80005060 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000509c:	4685                	li	a3,1
    8000509e:	01590633          	add	a2,s2,s5
    800050a2:	faf40593          	addi	a1,s0,-81
    800050a6:	0509b503          	ld	a0,80(s3)
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	814080e7          	jalr	-2028(ra) # 800018be <copyin>
    800050b2:	03650263          	beq	a0,s6,800050d6 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050b6:	21c4a783          	lw	a5,540(s1)
    800050ba:	0017871b          	addiw	a4,a5,1
    800050be:	20e4ae23          	sw	a4,540(s1)
    800050c2:	1ff7f793          	andi	a5,a5,511
    800050c6:	97a6                	add	a5,a5,s1
    800050c8:	faf44703          	lbu	a4,-81(s0)
    800050cc:	00e78c23          	sb	a4,24(a5)
      i++;
    800050d0:	2905                	addiw	s2,s2,1
    800050d2:	b755                	j	80005076 <pipewrite+0x80>
  int i = 0;
    800050d4:	4901                	li	s2,0
  wakeup(&pi->nread);
    800050d6:	21848513          	addi	a0,s1,536
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	362080e7          	jalr	866(ra) # 8000243c <wakeup>
  release(&pi->lock);
    800050e2:	8526                	mv	a0,s1
    800050e4:	ffffc097          	auipc	ra,0xffffc
    800050e8:	d32080e7          	jalr	-718(ra) # 80000e16 <release>
  return i;
    800050ec:	bfa9                	j	80005046 <pipewrite+0x50>

00000000800050ee <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050ee:	715d                	addi	sp,sp,-80
    800050f0:	e486                	sd	ra,72(sp)
    800050f2:	e0a2                	sd	s0,64(sp)
    800050f4:	fc26                	sd	s1,56(sp)
    800050f6:	f84a                	sd	s2,48(sp)
    800050f8:	f44e                	sd	s3,40(sp)
    800050fa:	f052                	sd	s4,32(sp)
    800050fc:	ec56                	sd	s5,24(sp)
    800050fe:	e85a                	sd	s6,16(sp)
    80005100:	0880                	addi	s0,sp,80
    80005102:	84aa                	mv	s1,a0
    80005104:	892e                	mv	s2,a1
    80005106:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005108:	ffffd097          	auipc	ra,0xffffd
    8000510c:	b68080e7          	jalr	-1176(ra) # 80001c70 <myproc>
    80005110:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005112:	8526                	mv	a0,s1
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	c4e080e7          	jalr	-946(ra) # 80000d62 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000511c:	2184a703          	lw	a4,536(s1)
    80005120:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005124:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005128:	02f71763          	bne	a4,a5,80005156 <piperead+0x68>
    8000512c:	2244a783          	lw	a5,548(s1)
    80005130:	c39d                	beqz	a5,80005156 <piperead+0x68>
    if(killed(pr)){
    80005132:	8552                	mv	a0,s4
    80005134:	ffffd097          	auipc	ra,0xffffd
    80005138:	54c080e7          	jalr	1356(ra) # 80002680 <killed>
    8000513c:	e949                	bnez	a0,800051ce <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000513e:	85a6                	mv	a1,s1
    80005140:	854e                	mv	a0,s3
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	296080e7          	jalr	662(ra) # 800023d8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000514a:	2184a703          	lw	a4,536(s1)
    8000514e:	21c4a783          	lw	a5,540(s1)
    80005152:	fcf70de3          	beq	a4,a5,8000512c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005156:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005158:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000515a:	05505463          	blez	s5,800051a2 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000515e:	2184a783          	lw	a5,536(s1)
    80005162:	21c4a703          	lw	a4,540(s1)
    80005166:	02f70e63          	beq	a4,a5,800051a2 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000516a:	0017871b          	addiw	a4,a5,1
    8000516e:	20e4ac23          	sw	a4,536(s1)
    80005172:	1ff7f793          	andi	a5,a5,511
    80005176:	97a6                	add	a5,a5,s1
    80005178:	0187c783          	lbu	a5,24(a5)
    8000517c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005180:	4685                	li	a3,1
    80005182:	fbf40613          	addi	a2,s0,-65
    80005186:	85ca                	mv	a1,s2
    80005188:	050a3503          	ld	a0,80(s4)
    8000518c:	ffffc097          	auipc	ra,0xffffc
    80005190:	6a6080e7          	jalr	1702(ra) # 80001832 <copyout>
    80005194:	01650763          	beq	a0,s6,800051a2 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005198:	2985                	addiw	s3,s3,1
    8000519a:	0905                	addi	s2,s2,1
    8000519c:	fd3a91e3          	bne	s5,s3,8000515e <piperead+0x70>
    800051a0:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051a2:	21c48513          	addi	a0,s1,540
    800051a6:	ffffd097          	auipc	ra,0xffffd
    800051aa:	296080e7          	jalr	662(ra) # 8000243c <wakeup>
  release(&pi->lock);
    800051ae:	8526                	mv	a0,s1
    800051b0:	ffffc097          	auipc	ra,0xffffc
    800051b4:	c66080e7          	jalr	-922(ra) # 80000e16 <release>
  return i;
}
    800051b8:	854e                	mv	a0,s3
    800051ba:	60a6                	ld	ra,72(sp)
    800051bc:	6406                	ld	s0,64(sp)
    800051be:	74e2                	ld	s1,56(sp)
    800051c0:	7942                	ld	s2,48(sp)
    800051c2:	79a2                	ld	s3,40(sp)
    800051c4:	7a02                	ld	s4,32(sp)
    800051c6:	6ae2                	ld	s5,24(sp)
    800051c8:	6b42                	ld	s6,16(sp)
    800051ca:	6161                	addi	sp,sp,80
    800051cc:	8082                	ret
      release(&pi->lock);
    800051ce:	8526                	mv	a0,s1
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	c46080e7          	jalr	-954(ra) # 80000e16 <release>
      return -1;
    800051d8:	59fd                	li	s3,-1
    800051da:	bff9                	j	800051b8 <piperead+0xca>

00000000800051dc <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800051dc:	1141                	addi	sp,sp,-16
    800051de:	e422                	sd	s0,8(sp)
    800051e0:	0800                	addi	s0,sp,16
    800051e2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800051e4:	8905                	andi	a0,a0,1
    800051e6:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800051e8:	8b89                	andi	a5,a5,2
    800051ea:	c399                	beqz	a5,800051f0 <flags2perm+0x14>
      perm |= PTE_W;
    800051ec:	00456513          	ori	a0,a0,4
    return perm;
}
    800051f0:	6422                	ld	s0,8(sp)
    800051f2:	0141                	addi	sp,sp,16
    800051f4:	8082                	ret

00000000800051f6 <exec>:

int
exec(char *path, char **argv)
{
    800051f6:	de010113          	addi	sp,sp,-544
    800051fa:	20113c23          	sd	ra,536(sp)
    800051fe:	20813823          	sd	s0,528(sp)
    80005202:	20913423          	sd	s1,520(sp)
    80005206:	21213023          	sd	s2,512(sp)
    8000520a:	ffce                	sd	s3,504(sp)
    8000520c:	fbd2                	sd	s4,496(sp)
    8000520e:	f7d6                	sd	s5,488(sp)
    80005210:	f3da                	sd	s6,480(sp)
    80005212:	efde                	sd	s7,472(sp)
    80005214:	ebe2                	sd	s8,464(sp)
    80005216:	e7e6                	sd	s9,456(sp)
    80005218:	e3ea                	sd	s10,448(sp)
    8000521a:	ff6e                	sd	s11,440(sp)
    8000521c:	1400                	addi	s0,sp,544
    8000521e:	892a                	mv	s2,a0
    80005220:	dea43423          	sd	a0,-536(s0)
    80005224:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005228:	ffffd097          	auipc	ra,0xffffd
    8000522c:	a48080e7          	jalr	-1464(ra) # 80001c70 <myproc>
    80005230:	84aa                	mv	s1,a0

  begin_op();
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	482080e7          	jalr	1154(ra) # 800046b4 <begin_op>

  if((ip = namei(path)) == 0){
    8000523a:	854a                	mv	a0,s2
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	258080e7          	jalr	600(ra) # 80004494 <namei>
    80005244:	c93d                	beqz	a0,800052ba <exec+0xc4>
    80005246:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	aa0080e7          	jalr	-1376(ra) # 80003ce8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005250:	04000713          	li	a4,64
    80005254:	4681                	li	a3,0
    80005256:	e5040613          	addi	a2,s0,-432
    8000525a:	4581                	li	a1,0
    8000525c:	8556                	mv	a0,s5
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	d3e080e7          	jalr	-706(ra) # 80003f9c <readi>
    80005266:	04000793          	li	a5,64
    8000526a:	00f51a63          	bne	a0,a5,8000527e <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000526e:	e5042703          	lw	a4,-432(s0)
    80005272:	464c47b7          	lui	a5,0x464c4
    80005276:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000527a:	04f70663          	beq	a4,a5,800052c6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000527e:	8556                	mv	a0,s5
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	cca080e7          	jalr	-822(ra) # 80003f4a <iunlockput>
    end_op();
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	4aa080e7          	jalr	1194(ra) # 80004732 <end_op>
  }
  return -1;
    80005290:	557d                	li	a0,-1
}
    80005292:	21813083          	ld	ra,536(sp)
    80005296:	21013403          	ld	s0,528(sp)
    8000529a:	20813483          	ld	s1,520(sp)
    8000529e:	20013903          	ld	s2,512(sp)
    800052a2:	79fe                	ld	s3,504(sp)
    800052a4:	7a5e                	ld	s4,496(sp)
    800052a6:	7abe                	ld	s5,488(sp)
    800052a8:	7b1e                	ld	s6,480(sp)
    800052aa:	6bfe                	ld	s7,472(sp)
    800052ac:	6c5e                	ld	s8,464(sp)
    800052ae:	6cbe                	ld	s9,456(sp)
    800052b0:	6d1e                	ld	s10,448(sp)
    800052b2:	7dfa                	ld	s11,440(sp)
    800052b4:	22010113          	addi	sp,sp,544
    800052b8:	8082                	ret
    end_op();
    800052ba:	fffff097          	auipc	ra,0xfffff
    800052be:	478080e7          	jalr	1144(ra) # 80004732 <end_op>
    return -1;
    800052c2:	557d                	li	a0,-1
    800052c4:	b7f9                	j	80005292 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800052c6:	8526                	mv	a0,s1
    800052c8:	ffffd097          	auipc	ra,0xffffd
    800052cc:	a6c080e7          	jalr	-1428(ra) # 80001d34 <proc_pagetable>
    800052d0:	8b2a                	mv	s6,a0
    800052d2:	d555                	beqz	a0,8000527e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052d4:	e7042783          	lw	a5,-400(s0)
    800052d8:	e8845703          	lhu	a4,-376(s0)
    800052dc:	c735                	beqz	a4,80005348 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052de:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052e0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800052e4:	6a05                	lui	s4,0x1
    800052e6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800052ea:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800052ee:	6d85                	lui	s11,0x1
    800052f0:	7d7d                	lui	s10,0xfffff
    800052f2:	ac3d                	j	80005530 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052f4:	00003517          	auipc	a0,0x3
    800052f8:	54450513          	addi	a0,a0,1348 # 80008838 <syscalls+0x2a8>
    800052fc:	ffffb097          	auipc	ra,0xffffb
    80005300:	244080e7          	jalr	580(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005304:	874a                	mv	a4,s2
    80005306:	009c86bb          	addw	a3,s9,s1
    8000530a:	4581                	li	a1,0
    8000530c:	8556                	mv	a0,s5
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	c8e080e7          	jalr	-882(ra) # 80003f9c <readi>
    80005316:	2501                	sext.w	a0,a0
    80005318:	1aa91963          	bne	s2,a0,800054ca <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000531c:	009d84bb          	addw	s1,s11,s1
    80005320:	013d09bb          	addw	s3,s10,s3
    80005324:	1f74f663          	bgeu	s1,s7,80005510 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005328:	02049593          	slli	a1,s1,0x20
    8000532c:	9181                	srli	a1,a1,0x20
    8000532e:	95e2                	add	a1,a1,s8
    80005330:	855a                	mv	a0,s6
    80005332:	ffffc097          	auipc	ra,0xffffc
    80005336:	eb6080e7          	jalr	-330(ra) # 800011e8 <walkaddr>
    8000533a:	862a                	mv	a2,a0
    if(pa == 0)
    8000533c:	dd45                	beqz	a0,800052f4 <exec+0xfe>
      n = PGSIZE;
    8000533e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005340:	fd49f2e3          	bgeu	s3,s4,80005304 <exec+0x10e>
      n = sz - i;
    80005344:	894e                	mv	s2,s3
    80005346:	bf7d                	j	80005304 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005348:	4901                	li	s2,0
  iunlockput(ip);
    8000534a:	8556                	mv	a0,s5
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	bfe080e7          	jalr	-1026(ra) # 80003f4a <iunlockput>
  end_op();
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	3de080e7          	jalr	990(ra) # 80004732 <end_op>
  p = myproc();
    8000535c:	ffffd097          	auipc	ra,0xffffd
    80005360:	914080e7          	jalr	-1772(ra) # 80001c70 <myproc>
    80005364:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005366:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000536a:	6785                	lui	a5,0x1
    8000536c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000536e:	97ca                	add	a5,a5,s2
    80005370:	777d                	lui	a4,0xfffff
    80005372:	8ff9                	and	a5,a5,a4
    80005374:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005378:	4691                	li	a3,4
    8000537a:	6609                	lui	a2,0x2
    8000537c:	963e                	add	a2,a2,a5
    8000537e:	85be                	mv	a1,a5
    80005380:	855a                	mv	a0,s6
    80005382:	ffffc097          	auipc	ra,0xffffc
    80005386:	248080e7          	jalr	584(ra) # 800015ca <uvmalloc>
    8000538a:	8c2a                	mv	s8,a0
  ip = 0;
    8000538c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000538e:	12050e63          	beqz	a0,800054ca <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005392:	75f9                	lui	a1,0xffffe
    80005394:	95aa                	add	a1,a1,a0
    80005396:	855a                	mv	a0,s6
    80005398:	ffffc097          	auipc	ra,0xffffc
    8000539c:	468080e7          	jalr	1128(ra) # 80001800 <uvmclear>
  stackbase = sp - PGSIZE;
    800053a0:	7afd                	lui	s5,0xfffff
    800053a2:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800053a4:	df043783          	ld	a5,-528(s0)
    800053a8:	6388                	ld	a0,0(a5)
    800053aa:	c925                	beqz	a0,8000541a <exec+0x224>
    800053ac:	e9040993          	addi	s3,s0,-368
    800053b0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053b4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053b6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800053b8:	ffffc097          	auipc	ra,0xffffc
    800053bc:	c22080e7          	jalr	-990(ra) # 80000fda <strlen>
    800053c0:	0015079b          	addiw	a5,a0,1
    800053c4:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053c8:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800053cc:	13596663          	bltu	s2,s5,800054f8 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053d0:	df043d83          	ld	s11,-528(s0)
    800053d4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800053d8:	8552                	mv	a0,s4
    800053da:	ffffc097          	auipc	ra,0xffffc
    800053de:	c00080e7          	jalr	-1024(ra) # 80000fda <strlen>
    800053e2:	0015069b          	addiw	a3,a0,1
    800053e6:	8652                	mv	a2,s4
    800053e8:	85ca                	mv	a1,s2
    800053ea:	855a                	mv	a0,s6
    800053ec:	ffffc097          	auipc	ra,0xffffc
    800053f0:	446080e7          	jalr	1094(ra) # 80001832 <copyout>
    800053f4:	10054663          	bltz	a0,80005500 <exec+0x30a>
    ustack[argc] = sp;
    800053f8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053fc:	0485                	addi	s1,s1,1
    800053fe:	008d8793          	addi	a5,s11,8
    80005402:	def43823          	sd	a5,-528(s0)
    80005406:	008db503          	ld	a0,8(s11)
    8000540a:	c911                	beqz	a0,8000541e <exec+0x228>
    if(argc >= MAXARG)
    8000540c:	09a1                	addi	s3,s3,8
    8000540e:	fb3c95e3          	bne	s9,s3,800053b8 <exec+0x1c2>
  sz = sz1;
    80005412:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005416:	4a81                	li	s5,0
    80005418:	a84d                	j	800054ca <exec+0x2d4>
  sp = sz;
    8000541a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000541c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000541e:	00349793          	slli	a5,s1,0x3
    80005422:	f9078793          	addi	a5,a5,-112
    80005426:	97a2                	add	a5,a5,s0
    80005428:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000542c:	00148693          	addi	a3,s1,1
    80005430:	068e                	slli	a3,a3,0x3
    80005432:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005436:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000543a:	01597663          	bgeu	s2,s5,80005446 <exec+0x250>
  sz = sz1;
    8000543e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005442:	4a81                	li	s5,0
    80005444:	a059                	j	800054ca <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005446:	e9040613          	addi	a2,s0,-368
    8000544a:	85ca                	mv	a1,s2
    8000544c:	855a                	mv	a0,s6
    8000544e:	ffffc097          	auipc	ra,0xffffc
    80005452:	3e4080e7          	jalr	996(ra) # 80001832 <copyout>
    80005456:	0a054963          	bltz	a0,80005508 <exec+0x312>
  p->trapframe->a1 = sp;
    8000545a:	058bb783          	ld	a5,88(s7)
    8000545e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005462:	de843783          	ld	a5,-536(s0)
    80005466:	0007c703          	lbu	a4,0(a5)
    8000546a:	cf11                	beqz	a4,80005486 <exec+0x290>
    8000546c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000546e:	02f00693          	li	a3,47
    80005472:	a039                	j	80005480 <exec+0x28a>
      last = s+1;
    80005474:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005478:	0785                	addi	a5,a5,1
    8000547a:	fff7c703          	lbu	a4,-1(a5)
    8000547e:	c701                	beqz	a4,80005486 <exec+0x290>
    if(*s == '/')
    80005480:	fed71ce3          	bne	a4,a3,80005478 <exec+0x282>
    80005484:	bfc5                	j	80005474 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005486:	4641                	li	a2,16
    80005488:	de843583          	ld	a1,-536(s0)
    8000548c:	158b8513          	addi	a0,s7,344
    80005490:	ffffc097          	auipc	ra,0xffffc
    80005494:	b18080e7          	jalr	-1256(ra) # 80000fa8 <safestrcpy>
  oldpagetable = p->pagetable;
    80005498:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000549c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800054a0:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054a4:	058bb783          	ld	a5,88(s7)
    800054a8:	e6843703          	ld	a4,-408(s0)
    800054ac:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054ae:	058bb783          	ld	a5,88(s7)
    800054b2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054b6:	85ea                	mv	a1,s10
    800054b8:	ffffd097          	auipc	ra,0xffffd
    800054bc:	918080e7          	jalr	-1768(ra) # 80001dd0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054c0:	0004851b          	sext.w	a0,s1
    800054c4:	b3f9                	j	80005292 <exec+0x9c>
    800054c6:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800054ca:	df843583          	ld	a1,-520(s0)
    800054ce:	855a                	mv	a0,s6
    800054d0:	ffffd097          	auipc	ra,0xffffd
    800054d4:	900080e7          	jalr	-1792(ra) # 80001dd0 <proc_freepagetable>
  if(ip){
    800054d8:	da0a93e3          	bnez	s5,8000527e <exec+0x88>
  return -1;
    800054dc:	557d                	li	a0,-1
    800054de:	bb55                	j	80005292 <exec+0x9c>
    800054e0:	df243c23          	sd	s2,-520(s0)
    800054e4:	b7dd                	j	800054ca <exec+0x2d4>
    800054e6:	df243c23          	sd	s2,-520(s0)
    800054ea:	b7c5                	j	800054ca <exec+0x2d4>
    800054ec:	df243c23          	sd	s2,-520(s0)
    800054f0:	bfe9                	j	800054ca <exec+0x2d4>
    800054f2:	df243c23          	sd	s2,-520(s0)
    800054f6:	bfd1                	j	800054ca <exec+0x2d4>
  sz = sz1;
    800054f8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054fc:	4a81                	li	s5,0
    800054fe:	b7f1                	j	800054ca <exec+0x2d4>
  sz = sz1;
    80005500:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005504:	4a81                	li	s5,0
    80005506:	b7d1                	j	800054ca <exec+0x2d4>
  sz = sz1;
    80005508:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000550c:	4a81                	li	s5,0
    8000550e:	bf75                	j	800054ca <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005510:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005514:	e0843783          	ld	a5,-504(s0)
    80005518:	0017869b          	addiw	a3,a5,1
    8000551c:	e0d43423          	sd	a3,-504(s0)
    80005520:	e0043783          	ld	a5,-512(s0)
    80005524:	0387879b          	addiw	a5,a5,56
    80005528:	e8845703          	lhu	a4,-376(s0)
    8000552c:	e0e6dfe3          	bge	a3,a4,8000534a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005530:	2781                	sext.w	a5,a5
    80005532:	e0f43023          	sd	a5,-512(s0)
    80005536:	03800713          	li	a4,56
    8000553a:	86be                	mv	a3,a5
    8000553c:	e1840613          	addi	a2,s0,-488
    80005540:	4581                	li	a1,0
    80005542:	8556                	mv	a0,s5
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	a58080e7          	jalr	-1448(ra) # 80003f9c <readi>
    8000554c:	03800793          	li	a5,56
    80005550:	f6f51be3          	bne	a0,a5,800054c6 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005554:	e1842783          	lw	a5,-488(s0)
    80005558:	4705                	li	a4,1
    8000555a:	fae79de3          	bne	a5,a4,80005514 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000555e:	e4043483          	ld	s1,-448(s0)
    80005562:	e3843783          	ld	a5,-456(s0)
    80005566:	f6f4ede3          	bltu	s1,a5,800054e0 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000556a:	e2843783          	ld	a5,-472(s0)
    8000556e:	94be                	add	s1,s1,a5
    80005570:	f6f4ebe3          	bltu	s1,a5,800054e6 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005574:	de043703          	ld	a4,-544(s0)
    80005578:	8ff9                	and	a5,a5,a4
    8000557a:	fbad                	bnez	a5,800054ec <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000557c:	e1c42503          	lw	a0,-484(s0)
    80005580:	00000097          	auipc	ra,0x0
    80005584:	c5c080e7          	jalr	-932(ra) # 800051dc <flags2perm>
    80005588:	86aa                	mv	a3,a0
    8000558a:	8626                	mv	a2,s1
    8000558c:	85ca                	mv	a1,s2
    8000558e:	855a                	mv	a0,s6
    80005590:	ffffc097          	auipc	ra,0xffffc
    80005594:	03a080e7          	jalr	58(ra) # 800015ca <uvmalloc>
    80005598:	dea43c23          	sd	a0,-520(s0)
    8000559c:	d939                	beqz	a0,800054f2 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000559e:	e2843c03          	ld	s8,-472(s0)
    800055a2:	e2042c83          	lw	s9,-480(s0)
    800055a6:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055aa:	f60b83e3          	beqz	s7,80005510 <exec+0x31a>
    800055ae:	89de                	mv	s3,s7
    800055b0:	4481                	li	s1,0
    800055b2:	bb9d                	j	80005328 <exec+0x132>

00000000800055b4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055b4:	7179                	addi	sp,sp,-48
    800055b6:	f406                	sd	ra,40(sp)
    800055b8:	f022                	sd	s0,32(sp)
    800055ba:	ec26                	sd	s1,24(sp)
    800055bc:	e84a                	sd	s2,16(sp)
    800055be:	1800                	addi	s0,sp,48
    800055c0:	892e                	mv	s2,a1
    800055c2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055c4:	fdc40593          	addi	a1,s0,-36
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	a5e080e7          	jalr	-1442(ra) # 80003026 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055d0:	fdc42703          	lw	a4,-36(s0)
    800055d4:	47bd                	li	a5,15
    800055d6:	02e7eb63          	bltu	a5,a4,8000560c <argfd+0x58>
    800055da:	ffffc097          	auipc	ra,0xffffc
    800055de:	696080e7          	jalr	1686(ra) # 80001c70 <myproc>
    800055e2:	fdc42703          	lw	a4,-36(s0)
    800055e6:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffbd10a>
    800055ea:	078e                	slli	a5,a5,0x3
    800055ec:	953e                	add	a0,a0,a5
    800055ee:	611c                	ld	a5,0(a0)
    800055f0:	c385                	beqz	a5,80005610 <argfd+0x5c>
    return -1;
  if(pfd)
    800055f2:	00090463          	beqz	s2,800055fa <argfd+0x46>
    *pfd = fd;
    800055f6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055fa:	4501                	li	a0,0
  if(pf)
    800055fc:	c091                	beqz	s1,80005600 <argfd+0x4c>
    *pf = f;
    800055fe:	e09c                	sd	a5,0(s1)
}
    80005600:	70a2                	ld	ra,40(sp)
    80005602:	7402                	ld	s0,32(sp)
    80005604:	64e2                	ld	s1,24(sp)
    80005606:	6942                	ld	s2,16(sp)
    80005608:	6145                	addi	sp,sp,48
    8000560a:	8082                	ret
    return -1;
    8000560c:	557d                	li	a0,-1
    8000560e:	bfcd                	j	80005600 <argfd+0x4c>
    80005610:	557d                	li	a0,-1
    80005612:	b7fd                	j	80005600 <argfd+0x4c>

0000000080005614 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005614:	1101                	addi	sp,sp,-32
    80005616:	ec06                	sd	ra,24(sp)
    80005618:	e822                	sd	s0,16(sp)
    8000561a:	e426                	sd	s1,8(sp)
    8000561c:	1000                	addi	s0,sp,32
    8000561e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005620:	ffffc097          	auipc	ra,0xffffc
    80005624:	650080e7          	jalr	1616(ra) # 80001c70 <myproc>
    80005628:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000562a:	0d050793          	addi	a5,a0,208
    8000562e:	4501                	li	a0,0
    80005630:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005632:	6398                	ld	a4,0(a5)
    80005634:	cb19                	beqz	a4,8000564a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005636:	2505                	addiw	a0,a0,1
    80005638:	07a1                	addi	a5,a5,8
    8000563a:	fed51ce3          	bne	a0,a3,80005632 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000563e:	557d                	li	a0,-1
}
    80005640:	60e2                	ld	ra,24(sp)
    80005642:	6442                	ld	s0,16(sp)
    80005644:	64a2                	ld	s1,8(sp)
    80005646:	6105                	addi	sp,sp,32
    80005648:	8082                	ret
      p->ofile[fd] = f;
    8000564a:	01a50793          	addi	a5,a0,26
    8000564e:	078e                	slli	a5,a5,0x3
    80005650:	963e                	add	a2,a2,a5
    80005652:	e204                	sd	s1,0(a2)
      return fd;
    80005654:	b7f5                	j	80005640 <fdalloc+0x2c>

0000000080005656 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005656:	715d                	addi	sp,sp,-80
    80005658:	e486                	sd	ra,72(sp)
    8000565a:	e0a2                	sd	s0,64(sp)
    8000565c:	fc26                	sd	s1,56(sp)
    8000565e:	f84a                	sd	s2,48(sp)
    80005660:	f44e                	sd	s3,40(sp)
    80005662:	f052                	sd	s4,32(sp)
    80005664:	ec56                	sd	s5,24(sp)
    80005666:	e85a                	sd	s6,16(sp)
    80005668:	0880                	addi	s0,sp,80
    8000566a:	8b2e                	mv	s6,a1
    8000566c:	89b2                	mv	s3,a2
    8000566e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005670:	fb040593          	addi	a1,s0,-80
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	e3e080e7          	jalr	-450(ra) # 800044b2 <nameiparent>
    8000567c:	84aa                	mv	s1,a0
    8000567e:	14050f63          	beqz	a0,800057dc <create+0x186>
    return 0;

  ilock(dp);
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	666080e7          	jalr	1638(ra) # 80003ce8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000568a:	4601                	li	a2,0
    8000568c:	fb040593          	addi	a1,s0,-80
    80005690:	8526                	mv	a0,s1
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	b3a080e7          	jalr	-1222(ra) # 800041cc <dirlookup>
    8000569a:	8aaa                	mv	s5,a0
    8000569c:	c931                	beqz	a0,800056f0 <create+0x9a>
    iunlockput(dp);
    8000569e:	8526                	mv	a0,s1
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	8aa080e7          	jalr	-1878(ra) # 80003f4a <iunlockput>
    ilock(ip);
    800056a8:	8556                	mv	a0,s5
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	63e080e7          	jalr	1598(ra) # 80003ce8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056b2:	000b059b          	sext.w	a1,s6
    800056b6:	4789                	li	a5,2
    800056b8:	02f59563          	bne	a1,a5,800056e2 <create+0x8c>
    800056bc:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffbd134>
    800056c0:	37f9                	addiw	a5,a5,-2
    800056c2:	17c2                	slli	a5,a5,0x30
    800056c4:	93c1                	srli	a5,a5,0x30
    800056c6:	4705                	li	a4,1
    800056c8:	00f76d63          	bltu	a4,a5,800056e2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800056cc:	8556                	mv	a0,s5
    800056ce:	60a6                	ld	ra,72(sp)
    800056d0:	6406                	ld	s0,64(sp)
    800056d2:	74e2                	ld	s1,56(sp)
    800056d4:	7942                	ld	s2,48(sp)
    800056d6:	79a2                	ld	s3,40(sp)
    800056d8:	7a02                	ld	s4,32(sp)
    800056da:	6ae2                	ld	s5,24(sp)
    800056dc:	6b42                	ld	s6,16(sp)
    800056de:	6161                	addi	sp,sp,80
    800056e0:	8082                	ret
    iunlockput(ip);
    800056e2:	8556                	mv	a0,s5
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	866080e7          	jalr	-1946(ra) # 80003f4a <iunlockput>
    return 0;
    800056ec:	4a81                	li	s5,0
    800056ee:	bff9                	j	800056cc <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800056f0:	85da                	mv	a1,s6
    800056f2:	4088                	lw	a0,0(s1)
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	456080e7          	jalr	1110(ra) # 80003b4a <ialloc>
    800056fc:	8a2a                	mv	s4,a0
    800056fe:	c539                	beqz	a0,8000574c <create+0xf6>
  ilock(ip);
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	5e8080e7          	jalr	1512(ra) # 80003ce8 <ilock>
  ip->major = major;
    80005708:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000570c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005710:	4905                	li	s2,1
    80005712:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005716:	8552                	mv	a0,s4
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	504080e7          	jalr	1284(ra) # 80003c1c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005720:	000b059b          	sext.w	a1,s6
    80005724:	03258b63          	beq	a1,s2,8000575a <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005728:	004a2603          	lw	a2,4(s4)
    8000572c:	fb040593          	addi	a1,s0,-80
    80005730:	8526                	mv	a0,s1
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	cb0080e7          	jalr	-848(ra) # 800043e2 <dirlink>
    8000573a:	06054f63          	bltz	a0,800057b8 <create+0x162>
  iunlockput(dp);
    8000573e:	8526                	mv	a0,s1
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	80a080e7          	jalr	-2038(ra) # 80003f4a <iunlockput>
  return ip;
    80005748:	8ad2                	mv	s5,s4
    8000574a:	b749                	j	800056cc <create+0x76>
    iunlockput(dp);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	7fc080e7          	jalr	2044(ra) # 80003f4a <iunlockput>
    return 0;
    80005756:	8ad2                	mv	s5,s4
    80005758:	bf95                	j	800056cc <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000575a:	004a2603          	lw	a2,4(s4)
    8000575e:	00003597          	auipc	a1,0x3
    80005762:	0fa58593          	addi	a1,a1,250 # 80008858 <syscalls+0x2c8>
    80005766:	8552                	mv	a0,s4
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	c7a080e7          	jalr	-902(ra) # 800043e2 <dirlink>
    80005770:	04054463          	bltz	a0,800057b8 <create+0x162>
    80005774:	40d0                	lw	a2,4(s1)
    80005776:	00003597          	auipc	a1,0x3
    8000577a:	0ea58593          	addi	a1,a1,234 # 80008860 <syscalls+0x2d0>
    8000577e:	8552                	mv	a0,s4
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	c62080e7          	jalr	-926(ra) # 800043e2 <dirlink>
    80005788:	02054863          	bltz	a0,800057b8 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000578c:	004a2603          	lw	a2,4(s4)
    80005790:	fb040593          	addi	a1,s0,-80
    80005794:	8526                	mv	a0,s1
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	c4c080e7          	jalr	-948(ra) # 800043e2 <dirlink>
    8000579e:	00054d63          	bltz	a0,800057b8 <create+0x162>
    dp->nlink++;  // for ".."
    800057a2:	04a4d783          	lhu	a5,74(s1)
    800057a6:	2785                	addiw	a5,a5,1
    800057a8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	46e080e7          	jalr	1134(ra) # 80003c1c <iupdate>
    800057b6:	b761                	j	8000573e <create+0xe8>
  ip->nlink = 0;
    800057b8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057bc:	8552                	mv	a0,s4
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	45e080e7          	jalr	1118(ra) # 80003c1c <iupdate>
  iunlockput(ip);
    800057c6:	8552                	mv	a0,s4
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	782080e7          	jalr	1922(ra) # 80003f4a <iunlockput>
  iunlockput(dp);
    800057d0:	8526                	mv	a0,s1
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	778080e7          	jalr	1912(ra) # 80003f4a <iunlockput>
  return 0;
    800057da:	bdcd                	j	800056cc <create+0x76>
    return 0;
    800057dc:	8aaa                	mv	s5,a0
    800057de:	b5fd                	j	800056cc <create+0x76>

00000000800057e0 <sys_dup>:
{
    800057e0:	7179                	addi	sp,sp,-48
    800057e2:	f406                	sd	ra,40(sp)
    800057e4:	f022                	sd	s0,32(sp)
    800057e6:	ec26                	sd	s1,24(sp)
    800057e8:	e84a                	sd	s2,16(sp)
    800057ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057ec:	fd840613          	addi	a2,s0,-40
    800057f0:	4581                	li	a1,0
    800057f2:	4501                	li	a0,0
    800057f4:	00000097          	auipc	ra,0x0
    800057f8:	dc0080e7          	jalr	-576(ra) # 800055b4 <argfd>
    return -1;
    800057fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057fe:	02054363          	bltz	a0,80005824 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005802:	fd843903          	ld	s2,-40(s0)
    80005806:	854a                	mv	a0,s2
    80005808:	00000097          	auipc	ra,0x0
    8000580c:	e0c080e7          	jalr	-500(ra) # 80005614 <fdalloc>
    80005810:	84aa                	mv	s1,a0
    return -1;
    80005812:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005814:	00054863          	bltz	a0,80005824 <sys_dup+0x44>
  filedup(f);
    80005818:	854a                	mv	a0,s2
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	310080e7          	jalr	784(ra) # 80004b2a <filedup>
  return fd;
    80005822:	87a6                	mv	a5,s1
}
    80005824:	853e                	mv	a0,a5
    80005826:	70a2                	ld	ra,40(sp)
    80005828:	7402                	ld	s0,32(sp)
    8000582a:	64e2                	ld	s1,24(sp)
    8000582c:	6942                	ld	s2,16(sp)
    8000582e:	6145                	addi	sp,sp,48
    80005830:	8082                	ret

0000000080005832 <sys_read>:
{
    80005832:	7179                	addi	sp,sp,-48
    80005834:	f406                	sd	ra,40(sp)
    80005836:	f022                	sd	s0,32(sp)
    80005838:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000583a:	fd840593          	addi	a1,s0,-40
    8000583e:	4505                	li	a0,1
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	806080e7          	jalr	-2042(ra) # 80003046 <argaddr>
  argint(2, &n);
    80005848:	fe440593          	addi	a1,s0,-28
    8000584c:	4509                	li	a0,2
    8000584e:	ffffd097          	auipc	ra,0xffffd
    80005852:	7d8080e7          	jalr	2008(ra) # 80003026 <argint>
  if(argfd(0, 0, &f) < 0)
    80005856:	fe840613          	addi	a2,s0,-24
    8000585a:	4581                	li	a1,0
    8000585c:	4501                	li	a0,0
    8000585e:	00000097          	auipc	ra,0x0
    80005862:	d56080e7          	jalr	-682(ra) # 800055b4 <argfd>
    80005866:	87aa                	mv	a5,a0
    return -1;
    80005868:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000586a:	0007cc63          	bltz	a5,80005882 <sys_read+0x50>
  return fileread(f, p, n);
    8000586e:	fe442603          	lw	a2,-28(s0)
    80005872:	fd843583          	ld	a1,-40(s0)
    80005876:	fe843503          	ld	a0,-24(s0)
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	43c080e7          	jalr	1084(ra) # 80004cb6 <fileread>
}
    80005882:	70a2                	ld	ra,40(sp)
    80005884:	7402                	ld	s0,32(sp)
    80005886:	6145                	addi	sp,sp,48
    80005888:	8082                	ret

000000008000588a <sys_write>:
{
    8000588a:	7179                	addi	sp,sp,-48
    8000588c:	f406                	sd	ra,40(sp)
    8000588e:	f022                	sd	s0,32(sp)
    80005890:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005892:	fd840593          	addi	a1,s0,-40
    80005896:	4505                	li	a0,1
    80005898:	ffffd097          	auipc	ra,0xffffd
    8000589c:	7ae080e7          	jalr	1966(ra) # 80003046 <argaddr>
  argint(2, &n);
    800058a0:	fe440593          	addi	a1,s0,-28
    800058a4:	4509                	li	a0,2
    800058a6:	ffffd097          	auipc	ra,0xffffd
    800058aa:	780080e7          	jalr	1920(ra) # 80003026 <argint>
  if(argfd(0, 0, &f) < 0)
    800058ae:	fe840613          	addi	a2,s0,-24
    800058b2:	4581                	li	a1,0
    800058b4:	4501                	li	a0,0
    800058b6:	00000097          	auipc	ra,0x0
    800058ba:	cfe080e7          	jalr	-770(ra) # 800055b4 <argfd>
    800058be:	87aa                	mv	a5,a0
    return -1;
    800058c0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058c2:	0007cc63          	bltz	a5,800058da <sys_write+0x50>
  return filewrite(f, p, n);
    800058c6:	fe442603          	lw	a2,-28(s0)
    800058ca:	fd843583          	ld	a1,-40(s0)
    800058ce:	fe843503          	ld	a0,-24(s0)
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	4a6080e7          	jalr	1190(ra) # 80004d78 <filewrite>
}
    800058da:	70a2                	ld	ra,40(sp)
    800058dc:	7402                	ld	s0,32(sp)
    800058de:	6145                	addi	sp,sp,48
    800058e0:	8082                	ret

00000000800058e2 <sys_close>:
{
    800058e2:	1101                	addi	sp,sp,-32
    800058e4:	ec06                	sd	ra,24(sp)
    800058e6:	e822                	sd	s0,16(sp)
    800058e8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058ea:	fe040613          	addi	a2,s0,-32
    800058ee:	fec40593          	addi	a1,s0,-20
    800058f2:	4501                	li	a0,0
    800058f4:	00000097          	auipc	ra,0x0
    800058f8:	cc0080e7          	jalr	-832(ra) # 800055b4 <argfd>
    return -1;
    800058fc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058fe:	02054463          	bltz	a0,80005926 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005902:	ffffc097          	auipc	ra,0xffffc
    80005906:	36e080e7          	jalr	878(ra) # 80001c70 <myproc>
    8000590a:	fec42783          	lw	a5,-20(s0)
    8000590e:	07e9                	addi	a5,a5,26
    80005910:	078e                	slli	a5,a5,0x3
    80005912:	953e                	add	a0,a0,a5
    80005914:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005918:	fe043503          	ld	a0,-32(s0)
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	260080e7          	jalr	608(ra) # 80004b7c <fileclose>
  return 0;
    80005924:	4781                	li	a5,0
}
    80005926:	853e                	mv	a0,a5
    80005928:	60e2                	ld	ra,24(sp)
    8000592a:	6442                	ld	s0,16(sp)
    8000592c:	6105                	addi	sp,sp,32
    8000592e:	8082                	ret

0000000080005930 <sys_fstat>:
{
    80005930:	1101                	addi	sp,sp,-32
    80005932:	ec06                	sd	ra,24(sp)
    80005934:	e822                	sd	s0,16(sp)
    80005936:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005938:	fe040593          	addi	a1,s0,-32
    8000593c:	4505                	li	a0,1
    8000593e:	ffffd097          	auipc	ra,0xffffd
    80005942:	708080e7          	jalr	1800(ra) # 80003046 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005946:	fe840613          	addi	a2,s0,-24
    8000594a:	4581                	li	a1,0
    8000594c:	4501                	li	a0,0
    8000594e:	00000097          	auipc	ra,0x0
    80005952:	c66080e7          	jalr	-922(ra) # 800055b4 <argfd>
    80005956:	87aa                	mv	a5,a0
    return -1;
    80005958:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000595a:	0007ca63          	bltz	a5,8000596e <sys_fstat+0x3e>
  return filestat(f, st);
    8000595e:	fe043583          	ld	a1,-32(s0)
    80005962:	fe843503          	ld	a0,-24(s0)
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	2de080e7          	jalr	734(ra) # 80004c44 <filestat>
}
    8000596e:	60e2                	ld	ra,24(sp)
    80005970:	6442                	ld	s0,16(sp)
    80005972:	6105                	addi	sp,sp,32
    80005974:	8082                	ret

0000000080005976 <sys_link>:
{
    80005976:	7169                	addi	sp,sp,-304
    80005978:	f606                	sd	ra,296(sp)
    8000597a:	f222                	sd	s0,288(sp)
    8000597c:	ee26                	sd	s1,280(sp)
    8000597e:	ea4a                	sd	s2,272(sp)
    80005980:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005982:	08000613          	li	a2,128
    80005986:	ed040593          	addi	a1,s0,-304
    8000598a:	4501                	li	a0,0
    8000598c:	ffffd097          	auipc	ra,0xffffd
    80005990:	6da080e7          	jalr	1754(ra) # 80003066 <argstr>
    return -1;
    80005994:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005996:	10054e63          	bltz	a0,80005ab2 <sys_link+0x13c>
    8000599a:	08000613          	li	a2,128
    8000599e:	f5040593          	addi	a1,s0,-176
    800059a2:	4505                	li	a0,1
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	6c2080e7          	jalr	1730(ra) # 80003066 <argstr>
    return -1;
    800059ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059ae:	10054263          	bltz	a0,80005ab2 <sys_link+0x13c>
  begin_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	d02080e7          	jalr	-766(ra) # 800046b4 <begin_op>
  if((ip = namei(old)) == 0){
    800059ba:	ed040513          	addi	a0,s0,-304
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	ad6080e7          	jalr	-1322(ra) # 80004494 <namei>
    800059c6:	84aa                	mv	s1,a0
    800059c8:	c551                	beqz	a0,80005a54 <sys_link+0xde>
  ilock(ip);
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	31e080e7          	jalr	798(ra) # 80003ce8 <ilock>
  if(ip->type == T_DIR){
    800059d2:	04449703          	lh	a4,68(s1)
    800059d6:	4785                	li	a5,1
    800059d8:	08f70463          	beq	a4,a5,80005a60 <sys_link+0xea>
  ip->nlink++;
    800059dc:	04a4d783          	lhu	a5,74(s1)
    800059e0:	2785                	addiw	a5,a5,1
    800059e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059e6:	8526                	mv	a0,s1
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	234080e7          	jalr	564(ra) # 80003c1c <iupdate>
  iunlock(ip);
    800059f0:	8526                	mv	a0,s1
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	3b8080e7          	jalr	952(ra) # 80003daa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059fa:	fd040593          	addi	a1,s0,-48
    800059fe:	f5040513          	addi	a0,s0,-176
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	ab0080e7          	jalr	-1360(ra) # 800044b2 <nameiparent>
    80005a0a:	892a                	mv	s2,a0
    80005a0c:	c935                	beqz	a0,80005a80 <sys_link+0x10a>
  ilock(dp);
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	2da080e7          	jalr	730(ra) # 80003ce8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a16:	00092703          	lw	a4,0(s2)
    80005a1a:	409c                	lw	a5,0(s1)
    80005a1c:	04f71d63          	bne	a4,a5,80005a76 <sys_link+0x100>
    80005a20:	40d0                	lw	a2,4(s1)
    80005a22:	fd040593          	addi	a1,s0,-48
    80005a26:	854a                	mv	a0,s2
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	9ba080e7          	jalr	-1606(ra) # 800043e2 <dirlink>
    80005a30:	04054363          	bltz	a0,80005a76 <sys_link+0x100>
  iunlockput(dp);
    80005a34:	854a                	mv	a0,s2
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	514080e7          	jalr	1300(ra) # 80003f4a <iunlockput>
  iput(ip);
    80005a3e:	8526                	mv	a0,s1
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	462080e7          	jalr	1122(ra) # 80003ea2 <iput>
  end_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	cea080e7          	jalr	-790(ra) # 80004732 <end_op>
  return 0;
    80005a50:	4781                	li	a5,0
    80005a52:	a085                	j	80005ab2 <sys_link+0x13c>
    end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	cde080e7          	jalr	-802(ra) # 80004732 <end_op>
    return -1;
    80005a5c:	57fd                	li	a5,-1
    80005a5e:	a891                	j	80005ab2 <sys_link+0x13c>
    iunlockput(ip);
    80005a60:	8526                	mv	a0,s1
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	4e8080e7          	jalr	1256(ra) # 80003f4a <iunlockput>
    end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	cc8080e7          	jalr	-824(ra) # 80004732 <end_op>
    return -1;
    80005a72:	57fd                	li	a5,-1
    80005a74:	a83d                	j	80005ab2 <sys_link+0x13c>
    iunlockput(dp);
    80005a76:	854a                	mv	a0,s2
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	4d2080e7          	jalr	1234(ra) # 80003f4a <iunlockput>
  ilock(ip);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	266080e7          	jalr	614(ra) # 80003ce8 <ilock>
  ip->nlink--;
    80005a8a:	04a4d783          	lhu	a5,74(s1)
    80005a8e:	37fd                	addiw	a5,a5,-1
    80005a90:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a94:	8526                	mv	a0,s1
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	186080e7          	jalr	390(ra) # 80003c1c <iupdate>
  iunlockput(ip);
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	4aa080e7          	jalr	1194(ra) # 80003f4a <iunlockput>
  end_op();
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	c8a080e7          	jalr	-886(ra) # 80004732 <end_op>
  return -1;
    80005ab0:	57fd                	li	a5,-1
}
    80005ab2:	853e                	mv	a0,a5
    80005ab4:	70b2                	ld	ra,296(sp)
    80005ab6:	7412                	ld	s0,288(sp)
    80005ab8:	64f2                	ld	s1,280(sp)
    80005aba:	6952                	ld	s2,272(sp)
    80005abc:	6155                	addi	sp,sp,304
    80005abe:	8082                	ret

0000000080005ac0 <sys_unlink>:
{
    80005ac0:	7151                	addi	sp,sp,-240
    80005ac2:	f586                	sd	ra,232(sp)
    80005ac4:	f1a2                	sd	s0,224(sp)
    80005ac6:	eda6                	sd	s1,216(sp)
    80005ac8:	e9ca                	sd	s2,208(sp)
    80005aca:	e5ce                	sd	s3,200(sp)
    80005acc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ace:	08000613          	li	a2,128
    80005ad2:	f3040593          	addi	a1,s0,-208
    80005ad6:	4501                	li	a0,0
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	58e080e7          	jalr	1422(ra) # 80003066 <argstr>
    80005ae0:	18054163          	bltz	a0,80005c62 <sys_unlink+0x1a2>
  begin_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	bd0080e7          	jalr	-1072(ra) # 800046b4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005aec:	fb040593          	addi	a1,s0,-80
    80005af0:	f3040513          	addi	a0,s0,-208
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	9be080e7          	jalr	-1602(ra) # 800044b2 <nameiparent>
    80005afc:	84aa                	mv	s1,a0
    80005afe:	c979                	beqz	a0,80005bd4 <sys_unlink+0x114>
  ilock(dp);
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	1e8080e7          	jalr	488(ra) # 80003ce8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b08:	00003597          	auipc	a1,0x3
    80005b0c:	d5058593          	addi	a1,a1,-688 # 80008858 <syscalls+0x2c8>
    80005b10:	fb040513          	addi	a0,s0,-80
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	69e080e7          	jalr	1694(ra) # 800041b2 <namecmp>
    80005b1c:	14050a63          	beqz	a0,80005c70 <sys_unlink+0x1b0>
    80005b20:	00003597          	auipc	a1,0x3
    80005b24:	d4058593          	addi	a1,a1,-704 # 80008860 <syscalls+0x2d0>
    80005b28:	fb040513          	addi	a0,s0,-80
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	686080e7          	jalr	1670(ra) # 800041b2 <namecmp>
    80005b34:	12050e63          	beqz	a0,80005c70 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b38:	f2c40613          	addi	a2,s0,-212
    80005b3c:	fb040593          	addi	a1,s0,-80
    80005b40:	8526                	mv	a0,s1
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	68a080e7          	jalr	1674(ra) # 800041cc <dirlookup>
    80005b4a:	892a                	mv	s2,a0
    80005b4c:	12050263          	beqz	a0,80005c70 <sys_unlink+0x1b0>
  ilock(ip);
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	198080e7          	jalr	408(ra) # 80003ce8 <ilock>
  if(ip->nlink < 1)
    80005b58:	04a91783          	lh	a5,74(s2)
    80005b5c:	08f05263          	blez	a5,80005be0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b60:	04491703          	lh	a4,68(s2)
    80005b64:	4785                	li	a5,1
    80005b66:	08f70563          	beq	a4,a5,80005bf0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b6a:	4641                	li	a2,16
    80005b6c:	4581                	li	a1,0
    80005b6e:	fc040513          	addi	a0,s0,-64
    80005b72:	ffffb097          	auipc	ra,0xffffb
    80005b76:	2ec080e7          	jalr	748(ra) # 80000e5e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b7a:	4741                	li	a4,16
    80005b7c:	f2c42683          	lw	a3,-212(s0)
    80005b80:	fc040613          	addi	a2,s0,-64
    80005b84:	4581                	li	a1,0
    80005b86:	8526                	mv	a0,s1
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	50c080e7          	jalr	1292(ra) # 80004094 <writei>
    80005b90:	47c1                	li	a5,16
    80005b92:	0af51563          	bne	a0,a5,80005c3c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b96:	04491703          	lh	a4,68(s2)
    80005b9a:	4785                	li	a5,1
    80005b9c:	0af70863          	beq	a4,a5,80005c4c <sys_unlink+0x18c>
  iunlockput(dp);
    80005ba0:	8526                	mv	a0,s1
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	3a8080e7          	jalr	936(ra) # 80003f4a <iunlockput>
  ip->nlink--;
    80005baa:	04a95783          	lhu	a5,74(s2)
    80005bae:	37fd                	addiw	a5,a5,-1
    80005bb0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bb4:	854a                	mv	a0,s2
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	066080e7          	jalr	102(ra) # 80003c1c <iupdate>
  iunlockput(ip);
    80005bbe:	854a                	mv	a0,s2
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	38a080e7          	jalr	906(ra) # 80003f4a <iunlockput>
  end_op();
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	b6a080e7          	jalr	-1174(ra) # 80004732 <end_op>
  return 0;
    80005bd0:	4501                	li	a0,0
    80005bd2:	a84d                	j	80005c84 <sys_unlink+0x1c4>
    end_op();
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	b5e080e7          	jalr	-1186(ra) # 80004732 <end_op>
    return -1;
    80005bdc:	557d                	li	a0,-1
    80005bde:	a05d                	j	80005c84 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005be0:	00003517          	auipc	a0,0x3
    80005be4:	c8850513          	addi	a0,a0,-888 # 80008868 <syscalls+0x2d8>
    80005be8:	ffffb097          	auipc	ra,0xffffb
    80005bec:	958080e7          	jalr	-1704(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bf0:	04c92703          	lw	a4,76(s2)
    80005bf4:	02000793          	li	a5,32
    80005bf8:	f6e7f9e3          	bgeu	a5,a4,80005b6a <sys_unlink+0xaa>
    80005bfc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c00:	4741                	li	a4,16
    80005c02:	86ce                	mv	a3,s3
    80005c04:	f1840613          	addi	a2,s0,-232
    80005c08:	4581                	li	a1,0
    80005c0a:	854a                	mv	a0,s2
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	390080e7          	jalr	912(ra) # 80003f9c <readi>
    80005c14:	47c1                	li	a5,16
    80005c16:	00f51b63          	bne	a0,a5,80005c2c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c1a:	f1845783          	lhu	a5,-232(s0)
    80005c1e:	e7a1                	bnez	a5,80005c66 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c20:	29c1                	addiw	s3,s3,16
    80005c22:	04c92783          	lw	a5,76(s2)
    80005c26:	fcf9ede3          	bltu	s3,a5,80005c00 <sys_unlink+0x140>
    80005c2a:	b781                	j	80005b6a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c2c:	00003517          	auipc	a0,0x3
    80005c30:	c5450513          	addi	a0,a0,-940 # 80008880 <syscalls+0x2f0>
    80005c34:	ffffb097          	auipc	ra,0xffffb
    80005c38:	90c080e7          	jalr	-1780(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005c3c:	00003517          	auipc	a0,0x3
    80005c40:	c5c50513          	addi	a0,a0,-932 # 80008898 <syscalls+0x308>
    80005c44:	ffffb097          	auipc	ra,0xffffb
    80005c48:	8fc080e7          	jalr	-1796(ra) # 80000540 <panic>
    dp->nlink--;
    80005c4c:	04a4d783          	lhu	a5,74(s1)
    80005c50:	37fd                	addiw	a5,a5,-1
    80005c52:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	fc4080e7          	jalr	-60(ra) # 80003c1c <iupdate>
    80005c60:	b781                	j	80005ba0 <sys_unlink+0xe0>
    return -1;
    80005c62:	557d                	li	a0,-1
    80005c64:	a005                	j	80005c84 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c66:	854a                	mv	a0,s2
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	2e2080e7          	jalr	738(ra) # 80003f4a <iunlockput>
  iunlockput(dp);
    80005c70:	8526                	mv	a0,s1
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	2d8080e7          	jalr	728(ra) # 80003f4a <iunlockput>
  end_op();
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	ab8080e7          	jalr	-1352(ra) # 80004732 <end_op>
  return -1;
    80005c82:	557d                	li	a0,-1
}
    80005c84:	70ae                	ld	ra,232(sp)
    80005c86:	740e                	ld	s0,224(sp)
    80005c88:	64ee                	ld	s1,216(sp)
    80005c8a:	694e                	ld	s2,208(sp)
    80005c8c:	69ae                	ld	s3,200(sp)
    80005c8e:	616d                	addi	sp,sp,240
    80005c90:	8082                	ret

0000000080005c92 <sys_open>:

uint64
sys_open(void)
{
    80005c92:	7131                	addi	sp,sp,-192
    80005c94:	fd06                	sd	ra,184(sp)
    80005c96:	f922                	sd	s0,176(sp)
    80005c98:	f526                	sd	s1,168(sp)
    80005c9a:	f14a                	sd	s2,160(sp)
    80005c9c:	ed4e                	sd	s3,152(sp)
    80005c9e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ca0:	f4c40593          	addi	a1,s0,-180
    80005ca4:	4505                	li	a0,1
    80005ca6:	ffffd097          	auipc	ra,0xffffd
    80005caa:	380080e7          	jalr	896(ra) # 80003026 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cae:	08000613          	li	a2,128
    80005cb2:	f5040593          	addi	a1,s0,-176
    80005cb6:	4501                	li	a0,0
    80005cb8:	ffffd097          	auipc	ra,0xffffd
    80005cbc:	3ae080e7          	jalr	942(ra) # 80003066 <argstr>
    80005cc0:	87aa                	mv	a5,a0
    return -1;
    80005cc2:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cc4:	0a07c963          	bltz	a5,80005d76 <sys_open+0xe4>

  begin_op();
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	9ec080e7          	jalr	-1556(ra) # 800046b4 <begin_op>

  if(omode & O_CREATE){
    80005cd0:	f4c42783          	lw	a5,-180(s0)
    80005cd4:	2007f793          	andi	a5,a5,512
    80005cd8:	cfc5                	beqz	a5,80005d90 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cda:	4681                	li	a3,0
    80005cdc:	4601                	li	a2,0
    80005cde:	4589                	li	a1,2
    80005ce0:	f5040513          	addi	a0,s0,-176
    80005ce4:	00000097          	auipc	ra,0x0
    80005ce8:	972080e7          	jalr	-1678(ra) # 80005656 <create>
    80005cec:	84aa                	mv	s1,a0
    if(ip == 0){
    80005cee:	c959                	beqz	a0,80005d84 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cf0:	04449703          	lh	a4,68(s1)
    80005cf4:	478d                	li	a5,3
    80005cf6:	00f71763          	bne	a4,a5,80005d04 <sys_open+0x72>
    80005cfa:	0464d703          	lhu	a4,70(s1)
    80005cfe:	47a5                	li	a5,9
    80005d00:	0ce7ed63          	bltu	a5,a4,80005dda <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	dbc080e7          	jalr	-580(ra) # 80004ac0 <filealloc>
    80005d0c:	89aa                	mv	s3,a0
    80005d0e:	10050363          	beqz	a0,80005e14 <sys_open+0x182>
    80005d12:	00000097          	auipc	ra,0x0
    80005d16:	902080e7          	jalr	-1790(ra) # 80005614 <fdalloc>
    80005d1a:	892a                	mv	s2,a0
    80005d1c:	0e054763          	bltz	a0,80005e0a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d20:	04449703          	lh	a4,68(s1)
    80005d24:	478d                	li	a5,3
    80005d26:	0cf70563          	beq	a4,a5,80005df0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d2a:	4789                	li	a5,2
    80005d2c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d30:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d34:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d38:	f4c42783          	lw	a5,-180(s0)
    80005d3c:	0017c713          	xori	a4,a5,1
    80005d40:	8b05                	andi	a4,a4,1
    80005d42:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d46:	0037f713          	andi	a4,a5,3
    80005d4a:	00e03733          	snez	a4,a4
    80005d4e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d52:	4007f793          	andi	a5,a5,1024
    80005d56:	c791                	beqz	a5,80005d62 <sys_open+0xd0>
    80005d58:	04449703          	lh	a4,68(s1)
    80005d5c:	4789                	li	a5,2
    80005d5e:	0af70063          	beq	a4,a5,80005dfe <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d62:	8526                	mv	a0,s1
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	046080e7          	jalr	70(ra) # 80003daa <iunlock>
  end_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	9c6080e7          	jalr	-1594(ra) # 80004732 <end_op>

  return fd;
    80005d74:	854a                	mv	a0,s2
}
    80005d76:	70ea                	ld	ra,184(sp)
    80005d78:	744a                	ld	s0,176(sp)
    80005d7a:	74aa                	ld	s1,168(sp)
    80005d7c:	790a                	ld	s2,160(sp)
    80005d7e:	69ea                	ld	s3,152(sp)
    80005d80:	6129                	addi	sp,sp,192
    80005d82:	8082                	ret
      end_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	9ae080e7          	jalr	-1618(ra) # 80004732 <end_op>
      return -1;
    80005d8c:	557d                	li	a0,-1
    80005d8e:	b7e5                	j	80005d76 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d90:	f5040513          	addi	a0,s0,-176
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	700080e7          	jalr	1792(ra) # 80004494 <namei>
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	c905                	beqz	a0,80005dce <sys_open+0x13c>
    ilock(ip);
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	f48080e7          	jalr	-184(ra) # 80003ce8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005da8:	04449703          	lh	a4,68(s1)
    80005dac:	4785                	li	a5,1
    80005dae:	f4f711e3          	bne	a4,a5,80005cf0 <sys_open+0x5e>
    80005db2:	f4c42783          	lw	a5,-180(s0)
    80005db6:	d7b9                	beqz	a5,80005d04 <sys_open+0x72>
      iunlockput(ip);
    80005db8:	8526                	mv	a0,s1
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	190080e7          	jalr	400(ra) # 80003f4a <iunlockput>
      end_op();
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	970080e7          	jalr	-1680(ra) # 80004732 <end_op>
      return -1;
    80005dca:	557d                	li	a0,-1
    80005dcc:	b76d                	j	80005d76 <sys_open+0xe4>
      end_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	964080e7          	jalr	-1692(ra) # 80004732 <end_op>
      return -1;
    80005dd6:	557d                	li	a0,-1
    80005dd8:	bf79                	j	80005d76 <sys_open+0xe4>
    iunlockput(ip);
    80005dda:	8526                	mv	a0,s1
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	16e080e7          	jalr	366(ra) # 80003f4a <iunlockput>
    end_op();
    80005de4:	fffff097          	auipc	ra,0xfffff
    80005de8:	94e080e7          	jalr	-1714(ra) # 80004732 <end_op>
    return -1;
    80005dec:	557d                	li	a0,-1
    80005dee:	b761                	j	80005d76 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005df0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005df4:	04649783          	lh	a5,70(s1)
    80005df8:	02f99223          	sh	a5,36(s3)
    80005dfc:	bf25                	j	80005d34 <sys_open+0xa2>
    itrunc(ip);
    80005dfe:	8526                	mv	a0,s1
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	ff6080e7          	jalr	-10(ra) # 80003df6 <itrunc>
    80005e08:	bfa9                	j	80005d62 <sys_open+0xd0>
      fileclose(f);
    80005e0a:	854e                	mv	a0,s3
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	d70080e7          	jalr	-656(ra) # 80004b7c <fileclose>
    iunlockput(ip);
    80005e14:	8526                	mv	a0,s1
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	134080e7          	jalr	308(ra) # 80003f4a <iunlockput>
    end_op();
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	914080e7          	jalr	-1772(ra) # 80004732 <end_op>
    return -1;
    80005e26:	557d                	li	a0,-1
    80005e28:	b7b9                	j	80005d76 <sys_open+0xe4>

0000000080005e2a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e2a:	7175                	addi	sp,sp,-144
    80005e2c:	e506                	sd	ra,136(sp)
    80005e2e:	e122                	sd	s0,128(sp)
    80005e30:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	882080e7          	jalr	-1918(ra) # 800046b4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e3a:	08000613          	li	a2,128
    80005e3e:	f7040593          	addi	a1,s0,-144
    80005e42:	4501                	li	a0,0
    80005e44:	ffffd097          	auipc	ra,0xffffd
    80005e48:	222080e7          	jalr	546(ra) # 80003066 <argstr>
    80005e4c:	02054963          	bltz	a0,80005e7e <sys_mkdir+0x54>
    80005e50:	4681                	li	a3,0
    80005e52:	4601                	li	a2,0
    80005e54:	4585                	li	a1,1
    80005e56:	f7040513          	addi	a0,s0,-144
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	7fc080e7          	jalr	2044(ra) # 80005656 <create>
    80005e62:	cd11                	beqz	a0,80005e7e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	0e6080e7          	jalr	230(ra) # 80003f4a <iunlockput>
  end_op();
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	8c6080e7          	jalr	-1850(ra) # 80004732 <end_op>
  return 0;
    80005e74:	4501                	li	a0,0
}
    80005e76:	60aa                	ld	ra,136(sp)
    80005e78:	640a                	ld	s0,128(sp)
    80005e7a:	6149                	addi	sp,sp,144
    80005e7c:	8082                	ret
    end_op();
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	8b4080e7          	jalr	-1868(ra) # 80004732 <end_op>
    return -1;
    80005e86:	557d                	li	a0,-1
    80005e88:	b7fd                	j	80005e76 <sys_mkdir+0x4c>

0000000080005e8a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e8a:	7135                	addi	sp,sp,-160
    80005e8c:	ed06                	sd	ra,152(sp)
    80005e8e:	e922                	sd	s0,144(sp)
    80005e90:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	822080e7          	jalr	-2014(ra) # 800046b4 <begin_op>
  argint(1, &major);
    80005e9a:	f6c40593          	addi	a1,s0,-148
    80005e9e:	4505                	li	a0,1
    80005ea0:	ffffd097          	auipc	ra,0xffffd
    80005ea4:	186080e7          	jalr	390(ra) # 80003026 <argint>
  argint(2, &minor);
    80005ea8:	f6840593          	addi	a1,s0,-152
    80005eac:	4509                	li	a0,2
    80005eae:	ffffd097          	auipc	ra,0xffffd
    80005eb2:	178080e7          	jalr	376(ra) # 80003026 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005eb6:	08000613          	li	a2,128
    80005eba:	f7040593          	addi	a1,s0,-144
    80005ebe:	4501                	li	a0,0
    80005ec0:	ffffd097          	auipc	ra,0xffffd
    80005ec4:	1a6080e7          	jalr	422(ra) # 80003066 <argstr>
    80005ec8:	02054b63          	bltz	a0,80005efe <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ecc:	f6841683          	lh	a3,-152(s0)
    80005ed0:	f6c41603          	lh	a2,-148(s0)
    80005ed4:	458d                	li	a1,3
    80005ed6:	f7040513          	addi	a0,s0,-144
    80005eda:	fffff097          	auipc	ra,0xfffff
    80005ede:	77c080e7          	jalr	1916(ra) # 80005656 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ee2:	cd11                	beqz	a0,80005efe <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ee4:	ffffe097          	auipc	ra,0xffffe
    80005ee8:	066080e7          	jalr	102(ra) # 80003f4a <iunlockput>
  end_op();
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	846080e7          	jalr	-1978(ra) # 80004732 <end_op>
  return 0;
    80005ef4:	4501                	li	a0,0
}
    80005ef6:	60ea                	ld	ra,152(sp)
    80005ef8:	644a                	ld	s0,144(sp)
    80005efa:	610d                	addi	sp,sp,160
    80005efc:	8082                	ret
    end_op();
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	834080e7          	jalr	-1996(ra) # 80004732 <end_op>
    return -1;
    80005f06:	557d                	li	a0,-1
    80005f08:	b7fd                	j	80005ef6 <sys_mknod+0x6c>

0000000080005f0a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f0a:	7135                	addi	sp,sp,-160
    80005f0c:	ed06                	sd	ra,152(sp)
    80005f0e:	e922                	sd	s0,144(sp)
    80005f10:	e526                	sd	s1,136(sp)
    80005f12:	e14a                	sd	s2,128(sp)
    80005f14:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f16:	ffffc097          	auipc	ra,0xffffc
    80005f1a:	d5a080e7          	jalr	-678(ra) # 80001c70 <myproc>
    80005f1e:	892a                	mv	s2,a0
  
  begin_op();
    80005f20:	ffffe097          	auipc	ra,0xffffe
    80005f24:	794080e7          	jalr	1940(ra) # 800046b4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f28:	08000613          	li	a2,128
    80005f2c:	f6040593          	addi	a1,s0,-160
    80005f30:	4501                	li	a0,0
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	134080e7          	jalr	308(ra) # 80003066 <argstr>
    80005f3a:	04054b63          	bltz	a0,80005f90 <sys_chdir+0x86>
    80005f3e:	f6040513          	addi	a0,s0,-160
    80005f42:	ffffe097          	auipc	ra,0xffffe
    80005f46:	552080e7          	jalr	1362(ra) # 80004494 <namei>
    80005f4a:	84aa                	mv	s1,a0
    80005f4c:	c131                	beqz	a0,80005f90 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	d9a080e7          	jalr	-614(ra) # 80003ce8 <ilock>
  if(ip->type != T_DIR){
    80005f56:	04449703          	lh	a4,68(s1)
    80005f5a:	4785                	li	a5,1
    80005f5c:	04f71063          	bne	a4,a5,80005f9c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f60:	8526                	mv	a0,s1
    80005f62:	ffffe097          	auipc	ra,0xffffe
    80005f66:	e48080e7          	jalr	-440(ra) # 80003daa <iunlock>
  iput(p->cwd);
    80005f6a:	15093503          	ld	a0,336(s2)
    80005f6e:	ffffe097          	auipc	ra,0xffffe
    80005f72:	f34080e7          	jalr	-204(ra) # 80003ea2 <iput>
  end_op();
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	7bc080e7          	jalr	1980(ra) # 80004732 <end_op>
  p->cwd = ip;
    80005f7e:	14993823          	sd	s1,336(s2)
  return 0;
    80005f82:	4501                	li	a0,0
}
    80005f84:	60ea                	ld	ra,152(sp)
    80005f86:	644a                	ld	s0,144(sp)
    80005f88:	64aa                	ld	s1,136(sp)
    80005f8a:	690a                	ld	s2,128(sp)
    80005f8c:	610d                	addi	sp,sp,160
    80005f8e:	8082                	ret
    end_op();
    80005f90:	ffffe097          	auipc	ra,0xffffe
    80005f94:	7a2080e7          	jalr	1954(ra) # 80004732 <end_op>
    return -1;
    80005f98:	557d                	li	a0,-1
    80005f9a:	b7ed                	j	80005f84 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f9c:	8526                	mv	a0,s1
    80005f9e:	ffffe097          	auipc	ra,0xffffe
    80005fa2:	fac080e7          	jalr	-84(ra) # 80003f4a <iunlockput>
    end_op();
    80005fa6:	ffffe097          	auipc	ra,0xffffe
    80005faa:	78c080e7          	jalr	1932(ra) # 80004732 <end_op>
    return -1;
    80005fae:	557d                	li	a0,-1
    80005fb0:	bfd1                	j	80005f84 <sys_chdir+0x7a>

0000000080005fb2 <sys_exec>:

uint64
sys_exec(void)
{
    80005fb2:	7145                	addi	sp,sp,-464
    80005fb4:	e786                	sd	ra,456(sp)
    80005fb6:	e3a2                	sd	s0,448(sp)
    80005fb8:	ff26                	sd	s1,440(sp)
    80005fba:	fb4a                	sd	s2,432(sp)
    80005fbc:	f74e                	sd	s3,424(sp)
    80005fbe:	f352                	sd	s4,416(sp)
    80005fc0:	ef56                	sd	s5,408(sp)
    80005fc2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005fc4:	e3840593          	addi	a1,s0,-456
    80005fc8:	4505                	li	a0,1
    80005fca:	ffffd097          	auipc	ra,0xffffd
    80005fce:	07c080e7          	jalr	124(ra) # 80003046 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005fd2:	08000613          	li	a2,128
    80005fd6:	f4040593          	addi	a1,s0,-192
    80005fda:	4501                	li	a0,0
    80005fdc:	ffffd097          	auipc	ra,0xffffd
    80005fe0:	08a080e7          	jalr	138(ra) # 80003066 <argstr>
    80005fe4:	87aa                	mv	a5,a0
    return -1;
    80005fe6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005fe8:	0c07c363          	bltz	a5,800060ae <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005fec:	10000613          	li	a2,256
    80005ff0:	4581                	li	a1,0
    80005ff2:	e4040513          	addi	a0,s0,-448
    80005ff6:	ffffb097          	auipc	ra,0xffffb
    80005ffa:	e68080e7          	jalr	-408(ra) # 80000e5e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ffe:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006002:	89a6                	mv	s3,s1
    80006004:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006006:	02000a13          	li	s4,32
    8000600a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000600e:	00391513          	slli	a0,s2,0x3
    80006012:	e3040593          	addi	a1,s0,-464
    80006016:	e3843783          	ld	a5,-456(s0)
    8000601a:	953e                	add	a0,a0,a5
    8000601c:	ffffd097          	auipc	ra,0xffffd
    80006020:	f6c080e7          	jalr	-148(ra) # 80002f88 <fetchaddr>
    80006024:	02054a63          	bltz	a0,80006058 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006028:	e3043783          	ld	a5,-464(s0)
    8000602c:	c3b9                	beqz	a5,80006072 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    //argv[i] = kalloc();
    argv[i] = n_kallock();
    8000602e:	ffffb097          	auipc	ra,0xffffb
    80006032:	c14080e7          	jalr	-1004(ra) # 80000c42 <n_kallock>
    80006036:	85aa                	mv	a1,a0
    80006038:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000603c:	cd11                	beqz	a0,80006058 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000603e:	6605                	lui	a2,0x1
    80006040:	e3043503          	ld	a0,-464(s0)
    80006044:	ffffd097          	auipc	ra,0xffffd
    80006048:	f96080e7          	jalr	-106(ra) # 80002fda <fetchstr>
    8000604c:	00054663          	bltz	a0,80006058 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006050:	0905                	addi	s2,s2,1
    80006052:	09a1                	addi	s3,s3,8
    80006054:	fb491be3          	bne	s2,s4,8000600a <sys_exec+0x58>
    n_kfree(argv[i]);
  }
  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006058:	f4040913          	addi	s2,s0,-192
    8000605c:	6088                	ld	a0,0(s1)
    8000605e:	c539                	beqz	a0,800060ac <sys_exec+0xfa>
    //kfree(argv[i]);
    n_kfree(argv[i]);
    80006060:	ffffb097          	auipc	ra,0xffffb
    80006064:	bae080e7          	jalr	-1106(ra) # 80000c0e <n_kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006068:	04a1                	addi	s1,s1,8
    8000606a:	ff2499e3          	bne	s1,s2,8000605c <sys_exec+0xaa>
  return -1;
    8000606e:	557d                	li	a0,-1
    80006070:	a83d                	j	800060ae <sys_exec+0xfc>
      argv[i] = 0;
    80006072:	0a8e                	slli	s5,s5,0x3
    80006074:	fc0a8793          	addi	a5,s5,-64
    80006078:	00878ab3          	add	s5,a5,s0
    8000607c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006080:	e4040593          	addi	a1,s0,-448
    80006084:	f4040513          	addi	a0,s0,-192
    80006088:	fffff097          	auipc	ra,0xfffff
    8000608c:	16e080e7          	jalr	366(ra) # 800051f6 <exec>
    80006090:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++){
    80006092:	f4040993          	addi	s3,s0,-192
    80006096:	6088                	ld	a0,0(s1)
    80006098:	c901                	beqz	a0,800060a8 <sys_exec+0xf6>
    n_kfree(argv[i]);
    8000609a:	ffffb097          	auipc	ra,0xffffb
    8000609e:	b74080e7          	jalr	-1164(ra) # 80000c0e <n_kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++){
    800060a2:	04a1                	addi	s1,s1,8
    800060a4:	ff3499e3          	bne	s1,s3,80006096 <sys_exec+0xe4>
  return ret;
    800060a8:	854a                	mv	a0,s2
    800060aa:	a011                	j	800060ae <sys_exec+0xfc>
  return -1;
    800060ac:	557d                	li	a0,-1
}
    800060ae:	60be                	ld	ra,456(sp)
    800060b0:	641e                	ld	s0,448(sp)
    800060b2:	74fa                	ld	s1,440(sp)
    800060b4:	795a                	ld	s2,432(sp)
    800060b6:	79ba                	ld	s3,424(sp)
    800060b8:	7a1a                	ld	s4,416(sp)
    800060ba:	6afa                	ld	s5,408(sp)
    800060bc:	6179                	addi	sp,sp,464
    800060be:	8082                	ret

00000000800060c0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060c0:	7139                	addi	sp,sp,-64
    800060c2:	fc06                	sd	ra,56(sp)
    800060c4:	f822                	sd	s0,48(sp)
    800060c6:	f426                	sd	s1,40(sp)
    800060c8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060ca:	ffffc097          	auipc	ra,0xffffc
    800060ce:	ba6080e7          	jalr	-1114(ra) # 80001c70 <myproc>
    800060d2:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800060d4:	fd840593          	addi	a1,s0,-40
    800060d8:	4501                	li	a0,0
    800060da:	ffffd097          	auipc	ra,0xffffd
    800060de:	f6c080e7          	jalr	-148(ra) # 80003046 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800060e2:	fc840593          	addi	a1,s0,-56
    800060e6:	fd040513          	addi	a0,s0,-48
    800060ea:	fffff097          	auipc	ra,0xfffff
    800060ee:	dc2080e7          	jalr	-574(ra) # 80004eac <pipealloc>
    return -1;
    800060f2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060f4:	0c054463          	bltz	a0,800061bc <sys_pipe+0xfc>
  fd0 = -1;
    800060f8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060fc:	fd043503          	ld	a0,-48(s0)
    80006100:	fffff097          	auipc	ra,0xfffff
    80006104:	514080e7          	jalr	1300(ra) # 80005614 <fdalloc>
    80006108:	fca42223          	sw	a0,-60(s0)
    8000610c:	08054b63          	bltz	a0,800061a2 <sys_pipe+0xe2>
    80006110:	fc843503          	ld	a0,-56(s0)
    80006114:	fffff097          	auipc	ra,0xfffff
    80006118:	500080e7          	jalr	1280(ra) # 80005614 <fdalloc>
    8000611c:	fca42023          	sw	a0,-64(s0)
    80006120:	06054863          	bltz	a0,80006190 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006124:	4691                	li	a3,4
    80006126:	fc440613          	addi	a2,s0,-60
    8000612a:	fd843583          	ld	a1,-40(s0)
    8000612e:	68a8                	ld	a0,80(s1)
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	702080e7          	jalr	1794(ra) # 80001832 <copyout>
    80006138:	02054063          	bltz	a0,80006158 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000613c:	4691                	li	a3,4
    8000613e:	fc040613          	addi	a2,s0,-64
    80006142:	fd843583          	ld	a1,-40(s0)
    80006146:	0591                	addi	a1,a1,4
    80006148:	68a8                	ld	a0,80(s1)
    8000614a:	ffffb097          	auipc	ra,0xffffb
    8000614e:	6e8080e7          	jalr	1768(ra) # 80001832 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006152:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006154:	06055463          	bgez	a0,800061bc <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006158:	fc442783          	lw	a5,-60(s0)
    8000615c:	07e9                	addi	a5,a5,26
    8000615e:	078e                	slli	a5,a5,0x3
    80006160:	97a6                	add	a5,a5,s1
    80006162:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006166:	fc042783          	lw	a5,-64(s0)
    8000616a:	07e9                	addi	a5,a5,26
    8000616c:	078e                	slli	a5,a5,0x3
    8000616e:	94be                	add	s1,s1,a5
    80006170:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006174:	fd043503          	ld	a0,-48(s0)
    80006178:	fffff097          	auipc	ra,0xfffff
    8000617c:	a04080e7          	jalr	-1532(ra) # 80004b7c <fileclose>
    fileclose(wf);
    80006180:	fc843503          	ld	a0,-56(s0)
    80006184:	fffff097          	auipc	ra,0xfffff
    80006188:	9f8080e7          	jalr	-1544(ra) # 80004b7c <fileclose>
    return -1;
    8000618c:	57fd                	li	a5,-1
    8000618e:	a03d                	j	800061bc <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006190:	fc442783          	lw	a5,-60(s0)
    80006194:	0007c763          	bltz	a5,800061a2 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006198:	07e9                	addi	a5,a5,26
    8000619a:	078e                	slli	a5,a5,0x3
    8000619c:	97a6                	add	a5,a5,s1
    8000619e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800061a2:	fd043503          	ld	a0,-48(s0)
    800061a6:	fffff097          	auipc	ra,0xfffff
    800061aa:	9d6080e7          	jalr	-1578(ra) # 80004b7c <fileclose>
    fileclose(wf);
    800061ae:	fc843503          	ld	a0,-56(s0)
    800061b2:	fffff097          	auipc	ra,0xfffff
    800061b6:	9ca080e7          	jalr	-1590(ra) # 80004b7c <fileclose>
    return -1;
    800061ba:	57fd                	li	a5,-1
}
    800061bc:	853e                	mv	a0,a5
    800061be:	70e2                	ld	ra,56(sp)
    800061c0:	7442                	ld	s0,48(sp)
    800061c2:	74a2                	ld	s1,40(sp)
    800061c4:	6121                	addi	sp,sp,64
    800061c6:	8082                	ret
	...

00000000800061d0 <kernelvec>:
    800061d0:	7111                	addi	sp,sp,-256
    800061d2:	e006                	sd	ra,0(sp)
    800061d4:	e40a                	sd	sp,8(sp)
    800061d6:	e80e                	sd	gp,16(sp)
    800061d8:	ec12                	sd	tp,24(sp)
    800061da:	f016                	sd	t0,32(sp)
    800061dc:	f41a                	sd	t1,40(sp)
    800061de:	f81e                	sd	t2,48(sp)
    800061e0:	fc22                	sd	s0,56(sp)
    800061e2:	e0a6                	sd	s1,64(sp)
    800061e4:	e4aa                	sd	a0,72(sp)
    800061e6:	e8ae                	sd	a1,80(sp)
    800061e8:	ecb2                	sd	a2,88(sp)
    800061ea:	f0b6                	sd	a3,96(sp)
    800061ec:	f4ba                	sd	a4,104(sp)
    800061ee:	f8be                	sd	a5,112(sp)
    800061f0:	fcc2                	sd	a6,120(sp)
    800061f2:	e146                	sd	a7,128(sp)
    800061f4:	e54a                	sd	s2,136(sp)
    800061f6:	e94e                	sd	s3,144(sp)
    800061f8:	ed52                	sd	s4,152(sp)
    800061fa:	f156                	sd	s5,160(sp)
    800061fc:	f55a                	sd	s6,168(sp)
    800061fe:	f95e                	sd	s7,176(sp)
    80006200:	fd62                	sd	s8,184(sp)
    80006202:	e1e6                	sd	s9,192(sp)
    80006204:	e5ea                	sd	s10,200(sp)
    80006206:	e9ee                	sd	s11,208(sp)
    80006208:	edf2                	sd	t3,216(sp)
    8000620a:	f1f6                	sd	t4,224(sp)
    8000620c:	f5fa                	sd	t5,232(sp)
    8000620e:	f9fe                	sd	t6,240(sp)
    80006210:	c45fc0ef          	jal	ra,80002e54 <kerneltrap>
    80006214:	6082                	ld	ra,0(sp)
    80006216:	6122                	ld	sp,8(sp)
    80006218:	61c2                	ld	gp,16(sp)
    8000621a:	7282                	ld	t0,32(sp)
    8000621c:	7322                	ld	t1,40(sp)
    8000621e:	73c2                	ld	t2,48(sp)
    80006220:	7462                	ld	s0,56(sp)
    80006222:	6486                	ld	s1,64(sp)
    80006224:	6526                	ld	a0,72(sp)
    80006226:	65c6                	ld	a1,80(sp)
    80006228:	6666                	ld	a2,88(sp)
    8000622a:	7686                	ld	a3,96(sp)
    8000622c:	7726                	ld	a4,104(sp)
    8000622e:	77c6                	ld	a5,112(sp)
    80006230:	7866                	ld	a6,120(sp)
    80006232:	688a                	ld	a7,128(sp)
    80006234:	692a                	ld	s2,136(sp)
    80006236:	69ca                	ld	s3,144(sp)
    80006238:	6a6a                	ld	s4,152(sp)
    8000623a:	7a8a                	ld	s5,160(sp)
    8000623c:	7b2a                	ld	s6,168(sp)
    8000623e:	7bca                	ld	s7,176(sp)
    80006240:	7c6a                	ld	s8,184(sp)
    80006242:	6c8e                	ld	s9,192(sp)
    80006244:	6d2e                	ld	s10,200(sp)
    80006246:	6dce                	ld	s11,208(sp)
    80006248:	6e6e                	ld	t3,216(sp)
    8000624a:	7e8e                	ld	t4,224(sp)
    8000624c:	7f2e                	ld	t5,232(sp)
    8000624e:	7fce                	ld	t6,240(sp)
    80006250:	6111                	addi	sp,sp,256
    80006252:	10200073          	sret
    80006256:	00000013          	nop
    8000625a:	00000013          	nop
    8000625e:	0001                	nop

0000000080006260 <timervec>:
    80006260:	34051573          	csrrw	a0,mscratch,a0
    80006264:	e10c                	sd	a1,0(a0)
    80006266:	e510                	sd	a2,8(a0)
    80006268:	e914                	sd	a3,16(a0)
    8000626a:	6d0c                	ld	a1,24(a0)
    8000626c:	7110                	ld	a2,32(a0)
    8000626e:	6194                	ld	a3,0(a1)
    80006270:	96b2                	add	a3,a3,a2
    80006272:	e194                	sd	a3,0(a1)
    80006274:	4589                	li	a1,2
    80006276:	14459073          	csrw	sip,a1
    8000627a:	6914                	ld	a3,16(a0)
    8000627c:	6510                	ld	a2,8(a0)
    8000627e:	610c                	ld	a1,0(a0)
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	30200073          	mret
	...

000000008000628a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000628a:	1141                	addi	sp,sp,-16
    8000628c:	e422                	sd	s0,8(sp)
    8000628e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006290:	0c0007b7          	lui	a5,0xc000
    80006294:	4705                	li	a4,1
    80006296:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006298:	c3d8                	sw	a4,4(a5)
}
    8000629a:	6422                	ld	s0,8(sp)
    8000629c:	0141                	addi	sp,sp,16
    8000629e:	8082                	ret

00000000800062a0 <plicinithart>:

void
plicinithart(void)
{
    800062a0:	1141                	addi	sp,sp,-16
    800062a2:	e406                	sd	ra,8(sp)
    800062a4:	e022                	sd	s0,0(sp)
    800062a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062a8:	ffffc097          	auipc	ra,0xffffc
    800062ac:	99c080e7          	jalr	-1636(ra) # 80001c44 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062b0:	0085171b          	slliw	a4,a0,0x8
    800062b4:	0c0027b7          	lui	a5,0xc002
    800062b8:	97ba                	add	a5,a5,a4
    800062ba:	40200713          	li	a4,1026
    800062be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062c2:	00d5151b          	slliw	a0,a0,0xd
    800062c6:	0c2017b7          	lui	a5,0xc201
    800062ca:	97aa                	add	a5,a5,a0
    800062cc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800062d0:	60a2                	ld	ra,8(sp)
    800062d2:	6402                	ld	s0,0(sp)
    800062d4:	0141                	addi	sp,sp,16
    800062d6:	8082                	ret

00000000800062d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062d8:	1141                	addi	sp,sp,-16
    800062da:	e406                	sd	ra,8(sp)
    800062dc:	e022                	sd	s0,0(sp)
    800062de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062e0:	ffffc097          	auipc	ra,0xffffc
    800062e4:	964080e7          	jalr	-1692(ra) # 80001c44 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062e8:	00d5151b          	slliw	a0,a0,0xd
    800062ec:	0c2017b7          	lui	a5,0xc201
    800062f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800062f2:	43c8                	lw	a0,4(a5)
    800062f4:	60a2                	ld	ra,8(sp)
    800062f6:	6402                	ld	s0,0(sp)
    800062f8:	0141                	addi	sp,sp,16
    800062fa:	8082                	ret

00000000800062fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062fc:	1101                	addi	sp,sp,-32
    800062fe:	ec06                	sd	ra,24(sp)
    80006300:	e822                	sd	s0,16(sp)
    80006302:	e426                	sd	s1,8(sp)
    80006304:	1000                	addi	s0,sp,32
    80006306:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006308:	ffffc097          	auipc	ra,0xffffc
    8000630c:	93c080e7          	jalr	-1732(ra) # 80001c44 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006310:	00d5151b          	slliw	a0,a0,0xd
    80006314:	0c2017b7          	lui	a5,0xc201
    80006318:	97aa                	add	a5,a5,a0
    8000631a:	c3c4                	sw	s1,4(a5)
}
    8000631c:	60e2                	ld	ra,24(sp)
    8000631e:	6442                	ld	s0,16(sp)
    80006320:	64a2                	ld	s1,8(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret

0000000080006326 <free_desc>:
    80006326:	1141                	addi	sp,sp,-16
    80006328:	e406                	sd	ra,8(sp)
    8000632a:	e022                	sd	s0,0(sp)
    8000632c:	0800                	addi	s0,sp,16
    8000632e:	479d                	li	a5,7
    80006330:	04a7cc63          	blt	a5,a0,80006388 <free_desc+0x62>
    80006334:	0003c797          	auipc	a5,0x3c
    80006338:	a9c78793          	addi	a5,a5,-1380 # 80041dd0 <disk>
    8000633c:	97aa                	add	a5,a5,a0
    8000633e:	0187c783          	lbu	a5,24(a5)
    80006342:	ebb9                	bnez	a5,80006398 <free_desc+0x72>
    80006344:	00451693          	slli	a3,a0,0x4
    80006348:	0003c797          	auipc	a5,0x3c
    8000634c:	a8878793          	addi	a5,a5,-1400 # 80041dd0 <disk>
    80006350:	6398                	ld	a4,0(a5)
    80006352:	9736                	add	a4,a4,a3
    80006354:	00073023          	sd	zero,0(a4)
    80006358:	6398                	ld	a4,0(a5)
    8000635a:	9736                	add	a4,a4,a3
    8000635c:	00072423          	sw	zero,8(a4)
    80006360:	00071623          	sh	zero,12(a4)
    80006364:	00071723          	sh	zero,14(a4)
    80006368:	97aa                	add	a5,a5,a0
    8000636a:	4705                	li	a4,1
    8000636c:	00e78c23          	sb	a4,24(a5)
    80006370:	0003c517          	auipc	a0,0x3c
    80006374:	a7850513          	addi	a0,a0,-1416 # 80041de8 <disk+0x18>
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	0c4080e7          	jalr	196(ra) # 8000243c <wakeup>
    80006380:	60a2                	ld	ra,8(sp)
    80006382:	6402                	ld	s0,0(sp)
    80006384:	0141                	addi	sp,sp,16
    80006386:	8082                	ret
    80006388:	00002517          	auipc	a0,0x2
    8000638c:	52050513          	addi	a0,a0,1312 # 800088a8 <syscalls+0x318>
    80006390:	ffffa097          	auipc	ra,0xffffa
    80006394:	1b0080e7          	jalr	432(ra) # 80000540 <panic>
    80006398:	00002517          	auipc	a0,0x2
    8000639c:	52050513          	addi	a0,a0,1312 # 800088b8 <syscalls+0x328>
    800063a0:	ffffa097          	auipc	ra,0xffffa
    800063a4:	1a0080e7          	jalr	416(ra) # 80000540 <panic>

00000000800063a8 <virtio_disk_init>:
    800063a8:	1101                	addi	sp,sp,-32
    800063aa:	ec06                	sd	ra,24(sp)
    800063ac:	e822                	sd	s0,16(sp)
    800063ae:	e426                	sd	s1,8(sp)
    800063b0:	e04a                	sd	s2,0(sp)
    800063b2:	1000                	addi	s0,sp,32
    800063b4:	00002597          	auipc	a1,0x2
    800063b8:	51458593          	addi	a1,a1,1300 # 800088c8 <syscalls+0x338>
    800063bc:	0003c517          	auipc	a0,0x3c
    800063c0:	b3c50513          	addi	a0,a0,-1220 # 80041ef8 <disk+0x128>
    800063c4:	ffffb097          	auipc	ra,0xffffb
    800063c8:	90e080e7          	jalr	-1778(ra) # 80000cd2 <initlock>
    800063cc:	100017b7          	lui	a5,0x10001
    800063d0:	4398                	lw	a4,0(a5)
    800063d2:	2701                	sext.w	a4,a4
    800063d4:	747277b7          	lui	a5,0x74727
    800063d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063dc:	14f71b63          	bne	a4,a5,80006532 <virtio_disk_init+0x18a>
    800063e0:	100017b7          	lui	a5,0x10001
    800063e4:	43dc                	lw	a5,4(a5)
    800063e6:	2781                	sext.w	a5,a5
    800063e8:	4709                	li	a4,2
    800063ea:	14e79463          	bne	a5,a4,80006532 <virtio_disk_init+0x18a>
    800063ee:	100017b7          	lui	a5,0x10001
    800063f2:	479c                	lw	a5,8(a5)
    800063f4:	2781                	sext.w	a5,a5
    800063f6:	12e79e63          	bne	a5,a4,80006532 <virtio_disk_init+0x18a>
    800063fa:	100017b7          	lui	a5,0x10001
    800063fe:	47d8                	lw	a4,12(a5)
    80006400:	2701                	sext.w	a4,a4
    80006402:	554d47b7          	lui	a5,0x554d4
    80006406:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000640a:	12f71463          	bne	a4,a5,80006532 <virtio_disk_init+0x18a>
    8000640e:	100017b7          	lui	a5,0x10001
    80006412:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
    80006416:	4705                	li	a4,1
    80006418:	dbb8                	sw	a4,112(a5)
    8000641a:	470d                	li	a4,3
    8000641c:	dbb8                	sw	a4,112(a5)
    8000641e:	4b98                	lw	a4,16(a5)
    80006420:	c7ffe6b7          	lui	a3,0xc7ffe
    80006424:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fbc84f>
    80006428:	8f75                	and	a4,a4,a3
    8000642a:	d398                	sw	a4,32(a5)
    8000642c:	472d                	li	a4,11
    8000642e:	dbb8                	sw	a4,112(a5)
    80006430:	5bbc                	lw	a5,112(a5)
    80006432:	0007891b          	sext.w	s2,a5
    80006436:	8ba1                	andi	a5,a5,8
    80006438:	10078563          	beqz	a5,80006542 <virtio_disk_init+0x19a>
    8000643c:	100017b7          	lui	a5,0x10001
    80006440:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
    80006444:	43fc                	lw	a5,68(a5)
    80006446:	2781                	sext.w	a5,a5
    80006448:	10079563          	bnez	a5,80006552 <virtio_disk_init+0x1aa>
    8000644c:	100017b7          	lui	a5,0x10001
    80006450:	5bdc                	lw	a5,52(a5)
    80006452:	2781                	sext.w	a5,a5
    80006454:	10078763          	beqz	a5,80006562 <virtio_disk_init+0x1ba>
    80006458:	471d                	li	a4,7
    8000645a:	10f77c63          	bgeu	a4,a5,80006572 <virtio_disk_init+0x1ca>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	7e4080e7          	jalr	2020(ra) # 80000c42 <n_kallock>
    80006466:	0003c497          	auipc	s1,0x3c
    8000646a:	96a48493          	addi	s1,s1,-1686 # 80041dd0 <disk>
    8000646e:	e088                	sd	a0,0(s1)
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	7d2080e7          	jalr	2002(ra) # 80000c42 <n_kallock>
    80006478:	e488                	sd	a0,8(s1)
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	7c8080e7          	jalr	1992(ra) # 80000c42 <n_kallock>
    80006482:	87aa                	mv	a5,a0
    80006484:	e888                	sd	a0,16(s1)
    80006486:	6088                	ld	a0,0(s1)
    80006488:	cd6d                	beqz	a0,80006582 <virtio_disk_init+0x1da>
    8000648a:	0003c717          	auipc	a4,0x3c
    8000648e:	94e73703          	ld	a4,-1714(a4) # 80041dd8 <disk+0x8>
    80006492:	cb65                	beqz	a4,80006582 <virtio_disk_init+0x1da>
    80006494:	c7fd                	beqz	a5,80006582 <virtio_disk_init+0x1da>
    80006496:	6605                	lui	a2,0x1
    80006498:	4581                	li	a1,0
    8000649a:	ffffb097          	auipc	ra,0xffffb
    8000649e:	9c4080e7          	jalr	-1596(ra) # 80000e5e <memset>
    800064a2:	0003c497          	auipc	s1,0x3c
    800064a6:	92e48493          	addi	s1,s1,-1746 # 80041dd0 <disk>
    800064aa:	6605                	lui	a2,0x1
    800064ac:	4581                	li	a1,0
    800064ae:	6488                	ld	a0,8(s1)
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	9ae080e7          	jalr	-1618(ra) # 80000e5e <memset>
    800064b8:	6605                	lui	a2,0x1
    800064ba:	4581                	li	a1,0
    800064bc:	6888                	ld	a0,16(s1)
    800064be:	ffffb097          	auipc	ra,0xffffb
    800064c2:	9a0080e7          	jalr	-1632(ra) # 80000e5e <memset>
    800064c6:	100017b7          	lui	a5,0x10001
    800064ca:	4721                	li	a4,8
    800064cc:	df98                	sw	a4,56(a5)
    800064ce:	4098                	lw	a4,0(s1)
    800064d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
    800064d4:	40d8                	lw	a4,4(s1)
    800064d6:	08e7a223          	sw	a4,132(a5)
    800064da:	6498                	ld	a4,8(s1)
    800064dc:	0007069b          	sext.w	a3,a4
    800064e0:	08d7a823          	sw	a3,144(a5)
    800064e4:	9701                	srai	a4,a4,0x20
    800064e6:	08e7aa23          	sw	a4,148(a5)
    800064ea:	6898                	ld	a4,16(s1)
    800064ec:	0007069b          	sext.w	a3,a4
    800064f0:	0ad7a023          	sw	a3,160(a5)
    800064f4:	9701                	srai	a4,a4,0x20
    800064f6:	0ae7a223          	sw	a4,164(a5)
    800064fa:	4705                	li	a4,1
    800064fc:	c3f8                	sw	a4,68(a5)
    800064fe:	00e48c23          	sb	a4,24(s1)
    80006502:	00e48ca3          	sb	a4,25(s1)
    80006506:	00e48d23          	sb	a4,26(s1)
    8000650a:	00e48da3          	sb	a4,27(s1)
    8000650e:	00e48e23          	sb	a4,28(s1)
    80006512:	00e48ea3          	sb	a4,29(s1)
    80006516:	00e48f23          	sb	a4,30(s1)
    8000651a:	00e48fa3          	sb	a4,31(s1)
    8000651e:	00496913          	ori	s2,s2,4
    80006522:	0727a823          	sw	s2,112(a5)
    80006526:	60e2                	ld	ra,24(sp)
    80006528:	6442                	ld	s0,16(sp)
    8000652a:	64a2                	ld	s1,8(sp)
    8000652c:	6902                	ld	s2,0(sp)
    8000652e:	6105                	addi	sp,sp,32
    80006530:	8082                	ret
    80006532:	00002517          	auipc	a0,0x2
    80006536:	3a650513          	addi	a0,a0,934 # 800088d8 <syscalls+0x348>
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	006080e7          	jalr	6(ra) # 80000540 <panic>
    80006542:	00002517          	auipc	a0,0x2
    80006546:	3b650513          	addi	a0,a0,950 # 800088f8 <syscalls+0x368>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	ff6080e7          	jalr	-10(ra) # 80000540 <panic>
    80006552:	00002517          	auipc	a0,0x2
    80006556:	3c650513          	addi	a0,a0,966 # 80008918 <syscalls+0x388>
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	fe6080e7          	jalr	-26(ra) # 80000540 <panic>
    80006562:	00002517          	auipc	a0,0x2
    80006566:	3d650513          	addi	a0,a0,982 # 80008938 <syscalls+0x3a8>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd6080e7          	jalr	-42(ra) # 80000540 <panic>
    80006572:	00002517          	auipc	a0,0x2
    80006576:	3e650513          	addi	a0,a0,998 # 80008958 <syscalls+0x3c8>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>
    80006582:	00002517          	auipc	a0,0x2
    80006586:	3f650513          	addi	a0,a0,1014 # 80008978 <syscalls+0x3e8>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	fb6080e7          	jalr	-74(ra) # 80000540 <panic>

0000000080006592 <virtio_disk_rw>:
    80006592:	7119                	addi	sp,sp,-128
    80006594:	fc86                	sd	ra,120(sp)
    80006596:	f8a2                	sd	s0,112(sp)
    80006598:	f4a6                	sd	s1,104(sp)
    8000659a:	f0ca                	sd	s2,96(sp)
    8000659c:	ecce                	sd	s3,88(sp)
    8000659e:	e8d2                	sd	s4,80(sp)
    800065a0:	e4d6                	sd	s5,72(sp)
    800065a2:	e0da                	sd	s6,64(sp)
    800065a4:	fc5e                	sd	s7,56(sp)
    800065a6:	f862                	sd	s8,48(sp)
    800065a8:	f466                	sd	s9,40(sp)
    800065aa:	f06a                	sd	s10,32(sp)
    800065ac:	ec6e                	sd	s11,24(sp)
    800065ae:	0100                	addi	s0,sp,128
    800065b0:	8aaa                	mv	s5,a0
    800065b2:	8c2e                	mv	s8,a1
    800065b4:	00c52d03          	lw	s10,12(a0)
    800065b8:	001d1d1b          	slliw	s10,s10,0x1
    800065bc:	1d02                	slli	s10,s10,0x20
    800065be:	020d5d13          	srli	s10,s10,0x20
    800065c2:	0003c517          	auipc	a0,0x3c
    800065c6:	93650513          	addi	a0,a0,-1738 # 80041ef8 <disk+0x128>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	798080e7          	jalr	1944(ra) # 80000d62 <acquire>
    800065d2:	4981                	li	s3,0
    800065d4:	44a1                	li	s1,8
    800065d6:	0003bb97          	auipc	s7,0x3b
    800065da:	7fab8b93          	addi	s7,s7,2042 # 80041dd0 <disk>
    800065de:	4b0d                	li	s6,3
    800065e0:	0003cc97          	auipc	s9,0x3c
    800065e4:	918c8c93          	addi	s9,s9,-1768 # 80041ef8 <disk+0x128>
    800065e8:	a08d                	j	8000664a <virtio_disk_rw+0xb8>
    800065ea:	00fb8733          	add	a4,s7,a5
    800065ee:	00070c23          	sb	zero,24(a4)
    800065f2:	c19c                	sw	a5,0(a1)
    800065f4:	0207c563          	bltz	a5,8000661e <virtio_disk_rw+0x8c>
    800065f8:	2905                	addiw	s2,s2,1
    800065fa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800065fc:	05690c63          	beq	s2,s6,80006654 <virtio_disk_rw+0xc2>
    80006600:	85b2                	mv	a1,a2
    80006602:	0003b717          	auipc	a4,0x3b
    80006606:	7ce70713          	addi	a4,a4,1998 # 80041dd0 <disk>
    8000660a:	87ce                	mv	a5,s3
    8000660c:	01874683          	lbu	a3,24(a4)
    80006610:	fee9                	bnez	a3,800065ea <virtio_disk_rw+0x58>
    80006612:	2785                	addiw	a5,a5,1
    80006614:	0705                	addi	a4,a4,1
    80006616:	fe979be3          	bne	a5,s1,8000660c <virtio_disk_rw+0x7a>
    8000661a:	57fd                	li	a5,-1
    8000661c:	c19c                	sw	a5,0(a1)
    8000661e:	01205d63          	blez	s2,80006638 <virtio_disk_rw+0xa6>
    80006622:	8dce                	mv	s11,s3
    80006624:	000a2503          	lw	a0,0(s4)
    80006628:	00000097          	auipc	ra,0x0
    8000662c:	cfe080e7          	jalr	-770(ra) # 80006326 <free_desc>
    80006630:	2d85                	addiw	s11,s11,1
    80006632:	0a11                	addi	s4,s4,4
    80006634:	ff2d98e3          	bne	s11,s2,80006624 <virtio_disk_rw+0x92>
    80006638:	85e6                	mv	a1,s9
    8000663a:	0003b517          	auipc	a0,0x3b
    8000663e:	7ae50513          	addi	a0,a0,1966 # 80041de8 <disk+0x18>
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	d96080e7          	jalr	-618(ra) # 800023d8 <sleep>
    8000664a:	f8040a13          	addi	s4,s0,-128
    8000664e:	8652                	mv	a2,s4
    80006650:	894e                	mv	s2,s3
    80006652:	b77d                	j	80006600 <virtio_disk_rw+0x6e>
    80006654:	f8042503          	lw	a0,-128(s0)
    80006658:	00a50713          	addi	a4,a0,10
    8000665c:	0712                	slli	a4,a4,0x4
    8000665e:	0003b797          	auipc	a5,0x3b
    80006662:	77278793          	addi	a5,a5,1906 # 80041dd0 <disk>
    80006666:	00e786b3          	add	a3,a5,a4
    8000666a:	01803633          	snez	a2,s8
    8000666e:	c690                	sw	a2,8(a3)
    80006670:	0006a623          	sw	zero,12(a3)
    80006674:	01a6b823          	sd	s10,16(a3)
    80006678:	f6070613          	addi	a2,a4,-160
    8000667c:	6394                	ld	a3,0(a5)
    8000667e:	96b2                	add	a3,a3,a2
    80006680:	00870593          	addi	a1,a4,8
    80006684:	95be                	add	a1,a1,a5
    80006686:	e28c                	sd	a1,0(a3)
    80006688:	0007b803          	ld	a6,0(a5)
    8000668c:	9642                	add	a2,a2,a6
    8000668e:	46c1                	li	a3,16
    80006690:	c614                	sw	a3,8(a2)
    80006692:	4585                	li	a1,1
    80006694:	00b61623          	sh	a1,12(a2)
    80006698:	f8442683          	lw	a3,-124(s0)
    8000669c:	00d61723          	sh	a3,14(a2)
    800066a0:	0692                	slli	a3,a3,0x4
    800066a2:	9836                	add	a6,a6,a3
    800066a4:	058a8613          	addi	a2,s5,88
    800066a8:	00c83023          	sd	a2,0(a6)
    800066ac:	0007b803          	ld	a6,0(a5)
    800066b0:	96c2                	add	a3,a3,a6
    800066b2:	40000613          	li	a2,1024
    800066b6:	c690                	sw	a2,8(a3)
    800066b8:	001c3613          	seqz	a2,s8
    800066bc:	0016161b          	slliw	a2,a2,0x1
    800066c0:	00166613          	ori	a2,a2,1
    800066c4:	00c69623          	sh	a2,12(a3)
    800066c8:	f8842603          	lw	a2,-120(s0)
    800066cc:	00c69723          	sh	a2,14(a3)
    800066d0:	00250693          	addi	a3,a0,2
    800066d4:	0692                	slli	a3,a3,0x4
    800066d6:	96be                	add	a3,a3,a5
    800066d8:	58fd                	li	a7,-1
    800066da:	01168823          	sb	a7,16(a3)
    800066de:	0612                	slli	a2,a2,0x4
    800066e0:	9832                	add	a6,a6,a2
    800066e2:	f9070713          	addi	a4,a4,-112
    800066e6:	973e                	add	a4,a4,a5
    800066e8:	00e83023          	sd	a4,0(a6)
    800066ec:	6398                	ld	a4,0(a5)
    800066ee:	9732                	add	a4,a4,a2
    800066f0:	c70c                	sw	a1,8(a4)
    800066f2:	4609                	li	a2,2
    800066f4:	00c71623          	sh	a2,12(a4)
    800066f8:	00071723          	sh	zero,14(a4)
    800066fc:	00baa223          	sw	a1,4(s5)
    80006700:	0156b423          	sd	s5,8(a3)
    80006704:	6794                	ld	a3,8(a5)
    80006706:	0026d703          	lhu	a4,2(a3)
    8000670a:	8b1d                	andi	a4,a4,7
    8000670c:	0706                	slli	a4,a4,0x1
    8000670e:	96ba                	add	a3,a3,a4
    80006710:	00a69223          	sh	a0,4(a3)
    80006714:	0ff0000f          	fence
    80006718:	6798                	ld	a4,8(a5)
    8000671a:	00275783          	lhu	a5,2(a4)
    8000671e:	2785                	addiw	a5,a5,1
    80006720:	00f71123          	sh	a5,2(a4)
    80006724:	0ff0000f          	fence
    80006728:	100017b7          	lui	a5,0x10001
    8000672c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>
    80006730:	004aa783          	lw	a5,4(s5)
    80006734:	0003b917          	auipc	s2,0x3b
    80006738:	7c490913          	addi	s2,s2,1988 # 80041ef8 <disk+0x128>
    8000673c:	4485                	li	s1,1
    8000673e:	00b79c63          	bne	a5,a1,80006756 <virtio_disk_rw+0x1c4>
    80006742:	85ca                	mv	a1,s2
    80006744:	8556                	mv	a0,s5
    80006746:	ffffc097          	auipc	ra,0xffffc
    8000674a:	c92080e7          	jalr	-878(ra) # 800023d8 <sleep>
    8000674e:	004aa783          	lw	a5,4(s5)
    80006752:	fe9788e3          	beq	a5,s1,80006742 <virtio_disk_rw+0x1b0>
    80006756:	f8042903          	lw	s2,-128(s0)
    8000675a:	00290713          	addi	a4,s2,2
    8000675e:	0712                	slli	a4,a4,0x4
    80006760:	0003b797          	auipc	a5,0x3b
    80006764:	67078793          	addi	a5,a5,1648 # 80041dd0 <disk>
    80006768:	97ba                	add	a5,a5,a4
    8000676a:	0007b423          	sd	zero,8(a5)
    8000676e:	0003b997          	auipc	s3,0x3b
    80006772:	66298993          	addi	s3,s3,1634 # 80041dd0 <disk>
    80006776:	00491713          	slli	a4,s2,0x4
    8000677a:	0009b783          	ld	a5,0(s3)
    8000677e:	97ba                	add	a5,a5,a4
    80006780:	00c7d483          	lhu	s1,12(a5)
    80006784:	854a                	mv	a0,s2
    80006786:	00e7d903          	lhu	s2,14(a5)
    8000678a:	00000097          	auipc	ra,0x0
    8000678e:	b9c080e7          	jalr	-1124(ra) # 80006326 <free_desc>
    80006792:	8885                	andi	s1,s1,1
    80006794:	f0ed                	bnez	s1,80006776 <virtio_disk_rw+0x1e4>
    80006796:	0003b517          	auipc	a0,0x3b
    8000679a:	76250513          	addi	a0,a0,1890 # 80041ef8 <disk+0x128>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	678080e7          	jalr	1656(ra) # 80000e16 <release>
    800067a6:	70e6                	ld	ra,120(sp)
    800067a8:	7446                	ld	s0,112(sp)
    800067aa:	74a6                	ld	s1,104(sp)
    800067ac:	7906                	ld	s2,96(sp)
    800067ae:	69e6                	ld	s3,88(sp)
    800067b0:	6a46                	ld	s4,80(sp)
    800067b2:	6aa6                	ld	s5,72(sp)
    800067b4:	6b06                	ld	s6,64(sp)
    800067b6:	7be2                	ld	s7,56(sp)
    800067b8:	7c42                	ld	s8,48(sp)
    800067ba:	7ca2                	ld	s9,40(sp)
    800067bc:	7d02                	ld	s10,32(sp)
    800067be:	6de2                	ld	s11,24(sp)
    800067c0:	6109                	addi	sp,sp,128
    800067c2:	8082                	ret

00000000800067c4 <virtio_disk_intr>:
    800067c4:	1101                	addi	sp,sp,-32
    800067c6:	ec06                	sd	ra,24(sp)
    800067c8:	e822                	sd	s0,16(sp)
    800067ca:	e426                	sd	s1,8(sp)
    800067cc:	1000                	addi	s0,sp,32
    800067ce:	0003b497          	auipc	s1,0x3b
    800067d2:	60248493          	addi	s1,s1,1538 # 80041dd0 <disk>
    800067d6:	0003b517          	auipc	a0,0x3b
    800067da:	72250513          	addi	a0,a0,1826 # 80041ef8 <disk+0x128>
    800067de:	ffffa097          	auipc	ra,0xffffa
    800067e2:	584080e7          	jalr	1412(ra) # 80000d62 <acquire>
    800067e6:	10001737          	lui	a4,0x10001
    800067ea:	533c                	lw	a5,96(a4)
    800067ec:	8b8d                	andi	a5,a5,3
    800067ee:	d37c                	sw	a5,100(a4)
    800067f0:	0ff0000f          	fence
    800067f4:	689c                	ld	a5,16(s1)
    800067f6:	0204d703          	lhu	a4,32(s1)
    800067fa:	0027d783          	lhu	a5,2(a5)
    800067fe:	04f70863          	beq	a4,a5,8000684e <virtio_disk_intr+0x8a>
    80006802:	0ff0000f          	fence
    80006806:	6898                	ld	a4,16(s1)
    80006808:	0204d783          	lhu	a5,32(s1)
    8000680c:	8b9d                	andi	a5,a5,7
    8000680e:	078e                	slli	a5,a5,0x3
    80006810:	97ba                	add	a5,a5,a4
    80006812:	43dc                	lw	a5,4(a5)
    80006814:	00278713          	addi	a4,a5,2
    80006818:	0712                	slli	a4,a4,0x4
    8000681a:	9726                	add	a4,a4,s1
    8000681c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006820:	e721                	bnez	a4,80006868 <virtio_disk_intr+0xa4>
    80006822:	0789                	addi	a5,a5,2
    80006824:	0792                	slli	a5,a5,0x4
    80006826:	97a6                	add	a5,a5,s1
    80006828:	6788                	ld	a0,8(a5)
    8000682a:	00052223          	sw	zero,4(a0)
    8000682e:	ffffc097          	auipc	ra,0xffffc
    80006832:	c0e080e7          	jalr	-1010(ra) # 8000243c <wakeup>
    80006836:	0204d783          	lhu	a5,32(s1)
    8000683a:	2785                	addiw	a5,a5,1
    8000683c:	17c2                	slli	a5,a5,0x30
    8000683e:	93c1                	srli	a5,a5,0x30
    80006840:	02f49023          	sh	a5,32(s1)
    80006844:	6898                	ld	a4,16(s1)
    80006846:	00275703          	lhu	a4,2(a4)
    8000684a:	faf71ce3          	bne	a4,a5,80006802 <virtio_disk_intr+0x3e>
    8000684e:	0003b517          	auipc	a0,0x3b
    80006852:	6aa50513          	addi	a0,a0,1706 # 80041ef8 <disk+0x128>
    80006856:	ffffa097          	auipc	ra,0xffffa
    8000685a:	5c0080e7          	jalr	1472(ra) # 80000e16 <release>
    8000685e:	60e2                	ld	ra,24(sp)
    80006860:	6442                	ld	s0,16(sp)
    80006862:	64a2                	ld	s1,8(sp)
    80006864:	6105                	addi	sp,sp,32
    80006866:	8082                	ret
    80006868:	00002517          	auipc	a0,0x2
    8000686c:	12850513          	addi	a0,a0,296 # 80008990 <syscalls+0x400>
    80006870:	ffffa097          	auipc	ra,0xffffa
    80006874:	cd0080e7          	jalr	-816(ra) # 80000540 <panic>
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
