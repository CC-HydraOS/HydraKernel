---@diagnostic disable lowercase-global

local container = ...

local _require = require
local function require(modname)
   local ret = pcall(_require, modname)
   
   if ret then
      return _require(modname)
   else
      return _require(container .. "." .. modname)
   end
end

---@class HydraKernel
kernel = setmetatable({}, {
   __type = "HydraKernel"
})
kernel.filesystem = require("modules.filesystem")
kernel.screen = require("modules.screen")
kernel.peripherals = require("modules.peripherals")


for k, v in pairs(kernel) do
   if type(v) == "table" then
      kernel[k] = setmetatable({}, {
         __index = v,
         __newindex = function()
            error("HydraKernel APIs are read-only.")
         end
      })
   end
end

kernel = setmetatable({}, {
   __index = kernel,
   __newindex = function()
      error("HydraKernel APIs are read-only.")
   end
})
_G.kernel = kernel

return kernel

