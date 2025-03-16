---@diagnostic disable undefined-field

---@class HydraKernel.FileSystem
---@field fs {[string]: function}
local lib = setmetatable({}, {
   __type = "HydraKernel.FileSystem"
})

if false then
   ---@class HydraKernel.FileSystem.File
   local file = {
      ---Writes a single byte to a file.
      ---@param self HydraKernel.FileSystem.File
      ---@param byte number
      write = function(self, byte) end, ---@diagnostic disable-line unused

      ---Reads a single byte from a file.
      ---@param self HydraKernel.FileSystem.File
      ---@return number?
      read = function(self) end, ---@diagnostic disable-line unused

      ---Closes a currently open file.
      ---@param self HydraKernel.FileSystem.File
      close = function(self) end, ---@diagnostic disable-line unused

      ---The path of the file.
      path = "",
      ---The current byte
      byte = 0,
      ---Whether a file is opened.
      opened = false
   }
end

local specialfiles = {
   ["/dev/random"] = {
      read = function()
         return math.random(0, 255)
      end,
      write = function() end
   },
   ["/dev/urandom"] = {
      read = function()
         return math.random(0, 255)
      end,
      write = function() end
   },
   ["/dev/null"] = {
      read = function()
         return 0
      end,
      write = function() end
   }
}

local opened = {}
local metatables = {}

do
   local indexes = {}

   indexes.readFile = {
      read = function(self)
         if not self.opened then error("File closed.") end

         if specialfiles[self.path] then
            return specialfiles[self.path].read()
         end

         local file = fs.open(self.path, "r")
         file.seek("set", byte)

         local byte = string.byte(file.read(1))

         file.close()

         return byte
      end,
      write = function()
         if not self.opened then error("File closed.") end

         error("File is opened for reading.")
      end,
      close = function(self)
         if not self.opened then error("File closed.") end

         opened[self.path] = false
         self.opened = false
      end
   }

   indexes.writeFile = {
      write = function(self, byte)
         if not self.opened then error("File closed.") end

         if specialfiles[self.path] then
            return specialfiles[self.path].write(byte)
         end

         local file = fs.open(self.path, "w+")
         file.seek("set", byte)

         file.write(string.char(byte))

         file.close()

         return byte
      end,
      read = function()
         if not self.opened then error("File closed.") end

         error("File is opened for writing.")
      end,
      close = function(self)
         if not self.opened then error("File closed.") end

         opened[self.path] = false
         self.opened = false
      end
   }

   for k, v in pairs(indexes) do
      metatables[k] = {
         __index = v,
         __type = "HydraKernel.FileSystem.File"
      }
   end
end

---@diagnostic disable-next-line undefined-global
lib.fs = fs

---Creates a new file.
---@param path string
function lib.newFile(path)
   if fs.exists(fs.getDir(path)) then
      local file, err = fs.open(path, "w")

      if not file then
         return false, err
      end

      file.write("")
      file.close()
   else
      error("Parent directory does not exist.")
   end
end

---Opens a file for reading or writing
---@param path string
---@param mode "r"|"w"
---@return HydraKernel.FileSystem.File?
function lib.openFile(path, mode)
   if not fs.exists(path) then
      return false, "File " .. path .. " does not exist."
   end

   if mode == "r" and not (not opened[path] and not specialfiles[path]) then
      opened[path] = true
      return setmetatable({byte = 0, path = path, opened = true}, metatables.readFile)
   elseif mode == "w" and not (not opened[path] and not specialfiles[path]) then
      opened[path] = true
      
      lib.newFile(path)

      return setmetatable({byte = 0, path = path, opened = true}, metatables.writeFile)
   elseif mode == "r" or mode == "w" then
      print("File already open.")
   else
      error("Invalid file mode " .. mode .. ".")
   end
end

---Creates a new directory.
---@param path string
function lib.newDirectory(path)
   if fs.exists(fs.getDir(path)) then
      fs.makeDir(path)
   else
      error("Parent directory does not exist.")
   end
end

---Lists a directory's contents.
---@param path any
---@return boolean|string[]
---@return string?
function lib.listDirectory(path)
   if not fs.exists(path) then
      return false, "Directory " .. path .. " does not exist."
   elseif not fs.isDir(path) then
      return false, path .. " is not a directory."
   end

   return fs.list(path)
end

return lib

