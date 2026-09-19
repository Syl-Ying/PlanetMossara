extends CanvasLayer

const OBSERVATION_TEXT := {
	"Spore Tree": "SPORE TREE\nThe translucent chambers open and close with the weather. Pigoids carry its spores without appearing to notice.",
	"Pigoid": "PIGOID\nA quiet six-limbed grazer. Its sensory filaments follow nutrient traces before sight or sound.",
	"Sterq Serpent": "STERQ SERPENT\nIts lateral veils read pressure changes in the basin. It hunts rarely and rests for long intervals.",
}

var intro: Control
var intro_time := 7.0
var hint_label: Label
var hint_time := 13.0
var message_label: Label
var message_time := 0.0
var journal_panel: ColorRect
var journal_label: Label
var discovery_timer := 0.0
var observations: Dictionary = {}


func _ready() -> void:
	add_to_group("hud")
	_build_intro()
	_build_interface()


func _build_intro() -> void:
	intro = Control.new()
	intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(intro)

	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = load("res://assets/vesta_quiet_basin.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	intro.add_child(art)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.035, 0.045, 0.18)
	intro.add_child(shade)

	var title := Label.new()
	title.text = "SCAVENGERS REIGN\nVESTA — A QUIET WALK"
	title.position = Vector2(58.0, 55.0)
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color("f0eee5"))
	intro.add_child(title)

	var invitation := Label.new()
	invitation.text = "There is nothing to complete.\nWalk slowly. Watch what the world does without you.\n\npress any key"
	invitation.position = Vector2(62.0, 565.0)
	invitation.add_theme_font_size_override("font_size", 17)
	invitation.add_theme_color_override("font_color", Color(0.92, 0.91, 0.86, 0.88))
	intro.add_child(invitation)


func _build_interface() -> void:
	var location_label := Label.new()
	location_label.text = "VESTA MINOR  /  RAIN BASIN 03"
	location_label.position = Vector2(24.0, 20.0)
	location_label.add_theme_font_size_override("font_size", 13)
	location_label.add_theme_color_override("font_color", Color(0.88, 0.89, 0.85, 0.72))
	add_child(location_label)

	hint_label = Label.new()
	hint_label.text = "WASD  walk    mouse  look    Q  scent trace    E  soft pulse    Tab  observations"
	hint_label.position = Vector2(24.0, 682.0)
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.84, 0.68))
	add_child(hint_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(390.0, 626.0)
	message_label.size = Vector2(500.0, 32.0)
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color("e7d4b7"))
	add_child(message_label)

	journal_panel = ColorRect.new()
	journal_panel.position = Vector2(790.0, 34.0)
	journal_panel.size = Vector2(450.0, 560.0)
	journal_panel.color = Color(0.10, 0.11, 0.13, 0.91)
	journal_panel.visible = false
	add_child(journal_panel)

	var journal_title := Label.new()
	journal_title.text = "OBSERVATIONS / NO CONCLUSIONS"
	journal_title.position = Vector2(28.0, 24.0)
	journal_title.add_theme_font_size_override("font_size", 18)
	journal_title.add_theme_color_override("font_color", Color("d8d4c9"))
	journal_panel.add_child(journal_title)

	journal_label = Label.new()
	journal_label.text = "Spend time near another organism.\nThe field notes will fill themselves."
	journal_label.position = Vector2(28.0, 72.0)
	journal_label.size = Vector2(392.0, 455.0)
	journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_label.add_theme_font_size_override("font_size", 15)
	journal_label.add_theme_color_override("font_color", Color("c8c7c0"))
	journal_panel.add_child(journal_label)


func _unhandled_input(event: InputEvent) -> void:
	if intro and intro.visible and (event is InputEventKey or event is InputEventMouseButton):
		intro.visible = false
		intro_time = 0.0


func _process(delta: float) -> void:
	if intro and intro.visible:
		intro_time -= delta
		if intro_time <= 1.5:
			intro.modulate.a = maxf(0.0, intro_time / 1.5)
		if intro_time <= 0.0:
			intro.visible = false

	if Input.is_action_just_pressed("journal"):
		journal_panel.visible = not journal_panel.visible

	hint_time -= delta
	if hint_time < 4.0:
		hint_label.modulate.a = clampf(hint_time / 4.0, 0.0, 1.0)
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.text = ""

	discovery_timer -= delta
	if discovery_timer <= 0.0:
		discovery_timer = 0.75
		_scan_observations(get_tree().get_first_node_in_group("ecosystem"))


func show_ecology_message(text: String) -> void:
	message_label.text = text
	message_time = 2.8


func _scan_observations(ecosystem: Node) -> void:
	if ecosystem == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var nearby: Array[String] = ecosystem.discover_species_near(
		Vector2(player.global_position.x, player.global_position.z), 7.0
	)
	for species_name in nearby:
		if observations.has(species_name):
			continue
		observations[species_name] = true
		show_ecology_message(species_name + " observed")
	_update_journal_text()


func _update_journal_text() -> void:
	if observations.is_empty():
		journal_label.text = "Spend time near another organism.\nThe field notes will fill themselves."
		return
	var sections: Array[String] = []
	for species_name in ["Spore Tree", "Pigoid", "Sterq Serpent"]:
		if observations.has(species_name):
			sections.append(OBSERVATION_TEXT[species_name])
	journal_label.text = "\n\n".join(sections)
