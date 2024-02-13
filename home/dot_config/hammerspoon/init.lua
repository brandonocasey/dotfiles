local hyper = hs.hotkey.modal.new({}, nil)

-- See https://github.com/Hammerspoon/hammerspoon/issues/1984
local doKeyStroke = function(modifiers, character)
  if type(modifiers) == 'table' then
    local event = hs.eventtap.event

    for _, modifier in pairs(modifiers) do
      event.newKeyEvent(modifier, true):post()
    end

    event.newKeyEvent(character, true):post()
    event.newKeyEvent(character, false):post()

    for i = #modifiers, 1, -1 do
      event.newKeyEvent(modifiers[i], false):post()
    end
  end
end
hyper.pressed = function()
  hyper.triggered = false
  hyper:enter()
end

hyper.released = function()
  hyper:exit()
  if not hyper.triggered then
    hs.eventtap.keyStroke({}, 'ESCAPE')
  end
end

local rectangleKeys = { 'left', 'right', 'up', 'down', 'v', '1', '2', '3', '4' }

for i = 1, #rectangleKeys do
  local key = rectangleKeys[i]

  hyper:bind({}, key, nil, function()
    doKeyStroke({ 'cmd', 'alt', 'shift', 'ctrl' }, key)
    hyper.triggered = true
  end)
end

hyper:bind({}, "l", function()
  hs.caffeinate.startScreensaver()
  hyper.triggered = true
end)


-- Set the key you want to be HYPER to F19 in karabiner or keyboard
-- Bind the Hyper key to the hammerspoon modal
hs.hotkey.bind({}, 'F19', hyper.pressed, hyper.released)

hs.pathwatcher.new(os.getenv("HOME") .. "/.config/hammerspoon/", hs.reload):start()
hs.alert.show("Config loaded")
