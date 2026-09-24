# Junk vs Plants

Prototyp gry typu tower-defense (na wzór Plants vs Zombies) na Androida.
Rośliny bronią ogrodu przed falami śmieci-stworów.

## Ustalenia projektowe (MVP)

- **Silnik:** Godot 4.x (projekt tworzony na 4.4/4.7, zadziała na dowolnej nowszej wersji 4.x)
- **Orientacja i plansza:** ekran poziomy (landscape, 1280x720), siatka ogrodu 10 kolumn x 5 wierszy, po prawej stronie ekranu (pasek roślin zajmuje lewą kolumnę).
- **Przeciwnicy:** mix śmieci — Butelka PET, Puszka, Kartonowy Golem, Brudna Gąbka (dane w `scripts/main.gd`, `ENEMY_TYPES`). Szkodnik, który dotrze do rośliny, "zjada" ją stopniowo (odgryza kawałek HP co jakiś czas), a nie rani jej od razu.
- **Rośliny** (dane w `scripts/plant_data.gd`, `PlantData.TYPES`, 8 sztuk) — każda ma pole `unlock_level`, czyli numer poziomu, od którego jest dostępna do wyboru w talii:
  - **Kukurydza** i **Kaktus** — dostępne od startu.
  - **Liść Bananowca**, **Mrozoroślinka**, **Wichurowy**, **Bumorzech**, **Bitny Brokuł**, **Pokrzywa** — odblokowują się kolejno wraz z postępem po ścieżce poziomów.
- **Waluta:** krople wody unoszące się nad ekranem — zbierane tapnięciem, zanim znikną. Powstają z Kaktusa. Poziom startuje ze 100 kroplami (`START_WATER` w `scripts/main.gd`).
- **Paski życia:** pojawiają się tylko wtedy, gdy roślina/szkodnik są właśnie atakowani (znikają po ~2s bez trafienia).
- **Sterowanie:** tap-tap — tapnij kafelek rośliny w pionowym pasku po lewej (same ikonki, bez nazw, z kosztem na tle kropli), potem tapnij pole w ogrodzie; kafelek bez wystarczającej ilości wody jest przyciemniony, ale wciąż klikalny. Nawóz to taki sam kafelek pod ostatnią rośliną. Tapnij kroplę wody, żeby ją zebrać.
- **Poziomy:** 17 plansz (`LevelData.LEVELS` w `scripts/level_data.gd`), każdy z 4-6 falami mieszającymi pojedynczych szkodników i większe grupy — ostatnia fala na poziomie jest zawsze największa. Bossowie (`BossData.TYPES`) pojawiają się na poziomach 3, 5, 7, 9, 11, 13, 15, 17, na końcowych trzech (13, 15, 17) z podwyższonym HP (`boss_hp_multiplier`). Poziom odblokowuje się po ukończeniu poprzedniego.
- **Trudność rośnie stopniowo:** Kaktus produkuje wodę coraz wolniej (mnożnik odstępu czasu, `cactus_water_multiplier`, rośnie z każdym kolejnym poziomem), od poziomu 6 dochodzi nowy przeciwnik — **Brudna Gąbka** (`ENEMY_TYPES`, `water_thief`): po pojawieniu się na planszy przyciąga najbliższą wolną kroplę wody (przebarwia ją na brudno-zielono i powoli ściąga w swoją stronę); gracz wciąż może ją tapnąć i odzyskać, zanim dolatuje do gąbki — wtedy znika bez zwrotu wody. Od poziomu 8 dochodzą też pola na planszy, na których nie można sadzić roślin (`blocked_tiles`, zaznaczone czerwonym nakryciem na siatce).
- **Menu:** ekran startowy to przewijana w poziomie ścieżka poziomów (`LevelSelect.tscn`) — kółka poziomów połączone linią, z osobnymi kółkami na odblokowywane rośliny między nimi (jak mapa przygody w Plants vs. Zombies). Przed każdym poziomem pokazuje się ekran wyboru talii (`PlantSelect.tscn`, max 6 roślin), zapamiętywany osobno dla każdego poziomu.
- **Zapis postępu:** ukończone poziomy (`completed_levels`) i wybrane talie per poziom (`loadouts`) zapisywane lokalnie (`user://savegame.json`, wersja 2, przez `scripts/game_state.gd`, autoload `GameState`). Stary format zapisu (sprzed wersji z 17 poziomami) jest migrowany automatycznie przy wczytaniu.
- **Grafika:** wygenerowane ikony PNG w stylu naklejek (sticker, chibi-kawaii) w `assets/sprites/` — jedyny pozostały placeholder SVG to `icon.svg` (ikona gry).
- **Animacje:** proceduralne (Tween na sprite'ach + proste kształty rysowane w kodzie, bez dodatkowych plików graficznych) — wyrzut pocisku z Kukurydzy/Pokrzywy, cios pięścią Bitnego Brokułu, przelatująca chmurka Wichurowego, wybuch Bumorzecha, chodzenie i "jedzenie" wrogów, konfetti przy wygranej, duży śmieciostwór przy przegranej.

## Struktura projektu

```
junk-vs-plants/
  project.godot              - konfiguracja projektu Godot (autoload GameState, scena startowa LevelSelect)
  icon.svg                    - placeholder ikony gry
  scenes/LevelSelect.tscn      - ścieżka poziomów, przewijana w poziomie (scena startowa)
  scenes/PlantSelect.tscn      - ekran wyboru talii przed poziomem (max 6 roślin)
  scenes/Main.tscn             - scena rozgrywki (jeden poziom)
  scripts/level_select.gd      - logika przewijanej ścieżki poziomów
  scripts/plant_select.gd      - logika ekranu wyboru talii
  scripts/level_data.gd        - dane 17 poziomów (LevelData.LEVELS), używane przez Main i sciezke
  scripts/game_state.gd        - autoload: postęp gracza (ukończone poziomy, talie per poziom), zapis/odczyt
  scripts/plant_data.gd        - dane roślin (PlantData.TYPES, w tym unlock_level), używane przez Main, sciezke i PlantSelect
  scripts/boss_data.gd         - dane bossów (BossData.TYPES)
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
3. Naciśnij F5 (lub przycisk Play), żeby uruchomić grę w oknie na komputerze. Start to przewijana ścieżka poziomów.

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
