--Creating a global version later should be easy
require "import"
Lisp = import "lispcode"

Lisp.code [=[
		(defun (hello x) (print x))
		(defun (throwback v) (set l 22) (lua [[print v+l]]))
]=]



hello(13)
throwback(12)
