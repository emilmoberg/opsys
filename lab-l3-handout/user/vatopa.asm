
user/_vatopa:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
    if(argc < 2 || argc > 3) {
   e:	ffe5071b          	addiw	a4,a0,-2
  12:	4785                	li	a5,1
  14:	00e7ff63          	bgeu	a5,a4,32 <main+0x32>
        printf("Usage: vatopa virtual_address [pid]\n");
  18:	00001517          	auipc	a0,0x1
  1c:	83850513          	addi	a0,a0,-1992 # 850 <malloc+0xe8>
  20:	00000097          	auipc	ra,0x0
  24:	690080e7          	jalr	1680(ra) # 6b0 <printf>
        exit(0);
  28:	4501                	li	a0,0
  2a:	00000097          	auipc	ra,0x0
  2e:	2e4080e7          	jalr	740(ra) # 30e <exit>
  32:	84aa                	mv	s1,a0
  34:	892e                	mv	s2,a1
    }

    uint64 addr = atoi(argv[1]); // Convert the virtual address from string to int
  36:	6588                	ld	a0,8(a1)
  38:	00000097          	auipc	ra,0x0
  3c:	1dc080e7          	jalr	476(ra) # 214 <atoi>
  40:	89aa                	mv	s3,a0
    int pid = argc == 3 ? atoi(argv[2]) : getpid(); // If pid is not provided, use current process's pid
  42:	478d                	li	a5,3
  44:	02f48a63          	beq	s1,a5,78 <main+0x78>
  48:	00000097          	auipc	ra,0x0
  4c:	346080e7          	jalr	838(ra) # 38e <getpid>
  50:	85aa                	mv	a1,a0

    uint64 pa = va2pa(addr, pid); // Call the va2pa system call
  52:	854e                	mv	a0,s3
  54:	00000097          	auipc	ra,0x0
  58:	372080e7          	jalr	882(ra) # 3c6 <va2pa>
  5c:	85aa                	mv	a1,a0

    printf("0x%x\n", pa);
  5e:	00001517          	auipc	a0,0x1
  62:	81a50513          	addi	a0,a0,-2022 # 878 <malloc+0x110>
  66:	00000097          	auipc	ra,0x0
  6a:	64a080e7          	jalr	1610(ra) # 6b0 <printf>

    exit(0);
  6e:	4501                	li	a0,0
  70:	00000097          	auipc	ra,0x0
  74:	29e080e7          	jalr	670(ra) # 30e <exit>
    int pid = argc == 3 ? atoi(argv[2]) : getpid(); // If pid is not provided, use current process's pid
  78:	01093503          	ld	a0,16(s2)
  7c:	00000097          	auipc	ra,0x0
  80:	198080e7          	jalr	408(ra) # 214 <atoi>
  84:	85aa                	mv	a1,a0
  86:	b7f1                	j	52 <main+0x52>

0000000000000088 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  88:	1141                	addi	sp,sp,-16
  8a:	e406                	sd	ra,8(sp)
  8c:	e022                	sd	s0,0(sp)
  8e:	0800                	addi	s0,sp,16
  extern int main();
  main();
  90:	00000097          	auipc	ra,0x0
  94:	f70080e7          	jalr	-144(ra) # 0 <main>
  exit(0);
  98:	4501                	li	a0,0
  9a:	00000097          	auipc	ra,0x0
  9e:	274080e7          	jalr	628(ra) # 30e <exit>

00000000000000a2 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  a2:	1141                	addi	sp,sp,-16
  a4:	e422                	sd	s0,8(sp)
  a6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  a8:	87aa                	mv	a5,a0
  aa:	0585                	addi	a1,a1,1
  ac:	0785                	addi	a5,a5,1
  ae:	fff5c703          	lbu	a4,-1(a1)
  b2:	fee78fa3          	sb	a4,-1(a5)
  b6:	fb75                	bnez	a4,aa <strcpy+0x8>
    ;
  return os;
}
  b8:	6422                	ld	s0,8(sp)
  ba:	0141                	addi	sp,sp,16
  bc:	8082                	ret

00000000000000be <strcmp>:

int
strcmp(const char *p, const char *q)
{
  be:	1141                	addi	sp,sp,-16
  c0:	e422                	sd	s0,8(sp)
  c2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  c4:	00054783          	lbu	a5,0(a0)
  c8:	cb91                	beqz	a5,dc <strcmp+0x1e>
  ca:	0005c703          	lbu	a4,0(a1)
  ce:	00f71763          	bne	a4,a5,dc <strcmp+0x1e>
    p++, q++;
  d2:	0505                	addi	a0,a0,1
  d4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  d6:	00054783          	lbu	a5,0(a0)
  da:	fbe5                	bnez	a5,ca <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  dc:	0005c503          	lbu	a0,0(a1)
}
  e0:	40a7853b          	subw	a0,a5,a0
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	addi	sp,sp,16
  e8:	8082                	ret

00000000000000ea <strlen>:

