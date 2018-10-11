--[[
--   The editor that allows us to select tiles on a tileset.
--]]

function onCreated()
  menu = CreateWindow("Editing: Loading...", 0, 0, 300, 235); menu:center(); menu:setMovable(); menu:setResizable()
  menu:setMinWidth(menu:getWidth()); menu:setMinHeight(menu:getHeight())

  tileset = nil
  tilesetSq = nil; tilesetSqPos = { mID = nil, begins = { x = nil, y = nil }, ends = { x = nil, y = nil } }
  tilesetPKey = nil
  tilesetParent = CreateListBox(5, 25, 200, 175); menu:addElement(tilesetParent)

  tilesetScrollHoriz = CreateScrollBar(true, 0,0,0,0); tilesetScrollHoriz:hide(); menu:addElement(tilesetScrollHoriz)
  tilesetScrollVert = CreateScrollBar(false, 0,0,0,0); tilesetScrollVert:hide(); menu:addElement(tilesetScrollVert)

  propertiesText = CreateText("Properties", 0, 25, 80, 18); propertiesText:setTextAlignment("center", "center"); menu:addElement(propertiesText)
  propertiesParent = CreateListBox(0, 25+18, 80, 0); menu:addElement(propertiesParent)

  layerScroll = CreateScrollBar(true, 0,0,0,0); layerScroll:setMax(5); layerScroll:setSmallStep(1); menu:addElement(layerScroll)
  layerText = CreateText("Layer: 0"); layerText:setTextAlignment("left", "center"); layerText:setWordWrap(false); layerText:setClipped(false); menu:addElement(layerText)

  editButton = CreateButton("Change",0,0,80,25); menu:addElement(editButton)
  closeButton = CreateButton("Close",0,0,80,25); menu:addElement(closeButton)
  undoButton = CreateButton("Undo",0,0,80,25); menu:addElement(undoButton)

  local lx,ly,lw,lh = menu:getRect()
  onElementResize(menu, lx, ly, lw, lh)
end

function loadTileset(PKey)
  if PKey == nil then return; end

  server:getSQL("Databases/tilesets.db",
   "SELECT Type, Value " ..
    "FROM Properties " ..
    "WHERE TilesetPKey = '" .. tostring(PKey) .. "' " ..
    "UNION " ..
    "SELECT 'Name', Name " ..
    "FROM Tilesets " ..
    "WHERE PKey = '" .. tostring(PKey) .. "'",
    "loadTileset")
  tilesetPKey = PKey
  setTileset(nil)
  layerScroll:setValue(0); onScrollBarChanged(layerScroll); propertiesParent:clear()
end

function setTileset(path)
  if tileset ~= nil then tileset:remove(); tileset = nil; tilesetSq = nil; end

  if path ~= nil then
    tileset = CreateImage("Tilesets/" .. path, 0, 0)
    tilesetSq = CreateImage("GLOBAL/pixel.png", 0, 0, 16, 16); tilesetSq:setColor(0,0,255,100); tileset:addElement(tilesetSq)
    tilesetParent:addElement(tileset)
  end

  tilesetScrollHoriz:setValue(0); tilesetScrollVert:setValue(0)
  for i=0, 1 do onElementResize(menu); end
end

-- Set which tiles will be placed based on tiles selected on the tileset
function setClipboard(x, y, w, h)
  if tileset == nil then return; end

  local clipboard = {}
  local cropX, cropY, cropW, cropH = tileset:getCrop()

  for i=0, w-1, 16 do
    local posX = math.floor(i/16)+1
    clipboard[posX] = {}
    for n=0, h-1, 16 do
      local posY = math.floor(n/16)+1
      clipboard[posX][posY] = { x = cropX+i+x, y = cropY+n+y }
    end
  end

  script:triggerFunction("setClipboard", "Scripts/editors/tileeditor/placer.lua", clipboard)
end

-- Refreshes the tileset, re-grabbing information from server
function refresh()
  if tilesetPKey == nil then return; end

  loadTileset(tilesetPKey)
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

