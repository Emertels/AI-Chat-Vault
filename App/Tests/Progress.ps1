$ErrorActionPreference='Stop'
. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'AI-Chat-Vault.ps1') -Idioma en
Assert-Test ((Format-VaultProgress 'Hash' 1 2 ([timespan]::FromSeconds(65))) -match '50[.,]0%.*Hash.*00:01:05') 'Measured percentage / elapsed.'
Assert-Test ((Format-VaultProgress 'Counting' 100 0 ([timespan]::Zero)) -match '--%') 'No fabricated counting percentage.'
Assert-Test ((Format-VaultProgress 'Hash' 9 2 ([timespan]::Zero)) -match '100[.,]0%') 'Clamp progress.'
Assert-Test ((Limit-VaultText ('A'*300) 50).Length -eq 50) 'Bounded ASCII output.'
Assert-Test ((Limit-VaultText ('日本語'*50) 30).Length -le 30) 'Wide text output.'
$profile=New-Profile 'display-fixture' 'Display fixture' @('nonexistent-vault-fixture.exe') '' @() ''
$script:TestMode=$false
$output=(& { Invoke-VaultOperation $profile (L 'working_backup') { Set-VaultWork 'Fixture SHA-256' 2 'chat.txt';Update-VaultWork 1 'chat.txt' -Force;return 'OUTPUT-SENTINEL' } } 6>&1 | Out-String)
Assert-Test ($output.Contains('Backing up') -and ($output -match '50[.,]0%') -and $output.Contains('OUTPUT-SENTINEL')) 'Inline progress and return value.'
Assert-Test ($null -eq $script:VaultOperation) 'Operation state leaked.'
$output=(& { Invoke-VaultOperation $profile (L 'working_restore') { Set-VaultOperationCanceled } } 6>&1 | Out-String)
Assert-Test ($output.Contains('Cancelled') -and !$output.Contains('Operation finished')) 'Cancellation is not success.'
$caught=$false
$output=(& { try { Invoke-VaultOperation $profile 'Failure fixture' {throw 'EXPECTED-FAILURE'} } catch { $script:caught=$true } } 6>&1 | Out-String)
Assert-Test ($caught -and $output.Contains('Operation interrupted') -and !$output.Contains('Operation finished')) 'Failure is not success.'
Assert-Test ($null -eq $script:VaultOperation) 'Error state leaked.'
Write-Output 'PASS: inline progress, percentages, unknown totals, elapsed time, width, output preservation, cancellation and error cleanup.'
