# Zadanie 08: podgląd ekranu drugiego gracza

**Status: ZREALIZOWANE (2026-11-05, bez testu na dwóch telefonach)**

## Cel

W trybie gry z innym graczem pokaż na dole ekranu mały podgląd planszy drugiego gracza, żeby było widać, co robi. Najwięcej da w rywalizacji (pojedynku), gdzie każdy ma własną planszę. We współpracy obaj widzą już tę samą planszę, więc podgląd jest tam niepotrzebny.

## Repozytorium i gałąź

- Repozytorium `JeanPaulSzefler/education-games`, projekt w `junk-vs-plants/`.
- Pracuj na gałęzi `jvp-notatki-2026-10-30`. Nie twórz nowej gałęzi, nie wypychaj na `master`, nie używaj `git push --force`.

## Gdzie umieścić zmiany

- `junk-vs-plants/scripts/main.gd`: tryb pojedynku (zmienna `duel`, funkcje `_setup_duel`, `_duel_send_enemy`) oraz gotowy wzór rysowania cudzej planszy z gry zespołowej (`_build_snapshot`, `_apply_snapshot`, `_make_enemy_view`, `_make_plant_view`).
- `junk-vs-plants/scripts/net_session.gd`: nowe wiadomości sieciowe (jak `send_duel_enemy`/`_rpc_duel_enemy`). Po zmianie protokołu podnieś `PROTOCOL_VERSION`.
- Nowy skrypt na podgląd może trafić do `junk-vs-plants/scripts/` (np. `friend_preview.gd`). Teksty dodaj w `junk-vs-plants/scripts/i18n/` we wszystkich 7 językach (kolejność pl, en, es, fr, de, pt, uk).

## Wymagania

1. Podgląd to zmniejszona plansza (ok. 1/4 rozmiaru) na dole ekranu, nie zasłania planszy gracza ani przycisków. Widać na niej rośliny, wrogów i licznik wody znajomego.
2. Telefon wysyła uproszczony stan swojej planszy kilka razy na sekundę (np. 4-5), tylko w trybie rywalizacji. Wysyłaj mało danych: rodzaj i pozycja roślin i wrogów, bez pasków życia i animacji.
3. Podgląd jest tylko do oglądania: dotyk nic w nim nie robi.
4. Po zakończeniu pojedynku albo rozłączeniu podgląd znika.
5. Nie zmieniaj działania gry we współpracy ani w grze jednoosobowej.
6. Sprawdź w Godocie (4.7), że gra się uruchamia bez błędów i że podgląd się odświeża.

## Po wykonaniu

1. Zmień status na górze tego pliku na `ZREALIZOWANE (RRRR-MM-DD, commit <skrót>)`.
2. Zmień status zadania 08 w `junk-vs-plants/zadania/README.md`.
3. Zakommituj zmiany razem z tym plikiem i wypchnij na `jvp-notatki-2026-10-30`.
4. W odpowiedzi napisz, co zrobiono i czego nie dało się sprawdzić (np. test na dwóch telefonach).

## Gdy zadania nie da się wykonać w całości

Zostaw status `NIEZREALIZOWANE`, opisz w odpowiedzi, co brakuje i dlaczego, i wypchnij tylko działające zmiany.
