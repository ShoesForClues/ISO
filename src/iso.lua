--[[
MIT License

Copyright (c) 2023 Shoelee

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local lexer    = require "lexer"
local parser   = require "parser"
local compiler = require "compiler"
local vm       = require "vm"

-------------------------------------------------------------------------------

local function report(message)
	print(
		string.char(27).."[91m[FATAL ERROR]"..
		string.char(27).."[0m "..
		message
	)
	os.exit(1)
end

local function list(bytecode)
	local i=1
	
	while i<=#bytecode do
		if bytecode[i]==0x11 then
			print(("%.8X | %.2X %.2X"):format(
				i,
				bytecode[i],
				bytecode[i+1]
			))
			
			i=i+2
		elseif bytecode[i]==0x10 or bytecode[i]==0x20 then
			print(("%.8X | %.2X %.8X"):format(
				i,
				bytecode[i],
				bytecode[i+1]
			))
			
			i=i+2
		elseif bytecode[i]==0x21 then
			print(("%.8X | %.2X %.2X "..("%.8X "):rep(bytecode[i+1])):format(
				i,(unpack or table.unpack)(bytecode,i,i+bytecode[i+1]+1)
			))
			
			i=i+bytecode[i+1]+2
		else
			print(("%.8X | %.2X"):format(i,bytecode[i]))
			
			i=i+1
		end
	end
end

-------------------------------------------------------------------------------

if #arg==0 then
	print("ISO v0 Copyright (C) 2023 Shoelee")
	print("Usage: iso <file>")
	print("Options:")
	print("-d	Debug mode")
	print("-l	List bytecode")
	
	return
end

local source     = {}
local debug_mode = false

for _,arg in ipairs(arg) do --Super rudimentary arg parsing
	if arg:sub(1,1)=="-" then
		if arg:lower()=="-d" then
			debug_mode=true
		elseif arg:lower()=="-l" then
			list(compiler:compile(source))
			return
		else
			report("Invalid option: '"..arg.."'")
		end
	else
		local file=io.open(arg,"r")
		
		if not file then
			report("Cannot read file: '"..arg.."'")
		end
		
		local oplist=parser:parse(
			lexer:lex(
				file:read("*a"),
				arg
			)
		)
		
		file:close()
		
		for _,op in ipairs(oplist) do
			source[#source+1]=op
		end
	end
end

local filename = arg[1]
local file     = io.open(filename,"r")

if not file then
	report("Cannot read file: '"..filename.."'")
end

local vm_context=vm:new()

vm:init(
	vm_context,
	compiler:compile(source)
)

file:close()

while true do
	vm:step(vm_context)
	
	if debug_mode then
		os.execute(("title INT: %.8X PC: %.8X SP: %.8X"):format(
			vm_context.INT,
			vm_context.PC,
			vm_context.SP
		))
	end
	
	if vm_context.INT==0x10 then
		print(vm_context.stack[vm_context.SP-1])
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x11 then
		io.write(string.char(vm_context.stack[vm_context.SP-1]))
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x12 then
		local msg_end   = vm:pop(vm_context)
		local msg_start = vm:pop(vm_context)
		
		print(string.char((unpack or table.unpack)(
			vm_context.stack,msg_start+1,msg_end
		)))
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x20 then
		local input=io.read("*l")
		
		for i=1,#input do
			vm:push(vm_context,input:sub(i,i):byte())
		end
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x0E then
		break
	elseif vm_context.INT~=0 then
		print("UNHANDLED EXCEPTION")
		vm:debug(vm_context)
		
		break
	end
end