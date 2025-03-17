---@diagnostic disable lowercase-global

local container = ...

require, package = dofile("/boot/kernel/require.lua")()

---@class HydraKernel
kernel = setmetatable({}, {
   __type = "HydraKernel"
})
kernel.filesystem = require("kernel.modules.filesystem")
kernel.screen = require("kernel.modules.screen")
kernel.peripherals = require("kernel.modules.peripherals")
kernel.events = require("kernel.modules.events")
kernel.processes = require("kernel.modules.processes")


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

kernel.processes.run("/boot/HydraKernel/login.lua")

while true do
   kernel.events.fireEvent(kernel.events.awaitEvent())
end

