class_name AddonData
extends RefCounted

# Dwie rotacje obok wydarzenia tygodnia (ankiety 2026-10-30 i 2026-11-03):
# dodatki i gry edukacyjne. Kazdy wpis trwa DURATION_DAYS dni, potem przychodzi
# nastepny, a po ostatnim rotacja zaczyna sie od poczatku. Postepy wpisu znikaja
# razem z nim (poza albumem naklejek). Nazwy i opisy sa w scripts/i18n/addons.gd
# pod kluczami "addon_<id>", "addon_<id>_desc" i "addon_<id>_help".
#
# kind: "combat"  etapy na planszy (main.gd), zasady jak w EventData
#       "path"    Budowanie sciezki (path_defense.gd), etapy
#       "maze"    Labirynt pszczolki (bee_maze.gd), etapy z gwiazdkami
#       "memory", "catch", "quiz", "sort_game"  mini-gry bez etapow
#       "album", "bingo", "duel"  wydarzenia meta (rotation_screen.gd)
const DURATION_DAYS := 5
const KIND_ADDON := "addon"
const KIND_EDU := "edu"

# Nagroda za pierwsze przejscie etapu (combat, path, maze). Powtorka daje
# REPLAY_COINS, a co REPLAY_SAPLING_EVERY wygrana powtorka takze sadzonke.
const STAGE_REWARDS := [
	{"saplings": 1},
	{"moves": 1},
	{"saplings": 2},
	{"moves": 1},
	{"saplings": 2, "rubies": 1},
]
const REPLAY_COINS := 10
const REPLAY_SAPLING_EVERY := 3

const ADDONS := [
	{"id": "memory", "kind": "memory", "help": {"type": "preview", "cost": 30}},
	{"id": "seasons", "kind": "combat", "planting": "standard", "seasons": true,
		"help": {"type": "umbrella", "cost": 40}},
	{"id": "catch", "kind": "catch"},
	{"id": "conveyor", "kind": "combat", "planting": "standard", "conveyor_rows": [1, 3],
		"help": {"type": "belt_stop", "cost": 30}},
	{"id": "bingo", "kind": "bingo", "help": {"type": "swap_task", "cost": 40}},
	{"id": "storm", "kind": "combat", "planting": "standard", "storm": true,
		"help": {"type": "rod", "cost": 40}},
	{"id": "maze", "kind": "maze"},
	{"id": "river", "kind": "combat", "planting": "standard", "river_row": 2,
		"help": {"type": "bridges", "cost": 30}},
	{"id": "album", "kind": "album"},
	{"id": "tree", "kind": "combat", "planting": "standard", "tree": true, "final_rubies": 2,
		"help": {"type": "tree_hp", "cost": 50}},
	{"id": "path_build", "kind": "path", "help": {"type": "stones", "cost": 40}},
	{"id": "treasures", "kind": "combat", "planting": "standard", "treasures": 6,
		"help": {"type": "detector", "cost": 30}},
	{"id": "swarm", "kind": "combat", "planting": "standard", "swarm": true,
		"help": {"type": "early_bee", "cost": 30}},
	{"id": "puzzle", "kind": "combat", "planting": "puzzle", "puzzle": true,
		"help": {"type": "hint", "cost": 20}},
	{"id": "duel", "kind": "duel"},
	{"id": "single_plant", "kind": "combat", "planting": "standard", "forced_deck": true, "single_plant": true,
		"help": {"type": "reroll", "cost": 30}},
	{"id": "seeds", "kind": "combat", "planting": "standard", "seeds": true,
		"help": {"type": "double_seeds", "cost": 30}},
	{"id": "transplant", "kind": "combat", "planting": "standard", "transplant": true, "enemy_speed": 1.3,
		"help": {"type": "fast_move", "cost": 30}},
	{"id": "animals", "kind": "combat", "planting": "standard", "animals": true,
		"help": {"type": "weak_cages", "cost": 30}},
	{"id": "invisible", "kind": "combat", "planting": "standard", "invisible": true,
		"help": {"type": "firefly", "cost": 30}},
	{"id": "giant", "kind": "combat", "planting": "standard", "giant": true, "enemy_hp": 1.3,
		"help": {"type": "giant_boost", "cost": 40}},
]

# Gry edukacyjne: osobna rotacja i osobny przycisk na sciezce.
const EDU := [
	{"id": "quiz", "kind": "quiz"},
	{"id": "sort_game", "kind": "sort_game"},
	{"id": "sorting", "kind": "combat", "planting": "standard", "sorting": true},
]

static func entries(kind: String) -> Array:
	return EDU if kind == KIND_EDU else ADDONS

