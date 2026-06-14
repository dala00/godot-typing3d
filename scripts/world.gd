extends Node3D
## Typing3D - MS1 雰囲気シーン
## 真っ暗な部屋にノートPCを置き、ディスプレイの光で照らされた
## 文字入りキーボード(英字26)を構築する。すべてコードから生成する。

const KEYCAP_W := 0.165
const KEYCAP_D := 0.165
const KEYCAP_H := 0.05
const PITCH := 0.19

const ROWS := ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
const ROW_STAGGER := [0.0, 0.5, 1.0] # 横ずらし(キー数)

# 三人称追従カメラのオフセット(キャラ基準)
const CAM_OFFSET := Vector3(0.0, 0.40, 0.50)
const CAM_LOOK := Vector3(0.0, 0.08, -0.60)

# 操作(WASD移動＋スペースジャンプ)パラメータ
const MOVE_SPEED := 0.92      # units/sec
const JUMP_V := 0.98          # 初速
const GRAVITY := 4.4
const STOMP_RADIUS := 0.115   # 着地時にキーを踏んだと判定する半径
const JUMP_BUFFER := 0.13     # 早押しジャンプの受付時間
const COYOTE := 0.10          # 接地を離れてからジャンプ可能な猶予

# スコア
const SCORE_PER := 100        # 1キー正解(×コンボ)
const WORD_BONUS := 500       # 単語クリア

# キーボード全体の基準。X中央=0、Z=0付近に手前行。
var _kbd_width := 10.0 * PITCH
# 各キーの床位置(y=0)。文字 -> Vector3
var _key_pos := {}
var _key_node := {} # 文字 -> MeshInstance3D
var _key_label := {} # 文字 -> Label3D
var _runner: Node3D = null
var _cam: Camera3D = null
var _rim: OmniLight3D = null

# --- ゲーム状態 ---
const LABEL_BASE := Color(0.85, 1.25, 2.1)      # 通常の文字色(青白・発光)
const LABEL_NEXT := Color(2.6, 2.2, 0.4)        # 次に押すキー(金・強発光)
const WORDS := [
	# 3
	"CAT", "DOG", "RUN", "SKY", "FOX", "ZAP", "SUN", "MAP", "BUG", "CUP",
	"HAT", "ICE", "JAM", "KEY", "LOG", "NET", "OWL", "PEN", "RAT", "TOP",
	"VAN", "WAX", "YES", "ZIP", "ARM", "BOX", "EAR", "FAN", "GAP", "JOY",
	# 4
	"JUMP", "GAME", "CODE", "DARK", "GLOW", "KEYS", "FAST", "STAR", "MOON", "TYPE",
	"WAVE", "FIRE", "WIND", "SNOW", "RAIN", "LEAF", "ROCK", "GOLD", "BLUE", "PINK",
	"FROG", "BIRD", "FISH", "LION", "BEAR", "WOLF", "DUCK", "CITY", "ROAD", "SHIP",
	"COIN", "DASH", "GRID", "HERO", "KING", "MAZE", "BEAM", "BOLT", "CAVE", "DUSK",
	# 5
	"GODOT", "PIXEL", "LEVEL", "SCORE", "SPEED", "LIGHT", "NIGHT", "BRAVE", "QUEST", "MAGIC",
	"ROBOT", "LASER", "POWER", "GHOST", "CLOUD", "STORM", "FLAME", "RIVER", "OCEAN", "TIGER",
	"EAGLE", "SNAKE", "PANDA", "HONEY", "CANDY", "DREAM", "SPACE", "EARTH", "PLANT", "MOUSE",
	"SWORD", "SHARP", "QUICK", "JOLLY", "ZEBRA",
	# 6
	"TYPING", "RUNNER", "PLAYER", "JUMPER", "ROCKET", "DRAGON", "KNIGHT", "WIZARD", "PLANET", "GALAXY",
	"SHADOW", "BRIGHT", "FROZEN", "GARDEN", "FOREST", "SILVER", "GOLDEN", "PURPLE", "ORANGE", "CASTLE",
	# 7
	"VICTORY", "THUNDER", "CRYSTAL", "DIAMOND", "JOURNEY", "MACHINE", "PROGRAM", "RAINBOW", "STARGEM", "MONSTER",
	# 8
	"KEYBOARD", "COMPUTER", "MOUNTAIN", "ELEPHANT", "SUNLIGHT", "MOONBEAM", "FIREWORK", "DINOSAUR",
]
var _target := ""
var _char_idx := 0
var _runner_char := "F"
var _highlight_char := ""
var _ui: RichTextLabel = null

