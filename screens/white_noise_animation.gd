extends CanvasLayer

@onready var texture_rect : TextureRect = $TextureRect
@onready var noise_texture : NoiseTexture2D = texture_rect.texture as NoiseTexture2D
@onready var noise : FastNoiseLite = noise_texture.noise

var _is_transitioning : bool = false

func _ready() -> void:
	randomize()
	_sync_to_viewport()
	get_viewport().size_changed.connect(_sync_to_viewport)
	texture_rect.hide()

func _process(_delta: float) -> void:
	if _is_transitioning:
		noise.seed = randi()

func start_transition() -> void:
	_is_transitioning = true
	texture_rect.show()

func stop_transition() -> void:
	_is_transitioning = false
	texture_rect.hide()

func _sync_to_viewport() -> void:
	var viewport_size : Vector2 = get_viewport().get_visible_rect().size
	noise_texture.width = maxi(int(ceil(viewport_size.x)), 1)
	noise_texture.height = maxi(int(ceil(viewport_size.y)), 1)