static func has_stages(entry: Dictionary) -> bool:
	return ["combat", "path", "maze"].has(entry.get("kind", ""))

static func title(entry: Dictionary) -> String:
	return Lang.t("addon_" + entry["id"])

static func description(entry: Dictionary) -> String:
	return Lang.t("addon_%s_desc" % entry["id"])

static func help_text(entry: Dictionary) -> String:
	return Lang.t("addon_%s_help" % entry["id"])

# --- Pory roku: kazdy etap ma swoja pore, ostatni zmienia je co chwile ---
const SEASONS := ["spring", "summer", "autumn", "winter"]
const SEASON_CYCLE_TIME := 30.0

static func season_for_stage(stage: int) -> int:
	return stage if stage < SEASONS.size() else -1

# --- Sortowanie smieci: pojemnik kazdego rodzaju smiecia (indeksy w main.gd
# ENEMY_TYPES i BossData.TYPES) ---
const BIN_YELLOW := "yellow"
const BIN_BLUE := "blue"
const BIN_BLACK := "black"
const BIN_COLORS := {
	"yellow": Color(0.98, 0.85, 0.15),
	"blue": Color(0.2, 0.45, 0.95),
	"green": Color(0.2, 0.7, 0.3),
	"brown": Color(0.55, 0.33, 0.15),
	"black": Color(0.15, 0.15, 0.15),
}
# Butelka i puszka do zoltego, karton do niebieskiego, brudna gabka do czarnego.
const ENEMY_BINS := ["yellow", "yellow", "blue", "black"]
# Puszkowy Tyran, Foliowy Duch, Magnetyczny Zlomiarz - zolty; Kompaktor i Kolos - czarny.
const BOSS_BINS := ["yellow", "yellow", "black", "yellow", "black"]

# --- Zagadka obronna: gotowe plansze. "plants": [indeks rosliny, kolumna, rzad],
# "deck": rosliny do dosadzenia, "water": krople, "wave": wrogowie jednej fali,
# "hint": [kolumna, rzad, indeks rosliny] - podpowiedz z pomocy. ---
const PUZZLES := [
	{
		"plants": [[0, 0, 2]], "deck": [0], "water": 100,
		"wave": [{"type": 0, "row": 0}, {"type": 0, "row": 2}, {"type": 0, "row": 4}, {"type": 1, "row": 0}, {"type": 1, "row": 4}],
		"hint": [0, 0, 0],
	},
	{
		"plants": [[0, 0, 1], [0, 0, 3]], "deck": [0, 2], "water": 150,
		"wave": [{"type": 2, "row": 2}, {"type": 0, "row": 1}, {"type": 0, "row": 3}, {"type": 1, "row": 0}, {"type": 1, "row": 4}, {"type": 0, "row": 2}],
		"hint": [1, 2, 0],
	},
	{
		"plants": [[0, 0, 0], [0, 0, 4], [2, 3, 2]], "deck": [0, 5], "water": 130,
		"wave": [{"type": 2, "row": 2}, {"type": 2, "row": 2}, {"type": 1, "row": 1}, {"type": 1, "row": 3}, {"type": 0, "row": 0}, {"type": 0, "row": 4}, {"type": 1, "row": 1}],
		"hint": [0, 2, 0],
	},
	{
		"plants": [[0, 1, 1], [0, 1, 3], [4, 4, 2]], "deck": [0, 6, 8], "water": 160,
		"wave": [{"type": 2, "row": 0}, {"type": 2, "row": 4}, {"type": 2, "row": 2}, {"type": 0, "row": 1}, {"type": 0, "row": 3}, {"type": 1, "row": 0}, {"type": 1, "row": 4}, {"type": 3, "row": 2}],
		"hint": [0, 0, 0],
	},
	{
		"plants": [[0, 0, 0], [0, 0, 2], [0, 0, 4], [2, 3, 1], [2, 3, 3]], "deck": [0, 6, 7, 5], "water": 200,
		"wave": [{"type": 2, "row": 1}, {"type": 2, "row": 3}, {"type": 2, "row": 2}, {"type": 0, "row": 0}, {"type": 0, "row": 4}, {"type": 1, "row": 1}, {"type": 1, "row": 3}, {"type": 3, "row": 2}, {"type": 2, "row": 0}],
		"hint": [1, 2, 0],
	},
]

# --- Uwolnij zwierzatka ---
const ANIMALS := ["hedgehog", "bird", "frog", "butterfly"]
const CAGE_COUNTS := [3, 3, 4, 4, 5]

# --- Pszczeli roj: odstep miedzy pszczolkami na kolejnych etapach ---
const SWARM_INTERVALS := [[20.0, 24.0], [21.0, 26.0], [22.0, 27.0], [24.0, 29.0], [25.0, 30.0]]
const SWARM_BONUSES := ["recharge", "slow", "water"]

