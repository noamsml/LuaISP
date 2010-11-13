--require "pprint"

type_sexp, type_ident, type_num, type_str = 1,2,3,4

function stringstream(str)
	local index = 1
	return function()
		if index > str:len() then
			return nil
		end
		
		index = index + 1
		
		return str:sub(index-1, index-1)
	end
end

function readonefrominput()
	return io.read(1)
end

function tokenstream(getchar)
	local a = nil
	local singles = {["("] = true, [")"] = true, ["'"] = true}
	local delims = {[" "] = true, ["\t"] = true, ["\n"] = true}
	
	a = getchar()
	return function ()
		local retval
		
		while a and delims[a] do
			a = getchar()
		end
		
		if not a then return nil end -- trailing whitespace what what
		
		if singles[a] then 
			local b = a
			a = getchar()
			return b
		end
		
		--string
		if a == "\"" then
			retval = a
			a = getchar()
			while a ~= "\"" do
				if not a then error "Mismatched quotes" end
				retval = retval .. a
				if a == "\\" then
					a = getchar()
					if not a then error "Mismatched quotes" end
					retval = retval .. a
				end
				a = getchar()
			end
			retval = retval .. a
			a = getchar()
			return retval
		end
		
		
		--identifier/number
		retval = a
		
		a = getchar()
		while a and not (delims[a] or singles[a]) do
			retval = retval .. a
			a = getchar()
		end
		
		--"nullify" a
		if not singles[a] then
			a = getchar()
		end
		
		return retval
	
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
	elseif str:sub(1,1) == "\"" then
		bychar = stringstream(str)
		bychar()
		local retval = ""
		local nextchar = bychar()
		while nextchar ~= "\"" do
			if nextchar == "\\" then
				retval = retval .. bychar()
			else
				retval = retval .. nextchar
			end
			
			nextchar = bychar()
		end
		return {dtype=type_str, str=retval}
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
		elseif sexp.dtype == type_str then
			return sexp.str
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

a = tokenstream(readonefrominput)
while true do
	exec(parse_sexp(a, true))
end	


