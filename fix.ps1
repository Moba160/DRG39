$file = "index.html"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

$startMarker = "// NEU (fahrzeuge.csv) Inventar"
$endMarker = "function gLoadCSV() {"

$startIndex = $content.IndexOf($startMarker)
$endIndex = $content.IndexOf($endMarker, $startIndex)

if ($startIndex -ge 0 -and $endIndex -ge 0) {
    # Extract before and after
    $before = $content.Substring(0, $startIndex)
    $after = $content.Substring($endIndex)
    
    $correctFunctions = @"
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
            if(icon) icon.textContent = isCollapsed ? '\u25BC' : '\u25B6';
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
                    
                    tr.innerHTML = '<td colspan="5" style="padding:4px;"><span class="toggle-icon" style="display:inline-block; width:20px;">\u25BC</span> ' + title + '</td>';
                    tbody.appendChild(tr);
                } else {
                    const cols = line.split('\t');
                    if(cols.length < 5) return;
                    const tr = document.createElement('tr');
                    tr.className = 'neu-group-row-' + groupId;
                    
                    tr.innerHTML = '<td style="padding:4px;">' + (cols[0] || '') + '</td>' +
                                   '<td style="padding:4px;">' + (cols[1] || '') + '</td>' +
                                   '<td style="padding:4px;">' + (cols[2] || '') + '</td>' +
                                   '<td style="padding:4px;">' + (cols[3] || '') + '</td>' +
                                   '<td style="padding:4px;">' + (cols[4] || '') + '</td>';
                    tbody.appendChild(tr);
                }
            });
        }
        
"@

    $newContent = $before + $correctFunctions + $after
    [System.IO.File]::WriteAllText($file, $newContent, [System.Text.Encoding]::UTF8)
    Write-Host "Fixed index.html"
} else {
    Write-Host "Could not find markers"
}
