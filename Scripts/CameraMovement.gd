extends Camera2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			var newZoom = zoom + Vector2(0.25, 0.25)
			zoom = newZoom
		if event.button_index == BUTTON_WHEEL_UP and event.pressed:
			var newZoom = zoom - Vector2(0.25, 0.25)
			zoom = newZoom
			
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_W:
			move_local_y(-10)
		if event.scancode == KEY_S:
			move_local_y(10)
		if event.scancode == KEY_A:
			move_local_x(-10)
		if event.scancode == KEY_D:
			move_local_x(10)
		   

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
