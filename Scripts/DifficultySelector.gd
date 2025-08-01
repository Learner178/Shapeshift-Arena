extends Control

@onready var level_scene_path = "res://Scenes/Level.tscn"

func _ready():
    visible = true

func _on_easy_button_pressed():
    GameSettings.difficulty = GameSettings.Difficulty.EASY
    start_game()

func _on_medium_button_pressed():
    GameSettings.difficulty = GameSettings.Difficulty.MEDIUM
    start_game()

func _on_hard_button_pressed():
    GameSettings.difficulty = GameSettings.Difficulty.HARD
    start_game()

func _on_insane_button_pressed():
    GameSettings.difficulty = GameSettings.Difficulty.INSANE
    start_game()

func start_game():
    visible = false  # Hide the menu
    var level = preload("res://Scenes/level.tscn").instantiate()
    get_tree().get_root().add_child(level)
    level.global_position = Vector2(0, 0)  # Optional: Positioning
    queue_free()  # Remove the menu scene completely
