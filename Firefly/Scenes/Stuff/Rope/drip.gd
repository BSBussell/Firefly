extends CPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_finished():
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var random_dur: float = rng.randf_range(5,20)
	await get_tree().create_timer(random_dur).timeout
	emitting = true
