class_name PlantData
extends RefCounted

# role: "shooter"   strzela w szkodnika w tym samym rzedzie (pole "pierce": true = pocisk przebija caly rzad)
#       "generator" co jakis czas tworzy kropelke wody do zebrania
#       "wall"      tylko blokuje, nie atakuje
#       "melee"     kontratakuje szkodnika w chwili gdy ten ja gryzie (pole "counter_dmg")
#       "freeze"    jednorazowa: gdy szkodnik do niej dotrze, spowalnia caly jej rzad i znika
#       "bomb"      jednorazowa: po czasie "fuse_time" wybucha, raniac wszystko w pobliskich polach
#       "gust"      jednorazowa: gdy szkodnik do niej dotrze, rani i odrzuca caly jej rzad, po czym znika
const TYPES := [
	{
		"name": "Kukurydza", "cost": 50, "hp": 100, "role": "shooter",
		"dmg": 20, "interval": 1.2,
		"texture": "res://assets/sprites/plants/corn.svg",
	},
	{
		"name": "Kaktus", "cost": 25, "hp": 80, "role": "generator",
		"water_interval": 7.0, "water_value": 20,
		"texture": "res://assets/sprites/plants/cactus.svg",
	},
	{
		"name": "Lisc Bananowca", "cost": 75, "hp": 400, "role": "wall",
		"texture": "res://assets/sprites/plants/banana_leaf.svg",
	},
	{
		"name": "Pokrzywa", "cost": 60, "hp": 90, "role": "shooter",
		"dmg": 12, "interval": 1.4, "pierce": true,
		"texture": "res://assets/sprites/plants/nettle.svg",
	},
	{
		"name": "Bitny Brokul", "cost": 70, "hp": 220, "role": "melee",
		"counter_dmg": 30,
		"texture": "res://assets/sprites/plants/broccoli.svg",
	},
	{
		"name": "Mrozoroslinka", "cost": 40, "hp": 40, "role": "freeze",
		"slow_factor": 0.15, "slow_duration": 5.0,
		"texture": "res://assets/sprites/plants/frost.svg",
	},
	{
		"name": "Bumorzech", "cost": 90, "hp": 40, "role": "bomb",
		"fuse_time": 1.5, "blast_dmg": 300, "blast_radius_cells": 1,
		"texture": "res://assets/sprites/plants/bomb_nut.svg",
	},
	{
		"name": "Wichurowy", "cost": 65, "hp": 40, "role": "gust",
		"gust_dmg": 220, "knockback": 130.0,
		"texture": "res://assets/sprites/plants/gust_leaf.svg",
	},
]
