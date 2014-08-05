local function captureGlobals(f)
	local newG = {}
	local oldG = _ENV
	_ENV = newG
	f()
	_ENV = oldG
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

local function invokeWithSelf(self, f, ...)
	local oldSelf = _ENV["self"]
	local oldmt = getmetatable(_ENV)
	_ENV["self"] = self
	setmetatable(_ENV, {__index = self, __newindex = self})
	local retVal = f(...)
	setmetatable(_ENV, oldmt)
	_ENV["self"] = oldSelf
	return retVal
end

local function setSelfInvoker(f)
	return function(self, ...)
		return invokeWithSelf(self, f, ...)
	end
end

local function copyFunctionsTap(src, dst, tap)
	for k,v in pairs(src) do
		if type(v) == "function" then
			dst[k] = tap(v)
		end
	end
end

local function safeCallAlternative(funcName, alternative)
	return function(self, ...)
		if self[funcName] then
			return invokeWithSelf(self, self[funcName], self, ...)
		else
			if alternative then
				return alternative(self, ...)
			end
		end
	end
end

local instmt = {
	__tostring = safeCallAlternative("__tostring__", function(self, ...)
		return ("Instance<%s>"):format(self.__name)
	end),

	__call = safeCallAlternative("__call__"),
	__len = safeCallAlternative("__len__"),
	__unm = safeCallAlternative("__unm__"),
	__add = safeCallAlternative("__add__"),
	__sub = safeCallAlternative("__sub__"),
	__mul = safeCallAlternative("__mul__"),
	__div = safeCallAlternative("__div__"),
	__mod = safeCallAlternative("__mod__"),
	__pow = safeCallAlternative("__pow__"),
	__concat = safeCallAlternative("__concat__"),
	__eq = safeCallAlternative("__eq__"),
	__lt = safeCallAlternative("__lt__"),
	__le = safeCallAlternative("__le__"),
}

local mt = {
	__call = function(self, ...)
		return self:new(...)
	end,

	__tostring = function(self)
		return ("Class<%s>"):format(self.name)
	end,
}

local function instantiate(class, ...)
	local inst = {
		__name = class.name
	}

	deepcopy(class.variables, inst)
	copyFunctionsTap(class.functions, inst, setSelfInvoker)

	if inst.__init__ then
		inst:__init__(...)
	end
	return setmetatable(inst, instmt)
end

function class(name, f)
	local classData = captureGlobals(f)
	local functions, variables = splitClass(classData)

	local classTable = {
		name = name,
		functions = functions,
		variables = variables,
	}

	classTable.new = instantiate

	return setmetatable(classTable, mt)
end
