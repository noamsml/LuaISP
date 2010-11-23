require "import"

local function pkg_init(LispSexp)
	LispSexp.Sexp = {}
	LispSexp.MetaFunction = {}
	LispSexp.Ident = {}
	
	function LispSexp.make_sexp(car, cdr)
		local rval = {car = car, cdr = cdr}
		setmetatable(rval, LispSexp.Sexp)
		return rval
	end
	
	function LispSexp.make_ident(str)
		local rval = {ident = str}
		setmetatable(rval, LispSexp.Ident)
		return rval
	end
	
	function LispSexp.METAFUN(fun)
		local rval = {fun = fun}
		setmetatable(rval, LispSexp.MetaFunction)
		return rval
	end
	
	
	function LispSexp.is_sexp(val)
		return (getmetatable(val) == LispSexp.Sexp)
	end
	
	function LispSexp.is_ident(val)
		return (getmetatable(val) == LispSexp.Ident)
	end
	
	function LispSexp.is_metafun(val)
		return (getmetatable(val) == LispSexp.MetaFunction)
	end
end

return pkg_init
