class_name GuideData
extends RefCounted

# Przewodnik po grze (notatki 2026-11-03, plan w PRZEWODNIK.md). Na poczatku
# "Opis gry" ma tylko podstawy, a kolejne funkcje odblokowuja sie po kolei,
# po przejsciu kilku poziomow. Kazdy krok:
#   "after"   ile poziomow sciezki trzeba miec za soba
#   "target"  przycisk na sciezce, na ktory wskazuje strzalka ("info" = Opis gry);
#             przycisk innej funkcji jest do tej pory zablokowany (klodka)
# Teksty: i18n/guide.gd, klucze "guide_<id>" (tytul) i "guide_<id>_text".
# Strzalka wskazuje zawsze tylko jeden krok naraz - pierwszy nieobejrzany.
const STEPS := [
	{"id": "basics", "after": 0, "target": "info"},
	{"id": "my_plants", "after": 1, "target": "my_plants"},
	{"id": "chests", "after": 3, "target": "shop"},
	{"id": "education", "after": 4, "target": "education"},
	{"id": "new_plants", "after": 5, "target": "info"},
	{"id": "bosses", "after": 6, "target": "info"},
	{"id": "event", "after": 7, "target": "event"},
	{"id": "garden", "after": 8, "target": "garden"},
	{"id": "fertilizer", "after": 9, "target": "info"},
	{"id": "match", "after": 11, "target": "match"},
	{"id": "piles", "after": 12, "target": "info"},
	{"id": "upgrades", "after": 13, "target": "my_plants"},
	{"id": "multiplayer", "after": 15, "target": "multiplayer"},
	{"id": "addons", "after": 17, "target": "addons"},
	{"id": "rent_slot", "after": 25, "target": "info"},
	{"id": "endless", "after": 60, "target": "info"},
]

static func is_unlocked(step: Dictionary) -> bool:
	return GameState.completed_level_count() >= step["after"]

# Krok, ktory odblokowuje dany przycisk (pierwszy z tym celem).
static func step_for_target(target: String) -> Dictionary:
	for step in STEPS:
		if step["target"] == target:
			return step
	return {}

static func is_target_unlocked(target: String) -> bool:
	var step := step_for_target(target)
	return step.is_empty() or is_unlocked(step)

# Pierwszy odblokowany, a jeszcze nieobejrzany krok (pusty, gdy wszystko widziane).
static func next_step() -> Dictionary:
	for step in STEPS:
		if is_unlocked(step) and not GameState.is_guide_seen(step["id"]):
			return step
	return {}

# Gracz otworzyl przycisk: kroki z tym celem sa obejrzane.
static func mark_target_seen(target: String) -> void:
	for step in STEPS:
		if step["target"] == target and is_unlocked(step):
			GameState.mark_guide_seen(step["id"])

static func unlocked_steps() -> Array:
	return STEPS.filter(func(step): return is_unlocked(step))
