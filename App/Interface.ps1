function List-Snapshots {
    param($Profile)
    $parent = Join-Path $script:BackupBase $Profile.Id
    if (!(Test-Path -LiteralPath $parent)) { return }
    Assert-NoReparse $parent
    foreach ($dir in @(Get-ChildItem -LiteralPath $parent -Directory | Sort-Object Name -Descending)) {
        if ($dir.Name -notmatch '^\d{8}T\d{9}Z-[a-f0-9]{8}$') { continue }
        try {
            Assert-NoReparse $dir.FullName
            if (!(Test-Path -LiteralPath (Join-Path $dir.FullName 'CONCLUIDO') -PathType Leaf)) { continue }
            $manifest = Read-Json (Join-Path $dir.FullName 'manifesto.json')
            if ($manifest.AppId -ne $Profile.Id -or $manifest.Id -ne $dir.Name) { continue }
            [pscustomobject]@{ Path=$dir.FullName; Date=$manifest.CreatedUtc; Kind=$manifest.Kind; Bytes=[long]$manifest.Bytes }
        } catch { Write-Line ("Backup com metadados ilegíveis: $($dir.Name)") Yellow }
    }
}

function Choose-Snapshot {
    param($Profile, [switch]$OnlySafety, [string]$PurposeKey='restore')
    Show-Header (L $PurposeKey)
    Write-Line ('  '+$Profile.Name) Cyan
    Write-Line ''
    $list = @(List-Snapshots $Profile)
    if ($OnlySafety) { $list = @($list | Where-Object { $_.Kind -eq 'AntesDeRestaurar' }) }
    if ($list.Count -eq 0) { Write-Line (L 'nobackup') Yellow; return $null }
    for ($i=0; $i -lt $list.Count; $i++) {
        $label = (L 'manual')
        if ($list[$i].Kind -eq 'AntesDeRestaurar') { $label = (L 'safety') }
        $date = [datetime]::Parse($list[$i].Date).ToLocalTime().ToString('dd/MM/yyyy HH:mm:ss')
        Write-Line ('  {0,2}. {1} | {2} | {3}' -f ($i+1), $date, $label, (Format-Bytes $list[$i].Bytes))
    }
    Write-Line ('   0. '+(L 'back'))
    while ($true) {
        $choice=Read-Host (L 'backup_choice')
        if (!$choice -or $choice -eq '0') { Write-Line (L 'selection_cancelled') Yellow; return $null }
        $number = 0
        if ([int]::TryParse($choice, [ref]$number) -and $number -ge 1 -and $number -le $list.Count) {
            return $list[$number-1].Path
        }
        Write-Line (L 'invalid_backup') Yellow
    }
}

function Confirm-RestoreChoice {
    Write-Line ''
    Write-Line (L 'restore_hint') Cyan
    Write-Line ''
    Write-Line ('   1. '+(L 'restore_apply')) Green
    Write-Line ('   0. '+(L 'cancel')) DarkGray
    while ($true) {
        $choice=Read-Host (L 'option')
        if ($choice -eq '1') { return $true }
        if (!$choice -or $choice -eq '0') { return $false }
        Write-Line (L 'invalid') Yellow
    }
}

function Backup-All {
    Ensure-Directory $script:LogBase
    $results = @()
    foreach ($profile in $script:Profiles) {
        Write-Line ("BACKUP | $($profile.Name)") Cyan
        Show-ProfileScope $profile
        try {
            $roots = @(Get-BackupRoots $profile)
            $present = @($roots | Where-Object { Test-Path -LiteralPath $_.Path -PathType Container })
            if ($present.Count -eq 0) { $results += [pscustomobject]@{ App=$profile.Name; Status=(L 'absent'); Path='' }; continue }
            $path = New-Snapshot $profile $roots
            $results += [pscustomobject]@{ App=$profile.Name; Status=(L 'verified'); Path=$path }
        } catch [OperationCanceledException] { throw } catch {
            $results += [pscustomobject]@{ App=$profile.Name; Status=('Não concluído: ' + $_.Exception.Message); Path='' }
        }
    }
    $results | Format-Table App, Status -Wrap -AutoSize | Out-Host
    Write-NewJson (Join-Path $script:LogBase ('backup-summary-' + [guid]::NewGuid().ToString('N') + '.json')) $results
    Write-Line (L 'allresult') Yellow
}

