# home-windows

🪟 My home directory on Windows.

## First time setup

```powershell
cd $HOME
git clone git@github.com:jessestricker/home-windows.git
Import-Module -Force .\.github\Home.psm1
Sync-HomeFiles
```
