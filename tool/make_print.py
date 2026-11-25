#!/usr/bin/env python3
"""Builds a ready-to-print PDF of every book, in the book's own theme:
a cover with its 3D stickers, a "how to use" page, every AR page, and a back
cover listing what is inside. A4, one page per sheet.

    python3 tool/make_print.py            -> book/print/<book>.pdf
    python3 tool/make_print.py --only=cars

Run after make_pages.py (the AR pages) and make_stickers.py (the stickers).
Needs Google Chrome in /Applications.
"""
import html
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
AR = ROOT / "app" / "assets" / "ar"
OUT = ROOT / "book" / "print"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ONLY = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--only=")), "")

# A line under the title and the "how to" sentence for what you meet in the book.
THEME = {
    "animals": ("Meet 14 animals in 3D!", "Découvre 14 animaux en 3D !", "تعرّف على 14 حيوانًا بالأبعاد الثلاثة!", "🐾"),
    "vehicles": ("Drive 9 vehicles in 3D!", "Conduis 9 véhicules en 3D !", "قُد 9 مركبات بالأبعاد الثلاثة!", "🚗"),
    "letters": ("The 28 Arabic letters come alive!", "Les 28 lettres arabes prennent vie !", "الحروف العربية الـ28 تنبض بالحياة!", "✏️"),
    "colors": ("Ten colours to find and mix!", "Dix couleurs à trouver et mélanger !", "عشرة ألوان لتكتشفها وتمزجها!", "🎨"),
    "shapes": ("Ten shapes to name and count!", "Dix formes à nommer et compter !", "عشرة أشكال لتسميها وتعدّ أضلاعها!", "🔷"),
    "numbers": ("Count from 1 to 10 in 3D!", "Compte de 1 à 10 en 3D !", "عُدّ من 1 إلى 10 بالأبعاد الثلاثة!", "🔢"),
    "heritage": ("12 treasures of Algeria in 3D!", "12 trésors de l'Algérie en 3D !", "12 كنزًا من الجزائر بالأبعاد الثلاثة!", "🌴"),
}
PAGES = {"animals": ROOT / "book" / "pages"}  # the first book keeps its old folder

