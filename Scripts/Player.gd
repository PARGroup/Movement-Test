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
const BLOCK_TIME = 0.8
const STUN_TIME = 1.2

const LEAP_BACK_SCALE = 0.65

const INPUT_RETENTION_TIME = 0.5

var matDefault = load("res://Materials/Default.material")
var matAttacking = load("res://Materials/Attacking.material")
var matBlocking = load("res://Materials/Blocking.material")
var matStunned = load("res://Materials/Stunned.material")

var IDLING = State.new(Vector3(0, 0, 0), 0, Vector3(0, 0, 0), StateType.IDLING, matDefault)
var DASHING = State.new(Vector3(DASH_VEL, 0, 0), DASH_TIME, Vector3(DASH_ACL, 0, 0), StateType.DASHING, matDefault)
var KNOCKBACK = State.new(Vector3(KNOCKBACK_VEL, 0, 0), KNOCKBACK_TIME, Vector3(KNOCKBACK_ACL, 0, 0), StateType.KNOCKED_BACK, matDefault)
var ATTACKING = State.new(Vector3(0, 0, 0), ATTACK_TIME, Vector3(0, 0, 0), StateType.ATTACKING, matAttacking)
var BLOCKING = State.new(Vector3(0, 0, 0), BLOCK_TIME, Vector3(0, 0, 0), StateType.BLOCKING, matBlocking)
var STUNNED = State.new(Vector3(0, 0, 0), STUN_TIME, Vector3(0, 0, 0), StateType.STUNNED, matStunned)

var acceleration = Vector3()
var velocity = Vector3()
var movementScale = 0

var currentState = self.IDLING

var stateTime = 0

var health = 100

var inputCountdown = 0

var moveRight
var moveLeft

onready var hitBoxRight = get_node("HitboxRight")
onready var hitBoxLeft = get_node("HitboxLeft")
onready var hurtBox = get_node("Hurtbox")

func _ready():
	if player1:
		moveRight = "player1_move_right"
		moveLeft = "player1_move_left"
	else:
		moveRight = "player2_move_right"
		moveLeft = "player2_move_left"
		
	particles.set_emitting(false)
	particles.set_one_shot(true)

func _physics_process(delta):
		
	if stateTime != 0:
		stateTime -= delta
	
	match currentState.stateType:
		StateType.IDLING:
			if Input.is_action_just_pressed(moveRight):
				if(get_attackers("Left").empty()):
					inputCountdown = INPUT_RETENTION_TIME
					hitBoxRight.visible = true;
					hitBoxRight.monitoring = true;
					set_movement_state(self.DASHING, 1)
				else:
					set_state(self.BLOCKING)
			elif Input.is_action_just_pressed(moveLeft):
				if(get_attackers("Right").empty()):
					inputCountdown = INPUT_RETENTION_TIME
					hitBoxLeft.visible = true;
					hitBoxLeft.monitoring = true;
					set_movement_state(self.DASHING, -1)
				else:
					set_state(self.BLOCKING)
		
		StateType.DASHING:
			velocity += acceleration * delta
			move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 2)
			
			var collisions = get_enemy_collisions()
			
			for body in collisions:
				if body != self && body.is_class("KinematicBody"): #change to specify players
					set_state(self.ATTACKING)
			
		StateType.ATTACKING:
			
			if stateTime <= 0:
				var collisions = get_enemy_collisions()
			
				for body in collisions:
					if body != self && body.is_class("KinematicBody"):
						if body.player1:
							body.hit(self, -2)
						else:
							body.hit(self, 2)
			
			# Feinting
			if Input.is_action_just_pressed(moveRight) && !hitBoxRight.monitoring:
				inputCountdown = INPUT_RETENTION_TIME
				hitBoxLeft.visible = false;
				hitBoxLeft.monitoring = false;
				set_movement_state(self.DASHING, 0.5)
			elif Input.is_action_just_pressed(moveLeft) &&!hitBoxLeft.monitoring:
				inputCountdown = INPUT_RETENTION_TIME
				hitBoxRight.visible = false;
				hitBoxRight.monitoring = false;
				set_movement_state(self.DASHING, -0.5)
			
		StateType.BLOCKING:
			if get_attackers("Right").size() == 0 && get_attackers("Left").size() == 0:
				set_state(self.STUNNED)
			
		StateType.KNOCKED_BACK:
			move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 2)
	
	if inputCountdown > 0:
		
		inputCountdown -= delta
		
		if inputCountdown <= 0:
			inputCountdown = 0
	
	if stateTime <= 0:
		stateTime = 0
		hitBoxRight.visible = false;
		hitBoxRight.monitoring = false;
		hitBoxLeft.visible = false;
		hitBoxLeft.monitoring = false;
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
	if currentState == self.BLOCKING:
		attacker.hit(self, -knockbackScale)
		set_state(self.IDLING)
	else:
		particles.restart()
		set_movement_state(self.KNOCKBACK, knockbackScale)
	
func get_attackers(direction):
	var attackers = []
	var test = hurtBox.get_overlapping_areas()
	for body in test:
		if body.get_owner() != self && body.get_name() == ("Hitbox" + direction) && body.get_owner().is_attacking():
			attackers.append(body.get_owner())
	return attackers

func get_enemy_collisions():
	var collisions
	if hitBoxLeft.monitoring:
		collisions = hitBoxLeft.get_overlapping_bodies()
	elif hitBoxRight.monitoring:
		collisions = hitBoxRight.get_overlapping_bodies()
	else: collisions = []
	return collisions

func is_attacking():
	if currentState == self.ATTACKING:
		return true
	else:
		return false
		
func is_blocking():
	if currentState == self.BLOCKING:
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
