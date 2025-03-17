---@diagnostic disable undefined-field

if not fs.exists("/dev") then fs.makeDir("/dev") end

---@class HydraKernel.FileSystem
local lib = setmetatable({}, {
   __type = "HydraKernel.FileSystem"
})

if false then
   ---@class HydraKernel.FileSystem.File
   local file = {
      ---Writes to a file.
      ---@param self HydraKernel.FileSystem.File
      ---@param data string|integer[]
      write = function(self, data) end, ---@diagnostic disable-line unused

      ---Reads from a file.
      ---@param self HydraKernel.FileSystem.File
      ---@return integer[]
      read = function(self) end, ---@diagnostic disable-line unused

      ---Closes a currently open file.
      ---@param self HydraKernel.FileSystem.File
      close = function(self) end, ---@diagnostic disable-line unused

      ---The path of the file.
      path = "",
      ---Whether a file is opened.
      opened = false,
      ---Which byte is next.
      byte = 0
   }
end

local specialfiles = {
   ["/dev/random"] = {
      read = function(count)
         local ret = ""
         for _ = 1, count do
            ret = ret .. math.random(0, 255)
         end
         return math.random(0, 255)
      end,
      write = function() end
   },
   ["/dev/urandom"] = {
      read = function(count)
         local ret = ""

         for _ = 1, count do
            ret = ret .. math.random(0, 255)
         end

         return math.random(0, 255)
      end,
      write = function() end
   },
   ["/dev/null"] = {
      read = function(count) return ("\x00"):rep(count) end,
      write = function() end
   }
}

local opened = {}
local metatables = {}

do
   local indexes = {}

   indexes.readFile = {
      read = function(self, count)
         if not self.opened then error("File closed.") end

         if specialfiles[self.path] then
            return specialfiles[self.path].read(count)
         end

         local file = fs.open(self.path, "r")
         file.seek("set", self.byte)

         self.byte = self.byte + count
         local byte = string.byte(file.read(count))

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
      write = function(self, data)
         if not self.opened then error("File closed.") end

         if specialfiles[self.path] then
            return specialfiles[self.path].write(data)
         end

         local file = fs.open(self.path, "w+")
         file.seek("set", self.byte)

         self.byte = self.byte + count
         file.write(type(data) == "string" and data or string.char(table.unpack(data)))

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

local specialFolders = {}

---Creates a new folder to check for special files
---@param path string
---@param func fun(request: "list_files"|"open_file"|"exists", ...: unknown): unknown?
function lib.makeSpecialFileFolder(path, func)
   if not fs.exists(path) then fs.makeDir(path) end
   
   specialFolders[path] = func
end

---Creates a new file.
---@param path string
function lib.newFile(path)
   if specialFolders["/" .. fs.combine(fs.getDir(path))] then
      error("Parent directory is a special directory and does not support custom files.")
   end

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

   if specialFolders["/" .. fs.combine(fs.getDir(path))] then
      return specialFolders["/" .. fs.combine(fs.getDir(path))]("open_file", path, mode)
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
   if specialFolders["/" .. fs.combine(fs.getDir(path))] then
      error("Parent directory is a special directory and does not support custom files.")
   end

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
   if specialFolders["/" .. fs.combine(fs.getDir(path))] then
      return specialFolders["/" .. fs.combine(fs.getDir(path))]("list_files")
   end

   if not fs.exists(path) then
      return false, "Directory " .. path .. " does not exist."
   elseif not fs.isDir(path) then
      return false, path .. " is not a directory."
   end

   return fs.list(path)
end

---Returns whether a path exists
---@param path string
---@return "file"|"directory"|false
function lib.pathExists(path)
   if specialFolders["/" .. fs.combine(fs.getDir(path))] then
      return specialFolders["/" .. fs.combine(fs.getDir(path))]("exists", path)
   end

   if specialfiles["/" .. path:gsub("^/", ""):gsub("/$", "")] then
      return "file"
   end

   if not fs.exists(path) then return false end
   return fs.isDir(path) and "directory" or "file"
end

return lib, fs

