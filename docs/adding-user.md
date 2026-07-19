# Thêm người dùng

## 1. Tạo thư mục

```bash
cd /etc/nixos
mkdir -p users/<username>
```

```text
users/<username>/
├── default.nix
└── home.nix
```

## 2. Tạo tài khoản NixOS

```nix
{
  inputs,
  pkgs,
  ...
}:

{
  users.users.<username> = {
    isNormalUser = true;
    description = "<tên-hiển-thị>";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    createHome = true;
  };

  home-manager.users.<username> = {
    imports = [
      ./home.nix
    ];
  };
}
```

Với Plasma Manager:

```nix
home-manager.users.<username>.imports = [
  inputs.plasma-manager.homeModules.plasma-manager
  ./home.nix
];
```

Không import Plasma Manager ở cấp NixOS.

## 3. Tạo Home Manager configuration

```nix
{
  imports = [
    ../../profiles/home/common.nix
    ../../profiles/home/desktop.nix
    ../../profiles/home/plasma.nix
  ];

  home = {
    username = "<username>";
    homeDirectory = "/home/<username>";
    stateVersion = "26.05";
  };
}
```

Thông tin cá nhân như Git name và email đặt trong `home.nix`, không đặt trong module dùng chung.

## 4. Gắn user vào host

```nix
hosts = {
  j4n9-hplaptop = {
    system = "x86_64-linux";
    users = [
      ./users/ntgiang
      ./users/<username>
    ];
  };
};
```

Không tự quét `users/`.

## 5. Kiểm tra

```bash
nixosctl fmt
nixosctl check
nixosctl build
nixosctl test
```

```bash
nix eval   .#nixosConfigurations.j4n9-hplaptop.config.users.users.<username>.isNormalUser

nix eval   .#nixosConfigurations.j4n9-hplaptop.config.home-manager.users.<username>.home.username
```

Sau khi switch:

```bash
getent passwd <username>
systemctl status home-manager-<username>.service --no-pager
```

## Checklist

```text
[ ] Có default.nix và home.nix
[ ] User được khai báo tường minh
[ ] Chỉ có nhóm cần thiết
[ ] Thông tin cá nhân không nằm trong module dùng chung
[ ] Có home.stateVersion
[ ] Home Manager activation thành công
```
