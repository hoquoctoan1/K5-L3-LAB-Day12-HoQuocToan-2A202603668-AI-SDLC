extends RefCounted
## Cai dat nguoi choi, luu ConfigFile. `var s = Settings.new(); s.load_settings()`.
signal changed

const DEFAULT_PATH := "user://settings.cfg"
var path: String = DEFAULT_PATH
var volume: float = 0.8            # 0..1 (master)
var mouse_sensitivity: float = 1.0 # he so 0.25..3.0 (nhan voi 0.004 rad/px)
var colorblind: bool = false       # v1.2: "Bang mau de phan biet" (TICKET-03 muc 6), duoc luu

func _init(p: String = DEFAULT_PATH) -> void:
	path = p

func load_settings() -> bool:
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return false
	volume = clampf(float(cf.get_value("audio", "volume", volume)), 0.0, 1.0)
	mouse_sensitivity = clampf(float(cf.get_value("input", "mouse_sensitivity", mouse_sensitivity)), 0.25, 3.0)
	colorblind = bool(cf.get_value("display", "colorblind", colorblind))
	changed.emit()
	return true

func save_settings() -> int:
	var cf := ConfigFile.new()
	cf.set_value("audio", "volume", volume)
	cf.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cf.set_value("display", "colorblind", colorblind)
	return cf.save(path)

func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	changed.emit()

func set_colorblind(v: bool) -> void:
	colorblind = v
	changed.emit()

func set_mouse_sensitivity(v: float) -> void:
	mouse_sensitivity = clampf(v, 0.25, 3.0)
	changed.emit()
