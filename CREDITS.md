# 素材とライセンス

- キャラクター：本プロジェクト用に直接描き起こした96×128のオリジナルドット絵。生成元 `tools/pixel_characters.py`。整数ピクセルの配色・輪郭をSVGに保存し、ゲームでは補間せず表示。全12状態で人物と衣装を統一。
- オフィス、モニター、UI、アイコン：オリジナルSVGおよびGodot描画。生成元 `tools/build_assets.py` と `scripts/office_view.gd`。
- BGM、タンバリン、トライアングル、シンバル、バスドラム、エラー音、風、ジングル：本プロジェクト用に数式合成したオリジナル音源。外部楽曲・録音・サンプルは使用していません。生成元 `tools/build_assets.py`。
- 日本語フォント：**Noto Sans JP Regular**（Noto CJK / Google・Adobe他の貢献者）。[公式配布元](https://github.com/notofonts/noto-cjk/tree/main/Sans/SubsetOTF/JP)。**SIL Open Font License 1.1**。同梱原文：`assets/fonts/OFL.txt`。フォントは無改変で同梱しています。
- ゲームエンジン：**Godot Engine 4.5.1**。[MIT Licenseと第三者ライセンス](https://godotengine.org/license/)。著作権表示：Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur。`GODOT_LICENSE.txt` にMIT本文を同梱。
- 開発用音源生成：NumPy（BSD-3-Clause）。ブラウザ検証：Playwright（Apache-2.0）。ゲーム配信にこれらの開発ツールは含めません。

「LINE」「Excel」は業務の呼び名として用いています。実在サービスのロゴ・画面のコピーは使用せず、提携や公式作品であることを示すものではありません。