function Configure-Roots {
    $profile = Choose-Profile
    if (!$profile) { return }
    Write-Line (L 'customwarning') Yellow
    Show-ProfileScope $profile
    $path = (Read-Host (L 'folderprompt')).Trim().Trim('"')
    if (!$path) { return }
    Assert-SourcePath $path
    if (!(Test-Path -LiteralPath $path -PathType Container)) { throw 'A pasta precisa existir para ser cadastrada pelo menu.' }
    $newKey = 'extra-' + [guid]::NewGuid().ToString('N').Substring(0,12)
    $oldRoots = @($profile.Roots)
    try {
        $profile.Roots = @($oldRoots) + @((New-Root $newKey (Full-Path $path)))
        [void](Resolve-Roots $profile)
        Validate-Profiles $script:Profiles
        $value = [pscustomobject]@{ Schema=1; Profiles=@($script:Profiles) }
        $temp = $script:ConfigPath + '.' + [guid]::NewGuid().ToString('N') + '.novo'
        Write-NewJson $temp $value
        if (Test-Path -LiteralPath $script:ConfigPath) {
            $old = $script:ConfigPath + '.' + (Get-Date).ToString('yyyyMMddHHmmssfff') + '.anterior'
            [IO.File]::Replace($temp, $script:ConfigPath, $old)
        } else { [IO.File]::Move($temp, $script:ConfigPath) }
        Write-Line (L 'saved') Green
    } catch { $profile.Roots=$oldRoots; throw }
}

function Export-SnapshotInternal {
    param($Profile, [string]$Path)
    $manifest = Test-Snapshot $Path
    if ($manifest.AppId -ne $Profile.Id) { throw 'Backup de outro aplicativo.' }
    $destination = Join-Path (Join-Path $script:BackupBase 'Exports') ($Profile.Id + '-' + [guid]::NewGuid().ToString('N'))
    Ensure-Directory ([IO.Path]::GetDirectoryName($destination))
    Assert-Space $destination ([long]$manifest.Bytes)
    Copy-CheckedTree (Join-Path $Path 'dados') $destination @(Get-Inventory (Join-Path $Path 'dados'))
    Write-Line ("Cópia extraída para inspeção, sem alterar o aplicativo: $destination") Green
}

function Show-Help {
    foreach($key in @('closeapp','restorewarning','repairwarning','nospecificrepair','portable','localonly','privacy','technical')){
        Write-Line (L $key); Write-Line ''
    }
    Write-Line 'README.md / README.pt-BR.md / App/Docs' Cyan
}

function Show-Header {
    param([string]$Page='')
    if(!$Page){$Page=L 'home'}
    try { Clear-Host } catch { Write-Line '' }
    Write-Line '  ==============================================================' DarkCyan
    Write-Line ('    AI CHAT VAULT  |  '+(L 'subtitle')) Cyan
    Write-Line ('    '+$Page+'  |  v'+$script:Version+'  |  '+$script:LanguageNames[$script:Language]) White
    Write-Line ('  '+(L 'session' @($script:SessionId,$script:Started.ToString('g',$script:DisplayCulture)))) DarkGray
    Write-Line ('  '+(L 'now' @((Get-Date).ToString('F',$script:DisplayCulture)))) DarkGray
    Write-Line ('  Backups: '+$script:BackupBase) DarkGray
    if(@(Get-PendingTransactions).Count){Write-Line (L 'pending') Yellow}
    Write-Line ''
}

