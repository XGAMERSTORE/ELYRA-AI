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
	camera.position = Vector3(0, 1.6, 4.5)
	add_child(camera)
	camera.look_at(Vector3(0, 1.25, 0))
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
	avatar = Node3D.new()
	add_child(avatar)
	_part(avatar, 0.29, 0.55, Vector3(0, 2.13, 0), Color("#edb5a5"))
	_part(avatar, 0.36, 0.65, Vector3(0, 2.37, -0.12), Color("#34263d"))
	body_mesh = _part(avatar, 0.38, 1.0, Vector3(0, 1.42, 0), Color("#8e50b5"))
	_part(avatar, 0.12, 0.9, Vector3(-0.22, 0.51, 0), Color("#2c2441"))
	_part(avatar, 0.12, 0.9, Vector3(0.22, 0.51, 0), Color("#2c2441"))
	_part(avatar, 0.11, 0.85, Vector3(-0.49, 1.46, 0), Color("#edb5a5"))
	_part(avatar, 0.11, 0.85, Vector3(0.49, 1.46, 0), Color("#edb5a5"))
	# Basic facial features and layered hair, generated without external assets.
	_part(avatar, 0.034, 0.07, Vector3(-0.13, 2.18, 0.265), Color("#38263d"))
	_part(avatar, 0.034, 0.07, Vector3(0.13, 2.18, 0.265), Color("#38263d"))
	_part(avatar, 0.042, 0.055, Vector3(0, 2.01, 0.285), Color("#a75870"))
	_part(avatar, 0.15, 1.10, Vector3(-0.29, 1.98, -0.11), Color("#32213b"))
	_part(avatar, 0.15, 1.10, Vector3(0.29, 1.98, -0.11), Color("#32213b"))

func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 8)
	root.add_child(layout)
	var heading := Label.new()
	heading.text = "♥ ELYRA AI  |  Godot 3D"
	heading.add_theme_font_size_override("font_size", 30)
	layout.add_child(heading)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(gap)
	var buttons := HFlowContainer.new()
	layout.add_child(buttons)
	for action in ["Zamávat", "Tanec", "Objetí", "Polibek", "Oblečení", "18+"]:
		var b := Button.new()
		b.text = action
		buttons.add_child(b)
		b.pressed.connect(_action.bind(action))
	chat_log = RichTextLabel.new()
	chat_log.custom_minimum_size.y = 270
	chat_log.bbcode_enabled = false
	layout.add_child(chat_log)
	var input_row := HBoxContainer.new()
	layout.add_child(input_row)
	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Napiš Elyře..."
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_row.add_child(chat_input)
	chat_input.text_submitted.connect(_send)
	var send_button := Button.new()
	send_button.text = "Odeslat"
	send_button.pressed.connect(func(): _send(chat_input.text))
	input_row.add_child(send_button)

func _action(action: String) -> void:
	match action:
		"Zamávat": animation_mode = "wave"
		"Tanec": animation_mode = "dance"
		"Objetí": animation_mode = "hug"
		"Polibek": animation_mode = "kiss"
		"Oblečení":
			var material := body_mesh.material_override as StandardMaterial3D
			material.albedo_color = Color.from_hsv(randf(), 0.55, 0.8)
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
	avatar.position.y = sin(animation_time * 2.0) * 0.025
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
	if animation_time > 3.0:
		animation_mode = "idle"
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
		history = data.get("history", [])
		user_confirmed_adult = data.get("confirmed", false)
		adult_mode = data.get("adult", false) and user_confirmed_adult
		companion_name = str(data.get("name", "Elyra"))
