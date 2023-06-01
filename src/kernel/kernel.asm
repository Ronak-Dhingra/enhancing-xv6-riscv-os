
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	cc010113          	addi	sp,sp,-832 # 80008cc0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	b2e70713          	addi	a4,a4,-1234 # 80008b80 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	51c78793          	addi	a5,a5,1308 # 80006580 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffb59cf>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e5878793          	addi	a5,a5,-424 # 80000f06 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	902080e7          	jalr	-1790(ra) # 80002a2e <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
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
    8000018e:	b3650513          	addi	a0,a0,-1226 # 80010cc0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	ad2080e7          	jalr	-1326(ra) # 80000c64 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b2648493          	addi	s1,s1,-1242 # 80010cc0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	bb690913          	addi	s2,s2,-1098 # 80010d58 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	938080e7          	jalr	-1736(ra) # 80001af8 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	6b0080e7          	jalr	1712(ra) # 80002878 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	2a2080e7          	jalr	674(ra) # 80002478 <sleep>
    while(cons.r == cons.w){
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
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	7c6080e7          	jalr	1990(ra) # 800029d8 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	a9a50513          	addi	a0,a0,-1382 # 80010cc0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	aea080e7          	jalr	-1302(ra) # 80000d18 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	a8450513          	addi	a0,a0,-1404 # 80010cc0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	ad4080e7          	jalr	-1324(ra) # 80000d18 <release>
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
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	aef72323          	sw	a5,-1306(a4) # 80010d58 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
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
    800002d0:	9f450513          	addi	a0,a0,-1548 # 80010cc0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	990080e7          	jalr	-1648(ra) # 80000c64 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	792080e7          	jalr	1938(ra) # 80002a84 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	9c650513          	addi	a0,a0,-1594 # 80010cc0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	a16080e7          	jalr	-1514(ra) # 80000d18 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	9a270713          	addi	a4,a4,-1630 # 80010cc0 <cons>
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
    8000034c:	97878793          	addi	a5,a5,-1672 # 80010cc0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	9e27a783          	lw	a5,-1566(a5) # 80010d58 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	93670713          	addi	a4,a4,-1738 # 80010cc0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	92648493          	addi	s1,s1,-1754 # 80010cc0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	8ea70713          	addi	a4,a4,-1814 # 80010cc0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	96f72a23          	sw	a5,-1676(a4) # 80010d60 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	8ae78793          	addi	a5,a5,-1874 # 80010cc0 <cons>
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
    8000043a:	92c7a323          	sw	a2,-1754(a5) # 80010d5c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	91a50513          	addi	a0,a0,-1766 # 80010d58 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	1e2080e7          	jalr	482(ra) # 80002628 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	86050513          	addi	a0,a0,-1952 # 80010cc0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	76c080e7          	jalr	1900(ra) # 80000bd4 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00047797          	auipc	a5,0x47
    8000047c:	de078793          	addi	a5,a5,-544 # 80047258 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
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
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
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
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	8207ab23          	sw	zero,-1994(a5) # 80010d80 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	e2450513          	addi	a0,a0,-476 # 80008390 <states.0+0xa8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	5cf72123          	sw	a5,1474(a4) # 80008b40 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	7c6dad83          	lw	s11,1990(s11) # 80010d80 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	77050513          	addi	a0,a0,1904 # 80010d68 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	664080e7          	jalr	1636(ra) # 80000c64 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	61250513          	addi	a0,a0,1554 # 80010d68 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	5ba080e7          	jalr	1466(ra) # 80000d18 <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	5f648493          	addi	s1,s1,1526 # 80010d68 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	450080e7          	jalr	1104(ra) # 80000bd4 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	5b650513          	addi	a0,a0,1462 # 80010d88 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	3fa080e7          	jalr	1018(ra) # 80000bd4 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	422080e7          	jalr	1058(ra) # 80000c18 <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	3427a783          	lw	a5,834(a5) # 80008b40 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	494080e7          	jalr	1172(ra) # 80000cb8 <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	3127b783          	ld	a5,786(a5) # 80008b48 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	31273703          	ld	a4,786(a4) # 80008b50 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	528a0a13          	addi	s4,s4,1320 # 80010d88 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	2e048493          	addi	s1,s1,736 # 80008b48 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	2e098993          	addi	s3,s3,736 # 80008b50 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	d96080e7          	jalr	-618(ra) # 80002628 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	4ba50513          	addi	a0,a0,1210 # 80010d88 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	38e080e7          	jalr	910(ra) # 80000c64 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	2627a783          	lw	a5,610(a5) # 80008b40 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	26873703          	ld	a4,616(a4) # 80008b50 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	2587b783          	ld	a5,600(a5) # 80008b48 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	48c98993          	addi	s3,s3,1164 # 80010d88 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	24448493          	addi	s1,s1,580 # 80008b48 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	24490913          	addi	s2,s2,580 # 80008b50 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	b5c080e7          	jalr	-1188(ra) # 80002478 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	45648493          	addi	s1,s1,1110 # 80010d88 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	20e7b523          	sd	a4,522(a5) # 80008b50 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	3c0080e7          	jalr	960(ra) # 80000d18 <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	3cc48493          	addi	s1,s1,972 # 80010d88 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	29e080e7          	jalr	670(ra) # 80000c64 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	340080e7          	jalr	832(ra) # 80000d18 <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	e3b1                	bnez	a5,80000a3e <kfree+0x54>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00048797          	auipc	a5,0x48
    80000a02:	43278793          	addi	a5,a5,1074 # 80048e30 <end>
    80000a06:	02f56c63          	bltu	a0,a5,80000a3e <kfree+0x54>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	02f57863          	bgeu	a0,a5,80000a3e <kfree+0x54>
    panic("kfree");

  // Fill with junk to catch dangling refs.

  // START cow
  refIdx(pa)--;
    80000a12:	800007b7          	lui	a5,0x80000
    80000a16:	97aa                	add	a5,a5,a0
    80000a18:	83b1                	srli	a5,a5,0xc
    80000a1a:	078a                	slli	a5,a5,0x2
    80000a1c:	00010717          	auipc	a4,0x10
    80000a20:	3c470713          	addi	a4,a4,964 # 80010de0 <refCount>
    80000a24:	97ba                	add	a5,a5,a4
    80000a26:	4398                	lw	a4,0(a5)
    80000a28:	377d                	addiw	a4,a4,-1
    80000a2a:	0007069b          	sext.w	a3,a4
    80000a2e:	c398                	sw	a4,0(a5)
  if(refIdx(pa)==0){
    80000a30:	ce99                	beqz	a3,80000a4e <kfree+0x64>
    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
  }
}
    80000a32:	60e2                	ld	ra,24(sp)
    80000a34:	6442                	ld	s0,16(sp)
    80000a36:	64a2                	ld	s1,8(sp)
    80000a38:	6902                	ld	s2,0(sp)
    80000a3a:	6105                	addi	sp,sp,32
    80000a3c:	8082                	ret
    panic("kfree");
    80000a3e:	00007517          	auipc	a0,0x7
    80000a42:	62250513          	addi	a0,a0,1570 # 80008060 <digits+0x20>
    80000a46:	00000097          	auipc	ra,0x0
    80000a4a:	af8080e7          	jalr	-1288(ra) # 8000053e <panic>
    memset(pa, 1, PGSIZE);
    80000a4e:	6605                	lui	a2,0x1
    80000a50:	4585                	li	a1,1
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	30e080e7          	jalr	782(ra) # 80000d60 <memset>
    acquire(&kmem.lock);
    80000a5a:	00010917          	auipc	s2,0x10
    80000a5e:	36690913          	addi	s2,s2,870 # 80010dc0 <kmem>
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	200080e7          	jalr	512(ra) # 80000c64 <acquire>
    r->next = kmem.freelist;
    80000a6c:	01893783          	ld	a5,24(s2)
    80000a70:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a72:	00993c23          	sd	s1,24(s2)
    release(&kmem.lock);
    80000a76:	854a                	mv	a0,s2
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	2a0080e7          	jalr	672(ra) # 80000d18 <release>
}
    80000a80:	bf4d                	j	80000a32 <kfree+0x48>

0000000080000a82 <freerange>:
{
    80000a82:	715d                	addi	sp,sp,-80
    80000a84:	e486                	sd	ra,72(sp)
    80000a86:	e0a2                	sd	s0,64(sp)
    80000a88:	fc26                	sd	s1,56(sp)
    80000a8a:	f84a                	sd	s2,48(sp)
    80000a8c:	f44e                	sd	s3,40(sp)
    80000a8e:	f052                	sd	s4,32(sp)
    80000a90:	ec56                	sd	s5,24(sp)
    80000a92:	e85a                	sd	s6,16(sp)
    80000a94:	e45e                	sd	s7,8(sp)
    80000a96:	0880                	addi	s0,sp,80
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	94aa                	add	s1,s1,a0
    80000aa0:	757d                	lui	a0,0xfffff
    80000aa2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94be                	add	s1,s1,a5
    80000aa6:	0295ee63          	bltu	a1,s1,80000ae2 <freerange+0x60>
    80000aaa:	89ae                	mv	s3,a1
    refIdx(p) = 1;
    80000aac:	00010a97          	auipc	s5,0x10
    80000ab0:	334a8a93          	addi	s5,s5,820 # 80010de0 <refCount>
    80000ab4:	fff80937          	lui	s2,0xfff80
    80000ab8:	197d                	addi	s2,s2,-1
    80000aba:	0932                	slli	s2,s2,0xc
    80000abc:	4b85                	li	s7,1
    kfree(p);
    80000abe:	7b7d                	lui	s6,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6a05                	lui	s4,0x1
    refIdx(p) = 1;
    80000ac2:	012487b3          	add	a5,s1,s2
    80000ac6:	83b1                	srli	a5,a5,0xc
    80000ac8:	078a                	slli	a5,a5,0x2
    80000aca:	97d6                	add	a5,a5,s5
    80000acc:	0177a023          	sw	s7,0(a5)
    kfree(p);
    80000ad0:	01648533          	add	a0,s1,s6
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	f16080e7          	jalr	-234(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000adc:	94d2                	add	s1,s1,s4
    80000ade:	fe99f2e3          	bgeu	s3,s1,80000ac2 <freerange+0x40>
}
    80000ae2:	60a6                	ld	ra,72(sp)
    80000ae4:	6406                	ld	s0,64(sp)
    80000ae6:	74e2                	ld	s1,56(sp)
    80000ae8:	7942                	ld	s2,48(sp)
    80000aea:	79a2                	ld	s3,40(sp)
    80000aec:	7a02                	ld	s4,32(sp)
    80000aee:	6ae2                	ld	s5,24(sp)
    80000af0:	6b42                	ld	s6,16(sp)
    80000af2:	6ba2                	ld	s7,8(sp)
    80000af4:	6161                	addi	sp,sp,80
    80000af6:	8082                	ret

0000000080000af8 <kinit>:
{
    80000af8:	1141                	addi	sp,sp,-16
    80000afa:	e406                	sd	ra,8(sp)
    80000afc:	e022                	sd	s0,0(sp)
    80000afe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b00:	00007597          	auipc	a1,0x7
    80000b04:	56858593          	addi	a1,a1,1384 # 80008068 <digits+0x28>
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	2b850513          	addi	a0,a0,696 # 80010dc0 <kmem>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	0c4080e7          	jalr	196(ra) # 80000bd4 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b18:	45c5                	li	a1,17
    80000b1a:	05ee                	slli	a1,a1,0x1b
    80000b1c:	00048517          	auipc	a0,0x48
    80000b20:	31450513          	addi	a0,a0,788 # 80048e30 <end>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	f5e080e7          	jalr	-162(ra) # 80000a82 <freerange>
}
    80000b2c:	60a2                	ld	ra,8(sp)
    80000b2e:	6402                	ld	s0,0(sp)
    80000b30:	0141                	addi	sp,sp,16
    80000b32:	8082                	ret

0000000080000b34 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b34:	1101                	addi	sp,sp,-32
    80000b36:	ec06                	sd	ra,24(sp)
    80000b38:	e822                	sd	s0,16(sp)
    80000b3a:	e426                	sd	s1,8(sp)
    80000b3c:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b3e:	00010497          	auipc	s1,0x10
    80000b42:	28248493          	addi	s1,s1,642 # 80010dc0 <kmem>
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	11c080e7          	jalr	284(ra) # 80000c64 <acquire>
  r = kmem.freelist;
    80000b50:	6c84                	ld	s1,24(s1)
  if(r)
    80000b52:	c4a9                	beqz	s1,80000b9c <kalloc+0x68>
    kmem.freelist = r->next;
    80000b54:	609c                	ld	a5,0(s1)
    80000b56:	00010517          	auipc	a0,0x10
    80000b5a:	26a50513          	addi	a0,a0,618 # 80010dc0 <kmem>
    80000b5e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	1b8080e7          	jalr	440(ra) # 80000d18 <release>

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b68:	6605                	lui	a2,0x1
    80000b6a:	4595                	li	a1,5
    80000b6c:	8526                	mv	a0,s1
    80000b6e:	00000097          	auipc	ra,0x0
    80000b72:	1f2080e7          	jalr	498(ra) # 80000d60 <memset>
    refIdx(r)++;
    80000b76:	800007b7          	lui	a5,0x80000
    80000b7a:	97a6                	add	a5,a5,s1
    80000b7c:	83b1                	srli	a5,a5,0xc
    80000b7e:	078a                	slli	a5,a5,0x2
    80000b80:	00010717          	auipc	a4,0x10
    80000b84:	26070713          	addi	a4,a4,608 # 80010de0 <refCount>
    80000b88:	97ba                	add	a5,a5,a4
    80000b8a:	4398                	lw	a4,0(a5)
    80000b8c:	2705                	addiw	a4,a4,1
    80000b8e:	c398                	sw	a4,0(a5)
  }
  return (void*)r;
}
    80000b90:	8526                	mv	a0,s1
    80000b92:	60e2                	ld	ra,24(sp)
    80000b94:	6442                	ld	s0,16(sp)
    80000b96:	64a2                	ld	s1,8(sp)
    80000b98:	6105                	addi	sp,sp,32
    80000b9a:	8082                	ret
  release(&kmem.lock);
    80000b9c:	00010517          	auipc	a0,0x10
    80000ba0:	22450513          	addi	a0,a0,548 # 80010dc0 <kmem>
    80000ba4:	00000097          	auipc	ra,0x0
    80000ba8:	174080e7          	jalr	372(ra) # 80000d18 <release>
  if(r){
    80000bac:	b7d5                	j	80000b90 <kalloc+0x5c>

0000000080000bae <refInc>:

void refInc(uint64 pa){
    80000bae:	1141                	addi	sp,sp,-16
    80000bb0:	e422                	sd	s0,8(sp)
    80000bb2:	0800                	addi	s0,sp,16
  refIdx(pa) = refIdx(pa) + 1;
    80000bb4:	800007b7          	lui	a5,0x80000
    80000bb8:	953e                	add	a0,a0,a5
    80000bba:	8131                	srli	a0,a0,0xc
    80000bbc:	050a                	slli	a0,a0,0x2
    80000bbe:	00010797          	auipc	a5,0x10
    80000bc2:	22278793          	addi	a5,a5,546 # 80010de0 <refCount>
    80000bc6:	953e                	add	a0,a0,a5
    80000bc8:	411c                	lw	a5,0(a0)
    80000bca:	2785                	addiw	a5,a5,1
    80000bcc:	c11c                	sw	a5,0(a0)
}
    80000bce:	6422                	ld	s0,8(sp)
    80000bd0:	0141                	addi	sp,sp,16
    80000bd2:	8082                	ret

0000000080000bd4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bd4:	1141                	addi	sp,sp,-16
    80000bd6:	e422                	sd	s0,8(sp)
    80000bd8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bda:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bdc:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000be0:	00053823          	sd	zero,16(a0)
}
    80000be4:	6422                	ld	s0,8(sp)
    80000be6:	0141                	addi	sp,sp,16
    80000be8:	8082                	ret

0000000080000bea <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bea:	411c                	lw	a5,0(a0)
    80000bec:	e399                	bnez	a5,80000bf2 <holding+0x8>
    80000bee:	4501                	li	a0,0
  return r;
}
    80000bf0:	8082                	ret
{
    80000bf2:	1101                	addi	sp,sp,-32
    80000bf4:	ec06                	sd	ra,24(sp)
    80000bf6:	e822                	sd	s0,16(sp)
    80000bf8:	e426                	sd	s1,8(sp)
    80000bfa:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bfc:	6904                	ld	s1,16(a0)
    80000bfe:	00001097          	auipc	ra,0x1
    80000c02:	ede080e7          	jalr	-290(ra) # 80001adc <mycpu>
    80000c06:	40a48533          	sub	a0,s1,a0
    80000c0a:	00153513          	seqz	a0,a0
}
    80000c0e:	60e2                	ld	ra,24(sp)
    80000c10:	6442                	ld	s0,16(sp)
    80000c12:	64a2                	ld	s1,8(sp)
    80000c14:	6105                	addi	sp,sp,32
    80000c16:	8082                	ret

0000000080000c18 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c18:	1101                	addi	sp,sp,-32
    80000c1a:	ec06                	sd	ra,24(sp)
    80000c1c:	e822                	sd	s0,16(sp)
    80000c1e:	e426                	sd	s1,8(sp)
    80000c20:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c22:	100024f3          	csrr	s1,sstatus
    80000c26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c2a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c2c:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c30:	00001097          	auipc	ra,0x1
    80000c34:	eac080e7          	jalr	-340(ra) # 80001adc <mycpu>
    80000c38:	5d3c                	lw	a5,120(a0)
    80000c3a:	cf89                	beqz	a5,80000c54 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c3c:	00001097          	auipc	ra,0x1
    80000c40:	ea0080e7          	jalr	-352(ra) # 80001adc <mycpu>
    80000c44:	5d3c                	lw	a5,120(a0)
    80000c46:	2785                	addiw	a5,a5,1
    80000c48:	dd3c                	sw	a5,120(a0)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    mycpu()->intena = old;
    80000c54:	00001097          	auipc	ra,0x1
    80000c58:	e88080e7          	jalr	-376(ra) # 80001adc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c5c:	8085                	srli	s1,s1,0x1
    80000c5e:	8885                	andi	s1,s1,1
    80000c60:	dd64                	sw	s1,124(a0)
    80000c62:	bfe9                	j	80000c3c <push_off+0x24>

0000000080000c64 <acquire>:
{
    80000c64:	1101                	addi	sp,sp,-32
    80000c66:	ec06                	sd	ra,24(sp)
    80000c68:	e822                	sd	s0,16(sp)
    80000c6a:	e426                	sd	s1,8(sp)
    80000c6c:	1000                	addi	s0,sp,32
    80000c6e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	fa8080e7          	jalr	-88(ra) # 80000c18 <push_off>
  if(holding(lk))
    80000c78:	8526                	mv	a0,s1
    80000c7a:	00000097          	auipc	ra,0x0
    80000c7e:	f70080e7          	jalr	-144(ra) # 80000bea <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c82:	4705                	li	a4,1
  if(holding(lk))
    80000c84:	e115                	bnez	a0,80000ca8 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c86:	87ba                	mv	a5,a4
    80000c88:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c8c:	2781                	sext.w	a5,a5
    80000c8e:	ffe5                	bnez	a5,80000c86 <acquire+0x22>
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c94:	00001097          	auipc	ra,0x1
    80000c98:	e48080e7          	jalr	-440(ra) # 80001adc <mycpu>
    80000c9c:	e888                	sd	a0,16(s1)
}
    80000c9e:	60e2                	ld	ra,24(sp)
    80000ca0:	6442                	ld	s0,16(sp)
    80000ca2:	64a2                	ld	s1,8(sp)
    80000ca4:	6105                	addi	sp,sp,32
    80000ca6:	8082                	ret
    panic("acquire");
    80000ca8:	00007517          	auipc	a0,0x7
    80000cac:	3c850513          	addi	a0,a0,968 # 80008070 <digits+0x30>
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	88e080e7          	jalr	-1906(ra) # 8000053e <panic>

0000000080000cb8 <pop_off>:

void
pop_off(void)
{
    80000cb8:	1141                	addi	sp,sp,-16
    80000cba:	e406                	sd	ra,8(sp)
    80000cbc:	e022                	sd	s0,0(sp)
    80000cbe:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cc0:	00001097          	auipc	ra,0x1
    80000cc4:	e1c080e7          	jalr	-484(ra) # 80001adc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ccc:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cce:	e78d                	bnez	a5,80000cf8 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cd0:	5d3c                	lw	a5,120(a0)
    80000cd2:	02f05b63          	blez	a5,80000d08 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cd6:	37fd                	addiw	a5,a5,-1
    80000cd8:	0007871b          	sext.w	a4,a5
    80000cdc:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cde:	eb09                	bnez	a4,80000cf0 <pop_off+0x38>
    80000ce0:	5d7c                	lw	a5,124(a0)
    80000ce2:	c799                	beqz	a5,80000cf0 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ce8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cec:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cf0:	60a2                	ld	ra,8(sp)
    80000cf2:	6402                	ld	s0,0(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret
    panic("pop_off - interruptible");
    80000cf8:	00007517          	auipc	a0,0x7
    80000cfc:	38050513          	addi	a0,a0,896 # 80008078 <digits+0x38>
    80000d00:	00000097          	auipc	ra,0x0
    80000d04:	83e080e7          	jalr	-1986(ra) # 8000053e <panic>
    panic("pop_off");
    80000d08:	00007517          	auipc	a0,0x7
    80000d0c:	38850513          	addi	a0,a0,904 # 80008090 <digits+0x50>
    80000d10:	00000097          	auipc	ra,0x0
    80000d14:	82e080e7          	jalr	-2002(ra) # 8000053e <panic>

0000000080000d18 <release>:
{
    80000d18:	1101                	addi	sp,sp,-32
    80000d1a:	ec06                	sd	ra,24(sp)
    80000d1c:	e822                	sd	s0,16(sp)
    80000d1e:	e426                	sd	s1,8(sp)
    80000d20:	1000                	addi	s0,sp,32
    80000d22:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d24:	00000097          	auipc	ra,0x0
    80000d28:	ec6080e7          	jalr	-314(ra) # 80000bea <holding>
    80000d2c:	c115                	beqz	a0,80000d50 <release+0x38>
  lk->cpu = 0;
    80000d2e:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d32:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d36:	0f50000f          	fence	iorw,ow
    80000d3a:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d3e:	00000097          	auipc	ra,0x0
    80000d42:	f7a080e7          	jalr	-134(ra) # 80000cb8 <pop_off>
}
    80000d46:	60e2                	ld	ra,24(sp)
    80000d48:	6442                	ld	s0,16(sp)
    80000d4a:	64a2                	ld	s1,8(sp)
    80000d4c:	6105                	addi	sp,sp,32
    80000d4e:	8082                	ret
    panic("release");
    80000d50:	00007517          	auipc	a0,0x7
    80000d54:	34850513          	addi	a0,a0,840 # 80008098 <digits+0x58>
    80000d58:	fffff097          	auipc	ra,0xfffff
    80000d5c:	7e6080e7          	jalr	2022(ra) # 8000053e <panic>

0000000080000d60 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d60:	1141                	addi	sp,sp,-16
    80000d62:	e422                	sd	s0,8(sp)
    80000d64:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d66:	ca19                	beqz	a2,80000d7c <memset+0x1c>
    80000d68:	87aa                	mv	a5,a0
    80000d6a:	1602                	slli	a2,a2,0x20
    80000d6c:	9201                	srli	a2,a2,0x20
    80000d6e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d72:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d76:	0785                	addi	a5,a5,1
    80000d78:	fee79de3          	bne	a5,a4,80000d72 <memset+0x12>
  }
  return dst;
}
    80000d7c:	6422                	ld	s0,8(sp)
    80000d7e:	0141                	addi	sp,sp,16
    80000d80:	8082                	ret

0000000080000d82 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d82:	1141                	addi	sp,sp,-16
    80000d84:	e422                	sd	s0,8(sp)
    80000d86:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d88:	ca05                	beqz	a2,80000db8 <memcmp+0x36>
    80000d8a:	fff6069b          	addiw	a3,a2,-1
    80000d8e:	1682                	slli	a3,a3,0x20
    80000d90:	9281                	srli	a3,a3,0x20
    80000d92:	0685                	addi	a3,a3,1
    80000d94:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d96:	00054783          	lbu	a5,0(a0)
    80000d9a:	0005c703          	lbu	a4,0(a1)
    80000d9e:	00e79863          	bne	a5,a4,80000dae <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000da2:	0505                	addi	a0,a0,1
    80000da4:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da6:	fed518e3          	bne	a0,a3,80000d96 <memcmp+0x14>
  }

  return 0;
    80000daa:	4501                	li	a0,0
    80000dac:	a019                	j	80000db2 <memcmp+0x30>
      return *s1 - *s2;
    80000dae:	40e7853b          	subw	a0,a5,a4
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret
  return 0;
    80000db8:	4501                	li	a0,0
    80000dba:	bfe5                	j	80000db2 <memcmp+0x30>

0000000080000dbc <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dbc:	1141                	addi	sp,sp,-16
    80000dbe:	e422                	sd	s0,8(sp)
    80000dc0:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dc2:	c205                	beqz	a2,80000de2 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dc4:	02a5e263          	bltu	a1,a0,80000de8 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dc8:	1602                	slli	a2,a2,0x20
    80000dca:	9201                	srli	a2,a2,0x20
    80000dcc:	00c587b3          	add	a5,a1,a2
{
    80000dd0:	872a                	mv	a4,a0
      *d++ = *s++;
    80000dd2:	0585                	addi	a1,a1,1
    80000dd4:	0705                	addi	a4,a4,1
    80000dd6:	fff5c683          	lbu	a3,-1(a1)
    80000dda:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dde:	fef59ae3          	bne	a1,a5,80000dd2 <memmove+0x16>

  return dst;
}
    80000de2:	6422                	ld	s0,8(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret
  if(s < d && s + n > d){
    80000de8:	02061693          	slli	a3,a2,0x20
    80000dec:	9281                	srli	a3,a3,0x20
    80000dee:	00d58733          	add	a4,a1,a3
    80000df2:	fce57be3          	bgeu	a0,a4,80000dc8 <memmove+0xc>
    d += n;
    80000df6:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000df8:	fff6079b          	addiw	a5,a2,-1
    80000dfc:	1782                	slli	a5,a5,0x20
    80000dfe:	9381                	srli	a5,a5,0x20
    80000e00:	fff7c793          	not	a5,a5
    80000e04:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e06:	177d                	addi	a4,a4,-1
    80000e08:	16fd                	addi	a3,a3,-1
    80000e0a:	00074603          	lbu	a2,0(a4)
    80000e0e:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e12:	fee79ae3          	bne	a5,a4,80000e06 <memmove+0x4a>
    80000e16:	b7f1                	j	80000de2 <memmove+0x26>

0000000080000e18 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e18:	1141                	addi	sp,sp,-16
    80000e1a:	e406                	sd	ra,8(sp)
    80000e1c:	e022                	sd	s0,0(sp)
    80000e1e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e20:	00000097          	auipc	ra,0x0
    80000e24:	f9c080e7          	jalr	-100(ra) # 80000dbc <memmove>
}
    80000e28:	60a2                	ld	ra,8(sp)
    80000e2a:	6402                	ld	s0,0(sp)
    80000e2c:	0141                	addi	sp,sp,16
    80000e2e:	8082                	ret

0000000080000e30 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e30:	1141                	addi	sp,sp,-16
    80000e32:	e422                	sd	s0,8(sp)
    80000e34:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e36:	ce11                	beqz	a2,80000e52 <strncmp+0x22>
    80000e38:	00054783          	lbu	a5,0(a0)
    80000e3c:	cf89                	beqz	a5,80000e56 <strncmp+0x26>
    80000e3e:	0005c703          	lbu	a4,0(a1)
    80000e42:	00f71a63          	bne	a4,a5,80000e56 <strncmp+0x26>
    n--, p++, q++;
    80000e46:	367d                	addiw	a2,a2,-1
    80000e48:	0505                	addi	a0,a0,1
    80000e4a:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4c:	f675                	bnez	a2,80000e38 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e4e:	4501                	li	a0,0
    80000e50:	a809                	j	80000e62 <strncmp+0x32>
    80000e52:	4501                	li	a0,0
    80000e54:	a039                	j	80000e62 <strncmp+0x32>
  if(n == 0)
    80000e56:	ca09                	beqz	a2,80000e68 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e58:	00054503          	lbu	a0,0(a0)
    80000e5c:	0005c783          	lbu	a5,0(a1)
    80000e60:	9d1d                	subw	a0,a0,a5
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
    return 0;
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strncmp+0x32>

0000000080000e6c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e422                	sd	s0,8(sp)
    80000e70:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e72:	872a                	mv	a4,a0
    80000e74:	8832                	mv	a6,a2
    80000e76:	367d                	addiw	a2,a2,-1
    80000e78:	01005963          	blez	a6,80000e8a <strncpy+0x1e>
    80000e7c:	0705                	addi	a4,a4,1
    80000e7e:	0005c783          	lbu	a5,0(a1)
    80000e82:	fef70fa3          	sb	a5,-1(a4)
    80000e86:	0585                	addi	a1,a1,1
    80000e88:	f7f5                	bnez	a5,80000e74 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e8a:	86ba                	mv	a3,a4
    80000e8c:	00c05c63          	blez	a2,80000ea4 <strncpy+0x38>
    *s++ = 0;
    80000e90:	0685                	addi	a3,a3,1
    80000e92:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e96:	fff6c793          	not	a5,a3
    80000e9a:	9fb9                	addw	a5,a5,a4
    80000e9c:	010787bb          	addw	a5,a5,a6
    80000ea0:	fef048e3          	bgtz	a5,80000e90 <strncpy+0x24>
  return os;
}
    80000ea4:	6422                	ld	s0,8(sp)
    80000ea6:	0141                	addi	sp,sp,16
    80000ea8:	8082                	ret

0000000080000eaa <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eaa:	1141                	addi	sp,sp,-16
    80000eac:	e422                	sd	s0,8(sp)
    80000eae:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb0:	02c05363          	blez	a2,80000ed6 <safestrcpy+0x2c>
    80000eb4:	fff6069b          	addiw	a3,a2,-1
    80000eb8:	1682                	slli	a3,a3,0x20
    80000eba:	9281                	srli	a3,a3,0x20
    80000ebc:	96ae                	add	a3,a3,a1
    80000ebe:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec0:	00d58963          	beq	a1,a3,80000ed2 <safestrcpy+0x28>
    80000ec4:	0585                	addi	a1,a1,1
    80000ec6:	0785                	addi	a5,a5,1
    80000ec8:	fff5c703          	lbu	a4,-1(a1)
    80000ecc:	fee78fa3          	sb	a4,-1(a5)
    80000ed0:	fb65                	bnez	a4,80000ec0 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed2:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed6:	6422                	ld	s0,8(sp)
    80000ed8:	0141                	addi	sp,sp,16
    80000eda:	8082                	ret

0000000080000edc <strlen>:

int
strlen(const char *s)
{
    80000edc:	1141                	addi	sp,sp,-16
    80000ede:	e422                	sd	s0,8(sp)
    80000ee0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee2:	00054783          	lbu	a5,0(a0)
    80000ee6:	cf91                	beqz	a5,80000f02 <strlen+0x26>
    80000ee8:	0505                	addi	a0,a0,1
    80000eea:	87aa                	mv	a5,a0
    80000eec:	4685                	li	a3,1
    80000eee:	9e89                	subw	a3,a3,a0
    80000ef0:	00f6853b          	addw	a0,a3,a5
    80000ef4:	0785                	addi	a5,a5,1
    80000ef6:	fff7c703          	lbu	a4,-1(a5)
    80000efa:	fb7d                	bnez	a4,80000ef0 <strlen+0x14>
    ;
  return n;
}
    80000efc:	6422                	ld	s0,8(sp)
    80000efe:	0141                	addi	sp,sp,16
    80000f00:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f02:	4501                	li	a0,0
    80000f04:	bfe5                	j	80000efc <strlen+0x20>

0000000080000f06 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f06:	1141                	addi	sp,sp,-16
    80000f08:	e406                	sd	ra,8(sp)
    80000f0a:	e022                	sd	s0,0(sp)
    80000f0c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f0e:	00001097          	auipc	ra,0x1
    80000f12:	bbe080e7          	jalr	-1090(ra) # 80001acc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f16:	00008717          	auipc	a4,0x8
    80000f1a:	c4270713          	addi	a4,a4,-958 # 80008b58 <started>
  if(cpuid() == 0){
    80000f1e:	c139                	beqz	a0,80000f64 <main+0x5e>
    while(started == 0)
    80000f20:	431c                	lw	a5,0(a4)
    80000f22:	2781                	sext.w	a5,a5
    80000f24:	dff5                	beqz	a5,80000f20 <main+0x1a>
      ;
    __sync_synchronize();
    80000f26:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	ba2080e7          	jalr	-1118(ra) # 80001acc <cpuid>
    80000f32:	85aa                	mv	a1,a0
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	18450513          	addi	a0,a0,388 # 800080b8 <digits+0x78>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	64c080e7          	jalr	1612(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	0d8080e7          	jalr	216(ra) # 8000101c <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	cf0080e7          	jalr	-784(ra) # 80002c3c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f54:	00005097          	auipc	ra,0x5
    80000f58:	66c080e7          	jalr	1644(ra) # 800065c0 <plicinithart>
  }
  #ifdef MLFQ
  initialize_queue();
  #endif
  scheduler();        
    80000f5c:	00001097          	auipc	ra,0x1
    80000f60:	270080e7          	jalr	624(ra) # 800021cc <scheduler>
    consoleinit();
    80000f64:	fffff097          	auipc	ra,0xfffff
    80000f68:	4ec080e7          	jalr	1260(ra) # 80000450 <consoleinit>
    printfinit();
    80000f6c:	fffff097          	auipc	ra,0xfffff
    80000f70:	7fc080e7          	jalr	2044(ra) # 80000768 <printfinit>
    printf("\n");
    80000f74:	00007517          	auipc	a0,0x7
    80000f78:	41c50513          	addi	a0,a0,1052 # 80008390 <states.0+0xa8>
    80000f7c:	fffff097          	auipc	ra,0xfffff
    80000f80:	60c080e7          	jalr	1548(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f84:	00007517          	auipc	a0,0x7
    80000f88:	11c50513          	addi	a0,a0,284 # 800080a0 <digits+0x60>
    80000f8c:	fffff097          	auipc	ra,0xfffff
    80000f90:	5fc080e7          	jalr	1532(ra) # 80000588 <printf>
    printf("\n");
    80000f94:	00007517          	auipc	a0,0x7
    80000f98:	3fc50513          	addi	a0,a0,1020 # 80008390 <states.0+0xa8>
    80000f9c:	fffff097          	auipc	ra,0xfffff
    80000fa0:	5ec080e7          	jalr	1516(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000fa4:	00000097          	auipc	ra,0x0
    80000fa8:	b54080e7          	jalr	-1196(ra) # 80000af8 <kinit>
    kvminit();       // create kernel page table
    80000fac:	00000097          	auipc	ra,0x0
    80000fb0:	32c080e7          	jalr	812(ra) # 800012d8 <kvminit>
    kvminithart();   // turn on paging
    80000fb4:	00000097          	auipc	ra,0x0
    80000fb8:	068080e7          	jalr	104(ra) # 8000101c <kvminithart>
    procinit();      // process table
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	a16080e7          	jalr	-1514(ra) # 800019d2 <procinit>
    trapinit();      // trap vectors
    80000fc4:	00002097          	auipc	ra,0x2
    80000fc8:	c50080e7          	jalr	-944(ra) # 80002c14 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fcc:	00002097          	auipc	ra,0x2
    80000fd0:	c70080e7          	jalr	-912(ra) # 80002c3c <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd4:	00005097          	auipc	ra,0x5
    80000fd8:	5d6080e7          	jalr	1494(ra) # 800065aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fdc:	00005097          	auipc	ra,0x5
    80000fe0:	5e4080e7          	jalr	1508(ra) # 800065c0 <plicinithart>
    binit();         // buffer cache
    80000fe4:	00002097          	auipc	ra,0x2
    80000fe8:	786080e7          	jalr	1926(ra) # 8000376a <binit>
    iinit();         // inode table
    80000fec:	00003097          	auipc	ra,0x3
    80000ff0:	e2a080e7          	jalr	-470(ra) # 80003e16 <iinit>
    fileinit();      // file table
    80000ff4:	00004097          	auipc	ra,0x4
    80000ff8:	dc8080e7          	jalr	-568(ra) # 80004dbc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffc:	00005097          	auipc	ra,0x5
    80001000:	6cc080e7          	jalr	1740(ra) # 800066c8 <virtio_disk_init>
    userinit();      // first user process
    80001004:	00001097          	auipc	ra,0x1
    80001008:	e56080e7          	jalr	-426(ra) # 80001e5a <userinit>
    __sync_synchronize();
    8000100c:	0ff0000f          	fence
    started = 1;
    80001010:	4785                	li	a5,1
    80001012:	00008717          	auipc	a4,0x8
    80001016:	b4f72323          	sw	a5,-1210(a4) # 80008b58 <started>
    8000101a:	b789                	j	80000f5c <main+0x56>

000000008000101c <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101c:	1141                	addi	sp,sp,-16
    8000101e:	e422                	sd	s0,8(sp)
    80001020:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001022:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001026:	00008797          	auipc	a5,0x8
    8000102a:	b3a7b783          	ld	a5,-1222(a5) # 80008b60 <kernel_pagetable>
    8000102e:	83b1                	srli	a5,a5,0xc
    80001030:	577d                	li	a4,-1
    80001032:	177e                	slli	a4,a4,0x3f
    80001034:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001036:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000103a:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000103e:	6422                	ld	s0,8(sp)
    80001040:	0141                	addi	sp,sp,16
    80001042:	8082                	ret

0000000080001044 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001044:	7139                	addi	sp,sp,-64
    80001046:	fc06                	sd	ra,56(sp)
    80001048:	f822                	sd	s0,48(sp)
    8000104a:	f426                	sd	s1,40(sp)
    8000104c:	f04a                	sd	s2,32(sp)
    8000104e:	ec4e                	sd	s3,24(sp)
    80001050:	e852                	sd	s4,16(sp)
    80001052:	e456                	sd	s5,8(sp)
    80001054:	e05a                	sd	s6,0(sp)
    80001056:	0080                	addi	s0,sp,64
    80001058:	84aa                	mv	s1,a0
    8000105a:	89ae                	mv	s3,a1
    8000105c:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000105e:	57fd                	li	a5,-1
    80001060:	83e9                	srli	a5,a5,0x1a
    80001062:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001064:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001066:	04b7f263          	bgeu	a5,a1,800010aa <walk+0x66>
    panic("walk");
    8000106a:	00007517          	auipc	a0,0x7
    8000106e:	06650513          	addi	a0,a0,102 # 800080d0 <digits+0x90>
    80001072:	fffff097          	auipc	ra,0xfffff
    80001076:	4cc080e7          	jalr	1228(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000107a:	060a8663          	beqz	s5,800010e6 <walk+0xa2>
    8000107e:	00000097          	auipc	ra,0x0
    80001082:	ab6080e7          	jalr	-1354(ra) # 80000b34 <kalloc>
    80001086:	84aa                	mv	s1,a0
    80001088:	c529                	beqz	a0,800010d2 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000108a:	6605                	lui	a2,0x1
    8000108c:	4581                	li	a1,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	cd2080e7          	jalr	-814(ra) # 80000d60 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001096:	00c4d793          	srli	a5,s1,0xc
    8000109a:	07aa                	slli	a5,a5,0xa
    8000109c:	0017e793          	ori	a5,a5,1
    800010a0:	00f93023          	sd	a5,0(s2) # fffffffffff80000 <end+0xffffffff7ff371d0>
  for(int level = 2; level > 0; level--) {
    800010a4:	3a5d                	addiw	s4,s4,-9
    800010a6:	036a0063          	beq	s4,s6,800010c6 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010aa:	0149d933          	srl	s2,s3,s4
    800010ae:	1ff97913          	andi	s2,s2,511
    800010b2:	090e                	slli	s2,s2,0x3
    800010b4:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b6:	00093483          	ld	s1,0(s2)
    800010ba:	0014f793          	andi	a5,s1,1
    800010be:	dfd5                	beqz	a5,8000107a <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010c0:	80a9                	srli	s1,s1,0xa
    800010c2:	04b2                	slli	s1,s1,0xc
    800010c4:	b7c5                	j	800010a4 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c6:	00c9d513          	srli	a0,s3,0xc
    800010ca:	1ff57513          	andi	a0,a0,511
    800010ce:	050e                	slli	a0,a0,0x3
    800010d0:	9526                	add	a0,a0,s1
}
    800010d2:	70e2                	ld	ra,56(sp)
    800010d4:	7442                	ld	s0,48(sp)
    800010d6:	74a2                	ld	s1,40(sp)
    800010d8:	7902                	ld	s2,32(sp)
    800010da:	69e2                	ld	s3,24(sp)
    800010dc:	6a42                	ld	s4,16(sp)
    800010de:	6aa2                	ld	s5,8(sp)
    800010e0:	6b02                	ld	s6,0(sp)
    800010e2:	6121                	addi	sp,sp,64
    800010e4:	8082                	ret
        return 0;
    800010e6:	4501                	li	a0,0
    800010e8:	b7ed                	j	800010d2 <walk+0x8e>

00000000800010ea <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010ea:	57fd                	li	a5,-1
    800010ec:	83e9                	srli	a5,a5,0x1a
    800010ee:	00b7f463          	bgeu	a5,a1,800010f6 <walkaddr+0xc>
    return 0;
    800010f2:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f4:	8082                	ret
{
    800010f6:	1141                	addi	sp,sp,-16
    800010f8:	e406                	sd	ra,8(sp)
    800010fa:	e022                	sd	s0,0(sp)
    800010fc:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010fe:	4601                	li	a2,0
    80001100:	00000097          	auipc	ra,0x0
    80001104:	f44080e7          	jalr	-188(ra) # 80001044 <walk>
  if(pte == 0)
    80001108:	c105                	beqz	a0,80001128 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000110a:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000110c:	0117f693          	andi	a3,a5,17
    80001110:	4745                	li	a4,17
    return 0;
    80001112:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001114:	00e68663          	beq	a3,a4,80001120 <walkaddr+0x36>
}
    80001118:	60a2                	ld	ra,8(sp)
    8000111a:	6402                	ld	s0,0(sp)
    8000111c:	0141                	addi	sp,sp,16
    8000111e:	8082                	ret
  pa = PTE2PA(*pte);
    80001120:	00a7d513          	srli	a0,a5,0xa
    80001124:	0532                	slli	a0,a0,0xc
  return pa;
    80001126:	bfcd                	j	80001118 <walkaddr+0x2e>
    return 0;
    80001128:	4501                	li	a0,0
    8000112a:	b7fd                	j	80001118 <walkaddr+0x2e>

000000008000112c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000112c:	715d                	addi	sp,sp,-80
    8000112e:	e486                	sd	ra,72(sp)
    80001130:	e0a2                	sd	s0,64(sp)
    80001132:	fc26                	sd	s1,56(sp)
    80001134:	f84a                	sd	s2,48(sp)
    80001136:	f44e                	sd	s3,40(sp)
    80001138:	f052                	sd	s4,32(sp)
    8000113a:	ec56                	sd	s5,24(sp)
    8000113c:	e85a                	sd	s6,16(sp)
    8000113e:	e45e                	sd	s7,8(sp)
    80001140:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001142:	ca31                	beqz	a2,80001196 <mappages+0x6a>
    80001144:	8aaa                	mv	s5,a0
    80001146:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001148:	77fd                	lui	a5,0xfffff
    8000114a:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000114e:	15fd                	addi	a1,a1,-1
    80001150:	00c589b3          	add	s3,a1,a2
    80001154:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001158:	8952                	mv	s2,s4
    8000115a:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V && !(*pte & PTE_COW))
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000115e:	6b85                	lui	s7,0x1
    80001160:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001164:	4605                	li	a2,1
    80001166:	85ca                	mv	a1,s2
    80001168:	8556                	mv	a0,s5
    8000116a:	00000097          	auipc	ra,0x0
    8000116e:	eda080e7          	jalr	-294(ra) # 80001044 <walk>
    80001172:	c131                	beqz	a0,800011b6 <mappages+0x8a>
    if(*pte & PTE_V && !(*pte & PTE_COW))
    80001174:	611c                	ld	a5,0(a0)
    80001176:	1017f793          	andi	a5,a5,257
    8000117a:	4705                	li	a4,1
    8000117c:	02e78563          	beq	a5,a4,800011a6 <mappages+0x7a>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001180:	80b1                	srli	s1,s1,0xc
    80001182:	04aa                	slli	s1,s1,0xa
    80001184:	0164e4b3          	or	s1,s1,s6
    80001188:	0014e493          	ori	s1,s1,1
    8000118c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000118e:	05390063          	beq	s2,s3,800011ce <mappages+0xa2>
    a += PGSIZE;
    80001192:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001194:	b7f1                	j	80001160 <mappages+0x34>
    panic("mappages: size");
    80001196:	00007517          	auipc	a0,0x7
    8000119a:	f4250513          	addi	a0,a0,-190 # 800080d8 <digits+0x98>
    8000119e:	fffff097          	auipc	ra,0xfffff
    800011a2:	3a0080e7          	jalr	928(ra) # 8000053e <panic>
      panic("mappages: remap");
    800011a6:	00007517          	auipc	a0,0x7
    800011aa:	f4250513          	addi	a0,a0,-190 # 800080e8 <digits+0xa8>
    800011ae:	fffff097          	auipc	ra,0xfffff
    800011b2:	390080e7          	jalr	912(ra) # 8000053e <panic>
      return -1;
    800011b6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b8:	60a6                	ld	ra,72(sp)
    800011ba:	6406                	ld	s0,64(sp)
    800011bc:	74e2                	ld	s1,56(sp)
    800011be:	7942                	ld	s2,48(sp)
    800011c0:	79a2                	ld	s3,40(sp)
    800011c2:	7a02                	ld	s4,32(sp)
    800011c4:	6ae2                	ld	s5,24(sp)
    800011c6:	6b42                	ld	s6,16(sp)
    800011c8:	6ba2                	ld	s7,8(sp)
    800011ca:	6161                	addi	sp,sp,80
    800011cc:	8082                	ret
  return 0;
    800011ce:	4501                	li	a0,0
    800011d0:	b7e5                	j	800011b8 <mappages+0x8c>

00000000800011d2 <kvmmap>:
{
    800011d2:	1141                	addi	sp,sp,-16
    800011d4:	e406                	sd	ra,8(sp)
    800011d6:	e022                	sd	s0,0(sp)
    800011d8:	0800                	addi	s0,sp,16
    800011da:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011dc:	86b2                	mv	a3,a2
    800011de:	863e                	mv	a2,a5
    800011e0:	00000097          	auipc	ra,0x0
    800011e4:	f4c080e7          	jalr	-180(ra) # 8000112c <mappages>
    800011e8:	e509                	bnez	a0,800011f2 <kvmmap+0x20>
}
    800011ea:	60a2                	ld	ra,8(sp)
    800011ec:	6402                	ld	s0,0(sp)
    800011ee:	0141                	addi	sp,sp,16
    800011f0:	8082                	ret
    panic("kvmmap");
    800011f2:	00007517          	auipc	a0,0x7
    800011f6:	f0650513          	addi	a0,a0,-250 # 800080f8 <digits+0xb8>
    800011fa:	fffff097          	auipc	ra,0xfffff
    800011fe:	344080e7          	jalr	836(ra) # 8000053e <panic>

0000000080001202 <kvmmake>:
{
    80001202:	1101                	addi	sp,sp,-32
    80001204:	ec06                	sd	ra,24(sp)
    80001206:	e822                	sd	s0,16(sp)
    80001208:	e426                	sd	s1,8(sp)
    8000120a:	e04a                	sd	s2,0(sp)
    8000120c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	926080e7          	jalr	-1754(ra) # 80000b34 <kalloc>
    80001216:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001218:	6605                	lui	a2,0x1
    8000121a:	4581                	li	a1,0
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	b44080e7          	jalr	-1212(ra) # 80000d60 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001224:	4719                	li	a4,6
    80001226:	6685                	lui	a3,0x1
    80001228:	10000637          	lui	a2,0x10000
    8000122c:	100005b7          	lui	a1,0x10000
    80001230:	8526                	mv	a0,s1
    80001232:	00000097          	auipc	ra,0x0
    80001236:	fa0080e7          	jalr	-96(ra) # 800011d2 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000123a:	4719                	li	a4,6
    8000123c:	6685                	lui	a3,0x1
    8000123e:	10001637          	lui	a2,0x10001
    80001242:	100015b7          	lui	a1,0x10001
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f8a080e7          	jalr	-118(ra) # 800011d2 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001250:	4719                	li	a4,6
    80001252:	004006b7          	lui	a3,0x400
    80001256:	0c000637          	lui	a2,0xc000
    8000125a:	0c0005b7          	lui	a1,0xc000
    8000125e:	8526                	mv	a0,s1
    80001260:	00000097          	auipc	ra,0x0
    80001264:	f72080e7          	jalr	-142(ra) # 800011d2 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001268:	00007917          	auipc	s2,0x7
    8000126c:	d9890913          	addi	s2,s2,-616 # 80008000 <etext>
    80001270:	4729                	li	a4,10
    80001272:	80007697          	auipc	a3,0x80007
    80001276:	d8e68693          	addi	a3,a3,-626 # 8000 <_entry-0x7fff8000>
    8000127a:	4605                	li	a2,1
    8000127c:	067e                	slli	a2,a2,0x1f
    8000127e:	85b2                	mv	a1,a2
    80001280:	8526                	mv	a0,s1
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f50080e7          	jalr	-176(ra) # 800011d2 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000128a:	4719                	li	a4,6
    8000128c:	46c5                	li	a3,17
    8000128e:	06ee                	slli	a3,a3,0x1b
    80001290:	412686b3          	sub	a3,a3,s2
    80001294:	864a                	mv	a2,s2
    80001296:	85ca                	mv	a1,s2
    80001298:	8526                	mv	a0,s1
    8000129a:	00000097          	auipc	ra,0x0
    8000129e:	f38080e7          	jalr	-200(ra) # 800011d2 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012a2:	4729                	li	a4,10
    800012a4:	6685                	lui	a3,0x1
    800012a6:	00006617          	auipc	a2,0x6
    800012aa:	d5a60613          	addi	a2,a2,-678 # 80007000 <_trampoline>
    800012ae:	040005b7          	lui	a1,0x4000
    800012b2:	15fd                	addi	a1,a1,-1
    800012b4:	05b2                	slli	a1,a1,0xc
    800012b6:	8526                	mv	a0,s1
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f1a080e7          	jalr	-230(ra) # 800011d2 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012c0:	8526                	mv	a0,s1
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	67a080e7          	jalr	1658(ra) # 8000193c <proc_mapstacks>
}
    800012ca:	8526                	mv	a0,s1
    800012cc:	60e2                	ld	ra,24(sp)
    800012ce:	6442                	ld	s0,16(sp)
    800012d0:	64a2                	ld	s1,8(sp)
    800012d2:	6902                	ld	s2,0(sp)
    800012d4:	6105                	addi	sp,sp,32
    800012d6:	8082                	ret

00000000800012d8 <kvminit>:
{
    800012d8:	1141                	addi	sp,sp,-16
    800012da:	e406                	sd	ra,8(sp)
    800012dc:	e022                	sd	s0,0(sp)
    800012de:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	f22080e7          	jalr	-222(ra) # 80001202 <kvmmake>
    800012e8:	00008797          	auipc	a5,0x8
    800012ec:	86a7bc23          	sd	a0,-1928(a5) # 80008b60 <kernel_pagetable>
}
    800012f0:	60a2                	ld	ra,8(sp)
    800012f2:	6402                	ld	s0,0(sp)
    800012f4:	0141                	addi	sp,sp,16
    800012f6:	8082                	ret

00000000800012f8 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012f8:	715d                	addi	sp,sp,-80
    800012fa:	e486                	sd	ra,72(sp)
    800012fc:	e0a2                	sd	s0,64(sp)
    800012fe:	fc26                	sd	s1,56(sp)
    80001300:	f84a                	sd	s2,48(sp)
    80001302:	f44e                	sd	s3,40(sp)
    80001304:	f052                	sd	s4,32(sp)
    80001306:	ec56                	sd	s5,24(sp)
    80001308:	e85a                	sd	s6,16(sp)
    8000130a:	e45e                	sd	s7,8(sp)
    8000130c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000130e:	03459793          	slli	a5,a1,0x34
    80001312:	e795                	bnez	a5,8000133e <uvmunmap+0x46>
    80001314:	8a2a                	mv	s4,a0
    80001316:	892e                	mv	s2,a1
    80001318:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131a:	0632                	slli	a2,a2,0xc
    8000131c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001320:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001322:	6b05                	lui	s6,0x1
    80001324:	0735e263          	bltu	a1,s3,80001388 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001328:	60a6                	ld	ra,72(sp)
    8000132a:	6406                	ld	s0,64(sp)
    8000132c:	74e2                	ld	s1,56(sp)
    8000132e:	7942                	ld	s2,48(sp)
    80001330:	79a2                	ld	s3,40(sp)
    80001332:	7a02                	ld	s4,32(sp)
    80001334:	6ae2                	ld	s5,24(sp)
    80001336:	6b42                	ld	s6,16(sp)
    80001338:	6ba2                	ld	s7,8(sp)
    8000133a:	6161                	addi	sp,sp,80
    8000133c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000133e:	00007517          	auipc	a0,0x7
    80001342:	dc250513          	addi	a0,a0,-574 # 80008100 <digits+0xc0>
    80001346:	fffff097          	auipc	ra,0xfffff
    8000134a:	1f8080e7          	jalr	504(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    8000134e:	00007517          	auipc	a0,0x7
    80001352:	dca50513          	addi	a0,a0,-566 # 80008118 <digits+0xd8>
    80001356:	fffff097          	auipc	ra,0xfffff
    8000135a:	1e8080e7          	jalr	488(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000135e:	00007517          	auipc	a0,0x7
    80001362:	dca50513          	addi	a0,a0,-566 # 80008128 <digits+0xe8>
    80001366:	fffff097          	auipc	ra,0xfffff
    8000136a:	1d8080e7          	jalr	472(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000136e:	00007517          	auipc	a0,0x7
    80001372:	dd250513          	addi	a0,a0,-558 # 80008140 <digits+0x100>
    80001376:	fffff097          	auipc	ra,0xfffff
    8000137a:	1c8080e7          	jalr	456(ra) # 8000053e <panic>
    *pte = 0;
    8000137e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001382:	995a                	add	s2,s2,s6
    80001384:	fb3972e3          	bgeu	s2,s3,80001328 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001388:	4601                	li	a2,0
    8000138a:	85ca                	mv	a1,s2
    8000138c:	8552                	mv	a0,s4
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	cb6080e7          	jalr	-842(ra) # 80001044 <walk>
    80001396:	84aa                	mv	s1,a0
    80001398:	d95d                	beqz	a0,8000134e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000139a:	6108                	ld	a0,0(a0)
    8000139c:	00157793          	andi	a5,a0,1
    800013a0:	dfdd                	beqz	a5,8000135e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013a2:	3ff57793          	andi	a5,a0,1023
    800013a6:	fd7784e3          	beq	a5,s7,8000136e <uvmunmap+0x76>
    if(do_free){
    800013aa:	fc0a8ae3          	beqz	s5,8000137e <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013ae:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013b0:	0532                	slli	a0,a0,0xc
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	638080e7          	jalr	1592(ra) # 800009ea <kfree>
    800013ba:	b7d1                	j	8000137e <uvmunmap+0x86>

00000000800013bc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013bc:	1101                	addi	sp,sp,-32
    800013be:	ec06                	sd	ra,24(sp)
    800013c0:	e822                	sd	s0,16(sp)
    800013c2:	e426                	sd	s1,8(sp)
    800013c4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013c6:	fffff097          	auipc	ra,0xfffff
    800013ca:	76e080e7          	jalr	1902(ra) # 80000b34 <kalloc>
    800013ce:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013d0:	c519                	beqz	a0,800013de <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013d2:	6605                	lui	a2,0x1
    800013d4:	4581                	li	a1,0
    800013d6:	00000097          	auipc	ra,0x0
    800013da:	98a080e7          	jalr	-1654(ra) # 80000d60 <memset>
  return pagetable;
}
    800013de:	8526                	mv	a0,s1
    800013e0:	60e2                	ld	ra,24(sp)
    800013e2:	6442                	ld	s0,16(sp)
    800013e4:	64a2                	ld	s1,8(sp)
    800013e6:	6105                	addi	sp,sp,32
    800013e8:	8082                	ret

00000000800013ea <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ea:	7179                	addi	sp,sp,-48
    800013ec:	f406                	sd	ra,40(sp)
    800013ee:	f022                	sd	s0,32(sp)
    800013f0:	ec26                	sd	s1,24(sp)
    800013f2:	e84a                	sd	s2,16(sp)
    800013f4:	e44e                	sd	s3,8(sp)
    800013f6:	e052                	sd	s4,0(sp)
    800013f8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013fa:	6785                	lui	a5,0x1
    800013fc:	04f67863          	bgeu	a2,a5,8000144c <uvmfirst+0x62>
    80001400:	8a2a                	mv	s4,a0
    80001402:	89ae                	mv	s3,a1
    80001404:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001406:	fffff097          	auipc	ra,0xfffff
    8000140a:	72e080e7          	jalr	1838(ra) # 80000b34 <kalloc>
    8000140e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001410:	6605                	lui	a2,0x1
    80001412:	4581                	li	a1,0
    80001414:	00000097          	auipc	ra,0x0
    80001418:	94c080e7          	jalr	-1716(ra) # 80000d60 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000141c:	4779                	li	a4,30
    8000141e:	86ca                	mv	a3,s2
    80001420:	6605                	lui	a2,0x1
    80001422:	4581                	li	a1,0
    80001424:	8552                	mv	a0,s4
    80001426:	00000097          	auipc	ra,0x0
    8000142a:	d06080e7          	jalr	-762(ra) # 8000112c <mappages>
  memmove(mem, src, sz);
    8000142e:	8626                	mv	a2,s1
    80001430:	85ce                	mv	a1,s3
    80001432:	854a                	mv	a0,s2
    80001434:	00000097          	auipc	ra,0x0
    80001438:	988080e7          	jalr	-1656(ra) # 80000dbc <memmove>
}
    8000143c:	70a2                	ld	ra,40(sp)
    8000143e:	7402                	ld	s0,32(sp)
    80001440:	64e2                	ld	s1,24(sp)
    80001442:	6942                	ld	s2,16(sp)
    80001444:	69a2                	ld	s3,8(sp)
    80001446:	6a02                	ld	s4,0(sp)
    80001448:	6145                	addi	sp,sp,48
    8000144a:	8082                	ret
    panic("uvmfirst: more than a page");
    8000144c:	00007517          	auipc	a0,0x7
    80001450:	d0c50513          	addi	a0,a0,-756 # 80008158 <digits+0x118>
    80001454:	fffff097          	auipc	ra,0xfffff
    80001458:	0ea080e7          	jalr	234(ra) # 8000053e <panic>

000000008000145c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000145c:	1101                	addi	sp,sp,-32
    8000145e:	ec06                	sd	ra,24(sp)
    80001460:	e822                	sd	s0,16(sp)
    80001462:	e426                	sd	s1,8(sp)
    80001464:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001466:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001468:	00b67d63          	bgeu	a2,a1,80001482 <uvmdealloc+0x26>
    8000146c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000146e:	6785                	lui	a5,0x1
    80001470:	17fd                	addi	a5,a5,-1
    80001472:	00f60733          	add	a4,a2,a5
    80001476:	767d                	lui	a2,0xfffff
    80001478:	8f71                	and	a4,a4,a2
    8000147a:	97ae                	add	a5,a5,a1
    8000147c:	8ff1                	and	a5,a5,a2
    8000147e:	00f76863          	bltu	a4,a5,8000148e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001482:	8526                	mv	a0,s1
    80001484:	60e2                	ld	ra,24(sp)
    80001486:	6442                	ld	s0,16(sp)
    80001488:	64a2                	ld	s1,8(sp)
    8000148a:	6105                	addi	sp,sp,32
    8000148c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000148e:	8f99                	sub	a5,a5,a4
    80001490:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001492:	4685                	li	a3,1
    80001494:	0007861b          	sext.w	a2,a5
    80001498:	85ba                	mv	a1,a4
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	e5e080e7          	jalr	-418(ra) # 800012f8 <uvmunmap>
    800014a2:	b7c5                	j	80001482 <uvmdealloc+0x26>

00000000800014a4 <uvmalloc>:
  if(newsz < oldsz)
    800014a4:	0ab66563          	bltu	a2,a1,8000154e <uvmalloc+0xaa>
{
    800014a8:	7139                	addi	sp,sp,-64
    800014aa:	fc06                	sd	ra,56(sp)
    800014ac:	f822                	sd	s0,48(sp)
    800014ae:	f426                	sd	s1,40(sp)
    800014b0:	f04a                	sd	s2,32(sp)
    800014b2:	ec4e                	sd	s3,24(sp)
    800014b4:	e852                	sd	s4,16(sp)
    800014b6:	e456                	sd	s5,8(sp)
    800014b8:	e05a                	sd	s6,0(sp)
    800014ba:	0080                	addi	s0,sp,64
    800014bc:	8aaa                	mv	s5,a0
    800014be:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014c0:	6985                	lui	s3,0x1
    800014c2:	19fd                	addi	s3,s3,-1
    800014c4:	95ce                	add	a1,a1,s3
    800014c6:	79fd                	lui	s3,0xfffff
    800014c8:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014cc:	08c9f363          	bgeu	s3,a2,80001552 <uvmalloc+0xae>
    800014d0:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014d6:	fffff097          	auipc	ra,0xfffff
    800014da:	65e080e7          	jalr	1630(ra) # 80000b34 <kalloc>
    800014de:	84aa                	mv	s1,a0
    if(mem == 0){
    800014e0:	c51d                	beqz	a0,8000150e <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014e2:	6605                	lui	a2,0x1
    800014e4:	4581                	li	a1,0
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	87a080e7          	jalr	-1926(ra) # 80000d60 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014ee:	875a                	mv	a4,s6
    800014f0:	86a6                	mv	a3,s1
    800014f2:	6605                	lui	a2,0x1
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	c34080e7          	jalr	-972(ra) # 8000112c <mappages>
    80001500:	e90d                	bnez	a0,80001532 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001502:	6785                	lui	a5,0x1
    80001504:	993e                	add	s2,s2,a5
    80001506:	fd4968e3          	bltu	s2,s4,800014d6 <uvmalloc+0x32>
  return newsz;
    8000150a:	8552                	mv	a0,s4
    8000150c:	a809                	j	8000151e <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000150e:	864e                	mv	a2,s3
    80001510:	85ca                	mv	a1,s2
    80001512:	8556                	mv	a0,s5
    80001514:	00000097          	auipc	ra,0x0
    80001518:	f48080e7          	jalr	-184(ra) # 8000145c <uvmdealloc>
      return 0;
    8000151c:	4501                	li	a0,0
}
    8000151e:	70e2                	ld	ra,56(sp)
    80001520:	7442                	ld	s0,48(sp)
    80001522:	74a2                	ld	s1,40(sp)
    80001524:	7902                	ld	s2,32(sp)
    80001526:	69e2                	ld	s3,24(sp)
    80001528:	6a42                	ld	s4,16(sp)
    8000152a:	6aa2                	ld	s5,8(sp)
    8000152c:	6b02                	ld	s6,0(sp)
    8000152e:	6121                	addi	sp,sp,64
    80001530:	8082                	ret
      kfree(mem);
    80001532:	8526                	mv	a0,s1
    80001534:	fffff097          	auipc	ra,0xfffff
    80001538:	4b6080e7          	jalr	1206(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000153c:	864e                	mv	a2,s3
    8000153e:	85ca                	mv	a1,s2
    80001540:	8556                	mv	a0,s5
    80001542:	00000097          	auipc	ra,0x0
    80001546:	f1a080e7          	jalr	-230(ra) # 8000145c <uvmdealloc>
      return 0;
    8000154a:	4501                	li	a0,0
    8000154c:	bfc9                	j	8000151e <uvmalloc+0x7a>
    return oldsz;
    8000154e:	852e                	mv	a0,a1
}
    80001550:	8082                	ret
  return newsz;
    80001552:	8532                	mv	a0,a2
    80001554:	b7e9                	j	8000151e <uvmalloc+0x7a>

0000000080001556 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001556:	7179                	addi	sp,sp,-48
    80001558:	f406                	sd	ra,40(sp)
    8000155a:	f022                	sd	s0,32(sp)
    8000155c:	ec26                	sd	s1,24(sp)
    8000155e:	e84a                	sd	s2,16(sp)
    80001560:	e44e                	sd	s3,8(sp)
    80001562:	e052                	sd	s4,0(sp)
    80001564:	1800                	addi	s0,sp,48
    80001566:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001568:	84aa                	mv	s1,a0
    8000156a:	6905                	lui	s2,0x1
    8000156c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000156e:	4985                	li	s3,1
    80001570:	a821                	j	80001588 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001572:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001574:	0532                	slli	a0,a0,0xc
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	fe0080e7          	jalr	-32(ra) # 80001556 <freewalk>
      pagetable[i] = 0;
    8000157e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001582:	04a1                	addi	s1,s1,8
    80001584:	03248163          	beq	s1,s2,800015a6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001588:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158a:	00f57793          	andi	a5,a0,15
    8000158e:	ff3782e3          	beq	a5,s3,80001572 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001592:	8905                	andi	a0,a0,1
    80001594:	d57d                	beqz	a0,80001582 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001596:	00007517          	auipc	a0,0x7
    8000159a:	be250513          	addi	a0,a0,-1054 # 80008178 <digits+0x138>
    8000159e:	fffff097          	auipc	ra,0xfffff
    800015a2:	fa0080e7          	jalr	-96(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    800015a6:	8552                	mv	a0,s4
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	442080e7          	jalr	1090(ra) # 800009ea <kfree>
}
    800015b0:	70a2                	ld	ra,40(sp)
    800015b2:	7402                	ld	s0,32(sp)
    800015b4:	64e2                	ld	s1,24(sp)
    800015b6:	6942                	ld	s2,16(sp)
    800015b8:	69a2                	ld	s3,8(sp)
    800015ba:	6a02                	ld	s4,0(sp)
    800015bc:	6145                	addi	sp,sp,48
    800015be:	8082                	ret

00000000800015c0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015c0:	1101                	addi	sp,sp,-32
    800015c2:	ec06                	sd	ra,24(sp)
    800015c4:	e822                	sd	s0,16(sp)
    800015c6:	e426                	sd	s1,8(sp)
    800015c8:	1000                	addi	s0,sp,32
    800015ca:	84aa                	mv	s1,a0
  if(sz > 0)
    800015cc:	e999                	bnez	a1,800015e2 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ce:	8526                	mv	a0,s1
    800015d0:	00000097          	auipc	ra,0x0
    800015d4:	f86080e7          	jalr	-122(ra) # 80001556 <freewalk>
}
    800015d8:	60e2                	ld	ra,24(sp)
    800015da:	6442                	ld	s0,16(sp)
    800015dc:	64a2                	ld	s1,8(sp)
    800015de:	6105                	addi	sp,sp,32
    800015e0:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015e2:	6605                	lui	a2,0x1
    800015e4:	167d                	addi	a2,a2,-1
    800015e6:	962e                	add	a2,a2,a1
    800015e8:	4685                	li	a3,1
    800015ea:	8231                	srli	a2,a2,0xc
    800015ec:	4581                	li	a1,0
    800015ee:	00000097          	auipc	ra,0x0
    800015f2:	d0a080e7          	jalr	-758(ra) # 800012f8 <uvmunmap>
    800015f6:	bfe1                	j	800015ce <uvmfree+0xe>

00000000800015f8 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800015f8:	7139                	addi	sp,sp,-64
    800015fa:	fc06                	sd	ra,56(sp)
    800015fc:	f822                	sd	s0,48(sp)
    800015fe:	f426                	sd	s1,40(sp)
    80001600:	f04a                	sd	s2,32(sp)
    80001602:	ec4e                	sd	s3,24(sp)
    80001604:	e852                	sd	s4,16(sp)
    80001606:	e456                	sd	s5,8(sp)
    80001608:	e05a                	sd	s6,0(sp)
    8000160a:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    8000160c:	c655                	beqz	a2,800016b8 <uvmcopy+0xc0>
    8000160e:	8b2a                	mv	s6,a0
    80001610:	8aae                	mv	s5,a1
    80001612:	8a32                	mv	s4,a2
    80001614:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    80001616:	4601                	li	a2,0
    80001618:	85a6                	mv	a1,s1
    8000161a:	855a                	mv	a0,s6
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	a28080e7          	jalr	-1496(ra) # 80001044 <walk>
    80001624:	c529                	beqz	a0,8000166e <uvmcopy+0x76>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001626:	6118                	ld	a4,0(a0)
    80001628:	00177793          	andi	a5,a4,1
    8000162c:	cba9                	beqz	a5,8000167e <uvmcopy+0x86>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000162e:	00a75913          	srli	s2,a4,0xa
    80001632:	0932                	slli	s2,s2,0xc
    flags = PTE_FLAGS(*pte);

    // START cow
    flags = (flags|PTE_COW) & ~(PTE_W|PTE_V);
    *pte = (*pte | PTE_COW) & ~PTE_W;
    80001634:	efb77793          	andi	a5,a4,-261
    80001638:	1007e793          	ori	a5,a5,256
    8000163c:	e11c                	sd	a5,0(a0)
    flags = (flags|PTE_COW) & ~(PTE_W|PTE_V);
    8000163e:	3fa77713          	andi	a4,a4,1018

    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001642:	10076713          	ori	a4,a4,256
    80001646:	86ca                	mv	a3,s2
    80001648:	6605                	lui	a2,0x1
    8000164a:	85a6                	mv	a1,s1
    8000164c:	8556                	mv	a0,s5
    8000164e:	00000097          	auipc	ra,0x0
    80001652:	ade080e7          	jalr	-1314(ra) # 8000112c <mappages>
    80001656:	89aa                	mv	s3,a0
    80001658:	e91d                	bnez	a0,8000168e <uvmcopy+0x96>
      goto err;
    }
    refInc(pa);
    8000165a:	854a                	mv	a0,s2
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	552080e7          	jalr	1362(ra) # 80000bae <refInc>
  for(i = 0; i < sz; i += PGSIZE){
    80001664:	6785                	lui	a5,0x1
    80001666:	94be                	add	s1,s1,a5
    80001668:	fb44e7e3          	bltu	s1,s4,80001616 <uvmcopy+0x1e>
    8000166c:	a81d                	j	800016a2 <uvmcopy+0xaa>
      panic("uvmcopy: pte should exist");
    8000166e:	00007517          	auipc	a0,0x7
    80001672:	b1a50513          	addi	a0,a0,-1254 # 80008188 <digits+0x148>
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	ec8080e7          	jalr	-312(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000167e:	00007517          	auipc	a0,0x7
    80001682:	b2a50513          	addi	a0,a0,-1238 # 800081a8 <digits+0x168>
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	eb8080e7          	jalr	-328(ra) # 8000053e <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000168e:	4685                	li	a3,1
    80001690:	00c4d613          	srli	a2,s1,0xc
    80001694:	4581                	li	a1,0
    80001696:	8556                	mv	a0,s5
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	c60080e7          	jalr	-928(ra) # 800012f8 <uvmunmap>
  return -1;
    800016a0:	59fd                	li	s3,-1
}
    800016a2:	854e                	mv	a0,s3
    800016a4:	70e2                	ld	ra,56(sp)
    800016a6:	7442                	ld	s0,48(sp)
    800016a8:	74a2                	ld	s1,40(sp)
    800016aa:	7902                	ld	s2,32(sp)
    800016ac:	69e2                	ld	s3,24(sp)
    800016ae:	6a42                	ld	s4,16(sp)
    800016b0:	6aa2                	ld	s5,8(sp)
    800016b2:	6b02                	ld	s6,0(sp)
    800016b4:	6121                	addi	sp,sp,64
    800016b6:	8082                	ret
  return 0;
    800016b8:	4981                	li	s3,0
    800016ba:	b7e5                	j	800016a2 <uvmcopy+0xaa>

00000000800016bc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016bc:	1141                	addi	sp,sp,-16
    800016be:	e406                	sd	ra,8(sp)
    800016c0:	e022                	sd	s0,0(sp)
    800016c2:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016c4:	4601                	li	a2,0
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	97e080e7          	jalr	-1666(ra) # 80001044 <walk>
  if(pte == 0)
    800016ce:	c901                	beqz	a0,800016de <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016d0:	611c                	ld	a5,0(a0)
    800016d2:	9bbd                	andi	a5,a5,-17
    800016d4:	e11c                	sd	a5,0(a0)
}
    800016d6:	60a2                	ld	ra,8(sp)
    800016d8:	6402                	ld	s0,0(sp)
    800016da:	0141                	addi	sp,sp,16
    800016dc:	8082                	ret
    panic("uvmclear");
    800016de:	00007517          	auipc	a0,0x7
    800016e2:	aea50513          	addi	a0,a0,-1302 # 800081c8 <digits+0x188>
    800016e6:	fffff097          	auipc	ra,0xfffff
    800016ea:	e58080e7          	jalr	-424(ra) # 8000053e <panic>

00000000800016ee <copyout>:
  // START cow
  pte_t *pte;
  char * mem;
  // END

  while(len > 0){
    800016ee:	c2fd                	beqz	a3,800017d4 <copyout+0xe6>
{
    800016f0:	715d                	addi	sp,sp,-80
    800016f2:	e486                	sd	ra,72(sp)
    800016f4:	e0a2                	sd	s0,64(sp)
    800016f6:	fc26                	sd	s1,56(sp)
    800016f8:	f84a                	sd	s2,48(sp)
    800016fa:	f44e                	sd	s3,40(sp)
    800016fc:	f052                	sd	s4,32(sp)
    800016fe:	ec56                	sd	s5,24(sp)
    80001700:	e85a                	sd	s6,16(sp)
    80001702:	e45e                	sd	s7,8(sp)
    80001704:	e062                	sd	s8,0(sp)
    80001706:	0880                	addi	s0,sp,80
    80001708:	8aaa                	mv	s5,a0
    8000170a:	8b2e                	mv	s6,a1
    8000170c:	8bb2                	mv	s7,a2
    8000170e:	8a36                	mv	s4,a3

    // START
    va0 = PGROUNDDOWN(dstva);
    80001710:	74fd                	lui	s1,0xfffff
    80001712:	8ced                	and	s1,s1,a1

    if(va0 >= MAXVA){
    80001714:	57fd                	li	a5,-1
    80001716:	83e9                	srli	a5,a5,0x1a
    80001718:	0c97e063          	bltu	a5,s1,800017d8 <copyout+0xea>
    8000171c:	8c3e                	mv	s8,a5
    8000171e:	a835                	j	8000175a <copyout+0x6c>
    pte = walk(pagetable, va0,0);
    if(PTE_FLAGS(*pte) & PTE_COW){
      mem = kalloc();
      memmove(mem, (char*)pa0, PGSIZE);
      if(mappages(pagetable,va0 , PGSIZE, (uint64)mem, PTE_R|PTE_W|PTE_X|PTE_U) != 0){
        printf("ERROR\n");
    80001720:	00007517          	auipc	a0,0x7
    80001724:	ab850513          	addi	a0,a0,-1352 # 800081d8 <digits+0x198>
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	e60080e7          	jalr	-416(ra) # 80000588 <printf>
        return -1;
    80001730:	557d                	li	a0,-1
    80001732:	a845                	j	800017e2 <copyout+0xf4>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001734:	409b04b3          	sub	s1,s6,s1
    80001738:	0009861b          	sext.w	a2,s3
    8000173c:	85de                	mv	a1,s7
    8000173e:	9526                	add	a0,a0,s1
    80001740:	fffff097          	auipc	ra,0xfffff
    80001744:	67c080e7          	jalr	1660(ra) # 80000dbc <memmove>

    len -= n;
    80001748:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000174c:	9bce                	add	s7,s7,s3
  while(len > 0){
    8000174e:	080a0163          	beqz	s4,800017d0 <copyout+0xe2>
    if(va0 >= MAXVA){
    80001752:	092c6563          	bltu	s8,s2,800017dc <copyout+0xee>
    va0 = PGROUNDDOWN(dstva);
    80001756:	84ca                	mv	s1,s2
    dstva = va0 + PGSIZE;
    80001758:	8b4a                	mv	s6,s2
    pa0 = walkaddr(pagetable, va0);
    8000175a:	85a6                	mv	a1,s1
    8000175c:	8556                	mv	a0,s5
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	98c080e7          	jalr	-1652(ra) # 800010ea <walkaddr>
    80001766:	892a                	mv	s2,a0
    pte = walk(pagetable, va0,0);
    80001768:	4601                	li	a2,0
    8000176a:	85a6                	mv	a1,s1
    8000176c:	8556                	mv	a0,s5
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	8d6080e7          	jalr	-1834(ra) # 80001044 <walk>
    if(PTE_FLAGS(*pte) & PTE_COW){
    80001776:	611c                	ld	a5,0(a0)
    80001778:	1007f793          	andi	a5,a5,256
    8000177c:	cb9d                	beqz	a5,800017b2 <copyout+0xc4>
      mem = kalloc();
    8000177e:	fffff097          	auipc	ra,0xfffff
    80001782:	3b6080e7          	jalr	950(ra) # 80000b34 <kalloc>
    80001786:	89aa                	mv	s3,a0
      memmove(mem, (char*)pa0, PGSIZE);
    80001788:	6605                	lui	a2,0x1
    8000178a:	85ca                	mv	a1,s2
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	630080e7          	jalr	1584(ra) # 80000dbc <memmove>
      if(mappages(pagetable,va0 , PGSIZE, (uint64)mem, PTE_R|PTE_W|PTE_X|PTE_U) != 0){
    80001794:	4779                	li	a4,30
    80001796:	86ce                	mv	a3,s3
    80001798:	6605                	lui	a2,0x1
    8000179a:	85a6                	mv	a1,s1
    8000179c:	8556                	mv	a0,s5
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	98e080e7          	jalr	-1650(ra) # 8000112c <mappages>
    800017a6:	fd2d                	bnez	a0,80001720 <copyout+0x32>
      kfree((void*)pa0);
    800017a8:	854a                	mv	a0,s2
    800017aa:	fffff097          	auipc	ra,0xfffff
    800017ae:	240080e7          	jalr	576(ra) # 800009ea <kfree>
    pa0 = walkaddr(pagetable, va0);
    800017b2:	85a6                	mv	a1,s1
    800017b4:	8556                	mv	a0,s5
    800017b6:	00000097          	auipc	ra,0x0
    800017ba:	934080e7          	jalr	-1740(ra) # 800010ea <walkaddr>
    if(pa0 == 0)
    800017be:	c10d                	beqz	a0,800017e0 <copyout+0xf2>
    n = PGSIZE - (dstva - va0);
    800017c0:	6905                	lui	s2,0x1
    800017c2:	9926                	add	s2,s2,s1
    800017c4:	416909b3          	sub	s3,s2,s6
    if(n > len)
    800017c8:	f73a76e3          	bgeu	s4,s3,80001734 <copyout+0x46>
    800017cc:	89d2                	mv	s3,s4
    800017ce:	b79d                	j	80001734 <copyout+0x46>
  }
  return 0;
    800017d0:	4501                	li	a0,0
    800017d2:	a801                	j	800017e2 <copyout+0xf4>
    800017d4:	4501                	li	a0,0
}
    800017d6:	8082                	ret
      return -1;
    800017d8:	557d                	li	a0,-1
    800017da:	a021                	j	800017e2 <copyout+0xf4>
    800017dc:	557d                	li	a0,-1
    800017de:	a011                	j	800017e2 <copyout+0xf4>
      return -1;
    800017e0:	557d                	li	a0,-1
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6c02                	ld	s8,0(sp)
    800017f6:	6161                	addi	sp,sp,80
    800017f8:	8082                	ret

00000000800017fa <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017fa:	caa5                	beqz	a3,8000186a <copyin+0x70>
{
    800017fc:	715d                	addi	sp,sp,-80
    800017fe:	e486                	sd	ra,72(sp)
    80001800:	e0a2                	sd	s0,64(sp)
    80001802:	fc26                	sd	s1,56(sp)
    80001804:	f84a                	sd	s2,48(sp)
    80001806:	f44e                	sd	s3,40(sp)
    80001808:	f052                	sd	s4,32(sp)
    8000180a:	ec56                	sd	s5,24(sp)
    8000180c:	e85a                	sd	s6,16(sp)
    8000180e:	e45e                	sd	s7,8(sp)
    80001810:	e062                	sd	s8,0(sp)
    80001812:	0880                	addi	s0,sp,80
    80001814:	8b2a                	mv	s6,a0
    80001816:	8a2e                	mv	s4,a1
    80001818:	8c32                	mv	s8,a2
    8000181a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000181c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181e:	6a85                	lui	s5,0x1
    80001820:	a01d                	j	80001846 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001822:	018505b3          	add	a1,a0,s8
    80001826:	0004861b          	sext.w	a2,s1
    8000182a:	412585b3          	sub	a1,a1,s2
    8000182e:	8552                	mv	a0,s4
    80001830:	fffff097          	auipc	ra,0xfffff
    80001834:	58c080e7          	jalr	1420(ra) # 80000dbc <memmove>

    len -= n;
    80001838:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000183c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000183e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001842:	02098263          	beqz	s3,80001866 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001846:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000184a:	85ca                	mv	a1,s2
    8000184c:	855a                	mv	a0,s6
    8000184e:	00000097          	auipc	ra,0x0
    80001852:	89c080e7          	jalr	-1892(ra) # 800010ea <walkaddr>
    if(pa0 == 0)
    80001856:	cd01                	beqz	a0,8000186e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001858:	418904b3          	sub	s1,s2,s8
    8000185c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000185e:	fc99f2e3          	bgeu	s3,s1,80001822 <copyin+0x28>
    80001862:	84ce                	mv	s1,s3
    80001864:	bf7d                	j	80001822 <copyin+0x28>
  }
  return 0;
    80001866:	4501                	li	a0,0
    80001868:	a021                	j	80001870 <copyin+0x76>
    8000186a:	4501                	li	a0,0
}
    8000186c:	8082                	ret
      return -1;
    8000186e:	557d                	li	a0,-1
}
    80001870:	60a6                	ld	ra,72(sp)
    80001872:	6406                	ld	s0,64(sp)
    80001874:	74e2                	ld	s1,56(sp)
    80001876:	7942                	ld	s2,48(sp)
    80001878:	79a2                	ld	s3,40(sp)
    8000187a:	7a02                	ld	s4,32(sp)
    8000187c:	6ae2                	ld	s5,24(sp)
    8000187e:	6b42                	ld	s6,16(sp)
    80001880:	6ba2                	ld	s7,8(sp)
    80001882:	6c02                	ld	s8,0(sp)
    80001884:	6161                	addi	sp,sp,80
    80001886:	8082                	ret

0000000080001888 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001888:	c6c5                	beqz	a3,80001930 <copyinstr+0xa8>
{
    8000188a:	715d                	addi	sp,sp,-80
    8000188c:	e486                	sd	ra,72(sp)
    8000188e:	e0a2                	sd	s0,64(sp)
    80001890:	fc26                	sd	s1,56(sp)
    80001892:	f84a                	sd	s2,48(sp)
    80001894:	f44e                	sd	s3,40(sp)
    80001896:	f052                	sd	s4,32(sp)
    80001898:	ec56                	sd	s5,24(sp)
    8000189a:	e85a                	sd	s6,16(sp)
    8000189c:	e45e                	sd	s7,8(sp)
    8000189e:	0880                	addi	s0,sp,80
    800018a0:	8a2a                	mv	s4,a0
    800018a2:	8b2e                	mv	s6,a1
    800018a4:	8bb2                	mv	s7,a2
    800018a6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018a8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018aa:	6985                	lui	s3,0x1
    800018ac:	a035                	j	800018d8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018ae:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018b4:	0017b793          	seqz	a5,a5
    800018b8:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018bc:	60a6                	ld	ra,72(sp)
    800018be:	6406                	ld	s0,64(sp)
    800018c0:	74e2                	ld	s1,56(sp)
    800018c2:	7942                	ld	s2,48(sp)
    800018c4:	79a2                	ld	s3,40(sp)
    800018c6:	7a02                	ld	s4,32(sp)
    800018c8:	6ae2                	ld	s5,24(sp)
    800018ca:	6b42                	ld	s6,16(sp)
    800018cc:	6ba2                	ld	s7,8(sp)
    800018ce:	6161                	addi	sp,sp,80
    800018d0:	8082                	ret
    srcva = va0 + PGSIZE;
    800018d2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018d6:	c8a9                	beqz	s1,80001928 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018d8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018dc:	85ca                	mv	a1,s2
    800018de:	8552                	mv	a0,s4
    800018e0:	00000097          	auipc	ra,0x0
    800018e4:	80a080e7          	jalr	-2038(ra) # 800010ea <walkaddr>
    if(pa0 == 0)
    800018e8:	c131                	beqz	a0,8000192c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018ea:	41790833          	sub	a6,s2,s7
    800018ee:	984e                	add	a6,a6,s3
    if(n > max)
    800018f0:	0104f363          	bgeu	s1,a6,800018f6 <copyinstr+0x6e>
    800018f4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018f6:	955e                	add	a0,a0,s7
    800018f8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018fc:	fc080be3          	beqz	a6,800018d2 <copyinstr+0x4a>
    80001900:	985a                	add	a6,a6,s6
    80001902:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001904:	41650633          	sub	a2,a0,s6
    80001908:	14fd                	addi	s1,s1,-1
    8000190a:	9b26                	add	s6,s6,s1
    8000190c:	00f60733          	add	a4,a2,a5
    80001910:	00074703          	lbu	a4,0(a4)
    80001914:	df49                	beqz	a4,800018ae <copyinstr+0x26>
        *dst = *p;
    80001916:	00e78023          	sb	a4,0(a5)
      --max;
    8000191a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000191e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001920:	ff0796e3          	bne	a5,a6,8000190c <copyinstr+0x84>
      dst++;
    80001924:	8b42                	mv	s6,a6
    80001926:	b775                	j	800018d2 <copyinstr+0x4a>
    80001928:	4781                	li	a5,0
    8000192a:	b769                	j	800018b4 <copyinstr+0x2c>
      return -1;
    8000192c:	557d                	li	a0,-1
    8000192e:	b779                	j	800018bc <copyinstr+0x34>
  int got_null = 0;
    80001930:	4781                	li	a5,0
  if(got_null){
    80001932:	0017b793          	seqz	a5,a5
    80001936:	40f00533          	neg	a0,a5
}
    8000193a:	8082                	ret

000000008000193c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000193c:	7139                	addi	sp,sp,-64
    8000193e:	fc06                	sd	ra,56(sp)
    80001940:	f822                	sd	s0,48(sp)
    80001942:	f426                	sd	s1,40(sp)
    80001944:	f04a                	sd	s2,32(sp)
    80001946:	ec4e                	sd	s3,24(sp)
    80001948:	e852                	sd	s4,16(sp)
    8000194a:	e456                	sd	s5,8(sp)
    8000194c:	e05a                	sd	s6,0(sp)
    8000194e:	0080                	addi	s0,sp,64
    80001950:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001952:	00030497          	auipc	s1,0x30
    80001956:	8be48493          	addi	s1,s1,-1858 # 80031210 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000195a:	8b26                	mv	s6,s1
    8000195c:	00006a97          	auipc	s5,0x6
    80001960:	6a4a8a93          	addi	s5,s5,1700 # 80008000 <etext>
    80001964:	04000937          	lui	s2,0x4000
    80001968:	197d                	addi	s2,s2,-1
    8000196a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000196c:	0003ba17          	auipc	s4,0x3b
    80001970:	6a4a0a13          	addi	s4,s4,1700 # 8003d010 <tickslock>
    char *pa = kalloc();
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	1c0080e7          	jalr	448(ra) # 80000b34 <kalloc>
    8000197c:	862a                	mv	a2,a0
    if (pa == 0)
    8000197e:	c131                	beqz	a0,800019c2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001980:	416485b3          	sub	a1,s1,s6
    80001984:	858d                	srai	a1,a1,0x3
    80001986:	000ab783          	ld	a5,0(s5)
    8000198a:	02f585b3          	mul	a1,a1,a5
    8000198e:	2585                	addiw	a1,a1,1
    80001990:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001994:	4719                	li	a4,6
    80001996:	6685                	lui	a3,0x1
    80001998:	40b905b3          	sub	a1,s2,a1
    8000199c:	854e                	mv	a0,s3
    8000199e:	00000097          	auipc	ra,0x0
    800019a2:	834080e7          	jalr	-1996(ra) # 800011d2 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800019a6:	2f848493          	addi	s1,s1,760
    800019aa:	fd4495e3          	bne	s1,s4,80001974 <proc_mapstacks+0x38>
  }
}
    800019ae:	70e2                	ld	ra,56(sp)
    800019b0:	7442                	ld	s0,48(sp)
    800019b2:	74a2                	ld	s1,40(sp)
    800019b4:	7902                	ld	s2,32(sp)
    800019b6:	69e2                	ld	s3,24(sp)
    800019b8:	6a42                	ld	s4,16(sp)
    800019ba:	6aa2                	ld	s5,8(sp)
    800019bc:	6b02                	ld	s6,0(sp)
    800019be:	6121                	addi	sp,sp,64
    800019c0:	8082                	ret
      panic("kalloc");
    800019c2:	00007517          	auipc	a0,0x7
    800019c6:	81e50513          	addi	a0,a0,-2018 # 800081e0 <digits+0x1a0>
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	b74080e7          	jalr	-1164(ra) # 8000053e <panic>

00000000800019d2 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800019d2:	7139                	addi	sp,sp,-64
    800019d4:	fc06                	sd	ra,56(sp)
    800019d6:	f822                	sd	s0,48(sp)
    800019d8:	f426                	sd	s1,40(sp)
    800019da:	f04a                	sd	s2,32(sp)
    800019dc:	ec4e                	sd	s3,24(sp)
    800019de:	e852                	sd	s4,16(sp)
    800019e0:	e456                	sd	s5,8(sp)
    800019e2:	e05a                	sd	s6,0(sp)
    800019e4:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800019e6:	00007597          	auipc	a1,0x7
    800019ea:	80258593          	addi	a1,a1,-2046 # 800081e8 <digits+0x1a8>
    800019ee:	0002f517          	auipc	a0,0x2f
    800019f2:	3f250513          	addi	a0,a0,1010 # 80030de0 <pid_lock>
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	1de080e7          	jalr	478(ra) # 80000bd4 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019fe:	00006597          	auipc	a1,0x6
    80001a02:	7f258593          	addi	a1,a1,2034 # 800081f0 <digits+0x1b0>
    80001a06:	0002f517          	auipc	a0,0x2f
    80001a0a:	3f250513          	addi	a0,a0,1010 # 80030df8 <wait_lock>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	1c6080e7          	jalr	454(ra) # 80000bd4 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a16:	0002f497          	auipc	s1,0x2f
    80001a1a:	7fa48493          	addi	s1,s1,2042 # 80031210 <proc>
  {
    initlock(&p->lock, "proc");
    80001a1e:	00006b17          	auipc	s6,0x6
    80001a22:	7e2b0b13          	addi	s6,s6,2018 # 80008200 <digits+0x1c0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001a26:	8aa6                	mv	s5,s1
    80001a28:	00006a17          	auipc	s4,0x6
    80001a2c:	5d8a0a13          	addi	s4,s4,1496 # 80008000 <etext>
    80001a30:	04000937          	lui	s2,0x4000
    80001a34:	197d                	addi	s2,s2,-1
    80001a36:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a38:	0003b997          	auipc	s3,0x3b
    80001a3c:	5d898993          	addi	s3,s3,1496 # 8003d010 <tickslock>
    initlock(&p->lock, "proc");
    80001a40:	85da                	mv	a1,s6
    80001a42:	8526                	mv	a0,s1
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	190080e7          	jalr	400(ra) # 80000bd4 <initlock>
    p->state = UNUSED;
    80001a4c:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001a50:	415487b3          	sub	a5,s1,s5
    80001a54:	878d                	srai	a5,a5,0x3
    80001a56:	000a3703          	ld	a4,0(s4)
    80001a5a:	02e787b3          	mul	a5,a5,a4
    80001a5e:	2785                	addiw	a5,a5,1
    80001a60:	00d7979b          	slliw	a5,a5,0xd
    80001a64:	40f907b3          	sub	a5,s2,a5
    80001a68:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a6a:	2f848493          	addi	s1,s1,760
    80001a6e:	fd3499e3          	bne	s1,s3,80001a40 <procinit+0x6e>
  }
}
    80001a72:	70e2                	ld	ra,56(sp)
    80001a74:	7442                	ld	s0,48(sp)
    80001a76:	74a2                	ld	s1,40(sp)
    80001a78:	7902                	ld	s2,32(sp)
    80001a7a:	69e2                	ld	s3,24(sp)
    80001a7c:	6a42                	ld	s4,16(sp)
    80001a7e:	6aa2                	ld	s5,8(sp)
    80001a80:	6b02                	ld	s6,0(sp)
    80001a82:	6121                	addi	sp,sp,64
    80001a84:	8082                	ret

0000000080001a86 <random>:
// pseudo-random number generator
unsigned short lfsr = 0xACE1u;
unsigned bit;
unsigned
random()
{
    80001a86:	1141                	addi	sp,sp,-16
    80001a88:	e422                	sd	s0,8(sp)
    80001a8a:	0800                	addi	s0,sp,16
  bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) & 1;
    80001a8c:	00007717          	auipc	a4,0x7
    80001a90:	f1870713          	addi	a4,a4,-232 # 800089a4 <lfsr>
    80001a94:	00075503          	lhu	a0,0(a4)
    80001a98:	0025579b          	srliw	a5,a0,0x2
    80001a9c:	0035569b          	srliw	a3,a0,0x3
    80001aa0:	8fb5                	xor	a5,a5,a3
    80001aa2:	8fa9                	xor	a5,a5,a0
    80001aa4:	0055569b          	srliw	a3,a0,0x5
    80001aa8:	8fb5                	xor	a5,a5,a3
    80001aaa:	8b85                	andi	a5,a5,1
    80001aac:	00007697          	auipc	a3,0x7
    80001ab0:	0af6ae23          	sw	a5,188(a3) # 80008b68 <bit>
  return lfsr = (lfsr >> 1) | (bit << 15);
    80001ab4:	0015551b          	srliw	a0,a0,0x1
    80001ab8:	00f7979b          	slliw	a5,a5,0xf
    80001abc:	8d5d                	or	a0,a0,a5
    80001abe:	1542                	slli	a0,a0,0x30
    80001ac0:	9141                	srli	a0,a0,0x30
    80001ac2:	00a71023          	sh	a0,0(a4)
}
    80001ac6:	6422                	ld	s0,8(sp)
    80001ac8:	0141                	addi	sp,sp,16
    80001aca:	8082                	ret

0000000080001acc <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001acc:	1141                	addi	sp,sp,-16
    80001ace:	e422                	sd	s0,8(sp)
    80001ad0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ad2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ad4:	2501                	sext.w	a0,a0
    80001ad6:	6422                	ld	s0,8(sp)
    80001ad8:	0141                	addi	sp,sp,16
    80001ada:	8082                	ret

0000000080001adc <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001adc:	1141                	addi	sp,sp,-16
    80001ade:	e422                	sd	s0,8(sp)
    80001ae0:	0800                	addi	s0,sp,16
    80001ae2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ae4:	2781                	sext.w	a5,a5
    80001ae6:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ae8:	0002f517          	auipc	a0,0x2f
    80001aec:	32850513          	addi	a0,a0,808 # 80030e10 <cpus>
    80001af0:	953e                	add	a0,a0,a5
    80001af2:	6422                	ld	s0,8(sp)
    80001af4:	0141                	addi	sp,sp,16
    80001af6:	8082                	ret

0000000080001af8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001af8:	1101                	addi	sp,sp,-32
    80001afa:	ec06                	sd	ra,24(sp)
    80001afc:	e822                	sd	s0,16(sp)
    80001afe:	e426                	sd	s1,8(sp)
    80001b00:	1000                	addi	s0,sp,32
  push_off();
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	116080e7          	jalr	278(ra) # 80000c18 <push_off>
    80001b0a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b0c:	2781                	sext.w	a5,a5
    80001b0e:	079e                	slli	a5,a5,0x7
    80001b10:	0002f717          	auipc	a4,0x2f
    80001b14:	2d070713          	addi	a4,a4,720 # 80030de0 <pid_lock>
    80001b18:	97ba                	add	a5,a5,a4
    80001b1a:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	19c080e7          	jalr	412(ra) # 80000cb8 <pop_off>
  return p;
}
    80001b24:	8526                	mv	a0,s1
    80001b26:	60e2                	ld	ra,24(sp)
    80001b28:	6442                	ld	s0,16(sp)
    80001b2a:	64a2                	ld	s1,8(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b30:	1141                	addi	sp,sp,-16
    80001b32:	e406                	sd	ra,8(sp)
    80001b34:	e022                	sd	s0,0(sp)
    80001b36:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b38:	00000097          	auipc	ra,0x0
    80001b3c:	fc0080e7          	jalr	-64(ra) # 80001af8 <myproc>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	1d8080e7          	jalr	472(ra) # 80000d18 <release>

  if (first)
    80001b48:	00007797          	auipc	a5,0x7
    80001b4c:	e587a783          	lw	a5,-424(a5) # 800089a0 <first.1>
    80001b50:	eb89                	bnez	a5,80001b62 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b52:	00001097          	auipc	ra,0x1
    80001b56:	102080e7          	jalr	258(ra) # 80002c54 <usertrapret>
}
    80001b5a:	60a2                	ld	ra,8(sp)
    80001b5c:	6402                	ld	s0,0(sp)
    80001b5e:	0141                	addi	sp,sp,16
    80001b60:	8082                	ret
    first = 0;
    80001b62:	00007797          	auipc	a5,0x7
    80001b66:	e207af23          	sw	zero,-450(a5) # 800089a0 <first.1>
    fsinit(ROOTDEV);
    80001b6a:	4505                	li	a0,1
    80001b6c:	00002097          	auipc	ra,0x2
    80001b70:	22a080e7          	jalr	554(ra) # 80003d96 <fsinit>
    80001b74:	bff9                	j	80001b52 <forkret+0x22>

0000000080001b76 <allocpid>:
{
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	e04a                	sd	s2,0(sp)
    80001b80:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b82:	0002f917          	auipc	s2,0x2f
    80001b86:	25e90913          	addi	s2,s2,606 # 80030de0 <pid_lock>
    80001b8a:	854a                	mv	a0,s2
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	0d8080e7          	jalr	216(ra) # 80000c64 <acquire>
  pid = nextpid;
    80001b94:	00007797          	auipc	a5,0x7
    80001b98:	e1478793          	addi	a5,a5,-492 # 800089a8 <nextpid>
    80001b9c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b9e:	0014871b          	addiw	a4,s1,1
    80001ba2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba4:	854a                	mv	a0,s2
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	172080e7          	jalr	370(ra) # 80000d18 <release>
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret

0000000080001bbc <proc_pagetable>:
{
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	addi	s0,sp,32
    80001bc8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	7f2080e7          	jalr	2034(ra) # 800013bc <uvmcreate>
    80001bd2:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bd4:	c121                	beqz	a0,80001c14 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bd6:	4729                	li	a4,10
    80001bd8:	00005697          	auipc	a3,0x5
    80001bdc:	42868693          	addi	a3,a3,1064 # 80007000 <_trampoline>
    80001be0:	6605                	lui	a2,0x1
    80001be2:	040005b7          	lui	a1,0x4000
    80001be6:	15fd                	addi	a1,a1,-1
    80001be8:	05b2                	slli	a1,a1,0xc
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	542080e7          	jalr	1346(ra) # 8000112c <mappages>
    80001bf2:	02054863          	bltz	a0,80001c22 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bf6:	4719                	li	a4,6
    80001bf8:	05893683          	ld	a3,88(s2)
    80001bfc:	6605                	lui	a2,0x1
    80001bfe:	020005b7          	lui	a1,0x2000
    80001c02:	15fd                	addi	a1,a1,-1
    80001c04:	05b6                	slli	a1,a1,0xd
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	524080e7          	jalr	1316(ra) # 8000112c <mappages>
    80001c10:	02054163          	bltz	a0,80001c32 <proc_pagetable+0x76>
}
    80001c14:	8526                	mv	a0,s1
    80001c16:	60e2                	ld	ra,24(sp)
    80001c18:	6442                	ld	s0,16(sp)
    80001c1a:	64a2                	ld	s1,8(sp)
    80001c1c:	6902                	ld	s2,0(sp)
    80001c1e:	6105                	addi	sp,sp,32
    80001c20:	8082                	ret
    uvmfree(pagetable, 0);
    80001c22:	4581                	li	a1,0
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	99a080e7          	jalr	-1638(ra) # 800015c0 <uvmfree>
    return 0;
    80001c2e:	4481                	li	s1,0
    80001c30:	b7d5                	j	80001c14 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c32:	4681                	li	a3,0
    80001c34:	4605                	li	a2,1
    80001c36:	040005b7          	lui	a1,0x4000
    80001c3a:	15fd                	addi	a1,a1,-1
    80001c3c:	05b2                	slli	a1,a1,0xc
    80001c3e:	8526                	mv	a0,s1
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	6b8080e7          	jalr	1720(ra) # 800012f8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c48:	4581                	li	a1,0
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	974080e7          	jalr	-1676(ra) # 800015c0 <uvmfree>
    return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	bf7d                	j	80001c14 <proc_pagetable+0x58>

0000000080001c58 <proc_freepagetable>:
{
    80001c58:	1101                	addi	sp,sp,-32
    80001c5a:	ec06                	sd	ra,24(sp)
    80001c5c:	e822                	sd	s0,16(sp)
    80001c5e:	e426                	sd	s1,8(sp)
    80001c60:	e04a                	sd	s2,0(sp)
    80001c62:	1000                	addi	s0,sp,32
    80001c64:	84aa                	mv	s1,a0
    80001c66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c68:	4681                	li	a3,0
    80001c6a:	4605                	li	a2,1
    80001c6c:	040005b7          	lui	a1,0x4000
    80001c70:	15fd                	addi	a1,a1,-1
    80001c72:	05b2                	slli	a1,a1,0xc
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	684080e7          	jalr	1668(ra) # 800012f8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c7c:	4681                	li	a3,0
    80001c7e:	4605                	li	a2,1
    80001c80:	020005b7          	lui	a1,0x2000
    80001c84:	15fd                	addi	a1,a1,-1
    80001c86:	05b6                	slli	a1,a1,0xd
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	66e080e7          	jalr	1646(ra) # 800012f8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c92:	85ca                	mv	a1,s2
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	92a080e7          	jalr	-1750(ra) # 800015c0 <uvmfree>
}
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6902                	ld	s2,0(sp)
    80001ca6:	6105                	addi	sp,sp,32
    80001ca8:	8082                	ret

0000000080001caa <freeproc>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	addi	s0,sp,32
    80001cb4:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001cb6:	6d28                	ld	a0,88(a0)
    80001cb8:	c509                	beqz	a0,80001cc2 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	d30080e7          	jalr	-720(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001cc2:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001cc6:	68a8                	ld	a0,80(s1)
    80001cc8:	c511                	beqz	a0,80001cd4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cca:	64ac                	ld	a1,72(s1)
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	f8c080e7          	jalr	-116(ra) # 80001c58 <proc_freepagetable>
  p->pagetable = 0;
    80001cd4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cd8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cdc:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ce0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ce4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ce8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cec:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cf0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cf4:	0004ac23          	sw	zero,24(s1)
  p->static_priority = 0;
    80001cf8:	2e04a423          	sw	zero,744(s1)
  p->niceness = 5;
    80001cfc:	4795                	li	a5,5
    80001cfe:	2ef4a623          	sw	a5,748(s1)
  p->rtime = 0;
    80001d02:	2a04a023          	sw	zero,672(s1)
  p->stime = 0;
    80001d06:	2a04a623          	sw	zero,684(s1)
  p->sched_ct = 0;
    80001d0a:	2a04a823          	sw	zero,688(s1)
  p->etime = 0;
    80001d0e:	2a04a423          	sw	zero,680(s1)
}
    80001d12:	60e2                	ld	ra,24(sp)
    80001d14:	6442                	ld	s0,16(sp)
    80001d16:	64a2                	ld	s1,8(sp)
    80001d18:	6105                	addi	sp,sp,32
    80001d1a:	8082                	ret

0000000080001d1c <allocproc>:
{
    80001d1c:	1101                	addi	sp,sp,-32
    80001d1e:	ec06                	sd	ra,24(sp)
    80001d20:	e822                	sd	s0,16(sp)
    80001d22:	e426                	sd	s1,8(sp)
    80001d24:	e04a                	sd	s2,0(sp)
    80001d26:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d28:	0002f497          	auipc	s1,0x2f
    80001d2c:	4e848493          	addi	s1,s1,1256 # 80031210 <proc>
    80001d30:	0003b917          	auipc	s2,0x3b
    80001d34:	2e090913          	addi	s2,s2,736 # 8003d010 <tickslock>
    acquire(&p->lock);
    80001d38:	8526                	mv	a0,s1
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	f2a080e7          	jalr	-214(ra) # 80000c64 <acquire>
    if (p->state == UNUSED)
    80001d42:	4c9c                	lw	a5,24(s1)
    80001d44:	cf81                	beqz	a5,80001d5c <allocproc+0x40>
      release(&p->lock);
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	fd0080e7          	jalr	-48(ra) # 80000d18 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d50:	2f848493          	addi	s1,s1,760
    80001d54:	ff2492e3          	bne	s1,s2,80001d38 <allocproc+0x1c>
  return 0;
    80001d58:	4481                	li	s1,0
    80001d5a:	a0c9                	j	80001e1c <allocproc+0x100>
  p->pid = allocpid();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	e1a080e7          	jalr	-486(ra) # 80001b76 <allocpid>
    80001d64:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d66:	4785                	li	a5,1
    80001d68:	cc9c                	sw	a5,24(s1)
  p->queue_position = 0;
    80001d6a:	2c04a423          	sw	zero,712(s1)
  p->ticks_used = 0;
    80001d6e:	2c04a623          	sw	zero,716(s1)
  p->in_queue = 0;
    80001d72:	2c04b023          	sd	zero,704(s1)
  p->curr_wait_time = 0;
    80001d76:	2a04bc23          	sd	zero,696(s1)
  p->queue_entry = 0;
    80001d7a:	2e04a223          	sw	zero,740(s1)
    p->queue_time[i] = 0;
    80001d7e:	2c04a823          	sw	zero,720(s1)
    80001d82:	2c04aa23          	sw	zero,724(s1)
    80001d86:	2c04ac23          	sw	zero,728(s1)
    80001d8a:	2c04ae23          	sw	zero,732(s1)
    80001d8e:	2e04a023          	sw	zero,736(s1)
  p->static_priority = 60;
    80001d92:	03c00793          	li	a5,60
    80001d96:	2ef4a423          	sw	a5,744(s1)
  p->niceness = 5;
    80001d9a:	4795                	li	a5,5
    80001d9c:	2ef4a623          	sw	a5,748(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	d94080e7          	jalr	-620(ra) # 80000b34 <kalloc>
    80001da8:	892a                	mv	s2,a0
    80001daa:	eca8                	sd	a0,88(s1)
    80001dac:	cd3d                	beqz	a0,80001e2a <allocproc+0x10e>
  p->pagetable = proc_pagetable(p);
    80001dae:	8526                	mv	a0,s1
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	e0c080e7          	jalr	-500(ra) # 80001bbc <proc_pagetable>
    80001db8:	892a                	mv	s2,a0
    80001dba:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001dbc:	c159                	beqz	a0,80001e42 <allocproc+0x126>
  memset(&p->context, 0, sizeof(p->context));
    80001dbe:	07000613          	li	a2,112
    80001dc2:	4581                	li	a1,0
    80001dc4:	06048513          	addi	a0,s1,96
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	f98080e7          	jalr	-104(ra) # 80000d60 <memset>
  p->context.ra = (uint64)forkret;
    80001dd0:	00000797          	auipc	a5,0x0
    80001dd4:	d6078793          	addi	a5,a5,-672 # 80001b30 <forkret>
    80001dd8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dda:	60bc                	ld	a5,64(s1)
    80001ddc:	6705                	lui	a4,0x1
    80001dde:	97ba                	add	a5,a5,a4
    80001de0:	f4bc                	sd	a5,104(s1)
  p->max_alarm_ticks = -1;
    80001de2:	57fd                	li	a5,-1
    80001de4:	16f4a623          	sw	a5,364(s1)
  p->alarm_ticks = -1;
    80001de8:	16f4a823          	sw	a5,368(s1)
  p->handler = -1;
    80001dec:	16f4bc23          	sd	a5,376(s1)
  p->rtime = 0;
    80001df0:	2a04a023          	sw	zero,672(s1)
  p->etime = 0;
    80001df4:	2a04a423          	sw	zero,680(s1)
  p->ctime = ticks;
    80001df8:	00007797          	auipc	a5,0x7
    80001dfc:	d807a783          	lw	a5,-640(a5) # 80008b78 <ticks>
    80001e00:	2af4a223          	sw	a5,676(s1)
  p->stime = 0;
    80001e04:	2a04a623          	sw	zero,684(s1)
  p->ticks_used = 0;
    80001e08:	2c04a623          	sw	zero,716(s1)
  p->queue_position = 0;
    80001e0c:	2c04a423          	sw	zero,712(s1)
  p->in_queue = 0;
    80001e10:	2c04b023          	sd	zero,704(s1)
  p->queue_entry = 0;
    80001e14:	2e04a223          	sw	zero,740(s1)
  p->curr_wait_time = 0;
    80001e18:	2a04bc23          	sd	zero,696(s1)
}
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	60e2                	ld	ra,24(sp)
    80001e20:	6442                	ld	s0,16(sp)
    80001e22:	64a2                	ld	s1,8(sp)
    80001e24:	6902                	ld	s2,0(sp)
    80001e26:	6105                	addi	sp,sp,32
    80001e28:	8082                	ret
    freeproc(p);
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	e7e080e7          	jalr	-386(ra) # 80001caa <freeproc>
    release(&p->lock);
    80001e34:	8526                	mv	a0,s1
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	ee2080e7          	jalr	-286(ra) # 80000d18 <release>
    return 0;
    80001e3e:	84ca                	mv	s1,s2
    80001e40:	bff1                	j	80001e1c <allocproc+0x100>
    freeproc(p);
    80001e42:	8526                	mv	a0,s1
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	e66080e7          	jalr	-410(ra) # 80001caa <freeproc>
    release(&p->lock);
    80001e4c:	8526                	mv	a0,s1
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	eca080e7          	jalr	-310(ra) # 80000d18 <release>
    return 0;
    80001e56:	84ca                	mv	s1,s2
    80001e58:	b7d1                	j	80001e1c <allocproc+0x100>

0000000080001e5a <userinit>:
{
    80001e5a:	1101                	addi	sp,sp,-32
    80001e5c:	ec06                	sd	ra,24(sp)
    80001e5e:	e822                	sd	s0,16(sp)
    80001e60:	e426                	sd	s1,8(sp)
    80001e62:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	eb8080e7          	jalr	-328(ra) # 80001d1c <allocproc>
    80001e6c:	84aa                	mv	s1,a0
  initproc = p;
    80001e6e:	00007797          	auipc	a5,0x7
    80001e72:	d0a7b123          	sd	a0,-766(a5) # 80008b70 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e76:	03400613          	li	a2,52
    80001e7a:	00007597          	auipc	a1,0x7
    80001e7e:	b3658593          	addi	a1,a1,-1226 # 800089b0 <initcode>
    80001e82:	6928                	ld	a0,80(a0)
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	566080e7          	jalr	1382(ra) # 800013ea <uvmfirst>
  p->sz = PGSIZE;
    80001e8c:	6785                	lui	a5,0x1
    80001e8e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e90:	6cb8                	ld	a4,88(s1)
    80001e92:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e96:	6cb8                	ld	a4,88(s1)
    80001e98:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e9a:	4641                	li	a2,16
    80001e9c:	00006597          	auipc	a1,0x6
    80001ea0:	36c58593          	addi	a1,a1,876 # 80008208 <digits+0x1c8>
    80001ea4:	15848513          	addi	a0,s1,344
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	002080e7          	jalr	2(ra) # 80000eaa <safestrcpy>
  p->cwd = namei("/");
    80001eb0:	00006517          	auipc	a0,0x6
    80001eb4:	36850513          	addi	a0,a0,872 # 80008218 <digits+0x1d8>
    80001eb8:	00003097          	auipc	ra,0x3
    80001ebc:	900080e7          	jalr	-1792(ra) # 800047b8 <namei>
    80001ec0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ec4:	478d                	li	a5,3
    80001ec6:	cc9c                	sw	a5,24(s1)
  p->tickets = DEFAULT_TICKETS;
    80001ec8:	00007797          	auipc	a5,0x7
    80001ecc:	ae47a783          	lw	a5,-1308(a5) # 800089ac <DEFAULT_TICKETS>
    80001ed0:	2ef4a823          	sw	a5,752(s1)
  release(&p->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	e42080e7          	jalr	-446(ra) # 80000d18 <release>
}
    80001ede:	60e2                	ld	ra,24(sp)
    80001ee0:	6442                	ld	s0,16(sp)
    80001ee2:	64a2                	ld	s1,8(sp)
    80001ee4:	6105                	addi	sp,sp,32
    80001ee6:	8082                	ret

0000000080001ee8 <growproc>:
{
    80001ee8:	1101                	addi	sp,sp,-32
    80001eea:	ec06                	sd	ra,24(sp)
    80001eec:	e822                	sd	s0,16(sp)
    80001eee:	e426                	sd	s1,8(sp)
    80001ef0:	e04a                	sd	s2,0(sp)
    80001ef2:	1000                	addi	s0,sp,32
    80001ef4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001ef6:	00000097          	auipc	ra,0x0
    80001efa:	c02080e7          	jalr	-1022(ra) # 80001af8 <myproc>
    80001efe:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f00:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f02:	01204c63          	bgtz	s2,80001f1a <growproc+0x32>
  else if (n < 0)
    80001f06:	02094663          	bltz	s2,80001f32 <growproc+0x4a>
  p->sz = sz;
    80001f0a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f0c:	4501                	li	a0,0
}
    80001f0e:	60e2                	ld	ra,24(sp)
    80001f10:	6442                	ld	s0,16(sp)
    80001f12:	64a2                	ld	s1,8(sp)
    80001f14:	6902                	ld	s2,0(sp)
    80001f16:	6105                	addi	sp,sp,32
    80001f18:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f1a:	4691                	li	a3,4
    80001f1c:	00b90633          	add	a2,s2,a1
    80001f20:	6928                	ld	a0,80(a0)
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	582080e7          	jalr	1410(ra) # 800014a4 <uvmalloc>
    80001f2a:	85aa                	mv	a1,a0
    80001f2c:	fd79                	bnez	a0,80001f0a <growproc+0x22>
      return -1;
    80001f2e:	557d                	li	a0,-1
    80001f30:	bff9                	j	80001f0e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f32:	00b90633          	add	a2,s2,a1
    80001f36:	6928                	ld	a0,80(a0)
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	524080e7          	jalr	1316(ra) # 8000145c <uvmdealloc>
    80001f40:	85aa                	mv	a1,a0
    80001f42:	b7e1                	j	80001f0a <growproc+0x22>

0000000080001f44 <fork>:
{
    80001f44:	7139                	addi	sp,sp,-64
    80001f46:	fc06                	sd	ra,56(sp)
    80001f48:	f822                	sd	s0,48(sp)
    80001f4a:	f426                	sd	s1,40(sp)
    80001f4c:	f04a                	sd	s2,32(sp)
    80001f4e:	ec4e                	sd	s3,24(sp)
    80001f50:	e852                	sd	s4,16(sp)
    80001f52:	e456                	sd	s5,8(sp)
    80001f54:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	ba2080e7          	jalr	-1118(ra) # 80001af8 <myproc>
    80001f5e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f60:	00000097          	auipc	ra,0x0
    80001f64:	dbc080e7          	jalr	-580(ra) # 80001d1c <allocproc>
    80001f68:	12050463          	beqz	a0,80002090 <fork+0x14c>
    80001f6c:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f6e:	048ab603          	ld	a2,72(s5)
    80001f72:	692c                	ld	a1,80(a0)
    80001f74:	050ab503          	ld	a0,80(s5)
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	680080e7          	jalr	1664(ra) # 800015f8 <uvmcopy>
    80001f80:	06054063          	bltz	a0,80001fe0 <fork+0x9c>
  np->sz = p->sz;
    80001f84:	048ab783          	ld	a5,72(s5)
    80001f88:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f8c:	058ab683          	ld	a3,88(s5)
    80001f90:	87b6                	mv	a5,a3
    80001f92:	0589b703          	ld	a4,88(s3)
    80001f96:	12068693          	addi	a3,a3,288
    80001f9a:	0007b803          	ld	a6,0(a5)
    80001f9e:	6788                	ld	a0,8(a5)
    80001fa0:	6b8c                	ld	a1,16(a5)
    80001fa2:	6f90                	ld	a2,24(a5)
    80001fa4:	01073023          	sd	a6,0(a4)
    80001fa8:	e708                	sd	a0,8(a4)
    80001faa:	eb0c                	sd	a1,16(a4)
    80001fac:	ef10                	sd	a2,24(a4)
    80001fae:	02078793          	addi	a5,a5,32
    80001fb2:	02070713          	addi	a4,a4,32
    80001fb6:	fed792e3          	bne	a5,a3,80001f9a <fork+0x56>
  np->tickets = p->tickets;
    80001fba:	2f0aa783          	lw	a5,752(s5)
    80001fbe:	2ef9a823          	sw	a5,752(s3)
  np->trace_mask = p->trace_mask;
    80001fc2:	168aa783          	lw	a5,360(s5)
    80001fc6:	16f9a423          	sw	a5,360(s3)
  np->trapframe->a0 = 0;
    80001fca:	0589b783          	ld	a5,88(s3)
    80001fce:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fd2:	0d0a8493          	addi	s1,s5,208
    80001fd6:	0d098913          	addi	s2,s3,208
    80001fda:	150a8a13          	addi	s4,s5,336
    80001fde:	a00d                	j	80002000 <fork+0xbc>
    freeproc(np);
    80001fe0:	854e                	mv	a0,s3
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	cc8080e7          	jalr	-824(ra) # 80001caa <freeproc>
    release(&np->lock);
    80001fea:	854e                	mv	a0,s3
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	d2c080e7          	jalr	-724(ra) # 80000d18 <release>
    return -1;
    80001ff4:	597d                	li	s2,-1
    80001ff6:	a059                	j	8000207c <fork+0x138>
  for (i = 0; i < NOFILE; i++)
    80001ff8:	04a1                	addi	s1,s1,8
    80001ffa:	0921                	addi	s2,s2,8
    80001ffc:	01448b63          	beq	s1,s4,80002012 <fork+0xce>
    if (p->ofile[i])
    80002000:	6088                	ld	a0,0(s1)
    80002002:	d97d                	beqz	a0,80001ff8 <fork+0xb4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002004:	00003097          	auipc	ra,0x3
    80002008:	e4a080e7          	jalr	-438(ra) # 80004e4e <filedup>
    8000200c:	00a93023          	sd	a0,0(s2)
    80002010:	b7e5                	j	80001ff8 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002012:	150ab503          	ld	a0,336(s5)
    80002016:	00002097          	auipc	ra,0x2
    8000201a:	fbe080e7          	jalr	-66(ra) # 80003fd4 <idup>
    8000201e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002022:	4641                	li	a2,16
    80002024:	158a8593          	addi	a1,s5,344
    80002028:	15898513          	addi	a0,s3,344
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	e7e080e7          	jalr	-386(ra) # 80000eaa <safestrcpy>
  pid = np->pid;
    80002034:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002038:	854e                	mv	a0,s3
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	cde080e7          	jalr	-802(ra) # 80000d18 <release>
  acquire(&wait_lock);
    80002042:	0002f497          	auipc	s1,0x2f
    80002046:	db648493          	addi	s1,s1,-586 # 80030df8 <wait_lock>
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c18080e7          	jalr	-1000(ra) # 80000c64 <acquire>
  np->parent = p;
    80002054:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	cbe080e7          	jalr	-834(ra) # 80000d18 <release>
  acquire(&np->lock);
    80002062:	854e                	mv	a0,s3
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c00080e7          	jalr	-1024(ra) # 80000c64 <acquire>
  np->state = RUNNABLE;
    8000206c:	478d                	li	a5,3
    8000206e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002072:	854e                	mv	a0,s3
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	ca4080e7          	jalr	-860(ra) # 80000d18 <release>
}
    8000207c:	854a                	mv	a0,s2
    8000207e:	70e2                	ld	ra,56(sp)
    80002080:	7442                	ld	s0,48(sp)
    80002082:	74a2                	ld	s1,40(sp)
    80002084:	7902                	ld	s2,32(sp)
    80002086:	69e2                	ld	s3,24(sp)
    80002088:	6a42                	ld	s4,16(sp)
    8000208a:	6aa2                	ld	s5,8(sp)
    8000208c:	6121                	addi	sp,sp,64
    8000208e:	8082                	ret
    return -1;
    80002090:	597d                	li	s2,-1
    80002092:	b7ed                	j	8000207c <fork+0x138>

0000000080002094 <totalTickets>:
{
    80002094:	1141                	addi	sp,sp,-16
    80002096:	e422                	sd	s0,8(sp)
    80002098:	0800                	addi	s0,sp,16
  struct proc *p = proc;
    8000209a:	0002f797          	auipc	a5,0x2f
    8000209e:	17678793          	addi	a5,a5,374 # 80031210 <proc>
  int total = 0;
    800020a2:	4501                	li	a0,0
    if (p->state == RUNNABLE)
    800020a4:	460d                	li	a2,3
  while (p < &proc[NPROC])
    800020a6:	0003b697          	auipc	a3,0x3b
    800020aa:	f6a68693          	addi	a3,a3,-150 # 8003d010 <tickslock>
    800020ae:	a029                	j	800020b8 <totalTickets+0x24>
    p++;
    800020b0:	2f878793          	addi	a5,a5,760
  while (p < &proc[NPROC])
    800020b4:	00d78963          	beq	a5,a3,800020c6 <totalTickets+0x32>
    if (p->state == RUNNABLE)
    800020b8:	4f98                	lw	a4,24(a5)
    800020ba:	fec71be3          	bne	a4,a2,800020b0 <totalTickets+0x1c>
      total += p->tickets;
    800020be:	2f07a703          	lw	a4,752(a5)
    800020c2:	9d39                	addw	a0,a0,a4
    800020c4:	b7f5                	j	800020b0 <totalTickets+0x1c>
}
    800020c6:	6422                	ld	s0,8(sp)
    800020c8:	0141                	addi	sp,sp,16
    800020ca:	8082                	ret

00000000800020cc <update_time>:
{
    800020cc:	7179                	addi	sp,sp,-48
    800020ce:	f406                	sd	ra,40(sp)
    800020d0:	f022                	sd	s0,32(sp)
    800020d2:	ec26                	sd	s1,24(sp)
    800020d4:	e84a                	sd	s2,16(sp)
    800020d6:	e44e                	sd	s3,8(sp)
    800020d8:	e052                	sd	s4,0(sp)
    800020da:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    800020dc:	0002f497          	auipc	s1,0x2f
    800020e0:	13448493          	addi	s1,s1,308 # 80031210 <proc>
    if (p->state == RUNNING || p->state == SLEEPING || p->state == RUNNABLE)
    800020e4:	4909                	li	s2,2
    if (p->state == SLEEPING || p->state == RUNNABLE)
    800020e6:	4a05                	li	s4,1
  for (p = proc; p < &proc[NPROC]; p++)
    800020e8:	0003b997          	auipc	s3,0x3b
    800020ec:	f2898993          	addi	s3,s3,-216 # 8003d010 <tickslock>
    800020f0:	a00d                	j	80002112 <update_time+0x46>
      p->curr_wait_time++;
    800020f2:	2b84b783          	ld	a5,696(s1)
    800020f6:	0785                	addi	a5,a5,1
    800020f8:	2af4bc23          	sd	a5,696(s1)
    else if (p->state == SLEEPING)
    800020fc:	05260663          	beq	a2,s2,80002148 <update_time+0x7c>
    release(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	c16080e7          	jalr	-1002(ra) # 80000d18 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000210a:	2f848493          	addi	s1,s1,760
    8000210e:	05348363          	beq	s1,s3,80002154 <update_time+0x88>
    acquire(&p->lock);
    80002112:	8526                	mv	a0,s1
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	b50080e7          	jalr	-1200(ra) # 80000c64 <acquire>
    if (p->state == RUNNING || p->state == SLEEPING || p->state == RUNNABLE)
    8000211c:	4c90                	lw	a2,24(s1)
    8000211e:	ffe6069b          	addiw	a3,a2,-2
    80002122:	fcd96fe3          	bltu	s2,a3,80002100 <update_time+0x34>
      p->queue_time[p->queue_position]++;
    80002126:	2c84a783          	lw	a5,712(s1)
    8000212a:	078a                	slli	a5,a5,0x2
    8000212c:	97a6                	add	a5,a5,s1
    8000212e:	2d07a703          	lw	a4,720(a5)
    80002132:	2705                	addiw	a4,a4,1
    80002134:	2ce7a823          	sw	a4,720(a5)
    if (p->state == SLEEPING || p->state == RUNNABLE)
    80002138:	fada7de3          	bgeu	s4,a3,800020f2 <update_time+0x26>
      p->rtime++;
    8000213c:	2a04a783          	lw	a5,672(s1)
    80002140:	2785                	addiw	a5,a5,1
    80002142:	2af4a023          	sw	a5,672(s1)
    80002146:	bf6d                	j	80002100 <update_time+0x34>
      p->stime++;
    80002148:	2ac4a783          	lw	a5,684(s1)
    8000214c:	2785                	addiw	a5,a5,1
    8000214e:	2af4a623          	sw	a5,684(s1)
    80002152:	b77d                	j	80002100 <update_time+0x34>
}
    80002154:	70a2                	ld	ra,40(sp)
    80002156:	7402                	ld	s0,32(sp)
    80002158:	64e2                	ld	s1,24(sp)
    8000215a:	6942                	ld	s2,16(sp)
    8000215c:	69a2                	ld	s3,8(sp)
    8000215e:	6a02                	ld	s4,0(sp)
    80002160:	6145                	addi	sp,sp,48
    80002162:	8082                	ret

0000000080002164 <max>:
{
    80002164:	1141                	addi	sp,sp,-16
    80002166:	e422                	sd	s0,8(sp)
    80002168:	0800                	addi	s0,sp,16
}
    8000216a:	00b57363          	bgeu	a0,a1,80002170 <max+0xc>
    8000216e:	852e                	mv	a0,a1
    80002170:	6422                	ld	s0,8(sp)
    80002172:	0141                	addi	sp,sp,16
    80002174:	8082                	ret

0000000080002176 <min>:
{
    80002176:	1141                	addi	sp,sp,-16
    80002178:	e422                	sd	s0,8(sp)
    8000217a:	0800                	addi	s0,sp,16
}
    8000217c:	00a5f363          	bgeu	a1,a0,80002182 <min+0xc>
    80002180:	852e                	mv	a0,a1
    80002182:	6422                	ld	s0,8(sp)
    80002184:	0141                	addi	sp,sp,16
    80002186:	8082                	ret

0000000080002188 <get_dynamic_priority>:
{
    80002188:	1141                	addi	sp,sp,-16
    8000218a:	e422                	sd	s0,8(sp)
    8000218c:	0800                	addi	s0,sp,16
  if (p->rtime == 0)
    8000218e:	2a052703          	lw	a4,672(a0)
    niceness = 5;
    80002192:	4795                	li	a5,5
  if (p->rtime == 0)
    80002194:	cf09                	beqz	a4,800021ae <get_dynamic_priority+0x26>
    niceness = (p->stime / (p->rtime + p->stime)) * 10;
    80002196:	2ac52783          	lw	a5,684(a0)
    8000219a:	9f3d                	addw	a4,a4,a5
    8000219c:	02e7d73b          	divuw	a4,a5,a4
    800021a0:	0027179b          	slliw	a5,a4,0x2
    800021a4:	9fb9                	addw	a5,a5,a4
    800021a6:	0017979b          	slliw	a5,a5,0x1
    800021aa:	1782                	slli	a5,a5,0x20
    800021ac:	9381                	srli	a5,a5,0x20
  p->niceness = niceness;
    800021ae:	2ef52623          	sw	a5,748(a0)
  uint64 min_val = min(p->static_priority - niceness + 5, 100);
    800021b2:	2e852503          	lw	a0,744(a0)
    800021b6:	0515                	addi	a0,a0,5
    800021b8:	8d1d                	sub	a0,a0,a5
  if (a < b)
    800021ba:	06300793          	li	a5,99
    800021be:	00a7f463          	bgeu	a5,a0,800021c6 <get_dynamic_priority+0x3e>
    return b;
    800021c2:	06400513          	li	a0,100
}
    800021c6:	6422                	ld	s0,8(sp)
    800021c8:	0141                	addi	sp,sp,16
    800021ca:	8082                	ret

00000000800021cc <scheduler>:
{
    800021cc:	7159                	addi	sp,sp,-112
    800021ce:	f486                	sd	ra,104(sp)
    800021d0:	f0a2                	sd	s0,96(sp)
    800021d2:	eca6                	sd	s1,88(sp)
    800021d4:	e8ca                	sd	s2,80(sp)
    800021d6:	e4ce                	sd	s3,72(sp)
    800021d8:	e0d2                	sd	s4,64(sp)
    800021da:	fc56                	sd	s5,56(sp)
    800021dc:	f85a                	sd	s6,48(sp)
    800021de:	f45e                	sd	s7,40(sp)
    800021e0:	f062                	sd	s8,32(sp)
    800021e2:	ec66                	sd	s9,24(sp)
    800021e4:	e86a                	sd	s10,16(sp)
    800021e6:	e46e                	sd	s11,8(sp)
    800021e8:	1880                	addi	s0,sp,112
    800021ea:	8492                	mv	s1,tp
  int id = r_tp();
    800021ec:	2481                	sext.w	s1,s1
  c->proc = 0;
    800021ee:	00749d93          	slli	s11,s1,0x7
    800021f2:	0002f797          	auipc	a5,0x2f
    800021f6:	bee78793          	addi	a5,a5,-1042 # 80030de0 <pid_lock>
    800021fa:	97ee                	add	a5,a5,s11
    800021fc:	0207b823          	sd	zero,48(a5)
  printf("scheduler: FCFS\n");
    80002200:	00006517          	auipc	a0,0x6
    80002204:	02050513          	addi	a0,a0,32 # 80008220 <digits+0x1e0>
    80002208:	ffffe097          	auipc	ra,0xffffe
    8000220c:	380080e7          	jalr	896(ra) # 80000588 <printf>
        swtch(&c->context, &p_least_time->context);
    80002210:	0002f797          	auipc	a5,0x2f
    80002214:	c0878793          	addi	a5,a5,-1016 # 80030e18 <cpus+0x8>
    80002218:	9dbe                	add	s11,s11,a5
  struct proc *p_least_time = proc;
    8000221a:	0002f917          	auipc	s2,0x2f
    8000221e:	ff690913          	addi	s2,s2,-10 # 80031210 <proc>
      if (p->state == RUNNABLE)
    80002222:	498d                	li	s3,3
    80002224:	4c85                	li	s9,1
        c->proc = p_least_time;
    80002226:	049e                	slli	s1,s1,0x7
    80002228:	0002fc17          	auipc	s8,0x2f
    8000222c:	bb8c0c13          	addi	s8,s8,-1096 # 80030de0 <pid_lock>
    80002230:	9c26                	add	s8,s8,s1
    for (p = proc; p < &proc[NPROC]; p++)
    80002232:	0003ba97          	auipc	s5,0x3b
    80002236:	ddea8a93          	addi	s5,s5,-546 # 8003d010 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000223a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000223e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002242:	10079073          	csrw	sstatus,a5
    int min_ticks = -1;
    80002246:	5bfd                	li	s7,-1
    int flag = 0;
    80002248:	4b01                	li	s6,0
    for (p = proc; p < &proc[NPROC]; p++)
    8000224a:	0002f497          	auipc	s1,0x2f
    8000224e:	fc648493          	addi	s1,s1,-58 # 80031210 <proc>
        p_least_time->state = RUNNING;
    80002252:	4d11                	li	s10,4
    80002254:	a805                	j	80002284 <scheduler+0xb8>
          min_ticks = p->ctime;
    80002256:	2a44ab83          	lw	s7,676(s1)
        if (flag == 0)
    8000225a:	8926                	mv	s2,s1
    8000225c:	8b66                	mv	s6,s9
      acquire(&p_least_time->lock);
    8000225e:	8a4a                	mv	s4,s2
    80002260:	854a                	mv	a0,s2
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	a02080e7          	jalr	-1534(ra) # 80000c64 <acquire>
      if (p_least_time->state == RUNNABLE)
    8000226a:	01892783          	lw	a5,24(s2)
    8000226e:	03378563          	beq	a5,s3,80002298 <scheduler+0xcc>
      release(&p_least_time->lock);
    80002272:	8552                	mv	a0,s4
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	aa4080e7          	jalr	-1372(ra) # 80000d18 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000227c:	2f848493          	addi	s1,s1,760
    80002280:	fb548de3          	beq	s1,s5,8000223a <scheduler+0x6e>
      if (p->state == RUNNABLE)
    80002284:	4c9c                	lw	a5,24(s1)
    80002286:	fd379ce3          	bne	a5,s3,8000225e <scheduler+0x92>
        if (flag == 0 || p->ctime < min_ticks)
    8000228a:	fc0b06e3          	beqz	s6,80002256 <scheduler+0x8a>
    8000228e:	2a44a783          	lw	a5,676(s1)
    80002292:	fd77f6e3          	bgeu	a5,s7,8000225e <scheduler+0x92>
    80002296:	b7c1                	j	80002256 <scheduler+0x8a>
        p_least_time->state = RUNNING;
    80002298:	01a92c23          	sw	s10,24(s2)
        c->proc = p_least_time;
    8000229c:	032c3823          	sd	s2,48(s8)
        swtch(&c->context, &p_least_time->context);
    800022a0:	06090593          	addi	a1,s2,96
    800022a4:	856e                	mv	a0,s11
    800022a6:	00001097          	auipc	ra,0x1
    800022aa:	904080e7          	jalr	-1788(ra) # 80002baa <swtch>
        c->proc = 0;
    800022ae:	020c3823          	sd	zero,48(s8)
    800022b2:	b7c1                	j	80002272 <scheduler+0xa6>

00000000800022b4 <sched>:
{
    800022b4:	7179                	addi	sp,sp,-48
    800022b6:	f406                	sd	ra,40(sp)
    800022b8:	f022                	sd	s0,32(sp)
    800022ba:	ec26                	sd	s1,24(sp)
    800022bc:	e84a                	sd	s2,16(sp)
    800022be:	e44e                	sd	s3,8(sp)
    800022c0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	836080e7          	jalr	-1994(ra) # 80001af8 <myproc>
    800022ca:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	91e080e7          	jalr	-1762(ra) # 80000bea <holding>
    800022d4:	c93d                	beqz	a0,8000234a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022d6:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022d8:	2781                	sext.w	a5,a5
    800022da:	079e                	slli	a5,a5,0x7
    800022dc:	0002f717          	auipc	a4,0x2f
    800022e0:	b0470713          	addi	a4,a4,-1276 # 80030de0 <pid_lock>
    800022e4:	97ba                	add	a5,a5,a4
    800022e6:	0a87a703          	lw	a4,168(a5)
    800022ea:	4785                	li	a5,1
    800022ec:	06f71763          	bne	a4,a5,8000235a <sched+0xa6>
  if (p->state == RUNNING)
    800022f0:	4c98                	lw	a4,24(s1)
    800022f2:	4791                	li	a5,4
    800022f4:	06f70b63          	beq	a4,a5,8000236a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022f8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022fc:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022fe:	efb5                	bnez	a5,8000237a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002300:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002302:	0002f917          	auipc	s2,0x2f
    80002306:	ade90913          	addi	s2,s2,-1314 # 80030de0 <pid_lock>
    8000230a:	2781                	sext.w	a5,a5
    8000230c:	079e                	slli	a5,a5,0x7
    8000230e:	97ca                	add	a5,a5,s2
    80002310:	0ac7a983          	lw	s3,172(a5)
    80002314:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002316:	2781                	sext.w	a5,a5
    80002318:	079e                	slli	a5,a5,0x7
    8000231a:	0002f597          	auipc	a1,0x2f
    8000231e:	afe58593          	addi	a1,a1,-1282 # 80030e18 <cpus+0x8>
    80002322:	95be                	add	a1,a1,a5
    80002324:	06048513          	addi	a0,s1,96
    80002328:	00001097          	auipc	ra,0x1
    8000232c:	882080e7          	jalr	-1918(ra) # 80002baa <swtch>
    80002330:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002332:	2781                	sext.w	a5,a5
    80002334:	079e                	slli	a5,a5,0x7
    80002336:	97ca                	add	a5,a5,s2
    80002338:	0b37a623          	sw	s3,172(a5)
}
    8000233c:	70a2                	ld	ra,40(sp)
    8000233e:	7402                	ld	s0,32(sp)
    80002340:	64e2                	ld	s1,24(sp)
    80002342:	6942                	ld	s2,16(sp)
    80002344:	69a2                	ld	s3,8(sp)
    80002346:	6145                	addi	sp,sp,48
    80002348:	8082                	ret
    panic("sched p->lock");
    8000234a:	00006517          	auipc	a0,0x6
    8000234e:	eee50513          	addi	a0,a0,-274 # 80008238 <digits+0x1f8>
    80002352:	ffffe097          	auipc	ra,0xffffe
    80002356:	1ec080e7          	jalr	492(ra) # 8000053e <panic>
    panic("sched locks");
    8000235a:	00006517          	auipc	a0,0x6
    8000235e:	eee50513          	addi	a0,a0,-274 # 80008248 <digits+0x208>
    80002362:	ffffe097          	auipc	ra,0xffffe
    80002366:	1dc080e7          	jalr	476(ra) # 8000053e <panic>
    panic("sched running");
    8000236a:	00006517          	auipc	a0,0x6
    8000236e:	eee50513          	addi	a0,a0,-274 # 80008258 <digits+0x218>
    80002372:	ffffe097          	auipc	ra,0xffffe
    80002376:	1cc080e7          	jalr	460(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	eee50513          	addi	a0,a0,-274 # 80008268 <digits+0x228>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	1bc080e7          	jalr	444(ra) # 8000053e <panic>

000000008000238a <yield>:
{
    8000238a:	1101                	addi	sp,sp,-32
    8000238c:	ec06                	sd	ra,24(sp)
    8000238e:	e822                	sd	s0,16(sp)
    80002390:	e426                	sd	s1,8(sp)
    80002392:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	764080e7          	jalr	1892(ra) # 80001af8 <myproc>
    8000239c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8c6080e7          	jalr	-1850(ra) # 80000c64 <acquire>
  p->state = RUNNABLE;
    800023a6:	478d                	li	a5,3
    800023a8:	cc9c                	sw	a5,24(s1)
  sched();
    800023aa:	00000097          	auipc	ra,0x0
    800023ae:	f0a080e7          	jalr	-246(ra) # 800022b4 <sched>
  release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	964080e7          	jalr	-1692(ra) # 80000d18 <release>
}
    800023bc:	60e2                	ld	ra,24(sp)
    800023be:	6442                	ld	s0,16(sp)
    800023c0:	64a2                	ld	s1,8(sp)
    800023c2:	6105                	addi	sp,sp,32
    800023c4:	8082                	ret

00000000800023c6 <set_static_priority>:
{
    800023c6:	7179                	addi	sp,sp,-48
    800023c8:	f406                	sd	ra,40(sp)
    800023ca:	f022                	sd	s0,32(sp)
    800023cc:	ec26                	sd	s1,24(sp)
    800023ce:	e84a                	sd	s2,16(sp)
    800023d0:	e44e                	sd	s3,8(sp)
    800023d2:	e052                	sd	s4,0(sp)
    800023d4:	1800                	addi	s0,sp,48
    800023d6:	84aa                	mv	s1,a0
    800023d8:	892e                	mv	s2,a1
    if (myproc() != p)
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	71e080e7          	jalr	1822(ra) # 80001af8 <myproc>
    800023e2:	0002f797          	auipc	a5,0x2f
    800023e6:	e2e78793          	addi	a5,a5,-466 # 80031210 <proc>
    800023ea:	04a78b63          	beq	a5,a0,80002440 <set_static_priority+0x7a>
        old_priority = p->static_priority;
    800023ee:	8a3e                	mv	s4,a5
    800023f0:	2e87a983          	lw	s3,744(a5)
        acquire(&p->lock);
    800023f4:	853e                	mv	a0,a5
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	86e080e7          	jalr	-1938(ra) # 80000c64 <acquire>
        if (p->pid == pid)
    800023fe:	030a2783          	lw	a5,48(s4)
    80002402:	03278563          	beq	a5,s2,8000242c <set_static_priority+0x66>
        release(&p->lock);
    80002406:	0002f517          	auipc	a0,0x2f
    8000240a:	e0a50513          	addi	a0,a0,-502 # 80031210 <proc>
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	90a080e7          	jalr	-1782(ra) # 80000d18 <release>
    if (priority < old_priority)
    80002416:	0534cc63          	blt	s1,s3,8000246e <set_static_priority+0xa8>
}
    8000241a:	854e                	mv	a0,s3
    8000241c:	70a2                	ld	ra,40(sp)
    8000241e:	7402                	ld	s0,32(sp)
    80002420:	64e2                	ld	s1,24(sp)
    80002422:	6942                	ld	s2,16(sp)
    80002424:	69a2                	ld	s3,8(sp)
    80002426:	6a02                	ld	s4,0(sp)
    80002428:	6145                	addi	sp,sp,48
    8000242a:	8082                	ret
          p->niceness = 5;
    8000242c:	4715                	li	a4,5
    8000242e:	2eea2623          	sw	a4,748(s4)
          p->rtime = 0;
    80002432:	2a0a2023          	sw	zero,672(s4)
          p->stime = 0;
    80002436:	2a0a2623          	sw	zero,684(s4)
          p->static_priority = priority;
    8000243a:	2e9a2423          	sw	s1,744(s4)
    8000243e:	b7e1                	j	80002406 <set_static_priority+0x40>
    else if (p->pid == pid)
    80002440:	0002f797          	auipc	a5,0x2f
    80002444:	e007a783          	lw	a5,-512(a5) # 80031240 <proc+0x30>
  int old_priority = 0;
    80002448:	4981                	li	s3,0
    else if (p->pid == pid)
    8000244a:	fd2796e3          	bne	a5,s2,80002416 <set_static_priority+0x50>
      old_priority = p->static_priority;
    8000244e:	0002f797          	auipc	a5,0x2f
    80002452:	dc278793          	addi	a5,a5,-574 # 80031210 <proc>
    80002456:	2e87a983          	lw	s3,744(a5)
      p->niceness = 5;
    8000245a:	4715                	li	a4,5
    8000245c:	2ee7a623          	sw	a4,748(a5)
      p->rtime = 0;
    80002460:	2a07a023          	sw	zero,672(a5)
      p->stime = 0;
    80002464:	2a07a623          	sw	zero,684(a5)
      p->static_priority = priority;
    80002468:	2e97a423          	sw	s1,744(a5)
    8000246c:	b76d                	j	80002416 <set_static_priority+0x50>
      yield();
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	f1c080e7          	jalr	-228(ra) # 8000238a <yield>
    80002476:	b755                	j	8000241a <set_static_priority+0x54>

0000000080002478 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002478:	7179                	addi	sp,sp,-48
    8000247a:	f406                	sd	ra,40(sp)
    8000247c:	f022                	sd	s0,32(sp)
    8000247e:	ec26                	sd	s1,24(sp)
    80002480:	e84a                	sd	s2,16(sp)
    80002482:	e44e                	sd	s3,8(sp)
    80002484:	1800                	addi	s0,sp,48
    80002486:	89aa                	mv	s3,a0
    80002488:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	66e080e7          	jalr	1646(ra) # 80001af8 <myproc>
    80002492:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	7d0080e7          	jalr	2000(ra) # 80000c64 <acquire>
  release(lk);
    8000249c:	854a                	mv	a0,s2
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	87a080e7          	jalr	-1926(ra) # 80000d18 <release>

  // Go to sleep.
  p->chan = chan;
    800024a6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800024aa:	4789                	li	a5,2
    800024ac:	cc9c                	sw	a5,24(s1)

  sched();
    800024ae:	00000097          	auipc	ra,0x0
    800024b2:	e06080e7          	jalr	-506(ra) # 800022b4 <sched>

  // Tidy up.
  p->chan = 0;
    800024b6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	85c080e7          	jalr	-1956(ra) # 80000d18 <release>
  acquire(lk);
    800024c4:	854a                	mv	a0,s2
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	79e080e7          	jalr	1950(ra) # 80000c64 <acquire>
}
    800024ce:	70a2                	ld	ra,40(sp)
    800024d0:	7402                	ld	s0,32(sp)
    800024d2:	64e2                	ld	s1,24(sp)
    800024d4:	6942                	ld	s2,16(sp)
    800024d6:	69a2                	ld	s3,8(sp)
    800024d8:	6145                	addi	sp,sp,48
    800024da:	8082                	ret

00000000800024dc <waitx>:
{
    800024dc:	711d                	addi	sp,sp,-96
    800024de:	ec86                	sd	ra,88(sp)
    800024e0:	e8a2                	sd	s0,80(sp)
    800024e2:	e4a6                	sd	s1,72(sp)
    800024e4:	e0ca                	sd	s2,64(sp)
    800024e6:	fc4e                	sd	s3,56(sp)
    800024e8:	f852                	sd	s4,48(sp)
    800024ea:	f456                	sd	s5,40(sp)
    800024ec:	f05a                	sd	s6,32(sp)
    800024ee:	ec5e                	sd	s7,24(sp)
    800024f0:	e862                	sd	s8,16(sp)
    800024f2:	e466                	sd	s9,8(sp)
    800024f4:	e06a                	sd	s10,0(sp)
    800024f6:	1080                	addi	s0,sp,96
    800024f8:	8b2a                	mv	s6,a0
    800024fa:	8bae                	mv	s7,a1
    800024fc:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	5fa080e7          	jalr	1530(ra) # 80001af8 <myproc>
    80002506:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002508:	0002f517          	auipc	a0,0x2f
    8000250c:	8f050513          	addi	a0,a0,-1808 # 80030df8 <wait_lock>
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	754080e7          	jalr	1876(ra) # 80000c64 <acquire>
    havekids = 0;
    80002518:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    8000251a:	4a15                	li	s4,5
        havekids = 1;
    8000251c:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000251e:	0003b997          	auipc	s3,0x3b
    80002522:	af298993          	addi	s3,s3,-1294 # 8003d010 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002526:	0002fd17          	auipc	s10,0x2f
    8000252a:	8d2d0d13          	addi	s10,s10,-1838 # 80030df8 <wait_lock>
    havekids = 0;
    8000252e:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002530:	0002f497          	auipc	s1,0x2f
    80002534:	ce048493          	addi	s1,s1,-800 # 80031210 <proc>
    80002538:	a059                	j	800025be <waitx+0xe2>
          pid = np->pid;
    8000253a:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000253e:	2a04a703          	lw	a4,672(s1)
    80002542:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002546:	2a44a783          	lw	a5,676(s1)
    8000254a:	9f3d                	addw	a4,a4,a5
    8000254c:	2a84a783          	lw	a5,680(s1)
    80002550:	9f99                	subw	a5,a5,a4
    80002552:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffb61d0>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002556:	000b0e63          	beqz	s6,80002572 <waitx+0x96>
    8000255a:	4691                	li	a3,4
    8000255c:	02c48613          	addi	a2,s1,44
    80002560:	85da                	mv	a1,s6
    80002562:	05093503          	ld	a0,80(s2)
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	188080e7          	jalr	392(ra) # 800016ee <copyout>
    8000256e:	02054563          	bltz	a0,80002598 <waitx+0xbc>
          freeproc(np);
    80002572:	8526                	mv	a0,s1
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	736080e7          	jalr	1846(ra) # 80001caa <freeproc>
          release(&np->lock);
    8000257c:	8526                	mv	a0,s1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	79a080e7          	jalr	1946(ra) # 80000d18 <release>
          release(&wait_lock);
    80002586:	0002f517          	auipc	a0,0x2f
    8000258a:	87250513          	addi	a0,a0,-1934 # 80030df8 <wait_lock>
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	78a080e7          	jalr	1930(ra) # 80000d18 <release>
          return pid;
    80002596:	a09d                	j	800025fc <waitx+0x120>
            release(&np->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	77e080e7          	jalr	1918(ra) # 80000d18 <release>
            release(&wait_lock);
    800025a2:	0002f517          	auipc	a0,0x2f
    800025a6:	85650513          	addi	a0,a0,-1962 # 80030df8 <wait_lock>
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	76e080e7          	jalr	1902(ra) # 80000d18 <release>
            return -1;
    800025b2:	59fd                	li	s3,-1
    800025b4:	a0a1                	j	800025fc <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800025b6:	2f848493          	addi	s1,s1,760
    800025ba:	03348463          	beq	s1,s3,800025e2 <waitx+0x106>
      if (np->parent == p)
    800025be:	7c9c                	ld	a5,56(s1)
    800025c0:	ff279be3          	bne	a5,s2,800025b6 <waitx+0xda>
        acquire(&np->lock);
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	69e080e7          	jalr	1694(ra) # 80000c64 <acquire>
        if (np->state == ZOMBIE)
    800025ce:	4c9c                	lw	a5,24(s1)
    800025d0:	f74785e3          	beq	a5,s4,8000253a <waitx+0x5e>
        release(&np->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	742080e7          	jalr	1858(ra) # 80000d18 <release>
        havekids = 1;
    800025de:	8756                	mv	a4,s5
    800025e0:	bfd9                	j	800025b6 <waitx+0xda>
    if (!havekids || p->killed)
    800025e2:	c701                	beqz	a4,800025ea <waitx+0x10e>
    800025e4:	02892783          	lw	a5,40(s2)
    800025e8:	cb8d                	beqz	a5,8000261a <waitx+0x13e>
      release(&wait_lock);
    800025ea:	0002f517          	auipc	a0,0x2f
    800025ee:	80e50513          	addi	a0,a0,-2034 # 80030df8 <wait_lock>
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	726080e7          	jalr	1830(ra) # 80000d18 <release>
      return -1;
    800025fa:	59fd                	li	s3,-1
}
    800025fc:	854e                	mv	a0,s3
    800025fe:	60e6                	ld	ra,88(sp)
    80002600:	6446                	ld	s0,80(sp)
    80002602:	64a6                	ld	s1,72(sp)
    80002604:	6906                	ld	s2,64(sp)
    80002606:	79e2                	ld	s3,56(sp)
    80002608:	7a42                	ld	s4,48(sp)
    8000260a:	7aa2                	ld	s5,40(sp)
    8000260c:	7b02                	ld	s6,32(sp)
    8000260e:	6be2                	ld	s7,24(sp)
    80002610:	6c42                	ld	s8,16(sp)
    80002612:	6ca2                	ld	s9,8(sp)
    80002614:	6d02                	ld	s10,0(sp)
    80002616:	6125                	addi	sp,sp,96
    80002618:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000261a:	85ea                	mv	a1,s10
    8000261c:	854a                	mv	a0,s2
    8000261e:	00000097          	auipc	ra,0x0
    80002622:	e5a080e7          	jalr	-422(ra) # 80002478 <sleep>
    havekids = 0;
    80002626:	b721                	j	8000252e <waitx+0x52>

0000000080002628 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002628:	7139                	addi	sp,sp,-64
    8000262a:	fc06                	sd	ra,56(sp)
    8000262c:	f822                	sd	s0,48(sp)
    8000262e:	f426                	sd	s1,40(sp)
    80002630:	f04a                	sd	s2,32(sp)
    80002632:	ec4e                	sd	s3,24(sp)
    80002634:	e852                	sd	s4,16(sp)
    80002636:	e456                	sd	s5,8(sp)
    80002638:	0080                	addi	s0,sp,64
    8000263a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000263c:	0002f497          	auipc	s1,0x2f
    80002640:	bd448493          	addi	s1,s1,-1068 # 80031210 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002644:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002646:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002648:	0003b917          	auipc	s2,0x3b
    8000264c:	9c890913          	addi	s2,s2,-1592 # 8003d010 <tickslock>
    80002650:	a811                	j	80002664 <wakeup+0x3c>
      }
      release(&p->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	6c4080e7          	jalr	1732(ra) # 80000d18 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000265c:	2f848493          	addi	s1,s1,760
    80002660:	03248663          	beq	s1,s2,8000268c <wakeup+0x64>
    if (p != myproc())
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	494080e7          	jalr	1172(ra) # 80001af8 <myproc>
    8000266c:	fea488e3          	beq	s1,a0,8000265c <wakeup+0x34>
      acquire(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	5f2080e7          	jalr	1522(ra) # 80000c64 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000267a:	4c9c                	lw	a5,24(s1)
    8000267c:	fd379be3          	bne	a5,s3,80002652 <wakeup+0x2a>
    80002680:	709c                	ld	a5,32(s1)
    80002682:	fd4798e3          	bne	a5,s4,80002652 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002686:	0154ac23          	sw	s5,24(s1)
    8000268a:	b7e1                	j	80002652 <wakeup+0x2a>
    }
  }
}
    8000268c:	70e2                	ld	ra,56(sp)
    8000268e:	7442                	ld	s0,48(sp)
    80002690:	74a2                	ld	s1,40(sp)
    80002692:	7902                	ld	s2,32(sp)
    80002694:	69e2                	ld	s3,24(sp)
    80002696:	6a42                	ld	s4,16(sp)
    80002698:	6aa2                	ld	s5,8(sp)
    8000269a:	6121                	addi	sp,sp,64
    8000269c:	8082                	ret

000000008000269e <reparent>:
{
    8000269e:	7179                	addi	sp,sp,-48
    800026a0:	f406                	sd	ra,40(sp)
    800026a2:	f022                	sd	s0,32(sp)
    800026a4:	ec26                	sd	s1,24(sp)
    800026a6:	e84a                	sd	s2,16(sp)
    800026a8:	e44e                	sd	s3,8(sp)
    800026aa:	e052                	sd	s4,0(sp)
    800026ac:	1800                	addi	s0,sp,48
    800026ae:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800026b0:	0002f497          	auipc	s1,0x2f
    800026b4:	b6048493          	addi	s1,s1,-1184 # 80031210 <proc>
      pp->parent = initproc;
    800026b8:	00006a17          	auipc	s4,0x6
    800026bc:	4b8a0a13          	addi	s4,s4,1208 # 80008b70 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800026c0:	0003b997          	auipc	s3,0x3b
    800026c4:	95098993          	addi	s3,s3,-1712 # 8003d010 <tickslock>
    800026c8:	a029                	j	800026d2 <reparent+0x34>
    800026ca:	2f848493          	addi	s1,s1,760
    800026ce:	01348d63          	beq	s1,s3,800026e8 <reparent+0x4a>
    if (pp->parent == p)
    800026d2:	7c9c                	ld	a5,56(s1)
    800026d4:	ff279be3          	bne	a5,s2,800026ca <reparent+0x2c>
      pp->parent = initproc;
    800026d8:	000a3503          	ld	a0,0(s4)
    800026dc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026de:	00000097          	auipc	ra,0x0
    800026e2:	f4a080e7          	jalr	-182(ra) # 80002628 <wakeup>
    800026e6:	b7d5                	j	800026ca <reparent+0x2c>
}
    800026e8:	70a2                	ld	ra,40(sp)
    800026ea:	7402                	ld	s0,32(sp)
    800026ec:	64e2                	ld	s1,24(sp)
    800026ee:	6942                	ld	s2,16(sp)
    800026f0:	69a2                	ld	s3,8(sp)
    800026f2:	6a02                	ld	s4,0(sp)
    800026f4:	6145                	addi	sp,sp,48
    800026f6:	8082                	ret

00000000800026f8 <exit>:
{
    800026f8:	7179                	addi	sp,sp,-48
    800026fa:	f406                	sd	ra,40(sp)
    800026fc:	f022                	sd	s0,32(sp)
    800026fe:	ec26                	sd	s1,24(sp)
    80002700:	e84a                	sd	s2,16(sp)
    80002702:	e44e                	sd	s3,8(sp)
    80002704:	e052                	sd	s4,0(sp)
    80002706:	1800                	addi	s0,sp,48
    80002708:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000270a:	fffff097          	auipc	ra,0xfffff
    8000270e:	3ee080e7          	jalr	1006(ra) # 80001af8 <myproc>
    80002712:	89aa                	mv	s3,a0
  if (p == initproc)
    80002714:	00006797          	auipc	a5,0x6
    80002718:	45c7b783          	ld	a5,1116(a5) # 80008b70 <initproc>
    8000271c:	0d050493          	addi	s1,a0,208
    80002720:	15050913          	addi	s2,a0,336
    80002724:	02a79363          	bne	a5,a0,8000274a <exit+0x52>
    panic("init exiting");
    80002728:	00006517          	auipc	a0,0x6
    8000272c:	b5850513          	addi	a0,a0,-1192 # 80008280 <digits+0x240>
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	e0e080e7          	jalr	-498(ra) # 8000053e <panic>
      fileclose(f);
    80002738:	00002097          	auipc	ra,0x2
    8000273c:	768080e7          	jalr	1896(ra) # 80004ea0 <fileclose>
      p->ofile[fd] = 0;
    80002740:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002744:	04a1                	addi	s1,s1,8
    80002746:	01248563          	beq	s1,s2,80002750 <exit+0x58>
    if (p->ofile[fd])
    8000274a:	6088                	ld	a0,0(s1)
    8000274c:	f575                	bnez	a0,80002738 <exit+0x40>
    8000274e:	bfdd                	j	80002744 <exit+0x4c>
  begin_op();
    80002750:	00002097          	auipc	ra,0x2
    80002754:	284080e7          	jalr	644(ra) # 800049d4 <begin_op>
  iput(p->cwd);
    80002758:	1509b503          	ld	a0,336(s3)
    8000275c:	00002097          	auipc	ra,0x2
    80002760:	a70080e7          	jalr	-1424(ra) # 800041cc <iput>
  end_op();
    80002764:	00002097          	auipc	ra,0x2
    80002768:	2f0080e7          	jalr	752(ra) # 80004a54 <end_op>
  p->cwd = 0;
    8000276c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002770:	0002e497          	auipc	s1,0x2e
    80002774:	68848493          	addi	s1,s1,1672 # 80030df8 <wait_lock>
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	4ea080e7          	jalr	1258(ra) # 80000c64 <acquire>
  reparent(p);
    80002782:	854e                	mv	a0,s3
    80002784:	00000097          	auipc	ra,0x0
    80002788:	f1a080e7          	jalr	-230(ra) # 8000269e <reparent>
  wakeup(p->parent);
    8000278c:	0389b503          	ld	a0,56(s3)
    80002790:	00000097          	auipc	ra,0x0
    80002794:	e98080e7          	jalr	-360(ra) # 80002628 <wakeup>
  acquire(&p->lock);
    80002798:	854e                	mv	a0,s3
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	4ca080e7          	jalr	1226(ra) # 80000c64 <acquire>
  p->xstate = status;
    800027a2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027a6:	4795                	li	a5,5
    800027a8:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800027ac:	00006797          	auipc	a5,0x6
    800027b0:	3cc7a783          	lw	a5,972(a5) # 80008b78 <ticks>
    800027b4:	2af9a423          	sw	a5,680(s3)
  release(&wait_lock);
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	55e080e7          	jalr	1374(ra) # 80000d18 <release>
  sched();
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	af2080e7          	jalr	-1294(ra) # 800022b4 <sched>
  panic("zombie exit");
    800027ca:	00006517          	auipc	a0,0x6
    800027ce:	ac650513          	addi	a0,a0,-1338 # 80008290 <digits+0x250>
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	d6c080e7          	jalr	-660(ra) # 8000053e <panic>

00000000800027da <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800027da:	7179                	addi	sp,sp,-48
    800027dc:	f406                	sd	ra,40(sp)
    800027de:	f022                	sd	s0,32(sp)
    800027e0:	ec26                	sd	s1,24(sp)
    800027e2:	e84a                	sd	s2,16(sp)
    800027e4:	e44e                	sd	s3,8(sp)
    800027e6:	1800                	addi	s0,sp,48
    800027e8:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800027ea:	0002f497          	auipc	s1,0x2f
    800027ee:	a2648493          	addi	s1,s1,-1498 # 80031210 <proc>
    800027f2:	0003b997          	auipc	s3,0x3b
    800027f6:	81e98993          	addi	s3,s3,-2018 # 8003d010 <tickslock>
  {
    acquire(&p->lock);
    800027fa:	8526                	mv	a0,s1
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	468080e7          	jalr	1128(ra) # 80000c64 <acquire>
    if (p->pid == pid)
    80002804:	589c                	lw	a5,48(s1)
    80002806:	01278d63          	beq	a5,s2,80002820 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	50c080e7          	jalr	1292(ra) # 80000d18 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002814:	2f848493          	addi	s1,s1,760
    80002818:	ff3491e3          	bne	s1,s3,800027fa <kill+0x20>
  }
  return -1;
    8000281c:	557d                	li	a0,-1
    8000281e:	a829                	j	80002838 <kill+0x5e>
      p->killed = 1;
    80002820:	4785                	li	a5,1
    80002822:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002824:	4c98                	lw	a4,24(s1)
    80002826:	4789                	li	a5,2
    80002828:	00f70f63          	beq	a4,a5,80002846 <kill+0x6c>
      release(&p->lock);
    8000282c:	8526                	mv	a0,s1
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	4ea080e7          	jalr	1258(ra) # 80000d18 <release>
      return 0;
    80002836:	4501                	li	a0,0
}
    80002838:	70a2                	ld	ra,40(sp)
    8000283a:	7402                	ld	s0,32(sp)
    8000283c:	64e2                	ld	s1,24(sp)
    8000283e:	6942                	ld	s2,16(sp)
    80002840:	69a2                	ld	s3,8(sp)
    80002842:	6145                	addi	sp,sp,48
    80002844:	8082                	ret
        p->state = RUNNABLE;
    80002846:	478d                	li	a5,3
    80002848:	cc9c                	sw	a5,24(s1)
    8000284a:	b7cd                	j	8000282c <kill+0x52>

000000008000284c <setkilled>:

void setkilled(struct proc *p)
{
    8000284c:	1101                	addi	sp,sp,-32
    8000284e:	ec06                	sd	ra,24(sp)
    80002850:	e822                	sd	s0,16(sp)
    80002852:	e426                	sd	s1,8(sp)
    80002854:	1000                	addi	s0,sp,32
    80002856:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	40c080e7          	jalr	1036(ra) # 80000c64 <acquire>
  p->killed = 1;
    80002860:	4785                	li	a5,1
    80002862:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	4b2080e7          	jalr	1202(ra) # 80000d18 <release>
}
    8000286e:	60e2                	ld	ra,24(sp)
    80002870:	6442                	ld	s0,16(sp)
    80002872:	64a2                	ld	s1,8(sp)
    80002874:	6105                	addi	sp,sp,32
    80002876:	8082                	ret

0000000080002878 <killed>:

int killed(struct proc *p)
{
    80002878:	1101                	addi	sp,sp,-32
    8000287a:	ec06                	sd	ra,24(sp)
    8000287c:	e822                	sd	s0,16(sp)
    8000287e:	e426                	sd	s1,8(sp)
    80002880:	e04a                	sd	s2,0(sp)
    80002882:	1000                	addi	s0,sp,32
    80002884:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	3de080e7          	jalr	990(ra) # 80000c64 <acquire>
  k = p->killed;
    8000288e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002892:	8526                	mv	a0,s1
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	484080e7          	jalr	1156(ra) # 80000d18 <release>
  return k;
}
    8000289c:	854a                	mv	a0,s2
    8000289e:	60e2                	ld	ra,24(sp)
    800028a0:	6442                	ld	s0,16(sp)
    800028a2:	64a2                	ld	s1,8(sp)
    800028a4:	6902                	ld	s2,0(sp)
    800028a6:	6105                	addi	sp,sp,32
    800028a8:	8082                	ret

00000000800028aa <wait>:
{
    800028aa:	715d                	addi	sp,sp,-80
    800028ac:	e486                	sd	ra,72(sp)
    800028ae:	e0a2                	sd	s0,64(sp)
    800028b0:	fc26                	sd	s1,56(sp)
    800028b2:	f84a                	sd	s2,48(sp)
    800028b4:	f44e                	sd	s3,40(sp)
    800028b6:	f052                	sd	s4,32(sp)
    800028b8:	ec56                	sd	s5,24(sp)
    800028ba:	e85a                	sd	s6,16(sp)
    800028bc:	e45e                	sd	s7,8(sp)
    800028be:	e062                	sd	s8,0(sp)
    800028c0:	0880                	addi	s0,sp,80
    800028c2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	234080e7          	jalr	564(ra) # 80001af8 <myproc>
    800028cc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028ce:	0002e517          	auipc	a0,0x2e
    800028d2:	52a50513          	addi	a0,a0,1322 # 80030df8 <wait_lock>
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	38e080e7          	jalr	910(ra) # 80000c64 <acquire>
    havekids = 0;
    800028de:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800028e0:	4a15                	li	s4,5
        havekids = 1;
    800028e2:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028e4:	0003a997          	auipc	s3,0x3a
    800028e8:	72c98993          	addi	s3,s3,1836 # 8003d010 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028ec:	0002ec17          	auipc	s8,0x2e
    800028f0:	50cc0c13          	addi	s8,s8,1292 # 80030df8 <wait_lock>
    havekids = 0;
    800028f4:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028f6:	0002f497          	auipc	s1,0x2f
    800028fa:	91a48493          	addi	s1,s1,-1766 # 80031210 <proc>
    800028fe:	a0bd                	j	8000296c <wait+0xc2>
          pid = pp->pid;
    80002900:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002904:	000b0e63          	beqz	s6,80002920 <wait+0x76>
    80002908:	4691                	li	a3,4
    8000290a:	02c48613          	addi	a2,s1,44
    8000290e:	85da                	mv	a1,s6
    80002910:	05093503          	ld	a0,80(s2)
    80002914:	fffff097          	auipc	ra,0xfffff
    80002918:	dda080e7          	jalr	-550(ra) # 800016ee <copyout>
    8000291c:	02054563          	bltz	a0,80002946 <wait+0x9c>
          freeproc(pp);
    80002920:	8526                	mv	a0,s1
    80002922:	fffff097          	auipc	ra,0xfffff
    80002926:	388080e7          	jalr	904(ra) # 80001caa <freeproc>
          release(&pp->lock);
    8000292a:	8526                	mv	a0,s1
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	3ec080e7          	jalr	1004(ra) # 80000d18 <release>
          release(&wait_lock);
    80002934:	0002e517          	auipc	a0,0x2e
    80002938:	4c450513          	addi	a0,a0,1220 # 80030df8 <wait_lock>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	3dc080e7          	jalr	988(ra) # 80000d18 <release>
          return pid;
    80002944:	a0b5                	j	800029b0 <wait+0x106>
            release(&pp->lock);
    80002946:	8526                	mv	a0,s1
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	3d0080e7          	jalr	976(ra) # 80000d18 <release>
            release(&wait_lock);
    80002950:	0002e517          	auipc	a0,0x2e
    80002954:	4a850513          	addi	a0,a0,1192 # 80030df8 <wait_lock>
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	3c0080e7          	jalr	960(ra) # 80000d18 <release>
            return -1;
    80002960:	59fd                	li	s3,-1
    80002962:	a0b9                	j	800029b0 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002964:	2f848493          	addi	s1,s1,760
    80002968:	03348463          	beq	s1,s3,80002990 <wait+0xe6>
      if (pp->parent == p)
    8000296c:	7c9c                	ld	a5,56(s1)
    8000296e:	ff279be3          	bne	a5,s2,80002964 <wait+0xba>
        acquire(&pp->lock);
    80002972:	8526                	mv	a0,s1
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	2f0080e7          	jalr	752(ra) # 80000c64 <acquire>
        if (pp->state == ZOMBIE)
    8000297c:	4c9c                	lw	a5,24(s1)
    8000297e:	f94781e3          	beq	a5,s4,80002900 <wait+0x56>
        release(&pp->lock);
    80002982:	8526                	mv	a0,s1
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	394080e7          	jalr	916(ra) # 80000d18 <release>
        havekids = 1;
    8000298c:	8756                	mv	a4,s5
    8000298e:	bfd9                	j	80002964 <wait+0xba>
    if (!havekids || killed(p))
    80002990:	c719                	beqz	a4,8000299e <wait+0xf4>
    80002992:	854a                	mv	a0,s2
    80002994:	00000097          	auipc	ra,0x0
    80002998:	ee4080e7          	jalr	-284(ra) # 80002878 <killed>
    8000299c:	c51d                	beqz	a0,800029ca <wait+0x120>
      release(&wait_lock);
    8000299e:	0002e517          	auipc	a0,0x2e
    800029a2:	45a50513          	addi	a0,a0,1114 # 80030df8 <wait_lock>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	372080e7          	jalr	882(ra) # 80000d18 <release>
      return -1;
    800029ae:	59fd                	li	s3,-1
}
    800029b0:	854e                	mv	a0,s3
    800029b2:	60a6                	ld	ra,72(sp)
    800029b4:	6406                	ld	s0,64(sp)
    800029b6:	74e2                	ld	s1,56(sp)
    800029b8:	7942                	ld	s2,48(sp)
    800029ba:	79a2                	ld	s3,40(sp)
    800029bc:	7a02                	ld	s4,32(sp)
    800029be:	6ae2                	ld	s5,24(sp)
    800029c0:	6b42                	ld	s6,16(sp)
    800029c2:	6ba2                	ld	s7,8(sp)
    800029c4:	6c02                	ld	s8,0(sp)
    800029c6:	6161                	addi	sp,sp,80
    800029c8:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800029ca:	85e2                	mv	a1,s8
    800029cc:	854a                	mv	a0,s2
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	aaa080e7          	jalr	-1366(ra) # 80002478 <sleep>
    havekids = 0;
    800029d6:	bf39                	j	800028f4 <wait+0x4a>

00000000800029d8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029d8:	7179                	addi	sp,sp,-48
    800029da:	f406                	sd	ra,40(sp)
    800029dc:	f022                	sd	s0,32(sp)
    800029de:	ec26                	sd	s1,24(sp)
    800029e0:	e84a                	sd	s2,16(sp)
    800029e2:	e44e                	sd	s3,8(sp)
    800029e4:	e052                	sd	s4,0(sp)
    800029e6:	1800                	addi	s0,sp,48
    800029e8:	84aa                	mv	s1,a0
    800029ea:	892e                	mv	s2,a1
    800029ec:	89b2                	mv	s3,a2
    800029ee:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	108080e7          	jalr	264(ra) # 80001af8 <myproc>
  if (user_dst)
    800029f8:	c08d                	beqz	s1,80002a1a <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800029fa:	86d2                	mv	a3,s4
    800029fc:	864e                	mv	a2,s3
    800029fe:	85ca                	mv	a1,s2
    80002a00:	6928                	ld	a0,80(a0)
    80002a02:	fffff097          	auipc	ra,0xfffff
    80002a06:	cec080e7          	jalr	-788(ra) # 800016ee <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a0a:	70a2                	ld	ra,40(sp)
    80002a0c:	7402                	ld	s0,32(sp)
    80002a0e:	64e2                	ld	s1,24(sp)
    80002a10:	6942                	ld	s2,16(sp)
    80002a12:	69a2                	ld	s3,8(sp)
    80002a14:	6a02                	ld	s4,0(sp)
    80002a16:	6145                	addi	sp,sp,48
    80002a18:	8082                	ret
    memmove((char *)dst, src, len);
    80002a1a:	000a061b          	sext.w	a2,s4
    80002a1e:	85ce                	mv	a1,s3
    80002a20:	854a                	mv	a0,s2
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	39a080e7          	jalr	922(ra) # 80000dbc <memmove>
    return 0;
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	bff9                	j	80002a0a <either_copyout+0x32>

0000000080002a2e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a2e:	7179                	addi	sp,sp,-48
    80002a30:	f406                	sd	ra,40(sp)
    80002a32:	f022                	sd	s0,32(sp)
    80002a34:	ec26                	sd	s1,24(sp)
    80002a36:	e84a                	sd	s2,16(sp)
    80002a38:	e44e                	sd	s3,8(sp)
    80002a3a:	e052                	sd	s4,0(sp)
    80002a3c:	1800                	addi	s0,sp,48
    80002a3e:	892a                	mv	s2,a0
    80002a40:	84ae                	mv	s1,a1
    80002a42:	89b2                	mv	s3,a2
    80002a44:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	0b2080e7          	jalr	178(ra) # 80001af8 <myproc>
  if (user_src)
    80002a4e:	c08d                	beqz	s1,80002a70 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002a50:	86d2                	mv	a3,s4
    80002a52:	864e                	mv	a2,s3
    80002a54:	85ca                	mv	a1,s2
    80002a56:	6928                	ld	a0,80(a0)
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	da2080e7          	jalr	-606(ra) # 800017fa <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002a60:	70a2                	ld	ra,40(sp)
    80002a62:	7402                	ld	s0,32(sp)
    80002a64:	64e2                	ld	s1,24(sp)
    80002a66:	6942                	ld	s2,16(sp)
    80002a68:	69a2                	ld	s3,8(sp)
    80002a6a:	6a02                	ld	s4,0(sp)
    80002a6c:	6145                	addi	sp,sp,48
    80002a6e:	8082                	ret
    memmove(dst, (char *)src, len);
    80002a70:	000a061b          	sext.w	a2,s4
    80002a74:	85ce                	mv	a1,s3
    80002a76:	854a                	mv	a0,s2
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	344080e7          	jalr	836(ra) # 80000dbc <memmove>
    return 0;
    80002a80:	8526                	mv	a0,s1
    80002a82:	bff9                	j	80002a60 <either_copyin+0x32>

0000000080002a84 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002a84:	715d                	addi	sp,sp,-80
    80002a86:	e486                	sd	ra,72(sp)
    80002a88:	e0a2                	sd	s0,64(sp)
    80002a8a:	fc26                	sd	s1,56(sp)
    80002a8c:	f84a                	sd	s2,48(sp)
    80002a8e:	f44e                	sd	s3,40(sp)
    80002a90:	f052                	sd	s4,32(sp)
    80002a92:	ec56                	sd	s5,24(sp)
    80002a94:	e85a                	sd	s6,16(sp)
    80002a96:	e45e                	sd	s7,8(sp)
    80002a98:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	8f650513          	addi	a0,a0,-1802 # 80008390 <states.0+0xa8>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	ae6080e7          	jalr	-1306(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002aaa:	0002f497          	auipc	s1,0x2f
    80002aae:	8be48493          	addi	s1,s1,-1858 # 80031368 <proc+0x158>
    80002ab2:	0003a917          	auipc	s2,0x3a
    80002ab6:	6b690913          	addi	s2,s2,1718 # 8003d168 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aba:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002abc:	00005997          	auipc	s3,0x5
    80002ac0:	7e498993          	addi	s3,s3,2020 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002ac4:	00005a97          	auipc	s5,0x5
    80002ac8:	7e4a8a93          	addi	s5,s5,2020 # 800082a8 <digits+0x268>
    printf("\n");
    80002acc:	00006a17          	auipc	s4,0x6
    80002ad0:	8c4a0a13          	addi	s4,s4,-1852 # 80008390 <states.0+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ad4:	00006b97          	auipc	s7,0x6
    80002ad8:	814b8b93          	addi	s7,s7,-2028 # 800082e8 <states.0>
    80002adc:	a00d                	j	80002afe <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002ade:	ed86a583          	lw	a1,-296(a3)
    80002ae2:	8556                	mv	a0,s5
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	aa4080e7          	jalr	-1372(ra) # 80000588 <printf>
    printf("\n");
    80002aec:	8552                	mv	a0,s4
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a9a080e7          	jalr	-1382(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002af6:	2f848493          	addi	s1,s1,760
    80002afa:	03248163          	beq	s1,s2,80002b1c <procdump+0x98>
    if (p->state == UNUSED)
    80002afe:	86a6                	mv	a3,s1
    80002b00:	ec04a783          	lw	a5,-320(s1)
    80002b04:	dbed                	beqz	a5,80002af6 <procdump+0x72>
      state = "???";
    80002b06:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b08:	fcfb6be3          	bltu	s6,a5,80002ade <procdump+0x5a>
    80002b0c:	1782                	slli	a5,a5,0x20
    80002b0e:	9381                	srli	a5,a5,0x20
    80002b10:	078e                	slli	a5,a5,0x3
    80002b12:	97de                	add	a5,a5,s7
    80002b14:	6390                	ld	a2,0(a5)
    80002b16:	f661                	bnez	a2,80002ade <procdump+0x5a>
      state = "???";
    80002b18:	864e                	mv	a2,s3
    80002b1a:	b7d1                	j	80002ade <procdump+0x5a>
  }
}
    80002b1c:	60a6                	ld	ra,72(sp)
    80002b1e:	6406                	ld	s0,64(sp)
    80002b20:	74e2                	ld	s1,56(sp)
    80002b22:	7942                	ld	s2,48(sp)
    80002b24:	79a2                	ld	s3,40(sp)
    80002b26:	7a02                	ld	s4,32(sp)
    80002b28:	6ae2                	ld	s5,24(sp)
    80002b2a:	6b42                	ld	s6,16(sp)
    80002b2c:	6ba2                	ld	s7,8(sp)
    80002b2e:	6161                	addi	sp,sp,80
    80002b30:	8082                	ret

0000000080002b32 <settickets>:

void settickets(int n)
{
    80002b32:	7139                	addi	sp,sp,-64
    80002b34:	fc06                	sd	ra,56(sp)
    80002b36:	f822                	sd	s0,48(sp)
    80002b38:	f426                	sd	s1,40(sp)
    80002b3a:	f04a                	sd	s2,32(sp)
    80002b3c:	ec4e                	sd	s3,24(sp)
    80002b3e:	e852                	sd	s4,16(sp)
    80002b40:	e456                	sd	s5,8(sp)
    80002b42:	0080                	addi	s0,sp,64
    80002b44:	8aaa                	mv	s5,a0
  struct proc *p = proc;
  int i = 0;

  myproc()->tickets = n;
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	fb2080e7          	jalr	-78(ra) # 80001af8 <myproc>
    80002b4e:	2f552823          	sw	s5,752(a0)
  int i = 0;
    80002b52:	4901                	li	s2,0
  struct proc *p = proc;
    80002b54:	0002e497          	auipc	s1,0x2e
    80002b58:	6bc48493          	addi	s1,s1,1724 # 80031210 <proc>

  while (p < &proc[NPROC])
    80002b5c:	0003aa17          	auipc	s4,0x3a
    80002b60:	4b4a0a13          	addi	s4,s4,1204 # 8003d010 <tickslock>
  {
    if (p->pid == myproc()->pid)
    80002b64:	0304a983          	lw	s3,48(s1)
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	f90080e7          	jalr	-112(ra) # 80001af8 <myproc>
    80002b70:	591c                	lw	a5,48(a0)
    80002b72:	01378863          	beq	a5,s3,80002b82 <settickets+0x50>
    {
      proc[i].tickets = n;
      break;
    }
    i++;
    80002b76:	2905                	addiw	s2,s2,1
    p++;
    80002b78:	2f848493          	addi	s1,s1,760
  while (p < &proc[NPROC])
    80002b7c:	ff4494e3          	bne	s1,s4,80002b64 <settickets+0x32>
    80002b80:	a821                	j	80002b98 <settickets+0x66>
      proc[i].tickets = n;
    80002b82:	2f800793          	li	a5,760
    80002b86:	02f90933          	mul	s2,s2,a5
    80002b8a:	0002e797          	auipc	a5,0x2e
    80002b8e:	68678793          	addi	a5,a5,1670 # 80031210 <proc>
    80002b92:	993e                	add	s2,s2,a5
    80002b94:	2f592823          	sw	s5,752(s2)
  }
    80002b98:	70e2                	ld	ra,56(sp)
    80002b9a:	7442                	ld	s0,48(sp)
    80002b9c:	74a2                	ld	s1,40(sp)
    80002b9e:	7902                	ld	s2,32(sp)
    80002ba0:	69e2                	ld	s3,24(sp)
    80002ba2:	6a42                	ld	s4,16(sp)
    80002ba4:	6aa2                	ld	s5,8(sp)
    80002ba6:	6121                	addi	sp,sp,64
    80002ba8:	8082                	ret

0000000080002baa <swtch>:
    80002baa:	00153023          	sd	ra,0(a0)
    80002bae:	00253423          	sd	sp,8(a0)
    80002bb2:	e900                	sd	s0,16(a0)
    80002bb4:	ed04                	sd	s1,24(a0)
    80002bb6:	03253023          	sd	s2,32(a0)
    80002bba:	03353423          	sd	s3,40(a0)
    80002bbe:	03453823          	sd	s4,48(a0)
    80002bc2:	03553c23          	sd	s5,56(a0)
    80002bc6:	05653023          	sd	s6,64(a0)
    80002bca:	05753423          	sd	s7,72(a0)
    80002bce:	05853823          	sd	s8,80(a0)
    80002bd2:	05953c23          	sd	s9,88(a0)
    80002bd6:	07a53023          	sd	s10,96(a0)
    80002bda:	07b53423          	sd	s11,104(a0)
    80002bde:	0005b083          	ld	ra,0(a1)
    80002be2:	0085b103          	ld	sp,8(a1)
    80002be6:	6980                	ld	s0,16(a1)
    80002be8:	6d84                	ld	s1,24(a1)
    80002bea:	0205b903          	ld	s2,32(a1)
    80002bee:	0285b983          	ld	s3,40(a1)
    80002bf2:	0305ba03          	ld	s4,48(a1)
    80002bf6:	0385ba83          	ld	s5,56(a1)
    80002bfa:	0405bb03          	ld	s6,64(a1)
    80002bfe:	0485bb83          	ld	s7,72(a1)
    80002c02:	0505bc03          	ld	s8,80(a1)
    80002c06:	0585bc83          	ld	s9,88(a1)
    80002c0a:	0605bd03          	ld	s10,96(a1)
    80002c0e:	0685bd83          	ld	s11,104(a1)
    80002c12:	8082                	ret

0000000080002c14 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c14:	1141                	addi	sp,sp,-16
    80002c16:	e406                	sd	ra,8(sp)
    80002c18:	e022                	sd	s0,0(sp)
    80002c1a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c1c:	00005597          	auipc	a1,0x5
    80002c20:	6fc58593          	addi	a1,a1,1788 # 80008318 <states.0+0x30>
    80002c24:	0003a517          	auipc	a0,0x3a
    80002c28:	3ec50513          	addi	a0,a0,1004 # 8003d010 <tickslock>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	fa8080e7          	jalr	-88(ra) # 80000bd4 <initlock>
}
    80002c34:	60a2                	ld	ra,8(sp)
    80002c36:	6402                	ld	s0,0(sp)
    80002c38:	0141                	addi	sp,sp,16
    80002c3a:	8082                	ret

0000000080002c3c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c3c:	1141                	addi	sp,sp,-16
    80002c3e:	e422                	sd	s0,8(sp)
    80002c40:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c42:	00004797          	auipc	a5,0x4
    80002c46:	8ae78793          	addi	a5,a5,-1874 # 800064f0 <kernelvec>
    80002c4a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c4e:	6422                	ld	s0,8(sp)
    80002c50:	0141                	addi	sp,sp,16
    80002c52:	8082                	ret

0000000080002c54 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002c54:	1141                	addi	sp,sp,-16
    80002c56:	e406                	sd	ra,8(sp)
    80002c58:	e022                	sd	s0,0(sp)
    80002c5a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	e9c080e7          	jalr	-356(ra) # 80001af8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c68:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c6a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c6e:	00004617          	auipc	a2,0x4
    80002c72:	39260613          	addi	a2,a2,914 # 80007000 <_trampoline>
    80002c76:	00004697          	auipc	a3,0x4
    80002c7a:	38a68693          	addi	a3,a3,906 # 80007000 <_trampoline>
    80002c7e:	8e91                	sub	a3,a3,a2
    80002c80:	040007b7          	lui	a5,0x4000
    80002c84:	17fd                	addi	a5,a5,-1
    80002c86:	07b2                	slli	a5,a5,0xc
    80002c88:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c8a:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c8e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c90:	180026f3          	csrr	a3,satp
    80002c94:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c96:	6d38                	ld	a4,88(a0)
    80002c98:	6134                	ld	a3,64(a0)
    80002c9a:	6585                	lui	a1,0x1
    80002c9c:	96ae                	add	a3,a3,a1
    80002c9e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ca0:	6d38                	ld	a4,88(a0)
    80002ca2:	00000697          	auipc	a3,0x0
    80002ca6:	13e68693          	addi	a3,a3,318 # 80002de0 <usertrap>
    80002caa:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002cac:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cae:	8692                	mv	a3,tp
    80002cb0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cb6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cba:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cbe:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cc2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cc4:	6f18                	ld	a4,24(a4)
    80002cc6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cca:	6928                	ld	a0,80(a0)
    80002ccc:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002cce:	00004717          	auipc	a4,0x4
    80002cd2:	3ce70713          	addi	a4,a4,974 # 8000709c <userret>
    80002cd6:	8f11                	sub	a4,a4,a2
    80002cd8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002cda:	577d                	li	a4,-1
    80002cdc:	177e                	slli	a4,a4,0x3f
    80002cde:	8d59                	or	a0,a0,a4
    80002ce0:	9782                	jalr	a5
}
    80002ce2:	60a2                	ld	ra,8(sp)
    80002ce4:	6402                	ld	s0,0(sp)
    80002ce6:	0141                	addi	sp,sp,16
    80002ce8:	8082                	ret

0000000080002cea <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	e04a                	sd	s2,0(sp)
    80002cf4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cf6:	0003a917          	auipc	s2,0x3a
    80002cfa:	31a90913          	addi	s2,s2,794 # 8003d010 <tickslock>
    80002cfe:	854a                	mv	a0,s2
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	f64080e7          	jalr	-156(ra) # 80000c64 <acquire>
  ticks++;
    80002d08:	00006497          	auipc	s1,0x6
    80002d0c:	e7048493          	addi	s1,s1,-400 # 80008b78 <ticks>
    80002d10:	409c                	lw	a5,0(s1)
    80002d12:	2785                	addiw	a5,a5,1
    80002d14:	c09c                	sw	a5,0(s1)
  update_time();
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	3b6080e7          	jalr	950(ra) # 800020cc <update_time>
  wakeup(&ticks);
    80002d1e:	8526                	mv	a0,s1
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	908080e7          	jalr	-1784(ra) # 80002628 <wakeup>
  release(&tickslock);
    80002d28:	854a                	mv	a0,s2
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	fee080e7          	jalr	-18(ra) # 80000d18 <release>
}
    80002d32:	60e2                	ld	ra,24(sp)
    80002d34:	6442                	ld	s0,16(sp)
    80002d36:	64a2                	ld	s1,8(sp)
    80002d38:	6902                	ld	s2,0(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d48:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002d4c:	00074d63          	bltz	a4,80002d66 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002d50:	57fd                	li	a5,-1
    80002d52:	17fe                	slli	a5,a5,0x3f
    80002d54:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002d56:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002d58:	06f70363          	beq	a4,a5,80002dbe <devintr+0x80>
  }
}
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	64a2                	ld	s1,8(sp)
    80002d62:	6105                	addi	sp,sp,32
    80002d64:	8082                	ret
      (scause & 0xff) == 9)
    80002d66:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002d6a:	46a5                	li	a3,9
    80002d6c:	fed792e3          	bne	a5,a3,80002d50 <devintr+0x12>
    int irq = plic_claim();
    80002d70:	00004097          	auipc	ra,0x4
    80002d74:	888080e7          	jalr	-1912(ra) # 800065f8 <plic_claim>
    80002d78:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002d7a:	47a9                	li	a5,10
    80002d7c:	02f50763          	beq	a0,a5,80002daa <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002d80:	4785                	li	a5,1
    80002d82:	02f50963          	beq	a0,a5,80002db4 <devintr+0x76>
    return 1;
    80002d86:	4505                	li	a0,1
    else if (irq)
    80002d88:	d8f1                	beqz	s1,80002d5c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d8a:	85a6                	mv	a1,s1
    80002d8c:	00005517          	auipc	a0,0x5
    80002d90:	59450513          	addi	a0,a0,1428 # 80008320 <states.0+0x38>
    80002d94:	ffffd097          	auipc	ra,0xffffd
    80002d98:	7f4080e7          	jalr	2036(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d9c:	8526                	mv	a0,s1
    80002d9e:	00004097          	auipc	ra,0x4
    80002da2:	87e080e7          	jalr	-1922(ra) # 8000661c <plic_complete>
    return 1;
    80002da6:	4505                	li	a0,1
    80002da8:	bf55                	j	80002d5c <devintr+0x1e>
      uartintr();
    80002daa:	ffffe097          	auipc	ra,0xffffe
    80002dae:	bf0080e7          	jalr	-1040(ra) # 8000099a <uartintr>
    80002db2:	b7ed                	j	80002d9c <devintr+0x5e>
      virtio_disk_intr();
    80002db4:	00004097          	auipc	ra,0x4
    80002db8:	d34080e7          	jalr	-716(ra) # 80006ae8 <virtio_disk_intr>
    80002dbc:	b7c5                	j	80002d9c <devintr+0x5e>
    if (cpuid() == 0)
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	d0e080e7          	jalr	-754(ra) # 80001acc <cpuid>
    80002dc6:	c901                	beqz	a0,80002dd6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dc8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dcc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dce:	14479073          	csrw	sip,a5
    return 2;
    80002dd2:	4509                	li	a0,2
    80002dd4:	b761                	j	80002d5c <devintr+0x1e>
      clockintr();
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	f14080e7          	jalr	-236(ra) # 80002cea <clockintr>
    80002dde:	b7ed                	j	80002dc8 <devintr+0x8a>

0000000080002de0 <usertrap>:
{
    80002de0:	7179                	addi	sp,sp,-48
    80002de2:	f406                	sd	ra,40(sp)
    80002de4:	f022                	sd	s0,32(sp)
    80002de6:	ec26                	sd	s1,24(sp)
    80002de8:	e84a                	sd	s2,16(sp)
    80002dea:	e44e                	sd	s3,8(sp)
    80002dec:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dee:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002df2:	1007f793          	andi	a5,a5,256
    80002df6:	e3ad                	bnez	a5,80002e58 <usertrap+0x78>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002df8:	00003797          	auipc	a5,0x3
    80002dfc:	6f878793          	addi	a5,a5,1784 # 800064f0 <kernelvec>
    80002e00:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	cf4080e7          	jalr	-780(ra) # 80001af8 <myproc>
    80002e0c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e0e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e10:	14102773          	csrr	a4,sepc
    80002e14:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e16:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002e1a:	47a1                	li	a5,8
    80002e1c:	04f70663          	beq	a4,a5,80002e68 <usertrap+0x88>
  else if ((which_dev = devintr()) != 0)
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	f1e080e7          	jalr	-226(ra) # 80002d3e <devintr>
    80002e28:	c179                	beqz	a0,80002eee <usertrap+0x10e>
    if (which_dev == 2)
    80002e2a:	4789                	li	a5,2
    80002e2c:	06f51163          	bne	a0,a5,80002e8e <usertrap+0xae>
      if (p->max_alarm_ticks >= 1 && p->alarm_ticks > -1)
    80002e30:	16c4a783          	lw	a5,364(s1)
    80002e34:	00f05d63          	blez	a5,80002e4e <usertrap+0x6e>
    80002e38:	1704a703          	lw	a4,368(s1)
    80002e3c:	00074563          	bltz	a4,80002e46 <usertrap+0x66>
        p->alarm_ticks++;
    80002e40:	2705                	addiw	a4,a4,1
    80002e42:	16e4a823          	sw	a4,368(s1)
      if (p->max_alarm_ticks >= 1 && p->alarm_ticks == p->max_alarm_ticks)
    80002e46:	1704a703          	lw	a4,368(s1)
    80002e4a:	06f70d63          	beq	a4,a5,80002ec4 <usertrap+0xe4>
      yield();
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	53c080e7          	jalr	1340(ra) # 8000238a <yield>
    80002e56:	a825                	j	80002e8e <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002e58:	00005517          	auipc	a0,0x5
    80002e5c:	4e850513          	addi	a0,a0,1256 # 80008340 <states.0+0x58>
    80002e60:	ffffd097          	auipc	ra,0xffffd
    80002e64:	6de080e7          	jalr	1758(ra) # 8000053e <panic>
    if (killed(p))
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	a10080e7          	jalr	-1520(ra) # 80002878 <killed>
    80002e70:	e521                	bnez	a0,80002eb8 <usertrap+0xd8>
    p->trapframe->epc += 4;
    80002e72:	6cb8                	ld	a4,88(s1)
    80002e74:	6f1c                	ld	a5,24(a4)
    80002e76:	0791                	addi	a5,a5,4
    80002e78:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e7a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e7e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e82:	10079073          	csrw	sstatus,a5
    syscall();
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	358080e7          	jalr	856(ra) # 800031de <syscall>
  if(p->killed >= 1)
    80002e8e:	549c                	lw	a5,40(s1)
    80002e90:	10f04b63          	bgtz	a5,80002fa6 <usertrap+0x1c6>
  if (killed(p))
    80002e94:	8526                	mv	a0,s1
    80002e96:	00000097          	auipc	ra,0x0
    80002e9a:	9e2080e7          	jalr	-1566(ra) # 80002878 <killed>
    80002e9e:	10051a63          	bnez	a0,80002fb2 <usertrap+0x1d2>
  usertrapret();
    80002ea2:	00000097          	auipc	ra,0x0
    80002ea6:	db2080e7          	jalr	-590(ra) # 80002c54 <usertrapret>
}
    80002eaa:	70a2                	ld	ra,40(sp)
    80002eac:	7402                	ld	s0,32(sp)
    80002eae:	64e2                	ld	s1,24(sp)
    80002eb0:	6942                	ld	s2,16(sp)
    80002eb2:	69a2                	ld	s3,8(sp)
    80002eb4:	6145                	addi	sp,sp,48
    80002eb6:	8082                	ret
      exit(-1);
    80002eb8:	557d                	li	a0,-1
    80002eba:	00000097          	auipc	ra,0x0
    80002ebe:	83e080e7          	jalr	-1986(ra) # 800026f8 <exit>
    80002ec2:	bf45                	j	80002e72 <usertrap+0x92>
        p->alarm_ticks = -1;
    80002ec4:	57fd                	li	a5,-1
    80002ec6:	16f4a823          	sw	a5,368(s1)
        memmove(&p->alarm_trap, p->trapframe, sizeof(p->alarm_trap));
    80002eca:	12000613          	li	a2,288
    80002ece:	6cac                	ld	a1,88(s1)
    80002ed0:	18048513          	addi	a0,s1,384
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	ee8080e7          	jalr	-280(ra) # 80000dbc <memmove>
        p->trapframe->epc = p->handler;
    80002edc:	6cbc                	ld	a5,88(s1)
    80002ede:	1784b703          	ld	a4,376(s1)
    80002ee2:	ef98                	sd	a4,24(a5)
        usertrapret();
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	d70080e7          	jalr	-656(ra) # 80002c54 <usertrapret>
    80002eec:	b78d                	j	80002e4e <usertrap+0x6e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eee:	14202773          	csrr	a4,scause
    else if(r_scause()==15){
    80002ef2:	47bd                	li	a5,15
    80002ef4:	02f70f63          	beq	a4,a5,80002f32 <usertrap+0x152>
    80002ef8:	142025f3          	csrr	a1,scause
    printf("error in usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002efc:	5890                	lw	a2,48(s1)
    80002efe:	00005517          	auipc	a0,0x5
    80002f02:	46250513          	addi	a0,a0,1122 # 80008360 <states.0+0x78>
    80002f06:	ffffd097          	auipc	ra,0xffffd
    80002f0a:	682080e7          	jalr	1666(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f0e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f12:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f16:	00005517          	auipc	a0,0x5
    80002f1a:	48250513          	addi	a0,a0,1154 # 80008398 <states.0+0xb0>
    80002f1e:	ffffd097          	auipc	ra,0xffffd
    80002f22:	66a080e7          	jalr	1642(ra) # 80000588 <printf>
    setkilled(p);
    80002f26:	8526                	mv	a0,s1
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	924080e7          	jalr	-1756(ra) # 8000284c <setkilled>
    80002f30:	bfb9                	j	80002e8e <usertrap+0xae>
    80002f32:	143025f3          	csrr	a1,stval
    pte_t* pte = walk(p->pagetable, PGROUNDDOWN(r_stval()),0);
    80002f36:	4601                	li	a2,0
    80002f38:	77fd                	lui	a5,0xfffff
    80002f3a:	8dfd                	and	a1,a1,a5
    80002f3c:	68a8                	ld	a0,80(s1)
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	106080e7          	jalr	262(ra) # 80001044 <walk>
    if((*pte & PTE_COW)==0)
    80002f46:	00053903          	ld	s2,0(a0)
    80002f4a:	10097793          	andi	a5,s2,256
    80002f4e:	d7cd                	beqz	a5,80002ef8 <usertrap+0x118>
    char* mem = kalloc();
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	be4080e7          	jalr	-1052(ra) # 80000b34 <kalloc>
    80002f58:	89aa                	mv	s3,a0
    uint64 pa = PTE2PA(*pte);
    80002f5a:	00a95913          	srli	s2,s2,0xa
    80002f5e:	0932                	slli	s2,s2,0xc
    memmove(mem, (char*)pa, PGSIZE);
    80002f60:	6605                	lui	a2,0x1
    80002f62:	85ca                	mv	a1,s2
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	e58080e7          	jalr	-424(ra) # 80000dbc <memmove>
    80002f6c:	143025f3          	csrr	a1,stval
    if(mappages(p->pagetable,PGROUNDDOWN(r_stval()) , PGSIZE, (uint64)mem, PTE_R|PTE_W|PTE_X|PTE_U) != 0){
    80002f70:	4779                	li	a4,30
    80002f72:	86ce                	mv	a3,s3
    80002f74:	6605                	lui	a2,0x1
    80002f76:	77fd                	lui	a5,0xfffff
    80002f78:	8dfd                	and	a1,a1,a5
    80002f7a:	68a8                	ld	a0,80(s1)
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	1b0080e7          	jalr	432(ra) # 8000112c <mappages>
    80002f84:	e519                	bnez	a0,80002f92 <usertrap+0x1b2>
    kfree((void*)pa);
    80002f86:	854a                	mv	a0,s2
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	a62080e7          	jalr	-1438(ra) # 800009ea <kfree>
    80002f90:	bdfd                	j	80002e8e <usertrap+0xae>
      printf("ERROR\n");
    80002f92:	00005517          	auipc	a0,0x5
    80002f96:	24650513          	addi	a0,a0,582 # 800081d8 <digits+0x198>
    80002f9a:	ffffd097          	auipc	ra,0xffffd
    80002f9e:	5ee080e7          	jalr	1518(ra) # 80000588 <printf>
      p->killed=1;
    80002fa2:	4785                	li	a5,1
    80002fa4:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002fa6:	557d                	li	a0,-1
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	750080e7          	jalr	1872(ra) # 800026f8 <exit>
    80002fb0:	b5d5                	j	80002e94 <usertrap+0xb4>
    exit(-1);
    80002fb2:	557d                	li	a0,-1
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	744080e7          	jalr	1860(ra) # 800026f8 <exit>
    80002fbc:	b5dd                	j	80002ea2 <usertrap+0xc2>

0000000080002fbe <kerneltrap>:
{
    80002fbe:	7179                	addi	sp,sp,-48
    80002fc0:	f406                	sd	ra,40(sp)
    80002fc2:	f022                	sd	s0,32(sp)
    80002fc4:	ec26                	sd	s1,24(sp)
    80002fc6:	e84a                	sd	s2,16(sp)
    80002fc8:	e44e                	sd	s3,8(sp)
    80002fca:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fcc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fd4:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002fd8:	1004f793          	andi	a5,s1,256
    80002fdc:	c78d                	beqz	a5,80003006 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fde:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fe2:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002fe4:	eb8d                	bnez	a5,80003016 <kerneltrap+0x58>
  if ((which_dev = devintr()) == 0)
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	d58080e7          	jalr	-680(ra) # 80002d3e <devintr>
    80002fee:	cd05                	beqz	a0,80003026 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ff0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ff4:	10049073          	csrw	sstatus,s1
}
    80002ff8:	70a2                	ld	ra,40(sp)
    80002ffa:	7402                	ld	s0,32(sp)
    80002ffc:	64e2                	ld	s1,24(sp)
    80002ffe:	6942                	ld	s2,16(sp)
    80003000:	69a2                	ld	s3,8(sp)
    80003002:	6145                	addi	sp,sp,48
    80003004:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003006:	00005517          	auipc	a0,0x5
    8000300a:	3b250513          	addi	a0,a0,946 # 800083b8 <states.0+0xd0>
    8000300e:	ffffd097          	auipc	ra,0xffffd
    80003012:	530080e7          	jalr	1328(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003016:	00005517          	auipc	a0,0x5
    8000301a:	3ca50513          	addi	a0,a0,970 # 800083e0 <states.0+0xf8>
    8000301e:	ffffd097          	auipc	ra,0xffffd
    80003022:	520080e7          	jalr	1312(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003026:	85ce                	mv	a1,s3
    80003028:	00005517          	auipc	a0,0x5
    8000302c:	3d850513          	addi	a0,a0,984 # 80008400 <states.0+0x118>
    80003030:	ffffd097          	auipc	ra,0xffffd
    80003034:	558080e7          	jalr	1368(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003038:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000303c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003040:	00005517          	auipc	a0,0x5
    80003044:	3d050513          	addi	a0,a0,976 # 80008410 <states.0+0x128>
    80003048:	ffffd097          	auipc	ra,0xffffd
    8000304c:	540080e7          	jalr	1344(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003050:	00005517          	auipc	a0,0x5
    80003054:	3d850513          	addi	a0,a0,984 # 80008428 <states.0+0x140>
    80003058:	ffffd097          	auipc	ra,0xffffd
    8000305c:	4e6080e7          	jalr	1254(ra) # 8000053e <panic>

0000000080003060 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	e426                	sd	s1,8(sp)
    80003068:	1000                	addi	s0,sp,32
    8000306a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	a8c080e7          	jalr	-1396(ra) # 80001af8 <myproc>
  switch (n)
    80003074:	4795                	li	a5,5
    80003076:	0497e163          	bltu	a5,s1,800030b8 <argraw+0x58>
    8000307a:	048a                	slli	s1,s1,0x2
    8000307c:	00005717          	auipc	a4,0x5
    80003080:	4ec70713          	addi	a4,a4,1260 # 80008568 <states.0+0x280>
    80003084:	94ba                	add	s1,s1,a4
    80003086:	409c                	lw	a5,0(s1)
    80003088:	97ba                	add	a5,a5,a4
    8000308a:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    8000308c:	6d3c                	ld	a5,88(a0)
    8000308e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret
    return p->trapframe->a1;
    8000309a:	6d3c                	ld	a5,88(a0)
    8000309c:	7fa8                	ld	a0,120(a5)
    8000309e:	bfcd                	j	80003090 <argraw+0x30>
    return p->trapframe->a2;
    800030a0:	6d3c                	ld	a5,88(a0)
    800030a2:	63c8                	ld	a0,128(a5)
    800030a4:	b7f5                	j	80003090 <argraw+0x30>
    return p->trapframe->a3;
    800030a6:	6d3c                	ld	a5,88(a0)
    800030a8:	67c8                	ld	a0,136(a5)
    800030aa:	b7dd                	j	80003090 <argraw+0x30>
    return p->trapframe->a4;
    800030ac:	6d3c                	ld	a5,88(a0)
    800030ae:	6bc8                	ld	a0,144(a5)
    800030b0:	b7c5                	j	80003090 <argraw+0x30>
    return p->trapframe->a5;
    800030b2:	6d3c                	ld	a5,88(a0)
    800030b4:	6fc8                	ld	a0,152(a5)
    800030b6:	bfe9                	j	80003090 <argraw+0x30>
  panic("argraw");
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	38050513          	addi	a0,a0,896 # 80008438 <states.0+0x150>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	47e080e7          	jalr	1150(ra) # 8000053e <panic>

00000000800030c8 <fetchaddr>:
{
    800030c8:	1101                	addi	sp,sp,-32
    800030ca:	ec06                	sd	ra,24(sp)
    800030cc:	e822                	sd	s0,16(sp)
    800030ce:	e426                	sd	s1,8(sp)
    800030d0:	e04a                	sd	s2,0(sp)
    800030d2:	1000                	addi	s0,sp,32
    800030d4:	84aa                	mv	s1,a0
    800030d6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	a20080e7          	jalr	-1504(ra) # 80001af8 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800030e0:	653c                	ld	a5,72(a0)
    800030e2:	02f4f863          	bgeu	s1,a5,80003112 <fetchaddr+0x4a>
    800030e6:	00848713          	addi	a4,s1,8
    800030ea:	02e7e663          	bltu	a5,a4,80003116 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030ee:	46a1                	li	a3,8
    800030f0:	8626                	mv	a2,s1
    800030f2:	85ca                	mv	a1,s2
    800030f4:	6928                	ld	a0,80(a0)
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	704080e7          	jalr	1796(ra) # 800017fa <copyin>
    800030fe:	00a03533          	snez	a0,a0
    80003102:	40a00533          	neg	a0,a0
}
    80003106:	60e2                	ld	ra,24(sp)
    80003108:	6442                	ld	s0,16(sp)
    8000310a:	64a2                	ld	s1,8(sp)
    8000310c:	6902                	ld	s2,0(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret
    return -1;
    80003112:	557d                	li	a0,-1
    80003114:	bfcd                	j	80003106 <fetchaddr+0x3e>
    80003116:	557d                	li	a0,-1
    80003118:	b7fd                	j	80003106 <fetchaddr+0x3e>

000000008000311a <fetchstr>:
{
    8000311a:	7179                	addi	sp,sp,-48
    8000311c:	f406                	sd	ra,40(sp)
    8000311e:	f022                	sd	s0,32(sp)
    80003120:	ec26                	sd	s1,24(sp)
    80003122:	e84a                	sd	s2,16(sp)
    80003124:	e44e                	sd	s3,8(sp)
    80003126:	1800                	addi	s0,sp,48
    80003128:	892a                	mv	s2,a0
    8000312a:	84ae                	mv	s1,a1
    8000312c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000312e:	fffff097          	auipc	ra,0xfffff
    80003132:	9ca080e7          	jalr	-1590(ra) # 80001af8 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003136:	86ce                	mv	a3,s3
    80003138:	864a                	mv	a2,s2
    8000313a:	85a6                	mv	a1,s1
    8000313c:	6928                	ld	a0,80(a0)
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	74a080e7          	jalr	1866(ra) # 80001888 <copyinstr>
    80003146:	00054e63          	bltz	a0,80003162 <fetchstr+0x48>
  return strlen(buf);
    8000314a:	8526                	mv	a0,s1
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	d90080e7          	jalr	-624(ra) # 80000edc <strlen>
}
    80003154:	70a2                	ld	ra,40(sp)
    80003156:	7402                	ld	s0,32(sp)
    80003158:	64e2                	ld	s1,24(sp)
    8000315a:	6942                	ld	s2,16(sp)
    8000315c:	69a2                	ld	s3,8(sp)
    8000315e:	6145                	addi	sp,sp,48
    80003160:	8082                	ret
    return -1;
    80003162:	557d                	li	a0,-1
    80003164:	bfc5                	j	80003154 <fetchstr+0x3a>

0000000080003166 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003166:	1101                	addi	sp,sp,-32
    80003168:	ec06                	sd	ra,24(sp)
    8000316a:	e822                	sd	s0,16(sp)
    8000316c:	e426                	sd	s1,8(sp)
    8000316e:	1000                	addi	s0,sp,32
    80003170:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003172:	00000097          	auipc	ra,0x0
    80003176:	eee080e7          	jalr	-274(ra) # 80003060 <argraw>
    8000317a:	c088                	sw	a0,0(s1)
}
    8000317c:	60e2                	ld	ra,24(sp)
    8000317e:	6442                	ld	s0,16(sp)
    80003180:	64a2                	ld	s1,8(sp)
    80003182:	6105                	addi	sp,sp,32
    80003184:	8082                	ret

0000000080003186 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003186:	1101                	addi	sp,sp,-32
    80003188:	ec06                	sd	ra,24(sp)
    8000318a:	e822                	sd	s0,16(sp)
    8000318c:	e426                	sd	s1,8(sp)
    8000318e:	1000                	addi	s0,sp,32
    80003190:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003192:	00000097          	auipc	ra,0x0
    80003196:	ece080e7          	jalr	-306(ra) # 80003060 <argraw>
    8000319a:	e088                	sd	a0,0(s1)
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6105                	addi	sp,sp,32
    800031a4:	8082                	ret

00000000800031a6 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800031a6:	7179                	addi	sp,sp,-48
    800031a8:	f406                	sd	ra,40(sp)
    800031aa:	f022                	sd	s0,32(sp)
    800031ac:	ec26                	sd	s1,24(sp)
    800031ae:	e84a                	sd	s2,16(sp)
    800031b0:	1800                	addi	s0,sp,48
    800031b2:	84ae                	mv	s1,a1
    800031b4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031b6:	fd840593          	addi	a1,s0,-40
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	fcc080e7          	jalr	-52(ra) # 80003186 <argaddr>
  return fetchstr(addr, buf, max);
    800031c2:	864a                	mv	a2,s2
    800031c4:	85a6                	mv	a1,s1
    800031c6:	fd843503          	ld	a0,-40(s0)
    800031ca:	00000097          	auipc	ra,0x0
    800031ce:	f50080e7          	jalr	-176(ra) # 8000311a <fetchstr>
}
    800031d2:	70a2                	ld	ra,40(sp)
    800031d4:	7402                	ld	s0,32(sp)
    800031d6:	64e2                	ld	s1,24(sp)
    800031d8:	6942                	ld	s2,16(sp)
    800031da:	6145                	addi	sp,sp,48
    800031dc:	8082                	ret

00000000800031de <syscall>:
};
/* END */


void syscall(void)
{
    800031de:	7179                	addi	sp,sp,-48
    800031e0:	f406                	sd	ra,40(sp)
    800031e2:	f022                	sd	s0,32(sp)
    800031e4:	ec26                	sd	s1,24(sp)
    800031e6:	e84a                	sd	s2,16(sp)
    800031e8:	e44e                	sd	s3,8(sp)
    800031ea:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	90c080e7          	jalr	-1780(ra) # 80001af8 <myproc>
    800031f4:	84aa                	mv	s1,a0
  int num;

  num = p->trapframe->a7;
    800031f6:	05853903          	ld	s2,88(a0)
    800031fa:	0a893783          	ld	a5,168(s2)
    800031fe:	0007899b          	sext.w	s3,a5

  // START

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003202:	37fd                	addiw	a5,a5,-1
    80003204:	4769                	li	a4,26
    80003206:	16f76e63          	bltu	a4,a5,80003382 <syscall+0x1a4>
    8000320a:	00399713          	slli	a4,s3,0x3
    8000320e:	00005797          	auipc	a5,0x5
    80003212:	37278793          	addi	a5,a5,882 # 80008580 <syscalls>
    80003216:	97ba                	add	a5,a5,a4
    80003218:	639c                	ld	a5,0(a5)
    8000321a:	16078463          	beqz	a5,80003382 <syscall+0x1a4>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    p->trapframe->a0 = syscalls[num]();
    8000321e:	9782                	jalr	a5
    80003220:	06a93823          	sd	a0,112(s2)

    if ((1 << num) & p->trace_mask)
    80003224:	1684a783          	lw	a5,360(s1)
    80003228:	4137d7bb          	sraw	a5,a5,s3
    8000322c:	8b85                	andi	a5,a5,1
    8000322e:	16078963          	beqz	a5,800033a0 <syscall+0x1c2>
    {
      printf("%d: syscall %s (", p->pid, syscall_name[num]);
    80003232:	00005917          	auipc	s2,0x5
    80003236:	7b690913          	addi	s2,s2,1974 # 800089e8 <syscall_name>
    8000323a:	00399793          	slli	a5,s3,0x3
    8000323e:	97ca                	add	a5,a5,s2
    80003240:	6390                	ld	a2,0(a5)
    80003242:	588c                	lw	a1,48(s1)
    80003244:	00005517          	auipc	a0,0x5
    80003248:	1fc50513          	addi	a0,a0,508 # 80008440 <states.0+0x158>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	33c080e7          	jalr	828(ra) # 80000588 <printf>
      if (syscall_argc[num] > 0)
    80003254:	00299793          	slli	a5,s3,0x2
    80003258:	993e                	add	s2,s2,a5
    8000325a:	0e092783          	lw	a5,224(s2)
    8000325e:	0af04063          	bgtz	a5,800032fe <syscall+0x120>
        printf("%d", p->trapframe->a0);
      if (syscall_argc[num] > 1)
    80003262:	00299713          	slli	a4,s3,0x2
    80003266:	00005797          	auipc	a5,0x5
    8000326a:	78278793          	addi	a5,a5,1922 # 800089e8 <syscall_name>
    8000326e:	97ba                	add	a5,a5,a4
    80003270:	0e07a703          	lw	a4,224(a5)
    80003274:	4785                	li	a5,1
    80003276:	08e7cf63          	blt	a5,a4,80003314 <syscall+0x136>
        printf(" %d", p->trapframe->a1);
      if (syscall_argc[num] > 2)
    8000327a:	00299713          	slli	a4,s3,0x2
    8000327e:	00005797          	auipc	a5,0x5
    80003282:	76a78793          	addi	a5,a5,1898 # 800089e8 <syscall_name>
    80003286:	97ba                	add	a5,a5,a4
    80003288:	0e07a703          	lw	a4,224(a5)
    8000328c:	4789                	li	a5,2
    8000328e:	08e7ce63          	blt	a5,a4,8000332a <syscall+0x14c>
        printf(" %d", p->trapframe->a2);
      if (syscall_argc[num] > 3)
    80003292:	00299713          	slli	a4,s3,0x2
    80003296:	00005797          	auipc	a5,0x5
    8000329a:	75278793          	addi	a5,a5,1874 # 800089e8 <syscall_name>
    8000329e:	97ba                	add	a5,a5,a4
    800032a0:	0e07a703          	lw	a4,224(a5)
    800032a4:	478d                	li	a5,3
    800032a6:	08e7cd63          	blt	a5,a4,80003340 <syscall+0x162>
        printf(" %d", p->trapframe->a3);
      if (syscall_argc[num] > 4)
    800032aa:	00299713          	slli	a4,s3,0x2
    800032ae:	00005797          	auipc	a5,0x5
    800032b2:	73a78793          	addi	a5,a5,1850 # 800089e8 <syscall_name>
    800032b6:	97ba                	add	a5,a5,a4
    800032b8:	0e07a703          	lw	a4,224(a5)
    800032bc:	4791                	li	a5,4
    800032be:	08e7cc63          	blt	a5,a4,80003356 <syscall+0x178>
        printf(" %d", p->trapframe->a4);
      if (syscall_argc[num] > 5)
    800032c2:	098a                	slli	s3,s3,0x2
    800032c4:	00005797          	auipc	a5,0x5
    800032c8:	72478793          	addi	a5,a5,1828 # 800089e8 <syscall_name>
    800032cc:	99be                	add	s3,s3,a5
    800032ce:	0e09a703          	lw	a4,224(s3)
    800032d2:	4795                	li	a5,5
    800032d4:	08e7cc63          	blt	a5,a4,8000336c <syscall+0x18e>
        printf(" %d", p->trapframe->a5);
      printf(") ");
    800032d8:	00005517          	auipc	a0,0x5
    800032dc:	19050513          	addi	a0,a0,400 # 80008468 <states.0+0x180>
    800032e0:	ffffd097          	auipc	ra,0xffffd
    800032e4:	2a8080e7          	jalr	680(ra) # 80000588 <printf>
      printf("-> %d\n", p->trapframe->a0);
    800032e8:	6cbc                	ld	a5,88(s1)
    800032ea:	7bac                	ld	a1,112(a5)
    800032ec:	00005517          	auipc	a0,0x5
    800032f0:	18450513          	addi	a0,a0,388 # 80008470 <states.0+0x188>
    800032f4:	ffffd097          	auipc	ra,0xffffd
    800032f8:	294080e7          	jalr	660(ra) # 80000588 <printf>
    800032fc:	a055                	j	800033a0 <syscall+0x1c2>
        printf("%d", p->trapframe->a0);
    800032fe:	6cbc                	ld	a5,88(s1)
    80003300:	7bac                	ld	a1,112(a5)
    80003302:	00005517          	auipc	a0,0x5
    80003306:	15650513          	addi	a0,a0,342 # 80008458 <states.0+0x170>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	27e080e7          	jalr	638(ra) # 80000588 <printf>
    80003312:	bf81                	j	80003262 <syscall+0x84>
        printf(" %d", p->trapframe->a1);
    80003314:	6cbc                	ld	a5,88(s1)
    80003316:	7fac                	ld	a1,120(a5)
    80003318:	00005517          	auipc	a0,0x5
    8000331c:	14850513          	addi	a0,a0,328 # 80008460 <states.0+0x178>
    80003320:	ffffd097          	auipc	ra,0xffffd
    80003324:	268080e7          	jalr	616(ra) # 80000588 <printf>
    80003328:	bf89                	j	8000327a <syscall+0x9c>
        printf(" %d", p->trapframe->a2);
    8000332a:	6cbc                	ld	a5,88(s1)
    8000332c:	63cc                	ld	a1,128(a5)
    8000332e:	00005517          	auipc	a0,0x5
    80003332:	13250513          	addi	a0,a0,306 # 80008460 <states.0+0x178>
    80003336:	ffffd097          	auipc	ra,0xffffd
    8000333a:	252080e7          	jalr	594(ra) # 80000588 <printf>
    8000333e:	bf91                	j	80003292 <syscall+0xb4>
        printf(" %d", p->trapframe->a3);
    80003340:	6cbc                	ld	a5,88(s1)
    80003342:	67cc                	ld	a1,136(a5)
    80003344:	00005517          	auipc	a0,0x5
    80003348:	11c50513          	addi	a0,a0,284 # 80008460 <states.0+0x178>
    8000334c:	ffffd097          	auipc	ra,0xffffd
    80003350:	23c080e7          	jalr	572(ra) # 80000588 <printf>
    80003354:	bf99                	j	800032aa <syscall+0xcc>
        printf(" %d", p->trapframe->a4);
    80003356:	6cbc                	ld	a5,88(s1)
    80003358:	6bcc                	ld	a1,144(a5)
    8000335a:	00005517          	auipc	a0,0x5
    8000335e:	10650513          	addi	a0,a0,262 # 80008460 <states.0+0x178>
    80003362:	ffffd097          	auipc	ra,0xffffd
    80003366:	226080e7          	jalr	550(ra) # 80000588 <printf>
    8000336a:	bfa1                	j	800032c2 <syscall+0xe4>
        printf(" %d", p->trapframe->a5);
    8000336c:	6cbc                	ld	a5,88(s1)
    8000336e:	6fcc                	ld	a1,152(a5)
    80003370:	00005517          	auipc	a0,0x5
    80003374:	0f050513          	addi	a0,a0,240 # 80008460 <states.0+0x178>
    80003378:	ffffd097          	auipc	ra,0xffffd
    8000337c:	210080e7          	jalr	528(ra) # 80000588 <printf>
    80003380:	bfa1                	j	800032d8 <syscall+0xfa>
  }
  // END

  else
  {
    printf("%d %s: unknown sys call %d\n",
    80003382:	86ce                	mv	a3,s3
    80003384:	15848613          	addi	a2,s1,344
    80003388:	588c                	lw	a1,48(s1)
    8000338a:	00005517          	auipc	a0,0x5
    8000338e:	0ee50513          	addi	a0,a0,238 # 80008478 <states.0+0x190>
    80003392:	ffffd097          	auipc	ra,0xffffd
    80003396:	1f6080e7          	jalr	502(ra) # 80000588 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000339a:	6cbc                	ld	a5,88(s1)
    8000339c:	577d                	li	a4,-1
    8000339e:	fbb8                	sd	a4,112(a5)
  }
}
    800033a0:	70a2                	ld	ra,40(sp)
    800033a2:	7402                	ld	s0,32(sp)
    800033a4:	64e2                	ld	s1,24(sp)
    800033a6:	6942                	ld	s2,16(sp)
    800033a8:	69a2                	ld	s3,8(sp)
    800033aa:	6145                	addi	sp,sp,48
    800033ac:	8082                	ret

00000000800033ae <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800033ae:	1101                	addi	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800033b6:	fec40593          	addi	a1,s0,-20
    800033ba:	4501                	li	a0,0
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	daa080e7          	jalr	-598(ra) # 80003166 <argint>
  exit(n);
    800033c4:	fec42503          	lw	a0,-20(s0)
    800033c8:	fffff097          	auipc	ra,0xfffff
    800033cc:	330080e7          	jalr	816(ra) # 800026f8 <exit>
  return 0; // not reached
}
    800033d0:	4501                	li	a0,0
    800033d2:	60e2                	ld	ra,24(sp)
    800033d4:	6442                	ld	s0,16(sp)
    800033d6:	6105                	addi	sp,sp,32
    800033d8:	8082                	ret

00000000800033da <sys_getpid>:

uint64
sys_getpid(void)
{
    800033da:	1141                	addi	sp,sp,-16
    800033dc:	e406                	sd	ra,8(sp)
    800033de:	e022                	sd	s0,0(sp)
    800033e0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	716080e7          	jalr	1814(ra) # 80001af8 <myproc>
}
    800033ea:	5908                	lw	a0,48(a0)
    800033ec:	60a2                	ld	ra,8(sp)
    800033ee:	6402                	ld	s0,0(sp)
    800033f0:	0141                	addi	sp,sp,16
    800033f2:	8082                	ret

00000000800033f4 <sys_fork>:

uint64
sys_fork(void)
{
    800033f4:	1141                	addi	sp,sp,-16
    800033f6:	e406                	sd	ra,8(sp)
    800033f8:	e022                	sd	s0,0(sp)
    800033fa:	0800                	addi	s0,sp,16
  return fork();
    800033fc:	fffff097          	auipc	ra,0xfffff
    80003400:	b48080e7          	jalr	-1208(ra) # 80001f44 <fork>
}
    80003404:	60a2                	ld	ra,8(sp)
    80003406:	6402                	ld	s0,0(sp)
    80003408:	0141                	addi	sp,sp,16
    8000340a:	8082                	ret

000000008000340c <sys_wait>:

uint64
sys_wait(void)
{
    8000340c:	1101                	addi	sp,sp,-32
    8000340e:	ec06                	sd	ra,24(sp)
    80003410:	e822                	sd	s0,16(sp)
    80003412:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003414:	fe840593          	addi	a1,s0,-24
    80003418:	4501                	li	a0,0
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	d6c080e7          	jalr	-660(ra) # 80003186 <argaddr>
  return wait(p);
    80003422:	fe843503          	ld	a0,-24(s0)
    80003426:	fffff097          	auipc	ra,0xfffff
    8000342a:	484080e7          	jalr	1156(ra) # 800028aa <wait>
}
    8000342e:	60e2                	ld	ra,24(sp)
    80003430:	6442                	ld	s0,16(sp)
    80003432:	6105                	addi	sp,sp,32
    80003434:	8082                	ret

0000000080003436 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003436:	7179                	addi	sp,sp,-48
    80003438:	f406                	sd	ra,40(sp)
    8000343a:	f022                	sd	s0,32(sp)
    8000343c:	ec26                	sd	s1,24(sp)
    8000343e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003440:	fdc40593          	addi	a1,s0,-36
    80003444:	4501                	li	a0,0
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	d20080e7          	jalr	-736(ra) # 80003166 <argint>
  addr = myproc()->sz;
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	6aa080e7          	jalr	1706(ra) # 80001af8 <myproc>
    80003456:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003458:	fdc42503          	lw	a0,-36(s0)
    8000345c:	fffff097          	auipc	ra,0xfffff
    80003460:	a8c080e7          	jalr	-1396(ra) # 80001ee8 <growproc>
    80003464:	00054863          	bltz	a0,80003474 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003468:	8526                	mv	a0,s1
    8000346a:	70a2                	ld	ra,40(sp)
    8000346c:	7402                	ld	s0,32(sp)
    8000346e:	64e2                	ld	s1,24(sp)
    80003470:	6145                	addi	sp,sp,48
    80003472:	8082                	ret
    return -1;
    80003474:	54fd                	li	s1,-1
    80003476:	bfcd                	j	80003468 <sys_sbrk+0x32>

0000000080003478 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003478:	7139                	addi	sp,sp,-64
    8000347a:	fc06                	sd	ra,56(sp)
    8000347c:	f822                	sd	s0,48(sp)
    8000347e:	f426                	sd	s1,40(sp)
    80003480:	f04a                	sd	s2,32(sp)
    80003482:	ec4e                	sd	s3,24(sp)
    80003484:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003486:	fcc40593          	addi	a1,s0,-52
    8000348a:	4501                	li	a0,0
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	cda080e7          	jalr	-806(ra) # 80003166 <argint>
  acquire(&tickslock);
    80003494:	0003a517          	auipc	a0,0x3a
    80003498:	b7c50513          	addi	a0,a0,-1156 # 8003d010 <tickslock>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	7c8080e7          	jalr	1992(ra) # 80000c64 <acquire>
  ticks0 = ticks;
    800034a4:	00005917          	auipc	s2,0x5
    800034a8:	6d492903          	lw	s2,1748(s2) # 80008b78 <ticks>
  while (ticks - ticks0 < n)
    800034ac:	fcc42783          	lw	a5,-52(s0)
    800034b0:	cf9d                	beqz	a5,800034ee <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034b2:	0003a997          	auipc	s3,0x3a
    800034b6:	b5e98993          	addi	s3,s3,-1186 # 8003d010 <tickslock>
    800034ba:	00005497          	auipc	s1,0x5
    800034be:	6be48493          	addi	s1,s1,1726 # 80008b78 <ticks>
    if (killed(myproc()))
    800034c2:	ffffe097          	auipc	ra,0xffffe
    800034c6:	636080e7          	jalr	1590(ra) # 80001af8 <myproc>
    800034ca:	fffff097          	auipc	ra,0xfffff
    800034ce:	3ae080e7          	jalr	942(ra) # 80002878 <killed>
    800034d2:	ed15                	bnez	a0,8000350e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800034d4:	85ce                	mv	a1,s3
    800034d6:	8526                	mv	a0,s1
    800034d8:	fffff097          	auipc	ra,0xfffff
    800034dc:	fa0080e7          	jalr	-96(ra) # 80002478 <sleep>
  while (ticks - ticks0 < n)
    800034e0:	409c                	lw	a5,0(s1)
    800034e2:	412787bb          	subw	a5,a5,s2
    800034e6:	fcc42703          	lw	a4,-52(s0)
    800034ea:	fce7ece3          	bltu	a5,a4,800034c2 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800034ee:	0003a517          	auipc	a0,0x3a
    800034f2:	b2250513          	addi	a0,a0,-1246 # 8003d010 <tickslock>
    800034f6:	ffffe097          	auipc	ra,0xffffe
    800034fa:	822080e7          	jalr	-2014(ra) # 80000d18 <release>
  return 0;
    800034fe:	4501                	li	a0,0
}
    80003500:	70e2                	ld	ra,56(sp)
    80003502:	7442                	ld	s0,48(sp)
    80003504:	74a2                	ld	s1,40(sp)
    80003506:	7902                	ld	s2,32(sp)
    80003508:	69e2                	ld	s3,24(sp)
    8000350a:	6121                	addi	sp,sp,64
    8000350c:	8082                	ret
      release(&tickslock);
    8000350e:	0003a517          	auipc	a0,0x3a
    80003512:	b0250513          	addi	a0,a0,-1278 # 8003d010 <tickslock>
    80003516:	ffffe097          	auipc	ra,0xffffe
    8000351a:	802080e7          	jalr	-2046(ra) # 80000d18 <release>
      return -1;
    8000351e:	557d                	li	a0,-1
    80003520:	b7c5                	j	80003500 <sys_sleep+0x88>

0000000080003522 <sys_kill>:

uint64
sys_kill(void)
{
    80003522:	1101                	addi	sp,sp,-32
    80003524:	ec06                	sd	ra,24(sp)
    80003526:	e822                	sd	s0,16(sp)
    80003528:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000352a:	fec40593          	addi	a1,s0,-20
    8000352e:	4501                	li	a0,0
    80003530:	00000097          	auipc	ra,0x0
    80003534:	c36080e7          	jalr	-970(ra) # 80003166 <argint>
  return kill(pid);
    80003538:	fec42503          	lw	a0,-20(s0)
    8000353c:	fffff097          	auipc	ra,0xfffff
    80003540:	29e080e7          	jalr	670(ra) # 800027da <kill>
}
    80003544:	60e2                	ld	ra,24(sp)
    80003546:	6442                	ld	s0,16(sp)
    80003548:	6105                	addi	sp,sp,32
    8000354a:	8082                	ret

000000008000354c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000354c:	1101                	addi	sp,sp,-32
    8000354e:	ec06                	sd	ra,24(sp)
    80003550:	e822                	sd	s0,16(sp)
    80003552:	e426                	sd	s1,8(sp)
    80003554:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003556:	0003a517          	auipc	a0,0x3a
    8000355a:	aba50513          	addi	a0,a0,-1350 # 8003d010 <tickslock>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	706080e7          	jalr	1798(ra) # 80000c64 <acquire>
  xticks = ticks;
    80003566:	00005497          	auipc	s1,0x5
    8000356a:	6124a483          	lw	s1,1554(s1) # 80008b78 <ticks>
  release(&tickslock);
    8000356e:	0003a517          	auipc	a0,0x3a
    80003572:	aa250513          	addi	a0,a0,-1374 # 8003d010 <tickslock>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	7a2080e7          	jalr	1954(ra) # 80000d18 <release>
  return xticks;
}
    8000357e:	02049513          	slli	a0,s1,0x20
    80003582:	9101                	srli	a0,a0,0x20
    80003584:	60e2                	ld	ra,24(sp)
    80003586:	6442                	ld	s0,16(sp)
    80003588:	64a2                	ld	s1,8(sp)
    8000358a:	6105                	addi	sp,sp,32
    8000358c:	8082                	ret

000000008000358e <sys_trace>:

uint64
sys_trace(void)
{
    8000358e:	1101                	addi	sp,sp,-32
    80003590:	ec06                	sd	ra,24(sp)
    80003592:	e822                	sd	s0,16(sp)
    80003594:	1000                	addi	s0,sp,32
  int num;
  argint(0, &num);
    80003596:	fec40593          	addi	a1,s0,-20
    8000359a:	4501                	li	a0,0
    8000359c:	00000097          	auipc	ra,0x0
    800035a0:	bca080e7          	jalr	-1078(ra) # 80003166 <argint>
  myproc()->trace_mask = num;
    800035a4:	ffffe097          	auipc	ra,0xffffe
    800035a8:	554080e7          	jalr	1364(ra) # 80001af8 <myproc>
    800035ac:	fec42783          	lw	a5,-20(s0)
    800035b0:	16f52423          	sw	a5,360(a0)
  return 0;
}
    800035b4:	4501                	li	a0,0
    800035b6:	60e2                	ld	ra,24(sp)
    800035b8:	6442                	ld	s0,16(sp)
    800035ba:	6105                	addi	sp,sp,32
    800035bc:	8082                	ret

00000000800035be <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    800035be:	1101                	addi	sp,sp,-32
    800035c0:	ec06                	sd	ra,24(sp)
    800035c2:	e822                	sd	s0,16(sp)
    800035c4:	1000                	addi	s0,sp,32
  int ticks, handle;
  argint(0, &ticks);
    800035c6:	fec40593          	addi	a1,s0,-20
    800035ca:	4501                	li	a0,0
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	b9a080e7          	jalr	-1126(ra) # 80003166 <argint>
  argint(1, &handle);
    800035d4:	fe840593          	addi	a1,s0,-24
    800035d8:	4505                	li	a0,1
    800035da:	00000097          	auipc	ra,0x0
    800035de:	b8c080e7          	jalr	-1140(ra) # 80003166 <argint>
  if (ticks >= 0)
    800035e2:	fec42783          	lw	a5,-20(s0)
    proc->handler = (uint64)handle;
    proc->alarm_ticks = 0;
    proc->max_alarm_ticks = ticks;
    return 0;
  }
  return -1;
    800035e6:	557d                	li	a0,-1
  if (ticks >= 0)
    800035e8:	0007d663          	bgez	a5,800035f4 <sys_sigalarm+0x36>
}
    800035ec:	60e2                	ld	ra,24(sp)
    800035ee:	6442                	ld	s0,16(sp)
    800035f0:	6105                	addi	sp,sp,32
    800035f2:	8082                	ret
    struct proc *proc = myproc();
    800035f4:	ffffe097          	auipc	ra,0xffffe
    800035f8:	504080e7          	jalr	1284(ra) # 80001af8 <myproc>
    proc->handler = (uint64)handle;
    800035fc:	fe842783          	lw	a5,-24(s0)
    80003600:	16f53c23          	sd	a5,376(a0)
    proc->alarm_ticks = 0;
    80003604:	16052823          	sw	zero,368(a0)
    proc->max_alarm_ticks = ticks;
    80003608:	fec42783          	lw	a5,-20(s0)
    8000360c:	16f52623          	sw	a5,364(a0)
    return 0;
    80003610:	4501                	li	a0,0
    80003612:	bfe9                	j	800035ec <sys_sigalarm+0x2e>

0000000080003614 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80003614:	1141                	addi	sp,sp,-16
    80003616:	e406                	sd	ra,8(sp)
    80003618:	e022                	sd	s0,0(sp)
    8000361a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000361c:	ffffe097          	auipc	ra,0xffffe
    80003620:	4dc080e7          	jalr	1244(ra) # 80001af8 <myproc>
    80003624:	87aa                	mv	a5,a0
  if (p->alarm_ticks == -1)
    80003626:	17052683          	lw	a3,368(a0)
    8000362a:	577d                	li	a4,-1
  {
    p->alarm_ticks = 0;
    memmove(p->trapframe, &p->alarm_trap, sizeof(p->alarm_trap));
    return 0;
  }
  return -1;
    8000362c:	557d                	li	a0,-1
  if (p->alarm_ticks == -1)
    8000362e:	00e68663          	beq	a3,a4,8000363a <sys_sigreturn+0x26>
}
    80003632:	60a2                	ld	ra,8(sp)
    80003634:	6402                	ld	s0,0(sp)
    80003636:	0141                	addi	sp,sp,16
    80003638:	8082                	ret
    p->alarm_ticks = 0;
    8000363a:	1607a823          	sw	zero,368(a5)
    memmove(p->trapframe, &p->alarm_trap, sizeof(p->alarm_trap));
    8000363e:	12000613          	li	a2,288
    80003642:	18078593          	addi	a1,a5,384
    80003646:	6fa8                	ld	a0,88(a5)
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	774080e7          	jalr	1908(ra) # 80000dbc <memmove>
    return 0;
    80003650:	4501                	li	a0,0
    80003652:	b7c5                	j	80003632 <sys_sigreturn+0x1e>

0000000080003654 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003654:	7139                	addi	sp,sp,-64
    80003656:	fc06                	sd	ra,56(sp)
    80003658:	f822                	sd	s0,48(sp)
    8000365a:	f426                	sd	s1,40(sp)
    8000365c:	f04a                	sd	s2,32(sp)
    8000365e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003660:	fd840593          	addi	a1,s0,-40
    80003664:	4501                	li	a0,0
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	b20080e7          	jalr	-1248(ra) # 80003186 <argaddr>
  argaddr(1, &addr1);
    8000366e:	fd040593          	addi	a1,s0,-48
    80003672:	4505                	li	a0,1
    80003674:	00000097          	auipc	ra,0x0
    80003678:	b12080e7          	jalr	-1262(ra) # 80003186 <argaddr>
  argaddr(2, &addr2);
    8000367c:	fc840593          	addi	a1,s0,-56
    80003680:	4509                	li	a0,2
    80003682:	00000097          	auipc	ra,0x0
    80003686:	b04080e7          	jalr	-1276(ra) # 80003186 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000368a:	fc040613          	addi	a2,s0,-64
    8000368e:	fc440593          	addi	a1,s0,-60
    80003692:	fd843503          	ld	a0,-40(s0)
    80003696:	fffff097          	auipc	ra,0xfffff
    8000369a:	e46080e7          	jalr	-442(ra) # 800024dc <waitx>
    8000369e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800036a0:	ffffe097          	auipc	ra,0xffffe
    800036a4:	458080e7          	jalr	1112(ra) # 80001af8 <myproc>
    800036a8:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036aa:	4691                	li	a3,4
    800036ac:	fc440613          	addi	a2,s0,-60
    800036b0:	fd043583          	ld	a1,-48(s0)
    800036b4:	6928                	ld	a0,80(a0)
    800036b6:	ffffe097          	auipc	ra,0xffffe
    800036ba:	038080e7          	jalr	56(ra) # 800016ee <copyout>
    return -1;
    800036be:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036c0:	00054f63          	bltz	a0,800036de <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800036c4:	4691                	li	a3,4
    800036c6:	fc040613          	addi	a2,s0,-64
    800036ca:	fc843583          	ld	a1,-56(s0)
    800036ce:	68a8                	ld	a0,80(s1)
    800036d0:	ffffe097          	auipc	ra,0xffffe
    800036d4:	01e080e7          	jalr	30(ra) # 800016ee <copyout>
    800036d8:	00054a63          	bltz	a0,800036ec <sys_waitx+0x98>
    return -1;
  return ret;
    800036dc:	87ca                	mv	a5,s2
}
    800036de:	853e                	mv	a0,a5
    800036e0:	70e2                	ld	ra,56(sp)
    800036e2:	7442                	ld	s0,48(sp)
    800036e4:	74a2                	ld	s1,40(sp)
    800036e6:	7902                	ld	s2,32(sp)
    800036e8:	6121                	addi	sp,sp,64
    800036ea:	8082                	ret
    return -1;
    800036ec:	57fd                	li	a5,-1
    800036ee:	bfc5                	j	800036de <sys_waitx+0x8a>

00000000800036f0 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800036f0:	1101                	addi	sp,sp,-32
    800036f2:	ec06                	sd	ra,24(sp)
    800036f4:	e822                	sd	s0,16(sp)
    800036f6:	1000                	addi	s0,sp,32
  int priority = 0;
    800036f8:	fe042623          	sw	zero,-20(s0)
  int pid = 0;
    800036fc:	fe042423          	sw	zero,-24(s0)
  argint(0, &priority);
    80003700:	fec40593          	addi	a1,s0,-20
    80003704:	4501                	li	a0,0
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	a60080e7          	jalr	-1440(ra) # 80003166 <argint>
  argint(1, &pid);
    8000370e:	fe840593          	addi	a1,s0,-24
    80003712:	4505                	li	a0,1
    80003714:	00000097          	auipc	ra,0x0
    80003718:	a52080e7          	jalr	-1454(ra) # 80003166 <argint>
  return set_static_priority(priority, pid);
    8000371c:	fe842583          	lw	a1,-24(s0)
    80003720:	fec42503          	lw	a0,-20(s0)
    80003724:	fffff097          	auipc	ra,0xfffff
    80003728:	ca2080e7          	jalr	-862(ra) # 800023c6 <set_static_priority>
}
    8000372c:	60e2                	ld	ra,24(sp)
    8000372e:	6442                	ld	s0,16(sp)
    80003730:	6105                	addi	sp,sp,32
    80003732:	8082                	ret

0000000080003734 <sys_settickets>:

uint64
sys_settickets(void)
{
    80003734:	1101                	addi	sp,sp,-32
    80003736:	ec06                	sd	ra,24(sp)
    80003738:	e822                	sd	s0,16(sp)
    8000373a:	1000                	addi	s0,sp,32
  int num;
  argint(0, &num);
    8000373c:	fec40593          	addi	a1,s0,-20
    80003740:	4501                	li	a0,0
    80003742:	00000097          	auipc	ra,0x0
    80003746:	a24080e7          	jalr	-1500(ra) # 80003166 <argint>

  if(num>=1)
    8000374a:	fec42783          	lw	a5,-20(s0)
  {
    settickets(num);
    return 0;
  }
  return -1;
    8000374e:	557d                	li	a0,-1
  if(num>=1)
    80003750:	00f04663          	bgtz	a5,8000375c <sys_settickets+0x28>
    80003754:	60e2                	ld	ra,24(sp)
    80003756:	6442                	ld	s0,16(sp)
    80003758:	6105                	addi	sp,sp,32
    8000375a:	8082                	ret
    settickets(num);
    8000375c:	853e                	mv	a0,a5
    8000375e:	fffff097          	auipc	ra,0xfffff
    80003762:	3d4080e7          	jalr	980(ra) # 80002b32 <settickets>
    return 0;
    80003766:	4501                	li	a0,0
    80003768:	b7f5                	j	80003754 <sys_settickets+0x20>

000000008000376a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000376a:	7179                	addi	sp,sp,-48
    8000376c:	f406                	sd	ra,40(sp)
    8000376e:	f022                	sd	s0,32(sp)
    80003770:	ec26                	sd	s1,24(sp)
    80003772:	e84a                	sd	s2,16(sp)
    80003774:	e44e                	sd	s3,8(sp)
    80003776:	e052                	sd	s4,0(sp)
    80003778:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000377a:	00005597          	auipc	a1,0x5
    8000377e:	ee658593          	addi	a1,a1,-282 # 80008660 <syscalls+0xe0>
    80003782:	0003a517          	auipc	a0,0x3a
    80003786:	8a650513          	addi	a0,a0,-1882 # 8003d028 <bcache>
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	44a080e7          	jalr	1098(ra) # 80000bd4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003792:	00042797          	auipc	a5,0x42
    80003796:	89678793          	addi	a5,a5,-1898 # 80045028 <bcache+0x8000>
    8000379a:	00042717          	auipc	a4,0x42
    8000379e:	af670713          	addi	a4,a4,-1290 # 80045290 <bcache+0x8268>
    800037a2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800037a6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037aa:	0003a497          	auipc	s1,0x3a
    800037ae:	89648493          	addi	s1,s1,-1898 # 8003d040 <bcache+0x18>
    b->next = bcache.head.next;
    800037b2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800037b4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800037b6:	00005a17          	auipc	s4,0x5
    800037ba:	eb2a0a13          	addi	s4,s4,-334 # 80008668 <syscalls+0xe8>
    b->next = bcache.head.next;
    800037be:	2b893783          	ld	a5,696(s2)
    800037c2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800037c4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800037c8:	85d2                	mv	a1,s4
    800037ca:	01048513          	addi	a0,s1,16
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	4c4080e7          	jalr	1220(ra) # 80004c92 <initsleeplock>
    bcache.head.next->prev = b;
    800037d6:	2b893783          	ld	a5,696(s2)
    800037da:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800037dc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037e0:	45848493          	addi	s1,s1,1112
    800037e4:	fd349de3          	bne	s1,s3,800037be <binit+0x54>
  }
}
    800037e8:	70a2                	ld	ra,40(sp)
    800037ea:	7402                	ld	s0,32(sp)
    800037ec:	64e2                	ld	s1,24(sp)
    800037ee:	6942                	ld	s2,16(sp)
    800037f0:	69a2                	ld	s3,8(sp)
    800037f2:	6a02                	ld	s4,0(sp)
    800037f4:	6145                	addi	sp,sp,48
    800037f6:	8082                	ret

00000000800037f8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800037f8:	7179                	addi	sp,sp,-48
    800037fa:	f406                	sd	ra,40(sp)
    800037fc:	f022                	sd	s0,32(sp)
    800037fe:	ec26                	sd	s1,24(sp)
    80003800:	e84a                	sd	s2,16(sp)
    80003802:	e44e                	sd	s3,8(sp)
    80003804:	1800                	addi	s0,sp,48
    80003806:	892a                	mv	s2,a0
    80003808:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000380a:	0003a517          	auipc	a0,0x3a
    8000380e:	81e50513          	addi	a0,a0,-2018 # 8003d028 <bcache>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	452080e7          	jalr	1106(ra) # 80000c64 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000381a:	00042497          	auipc	s1,0x42
    8000381e:	ac64b483          	ld	s1,-1338(s1) # 800452e0 <bcache+0x82b8>
    80003822:	00042797          	auipc	a5,0x42
    80003826:	a6e78793          	addi	a5,a5,-1426 # 80045290 <bcache+0x8268>
    8000382a:	02f48f63          	beq	s1,a5,80003868 <bread+0x70>
    8000382e:	873e                	mv	a4,a5
    80003830:	a021                	j	80003838 <bread+0x40>
    80003832:	68a4                	ld	s1,80(s1)
    80003834:	02e48a63          	beq	s1,a4,80003868 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003838:	449c                	lw	a5,8(s1)
    8000383a:	ff279ce3          	bne	a5,s2,80003832 <bread+0x3a>
    8000383e:	44dc                	lw	a5,12(s1)
    80003840:	ff3799e3          	bne	a5,s3,80003832 <bread+0x3a>
      b->refcnt++;
    80003844:	40bc                	lw	a5,64(s1)
    80003846:	2785                	addiw	a5,a5,1
    80003848:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000384a:	00039517          	auipc	a0,0x39
    8000384e:	7de50513          	addi	a0,a0,2014 # 8003d028 <bcache>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	4c6080e7          	jalr	1222(ra) # 80000d18 <release>
      acquiresleep(&b->lock);
    8000385a:	01048513          	addi	a0,s1,16
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	46e080e7          	jalr	1134(ra) # 80004ccc <acquiresleep>
      return b;
    80003866:	a8b9                	j	800038c4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003868:	00042497          	auipc	s1,0x42
    8000386c:	a704b483          	ld	s1,-1424(s1) # 800452d8 <bcache+0x82b0>
    80003870:	00042797          	auipc	a5,0x42
    80003874:	a2078793          	addi	a5,a5,-1504 # 80045290 <bcache+0x8268>
    80003878:	00f48863          	beq	s1,a5,80003888 <bread+0x90>
    8000387c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000387e:	40bc                	lw	a5,64(s1)
    80003880:	cf81                	beqz	a5,80003898 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003882:	64a4                	ld	s1,72(s1)
    80003884:	fee49de3          	bne	s1,a4,8000387e <bread+0x86>
  panic("bget: no buffers");
    80003888:	00005517          	auipc	a0,0x5
    8000388c:	de850513          	addi	a0,a0,-536 # 80008670 <syscalls+0xf0>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>
      b->dev = dev;
    80003898:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000389c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800038a0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800038a4:	4785                	li	a5,1
    800038a6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038a8:	00039517          	auipc	a0,0x39
    800038ac:	78050513          	addi	a0,a0,1920 # 8003d028 <bcache>
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	468080e7          	jalr	1128(ra) # 80000d18 <release>
      acquiresleep(&b->lock);
    800038b8:	01048513          	addi	a0,s1,16
    800038bc:	00001097          	auipc	ra,0x1
    800038c0:	410080e7          	jalr	1040(ra) # 80004ccc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800038c4:	409c                	lw	a5,0(s1)
    800038c6:	cb89                	beqz	a5,800038d8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800038c8:	8526                	mv	a0,s1
    800038ca:	70a2                	ld	ra,40(sp)
    800038cc:	7402                	ld	s0,32(sp)
    800038ce:	64e2                	ld	s1,24(sp)
    800038d0:	6942                	ld	s2,16(sp)
    800038d2:	69a2                	ld	s3,8(sp)
    800038d4:	6145                	addi	sp,sp,48
    800038d6:	8082                	ret
    virtio_disk_rw(b, 0);
    800038d8:	4581                	li	a1,0
    800038da:	8526                	mv	a0,s1
    800038dc:	00003097          	auipc	ra,0x3
    800038e0:	fd8080e7          	jalr	-40(ra) # 800068b4 <virtio_disk_rw>
    b->valid = 1;
    800038e4:	4785                	li	a5,1
    800038e6:	c09c                	sw	a5,0(s1)
  return b;
    800038e8:	b7c5                	j	800038c8 <bread+0xd0>

00000000800038ea <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800038ea:	1101                	addi	sp,sp,-32
    800038ec:	ec06                	sd	ra,24(sp)
    800038ee:	e822                	sd	s0,16(sp)
    800038f0:	e426                	sd	s1,8(sp)
    800038f2:	1000                	addi	s0,sp,32
    800038f4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038f6:	0541                	addi	a0,a0,16
    800038f8:	00001097          	auipc	ra,0x1
    800038fc:	46e080e7          	jalr	1134(ra) # 80004d66 <holdingsleep>
    80003900:	cd01                	beqz	a0,80003918 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003902:	4585                	li	a1,1
    80003904:	8526                	mv	a0,s1
    80003906:	00003097          	auipc	ra,0x3
    8000390a:	fae080e7          	jalr	-82(ra) # 800068b4 <virtio_disk_rw>
}
    8000390e:	60e2                	ld	ra,24(sp)
    80003910:	6442                	ld	s0,16(sp)
    80003912:	64a2                	ld	s1,8(sp)
    80003914:	6105                	addi	sp,sp,32
    80003916:	8082                	ret
    panic("bwrite");
    80003918:	00005517          	auipc	a0,0x5
    8000391c:	d7050513          	addi	a0,a0,-656 # 80008688 <syscalls+0x108>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	c1e080e7          	jalr	-994(ra) # 8000053e <panic>

0000000080003928 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003928:	1101                	addi	sp,sp,-32
    8000392a:	ec06                	sd	ra,24(sp)
    8000392c:	e822                	sd	s0,16(sp)
    8000392e:	e426                	sd	s1,8(sp)
    80003930:	e04a                	sd	s2,0(sp)
    80003932:	1000                	addi	s0,sp,32
    80003934:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003936:	01050913          	addi	s2,a0,16
    8000393a:	854a                	mv	a0,s2
    8000393c:	00001097          	auipc	ra,0x1
    80003940:	42a080e7          	jalr	1066(ra) # 80004d66 <holdingsleep>
    80003944:	c92d                	beqz	a0,800039b6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003946:	854a                	mv	a0,s2
    80003948:	00001097          	auipc	ra,0x1
    8000394c:	3da080e7          	jalr	986(ra) # 80004d22 <releasesleep>

  acquire(&bcache.lock);
    80003950:	00039517          	auipc	a0,0x39
    80003954:	6d850513          	addi	a0,a0,1752 # 8003d028 <bcache>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	30c080e7          	jalr	780(ra) # 80000c64 <acquire>
  b->refcnt--;
    80003960:	40bc                	lw	a5,64(s1)
    80003962:	37fd                	addiw	a5,a5,-1
    80003964:	0007871b          	sext.w	a4,a5
    80003968:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000396a:	eb05                	bnez	a4,8000399a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000396c:	68bc                	ld	a5,80(s1)
    8000396e:	64b8                	ld	a4,72(s1)
    80003970:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003972:	64bc                	ld	a5,72(s1)
    80003974:	68b8                	ld	a4,80(s1)
    80003976:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003978:	00041797          	auipc	a5,0x41
    8000397c:	6b078793          	addi	a5,a5,1712 # 80045028 <bcache+0x8000>
    80003980:	2b87b703          	ld	a4,696(a5)
    80003984:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003986:	00042717          	auipc	a4,0x42
    8000398a:	90a70713          	addi	a4,a4,-1782 # 80045290 <bcache+0x8268>
    8000398e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003990:	2b87b703          	ld	a4,696(a5)
    80003994:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003996:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000399a:	00039517          	auipc	a0,0x39
    8000399e:	68e50513          	addi	a0,a0,1678 # 8003d028 <bcache>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	376080e7          	jalr	886(ra) # 80000d18 <release>
}
    800039aa:	60e2                	ld	ra,24(sp)
    800039ac:	6442                	ld	s0,16(sp)
    800039ae:	64a2                	ld	s1,8(sp)
    800039b0:	6902                	ld	s2,0(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret
    panic("brelse");
    800039b6:	00005517          	auipc	a0,0x5
    800039ba:	cda50513          	addi	a0,a0,-806 # 80008690 <syscalls+0x110>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>

00000000800039c6 <bpin>:

void
bpin(struct buf *b) {
    800039c6:	1101                	addi	sp,sp,-32
    800039c8:	ec06                	sd	ra,24(sp)
    800039ca:	e822                	sd	s0,16(sp)
    800039cc:	e426                	sd	s1,8(sp)
    800039ce:	1000                	addi	s0,sp,32
    800039d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039d2:	00039517          	auipc	a0,0x39
    800039d6:	65650513          	addi	a0,a0,1622 # 8003d028 <bcache>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	28a080e7          	jalr	650(ra) # 80000c64 <acquire>
  b->refcnt++;
    800039e2:	40bc                	lw	a5,64(s1)
    800039e4:	2785                	addiw	a5,a5,1
    800039e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039e8:	00039517          	auipc	a0,0x39
    800039ec:	64050513          	addi	a0,a0,1600 # 8003d028 <bcache>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	328080e7          	jalr	808(ra) # 80000d18 <release>
}
    800039f8:	60e2                	ld	ra,24(sp)
    800039fa:	6442                	ld	s0,16(sp)
    800039fc:	64a2                	ld	s1,8(sp)
    800039fe:	6105                	addi	sp,sp,32
    80003a00:	8082                	ret

0000000080003a02 <bunpin>:

void
bunpin(struct buf *b) {
    80003a02:	1101                	addi	sp,sp,-32
    80003a04:	ec06                	sd	ra,24(sp)
    80003a06:	e822                	sd	s0,16(sp)
    80003a08:	e426                	sd	s1,8(sp)
    80003a0a:	1000                	addi	s0,sp,32
    80003a0c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a0e:	00039517          	auipc	a0,0x39
    80003a12:	61a50513          	addi	a0,a0,1562 # 8003d028 <bcache>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	24e080e7          	jalr	590(ra) # 80000c64 <acquire>
  b->refcnt--;
    80003a1e:	40bc                	lw	a5,64(s1)
    80003a20:	37fd                	addiw	a5,a5,-1
    80003a22:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a24:	00039517          	auipc	a0,0x39
    80003a28:	60450513          	addi	a0,a0,1540 # 8003d028 <bcache>
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	2ec080e7          	jalr	748(ra) # 80000d18 <release>
}
    80003a34:	60e2                	ld	ra,24(sp)
    80003a36:	6442                	ld	s0,16(sp)
    80003a38:	64a2                	ld	s1,8(sp)
    80003a3a:	6105                	addi	sp,sp,32
    80003a3c:	8082                	ret

0000000080003a3e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a3e:	1101                	addi	sp,sp,-32
    80003a40:	ec06                	sd	ra,24(sp)
    80003a42:	e822                	sd	s0,16(sp)
    80003a44:	e426                	sd	s1,8(sp)
    80003a46:	e04a                	sd	s2,0(sp)
    80003a48:	1000                	addi	s0,sp,32
    80003a4a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a4c:	00d5d59b          	srliw	a1,a1,0xd
    80003a50:	00042797          	auipc	a5,0x42
    80003a54:	cb47a783          	lw	a5,-844(a5) # 80045704 <sb+0x1c>
    80003a58:	9dbd                	addw	a1,a1,a5
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	d9e080e7          	jalr	-610(ra) # 800037f8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a62:	0074f713          	andi	a4,s1,7
    80003a66:	4785                	li	a5,1
    80003a68:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a6c:	14ce                	slli	s1,s1,0x33
    80003a6e:	90d9                	srli	s1,s1,0x36
    80003a70:	00950733          	add	a4,a0,s1
    80003a74:	05874703          	lbu	a4,88(a4)
    80003a78:	00e7f6b3          	and	a3,a5,a4
    80003a7c:	c69d                	beqz	a3,80003aaa <bfree+0x6c>
    80003a7e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a80:	94aa                	add	s1,s1,a0
    80003a82:	fff7c793          	not	a5,a5
    80003a86:	8ff9                	and	a5,a5,a4
    80003a88:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a8c:	00001097          	auipc	ra,0x1
    80003a90:	120080e7          	jalr	288(ra) # 80004bac <log_write>
  brelse(bp);
    80003a94:	854a                	mv	a0,s2
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	e92080e7          	jalr	-366(ra) # 80003928 <brelse>
}
    80003a9e:	60e2                	ld	ra,24(sp)
    80003aa0:	6442                	ld	s0,16(sp)
    80003aa2:	64a2                	ld	s1,8(sp)
    80003aa4:	6902                	ld	s2,0(sp)
    80003aa6:	6105                	addi	sp,sp,32
    80003aa8:	8082                	ret
    panic("freeing free block");
    80003aaa:	00005517          	auipc	a0,0x5
    80003aae:	bee50513          	addi	a0,a0,-1042 # 80008698 <syscalls+0x118>
    80003ab2:	ffffd097          	auipc	ra,0xffffd
    80003ab6:	a8c080e7          	jalr	-1396(ra) # 8000053e <panic>

0000000080003aba <balloc>:
{
    80003aba:	711d                	addi	sp,sp,-96
    80003abc:	ec86                	sd	ra,88(sp)
    80003abe:	e8a2                	sd	s0,80(sp)
    80003ac0:	e4a6                	sd	s1,72(sp)
    80003ac2:	e0ca                	sd	s2,64(sp)
    80003ac4:	fc4e                	sd	s3,56(sp)
    80003ac6:	f852                	sd	s4,48(sp)
    80003ac8:	f456                	sd	s5,40(sp)
    80003aca:	f05a                	sd	s6,32(sp)
    80003acc:	ec5e                	sd	s7,24(sp)
    80003ace:	e862                	sd	s8,16(sp)
    80003ad0:	e466                	sd	s9,8(sp)
    80003ad2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003ad4:	00042797          	auipc	a5,0x42
    80003ad8:	c187a783          	lw	a5,-1000(a5) # 800456ec <sb+0x4>
    80003adc:	10078163          	beqz	a5,80003bde <balloc+0x124>
    80003ae0:	8baa                	mv	s7,a0
    80003ae2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003ae4:	00042b17          	auipc	s6,0x42
    80003ae8:	c04b0b13          	addi	s6,s6,-1020 # 800456e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003aec:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003aee:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003af0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003af2:	6c89                	lui	s9,0x2
    80003af4:	a061                	j	80003b7c <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003af6:	974a                	add	a4,a4,s2
    80003af8:	8fd5                	or	a5,a5,a3
    80003afa:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003afe:	854a                	mv	a0,s2
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	0ac080e7          	jalr	172(ra) # 80004bac <log_write>
        brelse(bp);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	e1e080e7          	jalr	-482(ra) # 80003928 <brelse>
  bp = bread(dev, bno);
    80003b12:	85a6                	mv	a1,s1
    80003b14:	855e                	mv	a0,s7
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	ce2080e7          	jalr	-798(ra) # 800037f8 <bread>
    80003b1e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b20:	40000613          	li	a2,1024
    80003b24:	4581                	li	a1,0
    80003b26:	05850513          	addi	a0,a0,88
    80003b2a:	ffffd097          	auipc	ra,0xffffd
    80003b2e:	236080e7          	jalr	566(ra) # 80000d60 <memset>
  log_write(bp);
    80003b32:	854a                	mv	a0,s2
    80003b34:	00001097          	auipc	ra,0x1
    80003b38:	078080e7          	jalr	120(ra) # 80004bac <log_write>
  brelse(bp);
    80003b3c:	854a                	mv	a0,s2
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	dea080e7          	jalr	-534(ra) # 80003928 <brelse>
}
    80003b46:	8526                	mv	a0,s1
    80003b48:	60e6                	ld	ra,88(sp)
    80003b4a:	6446                	ld	s0,80(sp)
    80003b4c:	64a6                	ld	s1,72(sp)
    80003b4e:	6906                	ld	s2,64(sp)
    80003b50:	79e2                	ld	s3,56(sp)
    80003b52:	7a42                	ld	s4,48(sp)
    80003b54:	7aa2                	ld	s5,40(sp)
    80003b56:	7b02                	ld	s6,32(sp)
    80003b58:	6be2                	ld	s7,24(sp)
    80003b5a:	6c42                	ld	s8,16(sp)
    80003b5c:	6ca2                	ld	s9,8(sp)
    80003b5e:	6125                	addi	sp,sp,96
    80003b60:	8082                	ret
    brelse(bp);
    80003b62:	854a                	mv	a0,s2
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	dc4080e7          	jalr	-572(ra) # 80003928 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003b6c:	015c87bb          	addw	a5,s9,s5
    80003b70:	00078a9b          	sext.w	s5,a5
    80003b74:	004b2703          	lw	a4,4(s6)
    80003b78:	06eaf363          	bgeu	s5,a4,80003bde <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003b7c:	41fad79b          	sraiw	a5,s5,0x1f
    80003b80:	0137d79b          	srliw	a5,a5,0x13
    80003b84:	015787bb          	addw	a5,a5,s5
    80003b88:	40d7d79b          	sraiw	a5,a5,0xd
    80003b8c:	01cb2583          	lw	a1,28(s6)
    80003b90:	9dbd                	addw	a1,a1,a5
    80003b92:	855e                	mv	a0,s7
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	c64080e7          	jalr	-924(ra) # 800037f8 <bread>
    80003b9c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b9e:	004b2503          	lw	a0,4(s6)
    80003ba2:	000a849b          	sext.w	s1,s5
    80003ba6:	8662                	mv	a2,s8
    80003ba8:	faa4fde3          	bgeu	s1,a0,80003b62 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003bac:	41f6579b          	sraiw	a5,a2,0x1f
    80003bb0:	01d7d69b          	srliw	a3,a5,0x1d
    80003bb4:	00c6873b          	addw	a4,a3,a2
    80003bb8:	00777793          	andi	a5,a4,7
    80003bbc:	9f95                	subw	a5,a5,a3
    80003bbe:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003bc2:	4037571b          	sraiw	a4,a4,0x3
    80003bc6:	00e906b3          	add	a3,s2,a4
    80003bca:	0586c683          	lbu	a3,88(a3)
    80003bce:	00d7f5b3          	and	a1,a5,a3
    80003bd2:	d195                	beqz	a1,80003af6 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bd4:	2605                	addiw	a2,a2,1
    80003bd6:	2485                	addiw	s1,s1,1
    80003bd8:	fd4618e3          	bne	a2,s4,80003ba8 <balloc+0xee>
    80003bdc:	b759                	j	80003b62 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003bde:	00005517          	auipc	a0,0x5
    80003be2:	ad250513          	addi	a0,a0,-1326 # 800086b0 <syscalls+0x130>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	9a2080e7          	jalr	-1630(ra) # 80000588 <printf>
  return 0;
    80003bee:	4481                	li	s1,0
    80003bf0:	bf99                	j	80003b46 <balloc+0x8c>

0000000080003bf2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003bf2:	7179                	addi	sp,sp,-48
    80003bf4:	f406                	sd	ra,40(sp)
    80003bf6:	f022                	sd	s0,32(sp)
    80003bf8:	ec26                	sd	s1,24(sp)
    80003bfa:	e84a                	sd	s2,16(sp)
    80003bfc:	e44e                	sd	s3,8(sp)
    80003bfe:	e052                	sd	s4,0(sp)
    80003c00:	1800                	addi	s0,sp,48
    80003c02:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003c04:	47ad                	li	a5,11
    80003c06:	02b7e763          	bltu	a5,a1,80003c34 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003c0a:	02059493          	slli	s1,a1,0x20
    80003c0e:	9081                	srli	s1,s1,0x20
    80003c10:	048a                	slli	s1,s1,0x2
    80003c12:	94aa                	add	s1,s1,a0
    80003c14:	0504a903          	lw	s2,80(s1)
    80003c18:	06091e63          	bnez	s2,80003c94 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003c1c:	4108                	lw	a0,0(a0)
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	e9c080e7          	jalr	-356(ra) # 80003aba <balloc>
    80003c26:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003c2a:	06090563          	beqz	s2,80003c94 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003c2e:	0524a823          	sw	s2,80(s1)
    80003c32:	a08d                	j	80003c94 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003c34:	ff45849b          	addiw	s1,a1,-12
    80003c38:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003c3c:	0ff00793          	li	a5,255
    80003c40:	08e7e563          	bltu	a5,a4,80003cca <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003c44:	08052903          	lw	s2,128(a0)
    80003c48:	00091d63          	bnez	s2,80003c62 <bmap+0x70>
      addr = balloc(ip->dev);
    80003c4c:	4108                	lw	a0,0(a0)
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	e6c080e7          	jalr	-404(ra) # 80003aba <balloc>
    80003c56:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003c5a:	02090d63          	beqz	s2,80003c94 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003c5e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003c62:	85ca                	mv	a1,s2
    80003c64:	0009a503          	lw	a0,0(s3)
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	b90080e7          	jalr	-1136(ra) # 800037f8 <bread>
    80003c70:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003c72:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003c76:	02049593          	slli	a1,s1,0x20
    80003c7a:	9181                	srli	a1,a1,0x20
    80003c7c:	058a                	slli	a1,a1,0x2
    80003c7e:	00b784b3          	add	s1,a5,a1
    80003c82:	0004a903          	lw	s2,0(s1)
    80003c86:	02090063          	beqz	s2,80003ca6 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003c8a:	8552                	mv	a0,s4
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	c9c080e7          	jalr	-868(ra) # 80003928 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c94:	854a                	mv	a0,s2
    80003c96:	70a2                	ld	ra,40(sp)
    80003c98:	7402                	ld	s0,32(sp)
    80003c9a:	64e2                	ld	s1,24(sp)
    80003c9c:	6942                	ld	s2,16(sp)
    80003c9e:	69a2                	ld	s3,8(sp)
    80003ca0:	6a02                	ld	s4,0(sp)
    80003ca2:	6145                	addi	sp,sp,48
    80003ca4:	8082                	ret
      addr = balloc(ip->dev);
    80003ca6:	0009a503          	lw	a0,0(s3)
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	e10080e7          	jalr	-496(ra) # 80003aba <balloc>
    80003cb2:	0005091b          	sext.w	s2,a0
      if(addr){
    80003cb6:	fc090ae3          	beqz	s2,80003c8a <bmap+0x98>
        a[bn] = addr;
    80003cba:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003cbe:	8552                	mv	a0,s4
    80003cc0:	00001097          	auipc	ra,0x1
    80003cc4:	eec080e7          	jalr	-276(ra) # 80004bac <log_write>
    80003cc8:	b7c9                	j	80003c8a <bmap+0x98>
  panic("bmap: out of range");
    80003cca:	00005517          	auipc	a0,0x5
    80003cce:	9fe50513          	addi	a0,a0,-1538 # 800086c8 <syscalls+0x148>
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>

0000000080003cda <iget>:
{
    80003cda:	7179                	addi	sp,sp,-48
    80003cdc:	f406                	sd	ra,40(sp)
    80003cde:	f022                	sd	s0,32(sp)
    80003ce0:	ec26                	sd	s1,24(sp)
    80003ce2:	e84a                	sd	s2,16(sp)
    80003ce4:	e44e                	sd	s3,8(sp)
    80003ce6:	e052                	sd	s4,0(sp)
    80003ce8:	1800                	addi	s0,sp,48
    80003cea:	89aa                	mv	s3,a0
    80003cec:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003cee:	00042517          	auipc	a0,0x42
    80003cf2:	a1a50513          	addi	a0,a0,-1510 # 80045708 <itable>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	f6e080e7          	jalr	-146(ra) # 80000c64 <acquire>
  empty = 0;
    80003cfe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d00:	00042497          	auipc	s1,0x42
    80003d04:	a2048493          	addi	s1,s1,-1504 # 80045720 <itable+0x18>
    80003d08:	00043697          	auipc	a3,0x43
    80003d0c:	4a868693          	addi	a3,a3,1192 # 800471b0 <log>
    80003d10:	a039                	j	80003d1e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d12:	02090b63          	beqz	s2,80003d48 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d16:	08848493          	addi	s1,s1,136
    80003d1a:	02d48a63          	beq	s1,a3,80003d4e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003d1e:	449c                	lw	a5,8(s1)
    80003d20:	fef059e3          	blez	a5,80003d12 <iget+0x38>
    80003d24:	4098                	lw	a4,0(s1)
    80003d26:	ff3716e3          	bne	a4,s3,80003d12 <iget+0x38>
    80003d2a:	40d8                	lw	a4,4(s1)
    80003d2c:	ff4713e3          	bne	a4,s4,80003d12 <iget+0x38>
      ip->ref++;
    80003d30:	2785                	addiw	a5,a5,1
    80003d32:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d34:	00042517          	auipc	a0,0x42
    80003d38:	9d450513          	addi	a0,a0,-1580 # 80045708 <itable>
    80003d3c:	ffffd097          	auipc	ra,0xffffd
    80003d40:	fdc080e7          	jalr	-36(ra) # 80000d18 <release>
      return ip;
    80003d44:	8926                	mv	s2,s1
    80003d46:	a03d                	j	80003d74 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d48:	f7f9                	bnez	a5,80003d16 <iget+0x3c>
    80003d4a:	8926                	mv	s2,s1
    80003d4c:	b7e9                	j	80003d16 <iget+0x3c>
  if(empty == 0)
    80003d4e:	02090c63          	beqz	s2,80003d86 <iget+0xac>
  ip->dev = dev;
    80003d52:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d56:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d5a:	4785                	li	a5,1
    80003d5c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d60:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d64:	00042517          	auipc	a0,0x42
    80003d68:	9a450513          	addi	a0,a0,-1628 # 80045708 <itable>
    80003d6c:	ffffd097          	auipc	ra,0xffffd
    80003d70:	fac080e7          	jalr	-84(ra) # 80000d18 <release>
}
    80003d74:	854a                	mv	a0,s2
    80003d76:	70a2                	ld	ra,40(sp)
    80003d78:	7402                	ld	s0,32(sp)
    80003d7a:	64e2                	ld	s1,24(sp)
    80003d7c:	6942                	ld	s2,16(sp)
    80003d7e:	69a2                	ld	s3,8(sp)
    80003d80:	6a02                	ld	s4,0(sp)
    80003d82:	6145                	addi	sp,sp,48
    80003d84:	8082                	ret
    panic("iget: no inodes");
    80003d86:	00005517          	auipc	a0,0x5
    80003d8a:	95a50513          	addi	a0,a0,-1702 # 800086e0 <syscalls+0x160>
    80003d8e:	ffffc097          	auipc	ra,0xffffc
    80003d92:	7b0080e7          	jalr	1968(ra) # 8000053e <panic>

0000000080003d96 <fsinit>:
fsinit(int dev) {
    80003d96:	7179                	addi	sp,sp,-48
    80003d98:	f406                	sd	ra,40(sp)
    80003d9a:	f022                	sd	s0,32(sp)
    80003d9c:	ec26                	sd	s1,24(sp)
    80003d9e:	e84a                	sd	s2,16(sp)
    80003da0:	e44e                	sd	s3,8(sp)
    80003da2:	1800                	addi	s0,sp,48
    80003da4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003da6:	4585                	li	a1,1
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	a50080e7          	jalr	-1456(ra) # 800037f8 <bread>
    80003db0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003db2:	00042997          	auipc	s3,0x42
    80003db6:	93698993          	addi	s3,s3,-1738 # 800456e8 <sb>
    80003dba:	02000613          	li	a2,32
    80003dbe:	05850593          	addi	a1,a0,88
    80003dc2:	854e                	mv	a0,s3
    80003dc4:	ffffd097          	auipc	ra,0xffffd
    80003dc8:	ff8080e7          	jalr	-8(ra) # 80000dbc <memmove>
  brelse(bp);
    80003dcc:	8526                	mv	a0,s1
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	b5a080e7          	jalr	-1190(ra) # 80003928 <brelse>
  if(sb.magic != FSMAGIC)
    80003dd6:	0009a703          	lw	a4,0(s3)
    80003dda:	102037b7          	lui	a5,0x10203
    80003dde:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003de2:	02f71263          	bne	a4,a5,80003e06 <fsinit+0x70>
  initlog(dev, &sb);
    80003de6:	00042597          	auipc	a1,0x42
    80003dea:	90258593          	addi	a1,a1,-1790 # 800456e8 <sb>
    80003dee:	854a                	mv	a0,s2
    80003df0:	00001097          	auipc	ra,0x1
    80003df4:	b40080e7          	jalr	-1216(ra) # 80004930 <initlog>
}
    80003df8:	70a2                	ld	ra,40(sp)
    80003dfa:	7402                	ld	s0,32(sp)
    80003dfc:	64e2                	ld	s1,24(sp)
    80003dfe:	6942                	ld	s2,16(sp)
    80003e00:	69a2                	ld	s3,8(sp)
    80003e02:	6145                	addi	sp,sp,48
    80003e04:	8082                	ret
    panic("invalid file system");
    80003e06:	00005517          	auipc	a0,0x5
    80003e0a:	8ea50513          	addi	a0,a0,-1814 # 800086f0 <syscalls+0x170>
    80003e0e:	ffffc097          	auipc	ra,0xffffc
    80003e12:	730080e7          	jalr	1840(ra) # 8000053e <panic>

0000000080003e16 <iinit>:
{
    80003e16:	7179                	addi	sp,sp,-48
    80003e18:	f406                	sd	ra,40(sp)
    80003e1a:	f022                	sd	s0,32(sp)
    80003e1c:	ec26                	sd	s1,24(sp)
    80003e1e:	e84a                	sd	s2,16(sp)
    80003e20:	e44e                	sd	s3,8(sp)
    80003e22:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003e24:	00005597          	auipc	a1,0x5
    80003e28:	8e458593          	addi	a1,a1,-1820 # 80008708 <syscalls+0x188>
    80003e2c:	00042517          	auipc	a0,0x42
    80003e30:	8dc50513          	addi	a0,a0,-1828 # 80045708 <itable>
    80003e34:	ffffd097          	auipc	ra,0xffffd
    80003e38:	da0080e7          	jalr	-608(ra) # 80000bd4 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e3c:	00042497          	auipc	s1,0x42
    80003e40:	8f448493          	addi	s1,s1,-1804 # 80045730 <itable+0x28>
    80003e44:	00043997          	auipc	s3,0x43
    80003e48:	37c98993          	addi	s3,s3,892 # 800471c0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e4c:	00005917          	auipc	s2,0x5
    80003e50:	8c490913          	addi	s2,s2,-1852 # 80008710 <syscalls+0x190>
    80003e54:	85ca                	mv	a1,s2
    80003e56:	8526                	mv	a0,s1
    80003e58:	00001097          	auipc	ra,0x1
    80003e5c:	e3a080e7          	jalr	-454(ra) # 80004c92 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e60:	08848493          	addi	s1,s1,136
    80003e64:	ff3498e3          	bne	s1,s3,80003e54 <iinit+0x3e>
}
    80003e68:	70a2                	ld	ra,40(sp)
    80003e6a:	7402                	ld	s0,32(sp)
    80003e6c:	64e2                	ld	s1,24(sp)
    80003e6e:	6942                	ld	s2,16(sp)
    80003e70:	69a2                	ld	s3,8(sp)
    80003e72:	6145                	addi	sp,sp,48
    80003e74:	8082                	ret

0000000080003e76 <ialloc>:
{
    80003e76:	715d                	addi	sp,sp,-80
    80003e78:	e486                	sd	ra,72(sp)
    80003e7a:	e0a2                	sd	s0,64(sp)
    80003e7c:	fc26                	sd	s1,56(sp)
    80003e7e:	f84a                	sd	s2,48(sp)
    80003e80:	f44e                	sd	s3,40(sp)
    80003e82:	f052                	sd	s4,32(sp)
    80003e84:	ec56                	sd	s5,24(sp)
    80003e86:	e85a                	sd	s6,16(sp)
    80003e88:	e45e                	sd	s7,8(sp)
    80003e8a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e8c:	00042717          	auipc	a4,0x42
    80003e90:	86872703          	lw	a4,-1944(a4) # 800456f4 <sb+0xc>
    80003e94:	4785                	li	a5,1
    80003e96:	04e7fa63          	bgeu	a5,a4,80003eea <ialloc+0x74>
    80003e9a:	8aaa                	mv	s5,a0
    80003e9c:	8bae                	mv	s7,a1
    80003e9e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ea0:	00042a17          	auipc	s4,0x42
    80003ea4:	848a0a13          	addi	s4,s4,-1976 # 800456e8 <sb>
    80003ea8:	00048b1b          	sext.w	s6,s1
    80003eac:	0044d793          	srli	a5,s1,0x4
    80003eb0:	018a2583          	lw	a1,24(s4)
    80003eb4:	9dbd                	addw	a1,a1,a5
    80003eb6:	8556                	mv	a0,s5
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	940080e7          	jalr	-1728(ra) # 800037f8 <bread>
    80003ec0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ec2:	05850993          	addi	s3,a0,88
    80003ec6:	00f4f793          	andi	a5,s1,15
    80003eca:	079a                	slli	a5,a5,0x6
    80003ecc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ece:	00099783          	lh	a5,0(s3)
    80003ed2:	c3a1                	beqz	a5,80003f12 <ialloc+0x9c>
    brelse(bp);
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	a54080e7          	jalr	-1452(ra) # 80003928 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003edc:	0485                	addi	s1,s1,1
    80003ede:	00ca2703          	lw	a4,12(s4)
    80003ee2:	0004879b          	sext.w	a5,s1
    80003ee6:	fce7e1e3          	bltu	a5,a4,80003ea8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003eea:	00005517          	auipc	a0,0x5
    80003eee:	82e50513          	addi	a0,a0,-2002 # 80008718 <syscalls+0x198>
    80003ef2:	ffffc097          	auipc	ra,0xffffc
    80003ef6:	696080e7          	jalr	1686(ra) # 80000588 <printf>
  return 0;
    80003efa:	4501                	li	a0,0
}
    80003efc:	60a6                	ld	ra,72(sp)
    80003efe:	6406                	ld	s0,64(sp)
    80003f00:	74e2                	ld	s1,56(sp)
    80003f02:	7942                	ld	s2,48(sp)
    80003f04:	79a2                	ld	s3,40(sp)
    80003f06:	7a02                	ld	s4,32(sp)
    80003f08:	6ae2                	ld	s5,24(sp)
    80003f0a:	6b42                	ld	s6,16(sp)
    80003f0c:	6ba2                	ld	s7,8(sp)
    80003f0e:	6161                	addi	sp,sp,80
    80003f10:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003f12:	04000613          	li	a2,64
    80003f16:	4581                	li	a1,0
    80003f18:	854e                	mv	a0,s3
    80003f1a:	ffffd097          	auipc	ra,0xffffd
    80003f1e:	e46080e7          	jalr	-442(ra) # 80000d60 <memset>
      dip->type = type;
    80003f22:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003f26:	854a                	mv	a0,s2
    80003f28:	00001097          	auipc	ra,0x1
    80003f2c:	c84080e7          	jalr	-892(ra) # 80004bac <log_write>
      brelse(bp);
    80003f30:	854a                	mv	a0,s2
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	9f6080e7          	jalr	-1546(ra) # 80003928 <brelse>
      return iget(dev, inum);
    80003f3a:	85da                	mv	a1,s6
    80003f3c:	8556                	mv	a0,s5
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	d9c080e7          	jalr	-612(ra) # 80003cda <iget>
    80003f46:	bf5d                	j	80003efc <ialloc+0x86>

0000000080003f48 <iupdate>:
{
    80003f48:	1101                	addi	sp,sp,-32
    80003f4a:	ec06                	sd	ra,24(sp)
    80003f4c:	e822                	sd	s0,16(sp)
    80003f4e:	e426                	sd	s1,8(sp)
    80003f50:	e04a                	sd	s2,0(sp)
    80003f52:	1000                	addi	s0,sp,32
    80003f54:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f56:	415c                	lw	a5,4(a0)
    80003f58:	0047d79b          	srliw	a5,a5,0x4
    80003f5c:	00041597          	auipc	a1,0x41
    80003f60:	7a45a583          	lw	a1,1956(a1) # 80045700 <sb+0x18>
    80003f64:	9dbd                	addw	a1,a1,a5
    80003f66:	4108                	lw	a0,0(a0)
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	890080e7          	jalr	-1904(ra) # 800037f8 <bread>
    80003f70:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f72:	05850793          	addi	a5,a0,88
    80003f76:	40c8                	lw	a0,4(s1)
    80003f78:	893d                	andi	a0,a0,15
    80003f7a:	051a                	slli	a0,a0,0x6
    80003f7c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f7e:	04449703          	lh	a4,68(s1)
    80003f82:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f86:	04649703          	lh	a4,70(s1)
    80003f8a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f8e:	04849703          	lh	a4,72(s1)
    80003f92:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f96:	04a49703          	lh	a4,74(s1)
    80003f9a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f9e:	44f8                	lw	a4,76(s1)
    80003fa0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003fa2:	03400613          	li	a2,52
    80003fa6:	05048593          	addi	a1,s1,80
    80003faa:	0531                	addi	a0,a0,12
    80003fac:	ffffd097          	auipc	ra,0xffffd
    80003fb0:	e10080e7          	jalr	-496(ra) # 80000dbc <memmove>
  log_write(bp);
    80003fb4:	854a                	mv	a0,s2
    80003fb6:	00001097          	auipc	ra,0x1
    80003fba:	bf6080e7          	jalr	-1034(ra) # 80004bac <log_write>
  brelse(bp);
    80003fbe:	854a                	mv	a0,s2
    80003fc0:	00000097          	auipc	ra,0x0
    80003fc4:	968080e7          	jalr	-1688(ra) # 80003928 <brelse>
}
    80003fc8:	60e2                	ld	ra,24(sp)
    80003fca:	6442                	ld	s0,16(sp)
    80003fcc:	64a2                	ld	s1,8(sp)
    80003fce:	6902                	ld	s2,0(sp)
    80003fd0:	6105                	addi	sp,sp,32
    80003fd2:	8082                	ret

0000000080003fd4 <idup>:
{
    80003fd4:	1101                	addi	sp,sp,-32
    80003fd6:	ec06                	sd	ra,24(sp)
    80003fd8:	e822                	sd	s0,16(sp)
    80003fda:	e426                	sd	s1,8(sp)
    80003fdc:	1000                	addi	s0,sp,32
    80003fde:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fe0:	00041517          	auipc	a0,0x41
    80003fe4:	72850513          	addi	a0,a0,1832 # 80045708 <itable>
    80003fe8:	ffffd097          	auipc	ra,0xffffd
    80003fec:	c7c080e7          	jalr	-900(ra) # 80000c64 <acquire>
  ip->ref++;
    80003ff0:	449c                	lw	a5,8(s1)
    80003ff2:	2785                	addiw	a5,a5,1
    80003ff4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ff6:	00041517          	auipc	a0,0x41
    80003ffa:	71250513          	addi	a0,a0,1810 # 80045708 <itable>
    80003ffe:	ffffd097          	auipc	ra,0xffffd
    80004002:	d1a080e7          	jalr	-742(ra) # 80000d18 <release>
}
    80004006:	8526                	mv	a0,s1
    80004008:	60e2                	ld	ra,24(sp)
    8000400a:	6442                	ld	s0,16(sp)
    8000400c:	64a2                	ld	s1,8(sp)
    8000400e:	6105                	addi	sp,sp,32
    80004010:	8082                	ret

0000000080004012 <ilock>:
{
    80004012:	1101                	addi	sp,sp,-32
    80004014:	ec06                	sd	ra,24(sp)
    80004016:	e822                	sd	s0,16(sp)
    80004018:	e426                	sd	s1,8(sp)
    8000401a:	e04a                	sd	s2,0(sp)
    8000401c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000401e:	c115                	beqz	a0,80004042 <ilock+0x30>
    80004020:	84aa                	mv	s1,a0
    80004022:	451c                	lw	a5,8(a0)
    80004024:	00f05f63          	blez	a5,80004042 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004028:	0541                	addi	a0,a0,16
    8000402a:	00001097          	auipc	ra,0x1
    8000402e:	ca2080e7          	jalr	-862(ra) # 80004ccc <acquiresleep>
  if(ip->valid == 0){
    80004032:	40bc                	lw	a5,64(s1)
    80004034:	cf99                	beqz	a5,80004052 <ilock+0x40>
}
    80004036:	60e2                	ld	ra,24(sp)
    80004038:	6442                	ld	s0,16(sp)
    8000403a:	64a2                	ld	s1,8(sp)
    8000403c:	6902                	ld	s2,0(sp)
    8000403e:	6105                	addi	sp,sp,32
    80004040:	8082                	ret
    panic("ilock");
    80004042:	00004517          	auipc	a0,0x4
    80004046:	6ee50513          	addi	a0,a0,1774 # 80008730 <syscalls+0x1b0>
    8000404a:	ffffc097          	auipc	ra,0xffffc
    8000404e:	4f4080e7          	jalr	1268(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004052:	40dc                	lw	a5,4(s1)
    80004054:	0047d79b          	srliw	a5,a5,0x4
    80004058:	00041597          	auipc	a1,0x41
    8000405c:	6a85a583          	lw	a1,1704(a1) # 80045700 <sb+0x18>
    80004060:	9dbd                	addw	a1,a1,a5
    80004062:	4088                	lw	a0,0(s1)
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	794080e7          	jalr	1940(ra) # 800037f8 <bread>
    8000406c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000406e:	05850593          	addi	a1,a0,88
    80004072:	40dc                	lw	a5,4(s1)
    80004074:	8bbd                	andi	a5,a5,15
    80004076:	079a                	slli	a5,a5,0x6
    80004078:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000407a:	00059783          	lh	a5,0(a1)
    8000407e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004082:	00259783          	lh	a5,2(a1)
    80004086:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000408a:	00459783          	lh	a5,4(a1)
    8000408e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004092:	00659783          	lh	a5,6(a1)
    80004096:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000409a:	459c                	lw	a5,8(a1)
    8000409c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000409e:	03400613          	li	a2,52
    800040a2:	05b1                	addi	a1,a1,12
    800040a4:	05048513          	addi	a0,s1,80
    800040a8:	ffffd097          	auipc	ra,0xffffd
    800040ac:	d14080e7          	jalr	-748(ra) # 80000dbc <memmove>
    brelse(bp);
    800040b0:	854a                	mv	a0,s2
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	876080e7          	jalr	-1930(ra) # 80003928 <brelse>
    ip->valid = 1;
    800040ba:	4785                	li	a5,1
    800040bc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800040be:	04449783          	lh	a5,68(s1)
    800040c2:	fbb5                	bnez	a5,80004036 <ilock+0x24>
      panic("ilock: no type");
    800040c4:	00004517          	auipc	a0,0x4
    800040c8:	67450513          	addi	a0,a0,1652 # 80008738 <syscalls+0x1b8>
    800040cc:	ffffc097          	auipc	ra,0xffffc
    800040d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>

00000000800040d4 <iunlock>:
{
    800040d4:	1101                	addi	sp,sp,-32
    800040d6:	ec06                	sd	ra,24(sp)
    800040d8:	e822                	sd	s0,16(sp)
    800040da:	e426                	sd	s1,8(sp)
    800040dc:	e04a                	sd	s2,0(sp)
    800040de:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800040e0:	c905                	beqz	a0,80004110 <iunlock+0x3c>
    800040e2:	84aa                	mv	s1,a0
    800040e4:	01050913          	addi	s2,a0,16
    800040e8:	854a                	mv	a0,s2
    800040ea:	00001097          	auipc	ra,0x1
    800040ee:	c7c080e7          	jalr	-900(ra) # 80004d66 <holdingsleep>
    800040f2:	cd19                	beqz	a0,80004110 <iunlock+0x3c>
    800040f4:	449c                	lw	a5,8(s1)
    800040f6:	00f05d63          	blez	a5,80004110 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800040fa:	854a                	mv	a0,s2
    800040fc:	00001097          	auipc	ra,0x1
    80004100:	c26080e7          	jalr	-986(ra) # 80004d22 <releasesleep>
}
    80004104:	60e2                	ld	ra,24(sp)
    80004106:	6442                	ld	s0,16(sp)
    80004108:	64a2                	ld	s1,8(sp)
    8000410a:	6902                	ld	s2,0(sp)
    8000410c:	6105                	addi	sp,sp,32
    8000410e:	8082                	ret
    panic("iunlock");
    80004110:	00004517          	auipc	a0,0x4
    80004114:	63850513          	addi	a0,a0,1592 # 80008748 <syscalls+0x1c8>
    80004118:	ffffc097          	auipc	ra,0xffffc
    8000411c:	426080e7          	jalr	1062(ra) # 8000053e <panic>

0000000080004120 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004120:	7179                	addi	sp,sp,-48
    80004122:	f406                	sd	ra,40(sp)
    80004124:	f022                	sd	s0,32(sp)
    80004126:	ec26                	sd	s1,24(sp)
    80004128:	e84a                	sd	s2,16(sp)
    8000412a:	e44e                	sd	s3,8(sp)
    8000412c:	e052                	sd	s4,0(sp)
    8000412e:	1800                	addi	s0,sp,48
    80004130:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004132:	05050493          	addi	s1,a0,80
    80004136:	08050913          	addi	s2,a0,128
    8000413a:	a021                	j	80004142 <itrunc+0x22>
    8000413c:	0491                	addi	s1,s1,4
    8000413e:	01248d63          	beq	s1,s2,80004158 <itrunc+0x38>
    if(ip->addrs[i]){
    80004142:	408c                	lw	a1,0(s1)
    80004144:	dde5                	beqz	a1,8000413c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004146:	0009a503          	lw	a0,0(s3)
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	8f4080e7          	jalr	-1804(ra) # 80003a3e <bfree>
      ip->addrs[i] = 0;
    80004152:	0004a023          	sw	zero,0(s1)
    80004156:	b7dd                	j	8000413c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004158:	0809a583          	lw	a1,128(s3)
    8000415c:	e185                	bnez	a1,8000417c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000415e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004162:	854e                	mv	a0,s3
    80004164:	00000097          	auipc	ra,0x0
    80004168:	de4080e7          	jalr	-540(ra) # 80003f48 <iupdate>
}
    8000416c:	70a2                	ld	ra,40(sp)
    8000416e:	7402                	ld	s0,32(sp)
    80004170:	64e2                	ld	s1,24(sp)
    80004172:	6942                	ld	s2,16(sp)
    80004174:	69a2                	ld	s3,8(sp)
    80004176:	6a02                	ld	s4,0(sp)
    80004178:	6145                	addi	sp,sp,48
    8000417a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000417c:	0009a503          	lw	a0,0(s3)
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	678080e7          	jalr	1656(ra) # 800037f8 <bread>
    80004188:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000418a:	05850493          	addi	s1,a0,88
    8000418e:	45850913          	addi	s2,a0,1112
    80004192:	a021                	j	8000419a <itrunc+0x7a>
    80004194:	0491                	addi	s1,s1,4
    80004196:	01248b63          	beq	s1,s2,800041ac <itrunc+0x8c>
      if(a[j])
    8000419a:	408c                	lw	a1,0(s1)
    8000419c:	dde5                	beqz	a1,80004194 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000419e:	0009a503          	lw	a0,0(s3)
    800041a2:	00000097          	auipc	ra,0x0
    800041a6:	89c080e7          	jalr	-1892(ra) # 80003a3e <bfree>
    800041aa:	b7ed                	j	80004194 <itrunc+0x74>
    brelse(bp);
    800041ac:	8552                	mv	a0,s4
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	77a080e7          	jalr	1914(ra) # 80003928 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800041b6:	0809a583          	lw	a1,128(s3)
    800041ba:	0009a503          	lw	a0,0(s3)
    800041be:	00000097          	auipc	ra,0x0
    800041c2:	880080e7          	jalr	-1920(ra) # 80003a3e <bfree>
    ip->addrs[NDIRECT] = 0;
    800041c6:	0809a023          	sw	zero,128(s3)
    800041ca:	bf51                	j	8000415e <itrunc+0x3e>

00000000800041cc <iput>:
{
    800041cc:	1101                	addi	sp,sp,-32
    800041ce:	ec06                	sd	ra,24(sp)
    800041d0:	e822                	sd	s0,16(sp)
    800041d2:	e426                	sd	s1,8(sp)
    800041d4:	e04a                	sd	s2,0(sp)
    800041d6:	1000                	addi	s0,sp,32
    800041d8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800041da:	00041517          	auipc	a0,0x41
    800041de:	52e50513          	addi	a0,a0,1326 # 80045708 <itable>
    800041e2:	ffffd097          	auipc	ra,0xffffd
    800041e6:	a82080e7          	jalr	-1406(ra) # 80000c64 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041ea:	4498                	lw	a4,8(s1)
    800041ec:	4785                	li	a5,1
    800041ee:	02f70363          	beq	a4,a5,80004214 <iput+0x48>
  ip->ref--;
    800041f2:	449c                	lw	a5,8(s1)
    800041f4:	37fd                	addiw	a5,a5,-1
    800041f6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800041f8:	00041517          	auipc	a0,0x41
    800041fc:	51050513          	addi	a0,a0,1296 # 80045708 <itable>
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	b18080e7          	jalr	-1256(ra) # 80000d18 <release>
}
    80004208:	60e2                	ld	ra,24(sp)
    8000420a:	6442                	ld	s0,16(sp)
    8000420c:	64a2                	ld	s1,8(sp)
    8000420e:	6902                	ld	s2,0(sp)
    80004210:	6105                	addi	sp,sp,32
    80004212:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004214:	40bc                	lw	a5,64(s1)
    80004216:	dff1                	beqz	a5,800041f2 <iput+0x26>
    80004218:	04a49783          	lh	a5,74(s1)
    8000421c:	fbf9                	bnez	a5,800041f2 <iput+0x26>
    acquiresleep(&ip->lock);
    8000421e:	01048913          	addi	s2,s1,16
    80004222:	854a                	mv	a0,s2
    80004224:	00001097          	auipc	ra,0x1
    80004228:	aa8080e7          	jalr	-1368(ra) # 80004ccc <acquiresleep>
    release(&itable.lock);
    8000422c:	00041517          	auipc	a0,0x41
    80004230:	4dc50513          	addi	a0,a0,1244 # 80045708 <itable>
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	ae4080e7          	jalr	-1308(ra) # 80000d18 <release>
    itrunc(ip);
    8000423c:	8526                	mv	a0,s1
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	ee2080e7          	jalr	-286(ra) # 80004120 <itrunc>
    ip->type = 0;
    80004246:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000424a:	8526                	mv	a0,s1
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	cfc080e7          	jalr	-772(ra) # 80003f48 <iupdate>
    ip->valid = 0;
    80004254:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004258:	854a                	mv	a0,s2
    8000425a:	00001097          	auipc	ra,0x1
    8000425e:	ac8080e7          	jalr	-1336(ra) # 80004d22 <releasesleep>
    acquire(&itable.lock);
    80004262:	00041517          	auipc	a0,0x41
    80004266:	4a650513          	addi	a0,a0,1190 # 80045708 <itable>
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	9fa080e7          	jalr	-1542(ra) # 80000c64 <acquire>
    80004272:	b741                	j	800041f2 <iput+0x26>

0000000080004274 <iunlockput>:
{
    80004274:	1101                	addi	sp,sp,-32
    80004276:	ec06                	sd	ra,24(sp)
    80004278:	e822                	sd	s0,16(sp)
    8000427a:	e426                	sd	s1,8(sp)
    8000427c:	1000                	addi	s0,sp,32
    8000427e:	84aa                	mv	s1,a0
  iunlock(ip);
    80004280:	00000097          	auipc	ra,0x0
    80004284:	e54080e7          	jalr	-428(ra) # 800040d4 <iunlock>
  iput(ip);
    80004288:	8526                	mv	a0,s1
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	f42080e7          	jalr	-190(ra) # 800041cc <iput>
}
    80004292:	60e2                	ld	ra,24(sp)
    80004294:	6442                	ld	s0,16(sp)
    80004296:	64a2                	ld	s1,8(sp)
    80004298:	6105                	addi	sp,sp,32
    8000429a:	8082                	ret

000000008000429c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000429c:	1141                	addi	sp,sp,-16
    8000429e:	e422                	sd	s0,8(sp)
    800042a0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800042a2:	411c                	lw	a5,0(a0)
    800042a4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800042a6:	415c                	lw	a5,4(a0)
    800042a8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800042aa:	04451783          	lh	a5,68(a0)
    800042ae:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800042b2:	04a51783          	lh	a5,74(a0)
    800042b6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800042ba:	04c56783          	lwu	a5,76(a0)
    800042be:	e99c                	sd	a5,16(a1)
}
    800042c0:	6422                	ld	s0,8(sp)
    800042c2:	0141                	addi	sp,sp,16
    800042c4:	8082                	ret

00000000800042c6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042c6:	457c                	lw	a5,76(a0)
    800042c8:	0ed7e963          	bltu	a5,a3,800043ba <readi+0xf4>
{
    800042cc:	7159                	addi	sp,sp,-112
    800042ce:	f486                	sd	ra,104(sp)
    800042d0:	f0a2                	sd	s0,96(sp)
    800042d2:	eca6                	sd	s1,88(sp)
    800042d4:	e8ca                	sd	s2,80(sp)
    800042d6:	e4ce                	sd	s3,72(sp)
    800042d8:	e0d2                	sd	s4,64(sp)
    800042da:	fc56                	sd	s5,56(sp)
    800042dc:	f85a                	sd	s6,48(sp)
    800042de:	f45e                	sd	s7,40(sp)
    800042e0:	f062                	sd	s8,32(sp)
    800042e2:	ec66                	sd	s9,24(sp)
    800042e4:	e86a                	sd	s10,16(sp)
    800042e6:	e46e                	sd	s11,8(sp)
    800042e8:	1880                	addi	s0,sp,112
    800042ea:	8b2a                	mv	s6,a0
    800042ec:	8bae                	mv	s7,a1
    800042ee:	8a32                	mv	s4,a2
    800042f0:	84b6                	mv	s1,a3
    800042f2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800042f4:	9f35                	addw	a4,a4,a3
    return 0;
    800042f6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800042f8:	0ad76063          	bltu	a4,a3,80004398 <readi+0xd2>
  if(off + n > ip->size)
    800042fc:	00e7f463          	bgeu	a5,a4,80004304 <readi+0x3e>
    n = ip->size - off;
    80004300:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004304:	0a0a8963          	beqz	s5,800043b6 <readi+0xf0>
    80004308:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000430a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000430e:	5c7d                	li	s8,-1
    80004310:	a82d                	j	8000434a <readi+0x84>
    80004312:	020d1d93          	slli	s11,s10,0x20
    80004316:	020ddd93          	srli	s11,s11,0x20
    8000431a:	05890793          	addi	a5,s2,88
    8000431e:	86ee                	mv	a3,s11
    80004320:	963e                	add	a2,a2,a5
    80004322:	85d2                	mv	a1,s4
    80004324:	855e                	mv	a0,s7
    80004326:	ffffe097          	auipc	ra,0xffffe
    8000432a:	6b2080e7          	jalr	1714(ra) # 800029d8 <either_copyout>
    8000432e:	05850d63          	beq	a0,s8,80004388 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004332:	854a                	mv	a0,s2
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	5f4080e7          	jalr	1524(ra) # 80003928 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000433c:	013d09bb          	addw	s3,s10,s3
    80004340:	009d04bb          	addw	s1,s10,s1
    80004344:	9a6e                	add	s4,s4,s11
    80004346:	0559f763          	bgeu	s3,s5,80004394 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000434a:	00a4d59b          	srliw	a1,s1,0xa
    8000434e:	855a                	mv	a0,s6
    80004350:	00000097          	auipc	ra,0x0
    80004354:	8a2080e7          	jalr	-1886(ra) # 80003bf2 <bmap>
    80004358:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000435c:	cd85                	beqz	a1,80004394 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000435e:	000b2503          	lw	a0,0(s6)
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	496080e7          	jalr	1174(ra) # 800037f8 <bread>
    8000436a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000436c:	3ff4f613          	andi	a2,s1,1023
    80004370:	40cc87bb          	subw	a5,s9,a2
    80004374:	413a873b          	subw	a4,s5,s3
    80004378:	8d3e                	mv	s10,a5
    8000437a:	2781                	sext.w	a5,a5
    8000437c:	0007069b          	sext.w	a3,a4
    80004380:	f8f6f9e3          	bgeu	a3,a5,80004312 <readi+0x4c>
    80004384:	8d3a                	mv	s10,a4
    80004386:	b771                	j	80004312 <readi+0x4c>
      brelse(bp);
    80004388:	854a                	mv	a0,s2
    8000438a:	fffff097          	auipc	ra,0xfffff
    8000438e:	59e080e7          	jalr	1438(ra) # 80003928 <brelse>
      tot = -1;
    80004392:	59fd                	li	s3,-1
  }
  return tot;
    80004394:	0009851b          	sext.w	a0,s3
}
    80004398:	70a6                	ld	ra,104(sp)
    8000439a:	7406                	ld	s0,96(sp)
    8000439c:	64e6                	ld	s1,88(sp)
    8000439e:	6946                	ld	s2,80(sp)
    800043a0:	69a6                	ld	s3,72(sp)
    800043a2:	6a06                	ld	s4,64(sp)
    800043a4:	7ae2                	ld	s5,56(sp)
    800043a6:	7b42                	ld	s6,48(sp)
    800043a8:	7ba2                	ld	s7,40(sp)
    800043aa:	7c02                	ld	s8,32(sp)
    800043ac:	6ce2                	ld	s9,24(sp)
    800043ae:	6d42                	ld	s10,16(sp)
    800043b0:	6da2                	ld	s11,8(sp)
    800043b2:	6165                	addi	sp,sp,112
    800043b4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043b6:	89d6                	mv	s3,s5
    800043b8:	bff1                	j	80004394 <readi+0xce>
    return 0;
    800043ba:	4501                	li	a0,0
}
    800043bc:	8082                	ret

00000000800043be <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043be:	457c                	lw	a5,76(a0)
    800043c0:	10d7e863          	bltu	a5,a3,800044d0 <writei+0x112>
{
    800043c4:	7159                	addi	sp,sp,-112
    800043c6:	f486                	sd	ra,104(sp)
    800043c8:	f0a2                	sd	s0,96(sp)
    800043ca:	eca6                	sd	s1,88(sp)
    800043cc:	e8ca                	sd	s2,80(sp)
    800043ce:	e4ce                	sd	s3,72(sp)
    800043d0:	e0d2                	sd	s4,64(sp)
    800043d2:	fc56                	sd	s5,56(sp)
    800043d4:	f85a                	sd	s6,48(sp)
    800043d6:	f45e                	sd	s7,40(sp)
    800043d8:	f062                	sd	s8,32(sp)
    800043da:	ec66                	sd	s9,24(sp)
    800043dc:	e86a                	sd	s10,16(sp)
    800043de:	e46e                	sd	s11,8(sp)
    800043e0:	1880                	addi	s0,sp,112
    800043e2:	8aaa                	mv	s5,a0
    800043e4:	8bae                	mv	s7,a1
    800043e6:	8a32                	mv	s4,a2
    800043e8:	8936                	mv	s2,a3
    800043ea:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800043ec:	00e687bb          	addw	a5,a3,a4
    800043f0:	0ed7e263          	bltu	a5,a3,800044d4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800043f4:	00043737          	lui	a4,0x43
    800043f8:	0ef76063          	bltu	a4,a5,800044d8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043fc:	0c0b0863          	beqz	s6,800044cc <writei+0x10e>
    80004400:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004402:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004406:	5c7d                	li	s8,-1
    80004408:	a091                	j	8000444c <writei+0x8e>
    8000440a:	020d1d93          	slli	s11,s10,0x20
    8000440e:	020ddd93          	srli	s11,s11,0x20
    80004412:	05848793          	addi	a5,s1,88
    80004416:	86ee                	mv	a3,s11
    80004418:	8652                	mv	a2,s4
    8000441a:	85de                	mv	a1,s7
    8000441c:	953e                	add	a0,a0,a5
    8000441e:	ffffe097          	auipc	ra,0xffffe
    80004422:	610080e7          	jalr	1552(ra) # 80002a2e <either_copyin>
    80004426:	07850263          	beq	a0,s8,8000448a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000442a:	8526                	mv	a0,s1
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	780080e7          	jalr	1920(ra) # 80004bac <log_write>
    brelse(bp);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	4f2080e7          	jalr	1266(ra) # 80003928 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000443e:	013d09bb          	addw	s3,s10,s3
    80004442:	012d093b          	addw	s2,s10,s2
    80004446:	9a6e                	add	s4,s4,s11
    80004448:	0569f663          	bgeu	s3,s6,80004494 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000444c:	00a9559b          	srliw	a1,s2,0xa
    80004450:	8556                	mv	a0,s5
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	7a0080e7          	jalr	1952(ra) # 80003bf2 <bmap>
    8000445a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000445e:	c99d                	beqz	a1,80004494 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004460:	000aa503          	lw	a0,0(s5)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	394080e7          	jalr	916(ra) # 800037f8 <bread>
    8000446c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000446e:	3ff97513          	andi	a0,s2,1023
    80004472:	40ac87bb          	subw	a5,s9,a0
    80004476:	413b073b          	subw	a4,s6,s3
    8000447a:	8d3e                	mv	s10,a5
    8000447c:	2781                	sext.w	a5,a5
    8000447e:	0007069b          	sext.w	a3,a4
    80004482:	f8f6f4e3          	bgeu	a3,a5,8000440a <writei+0x4c>
    80004486:	8d3a                	mv	s10,a4
    80004488:	b749                	j	8000440a <writei+0x4c>
      brelse(bp);
    8000448a:	8526                	mv	a0,s1
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	49c080e7          	jalr	1180(ra) # 80003928 <brelse>
  }

  if(off > ip->size)
    80004494:	04caa783          	lw	a5,76(s5)
    80004498:	0127f463          	bgeu	a5,s2,800044a0 <writei+0xe2>
    ip->size = off;
    8000449c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800044a0:	8556                	mv	a0,s5
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	aa6080e7          	jalr	-1370(ra) # 80003f48 <iupdate>

  return tot;
    800044aa:	0009851b          	sext.w	a0,s3
}
    800044ae:	70a6                	ld	ra,104(sp)
    800044b0:	7406                	ld	s0,96(sp)
    800044b2:	64e6                	ld	s1,88(sp)
    800044b4:	6946                	ld	s2,80(sp)
    800044b6:	69a6                	ld	s3,72(sp)
    800044b8:	6a06                	ld	s4,64(sp)
    800044ba:	7ae2                	ld	s5,56(sp)
    800044bc:	7b42                	ld	s6,48(sp)
    800044be:	7ba2                	ld	s7,40(sp)
    800044c0:	7c02                	ld	s8,32(sp)
    800044c2:	6ce2                	ld	s9,24(sp)
    800044c4:	6d42                	ld	s10,16(sp)
    800044c6:	6da2                	ld	s11,8(sp)
    800044c8:	6165                	addi	sp,sp,112
    800044ca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800044cc:	89da                	mv	s3,s6
    800044ce:	bfc9                	j	800044a0 <writei+0xe2>
    return -1;
    800044d0:	557d                	li	a0,-1
}
    800044d2:	8082                	ret
    return -1;
    800044d4:	557d                	li	a0,-1
    800044d6:	bfe1                	j	800044ae <writei+0xf0>
    return -1;
    800044d8:	557d                	li	a0,-1
    800044da:	bfd1                	j	800044ae <writei+0xf0>

00000000800044dc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800044dc:	1141                	addi	sp,sp,-16
    800044de:	e406                	sd	ra,8(sp)
    800044e0:	e022                	sd	s0,0(sp)
    800044e2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800044e4:	4639                	li	a2,14
    800044e6:	ffffd097          	auipc	ra,0xffffd
    800044ea:	94a080e7          	jalr	-1718(ra) # 80000e30 <strncmp>
}
    800044ee:	60a2                	ld	ra,8(sp)
    800044f0:	6402                	ld	s0,0(sp)
    800044f2:	0141                	addi	sp,sp,16
    800044f4:	8082                	ret

00000000800044f6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800044f6:	7139                	addi	sp,sp,-64
    800044f8:	fc06                	sd	ra,56(sp)
    800044fa:	f822                	sd	s0,48(sp)
    800044fc:	f426                	sd	s1,40(sp)
    800044fe:	f04a                	sd	s2,32(sp)
    80004500:	ec4e                	sd	s3,24(sp)
    80004502:	e852                	sd	s4,16(sp)
    80004504:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004506:	04451703          	lh	a4,68(a0)
    8000450a:	4785                	li	a5,1
    8000450c:	00f71a63          	bne	a4,a5,80004520 <dirlookup+0x2a>
    80004510:	892a                	mv	s2,a0
    80004512:	89ae                	mv	s3,a1
    80004514:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004516:	457c                	lw	a5,76(a0)
    80004518:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000451a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000451c:	e79d                	bnez	a5,8000454a <dirlookup+0x54>
    8000451e:	a8a5                	j	80004596 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004520:	00004517          	auipc	a0,0x4
    80004524:	23050513          	addi	a0,a0,560 # 80008750 <syscalls+0x1d0>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	016080e7          	jalr	22(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004530:	00004517          	auipc	a0,0x4
    80004534:	23850513          	addi	a0,a0,568 # 80008768 <syscalls+0x1e8>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	006080e7          	jalr	6(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004540:	24c1                	addiw	s1,s1,16
    80004542:	04c92783          	lw	a5,76(s2)
    80004546:	04f4f763          	bgeu	s1,a5,80004594 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000454a:	4741                	li	a4,16
    8000454c:	86a6                	mv	a3,s1
    8000454e:	fc040613          	addi	a2,s0,-64
    80004552:	4581                	li	a1,0
    80004554:	854a                	mv	a0,s2
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	d70080e7          	jalr	-656(ra) # 800042c6 <readi>
    8000455e:	47c1                	li	a5,16
    80004560:	fcf518e3          	bne	a0,a5,80004530 <dirlookup+0x3a>
    if(de.inum == 0)
    80004564:	fc045783          	lhu	a5,-64(s0)
    80004568:	dfe1                	beqz	a5,80004540 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000456a:	fc240593          	addi	a1,s0,-62
    8000456e:	854e                	mv	a0,s3
    80004570:	00000097          	auipc	ra,0x0
    80004574:	f6c080e7          	jalr	-148(ra) # 800044dc <namecmp>
    80004578:	f561                	bnez	a0,80004540 <dirlookup+0x4a>
      if(poff)
    8000457a:	000a0463          	beqz	s4,80004582 <dirlookup+0x8c>
        *poff = off;
    8000457e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004582:	fc045583          	lhu	a1,-64(s0)
    80004586:	00092503          	lw	a0,0(s2)
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	750080e7          	jalr	1872(ra) # 80003cda <iget>
    80004592:	a011                	j	80004596 <dirlookup+0xa0>
  return 0;
    80004594:	4501                	li	a0,0
}
    80004596:	70e2                	ld	ra,56(sp)
    80004598:	7442                	ld	s0,48(sp)
    8000459a:	74a2                	ld	s1,40(sp)
    8000459c:	7902                	ld	s2,32(sp)
    8000459e:	69e2                	ld	s3,24(sp)
    800045a0:	6a42                	ld	s4,16(sp)
    800045a2:	6121                	addi	sp,sp,64
    800045a4:	8082                	ret

00000000800045a6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800045a6:	711d                	addi	sp,sp,-96
    800045a8:	ec86                	sd	ra,88(sp)
    800045aa:	e8a2                	sd	s0,80(sp)
    800045ac:	e4a6                	sd	s1,72(sp)
    800045ae:	e0ca                	sd	s2,64(sp)
    800045b0:	fc4e                	sd	s3,56(sp)
    800045b2:	f852                	sd	s4,48(sp)
    800045b4:	f456                	sd	s5,40(sp)
    800045b6:	f05a                	sd	s6,32(sp)
    800045b8:	ec5e                	sd	s7,24(sp)
    800045ba:	e862                	sd	s8,16(sp)
    800045bc:	e466                	sd	s9,8(sp)
    800045be:	1080                	addi	s0,sp,96
    800045c0:	84aa                	mv	s1,a0
    800045c2:	8aae                	mv	s5,a1
    800045c4:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800045c6:	00054703          	lbu	a4,0(a0)
    800045ca:	02f00793          	li	a5,47
    800045ce:	02f70363          	beq	a4,a5,800045f4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800045d2:	ffffd097          	auipc	ra,0xffffd
    800045d6:	526080e7          	jalr	1318(ra) # 80001af8 <myproc>
    800045da:	15053503          	ld	a0,336(a0)
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	9f6080e7          	jalr	-1546(ra) # 80003fd4 <idup>
    800045e6:	89aa                	mv	s3,a0
  while(*path == '/')
    800045e8:	02f00913          	li	s2,47
  len = path - s;
    800045ec:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800045ee:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800045f0:	4b85                	li	s7,1
    800045f2:	a865                	j	800046aa <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800045f4:	4585                	li	a1,1
    800045f6:	4505                	li	a0,1
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	6e2080e7          	jalr	1762(ra) # 80003cda <iget>
    80004600:	89aa                	mv	s3,a0
    80004602:	b7dd                	j	800045e8 <namex+0x42>
      iunlockput(ip);
    80004604:	854e                	mv	a0,s3
    80004606:	00000097          	auipc	ra,0x0
    8000460a:	c6e080e7          	jalr	-914(ra) # 80004274 <iunlockput>
      return 0;
    8000460e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004610:	854e                	mv	a0,s3
    80004612:	60e6                	ld	ra,88(sp)
    80004614:	6446                	ld	s0,80(sp)
    80004616:	64a6                	ld	s1,72(sp)
    80004618:	6906                	ld	s2,64(sp)
    8000461a:	79e2                	ld	s3,56(sp)
    8000461c:	7a42                	ld	s4,48(sp)
    8000461e:	7aa2                	ld	s5,40(sp)
    80004620:	7b02                	ld	s6,32(sp)
    80004622:	6be2                	ld	s7,24(sp)
    80004624:	6c42                	ld	s8,16(sp)
    80004626:	6ca2                	ld	s9,8(sp)
    80004628:	6125                	addi	sp,sp,96
    8000462a:	8082                	ret
      iunlock(ip);
    8000462c:	854e                	mv	a0,s3
    8000462e:	00000097          	auipc	ra,0x0
    80004632:	aa6080e7          	jalr	-1370(ra) # 800040d4 <iunlock>
      return ip;
    80004636:	bfe9                	j	80004610 <namex+0x6a>
      iunlockput(ip);
    80004638:	854e                	mv	a0,s3
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	c3a080e7          	jalr	-966(ra) # 80004274 <iunlockput>
      return 0;
    80004642:	89e6                	mv	s3,s9
    80004644:	b7f1                	j	80004610 <namex+0x6a>
  len = path - s;
    80004646:	40b48633          	sub	a2,s1,a1
    8000464a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000464e:	099c5463          	bge	s8,s9,800046d6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004652:	4639                	li	a2,14
    80004654:	8552                	mv	a0,s4
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	766080e7          	jalr	1894(ra) # 80000dbc <memmove>
  while(*path == '/')
    8000465e:	0004c783          	lbu	a5,0(s1)
    80004662:	01279763          	bne	a5,s2,80004670 <namex+0xca>
    path++;
    80004666:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004668:	0004c783          	lbu	a5,0(s1)
    8000466c:	ff278de3          	beq	a5,s2,80004666 <namex+0xc0>
    ilock(ip);
    80004670:	854e                	mv	a0,s3
    80004672:	00000097          	auipc	ra,0x0
    80004676:	9a0080e7          	jalr	-1632(ra) # 80004012 <ilock>
    if(ip->type != T_DIR){
    8000467a:	04499783          	lh	a5,68(s3)
    8000467e:	f97793e3          	bne	a5,s7,80004604 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004682:	000a8563          	beqz	s5,8000468c <namex+0xe6>
    80004686:	0004c783          	lbu	a5,0(s1)
    8000468a:	d3cd                	beqz	a5,8000462c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000468c:	865a                	mv	a2,s6
    8000468e:	85d2                	mv	a1,s4
    80004690:	854e                	mv	a0,s3
    80004692:	00000097          	auipc	ra,0x0
    80004696:	e64080e7          	jalr	-412(ra) # 800044f6 <dirlookup>
    8000469a:	8caa                	mv	s9,a0
    8000469c:	dd51                	beqz	a0,80004638 <namex+0x92>
    iunlockput(ip);
    8000469e:	854e                	mv	a0,s3
    800046a0:	00000097          	auipc	ra,0x0
    800046a4:	bd4080e7          	jalr	-1068(ra) # 80004274 <iunlockput>
    ip = next;
    800046a8:	89e6                	mv	s3,s9
  while(*path == '/')
    800046aa:	0004c783          	lbu	a5,0(s1)
    800046ae:	05279763          	bne	a5,s2,800046fc <namex+0x156>
    path++;
    800046b2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046b4:	0004c783          	lbu	a5,0(s1)
    800046b8:	ff278de3          	beq	a5,s2,800046b2 <namex+0x10c>
  if(*path == 0)
    800046bc:	c79d                	beqz	a5,800046ea <namex+0x144>
    path++;
    800046be:	85a6                	mv	a1,s1
  len = path - s;
    800046c0:	8cda                	mv	s9,s6
    800046c2:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800046c4:	01278963          	beq	a5,s2,800046d6 <namex+0x130>
    800046c8:	dfbd                	beqz	a5,80004646 <namex+0xa0>
    path++;
    800046ca:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800046cc:	0004c783          	lbu	a5,0(s1)
    800046d0:	ff279ce3          	bne	a5,s2,800046c8 <namex+0x122>
    800046d4:	bf8d                	j	80004646 <namex+0xa0>
    memmove(name, s, len);
    800046d6:	2601                	sext.w	a2,a2
    800046d8:	8552                	mv	a0,s4
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	6e2080e7          	jalr	1762(ra) # 80000dbc <memmove>
    name[len] = 0;
    800046e2:	9cd2                	add	s9,s9,s4
    800046e4:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800046e8:	bf9d                	j	8000465e <namex+0xb8>
  if(nameiparent){
    800046ea:	f20a83e3          	beqz	s5,80004610 <namex+0x6a>
    iput(ip);
    800046ee:	854e                	mv	a0,s3
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	adc080e7          	jalr	-1316(ra) # 800041cc <iput>
    return 0;
    800046f8:	4981                	li	s3,0
    800046fa:	bf19                	j	80004610 <namex+0x6a>
  if(*path == 0)
    800046fc:	d7fd                	beqz	a5,800046ea <namex+0x144>
  while(*path != '/' && *path != 0)
    800046fe:	0004c783          	lbu	a5,0(s1)
    80004702:	85a6                	mv	a1,s1
    80004704:	b7d1                	j	800046c8 <namex+0x122>

0000000080004706 <dirlink>:
{
    80004706:	7139                	addi	sp,sp,-64
    80004708:	fc06                	sd	ra,56(sp)
    8000470a:	f822                	sd	s0,48(sp)
    8000470c:	f426                	sd	s1,40(sp)
    8000470e:	f04a                	sd	s2,32(sp)
    80004710:	ec4e                	sd	s3,24(sp)
    80004712:	e852                	sd	s4,16(sp)
    80004714:	0080                	addi	s0,sp,64
    80004716:	892a                	mv	s2,a0
    80004718:	8a2e                	mv	s4,a1
    8000471a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000471c:	4601                	li	a2,0
    8000471e:	00000097          	auipc	ra,0x0
    80004722:	dd8080e7          	jalr	-552(ra) # 800044f6 <dirlookup>
    80004726:	e93d                	bnez	a0,8000479c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004728:	04c92483          	lw	s1,76(s2)
    8000472c:	c49d                	beqz	s1,8000475a <dirlink+0x54>
    8000472e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004730:	4741                	li	a4,16
    80004732:	86a6                	mv	a3,s1
    80004734:	fc040613          	addi	a2,s0,-64
    80004738:	4581                	li	a1,0
    8000473a:	854a                	mv	a0,s2
    8000473c:	00000097          	auipc	ra,0x0
    80004740:	b8a080e7          	jalr	-1142(ra) # 800042c6 <readi>
    80004744:	47c1                	li	a5,16
    80004746:	06f51163          	bne	a0,a5,800047a8 <dirlink+0xa2>
    if(de.inum == 0)
    8000474a:	fc045783          	lhu	a5,-64(s0)
    8000474e:	c791                	beqz	a5,8000475a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004750:	24c1                	addiw	s1,s1,16
    80004752:	04c92783          	lw	a5,76(s2)
    80004756:	fcf4ede3          	bltu	s1,a5,80004730 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000475a:	4639                	li	a2,14
    8000475c:	85d2                	mv	a1,s4
    8000475e:	fc240513          	addi	a0,s0,-62
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	70a080e7          	jalr	1802(ra) # 80000e6c <strncpy>
  de.inum = inum;
    8000476a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000476e:	4741                	li	a4,16
    80004770:	86a6                	mv	a3,s1
    80004772:	fc040613          	addi	a2,s0,-64
    80004776:	4581                	li	a1,0
    80004778:	854a                	mv	a0,s2
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	c44080e7          	jalr	-956(ra) # 800043be <writei>
    80004782:	1541                	addi	a0,a0,-16
    80004784:	00a03533          	snez	a0,a0
    80004788:	40a00533          	neg	a0,a0
}
    8000478c:	70e2                	ld	ra,56(sp)
    8000478e:	7442                	ld	s0,48(sp)
    80004790:	74a2                	ld	s1,40(sp)
    80004792:	7902                	ld	s2,32(sp)
    80004794:	69e2                	ld	s3,24(sp)
    80004796:	6a42                	ld	s4,16(sp)
    80004798:	6121                	addi	sp,sp,64
    8000479a:	8082                	ret
    iput(ip);
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	a30080e7          	jalr	-1488(ra) # 800041cc <iput>
    return -1;
    800047a4:	557d                	li	a0,-1
    800047a6:	b7dd                	j	8000478c <dirlink+0x86>
      panic("dirlink read");
    800047a8:	00004517          	auipc	a0,0x4
    800047ac:	fd050513          	addi	a0,a0,-48 # 80008778 <syscalls+0x1f8>
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	d8e080e7          	jalr	-626(ra) # 8000053e <panic>

00000000800047b8 <namei>:

struct inode*
namei(char *path)
{
    800047b8:	1101                	addi	sp,sp,-32
    800047ba:	ec06                	sd	ra,24(sp)
    800047bc:	e822                	sd	s0,16(sp)
    800047be:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800047c0:	fe040613          	addi	a2,s0,-32
    800047c4:	4581                	li	a1,0
    800047c6:	00000097          	auipc	ra,0x0
    800047ca:	de0080e7          	jalr	-544(ra) # 800045a6 <namex>
}
    800047ce:	60e2                	ld	ra,24(sp)
    800047d0:	6442                	ld	s0,16(sp)
    800047d2:	6105                	addi	sp,sp,32
    800047d4:	8082                	ret

00000000800047d6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800047d6:	1141                	addi	sp,sp,-16
    800047d8:	e406                	sd	ra,8(sp)
    800047da:	e022                	sd	s0,0(sp)
    800047dc:	0800                	addi	s0,sp,16
    800047de:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800047e0:	4585                	li	a1,1
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	dc4080e7          	jalr	-572(ra) # 800045a6 <namex>
}
    800047ea:	60a2                	ld	ra,8(sp)
    800047ec:	6402                	ld	s0,0(sp)
    800047ee:	0141                	addi	sp,sp,16
    800047f0:	8082                	ret

00000000800047f2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800047f2:	1101                	addi	sp,sp,-32
    800047f4:	ec06                	sd	ra,24(sp)
    800047f6:	e822                	sd	s0,16(sp)
    800047f8:	e426                	sd	s1,8(sp)
    800047fa:	e04a                	sd	s2,0(sp)
    800047fc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800047fe:	00043917          	auipc	s2,0x43
    80004802:	9b290913          	addi	s2,s2,-1614 # 800471b0 <log>
    80004806:	01892583          	lw	a1,24(s2)
    8000480a:	02892503          	lw	a0,40(s2)
    8000480e:	fffff097          	auipc	ra,0xfffff
    80004812:	fea080e7          	jalr	-22(ra) # 800037f8 <bread>
    80004816:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004818:	02c92683          	lw	a3,44(s2)
    8000481c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000481e:	02d05763          	blez	a3,8000484c <write_head+0x5a>
    80004822:	00043797          	auipc	a5,0x43
    80004826:	9be78793          	addi	a5,a5,-1602 # 800471e0 <log+0x30>
    8000482a:	05c50713          	addi	a4,a0,92
    8000482e:	36fd                	addiw	a3,a3,-1
    80004830:	1682                	slli	a3,a3,0x20
    80004832:	9281                	srli	a3,a3,0x20
    80004834:	068a                	slli	a3,a3,0x2
    80004836:	00043617          	auipc	a2,0x43
    8000483a:	9ae60613          	addi	a2,a2,-1618 # 800471e4 <log+0x34>
    8000483e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004840:	4390                	lw	a2,0(a5)
    80004842:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004844:	0791                	addi	a5,a5,4
    80004846:	0711                	addi	a4,a4,4
    80004848:	fed79ce3          	bne	a5,a3,80004840 <write_head+0x4e>
  }
  bwrite(buf);
    8000484c:	8526                	mv	a0,s1
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	09c080e7          	jalr	156(ra) # 800038ea <bwrite>
  brelse(buf);
    80004856:	8526                	mv	a0,s1
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	0d0080e7          	jalr	208(ra) # 80003928 <brelse>
}
    80004860:	60e2                	ld	ra,24(sp)
    80004862:	6442                	ld	s0,16(sp)
    80004864:	64a2                	ld	s1,8(sp)
    80004866:	6902                	ld	s2,0(sp)
    80004868:	6105                	addi	sp,sp,32
    8000486a:	8082                	ret

000000008000486c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000486c:	00043797          	auipc	a5,0x43
    80004870:	9707a783          	lw	a5,-1680(a5) # 800471dc <log+0x2c>
    80004874:	0af05d63          	blez	a5,8000492e <install_trans+0xc2>
{
    80004878:	7139                	addi	sp,sp,-64
    8000487a:	fc06                	sd	ra,56(sp)
    8000487c:	f822                	sd	s0,48(sp)
    8000487e:	f426                	sd	s1,40(sp)
    80004880:	f04a                	sd	s2,32(sp)
    80004882:	ec4e                	sd	s3,24(sp)
    80004884:	e852                	sd	s4,16(sp)
    80004886:	e456                	sd	s5,8(sp)
    80004888:	e05a                	sd	s6,0(sp)
    8000488a:	0080                	addi	s0,sp,64
    8000488c:	8b2a                	mv	s6,a0
    8000488e:	00043a97          	auipc	s5,0x43
    80004892:	952a8a93          	addi	s5,s5,-1710 # 800471e0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004896:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004898:	00043997          	auipc	s3,0x43
    8000489c:	91898993          	addi	s3,s3,-1768 # 800471b0 <log>
    800048a0:	a00d                	j	800048c2 <install_trans+0x56>
    brelse(lbuf);
    800048a2:	854a                	mv	a0,s2
    800048a4:	fffff097          	auipc	ra,0xfffff
    800048a8:	084080e7          	jalr	132(ra) # 80003928 <brelse>
    brelse(dbuf);
    800048ac:	8526                	mv	a0,s1
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	07a080e7          	jalr	122(ra) # 80003928 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048b6:	2a05                	addiw	s4,s4,1
    800048b8:	0a91                	addi	s5,s5,4
    800048ba:	02c9a783          	lw	a5,44(s3)
    800048be:	04fa5e63          	bge	s4,a5,8000491a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048c2:	0189a583          	lw	a1,24(s3)
    800048c6:	014585bb          	addw	a1,a1,s4
    800048ca:	2585                	addiw	a1,a1,1
    800048cc:	0289a503          	lw	a0,40(s3)
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	f28080e7          	jalr	-216(ra) # 800037f8 <bread>
    800048d8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800048da:	000aa583          	lw	a1,0(s5)
    800048de:	0289a503          	lw	a0,40(s3)
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	f16080e7          	jalr	-234(ra) # 800037f8 <bread>
    800048ea:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800048ec:	40000613          	li	a2,1024
    800048f0:	05890593          	addi	a1,s2,88
    800048f4:	05850513          	addi	a0,a0,88
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	4c4080e7          	jalr	1220(ra) # 80000dbc <memmove>
    bwrite(dbuf);  // write dst to disk
    80004900:	8526                	mv	a0,s1
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	fe8080e7          	jalr	-24(ra) # 800038ea <bwrite>
    if(recovering == 0)
    8000490a:	f80b1ce3          	bnez	s6,800048a2 <install_trans+0x36>
      bunpin(dbuf);
    8000490e:	8526                	mv	a0,s1
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	0f2080e7          	jalr	242(ra) # 80003a02 <bunpin>
    80004918:	b769                	j	800048a2 <install_trans+0x36>
}
    8000491a:	70e2                	ld	ra,56(sp)
    8000491c:	7442                	ld	s0,48(sp)
    8000491e:	74a2                	ld	s1,40(sp)
    80004920:	7902                	ld	s2,32(sp)
    80004922:	69e2                	ld	s3,24(sp)
    80004924:	6a42                	ld	s4,16(sp)
    80004926:	6aa2                	ld	s5,8(sp)
    80004928:	6b02                	ld	s6,0(sp)
    8000492a:	6121                	addi	sp,sp,64
    8000492c:	8082                	ret
    8000492e:	8082                	ret

0000000080004930 <initlog>:
{
    80004930:	7179                	addi	sp,sp,-48
    80004932:	f406                	sd	ra,40(sp)
    80004934:	f022                	sd	s0,32(sp)
    80004936:	ec26                	sd	s1,24(sp)
    80004938:	e84a                	sd	s2,16(sp)
    8000493a:	e44e                	sd	s3,8(sp)
    8000493c:	1800                	addi	s0,sp,48
    8000493e:	892a                	mv	s2,a0
    80004940:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004942:	00043497          	auipc	s1,0x43
    80004946:	86e48493          	addi	s1,s1,-1938 # 800471b0 <log>
    8000494a:	00004597          	auipc	a1,0x4
    8000494e:	e3e58593          	addi	a1,a1,-450 # 80008788 <syscalls+0x208>
    80004952:	8526                	mv	a0,s1
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	280080e7          	jalr	640(ra) # 80000bd4 <initlock>
  log.start = sb->logstart;
    8000495c:	0149a583          	lw	a1,20(s3)
    80004960:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004962:	0109a783          	lw	a5,16(s3)
    80004966:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004968:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000496c:	854a                	mv	a0,s2
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	e8a080e7          	jalr	-374(ra) # 800037f8 <bread>
  log.lh.n = lh->n;
    80004976:	4d34                	lw	a3,88(a0)
    80004978:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000497a:	02d05563          	blez	a3,800049a4 <initlog+0x74>
    8000497e:	05c50793          	addi	a5,a0,92
    80004982:	00043717          	auipc	a4,0x43
    80004986:	85e70713          	addi	a4,a4,-1954 # 800471e0 <log+0x30>
    8000498a:	36fd                	addiw	a3,a3,-1
    8000498c:	1682                	slli	a3,a3,0x20
    8000498e:	9281                	srli	a3,a3,0x20
    80004990:	068a                	slli	a3,a3,0x2
    80004992:	06050613          	addi	a2,a0,96
    80004996:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004998:	4390                	lw	a2,0(a5)
    8000499a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000499c:	0791                	addi	a5,a5,4
    8000499e:	0711                	addi	a4,a4,4
    800049a0:	fed79ce3          	bne	a5,a3,80004998 <initlog+0x68>
  brelse(buf);
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	f84080e7          	jalr	-124(ra) # 80003928 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800049ac:	4505                	li	a0,1
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	ebe080e7          	jalr	-322(ra) # 8000486c <install_trans>
  log.lh.n = 0;
    800049b6:	00043797          	auipc	a5,0x43
    800049ba:	8207a323          	sw	zero,-2010(a5) # 800471dc <log+0x2c>
  write_head(); // clear the log
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	e34080e7          	jalr	-460(ra) # 800047f2 <write_head>
}
    800049c6:	70a2                	ld	ra,40(sp)
    800049c8:	7402                	ld	s0,32(sp)
    800049ca:	64e2                	ld	s1,24(sp)
    800049cc:	6942                	ld	s2,16(sp)
    800049ce:	69a2                	ld	s3,8(sp)
    800049d0:	6145                	addi	sp,sp,48
    800049d2:	8082                	ret

00000000800049d4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800049d4:	1101                	addi	sp,sp,-32
    800049d6:	ec06                	sd	ra,24(sp)
    800049d8:	e822                	sd	s0,16(sp)
    800049da:	e426                	sd	s1,8(sp)
    800049dc:	e04a                	sd	s2,0(sp)
    800049de:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800049e0:	00042517          	auipc	a0,0x42
    800049e4:	7d050513          	addi	a0,a0,2000 # 800471b0 <log>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	27c080e7          	jalr	636(ra) # 80000c64 <acquire>
  while(1){
    if(log.committing){
    800049f0:	00042497          	auipc	s1,0x42
    800049f4:	7c048493          	addi	s1,s1,1984 # 800471b0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049f8:	4979                	li	s2,30
    800049fa:	a039                	j	80004a08 <begin_op+0x34>
      sleep(&log, &log.lock);
    800049fc:	85a6                	mv	a1,s1
    800049fe:	8526                	mv	a0,s1
    80004a00:	ffffe097          	auipc	ra,0xffffe
    80004a04:	a78080e7          	jalr	-1416(ra) # 80002478 <sleep>
    if(log.committing){
    80004a08:	50dc                	lw	a5,36(s1)
    80004a0a:	fbed                	bnez	a5,800049fc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a0c:	509c                	lw	a5,32(s1)
    80004a0e:	0017871b          	addiw	a4,a5,1
    80004a12:	0007069b          	sext.w	a3,a4
    80004a16:	0027179b          	slliw	a5,a4,0x2
    80004a1a:	9fb9                	addw	a5,a5,a4
    80004a1c:	0017979b          	slliw	a5,a5,0x1
    80004a20:	54d8                	lw	a4,44(s1)
    80004a22:	9fb9                	addw	a5,a5,a4
    80004a24:	00f95963          	bge	s2,a5,80004a36 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a28:	85a6                	mv	a1,s1
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	ffffe097          	auipc	ra,0xffffe
    80004a30:	a4c080e7          	jalr	-1460(ra) # 80002478 <sleep>
    80004a34:	bfd1                	j	80004a08 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a36:	00042517          	auipc	a0,0x42
    80004a3a:	77a50513          	addi	a0,a0,1914 # 800471b0 <log>
    80004a3e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	2d8080e7          	jalr	728(ra) # 80000d18 <release>
      break;
    }
  }
}
    80004a48:	60e2                	ld	ra,24(sp)
    80004a4a:	6442                	ld	s0,16(sp)
    80004a4c:	64a2                	ld	s1,8(sp)
    80004a4e:	6902                	ld	s2,0(sp)
    80004a50:	6105                	addi	sp,sp,32
    80004a52:	8082                	ret

0000000080004a54 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a54:	7139                	addi	sp,sp,-64
    80004a56:	fc06                	sd	ra,56(sp)
    80004a58:	f822                	sd	s0,48(sp)
    80004a5a:	f426                	sd	s1,40(sp)
    80004a5c:	f04a                	sd	s2,32(sp)
    80004a5e:	ec4e                	sd	s3,24(sp)
    80004a60:	e852                	sd	s4,16(sp)
    80004a62:	e456                	sd	s5,8(sp)
    80004a64:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a66:	00042497          	auipc	s1,0x42
    80004a6a:	74a48493          	addi	s1,s1,1866 # 800471b0 <log>
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	1f4080e7          	jalr	500(ra) # 80000c64 <acquire>
  log.outstanding -= 1;
    80004a78:	509c                	lw	a5,32(s1)
    80004a7a:	37fd                	addiw	a5,a5,-1
    80004a7c:	0007891b          	sext.w	s2,a5
    80004a80:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a82:	50dc                	lw	a5,36(s1)
    80004a84:	e7b9                	bnez	a5,80004ad2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a86:	04091e63          	bnez	s2,80004ae2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004a8a:	00042497          	auipc	s1,0x42
    80004a8e:	72648493          	addi	s1,s1,1830 # 800471b0 <log>
    80004a92:	4785                	li	a5,1
    80004a94:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	280080e7          	jalr	640(ra) # 80000d18 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004aa0:	54dc                	lw	a5,44(s1)
    80004aa2:	06f04763          	bgtz	a5,80004b10 <end_op+0xbc>
    acquire(&log.lock);
    80004aa6:	00042497          	auipc	s1,0x42
    80004aaa:	70a48493          	addi	s1,s1,1802 # 800471b0 <log>
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1b4080e7          	jalr	436(ra) # 80000c64 <acquire>
    log.committing = 0;
    80004ab8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffe097          	auipc	ra,0xffffe
    80004ac2:	b6a080e7          	jalr	-1174(ra) # 80002628 <wakeup>
    release(&log.lock);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	250080e7          	jalr	592(ra) # 80000d18 <release>
}
    80004ad0:	a03d                	j	80004afe <end_op+0xaa>
    panic("log.committing");
    80004ad2:	00004517          	auipc	a0,0x4
    80004ad6:	cbe50513          	addi	a0,a0,-834 # 80008790 <syscalls+0x210>
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	a64080e7          	jalr	-1436(ra) # 8000053e <panic>
    wakeup(&log);
    80004ae2:	00042497          	auipc	s1,0x42
    80004ae6:	6ce48493          	addi	s1,s1,1742 # 800471b0 <log>
    80004aea:	8526                	mv	a0,s1
    80004aec:	ffffe097          	auipc	ra,0xffffe
    80004af0:	b3c080e7          	jalr	-1220(ra) # 80002628 <wakeup>
  release(&log.lock);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	222080e7          	jalr	546(ra) # 80000d18 <release>
}
    80004afe:	70e2                	ld	ra,56(sp)
    80004b00:	7442                	ld	s0,48(sp)
    80004b02:	74a2                	ld	s1,40(sp)
    80004b04:	7902                	ld	s2,32(sp)
    80004b06:	69e2                	ld	s3,24(sp)
    80004b08:	6a42                	ld	s4,16(sp)
    80004b0a:	6aa2                	ld	s5,8(sp)
    80004b0c:	6121                	addi	sp,sp,64
    80004b0e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b10:	00042a97          	auipc	s5,0x42
    80004b14:	6d0a8a93          	addi	s5,s5,1744 # 800471e0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b18:	00042a17          	auipc	s4,0x42
    80004b1c:	698a0a13          	addi	s4,s4,1688 # 800471b0 <log>
    80004b20:	018a2583          	lw	a1,24(s4)
    80004b24:	012585bb          	addw	a1,a1,s2
    80004b28:	2585                	addiw	a1,a1,1
    80004b2a:	028a2503          	lw	a0,40(s4)
    80004b2e:	fffff097          	auipc	ra,0xfffff
    80004b32:	cca080e7          	jalr	-822(ra) # 800037f8 <bread>
    80004b36:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b38:	000aa583          	lw	a1,0(s5)
    80004b3c:	028a2503          	lw	a0,40(s4)
    80004b40:	fffff097          	auipc	ra,0xfffff
    80004b44:	cb8080e7          	jalr	-840(ra) # 800037f8 <bread>
    80004b48:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b4a:	40000613          	li	a2,1024
    80004b4e:	05850593          	addi	a1,a0,88
    80004b52:	05848513          	addi	a0,s1,88
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	266080e7          	jalr	614(ra) # 80000dbc <memmove>
    bwrite(to);  // write the log
    80004b5e:	8526                	mv	a0,s1
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	d8a080e7          	jalr	-630(ra) # 800038ea <bwrite>
    brelse(from);
    80004b68:	854e                	mv	a0,s3
    80004b6a:	fffff097          	auipc	ra,0xfffff
    80004b6e:	dbe080e7          	jalr	-578(ra) # 80003928 <brelse>
    brelse(to);
    80004b72:	8526                	mv	a0,s1
    80004b74:	fffff097          	auipc	ra,0xfffff
    80004b78:	db4080e7          	jalr	-588(ra) # 80003928 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b7c:	2905                	addiw	s2,s2,1
    80004b7e:	0a91                	addi	s5,s5,4
    80004b80:	02ca2783          	lw	a5,44(s4)
    80004b84:	f8f94ee3          	blt	s2,a5,80004b20 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	c6a080e7          	jalr	-918(ra) # 800047f2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004b90:	4501                	li	a0,0
    80004b92:	00000097          	auipc	ra,0x0
    80004b96:	cda080e7          	jalr	-806(ra) # 8000486c <install_trans>
    log.lh.n = 0;
    80004b9a:	00042797          	auipc	a5,0x42
    80004b9e:	6407a123          	sw	zero,1602(a5) # 800471dc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ba2:	00000097          	auipc	ra,0x0
    80004ba6:	c50080e7          	jalr	-944(ra) # 800047f2 <write_head>
    80004baa:	bdf5                	j	80004aa6 <end_op+0x52>

0000000080004bac <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004bac:	1101                	addi	sp,sp,-32
    80004bae:	ec06                	sd	ra,24(sp)
    80004bb0:	e822                	sd	s0,16(sp)
    80004bb2:	e426                	sd	s1,8(sp)
    80004bb4:	e04a                	sd	s2,0(sp)
    80004bb6:	1000                	addi	s0,sp,32
    80004bb8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004bba:	00042917          	auipc	s2,0x42
    80004bbe:	5f690913          	addi	s2,s2,1526 # 800471b0 <log>
    80004bc2:	854a                	mv	a0,s2
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	0a0080e7          	jalr	160(ra) # 80000c64 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004bcc:	02c92603          	lw	a2,44(s2)
    80004bd0:	47f5                	li	a5,29
    80004bd2:	06c7c563          	blt	a5,a2,80004c3c <log_write+0x90>
    80004bd6:	00042797          	auipc	a5,0x42
    80004bda:	5f67a783          	lw	a5,1526(a5) # 800471cc <log+0x1c>
    80004bde:	37fd                	addiw	a5,a5,-1
    80004be0:	04f65e63          	bge	a2,a5,80004c3c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004be4:	00042797          	auipc	a5,0x42
    80004be8:	5ec7a783          	lw	a5,1516(a5) # 800471d0 <log+0x20>
    80004bec:	06f05063          	blez	a5,80004c4c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004bf0:	4781                	li	a5,0
    80004bf2:	06c05563          	blez	a2,80004c5c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004bf6:	44cc                	lw	a1,12(s1)
    80004bf8:	00042717          	auipc	a4,0x42
    80004bfc:	5e870713          	addi	a4,a4,1512 # 800471e0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c00:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c02:	4314                	lw	a3,0(a4)
    80004c04:	04b68c63          	beq	a3,a1,80004c5c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c08:	2785                	addiw	a5,a5,1
    80004c0a:	0711                	addi	a4,a4,4
    80004c0c:	fef61be3          	bne	a2,a5,80004c02 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c10:	0621                	addi	a2,a2,8
    80004c12:	060a                	slli	a2,a2,0x2
    80004c14:	00042797          	auipc	a5,0x42
    80004c18:	59c78793          	addi	a5,a5,1436 # 800471b0 <log>
    80004c1c:	963e                	add	a2,a2,a5
    80004c1e:	44dc                	lw	a5,12(s1)
    80004c20:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c22:	8526                	mv	a0,s1
    80004c24:	fffff097          	auipc	ra,0xfffff
    80004c28:	da2080e7          	jalr	-606(ra) # 800039c6 <bpin>
    log.lh.n++;
    80004c2c:	00042717          	auipc	a4,0x42
    80004c30:	58470713          	addi	a4,a4,1412 # 800471b0 <log>
    80004c34:	575c                	lw	a5,44(a4)
    80004c36:	2785                	addiw	a5,a5,1
    80004c38:	d75c                	sw	a5,44(a4)
    80004c3a:	a835                	j	80004c76 <log_write+0xca>
    panic("too big a transaction");
    80004c3c:	00004517          	auipc	a0,0x4
    80004c40:	b6450513          	addi	a0,a0,-1180 # 800087a0 <syscalls+0x220>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	8fa080e7          	jalr	-1798(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004c4c:	00004517          	auipc	a0,0x4
    80004c50:	b6c50513          	addi	a0,a0,-1172 # 800087b8 <syscalls+0x238>
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	8ea080e7          	jalr	-1814(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004c5c:	00878713          	addi	a4,a5,8
    80004c60:	00271693          	slli	a3,a4,0x2
    80004c64:	00042717          	auipc	a4,0x42
    80004c68:	54c70713          	addi	a4,a4,1356 # 800471b0 <log>
    80004c6c:	9736                	add	a4,a4,a3
    80004c6e:	44d4                	lw	a3,12(s1)
    80004c70:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c72:	faf608e3          	beq	a2,a5,80004c22 <log_write+0x76>
  }
  release(&log.lock);
    80004c76:	00042517          	auipc	a0,0x42
    80004c7a:	53a50513          	addi	a0,a0,1338 # 800471b0 <log>
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	09a080e7          	jalr	154(ra) # 80000d18 <release>
}
    80004c86:	60e2                	ld	ra,24(sp)
    80004c88:	6442                	ld	s0,16(sp)
    80004c8a:	64a2                	ld	s1,8(sp)
    80004c8c:	6902                	ld	s2,0(sp)
    80004c8e:	6105                	addi	sp,sp,32
    80004c90:	8082                	ret

0000000080004c92 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c92:	1101                	addi	sp,sp,-32
    80004c94:	ec06                	sd	ra,24(sp)
    80004c96:	e822                	sd	s0,16(sp)
    80004c98:	e426                	sd	s1,8(sp)
    80004c9a:	e04a                	sd	s2,0(sp)
    80004c9c:	1000                	addi	s0,sp,32
    80004c9e:	84aa                	mv	s1,a0
    80004ca0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ca2:	00004597          	auipc	a1,0x4
    80004ca6:	b3658593          	addi	a1,a1,-1226 # 800087d8 <syscalls+0x258>
    80004caa:	0521                	addi	a0,a0,8
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	f28080e7          	jalr	-216(ra) # 80000bd4 <initlock>
  lk->name = name;
    80004cb4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004cb8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004cbc:	0204a423          	sw	zero,40(s1)
}
    80004cc0:	60e2                	ld	ra,24(sp)
    80004cc2:	6442                	ld	s0,16(sp)
    80004cc4:	64a2                	ld	s1,8(sp)
    80004cc6:	6902                	ld	s2,0(sp)
    80004cc8:	6105                	addi	sp,sp,32
    80004cca:	8082                	ret

0000000080004ccc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ccc:	1101                	addi	sp,sp,-32
    80004cce:	ec06                	sd	ra,24(sp)
    80004cd0:	e822                	sd	s0,16(sp)
    80004cd2:	e426                	sd	s1,8(sp)
    80004cd4:	e04a                	sd	s2,0(sp)
    80004cd6:	1000                	addi	s0,sp,32
    80004cd8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cda:	00850913          	addi	s2,a0,8
    80004cde:	854a                	mv	a0,s2
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	f84080e7          	jalr	-124(ra) # 80000c64 <acquire>
  while (lk->locked) {
    80004ce8:	409c                	lw	a5,0(s1)
    80004cea:	cb89                	beqz	a5,80004cfc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004cec:	85ca                	mv	a1,s2
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	788080e7          	jalr	1928(ra) # 80002478 <sleep>
  while (lk->locked) {
    80004cf8:	409c                	lw	a5,0(s1)
    80004cfa:	fbed                	bnez	a5,80004cec <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004cfc:	4785                	li	a5,1
    80004cfe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	df8080e7          	jalr	-520(ra) # 80001af8 <myproc>
    80004d08:	591c                	lw	a5,48(a0)
    80004d0a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d0c:	854a                	mv	a0,s2
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	00a080e7          	jalr	10(ra) # 80000d18 <release>
}
    80004d16:	60e2                	ld	ra,24(sp)
    80004d18:	6442                	ld	s0,16(sp)
    80004d1a:	64a2                	ld	s1,8(sp)
    80004d1c:	6902                	ld	s2,0(sp)
    80004d1e:	6105                	addi	sp,sp,32
    80004d20:	8082                	ret

0000000080004d22 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d22:	1101                	addi	sp,sp,-32
    80004d24:	ec06                	sd	ra,24(sp)
    80004d26:	e822                	sd	s0,16(sp)
    80004d28:	e426                	sd	s1,8(sp)
    80004d2a:	e04a                	sd	s2,0(sp)
    80004d2c:	1000                	addi	s0,sp,32
    80004d2e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d30:	00850913          	addi	s2,a0,8
    80004d34:	854a                	mv	a0,s2
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	f2e080e7          	jalr	-210(ra) # 80000c64 <acquire>
  lk->locked = 0;
    80004d3e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d42:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d46:	8526                	mv	a0,s1
    80004d48:	ffffe097          	auipc	ra,0xffffe
    80004d4c:	8e0080e7          	jalr	-1824(ra) # 80002628 <wakeup>
  release(&lk->lk);
    80004d50:	854a                	mv	a0,s2
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	fc6080e7          	jalr	-58(ra) # 80000d18 <release>
}
    80004d5a:	60e2                	ld	ra,24(sp)
    80004d5c:	6442                	ld	s0,16(sp)
    80004d5e:	64a2                	ld	s1,8(sp)
    80004d60:	6902                	ld	s2,0(sp)
    80004d62:	6105                	addi	sp,sp,32
    80004d64:	8082                	ret

0000000080004d66 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d66:	7179                	addi	sp,sp,-48
    80004d68:	f406                	sd	ra,40(sp)
    80004d6a:	f022                	sd	s0,32(sp)
    80004d6c:	ec26                	sd	s1,24(sp)
    80004d6e:	e84a                	sd	s2,16(sp)
    80004d70:	e44e                	sd	s3,8(sp)
    80004d72:	1800                	addi	s0,sp,48
    80004d74:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d76:	00850913          	addi	s2,a0,8
    80004d7a:	854a                	mv	a0,s2
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	ee8080e7          	jalr	-280(ra) # 80000c64 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d84:	409c                	lw	a5,0(s1)
    80004d86:	ef99                	bnez	a5,80004da4 <holdingsleep+0x3e>
    80004d88:	4481                	li	s1,0
  release(&lk->lk);
    80004d8a:	854a                	mv	a0,s2
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	f8c080e7          	jalr	-116(ra) # 80000d18 <release>
  return r;
}
    80004d94:	8526                	mv	a0,s1
    80004d96:	70a2                	ld	ra,40(sp)
    80004d98:	7402                	ld	s0,32(sp)
    80004d9a:	64e2                	ld	s1,24(sp)
    80004d9c:	6942                	ld	s2,16(sp)
    80004d9e:	69a2                	ld	s3,8(sp)
    80004da0:	6145                	addi	sp,sp,48
    80004da2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004da4:	0284a983          	lw	s3,40(s1)
    80004da8:	ffffd097          	auipc	ra,0xffffd
    80004dac:	d50080e7          	jalr	-688(ra) # 80001af8 <myproc>
    80004db0:	5904                	lw	s1,48(a0)
    80004db2:	413484b3          	sub	s1,s1,s3
    80004db6:	0014b493          	seqz	s1,s1
    80004dba:	bfc1                	j	80004d8a <holdingsleep+0x24>

0000000080004dbc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004dbc:	1141                	addi	sp,sp,-16
    80004dbe:	e406                	sd	ra,8(sp)
    80004dc0:	e022                	sd	s0,0(sp)
    80004dc2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004dc4:	00004597          	auipc	a1,0x4
    80004dc8:	a2458593          	addi	a1,a1,-1500 # 800087e8 <syscalls+0x268>
    80004dcc:	00042517          	auipc	a0,0x42
    80004dd0:	52c50513          	addi	a0,a0,1324 # 800472f8 <ftable>
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	e00080e7          	jalr	-512(ra) # 80000bd4 <initlock>
}
    80004ddc:	60a2                	ld	ra,8(sp)
    80004dde:	6402                	ld	s0,0(sp)
    80004de0:	0141                	addi	sp,sp,16
    80004de2:	8082                	ret

0000000080004de4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004de4:	1101                	addi	sp,sp,-32
    80004de6:	ec06                	sd	ra,24(sp)
    80004de8:	e822                	sd	s0,16(sp)
    80004dea:	e426                	sd	s1,8(sp)
    80004dec:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004dee:	00042517          	auipc	a0,0x42
    80004df2:	50a50513          	addi	a0,a0,1290 # 800472f8 <ftable>
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	e6e080e7          	jalr	-402(ra) # 80000c64 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dfe:	00042497          	auipc	s1,0x42
    80004e02:	51248493          	addi	s1,s1,1298 # 80047310 <ftable+0x18>
    80004e06:	00043717          	auipc	a4,0x43
    80004e0a:	4aa70713          	addi	a4,a4,1194 # 800482b0 <disk>
    if(f->ref == 0){
    80004e0e:	40dc                	lw	a5,4(s1)
    80004e10:	cf99                	beqz	a5,80004e2e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e12:	02848493          	addi	s1,s1,40
    80004e16:	fee49ce3          	bne	s1,a4,80004e0e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e1a:	00042517          	auipc	a0,0x42
    80004e1e:	4de50513          	addi	a0,a0,1246 # 800472f8 <ftable>
    80004e22:	ffffc097          	auipc	ra,0xffffc
    80004e26:	ef6080e7          	jalr	-266(ra) # 80000d18 <release>
  return 0;
    80004e2a:	4481                	li	s1,0
    80004e2c:	a819                	j	80004e42 <filealloc+0x5e>
      f->ref = 1;
    80004e2e:	4785                	li	a5,1
    80004e30:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e32:	00042517          	auipc	a0,0x42
    80004e36:	4c650513          	addi	a0,a0,1222 # 800472f8 <ftable>
    80004e3a:	ffffc097          	auipc	ra,0xffffc
    80004e3e:	ede080e7          	jalr	-290(ra) # 80000d18 <release>
}
    80004e42:	8526                	mv	a0,s1
    80004e44:	60e2                	ld	ra,24(sp)
    80004e46:	6442                	ld	s0,16(sp)
    80004e48:	64a2                	ld	s1,8(sp)
    80004e4a:	6105                	addi	sp,sp,32
    80004e4c:	8082                	ret

0000000080004e4e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e4e:	1101                	addi	sp,sp,-32
    80004e50:	ec06                	sd	ra,24(sp)
    80004e52:	e822                	sd	s0,16(sp)
    80004e54:	e426                	sd	s1,8(sp)
    80004e56:	1000                	addi	s0,sp,32
    80004e58:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e5a:	00042517          	auipc	a0,0x42
    80004e5e:	49e50513          	addi	a0,a0,1182 # 800472f8 <ftable>
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	e02080e7          	jalr	-510(ra) # 80000c64 <acquire>
  if(f->ref < 1)
    80004e6a:	40dc                	lw	a5,4(s1)
    80004e6c:	02f05263          	blez	a5,80004e90 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e70:	2785                	addiw	a5,a5,1
    80004e72:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e74:	00042517          	auipc	a0,0x42
    80004e78:	48450513          	addi	a0,a0,1156 # 800472f8 <ftable>
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	e9c080e7          	jalr	-356(ra) # 80000d18 <release>
  return f;
}
    80004e84:	8526                	mv	a0,s1
    80004e86:	60e2                	ld	ra,24(sp)
    80004e88:	6442                	ld	s0,16(sp)
    80004e8a:	64a2                	ld	s1,8(sp)
    80004e8c:	6105                	addi	sp,sp,32
    80004e8e:	8082                	ret
    panic("filedup");
    80004e90:	00004517          	auipc	a0,0x4
    80004e94:	96050513          	addi	a0,a0,-1696 # 800087f0 <syscalls+0x270>
    80004e98:	ffffb097          	auipc	ra,0xffffb
    80004e9c:	6a6080e7          	jalr	1702(ra) # 8000053e <panic>

0000000080004ea0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ea0:	7139                	addi	sp,sp,-64
    80004ea2:	fc06                	sd	ra,56(sp)
    80004ea4:	f822                	sd	s0,48(sp)
    80004ea6:	f426                	sd	s1,40(sp)
    80004ea8:	f04a                	sd	s2,32(sp)
    80004eaa:	ec4e                	sd	s3,24(sp)
    80004eac:	e852                	sd	s4,16(sp)
    80004eae:	e456                	sd	s5,8(sp)
    80004eb0:	0080                	addi	s0,sp,64
    80004eb2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004eb4:	00042517          	auipc	a0,0x42
    80004eb8:	44450513          	addi	a0,a0,1092 # 800472f8 <ftable>
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	da8080e7          	jalr	-600(ra) # 80000c64 <acquire>
  if(f->ref < 1)
    80004ec4:	40dc                	lw	a5,4(s1)
    80004ec6:	06f05163          	blez	a5,80004f28 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004eca:	37fd                	addiw	a5,a5,-1
    80004ecc:	0007871b          	sext.w	a4,a5
    80004ed0:	c0dc                	sw	a5,4(s1)
    80004ed2:	06e04363          	bgtz	a4,80004f38 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ed6:	0004a903          	lw	s2,0(s1)
    80004eda:	0094ca83          	lbu	s5,9(s1)
    80004ede:	0104ba03          	ld	s4,16(s1)
    80004ee2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ee6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004eea:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004eee:	00042517          	auipc	a0,0x42
    80004ef2:	40a50513          	addi	a0,a0,1034 # 800472f8 <ftable>
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	e22080e7          	jalr	-478(ra) # 80000d18 <release>

  if(ff.type == FD_PIPE){
    80004efe:	4785                	li	a5,1
    80004f00:	04f90d63          	beq	s2,a5,80004f5a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f04:	3979                	addiw	s2,s2,-2
    80004f06:	4785                	li	a5,1
    80004f08:	0527e063          	bltu	a5,s2,80004f48 <fileclose+0xa8>
    begin_op();
    80004f0c:	00000097          	auipc	ra,0x0
    80004f10:	ac8080e7          	jalr	-1336(ra) # 800049d4 <begin_op>
    iput(ff.ip);
    80004f14:	854e                	mv	a0,s3
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	2b6080e7          	jalr	694(ra) # 800041cc <iput>
    end_op();
    80004f1e:	00000097          	auipc	ra,0x0
    80004f22:	b36080e7          	jalr	-1226(ra) # 80004a54 <end_op>
    80004f26:	a00d                	j	80004f48 <fileclose+0xa8>
    panic("fileclose");
    80004f28:	00004517          	auipc	a0,0x4
    80004f2c:	8d050513          	addi	a0,a0,-1840 # 800087f8 <syscalls+0x278>
    80004f30:	ffffb097          	auipc	ra,0xffffb
    80004f34:	60e080e7          	jalr	1550(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004f38:	00042517          	auipc	a0,0x42
    80004f3c:	3c050513          	addi	a0,a0,960 # 800472f8 <ftable>
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	dd8080e7          	jalr	-552(ra) # 80000d18 <release>
  }
}
    80004f48:	70e2                	ld	ra,56(sp)
    80004f4a:	7442                	ld	s0,48(sp)
    80004f4c:	74a2                	ld	s1,40(sp)
    80004f4e:	7902                	ld	s2,32(sp)
    80004f50:	69e2                	ld	s3,24(sp)
    80004f52:	6a42                	ld	s4,16(sp)
    80004f54:	6aa2                	ld	s5,8(sp)
    80004f56:	6121                	addi	sp,sp,64
    80004f58:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f5a:	85d6                	mv	a1,s5
    80004f5c:	8552                	mv	a0,s4
    80004f5e:	00000097          	auipc	ra,0x0
    80004f62:	34c080e7          	jalr	844(ra) # 800052aa <pipeclose>
    80004f66:	b7cd                	j	80004f48 <fileclose+0xa8>

0000000080004f68 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f68:	715d                	addi	sp,sp,-80
    80004f6a:	e486                	sd	ra,72(sp)
    80004f6c:	e0a2                	sd	s0,64(sp)
    80004f6e:	fc26                	sd	s1,56(sp)
    80004f70:	f84a                	sd	s2,48(sp)
    80004f72:	f44e                	sd	s3,40(sp)
    80004f74:	0880                	addi	s0,sp,80
    80004f76:	84aa                	mv	s1,a0
    80004f78:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	b7e080e7          	jalr	-1154(ra) # 80001af8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f82:	409c                	lw	a5,0(s1)
    80004f84:	37f9                	addiw	a5,a5,-2
    80004f86:	4705                	li	a4,1
    80004f88:	04f76763          	bltu	a4,a5,80004fd6 <filestat+0x6e>
    80004f8c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f8e:	6c88                	ld	a0,24(s1)
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	082080e7          	jalr	130(ra) # 80004012 <ilock>
    stati(f->ip, &st);
    80004f98:	fb840593          	addi	a1,s0,-72
    80004f9c:	6c88                	ld	a0,24(s1)
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	2fe080e7          	jalr	766(ra) # 8000429c <stati>
    iunlock(f->ip);
    80004fa6:	6c88                	ld	a0,24(s1)
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	12c080e7          	jalr	300(ra) # 800040d4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004fb0:	46e1                	li	a3,24
    80004fb2:	fb840613          	addi	a2,s0,-72
    80004fb6:	85ce                	mv	a1,s3
    80004fb8:	05093503          	ld	a0,80(s2)
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	732080e7          	jalr	1842(ra) # 800016ee <copyout>
    80004fc4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004fc8:	60a6                	ld	ra,72(sp)
    80004fca:	6406                	ld	s0,64(sp)
    80004fcc:	74e2                	ld	s1,56(sp)
    80004fce:	7942                	ld	s2,48(sp)
    80004fd0:	79a2                	ld	s3,40(sp)
    80004fd2:	6161                	addi	sp,sp,80
    80004fd4:	8082                	ret
  return -1;
    80004fd6:	557d                	li	a0,-1
    80004fd8:	bfc5                	j	80004fc8 <filestat+0x60>

0000000080004fda <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004fda:	7179                	addi	sp,sp,-48
    80004fdc:	f406                	sd	ra,40(sp)
    80004fde:	f022                	sd	s0,32(sp)
    80004fe0:	ec26                	sd	s1,24(sp)
    80004fe2:	e84a                	sd	s2,16(sp)
    80004fe4:	e44e                	sd	s3,8(sp)
    80004fe6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004fe8:	00854783          	lbu	a5,8(a0)
    80004fec:	c3d5                	beqz	a5,80005090 <fileread+0xb6>
    80004fee:	84aa                	mv	s1,a0
    80004ff0:	89ae                	mv	s3,a1
    80004ff2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ff4:	411c                	lw	a5,0(a0)
    80004ff6:	4705                	li	a4,1
    80004ff8:	04e78963          	beq	a5,a4,8000504a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ffc:	470d                	li	a4,3
    80004ffe:	04e78d63          	beq	a5,a4,80005058 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005002:	4709                	li	a4,2
    80005004:	06e79e63          	bne	a5,a4,80005080 <fileread+0xa6>
    ilock(f->ip);
    80005008:	6d08                	ld	a0,24(a0)
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	008080e7          	jalr	8(ra) # 80004012 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005012:	874a                	mv	a4,s2
    80005014:	5094                	lw	a3,32(s1)
    80005016:	864e                	mv	a2,s3
    80005018:	4585                	li	a1,1
    8000501a:	6c88                	ld	a0,24(s1)
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	2aa080e7          	jalr	682(ra) # 800042c6 <readi>
    80005024:	892a                	mv	s2,a0
    80005026:	00a05563          	blez	a0,80005030 <fileread+0x56>
      f->off += r;
    8000502a:	509c                	lw	a5,32(s1)
    8000502c:	9fa9                	addw	a5,a5,a0
    8000502e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005030:	6c88                	ld	a0,24(s1)
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	0a2080e7          	jalr	162(ra) # 800040d4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000503a:	854a                	mv	a0,s2
    8000503c:	70a2                	ld	ra,40(sp)
    8000503e:	7402                	ld	s0,32(sp)
    80005040:	64e2                	ld	s1,24(sp)
    80005042:	6942                	ld	s2,16(sp)
    80005044:	69a2                	ld	s3,8(sp)
    80005046:	6145                	addi	sp,sp,48
    80005048:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000504a:	6908                	ld	a0,16(a0)
    8000504c:	00000097          	auipc	ra,0x0
    80005050:	3c6080e7          	jalr	966(ra) # 80005412 <piperead>
    80005054:	892a                	mv	s2,a0
    80005056:	b7d5                	j	8000503a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005058:	02451783          	lh	a5,36(a0)
    8000505c:	03079693          	slli	a3,a5,0x30
    80005060:	92c1                	srli	a3,a3,0x30
    80005062:	4725                	li	a4,9
    80005064:	02d76863          	bltu	a4,a3,80005094 <fileread+0xba>
    80005068:	0792                	slli	a5,a5,0x4
    8000506a:	00042717          	auipc	a4,0x42
    8000506e:	1ee70713          	addi	a4,a4,494 # 80047258 <devsw>
    80005072:	97ba                	add	a5,a5,a4
    80005074:	639c                	ld	a5,0(a5)
    80005076:	c38d                	beqz	a5,80005098 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005078:	4505                	li	a0,1
    8000507a:	9782                	jalr	a5
    8000507c:	892a                	mv	s2,a0
    8000507e:	bf75                	j	8000503a <fileread+0x60>
    panic("fileread");
    80005080:	00003517          	auipc	a0,0x3
    80005084:	78850513          	addi	a0,a0,1928 # 80008808 <syscalls+0x288>
    80005088:	ffffb097          	auipc	ra,0xffffb
    8000508c:	4b6080e7          	jalr	1206(ra) # 8000053e <panic>
    return -1;
    80005090:	597d                	li	s2,-1
    80005092:	b765                	j	8000503a <fileread+0x60>
      return -1;
    80005094:	597d                	li	s2,-1
    80005096:	b755                	j	8000503a <fileread+0x60>
    80005098:	597d                	li	s2,-1
    8000509a:	b745                	j	8000503a <fileread+0x60>

000000008000509c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000509c:	715d                	addi	sp,sp,-80
    8000509e:	e486                	sd	ra,72(sp)
    800050a0:	e0a2                	sd	s0,64(sp)
    800050a2:	fc26                	sd	s1,56(sp)
    800050a4:	f84a                	sd	s2,48(sp)
    800050a6:	f44e                	sd	s3,40(sp)
    800050a8:	f052                	sd	s4,32(sp)
    800050aa:	ec56                	sd	s5,24(sp)
    800050ac:	e85a                	sd	s6,16(sp)
    800050ae:	e45e                	sd	s7,8(sp)
    800050b0:	e062                	sd	s8,0(sp)
    800050b2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800050b4:	00954783          	lbu	a5,9(a0)
    800050b8:	10078663          	beqz	a5,800051c4 <filewrite+0x128>
    800050bc:	892a                	mv	s2,a0
    800050be:	8aae                	mv	s5,a1
    800050c0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800050c2:	411c                	lw	a5,0(a0)
    800050c4:	4705                	li	a4,1
    800050c6:	02e78263          	beq	a5,a4,800050ea <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050ca:	470d                	li	a4,3
    800050cc:	02e78663          	beq	a5,a4,800050f8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800050d0:	4709                	li	a4,2
    800050d2:	0ee79163          	bne	a5,a4,800051b4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800050d6:	0ac05d63          	blez	a2,80005190 <filewrite+0xf4>
    int i = 0;
    800050da:	4981                	li	s3,0
    800050dc:	6b05                	lui	s6,0x1
    800050de:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800050e2:	6b85                	lui	s7,0x1
    800050e4:	c00b8b9b          	addiw	s7,s7,-1024
    800050e8:	a861                	j	80005180 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800050ea:	6908                	ld	a0,16(a0)
    800050ec:	00000097          	auipc	ra,0x0
    800050f0:	22e080e7          	jalr	558(ra) # 8000531a <pipewrite>
    800050f4:	8a2a                	mv	s4,a0
    800050f6:	a045                	j	80005196 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800050f8:	02451783          	lh	a5,36(a0)
    800050fc:	03079693          	slli	a3,a5,0x30
    80005100:	92c1                	srli	a3,a3,0x30
    80005102:	4725                	li	a4,9
    80005104:	0cd76263          	bltu	a4,a3,800051c8 <filewrite+0x12c>
    80005108:	0792                	slli	a5,a5,0x4
    8000510a:	00042717          	auipc	a4,0x42
    8000510e:	14e70713          	addi	a4,a4,334 # 80047258 <devsw>
    80005112:	97ba                	add	a5,a5,a4
    80005114:	679c                	ld	a5,8(a5)
    80005116:	cbdd                	beqz	a5,800051cc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005118:	4505                	li	a0,1
    8000511a:	9782                	jalr	a5
    8000511c:	8a2a                	mv	s4,a0
    8000511e:	a8a5                	j	80005196 <filewrite+0xfa>
    80005120:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005124:	00000097          	auipc	ra,0x0
    80005128:	8b0080e7          	jalr	-1872(ra) # 800049d4 <begin_op>
      ilock(f->ip);
    8000512c:	01893503          	ld	a0,24(s2)
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	ee2080e7          	jalr	-286(ra) # 80004012 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005138:	8762                	mv	a4,s8
    8000513a:	02092683          	lw	a3,32(s2)
    8000513e:	01598633          	add	a2,s3,s5
    80005142:	4585                	li	a1,1
    80005144:	01893503          	ld	a0,24(s2)
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	276080e7          	jalr	630(ra) # 800043be <writei>
    80005150:	84aa                	mv	s1,a0
    80005152:	00a05763          	blez	a0,80005160 <filewrite+0xc4>
        f->off += r;
    80005156:	02092783          	lw	a5,32(s2)
    8000515a:	9fa9                	addw	a5,a5,a0
    8000515c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005160:	01893503          	ld	a0,24(s2)
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	f70080e7          	jalr	-144(ra) # 800040d4 <iunlock>
      end_op();
    8000516c:	00000097          	auipc	ra,0x0
    80005170:	8e8080e7          	jalr	-1816(ra) # 80004a54 <end_op>

      if(r != n1){
    80005174:	009c1f63          	bne	s8,s1,80005192 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005178:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000517c:	0149db63          	bge	s3,s4,80005192 <filewrite+0xf6>
      int n1 = n - i;
    80005180:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005184:	84be                	mv	s1,a5
    80005186:	2781                	sext.w	a5,a5
    80005188:	f8fb5ce3          	bge	s6,a5,80005120 <filewrite+0x84>
    8000518c:	84de                	mv	s1,s7
    8000518e:	bf49                	j	80005120 <filewrite+0x84>
    int i = 0;
    80005190:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005192:	013a1f63          	bne	s4,s3,800051b0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005196:	8552                	mv	a0,s4
    80005198:	60a6                	ld	ra,72(sp)
    8000519a:	6406                	ld	s0,64(sp)
    8000519c:	74e2                	ld	s1,56(sp)
    8000519e:	7942                	ld	s2,48(sp)
    800051a0:	79a2                	ld	s3,40(sp)
    800051a2:	7a02                	ld	s4,32(sp)
    800051a4:	6ae2                	ld	s5,24(sp)
    800051a6:	6b42                	ld	s6,16(sp)
    800051a8:	6ba2                	ld	s7,8(sp)
    800051aa:	6c02                	ld	s8,0(sp)
    800051ac:	6161                	addi	sp,sp,80
    800051ae:	8082                	ret
    ret = (i == n ? n : -1);
    800051b0:	5a7d                	li	s4,-1
    800051b2:	b7d5                	j	80005196 <filewrite+0xfa>
    panic("filewrite");
    800051b4:	00003517          	auipc	a0,0x3
    800051b8:	66450513          	addi	a0,a0,1636 # 80008818 <syscalls+0x298>
    800051bc:	ffffb097          	auipc	ra,0xffffb
    800051c0:	382080e7          	jalr	898(ra) # 8000053e <panic>
    return -1;
    800051c4:	5a7d                	li	s4,-1
    800051c6:	bfc1                	j	80005196 <filewrite+0xfa>
      return -1;
    800051c8:	5a7d                	li	s4,-1
    800051ca:	b7f1                	j	80005196 <filewrite+0xfa>
    800051cc:	5a7d                	li	s4,-1
    800051ce:	b7e1                	j	80005196 <filewrite+0xfa>

00000000800051d0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800051d0:	7179                	addi	sp,sp,-48
    800051d2:	f406                	sd	ra,40(sp)
    800051d4:	f022                	sd	s0,32(sp)
    800051d6:	ec26                	sd	s1,24(sp)
    800051d8:	e84a                	sd	s2,16(sp)
    800051da:	e44e                	sd	s3,8(sp)
    800051dc:	e052                	sd	s4,0(sp)
    800051de:	1800                	addi	s0,sp,48
    800051e0:	84aa                	mv	s1,a0
    800051e2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800051e4:	0005b023          	sd	zero,0(a1)
    800051e8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800051ec:	00000097          	auipc	ra,0x0
    800051f0:	bf8080e7          	jalr	-1032(ra) # 80004de4 <filealloc>
    800051f4:	e088                	sd	a0,0(s1)
    800051f6:	c551                	beqz	a0,80005282 <pipealloc+0xb2>
    800051f8:	00000097          	auipc	ra,0x0
    800051fc:	bec080e7          	jalr	-1044(ra) # 80004de4 <filealloc>
    80005200:	00aa3023          	sd	a0,0(s4)
    80005204:	c92d                	beqz	a0,80005276 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	92e080e7          	jalr	-1746(ra) # 80000b34 <kalloc>
    8000520e:	892a                	mv	s2,a0
    80005210:	c125                	beqz	a0,80005270 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005212:	4985                	li	s3,1
    80005214:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005218:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000521c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005220:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005224:	00003597          	auipc	a1,0x3
    80005228:	28c58593          	addi	a1,a1,652 # 800084b0 <states.0+0x1c8>
    8000522c:	ffffc097          	auipc	ra,0xffffc
    80005230:	9a8080e7          	jalr	-1624(ra) # 80000bd4 <initlock>
  (*f0)->type = FD_PIPE;
    80005234:	609c                	ld	a5,0(s1)
    80005236:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000523a:	609c                	ld	a5,0(s1)
    8000523c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005240:	609c                	ld	a5,0(s1)
    80005242:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005246:	609c                	ld	a5,0(s1)
    80005248:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000524c:	000a3783          	ld	a5,0(s4)
    80005250:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005254:	000a3783          	ld	a5,0(s4)
    80005258:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000525c:	000a3783          	ld	a5,0(s4)
    80005260:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005264:	000a3783          	ld	a5,0(s4)
    80005268:	0127b823          	sd	s2,16(a5)
  return 0;
    8000526c:	4501                	li	a0,0
    8000526e:	a025                	j	80005296 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005270:	6088                	ld	a0,0(s1)
    80005272:	e501                	bnez	a0,8000527a <pipealloc+0xaa>
    80005274:	a039                	j	80005282 <pipealloc+0xb2>
    80005276:	6088                	ld	a0,0(s1)
    80005278:	c51d                	beqz	a0,800052a6 <pipealloc+0xd6>
    fileclose(*f0);
    8000527a:	00000097          	auipc	ra,0x0
    8000527e:	c26080e7          	jalr	-986(ra) # 80004ea0 <fileclose>
  if(*f1)
    80005282:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005286:	557d                	li	a0,-1
  if(*f1)
    80005288:	c799                	beqz	a5,80005296 <pipealloc+0xc6>
    fileclose(*f1);
    8000528a:	853e                	mv	a0,a5
    8000528c:	00000097          	auipc	ra,0x0
    80005290:	c14080e7          	jalr	-1004(ra) # 80004ea0 <fileclose>
  return -1;
    80005294:	557d                	li	a0,-1
}
    80005296:	70a2                	ld	ra,40(sp)
    80005298:	7402                	ld	s0,32(sp)
    8000529a:	64e2                	ld	s1,24(sp)
    8000529c:	6942                	ld	s2,16(sp)
    8000529e:	69a2                	ld	s3,8(sp)
    800052a0:	6a02                	ld	s4,0(sp)
    800052a2:	6145                	addi	sp,sp,48
    800052a4:	8082                	ret
  return -1;
    800052a6:	557d                	li	a0,-1
    800052a8:	b7fd                	j	80005296 <pipealloc+0xc6>

00000000800052aa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800052aa:	1101                	addi	sp,sp,-32
    800052ac:	ec06                	sd	ra,24(sp)
    800052ae:	e822                	sd	s0,16(sp)
    800052b0:	e426                	sd	s1,8(sp)
    800052b2:	e04a                	sd	s2,0(sp)
    800052b4:	1000                	addi	s0,sp,32
    800052b6:	84aa                	mv	s1,a0
    800052b8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800052ba:	ffffc097          	auipc	ra,0xffffc
    800052be:	9aa080e7          	jalr	-1622(ra) # 80000c64 <acquire>
  if(writable){
    800052c2:	02090d63          	beqz	s2,800052fc <pipeclose+0x52>
    pi->writeopen = 0;
    800052c6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800052ca:	21848513          	addi	a0,s1,536
    800052ce:	ffffd097          	auipc	ra,0xffffd
    800052d2:	35a080e7          	jalr	858(ra) # 80002628 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800052d6:	2204b783          	ld	a5,544(s1)
    800052da:	eb95                	bnez	a5,8000530e <pipeclose+0x64>
    release(&pi->lock);
    800052dc:	8526                	mv	a0,s1
    800052de:	ffffc097          	auipc	ra,0xffffc
    800052e2:	a3a080e7          	jalr	-1478(ra) # 80000d18 <release>
    kfree((char*)pi);
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffb097          	auipc	ra,0xffffb
    800052ec:	702080e7          	jalr	1794(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800052f0:	60e2                	ld	ra,24(sp)
    800052f2:	6442                	ld	s0,16(sp)
    800052f4:	64a2                	ld	s1,8(sp)
    800052f6:	6902                	ld	s2,0(sp)
    800052f8:	6105                	addi	sp,sp,32
    800052fa:	8082                	ret
    pi->readopen = 0;
    800052fc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005300:	21c48513          	addi	a0,s1,540
    80005304:	ffffd097          	auipc	ra,0xffffd
    80005308:	324080e7          	jalr	804(ra) # 80002628 <wakeup>
    8000530c:	b7e9                	j	800052d6 <pipeclose+0x2c>
    release(&pi->lock);
    8000530e:	8526                	mv	a0,s1
    80005310:	ffffc097          	auipc	ra,0xffffc
    80005314:	a08080e7          	jalr	-1528(ra) # 80000d18 <release>
}
    80005318:	bfe1                	j	800052f0 <pipeclose+0x46>

000000008000531a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000531a:	711d                	addi	sp,sp,-96
    8000531c:	ec86                	sd	ra,88(sp)
    8000531e:	e8a2                	sd	s0,80(sp)
    80005320:	e4a6                	sd	s1,72(sp)
    80005322:	e0ca                	sd	s2,64(sp)
    80005324:	fc4e                	sd	s3,56(sp)
    80005326:	f852                	sd	s4,48(sp)
    80005328:	f456                	sd	s5,40(sp)
    8000532a:	f05a                	sd	s6,32(sp)
    8000532c:	ec5e                	sd	s7,24(sp)
    8000532e:	e862                	sd	s8,16(sp)
    80005330:	1080                	addi	s0,sp,96
    80005332:	84aa                	mv	s1,a0
    80005334:	8aae                	mv	s5,a1
    80005336:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005338:	ffffc097          	auipc	ra,0xffffc
    8000533c:	7c0080e7          	jalr	1984(ra) # 80001af8 <myproc>
    80005340:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005342:	8526                	mv	a0,s1
    80005344:	ffffc097          	auipc	ra,0xffffc
    80005348:	920080e7          	jalr	-1760(ra) # 80000c64 <acquire>
  while(i < n){
    8000534c:	0b405663          	blez	s4,800053f8 <pipewrite+0xde>
  int i = 0;
    80005350:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005352:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005354:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005358:	21c48b93          	addi	s7,s1,540
    8000535c:	a089                	j	8000539e <pipewrite+0x84>
      release(&pi->lock);
    8000535e:	8526                	mv	a0,s1
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	9b8080e7          	jalr	-1608(ra) # 80000d18 <release>
      return -1;
    80005368:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000536a:	854a                	mv	a0,s2
    8000536c:	60e6                	ld	ra,88(sp)
    8000536e:	6446                	ld	s0,80(sp)
    80005370:	64a6                	ld	s1,72(sp)
    80005372:	6906                	ld	s2,64(sp)
    80005374:	79e2                	ld	s3,56(sp)
    80005376:	7a42                	ld	s4,48(sp)
    80005378:	7aa2                	ld	s5,40(sp)
    8000537a:	7b02                	ld	s6,32(sp)
    8000537c:	6be2                	ld	s7,24(sp)
    8000537e:	6c42                	ld	s8,16(sp)
    80005380:	6125                	addi	sp,sp,96
    80005382:	8082                	ret
      wakeup(&pi->nread);
    80005384:	8562                	mv	a0,s8
    80005386:	ffffd097          	auipc	ra,0xffffd
    8000538a:	2a2080e7          	jalr	674(ra) # 80002628 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000538e:	85a6                	mv	a1,s1
    80005390:	855e                	mv	a0,s7
    80005392:	ffffd097          	auipc	ra,0xffffd
    80005396:	0e6080e7          	jalr	230(ra) # 80002478 <sleep>
  while(i < n){
    8000539a:	07495063          	bge	s2,s4,800053fa <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000539e:	2204a783          	lw	a5,544(s1)
    800053a2:	dfd5                	beqz	a5,8000535e <pipewrite+0x44>
    800053a4:	854e                	mv	a0,s3
    800053a6:	ffffd097          	auipc	ra,0xffffd
    800053aa:	4d2080e7          	jalr	1234(ra) # 80002878 <killed>
    800053ae:	f945                	bnez	a0,8000535e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800053b0:	2184a783          	lw	a5,536(s1)
    800053b4:	21c4a703          	lw	a4,540(s1)
    800053b8:	2007879b          	addiw	a5,a5,512
    800053bc:	fcf704e3          	beq	a4,a5,80005384 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800053c0:	4685                	li	a3,1
    800053c2:	01590633          	add	a2,s2,s5
    800053c6:	faf40593          	addi	a1,s0,-81
    800053ca:	0509b503          	ld	a0,80(s3)
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	42c080e7          	jalr	1068(ra) # 800017fa <copyin>
    800053d6:	03650263          	beq	a0,s6,800053fa <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800053da:	21c4a783          	lw	a5,540(s1)
    800053de:	0017871b          	addiw	a4,a5,1
    800053e2:	20e4ae23          	sw	a4,540(s1)
    800053e6:	1ff7f793          	andi	a5,a5,511
    800053ea:	97a6                	add	a5,a5,s1
    800053ec:	faf44703          	lbu	a4,-81(s0)
    800053f0:	00e78c23          	sb	a4,24(a5)
      i++;
    800053f4:	2905                	addiw	s2,s2,1
    800053f6:	b755                	j	8000539a <pipewrite+0x80>
  int i = 0;
    800053f8:	4901                	li	s2,0
  wakeup(&pi->nread);
    800053fa:	21848513          	addi	a0,s1,536
    800053fe:	ffffd097          	auipc	ra,0xffffd
    80005402:	22a080e7          	jalr	554(ra) # 80002628 <wakeup>
  release(&pi->lock);
    80005406:	8526                	mv	a0,s1
    80005408:	ffffc097          	auipc	ra,0xffffc
    8000540c:	910080e7          	jalr	-1776(ra) # 80000d18 <release>
  return i;
    80005410:	bfa9                	j	8000536a <pipewrite+0x50>

0000000080005412 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005412:	715d                	addi	sp,sp,-80
    80005414:	e486                	sd	ra,72(sp)
    80005416:	e0a2                	sd	s0,64(sp)
    80005418:	fc26                	sd	s1,56(sp)
    8000541a:	f84a                	sd	s2,48(sp)
    8000541c:	f44e                	sd	s3,40(sp)
    8000541e:	f052                	sd	s4,32(sp)
    80005420:	ec56                	sd	s5,24(sp)
    80005422:	e85a                	sd	s6,16(sp)
    80005424:	0880                	addi	s0,sp,80
    80005426:	84aa                	mv	s1,a0
    80005428:	892e                	mv	s2,a1
    8000542a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000542c:	ffffc097          	auipc	ra,0xffffc
    80005430:	6cc080e7          	jalr	1740(ra) # 80001af8 <myproc>
    80005434:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005436:	8526                	mv	a0,s1
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	82c080e7          	jalr	-2004(ra) # 80000c64 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005440:	2184a703          	lw	a4,536(s1)
    80005444:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005448:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000544c:	02f71763          	bne	a4,a5,8000547a <piperead+0x68>
    80005450:	2244a783          	lw	a5,548(s1)
    80005454:	c39d                	beqz	a5,8000547a <piperead+0x68>
    if(killed(pr)){
    80005456:	8552                	mv	a0,s4
    80005458:	ffffd097          	auipc	ra,0xffffd
    8000545c:	420080e7          	jalr	1056(ra) # 80002878 <killed>
    80005460:	e941                	bnez	a0,800054f0 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005462:	85a6                	mv	a1,s1
    80005464:	854e                	mv	a0,s3
    80005466:	ffffd097          	auipc	ra,0xffffd
    8000546a:	012080e7          	jalr	18(ra) # 80002478 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000546e:	2184a703          	lw	a4,536(s1)
    80005472:	21c4a783          	lw	a5,540(s1)
    80005476:	fcf70de3          	beq	a4,a5,80005450 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000547a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000547c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000547e:	05505363          	blez	s5,800054c4 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005482:	2184a783          	lw	a5,536(s1)
    80005486:	21c4a703          	lw	a4,540(s1)
    8000548a:	02f70d63          	beq	a4,a5,800054c4 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000548e:	0017871b          	addiw	a4,a5,1
    80005492:	20e4ac23          	sw	a4,536(s1)
    80005496:	1ff7f793          	andi	a5,a5,511
    8000549a:	97a6                	add	a5,a5,s1
    8000549c:	0187c783          	lbu	a5,24(a5)
    800054a0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054a4:	4685                	li	a3,1
    800054a6:	fbf40613          	addi	a2,s0,-65
    800054aa:	85ca                	mv	a1,s2
    800054ac:	050a3503          	ld	a0,80(s4)
    800054b0:	ffffc097          	auipc	ra,0xffffc
    800054b4:	23e080e7          	jalr	574(ra) # 800016ee <copyout>
    800054b8:	01650663          	beq	a0,s6,800054c4 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054bc:	2985                	addiw	s3,s3,1
    800054be:	0905                	addi	s2,s2,1
    800054c0:	fd3a91e3          	bne	s5,s3,80005482 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800054c4:	21c48513          	addi	a0,s1,540
    800054c8:	ffffd097          	auipc	ra,0xffffd
    800054cc:	160080e7          	jalr	352(ra) # 80002628 <wakeup>
  release(&pi->lock);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffc097          	auipc	ra,0xffffc
    800054d6:	846080e7          	jalr	-1978(ra) # 80000d18 <release>
  return i;
}
    800054da:	854e                	mv	a0,s3
    800054dc:	60a6                	ld	ra,72(sp)
    800054de:	6406                	ld	s0,64(sp)
    800054e0:	74e2                	ld	s1,56(sp)
    800054e2:	7942                	ld	s2,48(sp)
    800054e4:	79a2                	ld	s3,40(sp)
    800054e6:	7a02                	ld	s4,32(sp)
    800054e8:	6ae2                	ld	s5,24(sp)
    800054ea:	6b42                	ld	s6,16(sp)
    800054ec:	6161                	addi	sp,sp,80
    800054ee:	8082                	ret
      release(&pi->lock);
    800054f0:	8526                	mv	a0,s1
    800054f2:	ffffc097          	auipc	ra,0xffffc
    800054f6:	826080e7          	jalr	-2010(ra) # 80000d18 <release>
      return -1;
    800054fa:	59fd                	li	s3,-1
    800054fc:	bff9                	j	800054da <piperead+0xc8>

00000000800054fe <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800054fe:	1141                	addi	sp,sp,-16
    80005500:	e422                	sd	s0,8(sp)
    80005502:	0800                	addi	s0,sp,16
    80005504:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005506:	8905                	andi	a0,a0,1
    80005508:	c111                	beqz	a0,8000550c <flags2perm+0xe>
      perm = PTE_X;
    8000550a:	4521                	li	a0,8
    if(flags & 0x2)
    8000550c:	8b89                	andi	a5,a5,2
    8000550e:	c399                	beqz	a5,80005514 <flags2perm+0x16>
      perm |= PTE_W;
    80005510:	00456513          	ori	a0,a0,4
    return perm;
}
    80005514:	6422                	ld	s0,8(sp)
    80005516:	0141                	addi	sp,sp,16
    80005518:	8082                	ret

000000008000551a <exec>:

int
exec(char *path, char **argv)
{
    8000551a:	de010113          	addi	sp,sp,-544
    8000551e:	20113c23          	sd	ra,536(sp)
    80005522:	20813823          	sd	s0,528(sp)
    80005526:	20913423          	sd	s1,520(sp)
    8000552a:	21213023          	sd	s2,512(sp)
    8000552e:	ffce                	sd	s3,504(sp)
    80005530:	fbd2                	sd	s4,496(sp)
    80005532:	f7d6                	sd	s5,488(sp)
    80005534:	f3da                	sd	s6,480(sp)
    80005536:	efde                	sd	s7,472(sp)
    80005538:	ebe2                	sd	s8,464(sp)
    8000553a:	e7e6                	sd	s9,456(sp)
    8000553c:	e3ea                	sd	s10,448(sp)
    8000553e:	ff6e                	sd	s11,440(sp)
    80005540:	1400                	addi	s0,sp,544
    80005542:	892a                	mv	s2,a0
    80005544:	dea43423          	sd	a0,-536(s0)
    80005548:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000554c:	ffffc097          	auipc	ra,0xffffc
    80005550:	5ac080e7          	jalr	1452(ra) # 80001af8 <myproc>
    80005554:	84aa                	mv	s1,a0

  begin_op();
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	47e080e7          	jalr	1150(ra) # 800049d4 <begin_op>

  if((ip = namei(path)) == 0){
    8000555e:	854a                	mv	a0,s2
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	258080e7          	jalr	600(ra) # 800047b8 <namei>
    80005568:	c93d                	beqz	a0,800055de <exec+0xc4>
    8000556a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	aa6080e7          	jalr	-1370(ra) # 80004012 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005574:	04000713          	li	a4,64
    80005578:	4681                	li	a3,0
    8000557a:	e5040613          	addi	a2,s0,-432
    8000557e:	4581                	li	a1,0
    80005580:	8556                	mv	a0,s5
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	d44080e7          	jalr	-700(ra) # 800042c6 <readi>
    8000558a:	04000793          	li	a5,64
    8000558e:	00f51a63          	bne	a0,a5,800055a2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005592:	e5042703          	lw	a4,-432(s0)
    80005596:	464c47b7          	lui	a5,0x464c4
    8000559a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000559e:	04f70663          	beq	a4,a5,800055ea <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800055a2:	8556                	mv	a0,s5
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	cd0080e7          	jalr	-816(ra) # 80004274 <iunlockput>
    end_op();
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	4a8080e7          	jalr	1192(ra) # 80004a54 <end_op>
  }
  return -1;
    800055b4:	557d                	li	a0,-1
}
    800055b6:	21813083          	ld	ra,536(sp)
    800055ba:	21013403          	ld	s0,528(sp)
    800055be:	20813483          	ld	s1,520(sp)
    800055c2:	20013903          	ld	s2,512(sp)
    800055c6:	79fe                	ld	s3,504(sp)
    800055c8:	7a5e                	ld	s4,496(sp)
    800055ca:	7abe                	ld	s5,488(sp)
    800055cc:	7b1e                	ld	s6,480(sp)
    800055ce:	6bfe                	ld	s7,472(sp)
    800055d0:	6c5e                	ld	s8,464(sp)
    800055d2:	6cbe                	ld	s9,456(sp)
    800055d4:	6d1e                	ld	s10,448(sp)
    800055d6:	7dfa                	ld	s11,440(sp)
    800055d8:	22010113          	addi	sp,sp,544
    800055dc:	8082                	ret
    end_op();
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	476080e7          	jalr	1142(ra) # 80004a54 <end_op>
    return -1;
    800055e6:	557d                	li	a0,-1
    800055e8:	b7f9                	j	800055b6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffc097          	auipc	ra,0xffffc
    800055f0:	5d0080e7          	jalr	1488(ra) # 80001bbc <proc_pagetable>
    800055f4:	8b2a                	mv	s6,a0
    800055f6:	d555                	beqz	a0,800055a2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055f8:	e7042783          	lw	a5,-400(s0)
    800055fc:	e8845703          	lhu	a4,-376(s0)
    80005600:	c735                	beqz	a4,8000566c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005602:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005604:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005608:	6a05                	lui	s4,0x1
    8000560a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000560e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005612:	6d85                	lui	s11,0x1
    80005614:	7d7d                	lui	s10,0xfffff
    80005616:	a481                	j	80005856 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005618:	00003517          	auipc	a0,0x3
    8000561c:	21050513          	addi	a0,a0,528 # 80008828 <syscalls+0x2a8>
    80005620:	ffffb097          	auipc	ra,0xffffb
    80005624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005628:	874a                	mv	a4,s2
    8000562a:	009c86bb          	addw	a3,s9,s1
    8000562e:	4581                	li	a1,0
    80005630:	8556                	mv	a0,s5
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	c94080e7          	jalr	-876(ra) # 800042c6 <readi>
    8000563a:	2501                	sext.w	a0,a0
    8000563c:	1aa91a63          	bne	s2,a0,800057f0 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005640:	009d84bb          	addw	s1,s11,s1
    80005644:	013d09bb          	addw	s3,s10,s3
    80005648:	1f74f763          	bgeu	s1,s7,80005836 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000564c:	02049593          	slli	a1,s1,0x20
    80005650:	9181                	srli	a1,a1,0x20
    80005652:	95e2                	add	a1,a1,s8
    80005654:	855a                	mv	a0,s6
    80005656:	ffffc097          	auipc	ra,0xffffc
    8000565a:	a94080e7          	jalr	-1388(ra) # 800010ea <walkaddr>
    8000565e:	862a                	mv	a2,a0
    if(pa == 0)
    80005660:	dd45                	beqz	a0,80005618 <exec+0xfe>
      n = PGSIZE;
    80005662:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005664:	fd49f2e3          	bgeu	s3,s4,80005628 <exec+0x10e>
      n = sz - i;
    80005668:	894e                	mv	s2,s3
    8000566a:	bf7d                	j	80005628 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000566c:	4901                	li	s2,0
  iunlockput(ip);
    8000566e:	8556                	mv	a0,s5
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	c04080e7          	jalr	-1020(ra) # 80004274 <iunlockput>
  end_op();
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	3dc080e7          	jalr	988(ra) # 80004a54 <end_op>
  p = myproc();
    80005680:	ffffc097          	auipc	ra,0xffffc
    80005684:	478080e7          	jalr	1144(ra) # 80001af8 <myproc>
    80005688:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000568a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000568e:	6785                	lui	a5,0x1
    80005690:	17fd                	addi	a5,a5,-1
    80005692:	993e                	add	s2,s2,a5
    80005694:	77fd                	lui	a5,0xfffff
    80005696:	00f977b3          	and	a5,s2,a5
    8000569a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000569e:	4691                	li	a3,4
    800056a0:	6609                	lui	a2,0x2
    800056a2:	963e                	add	a2,a2,a5
    800056a4:	85be                	mv	a1,a5
    800056a6:	855a                	mv	a0,s6
    800056a8:	ffffc097          	auipc	ra,0xffffc
    800056ac:	dfc080e7          	jalr	-516(ra) # 800014a4 <uvmalloc>
    800056b0:	8c2a                	mv	s8,a0
  ip = 0;
    800056b2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800056b4:	12050e63          	beqz	a0,800057f0 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800056b8:	75f9                	lui	a1,0xffffe
    800056ba:	95aa                	add	a1,a1,a0
    800056bc:	855a                	mv	a0,s6
    800056be:	ffffc097          	auipc	ra,0xffffc
    800056c2:	ffe080e7          	jalr	-2(ra) # 800016bc <uvmclear>
  stackbase = sp - PGSIZE;
    800056c6:	7afd                	lui	s5,0xfffff
    800056c8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800056ca:	df043783          	ld	a5,-528(s0)
    800056ce:	6388                	ld	a0,0(a5)
    800056d0:	c925                	beqz	a0,80005740 <exec+0x226>
    800056d2:	e9040993          	addi	s3,s0,-368
    800056d6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800056da:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800056dc:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800056de:	ffffb097          	auipc	ra,0xffffb
    800056e2:	7fe080e7          	jalr	2046(ra) # 80000edc <strlen>
    800056e6:	0015079b          	addiw	a5,a0,1
    800056ea:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800056ee:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800056f2:	13596663          	bltu	s2,s5,8000581e <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800056f6:	df043d83          	ld	s11,-528(s0)
    800056fa:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800056fe:	8552                	mv	a0,s4
    80005700:	ffffb097          	auipc	ra,0xffffb
    80005704:	7dc080e7          	jalr	2012(ra) # 80000edc <strlen>
    80005708:	0015069b          	addiw	a3,a0,1
    8000570c:	8652                	mv	a2,s4
    8000570e:	85ca                	mv	a1,s2
    80005710:	855a                	mv	a0,s6
    80005712:	ffffc097          	auipc	ra,0xffffc
    80005716:	fdc080e7          	jalr	-36(ra) # 800016ee <copyout>
    8000571a:	10054663          	bltz	a0,80005826 <exec+0x30c>
    ustack[argc] = sp;
    8000571e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005722:	0485                	addi	s1,s1,1
    80005724:	008d8793          	addi	a5,s11,8
    80005728:	def43823          	sd	a5,-528(s0)
    8000572c:	008db503          	ld	a0,8(s11)
    80005730:	c911                	beqz	a0,80005744 <exec+0x22a>
    if(argc >= MAXARG)
    80005732:	09a1                	addi	s3,s3,8
    80005734:	fb3c95e3          	bne	s9,s3,800056de <exec+0x1c4>
  sz = sz1;
    80005738:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000573c:	4a81                	li	s5,0
    8000573e:	a84d                	j	800057f0 <exec+0x2d6>
  sp = sz;
    80005740:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005742:	4481                	li	s1,0
  ustack[argc] = 0;
    80005744:	00349793          	slli	a5,s1,0x3
    80005748:	f9040713          	addi	a4,s0,-112
    8000574c:	97ba                	add	a5,a5,a4
    8000574e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffb60d0>
  sp -= (argc+1) * sizeof(uint64);
    80005752:	00148693          	addi	a3,s1,1
    80005756:	068e                	slli	a3,a3,0x3
    80005758:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000575c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005760:	01597663          	bgeu	s2,s5,8000576c <exec+0x252>
  sz = sz1;
    80005764:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005768:	4a81                	li	s5,0
    8000576a:	a059                	j	800057f0 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000576c:	e9040613          	addi	a2,s0,-368
    80005770:	85ca                	mv	a1,s2
    80005772:	855a                	mv	a0,s6
    80005774:	ffffc097          	auipc	ra,0xffffc
    80005778:	f7a080e7          	jalr	-134(ra) # 800016ee <copyout>
    8000577c:	0a054963          	bltz	a0,8000582e <exec+0x314>
  p->trapframe->a1 = sp;
    80005780:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005784:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005788:	de843783          	ld	a5,-536(s0)
    8000578c:	0007c703          	lbu	a4,0(a5)
    80005790:	cf11                	beqz	a4,800057ac <exec+0x292>
    80005792:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005794:	02f00693          	li	a3,47
    80005798:	a039                	j	800057a6 <exec+0x28c>
      last = s+1;
    8000579a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000579e:	0785                	addi	a5,a5,1
    800057a0:	fff7c703          	lbu	a4,-1(a5)
    800057a4:	c701                	beqz	a4,800057ac <exec+0x292>
    if(*s == '/')
    800057a6:	fed71ce3          	bne	a4,a3,8000579e <exec+0x284>
    800057aa:	bfc5                	j	8000579a <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800057ac:	4641                	li	a2,16
    800057ae:	de843583          	ld	a1,-536(s0)
    800057b2:	158b8513          	addi	a0,s7,344
    800057b6:	ffffb097          	auipc	ra,0xffffb
    800057ba:	6f4080e7          	jalr	1780(ra) # 80000eaa <safestrcpy>
  oldpagetable = p->pagetable;
    800057be:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800057c2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800057c6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800057ca:	058bb783          	ld	a5,88(s7)
    800057ce:	e6843703          	ld	a4,-408(s0)
    800057d2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800057d4:	058bb783          	ld	a5,88(s7)
    800057d8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800057dc:	85ea                	mv	a1,s10
    800057de:	ffffc097          	auipc	ra,0xffffc
    800057e2:	47a080e7          	jalr	1146(ra) # 80001c58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800057e6:	0004851b          	sext.w	a0,s1
    800057ea:	b3f1                	j	800055b6 <exec+0x9c>
    800057ec:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800057f0:	df843583          	ld	a1,-520(s0)
    800057f4:	855a                	mv	a0,s6
    800057f6:	ffffc097          	auipc	ra,0xffffc
    800057fa:	462080e7          	jalr	1122(ra) # 80001c58 <proc_freepagetable>
  if(ip){
    800057fe:	da0a92e3          	bnez	s5,800055a2 <exec+0x88>
  return -1;
    80005802:	557d                	li	a0,-1
    80005804:	bb4d                	j	800055b6 <exec+0x9c>
    80005806:	df243c23          	sd	s2,-520(s0)
    8000580a:	b7dd                	j	800057f0 <exec+0x2d6>
    8000580c:	df243c23          	sd	s2,-520(s0)
    80005810:	b7c5                	j	800057f0 <exec+0x2d6>
    80005812:	df243c23          	sd	s2,-520(s0)
    80005816:	bfe9                	j	800057f0 <exec+0x2d6>
    80005818:	df243c23          	sd	s2,-520(s0)
    8000581c:	bfd1                	j	800057f0 <exec+0x2d6>
  sz = sz1;
    8000581e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005822:	4a81                	li	s5,0
    80005824:	b7f1                	j	800057f0 <exec+0x2d6>
  sz = sz1;
    80005826:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000582a:	4a81                	li	s5,0
    8000582c:	b7d1                	j	800057f0 <exec+0x2d6>
  sz = sz1;
    8000582e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005832:	4a81                	li	s5,0
    80005834:	bf75                	j	800057f0 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005836:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000583a:	e0843783          	ld	a5,-504(s0)
    8000583e:	0017869b          	addiw	a3,a5,1
    80005842:	e0d43423          	sd	a3,-504(s0)
    80005846:	e0043783          	ld	a5,-512(s0)
    8000584a:	0387879b          	addiw	a5,a5,56
    8000584e:	e8845703          	lhu	a4,-376(s0)
    80005852:	e0e6dee3          	bge	a3,a4,8000566e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005856:	2781                	sext.w	a5,a5
    80005858:	e0f43023          	sd	a5,-512(s0)
    8000585c:	03800713          	li	a4,56
    80005860:	86be                	mv	a3,a5
    80005862:	e1840613          	addi	a2,s0,-488
    80005866:	4581                	li	a1,0
    80005868:	8556                	mv	a0,s5
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	a5c080e7          	jalr	-1444(ra) # 800042c6 <readi>
    80005872:	03800793          	li	a5,56
    80005876:	f6f51be3          	bne	a0,a5,800057ec <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000587a:	e1842783          	lw	a5,-488(s0)
    8000587e:	4705                	li	a4,1
    80005880:	fae79de3          	bne	a5,a4,8000583a <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005884:	e4043483          	ld	s1,-448(s0)
    80005888:	e3843783          	ld	a5,-456(s0)
    8000588c:	f6f4ede3          	bltu	s1,a5,80005806 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005890:	e2843783          	ld	a5,-472(s0)
    80005894:	94be                	add	s1,s1,a5
    80005896:	f6f4ebe3          	bltu	s1,a5,8000580c <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000589a:	de043703          	ld	a4,-544(s0)
    8000589e:	8ff9                	and	a5,a5,a4
    800058a0:	fbad                	bnez	a5,80005812 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800058a2:	e1c42503          	lw	a0,-484(s0)
    800058a6:	00000097          	auipc	ra,0x0
    800058aa:	c58080e7          	jalr	-936(ra) # 800054fe <flags2perm>
    800058ae:	86aa                	mv	a3,a0
    800058b0:	8626                	mv	a2,s1
    800058b2:	85ca                	mv	a1,s2
    800058b4:	855a                	mv	a0,s6
    800058b6:	ffffc097          	auipc	ra,0xffffc
    800058ba:	bee080e7          	jalr	-1042(ra) # 800014a4 <uvmalloc>
    800058be:	dea43c23          	sd	a0,-520(s0)
    800058c2:	d939                	beqz	a0,80005818 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800058c4:	e2843c03          	ld	s8,-472(s0)
    800058c8:	e2042c83          	lw	s9,-480(s0)
    800058cc:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800058d0:	f60b83e3          	beqz	s7,80005836 <exec+0x31c>
    800058d4:	89de                	mv	s3,s7
    800058d6:	4481                	li	s1,0
    800058d8:	bb95                	j	8000564c <exec+0x132>

00000000800058da <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800058da:	7179                	addi	sp,sp,-48
    800058dc:	f406                	sd	ra,40(sp)
    800058de:	f022                	sd	s0,32(sp)
    800058e0:	ec26                	sd	s1,24(sp)
    800058e2:	e84a                	sd	s2,16(sp)
    800058e4:	1800                	addi	s0,sp,48
    800058e6:	892e                	mv	s2,a1
    800058e8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800058ea:	fdc40593          	addi	a1,s0,-36
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	878080e7          	jalr	-1928(ra) # 80003166 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800058f6:	fdc42703          	lw	a4,-36(s0)
    800058fa:	47bd                	li	a5,15
    800058fc:	02e7eb63          	bltu	a5,a4,80005932 <argfd+0x58>
    80005900:	ffffc097          	auipc	ra,0xffffc
    80005904:	1f8080e7          	jalr	504(ra) # 80001af8 <myproc>
    80005908:	fdc42703          	lw	a4,-36(s0)
    8000590c:	01a70793          	addi	a5,a4,26
    80005910:	078e                	slli	a5,a5,0x3
    80005912:	953e                	add	a0,a0,a5
    80005914:	611c                	ld	a5,0(a0)
    80005916:	c385                	beqz	a5,80005936 <argfd+0x5c>
    return -1;
  if(pfd)
    80005918:	00090463          	beqz	s2,80005920 <argfd+0x46>
    *pfd = fd;
    8000591c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005920:	4501                	li	a0,0
  if(pf)
    80005922:	c091                	beqz	s1,80005926 <argfd+0x4c>
    *pf = f;
    80005924:	e09c                	sd	a5,0(s1)
}
    80005926:	70a2                	ld	ra,40(sp)
    80005928:	7402                	ld	s0,32(sp)
    8000592a:	64e2                	ld	s1,24(sp)
    8000592c:	6942                	ld	s2,16(sp)
    8000592e:	6145                	addi	sp,sp,48
    80005930:	8082                	ret
    return -1;
    80005932:	557d                	li	a0,-1
    80005934:	bfcd                	j	80005926 <argfd+0x4c>
    80005936:	557d                	li	a0,-1
    80005938:	b7fd                	j	80005926 <argfd+0x4c>

000000008000593a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000593a:	1101                	addi	sp,sp,-32
    8000593c:	ec06                	sd	ra,24(sp)
    8000593e:	e822                	sd	s0,16(sp)
    80005940:	e426                	sd	s1,8(sp)
    80005942:	1000                	addi	s0,sp,32
    80005944:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005946:	ffffc097          	auipc	ra,0xffffc
    8000594a:	1b2080e7          	jalr	434(ra) # 80001af8 <myproc>
    8000594e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005950:	0d050793          	addi	a5,a0,208
    80005954:	4501                	li	a0,0
    80005956:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005958:	6398                	ld	a4,0(a5)
    8000595a:	cb19                	beqz	a4,80005970 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000595c:	2505                	addiw	a0,a0,1
    8000595e:	07a1                	addi	a5,a5,8
    80005960:	fed51ce3          	bne	a0,a3,80005958 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005964:	557d                	li	a0,-1
}
    80005966:	60e2                	ld	ra,24(sp)
    80005968:	6442                	ld	s0,16(sp)
    8000596a:	64a2                	ld	s1,8(sp)
    8000596c:	6105                	addi	sp,sp,32
    8000596e:	8082                	ret
      p->ofile[fd] = f;
    80005970:	01a50793          	addi	a5,a0,26
    80005974:	078e                	slli	a5,a5,0x3
    80005976:	963e                	add	a2,a2,a5
    80005978:	e204                	sd	s1,0(a2)
      return fd;
    8000597a:	b7f5                	j	80005966 <fdalloc+0x2c>

000000008000597c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000597c:	715d                	addi	sp,sp,-80
    8000597e:	e486                	sd	ra,72(sp)
    80005980:	e0a2                	sd	s0,64(sp)
    80005982:	fc26                	sd	s1,56(sp)
    80005984:	f84a                	sd	s2,48(sp)
    80005986:	f44e                	sd	s3,40(sp)
    80005988:	f052                	sd	s4,32(sp)
    8000598a:	ec56                	sd	s5,24(sp)
    8000598c:	e85a                	sd	s6,16(sp)
    8000598e:	0880                	addi	s0,sp,80
    80005990:	8b2e                	mv	s6,a1
    80005992:	89b2                	mv	s3,a2
    80005994:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005996:	fb040593          	addi	a1,s0,-80
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	e3c080e7          	jalr	-452(ra) # 800047d6 <nameiparent>
    800059a2:	84aa                	mv	s1,a0
    800059a4:	14050f63          	beqz	a0,80005b02 <create+0x186>
    return 0;

  ilock(dp);
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	66a080e7          	jalr	1642(ra) # 80004012 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800059b0:	4601                	li	a2,0
    800059b2:	fb040593          	addi	a1,s0,-80
    800059b6:	8526                	mv	a0,s1
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	b3e080e7          	jalr	-1218(ra) # 800044f6 <dirlookup>
    800059c0:	8aaa                	mv	s5,a0
    800059c2:	c931                	beqz	a0,80005a16 <create+0x9a>
    iunlockput(dp);
    800059c4:	8526                	mv	a0,s1
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	8ae080e7          	jalr	-1874(ra) # 80004274 <iunlockput>
    ilock(ip);
    800059ce:	8556                	mv	a0,s5
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	642080e7          	jalr	1602(ra) # 80004012 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800059d8:	000b059b          	sext.w	a1,s6
    800059dc:	4789                	li	a5,2
    800059de:	02f59563          	bne	a1,a5,80005a08 <create+0x8c>
    800059e2:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffb6214>
    800059e6:	37f9                	addiw	a5,a5,-2
    800059e8:	17c2                	slli	a5,a5,0x30
    800059ea:	93c1                	srli	a5,a5,0x30
    800059ec:	4705                	li	a4,1
    800059ee:	00f76d63          	bltu	a4,a5,80005a08 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800059f2:	8556                	mv	a0,s5
    800059f4:	60a6                	ld	ra,72(sp)
    800059f6:	6406                	ld	s0,64(sp)
    800059f8:	74e2                	ld	s1,56(sp)
    800059fa:	7942                	ld	s2,48(sp)
    800059fc:	79a2                	ld	s3,40(sp)
    800059fe:	7a02                	ld	s4,32(sp)
    80005a00:	6ae2                	ld	s5,24(sp)
    80005a02:	6b42                	ld	s6,16(sp)
    80005a04:	6161                	addi	sp,sp,80
    80005a06:	8082                	ret
    iunlockput(ip);
    80005a08:	8556                	mv	a0,s5
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	86a080e7          	jalr	-1942(ra) # 80004274 <iunlockput>
    return 0;
    80005a12:	4a81                	li	s5,0
    80005a14:	bff9                	j	800059f2 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005a16:	85da                	mv	a1,s6
    80005a18:	4088                	lw	a0,0(s1)
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	45c080e7          	jalr	1116(ra) # 80003e76 <ialloc>
    80005a22:	8a2a                	mv	s4,a0
    80005a24:	c539                	beqz	a0,80005a72 <create+0xf6>
  ilock(ip);
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	5ec080e7          	jalr	1516(ra) # 80004012 <ilock>
  ip->major = major;
    80005a2e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005a32:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005a36:	4905                	li	s2,1
    80005a38:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005a3c:	8552                	mv	a0,s4
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	50a080e7          	jalr	1290(ra) # 80003f48 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a46:	000b059b          	sext.w	a1,s6
    80005a4a:	03258b63          	beq	a1,s2,80005a80 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a4e:	004a2603          	lw	a2,4(s4)
    80005a52:	fb040593          	addi	a1,s0,-80
    80005a56:	8526                	mv	a0,s1
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	cae080e7          	jalr	-850(ra) # 80004706 <dirlink>
    80005a60:	06054f63          	bltz	a0,80005ade <create+0x162>
  iunlockput(dp);
    80005a64:	8526                	mv	a0,s1
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	80e080e7          	jalr	-2034(ra) # 80004274 <iunlockput>
  return ip;
    80005a6e:	8ad2                	mv	s5,s4
    80005a70:	b749                	j	800059f2 <create+0x76>
    iunlockput(dp);
    80005a72:	8526                	mv	a0,s1
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	800080e7          	jalr	-2048(ra) # 80004274 <iunlockput>
    return 0;
    80005a7c:	8ad2                	mv	s5,s4
    80005a7e:	bf95                	j	800059f2 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a80:	004a2603          	lw	a2,4(s4)
    80005a84:	00003597          	auipc	a1,0x3
    80005a88:	dc458593          	addi	a1,a1,-572 # 80008848 <syscalls+0x2c8>
    80005a8c:	8552                	mv	a0,s4
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	c78080e7          	jalr	-904(ra) # 80004706 <dirlink>
    80005a96:	04054463          	bltz	a0,80005ade <create+0x162>
    80005a9a:	40d0                	lw	a2,4(s1)
    80005a9c:	00003597          	auipc	a1,0x3
    80005aa0:	db458593          	addi	a1,a1,-588 # 80008850 <syscalls+0x2d0>
    80005aa4:	8552                	mv	a0,s4
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	c60080e7          	jalr	-928(ra) # 80004706 <dirlink>
    80005aae:	02054863          	bltz	a0,80005ade <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ab2:	004a2603          	lw	a2,4(s4)
    80005ab6:	fb040593          	addi	a1,s0,-80
    80005aba:	8526                	mv	a0,s1
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	c4a080e7          	jalr	-950(ra) # 80004706 <dirlink>
    80005ac4:	00054d63          	bltz	a0,80005ade <create+0x162>
    dp->nlink++;  // for ".."
    80005ac8:	04a4d783          	lhu	a5,74(s1)
    80005acc:	2785                	addiw	a5,a5,1
    80005ace:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ad2:	8526                	mv	a0,s1
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	474080e7          	jalr	1140(ra) # 80003f48 <iupdate>
    80005adc:	b761                	j	80005a64 <create+0xe8>
  ip->nlink = 0;
    80005ade:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005ae2:	8552                	mv	a0,s4
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	464080e7          	jalr	1124(ra) # 80003f48 <iupdate>
  iunlockput(ip);
    80005aec:	8552                	mv	a0,s4
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	786080e7          	jalr	1926(ra) # 80004274 <iunlockput>
  iunlockput(dp);
    80005af6:	8526                	mv	a0,s1
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	77c080e7          	jalr	1916(ra) # 80004274 <iunlockput>
  return 0;
    80005b00:	bdcd                	j	800059f2 <create+0x76>
    return 0;
    80005b02:	8aaa                	mv	s5,a0
    80005b04:	b5fd                	j	800059f2 <create+0x76>

0000000080005b06 <sys_dup>:
{
    80005b06:	7179                	addi	sp,sp,-48
    80005b08:	f406                	sd	ra,40(sp)
    80005b0a:	f022                	sd	s0,32(sp)
    80005b0c:	ec26                	sd	s1,24(sp)
    80005b0e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005b10:	fd840613          	addi	a2,s0,-40
    80005b14:	4581                	li	a1,0
    80005b16:	4501                	li	a0,0
    80005b18:	00000097          	auipc	ra,0x0
    80005b1c:	dc2080e7          	jalr	-574(ra) # 800058da <argfd>
    return -1;
    80005b20:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b22:	02054363          	bltz	a0,80005b48 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005b26:	fd843503          	ld	a0,-40(s0)
    80005b2a:	00000097          	auipc	ra,0x0
    80005b2e:	e10080e7          	jalr	-496(ra) # 8000593a <fdalloc>
    80005b32:	84aa                	mv	s1,a0
    return -1;
    80005b34:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b36:	00054963          	bltz	a0,80005b48 <sys_dup+0x42>
  filedup(f);
    80005b3a:	fd843503          	ld	a0,-40(s0)
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	310080e7          	jalr	784(ra) # 80004e4e <filedup>
  return fd;
    80005b46:	87a6                	mv	a5,s1
}
    80005b48:	853e                	mv	a0,a5
    80005b4a:	70a2                	ld	ra,40(sp)
    80005b4c:	7402                	ld	s0,32(sp)
    80005b4e:	64e2                	ld	s1,24(sp)
    80005b50:	6145                	addi	sp,sp,48
    80005b52:	8082                	ret

0000000080005b54 <sys_read>:
{
    80005b54:	7179                	addi	sp,sp,-48
    80005b56:	f406                	sd	ra,40(sp)
    80005b58:	f022                	sd	s0,32(sp)
    80005b5a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005b5c:	fd840593          	addi	a1,s0,-40
    80005b60:	4505                	li	a0,1
    80005b62:	ffffd097          	auipc	ra,0xffffd
    80005b66:	624080e7          	jalr	1572(ra) # 80003186 <argaddr>
  argint(2, &n);
    80005b6a:	fe440593          	addi	a1,s0,-28
    80005b6e:	4509                	li	a0,2
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	5f6080e7          	jalr	1526(ra) # 80003166 <argint>
  if(argfd(0, 0, &f) < 0)
    80005b78:	fe840613          	addi	a2,s0,-24
    80005b7c:	4581                	li	a1,0
    80005b7e:	4501                	li	a0,0
    80005b80:	00000097          	auipc	ra,0x0
    80005b84:	d5a080e7          	jalr	-678(ra) # 800058da <argfd>
    80005b88:	87aa                	mv	a5,a0
    return -1;
    80005b8a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b8c:	0007cc63          	bltz	a5,80005ba4 <sys_read+0x50>
  return fileread(f, p, n);
    80005b90:	fe442603          	lw	a2,-28(s0)
    80005b94:	fd843583          	ld	a1,-40(s0)
    80005b98:	fe843503          	ld	a0,-24(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	43e080e7          	jalr	1086(ra) # 80004fda <fileread>
}
    80005ba4:	70a2                	ld	ra,40(sp)
    80005ba6:	7402                	ld	s0,32(sp)
    80005ba8:	6145                	addi	sp,sp,48
    80005baa:	8082                	ret

0000000080005bac <sys_write>:
{
    80005bac:	7179                	addi	sp,sp,-48
    80005bae:	f406                	sd	ra,40(sp)
    80005bb0:	f022                	sd	s0,32(sp)
    80005bb2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005bb4:	fd840593          	addi	a1,s0,-40
    80005bb8:	4505                	li	a0,1
    80005bba:	ffffd097          	auipc	ra,0xffffd
    80005bbe:	5cc080e7          	jalr	1484(ra) # 80003186 <argaddr>
  argint(2, &n);
    80005bc2:	fe440593          	addi	a1,s0,-28
    80005bc6:	4509                	li	a0,2
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	59e080e7          	jalr	1438(ra) # 80003166 <argint>
  if(argfd(0, 0, &f) < 0)
    80005bd0:	fe840613          	addi	a2,s0,-24
    80005bd4:	4581                	li	a1,0
    80005bd6:	4501                	li	a0,0
    80005bd8:	00000097          	auipc	ra,0x0
    80005bdc:	d02080e7          	jalr	-766(ra) # 800058da <argfd>
    80005be0:	87aa                	mv	a5,a0
    return -1;
    80005be2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005be4:	0007cc63          	bltz	a5,80005bfc <sys_write+0x50>
  return filewrite(f, p, n);
    80005be8:	fe442603          	lw	a2,-28(s0)
    80005bec:	fd843583          	ld	a1,-40(s0)
    80005bf0:	fe843503          	ld	a0,-24(s0)
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	4a8080e7          	jalr	1192(ra) # 8000509c <filewrite>
}
    80005bfc:	70a2                	ld	ra,40(sp)
    80005bfe:	7402                	ld	s0,32(sp)
    80005c00:	6145                	addi	sp,sp,48
    80005c02:	8082                	ret

0000000080005c04 <sys_close>:
{
    80005c04:	1101                	addi	sp,sp,-32
    80005c06:	ec06                	sd	ra,24(sp)
    80005c08:	e822                	sd	s0,16(sp)
    80005c0a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005c0c:	fe040613          	addi	a2,s0,-32
    80005c10:	fec40593          	addi	a1,s0,-20
    80005c14:	4501                	li	a0,0
    80005c16:	00000097          	auipc	ra,0x0
    80005c1a:	cc4080e7          	jalr	-828(ra) # 800058da <argfd>
    return -1;
    80005c1e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c20:	02054463          	bltz	a0,80005c48 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c24:	ffffc097          	auipc	ra,0xffffc
    80005c28:	ed4080e7          	jalr	-300(ra) # 80001af8 <myproc>
    80005c2c:	fec42783          	lw	a5,-20(s0)
    80005c30:	07e9                	addi	a5,a5,26
    80005c32:	078e                	slli	a5,a5,0x3
    80005c34:	97aa                	add	a5,a5,a0
    80005c36:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005c3a:	fe043503          	ld	a0,-32(s0)
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	262080e7          	jalr	610(ra) # 80004ea0 <fileclose>
  return 0;
    80005c46:	4781                	li	a5,0
}
    80005c48:	853e                	mv	a0,a5
    80005c4a:	60e2                	ld	ra,24(sp)
    80005c4c:	6442                	ld	s0,16(sp)
    80005c4e:	6105                	addi	sp,sp,32
    80005c50:	8082                	ret

0000000080005c52 <sys_fstat>:
{
    80005c52:	1101                	addi	sp,sp,-32
    80005c54:	ec06                	sd	ra,24(sp)
    80005c56:	e822                	sd	s0,16(sp)
    80005c58:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005c5a:	fe040593          	addi	a1,s0,-32
    80005c5e:	4505                	li	a0,1
    80005c60:	ffffd097          	auipc	ra,0xffffd
    80005c64:	526080e7          	jalr	1318(ra) # 80003186 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005c68:	fe840613          	addi	a2,s0,-24
    80005c6c:	4581                	li	a1,0
    80005c6e:	4501                	li	a0,0
    80005c70:	00000097          	auipc	ra,0x0
    80005c74:	c6a080e7          	jalr	-918(ra) # 800058da <argfd>
    80005c78:	87aa                	mv	a5,a0
    return -1;
    80005c7a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005c7c:	0007ca63          	bltz	a5,80005c90 <sys_fstat+0x3e>
  return filestat(f, st);
    80005c80:	fe043583          	ld	a1,-32(s0)
    80005c84:	fe843503          	ld	a0,-24(s0)
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	2e0080e7          	jalr	736(ra) # 80004f68 <filestat>
}
    80005c90:	60e2                	ld	ra,24(sp)
    80005c92:	6442                	ld	s0,16(sp)
    80005c94:	6105                	addi	sp,sp,32
    80005c96:	8082                	ret

0000000080005c98 <sys_link>:
{
    80005c98:	7169                	addi	sp,sp,-304
    80005c9a:	f606                	sd	ra,296(sp)
    80005c9c:	f222                	sd	s0,288(sp)
    80005c9e:	ee26                	sd	s1,280(sp)
    80005ca0:	ea4a                	sd	s2,272(sp)
    80005ca2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ca4:	08000613          	li	a2,128
    80005ca8:	ed040593          	addi	a1,s0,-304
    80005cac:	4501                	li	a0,0
    80005cae:	ffffd097          	auipc	ra,0xffffd
    80005cb2:	4f8080e7          	jalr	1272(ra) # 800031a6 <argstr>
    return -1;
    80005cb6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cb8:	10054e63          	bltz	a0,80005dd4 <sys_link+0x13c>
    80005cbc:	08000613          	li	a2,128
    80005cc0:	f5040593          	addi	a1,s0,-176
    80005cc4:	4505                	li	a0,1
    80005cc6:	ffffd097          	auipc	ra,0xffffd
    80005cca:	4e0080e7          	jalr	1248(ra) # 800031a6 <argstr>
    return -1;
    80005cce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cd0:	10054263          	bltz	a0,80005dd4 <sys_link+0x13c>
  begin_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	d00080e7          	jalr	-768(ra) # 800049d4 <begin_op>
  if((ip = namei(old)) == 0){
    80005cdc:	ed040513          	addi	a0,s0,-304
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	ad8080e7          	jalr	-1320(ra) # 800047b8 <namei>
    80005ce8:	84aa                	mv	s1,a0
    80005cea:	c551                	beqz	a0,80005d76 <sys_link+0xde>
  ilock(ip);
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	326080e7          	jalr	806(ra) # 80004012 <ilock>
  if(ip->type == T_DIR){
    80005cf4:	04449703          	lh	a4,68(s1)
    80005cf8:	4785                	li	a5,1
    80005cfa:	08f70463          	beq	a4,a5,80005d82 <sys_link+0xea>
  ip->nlink++;
    80005cfe:	04a4d783          	lhu	a5,74(s1)
    80005d02:	2785                	addiw	a5,a5,1
    80005d04:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d08:	8526                	mv	a0,s1
    80005d0a:	ffffe097          	auipc	ra,0xffffe
    80005d0e:	23e080e7          	jalr	574(ra) # 80003f48 <iupdate>
  iunlock(ip);
    80005d12:	8526                	mv	a0,s1
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	3c0080e7          	jalr	960(ra) # 800040d4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d1c:	fd040593          	addi	a1,s0,-48
    80005d20:	f5040513          	addi	a0,s0,-176
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	ab2080e7          	jalr	-1358(ra) # 800047d6 <nameiparent>
    80005d2c:	892a                	mv	s2,a0
    80005d2e:	c935                	beqz	a0,80005da2 <sys_link+0x10a>
  ilock(dp);
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	2e2080e7          	jalr	738(ra) # 80004012 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d38:	00092703          	lw	a4,0(s2)
    80005d3c:	409c                	lw	a5,0(s1)
    80005d3e:	04f71d63          	bne	a4,a5,80005d98 <sys_link+0x100>
    80005d42:	40d0                	lw	a2,4(s1)
    80005d44:	fd040593          	addi	a1,s0,-48
    80005d48:	854a                	mv	a0,s2
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	9bc080e7          	jalr	-1604(ra) # 80004706 <dirlink>
    80005d52:	04054363          	bltz	a0,80005d98 <sys_link+0x100>
  iunlockput(dp);
    80005d56:	854a                	mv	a0,s2
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	51c080e7          	jalr	1308(ra) # 80004274 <iunlockput>
  iput(ip);
    80005d60:	8526                	mv	a0,s1
    80005d62:	ffffe097          	auipc	ra,0xffffe
    80005d66:	46a080e7          	jalr	1130(ra) # 800041cc <iput>
  end_op();
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	cea080e7          	jalr	-790(ra) # 80004a54 <end_op>
  return 0;
    80005d72:	4781                	li	a5,0
    80005d74:	a085                	j	80005dd4 <sys_link+0x13c>
    end_op();
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	cde080e7          	jalr	-802(ra) # 80004a54 <end_op>
    return -1;
    80005d7e:	57fd                	li	a5,-1
    80005d80:	a891                	j	80005dd4 <sys_link+0x13c>
    iunlockput(ip);
    80005d82:	8526                	mv	a0,s1
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	4f0080e7          	jalr	1264(ra) # 80004274 <iunlockput>
    end_op();
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	cc8080e7          	jalr	-824(ra) # 80004a54 <end_op>
    return -1;
    80005d94:	57fd                	li	a5,-1
    80005d96:	a83d                	j	80005dd4 <sys_link+0x13c>
    iunlockput(dp);
    80005d98:	854a                	mv	a0,s2
    80005d9a:	ffffe097          	auipc	ra,0xffffe
    80005d9e:	4da080e7          	jalr	1242(ra) # 80004274 <iunlockput>
  ilock(ip);
    80005da2:	8526                	mv	a0,s1
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	26e080e7          	jalr	622(ra) # 80004012 <ilock>
  ip->nlink--;
    80005dac:	04a4d783          	lhu	a5,74(s1)
    80005db0:	37fd                	addiw	a5,a5,-1
    80005db2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005db6:	8526                	mv	a0,s1
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	190080e7          	jalr	400(ra) # 80003f48 <iupdate>
  iunlockput(ip);
    80005dc0:	8526                	mv	a0,s1
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	4b2080e7          	jalr	1202(ra) # 80004274 <iunlockput>
  end_op();
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	c8a080e7          	jalr	-886(ra) # 80004a54 <end_op>
  return -1;
    80005dd2:	57fd                	li	a5,-1
}
    80005dd4:	853e                	mv	a0,a5
    80005dd6:	70b2                	ld	ra,296(sp)
    80005dd8:	7412                	ld	s0,288(sp)
    80005dda:	64f2                	ld	s1,280(sp)
    80005ddc:	6952                	ld	s2,272(sp)
    80005dde:	6155                	addi	sp,sp,304
    80005de0:	8082                	ret

0000000080005de2 <sys_unlink>:
{
    80005de2:	7151                	addi	sp,sp,-240
    80005de4:	f586                	sd	ra,232(sp)
    80005de6:	f1a2                	sd	s0,224(sp)
    80005de8:	eda6                	sd	s1,216(sp)
    80005dea:	e9ca                	sd	s2,208(sp)
    80005dec:	e5ce                	sd	s3,200(sp)
    80005dee:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005df0:	08000613          	li	a2,128
    80005df4:	f3040593          	addi	a1,s0,-208
    80005df8:	4501                	li	a0,0
    80005dfa:	ffffd097          	auipc	ra,0xffffd
    80005dfe:	3ac080e7          	jalr	940(ra) # 800031a6 <argstr>
    80005e02:	18054163          	bltz	a0,80005f84 <sys_unlink+0x1a2>
  begin_op();
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	bce080e7          	jalr	-1074(ra) # 800049d4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005e0e:	fb040593          	addi	a1,s0,-80
    80005e12:	f3040513          	addi	a0,s0,-208
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	9c0080e7          	jalr	-1600(ra) # 800047d6 <nameiparent>
    80005e1e:	84aa                	mv	s1,a0
    80005e20:	c979                	beqz	a0,80005ef6 <sys_unlink+0x114>
  ilock(dp);
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	1f0080e7          	jalr	496(ra) # 80004012 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e2a:	00003597          	auipc	a1,0x3
    80005e2e:	a1e58593          	addi	a1,a1,-1506 # 80008848 <syscalls+0x2c8>
    80005e32:	fb040513          	addi	a0,s0,-80
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	6a6080e7          	jalr	1702(ra) # 800044dc <namecmp>
    80005e3e:	14050a63          	beqz	a0,80005f92 <sys_unlink+0x1b0>
    80005e42:	00003597          	auipc	a1,0x3
    80005e46:	a0e58593          	addi	a1,a1,-1522 # 80008850 <syscalls+0x2d0>
    80005e4a:	fb040513          	addi	a0,s0,-80
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	68e080e7          	jalr	1678(ra) # 800044dc <namecmp>
    80005e56:	12050e63          	beqz	a0,80005f92 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e5a:	f2c40613          	addi	a2,s0,-212
    80005e5e:	fb040593          	addi	a1,s0,-80
    80005e62:	8526                	mv	a0,s1
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	692080e7          	jalr	1682(ra) # 800044f6 <dirlookup>
    80005e6c:	892a                	mv	s2,a0
    80005e6e:	12050263          	beqz	a0,80005f92 <sys_unlink+0x1b0>
  ilock(ip);
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	1a0080e7          	jalr	416(ra) # 80004012 <ilock>
  if(ip->nlink < 1)
    80005e7a:	04a91783          	lh	a5,74(s2)
    80005e7e:	08f05263          	blez	a5,80005f02 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e82:	04491703          	lh	a4,68(s2)
    80005e86:	4785                	li	a5,1
    80005e88:	08f70563          	beq	a4,a5,80005f12 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e8c:	4641                	li	a2,16
    80005e8e:	4581                	li	a1,0
    80005e90:	fc040513          	addi	a0,s0,-64
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	ecc080e7          	jalr	-308(ra) # 80000d60 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e9c:	4741                	li	a4,16
    80005e9e:	f2c42683          	lw	a3,-212(s0)
    80005ea2:	fc040613          	addi	a2,s0,-64
    80005ea6:	4581                	li	a1,0
    80005ea8:	8526                	mv	a0,s1
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	514080e7          	jalr	1300(ra) # 800043be <writei>
    80005eb2:	47c1                	li	a5,16
    80005eb4:	0af51563          	bne	a0,a5,80005f5e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005eb8:	04491703          	lh	a4,68(s2)
    80005ebc:	4785                	li	a5,1
    80005ebe:	0af70863          	beq	a4,a5,80005f6e <sys_unlink+0x18c>
  iunlockput(dp);
    80005ec2:	8526                	mv	a0,s1
    80005ec4:	ffffe097          	auipc	ra,0xffffe
    80005ec8:	3b0080e7          	jalr	944(ra) # 80004274 <iunlockput>
  ip->nlink--;
    80005ecc:	04a95783          	lhu	a5,74(s2)
    80005ed0:	37fd                	addiw	a5,a5,-1
    80005ed2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ed6:	854a                	mv	a0,s2
    80005ed8:	ffffe097          	auipc	ra,0xffffe
    80005edc:	070080e7          	jalr	112(ra) # 80003f48 <iupdate>
  iunlockput(ip);
    80005ee0:	854a                	mv	a0,s2
    80005ee2:	ffffe097          	auipc	ra,0xffffe
    80005ee6:	392080e7          	jalr	914(ra) # 80004274 <iunlockput>
  end_op();
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	b6a080e7          	jalr	-1174(ra) # 80004a54 <end_op>
  return 0;
    80005ef2:	4501                	li	a0,0
    80005ef4:	a84d                	j	80005fa6 <sys_unlink+0x1c4>
    end_op();
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	b5e080e7          	jalr	-1186(ra) # 80004a54 <end_op>
    return -1;
    80005efe:	557d                	li	a0,-1
    80005f00:	a05d                	j	80005fa6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	95650513          	addi	a0,a0,-1706 # 80008858 <syscalls+0x2d8>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	634080e7          	jalr	1588(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f12:	04c92703          	lw	a4,76(s2)
    80005f16:	02000793          	li	a5,32
    80005f1a:	f6e7f9e3          	bgeu	a5,a4,80005e8c <sys_unlink+0xaa>
    80005f1e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f22:	4741                	li	a4,16
    80005f24:	86ce                	mv	a3,s3
    80005f26:	f1840613          	addi	a2,s0,-232
    80005f2a:	4581                	li	a1,0
    80005f2c:	854a                	mv	a0,s2
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	398080e7          	jalr	920(ra) # 800042c6 <readi>
    80005f36:	47c1                	li	a5,16
    80005f38:	00f51b63          	bne	a0,a5,80005f4e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005f3c:	f1845783          	lhu	a5,-232(s0)
    80005f40:	e7a1                	bnez	a5,80005f88 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f42:	29c1                	addiw	s3,s3,16
    80005f44:	04c92783          	lw	a5,76(s2)
    80005f48:	fcf9ede3          	bltu	s3,a5,80005f22 <sys_unlink+0x140>
    80005f4c:	b781                	j	80005e8c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005f4e:	00003517          	auipc	a0,0x3
    80005f52:	92250513          	addi	a0,a0,-1758 # 80008870 <syscalls+0x2f0>
    80005f56:	ffffa097          	auipc	ra,0xffffa
    80005f5a:	5e8080e7          	jalr	1512(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005f5e:	00003517          	auipc	a0,0x3
    80005f62:	92a50513          	addi	a0,a0,-1750 # 80008888 <syscalls+0x308>
    80005f66:	ffffa097          	auipc	ra,0xffffa
    80005f6a:	5d8080e7          	jalr	1496(ra) # 8000053e <panic>
    dp->nlink--;
    80005f6e:	04a4d783          	lhu	a5,74(s1)
    80005f72:	37fd                	addiw	a5,a5,-1
    80005f74:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f78:	8526                	mv	a0,s1
    80005f7a:	ffffe097          	auipc	ra,0xffffe
    80005f7e:	fce080e7          	jalr	-50(ra) # 80003f48 <iupdate>
    80005f82:	b781                	j	80005ec2 <sys_unlink+0xe0>
    return -1;
    80005f84:	557d                	li	a0,-1
    80005f86:	a005                	j	80005fa6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f88:	854a                	mv	a0,s2
    80005f8a:	ffffe097          	auipc	ra,0xffffe
    80005f8e:	2ea080e7          	jalr	746(ra) # 80004274 <iunlockput>
  iunlockput(dp);
    80005f92:	8526                	mv	a0,s1
    80005f94:	ffffe097          	auipc	ra,0xffffe
    80005f98:	2e0080e7          	jalr	736(ra) # 80004274 <iunlockput>
  end_op();
    80005f9c:	fffff097          	auipc	ra,0xfffff
    80005fa0:	ab8080e7          	jalr	-1352(ra) # 80004a54 <end_op>
  return -1;
    80005fa4:	557d                	li	a0,-1
}
    80005fa6:	70ae                	ld	ra,232(sp)
    80005fa8:	740e                	ld	s0,224(sp)
    80005faa:	64ee                	ld	s1,216(sp)
    80005fac:	694e                	ld	s2,208(sp)
    80005fae:	69ae                	ld	s3,200(sp)
    80005fb0:	616d                	addi	sp,sp,240
    80005fb2:	8082                	ret

0000000080005fb4 <sys_open>:

uint64
sys_open(void)
{
    80005fb4:	7131                	addi	sp,sp,-192
    80005fb6:	fd06                	sd	ra,184(sp)
    80005fb8:	f922                	sd	s0,176(sp)
    80005fba:	f526                	sd	s1,168(sp)
    80005fbc:	f14a                	sd	s2,160(sp)
    80005fbe:	ed4e                	sd	s3,152(sp)
    80005fc0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005fc2:	f4c40593          	addi	a1,s0,-180
    80005fc6:	4505                	li	a0,1
    80005fc8:	ffffd097          	auipc	ra,0xffffd
    80005fcc:	19e080e7          	jalr	414(ra) # 80003166 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005fd0:	08000613          	li	a2,128
    80005fd4:	f5040593          	addi	a1,s0,-176
    80005fd8:	4501                	li	a0,0
    80005fda:	ffffd097          	auipc	ra,0xffffd
    80005fde:	1cc080e7          	jalr	460(ra) # 800031a6 <argstr>
    80005fe2:	87aa                	mv	a5,a0
    return -1;
    80005fe4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005fe6:	0a07c963          	bltz	a5,80006098 <sys_open+0xe4>

  begin_op();
    80005fea:	fffff097          	auipc	ra,0xfffff
    80005fee:	9ea080e7          	jalr	-1558(ra) # 800049d4 <begin_op>

  if(omode & O_CREATE){
    80005ff2:	f4c42783          	lw	a5,-180(s0)
    80005ff6:	2007f793          	andi	a5,a5,512
    80005ffa:	cfc5                	beqz	a5,800060b2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ffc:	4681                	li	a3,0
    80005ffe:	4601                	li	a2,0
    80006000:	4589                	li	a1,2
    80006002:	f5040513          	addi	a0,s0,-176
    80006006:	00000097          	auipc	ra,0x0
    8000600a:	976080e7          	jalr	-1674(ra) # 8000597c <create>
    8000600e:	84aa                	mv	s1,a0
    if(ip == 0){
    80006010:	c959                	beqz	a0,800060a6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006012:	04449703          	lh	a4,68(s1)
    80006016:	478d                	li	a5,3
    80006018:	00f71763          	bne	a4,a5,80006026 <sys_open+0x72>
    8000601c:	0464d703          	lhu	a4,70(s1)
    80006020:	47a5                	li	a5,9
    80006022:	0ce7ed63          	bltu	a5,a4,800060fc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	dbe080e7          	jalr	-578(ra) # 80004de4 <filealloc>
    8000602e:	89aa                	mv	s3,a0
    80006030:	10050363          	beqz	a0,80006136 <sys_open+0x182>
    80006034:	00000097          	auipc	ra,0x0
    80006038:	906080e7          	jalr	-1786(ra) # 8000593a <fdalloc>
    8000603c:	892a                	mv	s2,a0
    8000603e:	0e054763          	bltz	a0,8000612c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006042:	04449703          	lh	a4,68(s1)
    80006046:	478d                	li	a5,3
    80006048:	0cf70563          	beq	a4,a5,80006112 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000604c:	4789                	li	a5,2
    8000604e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006052:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006056:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000605a:	f4c42783          	lw	a5,-180(s0)
    8000605e:	0017c713          	xori	a4,a5,1
    80006062:	8b05                	andi	a4,a4,1
    80006064:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006068:	0037f713          	andi	a4,a5,3
    8000606c:	00e03733          	snez	a4,a4
    80006070:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006074:	4007f793          	andi	a5,a5,1024
    80006078:	c791                	beqz	a5,80006084 <sys_open+0xd0>
    8000607a:	04449703          	lh	a4,68(s1)
    8000607e:	4789                	li	a5,2
    80006080:	0af70063          	beq	a4,a5,80006120 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006084:	8526                	mv	a0,s1
    80006086:	ffffe097          	auipc	ra,0xffffe
    8000608a:	04e080e7          	jalr	78(ra) # 800040d4 <iunlock>
  end_op();
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	9c6080e7          	jalr	-1594(ra) # 80004a54 <end_op>

  return fd;
    80006096:	854a                	mv	a0,s2
}
    80006098:	70ea                	ld	ra,184(sp)
    8000609a:	744a                	ld	s0,176(sp)
    8000609c:	74aa                	ld	s1,168(sp)
    8000609e:	790a                	ld	s2,160(sp)
    800060a0:	69ea                	ld	s3,152(sp)
    800060a2:	6129                	addi	sp,sp,192
    800060a4:	8082                	ret
      end_op();
    800060a6:	fffff097          	auipc	ra,0xfffff
    800060aa:	9ae080e7          	jalr	-1618(ra) # 80004a54 <end_op>
      return -1;
    800060ae:	557d                	li	a0,-1
    800060b0:	b7e5                	j	80006098 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800060b2:	f5040513          	addi	a0,s0,-176
    800060b6:	ffffe097          	auipc	ra,0xffffe
    800060ba:	702080e7          	jalr	1794(ra) # 800047b8 <namei>
    800060be:	84aa                	mv	s1,a0
    800060c0:	c905                	beqz	a0,800060f0 <sys_open+0x13c>
    ilock(ip);
    800060c2:	ffffe097          	auipc	ra,0xffffe
    800060c6:	f50080e7          	jalr	-176(ra) # 80004012 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800060ca:	04449703          	lh	a4,68(s1)
    800060ce:	4785                	li	a5,1
    800060d0:	f4f711e3          	bne	a4,a5,80006012 <sys_open+0x5e>
    800060d4:	f4c42783          	lw	a5,-180(s0)
    800060d8:	d7b9                	beqz	a5,80006026 <sys_open+0x72>
      iunlockput(ip);
    800060da:	8526                	mv	a0,s1
    800060dc:	ffffe097          	auipc	ra,0xffffe
    800060e0:	198080e7          	jalr	408(ra) # 80004274 <iunlockput>
      end_op();
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	970080e7          	jalr	-1680(ra) # 80004a54 <end_op>
      return -1;
    800060ec:	557d                	li	a0,-1
    800060ee:	b76d                	j	80006098 <sys_open+0xe4>
      end_op();
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	964080e7          	jalr	-1692(ra) # 80004a54 <end_op>
      return -1;
    800060f8:	557d                	li	a0,-1
    800060fa:	bf79                	j	80006098 <sys_open+0xe4>
    iunlockput(ip);
    800060fc:	8526                	mv	a0,s1
    800060fe:	ffffe097          	auipc	ra,0xffffe
    80006102:	176080e7          	jalr	374(ra) # 80004274 <iunlockput>
    end_op();
    80006106:	fffff097          	auipc	ra,0xfffff
    8000610a:	94e080e7          	jalr	-1714(ra) # 80004a54 <end_op>
    return -1;
    8000610e:	557d                	li	a0,-1
    80006110:	b761                	j	80006098 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006112:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006116:	04649783          	lh	a5,70(s1)
    8000611a:	02f99223          	sh	a5,36(s3)
    8000611e:	bf25                	j	80006056 <sys_open+0xa2>
    itrunc(ip);
    80006120:	8526                	mv	a0,s1
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	ffe080e7          	jalr	-2(ra) # 80004120 <itrunc>
    8000612a:	bfa9                	j	80006084 <sys_open+0xd0>
      fileclose(f);
    8000612c:	854e                	mv	a0,s3
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	d72080e7          	jalr	-654(ra) # 80004ea0 <fileclose>
    iunlockput(ip);
    80006136:	8526                	mv	a0,s1
    80006138:	ffffe097          	auipc	ra,0xffffe
    8000613c:	13c080e7          	jalr	316(ra) # 80004274 <iunlockput>
    end_op();
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	914080e7          	jalr	-1772(ra) # 80004a54 <end_op>
    return -1;
    80006148:	557d                	li	a0,-1
    8000614a:	b7b9                	j	80006098 <sys_open+0xe4>

000000008000614c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000614c:	7175                	addi	sp,sp,-144
    8000614e:	e506                	sd	ra,136(sp)
    80006150:	e122                	sd	s0,128(sp)
    80006152:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006154:	fffff097          	auipc	ra,0xfffff
    80006158:	880080e7          	jalr	-1920(ra) # 800049d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000615c:	08000613          	li	a2,128
    80006160:	f7040593          	addi	a1,s0,-144
    80006164:	4501                	li	a0,0
    80006166:	ffffd097          	auipc	ra,0xffffd
    8000616a:	040080e7          	jalr	64(ra) # 800031a6 <argstr>
    8000616e:	02054963          	bltz	a0,800061a0 <sys_mkdir+0x54>
    80006172:	4681                	li	a3,0
    80006174:	4601                	li	a2,0
    80006176:	4585                	li	a1,1
    80006178:	f7040513          	addi	a0,s0,-144
    8000617c:	00000097          	auipc	ra,0x0
    80006180:	800080e7          	jalr	-2048(ra) # 8000597c <create>
    80006184:	cd11                	beqz	a0,800061a0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006186:	ffffe097          	auipc	ra,0xffffe
    8000618a:	0ee080e7          	jalr	238(ra) # 80004274 <iunlockput>
  end_op();
    8000618e:	fffff097          	auipc	ra,0xfffff
    80006192:	8c6080e7          	jalr	-1850(ra) # 80004a54 <end_op>
  return 0;
    80006196:	4501                	li	a0,0
}
    80006198:	60aa                	ld	ra,136(sp)
    8000619a:	640a                	ld	s0,128(sp)
    8000619c:	6149                	addi	sp,sp,144
    8000619e:	8082                	ret
    end_op();
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	8b4080e7          	jalr	-1868(ra) # 80004a54 <end_op>
    return -1;
    800061a8:	557d                	li	a0,-1
    800061aa:	b7fd                	j	80006198 <sys_mkdir+0x4c>

00000000800061ac <sys_mknod>:

uint64
sys_mknod(void)
{
    800061ac:	7135                	addi	sp,sp,-160
    800061ae:	ed06                	sd	ra,152(sp)
    800061b0:	e922                	sd	s0,144(sp)
    800061b2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	820080e7          	jalr	-2016(ra) # 800049d4 <begin_op>
  argint(1, &major);
    800061bc:	f6c40593          	addi	a1,s0,-148
    800061c0:	4505                	li	a0,1
    800061c2:	ffffd097          	auipc	ra,0xffffd
    800061c6:	fa4080e7          	jalr	-92(ra) # 80003166 <argint>
  argint(2, &minor);
    800061ca:	f6840593          	addi	a1,s0,-152
    800061ce:	4509                	li	a0,2
    800061d0:	ffffd097          	auipc	ra,0xffffd
    800061d4:	f96080e7          	jalr	-106(ra) # 80003166 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061d8:	08000613          	li	a2,128
    800061dc:	f7040593          	addi	a1,s0,-144
    800061e0:	4501                	li	a0,0
    800061e2:	ffffd097          	auipc	ra,0xffffd
    800061e6:	fc4080e7          	jalr	-60(ra) # 800031a6 <argstr>
    800061ea:	02054b63          	bltz	a0,80006220 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800061ee:	f6841683          	lh	a3,-152(s0)
    800061f2:	f6c41603          	lh	a2,-148(s0)
    800061f6:	458d                	li	a1,3
    800061f8:	f7040513          	addi	a0,s0,-144
    800061fc:	fffff097          	auipc	ra,0xfffff
    80006200:	780080e7          	jalr	1920(ra) # 8000597c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006204:	cd11                	beqz	a0,80006220 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006206:	ffffe097          	auipc	ra,0xffffe
    8000620a:	06e080e7          	jalr	110(ra) # 80004274 <iunlockput>
  end_op();
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	846080e7          	jalr	-1978(ra) # 80004a54 <end_op>
  return 0;
    80006216:	4501                	li	a0,0
}
    80006218:	60ea                	ld	ra,152(sp)
    8000621a:	644a                	ld	s0,144(sp)
    8000621c:	610d                	addi	sp,sp,160
    8000621e:	8082                	ret
    end_op();
    80006220:	fffff097          	auipc	ra,0xfffff
    80006224:	834080e7          	jalr	-1996(ra) # 80004a54 <end_op>
    return -1;
    80006228:	557d                	li	a0,-1
    8000622a:	b7fd                	j	80006218 <sys_mknod+0x6c>

000000008000622c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000622c:	7135                	addi	sp,sp,-160
    8000622e:	ed06                	sd	ra,152(sp)
    80006230:	e922                	sd	s0,144(sp)
    80006232:	e526                	sd	s1,136(sp)
    80006234:	e14a                	sd	s2,128(sp)
    80006236:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006238:	ffffc097          	auipc	ra,0xffffc
    8000623c:	8c0080e7          	jalr	-1856(ra) # 80001af8 <myproc>
    80006240:	892a                	mv	s2,a0
  
  begin_op();
    80006242:	ffffe097          	auipc	ra,0xffffe
    80006246:	792080e7          	jalr	1938(ra) # 800049d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000624a:	08000613          	li	a2,128
    8000624e:	f6040593          	addi	a1,s0,-160
    80006252:	4501                	li	a0,0
    80006254:	ffffd097          	auipc	ra,0xffffd
    80006258:	f52080e7          	jalr	-174(ra) # 800031a6 <argstr>
    8000625c:	04054b63          	bltz	a0,800062b2 <sys_chdir+0x86>
    80006260:	f6040513          	addi	a0,s0,-160
    80006264:	ffffe097          	auipc	ra,0xffffe
    80006268:	554080e7          	jalr	1364(ra) # 800047b8 <namei>
    8000626c:	84aa                	mv	s1,a0
    8000626e:	c131                	beqz	a0,800062b2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006270:	ffffe097          	auipc	ra,0xffffe
    80006274:	da2080e7          	jalr	-606(ra) # 80004012 <ilock>
  if(ip->type != T_DIR){
    80006278:	04449703          	lh	a4,68(s1)
    8000627c:	4785                	li	a5,1
    8000627e:	04f71063          	bne	a4,a5,800062be <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006282:	8526                	mv	a0,s1
    80006284:	ffffe097          	auipc	ra,0xffffe
    80006288:	e50080e7          	jalr	-432(ra) # 800040d4 <iunlock>
  iput(p->cwd);
    8000628c:	15093503          	ld	a0,336(s2)
    80006290:	ffffe097          	auipc	ra,0xffffe
    80006294:	f3c080e7          	jalr	-196(ra) # 800041cc <iput>
  end_op();
    80006298:	ffffe097          	auipc	ra,0xffffe
    8000629c:	7bc080e7          	jalr	1980(ra) # 80004a54 <end_op>
  p->cwd = ip;
    800062a0:	14993823          	sd	s1,336(s2)
  return 0;
    800062a4:	4501                	li	a0,0
}
    800062a6:	60ea                	ld	ra,152(sp)
    800062a8:	644a                	ld	s0,144(sp)
    800062aa:	64aa                	ld	s1,136(sp)
    800062ac:	690a                	ld	s2,128(sp)
    800062ae:	610d                	addi	sp,sp,160
    800062b0:	8082                	ret
    end_op();
    800062b2:	ffffe097          	auipc	ra,0xffffe
    800062b6:	7a2080e7          	jalr	1954(ra) # 80004a54 <end_op>
    return -1;
    800062ba:	557d                	li	a0,-1
    800062bc:	b7ed                	j	800062a6 <sys_chdir+0x7a>
    iunlockput(ip);
    800062be:	8526                	mv	a0,s1
    800062c0:	ffffe097          	auipc	ra,0xffffe
    800062c4:	fb4080e7          	jalr	-76(ra) # 80004274 <iunlockput>
    end_op();
    800062c8:	ffffe097          	auipc	ra,0xffffe
    800062cc:	78c080e7          	jalr	1932(ra) # 80004a54 <end_op>
    return -1;
    800062d0:	557d                	li	a0,-1
    800062d2:	bfd1                	j	800062a6 <sys_chdir+0x7a>

00000000800062d4 <sys_exec>:

uint64
sys_exec(void)
{
    800062d4:	7145                	addi	sp,sp,-464
    800062d6:	e786                	sd	ra,456(sp)
    800062d8:	e3a2                	sd	s0,448(sp)
    800062da:	ff26                	sd	s1,440(sp)
    800062dc:	fb4a                	sd	s2,432(sp)
    800062de:	f74e                	sd	s3,424(sp)
    800062e0:	f352                	sd	s4,416(sp)
    800062e2:	ef56                	sd	s5,408(sp)
    800062e4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800062e6:	e3840593          	addi	a1,s0,-456
    800062ea:	4505                	li	a0,1
    800062ec:	ffffd097          	auipc	ra,0xffffd
    800062f0:	e9a080e7          	jalr	-358(ra) # 80003186 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800062f4:	08000613          	li	a2,128
    800062f8:	f4040593          	addi	a1,s0,-192
    800062fc:	4501                	li	a0,0
    800062fe:	ffffd097          	auipc	ra,0xffffd
    80006302:	ea8080e7          	jalr	-344(ra) # 800031a6 <argstr>
    80006306:	87aa                	mv	a5,a0
    return -1;
    80006308:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000630a:	0c07c263          	bltz	a5,800063ce <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000630e:	10000613          	li	a2,256
    80006312:	4581                	li	a1,0
    80006314:	e4040513          	addi	a0,s0,-448
    80006318:	ffffb097          	auipc	ra,0xffffb
    8000631c:	a48080e7          	jalr	-1464(ra) # 80000d60 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006320:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006324:	89a6                	mv	s3,s1
    80006326:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006328:	02000a13          	li	s4,32
    8000632c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006330:	00391793          	slli	a5,s2,0x3
    80006334:	e3040593          	addi	a1,s0,-464
    80006338:	e3843503          	ld	a0,-456(s0)
    8000633c:	953e                	add	a0,a0,a5
    8000633e:	ffffd097          	auipc	ra,0xffffd
    80006342:	d8a080e7          	jalr	-630(ra) # 800030c8 <fetchaddr>
    80006346:	02054a63          	bltz	a0,8000637a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000634a:	e3043783          	ld	a5,-464(s0)
    8000634e:	c3b9                	beqz	a5,80006394 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006350:	ffffa097          	auipc	ra,0xffffa
    80006354:	7e4080e7          	jalr	2020(ra) # 80000b34 <kalloc>
    80006358:	85aa                	mv	a1,a0
    8000635a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000635e:	cd11                	beqz	a0,8000637a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006360:	6605                	lui	a2,0x1
    80006362:	e3043503          	ld	a0,-464(s0)
    80006366:	ffffd097          	auipc	ra,0xffffd
    8000636a:	db4080e7          	jalr	-588(ra) # 8000311a <fetchstr>
    8000636e:	00054663          	bltz	a0,8000637a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006372:	0905                	addi	s2,s2,1
    80006374:	09a1                	addi	s3,s3,8
    80006376:	fb491be3          	bne	s2,s4,8000632c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000637a:	10048913          	addi	s2,s1,256
    8000637e:	6088                	ld	a0,0(s1)
    80006380:	c531                	beqz	a0,800063cc <sys_exec+0xf8>
    kfree(argv[i]);
    80006382:	ffffa097          	auipc	ra,0xffffa
    80006386:	668080e7          	jalr	1640(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000638a:	04a1                	addi	s1,s1,8
    8000638c:	ff2499e3          	bne	s1,s2,8000637e <sys_exec+0xaa>
  return -1;
    80006390:	557d                	li	a0,-1
    80006392:	a835                	j	800063ce <sys_exec+0xfa>
      argv[i] = 0;
    80006394:	0a8e                	slli	s5,s5,0x3
    80006396:	fc040793          	addi	a5,s0,-64
    8000639a:	9abe                	add	s5,s5,a5
    8000639c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800063a0:	e4040593          	addi	a1,s0,-448
    800063a4:	f4040513          	addi	a0,s0,-192
    800063a8:	fffff097          	auipc	ra,0xfffff
    800063ac:	172080e7          	jalr	370(ra) # 8000551a <exec>
    800063b0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063b2:	10048993          	addi	s3,s1,256
    800063b6:	6088                	ld	a0,0(s1)
    800063b8:	c901                	beqz	a0,800063c8 <sys_exec+0xf4>
    kfree(argv[i]);
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	630080e7          	jalr	1584(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063c2:	04a1                	addi	s1,s1,8
    800063c4:	ff3499e3          	bne	s1,s3,800063b6 <sys_exec+0xe2>
  return ret;
    800063c8:	854a                	mv	a0,s2
    800063ca:	a011                	j	800063ce <sys_exec+0xfa>
  return -1;
    800063cc:	557d                	li	a0,-1
}
    800063ce:	60be                	ld	ra,456(sp)
    800063d0:	641e                	ld	s0,448(sp)
    800063d2:	74fa                	ld	s1,440(sp)
    800063d4:	795a                	ld	s2,432(sp)
    800063d6:	79ba                	ld	s3,424(sp)
    800063d8:	7a1a                	ld	s4,416(sp)
    800063da:	6afa                	ld	s5,408(sp)
    800063dc:	6179                	addi	sp,sp,464
    800063de:	8082                	ret

00000000800063e0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800063e0:	7139                	addi	sp,sp,-64
    800063e2:	fc06                	sd	ra,56(sp)
    800063e4:	f822                	sd	s0,48(sp)
    800063e6:	f426                	sd	s1,40(sp)
    800063e8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800063ea:	ffffb097          	auipc	ra,0xffffb
    800063ee:	70e080e7          	jalr	1806(ra) # 80001af8 <myproc>
    800063f2:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800063f4:	fd840593          	addi	a1,s0,-40
    800063f8:	4501                	li	a0,0
    800063fa:	ffffd097          	auipc	ra,0xffffd
    800063fe:	d8c080e7          	jalr	-628(ra) # 80003186 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006402:	fc840593          	addi	a1,s0,-56
    80006406:	fd040513          	addi	a0,s0,-48
    8000640a:	fffff097          	auipc	ra,0xfffff
    8000640e:	dc6080e7          	jalr	-570(ra) # 800051d0 <pipealloc>
    return -1;
    80006412:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006414:	0c054463          	bltz	a0,800064dc <sys_pipe+0xfc>
  fd0 = -1;
    80006418:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000641c:	fd043503          	ld	a0,-48(s0)
    80006420:	fffff097          	auipc	ra,0xfffff
    80006424:	51a080e7          	jalr	1306(ra) # 8000593a <fdalloc>
    80006428:	fca42223          	sw	a0,-60(s0)
    8000642c:	08054b63          	bltz	a0,800064c2 <sys_pipe+0xe2>
    80006430:	fc843503          	ld	a0,-56(s0)
    80006434:	fffff097          	auipc	ra,0xfffff
    80006438:	506080e7          	jalr	1286(ra) # 8000593a <fdalloc>
    8000643c:	fca42023          	sw	a0,-64(s0)
    80006440:	06054863          	bltz	a0,800064b0 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006444:	4691                	li	a3,4
    80006446:	fc440613          	addi	a2,s0,-60
    8000644a:	fd843583          	ld	a1,-40(s0)
    8000644e:	68a8                	ld	a0,80(s1)
    80006450:	ffffb097          	auipc	ra,0xffffb
    80006454:	29e080e7          	jalr	670(ra) # 800016ee <copyout>
    80006458:	02054063          	bltz	a0,80006478 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000645c:	4691                	li	a3,4
    8000645e:	fc040613          	addi	a2,s0,-64
    80006462:	fd843583          	ld	a1,-40(s0)
    80006466:	0591                	addi	a1,a1,4
    80006468:	68a8                	ld	a0,80(s1)
    8000646a:	ffffb097          	auipc	ra,0xffffb
    8000646e:	284080e7          	jalr	644(ra) # 800016ee <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006472:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006474:	06055463          	bgez	a0,800064dc <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006478:	fc442783          	lw	a5,-60(s0)
    8000647c:	07e9                	addi	a5,a5,26
    8000647e:	078e                	slli	a5,a5,0x3
    80006480:	97a6                	add	a5,a5,s1
    80006482:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006486:	fc042503          	lw	a0,-64(s0)
    8000648a:	0569                	addi	a0,a0,26
    8000648c:	050e                	slli	a0,a0,0x3
    8000648e:	94aa                	add	s1,s1,a0
    80006490:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006494:	fd043503          	ld	a0,-48(s0)
    80006498:	fffff097          	auipc	ra,0xfffff
    8000649c:	a08080e7          	jalr	-1528(ra) # 80004ea0 <fileclose>
    fileclose(wf);
    800064a0:	fc843503          	ld	a0,-56(s0)
    800064a4:	fffff097          	auipc	ra,0xfffff
    800064a8:	9fc080e7          	jalr	-1540(ra) # 80004ea0 <fileclose>
    return -1;
    800064ac:	57fd                	li	a5,-1
    800064ae:	a03d                	j	800064dc <sys_pipe+0xfc>
    if(fd0 >= 0)
    800064b0:	fc442783          	lw	a5,-60(s0)
    800064b4:	0007c763          	bltz	a5,800064c2 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800064b8:	07e9                	addi	a5,a5,26
    800064ba:	078e                	slli	a5,a5,0x3
    800064bc:	94be                	add	s1,s1,a5
    800064be:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800064c2:	fd043503          	ld	a0,-48(s0)
    800064c6:	fffff097          	auipc	ra,0xfffff
    800064ca:	9da080e7          	jalr	-1574(ra) # 80004ea0 <fileclose>
    fileclose(wf);
    800064ce:	fc843503          	ld	a0,-56(s0)
    800064d2:	fffff097          	auipc	ra,0xfffff
    800064d6:	9ce080e7          	jalr	-1586(ra) # 80004ea0 <fileclose>
    return -1;
    800064da:	57fd                	li	a5,-1
}
    800064dc:	853e                	mv	a0,a5
    800064de:	70e2                	ld	ra,56(sp)
    800064e0:	7442                	ld	s0,48(sp)
    800064e2:	74a2                	ld	s1,40(sp)
    800064e4:	6121                	addi	sp,sp,64
    800064e6:	8082                	ret
	...

00000000800064f0 <kernelvec>:
    800064f0:	7111                	addi	sp,sp,-256
    800064f2:	e006                	sd	ra,0(sp)
    800064f4:	e40a                	sd	sp,8(sp)
    800064f6:	e80e                	sd	gp,16(sp)
    800064f8:	ec12                	sd	tp,24(sp)
    800064fa:	f016                	sd	t0,32(sp)
    800064fc:	f41a                	sd	t1,40(sp)
    800064fe:	f81e                	sd	t2,48(sp)
    80006500:	fc22                	sd	s0,56(sp)
    80006502:	e0a6                	sd	s1,64(sp)
    80006504:	e4aa                	sd	a0,72(sp)
    80006506:	e8ae                	sd	a1,80(sp)
    80006508:	ecb2                	sd	a2,88(sp)
    8000650a:	f0b6                	sd	a3,96(sp)
    8000650c:	f4ba                	sd	a4,104(sp)
    8000650e:	f8be                	sd	a5,112(sp)
    80006510:	fcc2                	sd	a6,120(sp)
    80006512:	e146                	sd	a7,128(sp)
    80006514:	e54a                	sd	s2,136(sp)
    80006516:	e94e                	sd	s3,144(sp)
    80006518:	ed52                	sd	s4,152(sp)
    8000651a:	f156                	sd	s5,160(sp)
    8000651c:	f55a                	sd	s6,168(sp)
    8000651e:	f95e                	sd	s7,176(sp)
    80006520:	fd62                	sd	s8,184(sp)
    80006522:	e1e6                	sd	s9,192(sp)
    80006524:	e5ea                	sd	s10,200(sp)
    80006526:	e9ee                	sd	s11,208(sp)
    80006528:	edf2                	sd	t3,216(sp)
    8000652a:	f1f6                	sd	t4,224(sp)
    8000652c:	f5fa                	sd	t5,232(sp)
    8000652e:	f9fe                	sd	t6,240(sp)
    80006530:	a8ffc0ef          	jal	ra,80002fbe <kerneltrap>
    80006534:	6082                	ld	ra,0(sp)
    80006536:	6122                	ld	sp,8(sp)
    80006538:	61c2                	ld	gp,16(sp)
    8000653a:	7282                	ld	t0,32(sp)
    8000653c:	7322                	ld	t1,40(sp)
    8000653e:	73c2                	ld	t2,48(sp)
    80006540:	7462                	ld	s0,56(sp)
    80006542:	6486                	ld	s1,64(sp)
    80006544:	6526                	ld	a0,72(sp)
    80006546:	65c6                	ld	a1,80(sp)
    80006548:	6666                	ld	a2,88(sp)
    8000654a:	7686                	ld	a3,96(sp)
    8000654c:	7726                	ld	a4,104(sp)
    8000654e:	77c6                	ld	a5,112(sp)
    80006550:	7866                	ld	a6,120(sp)
    80006552:	688a                	ld	a7,128(sp)
    80006554:	692a                	ld	s2,136(sp)
    80006556:	69ca                	ld	s3,144(sp)
    80006558:	6a6a                	ld	s4,152(sp)
    8000655a:	7a8a                	ld	s5,160(sp)
    8000655c:	7b2a                	ld	s6,168(sp)
    8000655e:	7bca                	ld	s7,176(sp)
    80006560:	7c6a                	ld	s8,184(sp)
    80006562:	6c8e                	ld	s9,192(sp)
    80006564:	6d2e                	ld	s10,200(sp)
    80006566:	6dce                	ld	s11,208(sp)
    80006568:	6e6e                	ld	t3,216(sp)
    8000656a:	7e8e                	ld	t4,224(sp)
    8000656c:	7f2e                	ld	t5,232(sp)
    8000656e:	7fce                	ld	t6,240(sp)
    80006570:	6111                	addi	sp,sp,256
    80006572:	10200073          	sret
    80006576:	00000013          	nop
    8000657a:	00000013          	nop
    8000657e:	0001                	nop

0000000080006580 <timervec>:
    80006580:	34051573          	csrrw	a0,mscratch,a0
    80006584:	e10c                	sd	a1,0(a0)
    80006586:	e510                	sd	a2,8(a0)
    80006588:	e914                	sd	a3,16(a0)
    8000658a:	6d0c                	ld	a1,24(a0)
    8000658c:	7110                	ld	a2,32(a0)
    8000658e:	6194                	ld	a3,0(a1)
    80006590:	96b2                	add	a3,a3,a2
    80006592:	e194                	sd	a3,0(a1)
    80006594:	4589                	li	a1,2
    80006596:	14459073          	csrw	sip,a1
    8000659a:	6914                	ld	a3,16(a0)
    8000659c:	6510                	ld	a2,8(a0)
    8000659e:	610c                	ld	a1,0(a0)
    800065a0:	34051573          	csrrw	a0,mscratch,a0
    800065a4:	30200073          	mret
	...

00000000800065aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800065aa:	1141                	addi	sp,sp,-16
    800065ac:	e422                	sd	s0,8(sp)
    800065ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800065b0:	0c0007b7          	lui	a5,0xc000
    800065b4:	4705                	li	a4,1
    800065b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800065b8:	c3d8                	sw	a4,4(a5)
}
    800065ba:	6422                	ld	s0,8(sp)
    800065bc:	0141                	addi	sp,sp,16
    800065be:	8082                	ret

00000000800065c0 <plicinithart>:

void
plicinithart(void)
{
    800065c0:	1141                	addi	sp,sp,-16
    800065c2:	e406                	sd	ra,8(sp)
    800065c4:	e022                	sd	s0,0(sp)
    800065c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065c8:	ffffb097          	auipc	ra,0xffffb
    800065cc:	504080e7          	jalr	1284(ra) # 80001acc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800065d0:	0085171b          	slliw	a4,a0,0x8
    800065d4:	0c0027b7          	lui	a5,0xc002
    800065d8:	97ba                	add	a5,a5,a4
    800065da:	40200713          	li	a4,1026
    800065de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800065e2:	00d5151b          	slliw	a0,a0,0xd
    800065e6:	0c2017b7          	lui	a5,0xc201
    800065ea:	953e                	add	a0,a0,a5
    800065ec:	00052023          	sw	zero,0(a0)
}
    800065f0:	60a2                	ld	ra,8(sp)
    800065f2:	6402                	ld	s0,0(sp)
    800065f4:	0141                	addi	sp,sp,16
    800065f6:	8082                	ret

00000000800065f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800065f8:	1141                	addi	sp,sp,-16
    800065fa:	e406                	sd	ra,8(sp)
    800065fc:	e022                	sd	s0,0(sp)
    800065fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006600:	ffffb097          	auipc	ra,0xffffb
    80006604:	4cc080e7          	jalr	1228(ra) # 80001acc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006608:	00d5179b          	slliw	a5,a0,0xd
    8000660c:	0c201537          	lui	a0,0xc201
    80006610:	953e                	add	a0,a0,a5
  return irq;
}
    80006612:	4148                	lw	a0,4(a0)
    80006614:	60a2                	ld	ra,8(sp)
    80006616:	6402                	ld	s0,0(sp)
    80006618:	0141                	addi	sp,sp,16
    8000661a:	8082                	ret

000000008000661c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000661c:	1101                	addi	sp,sp,-32
    8000661e:	ec06                	sd	ra,24(sp)
    80006620:	e822                	sd	s0,16(sp)
    80006622:	e426                	sd	s1,8(sp)
    80006624:	1000                	addi	s0,sp,32
    80006626:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006628:	ffffb097          	auipc	ra,0xffffb
    8000662c:	4a4080e7          	jalr	1188(ra) # 80001acc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006630:	00d5151b          	slliw	a0,a0,0xd
    80006634:	0c2017b7          	lui	a5,0xc201
    80006638:	97aa                	add	a5,a5,a0
    8000663a:	c3c4                	sw	s1,4(a5)
}
    8000663c:	60e2                	ld	ra,24(sp)
    8000663e:	6442                	ld	s0,16(sp)
    80006640:	64a2                	ld	s1,8(sp)
    80006642:	6105                	addi	sp,sp,32
    80006644:	8082                	ret

0000000080006646 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006646:	1141                	addi	sp,sp,-16
    80006648:	e406                	sd	ra,8(sp)
    8000664a:	e022                	sd	s0,0(sp)
    8000664c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000664e:	479d                	li	a5,7
    80006650:	04a7cc63          	blt	a5,a0,800066a8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006654:	00042797          	auipc	a5,0x42
    80006658:	c5c78793          	addi	a5,a5,-932 # 800482b0 <disk>
    8000665c:	97aa                	add	a5,a5,a0
    8000665e:	0187c783          	lbu	a5,24(a5)
    80006662:	ebb9                	bnez	a5,800066b8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006664:	00451613          	slli	a2,a0,0x4
    80006668:	00042797          	auipc	a5,0x42
    8000666c:	c4878793          	addi	a5,a5,-952 # 800482b0 <disk>
    80006670:	6394                	ld	a3,0(a5)
    80006672:	96b2                	add	a3,a3,a2
    80006674:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006678:	6398                	ld	a4,0(a5)
    8000667a:	9732                	add	a4,a4,a2
    8000667c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006680:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006684:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006688:	953e                	add	a0,a0,a5
    8000668a:	4785                	li	a5,1
    8000668c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006690:	00042517          	auipc	a0,0x42
    80006694:	c3850513          	addi	a0,a0,-968 # 800482c8 <disk+0x18>
    80006698:	ffffc097          	auipc	ra,0xffffc
    8000669c:	f90080e7          	jalr	-112(ra) # 80002628 <wakeup>
}
    800066a0:	60a2                	ld	ra,8(sp)
    800066a2:	6402                	ld	s0,0(sp)
    800066a4:	0141                	addi	sp,sp,16
    800066a6:	8082                	ret
    panic("free_desc 1");
    800066a8:	00002517          	auipc	a0,0x2
    800066ac:	1f050513          	addi	a0,a0,496 # 80008898 <syscalls+0x318>
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	e8e080e7          	jalr	-370(ra) # 8000053e <panic>
    panic("free_desc 2");
    800066b8:	00002517          	auipc	a0,0x2
    800066bc:	1f050513          	addi	a0,a0,496 # 800088a8 <syscalls+0x328>
    800066c0:	ffffa097          	auipc	ra,0xffffa
    800066c4:	e7e080e7          	jalr	-386(ra) # 8000053e <panic>

00000000800066c8 <virtio_disk_init>:
{
    800066c8:	1101                	addi	sp,sp,-32
    800066ca:	ec06                	sd	ra,24(sp)
    800066cc:	e822                	sd	s0,16(sp)
    800066ce:	e426                	sd	s1,8(sp)
    800066d0:	e04a                	sd	s2,0(sp)
    800066d2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800066d4:	00002597          	auipc	a1,0x2
    800066d8:	1e458593          	addi	a1,a1,484 # 800088b8 <syscalls+0x338>
    800066dc:	00042517          	auipc	a0,0x42
    800066e0:	cfc50513          	addi	a0,a0,-772 # 800483d8 <disk+0x128>
    800066e4:	ffffa097          	auipc	ra,0xffffa
    800066e8:	4f0080e7          	jalr	1264(ra) # 80000bd4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066ec:	100017b7          	lui	a5,0x10001
    800066f0:	4398                	lw	a4,0(a5)
    800066f2:	2701                	sext.w	a4,a4
    800066f4:	747277b7          	lui	a5,0x74727
    800066f8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066fc:	14f71c63          	bne	a4,a5,80006854 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006700:	100017b7          	lui	a5,0x10001
    80006704:	43dc                	lw	a5,4(a5)
    80006706:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006708:	4709                	li	a4,2
    8000670a:	14e79563          	bne	a5,a4,80006854 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000670e:	100017b7          	lui	a5,0x10001
    80006712:	479c                	lw	a5,8(a5)
    80006714:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006716:	12e79f63          	bne	a5,a4,80006854 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000671a:	100017b7          	lui	a5,0x10001
    8000671e:	47d8                	lw	a4,12(a5)
    80006720:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006722:	554d47b7          	lui	a5,0x554d4
    80006726:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000672a:	12f71563          	bne	a4,a5,80006854 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000672e:	100017b7          	lui	a5,0x10001
    80006732:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006736:	4705                	li	a4,1
    80006738:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000673a:	470d                	li	a4,3
    8000673c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000673e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006740:	c7ffe737          	lui	a4,0xc7ffe
    80006744:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fb592f>
    80006748:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000674a:	2701                	sext.w	a4,a4
    8000674c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000674e:	472d                	li	a4,11
    80006750:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006752:	5bbc                	lw	a5,112(a5)
    80006754:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006758:	8ba1                	andi	a5,a5,8
    8000675a:	10078563          	beqz	a5,80006864 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000675e:	100017b7          	lui	a5,0x10001
    80006762:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006766:	43fc                	lw	a5,68(a5)
    80006768:	2781                	sext.w	a5,a5
    8000676a:	10079563          	bnez	a5,80006874 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000676e:	100017b7          	lui	a5,0x10001
    80006772:	5bdc                	lw	a5,52(a5)
    80006774:	2781                	sext.w	a5,a5
  if(max == 0)
    80006776:	10078763          	beqz	a5,80006884 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000677a:	471d                	li	a4,7
    8000677c:	10f77c63          	bgeu	a4,a5,80006894 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006780:	ffffa097          	auipc	ra,0xffffa
    80006784:	3b4080e7          	jalr	948(ra) # 80000b34 <kalloc>
    80006788:	00042497          	auipc	s1,0x42
    8000678c:	b2848493          	addi	s1,s1,-1240 # 800482b0 <disk>
    80006790:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006792:	ffffa097          	auipc	ra,0xffffa
    80006796:	3a2080e7          	jalr	930(ra) # 80000b34 <kalloc>
    8000679a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000679c:	ffffa097          	auipc	ra,0xffffa
    800067a0:	398080e7          	jalr	920(ra) # 80000b34 <kalloc>
    800067a4:	87aa                	mv	a5,a0
    800067a6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800067a8:	6088                	ld	a0,0(s1)
    800067aa:	cd6d                	beqz	a0,800068a4 <virtio_disk_init+0x1dc>
    800067ac:	00042717          	auipc	a4,0x42
    800067b0:	b0c73703          	ld	a4,-1268(a4) # 800482b8 <disk+0x8>
    800067b4:	cb65                	beqz	a4,800068a4 <virtio_disk_init+0x1dc>
    800067b6:	c7fd                	beqz	a5,800068a4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800067b8:	6605                	lui	a2,0x1
    800067ba:	4581                	li	a1,0
    800067bc:	ffffa097          	auipc	ra,0xffffa
    800067c0:	5a4080e7          	jalr	1444(ra) # 80000d60 <memset>
  memset(disk.avail, 0, PGSIZE);
    800067c4:	00042497          	auipc	s1,0x42
    800067c8:	aec48493          	addi	s1,s1,-1300 # 800482b0 <disk>
    800067cc:	6605                	lui	a2,0x1
    800067ce:	4581                	li	a1,0
    800067d0:	6488                	ld	a0,8(s1)
    800067d2:	ffffa097          	auipc	ra,0xffffa
    800067d6:	58e080e7          	jalr	1422(ra) # 80000d60 <memset>
  memset(disk.used, 0, PGSIZE);
    800067da:	6605                	lui	a2,0x1
    800067dc:	4581                	li	a1,0
    800067de:	6888                	ld	a0,16(s1)
    800067e0:	ffffa097          	auipc	ra,0xffffa
    800067e4:	580080e7          	jalr	1408(ra) # 80000d60 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800067e8:	100017b7          	lui	a5,0x10001
    800067ec:	4721                	li	a4,8
    800067ee:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800067f0:	4098                	lw	a4,0(s1)
    800067f2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800067f6:	40d8                	lw	a4,4(s1)
    800067f8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800067fc:	6498                	ld	a4,8(s1)
    800067fe:	0007069b          	sext.w	a3,a4
    80006802:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006806:	9701                	srai	a4,a4,0x20
    80006808:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000680c:	6898                	ld	a4,16(s1)
    8000680e:	0007069b          	sext.w	a3,a4
    80006812:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006816:	9701                	srai	a4,a4,0x20
    80006818:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000681c:	4705                	li	a4,1
    8000681e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006820:	00e48c23          	sb	a4,24(s1)
    80006824:	00e48ca3          	sb	a4,25(s1)
    80006828:	00e48d23          	sb	a4,26(s1)
    8000682c:	00e48da3          	sb	a4,27(s1)
    80006830:	00e48e23          	sb	a4,28(s1)
    80006834:	00e48ea3          	sb	a4,29(s1)
    80006838:	00e48f23          	sb	a4,30(s1)
    8000683c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006840:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006844:	0727a823          	sw	s2,112(a5)
}
    80006848:	60e2                	ld	ra,24(sp)
    8000684a:	6442                	ld	s0,16(sp)
    8000684c:	64a2                	ld	s1,8(sp)
    8000684e:	6902                	ld	s2,0(sp)
    80006850:	6105                	addi	sp,sp,32
    80006852:	8082                	ret
    panic("could not find virtio disk");
    80006854:	00002517          	auipc	a0,0x2
    80006858:	07450513          	addi	a0,a0,116 # 800088c8 <syscalls+0x348>
    8000685c:	ffffa097          	auipc	ra,0xffffa
    80006860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006864:	00002517          	auipc	a0,0x2
    80006868:	08450513          	addi	a0,a0,132 # 800088e8 <syscalls+0x368>
    8000686c:	ffffa097          	auipc	ra,0xffffa
    80006870:	cd2080e7          	jalr	-814(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006874:	00002517          	auipc	a0,0x2
    80006878:	09450513          	addi	a0,a0,148 # 80008908 <syscalls+0x388>
    8000687c:	ffffa097          	auipc	ra,0xffffa
    80006880:	cc2080e7          	jalr	-830(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006884:	00002517          	auipc	a0,0x2
    80006888:	0a450513          	addi	a0,a0,164 # 80008928 <syscalls+0x3a8>
    8000688c:	ffffa097          	auipc	ra,0xffffa
    80006890:	cb2080e7          	jalr	-846(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006894:	00002517          	auipc	a0,0x2
    80006898:	0b450513          	addi	a0,a0,180 # 80008948 <syscalls+0x3c8>
    8000689c:	ffffa097          	auipc	ra,0xffffa
    800068a0:	ca2080e7          	jalr	-862(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800068a4:	00002517          	auipc	a0,0x2
    800068a8:	0c450513          	addi	a0,a0,196 # 80008968 <syscalls+0x3e8>
    800068ac:	ffffa097          	auipc	ra,0xffffa
    800068b0:	c92080e7          	jalr	-878(ra) # 8000053e <panic>

00000000800068b4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800068b4:	7119                	addi	sp,sp,-128
    800068b6:	fc86                	sd	ra,120(sp)
    800068b8:	f8a2                	sd	s0,112(sp)
    800068ba:	f4a6                	sd	s1,104(sp)
    800068bc:	f0ca                	sd	s2,96(sp)
    800068be:	ecce                	sd	s3,88(sp)
    800068c0:	e8d2                	sd	s4,80(sp)
    800068c2:	e4d6                	sd	s5,72(sp)
    800068c4:	e0da                	sd	s6,64(sp)
    800068c6:	fc5e                	sd	s7,56(sp)
    800068c8:	f862                	sd	s8,48(sp)
    800068ca:	f466                	sd	s9,40(sp)
    800068cc:	f06a                	sd	s10,32(sp)
    800068ce:	ec6e                	sd	s11,24(sp)
    800068d0:	0100                	addi	s0,sp,128
    800068d2:	8aaa                	mv	s5,a0
    800068d4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800068d6:	00c52d03          	lw	s10,12(a0)
    800068da:	001d1d1b          	slliw	s10,s10,0x1
    800068de:	1d02                	slli	s10,s10,0x20
    800068e0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800068e4:	00042517          	auipc	a0,0x42
    800068e8:	af450513          	addi	a0,a0,-1292 # 800483d8 <disk+0x128>
    800068ec:	ffffa097          	auipc	ra,0xffffa
    800068f0:	378080e7          	jalr	888(ra) # 80000c64 <acquire>
  for(int i = 0; i < 3; i++){
    800068f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800068f6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800068f8:	00042b97          	auipc	s7,0x42
    800068fc:	9b8b8b93          	addi	s7,s7,-1608 # 800482b0 <disk>
  for(int i = 0; i < 3; i++){
    80006900:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006902:	00042c97          	auipc	s9,0x42
    80006906:	ad6c8c93          	addi	s9,s9,-1322 # 800483d8 <disk+0x128>
    8000690a:	a08d                	j	8000696c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000690c:	00fb8733          	add	a4,s7,a5
    80006910:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006914:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006916:	0207c563          	bltz	a5,80006940 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000691a:	2905                	addiw	s2,s2,1
    8000691c:	0611                	addi	a2,a2,4
    8000691e:	05690c63          	beq	s2,s6,80006976 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006922:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006924:	00042717          	auipc	a4,0x42
    80006928:	98c70713          	addi	a4,a4,-1652 # 800482b0 <disk>
    8000692c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000692e:	01874683          	lbu	a3,24(a4)
    80006932:	fee9                	bnez	a3,8000690c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006934:	2785                	addiw	a5,a5,1
    80006936:	0705                	addi	a4,a4,1
    80006938:	fe979be3          	bne	a5,s1,8000692e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000693c:	57fd                	li	a5,-1
    8000693e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006940:	01205d63          	blez	s2,8000695a <virtio_disk_rw+0xa6>
    80006944:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006946:	000a2503          	lw	a0,0(s4)
    8000694a:	00000097          	auipc	ra,0x0
    8000694e:	cfc080e7          	jalr	-772(ra) # 80006646 <free_desc>
      for(int j = 0; j < i; j++)
    80006952:	2d85                	addiw	s11,s11,1
    80006954:	0a11                	addi	s4,s4,4
    80006956:	ffb918e3          	bne	s2,s11,80006946 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000695a:	85e6                	mv	a1,s9
    8000695c:	00042517          	auipc	a0,0x42
    80006960:	96c50513          	addi	a0,a0,-1684 # 800482c8 <disk+0x18>
    80006964:	ffffc097          	auipc	ra,0xffffc
    80006968:	b14080e7          	jalr	-1260(ra) # 80002478 <sleep>
  for(int i = 0; i < 3; i++){
    8000696c:	f8040a13          	addi	s4,s0,-128
{
    80006970:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006972:	894e                	mv	s2,s3
    80006974:	b77d                	j	80006922 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006976:	f8042583          	lw	a1,-128(s0)
    8000697a:	00a58793          	addi	a5,a1,10
    8000697e:	0792                	slli	a5,a5,0x4

  if(write)
    80006980:	00042617          	auipc	a2,0x42
    80006984:	93060613          	addi	a2,a2,-1744 # 800482b0 <disk>
    80006988:	00f60733          	add	a4,a2,a5
    8000698c:	018036b3          	snez	a3,s8
    80006990:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006992:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006996:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000699a:	f6078693          	addi	a3,a5,-160
    8000699e:	6218                	ld	a4,0(a2)
    800069a0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800069a2:	00878513          	addi	a0,a5,8
    800069a6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800069a8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800069aa:	6208                	ld	a0,0(a2)
    800069ac:	96aa                	add	a3,a3,a0
    800069ae:	4741                	li	a4,16
    800069b0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800069b2:	4705                	li	a4,1
    800069b4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800069b8:	f8442703          	lw	a4,-124(s0)
    800069bc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800069c0:	0712                	slli	a4,a4,0x4
    800069c2:	953a                	add	a0,a0,a4
    800069c4:	058a8693          	addi	a3,s5,88
    800069c8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800069ca:	6208                	ld	a0,0(a2)
    800069cc:	972a                	add	a4,a4,a0
    800069ce:	40000693          	li	a3,1024
    800069d2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800069d4:	001c3c13          	seqz	s8,s8
    800069d8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800069da:	001c6c13          	ori	s8,s8,1
    800069de:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800069e2:	f8842603          	lw	a2,-120(s0)
    800069e6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069ea:	00042697          	auipc	a3,0x42
    800069ee:	8c668693          	addi	a3,a3,-1850 # 800482b0 <disk>
    800069f2:	00258713          	addi	a4,a1,2
    800069f6:	0712                	slli	a4,a4,0x4
    800069f8:	9736                	add	a4,a4,a3
    800069fa:	587d                	li	a6,-1
    800069fc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006a00:	0612                	slli	a2,a2,0x4
    80006a02:	9532                	add	a0,a0,a2
    80006a04:	f9078793          	addi	a5,a5,-112
    80006a08:	97b6                	add	a5,a5,a3
    80006a0a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80006a0c:	629c                	ld	a5,0(a3)
    80006a0e:	97b2                	add	a5,a5,a2
    80006a10:	4605                	li	a2,1
    80006a12:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006a14:	4509                	li	a0,2
    80006a16:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80006a1a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006a1e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006a22:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006a26:	6698                	ld	a4,8(a3)
    80006a28:	00275783          	lhu	a5,2(a4)
    80006a2c:	8b9d                	andi	a5,a5,7
    80006a2e:	0786                	slli	a5,a5,0x1
    80006a30:	97ba                	add	a5,a5,a4
    80006a32:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006a36:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a3a:	6698                	ld	a4,8(a3)
    80006a3c:	00275783          	lhu	a5,2(a4)
    80006a40:	2785                	addiw	a5,a5,1
    80006a42:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a46:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a4a:	100017b7          	lui	a5,0x10001
    80006a4e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a52:	004aa783          	lw	a5,4(s5)
    80006a56:	02c79163          	bne	a5,a2,80006a78 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006a5a:	00042917          	auipc	s2,0x42
    80006a5e:	97e90913          	addi	s2,s2,-1666 # 800483d8 <disk+0x128>
  while(b->disk == 1) {
    80006a62:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006a64:	85ca                	mv	a1,s2
    80006a66:	8556                	mv	a0,s5
    80006a68:	ffffc097          	auipc	ra,0xffffc
    80006a6c:	a10080e7          	jalr	-1520(ra) # 80002478 <sleep>
  while(b->disk == 1) {
    80006a70:	004aa783          	lw	a5,4(s5)
    80006a74:	fe9788e3          	beq	a5,s1,80006a64 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006a78:	f8042903          	lw	s2,-128(s0)
    80006a7c:	00290793          	addi	a5,s2,2
    80006a80:	00479713          	slli	a4,a5,0x4
    80006a84:	00042797          	auipc	a5,0x42
    80006a88:	82c78793          	addi	a5,a5,-2004 # 800482b0 <disk>
    80006a8c:	97ba                	add	a5,a5,a4
    80006a8e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006a92:	00042997          	auipc	s3,0x42
    80006a96:	81e98993          	addi	s3,s3,-2018 # 800482b0 <disk>
    80006a9a:	00491713          	slli	a4,s2,0x4
    80006a9e:	0009b783          	ld	a5,0(s3)
    80006aa2:	97ba                	add	a5,a5,a4
    80006aa4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006aa8:	854a                	mv	a0,s2
    80006aaa:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006aae:	00000097          	auipc	ra,0x0
    80006ab2:	b98080e7          	jalr	-1128(ra) # 80006646 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006ab6:	8885                	andi	s1,s1,1
    80006ab8:	f0ed                	bnez	s1,80006a9a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006aba:	00042517          	auipc	a0,0x42
    80006abe:	91e50513          	addi	a0,a0,-1762 # 800483d8 <disk+0x128>
    80006ac2:	ffffa097          	auipc	ra,0xffffa
    80006ac6:	256080e7          	jalr	598(ra) # 80000d18 <release>
}
    80006aca:	70e6                	ld	ra,120(sp)
    80006acc:	7446                	ld	s0,112(sp)
    80006ace:	74a6                	ld	s1,104(sp)
    80006ad0:	7906                	ld	s2,96(sp)
    80006ad2:	69e6                	ld	s3,88(sp)
    80006ad4:	6a46                	ld	s4,80(sp)
    80006ad6:	6aa6                	ld	s5,72(sp)
    80006ad8:	6b06                	ld	s6,64(sp)
    80006ada:	7be2                	ld	s7,56(sp)
    80006adc:	7c42                	ld	s8,48(sp)
    80006ade:	7ca2                	ld	s9,40(sp)
    80006ae0:	7d02                	ld	s10,32(sp)
    80006ae2:	6de2                	ld	s11,24(sp)
    80006ae4:	6109                	addi	sp,sp,128
    80006ae6:	8082                	ret

0000000080006ae8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006ae8:	1101                	addi	sp,sp,-32
    80006aea:	ec06                	sd	ra,24(sp)
    80006aec:	e822                	sd	s0,16(sp)
    80006aee:	e426                	sd	s1,8(sp)
    80006af0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006af2:	00041497          	auipc	s1,0x41
    80006af6:	7be48493          	addi	s1,s1,1982 # 800482b0 <disk>
    80006afa:	00042517          	auipc	a0,0x42
    80006afe:	8de50513          	addi	a0,a0,-1826 # 800483d8 <disk+0x128>
    80006b02:	ffffa097          	auipc	ra,0xffffa
    80006b06:	162080e7          	jalr	354(ra) # 80000c64 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006b0a:	10001737          	lui	a4,0x10001
    80006b0e:	533c                	lw	a5,96(a4)
    80006b10:	8b8d                	andi	a5,a5,3
    80006b12:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006b14:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006b18:	689c                	ld	a5,16(s1)
    80006b1a:	0204d703          	lhu	a4,32(s1)
    80006b1e:	0027d783          	lhu	a5,2(a5)
    80006b22:	04f70863          	beq	a4,a5,80006b72 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006b26:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b2a:	6898                	ld	a4,16(s1)
    80006b2c:	0204d783          	lhu	a5,32(s1)
    80006b30:	8b9d                	andi	a5,a5,7
    80006b32:	078e                	slli	a5,a5,0x3
    80006b34:	97ba                	add	a5,a5,a4
    80006b36:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b38:	00278713          	addi	a4,a5,2
    80006b3c:	0712                	slli	a4,a4,0x4
    80006b3e:	9726                	add	a4,a4,s1
    80006b40:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006b44:	e721                	bnez	a4,80006b8c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b46:	0789                	addi	a5,a5,2
    80006b48:	0792                	slli	a5,a5,0x4
    80006b4a:	97a6                	add	a5,a5,s1
    80006b4c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006b4e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b52:	ffffc097          	auipc	ra,0xffffc
    80006b56:	ad6080e7          	jalr	-1322(ra) # 80002628 <wakeup>

    disk.used_idx += 1;
    80006b5a:	0204d783          	lhu	a5,32(s1)
    80006b5e:	2785                	addiw	a5,a5,1
    80006b60:	17c2                	slli	a5,a5,0x30
    80006b62:	93c1                	srli	a5,a5,0x30
    80006b64:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b68:	6898                	ld	a4,16(s1)
    80006b6a:	00275703          	lhu	a4,2(a4)
    80006b6e:	faf71ce3          	bne	a4,a5,80006b26 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006b72:	00042517          	auipc	a0,0x42
    80006b76:	86650513          	addi	a0,a0,-1946 # 800483d8 <disk+0x128>
    80006b7a:	ffffa097          	auipc	ra,0xffffa
    80006b7e:	19e080e7          	jalr	414(ra) # 80000d18 <release>
}
    80006b82:	60e2                	ld	ra,24(sp)
    80006b84:	6442                	ld	s0,16(sp)
    80006b86:	64a2                	ld	s1,8(sp)
    80006b88:	6105                	addi	sp,sp,32
    80006b8a:	8082                	ret
      panic("virtio_disk_intr status");
    80006b8c:	00002517          	auipc	a0,0x2
    80006b90:	df450513          	addi	a0,a0,-524 # 80008980 <syscalls+0x400>
    80006b94:	ffffa097          	auipc	ra,0xffffa
    80006b98:	9aa080e7          	jalr	-1622(ra) # 8000053e <panic>

0000000080006b9c <initialize_queue>:
struct queue_struct queue_struct;

void panic(char *) __attribute__((noreturn));

void initialize_queue()
{
    80006b9c:	1141                	addi	sp,sp,-16
    80006b9e:	e422                	sd	s0,8(sp)
    80006ba0:	0800                	addi	s0,sp,16
	int count = 1;
	for (int j = 0; j < 5; j++)
	{
		queue_struct.max_ticks[j] = count;
    80006ba2:	00042797          	auipc	a5,0x42
    80006ba6:	84e78793          	addi	a5,a5,-1970 # 800483f0 <queue_struct>
    80006baa:	4705                	li	a4,1
    80006bac:	c398                	sw	a4,0(a5)
    80006bae:	4709                	li	a4,2
    80006bb0:	c3d8                	sw	a4,4(a5)
    80006bb2:	4711                	li	a4,4
    80006bb4:	c798                	sw	a4,8(a5)
    80006bb6:	4721                	li	a4,8
    80006bb8:	c7d8                	sw	a4,12(a5)
    80006bba:	4741                	li	a4,16
    80006bbc:	cb98                	sw	a4,16(a5)
	for (int j = 0; j < 5; j++)
    80006bbe:	00042697          	auipc	a3,0x42
    80006bc2:	84668693          	addi	a3,a3,-1978 # 80048404 <queue_struct+0x14>
    80006bc6:	00042717          	auipc	a4,0x42
    80006bca:	a6a70713          	addi	a4,a4,-1430 # 80048630 <sched_queue+0x200>
    80006bce:	00042617          	auipc	a2,0x42
    80006bd2:	46260613          	addi	a2,a2,1122 # 80049030 <end+0x200>
		count *= 2;
	}
	for (int i = 0; i < 5; i++)
	{
		queue_struct.back[i] = 0;
    80006bd6:	0006aa23          	sw	zero,20(a3)
		queue_struct.size[i] = 0;
    80006bda:	0006a023          	sw	zero,0(a3)
		for (int j = 0; j < NPROC; j++)
    80006bde:	e0070793          	addi	a5,a4,-512
		{
			sched_queue[i][j] = 0;
    80006be2:	0007b023          	sd	zero,0(a5)
		for (int j = 0; j < NPROC; j++)
    80006be6:	07a1                	addi	a5,a5,8
    80006be8:	fef71de3          	bne	a4,a5,80006be2 <initialize_queue+0x46>
	for (int i = 0; i < 5; i++)
    80006bec:	0691                	addi	a3,a3,4
    80006bee:	20070713          	addi	a4,a4,512
    80006bf2:	fec712e3          	bne	a4,a2,80006bd6 <initialize_queue+0x3a>
		}
	}
}
    80006bf6:	6422                	ld	s0,8(sp)
    80006bf8:	0141                	addi	sp,sp,16
    80006bfa:	8082                	ret

0000000080006bfc <push_queue>:

// Pushes pointer to process in proc table into queue.
void push_queue(struct proc *p, int q_pos)
{
    80006bfc:	1141                	addi	sp,sp,-16
    80006bfe:	e422                	sd	s0,8(sp)
    80006c00:	0800                	addi	s0,sp,16
	sched_queue[q_pos][queue_struct.back[q_pos]] = p;
    80006c02:	00041717          	auipc	a4,0x41
    80006c06:	7ee70713          	addi	a4,a4,2030 # 800483f0 <queue_struct>
    80006c0a:	00858793          	addi	a5,a1,8
    80006c0e:	078a                	slli	a5,a5,0x2
    80006c10:	97ba                	add	a5,a5,a4
    80006c12:	4790                	lw	a2,8(a5)
    80006c14:	00659693          	slli	a3,a1,0x6
    80006c18:	96b2                	add	a3,a3,a2
    80006c1a:	068e                	slli	a3,a3,0x3
    80006c1c:	00042817          	auipc	a6,0x42
    80006c20:	81480813          	addi	a6,a6,-2028 # 80048430 <sched_queue>
    80006c24:	96c2                	add	a3,a3,a6
    80006c26:	e288                	sd	a0,0(a3)
	p->ticks_used = 0;
    80006c28:	2c052623          	sw	zero,716(a0)
	p->curr_wait_time = 0;
    80006c2c:	2a053c23          	sd	zero,696(a0)
	p->in_queue = 1;
    80006c30:	4685                	li	a3,1
    80006c32:	2cd53023          	sd	a3,704(a0)
	p->queue_position = q_pos;
    80006c36:	2cb52423          	sw	a1,712(a0)
	p->queue_entry = ticks;
    80006c3a:	00002697          	auipc	a3,0x2
    80006c3e:	f3e6a683          	lw	a3,-194(a3) # 80008b78 <ticks>
    80006c42:	2ed52223          	sw	a3,740(a0)
	queue_struct.back[q_pos]++;
    80006c46:	2605                	addiw	a2,a2,1
    80006c48:	c790                	sw	a2,8(a5)
	queue_struct.size[q_pos]++;
    80006c4a:	0591                	addi	a1,a1,4
    80006c4c:	058a                	slli	a1,a1,0x2
    80006c4e:	95ba                	add	a1,a1,a4
    80006c50:	41dc                	lw	a5,4(a1)
    80006c52:	2785                	addiw	a5,a5,1
    80006c54:	c1dc                	sw	a5,4(a1)
}
    80006c56:	6422                	ld	s0,8(sp)
    80006c58:	0141                	addi	sp,sp,16
    80006c5a:	8082                	ret

0000000080006c5c <pop_queue>:

// Pops pointer to process from front of queue.
struct proc *
pop_queue(int q_pos)
{
    80006c5c:	1141                	addi	sp,sp,-16
    80006c5e:	e422                	sd	s0,8(sp)
    80006c60:	0800                	addi	s0,sp,16
    80006c62:	872a                	mv	a4,a0
	struct proc *retval = sched_queue[q_pos][0];
    80006c64:	00951893          	slli	a7,a0,0x9
    80006c68:	00041797          	auipc	a5,0x41
    80006c6c:	7c878793          	addi	a5,a5,1992 # 80048430 <sched_queue>
    80006c70:	97c6                	add	a5,a5,a7
    80006c72:	6388                	ld	a0,0(a5)
	sched_queue[q_pos][0] = 0;
    80006c74:	0007b023          	sd	zero,0(a5)
	queue_struct.size[q_pos]--;
    80006c78:	00041597          	auipc	a1,0x41
    80006c7c:	77858593          	addi	a1,a1,1912 # 800483f0 <queue_struct>
    80006c80:	00470613          	addi	a2,a4,4
    80006c84:	060a                	slli	a2,a2,0x2
    80006c86:	962e                	add	a2,a2,a1
    80006c88:	00462803          	lw	a6,4(a2)
    80006c8c:	387d                	addiw	a6,a6,-1
    80006c8e:	01062223          	sw	a6,4(a2)
	queue_struct.back[q_pos]--;
    80006c92:	0721                	addi	a4,a4,8
    80006c94:	070a                	slli	a4,a4,0x2
    80006c96:	972e                	add	a4,a4,a1
    80006c98:	4710                	lw	a2,8(a4)
    80006c9a:	367d                	addiw	a2,a2,-1
    80006c9c:	c710                	sw	a2,8(a4)

	for (int i = 1; i < NPROC; i++)
    80006c9e:	00042697          	auipc	a3,0x42
    80006ca2:	98a68693          	addi	a3,a3,-1654 # 80048628 <sched_queue+0x1f8>
    80006ca6:	96c6                	add	a3,a3,a7
	{
		sched_queue[q_pos][i - 1] = sched_queue[q_pos][i];
    80006ca8:	6798                	ld	a4,8(a5)
    80006caa:	e398                	sd	a4,0(a5)
		if (sched_queue[q_pos][i] == 0)
    80006cac:	c701                	beqz	a4,80006cb4 <pop_queue+0x58>
	for (int i = 1; i < NPROC; i++)
    80006cae:	07a1                	addi	a5,a5,8
    80006cb0:	fed79ce3          	bne	a5,a3,80006ca8 <pop_queue+0x4c>
			break;
	}

	retval->in_queue = 0;
    80006cb4:	2c053023          	sd	zero,704(a0)
	return retval;
}
    80006cb8:	6422                	ld	s0,8(sp)
    80006cba:	0141                	addi	sp,sp,16
    80006cbc:	8082                	ret

0000000080006cbe <remove_queue>:

void remove_queue(struct proc *p, int qpos)
{
    80006cbe:	1141                	addi	sp,sp,-16
    80006cc0:	e422                	sd	s0,8(sp)
    80006cc2:	0800                	addi	s0,sp,16
	int found = -1;
	for (int i = 0; i < NPROC; i++)
    80006cc4:	00959713          	slli	a4,a1,0x9
    80006cc8:	00041797          	auipc	a5,0x41
    80006ccc:	76878793          	addi	a5,a5,1896 # 80048430 <sched_queue>
    80006cd0:	973e                	add	a4,a4,a5
    80006cd2:	4781                	li	a5,0
	int found = -1;
    80006cd4:	587d                	li	a6,-1
	for (int i = 0; i < NPROC; i++)
    80006cd6:	04000613          	li	a2,64
    80006cda:	a029                	j	80006ce4 <remove_queue+0x26>
    80006cdc:	2785                	addiw	a5,a5,1
    80006cde:	0721                	addi	a4,a4,8
    80006ce0:	00c78763          	beq	a5,a2,80006cee <remove_queue+0x30>
		if (sched_queue[qpos][i] == p)
    80006ce4:	6314                	ld	a3,0(a4)
    80006ce6:	fea69be3          	bne	a3,a0,80006cdc <remove_queue+0x1e>
    80006cea:	883e                	mv	a6,a5
    80006cec:	bfc5                	j	80006cdc <remove_queue+0x1e>
			found = i;
	if (found == -1)
    80006cee:	57fd                	li	a5,-1
    80006cf0:	04f80e63          	beq	a6,a5,80006d4c <remove_queue+0x8e>
		return;

	sched_queue[qpos][found] = 0;
    80006cf4:	00659793          	slli	a5,a1,0x6
    80006cf8:	97c2                	add	a5,a5,a6
    80006cfa:	078e                	slli	a5,a5,0x3
    80006cfc:	00041717          	auipc	a4,0x41
    80006d00:	73470713          	addi	a4,a4,1844 # 80048430 <sched_queue>
    80006d04:	97ba                	add	a5,a5,a4
    80006d06:	0007b023          	sd	zero,0(a5)
	for (int i = found + 1; i < NPROC; i++)
    80006d0a:	03e00793          	li	a5,62
    80006d0e:	0307cf63          	blt	a5,a6,80006d4c <remove_queue+0x8e>
    80006d12:	00659713          	slli	a4,a1,0x6
    80006d16:	9742                	add	a4,a4,a6
    80006d18:	00371793          	slli	a5,a4,0x3
    80006d1c:	00041697          	auipc	a3,0x41
    80006d20:	71468693          	addi	a3,a3,1812 # 80048430 <sched_queue>
    80006d24:	97b6                	add	a5,a5,a3
    80006d26:	03e00693          	li	a3,62
    80006d2a:	410686bb          	subw	a3,a3,a6
    80006d2e:	1682                	slli	a3,a3,0x20
    80006d30:	9281                	srli	a3,a3,0x20
    80006d32:	96ba                	add	a3,a3,a4
    80006d34:	068e                	slli	a3,a3,0x3
    80006d36:	00041717          	auipc	a4,0x41
    80006d3a:	70270713          	addi	a4,a4,1794 # 80048438 <sched_queue+0x8>
    80006d3e:	96ba                	add	a3,a3,a4
	{
		sched_queue[qpos][i - 1] = sched_queue[qpos][i];
    80006d40:	6798                	ld	a4,8(a5)
    80006d42:	e398                	sd	a4,0(a5)
		if (sched_queue[qpos][i] == 0)
    80006d44:	c701                	beqz	a4,80006d4c <remove_queue+0x8e>
	for (int i = found + 1; i < NPROC; i++)
    80006d46:	07a1                	addi	a5,a5,8
    80006d48:	fed79ce3          	bne	a5,a3,80006d40 <remove_queue+0x82>
			break;
	}
    80006d4c:	6422                	ld	s0,8(sp)
    80006d4e:	0141                	addi	sp,sp,16
    80006d50:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
