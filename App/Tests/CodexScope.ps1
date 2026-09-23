$ErrorActionPreference='Stop'
. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'AI-Chat-Vault.ps1') -Idioma en
$root=Join-Path ([IO.Path]::GetTempPath()) ('scoped-fixture-'+[guid]::NewGuid().ToString('N'))
Ensure-Directory $root
$script:Base=Join-Path $root 'vault'
$script:BackupBase=Join-Path $script:Base 'Backups'
$script:JournalBase=Join-Path $script:BackupBase '_transactions'
$script:LogBase=Join-Path $script:Base 'reports'
$script:LogPath=$null;$script:TestMode=$true
$engine=Join-Path $root 'codex'
$external=Join-Path $root 'external-data'
Ensure-Directory $engine;Ensure-Directory $external
Ensure-Directory (Join-Path $engine 'sessions/2026')
Ensure-Directory (Join-Path $engine 'attachments')
Ensure-Directory (Join-Path $engine 'plugins/cache')
Write-NewText (Join-Path $engine 'sessions/2026/chat.jsonl') '{"title":"Preserve — Anime TV"}'
Write-NewText (Join-Path $engine 'attachments/image.txt') 'attachment'
Write-NewText (Join-Path $engine 'state_5.sqlite') 'opaque-state-original'
Write-NewText (Join-Path $engine '.codex-global-state.json') '{"title":"Current title"}'
Write-NewText (Join-Path $external 'DO-NOT-COPY.txt') 'external sentinel'
[void](New-Item -ItemType Junction -Path (Join-Path $engine 'plugins/cache/latest') -Target $external)
$profile=New-Profile 'codex' 'Codex fixture' @('fake.exe') '' @((New-Root 'codex-engine' $engine)) 'Fixture scoped data'
$snapshot=New-Snapshot $profile @(Resolve-Roots $profile)
$manifest=Test-Snapshot $snapshot
Assert-Test ($manifest.Schema -eq 2) 'Expected scoped schema.'
Assert-Test ('plugins' -in @($manifest.Excluded.Relative)) 'Excluded cache scope not recorded.'
Assert-Test (@(Get-ChildItem -LiteralPath (Join-Path $snapshot 'dados') -Recurse -File | Where-Object Name -eq 'DO-NOT-COPY.txt').Count -eq 0) 'Followed cache junction.'
Assert-Test (@($manifest.Slots | Where-Object {$_.RootType -eq 'File' -and $_.Exists}).Count -eq 2) 'Root state files not backed up.'
[IO.File]::WriteAllText((Join-Path $engine 'state_5.sqlite'),'newer state')
[IO.File]::WriteAllText((Join-Path $engine 'sessions/2026/chat.jsonl'),'later conversation')
Write-NewText (Join-Path $engine 'state_5.sqlite-wal') 'later wal preserved by safety'
Write-NewText (Join-Path $engine 'state_99.sqlite') 'future database'
$pluginPath=@((Get-Item -LiteralPath (Join-Path $engine 'plugins/cache/latest')).Target) -join '|'
Restore-Snapshot $profile $snapshot -TestConfirmed
Assert-Test ([IO.File]::ReadAllText((Join-Path $engine 'state_5.sqlite')) -ceq 'opaque-state-original') 'File restore failed.'
Assert-Test (!(Test-Path -LiteralPath (Join-Path $engine 'state_5.sqlite-wal'))) 'Absent sidecar was not restored to absence.'
Assert-Test (!(Test-Path -LiteralPath (Join-Path $engine 'state_99.sqlite'))) 'New database remained active after restoring older scope.'
Assert-Test ((@((Get-Item -LiteralPath (Join-Path $engine 'plugins/cache/latest')).Target) -join '|') -eq $pluginPath) 'Cache link changed.'
Assert-Test ([IO.File]::ReadAllText((Join-Path $external 'DO-NOT-COPY.txt')) -ceq 'external sentinel') 'External target changed.'
$safety=@(List-Snapshots $profile | Where-Object Kind -eq 'AntesDeRestaurar')[0].Path
Restore-Snapshot $profile $safety -TestConfirmed
Assert-Test ([IO.File]::ReadAllText((Join-Path $engine 'state_5.sqlite-wal')) -ceq 'later wal preserved by safety') 'Safety undo lost WAL.'
$beforeState=[IO.File]::ReadAllText((Join-Path $engine 'state_5.sqlite'))
$beforeChat=[IO.File]::ReadAllText((Join-Path $engine 'sessions/2026/chat.jsonl'))
$failed=$false
try{Restore-Snapshot $profile $snapshot -TestConfirmed -InjectFailureAfter (@(Get-RestorePlan $profile $manifest).Count - 1)}catch{$failed=$true}
Assert-Test $failed 'Failure injection missing.'
Assert-Test ([IO.File]::ReadAllText((Join-Path $engine 'state_5.sqlite')) -ceq $beforeState) 'File rollback changed state.'
Assert-Test ([IO.File]::ReadAllText((Join-Path $engine 'sessions/2026/chat.jsonl')) -ceq $beforeChat) 'Directory rollback changed conversations.'
Assert-Test (@(Get-PendingTransactions).Count -eq 0) 'Rollback left unfinished journal.'

# Data reparse points remain rejected even though plugin cache is out of scope.
[void](New-Item -ItemType Junction -Path (Join-Path $engine 'sessions/unsafe-link') -Target $external)
$blocked=$false
try{[void](New-Snapshot $profile @(Resolve-Roots $profile))}catch{$blocked=$true}
Assert-Test $blocked 'Data link was silently skipped or followed.'

# Scoped mappings cannot request plugins or escape CODEX_HOME.
$slot=@($manifest.Slots | Where-Object RootType -eq 'File')[0]
foreach($bad in @('../outside','plugins','C:\outside','state_5.sqlite:evil')){
    $fake=[pscustomobject]@{Key=$slot.Key;RootType='File';SourceMapping=[pscustomobject]@{ParentKey='codex-engine';Relative=$bad}}
    $blocked=$false;try{[void](Resolve-UnitMapping $profile $fake)}catch{$blocked=$true}
    Assert-Test $blocked ('Accepted bad mapping: '+$bad)
}
Write-Host 'PASS: excluded cache junction; explicit manifest; root files; conversations; WAL absence; safety undo; mixed file/directory rollback; reject links inside data and malicious mappings.'
Write-Host $root
