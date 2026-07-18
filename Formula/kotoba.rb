class Kotoba < Formula
  desc "CLJC/EDN-authoritative Kotoba CLI launcher"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "9f31cefad1cb368d53e423caf0b38aade0c7052ac70dba736d2cb289cfeaddd4"
  license "Apache-2.0"
  head "https://github.com/kotoba-lang/kotoba.git", branch: "main"

  depends_on "clojure"

  def install
    libexec.install "deps.edn", "src", "bin", "LICENSE"
    (bin/"kotoba").write <<~EOS
      #!/bin/sh
      export KOTOBA_CLJ_HOME="#{libexec}"
      exec "#{libexec}/bin/kotoba-clj" "$@"
    EOS
  end

  test do
    ENV["KOTOBA_CLJ_HOME"] = libexec
    out = shell_output("#{bin}/kotoba selfhost check --json")
    assert_match "selfhost", out
    assert_match "valid", out
  end
end
