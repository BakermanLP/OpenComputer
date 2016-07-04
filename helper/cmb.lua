-- 
-- Component Methods Browser
-- Platform: OpenComputers
-- 
-- Author: Sharidan
--     www.sharidan.dk
-- 
-- You may freely use and distribute this script
-- as long as the original author information
-- is left as is.
-- Please give credit where credit is due :)
-- 
local app = {
  name    = "Component Methods Browser",
  version = "1.1-i",
}

-- Display color theme
local theme = {
  titleBar = {
    "black", "lightBlue",
  },
  desktop = {
    "white", "gray",
  },
  desktopError = {
    "red", "gray",
  },
  desktopWarning = {
    "yellow", "gray",
  },
  desktopAccept = {
    "lime", "gray",
  },
  desktopGray = {
    "silver", "gray",
  },
  highlight = {
    "lightBlue", "gray",
  },
  menu = {
    normal = {
      "black", "lightBlue",
    },
    highlight = {
      "black", "orange",
    },
  },
  lua = {
    text = {
      "white", "gray",
    },
    comment = {
      "silver", "gray",
    },
    strings = {
      "yellow", "gray",
    },
    numbers = {
      "red", "gray",
    },
    operators = {
      "magenta", "gray",
    },
    delims = {
      "lime", "gray",
    },
    consts = {
      "lightblue", "gray",
    },
    optionals = {
      "silver", "gray",
    },
    functs = {
      "lightblue", "gray",
    },
  },
}

-- Component references
local components = require("component")
local fs = require("filesystem")
local event = require("event")
local uni = require("unicode")
local keyb = require("keyboard")

-- Control flags
local refreshComponents = true

local function saveTheme()
  if (not fs.exists("/etc/cmb.theme")) then
    local f = io.open("/etc/cmb.theme", "w")
    if (f) then
      local ser = require("serialization")
      f:write("-- Theme file for: "..app.name.."\n")
      f:write(ser.serialize(theme))
      f:close()
      ser = nil
    end
    f = nil
  end
end

local function loadTheme()
  if (fs.exists("/etc/cmb.theme")) then
    local f = io.open("/etc/cmb.theme", "r")
    if (f) then
      local reading = true
      local data  = nil
      while reading do
        local ln,_ = f:read()
        if (ln) then
          if (string.sub(ln, 1, 1) == "{") then
            data = ln
            reading = nil
          end
        else
          reading = nil
        end
      end
      f:close()
      if (data) then
        local ser = require("serialization")
        theme = ser.unserialize(data)
        ser = nil
      end
      data = nil
    end
    f = nil
  else
    saveTheme()
  end
end

