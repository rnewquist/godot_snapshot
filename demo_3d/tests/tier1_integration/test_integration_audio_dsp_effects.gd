# test_integration_audio_dsp_effects.gd
# Tier 1 Integration Suite 7: Discrete tests for all 23 AudioEffect classes and AudioServer bus routing.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Integration_Audio_DSP_Effects"
	test_type = "integration"

# ==============================================================================
# DISCRETE TESTS FOR ALL 23 AUDIO DSP EFFECTS + BUS ROUTING
# ==============================================================================

func test_audio_effect_reverb() -> void:
	var reverb: AudioEffectReverb = AudioEffectReverb.new()
	reverb.room_size = 0.75
	reverb.damping = 0.4
	reverb.spread = 0.8
	reverb.dry = 0.9
	reverb.wet = 0.5
	assert_approx(reverb.room_size, 0.75, 0.001)
	assert_approx(reverb.damping, 0.4, 0.001)
	assert_approx(reverb.spread, 0.8, 0.001)
	assert_approx(reverb.dry, 0.9, 0.001)
	assert_approx(reverb.wet, 0.5, 0.001)

func test_audio_effect_delay() -> void:
	var delay: AudioEffectDelay = AudioEffectDelay.new()
	delay.tap1_delay_ms = 200.0
	delay.tap2_delay_ms = 400.0
	delay.feedback_active = true
	assert_approx(delay.tap1_delay_ms, 200.0, 0.001)
	assert_approx(delay.tap2_delay_ms, 400.0, 0.001)
	assert_true(delay.feedback_active)

func test_audio_effect_low_pass_filter() -> void:
	var lpf: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
	lpf.cutoff_hz = 1500.0
	lpf.resonance = 0.6
	lpf.db = AudioEffectFilter.FILTER_12DB
	assert_approx(lpf.cutoff_hz, 1500.0, 0.001)
	assert_approx(lpf.resonance, 0.6, 0.001)
	assert_eq(lpf.db, AudioEffectFilter.FILTER_12DB)

func test_audio_effect_high_pass_filter() -> void:
	var hpf: AudioEffectHighPassFilter = AudioEffectHighPassFilter.new()
	hpf.cutoff_hz = 350.0
	hpf.resonance = 0.5
	hpf.db = AudioEffectFilter.FILTER_24DB
	assert_approx(hpf.cutoff_hz, 350.0, 0.001)
	assert_approx(hpf.resonance, 0.5, 0.001)
	assert_eq(hpf.db, AudioEffectFilter.FILTER_24DB)

func test_audio_effect_band_pass_filter() -> void:
	var bpf: AudioEffectBandPassFilter = AudioEffectBandPassFilter.new()
	bpf.cutoff_hz = 1200.0
	bpf.resonance = 0.7
	assert_approx(bpf.cutoff_hz, 1200.0, 0.001)
	assert_approx(bpf.resonance, 0.7, 0.001)

func test_audio_effect_band_limit_filter() -> void:
	var blf: AudioEffectBandLimitFilter = AudioEffectBandLimitFilter.new()
	blf.cutoff_hz = 2500.0
	blf.resonance = 0.5
	assert_approx(blf.cutoff_hz, 2500.0, 0.001)
	assert_approx(blf.resonance, 0.5, 0.001)

func test_audio_effect_notch_filter() -> void:
	var nf: AudioEffectNotchFilter = AudioEffectNotchFilter.new()
	nf.cutoff_hz = 60.0
	nf.resonance = 0.9
	assert_approx(nf.cutoff_hz, 60.0, 0.001)
	assert_approx(nf.resonance, 0.9, 0.001)

func test_audio_effect_low_shelf_filter() -> void:
	var lsf: AudioEffectLowShelfFilter = AudioEffectLowShelfFilter.new()
	lsf.cutoff_hz = 350.0
	lsf.gain = 4.0
	assert_approx(lsf.cutoff_hz, 350.0, 0.001)
	assert_approx(lsf.gain, 4.0, 0.001)

func test_audio_effect_high_shelf_filter() -> void:
	var hsf: AudioEffectHighShelfFilter = AudioEffectHighShelfFilter.new()
	hsf.cutoff_hz = 4500.0
	hsf.gain = 0.5
	assert_approx(hsf.cutoff_hz, 4500.0, 0.001)
	assert_approx(hsf.gain, 0.5, 0.001)

func test_audio_effect_chorus() -> void:
	var chorus: AudioEffectChorus = AudioEffectChorus.new()
	chorus.voice_count = 3
	chorus.dry = 0.8
	chorus.wet = 0.4
	assert_eq(chorus.voice_count, 3)
	assert_approx(chorus.dry, 0.8, 0.001)
	assert_approx(chorus.wet, 0.4, 0.001)

func test_audio_effect_distortion() -> void:
	var dist: AudioEffectDistortion = AudioEffectDistortion.new()
	dist.mode = AudioEffectDistortion.MODE_OVERDRIVE
	dist.drive = 0.6
	dist.post_gain = -2.0
	assert_eq(dist.mode, AudioEffectDistortion.MODE_OVERDRIVE)
	assert_approx(dist.drive, 0.6, 0.001)
	assert_approx(dist.post_gain, -2.0, 0.001)

func test_audio_effect_pitch_shift() -> void:
	var pitch: AudioEffectPitchShift = AudioEffectPitchShift.new()
	pitch.pitch_scale = 1.5
	pitch.oversampling = 8
	pitch.fft_size = AudioEffectPitchShift.FFT_SIZE_2048
	assert_approx(pitch.pitch_scale, 1.5, 0.001)
	assert_eq(pitch.oversampling, 8)
	assert_eq(pitch.fft_size, AudioEffectPitchShift.FFT_SIZE_2048)

