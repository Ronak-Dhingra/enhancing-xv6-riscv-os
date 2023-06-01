#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"
#include "queue.h"

struct proc *sched_queue[5][NPROC];
struct queue_struct queue_struct;

void panic(char *) __attribute__((noreturn));

void initialize_queue()
{
	int count = 1;
	for (int j = 0; j < 5; j++)
	{
		queue_struct.max_ticks[j] = count;
		count *= 2;
	}
	for (int i = 0; i < 5; i++)
	{
		queue_struct.back[i] = 0;
		queue_struct.size[i] = 0;
		for (int j = 0; j < NPROC; j++)
		{
			sched_queue[i][j] = 0;
		}
	}
}

// Pushes pointer to process in proc table into queue.
void push_queue(struct proc *p, int q_pos)
{
	sched_queue[q_pos][queue_struct.back[q_pos]] = p;
	p->ticks_used = 0;
	p->curr_wait_time = 0;
	p->in_queue = 1;
	p->queue_position = q_pos;
	p->queue_entry = ticks;
	queue_struct.back[q_pos]++;
	queue_struct.size[q_pos]++;
}

// Pops pointer to process from front of queue.
struct proc *
pop_queue(int q_pos)
{
	struct proc *retval = sched_queue[q_pos][0];
	sched_queue[q_pos][0] = 0;
	queue_struct.size[q_pos]--;
	queue_struct.back[q_pos]--;

	for (int i = 1; i < NPROC; i++)
	{
		sched_queue[q_pos][i - 1] = sched_queue[q_pos][i];
		if (sched_queue[q_pos][i] == 0)
			break;
	}

	retval->in_queue = 0;
	return retval;
}

void remove_queue(struct proc *p, int qpos)
{
	int found = -1;
	for (int i = 0; i < NPROC; i++)
		if (sched_queue[qpos][i] == p)
			found = i;
	if (found == -1)
		return;

	sched_queue[qpos][found] = 0;
	for (int i = found + 1; i < NPROC; i++)
	{
		sched_queue[qpos][i - 1] = sched_queue[qpos][i];
		if (sched_queue[qpos][i] == 0)
			break;
	}
}