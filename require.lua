local filesystem = require((...):gsub("%.?require$", "") .. ".modules.filesystem")
local req
req = function(dir)
   dir = dir or "/"

   local package = {
      config = "/\n;\n?",
      loaded = {},
      path = dir .. "/?.lua;/lib/?.lua;/?.lua" .. dir .. "/?/init.lua;/lib/?/init.lua;/?.lua;/?/init.lua",
      preload = {},
      searchers = {},
      searchpath = {}
   }

   package.searchpath = function(module, path, seperator, replace)
      module = module:gsub(seperator, replace)
      for pattern in path:gmatch("[^;]+") do
         local script = pattern:gsub("%?", module)

         if filesystem.fs.exists(script) then
            return script
         end
      end

      return nil, "Module " .. module .. " not found."
   end

   package.searchers[1] = function(module)
      return package.preload[module]
   end

   package.searchers[2] = function(module)
      return package.searchpath(module, package.path, "%.", "/")
   end

   local function require(module)
      if package.loaded[module] then
         local ret = package.loaded[module] == true and {n=0} or package.loaded[module]
         return ret.n == 0 and true or table.unpack(ret, 1, ret.n)
      end

      local script
      local errs = ""
      for _, v in ipairs(package.searchers) do
         local err
         script, err = v(module)

         while type(script) == "function" do
            script, err = script(err)
         end

         if not script then
            errs = errs .. "\n" .. (err or "")
         else
            break
         end
      end

      if not script then
         error(errs)
      else
         local func, err = loadfile(script, nil, setmetatable({require = req(dir .. module:gsub("%.", "/"):gsub("[^/]+", ""))}, {__index=_G}))

         if not func then
            error(err)
         end

         package.loaded[module] = table.pack(func(dir:gsub("/", "."), module)) or true
         local ret = package.loaded[module] == true and {n=0} or package.loaded[module]
         return ret.n == 0 and true or table.unpack(ret, 1, ret.n)
      end
   end

   return require, package
end

return req

