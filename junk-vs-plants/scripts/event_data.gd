class_name EventData
extends RefCounted

# Wydarzenia czasowe: kazde trwa DURATION_DAYS dni, potem znika razem z
# postepami gracza i zastepuje je nastepne z ROTATION. Czas liczy sie osobno
# dla kazdego konta, od pierwszego wejscia do gry, bo gra nie ma serwera.
# Kolejnosc i zasady zatwierdzone w ankiecie (WYDARZENIA.md).
#
# Pola zasad (wszystkie poza "planting" opcjonalne):
#   "planting"          "belt" (rosliny z tasmy, bez wody) albo "standard" (talia i krople)
#   "help"              pomoc kupowana przed etapem: {"type", "cost", "text"}
#   "banned_roles"      role roslin niedostepnych w talii
#   "enemy_hp", "enemy_speed", "enemy_count"  mnozniki wrogow
#   "narrow_rows"       jedyne rzedy, ktorymi ida wrogowie
#   "short_waves"       ile fal zostaje z poziomu
#   "boss_rush"         liczba kolejnych bossow na etap, zamiast zwyklych fal
#   "clean_piles"       kupki na start na etap; wygrywa ich zniszczenie
#   "final_rubies"      rubiny za pierwsze przejscie ostatniego etapu
#   "sky_drops", "darkness", "fog", "no_losses", "time_race", "coin_hunt",
#   "belt_preview", "forced_deck"  tryby opisane w main.gd i plant_select.gd
#   "fertilizer_every"  co tyle sekund sam pojawia sie nawoz, bez limitu
#   "shared_garden"     w tym tygodniu gracz moze wybrac sadzenie razem (ogrod)
const DURATION_DAYS := 7
const REPLAY_SAPLINGS := 1
# Poziom sciezki (trudnosc) i sadzonki za pierwsze przejscie kazdego etapu.
const STAGES := [
	{"level_idx": 1, "saplings": 2},
	{"level_idx": 5, "saplings": 2},
	{"level_idx": 11, "saplings": 3},
	{"level_idx": 20, "saplings": 3},
	{"level_idx": 35, "saplings": 4},
]
const BOSS_RUSH_HP_STEP := 0.25
# Lowy na roslimonety: progi tygodniowej sumy monet i sadzonki za nie.
const HUNT_THRESHOLDS := [
	{"coins": 50, "saplings": 2},
	{"coins": 150, "saplings": 2},
	{"coins": 300, "saplings": 3},
	{"coins": 500, "saplings": 3},
	{"coins": 800, "saplings": 4},
]
const HUNT_DROP_CHANCE := 0.25
const HUNT_COIN_VALUE := 5
# Sadzenie razem: wspolny cel tygodnia (zbiory obojga) i nagroda dla kazdego,
# 2 razy wieksza niz w samotnym ogrodzie. Jedna sadzonka dziennie dla znajomego
# za darmo, kazda nastepna za GIFT_COST roslimonet.
const SHARED_GOAL_HARVESTS := 8
const SHARED_REWARD_SAPLINGS := 4
const GIFT_COST := 30

