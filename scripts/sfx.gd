extends Node
## 効果音をPCMでコード合成(音声アセット0)。起動時に全SFXを生成してキャッシュ。
## 参考: godot-procedural-sfx パターン。16bit/mono/22050Hz。

const SR := 22050
var _cache := {}

func _ready() -> void:
	_cache["jump"] = _make([
		{"freq": 320.0, "freq2": 620.0, "dur": 0.12, "wave": "tri", "vol": 0.45, "env": "attackdecay"},
	])
	_cache["stomp"] = _make([
		{"freq": 150.0, "freq2": 80.0, "dur": 0.09, "wave": "square", "vol": 0.5, "env": "decay"},
		{"freq": 0.0, "dur": 0.02, "wave": "noise", "vol": 0.25, "env": "decay"},
	])
	_cache["ok"] = _make([
		{"freq": 660.0, "dur": 0.05, "wave": "tri", "vol": 0.45, "env": "flat"},
		{"freq": 990.0, "dur": 0.09, "wave": "tri", "vol": 0.45, "env": "decay"},
	])
	_cache["err"] = _make([
		{"freq": 180.0, "freq2": 120.0, "dur": 0.18, "wave": "square", "vol": 0.45, "env": "decay"},
	])
	_cache["clear"] = _make([
		{"freq": 660.0, "dur": 0.10, "wave": "sine", "vol": 0.5, "env": "attackdecay"},
		{"freq": 880.0, "dur": 0.10, "wave": "sine", "vol": 0.5, "env": "attackdecay"},
		{"freq": 1175.0, "dur": 0.18, "wave": "sine", "vol": 0.5, "env": "decay"},
	])


func play(sfx_name: String) -> void:
	if not _cache.has(sfx_name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = _cache[sfx_name]
	add_child(p)
	p.play()
	p.finished.connect(func(): p.queue_free())


func _osc(wave: String, phase: float) -> float:
	var f: float = phase - floor(phase) # 0..1
	match wave:
		"square":
			return 1.0 if f < 0.5 else -1.0
		"tri":
			return 4.0 * abs(f - 0.5) - 1.0
		"saw":
			return 2.0 * f - 1.0
		"noise":
			return randf_range(-1.0, 1.0)
		_:
			return sin(TAU * phase)


func _make(segs: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	var phase := 0.0
	for s in segs:
		var freq: float = s.get("freq", 440.0)
		var freq2: float = s.get("freq2", freq)
		var dur: float = s.get("dur", 0.1)
		var wave: String = s.get("wave", "sine")
		var vol: float = s.get("vol", 0.6)
		var env: String = s.get("env", "decay")
		var n := int(dur * SR)
		for i in n:
			var t: float = float(i) / float(maxi(1, n))
			var fr: float = lerp(freq, freq2, t)
			phase += fr / SR
			var smp := _osc(wave, phase)
			var e := 1.0
			match env:
				"decay":
					e = 1.0 - t
				"attackdecay":
					e = sin(PI * t)
				_:
					e = 1.0
			var v: float = clampf(smp * vol * e, -1.0, 1.0)
			var iv := int(v * 32767.0)
			data.append(iv & 0xFF)
			data.append((iv >> 8) & 0xFF)
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = SR
	st.stereo = false
	st.data = data
	return st
