# Schema: Verkehrstage-Codierung für zpa.csv

## Analyse der Anmerkungen in zpAnmerkungen.txt (Betriebsjahr: 1939)

### Kategorie 1: Wochentags-basiert

| Anmerkung               | Bedeutung                                      | Schema-Code     |
|-------------------------|------------------------------------------------|-----------------|
| `vS`                    | Vor Sonn- und Feiertag (= Sa + Feiertag-Vortage) | `DOW:vS`     |
| `nS`                    | Nach Sonn- und Feiertag (= Mo + Feiertag-Folgetage) | `DOW:nS`  |
| `S`                     | Sonn- und Feiertag                             | `DOW:S`         |
| `vS u S`                | Samstag + Sonn-/Feiertag                       | `DOW:vS+S`      |
| `S/nS`                  | Sonn-/Feiertag + Folgetag                      | `DOW:S+nS`      |
| `vS, S u nS`            | Samstag + Sonn-/Feiertag + Montag              | `DOW:vS+S+nS`   |
| `nur S`                 | Nur Sonn- und Feiertage                        | `DOW:S`         |
| `nur vS`                | Nur Vorsonntag                                 | `DOW:vS`        |
| `nur vS u S`            | Nur Vorsonntag + Sonntag                       | `DOW:vS+S`      |
| `W`                     | Werktags (Mo-Sa)                               | `DOW:W`         |
| `vS bis Di`             | Von Samstag bis Dienstag (Sa, So, Mo, Di)      | `DOW:vS-Di`     |
| `Fr bis nS`             | Freitag bis Montag (Fr, Sa, So, Mo)            | `DOW:Fr-nS`     |
| `Di/Mi bis Fr/Sa`       | Dienstag bis Samstag                           | `DOW:Di-Sa`     |
| `ab Berlin Mi, Fr und So` | Nur Mi, Fr, So ab Berlin                    | `DOW:Mi+Fr+So`  |
| `an Berlin Di, Do u Sa` | Nur Di, Do, Sa nach Berlin                     | `DOW:Di+Do+Sa`  |

### Kategorie 2: Datumsbereich

Format: `DD./DD.MM.` - **beide Tage inklusive** (Betriebsjahr 1939)

Monate als römische Zahlen: I=Jan, II=Feb, ..., XII=Dez

Monatsschlüssel:
- I=01, II=02, III=03, IV=04, V=05, VI=06
- VII=07, VIII=08, IX=09, X=10, XI=11, XII=12

Bei Monatsübergang (z.B. XII. bis III.) gilt: XII = 1938/1939, I-III = 1939.
Bereiche über den Jahreswechsel werden als "von > bis" erkannt und entsprechend behandelt.

| Anmerkungsbeispiel                                             | Schema-Code               |
|----------------------------------------------------------------|---------------------------|
| `1.VI. bis 31.VIII.`                                          | `DATE:0601-0831`          |
| `14./15.VI. bis 15./16.VIII.`                                 | `DATE:0614-0816`          |
| `1./2.X.-13./14.XII., 15./16.IV. bis 13./14.V.`              | `DATE:1001-1214\|0415-0514` |
| `19./20.-28./29.VIII.`                                        | `DATE:0819-0829`          |
| `vom 10./11.I. bis 15./16.IV.`                                | `DATE:0110-0416`          |

Bei mehreren Bereichen (durch `,` oder `und` / `u.` verbunden) werden diese per `|` getrennt.

### Kategorie 3: Immer / Sonderfälle

| Anmerkung    | Bedeutung                        | Schema-Code     |
|--------------|----------------------------------|-----------------|
| *(leer)*     | Fährt täglich                    | `*`             |
| `Bedarf`     | Nur bei Bedarf (optional)        | `BEDARF`        |
| `nS leer`    | nS, aber als Leerwagen           | `DOW:nS:LEER`   |

### Kategorie 4: Sonstige (kein Verkehrstag, Zusatzinfo)

Diese kodieren **keinen Verkehrstag**, sondern Ausstattung, Route oder Kapazität.
Sie erhalten Schema-Code `INFO:{bezeichnung}` und werden bei der Verkehrstag-Auswertung **ignoriert** (= täglich gültig).

| Anmerkung                      | Art              |
|--------------------------------|------------------|
| `ü Singen`, `ü Nürnberg` usw. | Route / Umweg    |
| `bis Mailand 2 Abt 1. Kl`     | Ausstattung      |
| `Ab Milano 3 Abt. 1. Kl`      | Ausstattung      |
| `77 Plätze`, `je 102 Plätze`  | Kapazität        |
| `wie E67`, `wie E68`          | Querverweis      |
| `1 Fr 2. u 3. Kl`             | 1 Frauenabteil, 2. u. 3. Klasse |
| `1 Fr 3. Kl`                  | 1 Frauenabteil, 3. Klasse       |
| `Stuttgart 2, Berlin`          | Laufweg-Info     |
| `2`, `66`, `2 66`             | Zuggattungsinfo  |

