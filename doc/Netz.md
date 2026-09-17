# Netzplan mit Zugstandorten – Implementierungsplan

## Ziel

Erweiterung des bestehenden "Netz"-Tabs in `index.html` um eine interaktive, animierte
Darstellung der aktuellen Zugstandorte auf dem geografischen Netzplan.
Die Vorlage dafuer ist `ViewZugstandorteGrafisch.java` aus dem alten Java-Projekt
`workspaceEXCH/Anlagensteuerung`.

---

## Wie das Java-Programm es gemacht hat

### Datenmodell

| Java-Klasse | Entsprechung in DRG39 |
|---|---|
| `Bahnhof` | Eintrag in `geo.csv` (Bahnhof, lat, lon) |
| `Bahnhoefe` | `window._geoMap` (Name -> {lat, lon}) |
| `KBS` | `window._kbsMap` (KBS-ID -> [{bahnhof, km}, ...]) |
| `Strecken` | Aufgebaut aus `kbs.csv` |
| `Zug` | `window._fahrplanMap` (ZugNr -> [{bahnhof, abfahrt, ankunft}, ...]) |
| `Zuege` | Gesamtmenge aller Zuege |

### Geokoordinate -> Bildschirmkoordinate (Java)

```java
private int geoToX(float lon, boolean absolute) {
    return (int)((lon - Bahnhof.getMinLon()) * scale) + origin.x;
}
private int geoToY(float lat, boolean absolute) {
    return (int)((maxLat - minLat) * scale - (lat - minLat) * scale) + origin.y;
}
```

Im Web uebernimmt **Leaflet** die Projektion; wir uebergeben `[lat, lon]` direkt.

### Zugstandort berechnen (`getZugKoordinaten`)

Der Zug befindet sich entweder:
- **im Bahnhof** (`ortsart == im_bahnhof`) -> Koordinate des Bahnhofs
- **zwischen zwei Bahnhoefen** (`ortsart == zwischen`) -> lineare Interpolation
  entlang der Strecke (Anteil = `kmNach / kmEntfernung`)

```java
float anteil = so.kmNach / so.kmEntfernung();
x = x1 + (x2 - x1) * anteil;
y = y1 + (y2 - y1) * anteil;
```

Im Web:
```js
const anteil = (simTime - abfahrtMin) / (ankunftMin - abfahrtMin);
const lat = geo1.lat + (geo2.lat - geo1.lat) * anteil;
const lon = geo1.lon + (geo2.lon - geo1.lon) * anteil;
```

### Zeitberechnung der Position

- Simulationszeit laeuft im Java-Programm als `Observer`-Pattern (Uhr)
- Die Zugposition wird bei jeder Tick-Aktualisierung aus den Abfahrts-/Ankunftszeiten
  und der aktuellen Simulationszeit berechnet
- Im Web: identisch - `tickSimulation()` laeuft bereits in `requestAnimationFrame`,
  wir muessen dort die Zugpositionen neu berechnen und Leaflet-Marker verschieben

### Zeichnen (Java -> Leaflet)

| Java (GC) | Web (Leaflet) |
|---|---|
| `gc.drawLine(x1,y1,x2,y2)` | `L.polyline([[lat1,lon1],[lat2,lon2]])` |
| Strecke farbig | `.setStyle({color})` |
| Kreis am Bahnhof | `L.circleMarker([lat,lon])` |
| Zug-Symbol | `L.circleMarker` oder `L.divIcon` |
| Tooltip | `.bindTooltip(html)` |

### Interaktion (Java -> Web)

| Java | Web |
|---|---|
| Mausrad: Zoom | Leaflet eingebaut |
| Drag: Panning | Leaflet eingebaut |
| Hover -> Tooltip mit Zuginfo | `.bindTooltip()` |
| Klick auf Zug -> Auswahl | `.on('click', ...)` |
| Suchfeld fuer Bahnhof/KBS/Zug | `<input>` + Filter-Funktion |

---

## Was bereits in `index.html` vorhanden ist

Der "Netz"-Tab existiert bereits. Die Funktion `initNetzMap()` (ab ca. Zeile 2001):
- erstellt eine Leaflet-Karte (`window._netz_map`)
- zeichnet ueber `renderNetzMap()` alle KBS-Segmente (nur von Zuegen benutzte Kanten)
- zeigt Bahnhof-Marker mit Tooltips
- filtert ueber `buildTrainPathEdges()` welche Kanten genutzt werden
- benutzt aktuell **nur FD/FDt**-Zuege (das wird erweitert)

---

## Implementierungsplan

### Schritt 1 - Zugstandort-Berechnung

Neue Funktion `getZugPosition(zugNr, simTimeMinutes)` -> `{lat, lon, bf1, bf2, anteil}`.
Wird aus `tickSimulation()` heraus aufgerufen.

Algorithmus (identisch mit Java `getZugKoordinaten`):
1. Iteriere ueber alle Fahrtplanzeilen des Zuges (chronologisch)
2. Finde das Intervall [abfahrt-i, ankunft-(i+1)] in dem simTime liegt
3. Berechne linearen Anteil: `anteil = (simTime - abfahrt) / (ankunft - abfahrt)`
4. Interpoliere lat/lon zwischen den beiden Bahnhoefen
5. Sonderfall: Aufenthalt im Bahnhof (ankunft < simTime < abfahrt) -> lat/lon des Bahnhofs

### Schritt 2 - Zugmarker verwalten

Neue globale Map `window._zugMarkers = {}` (ZugNr -> Leaflet CircleMarker).

Bei jedem Tick:
- Zug aktiv (pos != null): Marker vorhanden -> `setLatLng()`; neu -> `L.circleMarker().addTo()`
- Zug inaktiv (pos == null): Marker entfernen und aus Map loeschen

