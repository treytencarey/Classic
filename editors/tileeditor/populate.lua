--[[
--   The tileset editor that allows us to change it's image or properties
--]]

function onCreated()
  menu = CreateWindow("Editing Tileset", 0, 0, 0, 275); menu:setMovable()

  fpEditBox = CreateEditBox(5, 25, 80, 25); menu:addElement(fpEditBox)
  browseButton = CreateButton("Browse", 0, 0); menu:addElement(browseButton); browseButton:setScaled(false)
  browsing = nil

  tileset = nil
  tilesetPKey = nil
  crop = nil
  tilesetParent = CreateListBox(0,0,0,0); menu:addElement(tilesetParent); tilesetParent:setScaled(false)
  tilesetScrollHoriz = CreateScrollBar(true, 0,0,0,0); menu:addElement(tilesetScrollHoriz)
  tilesetScrollVert = CreateScrollBar(false, 0,0,0,0); menu:addElement(tilesetScrollVert)

  propertiesText = CreateText("Properties:"); propertiesText:setScaled(false); menu:addElement(propertiesText); propertiesText:setTextAlignment("center", "center")
  propertiesParent = CreateListBox(0,0,0,0); menu:addElement(propertiesParent); propertiesParent:setScaled(false)
  propertiesList = {}
  modalChildren = nil

  createButton = CreateButton("New/Edit",0,0,0,0); menu:addElement(createButton); createButton:setScaled(false)
  removeButton = CreateButton("Remove",0,0,0,0); menu:addElement(removeButton); removeButton:setScaled(false)

  doneButton = CreateButton("Close",0,0,0,0); menu:addElement(doneButton); doneButton:setScaled(false)

  onWindowResize()
  menu:center()
end

-- Get tileset data from the server
function loadTileset(PKey)
  if PKey == 0 then
    server:getSQL( "Databases/tilesets.db",
      "INSERT INTO Tilesets ( Name ) VALUES ( 'New Tileset' ); " ..
      "SELECT MAX(PKey) AS PKey FROM Tilesets",
      "createTileset"
    )
    return
  end

  server:getSQL( "Databases/tilesets.db",
    "SELECT Type, Value " ..
    "FROM Properties " ..
    "WHERE TilesetPKey = '" .. tostring(PKey) .. "' " ..
    "UNION " ..
    "SELECT 'Name', Name " ..
    "FROM Tilesets " ..
    "WHERE PKey = '" .. tostring(PKey) .. "'",
    "loadTileset"
  )
  tilesetPKey = PKey
  propertiesParent:clear(); fpEditBox:setText(""); setTileset(nil); propertiesList = {}
  setCropPreview(0,0,0,0)
end

-- Displays the tileset we're using
function setTileset(path, userSet)
  if crop ~= nil then tileset:removeElement(crop); end
  if tileset ~= nil then tileset:remove(); end
  if path ~= nil then
    tileset = CreateImage("Tilesets/" .. path, 0, 0); tileset:setScaled(false)
    tilesetParent:addElement(tileset)
    if crop ~= nil then tileset:addElement(crop); end
  end

  tilesetScrollHoriz:setValue(0); tilesetScrollVert:setValue(0);
  onWindowResize()

  -- If the user changed the tileset (AKA the path was not auto-set by selection)
  if userSet == true then addProperty("Image", path); end
end

-- Displays if we've cropped the tileset
function setCropPreview(x, y, w, h)
  if crop ~= nil then crop:remove(); crop = nil; end
  if w <= 0 or h <= 0 then return; end

  crop = CreateImage("GLOBAL/pixel.png", x, y, w, h); crop:setScaled(false)
  crop:setColor(255,0,0,100)
  if tileset ~= nil then tileset:addElement(crop); end
end

-- A change was made to the tileset or it's properties. Refresh other scripts that use it.
function refreshView(property)
  -- Refresh the viewer
  if property == nil or property == "Name" or property == "Image" or property == "Crop" then
    script:triggerFunction("refresh", "Scripts/editors/tileeditor/viewer.lua")
  end
  -- Refresh the editor if we are changing properties on the same tileset
  if tilesetPKey ~= nil and script:getValue("tilesetPKey", "Scripts/editors/tileeditor/editor.lua") == tilesetPKey then
    script:triggerFunction("refresh", "Scripts/editors/tileeditor/editor.lua")
  end
end

