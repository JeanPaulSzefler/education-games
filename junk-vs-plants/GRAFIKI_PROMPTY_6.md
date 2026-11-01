# Polecenie do wygenerowania grafik — Junk vs Plants (część 6)

Obejmuje grafiki do Roślinnych trójek, ogrodu i wypożyczania 7. miejsca w talii: 7 plików. Do czasu ich dodania gra rysuje proste zastępstwa w kodzie (`scripts/ui_icons.gd`).

**Jak używać:**
1. Wklej do generatora cały blok poniżej. Jeśli możesz, dołącz jako wzór stylu `assets/sprites/plants/cactus.png`, a do grafik 6 i 7 także `assets/sprites/plants/nettle.png` i `assets/sprites/ui/sapling.png`.
2. Generator ma zwracać po jednej grafice. Pisz „następna”, aż dostaniesz wszystkie 7.
3. Każdą zapisz w folderze `junk-vs-plants/assets/sprites/ui/` pod podaną nazwą. Jeśli tło nie wyszło przezroczyste, wytnij je. Grafiki 1, 2, 4 i 5 przytnij do widocznej treści. Grafik 3, 6 i 7 nie przycinaj (zasady w opisach). Wszystkie zmniejsz do maks. 512 px.
4. Otwórz projekt w Godocie. Gra sama użyje plików.

```
You are creating a set of 7 game images for a children's tower-defense game in
which cute garden plants fight living trash monsters. Generate exactly ONE image
per reply, in the order below, and wait until I write "next" before the next one.
Each reply is a single image only, with no collage and no extra variants.

SHARED ART STYLE, for every image:
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole subject and each separate part
- simple cel shading: each color has one flat darker shade plus one small light
  highlight; no gradients, no textures, no realistic lighting, no blur
- bright, saturated, cheerful colors
- centered, the subject fills about 85-90% of the image, small empty margin
- square, 1024x1024 px, fully TRANSPARENT background (PNG with alpha), unless an
  image says otherwise
- no background, no ground, no drop shadow, no text, no letters, no numbers, no watermark
- must stay readable at about 48 px, so keep shapes bold and simple
- objects have NO face and NO eyes unless an image says otherwise

1. match_event.png: the icon of a "three in a row" puzzle mini-game with plants.
Three identical small rounded square garden tiles of light green grass stand side
by side in a straight horizontal row. On each tile sits the same tiny cute round
green cactus with a happy face (big round black eyes with white highlight dots,
small smile). A bright golden curved swoosh line runs under the row, and 3 small
four-pointed golden sparkles pop above it.

2. match_move.png: a "one move" token for the same puzzle. Two rounded square tiles
side by side, the left one bright green with a simple leaf on it, the right one warm
orange with a simple round flower on it. Two thick golden curved arrows form a
circle around them: the top arrow points from left to right, the bottom arrow
points from right to left, clearly showing that the two tiles swap places.

3. match_cell.png: one square cell of the puzzle board, seen directly from above.
Soft light-green short grass with a few tiny darker grass tufts, a slightly lighter
rounded inner square, and a thin darker green border along all four edges. This
image has NO transparency and NO black outline: the grass fills the entire image
edge to edge, with no margin. Keep it calm and low-contrast, because a plant
character will stand on top of it. No plants, no flowers. Do NOT crop.

4. match_pop.png: a round cartoon "pop" burst effect, shown when matched plants
disappear. Small bright green leaves, yellow four-pointed sparkles and tiny white
stars fly outward from the center in a circle, with a soft pale-yellow round flash
in the middle. The leaves have a thin black outline; the flash and the sparkles
have no outline.

5. rent_slot.png: a shiny golden KEY lying diagonally, its round bow (handle) shaped
like a bright green leaf with one central vein, a short green ribbon tied around the
key's neck, a white shine on the metal and one tiny four-pointed sparkle. It means
"unlock one extra plant slot for one game".

6. garden_stage_1.png: a YOUNG light-purple NETTLE plant, the first growth step
from a two-leaf sapling to the grown nettle (use the attached nettle.png for the
leaf shape and sapling.png for the soil). A short thin stem with four small,
jagged, light lavender-purple leaves, a tiny closed bud on top, growing from a
small lumpy mound of dark brown soil. No face yet. FRAMING: square canvas, the soil
mound touches the bottom edge and is centered; the plant with soil is about 60% of
the image height and the rest of the canvas above stays transparent. Do NOT crop.

7. garden_stage_2.png: the same light-purple NETTLE, half grown, the second growth
step. A thicker stem with six bigger jagged lavender-purple leaves spreading
outward, the bud starting to open, on the same mound of dark brown soil. A sleepy
cute face on the upper leaves: closed curved eyes and a small smile. FRAMING:
square canvas, the soil mound touches the bottom edge and is centered, exactly like
image 6; the plant with soil is about 85% of the image height. Do NOT crop.
```
