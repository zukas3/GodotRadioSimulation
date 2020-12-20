extends Node2D

class Helper:
	
	var tlc
	var brc
	var dss
	var tree
	
	func _init(tlc, brc, dss, tree):
		self.tlc = tlc
		self.brc = brc
		self.dss = dss
		self.tree = tree
	
	func random_node_position():
		var nodes = tree.get_nodes_in_group("path_nodes")
		var random = randi() % nodes.size()
		return nodes[random].global_position
	
	func random_position_in_building():
		randomize()
		var x = rand_range(tlc.x, brc.x)
		var y = rand_range(tlc.y, brc.y)
		var point = Vector2(x, y)

		var result = dss.intersect_point(point, 32, [], 2147483647, true, true)
				
		# Repeat while we are inside building area
		while result.empty():
			x = rand_range(tlc.x, brc.x)
			y = rand_range(tlc.y, brc.y)
			point = Vector2(x, y)
			result = dss.intersect_point(point, 32, [], 2147483647, true, true)

		return point

class Individual:
	var gene_count = 6
	var gene_locations = [] # Beacon locations
	var fitness
	
	func _init():
		
		pass
		
	func generate_random_genes(helper):
		for i in range(0, gene_count):
			var point = helper.random_node_position()
			gene_locations.append(point)
			
	func has_similar_location(position:Vector2):
		for pos in gene_locations:
			if position.distance_to(pos) < 100:
				return true
		
		return false
	

class Population:
	
	var mutation_chance
	var individual_count = 50
	
	var individuals = []
	
	var sim_runner
	var helper
	
	func _init(sim_runner, mutation_chance, helper):
		self.sim_runner = sim_runner
		self.mutation_chance = mutation_chance
		self.helper = helper
		
		
	func generate_gen_zero():
		for i in range(0, individual_count):
			var individual = Individual.new()
			individual.generate_random_genes(helper)
			individuals.append(individual)
	
	func calculate_fitness(individual):
		var result = sim_runner.simulate_from_positions(individual.gene_locations)
		var fitness = 1.0
		if result.out_of_range_count != 0:
			fitness = (0.9 / result.out_of_range_count) + (60 / result.totalDb) * 0.1
		individual.fitness = fitness
	
	func calculate_all_fitness():
		for individual in individuals:
			calculate_fitness(individual)
		
	func get_most_fitting():
		var currentIndividual = individuals[0]
		for individual in individuals:
			if individual.fitness > currentIndividual.fitness:
				currentIndividual = individual
				
		return currentIndividual
		
	func get_second_most_fitting():
		var currentIndividual = individuals[0]
		var secondIndividual = individuals[0]
		for individual in individuals:
			if individual.fitness > currentIndividual.fitness:
				secondIndividual = currentIndividual
				currentIndividual = individual
				
		return secondIndividual
		
	func get_least_fitting():
		var currentIndividual = individuals[0]
		for individual in individuals:
			if individual.fitness < currentIndividual.fitness:
				currentIndividual = individual
				
		return currentIndividual
		
	func get_second_least_fitting():
		var currentIndividual = individuals[0]
		var secondIndividual = individuals[0]
		for individual in individuals:
			if individual.fitness < currentIndividual.fitness:
				secondIndividual = currentIndividual
				currentIndividual = individual
				
		return secondIndividual
		
	func index_of(individual):
		for i in range(individual_count):
			if individuals[i] == individual:
				return i
		return -1
		
	func crossover():
		var mom = select()
		var dad = select()
		var least_fitting_first = index_of(get_least_fitting())
		var least_fitting_second = index_of(get_second_least_fitting())
		
		randomize()
		var num1 = randi() % 6
		var num2 = randi() % 6
		var segment_start = min(num1, num2)
		var segment_end = max(num1, num2)
		
		var offspring_one = offspring(segment_start, segment_end, mom, dad)
		var offspring_two = offspring(segment_start, segment_end, dad, mom)
			
		mutate(offspring_one)
		mutate(offspring_two)
		
		individuals[least_fitting_first] = offspring_one
		individuals[least_fitting_second] = offspring_two
	
	func offspring(start, end, mom, dad):
		var child = Individual.new()
		child.gene_locations = mom.gene_locations.duplicate()
		for i in range(start, end):
			var target_gene = dad.gene_locations[i]
			if child.has_similar_location(target_gene):
				child.gene_locations[i] = (dad.gene_locations[i] + mom.gene_locations[i]) / 2
			else:
				child.gene_locations[i] = dad.gene_locations[i]  #(dad.gene_locations[i] + mom.gene_locations[i]) / 2
		
		calculate_fitness(child)
		return child
		
	func mutate(individual):
		randomize()
		for i in range(6):
			var random = rand_range(0.0, 1.0)
			if random < mutation_chance:
				individual.gene_locations[i] = helper.random_node_position()
		
	
	func select():
		var fitnessSum = 0
		for indiv in individuals:
			fitnessSum += indiv.fitness 
		
		var roll = rand_range(0.0, 1.0) * fitnessSum
		for indiv in individuals:
			if roll < indiv.fitness:
				return indiv
			else:
				roll -= indiv.fitness
		
		assert("NOOO")
	



var population : Population

export var generations_count = 1000
export var mutation_rate = 0.05
export var top_left_corner : Vector2
export var bottom_right_corner : Vector2

onready var simulation_runner = $".."
onready var beacons = get_tree().get_nodes_in_group("beacons")

var current_generation = 0
var is_ready = false
var helper

func _ready():
	yield(get_tree().root, "ready")
	
	helper = Helper.new(top_left_corner, bottom_right_corner, get_world_2d().direct_space_state, get_tree())
	
	population = Population.new(simulation_runner, mutation_rate, helper)
	population.generate_gen_zero()
	population.calculate_all_fitness()
	place_real_beacons_on_most_fitting()
	
	print("--")
	print(population.get_most_fitting().fitness)
	print(population.index_of(population.get_most_fitting()))
	print(population.get_second_most_fitting().fitness)
	print(population.get_least_fitting().fitness)
	print(population.index_of(population.get_least_fitting()))
	
	is_ready = true


func _process(delta):
	if is_ready and current_generation < generations_count:
		print("Generation: " + str(current_generation))
		print(population.get_most_fitting().fitness)
		current_generation = current_generation + 1
		population.crossover()
		place_real_beacons_on_most_fitting()
		

func calculate_fitness():
	pass

func crossover():
	pass
	
func mutate():
	pass

func place_real_beacons_on_most_fitting():
	var mostFitting = population.get_most_fitting()
	for i in range(mostFitting.gene_count):
		beacons[i].global_position = mostFitting.gene_locations[i]
