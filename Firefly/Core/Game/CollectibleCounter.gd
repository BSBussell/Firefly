extends Node
class_name JarCounter

@onready var COUNTER: Label = $Label
@onready var COUNTER_ANIMATOR: AnimationPlayer = $AnimationPlayer
@onready var ANIMATION_TIMER: Timer = $HideTimer

var victory_screen: VictoryScreen
var COLLECTED: int = 0
var max: int = 100


var out: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	pass # Replace with function body.




func setup(result: VictoryScreen):
	
	max = 0
	
	var collectibles = get_tree().get_nodes_in_group("Collectible")
	for jar in collectibles:
		var error = jar.connect("collected", Callable(self, "jar_collected"))
		if error:
			print(error)
		else:
			max += 1
	
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
	
	if COLLECTED == max:
		victory_screen.show_Victory_Screen()
		
func peak_counter():
	show_counter()
	hide_counter()

func show_counter():
	if not out:
		COUNTER_ANIMATOR.play("Show")
		out = true

func hide_counter(time: float = 3.0):
	ANIMATION_TIMER.start(time)

func _on_hide_timer_timeout():
	out = false
	COUNTER_ANIMATOR.play("Hide")