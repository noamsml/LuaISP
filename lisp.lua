require "import"
local Lisp = import "lispcode"

if arg[1] then
	Lisp.require(arg[1])
else Lisp.code [[  
	(print "Welcome to LuaISP! Please write \"quit\" to exit the interperter")
	(setg quit (newtable))
	(while (not (eq 
		(set %% (exec (read "input> ")) ) 
		
		quit)) 
		
		(print (display %%))
	)
]]
end
