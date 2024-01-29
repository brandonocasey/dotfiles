#!/usr/bin/env bash
xcode-select --install 2>/dev/null 1>/dev/null

# clone to ~/.local/share/chezmoi
if [ ! -d ~/.local/share/chezmoi/.git ]; then
  mkdir -p ~/.local/share/chezmoi/.git
  git@brandonocasey.github.com:brandonocasey/chezmoi.git ~/.local/share/chezmoi/
fi

# install nvchad
if [ ! -d ~/.config/nvim/.git ]; then
  mkdir -p ~/.config/nvim
  git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
fi


# install brew if not installed
if ! command -v brew 2>/dev/null >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# install brew wrap
if [ ! -f "$(brew --prefix)/etc/brew-wrap" ]; then
  brew install rcmdnk/file/brew-file
fi

# source brew wrap
source "$(brew --prefix)/etc/brew-wrap"

# install brew dependencies
brew file update

# make sure everything from brew is in the path
eval "$(brew shellenv)"

# chezmoi
chezmoi apply --force

echo "Writings settings"

# Set dock size
defaults write com.apple.dock tilesize -int 75

# Disable press and hold
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Always show hidden files
defaults write com.apple.finder AppleShowAllFiles YES

# Show Path bar and status bar in finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# opening and closing windows and popovers
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

# smooth scrolling
defaults write -g NSScrollAnimationEnabled -bool false

# showing and hiding sheets, resizing preference windows, zooming windows
# float 0 doesn't work
defaults write -g NSWindowResizeTime -float 0.001

# opening and closing Quick Look windows
defaults write -g QLPanelAnimationDuration -float 0

# rubberband scrolling (doesn't affect web views)
defaults write -g NSScrollViewRubberbanding -bool false

# resizing windows before and after showing the version browser
# also disabled by NSWindowResizeTime -float 0.001
defaults write -g NSDocumentRevisionsWindowTransformAnimation -bool false

# showing a toolbar or menu bar in full screen
defaults write -g NSToolbarFullScreenAnimationDuration -float 0

# scrolling column views
defaults write -g NSBrowserColumnAnimationSpeedMultiplier -float 0

# showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide-delay -float 0

# showing and hiding Mission Control, command+numbers
defaults write com.apple.dock expose-animation-duration -float 0

# showing and hiding Launchpad
defaults write com.apple.dock springboard-show-duration -float 0
defaults write com.apple.dock springboard-hide-duration -float 0

# changing pages in Launchpad
defaults write com.apple.dock springboard-page-duration -float 0

# at least AnimateInfoPanes
defaults write com.apple.finder DisableAllAnimations -bool true

# sending messages and opening windows for replies
defaults write com.apple.Mail DisableSendAnimations -bool true
defaults write com.apple.Mail DisableReplyAnimations -bool true

# disable dock bouncing
defaults write com.apple.dock no-bouncing -bool TRUE

# Faster key repeat
defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)<Paste>

# disable mouse acceleration
defaults write .GlobalPreferences com.apple.mouse.scaling -1
defaults write .GlobalPreferences com.apple.scrollwheel.scaling -1

# autohide dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

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

# Do not keep recently used apps
defaults write com.apple.dock show-recents -bool false

# Enable Safari’s debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

killall Dock
killall Finder

# Specify the preferences directory
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$XDG_CONFIG_HOME/.iterm2"

# Tell iTerm2 to use the custom preferences in the directory
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

# tell hammerspoon to use this as the config directory
defaults write org.hammerspoon.Hammerspoon MJConfigFile "$XDG_CONFIG_HOME/hammerspoon/init.lua"

echo "Settings:"
echo "Now change mouse/trackpad settings"
echo "  a. Mouse"
echo "    i. Point & Click: Secondary Click Only + fastest mouse speed"
echo "    ii. More Gestures: All checked"
echo "    iii. Uncheck Scroll direction: Natural"
echo "  b. Trackpad"
echo "    i. Point & Click: All but look up and data detectors"
echo "mouse double click speed 3 notches below max"
echo "Night shift and 1 min Do not Disturb"
echo "Setup touch id"
echo "Show battery percentage in bar"
echo "Add sound icon to menu bar"
echo "Add Path to finder toolbar"
echo "Add Favorites"
echo "Change computer name via System Preferences -> Sharing -> Computer Name: "
echo "System appearnce to dark always"
echo "bottom bar: "
echo "- finder"
echo "- zoom"
echo "- chrome"
echo "- logitech camera"
echo "- system settings"
echo "- spotify"
echo "- speedcrunch"
echo "- devutils"
echo "- activity monitor"
echo "- browserstack local"
echo "- sublime"
echo "- vscodium"
echo "- openvpn"

echo "Install logitune https://support.logi.com/hc/en-nz/articles/360024849133-Download-HD-Pro-Webcam-C920"
echo "Install Epson printer utils"
