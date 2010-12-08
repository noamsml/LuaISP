--Creating a global version later should be easy
require "import"
Lisp = import "lispcode"

a = Lisp.code [=[
		(defun (hello x) (print x))
		(defun (throwback v) (set l 22) (lua [[print(v+l)]]))
		(+ 2 2)
]=]


print(a)
hello(13)
throwback(12)
