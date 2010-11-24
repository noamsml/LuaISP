require "import"
LispParser = import "parser"
LispSexp = import "Sexp"
LispExecutor = import "executor"
LispFunctions = import "functions"

local function pkg_init(Lisp)
	Lisp.code = function(str)
		local newenv = {}
		setmetatable(newenv, {__index = LispFunctions})
		local val = LispParser.stringstream(str)
		local parsed,cont = LispParser.parse(val)
		local result
		
		while cont do
			result = LispExecutor.exec(parsed, newenv)
			parsed,cont = LispParser.parse(val)
		end
		
		return result

	end

	Lisp.RunFile = function (file, interactive)
		local newenv = {}
		setmetatable(newenv, {__index = LispFunctions})
		local fstream = LispParser.filestream(file)
		if (interactive) then 
			io.output():write(">>> ")
			io.output():flush()
		end
		local parsed, cont = LispParser.parse(fstream)
		local result = nil
		while cont do
			
			result = LispExecutor.exec(parsed, newenv)
			if (interactive) then 
				print(result)
				io.output():write(">>> ")
				io.output():flush()
			end
			parsed,cont = LispParser.parse(fstream)
		end
		return result
	end

end

return pkg_init
