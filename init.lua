---@diagnostic disable lowercase-global

local container = ...

require, package = dofile("HydraKernel/require.lua")()

---@class HydraKernel
kernel = setmetatable({}, {
   __type = "HydraKernel"
})
kernel.filesystem = require("HydraKernel.modules.filesystem")
kernel.screen = require("HydraKernel.modules.screen")
kernel.peripherals = require("HydraKernel.modules.peripherals")
kernel.events = require("HydraKernel.modules.events")
kernel.processes = require("HydraKernel.modules.processes")


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

kernel.processes.run("/start.lua")

while true do
   kernel.events.fireEvent(kernel.events.awaitEvent())
end

