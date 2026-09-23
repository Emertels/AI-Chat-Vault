function Write-Line {
    param([string]$Text = '', [ConsoleColor]$Color = [ConsoleColor]::Gray)
    if ($script:TestMode) { return }
    Suspend-VaultProgress
    Write-Host $Text -ForegroundColor $Color
}

function Write-Log {
    param([string]$Text)
    if ($script:LogPath) {
        $line = '{0} | {1}{2}' -f (Get-Date).ToString('o'), $Text, [Environment]::NewLine
        [IO.File]::AppendAllText($script:LogPath, $line, (New-Object Text.UTF8Encoding($false)))
    }
}

function Ensure-Directory {
    param([string]$Path)
    Assert-NoReparse $Path
    [void][IO.Directory]::CreateDirectory($Path)
}

function Full-Path {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Caminho vazio.' }
    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar)
}

function Is-Within {
    param([string]$Path, [string]$Parent)
    $p = Full-Path $Path
    $root = Full-Path $Parent
    return ($p.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
        $p.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase))
}

function Assert-NoReparse {
    param([string]$Path)
    $current=[IO.Path]::GetFullPath($Path)
    while($current){
        try{
            $attributes=[IO.File]::GetAttributes($current)
            if(($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
                throw "Link, junção ou arquivo sob demanda não suportado: $current. Use uma pasta física local."
            }
        }catch{
            $cause=$_.Exception;while($cause.InnerException){$cause=$cause.InnerException}
            if($cause -isnot [IO.FileNotFoundException] -and $cause -isnot [IO.DirectoryNotFoundException]){throw}
        }
        $parent=[IO.Path]::GetDirectoryName($current)
        if($parent -eq $current){break};$current=$parent
    }
}

function Assert-Relative {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or [IO.Path]::IsPathRooted($Path)) {
        throw 'Caminho relativo inválido no inventário.'
    }
    foreach ($part in ($Path -split '[\\/]')) {
        if (!$part -or $part -in @('.','..') -or $part -match '[<>:"|?*\x00-\x1f]' -or
            $part -match '[. ]$' -or $part -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') {
            throw "Componente de caminho recusado: $part"
        }
    }
}

function Child-Path {
    param([string]$Root, [string]$Relative)
    Assert-Relative $Relative
    $path = Full-Path (Join-Path $Root $Relative)
    if (!(Is-Within $path $Root)) { throw 'Caminho fora da pasta autorizada.' }
    return $path
}

function Assert-SourcePath {
    param([string]$Path,[switch]$AllowFile)
    $pathFull = Full-Path $Path
    if (!$script:TestMode -and ($pathFull -notmatch '^[A-Za-z]:\\')) {
        throw 'Use uma unidade local do Windows, HD externo ou pendrive. Caminhos de rede não são suportados.'
    }
    $driveRoot = [IO.Path]::GetPathRoot($Path).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if ($pathFull -eq $driveRoot) { throw 'Uma unidade inteira não pode ser usada como perfil.' }
    foreach ($systemRoot in @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($systemRoot -and (Is-Within $pathFull $systemRoot)) { throw 'Pastas do sistema e de instalação não são perfis de conversa.' }
    }
    foreach ($container in @($env:USERPROFILE, $env:APPDATA, $env:LOCALAPPDATA)) {
        if ($container -and ((Full-Path $container) -eq $pathFull -or (Is-Within $container $pathFull))) {
            throw 'Selecione a subpasta do aplicativo, não todo o perfil do Windows ou AppData.'
        }
    }
    if (Is-Within $script:Base $pathFull) { throw 'A pasta de origem contém este cofre. Mova o cofre para fora dos dados do aplicativo.' }
    foreach ($cofreFolder in @($script:BackupBase, $script:JournalBase, $script:LogBase)) {
        if ((Is-Within $cofreFolder $pathFull) -or (Is-Within $pathFull $cofreFolder)) {
            throw 'A pasta de dados não pode conter nem ficar dentro das pastas Backups, Transacoes ou Relatorios do cofre.'
        }
    }
    Assert-NoReparse $pathFull
    if (!$AllowFile -and (Test-Path -LiteralPath $pathFull) -and !(Test-Path -LiteralPath $pathFull -PathType Container)) {
        throw "O perfil deve apontar para uma pasta: $pathFull"
    }
}

