# Zadanie dla ChatGPT: grafiki do gry Junk vs Plants (część 6)

## Cel

Wygeneruj 7 plików graficznych z `GRAFIKI_PROMPTY_6.md`, umieść je w repozytorium, zakommituj i wypchnij. Gra sama użyje każdego pliku, gdy znajdzie się on pod właściwą ścieżką, więc **nie zmieniaj kodu**.

## Repozytorium

- Repozytorium: `JeanPaulSzefler/education-games`
- Gałąź: `jvp-notatki-2026-10-30`. Pracuj na niej i nie twórz nowej.
- Projekt gry jest w podfolderze `junk-vs-plants/`.

## Co zrobić

1. Pobierz gałąź i przeczytaj `junk-vs-plants/GRAFIKI_PROMPTY_6.md`. Blok kodu w tym pliku zawiera wspólny styl i opis każdej grafiki.
2. Jako wzoru stylu użyj `junk-vs-plants/assets/sprites/plants/cactus.png`. Do grafik 6 i 7 użyj też `junk-vs-plants/assets/sprites/plants/nettle.png` (kształt liści) i `junk-vs-plants/assets/sprites/ui/sapling.png` (ziemia).
3. Wygeneruj każdą grafikę osobno, dokładnie według opisu.
4. Przygotuj pliki według wymagań poniżej i zapisz je pod ścieżkami z tabeli.
5. Sprawdź listę kontrolną.
6. Zakommituj i wypchnij pliki na tę samą gałąź.

## Pliki

Ścieżki są podane względem katalogu głównego repozytorium.

| Nr | Ścieżka | Do czego służy | Przezroczyste tło | Przycięcie do treści |
|---|---|---|---|---|
| 1 | `junk-vs-plants/assets/sprites/ui/match_event.png` | przycisk Roślinnych trójek na ścieżce | tak | tak |
| 2 | `junk-vs-plants/assets/sprites/ui/match_move.png` | ikonka ruchu (licznik, skrzynia, ogród) | tak | tak |
| 3 | `junk-vs-plants/assets/sprites/ui/match_cell.png` | pole planszy trójek | nie, trawa wypełnia cały obraz | nie |
| 4 | `junk-vs-plants/assets/sprites/ui/match_pop.png` | rozbłysk, gdy roślinki znikają | tak | tak |
| 5 | `junk-vs-plants/assets/sprites/ui/rent_slot.png` | przycisk wypożyczenia 7. miejsca | tak | tak |
| 6 | `junk-vs-plants/assets/sprites/ui/garden_stage_1.png` | 1. etap wzrostu w ogrodzie | tak | nie, kwadrat, ziemia przy dolnej krawędzi |
| 7 | `junk-vs-plants/assets/sprites/ui/garden_stage_2.png` | 2. etap wzrostu w ogrodzie | tak | nie, kwadrat, ziemia przy dolnej krawędzi |

## Wymagania techniczne

- Format PNG, kanał alfa tam, gdzie tabela tego wymaga.
- Najdłuższy bok maks. 512 px. Generuj w 1024x1024 px, a potem przytnij (jeśli tabela tak mówi) i zmniejsz.
- Grafiki 6 i 7 muszą być kwadratowe (512x512) i mieć kopczyk ziemi na środku dolnej krawędzi, w tym samym miejscu na obu. Gra płynnie przenika sadzonkę w etap 1, etap 1 w etap 2 i etap 2 w dorosłą Pokrzywę, więc ziemia nie może skakać między etapami.
- Żadnych napisów, liter, cyfr ani znaków wodnych.
- Wszystkie grafiki mają wyglądać jak jeden zestaw, spójny z `cactus.png`.

## Czego nie robić

- Nie zmieniaj plików `.gd`, `.tscn`, `project.godot` ani istniejących grafik.
- Nie dodawaj plików `.import` ani folderu `.godot/`. Godot tworzy je sam i są ignorowane przez Git.
- Nie dodawaj innych plików, np. wersji roboczych.
- Nie wypychaj na `master` i nie używaj `git push --force`.

## Lista kontrolna przed commitem

- [ ] Jest 7 plików, dokładnie pod ścieżkami z tabeli.
- [ ] Pliki 1, 2, 4, 5, 6 i 7 mają naprawdę przezroczyste tło, a nie narysowaną szachownicę.
- [ ] `match_cell.png` jest wypełniony trawą od krawędzi do krawędzi.
- [ ] `garden_stage_1.png` i `garden_stage_2.png` są kwadratowe, a ziemia na obu jest w tym samym miejscu.
- [ ] Żaden plik nie ma boku większego niż 512 px.
- [ ] Na żadnej grafice nie ma tekstu ani znaku wodnego.
- [ ] `git status` pokazuje tylko te 7 plików.

## Commit i push

```
git add junk-vs-plants/assets/sprites/ui/match_event.png junk-vs-plants/assets/sprites/ui/match_move.png junk-vs-plants/assets/sprites/ui/match_cell.png junk-vs-plants/assets/sprites/ui/match_pop.png junk-vs-plants/assets/sprites/ui/rent_slot.png junk-vs-plants/assets/sprites/ui/garden_stage_1.png junk-vs-plants/assets/sprites/ui/garden_stage_2.png
git commit -m "Add generated art for the match puzzle, garden growth and slot rental"
git push origin jvp-notatki-2026-10-30
```

## Gdy zadania nie da się wykonać w całości

Jeśli nie możesz wygenerować grafiki albo nie masz dostępu do zapisu w repozytorium, nie pomijaj tego po cichu. Napisz, których plików brakuje i dlaczego. Wypchnij tylko te pliki, które spełniają wymagania, bo gra używa rysunku zastępczego dla każdego brakującego pliku.
