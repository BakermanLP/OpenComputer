local config = {}

local fs = require("filesystem")

local data = {}

function config.parse(path)
  if not fs.exists(path) then return false end

  local f = io.open(path,"r")
  for line in f:lines() do
    local key, value = string.match(line, "(.*)%s=%s(.*)")
-- print(key.."=>"..value)    
    if key and value then
      data[key] = value
    end
  end
  return data
end

return config