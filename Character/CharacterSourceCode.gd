extends KinematicBody2D

export var MAX_SPEED = 200
export var GRAVITY = 20
export var ACCELERATION = 80
export var JUMP_PW= -400
export var FRICTION = 150

var state = MOVE
var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
var spriteFlipped = false
var coin_on_hands = 0

onready var stats = $Stats
onready var hp = stats.health
onready var pos_hit = $Position2D/Hitbox
onready var initial_scale = scale
onready var animationPlayer = $AnimationPlayer
onready var animationState = $AnimationTree.get("parameters/playback")
onready var swordHitbox = $Position2D/Hitbox
onready var pickupZone = $PickupZone
#onready var save_current_data = $Global

signal coin_updated(coin_on_hands)
signal health_updated(hp)
var floatingText = preload("res://src/Scenes/Interface/floating_text.tscn")

enum {
	MOVE,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3
	DEATH,
	BLOCK
}
func _ready():
	randomize()

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	velocity = move_and_slide(velocity, Vector2.UP)
	velocity.y += GRAVITY 
	
	match state:
		MOVE:
			move_state(delta)
		ATTACK_1:
			attack_state1(delta)
		ATTACK_2:
			attack_state2(delta)
		ATTACK_3:
			attack_state3(delta)
		BLOCK:
			block_state()
		DEATH:
			death_state(delta)

func move_state(delta):
	var input_vector = Vector2.ZERO
	var on_ground = false

	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		swordHitbox.knockback_vector = input_vector
		if input_vector.x > 0:
			velocity.x = min(velocity.x + ACCELERATION, MAX_SPEED)
			scale.x = initial_scale.x * sign(scale.y)
			spriteFlipped = true
		elif input_vector.x < 0:
			velocity.x = max(velocity.x - ACCELERATION, -MAX_SPEED) 
			scale.x = -initial_scale.x * sign(scale.y)
			spriteFlipped = false
		animationState.travel("Run")
	else:
		animationState.travel("Idle")
		on_ground = true

	if is_on_floor():
		var jump_count = 2
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_PW
		if on_ground == true:
			velocity.x = lerp(velocity.x, 0 , 0.1)
		
		#While not jump	
		if Input.is_action_just_pressed("attack1"):
			state = ATTACK_1
		if Input.is_action_just_pressed("attack2"):
			state = ATTACK_2
		if Input.is_action_just_pressed("attack3"):
			state = ATTACK_3
	else:
		if velocity.y < 0:
			animationState.travel("Jump")
		else:
			animationState.travel("Fall")
			if velocity.y > 2000: #stop endless falling (temporary)
				get_tree().change_scene("res://src/Scenes/Menus/GameOver.tscn")
				
		if on_ground == true:
			velocity.x = lerp(velocity.x, 0 , 0.01)
		
func attack_state1(delta):
	velocity = Vector2.ZERO
	animationState.travel("Attack_1")

func attack_state2(delta):
	pos_hit.set_damage(3)
	velocity = Vector2.ZERO
	animationState.travel("Attack_2")

func attack_state3(delta):
	pos_hit.set_damage(5)
	velocity = Vector2.ZERO
	animationState.travel("Attack_3")
		
func attack_finished():
	state = MOVE
	
func block_finished():
	state = MOVE

func block_state():
	animationState.travel("Block")
	
func death_state(delta):
	GlobalSave.player_hp = 10
	animationState.travel("Death")

func update_velocity(value):
	velocity = value

func _on_Hurtbox_area_entered(area):
	if area.name == "Hitbox":
		#hp -= area.MAX_DAMAGE
		GlobalSave.player_hp -= area.MAX_DAMAGE
		#emit_signal("health_updated", GlobalSave.player_hp)
		var text = floatingText.instance()
		text.amount = area.MAX_DAMAGE
		add_child(text)
		state = BLOCK
		if spriteFlipped == true:
			knockback.x = -0.3 * FRICTION
		else:
			knockback.x = 0.3 * FRICTION
		if GlobalSave.player_hp < 0:
			state = DEATH
			get_tree().change_scene("res://src/Scenes/Menus/GameOver.tscn")
		
	if area.name == "Boss_Hitbox":
		print("Boss is attacking!")
		#hp -= area.MAX_DAMAGE
		GlobalSave.player_hp -= area.MAX_DAMAGE
		#emit_signal("health_updated", GlobalSave.player_hp)
		var text = floatingText.instance()
		text.amount = area.MAX_DAMAGE
		add_child(text)
		state = BLOCK
		
		if spriteFlipped == true:
			knockback.x = -1.5 * FRICTION
		else:
			knockback.x = 1.5 * FRICTION
		if GlobalSave.player_hp < 0:
			state = DEATH
			get_tree().change_scene("res://src/Scenes/Menus/GameOver.tscn")
			
func _on_PickupZone_area_entered(area):
	if area.name == "Coin":
		#coin_on_hands += 1
		GlobalSave.player_coin +=1
		print("Coin on hands: ", GlobalSave.player_coin)
		emit_signal("coin_updated", GlobalSave.player_coin)
	if area.name == "HealthPotion":
		if (GlobalSave.player_hp < stats.MAX_HEALTH):
			var MAX_HEALING = 2
			GlobalSave.player_hp += MAX_HEALING
			emit_signal("health_updated", GlobalSave.player_hp)
			var text = floatingText.instance()
			text.amount = MAX_HEALING
			add_child(text)
