lolot
=====

"Lot Of Lines Of Terrible" is a different lua class system that focuses on avoiding repeated verbose statements.

Usage
-----

lolot uses a simple syntax although it does have a few quirks due to lua limitations.

The first step is as always to ```require``` the file: ```require "lolot"```

You then need to declare a class. This is done with a call to the function ```class()``` with 3 required parameters. The first being the name of the class, and the second being the parent class to enherit from (or nil if inheritance is unwanted). The third is the function encapsulating the namespace. The function will then return the definition, which you need to catch in a variable. This look like:

```
local Person = class("Person", function() end)
```

To add functionality to your newly created class you need to place it in the namespace function. This is where the elegance of lolot begins.

To add a new local variable you simply define it within the scope, the same goes for functions. A function will dynamically have a self variable set when called, so there is no need to have it as an argument. lolot will also pull the self table into the global environment when a function is called thus eliminating most of the redundant self table references, as they are now only required when something local or global hides the variable. All of this is demonstrated in the example below:

```
local Person = class.Person(function(env, prevEnv) _ENV=env
	name = "UNKNOWN" --Notice the inline variable definition, this is part of the class

	function __init__(name) --This is a special metamethod added by lolot that is called on initialization. At this point all variables defined in the namepace function can be considered initialized with the correct value.
		self.name = name
	end

	function setName(name)
		self.name = name --Since name is hidden by the local variable we fall back to using the self table
	end

	function hello()
		print(self)
	end

	function __tostring__() --lolot suffixes two underscores to metamethods in lua. Otherwise they are exactly the same.
		return "Hello i'm " .. name
	end
_ENV=prevEnv end)

local Butler = class.Butler(Person, function(env, prevEnv) _ENV=env
	--We inherit the name variable from the superclass

	function __init__(name) --If we didn't define this method it would just fall back to the superclass constructor. In this implementation it's currently superfluous.
		super(name) --No need to replicate code when we can just call the superclass constructor. Notice the passthrough of the arguments
	end

	--setName and hello are handled by the superclass

	function __tostring__()
		return super() .. ", I will be your butler today" --Append something to the data returned by the superclass. Easy!
	end
_ENV=prevEnv end)
```

If you have worked with any other lua OOP system you might notice that theres no references to the class table. Instead of ```Person:setName(name)``` it simply becomes ```setName(name)```, and since it's within the person namespace function lolot knows to treat it as a method. The same goes for variables. The instance variable ```name``` is simply declared in the namespace without explicit identification that it is part of the ```Person``` class. If the variable would otherwise be hidden by either a global or local variable we simply fall back to referencing the ```self``` table, as can be seen in the ```setName(name)``` method. This example class can be used like this:

```
local p = Person("John")
p:hello() --Prints "Hello i'm John"
local g = Butler("Sue")
g:hello() --Prints "Hello i'm Sue, I will be your butler today"
```

Lua also has support for metamethods. Lolot proxies that functionality out to classes. The naming of all the meta events is nearly identical. lolot suffixes them with two underscores to make them symmetric, only 3 events have been left out ```__index```, ```__newindex```, and ```__mode```. lolot also adds a new metamethod ```__init__``` which is the class constructor. This is called whenever your class is instantiated.

If you inherit from any a class the parent will be instantiated with the child. No constructor is called on the parent automatically. The superclass should automatically be carried out in the functions with the self table. You can access the hidden method as ```super(args)```. This can be seen in the ````__tostring__()``` Method.
