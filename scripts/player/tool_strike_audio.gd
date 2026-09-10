class_name ToolStrikeAudio
extends AudioStreamPlayer

const STRIKE_INTERVAL := 0.5
var cooldown_remaining := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	stream = preload("res://assets/Sounds/Action/pickaxestrike.mp3").duplicate()
	stream.loop = false
	max_polyphony = 1
	volume_db = -8.0

func _process(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)

func try_play_strike(material_tags: Array, tool_stack: Resource) -> bool:
	if cooldown_remaining > 0.0 or &"stone" not in material_tags or tool_stack == null:
		return false
	var profile: Resource = tool_stack.item_definition.tool_profile
	if profile == null or &"pickaxe" not in profile.capability_tags:
		return false
	cooldown_remaining = STRIKE_INTERVAL
	play()
	return true
