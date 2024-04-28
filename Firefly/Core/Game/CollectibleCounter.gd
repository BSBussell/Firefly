extends Node
class_name JarCounter

@export var COUNTER: Label 
@export var COUNTER_ANIMATOR: AnimationPlayer
@export var ANIMATION_TIMER: Timer

var victory_screen: VictoryScreen
var COLLECTED: int = 0
var max: int = 100


var out: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	pass # Replace with function body.




func setup(result: VictoryScreen):
	
	max = 0
	
	var collectibles = []
	collectibles = get_tree().get_nodes_in_group("Collectible")
	for jar in collectibles:
		
		# Connecting our jar collected signals
		var error = jar.connect("collected", Callable(self, "jar_collected"))
		if error:
			print(error)
	
	max = collectibles.size()
	print("Max:", max)
	COLLECTED = 0
	
	COUNTER.text = "%d/%d" % [COLLECTED, max]
	victory_screen = result

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func jar_collected(jar: FlyJar):
	
	#print("Boom Im a genius")
	
	COLLECTED += 1
	COUNTER.text = "%d/%d" % [COLLECTED, max]
	
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
	
	var current_pos = COUNTER.offset_right  # Assuming you're animating this property
	COUNTER_ANIMATOR.get_animation("Show").track_set_key_value(0, 0, current_pos)
	COUNTER_ANIMATOR.play("Show")
	
## Ensures that on animation playing we don't teleport pos
func play_hide():
	var current_pos = COUNTER.offset_right  # Assuming you're animating this property
	COUNTER_ANIMATOR.get_animation("Hide").track_set_key_value(0, 0, current_pos)
	COUNTER_ANIMATOR.play("Hide")
	
