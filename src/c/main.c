#include <stdio.h>
#include <stdlib.h>

#include "asm.h"
#include "vm.h"

int main(
	int argument_count,
	char *arguments[]
) {
	if (argument_count<=1) {
		printf(
			"ISO v2 Copyright (C) 2023 Shoelee\n"
			"Usage: iso <file>\n"
			"Options:\n"
			"-d\tDebug mode\n"
		);
		
		return 0;
	}
}