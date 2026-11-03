# Plan: wersja na iPhone'a, Google Play i App Store

Plan zadań od obecnego stanu (APK do testów, tylko Android) do gry w obu sklepach. Ceny i wymagania sklepów zmieniają się co roku, więc przed każdym krokiem trzeba je sprawdzić na stronach Google i Apple.

## 1. Przygotowanie wspólne dla obu sklepów

- [ ] **Kod testowy tylko w wersjach testowych.** Opcja „Kod testowy” i inne ułatwienia do testów mają działać tylko w wersji testowej (np. sprawdzenie `OS.is_debug_build()` albo osobny znacznik funkcji `dev` w eksporcie). W wersji ze sklepu nie może jej być.
- [ ] **Nazwa, ikona, numer wersji.** Ostateczna nazwa gry, ikona 1024x1024 px bez przezroczystości, ekran startowy. Numer wersji według zasady z README (`X.Y.Z`).
- [ ] **Polityka prywatności.** Strona WWW z polityką prywatności (wymagana w obu sklepach, zwłaszcza dla gier dla dzieci). Gra zapisuje dane tylko na telefonie i nie wysyła ich na serwer; sieć lokalna służy wyłącznie do gry ze znajomym.
- [ ] **Kategoria „dla dzieci”.** Google Play: program „Designed for Families” i jego zasady. App Store: kategoria Kids (opcjonalna) i wytyczne 1.3. W obu: brak reklam i analityki od firm zewnętrznych bez zgody rodzica, a zakupy i linki zewnętrzne tylko za „bramką dla rodzica” (np. zadanie matematyczne dla dorosłego).
- [ ] **Zakupy.** Zakupy rubinów w sklepie działają dziś tylko jako podgląd. Przed wydaniem: albo je wyłączyć, albo dodać prawdziwe płatności (Google Play Billing przez wtyczkę Godota oraz StoreKit przez wtyczkę iOS) z bramką dla rodzica. Oferta „Reklama” to dziś okienko „Miłego grania!”; w grze dla dzieci lepiej zostawić ją bez prawdziwych reklam.
- [ ] **Ekrany o innych proporcjach.** Gra ma ekran 1280x720. Sprawdzić długie telefony (19,5:9) i tablety (4:3), ustawienie `display/window/stretch/aspect` oraz obszar bezpieczny wokół wycięć ekranu (`DisplayServer.get_display_safe_area()`).
- [ ] **Teksty do sklepów** we wszystkich 7 językach gry: nazwa, krótki i długi opis, co nowego.
- [ ] **Zrzuty ekranu i filmik** z gry (telefon i tablet, w kilku językach).
- [ ] **Kopia zapisów.** Zapis jest tylko w telefonie. Warto rozważyć kopię w chmurze (Google Play Games / iCloud) w późniejszej wersji.

## 2. Google Play

- [ ] Konto Google Play Console (jednorazowa opłata, weryfikacja tożsamości). Konto osobiste albo organizacji (wtedy potrzebny numer D-U-N-S).
- [ ] **Klucz wydania (release keystore)** zamiast klucza debug. Wygenerować, zrobić kopie w dwóch bezpiecznych miejscach i włączyć Play App Signing. Bez tego klucza nie da się wydać aktualizacji.
- [ ] **Eksport AAB** (Android App Bundle) z Godota zamiast APK: włączyć Gradle build (szablon kompilacji Androida), ustawić docelowe API wymagane w danym roku przez Google Play.
- [ ] Uprawnienia jak dziś: `internet`, `access_network_state`, `access_wifi_state`, `change_wifi_multicast_state`. Bez innych.
- [ ] Karta sklepu: ikona 512x512, grafika 1024x500, zrzuty z telefonu i tabletu, opisy.
- [ ] Formularze: bezpieczeństwo danych („nie zbieramy danych”), klasyfikacja wiekowa (IARC), grupa docelowa (dzieci) i zasady programu dla rodzin.
- [ ] **Testy zamknięte.** Nowe konta osobiste muszą przed wydaniem przeprowadzić test zamknięty z odpowiednią liczbą testerów przez określony czas (w 2025 r.: 12 osób przez 14 dni). Kolejność ścieżek: test wewnętrzny → test zamknięty → produkcja.
- [ ] Wydanie produkcyjne, najlepiej stopniowe (np. 20% użytkowników na początek).

