class_name BossData
extends RefCounted

# special: rodzaj ataku specjalnego bossa, obslugiwany w main.gd -> _trigger_boss_special().
# Kazdy boss telegrafuje atak (miga na czerwono) 1s przed jego wykonaniem
# (main.gd -> BOSS_TELEGRAPH_TIME), zeby gracz mial szanse zareagowac.
#   "power_bite"   - co jakis czas gryzie kilka razy mocniej niz zwykle
#   "phase_jump"   - przeskakuje ponad blokujaca go roslina o jedno pole
#   "row_crush"    - rani WSZYSTKIE rosliny w swoim rzedzie naraz, nie tylko blokera
#   "magnet_pulse" - na kilka sekund wylacza wszystkie rosliny strzelajace w swoim rzedzie
#   "toxic_cloud"  - zatruwa blokujaca go rosline (dodatkowe obrazenia z opoznieniem)
const TYPES := [
	{
		"name": "Puszkowy Tyran", "hp": 500, "speed": 14.0, "bite_dmg": 16, "bite_interval": 1.0,
		"special": "power_bite", "special_interval": 8.0, "power_bite_multiplier": 2.5,
		"texture": "res://assets/sprites/enemies/boss_can.png",
	},
	{
		"name": "Foliowy Duch", "hp": 420, "speed": 30.0, "bite_dmg": 12, "bite_interval": 0.9,
		"special": "phase_jump", "special_interval": 7.0,
		"texture": "res://assets/sprites/enemies/boss_bag.png",
	},
	{
		"name": "Kompaktor Smieci", "hp": 900, "speed": 8.0, "bite_dmg": 20, "bite_interval": 1.3,
		"special": "row_crush", "special_interval": 9.0, "row_crush_dmg": 60,
		"texture": "res://assets/sprites/enemies/boss_compactor.png",
	},
	{
		"name": "Magnetyczny Zlomiarz", "hp": 750, "speed": 16.0, "bite_dmg": 18, "bite_interval": 1.1,
		"special": "magnet_pulse", "special_interval": 8.0, "disable_duration": 4.0,
		"texture": "res://assets/sprites/enemies/boss_magnet.png",
	},
	{
		"name": "Toksyczny Kolos", "hp": 1300, "speed": 10.0, "bite_dmg": 22, "bite_interval": 1.2,
		"special": "toxic_cloud", "special_interval": 7.0, "poison_dmg": 80, "poison_delay": 1.5,
		"texture": "res://assets/sprites/enemies/boss_toxic.png",
	},
]
