# toc-check

Minimal GitHub Action to check that every file listed in a World of Warcraft addon's TOC and XML exists.

It catches typos, renamed or deleted files and case mismatches for every client the TOC loads on,
including ones not tested in-game. On failure it prints every missing path and exits 1.

## Usage

`.github/workflows/lint.yml` in the addon repository:

```yaml
name: Lint

on:
  push:
    branches: [master]
    paths: ['**.lua', '**.xml', '*.toc', '.luacheckrc', '.github/workflows/lint.yml']
  pull_request:
    paths: ['**.lua', '**.xml', '*.toc', '.luacheckrc', '.github/workflows/lint.yml']

jobs:
  check:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          submodules: recursive # only if the TOC lists files inside submodules

      - name: Luacheck
        uses: lunarmodules/luacheck@v1

      - name: TOC check
        uses: lua-wow/toc-check@v1
```

### Inputs

| Input  | Default | Description           |
|:-------|:--------|:----------------------|
| `path` | `.`     | Addon root directory. |

## What is checked

1. The single `*.toc` in `path` (more than one fails).
2. Every TOC line that is not blank or a `#` comment. Trailing `[AllowLoad...]` directives are stripped and
   `\` becomes `/`. Paths are relative to `path`.
3. Every `.xml` reached: the `file` of each `<Script>` and `<Include>`, relative to that XML's folder,
   recursively. Commented-out (`<!-- -->`) entries are ignored.

Output:

```
missing: missing.lua (from Broken.toc)
missing: Core.lua (from init.xml)
missing: sub/gone.lua (from sub/sub.xml)
error: 3 missing file(s)
```

Limitations:

- The runner is case-sensitive, so a case mismatch fails even though it loads on Windows. Intended.
- `[Family]`, `[Game]` and `[TextLocale]` in a path pass if at least one folder matches; a missing
  per-client variant is not caught.
- It checks the repository, not the packaged zip, so a TOC entry removed by `exclude.lst` is not caught.

## Local use

`check.sh` also runs outside GitHub Actions (it needs `bash` and `perl`):

```sh
../toc-check/check.sh                     # checks the current directory
ADDON_PATH=../Tainted ../toc-check/check.sh
```

| Variable     | Input  |
|:-------------|:-------|
| `ADDON_PATH` | `path` |

## Versioning

Releases are tagged `vX.Y.Z`. The release workflow moves the major tag `vX` to the latest release, so
use `lua-wow/toc-check@v1` to receive fixes, or pin `@v1.0.0` (or a commit SHA) to stay fixed.

To release: update `CHANGELOG.md`, then `git tag v1.0.0 && git push origin v1.0.0`.

## License

[MIT](./LICENSE)
