extends Node

const MIX_RATE := 22050.0

var bed_player: AudioStreamPlayer
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var rng := RandomNumberGenerator.new()
var sample_clock := 0.0
var filtered_noise := 0.0
var next_call_time := 2.0
var call_started_at := -10.0
var call_frequency := 860.0


func _ready() -> void:
	rng.seed = 88173
	bed_player = AudioStreamPlayer.new()
	bed_player.name = "RainBasinBed"
	var bed_stream := load("res://assets/vesta_ambience.ogg") as AudioStreamOggVorbis
	if bed_stream:
		bed_stream.loop = true
		bed_player.stream = bed_stream
		bed_player.volume_db = -4.0
		add_child(bed_player)
		bed_player.play()

	player = AudioStreamPlayer.new()
	player.name = "DistantFaunaCalls"
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.8
	player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	player.stream = generator
	player.volume_db = -7.0
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if playback == null:
		playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
		if playback == null:
			return
	_fill_buffer(playback.get_frames_available())


func _fill_buffer(frame_count: int) -> void:
	for _frame in range(frame_count):
		var t := sample_clock / MIX_RATE
		if t >= next_call_time:
			call_started_at = t
			call_frequency = rng.randf_range(720.0, 1240.0)
			next_call_time = t + rng.randf_range(3.5, 9.0)

		filtered_noise = lerpf(filtered_noise, rng.randf_range(-1.0, 1.0), 0.004)
		var slow_wind := filtered_noise * (0.36 + sin(t * 0.19) * 0.08)
		var distant_drone := sin(TAU * 47.0 * t) * 0.055 + sin(TAU * 71.0 * t) * 0.026
		var water_tick := 0.0
		var droplet_phase := fmod(t * 0.37, 1.0)
		if droplet_phase < 0.007:
			water_tick = sin(TAU * 1650.0 * t) * (1.0 - droplet_phase / 0.007) * 0.045

		var animal_call := 0.0
		var call_age := t - call_started_at
		if call_age >= 0.0 and call_age < 0.72:
			var envelope := sin(PI * call_age / 0.72) ** 2
			var glide := call_frequency * (1.0 - call_age * 0.22)
			animal_call = sin(TAU * glide * t + sin(t * 19.0) * 1.8) * envelope * 0.075

		var sample := slow_wind + distant_drone + water_tick + animal_call
		var pan_drift := sin(t * 0.11) * 0.12
		playback.push_frame(Vector2(sample * (1.0 - pan_drift), sample * (1.0 + pan_drift)))
		sample_clock += 1.0
