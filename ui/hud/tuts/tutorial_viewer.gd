class_name TutorialViewer
extends Control


@onready var pages: Array[TutorialPage] = [
	$Pages/RatKing,
	$Pages/Marco,
	$Pages/PizzaBoy,
	$Pages/Liberty,
]
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var open := false
var hovered_page: int = -1
var page_active := false


func show_pages() -> void:
	show()
	get_tree().paused = true
	anim_player.play(&"show")
	anim_player.animation_finished.connect(
		func(_n):
			open = true,
		Node.CONNECT_ONE_SHOT
	)


func hide_pages() -> void:
	anim_player.play(&"hide")
	open = false
	anim_player.animation_finished.connect(
		func(_n):
			hide()
			get_tree().paused = false,
		Node.CONNECT_ONE_SHOT
	)


func select_page(index: int) -> void:
	hovered_page = index
	for i in pages.size():
		pages[i].set_state(TutorialPage.PageState.HOVERED if i == hovered_page else TutorialPage.PageState.IDLE)
	page_active = false


func activate_current_page() -> void:
	if hovered_page >= 0:
		for i in pages.size():
			pages[i].set_state(TutorialPage.PageState.ACTIVE if i == hovered_page else TutorialPage.PageState.IDLE)
		page_active = true


func _process(_delta: float) -> void:
	if not open:
		return
	
	if Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"ui_accept"):
		activate_current_page()
	elif Input.is_action_just_pressed(&"move_left") or Input.is_action_just_pressed(&"ui_left"):
		select_page(wrapi(hovered_page - 1, 0, pages.size()))
	elif Input.is_action_just_pressed(&"move_right") or Input.is_action_just_pressed(&"ui_right"):
		select_page(wrapi(hovered_page + 1, 0, pages.size()))
	elif Input.is_action_just_pressed(&"tutorial") or Input.is_action_just_pressed(&"ui_cancel"):
		if hovered_page >= 0 and page_active:
			select_page(hovered_page)
		else:
			hide_pages()


func _on_page_mouse_entered(page: TutorialPage) -> void:
	select_page(pages.find(page))


func _on_page_mouse_exited(page: TutorialPage) -> void:
	if hovered_page == pages.find(page):
		select_page(-1)

