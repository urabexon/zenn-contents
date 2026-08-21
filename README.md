# zenn-contents

Articles for [Zenn](https://zenn.dev/), assembled from my
[til](https://github.com/urabexon/til) notes once enough of them have piled up.

The til repository is never modified — this one only reads from it.

Articles themselves are written in Japanese.

## Why this fires on stock, not on time

Posting daily does not fail because of willpower. It fails because of how it is
usually set up.

- **The unit is too large.** One article is a lot to start, so it gets skipped
  on a busy day.
- **Streaks break badly.** Once a streak is gone, so is the motivation that
  depended on it.
- **Writing is decoupled from the work.** An activity that competes with real
  work for time will lose.
- **The blank page is the expensive part.** Deciding *what* to write costs more
  than writing it.

So this repository does not track days. It tracks **stock**: unused til entries.
When the count crosses a threshold, it says an article is available. On a day
when nothing was learned, it says nothing at all, and no obligation is created.

## Usage

```sh
# 1. how much material is waiting
./scripts/zenn-status.sh

# 2. bundle it into a draft — material is pasted in, prose is not
./scripts/zenn-draft.sh \
  --slug pitfalls-behind-one-shell-script \
  --title "..." --emoji "🪤" --topics bash,git,shell --pick bash,git

# 3. fill in the TODOs, then preview
npx zenn preview

# 4. move it into articles/ (--publish flips published to true)
./scripts/zenn-publish.sh 2026-08-22-pitfalls-behind-one-shell-script.md --publish
```

`TIL_DIR` points at the source notes (default `~/22.newurabe-project/til`).
`ZENN_THRESHOLD` sets the stock threshold (default 5).

## What the generator does not do

A draft arrives with the material in place and **three kinds of TODO left**:

- the introduction — why these N notes are one story
- the transitions — how each item leads to the next
- the conclusion — the single thing a reader should take away

That is the part the source notes cannot supply, and the part worth writing.
The blank page disappears; the writing does not.

## Layout

```
zenn-contents/
├── articles/     ← Zenn reads this. Putting a file here is the publish decision
├── books/
├── drafts/       ← Zenn ignores this. Where the TODOs get filled in
├── used.yaml     ← til entries already spent on an article
└── scripts/
    ├── zenn-status.sh
    ├── zenn-draft.sh
    └── zenn-publish.sh
```

## Zenn constraints the scripts enforce

- **The filename is the slug**: `a-z0-9_-`, 12–50 characters
- **At most 5 topics**
- **`articles/` and `books/` must sit at the repository root**
- **At most 2 repositories** can be connected to a Zenn account
- **Deletion happens in the Zenn dashboard only.** A file left in `articles/`
  can come back on the next deploy, so remove it here as well

## Notes on the GitHub integration

- Granting the GitHub App access to this repository alone
  (`Only select repositories`) is enough.
- **A private repository does not deploy.** Nothing errors: the App grants
  access, Zenn lists the repository, the push succeeds, and no article appears.
  Making the repository public surfaced the draft immediately. Since visibility
  was the only thing that changed, that is the cause.
  Keeping it private buys little anyway — anything under `articles/` is meant to
  be public, and unfinished work can live in `drafts/`, which Zenn never reads.
- Check that the branch Zenn syncs is the one you push to; the default is not
  always `main`.
