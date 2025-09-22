extends Node

@onready var HUD: CanvasLayer = preload("res://UI/HUD.tscn").instantiate()

const SOLAR_SYSTEM_SCENE = preload("res://SolarSystem/SolarSystem.tscn")
var SolarSystemScene: SolarSystem = null

func _ready():
	initialize()
func initialize():
	add_child(HUD)

	SolarSystemScene = SOLAR_SYSTEM_SCENE.instantiate()
	add_child(SolarSystemScene)

func _exit_tree():
	if SolarSystemScene:
		SolarSystemScene.queue_free()
		SolarSystemScene = null
