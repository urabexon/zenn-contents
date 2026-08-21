#!/usr/bin/env bash
# 未使用の til エントリを束ねて drafts/ に下書きを作る。
# 素材は自動で貼るが、繋ぎの文章は書かない。そこは人間の仕事。
set -eu
. "$(dirname "$0")/_common.sh"

slug=""; emoji="📝"; topics=""; title=""; type="tech"; pick=""

usage() {
  cat <<U
使い方:
  zenn-draft.sh --slug <slug> [options]

  --slug <s>      ファイル名になる。a-z0-9_- の 12〜50 文字（Zenn の制約）
  --title <t>     記事タイトル。省略時は TODO のまま
  --emoji <e>     アイキャッチの絵文字1文字（既定: 📝）
  --topics <a,b>  Zenn のトピック。最大5個
  --type <t>      tech | idea（既定: tech）
  --pick <a,b>    素材にするトピックを絞る（til のディレクトリ名）
  -h, --help
U
}

while [ $# -gt 0 ]; do
  case $1 in
    --slug)   shift; slug=${1:?} ;;
    --title)  shift; title=${1:?} ;;
    --emoji)  shift; emoji=${1:?} ;;
    --topics) shift; topics=${1:?} ;;
    --type)   shift; type=${1:?} ;;
    --pick)   shift; pick=${1:?} ;;
    -h|--help) usage; exit 0 ;;
    *) die "不明なオプション: $1" ;;
  esac
  shift
done

[ -n "$slug" ] || { usage >&2; die "--slug は必須です"; }
printf '%s' "$slug" | grep -qE '^[a-z0-9_-]{12,50}$' \
  || die "スラッグが Zenn の制約に合いません（a-z0-9_- の12〜50文字）: $slug (${#slug}文字)"
case $type in tech|idea) ;; *) die "--type は tech か idea です" ;; esac

if [ -n "$topics" ]; then
  nt=$(printf '%s' "$topics" | tr ',' '\n' | grep -c . || true)
  [ "$nt" -le 5 ] || die "topics は最大5個です（$nt 個指定されています）"
fi

# 素材を選ぶ
entries=$(unused_entries)
if [ -n "$pick" ]; then
  pat=$(printf '%s' "$pick" | tr ',' '|')
  entries=$(printf '%s\n' "$entries" | grep -E "^($pat)/" || true)
fi
[ -n "$entries" ] || die "素材になる未使用エントリがありません"

out="$ROOT/drafts/$(date +%Y-%m-%d)-$slug.md"
[ -e "$out" ] && die "既に存在します: $out"

topics_yaml="[]"
if [ -n "$topics" ]; then
  topics_yaml="[$(printf '%s' "$topics" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | paste -sd, - | sed 's/,/, /g')]"
fi

{
  printf -- '---\n'
  printf 'title: "%s"\n' "${title:-TODO: タイトル}"
  printf 'emoji: "%s"\n' "$emoji"
  printf 'type: "%s"\n' "$type"
  printf 'topics: %s\n' "$topics_yaml"
  printf 'published: false\n'
  printf -- '---\n\n'

  printf '<!-- zenn-sources\n'
  printf '%s\n' "$entries" | sed 's/^/  - /'
  printf -- '-->\n\n'

  printf '<!-- TODO: 導入。この %s 件がなぜ「ひとつの話」なのかを書く。\n' "$(printf '%s\n' "$entries" | grep -c .)"
  printf '     ここが記事の価値そのもので、素材からは自動生成できない部分。 -->\n\n'

  printf '%s\n' "$entries" | while IFS= read -r e; do
    [ -n "$e" ] || continue
    printf -- '## %s\n\n' "$(entry_title "$e")"
    # H1 を落とし、残りの見出しを1段繰り下げる。コードフェンス内は触らない
    sed '1{/^# /d;}' "$TIL_DIR/$e" | sed '1{/^$/d;}' | awk '
      /^```/ { fence = !fence; print; next }
      !fence && /^#{1,5} / { print "#" $0; next }
      { print }
    '
    printf '\n<!-- TODO: 次の項目への繋ぎ -->\n\n'
  done

  printf -- '---\n\n'
  printf '<!-- TODO: まとめ。読者が持ち帰るものを1つに絞る。 -->\n'
} > "$out"

printf '%s下書きを作りました%s\n' "$C_GRN" "$C_OFF"
printf '  %s\n' "$(printf '%s' "$out" | sed "s|^$HOME|~|")"
printf '  素材 %s 件 / %s 行\n\n' "$(printf '%s\n' "$entries" | grep -c .)" "$(wc -l < "$out" | tr -d ' ')"
printf '  次にやること\n'
printf '    1. TODO を埋める（導入・繋ぎ・まとめ）\n'
printf '    2. npx zenn preview で確認\n'
printf '    3. ./scripts/zenn-publish.sh %s\n' "$(basename "$out")"