### Schritt 3 - Farbgebung nach Gattung

Analog zu Java `colorZugstandortVonAhb / colorZugstandortNachAhb`:

```js
function gattungColor(gattung) {
    const map = {
        'FD': '#1a237e', 'FDt': '#1a237e',
        'D':  '#1565c0',
        'E':  '#2e7d32',
        'P':  '#558b2f',
        'Ng': '#827717',
    };
    return map[gattung] || '#555';
}
```

### Schritt 4 - Integration in `tickSimulation()`

In der bestehenden `tickSimulation()`-Funktion, direkt nach der Zeitberechnung:

```js
// Nur wenn Netz-Tab sichtbar (Performance)
if (window._netz_map && document.getElementById('panel-netz').classList.contains('active')) {
    updateZugMarkers(currentSimMinutes);
}
```

### Schritt 5 - Tooltip-Inhalt (analog zu `createToolTip()` in Java)

```js
function buildZugTooltip(zugNr, pos) {
    const gattung = window._zuegeMap ? window._zuegeMap[zugNr] : '';
    let tt = '<b>' + gattung + ' ' + zugNr + '</b>';
    if (pos.bf2) {
        tt += '<br>zwischen ' + pos.bf1 + ' -> ' + pos.bf2;
        tt += '<br>(' + Math.round(pos.anteil * 100) + '%)';
    } else {
        tt += '<br>in ' + pos.bf1;
    }
    return tt;
}
```

### Schritt 6 - Filter-Controls (analog zur Java-Toolbar)

Toolbar-Leiste oberhalb der Karte im Netz-Panel:

```html
<div id="netz-toolbar">
  <label><input type="checkbox" id="netz-show-zuege" checked> Zugstandorte</label>
  <label><input type="checkbox" id="netz-show-alle-kbs"> Alle KBS-Segmente</label>
  <select id="netz-gattung-filter">...</select>
  <input type="text" id="netz-filter-zug" placeholder="Zug-Nr filtern">
  <button id="netz-zoom-fit">Fit</button>
</div>
```

| Control | Java-Aequivalent |
|---|---|
| Zugstandorte-Checkbox | `actZugstandorte` |
| Alle KBS-Checkbox | `actAlleBf` |
| Gattungs-Dropdown | `actKeineBf / actNurHaltBf / actAlleBf` |
| Zug-Filter-Textfeld | `txtZugfilter` |
| Fit-Button | `actZoomAnpassen` (scaleToFit) |

### Schritt 7 - Klick auf Zug (Selektion)

```js
marker.on('click', () => {
    showZugDetails(zugNr); // bereits vorhanden in index.html
});
```

### Schritt 8 - Alle Gattungen zulassen

Aktuell filtert `buildTrainPathEdges()` nur FD/FDt.
Erweiterung: Parameter "gattungsFilter" (Array oder Set), gesteuert ueber Checkbox/Dropdown.

---

## Datenfluss

```
CSV-Dateien (kbs.csv, geo.csv, abfahrten.csv, zuege.csv)
         |
         v
   window._kbsMap, _geoMap, _fahrplanMap, _zuegeMap
         |
         v
  tickSimulation(now)
         |
         +-> updateZugMarkers(simTimeMinutes)
         |         |
         |         +-> getZugPosition(zugNr, t)
         |                   |
         |                   +-> lineare Interpolation zwischen
         |                       zwei Fahrplan-Eintraegen
         |
         +-> Leaflet circleMarker.setLatLng([lat,lon])
```

---

## Bekannte Besonderheiten / Fallstricke

1. **Mitternachts-Uebergang**: Zeiten nach 00:00 Uhr muessen modulo 1440 Minuten
   behandelt werden (wie im Java-Code `(1440 + a - b) % 1440`).

2. **Fehlende Geodaten**: Nicht alle Bahnhoefe haben geo.csv-Eintraege.
   -> `if (!geo1 || !geo2) return null` und Marker weglassen.

3. **Kein direkter KBS-Abschnitt**: Wenn zwei aufeinanderfolgende Fahrtplanhalte
   keine gemeinsame KBS haben, direkte Luftlinie zeichnen (Fallback).

4. **Performance**: Bei ~500 aktiven Zuegen koennen `setLatLng`-Aufrufe auf jedem
   Frame teuer werden. Loesung: Update nur wenn Netz-Tab sichtbar ist.

5. **Aufenthalt im Bahnhof**: Wenn ankunft und abfahrt vorhanden und simTime liegt
   dazwischen -> Zug steht still im Bahnhof (nicht unterwegs).

6. **netz-map vs netz-canvas**: Im HTML gibt es `<canvas id="netz-canvas">` aber der
   JS-Code sucht nach `<div id="netz-map">`. Das `<canvas>`-Element muss durch ein
   `<div id="netz-map">` ersetzt werden (Leaflet braucht ein DIV).

---

## Zu aendernde Dateien

| Datei | Aenderung |
|---|---|
| `index.html` | Netz-Panel: netz-canvas -> netz-map DIV; Toolbar hinzufuegen; `initNetzMap()` erweitern um Zugmarker-Funktionen; `tickSimulation()` um `updateZugMarkers()` ergaenzen |

Keine weiteren Dateien erforderlich - alle Daten sind bereits geladen.

---

## Referenzen (Java-Quellen)

- `ViewZugstandorteGrafisch.java` -> Hauptlogik: Zugposition, Zeichnen, Toolbar, Tooltip
- `GenScrollableCanvas.java` -> Zoom/Pan (durch Leaflet ersetzt)
- `KBS.java` -> Streckendaten-Modell
- `Strecken.java` -> Laden aus CSV (KBS.txt entspricht kbs.csv)
- `Bahnhof.java` -> Geodaten pro Bahnhof (lon, lat)
