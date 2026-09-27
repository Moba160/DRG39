$dir = "g:\Meine Ablage\Eisenbahn\Franky\PlatformIO\DRG39\data\rollmaterial"
$outputFile = Join-Path $dir "fahrzeuge.csv"

# Create or clear output file with UTF-8 encoding
Set-Content -Path $outputFile -Value "ID`tGattungsbezirk`tOrdnungsnummer" -Encoding UTF8

function Process-Csv {
    param(
        [string]$FileName,
        [string]$IdColumn,
        [string]$OrdColumn
    )
    $filePath = Join-Path $dir $FileName
    
    # Read all lines, filter out comments and empty lines
    $lines = Get-Content $filePath -Encoding UTF8 | Where-Object { 
        $_.Trim() -ne '' -and -not $_.StartsWith(';') 
    }
    
    # Parse as CSV with tab delimiter
    $csv = $lines | ConvertFrom-Csv -Delimiter "`t"
    
    foreach ($row in $csv) {
        $id = $row.$IdColumn
        $ord = $row.$OrdColumn
        if ([string]::IsNullOrEmpty($id) -and [string]::IsNullOrEmpty($ord)) { continue }
        
        $line = "$id`t`t$ord"
        Add-Content -Path $outputFile -Value $line -Encoding UTF8
    }
}

Process-Csv -FileName "loks.csv" -IdColumn "ID" -OrdColumn "Ordnungsnummer"
Process-Csv -FileName "p.csv" -IdColumn "Id" -OrdColumn "Wagennr."
Process-Csv -FileName "g.csv" -IdColumn "Id" -OrdColumn "Wagennummer"

Write-Host "Done"
