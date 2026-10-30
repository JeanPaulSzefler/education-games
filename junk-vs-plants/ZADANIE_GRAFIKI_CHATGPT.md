# Zadanie dla ChatGPT: grafiki do gry Junk vs Plants

## Cel

Wygeneruj 12 plików graficznych z `GRAFIKI_PROMPTY_5.md`, umieść je w repozytorium, zakommituj i wypchnij. Gra sama użyje każdego pliku, gdy znajdzie się on pod właściwą ścieżką, więc **nie zmieniaj kodu**.

## Repozytorium

- Repozytorium: `JeanPaulSzefler/education-games`
- Gałąź: `jvp-notatki-2026-10-30`. Pracuj na niej i nie twórz nowej.
- Projekt gry jest w podfolderze `junk-vs-plants/`.

## Co zrobić

1. Pobierz gałąź i przeczytaj `junk-vs-plants/GRAFIKI_PROMPTY_5.md`. Blok kodu w tym pliku zawiera wspólny styl i opis każdej grafiki.
2. Jako wzoru stylu użyj `junk-vs-plants/assets/sprites/plants/cactus.png`.
3. Wygeneruj każdą grafikę osobno, dokładnie według opisu.
4. Przygotuj pliki według wymagań poniżej i zapisz je pod ścieżkami z tabeli.
5. Sprawdź listę kontrolną.
6. Zakommituj i wypchnij pliki na tę samą gałąź.

## Pliki

Ścieżki są podane względem katalogu głównego repozytorium.

| Nr | Ścieżka | Przezroczyste tło | Przycięcie do treści |
|---|---|---|---|
| 1 | `junk-vs-plants/assets/sprites/plants/mega_cactus.png` (nadpisz istniejący) | tak | tak |
| 2 | `junk-vs-plants/assets/sprites/ui/chest.png` | tak | tak |
| 3 | `junk-vs-plants/assets/sprites/ui/plant_coin.png` | tak | tak |
| 4 | `junk-vs-plants/assets/sprites/ui/ruby.png` | tak | tak |
| 5 | `junk-vs-plants/assets/sprites/ui/sapling.png` | tak | tak |
| 6 | `junk-vs-plants/assets/sprites/ui/bee.png` | tak | tak |
| 7 | `junk-vs-plants/assets/sprites/ui/event_star.png` | tak | tak |
| 8 | `junk-vs-plants/assets/sprites/ui/padlock.png` | tak | tak |
| 9 | `junk-vs-plants/assets/sprites/ui/book.png` | tak | tak |
| 10 | `junk-vs-plants/assets/sprites/ui/shop_basket.png` | tak | tak |
| 11 | `junk-vs-plants/assets/sprites/ui/soil_plot.png` | nie, cały obraz wypełnia grządka | nie |
| 12 | `junk-vs-plants/assets/sprites/ui/fog.png` | częściowo, mgła ma krycie ok. 85% | nie |

## Wymagania techniczne

- Format PNG, kanał alfa tam, gdzie tabela tego wymaga.
- Najdłuższy bok maks. 512 px. Generuj w 1024x1024 px, a potem przytnij i zmniejsz.
- Żadnych napisów, liter, cyfr ani znaków wodnych.
- `fog.png` musi łączyć się bez widocznych szwów na wszystkich czterech krawędziach, bo gra układa go kafelkami.
- Wszystkie grafiki mają wyglądać jak jeden zestaw, spójny z `cactus.png`.

## Czego nie robić

- Nie zmieniaj plików `.gd`, `.tscn`, `project.godot` ani istniejących grafik poza `mega_cactus.png`.
- Nie dodawaj plików `.import` ani folderu `.godot/`. Godot tworzy je sam i są ignorowane przez Git.
- Nie dodawaj innych plików, np. wersji roboczych.
- Nie wypychaj na `master` i nie używaj `git push --force`.

## Lista kontrolna przed commitem

- [ ] Jest 12 plików, dokładnie pod ścieżkami z tabeli.
- [ ] Pliki od 1 do 10 mają naprawdę przezroczyste tło, a nie narysowaną szachownicę.
- [ ] Żaden plik nie ma boku większego niż 512 px.
- [ ] Na żadnej grafice nie ma tekstu ani znaku wodnego.
- [ ] `git status` pokazuje tylko te 12 plików.

## Commit i push

```
git add junk-vs-plants/assets/sprites/plants/mega_cactus.png junk-vs-plants/assets/sprites/ui/chest.png junk-vs-plants/assets/sprites/ui/plant_coin.png junk-vs-plants/assets/sprites/ui/ruby.png junk-vs-plants/assets/sprites/ui/sapling.png junk-vs-plants/assets/sprites/ui/bee.png junk-vs-plants/assets/sprites/ui/event_star.png junk-vs-plants/assets/sprites/ui/padlock.png junk-vs-plants/assets/sprites/ui/book.png junk-vs-plants/assets/sprites/ui/shop_basket.png junk-vs-plants/assets/sprites/ui/soil_plot.png junk-vs-plants/assets/sprites/ui/fog.png
git commit -m "Add generated art for icons, chest, coin, garden, fog and Megakaktus"
git push origin jvp-notatki-2026-10-30
```

## Gdy zadania nie da się wykonać w całości

Jeśli nie możesz wygenerować grafiki albo nie masz dostępu do zapisu w repozytorium, nie pomijaj tego po cichu. Napisz, których plików brakuje i dlaczego. Wypchnij tylko te pliki, które spełniają wymagania, bo gra używa rysunku zastępczego dla każdego brakującego pliku.
