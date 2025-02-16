#!/usr/bin/env bash

# use https://github.com/catilac/plistwatch to automate

export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
export MANPATH="$MANPATH:./man:/usr/share/man:/usr/local/man:/usr/local/share/man"
cmd_exists() {
  if command -v "$1" 2>/dev/null 1>/dev/null; then
    return 0
  fi

  return 1
}

# prevent annoying "Login Item" Notifications
sudo sfltool resetbtm

##
# setup computer name
##
sudo scutil --set HostName bcasey-macbook
sudo scutil --set LocalHostName bcasey-macbook
sudo scutil --set ComputerName bcasey-macbook


echo "Writings settings"

##
# dock
##

# Set to the left
defaults write com.apple.dock "orientation" -string "left"

# Set dock icon size
defaults write com.apple.dock "tilesize" -int "75"

# autohide
defaults write com.apple.dock "autohide" -bool "true"

# autohide instantly
defaults write com.apple.dock "autohide-time-modifier" -float "0"
defaults write com.apple.dock "autohide-delay" -float "0"

# Do not keep recently used apps
defaults write com.apple.dock "show-recents" -bool "false"

# Use the fastest application open/close to dock animation
defaults write com.apple.dock "mineffect" -string "scale"

# disable dock bouncing
defaults write com.apple.dock "no-bouncing" -bool "true"

# disable animation when launching from the dock
defaults write com.apple.dock "launchanim" -bool "false"

##
# Finder
##

# Settings > advanced > show all filename extensions
defaults write .GlobalPreferences AppleShowAllExtensions -bool true

# Settings > advanced > show warning before changing an extension: false
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# View > as list
defaults write com.apple.finder FXPreferredViewStyle -string "nlsv"

# View > show path bar
defaults write com.apple.finder ShowPathbar -bool true
# View > show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show all hidden files (cmd+shift+.)
defaults write com.apple.finder AppleShowAllFiles true

# Search in the current folder, not the entire mac
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"

# disable toolbar rollover delay
defaults write NSGlobalDomain "NSToolbarTitleViewRolloverDelay" -float "0"

# Show item counts at the bottom of finder
defaults write com.apple.finder "ShowStatusBar" -bool "true"

# Start save dialog expanded
defaults write NSGlobalDomain "NSNavPanelExpandedStateForSaveMode" -bool "true"
defaults write NSGlobalDomain "NSNavPanelExpandedStateForSaveMode2" -bool "true"

# Add Quit menu item
defaults write com.apple.finder "QuitMenuItem" -bool "true"

# Disable animation opening finder info
defaults write com.apple.finder "DisableAllAnimations" -bool "true"

# close tags in sidebar
defaults write "com.apple.finder" "SidebarTagsSctionDisclosedState" '0'

##
# Activity monitor
##
# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

##
# Keyboard
##

# Disable press and hold
defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool "false"

# Faster key repeat
defaults write NSGlobalDomain "InitialKeyRepeat" -int 10 # normal minimum is 15 (225 ms)
defaults write NSGlobalDomain "KeyRepeat" -int "1" # normal minimum is 2 (30 ms)<Paste>

##
# mouse
##


##
# Global
##

# disable animations for opening and closing windows and popovers
defaults write NSGlobalDomain "NSAutomaticWindowAnimationsEnabled" -bool "false"

# showing and hiding sheets, resizing preference windows, zooming windows
# float 0 doesn't work
defaults write NSGlobalDomain "NSWindowResizeTime" -float "0.001"

# opening and closing Quick Look windows
defaults write NSGlobalDomain "QLPanelAnimationDuration" -float "0"


# smooth scrolling
defaults write -g NSScrollAnimationEnabled -bool false


# rubberband scrolling (doesn't affect web views)
defaults write -g NSScrollViewRubberbanding -bool false

# resizing windows before and after showing the version browser
# also disabled by NSWindowResizeTime -float 0.001
defaults write -g NSDocumentRevisionsWindowTransformAnimation -bool false

# showing a toolbar or menu bar in full screen
defaults write -g NSToolbarFullScreenAnimationDuration -float 0

# scrolling column views
defaults write -g NSBrowserColumnAnimationSpeedMultiplier -float 0


# showing and hiding Mission Control, command+numbers
defaults write com.apple.dock expose-animation-duration -float 0

# showing and hiding Launchpad
defaults write com.apple.dock springboard-show-duration -float 0
defaults write com.apple.dock springboard-hide-duration -float 0

# changing pages in Launchpad
defaults write com.apple.dock springboard-page-duration -float 0

# sending messages and opening windows for replies
defaults write com.apple.Mail DisableSendAnimations -bool true
defaults write com.apple.Mail DisableReplyAnimations -bool true

# disable mouse acceleration
defaults write .GlobalPreferences com.apple.mouse.scaling -1
defaults write .GlobalPreferences com.apple.scrollwheel.scaling -1

# prevent dsstore
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
defaults write com.apple.desktopservices DSDontWriteUSBStores true

