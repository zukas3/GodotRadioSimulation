extends Node2D

const c = 299792458.0 # Speed of the light
const gamma = 2.2 # Path loss exponent
const normal = 0

const fsplConst = -27.55 # Free Space Path loss constant when in meters and megahertz

var distance = 10 # In meters
var refDistance = 2 # d0
var frequency = 2.4 * pow(10, 9) # In GHz
var transmitterGain = -8 # in dB
var receiverGain = -1.1 # in dB


# Called when the node enters the scene tree for the first time.
func _ready():
	var result = calculateLogDistancePathLoss()
	print("LDPL: " +  str(result) + " dB")
	result = calculateITU(distance)
	print("ITU: " +  str(result) + " dB")
	result = calculateMotleyKeenan([0])
	print("MotleyKeenan: " +  str(result) + " dB")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Calculates path loss using reference distance
func calculatePathLoss():
	var dlog = 20 * (log(refDistance) / log(10))
	var flog = 20 * (log(frequency) / log(10))
	var clog = 20 * (log(((4*PI)/c)) / log(10)) 
	var fspl = dlog + flog + clog - transmitterGain - receiverGain
	return fspl


func calculateLogDistancePathLoss():
	var pl = calculatePathLoss() + 10 * gamma * (log(distance/refDistance) / log(10)) + normal
	return pl

func calculateMotleyKeenan(obstacles):
	
	var sigma = 0;
	for i in range(0, obstacles.size()):
		sigma = sigma + obstacles[i]
	
	var pl = calculatePathLoss() + 10 * gamma * (log(distance/refDistance) / log(10)) + sigma
	return pl

func calculateITU(distanceInMeter):
	var flog = 20 * (log(frequency * 1000) / log(10)) # Takes in MHz, that's why we multiply frequency by 1000
	var nlog = 30 * (log(distanceInMeter)/log(10))
	# Floors are not important for us so it is exempt
	var itu = flog + nlog - 28
	return itu
