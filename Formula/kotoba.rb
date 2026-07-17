class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.2.tar.gz"
  sha256 "73cfdf962207cebcdf8486548a47d02980bd0deaef1c0671f3d9e76922424b52"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/kotoba-lang/homebrew-kotoba/releases/download/kotoba-0.6.2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "e764bb66f32015a7c511c32b8556985633c723d8fdae82f36ede03a05f21cdb4"
    sha256 cellar: :any_skip_relocation, sequoia:       "a5ba39ca55937d057cd3f805ee4799969d1af90ad32c5d1483b1f13aed5638f0"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "d5f44929408c193a77c60163ebced0038bcd55f5519d4a2d724043e8d95e2da5"
  end

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.2/kotoba-darwin-arm64.tar.gz"
        sha256 "9e45885da8687d38ed09ace3bc39afabd206de062e4cd721913eddbdf99fc0c6"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.2/kotoba-darwin-amd64.tar.gz"
        sha256 "429d8778156dff7f2600a998f67d6178ff379299dd330025e0bbf22d5869defa"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.2/kotoba-linux-amd64.tar.gz"
      sha256 "6b627e4e861a9ca711d0f693db99e8f494f69599dea4d95784d9624ce2da8da5"
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
      (ns homebrew.web-smoke)
      (defn main [] (+ 40 2))
    KOTOBA
    output = shell_output(
      "#{bin}/kotoba compile #{testpath}/web-smoke.kotoba " \
      "--target web -o #{testpath}/web-smoke.mjs --json",
    )
    assert_match '"kotoba.cli\\/code":"emitted"', output
    assert_path_exists testpath/"web-smoke.mjs"
  end
end
