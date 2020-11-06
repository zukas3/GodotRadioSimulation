extends RayCast2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(is_colliding()):
		var lr = get_child(0)
		lr.clear_points()
		lr.add_point(to_local(get_global_position()))
		lr.add_point(to_local(get_collision_point()))
		lr.add_point(to_local(get_collision_point() + get_collision_normal() * 50))
	pass
