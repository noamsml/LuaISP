local tblmassapply
local LispExecutor = {}
local LispParser = require "parser" --yay redundancy
local LispFunctions = require "functions"



LispExecutor.exec = function (sexp)
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


LispExecutor.apply = function (expr, rest, linkenv)
			if not type(expr) == "function" then
				error("Not a function")
			end
			
			--SLOW HACK BUT MIGHT BE NEEDED LATER
			local oldenv = getfenv(expr)
			local newenv = {}
			
			setmetatable(newenv, {__index = function(t,i,v)
												if linkenv[i] ~= nil then return linkenv[i]
												else return oldenv[i] end
												end,
			 __newindex = function(t,i,v)
							oldenv[i] = v
						 end
			})
			
			
			
			setfenv(expr, newenv)
			
			--HACK
			local val = expr(unpack(tblmassapply(rest)))
			
			setfenv(expr, oldenv)
			return val
			
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


return LispExecutor
