# Thêm module mới

## 1. Chọn lớp

NixOS module đặt trong `modules/nixos/` và dùng cho hardware, service hệ thống, networking, firewall, virtualization và desktop environment nền.

Home Manager module đặt trong `modules/home/` và dùng cho ứng dụng người dùng, shell, terminal, Git, trình duyệt, editor, XDG và user service.

## 2. Chọn nhóm

```text
modules/nixos/{core,hardware,desktop,services,security,virtualization}
modules/home/{core,desktop,programs,services,shell}
```

Tên file dùng chữ thường và dấu gạch ngang. Tránh tên mơ hồ như `misc.nix`.

## 3. Mẫu NixOS module

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.example;
in
{
  options.my.services.example.enable =
    lib.mkEnableOption "example service";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.example
    ];
  };
}
```

## 4. Mẫu Home Manager module

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.programs.example;
in
{
  options.my.programs.example.enable =
    lib.mkEnableOption "example application";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.example
    ];
  };
}
```

## 5. Import và bật

```nix
{
  imports = [
    ../../modules/home/programs/example.nix
  ];

  my.programs.example.enable = true;
}
```

Module không tự kích hoạt chỉ vì file tồn tại.

## 6. Quy tắc sở hữu package

Package được cài trong module sở hữu capability. Profile chỉ import module và bật option; không cài lại package.

## 7. Kiểm tra

```bash
cd /etc/nixos
nixosctl fmt
nixosctl check
nixosctl build
nixosctl diff
nixosctl test
```

## Checklist

```text
[ ] Chỉ có một capability
[ ] Namespace my.*
[ ] Không chứa hostname hoặc user cụ thể
[ ] Không import profile hoặc host
[ ] Không cài package trùng
[ ] Được import tường minh
[ ] Check và test thành công
```
