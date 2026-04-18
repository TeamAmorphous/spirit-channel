extends CanvasLayer

@onready var texture_rect : TextureRect = $TextureRect
@onready var noise : FastNoiseLite = texture_rect.texture.noise

var _is_transitioning : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _is_transitioning:
		noise.seed = randi()

func begin_transition_animation(duration: float = 1.0) -> Timer:
	_is_transitioning = true
	var timer : Timer = Timer.new()
	timer.start()
	return timer

func end_transition_animation() -> void:
	_is_transitioning = false