---

## Schema-Definition für Spalte `VkTage` (erste Spalte in zpa.csv)

**Aufbau:** `[Verkehrstage-Code]`

Trennzeichen: `|` für ODER-Bereiche (mehrere Datumsbereiche), `+` für UND-Verknüpfung

**Kodierungsregeln:**

```
*                      -> immer (täglich)
BEDARF                 -> nur bei Bedarf (vorhanden, aber optional)
DOW:vS                 -> Vorsonntag (Samstag + Feiertag-Vortage)
DOW:S                  -> Sonntag + Feiertage
DOW:nS                 -> Nachsonntag (Montag + Feiertag-Folgetage)
DOW:W                  -> Werktags (Mo-Sa)
DOW:vS+S               -> vS und S
DOW:S+nS               -> S und nS
DOW:vS+S+nS            -> vS, S und nS
DOW:Mo                 -> nur Montag
DOW:Di                 -> nur Dienstag
DOW:Mi                 -> nur Mittwoch
DOW:Do                 -> nur Donnerstag
DOW:Fr                 -> nur Freitag
DOW:Sa                 -> nur Samstag (= vS ohne Feiertag-Kontext)
DOW:So                 -> nur Sonntag
DOW:Mi+Fr+So           -> Mittwoch, Freitag, Sonntag (Liste mit +)
DOW:Fr-nS              -> Von Freitag bis Montag (Bereich mit -)
DOW:vS-Di              -> Von Samstag bis Dienstag
DOW:Di-Sa              -> Von Dienstag bis Samstag
DATE:MMDD-MMDD         -> Datumsbereich (inklusive), MMDD = nullgepaddet (Monat+Tag)
DATE:MMDD-MMDD|MMDD-MMDD -> mehrere Datumsbereiche (ODER)
DOW:xxx+DATE:...       -> Kombination: Wochentag UND Datum
BEDARF+DATE:...        -> Bedarf, aber nur innerhalb des Datumsbereichs
INFO:...               -> Zusatzinfo ohne Verkehrstagbedeutung (= täglich)
```

---

## Vollständige Übersetzungstabelle aller Anmerkungen