uint
strlen(const char *s)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  f0:	00054783          	lbu	a5,0(a0)
  f4:	cf91                	beqz	a5,110 <strlen+0x26>
  f6:	0505                	addi	a0,a0,1
  f8:	87aa                	mv	a5,a0
  fa:	4685                	li	a3,1
  fc:	9e89                	subw	a3,a3,a0
  fe:	00f6853b          	addw	a0,a3,a5
 102:	0785                	addi	a5,a5,1
 104:	fff7c703          	lbu	a4,-1(a5)
 108:	fb7d                	bnez	a4,fe <strlen+0x14>
    ;
  return n;
}
 10a:	6422                	ld	s0,8(sp)
 10c:	0141                	addi	sp,sp,16
 10e:	8082                	ret
  for(n = 0; s[n]; n++)
 110:	4501                	li	a0,0
 112:	bfe5                	j	10a <strlen+0x20>

0000000000000114 <memset>:

void*
memset(void *dst, int c, uint n)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 11a:	ca19                	beqz	a2,130 <memset+0x1c>
 11c:	87aa                	mv	a5,a0
 11e:	1602                	slli	a2,a2,0x20
 120:	9201                	srli	a2,a2,0x20
 122:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 126:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 12a:	0785                	addi	a5,a5,1
 12c:	fee79de3          	bne	a5,a4,126 <memset+0x12>
  }
  return dst;
}
 130:	6422                	ld	s0,8(sp)
 132:	0141                	addi	sp,sp,16
 134:	8082                	ret

0000000000000136 <strchr>:

char*
strchr(const char *s, char c)
{
 136:	1141                	addi	sp,sp,-16
 138:	e422                	sd	s0,8(sp)
 13a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 13c:	00054783          	lbu	a5,0(a0)
 140:	cb99                	beqz	a5,156 <strchr+0x20>
    if(*s == c)
 142:	00f58763          	beq	a1,a5,150 <strchr+0x1a>
  for(; *s; s++)
 146:	0505                	addi	a0,a0,1
 148:	00054783          	lbu	a5,0(a0)
 14c:	fbfd                	bnez	a5,142 <strchr+0xc>
      return (char*)s;
  return 0;
 14e:	4501                	li	a0,0
}
 150:	6422                	ld	s0,8(sp)
 152:	0141                	addi	sp,sp,16
 154:	8082                	ret
  return 0;
 156:	4501                	li	a0,0
 158:	bfe5                	j	150 <strchr+0x1a>

000000000000015a <gets>:

