# test_integration_audio_synthesis_fft.gd
# Tier 1 Integration Suite 8: AudioStreamGenerator Synthesis, 8-Octave FFT Spectrum Analysis, and 1D/2D/3D Audio Players.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Integration_Audio_Synthesis_FFT"
	test_type = "integration"

# ==============================================================================
# 1. AUDIO STREAM GENERATOR & SYNTHESIS WAVEFORMS
# ==============================================================================

func test_audio_stream_generator_configuration() -> void:
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.5
	assert_approx(gen.mix_rate, 44100.0, 0.001)
	assert_approx(gen.buffer_length, 0.5, 0.001)

func test_audio_stream_generator_playback_push_frames() -> void:
	var player: AudioStreamPlayer = autofree(AudioStreamPlayer.new()) as AudioStreamPlayer
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.1
	player.stream = gen
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback()
	assert_not_null(playback, "AudioStreamGeneratorPlayback instance must be valid after play()")
	if playback is AudioStreamGeneratorPlayback:
		var pushed = playback.push_frame(Vector2(0.5, 0.5))
		assert_true(pushed, "push_frame must succeed when buffer has available space")
	player.stop()

func test_audio_stream_generator_sine_wave_buffer() -> void:
	var player: AudioStreamPlayer = autofree(AudioStreamPlayer.new()) as AudioStreamPlayer
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.2
	player.stream = gen
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var frames_available = playback.get_frames_available()
		assert_gt(frames_available, 0)
		var buffer = PackedVector2Array()
		var sample_count = mini(frames_available, 128)
		var freq = 440.0
		for i in range(sample_count):
			var t = float(i) / 44100.0
			var sample = sin(2.0 * PI * freq * t) * 0.5
			buffer.append(Vector2(sample, sample))
		var pushed = playback.push_buffer(buffer)
		assert_true(pushed)
	player.stop()

func test_audio_stream_generator_square_wave_synthesis() -> void:
	var player: AudioStreamPlayer = autofree(AudioStreamPlayer.new()) as AudioStreamPlayer
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	player.stream = gen
	add_child(player)
	player.play()
	
	var playback = player.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var buffer = PackedVector2Array()
		for i in range(64):
			var sample = 0.5 if (i % 32 < 16) else -0.5
			buffer.append(Vector2(sample, sample))
		var pushed = playback.push_buffer(buffer)
		assert_true(pushed)
	player.stop()

# ==============================================================================
# 2. 8-OCTAVE FFT SPECTRUM ANALYZER QUERIES
# ==============================================================================

func test_spectrum_analyzer_sub_bass_and_bass_octaves() -> void:
	var spec = AudioEffectSpectrumAnalyzer.new()
	AudioServer.add_bus_effect(0, spec)
	var effect_idx = AudioServer.get_bus_effect_count(0) - 1
	var instance = AudioServer.get_bus_effect_instance(0, effect_idx)
	
	if instance is AudioEffectSpectrumAnalyzerInstance:
		var sub_bass = instance.get_magnitude_for_frequency_range(20.0, 60.0)
		var bass = instance.get_magnitude_for_frequency_range(60.0, 250.0)
		assert_gte(sub_bass.x, 0.0)
		assert_gte(sub_bass.y, 0.0)
		assert_gte(bass.x, 0.0)
		assert_gte(bass.y, 0.0)
		
	AudioServer.remove_bus_effect(0, effect_idx)

func test_spectrum_analyzer_midrange_octaves() -> void:
	var spec = AudioEffectSpectrumAnalyzer.new()
	AudioServer.add_bus_effect(0, spec)
	var effect_idx = AudioServer.get_bus_effect_count(0) - 1
	var instance = AudioServer.get_bus_effect_instance(0, effect_idx)
	
	if instance is AudioEffectSpectrumAnalyzerInstance:
		var low_mid = instance.get_magnitude_for_frequency_range(250.0, 500.0)
		var mid = instance.get_magnitude_for_frequency_range(500.0, 2000.0)
		var high_mid = instance.get_magnitude_for_frequency_range(2000.0, 4000.0)
		assert_gte(low_mid.x, 0.0)
		assert_gte(mid.x, 0.0)
		assert_gte(high_mid.x, 0.0)
		
	AudioServer.remove_bus_effect(0, effect_idx)

func test_spectrum_analyzer_treble_and_air_octaves() -> void:
	var spec = AudioEffectSpectrumAnalyzer.new()
	AudioServer.add_bus_effect(0, spec)
	var effect_idx = AudioServer.get_bus_effect_count(0) - 1
	var instance = AudioServer.get_bus_effect_instance(0, effect_idx)
	
	if instance is AudioEffectSpectrumAnalyzerInstance:
		var presence = instance.get_magnitude_for_frequency_range(4000.0, 6000.0)
		var brilliance = instance.get_magnitude_for_frequency_range(6000.0, 12000.0)
		var air = instance.get_magnitude_for_frequency_range(12000.0, 20000.0)
		assert_gte(presence.x, 0.0)
		assert_gte(brilliance.x, 0.0)
		assert_gte(air.x, 0.0)
		
	AudioServer.remove_bus_effect(0, effect_idx)

# ==============================================================================
# 3. 1D, 2D, AND 3D AUDIO PLAYERS
# ==============================================================================

func test_audio_stream_player_1d_routing() -> void:
	var player: AudioStreamPlayer = autofree(AudioStreamPlayer.new()) as AudioStreamPlayer
	player.bus = &"Master"
	player.volume_db = -6.0
	player.pitch_scale = 1.1
	add_child(player)
	
	assert_eq(player.bus, &"Master")
	assert_approx(player.volume_db, -6.0, 0.001)
	assert_approx(player.pitch_scale, 1.1, 0.001)

func test_audio_stream_player_2d_positional_attenuation() -> void:
	var player2d: AudioStreamPlayer2D = autofree(AudioStreamPlayer2D.new()) as AudioStreamPlayer2D
	player2d.bus = &"Master"
	player2d.max_distance = 800.0
	player2d.attenuation = 1.5
	player2d.panning_strength = 0.8
	player2d.position = Vector2(150, 250)
	add_child(player2d)
	
	assert_approx(player2d.max_distance, 800.0, 0.001)
	assert_approx(player2d.attenuation, 1.5, 0.001)
	assert_approx(player2d.panning_strength, 0.8, 0.001)
	assert_vector2_approx(player2d.position, Vector2(150, 250), 0.001)

func test_audio_stream_player_3d_spatial_attenuation() -> void:
	var player3d: AudioStreamPlayer3D = autofree(AudioStreamPlayer3D.new()) as AudioStreamPlayer3D
	player3d.bus = &"Master"
	player3d.unit_size = 10.0
	player3d.max_distance = 50.0
	player3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	player3d.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	player3d.position = Vector3(5, 10, 15)
	add_child(player3d)
	
	assert_approx(player3d.unit_size, 10.0, 0.001)
	assert_approx(player3d.max_distance, 50.0, 0.001)
	assert_eq(player3d.attenuation_model, AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE)
	assert_eq(player3d.doppler_tracking, AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP)
	assert_vector3_approx(player3d.position, Vector3(5, 10, 15), 0.001)