| Zeile | Original-Anmerkung                                              | Schema-Code                              |
|-------|-----------------------------------------------------------------|------------------------------------------|
| 1     | `1 Fr 2. u 3. Kl`                                              | `INFO:1Frauenabt-2u3Kl`                 |
| 2     | `1 Fr 3. Kl`                                                   | `INFO:1Frauenabt-3Kl`                   |
| 3     | `1 Wagenzug`                                                   | `INFO:1Wagenzug`                        |
| 4     | `1./2.X.-13./14.XII., 15./16.IV. bis 13./14.V.`               | `DATE:1001-1214\|0415-0514`             |
| 5     | `1.VI. bis 31.VIII.`                                           | `DATE:0601-0831`                        |
| 6     | `14./15.V. bis 14./14.VI. und 9./10.IX. bis 30.IX./1.X.`      | `DATE:0514-0614\|0909-1001`             |
| 7     | `14./15.VI. bis 15./16.VIII.`                                  | `DATE:0614-0816`                        |
| 8     | `14./15.VI. bis 8./9.IX. u. 14./15.XII. bis 29./30.III.`      | `DATE:0614-0909\|1214-0330`             |
| 9     | `14./15.VI. bis 9./10.IX., 14./15.XII. bis 30./31.III.`       | `DATE:0614-0910\|1214-0331`             |
| 10    | `15,/16.V. bis 1./2.X. und 15./16.XII. bis 15./16.IV.`        | `DATE:0515-1002\|1215-0416`             |
| 11    | `15./16.IV. bis 10./11.IX., 14./15.XII. bis 14./15.IV.`       | `DATE:0415-0911\|1214-0415`             |
| 12    | `15./16.V. bis 1.2/.X. und 14./15.XII. bis 14./15.IV.`        | `DATE:0515-1002\|1214-0415`             |
| 13    | `15./16.V. bis 10./11.IX., 15./16.XII. bis 31.III/1.IV.`      | `DATE:0515-0911\|1215-0401`             |
| 14    | `15./16.V. bis 15./16.VI. und 10./11.IX. bis 1.2.X.`          | `DATE:0515-0616\|0910-1002`             |
| 15    | `15.VI. bis 16.VIII.`                                          | `DATE:0615-0816`                        |
| 16    | `16./17. VI. bis 11./12.IX. u 15./16.XII. bis 15./16.IV`      | `DATE:0616-0912\|1215-0416`             |
| 17    | `16./17.VI. bis 10./11.IX., 16./17.XII. bis 31.III./1.IV.`    | `DATE:0616-0911\|1216-0401`             |
| 18    | `19./20.-28./29.VIII.`                                         | `DATE:0819-0829`                        |
| 19    | `2`                                                            | `INFO:Zugkat2`                          |
| 20    | `2 66`                                                         | `INFO:Zugkat2-66Pl`                     |
| 21    | `2./3.X.-14./15.XII., 16./17.IV.-14./15.V.`                   | `DATE:1002-1215\|0416-0515`             |
| 22    | `2.VI. bis 1.IX.`                                              | `DATE:0602-0901`                        |
| 23    | `2.VI. bis 31.VIII.`                                           | `DATE:0602-0831`                        |
| 24    | `20./21.-29./30.VIII.`                                         | `DATE:0820-0830`                        |
| 25    | `66`                                                           | `INFO:66Pl`                             |
| 26    | `77 Plätze`                                                    | `INFO:77Pl`                             |
| 27    | `ab Berlin Mi, Fr und So`                                      | `DOW:Mi+Fr+So`                          |
| 28    | `Ab Milano 3 Abt. 1. Kl`                                       | `INFO:3Abt1Kl`                          |
| 29    | `an Berlin Di, Do u Sa`                                        | `DOW:Di+Do+Sa`                          |
| 30    | `Bedarf`                                                       | `BEDARF`                                |
| 31    | `Bedarf, vom 10./11.I. bis 15./16.IV.`                        | `BEDARF+DATE:0110-0416`                 |
| 32    | `bis 1.X. regelm, ab 2.X. n Bed`                              | `DATE:*-1001\|BEDARF+DATE:1002-*`       |
| 33    | `bis 30.IX. U ab 2.V. ü Werdau`                               | `DATE:*-0930\|DATE:0502-*+INFO:üWerdau` |
| 34    | `bis Mailand 2 Abt 1. Kl`                                      | `INFO:2Abt1Kl`                          |
| 35    | `bis Milano 3 Abt. 1. Kl`                                      | `INFO:3Abt1Kl`                          |
| 36    | `Di/Mi bis Fr/Sa`                                              | `DOW:Di-Sa`                             |
| 37    | `Fr bis nS`                                                    | `DOW:Fr-nS`                             |
| 38    | `je 102 Plätze`                                                | `INFO:102Pl`                            |
| 39    | `nS`                                                           | `DOW:nS`                                |
| 40    | `nS leer`                                                      | `DOW:nS:LEER`                           |
| 41    | `nur S`                                                        | `DOW:S`                                 |
| 42    | `nur vS`                                                       | `DOW:vS`                                |
| 43    | `nur vS u S`                                                   | `DOW:vS+S`                              |
| 44    | `S`                                                            | `DOW:S`                                 |
| 45    | `S/nS`                                                         | `DOW:S+nS`                              |
| 46    | `Stuttgart 2, Berlin`                                           | `INFO:Stg2Ber`                          |
| 47    | `Stuttgart 2, Berlin 1 Wagenzug`                               | `INFO:1Wagenzug`                        |
| 48    | `ü Elsterwerda`                                                | `INFO:üElsterwerda`                     |
| 49    | `ü Halle S/nS`                                                 | `INFO:üHalle+DOW:S+nS`                  |
| 50    | `ü Nürnberg`                                                   | `INFO:üNürnberg`                        |
| 51    | `ü Nuürnberg` *(Tippfehler)*                                   | `INFO:üNürnberg`                        |
| 52    | `ü Osterburken`                                                | `INFO:üOsterburken`                     |
| 53    | `ü Singen`                                                     | `INFO:üSingen`                          |
| 54    | `ü Werdau bis 30. IX. U ab 2. V.`                              | `INFO:üWerdau+DATE:*-0930\|DATE:0502-*` |
| 55    | `vom 1.IX.-30.IX. und ab 15.IV.`                               | `DATE:0901-0930\|DATE:0415-*`           |
| 56    | `vom 10./11.I. bis 15./16.IV.`                                 | `DATE:0110-0416`                        |
| 57    | `vom 10./11.I. bis 31.III./1.IV.`                              | `DATE:0110-0401`                        |
| 58    | `vom 9./10.I. bis 14./15.IV.`                                  | `DATE:0109-0415`                        |
| 59    | `vom 9./10.I. bis 30./31.III.`                                 | `DATE:0109-0331`                        |
| 60    | `von FDt 572 77 Plätze`                                        | `INFO:vonFDt572`                        |
| 61    | `von FDt571 77 Plätze`                                         | `INFO:vonFDt571`                        |
| 62    | `vS`                                                           | `DOW:vS`                                |
| 63    | `vS bis Di`                                                    | `DOW:vS-Di`                             |
| 64    | `vS u S`                                                       | `DOW:vS+S`                              |
| 65    | `vS, S u nS`                                                   | `DOW:vS+S+nS`                           |
| 66    | `W`                                                            | `DOW:W`                                 |
| 67    | `wie E67`                                                      | `INFO:wieE67`                           |
| 68    | `wie E68`                                                      | `INFO:wieE68`                           |
| 69    | `Zugleich Express 8 Stg ab Crailsheim`                         | `INFO:ZugleichE8`                       |
| ---   | *(leer)*                                                       | `*`                                     |

