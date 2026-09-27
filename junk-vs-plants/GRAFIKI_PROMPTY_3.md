# Instrukcja dla agenta AI generującego grafiki — Junk vs Plants (część 3)

Ten plik jest instrukcją dla agenta AI, który ma wygenerować brakujące grafiki do gry **Junk vs Plants** (tower defense w stylu *Plants vs Zombies*, gra edukacyjna dla dzieci: rośliny bronią ogrodu przed śmieciami-stworami).

Wszystkie dotychczasowe grafiki w grze są już gotowe. Do zrobienia jest **6 nowych grafik**: 5 roślin i kupka śmieci. Obecnie w grze są w ich miejscu **tymczasowe placeholdery** (przebarwione kopie innych roślin i prosty szary kopczyk). Trzeba je podmienić.

## 1. Zanim zaczniesz — obejrzyj istniejące grafiki

Nowe grafiki muszą wyglądać, jakby narysował je ten sam ilustrator co resztę gry. Przed generowaniem obejrzyj te pliki, a jeśli generator na to pozwala, podaj je jako obrazy referencyjne stylu:

| Plik referencyjny | Dlaczego jest ważny |
|---|---|
| `assets/sprites/plants/frost.png` | Mrozoroślinka — **Ognioroślinka ma być jej ogniową „siostrą”**, o tej samej budowie |
| `assets/sprites/plants/gust_leaf.png` | Wichurowy — wzór dla liścia z efektem wiatru (**Liść klonu**) |
| `assets/sprites/plants/bomb_nut.png` | okrągła roślina z twarzą (dobry wzór dla **Aronii**) |
| `assets/sprites/plants/corn.png`, `cactus.png`, `nettle.png` | ogólny styl roślin-strzelców |
| `assets/sprites/enemies/bottle.png`, `can.png`, `cardboard_golem.png` | styl śmieci (wzór dla **kupki śmieci**) |

**Cechy stylu, których trzeba się trzymać (widać je na referencjach):**
- płaska grafika wektorowa w stylu **naklejki (sticker)**, postaci **chibi / kawaii**;
- **gruby, ciemny (granatowo-czarny) kontur** wokół całej postaci i jej części;
- dookoła całości **cienka biała obwódka naklejki**;
- kolory żywe i nasycone, mało cieniowania (najwyżej 1–2 płaskie odcienie na kolor, bez gradientów i realizmu);
- **każda roślina ma twarz** (oczy + buzia) wyrażającą jej charakter;
- **każda roślina stoi na małym brązowym kopczyku ziemi** u dołu obrazka;
- małe efekty (iskierki, płatki śniegu, linie wiatru) rysowane w tym samym płaskim stylu, luźno wokół postaci;
- postać wyśrodkowana, widoczna od przodu lub w 3/4.

## 2. Wymagania techniczne (dla każdego pliku)

- Format **PNG z przezroczystym tłem** (kanał alfa). Bez białego ani kolorowego tła, bez cienia pod obrazkiem, bez ramki, bez podpisu i tekstu.
- **Kwadrat, co najmniej 512 × 512 px**. Postać zajmuje ok. 85–90% obrazka, z małym marginesem dookoła.
- Czytelność w małym rozmiarze: w grze grafika jest pokazywana w rozmiarze ok. **64–72 px**. Sprawdź, czy po zmniejszeniu do 64 px nadal wiadomo, co to jest. Unikaj drobnych detali.
- Zapisz plik **dokładnie pod podaną ścieżką i nazwą** (nadpisz placeholder). Wtedy nie trzeba zmieniać kodu gry.
- Po podmianie plików otwórz projekt w Godocie (4.x), żeby zaimportował nowe obrazy. Pliki `.import` obok PNG zostaw bez zmian: Godot sam je odświeży.

## 3. Wspólny fragment promptu (dodaj na końcu KAŻDEGO promptu)

```
Flat 2D vector game sticker, chibi-kawaii style, thick dark navy-black
outline around every shape, thin white sticker border around the whole
character, bright saturated flat colors, at most one flat shade per color,
no gradients, no photorealism, no text, centered, small margin around the
subject, transparent background, square format, mobile tower-defense game
asset in the style of a cute "plants vs junk" garden game, readable at
64 px.
```

Dla roślin dodaj jeszcze: `The plant has a cute expressive face and stands on a small mound of brown soil.`

---

## 4. Grafiki do wygenerowania

### 4.1. `assets/sprites/plants/fire.png` — Ognioroślinka

**Rola w grze:** jednorazowa pułapka. Gdy śmieć na nią wejdzie, roślina znika, a wróg staje w ogniu i traci dużo życia. Jest ogniowym odpowiednikiem Mrozoroślinki.

**Najważniejsze:** ma mieć **tę samą budowę co `frost.png`** (kilka dużych spiczastych liści wyrastających kępką z kopczyka, twarz na środkowym liściu), tylko w wersji ogniowej. Gracz ma od razu widzieć, że to „siostra” Mrozoroślinki.

```
A small cartoon plant made of pointed flame-shaped leaves in warm red,
orange and yellow, the leaf tips curling upward like little tongues of
fire, same plant shape as an icy frost plant but fiery, a few tiny
sparks and embers floating around it instead of snowflakes, a cheeky
confident smiling face on the central leaf, soft warm orange glow, the
soil mound at its base has a few small glowing embers.
```

### 4.2. `assets/sprites/plants/aronia.png` — Aronia

**Rola w grze:** strzela z bliska (na 2 pola przed sobą) salwą 4 pocisków naraz, bardzo mocno.

