extends "res://Scripts/Events/base_event.gd"

@export var Text: Control

@export var score_thres: float = 0.6
@export var score_amount: float = 0.6
@export var score_duration: float = 30
@export var update: bool = false

@onready var animator = $"Nice!"

var inside = false
var animationEnded = true

func _ready():
	Text.visible = false
	animator.connect("animation_finished", Callable(self, "on_animator_end"))
	set_physics_process(false)

func _physics_process(_delta):
	if not inside and animationEnded:
		animator.play("fall_out")
		animationEnded = false
		set_physics_process(false)
	elif inside and enter_body and enter_body.is_on_floor() and animationEnded:
		animator.play("drop_in")
		
		var player: Flyph = enter_body as Flyph
		if not player:
			print("ah shit")
			
		player.enable_glow()
		if player.get_glow_score() < score_thres:
			player.add_glow(score_amount)
			if update:
				player.force_glow_update()
			
		animationEnded = false
		set_physics_process(false)

func on_enter(_body):
	
	var player: Flyph = _body as Flyph
	if not player:
		print("ah shit")
		
	
	inside = true
	set_physics_process(true)

func on_exit(_body):
	inside = false
	set_physics_process(true)

func on_animator_end(animation: String):
	if animation == "fall_out" or animation == "drop_in":
		animationEnded = true





