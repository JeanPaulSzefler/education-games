# Zadanie dla ChatGPT: grafiki do gry Junk vs Plants (część 7)

## Cel

Wygeneruj grafiki z `GRAFIKI_PROMPTY_7.md` w trzech partiach, umieść je w repozytorium, zakommituj i wypchnij **każdą partię osobnym commitem**. Najpierw partia A (tła), bo autorka gry wybiera jedno z nich w ankiecie. Gra sama użyje każdego pliku, gdy znajdzie się on pod właściwą ścieżką, więc **nie zmieniaj kodu**.

## Repozytorium

- Repozytorium: `JeanPaulSzefler/education-games`
- Gałąź: `jvp-notatki-2026-10-30`. Pracuj na niej i nie twórz nowej.
- Projekt gry jest w podfolderze `junk-vs-plants/`, a grafiki w `junk-vs-plants/assets/sprites/ui/`.

## Co zrobić

1. Pobierz gałąź i przeczytaj `junk-vs-plants/GRAFIKI_PROMPTY_7.md`.
2. Jako wzoru stylu użyj `junk-vs-plants/assets/sprites/plants/cactus.png`.
3. Dla każdej partii: wygeneruj każdą grafikę osobno, przygotuj pliki według tabeli, sprawdź listę kontrolną, zakommituj i wypchnij.

## Partia A — tła (najpierw)

| Plik w `junk-vs-plants/assets/sprites/ui/` | Rozmiar | Przezroczystość |
|---|---|---|
| `bg_option_1.png` | 1280x720 | nie, obraz wypełnia całość |
| `bg_option_2.png` | 1280x720 | nie |
| `bg_option_3.png` | 1280x720 | nie |
| `bg_option_4.png` | 1280x720 | nie |

Generuj w 16:9 (np. 1920x1080), a potem zmniejsz dokładnie do 1280x720 px. Nie przycinaj obrazu w inny sposób. Commit: `Add background options for the main screen`.

## Partia B — grafiki interfejsu i dodatków

16 plików z partii B w `junk-vs-plants/assets/sprites/ui/`, nazwy jak w poleceniach (`settings_gear.png`, `addon_gift.png`, `education_bins.png`, `mode_coop.png`, `mode_duel.png`, `guide_arrow.png`, `tree_of_life.png`, `cage.png`, `animal_hedgehog.png`, `animal_bird.png`, `animal_frog.png`, `animal_butterfly.png`, `seed.png`, `watering_can.png`, `spider_web.png`, `house.png`). Przezroczyste tło, przycięcie do widocznej treści, najdłuższy bok maks. 512 px. Commit: `Add art for settings, extras, learning games and the guide`.

## Partia C — śmieci

39 plików `trash_<nazwa>.png` z partii C w `junk-vs-plants/assets/sprites/ui/`. Przezroczyste tło, przycięcie do treści, maks. 512 px. Commit: `Add trash item icons for the quiz and sorting games`.

## Wymagania techniczne

- Format PNG. Tła bez kanału alfa, pozostałe z prawdziwą przezroczystością (nie narysowaną szachownicą).
- Żadnych napisów, liter, cyfr ani znaków wodnych.
- Wszystkie grafiki mają wyglądać jak jeden zestaw, spójny z `cactus.png`.

## Czego nie robić

- Nie zmieniaj plików `.gd`, `.tscn`, `project.godot` ani istniejących grafik.
- Nie twórz pliku `background.png` - powstanie z tła wybranego w ankiecie.
- Nie dodawaj plików `.import` ani folderu `.godot/`. Godot tworzy je sam i są ignorowane przez Git.
- Nie dodawaj innych plików, np. wersji roboczych.
- Nie wypychaj na `master` i nie używaj `git push --force`.

## Lista kontrolna przed każdym commitem

- [ ] Pliki są dokładnie pod ścieżkami i nazwami z tej instrukcji.
- [ ] Tła mają dokładnie 1280x720 px, pozostałe grafiki najwyżej 512 px na dłuższym boku.
- [ ] Na żadnej grafice nie ma tekstu ani znaku wodnego.
- [ ] `git status` pokazuje tylko pliki z tej partii.

## Polecenia Git (przykład dla partii A)

```
git add junk-vs-plants/assets/sprites/ui/bg_option_1.png junk-vs-plants/assets/sprites/ui/bg_option_2.png junk-vs-plants/assets/sprites/ui/bg_option_3.png junk-vs-plants/assets/sprites/ui/bg_option_4.png
git commit -m "Add background options for the main screen"
git push origin jvp-notatki-2026-10-30
```

## Gdy zadania nie da się wykonać w całości

Jeśli nie możesz wygenerować grafiki albo nie masz dostępu do zapisu w repozytorium, nie pomijaj tego po cichu. Napisz, których plików brakuje i dlaczego. Wypchnij tylko pliki, które spełniają wymagania, bo gra używa rysunku zastępczego dla każdego brakującego pliku.
