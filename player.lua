function onCreated()
  game:setTimeout(5, "dependents")
end

-- Triggered when dependent scripts have loaded
-- e.g can't add the player until the world has loaded
function onCreatedDependents()
  script:clear(script:thisName()) 
  script:triggerFunction("removeGrids", "Scripts/world.lua") -- In case this script was updated

  self:removeKey("gridPos")

  player = CreateImage("Players/player.png", 0, 0, 32, 32); player:setScaled(getWorld():getScaled()); player:crop(32,0,32,32); player:center(); player:setClipped(false); player:setProperty("isPlayer", "1")
  playerSpeed = 4; maxPlayerSpeed = playerSpeed*3
  getWorld():setPosition(0,0)
  local topLayer = script:getValue("topLayer", "Scripts/world.lua")
  topLayer:addElement(player)
  playerPos = { x = player:getX(), y = player:getY() }

  chat = CreateText("", 0, -4)
  player:addElement(chat)
  
  playerMoving = {}; moveTimeout = nil; animTimeout = nil
  
  fullOnGrid = {}
  lastOnGrid = nil
  updateGridPosition()

  sendPlayer()
end

function setChat(txt)
  chat:setText(txt); sendPlayer(chat)
end

-- Gets the element's top-most parent. e.g a tile's absolute parent is the world (rather than the layer)
function getAbsoluteParent(elem)
  if elem == nil then return; end

  while elem ~= elem:getParent() do
    elem = elem:getParent()
  end
  return elem
end

function getWorld()
  return script:getValue("parent", "Scripts/world.lua")
end

function onKeyDown(key)
  -- Move the player if we aren't clicked on a button, editbox, etc.
  if game:getFocusedElement() == nil or getAbsoluteParent(game:getFocusedElement()) == getWorld() or getAbsoluteParent(game:getFocusedElement()) == player then
    key = key == "W" and "UP" or key == "S" and "DOWN" or key == "A" and "LEFT" or key == "D" and "RIGHT" or key

    if playerMoving[key] == nil and (key == "LEFT" or key == "RIGHT" or key == "UP" or key == "DOWN") then
      if playerIsMoving() == false then startWalk = true; end -- Start with walking animation

      -- Can't move left & right at the same time. Same for up/down.
      playerMoving[key == "LEFT" and "RIGHT" or key == "RIGHT" and "LEFT" or key == "UP" and "DOWN" or "UP"] = nil
      
      playerMoving[key] = true
      movePlayer(playerSpeed)
      if startWalk then onTimeout("animPlayer", 0); startWalk = nil; end
    end
  end
end

function onKeyUp(key)
  key = key == "W" and "UP" or key == "S" and "DOWN" or key == "A" and "LEFT" or key == "D" and "RIGHT" or key
  if playerMoving[key] ~= nil then
    playerMoving[key] = nil
    onTimeout("animPlayer", 0) -- Show that the player is no longer moving
  end
end

-- Get which grid we're on
function getOnGrid()
  local gridSq = script:getValue("gridSq", "Scripts/world.lua")
  return { math.floor(playerPos.x/gridSq.w), math.floor(playerPos.y/gridSq.h), gridSq.horiz, gridSq.vert }
end

-- Send to all clients who have a grid we're standing on
function sendPlayer(obj)
  obj = obj or player
  lastOnGrid = getOnGrid()
  local posStr = tostring(lastOnGrid[1]) .. "," .. tostring(lastOnGrid[2])
  obj:sendToClients(true, "gridPos", posStr)
end

function playerIsMoving()
  return playerMoving["LEFT"] ~= nil or playerMoving["RIGHT"] ~= nil or playerMoving["UP"] ~= nil or playerMoving["DOWN"] ~= nil
end

function movePlayer(speed)
  if speed > maxPlayerSpeed then speed = maxPlayerSpeed; end -- Max speed due to lag
  
  -- Get our changed X/Y position based on the key pressed
  local difX = playerMoving["LEFT"] and speed*(-1) or playerMoving["RIGHT"] and speed or 0
  local difY = playerMoving["UP"] and speed*(-1) or playerMoving["DOWN"] and speed or 0

  --[[
  -- TODO - To move the player instead (rather than the world, e.g. when reaching the end of a level)
  -- don't change playerPos or getWorld() positions. Instead, add to player position directly.
  --]]
  playerPos.x = playerPos.x + difX
  playerPos.y = playerPos.y + difY
  getWorld():setPosition(getWorld():getX() - difX, getWorld():getY() - difY)
  player:setPosition(playerPos.x, playerPos.y) -- Since the player is an element of the world, need to move him with it

  if moveTimeout == nil and playerIsMoving() then
    game:setTimeout(5, "movePlayer"); moveTimeout = true
    if animTimeout == nil then
      game:setTimeout(150, "animPlayer"); animTimeout = true -- Change running frame every given milliseconds

      local dir = difY > 0 and 0 or difX < 0 and 1 or difY < 0 and 3 or difX > 0 and 2 or 0
      local pCropX, pCropY = player:getCrop()
      player:crop(pCropX, dir*32, 32, 32) -- Set the player direction (left/right/up/down)
    end
  end

  updateGridPosition()
  sendPlayer()
