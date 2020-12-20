extends Node2D

const c = 299792458.0 # Speed of the light
const gamma = 2.2 # Path loss exponent
export var normal = 14.1

const fsplConst = -27.55 # Free Space Path loss constant when in meters and megahertz
const meterInGodotUnits = 29.64959568 # approximately

export var refDistance = 2.0 # d0
export var frequency = 2.4 * 1000 # 2.4 GHz in MHz
export var transmitterGain = -8 # in dB
export var receiverGain = -1.1 # in dB


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func calculate_with_all():
	var localPos = get_global_position()
	
	var beacons = get_tree().get_nodes_in_group("beacons")
	print("Calculating radio link budgets")
	for beacon in beacons:
		print("--" + beacon.name + "--")
		var beaconPos = beacon.get_global_position();
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(localPos, beaconPos)
		# Find all obstacles
		var hits = []
		var obstacles = []
		while(true):
			var ray_result = space_state.intersect_ray(localPos, beaconPos, hits)
			if(ray_result.empty()):
				break
			
			hits.append(ray_result.collider)
			obstacles.append(12) # Concrete wall value used
		
		var distance = beaconPos.distance_to(localPos) / meterInGodotUnits
		print("Distance: " + str(distance) + " Obstacles:" + str(obstacles))
		calculateAllTypes(distance, obstacles)
		print()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func calculate_to_position(position):
	var localPos = get_global_position()
	var beaconPos = position
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(localPos, beaconPos)
	# Find all obstacles
	var hits = []
	var obstacles = []
	while(true):
		var ray_result = space_state.intersect_ray(localPos, beaconPos, hits)
		if(ray_result.empty()):
			break
			
		hits.append(ray_result.collider)
		obstacles.append(12) # Concrete wall index
		
	var distance = beaconPos.distance_to(localPos) / meterInGodotUnits
	print("Distance: " + str(distance) + " Obstacles:" + str(obstacles))
	return calculateAllTypes(distance, obstacles)
	
func get_log_distance_to_position(position):
	var localPos = get_global_position()
	var beaconPos = position
	var distance = beaconPos.distance_to(localPos) / meterInGodotUnits
	var ldpl = calculateLogDistancePathLoss(distance)
	ldpl = calculateRadioLinkBudget(ldpl)
	return ldpl
	

func calculateRadioLinkBudget(loss):
	var rlb = transmitterGain + receiverGain - loss
	return rlb

func calculateAllTypes(distance, obstacles):
	var result
	
	result = calculateLogDistancePathLoss(distance)
	var ldpl = "LDPL: " + "%.2f" % calculateRadioLinkBudget(result) + " dB"
	print(ldpl)
	result = calculateITU(distance)
	var itu = "ITU: " + "%.2f" % calculateRadioLinkBudget(result) + " dB"
	print(itu)
	result = calculateMotleyKeenan(distance, obstacles)
	var motley = "MotleyKeenan: " + "%.2f" % calculateRadioLinkBudget(result) + " dB"
	print(motley)
	return ldpl + "; " + itu + "; " + motley + "; " + "%.2f" % distance + "m "


# Calculates path loss using reference distance
func calculateFreeSpacePathLoss():
	var dlog = 20 * (log(refDistance) / log(10))
	var flog = 20 * (log(frequency) / log(10))
	var clog = 20 * (log(((4*PI)/c)) / log(10)) 
	var fspl = dlog + flog + fsplConst
	return fspl


func calculateLogDistancePathLoss(distance):
	var pl = calculateFreeSpacePathLoss() + 10 * gamma * (log(distance/refDistance) / log(10)) + normal
	return pl

func calculateMotleyKeenan(distance, obstacles):
	
	var sigma = 0;
	for i in range(0, obstacles.size()):
		sigma = sigma + obstacles[i]
	
	var pl = calculateFreeSpacePathLoss() + 10 * gamma * (log(distance/refDistance) / log(10)) + sigma
	return pl

func calculateITU(distance):
	var flog = 20 * (log(frequency) / log(10)) 
	var nlog = 30 * (log(distance) / log(10))
	# Floors are not important for us so it is exempt
	var itu = flog + nlog - 28
	return itu
