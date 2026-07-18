class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.22.tar.gz"
  sha256 "71bf92b90cd10c5bbaa990c992b769351810cc54d29107c1e4811b57f58c31e7"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/kotoba-lang/homebrew-kotoba/releases/download/kotoba-0.6.22"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "b0920cead99f0101cd10ad123c024bbf684d732b9de97bf01fe22c55ed18695f"
    sha256 cellar: :any_skip_relocation, sequoia:       "c9e8f977b4a08be740160464000b7e70e910ad9ebe801b7acf744b778db6e5dc"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "34999e0eb4c7f72808d266026e39d4d59700cbba45711f099ea2eef8aaae041d"
  end

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.22/kotoba-darwin-arm64.tar.gz"
        sha256 "b985d1b81688a113daf134488d5d5904a791cd1f4a107ac9307aa6bd49b82582"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.22/kotoba-darwin-amd64.tar.gz"
        sha256 "1f5ca13d5981cf1b598460a584e093441ddd878280b18c15cda09595d7c94a91"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.22/kotoba-linux-amd64.tar.gz"
      sha256 "9d0280e0b8f44eaa0842b749bfa58ffa8d92465bc41d85080de69eaa3c8afdd2"
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
