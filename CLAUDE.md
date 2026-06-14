# CLAUDE.md — typing-3d

## ゲーム概要
「タイピング3D」: 小さい主人公が**実物のPCキーボードの上を走り**、該当キーの上で**ジャンプして打鍵**する3Dタイピングゲーム。
舞台は真っ暗な部屋に置かれたノートPCで、**ディスプレイの光**が主光源。各キー上面には文字が書いてあり発光する。

## 技術スタック
- Godot **4.6.3** stable / レンダラ **GL Compatibility**（軽量・Web書き出し志向）/ 物理 Jolt
- Godot本体パスは `tools/.godot-path`（gitignore済）か環境変数 `GODOT_BIN` で解決（`import.ps1` が参照）
- 3Dアセットは **Blender (MCP経由)** で生成 → glTF(GLB) で取り込み

## 構成方針（重要）
シーンは「**薄い .tscn ＋ コード生成**」。`scenes/World.tscn` は空の Node3D ＋ `scripts/world.gd` のみ。
`world.gd` が `_ready()` で **環境・机・ノートPC・キーボード・ライト・主人公・カメラを全部コードから生成**する。
見た目の調整は基本 `world.gd` を編集して目視ループで詰める。

### world.gd の構造
- `_build_environment` 真っ暗背景＋弱い環境光＋glow(ブルーム)＋薄いフォグ
- `_build_desk` / `_build_laptop` 机とノートPC本体・ヒンジ・画面
  - ディスプレイは QuadMesh に `assets/display_soft.png` を unshaded＋emission で表示（＝光る画面）
- `_build_keyboard` / `_make_key` 英字26キー生成。**行は QWERTY=奥、ZXC=手前**（実キーボードと前後一致）。文字は Label3D を上面に寝かせ、HDR(modulate>1)で発光。`_key_pos[文字]=床位置` を記録。
- `_build_runner` `assets/runner.glb` を**ラッパーNode3D**の子として配置(モデルは素の正面が+Zなので180°回して-Zへ)。F キー上スタート。`Run`アニメはループだが`speed_scale`で移動中のみ動かす
- `_build_lights` 画面からの主光源(マゼンタ寄りSpot)＋補助Omni
- `_build_camera` **キャラ背後やや上からの三人称追従**（旋回に合わせて回り込む。`_forward()`基準）＋逆光防止のrim光

## 操作・ゲームループ
**タンク操作**: `A/D`=旋回(向き変更)、`W/S`=向き基準の前後移動、`SPACE`=ジャンプ。
お題の単語(`WORDS`)を上部UIに表示し、**次に踏むキーを金色ハイライト**。プレイヤーがキャラを動かして対象キーへ行き、**ジャンプ→着地で踏んだキーを判定**(`_key_under_runner`が`STOMP_RADIUS`内の最寄りキー)。正解なら白フラッシュ＆進行、違うキーは赤フラッシュ。単語完了で次の単語へ。
- 物理は`_physics_process`(移動/旋回/重力/着地)、カメラ追従は`_process`。移動範囲は`_compute_bounds`でキー配置から算出。
- 主要パラメータ: `MOVE_SPEED` `TURN_SPEED` `JUMP_V` `GRAVITY` `STOMP_RADIUS`。
- 操作感: ジャンプバッファ(`JUMP_BUFFER`)＋コヨーテ(`COYOTE`)。

## スコア・難易度・演出
- スコア: 正解で `SCORE_PER × コンボ`、お手つきでコンボ消滅＋時間-1秒。単語クリアで `WORD_BONUS`＋残り時間ボーナス。
- 制限時間: `_next_word`で `3.0 + 文字数 × per_char`(per_charはレベルで微減)。**キー間を歩く時間込みで長めに**(短すぎ厳禁。2026-06-14の調整)。
- 難易度: クリアごと`_level++`。`_pick_word`が`_level`で単語長を増やし、`per_char`を減らす。
- 効果音は `scripts/sfx.gd`(PCM合成・アセット0)。jump/stomp/ok/err/clear を起動時生成しキャッシュ、`_sfx.play(name)`で再生。
- HUD: 左上スコア＆コンボ／右上LV＆残り時間(残少で赤)／中央ポップ(CLEAR等)。
- **ゲームオーバー**: 制限時間切れで終了(`_game_over_now`)。最終スコアとセッションベストを表示し、`SPACE`/`ENTER`でリトライ(`_restart`)。リトライ受付は0.7秒の猶予後。

