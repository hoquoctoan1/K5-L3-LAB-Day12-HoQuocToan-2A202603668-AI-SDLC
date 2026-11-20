class_name TS
extends RefCounted
## Tien ich test toi thieu. Moi file test_*.gd co `func run(t: TS)` (khong static).

var failures: int = 0
var checks: int = 0
var current: String = ""

func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL [%s] %s" % [current, msg])

func eq(a, b, msg: String) -> void:
	ok(a == b, "%s (got %s, want %s)" % [msg, str(a), str(b)])

func near(a: float, b: float, msg: String, eps: float = 0.001) -> void:
	ok(absf(a - b) <= eps, "%s (got %f, want %f)" % [msg, a, b])
