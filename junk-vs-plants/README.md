# Junk vs Plants

Prototyp gry typu tower-defense (na wzór Plants vs Zombies) na Androida.
Rośliny bronią ogrodu przed falami śmieci-stworów.

## Ustalenia projektowe (MVP)

- **Silnik:** Godot 4.x (projekt tworzony na 4.4/4.7, zadziała na dowolnej nowszej wersji 4.x)
- **Orientacja i plansza:** ekran poziomy (landscape, 1280x720), siatka ogrodu 10 kolumn x 5 wierszy, po prawej stronie ekranu (pasek roślin zajmuje lewą kolumnę).
- **Przeciwnicy:** mix śmieci — Butelka PET, Puszka, Kartonowy Golem, Brudna Gąbka (dane w `scripts/main.gd`, `ENEMY_TYPES`). Szkodnik, który dotrze do rośliny, "zjada" ją stopniowo (odgryza kawałek HP co jakiś czas), a nie rani jej od razu.
- **Rośliny** (dane w `scripts/plant_data.gd`, `PlantData.TYPES`, 13 sztuk) — każda ma pole `unlock_level`, czyli numer poziomu, od którego jest dostępna do wyboru w talii; nowa roślina co 2-3 poziomy:
  - **Kukurydza** i **Kaktus** — od startu; **Liść Bananowca** — poz. 3; **Mrozoroślinka** — poz. 5; **Pnącza** — poz. 7; **Wichurowy** — poz. 9; **Ognioroślinka** — poz. 11; **Bumorzech** — poz. 13; **Bitny Brokuł** — poz. 15; **Liść Klonu** — poz. 18; **Aronia** — poz. 20; **Pokrzywa** — poz. 22; **Róża** — poz. 25.
  - **Ognioroślinka** (15 kropli): jednorazowa — wróg, który na nią wejdzie, staje w ogniu i przez 3 s traci w sumie 200 HP, ale może iść dalej. **Aronia** (60): strzela tylko na 2 pola przed sobą, ale salwą 4 pocisków naraz. **Liść Klonu** (20): jednorazowy, odpycha wszystkich wrogów w rzędzie o 4 pola. **Róża** (80): strzela w wroga najbliższego domu w dowolnym rzędzie (pocisk leci za celem). **Pnącza** (0): sadzi się je tylko na kupkach śmieci, które od razu niszczą.
