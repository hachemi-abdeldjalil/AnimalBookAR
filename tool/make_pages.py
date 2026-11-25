#!/usr/bin/env python3
"""Builds the printable animal book.

Reads app/assets/ar/animals.json and tool/photos/<id>.jpg, then writes:
  book/pages/<id>.png        one A4 page per animal (also the AR tracking image)
  book/animal-book.pdf       all pages, ready to print on A4
  app/assets/ar/pages/<id>.jpg  smaller copies the app shows ("Show page")
  app/assets/thumbs/<id>.jpg    round-photo thumbnails for the zoo path (square crops)

Usage: python3 tool/make_pages.py [--book=cars]   (paths for other books: see tool/bookcfg.py)
Needs Google Chrome in /Applications.
"""
import html
import json
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

from bookcfg import BOOK

ROOT = Path(__file__).resolve().parent.parent
APP_AR = ROOT / "app" / "assets" / "ar"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Where each animal is in its photo (x, y as fractions), for the square thumbnails.
THUMB_FOCUS = {"horse": (0.38, 0.5), "fox": (0.62, 0.45), "flamingo": (0.5, 0.5),
               "parrot": (0.42, 0.45), "stork": (0.5, 0.45), "cow": (0.5, 0.5), "sheep": (0.5, 0.55),
               "zebra": (0.5, 0.5), "llama": (0.45, 0.5), "dog": (0.5, 0.45), "lion": (0.5, 0.45),
               "elephant": (0.5, 0.5), "giraffe": (0.5, 0.35), "camel": (0.5, 0.45),
               "bus": (0.45, 0.5), "firetruck": (0.45, 0.5), "truck": (0.5, 0.55)}

# A4 at 96 CSS px per inch is 794 x 1123. Screenshots use a 1.5625 scale
# factor, giving 1240 x 1754 PNGs (150 dpi).
PAGE_W, PAGE_H, SCALE = 794, 1123, 1.5625

CSS = """
@page { size: A4; margin: 0; }
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { background: #fff; }
.page {
  width: 794px; height: 1123px; position: relative; overflow: hidden;
  background: #fffaf0; font-family: "Avenir Next", "Helvetica Neue", Arial, sans-serif;
  border: 22px solid var(--c); page-break-after: always;
}
.page:last-child { page-break-after: auto; }
.badge {
  position: absolute; top: 26px; left: 30px; background: var(--c); color: #fff;
  font-weight: 800; font-size: 22px; padding: 8px 18px; border-radius: 30px;
}
.photo {
  position: absolute; top: 90px; left: 40px; right: 40px; height: 600px;
  border-radius: 28px; overflow: hidden; border: 6px solid var(--c);
}
.photo img { width: 100%; height: 100%; object-fit: cover; }
.names { position: absolute; top: 715px; left: 40px; right: 40px; text-align: center; }
.en { font-size: 76px; font-weight: 900; color: var(--c); line-height: 1; }
.row { display: flex; justify-content: center; gap: 36px; margin-top: 14px; align-items: baseline; }
.fr { font-size: 40px; font-weight: 700; color: #333; }
.ar { font-size: 46px; font-weight: 700; color: #333; font-family: "Geeza Pro", "Al Bayan", sans-serif; }
.facts { position: absolute; top: 905px; left: 50px; right: 50px; font-size: 21px; color: #333; line-height: 1.45; }
.facts p { margin-bottom: 4px; }
.facts .far { direction: rtl; text-align: right; font-family: "Geeza Pro", sans-serif; font-size: 23px; }
.foot {
  position: absolute; bottom: 10px; left: 30px; right: 30px; font-size: 10px; color: #777;
  display: flex; justify-content: space-between; gap: 20px;
}
"""


ICON = {"vehicles": "🚗", "letters": "✏️", "colors": "🎨", "heritage": "🌴", "shapes": "🔷", "numbers": "🔢"}.get(BOOK.kind, "🐾")


