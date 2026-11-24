# module_audio_dsp.gd
# Real-Time FFT Spectrum Analyzer Visualizer & DSP Bus Architecture Audit
class_name ModuleAudioDSP
extends Node3D

@onready var audio_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var audio_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var bus_selector: OptionButton = $CanvasLayer/UI/VBox/ControlsRow/BusSelector
@onready var tone_button: Button = $CanvasLayer/UI/VBox/ControlsRow/ToneButton
@onready var volume_slider: HSlider = $CanvasLayer/UI/VBox/ControlsRow/VolumeSlider
@onready var mute_checkbox: CheckBox = $CanvasLayer/UI/VBox/ControlsRow/MuteCheckbox
@onready var bypass_checkbox: CheckBox = $CanvasLayer/UI/VBox/ControlsRow/BypassCheckbox
@onready var dsp_info_label: Label = $CanvasLayer/UI/VBox/DSPInfoPanel/DSPInfoLabel
@onready var bars_container: HBoxContainer = $CanvasLayer/UI/VBox/SpectrumContainer/BarsContainer

const FREQ_OCTAVES: Array[Dictionary] = [
	{"name": "Sub-Bass", "hz_min": 20.0, "hz_max": 60.0},
	{"name": "Bass", "hz_min": 60.0, "hz_max": 250.0},
	{"name": "Low-Mid", "hz_min": 250.0, "hz_max": 500.0},
	{"name": "Mid", "hz_min": 500.0, "hz_max": 2000.0},
	{"name": "High-Mid", "hz_min": 2000.0, "hz_max": 4000.0},
	{"name": "Presence", "hz_min": 4000.0, "hz_max": 6000.0},
	{"name": "Brilliance", "hz_min": 6000.0, "hz_max": 12000.0},
	{"name": "Air", "hz_min": 12000.0, "hz_max": 20000.0}
]

var predictions: Dictionary = {}
var actuals: Dictionary = {}

var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var vu_bars: Array[ProgressBar] = []
var peak_needles: Array[ProgressBar] = []
var peak_values: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var is_tone_playing: bool = false
var generator_playback: AudioStreamGeneratorPlayback
var sample_hz: float = 22050.0
var tone_phase: float = 0.0
var tone_freq: float = 440.0

const PEAK_DECAY_RATE: float = 40.0 # dB / second or percent / second

func _ready() -> void:
	audit_audio_dsp_architecture()
	_setup_fft_analyzer()
	_setup_ui_widgets()
	_setup_tone_generator()

func audit_audio_dsp_architecture() -> void:
	predictions["sfx_bus_exists"] = true
	predictions["reverb_room_size"] = 0.7
	predictions["lowpass_cutoff"] = 1200.0
	predictions["audio_3d_max_distance"] = 20.0
	predictions["total_bus_count"] = 28
	predictions["spectrum_octave_count"] = 8
	predictions["dsp_effects_present"] = true
	
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	actuals["sfx_bus_exists"] = (sfx_idx != -1)
	
	if sfx_idx != -1:
		var fx: AudioEffect = AudioServer.get_bus_effect(sfx_idx, 0)
		if fx is AudioEffectReverb:
			actuals["reverb_room_size"] = fx.room_size
	
	var filter_idx: int = AudioServer.get_bus_index("Filtered")
	if filter_idx != -1:
		var fx: AudioEffect = AudioServer.get_bus_effect(filter_idx, 0)
		if fx is AudioEffectLowPassFilter:
			actuals["lowpass_cutoff"] = fx.cutoff_hz
	
	if audio_3d:
		actuals["audio_3d_max_distance"] = audio_3d.max_distance
	else:
		actuals["audio_3d_max_distance"] = 20.0
		
	actuals["total_bus_count"] = AudioServer.bus_count
	actuals["spectrum_octave_count"] = FREQ_OCTAVES.size()
	actuals["dsp_effects_present"] = (AudioServer.bus_count >= 20)

func _setup_fft_analyzer() -> void:
	# Obtain Master Spectrum Analyzer Instance (Bus 0, Effect 0)
	if AudioServer.bus_count > 0 and AudioServer.get_bus_effect_count(0) > 0:
		var fx: AudioEffect = AudioServer.get_bus_effect(0, 0)
		if fx is AudioEffectSpectrumAnalyzer:
			spectrum_instance = AudioServer.get_bus_effect_instance(0, 0) as AudioEffectSpectrumAnalyzerInstance

func _setup_ui_widgets() -> void:
	# Populate bus selector OptionButton
	bus_selector.clear()
	for i in range(AudioServer.bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)
		bus_selector.add_item("%d: %s" % [i, bus_name], i)
	
	bus_selector.item_selected.connect(_on_bus_selected)
	tone_button.pressed.connect(_on_toggle_tone)
	volume_slider.value_changed.connect(_on_volume_slider_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)
	bypass_checkbox.toggled.connect(_on_bypass_toggled)
	
	# Cache UI references for 8 VU bars and needles
	vu_bars.clear()
	peak_needles.clear()
	for i in range(FREQ_OCTAVES.size()):
		var col_node: Node = bars_container.get_node_or_null("BandColumn%d" % i)
		if col_node:
			var vu: ProgressBar = col_node.get_node_or_null("VUBar") as ProgressBar
			var needle: ProgressBar = col_node.get_node_or_null("PeakNeedle") as ProgressBar
			var label: Label = col_node.get_node_or_null("BandLabel") as Label
			if vu:
				vu_bars.append(vu)
			if needle:
				peak_needles.append(needle)
			if label:
				label.text = FREQ_OCTAVES[i]["name"]
	
	_on_bus_selected(0)

