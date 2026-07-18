# homebrew-kotoba

Homebrew tap for [`kotoba`](https://github.com/kotoba-lang/kotoba) — a
capability-safe Lisp/EDN language that compiles to WebAssembly, with a
CLJC/EDN-authoritative CLI launcher.

## Install

```bash
brew tap kotoba-lang/kotoba
brew install kotoba
```

The formula tracks the current `v0.5.0` release. `brew upgrade kotoba` updates
an existing installation after a newer formula is published.

To track the upstream `main` branch instead of the latest tagged release,
add `--HEAD`:

```bash
brew install --HEAD kotoba
```

Then:

```bash
kotoba check --kind cli-contract --json     # validate the CLI/package/lock contract
kotoba did-derive <32-byte-hex-seed>        # → did:key:z…
```

See [kotoba-lang/kotoba](https://github.com/kotoba-lang/kotoba) for the
full README and current CLI command surface (versioned in
[`kotoba-lang/kotoba-lang`'s `lang/cli.edn`](https://github.com/kotoba-lang/kotoba-lang/blob/main/lang/cli.edn)).

## Requirements

- Clojure (auto-installed by `brew install`)
- macOS Command Line Tools (Xcode 26.3 or later)

## License

Apache-2.0 — see [LICENSE in the kotoba repo](https://github.com/kotoba-lang/kotoba/blob/main/LICENSE).
