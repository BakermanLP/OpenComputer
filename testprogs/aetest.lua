local helper = require("helper")
local textutils=require("serialization")
local component = require("component")
local ae = component.proxy(component.list("me_controller")())

local craftables = ae.getCraftables()
local networkItems = ae.getItemsInNetwork()

for i,j in ipairs(networkItems) do
  print(j.name.."."..tostring(j.damage))
  helper.print_r(j)
end