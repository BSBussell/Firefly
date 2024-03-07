extends Node

var COUNTER: Label
var COUNTER_ANIMATOR: AnimationPlayer
var ANIMATION_TIMER: Timer
var DISPLAY_TIME: float

var Victory: ColorRect

var COLLECTED: int = 0
var MAX: int = 100


var out: bool = false

func connect_timer():
	
	DISPLAY_TIME = ANIMATION_TIMER.wait_time
	ANIMATION_TIMER.connect("timeout", Callable(self, "on_timeout"))
	

func new_item_found():
	
	COLLECTED += 1
	COUNTER.text = "%d/%d" % [COLLECTED, MAX]
	
	show_counter()
	
	if COLLECTED == MAX:
		show_Victory_Screen()
		

func show_Victory_Screen():
	Victory.visible = true
	get_tree().paused = true
	
	
	

func show_counter():
	if not out:
		COUNTER_ANIMATOR.play("Show")
		out = true
		ANIMATION_TIMER.start(DISPLAY_TIME)
	else: # Restart the time if its already out
		ANIMATION_TIMER.start(DISPLAY_TIME)

func set_max_collectibles(max: int):
	MAX = max

func on_timeout():
	print("y")
	out = false
	COUNTER_ANIMATOR.play("Hide")