char*
gets(char *buf, int max)
{
 15a:	711d                	addi	sp,sp,-96
 15c:	ec86                	sd	ra,88(sp)
 15e:	e8a2                	sd	s0,80(sp)
 160:	e4a6                	sd	s1,72(sp)
 162:	e0ca                	sd	s2,64(sp)
 164:	fc4e                	sd	s3,56(sp)
 166:	f852                	sd	s4,48(sp)
 168:	f456                	sd	s5,40(sp)
 16a:	f05a                	sd	s6,32(sp)
 16c:	ec5e                	sd	s7,24(sp)
 16e:	1080                	addi	s0,sp,96
 170:	8baa                	mv	s7,a0
 172:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 174:	892a                	mv	s2,a0
 176:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 178:	4aa9                	li	s5,10
 17a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 17c:	89a6                	mv	s3,s1
 17e:	2485                	addiw	s1,s1,1
 180:	0344d863          	bge	s1,s4,1b0 <gets+0x56>
    cc = read(0, &c, 1);
 184:	4605                	li	a2,1
 186:	faf40593          	addi	a1,s0,-81
 18a:	4501                	li	a0,0
 18c:	00000097          	auipc	ra,0x0
 190:	19a080e7          	jalr	410(ra) # 326 <read>
    if(cc < 1)
 194:	00a05e63          	blez	a0,1b0 <gets+0x56>
    buf[i++] = c;
 198:	faf44783          	lbu	a5,-81(s0)
 19c:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1a0:	01578763          	beq	a5,s5,1ae <gets+0x54>
 1a4:	0905                	addi	s2,s2,1
 1a6:	fd679be3          	bne	a5,s6,17c <gets+0x22>
  for(i=0; i+1 < max; ){
 1aa:	89a6                	mv	s3,s1
 1ac:	a011                	j	1b0 <gets+0x56>
 1ae:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1b0:	99de                	add	s3,s3,s7
 1b2:	00098023          	sb	zero,0(s3)
  return buf;
}
 1b6:	855e                	mv	a0,s7
 1b8:	60e6                	ld	ra,88(sp)
 1ba:	6446                	ld	s0,80(sp)
 1bc:	64a6                	ld	s1,72(sp)
 1be:	6906                	ld	s2,64(sp)
 1c0:	79e2                	ld	s3,56(sp)
 1c2:	7a42                	ld	s4,48(sp)
 1c4:	7aa2                	ld	s5,40(sp)
 1c6:	7b02                	ld	s6,32(sp)
 1c8:	6be2                	ld	s7,24(sp)
 1ca:	6125                	addi	sp,sp,96
 1cc:	8082                	ret

00000000000001ce <stat>:

int
stat(const char *n, struct stat *st)
{
 1ce:	1101                	addi	sp,sp,-32
 1d0:	ec06                	sd	ra,24(sp)
 1d2:	e822                	sd	s0,16(sp)
 1d4:	e426                	sd	s1,8(sp)
 1d6:	e04a                	sd	s2,0(sp)
 1d8:	1000                	addi	s0,sp,32
 1da:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1dc:	4581                	li	a1,0
 1de:	00000097          	auipc	ra,0x0
 1e2:	170080e7          	jalr	368(ra) # 34e <open>
  if(fd < 0)
 1e6:	02054563          	bltz	a0,210 <stat+0x42>
 1ea:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ec:	85ca                	mv	a1,s2
 1ee:	00000097          	auipc	ra,0x0
 1f2:	178080e7          	jalr	376(ra) # 366 <fstat>
 1f6:	892a                	mv	s2,a0
  close(fd);
 1f8:	8526                	mv	a0,s1
 1fa:	00000097          	auipc	ra,0x0
 1fe:	13c080e7          	jalr	316(ra) # 336 <close>
  return r;
}
 202:	854a                	mv	a0,s2
 204:	60e2                	ld	ra,24(sp)
 206:	6442                	ld	s0,16(sp)
 208:	64a2                	ld	s1,8(sp)
 20a:	6902                	ld	s2,0(sp)
 20c:	6105                	addi	sp,sp,32
 20e:	8082                	ret
    return -1;
 210:	597d                	li	s2,-1
 212:	bfc5                	j	202 <stat+0x34>

0000000000000214 <atoi>:

int
atoi(const char *s)
{
 214:	1141                	addi	sp,sp,-16
 216:	e422                	sd	s0,8(sp)
 218:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 21a:	00054683          	lbu	a3,0(a0)
 21e:	fd06879b          	addiw	a5,a3,-48
 222:	0ff7f793          	zext.b	a5,a5
 226:	4625                	li	a2,9
 228:	02f66863          	bltu	a2,a5,258 <atoi+0x44>
 22c:	872a                	mv	a4,a0
  n = 0;
 22e:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 230:	0705                	addi	a4,a4,1
 232:	0025179b          	slliw	a5,a0,0x2
 236:	9fa9                	addw	a5,a5,a0
 238:	0017979b          	slliw	a5,a5,0x1
 23c:	9fb5                	addw	a5,a5,a3
 23e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 242:	00074683          	lbu	a3,0(a4)
 246:	fd06879b          	addiw	a5,a3,-48
 24a:	0ff7f793          	zext.b	a5,a5
 24e:	fef671e3          	bgeu	a2,a5,230 <atoi+0x1c>
  return n;
}
 252:	6422                	ld	s0,8(sp)
 254:	0141                	addi	sp,sp,16
 256:	8082                	ret
  n = 0;
 258:	4501                	li	a0,0
 25a:	bfe5                	j	252 <atoi+0x3e>

000000000000025c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 25c:	1141                	addi	sp,sp,-16
 25e:	e422                	sd	s0,8(sp)
 260:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 262:	02b57463          	bgeu	a0,a1,28a <memmove+0x2e>
    while(n-- > 0)
 266:	00c05f63          	blez	a2,284 <memmove+0x28>
 26a:	1602                	slli	a2,a2,0x20
 26c:	9201                	srli	a2,a2,0x20
 26e:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 272:	872a                	mv	a4,a0
      *dst++ = *src++;
 274:	0585                	addi	a1,a1,1
 276:	0705                	addi	a4,a4,1
 278:	fff5c683          	lbu	a3,-1(a1)
 27c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 280:	fee79ae3          	bne	a5,a4,274 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 284:	6422                	ld	s0,8(sp)
 286:	0141                	addi	sp,sp,16
 288:	8082                	ret
    dst += n;
 28a:	00c50733          	add	a4,a0,a2
    src += n;
 28e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 290:	fec05ae3          	blez	a2,284 <memmove+0x28>
 294:	fff6079b          	addiw	a5,a2,-1
 298:	1782                	slli	a5,a5,0x20
 29a:	9381                	srli	a5,a5,0x20
 29c:	fff7c793          	not	a5,a5
 2a0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2a2:	15fd                	addi	a1,a1,-1
 2a4:	177d                	addi	a4,a4,-1
 2a6:	0005c683          	lbu	a3,0(a1)
 2aa:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2ae:	fee79ae3          	bne	a5,a4,2a2 <memmove+0x46>
 2b2:	bfc9                	j	284 <memmove+0x28>

00000000000002b4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2b4:	1141                	addi	sp,sp,-16
 2b6:	e422                	sd	s0,8(sp)
 2b8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2ba:	ca05                	beqz	a2,2ea <memcmp+0x36>
 2bc:	fff6069b          	addiw	a3,a2,-1
 2c0:	1682                	slli	a3,a3,0x20
 2c2:	9281                	srli	a3,a3,0x20
 2c4:	0685                	addi	a3,a3,1
 2c6:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2c8:	00054783          	lbu	a5,0(a0)
 2cc:	0005c703          	lbu	a4,0(a1)
 2d0:	00e79863          	bne	a5,a4,2e0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2d4:	0505                	addi	a0,a0,1
    p2++;
 2d6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2d8:	fed518e3          	bne	a0,a3,2c8 <memcmp+0x14>
  }
  return 0;
 2dc:	4501                	li	a0,0
 2de:	a019                	j	2e4 <memcmp+0x30>
      return *p1 - *p2;
 2e0:	40e7853b          	subw	a0,a5,a4
}
 2e4:	6422                	ld	s0,8(sp)
 2e6:	0141                	addi	sp,sp,16
 2e8:	8082                	ret
  return 0;
 2ea:	4501                	li	a0,0
 2ec:	bfe5                	j	2e4 <memcmp+0x30>

