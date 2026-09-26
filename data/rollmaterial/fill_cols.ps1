$dir = "g:\Meine Ablage\Eisenbahn\Franky\PlatformIO\DRG39\data\rollmaterial"
$loksFile      = Join-Path $dir "loks.csv"
$fahrzeugeFile = Join-Path $dir "fahrzeuge.csv"

# ── 1. Read loks.csv ────────────────────────────────────────────────────────
$loksLines  = [System.IO.File]::ReadAllLines($loksFile, [System.Text.Encoding]::UTF8)
$loksHeader = $loksLines[0].Split("`t")

$idxId  = [Array]::IndexOf($loksHeader, "ID")
$idxRbd = [Array]::IndexOf($loksHeader, "RBD oder Bezirk")
$idxBw  = [Array]::IndexOf($loksHeader, "BW")
$idxHst = [Array]::IndexOf($loksHeader, "Hst")
$idxArt = [Array]::IndexOf($loksHeader, "Artikelnummer")

Write-Host "Cols: ID=$idxId RBD=$idxRbd BW=$idxBw Hst=$idxHst Art=$idxArt"

function SafeCol($cols, $idx) {
    if ($idx -ge 0 -and $idx -lt $cols.Count) { return $cols[$idx].Trim() }
    return ""
}

# Build lookup: ID -> hashtable with fields
$lokMap = @{}
for ($i = 1; $i -lt $loksLines.Count; $i++) {
    $line = $loksLines[$i]
    if (-not $line.Trim() -or $line.StartsWith(";")) { continue }
    $c  = $line.Split("`t")
    $id = SafeCol $c $idxId
    if (-not $id) { continue }
    $entry = New-Object PSObject -Property @{
        Rbd = SafeCol $c $idxRbd
        Bw  = SafeCol $c $idxBw
        Hst = SafeCol $c $idxHst
        Art = SafeCol $c $idxArt
    }
    $lokMap[$id] = $entry
}
Write-Host "Loaded $($lokMap.Count) lok entries"

# ── 2. Read fahrzeuge.csv, rebuild with fixed header + filled cols ──────────
$fahrzeugeLines = [System.IO.File]::ReadAllLines($fahrzeugeFile, [System.Text.Encoding]::UTF8)

$newHeader = "ID`tEpoche`tBV`tGattungsbezirk`tOrdnungsnummer`tDirektion`tBahnbetriebswerk`tHst`tArt.-Nr."
$newLines  = New-Object System.Collections.Generic.List[string]
$newLines.Add($newHeader)

$updL = 0; $skipL = 0

for ($i = 1; $i -lt $fahrzeugeLines.Count; $i++) {
    $line = $fahrzeugeLines[$i]
    if ($line.StartsWith(";") -or -not $line.Trim()) {
        $newLines.Add($line); continue
    }

    $cols = $line.Split("`t")
    $id   = if ($cols.Count -gt 0) { $cols[0].Trim() } else { "" }

    # Ensure 9 columns
    $arr = New-Object string[] 9
    for ($j = 0; $j -lt [Math]::Min($cols.Count, 9); $j++) { $arr[$j] = $cols[$j] }

    if ($id.StartsWith("L") -and $lokMap.ContainsKey($id)) {
        $e = $lokMap[$id]
        $arr[5] = $e.Rbd
        $arr[6] = $e.Bw
        $arr[7] = $e.Hst
        $arr[8] = $e.Art
        $updL++
    } else {
        $skipL++
    }

    $newLines.Add([string]::Join("`t", $arr))
}

[System.IO.File]::WriteAllLines($fahrzeugeFile, $newLines, [System.Text.Encoding]::UTF8)
Write-Host "Done. Updated=$updL skipped=$skipL"
