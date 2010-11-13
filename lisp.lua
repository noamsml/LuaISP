--require "pprint"

type_sexp, type_ident, type_num, type_str = 1,2,3,4

function tokenstream(str)
	local index = 1
	local singles = {["("] = true, [")"] = true, ["'"] = true}
	local delims = {[" "] = true, ["\t"] = true, ["\n"] = true}
	
	return function ()
		if index > str:len() then return nil end
		local a
		repeat
			a = str:sub(index,index)
			index = index + 1
		until (not delims[a]) or (index > str:len())
		
		if delims[a] then return nil end -- trailing whitespace what what
		
		if singles[a] then return a end
		
		while not (delims[str:sub(index,index)] or singles[str:sub(index,index)] or (index > str:len())) do
			a = a .. str:sub(index,index)
			index = index + 1
		end
		
		return a
	
	end
end



function parse_sexp (tstr_iter, expected_cparen)
	local tok1 = tstr_iter()
	
	if tok1 == nil then
		if expected_cparen then error("Close paren expected") else return nil end 
	elseif tok1 == ")" then
		if not expected_cparen then error("No close paren expected") else return nil end
	elseif tok1 == "'" then
		return { dtype = type_sexp, car = {dtype = type_ident, ident = "quot"}, 
				cdr = parse_sexp(tstr_iter) }
	elseif tok1 == "(" then
		local rval = {dtype = type_sexp, car=nil, cdr=nil}
		local parsed_sexp
		local curptr = rval
		
		rval.car = parse_sexp(tstr_iter, true)
		
		if not rval.car then return rval end
		
		while true do
			parsed_sexp = parse_sexp(tstr_iter, true)
			if not parsed_sexp then
				return rval
			else
				curptr.cdr = {dtype = type_sexp, car=nil, cdr=nil}
				curptr = curptr.cdr
				curptr.car = parsed_sexp
			end
		end
	else 
		return parse_identnum(tok1)
	end
end

function parse_identnum (str)
	if str:find("^%d+$") then
		return {dtype=type_num, num=tonumber(str)}
	else
		return {dtype=type_ident, ident=str}
	end
end


--global functions

_G["+"] = function(...)
			local rval = 0
			for i,v in ipairs(arg) do
				rval = rval + v
			end
			return rval
	end
	
_G["-"] = function(...)
			local rval = arg[1] * 2
			for i,v in ipairs(arg) do
				rval = rval - v
			end
			return rval
	end


car = function(expr)
			if not expr then return nil end
			if not type(expr) == "table" then return nil end
			if not expr.dtype == type_sexp then return nil end
			
			return expr.car
	end

cdr = function(expr)
			if not expr then return nil end
			if not type(expr) == "table" then return nil end
			if not expr.dtype == type_sexp then return nil end
			
			return expr.car
	end

exec = function (sexp)
		if sexp == nil then
			return nil
		elseif sexp.dtype == type_ident then
			return _G[sexp.ident]
		elseif sexp.dtype == type_num then
			return sexp.num
		elseif sexp.dtype == type_sexp then
			func = exec(sexp.car)
			
			
			return apply(func, sexp.cdr)
		end
	end

apply = function (expr, rest)
			if not type(expr) == "function" then
				error("Not a function")
			end
			
			--HACK
			return expr(unpack(tblmassapply(rest)))
		end 

totable = function (expr)
	local i = 1
	local rval = {}
	while expr do
		rval[i] = expr.car
		expr = expr.cdr
		i = i + 1
	end
	return rval
end

tblmassapply = function (expr)
	local i = 1
	local rval = {}
	while expr do
		rval[i] = exec(expr.car)
		expr = expr.cdr
		i = i + 1
	end
	return rval
end

print(exec(parse_sexp(tokenstream("(print 2 7)"), false)))
