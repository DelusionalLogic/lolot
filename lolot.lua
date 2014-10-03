local function captureGlobals(f)
	local newG = {}
	local oldG = _ENV
	f(newG, oldG)
	return newG
end

local function splitClass(class)
	local functions = {}
	local variables = {}

	for k,v in pairs(class) do
		if type(v) == "function" then
			functions[k] = v
		else
			variables[k] = v
		end
	end

	return functions, variables
end

local function deepcopy(table, dest)
	local dest = dest or {}

	for k,v in pairs(table) do
		if type(v) == "table" then
			dest[k] = deepcopy(v)
		else
			dest[k] = v
		end
	end
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------
---- This function is no fun. It sets the env up for a function call ----
-------------------------------------------------------------------------
-------------------------------------------------------------------------

local function invokeWithSelf(self, fname, f, ...)
	oldSelf = _ENV["self"]
	oldSuper = _ENV["super"]
	local oldmt = getmetatable(_ENV)
	_ENV["self"] = self
	if type(self.__super) == "table" then
		_ENV["super"] = function(...) return self.__super[fname](self, ...) end
	end
	setmetatable(_ENV, {__index = self, __newindex = self})
	local retVal = f( ... )
	setmetatable(_ENV, oldmt)
	_ENV["self"] = oldSelf
	_ENV["super"] = oldSuper
	return retVal
end

-----------------------
-----------------------
---- It's okay now ----
-----------------------
-----------------------

local function setSelfInvoker(n, f)
	return function(self, ...)
		return invokeWithSelf(self, n, f, ...)
	end
end

local function copyFunctionsTap(src, dst, tap)
	for k,v in pairs(src) do
		if type(v) == "function" then
			dst[k] = tap(k, v)
		end
	end
end

local function safeCallAlternative(funcName, alternative)
	return function(self, ...)
		if self[funcName] then
			return invokeWithSelf(self, funcName, self[funcName], self, ...)
		elseif alternative then
			return alternative(self, ...)
		end
	end
end

local instmt = {
	__tostring = safeCallAlternative("__tostring__", function(self, ...)
		return ("Instance<%s>"):format(self.__name)
	end),

	__add = safeCallAlternative("__add__"),
	__call = safeCallAlternative("__call__"),
	__concat = safeCallAlternative("__concat__"),
	__div = safeCallAlternative("__div__"),
	__eq = safeCallAlternative("__eq__"),
	__le = safeCallAlternative("__le__"),
	__len = safeCallAlternative("__len__"),
	__lt = safeCallAlternative("__lt__"),
	__mod = safeCallAlternative("__mod__"),
	__mul = safeCallAlternative("__mul__"),
	__pow = safeCallAlternative("__pow__"),
	__sub = safeCallAlternative("__sub__"),
	__unm = safeCallAlternative("__unm__"),
}

local function createMetaTbl(class, index)
	local instMetaTblCpy = {
		__index = index
	}
	deepcopy(instmt, instMetaTblCpy)
	return instMetaTblCpy
end

local function allocate(class, origClass)
	local baseClass = origClass or class

	local inst = {
		__name = class.name,
		type = class,
	}

	local instmt = {}
	if type(class.super) == "table" then
		parent = allocate(class.super, baseClass)
		instmt = createMetaTbl(baseClass, parent)
		inst.__super = parent
	else
		instmt = createMetaTbl(baseClass)
	end

	deepcopy(class.variables, inst)
	deepcopy(class.functions, inst)

	setmetatable(inst, instmt)

	return inst
end

local function initialize(object, ...)
	if object.__init__ then
		object:__init__( ... )
	end
end

local function instantiate(class, ...)
	local inst = allocate(class)
	initialize(inst, ...)
	return inst
end

local mt = {
	__call = function(self, ...)
		return self:new(...)
	end,

	__tostring = function(self)
		return ("Class<%s>"):format(self.name)
	end,
}

local function newClass(name, super, f)
	local classData = captureGlobals(f)
	local functions, variables = splitClass(classData)

	local classTable = {
		name = name,
		functions = {},
		variables = variables,
		super = super,
	}
	copyFunctionsTap(functions, classTable.functions, setSelfInvoker)

	classTable.new = instantiate

	return setmetatable(classTable, mt)
end

local classmt={
	__index = function(k) return function(super, f)
		if type(super) == "function" then
			return newClass(k, nil, super)
		else
			return newClass(k, super, f)
		end
	end end
}
local class = {}
setmetatable(class, classmt)
return class