00000000000002ee <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e406                	sd	ra,8(sp)
 2f2:	e022                	sd	s0,0(sp)
 2f4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2f6:	00000097          	auipc	ra,0x0
 2fa:	f66080e7          	jalr	-154(ra) # 25c <memmove>
}
 2fe:	60a2                	ld	ra,8(sp)
 300:	6402                	ld	s0,0(sp)
 302:	0141                	addi	sp,sp,16
 304:	8082                	ret

0000000000000306 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 306:	4885                	li	a7,1
 ecall
 308:	00000073          	ecall
 ret
 30c:	8082                	ret

000000000000030e <exit>:
.global exit
exit:
 li a7, SYS_exit
 30e:	4889                	li	a7,2
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <wait>:
.global wait
wait:
 li a7, SYS_wait
 316:	488d                	li	a7,3
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 31e:	4891                	li	a7,4
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <read>:
.global read
read:
 li a7, SYS_read
 326:	4895                	li	a7,5
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <write>:
.global write
write:
 li a7, SYS_write
 32e:	48c1                	li	a7,16
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <close>:
.global close
close:
 li a7, SYS_close
 336:	48d5                	li	a7,21
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <kill>:
.global kill
kill:
 li a7, SYS_kill
 33e:	4899                	li	a7,6
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <exec>:
.global exec
exec:
 li a7, SYS_exec
 346:	489d                	li	a7,7
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <open>:
.global open
open:
 li a7, SYS_open
 34e:	48bd                	li	a7,15
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 356:	48c5                	li	a7,17
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 35e:	48c9                	li	a7,18
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 366:	48a1                	li	a7,8
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <link>:
.global link
link:
 li a7, SYS_link
 36e:	48cd                	li	a7,19
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 376:	48d1                	li	a7,20
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 37e:	48a5                	li	a7,9
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <dup>:
.global dup
dup:
 li a7, SYS_dup
 386:	48a9                	li	a7,10
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 38e:	48ad                	li	a7,11
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 396:	48b1                	li	a7,12
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 39e:	48b5                	li	a7,13
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3a6:	48b9                	li	a7,14
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <ps>:
.global ps
ps:
 li a7, SYS_ps
 3ae:	48d9                	li	a7,22
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <schedls>:
.global schedls
schedls:
 li a7, SYS_schedls
 3b6:	48dd                	li	a7,23
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <schedset>:
.global schedset
schedset:
 li a7, SYS_schedset
 3be:	48e1                	li	a7,24
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <va2pa>:
.global va2pa
va2pa:
 li a7, SYS_va2pa
 3c6:	48e9                	li	a7,26
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <pfreepages>:
.global pfreepages
pfreepages:
 li a7, SYS_pfreepages
 3ce:	48e5                	li	a7,25
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3d6:	1101                	addi	sp,sp,-32
 3d8:	ec06                	sd	ra,24(sp)
 3da:	e822                	sd	s0,16(sp)
 3dc:	1000                	addi	s0,sp,32
 3de:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3e2:	4605                	li	a2,1
 3e4:	fef40593          	addi	a1,s0,-17
 3e8:	00000097          	auipc	ra,0x0
 3ec:	f46080e7          	jalr	-186(ra) # 32e <write>
}
 3f0:	60e2                	ld	ra,24(sp)
 3f2:	6442                	ld	s0,16(sp)
 3f4:	6105                	addi	sp,sp,32
 3f6:	8082                	ret

