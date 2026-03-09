extends Node2D

var tile_scene = preload("res://scenes/tile.tscn")

# --- Einstellungen ---
@export var is_hexagon_mode: bool = false
var new_tile_value = 2.0
var grid_size = 4
var padding = 10
var margin = 40
var use_animations = true
var corner_radius = 0 # 0 für eckige Tiles

# --- Variablen ---
var cell_size: float
var screen_width: float
var grid = {} 
var merged_tiles = []
var is_moving = false
var touch_start_pos = Vector2.ZERO
var min_swipe_distance = 50

func _ready():
	screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var total_paddings = padding * (grid_size - 1)
	var available_space = screen_width - (margin * 2) - total_paddings
	cell_size = available_space / grid_size
	
	initialize_grid()
	setup_background_grid()
	spawn_tile()
	spawn_tile()

func initialize_grid():
	grid.clear()
	if not is_hexagon_mode:
		for x in range(grid_size):
			for y in range(grid_size):
				grid[Vector2i(x, y)] = null
	else:
		var r_limit = 2 
		for q in range(-r_limit, r_limit + 1):
			var r1 = max(-r_limit, -q - r_limit)
			var r2 = min(r_limit, -q + r_limit)
			for r in range(r1, r2 + 1):
				grid[Vector2i(q, r)] = null

func get_tile_pos(coords: Vector2i) -> Vector2:
	if not is_hexagon_mode:
		var top_left_x = coords.x * (cell_size + padding) + margin
		var top_left_y = coords.y * (cell_size + padding) + 300
		return Vector2(top_left_x + cell_size / 2.0, top_left_y + cell_size / 2.0)
	else:
		var size = cell_size / 1.7
		var x = size * (sqrt(3) * coords.x + sqrt(3)/2.0 * coords.y)
		var y = size * (3.0/2.0 * coords.y)
		return (get_viewport_rect().size / 2.0) + Vector2(x, y)

func setup_background_grid():
	var board_color = Color("908474")
	if not is_hexagon_mode:
		var board_width = grid_size * (cell_size + padding) + padding
		var center = Vector2(margin - padding + board_width/2.0, 300 - padding + board_width/2.0)
		var board_bg = create_background_poly(center, board_width/2.0, board_color, 5) # Kleiner Bonus-Radius für das Board-Außenmaß
		board_bg.z_index = -2
		add_child(board_bg)
	else:
		var board_radius = cell_size * 2.2 
		var board_bg = create_background_poly(get_viewport_rect().size / 2.0, board_radius, board_color, 0)
		board_bg.z_index = -2
		add_child(board_bg)

	for coords in grid.keys():
		var slot_pos = get_tile_pos(coords)
		var empty_slot = create_background_poly(slot_pos, cell_size / 2.0, Color("ded5d0"), corner_radius)
		empty_slot.z_index = -1
		add_child(empty_slot)

func create_background_poly(pos: Vector2, s: float, color: Color, r: float) -> Polygon2D:
	var poly = Polygon2D.new()
	var points = PackedVector2Array()
	
	if not is_hexagon_mode:
		# Einfaches Rechteck, wenn r=0
		if r <= 0:
			points = [Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)]
		else:
			var corner_points = 10
			var angles = [270, 0, 90, 180]
			var centers = [Vector2(s-r, -s+r), Vector2(s-r, s-r), Vector2(-s+r, s-r), Vector2(-s+r, -s+r)]
			for i in range(4):
				for j in range(corner_points + 1):
					var angle = deg_to_rad(angles[i] + 90.0 * j / corner_points)
					points.append(centers[i] + Vector2(r * cos(angle), r * sin(angle)))
	else:
		# Hexagon
		for i in range(6):
			var angle = deg_to_rad(60 * i - 90)
			points.append(Vector2(s * cos(angle), s * sin(angle)))
				
	poly.polygon = points
	poly.color = color
	poly.position = pos
	return poly

