# 動作確認記録

2026-09-22 / Godot 4.5.1 stable / Windows / Chrome / Web Release

## ローカル確認

- Godotインポート・リリースWeb出力成功。パース・実行エラーなし。
- `tests/test_game.gd`：**148 checks / 0 failures**。判定境界±90/180/280ms、二重入力、誤番号、押し忘れ、入力補正、クリア境界、全編スコア、15MISS、リトライ、一時停止、タイトル帰還を検証。
- Chromeの実際のキーボードイベントで練習4ノート、本編114ノートを通して入力。全114 PERFECT、11400点、TASK100%、クリア画面へ到達。
- 続けてRETRY、入力しない経路で15MISS・ゲームオーバーへ到達し、TITLEへ帰還。
- Web Audio：AudioContext `running`、13バッファ読込、48kHz。出力グラフのサンプル最大絶対振幅0.260を確認（無音でない）。これは機械的な音声出力確認であり、人間による聴感評価とは別。
- Chrome 844×390、タッチ有効：4画面に実タッチイベントを送り練習全4 PERFECT。横画面の入力領域は約104×112px。
- Chrome 390×844：縦向き案内を確認。初回の小さな文字を修正し、実画面22px相当とした。
- ブラウザのJavaScript/Godot実行エラー：0件。

証拠：`tests/artifacts/unit_integration.json`、`browser_full.json`、`export.log`、`browser_title.png`、`browser_help.png`、`browser_game.png`、`browser_clear.png`、`browser_fail.png`、`mobile_touch_pass.png`、`mobile_portrait.png`。

## 公開URL

- 公開先： https://badgio0906.github.io/tachibana-task-heaven/
- リポジトリ： https://github.com/Badgio0906/tachibana-task-heaven
- Pages成功： https://github.com/Badgio0906/tachibana-task-heaven/actions/runs/35719632876
- 公開URLを新しいChromeコンテキストで開いて初回START→説明→練習→全3ステージを再検証。114 PERFECT、11400点、TASK100%、クリア。
- 一時停止の前後で音声時計差0秒。再開後の入力も全PERFECT。
- RETRY後、意図的に入力を遅らせGOOD・OKを各1、誤番号でMISSを1確認。その後押し忘れにより累計15MISS、110点のゲームオーバー。TITLE帰還も確認。
- 同じ公開URLで844×390タッチ練習全4 PERFECT。390×844の案内は修正後の大きな文字で確認。
- 公開リリースでF4を押してもタイトルのまま。強制クリア無効。
- 音声出力振幅0.160、AudioContext running、13音源読込、ブラウザエラー0。
- `browser_full.json` は公開版の記録、`browser_local_full.json` は先行ローカル検証記録。
- 公開前の最初のActionsはPages未有効化で失敗したが、Pagesを有効化して次の実行で解消済み。

公開通し検証後、判定幅・クリア率・MISS上限の説明表示も設定JSONを読むよう統一。既定値・ゲーム挙動は変更していない。再エクスポートと最終ページ表示で確認。

## 確認範囲

ブラウザ入力は譜面時刻に合わせた自動操作。人間の初見難易度・爽快感の評価、実機iPhone/Safari・Android端末、Bluetoothイヤホン固有の音声遅延は未検証。設定画面で±200msの入力補正と音量を変更できる。

通常のユーザーセーブやRing Survivorsの手動プレイログを自動検証で変更していない。Godot検証は `--verify` で保存を無効化、ブラウザ検証は隔離された一時ブラウザコンテキストで実行。

## 2026-09-22 キャラクターのドット絵化

- ユーザー指定に従い、立花さん6状態・女性上司6状態を96×128の自作ドット絵へ置換。輪郭・顔・手足・配色を統一。
- SVGは整数ピクセルの色を保持する形式で保存。GodotのNEAREST表示と縦横比保持でぼけ・横伸びを防止。
- 全12状態の一覧：`tests/artifacts/pixel_characters.png`。
- Chrome全編：114 PERFECT、11400点、TASK100%、クリア。GOOD/OK/誤番号MISS、15MISSでの失敗、リトライ、タッチ練習4PERFECT、一時停止の時計差0。実行エラー0。
- タイトル、本編、クリア、失敗、844×390横画面と390×844縦案内を目視確認。記録：`tests/artifacts/pixel_v2/`。
- 上司の指示ポーズは開いた手、喜びポーズは親指が判別できる形に仕上げ、12状態一覧で再確認。
- 譜面・判定・音源・スコア処理は未変更。更新したWeb出力とソースを同じコミットで公開。

## 2026-09-23 視認性・OJTモード

- 机の奥行きが見える浅い斜め俯瞰の構図に変更し、前景の立花さんを拡大。操作画面の下端だけが体に一部隠れる。4画面へのクリック・タッチ判定はそのまま。
- 薄緑の4点表示を廃止。回答開始の譜面時刻を基準に「入力まであと2拍」「あと1拍」「今！ 入力スタート」を高コントラストで表示。±280msの早め入力が可能な間も、表示上の開始時刻は前倒ししない。
- OJTモードでは次の未処理ノートを1拍前から番号・名前・画面枠で予告。説明画面・一時停止画面でON/OFFを切替でき、専用設定に保存。判定・スコアは不変。
- Godot統合テスト **154 checks / 0 failures**。予告の開始・対象・OFF・得点非干渉も確認：`tests/artifacts/unit_integration.json`。
- ローカルChrome全編：練習4入力、本編114 PERFECT、11400点・クリア、GOOD/OK/誤番号MISS、15MISSで失敗、844×390タッチ練習4 PERFECT、縦画面案内、実行エラー0：`tests/artifacts/ojt_v1/browser_full.json`。
- OJT実ブラウザ：2拍カウント、1拍前の予告、対象画面枠、PERFECT入力、一時停止でのOFF→ONを確認。スクリーンショットと結果は `tests/artifacts/ojt_v1/`。通常のユーザー設定は変更しない一時ブラウザコンテキストを使用。
