extends Node2D

#@onready var collision_polygon_2d = $floor/CollisionPolygon2D
#@onready var polygon_2d = $floor/CollisionPolygon2D/Polygon2D
#
#
#@onready var collision_polygon_2d_roof = $ceiling/CollisionPolygon2D2
#@onready var polygon_2d_roof = $ceiling/CollisionPolygon2D2/Polygon2D
#
#@onready var light_occluder_2d_floor = $floor/CollisionPolygon2D/LightOccluder2D
#@onready var light_occluder_2d_ceil = $ceiling/CollisionPolygon2D2/LightOccluder2D
#
@onready var music = $Flyph/Music



func _ready():
	
	music.play(0)
	#polygon_2d.polygon = collision_polygon_2d.polygon
	#
	#polygon_2d_roof.polygon = collision_polygon_2d_roof.polygon