function Check-Cancel {
    if (!$script:CancelAllowed -or $script:TestMode) { return }
    $escape = $false
    try {
        if (![Console]::IsInputRedirected -and [Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            $escape = ($key.Key -eq [ConsoleKey]::Escape)
        }
    } catch { return }
    if ($escape) { throw [OperationCanceledException]::new('Operação cancelada com Esc; nenhum backup incompleto será usado.') }
}

function Hash-File {
    param([string]$Path)
    Check-Cancel
    Assert-NoReparse $Path
    $stream = $null
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        $buffer = $script:HashBuffer
        while (($n = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            [void]$sha.TransformBlock($buffer, 0, $n, $buffer, 0)
            Show-VaultFileProgress $Path $stream.Position $stream.Length
            Check-Cancel
        }
        [void]$sha.TransformFinalBlock((New-Object byte[] 0), 0, 0)
        return ([BitConverter]::ToString($sha.Hash)).Replace('-', '').ToLowerInvariant()
    } catch {
        $cause=$_.Exception
        while($cause.InnerException){$cause=$cause.InnerException}
        if(($cause.HResult -band 0xffff) -in @(32,33)){
            throw [IO.IOException]::new((L 'locked' @($Path)),$cause)
        }
        throw
    } finally {
        if ($stream) { $stream.Dispose() }
        $sha.Dispose()
    }
}

function Write-NewText {
    param([string]$Path, [string]$Text)
    Assert-NoReparse $Path
    $stream = $null
    try {
        $stream = New-Object IO.FileStream($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($Text)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    } finally { if ($stream) { $stream.Dispose() } }
}

function Write-NewJson {
    param([string]$Path, $Value)
    Write-NewText $Path (ConvertTo-Json -InputObject $Value -Depth 80)
}

function Read-Json {
    param([string]$Path)
    Assert-NoReparse $Path
    return (Convert-JsonText ([IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)))
}

function Convert-JsonText {
    param([string]$Text)
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
        return (ConvertFrom-Json -InputObject $Text -DateKind String)
    }
    return (ConvertFrom-Json -InputObject $Text)
}

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return ('{0:N2} GiB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N1} MiB' -f ($Bytes / 1MB)) }
    return ('{0:N0} KiB' -f ($Bytes / 1KB))
}

function Assert-Space {
    param([string]$Path, [long]$Bytes)
    if ($script:TestMode) { return }
    $drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot([IO.Path]::GetFullPath($Path)))
    $needed = [long]([Math]::Ceiling($Bytes * 1.1) + 64MB)
    if (!$drive.IsReady -or $drive.AvailableFreeSpace -lt $needed) {
        throw "Espaço insuficiente em $($drive.Name). Necessário com margem: $(Format-Bytes $needed)."
    }
    if ($drive.DriveFormat -eq 'FAT32') {
        Write-Line 'Unidade FAT32: arquivos individuais acima de 4 GiB não cabem. Prefira NTFS ou exFAT.' Yellow
    }
}

# -----------------------------------------------------------------------------
# Perfis. São candidatos de armazenamento local, não adaptadores de API.
# A existência da pasta NÃO comprova que ela contém todo o histórico do aplicativo.
# -----------------------------------------------------------------------------

function Validate-Profiles {
    param([object[]]$Profiles)
    $seen = @{}
    foreach ($profile in $Profiles) {
        if ($profile.Id -notmatch '^[a-z0-9][a-z0-9-]{0,63}$' -or $seen.ContainsKey($profile.Id)) {
            throw 'ID de aplicativo inválido ou duplicado em perfis-locais.json.'
        }
        $seen[$profile.Id] = $true
        if ([string]::IsNullOrWhiteSpace($profile.Name) -or @($profile.Processes).Count -eq 0) {
            throw 'Cada perfil precisa de nome e nomes dos processos que usam seus dados.'
        }
        foreach ($proc in $profile.Processes) {
            if ($proc -notmatch '^[a-zA-Z0-9 ._-]+\.exe$') { throw 'Nome de processo inválido no perfil.' }
        }
        if ($profile.CommandMatch) { [void][regex]::new($profile.CommandMatch) }
        $keys = @{}
        foreach ($root in $profile.Roots) {
            if ($root.Key -notmatch '^[a-z0-9][a-z0-9-]{0,79}$' -or $keys.ContainsKey($root.Key)) {
                throw "ID de pasta inválido ou duplicado no perfil $($profile.Name)."
            }
            $keys[$root.Key] = $true
            if ([string]::IsNullOrWhiteSpace($root.Path)) { throw 'Pasta vazia no perfil.' }
        }
    }
}

function Load-Profiles {
    $defaults=@(Get-DefaultProfiles)
    $script:Profiles=@($defaults)
    if (Test-Path -LiteralPath $script:ConfigPath) {
        $config=Read-Json $script:ConfigPath
        if($config.Schema -ne 1){throw 'Unsupported profile configuration version.'}
        Validate-Profiles @($config.Profiles)
        # Preserve configured profiles and custom paths; append new built-in apps.
        $ids=@($config.Profiles | ForEach-Object {$_.Id})
        $script:Profiles=@($config.Profiles)+@($defaults | Where-Object {$_.Id -notin $ids})
    }
    Validate-Profiles $script:Profiles
    Set-ProfilePresentation $script:Profiles
    $script:Profiles=@($script:Profiles | Sort-Object Name)
}

function Get-Profile {
    param([string]$Id)
    $found = @($script:Profiles | Where-Object { $_.Id -eq $Id })
    if ($found.Count -ne 1) { throw "Aplicativo desconhecido: $Id" }
    return $found[0]
}

function Resolve-Roots {
    param($Profile)
    $roots = @()
    foreach ($root in $Profile.Roots) {
        $expanded = [Environment]::ExpandEnvironmentVariables($root.Path)
        if ($expanded -match '%[^%]+%') { throw "Variável de ambiente não definida: $($root.Path)" }
        Assert-SourcePath $expanded
        $roots += [pscustomobject]@{ Key=$root.Key; Path=(Full-Path $expanded) }
    }
    for ($i=0; $i -lt $roots.Count; $i++) {
        for ($j=$i+1; $j -lt $roots.Count; $j++) {
            if ((Is-Within $roots[$i].Path $roots[$j].Path) -or (Is-Within $roots[$j].Path $roots[$i].Path)) {
                throw 'Existem pastas sobrepostas no mesmo perfil. Mantenha apenas a pasta mais abrangente.'
            }
        }
    }
    return $roots
}

