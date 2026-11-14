#!/usr/bin/env python3
"""Zeichnet die eigenen SVG-Grafiken von Project Inkwell (1930er-Rubber-Hose-Stil).
Alle Motive sind Originale. Neu erzeugen: python3 tools/draw_art.py
Konvention: 2x-Auflösung (Sprite.scale = 0.5), Koordinaten in <g transform> in 1x-Einheiten."""
import math, os

ROOT = os.path.join(os.path.dirname(__file__), "..", "art")
INK = "#1c1f2a"
DEEP = "#0b0c10"
PAPER = "#f2e6c9"
GOLD = "#b8913a"
HERO = "#c8402e"
BLUE = "#2e4a7a"


def svg(path, w, h, body, defs=""):
    with open(os.path.join(ROOT, path), "w") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n')
        if defs:
            f.write(f"<defs>{defs}</defs>\n")
        f.write(body + "\n</svg>\n")


def lin(id_, c1, c2, vertical=True):
    x2, y2 = ("0", "1") if vertical else ("1", "0")
    return f'<linearGradient id="{id_}" x1="0" y1="0" x2="{x2}" y2="{y2}"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>'


def rad(id_, c1, c2, cx=0.4, cy=0.35, r=0.75):
    return f'<radialGradient id="{id_}" cx="{cx}" cy="{cy}" r="{r}"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></radialGradient>'


def pie_eye(cx, cy, rx, ry, look=(1, -1)):
    """Pie-Cut-Auge: schwarzes Oval mit ausgeschnittenem Keil."""
    wx, wy = cx + look[0] * rx * 0.25, cy + look[1] * ry * 0.35
    return (f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{INK}" stroke="none"/>'
            f'<path d="M{wx:.1f} {wy:.1f} L{wx + rx * 0.75:.1f} {wy - ry * 0.35:.1f} L{wx + rx * 0.5:.1f} {wy + ry * 0.3:.1f} Z" fill="#fff" stroke="none"/>')