function Show-ProfileRow {
    param($Profile,[int]$Number)
    $state='absent'
    try{if(Test-ProfileData $Profile){$state='found'}}catch{$state='review'}
    Write-Line ('  {0,2}. {1} ({2})' -f $Number,$Profile.Name,$Profile.Company) $Profile.Color
    Write-Line ('      '+(L $Profile.DescriptionKey)) Gray
    Write-Line ('      '+(L $state)) $(if($state -eq 'found'){'Green'}elseif($state -eq 'review'){'Yellow'}else{'DarkGray'})
    Write-Line ''
}

function Read-ProfileChoice {
    # Arrow keys are consumed immediately; numeric selections still require Enter.
    # Redirected input/non-console hosts retain the line-based N/P fallback.
    if ([Console]::IsInputRedirected -or $Host.Name -ne 'ConsoleHost') {
        return (Read-Host (L 'app'))
    }
    Write-Host ((L 'app')+': ') -NoNewline
    $digits=''
    while ($true) {
        $key=[Console]::ReadKey($true)
        switch ($key.Key) {
            'RightArrow' { [Console]::WriteLine(); return 'n' }
            'LeftArrow'  { [Console]::WriteLine(); return 'p' }
            'N'         { [Console]::WriteLine(); return 'n' }
            'P'         { [Console]::WriteLine(); return 'p' }
            'Escape'    { [Console]::WriteLine(); return '0' }
            'Enter'     { [Console]::WriteLine(); return $digits }
            'Backspace' {
                if ($digits.Length) {
                    $digits=$digits.Substring(0,$digits.Length-1)
                    [Console]::Write("`b `b")
                }
            }
            default {
                if ($key.KeyChar -match '^[0-9]$' -and $digits.Length -lt 2) {
                    $digits += $key.KeyChar
                    [Console]::Write([string]$key.KeyChar)
                }
            }
        }
    }
}

function Choose-Profile {
    $page=0;$size=10;$pages=[int][Math]::Ceiling($script:Profiles.Count/[double]$size)
    while($true){
        Show-Header (L 'app')
        for($i=$page*$size;$i -lt [Math]::Min(($page+1)*$size,$script:Profiles.Count);$i++){
            Show-ProfileRow $script:Profiles[$i] ($i+1)
        }
        Write-Line (L 'page' @(($page+1),$pages)) DarkCyan
        Write-Line (L 'page_hint') DarkGray
        Write-Line ('   0. '+(L 'back')) DarkGray
        $choice=Read-ProfileChoice
        if($choice -eq '0' -or !$choice){return $null}
        if($choice -eq 'n'){$page=($page+1)%$pages;continue}
        if($choice -eq 'p'){$page=($page+$pages-1)%$pages;continue}
        $number=0
        if([int]::TryParse($choice,[ref]$number) -and $number -ge 1 -and $number -le $script:Profiles.Count){return $script:Profiles[$number-1]}
        Write-Line (L 'invalid') Yellow
    }
}

function Wait-Menu {
    Write-Line '';[void](Read-Host (L 'enter'))
}

