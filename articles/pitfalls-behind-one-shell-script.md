---
title: "シェルスクリプトを1本公開するまでに踏んだ落とし穴4つ"
emoji: "🪤"
type: "tech"
topics: ["bash", "git", "shell", "macos"]
published: false
---


自分のホームディレクトリが git リポジトリになっていることに気づいた。しかも `origin` は公開リポジトリを指していた。

`.ssh/` も `.aws/` も、まだコミットはされていない。ただ作業ツリーの中にいるだけだ。`git status` は何も警告しない。ローカルでは全て正常だからだ。しかし `git add -A` を一度打てば、その瞬間に秘密鍵が公開リポジトリに入る。

これを実行前に教えてくれる道具が見つからなかったので、200行ほどのシェルスクリプトを書いた。

書き終えてから振り返ると、**たった1本のスクリプトを書いて配布するまでに4回つまずいていた**。しかも4つとも、エラーが出ずに間違った答えが静かに返ってくる種類のものだった。順に書く。

## bash のコマンド置換は NUL バイトを捨てる

`-z` オプションで NUL 区切り出力を得ても、`$( )` を通した時点で NUL が消える。

```sh
# 壊れる: NUL が失われ、1行として扱われる
entries=$(git ls-files -z)

while IFS= read -r -d '' e; do ...; done <<EOF
$(git ls-files -z)
EOF
```

bash は `command substitution: ignored null byte in input` を出すこともあるが、
黙って落とす場合もある。

### 正解はプロセス置換

```sh
while IFS= read -r -d '' path; do
  ...
done < <(git ls-files -z)
```

パイプ（`git ls-files -z | while ...`）ではなくプロセス置換にすると、
**ループがサブシェルではなく現在のシェルで走る**ので、
ループ内で増やしたカウンタや変数がループ後も残る。

検証: bash 3.2.57 (macOS 標準)

NUL は「データが静かに壊れる」話だった。次は「名前ひとつで機能が静かに消える」話になる。

## PATH 上の `git-*` は自動的に git のサブコマンドになる

`PATH` にある実行ファイルのうち `git-<名前>` という名前のものは、
`git <名前>` として呼べる。git 側に登録は要らない。

```sh
$ cp git-brink /usr/local/bin/
$ git brink --version
git-brink 0.1.0
```

### 拡張子を付けると壊れる

git は **`git-<名前>` の完全一致**で探すので、`.sh` を付けると見つからない。

```sh
$ ls /usr/local/bin/git-brink.sh
$ git brink --version
git: 'brink' is not a git command. See 'git --help'.
```

`git brink.sh` なら動くが、サブコマンドとして自然に呼べる利点が消える。
PATH に置く実行ファイルに拡張子を付けない慣習（`ls`, `curl`, `git` など）とも
一致するので、付けないのが正解。実装言語を変えても名前を変えずに済む。

検証: git 2.x / macOS

名前が決まったので、中身の話に移る。このツールの中核は「`git add -A` が実際に何を追加するのか」を事前に知ることだった。

## `git add -A` が実際に何を追加するかを事前に列挙する

`git ls-files --others --exclude-standard` が、
**未追跡かつ ignore されていないパス** ＝ `git add -A` が新規に追加するもの、
をそのまま返す。

```sh
git ls-files --others --exclude-standard -z
```

`git status --porcelain` をパースするより正確で速い。
`-z` を付けると NUL 区切りになり、空白や改行を含むファイル名でも壊れない。

### 巨大なリポジトリでは `--directory` が必須

`.gitignore` の無いリポジトリ（例: 事故で `$HOME` がリポジトリになった場合）では、
上のコマンドは `Library/` や全 `node_modules` を歩き回るため数分かかる。

```sh
git ls-files --others --exclude-standard --directory --no-empty-directory -z
```

`--directory` は**丸ごと未追跡のディレクトリを1エントリに畳む**ので、
git はその中へ降りない。実測で 5分超 → 3秒 になった。

畳まれた中身が必要なら、自分で浅く（`find -maxdepth 2` など）降りる。
全部を git に歩かせるより速い。

検証: git 2.x / macOS, ホームディレクトリ（未追跡 197 エントリ）

ここまでで動くものはできた。あとは配るだけ——と思ったところで、配布先の bash が古かった。

## macOS の `/bin/bash` は今も 3.2

```sh
$ /bin/bash --version
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin23)
```

ライセンス（bash 4 以降が GPLv3）の都合で更新されていない。
配布するスクリプトを `#!/usr/bin/env bash` で書くと、
利用者の環境によっては 3.2 で動くことになる。

### 3.2 で使えないもの

| 機能 | 必要バージョン |
|---|---|
| 連想配列 `declare -A` | 4.0 |
| `mapfile` / `readarray` | 4.0 |
| `${var,,}` / `${var^^}`（大小変換） | 4.0 |
| `**` によるグロブ再帰 | 4.0 |
| `wait -n` | 4.3 |

代替: 連想配列 → 区切り文字入りの文字列や `case`、
大小変換 → `tr '[:upper:]' '[:lower:]'`。

`bash -n script` は構文チェックのみなので、**3.2 で実際に走らせて確認する**。

### ついでに `timeout` も無い

GNU coreutils の `timeout` は macOS に標準で入っていない。
`brew install coreutils` で `gtimeout` になる。

検証: macOS 14 (Darwin 23.5.0)



---

## まとめ

4つに共通しているのは、**失敗が失敗の形をしていない**ことだ。

- NUL は消えても例外は出ない。1行として静かに処理される
- `.sh` を付けても `command not found` は出ない。ただ `git brink` が存在しないことになる
- `--directory` を忘れても止まらない。ただ5分帰ってこない
- bash 3.2 は 4.0 の構文で、環境によっては構文エラーすら出さずに黙る

つまり「自分の環境で動いた」は、正しさの証拠にも、他人の環境で動くことの証拠にもならない。

道具そのものを書くのは半日で終わった。残りの時間は、全部この4つに使った。
