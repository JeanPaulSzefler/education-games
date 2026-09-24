# Junk vs Plants — szkic planu usprawnień (na bazie notatek z 2026-09-23)

Dokument roboczy. **Nie jest to jeszcze plan do wykonania.** To lista decyzji, które trzeba
podjąć, żeby dopiero na ich podstawie napisać szczegółowy plan implementacji dla modelu
Sonnet 5.

Wejście: `notatki/JvP_notatki_20260923_transkrypcja.md`
Stan kodu na dziś: 5 poziomów, 8 roślin (wszystkie dostępne od startu), 5 bossów,
4 typy zwykłych wrogów, poziomy pasek roślin na dole, brak ekranu wyboru talii.

---

## Część I — Mapa zmian wynikających z notatek

Sześć niezależnych obszarów. Kolejność sugerowana (od fundamentu do kosmetyki):

| # | Obszar | Skala | Pliki, których dotknie |
|---|---|---|---|
| 1 | Rozbudowa z 5 do 17 poziomów | duża | `scripts/main.gd` (`LEVELS`), `scripts/level_select.gd`, `scripts/game_state.gd` |
| 2 | Stopniowe odblokowywanie roślin | średnia | `scripts/game_state.gd`, `scripts/main.gd`, `scripts/progress_path.gd` |
| 3 | Ekran wyboru talii (max 6 roślin przed grą) | średnia | nowa scena + `scripts/main.gd`, `scripts/level_select.gd` |
| 4 | Przebudowa HUD: pionowy pasek roślin po lewej, ikonki zamiast napisów | średnia | `scripts/main.gd` (`_build_hud`, stałe siatki) |
| 5 | Przestrojenie ekonomii („za łatwo") + nowe koszty roślin | mała, ale ryzykowna | `scripts/plant_data.gd`, `scripts/main.gd` |
| 6 | Animacje (rośliny, wrogowie, wygrana/przegrana) | duża | `scripts/main.gd`, ewentualnie nowe grafiki |

Obszary 1–3 są ze sobą sprzężone (wszystkie ruszają `game_state.gd` i format zapisu) —
powinny wejść jako jedna spójna zmiana albo w ustalonej kolejności. Obszary 4–6 są od
nich niezależne.

---

## Część II — Decyzje do podjęcia

Przy każdej decyzji: kontekst, opcje, moja rekomendacja. Odpowiedź „tak, rekomendacja"
wystarczy, żeby ruszyć dalej.

### Obszar 1 — 17 poziomów

**D1.1 — Nazwy i motywy poziomów 6–17.**
Dziś nazwy są zaszyte w dwóch miejscach naraz (`main.gd` → `LEVELS[i].name`
oraz `level_select.gd` → `LEVEL_NAMES`), w stylu „Poziom 4 - Sortownia Odpadów".
Do ustalenia: 12 nowych nazw/lokacji.
*Rekomendacja:* podaj listę 12 nazw; przy okazji Sonnet usunie duplikat i zostawi
jedno źródło prawdy (`LEVELS`).

**D1.2 — Bossowie na poziomach 6–17. — ROZSTRZYGNIĘTE (2026-09-24)**
Decyzja: **nie każdy poziom ma bossa, a bossowie mogą się powtarzać.** Żadnych nowych
bossów do projektowania — zostaje 5 istniejących z `boss_data.gd`.
- Bossowie są **mocniejsi (więcej HP) tylko na późniejszych poziomach** — ten sam boss
  pojawiający się drugi raz ma podbite HP.
- Poziomy z bossem: **co drugi, 3, 5, 7, 9, 11, 13, 15, 17** (potwierdzone). Poziomy
  1 i 2 bez bossa, ostatni poziom (17) z bossem. 8 występów przy 5 bossach, czyli
  poziomy 3–11 to pierwsze wystąpienia każdego bossa, a 13, 15, 17 to powtórki
  z podbitym HP. Poziom z bossem ma **oznaczenie na ścieżce** (np. ikonka bossa przy
  węźle).
- **Ostatnia fala każdego poziomu jest większa od zwykłych**: na poziomie bez bossa
  wyraźnie większa, na poziomie z bossem tylko trochę większa. Do zapisania jako pole
  w `LEVELS` (np. `final_wave_multiplier`) z domyślną wartością zależną od obecności bossa.
Do dopracowania przy planie wykonawczym (nie wymaga już Twojej decyzji, chyba że
zgłosisz inaczej):
- przydział bossów — **ROZSTRZYGNIĘTE (2026-09-24):** bossowie z podbitym HP są
  **ostatni i najtrudniejsi**. Kolejność rośnie z trudnością (indeksy z `boss_data.gd`):

  | Poziom | Boss | HP |
  |---|---|---|
  | 3 | Puszkowy Tyran (0) | bazowe |
  | 5 | Foliowy Duch (1) | bazowe |
  | 7 | Kompaktor Śmieci (2) | bazowe |
  | 9 | Magnetyczny Złomiarz (3) | bazowe |
  | 11 | Toksyczny Kolos (4) | bazowe |
  | 13 | Kompaktor Śmieci (2) | podbite |
  | 15 | Magnetyczny Złomiarz (3) | podbite bardziej |
  | 17 | Toksyczny Kolos (4) | podbite najbardziej — finał gry |

- sposób podbicia: pole `boss_hp_multiplier` w `LEVELS` (1.0 na poziomach 3–11,
  rosnące na 13 → 15 → 17, konkretne wartości do testu);
- czy podbijamy tylko HP, czy też obrażenia ugryzienia — *rekomendacja:* tylko HP,
  zgodnie z Twoim sformułowaniem.

**D1.3 — Krzywa trudności na 17 poziomach.**
Dziś utrudnienia to: `cactus_water_multiplier` (poz. 4–5), `blocked_tiles` (poz. 5),
Brudna Gąbka (poz. 4+). Trzeba rozłożyć je na 17 poziomów i ewentualnie dodać nowe.
Do ustalenia: czy dochodzą **nowe typy zwykłych wrogów** (dziś są 4), czy wystarczy
skalowanie liczby i HP istniejących.
*Rekomendacja:* na start bez nowych wrogów — skalowanie + więcej `blocked_tiles`
+ mocniejszy `cactus_water_multiplier`. Nowi wrogowie jako osobna iteracja.

**D1.4 — Ekran wyboru poziomu nie zmieści 17 kafelków.**
`level_select.gd`: przyciski 380×90 px, 3 w rzędzie, start Y=130. 17 poziomów = 6 rzędów
= koniec na Y≈780, a pod spodem jest jeszcze przycisk „Ścieżka sukcesów" — wyjdzie poza
ekran 1280×720.
Opcje:
- (a) mniejsze kafelki / 5 w rzędzie;
- (b) przewijana lista (`ScrollContainer`);
- (c) **połączyć ekran wyboru poziomu ze Ścieżką sukcesów w jedną planszę-ścieżkę** —
  pomysł już zapisany w README („Zapisane pomysły na później"), a notatka („ścieżka
  poziomów, na której odblokowują się roślinki") wprost o to prosi: przy poziomie widać
  roślinkę, która się na nim pojawia.
*Rekomendacja:* (c). Jest zgodne z notatką i likwiduje `ProgressPath.tscn` jako osobny
ekran. Wymaga jednak decyzji D1.5.

**D1.5 — Jeśli (c): jak wygląda ścieżka?**
Do ustalenia: układ (kręta ścieżka z węzłami vs. prosta siatka 17 kafelków),
czy jest przewijana, jak oznaczone są poziomy zablokowane, gdzie wyświetlana jest
nowo odblokowana roślinka.
**Wskazówka autora (2026-09-24, `JvP_notatki_20260923_dod.jpeg`):** ścieżka to kółka
połączone linią, biegnąca od lewej do prawej: `(1) — (roślinka) — (2) — (…)`.
Odblokowanie roślinki jest **osobnym węzłem między poziomami**, a nie ikonką nad
węzłem poziomu. W tym węźle wyświetlana jest **ikonka odblokowywanej roślinki**
(ta sama grafika co w pasku roślin). Poziomy z bossem mają własne oznaczenie (D1.2).
**ROZSTRZYGNIĘTE (2026-09-24):** 17 węzłów poziomów + 6 węzłów roślin (po poziomach
2, 4, 6, 8, 11, 15, czyli tuż przed poziomem, na którym roślina wchodzi) w **jednej
poziomej linii**; ekran **przesuwa się w poziomie**, żeby zobaczyć kolejne poziomy
(jak w „Plants vs. Zombies"). Zablokowane wyszarzone.

---

### Obszar 2 — Odblokowywanie roślin

**D2.1 — Semantyka listy z notatki. — ROZSTRZYGNIĘTE (2026-09-24): wariant (b).**
Zdobyte roślinki zostają na zawsze. Rozkład odblokowań (tabela poprawiona przez autora):
start — Kukurydza, Kaktus; poz. 3 — Liść bananowca; 5 — Mrozoroślinka; 7 — Wichurowy;
9 — Bumorzech; 12 — Bitny Brokuł; 16 — Pokrzywa.
Notatka podaje dla każdego poziomu zestaw roślin. Dwie różne interpretacje:
- (a) **Whitelist na poziom** — na poziomie N można użyć *dokładnie* wypisanych roślin,
  niezależnie od postępu. Poziom 1 zawsze tylko Kukurydza + Kaktus (nawet po przejściu gry).
- (b) **Nagroda za ukończenie** — roślina odblokowuje się trwale po ukończeniu poziomu
  i od tego momentu jest dostępna wszędzie, także przy powtórce poziomu 1.
*Rekomendacja (zmieniona 2026-09-24 na (b)):* wariant **(b)**, bo:
- notatka mówi „ścieżka poziomów, na której **odblokowują się** roślinki" — „odblokować"
  znaczy zwykle „na stałe";
- w grze jest już ekran „Ścieżka sukcesów – odblokowane rośliny", czyli kolekcja;
  wariant (a) czyniłby go bezsensownym;
- ekran wyboru 6 roślin (D3) ma sens dopiero, gdy gracz ma ich więcej niż 6
  (przy nowym rozkładzie: od poziomu 12).
Minus (b): powrót na wczesne poziomy staje się łatwy. Dla gry dla dzieci to raczej
nagroda za postęp niż wada.
Różnica między (a) i (b) dotyczy **wyłącznie powtarzania już ukończonych poziomów** —
przy pierwszym przejściu gry oba warianty wyglądają identycznie.

**D2.2 — Co wtedy znaczy „odblokowana" na Ścieżce sukcesów?**
Dziś `progress_path.gd` pokazuje wszystkie 8 roślin jako odblokowane + 4 puste sloty
„???" (`GameState.LOCKED_PLACEHOLDER_COUNT`).
*Rekomendacja (po D2.1(b)):* „odblokowana" = zdobyta na ścieżce; niezdobyte jako
wyszarzone sylwetki w swoich węzłach ścieżki (D1.5).

**D2.3 — Czy 4 sloty „???" zostają?**
Przy 8 roślinach rozłożonych na 17 poziomów zostają poziomy 2, 4, 6, 8, 10, 11, 13, 14,
15, 17 bez nowej rośliny. Pytanie: czy to celowe (oddech w tempie), czy sygnał, że planujesz **5 kolejnych
roślin**, które miałyby tam wejść.
*Rekomendacja:* potwierdź, że na razie 8 roślin wystarczy; `LOCKED_PLACEHOLDER_COUNT`
zmienić na 0 albo zostawić jako jawną zapowiedź.

**D2.4 — Zgodność starych zapisów.**
`user://savegame.json` trzyma dziś `{"unlocked_levels": [5 × bool]}`. Po zmianie będzie
17 pozycji + ewentualnie wybrana talia.
Opcje: (a) dopisać brakujące `false` i zachować postęp; (b) wykryć stary format
i zacząć od nowa.
*Rekomendacja:* (a), z polem `"version"` w pliku na przyszłość.

---

### Obszar 3 — Wybór talii (max 6 roślin)

**D3.1 — Kiedy ekran się pokazuje.**
Notatka: „zawsze przed grą". Ale przy pierwszym przejściu na poziomach 1–11 gracz ma
2–6 roślin, więc wybór „max 6" jest pustym klikiem.
Opcje: (a) zawsze, zgodnie z notatką (na wczesnych poziomach wszystko zaznaczone
z góry, gracz tylko potwierdza — działa jako ekran „oto twoje rośliny", czyli też
samouczek); (b) pokazywać dopiero gdy dostępnych jest więcej niż 6 (czyli praktycznie
od poziomu 12).
*Rekomendacja:* (a) — notatka mówi „zawsze", a wartość dydaktyczna (przypomnienie,
czym dysponujesz i ile kosztuje) jest realna nawet przy 3 roślinach.

**D3.2 — Czy 6 to twardy limit, czy limit slotów paska.**
Pionowy pasek z D4 fizycznie pomieści określoną liczbę wierszy. Czy 6 to liczba
wynikająca z paska (więc zmieni się, jeśli pasek urośnie), czy zasada rozgrywki.
*Rekomendacja:* zasada rozgrywki, stała `MAX_LOADOUT := 6`, pasek projektowany pod nią.

**D3.3 — Osobna scena czy nakładka.**
Opcje: (a) nowa scena `PlantSelect.tscn` między wyborem poziomu a `Main.tscn`;
(b) nakładka (overlay) w `Main.tscn` przed startem pierwszej fali.
*Rekomendacja:* (a) — `main.gd` ma już 990 linii i nie warto go dociążać.

**D3.4 — Czy wybór talii się zapamiętuje.**
Czy przy powtórce tego samego poziomu ekran pamięta poprzedni wybór.
*Rekomendacja:* tak, per poziom, w `savegame.json`.

---

### Obszar 4 — Przebudowa HUD

**D4.1 — Ile miejsca oddajemy paskowi. — ROZSTRZYGNIĘTE (2026-09-24)**
Decyzja: **`COLS = 10`**, `CELL` bez zmian (88 px).
Siatka: 10 × 88 = 880 px, więc na pionowy pasek po lewej zostaje ok. 330 px — z zapasem.
Rozmiary sprite'ów i logika pocisków bez zmian. Efekt uboczny, pożądany: krótszy
dystans dla wroga = **trudniej**, zgodnie z notatką „jest za łatwo".
Do sprawdzenia przy implementacji: `blocked_tiles` poziomu 5 (`[[4,1],[4,3],[2,2]]` —
mieszczą się w 10 kolumnach, OK) oraz zasięg `gust` i `bomb` po zwężeniu planszy.

**D4.2 — Co jeszcze ląduje w pasku, a co zostaje u góry.**
Dziś u góry są: tytuł poziomu, licznik wody, licznik nawozu, licznik fali, komunikaty,
nazwa bossa; na dole przyciski roślin + przycisk nawozu.
Do ustalenia: czy licznik wody i przycisk nawozu wędrują do pionowego paska (na szkicu
pasek zawiera tylko rośliny), czy zostają w górnym HUD.
*Rekomendacja:* licznik wody na górze paska (tam patrzy gracz, gdy wybiera roślinę),
przycisk nawozu pod ostatnią rośliną, reszta zostaje u góry ekranu.

**D4.3 — Jak wygląda pojedynczy kafelek rośliny.**
Notatka: „Obrazki, a nie napisy". Dziś: `btn.text = "%s\n%d kropel"` (`main.gd:275`).
Do ustalenia: czy nazwa rośliny znika całkowicie, czy zostaje malutkim podpisem;
jak pokazany jest koszt (sam liczba? liczba + mini-ikonka kropli?); jak zaznaczony
jest brak stać-mnie (wyszarzenie? czerwony koszt?).
*Rekomendacja:* ikonka + liczba kosztu w rogu na tle kropli, bez nazwy; przy braku
wody cały kafelek przyciemniony. Nazwa tylko na ekranie wyboru talii (D3) i Ścieżce.

**D4.4 — Czy kafelki mają cooldown po posadzeniu.**
W PvZ każda roślina ma odliczanie. Dziś w grze go nie ma — ogranicza tylko woda.
Notatka o tym nie mówi, ale to najczystszy sposób na „jest za łatwo".
*Rekomendacja:* poza zakresem tej rundy; odnotować i wrócić po D5.

---

### Obszar 5 — Ekonomia i koszty

**D5.1 — Nowa tabela kosztów (wymaga twojej decyzji, nie da się odczytać z kartki).**
Liczby w prostokątach na szkicu są wielokrotnie poprawiane. Zestawienie obecnych
wartości z tym, co *wydaje się* być na kartce:

| Roślina | Koszt dziś (`plant_data.gd`) | Odczyt ze szkicu |
|---|---|---|
| Kukurydza | 50 | 50 (zgodne) |
| Kaktus | 25 | ~15–25 (nieczytelne) |
| Liść Bananowca | 75 | ~50 (nieczytelne) |
| Bitny Brokuł | 70 | 60 |
| Mrozoroślinka | 40 | 70 `[?]` |
| Bumorzech | 90 | 50 |
| Wichurowy | 65 | 60 |
| Pokrzywa | 60 | brak na szkicu |

*Potrzebne:* pełna tabela 8 liczb. Sama zmiana kosztów bez D5.2 zmieni trudność
w nieprzewidziany sposób — te dwie decyzje trzeba podjąć razem.

**D5.2 — Którą dźwignią zmniejszamy „nagrody". — ROZSTRZYGNIĘTE (2026-09-24)**
Decyzja autora: **kaktusy wolniej produkują wodę** (dłuższy `water_interval`) oraz
**mniej wody na starcie poziomu** (niższe startowe 150). `water_value` bez zmian.
Konkretne liczby do ustalenia w planie wykonawczym i do testu (D0.2).
Poniżej pierwotna analiza:
Dostępne pokrętła: start gry `water = 150` (`main.gd:~146`), `water_value = 20` i
`water_interval = 7.0` u Kaktusa (`plant_data.gd`), `cactus_water_multiplier` per poziom.
Opcje: (a) obniżyć `water_value` (mniej z każdej kropli); (b) wydłużyć `water_interval`
(rzadziej); (c) obniżyć startowe 150; (d) kombinacja.
*Rekomendacja:* (d) — startowe 150 → 100 (wymusza świadome pierwsze posadzenie)
plus `water_value` 20 → 15. `water_interval` zostawić, bo od niego zależy rytm
tapania, który dzieciom działa dobrze.

**D5.3 — Czy podbijamy trudność również falami.**
(Wyjątek już przesądzony: większa ostatnia fala — D1.2.)
Notatka mówi tylko o nagrodach, ale sprzężenie D4.1 (mniej kolumn) + D5.2 (mniej wody)
może przestrzelić w drugą stronę.
*Rekomendacja:* w tej rundzie **nie** ruszać fal; najpierw przetestować efekt D4.1+D5.2,
dopiero potem stroić `LEVELS`.

---

### Obszar 6 — Animacje

**D6.1 — Technika (decyzja rozstrzygająca o kosztach całego obszaru).**
Cała grafika to dziś pojedyncze, statyczne PNG (`assets/sprites/...`).
Opcje:
- (a) **animacja proceduralna** — `Tween`/`AnimationPlayer` na istniejących sprite'ach:
  skalowanie, obrót, przesunięcie, mignięcie kolorem, dorysowane kształty (chmurka,
  pięść, błysk wybuchu) jako osobne małe węzły. Zero nowej grafiki;
- (b) **klatki** — wygenerować dla każdej rośliny/wroga po 2–4 klatki i przełączać
  je `AnimatedSprite2D`. Wymaga ~30+ nowych obrazków i utrzymania spójności stylu
  (`GRAFIKI_PROMPTY_2.md`);
- (c) hybryda: (a) dla roślin, (b) tylko dla chodzenia wrogów („ruszają nogami"),
  bo tego nie da się dobrze udać samym tweenem.
Doprecyzowanie autora (2026-09-24): Kukurydza i Pokrzywa mają **widocznie wyrzucać**
pocisk (ruch rośliny przy strzale, jak w „Plants vs. Zombies") — samo pojawienie się
pocisku w miejscu rośliny nie wystarcza.
*Rekomendacja:* (a) na całość jako pierwszy krok — daje 6 z 7 punktów z notatki
od razu i bez ryzyka graficznego. „Ruszanie nogami" udawać kołysaniem/podskokiem
sprite'a; jeśli po obejrzeniu będzie wyglądać źle, dorobić (b) tylko dla wrogów.

**D6.2 — „Otwieranie buzi" przy zjadaniu.**
To jedyny punkt z notatki, którego tween nie udaje sensownie bez drugiej klatki.
Opcje: (a) druga klatka „paszcza otwarta" dla 4 wrogów + 5 bossów (9 obrazków);
(b) zastąpić efektem zastępczym (szarpnięcie w stronę rośliny + okruchy).
*Rekomendacja:* (b) w tej rundzie, (a) gdy będziesz generować kolejną partię grafik.

**D6.3 — Zakres ekranów wygranej/przegranej.**
Notatka: konfetti na cały ekran przy wygranej, duża ikonka śmieciostwora przy przegranej.
Do ustalenia: czy podmieniamy obecny ekran końca gry (`main.gd:~978`, przyciski
„Jeszcze raz"/„Wybór poziomu"), czy dokładamy animację przed nim.
*Rekomendacja:* animacja przed istniejącym ekranem, przyciski bez zmian.

**D6.4 — Dźwięk.**
`assets/sounds` jest pusty, a README wymienia dźwięki jako kolejny krok. Animacje bez
dźwięku wypadają płasko.
*Rekomendacja:* poza zakresem tej rundy — osobna decyzja o źródle dźwięków.

---

## Część III — Decyzje przekrojowe

**D0.1 — Zakres jednej rundy.**
Sześć obszarów to dużo jak na jedną zmianę. Proponowany podział na trzy rundy:
1. **Runda A (fundament):** obszary 1 + 2 + 3 — 17 poziomów, trwałe odblokowania roślin,
   ekran talii, nowy format zapisu, połączona ścieżka poziomów.
2. **Runda B (odczucie gry):** obszary 4 + 5 — pionowy pasek, ikonki, nowe koszty,
   przestrojona ekonomia. Zakończona sesją testową.
3. **Runda C (polerka):** obszar 6 — animacje.
*Do potwierdzenia:* czy taki podział i taka kolejność.

**D0.2 — Jak testujemy.**
Projekt nie ma testów automatycznych, a zmiany 4 i 5 są czysto odczuciowe.
*Rekomendacja:* po rundach B i C ty przechodzisz poziomy 1, 5, 13 i 17 i zgłaszasz
wrażenia; Sonnet nie deklaruje „zbalansowane" bez tego.

**D0.3 — README.**
`README.md` jest już nieaktualny (mówi o 5 poziomach, 3 roślinach, plikach `.svg`,
podczas gdy w kodzie jest 8 roślin, 5 bossów, nawóz i PNG-i).
*Rekomendacja:* aktualizacja README jako ostatni krok każdej rundy, nie jedna wielka
na końcu.

**D0.4 — Nieskomitowane pliki.**
W `resources/` leży 15 nowych PNG-ów (`gpt_*.png`) poza gitem. Do decyzji: dołączyć
do repo czy usunąć jako materiał roboczy.

---

## Część IV — Co Sonnet 5 może zrobić bez pytania

Rzeczy jednoznaczne, niewymagające decyzji — do wpisania wprost w plan wykonawczy:

- usunięcie duplikatu nazw poziomów (`level_select.gd` czyta z `LEVELS`);
- wyniesienie stałych siatki (`COLS`, `CELL`, `GRID_LEFT`) tak, żeby zmiana jednej
  liczby nie rozjeżdżała HUD-u;
- dopisanie `"version"` do `savegame.json` i bezpieczne wczytywanie starego formatu;
- rozbicie `main.gd` (990 linii) przynajmniej na logikę HUD i logikę rozgrywki,
  skoro obszar 4 i tak przepisuje `_build_hud()`;
- komentarze po polsku, bez polskich znaków diakrytycznych — zgodnie z konwencją
  obecną w `plant_data.gd` i `boss_data.gd`.

---

## Następny krok

**2026-09-24: plan wykonawczy gotowy → `notatki/PLAN_WYKONAWCZY_2026-09-24.md`.**
Nierozstrzygnięte decyzje przyjęto w nim według rekomendacji (lista na końcu planu).

Odpowiedz na decyzje z Części II i III (wystarczy „D1.1 — takie nazwy, D1.2 — rekomendacja,
D1.3 — …"). Na tej podstawie powstanie szczegółowy plan wykonawczy dla Sonneta 5:
konkretne pliki, konkretne funkcje, kolejność zmian i kryteria sprawdzenia.

### Stan decyzji

Rozstrzygnięte 2026-09-24:
- **D4.1** — 10 kolumn, `CELL` = 88 bez zmian.
- **D1.2** — bossowie bez zmian co do typów; nie na każdym poziomie (na 1 na pewno nie),
  mocniejsi (więcej HP) dopiero na późniejszych.

- **D1.2 (uzupełnienie)** — bossowie co drugi poziom: 3, 5, 7, 9, 11, 13, 15, 17,
  oznaczeni na ścieżce;
  ostatnia fala zawsze większa (przy bossie tylko trochę).
- **D2.1** — wariant (b): zdobyte roślinki zostają na zawsze; 17 poziomów, rozkład
  odblokowań jak w transkrypcji.
- **D5.2** — wolniejsze kaktusy + mniej wody na starcie.
- **D1.5 (częściowo)** — węzły roślin między poziomami, z ikonką odblokowywanej rośliny.

Nadal blokujące: **D0.1** (podział na rundy).

Reszta (D1.1 nazwy poziomów, D5.1 tabela kosztów, D6.1 technika animacji) jest potrzebna
dopiero przy odpowiedniej rundzie.
