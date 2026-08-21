# zenn-contents

Zenn の記事。**til を素材にして、在庫がたまったら束ねて書く。**

til リポジトリは一切書き換えない（読むだけ）。

## なぜ「毎日投稿」にしないか

毎日投稿が続かないのは意志ではなく設計の問題。

- **単位が大きい。** 記事1本は着手コストが高く、忙しい日に飛ぶ
- **連続記録は壊れ方が悪い。** 一度切れると動機が一気にゼロになる
- **仕事と切り離されている。** 独立した作業は他の作業に負ける
- **白紙が重い。** 一番重いのは書くことではなく、何を書くか決めること

なのでこのリポジトリは**時間ではなく在庫で発火する**。
未使用の til エントリが閾値（既定5件）を超えたときだけ「書ける」と言う。
何も学ばなかった日に、書く義務は発生しない。

## 使い方

```sh
# 1) 在庫を見る
./scripts/zenn-status.sh

# 2) 束ねて下書きを作る（素材は自動、繋ぎの文章は書かれない）
./scripts/zenn-draft.sh \
  --slug pitfalls-behind-one-shell-script \
  --title "..." --emoji "🪤" --topics bash,git,shell --pick bash,git

# 3) TODO を埋める → プレビュー
npx zenn preview

# 4) articles/ に移す（--publish で published: true にする）
./scripts/zenn-publish.sh 2026-08-22-pitfalls-behind-one-shell-script.md --publish
```

`TIL_DIR` で素材の場所を変えられる（既定 `~/22.newurabe-project/til`）。
`ZENN_THRESHOLD` で在庫の閾値を変えられる（既定 5）。

## 生成される下書き

素材は自動で貼られるが、**3種類の TODO が残る**。

- 導入 — この N 件がなぜ「ひとつの話」なのか
- 繋ぎ — 項目から項目へ
- まとめ — 読者が持ち帰るものを1つに

**ここが記事の価値そのもので、素材からは自動生成できない。**
白紙は消えるが、書く仕事は消えない。

## 構成

```
zenn-contents/
├── articles/     ← Zenn が読む。ここに置いた時点で公開対象
├── books/
├── drafts/       ← Zenn は読まない。TODO を埋める場所
├── used.yaml     ← 使用済みの til エントリ
└── scripts/
    ├── zenn-status.sh
    ├── zenn-draft.sh
    └── zenn-publish.sh
```

## Zenn 側の制約（実装で効いているもの）

- **ファイル名がスラッグ。** `a-z0-9_-` の 12〜50 文字。`zenn-draft.sh` が検査する
- **topics は最大5個。** 同上
- **`articles/` と `books/` はリポジトリ直下**でなければならない
- **連携できるリポジトリは最大2つ**
- **削除はダッシュボードからのみ。** リポジトリにファイルが残っていると
  再デプロイで復活する。取り消すときは `articles/` からも消すこと

## 連携の設定

- GitHub App の権限は `Only select repositories` で、このリポジトリだけ渡せば足りる
- **private では記事が Zenn に出てこなかったため public にした**（2026-08-22）。
  private が原理的に不可なのか、他の設定（同期ブランチ等）の問題だったのかは切り分けていない
- Zenn 側のダッシュボードで「同期するブランチ」が `main` になっていることを確認する