CSS = """
@page { size: A4; margin: 0; }
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: "Avenir Next", "Helvetica Neue", Arial, sans-serif; }
.sheet { width: 210mm; height: 297mm; position: relative; overflow: hidden; page-break-after: always; }
.sheet:last-child { page-break-after: auto; }
.ar { font-family: "Geeza Pro", "Al Bayan", sans-serif; direction: rtl; }
/* cover */
.cover { color: #fff; background: linear-gradient(160deg, var(--light) 0%, var(--c) 45%, var(--dark) 100%); }
.cover .brand { position: absolute; top: 16mm; left: 0; right: 0; text-align: center; font-weight: 800; font-size: 15pt;
  letter-spacing: 3px; opacity: .9; }
.cover .title { position: absolute; top: 30mm; left: 12mm; right: 12mm; text-align: center; }
.cover h1 { font-size: 52pt; font-weight: 900; line-height: 1; text-shadow: 0 3px 0 rgba(0,0,0,.18); }
.cover .langs { margin-top: 5mm; font-size: 22pt; font-weight: 700; display: flex; justify-content: center; gap: 10mm; }
.cover .tag { margin-top: 6mm; display: inline-block; background: rgba(255,255,255,.95); color: var(--dark);
  border-radius: 30px; padding: 3mm 8mm; font-size: 14pt; font-weight: 800; }
.cover .stage { position: absolute; top: 108mm; left: 8mm; right: 8mm; height: 150mm; }
.cover .stage img { position: absolute; filter: drop-shadow(0 6px 8px rgba(0,0,0,.25)); }
.cover .disc { position: absolute; left: 20mm; right: 20mm; bottom: 6mm; height: 34mm; border-radius: 50%;
  background: rgba(255,255,255,.22); }
.cover .foot { position: absolute; bottom: 12mm; left: 0; right: 0; text-align: center; font-size: 12pt; opacity: .95; }
.dots { position: absolute; inset: 0; background-image: radial-gradient(rgba(255,255,255,.12) 2px, transparent 2px);
  background-size: 9mm 9mm; }
/* how to */
.howto { background: #fffaf0; padding: 18mm 16mm; color: #2b2118; }
.howto h2 { font-size: 30pt; font-weight: 900; color: var(--c); }
.howto .sub { font-size: 13pt; color: #7a6a5c; margin-top: 1mm; }
.step { display: flex; gap: 7mm; align-items: center; margin-top: 11mm; padding: 7mm; border-radius: 8mm; background: #fff;
  border: 1.2mm solid var(--soft); }
.num { flex: none; width: 22mm; height: 22mm; border-radius: 50%; background: var(--c); color: #fff; font-size: 26pt;
  font-weight: 900; display: flex; align-items: center; justify-content: center; }
.step .t { font-size: 16pt; font-weight: 800; }
.step .l { font-size: 12pt; color: #5c4a3a; margin-top: 1mm; line-height: 1.35; }
.step .l.ar { font-size: 14pt; }
.step img { flex: none; width: 34mm; height: 34mm; object-fit: contain; }
.tip { margin-top: 10mm; font-size: 11.5pt; color: #7a6a5c; line-height: 1.5; }
/* the AR pages */
.page img { width: 100%; height: 100%; display: block; }
/* back cover */
.back { background: linear-gradient(200deg, var(--light), var(--c) 60%, var(--dark)); color: #fff; padding: 16mm 12mm; }
.back h3 { font-size: 22pt; font-weight: 900; text-align: center; }
.grid { margin-top: 8mm; display: grid; grid-template-columns: repeat(4, 1fr); gap: 4mm; }
.cell { background: rgba(255,255,255,.95); border-radius: 5mm; padding: 2mm; text-align: center; color: #2b2118; }
.cell img { width: 100%; height: 26mm; object-fit: contain; }
.cell div { font-size: 9pt; font-weight: 800; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.cell .ar { font-size: 10pt; font-weight: 700; color: #5c4a3a; }
.back .foot { position: absolute; bottom: 12mm; left: 12mm; right: 12mm; text-align: center; font-size: 10.5pt; opacity: .95; }
"""


def shade(hex_color, k):
    """Lighter (k > 0) or darker (k < 0) version of a #rrggbb colour."""
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (1, 3, 5))
    t = 255 if k > 0 else 0
    k = abs(k)
    return "#%02x%02x%02x" % tuple(int(c + (t - c) * k) for c in (r, g, b))


def sticker(book, it):
    return (ROOT / "app" / book["thumbsDir"] / f"{it['id']}_sticker.png").as_uri()


def cover(book, items):
    e = html.escape
    en, fr, ar, icon = THEME[book["kind"]]
    picks = items[:7]
    # stickers on a fan: big in the middle, smaller to the sides
    spots = [(37, 22, 30), (8, 36, 22), (66, 36, 22), (20, 2, 18), (56, 2, 18), (0, 70, 16), (78, 70, 16)]
    imgs = "".join(
        f'<img src="{sticker(book, it)}" style="left:{x}%;top:{y}%;width:{w}%">' for it, (x, y, w) in zip(picks, spots))
    return f"""
<section class="sheet cover">
  <div class="dots"></div>
  <div class="brand">ANIMAL BOOK AR</div>
  <div class="title">
    <h1>{e(book['en'])}</h1>
    <div class="langs"><span>{e(book['fr'])}</span><span class="ar">{e(book['ar'])}</span></div>
    <div class="tag">{icon} {e(en)}</div>
  </div>
  <div class="stage"><div class="disc"></div>{imgs}</div>
  <div class="foot">{e(fr)} · <span class="ar">{e(ar)}</span></div>
</section>"""


