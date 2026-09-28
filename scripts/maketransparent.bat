@python -x "%~f0" %* & exit /b
# ---------------------------------------------------------------
# maketransparent.bat
# Macht weißen Hintergrund in PNG-Dateien transparent.
# Aufruf: maketransparent.bat [--tolerance N] [--dry-run]
#
# Optionen:
#   --tolerance N   Farbabstand zu Weiß (0-255), Standard: 15
#   --dry-run       Nur anzeigen, was gemacht würde (keine Änderung)
# ---------------------------------------------------------------
import os
import sys
import argparse
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow ist nicht installiert. Bitte installieren mit:")
    print("  pip install pillow")
    sys.exit(1)

# Pfad dieses Scripts → DRG39/scripts/ → eine Ebene hoch → DRG39/
SCRIPT_DIR = Path(__file__).resolve().parent
BASE_DIR    = SCRIPT_DIR.parent
IMG_DIRS    = [
    BASE_DIR / "data" / "img" / "loks",
    BASE_DIR / "data" / "img" / "pwagen",
    BASE_DIR / "data" / "img" / "gwagen",
]

def make_white_transparent(path: Path, tolerance: int) -> bool:
    """
    Ersetzt weiße und nahezu-weiße Pixel durch Transparenz.
    Gibt True zurück wenn das Bild verändert wurde.
    """
    img = Image.open(path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    changed = 0

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # Pixel ist "weiß" wenn alle Kanäle nah an 255 sind
            if r >= (255 - tolerance) and g >= (255 - tolerance) and b >= (255 - tolerance):
                pixels[x, y] = (r, g, b, 0)  # Alpha → 0
                changed += 1

    if changed:
        img.save(path, "PNG")
    return changed > 0

def main():
    parser = argparse.ArgumentParser(
        description="Weißen Hintergrund in PNG-Dateien transparent machen"
    )
    parser.add_argument(
        "--tolerance", type=int, default=15,
        help="Farbabstand zu Weiß (0–255, Standard: 15)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Nur anzeigen, keine Dateien ändern"
    )
    args = parser.parse_args()

    print(f"Toleranz: {args.tolerance}")
    if args.dry_run:
        print("DRY-RUN – keine Dateien werden geändert\n")

    total = 0
    modified = 0

    for folder in IMG_DIRS:
        if not folder.exists():
            print(f"  [WARNUNG] Verzeichnis nicht gefunden: {folder}")
            continue

        png_files = sorted(folder.glob("*.png"))
        print(f"\n{folder.name}/ ({len(png_files)} PNG-Dateien)")

        for png in png_files:
            total += 1
            if args.dry_run:
                print(f"  würde verarbeiten: {png.name}")
            else:
                try:
                    changed = make_white_transparent(png, args.tolerance)
                    status = "geändert" if changed else "unverändert"
                    print(f"  {png.name:50s}  {status}")
                    if changed:
                        modified += 1
                except Exception as e:
                    print(f"  [FEHLER] {png.name}: {e}")

    print(f"\nFertig. {modified}/{total} Dateien geändert.")

if __name__ == "__main__":
    main()
