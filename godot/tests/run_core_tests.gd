extends SceneTree
## GODOT --headless --path godot --script res://tests/run_core_tests.gd [-- --only <ten>]
## Quet tests/core va tests/headless, chay moi test_*.gd. Exit != 0 neu fail.

func _init() -> void:
	var only := ""
	var args := OS.get_cmdline_user_args()
	var i := args.find("--only")
	if i >= 0 and i + 1 < args.size():
		only = args[i + 1]
	var t := TS.new()
	var files: Array = []
	for dir in ["res://tests/core", "res://tests/headless"]:
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f in d.get_files():
			if f.begins_with("test_") and f.ends_with(".gd") and f != "test_support.gd":
				files.append(dir + "/" + f)
	files.sort()
	for path in files:
		var name: String = path.get_file().get_basename()
		if only != "" and not name.contains(only):
			continue
		t.current = name
		var script = load(path)
		if script == null:
			t.failures += 1
			printerr("FAIL [%s] khong nap duoc script" % name)
			continue
		var inst = script.new()
		if inst == null or not inst.has_method("run"):
			t.failures += 1
			printerr("FAIL [%s] script khong co run() hoac loi bien dich" % name)
			continue
		inst.run(t)
		print("ran ", name)
	print("checks=%d failures=%d" % [t.checks, t.failures])
	quit(1 if t.failures > 0 else 0)
