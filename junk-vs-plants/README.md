# Junk vs Plants

Prototyp gry typu tower-defense (na wzór Plants vs Zombies) na Androida.
Rośliny bronią ogrodu przed falami śmieci-stworów.

## Ustalenia projektowe (MVP)

- **Silnik:** Godot 4.x (projekt tworzony na 4.4, ale zadziała na dowolnej nowszej wersji 4.x)
- **Przeciwnicy:** mix śmieci — Butelka PET, Puszka, Kartonowy Golem (dane w `scripts/main.gd`, `ENEMY_TYPES`)
- **Rośliny:** Kaktus (strzelec), Liść Bananowca (blokada, duża wytrzymałość, nie atakuje) — `PLANT_TYPES`
- **Waluta:** krople wody, dopływ pasywny co 5s (docelowo: osobna roślina-generator)
- **Sterowanie:** tap-tap — tapnij przycisk rośliny na dole, potem tapnij pole w ogrodzie
- **Plansze:** obecnie 1 plansza / 3 fale w kodzie; docelowo 3-5 plansz
- **Grafika:** proste, płaskie ikony SVG (rośliny, śmieci-stwory, pociski, trawa) w `assets/sprites/` — patrz sekcja niżej

## Struktura projektu

```
junk-vs-plants/
  project.godot        - konfiguracja projektu Godot
  icon.svg              - placeholder ikony gry
  scenes/Main.tscn       - scena startowa
  scripts/main.gd        - cała logika gry (siatka, ekonomia, fale, walka)
  assets/sprites/plants  - grafiki roślin (cactus.svg, banana_leaf.svg)
  assets/sprites/enemies - grafiki śmieci-stworów (bottle.svg, can.svg, cardboard_golem.svg)
  assets/sprites/ui      - grafiki interfejsu (thorn.svg - pocisk, grass_tile.svg - podłoże)
  assets/sounds          - dźwięki/muzyka
  levels/                - miejsce na dane kolejnych plansz
```

## Jak otworzyć i testować

1. Zainstaluj [Godot](https://godotengine.org/download) — dowolna aktualna wersja 4.x (wersja Standard, nie .NET).
2. Otwórz Godota → "Import" → wskaż folder `junk-vs-plants` (plik `project.godot`).
3. Naciśnij F5 (lub przycisk Play), żeby uruchomić grę w oknie na komputerze.

## Jak zbudować APK na Androida

1. W Godot: **Editor → Manage Export Templates** → pobierz szablony eksportu dopasowane do wersji Godota, której używasz.
2. Zainstaluj Android SDK + Java JDK (Godot poprowadzi przez to w **Editor → Editor Settings → Export → Android**, gdzie wskazuje się ścieżki do `Android SDK` i `debug.keystore`; Godot potrafi wygenerować domyślny debug keystore jednym kliknięciem).
3. **Project → Export...** → dodaj preset "Android" → **Export Project** → zapisz plik `.apk`.
4. Przenieś `.apk` na telefon (kabel/USB, Google Drive, itp.) i zainstaluj (włącz "Instalacja z nieznanych źródeł" w ustawieniach Androida), albo użyj `adb install junk-vs-plants.apk` po podłączeniu telefonu kablem z włączonym trybem debugowania USB.

## Co dalej (kolejne kroki rozwoju)

- Grafiki obecnie to proste, płaskie ikony SVG narysowane jako placeholder stylu docelowego — do zastąpienia docelową grafiką/animacjami (np. z Aseprite lub grafika zlecona artyście)
- Dodanie 2-3 kolejnych roślin i przeciwników zgodnie z ustalonym zakresem MVP (4-5 roślin, 3-4 przeciwników)
- Ekran menu głównego i wyboru poziomu (docelowo 3-5 plansz)
- Dźwięki (sadzenie, trafienie, wygrana/przegrana)
- Zapis postępu gracza (odblokowane rośliny/poziomy)
