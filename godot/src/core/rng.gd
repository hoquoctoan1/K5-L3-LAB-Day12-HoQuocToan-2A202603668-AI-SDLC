class_name Rng
extends RefCounted
## mulberry32, thuan so nguyen 32-bit -> tat dinh.

const M32: int = 0xFFFFFFFF

var _s: int = 0

func _init(seed_value: int = 0) -> void:
	_s = seed_value & M32

func next_u32() -> int:
	_s = (_s + 0x6D2B79F5) & M32
	var t: int = _s
	t = ((t ^ (t >> 15)) * (t | 1)) & M32
	t = (t ^ (t + (((t ^ (t >> 7)) * (t | 61)) & M32))) & M32
	return (t ^ (t >> 14)) & M32

func next_float() -> float:
	return float(next_u32()) / 4294967296.0

func next_int(n: int) -> int:
	return next_u32() % n
