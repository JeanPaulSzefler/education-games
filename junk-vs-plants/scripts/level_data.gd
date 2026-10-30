class_name LevelData
extends RefCounted

# Kazdy poziom to lista fal, kazda fala to lista {type, row} (type = indeks w
# ENEMY_TYPES w main.gd). "boss" to indeks w BossData.TYPES, -1 = bez bossa,
# spawnowany po ostatniej fali; "boss_hp_multiplier" mnozy jego HP (domyslnie 1.0).
# "cactus_water_multiplier" mnozy odstep czasu miedzy kroplami z Kaktusa
# (domyslnie 1.0). "blocked_tiles" to pola, na ktorych nie mozna sadzic.
# "junk_pile_waves" (od poziomu 7, kiedy dochodza Pnacza) to indeksy fal, na
# poczatku ktorych na planszy pojawia sie nowa kupka smieci - z kazdej kupki
# na starcie kazdej kolejnej fali wychodzi jeden wrog (patrz main.gd).
#
# TWARDA ZASADA: 1. fala kazdego poziomu ma najwyzej 4 wrogow (i nigdy nie
# ma w niej nowej kupki smieci - "junk_pile_waves" zaczyna sie od 1). main.gd
# i tak przycina 1. fale do MAX_FIRST_WAVE_ENEMIES, ale dane maja to spelniac.
#
# Ponizej sa plansze bazowe; kazda daje dwa poziomy sciezki (patrz _build_levels).
#
# Zasada ukladania fal: liczba wrogow w zwyklych falach rosnie lagodnie z
# poziomem (poz. 1: 1-3 na fale, poz. 17: 5-8 na fale, poz. 28: 7-11).
# Ostatnia fala na kazdym poziomie jest zawsze najwieksza: bez bossa - ok. 2x
# (od poz. 18: ok. 1,6x) tyle wrogow co najwieksza z wczesniejszych fal; z
# bossem - ok. 1,3x tyle (boss i tak domyka finał).
# Uwaga: od 3. fali wzwyz main.gd doklada do kazdej fali dodatkowych wrogow
# (EXTRA_ENEMIES_FROM_WAVE_3), wiec realnie sa one ok. 2x wieksze niz tutaj.
# Gra zespolowa ponizej pierwszego poziomu z bossem: slabszy boss.
const TEAM_FIRST_FULL_BOSS_LEVEL := 5
const TEAM_EARLY_BOSS_HP := 0.6

