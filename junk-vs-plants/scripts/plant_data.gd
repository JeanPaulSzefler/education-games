class_name PlantData
extends RefCounted

# role: "shooter"   strzela w szkodnika w tym samym rzedzie (pole "pierce": true = pocisk przebija caly rzad)
#       "generator" co jakis czas tworzy kropelke wody do zebrania
#       "wall"      tylko blokuje, nie atakuje
#       "melee"     kontratakuje szkodnika w chwili gdy ten ja gryzie (pole "counter_dmg")
#       "freeze"    jednorazowa: gdy szkodnik na nia stanie, znika, a ten szkodnik
#                   zostaje calkowicie unieruchomiony na "slow_duration" (tylko on, nie caly rzad)
#       "bomb"      jednorazowa: po czasie "fuse_time" wybucha, raniac wszystko w pobliskich polach
#       "gust"      jednorazowa: gdy JAKIKOLWIEK szkodnik pojawi sie w jej rzedzie
#                   (nie trzeba czekac, az ja dotknie), rani i odrzuca caly rzad, po czym znika
#
# unlock_level: numer poziomu (od 1), na ktorym roslina jest juz dostepna do
# wyboru w taliii - odblokowuje sie na stale po ukonczeniu poziomu (unlock_level - 1).
const TYPES := [
	{
		"name": "Kukurydza", "cost": 50, "hp": 100, "role": "shooter",
		"dmg": 20, "interval": 1.2, "unlock_level": 1,
		"texture": "res://assets/sprites/plants/corn.png",
	},
	{
		"name": "Kaktus", "cost": 25, "hp": 80, "role": "generator",
		"water_interval": 9.0, "water_value": 20, "unlock_level": 1,
		"texture": "res://assets/sprites/plants/cactus.png",
	},
	{
		"name": "Lisc Bananowca", "cost": 50, "hp": 400, "role": "wall",
		"unlock_level": 3,
		"texture": "res://assets/sprites/plants/banana_leaf.png",
	},
	{
		"name": "Pokrzywa", "cost": 60, "hp": 90, "role": "shooter",
		"dmg": 12, "interval": 1.4, "pierce": true, "unlock_level": 16,
		"texture": "res://assets/sprites/plants/nettle.png",
	},
	{
		"name": "Bitny Brokul", "cost": 60, "hp": 220, "role": "melee",
		"counter_dmg": 30, "unlock_level": 12,
		"texture": "res://assets/sprites/plants/broccoli.png",
	},
	{
		"name": "Mrozoroslinka", "cost": 40, "hp": 40, "role": "freeze",
		"slow_factor": 0.0, "slow_duration": 5.0, "unlock_level": 5,
		"texture": "res://assets/sprites/plants/frost.png",
	},
	{
		"name": "Bumorzech", "cost": 90, "hp": 40, "role": "bomb",
		"fuse_time": 1.5, "blast_dmg": 300, "blast_radius_cells": 1, "unlock_level": 9,
		"texture": "res://assets/sprites/plants/bomb_nut.png",
	},
	{
		"name": "Wichurowy", "cost": 60, "hp": 40, "role": "gust",
		"gust_dmg": 220, "knockback": 130.0, "unlock_level": 7,
		"texture": "res://assets/sprites/plants/gust_leaf.png",
	},
]
