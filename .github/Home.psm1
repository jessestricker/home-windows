function Import-HomeFile {
    [CmdletBinding(DefaultParameterSetName = "Path")]

    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Path")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Path,

        [Parameter(Mandatory = $true, ParameterSetName = "LiteralPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath
    )

    $ErrorActionPreference = "Stop"

    $pathsToImport = @()
    if ($Path) {
        $pathsToImport += Get-Item -Path $Path | ForEach-Object { $_ -as [string] }
    }
    if ($LiteralPath) {
        $pathsToImport += Get-Item -LiteralPath $LiteralPath | ForEach-Object { $_ -as [string] }
    }

    $repoDir = Resolve-Path -LiteralPath "$PSScriptRoot/.."
    Write-Debug "repoDir: $repoDir"

    foreach ($pathToImport in $pathsToImport) {
        if (-not (Test-Path -LiteralPath $pathToImport -PathType Leaf)) {
            Write-Warning "Path '$pathToImport' must point to a regular file."
            continue
        }
        if ($pathToImport.StartsWith($repoDir)) {
            Write-Warning "Path '$pathToImport' must not be from the repository."
            continue
        }
        if (-not $pathToImport.StartsWith($HOME)) {
            Write-Warning "Path '$pathToImport' must be from the home directory."
            continue
        }

        $relativePath = Resolve-Path -LiteralPath $pathToImport -Relative -RelativeBasePath $HOME
        $repoPath = Join-Path $repoDir $relativePath
        Write-Debug "pathToImport: $pathToImport, relativePath: $relativePath, repoPath: $repoPath"

        if (Test-Path -LiteralPath $repoPath) {
            Write-Warning "Path '$pathToImport' must not be imported already."
            continue
        }

        Write-Host "Importing '$pathToImport'."
        New-Item -Path (Split-Path -LiteralPath $repoPath) -ItemType Directory -Force | Out-Null
        Move-Item -LiteralPath $pathToImport -Destination $repoPath
        New-Item -Path $pathToImport -ItemType SymbolicLink -Value $repoPath | Out-Null
    }
}

Export-ModuleMember -Function Import-HomeFile
