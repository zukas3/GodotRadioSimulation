extends Node

const SPACING_MULTIPLIER = 20

const OFFSET_X = -25.2631
const OFFSET_Y = -54.7298

# These are used to stretch the walls accordingly
const STRETCH_MULTIPLIER_X = 0.898
const STRETCH_MULTIPLIER_Y = 1.546

# Location in latitude, longitude
export var test_locations = PoolVector2Array()
export var test_accurate_locations = []

# spreadsheet holding all the info about test run data
var spreadsheet
var path_nodes = []

# UI
onready var slider = $"../UICanvas/UI/VBox/HBoxContainer/IterationSlider"
onready var label = $"../UICanvas/UI/VBox/HBoxContainer/IterationLabel"
onready var infoLabel = $"../UICanvas/UI/VBox/HBoxContainer2/InfoLabel"
onready var infoLabelSecond = $"../UICanvas/UI/VBox/HBoxContainer2/InfoLabel2"
onready var pathPrefab = $"./PathPrefab"


onready var receiver = get_tree().get_nodes_in_group("receivers")[0]
onready var beacons = get_tree().get_nodes_in_group("beacons")


class SimulationResults:
	var totalDb
	var minDb
	var maxDb
	var out_of_range_count
	
	func _init():
		pass

# Called when the node enters the scene tree for the first time.
func _ready():
	
	spreadsheet = read_csv()
	create_path()
	begin_test_run()
	hook_to_ui()


func create_path():
	path_nodes = []
	var prefab = preload("res://PathPrefab.tscn")
	var iterations = int(spreadsheet.size() / 2)
	for i in range(0, iterations):
		var index = i * 2
		var entry = spreadsheet[index]
		
		var long_and_lat = [float(entry[3]), float(entry[2])]
		var global_coords = projectionVectorToGlobalCoords(long_and_lat)
		
		# Check if this node is too close to any other nodes
		var too_close = false
		for node in path_nodes:
			var distance = node.global_position.distance_to(global_coords)
			if distance < 40:
				too_close = true
				break
		
		# Skip iteration if too close
		if too_close:
			continue
			
		var node_copy = prefab.instance()
		node_copy.add_to_group("path_nodes")
		add_child(node_copy)
		
		node_copy.global_position = global_coords
		path_nodes.append(node_copy)
		
		

func begin_test_run():
	var totalDb = 0
	var minDb = 0
	var maxDb = -100
	var incrementCount = 0
	
	for node in path_nodes:
		for beacon in beacons:
			receiver.global_position = node.global_position
			var pl = receiver.get_log_distance_to_position(beacon.global_position) 
			totalDb += pl
			incrementCount = incrementCount + 1
			if minDb > pl:
				minDb = pl
			if maxDb < pl:
				maxDb = pl
				
	totalDb = totalDb / incrementCount;
	
	print("minDb - {0} dB, maxDb - {1} dB, totalDb - {2} dB".format([minDb, maxDb, totalDb]))
	var results = SimulationResults.new()
	results.totalDb = totalDb
	results.minDb = minDb
	results.maxDb = maxDb
	return results
	

# Positions can be regarded as beacons
func simulate_from_positions(positions) -> SimulationResults:
	# Below -90 we wont tolerate signal loss
	var tolerance = -90
	
	var totalDb = 0
	var minDb = 0
	var maxDb = -100
	var incrementCount = 0
	var out_of_range_count = 0
	
	for node in path_nodes:
		# reachable beacons from this node point
		var reachable_beacon_count = 0
		for beacon_pos in positions:
			receiver.global_position = node.global_position
			var pl = receiver.get_log_distance_to_position(beacon_pos) 
			totalDb += pl
			incrementCount = incrementCount + 1
			if minDb > pl:
				minDb = pl
			if maxDb < pl:
				maxDb = pl
			if pl > tolerance:
				reachable_beacon_count += 1
		if reachable_beacon_count < 3:
			out_of_range_count += 1
	
	
	totalDb = totalDb / incrementCount;
	
	# print("minDb - {0} dB, maxDb - {1} dB, totalDb - {2} dB".format([minDb, maxDb, totalDb]))
	var results = SimulationResults.new()
	results.totalDb = totalDb
	results.minDb = minDb
	results.maxDb = maxDb
	results.out_of_range_count = out_of_range_count
	return results
	
			
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
