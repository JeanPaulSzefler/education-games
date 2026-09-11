# Prompty do generatora grafik — Junk vs Plants

Gotowe opisy do wklejenia w dowolne narzędzie generujące obrazy (Claude z generowaniem obrazów, Midjourney, Leonardo, Recraft, DALL-E itp.). Po wygenerowaniu podmień odpowiedni plik w `assets/sprites/...` (można zostawić `.svg` jeśli narzędzie eksportuje wektor, albo zapisać jako `.png` — wtedy trzeba zaktualizować ścieżkę w `plant_data.gd` / `main.gd`, dam znać jak to zrobić).

## Styl wspólny dla wszystkich grafik (dodaj do każdego promptu)

```
Flat 2D vector game icon, simple and colorful, thick black outline,
clean minimalist shapes, no shading or gradients, no photorealism,
centered composition with small margin around the subject,
front-facing or 3/4 view, transparent background, square format,
mobile game asset style, cheerful and readable at small size
```

Wspólna paleta: ciepłe, nasycone kolory (zieleń, brąz, żółty, czerwony), spójne z klimatem "ogród vs śmieci".

---

## Rośliny (`assets/sprites/plants/`)

### 1. corn.svg — Kukurydza (strzelec)
```
A cheerful cartoon corn cob character, upright like a plant turret,
green husk leaves opened like arms, bright yellow kernels showing,
small determined smiling face on the cob, tiny leaf "hands" as if
ready to shoot, standing on a small mound of soil.
```

### 2. cactus.svg — Kaktus (generator wody)
```
A round friendly cartoon cactus in a small clay pot, plump green body
with visible spines drawn as small simple marks (not sharp/scary),
a single sparkling water droplet floating just above its head,
happy simple face, slightly glossy green color.
```

### 3. banana_leaf.svg — Liść Bananowca (blokada/tarcza)
```
A single large, broad banana leaf standing upright like a shield,
thick green leaf with visible central rib and vein lines, sturdy and
tough-looking, rounded tip, small stem base rooted in soil, no face
needed (or a small calm face if it fits the plant family style).
```

---

## Przeciwnicy (`assets/sprites/enemies/`)

### 4. bottle.svg — Butelka PET
```
A cartoon monster made from a crumpled plastic PET bottle, walking on
two short bent legs, angry or mischievous cartoon eyes on the bottle
label area, slightly dented/crinkled plastic texture drawn simply,
translucent blue-ish color, small plastic cap as a "hat".
```

### 5. can.svg — Puszka
```
A cartoon monster made from a dented aluminum drink can, short stubby
legs, silver/metallic body with a colorful label patch, mischievous
grinning face, small dents drawn as simple lines, tilted slightly as
if scurrying forward quickly.
```

### 6. cardboard_golem.svg — Kartonowy Golem
```
A tall bulky golem built from stacked cardboard boxes and packing tape,
brown corrugated cardboard texture drawn simply, thick blocky arms and
legs made of boxes, tape strips as "muscles" or joints, slow and heavy
looking, simple tough/grumpy face on the top box.
```

---

## Interfejs / efekty (`assets/sprites/ui/`)

### 7. thorn.svg — Pocisk (kolec kukurydzy)
```
A small simple green plant thorn or seed-shaped projectile, pointed
oval shape, subtle motion lines behind it suggesting it was just
launched, bright green with a darker green outline.
```

### 8. water_drop.svg — Kropla wody
```
A single glossy cartoon water droplet, classic teardrop shape, bright
blue with a small white highlight/sparkle for shine, simple and round,
floating/bouncy feeling.
```

### 9. grass_tile.svg — Kafelek trawy (tło planszy)
```
A simple flat seamless-tileable square patch of grass, textured with
small simple tufts/blades of grass in two tones of green, subtle random
pattern so tiles don't look too repetitive when placed side by side,
no border, no outline needed since it's a background tile.
```

### 10. locked_slot.svg — Zablokowany slot (ścieżka sukcesów)
```
A simple flat icon of a closed padlock inside a rounded square badge,
gray/muted colors (desaturated, since it represents something locked),
thick outline matching the game's icon style, simple keyhole shape,
no bright colors — should look clearly "disabled" compared to other icons.
```

---

## Ikona aplikacji (`icon.svg`)

### 11. icon.svg — Ikona gry
```
App icon for a tower-defense game called "Junk vs Plants": a happy
green plant character (like the corn or a generic sprout) standing
bravely in front of a pile of cute cartoon trash monsters, rounded
square app-icon background in a fresh green color, bold simple shapes
that read clearly at very small sizes (like a phone home screen icon),
centered composition, thick outlines, flat colors, no text needed
(or optionally a small "JvP" monogram if the tool insists on text).
```

---

## Uwagi

- Jeśli narzędzie generuje PNG z tłem zamiast przezroczystego — dobrze, wystarczy przyciąć/usunąć tło (większość generatorów AI ma opcję "remove background" albo da się to zrobić w dowolnym prostym edytorze).
- Zachowaj proporcje 1:1 (kwadrat) dla wszystkich poza `grass_tile.svg`, który też jest kwadratowy, ale ma się dobrze płytkować.
- Jeśli wygenerujesz grafiki w innym formacie niż SVG (np. PNG), daj znać — podmienię rozszerzenia plików w kodzie (`plant_data.gd`, `main.gd`) tak, żeby wskazywały na nowe pliki.
