# homebrew-kotoba

Homebrew tap for [`kotoba`](https://github.com/kotoba-lang/kotoba) — a
capability-safe language that compiles to WebAssembly or restricted ESM.

## Install

```bash
brew tap kotoba-lang/kotoba
brew install kotoba
```

Then:

```bash
kotoba check --kind cli-contract --json     # validate the CLI/package/lock contract
kotoba did-derive <32-byte-hex-seed>        # → did:key:z…
```

See [kotoba-lang/kotoba](https://github.com/kotoba-lang/kotoba) for the
full README and current CLI command surface (versioned in
[`kotoba-lang/kotoba-lang`'s `lang/cli.edn`](https://github.com/kotoba-lang/kotoba-lang/blob/main/lang/cli.edn)).

The installed CLI is a native executable. Java, a JVM, Clojure, GraalVM, and
the macOS Command Line Tools are not runtime or installation dependencies.

## License

Apache-2.0 — see [LICENSE in the kotoba repo](https://github.com/kotoba-lang/kotoba/blob/main/LICENSE).
