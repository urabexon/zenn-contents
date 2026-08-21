# zenn-contents

[English](./README.md) · **日本語**

[Zenn](https://zenn.dev/) の記事。[til](https://github.com/urabexon/til) のメモを素材にして、
**在庫がたまったら束ねて書く。**

til リポジトリは一切書き換えない（読むだけ）。

## なぜ時間ではなく在庫で発火させるか

毎日投稿が続かないのは意志の問題ではなく、設計の問題である。

- **単位が大きい。** 記事1本は着手コストが高く、忙しい日に飛ぶ
- **連続記録は壊れ方が悪い。** 一度切れると、それに依存していた動機ごと消える
- **書くことが仕事と切り離されている。** 独立した作業は、他の作業と時間を奪い合って負ける
- **一番重いのは白紙。** 書くことより、何を書くか決めることの方がコストが高い

そこでこのリポジトリは日数を数えない。**在庫**——未使用の til エントリ——を数える。
閾値を超えたときだけ「記事1本分ある」と言う。
何も学ばなかった日には何も言わないので、義務が発生しない。

## 使い方

```sh
# 1. 素材がどれだけ待っているか
./scripts/zenn-status.sh

# 2. 束ねて下書きにする。素材は貼られるが、文章は書かれない
./scripts/zenn-draft.sh \
  --slug pitfalls-behind-one-shell-script \
  --title "..." --emoji "🪤" --topics bash,git,shell --pick bash,git

# 3. TODO を埋めてプレビュー
npx zenn preview

# 4. articles/ に移す（--publish で published: true になる）
./scripts/zenn-publish.sh 2026-08-22-pitfalls-behind-one-shell-script.md --publish
```

`TIL_DIR` で素材の場所を指定する（既定 `~/22.newurabe-project/til`）。
`ZENN_THRESHOLD` で在庫の閾値を変える（既定 5）。

## 生成器がやらないこと

下書きには素材が揃った状態で、**3種類の TODO が残る。**

- 導入 — この N 件がなぜ「ひとつの話」なのか
- 繋ぎ — 項目から項目へどう繋がるのか
- まとめ — 読者が持ち帰るものを1つに

**素材からは自動生成できない部分であり、書く価値があるのもそこ。**
白紙は消えるが、書く仕事は消えない。

## 構成

```
zenn-contents/
├── articles/     ← Zenn が読む。ここに置くことが公開の判断
├── books/
├── drafts/       ← Zenn は読まない。TODO を埋める場所
├── used.yaml     ← 記事に使用済みの til エントリ
└── scripts/
    ├── zenn-status.sh
    ├── zenn-draft.sh
    └── zenn-publish.sh
```

## スクリプトが検査している Zenn の制約

- **ファイル名がスラッグ**: `a-z0-9_-` の 12〜50 文字
- **topics は最大5個**
- **`articles/` と `books/` はリポジトリ直下**でなければならない
- **連携できるリポジトリは最大2つ**
- **削除は Zenn のダッシュボードからのみ。** `articles/` にファイルが残っていると
  次のデプロイで復活するので、こちらからも消すこと

## GitHub 連携について

- GitHub App の権限は、このリポジトリだけを渡せば足りる（`Only select repositories`）
- **private リポジトリではデプロイされない。** しかも何もエラーが出ない。
  App の権限付与は成功し、Zenn のリポジトリ一覧にも出て、push も通り、
  それでいて記事が現れない。public にした瞬間に下書きが出た。
  可視性以外は変えていないので、原因はそれである。
  そもそも private にする意味は薄い。`articles/` の中身は公開される前提のものだし、
  未完成のものは Zenn が読まない `drafts/` に置けばよい
- Zenn が同期するブランチが、push しているブランチと一致しているか確認する。
  既定が `main` とは限らない
