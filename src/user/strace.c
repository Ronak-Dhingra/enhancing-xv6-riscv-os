// made for spec-1, syscall-1
#include "user/user.h"

int main(int argc, char *argv[])
{
    if (argc >= 3)
    {
        int pid = fork();
        if (pid == 0)
        {
            trace(atoi(argv[1]));
            exec(argv[2], argv + 2);
            exit(0);
        }
        wait(0);
        exit(0);
    }
    else
    {
        printf("ERROR\n");
        exit(1);
    }
}