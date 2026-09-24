# Junk vs Plants — plan wykonawczy (2026-09-24)

Plan dla modelu, który zrealizuje zmiany. Jest samowystarczalny: nie trzeba czytać
notatek odręcznych. Tło decyzji: `notatki/PLAN_2026-09-23_decyzje.md` i
`notatki/JvP_notatki_20260923_transkrypcja.md`.

Projekt: Godot 4.x, GDScript, katalog `junk-vs-plants/`. Ekran 1280×720, landscape.
Całe UI budowane jest w kodzie (sceny `.tscn` to tylko korzeń + skrypt).

---

## 0. Zasady pracy

1. **Trzy rundy, po kolei: A → B → C.** Po każdej rundzie zatrzymaj się, opisz, co
   zrobiłeś, i poczekaj na test autora. Nie zaczynaj kolejnej rundy bez zgody.
2. **Konwencja kodu:** komentarze po polsku, **bez polskich znaków diakrytycznych**,
   tak samo teksty widoczne w grze („Wybierz rosline", nie „Wybierz roślinę") — tak
   jak w obecnym kodzie. Wcięcia tabulatorami. Styl jak w `main.gd`: słowniki
   w tablicach, UI składane z `Label`/`Button`/`TextureRect`/`ColorRect`.
3. **Bez wielkich refaktorów** poza wymienionymi w planie. Nie przepisuj logiki walki.
4. **Weryfikacja:** jeśli masz dostęp do Godota w wierszu poleceń, uruchom projekt
   bez okna (`godot --headless --path junk-vs-plants --quit`) i sprawdź, że nie ma
   błędów parsowania skryptów. Jeśli Godota nie masz, napisz to wprost; nie deklaruj,
   że działa. Balansu („jest zbalansowane") nie deklarujesz nigdy — ocenia autor.
5. Nie commituj, dopóki autor nie poprosi.
6. Na koniec każdej rundy zaktualizuj `junk-vs-plants/README.md` (tylko fragmenty,
   których runda dotyczy; README jest już częściowo nieaktualny — popraw przy okazji
   liczbę roślin, `.svg` → `.png`, 13 → 10 kolumn itd., gdy do nich dojdziesz).

### Indeksy, na które plan się powołuje

`PlantData.TYPES` (kolejność w pliku, NIE zmieniać — na niej opierają się zapisy):

| idx | Roślina | rola |
|---|---|---|
| 0 | Kukurydza | shooter |
| 1 | Kaktus | generator |
| 2 | Lisc Bananowca | wall |
| 3 | Pokrzywa | shooter (pierce) |
| 4 | Bitny Brokul | melee |
| 5 | Mrozoroslinka | freeze |
| 6 | Bumorzech | bomb |
| 7 | Wichurowy | gust |

`BossData.TYPES`: 0 Puszkowy Tyran, 1 Foliowy Duch, 2 Kompaktor Smieci,
3 Magnetyczny Zlomiarz, 4 Toksyczny Kolos (od najłatwiejszego do najtrudniejszego).

`ENEMY_TYPES` w `main.gd`: 0 Butelka PET, 1 Puszka (szybka), 2 Kartonowy Golem
(dużo HP), 3 Brudna Gabka (kradnie wodę).

---

## RUNDA A — 17 poziomów, odblokowywanie roślin, ścieżka, wybór talii

### A1. Nowy plik `scripts/level_data.gd` — jedno źródło danych poziomów

- `class_name LevelData`, `extends RefCounted`, stała `const LEVELS := [...]`.
- Przenieś tu `LEVELS` z `main.gd`. W `main.gd` zamień wszystkie `LEVELS` na
  `LevelData.LEVELS`. Usuń `LEVEL_NAMES` z `level_select.gd`.
- Format poziomu (pola opcjonalne mają wartości domyślne w kodzie przez `.get()`):

```gdscript
{
	"name": "Poziom 3 - Wysypisko",
	"boss": 0,                      # indeks w BossData.TYPES; -1 albo brak pola = bez bossa
	"boss_hp_multiplier": 1.0,      # domyslnie 1.0
	"cactus_water_multiplier": 1.0, # domyslnie 1.0
	"blocked_tiles": [],            # [[col, row], ...], col w zakresie 0..9
	"waves": [ ... ],               # jak dzis: lista fal, fala = lista {type, row}
}
```

- W `main.gd` → `_spawn_boss()`: HP bossa = `int(bt["hp"] * level.get("boss_hp_multiplier", 1.0))`
  (zarówno `hp`, jak i `max_hp`). Obrażenia bez zmian.

### A2. Treść 17 poziomów

Napisz od nowa wszystkie 17 wpisów (dotychczasowe 5 też — zmieniają się bossowie
i trudność). Nazwy 1–5 zostają; 6–17 to propozycja, którą autor może podmienić.

| Poz. | Nazwa | Boss (idx, HP×) | Nowa roślina na tym poz. | Fale | Wrogowie (typy) | `cactus_water_multiplier` | `blocked_tiles` |
|---|---|---|---|---|---|---|---|
| 1 | Podworko | — | (start: Kukurydza, Kaktus) | 4 | 0, 1 | 1.0 | — |
| 2 | Park | — | — | 5 | 0, 1 | 1.0 | — |
| 3 | Wysypisko | 0 ×1.0 | Lisc Bananowca | 5 | 0, 1, 2 | 1.0 | — |
| 4 | Sortownia Odpadow | — | — | 5 | 0, 1, 2 | 1.0 | — |
| 5 | Skladowisko | 1 ×1.0 | Mrozoroslinka | 5 | 0, 1, 2 | 1.0 | — |
| 6 | Plac Zabaw | — | — | 5 | 0–3 (Gabka od tego poz.) | 1.1 | — |
| 7 | Ogrodki Dzialkowe | 2 ×1.0 | Wichurowy | 5 | 0–3 | 1.1 | — |
| 8 | Brzeg Rzeki | — | — | 5 | 0–3 | 1.2 | 1 pole |
| 9 | Parking | 3 ×1.0 | Bumorzech | 5 | 0–3 | 1.2 | 1 pole |
| 10 | Targowisko | — | — | 6 | 0–3 | 1.25 | 2 pola |
| 11 | Dworzec | 4 ×1.0 | — | 6 | 0–3 | 1.25 | 2 pola |
| 12 | Port | — | Bitny Brokul | 6 | 0–3 | 1.3 | 2 pola |
| 13 | Zlomowisko | 2 ×1.4 | — | 6 | 0–3 | 1.3 | 3 pola |
| 14 | Oczyszczalnia | — | — | 6 | 0–3 | 1.35 | 3 pola |
| 15 | Hala Recyklingu | 3 ×1.6 | — | 6 | 0–3 | 1.35 | 3 pola |
| 16 | Stara Fabryka | — | Pokrzywa | 6 | 0–3 | 1.4 | 3 pola |
| 17 | Gora Smieci | 4 ×1.8 | — | 6 | 0–3 | 1.4 | 3 pola |

Nazwa w danych: `"Poziom N - <Nazwa>"`, jak dziś.

Zasady układania fal (sprawdź je dla każdego poziomu):
- Liczba wrogów w zwykłych falach rośnie łagodnie z poziomem (poz. 1: 1–3 na falę,
  poz. 17: 5–8 na falę). Golem (typ 2) rzadko na poz. 3–5, częściej później.
- **Ostatnia fala jest zawsze większa od każdej wcześniejszej:**
  - poziom **bez bossa** → ostatnia fala ma ok. **2×** tyle wrogów, co największa
    z wcześniejszych fal;
  - poziom **z bossem** → ostatnia fala ma ok. **1,3×** tyle (boss i tak domyka finał).
  Dopisz tę zasadę komentarzem nad `LEVELS`.
- Poziomy 1–2: gracz ma tylko Kukurydzę i Kaktusa — nie dawaj Golema, fale mają być
  do przejścia samymi strzelcami.
- `blocked_tiles`: kolumny 1–8 (nie 0 i nie 9), różne rzędy, nie wszystkie w jednej
  kolumnie. Siatka będzie miała 10 kolumn od rundy B, więc już teraz nie używaj
  kolumn ≥ 10.
- Rzędy wrogów: 0–4.

### A3. Poziom odblokowania roślin w `plant_data.gd`

Dodaj do każdej rośliny pole `"unlock_level"` (numer poziomu **od 1**, na którym
roślina jest już dostępna):

| Roślina | `unlock_level` |
|---|---|
| Kukurydza, Kaktus | 1 |
| Lisc Bananowca | 3 |
| Mrozoroslinka | 5 |
| Wichurowy | 7 |
| Bumorzech | 9 |
| Bitny Brokul | 12 |
| Pokrzywa | 16 |

Dopisz komentarz przy polu. Znaczenie: roślina odblokowuje się **na stałe** w chwili,
gdy odblokowuje się poziom `unlock_level` (czyli po ukończeniu poziomu `unlock_level - 1`).
Przy powtórce wcześniejszych poziomów gracz ma wszystkie zdobyte rośliny.

### A4. `game_state.gd` — nowy format zapisu

- `LEVEL_COUNT := 17` (albo `LevelData.LEVELS.size()`).
- `MAX_LOADOUT := 6`.
- Zamiast `unlocked_levels` przechowuj **`completed_levels`** (17 × bool). Pozwala to
  pokazać ukończenie także ostatniego poziomu.
- Funkcje:
  - `is_level_unlocked(i) -> bool` — `i == 0 or completed_levels[i - 1]` (i od 0);
  - `is_level_completed(i) -> bool`;
  - `is_plant_unlocked(plant_idx) -> bool` — `is_level_unlocked(unlock_level - 1)`;
  - `unlocked_plant_indices() -> Array` — w kolejności `PlantData.TYPES`;
  - `complete_level(i)` — ustawia `completed_levels[i] = true` i zapisuje;
  - `get_loadout(level_i) -> Array` / `set_loadout(level_i, plant_indices)` — wybór
    talii zapamiętany per poziom.
- `var current_loadout := []` — talia na bieżącą grę (ustawiana przez ekran wyboru).
- Usuń `LOCKED_PLACEHOLDER_COUNT` (sloty „???" znikają razem z ekranem ścieżki).
- Plik zapisu:

```json
{"version": 2, "completed_levels": [false, ...17], "loadouts": {"0": [0, 1], "4": [0, 1, 2, 5]}}
```

- **Migracja starego zapisu** (brak `version`, jest `unlocked_levels` z 5 pozycjami):
  `completed_levels[i] = unlocked_levels[i + 1]` dla `i` = 0..3; reszta `false`.
  Po wczytaniu od razu zapisz w nowym formacie. Wczytywanie ma być odporne: zła
  długość tablic, brak pól, śmieci w JSON → wartości domyślne, bez crasha.
- Przy wczytywaniu `loadouts` odfiltruj indeksy spoza 0..7, roślin nieodblokowanych
  i nadmiar ponad 6.

### A5. Ścieżka poziomów zamiast ekranu wyboru poziomu

Przepisz `scripts/level_select.gd` (scena `LevelSelect.tscn` zostaje sceną startową).
**Usuń** `scenes/ProgressPath.tscn`, `scripts/progress_path.gd` i jego `.uid` —
ścieżka przejmuje ich rolę. Usuń przycisk „Sciezka sukcesow".

Wygląd (wg szkicu autora: kółka połączone linią, od lewej do prawej, a między
poziomami osobne kółka z ikonką odblokowywanej roślinki):

- Tło jak dziś (`Color(0.15, 0.25, 0.15)`), tytuł „Junk vs Plants" u góry.
- Sekwencja węzłów (23 sztuki):
  `P1, P2, [Lisc], P3, P4, [Mroz], P5, P6, [Wichurowy], P7, P8, [Bumorzech], P9, P10,
  P11, [Brokul], P12, P13, P14, P15, [Pokrzywa], P16, P17`.
  Generuj ją w kodzie z `unlock_level` (węzeł rośliny wstaw tuż przed poziomem
  `unlock_level`; rośliny z `unlock_level == 1` nie mają węzła).
- **Wszystkie węzły w jednej poziomej linii**, od lewej do prawej, na wysokości
  ok. y = 380; odstęp między środkami ok. 170 px, margines ok. 150 px z każdej strony
  (cała ścieżka ma ok. 4000 px szerokości). Na ekranie widać naraz ok. 7 węzłów.
- **Ekran przesuwa się w poziomie** — jak mapa przygody w „Plants vs. Zombies":
  - Węzły i linie leżą w jednym kontenerze `path_layer` (`Control`), który przesuwasz
    po osi x. Tytuł i tło stoją w miejscu.
  - Przesuwanie palcem (`InputEventScreenDrag`) i myszą (ruch z wciśniętym lewym
    przyciskiem), a na komputerze także kółkiem myszy. Pozycję ogranicz tak, żeby
    nie dało się wyjechać poza pierwszy i ostatni węzeł.
  - **Tap a przesunięcie:** jeśli od wciśnięcia palec/mysz przesunęły się o więcej
    niż ok. 12 px, to jest przesuwanie i puszczenie **nie** uruchamia poziomu.
    Przyciski poziomów reagują dopiero na puszczenie po krótkim ruchu. Przetestuj
    to na obu rodzajach wejścia.
  - Po wejściu na ekran ścieżka ustawia się tak, żeby **aktualny poziom**
    (najwyższy odblokowany, nieukończony) był na środku ekranu.
  - Opcjonalnie: po lewej i prawej krawędzi półprzezroczyste strzałki „‹" „›",
    widoczne tylko wtedy, gdy w daną stronę jest jeszcze coś do zobaczenia; tap
    przesuwa ścieżkę o szerokość ekranu (płynnie, `Tween`).
- Linie łączące kolejne węzły: jedna gruba (ok. 8 px) jasnobrązowa linia
  (`Line2D` albo `ColorRect`-y pod węzłami). Odcinki prowadzące do zablokowanych
  węzłów — szare.
- **Węzeł poziomu:** okrągły `Button` 96×96 (okrąg = `StyleBoxFlat` z
  `corner_radius_*` = 48, ustaw style `normal`/`hover`/`pressed`/`disabled`), numer
  poziomu dużą czcionką (ok. 36).
  - ukończony → zielony;
  - odblokowany, jeszcze nieukończony → żółty + delikatne pulsowanie (`Tween`,
    skala 1.0 ↔ 1.08, w pętli; ustaw `pivot_offset` na środek);
  - zablokowany → szary, `disabled = true`.
  - Pod węzłem mała nazwa poziomu (bez „Poziom N - "), czcionka ok. 13.
- **Oznaczenie poziomu z bossem:** w prawym górnym rogu węzła odznaka — mała
  (ok. 44 px) ikonka tego bossa (`texture` z `BossData.TYPES`) na ciemnoczerwonym
  kółku. Dla zablokowanych poziomów odznaka przyciemniona, ale widoczna (dziecko
  widzi, że „tam czeka boss").
- **Węzeł rośliny:** okrąg 72×72 (`Panel` ze `StyleBoxFlat`), w środku ikonka rośliny
  (`texture` z `PlantData.TYPES`), pod spodem nazwa (czcionka ok. 13).
  - roślina odblokowana → jasnozielone tło, ikonka w kolorze;
  - zablokowana → szare tło, ikonka jako ciemna sylwetka (`modulate = Color(0.15, 0.15, 0.15)`).
  - Węzeł rośliny nie jest klikalny.
- Tap w odblokowany poziom → `GameState.current_level_index = i` →
  `change_scene_to_file("res://scenes/PlantSelect.tscn")`.

### A6. Nowa scena: wybór talii `scenes/PlantSelect.tscn` + `scripts/plant_select.gd`

Pokazuje się **zawsze** przed poziomem (także gdy gracz ma tylko 2 rośliny — wtedy
działa jako przypomnienie „oto twoje rośliny").

- Nagłówek: nazwa poziomu; pod spodem „Wybierz rosliny do tej gry (najwyzej 6)"
  i licznik „Wybrane: n / 6". Jeśli poziom ma bossa — mały napis z ikonką bossa
  „Na koncu: <nazwa bossa>".
- Karty wszystkich 8 roślin, 4 w rzędzie, 2 rzędy (ok. 260×220 px): ikonka ok. 110 px,
  nazwa, koszt z ikonką kropli (`assets/sprites/ui/water_drop.png`).
  - odblokowana: tap przełącza zaznaczenie; zaznaczona ma grubą zieloną ramkę
    i znacznik „✓" (lub zielone kółko, jeśli znak się nie renderuje);
  - zablokowana: sylwetka + napis „od poziomu N", nie da się zaznaczyć;
  - próba zaznaczenia 7. rośliny → komunikat „Mozesz wybrac najwyzej 6 roslin".
- Domyślne zaznaczenie: zapamiętana talia tego poziomu (`GameState.get_loadout`),
  a gdy jej nie ma — pierwsze 6 odblokowanych roślin w kolejności `PlantData.TYPES`.
- Przyciski: „Wroc" (do `LevelSelect.tscn`), „Graj!" (nieaktywny, gdy nic nie
  zaznaczono). „Graj!" → `GameState.current_loadout` = zaznaczone indeksy
  w kolejności `PlantData.TYPES`, `GameState.set_loadout(...)`, przejście do `Main.tscn`.

### A7. `main.gd` — korzystanie z talii

- `_build_plant_bar()` tworzy przyciski **tylko dla roślin z `GameState.current_loadout`**,
  a `bind` przekazuje prawdziwy indeks z `PlantData.TYPES` (reszta logiki używa
  `selected_plant_type` jako indeksu `PLANT_TYPES` — ma tak zostać).
- Jeśli `current_loadout` jest puste (np. uruchomienie `Main.tscn` z edytora) —
  weź `GameState.unlocked_plant_indices()`, maksymalnie 6.
- Przycisk „Wybierz poziom" na końcu gry prowadzi na ścieżkę (`LevelSelect.tscn`);
  „Zagraj ponownie" przeładowuje scenę z tą samą talią (tak działa już teraz,
  bo talia siedzi w `GameState`).

### Kryteria odbioru rundy A (sprawdza autor)

- [ ] Świeża gra (usunięty `user://savegame.json`): na ścieżce odblokowany tylko
      poziom 1, pulsuje; węzły roślin to sylwetki; poziomy 3, 5, 7, 9, 11, 13, 15, 17
      mają odznakę bossa.
- [ ] Ścieżka jest jedną linią; przesunięcie palcem/myszą pokazuje dalsze poziomy
      aż do 17 i nie wyjeżdża poza końce; przesuwanie nie uruchamia przypadkiem
      poziomu; po powrocie z gry aktualny poziom jest na środku ekranu.
- [ ] Poziom 1: wybór talii pokazuje Kukurydzę i Kaktusa zaznaczone, reszta
      zablokowana z napisem „od poziomu N". W grze w pasku tylko te 2 rośliny.
- [ ] Po wygraniu poziomu 2 węzeł Liścia Bananowca się koloruje, poziom 3 się
      odblokowuje, a Liść jest dostępny także przy powtórce poziomu 1.
- [ ] Poziom 3 kończy się bossem Puszkowym Tyranem; poziom 2 nie ma bossa.
- [ ] Zapis ze starej wersji gry (np. odblokowane poziomy 1–3) wczytuje się bez błędu
      i pokazuje ukończone poziomy 1–2.
- [ ] Wybór talii jest pamiętany przy powrocie do tego samego poziomu.

---

## RUNDA B — pionowy pasek roślin, ikonki, ekonomia

### B1. Siatka

- `COLS := 10` (`CELL` = 88, `ROWS` = 5, `GRID_TOP` = 92 bez zmian).
- `GRID_LEFT := 332` (1280 − 10·88 − 68: po prawej zostaje ten sam margines co dziś
  na wchodzących wrogów). Wszystkie pozycje w `main.gd` są już liczone od
  `GRID_LEFT`/`COLS`/`CELL` — sprawdź tylko stałe liczbowe w `_build_hud()`,
  `_build_plant_bar()`, `_build_fertilizer_button()`, `_show_end_buttons()`.
- Tło `_build_background()` na całą wysokość ekranu (dziś kończy się pod siatką).

### B2. Pionowy pasek po lewej (x ≈ 16–316)

Od góry:
1. **Licznik wody:** ikonka kropli (ok. 40 px) + duża liczba (ok. 30 pt). Zastępuje
   dotychczasowy napis „Krople wody: N".
2. **Kafelki roślin** z talii (max 6), jeden pod drugim, ok. 300×76 px, odstęp ok. 8 px:
   - ikonka rośliny ok. 64 px po lewej;
   - koszt: liczba na tle małej ikonki kropli, po prawej;
   - **bez nazwy rośliny** („Obrazki, a nie napisy");
   - wybrany kafelek: gruba żółta ramka;
   - gdy `water < cost`: cały kafelek przyciemniony (`modulate` ok. 0.45) — nadal
     klikalny, a przy próbie sadzenia komunikat „Za malo kropel wody", jak dziś.
   - Kafelek to `Button` z własnym `StyleBoxFlat` i dziećmi `TextureRect`/`Label`
     z `mouse_filter = IGNORE`, żeby tap trafiał w przycisk.
3. **Nawóz** pod ostatnim kafelkiem: ikonka nawozu + liczba, ten sam styl kafelka;
   zastępuje przycisk „Uzyj nawozu (N)" i osobny napis „Nawozy: N".

Stan kafelków odświeżaj w `_update_hud()` (jest wołane przy każdej zmianie wody).

### B3. Górny pasek nad siatką (od x = `GRID_LEFT`)

Tytuł poziomu, `wave_label`, pasek HP bossa — przesunięte w prawo nad siatkę.
`message_label` i przyciski końca gry pod siatką, również od x = `GRID_LEFT`.
Zmień tekst „Wybierz roslin z paska ponizej" na „Wybierz rosline z paska po lewej".

### B4. Ekonomia (decyzja autora: wolniejsze kaktusy + mniej wody na starcie)

- Woda na starcie poziomu: `150 → 100` (`var water` w `main.gd`; zrób z tego stałą
  `START_WATER := 100`).
- Kaktus: `water_interval` `7.0 → 9.0`. `water_value` zostaje 20.
- Koszty roślin — **wartości domyślne, autor może je zmienić przed rundą B**
  (odczyt ze szkicu tam, gdzie był czytelny; reszta bez zmian):

| Roślina | Dziś | Nowy koszt |
|---|---|---|
| Kukurydza | 50 | 50 |
| Kaktus | 25 | 25 |
| Lisc Bananowca | 75 | 50 |
| Pokrzywa | 60 | 60 |
| Bitny Brokul | 70 | 60 |
| Mrozoroslinka | 40 | 40 |
| Bumorzech | 90 | 90 |
| Wichurowy | 65 | 60 |

- Po zwężeniu planszy sprawdź, czy `Wichurowy` (`knockback` 130) i `Bumorzech`
  (promień 1 pole) nadal działają sensownie; nie zmieniaj ich wartości bez potrzeby.
- Fal poza ostatnią (zasada z A2) w tej rundzie nie ruszaj.

### Kryteria odbioru rundy B

- [ ] Pasek roślin po lewej, same ikonki z kosztem; siatka 10×5 po prawej; nic nie
      nachodzi na siebie w 1280×720.
- [ ] Wybrany kafelek wyróżniony; kafelki bez wystarczającej wody przyciemnione
      i rozjaśniają się po zebraniu kropli.
- [ ] Nawóz działa jak wcześniej (tap w kafelek nawozu → tap w roślinę).
- [ ] Start poziomu: 100 kropel. Kaktus wyraźnie wolniej daje wodę.
- [ ] Autor przechodzi poziomy 1, 5, 13 i 17 i ocenia trudność (to on decyduje
      o dalszym strojeniu).

---

## RUNDA C — animacje (proceduralne, bez nowych grafik)

Technika: `Tween` na istniejących `TextureRect`-ach + proste kształty rysowane
w kodzie (`Polygon2D` z punktami okręgu/gwiazdy albo `ColorRect`). Tweeny twórz
przez `node.create_tween()` (ginie razem z węzłem po `queue_free()`). Dla skalowania
i obrotu ustaw `pivot_offset = size / 2`. Wszystkie czasy krótkie (0,1–0,5 s), żeby
nie spowalniały gry. Animacje nie mogą zmieniać logiki (pozycji `e["x"]`, trafień).

### C1. Kukurydza i Pokrzywa — widoczne wyrzucenie pocisku (jak w PvZ)

Przy każdym strzale (`_update_plants`, gałąź `"shooter"`):
- roślina najpierw „nabiera" (0,08 s: odchylenie w lewo o ok. 6 px i skala 0,9 w
  poziomie), potem wyrzut (0,08 s: do przodu o ok. 8 px, skala 1,1), potem powrót
  (0,1 s);
- pocisk rodzi się w chwili wyrzutu z „pyszczka" rośliny (prawa krawędź sprite'a,
  wysokość ok. 40% od góry), startuje w skali 0,4 i w 0,1 s rośnie do 1,0.
  Pocisk nie może pojawiać się dalej niż dziś — przesunięcie tylko wizualne, trafienia
  liczone jak dotąd.
- Nie ruszaj `position.x` rośliny na stałe — tween wraca do pozycji bazowej zapisanej
  w słowniku rośliny (`"base_pos"`).

### C2. Bitny Brokuł — cios pięścią

Przy kontrataku (`bpt["role"] == "melee"` w `_update_enemies`): brokuł wyskakuje
o ok. 14 px w prawo i wraca (0,15 s); w miejscu wroga na 0,2 s pojawia się „pięść" —
zielone kółko ok. 26 px (`Polygon2D`) z żółtą gwiazdką uderzenia, która rośnie i znika.

### C3. Wichurowy — przesuwająca się niebieska chmurka

Przy `_trigger_gust`: chmurka (3–4 nakładające się jasnoniebieskie półprzezroczyste
kółka w jednym `Node2D`) startuje w polu rośliny i w 0,5 s przelatuje do prawej
krawędzi planszy w tym rzędzie, a potem zanika (0,2 s). Wróg odrzucany jest jak dziś.

### C4. Bumorzech — wybuch

Przy `_trigger_bomb`: pomarańczowe kółko na środku pola, rosnące w 0,3 s do średnicy
ok. 3 pól (zasięg 3×3), z żółtym środkiem, jednocześnie zanikające; na ułamek sekundy
białe mignięcie. Opcjonalnie drobne potrząśnięcie planszą (±4 px, 0,2 s).

### C5. Wrogowie — chodzenie i „jedzenie"

- **Chodzenie:** gdy wróg idzie (brak blokującej rośliny i nie jest zamrożony),
  sprite podskakuje: `position.y = base_y + sin(t * 10 + faza) * 3` i kołysze się
  (`rotation` ±0,08 rad). Faza losowa per wróg. Gdy stoi — wraca do `base_y`
  i rotacji 0. Licz to w `_update_enemies`, nie Tweenem.
- **Jedzenie** (zastępczo za „otwieranie buzi", bo nie ma klatek z otwartą paszczą):
  przy każdym ugryzieniu szybki wypad w lewo o ok. 8 px i spłaszczenie
  (`scale.y` 0,85) i powrót (0,15 s), plus 3–4 zielone okruszki (małe `ColorRect`),
  które odlatują z rośliny i znikają w 0,4 s.
- Bossowie tak samo, tylko wolniej i z większym wychyleniem.
- Pasek zdrowia jest dzieckiem sprite'a — kołysanie go obraca; to akceptowalne.

### C6. Wygrana — konfetti na cały ekran

W `_win_game()` przed pokazaniem przycisków: `CPUParticles2D` (działa w rendererze
„mobile") na całą szerokość ekranu, emisja z prostokąta nad górną krawędzią,
kolorowe prostokąciki spadające z grawitacją i obrotem, ok. 3 s, ok. 150–200 cząstek.
Napis „WYGRANA!" duży na środku. Przyciski pojawiają się po ok. 1,5 s.

### C7. Przegrana — duży śmieciostwór

W `_update_enemies` zapamiętaj wroga, który dotarł do domu. W `_lose_game()`:
półprzezroczysta ciemna nakładka na cały ekran, na środku **duża ikonka tego
właśnie wroga** (jego `texture`, ok. 320 px), wjeżdżająca skalą 0 → 1 z odbiciem
(`Tween.TRANS_BACK`), pod spodem napis „Smieci dotarly do domu!". Potem przyciski.

### Kryteria odbioru rundy C

- [ ] Każdy z 7 punktów z notatki widoczny w grze: pięść Brokuła, chmurka
      Wichurowego, wyrzut pocisku z Kukurydzy i Pokrzywy, wybuch Bumorzecha,
      chodzenie i „jedzenie" wrogów, konfetti, duży śmieciostwór.
- [ ] Brak zmian w rozgrywce: te same trafienia, czasy, obrażenia.
- [ ] Na telefonie gra nie zwalnia przy ostatniej fali poziomu 17.

---

## Poza zakresem (nie rób)

Cooldown roślin po posadzeniu, dźwięki, nowi wrogowie, nowe rośliny, klatki animacji
z otwartą paszczą, decyzja o plikach `resources/gpt_*.png`.

## Założenia przyjęte domyślnie (autor może je zmienić przed startem rundy)

Wynikają z rekomendacji w `PLAN_2026-09-23_decyzje.md`, na które autor jeszcze nie
odpowiedział: podział na rundy A/B/C (D0.1), nazwy poziomów 6–17 (D1.1), krzywa
trudności z tabeli A2 (D1.3), usunięcie slotów „???" (D2.3), migracja zapisu (D2.4),
ekran talii zawsze, osobna scena, zapamiętywany (D3.1–D3.4), układ paska (D4.2–D4.3),
koszty z tabeli B4 (D5.1), animacje proceduralne (D6.1–D6.3).
