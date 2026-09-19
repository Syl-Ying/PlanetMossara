extends CanvasLayer

var stats_label: Label
var message_label: Label
var objective_label: Label
var journal_panel: ColorRect
var journal_label: Label
var message_time := 0.0
var discovery_timer := 0.0
var observations: Dictionary = {}

const OBSERVATION_TEXT := {
	"Glow Reed": "GLOW REED\nStores ambient energy and recovers after grazing.",
	"Burrow Grazer": "BURROW GRAZER\nFollows nutrient signals, but survival responses take priority.",
	"Veil Stalker": "VEIL STALKER\nTracks grazers and retreats from intense defensive light.",
}


func _ready() -> void:
	add_to_group("hud")
	_build_interface()


func _build_interface() -> void:
	var panel := ColorRect.new()
	panel.position = Vector2(18.0, 18.0)
	panel.size = Vector2(640.0, 86.0)
	panel.color = Color(0.02, 0.035, 0.045, 0.78)
	add_child(panel)

	stats_label = Label.new()
	stats_label.position = Vector2(34.0, 30.0)
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color("d8f5df"))
	add_child(stats_label)

	var help_label := Label.new()
	help_label.text = "WASD move   Mouse look   Q nutrient   E defensive light   Tab journal   Esc mouse"
	help_label.position = Vector2(34.0, 67.0)
	help_label.add_theme_font_size_override("font_size", 14)
	help_label.add_theme_color_override("font_color", Color("9fbeb6"))
	add_child(help_label)

	objective_label = Label.new()
	objective_label.position = Vector2(24.0, 116.0)
	objective_label.size = Vector2(790.0, 42.0)
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", Color("ffd88a"))
	add_child(objective_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(430.0, 620.0)
	message_label.size = Vector2(420.0, 40.0)
	message_label.add_theme_font_size_override("font_size", 21)
	message_label.add_theme_color_override("font_color", Color("ffe590"))
	add_child(message_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(633.0, 345.0)
	crosshair.add_theme_font_size_override("font_size", 22)
	crosshair.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9, 0.8))
	add_child(crosshair)

	journal_panel = ColorRect.new()
	journal_panel.position = Vector2(835.0, 22.0)
	journal_panel.size = Vector2(410.0, 420.0)
	journal_panel.color = Color(0.025, 0.045, 0.052, 0.94)
	journal_panel.visible = false
	add_child(journal_panel)

	var journal_title := Label.new()
	journal_title.text = "FIELD JOURNAL"
	journal_title.position = Vector2(24.0, 18.0)
	journal_title.add_theme_font_size_override("font_size", 24)
	journal_title.add_theme_color_override("font_color", Color("b7f1d0"))
	journal_panel.add_child(journal_title)

	journal_label = Label.new()
	journal_label.text = "Approach organisms to record observations."
	journal_label.position = Vector2(24.0, 62.0)
	journal_label.size = Vector2(360.0, 330.0)
	journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_label.add_theme_font_size_override("font_size", 16)
	journal_label.add_theme_color_override("font_color", Color("d1dfd9"))
	journal_panel.add_child(journal_label)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("journal"):
		journal_panel.visible = not journal_panel.visible

	var ecosystem := get_tree().get_first_node_in_group("ecosystem")
	if ecosystem and stats_label:
		var snapshot: Dictionary = ecosystem.get_snapshot()
		stats_label.text = "LIVING WORLD  |  Reeds %d   Grazers %d   Stalkers %d   Fleeing %d   Signals %d   Time %.1fs" % [
			snapshot["reeds"], snapshot["grazers"], snapshot["stalkers"],
			snapshot["fleeing"], snapshot["signals"], snapshot["seconds"]
		]
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.text = ""

	discovery_timer -= delta
	if discovery_timer <= 0.0:
		discovery_timer = 0.5
		_scan_observations(ecosystem)


func show_ecology_message(text: String) -> void:
	message_label.text = text
	message_time = 2.4


func set_objective(text: String) -> void:
	if objective_label:
		objective_label.text = "OBJECTIVE  •  " + text


func _scan_observations(ecosystem: Node) -> void:
	if ecosystem == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var nearby: Array[String] = ecosystem.discover_species_near(
		Vector2(player.global_position.x, player.global_position.z), 8.0
	)
	for species_name in nearby:
		if observations.has(species_name):
			continue
		observations[species_name] = true
		show_ecology_message("Journal updated: " + species_name)
	_update_journal_text()


func _update_journal_text() -> void:
	if observations.is_empty():
		journal_label.text = "Approach organisms to record observations."
		return
	var sections: Array[String] = []
	for species_name in ["Glow Reed", "Burrow Grazer", "Veil Stalker"]:
		if observations.has(species_name):
			sections.append(OBSERVATION_TEXT[species_name])
	journal_label.text = "\n\n".join(sections)
