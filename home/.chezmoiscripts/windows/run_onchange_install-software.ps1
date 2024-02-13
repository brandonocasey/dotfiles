# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
    $CommandLine = "-NoExit -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -Wait -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    Exit
  }
}

$ChocoInstalled = $false
if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
    $ChocoInstalled = $true
}

# Install chocolatey if not installed
if (-Not $ChocoInstalled) {
  Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

$Packages = '7zip',
'autohotkey.portable',
'bitwarden',
'brave',
'chezmoi',
'chocolatey',
'chocolateygui',
'discord',
'docker-cli',
'docker-desktop',
'flow-launcher',
'nerd-fonts-IosevkaTerm',
'plex',
'plexamp',
'qbittorrent',
'rufus',
'sharex',
'spotify',
'steam',
'sublimetext4',
'ventoy',
'wezterm.install',
'zoom'

ForEach ($PackageName in $Packages) {
  choco install $PackageName -y
}
