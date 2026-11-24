# test_negative_audio_dsp.gd
# Tier 1 Negative Boundary Suite: linear_to_db Epsilon Clamping, Bus OOB, Filter Cutoffs, Pitch 0 & EQ Bands.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Negative_Audio_DSP"
	test_type = "integration"

# ==============================================================================
# 1. LINEAR_TO_DB ZERO AND EPSILON CLAMPING
# ==============================================================================

func test_linear_to_db_zero_and_epsilon_clamping() -> void:
	# Raw linear_to_db(0.0) yields -INF in standard IEEE 754 math
	var raw_zero_db: float = linear_to_db(0.0)
	assert_true(is_inf(raw_zero_db) and raw_zero_db < 0.0, "linear_to_db(0.0) must return -INF")
	
	# Epsilon clamping at 1e-6 guarantees a finite, well-behaved -120 dB floor
	var clamped_zero_db: float = linear_to_db(maxf(1e-6, 0.0))
	assert_approx(clamped_zero_db, -120.0, 0.1, "Clamped zero linear_to_db must be -120.0 dB")
	assert_false(is_inf(clamped_zero_db), "Clamped zero must not be infinite")
	assert_false(is_nan(clamped_zero_db), "Clamped zero must not be NaN")
	
	# Negative linear inputs clamped cleanly to 1e-6 floor
	var clamped_neg_db: float = linear_to_db(maxf(1e-6, -50.0))
	assert_approx(clamped_neg_db, -120.0, 0.1, "Negative input clamped to -120.0 dB")
	
	# Roundtrip test with standard value
	var val: float = 0.5
	var db: float = linear_to_db(maxf(1e-6, val))
	var roundtrip: float = db_to_linear(db)
	assert_approx(roundtrip, 0.5, 0.001, "Linear to DB roundtrip for 0.5 must match")

# ==============================================================================
# 2. AUDIO SERVER OUT-OF-BOUNDS BUS INDICES
# ==============================================================================

func test_audio_server_bus_index_out_of_bounds_protection() -> void:
	var total_buses: int = AudioServer.bus_count
	assert_gt(total_buses, 0, "AudioServer must have at least Master bus (count > 0)")
	
	# Query non-existent bus name
	var invalid_bus_idx: int = AudioServer.get_bus_index("NON_EXISTENT_BUS_RANDOM_XYZ_123")
	assert_eq(invalid_bus_idx, -1, "Querying non-existent bus name must return -1")
	
	# Defensive boundary helper pattern validation
	var is_bus_index_valid = func(idx: int) -> bool:
		return idx >= 0 and idx < AudioServer.bus_count
	
	assert_true(is_bus_index_valid.call(0), "Bus index 0 must be valid")
	assert_false(is_bus_index_valid.call(-1), "Bus index -1 must be invalid")
	assert_false(is_bus_index_valid.call(total_buses + 100), "Out of bounds bus index must be invalid")

# ==============================================================================
# 3. FILTER CUTOFF BOUNDARIES (0 Hz AND 48000 Hz)
# ==============================================================================

func test_filter_cutoff_boundary_0_and_48000_hz() -> void:
	var lpf: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	lpf.cutoff_hz = 0.0
	assert_approx(lpf.cutoff_hz, 0.0, 0.001, "LPF accepts 0.0 Hz cutoff")
	
	lpf.cutoff_hz = 48000.0
	assert_approx(lpf.cutoff_hz, 48000.0, 0.001, "LPF accepts 48000.0 Hz cutoff")
	
	lpf.cutoff_hz = -100.0
	assert_approx(lpf.cutoff_hz, -100.0, 0.001, "LPF accepts negative cutoff property without crash")
	
	var hpf: AudioEffectHighPassFilter = AudioEffectHighPassFilter.new()
	hpf.cutoff_hz = 0.0
	assert_approx(hpf.cutoff_hz, 0.0, 0.001, "HPF accepts 0.0 Hz cutoff")
	hpf.cutoff_hz = 48000.0
	assert_approx(hpf.cutoff_hz, 48000.0, 0.001, "HPF accepts 48000.0 Hz cutoff")