# ---------------------------------------------------------------- Pete
def pete():
    defs = lin("steel", "#eceef0", "#868c95") + rad("skin", "#fff8e8", "#e0cca4") + lin("brass", "#e2c06a", "#94712a")
    head = f'''<g stroke="{INK}" stroke-width="6" stroke-linejoin="round" stroke-linecap="round">
 <path d="M44 70 C30 62 16 50 2 54 C10 62 12 70 6 80 C20 76 32 80 44 78 Z" fill="{HERO}"/>
 <path d="M44 76 C36 86 26 96 10 100 C18 90 20 84 18 76 Z" fill="#9c2c1c"/>
 <circle cx="80" cy="86" r="42" fill="url(#skin)"/>
 <path d="M40 64 C40 36 58 20 80 20 C102 20 120 36 120 64 Z" fill="url(#steel)"/>
 <path d="M80 22 L80 60" fill="none" stroke-width="4"/>
 <circle cx="60" cy="48" r="3" fill="{INK}" stroke="none"/><circle cx="100" cy="48" r="3" fill="{INK}" stroke="none"/>
 <path d="M52 40 C58 30 68 26 74 26" fill="none" stroke="#fff" stroke-width="5" opacity="0.7"/>
 <path d="M70 20 C70 4 90 4 90 20 Z" fill="url(#brass)" stroke-width="4"/>
 <path d="M39 60 C60 70 100 70 121 60 L123 74 C100 84 60 84 37 74 Z" fill="{HERO}"/>
 <circle cx="42" cy="70" r="8" fill="{HERO}"/>
 {pie_eye(92, 96, 6.5, 11)}{pie_eye(110, 94, 6, 10.5)}
 <path d="M116 100 L157 108 L116 116 Z" fill="url(#brass)" stroke-width="4"/>
 <path d="M127 108 L151 108" fill="none" stroke-width="2.5"/>
 <circle cx="125" cy="108" r="3" fill="{INK}" stroke="none"/>
 <circle cx="84" cy="110" r="7" fill="#e3a07a" opacity="0.55" stroke="none"/>
 <path d="M92 116 C99 126 110 126 116 117" fill="none" stroke-width="4"/>
</g>'''
    svg("pete/head.svg", 160, 150, head, defs)

    # Torso: Ursprung 1x (0,-55) = Bildmitte
    torso = f'''<g transform="translate(48,50) scale(2)" stroke="{INK}" stroke-linejoin="round" stroke-linecap="round">
 <path d="M-11 -19 C-6 -24 6 -24 11 -19 L13 4 C6 9 -6 9 -13 4 Z" fill="{INK}" stroke-width="2.5"/>
 <path d="M-6 -17 C-4 -20 0 -21 2 -21" fill="none" stroke="#5a6080" stroke-width="2"/>
 <path d="M-18 1 C-8 -5 8 -5 18 1 C22 10 18 19 12 21 L-12 21 C-18 19 -22 10 -18 1 Z" fill="{BLUE}" stroke-width="2.5"/>
 <path d="M-17 2 C-8 -3 8 -3 17 2" fill="none" stroke="{GOLD}" stroke-width="2.5"/>
 <rect x="4" y="-3" width="5" height="12" rx="1.5" fill="{GOLD}" stroke-width="1.5"/>
 <path d="M-10 8 C-8 14 -8 17 -9 20" fill="none" stroke="#1f3456" stroke-width="1.5"/>
</g>'''
    svg("pete/torso.svg", 96, 100, torso)

    glove_open = f'''<g stroke="{INK}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
 <path d="M10 28 C4 20 8 8 16 8 C18 3 26 3 29 8 C35 7 40 13 38 20 C42 24 40 33 33 35 C27 41 15 41 10 28 Z" fill="#fff"/>
 <path d="M19 13 L19 22 M27 12 L27 22" stroke-width="2.5" fill="none"/>
 <path d="M6 31 C9 37 13 40 18 41" stroke-width="5" fill="none"/>
</g>'''
    svg("pete/glove.svg", 46, 46, glove_open)

    # Fingerpistole nach rechts, Handgelenk bei (14,24)
    glove_point = f'''<g stroke="{INK}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
 <path d="M14 30 C8 22 12 12 22 12 L48 12 C54 12 54 20 48 20 L34 20 C38 24 38 32 30 35 C24 38 17 36 14 30 Z" fill="#fff"/>
 <path d="M22 13 C20 4 26 1 30 6 L31 13" fill="#fff"/>
 <path d="M26 24 L34 24 M25 30 L32 30" stroke-width="2.5" fill="none"/>
 <path d="M8 22 C6 28 8 34 12 37" stroke-width="5" fill="none"/>
</g>'''
    svg("pete/glove_point.svg", 60, 46, glove_point)

    shoe = f'''<g stroke="{INK}" stroke-width="4" stroke-linejoin="round">
 <path d="M6 28 C5 14 18 10 30 12 C47 9 62 14 62 24 C62 32 52 34 32 34 L10 34 C6 34 6 32 6 28 Z" fill="#5a3a26"/>
 <ellipse cx="46" cy="18" rx="8" ry="4" fill="#fff" opacity="0.35" stroke="none"/>
 <path d="M8 30 L60 30" stroke-width="2.5" fill="none" stroke="#2e1d12"/>
</g>'''
    svg("pete/shoe.svg", 68, 38, shoe)