function onElementResize(elem, lx, ly, lw, lh)
  if elem == menu then
    if lx == nil then lx,ly,lw,lh = elem:getRect(); end

    tilesetParent:setWidth(tilesetParent:getWidth() + (menu:getWidth()-lw))
    tilesetParent:setHeight(tilesetParent:getHeight() + (menu:getHeight()-lh))

    if tileset ~= nil and tileset:getWidth() > tilesetParent:getWidth() then
      if tilesetScrollHoriz:isVisible() == false then
        tilesetScrollHoriz:setHeight(15)
        tilesetParent:setHeight(tilesetParent:getHeight() - tilesetScrollHoriz:getHeight())
        tilesetScrollHoriz:show()
      end
      tilesetScrollHoriz:setMax(tileset:getWidth() - tilesetParent:getWidth())
      tilesetScrollHoriz:setRect(tilesetParent:getX(), tilesetParent:getY() + tilesetParent:getHeight(), tilesetParent:getWidth(), tilesetScrollHoriz:getHeight())
    else
      if tilesetScrollHoriz:isVisible() == true then
        tilesetParent:setHeight(tilesetParent:getHeight() + tilesetScrollHoriz:getHeight())
        if tileset ~= nil then tileset:setX(0); end
        tilesetScrollHoriz:setHeight(0); tilesetScrollHoriz:hide(); tilesetScrollHoriz:setValue(0)
      end
    end

    if tileset ~= nil and tileset:getHeight() > tilesetParent:getHeight() then
      if tilesetScrollVert:isVisible() == false then
        tilesetScrollVert:setWidth(15)
        tilesetParent:setWidth(tilesetParent:getWidth() - tilesetScrollVert:getWidth())
        tilesetScrollVert:show()
      end
      tilesetScrollVert:setMax(tileset:getHeight() - tilesetParent:getHeight())
      tilesetScrollVert:setRect(tilesetParent:getX() + tilesetParent:getWidth(), tilesetParent:getY(), tilesetScrollVert:getWidth(), tilesetParent:getHeight())
    else
      if tilesetScrollVert:isVisible() then
        tilesetParent:setWidth(tilesetParent:getWidth() + tilesetScrollVert:getWidth())
        if tileset ~= nil then tileset:setY(0); end
        tilesetScrollVert:setWidth(0); tilesetScrollVert:hide(); tilesetScrollVert:setValue(0)
      end
    end

    layerScroll:setRect(tilesetParent:getX(), tilesetParent:getY() + tilesetParent:getHeight() + tilesetScrollHoriz:getHeight() + 5, 60, 15)
    layerText:setRect(layerScroll:getX() + layerScroll:getWidth() + 5, layerScroll:getY(), layerText:getTextWidth(), layerScroll:getHeight())

    propertiesParent:setX(tilesetParent:getX() + tilesetParent:getWidth() + tilesetScrollVert:getWidth() + 5); propertiesParent:setHeight(tilesetParent:getHeight() + tilesetScrollHoriz:getHeight() - 18 - 30)
    propertiesText:setX(propertiesParent:getX())

    editButton:setX(propertiesParent:getX()); editButton:setY(propertiesParent:getY() + propertiesParent:getHeight() + 5)
    closeButton:setX(propertiesParent:getX()); closeButton:setY(editButton:getY() + editButton:getHeight() + 5)
    undoButton:setX(closeButton:getX() - 80 - 5); undoButton:setY(closeButton:getY())

    menu:setMovableBoundaries(0-menu:getWidth()+40, -5, 640+menu:getWidth()-40, 480+menu:getHeight()-40)
  end
end

function onScrollBarChanged(elem, lval)
  if elem == tilesetScrollHoriz and tileset ~= nil then
    tileset:setX(tileset:getX() + (lval - elem:getValue()))
  elseif elem == tilesetScrollVert and tileset ~= nil then
    tileset:setY(tileset:getY() + (lval - elem:getValue()))
  elseif elem == layerScroll then
    layerText:setText("Layer: " .. tostring(elem:getValue()))
  end
end

function onButtonPressed(button)
  if button == closeButton then
    script:remove("Scripts/editors/tileeditor/placer.lua")
    script:remove(script:thisName())
  elseif button == editButton and tilesetPKey ~= nil then
    game:loadScripts("Scripts/editors/tileeditor/populate.lua")
    game:setTimeout(5, "editTileset" .. tostring(tilesetPKey))
  elseif button == undoButton then
    script:triggerFunction("undo", "Scripts/editors/tileeditor/placer.lua")
  end
end

