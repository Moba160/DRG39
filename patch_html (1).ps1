$html = Get-Content -Path "index.html" -Encoding UTF8 -Raw

# 1. Add "Neu" tab next to "G" tab in "Rollmaterial" section (also known as Inventar)
$gTabMatch = '<span class="col-tab" id="inv-tab-g" onclick="switchInvTab(''g'')">G</span>'
$neuTab = '<span class="col-tab" id="inv-tab-neu" onclick="switchInvTab(''neu'')">Neu</span>
                          <span class="tab-pin" id="pin-sub-inv-neu" title="Anpinnen, um diesen Tab beim Neustart standardmYig zu ffnen" onclick="toggleSubTabPin(''inv'',''neu'');"><svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M17 4a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1h1v5.586l-1.707 1.707A1 1 0 0 0 8 15h3v5a1 1 0 0 0 2 0v-5h3a1 1 0 0 0 .707-1.707L15 11.586V7h1a1 1 0 0 0 1-1V4z"/></svg></span>'

# Find the end of the line containing pin-sub-inv-g
$gPinEndSearch = '</svg></span>'
$gPinIndex = $html.IndexOf('id="pin-sub-inv-g"')
if ($gPinIndex -ge 0) {
    $gPinEndIndex = $html.IndexOf($gPinEndSearch, $gPinIndex)
    if ($gPinEndIndex -ge 0) {
        $insertIndex = $gPinEndIndex + $gPinEndSearch.Length
        # We need to insert a newline and the neuTab
        $html = $html.Insert($insertIndex, "`r`n                          $neuTab")
    }
}

# 2. Add inv-neu-view HTML
$gViewIndex = $html.IndexOf('id="inv-g-view"')
if ($gViewIndex -ge 0) {
    $endOfGView = $html.IndexOf('</div>', $gViewIndex)
    # the structure is: 
    # <div id="inv-g-view">
    #   <table>...</table>
    # </div>
    # But wait, table also has a </div> inside it? No.
    # Let's just find the next '</div>' after the table end.
    $tableEnd = $html.IndexOf('</table>', $gViewIndex)
    $divEnd = $html.IndexOf('</div>', $tableEnd)
    
    if ($divEnd -ge 0) {
        $neuView = @"
                    <div id="inv-neu-view" style="flex:1; overflow-y:auto; display:none;">
                        <table class="inv-table" id="inv-neu-table" style="table-layout:auto;">
                            <thead>
                                <tr id="inv-neu-header-row" style="background:#e8e8e8; position: sticky; top: 0; z-index: 10;">
                                    <th style="padding:4px; text-align:left;">ID</th>
                                    <th style="padding:4px; text-align:left;">Epoche</th>
                                    <th style="padding:4px; text-align:left;">BV</th>
                                    <th style="padding:4px; text-align:left;">Gattungsbezirk</th>
                                    <th style="padding:4px; text-align:left;">Ordnungsnummer</th>
                                </tr>
                            </thead>
                            <tbody></tbody>
                        </table>
                    </div>
"@
        $html = $html.Insert($divEnd + 6, "`r`n$neuView")
    }
}

# 3. Update switchInvTab function
$tabGToggle = "document.getElementById('inv-tab-g').classList.toggle('active', tab === 'g');"
if ($html.Contains($tabGToggle)) {
    $html = $html.Replace($tabGToggle, "$tabGToggle`r`n              const tabNeu = document.getElementById('inv-tab-neu'); if(tabNeu) tabNeu.classList.toggle('active', tab === 'neu');")
}

$viewGDisplay = "document.getElementById('inv-g-view').style.display = tab === 'g' ? 'block' : 'none';"
if ($html.Contains($viewGDisplay)) {
    $html = $html.Replace($viewGDisplay, "$viewGDisplay`r`n              const viewNeu = document.getElementById('inv-neu-view'); if(viewNeu) viewNeu.style.display = tab === 'neu' ? 'block' : 'none';")
}

