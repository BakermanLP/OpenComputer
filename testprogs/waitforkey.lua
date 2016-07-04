local event=require("event")

local running = true
local char_space = string.byte(" ")


while running do
  print("10 sekunden bis ende oder keypress")
  local _,_,char = event.pull(10,"key_down")
  print(char)
  if ( char ~= nil ) then
    running = false
  end
end