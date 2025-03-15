---@class HydraKernel.processes
local lib = {}

local req = require((...):gsub("%.processes$", ""):gsub("modules$", "") .. "require")
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

   processes[#processes + 1] = func

   return func(args)
end

return lib

