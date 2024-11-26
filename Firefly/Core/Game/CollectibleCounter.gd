extends UiComponent
class_name JarCounter

@export var COUNTER: Label 
@export var COUNTER_ANIMATOR: AnimationPlayer
@export var ANIMATION_TIMER: Timer

var COLLECTED: int = 0
var MAX: int = 100


var out: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	MAX = 0
	
	var collectibles = []
	collectibles = get_tree().get_nodes_in_group("FlyJar")
	for jar in collectibles:
		
		# Connecting our jar collected signals
		var error = jar.connect("collected", Callable(self, "jar_collected"))
		if error:
			print(error)
	
	MAX = _jar_tracker.num_known_jars(_globals.ACTIVE_LEVEL.id)
	COLLECTED = _jar_tracker.num_found_jars(_globals.ACTIVE_LEVEL.id)
	
	COUNTER.text = "%d/%d" % [COLLECTED, MAX]
	
	# Connect Blue Jars:
	collectibles = get_tree().get_nodes_in_group("BlueJar")
	for jar in collectibles:
		
		# Connecting our jar collected signals
		var error = jar.connect("collected", Callable(self, "jar_collected"))
		if error:
			print(error)
	
	pass # Replace with function body.



	
	


func jar_collected(_jar: FlyJar):
		
	MAX = _jar_tracker.num_known_jars(_globals.ACTIVE_LEVEL.id)
	COLLECTED = _jar_tracker.num_found_jars(_globals.ACTIVE_LEVEL.id)
	
	COUNTER.text = "%d/%d" % [COLLECTED, MAX]
	
	peak_counter()
	
		
func peak_counter():
	show_counter()
	hide_counter()

func show_counter():
	if not out:
		play_show()
		out = true

func hide_counter(time: float = 3.0):
	ANIMATION_TIMER.start(time)

func _on_hide_timer_timeout():
	out = false
	play_hide()

## Ensures that on animation playing we don't teleport pos
func play_show():
	
	var current_pos = COUNTER.anchor_left  
	COUNTER_ANIMATOR.get_animation("Show").track_set_key_value(0, 0, current_pos)
	COUNTER_ANIMATOR.play("Show")
	
## Ensures that on animation playing we don't teleport pos
func play_hide():
	var current_pos = COUNTER.anchor_left
	COUNTER_ANIMATOR.get_animation("Hide").track_set_key_value(0, 0, current_pos)
	COUNTER_ANIMATOR.play("Hide")
	
