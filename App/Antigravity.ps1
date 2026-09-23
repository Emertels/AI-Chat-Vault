# Reconstitui somente entradas ausentes usando o motor instalado, nunca bytes de
# protobuf inventados. A cópia isolada não recebe credenciais nem solicita geração.
function Get-CommandFlag {
    param([string]$Command, [string]$Flag)
    $m = [regex]::Match($Command, '(?:^|\s)--' + [regex]::Escape($Flag) + '(?:=|\s+)(?:"([^"]*)"|(\S+))')
    if (!$m.Success) { return $null }
    if ($m.Groups[1].Success) { return $m.Groups[1].Value }
    return $m.Groups[2].Value
}

function Invoke-AgRpc {
    param($Connection, [string]$Method, $Data=@{}, [switch]$Stream, [switch]$Discard)
    Initialize-Native
    $json = ConvertTo-Json -InputObject $Data -Depth 80 -Compress
    $raw = [Cofre.Native]::Rpc([int]$Connection.Port, $Connection.Token, $Method, $json, [bool]$Stream)
    if ($Discard) {
        if ($raw -notmatch '"trajectory"\s*:') { throw 'O motor não devolveu a trajetória solicitada.' }
        return
    }
    return (Convert-JsonText $raw)
}

function Read-AgSummaries {
    param($Connection)
    $response = Invoke-AgRpc $Connection 'JetboxSubscribeToSummaries' @{} -Stream
    if (!$response.PSObject.Properties['updates']) { throw 'API de summaries não reconhecida. Nenhum índice foi alterado.' }
    $map = @{}
    foreach ($prop in $response.updates.PSObject.Properties) {
        $guid = [guid]::Empty
        if (![guid]::TryParse($prop.Name,[ref]$guid)) { throw 'ID de conversa inválido no índice nativo.' }
        $map[$prop.Name] = $prop.Value
    }
    return ,$map
}

function Assert-AgIdle {
    param([hashtable]$Summaries)
    foreach ($value in $Summaries.Values) {
        if ($value.PSObject.Properties['status'] -and [string]$value.status -match 'RUNNING|QUEUED|CANCELING') {
            throw 'Há uma conversa em execução. Pause o agente e aguarde antes de reparar o índice.'
        }
    }
}

function Find-AgConnection {
    param($Profile)
    $candidates = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -eq 'language_server.exe' -and $_.ExecutablePath -match '(?i)antigravity' -and
        (Get-CommandFlag $_.CommandLine 'subclient_type') -eq 'hub' -and
        $_.CommandLine -notmatch 'cofre-isolado'
    })
    if ($candidates.Count -ne 1) { throw 'Abra somente uma instalação do AntiGravity 2.x e deixe o agente parado. Não foi identificado um único motor hub.' }
    $process = $candidates[0]
    $token = Get-CommandFlag $process.CommandLine 'csrf_token'
    $dataName = Get-CommandFlag $process.CommandLine 'app_data_dir'
    if (!$token -or $dataName -notin @('antigravity','antigravity-ide')) { throw 'Flags do motor não reconhecidas; reparo interrompido.' }
    $gemini = Get-CommandFlag $process.CommandLine 'gemini_dir'
    if (!$gemini) { $gemini = Join-Path $env:USERPROFILE '.gemini' }
    $dataPath = Full-Path (Join-Path $gemini $dataName)
    if (@(Resolve-Roots $Profile | Where-Object { (Full-Path $_.Path) -eq $dataPath }).Count -ne 1) {
        throw 'A pasta usada pelo motor não está mapeada neste perfil. Cadastre o local real antes de reparar.'
    }
    Assert-NoReparse $dataPath
    $version = Get-CommandFlag $process.CommandLine 'override_ide_version'
    if ($version -notmatch '^2\.') { throw "Motor ${version}: reparo nativo disponível somente para a família 2.x. Faça backup e diagnóstico." }
    # Confirma o dono da porta para não enviar o token para outro serviço local.
    $ports = @(Get-NetTCPConnection -OwningProcess $process.ProcessId -State Listen -ErrorAction Stop |
        Where-Object { $_.LocalAddress -in @('127.0.0.1','::1','0.0.0.0','::') } | Select-Object -ExpandProperty LocalPort -Unique | Sort-Object -Descending)
    foreach ($port in $ports) {
        $connection = [pscustomobject]@{ Port=[int]$port; Token=$token; Pid=[int]$process.ProcessId; Executable=$process.ExecutablePath; DataPath=$dataPath; DataName=$dataName; Version=$version }
        try {
            # Descoberta somente leitura. Versões com somente HTTPS são recusadas.
            $probe = Invoke-AgRpc $connection 'GetAllCascadeTrajectories' @{}
            if ($probe) { return $connection }
        } catch { continue }
    }
    throw 'Não foi encontrada uma API HTTP local compatível pertencente ao motor. Nenhum dado foi alterado.'
}

