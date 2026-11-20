extends RefCounted

const ID = preload("res://src/core/input_decoder.gd")

func _dec(frames: Array):
	var d = ID.new()
	var r: Dictionary = d.load_data({"frames": frames})
	return d if r["ok"] else null

func _near(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 1e-5

func run(t: TS) -> void:
	# idle
	var d0 = ID.new()
	var f0: Dictionary = d0.next(0)
	t.ok(_near(f0["move"], Vector2.ZERO) and not f0["jump"] and not f0["pulse"], "khong inputs -> idle")

	# theta = 0
	var d = _dec([{"tick": 0, "move": [0, 1], "cam_yaw_deg": 0}])
	t.ok(d != null, "parse hop le")
	t.ok(_near(d.next(0)["move"], Vector2(0, 1)), "theta=0 giu nguyen")

	# theta = 90: x'=z*1=1, z'=0 voi move [0,1]
	d = _dec([{"tick": 0, "move": [0, 1], "cam_yaw_deg": 90}])
	t.ok(_near(d.next(0)["move"], Vector2(1, 0)), "theta=90 xoay [0,1] -> [1,0]")
	d = _dec([{"tick": 0, "move": [1, 0], "cam_yaw_deg": 90}])
	t.ok(_near(d.next(0)["move"], Vector2(0, -1)), "theta=90 xoay [1,0] -> [0,-1]")

	# chuan hoa
	d = _dec([{"tick": 0, "move": [1, 1]}])
	var m: Vector2 = d.next(0)["move"]
	t.ok(absf(m.length() - 1.0) < 1e-5, "vector >1 chuan hoa ve 1")
	d = _dec([{"tick": 0, "move": [0.3, 0.4]}])
	t.ok(_near(d.next(0)["move"], Vector2(0.3, 0.4)), "vector <1 khong doi")

	# edge: giu true nhieu tick chi kich 1 lan; nha roi nhan lai kich lai
	d = _dec([{"tick": 1, "jump": true}, {"tick": 5, "jump": false}, {"tick": 6, "jump": true}])
	var fired: Array = []
	for k in range(9):
		if d.next(k)["jump"]:
			fired.append(k)
	t.eq(fired, [1, 6], "edge-trigger giu/nha/nhan lai")

	# trang thai giu nguyen khi thieu truong
	d = _dec([{"tick": 0, "move": [0, 1], "cam_yaw_deg": 90, "pulse": true}, {"tick": 3, "interact": true}])
	d.next(0)
	d.next(1)
	d.next(2)
	var f3: Dictionary = d.next(3)
	t.ok(_near(f3["move"], Vector2(1, 0)), "move/yaw giu gia tri cu")
	t.eq(f3["cam_yaw_deg"], 90.0, "yaw giu")
	t.ok(f3["interact"] and not f3["pulse"], "pulse khong lap lai khi thieu truong")

	# bo qua tick trong (lien tuc goi)
	d = _dec([{"tick": 2, "pulse": true}])
	t.ok(not d.next(0)["pulse"] and not d.next(1)["pulse"] and d.next(2)["pulse"], "pulse dung tick")

	# tu choi
	t.ok(not ID.parse({"frames": [{"tick": 1}, {"tick": 1}]})["ok"], "tick trung bi tu choi")
	t.ok(not ID.parse({"frames": [{"tick": 5}, {"tick": 2}]})["ok"], "tick giam bi tu choi")
	t.ok(not ID.parse({"frames": [{"tick": "0"}]})["ok"], "tick sai kieu")
	t.ok(not ID.parse({"frames": [{"tick": 0, "move": [2, 0]}]})["ok"], "move ngoai [-1,1]")
	t.ok(not ID.parse({"frames": [{"tick": 0, "move": [0]}]})["ok"], "move sai kich thuoc")
	t.ok(not ID.parse({"frames": [{"tick": 0, "move": ["a", 0]}]})["ok"], "move sai kieu")
	t.ok(not ID.parse({"frames": [{"tick": 0, "jump": 1}]})["ok"], "bool sai kieu")
	t.ok(not ID.parse({"frames": [{"tick": 0, "cam_yaw_deg": "x"}]})["ok"], "yaw sai kieu")
	t.ok(not ID.parse({"frames": {}})["ok"], "frames khong phai array")
	t.ok(not ID.parse([])["ok"], "root khong phai object")
	t.ok(ID.parse({"frames": []})["ok"], "frames rong hop le")
	t.ok(ID.parse({"frames": [{"tick": 0, "move": [0, 1]}, {"tick": 120, "interact": true}]})["ok"], "vi du hop le")

	# v2: dash, pause canh len
	d = _dec([{"tick": 1, "dash": true}, {"tick": 3, "dash": false}, {"tick": 4, "dash": true, "pause": true}, {"tick": 6, "pause": false}, {"tick": 7, "pause": true}])
	var fd: Array = []
	var fp: Array = []
	for k in range(9):
		var f: Dictionary = d.next(k)
		t.ok(f.has("dash") and f.has("pause"), "frame v2 co dash/pause")
		if f["dash"]:
			fd.append(k)
		if f["pause"]:
			fp.append(k)
	t.eq(fd, [1, 4], "dash canh len")
	t.eq(fp, [4, 7], "pause canh len")
	t.ok(not ID.parse({"frames": [{"tick": 0, "dash": 1}]})["ok"], "dash sai kieu")
	t.ok(not ID.parse({"frames": [{"tick": 0, "pause": "x"}]})["ok"], "pause sai kieu")
	t.ok(ID.parse({"frames": [{"tick": 0, "dash": true, "pause": false}]})["ok"], "dash/pause hop le")
