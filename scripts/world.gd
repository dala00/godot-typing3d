extends Node3D
## Typing3D - MS1 雰囲気シーン
## 真っ暗な部屋にノートPCを置き、ディスプレイの光で照らされた
## 文字入りキーボード(英字26)を構築する。すべてコードから生成する。

const KEY_W := 0.165
const KEY_D := 0.165
const KEY_H := 0.05
const PITCH := 0.19

const ROWS := ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
const ROW_STAGGER := [0.0, 0.5, 1.0] # 横ずらし(キー数)

# キーボード全体の基準。X中央=0、Z=0付近に手前行。
var _kbd_width := 10.0 * PITCH
# 各キーの床位置(y=0)。文字 -> Vector3
var _key_pos := {}
var _runner: Node3D = null

func _ready() -> void:
	_build_environment()
	_build_desk()
	_build_laptop()
	_build_keyboard()
	_build_lights()
	_build_runner()
	_build_camera()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.006, 0.01)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.45, 0.7)
	env.ambient_light_energy = 0.06
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_strength = 1.1
	env.glow_bloom = 0.25
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	# 奥行きのある暗さを出す軽いフォグ
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.03, 0.06)
	env.fog_density = 0.04
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _build_desk() -> void:
	var desk := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	desk.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.03, 0.04)
	mat.metallic = 0.1
	mat.roughness = 0.35 # 画面光をうっすら反射
	pm.material = mat
	desk.position = Vector3(0, -0.041, 0)
	add_child(desk)


func _build_laptop() -> void:
	# --- 本体(キーボードデッキ) ---
	var deck := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(_kbd_width + 0.35, 0.04, 0.95)
	deck.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.05, 0.05, 0.06)
	dmat.metallic = 0.6
	dmat.roughness = 0.45
	dm.material = dmat
	deck.position = Vector3(0, -0.02, -0.10)
	add_child(deck)

	# --- ヒンジ(画面の回転軸): デッキ奥端 ---
	var hinge := Node3D.new()
	hinge.position = Vector3(0, 0.0, -0.10 - 0.95 / 2.0)
	hinge.rotation_degrees = Vector3(-15, 0, 0) # 垂直からやや奥へ(開き角~105°)
	add_child(hinge)

	# 16:9 ディスプレイ
	var disp_h := 0.98
	var disp_w := disp_h * 16.0 / 9.0
	var bezel := 0.05
	var screen_w := disp_w + bezel * 2.0
	var screen_h := disp_h + bezel * 2.0

	# 画面の裏(ガワ)
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(screen_w, screen_h, 0.03)
	back.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.04, 0.04, 0.05)
	bmat.metallic = 0.6
	bmat.roughness = 0.4
	bm.material = bmat
	back.position = Vector3(0, screen_h / 2.0, 0)
	hinge.add_child(back)

	# 発光ディスプレイ(配信画像を表示・主光源の見た目)
	var disp := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(disp_w, disp_h)
	disp.mesh = qm
	var emat := StandardMaterial3D.new()
	emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var tex := load("res://assets/display_soft.png")
	emat.albedo_texture = tex
	emat.emission_enabled = true
	emat.emission_texture = tex
	emat.emission_energy_multiplier = 1.25
	qm.material = emat
	# QuadMeshは既定で+Zを向く(ヒンジのローカル+Z=キーボード/カメラ側)
	disp.position = Vector3(0, screen_h / 2.0, 0.018)
	hinge.add_child(disp)


func _build_keyboard() -> void:
	var depth_offset := 0.12 # 行全体を少し奥へ(画面との隙間を確保)
	for r in ROWS.size():
		var row: String = ROWS[r]
		# r=0(QWERTY)が奥、r=2(ZXC)が手前になるよう前後を反転
		var z := -float(ROWS.size() - 1 - r) * PITCH - depth_offset
		var x_off: float = ROW_STAGGER[r] * PITCH
		for i in row.length():
			var ch := row[i]
			var x := -_kbd_width / 2.0 + x_off + i * PITCH + PITCH / 2.0
			_make_key(ch, Vector3(x, 0.0, z))


