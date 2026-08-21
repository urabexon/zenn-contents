#!/usr/bin/env bash
# 下書きを articles/ に移し、使用した til エントリを used.yaml に記録する。
# articles/ に置いた時点で Zenn の公開対象になる（published の値で最終判断）。
set -eu
. "$(dirname "$0")/_common.sh"

[ $# -ge 1 ] || die "使い方: zenn-publish.sh <drafts 内のファイル名> [--publish]"
name=$(basename "$1")
src="$ROOT/drafts/$name"
[ -f "$src" ] || die "見つかりません: $src"

do_publish=0
[ "${2:-}" = "--publish" ] && do_publish=1

# TODO が残っていたら止める
if grep -q 'TODO' "$src"; then
  n=$(grep -c 'TODO' "$src")
  die "TODO が $n 件残っています。埋めてから実行してください: $src"
fi

# 日付接頭辞を外してスラッグにする（Zenn はファイル名がスラッグ）
slug=$(printf '%s' "$name" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//' | sed 's/\.md$//')
printf '%s' "$slug" | grep -qE '^[a-z0-9_-]{12,50}$' \
  || die "スラッグが制約に合いません: $slug"

dst="$ROOT/articles/$slug.md"
[ -e "$dst" ] && die "既に存在します: $dst"

sources=$(sed -n '/^<!-- zenn-sources$/,/^-->$/p' "$src" | sed -n 's/^  - //p')

# zenn-sources コメントは公開版から除去する
sed '/^<!-- zenn-sources$/,/^-->$/d' "$src" > "$dst"

if [ "$do_publish" -eq 1 ]; then
  sed -i.bak 's/^published: false$/published: true/' "$dst" && rm -f "$dst.bak"
fi

rm "$src"

# used.yaml へ追記
if [ -n "$sources" ]; then
  tmp=$(mktemp)
  if grep -q '^used: \[\]$' "$USED"; then
    sed 's/^used: \[\]$/used:/' "$USED" > "$tmp"
  else
    cp "$USED" "$tmp"
  fi
  printf '%s\n' "$sources" | sed 's/^/  - /' >> "$tmp"
  mv "$tmp" "$USED"
fi

printf '%s記事にしました%s\n' "$C_GRN" "$C_OFF"
printf '  %s\n' "$(printf '%s' "$dst" | sed "s|^$HOME|~|")"
printf '  published: %s\n' "$(grep -m1 '^published:' "$dst" | sed 's/^published: //')"
printf '  used.yaml に %s 件を記録\n\n' "$(printf '%s\n' "$sources" | grep -c . || echo 0)"
printf '  %s公開するには published: true にして push%s\n' "$C_DIM" "$C_OFF"
printf '  %s取り消すには articles/ から削除し、Zenn のダッシュボードでも削除する%s\n' "$C_DIM" "$C_OFF"
