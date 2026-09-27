$file = "index.html"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

# 1. Update the table header for Neu to include the filter fields
$oldHeader = @"
                            <thead>
                                <tr id="inv-neu-header-row" style="background:#e8e8e8; position: sticky; top: 0; z-index: 10;">
                                    <th style="padding:4px; text-align:left;">ID</th>
                                    <th style="padding:4px; text-align:left;">Epoche</th>
                                    <th style="padding:4px; text-align:left;">BV</th>
                                    <th style="padding:4px; text-align:left;">Gattungsbezirk</th>
                                    <th style="padding:4px; text-align:left;">Ordnungsnummer</th>
                                </tr>
                            </thead>
"@

$newHeader = @"
                            <thead>
                                <tr id="inv-neu-filter-row" style="background:#e8e8e8; position: sticky; top: 0; z-index: 11;">
                                    <th style="padding:4px;"><input type="text" id="inv-neu-filter-id" style="width:100%; box-sizing:border-box;" oninput="invNeuRender()" placeholder="ID..."></th>
                                    <th style="padding:4px;"><input type="text" id="inv-neu-filter-epoche" style="width:100%; box-sizing:border-box;" oninput="invNeuRender()" placeholder="Ep..."></th>
                                    <th style="padding:4px;"><input type="text" id="inv-neu-filter-bv" style="width:100%; box-sizing:border-box;" oninput="invNeuRender()" placeholder="BV..."></th>
                                    <th style="padding:4px;"><input type="text" id="inv-neu-filter-gattung" style="width:100%; box-sizing:border-box;" oninput="invNeuRender()" placeholder="Gattung..."></th>
                                    <th style="padding:4px;">
                                        <div style="display:flex;">
                                            <input type="text" id="inv-neu-filter-ord" style="width:100%; box-sizing:border-box;" oninput="invNeuRender()" placeholder="Ord.Nr....">
                                            <button onclick="invNeuReset()" style="margin-left:4px; cursor:pointer;" title="Filter zurücksetzen">✖</button>
                                        </div>
                                    </th>
                                </tr>
                                <tr id="inv-neu-header-row" style="background:#e8e8e8; position: sticky; top: 28px; z-index: 10;">
                                    <th style="padding:4px; text-align:left;">ID</th>
                                    <th style="padding:4px; text-align:left;">Epoche</th>
                                    <th style="padding:4px; text-align:left;">BV</th>
                                    <th style="padding:4px; text-align:left;">Gattungsbezirk</th>
                                    <th style="padding:4px; text-align:left;">Ordnungsnummer</th>
                                </tr>
                            </thead>
"@

if ($content.Contains($oldHeader)) {
    $content = $content.Replace($oldHeader, $newHeader)
}

# 2. Update globalEpToggle to call invNeuRender
$oldEpToggle = "if (window.gRender) gRender();"
if ($content.Contains($oldEpToggle)) {
    $newEpToggle = $oldEpToggle + "`r`n              if (window._invActiveTab === 'neu' && window.invNeuRender) invNeuRender();"
    if (-not $content.Contains("window._invActiveTab === 'neu' && window.invNeuRender")) {
        $content = $content.Replace($oldEpToggle, $newEpToggle)
    }
}

