function onCreated()
  script:triggerFunction("onCreated", "Scripts/player.lua") -- Reset player if this script was updated

  -- Create parent. Holds part of grid
  parent = CreateListBox(0,0,0,0); parent:setScaled(false)
  
  grids = {}
  layers = {}
  tiles = {}
  topLayer = CreateListBox(0,0,0,0); topLayer:setScaled(parent:getScaled()); parent:addElement(topLayer) -- Used for displaying above everything, such as clouds or a tile placer
  
  gridSq = { w = 30*16, h = 30*16 }
end

-- Creates necessary lists if they don't exists
function checkCreateLists(gridX, gridY, layer)
  if grids[tostring(gridX)] == nil then grids[tostring(gridX)] = {}; end
  if layers[tostring(gridX)] == nil then layers[tostring(gridX)] = {}; end
  if layers[tostring(gridX)][tostring(gridY)] == nil then layers[tostring(gridX)][tostring(gridY)] = {}; end
  if tiles[tostring(gridX)] == nil then tiles[tostring(gridX)] = {}; end
  if tiles[tostring(gridX)][tostring(gridY)] == nil then tiles[tostring(gridX)][tostring(gridY)] = {}; end
  if tiles[tostring(gridX)][tostring(gridY)][tostring(layer)] == nil then tiles[tostring(gridX)][tostring(gridY)][tostring(layer)] = {}; end

  -- Create part of grid. Holds layers
  local grid = grids[tostring(gridX)][tostring(gridY)]
  if grid == nil then
    grid = CreateListBox(gridX*gridSq.w, gridY*gridSq.h, gridSq.w, gridSq.h); grid:setScaled(parent:getScaled())
    grids[tostring(gridX)][tostring(gridY)] = grid
    parent:addElement(grid)
  end
  
  -- Create layer. Holds tiles
  if layers[tostring(gridX)][tostring(gridY)][tostring(layer)] == nil then
    local layerLB = CreateListBox(0,0,0,0); layerLB:setScaled(parent:getScaled())
    layers[tostring(gridX)][tostring(gridY)][tostring(layer)] = layerLB
    grid:addElement(layerLB)
    reorderLayers(gridX, gridY)
  end
end

-- Get a tile on any grid based on position and layer. Returns nil if none exists.
function getTile(x, y, layer)
  local gridX, gridY = math.floor(x/gridSq.w), math.floor(y/gridSq.h)
  local tileX, tileY = math.floor((x-gridX*gridSq.w)/16)+1, math.floor((y-gridY*gridSq.h)/16)+1

  if tiles[tostring(gridX)] ~= nil and tiles[tostring(gridX)][tostring(gridY)] ~= nil and tiles[tostring(gridX)][tostring(gridY)][tostring(layer)] ~= nil and tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)] ~= nil then
    return tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)][tostring(tileY)]
  end
  return nil
end

-- Remove a tile on any grid based on tile position
function removeTile(x, y, layer)
  local gridX, gridY = math.floor(x/gridSq.w), math.floor(y/gridSq.h)
  local tileX, tileY = math.floor((x-gridX*gridSq.w)/16)+1, math.floor((y-gridY*gridSq.h)/16)+1

  if tiles[tostring(gridX)] ~= nil and tiles[tostring(gridX)][tostring(gridY)] ~= nil and tiles[tostring(gridX)][tostring(gridY)][tostring(layer)] ~= nil and tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)] ~= nil and tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)][tostring(tileY)] ~= nil then
    local tile = tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)][tostring(tileY)]
    tile:removeFromClients()
    tile:remove()
    tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)][tostring(tileY)] = nil
  end
end

-- Set a tile on any grid based on tile position
function setTile(x, y, layer, img, cropX, cropY)
  local gridX , gridY = math.floor(x/gridSq.w), math.floor(y/gridSq.h)
  local tileX, tileY = math.floor((x-gridX*gridSq.w)/16)+1, math.floor((y-gridY*gridSq.h)/16)+1

  checkCreateLists(gridX, gridY, layer)
  if tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)] == nil then tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)] = {}; end

  tile = tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)][tostring(tileY)]
  if tile ~= nil then 
    tile:setImage(img); tile:crop(cropX, cropY, 16, 16)
  else
    tile = CreateImage(img, (tileX-1)*16, (tileY-1)*16, 16, 16); tile:setID(getTileID(gridX, gridY, tileX, tileY, layer)); tile:setProperty("isTile", "1"); tile:setClipped(false); tile:setScaled(parent:getScaled())
    tile:crop(cropX,cropY,16,16)

    if tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)] == nil then tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)] = {}; end
    tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)][tostring(tileY)] = tile
    layers[tostring(gridX)][tostring(gridY)][tostring(layer)]:addElement(tile)
  end
  tile:sendToClients(true, "gridPos", tostring(gridX) .. "," .. tostring(gridY))

  -- print("Placing at: " .. tostring(gridX) .. ", " .. tostring(gridY) .. ", " .. tostring(tileX) .. ", " .. tostring(tileY))