def page_html(a, num, credit):
    e = html.escape
    return f"""
<section class="page" style="--c:{a['color']}">
  <div class="badge">{num}</div>
  <div class="photo"><img src="{(BOOK.photos / (a.get('photo', a['id']) + '.jpg')).as_uri()}"></div>
  <div class="names">
    <div class="en" style="font-size:{76 if len(a['en']) <= 15 else int(76 * 15 / len(a['en']))}px">{e(a['en'])}</div>
    <div class="row"><span class="fr">{e(a['fr'])}</span><span class="ar" dir="rtl">{e(a['ar'])}</span></div>
  </div>
  <div class="facts" style="{'font-size:18.5px' if len(a['fact_en']) + len(a['fact_fr']) > 125 else ''}">
    <p>{ICON} {e(a['fact_en'])}</p>
    <p>{ICON} {e(a['fact_fr'])}</p>
    <p class="far">{e(a['fact_ar'])} {ICON}</p>
  </div>
  <div class="foot"><span>Point the Animal Book AR app at this page ({e(BOOK.cfg["en"])})</span><span>Photo: {e(credit)}</span></div>
</section>"""


LEARN_CSS = """
.letter-top { position: absolute; top: 90px; left: 40px; right: 40px; height: 430px; display: flex; gap: 26px; align-items: center; }
.big { flex: 1; height: 100%; border-radius: 28px; background: var(--c); color: #fff; display: flex;
  align-items: center; justify-content: center; font-weight: 900; line-height: 1; }
.big.ar { font-family: "Geeza Pro", "Al Bayan", sans-serif; font-size: 330px; padding-bottom: 40px; }
.big.fr { font-family: "Avenir Next", "Helvetica Neue", Arial, sans-serif; font-size: 230px; }
.pic { width: 330px; height: 330px; border-radius: 28px; overflow: hidden; border: 6px solid var(--c); flex: none; }
.pic img { width: 100%; height: 100%; object-fit: cover; }
.word { position: absolute; top: 545px; left: 40px; right: 40px; text-align: center; }
.word .main { font-size: 96px; font-weight: 900; color: var(--c); line-height: 1.05; }
.word .main.ar { font-family: "Geeza Pro", sans-serif; }
.forms { position: absolute; top: 760px; left: 60px; right: 60px; display: flex; justify-content: center; gap: 22px; }
.forms span { min-width: 120px; padding: 6px 18px; text-align: center; border: 4px dashed var(--c); border-radius: 22px;
  font-size: 74px; font-weight: 800; color: #333; font-family: "Geeza Pro", "Avenir Next", sans-serif; }
.forms-label { position: absolute; top: 722px; left: 0; right: 0; text-align: center; font-size: 20px; color: #777; }
.splash { position: absolute; top: 70px; left: 20px; right: 20px; height: 640px; }
.scene { position: absolute; top: 95px; left: 60px; right: 60px; height: 470px; }
.shades { position: absolute; top: 572px; left: 40px; right: 40px; display: flex; justify-content: center; gap: 26px; }
.shade { width: 200px; text-align: center; }
.shade b { display: block; width: 62px; height: 62px; margin: 0 auto 6px; border-radius: 50%; border: 3px solid rgba(0,0,0,.15); }
.shade .n { font-size: 19px; font-weight: 800; color: #333; }
.shade .o { font-size: 14px; color: #666; }
.scene img { width: 100%; height: 100%; object-fit: contain; }
.cname { position: absolute; top: 715px; left: 40px; right: 40px; text-align: center; }
.cname .en { -webkit-text-stroke: 3px #333; }
"""

SPLASH = ("M300 40 C390 20 470 90 560 70 C680 40 760 150 720 250 C700 300 770 360 740 440 C700 560 560 560 470 600 "
          "C380 640 260 620 190 560 C110 500 30 470 40 360 C48 270 10 200 70 130 C130 60 220 60 300 40 Z")


