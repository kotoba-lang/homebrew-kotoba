class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.4.tar.gz"
  sha256 "ecabc5964f4a1cee521ce453825fa27fab223f02581ae8446550ed618cf27588"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/kotoba-lang/homebrew-kotoba/releases/download/kotoba-0.6.4"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "f5b4fe3653781a8f959ed792b2384d4080ddde5f2efb3853f5f5bf56b219a1c6"
    sha256 cellar: :any_skip_relocation, sequoia:       "214a6018f7965a0997fcf5820374681d85e22658f6d662cab30f70462d2536cd"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "25e9e804fbea8ff86d8bc0468588808acdfe941dd3b2ff90a3abb4adb421fae5"
  end

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.4/kotoba-darwin-arm64.tar.gz"
        sha256 "ef10de1f25493700f8126ef9be9a69c45feddccee7470fdafb8506f0229dce2a"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.4/kotoba-darwin-amd64.tar.gz"
        sha256 "7020bc7425b0627a8385fc698c36fd8c5de2b450efa4878c9af12f769c92d70b"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.4/kotoba-linux-amd64.tar.gz"
      sha256 "1656300de4c57b5b980c5203d625283ab437710cf739a758f1852f8b39659807"
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
  end
end
