"""Génère les icônes de lancement dev/staging à partir de celles de la prod :
fond recoloré + bandeau d'environnement (DEV / STG).

Usage (Pillow requis) : python3 scripts/generate_flavor_icons.py
puis : dart run flutter_launcher_icons
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
src = root / "assets/app-icon"
font_path = root / "assets/fonts/inter/Inter_18pt-Bold.ttf"
CREAM = (250, 250, 247)
ENVS = {
    "dev": {"label": "DEV", "bg": (61, 107, 74)},        # vertSavane
    "staging": {"label": "STG", "bg": (154, 74, 33)},    # terreCuiteDark
}

def full_icon(bg):
    """Fond uni + logo transparent du premier plan, au cadrage de
    appstore_1024 (même logo à l'échelle 1086/432, centré) : le « E » garde
    son Bleu Profond, seul le fond change."""
    img = Image.new("RGBA", (1024, 1024), (*bg, 255))
    fg = Image.open(src / "ic_launcher_foreground.png").convert("RGBA")
    fg = fg.resize((1086, 1086), Image.LANCZOS)
    img.paste(fg, (-31, -31), fg)
    return img

def banner(img, label, ink, top, bottom, left, right, radius):
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((left, top, right, bottom), radius=radius, fill=CREAM)
    size = int((bottom - top) * 0.62)
    font = ImageFont.truetype(str(font_path), size)
    cx, cy = (left + right) / 2, (top + bottom) / 2
    d.text((cx, cy), label, font=font, fill=ink, anchor="mm")

for env, spec in ENVS.items():
    out = src / env
    out.mkdir(exist_ok=True)
    # Icône pleine (iOS, Android héritée) : bandeau pleine largeur en bas,
    # sous le disque crème ; le masque iOS arrondit ses coins.
    full = full_icon(spec["bg"])
    banner(full, spec["label"], spec["bg"], 860, 1024, -40, 1064, 0)
    full.save(out / "appstore_1024.png")
    # Premier plan adaptatif (Android ≥ 8) : fond transparent, la couleur
    # passe par adaptive_icon_background ; pastille centrée dans la zone sûre.
    fg = Image.open(src / "ic_launcher_foreground.png").convert("RGBA")
    banner(fg, spec["label"], spec["bg"], 330, 392, 121, 311, 31)
    fg.save(out / "ic_launcher_foreground.png")
    print(env, "ok")
