# Przewodnik po grze — plan

Gra ma dużo elementów, więc nowy gracz poznaje je stopniowo. Na początku widzi tylko podstawy, a każda kolejna funkcja odblokowuje się po przejściu kilku poziomów ścieżki. Dane są w `scripts/guide_data.gd`, teksty w `scripts/i18n/guide.gd`.

## Jak to działa

- Przycisk funkcji, której gracz jeszcze nie odblokował, jest szary, z kłódką i podpisem „Poziom X”.
- Gdy funkcja się odblokuje, nad jej przyciskiem pojawia się podskakująca żółta strzałka. Strzałka pokazuje zawsze tylko jedną nową rzecz naraz. Następna pojawia się, gdy gracz otworzy poprzednią.
- Każda funkcja ma swój rozdział w „Opisie gry”. Opis pokazuje tylko odblokowane rozdziały, a nowe są oznaczone „Nowe!”. Na dole jest informacja, że kolejne rozdziały pojawią się w trakcie gry.
- Rozdziały bez osobnego przycisku (np. bossowie, nawozy) dostają strzałkę na „Opisie gry”.
- Ustawienia (język) i plakietka gracza są dostępne od początku.
- Na 1. poziomie, przy pierwszej grze na koncie, strzałka i napisy prowadzą przez pierwsze kroki: Kaktus, posadzenie, zbieranie kropli, Kukurydza.
- Konta założone przed tą zmianą widzą od razu wszystko, co odblokowały, ale strzałka i tak pokaże po kolei funkcje, których jeszcze nie obejrzały.

## Kolejność

| Po poziomie | Co się odblokowuje | Strzałka wskazuje | Dlaczego wtedy |
|---|---|---|---|
| od początku | Podstawy: cel gry, ścieżka, Kaktus i Kukurydza | Opis gry | Tyle wystarczy, żeby zagrać pierwszy poziom |
| 1 | Moje roślinki | Moje roślinki | Gracz zna już 2 roślinki i jest ciekawy kolejnych |
| 3 | Skrzynie, rubiny, sklep | Sklep | Za 3 poziomami czeka pierwsza skrzynia, a gracz ma już kilka rubinów |
| 4 | Gry edukacyjne | Gry edukacyjne | Krótkie gry o segregacji, bez walki, dają pierwsze sadzonki i roślimonety |
| 5 | Nowe roślinki na ścieżce | Opis gry | Przed poziomem 6 czeka pierwsza nowa roślinka (Liść Bananowca) |
| 6 | Bossowie | Opis gry | Poziom 6 ma pierwszego bossa |
| 7 | Wydarzenie tygodnia | Wydarzenie | Etapy wydarzeń dają sadzonki do ogrodu |
| 8 | Ogród | Ogród | Gracz ma już sadzonki z wydarzeń |
| 9 | Nawozy | Opis gry | Od poziomu 9 nawozy pojawiają się na planszy |
| 11 | Roślinne trójki | Roślinne trójki | Ruchy przychodzą już z ogrodu i za bossa |
| 12 | Kupki śmieci | Opis gry | Od poziomu 13 na planszy pojawiają się kupki |
| 13 | Ulepszenia roślin | Moje roślinki | Gracz ma dość rubinów i punktów z trójek |
| 15 | Gra z innym graczem | Gra z innym graczem | Gracz zna podstawy na tyle, żeby pomóc znajomemu |
| 17 | Dodatki | Dodatki | Nowe zasady i mini-gry, gdy podstawowa gra jest już opanowana |
| 25 | Siódme miejsce w talii | Opis gry | Od poziomu 25 gracz ma 7 roślinek |
| 60 | Tryb nieskończony | Opis gry | Odblokowuje się po ostatnim poziomie |
