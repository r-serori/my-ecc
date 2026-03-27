---
description: "ECC component installer. Use /ecc-bootstrap, /ecc-configure, or /ecc-evolve directly."
---

# ECC Setup — Command Router

`$ARGUMENTS` was provided to this command.

If `$ARGUMENTS` contains "init", tell the user:
「`/ecc-init` コマンドに移行しました。`/ecc-init` を実行してください。」

If `$ARGUMENTS` contains "bootstrap", tell the user:
「`/ecc-bootstrap` コマンドに移行しました。`/ecc-bootstrap` を実行してください。」

If `$ARGUMENTS` contains "configure", tell the user:
「`/ecc-configure` コマンドに移行しました。`/ecc-configure` を実行してください。」

If `$ARGUMENTS` contains "evolve", tell the user:
「`/ecc-evolve` コマンドに移行しました。`/ecc-evolve` を実行してください。」

Otherwise, display this help:

```
ECC Setup — コンポーネントインストーラー

以下のコマンドを直接使用してください:

  /ecc-init       — プロジェクト初期セットアップ（最初に実行）
  /ecc-bootstrap  — 安全方針 + 設計知識をインストール（cc-sdd 前）
  /ecc-configure  — 実装コンポーネントをインストール（cc-sdd 設計確定後）
  /ecc-evolve     — 継続改善 + ECC 更新差分の適用
```
