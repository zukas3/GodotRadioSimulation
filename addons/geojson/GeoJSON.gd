tool
extends EditorPlugin

# PLUGIN
var dock
const MENU_NAME = "Create on Parent GeoJSON"

# PROCESS
var selectedNode
var sceneOwner
var mapWidth = 590
var mapHeight = 260

const SPACING_MULTIPLIER = 20

const OFFSET_X = -25.2631
const OFFSET_Y = -54.7298

# These are used to stretch the walls accordingly
const STRETCH_MULTIPLIER_X = 0.898
const STRETCH_MULTIPLIER_Y = 1.546


func _enter_tree():
	dock = preload("res://addons/geojson/dock.tscn").instance()

	# Add the loaded scene to the docks.
	#add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	
	add_tool_menu_item(MENU_NAME, self, "run_plugin")
	pass


func _exit_tree():
	#remove_control_from_docks(dock)
	remove_tool_menu_item(MENU_NAME)
	# Erase the control from the memory.
	#dock.free()

func run_plugin(variant):
	selectedNode = get_editor_interface().get_selection().get_selected_nodes()[0]
	sceneOwner = selectedNode.get_tree().get_edited_scene_root()
	
	doBoundary()
	doWalls()


func doBoundary():
	var file = File.new()
	file.open("res://JSON/mif3floor_ground.geojson", file.READ)
	var json = file.get_as_text()
	file.close()
	
	var json_result = JSON.parse(json)
	var dict = json_result.result
	for feature in dict["features"]:
		var geometry = feature["geometry"]
		createWallFromCoordinates(geometry["coordinates"][0][0])

func doWalls():
	var file = File.new()
	file.open("res://JSON/mif3floor_walls.geojson", file.READ)
	var json = file.get_as_text()
	file.close()
	
	var json_result = JSON.parse(json)
	var dict = json_result.result
	for feature in dict["features"]:
		var geometry = feature["geometry"]
		createWallFromCoordinates(geometry["coordinates"][0])


func createWallFromCoordinates(coords):
	var line = Line2D.new()
	line.width = 8
	selectedNode.add_child(line)
	line.set_owner(sceneOwner)
	
	for pair in coords:
		#var mPair = mercatorToCoords(pair[1], pair[0]) 
		var mPair = [degreesToMeters(pair[0] + OFFSET_X), degreesToMeters(pair[1] + OFFSET_Y)]
		#mPair = [mPair[0], mPair[1]]
		print(mPair)
		# Don't forget to flip Y since this is not usual cartesian
		line.add_point(Vector2(mPair[0] * SPACING_MULTIPLIER * STRETCH_MULTIPLIER_X, -mPair[1] * SPACING_MULTIPLIER * STRETCH_MULTIPLIER_Y))
		
	addCollisionToLine(line)
	


func addCollisionToLine(line):
	var body = StaticBody2D.new()
	body.set_owner(sceneOwner)
	line.add_child(body)
	body.set_owner(sceneOwner)
	
	var array = line.points
	for i in range(0, array.size() - 1):
		var firstPos = array[i]
		var secondPos = array[i + 1]
		
		# Create segment shape
		var segment = SegmentShape2D.new()
		segment.set_a(firstPos)
		segment.set_b(secondPos)
		
		# Add physical collision
		var shape = CollisionShape2D.new()
		shape.set_shape(segment)
		body.add_child(shape)
		shape.set_owner(sceneOwner)
		
	
func degreesToMeters(value):
	# DEGREES * KM * M
	return value * 111139.0
	
	
func mercatorToCoords(latitude, longitude):
	var x = (longitude + 180) * (mapWidth / 360)
	var latRad = (latitude * PI) / 180;
	
	var mercN = log(tan( (PI/4) + (latRad / 2) ))
	var y = (mapHeight / 2) - (mapHeight * mercN / (2 * PI))

	return [x, y]
