require "import"
LispParser = import "parser"
LispSexp = import "Sexp"
LispExecutor = import "executor"
LispFunctions = import "functions"

local function pkg_init(Lisp)
	Lisp.code = function(str)
		local newenv = {}
		setmetatable(newenv, {__index = LispFunctions})
		local parser = LispParser.parse(LispParser.stringstream(str))
		local parsed,cont = parser()
		local result
		
		while cont do
			result = LispExecutor.exec(parsed, newenv)
			parsed,cont = parser()
		end
		
		return result

	end

	Lisp.RunFile = function (file, interactive)
		local newenv = {}
		setmetatable(newenv, {__index = LispFunctions})
		local parser = LispParser.parse(LispParser.filestream(file))
		if (interactive) then 
			interactive:write(">>> ")
			interactive:flush()
		end
		local parsed, cont = parser()
		local result = nil
		while cont do
			
			result = LispExecutor.exec(parsed, newenv)
			if (interactive) then 
				print(LispFunctions.display(result))
				interactive:write(">>> ")
				interactive:flush()
			end
			parsed,cont = parser()
		end
		return result
	end
	
	
	Lisp.require = function (fname)
		return Lisp.RunFile(io.open(fname, "r"))
	end
end

return pkg_init
