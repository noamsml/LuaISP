require "import"
local tblmassapply
local LispParser = import "parser" --yay redundancy
local LispFunctions = import "functions"

function pkg_init(LispExecutor)
	LispExecutor.MetaFunction = {}


	LispExecutor.RunFile = {
		
	}

	LispExecutor.exec = function (sexp, environ)
			if sexp == nil then
				return nil
			elseif sexp.dtype == LispParser.type_ident then
				return LispFunctions[sexp.ident]
			elseif sexp.dtype == LispParser.type_data then
				return sexp.data
			elseif sexp.dtype == LispParser.type_sexp then
				func = LispExecutor.exec(sexp.car)
				return LispExecutor.apply(func, sexp.cdr, LispFunctions)
			end
		end


	LispExecutor.apply = function (expr, rest, environ)
				if type(expr) == "function" then
					return  expr(unpack(tblmassapply(rest)))
				elseif type(expr) == "table" and getmetatable(expr) == LispExecutor.MetaFunction then
					return 1
				else
					error("Not a function or metafunction")
				end
				
			end 

	tblmassapply = function (expr)
		local i = 1
		local rval = {}
		while expr do
			rval[i] = LispExecutor.exec(expr.car)
			expr = expr.cdr
			i = i + 1
		end
		return rval
	end
end

return pkg_init
