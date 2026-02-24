extends Node2D

var tile_scene = preload("res://scenes/tile.tscn")

# Einstellungen
var grid_size = 5     # Das Feld passt sich jetzt automatisch an
var padding = 10      # Abstand zwischen den Kacheln
var margin = 40       # Abstand zum Bildschirmrand links/rechts

# Variablen für die dynamische Berechnung
var cell_size: float
var screen_width: float
var grid = []
var merged_tiles = []

func _ready():
	# 1. Bildschirmbreite aus den Einstellungen holen
	screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	
	# 2. Dynamische Kachelgröße berechnen
	# Platz = Gesamtbreite - (Ränder links/rechts) - (Lücken zwischen Kacheln)
	var total_paddings = padding * (grid_size - 1)
	var available_space = screen_width - (margin * 2) - total_paddings
	cell_size = available_space / grid_size
	
	# 3. Gitter-Array initialisieren
	for x in range(grid_size):
		grid.append([])
		for y in range(grid_size):
			grid[x].append(null)
	
	spawn_tile()
	spawn_tile()

# Hilfsfunktion, um die exakte Pixel-Position einer Gitter-Koordinate zu berechnen
func get_tile_pos(x: int, y: int) -> Vector2:
	var pos_x = x * (cell_size + padding) + margin
	var pos_y = y * (cell_size + padding) + 300 # Start-Höhe von oben (Y-Offset)
	return Vector2(pos_x, pos_y)

func spawn_tile():
	var empty_cells = []
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[x][y] == null:
				empty_cells.append(Vector2(x, y))
	
	if empty_cells.size() > 0:
		var random_pos = empty_cells[randi() % empty_cells.size()]
		var x = int(random_pos.x)
		var y = int(random_pos.y)
		
		var new_tile = tile_scene.instantiate()
		new_tile.value = 2.0 
		
		# Skalierung der Kachel anpassen (Originalgröße in tscn ist 160)
		var scale_factor = cell_size / 160.0
		new_tile.scale = Vector2(scale_factor, scale_factor)
		
		new_tile.position = get_tile_pos(x, y)
		add_child(new_tile)
		grid[x][y] = new_tile

func _input(event):
	if event.is_action_pressed("ui_left"):
		move_all_tiles(Vector2.LEFT)
	elif event.is_action_pressed("ui_right"):
		move_all_tiles(Vector2.RIGHT)
	elif event.is_action_pressed("ui_up"):
		move_all_tiles(Vector2.UP)
	elif event.is_action_pressed("ui_down"):
		move_all_tiles(Vector2.DOWN)

func move_all_tiles(direction: Vector2):
	var moved = false
	merged_tiles.clear()
	
	var x_range = range(grid_size)
	if direction.x > 0: x_range = range(grid_size - 1, -1, -1)
	var y_range = range(grid_size)
	if direction.y > 0: y_range = range(grid_size - 1, -1, -1)

	for x in x_range:
		for y in y_range:
			var tile = grid[x][y]
			if tile:
				if shift_tile(tile, x, y, direction):
					moved = true
	
	if moved:
		spawn_tile()

func shift_tile(tile, x, y, direction):
	var curr_x = x
	var curr_y = y
	var next_x = x + int(direction.x)
	var next_y = y + int(direction.y)
	var has_moved = false
	
	while next_x >= 0 and next_x < grid_size and next_y >= 0 and next_y < grid_size and grid[next_x][next_y] == null:
		grid[next_x][next_y] = tile
		grid[curr_x][curr_y] = null
		curr_x = next_x
		curr_y = next_y
		next_x = curr_x + int(direction.x)
		next_y = curr_y + int(direction.y)
		has_moved = true

	if next_x >= 0 and next_x < grid_size and next_y >= 0 and next_y < grid_size:
		var target_tile = grid[next_x][next_y]
		if target_tile and target_tile.value == tile.value and not target_tile in merged_tiles:
			target_tile.value *= 2
			target_tile.update_display()
			merged_tiles.append(target_tile)
			grid[curr_x][curr_y] = null
			tile.queue_free()
			return true

	if has_moved:
		tile.position = get_tile_pos(curr_x, curr_y)
		return true
		
	return false
