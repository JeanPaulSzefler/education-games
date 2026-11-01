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

## Roślinne trójki (wydarzenie stałe)

Nie jest częścią tygodniowej kolejki. Przycisk jest zawsze u góry ścieżki i pokazuje liczbę ruchów. Plansza 8x6 jest pełna wszystkich 14 roślin, a śmieciostwory nie przychodzą. Gracz zamienia dwie sąsiednie roślinki tak, żeby co najmniej 3 takie same stanęły w rzędzie lub kolumnie. Wtedy znika cała grupa stykających się roślinek tego rodzaju, a roślina dostaje punkty: 3-4 roślinki to 1 punkt, 5-6 to 2, 7-8 to 3. 8 punktów zamienia się w jedno ulepszenie tej rośliny, także jeszcze nieodblokowanej. Zamiana, która nie układa trójki, nie zużywa ruchu. Ruchy: 1 za każdą roślinkę zebraną w ogrodzie (obok 50 roślimonet) i 0-2 ze skrzyni (najczęściej 0). Szczegóły w `README.md` i `scripts/plant_match.gd`.

## Propozycje na później (ankieta 2026-11-01)

Wszystkie 16 propozycji zostało zatwierdzonych do wprowadzenia w przyszłości. Kolejność i liczby są do ustalenia przy wdrażaniu.

### Mini-gry bez walki

| Nazwa | Na czym polega | Pomoc | Nagroda |
|---|---|---|---|
| Pamięć ogrodnika | Plansza 4x5 zakrytych kart z roślinkami. Gracz odsłania dwie: para zostaje odkryta i daje 1 punkt tej roślinie (8 punktów to ulepszenie, jak w trójkach). Próba kosztuje 1 ruch, para oddaje ruch | 30: podgląd całej planszy przez 3 s | punkty do ulepszeń |
| Łapanie kropli | Z nieba spadają krople wody, nawozy i śmieci. Gracz przesuwa konewkę palcem: krople to punkty, nawóz podwaja punkty do końca rundy, złapany śmieć zabiera 1 z 3 serc. Runda ok. 60 s, coraz szybciej | – | 1/2/3 sadzonki za 100/250/500 punktów |
| Quiz ekologiczny | 5 pytań na etap, odpowiedzi obrazkami: do którego pojemnika wyrzucić puszkę, butelkę, karton, skórkę banana. Etap raz dziennie, pytania losowane z ok. 60 | – | 20 roślimonet za dobrą odpowiedź, sadzonka za 5/5 |
| Album naklejek | Za etapy wydarzeń, skrzynie i zbiory z ogrodu losowe naklejki z roślinkami i śmieciostworami (z opisem). Powtórki można wymienić ze znajomym przez Wi-Fi | – | 5 rubinów za pełną stronę (8 naklejek), ramka na plakietkę za cały album |

### Nowe zasady na planszy

| Nazwa | Na czym polega | Pomoc |
|---|---|---|
| Pory roku | Każdy z 5 etapów ma porę roku. Wiosna: Kaktusy dają krople 1,5 raza częściej. Lato: rośliny bez Liścia Bananowca obok powoli tracą życie. Jesień: co 20 s wiatr przesuwa wrogów o pole wstecz. Zima: śnieg spowalnia wrogów, ale też strzały | 40: parasol, który wyłącza porę roku na 30 s |
| Ruchome pasy ziemi | Dwa rzędy to taśmy ziemi: co 15 s posadzone tam rośliny przesuwają się o pole w lewo, a zepchnięta z planszy wraca do paska z odnowieniem | 30: blokada taśmy na 20 s |
| Burza | Co 25-35 s burza: 3 s ostrzeżenia (chmury nad 2 rzędami), potem deszcz przyspiesza wrogów w tych rzędach na 8 s, a piorun niszczy losową kupkę śmieci albo roślinę bez osłony | 40: piorunochron w wybranym polu, chroni 3x3 |
| Rzeka przez ogród | Środkowy rząd to rzeka: nie da się tam sadzić, a wrogowie płyną nią 2 razy szybciej. Kładka (20 kropli) mieści jedną roślinę. Kaktusy przy rzece dają krople o 25% częściej | 30: 2 darmowe kładki |

### Nowe cele etapów

