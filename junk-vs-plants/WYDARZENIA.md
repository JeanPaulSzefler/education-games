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

Etapy 3 i 5 każdego wydarzenia tygodnia dają przy pierwszym przejściu także 1 ruch do Roślinnych trójek.

## Roślinne trójki (wydarzenie stałe)

Nie jest częścią żadnej rotacji. Przycisk jest zawsze u góry ścieżki i pokazuje liczbę ruchów. Plansza 8x6 jest pełna wszystkich 14 roślin i zostaje między wejściami. Generator dba, żeby ruch miało zawsze co najmniej 10 rodzajów roślin (po każdym ruchu co najmniej 8), więc gracz sam wybiera, którą roślinkę ulepsza. Gracz zamienia dwie sąsiednie roślinki tak, żeby co najmniej 3 takie same stanęły w rzędzie lub kolumnie. Znika wtedy cała grupa stykających się roślinek tego rodzaju, a roślina dostaje punkty: 3-4 roślinki to 1 punkt, 5-6 to 2, 7-8 to 3. 8 punktów zamienia się w jedno ulepszenie tej rośliny, także jeszcze nieodblokowanej. Zamiana, która nie układa trójki, nie zużywa ruchu.

Ruchy (notatki 2026-11-03): 1 za każdą roślinkę zebraną w ogrodzie, 0-2 ze skrzyni (najczęściej 0), 1 za pierwsze wygranie poziomu z bossem, 1 za każdą skończoną grę z innym graczem (najwyżej 3 dziennie), 1 za etapy 3 i 5 wydarzenia tygodnia, ruchy z dodatków i z trybu nieskończonego.

## Dodatki (rotacja co 5 dni)

Zatwierdzone w ankietach 2026-11-01 i 2026-11-03. Przycisk „Dodatki” na ścieżce. Każdy dodatek trwa 5 dni, potem przychodzi następny, a po ostatnim rotacja zaczyna się od początku. Postępy znikają razem z dodatkiem (album naklejek zostaje). Kolejność i dane: `scripts/addon_data.gd`, zasady walki: `scripts/addon_modes.gd`.

Etapy (walka, Budowanie ścieżki) mają trudność poziomów 2, 6, 12, 21 i 36. Pierwsze przejście daje: 1 sadzonkę, 1 ruch, 2 sadzonki, 1 ruch, 2 sadzonki i rubin. Każda powtórka daje 10 roślimonet, a co trzecia także sadzonkę. Pomoc kupuje się przed etapem.

| Nr | Nazwa | Rodzaj | Na czym polega | Pomoc za roślimonety |
|---|---|---|---|---|
| 1 | Pamięć ogrodnika | mini-gra | 20 kart (10 par). Druga karta kosztuje ruch z trójek, para go oddaje i daje roślinie punkt do ulepszenia. Plansza zostaje do końca dodatku | 30: podgląd planszy przez 3 s (w grze) |
| 2 | Pory roku | walka | Etapy 1-4: wiosna (Kaktusy x1,5), lato (rośliny bez Liścia Bananowca obok tracą 6 HP co 5 s), jesień (co 20 s wiatr odpycha wrogów o pole), zima (wrogowie i pociski x0,7). Etap 5: pory zmieniają się co 30 s | 40: parasol wyłącza porę roku na 30 s |
| 3 | Łapanie kropli | mini-gra | Konewka łapie krople (5 pkt), nawóz podwaja punkty, śmieć zabiera 1 z 3 serc. 60 s, coraz szybciej | – |
| 4 | Ruchome pasy ziemi | walka | Rzędy 2 i 4: co 15 s rośliny przesuwają się o pole w lewo; zepchnięta wraca na pasek i się odnawia | 30: stop taśm na 20 s |
| 5 | Ogrodowe bingo | meta | Karta 4x4 z 20 możliwych zadań wykonywanych w zwykłych grach. Linia: na zmianę sadzonka i ruch, cała karta: 5 rubinów | 40: zamiana zadania |
| 6 | Burza | walka | Co 25-35 s: 3 s ostrzeżenia nad 2 rzędami, potem 8 s deszczu (wrogowie x1,5) i piorun w kupkę albo roślinę | 40: piorunochron chroni 3x3 |
| 7 | Labirynt pszczółki | etapy | 5 labiryntów, pszczółka za palcem, nektar -2 s, pajęczyna = start. 1-3 gwiazdki za czas | – |
| 8 | Rzeka przez ogród | walka | Środkowy rząd: wrogowie x2, sadzenie tylko na kładce (20 kropli), Kaktusy obok rzeki x1,25 | 30: 2 darmowe kładki |
| 9 | Album naklejek | meta | 24 naklejki (rośliny, śmieciostwory, bossowie, pszczółka) za wygrane i zbiory w ogrodzie. Strona (8): 5 rubinów, cały album: złota ramka plakietki. Wymiana powtórek przez Wi-Fi | – |
| 10 | Ochrona drzewka | walka | Drzewko (1200 + 300 na etap HP) w kolumnie 2, rząd 3. Wrogowie skręcają do niego; zjedzone = przegrana. Po fali +50 kropel. 2 rubiny za ostatni etap | 50: podwójne życie |
| 11 | Budowanie ścieżki | etapy | Plansza 12x7: gracz układa ścieżkę od wejścia do domu (12 pól + 8-12 kamieni), potem sadzi obok Kukurydzę, Pokrzywę (obszar) i Mrozoroślinkę (spowalnia) | 40: 3 kamienie więcej |
| 12 | Skarby w ziemi | walka | 6 ukrytych skarbów: 50 kropel, nawóz, 20 roślimonet albo rubin (5%). Wróg na polu skarbu go kradnie | 30: wykrywacz pokazuje 2 |
| 13 | Pszczeli rój | walka | Co 20-30 s pszczółka; złapana daje do wyboru premię na 15 s: odnawianie x2, wrogowie x0,5, krople x2 | 30: pierwsza od razu, na 10 s |
| 14 | Zagadka obronna | walka | 5 gotowych plansz z roślinami, stałą wodą i jedną falą. Gracz dosadza rośliny i naciska Start | 20: podpowiedź pola |
| 15 | Pojedynek ze znajomym | meta | Tydzień pojedynków: pierwsza wygrana dnia daje +1 rubin i +30 roślimonet ekstra | – |
| 16 | Jedna roślinka | walka | Kaktus i jedna losowa roślina (bez wody i Pnączy), inna na każdym etapie. Jednorazowe odnawiają się 2 razy szybciej, strzelające mają nawóz na start | 30: losowanie innej rośliny |
| 17 | Zbieracz nasion | walka | 30% szans na nasionko z wroga; 5 nasion = darmowa roślina z talii | 30: podwójne nasiona przez 2 fale |
| 18 | Przesadzanie roślin | walka | Co 10 s przesadzenie rośliny na sąsiednie pole; wrogowie x1,3 | 30: co 5 s |
| 19 | Uwolnij zwierzątka | walka | 3-5 klatek (250 HP): jeż (ściana), ptaszek (kropla co 15 s), żabka (zjada wroga), motyl (odnawianie x1,5). Wróg przy klatce ją zabiera | 30: klatki z połową życia |
| 20 | Niewidzialne śmieci | walka | 30-60% wrogów prawie niewidocznych do trafienia albo do 3 pól od rośliny | 30: świetlik w wybranym rzędzie |
| 21 | Olbrzymia roślinka | walka | Wybrana roślina raz na etap jako olbrzym 2x2: 4x życie, 2 rzędy strzałów, 2x krople, większy wybuch, koszt x2. Wrogowie x1,3 życia | 40: olbrzym z nawozem |

