extends Node2D

var selected_difficulty = "medium"

func set_difficulty(diff: String):
	selected_difficulty = diff

func _ready():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("set_difficulty"):
			enemy.set_difficulty(selected_difficulty)
