#!/usr/bin/env python3
"""
extract_eisenbahnstiftung.py

Extracts an image index from the Eisenbahnstiftung gallery:
  https://eisenbahnstiftung.de/bildergalerie/Deutsche%20Reichsbahn%20Gesellschaft

For each image the following is written to the index:
  - thumbnail_url  : URL of the gallery thumbnail
  - detail_url     : URL of the full-size (detail) image
  - caption        : Full descriptive caption (from the alt attribute)
  - title          : Short title shown below the thumbnail (from the <p> text)

Output: data/img/vorbild/eisenbahnstiftung_index.json  (and a TSV summary)

Already-extracted images (identified by detail_url) are skipped on re-runs.
Progress is shown as "." per new image, with a newline after every 50.
"""

import json
import re
import sys
import time
import urllib.request
from html.parser import HTMLParser
import pathlib

BASE_URL    = "https://eisenbahnstiftung.de"
GALLERY_URL = "/bildergalerie/Deutsche%20Reichsbahn%20Gesellschaft"
OUTPUT_JSON = "eisenbahnstiftung_index.json"
OUTPUT_TSV  = "eisenbahnstiftung_index.tsv"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; EisenbahnExtractor/1.0)",
    "Accept-Language": "de-DE,de;q=0.9",
}


def fetch(url: str) -> str:
    """Fetch a URL and return its HTML as a string."""
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=20) as resp:
        return resp.read().decode("utf-8", errors="replace")


class GalleryParser(HTMLParser):
    """Parse imgBox blocks from a gallery page."""

    def __init__(self):
        super().__init__()
        self.images = []
        self._in_imgbox = False
        self._in_p = False
        self._after_br = False
        self._current = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "div" and attrs.get("class") == "imgBox":
            self._in_imgbox = True
            self._current = {}
            self._in_p = False
            self._after_br = False

        if self._in_imgbox:
            if tag == "p":
                self._in_p = True
                self._after_br = False
            elif tag == "img" and "openMe" in attrs.get("class", ""):
                detail_path = attrs.get("id", "")
                thumb_path  = attrs.get("src", "")
                caption     = attrs.get("alt", "")
                caption = (caption
                           .replace("&lt;", "<")
                           .replace("&gt;", ">")
                           .replace("&amp;", "&")
                           .replace("&quot;", '"')
                           .replace("&#039;", "'")
                           .replace("&nbsp;", " "))
                self._current["detail_url"]    = BASE_URL + detail_path
                self._current["thumbnail_url"] = BASE_URL + "/" + thumb_path.lstrip("/")
                self._current["caption"]       = caption.strip()
            elif tag == "br" and self._in_p:
                self._after_br = True

    def handle_endtag(self, tag):
        if tag == "div" and self._in_imgbox:
            if self._current and "detail_url" in self._current:
                self.images.append(self._current)
            self._in_imgbox = False
            self._current = None
        if tag == "p":
            self._in_p = False
            self._after_br = False

    def handle_data(self, data):
        if self._in_p and self._after_br and self._current is not None:
            text = data.strip()
            if text:
                self._current.setdefault("title", text)
                self._after_br = False


def get_page_urls(first_page_html):
    """Extract all gallery page URLs from the pager on the first page."""
    pages = re.findall(
        r'href="(/bildergalerie/Deutsche%20Reichsbahn%20Gesellschaft\?[^"]*page=(\d+))"',
        first_page_html
    )
    unique = {}
    for path, num in pages:
        unique[int(num)] = BASE_URL + path
    all_urls = [BASE_URL + GALLERY_URL]
    for n in sorted(unique.keys()):
        all_urls.append(unique[n])
    return all_urls


import csv

