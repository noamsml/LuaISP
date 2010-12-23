require "import"
local LispSexp = import "Sexp"

local function pkg_init(LispParser)

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
				
				--print(":: " .. a)
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
				
				
				--or
				if a == "[" then
					local lv_in = 0
					local lv_out = 0
					retval = "["
					while a == "[" do
						lv_in =  lv_in + 1
						a = getchar()
					end
					
					
					
					while a and lv_out ~= lv_in  do
						if a == "]" then
							lv_out = lv_out + 1
						else
							while lv_out > 0 do
								retval = retval .. "]"
								lv_out = lv_out - 1
							end
							retval = retval .. a
						end
						a = getchar()
					end
				--	a = getchar()
					return retval
				end
					
				
				
				--identifier/number
				retval = a
				
				a = getchar()
				while a and not (delims[a] or singles[a]) do
					retval = retval .. a
					a = getchar()
				end
				
				
				
				return retval
			end
		end


		parse_sexp = function (tstr_iter, expected_cparen)
			local tok1 = tstr_iter()
			--print(tok1) --TODO: tokenbug
			if tok1 == nil then
				if expected_cparen then error("Close paren expected") else return nil, false end 
			elseif tok1 == ")" then
				if not expected_cparen then error("No close paren expected") else return nil, false end
			elseif tok1 == "'" then
				return LispSexp.make_sexp(LispSexp.make_ident("quot"), LispSexp.make_sexp(parse_sexp(tstr_iter), nil)), true
			elseif tok1 == "(" then
				local rval = LispSexp.make_sexp()
				local parsed_sexp
				local curptr = rval
				local cont
				rval.car, cont = parse_sexp(tstr_iter, true)
				
				if not cont then return nil, true end
				
				while true do
					parsed_sexp, cont = parse_sexp(tstr_iter, true)
					if not cont then
						return rval, true
					else
						curptr.cdr = LispSexp.make_sexp(parsed_sexp)
						curptr = curptr.cdr
					end
				end
			else 
				return parse_identnum(tok1), true
			end
		end

		parse_identnum = function (str)
			if str:find("^-?%d+[.]?%d*$") then
				return tonumber(str)
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
				return retval
			elseif str:sub(1,1) == "[" then
				if str:sub(2,2) == "\n" then
					return str:sub(3)
				else
					return str:sub(2)
				end
			elseif str == "nil" then
				return nil
			else
				return LispSexp.make_ident(str)
			end
		end
		
		
		return function () 
			local s = tokenstream(stream);  
			return parse_sexp(s);
		end
	end
end

return pkg_init
