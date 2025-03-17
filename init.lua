---@diagnostic disable lowercase-global

local container = ...

require, package = dofile("/boot/kernel/require.lua")()
package.path = package.path .. ";/boot/?.lua"

---@class HydraKernel
kernel = setmetatable({}, {
   __type = "HydraKernel"
})
kernel.filesystem = require("boot.kernel.modules.filesystem")
kernel.screen = require("boot.kernel.modules.screen")
kernel.peripherals = require("boot.kernel.modules.peripherals")
kernel.events = require("boot.kernel.modules.events")
kernel.processes = require("boot.kernel.modules.processes")

for _, v in pairs(fs.list("/boot/kernel/modules")) do
   local name = v:gsub("%.lua$", "")
   kernel[name] = require(fs.combine("/boot/kernel/modules", name):gsub("/", "."))
end

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

kernel.processes.run("/boot/kernel/login.lua")

while true do
   kernel.events.fireEvent(kernel.events.awaitEvent())
end

