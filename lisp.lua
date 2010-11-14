local LispParser = require "parser"
local LispExecutor = require "executor"

--global functions


input = LispParser.filestream(io.input())


while true do
	inp = LispParser.parse(input)
	print(LispExecutor.exec(inp))
end	


