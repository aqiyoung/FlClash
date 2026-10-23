# The Core Submodule

The proxying core is built from a git submodule rather than a published Go module, so its version is
recorded twice, in two files that know nothing about each other. This note is what to check and what to
move when upstream ships a release.

## What the submodule is

`core/Clash.Meta` points at `git@github.com:aqiyoung/skyward-core.git`, branch `FlClash`. `skyward-core`
is this project's mirror of `chen08209/Clash.Meta` — upstream FlClash's own core fork — renamed because
mihomo's README forbids a downstream that is not MetaCubeX's from carrying "mihomo" in its name, and
Skyward publishes the core it builds.

The mirror adds nothing of its own: its `FlClash` head is the same commit as `chen08209/Clash.Meta`'s,
which is an upstream release tag plus the patches upstream FlClash carries (four as of v1.19.33, the
oldest being `support FlClash`). No code under `lib/` depends on a core patch of our own, so bumping the
core is a mirror move plus a version string, not a rebase of our work.

The Go module path inside stays `github.com/metacubex/mihomo`, even though the repository does not.
`core/go.mod` replaces it with `./Clash.Meta`, and both builders inject the version through that path:

- `plugins/setup/setup_hooks/lib/src/go_builder.dart`: `-X github.com/metacubex/mihomo/constant.Version`
- `android/core/build.gradle.kts`: the same flag, for the gomobile archive

Renaming the repository is therefore free, and the injected symbol keeps resolving. Do not rename the
module to match the repository.

## Where the version lives

Bump these together, every time:

| What | Where |
| --- | --- |
| The code | `git ls-tree HEAD core/Clash.Meta` — the submodule pin |
| The string the app reports | `core_version` in `build_config.yaml` |

Nothing derives one from the other. A pin that is not the release the string names makes every bug
report quote a version that was never built.

## Checking where we are

```bash
git ls-tree HEAD core/Clash.Meta                               # the pin
git submodule status core/Clash.Meta                           # pin against the branch head
grep core_version build_config.yaml                            # the string we ship
gh release view -R MetaCubeX/mihomo --json tagName -q .tagName  # the newest release
```

The pin's parents say which tag it sits on: walk down from our head until a commit is no longer one of
the FlClash patches, and that commit is the release the mirror was taken from.


A scheduled job on the default branch does the comparison for you: `core-watch.yaml` reads `beta`'s
`core_version`, compares it with mihomo's newest release, and announces a difference on Telegram once,
recording what it said as a `core-watch-<release>` tag. A release left unpicked therefore does not
repeat every morning; delete that tag to be told again.

## Bumping

1. Mirror the new branch head. `aqiyoung` carries no patches of its own, so this is a fast-forward:

   ```bash
   git clone --branch FlClash git@github.com:aqiyoung/skyward-core.git
   cd skyward-core
   git remote add upstream git@github.com:chen08209/Clash.Meta.git
   git fetch upstream FlClash
   git merge --ff-only upstream/FlClash
   git push origin FlClash
   ```

2. Move the pin and the string. `.gitmodules` names `FlClash`, so `--remote` follows that branch:

   ```bash
   git submodule update --remote core/Clash.Meta
   git submodule status core/Clash.Meta
   ```

   Then set `core_version` to the tag that head sits on, and stage both with
   `git add core/Clash.Meta build_config.yaml`.

3. Carry the dependency moves. A new core can require a newer direct or indirect module, and that diff
   belongs in the same commit (see `build: update mihomo to v1.19.33`, which bumped `metacubex/tls` and
   a dozen indirects). `go mod tidy` inside `core/` is what produces it: it resolves modules and does
   not build the app, so the rule against building on the host does not cover it.

4. Verify in CI, never locally. Push `beta`; the preview builds the Go core, so a pin that does not
   compile fails there. Read the injected version back from the build log (`-X ...constant.Version=`) and
   from the core's own startup lines in the app's log page.

## Traps

- Do not track `main`. Upstream's `main` is a stale branch (head `008b91b`, February 2025) sharing no
  history with `FlClash`; development lands on `Alpha`, and `Alpha` is the tagged release between
  releases.
- Do not pin an untagged `Alpha` commit: `core_version` would then name a release the binary is not.
- `.gitmodules` uses an SSH URL, while CI checks the submodule out with `submodules: recursive` and no
  credentials of its own. Keep `skyward-core` public, or the workflow needs a token or a key.
- `git submodule update` keeps the recorded pin; only `--remote` moves it to the branch head.
