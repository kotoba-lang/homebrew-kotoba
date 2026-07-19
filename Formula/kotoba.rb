class Kotoba < Formula
  desc "Capability-safe Kotoba language compiler and CLI"
  homepage "https://github.com/kotoba-lang/kotoba"
  url "https://github.com/kotoba-lang/kotoba/archive/refs/tags/v0.6.29.tar.gz"
  sha256 "f3e21f81f6435ff540ff93036d6632e26424d7f7fb52ff157d8b6a30cfb57a10"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/kotoba-lang/homebrew-kotoba/releases/download/kotoba-0.6.29"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "6ce6056e61dc0f025c69db7c49e6a93711b5d0189d9b980a0dc61ff34869776b"
    sha256 cellar: :any_skip_relocation, sequoia:       "758278ae6998cd44debb282fe1d91d5026c3519e5cc0c28833b9df29621211c9"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "f50be4a03e9c127df193de22e7f1694960ad61190ecb57243ac97c432d1e5da3"
  end

  resource "binary" do
    on_macos do
      on_arm do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.29/kotoba-darwin-arm64.tar.gz"
        sha256 "35835c5495388084b2987403d20cbccab2e5e02667a45db068e8a83e342c9b47"
      end
      on_intel do
        url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.29/kotoba-darwin-amd64.tar.gz"
        sha256 "395a369c51dbecd54348256b77e6eef3d5e1c8fdb13d58eee42ffe2eeeb1d067"
      end
    end
    on_linux do
      url "https://github.com/kotoba-lang/kotoba/releases/download/v0.6.29/kotoba-linux-amd64.tar.gz"
      sha256 "287ddf7874d3e198a941f011b3bdc4a6032d6d15e191be83c686231163ccb508"
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

    (testpath/"src/shared").mkpath
    (testpath/"src/shared/value.cljc").write <<~CLJC
      (ns shared.value "bounded bottle project documentation" (:export [answer]))
      (defn answer [] 42)
    CLJC
    (testpath/"main.cljc").write <<~CLJC
      (ns shared.app
        (:require [shared.value :as value])
        (:export [main]))
      (defn main [] (value/answer))
    CLJC
    output = shell_output(
      "#{bin}/kotoba compile #{testpath}/main.cljc " \
      "--source-path #{testpath}/src --target web " \
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

    (testpath/"typed/fixture").mkpath
    (testpath/"typed/fixture/coverage.kotoba").write <<~KOTOBA
      (ns fixture.coverage
        (:export [ready? make-report none-report choose-report covered-count map-score]))
      (def label-map-type [:map :keyword :string])
      (defn ready? [covered [:set :keyword]] :bool
        (typed-set-contains [:set :keyword] covered :ready))
      (defn none-report []
        [:option [:record :fixture/report
                  [[:label :string] [:covered [:set :keyword]]]]]
        (option-none-of
          [:option [:record :fixture/report
                    [[:label :string] [:covered [:set :keyword]]]]]))
      (defn make-report []
        [:record :fixture/report [[:label :string] [:covered [:set :keyword]]]]
        (record
          [:record :fixture/report [[:label :string] [:covered [:set :keyword]]]]
          "qualified" (typed-set [:set :keyword] :ready :reviewed)))
      (defn choose-report
        [left [:option [:record :fixture/report
                        [[:label :string] [:covered [:set :keyword]]]]]
         right [:option [:record :fixture/report
                         [[:label :string] [:covered [:set :keyword]]]]]]
        [:option [:record :fixture/report
                  [[:label :string] [:covered [:set :keyword]]]]]
        (match-option left
          [:option [:record :fixture/report
                    [[:label :string] [:covered [:set :keyword]]]]]
          (none right)
          (some left-report
            (match-option right
              [:option [:record :fixture/report
                        [[:label :string] [:covered [:set :keyword]]]]]
              (none left)
              (some right-report right)))))
      (defn covered-count
        [report [:record :fixture/report
                 [[:label :string] [:covered [:set :keyword]]]]]
        :i64
        (typed-set-count [:set :keyword]
          (record-get
            [:record :fixture/report [[:label :string] [:covered [:set :keyword]]]]
            report :covered)))
      (defn map-score [] :i64
        (let [labels (typed-map-assoc label-map-type
                       (typed-map-assoc label-map-type
                         (typed-map-new label-map-type) :ready "yes")
                       :reviewed "yes")
              first-entry (option-value-of
                            [:option [:vector [:keyword :string]]]
                            (typed-map-entry-at label-map-type labels 0)
                            (hetero-vector [:vector [:keyword :string]] :missing "no"))]
          (if (= (typed-map-count label-map-type labels) 2)
            (if (typed-map-contains label-map-type labels :ready)
              (if (string=?
                    (option-value-of [:option :string]
                      (typed-map-get label-map-type labels :reviewed) "no")
                    "yes")
                (if (= (hetero-vector-count
                         [:vector [:keyword :string]] first-entry) 2)
                  2
                  0)
                0)
              0)
            0)))
    KOTOBA
    (testpath/"typed/fixture/app.kotoba").write <<~KOTOBA
      (ns fixture.app
        (:require [fixture.coverage :as coverage])
        (:export [main]))
      (defn main [] :i64
        (let [covered (typed-set [:set :keyword] :ready :reviewed)]
          (if (coverage/ready? covered)
            (if (string=? "Kotoba" "Kotoba")
              (+ 38
                (coverage/map-score)
                (coverage/covered-count
                  (option-value-of
                    [:option [:record :fixture/report
                              [[:label :string] [:covered [:set :keyword]]]]]
                    (coverage/choose-report
                      (coverage/none-report)
                      (option-some-of
                        [:option [:record :fixture/report
                                  [[:label :string] [:covered [:set :keyword]]]]]
                        (coverage/make-report)))
                    (coverage/make-report))))
              1)
            0)))
    KOTOBA
    web = shell_output(
      "#{bin}/kotoba compile #{testpath}/typed/fixture/app.kotoba " \
      "--source-path #{testpath}/typed --target web " \
      "--output #{testpath}/typed-app.mjs --json",
    )
    assert_match '"kotoba.artifact\\/value-profile":"typed-v1"', web
    assert_match '"kotoba.artifact\\/module-graph-digest"', web
    wasm = shell_output(
      "#{bin}/kotoba compile #{testpath}/typed/fixture/app.kotoba " \
      "--source-path #{testpath}/typed --target wasm " \
      "--output #{testpath}/typed-app.wasm --json",
    )
    assert_match '"value-profile":"typed-v1"', wasm
    assert_match '"value-abi":"externref-v1"', wasm
    assert_path_exists testpath/"typed-app.wasm"
  end
end
