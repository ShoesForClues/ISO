local parser={}

-------------------------------------------------------------------------------

parser.warn=function(parser,filename,row,column,message)
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

parser.report=function(parser,filename,row,column,message)
	print((
		string.char(27).."[91m[SYNTAX ERROR]"..
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

parser.grammar={}

parser.grammar["SYMBOL"]=function(parser,context,token)
	context.operations[#context.operations+1]={
		filename   = token.filename,
		row        = token.row,
		column     = token.column,
		opcode     = token.value,
		parameters = {}
	}
end

parser.grammar["NUMBER"]=function(parser,context,token)
	if #context.operations==0 then
		parser:report(
			token.filename,
			token.row,
			token.column,
			"Symbol expected"
		)
	end
	
	local operation  = context.operations[#context.operations]
	local parameters = operation.parameters
	local parameter  = parameters[#parameters]
	
	if not parameter then
		parameter={}
		parameters[#parameters+1]=parameter
	end
	
	parameter[#parameter+1]=token.value
end

parser.grammar["STRING"]=function(parser,context,token)
	if #context.operations==0 then
		parser:report(
			token.filename,
			token.row,
			token.column,
			"Symbol expected"
		)
	end
	if #token.value==0 then
		parser:warn(
			token.filename,
			token.row,
			token.column,
			"Empty string"
		)
	end
	
	local operation  = context.operations[#context.operations]
	local parameters = operation.parameters
	local parameter  = parameters[#parameters]
	
	if not parameter then
		parameter={}
		parameters[#parameters+1]=parameter
	end
	
	for i=1,#token.value do
		parameter[#parameter+1]=token.value:sub(i,i):byte()
	end
end

parser.grammar["SPLICE"]=function(parser,context,token)
	if #context.operations==0 then
		parser:report(
			token.filename,
			token.row,
			token.column,
			"Symbol expected"
		)
	end
	
	local operation  = context.operations[#context.operations]
	local parameters = operation.parameters
	
	if #parameters==0 then
		parser:report(
			token.filename,
			token.row,
			token.column,
			"Missing parameter"
		)
	end
	
	parameters[#parameters+1]={}
end

-------------------------------------------------------------------------------

parser.parse=function(parser,tokens)
	local context={
		tokens     = tokens,
		operations = {}
	}
	
	for _,token in ipairs(context.tokens) do
		parser.grammar[token.name](
			parser,
			context,
			token
		)
	end
	
	return context.operations
end

-------------------------------------------------------------------------------

return parser