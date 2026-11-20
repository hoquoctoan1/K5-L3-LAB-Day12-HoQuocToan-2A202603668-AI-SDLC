extends RefCounted
## Tong hop am thanh thuan tuy bang code. Tra PackedFloat32Array mono [-1,1] @ RATE.
const RATE := 22050
const SFX_NAMES := ["pickup", "light_lantern", "pulse", "hit", "jump", "dash", "win", "lose", "shade_spawn", "countdown_tick"]

## Mot not: tan so f0 -> f1, dai dur giay, song 0=sin 1=vuong mem 2=nhieu 3=tam giac.
static func _note(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, vol: float, wave: int = 0, atk: float = 0.005, rel: float = -1.0) -> void:
	var n := int(dur * RATE)
	var s0 := int(start * RATE)
	if rel < 0.0:
		rel = dur * 0.6
	var ph := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		if s0 + i >= buf.size():
			break
		var t := float(i) / RATE
		var f := lerpf(f0, f1, float(i) / maxf(n - 1, 1))
		ph += f / RATE
		var x: float
		match wave:
			1: x = clampf(sin(TAU * ph) * 2.5, -1.0, 1.0) * 0.6
			2: x = rng.randf_range(-1.0, 1.0)
			3: x = 4.0 * absf(fposmod(ph, 1.0) - 0.5) - 1.0
			_: x = sin(TAU * ph)
		var env := minf(t / atk, 1.0) * clampf((dur - t) / rel, 0.0, 1.0)
		buf[s0 + i] += x * env * vol

static func _blank(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * RATE))
	return b

static func sfx(name: String) -> PackedFloat32Array:
	var b: PackedFloat32Array
	match name:
		"pickup":
			b = _blank(0.2); _note(b, 0, 0.08, 880, 1100, 0.5); _note(b, 0.07, 0.12, 1320, 1320, 0.5)
		"light_lantern":
			b = _blank(0.7); _note(b, 0, 0.6, 440, 440, 0.35, 3); _note(b, 0.08, 0.55, 660, 660, 0.3); _note(b, 0.18, 0.5, 880, 880, 0.3)
		"pulse":
			b = _blank(0.5); _note(b, 0, 0.45, 200, 900, 0.4, 0, 0.01, 0.35); _note(b, 0, 0.3, 400, 1200, 0.2, 3)
		"hit":
			b = _blank(0.3); _note(b, 0, 0.25, 180, 60, 0.6, 1); _note(b, 0, 0.1, 1, 1, 0.4, 2)
		"jump":
			b = _blank(0.2); _note(b, 0, 0.17, 300, 650, 0.45, 3)
		"dash":
			b = _blank(0.25); _note(b, 0, 0.22, 1, 1, 0.35, 2, 0.02, 0.18); _note(b, 0, 0.2, 500, 200, 0.2, 0)
		"win":
			b = _blank(1.0)
			var fr := [523.0, 659.0, 784.0, 1047.0]
			for i in 4:
				_note(b, i * 0.14, 0.5 if i == 3 else 0.2, fr[i], fr[i], 0.4, 3)
		"lose":
			b = _blank(1.0)
			var fl := [392.0, 349.0, 311.0, 233.0]
			for i in 4:
				_note(b, i * 0.2, 0.3 if i < 3 else 0.2 + 0.2, fl[i], fl[i] * 0.97, 0.4, 3)
		"shade_spawn":
			b = _blank(0.6); _note(b, 0, 0.55, 110, 70, 0.5, 3, 0.1, 0.4); _note(b, 0.1, 0.4, 116, 66, 0.3, 0, 0.1, 0.3)
		"countdown_tick":
			b = _blank(0.12); _note(b, 0, 0.08, 1000, 1000, 0.5, 1, 0.002, 0.07)
		_:
			return PackedFloat32Array()
	return b

## Nhac nen ~12.8 s loop: pad Am-F-C-G + arpeggio nhe.
static func music() -> PackedFloat32Array:
	var bar := 3.2
	var chords := [[220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [261.63, 329.63, 392.0], [196.0, 246.94, 293.66]]
	var b := _blank(bar * 4)
	for ci in 4:
		var t0: float = ci * bar
		for f in chords[ci]:
			_note(b, t0, bar, f * 0.5, f * 0.5, 0.12, 0, 0.8, 0.8)
		var notes: Array = chords[ci]
		for k in 8:
			var f2: float = float(notes[k % 3]) * (2.0 if k % 2 == 1 else 1.0)
			_note(b, t0 + k * 0.4, 0.5, f2, f2, 0.09, 3, 0.01, 0.45)
	return b

static func peak(s: PackedFloat32Array) -> float:
	var p := 0.0
	for v in s:
		p = maxf(p, absf(v))
	return p

static func to_wav(s: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = s.size()
	return w
