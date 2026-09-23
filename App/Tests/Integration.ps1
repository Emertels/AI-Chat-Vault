$ErrorActionPreference='Stop'
$initialLocation=Get-Location
try {
$package=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $package 'AI-Chat-Vault.ps1') -Idioma en
$originalBase=$script:Base
Load-Profiles
Assert-Test ($script:Profiles.Count -eq 20) 'Catalog must contain 20 apps.'
Assert-Test ((@($script:Profiles.Name) -join '|') -ceq (@($script:Profiles.Name | Sort-Object) -join '|')) 'Catalog order.'
$keys=@($script:English.PSObject.Properties.Name | Sort-Object)
foreach($code in $script:LanguageNames.Keys){
    Initialize-Language $code
    Assert-Test ((@($script:Translations.PSObject.Properties.Name | Sort-Object) -join '|') -ceq ($keys -join '|')) ('Key coverage '+$code)
    foreach($key in $keys){
        $englishText=$script:English.PSObject.Properties[$key].Value
        $translated=$script:Translations.PSObject.Properties[$key].Value
        $a=@([regex]::Matches($englishText,'\{\d+\}') | ForEach-Object Value | Sort-Object) -join '|'
        $b=@([regex]::Matches($translated,'\{\d+\}') | ForEach-Object Value | Sort-Object) -join '|'
        Assert-Test ($a -ceq $b) ('Placeholders '+$code+'/'+$key)
        [void](L $key @('VALUE1','VALUE2','VALUE3'))
    }
    foreach($profile in $script:Profiles){Assert-Test (![string]::IsNullOrWhiteSpace((L $profile.DescriptionKey))) 'App description missing.'}
}
Assert-Test ((Resolve-Language 'pt-PT') -eq 'pt-PT') 'Portuguese mapping.'
Assert-Test ((Resolve-Language 'en-GB') -eq 'en') 'English mapping.'
Assert-Test ((Resolve-Language 'zh-TW') -eq 'zh-TW') 'Chinese mapping.'
Assert-Test ((Resolve-Language 'pl-PL') -eq 'en') 'Unknown locale fallback.'
Initialize-Language 'ja'
$script:Translations.PSObject.Properties.Remove('backup')
Assert-Test ((L 'backup') -ceq $script:English.backup) 'Missing key fallback.'

$temp=Join-Path ([IO.Path]::GetTempPath()) ('Cofre-v3-'+[guid]::NewGuid().ToString('N'))
Ensure-Directory $temp
$portable=Join-Path $temp 'vault A with spaces'
Ensure-Directory $portable
Copy-Item -LiteralPath (Join-Path $package 'AI-Chat-Vault.ps1') -Destination $portable
Ensure-Directory (Join-Path $portable 'App')
foreach($item in @(Get-ChildItem -LiteralPath (Join-Path $package 'App') -Force | Where-Object Name -ne 'Data')){
    Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $portable 'App') -Recurse
}
. (Join-Path $portable 'AI-Chat-Vault.ps1') -Idioma en
$script:TestMode=$true
Save-Language 'ja'
Initialize-Language
Assert-Test ($script:Language -eq 'ja') 'Persistent language preference.'
Initialize-Language 'fr'
Assert-Test ($script:Language -eq 'fr') 'Session language override.'
Initialize-Language
Assert-Test ($script:Language -eq 'ja') 'Session override must not overwrite preference.'
function Get-WindowsDisplayLanguage {return 'de-DE'}
Save-Language 'auto'
Assert-Test ($script:Language -eq 'de') 'Windows display language detection.'
Initialize-Language 'en'

# v2 configuration remains authoritative for customized roots; new apps append.
$legacy=@(Get-DefaultProfiles | Select-Object -First 10)
$legacy[0].Roots[0].Path=Join-Path $temp 'custom profile'
Write-NewJson $script:ConfigPath ([pscustomobject]@{Schema=1;Profiles=$legacy})
Load-Profiles
Assert-Test ($script:Profiles.Count -eq 20) 'v2 configuration lost new profiles.'
Assert-Test ((Get-Profile $legacy[0].Id).Roots[0].Path -ceq $legacy[0].Roots[0].Path) 'Custom path overwritten.'

# Extension detection must not match an editor folder alone.
$data=Join-Path $temp 'editor User';Ensure-Directory $data
$marker=Join-Path $data 'globalStorage/example.extension'
$profile=New-Profile 'fixture' 'Fixture' @('fake.exe') '' @((New-Root 'user' $data $marker)) 'Synthetic data'
Assert-Test (!(Test-ProfileData $profile)) 'False extension detection.'
Ensure-Directory $marker
Write-NewText (Join-Path $data 'conversa [01].json') '{"title":"日本語 — ação"}'
Assert-Test (Test-ProfileData $profile) 'Extension data not detected.'
Set-Location $env:SystemRoot
$backup=New-Snapshot $profile @(Resolve-Roots $profile)
Assert-Test (Is-Within $backup (Join-Path $portable 'Backups')) 'Backup location follows terminal instead of script.'
Initialize-Language 'ru'
[void](Test-Snapshot $backup)
$moved=Join-Path $temp 'vault B moved'
Assert-Test ((Is-Within $portable $temp) -and (Is-Within $moved $temp)) 'Unsafe fixture move.'
[IO.Directory]::Move($portable,$moved)
. (Join-Path $moved 'AI-Chat-Vault.ps1') -Idioma ja
$script:TestMode=$true
$snapshots=@(List-Snapshots $profile)
Assert-Test ($snapshots.Count -eq 1) 'Moved snapshot undiscoverable.'
[IO.File]::WriteAllText((Join-Path $data 'conversa [01].json'),'later data')
Restore-Snapshot $profile $snapshots[0].Path -TestConfirmed
Assert-Test ([IO.File]::ReadAllText((Join-Path $data 'conversa [01].json')).Contains('日本語')) 'Cross-locale portable restore failed.'

# File sharing conflict must be actionable and never publish a completed backup.
$locked=Join-Path $data 'state.vscdb-shm'
Write-NewText $locked 'locked fixture'
$stream=[IO.File]::Open($locked,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try{
    $blocked=$false
    try{[void](New-Snapshot $profile @(Resolve-Roots $profile))}catch{$blocked=$true;Assert-Test ($_.Exception.Message.Contains($locked)) 'Locked file path missing from message.';Assert-Test ($_.Exception.Message -notmatch 'Exception calling|Exceção ao chamar') 'Raw .NET error leaked.'}
    Assert-Test $blocked 'Locked file was ignored.'
}finally{$stream.Dispose()}
Write-Host 'PASS: 20 profiles; 15 catalogs; placeholders; fallback; preference; display language; config migration; extension gates; portable cross-language restore; locked file.'
Write-Host $temp

} finally { Set-Location $initialLocation }
