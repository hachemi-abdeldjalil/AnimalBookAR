#!/usr/bin/env python3
"""Writes the items files of the Arabic letters, Colors, Algeria, Shapes and Numbers books.

    python3 tool/make_learning_books.py

The words, letter names and colours live here; the 3D models come from
tool/make_shapes.py (run it next: it also fills in each colour scene's parts).
Then run make_pages.py and compile_targets.py with --book=letters_ar,
--book=colors and --book=algeria.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AR = ROOT / "app" / "assets" / "ar" / "books"

# A rainbow for the letters, one colour per page in turn.
RAINBOW = ["#E4572E", "#F29E1F", "#E8B90C", "#4CAF50", "#1E88E5", "#7E57C2", "#D81B60", "#00897B"]

# Arabic: letter, its name (spoken), the word, the word in English and French,
# the photo, whether the letter joins the next one (has initial/medial forms).
ARABIC = [
    ("ا", "أَلِف", "أسد", "lion", "lion", "lion", False),
    ("ب", "باء", "بقرة", "cow", "vache", "cow", True),
    ("ت", "تاء", "تفاحة", "apple", "pomme", "apple", True),
    ("ث", "ثاء", "ثعلب", "fox", "renard", "fox", True),
    ("ج", "جيم", "جمل", "camel", "chameau", "camel", True),
    ("ح", "حاء", "حصان", "horse", "cheval", "horse", True),
    ("خ", "خاء", "خروف", "sheep", "mouton", "sheep", True),
    ("د", "دال", "دب", "bear", "ours", "bear", False),
    ("ذ", "ذال", "ذرة", "corn", "maïs", "corn", False),
    ("ر", "راء", "رمان", "pomegranate", "grenade", "pomegranate", False),
    ("ز", "زاي", "زرافة", "giraffe", "girafe", "giraffe", False),
    ("س", "سين", "سيارة", "car", "voiture", "car", True),
    ("ش", "شين", "شاحنة", "truck", "camion", "truck", True),
    ("ص", "صاد", "صقر", "falcon", "faucon", "falcon", True),
    ("ض", "ضاد", "ضفدع", "frog", "grenouille", "frog", True),
    ("ط", "طاء", "طائرة", "airplane", "avion", "airplane", True),
    ("ظ", "ظاء", "ظبي", "gazelle", "gazelle", "gazelle", True),
    ("ع", "عين", "عصفور", "sparrow", "moineau", "sparrow", True),
    ("غ", "غين", "غيمة", "cloud", "nuage", "cloud", True),
    ("ف", "فاء", "فيل", "elephant", "éléphant", "elephant", True),
    ("ق", "قاف", "قطة", "cat", "chat", "cat", True),
    ("ك", "كاف", "كلب", "dog", "chien", "dog", True),
    ("ل", "لام", "لقلق", "stork", "cigogne", "stork", True),
    ("م", "ميم", "موز", "banana", "banane", "banana", True),
    ("ن", "نون", "نحلة", "bee", "abeille", "bee", True),
    ("ه", "هاء", "هدهد", "hoopoe", "huppe", "hoopoe", True),
    ("و", "واو", "وردة", "rose", "rose", "rose", False),
    ("ي", "ياء", "يمامة", "dove", "colombe", "dove", True),
]
ARABIC_LATIN = ["Alif", "Baa", "Taa", "Thaa", "Jiim", "Haa", "Khaa", "Daal", "Thaal", "Raa", "Zaay", "Siin",
                "Shiin", "Saad", "Daad", "Taa", "Thaa", "Ayn", "Ghayn", "Faa", "Qaaf", "Kaaf", "Laam", "Miim",
                "Nuun", "Haa", "Waaw", "Yaa"]

# Colours: id, hex, names, the spoken "find" question, a fact.
COLORS = [
    ("red", "#E53935", "Red", "Rouge", "أحمر", "le rouge", "الأحمر",
     ("Strawberries and fire trucks are red.", "Les fraises et les camions de pompiers sont rouges.",
      "الفراولة وشاحنة الإطفاء لونهما أحمر.")),
    ("orange", "#FB8C00", "Orange", "Orange", "برتقالي", "l'orange", "البرتقالي",
     ("Oranges and carrots are orange.", "Les oranges et les carottes sont orange.", "البرتقال والجزر لونهما برتقالي.")),
    ("yellow", "#FDD835", "Yellow", "Jaune", "أصفر", "le jaune", "الأصفر",
     ("Bananas and the sun are yellow.", "Les bananes et le soleil sont jaunes.", "الموز والشمس لونهما أصفر.")),
    ("green", "#43A047", "Green", "Vert", "أخضر", "le vert", "الأخضر",
     ("Grass and frogs are green.", "L'herbe et les grenouilles sont vertes.", "العشب والضفدع لونهما أخضر.")),
    ("blue", "#1E88E5", "Blue", "Bleu", "أزرق", "le bleu", "الأزرق",
     ("The sky and the sea are blue.", "Le ciel et la mer sont bleus.", "السماء والبحر لونهما أزرق.")),
    ("purple", "#8E24AA", "Purple", "Violet", "بنفسجي", "le violet", "البنفسجي",
     ("Grapes and eggplants can be purple.", "Le raisin et l'aubergine peuvent être violets.",
      "العنب والباذنجان قد يكونان بنفسجيين.")),
    ("pink", "#EC6FA9", "Pink", "Rose", "وردي", "le rose", "الوردي",
     ("Flamingos are pink.", "Les flamants sont roses.", "طيور النحام لونها وردي.")),
    ("brown", "#795548", "Brown", "Marron", "بني", "le marron", "البني",
     ("Bears and chocolate are brown.", "Les ours et le chocolat sont marron.", "الدب والشوكولاتة لونهما بني.")),
    ("black", "#2B2B2B", "Black", "Noir", "أسود", "le noir", "الأسود",
     ("The night sky is black.", "Le ciel de la nuit est noir.", "سماء الليل سوداء.")),
    ("white", "#F5F5F5", "White", "Blanc", "أبيض", "le blanc", "الأبيض",
     ("Milk and snow are white.", "Le lait et la neige sont blancs.", "الحليب والثلج لونهما أبيض.")),
]


def arabic_forms(letter, joins):
    t = "ـ"  # tatweel shows the joined shapes
    return [letter, letter + t, t + letter + t, t + letter] if joins else [letter, t + letter]


def letters_ar():
    items = []
    for i, ((ch, name, word, en, fr, photo, joins), latin) in enumerate(zip(ARABIC, ARABIC_LATIN)):
        items.append({
            "id": f"ar_{i + 1:02d}", "page": i + 1,
            "en": f"{latin} · {en.capitalize()}", "fr": f"{latin} · {fr.capitalize()}", "ar": f"{ch} · {word}",
            "fr_of": f"de la lettre {latin}", "ar_def": f"حرف {name}",
            "fact_en": f"{en.capitalize()} ({word}) starts with the letter {latin}.",
            "fact_fr": f"{fr.capitalize()} ({word}) commence par la lettre {latin}.",
            "fact_ar": f"كلمة {word} تبدأ بحرف {name}.",
            "letter": ch, "forms": arabic_forms(ch, joins), "word": word, "photo": photo,
            "say": f"{name}. {word}", "say_lang": "ar",
            "model": f"books/letters_ar/models/ar_{i + 1:02d}.glb", "sound": None,
            "color": RAINBOW[i % len(RAINBOW)], "size": 0.42, "lift": 0, "turn": 0,
            "helps": {"en": f"Where is the letter {latin}?", "fr": f"Où est la lettre {latin} ?",
                      "ar": f"أين حرف ال{name}؟" if not name.startswith("أ") else f"أين حرف {name}؟"},
            "helps_say": f"أين حرف {name}؟",
            "parts": [],
        })
    return items


def colors():
    items = []
    for i, (cid, hexc, en, fr, ar, fr_def, ar_def, (fen, ffr, far)) in enumerate(COLORS):
        items.append({
            "id": f"color_{cid}", "page": i + 1, "en": en, "fr": fr, "ar": ar,
            "fr_of": f"du {fr_def[3:]}" if fr_def.startswith("le ") else f"de {fr_def}", "ar_def": f"اللون {ar_def}",
            "fact_en": fen, "fact_fr": ffr, "fact_ar": far,
            "model": f"books/colors/models/{cid}.glb", "sound": None,
            "say": None,
            "color": hexc, "size": 0.62, "lift": 0, "turn": 0,
            "needs": [cid],
            "helps": {"en": f"Find the colour {en.lower()}!", "fr": f"Trouve la couleur {fr.lower()} !",
                      "ar": f"ابحث عن اللون {ar_def}!"},
            "parts": [],  # filled in by make_shapes.py: the objects in the scene
        })
    return items



# Algeria: id, colour, size, names (en, fr, ar), fr_of, ar_def, fact (en, fr, ar),
# parts (id, en, fr, ar, fr_def, ar_def). Models come from make_shapes.py, except
# the fennec, which reuses the animated fox.
P = {
    "crescent": ("Crescent", "Croissant", "هلال", "le croissant", "الهلال"),
    "star": ("Star", "Étoile", "نجمة", "l'étoile", "النجمة"),
    "pole": ("Pole", "Mât", "سارية", "le mât", "السارية"),
    "leaf": ("Palm leaf", "Palme", "سعفة", "la palme", "السعفة"),
    "flame": ("Eternal flame", "Flamme éternelle", "الشعلة", "la flamme", "الشعلة"),
    "base": ("Base", "Socle", "قاعدة", "le socle", "القاعدة"),
    "minaret": ("Minaret", "Minaret", "مئذنة", "le minaret", "المئذنة"),
    "dome": ("Dome", "Coupole", "قبة", "la coupole", "القبة"),
    "arches": ("Arches", "Arcades", "أقواس", "les arcades", "الأقواس"),
    "house": ("House", "Maison", "بيت", "la maison", "البيت"),
    "stairs": ("Stairs", "Escalier", "درج", "l'escalier", "الدرج"),
    "sea": ("Sea", "Mer", "بحر", "la mer", "البحر"),
    "arch": ("Arch", "Arc", "قوس", "l'arc", "القوس"),
    "column": ("Column", "Colonne", "عمود", "la colonne", "العمود"),
    "hill": ("Hill", "Colline", "تل", "la colline", "التل"),
    "rock": ("Rock", "Rocher", "صخرة", "le rocher", "الصخرة"),
    "sand": ("Sand", "Sable", "رمل", "le sable", "الرمل"),
    "painting": ("Rock painting", "Peinture", "رسم", "la peinture", "الرسم"),
    "trunk": ("Trunk", "Tronc", "جذع", "le tronc", "الجذع"),
    "fronds": ("Fronds", "Palmes", "سعف", "les palmes", "السعف"),
    "dates": ("Dates", "Dattes", "تمر", "les dattes", "التمر"),
    "plate": ("Dish", "Plat", "طبق", "le plat", "الطبق"),
    "grains": ("Semolina", "Semoule", "سميد", "la semoule", "السميد"),
    "carrot": ("Carrot", "Carotte", "جزرة", "la carotte", "الجزرة"),
    "chickpeas": ("Chickpeas", "Pois chiches", "حمص", "les pois chiches", "الحمص"),
    "teapot": ("Teapot", "Théière", "إبريق", "la théière", "الإبريق"),
    "glass": ("Glass", "Verre", "كأس", "le verre", "الكأس"),
    "mint": ("Mint", "Menthe", "نعناع", "la menthe", "النعناع"),
    "tray": ("Tray", "Plateau", "صينية", "le plateau", "الصينية"),
    "skin": ("Drum skin", "Peau", "جلد", "la peau", "الجلد"),
    "body": ("Body", "Corps", "جسم", "le corps", "الجسم"),
}
ALGERIA = [
    ("flag", "#006233", 0.38, ("Flag of Algeria", "Drapeau algérien", "العلم الجزائري"), "du drapeau", "العلم الجزائري",
     ("The green and white flag has a red crescent and star.", "Le drapeau vert et blanc porte un croissant et une étoile rouges.",
      "العلم الأخضر والأبيض يحمل هلالًا ونجمة باللون الأحمر."), ["crescent", "star", "pole"]),
    ("memorial", "#8D6E63", 0.42, ("Maqam Echahid", "Maqam Echahid", "مقام الشهيد"), "du Maqam Echahid", "مقام الشهيد",
     ("Maqam Echahid, 92 metres tall, honours the martyrs.", "Le Maqam Echahid, haut de 92 mètres, honore les martyrs.",
      "مقام الشهيد بارتفاع 92 مترًا يخلّد ذكرى الشهداء."), ["leaf", "flame", "base"]),
    ("mosque", "#00897B", 0.5, ("Djamaa El Djazair", "Djamaa El Djazaïr", "جامع الجزائر"), "de Djamaa El Djazaïr", "جامع الجزائر",
     ("Djamaa El Djazair has the tallest minaret in the world: 265 metres.",
      "Djamaa El Djazaïr a le plus haut minaret du monde : 265 mètres.", "لجامع الجزائر أطول مئذنة في العالم: 265 مترًا."),
     ["minaret", "dome", "arches"]),
    ("casbah", "#1E88E5", 0.62, ("Casbah of Algiers", "Casbah d'Alger", "القصبة"), "de la Casbah", "القصبة",
     ("The Casbah of Algiers: old white houses and narrow streets.",
      "La Casbah d'Alger : vieilles maisons blanches et ruelles étroites.",
      "القصبة مدينة قديمة في الجزائر العاصمة بيوتها بيضاء وأزقتها ضيقة."), ["house", "stairs", "sea"]),
    ("timgad", "#C2853D", 0.6, ("Timgad", "Timgad", "تيمقاد"), "de Timgad", "تيمقاد",
     ("Timgad is a Roman town almost 2,000 years old.", "Timgad est une ville romaine vieille de près de 2 000 ans.",
      "تيمقاد مدينة رومانية عمرها نحو ألفي سنة."), ["arch", "column"]),
    ("ghardaia", "#D08C3A", 0.62, ("Ghardaïa", "Ghardaïa", "غرداية"), "de Ghardaïa", "غرداية",
     ("In the M'zab valley, houses climb the hill around the mosque.",
      "Dans la vallée du M'zab, les maisons montent la colline autour de la mosquée.",
      "في وادي ميزاب تصعد البيوت التلّ حول المسجد."), ["minaret", "house", "hill"]),
    ("tassili", "#B5452F", 0.62, ("Tassili n'Ajjer", "Tassili n'Ajjer", "طاسيلي ناجر"), "du Tassili", "طاسيلي ناجر",
     ("Tassili n'Ajjer has very old paintings of animals on its rocks.",
      "Le Tassili n'Ajjer a de très vieilles peintures d'animaux sur ses rochers.",
      "في طاسيلي ناجر رسوم قديمة جدًا لحيوانات على الصخور."), ["rock", "sand", "painting"]),
    ("palm", "#6B8E23", 0.4, ("Date palm", "Palmier dattier", "النخلة"), "du palmier", "النخلة",
     ("Dates from Biskra, like Deglet Nour, are famous all over the world.",
      "Les dattes de Biskra, comme la Deglet Nour, sont célèbres dans le monde.",
      "تمور بسكرة مثل دقلة نور مشهورة في العالم كله."), ["trunk", "fronds", "dates"]),
    ("fennec", "#E0A458", 0.55, ("Fennec", "Fennec", "الفنك"), "du fennec", "الفنك",
     ("The fennec is Algeria's national animal. Its big ears keep it cool.",
      "Le fennec est l'animal national de l'Algérie. Ses grandes oreilles le rafraîchissent.",
      "الفنك هو الحيوان الوطني للجزائر، وأذناه الكبيرتان تبرّدان جسمه."), None),
    ("couscous", "#E3B04B", 0.55, ("Couscous", "Couscous", "الكسكسي"), "du couscous", "الكسكسي",
     ("Couscous is made of small grains of semolina, served with vegetables.",
      "Le couscous est fait de petits grains de semoule, servis avec des légumes.",
      "الكسكسي حبيبات صغيرة من السميد تقدَّم مع الخضر."), ["plate", "grains", "carrot", "chickpeas"]),
    ("tea", "#2E7D32", 0.55, ("Mint tea", "Thé à la menthe", "الشاي بالنعناع"), "du thé à la menthe", "الشاي بالنعناع",
     ("Mint tea is poured from high up to make foam.", "Le thé à la menthe est versé de haut pour faire de la mousse.",
      "يُسكب الشاي بالنعناع من الأعلى لتكوين الرغوة."), ["teapot", "glass", "mint", "tray"]),
    ("darbuka", "#D21034", 0.45, ("Darbuka", "Darbouka", "الدربوكة"), "de la darbouka", "الدربوكة",
     ("The darbuka is a drum played with the hands at weddings and parties.",
      "La darbouka est un tambour joué avec les mains aux mariages et aux fêtes.",
      "الدربوكة طبل يُعزف باليدين في الأعراس والحفلات."), ["skin", "body"]),
]


def algeria():
    fox = next(a for a in json.loads((ROOT / "app/assets/ar/animals.json").read_text()) if a["id"] == "fox")
    items = []
    for i, (iid, color, size, (en, fr, ar), fr_of, ar_def, (fen, ffr, far), parts) in enumerate(ALGERIA):
        it = {
            "id": f"dz_{iid}", "page": i + 1, "en": en, "fr": fr, "ar": ar, "fr_of": fr_of, "ar_def": ar_def,
            "fact_en": fen, "fact_fr": ffr, "fact_ar": far,
            "model": f"books/algeria/models/{iid}.glb", "sound": None, "photo": iid,
            "color": color, "size": size, "lift": 0, "turn": 0,
            "helps": {"en": f"Where is {en}?", "fr": f"Où est {fr} ?", "ar": f"أين {ar_def}؟"},
            "parts": [{"id": p, "en": P[p][0], "fr": P[p][1], "ar": P[p][2], "fr_def": P[p][3], "ar_def": P[p][4],
                       "at": [0.5, 0.5, 0.5]} for p in parts] if parts else [],
        }
        if iid == "fennec":  # the animated fox, with its sound and body parts
            it.update(model=fox["model"], sound=fox["sound"], turn=fox["turn"], lift=fox["lift"], parts=fox["parts"])
        if iid == "darbuka":
            it["sound"] = "books/algeria/sounds/darbuka.m4a"
        items.append(it)
    return items



# Shapes: id, names (en, fr, ar), fr_def, ar_def, sides/corners fact (en, fr, ar).
SHAPES = [
    ("circle", "Circle", "Cercle", "دائرة", "le cercle", "الدائرة",
     ("A circle is round: no sides, no corners. Like a wheel!", "Un cercle est rond : ni côtés ni coins. Comme une roue !",
      "الدائرة مستديرة: بلا أضلاع ولا زوايا. مثل العجلة!")),
    ("square", "Square", "Carré", "مربع", "le carré", "المربع",
     ("A square has 4 equal sides and 4 corners.", "Un carré a 4 côtés égaux et 4 coins.", "للمربع 4 أضلاع متساوية و4 زوايا.")),
    ("triangle", "Triangle", "Triangle", "مثلث", "le triangle", "المثلث",
     ("A triangle has 3 sides and 3 corners.", "Un triangle a 3 côtés et 3 coins.", "للمثلث 3 أضلاع و3 زوايا.")),
    ("rectangle", "Rectangle", "Rectangle", "مستطيل", "le rectangle", "المستطيل",
     ("A rectangle has 4 sides: 2 long and 2 short. Like a door!", "Un rectangle a 4 côtés : 2 longs et 2 courts. Comme une porte !",
      "للمستطيل 4 أضلاع: ضلعان طويلان وضلعان قصيران. مثل الباب!")),
    ("oval", "Oval", "Ovale", "بيضاوي", "l'ovale", "الشكل البيضاوي",
     ("An oval is a stretched circle. Like an egg!", "Un ovale est un cercle étiré. Comme un œuf !",
      "الشكل البيضاوي دائرة ممدودة. مثل البيضة!")),
    ("star", "Star", "Étoile", "نجمة", "l'étoile", "النجمة",
     ("This star has 5 points.", "Cette étoile a 5 pointes.", "لهذه النجمة 5 رؤوس.")),
    ("heart", "Heart", "Cœur", "قلب", "le cœur", "القلب",
     ("A heart shape means love!", "Un cœur veut dire « je t'aime » !", "شكل القلب يعني الحب!")),
    ("diamond", "Diamond", "Losange", "معين", "le losange", "المعين",
     ("A diamond has 4 equal sides, standing on a corner.", "Un losange a 4 côtés égaux, posé sur un coin.",
      "للمعين 4 أضلاع متساوية، ويقف على زاوية.")),
    ("pentagon", "Pentagon", "Pentagone", "مخمس", "le pentagone", "المخمس",
     ("A pentagon has 5 sides and 5 corners.", "Un pentagone a 5 côtés et 5 coins.", "للمخمس 5 أضلاع و5 زوايا.")),
    ("hexagon", "Hexagon", "Hexagone", "مسدس", "l'hexagone", "المسدس",
     ("A hexagon has 6 sides. Bees build hexagons!", "Un hexagone a 6 côtés. Les abeilles en construisent !",
      "للمسدس 6 أضلاع. النحل يبني خلايا سداسية!")),
]

# Numbers 1 to 10: the word in each language.
NUMBERS = [
    (1, "One", "Un", "واحد"), (2, "Two", "Deux", "اثنان"), (3, "Three", "Trois", "ثلاثة"), (4, "Four", "Quatre", "أربعة"),
    (5, "Five", "Cinq", "خمسة"), (6, "Six", "Six", "ستة"), (7, "Seven", "Sept", "سبعة"), (8, "Eight", "Huit", "ثمانية"),
    (9, "Nine", "Neuf", "تسعة"), (10, "Ten", "Dix", "عشرة"),
]
EASTERN = "٠١٢٣٤٥٦٧٨٩"


def shapes_book():
    items = []
    for i, (sid, en, fr, ar, fr_def, ar_def, (fen, ffr, far)) in enumerate(SHAPES):
        items.append({
            "id": f"shape_{sid}", "page": i + 1, "en": en, "fr": fr, "ar": ar,
            "fr_of": ("du " + fr_def[3:]) if fr_def.startswith("le ") else ("de " + fr_def), "ar_def": ar_def,
            "fact_en": fen, "fact_fr": ffr, "fact_ar": far,
            "model": f"books/shapes/models/{sid}.glb", "sound": None, "letter": f"shape:{sid}", "shape": sid,
            "color": RAINBOW[i % len(RAINBOW)], "size": 0.42, "lift": 0, "turn": 0,
            "helps": {"en": f"Where is the {en.lower()}?", "fr": f"Où est {fr_def} ?", "ar": f"أين {ar_def}؟"},
            "parts": [],
        })
    return items


def numbers_book():
    items = []
    for i, (n, en, fr, ar) in enumerate(NUMBERS):
        east = "".join(EASTERN[int(d)] for d in str(n))
        items.append({
            "id": f"num_{n}", "page": i + 1, "en": f"{n} · {en}", "fr": f"{n} · {fr}", "ar": f"{east} · {ar}",
            "fr_of": f"du nombre {n}", "ar_def": f"العدد {ar}",
            "fact_en": f"Count the stars: there are {n}!", "fact_fr": f"Compte les étoiles : il y en a {n} !",
            "fact_ar": f"عُدّ النجوم: إنها {ar}!",
            "model": f"books/numbers/models/num_{n}.glb", "sound": None, "letter": str(n), "number": n, "eastern": east,
            "color": RAINBOW[i % len(RAINBOW)], "size": 0.5, "lift": 0, "turn": 0,
            "helps": {"en": f"Where is number {en.lower()}?", "fr": f"Où est le nombre {fr.lower()} ?", "ar": f"أين العدد {ar}؟"},
            "parts": [],
        })
    return items


def write(book, items):
    d = AR / book
    for sub in ["models", "pages", "thumbs", "sounds"] if book == "algeria" else ["models", "pages", "thumbs"]:
        (d / sub).mkdir(parents=True, exist_ok=True)
    f = d / "items.json"
    if f.exists():  # keep the spots make_shapes.py measured
        old = {x["id"]: x for x in json.loads(f.read_text())}
        for it in items:
            before = {p["id"]: p for p in old.get(it["id"], {}).get("parts", [])}
            if not it["parts"]:
                it["parts"] = list(before.values())
            for p in it["parts"]:
                if p["id"] in before and p.get("at") == [0.5, 0.5, 0.5]:
                    p["at"] = before[p["id"]]["at"]
    f.write_text(json.dumps(items, ensure_ascii=False, indent=1))
    print("wrote", f.relative_to(ROOT), len(items))


if __name__ == "__main__":
    write("letters_ar", letters_ar())
    write("colors", colors())
    write("algeria", algeria())
    write("shapes", shapes_book())
    write("numbers", numbers_book())