# --- Niewidzialne smieci: czesc niewidocznych wrogow na kolejnych etapach ---
const INVISIBLE_SHARE := [0.3, 0.37, 0.45, 0.52, 0.6]

# --- Bingo: zadania z licznikami w GameState (bingo_count) ---
# "goal" to ile razy trzeba to zrobic; nazwy w addons.gd jako "bingo_<id>".
const BINGO_TASKS := [
	{"id": "plant_corn", "goal": 10},
	{"id": "plant_cactus", "goal": 10},
	{"id": "plant_any", "goal": 40},
	{"id": "boss", "goal": 1},
	{"id": "fertilizer", "goal": 3},
	{"id": "win_level", "goal": 2},
	{"id": "win_no_loss", "goal": 1},
	{"id": "garden_collect", "goal": 1},
	{"id": "match_move", "goal": 3},
	{"id": "event_stage", "goal": 1},
	{"id": "kill", "goal": 60},
	{"id": "pile", "goal": 2},
	{"id": "water", "goal": 30},
	{"id": "chest_or_shop", "goal": 1},
	{"id": "upgrade", "goal": 1},
	{"id": "garden_water", "goal": 2},
	{"id": "addon_game", "goal": 2},
	{"id": "freeze", "goal": 3},
	{"id": "one_shot", "goal": 5},
	{"id": "remove", "goal": 1},
]
const BINGO_SIZE := 4
const BINGO_CARD_RUBIES := 5

# --- Album naklejek: 3 strony po 8 naklejek ---
# Naklejki to rosliny ("p<i>"), smieciostwory ("e<i>"), bossowie ("b<i>") i pszczolka.
const ALBUM_PAGE_SIZE := 8
const ALBUM_PAGE_RUBIES := 5

static func album_stickers() -> Array:
	var result := []
	for i in range(PlantData.TYPES.size()):
		result.append("p%d" % i)
	for i in range(4):
		result.append("e%d" % i)
	for i in range(BossData.TYPES.size()):
		result.append("b%d" % i)
	result.append("bee")
	return result

# --- Pojedynek: nagroda za wygrana w tygodniu pojedynkow, raz dziennie ---
const DUEL_WEEK_RUBIES := 1
const DUEL_WEEK_COINS := 30

# --- Lapanie kropli i Sortownia: progi wyniku i sadzonki (kazdy prog raz) ---
const CATCH_THRESHOLDS := [{"score": 100, "saplings": 1}, {"score": 250, "saplings": 2}, {"score": 500, "saplings": 3}]
const SORT_THRESHOLDS := [{"score": 15, "saplings": 1}, {"score": 30, "saplings": 2}, {"score": 50, "saplings": 3}]

# --- Smieci do Quizu i Sortowni: [id, pojemnik] wedlug zasad segregacji w Polsce.
# Nazwy w i18n/quiz.gd ("trash_<id>"), grafiki opcjonalnie w ui/trash_<id>.png. ---
const BINS := ["yellow", "blue", "green", "brown", "black"]
const TRASH_ITEMS := [
	["plastic_bottle", "yellow"], ["drink_can", "yellow"], ["yogurt_cup", "yellow"],
	["plastic_bag", "yellow"], ["juice_carton", "yellow"], ["milk_carton", "yellow"],
	["bottle_cap", "yellow"], ["food_tin", "yellow"], ["chips_bag", "yellow"], ["shampoo_bottle", "yellow"],
	["newspaper", "blue"], ["cardboard_box", "blue"], ["notebook", "blue"], ["paper_bag", "blue"],
	["egg_carton", "blue"], ["magazine", "blue"], ["paper_flyer", "blue"], ["envelope", "blue"],
	["glass_bottle", "green"], ["jam_jar", "green"], ["perfume_bottle", "green"],
	["juice_glass_bottle", "green"], ["cream_jar", "green"],
	["banana_peel", "brown"], ["apple_core", "brown"], ["eggshells", "brown"], ["vegetable_peels", "brown"],
	["coffee_grounds", "brown"], ["dry_leaves", "brown"], ["wilted_flowers", "brown"], ["orange_peel", "brown"],
	["used_tissue", "black"], ["broken_mug", "black"], ["greasy_pizza_box", "black"], ["receipt", "black"],
	["dirty_sponge", "black"], ["old_toothbrush", "black"], ["broken_mirror", "black"], ["diaper", "black"],
]

# --- Quiz: raz dziennie 5 pytan ---
const QUIZ_QUESTIONS := 5
const QUIZ_COINS_PER_ANSWER := 20