def letter_page(a, num, credit, photo):
    e = html.escape
    lang = "ar" if BOOK.id == "letters_ar" else "fr"
    other = (f'<span class="fr">{e(a["fr"].split(" · ")[-1])}</span><span class="en" style="font-size:40px;font-weight:700;color:#333">'
             f'{e(a["en"].split(" · ")[-1])}</span>') if lang == "ar" else \
            (f'<span class="ar" dir="rtl">{e(a["ar"].split(" · ")[-1])}</span><span style="font-size:40px;font-weight:700;color:#333">'
             f'{e(a["en"].split(" · ")[-1])}</span>')
    forms = "".join(f"<span>{e(f)}</span>" for f in a["forms"])
    label = "أشكال الحرف" if lang == "ar" else "Majuscule · minuscule"
    return f"""
<section class="page" style="--c:{a['color']}">
  <div class="badge">{num}</div>
  <div class="letter-top"><div class="big {lang}" {'dir="rtl"' if lang == 'ar' else ''}>{e(a['letter'])}</div>
    <div class="pic"><img src="{photo.as_uri()}"></div></div>
  <div class="word"><div class="main {lang}" {'dir="rtl"' if lang == 'ar' else ''}>{e(a['word'])}</div>
    <div class="row">{other}</div></div>
  <div class="forms-label">{label}</div>
  <div class="forms" {'dir="rtl"' if lang == 'ar' else ''}>{forms}</div>
  <div class="facts" style="top:930px">
    <p>{ICON} {e(a['fact_en'])}</p>
    <p>{ICON} {e(a['fact_fr'])}</p>
    <p class="far">{e(a['fact_ar'])} {ICON}</p>
  </div>
  <div class="foot"><span>Point the Animal Book AR app at this page ({e(BOOK.cfg["en"])})</span><span>Photo: {e(credit)}</span></div>
</section>"""


def color_page(a, num):
    e = html.escape
    scene = BOOK.photos / (a["id"].removeprefix("color_") + ".png")
    edge = "#333" if a["color"].upper() in ("#F5F5F5", "#FDD835") else a["color"]
    return f"""
<section class="page" style="--c:{edge}">
  <div class="badge">{num}</div>
  {pattern(num * 13 + 5, 60, 700, avoid=(150, 150, 650, 560))}
  <svg class="splash" viewBox="0 0 800 640" preserveAspectRatio="none"><path d="{SPLASH}" fill="{a['color']}" opacity=".28"
    stroke="{edge}" stroke-width="6" stroke-dasharray="18 12"/></svg>
  <div class="scene"><img src="{scene.as_uri()}"></div>
  <div class="shades">{"".join(f'<div class="shade"><b style="background:{p["hex"]}"></b><div class="n">{e(p["en"])}</div>'
                               f'<div class="o">{e(p["fr"])} · <span dir="rtl">{e(p["ar"])}</span></div></div>'
                               for p in a["parts"])}</div>
  <div class="cname">
    <div class="en" style="color:{a['color']};font-size:96px;font-weight:900;line-height:1">{e(a['en'])}</div>
    <div class="row"><span class="fr">{e(a['fr'])}</span><span class="ar" dir="rtl">{e(a['ar'])}</span></div>
  </div>
  <div class="facts">
    <p>{ICON} {e(a['fact_en'])}</p>
    <p>{ICON} {e(a['fact_fr'])}</p>
    <p class="far">{e(a['fact_ar'])} {ICON}</p>
  </div>
  <div class="foot"><span>Point the Animal Book AR app at this page ({e(BOOK.cfg["en"])})</span><span>Pictures: Animal Book AR</span></div>
</section>"""


# Shapes drawn in a 200 x 200 box (the printed Shapes pages).
SHAPE_SVG = {
    "circle": '<circle cx="100" cy="100" r="86"/>',
    "square": '<rect x="22" y="22" width="156" height="156"/>',
    "triangle": '<polygon points="100,14 192,172 8,172"/>',
    "rectangle": '<rect x="6" y="46" width="188" height="108"/>',
    "oval": '<ellipse cx="100" cy="100" rx="94" ry="60"/>',
    "star": '<polygon points="100,8 123,72 192,72 136,112 157,180 100,140 43,180 64,112 8,72 77,72"/>',
    "heart": '<path d="M100 178 C40 130 6 98 14 60 C22 22 74 14 100 52 C126 14 178 22 186 60 C194 98 160 130 100 178Z"/>',
    "diamond": '<polygon points="100,6 166,100 100,194 34,100"/>',
    "pentagon": '<polygon points="100,10 188,74 154,180 46,180 12,74"/>',
    "hexagon": '<polygon points="190,100 145,178 55,178 10,100 55,22 145,22"/>',
}
STAR_SVG = '<svg viewBox="0 0 40 40"><polygon fill="#F2B705" stroke="#C98A00" stroke-width="1.5" points="20,2 25,15 39,15 28,24 32,38 20,30 8,38 12,24 1,15 15,15"/></svg>'