00000000000003f8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3f8:	7139                	addi	sp,sp,-64
 3fa:	fc06                	sd	ra,56(sp)
 3fc:	f822                	sd	s0,48(sp)
 3fe:	f426                	sd	s1,40(sp)
 400:	f04a                	sd	s2,32(sp)
 402:	ec4e                	sd	s3,24(sp)
 404:	0080                	addi	s0,sp,64
 406:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 408:	c299                	beqz	a3,40e <printint+0x16>
 40a:	0805c963          	bltz	a1,49c <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 40e:	2581                	sext.w	a1,a1
  neg = 0;
 410:	4881                	li	a7,0
 412:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 416:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 418:	2601                	sext.w	a2,a2
 41a:	00000517          	auipc	a0,0x0
 41e:	4c650513          	addi	a0,a0,1222 # 8e0 <digits>
 422:	883a                	mv	a6,a4
 424:	2705                	addiw	a4,a4,1
 426:	02c5f7bb          	remuw	a5,a1,a2
 42a:	1782                	slli	a5,a5,0x20
 42c:	9381                	srli	a5,a5,0x20
 42e:	97aa                	add	a5,a5,a0
 430:	0007c783          	lbu	a5,0(a5)
 434:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 438:	0005879b          	sext.w	a5,a1
 43c:	02c5d5bb          	divuw	a1,a1,a2
 440:	0685                	addi	a3,a3,1
 442:	fec7f0e3          	bgeu	a5,a2,422 <printint+0x2a>
  if(neg)
 446:	00088c63          	beqz	a7,45e <printint+0x66>
    buf[i++] = '-';
 44a:	fd070793          	addi	a5,a4,-48
 44e:	00878733          	add	a4,a5,s0
 452:	02d00793          	li	a5,45
 456:	fef70823          	sb	a5,-16(a4)
 45a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 45e:	02e05863          	blez	a4,48e <printint+0x96>
 462:	fc040793          	addi	a5,s0,-64
 466:	00e78933          	add	s2,a5,a4
 46a:	fff78993          	addi	s3,a5,-1
 46e:	99ba                	add	s3,s3,a4
 470:	377d                	addiw	a4,a4,-1
 472:	1702                	slli	a4,a4,0x20
 474:	9301                	srli	a4,a4,0x20
 476:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 47a:	fff94583          	lbu	a1,-1(s2)
 47e:	8526                	mv	a0,s1
 480:	00000097          	auipc	ra,0x0
 484:	f56080e7          	jalr	-170(ra) # 3d6 <putc>
  while(--i >= 0)
 488:	197d                	addi	s2,s2,-1
 48a:	ff3918e3          	bne	s2,s3,47a <printint+0x82>
}
 48e:	70e2                	ld	ra,56(sp)
 490:	7442                	ld	s0,48(sp)
 492:	74a2                	ld	s1,40(sp)
 494:	7902                	ld	s2,32(sp)
 496:	69e2                	ld	s3,24(sp)
 498:	6121                	addi	sp,sp,64
 49a:	8082                	ret
    x = -xx;
 49c:	40b005bb          	negw	a1,a1
    neg = 1;
 4a0:	4885                	li	a7,1
    x = -xx;
 4a2:	bf85                	j	412 <printint+0x1a>

