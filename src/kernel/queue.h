#include "param.h"

struct queue_struct {
	int max_ticks[5];
	int size[5];
	int back[5];
};

extern struct queue_struct queue_struct;
extern struct proc *sched_queue[5][NPROC];