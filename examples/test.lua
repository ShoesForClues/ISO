local lexer    = require "lexer"
local parser   = require "parser"
local compiler = require "compiler"
local vm       = require "vm"

local source=[[
TAG "MSG_START"    REM "Store current stack pointer"
ARR "Hello World!" REM "Push 12 numbers to stack"
TAG "MSG_END"

VAR "MSG_START"    REM "Recall stack pointer and push to stack"
VAR "MSG_END"
INT 0x01           REM "Interrupt program with print request"
INT 0x02           REM "Interrupt program with termination"
]]

local bytecode=compiler:compile(
	parser:parse(
		lexer:lex(
			source,
			"Filename"
		)
	)
)

local context=vm:new()
vm:init(context,bytecode)

while true do
	vm:run(context) --Program pauses when INT register is not 0
	
	if context.INT==0x01 then --Program is requesting to print
		local msg_end   = vm:pop(context) --Pop 2 values from the stack
		local msg_start = vm:pop(context)
		
		print(string.char((unpack or table.unpack)(
			context.stack,msg_start+1,msg_end
		)))
		
		context.INT=0x00 --Set INT register back to 0
	elseif context.INT==0x02 then --Program is requesting to terminate
		break
	else --Unknown interrupt
		print("UNHANDLED INTERRUPT")
		vm:debug(context)
		
		break
	end
end