**Wygląd (opis od autora gry):** fioletowa kulka (albo kilka kulek) z groźnym uśmiechem.

```
A cartoon chokeberry (aronia) plant character: a small cluster of three
glossy dark purple-black round berries on a short green stem with two
small green leaves, the biggest front berry has a menacing, mischievous
grin with visible teeth and narrowed determined eyes, the smaller
berries also have tiny grumpy faces, a few small purple juice droplets
flying forward to hint it shoots a burst of projectiles, standing on a
small mound of brown soil.
```

Uwaga: kolor ma być wyraźnie **fioletowy** (śliwkowy, bakłażanowy), nie czarny. Na zielonej trawie grafika musi być dobrze widoczna.

### 4.3. `assets/sprites/plants/maple_leaf.png` — Liść klonu

**Rola w grze:** jednorazowy. Wieje silnym wiatrem i odpycha wszystkich wrogów w rzędzie o 4 pola do tyłu, po czym znika.

**Musi się wyraźnie różnić od Wichurowego (`gust_leaf.png`):** Wichurowy to zielona kępka liści. Liść klonu to **jeden duży, charakterystyczny liść klonu** w jesiennych kolorach.

```
A single big cartoon maple leaf character with the classic five-pointed
maple leaf shape, autumn colors (bright red-orange with golden-yellow
veins), puffed cheeks as if blowing a strong gust of wind to the right,
determined eyes, several curved white-blue wind lines streaming out to
the right in front of its mouth, a couple of tiny red maple seeds
(helicopter samaras) spinning in the wind, the leaf stem planted in a
small mound of brown soil.
```

### 4.4. `assets/sprites/plants/rose.png` — Róża

**Rola w grze:** strzelec, który trafia wrogów **we wszystkich rzędach** (jej kolce same lecą do celu). Kosztowna, „elegancka” roślina.

```
A cartoon red rose plant character: one large open red rose blossom as
the head with a confident, proud, slightly smug face in the center of
the petals, a green stem with two leaves and a few sharp visible
thorns, one leaf raised like an arm pointing forward as if aiming,
two small pink thorn-darts flying out diagonally (one up-right, one
down-right) to hint it can shoot in any direction, standing on a small
mound of brown soil.
```

### 4.5. `assets/sprites/plants/vines.png` — Pnącza

**Rola w grze:** można je posadzić tylko na kupce śmieci. Od razu ją oplatają i niszczą, po czym znikają. Kosztują 0 kropli wody.

```
A cartoon cluster of energetic green climbing vines: several thick
curly green tendrils twisting upward and outward like grabbing arms,
small heart-shaped leaves along them, one main vine tip curled like a
fist or a lasso ready to wrap around something, a friendly but
determined face on the biggest leaf at the center, tendrils sprouting
from a small mound of brown soil.
```

Uwaga: pnącza muszą wyglądać na „aktywne” (gotowe do chwytania), a nie jak zwykły krzaczek. W grze pojawiają się na chwilę na kupce śmieci i ją oplatają.

### 4.6. `assets/sprites/ui/junk_pile.png` — Kupka śmieci

**Rola w grze:** pojawia się na polu planszy (na trawie). Co falę wychodzą z niej śmieci-stwory. Rośliny mogą ją zestrzelić, a Pnącza niszczą ją od razu.

**To NIE jest roślina ani postać wroga.** Nie ma twarzy i nie ma kopczyka ziemi. To kopiec śmieci z ciemnym „wejściem”, z którego coś wychodzi.

```
A small cartoon heap of mixed garbage sitting on the ground: a crumpled
plastic bottle, a dented soda can, a flattened cardboard piece, a torn
plastic bag and a banana peel piled into a rounded mound, a dark
opening/hole at the front of the heap with two small glowing yellow
eyes peeking out from the darkness (hinting that junk monsters crawl
out of it), a few small flies or stink lines above it, grimy grey-brown
base colors with small bright accents on the trash items, flat bottom
edge so it sits naturally on a grass tile, no soil mound, no face on the
heap itself.
```

Uwaga: kupka ma być **szersza niż wyższa** (kopiec), ok. 90% szerokości obrazka i ok. 60–70% wysokości, przy dolnej krawędzi. Wszystkie śmieci w tym samym stylu co przeciwnicy (`bottle.png`, `can.png`).

---

## 5. Kontrola jakości (sprawdź przed oddaniem)

Dla każdej z 6 grafik:

1. [ ] Przezroczyste tło (bez białego prostokąta).
2. [ ] Gruby ciemny kontur i biała obwódka naklejki, jak w `frost.png`.
3. [ ] Roślina ma twarz i kopczyk ziemi. Kupka śmieci nie ma kopczyka.
4. [ ] Po zmniejszeniu do 64 px wiadomo, co to jest, a sylwetka różni się od pozostałych roślin w grze.
5. [ ] Ognioroślinka wyraźnie przypomina Mrozoroślinkę, a Liść klonu **nie** przypomina Wichurowego.
6. [ ] Na obrazku nie ma tekstu, podpisu ani znaku wodnego.
7. [ ] Plik zapisany pod dokładnie tą samą ścieżką i nazwą (`fire.png`, `aronia.png`, `maple_leaf.png`, `rose.png`, `vines.png`, `junk_pile.png`).

Jeśli któraś grafika wyszła z nieprzezroczystym tłem, usuń tło (np. narzędziem do wycinania tła) przed zapisaniem. W grze nie może być widać prostokąta wokół postaci.