end

function compareGrids(t1, t2)
  local newT = {}
  for i,tbl1 in pairs(t1) do
    local found = nil
    for n,tbl2 in pairs(t2) do
      if tbl1[1] == tbl2[1] and tbl1[2] == tbl2[2] then
        found = n; break
      end
    end
    if found == nil then
      table.insert(newT, tbl1)
    end
  end
  return newT
end

function printGrid(tbl)
  for i,t in pairs(tbl) do
    print("  " .. tostring(t[1]) .. ", " .. tostring(t[2]))
  end
end

function updateGridPosition(doAnyways)
  local onGrid = getOnGrid()
  
  if doAnyways == true or lastOnGrid == nil or onGrid[1] ~= lastOnGrid[1] or onGrid[2] ~= lastOnGrid[2] then
    local newFullOnGrid = {}
    --[[ Create new grid, determined in the world script by window size --]]
    for i=math.ceil(onGrid[3]/2)*(-1), math.ceil(onGrid[3]/2) do
      for n=math.ceil(onGrid[4]/2)*(-1), math.ceil(onGrid[4]/2) do
        table.insert(newFullOnGrid, { onGrid[1]+i, onGrid[2]+n } )
      end
    end

    local remKeys = compareGrids(fullOnGrid, newFullOnGrid)
    local addKeys = compareGrids(newFullOnGrid, fullOnGrid)

    --  If we remove all keys, simply clear them. Otherwise remove individual keys.
    -- We don't do an else-if so that we can remove all before adding, or add before removing certain keys (prevents "flickering" when a key is removed).
    if #remKeys == #fullOnGrid then
      self:removeKey("gridPos")
      script:triggerFunction("removeGrids", "Scripts/world.lua")
      -- print("Removing all keys")
    end

    --  Add keys
    for i,tbl in pairs(addKeys) do
      self:addKey("gridPos", tostring(tbl[1]) .. "," .. tostring(tbl[2]))
      script:triggerFunction("loadGrid", "Scripts/world.lua", tbl[1], tbl[2])
      -- print("Adding key: " .. tostring(tbl[1]) .. ", " .. tostring(tbl[2]))
    end

    -- Read above (removing all keys) for why this isn't in an else-statement.
    if #remKeys ~= #fullOnGrid then
      for i,tbl in pairs(remKeys) do
        self:removeKey("gridPos", tostring(tbl[1]) .. "," .. tostring(tbl[2]))
        script:triggerFunction("removeGrid", "Scripts/world.lua", tbl[1], tbl[2])
        -- print("Removing key: " .. tostring(tbl[1]) .. ", " .. tostring(tbl[2]))
      end
    end
    --[[
      print("Old (" .. tostring(lastOnGrid[1]) .. ", " .. tostring(lastOnGrid[2]) .. "):"); printGrid(fullOnGrid)
      print("Adding:"); printGrid(addKeys)
      print("Removing:"); printGrid(remKeys)
      print("New (" .. tostring(onGrid[1]) .. ", " .. tostring(onGrid[2]) .. "):"); printGrid(newFullOnGrid)
    --]]

    fullOnGrid = newFullOnGrid

    lastOnGrid = onGrid
  end
end

function onTimeout(ID, time, realTime)
  if ID == "movePlayer" then
    moveTimeout = nil; movePlayer(realTime/time*playerSpeed)
  elseif ID == "animPlayer" then
    animTimeout = nil
    local pCropX, pCropY = player:getCrop()
    player:crop(playerIsMoving() and (pCropX < 32*2 and pCropX+32 or 0) or 32, pCropY, 32, 32) -- If we're running, change frame. Otherwise, display standing still.
    if playerIsMoving() == false then sendPlayer(); end -- Make sure clients receive the player is not moving.
  elseif ID == "dependents" then
    if game:getScript("Scripts/world.lua") ~= nil then
      onCreatedDependents()
    else
      game:setTimeout(time, ID)
    end
  end
end

-- Make sure that online players are associated with the world's position
function onCommand(cmd, cmdStr)
  local elem = server:getObjectFromCommand(cmd)
  if elem ~= nil and elem:getProperty("isPlayer") == "1" then
    getWorld():addElement(elem)
  end
end