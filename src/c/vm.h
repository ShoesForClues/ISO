#ifndef ISO_VM_H
#define ISO_VM_H

/* Operation codes */

#define ISO_OP_NOP 0x00
#define ISO_OP_INT 0x10
#define ISO_OP_RSP 0x11
#define ISO_OP_NUM 0x20
#define ISO_OP_ARR 0x21
#define ISO_OP_INC 0x30
#define ISO_OP_DEC 0x31
#define ISO_OP_DUP 0x32
#define ISO_OP_POP 0x33
#define ISO_OP_ROT 0x34
#define ISO_OP_SET 0x40
#define ISO_OP_GET 0x41
#define ISO_OP_JMP 0x50
#define ISO_OP_JEQ 0x51
#define ISO_OP_JNE 0x52
#define ISO_OP_JLS 0x53
#define ISO_OP_JLE 0x54
#define ISO_OP_ADD 0x60
#define ISO_OP_SUB 0x61
#define ISO_OP_MUL 0x62
#define ISO_OP_DIV 0x63
#define ISO_OP_POW 0x64
#define ISO_OP_MOD 0x65
#define ISO_OP_NOT 0x70
#define ISO_OP_AND 0x71
#define ISO_OP_BOR 0x72
#define ISO_OP_XOR 0x73
#define ISO_OP_LSH 0x74
#define ISO_OP_RSH 0x75

/* Interrupt codes */

#define ISO_INT_ILLEGAL_INSTRUCTION 0x0100
#define ISO_INT_ILLEGAL_JUMP        0x0101
#define ISO_INT_END_OF_PROGRAM      0x0102
#define ISO_INT_STACK_OVERFLOW      0x0200
#define ISO_INT_STACK_UNDERFLOW     0x0201
#define ISO_INT_OUT_OF_BOUNDS       0x0202

typedef double        iso_word;
typedef unsigned int  iso_uint;
typedef unsigned char iso_char;

typedef struct {
	iso_uint  INT;
	iso_uint  PC;
	iso_uint  SP;
	iso_uint  program_size;
	iso_uint  stack_size;
	iso_char *program;
	iso_word *stack;
} iso_vm;

void iso_vm_init(
	iso_vm *context,
	iso_char *program,
	iso_uint program_size,
	iso_word *stack,
	iso_uint stack_size
) {
	context->INT          = 0;
	context->PC           = 0;
	context->SP           = 0;
	context->program_size = program_size;
	context->stack_size   = stack_size;
	context->program      = program;
	context->stack        = stack;
}

iso_char iso_vm_fetch(
	iso_vm *context
) {
	iso_uint  PC           = context->PC;
	iso_uint  program_size = context->program_size;
	iso_char *program      = context->program;
	
	if (PC==program_size) {
		context->INT=ISO_INT_END_OF_PROGRAM;
		
		return 0;
	}
	
	context->PC = PC+1;
	
	return program[PC];
}

void iso_vm_push(
	iso_vm *context,
	iso_word value
) {
	iso_uint  SP         = context->SP;
	iso_uint  stack_size = context->stack_size;
	iso_word *stack      = context->stack;
	
	if (SP>=stack_size) {
		context->INT=ISO_INT_STACK_OVERFLOW;
		
		return;
	}
	
	context->SP = SP+1;
	stack[SP]   = value;
}

iso_word iso_vm_pop(
	iso_vm *context
) {
	iso_uint  SP    = context->SP;
	iso_word *stack = context->stack;
	
	if (SP==0) {
		context->INT=ISO_INT_STACK_UNDERFLOW;
		
		return 0;
	}
	
	context->SP=SP-1;
	
	return stack[SP];
}

void iso_vm_set(
	iso_vm *context,
	iso_uint address,
	iso_word value
) {
	iso_uint  SP    = context->SP;
	iso_word *stack = context->stack;
	
	if (address>=SP) {
		context->INT=ISO_INT_OUT_OF_BOUNDS;
		
		return;
	}
	
	context->stack[address]=value;
}

iso_word iso_vm_get(
	iso_vm *context,
	iso_uint address
) {
	iso_uint  SP    = context->SP;
	iso_word *stack = context->stack;
	
	if (address>=SP) {
		context->INT=ISO_INT_OUT_OF_BOUNDS;
		
		return 0;
	}
	
	return context->stack[address];
}

void iso_vm_goto(
	iso_vm *context,
	iso_uint address
) {
	if (address>=context->program_size)
		context->INT=ISO_INT_ILLEGAL_JUMP;
	
	context->PC=address;
}