func _make_key(ch: String, base: Vector3) -> void:
	_key_pos[ch] = base
	var key := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(KEY_W, KEY_H, KEY_D)
	key.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.07, 0.085)
	mat.metallic = 0.25
	mat.roughness = 0.5
	bm.material = mat
	key.position = base + Vector3(0, KEY_H / 2.0, 0)
	add_child(key)

	var lbl := Label3D.new()
	lbl.text = ch
	lbl.font_size = 72
	lbl.pixel_size = 0.0011
	# HDRで1.0超の明るさにして発光(ブルーム)させる
	lbl.modulate = Color(0.85, 1.25, 2.1)
	lbl.outline_modulate = Color(0.1, 0.3, 0.6, 0.5)
	lbl.outline_size = 10
	lbl.rotation_degrees = Vector3(-90, 0, 0) # 上面に寝かせる
	lbl.position = base + Vector3(0, KEY_H + 0.002, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(lbl)


func _build_runner() -> void:
	var packed := load("res://assets/runner.glb")
	if packed == null:
		push_warning("runner.glb が未インポートです")
		return
	var runner: Node3D = packed.instantiate()
	runner.name = "Runner"
	add_child(runner)
	_runner = runner

	# キー上に立たせる(高さ~0.22)。ホームポジションの F キーへ。
	var on: Vector3 = _key_pos.get("F", Vector3.ZERO)
	runner.scale = Vector3.ONE * 0.26
	runner.position = on + Vector3(0, KEY_H, 0)
	# 画面(奥=-Z)の方を向いて走る
	runner.rotation_degrees = Vector3(0, 0, 0)

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		var anim_name := ""
		for n in ap.get_animation_list():
			if n.to_lower().ends_with("run") or n.to_lower() == "run":
				anim_name = n
				break
		if anim_name == "" and ap.get_animation_list().size() > 0:
			anim_name = ap.get_animation_list()[0]
		if anim_name != "":
			var a := ap.get_animation(anim_name)
			a.loop_mode = Animation.LOOP_LINEAR
			ap.play(anim_name)


func _build_lights() -> void:
	# 画面からキーボードへ降り注ぐ主光源(配信画像の色味=マゼンタ寄り)
	var spot := SpotLight3D.new()
	spot.light_color = Color(1.0, 0.55, 0.85)
	spot.light_energy = 6.5
	spot.spot_range = 4.0
	spot.spot_angle = 55.0
	spot.spot_attenuation = 1.2
	spot.shadow_enabled = true
	spot.position = Vector3(0, 0.95, -0.55)
	spot.look_at_from_position(spot.position, Vector3(0, 0, -0.05), Vector3.UP)
	add_child(spot)

	# キーの陰影に色を足す弱い補助光(青紫)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.45, 0.4, 0.9)
	fill.light_energy = 1.0
	fill.omni_range = 2.5
	fill.position = Vector3(0.0, 0.5, 0.6)
	add_child(fill)


func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.fov = 58.0
	# キャラの背後やや上から、走る先(画面=奥)を見る三人称追従
	var target := Vector3(0, 0.05, -0.30) # フォールバック
	if _runner != null:
		target = _runner.position
	cam.position = target + Vector3(0.0, 0.40, 0.50)
	add_child(cam)
	cam.look_at(target + Vector3(0.0, 0.08, -0.60), Vector3.UP)
	cam.current = true

	# キャラの背中(カメラ側)を起こす補助光。逆光シルエット化を防ぐ。
	var rim := OmniLight3D.new()
	rim.light_color = Color(0.7, 0.78, 0.95)
	rim.light_energy = 0.7
	rim.omni_range = 2.5
	rim.omni_attenuation = 1.0
	rim.position = target + Vector3(0.0, 0.5, 0.55)
	add_child(rim)
