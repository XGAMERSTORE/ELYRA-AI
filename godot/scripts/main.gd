extends Node3D

# ELYRA AI: Godot Android-first foundation.
# Replace primitive mannequin with licensed, rigged adult GLB/VRM character.
var avatar: Node3D
var camera: Camera3D
var chat_log: RichTextLabel
var chat_input: LineEdit
var animation_time := 0.0
var animation_mode := "idle"
var body_mesh: MeshInstance3D
var face_eyes: Array[Node3D] = []
var model_loaded := false
var walking := false
var walk_target := Vector3.ZERO
var move_speed := 1.45
var scene_height_fraction := 0.69
const CHARACTER_SCENE := "res://assets/characters/elyra.glb"
var voice_enabled := true
var adult_mode := false
var user_confirmed_adult := false
var companion_name := "Elyra"
var history: Array = []
const SAVE_PATH := "user://elyra.json"

func _ready() -> void:
	_load_state()
	_setup_world()
	_setup_ui()
	_show_history()

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

func _part(parent: Node3D, radius: float, height: float, position: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	part.mesh = capsule
	part.position = position
	part.material_override = _material(color)
	parent.add_child(part)
	return part

func _setup_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#171020")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e5caff")
	env.ambient_light_energy = 0.8
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -20, 0)
	light.light_energy = 1.5
	add_child(light)
	camera = Camera3D.new()
	camera.position = Vector3(0, 3.4, 6.7)
	add_child(camera)
	camera.look_at(Vector3(0, 1.0, -0.4))
	camera.current = true
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(8, 0.15, 8)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = -0.1
	floor_mesh.material_override = _material(Color("#352c41"))
	add_child(floor_mesh)
	var back := MeshInstance3D.new()
	var wall := BoxMesh.new()
	wall.size = Vector3(8, 4, 0.15)
	back.mesh = wall
	back.position = Vector3(0, 2, -3)
	back.material_override = _material(Color("#43304f"))
	add_child(back)
	# Simple 3D apartment furniture with real depth and lighting.
	_box(Vector3(-2.1, 0.35, -1.7), Vector3(2.0, 0.7, 0.9), Color("#685477"))
	_box(Vector3(-2.1, 0.78, -2.05), Vector3(2.0, 0.8, 0.22), Color("#796487"))
	_box(Vector3(1.8, 0.37, -1.8), Vector3(1.5, 0.74, 0.75), Color("#56475f"))
	_box(Vector3(1.8, 0.78, -1.8), Vector3(1.65, 0.09, 0.85), Color("#ac8d70"))
	_box(Vector3(0, 0.22, 1.8), Vector3(1.4, 0.4, 0.75), Color("#805f73"))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-2.5, 2.7, -1.5)
	lamp.light_color = Color("#ffd9af")
	lamp.light_energy = 1.8
	lamp.omni_range = 6.0
	add_child(lamp)
	avatar = Node3D.new()
	add_child(avatar)
	# Import a properly licensed rigged GLB as soon as it is added to the project.
	# The generated placeholder remains usable while the asset is unavailable.
	if ResourceLoader.exists(CHARACTER_SCENE):
		var packed = load(CHARACTER_SCENE)
		if packed is PackedScene:
			var character = packed.instantiate()
			if character is Node3D:
				avatar.add_child(character)
				model_loaded = true
	if model_loaded:
		return
	_part(avatar, 0.29, 0.55, Vector3(0, 2.13, 0), Color("#edb5a5"))
	_part(avatar, 0.36, 0.65, Vector3(0, 2.37, -0.12), Color("#34263d"))
	body_mesh = _part(avatar, 0.38, 1.0, Vector3(0, 1.42, 0), Color("#8e50b5"))
	_part(avatar, 0.12, 0.9, Vector3(-0.22, 0.51, 0), Color("#2c2441"))
	_part(avatar, 0.12, 0.9, Vector3(0.22, 0.51, 0), Color("#2c2441"))
	_part(avatar, 0.11, 0.85, Vector3(-0.49, 1.46, 0), Color("#edb5a5"))
	_part(avatar, 0.11, 0.85, Vector3(0.49, 1.46, 0), Color("#edb5a5"))
	# Basic facial features and layered hair, generated without external assets.
	var left_eye := _part(avatar, 0.034, 0.07, Vector3(-0.13, 2.18, 0.265), Color("#38263d"))
	var right_eye := _part(avatar, 0.034, 0.07, Vector3(0.13, 2.18, 0.265), Color("#38263d"))
	face_eyes.append(left_eye)
	face_eyes.append(right_eye)
	_part(avatar, 0.042, 0.055, Vector3(0, 2.01, 0.285), Color("#a75870"))
	_part(avatar, 0.15, 1.10, Vector3(-0.29, 1.98, -0.11), Color("#32213b"))
	_part(avatar, 0.15, 1.10, Vector3(0.29, 1.98, -0.11), Color("#32213b"))

