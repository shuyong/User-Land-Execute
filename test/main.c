
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include "uland_exec.h"

void * start_server(void *data)
{
	char **argv = (char**)data;
	int ret;
	ret = uland_execvp(argv[0], argv);
	if (ret != 0)
	    pthread_exit(&ret);
	return 0;
}

int main(int argc, char *argv[])
{
	if (argc < 2) {
		fprintf(stderr, "userland execute: %s programme [argv] ...\n", argv[0]);
		exit(1);
	}


	pthread_t server_thread;

	argc--;
	argv++;
	printf ("execute: %s", argv[0]);
	for (int i = 1; i < argc; i++) {
		printf (" %s", argv[i]);
	}
	printf ("\n");
	pthread_create (&server_thread, NULL, start_server, argv);

	pthread_join(server_thread, NULL);

	exit(EXIT_SUCCESS);
}
