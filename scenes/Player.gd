extends KinematicBody

# Stages of an attacK:
# 1. Standby
# 2. Wind-up
# 3. Strike
# 4. Follow Through

export var player1 = false

onready var particles = $Particles

var IDLING = State.new(Vector3(0, 0, 0), 0, Vector3(0, 0, 0), StateType.IDLING)
var DASHING = State.new(Vector3(20, 0, 0), 0.1, Vector3(10, 0, 0), StateType.DASHING)
var KNOCKBACK = State.new(Vector3(10, 0, 0), 0.1, Vector3(5, 0, 0), StateType.KNOCKED_BACK)

var acceleration = Vector3()
var velocity = Vector3()
var movementScale = 0

var currentState = self.IDLING

var stateTime = 0

var health = 100

func _ready():
	particles.set_emitting(false)
	particles.set_one_shot(true)

func _physics_process(delta):
	
	match currentState.stateType:
		StateType.IDLING:
			
			if player1:
				if Input.is_action_just_pressed("player1_move_right"):
					set_movement_state(self.DASHING, 1)
				elif Input.is_action_just_pressed("player1_move_left"):
					set_movement_state(self.DASHING, -1)
			else:
				if Input.is_action_just_pressed("player2_move_right"):
					set_movement_state(self.DASHING, 1)
				elif Input.is_action_just_pressed("player2_move_left"):
					set_movement_state(self.DASHING, -1)
		
		StateType.DASHING:
			
			stateTime -= delta
			velocity += acceleration * delta
			move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 2)
			
			if get_slide_count() > 0:
				
				stateTime = 0
				
				var collision = get_slide_collision(0)
				var otherPlayer = collision.collider
				
				if otherPlayer.is_class("KinematicBody"):
					match otherPlayer.currentState.stateType:
						StateType.IDLING:
							otherPlayer.hit(self, movementScale)
			
		StateType.KNOCKED_BACK:
			stateTime -= delta
			move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 2)
		
	
	if stateTime <= 0:
		stateTime = 0
		currentState = self.IDLING
	

func set_movement_state(state, movementScale):
	
	currentState = state
	self.movementScale = movementScale
	
	velocity = state.velocity * movementScale
	acceleration = state.acceleration * movementScale
	stateTime = state.time
	

func hit(attacker, knockbackScale):
	
	particles.restart()
	
	set_movement_state(self.KNOCKBACK, knockbackScale)
	

class State:
	
	var velocity
	var time
	var acceleration
	var stateType
	
	func _init(velocity, time, acceleration, stateType):
		self.velocity = velocity
		self.time = time
		self.acceleration = acceleration
		self.stateType = stateType

enum StateType {
	IDLING,
	BLOCKING,
	DASHING,
	KNOCKED_BACK,
	STUNNED,
}