-- Snippet: term
-- GPU wrapper that creates an alternative term object
-- for manipulating screen contents.
local function newTerm()
  local this = {}
  
  -- this._so = require("component").gpu
  this._so = components.gpu
  this._od = this._so.getDepth()
  this._ow, this._oh = this._so.getResolution()
  this.width = this._ow
  this.height = this._oh
  this.depth = this._od
  this._cx, this._cy = 1, 1
  
  function this:color(fore, back)
    local function fixclr(c, d)
      local cl = { "white", "orange", "magenta", "lightblue", "yellow", "lime", "pink", "gray", "silver", "cyan", "purple", "blue", "brown", "green", "red", "black" }
      local cn = { 0xffffff, 0xffcc33, 0xcc66cc, 0x6699ff, 0xffff33, 0x33cc33, 0xff6699, 0x333333, 0xcccccc, 0x336699, 0x9933cc, 0x333399, 0x663300, 0x336600, 0xff3333, 0x000000 }
      local nc = -1
      if (type(c) == "string") then
        local t = string.lower(string.gsub(c, " ", ""))
        t = string.gsub(t, "grey", "gray")
        t = string.gsub(t, "lightgray", "silver")
        for i = 1, #cl do
          if (t == cl[i]) then
            nc = i
            break
          end
        end
      elseif (type(c) == "number") then
        if (c >= 0 and c <= 15) then
          nc = c + 1
        end
      end
      cl = nil
      if (d == 1 and nc > -1) then
        --     Gray        Cyan      Purple        Blue       Brown       Green       Black
        if (nc == 8 or nc == 10 or nc == 11 or nc == 12 or nc == 13 or nc == 14 or nc == 16) then
          return cn[16] -- Black
        else
          return cn[1] -- White
        end
      elseif ((d == 4 or d == 8) and nc > -1) then
        return cn[nc]
      end
      return nil
    end
    local d = self._so.getDepth()
    local f, fp = fixclr(fore, d)
    local b, bp = fixclr(back, d)
    if (f) then
      self._so.setForeground(f, false)
    end
    if (b) then
      self._so.setBackground(b, false)
    end
  end
  function this:cls(fore, back)
    if (fore) then
      self:color(fore, back)
    end
    self._so.fill(1, 1, self.width, self.height, " ")
    self._cx = 1
    self._cy = 1
  end
  function this:clearln(y, fore, back)
    if (fore) then
      self:color(fore, back)
    end
    self._so.set(1, y, string.rep(" ", self.width))
    self._cx = 1
    self._cy = y
  end
  function this:drawRect(x, y, width, height, ch)
    self._so.fill(x, y, width, height, ch)
    self._cx = x
    self._cy = y
  end
  function this:write(text)
    local txt = tostring(text)
    self._so.set(self._cx, self._cy, txt)
    self._cx = self._cx + #txt
  end
  function this:writeXY(x, y, text)
    local txt = tostring(text)
    self._so.set(x, y, txt)
    self._cx = x + #txt
    self._cy = y
  end
  function this:rightXY(x, y, text)
    local txt = tostring(text)
    self._so.set((x - #txt) + 1, y, txt)
    self._cx = x + 1
    self._cy = y
  end
  function this:centerY(y, text)
    local txt = tostring(text)
    local x = math.floor((self.width - #txt) / 2) + 1
    self._so.set(x, y, txt)
    self._cx = x + #txt
    self._cy = y
  end
  function this:getXY()
    return self._cx, self._cy
  end
  function this:gotoXY(x, y)
    self._cx = tonumber(x)
    self._cy = tonumber(y)
  end
  function this:cleartb(fore, back, tbFore, tbBack, appName, appVers)
    if (fore) then
      self:cls(fore, back)
      self:clearln(1, tbFore, tbBack)
      self:writeXY(2, 1, appName)
      self:rightXY(self.width - 1, 1, "v"..appVers)
    else
      self:cls(table.unpack(theme.desktop))
      self:clearln(1, table.unpack(theme.titleBar))
      self:writeXY(2, 1, app.name)
      self:rightXY(self.width - 1, 1, "v"..app.version)
    end
  end
  function this:init(width, height, depth)
    self:cls("white", "black")
    self._so.setResolution(width, height)
    if (type(depth) == "number") then
      if (depth == 1 or depth == 4 or depth == 8) then
        self._so.setDepth(depth)
      end
    end
    self.width, self.height = self._so.getResolution()
    self.depth = self._so.getDepth()
  end
  function this:close()
    self:cls("white", "black")
    self:drawRect(1, 1, self._ow, self._oh, " ")
    self._so.setResolution(self._ow, self._oh)
    self._so.setDepth(self._od)
    self:cls("white", "black")
    if (package.loaded.term) then
      package.loaded.term.setCursor(1, 1)
    else
      require("term").setCursor(1, 1)
    end
  end
  
  return this
end
local term = newTerm()

-- Self contained list object
-- Requires: term object !!
local function newList(x, y, width, height)
  local this = {}
  
  this._x = 1
  this._y = 1
  this._w = 0
  this._h = 0
  this.width = 0
  this.height = 0
  this._nf = "white"
  this._nb = "gray"
  this._hf = "black"
  this._hb = "orange"
  this._le = {}
  this._si = 1
  this._pi = 0
  this._lo = 0
  this._ov = true
  this._ur = true
  this._urf = true
  
  function this:clear(all)
    self._le = nil
    self._le = {}
    if (all) then
      self._x = 1
      self._y = 1
      self._w = 0
      self._h = 0
      self.width = 0
      self.height = 0
      self._si = 1
      self._lo = 0
      self._ur = true
      self._urf = true
    end
    os.sleep(0)
  end
  function this:setXY(x, y)
    if (tonumber(x) and tonumber(y)) then
      if (self._x ~= x or self._y ~= y) then
        self._x = x
        self._y = y
        self._ur = true
        self._urf = true
      end
    end
  end
  function this:getXY()
    return self._x, self._y
  end
  function this:setWidth(width)
    if (tonumber(width)) then
      if (self._w ~= width) then
        self._w, self.width = width, width
        self._ur = true
        self._urf = true
      end
    end
  end
  function this:setHeight(height)
    if (tonumber(height)) then
      if (self._h ~= height) then
        self._h, self.height = height, height
        self._ur = true
        self._urf = true
      end
    end
  end
  function this:setSize(width, height)
    if (tonumber(width) and tonumber(height)) then
      if (self._w ~= width or self._h ~= height) then
        self._w, self.width = width, width
        self._h, self.height = height, height
        self._ur = true
        self._urf = true
      end
    end
  end
  function this:getSize()
    return self._w, self._h
  end
  function this:setNormal(fore, back)
    if (type(fore) == "string" and type(back) == "string") then
      self._nf, self._nb = fore, back
    end
  end
  function this:setHighlight(fore, back)
    if (type(fore) == "string" and type(back) == "string") then
      self._hf, self._hb = fore, back
    end
  end
  function this:add(entry)
    if (entry) then
      table.insert(self._le, tostring(entry))
      self._ur, self._urf = true, true
    end
  end
  function this:setList(list)
    if (type(list) == "table") then
      self._le = nil
      self._le = {}
      for l = 1, #list do
        table.insert(self._le, tostring(list[l]))
      end
      os.sleep(0)
      self._ur, self._urf = true, true
    end
  end
  function this:getList()
    return self._le
  end
  function this:getSelectedIndex()
    if (#self._le > 0) then
      return self._si
    else
      return 0
    end
  end
  function this:getSelectedEntry()
    if (#self._le > 0) then
      return self._le[self._si]
    else
      return ""
    end
  end
  function this:refresh()
    self._ur = true
    self._urf = true
    return true
  end
  function this:render()
    if (self._ur) then
      local spc = true
      for y = 1, self._h do
        local i = self._lo + y
        if (i <= #self._le) then
          if (i == self._si) then
            term:color(self._hf, self._hb)
            spc = true
          else
            if ((i == self._pi or self._urf) and spc) then
              term:color(self._nf, self._nb)
              spc = false
            end
          end
          if ((i == self._pi or self._urf) or i == self._si) then
            local le = " "..self._le[i]..string.rep(" ", self._w)
            if (#le > self._w) then
              le = string.sub(le, 1, self._w)
            end
            term:writeXY(self._x, self._y + (y - 1), le)
            le = nil
          end
        elseif (self._urf) then
          if (spc) then
            term:color(self._nf, self._nb)
          end
          term:writeXY(self._x, self._y + (y - 1), string.rep(" ", self._w))
        end
      end
      spc = nil
      self._urf = false
      self._ur = false
      os.sleep(0)
    end
  end
  function this:_mud(key)
    if (key == 200) then
      if (self._si > 1) then
        self._pi = self._si
        self._si = self._si - 1
        if (self._si < self._lo + 1) then
          self._lo = self._lo - 1
          self._urf = true
        end
        self._ur = true
      end
    elseif (key == 208) then
      if (self._si + 1 <= #self._le) then
        self._pi = self._si
        self._si = self._si + 1
        if (self._si - self._lo > self._h) then
          self._lo = self._lo + 1
          self._urf = true
        end
        self._ur = true
      end
    end
  end
  function this:checkEvent(...)
    local eventID, arg1, arg2, arg3, arg4, arg5 = table.unpack({...})
    if (eventID == "key_down" and #self._le > 0) then
      local key = tonumber(arg3)
      if (key == 199) then -- Home
        if (self._si > 1) then
          self._pi = self._si
          self._si = 1
          if (self._lo > 0) then
            self._lo = 0
            self._urf = true
          end
          self._ur = true
        end
        return nil
      elseif (key == 207) then -- End
        if (self._si < #self._le) then
          self._si = #self._le
          self._pi = 0
          self._lo = #self._le - self._h
          if (self._lo < 0) then
            self._lo = 0
          end
          self._ur = true
          self._urf = true
        end
        return nil
      elseif (key == 201) then -- PgUp
        if (self._si > self._lo + 1) then
          self._pi = self._si
          self._si = self._lo + 1
          self._ur = true
        elseif (self._si == self._lo + 1) then
          if (self._lo > 0) then
            self._lo = self._lo - self._h
            if (self._lo < 0) then
              self._lo = 0
            end
            self._si = self._lo + 1
            self._ur = true
            self._urf = true
          end
        end
        return nil
      elseif (key == 209) then -- PgDn
        if (self._si < self._lo + self._h) then
          self._pi = self._si
          self._si = self._lo + self._h
          if (self._si > #self._le) then
            self._si = #self._le
          end
          self._ur = true
        else
          if (self._si < #self._le) then
            self._lo = self._lo + self._h
            if (self._lo > #self._le - self._h) then
              self._lo = #self._le - self._h
            end
            self._si = self._lo + self._h
            if (self._si > #self._le) then
              self._si = #self._le
            end
            self._pi = 0
            self._ur = true
            self._urf = true
          end
        end
        return nil
      elseif (key == 200) then -- Up
        self:_mud(key)
        return nil
      elseif (key == 208) then -- Down
        self:_mud(key)
        return nil
      elseif (key == 28) then -- Enter
        return "listbox_select", arg1, self._si, self._le[self._si], arg4, nil
      end
    elseif (eventID == "touch" and #self._le > 0) then
      local x, y = tonumber(arg2), tonumber(arg3)
      if ((x >= self._x and x <= (self._x + self._w) - 1) and (y >= self._y and y <= (self._y + self._h) - 1)) then
        if (arg4 == 0) then
          local ni = self._lo + ((y - self._y) + 1)
          if (ni == self._si) then
            return "listbox_select", arg1, self._si, self._le[self._si], arg5, nil
          elseif (ni <= #self._le) then
            self._pi = self._si
            self._si = ni
            self._ur = true
            return nil
          end
        end
      end
    elseif (eventID == "scroll" and #self._le > 0) then
      local x, y = tonumber(arg2), tonumber(arg3)
      if ((x >= self._x and x <= (self._x + self._w) - 1) and (y >= self._y and y <= (self._y + self._h) - 1)) then
        if (arg4 == 1) then
          self:_mud(200)
          return nil
        elseif (arg4 == -1) then
          self:_mud(208)
          return nil
        end
      end
    end
    return eventID, arg1, arg2, arg3, arg4, arg5
  end
  if (type(x) == "number" and type(y) == "number") then
    this:setXY(x, y)
  end
  if (type(width) == "number" and type(height) == "number") then
    this:setSize(width, height)
  end
  
  return this
end

-- ## StatusBar caption functions
-- Splits an ampersand highlighted caption into a key/label pair
local function fixCaption(caption)
  local key, keyPos, label, work = 0, 0, "", ""
  work = string.gsub(caption, "&&", ";amp;")
  local amp = string.find(work, "&")
  if (amp) then
    key = string.sub(work, amp + 1, amp + 1)
    keyPos = tonumber(amp)
    label = string.gsub(string.gsub(work, "&", ""), ";amp;", "&")
    return true, key, keyPos, label
  end
  return false, 0, 0, string.gsub(work, ";amp;", "&")
end

-- Alternative key names for on-screen display
local function getKeyName(keyNum)
  local tbl = {
    [59] = "F1",
    [60] = "F2",
    [61] = "F3",
    [62] = "F4",
    [63] = "F5",
    [64] = "F6",
    [65] = "F7",
    [66] = "F8",
    [67] = "F9",
    [68] = "F10",
    [87] = "F11",
    [88] = "F12",
    [183] = "PrnScr",
    [70] = "ScrLck",
    [197] = "Pause",
    [41] = "Tilde",
    [12] = "Minus",
    [13] = "Equals",
    [14] = "BckSpc",
    [210] = "Ins",
    [199] = "Home",
    [201] = "PgUp",
    [69] = "NumLck",
    [181] = "Pad/",
    [55] = "Pad*",
    [74] = "Pad-",
    [15] = "Tab",
    [26] = "LBracket",
    [27] = "RBracket",
    [43] = "BSlash",
    [211] = "Del",
    [207] = "End",
    [209] = "PgDn",
    [71] = "Pad7",
    [72] = "Pad8",
    [73] = "Pad9",
    [78] = "Pad+",
    [58] = "CpsLck",
    [39] = "SColon",
    [40] = "Apos",
    [28] = "Enter",
    [75] = "Pad4",
    [76] = "Pad5",
    [77] = "Pad6",
    [42] = "LShift",
    [51] = "Comma",
    [52] = "Period",
    [53] = "Slash",
    [54] = "RShift",
    [200] = "Up",
    [79] = "Pad1",
    [80] = "Pad2",
    [81] = "Pad3",
    [29] = "LCtrl",
    [219] = "LSuper",
    [56] = "Alt",
    [57] = "Space",
    [184] = "AltGr",
    [220] = "RSuper",
    [221] = "WMenu",
    [157] = "RShift",
    [203] = "Left",
    [208] = "Down",
    [205] = "Right",
    [82] = "Pad0",
    [83] = "Pad."
  }
  local res = tbl[keyNum] or "???"
  tbl = nil
  os.sleep(0)
  return res
end

-- Snippet: statusBar
local function newStatusBar(...)
  local this = {}
  
  this._nt = ""
  this._ht = {}
  
  function this:set(...)
    local labels = {...}
    self._nt = ""
    self._ht = nil
    self._ht = {}
    local x, keyCap = 2, ""
    for l = 1, #labels do
      if (type(labels[l]) == "number") then
        keyCap = getKeyName(labels[l])
      elseif (type(labels[l]) == "string") then
        local success, key, keyPos, cap = fixCaption(labels[l])
        if (not success) then
          key = 0
          keyPos = 0
        end
        if (#keyCap > 0) then
          if (term.depth == 1) then
            self._nt = self._nt.."["..keyCap.."]: "..cap
          else
            self._nt = self._nt.."["..string.rep(" ", #keyCap).."]: "..cap
            table.insert(self._ht, { (x + 1), keyCap } )
          end
        else
          if (keyPos > 0) then
            if (term.depth == 1) then
              self._nt = self._nt.."["..string.upper(key).."]: "..cap
            else
              self._nt = self._nt..cap
              table.insert(self._ht, { (x + (keyPos - 1)), key } )
            end
          else
            self._nt = self._nt..cap
          end
        end
      end
      if (type(labels[l]) == "string" and l < #labels) then
        self._nt = self._nt..", "
      end
      x = #self._nt + 2
    end -- for l
    os.sleep(0)
  end
  function this:render()
    if (self._nt ~= "") then
      term:clearln(term.height, table.unpack(theme.desktop))
      term:writeXY(2, term.height, self._nt)
      if (#self._ht > 0) then
        term:color(table.unpack(theme.highlight))
        for h = 1, #self._ht do
          term:writeXY(self._ht[h][1], term.height, self._ht[h][2])
        end
      end
    end
  end
  this:set(...)
  
  return this
end
-- ### End of statusBar caption functions

-- Text padding; both left and right
local function pad(text, size, pre)
  local result = tostring(text)
  while #result < size do
    if (pre) then
      result = " "..result
    else
      result = result.." "
    end
  end
  return result
end

-- Splitter function
local function split(str, pat)
  local r = {}
  for s in string.gmatch(str, "[^"..pat.."]+") do
    table.insert(r, s)
  end
  return r
end
-- Wrap text inside specified width
local function wrapText(text, width)
  local txt = split(text, "\n")
  local l = {}
  for t = 1, #txt do
    local cl = ""
    local msg = ""..txt[t]..""
    for w in msg:gmatch("%S+%s*") do
      if (#cl + #w >= width) then
        table.insert(l, cl)
        cl = w
      else
        cl = cl..w
      end
    end -- for
    if (cl ~= "") then
      table.insert(l, cl)
    end
  end
  return l
end

-- Remove preceeding & trailing spaces
local function trim(text)
  local txt = tostring(text)
  if (string.sub(txt, 1, 1) == " ") then
    while (#txt > 0 and string.sub(txt, 1, 1) == " ") do
      txt = string.sub(txt, 2, #txt)
    end
  end
  if (string.sub(txt, #txt, #txt) == " ") then
    while (#txt > 0 and string.sub(txt, #txt, #txt) == " ") do
      txt = string.sub(txt, 1, #txt - 1)
    end
  end
  return txt
end

-- Some doc's return "int" instead of "number"
local function fixVars(v)
  if (string.find(v, ",")) then
    local lst = split(v, ",")
    for l = 1, #lst do
      if (string.lower(lst[l]) == "int") then
        lst[l] = "number"
      end
    end
    return table.concat(lst, ",")
  else
    if (string.lower(v) == "int") then
      return "number"
    end
  end
  return v
end

-- Splits function parameters into browsable table structures
local function splitParameters(params)
  if (params ~= "" and params ~= nil) then
    local aopt = false
    if (string.sub(params, 1, 1) == "[" and string.sub(params, #params, #params) == "]") then
      params = string.sub(params, 2, #params)
      params = string.sub(params, 1, #params - 1)
      aopt = true
    end
    local result = {}
    local args = split(params, ",")
    local an, at, aat, tn, vn, vt = "", "", "", ""
    local opt, itl, ivl, vo, sr = false, false, false, false, false
    local tl, vl = {}, {}
    for a = 1, #args do
      sr = false;vo = false
      if (string.find(args[a], "[:]")) then
        local ap = split(args[a], ":")
        an = ap[1];at = ap[2];aat = ap[3] or ""
      else
        an = args[a];at = "";aat = ""
      end
      an = string.gsub(an, " ", "");at = string.gsub(at, " ", "");aat = string.gsub(aat, " ", "")
      if (string.sub(at, #at, #at) == "[") then
        at = string.gsub(at, "[[]", "")
        if (string.find(at, "[?]")) then
          at = string.gsub(at, "[?]", "");vo = true;sr = true
        else
          sr = true
        end
        opt = true
      elseif (string.sub(an, 1, 1) == "[") then
        an = string.sub(an, 2, #an)
        sr = true
        opt = true
      elseif (string.sub(at, #at, #at) == "]" and opt) then
        opt = false;at = string.gsub(at, "[]]", "");vo = true;sr = true
      elseif (string.sub(at, 1, 1) == "{") then
        tn = an;tl = {};itl = true;at = string.gsub(at, "[{]", "")
        if (string.find(aat, "[?]")) then
          aat = string.gsub(aat, "[?]", "")
          table.insert(tl, { at, aat, true } )
        else
          table.insert(tl, { at, aat, false } )
        end
      elseif (string.find(at, "[{]")) then
        local tp = split(at, "{")
        if (tp[1] == "table") then
          tn = an;tl = {};itl = true
          if (string.find(aat, "[?]")) then
            aat = string.gsub(aat, "[?]", "")
            table.insert(tl, { tp[2], aat, true } )
          else
            table.insert(tl, { tp[2], aat, false } )
          end
        else
          vn = an;vt = tp[1];vl = {};ivl = true
          table.insert(vl, tp[2])
        end
      elseif (string.find(an, "[}]")) then
        local tp = split(an, "}")
        if (itl) then
          table.insert(tl, { tp[1], "", false } )
          if (tp[2] == "?") then
            vo = true
          end
          sr = true;an = tn;at = "table"
        elseif (ivl) then
          table.insert(vl, tp[1])
          if (tp[2] == "?") then
            vo = true
          end
          sr = true;an = vn;at = vt
        end
      elseif (itl) then
        if (string.find(at, "[?]")) then
          at = string.gsub(at, "[?]", "")
          table.insert(tl, { an, at, true } )
        else
          table.insert(tl, { an, at, false } )
        end
      elseif (ivl) then
        table.insert(vl, an)
      else
        if (string.find(at, "[?]")) then
          at = string.gsub(at, "[?]", "");vo = true;sr = true
        elseif (opt) then
          vo = true;sr = true
        else
          sr = true
        end
      end
      if (sr) then
        if (aopt) then
          vo = true
        end
        if (itl) then
          table.insert(result, { an, fixVars(at), vo, tl } )
          itl = false;tl = {};tn = ""
        elseif (ivl) then
          table.insert(result, { an, fixVars(at), vo, vl } )
          ivl = false;vl = {};vn = "";vt = ""
        else
          table.insert(result, { an, fixVars(at), vo, false } )
        end
      end
    end
    return result
  end
  return {}
end

-- Splits returned documentation into browsable table structures
local function splitDoc(methodName, methodType, methodDoc)
  if (methodDoc) then
    local code, doc, mn, mt, rt, params = "", "", methodName, "", "", ""
    local ma = {}
    local rem1, rem2 = string.find(methodDoc, "[--]")
    if (rem1 and rem2) then
      code = string.sub(methodDoc, 1, rem1 - 2)
      doc = string.sub(methodDoc, rem2 + 3, #methodDoc)
    end
    if (code ~= "") then
      local ps1, ps2 = string.find(code, "[(]")
      local pe1, pe2 = string.find(code, "[)]")
      if (ps1 and pe1) then
        mt = string.sub(code, 1, ps1 - 1)
        params = string.sub(code, ps1 + 1, pe1 - 1)
        local tmp = string.sub(code, pe1 + 1, #code)
        local pc1, pc2 = string.find(tmp, "[:]")
        if (pc1) then
          rt = fixVars(trim(string.sub(tmp, pc1 + 1, #tmp)))
        end
      end
    end
    return { mn, mt, splitParameters(params), rt, doc }
  else
    if (methodName == "address" and methodType == "string") then
      return { methodName, methodType, false, false, "The address of this component." }
    elseif (methodName == "type" and methodType == "string") then
      return { methodName, methodType, false, false, "Which type this component is." }
    elseif (methodName == "slot" and methodType == "number") then
      return { methodName, methodType, false, false, "The slot this component is installed in." }
    else
      return { methodName, methodType, false, false, "No further documentation available." }
    end
  end
  return nil
end

local function findAddress(partial, addressList)
  if (string.find(partial, "[..]") or string.find(partial, " ")) then
    if (string.find(partial, "[..]")) then
      partial = string.sub(partial, 1, string.find(partial, "[..]") - 1)
    end
    if (string.find(partial, " ")) then
      partial = string.sub(partial, 1, string.find(partial, " ") - 1)
    end
  end
  for a = 1, #addressList do
    if (string.sub(addressList[a], 1, #partial) == partial) then
      return addressList[a]
    end
  end
  return partial
end

-- Get a table of filesystem mounts:
-- address, label, mode, path
local function getMounts(address)
  local result = {}
  for proxy, path in fs.mounts() do
    local label = proxy.getLabel() or ""
    local mode = proxy.isReadOnly() and "ro" or "rw"
    if (address) then
      if (proxy.address == address) then
        table.insert(result, { proxy.address, label, mode, path } )
      end
    else
      table.insert(result, { proxy.address, label, mode, path } )
    end
  end
  return result
end

-- Get a list of all attached/visible components
-- sorted by type, sub-sorted by address
local function getComponents()
  local result = {}
  local cal, ctl = {}, {}
  for a, t in components.list() do
    local found = false
    for c = 1, #ctl do
      if (ctl[c] == t) then
        found = true
        break
      end
    end
    if (not found) then
      table.insert(ctl, t)
    end
    if (not cal[t]) then
      cal[t] = {}
    end
    table.insert(cal[t], a)
  end
  table.sort(ctl)
  for c = 1, #ctl do
    local al = {}
    for a = 1, #cal[ctl[c]] do
      table.insert(al, cal[ctl[c]][a])
    end
    table.sort(al)
    table.insert(result, { ctl[c], al } )
    al = nil
  end
  ctl = nil
  cal = nil
  return result
end

local function showHelp()
  local statusBar = newStatusBar("&Quit", 14, "Close help screen")
  term:cleartb()
  statusBar:render()
  term:color(table.unpack(theme.desktop))
  term:writeXY(2, 3, "The following keys can be used to navigate")
  term:writeXY(2, 4, "and select on most screens.")
  term:writeXY(2, 6, "[ArrowKeys]: Move selection.")
  term:writeXY(2, 7, "[Enter]    : Select highlighted entry.")
  term:writeXY(2, 8, "[BckSpc]   : Back to previous menu.")
  term:writeXY(2, 10, "[M]        : Display mount information.")
  term:writeXY(15, 12, "Only on address screen.")
  term:writeXY(2, 14, "[Q]        : Quit and return to OS.")
  term:color(table.unpack(theme.desktopError))
  term:writeXY(15, 11, "FileSystems only!")
  local running = true
  local res
  while running do
    local e, p1, p2, p3, p4, p5 = event.pull()
    if ((e == "key_down" and p3 == 14) or (e == "touch" and p4 == 1)) then
      running = nil
    elseif (e == "key_down" and p3 == 16) then
      res = "quit"
      running = nil
    end
  end
  statusBar = nil
  return res
end

-- Check all the standard events
local function stdEvents(e, p1, p2, p3, p4, p5, ct)
  if (e) then
    if (e == "key_down") then
      if (p3 == 14) then
        return "menu_back"
      else
        local c = string.lower(uni.char(p2))
        if (p3 == 50 and ct == "filesystem") then -- "m"
          return "menu_mount"
        elseif (p3 == 35) then -- "h"
          if (showHelp() == "quit") then
            return "quit"
          else
            return "ui_refresh"
          end
        elseif (p3 == 16) then -- "q"
          return "quit"
        end
      end
    elseif (e == "touch" and p4 == 1) then
      return "menu_back"
    elseif (string.sub(e, 1, 10) == "component_") then
      -- Force main menu to refresh component list
      refreshComponents = true
    end
  end
  return nil
end

local function varName(componentType)
  local ren = {
    chest = {
      "copper", "crystal", "diamond", "dirtchest9000", "gold", "iron", "obsidian", "silver", "blockvacuumchest",
      "extrautils_filing_cabinet",
    },
    machine = {
      "tile_blockbuffer_item", "tileentityfluidcrafter", "blockcrafter", "tileentityhardmedrive", "tilechest",
      "tiledrive", "tileentityfluidfiller", "tileentityvibrationchamberfluid", "alloy_smelter", "blocksagmill",
      "auto_painter", "blockvat", "blockwirelesschargertileentity", "farming_station", "blocktransceiver",
      "blockpoweredspawner", "blocksliceandsplice", "blocksoulbinder", "blocktelepadtileentity",
      "blockattractor", "blockenchanter", "blockexperienceobelisk", "blockinhibitorobelisk", "blockkillerjoe",
      "blockspawnguard", "blockweatherobelisk", 
    },
    loader    = { "adv__item__loader", "fluid_loader", "item_loader", },
    unloader  = { "adv__item__unloader", "fluid_unloader", "item_unloader", },
    dispenser = { "cart_dispenser", "train_dispenser", },
    export    = { "me_exportbus", },
    import    = { "me_importbus", },
    interface = { "me_interface", },
    tank      = { "tileentitycertustank", "blockreservoirtileentity", },
    generator = { "blockcombustiongenerator", "blockzombiegenerator", "stirling_generator", "generatorfurnace", },
    solar     = { "blocksolarpaneltileentity", "extrautils_generatorsolar", },
    power     = { "tile_blockcapacitorbank_name", },
    monitor   = { "tile_blockpowermonitor", "blockinventorypanel", },
    barrel    = { "mcp_mobius_betterbarrel", },
    trashcan  = { "tileentitytrashcanenergy", "tileentitytrashcanfluids", },
  }
  local repl = {
    "openperipheral_", "tile_thermalexpansion_device_", "tile_thermalexpansion_dynamo_",
    "tile_thermalexpansion_machine_", "tile_thermalexpansion_", "thermalexpansion_",
  }
  local repl2 = {
    "_basic_name", "_name",
  }
  local res = string.lower(componentType)
  for r = 1, #repl do
    local tmp = string.sub(res, 1, #repl[r])
    if (string.sub(res, 1, #repl[r]) == repl[r]) then
      res = string.sub(res, #tmp + 1, #res)
      for i = 1, #repl2 do
        tmp = string.sub(res, (#res - #repl2[i]) + 1, #res)
        if (tmp == repl2[i]) then
          res = string.sub(res, 1, (#res - #repl2[i]))
          break
        end
      end
      return res
    end
  end
  -- Check for renaming
  for nr, lst in pairs(ren) do
    for l = 1, #lst do
      if (res == lst[l]) then
        return nr
      end
    end
  end
  return componentType
end

local function shiftMore(show)
  term:color(table.unpack(theme.desktop))
  if (show) then
    term:rightXY(term.width + 3, term.height, "[     ]: "..uni.char(0x25bc).." view more "..uni.char(0x25bc))
    term:color(table.unpack(theme.highlight))
    term:rightXY(term.width - 17, term.height, "Shift")
  else
    term:rightXY(term.width, term.height, string.rep(" ", 23))
  end
end

local function clua(ct)
  term:color(table.unpack(theme.lua[ct]))
end

-- Menu: Method Details
local function menuDoc(componentType, doc)
  local objName = varName(componentType)
  if (#objName > 10) then
    objName = "peripheral"
  end
  local mn, mt = " "..doc[1].." ", doc[2]
  local x, y, methodx, methody, docY, docD = 1, 1, 0, 0, 0, 0
  local hit = {}
  local docLines = wrapText(doc[5], term.width - 2)
  local running = true
  local refreshUI, uiFull, ms, sh, cb = true, true, true, false, false
  local pi, opi = 1, 0
  local res
  
  local statusBar = newStatusBar(14, "Back")
  while running do
    if (refreshUI) then
      if (uiFull) then
        hit = {}
        term:cleartb()
        statusBar:render()
        
        term:color(table.unpack(theme.desktopGray))
        term:writeXY(2, 3, componentType)
        
        if (doc[3]) then
          local rts = { "nil" }
          if (doc[4]) then
            if (string.find(doc[4], " or ")) then
              rts = split(string.gsub(doc[4], " or ", "----"), "----")
            else
              rts = { doc[4] }
            end
          end
          if (rts[1] == "") then
            rts[1] = "nil"
          end
          if (rts[1] == "nil") then
            clua("consts")
          else
            clua("text")
          end
          term:writeXY(2, 5, rts[1])
          clua("operators")
          term:write(" = ")
          clua("functs")
          term:writeXY(4, 6, "function")
          clua("text")
          methodx, methody = term:getXY()
          term:write(mn)
          clua("delims")
          if (#doc[3] > 0) then
            term:write("(")
            x, y = 5, 7
            term:gotoXY(x, y)
            for p = 1, #doc[3] do
              x, y = term:getXY()
              if (x + #doc[3][p][1] + 3 > term.width) then
                x = 5
                y = y + 1
                term:gotoXY(x, y)
              end
              if (doc[3][p][3]) then
                clua("optionals")
              else
                clua("text")
              end
              local arg = " "..doc[3][p][1].." "
              table.insert(hit, { x, y, arg } )
              term:write(arg)
              if (p < #doc[3]) then
                clua("delims")
                term:write(",")
              end
            end
            y = y + 1
            clua("delims")
            term:writeXY(4, y, ")")
          else
            term:write("()")
          end
          x, y = term:getXY()
          docY = y + 2
        else
          clua("text")
          term:writeXY(2, 5, mt)
          clua("operators")
          term:write(" = ")
          clua("optionals")
          term:write(objName)
          clua("operators")
          term:write(".")
          clua("text")
          term:write(trim(mn))
          x, y = term:getXY()
          docY = y + 2
        end
        uiFull = false
      end -- uiFull
      docD = term.height - docY
      if (opi > 0) then
        if (doc[3][opi][3]) then
          clua("optionals")
        else
          clua("text")
        end
        term:writeXY(hit[opi][1], hit[opi][2], hit[opi][3])
        opi = 0
      end
      if (ms) then
        -- Method mode
        if (type(doc[3]) == "table") then
          if (#doc[3] > 0) then
            term:color(table.unpack(theme.menu.highlight))
            term:writeXY(methodx, methody, mn)
          end
        end
        term:color(table.unpack(theme.desktop))
        term:drawRect(1, docY, term.width, term.height - docY, " ")
        if (#docLines > docD) then
          if (keyb.isShiftDown()) then
            term:drawRect(1, 3, term.width, term.height - 3, " ")
            for d = 1, #docLines do
              if (d + 2 < term.height) then
                term:writeXY(2, d + 2, docLines[d])
              end
            end
            shiftMore(false)
          else
            for d = 1, docD do
              term:writeXY(2, (docY + d) - 1, docLines[d])
            end
            shiftMore(true)
          end
        else
          for d = 1, #docLines do
            term:writeXY(2, (docY + d) - 1, docLines[d])
          end
        end
      elseif (doc[3] and pi > 0) then
        -- Parameter mode
        term:color(table.unpack(theme.menu.highlight))
        term:writeXY(hit[pi][1], hit[pi][2], hit[pi][3])
        
        term:color(table.unpack(theme.desktop))
        term:drawRect(1, docY, term.width, term.height - docY, " ")
        if (doc[3][pi][3]) then
          clua("optionals")
          term:writeXY(2, docY, "Parameter "..pi.." (optional):")
        else
          clua("text")
          term:writeXY(2, docY, "Parameter "..pi..":")
        end
        term:writeXY(2, docY + 2, doc[3][pi][1])
        clua("operators")
        term:write(" : ")
        if (doc[3][pi][3]) then
          clua("optionals")
        else
          clua("text")
        end
        term:write(doc[3][pi][2])
        if (doc[3][pi][4]) then
          if (doc[3][pi][2] == "table") then
            local mtn, mtt = 0, 0
            local startY = docY + 1
            for t = 1, #doc[3][pi][4] do
              if (#doc[3][pi][4][t][1] > mtn) then
                mtn = #doc[3][pi][4][t][1]
              end
              if (#doc[3][pi][4][t][2] > mtt) then
                mtt = #doc[3][pi][4][t][2]
              end
            end
            local col1 = 50 - (mtn + mtt + 4)
            local sep = col1 + mtn + 1
            local col2 = sep + 2
            -- Render the contents...
            clua("text")
            term:writeXY(col1, startY - 1, doc[3][pi][1])
            clua("operators")
            term:write(" = ")
            clua("delims")
            term:write("{")
            for t = 1, #doc[3][pi][4] do
              if (doc[3][pi][4][t][3]) then
                clua("optionals")
                term:writeXY(col1 - 1, (startY + t) - 1, "("..doc[3][pi][4][t][1])
              else
                clua("text")
                term:writeXY(col1, (startY + t) - 1, doc[3][pi][4][t][1])
              end
              if (doc[3][pi][4][t][2] ~= "") then
                clua("operators")
                term:writeXY(sep, (startY + t) - 1, ":")
                if (doc[3][pi][4][t][3]) then
                  clua("optionals")
                  term:writeXY(col2, (startY + t) - 1, doc[3][pi][4][t][2]..")")
                else
                  clua("text")
                  term:writeXY(col2, (startY + t) - 1, doc[3][pi][4][t][2])
                end
              else
                if (doc[3][pi][4][t][3]) then
                  term:write(")")
                end
              end
            end
            clua("delims")
            term:rightXY(col1, startY + #doc[3][pi][4], "}")
          else
            term:color(table.unpack(theme.desktop))
            term:writeXY(2, docY + 4, "Values: ")
            for v = 1, #doc[3][pi][4] do
              local txt = doc[3][pi][4][v]
              local vx, vy = term:getXY()
              if (vx + #txt + 2 > term.width) then
                term:gotoXY(10, vy + 1)
              end
              term:write(txt)
              if (v < #doc[3][pi][4]) then
                term:write(", ")
              end
            end
          end
        end
      end
      
      refreshUI = false
    end
    
    local e, p1, p2, p3, p4, p5 = event.pull()
    local r = stdEvents(e, p1, p2, p3, p4, p5)
    if (r == "menu_back") then
      running = nil
    elseif (r == "ui_refresh") then
      uiFull = true
      refreshUI = true
    elseif (r == "quit") then
      res = "quit"
      running = nil
    elseif (e) then
      if (e == "key_down") then
        if (ms) then
          if (#docLines > docD) then
            if (keyb.isShiftDown() and not sh) then
              cb = cur.en
              cur.en = false
              sh = true
              refreshUI = true
            elseif (not keyb.isShiftDown() and sh) then
              sh = false
              uiFull = true
              refreshUI = true
              cur.en = cb
            end
          end
          if (doc[3] and p3 == 208) then -- arrow down: switch to parameter mode
            if (#doc[3] > 0) then
              pi = 1
              ms = false
              clua("text")
              term:writeXY(methodx, methody, mn)
              if (#docLines > docD) then
                shiftMore(false)
              end
              refreshUI = true
            end
          end
        else -- if ms
          if (doc[3] and p3 == 200) then -- arrow up: switch to method mode
            opi = pi
            pi = 1
            ms = true
            if (#docLines > docD) then
              shiftMore(true)
            end
            refreshUI = true
          elseif (doc[3] and p3 == 203) then
            -- previous parameter
            if (pi > 1) then
              opi = pi
              pi = pi - 1
              refreshUI = true
            end
          elseif (doc[3] and p3 == 205) then
            -- next parameter
            if (pi < #doc[3]) then
              opi = pi
              pi = pi + 1
              refreshUI = true
            end
          end
        end -- if ms
      elseif (e == "touch") then
        if (p4 == 0) then -- left
          local tx, ty = p2, p3
          if ((tx >= methodx and tx <= methodx + (#mn - 1)) and (ty == methody)) then
            if (not ms) then
              opi = pi
              pi = 1
              ms = true
              if (#docLines > docD) then
                shiftMore(true)
              end
              refreshUI = true
            end
          else
            -- Loop through any argument hits
            for h = 1, #hit do
              if ((tx >= hit[h][1] and tx <= hit[h][1] + (#hit[h][3] - 1)) and (ty == hit[h][2])) then
                if (ms) then
                  pi = h
                  ms = false
                  clua("text")
                  term:writeXY(methodx, methody, mn)
                  if (#docLines > docD) then
                    shiftMore(false)
                  end
                  refreshUI = true
                  break
                else
                  opi = pi
                  pi = h
                  refreshUI = true
                  break
                end
              end
            end
          end
        end
      end
    end
  end
  
  statusBar = nil
  os.sleep(0)
  return res
end

-- Menu: Component Methods List
local function menuMethods(componentType, address)
  local running = true
  local refreshUI = true
  local docList = {}
  local statusBar = newStatusBar(14, "Back", 28, "View")
  local list = newList(1, 4, term.width, term.height - 5)
  local dev, reason = components.proxy(address)
  if (dev) then
    local lst = {}
    for n, v in pairs(dev) do
      table.insert(lst, n)
    end
    table.sort(lst)
    for l = 1, #lst do
      table.insert(docList, splitDoc(lst[l], type(dev[lst[l]]), components.doc(address, lst[l])))
    end
    lst = nil
    for d = 1, #docList do
      list:add(docList[d][1])
    end
  end
  local res
  while running do
    if (refreshUI) then
      term:cleartb()
      statusBar:render()
      if (dev) then
        term:color(table.unpack(theme.desktop))
        term:centerY(2, componentType)
      else
        term:color(table.unpack(theme.desktopError))
        term:centerY(3, "Component error!")
        term:color(table.unpack(theme.desktop))
        term:writeXY(2, 5, componentType)
        term:writeXY(2, 6, address)
        if (reason) then
          term:writeXY(2, 8, reason)
        else
          term:writeXY(2, 8, "Unable to connect to component")
        end
      end
      refreshUI = false
    end
    list:render()
    local e, p1, p2, p3, p4, p5 = list:checkEvent(event.pull())
    if (e == "listbox_select") then
      if (menuDoc(componentType, docList[p2]) == "quit") then
        res = "quit"
        running = nil
      else
        refreshUI = list:refresh()
      end
    elseif (e) then
      r = stdEvents(e, p1, p2, p3, p4, p5)
      if (r == "menu_back") then
        running = nil
      elseif (r == "ui_refresh") then
        refreshUI = list:refresh()
      elseif (r == "quit") then
        res = "quit"
        running = nil
      end
    end
  end
  dev = nil
  list:clear(true)
  list = nil
  statusBar = nil
  os.sleep(0)
  return res
end

-- Menu: FileSystem Mounts
local function menuMounts(address)
  local running = true
  local refreshUI = true
  local mounts = getMounts(address)
  local statusBar = newStatusBar("&Quit", 14, "Back")
  while running do
    if (refreshUI) then
      term:cleartb()
      statusBar:render()
      term:color(table.unpack(theme.desktop))
      term:writeXY(2, 3, "Filesystem on:")
      term:writeXY(2, 4, address)
      local y = 6
      for m = 1, #mounts do
        term:color(table.unpack(theme.desktop))
        term:writeXY(2, y + 0, "Label:")
        term:writeXY(2, y + 1, "Mode :")
        term:writeXY(2, y + 2, "Path :")
        if (mounts[m][2] == "") then
          term:color(table.unpack(theme.desktopWarning))
          term:writeXY(9, y + 0, "{No label set}")
        else
          term:writeXY(9, y + 0, mounts[m][2])
        end
        if (mounts[m][3] == "ro") then
          term:color(table.unpack(theme.desktopError))
          term:writeXY(9, y + 1, "[ro] Read Only")
        else
          term:color(table.unpack(theme.desktopAccept))
          term:writeXY(9, y + 1, "[rw] Read Write")
        end
        term:color(table.unpack(theme.desktop))
        term:writeXY(9, y + 2, mounts[m][4])
        y = y + 4
      end
      refreshUI = false
    end
    local r = stdEvents(event.pull())
    if (r == "menu_back") then
      running = nil
    elseif (r == "ui_refresh") then
      refreshUI = true
    elseif (r == "quit") then
      return "quit"
    end
  end
  statusBar = nil
  os.sleep(0)
end

-- Menu: Component address selection
local function menuAddress(componentType, addressList)
  local running = true
  local refreshUI = true
  local statusBar = nil
  if (componentType == "filesystem") then
    statusBar = newStatusBar("&Mount" , 14, "Back", 28, "View")
  else
    statusBar = newStatusBar(14, "Back", 28, "View")
  end
  local list = newList(1, 3, term.width, term.height - 4)
  if (componentType == "filesystem") then
    local mounts = getMounts()
    local address, label, mode, path
    local mwl, mwp = 0, 0
    for a = 1, #addressList do
      local count = 0
      for m = 1, #mounts do
        if (#mounts[m][2] > mwl) then
          mwl = #mounts[m][2]
        end
        if (#mounts[m][4] > mwp) then
          mwp = #mounts[m][4]
        end
        if (mounts[m][1] == addressList[a]) then
          address, label, mode, path = mounts[m][1], mounts[m][2], mounts[m][3], mounts[m][4]
          count = count + 1
        end
      end
      -- spacing + address + spacing + "[??] " + label + spacing + path + spacing
      if (term.width >= 1 + #addressList[1] + 1 + 5 + mwl + 1 + mwp + 1) then
        if (count > 1) then
          list:add(addressList[a].." "..pad(tostring(count), 4, true).." mounts")
        else
          list:add(addressList[a].." ["..mode.."] "..pad(label, mwl).." "..path)
        end
      else
        local diff = term.width - (mwl + mwp + 11)
        if (diff < 5) then
          diff = 5
        end
        if (count > 1) then
          list:add(string.sub(addressList[a], 1, diff)..".. "..pad(tostring(count), 4, true).." mounts")
        else
          list:add(string.sub(addressList[a], 1, diff)..".. ["..mode.."] "..pad(label, mwl).." "..path)
        end
      end
    end
  else
    local cap = componentType
    if (#cap > #addressList[1]) then
      local parts = split(cap, "_")
      local s = #parts
      cap = ""
      while #cap < #addressList[1] do
        cap = parts[1].."_..."
        for p = s, #parts do
          cap = cap.."_"..parts[p]
        end
        s = s - 1
      end
      s = s + 2
      cap = parts[1].."_..."
      for p = s, #parts do
        cap = cap.."_"..parts[p]
      end
    end
    for a = 1, #addressList do
      if (term.width > 1 + #addressList[1] + 1 + #cap + 1) then
        list:add(addressList[a].." "..cap)
      else
        local diff = term.width - (#cap + 5)
        if (diff < 5) then
          diff = 5
        end
        list:add(string.sub(addressList[a], 1, diff)..".. "..cap)
      end
    end
  end
  local res
  while running do
    if (refreshUI) then
      term:cleartb()
      statusBar:render()
      refreshUI = false
    end
    list:render()
    local e, p1, p2, p3, p4, p5 = list:checkEvent(event.pull())
    if (e == "listbox_select") then
      local addr = findAddress(p3, addressList)
      if (menuMethods(componentType, addr) == "quit") then
        res = "quit"
        running = nil
      else
        refreshUI = list:refresh()
      end
    elseif (e) then
      r = stdEvents(e, p1, p2, p3, p4, p5, componentType)
      if (r == "menu_back") then
        running = nil
      elseif (r == "menu_mount") then
        local addr = findAddress(list:getSelectedEntry(), addressList)
        if (menuMounts(addr, addressList) == "quit") then
          res = "quit"
          running = nil
        else
          refreshUI = list:refresh()
        end
      elseif (r == "ui_refresh") then
        refreshUI = list:refresh()
      elseif (r == "quit") then
        res = "quit"
        running = nil
      end
    end
  end -- while
  list:clear(true)
  list = nil
  statusBar = nil
  os.sleep(0)
  return res
end

-- Menu: Component type selection
local function menuType()
  local running = true
  local refreshUI = true
  local cl = {}
  local ci = 1
  local statusBar = newStatusBar("&Quit", "&Help", 28, "View")
  local list = newList(1, 3, term.width, term.height - 4)
  while running do
    if (refreshComponents) then
      cl = getComponents()
      list:clear()
      for c = 1, #cl do
        list:add(cl[c][1])
      end
      refreshComponents = false
      refreshUI = true
    end
    if (refreshUI) then
      term:cleartb()
      statusBar:render()
      refreshUI = false
    end
    list:render()
    local e, p1, p2, p3, p4, p5 = list:checkEvent(event.pull())
    if (e == "listbox_select") then
      for c = 1, #cl do
        if (cl[c][1] == p3) then
          if (menuAddress(cl[c][1], cl[c][2]) == "quit") then
            running = nil
          else
            refreshUI = list:refresh()
          end
          break
        end
      end
    elseif (e) then
      local r = stdEvents(e, p1, p2, p3, p4, p5)
      if (r == "ui_refresh") then
        refreshUI = list:refresh()
      elseif (r == "quit") then
        running = nil
      end
    end
  end
  list:clear(true)
  list = nil
  statusBar = nil
  os.sleep(0)
end

loadTheme()
if (term.width > 80 and term.height > 25) then
  term:init(80, 25)
end
menuType()

-- Clean up globals
term:close()
term = nil -- clear: newTerm() object, not the term API!!
theme = nil
-- Clear library vars
components = nil
event = nil
keyb = nil
uni = nil
fs = nil