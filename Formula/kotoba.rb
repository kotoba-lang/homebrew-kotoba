class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.14.tar.gz"
  sha256 "4a6ff7e98bc6f0a620cebd72406e93affebb269c977fe5cdc0b891f07497aeac"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/kotoba-lang/homebrew-kotoba/releases/download/kotoba-0.6.14"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "0560f49aeca4d1138ded135ecc2086e86d583e6699b69eddd6d89eba60fe884e"
    sha256 cellar: :any_skip_relocation, sequoia:       "0bf6dcefcc4a449ef8dddee3fe33eb32b472afaae2587e8ffb528831bc960b5a"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "4d99fbb8a77f734702f848260f66834388f20afba21280507b4b754c4f9a5cc4"
  end

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.14/kotoba-darwin-arm64.tar.gz"
        sha256 "399374c2a4fd13f6d206747a76f52843835af3d612310f6654803354f86f5f54"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.14/kotoba-darwin-amd64.tar.gz"
        sha256 "ab303e5a3ec5564cacb50aa2098b22dc9d4ce09032f58469d071cc9384968d85"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.14/kotoba-linux-amd64.tar.gz"
      sha256 "5922756a2d223dc11603228f08468598646cc1b7eac5914bc46f7491a2c034d7"
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
       :kotoba.project/dependency-manifests {}}
    EDN
    (testpath/"kotoba.lock.edn").write <<~EDN
      {:kotoba.lock/version 1 :deps []}
    EDN
    (testpath/"kotoba.trust.edn").write "{}\n"
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