end

-- E.g if layers 1 and 4 already exist but 3 was just created, layer 3 will be above layer 4.
-- This way, we can move them around as necessary. 
function reorderLayers(gridX, gridY)
  local lyrs = layers[tostring(gridX)][tostring(gridY)]
  local lyrNums = {}
  
  -- Turn each layer into a number (from a string) and sort
  for num,k in pairs(lyrs) do table.insert(lyrNums, num+0); end
  table.sort(lyrNums)
  
  -- bringToFront starting at first layer in sorted numbers
  for i,num in pairs(lyrNums) do lyrs[tostring(num)]:bringToFront(); end
  topLayer:bringToFront()
end

function getTileID(gridX, gridY, tileX, tileY, layer)
  return "-" .. tostring(gridX) .. "-" .. tostring(gridY) .. "-" .. tostring(tileX) .. "-" .. tostring(tileY) .. "-" .. tostring(layer)
end

function loadGrid(gridX, gridY)
  checkCreateLists(gridX, gridY, 1)
  local begX = operations:arraySize(tiles[tostring(gridX)][tostring(gridY)]["1"])
  local begY = tiles[tostring(gridX)][tostring(gridY)]["1"] and tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(begX)] and operations:arraySize(tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(begX)]) or 0
  if begY > 0  then begX = begX-1; end

  local time, maxTime= game:getTime(), 150
  for x=begX*16, gridSq.w-1, 16 do
    for y=begY*16, gridSq.h-1, 16 do
      local tileX, tileY = math.floor(x/16)+1, math.floor(y/16)+1
      local ID = getTileID(gridX, gridY, tileX, tileY, 1)
      local tile = game:getElementFromID(ID)
      if tile == nil then
        tile = CreateImage("Tilesets/tileset2.png", x, y, 16, 16); tile:setID(ID); tile:setProperty("isTile", "1"); tile:setClipped(false); tile:setScaled(parent:getScaled())
        tile:crop(0,0,16,16)
        -- Add tile to first layer of grid
        layers[tostring(gridX)][tostring(gridY)]["1"]:addElement(tile)
      else
        layers[tostring(gridX)][tostring(gridY)]["1"]:addElement(tile)
      end
      if tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(tileX)] == nil then tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(tileX)] = {}; end
      if tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(tileX)][tostring(tileY)] == nil then tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(tileX)][tostring(tileY)] = {}; end
      tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(tileX)][tostring(tileY)] = tile

      if game:getTime() > time+maxTime then game:setTimeout(150, "loadGrid," .. tostring(gridX) .. "," .. tostring(gridY)); return; end -- Tiles didn't finish loading within our maxTime. Get ready for next batch
    end
    begY = 0
  end
  topLayer:bringToFront()
  print("Loaded grid in " .. tostring(game:getTime()-time) .. " milliseconds")
end

function removeGrid(gridX, gridY)
  if grids[tostring(gridX)] == nil or grids[tostring(gridX)][tostring(gridY)] == nil then return; end
  
  local grid = grids[tostring(gridX)][tostring(gridY)]
  grid:remove()
  grids[tostring(gridX)][tostring(gridY)] = nil
  tiles[tostring(gridX)][tostring(gridY)] = nil
  layers[tostring(gridX)][tostring(gridY)] = nil
end

function removeGrids()
  for x,tbl in pairs(grids) do
    for y,grid in pairs(tbl) do
      removeGrid(x, y)
    end
  end
end

-- Always keep the world centered, if it's not scaled
function onWindowResize(lX, lY, lW, lH)
  if parent:getScaled() then return; end

  local w, h = game:getWindowWidth(), game:getWindowHeight()
  parent:setPosition(parent:getX()+(w-lW)/2, parent:getY()+(h-lH)/2)
end

function onTimeout(ID, time)
  if ID:find("loadGrid") == 1 then
    local gridInfo = operations:getTokens(ID, ",")
    local gridX, gridY = gridInfo[1], gridInfo[2]
    if grids[tostring(gridX)] ~= nil and grids[tostring(gridX)][tostring(gridY)] ~= nil then -- Don't continue loading if the grid was removed
      loadGrid(gridX, gridY)
    end
  end
end

function onCommand(cmd, cmdStr)
  local elem = server:getObjectFromCommand(cmd)
  if elem ~= nil and elem:getProperty("isTile") == "1" and elem:getParent() == elem then
    local tileProps = operations:getTokens(elem:getID(), "-")
    local gridX, gridY, tileX, tileY, layer = tileProps[1], tileProps[2], tileProps[3], tileProps[4], tileProps[5]
    checkCreateLists(gridX, gridY, layer)
    layers[tostring(gridX)][tostring(gridY)][tostring(layer)]:addElement(elem)
  end
end

function main()
  parent:bringToBack()
end