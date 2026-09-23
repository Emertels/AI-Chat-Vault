function Assert-Test {
    param([bool]$Condition, [string]$Message)
    if (!$Condition) { throw "AUTOTESTE: $Message" }
}

function Invoke-SelfTest {
    Write-Line 'Executando autoteste somente com dados artificiais temporários...' Cyan
    $saved = @{
        Base=$script:Base; BackupBase=$script:BackupBase; JournalBase=$script:JournalBase
        LogBase=$script:LogBase; LogPath=$script:LogPath; TestMode=$script:TestMode; CancelAllowed=$script:CancelAllowed
    }
    $temp = Join-Path ([IO.Path]::GetTempPath()) ('CofreIA-Teste-' + [guid]::NewGuid().ToString('N'))
    Ensure-Directory $temp
    $checks = New-Object 'System.Collections.Generic.List[string]'
    try {
        $script:TestMode = $true
        $script:Base = Join-Path $temp 'cofre'
        $script:BackupBase = Join-Path $script:Base 'Backups'
        $script:JournalBase = Join-Path $script:BackupBase '_transactions'
        $script:LogBase = Join-Path $script:Base 'App/Data/Logs'
        $script:LogPath = $null
        Ensure-Directory $script:Base
        $one = Join-Path $temp 'dados com acentos e espaços'
        $two = Join-Path $temp 'dados-dois'
        Ensure-Directory $one
        Ensure-Directory $two
        Ensure-Directory (Join-Path $one 'subpasta vazia')
        Write-NewText (Join-Path $one 'conversa [01].json') '{"titulo":"Anime TV","texto":"ação e restauração"}'
        Write-NewText (Join-Path $two 'indice.pb') 'indice-artificial-01'
        $profile = New-Profile 'teste' 'Dados artificiais' @('ficticio.exe') '' @(
            (New-Root 'um' $one), (New-Root 'dois' $two)
        ) 'Autoteste isolado.'
        $roots = @(Resolve-Roots $profile)
        $snapshot = New-Snapshot $profile $roots
        [void](Test-Snapshot $snapshot)
        $checks.Add('Backup, hash, Unicode, colchetes e diretório vazio')
        [IO.File]::WriteAllText((Join-Path $one 'conversa [01].json'), 'conteudo posterior')
        Write-NewText (Join-Path $one 'nova conversa.txt') 'Não pode desaparecer do backup de retorno'
        Restore-Snapshot $profile $snapshot -TestConfirmed
        Assert-Test ([IO.File]::ReadAllText((Join-Path $one 'conversa [01].json')) -match 'Anime TV') 'A restauração não repôs os bytes originais.'
        $safetyDirs = @(Get-ChildItem -LiteralPath (Join-Path $script:BackupBase 'teste') -Directory | Where-Object { $_.FullName -ne $snapshot })
        $safety = @($safetyDirs | Where-Object { (Read-Json (Join-Path $_.FullName 'manifesto.json')).Kind -eq 'AntesDeRestaurar' })[0].FullName
        Assert-Test (Test-Path -LiteralPath (Join-Path $safety 'dados/um/nova conversa.txt')) 'A conversa posterior não foi preservada.'
        $checks.Add('Restauração exata e preservação de conversas posteriores')
        Restore-Snapshot $profile $safety -TestConfirmed
        Assert-Test ([IO.File]::ReadAllText((Join-Path $one 'conversa [01].json')) -eq 'conteudo posterior') 'O retorno ao estado anterior falhou.'
        $checks.Add('Retorno ao estado anterior')
        $mismatch = Read-Json (Join-Path $snapshot 'manifesto.json')
        $mismatch.AppId = 'outro-aplicativo'
        $blocked = $false
        try { [void](Get-RestorePlan $profile $mismatch) } catch { $blocked=$true }
        Assert-Test $blocked 'Foi aceito backup de outro aplicativo.'
        $checks.Add('Bloqueio de restauração em outro aplicativo')
        $before = @(Get-Inventory $one)
        $failed = $false
        try { Restore-Snapshot $profile $snapshot -TestConfirmed -InjectFailureAfter 1 } catch { $failed = $true }
        Assert-Test $failed 'A falha simulada não ocorreu.'
        Assert-Test (Compare-Inventory $before @(Get-Inventory $one)) 'A reversão não preservou o primeiro destino.'
        Assert-Test (@(Get-PendingTransactions).Count -eq 0) 'Sobrou uma transação pendente após a reversão.'
        $checks.Add('Falha entre duas pastas e reversão')
        # Simula restauração em uma pasta que não existia e posterior retorno.
        $absent = Join-Path $temp 'destino inicialmente ausente'
        $absentProfile = New-Profile 'ausente' 'Destino ausente' @('ficticio.exe') '' @((New-Root 'um' $absent)) 'Autoteste.'
        $absentBefore = New-Snapshot $absentProfile @(Resolve-Roots $absentProfile) 'AntesDeRestaurar'
        Ensure-Directory $absent
        Write-NewText (Join-Path $absent 'dados novos.txt') 'preservar'
        Restore-Snapshot $absentProfile $absentBefore -TestConfirmed
        Assert-Test (!(Test-Path -LiteralPath $absent)) 'O retorno não recuperou o estado de pasta ausente.'
        $checks.Add('Retorno de pasta originalmente ausente sem apagar a cópia posterior')
        $payloadFile = Join-Path $snapshot 'dados/dois/indice.pb'
        [IO.File]::AppendAllText($payloadFile, 'corrupcao')
        $blocked = $false
        try { [void](Test-Snapshot $snapshot) } catch { $blocked = $true }
        Assert-Test $blocked 'O backup corrompido foi aceito.'
        $checks.Add('Bloqueio de backup corrompido')
        foreach ($bad in @('../fora','a/../fora','C:\fora','arquivo:stream','CON.txt','a/./b')) {
            $blocked = $false
            try { Assert-Relative $bad } catch { $blocked = $true }
            Assert-Test $blocked "Caminho perigoso aceito: $bad"
        }
        $checks.Add('Bloqueio de travessia, caminhos absolutos e fluxos alternativos')
        Write-NewJson (Join-Path $temp 'resultado.json') ([pscustomobject]@{ Passed=$true; Engine=$PSVersionTable.PSVersion.ToString(); Checks=$checks.ToArray() })
    } finally {
        $script:Base=$saved.Base; $script:BackupBase=$saved.BackupBase; $script:JournalBase=$saved.JournalBase
        $script:LogBase=$saved.LogBase; $script:LogPath=$saved.LogPath; $script:TestMode=$saved.TestMode
        $script:CancelAllowed=$saved.CancelAllowed
    }
    Write-Line ('Autoteste concluído: {0} grupos de verificação passaram.' -f $checks.Count) Green
    Write-Line ("Dados artificiais e resultado preservados em: $temp") DarkGray
}

# -----------------------------------------------------------------------------
# Menus e configuração local
# -----------------------------------------------------------------------------
