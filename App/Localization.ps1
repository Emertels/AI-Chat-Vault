function Resolve-Language {
    param([string]$Name)
    if ($Name -match '^pt-PT(?:-|$)') { return 'pt-PT' }
    if ($Name -match '^pt(?:-|$)') { return 'pt-BR' }
    if ($Name -match '^zh-(?:TW|HK|MO|Hant)(?:-|$)') { return 'zh-TW' }
    if ($Name -match '^zh(?:-|$)') { return 'zh-CN' }
    foreach ($code in @('en','es','fr','de','it','ja','ko','ru','nl','ar','hi')) {
        if ($Name -match ('^'+$code+'(?:-|$)')) { return $code }
    }
    return 'en'
}

function Get-WindowsDisplayLanguage {
    # Display language, not regional number/date formatting.
    try {
        if (Get-Command Get-WinUILanguageOverride -ErrorAction SilentlyContinue) {
            $override = Get-WinUILanguageOverride
            if ($override -and $override.Name) { return $override.Name }
        }
    } catch { }
    return [Globalization.CultureInfo]::CurrentUICulture.Name
}

function Initialize-Language {
    param([string]$Choice='')
    # ASCII English language names are universal labels, independent of UI locale.
    $script:LanguageNames = [ordered]@{
        'ar'='Arabic'; 'zh-CN'='Chinese (Simplified)'; 'zh-TW'='Chinese (Traditional)'
        'nl'='Dutch'; 'en'='English'; 'fr'='French'; 'de'='German'; 'hi'='Hindi'
        'it'='Italian'; 'ja'='Japanese'; 'ko'='Korean'; 'pt-BR'='Portuguese (Brazil)'
        'pt-PT'='Portuguese (Portugal)'; 'ru'='Russian'; 'es'='Spanish'
    }
    $script:PreferencesPath=Join-Path $script:Base 'App/Data/preferences.json'
    if (!$Choice -and (Test-Path -LiteralPath $script:PreferencesPath)) {
        $settings=Read-Json $script:PreferencesPath
        if ($settings.PSObject.Properties['Language']) { $Choice=[string]$settings.Language }
    }
    if (!$Choice) { $Choice='auto' }
    if ($Choice -ne 'auto' -and !$script:LanguageNames.Contains($Choice)) { $Choice='auto' }
    $script:LanguageChoice=$Choice
    if ($Choice -eq 'auto') { $Choice=Resolve-Language (Get-WindowsDisplayLanguage) }
    $script:Language=$Choice
    $folder=Join-Path $script:Base 'App/Locales'
    $script:English=Read-Json (Join-Path $folder 'en.json')
    $script:Translations=Read-Json (Join-Path $folder ($Choice+'.json'))
    $cultureName=if($Choice -eq 'en'){'en-US'}elseif($Choice -eq 'zh-CN'){'zh-CN'}else{$Choice}
    $script:DisplayCulture=[Globalization.CultureInfo]::GetCultureInfo($cultureName)
}

function L {
    param([string]$Key, [object[]]$Values=@())
    $property=$script:Translations.PSObject.Properties[$Key]
    if (!$property -or [string]::IsNullOrEmpty($property.Value)) { $property=$script:English.PSObject.Properties[$Key] }
    if (!$property) { throw "Missing UI translation: $Key" }
    if ($Values.Count) { return [string]::Format($script:DisplayCulture,[string]$property.Value,$Values) }
    return [string]$property.Value
}

function Save-Language {
    param([string]$Choice)
    if ($Choice -ne 'auto' -and !$script:LanguageNames.Contains($Choice)) { throw 'Invalid language.' }
    Ensure-Directory ([IO.Path]::GetDirectoryName($script:PreferencesPath))
    $temp=$script:PreferencesPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    Write-NewJson $temp ([pscustomobject]@{Schema=1;Language=$Choice})
    if(Test-Path -LiteralPath $script:PreferencesPath){
        Assert-NoReparse $script:PreferencesPath
        [IO.File]::Replace($temp,$script:PreferencesPath,$script:PreferencesPath+'.previous')
    }else{[IO.File]::Move($temp,$script:PreferencesPath)}
    Initialize-Language $Choice
}

function Select-Language {
    Write-Line ('   0. '+(L 'auto')) Cyan
    $codes=@($script:LanguageNames.Keys | Sort-Object { $script:LanguageNames[$_] })
    for($i=0;$i -lt $codes.Count;$i++){Write-Line ('  {0,2}. {1}' -f ($i+1),$script:LanguageNames[$codes[$i]])}
    Write-Line (L 'enter') DarkGray
    $number=0
    if(![int]::TryParse((Read-Host (L 'language')),[ref]$number)){return}
    if($number -eq 0){Save-Language 'auto'}
    elseif($number -ge 1 -and $number -le $codes.Count){Save-Language $codes[$number-1]}
    else{return}
    Write-Line (L 'saved') Green
}

function Show-ProfileScope {
    param($Profile)
    if($Profile.PSObject.Properties['DescriptionKey']){Write-Line (L $Profile.DescriptionKey)}
    if($Profile.PSObject.Properties['Shared'] -and $Profile.Shared){Write-Line (L 'shared') Yellow}
    if($Profile.PSObject.Properties['Confidence'] -and $Profile.Confidence -eq 'candidate'){Write-Line (L 'candidate') Yellow}
    if($Profile.Id -eq 'codex'){Write-Line (L 'codex_scope') Yellow}
    Write-Line (L 'localonly') DarkGray
}

function Show-OperationError {
    param($ErrorRecord)
    Write-Line (L 'error' @($ErrorRecord.Exception.Message)) Red
    Write-Log ('ERROR | '+$ErrorRecord.Exception.Message)
}
