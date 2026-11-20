extends RefCounted

func run(t: TS) -> void:
	var f := FileAccess.open("res://../game.contract.json", FileAccess.READ)
	t.ok(f != null, "doc duoc game.contract.json")
	if f == null:
		return
	var c = JSON.parse_string(f.get_as_text())
	t.eq(c["contract_version"], "1.0", "contract_version")
	var want := GameConfig.tuning_dict()
	var got: Dictionary = c["tuning"]
	for k in want.keys():
		if k == "score":
			for s in want[k].keys():
				t.eq(float(got["score"][s]), float(want["score"][s]), "score." + s)
		elif k == "fall_enabled":
			t.eq(got[k], want[k], k)
		else:
			t.eq(float(got[k]), float(want[k]), k)
	var r := Rng.new(1)
	var r2 := Rng.new(1)
	t.eq(r.next_u32(), r2.next_u32(), "rng tat dinh")
	t.ok(Rng.new(1).next_u32() != Rng.new(2).next_u32(), "seed khac -> khac")