# ゲーム進行
var _score := 0
var _combo := 0
var _level := 1
var _time_left := 0.0
var _time_limit := 1.0
var _playing := false
var _game_over := false
var _go_ready := false   # ゲームオーバー後、リトライ受付可能か
var _best := 0
var _ui_score: Label = null
var _ui_time: Label = null
var _ui_pop: Label = null
var _sfx: Node = null
# 操作感
var _jump_buf := 0.0
var _coyote := 0.0

# 操作・物理
const TURN_SPEED := 3.2        # rad/sec (A/D旋回)
var _grounded := true
var _jump_vy := 0.0
var _y_ground := KEYCAP_H
var _bmin := Vector2.ZERO      # 移動可能範囲(x,z)
var _bmax := Vector2.ZERO
var _ap: AnimationPlayer = null

func _ready() -> void:
	_build_environment()
	_build_desk()
	_build_laptop()
	_build_keyboard()
	_build_lights()
	_build_runner()
	_build_camera()
	_build_ui()
	_compute_bounds()
	_sfx = preload("res://scripts/sfx.gd").new()
	add_child(_sfx)
	_start_game()


func _compute_bounds() -> void:
	var first := true
	for ch in _key_pos.keys():
		var p: Vector3 = _key_pos[ch]
		if first:
			_bmin = Vector2(p.x, p.z)
			_bmax = Vector2(p.x, p.z)
			first = false
		else:
			_bmin.x = minf(_bmin.x, p.x)
			_bmin.y = minf(_bmin.y, p.z)
			_bmax.x = maxf(_bmax.x, p.x)
			_bmax.y = maxf(_bmax.y, p.z)
	# キー範囲から少しだけ外に出られる余白
	var m := PITCH * 0.5
	_bmin -= Vector2(m, m)
	_bmax += Vector2(m, m)


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
	dm.size = Vector3(_kbd_width + 0.35, 0.04, 1.15)
	deck.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.05, 0.05, 0.06)
	dmat.metallic = 0.6
	dmat.roughness = 0.45
	dm.material = dmat
	deck.position = Vector3(0, -0.02, -0.20)
	add_child(deck)

	# --- ヒンジ(画面の回転軸): デッキ奥端 ---
	var hinge := Node3D.new()
	hinge.position = Vector3(0, 0.0, -0.20 - 1.15 / 2.0)
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
	var depth_offset := 0.0 # 行全体の前後位置(小さいほど手前=画面から離れる)
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
	bm.size = Vector3(KEYCAP_W, KEYCAP_H, KEYCAP_D)
	key.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.07, 0.085)
	mat.metallic = 0.25
	mat.roughness = 0.5
	bm.material = mat
	key.position = base + Vector3(0, KEYCAP_H / 2.0, 0)
	add_child(key)
	_key_node[ch] = key

	var lbl := Label3D.new()
	lbl.text = ch
	lbl.font_size = 72
	lbl.pixel_size = 0.0011
	# HDRで1.0超の明るさにして発光(ブルーム)させる
	lbl.modulate = LABEL_BASE
	lbl.outline_modulate = Color(0.1, 0.3, 0.6, 0.5)
	lbl.outline_size = 10
	lbl.rotation_degrees = Vector3(-90, 0, 0) # 上面に寝かせる
	lbl.position = base + Vector3(0, KEYCAP_H + 0.002, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(lbl)
	_key_label[ch] = lbl


func _build_runner() -> void:
	var packed := load("res://assets/runner.glb")
	if packed == null:
		push_warning("runner.glb が未インポートです")
		return
	# コントローラ(位置・yaw)＋その子にモデル。
	# モデルの素の正面は+Zなので180°回してコントローラのforward(-Z)に合わせる。
	var model: Node3D = packed.instantiate()
	var runner := Node3D.new()
	runner.name = "Runner"
	add_child(runner)
	runner.add_child(model)
	model.rotation.y = PI
	model.scale = Vector3.ONE * 0.26
	_runner = runner

	# キー上に立たせる。ホームポジションの F キーへ。yaw=0 で -Z(画面方向)。
	var on: Vector3 = _key_pos.get("F", Vector3.ZERO)
	runner.position = on + Vector3(0, KEYCAP_H, 0)
	runner.rotation = Vector3.ZERO

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		_ap = ap
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
			ap.speed_scale = 0.0 # 静止時は止める(移動中のみ動かす)


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
	cam.position = target + CAM_OFFSET
	add_child(cam)
	cam.look_at(target + CAM_LOOK, Vector3.UP)
	cam.current = true
	_cam = cam

	# キャラの背中(カメラ側)を起こす補助光。逆光シルエット化を防ぐ。
	var rim := OmniLight3D.new()
	rim.light_color = Color(0.7, 0.78, 0.95)
	rim.light_energy = 0.7
	rim.omni_range = 2.5
	rim.omni_attenuation = 1.0
	rim.position = target + Vector3(0.0, 0.5, 0.55)
	add_child(rim)
	_rim = rim


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# 読みやすさ用の半透明の帯
	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.45)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 96
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bar)

	var panel := RichTextLabel.new()
	panel.bbcode_enabled = true
	panel.fit_content = true
	panel.scroll_active = false
	panel.autowrap_mode = TextServer.AUTOWRAP_OFF
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-300, 16)
	panel.custom_minimum_size = Vector2(600, 0)
	panel.add_theme_font_size_override("normal_font_size", 44)
	panel.add_theme_font_size_override("bold_font_size", 44)
	layer.add_child(panel)
	_ui = panel

	# スコア(左上)
	var sc := Label.new()
	sc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sc.position = Vector2(22, 14)
	sc.add_theme_font_size_override("font_size", 26)
	layer.add_child(sc)
	_ui_score = sc

	# タイム/レベル(右上)
	var tm := Label.new()
	tm.anchor_left = 1.0
	tm.anchor_right = 1.0
	tm.offset_left = -320
	tm.offset_right = -22
	tm.offset_top = 14
	tm.offset_bottom = 84
	tm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tm.add_theme_font_size_override("font_size", 26)
	layer.add_child(tm)
	_ui_time = tm

	# 中央ポップ(クリア演出など)
	var pop := Label.new()
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pop.add_theme_font_size_override("font_size", 72)
	pop.modulate = Color(1, 1, 1, 0)
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(pop)
	_ui_pop = pop

	# 操作ヒント
	var hint := Label.new()
	hint.text = "A/D 旋回   W/S 前後   SPACE ジャンプで踏む"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	hint.add_theme_font_size_override("font_size", 20)
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.position = Vector2(0, -10)
	layer.add_child(hint)