def pattern(seed, top, bottom, avoid=None, count=70, opacity=0.6):
    """A layer of small shapes across the page between [top] and [bottom] px, different on every
    page (seeded): pages that would otherwise look alike in black and white (the same balls,
    the same layout) each get their own pattern for the camera to recognise. [avoid] is a box
    (x0, y0, x1, y1) left empty."""
    import random
    rnd = random.Random(seed * 104729 + 17)
    kinds = list(SHAPE_SVG)
    colors = ["#C0392B", "#D35400", "#B7950B", "#1E8449", "#1F618D", "#6C3483", "#A93226", "#2E4053"]
    out = []
    for _ in range(count * 3):
        if len(out) >= count:
            break
        x, y = rnd.uniform(10, 784), rnd.uniform(top, bottom)
        if avoid and avoid[0] < x < avoid[2] and avoid[1] < y < avoid[3]:
            continue
        sc = rnd.uniform(0.09, 0.17)
        out.append(f'<g transform="translate({x - 100 * sc:.0f},{y - 100 * sc:.0f}) scale({sc:.2f}) '
                   f'rotate({rnd.randint(0, 359)} 100 100)" fill="{rnd.choice(colors)}">{SHAPE_SVG[rnd.choice(kinds)]}</g>')
    return (f'<svg style="position:absolute;left:0;top:0;width:794px;height:1123px;opacity:{opacity}" '
            f'viewBox="0 0 794 1123">{"".join(out)}</svg>')


def confetti(seed):
    """Small faint shapes scattered around the page's big one: more detail for
    the camera to track, and a different pattern on every page."""
    import random
    rnd = random.Random(seed * 7919)
    kinds = list(SHAPE_SVG)
    colors = ["#E4572E", "#F29E1F", "#E8B90C", "#4CAF50", "#1E88E5", "#7E57C2", "#D81B60"]
    out = []
    for _ in range(44):
        x, y = rnd.uniform(0, 620), rnd.uniform(0, 360)
        if 170 < x < 470 and 40 < y < 340:
            continue  # keep the middle for the big shape
        k = rnd.choice(kinds)
        out.append(f'<g transform="translate({x - 20:.0f},{y - 20:.0f}) scale(.2) rotate({rnd.randint(0, 90)} 100 100)" '
                   f'fill="{rnd.choice(colors)}" opacity=".7">{SHAPE_SVG[k]}</g>')
    return "".join(out)


def shape_page(a, num):
    e = html.escape
    return f"""
<section class="page" style="--c:{a['color']}">
  <div class="badge">{num}</div>
  <div class="letter-top"><div class="big" style="background:#fff;border:6px solid var(--c)">
    <svg viewBox="0 0 640 380" style="width:100%;height:100%">{confetti(num)}
      <g transform="translate(200,70) scale(1.2)" fill="{a['color']}" stroke="rgba(0,0,0,.25)" stroke-width="4">{SHAPE_SVG[a['shape']]}</g></svg></div></div>
  <div class="word"><div class="main">{e(a['en'])}</div>
    <div class="row"><span class="fr">{e(a['fr'])}</span><span class="ar" dir="rtl">{e(a['ar'])}</span></div></div>
  {pattern(num * 31 + 7, 470, 560, count=24, opacity=0.5)}
  <div class="facts" style="top:800px">
    <p>{ICON} {e(a['fact_en'])}</p>
    <p>{ICON} {e(a['fact_fr'])}</p>
    <p class="far">{e(a['fact_ar'])} {ICON}</p>
  </div>
  <div class="foot"><span>Point the Animal Book AR app at this page ({e(BOOK.cfg["en"])})</span><span>Pictures: Animal Book AR</span></div>
</section>"""


