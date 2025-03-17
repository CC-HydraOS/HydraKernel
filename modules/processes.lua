---@class HydraKernel.processes
local lib = {}

local req = require("boot.kernel.require")
local function mkEnv(dir)
   return setmetatable({
      require = req(dir)
   }, {
      __index = _G
   })
end

local processes = {}

local pattern = {
   ["("] = "%(",
   [")"] = "%)",
   ["."] = "%.",
   ["%"] = "%%",
   ["+"] = "%+",
   ["-"] = "%-",
   ["*"] = "%*",
   ["?"] = "%?",
   ["["] = "%[",
   ["]"] = "%]",
   ["^"] = "%^",
   ["$"] = "%$"
}

---Runs a file as a new process
---@param path string
function lib.run(path, args)
   path = path or "/"

   local parent = path:gsub("[^/]+$", "")
   local name = path:gsub("/" .. parent:gsub(".", pattern) .. "$", "")
   local func = assert(loadfile(path, nil, mkEnv(parent)))

   processes[#processes + 1] = {coroutine = coroutine.create(func), name = name}

   return coroutine.resume(processes[#processes].coroutine, args)
end

function lib.fireEvent(...)
   local dead = {}
   for k, v in pairs(processes) do
      if coroutine.status(v.coroutine) == "dead" then
         dead[k] = true
      end

      coroutine.resume(v.coroutine, ...)
   end

   for k in pairs(dead) do
      processes[k] = nil
   end
end

function lib.killProcess(name)
   local delete = {}
   for k, v in pairs(processes) do
      delete[k] = (v.name == name)
   end

   for k in pairs(delete) do
      processes[k] = nil
   end
end

return lib

