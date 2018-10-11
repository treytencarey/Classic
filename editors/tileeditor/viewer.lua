--[[
--   The viewer to see which tilesets we can use or edit.
--]]

function onCreated()
  menu = CreateWindow("Tile Editor Menu", 0, 0, 235, 275)
  menu:setMinWidth(menu:getWidth()); menu:setMaxWidth(menu:getWidth()); menu:setMinHeight(menu:getHeight())
  menu:setMovable()
  menu:setResizable()
  menu:center()

  mouseDownElem = nil

  closeButton = CreateButton("Close", menu:getWidth() - 80 - 5, 0, 80, 25); menu:addElement(closeButton)

  parent = CreateListBox(5, 25, menu:getWidth() - 10, 0)
  scrollBar = CreateScrollBar(false, menu:getWidth() - 5 - 25, parent:getY(), 25, 0)
  menu:addElement(parent); menu:addElement(scrollBar)
  onElementResize(menu)

  tilesets = {}
  refresh()
end

function refresh(initial)
  if initial == nil then initial = true; end
  if initial then -- Initial refresh; receive information from the server
    local children = parent:getElements() or {}
    for i,child in pairs(children) do
      child:remove()
    end
    scrollBar:setValue(0)

    getSQL(
      "SELECT T.PKey AS PKey, T.Name, " ..
      "( SELECT P.Value " ..
    "   FROM Properties P " ..
    "   WHERE P.TilesetPKey = T.PKey AND P.Type = 'Crop' " ..
     ") AS Crop, " ..
     "( SELECT P.Value " ..
     "  FROM Properties P " ..
     "  WHERE P.TilesetPKey = T.PKey AND P.Type = 'Image' " ..
     ") AS Image " ..
      "FROM Tilesets T, Properties P " ..
      "GROUP BY T.PKey "
    , "viewTilesets")
  else -- Already got information from the server. Refresh our elements to display the info.
    local createTileset = { Name = "Create New", Crop = "0,0,0,0", Image = "" }
    table.insert(tilesets, createTileset)

    for i,tileset in pairs(tilesets) do
      local img = CreateImage("Tilesets/" .. tileset["Image"], 5, 5*i + 100*(i-1), 100, 100)
      local crop = operations:getTokens(tileset["Crop"], ",")
      img:crop(crop[0], crop[1], crop[2], crop[3]); img:setColor(100,100,100,255)
      local name = CreateText(tileset["Name"], 0, 0, img:getWidth(), img:getHeight())
      name:setColor(255,255,255,255); name:setTextAlignment("center", "center")
      img:addElement(name)

      local editButton = nil
      local deleteButton = nil

      local elems = {}
      if i < #tilesets then
        editButton = CreateButton("Edit", img:getX() + img:getWidth() + 10, img:getY() + 5, 80, img:getHeight()/2 - 10)
        deleteButton = CreateButton("Delete", editButton:getX(), editButton:getY() + editButton:getHeight() + 5, editButton:getWidth(), editButton:getHeight())
        elems["EditButton"] = editButton; elems["DeleteButton"] = deleteButton
      end

      elems["Image"] = img
      for i,elem in pairs(elems) do parent:addElement(elem); end

      tilesets[i]["elems"] = elems
      onElementResize(menu)
    end    
  end
end

function removeTileset(PKey)
  -- Multiple deletes could be changed to an SQL trigger in the future. Doesn't really matter right now.
  server:getSQL("Databases/tilesets.db",
    "DELETE FROM Properties " ..
    "WHERE TilesetPKey='" .. PKey .. "'; " ..
    "DELETE FROM Tilesets " ..
    "WHERE PKey='" .. PKey .. "'; "
  )
  refresh()
end

-- Tilesets stored in this location. Makes it easier if we ever change stored location
function getSQL(sql, ID)
  server:getSQL("Databases/tilesets.db", sql, ID)
end

function onButtonPressed(button)
  if button == closeButton then
    game:loadScripts("Scripts/editors/tileeditor/viewerButton.lua")
    script:remove(script:thisName())
    return
  end

  -- Check if a tileset edit/delete button is pressed, and get which tileset it was
  for i,tileset in pairs(tilesets) do
    if button == tileset["elems"]["EditButton"] then
      game:loadScripts("Scripts/editors/tileeditor/populate.lua")
      game:setTimeout(5, "editTileset" .. tileset["PKey"])
      return
    elseif button == tileset["elems"]["DeleteButton"] then
      removeTileset(tileset["PKey"])
    end
  end
end