# -----------------------------------------------------------------------------
# Inventário e cópia. Sem exclusões silenciosas, links ou arquivo em uso.
# -----------------------------------------------------------------------------

function Get-Inventory {
    param([string]$Root)
    Assert-NoReparse $Root
    if(![IO.Directory]::Exists($Root)){throw "Pasta não encontrada: $Root"}
    $prefix=(Full-Path $Root)+[IO.Path]::DirectorySeparatorChar
    $items=New-Object 'System.Collections.Generic.List[object]'
    $files=New-Object 'System.Collections.Generic.List[object]'
    $stack=New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push((Full-Path $Root))
    Set-VaultWork (L 'progress_count') 0 $Root
    while($stack.Count -gt 0){
        Check-Cancel
        $dir=$stack.Pop();Assert-NoReparse $dir
        foreach($item in ([IO.DirectoryInfo]::new($dir)).EnumerateFileSystemInfos()){
            if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw "Link/junção/arquivo sob demanda encontrado: $($item.FullName). Backup interrompido para não omitir dados."}
            $relative=$item.FullName.Substring($prefix.Length);Assert-Relative $relative
            if(($item.Attributes -band [IO.FileAttributes]::Directory) -ne 0){
                $items.Add([pscustomobject]@{Path=$relative;Kind='Directory';Length=0;Hash='';Utc=$item.LastWriteTimeUtc.ToString('o')})
                $stack.Push($item.FullName)
            }else{$files.Add($item)}
            Update-VaultWork $files.Count $item.FullName
            Check-Cancel
        }
    }
    Set-VaultWork (L 'inventory') $files.Count $Root
    $index=0
    foreach($item in $files){
        Update-VaultWork $index $item.FullName
        $hash=Hash-File $item.FullName;$item.Refresh()
        $items.Add([pscustomobject]@{Path=$item.FullName.Substring($prefix.Length);Kind='File';Length=[long]$item.Length;Hash=$hash;Utc=$item.LastWriteTimeUtc.ToString('o')})
        $index++;Update-VaultWork $index $item.FullName
    }
    Update-VaultWork $files.Count $Root -Force
    return $items.ToArray() | Sort-Object Path
}

function Compare-Inventory {
    param([object[]]$Expected, [object[]]$Actual)
    if (@($Expected).Count -ne @($Actual).Count) { return $false }
    $lookup = @{}
    foreach ($entry in @($Actual)) {
        if ($lookup.ContainsKey($entry.Path)) { return $false }
        $lookup[$entry.Path] = $entry
    }
    foreach ($entry in @($Expected)) {
        if (!$lookup.ContainsKey($entry.Path)) { return $false }
        $other = $lookup[$entry.Path]
        if ($entry.Kind -ne $other.Kind -or [long]$entry.Length -ne [long]$other.Length -or $entry.Hash -ne $other.Hash) { return $false }
    }
    return $true
}