const BASE_LEVELS := [
	{
		"name": "Poziom 1 - Podworko",
		"boss": -1,
		"cactus_water_multiplier": 1.0,
		"waves": [
			[{"type": 0, "row": 2}],
			[{"type": 0, "row": 1}, {"type": 1, "row": 3}],
			[{"type": 1, "row": 2}, {"type": 0, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 2 - Park",
		"boss": -1,
		"cactus_water_multiplier": 1.0,
		"waves": [
			[{"type": 0, "row": 1}, {"type": 0, "row": 3}],
			[{"type": 1, "row": 2}, {"type": 1, "row": 0}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 2}, {"type": 0, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 3 - Wysypisko",
		"boss": 0,
		"cactus_water_multiplier": 1.0,
		"waves": [
			[{"type": 1, "row": 0}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 1}, {"type": 0, "row": 3}],
			[{"type": 2, "row": 2}, {"type": 1, "row": 1}, {"type": 0, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 2}, {"type": 0, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 2, "row": 3}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 4 - Sortownia Odpadow",
		"boss": -1,
		"cactus_water_multiplier": 1.0,
		"waves": [
			[{"type": 0, "row": 1}, {"type": 1, "row": 3}],
			[{"type": 1, "row": 0}, {"type": 0, "row": 2}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 2}, {"type": 0, "row": 0}, {"type": 1, "row": 1}],
			[{"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 0, "row": 4}],
		],
	},
	{
		"name": "Poziom 5 - Skladowisko",
		"boss": -1,
		"cactus_water_multiplier": 1.0,
		"waves": [
			[{"type": 0, "row": 0}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 3}],
			[{"type": 2, "row": 2}, {"type": 0, "row": 1}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 0, "row": 3}, {"type": 1, "row": 2}],
			[{"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 4}],
		],
	},
	{
		# Gabka (typ 3, kradnie krople wody) pojawia sie od tego poziomu.
		"name": "Poziom 6 - Plac Zabaw",
		"boss": 1,
		"cactus_water_multiplier": 1.1,
		"waves": [
			[{"type": 0, "row": 0}, {"type": 1, "row": 2}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 0, "row": 3}, {"type": 2, "row": 2}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 3, "row": 0}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 7 - Ogrodki Dzialkowe",
		"boss": -1,
		"cactus_water_multiplier": 1.1,
		"junk_pile_waves": [1, 3],
		"waves": [
			[{"type": 0, "row": 1}, {"type": 1, "row": 3}, {"type": 3, "row": 2}],
			[{"type": 2, "row": 2}, {"type": 1, "row": 0}, {"type": 0, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 3, "row": 0}, {"type": 0, "row": 2}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 1}, {"type": 0, "row": 0}, {"type": 1, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 8 - Brzeg Rzeki",
		"boss": -1,
		"cactus_water_multiplier": 1.2,
		"blocked_tiles": [[5, 2]],
		"waves": [
			[{"type": 0, "row": 0}, {"type": 3, "row": 2}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 0, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 0, "row": 1}, {"type": 1, "row": 2}, {"type": 3, "row": 0}, {"type": 2, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 0, "row": 3}, {"type": 3, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 9 - Parking",
		"boss": 2,
		"cactus_water_multiplier": 1.2,
		"junk_pile_waves": [2],
		"blocked_tiles": [[3, 1]],
		"waves": [
			[{"type": 0, "row": 1}, {"type": 3, "row": 3}, {"type": 1, "row": 0}],
			[{"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 0, "row": 4}, {"type": 3, "row": 0}],
			[{"type": 2, "row": 0}, {"type": 1, "row": 2}, {"type": 3, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 2, "row": 3}, {"type": 0, "row": 4}],
		],
	},
	{
		"name": "Poziom 10 - Targowisko",
		"boss": -1,
		"cactus_water_multiplier": 1.25,
		"junk_pile_waves": [2],
		"blocked_tiles": [[2, 0], [6, 3]],
		"waves": [
			[{"type": 0, "row": 0}, {"type": 1, "row": 2}, {"type": 3, "row": 4}],
			[{"type": 2, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 3, "row": 0}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 1, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 11 - Dworzec",
		"boss": -1,
		"cactus_water_multiplier": 1.25,
		"junk_pile_waves": [1, 3],
		"blocked_tiles": [[4, 1], [7, 3]],
		"waves": [
			[{"type": 0, "row": 2}, {"type": 1, "row": 4}, {"type": 3, "row": 0}],
			[{"type": 2, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 1}, {"type": 1, "row": 2}, {"type": 3, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 0, "row": 4}, {"type": 2, "row": 4}],
		],
	},
	{
		"name": "Poziom 12 - Port",
		"boss": 3,
		"cactus_water_multiplier": 1.3,
		"blocked_tiles": [[3, 0], [6, 3]],
		"waves": [
			[{"type": 0, "row": 0}, {"type": 1, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 1}, {"type": 1, "row": 2}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 1}, {"type": 1, "row": 3}, {"type": 3, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 3}, {"type": 1, "row": 4}, {"type": 0, "row": 4}],
		],
	},
	{
		"name": "Poziom 13 - Zlomowisko",
		"boss": -1,
		"cactus_water_multiplier": 1.3,
		"junk_pile_waves": [1, 3],
		"blocked_tiles": [[2, 0], [5, 2], [7, 4]],
		"waves": [
			[{"type": 0, "row": 1}, {"type": 1, "row": 3}, {"type": 2, "row": 0}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 2}, {"type": 1, "row": 2}, {"type": 3, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 4}, {"type": 3, "row": 4}],
		],
	},
	{
		"name": "Poziom 14 - Oczyszczalnia",
		"boss": -1,
		"cactus_water_multiplier": 1.35,
		"blocked_tiles": [[3, 0], [6, 2], [4, 4]],
		"waves": [
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 1}, {"type": 1, "row": 2}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 1}, {"type": 1, "row": 3}, {"type": 3, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 3}, {"type": 1, "row": 4}, {"type": 0, "row": 4}],
		],
	},
	{
		"name": "Poziom 15 - Hala Recyklingu",
		"boss": 4,
		"boss_hp_multiplier": 1.3,
		"cactus_water_multiplier": 1.35,
		"junk_pile_waves": [2],
		"blocked_tiles": [[1, 1], [5, 3], [8, 0]],
		"waves": [
			[{"type": 0, "row": 1}, {"type": 1, "row": 3}, {"type": 2, "row": 0}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 1}, {"type": 1, "row": 2}, {"type": 3, "row": 3}, {"type": 0, "row": 4}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 3}, {"type": 3, "row": 4}, {"type": 0, "row": 4}],
		],
	},
	{
		"name": "Poziom 16 - Stara Fabryka",
		"boss": -1,
		"cactus_water_multiplier": 1.4,
		"junk_pile_waves": [1, 2, 4],
		"blocked_tiles": [[2, 2], [5, 0], [7, 4]],
		"waves": [
			[{"type": 0, "row": 0}, {"type": 1, "row": 2}, {"type": 2, "row": 4}, {"type": 3, "row": 1}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 1}, {"type": 1, "row": 2}, {"type": 3, "row": 3}, {"type": 2, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 3}, {"type": 1, "row": 4}, {"type": 0, "row": 4}, {"type": 2, "row": 4}],
		],
	},
	{
		"name": "Poziom 17 - Gora Smieci",
		"boss": -1,
		"cactus_water_multiplier": 1.4,
		"junk_pile_waves": [1, 3],
		"blocked_tiles": [[3, 1], [6, 3], [8, 0]],
		"waves": [
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 1, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 1, "row": 2}, {"type": 3, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 3}, {"type": 1, "row": 4}, {"type": 0, "row": 4}],
		],
	},
	{
		"name": "Poziom 18 - Wysypisko Elektrosmieci",
		"boss": 0,
		"boss_hp_multiplier": 2.0,
		"cactus_water_multiplier": 1.42,
		"blocked_tiles": [[2, 1], [6, 3], [8, 0]],
		"junk_pile_waves": [2],
		"waves": [
			[{"type": 0, "row": 2}, {"type": 0, "row": 4}, {"type": 0, "row": 4}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 2, "row": 3}],
			[{"type": 2, "row": 0}, {"type": 2, "row": 0}, {"type": 3, "row": 2}, {"type": 2, "row": 4}, {"type": 1, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 4}, {"type": 3, "row": 4}, {"type": 2, "row": 4}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 1}, {"type": 1, "row": 1}, {"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 2}, {"type": 0, "row": 2}, {"type": 0, "row": 3}, {"type": 1, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 0, "row": 0}, {"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 2, "row": 2}, {"type": 3, "row": 2}, {"type": 2, "row": 2}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 19 - Zatoka Plastiku",
		"boss": -1,
		"cactus_water_multiplier": 1.44,
		"blocked_tiles": [[3, 0], [5, 2], [7, 4]],
		"junk_pile_waves": [1, 2, 4],
		"waves": [
			[{"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 1, "row": 4}, {"type": 3, "row": 4}],
			[{"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 0, "row": 2}, {"type": 0, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 3, "row": 0}, {"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 1, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 1, "row": 0}, {"type": 1, "row": 0}, {"type": 3, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 4}, {"type": 1, "row": 4}, {"type": 2, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 2}, {"type": 1, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 3}, {"type": 0, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 1, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 1}, {"type": 1, "row": 1}, {"type": 1, "row": 1}, {"type": 0, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 3}, {"type": 1, "row": 4}, {"type": 0, "row": 4}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 20 - Tunel Kanalizacji",
		"boss": -1,
		"cactus_water_multiplier": 1.46,
		"blocked_tiles": [[1, 3], [4, 1], [7, 2]],
		"junk_pile_waves": [2],
		"waves": [
			[{"type": 1, "row": 1}, {"type": 3, "row": 3}, {"type": 3, "row": 3}],
			[{"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 1, "row": 1}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 0, "row": 1}, {"type": 0, "row": 3}, {"type": 1, "row": 4}, {"type": 0, "row": 4}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 2}, {"type": 0, "row": 3}, {"type": 3, "row": 3}, {"type": 0, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 0, "row": 0}, {"type": 3, "row": 0}, {"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 2, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 21 - Stara Kopalnia",
		"boss": 1,
		"boss_hp_multiplier": 2.2,
		"cactus_water_multiplier": 1.48,
		"blocked_tiles": [[2, 4], [5, 0], [8, 2]],
		"junk_pile_waves": [1, 3],
		"waves": [
			[{"type": 0, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 4}],
			[{"type": 1, "row": 1}, {"type": 1, "row": 2}, {"type": 2, "row": 2}, {"type": 1, "row": 2}, {"type": 1, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 0, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 2}, {"type": 3, "row": 2}, {"type": 1, "row": 4}, {"type": 2, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 0, "row": 1}, {"type": 2, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 4}, {"type": 1, "row": 4}, {"type": 3, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 3, "row": 1}, {"type": 0, "row": 1}, {"type": 0, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 2, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 0, "row": 1}, {"type": 2, "row": 1}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 1, "row": 1}, {"type": 1, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 1}, {"type": 1, "row": 2}, {"type": 0, "row": 3}, {"type": 1, "row": 3}, {"type": 2, "row": 4}],
		],
	},
	{
		"name": "Poziom 22 - Spalarnia",
		"boss": -1,
		"cactus_water_multiplier": 1.5,
		"blocked_tiles": [[3, 2], [6, 0], [6, 4]],
		"junk_pile_waves": [1, 3, 5],
		"waves": [
			[{"type": 0, "row": 0}, {"type": 0, "row": 3}, {"type": 0, "row": 4}, {"type": 3, "row": 4}],
			[{"type": 2, "row": 2}, {"type": 0, "row": 3}, {"type": 2, "row": 4}, {"type": 1, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 1, "row": 1}, {"type": 0, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 2}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 1, "row": 2}, {"type": 3, "row": 2}, {"type": 3, "row": 3}, {"type": 0, "row": 3}, {"type": 0, "row": 3}, {"type": 0, "row": 3}, {"type": 2, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 0, "row": 0}, {"type": 0, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 4}, {"type": 0, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 2, "row": 0}, {"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 3}, {"type": 3, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 3}, {"type": 1, "row": 3}, {"type": 1, "row": 4}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 23 - Bagna Zanieczyszczen",
		"boss": -1,
		"cactus_water_multiplier": 1.52,
		"blocked_tiles": [[2, 0], [4, 3], [7, 1], [8, 4]],
		"waves": [
			[{"type": 0, "row": 1}, {"type": 0, "row": 2}, {"type": 0, "row": 3}, {"type": 3, "row": 3}],
			[{"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 1, "row": 3}, {"type": 3, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 1, "row": 2}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 0, "row": 0}, {"type": 0, "row": 1}, {"type": 0, "row": 2}, {"type": 3, "row": 3}, {"type": 3, "row": 4}, {"type": 0, "row": 4}, {"type": 0, "row": 4}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 3, "row": 0}, {"type": 0, "row": 1}, {"type": 0, "row": 2}, {"type": 0, "row": 3}, {"type": 3, "row": 3}, {"type": 0, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 0}, {"type": 3, "row": 0}, {"type": 1, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 2}, {"type": 0, "row": 3}, {"type": 3, "row": 3}, {"type": 2, "row": 3}, {"type": 2, "row": 4}, {"type": 0, "row": 4}, {"type": 2, "row": 4}],
		],
	},
	{
		"name": "Poziom 24 - Opuszczone Lotnisko",
		"boss": 2,
		"boss_hp_multiplier": 1.8,
		"cactus_water_multiplier": 1.54,
		"blocked_tiles": [[1, 2], [5, 1], [8, 3]],
		"junk_pile_waves": [2, 4],
		"waves": [
			[{"type": 0, "row": 1}, {"type": 3, "row": 1}, {"type": 0, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 3, "row": 1}, {"type": 2, "row": 2}, {"type": 2, "row": 3}, {"type": 2, "row": 3}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 0}, {"type": 0, "row": 0}, {"type": 0, "row": 0}, {"type": 3, "row": 1}, {"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 0, "row": 2}],
			[{"type": 3, "row": 0}, {"type": 1, "row": 0}, {"type": 0, "row": 0}, {"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 3, "row": 4}, {"type": 3, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 2, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 1, "row": 0}, {"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 3}, {"type": 0, "row": 3}, {"type": 1, "row": 4}, {"type": 1, "row": 4}, {"type": 1, "row": 4}, {"type": 3, "row": 4}, {"type": 0, "row": 4}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 25 - Dzielnica Przemyslowa",
		"boss": -1,
		"cactus_water_multiplier": 1.56,
		"blocked_tiles": [[3, 0], [3, 4], [6, 2], [8, 1]],
		"junk_pile_waves": [1, 2, 4],
		"waves": [
			[{"type": 1, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 3}],
			[{"type": 0, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 2}, {"type": 2, "row": 3}, {"type": 1, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 0, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 2}, {"type": 0, "row": 4}, {"type": 3, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 1, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 3}, {"type": 3, "row": 4}, {"type": 2, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 2, "row": 0}, {"type": 1, "row": 0}, {"type": 1, "row": 2}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 3}, {"type": 0, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 1, "row": 1}, {"type": 1, "row": 2}, {"type": 2, "row": 2}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 0, "row": 3}, {"type": 1, "row": 3}, {"type": 3, "row": 4}, {"type": 2, "row": 4}, {"type": 3, "row": 4}, {"type": 0, "row": 4}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 26 - Wulkan Odpadow",
		"boss": -1,
		"cactus_water_multiplier": 1.58,
		"blocked_tiles": [[2, 2], [5, 0], [5, 4], [7, 2]],
		"junk_pile_waves": [1, 3],
		"waves": [
			[{"type": 1, "row": 0}, {"type": 0, "row": 2}, {"type": 3, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 0}, {"type": 3, "row": 0}, {"type": 0, "row": 0}, {"type": 1, "row": 2}, {"type": 1, "row": 2}, {"type": 1, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 2, "row": 0}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 1, "row": 2}, {"type": 2, "row": 3}, {"type": 2, "row": 3}, {"type": 0, "row": 3}, {"type": 3, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 3}, {"type": 1, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 2, "row": 2}, {"type": 2, "row": 3}, {"type": 3, "row": 3}, {"type": 2, "row": 3}, {"type": 2, "row": 4}, {"type": 3, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 0, "row": 0}, {"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 1, "row": 2}, {"type": 3, "row": 2}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 4}, {"type": 2, "row": 4}],
		],
	},
	{
		"name": "Poziom 27 - Krawedz Wysypiska",
		"boss": -1,
		"cactus_water_multiplier": 1.6,
		"blocked_tiles": [[1, 0], [4, 2], [6, 4], [8, 1]],
		"junk_pile_waves": [1, 2, 4],
		"waves": [
			[{"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 3}],
			[{"type": 0, "row": 0}, {"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 0, "row": 1}, {"type": 0, "row": 2}, {"type": 3, "row": 3}, {"type": 2, "row": 3}, {"type": 2, "row": 4}, {"type": 0, "row": 4}, {"type": 2, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 1, "row": 0}, {"type": 0, "row": 0}, {"type": 2, "row": 1}, {"type": 0, "row": 2}, {"type": 1, "row": 3}, {"type": 2, "row": 4}, {"type": 2, "row": 4}, {"type": 1, "row": 4}, {"type": 3, "row": 4}],
			[{"type": 0, "row": 0}, {"type": 3, "row": 0}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 0, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 3}, {"type": 2, "row": 3}, {"type": 1, "row": 3}, {"type": 1, "row": 3}, {"type": 0, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 3, "row": 0}, {"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 2}, {"type": 2, "row": 2}, {"type": 3, "row": 2}, {"type": 1, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 3}, {"type": 1, "row": 3}, {"type": 1, "row": 3}, {"type": 2, "row": 3}, {"type": 2, "row": 4}, {"type": 2, "row": 4}, {"type": 1, "row": 4}, {"type": 1, "row": 4}],
		],
	},
	{
		"name": "Poziom 28 - Serce Gory Smieci",
		"boss": 4,
		"boss_hp_multiplier": 2.2,
		"cactus_water_multiplier": 1.6,
		"blocked_tiles": [[2, 1], [4, 3], [6, 0], [7, 4], [8, 2]],
		"junk_pile_waves": [1, 3, 5],
		"waves": [
			[{"type": 0, "row": 1}, {"type": 3, "row": 2}, {"type": 1, "row": 3}, {"type": 1, "row": 4}],
			[{"type": 1, "row": 0}, {"type": 0, "row": 1}, {"type": 1, "row": 1}, {"type": 3, "row": 2}, {"type": 0, "row": 2}, {"type": 2, "row": 2}, {"type": 2, "row": 3}],
			[{"type": 1, "row": 0}, {"type": 0, "row": 0}, {"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 2}, {"type": 3, "row": 2}, {"type": 3, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 1, "row": 2}, {"type": 1, "row": 2}, {"type": 0, "row": 2}, {"type": 3, "row": 3}, {"type": 3, "row": 3}, {"type": 2, "row": 4}],
			[{"type": 2, "row": 0}, {"type": 3, "row": 0}, {"type": 0, "row": 0}, {"type": 2, "row": 0}, {"type": 0, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 2}, {"type": 3, "row": 3}, {"type": 2, "row": 4}, {"type": 1, "row": 4}],
			[{"type": 3, "row": 0}, {"type": 2, "row": 0}, {"type": 2, "row": 0}, {"type": 1, "row": 1}, {"type": 2, "row": 2}, {"type": 3, "row": 3}, {"type": 1, "row": 3}, {"type": 2, "row": 3}, {"type": 2, "row": 3}, {"type": 3, "row": 3}, {"type": 2, "row": 4}, {"type": 0, "row": 4}],
			[{"type": 0, "row": 1}, {"type": 1, "row": 1}, {"type": 2, "row": 1}, {"type": 0, "row": 1}, {"type": 3, "row": 1}, {"type": 2, "row": 1}, {"type": 2, "row": 1}, {"type": 3, "row": 1}, {"type": 0, "row": 2}, {"type": 2, "row": 2}, {"type": 1, "row": 3}, {"type": 0, "row": 3}, {"type": 2, "row": 3}, {"type": 0, "row": 4}, {"type": 2, "row": 4}, {"type": 3, "row": 4}],
		],
	},
	{
		# Tryb nieskonczony: odblokowuje sie po ostatnim poziomie. Fale (lacznie z
		# bossami) generuje main.gd -> _generate_endless_wave(); gra trwa, az
		# smieci dotra do domu, a wynikiem jest liczba pokonanych wrogow.
		"name": "Tryb nieskonczony - Wieczna Gora Smieci",
		"endless": true,
		"boss": -1,
		"cactus_water_multiplier": 1.0,
		"waves": [],
	},
]

# Sciezka: kazda plansza bazowa daje dwa kolejne poziomy, zeby rosliny mogly
# odblokowywac sie co ok. 5 poziomow (notatki 2026-10-30), a trudnosc rosla
# tak samo wzgledem liczby roslin. Druga czesc ma lustrzanie ulozone rzedy i
# bossa planszy, wiec boss przychodzi co 6 poziomow i na ostatnim. Tryb
# nieskonczony zostaje na koncu.
static var LEVELS: Array = _build_levels()

static func _build_levels() -> Array:
	var result := []
	for i in range(BASE_LEVELS.size()):
		var base: Dictionary = BASE_LEVELS[i]
		if base.get("endless", false):
			result.append(base)
			continue
		var place: String = base["name"].get_slice(" - ", 1)
		var first: Dictionary = base.duplicate(true)
		first["name"] = "Poziom %d - %s" % [result.size() + 1, place]
		first["boss"] = -1
		first.erase("boss_hp_multiplier")
		if i > 0:
			first["cactus_water_multiplier"] = (base["cactus_water_multiplier"] + BASE_LEVELS[i - 1]["cactus_water_multiplier"]) / 2.0
		result.append(first)
		var second := _mirrored(base)
		second["name"] = "Poziom %d - %s II" % [result.size() + 1, place]
		result.append(second)
	return result

static func _mirrored(base: Dictionary) -> Dictionary:
	var level: Dictionary = base.duplicate(true)
	var last_row := 4
	for wave in level["waves"]:
		for enemy in wave:
			enemy["row"] = last_row - enemy["row"]
	for tile in level.get("blocked_tiles", []):
		tile[1] = last_row - tile[1]
	return level

# Ile nawozow pojawia sie samych na planszy w trakcie poziomu.
static func fertilizer_count(level_idx: int) -> int:
	if level_idx < 8:
		return 0
	if level_idx < 24:
		return 1
	return 2 if level_idx < 40 else 3

# Plansza gry zespolowej: trudnosc poziomu sredniego obu graczy, zawsze z bossem.
static func team_level(difficulty_idx: int, boss_idx: int) -> Dictionary:
	var level: Dictionary = LEVELS[difficulty_idx].duplicate(true)
	level["name"] = "Gra zespolowa"
	level["boss"] = boss_idx
	if difficulty_idx < TEAM_FIRST_FULL_BOSS_LEVEL:
		level["boss_hp_multiplier"] = TEAM_EARLY_BOSS_HP
	return level

# Losowy boss sposrod tych, ktorych gracze spotkaliby do tej trudnosci.
static func random_team_boss(difficulty_idx: int) -> int:
	var bosses := []
	for i in range(difficulty_idx + 1):
		var boss: int = LEVELS[i].get("boss", -1)
		if boss >= 0 and not bosses.has(boss):
			bosses.append(boss)
	return bosses.pick_random() if not bosses.is_empty() else 0

# Srednia poziomow obu graczy (np. poziomy 2 i 6 daja poziom 4).
static func team_difficulty(level_a: int, level_b: int) -> int:
	return roundi((level_a + level_b) / 2.0)
