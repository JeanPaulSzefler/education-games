# Junk vs Plants

Prototyp gry typu tower-defense (na wzór Plants vs Zombies) na Androida.
Rośliny bronią ogrodu przed falami śmieci-stworów.

## Ustalenia projektowe (MVP)

- **Silnik:** Godot 4.x (projekt tworzony na 4.4/4.7, zadziała na dowolnej nowszej wersji 4.x)
- **Orientacja i plansza:** ekran poziomy (landscape, 1280x720), siatka ogrodu 10 kolumn x 5 wierszy, po prawej stronie ekranu (pasek roślin zajmuje lewą kolumnę).
- **Przeciwnicy:** mix śmieci — Butelka PET, Puszka, Kartonowy Golem, Brudna Gąbka (dane w `scripts/main.gd`, `ENEMY_TYPES`). Szkodnik, który dotrze do rośliny, "zjada" ją stopniowo (odgryza kawałek HP co jakiś czas), a nie rani jej od razu.
- **Rośliny** (dane w `scripts/plant_data.gd`, `PlantData.TYPES`, 14 sztuk) — każda ma pole `unlock_level`, czyli numer poziomu, od którego jest dostępna do wyboru w talii; nowa roślina co ok. 5 poziomów:
  - **Kukurydza** i **Kaktus** — od startu; **Liść Bananowca** — poz. 6; **Mrozoroślinka** — poz. 11; **Pnącza** — poz. 16; **Wichurowy** — poz. 20; **Ognioroślinka** — poz. 25; **Bumorzech** — poz. 30; **Bitny Brokuł** — poz. 34; **Liść Klonu** — poz. 39; **Aronia** — poz. 43; **Pokrzywa** — poz. 48; **Róża** — poz. 52; **Megakaktus** — poz. 57.
  - **Ognioroślinka** (15 kropli): jednorazowa — wróg, który na nią wejdzie, staje w ogniu i przez 3 s traci w sumie 200 HP, ale może iść dalej. **Aronia** (60): strzela tylko na 2 pola przed sobą, ale salwą 4 pocisków naraz. **Liść Klonu** (20): jednorazowy, odpycha wszystkich wrogów w rzędzie o 4 pola. **Róża** (80): strzela w wroga najbliższego domu w dowolnym rzędzie (pocisk leci za celem). **Pnącza** (0): sadzi się je tylko na kupkach śmieci, które od razu niszczą. **Bumorzech** (90): czeka, aż wróg dojdzie do jego pola, i wtedy od razu wybucha. **Megakaktus** (75): daje po dwie krople wody naraz. Wybuch Bumorzecha widać w pełnym rozmiarze w tej samej klatce, w której wrogowie tracą życie, a wrogów odrzuca dopiero chmurka podmuchu, gdy do nich dotrze (`_update_gusts` w `scripts/main.gd`).