00000000000004a4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4a4:	7119                	addi	sp,sp,-128
 4a6:	fc86                	sd	ra,120(sp)
 4a8:	f8a2                	sd	s0,112(sp)
 4aa:	f4a6                	sd	s1,104(sp)
 4ac:	f0ca                	sd	s2,96(sp)
 4ae:	ecce                	sd	s3,88(sp)
 4b0:	e8d2                	sd	s4,80(sp)
 4b2:	e4d6                	sd	s5,72(sp)
 4b4:	e0da                	sd	s6,64(sp)
 4b6:	fc5e                	sd	s7,56(sp)
 4b8:	f862                	sd	s8,48(sp)
 4ba:	f466                	sd	s9,40(sp)
 4bc:	f06a                	sd	s10,32(sp)
 4be:	ec6e                	sd	s11,24(sp)
 4c0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4c2:	0005c903          	lbu	s2,0(a1)
 4c6:	18090f63          	beqz	s2,664 <vprintf+0x1c0>
 4ca:	8aaa                	mv	s5,a0
 4cc:	8b32                	mv	s6,a2
 4ce:	00158493          	addi	s1,a1,1
  state = 0;
 4d2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4d4:	02500a13          	li	s4,37
 4d8:	4c55                	li	s8,21
 4da:	00000c97          	auipc	s9,0x0
 4de:	3aec8c93          	addi	s9,s9,942 # 888 <malloc+0x120>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4e2:	02800d93          	li	s11,40
  putc(fd, 'x');
 4e6:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4e8:	00000b97          	auipc	s7,0x0
 4ec:	3f8b8b93          	addi	s7,s7,1016 # 8e0 <digits>
 4f0:	a839                	j	50e <vprintf+0x6a>
        putc(fd, c);
 4f2:	85ca                	mv	a1,s2
 4f4:	8556                	mv	a0,s5
 4f6:	00000097          	auipc	ra,0x0
 4fa:	ee0080e7          	jalr	-288(ra) # 3d6 <putc>
 4fe:	a019                	j	504 <vprintf+0x60>
    } else if(state == '%'){
 500:	01498d63          	beq	s3,s4,51a <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 504:	0485                	addi	s1,s1,1
 506:	fff4c903          	lbu	s2,-1(s1)
 50a:	14090d63          	beqz	s2,664 <vprintf+0x1c0>
    if(state == 0){
 50e:	fe0999e3          	bnez	s3,500 <vprintf+0x5c>
      if(c == '%'){
 512:	ff4910e3          	bne	s2,s4,4f2 <vprintf+0x4e>
        state = '%';
 516:	89d2                	mv	s3,s4
 518:	b7f5                	j	504 <vprintf+0x60>
      if(c == 'd'){
 51a:	11490c63          	beq	s2,s4,632 <vprintf+0x18e>
 51e:	f9d9079b          	addiw	a5,s2,-99
 522:	0ff7f793          	zext.b	a5,a5
 526:	10fc6e63          	bltu	s8,a5,642 <vprintf+0x19e>
 52a:	f9d9079b          	addiw	a5,s2,-99
 52e:	0ff7f713          	zext.b	a4,a5
 532:	10ec6863          	bltu	s8,a4,642 <vprintf+0x19e>
 536:	00271793          	slli	a5,a4,0x2
 53a:	97e6                	add	a5,a5,s9
 53c:	439c                	lw	a5,0(a5)
 53e:	97e6                	add	a5,a5,s9
 540:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 542:	008b0913          	addi	s2,s6,8
 546:	4685                	li	a3,1
 548:	4629                	li	a2,10
 54a:	000b2583          	lw	a1,0(s6)
 54e:	8556                	mv	a0,s5
 550:	00000097          	auipc	ra,0x0
 554:	ea8080e7          	jalr	-344(ra) # 3f8 <printint>
 558:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 55a:	4981                	li	s3,0
 55c:	b765                	j	504 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 55e:	008b0913          	addi	s2,s6,8
 562:	4681                	li	a3,0
 564:	4629                	li	a2,10
 566:	000b2583          	lw	a1,0(s6)
 56a:	8556                	mv	a0,s5
 56c:	00000097          	auipc	ra,0x0
 570:	e8c080e7          	jalr	-372(ra) # 3f8 <printint>
 574:	8b4a                	mv	s6,s2
      state = 0;
 576:	4981                	li	s3,0
 578:	b771                	j	504 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 57a:	008b0913          	addi	s2,s6,8
 57e:	4681                	li	a3,0
 580:	866a                	mv	a2,s10
 582:	000b2583          	lw	a1,0(s6)
 586:	8556                	mv	a0,s5
 588:	00000097          	auipc	ra,0x0
 58c:	e70080e7          	jalr	-400(ra) # 3f8 <printint>
 590:	8b4a                	mv	s6,s2
      state = 0;
 592:	4981                	li	s3,0
 594:	bf85                	j	504 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 596:	008b0793          	addi	a5,s6,8
 59a:	f8f43423          	sd	a5,-120(s0)
 59e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5a2:	03000593          	li	a1,48
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	e2e080e7          	jalr	-466(ra) # 3d6 <putc>
  putc(fd, 'x');
 5b0:	07800593          	li	a1,120
 5b4:	8556                	mv	a0,s5
 5b6:	00000097          	auipc	ra,0x0
 5ba:	e20080e7          	jalr	-480(ra) # 3d6 <putc>
 5be:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5c0:	03c9d793          	srli	a5,s3,0x3c
 5c4:	97de                	add	a5,a5,s7
 5c6:	0007c583          	lbu	a1,0(a5)
 5ca:	8556                	mv	a0,s5
 5cc:	00000097          	auipc	ra,0x0
 5d0:	e0a080e7          	jalr	-502(ra) # 3d6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5d4:	0992                	slli	s3,s3,0x4
 5d6:	397d                	addiw	s2,s2,-1
 5d8:	fe0914e3          	bnez	s2,5c0 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5dc:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5e0:	4981                	li	s3,0
 5e2:	b70d                	j	504 <vprintf+0x60>
        s = va_arg(ap, char*);
 5e4:	008b0913          	addi	s2,s6,8
 5e8:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5ec:	02098163          	beqz	s3,60e <vprintf+0x16a>
        while(*s != 0){
 5f0:	0009c583          	lbu	a1,0(s3)
 5f4:	c5ad                	beqz	a1,65e <vprintf+0x1ba>
          putc(fd, *s);
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	dde080e7          	jalr	-546(ra) # 3d6 <putc>
          s++;
 600:	0985                	addi	s3,s3,1
        while(*s != 0){
 602:	0009c583          	lbu	a1,0(s3)
 606:	f9e5                	bnez	a1,5f6 <vprintf+0x152>
        s = va_arg(ap, char*);
 608:	8b4a                	mv	s6,s2
      state = 0;
 60a:	4981                	li	s3,0
 60c:	bde5                	j	504 <vprintf+0x60>
          s = "(null)";
 60e:	00000997          	auipc	s3,0x0
 612:	27298993          	addi	s3,s3,626 # 880 <malloc+0x118>
        while(*s != 0){
 616:	85ee                	mv	a1,s11
 618:	bff9                	j	5f6 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 61a:	008b0913          	addi	s2,s6,8
 61e:	000b4583          	lbu	a1,0(s6)
 622:	8556                	mv	a0,s5
 624:	00000097          	auipc	ra,0x0
 628:	db2080e7          	jalr	-590(ra) # 3d6 <putc>
 62c:	8b4a                	mv	s6,s2
      state = 0;
 62e:	4981                	li	s3,0
 630:	bdd1                	j	504 <vprintf+0x60>
        putc(fd, c);
 632:	85d2                	mv	a1,s4
 634:	8556                	mv	a0,s5
 636:	00000097          	auipc	ra,0x0
 63a:	da0080e7          	jalr	-608(ra) # 3d6 <putc>
      state = 0;
 63e:	4981                	li	s3,0
 640:	b5d1                	j	504 <vprintf+0x60>
        putc(fd, '%');
 642:	85d2                	mv	a1,s4
 644:	8556                	mv	a0,s5
 646:	00000097          	auipc	ra,0x0
 64a:	d90080e7          	jalr	-624(ra) # 3d6 <putc>
        putc(fd, c);
 64e:	85ca                	mv	a1,s2
 650:	8556                	mv	a0,s5
 652:	00000097          	auipc	ra,0x0
 656:	d84080e7          	jalr	-636(ra) # 3d6 <putc>
      state = 0;
 65a:	4981                	li	s3,0
 65c:	b565                	j	504 <vprintf+0x60>
        s = va_arg(ap, char*);
 65e:	8b4a                	mv	s6,s2
      state = 0;
 660:	4981                	li	s3,0
 662:	b54d                	j	504 <vprintf+0x60>
    }
  }
}
 664:	70e6                	ld	ra,120(sp)
 666:	7446                	ld	s0,112(sp)
 668:	74a6                	ld	s1,104(sp)
 66a:	7906                	ld	s2,96(sp)
 66c:	69e6                	ld	s3,88(sp)
 66e:	6a46                	ld	s4,80(sp)
 670:	6aa6                	ld	s5,72(sp)
 672:	6b06                	ld	s6,64(sp)
 674:	7be2                	ld	s7,56(sp)
 676:	7c42                	ld	s8,48(sp)
 678:	7ca2                	ld	s9,40(sp)
 67a:	7d02                	ld	s10,32(sp)
 67c:	6de2                	ld	s11,24(sp)
 67e:	6109                	addi	sp,sp,128
 680:	8082                	ret

0000000000000682 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 682:	715d                	addi	sp,sp,-80
 684:	ec06                	sd	ra,24(sp)
 686:	e822                	sd	s0,16(sp)
 688:	1000                	addi	s0,sp,32
 68a:	e010                	sd	a2,0(s0)
 68c:	e414                	sd	a3,8(s0)
 68e:	e818                	sd	a4,16(s0)
 690:	ec1c                	sd	a5,24(s0)
 692:	03043023          	sd	a6,32(s0)
 696:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 69a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 69e:	8622                	mv	a2,s0
 6a0:	00000097          	auipc	ra,0x0
 6a4:	e04080e7          	jalr	-508(ra) # 4a4 <vprintf>
}
 6a8:	60e2                	ld	ra,24(sp)
 6aa:	6442                	ld	s0,16(sp)
 6ac:	6161                	addi	sp,sp,80
 6ae:	8082                	ret

00000000000006b0 <printf>:

void
printf(const char *fmt, ...)
{
 6b0:	711d                	addi	sp,sp,-96
 6b2:	ec06                	sd	ra,24(sp)
 6b4:	e822                	sd	s0,16(sp)
 6b6:	1000                	addi	s0,sp,32
 6b8:	e40c                	sd	a1,8(s0)
 6ba:	e810                	sd	a2,16(s0)
 6bc:	ec14                	sd	a3,24(s0)
 6be:	f018                	sd	a4,32(s0)
 6c0:	f41c                	sd	a5,40(s0)
 6c2:	03043823          	sd	a6,48(s0)
 6c6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6ca:	00840613          	addi	a2,s0,8
 6ce:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6d2:	85aa                	mv	a1,a0
 6d4:	4505                	li	a0,1
 6d6:	00000097          	auipc	ra,0x0
 6da:	dce080e7          	jalr	-562(ra) # 4a4 <vprintf>
}
 6de:	60e2                	ld	ra,24(sp)
 6e0:	6442                	ld	s0,16(sp)
 6e2:	6125                	addi	sp,sp,96
 6e4:	8082                	ret

00000000000006e6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6e6:	1141                	addi	sp,sp,-16
 6e8:	e422                	sd	s0,8(sp)
 6ea:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ec:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6f0:	00001797          	auipc	a5,0x1
 6f4:	9107b783          	ld	a5,-1776(a5) # 1000 <freep>
 6f8:	a02d                	j	722 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6fa:	4618                	lw	a4,8(a2)
 6fc:	9f2d                	addw	a4,a4,a1
 6fe:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 702:	6398                	ld	a4,0(a5)
 704:	6310                	ld	a2,0(a4)
 706:	a83d                	j	744 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 708:	ff852703          	lw	a4,-8(a0)
 70c:	9f31                	addw	a4,a4,a2
 70e:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 710:	ff053683          	ld	a3,-16(a0)
 714:	a091                	j	758 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 716:	6398                	ld	a4,0(a5)
 718:	00e7e463          	bltu	a5,a4,720 <free+0x3a>
 71c:	00e6ea63          	bltu	a3,a4,730 <free+0x4a>
{
 720:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 722:	fed7fae3          	bgeu	a5,a3,716 <free+0x30>
 726:	6398                	ld	a4,0(a5)
 728:	00e6e463          	bltu	a3,a4,730 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 72c:	fee7eae3          	bltu	a5,a4,720 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 730:	ff852583          	lw	a1,-8(a0)
 734:	6390                	ld	a2,0(a5)
 736:	02059813          	slli	a6,a1,0x20
 73a:	01c85713          	srli	a4,a6,0x1c
 73e:	9736                	add	a4,a4,a3
 740:	fae60de3          	beq	a2,a4,6fa <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 744:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 748:	4790                	lw	a2,8(a5)
 74a:	02061593          	slli	a1,a2,0x20
 74e:	01c5d713          	srli	a4,a1,0x1c
 752:	973e                	add	a4,a4,a5
 754:	fae68ae3          	beq	a3,a4,708 <free+0x22>
    p->s.ptr = bp->s.ptr;
 758:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 75a:	00001717          	auipc	a4,0x1
 75e:	8af73323          	sd	a5,-1882(a4) # 1000 <freep>
}
 762:	6422                	ld	s0,8(sp)
 764:	0141                	addi	sp,sp,16
 766:	8082                	ret

0000000000000768 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 768:	7139                	addi	sp,sp,-64
 76a:	fc06                	sd	ra,56(sp)
 76c:	f822                	sd	s0,48(sp)
 76e:	f426                	sd	s1,40(sp)
 770:	f04a                	sd	s2,32(sp)
 772:	ec4e                	sd	s3,24(sp)
 774:	e852                	sd	s4,16(sp)
 776:	e456                	sd	s5,8(sp)
 778:	e05a                	sd	s6,0(sp)
 77a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 77c:	02051493          	slli	s1,a0,0x20
 780:	9081                	srli	s1,s1,0x20
 782:	04bd                	addi	s1,s1,15
 784:	8091                	srli	s1,s1,0x4
 786:	0014899b          	addiw	s3,s1,1
 78a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 78c:	00001517          	auipc	a0,0x1
 790:	87453503          	ld	a0,-1932(a0) # 1000 <freep>
 794:	c515                	beqz	a0,7c0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 796:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 798:	4798                	lw	a4,8(a5)
 79a:	02977f63          	bgeu	a4,s1,7d8 <malloc+0x70>
 79e:	8a4e                	mv	s4,s3
 7a0:	0009871b          	sext.w	a4,s3
 7a4:	6685                	lui	a3,0x1
 7a6:	00d77363          	bgeu	a4,a3,7ac <malloc+0x44>
 7aa:	6a05                	lui	s4,0x1
 7ac:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7b0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7b4:	00001917          	auipc	s2,0x1
 7b8:	84c90913          	addi	s2,s2,-1972 # 1000 <freep>
  if(p == (char*)-1)
 7bc:	5afd                	li	s5,-1
 7be:	a895                	j	832 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7c0:	00001797          	auipc	a5,0x1
 7c4:	85078793          	addi	a5,a5,-1968 # 1010 <base>
 7c8:	00001717          	auipc	a4,0x1
 7cc:	82f73c23          	sd	a5,-1992(a4) # 1000 <freep>
 7d0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7d2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7d6:	b7e1                	j	79e <malloc+0x36>
      if(p->s.size == nunits)
 7d8:	02e48c63          	beq	s1,a4,810 <malloc+0xa8>
        p->s.size -= nunits;
 7dc:	4137073b          	subw	a4,a4,s3
 7e0:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7e2:	02071693          	slli	a3,a4,0x20
 7e6:	01c6d713          	srli	a4,a3,0x1c
 7ea:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7ec:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7f0:	00001717          	auipc	a4,0x1
 7f4:	80a73823          	sd	a0,-2032(a4) # 1000 <freep>
      return (void*)(p + 1);
 7f8:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7fc:	70e2                	ld	ra,56(sp)
 7fe:	7442                	ld	s0,48(sp)
 800:	74a2                	ld	s1,40(sp)
 802:	7902                	ld	s2,32(sp)
 804:	69e2                	ld	s3,24(sp)
 806:	6a42                	ld	s4,16(sp)
 808:	6aa2                	ld	s5,8(sp)
 80a:	6b02                	ld	s6,0(sp)
 80c:	6121                	addi	sp,sp,64
 80e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 810:	6398                	ld	a4,0(a5)
 812:	e118                	sd	a4,0(a0)
 814:	bff1                	j	7f0 <malloc+0x88>
  hp->s.size = nu;
 816:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 81a:	0541                	addi	a0,a0,16
 81c:	00000097          	auipc	ra,0x0
 820:	eca080e7          	jalr	-310(ra) # 6e6 <free>
  return freep;
 824:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 828:	d971                	beqz	a0,7fc <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 82a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 82c:	4798                	lw	a4,8(a5)
 82e:	fa9775e3          	bgeu	a4,s1,7d8 <malloc+0x70>
    if(p == freep)
 832:	00093703          	ld	a4,0(s2)
 836:	853e                	mv	a0,a5
 838:	fef719e3          	bne	a4,a5,82a <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 83c:	8552                	mv	a0,s4
 83e:	00000097          	auipc	ra,0x0
 842:	b58080e7          	jalr	-1192(ra) # 396 <sbrk>
  if(p == (char*)-1)
 846:	fd5518e3          	bne	a0,s5,816 <malloc+0xae>
        return 0;
 84a:	4501                	li	a0,0
 84c:	bf45                	j	7fc <malloc+0x94>