# ---------------- ゲームループ ----------------

func _start_game() -> void:
	_score = 0
	_combo = 0
	_level = 1
	_next_word()


func _pick_word() -> String:
	var target_len: int = clampi(3 + int(_level / 2.0), 3, 8)
	var cands := WORDS.filter(func(s): return abs(s.length() - target_len) <= 1)
	if cands.is_empty():
		cands = WORDS
	var w: String = cands[randi() % cands.size()]
	if w == _target and cands.size() > 1:
		w = cands[(cands.find(w) + 1) % cands.size()]
	return w


func _next_word() -> void:
	_target = _pick_word()
	_char_idx = 0
	# キー間を歩いて移動する時間を見込みつつ、ややタイトに(レベルで微減)
	var per_char: float = clampf(2.6 - _level * 0.13, 1.4, 2.6)
	_time_limit = 2.0 + _target.length() * per_char
	_time_left = _time_limit
	_playing = true
	_update_ui()
	_update_hud()
	_set_next_highlight()


func _set_next_highlight() -> void:
	# 直前のハイライトを戻す
	if _highlight_char != "" and _key_label.has(_highlight_char):
		_key_label[_highlight_char].modulate = LABEL_BASE
	_highlight_char = ""
	if _char_idx < _target.length():
		var ch := _target[_char_idx]
		if _key_label.has(ch):
			_key_label[ch].modulate = LABEL_NEXT
			_highlight_char = ch


