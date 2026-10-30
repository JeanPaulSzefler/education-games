# Wydarzenia — Junk vs Plants

Lista zatwierdzona w ankiecie (2026-10-30). Wydarzenia pojawiają się po kolei, każde na tydzień, i znikają razem z postępami; sadzonki i waluty zostają. Kolejność i zasady są w `scripts/event_data.gd`.

Każde wydarzenie ma 5 etapów o rosnącej trudności (trudność poziomów 2, 6, 12, 21 i 36). Jeśli nie napisano inaczej, pierwsze przejścia etapów dają 2/2/3/3/4 sadzonki, a powtórka 1. Pomoc kupuje się przed etapem i działa tylko na to wejście.

| Nr | Nazwa | Sadzenie | Na czym polega | Pomoc za roślimonety | Dodatkowa nagroda |
|---|---|---|---|---|---|
| 0 | Taśma roślin | z taśmy | Rośliny same pojawiają się na pasku | brak | – |
| 1 | Krople z nieba | standardowe | Bez Kaktusów; krople spadają co 6-11 s, coraz rzadziej | 50: 50 kropel na start | – |
| 2 | Nocny ogród | standardowe | Widać tylko pola wokół roślin i wrogów na nich | 40: latarnia na rząd wskazany tapnięciem | – |
| 3 | Mgła | z taśmy | Prawe 5 kolumn pod mgłą: 20 s mgły, 5 s przerwy | 30: podmuch rozwiewa mgłę na 10 s | – |
| 4 | Wielkie sprzątanie | z taśmy | 3-7 kupek na start; zniszczenie wszystkich to wygrana | 40: Pnącza na start | 1 rubin za ostatni etap |
| 5 | Mali, ale szybcy | z taśmy | Połowa życia, 2 razy większa prędkość | 40: Mrozoroślinka gotowa od razu | – |
| 6 | Olbrzymy | standardowe | Połowa wrogów, 3 razy więcej życia, prędkość 70% | 50: darmowy Bumorzech raz na etap | – |
| 7 | Wąskie gardło | standardowe | 2 razy więcej wrogów, tylko rzędami 2 i 3 | 30: dodatkowy nawóz na start | – |
| 8 | Narzucona talia | standardowe | 3 wylosowane rośliny, zawsze z Kaktusem albo Megakaktusem | 40: czwarta roślina do wyboru | – |
| 9 | Żadnych strat | standardowe | Strata rośliny kończy etap; tylko ostatnie 3 fale | 50: tarcza raz ratuje roślinę | 2 rubiny za ostatni etap |
| 10 | Wyścig | z taśmy | Limit czasu; 1-3 gwiazdki | 30: 20 s więcej | sadzonka za każdą nową gwiazdkę, zamiast 2/2/3/3/4 |
| 11 | Szalony nawóz | z taśmy | Nawóz co 8 s, bez limitu; wrogowie mają 1,5 raza więcej życia | brak | – |
| 12 | Boss za bossem | standardowe | 2-5 bossów po kolei, każdy silniejszy, 12 s przerwy | 60: 100 kropel między bossami | 3 rubiny za ostatni etap |
| 13 | Łowy na roślimonety | standardowe | Wrogowie upuszczają monety po 5 (szansa 25%); etapy otwarte od razu | brak | sadzonki 2/2/3/3/4 za progi 50/150/300/500/800 monet, zamiast nagród za etapy |
| 14 | Taśma z podglądem | z taśmy | Widać 3 kolejne rośliny | 20 za wymianę rośliny, każdą raz, w trakcie gry | – |

## Kod testowy

Na plakietce każdego konta jest przycisk „Kod testowy”. Poprawny kod pozwala raz zmienić bieżące wydarzenie na dowolne inne, a kolejna zmiana wymaga ponownego wpisania kodu. Gracz decyduje, czy postępy z opuszczanego wydarzenia mają się zapisać. Zapisane wracają przy ponownym przejściu na to wydarzenie kodem. Wybrane wydarzenie startuje z pełnym tygodniem, a potem gra przechodzi do następnego w kolejności. Po 3 nieudanych próbach z rzędu opcja blokuje się na 10 minut na całym telefonie, niezależnie od konta. W repozytorium jest tylko skrót kodu (`TEST_CODE_SHA256` w `scripts/game_state.gd`). **Przed wydaniem gry ten kod trzeba usunąć.**

## Sadzenie razem (opcja w tygodniu Łowów)

To nie jest osobny tydzień. Podczas Łowów ogród pyta gracza, czy chce sadzić razem ze znajomym. Dzięki temu w tym tygodniu sadzonki można zdobywać w Łowach.

Po zatwierdzeniu ogród działa dalej, a na ekranie pojawia się przycisk „Sadzimy razem”, który łączy z osobą w tej samej sieci Wi-Fi. Połączeni gracze wysyłają sobie sadzonki: jedna dziennie za darmo, każda następna za 30 roślimonet. Zbiory obojga liczą się do wspólnego celu 8 roślinek. Po jego osiągnięciu każdy dostaje 4 sadzonki.
