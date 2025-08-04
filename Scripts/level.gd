extends Node2D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var total_players := 1
@export var total_enemies := 1

var selected_difficulty = "medium"

func set_difficulty(diff: String):
    selected_difficulty = diff

func _ready():
    spawn_players_and_enemies()
    
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy.has_method("set_difficulty"):
            enemy.set_difficulty(selected_difficulty)

func spawn_players_and_enemies():
    var spawn_markers := $SpawnPoints.get_children()
    spawn_markers.shuffle()

    var spawned = 0

    for i in range(total_players):
        if spawned >= spawn_markers.size():
            break
        var player = player_scene.instantiate()
        player.position = spawn_markers[spawned].global_position
        add_child(player)
        spawned += 1

    for i in range(total_enemies):
        if spawned >= spawn_markers.size():
            break
        var enemy = enemy_scene.instantiate()
        enemy.position = spawn_markers[spawned].global_position
        add_child(enemy)
        spawned += 1