iso_uint iso_vm_run(
	iso_vm *context
) {
	if (context->INT!=0)
		return context->INT;
	
	/* Registers */
	
	iso_uint *INT = &context->INT;
	iso_uint *PC  = &context->PC;
	iso_uint *SP  = &context->SP;
	
	/* Working variables */
	
	iso_uint A,B;
	iso_word D,E;
	
	do {
		switch(iso_vm_fetch(context)) {
			case ISO_OP_NOP:
				break;
			case ISO_OP_INT:
				*INT=(iso_uint)iso_vm_fetch(context);
				
				break;
			case ISO_OP_RSP:
				iso_vm_push(context,(iso_word)*SP);
				
				break;
			case ISO_OP_NUM:
				A = 0;
				
				for (iso_char i=0; i<iso_vm_fetch(context); i+=1)
					A = (A<<8)|(iso_uint)iso_vm_fetch(context);
				
				iso_vm_push(context,(iso_word)A);
				
				break;
			case ISO_OP_INC:
				for (iso_uint i=0; i<(iso_uint)iso_vm_pop(context); i++)
					iso_vm_push(context,0);
				
				break;
			case ISO_OP_DEC:
				for (iso_uint i=0; i<(iso_uint)iso_vm_pop(context); i++)
					iso_vm_pop(context);
				
				break;
			case ISO_OP_DUP:
				if (*SP==0)
					break;
				
				iso_vm_push(context,iso_vm_get(context,*SP-1));
				
				break;
			case ISO_OP_POP:
				iso_vm_pop(context);
				
				break;
			case ISO_OP_ROT:
				if (*SP<2)
					break;
				
				D = iso_vm_get(context,*SP-2);
				E = iso_vm_get(context,*SP-1);
				
				iso_vm_set(context,*SP-2,E);
				iso_vm_set(context,*SP-1,D);
				
				break;
			case ISO_OP_JMP:
				A = (iso_uint)iso_vm_pop(context);
				
				iso_vm_goto(context,A);
				
				break;
			case ISO_OP_JEQ:
				A = (iso_uint)iso_vm_pop(context);
				E = iso_vm_pop(context);
				D = iso_vm_pop(context);
				
				if (D==E)
					iso_vm_goto(context,A);
				
				break;
			case ISO_OP_JNE:
				A = (iso_uint)iso_vm_pop(context);
				E = iso_vm_pop(context);
				D = iso_vm_pop(context);
				
				if (D!=E)
					iso_vm_goto(context,A);
				
				break;
			case ISO_OP_JLS:
				A = (iso_uint)iso_vm_pop(context);
				E = iso_vm_pop(context);
				D = iso_vm_pop(context);
				
				if (D<E)
					iso_vm_goto(context,A);
				
				break;
			case ISO_OP_JLE:
				A = (iso_uint)iso_vm_pop(context);
				E = iso_vm_pop(context);
				D = iso_vm_pop(context);
				
				if (D<=E)
					iso_vm_goto(context,A);
				
				break;
			case ISO_OP_ADD:
				E = iso_vm_pop(context);
				D = iso_vm_pop(context);
				
				iso_vm_push(context,D+E);
				
				break;
			case ISO_OP_SUB:
				E = iso_vm_pop(context);
				D = iso_vm_pop(context);
				
				iso_vm_push(context,D-E);
				
				break;
			case ISO_OP_MUL:
				E = iso_vm_pop(context);
				D = iso_vm_pop(context);
				
				iso_vm_push(context,D*E);
				
				break;
			case ISO_OP_DIV:
				E = iso_vm_pop(context);
				D = iso_vm_pop(context);
				
				iso_vm_push(context,D/E);
				
				break;
			case ISO_OP_NOT:
				A = (iso_uint)iso_vm_pop(context);
				
				iso_vm_push(context,(iso_word)~A);
				
				break;
			case ISO_OP_AND:
				B = (iso_uint)iso_vm_pop(context);
				A = (iso_uint)iso_vm_pop(context);
				
				iso_vm_push(context,(iso_word)(A&B));
				
				break;
			case ISO_OP_BOR:
				B = (iso_uint)iso_vm_pop(context);
				A = (iso_uint)iso_vm_pop(context);
				
				iso_vm_push(context,(iso_word)(A|B));
				
				break;
			case ISO_OP_XOR:
				B = (iso_uint)iso_vm_pop(context);
				A = (iso_uint)iso_vm_pop(context);
				
				iso_vm_push(context,(iso_word)(A^B));
				
				break;
			case ISO_OP_LSH:
				B = (iso_uint)iso_vm_pop(context);
				A = (iso_uint)iso_vm_pop(context);
				
				iso_vm_push(context,(iso_word)(A<<B));
				
				break;
			case ISO_OP_RSH:
				B = (iso_uint)iso_vm_pop(context);
				A = (iso_uint)iso_vm_pop(context);
				
				iso_vm_push(context,(iso_word)(A>>B));
				
				break;
			default:
				*INT=ISO_INT_ILLEGAL_INSTRUCTION;
		}
	} while (*INT==0);
	
	return *INT;
}

#endif