## アセット
- `assets/blend/runner.blend` 主人公のソース（Blender 5.x）。ちびキャラ（大頭＋胴＋腕脚）＋11ボーンのアーマチュア。**リジッドスキン**（各パーツを頂点グループ weight=1 で1ボーンに割当→join）。`Run` アクション（24fps, 1–20フレームループ。コンタクト/パッシング×2）。**肘は前曲げ・膝は後ろ曲げ**（人体準拠）。
- `assets/runner.glb` 上記の書き出し（`use_selection`, yup, ACTIONS）
- `assets/display.png` ディスプレイ原画 / `assets/display_soft.png` それを縮小→拡大でぼかした版（至近距離風）。**表示に使うのは soft 版**。
- `assets/bgm.mp3` BGM(DOVA素材, Addpico「プレゼントボックス feat.音影カナ」)。`_build_bgm`でループ再生(volume_db -12)。**再配布回避でgit非追跡**(`.gitignore`)、無ければ無音で動作。クレジットは `README.md`。

## 開発ワークフロー（tools/ スクリプト）
許可プロンプトを減らすため、よく使う操作は **`tools/` の固定引数スクリプト**にしてある。引数なしで呼べば既定で動く。
- `tools/cap.ps1` 実行中ゲーム窓 `(DEBUG)` のスクショ→`tools/shot.png`（待機内蔵・PrintWindow→失敗時CopyFromScreen）
- `tools/import.ps1` Godotヘッドレス再インポート（新規 .glb/.png を取り込む。**新アセット追加後は必須**）
- `tools/crop.ps1` `shot.png` の一部を拡大→`tools/crop.png`（キャラ等の細部確認用）
- `tools/blur.ps1` 画像を縮小→拡大でぼかす（ディスプレイ画像の再生成用）
- `tools/sendkeys.ps1` ゲーム窓へキー入力（`-Keys "godot"`で文字列、`-Key W -Hold 700`で長押し）。操作検証用

典型ループ: `world.gd`編集 → `mcp__godot__run_project` → `tools/cap.ps1` で確認 → 直す → `mcp__godot__stop_project`。
パースエラーは `mcp__godot__get_debug_output` に行番号付きで出る。

## 注意・落とし穴
- スクショは必ず `(DEBUG)` 窓を狙う（`cap.ps1` の既定）。`typing3d` で曖昧一致するとエディタ本体を撮る。
- GodotはBlend直接インポートを試みて失敗するので、`project.godot` で `import/blender/enabled=false`。`assets/blend/` と `tools/` には `.gdignore` を置いてGodogの索引から除外。
- Blender 5.x の新アニメAPIでは `Action.fcurves` が無い（layers/strips経由）。`keyframe_insert` 自体は従来通り使える。
- **定数名の衝突注意**: Godotの組み込みキー定数 `KEY_W` `KEY_A` … `KEY_H` `KEY_SPACE` 等は global。自前の定数を `KEY_*` で作ると衝突して `Input.is_key_pressed()` にfloatを渡すバグになる。キー寸法は `KEYCAP_W/D/H` という名前にしてある。
- **型推論の注意**: `lerp()` `max()` `floor()` などは Variant を返すことがあり `var x := ...` で「型推論できない」エラーになる。`var x: float = ...` と明示するか `maxi/maxf/clampf` 等の型付き関数を使う。
- `.claude/settings.local.json`（マシン固有の絶対パス許可）と `tools/shot.png`/`crop.png` は gitignore 済み。
