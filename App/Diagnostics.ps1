function Get-ProfileEvidence {
    param($Profile)
    $roots=@(Get-BackupRoots $Profile)
    $hits=New-Object 'System.Collections.Generic.List[object]'
    # Busca rasa por locais conhecidos; não percorre projetos, node_modules ou caches.
    $patterns=switch($Profile.Id){
        'antigravity' {@('conversations/*.db','conversations/*.pb','agyhub_summaries_proto.pb','conversation_summaries.db','User/globalStorage/state.vscdb')}
        'claude-code' {@('projects/*/*.jsonl','claude-code-sessions/*/*/*.json','local-agent-mode-sessions/*/*/*.json')}
        'codex' {@('state_*.sqlite','session_index.jsonl','sessions/*/*/*/*.jsonl','archived_sessions/*.jsonl')}
        'cursor' {@('globalStorage/state.vscdb','workspaceStorage/*/state.vscdb','*/agent-transcripts/*','*/agent-transcripts/*/*.jsonl')}
        'copilot-vscode' {@('workspaceStorage/*/chatSessions/*.json','workspaceStorage/*/chatSessions/*.jsonl','globalStorage/emptyWindowChatSessions/*','globalStorage/state.vscdb')}
        'kimi-code' {@('daimon-share/daimon/agents/*/sessions/hosted-logical/conversations.sqlite','session_index.jsonl','sessions/*/*/context.jsonl','sessions/*/*/state.json')}
        'trae' {@('workspaceStorage/*/state.vscdb','globalStorage/state.vscdb','workspaceStorage/*/chatSessions/*','workspaceStorage/*/traeChat/*')}
        'windsurf' {@('cascade/*.pb','cascade/*.db','globalStorage/state.vscdb','workspaceStorage/*/state.vscdb')}
        'xiaomi-mimo' {@('mimocode.db','db/*.db')}
        'zcode' {@('cli/db/db.sqlite','cli/rollout/*.jsonl','v2/tasks-index.sqlite')}
        'cline' {@('tasks/*/ui_messages.json','tasks/*/api_conversation_history.json','globalStorage/saoudrizwan.claude-dev/tasks/*/ui_messages.json','globalStorage/state.vscdb')}
        'continue' {@('sessions/*.json','globalStorage/state.vscdb')}
        'kilo-code' {@('kilo.db','agent-manager.json','globalStorage/kilocode.kilo-code/tasks/*/ui_messages.json','globalStorage/state.vscdb')}
        'kiro' {@('globalStorage/state.vscdb','workspaceStorage/*/state.vscdb')}
        'opencode' {@('opencode.db','storage/session/*/*.json')}
        'qwen-code' {@('projects/*/chats/*.json','projects/*/chats/*.jsonl')}
        'roo-code' {@('globalStorage/rooveterinaryinc.roo-cline/tasks/*/ui_messages.json','globalStorage/state.vscdb')}
        'zed' {@('db/*/*.mdb','db/*/*.sqlite','db/*/*.db','threads/*')}
        default {@('globalStorage/state.vscdb')}
    }
    $seen=@{}; $step=0; Set-VaultWork (L 'working_diagnose') ($roots.Count*@($patterns).Count)
    foreach($root in $roots){
        if(!(Test-Path -LiteralPath $root.Path -PathType Container)){continue}
        foreach($pattern in $patterns){
            $step++;Update-VaultWork $step (Join-Path $root.Path $pattern)
            # Escapa colchetes na parte literal antes de acrescentar o padrão conhecido.
            $search=Join-Path ([WildcardPattern]::Escape($root.Path)) $pattern
            foreach($file in @(Get-ChildItem -Path $search -File -Force -ErrorAction SilentlyContinue)){
                if($seen.ContainsKey($file.FullName)){continue};$seen[$file.FullName]=$true
                Assert-NoReparse $file.FullName
                $hits.Add([pscustomobject]@{Path=$file.FullName;Bytes=[long]$file.Length;Kind=$file.Extension;Root=$root.Key})
            }
        }
    }
    return $hits.ToArray()
}

