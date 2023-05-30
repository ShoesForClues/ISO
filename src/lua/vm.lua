--[[
INTERRUPT STATUS CODES

0x01 - INVALID OPCODE
0x02 - STACK UNDERFLOW
0x03 - STACK OVERFLOW
0x04 - OUT OF BOUNDS
0x05 - EOL
]]

local bit=bit32 or require("bit")

local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local bit_and    = bit.band
local bit_or     = bit.bor
local bit_xor    = bit.bxor
local bit_not    = bit.bnot

local vm={}

-------------------------------------------------------------------------------

vm.new=function(vm)
	local context={
		INT     = 0x00000000,
		PC      = 0x00000001,
		SP      = 0x00000001,
		program = {},
		stack   = {}
	}
	
	return context
end

vm.init=function(vm,context,program)
	context.INT     = 0x00000000
	context.PC      = 0x00000001
	context.SP      = 0x00000001
	context.program = program
	context.stack   = {}
end

vm.run=function(vm,context)
	local program = context.program
	
	while context.INT==0 do
		if context.INT~=0 then
			break
		elseif context.SP<1 then
			context.INT=0x02
			
			break
		elseif (
			context.PC<1 or 
			context.PC>#program
		) then
			context.INT=0x05
			
			break
		end
		
		local opcode=program[context.PC]
		
		if vm.execute[opcode] then
			vm.execute[opcode](context)
		else
			context.INT=0x01
		end
	end
	
	return context.INT
end

vm.step=function(vm,context)
	local program = context.program
	local opcode  = program[context.PC]
	
	if context.INT~=0 then
		return context.INT
	elseif context.SP<1 then
		context.INT=0x02
		
		return context.INT
	elseif (
		context.PC<1 or 
		context.PC>#program
	) then
		context.INT=0x05
		
		return context.INT
	end
	
	if vm.execute[opcode] then
		vm.execute[opcode](context)
	else
		context.INT=0x01
	end
	
	return context.INT
end

vm.debug=function(vm,context)
	print(("INT: %.8X\tPC: %.8X\tSP: %.8X"):format(
		context.INT,
		context.PC,
		context.SP
	))
end

vm.push=function(vm,context,value)
	local SP    = context.SP
	local stack = context.stack
	
	stack[SP]  = value
	context.SP = SP+1
end

vm.pop=function(vm,context)
	local SP    = context.SP
	local stack = context.stack
	local value = stack[SP-1]
	
	stack[SP-1]  = nil
	context.SP = SP-1
	
	return value
end

-------------------------------------------------------------------------------

vm.execute={}

vm.execute[0x00]=function(context) --NOP
	context.PC=context.PC+1
end

vm.execute[0x10]=function(context) --INT
	local PC      = context.PC
	local program = context.program
	
	context.INT = program[PC+1]
	context.PC  = PC+2
end

vm.execute[0x11]=function(context) --REG
	local INT      = context.INT
	local PC       = context.PC
	local SP       = context.SP
	local stack    = context.stack
	local register = context.program[PC+1]
	
	if register==0x00 then
		stack[SP]=INT
	elseif register==0x01 then
		stack[SP]=PC
	elseif register==0x02 then
		stack[SP]=SP-1
	else
		context.INT=0x11
	end
	
	context.SP = SP+1
	context.PC = PC+2
end

vm.execute[0x20]=function(context) --NUM
	local PC      = context.PC
	local SP      = context.SP
	local program = context.program
	local stack   = context.stack
	
	stack[SP]  = program[PC+1]
	context.SP = SP+1
	context.PC = PC+2
end

vm.execute[0x21]=function(context) --ARR
	local PC      = context.PC
	local SP      = context.SP
	local stack   = context.stack
	local program = context.program
	local length  = program[PC+1]
	
	for i=1,length do
		stack[SP+i-1]=program[PC+i+1]
	end
	
	context.SP = SP+length
	context.PC = PC+length+2
end

vm.execute[0x30]=function(context) --INC
	local PC    = context.PC
	local SP    = context.SP
	local stack = context.stack
	local count = stack[SP-1]
	
	for i=1,count do
		stack[SP+i-2]=0x00
	end
	
	context.SP = SP+count-1
	context.PC = PC+1
end

vm.execute[0x31]=function(context) --DEC
	local PC    = context.PC
	local SP    = context.SP
	local stack = context.stack
	local count = stack[SP-1]
	
	for i=SP-1,SP-count-1,-1 do
		stack[i]=nil
	end
	
	context.SP = SP-count-1
	context.PC = PC+1