function Assert-AgConnection {
    param($Connection)
    $process = Get-CimInstance Win32_Process -Filter ('ProcessId=' + [int]$Connection.Pid) -ErrorAction Stop
    if (!$process -or $process.ExecutablePath -ne $Connection.Executable -or
        (Get-CommandFlag $process.CommandLine 'csrf_token') -ne $Connection.Token) { throw 'O AntiGravity reiniciou. Execute o reparo novamente.' }
    $listener = @(Get-NetTCPConnection -OwningProcess $Connection.Pid -State Listen -ErrorAction Stop | Where-Object LocalPort -eq $Connection.Port)
    if (!$listener) { throw 'A porta do motor mudou. Execute novamente.' }
}

function Start-AgIsolated {
    param([string]$Executable,[string]$Directory,[string]$DataName='antigravity',[switch]$Hub,[string]$IdeVersion)
    Assert-NoReparse $Executable
    if($DataName -notmatch '^[a-z0-9-]+$'){throw 'Nome de dados inválido.'}
    if(!$IdeVersion){
        $install=[IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($Executable)))
        $appExe=Join-Path $install 'Antigravity.exe'
        if(!(Test-Path -LiteralPath $appExe)){throw 'Informe a versão do aplicativo para o motor isolado.'}
        $IdeVersion=[regex]::Match((Get-Item -LiteralPath $appExe).VersionInfo.ProductVersion,'^\d+\.\d+\.\d+').Value
    }
    if($IdeVersion -notmatch '^2\.\d+\.\d+(?:\.\d+)?$'){throw 'Versão do motor isolado não reconhecida.'}
    Ensure-Directory $Directory
    $token = [guid]::NewGuid().ToString('N')
    $root = Join-Path $Directory 'cofre-isolado'
    Ensure-Directory (Join-Path $root $DataName)
    $stdout = Join-Path $Directory ('motor-' + $token.Substring(0,8) + '.out.log')
    $stderr = $stdout + '.err.log'
    # Windows quoting: caminhos são absolutos sem aspas/control chars e sem barra final.
    if ($root -match '["\r\n]') { throw 'Caminho inválido para o motor isolado.' }
    $arguments = '--standalone --override_ide_name antigravity --override_ide_version ' + $IdeVersion + ' --override_user_agent_name antigravity --gemini_dir "' + $root + '" --app_data_dir ' + $DataName +
        ' --disable_telemetry --use_ls_chrome_devtools_mcp=false --csrf_token ' + $token +
        ' --api_server_url http://127.0.0.1:1 --cloud_code_endpoint http://127.0.0.1:1'
    if ($Hub) { $arguments += ' --subclient_type hub' }
    $stdin=Join-Path $Directory ('stdin-'+$token.Substring(0,8)+'.txt');Write-NewText $stdin ''
    # Proxies somente no ambiente herdado pelo auxiliar: impede downloads HTTP
    # incidentais na inicialização, sem mudar configurações do usuário/Windows.
    $environmentBefore=@{}
    try{
        foreach($name in @('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','NO_PROXY','PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD')){
            $environmentBefore[$name]=[Environment]::GetEnvironmentVariable($name,'Process')
            $value='http://127.0.0.1:1'
            if($name -eq 'NO_PROXY'){$value='127.0.0.1,localhost,::1'}
            if($name -eq 'PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD'){$value='1'}
            [Environment]::SetEnvironmentVariable($name,$value,'Process')
        }
        $process = Start-Process -FilePath $Executable -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardInput $stdin -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    }finally{
        foreach($name in $environmentBefore.Keys){[Environment]::SetEnvironmentVariable($name,$environmentBefore[$name],'Process')}
    }
    $connection = [pscustomobject]@{ Pid=$process.Id; Token=$token; Port=0; Executable=$Executable; Root=$root; DataPath=(Join-Path $root $DataName); Directory=$Directory; Log=$stdout; ErrorLog=$stderr }
    try {
        $until = (Get-Date).AddSeconds(40)
        while ((Get-Date) -lt $until) {
            $process.Refresh()
            if ($process.HasExited) { throw "Motor isolado terminou. Consulte $stderr" }
            $text = ''
            foreach ($log in @($stdout,$stderr)) {
                if (Test-Path -LiteralPath $log) {
                    $stream=[IO.File]::Open($log,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
                    $reader=New-Object IO.StreamReader($stream,[Text.Encoding]::UTF8)
                    try{$text+=$reader.ReadToEnd()}finally{$reader.Dispose()}
                }
            }
            $matchesFound = [regex]::Matches($text,'port at (\d+) for HTTP\b')
            if ($matchesFound.Count) { $connection.Port=[int]$matchesFound[$matchesFound.Count-1].Groups[1].Value; return $connection }
            Start-Sleep -Milliseconds 250
        }
        throw 'O motor isolado não publicou uma porta HTTP em 40 segundos.'
    } catch { Stop-AgIsolated $connection; throw }
}

