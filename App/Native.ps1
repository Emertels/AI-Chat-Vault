function Initialize-Native {
    if ('Cofre.Native' -as [type]) { return }
    # HttpWebRequest mantém compatibilidade com .NET Framework / PowerShell 5.1.
    Add-Type -Path (Join-Path $PSScriptRoot 'Native.cs') -IgnoreWarnings -WarningAction SilentlyContinue -ErrorAction Stop
}

function Copy-SqliteSnapshot {
    param([string]$Source, [string]$Destination)
    Assert-NoReparse $Source
    Assert-NoReparse $Destination
    if (Test-Path -LiteralPath $Destination) { throw 'O destino SQLite já existe.' }
    Ensure-Directory ([IO.Path]::GetDirectoryName($Destination))
    Initialize-Native
    [Cofre.Native]::Backup($Source, $Destination)
}

function Test-SqliteFile {
    param([string]$Path)
    Assert-NoReparse $Path
    Initialize-Native
    $result = [Cofre.Native]::Scalar($Path, 'PRAGMA quick_check')
    if ($result -ne 'ok') { throw "SQLite não íntegro: $Path ($result)" }
}
