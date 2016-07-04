-- AE part
local component = require("component")
local ae = component.proxy(component.list("me_controller")())
local craftables = ae.getCraftables()

-- Network part
local myNet = require("network")
myNet.init()

-- Serialization part
local serial = require("serialization")

-- main

while true do

  print("Warte auf Job")
  gotit = myNet.listen()
  print("Main" .. tostring(gotit))
  data = serial.unserialize(gotit)

  toProduce = ae.getCraftables({name = data.name, damage = data.damage})
  if toProduce.n == 1 then
    toProduce = toProduce[1]
    io.write("Produziere "..data.name.."."..data.damage.." Anzahl: "..tostring(data.count))

    retVal=toProduce.request(data.count)

    while retVal.isDone() == false do
      io.write(".")
      os.sleep(0.1)
    end
    print(" "..tostring(retVal.isDone()))
  end
  os.sleep(1)
end