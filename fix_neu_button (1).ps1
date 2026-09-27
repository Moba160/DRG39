$file = "index.html"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

# Fix 1: Replace broken reset button area
$btnSearchOld = 'id="inv-neu-filter-ord"'
$btnIdx = $content.IndexOf($btnSearchOld)
if ($btnIdx -ge 0) {
    $closeDivIdx = $content.IndexOf('</div>', $btnIdx)
    if ($closeDivIdx -ge 0) {
        $openDivIdx = $content.LastIndexOf('<div style="display:flex;">', $btnIdx)
        if ($openDivIdx -ge 0) {
            $before = $content.Substring(0, $openDivIdx)
            $after  = $content.Substring($closeDivIdx + 6)
            $newBlock = '<div style="display:flex; align-items:center; gap:4px;"><input type="text" id="inv-neu-filter-ord" style="flex:1; box-sizing:border-box;" oninput="invNeuRender()" placeholder="Ord.Nr...."><span id="inv-neu-count" style="font-size:11px; color:#555; white-space:nowrap;"></span><button onclick="invNeuReset()" style="cursor:pointer; padding:0 4px; font-size:13px;" title="Filter zur&uuml;cksetzen">&#10006;</button></div>'
            $content = $before + $newBlock + $after
            Write-Host "Fixed reset button and added match count span"
        }
    }
}

# Fix 2: Add count update at end of invNeuRender - find closing lines of the forEach
$searchEnd = "        }" + [char]13 + [char]10 + "        }" + [char]13 + [char]10
$endIdx = $content.LastIndexOf($searchEnd)
if ($endIdx -gt 0) {
    $contextBefore = $content.Substring([Math]::Max(0, $endIdx - 100), 100)
    if ($contextBefore.Contains("tbody.appendChild")) {
        $insertPos = $endIdx + 9  # after first `        }`
        $countCode = [char]13 + [char]10 + [char]13 + [char]10 + "            // Update match count" + [char]13 + [char]10 +
            "            const totalItems = groups.reduce(function(sum, g) { return sum + g.items.length; }, 0);" + [char]13 + [char]10 +
            "            const countEl = document.getElementById('inv-neu-count');" + [char]13 + [char]10 +
            "            if (countEl) {" + [char]13 + [char]10 +
            "                const hasFilter = filterId || filterEp || filterBv || filterGat || filterOrd || globalEp;" + [char]13 + [char]10 +
            "                countEl.textContent = hasFilter ? (totalItems + ' Treffer') : '';" + [char]13 + [char]10 +
            "            }"
        $content = $content.Substring(0, $insertPos) + $countCode + $content.Substring($insertPos)
        Write-Host "Added count update"
    } else {
        Write-Host "Wrong location for end marker"
    }
}

# Fix 3: Also patch globalEpToggle to call invNeuRender
$oldEpLine = "if (window._invActiveTab === 'g') invGRender();"
$newEpLine = "if (window._invActiveTab === 'g') invGRender();" + [char]13 + [char]10 +
             "              if (window._invActiveTab === 'neu' && window.invNeuRender) invNeuRender();"
if ($content.Contains($oldEpLine) -and -not $content.Contains("window._invActiveTab === 'neu' && window.invNeuRender")) {
    $content = $content.Replace($oldEpLine, $newEpLine)
    Write-Host "Patched globalEpToggle"
}

[System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
Write-Host "Done"