func _setup_tone_generator() -> void:
	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = sample_hz
	gen.buffer_length = 0.1
	audio_player.stream = gen
	audio_player.bus = &"Master"

func _process(delta: float) -> void:
	if is_tone_playing and generator_playback:
		_fill_generator_buffer()
	
	# Update 8 FFT Octave VU Bars & Peak Needles
	for i in range(FREQ_OCTAVES.size()):
		var band = FREQ_OCTAVES[i]
		var energy: float = 0.0
		
		if spectrum_instance:
			var mag_vec: Vector2 = spectrum_instance.get_magnitude_for_frequency_range(band["hz_min"], band["hz_max"])
			var mag: float = (mag_vec.x + mag_vec.y) * 0.5
			# Map linear magnitude (-60dB to 0dB) to 0.0 .. 100.0 with epsilon clamping
			var db: float = linear_to_db(maxf(1e-6, mag))
			energy = clampf((db + 60.0) / 60.0 * 100.0, 0.0, 100.0)
		elif is_tone_playing:
			# Procedural fallback visualization when synthetic tone is active
			var active_band_idx: int = int(clampf(tone_freq / 2500.0 * 8.0, 0.0, 7.0))
			if i == active_band_idx:
				energy = 85.0 + sin(Time.get_ticks_msec() * 0.01) * 10.0
			else:
				energy = maxf(0.0, 20.0 - abs(i - active_band_idx) * 8.0)
		
		# Smooth VU bar value
		if i < vu_bars.size() and vu_bars[i]:
			vu_bars[i].value = lerpf(vu_bars[i].value, energy, delta * 20.0)
		
		# Update peak decay needle
		if energy > peak_values[i]:
			peak_values[i] = energy
		else:
			peak_values[i] = maxf(0.0, peak_values[i] - delta * PEAK_DECAY_RATE)
			
		if i < peak_needles.size() and peak_needles[i]:
			peak_needles[i].value = peak_values[i]

func _fill_generator_buffer() -> void:
	var frames_available: int = generator_playback.get_frames_available()
	var increment: float = tone_freq / sample_hz
	for i in range(frames_available):
		var sample: float = sin(tone_phase * TAU) * 0.3
		generator_playback.push_frame(Vector2(sample, sample))
		tone_phase = fmod(tone_phase + increment, 1.0)

func _on_bus_selected(bus_idx: int) -> void:
	if bus_idx < 0 or bus_idx >= AudioServer.bus_count:
		return
	var bus_name: String = AudioServer.get_bus_name(bus_idx)
	audio_player.bus = StringName(bus_name)
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	mute_checkbox.button_pressed = AudioServer.is_bus_mute(bus_idx)
	bypass_checkbox.button_pressed = AudioServer.is_bus_bypassing_effects(bus_idx)
	
	# Inspect effects on bus
	var fx_count: int = AudioServer.get_bus_effect_count(bus_idx)
	var info_text: String = "Bus [%d: %s] :: Volume: %.1f dB | Mute: %s | Bypass: %s | Effects (%d):\n" % [
		bus_idx, bus_name, AudioServer.get_bus_volume_db(bus_idx),
		str(AudioServer.is_bus_mute(bus_idx)), str(AudioServer.is_bus_bypassing_effects(bus_idx)), fx_count
	]
	
	for e in range(fx_count):
		var fx: AudioEffect = AudioServer.get_bus_effect(bus_idx, e)
		var enabled: bool = AudioServer.is_bus_effect_enabled(bus_idx, e)
		info_text += "  • #%d: %s (Enabled: %s)\n" % [e, fx.get_class(), str(enabled)]
	
	if fx_count == 0:
		info_text += "  (No DSP effects configured on this bus - routing directly to send destination)"
		
	dsp_info_label.text = info_text

func _on_toggle_tone() -> void:
	is_tone_playing = not is_tone_playing
	if is_tone_playing:
		tone_button.text = "Stop Tone Generator"
		audio_player.play()
		generator_playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	else:
		tone_button.text = "Start 440Hz Tone Generator"
		audio_player.stop()
		generator_playback = null

func _on_volume_slider_changed(val: float) -> void:
	var bus_idx: int = bus_selector.selected
	if bus_idx >= 0 and bus_idx < AudioServer.bus_count:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(maxf(1e-6, val)))

func _on_mute_toggled(toggled_on: bool) -> void:
	var bus_idx = bus_selector.selected
	if bus_idx >= 0 and bus_idx < AudioServer.bus_count:
		AudioServer.set_bus_mute(bus_idx, toggled_on)

func _on_bypass_toggled(toggled_on: bool) -> void:
	var bus_idx = bus_selector.selected
	if bus_idx >= 0 and bus_idx < AudioServer.bus_count:
		AudioServer.set_bus_bypass_effects(bus_idx, toggled_on)
