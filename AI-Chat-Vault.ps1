#Requires -Version 5.1
<#
.SYNOPSIS
    Cofre IA: backup e restauração de perfis locais de ferramentas de programação.
.DESCRIPTION
    Windows PowerShell 5.1 / PowerShell 7 no Windows. Sem downloads ou módulos externos.
    Trabalha com cópias completas de pastas explicitamente mapeadas. Não mescla bancos
    e inclui reconstrução nativa do índice AntiGravity 2.x. SHA-256 verifica bytes, não a leitura pelo app.
    Antes de aplicar: prévia, aplicativo fechado, backup de retorno, staging verificado
    e registro recuperável de cada troca de pasta. Originais não são apagados.
.EXAMPLE
    .\AI-Chat-Vault.ps1
.EXAMPLE
    .\AI-Chat-Vault.ps1 -Acao AutoTeste
.EXAMPLE
    .\AI-Chat-Vault.ps1 -Acao Diagnostico -Aplicativo antigravity
.EXAMPLE
    .\AI-Chat-Vault.ps1 -Acao Backup -Aplicativo codex
.NOTES
    Versão 4.1.4 | 23/09/2026 | Código aberto, licença MIT no guia.
    Não executar como administrador. Consulte README.pt-BR.md antes de restaurar.
#>
[CmdletBinding()]
param(
    [ValidateSet('Menu','Diagnostico','Diagnostics','Backup','BackupTodos','Verificar','Restaurar','AutoTeste','Reparar','Listar')]
    [string]$Acao = 'Menu',
    [string]$Aplicativo,
    [string]$CaminhoBackup,
    [ValidateSet('auto','pt-BR','en','es','fr','de','it','ja','ko','zh-CN','ru','pt-PT','nl','zh-TW','ar','hi')]
    [string]$Idioma
)

if ($Acao -eq 'Diagnostico') { $Acao = 'Diagnostics' }

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:Version = '4.1.4'
$script:Started = Get-Date
$script:SessionId = [guid]::NewGuid().ToString('N').Substring(0,8)
$script:Base = [IO.Path]::GetFullPath($PSScriptRoot)
$script:BackupBase = Join-Path $script:Base 'Backups'
$script:JournalBase = Join-Path $script:BackupBase '_transactions'
$script:LogBase = Join-Path $script:Base 'App/Data/Logs'
$script:ConfigPath = Join-Path $script:Base 'App/Data/profiles.local.json'
if(!(Test-Path -LiteralPath $script:ConfigPath) -and (Test-Path -LiteralPath (Join-Path $script:Base 'perfis-locais.json'))){$script:ConfigPath=Join-Path $script:Base 'perfis-locais.json'}
$script:LogPath = $null
$script:TestMode = $false
$script:CancelAllowed = $true
$script:SelfTestPassed = $false
$script:MutexHandle = $null
$script:MutexOwned = $false
$script:Profiles = @()


foreach ($module in @('Core','Localization','Progress','Profiles','Processes','Native','DataScope','Diagnostics','Antigravity','Tests','Interface')) {
    $modulePath = Join-Path $PSScriptRoot ('App/' + $module + '.ps1')
    if (!(Test-Path -LiteralPath $modulePath)) { throw "Módulo ausente: $modulePath. Copie a pasta completa do cofre." }
    . $modulePath
}

Initialize-Language $Idioma

function Main {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'Este arquivo foi projetado para Windows. Execute-o no PowerShell 5.1 ou 7 do Windows.'
    }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Abra um PowerShell normal, sem Executar como administrador. O cofre deve usar o seu perfil e permissões habituais.'
    }
    try {
        $script:MutexHandle = New-Object Threading.Mutex($false, ('Local\CofreIA-' + $identity.User.Value))
        try { $script:MutexOwned=$script:MutexHandle.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $script:MutexOwned=$true }
        if (!$script:MutexOwned) { throw 'Outra instância do Cofre IA já está aberta neste usuário.' }
        Ensure-Directory $script:LogBase
        $script:LogPath = Join-Path $script:LogBase ('session-' + (Get-Date).ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.log')
        Write-NewText $script:LogPath ('Cofre IA ' + $script:Version + [Environment]::NewLine)
        Load-Profiles
        if ($Acao -eq 'AutoTeste') { Invoke-SelfTest; return }
        $pending = @(Get-PendingTransactions)
        if ($pending.Count -gt 0 -and $Acao -ne 'Menu') { throw 'Operação interrompida detectada. Abra o menu e entre em Ferramentas > Recuperar operação interrompida.' }
        if ($Acao -eq 'Menu') { Run-Menu; return }
        if ($Acao -eq 'Listar') { Show-Catalog; return }
        if ($Acao -eq 'BackupTodos') { Backup-All; return }
        $profile = Get-Profile $Aplicativo
        switch ($Acao) {
            'Reparar' { Invoke-AppRepair $profile }
            'Diagnostics' { Show-Diagnostic $profile }
            'Backup' { $result=New-Snapshot $profile @(Resolve-Roots $profile); Write-Line (L 'done' @($result)) Green }
            'Verificar' {
                $manifest=Invoke-VaultOperation $profile (L 'working_verify') { Test-Snapshot $CaminhoBackup }
                if ($manifest.AppId -ne $profile.Id) { throw 'O backup pertence a outro aplicativo.' }
                Write-Line (L 'verified') Green
            }
            'Restaurar' { Restore-Snapshot $profile $CaminhoBackup }
        }
    } finally {
        if ($script:MutexHandle) {
            if ($script:MutexOwned) { $script:MutexHandle.ReleaseMutex() }
            $script:MutexHandle.Dispose()
        }
    }
}
# Permite inspeção e testes externos por dot-sourcing, sem executar o menu.
if ($MyInvocation.InvocationName -ne '.') {
    try { Main }
    catch {
        Show-OperationError $_
        if ($Acao -eq 'Menu') { [void](Read-Host (L 'enter')) }
        exit 1
    }
}

