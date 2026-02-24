extends Node2D

# Wir laden die Kachel-Vorlage
var tile_scene = preload("res://scenes/tile.tscn")

var grid_size = 4
var cell_size = 160 # Pixel pro Kachel
var padding = 15    # Abstand zwischen Kacheln

func _ready():
	setup_grid()

func setup_grid():
	for x in range(grid_size):
		for y in range(grid_size):
			var new_tile = tile_scene.instantiate()
			
			# Position berechnen:
			# Wir versetzen die Kacheln, damit sie nicht alle auf (0,0) liegen
			var pos_x = x * (cell_size + padding) + 40
			var pos_y = y * (cell_size + padding) + 300
			
			new_tile.position = Vector2(pos_x, pos_y)
			add_child(new_tile)
