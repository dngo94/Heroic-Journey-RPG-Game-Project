extends Node2D

export(int) var roaming_range = 32

onready var start_position = global_position #holds the current position
onready var target_position = global_position #initialize new position
onready var timer = $Timer #Call Timer node

func _ready():
	position_update()
	
func position_update(): #randome a new position
	var target_vector = Vector2(rand_range(-roaming_range,roaming_range),rand_range(-roaming_range,roaming_range))
	target_position = target_vector

func get_time_left(): 
	return timer.time_left
	
func start_roaming_timer(duration):
	timer.start(duration)

func _on_Timer_timeout(): #update position when time runs out
	position_update()
