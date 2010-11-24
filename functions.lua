require "import"
local LispParser = import "parser"
local LispExecutor = import "executor"
local LispSexp = import "Sexp"

local function pkg_init(LispFunctions)
	
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
	
	LispFunctions.lambda = LispSexp.METAFUN( function(environ, rest)
							return function(...)
								local blah = rest.car
								local newenv = {}
								local i = 1
								local sexp = rest.cdr
								local rval = nil
								setmetatable(newenv, {__index = environ})
								while LispSexp.is_sexp(blah) and blah.car do
									assert(LispSexp.is_ident(blah.car))  --"state of the art error handling" :P
									newenv[blah.car.ident] = arg[i]
									i = i + 1
									blah = blah.cdr
								end
								
								while sexp do
									rval = LispExecutor.exec(sexp.car, newenv)
									sexp = sexp.cdr
								end
								return rval
							end
						end )
						
	LispFunctions.set = LispSexp.METAFUN( function(environ, rest)
								assert(LispSexp.is_ident(rest.car))
								environ[rest.car.ident] = LispExecutor.exec(rest.cdr.car, environ)
								return environ[rest.car.ident]
						end )
	LispFunctions.setg = LispSexp.METAFUN( function(environ, rest)
								assert(LispSexp.is_ident(rest.car))
								_G[rest.car.ident] = LispExecutor.exec(rest.cdr.car, environ)
								return _G[rest.car.ident]
						end )
						
	LispFunctions.defun = LispSexp.METAFUN( function(environ, rest)
								assert(LispSexp.is_sexp(rest.car) and LispSexp.is_ident(rest.car.car) )
								_G[rest.car.car.ident] = 
									LispFunctions.lambda.fun(environ, LispSexp.make_sexp(rest.car.cdr, rest.cdr))
								return _G[rest.car.car.ident]
						end )
						
	LispFunctions.cons = function(car, cdr)
					return LispSexp.make_sexp(car, cdr)
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
						
	
	
	
	LispFunctions["true"] = true
	LispFunctions["false"] = false
	
	LispFunctions["not"] = function(a) return not a end
	LispFunctions["and"] = function(a,b) return a and b end
	LispFunctions["or"] = function(a,b) return a or b end
	
	-- HACK
	LispFunctions["do"] = function(...) return arg[table.getn(arg)] end
	
	setmetatable(LispFunctions, {__index = getfenv(1)});
end

return pkg_init
