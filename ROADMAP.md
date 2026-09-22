# タスク天国：制作・検証記録

このプロジェクトは2026-09-22のユーザー添付仕様書による独立した新作です。Ring SurvivorsのM03以降とは別工程です。

| 工程 | 依存 | 完了条件 | 状態 |
|---|---|---|---|
| T01 ゲーム本編 | 仕様全文 | 説明・練習・3ステージ・時間判定・入力・結果・再挑戦 | 完了 |
| T02 表現・音 | T01 | オリジナル図版・4音色・BGM同期・反応・日本語表示 | 完了 |
| T03 Web検証 | T01/T02 | Chromeで全編・タッチ・横縦表示・音声確認 | 完了 |
| T04 公開 | T03 | 専用GitHub、push、Pages、公開URLでプレイ確認 | 完了 |

仮数値：TASK初期40、正解+2.5、MISS-6、クリア70、15MISSで失敗。判定幅は仕様どおり90/180/280ms。難易度数値は `data/settings.json` に集約。

検証証拠：`tests/artifacts/unit_integration.json`（148項目成功）、`tests/artifacts/export.log`、Chrome画面は `tests/artifacts/browser_*.png`。

完了証拠：`tests/artifacts/browser_full.json` は公開URLでの全編114 PERFECT、GOOD/OK/誤番号MISS、15MISSでの失敗、タッチ4入力、一時停止中の時計差0、実行エラー0を記録。Pages公開成功：Actions run `35719632876`。詳細と実機未検証の範囲は `VERIFICATION.md`。
