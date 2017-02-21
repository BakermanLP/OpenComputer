--
-- Includes
-- 
local nav = require("nibnav")
local sides = require("sides")
local robot = require("robot")
local computer = require("computer")
local log = require("log")

local i = 0

-- Init Robot Position
nav.setPosition(0,0,0,sides.east)

-- Init log modul
log.outfile="debug.log"
log.level="debug"

--
-- Functions
--
function table.count(table, element, minx, maxx, minz, maxz)
  local counter = 0
  local a
  local b

  for a=minx,maxx do
      for b=minz,maxz do
          if table[b][a] == element then
                counter = counter + 1
          end
    end
  end

  return counter
end

function parseCmdLine(args)
    local retval = {"testing.txt",0}

    for i = 1, #args do
        retval[i]=args[i]
    end

    return retval[1], retval[2]
end

function explode(div,str)
    local multiplier = 0
    local special = ''
    local count = 0

    local pos,arr = 0,{}
    for st,sp in function() return string.find(str,' ',pos,true) end do
        if count % 2 == 0 then
            multiplier = string.sub(str,pos,st-1)
        else
            special=string.sub(str,pos,st-1)
            for i=1,multiplier do
                table.insert(arr,special)
            end
        end
        pos = sp + 1
        count = count + 1
    end

    return arr
end

function refuel(lastY)
    log.info("Need to refuel, going to 0,0,0")
    nav.moveXZ(0,0)
    nav.moveY(0)
    while computer.maxEnergy() - computer.energy() > 100 do
       os.sleep(1)
    end
    nav.moveY(lastY)
end

function placeBlock()
    log.trace("Function placeBlock")
    if robot.count() < 2 then
        local findSlot = 0

        for slot=2, robot.inventorySize() do
            if robot.count(slot) > 1 then
                findSlot = slot
                log.debug("Next Slot: "..tostring(findSlot))
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
    log.trace("Function refill")
    robot.select(1)
    robot.swingUp()
    robot.placeUp()

    for slot=2, robot.inventorySize() do
        if robot.space(slot) > 0 then
          robot.select(slot)
          log.debug("Filling Slot "..tostring(slot))
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

--
-- MAIN
--

local args = {...}
local tmp = ''
filename= parseCmdLine(args)
local file = io.open(filename,"r")

if file then
  write = io.write
  io.input(file)
  tmp = io.read() -- #binvox ASCII data
  line = io.read() -- dim 5 5 5
  local maxsx, maxsy,maxsz = line:match("dim (%d+) (%d+) (%d+)")
  local maxx,maxy,maxz = tonumber(maxsx),tonumber(maxsy),tonumber(maxsz)

  tmp = io.read() -- translate -7.595 -24.27 -68.41
  tmp = io.read() -- scale 135.94
  tmp = io.read() -- data

  -- tblline[z][x] !!
  for y=0, maxy-1 do
    local tbllines = {}
     
    -- Aktuelle Ebene einlesen
    for b=1,maxz do
      line=io.read()
      tbllines[b]=explode(" ",line)
    end

    local findings = table.count(tbllines,"1", 1, maxx, 1, maxz)
    log.info("Layer "..tostring(y).." blocks to set "..findings)
    -- minway auf Maximalen Weg in alle 3 Koordinaten setzen

    while table.count(tbllines,"1", 1, maxx, 1, maxz) > 0 do
        local minway=maxx * 3 * 15 + 10

        local gotcha = 0
        for x=1,maxx do
            for z=1,maxz do
                if tbllines[z][x] == "1" then
                    gotcha = 1
                    tempway=nav.getCost(x,y,z)
                    
                    if tempway<minway then
                        minway = tempway
                        nextX = x
                        nextZ = z
                    end
                end
            end
        end
        -- Nur laufen und Setzen, wenn wirklich Block platzieren
        if gotcha > 0 then
            log.trace("Next block to set X = "..tostring(nextX)..", NextZ = "..tostring(nextZ))
            nav.moveXZ(nextX,nextZ)
            placeBlock()
        end
        tbllines[nextZ][nextX] = "0"

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
  log.fatal("file not found")
end
