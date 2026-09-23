function New-Root {
    param([string]$Key, [string]$Path, [string]$Requires='')
    return [pscustomobject]@{ Key = $Key; Path = $Path; Requires = $Requires }
}

function New-Profile {
    param([string]$Id, [string]$Name, [string[]]$Processes, [string]$CommandMatch,
          [object[]]$Roots, [string]$Notes)
    return [pscustomobject]@{
        Id=$Id; Name=$Name; Processes=@($Processes); CommandMatch=$CommandMatch
        Roots=@($Roots); Notes=$Notes
    }
}

function Get-DefaultProfiles {
    $codexRoot = '%USERPROFILE%\.codex'
    if ($env:CODEX_HOME) { $codexRoot = $env:CODEX_HOME }
    $claudeRoot = '%USERPROFILE%\.claude'
    if ($env:CLAUDE_CONFIG_DIR) { $claudeRoot = $env:CLAUDE_CONFIG_DIR }
    $list = @(
        (New-Profile 'antigravity' 'Antigravity' @('antigravity.exe','antigravity ide.exe') 'antigravity|agyhub' @(
            (New-Root 'gemini-antigravity' '%USERPROFILE%\.gemini\antigravity'),
            (New-Root 'gemini-antigravity-ide' '%USERPROFILE%\.gemini\antigravity-ide'),
            (New-Root 'gemini-antigravity-backup' '%USERPROFILE%\.gemini\antigravity-backup'),
            (New-Root 'roaming-antigravity' '%APPDATA%\Antigravity'),
            (New-Root 'roaming-antigravity-ide' '%APPDATA%\Antigravity IDE')
        ) 'Bancos, brain, scratch, índices e perfil. Reparo nativo 2.x para conversas .db ausentes da lista; preserva entradas existentes. Versões antigas .pb: diagnóstico e backup, sem reescrever esquema desconhecido.'),
        (New-Profile 'claude-code' 'Claude Code' @('claude.exe','code.exe','code-insiders.exe') 'claude-code|anthropic[\\/]claude|claude.*(agent|session)' @(
            (New-Root 'claude-engine' $claudeRoot),
            (New-Root 'claude-desktop' '%APPDATA%\Claude')
        ) 'Motor local e perfil do Claude Desktop. Chat web, Code, extensão e sessões remotas podem ter históricos distintos. Perfil Desktop pode incluir dados de outras abas.'),
        (New-Profile 'codex' 'Codex' @('codex.exe','code.exe','code-insiders.exe') 'codex.*app-server|@openai[\\/]codex' @(
            (New-Root 'codex-engine' $codexRoot),
            (New-Root 'codex-desktop' '%APPDATA%\Codex')
        ) 'Inclui sessions, archived_sessions e bancos/índices locais presentes no CODEX_HOME. Sessões e arquivos exclusivamente remotos não são baixados.'),
        (New-Profile 'cursor' 'Cursor' @('cursor.exe') 'cursor.*(extensionHost|server)' @(
            (New-Root 'cursor-user' '%APPDATA%\Cursor\User'),
            (New-Root 'cursor-projects' '%USERPROFILE%\.cursor\projects')
        ) 'Snapshot do perfil User: workspaceStorage, globalStorage, perfis e configurações. Restauração também volta o estado de outras extensões desse perfil.'),
        (New-Profile 'copilot-vscode' 'GitHub Copilot' @('code.exe','code-insiders.exe') 'vscode.*(agent|server)|copilot.*(agent|server)' @(
            (New-Root 'vscode-user' '%APPDATA%\Code\User' '%APPDATA%\Code\User\workspaceStorage'),
            (New-Root 'vscode-insiders-user' '%APPDATA%\Code - Insiders\User' '%APPDATA%\Code - Insiders\User\workspaceStorage')
        ) 'Snapshot completo do perfil User do VS Code, inclusive outras extensões. Sessões de agentes externos podem exigir também o perfil do fornecedor.'),
        (New-Profile 'kimi-code' 'Kimi Code / Desktop' @('kimi.exe','kimi-desktop.exe') 'kimi[_-](cli|code|desktop)|daimon-share|moonshot.*kimi' @(
            (New-Root 'kimi-local' '%USERPROFILE%\.kimi'),
            (New-Root 'kimi-code-engine' '%USERPROFILE%\.kimi-code'),
            (New-Root 'kimi-desktop' '%APPDATA%\kimi-desktop')
        ) 'Desktop: tarefas Work locais em daimon-share e metadados kimi-agent. Inclui motores usados nas integrações Code. Chats exclusivamente na nuvem não são baixados.'),
        (New-Profile 'trae' 'Trae' @('trae.exe','trae cn.exe') 'trae.*(agent|server)' @(
            (New-Root 'trae-user' '%APPDATA%\Trae\User'),
            (New-Root 'trae-cn-user' '%APPDATA%\Trae CN\User')
        ) 'Candidatos de perfil local do IDE. Estrutura de histórico varia por versão; backup de arquivos não comprova que o Trae conseguirá listar as conversas.'),
        (New-Profile 'windsurf' 'Windsurf' @('windsurf.exe','windsurf - next.exe','devin.exe') 'codeium|windsurf|devin.*language_server' @(
            (New-Root 'windsurf-engine' '%USERPROFILE%\.codeium\windsurf'),
            (New-Root 'windsurf-user' '%APPDATA%\Windsurf\User'),
            (New-Root 'windsurf-next-user' '%APPDATA%\Windsurf - Next\User')
        ) 'Candidatos do Windsurf/Cascade. Não presume que versões com outro nome de produto mantenham o mesmo armazenamento; adicione o caminho real se mudou.'),
        (New-Profile 'xiaomi-mimo' 'Xiaomi MiMo' @('Xiaomi MiMo AI.exe','mimocode.exe','mimo.exe') 'mimocode|Xiaomi MiMo AI' @(
            (New-Root 'mimo-engine' '%USERPROFILE%\.local\share\mimocode'),
            (New-Root 'mimo-desktop' '%APPDATA%\Xiaomi MiMo AI')
        ) 'Motor mimocode.db: sessões, mensagens e partes; perfil Desktop: anexos, artefatos e índices auxiliares. Banco compartilhado pode conter dados de conta.'),
        (New-Profile 'zcode' 'ZCode' @('zcode.exe') 'zcode|@zcode' @(
            (New-Root 'zcode-engine' '%USERPROFILE%\.zcode'),
            (New-Root 'zcode-desktop' '%APPDATA%\ZCode')
        ) 'Candidatos locais; valide a instalação no diagnóstico. Conversas com GLM, MiMo ou outro modelo são protegidas pelo aplicativo que as armazenou.')
    )
    $list += @(
        (New-Profile 'augment-code' 'Augment Code' @('code.exe','code-insiders.exe','cursor.exe') 'augment' @((New-Root 'augment-engine' '%USERPROFILE%\.augment' ''),(New-Root 'augment-code-vscode' '%APPDATA%\Code\User' '%APPDATA%\Code\User\globalStorage\augment.vscode-augment'),(New-Root 'augment-code-insiders' '%APPDATA%\Code - Insiders\User' '%APPDATA%\Code - Insiders\User\globalStorage\augment.vscode-augment'),(New-Root 'augment-code-cursor' '%APPDATA%\Cursor\User' '%APPDATA%\Cursor\User\globalStorage\augment.vscode-augment')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'cline' 'Cline' @('code.exe','code-insiders.exe','cursor.exe','cline.exe') 'cline' @((New-Root 'cline-engine' '%USERPROFILE%\.cline' ''),(New-Root 'cline-vscode' '%APPDATA%\Code\User' '%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev'),(New-Root 'cline-insiders' '%APPDATA%\Code - Insiders\User' '%APPDATA%\Code - Insiders\User\globalStorage\saoudrizwan.claude-dev'),(New-Root 'cline-cursor' '%APPDATA%\Cursor\User' '%APPDATA%\Cursor\User\globalStorage\saoudrizwan.claude-dev')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'continue' 'Continue' @('code.exe','code-insiders.exe','cursor.exe') 'continue' @((New-Root 'continue-engine' '%USERPROFILE%\.continue' ''),(New-Root 'continue-vscode' '%APPDATA%\Code\User' '%APPDATA%\Code\User\globalStorage\continue.continue'),(New-Root 'continue-insiders' '%APPDATA%\Code - Insiders\User' '%APPDATA%\Code - Insiders\User\globalStorage\continue.continue'),(New-Root 'continue-cursor' '%APPDATA%\Cursor\User' '%APPDATA%\Cursor\User\globalStorage\continue.continue')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'kilo-code' 'Kilo Code' @('code.exe','code-insiders.exe','cursor.exe','kilo.exe') 'kilo' @((New-Root 'kilo-engine' '%USERPROFILE%\.local\share\kilo' ''),(New-Root 'kilo-agent-manager' '%USERPROFILE%\.kilo' ''),(New-Root 'kilo-code-vscode' '%APPDATA%\Code\User' '%APPDATA%\Code\User\globalStorage\kilocode.kilo-code'),(New-Root 'kilo-code-insiders' '%APPDATA%\Code - Insiders\User' '%APPDATA%\Code - Insiders\User\globalStorage\kilocode.kilo-code'),(New-Root 'kilo-code-cursor' '%APPDATA%\Cursor\User' '%APPDATA%\Cursor\User\globalStorage\kilocode.kilo-code')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'kiro' 'Kiro' @('kiro.exe','kiro-cli.exe') 'kiro' @((New-Root 'kiro-user' '%APPDATA%\Kiro\User' ''),(New-Root 'kiro-engine' '%USERPROFILE%\.kiro' '')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'opencode' 'OpenCode Desktop' @('opencode.exe','opencode-desktop.exe','opencode-cli.exe') 'opencode' @((New-Root 'opencode-engine' '%USERPROFILE%\.local\share\opencode' ''),(New-Root 'opencode-desktop' '%APPDATA%\ai.opencode.desktop' '')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'qwen-code' 'Qwen Code' @('code.exe','code-insiders.exe','cursor.exe','qwen.exe') 'qwen' @((New-Root 'qwen-engine' '%USERPROFILE%\.qwen' '')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'roo-code' 'Roo Code' @('code.exe','code-insiders.exe','cursor.exe') 'roo-cline|roocode' @((New-Root 'roo-code-vscode' '%APPDATA%\Code\User' '%APPDATA%\Code\User\globalStorage\rooveterinaryinc.roo-cline'),(New-Root 'roo-code-insiders' '%APPDATA%\Code - Insiders\User' '%APPDATA%\Code - Insiders\User\globalStorage\rooveterinaryinc.roo-cline'),(New-Root 'roo-code-cursor' '%APPDATA%\Cursor\User' '%APPDATA%\Cursor\User\globalStorage\rooveterinaryinc.roo-cline')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'tabnine' 'Tabnine' @('code.exe','code-insiders.exe','cursor.exe','TabNine.exe') 'tabnine' @((New-Root 'tabnine-local' '%APPDATA%\TabNine' ''),(New-Root 'tabnine-agent' '%USERPROFILE%\.tabnine' ''),(New-Root 'tabnine-vscode' '%APPDATA%\Code\User' '%APPDATA%\Code\User\globalStorage\tabnine.tabnine-vscode'),(New-Root 'tabnine-insiders' '%APPDATA%\Code - Insiders\User' '%APPDATA%\Code - Insiders\User\globalStorage\tabnine.tabnine-vscode'),(New-Root 'tabnine-cursor' '%APPDATA%\Cursor\User' '%APPDATA%\Cursor\User\globalStorage\tabnine.tabnine-vscode')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.'),
        (New-Profile 'zed' 'Zed' @('zed.exe') 'zed' @((New-Root 'zed-data' '%LOCALAPPDATA%\Zed' ''),(New-Root 'zed-settings' '%APPDATA%\Zed' '')) 'Snapshot de dados locais. Consulte README.md e PESQUISA.md para o escopo e a validação deste perfil.')
    )
    foreach ($profile in $list) {
        foreach($root in $profile.Roots){
            if($root.Key -eq 'continue-engine' -and $env:CONTINUE_GLOBAL_DIR){$root.Path=$env:CONTINUE_GLOBAL_DIR}
            if($root.Key -eq 'qwen-engine'){
                if($env:QWEN_RUNTIME_DIR){$root.Path=$env:QWEN_RUNTIME_DIR}
                elseif($env:QWEN_HOME){$root.Path=$env:QWEN_HOME}
            }
            if($root.Key -eq 'opencode-engine' -and $env:OPENCODE_DB){
                $root.Path=[IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($env:OPENCODE_DB))
            }
        }
    }
    return $list | Sort-Object Name
}


function Test-RootGate {
    param($Profile,$Root)
    $definition=@($Profile.Roots | Where-Object Key -eq $Root.Key)
    if($definition.Count -ne 1){throw 'Definição de pasta não encontrada.'}
    $item=$definition[0]
    if($item.PSObject.Properties['Requires'] -and $item.Requires){
        return (Test-Path -LiteralPath ([Environment]::ExpandEnvironmentVariables($item.Requires)))
    }
    return $true
}

function Get-BackupRoots {
    param($Profile)
    return @(Resolve-Roots $Profile | Where-Object { Test-RootGate $Profile $_ })
}

function Test-ProfileData {
    param($Profile)
    return (@(Get-BackupRoots $Profile | Where-Object {Test-Path -LiteralPath $_.Path -PathType Container}).Count -gt 0)
}

function Set-ProfilePresentation {
    param([object[]]$Profiles)
    $catalog=Read-Json (Join-Path $script:Base 'App/Catalog.json')
    foreach($profile in $Profiles){
        $entry=$catalog.PSObject.Properties[$profile.Id]
        $company='';$color='Cyan';$description='desc_custom';$shared=$false;$confidence='candidate'
        if($entry){$company=$entry.Value.Company;$color=$entry.Value.Color;$description=$entry.Value.Description;$shared=$entry.Value.Shared;$confidence=$entry.Value.Confidence}
        foreach($pair in @(@('Company',$company),@('Color',$color),@('DescriptionKey',$description),@('Shared',[bool]$shared),@('Confidence',$confidence))){
            $profile | Add-Member -NotePropertyName $pair[0] -NotePropertyValue $pair[1] -Force
        }
    }
}