func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = pos
	mesh.material_override = _material(color)
	add_child(mesh)

func _unhandled_input(event: InputEvent) -> void:
	# Tap empty 3D floor to move Elyra; ignore the chat/control area.
	var point := Vector2(-1, -1)
	if event is InputEventScreenTouch and event.pressed:
		point = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
	if point.x < 0 or point.y > get_viewport().get_visible_rect().size.y * scene_height_fraction:
		return
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	var ground := Plane(Vector3.UP, 0.0)
	var intersection = ground.intersects_ray(origin, direction)
	if intersection is Vector3:
		walk_target = Vector3(clampf(intersection.x, -3.3, 3.3), 0.0, clampf(intersection.z, -2.4, 3.2))
		walking = true
		animation_mode = "walk"

func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 76
	top.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.055, 0.13, 0.92)))
	root.add_child(top)
	var title := Label.new()
	title.text = "ELYRA  •  DOMOV"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_top = -355
	bottom.offset_bottom = 0
	bottom.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.065, 0.15, 0.96)))
	root.add_child(bottom)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	bottom.add_child(layout)
	var hint := Label.new()
	hint.text = "Klepni do místnosti a Elyra se přesune"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	layout.add_child(hint)
	# Horizontal action bar stays usable on narrow phone screens.
	var action_scroll := ScrollContainer.new()
	action_scroll.custom_minimum_size.y = 54
	action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	action_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(action_scroll)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	action_scroll.add_child(buttons)
	for action in ["Zamávat", "Tanec", "Objetí", "Polibek", "Oblečení", "18+"]:
		var button := Button.new()
		button.text = action
		button.custom_minimum_size = Vector2(112, 46)
		button.add_theme_font_size_override("font_size", 17)
		buttons.add_child(button)
		button.pressed.connect(_action.bind(action))
	chat_log = RichTextLabel.new()
	chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_log.scroll_following = true
	chat_log.bbcode_enabled = false
	chat_log.add_theme_font_size_override("normal_font_size", 17)
	layout.add_child(chat_log)
	var input_row := HBoxContainer.new()
	layout.add_child(input_row)
	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Napiš Elyře..."
	chat_input.custom_minimum_size.y = 54
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_row.add_child(chat_input)
	chat_input.text_submitted.connect(_send)
	var send_button := Button.new()
	send_button.text = "➤"
	send_button.custom_minimum_size = Vector2(65, 54)
	send_button.pressed.connect(func(): _send(chat_input.text))
	input_row.add_child(send_button)

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _action(action: String) -> void:
	match action:
		"Zamávat": animation_mode = "wave"
		"Tanec": animation_mode = "dance"
		"Objetí": animation_mode = "hug"
		"Polibek": animation_mode = "kiss"
		"Oblečení":
			if body_mesh != null:
				var material := body_mesh.material_override as StandardMaterial3D
				material.albedo_color = Color.from_hsv(randf(), 0.55, 0.8)
			else:
				_append("Systém", "Oblečení importovaného modelu se nastavuje přes jeho materiály.")
		"18+":
			if not user_confirmed_adult:
				_show_adult_confirmation()
				return
			adult_mode = not adult_mode
			_append("Systém", "Romantický režim: " + ("zapnutý" if adult_mode else "vypnutý"))
			_save_state()
	if action != "18+":
		animation_time = 0.0

