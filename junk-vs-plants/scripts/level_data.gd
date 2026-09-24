class_name LevelData
extends RefCounted

# Kazdy poziom to lista fal, kazda fala to lista {type, row} (type = indeks w
# ENEMY_TYPES w main.gd). "boss" to indeks w BossData.TYPES, -1 = bez bossa,
# spawnowany po ostatniej fali; "boss_hp_multiplier" mnozy jego HP (domyslnie 1.0).
# "cactus_water_multiplier" mnozy odstep czasu miedzy kroplami z Kaktusa
# (domyslnie 1.0). "blocked_tiles" to pola, na ktorych nie mozna sadzic.
#
# Zasada ukladania fal: liczba wrogow w zwyklych falach rosnie lagodnie z
# poziomem (poz. 1: 1-3 na fale, poz. 17: 5-8 na fale). Ostatnia fala na
# kazdym poziomie jest zawsze najwieksza: bez bossa - ok. 2x tyle wrogow co
# najwieksza z wczesniejszych fal; z bossem - ok. 1,3x tyle (boss i tak
# domyka finał).
const LEVELS := [
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
		"boss": 1,
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
		"boss": -1,
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
		"boss": 2,
		"cactus_water_multiplier": 1.1,
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
		"boss": 3,
		"cactus_water_multiplier": 1.2,
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
		"boss": 4,
		"cactus_water_multiplier": 1.25,
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
		"boss": -1,
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
		"boss": 2,
		"boss_hp_multiplier": 1.4,
		"cactus_water_multiplier": 1.3,
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
		"boss": 3,
		"boss_hp_multiplier": 1.6,
		"cactus_water_multiplier": 1.35,
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
		"boss": 4,
		"boss_hp_multiplier": 1.8,
		"cactus_water_multiplier": 1.4,
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
]
