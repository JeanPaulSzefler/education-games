# Prompty do generatora grafik — Junk vs Plants (część 3)

**Jak używać:** poniższe prompty są samowystarczalne — model graficzny nie musi mieć dostępu do repozytorium ani do innych grafik z gry. Styl gry jest opisany słowami w każdym prompcie.

- Wklejaj do generatora **jeden prompt na raz** (cały blok kodu z sekcji danej grafiki — styl jest już w środku).
- Jeśli generator pozwala dołączyć obrazek referencyjny, **możesz** dołączyć któryś z gotowych sprite'ów gry (np. `assets/sprites/plants/frost.png` przy Ognioroślince) — to poprawi zgodność stylu, ale nie jest konieczne.
- Najlepiej generować wszystkie 6 grafik w **jednej rozmowie** z tym samym modelem i po pierwszej udanej dopisać: *"Keep exactly the same art style as the previous image."*
- Gotowy plik zapisz pod nazwą podaną przy prompcie, nadpisując placeholder w repo (ścieżka też podana). Jeśli tło nie wyszło przezroczyste — wytnij je przed zapisaniem.

---

## 1. Ognioroślinka → `assets/sprites/plants/fire.png`

```
Create a single game sprite: a cute cartoon FIRE PLANT for a children's
tower-defense game where garden plants fight living trash monsters.

SUBJECT: a small plant made of 5 large pointed leaves growing in a tight
tuft from one short stem: one tall central leaf pointing straight up, two
medium leaves angled up-left and up-right, two smaller leaves spreading
out low to the left and right. The leaves are shaped like flames: wavy
edges and tips that curl upward like tongues of fire. Colors: bright red
at the outer edges, orange in the middle, golden yellow near the veins
and the base. The central leaf has a cute face: closed happy curved eyes
(like "^ ^") and a small smiling open mouth, a cheeky, warm expression.
Around the plant float 4-5 tiny orange sparks and ember dots. It stands
on a small lumpy mound of dark brown soil with a few tiny glowing orange
embers in the soil.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole character and around
  every separate part (each leaf, the soil mound, each spark)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated, cheerful colors
- eyes drawn as simple black shapes with a small white highlight dot
- composition: centered, front view, the character fills about 85-90% of
  the image, small empty margin around it
- TRANSPARENT background (PNG with alpha). No background color, no
  shadow on the ground, no frame, no text, no watermark
- square image, at least 512x512 px
- must stay clearly readable when shrunk to 64x64 px: bold simple shapes,
  no tiny details
```

## 2. Aronia → `assets/sprites/plants/aronia.png`

```
Create a single game sprite: a cute but menacing cartoon CHOKEBERRY
(ARONIA) PLANT for a children's tower-defense game where garden plants
fight living trash monsters. In the game it shoots a burst of 4 berry
projectiles at close range.

SUBJECT: a cluster of three round, glossy berries on one short green
stem with two small pointed green leaves at the base. The berries are
deep, clearly PURPLE (plum / eggplant purple, not black), each with a
small shiny white highlight. The biggest berry is in front and in the
middle; it has a menacing, mischievous face: narrowed determined eyes
with angled eyebrows and a wide toothy grin (white teeth). The two
smaller berries behind it, one on each side, have small grumpy faces.
Two or three small purple juice droplets fly out to the right, hinting
that it shoots. The stem stands on a small lumpy mound of dark brown
soil with a few small pebbles.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole character and around
  every separate part (each berry, each leaf, the soil mound, each droplet)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated, cheerful colors
- eyes drawn as simple black shapes with a small white highlight dot
- composition: centered, front view, the character fills about 85-90% of
  the image, small empty margin around it
- TRANSPARENT background (PNG with alpha). No background color, no
  shadow on the ground, no frame, no text, no watermark
- square image, at least 512x512 px
- must stay clearly readable when shrunk to 64x64 px: bold simple shapes,
  no tiny details
```

## 3. Liść klonu → `assets/sprites/plants/maple_leaf.png`

```
Create a single game sprite: a cute cartoon MAPLE LEAF character for a
children's tower-defense game where garden plants fight living trash
monsters. In the game it blows a powerful gust of wind that pushes all
enemies back.

SUBJECT: ONE big maple leaf with the classic, clearly recognizable
five-pointed maple leaf shape (like the leaf on the Canadian flag, but
cartoony and rounded), standing upright on its short stem. Autumn
colors: bright red-orange leaf with golden-yellow veins. In the middle
of the leaf is a face: puffed-out round cheeks and pursed lips, as if
blowing hard to the right, with determined eyes and angled eyebrows.
From its mouth, 3-4 curved white-and-light-blue wind lines stream out
to the right, and 1-2 small spinning maple seeds (winged "helicopter"
seeds) fly in the wind. The stem is planted in a small lumpy mound of
dark brown soil with a few small pebbles.
It must NOT look like a green bush or a cluster of green leaves - it is
one single big red-orange maple leaf.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole character and around
  every separate part (the leaf, the soil mound, each wind line, each seed)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated, cheerful colors
- eyes drawn as simple black shapes with a small white highlight dot
- composition: centered, front view, the character fills about 85-90% of
  the image, small empty margin around it
- TRANSPARENT background (PNG with alpha). No background color, no
  shadow on the ground, no frame, no text, no watermark
- square image, at least 512x512 px
- must stay clearly readable when shrunk to 64x64 px: bold simple shapes,
  no tiny details
```

