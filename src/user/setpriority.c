#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
	if(argc < 2)
	{
	  printf("ERROR\n");
  	  exit(1);
	}
	set_priority(atoi(argv[1]), atoi(argv[2]));

	exit(0);
}