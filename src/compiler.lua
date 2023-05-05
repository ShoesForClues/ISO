local bit=bit32 or require("bit")

local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local bit_and    = bit.band
local bit_or     = bit.bor
local bit_xor    = bit.bxor
local bit_not    = bit.bnot

local compiler={}

-------------------------------------------------------------------------------

compiler.warn=function(compiler,filename,row,column,message)
	print((
		string.char(27).."[93m[WARNING]"..
		string.char(27).."[36m[%s,%d,%d]"..
		string.char(27).."[0m %s"
	):format(
		filename,
		row,
		column,
		message
	))
end

compiler.report=function(compiler,filename,row,column,message)
	print((
		string.char(27).."[91m[COMPILATION ERROR]"..
		string.char(27).."[36m[%s,%d,%d]"..
		string.char(27).."[0m %s"
	):format(
		filename,
		row,
		column,
		message
	))
	os.exit(1)
end

-------------------------------------------------------------------------------

compiler.translate={}

compiler.translate["NOP"]=function(compiler,context,operation)
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1] = 0x00
end

compiler.translate["INT"]=function(compiler,context,operation)
	if #operation.parameters==0 or #operation.parameters[1]==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	if #operation.parameters[1]>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Parameter is too long"
		)
	end
	if operation.parameters[1][1]%1~=0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Parameter must be an integer"
		)
	end
	if operation.parameters[1][1]<0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Parameter must be a positive integer"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1] = 0x10
	bytecode[#bytecode+1] = operation.parameters[1][1]
end

compiler.translate["REG"]=function(compiler,context,operation)
	if #operation.parameters==0 or #operation.parameters[1]==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	if #operation.parameters[1]>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Parameter is too long"
		)
	end
	if operation.parameters[1][1]%1~=0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Parameter must be an integer"
		)
	end
	if operation.parameters[1][1]<0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Parameter must be a positive integer"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1] = 0x11
	bytecode[#bytecode+1] = operation.parameters[1][1]
end

compiler.translate["NUM"]=function(compiler,context,operation)
	if #operation.parameters==0 or #operation.parameters[1]==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	if #operation.parameters[1]>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Parameter must be a single value"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1] = 0x20
	bytecode[#bytecode+1] = operation.parameters[1][1]
end

compiler.translate["ARR"]=function(compiler,context,operation)
	if #operation.parameters==0 or #operation.parameters[1]==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	if #operation.parameters[1]==1 then
		compiler:warn(
			operation.filename,
			operation.row,
			operation.column,
			"Use NUM for single value"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1] = 0x21
	bytecode[#bytecode+1] = #operation.parameters[1] --MAX: 255
	
	for _,value in ipairs(operation.parameters[1]) do
		bytecode[#bytecode+1]=value
	end
end

compiler.translate["INC"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x30
end

compiler.translate["DEC"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x31
end

compiler.translate["DUP"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x32
end

compiler.translate["POP"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x33
end

compiler.translate["ROT"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x34
end

compiler.translate["SET"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x40
end

compiler.translate["GET"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x41
end

compiler.translate["STA"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x42
end

compiler.translate["GTA"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x43
end

compiler.translate["JMP"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	if (
		not context.operations[context.parse_index-1] or
		context.operations[context.parse_index-1].opcode~="REC"
	) then
		compiler:warn(
			operation.filename,
			operation.row,
			operation.column,
			"Arbitrary jump"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x50
end

compiler.translate["JEQ"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	if (
		not context.operations[context.parse_index-1] or
		context.operations[context.parse_index-1].opcode~="REC"
	) then
		compiler:warn(
			operation.filename,
			operation.row,
			operation.column,
			"Arbitrary jump"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x51
end

compiler.translate["JNE"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	if (
		not context.operations[context.parse_index-1] or
		context.operations[context.parse_index-1].opcode~="REC"
	) then
		compiler:warn(
			operation.filename,
			operation.row,
			operation.column,
			"Arbitrary jump"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x52
end

compiler.translate["JLS"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	if (
		not context.operations[context.parse_index-1] or
		context.operations[context.parse_index-1].opcode~="REC"
	) then
		compiler:warn(
			operation.filename,
			operation.row,
			operation.column,
			"Arbitrary jump"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x53
end

compiler.translate["JLE"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	if (
		not context.operations[context.parse_index-1] or
		context.operations[context.parse_index-1].opcode~="REC"
	)then
		compiler:warn(
			operation.filename,
			operation.row,
			operation.column,
			"Arbitrary jump"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x54
end

compiler.translate["ADD"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x60
end

compiler.translate["SUB"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x61
end

compiler.translate["MUL"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x62
end

compiler.translate["DIV"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x63
end

compiler.translate["POW"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x64
end

compiler.translate["MOD"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x65
end

compiler.translate["NOT"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x70
end

compiler.translate["AND"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x71
end

compiler.translate["BOR"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x72
end

compiler.translate["XOR"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x73
end

compiler.translate["LSH"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x74
end

compiler.translate["RSH"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode=context.bytecode
	
	bytecode[#bytecode+1]=0x75
end

compiler.translate["REM"]=function(compiler,context,operation)
end

compiler.translate["DEF"]=function(compiler,context,operation)
	if (
		#operation.parameters~=2 or
		#operation.parameters[1]==0 or
		#operation.parameters[2]==0
	) then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected 2 parameters"
		)
	end
	
	local definitions = context.definitions
	local parameters  = operation.parameters
	
	local definition
	
	for _,definition_ in ipairs(definitions) do
		if #definition_.tag==#parameters[1] then
			local match_=true
			
			for i=1,#definition_.tag do
				if definition_.tag[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				definition=definition_
				break
			end
		end
	end
	
	if not definition then
		definitions[#definitions+1]={
			tag   = parameters[1],
			value = parameters[2]
		}
	else
		definition.value=parameters[2]
		
		compiler:warn(
			operation.filename,
			operation.row,
			operation.column,
			"Redefinition"
		)
	end
end

compiler.translate["REF"]=function(compiler,context,operation)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode    = context.bytecode
	local parameters  = operation.parameters
	local definitions = context.definitions
	local definition
	
	for _,definition_ in ipairs(definitions) do
		if #definition_.tag==#parameters[1] then
			local match_=true
			
			for i=1,#definition_.tag do
				if definition_.tag[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				definition=definition_
				break
			end
		end
	end
	
	if definition then
		if #definition.value>1 then
			bytecode[#bytecode+1] = 0x21
			bytecode[#bytecode+1] = #definition.value
			
			for _,value in ipairs(definition.value) do
				bytecode[#bytecode+1]=value
			end
		else
			bytecode[#bytecode+1] = 0x20
			bytecode[#bytecode+1] = definition.value
		end
	else
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Undefined reference"
		)
	end
end

compiler.translate["SEC"]=function(compiler,context,operation)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode   = context.bytecode
	local sections   = context.sections
	local parameters = operation.parameters
	
	local section
	
	for _,section_ in ipairs(sections) do
		if #section_.tag==#parameters[1] then
			local match_=true
			
			for i=1,#section_.tag do
				if section_.tag[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				section=section_
				break
			end
		end
	end
	
	if not section then
		sections[#sections+1]={
			tag     = parameters[1],
			address = #bytecode
		}
	else
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Section already defined"
		)
	end
end

compiler.translate["REC"]=function(compiler,context,operation)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode   = context.bytecode
	local recalls    = context.recalls
	local parameters = operation.parameters
	
	recalls[#recalls+1]={
		operation = operation,
		tag       = parameters[1],
		address   = #bytecode+2
	}
	
	bytecode[#bytecode+1] = 0x20
	bytecode[#bytecode+1] = 0x00
end

compiler.translate["TAG"]=function(compiler,context,operation)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode   = context.bytecode
	local variables  = context.variables
	local parameters = operation.parameters
	
	local address
	
	for index,variable in ipairs(variables) do
		if #variable==#parameters[1] then
			local match_=true
			
			for i=1,#variable do
				if variable[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				address=index-1
				break
			end
		end
	end
	
	if not address then
		address=#variables
		variables[#variables+1]=parameters[1]
	end
	
	bytecode[#bytecode+1] = 0x11
	bytecode[#bytecode+1] = 0x02
	bytecode[#bytecode+1] = 0x20
	bytecode[#bytecode+1] = address
	bytecode[#bytecode+1] = 0x40
end

compiler.translate["VAR"]=function(compiler,context,operation)
	if #operation.parameters==0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Expected parameter"
		)
	elseif #operation.parameters>1 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Too many parameters"
		)
	end
	
	local bytecode   = context.bytecode
	local variables  = context.variables
	local parameters = operation.parameters
	
	local address
	
	for index,variable in ipairs(variables) do
		if #variable==#parameters[1] then
			local match_=true
			
			for i=1,#variable do
				if variable[i]~=parameters[1][i] then
					match_=false
					break
				end
			end
			
			if match_ then
				address=index-1
				break
			end
		end
	end
	
	if not address then
		address=#variables
		variables[#variables+1]=parameters[1]
	end
	
	bytecode[#bytecode+1] = 0x20
	bytecode[#bytecode+1] = address
	bytecode[#bytecode+1] = 0x41
end

compiler.translate["CSR"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode = context.bytecode
	
	bytecode[#bytecode+1] = 0x20 --NUM 0x01
	bytecode[#bytecode+1] = 0x01
	bytecode[#bytecode+1] = 0x40 --SET
	bytecode[#bytecode+1] = 0x20 --NUM
	bytecode[#bytecode+1] = #bytecode+13
	bytecode[#bytecode+1] = 0x20 --NUM 0x00
	bytecode[#bytecode+1] = 0x00
	bytecode[#bytecode+1] = 0x41 --GET
	bytecode[#bytecode+1] = 0x11 --REG 0x02
	bytecode[#bytecode+1] = 0x02
	bytecode[#bytecode+1] = 0x20 --NUM 0x00
	bytecode[#bytecode+1] = 0x00
	bytecode[#bytecode+1] = 0x40 --SET
	bytecode[#bytecode+1] = 0x20 --NUM 0x01
	bytecode[#bytecode+1] = 0x01
	bytecode[#bytecode+1] = 0x41 --GET
	bytecode[#bytecode+1] = 0x50 --JMP
end

compiler.translate["RET"]=function(compiler,context,operation)
	if #operation.parameters>0 then
		compiler:report(
			operation.filename,
			operation.row,
			operation.column,
			"Unexpected parameter"
		)
	end
	
	local bytecode = context.bytecode
	
	bytecode[#bytecode+1] = 0x11 --REG 0x02
	bytecode[#bytecode+1] = 0x02
	bytecode[#bytecode+1] = 0x20 --NUM 0x01
	bytecode[#bytecode+1] = 0x00
	bytecode[#bytecode+1] = 0x41 --GET
	bytecode[#bytecode+1] = 0x61 --SUB
	bytecode[#bytecode+1] = 0x31 --DEC
	bytecode[#bytecode+1] = 0x20 --NUM 0x01
	bytecode[#bytecode+1] = 0x00
	bytecode[#bytecode+1] = 0x40 --SET
	bytecode[#bytecode+1] = 0x50 --JMP
end

-------------------------------------------------------------------------------

compiler.compile=function(compiler,operations)
	local context={
		operations  = operations,
		parse_index = 1,
		word_size   = 32,
		bytecode    = {0x20,0x00,0x30},
		definitions = {},
		sections    = {},
		recalls     = {},
		variables   = {
			{("ISO_CALL_STACK"):byte(1,10)},
			{("ISO_CALL_ADDRESS"):byte(1,10)}
		}
	}
	
	while context.parse_index<=#context.operations do
		local operation=context.operations[context.parse_index]
		
		if compiler.translate[operation.opcode] then
			compiler.translate[operation.opcode](
				compiler,
				context,
				operation
			)
		else
			compiler:report(
				operation.filename,
				operation.row,
				operation.column,
				"Invalid opcode: "..operation.opcode
			)
		end
		
		context.parse_index=context.parse_index+1
	end
	
	context.bytecode[2]=#context.variables
	
	for _,recall in ipairs(context.recalls) do
		local address
		
		for _,section in ipairs(context.sections) do
			if #section.tag==#recall.tag then
				local match_=true
				
				for i,value in ipairs(section.tag) do
					if recall.tag[i]~=value then
						match_=false
						break
					end
				end
				
				if match_ then
					address=section.address
					break
				end
			end
		end
		
		if address then
			context.bytecode[recall.address]=address
		else
			compiler:report(
				recall.operation.filename,
				recall.operation.row,
				recall.operation.column,
				"Undefined section"
			)
		end
	end
	
	return context.bytecode	
end

-------------------------------------------------------------------------------

return compiler