# always show scroll bars
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Menu bar: show remaining battery percentage; hide time
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write com.apple.menuextra.battery ShowTime -string "NO"
# Menu bar: show remaining battery percentage (with Big Sur or Monterey)
defaults write com.apple.controlcenter.plist BatteryShowPercentage -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode  -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Bottom right screen corner -> Start screen saver
defaults write com.apple.dock wvous-br-corner -int 5

# ***** Settings > Control Center *****
# Bluetooth: always show in menu bar
defaults -currentHost write com.apple.controlcenter Bluetooth -int 18
# Sound: always show in menu bar
defaults -currentHost write com.apple.controlcenter Sound -int 18
# Battery - show percentage
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

# automatic dark/light mode
defaults delete "Apple Global Domain" "AppleInterfaceStyleSwitchesAutomatically"
defaults write "Apple Global Domain" "AppleInterfaceStyle" 'Dark'

##
# apps
##

# tell hammerspoon to use this as the config directory
defaults write org.hammerspoon.Hammerspoon MJConfigFile "$HOME/.config/hammerspoon/init.lua"

##
# Setup login Items
##
loginitems -l | while read -r item; do
  loginitems -d "$item"
done

loginitems -a "Hammerspoon" -p "/Applications/Hammerspoon.app/"
loginitems -a "Karabiner" -p "/Applications/Karabiner-Elements.app/"
loginitems -a "LinearMouse" -p "/Applications/LinearMouse.app/"
loginitems -a "Rectangle" -p "/Applications/Rectangle.app/"
loginitems -a "Open In Terminal" -p "/Applications/OpenInTerminal.app/"
loginitems -a "Ollama" -p "/Applications/Ollama.app/"
loginitems -a "Docker" -p "/Applications/Docker.app/"

##
# setup dock
##
dockutil --remove all --no-restart
dockutil --add "/Applications/Brave Browser.app" --no-restart
dockutil --add "/System/Applications/System Settings.app" --no-restart
dockutil --add "/System/Applications/Utilities/Activity Monitor.app" --no-restart
dockutil --add "/Applications/Spotify.app" --no-restart
dockutil --add "/Applications/Visual Studio Code.app" --no-restart
dockutil --add "/Applications/Sublime Text.app" --no-restart
dockutil --add "/Applications/Ghostty.app" --no-restart
dockutil --add "$HOME/Downloads/" --display stack

# turn on OpenInTerminal finder extension
pluginkit -e "use" -u "wang.jianing.app.OpenInTerminal.OpenInTerminalFinderExtension"
# customize finder toolbar
defaults write "com.apple.finder" "NSToolbar Configuration Browser" '{"TB Default Item Identifiers"=("com.apple.finder.BACK","com.apple.finder.SWCH",NSToolbarSpaceItem,"com.apple.finder.ARNG","com.apple.finder.SHAR","com.apple.finder.LABL","com.apple.finder.ACTN",NSToolbarSpaceItem,"com.apple.finder.SRCH",);"TB Display Mode"=1;"TB Icon Size Mode"=1;"TB Is Shown"=1;"TB Item Identifiers"=("com.apple.finder.BACK","com.apple.finder.PATH","com.apple.finder.SWCH",NSToolbarSpaceItem,"wang.jianing.app.OpenInTerminal.OpenInTerminalFinderExtension","com.apple.finder.SHAR","com.apple.finder.ACTN",NSToolbarSpaceItem,"com.apple.finder.SRCH",);"TB Size Mode"=1;}'

if cmd_exists nvim; then
  if cmd_exists mise; then
    defaults write "$HOME/Library/Group Containers/group.wang.jianing.app.OpenInTerminal/Library/Preferences/group.wang.jianing.app.OpenInTerminal.plist" NeovimCommand "open -na Ghostty --args -e '$(which mise) x -- $(which nvim) PATH'"
  fi
fi

##
# Reset Everything
##
killall Dock
killall Finder
killall Safari
killall Rectangle
killall Hammerspoon
killall Karabiner-Elements
killall LinearMouse
open --hide --background /Applications/Hammerspoon.app
open --hide --background /Applications/Karabiner-Elements.app
open --hide --background /Applications/Rectangle.app
open --hide --background /Applications/LinearMouse.app

cat <<EOF
# System Settings:
- Display scale
- Add HOME directory to left bar
- Add Projects directory to left bar
- Setup Touch id
EOF

echo "
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
  <dict>
    <key>Label</key>
    <string>ollama</string>
    <key>StandardOutPath</key>
    <string>$HOME/.ollama/launchd.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.ollama/launchd.stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_HOST</key>
        <string>0.0.0.0:11434</string>
        <key>OLLAMA_ORIGINS</key>
        <string>*</string>
    </dict>
    <key>ProgramArguments</key>
    <array>
      <string>/opt/homebrew/bin/ollama</string>
      <string>serve</string>
    </array>
    <key>UserName</key>
    <string>$(id -un)</string>
    <key>GroupName</key>
    <string>$(id -gn)</string>
    <key>ExitTimeOut</key>
    <integer>30</integer>
    <key>Disabled</key>
    <false />
    <key>KeepAlive</key>
    <true />
  </dict>
</plist>" | sudo tee /Library/LaunchDaemons/ollama.plist >/dev/null
