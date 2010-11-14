require "import"
local LispParser = import "parser"
local LispExecutor = import "executor"

--global functions


input = LispParser.filestream(io.input())


while true do
	inp = LispParser.parse(input)
	print(LispExecutor.exec(inp))
end	


