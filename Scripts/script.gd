extends Node2D
@export var cell_count: int = 6
@export var cell_width: int = 64
@export var cell_height: int = 64
@export var start_position: Vector2 = Vector2(100, 200)
const PLAYER_SCENE = preload("res://Scene/player.tscn")
var horizontal_grid: Array = []
var player_instance: Node2D = null
func _ready() -> void:
	generate_grid()
	spawn_player()
	
func generate_grid() -> void:
	horizontal_grid.clear()
	for i in range(cell_count):
		var cell_pos = start_position + Vector2(i * cell_width, 0)
		var cell_data = {
			"id": "col_" + str(i),          
			"position": cell_pos,           
			"index": i,                    
			"occupied_by": null             
		}
		horizontal_grid.append(cell_data)

func _draw() -> void:
	for cell in horizontal_grid:
		var rect = Rect2(cell["position"], Vector2(cell_width, cell_height))
		draw_rect(rect, Color(0.2, 0.2, 0.3), true)
		draw_rect(rect, Color(0.8, 0.8, 0.8), false, 2.0)

func get_cell_by_id(id: String) -> Dictionary:
	for cell in horizontal_grid:
		if cell["id"] == id:
			return cell
	return {}

func get_cell_by_index(index: int) -> Dictionary:
	if index >= 0 and index < horizontal_grid.size():
		return horizontal_grid[index]
	return {}

func spawn_player() -> void:
	if horizontal_grid.is_empty():
		return
	player_instance = PLAYER_SCENE.instantiate()
	add_child(player_instance)
	player_instance.z_index = 10
	var first_cell = horizontal_grid[0]
	var center_offset = Vector2(cell_width / 2.0, cell_height / 2.0)
	player_instance.setup_position(first_cell["position"] + center_offset)
	print("Joueur spawné à la position : ", player_instance.global_position)

func _input(event: InputEvent) -> void:
	if not player_instance:
		return
	var current_index = player_instance.current_cell_index
	if event.is_action_pressed("ui_left"):
		try_move_player(current_index - 1)	
	elif event.is_action_pressed("ui_right"):
		try_move_player(current_index + 1)
	elif event.is_action_pressed("ui_accept"):
		player_instance.flip_direction()

func try_move_player(target_index: int) -> void:
	if target_index >= 0 and target_index < horizontal_grid.size():
		var target_cell = horizontal_grid[target_index]
		var center_offset = Vector2(cell_width / 2.0, cell_height / 2.0)
		
		player_instance.move_to(target_cell["position"] + center_offset, target_index)
