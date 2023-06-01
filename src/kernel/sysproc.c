#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

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

uint64
sys_trace(void)
{
  int num;
  argint(0, &num);
  myproc()->trace_mask = num;
  return 0;
}

uint64
sys_sigalarm(void)
{
  int ticks, handle;
  argint(0, &ticks);
  argint(1, &handle);
  if (ticks >= 0)
  {
    struct proc *proc = myproc();
    proc->handler = (uint64)handle;
    proc->alarm_ticks = 0;
    proc->max_alarm_ticks = ticks;
    return 0;
  }
  return -1;
}

uint64
sys_sigreturn(void)
{
  struct proc *p = myproc();
  if (p->alarm_ticks == -1)
  {
    p->alarm_ticks = 0;
    memmove(p->trapframe, &p->alarm_trap, sizeof(p->alarm_trap));
    return 0;
  }
  return -1;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1);
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sys_set_priority(void)
{
  int priority = 0;
  int pid = 0;
  argint(0, &priority);
  argint(1, &pid);
  return set_static_priority(priority, pid);
}

uint64
sys_settickets(void)
{
  int num;
  argint(0, &num);

  if(num>=1)
  {
    settickets(num);
    return 0;
  }
  return -1;
}