def match_trains(all_images, script_dir):
    zuege_csv = script_dir.parent / "data" / "fahrplan" / "zuege.csv"
    train_photos_json = script_dir.parent / "data" / "img" / "vorbild" / "train_photos.json"

    if not zuege_csv.exists():
        print(f"Warning: {zuege_csv} not found, skipping train matching.")
        return

    with open(zuege_csv, "r", encoding="utf-8") as f:
        reader = csv.reader(f, delimiter='\t')
        header = next(reader)
        fotos_idx = header.index("Fotos") if "Fotos" in header else len(header)
        if "Fotos" not in header:
            header.append("Fotos")
        
        rows = []
        train_photos = {}
        for row in reader:
            if len(row) < 2:
                continue
            gattung = row[0].strip()
            zugnr = row[1].strip()
            
            # pattern to match: Gattung + optional space + ZugNr, e.g. "D 120" or "D120"
            pattern = rf"(?<![A-Za-z0-9]){gattung}\s*{zugnr}(?![0-9])"
            regex = re.compile(pattern, re.IGNORECASE)
            
            fotos_for_train = []
            detail_urls = []
            
            for img in all_images:
                caption = img.get("caption", "")
                if regex.search(caption):
                    fotos_for_train.append(img)
                    detail_urls.append(img["detail_url"])
            
            if fotos_for_train:
                train_photos[zugnr] = fotos_for_train
            
            # ensure row has enough columns
            while len(row) <= fotos_idx:
                row.append("")
            row[fotos_idx] = "|".join(detail_urls)
            rows.append(row)
            
    # Write back zuege.csv
    with open(zuege_csv, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, delimiter='\t')
        writer.writerow(header)
        writer.writerows(rows)
        
    print(f"\nUpdated {zuege_csv.name} with 'Fotos' column. Found photos for {len(train_photos)} trains.")
    
    # Write train_photos.json
    with open(train_photos_json, "w", encoding="utf-8") as f:
        json.dump(train_photos, f, ensure_ascii=False, indent=2)
    print(f"Written to: {train_photos_json}")


def main():
    script_dir = pathlib.Path(__file__).parent
    out_dir = script_dir.parent / "data" / "img" / "vorbild"
    out_dir.mkdir(parents=True, exist_ok=True)
    json_path = out_dir / OUTPUT_JSON
    tsv_path  = out_dir / OUTPUT_TSV

    # Load existing index so we can skip already-extracted images
    existing = []
    if json_path.exists():
        with open(json_path, encoding="utf-8") as f:
            existing = json.load(f)
        print(f"Loaded {len(existing)} already-extracted images from {json_path}")
    known_urls = {img["detail_url"] for img in existing}

    print(f"Fetching gallery index: {BASE_URL + GALLERY_URL}")
    first_html = fetch(BASE_URL + GALLERY_URL)

    page_urls = get_page_urls(first_html)
    print(f"Found {len(page_urls)} page(s).")

    new_images = []
    dot_count = 0

    for i, url in enumerate(page_urls):
        print(f"\nPage {i + 1}/{len(page_urls)}: {url}")
        if i == 0:
            html = first_html
        else:
            time.sleep(1)  # be polite
            html = fetch(url)

        parser = GalleryParser()
        parser.feed(html)

        page_new = 0
        page_skip = 0
        for img in parser.images:
            if img["detail_url"] in known_urls:
                page_skip += 1
            else:
                known_urls.add(img["detail_url"])
                new_images.append(img)
                page_new += 1
                dot_count += 1
                sys.stdout.write(".")
                if dot_count % 50 == 0:
                    sys.stdout.write("\n")
                sys.stdout.flush()

        print(f"\n  -> {page_new} new, {page_skip} already known")

    all_images = existing + new_images
    print(f"\nTotal: {len(all_images)} images ({len(new_images)} new, {len(existing)} existing)")

    if new_images:
        # Write JSON index
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(all_images, f, ensure_ascii=False, indent=2)
        print(f"JSON index written to: {json_path}")

        # Write TSV for quick inspection
        with open(tsv_path, "w", encoding="utf-8") as f:
            f.write("title\tdetail_url\tthumbnail_url\tcaption\n")
            for img in all_images:
                line = "\t".join([
                    img.get("title", ""),
                    img.get("detail_url", ""),
                    img.get("thumbnail_url", ""),
                    img.get("caption", "").replace("\n", " ").replace("\t", " "),
                ])
                f.write(line + "\n")
        print(f"TSV  index written to: {tsv_path}")
    else:
        print("Nothing new — index unchanged.")

    # Always run matching so users can re-match on changed zuege.csv
    match_trains(all_images, script_dir)

if __name__ == "__main__":
    main()