function Run-ToolsMenu {
    while($true){
        Show-Header (L 'tools')
        Write-Line ('   1. '+(L 'verify'))
        Write-Line ('   2. '+(L 'safety'))
        Write-Line ('   3. '+(L 'recover'))
        Write-Line ('   4. '+(L 'extract'))
        Write-Line ('   5. '+(L 'custom'))
        Write-Line ('   6. '+(L 'sqlite'))
        Write-Line ('   7. '+(L 'test'))
        Write-Line ('   8. '+(L 'help'))
        Write-Line ('   0. '+(L 'back')) DarkGray
        $choice=Read-Host (L 'option')
        if($choice -eq '0'){return}
        try{
            if($choice -in @('1','2','4','6')){
                $profile=Choose-Profile;if(!$profile){continue}
                if($choice -eq '6'){Show-Diagnostic $profile -CheckDatabases}
                else{
                    $purpose=switch($choice){'1'{'verify'}'2'{'safety'}'4'{'extract'}}
                    $path=Choose-Snapshot $profile -OnlySafety:($choice -eq '2') -PurposeKey $purpose;if(!$path){continue}
                    switch($choice){
                        '1'{Invoke-VaultOperation $profile (L 'working_verify') { [void](Test-Snapshot $path) };Write-Line (L 'verified') Green}
                        '2'{Restore-Snapshot $profile $path}
                        '4'{Export-Snapshot $profile $path}
                    }
                }
            }elseif($choice -eq '3'){
                $pending=@(Get-PendingTransactions)
                if(!$pending.Count){Write-Line (L 'nopending') Green}
                foreach($item in $pending){
                    $profile=Get-Profile $item.Journal.AppId
                    Write-Line ("$($profile.Name): $($item.Journal.State)") Yellow
                    if((Read-Host (L 'confirm' @('REVERTER'))) -ceq 'REVERTER'){Recover-Transaction $profile $item.Journal $item.Directory;Write-Line (L 'restored') Green}
                }
            }elseif($choice -eq '5'){Configure-Roots}
            elseif($choice -eq '7'){Invoke-SelfTest}
            elseif($choice -eq '8'){Show-Help}
            else{Write-Line (L 'invalid') Yellow}
        }catch{Show-OperationError $_}
        Wait-Menu
    }
}

function Run-Menu {
    while($true){
        Show-Header
        Write-Line ('   1. '+(L 'backup')) White
        Write-Line ('   2. '+(L 'restore')) White
        Write-Line ('   3. '+(L 'repair')) White
        Write-Line ('   4. '+(L 'tools')) Gray
        Write-Line ('   5. '+(L 'language')+$(if($script:Language -ne 'en'){' / Language'}else{''})) Cyan
        Write-Line ('   0. '+(L 'exit')) DarkGray
        Write-Line ''
        $choice=Read-Host (L 'option')
        if($choice -eq '0'){return}
        try{
            if($choice -eq '4'){Run-ToolsMenu;continue}
            if($choice -eq '5'){Select-Language;continue}
            if($choice -notin @('1','2','3')){Write-Line (L 'invalid') Yellow;Wait-Menu;continue}
            Show-Header $(switch($choice){'1'{(L 'backup')}'2'{(L 'restore')}'3'{(L 'repair')}})
            if($choice -eq '1'){
                Write-Line ('   1. '+(L 'one'))
                Write-Line ('   2. '+(L 'all'))
                Write-Line ('   0. '+(L 'back')) DarkGray
                $scope=Read-Host (L 'backup')
                if($scope -eq '0'){continue}
                if($scope -eq '2'){Backup-All;Wait-Menu;continue}
                if($scope -ne '1'){continue}
            }
            $profile=Choose-Profile;if(!$profile){continue}
            switch($choice){
                '1'{Show-ProfileScope $profile;$result=New-Snapshot $profile @(Resolve-Roots $profile);Write-Line (L 'done' @($result)) Green}
                '2'{$path=Choose-Snapshot $profile;if($path){Restore-Snapshot $profile $path}}
                '3'{
                    Write-Line ('   1. '+(L 'diagnose'))
                    if($profile.Id -eq 'antigravity'){Write-Line ('   2. '+(L 'agrepair'))}
                    Write-Line ('   0. '+(L 'back')) DarkGray
                    $action=Read-Host (L 'option')
                    if($action -eq '1'){Show-Diagnostic $profile}
                    elseif($action -eq '2' -and $profile.Id -eq 'antigravity'){Invoke-AppRepair $profile}
                }
            }
        }catch{Show-OperationError $_}
        finally{Suspend-VaultProgress}
        Wait-Menu
    }
}

function Export-Snapshot {
    param($Profile,[string]$Path)
    Invoke-VaultOperation $Profile (L 'working_extract') { Export-SnapshotInternal $Profile $Path }
}
