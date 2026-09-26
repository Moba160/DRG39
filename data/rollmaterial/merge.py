import csv
import os

dir_path = r"g:\Meine Ablage\Eisenbahn\Franky\PlatformIO\DRG39\data\rollmaterial"

files = [
    ("loks.csv", "ID", "Ordnungsnummer"),
    ("p.csv", "Id", "Wagennr."),
    ("g.csv", "Id", "Wagennummer")
]

output_file = os.path.join(dir_path, "fahrzeuge.csv")

with open(output_file, "w", encoding="utf-8", newline="") as f_out:
    writer = csv.writer(f_out, delimiter='\t')
    writer.writerow(["ID", "Gattungsbezirk", "Ordnungsnummer"])
    
    for filename, id_col, ord_col in files:
        file_path = os.path.join(dir_path, filename)
        
        # Read the file to determine encoding or use a default
        with open(file_path, "r", encoding="utf-8", errors="replace") as f_in:
            lines = f_in.readlines()
            
        # Parse lines, removing comments
        clean_lines = [line for line in lines if line.strip() and not line.startswith(";")]
        
        reader = csv.DictReader(clean_lines, delimiter='\t')
        
        # Some headers might have trailing spaces or special characters, let's normalize headers in DictReader
        # Not strictly needed if they match exactly, but let's check
        if reader.fieldnames:
            reader.fieldnames = [str(x).strip() for x in reader.fieldnames]
            
        for row in reader:
            id_val = row.get(id_col, "")
            ord_val = row.get(ord_col, "")
            if id_val or ord_val:
                writer.writerow([id_val, "", ord_val])

print("Done")
