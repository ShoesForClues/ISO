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

local function list(context)
	local bytecode = context.bytecode
	local sections = context.sections
	
	local i = 1
	local j = 1
	
	while i<=#bytecode do
		local section
		
		if sections[j] and i==sections[j].address+1 then
			section=string.char((unpack or table.unpack)(
				sections[j].tag
			))
			
			j=j+1
		end
		
		if bytecode[i]==0x11 then
			io.write(("%.8X | %.2X %.2X"):format(
				i,
				bytecode[i],
				bytecode[i+1]
			))
			
			i=i+2
		elseif bytecode[i]==0x10 or bytecode[i]==0x20 then
			io.write(("%.8X | %.2X %.8X"):format(
				i,
				bytecode[i],
				bytecode[i+1]
			))
			
			i=i+2
		elseif bytecode[i]==0x21 then
			io.write(("%.8X | %.2X %.2X "..("%.8X "):rep(bytecode[i+1])):format(
				i,(unpack or table.unpack)(bytecode,i,i+bytecode[i+1]+1)
			))
			
			i=i+bytecode[i+1]+2
		else
			io.write(("%.8X | %.2X"):format(i,bytecode[i]))
			
			i=i+1
		end
		
		print(section and " - "..section or "")
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
	compiler:compile(source).bytecode
)

file:close()

local process_handles = {}
local file_handles    = {}

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
		
		io.write(string.char((unpack or table.unpack)(
			vm_context.stack,
			msg_start+1,
			msg_end
		)))
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x20 then
		local input=io.read("*l")
		
		for i=1,#input do
			vm:push(vm_context,input:sub(i,i):byte())
		end
		
		vm_context.INT=0x00
	elseif vm_context.INT==0xE0 then
		local cmd_end   = vm:pop(vm_context)
		local cmd_start = vm:pop(vm_context)
		
		process_handles[#process_handles+1]=io.popen(
			string.char((unpack or table.unpack)(
				vm_context.stack,
				cmd_start+1,
				cmd_end
			))
		)
		
		vm:push(vm_context,#process_handles)
		
		vm_context.INT=0x00
	elseif vm_context.INT==0xE1 then
		local handle=vm:pop(vm_context)
		
		process_handles[handle]:close()
		table.remove(process_handles,handle)
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x0E then
		break
	elseif vm_context.INT==0x24 then --TIME
		vm:push(vm_context,os.clock())
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x30 then --FILE OPEN
		local mode           = vm:pop(vm_context)
		local filename_end   = vm:pop(vm_context)
		local filename_start = vm:pop(vm_context)
		local handle
		
		if mode==0x00 then
			handle=io.open(
				string.char((unpack or table.unpack)(
					vm_context.stack,
					filename_start+1,
					filename_end
				)),
				"rb"
			)
		elseif mode==0x01 then
			handle=io.open(
				string.char((unpack or table.unpack)(
					vm_context.stack,
					filename_start+1,
					filename_end
				)),
				"wb"
			)
		end
		
		file_handles[#file_handles+1]=handle
		
		vm:push(vm_context,#file_handles)
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x31 then --FILE CLOSE
		local id = vm:pop(vm_context)
		
		file_handles[id]:close()
		
		table.remove(file_handles,id)
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x32 then --FILE SIZE
		local id     = vm:pop(vm_context)
		local handle = file_handles[id]
		
		local current = handle:seek()
        local size    = handle:seek("end")
        handle:seek("set", current)
		
		vm:push(vm_context,size)
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x33 then --FILE SEEK
		local id      = vm:pop(vm_context)
		local address = vm:pop(vm_context)
		local handle  = file_handles[id]
		
		handle:seek("set",address)
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x34 then --FILE READ
		local id     = vm:pop(vm_context)
		local handle = file_handles[id]
		local value  = handle:read(1):byte()
		
		vm:push(vm_context,value)
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x35 then --FILE WRITE
		local id     = vm:pop(vm_context)
		local value  = vm:pop(vm_context)
		local handle = file_handles[id]
		
		handle:write(value)
		
		vm_context.INT=0x00
	elseif vm_context.INT==0x36 then --FILE LOAD
		local filename_end   = vm:pop(vm_context)
		local filename_start = vm:pop(vm_context)
		local handle         = io.open(
			string.char((unpack or table.unpack)(
				vm_context.stack,
				filename_start+1,
				filename_end
			)),
			"rb"
		)
		
        local size = handle:seek("end")
        handle:seek("set",0)
		
		for i=1,size do
			vm:push(vm_context,handle:read(1):byte())
		end
		
		vm:push(vm_context,size)
		
		handle:close()
		
		vm_context.INT=0x00
	elseif vm_context.INT~=0 then
		print("UNHANDLED EXCEPTION")
		vm:debug(vm_context)
		
		break
	end
end