# 3. Replace invNeuRender with the new version including filtering and reset
$startMarker = "window.invNeuRender = function() {"
$endMarker = "}"
$startIndex = $content.IndexOf($startMarker)
if ($startIndex -ge 0) {
    # Find the end of window.invNeuRender function. It ends just before `@"` or `</script>` or `// NEU` etc.
    # Actually, let's just find the first `        }` after `});`
    # A safe way is to find the next function or the end of the block.
    # We can just replace from startMarker to the end of _neuData.forEach(...}); }
    
    $endIndex = $content.IndexOf("        }", $content.IndexOf("});", $startIndex))
    if ($endIndex -ge 0) {
        $before = $content.Substring(0, $startIndex)
        $after = $content.Substring($endIndex + 9) # skip `        }\r\n`
        
        $newRenderFunction = @"
        window.invNeuReset = function() {
            ['inv-neu-filter-id', 'inv-neu-filter-epoche', 'inv-neu-filter-bv', 'inv-neu-filter-gattung', 'inv-neu-filter-ord'].forEach(id => {
                const el = document.getElementById(id);
                if (el) el.value = '';
            });
            invNeuRender();
        };

        window.invNeuRender = function() {
            const tbody = document.querySelector('#inv-neu-table tbody');
            if(!tbody) return;
            tbody.innerHTML = '';
            
            // Read global epoche filter
            const epBtn = document.querySelector('.global-ep-btn.active');
            const globalEp = epBtn ? epBtn.textContent.trim() : '';

            // Read text filters
            const filterId = (document.getElementById('inv-neu-filter-id')?.value || '').toLowerCase();
            const filterEp = (document.getElementById('inv-neu-filter-epoche')?.value || '').toLowerCase();
            const filterBv = (document.getElementById('inv-neu-filter-bv')?.value || '').toLowerCase();
            const filterGat = (document.getElementById('inv-neu-filter-gattung')?.value || '').toLowerCase();
            const filterOrd = (document.getElementById('inv-neu-filter-ord')?.value || '').toLowerCase();
            
            // First pass: group the data
            const groups = [];
            let currentGroup = null;
            let groupId = 0;

            _neuData.forEach(line => {
                if (line.startsWith(';')) {
                    groupId++;
                    currentGroup = { id: groupId, title: line.substring(1), items: [] };
                    groups.push(currentGroup);
                } else {
                    const cols = line.split('\t');
                    if (cols.length < 5) return;
                    
                    // Filter logic
                    const idVal = (cols[0] || '').toLowerCase();
                    const epVal = (cols[1] || '').toLowerCase();
                    const bvVal = (cols[2] || '').toLowerCase();
                    const gatVal = (cols[3] || '').toLowerCase();
                    const ordVal = (cols[4] || '').toLowerCase();

                    // Epochen filter (global)
                    if (globalEp && cols[1] !== globalEp && !globalEp.includes('Alle')) {
                        return; // does not match global epoche
                    }

                    // Text filters
                    if (filterId && !idVal.includes(filterId)) return;
                    if (filterEp && !epVal.includes(filterEp)) return;
                    if (filterBv && !bvVal.includes(filterBv)) return;
                    if (filterGat && !gatVal.includes(filterGat)) return;
                    if (filterOrd && !ordVal.includes(filterOrd)) return;

                    if (!currentGroup) {
                        groupId++;
                        currentGroup = { id: groupId, title: "Ungruppiert", items: [] };
                        groups.push(currentGroup);
                    }
                    currentGroup.items.push(cols);
                }
            });

            // Second pass: render
            groups.forEach(group => {
                if (group.items.length === 0) return; // Hide empty groups

                // Group header
                const trHeader = document.createElement('tr');
                trHeader.id = 'neu-group-header-' + group.id;
                trHeader.setAttribute('data-collapsed', 'false');
                trHeader.style.cursor = 'pointer';
                trHeader.style.backgroundColor = '#ddd';
                trHeader.style.fontWeight = 'bold';
                trHeader.onclick = () => toggleNeuGroup(group.id);
                
                trHeader.innerHTML = '<td colspan="5" style="padding:4px;"><span class="toggle-icon" style="display:inline-block; width:20px;">\u25BC</span> ' + group.title + '</td>';
                tbody.appendChild(trHeader);

                // Group items
                group.items.forEach(cols => {
                    const tr = document.createElement('tr');
                    tr.className = 'neu-group-row-' + group.id;
                    tr.innerHTML = '<td style="padding:4px;">' + (cols[0] || '') + '</td>' +
                                   '<td style="padding:4px;">' + (cols[1] || '') + '</td>' +
                                   '<td style="padding:4px;">' + (cols[2] || '') + '</td>' +
                                   '<td style="padding:4px;">' + (cols[3] || '') + '</td>' +
                                   '<td style="padding:4px;">' + (cols[4] || '') + '</td>';
                    tbody.appendChild(tr);
                });
            });
        }
"@

        $content = $before + $newRenderFunction + "`r`n" + $after
    } else {
        Write-Host "Could not find end of invNeuRender"
    }
} else {
    Write-Host "Could not find start of invNeuRender"
}

[System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
Write-Host "Done"
