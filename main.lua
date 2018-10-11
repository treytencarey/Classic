function onCreated()
  if game:isMobile() then
    game:loadScripts("GLOBAL/Scripts/touch/touch-lrud.lua")
  end
  game:loadScripts("Scripts/player.lua")
  game:loadScripts("Scripts/world.lua")
  game:loadScripts("Scripts/editors/tileeditor/viewerButton.lua")
  game:loadScripts("GLOBAL/Scripts/main.lua")
end