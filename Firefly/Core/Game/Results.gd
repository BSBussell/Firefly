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
	
	_logger.info("Result - Process")
	
	if not get_tree().paused:
		_stats.TIME += delta

	var minutes: int = int(_stats.TIME) / 60
	var seconds: int = int(_stats.TIME) % 60
	var milliseconds: int = int((_stats.TIME - int(_stats.TIME)) * 1000)

	var display_time = "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

	stats_label.text = "Time: %s\n Total Deaths: %d" % [display_time, _stats.DEATHS]

	_logger.info("Result - Process End")

func show_Victory_Screen():
	self.visible = true
	get_tree().paused = true
	displayed = true

func hide_Victory_Screen():
	self.visible = false
	get_tree().paused = false
	displayed = false
	
func connect_signal(sig: String):
	
	var error = connect(sig, Callable(self, "show_Victory_Screen"))
	if error != OK:
		print("Error Connecting Signal: ", error)