| Nazwa | Na czym polega | Pomoc | Dodatkowa nagroda |
|---|---|---|---|
| Ochrona drzewka | W środku planszy rośnie Drzewko Życia (dużo życia, bez leczenia). Wrogowie idą do niego zamiast do domu; przegrana, gdy je zjedzą. Między falami Drzewko daje 50 kropel | 50: Drzewko z podwójnym życiem | 2 rubiny za ostatni etap |
| Sortowanie śmieci | Śmieciostwory mają kolory pojemników: żółty (plastik i metal), niebieski (papier), zielony (szkło), brązowy (bio). Każda roślina dostaje kolor na etap: 2 razy więcej obrażeń wrogom w swoim kolorze, połowa pozostałym. Kolory fal widać przed etapem | – | – |
| Skarby w ziemi | Pod 6 losowymi polami są skarby. Posadzenie rośliny na takim polu odkrywa skarb: 50 kropel, nawóz, 20 roślimonet albo rzadko rubin. Wróg, który wejdzie na nieodkryty skarb, kradnie go | 30: wykrywacz pokazuje 2 skarby | skarby |
| Zagadka obronna | Gotowe ustawienie części roślin i stała liczba kropel, bez Kaktusów. Gracz dosadza 2-4 rośliny, potem fala idzie sama i nic nie można zmienić. Jedna fala na etap | 20: podpowiedź jednego pola | – |

### Talia, znajomi, budowanie

| Nazwa | Na czym polega | Pomoc | Nagroda |
|---|---|---|---|
| Jedna roślinka | Talia to jedna losowa roślina (bez źródła wody) i Kaktus, inna na każdym etapie. Rośliny jednorazowe szybciej się odnawiają, a strzelające mają dodatkowy nawóz na start | 30: zmiana wylosowanej rośliny | – |
| Pojedynek ze znajomym | Dwa telefony w tej samej sieci Wi-Fi, każdy broni swojego ogrodu. Każdy pokonany wróg wysyła śmieciostwora do ogrodu znajomego, a co 10. pokonany wysyła dużego. Wygrywa ten, kto dłużej wytrzyma | – | 1 rubin i 30 roślimonet za wygraną, raz dziennie |
| Budowanie ścieżki | Przed falą gracz układa z 8-12 kamieni krętą ścieżkę, którą wrogowie muszą iść do domu. Rośliny sadzi się obok ścieżki i strzelają w każdym kierunku na 2 pola | 40: 3 dodatkowe kamienie | – |
| Przesadzanie roślin | Raz na 10 s można przeciągnąć posadzoną roślinę na sąsiednie wolne pole, np. uciec przed bossem. Wrogowie są 1,3 raza szybsi | 30: przesadzanie co 5 s | – |

## Kod testowy

Na plakietce każdego konta jest przycisk „Kod testowy”. Poprawny kod pozwala raz zmienić bieżące wydarzenie na dowolne inne, a kolejna zmiana wymaga ponownego wpisania kodu. Gracz decyduje, czy postępy z opuszczanego wydarzenia mają się zapisać. Zapisane wracają przy ponownym przejściu na to wydarzenie kodem. Wybrane wydarzenie startuje z pełnym tygodniem, a potem gra przechodzi do następnego w kolejności. Po 3 nieudanych próbach z rzędu opcja blokuje się na 10 minut na całym telefonie, niezależnie od konta. W repozytorium jest tylko skrót kodu (`TEST_CODE_SHA256` w `scripts/game_state.gd`). **Przed wydaniem gry ten kod trzeba usunąć.**

## Sadzenie razem (opcja w tygodniu Łowów)

To nie jest osobny tydzień. Podczas Łowów ogród pyta gracza, czy chce sadzić razem ze znajomym. Dzięki temu w tym tygodniu sadzonki można zdobywać w Łowach.

Po zatwierdzeniu ogród działa dalej, a na ekranie pojawia się przycisk „Sadzimy razem”, który łączy z osobą w tej samej sieci Wi-Fi. Połączeni gracze wysyłają sobie sadzonki: jedna dziennie za darmo, każda następna za 30 roślimonet. Zbiory obojga liczą się do wspólnego celu 8 roślinek. Po jego osiągnięciu każdy dostaje 4 sadzonki.
