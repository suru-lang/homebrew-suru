# このファイルは suru-lang/suru の packaging/homebrew/make_formula.py が作ったものです
class Suru < Formula
  desc "日本語の関数型プログラミング言語「する」(インタプリタ・型検査・コンパイラ・言語サーバー)"
  homepage "https://github.com/suru-lang/suru"
  url "https://github.com/suru-lang/suru/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "494a09bb58f7ad4dbbbdecb4d0fcc622e0f263c0987d8dedc4a32a69c830b2b3"
  license all_of: ["GPL-3.0-or-later", "MIT"]
  head "https://github.com/suru-lang/suru.git", branch: "main"

  depends_on "go" => :build
  depends_on "python@3.13"

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(output: bin/"suruc", ldflags:), "./cmd/suruc"
    system "go", "build", *std_go_args(output: bin/"suru-ls", ldflags:), "./cmd/suru-ls"
    system "go", "build", *std_go_args(output: bin/"kumu", ldflags:), "./cmd/kumu"

    # Python 版はリポジトリと同じ並び(suru.py の隣に lib/ と runtime/)で libexec に置く
    libexec.install "suru.py", "suru_check.py", "suru_compile.py", "lib", "runtime"
    python = Formula["python@3.13"].opt_bin/"python3.13"
    (bin/"suru").write <<~SH
      #!/bin/sh
      exec "#{python}" "#{libexec}/suru.py" "$@"
    SH
    pkgshare.install "examples"
  end

  def caveats
    <<~EOS
      バイナリを作る(suru --翻訳、suruc)には clang が要ります。
      macOS では Xcode のコマンドラインツール(xcode-select --install)に入っています。
      Linux では、ディストリビューションの clang か brew install llvm を入れてください。
    EOS
  end

  test do
    (testpath/"t.suru").write "1 と 2 を 加算する\n"
    assert_equal "3", shell_output("#{bin}/suru t.suru").strip
    assert_match version.to_s, shell_output("#{bin}/suruc --version")
    assert_match version.to_s, shell_output("#{bin}/suru-ls --version")
    assert_match version.to_s, shell_output("#{bin}/kumu --version")
  end
end
