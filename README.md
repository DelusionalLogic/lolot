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

To add a new local variable you simply define it within the scope, the same goes with functions. A function will dynamically have a self variable set when called, so there is no need to have it as an argument. You could therefore make a person class that encapsulates a persons age as simply as:

```
local Person = class("Person", function()
	age = 0

	function __init__(birthYear)
		self.age = 2014 - birthYear
	end

	function setAge(age)
		self.age = age
	end

	function __tostring__()
		return tostring(self.age)
	end

	function printAge()
		print(self.age)
	end
end)
```

Things you might notice if you have worked with other lua class systems is that we don't type the name of the variable before the function definitions, and local instance variables just work. When you declare instance variables you should remember that none of the lua functions are available, so if you need to assign variables values from function calls you should assign them in the constructor.

Another thing you might want to do is take advantage of lua metatable events. lolot redirects all these to methods of the same name, except if follows the python way of symmetry with the underscores. One exception is ```__init__()``` which is the constructor. You should notice that all variables declared globally in the namespace are automatically constructed on instantiation. An example use of the given class would look like:

```
Oscar = Person(2010)
Oscar:printAge() --> prints 4
```
