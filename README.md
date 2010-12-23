# LuaISP #
A lisp dialect written in lua that is a lua dialect that behaves like lisp.

## status ##
Still in heavy development. Spec not yet finalized.

## ultimate goal ##
Nothing really. I'm just messing around. What I want to make is something where you can import a module and then write something like

Lisp.require("fname.luaisp")

and then the functions defined there will integrate seamslessly with lua functions (and luaisp sexps will be easy to manipulate from within lua etc etc)

## todo ##
### Roadmap to making an IRC bot in LuaISP ###
1. Capacity to use $ to apply and create functions in object style -- DONE
2. Error capturing -- DONE 
3. Handle multiple return values to/from lua functions gracefully -- DONE
4. BUG: Lambda doesn't play nice with negative numbers -- FIXED, TURNS OUT ALL OF LUAISP DIDN'T

### And other stuff ###
4. ???
5. PROFIT

## what is this project good for? ##
Nothing whatsoever :/
