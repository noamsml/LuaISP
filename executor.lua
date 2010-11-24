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
				return environ[sexp.ident]
			elseif LispSexp.is_sexp(sexp) then
				func = LispExecutor.exec(sexp.car, environ)
				return LispExecutor.apply(func, sexp.cdr, environ)
			else
				return sexp
			end
		end
	



	LispExecutor.apply = function (expr, rest, environ)
				if type(expr) == "function" then
					return  expr(unpack(tblmassapply(rest, environ)))
				elseif LispSexp.is_metafun(expr) then
					return expr.fun(environ, rest)
				else
					error("Not a function or metafunction")
				end
			end 

	tblmassapply = function (expr, environ)
		local i = 1
		local rval = {}
		while expr do
			rval[i] = LispExecutor.exec(expr.car, environ)
			expr = expr.cdr
			i = i + 1
		end
		return rval
	end
end

return pkg_init