# ---------------------------------------------------------------- Gegner
def enemies():
    defs = rad("blobg", "#454a62", "#101219", 0.4, 0.3, 0.8) + rad("flame", "#ffe39a", "#e0752a", 0.5, 0.7, 0.7)
    blob = f'''<g stroke="{DEEP}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round">
 <path d="M50 16 C46 8 52 2 50 -6 C58 2 60 10 56 16 Z" transform="translate(0,6)" fill="url(#flame)" stroke-width="3"/>
 <path d="M14 82 C2 82 2 60 12 46 C20 24 36 16 50 18 C68 18 84 30 88 50 C94 64 94 82 80 84 Z" fill="url(#blobg)"/>
 <path d="M26 40 C30 30 38 26 46 26" fill="none" stroke="#fff" stroke-width="5" opacity="0.45"/>
 <ellipse cx="38" cy="52" rx="10" ry="13" fill="#fff" stroke-width="3"/>
 <ellipse cx="62" cy="52" rx="10" ry="13" fill="#fff" stroke-width="3"/>
 {pie_eye(41, 55, 4.5, 7.5)}{pie_eye(65, 55, 4.5, 7.5)}
 <path d="M28 36 L46 42 M72 36 L54 42" fill="none" stroke-width="4"/>
 <path d="M40 72 C46 66 56 66 62 72" fill="none" stroke="#fff" stroke-width="3"/>
</g>'''
    svg("enemies/ink_blob.svg", 100, 92, blob, defs)

    # Bleistift zeigt nach unten, Bildmitte = 1x (0,0), Spitze bei 1x y≈48
    pdefs = lin("wood", "#f3dfb3", "#c9a56a", False) + lin("yel", "#f2cf5a", "#c99a24", False) + lin("metal", "#d7dbe0", "#868c95", False)
    pencil = f'''<g stroke="{INK}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
 <rect x="14" y="4" width="36" height="22" rx="8" fill="#a85a4a"/>
 <rect x="12" y="24" width="40" height="18" fill="url(#metal)"/>
 <path d="M12 30 L52 30 M12 36 L52 36" stroke-width="2"/>
 <rect x="12" y="42" width="40" height="104" fill="url(#yel)"/>
 <path d="M25 42 L25 146 M39 42 L39 146" stroke="#a77f1c" stroke-width="2.5"/>
 <path d="M12 146 L52 146 L32 188 Z" fill="url(#wood)"/>
 <path d="M24 170 L40 170 L32 192 Z" fill="#2a2a2e"/>
 <path d="M18 76 L28 84 M46 76 L36 84" stroke-width="3.5" fill="none"/>
 {pie_eye(24, 92, 4, 7)}{pie_eye(40, 92, 4, 7, (-1, -1))}
 <path d="M24 114 C28 108 36 108 40 114" fill="none" stroke-width="3"/>
</g>'''
    svg("enemies/pencil.svg", 64, 200, pencil, pdefs)

    wing = f'''<g stroke="{INK}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">
 <path d="M4 18 C14 2 40 0 58 6 C50 12 52 14 58 18 C48 22 50 26 54 30 C36 34 14 30 4 18 Z" fill="#fff"/>
 <path d="M14 18 C26 14 38 14 48 16 M16 22 C28 22 38 24 46 26" fill="none" stroke-width="2"/>
</g>'''
    svg("enemies/wing.svg", 62, 36, wing)


