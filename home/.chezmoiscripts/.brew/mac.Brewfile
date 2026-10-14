# macOS-only tools and applications.
# Installed by darwin/run_onchange_before_11-brew-mac.sh.tmpl. The OS guard
# keeps the shared cleanup step safe to read this file on Linux.

if OS.mac?
  # Cursor CLI uses a cask on macOS and its official installer on Linux.
  cask 'cursor-cli'
  # Antigravity CLI: macOS-only (no standalone Linux CLI; it ships inside the IDE)
  cask 'antigravity-cli'

  brew 'reattach-to-user-namespace'
  brew 'dockutil'
  brew 'mas'
  brew 'mist-cli'
  brew 'trash'
  brew 'coreutils'

  tap 'OJFord/formulae'
  brew 'loginitems'

  # Applications
  cask 'android-platform-tools'
  # sdkmanager and avdmanager; they run on openjdk@17
  cask 'android-commandlinetools'
  brew 'openjdk@17'
  # remote Web Inspector for Safari on iOS devices
  brew 'ios-webkit-debug-proxy'
  cask 'balenaetcher'
  cask 'brave-browser'
  cask 'calibre'
  cask 'charles'
  cask 'docker-desktop'
  cask 'firefox'
  cask 'google-chrome'
  cask 'grandperspective'
  cask 'imageoptim'
  cask 'karabiner-elements'
  cask 'keka'
  cask 'linearmouse'
  cask 'microsoft-edge'
  cask 'openvpn-connect'
  cask 'plex'
  cask 'plexamp'
  cask 'rectangle'
  cask 'speedcrunch'
  cask 'spotify'
  cask 'sublime-text'
  cask 'vlc'
  cask 'visual-studio-code'
  cask 'ghostty'
  cask 'wireshark-app'
  cask 'openinterminal'
  # Finder sidebar CLI; the pkg installer needs sudo
  cask 'mysides'

  # App Store applications
  mas 'Xcode', id: 497799835
  mas 'WireGuard', id: 1451685025
end
