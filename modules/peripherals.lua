if peripheral.getNames and debug then
   local i, key, value = 1, debug.getupvalue(peripheral.isPresent, 2)
   while key ~= "native" and key ~= nil do
      key, value = debug.getupvalue(peripheral.isPresent, i)
      i=i+1
   end
   _G.peripheral = value or peripheral
end
local native = peripheral
peripheral = nil ---@diagnostic disable-line lowercase-global

---@class HydraKernel.Peripherals
local lib = {}

local sides = {
   "bottom", "top", "back", "front", "left", "right"
}

---Returns a list of peripherals
---@return string[]
function lib.getPeripherals()
   local names = {}

   for _, side in ipairs(sides) do
      if native.isPresent(side) then
         names[#names + 1] = side
         if native.hasType(side, "peripheral_hub") then
            local remote = native.call(side, "getNamesRemote")

            for _, name in ipairs(remote) do
               names[#names + 1] = name
            end
         end
      end
   end

   return names
end

---Returns whether a peripheral is present
---@param name string
---@return boolean
function lib.isPresent(name)
   if native.isPresent(name) then
      return true
   end

   for _, side in ipairs(sides) do
      if native.isPresent(side) then
         if native.hasType(side, "peripheral_hub") and native.call(side, "isPresentRemote", name) then
            return true
         end
      end
   end

   return false
end

---Returns the type of a peripheral
---@param name string
---@return string?
function lib.type(name)
   if native.isPresent(name) then
      return native.getType(name)
   end

   for _, side in ipairs(sides) do
      if native.isPresent(side) then
         if native.hasType(side, "peripheral_hub") and native.call(side, "isPresentRemote", name) then
            return native.call(side, "getTypeRemote", name)
         end
      end
   end
end

---Checks whether a peripheral has a specific type
---@param name string
---@param type string
---@return boolean
function lib.hasType(name, type)
   if native.isPresent(name) then
      return native.hasType(name, type)
   end

   for _, side in ipairs(sides) do
      if native.isPresent(side) then
         if native.hasType(side, "peripheral_hub") and native.call(side, "isPresentRemote", name) then
            return native.call(side, "hasTypeRemote", name, type)
         end
      end
   end

   return false
end

---Returns the methods a peripheral has
---@param name string
---@return string[]?
function lib.getMethods(name)
   if native.isPresent(name) then
      return native.getMethods(name)
   end

   for _, side in ipairs(sides) do
      if native.isPresent(side) then
         if native.hasType(side, "peripheral_hub") and native.call(side, "isPresentRemote", name) then
            return native.call(side, "getMethodsRemote", name)
         end
      end
   end
end

---Calls a method on a peripheral
---@param name string
---@param method string
---@param ... unknown
---@return unknown?
function lib.call(name, method, ...)
   if native.isPresent(name) then
      return native.call(name, method, ...)
   end

   for _, side in ipairs(sides) do
      if native.isPresent(side) then
         if native.hasType(side, "peripheral_hub") and native.call(side, "isPresentRemote", name) then
            return native.call(side, "callRemote", name, method, ...)
         end
      end
   end
end

---Returns the type of a peripheral
---@param name string
---@return string?
function lib.getType(name)
   if native.isPresent(name) then
      return native.getType(name)
   end

   for _, side in ipairs(sides) do
      if native.isPresent(side) then
         if native.hasType(side, "peripheral_hub") and native.call(side, "isPresentRemote", name) then
            return native.call(side, "getTypeRemote", name)
         end
      end
   end
end

---Wraps a peripheral
---@param name string
---@return {name: string, type: string, [string]: function}
function lib.wrap(name)
   local wrapped = {name = name, type = lib.getType(name)}

   for _, method in ipairs(lib.getMethods(name) --[[@as table]]) do
      wrapped[method] = function(...)
         lib.call(name, method, ...)
      end
   end

   return wrapped
end

---Gets and wraps every peripheral of a specific type based on an optional filter
---@param type any
---@param filter (fun(name: string, peripheral: {name: string, type: string, [string]: function}): boolean)?
---@return {name: string, type: string, [string]: function}[]
function lib.find(type, filter)
   filter = filter or function() return true end

   local peripherals = {}
   for _, name in ipairs(lib.getPeripherals()) do
      if lib.hasType(name, type) then
         local wrapped = lib.wrap(name) --[[@as {name: string, type: string, [string]: function}]]

         if filter(name, wrapped) then
            table.insert(peripherals, wrapped)
         end
      end
   end
   return peripherals
end

return lib

