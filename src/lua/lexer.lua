local lexer={}

-------------------------------------------------------------------------------

lexer.warn=function(lexer,filename,row,column,message)
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

lexer.report=function(lexer,filename,row,column,message)
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

lexer.step=function(lexer,context)
	if context.source:sub(context.index,context.index)=="\n" then
		context.row    = context.row+1
		context.column = 0
	end
	
	context.index  = context.index+1
	context.column = context.column+1
	
	return context.source:sub(context.index,context.index)
end

-------------------------------------------------------------------------------

lexer.tokenize={}

lexer.tokenize[function(char_)
	return
		not not char_:find("%s") or 
		not not char_:find("%c")
end]=function(lexer,context)
	lexer:step(context)
end

lexer.tokenize[function(char_)
	return not not char_:find("%u")
end]=function(lexer,context)
	local start_index  = context.index
	local start_row    = context.row
	local start_column = context.column
	
	while context.index<#context.source do
		local next_char=lexer:step(context)
		
		if next_char:find("%s") or next_char:find("%c") then
			break
		elseif not next_char:find("%u") then
			lexer:report(
				context.filename,
				context.row,
				context.column,
				("Invalid character in symbol: '%s'"):format(
					context.source:sub(
						start_index,
						context.index
					)
				)
			)
		end
	end
	
	context.tokens[#context.tokens+1]={
		name     = "SYMBOL",
		filename = context.filename,
		row      = start_row,
		column   = start_column,
		value    = context.source:sub(
			start_index,
			context.index-1
		)
	}
end

lexer.tokenize[function(char_)
	return
		not not char_:find("%d") or 
		char_=="-" or 
		char_=="."
end]=function(lexer,context)
	local start_index  = context.index
	local start_row    = context.row
	local start_column = context.column
	local decimal      = false
	local hex          = false
	
	while context.index<#context.source do
		local next_char=lexer:step(context)
		
		if (
			next_char:find("%s") or 
			next_char:find("%c")  or 
			next_char==","
		) then
			break
		elseif next_char=="." then
			if decimal then
				lexer:report(
					context.filename,
					context.row,
					context.column,
					("Malformed number: '%s'"):format(
						context.source:sub(
							start_index,
							context.index
						)
					)
				)
			end
			
			decimal=true
		elseif (
			next_char=="x" and 
			context.index==start_index+1
		) then
			hex=true
		elseif not (
			next_char:find("%d") or
			next_char:find("%x")
		) then
			lexer:report(
				context.filename,
				context.row,
				context.column,
				("Invalid character in number: '%s'"):format(
					context.source:sub(
						start_index,
						context.index
					)
				)
			)
		end
		
		if hex and decimal then
			lexer:report(
				context.filename,
				context.row,
				context.column,
				("Malformed number: '%s'"):format(
					context.source:sub(
						start_index,
						context.index-1
					)
				)
			)
		end
	end
	
	context.tokens[#context.tokens+1]={
		name     = "NUMBER",
		filename = context.filename,
		row      = start_row,
		column   = start_column,
		value    = tonumber(
			context.source:sub(
				start_index,
				context.index-1
			)
		)
	}
end

lexer.tokenize[function(char_)
	return char_=='"'
end]=function(lexer,context)
	local start_index  = context.index
	local start_row    = context.row
	local start_column = context.column
	
	while context.index<#context.source do
		local next_char=lexer:step(context)
		
		if next_char=='"' then
			break
		elseif (
			next_char=="\n" or 
			context.index==#context.source
		) then
			lexer:report(
				context.filename,
				context.row,
				context.column,
				"Unterminated string"
			)
		end
	end
	
	if context.index>start_index then
		context.tokens[#context.tokens+1]={
			name     = "STRING",
			filename = context.filename,
			row      = start_row,
			column   = start_column,
			value    = context.source:sub(
				start_index+1,
				context.index-1
			)
		}
	else
		context.tokens[#context.tokens+1]={
			name     = "STRING",
			filename = context.filename,
			row      = start_row,
			column   = start_column,
			value    = ""
		}
	end
	
	lexer:step(context)
end

lexer.tokenize[function(char_)
	return char_==","
end]=function(lexer,context)
	context.tokens[#context.tokens+1]={
		name     = "SPLICE",
		filename = context.filename,
		row      = context.row,
		column   = context.column,
		value    = ","
	}
	
	lexer:step(context)
end

-------------------------------------------------------------------------------

lexer.lex=function(lexer,source,filename,tokens)
	local context={
		source   = source.." ",
		filename = filename,
		index    = 1,
		row      = 1,
		column   = 1,
		tokens   = tokens or {}
	}
	
	while context.index<#context.source do
		local match_=false
		
		local char_=context.source:sub(
			context.index,
			context.index
		)
		
		for match_char,tokenize in pairs(lexer.tokenize) do
			if match_char(char_) then
				match_=true
				tokenize(lexer,context)
				break
			end
		end
		
		if not match_ then
			lexer:report(
				context.filename,
				context.row,
				context.column,
				("Unexpected character: '%s'"):format(
					context.source:sub(
						context.index,
						context.index
					)
				)
			)
		end
	end
	
	return context.tokens
end

-------------------------------------------------------------------------------

return lexer