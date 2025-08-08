extends Node2D

@export var gun_scene: PackedScene
@export var spawn_positions: Array[Node2D] = []

func _ready():
    $Timer.timeout.connect(spawn_gun)
    $Timer.start(2.0) # Spawn every 2 seconds

func spawn_gun():
    if !gun_scene or spawn_positions.is_empty():
        return

    var spawn_pos = spawn_positions.pick_random()

    # --- NEW: check if there's already a gun at this spawn position ---
    for child in get_parent().get_children():
        if child.scene_file_path == gun_scene.resource_path:
            if child.global_position.distance_to(spawn_pos.global_position) < 1.0:
                return  # a gun is already here, skip spawning

    var gun = gun_scene.instantiate()
    gun.global_position = spawn_pos.global_position
    get_parent().add_child(gun)