func test_audio_effect_phaser() -> void:
	var phaser: AudioEffectPhaser = AudioEffectPhaser.new()
	phaser.range_min_hz = 400.0
	phaser.range_max_hz = 1600.0
	phaser.rate_hz = 1.0
	phaser.feedback = 0.5
	assert_approx(phaser.range_min_hz, 400.0, 0.001)
	assert_approx(phaser.range_max_hz, 1600.0, 0.001)
	assert_approx(phaser.rate_hz, 1.0, 0.001)
	assert_approx(phaser.feedback, 0.5, 0.001)

func test_audio_effect_eq6() -> void:
	var eq6: AudioEffectEQ6 = AudioEffectEQ6.new()
	assert_eq(eq6.get_band_count(), 6)
	eq6.set_band_gain_db(0, 2.0)
	eq6.set_band_gain_db(5, -4.0)
	assert_approx(eq6.get_band_gain_db(0), 2.0, 0.001)
	assert_approx(eq6.get_band_gain_db(5), -4.0, 0.001)

func test_audio_effect_eq10() -> void:
	var eq10: AudioEffectEQ10 = AudioEffectEQ10.new()
	assert_eq(eq10.get_band_count(), 10)
	eq10.set_band_gain_db(3, 1.5)
	eq10.set_band_gain_db(8, -2.5)
	assert_approx(eq10.get_band_gain_db(3), 1.5, 0.001)
	assert_approx(eq10.get_band_gain_db(8), -2.5, 0.001)

func test_audio_effect_eq21() -> void:
	var eq21: AudioEffectEQ21 = AudioEffectEQ21.new()
	assert_eq(eq21.get_band_count(), 21)
	eq21.set_band_gain_db(10, 3.0)
	eq21.set_band_gain_db(20, -1.0)
	assert_approx(eq21.get_band_gain_db(10), 3.0, 0.001)
	assert_approx(eq21.get_band_gain_db(20), -1.0, 0.001)

func test_audio_effect_compressor() -> void:
	var comp: AudioEffectCompressor = AudioEffectCompressor.new()
	comp.threshold = -18.0
	comp.ratio = 4.0
	comp.gain = 2.0
	comp.attack_us = 20.0
	comp.release_ms = 250.0
	assert_approx(comp.threshold, -18.0, 0.001)
	assert_approx(comp.ratio, 4.0, 0.001)
	assert_approx(comp.gain, 2.0, 0.001)
	assert_approx(comp.attack_us, 20.0, 0.001)
	assert_approx(comp.release_ms, 250.0, 0.001)

func test_audio_effect_limiter() -> void:
	var limiter: AudioEffectLimiter = AudioEffectLimiter.new()
	limiter.ceiling_db = -0.1
	limiter.threshold_db = -2.0
	limiter.soft_clip_db = -1.0
	assert_approx(limiter.ceiling_db, -0.1, 0.001)
	assert_approx(limiter.threshold_db, -2.0, 0.001)
	assert_approx(limiter.soft_clip_db, -1.0, 0.001)

func test_audio_effect_panner() -> void:
	var panner: AudioEffectPanner = AudioEffectPanner.new()
	panner.pan = -0.5
	assert_approx(panner.pan, -0.5, 0.001)

func test_audio_effect_stereo_enhance() -> void:
	var stereo: AudioEffectStereoEnhance = AudioEffectStereoEnhance.new()
	stereo.pan_pullout = 1.2
	stereo.time_pullout_ms = 4.0
	stereo.surround = 0.3
	assert_approx(stereo.pan_pullout, 1.2, 0.001)
	assert_approx(stereo.time_pullout_ms, 4.0, 0.001)
	assert_approx(stereo.surround, 0.3, 0.001)

func test_audio_effect_spectrum_analyzer() -> void:
	var spec: AudioEffectSpectrumAnalyzer = AudioEffectSpectrumAnalyzer.new()
	spec.buffer_length = 3.0
	spec.tap_back_pos = 0.01
	spec.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	assert_approx(spec.buffer_length, 3.0, 0.001)
	assert_approx(spec.tap_back_pos, 0.01, 0.001)
	assert_eq(spec.fft_size, AudioEffectSpectrumAnalyzer.FFT_SIZE_1024)

func test_audio_effect_capture() -> void:
	var cap: AudioEffectCapture = AudioEffectCapture.new()
	cap.buffer_length = 0.25
	assert_approx(cap.buffer_length, 0.25, 0.001)

func test_audio_effect_record() -> void:
	var rec: AudioEffectRecord = AudioEffectRecord.new()
	rec.format = AudioStreamWAV.FORMAT_16_BITS
	assert_eq(rec.format, AudioStreamWAV.FORMAT_16_BITS)

func test_audio_effect_amplify_and_bus_routing() -> void:
	var amp: AudioEffectAmplify = AudioEffectAmplify.new()
	amp.volume_db = 4.5
	assert_approx(amp.volume_db, 4.5, 0.001)
	
	# Dynamically add to bus 0, verify, then remove
	var bus_idx: int = 0
	AudioServer.add_bus_effect(bus_idx, amp)
	var effect_count = AudioServer.get_bus_effect_count(bus_idx)
	assert_gt(effect_count, 0)
	
	var last_effect = AudioServer.get_bus_effect(bus_idx, effect_count - 1)
	assert_eq(last_effect, amp)
	
	AudioServer.remove_bus_effect(bus_idx, effect_count - 1)
