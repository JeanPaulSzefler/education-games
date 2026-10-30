# Polecenie do wygenerowania grafik — Junk vs Plants (część 5)

Obejmuje wszystkie grafiki, które w grze są tymczasowe albo rysowane w kodzie: 12 plików. Ikony pauzy i „graj” są zwykłymi symbolami i nie wymagają nowej wersji.

**Jak używać:**
1. Wklej do generatora cały blok poniżej. Jeśli możesz, dołącz `assets/sprites/plants/cactus.png` jako wzór stylu.
2. Generator ma zwracać po jednej grafice. Pisz „następna”, aż dostaniesz wszystkie 12.
3. Każdą zapisz w folderze `junk-vs-plants/assets/sprites/` pod podaną nazwą, a `plants/mega_cactus.png` nadpisz. Jeśli tło nie wyszło przezroczyste, wytnij je. Przytnij do widocznej treści (poza kafelkami 11 i 12) i zmniejsz do maks. 512 px.
4. Otwórz projekt w Godocie. Gra sama użyje plików.

```
You are creating a set of 12 game images for a children's tower-defense game in
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

1. plants/mega_cactus.png: a GIANT CACTUS character. A big, proud, chubby round
barrel cactus, clearly stronger than a small cactus. Deep emerald green body with
vertical ribs and short pale-yellow triangular spines, two stubby side arms, two
small pink flower buds on top. Cute confident face: big round black eyes with
white highlight dots and a wide happy smile. Two plump blue water drops float
above its arms, one on each side. It stands on a small lumpy mound of dark brown soil.

2. ui/chest.png: a closed wooden TREASURE CHEST, front view from slightly above.
Rounded lid, boxy base, warm reddish-brown planks. Two wide golden vertical bands
and a golden rim, a big golden lock plate with a leaf-shaped keyhole, small green
leaves and a short vine at one bottom corner, a soft golden glow from the gap
under the lid, and 2-3 tiny four-pointed sparkles.

3. ui/plant_coin.png: one thick round GOLD COIN, front view, with a raised rim and
a bold bright green leaf with one central vein in the middle. A small white shine
on the upper left of the rim, and one tiny four-pointed sparkle at the upper right.

4. ui/ruby.png: one large faceted RUBY gem, front view, in a classic cut shape:
flat top, wide shoulders, pointed bottom. Crimson red with clear flat facets in
lighter pink and darker wine red, a white shine on the upper left, and one tiny
four-pointed sparkle.

5. ui/sapling.png: a small young SAPLING. A short green stem with two bright rounded
leaves spreading left and right, a tiny third leaf starting between them, growing
from a small mound of dark brown soil. Fresh and hopeful.

6. ui/bee.png: a cute round chubby BUMBLEBEE character in side view, flying to the
left. Yellow body with bold black stripes, two small pale-blue translucent-looking
wings drawn with flat color, tiny antennae, a very small rounded stinger. Cute face:
one big round black eye with a white highlight dot and a small smile.

7. ui/event_star.png: one large, rounded, five-pointed golden STAR with soft puffy
points, a flat orange shade on one side and a pale yellow highlight, with 3 tiny
sparkles and a small green leaf tucked behind one point.

8. ui/padlock.png: a closed chunky golden PADLOCK, front view. A rounded dark gray
metal shackle on top, a wide golden body, and a simple dark leaf-shaped keyhole in
the center.

9. ui/book.png: an open chunky STORY BOOK seen from the front and slightly above.
A brown leather cover, two curved cream pages with a few simple gray wavy lines
standing for writing (no real letters), and a green leaf bookmark at the center.

10. ui/shop_basket.png: a woven wicker SHOPPING BASKET, front view. Warm golden-brown
weave, a tall curved handle, filled at the top with a few green leaves and a red
ruby peeking out.

11. ui/soil_plot.png: a top-down square GARDEN BED of soft dark brown soil, seen
directly from above, with neat raked furrows, a few small pebbles and a low border
of lighter wood planks along all four edges. This image has NO transparency: the
bed fills the entire image edge to edge, with no margin. No plants.

12. ui/fog.png: a seamless square tile of soft pale-gray and white cartoon FOG, drawn
as flat overlapping rounded cloud shapes with NO black outline. It must tile
seamlessly on all four sides, fill the whole image edge to edge, and be about 85%
opaque, so the ground is only faintly visible through it.
```
