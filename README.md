# LuaISP #
A lisp dialect written in lua that is a lua dialect that behaves like lisp.

## status ##
Still in heavy development. Spec not yet finalized.

## ultimate goal ##
Nothing really. I'm just messing around. What I want to make is something where you can import a module and then write something like

Lisp.require("fname.luaisp")

and then the functions defined there will integrate seamslessly with lua functions (and luaisp sexps will be easy to manipulate from within lua etc etc)

## todo ##
1. Change the way literals work so I don't have to do awkward back-and-forth conversion (and figure out nil values)
2. Add more functions and metafunctions. Add setg (global set) and setl (lisp-function-level set). Add defun (define a global function)
3. Use metatables to create methods to manipulate sexps easily from within lua
4. ???
5. PROFIT

## what is this project good for? ##
Nothing whatsoever :/
