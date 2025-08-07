extends Node2D

@export var gun_scene: PackedScene
@export var spawn_positions: Array[Node2D] = []

func _ready():
    $Timer.timeout.connect(spawn_gun)
    $Timer.start(2.0) # Spawn every 2 seconds

func spawn_gun():
    if !gun_scene or spawn_positions.is_empty():
        return
    var gun = gun_scene.instantiate()
    var spawn_pos = spawn_positions.pick_random()
    gun.global_position = spawn_pos.global_position
    get_parent().add_child(gun)