# ---------------------------------------------------------------- Sir Reginald
def reginald():
    defs = (lin("glass", "#2f3548", "#0c0e15", False) + lin("gold", "#ecd08a", "#8e6c24") + rad("rskin", "#fff4e0", "#dcc49a")
            + lin("nibg", "#f0d58e", "#8c6a22", False))
    s = 2
    well = f'''<g transform="translate(380,664) scale({s})" stroke="{DEEP}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
 <path d="M-182 0 L-166 -230 C-160 -262 -122 -275 -92 -278 L-92 -300 L92 -300 L92 -278 C122 -275 160 -262 166 -230 L182 0 Z" fill="url(#glass)"/>
 <path d="M-142 -40 C-152 -120 -142 -200 -120 -240 L-108 -236 C-128 -196 -136 -120 -128 -40 Z" fill="#fff" opacity="0.22" stroke="none"/>
 <path d="M120 -60 C128 -120 128 -180 118 -220" fill="none" stroke="#fff" stroke-width="5" opacity="0.15"/>
 <path d="M-172 -128 L172 -128 L168 -202 L-168 -202 Z" fill="url(#gold)"/>
 <path d="M-160 -136 L160 -136 L157 -194 L-157 -194 Z" fill="none" stroke-width="2.5"/>
 <path d="M-26 -196 L26 -196 L26 -158 C26 -144 0 -134 0 -134 C0 -134 -26 -144 -26 -158 Z" fill="#7a2a22" stroke-width="3"/>
 <path d="M-14 -150 L14 -184 M14 -150 L-14 -184" stroke="#f4efe6" stroke-width="4"/>
 <rect x="-100" y="-322" width="200" height="26" rx="8" fill="url(#gold)"/>
 <path d="M-182 0 L182 0" stroke-width="6"/>
</g>'''
    svg("reginald/inkwell.svg", 760, 680, well, defs)

    wig = "".join(
        f'<circle cx="{x}" cy="{y}" r="34" fill="#f6f1e7"/><path d="M{x - 14} {y + 4} C{x - 14} {y - 14} {x + 12} {y - 14} {x + 10} {y + 4}" fill="none" stroke-width="3"/>'
        for x, y in [(-84, -42), (-98, 8), (-88, 58), (84, -42), (98, 8), (88, 58), (-44, -84), (0, -98), (44, -84)])
    head = f'''<g transform="translate(260,330) scale({s})" stroke="{DEEP}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
 <path d="M-84 104 C-96 20 -42 -96 0 -172 C42 -96 96 20 84 104 Z" fill="url(#nibg)"/>
 <path d="M0 -150 L0 -60" stroke-width="3"/><circle cx="0" cy="-56" r="7" fill="{DEEP}"/>
 {wig}
 <ellipse cx="0" cy="18" rx="68" ry="80" fill="url(#rskin)"/>
 <path d="M-50 -30 C-38 -46 -18 -46 -8 -36" fill="none" stroke-width="7"/>
 <path d="M10 -40 C22 -52 42 -50 50 -38" fill="none" stroke-width="7"/>
 {pie_eye(-26, -8, 8, 13, (-1, -1))}{pie_eye(26, -8, 8, 13, (-1, -1))}
 <path d="M-8 4 C-36 22 -74 34 -66 46 C-44 48 -22 40 -4 30 Z" fill="url(#rskin)"/>
 <path d="M-12 38 C-30 34 -50 44 -60 34 C-58 52 -30 54 -14 46 C2 54 26 54 34 38 C22 46 6 36 -12 38 Z" fill="#3a3a44"/>
 <path d="M-46 58 C-30 86 12 88 28 60 C10 70 -26 70 -46 58 Z" fill="#5a1d18"/>
 <path d="M-36 62 C-20 70 8 70 20 64 L18 70 C4 74 -20 74 -34 68 Z" fill="#fff" stroke-width="2"/>
 <circle cx="44" cy="30" r="9" fill="#e3a07a" opacity="0.5" stroke="none"/>
</g>'''
    svg("reginald/head.svg", 520, 620, head, defs)

    monocle = f'''<g stroke="{DEEP}" stroke-linecap="round">
 <path d="M58 70 C70 100 66 130 76 150" fill="none" stroke="{GOLD}" stroke-width="3" stroke-dasharray="6 4"/>
 <circle cx="40" cy="40" r="32" fill="#fff" fill-opacity="0.25" stroke="url(#gold)" stroke-width="10"/>
 <circle cx="40" cy="40" r="37" fill="none" stroke-width="3"/>
 <path d="M24 26 C30 18 40 16 48 18" fill="none" stroke="#fff" stroke-width="5" opacity="0.8"/>
</g>'''
    svg("reginald/monocle.svg", 84, 156, monocle, lin("gold", "#ecd08a", "#8e6c24"))

    glove = (f'<path d="M-18 6 C-24 -6 -14 -20 0 -18 C10 -24 22 -16 20 -4 C26 4 18 18 6 18 C-6 24 -16 18 -18 6 Z" fill="#fff"/>'
             f'<path d="M-6 -10 L-6 0 M4 -10 L4 0" stroke-width="2.5" fill="none"/>')
    quill = f'''<g transform="translate(200,372) scale({s})" stroke="{DEEP}" stroke-width="3.5" stroke-linejoin="round" stroke-linecap="round">
 <path d="M-6 -8 C-20 -60 -50 -120 -78 -170 C-50 -150 -30 -110 -18 -70 C-40 -110 -64 -140 -86 -160 C-60 -100 -40 -60 -12 -6 Z" fill="#fbf7ef"/>
 <path d="M-4 -4 L-80 -164" stroke-width="2.5" fill="none"/>
 <path d="M2 4 L10 22" stroke-width="5" stroke="{INK}"/>
 <path d="M6 14 L14 30 L8 28 Z" fill="{INK}"/>
 {glove}
</g>'''
    svg("reginald/quill_arm.svg", 250, 430, quill)

    seal = f'''<g transform="translate(70,150) scale({s})" stroke="{DEEP}" stroke-width="3.5" stroke-linejoin="round" stroke-linecap="round">
 <rect x="-8" y="-60" width="16" height="44" rx="6" fill="#7a4e2d"/>
 <ellipse cx="0" cy="-64" rx="12" ry="8" fill="#9a6a3c"/>
 <ellipse cx="0" cy="-16" rx="26" ry="10" fill="{GOLD}"/>
 <path d="M-28 -10 C-30 6 30 6 28 -10 C20 -2 -20 -2 -28 -10 Z" fill="#8f2a20"/>
 {glove}
</g>'''
    svg("reginald/seal_arm.svg", 140, 200, seal)

    stamp = f'''<g transform="translate(170,320) scale({s})" stroke="{DEEP}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round">
 <path d="M-22 -150 C-30 -150 -32 -130 -24 -120 L-14 -70 L14 -70 L24 -120 C32 -130 30 -150 22 -150 Z" fill="#8a5a34"/>
 <ellipse cx="0" cy="-150" rx="22" ry="10" fill="#a8744a"/>
 <path d="M-12 -140 C-14 -120 -10 -100 -8 -80" fill="none" stroke="#c99a6a" stroke-width="3" opacity="0.7"/>
 <path d="M-50 -70 L50 -70 L60 -40 L-60 -40 Z" fill="url(#gold)"/>
 <path d="M-78 -40 L78 -40 C84 -40 84 -10 78 -6 L-78 -6 C-84 -10 -84 -40 -78 -40 Z" fill="url(#gold)"/>
 <path d="M-76 -6 C-80 6 80 6 76 -6 Z" fill="#8f2a20"/>
 <path d="M-40 -26 L40 -26" stroke-width="3"/>
</g>'''
    svg("reginald/stamp.svg", 340, 340, stamp, lin("gold", "#ecd08a", "#8e6c24"))

    big_quill = f'''<g transform="translate(60,1080) scale({s})" stroke="{DEEP}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">
 <path d="M0 0 L10 -60 C0 -200 20 -380 60 -520 C40 -380 50 -250 44 -140 C60 -260 80 -380 110 -470 C100 -330 76 -180 30 -60 Z" fill="#fbf7ef"/>
 <path d="M6 -40 C30 -200 50 -360 64 -500" fill="none" stroke-width="2.5"/>
 <path d="M0 0 L10 -60 L18 -40 Z" fill="{INK}"/>
</g>'''
    svg("reginald/big_quill.svg", 260, 1100, big_quill)


