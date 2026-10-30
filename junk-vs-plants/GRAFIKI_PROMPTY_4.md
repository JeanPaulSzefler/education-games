# Prompty do generatora grafik — Junk vs Plants (część 4)

**Jak używać:** poniższe prompty są samowystarczalne — model graficzny nie musi mieć dostępu do repozytorium ani do innych grafik z gry. Styl gry jest opisany słowami w każdym prompcie.

- Wklejaj do generatora **jeden prompt na raz** (cały blok kodu z sekcji danej grafiki — styl jest już w środku).
- Jeśli generator pozwala dołączyć obrazek referencyjny, **możesz** dołączyć któryś z gotowych sprite'ów gry (np. `assets/sprites/ui/fertilizer.png`) — to poprawi zgodność stylu, ale nie jest konieczne.
- Najlepiej generować obie grafiki w **jednej rozmowie** i po pierwszej udanej dopisać: *"Keep exactly the same art style as the previous image."*
- Gotowy plik zapisz pod nazwą i w folderze podanym przy prompcie. Jeśli tło nie wyszło przezroczyste — wytnij je przed zapisaniem. Przytnij grafikę do widocznej treści i zmniejsz do maks. 512 px, jak pozostałe.
- Gra sama użyje pliku, gdy tylko pojawi się on w tym folderze i projekt zostanie otwarty w Godocie. Do tego czasu pokazuje prosty rysunek z kodu.

---

## 1. Skrzynia z nagrodami → `assets/sprites/ui/chest.png`

```
Create a single game icon: a cute cartoon TREASURE CHEST for a children's
tower-defense game where garden plants fight living trash monsters.

SUBJECT: a small, chunky, closed wooden treasure chest seen from the front,
slightly from above. It has a rounded barrel-shaped lid and a boxy base, made
of warm reddish-brown wooden planks with visible plank lines. Two wide golden
metal bands run vertically over the lid and the base, and a golden band runs
along the rim where the lid meets the base. In the center is a big, simple
golden padlock plate with a small leaf-shaped keyhole, which ties the chest to
the garden theme. Small green leaves and a short curling vine grow around one
bottom corner. A soft golden glow leaks out through the gap under the lid, and
2-3 tiny four-pointed sparkles float near the top. The chest has no face and
no eyes: it is an object, not a character.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole object and around every
  separate part (lid, base, each metal band, the lock, each leaf, each sparkle)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated, cheerful colors
- composition: centered, the chest fills about 85-90% of the image, small
  empty margin around it

TECHNICAL: square image, 1024x1024 px, fully TRANSPARENT background (PNG with
alpha). No background color, no ground, no drop shadow, no text, no letters,
no numbers, no watermark.
```

## 2. Roślimoneta → `assets/sprites/ui/plant_coin.png`

```
Create a single game icon: a cute cartoon GOLD COIN WITH A LEAF for a
children's tower-defense game where garden plants fight living trash monsters.

SUBJECT: one thick, round gold coin seen from the front, with a raised rim
around its edge. In the center of the coin is a simple, bold, bright green
leaf with one central vein, slightly tilted. A small white shine shape sits on
the upper left of the rim, and one tiny four-pointed sparkle floats at the
upper right. The coin has no face and no eyes: it is an object, not a character.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole coin and around every
  separate part (rim, leaf, sparkle)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated, cheerful colors
- must stay readable at very small sizes (about 40 px), so keep it simple
- composition: centered, the coin fills about 85-90% of the image, small empty
  margin around it

TECHNICAL: square image, 1024x1024 px, fully TRANSPARENT background (PNG with
alpha). No background color, no ground, no drop shadow, no text, no letters,
no numbers, no watermark.
```

## 3. Megakaktus → `assets/sprites/plants/mega_cactus.png`

W repo jest tymczasowo przebarwiony Kaktus; ten plik trzeba nadpisać. Jeśli generator pozwala, dołącz `assets/sprites/plants/cactus.png` jako referencję.

```
Create a single game sprite: a cute cartoon GIANT CACTUS for a children's
tower-defense game where garden plants fight living trash monsters.

SUBJECT: a big, proud, chubby round barrel cactus, clearly larger and stronger
looking than an ordinary little cactus. Deep emerald green body with vertical
ribs, and short pale-yellow spines drawn as small simple triangles. Two short
stubby side arms stick out to the left and right. On top sit two small pink
flower buds. It has a cute confident face in the middle: big round black eyes
with small white highlights, and a wide happy smile. Two plump blue water drops
float just above its arms, one on each side, showing that it makes two drops at
once. It stands on a small lumpy mound of dark brown soil.

ART STYLE (important, match exactly):
- flat 2D cartoon sticker art, chibi-kawaii, like a modern mobile game icon
- thick, uniform, solid BLACK outline around the whole character and around
  every separate part (body, each arm, each flower bud, each drop, soil mound)
- simple cel shading: each color has only one flat darker shade on one side
  plus one small light highlight shape; no gradients, no textures, no
  realistic lighting, no blur
- bright, saturated, cheerful colors
- eyes drawn as simple black shapes with a small white highlight dot
- composition: centered, front view, the character fills about 85-90% of the
  image, small empty margin around it

TECHNICAL: square image, 1024x1024 px, fully TRANSPARENT background (PNG with
alpha). No background color, no ground, no drop shadow, no text, no letters,
no numbers, no watermark.
```
