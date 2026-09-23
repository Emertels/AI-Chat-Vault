# Process shutdown is a preparation step only. Guards during copying remain read-only.
function Get-VaultProcessTable {
    return @(Get-CimInstance Win32_Process -ErrorAction Stop)
}

function Test-AppProcess {
    param($Profile,$Process)
    if ($Process.Name -in @($Profile.Processes)) { return $true }
    # Known sidecar, also for profiles saved by earlier versions.
    if ($Profile.Id -eq 'opencode' -and $Process.Name -eq 'opencode-cli.exe') { return $true }
    if (!$Profile.CommandMatch) { return $false }
    $entry=[string]$Process.ExecutablePath
    if ($Process.Name -match '^(node|python|pythonw|bun|deno)\.exe$') {
        # Match the runtime entry point, never prompt text or arbitrary later arguments.
        $tokens=@([regex]::Matches([string]$Process.CommandLine,'"[^"]*"|\S+') | ForEach-Object { $_.Value.Trim('"') })
        if ($tokens.Count -lt 2) { return $false }
        $index=1
        while ($index -lt $tokens.Count -and $tokens[$index] -in @('--no-warnings','--enable-source-maps','--unhandled-rejections=strict','-u')) { $index++ }
        if ($index -ge $tokens.Count -or $tokens[$index].StartsWith('-')) { return $false }
        $entry=$tokens[$index]
    } elseif ($Process.Name -notmatch '^(language_server.*|.*agent.*)\.exe$') { return $false }
    return ($entry -match ('(?i)(?:^|[\\/ @._-])(?:'+$Profile.CommandMatch+ ')(?=$|[\\/ ._@-])'))
}

function Get-AppProcessTree {
    param($Profile,[object[]]$Table,[object[]]$Tracked=@())
    $found=@{}
    foreach ($proc in $Table) {
        if ([int]$proc.SessionId -ne [Diagnostics.Process]::GetCurrentProcess().SessionId) { continue }
        $retained=@($Tracked | Where-Object { $_.ProcessId -eq $proc.ProcessId -and $_.CreationDate -eq $proc.CreationDate }).Count -gt 0
        if ($retained -or (Test-AppProcess $Profile $proc)) { $found[[int]$proc.ProcessId]=$proc }
    }
    do {
        $added=$false
        foreach ($proc in $Table) {
            if ($found.ContainsKey([int]$proc.ProcessId) -or !$found.ContainsKey([int]$proc.ParentProcessId)) { continue }
            $parent=$found[[int]$proc.ParentProcessId]
            if ($proc.CreationDate -lt $parent.CreationDate -or $proc.SessionId -ne $parent.SessionId) { continue }
            $found[[int]$proc.ProcessId]=$proc;$added=$true
        }
    } while ($added)
    return @($found.Values | Sort-Object CreationDate,ProcessId)
}

function Get-VaultAncestorIds {
    param([object[]]$Table)
    $lookup=@{};foreach($proc in $Table){$lookup[[int]$proc.ProcessId]=$proc}
    $seen=@{};$current=[int]$PID
    while ($current -gt 0 -and !$seen.ContainsKey($current)) {
        $seen[$current]=$true
        if (!$lookup.ContainsKey($current)) { break }
        $child=$lookup[$current];$parentId=[int]$child.ParentProcessId
        if (!$lookup.ContainsKey($parentId) -or $lookup[$parentId].CreationDate -gt $child.CreationDate) { break }
        $current=$parentId
    }
    return @($seen.Keys)
}

function Assert-ProcessTargets {
    param([object[]]$Targets,[object[]]$Table)
    $ancestors=@(Get-VaultAncestorIds $Table)
    if (@($Targets | Where-Object { [int]$_.ProcessId -in $ancestors }).Count) { throw (L 'process_host') }
    $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    foreach($proc in $Targets){
        try { $owner=Invoke-CimMethod -InputObject $proc -MethodName GetOwnerSid -ErrorAction Stop }
        catch {
            if (!(Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue)) { continue }
            throw (L 'process_denied' @($proc.Name,$proc.ProcessId))
        }
        if ($owner.ReturnValue -ne 0 -or $owner.Sid -ne $sid) {
            if (!(Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue)) { continue }
            throw (L 'process_denied' @($proc.Name,$proc.ProcessId))
        }
    }
}

function Stop-VaultProcess {
    param($Record,[switch]$Force)
    $handle=Get-Process -Id $Record.ProcessId -ErrorAction SilentlyContinue
    if (!$handle) { return }
    try {
        # Pin the OS process handle and check creation time: never terminate a reused PID.
        $null=$handle.Handle
        if ($handle.HasExited) { return }
        if ([Math]::Abs(($handle.StartTime.ToUniversalTime()-([datetime]$Record.CreationDate).ToUniversalTime()).TotalMilliseconds) -gt 2) { return }
        if ($Force) { $handle.Kill() }
        else { [void]$handle.CloseMainWindow() }
    } catch {
        if (!$handle.HasExited) { throw (L 'process_denied' @($Record.Name,$Record.ProcessId)) }
    } finally { $handle.Dispose() }
}

function Stop-AppForDataOperation {
    param($Profile)
    if ($script:TestMode) { return }
    $table=@(Get-VaultProcessTable)
    $tracked=@(Get-AppProcessTree $Profile $table)
    if (!$tracked.Count) { return }
    Assert-ProcessTargets $tracked $table
    Write-Line (L 'process_closing' @($Profile.Name)) Yellow
    Write-Log ('PROCESS close requested | '+$Profile.Id+' | '+(($tracked | ForEach-Object { '{0}:{1}' -f $_.Name,$_.ProcessId }) -join ', '))
    foreach ($proc in $tracked) { Stop-VaultProcess $proc }
    $watch=[Diagnostics.Stopwatch]::StartNew();$quiet=0;$forceShown=$false
    while ($watch.Elapsed.TotalSeconds -lt 15) {
        Start-Sleep -Milliseconds 500
        $table=@(Get-VaultProcessTable)
        $targets=@(Get-AppProcessTree $Profile $table $tracked)
        if (!$targets.Count) {
            $quiet++
            if ($quiet -ge 3) { Write-Line (L 'process_closed') Green;Write-Log ('PROCESS closed | '+$Profile.Id);return }
            continue
        }
        $quiet=0;$tracked=$targets
        Assert-ProcessTargets $targets $table
        if ($watch.Elapsed.TotalSeconds -ge 3) {
            if (!$forceShown) { Write-Line (L 'process_forcing') Yellow;$forceShown=$true }
            foreach ($proc in $targets) { Stop-VaultProcess $proc -Force }
        }
    }
    throw (L 'process_timeout' @($Profile.Name))
}

function Assert-AppClosed {
    param($Profile)
    if ($script:TestMode) { return }
    $busy=@(Get-AppProcessTree $Profile @(Get-VaultProcessTable))
    if ($busy.Count) {
        $names=($busy | ForEach-Object { '{0} (PID {1})' -f $_.Name,$_.ProcessId }) -join ', '
        throw (L 'busy' @($names))
    }
}
