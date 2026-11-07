# Przegląd repozytorium — 2026-10-30 — ChatGPT (Codex)

**Autor:** ChatGPT (Codex, OpenAI).

**Data:** 30 października 2026, strefa Europe/Warsaw (CET, UTC+01:00).

**Repozytorium:** `JeanPaulSzefler/education-games`.

**Zakres:** wszystkie gałęzie obecne na serwerze, w tym `master`, wykonanie zadania graficznego oraz przegląd kodu i dokumentacji.

**Charakter przeglądu:** analiza kodu, diagnostyczne uruchomienia Godota i kontrola plików graficznych. To przegląd techniczny, nie ocena balansu gry.

> **Aktualizacja 2026-11-07 (Claude):** błędy R1–R4 są naprawione w `0dbdd8a`. Przegląd ma też nowy kontekst: decyzja Ownera o grze przez internet z kontami i zakupami. Stan zaleceń i ich wpływ opisuje [§7](#7-aktualizacja-2026-11-07--stan-zaleceń-i-gra-przez-internet). Sekcje 1–6 pozostają bez zmian, jako zapis przeglądu z 30 października.

## 1. Gałęzie i stan źródeł

Gałęzie odczytano przez `git ls-remote --heads origin` i pobrano przez `git fetch`. Uwzględniono merge wykonany przez autora w trakcie tej sesji.

| Gałąź zdalna | Commit źródłowy objęty przeglądem | Wynik porównania |
|---|---|---|
| `master` | `03b0ba0187303aa48197c384529c340bf2ab751c` | Merge PR #2; zawartość identyczna z bazą gałęzi z 30 października. |
| `jvp-notatki-2026-10-30` | `59af14cba707568f4c562bef07a702c27034f746` | Cały ten stan był już scalony do `master`. Na tej gałęzi dodano następnie grafiki w commicie `abad056`. |
| `jvp-notatki-2026-10-06` | `9732b5d2405bfed845c77f9a1d61c26fefc74c20` | Starsza wersja, również całkowicie scalona do `master`; nie zawiera wydarzeń, ogrodu ani ENet. |

`git rev-list --count origin/master..origin/<gałąź>` przed dodaniem grafik zwrócił `0` dla obu gałęzi roboczych. Drzewo `master` i bazy z 30 października miało identyczny identyfikator `7f815b124c471e6176dd12378a4b0583b6d096eb`.

Lokalna gałąź środowiska `work` wskazuje `0fb7011`; jej drzewo jest identyczne z gałęzią z 6 października (`b9914c7f4fa5c44db64ad4d97b2b34b8502a8bad`). Pierwszy test środowiska wykonano właśnie na tym starszym drzewie. Nie jest to dodatkowa aktywna gałąź zdalna.

Przejrzano wspólne mechanizmy profili, zapisu, odblokowań i ścieżki oraz zmiany z 30 października: migracje do wersji 5, wydarzenia, ogród, nagrody, wybór talii i komunikację sieciową. Cztery odtworzone problemy poniżej dotyczą aktualnego kodu na `master` i gałęzi z 30 października. Nie przypisuję ich starszej gałęzi, na której odpowiednie funkcje jeszcze nie istnieją. Nie znaleziono osobnej, odtworzonej usterki w sprawdzonym starszym zakresie.

## 2. Wykonane zadanie dla ChatGPT

Instrukcję znaleziono w [`ZADANIE_GRAFIKI_CHATGPT.md`](../junk-vs-plants/ZADANIE_GRAFIKI_CHATGPT.md). Opisy pochodzą z [`GRAFIKI_PROMPTY_5.md`](../junk-vs-plants/GRAFIKI_PROMPTY_5.md). Na pierwotnie wybranym `master` sprzed merge tej instrukcji nie było; odnaleziono ją na wskazanej w niej gałęzi `jvp-notatki-2026-10-30`.

Każdą grafikę wygenerowano osobno. Dla ikon i grządki użyto `assets/sprites/plants/cactus.png` jako wzoru stylu. Przygotowano wersje robocze 1024 × 1024 poza repozytorium, następnie przycięto ikony do treści i zmniejszono pliki. Kłódkę poprawiono, aby otwór na klucz miał wyraźny kształt liścia. Przeciwległe krawędzie mgły dopasowano przez lustrzane kafelkowanie, a kanał alfa ustawiono na `217/255` (85,1%).

Wszystkie ścieżki w poniższej tabeli są względem `junk-vs-plants/assets/sprites/`.

| Plik | Wymiary końcowe | Tło |
|---|---:|---|
| `plants/mega_cactus.png` | 511 × 493 | Przezroczyste; nadpisany dotychczasowy plik. |
| `ui/chest.png` | 512 × 433 | Przezroczyste. |
| `ui/plant_coin.png` | 503 × 512 | Przezroczyste. |
| `ui/ruby.png` | 512 × 435 | Przezroczyste. |
| `ui/sapling.png` | 512 × 411 | Przezroczyste. |
| `ui/bee.png` | 512 × 493 | Przezroczyste. |
| `ui/event_star.png` | 492 × 442 | Przezroczyste. |
| `ui/padlock.png` | 435 × 512 | Przezroczyste. |
| `ui/book.png` | 512 × 410 | Przezroczyste. |
| `ui/shop_basket.png` | 463 × 504 | Przezroczyste. |
| `ui/soil_plot.png` | 512 × 512 | Całkowicie nieprzezroczyste, bez przycinania. |
| `ui/fog.png` | 512 × 512 | Stała alfa 217, bez przycinania. |

Kontrola programowa potwierdziła format PNG, limit wymiarów, rzeczywisty kanał alfa i przycięcie dziesięciu ikon, pełne krycie grządki oraz identyczność przeciwległych krawędzi mgły we wszystkich kanałach RGBA. Obejrzano komplet grafik: nie zawierają liter, cyfr ani znaków wodnych; książka ma jedynie umowne faliste linie zgodnie z opisem.

Godot potwierdził użycie plików w dziewięciu fabrykach ikon `UiIcons`, w grządce, Megakaktusie i wszystkich 50 polach nakładki mgły. Sprawdzono również, że mgła zasłania prawą połowę planszy.

Commit **`abad056` — `Add generated art for icons, chest, coin, garden, fog and Megakaktus`** zawiera dokładnie 12 wskazanych plików i został wypchnięty na `jvp-notatki-2026-10-30`. Nie zmieniono `.gd`, `.tscn`, `project.godot`, presetu eksportu ani pozostałych istniejących grafik. Nie dodano `.import`, `.godot/` ani plików roboczych. Ten raport jest oddzielnym dodatkiem zamówionym przez użytkownika.

## 3. Odtworzone problemy

Priorytet **P2** oznacza błąd do poprawienia w zwykłym cyklu prac. Nie stwierdzono odtworzonego problemu klasy P0/P1 w wykonanym zakresie.

### R1 — P2: „Wąskie gardło” wypuszcza dodatkowych wrogów poza dozwolonymi rzędami

**Miejsca:** [`main.gd:988`](../junk-vs-plants/scripts/main.gd#L988), [`main.gd:1041`](../junk-vs-plants/scripts/main.gd#L1041), [`level_data.gd:537`](../junk-vs-plants/scripts/level_data.gd#L537).

**Warunek:** wydarzenie `narrow`, od trzeciej fali. Dane etapu poprawnie przekładają rzędy na indeksy `1` i `2` (rzędy 2 i 3), ale `_add_extra_enemies()` później losuje rząd kopii z całego zakresu `0..4`. Pomija `narrow_rows`.

**Odtworzenie:** przygotować etap 0 wydarzenia o indeksie 7, ustawić `seed(1)`, `current_wave = 2`, `between_waves_timer = 0` i wywołać `_update_wave_spawning(0.01)`. W kolejce dodatkowych przeciwników pojawiły się niedozwolone rzędy **`[0, 4, 4]`**.

**Skutek:** gracz broniący dwóch rzędów zgodnie z zasadami może przegrać przez przeciwników na pozostałych trzech. Dotyczy to zwykłego przebiegu gry, bez modyfikacji klienta.

**Proponowana poprawka:** przy tworzeniu dodatkowych przeciwników wybierać rząd z `event_rules.get("narrow_rows", ...)` albo ponownie nakładać ograniczenie na gotową kolejkę. Przejrzeć też rzędy przeciwników wypuszczanych z kupek. Test regresji powinien sprawdzać całą kolejkę każdej fali, nie tylko bazowe dane poziomu.

### R2 — P2: kupiona czwarta roślina zostaje na kolejne próby

**Miejsca:** [`plant_select.gd:84`](../junk-vs-plants/scripts/plant_select.gd#L84), [`main.gd:303`](../junk-vs-plants/scripts/main.gd#L303), [`main.gd:504`](../junk-vs-plants/scripts/main.gd#L504), [`main.gd:2976`](../junk-vs-plants/scripts/main.gd#L2976).

**Warunek:** wydarzenie `forced_deck`, zakup pomocy pozwalającej dodać czwartą roślinę, a następnie „Zagraj ponownie”.

**Przyczyna:** pierwsza plansza zużywa `event_help_active`, lecz ponowne wczytanie sceny zachowuje czteroelementowe `GameState.current_loadout`. Pasek nie sprawdza ponownie, czy dodatkowa roślina jest jeszcze opłacona. Nie ma powrotu przez ekran wyboru talii.

**Odtworzenie:** etap 0 wydarzenia o indeksie 8 uruchomić z pomocą i czterema roślinami; po zbudowaniu pierwszej sceny potwierdzić `event_help_active == false`; zbudować kolejną scenę z zachowanym stanem, jak robi to przycisk powtórki. Wynik: **`help=false; sidebar plants=4; loadout=[1, 3, 11, 0]`**. Pierwsze trzy indeksy są losowe, istotna jest liczba czterech roślin.

**Skutek:** płatna pomoc opisana jako działająca tylko na jedno wejście działa w następnych powtórkach bez kolejnego zakupu.

**Proponowana poprawka:** powtórkę wydarzenia przygotowywać jako nowe wejście, z talią ograniczoną do trzech narzuconych roślin, albo prowadzić przez ekran wyboru/zakupu. Walidować również bezpośrednie uruchomienie `Main` z zachowanym stanem. Po naprawie druga próba bez zakupu powinna mieć trzy kafelki.

### R3 — P2: otwarty ekran pozwala wystartować wygasłe wydarzenie

**Miejsca:** [`game_state.gd:284`](../junk-vs-plants/scripts/game_state.gd#L284), [`game_state.gd:297`](../junk-vs-plants/scripts/game_state.gd#L297), [`game_state.gd:323`](../junk-vs-plants/scripts/game_state.gd#L323), [`events.gd:22`](../junk-vs-plants/scripts/events.gd#L22), [`events.gd:176`](../junk-vs-plants/scripts/events.gd#L176).

**Warunek:** gracz otwiera ekran wydarzenia przed końcem tygodnia i pozostawia go otwarty do wygaśnięcia; może też pozostać na ekranie wyniku i powtarzać etap.

**Przyczyna:** `refresh_event()` jest wywoływane przy wejściu na ekran, ale nie przed rozpoczęciem etapu. `current_event()` sprawdza tylko niezerowy czas startu i zakres indeksu. `start_event_game()` nie sprawdza czasu, więc przeterminowane wydarzenie nadal daje się uruchomić.

**Odtworzenie:** ustawić `event_index = 0`, `event_started = now - 9 * 86400` i wywołać `start_event_game(0)`. Wynik: **`seconds_left=0; start accepted=true; event_index=0`**. Dopiero jawne `refresh_event()` zmienia indeks na `1`.

**Skutek:** dostępność wydarzenia i możliwość zdobywania jego nagród zależą od ponownego otwarcia ekranu zamiast od końca tygodnia. `complete_event_stage()` również nie wiąże wyniku z niezmiennym identyfikatorem edycji wydarzenia.

**Proponowana poprawka:** centralnie odświeżać i walidować wydarzenie przed uruchomieniem etapu; po zmianie edycji przebudować ekran zamiast używać przechwyconego wcześniej słownika. Powiązać uruchomioną grę z edycją wydarzenia i jawnie ustalić zasady ukończenia etapu rozpoczętego przed wygaśnięciem. Testować sam moment przekroczenia granicy siedmiu dni.

### R4 — P2: host nie egzekwuje odnowienia roślin gościa

**Miejsca:** [`main.gd:2546`](../junk-vs-plants/scripts/main.gd#L2546), [`main.gd:810`](../junk-vs-plants/scripts/main.gd#L810), [`main.gd:2603`](../junk-vs-plants/scripts/main.gd#L2603), [`net_session.gd:445`](../junk-vs-plants/scripts/net_session.gd#L445).

**Warunek:** zaakceptowany gość wysyła dwie kolejne poprawnie sformatowane akcje `place` dla tej samej rośliny na różne wolne pola. Wymaga to zmodyfikowanego klienta lub bezpośredniego wysłania RPC; zwykły interfejs gościa ma własny cooldown.

**Przyczyna:** host weryfikuje współrzędne, zakres indeksu, zajętość pola i koszt wody, ale `_on_guest_action()` wywołuje `_place_plant()` bez odnowienia przypisanego do gościa. Ograniczenie jest nakładane dopiero lokalnie u klienta po `place_confirmed`.

**Odtworzenie:** w dwóch rzeczywistych procesach Godota połączonych przez ENet na loopbackie, po handshake i wejściu na planszę, gość wysłał bez czekania `place [0, 0, 0]` oraz `place [0, 0, 1]`. Host miał 500 wody. Wynik: **`host accepted 2 plants from consecutive actions; water=400`**. Gość odebrał następnie oba obiekty przez snapshot.

**Skutek:** host, mimo że jest autorytetem symulacji, akceptuje sadzenie sprzeczne z zasadami przez klienta omijającego swój interfejs.

**Proponowana poprawka:** przechowywać cooldowny i zatwierdzoną talię każdego gracza po stronie hosta; sprawdzać je przed wykonaniem akcji i dopiero po przyjęciu akcji aktualizować stan. Test regresji: druga akcja przed upływem odnowienia ma zostać odrzucona bez pobrania wody; po odnowieniu ma przejść.

## 4. Wyniki walidacji i ich granice

Środowisko: Linux x86_64, Godot Standard **4.6.3.stable.official.7d41c59c4**. Testy zapisu używały oddzielnych katalogów XDG w `/tmp`, więc nie pracowały na zapisach gracza. Skrypty diagnostyczne i materiały robocze pozostawiono poza repozytorium w `/workspace/.godot-runtime/`.

| Kontrola | Wynik | Zakres |
|---|---|---|
| Starsze drzewo z 6 października | Przeszło | Import, uruchomienie bez okna, zapis/wczytanie profilu, cztery sceny, sadzenie i pojawienie się przeciwnika. Test przeprowadzony przed zmianą gałęzi. |
| Import aktualnego projektu | Zakończony kodem 0, bez błędów skryptów | Komunikaty dotyczące presetu eksportu i debuggera opisano niżej. |
| 15 wydarzeń × 5 etapów | Przeszło uruchomienie 75/75 | Dla każdego etapu zbudowano scenę, wykonano aktualizację wydarzenia i sprawdzono pojawienie się pierwszego przeciwnika. Nie rozegrano etapów do końca. |
| Profile i sceny | Przeszło | Zapis/wczytanie talii i zbudowanie `ProfileSelect`, `LevelSelect`, `PlantSelect`, `Garden`, `Events`. |
| Migracja zapisu v3 → v5 | Przeszła sprawdzony przypadek | Dwa ukończone dawne poziomy dają cztery nowe, zachowano dwa rubiny, talię nieskończoną przeniesiono z klucza `28` na `60`. |
| Diagnostyczny zestaw scenariuszy | 240 kontroli, 0 nieoczekiwanych niepowodzeń | 237 kontroli potwierdzało poprawne zachowanie; 3 celowo potwierdzały błędne stany R1–R3. Wynik nie oznacza usunięcia tych błędów. |
| Dwie instancje ENet | Oba procesy zakończyły się kodem 0 | Dołączenie z tokenem, gotowość obu stron, wejście do gry, akcje gościa i snapshoty hosta; dodatkowo odtworzono R4. |
| Parametry 12 PNG | Przeszły wszystkie kontrole | Wymiary, alfa, przycięcie i zgodność krawędzi mgły. |
| Użycie grafik w Godocie | Przeszło | Wszystkie 12 tekstur; bez fallbacków w sprawdzonych fabrykach ikon i nakładce mgły. |
| Zakres commita graficznego | Zgodny | Dokładnie 12 wymaganych plików; żadnych zmian w kodzie. |

Przykładowe polecenia ponownego uruchomienia diagnostyki w tym środowisku:

```bash
cd /workspace/education-games
export XDG_DATA_HOME=/tmp/jvp-review-2026-10-30/data
export XDG_CONFIG_HOME=/tmp/jvp-review-2026-10-30/config
export XDG_CACHE_HOME=/tmp/jvp-review-2026-10-30/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --path junk-vs-plants --script /workspace/.godot-runtime/review-smoke.gd
godot --headless --path junk-vs-plants --script /workspace/.godot-runtime/art-readiness.gd
python3 /workspace/.godot-runtime/run-network-review.py
```

Te skrypty są lokalnymi narzędziami tej sesji i nie stanowią istniejącego wcześniej zestawu testów repozytorium. Do uruchomienia dwóch procesów ENet potrzebna jest możliwość tworzenia lokalnych gniazd sieciowych; w tej sesji test wykonano poza ograniczeniem sandboxa blokującym takie gniazda. Odtworzenia R1–R4 opisano wyżej również niezależnie od ścieżek tych narzędzi.

**Nie sprawdzono:** eksportu APK, uruchomienia na Androidzie, renderowania w oknie, fizycznego dotyku, wykrywania telefonów przez UDP broadcast/hotspot, długiego przebiegu rozgrywki i balansu wszystkich poziomów. Test dwóch procesów obejmował ENet, nie cały proces zapraszania przez UDP.

## 5. Pozostałe obserwacje i zalecenia

### Zgodność wersji Godota i eksport

`project.godot` deklaruje funkcje wersji `4.7`, natomiast dostępne środowisko ma `4.6.3`. Import tej wersji zgłasza:

```text
Couldn't find the given section "preset.0" and key "runnable", and no default was given.
```

Preset ma sekcję `[runnable_presets]` zamiast pola oczekiwanego przez dostępny silnik. To **zaobserwowana niezgodność narzędzi/presetu**, a nie potwierdzony błąd eksportu w Godocie 4.7. Należy ustalić i udokumentować jedną wspieraną wersję silnika, a następnie sprawdzić w niej preset oraz eksport APK. Nie zmieniano presetu w zadaniu graficznym.

Headless editor zgłaszał ponadto błędy `TCPServer.listen` przy tworzeniu debuggera w sandboxie. Nie były to błędy parsera gry. Lokalny test ENet poza tym ograniczeniem przeszedł. Dokumentacja nadal wskazuje w opisie struktury `icon.svg`, chociaż projekt używa `icon.png`.

### Testy utrzymywane w repozytorium

Nie znaleziono istniejącego zestawu testów ani konfiguracji CI. Najbardziej użyteczne następne testy to: ograniczenia rzędów po powiększeniu fal, zużycie pomocy między próbami, granica czasu wydarzenia, walidacja akcji gościa oraz reprezentatywne migracje zapisów. Sam import projektu nie wykrywa R1–R4.

### Odpowiedzialności i zapis

Oddzielenie `PlantData`, `LevelData`, `EventData` oraz `UiIcons` ułatwia kontrolę danych i pozwoliło dodać grafiki bez zmiany kodu. `main.gd` ma jednak 2984 wiersze, a `game_state.gd` 964: obsługa wydarzeń, powtórek, nagród i trwałego stanu jest rozproszona. R2 i R3 pokazują, że warto najpierw wydzielić przygotowanie nowego wejścia na etap i reguły ważności wydarzenia. Duży refaktor całej walki nie jest potrzebny do naprawy opisanych usterek.

`save_progress()` i `save_profiles()` zapisują bezpośrednio do pliku docelowego; nie ma zapisu przez plik tymczasowy ani zapasowej kopii. Warto rozważyć atomową podmianę i obsługę błędów zapisu dla aplikacji mobilnej. W tej sesji **nie odtworzono utraty zapisu**, więc nie zaliczam tego do czterech potwierdzonych błędów.

## 6. Proponowana kolejność dalszych prac

1. Naprawić R1, bo dotyczy normalnej rozgrywki wydarzenia.
2. Naprawić cykl uruchamiania i powtarzania etapów: R2 i R3, z testami granic czasu i zużycia pomocy.
3. Przenieść egzekwowanie odnowienia i zatwierdzonej talii gościa do hosta — R4.
4. Ustalić wersję Godota, sprawdzić APK oraz zaproszenia na dwóch fizycznych urządzeniach.
5. Przenieść wybrane scenariusze diagnostyczne do utrzymywanego zestawu testów/CI.

W ramach tej sesji wykonano zadanie graficzne i zapisano przegląd; opisane poprawki kodu pozostają osobnym zadaniem. `master` nie został zmieniony przez tę sesję; grafiki i raport trafiają na `jvp-notatki-2026-10-30`.

## 7. Aktualizacja 2026-11-07 — stan zaleceń i gra przez internet

**Autor aktualizacji:** Claude (Anthropic), sesja Claude Code.

**Zakres:**

- stan R1–R4 i zaleceń z §5 na `master` (`612e937`) i na `jvp-notatki-2026-10-30` (`87655b7`, wersja 1.2.0, jeszcze niescalona z `master`);
- wpływ decyzji Ownera z 7 listopada 2026: **gra przez internet, konta graczy na serwerze, zakupy po zalogowaniu kontem Google**.

**Metoda:** wyłącznie lektura kodu i historii gita. W tej sesji **nie uruchamiano Godota** i nie powtarzano odtworzeń z §3.

### 7.1. Stan błędów R1–R4

Wszystkie cztery poprawiono w commicie `0dbdd8a` („fix the issues from the ChatGPT review”, 30 października 2026). Poprawki są na `master` i na `jvp-notatki-2026-10-30`.

| Błąd | Stan | Co zmieniono |
|---|---|---|
| R1 — dodatkowi wrogowie poza rzędami „Wąskiego gardła” | Naprawiony | `main.gd`: `_random_enemy_row()` losuje tylko z `narrow_rows`; kupki śmieci też tylko w dozwolonych rzędach |
| R2 — kupiona czwarta roślina zostaje na kolejne próby | Naprawiony | `main.gd`: powtórka bez ponownego zakupu przywraca narzuconą talię (`event_forced_plants`) |
| R3 — wygasłe wydarzenie daje się wystartować | Naprawiony | `game_state.gd`: `start_event_game()` odświeża wydarzenie i odrzuca start, gdy zmienił się jego identyfikator. Przycisk powtórki wraca do ekranu wydarzeń po upływie czasu |
| R4 — host nie egzekwuje odnowienia roślin gościa | Naprawiony | `main.gd`: host trzyma `guest_cooldowns` i odrzuca sadzenie przed końcem odnowienia, z komunikatem dla gościa |

**Uwaga:** poprawek nie potwierdzono testem regresji. W repozytorium nadal nie ma testów (zob. 7.2), więc każdy z tych błędów może wrócić niezauważony.

### 7.2. Stan pozostałych zaleceń z §5 i §6

| Zalecenie | Stan na 2026-11-07 |
|---|---|
| Jedna wspierana wersja Godota, sprawdzony eksport APK | **Częściowo.** Projekt deklaruje `4.7`; APK 1.1.0 i 1.2.0 zbudowano, więc eksport działa u Ownera. Preset nadal nie ma klucza `runnable` w `[preset.0]`, a README mówi „4.4/4.7”. Wersję warto zapisać jednoznacznie |
| Zaproszenia na dwóch fizycznych urządzeniach | Nie ma zapisu o teście w repozytorium |
| Utrzymywany zestaw testów i CI | **Otwarte.** Brak testów i konfiguracji CI |
| Atomowy zapis postępu | **Otwarte.** `save_progress()` nadal pisze bezpośrednio do pliku docelowego |
| `icon.svg` w opisie struktury | **Otwarte.** README nadal wymienia `icon.svg` |

### 7.3. Wpływ decyzji o grze przez internet

Przegląd z 30 października zakładał grę bez serwera. Po decyzji Ownera niektóre ustalenia ważą więcej:

1. **Klasa błędów R3 (czas z urządzenia).** Wydarzenia, ogród (15 godzin wzrostu) i dzienna oferta rubinów liczą czas zegarem telefonu. Offline to drobna luka. Przy kontach na serwerze i zakupach zmiana zegara daje darmowe nagrody. Czas wydarzeń i limity dzienne powinien wyznaczać serwer, a każde wydarzenie powinno mieć identyfikator edycji (jak w zaleceniu R3).
2. **Klasa błędów R4 (zaufanie do klienta).** Host między dwoma telefonami wystarcza do wspólnej gry ze znajomym. **Nie wystarcza do ekonomii:** zmodyfikowany klient może przyznać sobie rubiny i roślimonety. Rubiny, roślimonety, nagrody i zakupy powinny żyć w **portfelu na serwerze**, a zakupy z Google Play powinny być weryfikowane na serwerze. Rozgrywka może dalej zależeć od hosta.
3. **Zapis.** Serwer staje się źródłem prawdy dla danych konta; zapis lokalny zostaje do gry offline. Potrzebne są reguły:
   - jednorazowe przeniesienie istniejących lokalnych kont (do 6 na telefon) na konto online;
   - rozstrzyganie konfliktów;
   - atomowy zapis lokalny (zalecenie z §5) przed pierwszą synchronizacją.
4. **Sieć.** Dziś: wykrywanie przez broadcast UDP (port 47810) i bezpośrednie połączenie ENet (port 47811). Działa tylko w jednej sieci Wi-Fi lub na hotspocie. Przez internet potrzebny jest pośrednik (relay) albo serwer gry. Lokalny tryb Wi-Fi warto zostawić jako zapasowy.
5. **Gra dla dzieci.** Konta i gra online wymagają:
   - zgody rodzica (RODO art. 8; granica wieku w Polsce do potwierdzenia);
   - usuwania konta w aplikacji i przez stronę WWW (Google Play);
   - braku otwartego czatu z nieznajomymi (Google Play Families): tylko znajomi przez kod, gotowe emotki;
   - na iOS: „Sign in with Apple” obok logowania Google.
6. **Oferty „za reklamę”.** Dziś gra pokazuje zamiast reklamy własny napis z odliczaniem (`level_select.gd`), więc nie ma zewnętrznego SDK reklam. Jeśli pojawią się prawdziwe reklamy, w aplikacji z programu Families wolno używać tylko certyfikowanych sieci reklamowych.

Analiza backendu z rekomendacją Nakamy jest w repozytorium `JeanPaulSzefler/AI-crew`, w pliku `outputs/2026-11-07-orkiestracja-agentow-i-hosting-v2.md`, sekcja 3.1. Nakama to otwartoźródłowy serwer gier z SDK dla Godota: konta Google i Apple, portfel, weryfikacja zakupów, mecze przez pośrednika.

### 7.4. Proponowana kolejność dalszych prac (zastępuje §6)

1. Scalić `jvp-notatki-2026-10-30` (wersja 1.2.0) z `master`.
2. Dodać utrzymywane testy regresji dla R1–R4 i migracji zapisów, uruchamiane w trybie headless, oraz prosty CI.
3. Wprowadzić atomowy zapis lokalny (plik tymczasowy i podmiana) i zapisać wspieraną wersję Godota.
4. Napisać specyfikację „JvP online”:
   - zakres: znajomi przez kod, bez czatu;
   - bramka rodzica;
   - minimum danych;
   - usuwanie konta;
   - które dane przechodzą na serwer.
5. Przenieść ekonomię (rubiny, roślimonety, nagrody) do modelu z portfelem na serwerze i czasem serwera; rozgrywka z hostem bez zmian.
6. Zbudować backend lokalnie (Docker), potem zintegrować logowanie, zakupy testowe Google Play Billing i grę przez pośrednika.
7. Przed testem zamkniętym w Google Play uruchomić serwer produkcyjny w UE, z kopiami zapasowymi poza dostawcą.