## 4. Róża → `assets/sprites/plants/rose.png`

```
Create a single game sprite: a cute cartoon ROSE PLANT character for a
children's tower-defense game where garden plants fight living trash
monsters. In the game it shoots thorns that fly to enemies in any
direction.

SUBJECT: one large, open, bright red rose blossom as the head, with
rounded layered petals. In the center of the blossom is a face: a
confident, proud, slightly smug expression (half-closed self-assured
eyes, one eyebrow raised, small smirk). Below it a green stem with a
few clearly visible sharp thorns and two green leaves; one leaf is
raised forward like an arm pointing at a target. Two small pink thorn
darts fly out from it: one diagonally up-right, one diagonally
down-right. The stem stands on a small lumpy mound of dark brown soil
with a few small pebbles.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole character and around
  every separate part (the blossom, stem, each leaf, the soil mound, each dart)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated, cheerful colors
- eyes drawn as simple black shapes with a small white highlight dot
- composition: centered, front view, the character fills about 85-90% of
  the image, small empty margin around it
- TRANSPARENT background (PNG with alpha). No background color, no
  shadow on the ground, no frame, no text, no watermark
- square image, at least 512x512 px
- must stay clearly readable when shrunk to 64x64 px: bold simple shapes,
  no tiny details
```

## 5. Pnącza → `assets/sprites/plants/vines.png`

```
Create a single game sprite: cute cartoon CLIMBING VINES character for a
children's tower-defense game where garden plants fight living trash
monsters. In the game the vines grab and wrap around a heap of garbage
and destroy it.

SUBJECT: a lively cluster of 4-5 thick, bright green curly vine
tendrils growing out of one spot and twisting upward and outward like
grabbing arms. Small heart-shaped green leaves grow along the tendrils.
The tip of the biggest tendril is curled into a loop like a lasso, ready
to wrap around something. On the biggest leaf in the center there is a
friendly but determined face (confident eyes, eager open smile). The
vines look energetic and active, NOT like a calm bush. They grow from a
small lumpy mound of dark brown soil with a few small pebbles.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole character and around
  every separate part (each tendril, each leaf, the soil mound)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated, cheerful colors
- eyes drawn as simple black shapes with a small white highlight dot
- composition: centered, front view, the character fills about 85-90% of
  the image, small empty margin around it
- TRANSPARENT background (PNG with alpha). No background color, no
  shadow on the ground, no frame, no text, no watermark
- square image, at least 512x512 px
- must stay clearly readable when shrunk to 64x64 px: bold simple shapes,
  no tiny details
```

## 6. Kupka śmieci → `assets/sprites/ui/junk_pile.png`

```
Create a single game sprite: a cartoon HEAP OF GARBAGE lying on the
ground, for a children's tower-defense game where garden plants fight
living trash monsters. In the game, trash monsters crawl out of this
heap. It is an object, not a character: the heap itself has NO face.

SUBJECT: a low, rounded mound of mixed trash, wider than it is tall
(about 90% of the image width, about 60-70% of its height, resting on
the bottom edge of the image with a flat bottom so it sits naturally on
a patch of grass). Recognizable items piled together: a crumpled
light-blue plastic bottle with a dark blue cap, a dented grey soda can
with a red-and-yellow label, a flattened brown cardboard piece, a torn
white plastic bag and a yellow banana peel. At the front of the heap is
a dark hole/opening, and from the darkness two small glowing yellow
eyes peek out (something is hiding inside). Above the heap float 2-3
wavy green stink lines and one or two tiny cartoon flies. Base colors
of the heap are grimy grey-brown, with the bright colors of the trash
items as accents. No soil mound, no plants, no grass.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole heap and around
  every separate item (each piece of trash, the stink lines, the flies)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated colors on the trash items, playful not disgusting
- composition: centered, front view, small empty margin around it
- TRANSPARENT background (PNG with alpha). No background color, no
  shadow on the ground, no frame, no text, no watermark
- square image, at least 512x512 px
- must stay clearly readable when shrunk to 64x64 px: bold simple shapes,
  no tiny details
```

---

## Kontrola przed zapisaniem (dla każdej grafiki)

1. [ ] Przezroczyste tło — bez białego ani kolorowego prostokąta.
2. [ ] Gruby czarny kontur wokół całości i każdej części, płaskie kolory bez gradientów.
3. [ ] Roślina ma twarz i kopczyk ziemi; kupka śmieci — bez twarzy (tylko oczka w dziurze) i bez kopczyka.
4. [ ] Po zmniejszeniu do 64 px wciąż wiadomo, co to jest.
5. [ ] Aronia jest fioletowa (nie czarna); Liść klonu to jeden czerwono-pomarańczowy liść (nie zielona kępka).
6. [ ] Brak tekstu, podpisu, znaku wodnego.
7. [ ] Nazwa pliku dokładnie jak w nagłówku sekcji (nadpisuje placeholder).