func _update_ui() -> void:
	if _ui == null:
		return
	var done := _target.substr(0, _char_idx)
	var cur := ""
	var rest := ""
	if _char_idx < _target.length():
		cur = _target[_char_idx]
		rest = _target.substr(_char_idx + 1)
	var bb := "[center]"
	bb += "[color=#7fff9f]" + done + "[/color]"
	bb += "[color=#ffe14d][b]" + cur + "[/b][/color]"
	bb += "[color=#5a6472]" + rest + "[/color]"
	bb += "[/center]"
	_ui.text = bb


func _forward() -> Vector3:
	# rotation.y=0 で -Z(画面方向)を向く
	var y := _runner.rotation.y
	return Vector3(-sin(y), 0.0, -cos(y))


func _physics_process(delta: float) -> void:
	if _runner == null:
		return
	if _game_over:
		_check_restart()
		return
	# A/D = 旋回(向き変更)
	var turn := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		turn += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		turn -= 1.0
	_runner.rotation.y += turn * TURN_SPEED * delta

	# W/S = 向き基準の前後移動
	var mv := 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		mv += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		mv -= 0.6 # 後退は遅め
	var pos: Vector3 = _runner.position
	if mv != 0.0:
		pos += _forward() * (mv * MOVE_SPEED * delta)
	pos.x = clampf(pos.x, _bmin.x, _bmax.x)
	pos.z = clampf(pos.z, _bmin.y, _bmax.y)

	# ジャンプバッファ(早押し受付)とコヨーテタイム
	if Input.is_key_pressed(KEY_SPACE):
		_jump_buf = JUMP_BUFFER
	else:
		_jump_buf = maxf(0.0, _jump_buf - delta)
	if _grounded:
		_coyote = COYOTE
	else:
		_coyote = maxf(0.0, _coyote - delta)

	# ジャンプ発動
	if _jump_buf > 0.0 and _coyote > 0.0:
		_jump_vy = JUMP_V
		_grounded = false
		_jump_buf = 0.0
		_coyote = 0.0
		if _sfx:
			_sfx.play("jump")

	# 重力/着地
	if not _grounded:
		_jump_vy -= GRAVITY * delta
		pos.y += _jump_vy * delta
		if pos.y <= _y_ground:
			pos.y = _y_ground
			_grounded = true
			_runner.position = pos
			_on_land()
			_update_anim(mv, turn)
			return
	else:
		pos.y = _y_ground
	_runner.position = pos
	_update_anim(mv, turn)

	# 制限時間
	if _playing:
		_time_left -= delta
		if _time_left <= 0.0:
			_time_left = 0.0
			_on_time_up()
		_update_hud()


func _update_anim(mv: float, turn: float) -> void:
	if _ap == null:
		return
	# 移動・旋回・空中では走り再生、静止時は停止
	var active := (mv != 0.0) or (turn != 0.0) or (not _grounded)
	_ap.speed_scale = 1.0 if active else 0.0


func _on_land() -> void:
	var ch := _key_under_runner()
	if ch == "":
		return
	_runner_char = ch
	_key_depress(ch)
	if _sfx:
		_sfx.play("stomp")
	if not _playing:
		return
	if ch == _highlight_char:
		_combo += 1
		_score += SCORE_PER * _combo
		_flash_label(ch, Color(3.0, 3.0, 3.0)) # 正解フラッシュ(白)
		if _sfx:
			_sfx.play("ok")
		_update_hud()
		_advance()
	else:
		# お手つき: コンボ消滅＋時間ペナルティ
		_combo = 0
		_time_left = maxf(0.0, _time_left - 1.0)
		_flash_label(ch, Color(3.0, 0.35, 0.35))
		if _sfx:
			_sfx.play("err")
		_update_hud()


func _advance() -> void:
	_char_idx += 1
	_update_ui()
	_set_next_highlight()
	if _char_idx >= _target.length():
		_on_word_clear()


func _on_word_clear() -> void:
	_playing = false
	var time_bonus := int(_time_left * 50.0)
	var gained := WORD_BONUS + time_bonus
	_score += gained
	_level += 1
	if _sfx:
		_sfx.play("clear")
	_popup("CLEAR!  +" + str(gained), Color(0.6, 1.0, 0.7))
	_update_hud()
	var t := create_tween()
	t.tween_interval(0.95)
	t.tween_callback(_next_word)