def number_page(a, num):
    e = html.escape
    n = a["number"]
    stars = "".join(f'<span style="display:inline-block;width:{70 if n <= 5 else 62}px;margin:4px">{STAR_SVG}</span>' for _ in range(n))
    return f"""
<section class="page" style="--c:{a['color']}">
  <div class="badge">{num}</div>
  <div class="letter-top" style="height:380px"><div class="big fr" style="font-size:300px">{n}</div>
    <div class="pic" style="display:flex;align-items:center;justify-content:center;background:#fff;font-size:200px;
      font-weight:900;color:var(--c);font-family:'Geeza Pro',sans-serif">{e(a['eastern'])}</div></div>
  {pattern(n * 53 + 11, 440, 680, avoid=(40, 470, 754, 600), count=40)}
  <div style="position:absolute;top:490px;left:40px;right:40px;text-align:center">{stars}</div>
  <div class="word" style="top:690px"><div class="main">{e(a['en'].split(' · ')[1])}</div>
    <div class="row"><span class="fr">{e(a['fr'].split(' · ')[1])}</span><span class="ar" dir="rtl">{e(a['ar'].split(' · ')[1])}</span></div></div>
  <div class="facts" style="top:930px">
    <p>{ICON} {e(a['fact_en'])}</p>
    <p>{ICON} {e(a['fact_fr'])}</p>
    <p class="far">{e(a['fact_ar'])} {ICON}</p>
  </div>
  <div class="foot"><span>Point the Animal Book AR app at this page ({e(BOOK.cfg["en"])})</span><span>Pictures: Animal Book AR</span></div>
</section>"""


def letter_photo(name):
    for d in ["letters", "", "cars"]:
        f = ROOT / "tool" / "photos" / d / f"{name}.jpg"
        if f.exists():
            return f
    raise SystemExit(f"no photo for {name}: put it in tool/photos/letters/{name}.jpg")


def doc(body):
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}{LEARN_CSS}</style></head><body>{body}</body></html>'


def chrome(*args):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--allow-file-access-from-files", *args],
                   check=True, capture_output=True, timeout=120)


def make_thumb(animal_id):
    out = BOOK.thumbs / f"{animal_id}.jpg"
    out.parent.mkdir(parents=True, exist_ok=True)
    fx, fy = THUMB_FOCUS.get(animal_id, (0.5, 0.5))
    photo = next((a.get("photo", a["id"]) for a in BOOK.items if a["id"] == animal_id), animal_id)
    with Image.open(BOOK.photos / f"{photo}.jpg") as im:
        im = im.convert("RGB")
        w, h = im.size
        s = min(w, h)
        left = max(0, min(w - s, int(fx * w) - s // 2))
        top = max(0, min(h - s, int(fy * h) - s // 2))
        im.crop((left, top, left + s, top + s)).resize((256, 256), Image.LANCZOS).save(out, quality=85, optimize=True)


def main():
    animals = BOOK.items
    credits = json.loads((ROOT / "tool" / "credits.json").read_text())
    BOOK.pages.mkdir(parents=True, exist_ok=True)
    BOOK.app_pages.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp())
    sections = []
    for i, a in enumerate(animals, 1):
        if BOOK.kind == "colors":
            sec = color_page(a, i)
        elif BOOK.kind == "shapes":
            sec = shape_page(a, i)
        elif BOOK.kind == "numbers":
            sec = number_page(a, i)
        else:
            c = credits[a.get("photo", a["id"]) + "_photo"]
            credit = f"{c['artist']}, {c['license']}, Wikimedia Commons"
            sec = letter_page(a, i, credit, letter_photo(a["photo"])) if BOOK.kind == "letters" else page_html(a, i, credit)
        sections.append(sec)
        f = tmp / f"{a['id']}.html"
        f.write_text(doc(sec))
        out = BOOK.pages / f"{a['id']}.png"
        chrome(f"--window-size={PAGE_W},{PAGE_H}", f"--force-device-scale-factor={SCALE}",
               f"--screenshot={out}", f.as_uri())
        with Image.open(out) as im:
            im = im.convert("RGB")
            im.thumbnail((900, 900 * PAGE_H // PAGE_W + 1))
            im.save(BOOK.app_pages / f"{a['id']}.jpg", quality=85, optimize=True)
        if BOOK.kind not in ("letters", "colors", "shapes", "numbers"):  # those thumbnails come from make_shapes.py
            make_thumb(a["id"])
        print("page", out.relative_to(ROOT))
    book = tmp / "book.html"
    book.write_text(doc("".join(sections)))
    pdf = BOOK.pdf
    chrome(f"--print-to-pdf={pdf}", "--no-pdf-header-footer", book.as_uri())
    print("book", pdf.relative_to(ROOT))


if __name__ == "__main__":
    main()
