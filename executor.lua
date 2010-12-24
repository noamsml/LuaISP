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
				
				
				local success, func, rval
				success, func = pcall(LispExecutor.exec, sexp.car, environ)
				if not success then
					error("In functional expression " .. LispFunctions.display(sexp.car) .. ":: \n" .. tostring(func))
				end
				
				
				success, rval =  pcall(LispExecutor.apply, func, sexp.cdr, environ, hist)
				if not success then
					error("In expression " .. LispFunctions.display(sexp) .. ":: \n" .. tostring(rval))
				end
				
				
				return rval
			else
				return sexp
			end
		end
		
	
	LispExecutor.parse_id  = function(ident, environ)
		local dot = ident:find("[.]")
		local olddot = 1
		local subenv = environ
		local finalstep

		while dot do
			subenv = subenv[ident:sub(olddot,dot-1)]
			olddot = dot+1
			dot = ident:find("[.]", olddot)
		end
		finalstep = ident:sub(olddot)

		return subenv,finalstep
	end
	
	
	LispExecutor.resolve_id = function (ident, environ)
		local get,set
		local subenv,finalstep = LispExecutor.parse_id(ident,environ)
		
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
	


	-- Fair warning: This has nothing to do with real lisp's "apply" function :P
	-- I can't really change the way things work because it would break
	-- meta-functions
	LispExecutor.apply = function (expr, rest, environ)
				if type(expr) == "function" then
					return  expr(massexec(rest, environ))
				elseif LispSexp.is_metafun(expr) then
					return expr.fun(environ, rest)
				else
					error("Not a function or metafunction")
				end
			end 

	massexec = function (expr, environ, hist)
		if expr then
			return LispExecutor.exec(expr.car,environ, hist), massexec(expr.cdr, environ)
		end
	end
	
	
end

return pkg_init
