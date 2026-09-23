# Inline progress belongs to the current operation, never to PowerShell's overlay.
$script:VaultOperation=$null
$script:VaultWork=$null
$script:VaultProgressRow=$null
$script:VaultProgressWidth=0
$script:VaultProgressTick=[datetime]::MinValue
$script:HashBuffer=New-Object byte[] 1048576

function Suspend-VaultProgress {
    $script:VaultProgressRow=$null
}

function Format-VaultProgress {
    param([string]$Phase,[double]$Done,[double]$Total,[timespan]$Elapsed)
    $bar='.'*16;$percent='--%'
    if($Total -gt 0){
        $value=[Math]::Max(0,[Math]::Min(100,100*$Done/$Total))
        $filled=[int][Math]::Floor(16*$value/100)
        $bar=('#'*$filled)+('-'*(16-$filled));$percent=('{0,5:N1}%' -f $value)
    }
    return ('  [{0}] {1} | {2} | {3:00}:{4:00}:{5:00}' -f $bar,$percent,$Phase,[int][Math]::Floor($Elapsed.TotalHours),$Elapsed.Minutes,$Elapsed.Seconds)
}

function Limit-VaultText {
    param([string]$Text,[int]$Width)
    $Text=$Text -replace '[\r\n\t]',' '
    $result=New-Object Text.StringBuilder;$cells=0
    $elements=[Globalization.StringInfo]::GetTextElementEnumerator($Text)
    while($elements.MoveNext()){
        $part=$elements.GetTextElement();$code=[int][char]$part[0]
        $size=1
        if($code -ge 0x1100 -and ($code -le 0x115f -or $code -ge 0x2e80 -and $code -le 0xa4cf -or $code -ge 0xac00 -and $code -le 0xd7af -or $code -ge 0xd800 -and $code -le 0xdfff -or $code -ge 0xf900)){$size=2}
        if($cells+$size -gt $Width-3){[void]$result.Append('...');$cells+=3;break}
        [void]$result.Append($part);$cells+=$size
    }
    return $result.ToString()+(' '*[Math]::Max(0,$Width-$cells))
}

function Show-VaultProgress {
    param([string]$Phase,[string]$Path='',[double]$Done=0,[double]$Total=0,[switch]$Force)
    if($script:TestMode -or !$script:VaultOperation){return}
    $now=Get-Date
    $interactive=$false
    try{$interactive=![Console]::IsOutputRedirected -and [Console]::BufferWidth -gt 20}catch{}
    $interval=if($interactive){200}else{5000}
    if(!$Force -and ($now-$script:VaultProgressTick).TotalMilliseconds -lt $interval){return}
    $script:VaultProgressTick=$now
    $line=Format-VaultProgress $Phase $Done $Total ($now-$script:VaultOperation.Started)
    if(!$interactive){Write-Host $line -ForegroundColor Cyan;if($Path){Write-Host ('  '+$Path) -ForegroundColor DarkGray};return}
    try{
        $width=[Math]::Max(20,[Math]::Min(160,[Console]::BufferWidth-2))
        if($null -ne $script:VaultProgressRow -and $script:VaultProgressWidth -eq $width -and $script:VaultProgressRow -ge 0 -and $script:VaultProgressRow+2 -lt [Console]::BufferHeight){
            [Console]::SetCursorPosition(0,$script:VaultProgressRow)
        }
        $color=[Console]::ForegroundColor
        try{
            [Console]::ForegroundColor=[ConsoleColor]::Cyan
            [Console]::WriteLine((Limit-VaultText $line $width))
            [Console]::ForegroundColor=[ConsoleColor]::DarkGray
            [Console]::WriteLine((Limit-VaultText ('  '+$Path) $width))
        }finally{[Console]::ForegroundColor=$color}
        $script:VaultProgressRow=[Math]::Max(0,[Console]::CursorTop-2);$script:VaultProgressWidth=$width
    }catch{Suspend-VaultProgress;Write-Host $line}
}

function Set-VaultWork {
    param([string]$Phase,[double]$Total=0,[string]$Path='')
    $script:VaultWork=[pscustomobject]@{Phase=$Phase;Done=0.0;Total=$Total;Path=$Path}
    Show-VaultProgress $Phase $Path 0 $Total -Force
}

function Update-VaultWork {
    param([double]$Done,[string]$Path='',[switch]$Force)
    if(!$script:VaultWork){return}
    $script:VaultWork.Done=$Done;$script:VaultWork.Path=$Path
    Show-VaultProgress $script:VaultWork.Phase $Path $Done $script:VaultWork.Total -Force:$Force
}

function Show-VaultFileProgress {
    param([string]$Path,[long]$Position,[long]$Length)
    if($script:TestMode -or !$script:VaultOperation){return}
    $fraction=if($Length -gt 0){[Math]::Min(0.999,$Position/[double]$Length)}else{0}
    if($script:VaultWork){Show-VaultProgress $script:VaultWork.Phase $Path ($script:VaultWork.Done+$fraction) $script:VaultWork.Total}
    else{Show-VaultProgress (L 'inventory') $Path $Position $Length}
}

function Invoke-VaultOperation {
    param($Profile,[string]$Action,[scriptblock]$Body)
    if($script:VaultOperation -or $script:TestMode){& $Body;return}
    $script:VaultOperation=[pscustomobject]@{Started=(Get-Date);Action=$Action;App=$Profile.Name;Canceled=$false}
    $script:VaultWork=$null;$script:VaultProgressRow=$null;$script:VaultProgressTick=[datetime]::MinValue
    try{
        $color=if($Profile.PSObject.Properties['Color']){$Profile.Color}else{'Cyan'}
        Write-Line '';Write-Line ('  '+$Profile.Name+' | '+$Action) $color
        Set-VaultWork (L 'progress_prepare')
        $result=@(& $Body)
        if($script:VaultOperation.Canceled){Show-VaultProgress (L 'progress_cancelled') '' 0 0 -Force}
        else{Show-VaultProgress (L 'progress_finished') '' 1 1 -Force}
        return $result
    }catch{
        Show-VaultProgress (L 'progress_failed') $_.Exception.Message 0 0 -Force
        throw
    }finally{Suspend-VaultProgress;$script:VaultOperation=$null;$script:VaultWork=$null}
}

function Set-VaultOperationCanceled {
    if($script:VaultOperation){$script:VaultOperation.Canceled=$true}
}
