function onCreated()
  script:triggerFunction("onCreated", "Scripts/player.lua") -- Reset player if this script was updated

  -- Create parent. Holds part of grid
  parent = CreateListBox(0,0,0,0)
  
  grids = {}
  layers = {}
  tiles = {}
  topLayer = CreateListBox(0,0,0,0); parent:addElement(topLayer) -- Used for displaying above everything, such as clouds or a tile placer
  
  gridSq = { w = 7*16, h = 7*16 }
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
    grid = CreateListBox(gridX*gridSq.w, gridY*gridSq.h, gridSq.w, gridSq.h)
    grids[tostring(gridX)][tostring(gridY)] = grid
    parent:addElement(grid)
  end
  
  -- Create layer. Holds tiles
  if layers[tostring(gridX)][tostring(gridY)][tostring(layer)] == nil then
    local layerLB = CreateListBox(0,0,0,0)
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
    tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)][tostring(tileY)]:remove()
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
    tile = CreateImage(img, (tileX-1)*16, (tileY-1)*16, 16, 16); tile:setClipped(false)
    tile:crop(cropX,cropY,16,16)

    if tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)] == nil then tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)] = {}; end
    tiles[tostring(gridX)][tostring(gridY)][tostring(layer)][tostring(tileX)][tostring(tileY)] = tile
    layers[tostring(gridX)][tostring(gridY)][tostring(layer)]:addElement(tile)
  end

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

function loadGrid(gridX, gridY)
  checkCreateLists(gridX, gridY, 1)
  
  for x=0, gridSq.w-1, 16 do
    for y=0, gridSq.h-1, 16 do
      local tile = CreateImage("Tilesets/tileset2.png", x, y, 16, 16); tile:setClipped(false)
      tile:crop(0,0,16,16)
      if tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(x/16+1)] == nil then tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(x/16+1)] = {}; end
      tiles[tostring(gridX)][tostring(gridY)]["1"][tostring(x/16+1)][tostring(y/16+1)] = tile
      -- Add tile to first layer of grid
      layers[tostring(gridX)][tostring(gridY)]["1"]:addElement(tile)
    end
  end
  
  topLayer:bringToFront()
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

function main()
  parent:bringToBack()
end