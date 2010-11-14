require "import"
local LispParser = import "parser"
local LispExecutor = import "executor"

--global functions


LispExecutor.RunFile(io.input(), true)

