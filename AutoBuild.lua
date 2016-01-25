--
-- Includes
-- 
local nav = require("nibnav")
local sides = require("sides")
local robot = require("robot")
local computer = require("computer")
-- local term = require("term")

local file = io.open("/industrialbuilding.txt")
local i = 0

-- Init Robot Position
nav.setPosition(0,0,0,sides.east)

function explode(div,str)
    if (div=='') then return false end
    local pos,arr = 0,{}
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1))
        pos = sp + 1
    end
    table.insert(arr,string.sub(str,pos))
    return arr
end

function refuel(lastY)
    print("Need to refuel, going to 0,0,0")
    print("Energy before goto 0,0,0 : "..tostring(computer.energy()))
    print("Calculated fuel to 0,0,0 : "..tostring(nav.getCost(0,0,0)))
    nav.moveXZ(0,0)
    nav.moveY(0)
    print("Energy after goto 0,0,0 : "..tostring(computer.energy()))
    while computer.maxEnergy() - computer.energy() > 100 do
       os.sleep(1)
    end
    nav.moveY(lastY)
end

function placeBlock()
    if robot.count() < 2 then
        local findSlot = 0

        for slot=2, robot.inventorySize() do
            if robot.count(slot) > 1 then
                findSlot = slot
                print("Next Slot: "..tostring(findSlot))
                break
            end
        end

        if findSlot < 1 then
            refill()
            findSlot=2
        end
        robot.select(findSlot)
    end
    repeat
        robot.swingDown()
    until robot.placeDown()
end

function refill()
    robot.select(1)
    robot.swingUp()
    robot.placeUp()

    for slot=2, robot.inventorySize() do
        if robot.space(slot) > 0 then
          robot.select(slot)
          print("Filling Slot "..tostring(slot))
          repeat
            local before = robot.space()
            robot.suckUp(robot.space())
            if robot.space() == before then
              os.sleep(5) -- Don't busy idle.
            end
          until robot.space() < 1
        end
    end

    robot.select(1)
    robot.swingUp()
    robot.select(2)
end

-- MAIN
if file then
  write = io.write
  io.input(file)
  line = io.read() -- #binvox ASCII data
--  print( line )
  line = io.read() -- dim 5 5 5
--  print(line)
  local maxsx, maxsy,maxsz = line:match("dim (%d+) (%d+) (%d+)")
  local maxx,maxy,maxz = tonumber(maxsx),tonumber(maxsy),tonumber(maxsz)

  tmp = io.read() -- translate -7.595 -24.27 -68.41
  tmp = io.read() -- scale 135.94
  tmp = io.read() -- data

  local tbllines = {}

  -- tblline[z][x] !!
  for y=0, maxy-1 do
     
    print("Ebene "..tostring(i))
    for b=1,maxz do
      line=io.read()
      tbllines[b]=explode(" ",line)
    end

    local findings = 1
    -- minway auf Maximalen Weg in alle 3 Koordinaten setzen

    while findings > 0 do
        local minway=maxx * 3 * 15 + 10
        findings = 0
        for x=1,maxx do
            for z=1,maxz do
                if tbllines[z][x] == "1" then
                    findings = findings + 1
                    tempway=nav.getCost(x,y,z)
                    
                    if tempway<minway then
                    -- print(tostring(x)..","..tostring(y)..","..tostring(z).." => "..tostring(tempway))
                        minway = tempway
                        nextX = x
                        nextZ = z
                    end
                end
            end
        end
        print("NextX = "..tostring(nextX)..", NextZ = "..tostring(nextZ))
        nav.moveXZ(nextX,nextZ)
        -- Place Block
        placeBlock()
        tbllines[nextZ][nextX] = "0"
        findings = findings - 1
        print("Noch "..tostring(findings).." Bloecke zu setzen")

        refuelCost = nav.getCost(0,0,0)
        maxTravelCost = maxx * 3 * 15 + 10 
        if computer.energy() < refuelCost + maxTravelCost then
            refuel(y)
        end

        os.sleep(0.1)
    end

    nav.up()
  end
  file:close()
  nav.moveXZ(0,0)
  nav.moveY(0)
  nav.faceSide(sides.east)
else
  error("file not found")
end