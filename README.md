# Operating Systems Project - Anuhya, Ronak

<!-- gif or photo -->
![xv6-os](./demo.gif)

This repository contains the enhanced XV-6 operating system (developed by MIT) group project made in my second year (October 2022).

An extension of the [MIT](https://github.com/mit-pdos)'s [xv6 Operating System for RISC-V](https://github.com/mit-pdos/xv6-riscv).

 The following features were added to the operating system:
 - System calls: `strace`, `sigalarm` and `sigreturn`
 - Scheduling algorithms: `FCFS`, `PBS`, `MLFQ` and `LBS`
 - Copy-on-write fork

 Detailed analysis of the project is also given below.

## Installation

You can follow the install instructions [here](https://pdos.csail.mit.edu/6.S081/2020/tools.html). (Skip the Athena part)


## Running the OS

Navigate to the `src` directory.

```sh
$ make clean
$ make qemu SCHEDULER=[RR/PBS/FCFS/LB/MLFQ] CPUS=[N_CPU]
```


# Specification 1: System Calls

Running:
```sh
$ strace [mask] [command] [args]
```

Usage: Run the command `alarmtest` to test the alarm system calls.

1. system calls pass through the function `syscall` in `syscall.c`. We implement strace, sigalarm and sigreturn by making changes here. 
2. We add a variable `trace_mask` to the `proc` datastructure and initialize its value to 0. This variable records which syscalls must be printed by strace. 
3. We then add the strace syscall which simply sets the mask to the value of the argument passed to it. This is achieved using argint function.
4. Now in `syscall`, we print the bits in the mask that are set. So, we print the information corresponding to that bit.
5. Because there is no easy way to know how many arguments each syscall accepts we hardcode them in an array.
6. After the syscall has executed just print the required syscall traces with the saved values.
7. We do some book-keeping in user files like usys.pl, user.h and make a new file called strace.c
8. A new system call called sigalarm and sigreturn were added. The syscall sigalarm call with parameter n calls function f after every n ticks of CPU time. sigreturn resets the process state.
9. alarmtest.c file was added to check the working of these system calls.
10. New variables were added to keep track of alarm ticks and handler for every process. 

# Specification 2: Scheduling

Usage: Run the command `schedulertest` to test the scheduler.

1. We add a macro `SCHEDULER` to the makefile so we can select the scheduler. It accepts arguments of the form `make qemu SCHEDULER=S CPUS=1` where `S` can be
	a. RR (this is also taken to be the default)
	b. FCFS
	c. PBS
	d. MLFQ
2. `waitx` system call was taken from tutorial and `schedulertest.c` was made to test our schedulers.

## FCFS
1. Iterate through the process table and select the process with lowest creation time.
2. Creation time is tracked by adding a variable to proc and initializing it with the value of `ticks`.
3. We continually acquire and release locks of processes except for the current best process where we don't release. We then context switch to that process to start executing it.
4. We disable `yield()` due to timer interrupt on.
5. Note, FCFS is non preemptive.


## PBS
1. Create a new variable to represent priority and set its default value to 60.
2. Add new variables to check the number of ticks the process was sleeping and running from the last time it was scheduled.
3. Make `update_time()` function which runs in every timer interrupt. It updates rtime, stime etc of various processes.
4. Our variables have been accounted for, we can implement the algorithm by making it pick the process based on the DP value and niceness considerations.
5. Make a new syscall which modifies the value of the static_priority value a process has.

## MLFQ
1. We create a new file `queue.c` and implement the functions of a simple queue datastructure namely `push_queue`, `pop_queue` and `remove_queue`that works on static memory and allocation.
2. Now in the MLFQ scheduler, we begin by checking for any processes in RUNNABLE state. If found and they're not already in the queue, we add them to the priority 0 queue.
3. Now, in the scheduler, we go in order from the priority 0 queue to the priority 4 queue and execute processes in it in order. If a process was found when iterating in this order, we immediately execute it.
4. CPU yields only if the ticks occupied by a process after incrementing exceeds its limit. 
5. We yield process of higher priority and preempt the other process out of the queue.
6. If the process relinquishes control of the CPU for any reason without using its entire timeslice, then we put it back in the same queue.
7. We implement this as follows. Before execution it is popped from queue, in `trap.c` if we find a better priority process to preempt or the process is giving up control then we push it back into the same priority queue and yield cpu. Otherwise it has finished its time slice and we push it into the next queue. 
8. After this is done, we implement aging in a similar fashion. Before pushing stuff into the queue in scheduler, check if any process has wait time > MAXWAITTIME. If yes, move it up one priority. We can keep track of wait time again in `update_time` as implemented before.
9. `MAXWAITTIME` is defined in `params.h` and we implement moving up a priority by removing from original queue and pushing it up a queue.

## LBS
1. In proportion to the number of tickets owned, each process is assigned a time slice.
2. By default, each process will get one ticket.
3. We implemented a system call `int settickets(int number)` which sets the number of tickets of the calling process i.e using this system call we can raise the number of tickets it recieves, and thus receive a higher proportion of CPU cycles.
4. In `proc.h` we declare a new variable called `tickets`. It is used to assign the number of tickets allowed for each process.
5. Whenever the tickets are changed using `settickets()`, we update the proc structures tickets variable is updated and the CPU time is also alloted accordingly.

# Specification 3: Copy-on-write fork
1. In COW fork the parent and child initially share all physical pages, but map them read-only. 
2. When the child or parent executes a store instruction, the RISC-V CPU raises a page-fault exception and the kernel makes a copy of the page that contains the faulted address. 
3. It maps one copy read/write in the child’s address space and the other copy read/write in the parent’s address space. 
4. After updating the page tables, the kernel resumes the faulting process at the instruction that caused the fault. Because the kernel has updated the relevant PTE to allow writes, the faulting instruction will now execute without a fault.

# Analysis
Upon running the schedulertest function on all the different schedulers, we got the following results.

> MLFQ:  Average rtime 29,  wtime 263	| 1 CPU
> PBS:   Average rtime 27,  wtime 247	| 1 CPU
> FCFS:  Average rtime 23,  wtime 128	| 1 CPU
> LBS:   Average rtime 28 , wtime 237   | 1 CPU
> RR:    Average rtime 44,  wtime 118	| 3 CPUs 

