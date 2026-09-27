import sys

def extract_loks(ids):
    lines = open('loks.csv', 'r', encoding='iso-8859-1').read().split('\n')
    merged = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line:
            i += 1
            continue
        if line.startswith(';'):
            merged.append(line)
            i += 1
            continue
        cols = line.split('\t')
        while len(cols) < 26 and i + 1 < len(lines):
            i += 1
            next_line = lines[i]
            next_cols = next_line.split('\t')
            cols[-1] = cols[-1] + ' ' + next_cols[0]
            cols.extend(next_cols[1:])
        merged.append('\t'.join(cols))
        i += 1

    header = merged[0].split('\t')
    idx = {k.strip(): j for j, k in enumerate(header)}
    
    out = []
    for line in merged:
        cols = line.split('\t')
        if len(cols) <= idx['ID']: continue
        id_val = cols[idx['ID']].strip()
        if id_val in ids:
            gat_neu = cols[idx['Gattung neu']].strip()
            gat_alt = cols[idx['Gattung alt']].strip()
            gat = gat_neu
            if gat_alt:
                gat = f'{gat_neu} ({gat_alt})' if gat_neu else f'({gat_alt})'
            
            row = [
                id_val,
                cols[idx['Ep']].strip(),
                cols[idx['BV']].strip(),
                gat,
                cols[idx['Ordnungsnummer']].strip(),
                cols[idx['RBD oder Bezirk']].strip(),
                cols[idx['BW']].strip(),
                cols[idx['Hst']].strip(),
                cols[idx['Artikelnummer']].strip(),
                cols[idx['GAM']].strip() if 'GAM' in idx and len(cols) > idx['GAM'] else '-'
            ]
            out.append('\t'.join(row))
    return out

print("\n".join(extract_loks(['L60', 'L151', 'L152', *[f'L{k}' for k in range(81, 89)]])))
