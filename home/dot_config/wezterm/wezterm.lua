-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- https://wezfurlong.org/wezterm/#features

-- TODO: monitor this one https://github.com/wez/wezterm/issues/549
-- which will allow dragging around tabs, the one feature that I think is missing
-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

local function get_system_appearance()
  local appearance = 'Dark'

  if (wezterm.gui) then
    appearance = wezterm.gui.get_appearance()
  end
  return appearance
end


local function color_scheme_for_system_theme()
  --if get_system_appearance():find 'Dark' then
  return 'OneDark (base16)'
  --else
  -- return 'One Light (base16)'
  --end
end

-- This is where you actually apply your config choices
local font_size = 17
config.line_height = 1
--config.line_height = 0.9 for iosevka
local font = wezterm.font_with_fallback({
  { family = 'PragmataPro Mono', harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' } },
  { family = 'IosevkaTerm Nerd Font Propo', harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' } },
  { family = 'Inconsolata Nerd Font Propo' },
  { family = 'JetBrains Mono' },
})

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.use_fancy_tab_bar = true

config.font = font
config.font_size = font_size
config.color_scheme = color_scheme_for_system_theme()

--config.colors = {
--  background = 'black',
--  cursor_bg = 'orange',
--  cursor_fg = 'orange',
--  cursor_border = 'orange'
--}
--
config.scrollback_lines = 10000
--config.enable_scroll_bar = true

config.window_frame = {
  -- The font used in the tab bar.
  -- Roboto Bold is the default; this font is bundled
  -- with wezterm.
  -- Whatever font is selected here, it will have the
  -- main font setting appended to it to pick up any
  -- fallback fonts you may have used there.
  font = font,

  -- The size of the font in the tab bar.
  -- Default to 10.0 on Windows but 12.0 on other systems
  font_size = font_size - 2
}
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.7,
}
config.window_padding = {
  left = '0.25cell',
  right = '0.25cell',
  top = '0.25cell',
  bottom = '0.25cell',
}

config.keys = {
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = wezterm.action { SendString = "\x1bOH" },
  },
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = wezterm.action { SendString = "\x1bOF" },
  },
}

-- 4 mouse clicks to select between prompts
config.mouse_bindings = {
  {
    event = { Down = { streak = 4, button = 'Left' } },
    action = wezterm.action.SelectTextAtMouseCursor 'SemanticZone',
    mods = 'NONE',
  },
}

local wsl_domains = wezterm.default_wsl_domains()

if next(wsl_domains) ~= nil then
  config.default_domain = wsl_domains[1].name
  table.insert(config.keys, {
    key = 'v',
    mods = 'CTRL',
    action = wezterm.action.PasteFrom 'Clipboard'
  })
end
-- and finally, return the configuration to wezterm
return config
