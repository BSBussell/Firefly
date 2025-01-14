extends "res://Scripts/Events/base_event.gd"

@export var Text: Control
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
		
		var flyph: Flyph = _globals.ACTIVE_PLAYER
		var gem_manager: GemManager = _globals.GEM_MANAGER
		
		flyph.enable_glow()
		gem_manager.show_gems()
		
		animationEnded = false
		set_physics_process(false)

func on_enter(_body):
	inside = true
	set_physics_process(true)

func on_exit(_body):
	inside = false
	set_physics_process(true)

func on_animator_end(animation: String):
	if animation == "fall_out" or animation == "drop_in":
		animationEnded = true
