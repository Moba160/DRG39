import sys

def extract_g(ids):
    lines = open('g.csv', 'r', encoding='iso-8859-1').read().split('\n')
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
        while len(cols) < 17 and i + 1 < len(lines):
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
        if len(cols) <= idx['Id']: continue
        id_val = cols[idx['Id']].strip()
        if id_val in ids:
            gat = cols[idx['Gattungsbezi']].strip()
            
            row = [
                id_val,
                cols[idx['Ep']].strip(),
                cols[idx['BV']].strip(),
                gat,
                cols[idx['Wagennummer']].strip(),
                "", # Direktion
                "", # Bahnbetriebswerk
                cols[idx['Herst']].strip(),
                cols[idx['Art.-Nr.']].strip(),
                "-"
            ]
            out.append('\t'.join(row))
    return out

print("\n".join(extract_g(['G275'])))
