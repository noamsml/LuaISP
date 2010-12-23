require "import"
local LispParser = import "parser"
local LispExecutor = import "executor"
local LispSexp = import "Sexp"

local function pkg_init(LispFunctions)
	
	-- temporarily moved from LispCode for convenience
	
	
	LispFunctions["run-file"] = function (file)
		local newenv = {}
		setmetatable(newenv, {__index = LispFunctions})
		local parser = LispParser.parse(LispParser.filestream(file))
		local parsed, cont = parser()
		local result = nil
		while cont do
			
			result = LispExecutor.exec(parsed, newenv)
			parsed,cont = parser()
		end
		return result
	end
	
	
	LispFunctions["require-lisp"] = function (fname)
		return LispFunctions["run-file"](io.open(fname, "r"))
	end
	
	
	
	
	
	
	LispFunctions["+"] = function(...)
				local rval = 0
				for i,v in ipairs(arg) do
					rval = rval + v
				end
				return rval
		end
		
	LispFunctions["-"] = function(...)
				local rval = arg[1] * 2
				for i,v in ipairs(arg) do
					rval = rval - v
				end
				return rval
		end
		
	LispFunctions["*"] = function(...)
			local rval = 1
			for i,v in ipairs(arg) do
				rval = rval * v
			end
			return rval
	end


	LispFunctions.car = function(expr)
				if not LispSexp.is_sexp(expr) then return nil end
				
				return expr.car
		end

	LispFunctions.cdr = function(expr)
				if not LispSexp.is_sexp(expr) then return nil end
				return expr.cdr
		end


	LispFunctions.totable = function (expr)
		local i = 1
		local rval = {}
		while expr do
			rval[i] = expr.car
			expr = expr.cdr
			i = i + 1
		end
		return rval
	end
	
	LispFunctions.eq = function(a,b)
						return a == b
					end
	
	function LispFunctions.eqv(a,b)
			if type(a) ~= type(b) or getmetatable(a) ~= getmetatable(b) then
				return false
			elseif LispSexp.is_ident(a) then
					return a.ident == b.ident
			elseif LispSexp.is_sexp(a) then	
				if not LispFunctions.eqv(a.car, b.car) then
					return false
				else
					return LispFunctions.eqv(a.cdr, b.cdr)
				end
			end
			
			return a == b
	end
	
	
	LispFunctions.quot = LispSexp.METAFUN(  function(environ, rest)
							return rest.car
						end )
	
	LispFunctions.newenv = function (environ) 
			local newenv = {}
			setmetatable(newenv, {__index = environ})
			return newenv
	end
	
	LispFunctions.lambda = LispSexp.METAFUN( function(environ, rest)
							return function(...)
								local blah = rest.car
								local newenv = {}
								local i = 1
								local sexp = rest.cdr
								local rval = nil
								local restarg = nil
								
								setmetatable(newenv, {__index = environ})
								while LispSexp.is_sexp(blah) and blah.car do
									assert(LispSexp.is_ident(blah.car))  --"state of the art error handling" :P
									newenv[blah.car.ident] = arg[i]
									i = i + 1
									blah = blah.cdr
								end
								
								--AND
								local j = table.getn(arg)
								while j >= i do
										restarg = LispSexp.make_sexp(arg[j], restarg)
										j = j - 1
								end
								newenv["#"] = restarg
								
								while sexp do
									--DEBUG
									
									rval = LispExecutor.exec(sexp.car, newenv)
									
									sexp = sexp.cdr
								end
								return rval
							end
						end )
						
	LispFunctions.set = LispSexp.METAFUN( function(environ, rest)
								assert(LispSexp.is_ident(rest.car))
								local get,set = LispExecutor.resolve_id(rest.car.ident, environ)
								local val = LispExecutor.exec(rest.cdr.car, environ)
								set(val)
								return val
						end )
						
	
						
	LispFunctions.setl = LispSexp.METAFUN( function(environ, rest)
								assert(LispSexp.is_ident(rest.car))
								local get,set = LispExecutor.resolve_id(rest.car.ident, LispFunctions)
								local val = LispExecutor.exec(rest.cdr.car, environ)
								set(val)
								return val
						end )

	LispFunctions.setg = LispSexp.METAFUN( function(environ, rest)
								assert(LispSexp.is_ident(rest.car))
								local get,set = LispExecutor.resolve_id(rest.car.ident, _G)
								local val = LispExecutor.exec(rest.cdr.car, environ)
								set(val)
								return val
						end )
	
	--REPACK VALUES USING MAGIC
	LispFunctions.repack = LispSexp.METAFUN( function(environ, rest)
							local data = function (...)
								local x = rest.cdr
								local i = 1
								while x do
									local get,set = LispExecutor.resolve_id(x.car.ident, LispFunctions)
									set(arg[i])
									i = i + 1
									x = x.cdr
								end
								return i-1
							end
							
							return data(LispExecutor.exec(rest.car, environ))
							
		end )
	
	LispFunctions["capture-error"] = LispSexp.METAFUN ( function(environ, rest)
						local capfun = LispExecutor.exec(rest.car, environ) -- capfun is first
																	  -- because it's likely shorter
						
						
						local captured = function (...)
							if (arg[1] == true) then return unpack(arg,2)
							else return capfun(arg[2]) end
						end
						
						return captured(pcall(function ()
							local x = rest.cdr
							local z = nil
							while x do
								z = LispExecutor.exec(x.car, environ) 
								x = x.cdr
							end
							return z
						 end))
														 
	end )
	
	LispFunctions["return-multiple"] = function(...)
		return unpack(arg)
	end
						
	LispFunctions.defun = LispSexp.METAFUN( function(environ, rest)
								assert(LispSexp.is_sexp(rest.car) and LispSexp.is_ident(rest.car.car) )
								local get,set = LispExecutor.resolve_id(rest.car.car.ident, _G)
								local val = 
									LispFunctions.lambda.fun(environ, LispSexp.make_sexp(rest.car.cdr, rest.cdr))
								set(val)
								return val
						end )
						
	
						
	LispFunctions.cons = function(car, cdr)
					return LispSexp.make_sexp(car, cdr)
	end
	
	LispFunctions.list = function(...)
		local i = table.getn(arg)
		local rval = nil
		while i > 0 do
			rval = LispSexp.make_sexp(arg[i], rval)
			i = i - 1
		end
		return rval
	end
						
	LispFunctions["if"] = LispSexp.METAFUN( function(environ, rest)
								if (LispExecutor.exec(rest.car, environ)) then
									return LispExecutor.exec(rest.cdr.car, environ)
								elseif rest.cdr.cdr then
									return LispExecutor.exec(rest.cdr.cdr.car, environ)
								end
								
								return nil
						end )
						
	LispFunctions["while"] = LispSexp.METAFUN ( function(environ, rest)
								local rval
								while (LispExecutor.exec(rest.car, environ)) do
									rval = LispExecutor.exec(rest.cdr.car, environ)
								end
								
								return rval
						end )
						
	
	LispFunctions.lua = LispSexp.METAFUN ( function(environ, rest)
							local newenv = {}
							setmetatable(newenv, {--ARE YOU READY?
							__index = environ,
							__newindex = function(t,i,v)
									local newt = getmetatable(t).__index 
									while newt ~= _G and newt[i] == nil do
										newt = getmetatable(newt).__index
									end
									newt[i] = v
							end
							})
							
							code_data = loadstring(LispExecutor.exec(rest.car, environ)) --The exec is mostly "just in case"
							
							if code_data == nil then error "Bad lua code" end
							
							setfenv(code_data, newenv)
							return code_data()
					end)
	
	
	
	LispFunctions["true"] = true
	LispFunctions["false"] = false
	
	LispFunctions["not"] = function(a) return not a end
	LispFunctions["and"] = function(a,b) return a and b end
	LispFunctions["or"] = function(a,b) return a or b end
	
	-- HACK
	LispFunctions["do"] = function(...) return arg[table.getn(arg)] end
	
	LispFunctions.is_list = LispSexp.is_sexp
	
	LispFunctions.is_ident = LispSexp.is_ident
	
	LispFunctions.is_metafun = LispSexp.is_metafun
	
	LispFunctions.is_string = function (m) return (type(m) == "string") end
	
	LispFunctions.is_num = function (m) return (type(m) == "number") end
	
	LispFunctions.display = function (m)
		local retval = ""
		if LispSexp.is_sexp(m) then
			retval = "("
			while m.cdr do
				retval = retval .. LispFunctions.display(m.car) .. " "
				m = m.cdr
			end
			retval = retval .. LispFunctions.display(m.car) .. ")"
			return retval
		elseif LispSexp.is_ident(m) then
			return m.ident
		elseif type(m) == "number" then
			return tostring(m) --yes, I'm being lazy here
		elseif type(m) == "string" then
			return "\"" .. m:gsub("[\\\"]", "\\%1") .. "\""
		elseif m == nil then
			return "()"
		else
			return "<" .. tostring(m) .. ">"
		end
	end
	
	-- Yes, it's a metafunction; blame the use of environ
	LispFunctions.exec = LispSexp.METAFUN( function (environ, rest) 
		--Yo dawg, I heard you like evaluation, so I put evaluation in your evaluation so you can
		--evaluate while you evaluate
		return LispExecutor.exec(LispExecutor.exec(rest.car, environ), environ)
	end )
	
	LispFunctions.apply = LispSexp.METAFUN(function (environ,rest) 
		return LispExecutor.apply(LispExecutor.exec(rest.car,environ), 
			LispExecutor.exec(rest.cdr.car, environ), environ)
	end)
	
	LispFunctions.metafun = LispSexp.METAFUN;
	
	LispFunctions[":"] = function(a,b)
		if LispFunctions.is_ident(b) then
			b = b.ident
		end
		
		return a[b]
	end
	
	LispFunctions[":="] = function(a,b,c)
		if LispFunctions.is_ident(b) then
			b = b.ident
		end
		
		a[b] = c
		return c
	end
	
	LispFunctions["/"] = function(a,b)
		return a/b
	end
	
	LispFunctions["read"] = function(message)
		if (message) then io.write(message) end
		
		local instream = LispParser.parse(LispParser.filestream(io.input()))
		return instream()
	end
	
	LispFunctions["newtable"] = function()
		return {}
	end
	
	LispFunctions.parse_id = function(id,env)
		return LispExecutor.parse_id (id.ident, env)
	end
	
	
	LispFunctions.metafun = LispSexp.METAFUN
	
	LispFunctions.metacall = function (f, environ, rest)
		return f.fun(environ, rest)
	end
	
	LispFunctions.idstring = function (ident) return ident.ident end
	
	setmetatable(LispFunctions, {__index = getfenv(1)});
end

return pkg_init
