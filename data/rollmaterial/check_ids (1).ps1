$dir = "g:\Meine Ablage\Eisenbahn\Franky\PlatformIO\DRG39\data\rollmaterial"

function Check-MissingIds {
    param(
        [string]$FileName,
        [string]$IdColumn
    )
    $filePath = Join-Path $dir $FileName
    
    $lines = Get-Content $filePath -Encoding UTF8 | Where-Object { 
        $_.Trim() -ne '' -and -not $_.StartsWith(';') 
    }
    
    $csv = $lines | ConvertFrom-Csv -Delimiter "`t"
    
    $missingCount = 0
    foreach ($row in $csv) {
        $id = $row.$IdColumn
        if ([string]::IsNullOrWhiteSpace($id)) {
            Write-Host "Fehlende ID in $FileName - Zeile: $($row | ConvertTo-Json -Compress)"
            $missingCount++
        }
    }
    if ($missingCount -eq 0) {
        Write-Host "Keine fehlenden IDs in $FileName gefunden."
    }
}

Check-MissingIds -FileName "loks.csv" -IdColumn "ID"
Check-MissingIds -FileName "p.csv" -IdColumn "Id"
Check-MissingIds -FileName "g.csv" -IdColumn "Id"
