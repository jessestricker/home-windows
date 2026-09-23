using namespace System.IO

$HomeDir = [Path]::GetFullPath($HOME)
$RepoDir = [Path]::GetFullPath("$HOME\home-windows")

function Get-RepoFiles {
    $excludedTopLevelEntries = ".git", ".github"

    Get-ChildItem -LiteralPath $RepoDir -Force |
        Where-Object { $_.Name -notin $excludedTopLevelEntries } |
        ForEach-Object {
            # expand directories recursively
            if ($_ -is [DirectoryInfo]) {
                Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force
            }
            else {
                $_
            }
        } |
        ForEach-Object { $_.FullName }
}

function Sync-HomeFiles {
    [CmdletBinding()]
    param ()

    $ErrorActionPreference = "Stop"

    $repoFiles = Get-RepoFiles
    foreach ($repoFile in $repoFiles) {
        Write-Debug "repoFile = $repoFile"

        $relativePath = [Path]::GetRelativePath($RepoDir, $repoFile)
        Write-Debug "relativePath = $relativePath"

        $homeFile = [Path]::GetFullPath($relativePath, $HomeDir)
        Write-Debug "homeFile = $homeFile"

        # Check whether homeFile exists and links to the repo file.
        try {
            $homeFileLinkTarget = (Get-Item -LiteralPath $homeFile).Target
            Write-Debug "homeFileLinkTarget = $homeFileLinkTarget"
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            # homeFile does not exist: create symbolic link.
            [Directory]::CreateDirectory([Path]::GetDirectoryName($homeFile)) | Out-Null
            [File]::CreateSymbolicLink($homeFile, $repoFile) | Out-Null

            Write-Host "$($PSStyle.Foreground.Blue)Synced:$($PSStyle.Reset) $relativePath"
            continue
        }

        if ($homeFileLinkTarget -eq $repoFile) {
            # homeFile exists and links to the repoFile: nothing to do.
            Write-Host "$($PSStyle.Foreground.Green)Ok:$($PSStyle.Reset) $relativePath"
            continue
        }

        # homeFile exists but does not link to the repoFile: inform user.
        Write-Host "$($PSStyle.Foreground.Red)Conflict:$($PSStyle.Reset) $relativePath"
    }
}

Export-ModuleMember -Function Sync-HomeFiles

function Import-HomeFile {
    [CmdletBinding(DefaultParameterSetName = "Path")]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = "LiteralPath",
            HelpMessage = "Literal path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]] $LiteralPath,

        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = "Path",
            HelpMessage = "Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]] $Path
    )

    $ErrorActionPreference = "Stop"

    $paths = @()
    if ($null -ne $LiteralPath) {
        $paths = $LiteralPath | ForEach-Object { Resolve-Path -LiteralPath $_ }
    }
    if ($null -ne $Path) {
        $paths = $Path | ForEach-Object { Resolve-Path -Path $_ }
    }

    foreach ($path in $paths) {
        Write-Debug "path = $path"

        $homeFile = (Resolve-Path -LiteralPath $Path).ProviderPath
        Write-Debug "homeFile = $homeFile"

        if (-not [File]::Exists($homeFile)) {
            throw "Path '$path' must point to an existing regular file."
        }
        if (-not $homeFile.StartsWith($HomeDir)) {
            throw "Path '$path' must be from the home directory."
        }
        if ($homeFile.StartsWith($RepoDir)) {
            throw "Path '$path' must not be from the repo directory."
        }

        $relativePath = [Path]::GetRelativePath($HomeDir, $homeFile)
        Write-Debug "relativePath = $relativePath"

        $repoFile = [Path]::GetFullPath($relativePath, $RepoDir)
        Write-Debug "repoFile = $repoFile"

        if ([Path]::Exists($repoFile)) {
            Write-Host "$($PSStyle.Foreground.Red)Conflict:$($PSStyle.Reset) $relativePath"
            continue
        }

        [Directory]::CreateDirectory([Path]::GetDirectoryName($repoFile)) | Out-Null
        [File]::Move($homeFile, $repoFile)
        [File]::CreateSymbolicLink($homeFile, $repoFile) | Out-Null

        Write-Host "$($PSStyle.Foreground.Blue)Imported:$($PSStyle.Reset) $relativePath"
    }
}

Export-ModuleMember -Function Import-HomeFile
