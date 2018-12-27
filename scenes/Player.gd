extends KinematicBody

# Stages of an attacK:
# 1. Standby
# 2. Wind-up
# 3. Strike
# 4. Follow Through

export var player1 = false

onready var particles = $Particles

const DASH_VEL = 20;
const DASH_SPD = 0.4;
const DASH_ACL = 8;
const KNOCKBACK_VEL = 10;
const KNOCKBACK_SPD = 0.3;
const KNOCKBACK_ACL = 5

const LEAP_BACK_SCALE = 0.5

var IDLING = State.new(Vector3(0, 0, 0), 0, Vector3(0, 0, 0), StateType.IDLING)
var DASHING = State.new(Vector3(DASH_VEL, 0, 0), DASH_SPD, Vector3(DASH_ACL, 0, 0), StateType.DASHING)
var KNOCKBACK = State.new(Vector3(KNOCKBACK_VEL, 0, 0), KNOCKBACK_SPD, Vector3(KNOCKBACK_ACL, 0, 0), StateType.KNOCKED_BACK)

var acceleration = Vector3()
var velocity = Vector3()
var movementScale = 0

var currentState = self.IDLING

var stateTime = 0

var health = 100

const INPUT_RETENTION_TIME = 0.5

var inputCountdown = 0

var player1MoveRight = false
var player1MoveLeft = false

var player2MoveLeft = false
var player2MoveRight = false

func _ready():
	particles.set_emitting(false)
	particles.set_one_shot(true)

func _physics_process(delta):
	
	if player1:
		if Input.is_action_just_pressed("player1_move_right"):
			player1MoveRight = true
			player1MoveLeft = false
			inputCountdown = INPUT_RETENTION_TIME
		elif Input.is_action_just_pressed("player1_move_left"):
			player1MoveLeft = true
			player1MoveRight = false
			inputCountdown = INPUT_RETENTION_TIME
	else:
		if Input.is_action_just_pressed("player2_move_right"):
			player2MoveRight = true
			player2MoveLeft = false
			inputCountdown = INPUT_RETENTION_TIME
		elif Input.is_action_just_pressed("player2_move_left"):
			player2MoveLeft = true
			player2MoveRight = false
			inputCountdown = INPUT_RETENTION_TIME

	match currentState.stateType:
		StateType.IDLING:
			
			if player1:
				if player1MoveRight:
					set_movement_state(self.DASHING, 1)
					player1MoveRight = false
				elif player1MoveLeft:
					set_movement_state(self.DASHING, -1 * LEAP_BACK_SCALE)
					player1MoveLeft = false
			else:
				if player2MoveRight:
					set_movement_state(self.DASHING, 1 * LEAP_BACK_SCALE)
					player2MoveRight = false
				elif player2MoveLeft:
					set_movement_state(self.DASHING, -1)
					player2MoveLeft = false
		
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
		
	
	if inputCountdown > 0:
		
		inputCountdown -= delta
		
		if inputCountdown <= 0:
			inputCountdown = 0
			
			player1MoveRight = false
			player1MoveLeft = false
			
			player2MoveLeft = false
			player2MoveRight = false
	
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
