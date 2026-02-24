extends Node2D

var tile_scene = preload("res://scenes/tile.tscn")

# Einstellungen
var grid_size = 5
var padding = 10
var margin = 40

# Variablen für die dynamische Berechnung
var cell_size: float
var screen_width: float
var grid = []
var merged_tiles = []

# NEU: Die "Ampel" für Eingaben
var is_moving = false

func _ready():
	screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	
	var total_paddings = padding * (grid_size - 1)
	var available_space = screen_width - (margin * 2) - total_paddings
	cell_size = available_space / grid_size
	
	for x in range(grid_size):
		grid.append([])
		for y in range(grid_size):
			grid[x].append(null)
	
	spawn_tile()
	spawn_tile()

func get_tile_pos(x: int, y: int) -> Vector2:
	var pos_x = x * (cell_size + padding) + margin
	var pos_y = y * (cell_size + padding) + 300 
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
		
		var target_scale = Vector2(cell_size / 160.0, cell_size / 160.0)
		
		# BEREINIGT: Wir fügen die Kachel nur EINMAL hinzu
		new_tile.position = get_tile_pos(x, y)
		new_tile.scale = Vector2.ZERO # Startet winzig
		add_child(new_tile)
		grid[x][y] = new_tile
		
		var tween = create_tween()
		tween.tween_property(new_tile, "scale", target_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _input(event):
	# NEU: Wenn wir uns gerade bewegen, ignorieren wir alle Eingaben!
	if is_moving:
		return
		
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

	# NEU: Liste um alle aktiven Tweens zu sammeln
	var active_tweens = []

	for x in x_range:
		for y in y_range:
			var tile = grid[x][y]
			if tile:
				# shift_tile gibt jetzt den Tween zurück, falls es eine Bewegung gab
				var tween = shift_tile(tile, x, y, direction)
				if tween:
					moved = true
					active_tweens.append(tween)
	
	if moved:
		is_moving = true # Ampel auf Rot schalten
		
		# Wir warten, bis der letzte Tween in der Liste fertig ist
		if active_tweens.size() > 0:
			var last_tween = active_tweens.back()
			# Sobald die Animation fertig ist, neue Kachel spawnen und Ampel auf Grün schalten
			last_tween.finished.connect(_on_move_finished)
	else:
		# Falls keine Kachel rutschen konnte (Wand blockiert), Ampel direkt wieder grün
		is_moving = false

# NEU: Die Funktion, die nach der Bewegung aufgerufen wird
func _on_move_finished():
	spawn_tile()
	is_moving = false

func shift_tile(tile, x, y, direction):
	var curr_x = x
	var curr_y = y
	var next_x = x + int(direction.x)
	var next_y = y + int(direction.y)
	var has_moved = false
	var final_tween = null # Wir speichern den Tween, um ihn zurückzugeben
	
	while next_x >= 0 and next_x < grid_size and next_y >= 0 and next_y < grid_size and grid[next_x][next_y] == null:
		grid[next_x][next_y] = tile
		grid[curr_x][curr_y] = null
		curr_x = next_x
		curr_y = next_y
		next_x = curr_x + int(direction.x)
		next_y = curr_y + int(direction.y)
		has_moved = true

	# Standard-Bewegung (ohne Verschmelzen)
	if has_moved:
		final_tween = create_tween()
		final_tween.tween_property(tile, "position", get_tile_pos(curr_x, curr_y), 0.1)

	if next_x >= 0 and next_x < grid_size and next_y >= 0 and next_y < grid_size:
		var target_tile = grid[next_x][next_y]
		if target_tile and target_tile.value == tile.value and not target_tile in merged_tiles:
			target_tile.value *= 2
			
			final_tween = create_tween()
			final_tween.tween_property(tile, "position", get_tile_pos(next_x, next_y), 0.1)
			
			# Nach der Bewegung: Altes löschen, Neues updaten
			final_tween.tween_callback(tile.queue_free)
			final_tween.tween_callback(target_tile.update_display)
			
			var bounce_tween = create_tween()
			# Damit der Bounce erst startet, wenn die Kachel angekommen ist, fügen wir eine Pause ein
			bounce_tween.tween_interval(0.1) 
			var original_scale = Vector2(cell_size / 160.0, cell_size / 160.0)
			bounce_tween.tween_property(target_tile, "scale", original_scale * 1.2, 0.05)
			bounce_tween.tween_property(target_tile, "scale", original_scale, 0.05)
			
			merged_tiles.append(target_tile)
			grid[curr_x][curr_y] = null
			
			return final_tween # Gib den Merge-Tween zurück
			
	return final_tween # Gib den Move-Tween zurück (oder null, falls nichts passiert ist)
