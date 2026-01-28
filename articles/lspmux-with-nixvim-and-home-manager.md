---
title: "nixvim+home-managerでlspmux(rust-analyzer)を宣言的に設定"
emoji: "⚙️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["rust", "neovim", "lsp", "nix", "nixos"]
published: false
---

## 想定読者

ほぼタイトルの通りですが、nixvimとhome-managerを使っている人でlspmuxを設定したい人向けです。

- lspmuxて何?な人は以下の記事をどうぞ

<https://zenn.dev/dalance/articles/ad3443d6282ce2>

## nixvim側の設定

```nix
programs.nixvim = 
  { lib, ... }:
  {
    ...
    plugins = {
      ...
      lsp = {
        enable = true;
        autoload = true;
        servers = {
          ...
          rust-analyzer = {
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
    };
  };
```

`programs.nixvim.plugins.lsp.servers.rust-analyzer.extraOptions`のところ、特に`lib.nixvim.mkRaw`のところがミソです。
(`lib`モジュールを`programs.nixvim`の引数として取る必要がある点に注意)

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
