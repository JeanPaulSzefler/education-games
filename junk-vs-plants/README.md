# Junk vs Plants

Prototyp gry typu tower-defense (na wzór Plants vs Zombies) na Androida.
Rośliny bronią ogrodu przed falami śmieci-stworów.

## Ustalenia projektowe (MVP)

- **Silnik:** Godot 4.x (projekt tworzony na 4.4/4.7, zadziała na dowolnej nowszej wersji 4.x)
- **Orientacja i plansza:** ekran poziomy (landscape, 1280x720), szersza siatka ogrodu (13 kolumn x 5 wierszy zamiast pierwotnych 8x5) — więcej miejsca na taktykę dzięki szerszemu ekranowi.
- **Przeciwnicy:** mix śmieci — Butelka PET, Puszka, Kartonowy Golem (dane w `scripts/main.gd`, `ENEMY_TYPES`). Szkodnik, który dotrze do rośliny, "zjada" ją stopniowo (odgryza kawałek HP co jakiś czas), a nie rani jej od razu.
- **Rośliny** (dane w `scripts/plant_data.gd`, `PlantData.TYPES`):
  - **Kukurydza** — strzelec, atakuje szkodnika w swoim rzędzie.
  - **Kaktus** — generator wody: co jakiś czas tworzy kropelkę wody obok siebie.
  - **Liść Bananowca** — blokada, dużo więcej HP niż inne rośliny (dłużej się "je"), sama nie atakuje.
- **Waluta:** krople wody unoszące się nad ekranem — zbierane tapnięciem, zanim znikną. Powstają z Kaktusa.
- **Paski życia:** pojawiają się tylko wtedy, gdy roślina/szkodnik są właśnie atakowani (znikają po ~2s bez trafienia).
- **Sterowanie:** tap-tap — tapnij przycisk rośliny na dole, potem tapnij pole w ogrodzie; tapnij kroplę wody, żeby ją zebrać.
- **Poziomy:** 5 plansz (`LEVELS` w `scripts/main.gd`), każda z 5 falami mieszającymi pojedynczych szkodników i większe grupy — ostatnia fala na poziomie jest zawsze największa. Każdy kolejny poziom odblokowuje się po ukończeniu poprzedniego.
- **Trudność rośnie na poziomach 4-5:** Kaktus produkuje wodę wolniej (mnożnik odstępu czasu, `cactus_water_multiplier`), od poziomu 5 dochodzą też pola na planszy, na których nie można sadzić roślin (`blocked_tiles`, zaznaczone czerwonym nakryciem na siatce), a od poziomu 4 pojawia się nowy przeciwnik — **Brudna Gąbka** (`ENEMY_TYPES`, `water_thief`): po pojawieniu się na planszy przyciąga najbliższą wolną kroplę wody (przebarwia ją na brudno-zielono i powoli ściąga w swoją stronę); gracz wciąż może ją tapnąć i odzyskać, zanim dolatuje do gąbki — wtedy znika bez zwrotu wody.
- **Menu:** ekran wyboru poziomu (`LevelSelect.tscn`) + ścieżka sukcesów (`ProgressPath.tscn`) pokazująca zdobyte rośliny i zablokowane sloty na przyszłe (typy/działanie tych roślin ustalimy przy kolejnych aktualizacjach).
- **Zapis postępu:** odblokowane poziomy zapisywane lokalnie (`user://savegame.json` przez `scripts/game_state.gd`, autoload `GameState`).
- **Grafika:** wygenerowane ikony PNG w stylu naklejek (sticker, chibi-kawaii) w `assets/sprites/` — jedyny pozostały placeholder SVG to `icon.svg` (ikona gry).

## Struktura projektu

```
junk-vs-plants/
  project.godot              - konfiguracja projektu Godot (autoload GameState, scena startowa LevelSelect)
  icon.svg                    - placeholder ikony gry
  scenes/LevelSelect.tscn      - ekran wyboru poziomu (scena startowa)
  scenes/ProgressPath.tscn     - ścieżka sukcesów (odblokowane/zablokowane rośliny)
  scenes/Main.tscn             - scena rozgrywki (jeden poziom)
  scripts/level_select.gd      - logika ekranu wyboru poziomu
  scripts/progress_path.gd     - logika ścieżki sukcesów
  scripts/game_state.gd        - autoload: postęp gracza (odblokowane poziomy), zapis/odczyt
  scripts/plant_data.gd        - dane roślin (PlantData.TYPES), używane przez Main i ProgressPath
  scripts/main.gd              - logika rozgrywki (siatka, fale, ekonomia wody, walka, zjadanie, paski życia)
  assets/sprites/plants        - grafiki roślin (corn.svg, cactus.svg, banana_leaf.svg)
  assets/sprites/enemies       - grafiki śmieci-stworów (bottle.svg, can.svg, cardboard_golem.svg)
  assets/sprites/ui            - grafiki interfejsu (thorn.svg, water_drop.svg, grass_tile.svg, locked_slot.svg)
  assets/sounds                - dźwięki/muzyka
  levels/                      - zarezerwowane na przyszłość (osobne pliki danych poziomów)
```

## Jak otworzyć i testować

1. Zainstaluj [Godot](https://godotengine.org/download) — dowolna aktualna wersja 4.x (wersja Standard, nie .NET).
2. Otwórz Godota → "Import" → wskaż folder `junk-vs-plants` (plik `project.godot`).
3. Naciśnij F5 (lub przycisk Play), żeby uruchomić grę w oknie na komputerze. Start to ekran wyboru poziomu.

## Jak zbudować APK na Androida

1. W Godot: **Editor → Manage Export Templates** → pobierz szablony eksportu dopasowane do wersji Godota, której używasz.
2. Zainstaluj Android SDK + Java JDK (Godot poprowadzi przez to w **Editor → Editor Settings → Export → Android**, gdzie wskazuje się ścieżki do `Android SDK` i `debug.keystore`; Godot potrafi wygenerować domyślny debug keystore jednym kliknięciem).
3. **Project → Export...** → dodaj preset "Android" → **Export Project** → zapisz plik `.apk`.
4. Przenieś `.apk` na telefon (kabel/USB, Google Drive, itp.) i zainstaluj (włącz "Instalacja z nieznanych źródeł" w ustawieniach Androida), albo użyj `adb install junk-vs-plants.apk` po podłączeniu telefonu kablem z włączonym trybem debugowania USB.

## Co dalej (kolejne kroki rozwoju)

- Animacje grafik (obecnie statyczne ikony PNG) — sadzenie, atak, zbieranie wody, śmierć
- Ustalenie typów i działania kolejnych roślin na zablokowanych slotach ścieżki sukcesów
- Dźwięki (sadzenie, trafienie, zbieranie wody, wygrana/przegrana)
- Ekran główny/tytułowy przed ekranem wyboru poziomu

## Zapisane pomysły na później

- Połączenie ekranu wyboru poziomu i ścieżki sukcesów w jedną planszę-ścieżkę — tak żeby przy niektórych poziomach było widać, jaka nowa roślinka się po nich odblokowuje
- Burza mózgów: nowe roślinki oraz nowe etapy z silniejszymi przeciwnikami (bossowie)
