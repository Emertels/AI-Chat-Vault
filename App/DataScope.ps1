# Conversation-scoped Codex snapshots. File units and directory units share the
# verified staging/rollback engine; caches are never traversed or replaced.
function Get-CodexDirectories {
    return @('sessions','archived_sessions','attachments','visualizations','dictation-history','sqlite','rollout-migrations','vendor_imports','agents')
}

function Test-CodexFileName {
    param([string]$Name)
    if($Name -in @('.codex-global-state.json','.codex-global-state.json.bak','session_index.jsonl','history.jsonl','config.toml','auth.json')){return $true}
    return ($Name -match '^[a-zA-Z0-9_.-]+\.sqlite(?:-(?:wal|shm))?$' -and $Name -notmatch '^logs_')
}

function Get-UnitKey {
    param([string]$ParentKey,[string]$Relative)
    $sha=[Security.Cryptography.SHA256]::Create()
    try{
        $bytes=[Text.Encoding]::UTF8.GetBytes(($ParentKey+'/'+$Relative).ToLowerInvariant())
        $label=($Relative -replace '[^a-zA-Z0-9-]','-').Trim('-').ToLowerInvariant()
        if($label.Length -gt 40){$label=$label.Substring(0,40)}
        return 'codex-'+$label+'-'+([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').Substring(0,12).ToLowerInvariant()
    }finally{$sha.Dispose()}
}

function Get-DataType {
    param($Item)
    if($Item.PSObject.Properties['RootType']){return [string]$Item.RootType}
    return 'Directory'
}

function Get-SourceMapping {
    param($Item)
    if($Item.PSObject.Properties['SourceMapping']){return $Item.SourceMapping}
    return $null
}

function Resolve-UnitMapping {
    param($Profile,$Item)
    $mapping=Get-SourceMapping $Item
    if(!$mapping){throw 'Missing scoped-data mapping.'}
    if($Profile.Id -ne 'codex' -or $mapping.ParentKey -ne 'codex-engine'){throw 'Scoped mapping not allowed for this profile.'}
    $relative=[string]$mapping.Relative
    Assert-Relative $relative
    if($relative -match '[\\/]'){throw 'Scoped units must be immediate children of CODEX_HOME.'}
    $type=Get-DataType $Item
    if($type -eq 'Directory'){
        if($relative -notin @(Get-CodexDirectories)){throw 'Unknown Codex data directory.'}
    }elseif($type -eq 'File'){
        if(!(Test-CodexFileName $relative)){throw 'Unknown Codex data file.'}
    }else{throw 'Unknown scoped data type.'}
    if($Item.Key -cne (Get-UnitKey $mapping.ParentKey $relative)){throw 'Scoped unit key does not match its mapping.'}
    $parents=@(Resolve-Roots $Profile | Where-Object Key -eq $mapping.ParentKey)
    if($parents.Count -ne 1){throw 'Original CODEX_HOME mapping is unavailable.'}
    $path=Child-Path $parents[0].Path $relative
    Assert-SourcePath $path -AllowFile:($type -eq 'File')
    return [pscustomobject]@{Key=$Item.Key;Path=$path;RootType=$type;SourceMapping=$mapping}
}

function Expand-BackupRoots {
    param($Profile,[object[]]$Roots)
    $result=New-Object 'System.Collections.Generic.List[object]'
    foreach($root in $Roots){
        if($Profile.Id -ne 'codex' -or $root.Key -ne 'codex-engine'){$result.Add($root);continue}
        $files=@('.codex-global-state.json','.codex-global-state.json.bak','session_index.jsonl','history.jsonl','config.toml','auth.json')
        if(Test-Path -LiteralPath $root.Path -PathType Container){
            # Only one directory listing. Never descend into plugins/cache or links.
            foreach($entry in @(Get-ChildItem -LiteralPath $root.Path -Force)){
                if(!$entry.PSIsContainer -and (Test-CodexFileName $entry.Name)){
                    $files+=$entry.Name
                    if($entry.Name -match '^(.+\.sqlite)(?:-(?:wal|shm))?$'){
                        $files+=$Matches[1];$files+=($Matches[1]+'-wal');$files+=($Matches[1]+'-shm')
                    }
                }
            }
        }
        foreach($type in @('Directory','File')){
            $names=if($type -eq 'Directory'){@(Get-CodexDirectories)}else{@($files | Sort-Object -Unique)}
            foreach($name in $names){
                $unit=[pscustomobject]@{
                    Key=(Get-UnitKey $root.Key $name);RootType=$type
                    SourceMapping=[pscustomobject]@{ParentKey=$root.Key;Relative=$name}
                }
                $result.Add((Resolve-UnitMapping $Profile $unit))
            }
        }
    }
    return $result.ToArray()
}

function Get-ScopeExclusions {
    param($Profile,[object[]]$Roots)
    if($Profile.Id -ne 'codex'){return @()}
    $base=@(Resolve-Roots $Profile | Where-Object Key -eq 'codex-engine')
    if(!$base.Count -or !(Test-Path -LiteralPath $base[0].Path -PathType Container)){return @()}
    $included=@($Roots | Where-Object {Get-SourceMapping $_} | ForEach-Object {$_.SourceMapping.Relative})
    return @(Get-ChildItem -LiteralPath $base[0].Path -Force | Where-Object Name -NotIn $included | ForEach-Object {
        [pscustomobject]@{ParentKey='codex-engine';Relative=$_.Name;Reason='Outside conversation-data scope; never traversed or restored'}
    })
}

function Get-DataInventory {
    param([string]$Path,[string]$RootType='Directory')
    Assert-SourcePath $Path -AllowFile:($RootType -eq 'File')
    if($RootType -eq 'Directory'){return @(Get-Inventory $Path)}
    if($RootType -ne 'File' -or !(Test-Path -LiteralPath $Path -PathType Leaf)){throw "Expected a regular file: $Path"}
    $hash=Hash-File $Path
    $item=Get-Item -LiteralPath $Path -Force
    return @([pscustomobject]@{Path='file';Kind='File';Length=[long]$item.Length;Hash=$hash;Utc=$item.LastWriteTimeUtc.ToString('o')})
}

function Copy-VerifiedFile {
    param([string]$Source,[string]$Destination,$Entry)
    Assert-NoReparse $Source;Assert-NoReparse $Destination
    if(Test-Path -LiteralPath $Destination){throw 'Copy destination already exists.'}
    Ensure-Directory ([IO.Path]::GetDirectoryName($Destination))
    Set-VaultWork (L 'copying') 2 $Source
    $inputStream=$null;$outputStream=$null
    try{
        $inputStream=[IO.File]::Open($Source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        $outputStream=[IO.File]::Open($Destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $buffer=New-Object byte[] 1048576
        while(($count=$inputStream.Read($buffer,0,$buffer.Length)) -gt 0){$outputStream.Write($buffer,0,$count);Show-VaultFileProgress $Source $inputStream.Position $inputStream.Length;Check-Cancel}
        $outputStream.Flush($true)
    }finally{if($inputStream){$inputStream.Dispose()};if($outputStream){$outputStream.Dispose()}}
    Update-VaultWork 1 $Destination
    [IO.File]::SetLastWriteTimeUtc($Destination,[datetime]::Parse($Entry.Utc).ToUniversalTime())
    if((Get-Item -LiteralPath $Destination).Length -ne [long]$Entry.Length -or (Hash-File $Destination) -ne $Entry.Hash){throw 'File copy failed SHA-256 verification.'}
    Update-VaultWork 2 $Destination -Force
}

function Copy-DataToPayload {
    param([string]$Source,[string]$Destination,[object[]]$Inventory,[string]$RootType)
    if($RootType -eq 'Directory'){Copy-CheckedTree $Source $Destination $Inventory;return}
    Ensure-Directory $Destination
    Copy-VerifiedFile $Source (Join-Path $Destination 'file') $Inventory[0]
}

function Copy-PayloadToStage {
    param([string]$Source,[string]$Destination,$Slot)
    if((Get-DataType $Slot) -eq 'Directory'){Copy-CheckedTree $Source $Destination @($Slot.Items);return}
    Copy-VerifiedFile (Join-Path $Source 'file') $Destination @($Slot.Items)[0]
}

function Move-DataEntry {
    param([string]$Source,[string]$Destination)
    Assert-NoReparse $Source;Assert-NoReparse $Destination
    if(Test-Path -LiteralPath $Destination){throw 'Move destination already exists.'}
    if(Test-Path -LiteralPath $Source -PathType Container){[IO.Directory]::Move($Source,$Destination)}
    elseif(Test-Path -LiteralPath $Source -PathType Leaf){[IO.File]::Move($Source,$Destination)}
    else{throw 'Move source disappeared.'}
}
