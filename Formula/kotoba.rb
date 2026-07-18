class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.24.tar.gz"
  sha256 "03c29ddb270158f643e0a50e5d9b2cdeae1e9c43443062c23f0b4882a226b850"
  license "Apache-2.0"

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.24/kotoba-darwin-arm64.tar.gz"
        sha256 "35da0c32a9d5961f5c8b12eda02f25ce115f3792b5496971bb80efb752ff1a64"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.24/kotoba-darwin-amd64.tar.gz"
        sha256 "e992c078eddd105ff939cc0ad3b44f24e8b487117bccc666118a202f968fa0e7"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.24/kotoba-linux-amd64.tar.gz"
      sha256 "a0a5985d356f282fac578e0d51ad76ab388c97f27d788d8e02400a950706f822"
    end
  end

  def install
    resource("binary").stage do
      bin.install "kotoba"
    end
  end

  test do
    output = shell_output("#{bin}/kotoba selfhost check --json")
    assert_match '"kotoba.cli\\/ok?":true', output
    assert_match '"kotoba.cli\\/code":"valid"', output

    (testpath/"web-string.kotoba").write <<~KOTOBA
      (ns homebrew.web-string (:export [greet byte-length]))
      (defn greet [name :string] :string
        (string-concat "こんにちは、" name))
      (defn byte-length [value :string] :i64
        (string-byte-length value))
    KOTOBA
    output = shell_output(
      "#{bin}/kotoba compile #{testpath}/web-string.kotoba " \
      "--target web -o #{testpath}/web-string.mjs --json",
    )
    assert_match '"kotoba.cli\\/code":"emitted"', output
    assert_match '"kotoba.artifact\\/value-profile":"typed-v1"', output
    assert_path_exists testpath/"web-string.mjs"
    generated = (testpath/"web-string.mjs").read
    assert_match "entry:null", generated
    assert_match "valueProfile:'typed-v1'", generated
    string_limits = "stringLimits:Object.freeze({literalBytes:4096," \
                    "moduleLiteralBytes:65536,valueBytes:65536})"
    assert_match string_limits, generated
    assert_match "こんにちは、", generated
    assert_match "Object.freeze({'greet':k$greet,'byte-length':k$byte$002dlength})", generated

    (testpath/"safe-window-name.kotoba").write <<~KOTOBA
      (ns homebrew.timing (:export [shot-hit]))
      (defn shot-hit [delta-present delta-ms window-ms]
        (if delta-present (if (<= delta-ms window-ms) 1 0) 0))
    KOTOBA
    output = shell_output(
      "#{bin}/kotoba compile #{testpath}/safe-window-name.kotoba " \
      "--target web -o #{testpath}/safe-window-name.mjs --json",
    )
    assert_match '"kotoba.cli\\/code":"emitted"', output
    assert_match "k$window$002dms", (testpath/"safe-window-name.mjs").read

    (testpath/"shared").mkpath
    (testpath/"shared/value.cljc").write <<~CLJC
      (ns shared.value (:export [answer]))
      (defn answer [] 42)
    CLJC
    (testpath/"shared/app.cljc").write <<~CLJC
      (ns shared.app
        (:require [shared.value :as value])
        (:export [main]))
      (defn main [] (value/answer))
    CLJC
    output = shell_output(
      "#{bin}/kotoba compile #{testpath}/shared/app.cljc " \
      "--source-path #{testpath} --target web " \
      "--output #{testpath}/shared-app.mjs --json",
    )
    assert_match '"kotoba.cli\\/code":"emitted"', output
    assert_match '"kotoba.artifact\\/module-graph-digest"', output
    assert_path_exists testpath/"shared-app.mjs"

    (testpath/"text.kotoba").write <<~KOTOBA
      (ns homebrew.text (:export [greet]))
      (defn greet [name :string] :string
        (string-concat "こんにちは、" name))
    KOTOBA
    (testpath/"app.kotoba").write <<~KOTOBA
      (ns homebrew.app
        (:require [homebrew.text :as text])
        (:export [welcome]))
      (defn welcome [name :string] :string (text/greet name))
    KOTOBA
    (testpath/"kotoba-project.edn").write <<~EDN
      {:kotoba.project/root homebrew.app
       :kotoba.project/modules
       {homebrew.app "app.kotoba"
        homebrew.text "text.kotoba"}
       :kotoba.project/package-lock "kotoba.lock.edn"
       :kotoba.project/trust "kotoba.trust.edn"
       :kotoba.project/dependency-manifests
       {"kotoba-lang/json" "json.package.edn"}}
    EDN
    (testpath/"kotoba.lock.edn").write <<~EDN
      {:kotoba.lock/version 1
       :deps
       [{:dep/name "kotoba-lang/json"
         :dep/version "0.1.0"
         :dep/repo-rid "bafyreiarfykm5z7sphdaldk27xkdioykfxkyib7iyglqiteaszqlhoka5i"
         :dep/ref "refs/tags/v0.1.0"
         :dep/commit "0123456789abcdef0123456789abcdef01234567"
         :dep/tree-cid "bafyreiawokfmkzvlt3yhwb5qd6widilkuvriucz6kxlrwb2o5whnpkjek4"
         :dep/manifest-cid "bafyreielazp7f3frjhrgrbhyxffsq7hdkj7msbjqwficmlfftnv5oqf6da"
         :dep/signers ["did:key:z6MkhFT5VyDsLkruumQGkBb6sMWPGmB9ddsb6hc8AwaxyuQ4"]
         :dep/capabilities []}]}
    EDN
    (testpath/"kotoba.trust.edn").write <<~'EDN'
      {:declared-capabilities []
       :trusted-signers
       #{"did:key:z6MkhFT5VyDsLkruumQGkBb6sMWPGmB9ddsb6hc8AwaxyuQ4"}}
    EDN
    (testpath/"json.package.edn").write <<~EDN
      {:kotoba.package/name "kotoba-lang/json"
       :kotoba.package/version "0.1.0"
       :kotoba.package/repo-rid "bafyreiarfykm5z7sphdaldk27xkdioykfxkyib7iyglqiteaszqlhoka5i"
       :kotoba.package/source
       {:git-commit "0123456789abcdef0123456789abcdef01234567"
        :tree-cid "bafyreiawokfmkzvlt3yhwb5qd6widilkuvriucz6kxlrwb2o5whnpkjek4"
        :manifest-cid "bafyreielazp7f3frjhrgrbhyxffsq7hdkj7msbjqwficmlfftnv5oqf6da"}
       :kotoba.package/build
       {:deterministic true
        :profile-version 1
        :component-cid "bafyreie5o2doj4tyfq23nc3eqowgdyjlf77g3c4jzl3rbx6tznasoubiw4"}
       :kotoba.package/capabilities [:graph-read]
       :kotoba.package/dependencies []
       :kotoba.package/signatures
       [{:did "did:key:z6MkhFT5VyDsLkruumQGkBb6sMWPGmB9ddsb6hc8AwaxyuQ4"
         :alg :ed25519
         :sig "SKXsX4fGGot2GJmwBYT4xnvYD+G7gdfLBM8wceMZz0JVN7DhdRWyQhR7oYoF+BOIymecQINcLzdBpnjfEI3eCA=="}]}
    EDN
    output = shell_output(
      "#{bin}/kotoba compile --project #{testpath}/kotoba-project.edn " \
      "--target web -o #{testpath}/app.mjs --json",
    )
    assert_match '"kotoba.cli\\/code":"emitted"', output
    assert_match '"kotoba.artifact\\/module-graph-digest"', output
    assert_match '"homebrew.app"', output
    assert_match '"homebrew.text"', output
    project_generated = (testpath/"app.mjs").read
    assert_match "Object.freeze({'welcome':k$welcome})", project_generated
    assert_match "moduleGraphDigest:", project_generated
    assert_match "moduleSourceDigests:Object.freeze", project_generated
    assert_match "packageLockDigest:", project_generated
    assert_match "trustPolicyDigest:", project_generated
    assert_match "packageReceiptDigest:", project_generated
  end
end
