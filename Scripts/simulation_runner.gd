extends Node

const SPACING_MULTIPLIER = 20

const OFFSET_X = -25.2631
const OFFSET_Y = -54.7298

# These are used to stretch the walls accordingly
const STRETCH_MULTIPLIER_X = 0.898
const STRETCH_MULTIPLIER_Y = 1.546

const TEST_LOCATIONS = [[25.26321, 54.72989],
						[25.26348, 54.72985],
						[25.26307, 54.72994],
						[25.26274, 54.72997], # 893
						[25.26299, 54.72987], # 430
						[25.26306, 54.72997], # 877
						[25.26318, 54.72991], # 1375
						[25.26271, 54.72988], # 14
						[25.26348, 54.72982]] # 185
# Location in latitude, longitude
export var test_locations = PoolVector2Array()
export var test_accurate_locations = []


# Called when the node enters the scene tree for the first time.
func _ready():
	var receivers = get_tree().get_nodes_in_group("receivers")
	var receiver = receivers[0]
	
	for position in TEST_LOCATIONS:
		var global_coords = projectionVectorToGlobalCoords(position)
		receiver.global_position = global_coords

		print(global_coords)
	receiver.calculate()
	
	pass # Replace with function body.


func projectionVectorToGlobalCoords(projection):
	return Vector2(
		degreesToMeters(projection[0] + OFFSET_X) * SPACING_MULTIPLIER * STRETCH_MULTIPLIER_X,
		-degreesToMeters(projection[1] + OFFSET_Y) * SPACING_MULTIPLIER * STRETCH_MULTIPLIER_Y)

func degreesToMeters(value):
	# DEGREES * KM * M
	return value * 111139.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
