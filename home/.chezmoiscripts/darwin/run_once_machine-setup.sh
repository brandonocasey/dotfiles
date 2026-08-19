#!/usr/bin/env bash

# One-time machine setup. Everything here needs sudo and never changes,
# so it lives apart from the run_onchange settings script.

# Prime sudo up front so the password prompt appears immediately,
# not minutes into the apply.
sudo -v

##
# One sudo password entry covers 15 minutes across all terminals,
# so brew casks stop re-prompting mid-install.
# A broken sudoers.d file locks out sudo; visudo -c MUST pass or we remove it.
##
sudo tee /etc/sudoers.d/timestamp-timeout >/dev/null <<'EOF'
Defaults timestamp_timeout=15
Defaults timestamp_type=global
EOF
sudo chmod 440 /etc/sudoers.d/timestamp-timeout
sudo visudo -c -f /etc/sudoers.d/timestamp-timeout || sudo rm /etc/sudoers.d/timestamp-timeout

##
# setup computer name
##
sudo scutil --set HostName bcasey-macbook
sudo scutil --set LocalHostName bcasey-macbook
sudo scutil --set ComputerName bcasey-macbook

##
# ollama launch daemon
##
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
