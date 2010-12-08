require "import"
local Lisp = import "lispcode"

--global functions


Lisp.code [[  (setg quit (newtable))
	(while (not (eq (set lastval (exec (read "input> "))) quit)) (print (display lastval)))
]]
