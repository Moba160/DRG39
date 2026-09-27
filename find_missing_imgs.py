import os

img_base = r'C:\Users\Frank\Meine Ablage\Eisenbahn\Franky\PlatformIO\DRG39\data\img'
csv_path = r'C:\Users\Frank\Meine Ablage\Eisenbahn\Franky\PlatformIO\DRG39\data\rollmaterial\fahrzeuge.csv'

# Build sets of IDs that have images (prefix before first '-')
loks_files = os.listdir(os.path.join(img_base, 'loks'))
loks_ids = set()
for f in loks_files:
    parts = f.split('-')
    if parts[0].startswith('L') and parts[0][1:].isdigit():
        loks_ids.add(parts[0])

print("Loks mit Bild:", sorted(loks_ids))
print()

with open(csv_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print('=== Loks OHNE Bild ===')
for i, line in enumerate(lines):
    if line.startswith(';') or line.strip() == '':
        continue
    cols = line.rstrip('\n').split('\t')
    lid = cols[0]
    if lid.startswith('L') and lid[1:].isdigit():
        if lid not in loks_ids:
            g = cols[3] if len(cols) > 3 else ''
            o = cols[4] if len(cols) > 4 else ''
            print(f'Zeile {i+1}: {lid}  Gattung={g}  Ordnungsnr={o}')
