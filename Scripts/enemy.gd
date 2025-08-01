extends RigidBody2D

@export var base_torque_force: float = 17500.0
@export var base_jump_force: float = 250.0

@onready var ground_check: Node2D = $GroundCheck 
@onready var ray_ground: RayCast2D = $GroundCheck/RayCastGround
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var shapeshift_timer: Timer = $ShapeShiftTimer
@onready var decision_timer: Timer = $DecisionTimer  # Add this in your enemy scene!

var shapes = ["circle", "square", "capsule", "triangle", "rocket", "magnet", "hexagon"]
var current_shape = ""
var target: Node2D = null
var all_targets: Array = []
var move_dir := 0
var decision_delay := 0.5

func _ready():
	sleeping = false
	randomize()
	shapeshift()
	start_shapeshift_timer()
	set_difficulty_logic()
	decision_timer.wait_time = decision_delay
	decision_timer.timeout.connect(_on_decision_timer_timeout)
	decision_timer.start()

func _physics_process(delta: float) -> void:
	ground_check.rotation = -rotation

	if not target:
		return

	if move_dir != 0:
		apply_torque_impulse(move_dir * base_torque_force * delta)

	if should_jump():
		var impulse = Vector2(0, -base_jump_force)
		if current_shape == "rocket":
			impulse *= delta
		apply_central_impulse(impulse)

func set_difficulty_logic():
	match GameSettings.difficulty:
		GameSettings.Difficulty.EASY:
			decision_delay = 1.2
		GameSettings.Difficulty.MEDIUM:
			decision_delay = 0.8
		GameSettings.Difficulty.HARD:
			decision_delay = 0.5
		GameSettings.Difficulty.INSANE:
			decision_delay = 0.3
		_:
			decision_delay = 0.8

func _on_decision_timer_timeout():
	update_target()

	if not target:
		move_dir = 0
		return

	var dx = target.global_position.x - global_position.x
	var dy = target.global_position.y - global_position.y

	match GameSettings.difficulty:
		GameSettings.Difficulty.EASY:
			move_dir = sign(dx) if abs(dx) < 250 else 0
		GameSettings.Difficulty.MEDIUM:
			move_dir = sign(dx) if abs(dx) < 400 else 0
		GameSettings.Difficulty.HARD:
			move_dir = sign(dx)
			if ray_ground.is_colliding() and abs(dx) < 50 and randf() < 0.4:
				move_dir = 0  # brief pause before attacking
		GameSettings.Difficulty.INSANE:
			move_dir = sign(dx)
			# Predictive dodge / engage
			if abs(dx) < 100 and dy < 0 and randf() < 0.3:
				move_dir *= -1  # quick backstep before attacking
		_:
			move_dir = sign(dx)

	decision_timer.wait_time = decision_delay
	decision_timer.start()

func should_jump() -> bool:
	if not ray_ground.is_colliding():
		return false

	var dy = target.global_position.y - global_position.y
	match GameSettings.difficulty:
		GameSettings.Difficulty.EASY:
			return randf() < 0.1
		GameSettings.Difficulty.MEDIUM:
			return randf() < 0.3 or dy < -30
		GameSettings.Difficulty.HARD:
			return randf() < 0.5 or dy < -50
		GameSettings.Difficulty.INSANE:
			return randf() < 0.9 or (dy < -50 and abs(target.global_position.x - global_position.x) < 100)
	return false

func update_target():
	all_targets = get_tree().get_nodes_in_group("players")
	if all_targets.size() == 0:
		target = null
		return

	var closest = all_targets[0]
	var closest_dist = global_position.distance_squared_to(closest.global_position)
	for player in all_targets:
		var dist = global_position.distance_squared_to(player.global_position)
		if dist < closest_dist:
			closest = player
			closest_dist = dist
	target = closest

# All your shapeshift and timer code remains the same:

func shapeshift():
	var selected = shapes.pick_random()
	current_shape = selected

	match selected:
		"circle":
			shape.shape = CircleShape2D.new()
			sprite.texture = preload("res://Assets/football.png")
			sprite.scale = Vector2(0.025, 0.025)
			sprite.rotation_degrees = 0
			self.physics_material_override = create_physics_material(0.6, 0.3)
		"square":
			shape.shape = RectangleShape2D.new()
			shape.shape.extents = Vector2(10, 10)
			sprite.texture = preload("res://Assets/square.png")
			sprite.scale = Vector2(0.08, 0.08)
			sprite.rotation_degrees = 0
			self.physics_material_override = create_physics_material(0.6, 0.1)
		"capsule":
			shape.shape = CapsuleShape2D.new()
			sprite.texture = preload("res://Assets/american-football.png")
			sprite.scale = Vector2(0.02, 0.02)
			sprite.rotation_degrees = 90
			self.physics_material_override = create_physics_material(0.5, 0.3)
		"triangle":
			shape.shape = ConvexPolygonShape2D.new()
			shape.shape.points = [Vector2(-10, 10), Vector2(0, -10), Vector2(10, 10)]
			sprite.texture = preload("res://Assets/triangle.png")
			sprite.scale = Vector2(0.03, 0.03)
			sprite.rotation_degrees = 0
			self.physics_material_override = create_physics_material(0.5, 0.2)
		"rocket":
			shape.shape = RectangleShape2D.new()
			shape.shape.extents = Vector2(8, 16)
			sprite.texture = preload("res://Assets/rocket.png")
			sprite.scale = Vector2(0.05, 0.05)
			sprite.rotation_degrees = 0
			self.physics_material_override = create_physics_material(0.6, 0.2)
			
		"hexagon":
			var hex = ConvexPolygonShape2D.new()
			var size = 12.0
			hex.points = [
				Vector2(size * cos(deg_to_rad(0)), size * sin(deg_to_rad(0))),
				Vector2(size * cos(deg_to_rad(60)), size * sin(deg_to_rad(60))),
				Vector2(size * cos(deg_to_rad(120)), size * sin(deg_to_rad(120))),
				Vector2(size * cos(deg_to_rad(180)), size * sin(deg_to_rad(180))),
				Vector2(size * cos(deg_to_rad(240)), size * sin(deg_to_rad(240))),
				Vector2(size * cos(deg_to_rad(300)), size * sin(deg_to_rad(300)))
			]
			shape.shape = hex
			sprite.texture = preload("res://Assets/hexagon.png")
			sprite.scale = Vector2(0.05, 0.05)
			sprite.rotation_degrees = 30
			self.physics_material_override = create_physics_material(0.6, 0.2)
		"magnet":
			shape.shape = CircleShape2D.new()
			sprite.texture = preload("res://Assets/magnet.png")
			sprite.scale = Vector2(0.03, 0.03)
			self.physics_material_override = create_physics_material(0.75, 0.1)

func create_physics_material(friction: float, bounce: float) -> PhysicsMaterial:
	var mat = PhysicsMaterial.new()
	mat.friction = friction
	mat.bounce = bounce
	return mat

func start_shapeshift_timer():
	shapeshift_timer.wait_time = 5.0
	shapeshift_timer.start()

func _on_shape_shift_timer_timeout() -> void:
	shapeshift()
	start_shapeshift_timer()
