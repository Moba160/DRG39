$dir = "g:\Meine Ablage\Eisenbahn\Franky\PlatformIO\DRG39\data\rollmaterial"
$loksFile = Join-Path $dir "loks.csv"
$fahrzeugeFile = Join-Path $dir "fahrzeuge.csv"

# Read loks.csv
$loksLines = [System.IO.File]::ReadAllLines($loksFile, [System.Text.Encoding]::UTF8)
$loksHeader = $loksLines[0].Split("`t")

$idxId       = [Array]::IndexOf($loksHeader, "ID")
$idxGatNeu   = [Array]::IndexOf($loksHeader, "Gattung neu")
$idxGatAlt   = [Array]::IndexOf($loksHeader, "Gattung alt")

if ($idxId -lt 0 -or $idxGatNeu -lt 0 -or $idxGatAlt -lt 0) {
    Write-Host "ERROR: Could not find required columns in loks.csv"
    Write-Host "ID=$idxId, Gattung neu=$idxGatNeu, Gattung alt=$idxGatAlt"
    exit 1
}

# Build lookup: ID -> Gattungsbezirk string
$gattungMap = @{}
foreach ($line in $loksLines[1..($loksLines.Count-1)]) {
    if (-not $line.Trim() -or $line.StartsWith(";")) { continue }
    $cols = $line.Split("`t")
    $id = if ($idxId -lt $cols.Count) { $cols[$idxId].Trim() } else { "" }
    if (-not $id) { continue }
    $gatNeu = if ($idxGatNeu -lt $cols.Count) { $cols[$idxGatNeu].Trim() } else { "" }
    $gatAlt = if ($idxGatAlt -lt $cols.Count) { $cols[$idxGatAlt].Trim() } else { "" }
    
    # Build Gattungsbezirk value
    $gattung = $gatNeu
    if ($gatAlt -ne "") {
        if ($gattung -ne "") {
            $gattung += " ($gatAlt)"
        } else {
            $gattung = "($gatAlt)"
        }
    }
    $gattungMap[$id] = $gattung
}

Write-Host "Loaded $($gattungMap.Count) lok entries with Gattung"

# Read fahrzeuge.csv
$fahrzeugeLines = [System.IO.File]::ReadAllLines($fahrzeugeFile, [System.Text.Encoding]::UTF8)
$fahrzeugeHeader = $fahrzeugeLines[0].Split("`t")

$fidxId          = [Array]::IndexOf($fahrzeugeHeader, "ID")
$fidxGattung     = [Array]::IndexOf($fahrzeugeHeader, "Gattungsbezirk")

if ($fidxId -lt 0 -or $fidxGattung -lt 0) {
    Write-Host "ERROR: Could not find required columns in fahrzeuge.csv"
    Write-Host "ID=$fidxId, Gattungsbezirk=$fidxGattung"
    exit 1
}

# Update fahrzeuge.csv - only for L-entries
$updated = 0
$newLines = New-Object System.Collections.Generic.List[string]
$newLines.Add($fahrzeugeLines[0])  # header

foreach ($line in $fahrzeugeLines[1..($fahrzeugeLines.Count-1)]) {
    # Keep section headers and empty lines as-is
    if ($line.StartsWith(";") -or -not $line.Trim()) {
        $newLines.Add($line)
        continue
    }
    
    $cols = $line.Split("`t")
    $id = if ($fidxId -lt $cols.Count) { $cols[$fidxId].Trim() } else { "" }
    
    # Only fill Gattungsbezirk for Lok entries (L-prefix)
    if ($id.StartsWith("L") -and $gattungMap.ContainsKey($id)) {
        # Ensure cols array is long enough
        while ($cols.Count -le $fidxGattung) { $cols += "" }
        $cols[$fidxGattung] = $gattungMap[$id]
        $newLines.Add([string]::Join("`t", $cols))
        $updated++
    } else {
        $newLines.Add($line)
    }
}

[System.IO.File]::WriteAllLines($fahrzeugeFile, $newLines, [System.Text.Encoding]::UTF8)
Write-Host "Updated $updated Lok entries in fahrzeuge.csv"
