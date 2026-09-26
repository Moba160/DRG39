import re
import sys

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# 1. Add "Neu" tab next to "G" tab in "Rollmaterial" section (also known as Inventar)
pin_g = """<span class="tab-pin" id="pin-sub-inv-g" title="Anpinnen, um diesen Tab beim Neustart standardmäßig zu öffnen" onclick="toggleSubTabPin('inv','g');"><svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M17 4a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1h1v5.586l-1.707 1.707A1 1 0 0 0 8 15h3v5a1 1 0 0 0 2 0v-5h3a1 1 0 0 0 .707-1.707L15 11.586V7h1a1 1 0 0 0 1-1V4z"/></svg></span>"""

neu_tab = """
                        <span class="col-tab" id="inv-tab-neu" onclick="switchInvTab('neu')">Neu</span>
                        <span class="tab-pin" id="pin-sub-inv-neu" title="Anpinnen, um diesen Tab beim Neustart standardmäßig zu öffnen" onclick="toggleSubTabPin('inv','neu');"><svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M17 4a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1h1v5.586l-1.707 1.707A1 1 0 0 0 8 15h3v5a1 1 0 0 0 2 0v-5h3a1 1 0 0 0 .707-1.707L15 11.586V7h1a1 1 0 0 0 1-1V4z"/></svg></span>"""

# Handle encoding issues with 'mäßig' and 'öffnen' - let's just find the closing tag of the G pin
g_pin_end = html.find("""<path d="M17 4a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1h1v5.586l-1.707 1.707A1 1 0 0 0 8 15h3v5a1 1 0 0 0 2 0v-5h3a1 1 0 0 0 .707-1.707L15 11.586V7h1a1 1 0 0 0 1-1V4z"/></svg></span>""")
if g_pin_end == -1:
    print("Could not find G pin end")
    sys.exit(1)

# Find the end of the line
g_pin_line_end = html.find("\n", g_pin_end)
if g_pin_line_end != -1:
    # insert neu tab
    html = html[:g_pin_line_end] + neu_tab + html[g_pin_line_end:]

# 2. Add inv-neu-view HTML
g_view_end_idx = html.find('id="inv-g-view"')
if g_view_end_idx != -1:
    end_of_g_view = html.find('</div>\n                  </div>\n              </div>', g_view_end_idx)
    if end_of_g_view != -1:
        # insert neu view
        neu_view = """
                    <div id="inv-neu-view" style="flex:1; overflow-y:auto; display:none;">
                        <table class="inv-table" id="inv-neu-table" style="table-layout:auto;">
                            <thead>
                                <tr id="inv-neu-header-row" style="background:#e8e8e8; position: sticky; top: 0; z-index: 10;">
                                    <th>ID</th>
                                    <th>Epoche</th>
                                    <th>BV</th>
                                    <th>Gattungsbezirk</th>
                                    <th>Ordnungsnummer</th>
                                </tr>
                            </thead>
                            <tbody></tbody>
                        </table>
                    </div>"""
        html = html[:end_of_g_view + 6] + neu_view + html[end_of_g_view + 6:]

# 3. Update switchInvTab function
tab_g_toggle = "document.getElementById('inv-tab-g').classList.toggle('active', tab === 'g');"
if tab_g_toggle in html:
    html = html.replace(tab_g_toggle, tab_g_toggle + "\n            const tabNeu = document.getElementById('inv-tab-neu'); if(tabNeu) tabNeu.classList.toggle('active', tab === 'neu');")

view_g_display = "document.getElementById('inv-g-view').style.display = tab === 'g' ? 'block' : 'none';"
if view_g_display in html:
    html = html.replace(view_g_display, view_g_display + "\n            const viewNeu = document.getElementById('inv-neu-view'); if(viewNeu) viewNeu.style.display = tab === 'neu' ? 'block' : 'none';")

# 4. Update switchInvTab logic to load CSV
g_load_call = """const pData = window._gLoaded ? Promise.resolve() : gLoadCSV();"""
if g_load_call in html:
    neu_logic = """
            } else if (tab === 'neu') {
                const isFirstOpen = !window._neuLoaded;
                const pData = window._neuLoaded ? Promise.resolve() : neuLoadCSV();
                Promise.all([pData, pHer]).then(() => {
                    if (isFirstOpen) {
                        invNeuRender();
                    }
                });"""
    html = html.replace("} else if (tab === 'g') {", neu_logic + "\n            } else if (tab === 'g') {")

# 5. Add load and render functions for neu
if "function gLoadCSV()" in html:
    neu_functions = """
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
                const lines = text.split('\\n');
                
                let headers = [];
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue;
                    if (i === 0 && !line.startsWith(';')) {
                        headers = line.split('\\t').map(h => h.trim());
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

        function invNeuRender() {
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
                    tr.onclick = () => toggleNeuGroup(groupId);
                    
                    tr.innerHTML = `<td colspan="5"><span class="toggle-icon" style="display:inline-block; width:20px;">▼</span> ${title}</td>`;
                    tbody.appendChild(tr);
                } else {
                    const cols = line.split('\\t');
                    if(cols.length < 5) return;
                    const tr = document.createElement('tr');
                    tr.className = 'neu-group-row-' + groupId;
                    
                    tr.innerHTML = `
                        <td>${cols[0] || ''}</td>
                        <td>${cols[1] || ''}</td>
                        <td>${cols[2] || ''}</td>
                        <td>${cols[3] || ''}</td>
                        <td>${cols[4] || ''}</td>
                    `;
                    tbody.appendChild(tr);
                }
            });
        }
"""
    html = html.replace("function gLoadCSV() {", neu_functions + "\n        function gLoadCSV() {")

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)
print("Updated index.html")
