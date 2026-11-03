# Polecenia do wygenerowania grafik — Junk vs Plants (część 7)

Trzy partie grafik do nowości z 2026-11-03. Do czasu ich dodania gra rysuje proste zastępstwa w kodzie, więc każdą partię można dodać osobno.

- **Partia A — 4 propozycje tła** ekranu głównego. Autorka gry wybierze jedną w ankiecie, a gra użyje jej jako `ui/background.png`.
- **Partia B — 16 grafik** do ustawień, dodatków, gier edukacyjnych, gry z innym graczem i przewodnika.
- **Partia C — 39 ikonek śmieci** do Quizu ekologicznego i Sortowni.

**Jak używać:** wklej do generatora wspólny styl i blok jednej partii. Jako wzoru stylu dołącz `assets/sprites/plants/cactus.png`. Generator ma zwracać po jednej grafice; pisz „następna”, aż dostaniesz wszystkie z partii. Szczegóły zapisu plików: `zadania/ZADANIE_07_GRAFIKI.md`.

## Wspólny styl (wklej przed każdą partią)

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

## Partia A — tła (4 propozycje)

```
BACKGROUNDS. These differ from the shared style in these ways: each image is a
full landscape scene, 1920x1080 px (16:9), with NO transparency, filling the
whole image edge to edge. Outlines on background shapes are thinner than on
characters. The game draws white text, round green buttons and a horizontal row
of level circles on top of it, so:
- keep the middle horizontal band (from 40% to 70% of the height) calm and simple,
  e.g. an open meadow or a path, without small busy details
- keep the colors slightly muted and medium-dark overall, so white text and the
  buttons stay easy to read
- put the most interesting details in the four corners and along the top edge
- no characters, no plants with faces, no trash monsters

1. bg_option_1.png "Sunny garden": a bright friendly backyard garden on a sunny
day. Soft blue sky with two puffy clouds at the top, gentle green hills in the
distance, a low wooden fence across the background, colorful flower beds and a
small watering can in the bottom corners, a cosy little house with a red roof at
the far left edge. The middle band is a smooth green lawn.

2. bg_option_2.png "Forest clearing": a sunny clearing in a friendly cartoon
forest. Tall rounded trees frame the left and right edges, rays of light fall
through the leaves at the top, red-and-white mushrooms and ferns in the bottom
corners. The middle band is a soft grassy clearing with a faint winding dirt trail.

3. bg_option_3.png "Sunset allotments": allotment gardens at golden sunset. Warm
orange-pink sky with a big low sun near the top center, small greenhouses and
garden sheds as darker shapes along the horizon, tall sunflowers in the bottom
corners. The middle band is a calm field of soft green-brown garden beds.

4. bg_option_4.png "Garden before Trash Mountain": a clean, happy garden in the
front, and far away in the hazy background a big grey-purple mountain made of
cartoon junk (bottles, cans, boxes), drawn small and soft so it is not scary. Blue
sky at the top, a wooden fence and bushes in the bottom corners. The middle band
is a smooth green lawn.
```

## Partia B — grafiki interfejsu i dodatków (16)

```
UI AND EXTRAS. Each image: square, 1024x1024 px, fully TRANSPARENT background
(PNG with alpha), the subject centered and filling about 85-90% of the image,
no ground, no drop shadow, readable at about 48 px.

1. settings_gear.png: a chunky light-grey cog wheel with 8 rounded teeth, a darker
grey ring inside and a small green leaf in the center hole.

2. addon_gift.png: a cute gift box, pink-red with a golden ribbon and a big golden
bow on top, two small green leaves sticking out from under the lid.

3. education_bins.png: three small rounded recycling bins standing side by side:
yellow, blue and green, each with a lid and a simple white recycling arrow symbol
(three arrows in a triangle, no letters).

4. mode_coop.png: a little Corn character and a little round green Cactus
character (cute faces, big round black eyes) standing side by side and giving
each other a high five, with a small pink heart above them.

5. mode_duel.png: the same little Corn and Cactus characters facing each other in
a friendly playful challenge pose, each holding up a small fist, with a small
yellow lightning spark between them. Both smiling, not angry.

6. guide_arrow.png: a thick, rounded, bright yellow arrow pointing straight DOWN,
with a light orange shade on one side and a white highlight. Simple and bold.

7. tree_of_life.png: a small magical tree of life: a short sturdy brown trunk, a
big round bright green crown with a few small pink blossoms and two golden
sparkles. Cute face on the trunk: big round black eyes with white highlight dots
and a small smile. It stands on a small mound of dark brown soil.

8. cage.png: an EMPTY cage made of junk seen from the front: a rusty grey metal
frame with 4 vertical bars, a top made of a flattened tin lid and a bottom made
of an old cardboard box edge, with a little padlock hanging on one bar. The
spaces between the bars are see-through (transparent).

9. animal_hedgehog.png: a cute round hedgehog in side view, brown spiky back,
light tan face and belly, big round black eye with a white highlight, small smile.

10. animal_bird.png: a cute round little blue bird in side view, flying with wings
up, orange beak, big round black eye with a white highlight, small smile.

11. animal_frog.png: a cute round green frog sitting, front view, two big round
eyes on top with white highlights, wide happy smile, light green belly.

12. animal_butterfly.png: a cute butterfly seen from the front with wings open:
pink and purple wings with simple round spots, small dark body, two curled
antennae, tiny happy face.

13. seed.png: one plump brown plant seed (teardrop shape) with a lighter stripe
down the middle and a tiny fresh green sprout leaf coming out of the top.

14. watering_can.png: a blue metal watering can in side view, spout pointing to
the right, round handle on top, a few water drops coming out of the spout.

15. spider_web.png: a simple round white spider web with 8 spokes and 4 rings,
drawn with a thin dark grey outline so it is visible on light grass, and a tiny
cute black spider hanging from one thread. The spaces of the web are transparent.

16. house.png: a small cosy cottage, front view: cream walls, red roof, a round
window with light, a green door, a little chimney and a flower box under the window.
```

