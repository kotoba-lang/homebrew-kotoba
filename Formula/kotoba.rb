class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.7.tar.gz"
  sha256 "cab6b48f1bcee0401a56c7aba6f59cdc68a7d5875d2f03b109fb0fbd13e207ac"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/kotoba-lang/homebrew-kotoba/releases/download/kotoba-0.6.7"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "c992992fb7ff8d026f11064d2406293922d56d9dd860255e903b71ac35508475"
    sha256 cellar: :any_skip_relocation, sequoia:       "d22eb7a77f14b0496b2036e10ecc6239143c2e069c91b9e8c27963e5a5f47c1f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "407b977f51277216244b541c52b4aadbdf0cd8efc22d56f3ce3d20c3f2865891"
  end

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.7/kotoba-darwin-arm64.tar.gz"
        sha256 "4625b14183247120d2994c137906e5dd65b63f21fe59f61024dc8f1ec948636c"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.7/kotoba-darwin-amd64.tar.gz"
        sha256 "f0ec98b46d19e62745a072be35ec47b3df874b892737320f77541e4fcf53da6e"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.7/kotoba-linux-amd64.tar.gz"
      sha256 "081a7bb998a1b38f875f164c9ee6bb88accacdb7c5e46fe6768f3e90ee2c4cbd"
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
        homebrew.text "text.kotoba"}}
    EDN
    output = shell_output(
      "#{bin}/kotoba compile --project #{testpath}/kotoba-project.edn " \
      "--target web -o #{testpath}/app.mjs --json",
    )
    assert_match '"kotoba.cli\\/code":"emitted"', output
    assert_match '"kotoba.artifact\\/module-graph-digest"', output
    assert_match '"homebrew.app"', output
    assert_match '"homebrew.text"', output
    assert_match "Object.freeze({'welcome':k$welcome})", (testpath/"app.mjs").read
  end
end
