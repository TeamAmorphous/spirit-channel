@tool
class_name OSDProgressBar
extends VBoxContainer


var _value: int = 0
@export var max_value: int = 10:
	set = _set_max_value

@export var value: int = 5:
	set = _set_value,
	get = _get_value
@export_range(0.0, 1.0) var ratio: float = 0.5:
	set(r):
		_value = int(roundf(r * max_value))
		_set_segments()
	get:
		return float(_value) / float(max_value)

@export var label: String:
	set(text):
		label = text
		if _label:
			_label.text = label
@export var label_settings: LabelSettings:
	set(settings):
		label_settings = settings
		if _label:
			_label.label_settings = label_settings
		for s in _segments:
			s.color = label_settings.font_color
@export var segment_enabled_size: Vector2 = Vector2(5, 15):
	set(size):
		segment_enabled_size = size
		_set_segments()
@export var segment_disabled_size: Vector2 = Vector2(5, 5):
	set(size):
		segment_disabled_size = size
		_set_segments()
@export var segment_spacing: int = 4:
	set(spacing):
		segment_spacing = spacing
		_set_segments()


var _label: Label
var _container: HBoxContainer
var _segments: Array[ColorRect]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_build()


func _build() -> void:
	if _label:
		_label.queue_free()
		_label = null
	if _container:
		_container.queue_free()
		_container = null
	_segments.clear()

	_label = Label.new()
	_label.label_settings = label_settings
	_label.text = label
	_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_label)

	_container = HBoxContainer.new()
	add_child(_container)
	_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_container.alignment = BoxContainer.ALIGNMENT_CENTER

	_build_segments()
	_set_segments()


func _build_segments() -> void:
	if not _container:
		return
	
	# add to max size
	while _segments.size() < max_value:
		var seg := ColorRect.new()
		seg.color = label_settings.font_color
		seg.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER)
		seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_container.add_child(seg)
		_segments.append(seg)

	# remove extras
	while _segments.size() > max_value:
		_segments.pop_back().queue_free()
		

func _set_segments() -> void:
	if not _container:
		return
	
	_container.custom_minimum_size = segment_enabled_size
	_container.add_theme_constant_override("separation", segment_spacing)
	for i in _segments.size():
		var seg := _segments[i]
		seg.custom_minimum_size = segment_enabled_size if i < value else segment_disabled_size
		seg.size = seg.custom_minimum_size


func _set_max_value(amount: int) -> void:
	amount = maxi(amount, 1)
	if amount == max_value:
		return
	max_value = amount
	_build()
	value = clampi(amount, 0, max_value)


func _set_value(amount: int) -> void:
	_value = clampi(amount, 0, max_value)
	_set_segments()


func _get_value() -> int:
	return _value
