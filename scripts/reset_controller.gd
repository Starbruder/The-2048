extends Node

# --- Einstellungen ---
const TAP_THRESHOLD = 0.4  # Zeitfenster für Mehrfachklicks (in Sekunden)
const MAX_TAP_DISTANCE = 50.0 # Maximale Bewegung, die noch als "Tap" zählt (wie in main.gd)

var tap_count = 0
var last_tap_time = 0.0
var tap_start_pos = Vector2.ZERO # Merkt sich, wo der Klick startete

func _ready():
	# WICHTIG: Verhindert, dass die App beim Zurück-Button schließt
	get_tree().set_quit_on_go_back(false)
	
# Diese Funktion fängt System-Events ab (wie den Android Back-Button)
func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		trigger_reset("Android Zurück-Taste (System)")

func _input(event):
	# 1. PC: ESC-Taste oder Mittlere Maustaste
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		trigger_reset("PC (Taste ESC)")
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		trigger_reset("PC (Mittlere Maustaste)")

	# 2. HANDY & PC: Triple-Tap (Nur wenn fast stillstehend)
	var is_tap_action = (event is InputEventScreenTouch) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	
	if is_tap_action:
		if event.pressed:
			# Start-Position merken
			tap_start_pos = event.position
		else:
			# Beim Loslassen prüfen: Wie weit war der Weg?
			var travel_distance = event.position.distance_to(tap_start_pos)
			
			if travel_distance <= MAX_TAP_DISTANCE:
				# Es war ein "ruhiger" Tap -> Zeit-Logik prüfen
				var current_time = Time.get_unix_time_from_system()
				
				if current_time - last_tap_time > TAP_THRESHOLD:
					tap_count = 1
				else:
					tap_count += 1
				
				last_tap_time = current_time
				
				if tap_count >= 3:
					tap_count = 0
					trigger_reset("Triple-Tap (Stillstehend)")
			else:
				# Es war eine Wischbewegung (Swipe) -> Zähler für Reset abbrechen
				tap_count = 0

func trigger_reset(reason: String):
	print("Reset ausgelöst durch: ", reason)
	if is_inside_tree():
		var tree = get_tree()
		if tree != null:
			tree.reload_current_scene()
	else:
		var main_tree = Engine.get_main_loop() as SceneTree
		if main_tree:
			main_tree.reload_current_scene()
