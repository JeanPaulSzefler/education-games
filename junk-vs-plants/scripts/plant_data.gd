class_name PlantData
extends RefCounted

# role: "shooter" strzela w szkodnika w tym samym rzedzie
#       "generator" co jakis czas tworzy kropelke wody do zebrania
#       "wall" tylko blokuje, nie atakuje
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
]
