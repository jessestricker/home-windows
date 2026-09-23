# home-windows

🪟 My home directory on Windows.

## First time setup

```powershell
# Clone the repository to ~/home-windows.
git clone git@github.com:jessestricker/home-windows.git ~/home-windows
cd ~/home-windows

# Install software.
winget import --import-file ./.github/winget-packages.json --no-upgrade

# Setup home file links.
Import-Module -Force ./Documents/PowerShell/Modules/Home/Home.psm1
Sync-HomeFiles
```
