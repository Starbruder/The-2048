extends Node2D

var tile_scene = preload("res://scenes/tile.tscn")

# --- Einstellungen ---
var new_tile_value = 2.0
var grid_size = 4
var padding = 10
var margin = 40
var use_animations = true
var corner_radius = 10 # 0 = eckig

# --- Variablen ---
var cell_size: float
var screen_width: float
var grid = []
var merged_tiles = []
var is_moving = false
var touch_start_pos = Vector2.ZERO
var min_swipe_distance = 50

func _ready():
	screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var total_paddings = padding * (grid_size - 1)
	var available_space = screen_width - (margin * 2) - total_paddings
	cell_size = available_space / grid_size
	
	for x in range(grid_size):
		grid.append([])
		for y in range(grid_size):
			grid[x].append(null)
			
	setup_background_grid()
	spawn_tile()
	spawn_tile()

func get_tile_pos(x: int, y: int) -> Vector2:
	return Vector2(x * (cell_size + padding) + margin, y * (cell_size + padding) + 300)
	
func setup_background_grid():
	# 1. Das große Haupt-Spielfeld
	var board_bg = Panel.new() # Panel statt ColorRect
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color("908474")
	style_bg.set_corner_radius_all(corner_radius)
	board_bg.add_theme_stylebox_override("panel", style_bg)
	
	var board_size = grid_size * (cell_size + padding) + padding
	board_bg.size = Vector2(board_size, board_size)
	board_bg.position = Vector2(margin - padding, 300 - padding)
	board_bg.z_index = -2
	add_child(board_bg)
	
	# 2. Die leeren Felder (Slots)
	for x in range(grid_size):
		for y in range(grid_size):
			var empty_slot = Panel.new() # Panel statt ColorRect
			
			var style_slot = StyleBoxFlat.new()
			style_slot.bg_color = Color("ded5d0")
			#style_slot.set_corner_radius_all(corner_radius)
			empty_slot.add_theme_stylebox_override("panel", style_slot)
			
			empty_slot.size = Vector2(cell_size, cell_size)
			empty_slot.position = get_tile_pos(x, y)
			empty_slot.z_index = -1
			add_child(empty_slot)

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
		new_tile.value = new_tile_value
		var target_scale = Vector2(cell_size / 160.0, cell_size / 160.0)
		new_tile.position = get_tile_pos(x, y)
		add_child(new_tile)
		grid[x][y] = new_tile
		
		if use_animations:
			new_tile.scale = Vector2.ZERO
			var tween = create_tween()
			tween.tween_property(new_tile, "scale", target_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			new_tile.scale = target_scale

func _input(event):
	if is_moving: return
	
	# 1. Tastensteuerung (PC) bleibt erhalten
	var direction = Vector2.ZERO
	if event.is_action_pressed("ui_left"): direction = Vector2.LEFT
	elif event.is_action_pressed("ui_right"): direction = Vector2.RIGHT
	elif event.is_action_pressed("ui_up"): direction = Vector2.UP
	elif event.is_action_pressed("ui_down"): direction = Vector2.DOWN
	
	if direction != Vector2.ZERO:
		move_all_tiles(direction)
		return

	# 2. Touch & Maus-Swipe Logik (Gefixed!)
	# Wir prüfen, ob es ein Touch ist ODER explizit die LINKE Maustaste
	var is_valid_swipe = (event is InputEventScreenTouch) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	
	if is_valid_swipe:
		if event.pressed:
			# Finger/Maus wurde gerade aufgesetzt
			touch_start_pos = event.position
		else:
			# Finger/Maus wurde losgelassen -> Differenz berechnen
			# Sicherheits-Check: Nur rechnen, wenn auch wirklich eine Startposition gesetzt wurde
			if touch_start_pos != Vector2.ZERO:
				var swipe_vector = event.position - touch_start_pos
				
				# Nur reagieren, wenn die Bewegung weit genug war
				if swipe_vector.length() > min_swipe_distance:
					analyze_swipe(swipe_vector)
				
				# Startposition wieder zurücksetzen, um Geister-Swipes zu verhindern
				touch_start_pos = Vector2.ZERO

# Hilfsfunktion, um den Winkel des Swipes in eine Richtung zu übersetzen
func analyze_swipe(swipe: Vector2):
	var swipe_direction = Vector2.ZERO
	
	# Wir prüfen, ob die Bewegung eher horizontal oder vertikal war
	if abs(swipe.x) > abs(swipe.y):
		# Horizontal
		if swipe.x > 0:
			swipe_direction = Vector2.RIGHT
		else:
			swipe_direction = Vector2.LEFT
	else:
		# Vertikal
		if swipe.y > 0:
			swipe_direction = Vector2.DOWN
		else:
			swipe_direction = Vector2.UP
			
	if swipe_direction != Vector2.ZERO:
		move_all_tiles(swipe_direction)

func move_all_tiles(direction: Vector2):
	var moved = false
	merged_tiles.clear()
	
	var x_range = range(grid_size)
	if direction.x > 0: x_range = range(grid_size - 1, -1, -1)
	var y_range = range(grid_size)
	if direction.y > 0: y_range = range(grid_size - 1, -1, -1)

	var active_tweens = []

	for x in x_range:
		for y in y_range:
			var tile = grid[x][y]
			if tile:
				var result = shift_tile(tile, x, y, direction)
				if result:
					moved = true
					if result is Tween:
						active_tweens.append(result)
	
	if moved:
		if use_animations and active_tweens.size() > 0:
			is_moving = true
			active_tweens.back().finished.connect(_on_move_finished)
		else:
			# Sofort spawnen im Turbo-Modus
			spawn_tile()
	else:
		is_moving = false

func _on_move_finished():
	spawn_tile()
	is_moving = false

func shift_tile(tile, x, y, direction):
	var curr_x = x
	var curr_y = y
	var next_x = x + int(direction.x)
	var next_y = y + int(direction.y)
	var has_shifted = false
	
	# 1. Rutschen
	while next_x >= 0 and next_x < grid_size and next_y >= 0 and next_y < grid_size and grid[next_x][next_y] == null:
		grid[next_x][next_y] = tile
		grid[curr_x][curr_y] = null
		curr_x = next_x
		curr_y = next_y
		next_x = curr_x + int(direction.x)
		next_y = curr_y + int(direction.y)
		has_shifted = true

	var movement_tween = null
	if has_shifted and use_animations:
		movement_tween = create_tween()
		movement_tween.tween_property(tile, "position", get_tile_pos(curr_x, curr_y), 0.1)
	elif has_shifted:
		tile.position = get_tile_pos(curr_x, curr_y)

	# 2. Verschmelzen
	if next_x >= 0 and next_x < grid_size and next_y >= 0 and next_y < grid_size:
		var target_tile = grid[next_x][next_y]
		if target_tile and target_tile.value == tile.value and not target_tile in merged_tiles:
			target_tile.value *= 2
			merged_tiles.append(target_tile)
			grid[curr_x][curr_y] = null
			
			if use_animations:
				var merge_tween = create_tween()
				merge_tween.tween_property(tile, "position", get_tile_pos(next_x, next_y), 0.1)
				merge_tween.tween_callback(tile.queue_free)
				merge_tween.tween_callback(target_tile.update_display)
				
				# Bounce Effekt
				var bounce = create_tween()
				bounce.tween_interval(0.1)
				var s = Vector2(cell_size/160.0, cell_size/160.0)
				bounce.tween_property(target_tile, "scale", s * 1.2, 0.05)
				bounce.tween_property(target_tile, "scale", s, 0.05)
				return merge_tween
			else:
				tile.queue_free()
				target_tile.update_display()
				return true # Signaliert Erfolg ohne Tween
				
	return movement_tween if use_animations else has_shifted