## 3. iPhone i App Store

- [ ] Mac z Xcode (własny albo wynajęty w chmurze) i konto Apple Developer Program (opłata roczna).
- [ ] Szablony eksportu iOS w Godocie i preset „iOS”: identyfikator `com.jeanpaulszefler.junkvsplants`, zespół (Team ID), podpisywanie automatyczne, tylko orientacja pozioma, iPhone i iPad.
- [ ] **Sieć lokalna na iOS.** iOS pyta o zgodę na sieć lokalną: w `Info.plist` potrzebny opis `NSLocalNetworkUsageDescription`. Wyszukiwanie znajomych przez rozgłoszenie UDP wymaga dodatkowo uprawnienia Apple „multicast networking” (`com.apple.developer.networking.multicast`), o które trzeba złożyć wniosek. Alternatywa: przejść na Bonjour (mDNS), który działa bez specjalnej zgody.
- [ ] Ikony we wszystkich rozmiarach (Godot generuje je z ikony 1024), ekran startowy.
- [ ] Testy na prawdziwym iPhonie i iPadzie przez Xcode, potem **TestFlight**: najpierw testerzy wewnętrzni, potem zewnętrzni (wymaga krótkiej recenzji Apple).
- [ ] Karta w App Store Connect: zrzuty dla największego iPhone'a i iPada, opisy w 7 językach, etykieta prywatności („Data Not Collected”), klasyfikacja wiekowa, kategoria (Games / Kids).
- [ ] Przegląd Apple: zakupy tylko przez StoreKit, bramka dla rodzica przy zakupach i linkach, brak reklam zewnętrznych w kategorii Kids.
- [ ] Wydanie, a po nim sprawdzanie raportów awarii w Xcode Organizer.

## 4. Kolejność prac (propozycja)

1. Wspólne przygotowanie (punkt 1) i klucz wydania Androida.
2. Google Play: test wewnętrzny na własnych telefonach, potem test zamknięty z rodziną i znajomymi.
3. W tym samym czasie wersja iOS: eksport, poprawki sieci lokalnej, TestFlight.
4. Wydanie w Google Play, a po przejściu przeglądu Apple — w App Store.

## 5. Jak testować grę lokalnie, gdy będzie już w sklepie

- **Dwie aplikacje na jednym telefonie.** Osobny preset eksportu „Junk vs Plants DEV” z innym identyfikatorem (np. `com.jeanpaulszefler.junkvsplants.dev`), inną nazwą i ikoną. Wersja testowa instaluje się obok wersji ze sklepu, ma własne zapisy i nic nie psuje w prawdziwej grze. Kod testowy i inne ułatwienia działają tylko w niej.
- **Szybkie próby z komputera.** Do codziennych zmian: Godot „Remote Debug / One-click Deploy” przez kabel USB albo Wi-Fi, albo APK z folderu `releases/` instalowany przez `adb install`.
- **Wersje przed wydaniem przez sklep.** Każdą kandydatkę do wydania wrzucać najpierw na ścieżkę testu wewnętrznego Google Play (jest na telefonie po kilku minutach) i do TestFlight na iOS. Tak testuje się dokładnie to, co dostaną gracze, z tym samym podpisem.
- **Test aktualizacji.** Przed każdym wydaniem: zainstalować poprzednią wersję ze sklepu, zagrać chwilę, potem zainstalować nową z testu wewnętrznego. Postęp, rubiny i ogród muszą zostać (gra sama przenosi stare zapisy na nowy format).
- **Gra z innym graczem** zawsze na dwóch prawdziwych telefonach w jednej sieci Wi-Fi (i raz przez hotspot), a na iOS także z zgodą na sieć lokalną.