const ROTATION := [
	{
		"id": "plant_belt", "name": "Tasma roslin", "planting": "belt",
		"description": "Bez wody i bez Kaktusow. Roslinki same pojawiaja sie na pasku - tapnij i posadz.",
	},
	{
		"id": "sky_drops", "name": "Krople z nieba", "planting": "standard",
		"description": "Nie ma Kaktusow, ale krople same spadaja z gory, coraz rzadziej. Zbieraj je szybko!",
		"banned_roles": ["generator"], "sky_drops": true,
		"help": {"type": "start_water", "cost": 50, "text": "50 kropel na start"},
	},
	{
		"id": "night", "name": "Nocny ogrod", "planting": "standard",
		"description": "Ciemno! Widac tylko pola wokol roslin, a wrogow dopiero, gdy podejda blizej.",
		"darkness": true,
		"help": {"type": "lantern", "cost": 40, "text": "Latarnia rozswietla jeden rzad"},
	},
	{
		"id": "fog", "name": "Mgla", "planting": "belt",
		"description": "Prawa polowa planszy jest pod mgla, ktora co jakis czas rzednie. Przewiduj, skad przyjda wrogowie.",
		"fog": true,
		"help": {"type": "fog_blow", "cost": 30, "text": "Podmuch rozwiewa mgle na 10 s"},
	},
	{
		"id": "cleanup", "name": "Wielkie sprzatanie", "planting": "belt",
		"description": "Na planszy leza kupki smieci. Zniszcz je wszystkie, zeby wygrac.",
		"clean_piles": [3, 4, 5, 6, 7], "final_rubies": 1,
		"help": {"type": "belt_vines", "cost": 40, "text": "Dodatkowe Pnacza na start"},
	},
	{
		"id": "fast", "name": "Mali, ale szybcy", "planting": "belt",
		"description": "Wrogowie maja o polowe mniej zycia, ale ida dwa razy szybciej.",
		"enemy_hp": 0.5, "enemy_speed": 2.0,
		"help": {"type": "belt_frost", "cost": 40, "text": "Mrozoroslinka gotowa od razu"},
	},
	{
		"id": "giants", "name": "Olbrzymy", "planting": "standard",
		"description": "Wrogow jest malo, ale maja 3 razy wiecej zycia i ida wolniej.",
		"enemy_hp": 3.0, "enemy_speed": 0.7, "enemy_count": 0.5,
		"help": {"type": "free_bomb", "cost": 50, "text": "Darmowy Bumorzech raz na etap"},
	},
	{
		"id": "narrow", "name": "Waskie gardlo", "planting": "standard",
		"description": "Wrogowie ida tylko rzedami 2 i 3, ale jest ich bardzo duzo.",
		"narrow_rows": [1, 2], "enemy_count": 2.0,
		"help": {"type": "start_fertilizer", "cost": 30, "text": "Dodatkowy nawoz na start"},
	},
	{
		"id": "forced_deck", "name": "Narzucona talia", "planting": "standard",
		"description": "Grasz 3 wylosowanymi roslinami, takze takimi, ktorych jeszcze nie masz. Zawsze jest wsrod nich Kaktus albo Megakaktus.",
		"forced_deck": true,
		"help": {"type": "fourth_plant", "cost": 40, "text": "Czwarta roslina do wyboru"},
	},
	{
		"id": "no_losses", "name": "Zadnych strat", "planting": "standard",
		"description": "Etap przepada, gdy stracisz choc jedna rosline. Fale sa za to krotkie.",
		"no_losses": true, "short_waves": 3, "final_rubies": 2,
		"help": {"type": "shield", "cost": 50, "text": "Tarcza raz ratuje rosline"},
	},
	{
		"id": "race", "name": "Wyscig", "planting": "belt",
		"description": "Pokonaj wszystkich, zanim minie czas. Im szybciej, tym wiecej gwiazdek i sadzonek.",
		"time_race": true,
		"help": {"type": "extra_time", "cost": 30, "text": "20 sekund wiecej"},
	},
	{
		"id": "crazy_fertilizer", "name": "Szalony nawoz", "planting": "belt",
		"description": "Nawozy pojawiaja sie bardzo czesto i nie ma ich limitu, ale wrogowie sa mocniejsi.",
		"fertilizer_every": 8.0, "enemy_hp": 1.5,
	},
	{
		"id": "boss_rush", "name": "Boss za bossem", "planting": "standard",
		"description": "Bez zwyklych fal: bossowie po kolei, coraz silniejsi, z krotka przerwa na sadzenie.",
		"boss_rush": [2, 3, 3, 4, 5], "final_rubies": 3,
		"help": {"type": "boss_water", "cost": 60, "text": "100 kropel miedzy bossami"},
	},
	{
		"id": "coin_hunt", "name": "Lowy na roslimonety", "planting": "standard",
		"description": "Pokonani wrogowie czasem upuszczaja monety - tapnij, zanim znikna. Liczy sie suma z tygodnia. W tym tygodniu mozesz tez sadzic razem ze znajomym.",
		"coin_hunt": true, "shared_garden": true,
	},
	{
		"id": "belt_preview", "name": "Tasma z podgladem", "planting": "belt",
		"description": "Jak Tasma roslin, ale widac 3 kolejne rosliny. Kazda mozna raz wymienic za 20 roslimonet.",
		"belt_preview": true, "preview_swap_cost": 20,
	},
]