# ==============================================================================
# 4. PITCH SCALE ZERO AND NEGATIVE BOUNDARIES
# ==============================================================================

func test_pitch_scale_zero_and_boundaries() -> void:
	var player: AudioStreamPlayer = autofree(AudioStreamPlayer.new()) as AudioStreamPlayer
	player.pitch_scale = 0.0
	assert_true(player.pitch_scale >= 0.0, "AudioStreamPlayer safely handles 0.0 pitch scale")
	
	player.pitch_scale = -1.0
	assert_true(player.pitch_scale > 0.0, "AudioStreamPlayer safely rejects negative pitch scale")
	
	player.pitch_scale = 32.0
	assert_approx(player.pitch_scale, 32.0, 0.001, "AudioStreamPlayer accepts max pitch scale")
	
	var pitch_shift: AudioEffectPitchShift = AudioEffectPitchShift.new()
	pitch_shift.pitch_scale = 0.5
	assert_approx(pitch_shift.pitch_scale, 0.5, 0.001, "AudioEffectPitchShift pitch scale 0.5")

# ==============================================================================
# 5. EQ BAND OUT-OF-BOUNDS AND GAIN EXTREMES
# ==============================================================================

func test_audio_effect_eq_band_boundaries() -> void:
	var eq6: AudioEffectEQ6 = AudioEffectEQ6.new()
	assert_eq(eq6.get_band_count(), 6, "EQ6 must have exactly 6 bands")
	
	# Extreme gain boundaries
	eq6.set_band_gain_db(0, -60.0)
	assert_approx(eq6.get_band_gain_db(0), -60.0, 0.001, "Band 0 gain -60.0 dB")
	eq6.set_band_gain_db(5, 24.0)
	assert_approx(eq6.get_band_gain_db(5), 24.0, 0.001, "Band 5 gain 24.0 dB")
	
	var eq10: AudioEffectEQ10 = AudioEffectEQ10.new()
	assert_eq(eq10.get_band_count(), 10, "EQ10 must have exactly 10 bands")
	
	var eq21: AudioEffectEQ21 = AudioEffectEQ21.new()
	assert_eq(eq21.get_band_count(), 21, "EQ21 must have exactly 21 bands")

# ==============================================================================
# 6. SPECTRUM ANALYZER INVERTED FREQUENCY RANGES
# ==============================================================================

func test_spectrum_analyzer_inverted_frequency_ranges() -> void:
	var analyzer: AudioEffectSpectrumAnalyzer = AudioEffectSpectrumAnalyzer.new()
	analyzer.buffer_length = 0.1
	analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	assert_approx(analyzer.buffer_length, 0.1, 0.001, "Spectrum analyzer buffer length 0.1s")
	assert_eq(analyzer.fft_size, AudioEffectSpectrumAnalyzer.FFT_SIZE_1024, "FFT Size 1024")
	
	# Validate safe frequency range ordering helper
	var sanitize_freq_range = func(min_hz: float, max_hz: float) -> Vector2:
		var safe_min: float = maxf(0.0, minf(min_hz, max_hz))
		var safe_max: float = maxf(safe_min, maxf(min_hz, max_hz))
		return Vector2(safe_min, safe_max)
	
	var sanitized_inverted: Vector2 = sanitize_freq_range.call(5000.0, 100.0)
	assert_approx(sanitized_inverted.x, 100.0, 0.001, "Sanitized min Hz")
	assert_approx(sanitized_inverted.y, 5000.0, 0.001, "Sanitized max Hz")
	
	var sanitized_neg: Vector2 = sanitize_freq_range.call(-200.0, -50.0)
	assert_approx(sanitized_neg.x, 0.0, 0.001, "Negative Hz clamped to 0")