func spawn_tile():
	var empty_cells = []
	for coords in grid.keys():
		if grid[coords] == null:
			empty_cells.append(coords)
	
	if empty_cells.size() > 0:
		var random_coords = empty_cells[randi() % empty_cells.size()]
		var new_tile = tile_scene.instantiate()
		new_tile.value = new_tile_value
		new_tile.is_hexagon = is_hexagon_mode
		new_tile.corner_radius = corner_radius
		
		var target_scale = Vector2(cell_size / 160.0, cell_size / 160.0)
		new_tile.position = get_tile_pos(random_coords)
		new_tile.scale = Vector2.ZERO # Start bei 0
		add_child(new_tile)
		grid[random_coords] = new_tile
		
		if use_animations:
			# TRANS_QUAD verhindert das "Hüpfen" (kein Overshoot wie bei TRANS_BACK)
			create_tween().tween_property(new_tile, "scale", target_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			new_tile.scale = target_scale

func move_all_tiles(direction: Vector2i):
	if is_moving: return
	var moved = false
	merged_tiles.clear()
	
	var sorted_coords = grid.keys()
	sorted_coords.sort_custom(func(a, b):
		# Wir sortieren nach der Projektion auf die Bewegungsrichtung
		var dir_v = Vector2(direction)
		return Vector2(a).dot(dir_v) > Vector2(b).dot(dir_v)
	)

	var active_tweens = []

	for coords in sorted_coords:
		var tile = grid[coords]
		if tile:
			var result = shift_tile(tile, coords, direction)
			if result:
				moved = true
				if result is Tween: active_tweens.append(result)
	
	if moved:
		is_moving = true
		if use_animations and active_tweens.size() > 0:
			# Wir warten auf den letzten Tween
			active_tweens.back().finished.connect(func(): 
				is_moving = false
				spawn_tile()
			)
		else:
			is_moving = false
			spawn_tile()

func shift_tile(tile, current_coords: Vector2i, direction: Vector2i):
	var curr = current_coords
	var next = curr + direction
	var has_shifted = false
	
	while grid.has(next) and grid[next] == null:
		grid[next] = tile
		grid[curr] = null
		curr = next
		next = curr + direction
		has_shifted = true

	var move_tween = null
	if has_shifted:
		if use_animations:
			move_tween = create_tween()
			move_tween.tween_property(tile, "position", get_tile_pos(curr), 0.1).set_trans(Tween.TRANS_SINE)
		else:
			tile.position = get_tile_pos(curr)

	if grid.has(next):
		var target_tile = grid[next]
		if target_tile and target_tile.value == tile.value and not target_tile in merged_tiles:
			target_tile.value *= 2
			merged_tiles.append(target_tile)
			grid[curr] = null
			
			if use_animations:
				var m_tween = create_tween()
				m_tween.tween_property(tile, "position", get_tile_pos(next), 0.1).set_trans(Tween.TRANS_SINE)
				m_tween.tween_callback(tile.queue_free)
				m_tween.parallel().tween_callback(target_tile.update_display)
				
				# Der Bounce-Effekt passiert nur HIER beim Verschmelzen
				var bounce = create_tween()
				bounce.tween_interval(0.05)
				var s = Vector2(cell_size / 160.0, cell_size / 160.0)
				bounce.tween_property(target_tile, "scale", s * 1.15, 0.05)
				bounce.tween_property(target_tile, "scale", s, 0.05)
				return m_tween
			else:
				tile.queue_free()
				target_tile.update_display()
				return true
				
	return move_tween

# --- Input-Handling (Swipe & Keys) ---

func _input(event):
	if is_moving: return
	
	var dir = Vector2i.ZERO
	if event.is_action_pressed("ui_left"): dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"): dir = Vector2i(1, 0)
	elif event.is_action_pressed("ui_up"): dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"): dir = Vector2i(0, 1)

	if dir != Vector2i.ZERO:
		move_all_tiles(dir)
		return

	if (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)):
		if event.pressed: touch_start_pos = event.position
		elif touch_start_pos != Vector2.ZERO:
			var swipe = event.position - touch_start_pos
			if swipe.length() > min_swipe_distance:
				analyze_swipe(swipe)
			touch_start_pos = Vector2.ZERO

func analyze_swipe(swipe: Vector2):
	var angle = rad_to_deg(swipe.angle())
	var dir = Vector2i.ZERO
	if not is_hexagon_mode:
		if abs(swipe.x) > abs(swipe.y): dir = Vector2i(1, 0) if swipe.x > 0 else Vector2i(-1, 0)
		else: dir = Vector2i(0, 1) if swipe.y > 0 else Vector2i(0, -1)
	else:
		if angle > -30 and angle <= 30: dir = Vector2i(1, 0)
		elif angle > 30 and angle <= 90: dir = Vector2i(0, 1)
		elif angle > 90 and angle <= 150: dir = Vector2i(-1, 1)
		elif angle > 150 or angle <= -150: dir = Vector2i(-1, 0)
		elif angle > -150 and angle <= -90: dir = Vector2i(0, -1)
		elif angle > -90 and angle <= -30: dir = Vector2i(1, -1)
	
	if dir != Vector2i.ZERO: 
		move_all_tiles(dir)