function Stop-AgIsolated {
    param($Connection)
    if (!$Connection) { return }
    $process = Get-CimInstance Win32_Process -Filter ('ProcessId=' + [int]$Connection.Pid) -ErrorAction SilentlyContinue
    if ($process -and $process.ExecutablePath -eq $Connection.Executable -and
        (Get-CommandFlag $process.CommandLine 'csrf_token') -eq $Connection.Token -and
        (Get-CommandFlag $process.CommandLine 'gemini_dir') -eq $Connection.Root) {
        Stop-Process -Id $Connection.Pid -ErrorAction Stop
    }
}

function Get-AgNativeSummaries {
    param($Connection,[string[]]$Ids)
    $number=0
    foreach ($id in $Ids) {
        Check-Cancel
        $number++
        Write-Line ("  Lendo conversa {0}/{1}: {2}" -f $number,$Ids.Count,$id) DarkGray
        Invoke-AgRpc $Connection 'GetCascadeTrajectory' @{cascadeId=$id;disableRehydration=$true} -Discard
    }
    $response = Invoke-AgRpc $Connection 'GetAllCascadeTrajectories' @{}
    if (!$response.PSObject.Properties['trajectorySummaries']) { throw 'O motor não reconstituiu os summaries.' }
    $map=@{}
    foreach ($prop in $response.trajectorySummaries.PSObject.Properties) { $map[$prop.Name]=$prop.Value }
    foreach ($id in $Ids) { if (!$map.ContainsKey($id)) { throw "Não foi possível reconstruir $id; o índice do aplicativo não será alterado." } }
    return ,$map
}

function Get-AgAbsentIds {
    param([string[]]$Ids,[hashtable]$Existing)
    return @($Ids | Where-Object { !$Existing.ContainsKey($_) } | Sort-Object -Unique)
}

