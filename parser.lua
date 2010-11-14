require "import"

function pkg_init(LispParser)
	LispParser.type_sexp, LispParser.type_ident, LispParser.type_data = 1,2,3

	--for brevity's sake
	local type_sexp, type_ident, type_data = 1,2,3




	function LispParser.stringstream(str)
		local index = 1
		return function()
			if index > str:len() then
				return nil
			end
			
			index = index + 1
			
			return str:sub(index-1, index-1)
		end
	end

	function LispParser.filestream(file)
		return function () return file:read(1) end
	end



	function LispParser.parse (stream)
		local tokenstream, parse_identnum, parse_sexp
		tokenstream = function (getchar)
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


		parse_sexp = function (tstr_iter, expected_cparen)
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

		parse_identnum = function (str)
			if str:find("^%d+$") then
				return {dtype=type_data, data=tonumber(str)}
			elseif str:sub(1,1) == "\"" then
				bychar = LispParser.stringstream(str)
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
				return {dtype=type_data, data=retval}
			else
				return {dtype=type_ident, ident=str}
			end
		end
		
		
		return parse_sexp(tokenstream(stream))
	end
end

return pkg_init
