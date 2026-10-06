class_name PlantData
extends RefCounted

# role: "shooter"   strzela w szkodnika w tym samym rzedzie (pole "pierce": true = pocisk przebija caly rzad)
#       "volley"    krotki zasieg: gdy szkodnik jest najwyzej "range_cells" pol przed nia,
#                   wystrzeliwuje naraz "volley_count" pociskow (od gory do dolu pola)
#       "aimed"     strzela w szkodnika w DOWOLNYM rzedzie (najblizszego domu),
#                   pocisk leci za celem
#       "generator" co jakis czas tworzy kropelke wody do zebrania
#       "wall"      tylko blokuje, nie atakuje
#       "melee"     kontratakuje szkodnika w chwili gdy ten ja gryzie (pole "counter_dmg")
#       "freeze"    jednorazowa: gdy szkodnik na nia stanie, znika, a ten szkodnik
#                   zostaje calkowicie unieruchomiony na "slow_duration" (tylko on, nie caly rzad)
#       "burn"      jednorazowa: gdy szkodnik na nia stanie, znika, a ten szkodnik plonie
#                   przez "burn_duration" s, tracac w sumie "burn_dmg" HP (moze isc dalej)
#       "bomb"      jednorazowa: po czasie "fuse_time" wybucha, raniac wszystko w pobliskich polach
#       "gust"      jednorazowa: gdy JAKIKOLWIEK szkodnik pojawi sie w jej rzedzie
#                   (nie trzeba czekac, az ja dotknie), rani ("gust_dmg") i odrzuca
#                   ("knockback", w pikselach) caly rzad, po czym znika
#       "vines"     sadzi sie TYLKO na kupce smieci - od razu ja niszczy i znika
#
# recharge: czas odnowienia w sekundach (jak w Plants vs Zombies) - po
# posadzeniu rosliny jej kafelek w pasku jest zacieniony i nie da sie jej
# wybrac, dopoki licznik nie dobiegnie konca. Na starcie poziomu wszystkie
# rosliny sa gotowe. Tanie rosliny jednorazowe odnawiaja sie najdluzej.
#
# unlock_level: numer poziomu (od 1), na ktorym roslina jest juz dostepna do
# wyboru w taliii. Po ukonczeniu poziomu (unlock_level - 1) gracz musi jeszcze
# "wejsc" w kolko rosliny na sciezce (GameState.claim_plant) - dopiero wtedy
# roslina odblokowuje sie na stale, a nastepny poziom sie otwiera.
# Nowa roslina co 2-3 poziomy.
#
# Kolejnosc w tablicy = indeksy zapisane w talii gracza (savegame), wiec nowe
# rosliny dopisujemy zawsze na koncu.
#
# description: krotki opis dla dziecka - pokazywany przy odblokowaniu rosliny
# na sciezce, w "Opisie gry" i w "Moich roslinkach".
const TYPES := [
	{
		"name": "Kukurydza", "recharge": 5.0, "cost": 50, "hp": 100, "role": "shooter",
		"dmg": 20, "interval": 1.2, "unlock_level": 1,
		"texture": "res://assets/sprites/plants/corn.png",
		"description": "Strzela ziarnami w smieci w swoim rzedzie.",
	},
	{
		"name": "Kaktus", "recharge": 5.0, "cost": 25, "hp": 80, "role": "generator",
		"water_interval": 9.0, "water_value": 20, "unlock_level": 1,
		"texture": "res://assets/sprites/plants/cactus.png",
		"description": "Co jakis czas daje krople wody - za nie sadzisz kolejne rosliny.",
	},
	{
		"name": "Lisc Bananowca", "recharge": 12.0, "cost": 50, "hp": 400, "role": "wall",
		"unlock_level": 3,
		"texture": "res://assets/sprites/plants/banana_leaf.png",
		"description": "Wielki, mocny lisc. Nie strzela, ale dlugo zatrzymuje smieci.",
	},
	{
		"name": "Pokrzywa", "recharge": 5.0, "cost": 60, "hp": 90, "role": "shooter",
		"dmg": 26, "interval": 1.2, "pierce": true, "unlock_level": 22,
		"texture": "res://assets/sprites/plants/nettle.png",
		"description": "Parzace pociski leca przez caly rzad i rania kazdego smiecia po drodze.",
	},
	{
		"name": "Bitny Brokul", "recharge": 8.0, "cost": 60, "hp": 220, "role": "melee",
		"counter_dmg": 30, "unlock_level": 15,
		"texture": "res://assets/sprites/plants/broccoli.png",
		"description": "Kiedy smiec zaczyna go gryzc, Brokul oddaje mu piesciami.",
	},
	{
		"name": "Mrozoroslinka", "recharge": 20.0, "cost": 10, "hp": 40, "role": "freeze",
		"slow_factor": 0.0, "slow_duration": 5.0, "unlock_level": 5,
		"texture": "res://assets/sprites/plants/frost.png",
		"description": "Jednorazowa. Smiec, ktory na nia wejdzie, zamarza na 5 sekund.",
	},
	{
		"name": "Bumorzech", "recharge": 15.0, "cost": 90, "hp": 40, "role": "bomb",
		"fuse_time": 1.5, "blast_dmg": 300, "blast_radius_cells": 1, "unlock_level": 13,
		"texture": "res://assets/sprites/plants/bomb_nut.png",
		"description": "Po chwili wybucha i mocno rani wszystkie smieci dookola.",
	},
	{
		"name": "Wichurowy", "recharge": 12.0, "cost": 60, "hp": 40, "role": "gust",
		"gust_dmg": 220, "knockback": 130.0, "unlock_level": 9,
		"texture": "res://assets/sprites/plants/gust_leaf.png",
		"description": "Jednorazowy. Gdy w rzedzie pojawi sie smiec, wichura rani i odpycha caly rzad.",
	},
	{
		"name": "Ognioroslinka", "recharge": 20.0, "cost": 15, "hp": 40, "role": "burn",
		"burn_dmg": 200, "burn_duration": 3.0, "unlock_level": 11,
		"texture": "res://assets/sprites/plants/fire.png",
		"description": "Jednorazowa. Smiec, ktory na nia wejdzie, plonie przez 3 sekundy.",
	},
	{
		"name": "Aronia", "recharge": 5.0, "cost": 60, "hp": 100, "role": "volley",
		"dmg": 25, "interval": 1.6, "range_cells": 2, "volley_count": 4, "unlock_level": 20,
		"texture": "res://assets/sprites/plants/aronia.png",
		"description": "Strzela tylko blisko (2 pola), ale 4 pociskami naraz.",
	},
	{
		# knockback = 4 pola (CELL = 88 px w main.gd), bez obrazen.
		"name": "Lisc Klonu", "recharge": 16.0, "cost": 20, "hp": 40, "role": "gust",
		"gust_dmg": 0, "knockback": 352.0, "unlock_level": 18,
		"texture": "res://assets/sprites/plants/maple_leaf.png",
		"description": "Jednorazowy. Odpycha wszystkie smieci w rzedzie o 4 pola do tylu.",
	},
	{
		"name": "Roza", "recharge": 10.0, "cost": 80, "hp": 100, "role": "aimed",
		"dmg": 20, "interval": 1.3, "unlock_level": 25,
		"texture": "res://assets/sprites/plants/rose.png",
		"description": "Strzela w smiecia najblizej domu w dowolnym rzedzie - pocisk leci za nim.",
	},
	{
		"name": "Pnacza", "recharge": 24.0, "cost": 0, "hp": 1, "role": "vines",
		"unlock_level": 7,
		"texture": "res://assets/sprites/plants/vines.png",
		"description": "Sadzi sie je tylko na kupce smieci - od razu ja niszcza.",
	},
]
