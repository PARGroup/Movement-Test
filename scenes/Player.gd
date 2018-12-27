extends KinematicBody

# Stages of an attacK:
# 1. Standby
# 2. Wind-up
# 3. Strike
# 4. Follow Through

export var player1 = false

onready var particles = $Particles

var acceleration = Vector3()
var velocity = Vector3()
var movementDirection = Vector3()

var dashProperties = StateProperties.new(3.5, 0.25)
var defenseProperties = StateProperties.new(1, 0.5)
var knockbackProperties = StateProperties.new(0.5, 0.1)

var state = State.IDLING
var stateTime = 0

var health = 100

func _ready():
	particles.set_emitting(false)
	particles.set_one_shot(true)

func _physics_process(delta):
	
	match state:
		State.IDLING:
			
			if player1:
				if Input.is_action_just_pressed("player1_move_right"):
					set_movement_state(State.DASHING, dashProperties, Vector3(1, 0, 0))
				elif Input.is_action_just_pressed("player1_move_left"):
					set_movement_state(State.DASHING, dashProperties, Vector3(-1, 0, 0))
			else:
				if Input.is_action_just_pressed("player2_move_right"):
					set_movement_state(State.DASHING, dashProperties, Vector3(1, 0, 0))
				elif Input.is_action_just_pressed("player2_move_left"):
					set_movement_state(State.DASHING, dashProperties, Vector3(-1, 0, 0))
		
		State.DASHING:
			stateTime -= delta
			move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 2)
			
			if get_slide_count() > 0:
				
				stateTime = 0
				
				var collision = get_slide_collision(0)
				var otherPlayer = collision.collider
				
				match otherPlayer.state:
					State.IDLING:
						otherPlayer.hit(self, movementDirection)
			
		State.KNOCKED_BACK:
			stateTime -= delta
			move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 2)
		
	
	if stateTime <= 0:
		stateTime = 0
		state = State.IDLING
		movementDirection = Vector3(0, 0, 0)
	

func set_movement_state(state, stateProperties, direction):
	
	self.state = state
	stateTime = stateProperties.time
	movementDirection = direction
	
	velocity = direction * (stateProperties.distance / stateProperties.time)
	

func hit(attacker, knockbackDirection):
	
	particles.restart()
	particles.set_emitting(true)
	
	set_movement_state(State.KNOCKED_BACK, knockbackProperties, knockbackDirection)
	

class StateProperties:
	
	var distance
	var time
	
	func _init(distance, time):
		self.distance = distance
		self.time = time

enum State {
	IDLING,
	BLOCKING,
	DASHING,
	KNOCKED_BACK,
	STUNNED,
}