function onElementResize(elem)
  if elem == menu then
    parent:setHeight(menu:getHeight() - parent:getY() - 35)
    closeButton:setY(parent:getY() + parent:getHeight() + 5)

    -- Show/hide scrollbar and set it's max value to scroll.
    if tilesets ~= nil and tilesets[#tilesets] ~= nil and tilesets[#tilesets]["elems"] ~= nil and tilesets[#tilesets]["elems"]["Image"] ~= nil then
      local img = tilesets[#tilesets]["elems"]["Image"]
      local firstImg = tilesets[1]["elems"]["Image"]
      local sz = img:getY() + img:getHeight() - firstImg:getY() + 10

      if sz > parent:getHeight() then
        parent:setWidth(menu:getWidth() - 10 - scrollBar:getWidth()); scrollBar:setHeight(parent:getHeight()); scrollBar:show()
        scrollBar:setMax(sz - parent:getHeight())
      else
        parent:setWidth(menu:getWidth() - 10); scrollBar:hide(); scrollBar:setValue(0)
        if firstImg:getY() < 5 then
          local children = parent:getElements() or {}
          local change = firstImg:getY()*(-1) + 5
          for i,child in pairs(children) do child:setY(child:getY() + change); end
        end
      end
    end

    menu:setMovableBoundaries(0-menu:getWidth()+40, -5, 640+menu:getWidth()-40, 480+menu:getHeight()-40)
  end
end

function onScrollBarChanged(elem, lastVal)
  if elem == scrollBar then
    local change = lastVal - elem:getValue()
    local children = parent:getElements()
    for i,child in pairs(children) do child:setY(child:getY() + change); end
  end
end

function onSQLReceived(res, ID)
  -- Received our viewable list of tilesets
  if ID == "viewTilesets" then
    tilesets = {}
    -- put into a form that looks like e.g: tilesets[2]["Crop"] = "0,0,144,96"
    for i,tbl in pairs(res) do
      for n,val in pairs(tbl) do
        if tilesets[n] == nil then tilesets[n] = {}; end
        tilesets[n][i] = val
      end
    end
    refresh(false)
  end
end

-- Check if we clicked on any element located in the menu. Used for making the scrollbar always focused for easier scrolling access
function isScrollFocus(clickedElem)
  if clickedElem == nil then return false; end

  while clickedElem ~= clickedElem:getParent() do
    clickedElem = clickedElem:getParent()
  end

  if clickedElem == menu then return true; end
  return false
end

function onLeftMouseDown(mID)
  mouseDownElem = { mID = mID, elem = mouse:getElement(mID) }
end

function onLeftMouseUp(mID)
  local elem = mouse:getElement(mID)

  -- The tileset name text's parent is the image, and the image's parent is the listbox.
  if elem ~= nil and mouseDownElem.elem ~= nil and mouseDownElem.elem == elem and elem:getParent():getParent() == parent then
    for i,tileset in pairs(tilesets) do
      if elem:getParent() == tileset["elems"]["Image"] then
        if i == #tilesets then
          game:loadScripts("Scripts/editors/tileeditor/populate.lua")
          game:setTimeout(5, "editTileset0")
        else
          game:loadScripts("Scripts/editors/tileeditor/editor.lua")
          game:setTimeout(5, "openTileset" .. tileset["PKey"])
        end
        break
      end
    end
  end

  -- If we clicked on any element in the menu, set the scrollbar's focus.
  if mouseDownElem ~= nil and mouseDownElem.mID == mID then
    if elem ~= nil and elem == menu or elem:getParent() == menu or elem:getParent():getParent() == menu then
      if mouseDownElem ~= nil and mouseDownElem.elem == elem and elem:getElementType() == "CreateButton" then -- Trigger the button's press. setFocused() overrides this otherwise
        onButtonPressed(elem)
      end
      scrollBar:setFocused()
    end
    mouseDownElem = nil
  end
end

function onTimeout(ID, time)
  if ID:find("editTileset") == 1 then
    if game:getScript("Scripts/editors/tileeditor/populate.lua") ~= nil then
      script:triggerFunction("loadTileset", "Scripts/editors/tileeditor/populate.lua", ID:sub(12)+0)
    else
      game:setTimeout(time, ID)
    end
  elseif ID:find("openTileset") == 1 then
    if game:getScript("Scripts/editors/tileeditor/editor.lua") ~= nil then
      script:triggerFunction("loadTileset", "Scripts/editors/tileeditor/editor.lua", ID:sub(12)+0)
    else
      game:setTimeout(time, ID)
    end
  end
end