- **Kupki śmieci** (od poziomu 7, pole `junk_pile_waves` w `level_data.gd`): pojawiają się w prawej części planszy na początku wybranych fal; z każdej kupki na starcie każdej fali wychodzi jeden wróg. Na kupce nie da się sadzić (poza Pnączami); rośliny mogą ją zestrzelić (pociski, wybuch Bumorzecha), a Pnącza niszczą ją od razu.
- **Waluta:** krople wody unoszące się nad ekranem — zbierane tapnięciem, zanim znikną. Powstają z Kaktusa. Poziom startuje ze 100 kroplami (`START_WATER` w `scripts/main.gd`).
- **Paski życia:** pojawiają się tylko wtedy, gdy roślina/szkodnik są właśnie atakowani (znikają po ~2s bez trafienia).
- **Sterowanie:** tap-tap — tapnij kafelek rośliny w pionowym pasku po lewej (same ikonki, bez nazw, z kosztem na tle kropli), potem tapnij pole w ogrodzie; wybrany kafelek podświetla się (złota ramka, jaśniejsze tło, wysunięcie w prawo), a kafelek rośliny, na którą brakuje wody, świeci się na czerwono i nie da się go wybrać. Po posadzeniu roślina odnawia się jak w *Plants vs Zombies* — jej kafelek jest zacieniony, a cień kurczy się, aż znów można ją posadzić (Mrozoroślinka: koszt 10, ale najdłuższe odnawianie). Przycisk **X** pod prawym dolnym rogiem planszy włącza tryb usuwania: tapnij potem roślinę, żeby ją usunąć — wydane krople wody nie wracają. Nawóz to taki sam kafelek pod ostatnią rośliną. Tapnij kroplę wody, żeby ją zebrać. Nad prawym górnym rogiem planszy są przyciski **WYJŚCIE** (okienko „Czy na pewno?" z ZOSTAŃ / WYJDŹ) i **pauza** (gra staje, ekran się przyciemnia, duży przycisk ▶ wznawia grę).
- **Poziomy:** 28 plansz (`LevelData.LEVELS` w `scripts/level_data.gd`), każdy z 4-6 falami mieszającymi pojedynczych szkodników i większe grupy — ostatnia fala na poziomie jest zawsze największa. Od 3. fali każda fala jest w grze ok. 2x większa niż w danych (`EXTRA_ENEMIES_FROM_WAVE_3` w `scripts/main.gd`). Bossowie (`BossData.TYPES`) pojawiają się co 3 poziomy (3, 6, 9, 12, 15, 18, 21, 24) i na ostatnim, 28. poziomie; od 15. poziomu z podwyższonym HP (`boss_hp_multiplier`). Poziom odblokowuje się po ukończeniu poprzedniego.
- **Tryb nieskończony:** kółko **∞** na końcu ścieżki, odblokowane po poziomie 28. Od 3. fali co 3 fale pojawia się kupka śmieci. Fale są generowane w locie (`_generate_endless_wave` w `scripts/main.gd`, stałe `ENDLESS_*`): 1. i 2. fala są małe, potem fale rosną z numerem fali i z czasem gry, wrogowie z czasem mają więcej HP i są szybsi, a od 5. fali co kilka fal przychodzi losowy boss (później kilku naraz). Gra trwa, aż śmieci dotrą do domu; u góry widać licznik pokonanych wrogów i rekord (`endless_best` w zapisie).
- **Trudność rośnie stopniowo:** Kaktus produkuje wodę coraz wolniej (mnożnik odstępu czasu, `cactus_water_multiplier`, rośnie z każdym kolejnym poziomem), od poziomu 6 dochodzi nowy przeciwnik — **Brudna Gąbka** (`ENEMY_TYPES`, `water_thief`): po pojawieniu się na planszy przyciąga najbliższą wolną kroplę wody (przebarwia ją na brudno-zielono i szybko ściąga w swoją stronę, `WATER_DROP_STEAL_SPEED`); gracz wciąż może ją tapnąć i odzyskać, zanim dolatuje do gąbki — wtedy znika bez zwrotu wody. Od poziomu 8 dochodzą też pola na planszy, na których nie można sadzić roślin (`blocked_tiles`, zaznaczone czerwonym nakryciem na siatce).
- **Konta graczy (lokalne):** ekran startowy (`ProfileSelect.tscn`) — przy pierwszym uruchomieniu „Utwórz konto" (nazwa + ikona, bez hasła), później gracz klika swoje konto na liście (max 6 kont na urządzeniu). Konta są tylko na tym telefonie, bez synchronizacji. Zmiana konta: plakietka gracza na ścieżce → „Zmień konto"; tam też „Usuń konto" (po potwierdzeniu usuwa wybrane konto razem z całym postępem i wraca do ekranu kont).
- **Menu:** po wyborze konta pokazuje się przewijana w poziomie ścieżka poziomów (`LevelSelect.tscn`) — kółka poziomów połączone linią, z osobnymi kółkami na odblokowywane rośliny między nimi (jak mapa przygody w Plants vs. Zombies). Po ukończeniu poziomu, za którym stoi nowa roślina, jej kółko pulsuje na złoto — gracz musi w nie „wejść" (okienko „Odblokowujesz: …" z dużą ikoną i opisem); dopiero wtedy roślina jest dostępna i otwiera się następny poziom. W rogach ścieżki: **Opis gry** (zasady + opisy odblokowanych roślin), **Sklep** z liczbą rubinów (na razie tylko podgląd ofert — zakupy i reklamy nie działają), **Moje roślinki** (wszystkie rośliny, zablokowane jako cień) i plakietka **gracza** (zmiana nazwy i ikony). Przed każdym poziomem pokazuje się ekran wyboru talii (`PlantSelect.tscn`, max 6 roślin), zapamiętywany osobno dla każdego poziomu.
- **Rubiny:** 1 za pierwsze wygranie każdego poziomu i 1 (jednorazowo) za pokonanie co najmniej 50 wrogów w trybie nieskończonym (`ENDLESS_RUBY_KILLS` w `scripts/game_state.gd`). Na razie nie ma na co ich wydać (ulepszenia w sklepie — później).
- **Zapis postępu:** ukończone poziomy (`completed_levels`), wybrane talie per poziom (`loadouts`), rekord trybu nieskończonego (`endless_best`), rubiny (`rubies`, `ruby_levels`), odebrane rośliny (`claimed_plants`) zapisywane lokalnie osobno dla każdego konta (`user://save_<id>.json`, wersja 3, przez `scripts/game_state.gd`, autoload `GameState`). Lista kont z nazwami i ikonami jest w `user://profiles.json`; zapis sprzed kont (`user://savegame.json`) staje się automatycznie pierwszym kontem „Gracz". Starsze formaty zapisu są migrowane automatycznie przy wczytaniu (przy przejściu na wersję 3 rośliny z ukończonych odcinków ścieżki są uznawane za odebrane, a za ukończone poziomy przyznawane są należne rubiny).
- **Grafika:** wygenerowane ikony PNG w stylu naklejek (sticker, chibi-kawaii) w `assets/sprites/` (oryginały z generatora w `resources/gpt_*.png`, prompty w `GRAFIKI_PROMPTY*.md`). Grafiki w grze są przycięte do widocznej treści i zmniejszone do maks. 512 px.
- **Animacje:** proceduralne (Tween na sprite'ach + proste kształty rysowane w kodzie, bez dodatkowych plików graficznych) — wyrzut pocisku z Kukurydzy/Pokrzywy, cios pięścią Bitnego Brokułu, przelatująca chmurka Wichurowego, wybuch Bumorzecha, chodzenie i "jedzenie" wrogów, konfetti przy wygranej, duży śmieciostwór przy przegranej.

## Struktura projektu

```
junk-vs-plants/
  project.godot              - konfiguracja projektu Godot (autoload GameState, scena startowa ProfileSelect)
  icon.svg                    - placeholder ikony gry
  scenes/ProfileSelect.tscn    - wybór / zakładanie lokalnego konta gracza (scena startowa)
  scenes/LevelSelect.tscn      - ścieżka poziomów, przewijana w poziomie
  scenes/PlantSelect.tscn      - ekran wyboru talii przed poziomem (max 6 roślin)
  scenes/Main.tscn             - scena rozgrywki (jeden poziom)
  scripts/profile_select.gd    - logika ekranu kont
  scripts/level_select.gd      - logika przewijanej ścieżki poziomów
  scripts/plant_select.gd      - logika ekranu wyboru talii
  scripts/level_data.gd        - dane 28 poziomów (LevelData.LEVELS), używane przez Main i sciezke
  scripts/game_state.gd        - autoload: postęp gracza (ukończone poziomy, talie per poziom), zapis/odczyt
  scripts/plant_data.gd        - dane roślin (PlantData.TYPES, w tym unlock_level), używane przez Main, sciezke i PlantSelect
  scripts/boss_data.gd         - dane bossów (BossData.TYPES)
  scripts/ui_icons.gd          - ikonki interfejsu rysowane w kodzie (rubin, książka, koszyk, pauza/play)
  scripts/main.gd              - logika rozgrywki (siatka, fale, ekonomia wody, walka, zjadanie, paski życia)
  assets/sprites/plants        - grafiki roślin (PNG)
  assets/sprites/enemies       - grafiki śmieci-stworów i bossów (PNG)
  assets/sprites/ui            - grafiki interfejsu (PNG)
  assets/sounds                - dźwięki/muzyka
  levels/                      - zarezerwowane na przyszłość (osobne pliki danych poziomów)
```

## Jak otworzyć i testować

1. Zainstaluj [Godot](https://godotengine.org/download) — dowolna aktualna wersja 4.x (wersja Standard, nie .NET).
2. Otwórz Godota → "Import" → wskaż folder `junk-vs-plants` (plik `project.godot`).
3. Naciśnij F5 (lub przycisk Play), żeby uruchomić grę w oknie na komputerze. Start to ekran wyboru konta, potem przewijana ścieżka poziomów.

## Jak zbudować APK na Androida

1. W Godot: **Editor → Manage Export Templates** → pobierz szablony eksportu dopasowane do wersji Godota, której używasz.
2. Zainstaluj Android SDK + Java JDK (Godot poprowadzi przez to w **Editor → Editor Settings → Export → Android**, gdzie wskazuje się ścieżki do `Android SDK` i `debug.keystore`; Godot potrafi wygenerować domyślny debug keystore jednym kliknięciem).
3. **Project → Export...** → dodaj preset "Android" → **Export Project** → zapisz plik `.apk`.
4. Przenieś `.apk` na telefon (kabel/USB, Google Drive, itp.) i zainstaluj (włącz "Instalacja z nieznanych źródeł" w ustawieniach Androida), albo użyj `adb install junk-vs-plants.apk` po podłączeniu telefonu kablem z włączonym trybem debugowania USB.

## Co dalej (kolejne kroki rozwoju)

- Dalsze dostrojenie ekonomii wody, kosztów roślin i trudności fal po testach rozgrywki
- Dźwięki (sadzenie, trafienie, zbieranie wody, wygrana/przegrana)
- Ekran główny/tytułowy przed ścieżką poziomów

## Zapisane pomysły na później

- Burza mózgów: nowe roślinki oraz nowe typy przeciwników
