# Zadanie 09: grafiki do gry Junk vs Plants (część 8)

**Status: ZREALIZOWANE (2026-11-05)**

## Cel

Wygeneruj 3 grafiki z `GRAFIKI_PROMPTY_8.md`, umieść je w repozytorium, zakommituj i wypchnij jednym commitem. Gra sama użyje każdego pliku, gdy znajdzie się pod właściwą ścieżką, więc **nie zmieniaj kodu**.

## Repozytorium

- Repozytorium: `JeanPaulSzefler/education-games`
- Gałąź: `jvp-notatki-2026-10-30`. Pracuj na niej i nie twórz nowej.
- Projekt gry jest w podfolderze `junk-vs-plants/`, a grafiki w `junk-vs-plants/assets/sprites/ui/`.

## Co zrobić

1. Pobierz gałąź i przeczytaj `junk-vs-plants/GRAFIKI_PROMPTY_8.md`.
2. Jako wzoru stylu użyj `junk-vs-plants/assets/sprites/plants/cactus.png`.
3. Wygeneruj każdą grafikę osobno i przygotuj pliki według tabeli.

| Plik w `junk-vs-plants/assets/sprites/ui/` | Rozmiar | Przezroczystość |
|---|---|---|
| `bg_yard.png` | 1280x720 | nie, obraz wypełnia całość |
| `bg_leaves.png` | 1280x720 | nie |
| `lawnmower.png` | najdłuższy bok maks. 512 px, przycięta do treści | tak, prawdziwa |

Tła generuj w 16:9 (np. 1920x1080), a potem zmniejsz dokładnie do 1280x720 px. Nie przycinaj ich w inny sposób.

Commit: `Add backyard and leaf backgrounds and the lawn mower`.

## Wymagania techniczne

- Format PNG. Tła bez kanału alfa, kosiarka z prawdziwą przezroczystością (nie narysowaną szachownicą).
- Żadnych napisów, liter, cyfr ani znaków wodnych.
- Grafiki mają wyglądać jak jeden zestaw, spójny z `cactus.png`. Tła mają być średnio ciemne i spokojne, bo gra rysuje na nich białe napisy.

## Czego nie robić

- Nie zmieniaj plików `.gd`, `.tscn`, `project.godot` ani istniejących grafik (także `background.png`).
- Nie dodawaj plików `.import` ani folderu `.godot/`.
- Nie dodawaj innych plików, np. wersji roboczych.
- Nie wypychaj na `master` i nie używaj `git push --force`.

## Lista kontrolna przed commitem

- [x] Pliki są dokładnie pod ścieżkami i nazwami z tabeli.
- [x] Tła mają dokładnie 1280x720 px, kosiarka najwyżej 512 px na dłuższym boku.
- [x] Na żadnej grafice nie ma tekstu ani znaku wodnego.
- [x] Przed aktualizacją statusów `git status` pokazywał tylko te 3 pliki.

## Wynik

Dodano oba tła jako PNG RGB 1280x720 oraz kosiarkę jako PNG RGBA 512x425,
przyciętą do treści. Godot 4.6.3 potwierdził użycie obu teł i tekstury pięciu
kosiarek na planszy oraz uruchomienie kosiarki. Przeszedł również test profilu,
12 scen, sadzenia rośliny i pojawiania się przeciwników. Kod gry i istniejące
grafiki pozostały bez zmian. Eksportu APK nie testowano; import nadal zgłasza
znaną niezgodność `preset.0/runnable` z dostępną wersją Godota.
