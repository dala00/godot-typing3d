# CLAUDE.md — typing-3d

## ゲーム概要
「タイピング3D」: 小さい主人公が**実物のPCキーボードの上を走り**、該当キーの上で**ジャンプして打鍵**する3Dタイピングゲーム。
舞台は真っ暗な部屋に置かれたノートPCで、**ディスプレイの光**が主光源。各キー上面には文字が書いてあり発光する。

## 技術スタック
- Godot **4.6.3** stable / レンダラ **GL Compatibility**（軽量・Web書き出し志向）/ 物理 Jolt
- Godot本体: `D:\users\documents\programs\godot\4.6.3\Godot_v4.6.3-stable_win64_console.exe`
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
- `_build_runner` `assets/runner.glb` を instantiate し F キー上に配置、`Run` アニメをループ再生
- `_build_lights` 画面からの主光源(マゼンタ寄りSpot)＋補助Omni
- `_build_camera` **キャラ背後やや上からの三人称追従**（走る先＝画面方向を見る）＋逆光防止のrim光

## アセット
- `assets/blend/runner.blend` 主人公のソース（Blender 5.x）。ちびキャラ（大頭＋胴＋腕脚）＋11ボーンのアーマチュア。**リジッドスキン**（各パーツを頂点グループ weight=1 で1ボーンに割当→join）。`Run` アクション（24fps, 1–20フレームループ。コンタクト/パッシング×2）。**肘は前曲げ・膝は後ろ曲げ**（人体準拠）。
- `assets/runner.glb` 上記の書き出し（`use_selection`, yup, ACTIONS）
- `assets/display.png` ディスプレイ原画 / `assets/display_soft.png` それを縮小→拡大でぼかした版（至近距離風）。**表示に使うのは soft 版**。

## 開発ワークフロー（tools/ スクリプト）
許可プロンプトを減らすため、よく使う操作は **`tools/` の固定引数スクリプト**にしてある。引数なしで呼べば既定で動く。
- `tools/cap.ps1` 実行中ゲーム窓 `(DEBUG)` のスクショ→`tools/shot.png`（待機内蔵・PrintWindow→失敗時CopyFromScreen）
- `tools/import.ps1` Godotヘッドレス再インポート（新規 .glb/.png を取り込む。**新アセット追加後は必須**）
- `tools/crop.ps1` `shot.png` の一部を拡大→`tools/crop.png`（キャラ等の細部確認用）
- `tools/blur.ps1` 画像を縮小→拡大でぼかす（ディスプレイ画像の再生成用）

典型ループ: `world.gd`編集 → `mcp__godot__run_project` → `tools/cap.ps1` で確認 → 直す → `mcp__godot__stop_project`。
パースエラーは `mcp__godot__get_debug_output` に行番号付きで出る。

## 注意・落とし穴
- スクショは必ず `(DEBUG)` 窓を狙う（`cap.ps1` の既定）。`typing3d` で曖昧一致するとエディタ本体を撮る。
- GodotはBlend直接インポートを試みて失敗するので、`project.godot` で `import/blender/enabled=false`。`assets/blend/` と `tools/` には `.gdignore` を置いてGodogの索引から除外。
- Blender 5.x の新アニメAPIでは `Action.fcurves` が無い（layers/strips経由）。`keyframe_insert` 自体は従来通り使える。
- `.claude/settings.local.json`（マシン固有の絶対パス許可）と `tools/shot.png`/`crop.png` は gitignore 済み。
