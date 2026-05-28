# homebrew-kotoba

Homebrew tap for [`kotoba`](https://github.com/etzhayyim/kotoba) — a
content-addressed distributed Datalog database with native CACAO
authentication.

## Install

```bash
brew tap etzhayyim/kotoba
brew install --HEAD kotoba
```

The `--HEAD` flag is required while the formula tracks the upstream `main`
branch (no tagged release yet). Once `kotoba` cuts its first tag, the
formula will gain a stable `url` + `sha256` and plain `brew install kotoba`
will work without the flag.

Then:

```bash
kotoba init                                              # one-time identity
kotoba serve &                                           # IPFS + CACAO default-on
kotoba demo                                              # smoke test
kotoba sparql 'ASK { ?s <kg/claim/role> "admin" }'
```

See [etzhayyim/kotoba](https://github.com/etzhayyim/kotoba) for the
full README, SPARQL surface, and performance matrix.

## Requirements

- Rust (auto-installed by `brew install`)
- macOS Command Line Tools (Xcode 26.3 or later)
- Optional: `ipfs daemon` running on `KOTOBA_IPFS_ENDPOINT` (default
  `http://localhost:5001`) — set `KOTOBA_IPFS=off` to disable

## License

Apache-2.0 — see [LICENSE in the kotoba repo](https://github.com/etzhayyim/kotoba/blob/main/LICENSE).