function onKeyDown(key)
  if key == "LCTRL" or key == "RCTRL" then ctrlDown = true; end
end

function onKeyUp(key)
  if key == "Z" and ctrlDown ~= nil then
    onButtonPressed(undoButton)
  end
  if key == "LCTRL" or key == "RCTRL" then ctrlDown = nil; end
end

function onLeftMouseDown(mID)
  local elem = mouse:getElement(mID)
  -- If our mouse pressed down on the tileset
  if elem ~= nil and tileset ~= nil and (elem == tileset or elem:getParent() == tileset) then
    elem = tileset
    local x,y = getAbsolutePosition(elem)

    tilesetSqPos.begins = { x = math.floor((mouse:getX(mID, true) - x)/16)*16, y = math.floor((mouse:getY(mID, true) - y)/16)*16 }
    -- NOTE: +16 if > than ends
    tilesetSqPos.mID = mID
  end
end

function onLeftMouseUp(mID)
  if tilesetSqPos.mID ~= nil and tilesetSqPos.mID == mID then
    if tilesetSq ~= nil then setClipboard(tilesetSq:getRect()); end

    tilesetSqPos.begins = { x = nil, y = nil }
    tilesetSqPos.mID = nil
  end
end

function onMouseMoved(mID)
  local elem = mouse:getElement(mID)
  -- If our mouse moved over the tileset
  if elem ~= nil and tileset ~= nil and (elem == tileset or elem:getParent() == tileset) then
    elem = tileset
    local x,y = getAbsolutePosition(elem)

    tilesetSqPos.ends = { x = math.floor((mouse:getX(mID, true) - x)/16)*16 + 16, y = math.floor((mouse:getY(mID, true) - y)/16)*16 + 16 }
    -- NOTE: -16 if < than begins

    local x = tilesetSqPos.begins.x or tilesetSqPos.ends.x-16
    local w = tilesetSqPos.begins.x ~= nil and tilesetSqPos.ends.x-tilesetSqPos.begins.x or 16
    if tilesetSqPos.begins.x ~= nil and tilesetSqPos.begins.x >= tilesetSqPos.ends.x then x = x+16; w = w-32; end

    local y = tilesetSqPos.begins.y or tilesetSqPos.ends.y-16
    local h = tilesetSqPos.begins.y ~= nil and tilesetSqPos.ends.y-tilesetSqPos.begins.y or 16
    if tilesetSqPos.begins.y ~= nil and tilesetSqPos.begins.y >= tilesetSqPos.ends.y then y = y+16; h = h-32; end

    tilesetSq:setRect(x, y, w, h)
  end
end

function onTimeout(ID, time)
  if ID:find("editTileset") == 1 then
    if game:getScript("Scripts/editors/tileeditor/populate.lua") ~= nil then
      script:triggerFunction("loadTileset", "Scripts/editors/tileeditor/populate.lua", ID:sub(12)+0)
    else
      game:setTimeout(time, ID)
    end
  elseif ID == "placer" then
    if game:getScript("Scripts/editors/tileeditor/placer.lua") ~= nil then
      script:triggerFunction("setTileset", "Scripts/editors/tileeditor/placer.lua", tileset)
    else
      game:setTimeout(time, ID)
    end
  end
end

-- Received tileset information from the server
function onSQLReceived(res, ID)
  if ID == "loadTileset" then
    local properties = {}
    for i=1, #res["Type"] do
      properties[res["Type"][i]] = res["Value"][i] -- Put into a form that looks like e.g: properties["Image"] = "tileset.png"
    end
    for i,v in pairs(properties) do
      if i ~= "Name" then
        propertiesParent:addItem(i .. ": " .. v)
      end
    end
    if properties["Name"] ~= nil then
      menu:setText("Editing: " .. properties["Name"])
    end
    if properties["Image"] ~= nil then
      setTileset(properties["Image"])
      game:loadScripts("Scripts/editors/tileeditor/placer.lua")
      game:setTimeout(5, "placer")
    end
    if properties["Crop"] ~= nil and tileset ~= nil then
      local crop = operations:getTokens(properties["Crop"], ",")
      tileset:crop(crop[0], crop[1], crop[2], crop[3]); tileset:setWidth(crop[2]); tileset:setHeight(crop[3])
      onElementResize(menu)
    end
  end
end