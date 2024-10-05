extends UiComponent
class_name VictoryScreen

signal Show_Victory()
@onready var stats_label = $VBoxContainer/CenterContainer2/Stats

@onready var version_num = $Control/Label

var displayed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	self.visible = false
	
	var victory_function: Callable = Callable(self, "show_Victory_Screen")
	context.connect_to_win(victory_function)

	version_num.text = _meta.VERSION_NO


func _input(event):
	
	if Input.is_action_just_pressed("ui_accept") and self.visible:
		hide_Victory_Screen()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	pass	
	_logger.info("Result - Process")
	
	var display_time = _stats.get_timer_string()

	var found_jars: int = _jar_tracker.num_found_jars()

	stats_label.text = "Time: %s\n Jars Found: %d\n Total Deaths: %d" % [display_time, found_jars, _stats.DEATHS]

	_logger.info("Result - Process End")

func show_Victory_Screen():
	self.visible = true
	get_tree().paused = true

	# Update stats label
	var display_time = _stats.get_timer_string()
	var found_jars: int = _jar_tracker.num_found_jars()
	stats_label.text = "Time: %s\n Jars Found: %d\n Total Deaths: %d" % [display_time, found_jars, _stats.DEATHS]

	displayed = true

func hide_Victory_Screen():
	self.visible = false
	get_tree().paused = false  
	displayed = false
	
func connect_signal(sig: String):
	
	var error = connect(sig, Callable(self, "show_Victory_Screen"))
	if error != OK:
		print("Error Connecting Signal: ", error)
