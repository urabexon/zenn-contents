#!/usr/bin/env bash
# 未使用の til エントリの在庫を表示する。時間ではなく在庫で発火させるための道具。
set -eu
. "$(dirname "$0")/_common.sh"

THRESHOLD="${ZENN_THRESHOLD:-5}"

unused=$(unused_entries)
n=0
[ -n "$unused" ] && n=$(printf '%s\n' "$unused" | grep -c . || true)

printf '%szenn status%s  %s\n\n' "$C_BLD" "$C_OFF" "$(printf '%s' "$TIL_DIR" | sed "s|^$HOME|~|")"

printf '  未使用の TIL   %s 件   （閾値 %s）\n' "$n" "$THRESHOLD"

# 最終投稿からの日数
last=0
for f in "$ROOT"/articles/*.md; do
  [ -e "$f" ] || continue
  m=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
  if [ "$m" -gt "$last" ]; then last=$m; fi
done
if [ "$last" -gt 0 ]; then
  printf '  最終投稿から   %s 日\n' "$(( ( $(date +%s) - last ) / 86400 ))"
else
  printf '  最終投稿から   （まだ1本も無い）\n'
fi

if [ "$n" -gt 0 ]; then
  printf '\n  トピック別\n'
  printf '%s\n' "$unused" | sed 's|/.*||' | sort | uniq -c \
    | while read -r c t; do printf '    %-12s %s 件\n' "$t" "$c"; done
  printf '\n  未使用の一覧\n'
  printf '%s\n' "$unused" | while IFS= read -r e; do
    printf '    %s%-42s%s %s\n' "$C_DIM" "$e" "$C_OFF" "$(entry_title "$e")"
  done
fi

printf '\n'
if [ "$n" -ge "$THRESHOLD" ]; then
  printf '%s記事 1 本分の在庫があります。%s\n' "$C_GRN" "$C_OFF"
  printf '  %szenn-draft.sh --slug <12-50文字> --emoji 🪤 --topics bash,git%s\n' "$C_DIM" "$C_OFF"
  exit 0
else
  printf '%sまだ在庫が足りません。%s あと %s 件。\n' "$C_YEL" "$C_OFF" "$(( THRESHOLD - n ))"
  printf '  %s何も学ばなかった日に、書く義務は発生しません。%s\n' "$C_DIM" "$C_OFF"
  exit 0
fi
