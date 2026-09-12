# Prompty do generatora grafik — Junk vs Plants (część 2: pozostałe placeholdery)

Pierwsza partia grafik (kukurydza, kaktus, liść bananowca, przeciwnicy podstawowi, krople, trawa itd.) została już podmieniona na wygenerowane pliki PNG. Poniżej prompty dla grafik, które **wciąż są prostymi SVG-placeholderami** narysowanymi na szybko — do podmiany w tej samej kolejności co poprzednio.

Po wygenerowaniu podmień plik w `assets/sprites/...`. Jeśli zapiszesz jako `.png` zamiast `.svg`, trzeba zaktualizować ścieżkę tekstury w `plant_data.gd` / `boss_data.gd` / `main.gd` — daj znać, to zrobię.

## Styl wspólny dla wszystkich grafik (dodaj do każdego promptu)

```
Flat 2D vector game icon, simple and colorful, thick black outline,
clean minimalist shapes, no shading or gradients, no photorealism,
centered composition with small margin around the subject,
front-facing or 3/4 view, transparent background, square format,
mobile game asset style, cheerful and readable at small size
```

Wspólna paleta: ciepłe, nasycone kolory (zieleń, brąz, żółty, czerwony), spójne z klimatem "ogród vs śmieci". Bossowie mogą być wizualnie bardziej "groźni/duzi" niż zwykli przeciwnicy, ale nadal w tym samym płaskim, kreskówkowym stylu — bez realizmu i horroru.

---

## Rośliny (`assets/sprites/plants/`)

### 1. nettle.svg — Pokrzywa (strzelec, przebija cały rząd)
```
A spiky cartoon nettle plant character, upright stem with a few
serrated dark-green leaves, small angry-cute face in the center leaf,
tiny white dots scattered on the leaves suggesting stinging hairs,
a subtle motion-line or spark near the top hinting it shoots piercing
darts, standing on a small mound of soil.
```

### 2. broccoli.svg — Bitny Brokul (melee, kontratakuje gryzącego)
```
A stocky cartoon broccoli character shaped like a small boxer, thick
tree-trunk stalk as legs, round bumpy green floret head, two small
leaf "fists" raised in a fighting stance, determined tough facial
expression, maybe a tiny sweatband or scar for character, standing
on a small mound of soil.
```

### 3. frost.svg — Mrozoroślinka (jednorazowa, spowalnia rząd)
```
A small delicate cartoon plant made of pale icy-blue leaves with a
faint frosty sparkle/snowflake pattern on them, tiny icicles hanging
from the leaf tips, calm sleepy-cute face, soft glowing light-blue
aura around it suggesting a chill effect, standing on a small mound
of soil dusted with light frost.
```

### 4. bomb_nut.svg — Bumorzech (jednorazowa, wybucha po lontku)
```
A round cartoon nut/seed character shaped like a small bomb, dark
brown spherical shell with a lit fuse sticking out the top with a
small spark/flame, nervous or mischievous grinning face on the shell,
thin green leaf sprout at the base, standing on a small mound of soil.
```

### 5. gust_leaf.svg — Wichurowy (jednorazowa, rani i odrzuca cały rząd)
```
A cartoon plant character made of a cluster of light green leaves
caught mid-swirl as if generating a gust of wind, a small tornado/
swirl symbol or curved wind-lines drawn around it, leaves flowing to
one side, excited energetic face, standing on a small mound of soil.
```

---

## Nowy przeciwnik (`assets/sprites/enemies/`)

### 6. sponge.svg — Brudna Gąbka (kradnie krople wody)
```
A cartoon dirty kitchen sponge creature, rectangular-rounded yellow-
brown body covered in visible dark grimy pores/holes, a few drips of
dirty grey-green liquid oozing from it, sly or greedy facial
expression (narrow eyes, small sneaky grin) as if eyeing something
to steal, slightly hunched posture like it's reaching forward,
subtle motion lines suggesting it is slowly creeping.
```

---

## Bossowie (`assets/sprites/enemies/`, jeden na koniec każdego poziomu)

Bossowie powinni być narysowani jako wyraźnie większe, groźniejsze wersje zwykłych śmieci-stworów — dodaj do promptu: *"larger and more imposing than regular enemies, slightly more detailed, but still flat vector cartoon style, not realistic or scary-horror"*.

### 7. boss_can.svg — Puszkowy Tyran (poziom 1, mocniejsze gryzienie)
```
A large intimidating cartoon soda/tin can monster, dented and rusty
metal body, sharp jagged torn lid forming a mouth full of crooked
metal "teeth", angry glowing eyes, small crushed-metal spikes along
its top edge like a crown, sturdy stance suggesting it hits hard.
```

### 8. boss_bag.svg — Foliowy Duch (poziom 2, przeskakuje przez rośliny)
```
A large ghostly cartoon plastic bag monster, semi-transparent thin
plastic material with wrinkles and creases, flowing tattered edges
like a ghost's tail, simple glowing eyes visible through the plastic,
floating slightly above the ground with a faint motion blur/afterimage
suggesting it can phase and jump.
```

### 9. boss_compactor.svg — Kompaktor Śmieci (poziom 3, rani cały rząd)
```
A large blocky cartoon trash-compactor monster, boxy metal body made
of compressed mixed junk (visible flattened cans, cardboard, wrappers
pressed into its chest), thick heavy metal arms/pistons, small angry
eyes on a control-panel-like face, wide stable stance suggesting it
crushes everything in front of it.
```

### 10. boss_magnet.svg — Magnetyczny Złomiarz (poziom 4, wyłącza rośliny strzelające)
```
A large cartoon scrap-metal monster built around a big red-and-silver
horseshoe magnet as its head/core, small bits of metal junk (bolts,
nuts, wire) stuck to its magnetic body, sparking electric arcs near
the magnet tips, mischievous confident expression, sturdy junk-metal
body and limbs.
```

### 11. boss_toxic.svg — Toksyczny Kolos (poziom 5, zatruwa rośliny)
```
A large hulking cartoon monster made of stacked toxic waste barrels
and sludge, glowing sickly green-yellow toxic goo dripping from seams,
a simple biohazard-like marking on its chest, small bubbling toxic
puddle at its feet, menacing but still flat-cartoon (not gory) style.
```

---

## Elementy UI (`assets/sprites/ui/`)

### 12. fertilizer.svg — Nawóz (zbierany po pokonaniu rośliny, wzmacnia inną roślinę)
```
A simple cartoon icon of a golden/amber fertilizer granule pile or a
small glowing sack of plant fertilizer, warm golden-brown color with
a subtle sparkle or glow, maybe a small green leaf sprout emerging
from the top to signal "growth boost", simple and very readable at
small size.
```

### 13. boost_ring.svg — Pierścień wzmocnienia (efekt wizualny na roślinie pod wpływem nawozu)
```
A simple glowing golden ring / halo effect icon, thin circular ring
made of light with small sparkle particles around it, warm yellow-
gold color, meant to be overlaid on top of a plant sprite to show it
is temporarily boosted, mostly transparent except for the glowing
ring itself.
```