## Gry edukacyjne (osobna rotacja co 5 dni)

Prośba z 2026-11-03: gry edukacyjne mają własny przycisk na ścieżce i własną rotację. Nowe gry edukacyjne dopisuje się do `AddonData.EDU`. Zasady segregacji według systemu w Polsce: żółty (metale i tworzywa), niebieski (papier), zielony (szkło), brązowy (bio), czarny (zmieszane).

| Nr | Nazwa | Na czym polega | Nagrody |
|---|---|---|---|
| 1 | Quiz ekologiczny | Raz dziennie 5 pytań z 39 śmieci: do którego pojemnika? Po odpowiedzi gra pokazuje właściwy pojemnik | 20 roślimonet za dobrą odpowiedź, sadzonka za 5/5 |
| 2 | Sortownia | Taśma ze śmieciami, przeciąganie do 5 pojemników, coraz szybciej; 3 błędy albo 90 s kończą rundę | 1/2/3 sadzonki za 15/30/50 (każdy próg raz) |
| 3 | Sortowanie śmieci | Walka: wrogowie mają kolor pojemnika (butelka i puszka żółte, karton niebieski, gąbka czarna), rośliny losowy kolor na etap. Ten sam kolor: obrażenia x2, inny: x0,5 | jak etapy dodatków |

## Kod testowy

Na plakietce każdego konta jest przycisk „Kod testowy”. Poprawny kod pozwala raz zmienić bieżące wydarzenie, dodatek albo grę edukacyjną na dowolne inne (wybrany dodatek startuje od razu z pełnymi 5 dniami), a kolejna zmiana wymaga ponownego wpisania kodu. Gracz decyduje, czy postępy z opuszczanego wydarzenia mają się zapisać. Zapisane wracają przy ponownym przejściu na to wydarzenie kodem. Wybrane wydarzenie startuje z pełnym tygodniem, a potem gra przechodzi do następnego w kolejności. Po 3 nieudanych próbach z rzędu opcja blokuje się na 10 minut na całym telefonie, niezależnie od konta. W repozytorium jest tylko skrót kodu (`TEST_CODE_SHA256` w `scripts/game_state.gd`). **Przed wydaniem gry ten kod trzeba usunąć.**

## Sadzenie razem (opcja w tygodniu Łowów)

To nie jest osobny tydzień. Podczas Łowów ogród pyta gracza, czy chce sadzić razem ze znajomym. Dzięki temu w tym tygodniu sadzonki można zdobywać w Łowach.

Po zatwierdzeniu ogród działa dalej, a na ekranie pojawia się przycisk „Sadzimy razem”, który łączy z osobą w tej samej sieci Wi-Fi. Połączeni gracze wysyłają sobie sadzonki: jedna dziennie za darmo, każda następna za 30 roślimonet. Zbiory obojga liczą się do wspólnego celu 8 roślinek. Po jego osiągnięciu każdy dostaje 4 sadzonki.
