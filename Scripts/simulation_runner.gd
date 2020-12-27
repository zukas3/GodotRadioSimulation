extends Node

class Sorter:
	static func sort_clockwise(a, b):
		if a.y * b.y <= 0:
			return a.y < b.y or (a.y == b.y and a.x < b.x)
		else:
			return a.x * b.y - a.y * b.x < 0

const SPACING_MULTIPLIER = 20

const OFFSET_X = -25.2631
const OFFSET_Y = -54.7298

# These are used to stretch the walls accordingly
const STRETCH_MULTIPLIER_X = 0.898
const STRETCH_MULTIPLIER_Y = 1.546

export var run_spreadsheet_test = false

# spreadsheet holding all the info about test run data
var spreadsheet
var path_nodes = []

# UI
onready var slider = $"../UICanvas/UI/VBox/HBoxContainer/IterationSlider"
onready var label = $"../UICanvas/UI/VBox/HBoxContainer/IterationLabel"
onready var infoLabel = $"../UICanvas/UI/VBox/HBoxContainer2/InfoLabel"
onready var infoLabelSecond = $"../UICanvas/UI/VBox/HBoxContainer2/InfoLabel2"
onready var pathPrefab = $"./PathPrefab"


onready var receiver = $"../RadioCalculator"
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
	if run_spreadsheet_test:
		begin_spreadsheet_run()
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
		
		
func begin_spreadsheet_run():
	var totalDb = 0
	var minDb = 0
	var maxDb = -100
	var incrementCount = 0
	var tolerance = -96
	
	var real_db = 0.0
	var real_miss = 0
	var log_db = 0.0
	var log_miss = 0
	var itu_db = 0.0
	var itu_miss = 0
	var mk_db = 0.0
	var mk_miss = 0
	
	# For every entry
	for i in spreadsheet.size():
		var entry = spreadsheet[i]
		var long_and_lat = [float(entry[3]), float(entry[2])]
		var global_coords = projectionVectorToGlobalCoords(long_and_lat)
		
		# Set receiver position
		receiver.global_position = global_coords
		
		# Display all original data
		var spreadsheet_data = ""
		var simulated_data = ""
		for j in range(4, 10):
			incrementCount += 1
			
			var beaconPos = beacons[j-4].get_global_position()
			# Real data
			var real = float(entry[j])
			if real != 0:
				real_db += (real - real_db) / incrementCount
			else:
				incrementCount -= 1
				continue
				real_miss += 1
				
			var ldpl = receiver.get_model_budget_to_position(receiver.ModelType.LOG_DISTANCE, beaconPos)
			if ldpl > tolerance:
				log_db += (ldpl - log_db) / incrementCount
			else:
				log_miss += 1
				
			var itu = receiver.get_model_budget_to_position(receiver.ModelType.ITU, beaconPos)
			if itu > tolerance:
				itu_db += (itu - itu_db) / incrementCount
			else:
				itu_miss += 1
				
			var mk = receiver.get_model_budget_to_position(receiver.ModelType.MOTLEY_KEENAN, beaconPos)
			if mk > tolerance:
				mk_db += (mk - mk_db) / incrementCount
			else:
				mk_miss += 1

	
	print("Real data: average - {0} dB, miss - {1}".format([real_db, real_miss]))
	print("Log: average - {0} dB, miss - {1}".format([log_db, log_miss]))
	print("ITU: average - {0} dB, miss - {1}".format([itu_db, itu_miss]))
	print("Motley: average - {0} dB, miss - {1}".format([mk_db, mk_miss]))
	var results = SimulationResults.new()
	results.totalDb = totalDb
	results.minDb = minDb
	results.maxDb = maxDb
	return results
	

# Positions can be regarded as beacons
func simulate_from_positions(positions, should_color=false) -> SimulationResults:
	# Below -90 we wont tolerate signal loss
	var tolerance = -90
	
	var totalDb = 0.0
	var incrementCount = 1
	var out_of_range_count = 0
	var node_index = 0.0
	
	for node in path_nodes:
		receiver.global_position = node.global_position
		# reachable beacons from this node point
		var reachable_beacon_count = 0
		var reachable_beacon_positions = []
		for beacon_pos in positions:
			var pl = receiver.get_log_distance_to_position(beacon_pos) 
			
			if pl > tolerance:
				reachable_beacon_count += 1
				reachable_beacon_positions.append(beacon_pos)
				totalDb += int((pl - totalDb) / incrementCount)
				assert(typeof(totalDb) != TYPE_STRING)
				incrementCount = incrementCount + 1
			# End inner loop
		
		# Get node index
		var dir_vectors = []
		for beacon in reachable_beacon_positions:
			var dir_vector = receiver.global_position.direction_to(beacon)
			dir_vectors.append(dir_vector)
		
		dir_vectors.sort_custom(Sorter, "sort_clockwise")
		if dir_vectors.size() >= 3:
			var total_angle = 0.0
			for i in range(dir_vectors.size() - 1):
				total_angle += abs(dir_vectors[i].angle_to(dir_vectors[i+1]))
				
			print("Total angle: " + str(total_angle))
			
		if reachable_beacon_count >= 3:
			if should_color:
				node.self_modulate = Color(0, 1, 0, 1)
		else:
			out_of_range_count += 1
			if should_color:
				node.self_modulate = Color(1, 0, 0, 1)
			
	

	var results = SimulationResults.new()
	results.totalDb = totalDb
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
		simulated_data += receiver.get_string_info_from_position(beacons[i-4].get_global_position()) + '\n'
		spreadsheet_data += spreadsheet[0][i] + " - Captured: "  + "%.2f" % float(entry[i]) + '\n'
		
	infoLabel.text = spreadsheet_data #'{}\n{}\n'.format([entry[4], entry[5]], '{}')
	infoLabelSecond.text = simulated_data
	

func hook_to_ui():
	slider.min_value = 1;
	slider.max_value = spreadsheet.size() - 1;


func _on_IterationSlider_value_changed(value):
	label.text = str(value)
	scan_position(value)
