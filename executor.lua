require "import"
local tblmassapply
local LispParser = import "parser" --yay redundancy
local LispFunctions = import "functions"
local LispSexp = import "Sexp"


local function pkg_init(LispExecutor)

	LispExecutor.exec = function (sexp, environ)
			if sexp == nil then
				return nil
			elseif LispSexp.is_ident(sexp) then
				local get, set = LispExecutor.resolve_id(sexp.ident, environ)				
				--print (subenv, finalstep)
				return get()
			elseif LispSexp.is_sexp(sexp) then
				func = LispExecutor.exec(sexp.car, environ)
				return LispExecutor.apply(func, sexp.cdr, environ)
			else
				return sexp
			end
		end
		
	LispExecutor.resolve_id = function (ident, environ)
		local dot = ident:find("[.]")
		local olddot = 1
		local subenv = environ
		local finalstep
		local get,set
		
		while dot do
			subenv = subenv[ident:sub(olddot,dot-1)]
			olddot = dot+1
			dot = ident:find("[.]", olddot)
		end
		
		finalstep = ident:sub(olddot)
		local dolla = finalstep:find("[$]")
		if not dolla then
			get = function ()
				return subenv[finalstep]
			end
			
			set = function (val)
				subenv[finalstep] = val
			end
			
		else
			subenv = subenv[finalstep:sub(1,dolla-1)]
			finalstep = finalstep:sub(dolla+1)
			get = function ()
				-- BUG: This doesn't play nice with nil
				return function(...)
					return subenv[finalstep](subenv, unpack(arg))
				end
			end
			
			set = function(val)
				error("Currently not supported :(")
			end
				
		end
		
		return get,set
	end
	



	LispExecutor.apply = function (expr, rest, environ)
				if type(expr) == "function" then
					return  expr(massexec(rest, environ))
				elseif LispSexp.is_metafun(expr) then
					return expr.fun(environ, rest)
				else
					error("Not a function or metafunction")
				end
			end 

	massexec = function (expr, environ)
		if expr then
			return LispExecutor.exec(expr.car,environ), massexec(expr.cdr, environ)
		end
	end
	
	
end

return pkg_init
