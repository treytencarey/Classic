--[[
--   The button on the screen that opens the tileset viewer
--]]

function onCreated()
  button = CreateButton("", 640-10-60-10-60, 10, 60, 60)
  button:setImage("GUIs/editors/tileeditor/viewerButton.png")
  button:setScaleImage(true)
end

function onButtonPressed(elem)
  if elem == button then
    game:loadScripts("Scripts/editors/tileeditor/viewer.lua")
    script:remove(script:thisName())
    return
  end
end