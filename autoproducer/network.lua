--[[ Little network library ]]

local event = require "event"
local component = require "component"
local modem = component.modem
local serial = require("serialization")

local network = {}

network.myaddress = modem.address

network.port = 831
network.signalStrength=256

function network.init()
  modem.setStrength(512)
  modem.open(network.port)
end

function network.send(data)
    modem.broadcast(network.port,serialize)

    _,_,sender,_,_,message = event.pull(5,"modem") -- wait 5 secs for reply

    if message ~= nil then
        print("Confirmation of execution from "..tostring(sender))
    else
        print("Did not receive confirmation in time from "..tostring(network.port)..".")
    end
end

function network.listen()
  local _, localNetworkCard, remoteAddress, inport, distance, payload = event.pull("modem_message")
  modem.send(remoteAddress, network.port,"OK")
  return(payload)
end

return network