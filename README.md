# タイピング3D

小さな主人公が**実物のPCキーボードの上を走り回り**、お題の文字キーまで移動して**ジャンプで踏んで打鍵**する3Dタイピング・アクション。真っ暗な部屋でノートPCのディスプレイだけが光る雰囲気。

Godot 4.6.3 / GL Compatibility。

## 操作
- `A` / `D` … 旋回（向き変更）
- `W` / `S` … 前後移動（向き基準）
- `SPACE` … ジャンプ（着地でそのキーを踏む）
- お題単語の**次に踏むキーが金色**にハイライト。正しいキーを踏むと進行、違うキーはお手つき（コンボ消滅＋時間ペナルティ）。
- 単語クリアでボーナス、レベルが上がると単語が長く・制限時間がタイトに。**時間切れでゲームオーバー**（`SPACE`でリトライ）。

## クレジット

### BGM
- **プレゼントボックス feat.音影カナ** / 作者: **Addpico**
- 配布: DOVA-SYNDROME https://dova-s.jp/bgm/detail/13817
- 利用条件: https://dova-s.jp/creator/detail/162 ／ 規約: https://dova-s.jp/contents/terms ／ ライセンス: https://dova-s.jp/contents/license
- ニコニコ親作品ID: `nc232337`
- ファイル `assets/bgm.mp3` は**再配布回避のためgit非追跡**。DOVAから各自ダウンロードして配置（無い場合はBGM無しで動作）。

### 効果音
- すべてコードでPCM合成（`scripts/sfx.gd`）。外部素材なし。

### フォント
- **Sawarabi Gothic**（SIL Open Font License）。使用文字のみにサブセット化して同梱（`fonts/SawarabiGothic-subset.ttf`、ライセンス: `fonts/OFL.txt`）。

### その他
- ディスプレイ表示画像 `assets/display.png` はユーザー提供素材。

## Web(HTML5)公開
- 書き出し: `tools/export_web.ps1`（→ `exports/typing3d.html`）。日本語フォント埋め込み済み、BGMは初回操作で再生開始。
- `assets/bgm.mp3` はローカルに配置が必要（git非追跡）。無くてもBGM無しで動作。