- **Kupki śmieci** (od poziomu 13, pole `junk_pile_waves` w `level_data.gd`): pojawiają się w prawej części planszy na początku wybranych fal; z każdej kupki na starcie każdej fali wychodzi jeden wróg. Na kupce nie da się sadzić (poza Pnączami); rośliny mogą ją zestrzelić (pociski, wybuch Bumorzecha), a Pnącza niszczą ją od razu.
- **Waluta:** krople wody unoszące się nad ekranem — zbierane tapnięciem, zanim znikną. Powstają z Kaktusa. Poziom startuje ze 100 kroplami (`START_WATER` w `scripts/main.gd`).
- **Paski życia:** pojawiają się tylko wtedy, gdy roślina/szkodnik są właśnie atakowani (znikają po ~2s bez trafienia).
- **Sterowanie:** tap-tap — tapnij kafelek rośliny w pionowym pasku po lewej (same ikonki, bez nazw, z kosztem na tle kropli), potem tapnij pole w ogrodzie; wybrany kafelek podświetla się (złota ramka, jaśniejsze tło, wysunięcie w prawo), a kafelek rośliny, na którą brakuje wody, świeci się na czerwono i nie da się go wybrać. Po posadzeniu roślina odnawia się jak w *Plants vs Zombies* — jej kafelek jest zacieniony, a cień kurczy się, aż znów można ją posadzić (Mrozoroślinka: koszt 10, ale najdłuższe odnawianie). Przycisk **X** pod prawym dolnym rogiem planszy włącza tryb usuwania: tapnij potem roślinę, żeby ją usunąć — wydane krople wody nie wracają. Nawóz (kafelek pod ostatnią rośliną, z licznikiem i limitem) zbiera się z planszy tapnięciem. Tapnij kroplę wody, żeby ją zebrać. Nad prawym górnym rogiem planszy są przyciski **WYJŚCIE** (okienko „Czy na pewno?" z ZOSTAŃ / WYJDŹ) i **pauza** (gra staje, ekran się przyciemnia, duży przycisk ▶ wznawia grę).
- **Poziomy:** 60 poziomów (`LevelData.LEVELS` w `scripts/level_data.gd`): każda z 30 plansz (`BASE_LEVELS` i `EXTRA_BOARDS`) daje dwa kolejne poziomy, a druga część ma lustrzanie ułożone rzędy. Każdy ma 4-6 fal mieszających pojedynczych szkodników i większe grupy — ostatnia fala na poziomie jest zawsze największa. Od 3. fali każda fala jest w grze ok. 2x większa niż w danych (`EXTRA_ENEMIES_FROM_WAVE_3` w `scripts/main.gd`). Bossowie (`BossData.TYPES`) pojawiają się co 6 poziomów (6, 12, ..., 48) oraz na poziomach 56 i 60; później z podwyższonym HP (`boss_hp_multiplier`). Poziom odblokowuje się po ukończeniu poprzedniego.
- **Skrzynie:** w co drugiej przerwie między roślinami (`GameState.chest_levels`, poziomy 4, 14, 23, 32, 41, 50, 59). Otwierają się po ukończeniu poziomu przed nimi i nie blokują dalszej drogi. Każda daje 1-3 rubiny i 100-300 roślimonet, losowane z przewagą niższych wartości (`CHEST_RUBY_WEIGHTS`, `CHEST_COIN_WEIGHTS`). Grafiki tymczasowe i rysowane w kodzie: prompty w `GRAFIKI_PROMPTY_5.md`; gra sama użyje plików po ich dodaniu.
- **Nawozy:** pojawiają się same na planszy na różnych etapach poziomu (`LevelData.fertilizer_count`: do poz. 8 żadnego, do poz. 24 jeden, do poz. 40 dwa, potem trzy; w trybie nieskończonym co 4 fale), latają jak krople wody i czekają na tapnięcie. Pokonana roślina po prostu znika, bez nawozu. Można mieć najwyżej 2 nawozy; limit zwiększa się w sklepie za 5, 6, 7 i 8 rubinów, najwyżej do 6. Nawóz działa 2,5 raza mocniej na każdą roślinę oprócz Pnączy, które znikają od razu po posadzeniu: strzelające i Kaktusy działają szybciej, Brokuł mocniej oddaje, a Liść Bananowca wolniej traci życie (przez 9 s). Rośliny jednorazowe trzymają nawóz do chwili użycia: dłuższe zamrożenie, mocniejsze palenie i wybuch, mocniejszy i dalszy odrzut.
- **Ogród** (`scenes/Garden.tscn`, stały, przycisk na ścieżce): 8 pól. Gracz sadzi sadzonkę, podlewa ją kropelką i czeka 15 godzin; dorosła roślinka (jasnofioletowa Pokrzywa) daje 50 roślimonet i znika. Przyspieszenie: 15 rubinów (od razu) albo pszczółka (−3 godziny), która po użyciu odlatuje i wraca po 15-30 minutach. Czas liczy zegar telefonu.
- **Wydarzenia czasowe** (`scenes/Events.tscn`, `scripts/event_data.gd`): każde trwa 7 dni, potem znika razem z postępami, a jego miejsce zajmuje następne z `EventData.ROTATION`. Bez serwera czas liczy się osobno dla każdego konta od pierwszego wejścia. Pierwsze to **Taśma roślin** (5 etapów): bez wody i Kaktusów, pasek na 6 roślin zapełnia się sam losowymi roślinami, także jeszcze nieodblokowanymi, a posadzona znika z paska. Za pierwsze przejście etapu 2-4 sadzonki, za powtórkę 1. Pełna lista 15 wydarzeń z zasadami, pomocami kupowanymi za roślimonety i opcją sadzenia razem: `WYDARZENIA.md`.
- **Tryb nieskończony:** kółko **∞** na końcu ścieżki, odblokowane po poziomie 60. Od 3. fali co 3 fale pojawia się kupka śmieci. Fale są generowane w locie (`_generate_endless_wave` w `scripts/main.gd`, stałe `ENDLESS_*`): 1. i 2. fala są małe, potem fale rosną z numerem fali i z czasem gry, wrogowie z czasem mają więcej HP i są szybsi, a od 5. fali co kilka fal przychodzi losowy boss (później kilku naraz). Gra trwa, aż śmieci dotrą do domu; u góry widać licznik pokonanych wrogów i rekord (`endless_best` w zapisie).
- **Trudność rośnie stopniowo:** Kaktus produkuje wodę coraz wolniej (mnożnik odstępu czasu, `cactus_water_multiplier`, rośnie z każdym kolejnym poziomem), od poziomu 6 dochodzi nowy przeciwnik — **Brudna Gąbka** (`ENEMY_TYPES`, `water_thief`): po pojawieniu się na planszy przyciąga najbliższą wolną kroplę wody (przebarwia ją na brudno-zielono i szybko ściąga w swoją stronę, `WATER_DROP_STEAL_SPEED`); gracz wciąż może ją tapnąć i odzyskać, zanim dolatuje do gąbki — wtedy znika bez zwrotu wody. Od poziomu 8 dochodzą też pola na planszy, na których nie można sadzić roślin (`blocked_tiles`, zaznaczone czerwonym nakryciem na siatce).
- **Konta graczy (lokalne):** ekran startowy (`ProfileSelect.tscn`) — przy pierwszym uruchomieniu „Utwórz konto" (nazwa + ikona, bez hasła), później gracz klika swoje konto na liście (max 6 kont na urządzeniu). Konta są tylko na tym telefonie, bez synchronizacji. Zmiana konta: plakietka gracza na ścieżce → „Zmień konto"; tam też „Usuń konto" (po potwierdzeniu usuwa wybrane konto razem z całym postępem i wraca do ekranu kont).
- **Menu:** po wyborze konta pokazuje się przewijana w poziomie ścieżka poziomów (`LevelSelect.tscn`) — kółka poziomów połączone linią, z osobnymi kółkami na odblokowywane rośliny między nimi (jak mapa przygody w Plants vs. Zombies). Po ukończeniu poziomu, za którym stoi nowa roślina, jej kółko pulsuje na złoto — gracz musi w nie „wejść" (okienko „Odblokowujesz: …" z dużą ikoną i opisem); dopiero wtedy roślina jest dostępna i otwiera się następny poziom. W rogach ścieżki: **Opis gry** (zasady + opisy odblokowanych roślin), **Sklep** z liczbą rubinów i roślimonet (za rubiny działa zwiększanie limitu nawozów, oferty za pieniądze i reklamy to na razie podgląd), **Moje roślinki** (wszystkie rośliny, zablokowane jako cień) i plakietka **gracza** (zmiana nazwy i ikony). Przed każdym poziomem pokazuje się ekran wyboru talii (`PlantSelect.tscn`, max 6 roślin), zapamiętywany osobno dla każdego poziomu.
- **Rubiny i roślimonety:** rubin za pierwsze wygranie każdego poziomu i jeden (jednorazowo) za pokonanie co najmniej 50 wrogów w trybie nieskończonym (`ENDLESS_RUBY_KILLS` w `scripts/game_state.gd`). Rubiny i roślimonety dają też skrzynie i wygrane gry zespołowe. Roślimonety daje też ogród. Rubiny kupują limit nawozów i przyspieszenie w ogrodzie. Roślimonetami płaci się w wydarzeniach poza ścieżką: za pomoc przed etapem, wymianę rośliny w Taśmie z podglądem i dodatkowe sadzonki dla znajomego.
- **Ikonki gracza:** ikonki dwóch roślin startowych są dostępne od razu. Pozostałe mają na plakietce gracza dwa kolejne stany: kłódka (roślina jeszcze zablokowana) i szara (do odblokowania w kilku krokach: 2 do poz. 11, 3 do poz. 34, potem 5 — `icon_steps_required` w `scripts/game_state.gd`). Zamiast reklamy każdy krok pokazuje na 3 sekundy napis „dobrego dnia!" (`_show_greeting` w `scripts/level_select.gd`). Po ostatnim kroku ikonka staje się kolorowa. Konta założone wcześniej zachowują wybraną ikonę.
- **Gra zespołowa (bez serwera):** plakietka gracza → „Gra zespołowa" (`scenes/TeamPlay.tscn`). Telefony muszą być w tej samej sieci Wi-Fi albo jeden na hotspocie drugiego; znajdują się przez rozgłoszenie UDP (port 47810) i łączą bezpośrednio przez ENet (port 47811). Gracz wybiera znajomego z listy osób w pobliżu, a znajomy potwierdza grę na swoim koncie (musi mieć otwarty ten sam ekran); odmowa albo brak odpowiedzi przez 30 s oznacza, że nie grają. Gra toczy się na osobnej planszy zespołowej (`LevelData.team_level`): trudność to średnia poziomów obu graczy (poziomy 2 i 6 dają trudność poziomu 4), na końcu zawsze jest boss, wylosowany spośród tych, których gracze spotkaliby do tej trudności (przed pierwszym bossem ze ścieżki słabszy, 60% HP). Start ze 150 kroplami, fale o 50% większe (`TEAM_*` w `scripts/main.gd`, limit 1. fali zostaje). Każdy gracz wybiera własną talię, a plansza, woda i nawozy są wspólne (liczy się większy limit nawozów z obu kont). Symulację liczy telefon zapraszającego, drugi wysyła akcje i rysuje stan planszy (`scripts/net_session.gd`, sekcja „Gra zespołowa" w `main.gd`). Nie ma pauzy. Każda wygrana daje obu graczom 1 rubin i 50 roślimonet, ale nie posuwa ścieżki. Wersje gry z innym `PROTOCOL_VERSION` się nie widzą. Eksport na Androida wymaga uprawnień `internet`, `access_network_state`, `access_wifi_state` i `change_wifi_multicast_state`.
- **Zapis postępu:** ukończone poziomy (`completed_levels`), wybrane talie per poziom (`loadouts`), rekord trybu nieskończonego (`endless_best`), rubiny (`rubies`, `ruby_levels`), odebrane rośliny (`claimed_plants`), ikonki (`unlocked_icons`, `icon_unlock_steps`), roślimonety (`plant_coins`), otwarte skrzynie (`opened_chests`), limit nawozów (`fertilizer_limit`), ogród (`saplings`, `garden_plots`, `next_bee_time`), wydarzenie (`event_index`, `event_started`, `event_completed_stages`) zapisywane lokalnie osobno dla każdego konta (`user://save_<id>.json`, wersja 5, przez `scripts/game_state.gd`, autoload `GameState`). Lista kont z nazwami i ikonami jest w `user://profiles.json`; zapis sprzed kont (`user://savegame.json`) staje się automatycznie pierwszym kontem „Gracz". Starsze formaty zapisu są migrowane automatycznie przy wczytaniu (przy przejściu na wersję 3 rośliny z ukończonych odcinków ścieżki są uznawane za odebrane, a za ukończone poziomy przyznawane są należne rubiny; przy przejściu na wersję 4 każdy dawny poziom przechodzi na oba nowe, bez dodatkowych rubinów; przy przejściu na wersję 5 talia trybu nieskończonego przechodzi na jego nowy numer).
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
  scenes/TeamPlay.tscn         - szukanie znajomego i zaproszenia do gry zespołowej
  scenes/Garden.tscn           - ogród (sadzenie, podlewanie, pszczółka)
  scenes/Events.tscn           - ekran bieżącego wydarzenia
  scenes/SharedGarden.tscn     - sadzenie razem ze znajomym
  scripts/shared_garden.gd     - logika sadzenia razem
  scripts/garden.gd            - logika ogrodu
  scripts/events.gd            - logika ekranu wydarzenia
  scripts/event_data.gd        - dane wydarzeń i kolejność ich pojawiania się
  scripts/net_session.gd       - autoload: połączenie telefonów bez serwera (wykrywanie, zaproszenia, RPC)
  scripts/team_play.gd         - logika ekranu gry zespołowej
  scripts/profile_select.gd    - logika ekranu kont
  scripts/level_select.gd      - logika przewijanej ścieżki poziomów
  scripts/plant_select.gd      - logika ekranu wyboru talii
  scripts/level_data.gd        - dane 56 poziomów (LevelData.LEVELS), używane przez Main i sciezke
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

Gotowe wersje testowe trafiają do `releases/` pod nazwą `JunkVsPlants-<data>-<commit>.apk`. Pliki `.apk` są ignorowane przez Git, a `.gdignore` sprawia, że Godot pomija ten folder.

## Co dalej (kolejne kroki rozwoju)

- Dalsze dostrojenie ekonomii wody, kosztów roślin i trudności fal po testach rozgrywki
- Dźwięki (sadzenie, trafienie, zbieranie wody, wygrana/przegrana)
- Ekran główny/tytułowy przed ścieżką poziomów

## Zapisane pomysły na później

- Burza mózgów: nowe roślinki oraz nowe typy przeciwników
