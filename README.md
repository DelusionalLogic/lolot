lolot
=====

"Lot Of Lines Of Terrible" is a different lua class system that focuses on avoiding repeated verbose statements.

Usage
-----

lolot is uses a simple syntax although it does have a few quirks due to lua limitations.

The first step is as always to ```require``` the file: ```require "lolot"```

You then need to declare a class. This is done with a call to the function ```class()``` with 2 required parameters. The first being the name of the class, and the second being the function encapsulating the namespace. The function will then return the definition, which you need to catch in a variable. This look like:

```
local Person = class("Person", function() end)
```

To add functionality to your newly created class you need to place it in the namespace function. This is where the elegance of lolot begins.

To add a new local variable you simply define it within the scope, the same goes for functions. A function will dynamically have a self variable set when called, so there is no need to have it as an argument. lolot will also pull the self table into the global environment when when a function is called. This removes most of the redundant self table references, as they are now only required when something local or global hides the variable. All of this is demonstrated in the example below:

```
local Person = class("Person", function()
	age = 0

	function __init__(birthYear)
		age = 2014 - birthYear
	end

	function setAge(age)
		self.age = age
	end

	function __tostring__()
		return tostring(age)
	end

	function printAge()
		print(age)
	end
end)
```

If you have worked with any other lua OOP system you might notice that theres no references to the class table. Instead of ```Person:setAge(age)``` it simply becomes ```setAge(age)```, and since it's within the person namespace function lolot knows to treat it as a method. The same goes for variables. The instance variable ```age``` is simply declared in the namespace without explicit identification that it is part of the ```Person``` class. If the variable would otherwise be hidden by either a global or local variable we simply fall back to referencing the ```self``` table, as can be seen in the ```setAge(age)``` method. This example class can be used like this:

```
Oscar = Person(2010)
Oscar:printAge() --> prints 4
Oscar:setAge(20)
Oscar:printAge() --> prints 20
```

Lua also has support for metamethods. Lolot proxies that functionality out to classes. The naming of all the meta events is nearly identical. lolot suffixes them with two underscores to make them symmetric, only 3 events have been left out ```__index```, ```__newindex```, and ```__mode```. lolot also adds a new metamethod ```__init__``` which is the class constructor. This is called whenever your class is instantiated.