end

vm.execute[0x32]=function(context) --DUP
	local PC    = context.PC
	local SP    = context.SP
	local stack = context.stack
	
	stack[SP]  = stack[SP-1]
	context.SP = SP+1
	context.PC = PC+1
end

vm.execute[0x33]=function(context) --POP
	local PC    = context.PC
	local SP    = context.SP
	local stack = context.stack
	
	stack[SP-1] = nil
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x34]=function(context) --ROT
	local PC    = context.PC
	local SP    = context.SP
	local stack = context.stack
	
	stack[SP-2],stack[SP-1] = stack[SP-1],stack[SP-2]
	context.PC              = PC+1
end

vm.execute[0x40]=function(context) --SET
	local PC      = context.PC
	local SP      = context.SP
	local stack   = context.stack
	local address = stack[SP-1]+1
	local value   = stack[SP-2]
	
	if address<1 or address>=SP then
		context.INT=0x04
	else
		stack[address] = value
		context.SP     = SP-2
		context.PC     = PC+1
	end
end

vm.execute[0x41]=function(context) --GET
	local PC      = context.PC
	local SP      = context.SP
	local stack   = context.stack
	local address = stack[SP-1]+1
	
	if address<1 or address>=SP then
		context.INT=0x04
	else
		stack[SP-1] = stack[address]
		context.PC  = PC+1
	end
end

vm.execute[0x50]=function(context) --JMP
	local PC      = context.PC
	local SP      = context.SP
	local program = context.program
	local stack   = context.stack
	local address = stack[SP-1]+1
	
	stack[SP-1] = nil
	context.SP  = SP-1
	context.PC  = address
end

vm.execute[0x51]=function(context) --JEQ
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local address   = stack[SP-1]+1
	local operand_a = stack[SP-3]
	local operand_b = stack[SP-2]
	
	stack[SP-1] = nil
	stack[SP-2] = nil
	stack[SP-3] = nil
	context.SP  = SP-3
	context.PC  = operand_a==operand_b and address or PC+1
end

vm.execute[0x52]=function(context) --JNE
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local address   = stack[SP-1]+1
	local operand_a = stack[SP-3]
	local operand_b = stack[SP-2]
	
	stack[SP-1] = nil
	stack[SP-2] = nil
	stack[SP-3] = nil
	context.SP  = SP-3
	context.PC  = operand_a~=operand_b and address or PC+1
end

vm.execute[0x53]=function(context) --JLS
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local address   = stack[SP-1]+1
	local operand_a = stack[SP-3]
	local operand_b = stack[SP-2]
	
	stack[SP-1] = nil
	stack[SP-2] = nil
	stack[SP-3] = nil
	context.SP  = SP-3
	context.PC  = operand_a<operand_b and address or PC+1
end

vm.execute[0x54]=function(context) --JLE
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local address   = stack[SP-1]+1
	local operand_a = stack[SP-3]
	local operand_b = stack[SP-2]
	
	stack[SP-1] = nil
	stack[SP-2] = nil
	stack[SP-3] = nil
	context.SP  = SP-3
	context.PC  = operand_a<=operand_b and address or PC+1
end

vm.execute[0x60]=function(context) --ADD
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = operand_a+operand_b
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x61]=function(context) --SUB
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = operand_a-operand_b
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x62]=function(context) --MUL
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = operand_a*operand_b
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x63]=function(context) --DIV
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = operand_a/operand_b
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x64]=function(context) --POW
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = operand_a^operand_b
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x65]=function(context) --MOD
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = operand_a%operand_b
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x70]=function(context) --NOT
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local stack     = context.stack
	
	stack[SP-1] = bit_not(stack[SP-1])
	context.PC  = PC+1
end

vm.execute[0x71]=function(context) --AND
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = bit_and(operand_a,operand_b)
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x72]=function(context) --BOR
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = bit_or(operand_a,operand_b)
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x73]=function(context) --XOR
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = bit_xor(operand_a,operand_b)
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x74]=function(context) --LSH
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = bit_lshift(operand_a,operand_b)
	context.SP  = SP-1
	context.PC  = PC+1
end

vm.execute[0x75]=function(context) --RSH
	local PC        = context.PC
	local SP        = context.SP
	local program   = context.program
	local operand_a = stack[SP-2]
	local operand_b = stack[SP-1]
	
	stack[SP-1] = nil
	stack[SP-2] = bit_rshift(operand_a,operand_b)
	context.SP  = SP-1
	context.PC  = PC+1
end

-------------------------------------------------------------------------------

return vm