func _show_adult_confirmation() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Potvrzení věku"
	dialog.dialog_text = "Potvrzuješ, že je ti alespoň 18 let? Tento prototyp neobsahuje explicitní animace."
	add_child(dialog)
	dialog.confirmed.connect(func():
		user_confirmed_adult = true
		adult_mode = true
		_append("Systém", "Romantický režim zapnut.")
		_save_state()
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered()

func _process(delta: float) -> void:
	animation_time += delta
	if avatar == null:
		return
	if walking:
		var offset := Vector3(walk_target.x - avatar.position.x, 0.0, walk_target.z - avatar.position.z)
		if offset.length() < 0.08:
			walking = false
			animation_mode = "idle"
		else:
			var step := offset.normalized() * minf(move_speed * delta, offset.length())
			avatar.position.x += step.x
			avatar.position.z += step.z
			avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(-offset.x, -offset.z), delta * 6.0)
	avatar.position.y = sin(animation_time * (8.0 if walking else 2.0)) * (0.055 if walking else 0.025)
	# Subtle periodic eye blink on the procedural fallback avatar.
	var blink := absf(sin(animation_time * 0.72))
	var eye_scale := 0.12 if blink > 0.993 else 1.0
	for eye in face_eyes:
		eye.scale.y = eye_scale
	match animation_mode:
		"dance":
			avatar.rotation.z = sin(animation_time * 5.0) * 0.12
		"wave":
			avatar.rotation.z = sin(animation_time * 7.0) * 0.06
		"hug":
			avatar.position.z = 0.3
		"kiss":
			avatar.rotation.x = -0.12
		_:
			avatar.rotation = avatar.rotation.lerp(Vector3.ZERO, delta * 4.0)
	if animation_time > 3.0 and not walking:
		animation_mode = "idle"
		if not walking:
			avatar.position.z = lerpf(avatar.position.z, 0.0, delta * 4.0)

func _send(text: String) -> void:
	var clean := text.strip_edges().substr(0, 500)
	if clean.is_empty():
		return
	chat_input.clear()
	_append("Ty", clean)
	var replies := ["Povíš mi o tom víc? ♥", "Ráda si s tebou povídám.", "Co bys chtěl dnes podniknout?"]
	if adult_mode:
		replies = ["Ráda s tebou flirtuju. ♥", "Představ si společný tanec při svíčkách.", "To zní romanticky. ♥"]
	_append(companion_name, replies.pick_random())
	_save_state()

func _append(who: String, message: String) -> void:
	history.append({"who": who, "message": message})
	if history.size() > 100:
		history.pop_front()
	chat_log.append_text(who + ": " + message + "\n")

func _show_history() -> void:
	if history.is_empty():
		_append(companion_name, "Ahoj! ♥ Vítej v mém virtuálním bytě.")
		_save_state()
	else:
		for entry in history:
			chat_log.append_text(str(entry.get("who", "")) + ": " + str(entry.get("message", "")) + "\n")

func _save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"history": history, "adult": adult_mode, "confirmed": user_confirmed_adult, "name": companion_name}))

func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		var stored_history = data.get("history", [])
		if stored_history is Array:
			history = stored_history
		user_confirmed_adult = data.get("confirmed", false)
		adult_mode = data.get("adult", false) and user_confirmed_adult
		companion_name = str(data.get("name", "Elyra"))
