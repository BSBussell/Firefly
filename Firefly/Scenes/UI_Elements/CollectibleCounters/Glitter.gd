extends CPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	_viewports.viewer.connect_to_res_changed(Callable(self, "resolution_update"))

func resolution_update():
	
	var parent: Control = get_parent()
	
	self.position.x = parent.size.x / 2
	self.position.y = parent.size.y / 3
	
	self.emission_rect_extents = self.position
	
	self.scale_amount_min = 0.5 * (self.position.x / 111)
	self.scale_amount_max = 1.0 * (self.position.x / 111)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
