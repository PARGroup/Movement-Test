extends KinematicBody

# Stages of an attacK:
# 1. Standby
# 2. Wind-up
# 3. Strike
# 4. Follow Through

export var player1 = false

onready var particles = $Particles

const DASH_VEL = 30;
const DASH_TIME = 0.2;
const DASH_ACL = 10;
const KNOCKBACK_VEL = 15;
const KNOCKBACK_TIME = 0.1;
const KNOCKBACK_ACL = 8
const ATTACK_TIME = 0.3
const BLOCK_TIME = 0.1

const LEAP_BACK_SCALE = 0.65

const INPUT_RETENTION_TIME = 0.5

var matDefault = load("res://Materials/Default.material")
var matAttacking = load("res://Materials/Attacking.material")
var matBlocking = load("res://Materials/Blocking.material")

var IDLING = State.new(Vector3(0, 0, 0), 0, Vector3(0, 0, 0), StateType.IDLING, matDefault)
var DASHING = State.new(Vector3(DASH_VEL, 0, 0), DASH_TIME, Vector3(DASH_ACL, 0, 0), StateType.DASHING, matDefault)
var KNOCKBACK = State.new(Vector3(KNOCKBACK_VEL, 0, 0), KNOCKBACK_TIME, Vector3(KNOCKBACK_ACL, 0, 0), StateType.KNOCKED_BACK, matDefault)
var ATTACKING = State.new(Vector3(0, 0, 0), ATTACK_TIME, Vector3(0, 0, 0), StateType.ATTACKING, matAttacking)
var BLOCKING = State.new(Vector3(0, 0, 0), BLOCK_TIME, Vector3(0, 0, 0), StateType.BLOCKING, matBlocking)

var acceleration = Vector3()
var velocity = Vector3()
var movementScale = 0

var currentState = self.IDLING

var stateTime = 0

var health = 100

var inputCountdown = 0

var player1MoveRight = false
var player1MoveLeft = false

var player2MoveLeft = false
var player2MoveRight = false

func _ready():
	particles.set_emitting(false)
	particles.set_one_shot(true)

func _physics_process(delta):
	
	var attackers = []
	var test = get_node("Hurtbox").get_overlapping_areas()
	for body in test:
		if body.get_owner() != self && body.is_class("Area") && body.get_owner().is_attacking():
			attackers.append(body.get_owner())
	
	if player1:
		if Input.is_action_just_pressed("player1_move_right"):
			if(attackers.empty()):
				player1MoveRight = true
				player1MoveLeft = false
				inputCountdown = INPUT_RETENTION_TIME
			else:
				set_state(self.BLOCKING)
				for body in attackers:
					if body.player1:
						body.hit(self, -2)
					else:
						body.hit(self, 2)
		elif Input.is_action_just_pressed("player1_move_left"):
			if(attackers.empty()):
				player1MoveLeft = true
				player1MoveRight = false
				inputCountdown = INPUT_RETENTION_TIME
			else:
				set_state(self.BLOCKING)
				for body in attackers:
					if body.player1:
						body.hit(self, -2)
					else:
						body.hit(self, 2)
	else:
		if Input.is_action_just_pressed("player2_move_right"):
			if(attackers.empty()):
				player2MoveRight = true
				player2MoveLeft = false
				inputCountdown = INPUT_RETENTION_TIME
			else:
				set_state(self.BLOCKING)
				for body in attackers:
					if body.player1:
						body.hit(self, -2)
					else:
						body.hit(self, 2)
		elif Input.is_action_just_pressed("player2_move_left"):
			if(attackers.empty()):
				player2MoveLeft = true
				player2MoveRight = false
				inputCountdown = INPUT_RETENTION_TIME
			else:
				set_state(self.BLOCKING)
				for body in attackers:
					if body.player1:
						body.hit(self, -2)
					else:
						body.hit(self, 2)

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
			
			var collisions = get_node("Hitbox").get_overlapping_bodies()
			
			for body in collisions:
				if body != self && body.is_class("KinematicBody"): #change to specify players
					set_state(self.ATTACKING)
			
		StateType.ATTACKING:
			stateTime -= delta
			
			if stateTime <= 0:
				var collisions = get_node("Hitbox").get_overlapping_bodies()
			
				for body in collisions:
					if body != self && body.is_class("KinematicBody"):
						if body.player1:
							body.hit(self, -2)
						else:
							body.hit(self, 2)
			
		StateType.BLOCKING:
			stateTime -= delta
			
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
		set_state(self.IDLING)
	
func set_state(state):
	stateTime = state.time
	currentState = state
	get_node("MeshInstance").set_material_override(state.material)

func set_movement_state(state, movementScale):
	
	self.movementScale = movementScale
	
	velocity = state.velocity * movementScale
	acceleration = state.acceleration * movementScale
	set_state(state)

func hit(attacker, knockbackScale):
	
	particles.restart()
	
	set_movement_state(self.KNOCKBACK, knockbackScale)
	

func is_attacking():
	if currentState == self.ATTACKING:
		return true
	else:
		return false

class State:
	
	var velocity
	var time
	var acceleration
	var stateType
	var material
	
	func _init(velocity, time, acceleration, stateType, material):
		self.velocity = velocity
		self.time = time
		self.acceleration = acceleration
		self.stateType = stateType
		self.material = material

enum StateType {
	IDLING,
	BLOCKING,
	DASHING,
	KNOCKED_BACK,
	STUNNED,
	ATTACKING,
	BLOCKING,
}
