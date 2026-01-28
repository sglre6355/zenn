---
title: "nixvim+home-managerでlspmux(rust-analyzer)を宣言的に設定"
emoji: "⚙️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["rust", "neovim", "lsp", "nix"]
published: true
---

自分で設定していて少しつまずいた&日本語ソースが皆無だったので筆を取りました

## 想定読者

ほぼタイトルの通りですが、nixvimとhome-managerを使っている人でlspmuxを設定したい人向けです。この記事ではrust-analyzerの設定を例示しますが、他のLSPでも同様に行えるはずです。

- lspmuxて何？という人は以下の記事をどうぞ

  @[card](https://zenn.dev/dalance/articles/ad3443d6282ce2)

- nixvimはある程度設定済みの想定です

## nixvim側の設定

```nix
programs.nixvim = 
  { lib, ... }:
  {
    plugins.lsp.servers.rust-analyzer = {
      enable = true;
      installCargo = true;
      installRustc = true;
      extraOptions = {
        cmd = lib.nixvim.mkRaw ''
          vim.lsp.rpc.connect("127.0.0.1", 27631)
        '';
        settings.rust-analyzer = {
          lspMux = {
            version = "1";
            method = "connect";
            server = "rust-analyzer";
          };
        };
      };
    };
  };
```

`programs.nixvim.plugins.lsp.servers.rust-analyzer.extraOptions`のところ、特に`lib.nixvim.mkRaw`のところがミソです。`programs.nixvim.plugins.lsp.servers.rust-analyzer.cmd`というオプションも別で用意されているのですが、`string`のリストのみ取る形となっているので`lib.nixvim.mkRaw`で生のluaコードを注入してあげる必要があります。([`lib`モジュールを`programs.nixvim`の引数として取る](https://nix-community.github.io/nixvim/lib/nixvim/index.html)必要がある点に注意)

## lspmuxをデーモン化

```nix
systemd.user.services.lspmux = {
  Unit = {
    Description = "Language server multiplexer server";
  };
  Install = {
    WantedBy = [ "default.target" ];
  };
  Service = {
    Type = "simple";
    ExecStart = "${pkgs.lspmux}/bin/lspmux server";
    Environment = [
      "PATH=${pkgs.gcc}/bin:${pkgs.cargo}/bin:${pkgs.rustc}/bin:${pkgs.rust-analyzer}/bin"
      "RUST_SRC_PATH=${pkgs.rustPlatform.rustLibSrc}"
    ];
  };
};
```

rust-analyzer以外のLSPを設定したい場合は必要なバイナリへのパスを`PATH`に追加してください。

## 終わり

こんなニッチめな設定をしたいという人が他にいるかは微妙ですが、参考になれば幸いです
