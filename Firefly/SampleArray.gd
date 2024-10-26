extends Node
class_name SampleArray


var max_elements: int
var elements: PackedFloat32Array = PackedFloat32Array()
var total: float = 0.0

func _init(max_elem: int):
	self.max_elements = max_elem

func add_element(element: float):
	
	var round_elem: float = snappedf(element, 0.01)
	
	if elements.size() >= max_elements:
		var old_element = elements[0]
		total -= old_element
		elements.remove_at(0)  # Remove the first element
	elements.push_back(round_elem)
	total += round_elem

func get_average() -> float:
	if elements.size() == 0:
		return 0.0  # Avoid division by zero
	return snappedf(total / elements.size(), 0.01)
	 
func get_elements() -> PackedFloat32Array:
	return elements

func get_pop() -> float:
	if elements.size() == 0:
		return 0.0  # Return 0.0 if there are no elements
	return elements[elements.size() - 1]
