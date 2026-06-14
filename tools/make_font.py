# scripts/*.gd で使う文字だけに日本語フォントをサブセット化する(Web書き出し用・豆腐回避)。
# 原本: fonts/_src/SawarabiGothic-Regular.ttf  ->  fonts/SawarabiGothic-subset.ttf
# 文字を増やしたら再実行すればよい(.gd を走査するだけ)。
#   python tools/make_font.py
import glob
import os
from fontTools.subset import Subsetter, Options
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "fonts", "_src", "SawarabiGothic-Regular.ttf")
DST = os.path.join(ROOT, "fonts", "SawarabiGothic-subset.ttf")

chars = set(chr(c) for c in range(0x20, 0x7F))  # ASCII印字可能
# 共通の日本語記号
chars.update("　、。！？・ー％／（）")
# .gd 内の全文字(日本語UI文字列を取りこぼさない)
for path in glob.glob(os.path.join(ROOT, "scripts", "*.gd")):
    with open(path, encoding="utf-8") as fh:
        chars.update(fh.read())
chars = {c for c in chars if ord(c) >= 0x20}

text = "".join(sorted(chars))
opt = Options()
opt.recalc_bounds = True
opt.name_IDs = ["*"]
opt.name_legacy = True
opt.glyph_names = False
font = TTFont(SRC)
sub = Subsetter(options=opt)
sub.populate(text=text)
sub.subset(font)
font.save(DST)
print("chars=%d  out=%d bytes  -> %s" % (len(chars), os.path.getsize(DST), DST))
