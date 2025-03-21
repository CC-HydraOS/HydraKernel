local lib = {}
---@class HydraKernel.Screen
---@field native table
---@field name string?
local screen = {}
local screenMt = {
   __index = screen,
   __type = "HydraKernel.Screen"
}

---Writes text to the screen.
---@param self HydraKernel.Screen
---@param text string
---@param wrap boolean?
function screen.write(self, text, wrap)
   if wrap then
      local x, y = self:getCursorPos()
      local width = self:getWidth()

      self.native.write(text:sub(1, width - x))

      local iter = 0
      for i = (width - x), #text, width do
         iter = iter + 1

         if (y + iter) > width then
            self:scroll(1)
            y = y - 1
         end
         self:setCursorPos(1, y + iter)

         self.native:write(text:sub(i, i + width - 1))
      end
   else
      self.native.write(text)
   end
end

---Scrolls by `y` lines
---@param self HydraKernel.Screen
---@param amount integer
function screen.scroll(self, amount)
   self.native.scroll(amount)
end

---Returns the current cursor position
---@param self HydraKernel.Screen
---@return integer
---@return integer
function screen.getCursorPos(self)
   return self.native.getCursorPos()
end

---Sets the cursor's position
---@param self HydraKernel.Screen
---@param x integer
---@param y integer
function screen.setCursorPos(self, x, y)
   self.native.setCursorPos(x, y)
end

---Returns whether or not the cursor is blinking
---@param self HydraKernel.Screen
---@return boolean
function screen.isCursorBlinking(self)
   return self.native.getCursorBlink()
end

---Sets whether the cursor is blinking
---@param self HydraKernel.Screen
---@param state boolean
function screen.setCursorBlinking(self, state)
   self.native.setCursorBlink(state)
end

---Returns the screen's size
---@param self HydraKernel.Screen
---@return integer
---@return integer
function screen.getSize(self)
   return self.native.getSize()
end

---Gets the screen's width
---@param self HydraKernel.Screen
---@return integer
function screen.getWidth(self)
   local ret = self:getSize()
   return ret
end

---Gets the screen's height
---@param self HydraKernel.Screen
---@return integer
function screen.getHeight(self)
   local _, ret = self:getSize()
   return ret
end

---Clears the screen
---@param self HydraKernel.Screen
function screen.clear(self)
   self.native.clear()
end

---Clears the line the cursor is on
---@param self HydraKernel.Screen
function screen.clearLine(self)
   self.native.clearLine()

   local _, y = self:getCursorPos()
   self:setCursorPos(1, y)
end

---Returns the current text color
---@param self HydraKernel.Screen
---@return integer
function screen.getTextColor(self)
   return self.native.getTextColor()
end

---Sets the current text color
---@param self HydraKernel.Screen
---@param color integer
function screen.setTextColor(self, color)
   self.native.setTextColor(color)
end

---Returns the current background color
---@param self HydraKernel.Screen
---@return integer
function screen.getBackgroundColor(self)
   return self.native.getBackgroundColor()
end

---Sets the current background color
---@param self HydraKernel.Screen
---@param color integer
function screen.setBackgroundColor(self, color)
   self.native.setBackgroundColor(color)
end

---Returns whether or not the screen supports all 16 colors
---@param self HydraKernel.Screen
---@return boolean
function screen.isColor(self)
   return self.native.isColor()
end

---Writes text with specific colors
---@param self HydraKernel.Screen
---@param text string
---@param textColor string
---@param backgroundColor string
---@param wrap boolean
function screen.blit(self, text, textColor, backgroundColor, wrap)
   if wrap then
      local x, y = self:getCursorPos()
      local width = self:getWidth()

      self.native.blit(text:sub(1, width - x), textColor:sub(1, width - x), backgroundColor:sub(1, width - x))

      local iter = 0
      for i = (width - x), #text, width do
         iter = iter + 1

         if (y + iter) > width then
            self:scroll(1)
            y = y - 1
         end
         self:setCursorPos(1, y + iter)

         self.native.blit(text:sub(i, i + width - 1), textColor:sub(i, i + width - 1), backgroundColor:sub(i, i + width - 1))
      end
   else
      self.native.blit(text, textColor, backgroundColor)
   end
end

---Gets the true color for a color in the palette
---@param self HydraKernel.Screen
---@param index integer
---@return integer
function screen.getPaletteColor(self, index)
   return self.native.getPaletteColor(index)
end

---Sets the true color for a color in the palette
---@param self HydraKernel.Screen
---@param index integer
---@param color integer
function screen.setPaletteColor(self, index, color)
   self.native.setPaletteColor(index, color)
end


local function wrap(monitor, name)
   return setmetatable({native = (monitor.native and monitor.native() or monitor), name = name}, screenMt)
end

local screens = {
   [0] = wrap(term)
}
---@diagnostic disable-next-line lowercase-global
_G.term = nil

local peripherals = require("boot.kernel.modules.peripherals")
local function updateScreens()
   local native = screens[0]
   screens = {[0] = native}

   for _, monitor in pairs(peripherals.find("monitor")) do
      screens[#screens + 1] = wrap(monitor, monitor.name or "Built-in Screen")
   end
end

function lib.get(id)
   updateScreens()
   return screens[id]
end

local function split(str, on)
    on = on or " "
    local result = {}
    local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for match in (str .. on):gmatch("(.-)" .. delimiter) do
        result[#result+1] = match
    end
    return result
end

function _G.print(...)
   local packed = table.pack(...) or {n=0}

   local term = lib.get(0)
   for i = 1, packed.n do
      if i == packed.n and (getmetatable(packed[i]) or {}).__type == "HydraKernel.Screen" then
         term = packed[i]
         packed[i] = nil
         break
      else
         packed[i] = tostring(packed[i])
      end
   end

   local text = table.concat(packed, " ")

   for _, str in ipairs(split(text, "\n")) do
      term:write(str, true)
      local _, y = term:getCursorPos()

      if y >= term:getHeight() then
         y = y - 1
         term:scroll(1)
      end

      term:setCursorPos(1, y + 1)
   end
end

---Returns a table of every screen available.
---@return HydraKernel.Screen[]
function lib.getAll()
   updateScreens()
   return screens
end

require("boot.kernel.modules.filesystem").makeSpecialFileFolder("/dev/screens", function(request, path, mode)
   if request == "list_files" then
      updateScreens()
   elseif request == "open_file" then
      if mode == "r" then
         error("Screens do not support reading.")
      elseif mode == "w" then
         return lib.get(tonumber(path:match("[0-9]+$")))
      end
   elseif request == "exists" then
      return lib.get(tonumber(path:match("[0-9]+$"))) and "file"
   end
end)

return lib

