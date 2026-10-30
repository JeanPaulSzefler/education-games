class_name EventData
extends RefCounted

# Wydarzenia czasowe: kazde trwa DURATION_DAYS dni, potem znika razem z
# postepami gracza i zastepuje je nastepne z ROTATION. Czas liczy sie osobno
# dla kazdego konta, od pierwszego wejscia do gry, bo gra nie ma serwera.
# Nowe, zatwierdzone wydarzenia (WYDARZENIA_PROPOZYCJE.md) dopisujemy na koncu.
#
# stages[i]: "level_idx" - poziom sciezki, z ktorego plansza bierze fale i
# trudnosc; "saplings" - sadzonki za pierwsze przejscie etapu.
const DURATION_DAYS := 7
const REPLAY_SAPLINGS := 1
const ROTATION := [
	{
		"id": "plant_belt",
		"name": "Tasma roslin",
		"description": "Bez wody i bez Kaktusow. Roslinki same pojawiaja sie na pasku - tapnij i posadz. Nagroda: sadzonki do ogrodu.",
		"stages": [
			{"level_idx": 1, "saplings": 2},
			{"level_idx": 5, "saplings": 2},
			{"level_idx": 11, "saplings": 3},
			{"level_idx": 20, "saplings": 3},
			{"level_idx": 35, "saplings": 4},
		],
	},
]
