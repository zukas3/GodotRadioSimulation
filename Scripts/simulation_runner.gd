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

# spreadsheet holding all the info about test run data
var spreadsheet

# UI
onready var slider = $"../UICanvas/UI/VBox/HBoxContainer/IterationSlider"
onready var label = $"../UICanvas/UI/VBox/HBoxContainer/IterationLabel"
onready var infoLabel = $"../UICanvas/UI/VBox/HBoxContainer2/InfoLabel"
onready var infoLabelSecond = $"../UICanvas/UI/VBox/HBoxContainer2/InfoLabel2"
onready var pathPrefab = $"./PathPrefab"


onready var receiver = get_tree().get_nodes_in_group("receivers")[0]
onready var beacons = get_tree().get_nodes_in_group("beacons")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	spreadsheet = read_csv()
	hook_to_ui()


func debug_scan_all():
	var receivers = get_tree().get_nodes_in_group("receivers")
	var receiver = receivers[0]
	
	for position in TEST_LOCATIONS:
		var global_coords = projectionVectorToGlobalCoords(position)
		receiver.global_position = global_coords

		print(global_coords)
	receiver.calculate()
	

func projectionVectorToGlobalCoords(projection):
	return Vector2(
		degreesToMeters(projection[0] + OFFSET_X) * SPACING_MULTIPLIER * STRETCH_MULTIPLIER_X,
		-degreesToMeters(projection[1] + OFFSET_Y) * SPACING_MULTIPLIER * STRETCH_MULTIPLIER_Y)

func degreesToMeters(value):
	# DEGREES * KM * M
	return value * 111139.0

func read_csv():
	var spreadsheet = []
	
	var file = File.new()
	file.open("res://Data/data_aggregated.gcsv", file.READ)
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		spreadsheet.append(line)
		
	file.close()
	
	return spreadsheet;

func scan_position(index):
	var entry = spreadsheet[index]
	
	var long_and_lat = [float(entry[3]), float(entry[2])]
	var global_coords = projectionVectorToGlobalCoords(long_and_lat)
	
	# receiver.calculate
	receiver.global_position = global_coords
	
	# Display all original data
	var spreadsheet_data = ""
	var simulated_data = ""
	for i in range(4, 10):
		simulated_data += receiver.calculate_to_position(beacons[i-4].get_global_position()) + '\n'
		spreadsheet_data += spreadsheet[0][i] + " - Captured: "  + "%.2f" % float(entry[i]) + '\n'
		
	infoLabel.text = spreadsheet_data #'{}\n{}\n'.format([entry[4], entry[5]], '{}')
	infoLabelSecond.text = simulated_data
	

func hook_to_ui():
	slider.min_value = 1;
	slider.max_value = spreadsheet.size() - 1;


func _on_IterationSlider_value_changed(value):
	label.text = str(value)
	scan_position(value)