function Copy-CheckedTree {
    param([string]$Source, [string]$Destination, [object[]]$Inventory)
    if (Test-Path -LiteralPath $Destination) { throw "A pasta de cópia já existe: $Destination" }
    Assert-NoReparse $Source
    Ensure-Directory $Destination
    $index = 0
    $totalFiles=@($Inventory | Where-Object Kind -eq 'File').Count
    Set-VaultWork (L 'copying') ($totalFiles*2) $Source
    foreach ($entry in @($Inventory | Sort-Object { $_.Path.Length })) {
        Check-Cancel
        $target = Child-Path $Destination $entry.Path
        $origin = Child-Path $Source $entry.Path
        Assert-NoReparse $origin
        Assert-NoReparse $target
        if ($entry.Kind -eq 'Directory') { Ensure-Directory $target; continue }
        Ensure-Directory ([IO.Path]::GetDirectoryName($target))
        Update-VaultWork $index $origin
        $inputStream = $null
        $outputStream = $null
        try {
            $inputStream = [IO.File]::Open($origin, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
            $outputStream = New-Object IO.FileStream($target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            $buffer = New-Object byte[] 1048576
            while (($n = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $outputStream.Write($buffer, 0, $n)
                Show-VaultFileProgress $origin $inputStream.Position $inputStream.Length
                Check-Cancel
            }
            $outputStream.Flush($true)
        } finally {
            if ($inputStream) { $inputStream.Dispose() }
            if ($outputStream) { $outputStream.Dispose() }
        }
        $index++;Update-VaultWork $index $target
        [IO.File]::SetLastWriteTimeUtc($target, [datetime]::Parse($entry.Utc).ToUniversalTime())
        if ((Get-Item -LiteralPath $target).Length -ne [long]$entry.Length -or (Hash-File $target) -ne $entry.Hash) {
            throw "Falha de verificação durante a cópia: $($entry.Path)"
        }
        $index++
        Update-VaultWork $index $target
    }
    Update-VaultWork ($totalFiles*2) $Destination -Force
}

function New-SnapshotInternal {
    param($Profile, [object[]]$Roots, [ValidateSet('Manual','AntesDeRestaurar')][string]$Kind='Manual')
    if($Kind -eq 'Manual'){
        Stop-AppForDataOperation $Profile
        $Roots=@(Expand-BackupRoots $Profile @($Roots | Where-Object {Test-RootGate $Profile $_}))
    }
    Assert-AppClosed $Profile
    $slots = @()
    [long]$bytes = 0
    $present = 0
    foreach ($root in $Roots) {
        $rootType=Get-DataType $root
        Assert-SourcePath $root.Path -AllowFile:($rootType -eq 'File')
        $exists = Test-Path -LiteralPath $root.Path
        if($exists -and ((Test-Path -LiteralPath $root.Path -PathType Container) -ne ($rootType -eq 'Directory'))){throw 'Data entry type differs from its mapping.'}
        $inventory = @()
        if ($exists) {
            $present++
            $inventory = @(Get-DataInventory $root.Path $rootType)
            foreach ($item in $inventory) { $bytes += [long]$item.Length }
        }
        $slots += [pscustomobject]@{ Key=$root.Key; OriginalPath=$root.Path; Exists=[bool]$exists; Items=@($inventory); RootType=$rootType; SourceMapping=(Get-SourceMapping $root) }
    }
    if ($present -eq 0 -and $Kind -eq 'Manual') { throw 'Nenhuma pasta de dados encontrada. Use Diagnóstico / Configurar pastas.' }
    Ensure-Directory $script:BackupBase
    Assert-Space $script:BackupBase $bytes
    $id = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
    $parent = Join-Path $script:BackupBase $Profile.Id
    Ensure-Directory $parent
    $working = Join-Path $parent ($id + '.incompleto')
    $final = Join-Path $parent $id
    Ensure-Directory $working
    $payload = Join-Path $working 'dados'
    Ensure-Directory $payload
    Write-Log "BACKUP iniciado | $($Profile.Id) | $working | $Kind"
    foreach ($slot in $slots) {
        Check-Cancel
        Assert-AppClosed $Profile
        if ($slot.Exists) { Copy-DataToPayload $slot.OriginalPath (Join-Path $payload $slot.Key) @($slot.Items) (Get-DataType $slot) }
    }
    # Segunda leitura detecta arquivos alterados, criados ou removidos enquanto copiava.
    foreach ($slot in $slots) {
        if ($slot.Exists) {
            if (!(Compare-Inventory @($slot.Items) @(Get-DataInventory $slot.OriginalPath (Get-DataType $slot)))) {
                throw 'Os dados mudaram durante o backup. A cópia incompleta foi preservada, mas não será oferecida para restaurar.'
            }
        } elseif (Test-Path -LiteralPath $slot.OriginalPath) { throw 'O aplicativo criou uma pasta durante o backup. Feche-o e tente novamente.' }
    }
    Assert-AppClosed $Profile
    $manifest = [pscustomobject]@{
        Schema=$(if(@($slots | Where-Object {Get-SourceMapping $_}).Count){2}else{1}); Tool='Cofre-IA'; ToolVersion=$script:Version; Id=$id; AppId=$Profile.Id
        AppName=$Profile.Name; Kind=$Kind; CreatedUtc=(Get-Date).ToUniversalTime().ToString('o')
        Machine=[Environment]::MachineName; User=[Environment]::UserName
        Bytes=$bytes; ScopeNote=$Profile.Notes; Slots=@($slots); Excluded=@(Get-ScopeExclusions $Profile $Roots)
        Validation='SHA256 de todos os arquivos. Leitura no aplicativo não testada pelo script.'
    }
    $manifestPath = Join-Path $working 'manifesto.json'
    Write-NewJson $manifestPath $manifest
    Write-NewText (Join-Path $working 'manifesto.sha256') (Hash-File $manifestPath)
    Write-NewText (Join-Path $working 'CONCLUIDO') $id
    [void](Test-Snapshot $working)
    [IO.Directory]::Move($working, $final)
    Write-Log "BACKUP verificado | $final | bytes=$bytes"
    return $final
}

function Test-Snapshot {
    param([string]$Path)
    $pathFull = Full-Path $Path
    if (!(Is-Within $pathFull $script:BackupBase) -or $pathFull -eq (Full-Path $script:BackupBase)) {
        throw 'O backup deve estar na pasta Backups deste script. Copie a pasta completa do cofre ao trocar de unidade.'
    }
    Assert-NoReparse $pathFull
    $manifestPath = Join-Path $pathFull 'manifesto.json'
    foreach ($name in @('manifesto.json','manifesto.sha256','CONCLUIDO')) {
        if (!(Test-Path -LiteralPath (Join-Path $pathFull $name) -PathType Leaf)) { throw 'Backup incompleto: faltam metadados de conclusão.' }
        Assert-NoReparse (Join-Path $pathFull $name)
    }
    $expectedHash = [IO.File]::ReadAllText((Join-Path $pathFull 'manifesto.sha256')).Trim()
    if ($expectedHash -notmatch '^[a-f0-9]{64}$' -or (Hash-File $manifestPath) -ne $expectedHash) {
        throw 'O manifesto foi alterado ou corrompido. Restauração bloqueada.'
    }
    $manifest = Read-Json $manifestPath
    if ($manifest.Schema -notin @(1,2) -or $manifest.Tool -ne 'Cofre-IA' -or $manifest.Id -notmatch '^\d{8}T\d{9}Z-[a-f0-9]{8}$' -or
        $manifest.Kind -notin @('Manual','AntesDeRestaurar') -or $manifest.AppId -notmatch '^[a-z0-9-]{1,64}$') {
        throw 'Formato de backup não suportado.'
    }
    if ([IO.File]::ReadAllText((Join-Path $pathFull 'CONCLUIDO')).Trim() -ne $manifest.Id) { throw 'Marcador de conclusão divergente.' }
    $payload = Join-Path $pathFull 'dados'
    Assert-NoReparse $payload
    $keys = @{}
    $expectedFolders = @()
    foreach ($slot in @($manifest.Slots)) {
        if ($slot.Key -notmatch '^[a-z0-9][a-z0-9-]{0,79}$' -or $keys.ContainsKey($slot.Key) -or $slot.Exists -isnot [bool]) {
            throw 'Pasta de dados inválida no manifesto.'
        }
        $keys[$slot.Key] = $true
        $rootType=Get-DataType $slot
        if($rootType -notin @('File','Directory')){throw 'Invalid snapshot data type.'}
        $mapping=Get-SourceMapping $slot
        if($rootType -eq 'File' -and (!$mapping -or $manifest.Schema -ne 2)){throw 'File units require scoped schema 2.'}
        if($mapping){
            if($manifest.Schema -ne 2 -or $manifest.AppId -ne 'codex' -or $mapping.ParentKey -ne 'codex-engine'){throw 'Invalid scoped snapshot.'}
            Assert-Relative $mapping.Relative
            if($mapping.Relative -match '[\\/]' -or $slot.Key -cne (Get-UnitKey $mapping.ParentKey $mapping.Relative)){throw 'Invalid unit mapping.'}
            if(($rootType -eq 'File' -and !(Test-CodexFileName $mapping.Relative)) -or
               ($rootType -eq 'Directory' -and $mapping.Relative -notin @(Get-CodexDirectories))){throw 'Unknown conversation data unit.'}
        }
        if($rootType -eq 'File' -and $slot.Exists -and (@($slot.Items).Count -ne 1 -or $slot.Items[0].Path -cne 'file' -or $slot.Items[0].Kind -ne 'File')){throw 'Invalid file-unit payload.'}
        $paths = @{}
        foreach ($entry in @($slot.Items)) {
            Assert-Relative $entry.Path
            if ($paths.ContainsKey($entry.Path) -or $entry.Kind -notin @('File','Directory') -or [long]$entry.Length -lt 0) {
                throw 'Entrada inválida ou duplicada no inventário.'
            }
            $paths[$entry.Path] = $true
            if ($entry.Kind -eq 'File' -and $entry.Hash -notmatch '^[a-f0-9]{64}$') { throw 'Hash inválido no inventário.' }
            if ($entry.Kind -eq 'Directory' -and ([long]$entry.Length -ne 0 -or $entry.Hash -ne '')) { throw 'Diretório inválido no inventário.' }
            [void][datetime]::Parse($entry.Utc)
        }
        if ($slot.Exists) {
            $expectedFolders += $slot.Key
            $actual = @(Get-Inventory (Join-Path $payload $slot.Key))
            if (!(Compare-Inventory @($slot.Items) $actual)) { throw "Arquivos ausentes, extras ou diferentes no backup: $($slot.Key)" }
        } elseif (@($slot.Items).Count -gt 0) { throw 'Uma pasta ausente não pode conter arquivos no inventário.' }
    }
    $actualFolders = @(Get-ChildItem -LiteralPath $payload -Force)
    if ($actualFolders.Count -ne $expectedFolders.Count) { throw 'Conteúdo inesperado na raiz dos dados do backup.' }
    foreach ($folder in $actualFolders) {
        if (!$folder.PSIsContainer -or $folder.Name -notin $expectedFolders) { throw 'Conteúdo inesperado no backup.' }
    }
    return $manifest
}

# -----------------------------------------------------------------------------
# Restauração transacional: diário gravado antes das trocas, originais preservados.
# -----------------------------------------------------------------------------

function Get-RestorePlan {
    param($Profile, $Manifest)
    if ($Manifest.AppId -ne $Profile.Id) { throw 'Não é possível restaurar o backup em outro aplicativo.' }
    $roots = @(Resolve-Roots $Profile)
    $plan = @()
    foreach ($slot in @($Manifest.Slots)) {
        if (!$slot.Exists -and $Manifest.Kind -ne 'AntesDeRestaurar' -and !(Get-SourceMapping $slot)) { continue }
        $target = @(if(Get-SourceMapping $slot){Resolve-UnitMapping $Profile $slot}else{$roots | Where-Object { $_.Key -eq $slot.Key }})
        if ($target.Count -ne 1) { throw "O local '$($slot.Key)' não está na configuração atual. Restaure o mapeamento antes de continuar." }
        Assert-SourcePath $target[0].Path -AllowFile:((Get-DataType $slot) -eq 'File')
        $plan += [pscustomobject]@{ Key=$slot.Key; Path=$target[0].Path; Slot=$slot }
    }
    # A scoped restore returns the entire selected data scope to its snapshot date.
    # Include database files created later as absent targets, with a safety copy.
    if($Manifest.Schema -eq 2 -and $Profile.Id -eq 'codex'){
        $keys=@($plan | ForEach-Object Key)
        foreach($unit in @(Expand-BackupRoots $Profile @(Resolve-Roots $Profile))){
            if(!(Get-SourceMapping $unit) -or $unit.Key -in $keys -or !(Test-Path -LiteralPath $unit.Path)){continue}
            $slot=[pscustomobject]@{Key=$unit.Key;OriginalPath=$unit.Path;Exists=$false;Items=@();RootType=$unit.RootType;SourceMapping=$unit.SourceMapping}
            $plan += [pscustomobject]@{Key=$unit.Key;Path=$unit.Path;Slot=$slot}
        }
    }
    if ($plan.Count -eq 0) { throw 'O backup não contém pastas restauráveis.' }
    return $plan
}

function Save-Journal {
    param($Journal, [string]$Directory)
    $Journal.Sequence = [int]$Journal.Sequence + 1
    $name = '{0:D6}.json' -f $Journal.Sequence
    Write-NewJson (Join-Path $Directory $name) $Journal
}

function Read-Journal {
    param([string]$Directory)
    Assert-NoReparse $Directory
    $files = @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File | Sort-Object Name -Descending)
    foreach ($file in $files) {
        try {
            $journal = Read-Json $file.FullName
            if ($journal.Schema -in @(1,2) -and $journal.Id -eq (Split-Path $Directory -Leaf)) { return $journal }
        } catch { continue }
    }
    throw "Não foi possível ler o diário: $Directory. Não altere as pastas .cofre-*; elas preservam os dados."
}

function Assert-Journal {
    param($Journal, $Profile)
    if ($Journal.Id -notmatch '^[a-f0-9]{32}$' -or $Journal.AppId -ne $Profile.Id) { throw 'Diário de restauração inválido.' }
    $roots = @(Resolve-Roots $Profile)
    $seen = @{}
    foreach ($entry in @($Journal.Entries)) {
        if ($seen.ContainsKey($entry.Key)) { throw 'Entrada duplicada no diário.' }
        $seen[$entry.Key] = $true
        $root = @(if(Get-SourceMapping $entry){Resolve-UnitMapping $Profile $entry}else{$roots | Where-Object { $_.Key -eq $entry.Key }})
        if ($root.Count -ne 1 -or (Full-Path $root[0].Path) -ne (Full-Path $entry.Target)) {
            throw 'O mapeamento do perfil mudou. Restaure a configuração original para recuperar a transação.'
        }
        $parent = [IO.Path]::GetDirectoryName($entry.Target)
        $prefix = '.cofre-' + $Journal.Id + '-' + $entry.Key
        foreach ($pair in @(@('Stage','-novo'), @('Old','-anterior'), @('Removed','-retirado'))) {
            $property = [string]$pair[0]
            $expected = Join-Path $parent ($prefix + $pair[1])
            if ((Full-Path $entry.$property) -ne (Full-Path $expected)) { throw 'Caminho inesperado no diário.' }
            Assert-NoReparse $entry.$property
        }
        Assert-SourcePath $entry.Target -AllowFile:((Get-DataType $entry) -eq 'File')
    }
}

function Recover-TransactionInternal {
    param($Profile, $Journal, [string]$Directory)
    Assert-Journal $Journal $Profile
    Stop-AppForDataOperation $Profile
    Assert-AppClosed $Profile
    # Resolve relativamente ao cofre atual, inclusive depois de movê-lo de unidade.
    $safetyId = Split-Path $Journal.SafetyBackup -Leaf
    $safetyPath = Child-Path $script:BackupBase ($Profile.Id + '/' + $safetyId)
    $safetyManifest = Test-Snapshot $safetyPath
    if ($safetyManifest.AppId -ne $Profile.Id -or $safetyManifest.Kind -ne 'AntesDeRestaurar') {
        throw 'Backup de retorno incompatível com a transação.'
    }
    $script:CancelAllowed = $false
    try {
        $Journal.State = 'Revertendo'
        Save-Journal $Journal $Directory
        $entries = @($Journal.Entries)
        [array]::Reverse($entries)
        foreach ($entry in $entries) {
            Assert-AppClosed $Profile
            $targetExists = Test-Path -LiteralPath $entry.Target
            $oldExists = Test-Path -LiteralPath $entry.Old
            if ($oldExists) {
                if ($targetExists) {
                    if (Test-Path -LiteralPath $entry.Removed) { throw 'Há dados já preservados na pasta de retirada. Recuperação manual necessária.' }
                    Move-DataEntry $entry.Target $entry.Removed
                }
                Move-DataEntry $entry.Old $entry.Target
            } elseif (!$entry.HadOriginal -and $targetExists -and $entry.Phase -in @('Instalando','Aplicado')) {
                if (Test-Path -LiteralPath $entry.Removed) { throw 'Pasta de retirada já existe; nenhum dado foi sobrescrito.' }
                Move-DataEntry $entry.Target $entry.Removed
            } elseif ($entry.HadOriginal -and !$targetExists) {
                throw "O original não foi localizado em $($entry.Target). Use o backup de retorno: $($Journal.SafetyBackup)"
            }
            $entry.Phase = 'Revertido'
            Save-Journal $Journal $Directory
        }
        foreach ($entry in @($Journal.Entries)) {
            $savedSlots = @($safetyManifest.Slots | Where-Object { $_.Key -eq $entry.Key })
            if ($savedSlots.Count -ne 1) { throw 'O backup de retorno não cobre todos os destinos.' }
            $slot = $savedSlots[0]
            if ($slot.Exists) {
                if (!(Compare-Inventory @($slot.Items) @(Get-DataInventory $entry.Target (Get-DataType $slot)))) {
                    throw "A reversão não corresponde ao backup de retorno: $($entry.Target)"
                }
            } elseif (Test-Path -LiteralPath $entry.Target) {
                throw "A pasta deveria estar ausente após a reversão: $($entry.Target)"
            }
        }
        Assert-AppClosed $Profile
        $Journal.State = 'Revertido'
        Save-Journal $Journal $Directory
        Write-Log "TRANSACAO revertida | $($Journal.Id)"
    } finally { $script:CancelAllowed = $true }
}

function Get-PendingTransactions {
    if (!(Test-Path -LiteralPath $script:JournalBase)) { return }
    foreach ($dir in @(Get-ChildItem -LiteralPath $script:JournalBase -Directory -Force)) {
        if ($dir.Name -notmatch '^[a-f0-9]{32}$') { continue }
        $journal = Read-Journal $dir.FullName
        if ($journal.State -notin @('Concluido','Revertido','Cancelado')) {
            [pscustomobject]@{ Directory=$dir.FullName; Journal=$journal }
        }
    }
}

function Restore-SnapshotInternal {
    param($Profile, [string]$Path, [switch]$TestConfirmed, [int]$InjectFailureAfter=0)
    if (($TestConfirmed -or $InjectFailureAfter -gt 0) -and !$script:TestMode) { throw 'Parâmetros internos reservados ao autoteste isolado.' }
    # Autoteste disponível no menu Ferramentas; sem executar testes a cada restauração.
    if (@(Get-PendingTransactions).Count -gt 0) { throw 'Existe uma restauração interrompida. Use Recuperar operação interrompida antes de iniciar outra.' }
    $manifest = Test-Snapshot $Path
    if ($manifest.AppId -ne $Profile.Id) { throw 'Backup belongs to another application.' }
    Stop-AppForDataOperation $Profile
    Assert-AppClosed $Profile
    $plan = @(Get-RestorePlan $Profile $manifest)
    Write-Line ''
    Write-Line ((L 'restore')+': '+$Profile.Name+' | '+$manifest.CreatedUtc) Cyan
    Show-ProfileScope $Profile
    Write-Line (L 'restorewarning') Yellow
    foreach ($entry in $plan) {
        $action = if((Get-DataType $entry.Slot) -eq 'File'){L 'replacefile'}else{L 'replacefolder'}
        if (!$entry.Slot.Exists) { $action = (L 'removeitem') }
        Write-Line ("  $action -> $($entry.Path)")
        if ($entry.Path -ne $entry.Slot.OriginalPath) { Write-Line ("    Origem do backup: $($entry.Slot.OriginalPath)") DarkYellow }
    }
    if (!$TestConfirmed) {
        Write-Line (L 'versionwarning') Yellow
        if (!(Confirm-RestoreChoice)) { Set-VaultOperationCanceled; return }
    }
    Assert-AppClosed $Profile
    $roots = @($plan | ForEach-Object { [pscustomobject]@{ Key=$_.Key; Path=$_.Path; RootType=(Get-DataType $_.Slot); SourceMapping=(Get-SourceMapping $_.Slot) } })
    Write-Line (L 'creating_safety') Cyan
    $safety = New-Snapshot $Profile $roots 'AntesDeRestaurar'
    $safetyManifest = Test-Snapshot $safety
    $id = [guid]::NewGuid().ToString('N')
    $journalDir = Join-Path $script:JournalBase $id
    Ensure-Directory $journalDir
    $journal = [pscustomobject]@{
        Schema=$manifest.Schema; Id=$id; AppId=$Profile.Id; Sequence=0; State='Preparando'
        SourceBackup=(Full-Path $Path); SafetyBackup=$safety; Entries=@()
    }
    foreach ($entry in $plan) {
        $parent = [IO.Path]::GetDirectoryName($entry.Path)
        $prefix = '.cofre-' + $id + '-' + $entry.Key
        $journal.Entries += [pscustomobject]@{
            Key=$entry.Key; Target=$entry.Path; RootType=(Get-DataType $entry.Slot); SourceMapping=(Get-SourceMapping $entry.Slot); Stage=(Join-Path $parent ($prefix + '-novo'))
            Old=(Join-Path $parent ($prefix + '-anterior')); Removed=(Join-Path $parent ($prefix + '-retirado'))
            HadOriginal=[bool](Test-Path -LiteralPath $entry.Path); DesiredExists=[bool]$entry.Slot.Exists; Phase='Preparando'
        }
    }
    Save-Journal $journal $journalDir
    $committed = 0
    try {
        # Soma por unidade: várias pastas no mesmo disco precisam caber simultaneamente.
        $driveBytes = @{}
        foreach ($entry in $plan) {
            $driveName = [IO.Path]::GetPathRoot($entry.Path)
            if (!$driveBytes.ContainsKey($driveName)) { $driveBytes[$driveName] = [long]0 }
            foreach ($item in @($entry.Slot.Items)) { $driveBytes[$driveName] += [long]$item.Length }
        }
        foreach ($driveName in $driveBytes.Keys) { Assert-Space $driveName $driveBytes[$driveName] }
        for ($i=0; $i -lt $plan.Count; $i++) {
            $entry = $journal.Entries[$i]
            Ensure-Directory ([IO.Path]::GetDirectoryName($entry.Target))
            if ($entry.DesiredExists) {
                Copy-PayloadToStage (Join-Path (Join-Path $Path 'dados') $entry.Key) $entry.Stage $plan[$i].Slot
                if (!(Compare-Inventory @($plan[$i].Slot.Items) @(Get-DataInventory $entry.Stage (Get-DataType $plan[$i].Slot)))) { throw 'A cópia de preparação divergiu do backup.' }
            }
        }
        Assert-Journal $journal $Profile
        # O destino precisa continuar igual ao backup de retorno que acabamos de validar.
        foreach ($slot in @($safetyManifest.Slots)) {
            $target = @($plan | Where-Object { $_.Key -eq $slot.Key })[0].Path
            if ($slot.Exists) {
                if (!(Compare-Inventory @($slot.Items) @(Get-DataInventory $target (Get-DataType $slot)))) { throw 'O destino mudou durante a preparação. Nenhuma troca será iniciada.' }
            } elseif (Test-Path -LiteralPath $target) { throw 'Uma pasta apareceu durante a preparação. Nenhuma troca será iniciada.' }
        }
        Assert-AppClosed $Profile
        Check-Cancel
        $script:CancelAllowed = $false
        $journal.State = 'Aplicando'
        Save-Journal $journal $journalDir
        foreach ($entry in @($journal.Entries)) {
            Assert-AppClosed $Profile
            Assert-NoReparse $entry.Target
            $entry.Phase = 'GuardandoOriginal'
            Save-Journal $journal $journalDir
            if ($entry.HadOriginal) { Move-DataEntry $entry.Target $entry.Old }
            $entry.Phase = 'Instalando'
            Save-Journal $journal $journalDir
            if ($entry.DesiredExists) { Move-DataEntry $entry.Stage $entry.Target }
            $entry.Phase = 'Aplicado'
            Save-Journal $journal $journalDir
            $committed++
            if ($InjectFailureAfter -gt 0 -and $committed -eq $InjectFailureAfter) { throw 'Falha simulada para testar reversão.' }
        }
        foreach ($entry in $plan) {
            if ($entry.Slot.Exists) {
                if (!(Compare-Inventory @($entry.Slot.Items) @(Get-DataInventory $entry.Path (Get-DataType $entry.Slot)))) { throw 'A verificação final do destino falhou.' }
            } elseif (Test-Path -LiteralPath $entry.Path) { throw 'O destino deveria estar ausente após o retorno.' }
        }
        Assert-AppClosed $Profile
        $journal.State = 'Concluido'
        Save-Journal $journal $journalDir
        Write-Log "RESTAURACAO arquivos verificados | $($Profile.Id) | retorno=$safety | transacao=$id"
        Write-Line (L 'restored') Green
        Write-Line ("Backup para voltar ao estado anterior: $safety") Cyan
        Write-Line 'As pastas anteriores também foram preservadas ao lado dos dados, com prefixo .cofre-.' DarkGray
    } catch {
        $failure = $_
        Write-Log "RESTAURACAO interrompida | $($failure.Exception.Message) | $id"
        try {
            Recover-Transaction $Profile $journal $journalDir
            Write-Line 'Operação interrompida; as trocas foram revertidas. Os arquivos de preparação e retorno foram preservados.' Yellow
        } catch {
            Write-Line ("A reversão não terminou: $($_.Exception.Message)") Red
            Write-Line ("Não abra o aplicativo. Use Recuperar operação interrompida. Backup de retorno: $safety") Yellow
        }
        throw $failure
    } finally { $script:CancelAllowed = $true }
}

# -----------------------------------------------------------------------------
# Diagnóstico não modifica os dados dos aplicativos.
# -----------------------------------------------------------------------------

function New-Snapshot {
    param($Profile,[object[]]$Roots,[ValidateSet('Manual','AntesDeRestaurar')][string]$Kind='Manual')
    Invoke-VaultOperation $Profile (L 'working_backup') { New-SnapshotInternal $Profile $Roots $Kind }
}
function Restore-Snapshot {
    param($Profile,[string]$Path,[switch]$TestConfirmed,[int]$InjectFailureAfter=0)
    Invoke-VaultOperation $Profile (L 'working_restore') { Restore-SnapshotInternal $Profile $Path -TestConfirmed:$TestConfirmed -InjectFailureAfter $InjectFailureAfter }
}
function Recover-Transaction {
    param($Profile,$Journal,[string]$Directory)
    Invoke-VaultOperation $Profile (L 'working_recover') { Recover-TransactionInternal $Profile $Journal $Directory }
}