# 4. Update switchInvTab logic to load CSV
$gLogicSearch = "} else if (tab === 'g') {"
$neuLogic = @"
            } else if (tab === 'neu') {
                const isFirstOpen = !window._neuLoaded;
                const pData = window._neuLoaded ? Promise.resolve() : neuLoadCSV();
                Promise.all([pData, pHer]).then(() => {
                    if (isFirstOpen) {
                        invNeuRender();
                    }
                });
"@
if ($html.Contains($gLogicSearch)) {
    $html = $html.Replace($gLogicSearch, "$neuLogic`r`n            $gLogicSearch")
}

# 5. Add load and render functions for neu
$gLoadSearch = "function gLoadCSV() {"
$neuFunctions = @"
        // NEU (fahrzeuge.csv) Inventar
        let _neuData = [];
        let _neuLoadPromise = null;
        function neuLoadCSV() {
            if (!_neuLoadPromise) _neuLoadPromise = _neuLoadCSV_internal();
            return _neuLoadPromise;
        }

        async function _neuLoadCSV_internal() {
            window._neuLoaded = true;
            try {
                const resp = await fetch('data/rollmaterial/fahrzeuge.csv');
                const buf = await resp.arrayBuffer();
                const text = new TextDecoder('utf-8').decode(buf);
                const lines = text.split('\n');
                
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue;
                    if (i === 0 && !line.startsWith(';')) {
                        // skip header row
                        continue;
                    }
                    _neuData.push(line);
                }
                invNeuRender();
            } catch(e) {
                console.error('Fehler beim Laden von fahrzeuge.csv', e);
            }
        }
        
        window.toggleNeuGroup = function(groupId) {
            const trs = document.querySelectorAll('.neu-group-row-' + groupId);
            const headerRow = document.getElementById('neu-group-header-' + groupId);
            const isCollapsed = headerRow.getAttribute('data-collapsed') === 'true';
            
            trs.forEach(tr => {
                tr.style.display = isCollapsed ? '' : 'none';
            });
            
            headerRow.setAttribute('data-collapsed', isCollapsed ? 'false' : 'true');
            const icon = headerRow.querySelector('.toggle-icon');
            if(icon) icon.textContent = isCollapsed ? '▼' : '▶';
        };

        window.invNeuRender = function() {
            const tbody = document.querySelector('#inv-neu-table tbody');
            if(!tbody) return;
            tbody.innerHTML = '';
            
            let groupId = 0;
            
            _neuData.forEach(line => {
                if (line.startsWith(';')) {
                    groupId++;
                    const title = line.substring(1);
                    const tr = document.createElement('tr');
                    tr.id = 'neu-group-header-' + groupId;
                    tr.setAttribute('data-collapsed', 'false');
                    tr.style.cursor = 'pointer';
                    tr.style.backgroundColor = '#ddd';
                    tr.style.fontWeight = 'bold';
                    tr.onclick = () => toggleNeuGroup(tr.id.replace('neu-group-header-', ''));
                    
                    tr.innerHTML = `<td colspan="5" style="padding:4px;"><span class="toggle-icon" style="display:inline-block; width:20px;">▼</span> \${title}</td>`;
                    tbody.appendChild(tr);
                } else {
                    const cols = line.split('\t');
                    if(cols.length < 5) return;
                    const tr = document.createElement('tr');
                    tr.className = 'neu-group-row-' + groupId;
                    
                    tr.innerHTML = `
                        <td style="padding:4px;">\${cols[0] || ''}</td>
                        <td style="padding:4px;">\${cols[1] || ''}</td>
                        <td style="padding:4px;">\${cols[2] || ''}</td>
                        <td style="padding:4px;">\${cols[3] || ''}</td>
                        <td style="padding:4px;">\${cols[4] || ''}</td>
                    `;
                    tbody.appendChild(tr);
                }
            });
        }
"@
if ($html.Contains($gLoadSearch)) {
    $html = $html.Replace($gLoadSearch, "$neuFunctions`r`n        $gLoadSearch")
}

Set-Content -Path "index.html" -Value $html -Encoding UTF8
Write-Host "Done"
