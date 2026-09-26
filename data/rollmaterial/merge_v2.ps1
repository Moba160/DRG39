$dir = "g:\Meine Ablage\Eisenbahn\Franky\PlatformIO\DRG39\data\rollmaterial"
$outputFile = Join-Path $dir "fahrzeuge.csv"

# Function to get max ID from a file
function Get-MaxId {
    param([string]$FileName, [string]$IdColName, [string]$Prefix)
    $filePath = Join-Path $dir $FileName
    $max = 0
    
    # Read using Default encoding (Windows-1252 on German systems) to correctly read special characters
    $lines = Get-Content $filePath -Encoding Default
    $headers = $null
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith(";")) { continue }
        if ($headers -eq $null) {
            $headers = $line.Split("`t") | ForEach-Object { $_.Trim() }
            continue
        }
        $cols = $line.Split("`t")
        $idIdx = [array]::IndexOf($headers, $IdColName)
        if ($idIdx -ge 0 -and $idIdx -lt $cols.Length) {
            $idStr = $cols[$idIdx].Trim()
            if ($idStr.StartsWith($Prefix)) {
                $num = $idStr.Substring($Prefix.Length)
                $val = 0
                if ([int]::TryParse($num, [ref]$val)) {
                    if ($val -gt $max) { $max = $val }
                }
            }
        }
    }
    return $max
}

$maxL = Get-MaxId -FileName "loks.csv" -IdColName "ID" -Prefix "L"
$maxP = Get-MaxId -FileName "p.csv" -IdColName "Id" -Prefix "P"
$maxG = Get-MaxId -FileName "g.csv" -IdColName "Id" -Prefix "G"

$outLines = New-Object System.Collections.Generic.List[string]
$outLines.Add("ID`tEpoche`tBV`tGattungsbezirk`tOrdnungsnummer")

function Process-File {
    param([string]$FileName, [string]$IdColName, [string]$OrdColName, [string]$GatColName, [string]$Prefix, [ref]$maxRef)
    $filePath = Join-Path $dir $FileName
    
    $lines = Get-Content $filePath -Encoding Default
    $headers = $null
    
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        
        if ($line.StartsWith(";")) {
            $outLines.Add($line)
            continue
        }
        
        if ($headers -eq $null) {
            $headers = $line.Split("`t") | ForEach-Object { $_.Trim() }
            continue
        }
        
        $cols = $line.Split("`t")
        
        $idIdx = [array]::IndexOf($headers, $IdColName)
        $epIdx = [array]::IndexOf($headers, "Ep")
        $bvIdx = [array]::IndexOf($headers, "BV")
        $ordIdx = [array]::IndexOf($headers, $OrdColName)
        
        $gatIdx = -1
        if (-not [string]::IsNullOrEmpty($GatColName)) {
            $gatIdx = [array]::IndexOf($headers, $GatColName)
        }
        
        $idStr = ""
        $epStr = ""
        $bvStr = ""
        $ordStr = ""
        $gatStr = ""
        
        if ($idIdx -ge 0 -and $idIdx -lt $cols.Length) { $idStr = $cols[$idIdx].Trim() }
        if ($epIdx -ge 0 -and $epIdx -lt $cols.Length) { $epStr = $cols[$epIdx].Trim() }
        if ($bvIdx -ge 0 -and $bvIdx -lt $cols.Length) { $bvStr = $cols[$bvIdx].Trim() }
        if ($ordIdx -ge 0 -and $ordIdx -lt $cols.Length) { $ordStr = $cols[$ordIdx].Trim() }
        if ($gatIdx -ge 0 -and $gatIdx -lt $cols.Length) { $gatStr = $cols[$gatIdx].Trim() }
        
        if ([string]::IsNullOrEmpty($idStr) -and [string]::IsNullOrEmpty($ordStr) -and [string]::IsNullOrEmpty($epStr) -and [string]::IsNullOrEmpty($bvStr) -and [string]::IsNullOrEmpty($gatStr)) { continue }
        
        if ([string]::IsNullOrEmpty($idStr)) {
            $maxRef.Value++
            $idStr = "$Prefix$($maxRef.Value)"
        }
        
        $outLines.Add("$idStr`t$epStr`t$bvStr`t$gatStr`t$ordStr")
    }
}

Process-File -FileName "loks.csv" -IdColName "ID" -OrdColName "Ordnungsnummer" -GatColName "" -Prefix "L" -maxRef ([ref]$maxL)
Process-File -FileName "p.csv" -IdColName "Id" -OrdColName "Wagennr." -GatColName "Bezirk" -Prefix "P" -maxRef ([ref]$maxP)
Process-File -FileName "g.csv" -IdColName "Id" -OrdColName "Wagennummer" -GatColName "Gattungsbezi" -Prefix "G" -maxRef ([ref]$maxG)

Set-Content -Path $outputFile -Value $outLines -Encoding UTF8
Write-Host "Done"