function Show-DiagnosticInternal {
    param($Profile,[switch]$CheckDatabases)
    Write-Line ("DIAGNÓSTICO | $($Profile.Name)") Cyan
    Show-ProfileScope $Profile
    Write-Line ''
    $paths=@();$checks=@()
    foreach($root in @(Get-BackupRoots $Profile)){
        $present=Test-Path -LiteralPath $root.Path -PathType Container
        $paths+=[pscustomobject]@{Key=$root.Key;Path=$root.Path;Exists=[bool]$present}
        $label=if($present){'Encontrada'}else{'Ausente   '}
        Write-Line ("  $label  $($root.Path)") $(if($present){'Green'}else{'DarkGray'})
    }
    $evidence=@(Get-ProfileEvidence $Profile)
    Write-Line ("`n  Arquivos de histórico/índice reconhecidos: {0}" -f $evidence.Count) Cyan
    foreach($item in @($evidence | Select-Object -First 8)) {Write-Line ('  '+$item.Path) DarkGray}
    if($evidence.Count -gt 8){Write-Line ('  ... e mais '+($evidence.Count-8)+' no relatório.') DarkGray}
    if($Profile.Id -eq 'antigravity'){
        $dbs=@($evidence | Where-Object { $_.Path -match '[\\/]conversations[\\/].*\.db$' })
        Write-Line ("  Bancos de conversa: {0} (incluem subagentes; não equivalem ao número de chats principais)." -f $dbs.Count)
        foreach($proto in @($evidence | Where-Object Path -Like '*agyhub_summaries_proto.pb')){
            try{Initialize-Native;$ids=@([Cofre.Native]::SummaryIds($proto.Path));Write-Line ("  Índice protobuf: {0} entradas." -f $ids.Count) Green}
            catch{Write-Line ('  Índice não reconhecido: '+$_.Exception.Message) Yellow}
        }
    }
    if($CheckDatabases){
        Assert-AppClosed $Profile
        foreach($file in @($evidence | Where-Object { $_.Kind -in @('.db','.sqlite','.vscdb') })){
            try{Test-SqliteFile $file.Path;$checks+=[pscustomobject]@{Path=$file.Path;Result='quick_check: ok'}}
            catch{$checks+=[pscustomobject]@{Path=$file.Path;Result=$_.Exception.Message}}
        }
        foreach($check in $checks){Write-Line ("  $($check.Result) | $($check.Path)")}
    }
    Ensure-Directory $script:LogBase
    $file=Join-Path $script:LogBase ('diagnostic-'+$Profile.Id+'-'+(Get-Date -Format yyyyMMdd-HHmmss)+'-'+[guid]::NewGuid().ToString('N').Substring(0,6)+'.json')
    Write-NewJson $file ([pscustomobject]@{Date=(Get-Date).ToString('o');App=$Profile.Id;Roots=$paths;Evidence=$evidence;DatabaseChecks=$checks;Note='Arquivos locais encontrados; não comprova cobertura de nuvem nem restauração na interface.'})
    Write-Line ("`nRelatório: $file") DarkGray
    if(!$evidence.Count){Write-Line 'Nenhum formato conhecido encontrado. Confira pastas personalizadas antes de confiar na cobertura deste perfil.' Yellow}
    if($Profile.Id -eq 'trae'){Write-Line 'Trae: caminhos de perfil são candidatos; restauração semântica ainda não validada nesta instalação.' Yellow}
}

function Show-Catalog {
    $number=0
    foreach($profile in $script:Profiles){$number++;Show-ProfileRow $profile $number}
}

function Show-Diagnostic {
    param($Profile,[switch]$CheckDatabases)
    Invoke-VaultOperation $Profile (L 'working_diagnose') { Show-DiagnosticInternal $Profile -CheckDatabases:$CheckDatabases }
}