def howto(book, items):
    e = html.escape
    steps = [
        ("Open the app", "Ouvre l'appli", "افتح التطبيق",
         f"Choose “{book['en']}” on the bookshelf.", f"Choisis « {book['fr']} » dans la bibliothèque.",
         f"اختر «{book['ar']}» من المكتبة.", items[0]),
        ("Point the camera at a page", "Vise une page avec la caméra", "وجّه الكاميرا نحو صفحة",
         "Keep the whole page in view, in good light.", "Garde toute la page visible, avec une bonne lumière.",
         "اجعل الصفحة كلها ظاهرة في إضاءة جيدة.", items[1 % len(items)]),
        ("Play!", "Joue !", "العب!",
         "Turn it with a finger, pinch to zoom, find the parts, then try the games.",
         "Tourne-le avec un doigt, pince pour zoomer, trouve les parties, puis joue.",
         "أدِره بإصبع، كبّره بإصبعين، اعثر على الأجزاء ثم جرّب الألعاب.", items[2 % len(items)]),
    ]
    blocks = "".join(f"""
  <div class="step"><div class="num">{i}</div>
    <div style="flex:1"><div class="t">{e(t_en)}</div>
      <div class="l">{e(l_en)}<br>{e(t_fr)} : {e(l_fr)}</div>
      <div class="l ar">{e(t_ar)}: {e(l_ar)}</div></div>
    <img src="{sticker(book, it)}"></div>""" for i, (t_en, t_fr, t_ar, l_en, l_fr, l_ar, it) in enumerate(steps, 1))
    return f"""
<section class="sheet howto">
  <h2>How to use this book</h2>
  <div class="sub">Comment utiliser ce livre · <span class="ar">كيف تستعمل هذا الكتاب</span></div>
  {blocks}
  <div class="tip">Print in colour on A4. Each page is a picture the app recognises: keep pages flat and clean, and
  don't crop them. · Imprime en couleur sur A4, pages bien à plat. ·
  <span class="ar">اطبع بالألوان على ورق A4 واحفظ الصفحات مستوية ونظيفة.</span></div>
</section>"""


def back(book, items):
    e = html.escape
    cells = "".join(f"""<div class="cell"><img src="{sticker(book, it)}"><div>{it['page']}. {e(it['en'])}</div>
      <div class="ar">{e(it['ar'])}</div></div>""" for it in items)
    return f"""
<section class="sheet back">
  <div class="dots"></div>
  <h3>In this book · Dans ce livre · <span class="ar">في هذا الكتاب</span></h3>
  <div class="grid">{cells}</div>
  <div class="foot">Animal Book AR · Photo, sound and model credits: see CREDITS.md in the app</div>
</section>"""


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    books = json.loads((AR / "books.json").read_text())
    tmp = Path(tempfile.mkdtemp())
    for book in books:
        if ONLY and ONLY != book["id"]:
            continue
        items = json.loads((AR / book["data"]).read_text())
        pages_dir = PAGES.get(book["id"], ROOT / "book" / book["id"] / "pages")
        c = book["color"]
        style = f"--c:{c};--light:{shade(c, 0.25)};--dark:{shade(c, -0.3)};--soft:{shade(c, 0.75)}"
        # the pages as high-quality JPEGs: the PDFs stay small enough to send (PNG pages make ~30 MB books)
        jpgs = []
        for it in items:
            j = tmp / f"{book['id']}-{it['id']}.jpg"
            with Image.open(pages_dir / f"{it['id']}.png") as im:
                im.convert("RGB").save(j, quality=88, optimize=True)
            jpgs.append(j)
        pages = "".join(f'<section class="sheet page"><img src="{j.as_uri()}"></section>' for j in jpgs)
        doc = (f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head>'
               f'<body style="{style}">{cover(book, items)}{howto(book, items)}{pages}{back(book, items)}</body></html>')
        f = tmp / f"{book['id']}.html"
        f.write_text(doc)
        out = OUT / f"{book['id']}.pdf"
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--allow-file-access-from-files",
                        f"--print-to-pdf={out}", "--no-pdf-header-footer", f.as_uri()],
                       check=True, capture_output=True, timeout=300)
        print(f"wrote {out.relative_to(ROOT)} ({len(items) + 3} pages, {out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