func _on_time_up() -> void:
	if not _playing:
		return
	_game_over_now()


func _game_over_now() -> void:
	_playing = false
	_game_over = true
	_go_ready = false
	_combo = 0
	_best = maxi(_best, _score)
	if _sfx:
		_sfx.play("err")
	_update_hud()
	if _ui_pop:
		_ui_pop.text = "GAME OVER\nSCORE %d    BEST %d\n\n[ SPACE ] でリトライ" % [_score, _best]
		_ui_pop.add_theme_font_size_override("font_size", 56)
		_ui_pop.modulate = Color(1.0, 0.55, 0.55, 1.0)
	var t := create_tween()
	t.tween_interval(0.7)
	t.tween_callback(func(): _go_ready = true)


func _check_restart() -> void:
	if _go_ready and (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)):
		_restart()


func _restart() -> void:
	_game_over = false
	_go_ready = false
	if _ui_pop:
		_ui_pop.modulate = Color(1, 1, 1, 0)
	# ハイライトを消す
	if _highlight_char != "" and _key_label.has(_highlight_char):
		_key_label[_highlight_char].modulate = LABEL_BASE
	_highlight_char = ""
	# 主人公をホームへ
	_runner.position = _key_pos.get("F", Vector3.ZERO) + Vector3(0, KEYCAP_H, 0)
	_runner.rotation = Vector3.ZERO
	_grounded = true
	_jump_vy = 0.0
	_start_game()


func _update_hud() -> void:
	if _ui_score:
		_ui_score.text = "SCORE %d" % _score
		if _combo >= 2:
			_ui_score.text += "    COMBO x%d" % _combo
	if _ui_time:
		_ui_time.text = "LV %d\nTIME %0.1f" % [_level, _time_left]
		# 残り時間で色を変える
		var r: float = clampf(_time_left / maxf(0.01, _time_limit), 0.0, 1.0)
		_ui_time.modulate = Color(1.0, 0.4 + 0.6 * r, 0.4 + 0.6 * r) if r < 0.4 else Color(1, 1, 1)


func _popup(text: String, col: Color) -> void:
	if _ui_pop == null:
		return
	_ui_pop.add_theme_font_size_override("font_size", 72)
	_ui_pop.text = text
	_ui_pop.modulate = Color(col.r, col.g, col.b, 1.0)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(_ui_pop, "modulate:a", 0.0, 0.5)


func _key_under_runner() -> String:
	var p: Vector3 = _runner.position
	var best := ""
	var bestd := STOMP_RADIUS
	for ch in _key_pos.keys():
		var kp: Vector3 = _key_pos[ch]
		var d := Vector2(p.x - kp.x, p.z - kp.z).length()
		if d < bestd:
			bestd = d
			best = ch
	return best


func _key_depress(ch: String) -> void:
	if not _key_node.has(ch):
		return
	var key: MeshInstance3D = _key_node[ch]
	var base_y: float = _key_pos[ch].y + KEYCAP_H / 2.0
	var tw := create_tween()
	tw.tween_property(key, "position:y", base_y - 0.025, 0.05)
	tw.tween_property(key, "position:y", base_y, 0.09)


func _flash_label(ch: String, col: Color) -> void:
	if not _key_label.has(ch):
		return
	var lbl: Label3D = _key_label[ch]
	lbl.modulate = col
	var tw := create_tween()
	# 踏んだキーは次の対象ではなくなるので通常色に戻す
	tw.tween_property(lbl, "modulate", LABEL_BASE, 0.3)


func _process(delta: float) -> void:
	if _cam == null or _runner == null:
		return
	var rp: Vector3 = _runner.position
	var fwd := _forward()
	var desired := rp + Vector3(0.0, CAM_OFFSET.y, 0.0) - fwd * CAM_OFFSET.z
	var k: float = clampf(delta * 7.0, 0.0, 1.0)
	_cam.position = _cam.position.lerp(desired, k)
	_cam.look_at(rp + Vector3(0.0, CAM_LOOK.y, 0.0) + fwd * (-CAM_LOOK.z), Vector3.UP)
	if _rim != null:
		_rim.position = rp + Vector3(0.0, 0.5, 0.0) - fwd * 0.55