-- Remove tileset property from the server and refresh
function removeProperty(property, refresh)
  if tilesetPKey == nil then return; end
  if refresh == nil then refresh = true; end

  server:getSQL("Databases/tilesets.db",
    "DELETE FROM Properties " ..
    "WHERE Type='" .. property .. "' AND TilesetPKey='" .. tostring(tilesetPKey) .. "'",
    "checkpropertyremove")
  loadTileset(tilesetPKey)
  if refresh == true then refreshView(property); end
end

-- Add new property to the server and refresh
function addProperty(property, propertyStr)
  if tilesetPKey == nil then return; end

  if property == 'Name' then
    server:getSQL("Databases/tilesets.db",
      "UPDATE Tilesets " ..
      "SET Name='" .. propertyStr .. "' " ..
      "WHERE PKey='" .. tostring(tilesetPKey) .. "'")
  else
    server:getSQL("Databases/tilesets.db",
      "INSERT INTO Properties ( TilesetPKey, Type, Value ) " ..
      "VALUES (" .. tostring(tilesetPKey) .. ", '" .. property .. "', '" .. propertyStr .. "')",
      "checkpropertyadd")
  end
  loadTileset(tilesetPKey)
  refreshView(property)
end

function onWindowResize()
  browseButton:setRect(fpEditBox:getX(false) + fpEditBox:getWidth(false), fpEditBox:getY(false), 60, fpEditBox:getHeight(false))

  local scaleX,scaleY = game:getWindowScale()
  local tilesetParentW = fpEditBox:getWidth(false) + browseButton:getWidth(false)
  local tilesetParentH = menu:getHeight(false) - fpEditBox:getY(false) - fpEditBox:getHeight(false) - 40*scaleY

  if tileset ~= nil and tileset:getHeight(false) > tilesetParentH then
    tilesetParentW = tilesetParentW - 15*scaleX
    tilesetScrollVert:setRect(fpEditBox:getX() + tilesetParentW/scaleX, fpEditBox:getY() + fpEditBox:getHeight() + 5, 15, tilesetParentH/scaleY); tilesetScrollVert:show()
  else
    tilesetScrollVert:setRect(0,0,0,0); tilesetScrollVert:setValue(0); tilesetScrollVert:hide()
  end
  if tileset ~= nil and tileset:getWidth(false) > tilesetParentW then
    tilesetParentH = tilesetParentH - 15*scaleY
    tilesetScrollHoriz:setRect(fpEditBox:getX(), fpEditBox:getY() + fpEditBox:getHeight() + 5 + tilesetParentH/scaleY, tilesetParentW/scaleX, 15); tilesetScrollHoriz:show()
  else
    tilesetScrollHoriz:setRect(0,0,0,0); tilesetScrollHoriz:setValue(0); tilesetScrollHoriz:hide()
  end

  tilesetParent:setRect(fpEditBox:getX(false), fpEditBox:getY(false) + fpEditBox:getHeight(false) + 5*scaleY, tilesetParentW, tilesetParentH)
  if tileset ~= nil then
    if tilesetScrollHoriz:isVisible() then
      tilesetScrollHoriz:setMax(tileset:getWidth(false) - tilesetParent:getWidth(false))
    end
    if tilesetScrollVert:isVisible() then
      tilesetScrollVert:setMax(tileset:getHeight(false) - tilesetParent:getHeight(false))
    end
  end
  propertiesParent:setRect(tilesetParent:getX(false) + tilesetParent:getWidth(false) + tilesetScrollVert:getWidth(false) + 5*scaleX, tilesetParent:getY(false), tilesetParent:getWidth(false) + tilesetScrollVert:getWidth(false), tilesetParent:getHeight(false) + tilesetScrollHoriz:getHeight(false) - 30*scaleY)
  createButton:setRect(propertiesParent:getX(false), propertiesParent:getY(false) + propertiesParent:getHeight(false) + 5*scaleY, (tilesetParent:getWidth(false)+tilesetScrollVert:getWidth(false)-4*scaleX)/2, 25*scaleY)
  removeButton:setRect(createButton:getX(false) + createButton:getWidth(false) + 5*scaleX, createButton:getY(false), createButton:getWidth(false), createButton:getHeight(false))
  propertiesText:setRect(propertiesParent:getX(false), fpEditBox:getY(false), propertiesParent:getWidth(false), fpEditBox:getHeight(false))

  doneButton:setRect(propertiesParent:getX(false), menu:getHeight(false)-30*scaleY, propertiesParent:getWidth(false), 25*scaleY)

  menu:setWidth((propertiesParent:getX() + propertiesParent:getWidth(true))/scaleX + 5)
  menu:setMovableBoundaries(0-menu:getWidth()+40, -5, 640+menu:getWidth()-40, 480+menu:getHeight()-40)