## Partia C — śmieci do Quizu i Sortowni (39)

```
TRASH ITEMS. Each image: square, 1024x1024 px, fully TRANSPARENT background, one
everyday waste item centered and filling about 80% of the image, NO face and NO
eyes, clearly recognizable for a 7-year-old, no brand names or labels with text.

1. trash_plastic_bottle.png: an empty clear plastic drink bottle with a blue cap, slightly crushed.
2. trash_drink_can.png: an empty aluminium drink can, red and silver, slightly dented.
3. trash_yogurt_cup.png: an empty white plastic yogurt cup with a peeled foil lid.
4. trash_plastic_bag.png: a crumpled thin plastic shopping bag, light blue.
5. trash_juice_carton.png: an empty juice carton box with an orange on the side and a small straw.
6. trash_milk_carton.png: an empty milk carton with a gable top, white and blue.
7. trash_bottle_cap.png: one plastic bottle cap, green.
8. trash_food_tin.png: an empty open tin can with the lid bent up.
9. trash_chips_bag.png: an empty crinkled crisp packet, shiny silver inside.
10. trash_shampoo_bottle.png: an empty plastic shampoo bottle, pink, with a flip cap.
11. trash_newspaper.png: a folded newspaper with grey lines and a small picture (no real letters).
12. trash_cardboard_box.png: a flattened brown cardboard box.
13. trash_notebook.png: an old school notebook with a few grey lines, slightly worn.
14. trash_paper_bag.png: a brown paper bag with a folded top.
15. trash_egg_carton.png: a grey paper egg carton, empty, lid open.
16. trash_magazine.png: a colorful magazine with abstract shapes on the cover (no letters).
17. trash_paper_flyer.png: a single colorful paper flyer, slightly folded.
18. trash_envelope.png: a white paper envelope, closed.
19. trash_glass_bottle.png: an empty green glass bottle.
20. trash_jam_jar.png: an empty glass jam jar with a red lid next to it.
21. trash_perfume_bottle.png: an empty small glass perfume bottle with a round cap.
22. trash_juice_glass_bottle.png: an empty clear glass juice bottle with a metal cap.
23. trash_cream_jar.png: an empty small glass cosmetic jar with a white lid.
24. trash_banana_peel.png: a yellow banana peel.
25. trash_apple_core.png: a red apple core with a stalk.
26. trash_eggshells.png: three cracked white eggshell halves.
27. trash_vegetable_peels.png: a small pile of carrot and potato peels.
28. trash_coffee_grounds.png: a small pile of dark brown coffee grounds.
29. trash_dry_leaves.png: three dry autumn leaves, brown and orange.
30. trash_wilted_flowers.png: a small bunch of wilted drooping flowers.
31. trash_orange_peel.png: a curly orange peel.
32. trash_used_tissue.png: a crumpled used paper tissue.
33. trash_broken_mug.png: a broken ceramic mug in two pieces.
34. trash_greasy_pizza_box.png: an open pizza box with greasy stains inside.
35. trash_receipt.png: a long curled shop receipt with grey lines (no real numbers).
36. trash_dirty_sponge.png: a dirty kitchen sponge, yellow and green, with brown stains.
37. trash_old_toothbrush.png: an old toothbrush with splayed bristles.
38. trash_broken_mirror.png: a small broken hand mirror with a crack.
39. trash_diaper.png: a rolled-up used disposable diaper (clean-looking, no dirt shown).
```
