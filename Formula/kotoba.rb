class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.3.tar.gz"
  sha256 "00b82eb5041d492487b273720d77b6dec2590bd73a51be70162ca2bc00e52059"
  license "Apache-2.0"

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.3/kotoba-darwin-arm64.tar.gz"
        sha256 "8ccdc6020dfe233e696075f77df8c404fab66c99903cf19a5b4572a40775da5a"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.3/kotoba-darwin-amd64.tar.gz"
        sha256 "64625ff5fc2d6ca5d5ac4c5aa4939d4eedba0e110acf2e0bc01d940fdda187f0"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.3/kotoba-linux-amd64.tar.gz"
      sha256 "35d15ffd8a9ac5102a828750fb96ee15dcec172aad0d1519894b61a26944b738"
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

    (testpath/"web-smoke.kotoba").write <<~KOTOBA
      (ns homebrew.web-smoke (:export [add1]))
      (defn- increment [value] (+ value 1))
      (defn add1 [value] (increment value))
    KOTOBA
    output = shell_output(
      "#{bin}/kotoba compile #{testpath}/web-smoke.kotoba " \
      "--target web -o #{testpath}/web-smoke.mjs --json",
    )
    assert_match '"kotoba.cli\\/code":"emitted"', output
    assert_path_exists testpath/"web-smoke.mjs"
    generated = (testpath/"web-smoke.mjs").read
    assert_match "entry:null", generated
    assert_match "Object.freeze({'add1':k$add1})", generated
    refute_match "'increment':", generated
  end
end
