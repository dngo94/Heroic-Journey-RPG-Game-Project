extends KinematicBody2D

export var MAX_ROAMING_RANGE = 4
export var MAX_SPEED = 100
export var GRAVITY = 20
export var ACCELERATION = 80
export var FRICTION = 150

var velocity = Vector2()
var knockback = Vector2.ZERO
var state = CHASE

enum {
	IDLE,
	TAKE_HIT,
	DEATH,
	CHASE,
	ATTACK,
	ROAM
}

onready var initial_scale = scale
onready var roamAI = $RoamingAI
onready var stats = $Stats
onready var hp = stats.health
onready var playerDetectionZone = $PlayerDectection
onready var animationPlayer = $AnimationPlayer
onready var animationState = $AnimationTree.get("parameters/playback")


var coin_scene = preload("res://src/Scenes/Items/Coin.tscn")
var floatingText = preload("res://src/Scenes/Interface/floating_text.tscn")

func _ready():
	pick_random_state([IDLE,ROAM])
	randomize() #to random the game's seed every time 
	
func _physics_process(delta):
	velocity.y += GRAVITY	
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	match state:
		IDLE:
			idle_state(delta)
		TAKE_HIT:
			take_hit(delta)
		DEATH:
			death_state(delta)
		CHASE:
			chase_state(delta)
		ATTACK:
			attack_state()
		#RPG enemies's AI: Free on roaming
		ROAM:
			detectPlayer()
			if roamAI.get_time_left() == 0:
				roamAI_update()
			var direction = global_position.direction_to(roamAI.target_position).normalized()
			if roamAI.target_position.x < 0:
				animationState.travel("Run")
				scale.x = -initial_scale.x * sign(scale.y)
				velocity.x = -max(direction.x + ACCELERATION, MAX_SPEED * delta)
			elif roamAI.target_position.x > 0:
				animationState.travel("Run")
				scale.x = initial_scale.x * sign(scale.y)
				velocity.x = max(direction.x + ACCELERATION, MAX_SPEED * delta)
			
			#Prevent enemies from roaming too far away their original position
			if global_position.distance_to(roamAI.target_position) <= MAX_ROAMING_RANGE:
				roamAI_update()
			
			area_checking()
				
	#if the enemies fall, they will die
	if velocity.y > 650:
		queue_free()
	
	velocity = move_and_slide(velocity)

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func roamAI_update():
	state = pick_random_state([IDLE,ROAM])
	roamAI.start_roaming_timer(rand_range(1,3))
	
func detectPlayer():
	if playerDetectionZone.detected():
		state = CHASE

func _on_Hurtbox_area_entered(area):
	if area.name == "Hitbox":
		hp -= area.MAX_DAMAGE
		var text = floatingText.instance()
		text.amount = area.MAX_DAMAGE
		add_child(text)
		knockback = area.knockback_vector * FRICTION
		state = TAKE_HIT
		if hp < 0:
			state = DEATH
			on_death()

func idle_state(delta):
	velocity.x = 0
	animationState.travel("Idle")
	detectPlayer()
	if roamAI.get_time_left() == 0:
		roamAI_update()
	
func take_hit(delta):
	animationState.travel("Take_Hit")
	
func death_state(delta):
	velocity.x = 0
	animationState.travel("Death")

#RPG enemies's A.I: Detect and chase after player
func chase_state(delta):
	var player = playerDetectionZone.player
	if player != null: 
		var location = (player.global_position  - global_position).normalized()
		animationState.travel("Run")
		if player.global_position < global_position:
			scale.x = -initial_scale.x * sign(scale.y)
			velocity.x = -max(location.x + ACCELERATION, MAX_SPEED * delta)
			area_checking()
		else:
			scale.x = initial_scale.x * sign(scale.y)
			velocity.x = max(location.x + ACCELERATION, MAX_SPEED * delta)
			area_checking()
		
		if is_on_wall():
			animationState.travel("Attack")
	else:
		state = IDLE
				
func attack_state():
	animationState.travel("Attack")

func takehit_finished():
	state = IDLE
	
func attack_finished():
	state = IDLE

func on_death():
	var coin = coin_scene.instance()
	coin.global_position = global_position
	get_parent().add_child(coin)

func area_checking():
	#If standing too close to the edge
	if $RayCast2D.is_colliding() == false:
		state = IDLE 
			
	#Detect collision with wall
	if is_on_wall():
		animationState.travel("Idle")