function Invoke-AntigravityRepair {
    param($Profile)
    $live = Find-AgConnection $Profile
    Assert-AgConnection $live
    $before = Read-AgSummaries $live
    Assert-AgIdle $before
    $conversations = Join-Path $live.DataPath 'conversations'
    Assert-NoReparse $conversations
    $dbs = @(Get-ChildItem -LiteralPath $conversations -Filter '*.db' -File -ErrorAction Stop | Where-Object BaseName -Match '^[a-fA-F0-9-]{36}$')
    $missing = @(Get-AgAbsentIds @($dbs.BaseName) $before)
    Write-Line ("AntiGravity {0}: {1} bancos; {2} entradas no índice; {3} ausentes." -f $live.Version,$dbs.Count,$before.Count,$missing.Count) Cyan
    if (!$missing.Count) { Write-Line 'Não há entradas ausentes. Nomes, arquivamentos e favoritos permanecem como estão.' Green; return }
    Write-Line (L 'repairwarning')
    Write-Line (L 'idle') Yellow
    if ((Read-Host (L 'confirm' @('REPARAR'))) -cne 'REPARAR') { Set-VaultOperationCanceled; return }
    Assert-AgConnection $live
    $id=(Get-Date).ToString('yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
    $folder=Join-Path (Join-Path $script:BackupBase 'antigravity-reparos') $id
    Ensure-Directory $folder
    $manifest=[pscustomobject]@{Schema=1;Type='ReparoNativoAntiGravity';Version=$live.Version;Created=(Get-Date).ToString('o');DataPath=$live.DataPath;State='Preparando';Requested=@($missing);Written=@();Preserved=@($before.Keys);Files=@()}
    Write-NewJson (Join-Path $folder 'antes-summaries.json') $before
    # Backups do índice e estado. Dados de conta/tokens não são incluídos aqui.
    $indexDir=Join-Path $folder 'indice-anterior';Ensure-Directory $indexDir
    foreach ($name in @('agyhub_summaries_proto.pb','conversation_summaries.db','antigravity_state.pbtxt')) {
        $source=Join-Path $live.DataPath $name
        if (!(Test-Path -LiteralPath $source -PathType Leaf)) { continue }
        $dest=Join-Path $indexDir $name
        if ($name.EndsWith('.db')) { Copy-SqliteSnapshot $source $dest }
        else { $hash=Hash-File $source;[IO.File]::Copy($source,$dest);if ((Hash-File $dest) -ne $hash -or (Hash-File $source) -ne $hash) { throw 'O índice mudou durante a cópia. Execute novamente com o agente parado.' } }
        $manifest.Files += [pscustomobject]@{Path=('indice-anterior/'+$name);Hash=(Hash-File $dest)}
    }
    $isolated=$null
    try {
        $clone=Join-Path $folder ('cofre-isolado/'+$live.DataName+'/conversations');Ensure-Directory $clone
        [long]$bytes=0;foreach($db in $dbs){if($db.BaseName -in $missing){$bytes+=$db.Length}}
        Assert-Space $folder ($bytes * 2)
        Set-VaultWork (L 'copying') $missing.Count $conversations
        $progressIndex=0
        foreach ($cid in $missing) {
            Update-VaultWork $progressIndex ($cid+'.db')
            $progressIndex++
            $source=Join-Path $conversations ($cid+'.db');$dest=Join-Path $folder ('conversas-originais/'+$cid+'.db')
            Copy-SqliteSnapshot $source $dest
            $manifest.Files += [pscustomobject]@{Path=('conversas-originais/'+$cid+'.db');Hash=(Hash-File $dest)}
            [IO.File]::Copy($dest,(Join-Path $clone ($cid+'.db')))
        }
        $isolated=Start-AgIsolated $live.Executable $folder $live.DataName -IdeVersion $live.Version
        Set-VaultWork (L 'repair') 0 $folder
        $recovered=Get-AgNativeSummaries $isolated $missing
        Stop-AgIsolated $isolated;$isolated=$null
        Write-NewJson (Join-Path $folder 'summaries-reconstruidos.json') $recovered
        $manifest.State='Preparado';Write-NewJson (Join-Path $folder 'preparado.json') $manifest
        Assert-AgConnection $live
        $fresh=Read-AgSummaries $live;Assert-AgIdle $fresh
        $apply=@(Get-AgAbsentIds $missing $fresh)
        # Preserva os favoritos sobreviventes no perfil do hub.
        $pins=@();$storage=Join-Path $env:APPDATA 'Antigravity/app_storage.json'
        if(Test-Path -LiteralPath $storage){$settings=Read-Json $storage;if($settings.PSObject.Properties['pinned_conversations_order']){try{$pins=@($settings.pinned_conversations_order | ConvertFrom-Json)}catch{}}}
        Set-VaultWork (L 'repair') $apply.Count $folder
        foreach ($cid in $apply) {
            Update-VaultWork $manifest.Written.Count $cid
            Check-Cancel
            Assert-AgConnection $live
            $summary=$recovered[$cid]
            if (!$summary.PSObject.Properties['annotations']) { $summary | Add-Member -NotePropertyName annotations -NotePropertyValue ([pscustomobject]@{}) }
            $summary.annotations | Add-Member -NotePropertyName archived -NotePropertyValue $false -Force
            if ($cid -in $pins) { $summary.annotations | Add-Member -NotePropertyName pinned -NotePropertyValue $true -Force }
            [void](Invoke-AgRpc $live 'JetboxWriteSummary' @{cascadeId=$cid;summary=$summary})
            $manifest.Written+= $cid
            Write-NewJson (Join-Path $folder ('gravado-'+$cid+'.json')) ([pscustomobject]@{Id=$cid;Date=(Get-Date).ToString('o')})
        }
        $after=Read-AgSummaries $live
        foreach($cid in @($fresh.Keys)+@($apply)){if(!$after.ContainsKey($cid)){throw "A API não confirmou a entrada $cid."}}
        foreach($cid in $fresh.Keys){
            if((ConvertTo-Json -InputObject $fresh[$cid] -Depth 80 -Compress) -cne (ConvertTo-Json -InputObject $after[$cid] -Depth 80 -Compress)){throw 'Uma entrada existente mudou durante o reparo. Consulte o relatório; nenhum rollback automático será feito sobre uma alteração concorrente.'}
        }
        Set-VaultWork (L 'verify') 0 $live.DataPath
        $persisted=Wait-AgPersistence $live.DataPath @($fresh.Keys+$apply)
        if(!$persisted){throw 'API atualizada, mas a persistência do índice não foi confirmada. Preserve o relatório e confira o aplicativo antes de reiniciá-lo.'}
        $manifest.State='Concluido';Write-NewJson (Join-Path $folder 'resultado.json') $manifest
        Write-Line ("Reparo confirmado na API e no índice persistido: {0} entradas acrescentadas." -f $apply.Count) Green
        Write-Line 'Confira as conversas na interface e depois de reabrir o aplicativo. Títulos recuperados podem ser anteriores à perda do índice.'
        Write-Line ("Cópias e relatório: $folder") Cyan
    } catch {
        $manifest.State='Interrompido'
        Write-NewJson (Join-Path $folder ('falha-'+[guid]::NewGuid().ToString('N')+'.json')) $manifest
        Write-Line ("Interrompido. {0} entradas podem já ter sido acrescentadas. Executar novamente não reescreve IDs existentes. Cópias: {1}" -f $manifest.Written.Count,$folder) Yellow
        throw
    } finally { Stop-AgIsolated $isolated }
}

function Wait-AgPersistence {
    param([string]$DataPath,[string[]]$Ids)
    Initialize-Native
    $proto=Join-Path $DataPath 'agyhub_summaries_proto.pb'
    $dbIndex=Join-Path $DataPath 'conversation_summaries.db'
    $deadline=(Get-Date).AddSeconds(20)
    do{
        try{
            if(Test-Path -LiteralPath $proto){
                $saved=@([Cofre.Native]::SummaryIds($proto))
                if(@($Ids | Where-Object {$_ -notin $saved}).Count -eq 0){return $true}
            }elseif(Test-Path -LiteralPath $dbIndex){
                $ok=$true
                foreach($cid in $Ids){
                    if($cid -notmatch '^[a-fA-F0-9-]{36}$'){throw 'ID inválido.'}
                    if([Cofre.Native]::Scalar($dbIndex,("select count(*) from conversation_summaries where conversation_id='"+$cid+"'")) -ne '1'){$ok=$false}
                }
                if($ok){return $true}
            }
        }catch{ # Uma gravação atômica pode estar trocando o arquivo; a API já confirmou os IDs.
        }
        Start-Sleep -Milliseconds 250
    }while((Get-Date) -lt $deadline)
    return $false
}

function Invoke-AppRepairInternal {
    param($Profile)
    if ($Profile.Id -eq 'antigravity') { Invoke-AntigravityRepair $Profile; return }
    Show-Diagnostic $Profile
    Write-Line (L 'nospecificrepair') Cyan
    Write-Line 'Não há reconstrução validada de índice nesta versão. O script não inventa registros nem altera bancos de outros formatos.'
}

function Invoke-AppRepair {
    param($Profile)
    Invoke-VaultOperation $Profile (L 'working_repair') { Invoke-AppRepairInternal $Profile }
}
