# 共通処理。各スクリプトから source する。

TIL_DIR="${TIL_DIR:-$HOME/22.newurabe-project/til}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USED="$ROOT/used.yaml"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_BLD=$(printf '\033[1m'); C_DIM=$(printf '\033[2m')
  C_GRN=$(printf '\033[32m'); C_YEL=$(printf '\033[33m'); C_OFF=$(printf '\033[0m')
else
  C_BLD=; C_DIM=; C_GRN=; C_YEL=; C_OFF=
fi

die() { printf '%s\n' "$*" >&2; exit 1; }

# til の全エントリを「トピック/スラッグ」形式で列挙する
til_entries() {
  [ -d "$TIL_DIR" ] || die "til が見つかりません: $TIL_DIR (TIL_DIR で指定できます)"
  find "$TIL_DIR" -name '*.md' -not -name 'README.md' -not -path '*/.git/*' \
    -not -path '*/scripts/*' 2>/dev/null \
    | sed "s|^$TIL_DIR/||" | sort
}

# used.yaml に記録済みのエントリ
used_entries() {
  [ -f "$USED" ] || return 0
  sed -n 's/^  - //p' "$USED" | sed 's/^"//;s/"$//'
}

# 未使用のエントリ
unused_entries() {
  local u; u=$(used_entries)
  til_entries | while IFS= read -r e; do
    if printf '%s\n' "$u" | grep -qxF "$e"; then :; else printf '%s\n' "$e"; fi
  done
}

# エントリの H1 をタイトルとして取り出す
entry_title() {
  grep -m1 '^# ' "$TIL_DIR/$1" 2>/dev/null | sed 's/^# //'
}
