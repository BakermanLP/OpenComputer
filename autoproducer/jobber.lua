-- Config part
local config = require("iniparse")
local pathToConfig = "items.cfg"
local textutils = require("serialization")
local myConfig = config.parse(pathToConfig)

-- AE part
local component = require("component")
local ae = component.proxy(component.list("me_controller")())

-- Network part
local network = require "network"
network.init()

-- Helper API
local helper = require("helper")

-- Main
for i,c in pairs( myConfig ) do
  local pointPos = string.find(i, ".[^.]*$")
  local nameToFind = string.sub(i, 1, pointPos-1)
  local damageToFind = tonumber(string.sub(i, pointPos+1))

  tobeinSystem = c
  inSystem = 0

  data = ae.getItemsInNetwork({name = nameToFind, damage = damageToFind})

  if data.n == 1 then
    data = data[1]
    inSystem = data.size
  end

  toProduce = tobeinSystem - inSystem

  if toProduce > 0 then
    print("Suche nach "..nameToFind.."."..tostring(nameToFind).." soll: "..tostring(tobeinSystem).." ist: "..tostring(inSystem).." toProduce: "..tostring(toProduce))
  
    job = { type="produce", name=nameToFind, damage=damageToFind, count=toProduce }

    network.send(job)  
    os.sleep(10)
  end
  os.sleep(1)
end