---

## Auswertungslogik (JavaScript-Pseudocode)

```js
// Gegeben:
//   dateMMDD        : string  - aktuelles Datum als "MMDD" (z.B. "0614")
//   wochentag       : string  - "Mo"|"Di"|"Mi"|"Do"|"Fr"|"Sa"|"So"
//   isFeiertag      : boolean
//   morgenFeiertag  : boolean  (ist morgen ein Feiertag?)
//   gesternFeiertag : boolean  (war gestern ein Feiertag?)

function istAktiv(vkTageCode, dateMMDD, wochentag, isFeiertag, morgenFeiertag, gesternFeiertag) {
    const isVS  = (wochentag === 'Sa') || morgenFeiertag;
    const isS   = (wochentag === 'So') || isFeiertag;
    const isNS  = (wochentag === 'Mo') || gesternFeiertag;
    const isW   = !isS;  // Mo-Sa

    // ODER-Segmente (|) -> eines muss stimmen
    return vkTageCode.split('|').some(seg => auswertSegment(seg.trim(), dateMMDD, wochentag, isVS, isS, isNS, isW));
}

function auswertSegment(seg, dateMMDD, wochentag, isVS, isS, isNS, isW) {
    // UND-Teile (+) -> alle müssen stimmen
    return seg.split('+').every(part => auswertPart(part.trim(), dateMMDD, wochentag, isVS, isS, isNS, isW));
}

function auswertPart(part, dateMMDD, wochentag, isVS, isS, isNS, isW) {
    if (part === '*')            return true;
    if (part === 'BEDARF')       return true;    // Optional, aber vorhanden
    if (part.startsWith('INFO:')) return true;   // Keine Einschränkung

    if (part.startsWith('DOW:')) {
        const dow = part.slice(4);
        const map = { 'vS': isVS, 'S': isS, 'nS': isNS, 'W': isW,
                      'vS+S': isVS||isS, 'S+nS': isS||isNS, 'vS+S+nS': isVS||isS||isNS,
                      'Fr-nS': ['Fr','Sa','So','Mo'].includes(wochentag)||isVS||isS||isNS,
                      'vS-Di': isVS||isS||isNS||wochentag==='Di',
                      'Di-Sa': ['Di','Mi','Do','Fr','Sa'].includes(wochentag) };
        if (dow in map) return map[dow];
        // Listen wie "Mi+Fr+So"
        if (dow.includes('+')) return dow.split('+').some(t => t === wochentag || (t==='vS'&&isVS)||(t==='S'&&isS)||(t==='nS'&&isNS));
    }

    if (part.startsWith('DATE:')) {
        const range = part.slice(5);
        const [von, bis] = range.split('-');
        if (von === '*') return dateMMDD <= bis;
        if (bis === '*') return dateMMDD >= von;
        if (von > bis)   return dateMMDD >= von || dateMMDD <= bis;  // Jahresübergang
        return dateMMDD >= von && dateMMDD <= bis;
    }

    return true;  // Unbekanntes Format -> sicher true
}
```

> **Hinweis Jahresübergang:** Wenn `von > bis` (z.B. `DATE:1214-0330`), gilt der Bereich
> als Jahresübergang. Das Datum ist dann aktiv wenn es >= von (Dez) **oder** <= bis (März) ist.

> **Hinweis BEDARF:** Der Wagen ist grundsätzlich im Plan vorgesehen, fährt aber nur
> wenn Bedarf besteht. Bei der Anzeige kann er z.B. anders markiert werden (gestrichelt).