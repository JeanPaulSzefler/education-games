# Transkrypcja notatek odręcznych — 2026-09-23

Źródło: `notatki/JvP_notatki_20260923.jpeg`

Zapis wierny treści kartki. Fragmenty nieczytelne oznaczone `[?]`.

---

## 1. Animacje — wykonalne?

- **Bitny Brokuł** razi pięściami.
- **Wichurowy** pokazuje przesuwającą się niebieską chmurkę.
- **Kukurydza i Pokrzywa** wyrzucają pociski — widać ruch rośliny przy strzale (jak w
  „Plants vs. Zombies"), a nie tylko pocisk pojawiający się w miejscu rośliny i lecący
  do przodu.
- **Bumorzech** pokazuje wybuch.
- **Wrogowie** ruszają nogami kiedy chodzą i otwierają buzię zjadając rośliny, do których dotarli.
- **Kiedy wygrana** — konfetti na cały ekran.
- **Kiedy przegrana** — duża ikonka śmieciostwora, który się przedostał.

## 2. Ekonomia / trudność

> Zmniejszenie ilości nagród, bo jest za łatwo.

Wyjaśnienie autora (2026-09-24):
- **kaktusy wolniej produkują krople wody**;
- **na początku poziomu gracz ma mniej kropel wody**.

## 3. Wybór roślin przed grą

> Zawsze przed grą gracz wybiera ze swoich roślinek **max. 6 rodzajów**, których będzie
> używał w tej grze.

## 4. Układ ekranu rozgrywki

Na kartce narysowane **dwa** szkice:

- **Szkic górny — PRZEKREŚLONY (X przez całość):** obecny układ, czyli siatka ogrodu
  na całej szerokości + **poziomy pasek przycisków roślin na dole** ekranu. Do usunięcia.
- **Szkic dolny — obowiązujący:** **pionowy pasek roślin po LEWEJ stronie** ekranu,
  obok niego węższa siatka ogrodu. Pasek to lista wierszy, każdy wiersz = ikonka rośliny
  + prostokącik z kosztem:

  | Roślina | Koszt na szkicu |
  |---|---|
  | Kukurydza | 50 |
  | Kaktus | `[?]` (poprawiane, ~15–25) |
  | Liść bananowca | `[?]` (poprawiane, ~50) |
  | Bitny Brokuł | 60 |
  | Mrozoroślinka | 70 `[?]` |
  | (6. wiersz bez podpisu) | 30 |

  Pod spodem, w nawiasie, osobno: `( [50] [60] )` z podpisem **„Bumorzech, Wichurowy"**.

  **Uwaga:** liczby w prostokątach są wielokrotnie poprawiane i nie da się ich odczytać
  jednoznacznie. Traktować jako *intencję zmiany kosztów*, nie jako gotową tabelę.

- Dopisek w kółku ze strzałką do paska roślin: **„Obrazki, a nie napisy"** — przyciski
  roślin mają być ikonkami, nie tekstem.
- Dopisek obok: **„i zamienić ilość kropel potrzebnych"** — przy okazji zmienić koszty.

## 5. Ścieżka poziomów, na której odblokowują się roślinki

(`-"-` = to samo, co w wierszu wyżej)

| Poziom | Dostępne roślinki |
|---|---|
| 1 | Kukurydza, Kaktus, ~~Liść bananowca~~ *(skreślone)* |
| 2 | `-"-`, `-"-`, `-"-` |
| 3 | Kukurydza, Kaktus, Liść bananowca |
| 4 | `-"-`, `-"-`, `-"-` |
| 5 | `-"-`, `-"-`, `-"-`, **Mrozoroślinka** |
| 6 | `-"-`, `-"-`, `-"-` |
| 7 | `-"-`, `-"-`, `-"-`, `-"-`, **Wichurowy** |
| 8 | `-"-` |
| 9 | `-"-`, **Bumorzech** |
| 10 | `-"-` |
| 11 | `-"-` |
| 12 | `-"-`, **Bitny Brokuł** |
| 13 | `-"-`, `-"-`, `-"-` |
| 14 | `-"-` |
| 15 | `-"-` |
| 16 | **Pokrzywa**, `-"-` |
| 17 | `-"-`, `-"-`, `-"-` |

Wniosek (po poprawce tabeli, 2026-09-24): docelowo **17 poziomów**. Na poziomach 1–2
tylko Kukurydza i Kaktus; kolejne rośliny dochodzą na poziomach 3, 5, 7, 9, 12 i 16.
Wszystkie 8 dostępne od poziomu 16.

Dopowiedzenia autora (2026-09-24):
- Zdobyte roślinki **zostają na zawsze** — przy powtórce wcześniejszego poziomu gracz
  ma do dyspozycji wszystko, co już odblokował (wybierając max. 6, patrz pkt 3).
- Bossowie **co drugi poziom: 3, 5, 7, 9, 11, 13, 15, 17** — poziomy 1 i 2 bez bossa,
  ostatni poziom (17) z bossem. Poziom z bossem ma mieć **oznaczenie na ścieżce**.
- Bossowie powtórzeni z **podbitym HP** występują na **późniejszych poziomach**
  (13, 15, 17) — mają być ostatni i najtrudniejsi.
- **Ostatnia fala każdego poziomu jest większa niż zwykłe.** Na poziomie bez bossa —
  wyraźnie większa; na poziomie z bossem — tylko trochę większa (boss i tak podnosi
  trudność finału).

## 6. Ilustracja: początek ścieżki sukcesów

Źródło: `notatki/JvP_notatki_20260923_dod.jpeg`

Zdjęcie jest obrócone o 90° (cyfry leżą na boku). Po obróceniu ścieżka biegnie
**poziomo, od lewej do prawej**:

```
( 1 ) ——— ( roślinka ) ——— ( 2 ) ——— ( … )
```

- Węzły to kółka połączone linią.
- **Kółko z cyfrą** = poziom (1, 2, …).
- **Kółko z ikonką** między poziomami = osobny węzeł **odblokowania roślinki**
  (potwierdzone przez autora). W kółku ma być **ikonka tej roślinki, która w tym
  miejscu się odblokowuje** — na szkicu narysowana schematycznie.
- `(…)` = ścieżka ciągnie się dalej.
