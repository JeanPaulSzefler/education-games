# Polecenia do wygenerowania grafik — Junk vs Plants (część 8)

Trzy grafiki do nowości z 2026-11-05: tło planszy walki, tło gier edukacyjnych i kosiarka. Do czasu ich dodania gra rysuje zastępstwa w kodzie (brązowy i turkusowy gradient oraz kosiarka z prostych kształtów), więc każdą grafikę można dodać osobno.

**Jak używać:** wklej do generatora wspólny styl i blok jednej grafiki. Jako wzoru stylu dołącz `assets/sprites/plants/cactus.png`. Generator ma zwracać po jednej grafice; pisz „next”, aż dostaniesz wszystkie. Zapis plików: `zadania/ZADANIE_09_GRAFIKI_8.md`.

## Wspólny styl (wklej przed każdą grafiką)

```
You are creating game images for a children's tower-defense game in which cute
garden plants fight living trash monsters. Generate exactly ONE image per reply,
in the order given, and wait until I write "next" before the next one. Each reply
is a single image only, with no collage and no extra variants.

SHARED ART STYLE:
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game
- thick, uniform, solid BLACK outline around each subject and each separate part
- simple cel shading: each color has one flat darker shade plus one small light
  highlight; no gradients on objects, no textures, no realistic lighting, no blur
- bright, saturated, cheerful colors
- no text, no letters, no numbers, no logos, no watermark
- objects have NO face and NO eyes unless an image says otherwise
```

## 1. Tło planszy walki — `bg_yard.png`

```
BACKGROUND, differs from the shared style: a full landscape scene, 1920x1080 px
(16:9), NO transparency, filling the whole image edge to edge. Outlines on
background shapes are thinner than on characters.

Scene: a cozy backyard seen from slightly above. Warm brown soil fills most of the
image, with a few faint lighter stripes of tilled earth running left to right.
Along the top edge a low wooden fence with a thin strip of green grass in front of
it. In the bottom-left and bottom-right corners a few small tufts of grass and two
tiny flowers. Nothing else.

The game draws a 10x5 grid of plant tiles, white text and round buttons on top of
it, so:
- keep the whole middle area calm, with soft low-contrast soil stripes only and no
  small busy details
- keep colors medium-dark and slightly muted (warm brown and olive green), so
  white text stays easy to read
- no house, no path, no characters
```

## 2. Tło gier edukacyjnych — `bg_leaves.png`

```
BACKGROUND, differs from the shared style: a seamless-looking decorative pattern,
1920x1080 px (16:9), NO transparency, filling the whole image edge to edge.

Scene: a deep teal-green background (medium-dark) covered with a loose, evenly
spaced pattern of large simple leaves and round water drops in slightly lighter
and slightly darker teal shades. The pattern is low contrast and tone-on-tone,
with no black outlines, so it reads as a soft wallpaper. Leave larger calm gaps
between the shapes.

The game draws white text, cards and buttons on top of it, so keep it
medium-dark overall and never use bright or white shapes.
```

## 3. Kosiarka — `lawnmower.png`

```
A cute red push lawn mower seen from the side, facing RIGHT: round red body with a
lighter red highlight stripe, two dark gray wheels, a small silver blade cover at
the front, and a dark handle going up and back at the left. Chunky, friendly
shape. No face. TRANSPARENT background, the mower fills the image.
```
