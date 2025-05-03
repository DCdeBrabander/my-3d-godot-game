extends CanvasLayer

@onready var currently_selected_label: Label = $Control/CurrentSelectedLabel

func _ready() -> void:
	Signalbus.node_selected.connect(_on_node_selected)
	
func _on_node_selected(node: Node):
	if node is Planet: currently_selected_label.text = "Planet: " + node.planet_name
