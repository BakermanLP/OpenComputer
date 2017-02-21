-- local serialization=require("serialization")

--# Implement basic API's
table.size=function(tbl)local Count=0 for k,v in pairs(tbl) do Count=Count+1 end return Count end


--# Main Block --
local function Compress(Str)
  local Length = string.len(Str)
  local retstring = ''

  OutputCurrent = 0
  CurrentChar = ''
  for I = 1, Length do
        local Current = string.sub(Str, I, I)

        if CurrentChar == Current then
          OutputCurrent = OutputCurrent +1
          if Length == I then
            retstring=retstring..OutputCurrent.." "..CurrentChar.." "
          end
        else
          if OutputCurrent > 0 then
            retstring=retstring..OutputCurrent.." "..CurrentChar.." "
          end
          OutputCurrent=1
          CurrentChar=Current
        end
  end
  -- letztes Zeichen sollte immer ein return sein, also brauchen wir das nicht
  -- retstring=retstring.."+"..OutputCurrent.." "..CurrentChar

  return retstring
end

headercount=0
for Str in io.lines("./voxels-256.txt") do
headercount=headercount+1
if headercount>5 then
    print(Compress(Str))
else
    print(Str)
end
end