end

function onOpenFileName(path)
  -- Pressed the browse button and selected a new tileset
  if path ~= "" and browsing == true then
    path = string.match(path, "Worlds/" .. self:getWorld() .. "/Tilesets/(.*)") -- Check that the tileset is probably located in the Tilesets/ folder
    if path ~= nil and operations:fileExists("Tilesets/" .. path) then -- Make sure the tileset was actually located in the Tilesets/ folder
      fpEditBox:setText(path)
      setTileset(path, true)
    else
      game:addError("Path is not located in the Worlds/" .. self:getWorld() .. "/Tilesets/* directory.")
    end
  end
end

function onTimeout(ID, time)
  if ID == "modal" then
    -- Loaded modal script for properties. Add elements to it.
    if game:getScript("GLOBAL/Scripts/modal.lua") ~= nil then
      modalChildren = { { element = CreateEditBox(5, 25, 245/2+1, 25) }, { element = CreateEditBox(5+245/2+5/2+1, 25, 245/2+1, 25) } }

      local sel = propertiesParent:getSelected()+1
      if sel > 0 then modalChildren[1].element:setText(propertiesList[sel][1]); modalChildren[2].element:setText(propertiesList[sel][2]); end

      script:triggerFunction("onCreatedArgs", "GLOBAL/Scripts/modal.lua", script:thisName(), "Set Property", "onModalButtonPressed", "", { elements = modalChildren, editBox = { rendered = false } } )
    else
      game:setTimeout(time, ID)
    end
    return
  end
end

-- The changing properties modal does a callback to this function
function onModalButtonPressed(txt)
  if txt == "Done" and modalChildren ~= nil then
    local property = modalChildren[1].element:getText()
    local propertyStr = modalChildren[2].element:getText()
    if property:len() > 0 and propertyStr:len() > 0 then
      addProperty(property, propertyStr)
      script:remove("GLOBAL/Scripts/modal.lua")
    end
  end
end

function onButtonPressed(button)
  if button == browseButton then
    browsing = true
    game:getOpenFileName()
  elseif button == createButton then
    game:loadScripts("GLOBAL/Scripts/modal.lua")
    game:setTimeout(5, "modal")
  elseif button == doneButton then
    script:remove(script:thisName())
  elseif button == removeButton and propertiesParent:getSelected() >= 0 then
    removeProperty(propertiesList[propertiesParent:getSelected()+1][1])
  end
end

function onElementFocusLost(elem)
  -- We were clicked on the tileset location editbox, but now we clicked off of it. Load new tileset
  if mouse:getElement(browseButton) == nil and elem == fpEditBox then
    setTileset(elem:getText(), true)
  end
end

-- Image downloaded. Make sure our scrollbars update
function onCommand(cmd)
  if cmd == "writeFile" .. tileset:getImage() then
    onWindowResize()
  end
end

function onSQLReceived(res, ID)
  if ID:find("checkproperty") == 1 then -- Make sure our property was successfully changed/added to the server
    if res["DBERROR"] ~= nil and res["DBERROR"][1] ~= nil then
      game:addError("Could not " .. ID:sub(14) .. " property. Error: " .. res["DBERROR"][1])
    end
  elseif ID == "loadTileset" then -- Tileset information received from the server
    local properties = {}
    for i=1, #res["Type"] do
      properties[res["Type"][i]] = res["Value"][i] -- Put into a form that looks like e.g: properties["Image"] = "tileset.png"
    end
    for i,v in pairs(properties) do
      if i == "Image" then
        setTileset(v); fpEditBox:setText(v)
      else
        propertiesParent:addItem(i .. ": " .. v)
        table.insert(propertiesList, { i, v })
      end
    end
    if properties["Crop"] ~= nil and tileset ~= nil then
      local crop = operations:getTokens(properties["Crop"], ",")
      setCropPreview(crop[0]+0, crop[1]+0, crop[2]+0, crop[3]+0)
    end
  elseif ID == "createTileset" then -- Created a new tileset successfully
    if res["PKey"] ~= nil and res["PKey"][1] ~= nil then
      loadTileset(res["PKey"][1]+0); refreshView()
    end
  end
end

function onScrollBarChanged(elem, lastVal)
  local change = lastVal-elem:getValue()
  -- Move the tileset if we're scrolling
  if elem == tilesetScrollHoriz then
    tileset:setX(tileset:getX() + change)
  elseif elem == tilesetScrollVert then
    tileset:setY(tileset:getY() + change)
  end
end