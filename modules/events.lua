---@class HydraKernel.Events
local lib = {}
local registered = {}

---@alias HydraKernel.EventFunc fun(event: string, ...: unknown)

---Registers an event function.
---@param func HydraKernel.EventFunc
---@param name string?
function lib.register(func, name)
   if not func then error("No function provided.") end

   registered[#registered + 1] = {
      name = name,
      func = func
   }
end

---@param callback string|function
function lib.deregister(callback)
   for k, v in pairs(registered) do
      if v.name == callback or v.func == callback then
         registered[k] = nil
      end
   end
end

function lib.awaitEvent()
   return coroutine.yield()
end

return lib

