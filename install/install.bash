#!/usr/bin/env bash

echo "Getting sudo pre-approval"
sudo -v

if [ "$(uname)" = "Linux" ]; then 
  sudo apt-get install curl git
  PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
elif [ "$(uname)" = "Darwin" ]; then
  PATH="$PATH:/usr/local/bin"
fi

# install nvchad
if [ ! -d ~/.config/nvim/.git ]; then
  echo "Cloning nvchad for nvim"
  mkdir -p ~/.config/nvim
  git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
fi

# install brew if not installed
if ! command -v brew 2>/dev/null >/dev/null; then
  echo "Installing Brew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# make sure everything from brew is in the path
eval "$(brew shellenv)"

# chezmoi
echo "Installing and Applying Chezmoi config"
if ! command -v chezmoi 2>/dev/null >/dev/null; then
  brew install chezmoi
fi

chezmoi init --apply brandonocasey

# install brew dependencies
echo "Installing Brewfile software"
brew bundle --file="$HOME/.config/brewfile/Brewfile"

if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
  mkdir -p "$HOME/.config/chezmoi"
  {
    echo "[git]"
    echo "    autoCommit = true"
    echo "    autoPush = true"
  } >> "$HOME/.config/chezmoi/chezmoi.toml"
fi

fish_loc="$(which fish)"
if ! grep -q "$fish_loc" /etc/shells && command -v fish 2>/dev/null >/dev/null; then
  echo "Changing default shell to fish"
  echo "$fish_loc" | sudo tee -a '/etc/shells'
  chsh -s "$fish_loc"
fi

echo "Setting up asdf"
if command -v asdf 2>/dev/null >/dev/null; then
  while read -r p; do
    plugin_name="${p%%[[:space:]]*}"
    asdf plugin-add "$plugin_name"
    asdf install "$plugin_name"
    if [ "$plugin_name" = "direnv" ]; then
      asdf direnv setup --shell fish --version latest
    fi
  done < ~/.tool-versions
fi
fish -c "fish_update_completions" &
disown

tldr -u &
disown

if [ "$(uname)" = "Darwin" ]; then
  #!/usr/bin/env bash

  xcode-select --install 2>/dev/null 1>/dev/null
  sudo xcodebuild -license accept

  # prevent annoying "Login Item" Notifications
  sfltool resetbtm

  # install brew dependencies
  echo "Installing Brewfile-mac software"
  brew bundle --file="$HOME/.config/brewfile/Brewfile-mac"

  echo "Writings settings"

  ##
  # dock
  ##

  # Set to the right
  defaults write com.apple.dock "orientation" -string "right"

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
  # Safari
  ##

  # Show full website url
  defaults write com.apple.Safari "ShowFullURLInSmartSearchField" -bool "true"

  # Enable Safari’s debug menu
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

  # Disable webkit rendering delay
  defaults write com.apple.Safari WebKitInitialTimedLayoutDelay 0.25

  ##
  # Finder
  ##

  # Always show file extensions
  defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true" 

  # Don't show hidden files
  defaults write com.apple.finder "AppleShowAllFiles" -bool "false"

  # Show the "path" bar
  defaults write com.apple.finder "ShowPathbar" -bool "true"

  # list view by default
  defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"

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

  ##
  # apps
  ##

  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.config/.iterm2"

  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

  # tell hammerspoon to use this as the config directory
  defaults write org.hammerspoon.Hammerspoon MJConfigFile "$HOME/.config/hammerspoon/init.lua"

  killall Dock
  killall Finder
  killall Safari
  killall Rectangle
  killall Hammerspoon
  killall Karabiner-Elements
  open /Applications/Hammerspoon.app/
  open /Applications/Karabiner-Elements.app/
  open /Applications/Rectangle.app/

  echo "Settings:"
  echo "Night shift and 1 min Do not Disturb"
  echo "Setup touch id"
  echo "Show battery percentage in bar"
  echo "Add sound icon to menu bar"
  echo "Add Path to finder toolbar"
  echo "Add Favorites"
  echo "Change computer name via System Preferences -> Sharing -> Computer Name: "
  echo "System appearance to dark always"
  echo "bottom bar: "
  echo "- finder"
  echo "- brave"
  echo "- system settings"
  echo "- spotify"
  echo "- speedcrunch"
  echo "- devutils"
  echo "- activity monitor"
  echo "- browserstack local"

  echo "Install Epson printer utils"
fi

