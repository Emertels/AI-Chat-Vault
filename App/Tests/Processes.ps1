$ErrorActionPreference='Stop'
. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'AI-Chat-Vault.ps1') -Idioma en
Load-Profiles
$session=[Diagnostics.Process]::GetCurrentProcess().SessionId
$created=(Get-Date).AddMinutes(-5)
function Mock-Process($Id,$Parent,$Name,$Command='',$Path='C:\Fixture\unknown.exe') {
    return [pscustomobject]@{ProcessId=$Id;ParentProcessId=$Parent;Name=$Name;CommandLine=$Command;ExecutablePath=$Path;SessionId=$session;CreationDate=$created.AddSeconds($Id)}
}
foreach($profile in $script:Profiles){
    $table=@((Mock-Process 100 1 $profile.Processes[0]),(Mock-Process 101 100 'worker.exe'),(Mock-Process 102 101 'node.exe'),(Mock-Process 200 1 'unrelated.exe'))
    $result=@(Get-AppProcessTree $profile $table)
    Assert-Test ($result.Count -eq 3) ('Process tree for '+$profile.Id)
}
$open=Get-Profile opencode
Assert-Test (Test-AppProcess $open (Mock-Process 100 1 'opencode-cli.exe')) 'Orphan OpenCode sidecar.'
Assert-Test (!(Test-AppProcess $open (Mock-Process 100 1 'node.exe' 'node.exe C:\tools\other.js --prompt opencode'))) 'Do not match prompt arguments.'
Assert-Test (Test-AppProcess $open (Mock-Process 100 1 'node.exe' 'node.exe "C:\apps\opencode\bin.js" serve')) 'Runtime entry point.'
Assert-Test (!(Test-AppProcess (Get-Profile continue) (Mock-Process 100 1 'node.exe' 'node.exe C:\discontinued\main.js'))) 'Do not match partial words.'
$table=@((Mock-Process 100 1 'OpenCode.exe'),(Mock-Process 101 100 'worker.exe'))
$old=@(Get-AppProcessTree $open $table)
Assert-Test (@(Get-AppProcessTree $open @($table[1]) $old).Count -eq 1) 'Retain child after parent exits.'
$table[1].CreationDate=$created.AddSeconds(90)
Assert-Test (@(Get-AppProcessTree $open $table).Count -eq 1) 'Reject child of reused parent PID.'
$table[1].SessionId=$session+1
Assert-Test (@(Get-AppProcessTree $open $table).Count -eq 1) 'Do not target another session.'
$self=Get-CimInstance Win32_Process -Filter "ProcessId=$PID"
$blocked=$false
try { Assert-ProcessTargets @($self) @(Get-VaultProcessTable) } catch { $blocked=$_.Exception.Message -eq (L 'process_host') }
Assert-Test $blocked 'Protect vault and launching application.'

# A disposable .NET helper ignores window-close requests, and creates a worker.
# Never terminate actual user applications in tests.
$temp=Join-Path ([IO.Path]::GetTempPath()) ('Vault-process-test-'+[guid]::NewGuid().ToString('N'))
Ensure-Directory $temp
$source=Join-Path $temp 'helper.cs'
$exe=Join-Path $temp ('VaultFixture-'+[guid]::NewGuid().ToString('N')+'.exe');$childExe=Join-Path $temp 'VaultWorker.exe'
[IO.File]::WriteAllText($source,@'
using System;
using System.Diagnostics;
using System.Threading;
class Fixture {
  static void Main(string[] args) {
    if(args.Length > 1 && args[0] == "parent") {
      var start = new ProcessStartInfo(args[1], "child");
      start.UseShellExecute = false; start.CreateNoWindow = true;
      Process.Start(start);
    }
    Thread.Sleep(120000);
  }
}
'@)
$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
& $compiler /nologo /target:winexe "/out:$exe" $source
if($LASTEXITCODE -ne 0){throw 'Fixture compilation failed.'}
Copy-Item -LiteralPath $exe -Destination $childExe
$profile=New-Profile 'process-fixture' 'Process fixture' @([IO.Path]::GetFileName($exe)) '' @((New-Root 'data' (Join-Path $temp 'data'))) 'Disposable fixture'
Ensure-Directory $profile.Roots[0].Path
$file=Join-Path $profile.Roots[0].Path 'chat.txt';Write-NewText $file 'original'
$script:BackupBase=Join-Path $temp 'portable vault\Backups'
$script:JournalBase=Join-Path $script:BackupBase '_transactions'
$script:LogPath=$null;$script:TestMode=$false
$launched=@()
function Start-Fixture {
    $handle=Start-Process -FilePath $exe -ArgumentList @('parent',('"'+$childExe+'"')) -WindowStyle Hidden -PassThru
    $script:fixtureHandles+=@($handle)
    for($i=0;$i -lt 20;$i++){
        $tree=@(Get-AppProcessTree $profile @(Get-VaultProcessTable))
        if($tree.Count -ge 2){return $tree}
        Start-Sleep -Milliseconds 100
    }
    throw 'Fixture child failed to start.'
}
$script:fixtureHandles=@()
try {
    $records=@(Start-Fixture)
    $reused=$records[0] | Select-Object *;$reused.CreationDate=$reused.CreationDate.AddSeconds(-30)
    Stop-VaultProcess $reused -Force
    Assert-Test ([bool](Get-Process -Id $records[0].ProcessId -ErrorAction SilentlyContinue)) 'PID creation mismatch must not terminate.'
    $backup=New-Snapshot $profile @(Resolve-Roots $profile)
    Assert-Test (@(Get-AppProcessTree $profile @(Get-VaultProcessTable) $records).Count -eq 0) 'Backup must stop parent and worker.'
    [void](Test-Snapshot $backup)
    Assert-Test (Is-Within $backup $script:BackupBase) 'Backup beside portable vault.'
    [IO.File]::WriteAllText($file,'later')
    $records=@(Start-Fixture)
    function Read-Host { param($Prompt) return '1' }
    Restore-Snapshot $profile $backup
    Assert-Test ([IO.File]::ReadAllText($file) -eq 'original') 'Restore after automatic shutdown.'
    Assert-Test (@(Get-AppProcessTree $profile @(Get-VaultProcessTable) $records).Count -eq 0) 'Restore must stop workers.'
    # Read-only guard never kills an app that reappears after preparation.
    $records=@(Start-Fixture);$blocked=$false
    try{Assert-AppClosed $profile}catch{$blocked=$true}
    Assert-Test $blocked 'Mid-operation reopen guard.'
    Assert-Test ([bool](Get-Process -Id $records[0].ProcessId -ErrorAction SilentlyContinue)) 'Guard must not mutate processes.'
    Stop-AppForDataOperation $profile
    Write-Output 'PASS: 20 profile trees; OpenCode sidecar; unrelated arguments; orphans; PID reuse; session/ancestor guards; real fixture forced shutdown; backup/restore; reopen guard.'
} finally {
    # Only handles to synthetic processes in this unique temporary directory.
    foreach($proc in @(Get-VaultProcessTable | Where-Object { $_.ExecutablePath -in @($exe,$childExe) })) { Stop-VaultProcess $proc -Force }
    foreach($handle in $script:fixtureHandles){$handle.Dispose()}
}