# ---------------------------------------------------------------- Hintergrund (ohne harte Outlines)
def backgrounds():
    window = f'''<defs>{lin("sky", "#a9c4bc", "#d9e0cf")}{rad("sun", "#fff1b8", "#e8b84a", 0.45, 0.4, 0.7)}{lin("frame", "#9c7a54", "#6e5236")}</defs>
<rect x="20" y="20" width="560" height="440" rx="6" fill="url(#sky)"/>
<g fill="#f4efe2" opacity="0.85"><ellipse cx="140" cy="300" rx="90" ry="34"/><ellipse cx="200" cy="280" rx="70" ry="40"/><ellipse cx="440" cy="340" rx="110" ry="36"/></g>
<g transform="translate(330,180)">
 <g stroke="#e0a63a" stroke-width="10" stroke-linecap="round" opacity="0.7">{"".join(f'<path d="M{math.cos(a) * 100:.0f} {math.sin(a) * 100:.0f} L{math.cos(a) * 130:.0f} {math.sin(a) * 130:.0f}"/>' for a in [i * math.pi / 6 for i in range(12)])}</g>
 <circle r="84" fill="url(#sun)"/>
 <ellipse cx="-26" cy="-14" rx="9" ry="14" fill="#8a5d2a"/><ellipse cx="26" cy="-14" rx="9" ry="14" fill="#8a5d2a"/>
 <path d="M-34 24 C-14 44 14 44 34 24" fill="none" stroke="#8a5d2a" stroke-width="7" stroke-linecap="round"/>
 <circle cx="-48" cy="14" r="12" fill="#e89a6a" opacity="0.5"/><circle cx="48" cy="14" r="12" fill="#e89a6a" opacity="0.5"/>
</g>
<path d="M0 0 L600 0 L600 480 L0 480 Z M24 24 L24 456 L576 456 L576 24 Z" fill="url(#frame)" fill-rule="evenodd"/>
<rect x="290" y="20" width="20" height="440" fill="#7d5f40"/><rect x="20" y="230" width="560" height="16" fill="#7d5f40"/>'''
    svg("bg/window.svg", 600, 480, window)

    books = []
    import random
    rnd = random.Random(1930)
    cols = ["#9c6b5a", "#6f8c86", "#a8885a", "#7d6a8c", "#8a9c6a", "#b07a52"]
    for row in range(3):
        x = 30
        base = 210 + row * 210
        while x < 590:
            w = rnd.randint(22, 40)
            h = rnd.randint(120, 170)
            c = rnd.choice(cols)
            tilt = rnd.random() < 0.08
            tr = f' transform="rotate(-10 {x} {base})"' if tilt else ""
            books.append(f'<rect x="{x}" y="{base - h}" width="{w}" height="{h}" rx="3" fill="{c}"{tr}/>'
                         f'<rect x="{x + 4}" y="{base - h + 16}" width="{w - 8}" height="6" fill="#e2c98e" opacity="0.6"{tr}/>')
            x += w + rnd.randint(1, 4)
    shelf = f'''<rect x="0" y="0" width="620" height="680" rx="10" fill="#7a5a40"/>
<rect x="20" y="20" width="580" height="640" fill="#5e4430"/>
{"".join(books)}
{"".join(f'<rect x="10" y="{210 + r * 210}" width="600" height="18" fill="#8a6a4c"/>' for r in range(3))}'''
    svg("bg/bookshelf.svg", 620, 680, shelf)

    globe = f'''<defs>{rad("sea", "#bcd0c4", "#7f9c92", 0.4, 0.35, 0.8)}</defs>
<g transform="translate(130,130)">
 <circle r="110" fill="url(#sea)"/>
 <path d="M-60 -60 C-30 -80 0 -60 -10 -30 C-30 -10 -60 -20 -70 -40 Z M20 10 C50 -10 80 10 70 50 C50 70 20 60 20 30 Z M-40 40 C-20 30 0 50 -20 70 C-40 70 -50 56 -40 40 Z" fill="#c9b27a"/>
 <ellipse rx="110" ry="36" fill="none" stroke="#9c8456" stroke-width="5"/>
 <ellipse rx="40" ry="110" fill="none" stroke="#9c8456" stroke-width="5"/>
 <path d="M-118 0 A118 118 0 0 1 118 0" fill="none" stroke="#a88a52" stroke-width="10"/>
</g>'''
    svg("bg/globe.svg", 260, 260, globe)

    lamp = f'''<defs>{lin("shade", "#93a67e", "#5d7050")}{rad("glow", "#fff4c2", "#fff4c2", 0.5, 0.2, 0.6)}</defs>
<path d="M60 330 L240 330 L180 230 L120 230 Z" fill="#fff4c2" opacity="0.25"/>
<path d="M30 230 C40 150 90 120 150 120 C210 120 260 150 270 230 Z" fill="url(#shade)"/>
<ellipse cx="150" cy="230" rx="120" ry="16" fill="#4a5a3e"/>
<ellipse cx="150" cy="236" rx="34" ry="20" fill="#fff4c2"/>
<rect x="140" y="96" width="20" height="28" rx="6" fill="#8f7a52"/>'''
    svg("bg/lamp.svg", 300, 340, lamp)

    ticks = "".join(
        f'<rect x="-4" y="-122" width="8" height="{24 if i % 3 == 0 else 12}" fill="#6e5a44" transform="rotate({i * 30})"/>' for i in range(12))
    clock = f'''<defs>{rad("face", "#f6ecd2", "#d9c49a", 0.45, 0.4, 0.75)}</defs>
<g transform="translate(150,170)">
 <circle cx="-110" cy="-120" r="36" fill="#c4a066"/><circle cx="110" cy="-120" r="36" fill="#c4a066"/>
 <rect x="-12" y="-170" width="24" height="30" fill="#a88452"/>
 <circle r="140" fill="#b89260"/><circle r="122" fill="url(#face)"/>
 {ticks}
 <ellipse cx="-36" cy="-26" rx="12" ry="18" fill="#6e5a44"/><ellipse cx="36" cy="-26" rx="12" ry="18" fill="#6e5a44"/>
 <path d="M-40 40 C-16 60 16 60 40 40" fill="none" stroke="#6e5a44" stroke-width="8" stroke-linecap="round"/>
 <path d="M-100 130 L-120 170 M100 130 L120 170" stroke="#8a6a44" stroke-width="16" stroke-linecap="round"/>
</g>'''
    svg("bg/clock.svg", 300, 340, clock)


if __name__ == "__main__":
    pete(); enemies(); reginald(); backgrounds()
    print("SVGs geschrieben nach", os.path.abspath(ROOT))
