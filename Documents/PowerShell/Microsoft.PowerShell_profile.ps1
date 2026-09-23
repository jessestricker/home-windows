# Global Settings

[cultureinfo]::CurrentCulture = "en-IE"
[cultureinfo]::CurrentUICulture = "en-IE"

# Key Bindings

Set-PSReadLineKeyHandler -Chord 'Ctrl+Spacebar' -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 'Ctrl+?' -Function AcceptSuggestion

# Prompt

function prompt {
    $Prompt = ""

    # current working directory
    $Prompt += "`e[1;34m"
    $CurrentDir = $PWD.Path
    if ($CurrentDir.StartsWith($HOME)) {
        $Prompt += "~" + $CurrentDir.Substring($HOME.Length)
    }
    else {
        $Prompt += $CurrentDir
    }

    # prompt indicator ">"
    $Prompt += "`e[39m" + (">" * ($NestedPromptLevel + 1))

    # reset style and space
    $Prompt += "`e[0m "

    return $Prompt
}

# Functions

function New-Password {
    <#
    .SYNOPSIS
        Creates a new random password.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [PSDefaultValue()]
        [ValidateRange("Positive")]
        [int] $Entropy = 256,

        [switch] $WithSymbols
    )

    $Ascii = "`u{0000}".."`u{007F}"
    $Digits = $Ascii | Where-Object { [System.Char]::IsDigit($_) }
    $Letters = $Ascii | Where-Object { [System.Char]::IsLetter($_) }
    $Symbols = $Ascii | Where-Object { [System.Char]::IsPunctuation($_) -or [System.Char]::IsSymbol($_) }

    $Alphabet = $Digits + $Letters
    if ($WithSymbols) {
        $Alphabet += $Symbols
    }

    $Length = [Math]::Ceiling($Entropy / [Math]::Log2($Alphabet.Count))
    $Password = 1..$Length | ForEach-Object { $Alphabet | Get-SecureRandom } | Join-String

    return $Password
}

function ConvertTo-Base64 {
    <#
    .SYNOPSIS
        Encodes a byte array into a string using base64.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [byte[]]
        $Value = @()
    )

    return [System.Convert]::ToBase64String($Value)
}

function ConvertFrom-Base64 {
    <#
    .SYNOPSIS
        Decodes a base64-encoded string into the original byte array.
    #>

    [CmdletBinding()]
    [OutputType([byte[]])]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [string]
        $Value = ""
    )

    return (, [System.Convert]::FromBase64String($Value))
}

function ConvertTo-Utf8 {
    <#
    .SYNOPSIS
        Encodes a string into a byte array using UTF-8.
    #>

    [CmdletBinding()]
    [OutputType([byte[]])]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [string]
        $Value = ""
    )

    return (, [System.Text.Encoding]::UTF8.GetBytes($Value))
}

function ConvertFrom-Utf8 {
    <#
    .SYNOPSIS
        Decodes a UTF-8 encoded byte array into a string.
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [byte[]]
        $Value = @()
    )

    return [System.Text.Encoding]::UTF8.GetString($Value)
}
