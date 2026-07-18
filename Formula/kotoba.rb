class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.10.tar.gz"
  sha256 "a43f9a577aec894f15bf4d39e4d2722aaec77248d618b4a35cfe44a8b1efb93d"
  license "Apache-2.0"

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.10/kotoba-darwin-arm64.tar.gz"
        sha256 "4127cae2f4f25e8975a1188a03064fe6fbe3c8629172c0265e608e5d73dceb61"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.10/kotoba-darwin-amd64.tar.gz"
        sha256 "6c1490f7cc902d72983195886bfd84438fea0e2418bdf1c2abe7569d9587cbd1"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.10/kotoba-linux-amd64.tar.gz"
      sha256 "f5e883c34aecb73202a32c50d65c2becafee46d58eabc830ddd902b7eda1aeda"
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
    project_generated = (testpath/"app.mjs").read
    assert_match "Object.freeze({'welcome':k$welcome})", project_generated
    assert_match "moduleGraphDigest:", project_generated
    assert_match "moduleSourceDigests:Object.freeze", project_generated
  end
end
