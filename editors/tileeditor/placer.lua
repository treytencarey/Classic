--[[
--   The placer works with the editor and the world to place down selected tiles and show where we're placing them
--]]

function onCreated()
  rect = CreateImage("GLOBAL/pixel.png", 0,0,16,16); rect:setClipped(false); rect:hide()
  rect:setColor(0,0,255,100)
  lastRectPos = nil -- To avoid placing a ton of tiles at the same location

  rectParent = script:getValue("topLayer", "Scripts/world.lua"); rectParent:addElement(rect)

  undoList = { {} }; maxUndos = 30

  clipboard = {}
  setClipboard()

  selElem = nil

  tileset = nil
end

-- Set which tileset the placer is using
function setTileset(newTileset)
  tileset = newTileset

  setClipboard()
end

-- Clipboard may come from the editor while selecting tiles
function setClipboard(tiles)
  if tiles == nil then
    -- Same as tiles[1][1] = { x = 0, y = 0 }
    tiles = { { { x = 0, y = 0 } } }
  end

  clipboard = tiles
end

function undo()
  for x,tbl in pairs(undoList[#undoList-1]) do
    for y,tile in pairs(tbl) do
      if tile.cropX ~= nil then -- Tile existed before a new one was placed; revert to old tile
        script:triggerFunction("setTile", "Scripts/world.lua", tile.x, tile.y, tile.layer, tile.img, tile.cropX, tile.cropY)
      else -- Tile didn't exist before a new one was placed; remove it
        script:triggerFunction("removeTile", "Scripts/world.lua", tile.x, tile.y, tile.layer)
      end
    end
  end
  table.remove(undoList, #undoList-1)
end

-- Gets the real position of an element. e.g if an element is at position 10 but it's parent is at position 20, the absolute position is 30.
function getAbsolutePosition(elem)
  if elem == nil then return; end

  local x,y = elem:getPosition()
  while elem ~= elem:getParent() do
    elem = elem:getParent()

    local px, py = elem:getPosition()
    x = x + px; y = y + py
  end

  return x,y
end

-- Gets the element's top-most parent. e.g a tile's absolute parent is the world (rather than the layer)
function getAbsoluteParent(elem)
  if elem == nil then return; end

  while elem ~= elem:getParent() do
    elem = elem:getParent()
  end
  return elem
end

-- Places clipboard tiles starting at a screen position
function placeTiles(x, y)
  tileset = script:getValue("tileset", "Scripts/editors/tileeditor/editor.lua")
  local layer = script:getValue("layerScroll", "Scripts/editors/tileeditor/editor.lua"); layer = layer:getValue()+1
  for cx,tbl in pairs(clipboard) do
    for cy,v in pairs(tbl) do
      local absX, absY = x+(cx-1)*16, y+(cy-1)*16

      if undoList[#undoList][absX] == nil then undoList[#undoList][absX] = {}; end
      if undoList[#undoList][absX][absY] == nil then
        local oldTile = script:triggerFunction("getTile", "Scripts/world.lua", absX, absY, layer)
        if oldTile ~= nil then -- Placing a tile where a tile used to be
          local oCX, oCY, oCW, ocH = oldTile:getCrop()
          
          undoList[#undoList][absX][absY] = {x = absX, y = absY, layer = layer, img = oldTile:getImage(), cropX = oCX, cropY = oCY}
        else -- Placed a new tile; no tiles existed where this one is begin put
          undoList[#undoList][absX][absY] = {x = absX, y = absY, layer = layer}
        end
      end

      script:triggerFunction("setTile", "Scripts/world.lua", absX, absY, layer, tileset:getImage(), v.x, v.y)
    end
  end
end

function getWorld(elem)
  return script:getValue("parent", "Scripts/world.lua")
end

function onLeftMouseDown(mID)
  local elem = mouse:getElement(mID)

  local world = getWorld()
  -- If we're clicking on the world
  if elem ~= nil and world ~= nil and getAbsoluteParent(elem) == world then
    selElem = { elem = world, mID = mID }
    onMouseMoved(mID) -- trigger place tile
  end
end

function onLeftMouseUp(mID)
  local elem = mouse:getElement(mID)

  local world = getWorld()
  -- If we lifted our mouse from the world
  if elem ~= nil and world ~= nil and getAbsoluteParent(elem) == world then
    table.insert(undoList, {})
    if #undoList > maxUndos then table.remove(undoList, 1); end

    -- Mobile doesn't place tiles until lifting a finger
    if game:isMobile() and selElem ~= nil and selElem.elem == world and selElem.mID == mID then
      placeTiles(rect:getPosition())
    end
  end
  selElem = nil
  lastRectPos = nil
end

function onMouseMoved(mID)
  local elem = mouse:getElement(mID)

  local world = getWorld()
  -- If our mouse moved over the world
  if elem ~= nil and world ~= nil and getAbsoluteParent(elem) == world then
    elem = world

    local x, y = getAbsolutePosition(elem)
    x = math.floor((mouse:getX(mID, true) - x)/16)*16
    y = math.floor((mouse:getY(mID, true) - y)/16)*16

    rect:bringToFront(); rect:setRect(x, y, #clipboard*16, #clipboard[1]*16); rect:show()

    -- Avoid placing tiles if our mose only moved a few pixels (prevents placing at the same location several times)
    if lastRectPos == nil or lastRectPos.x <= rect:getX()-16 or lastRectPos.x >= rect:getX()+16 or lastRectPos.y >= rect:getY()+16 or lastRectPos.y <= rect:getY()-16 then
      -- PC places tiles each time we click and drag
      if game:isMobile() == false and selElem ~= nil and selElem.elem == world and selElem.mID == mID then
        placeTiles(rect:getPosition())
        lastRectPos = { x = rect:getX(); y = rect:getY() }
      end
    end
  else -- Mouse did not move over the world
    rect:hide()
  end
end