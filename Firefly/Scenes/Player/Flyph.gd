class_name Flyph
extends CharacterBody2D

@export_category("Movement Resource")
@export var movement_data : PlayerMovementData


@onready var animation = $AnimatedSprite2D
@onready var StateMachine = $StateMachine


# I'm Being really annoying about this btw
func _ready() -> void:
	
	# Initialize the State Machine pass self to it
	StateMachine.init(self)
	
func _unhandled_input(event: InputEvent) -> void:
	
	StateMachine.process_input(event)
	
func _physics_process(delta: float) -> void:
	
	StateMachine.process_physics(delta)
	
func _process(delta: float) -> void:
	
	StateMachine.process(delta)
