# Kiến trúc dự án NixOS

## Mục tiêu

Dự án phải rõ ràng, ổn định, dễ kiểm tra, dễ mở rộng nhiều host và nhiều người dùng; không phụ thuộc import ngầm và không tạo abstraction khi chưa có nhu cầu thực tế.

## Nguyên tắc xuyên suốt

```text
Module  → cung cấp một khả năng
Profile → lựa chọn và phối hợp nhiều khả năng
Host    → mô tả máy, phần cứng và ngoại lệ
User    → tạo tài khoản và nối Home Manager
Home    → mô tả môi trường cá nhân
Lib     → ghép các lớp thành hệ thống
Flake   → khai báo đầu vào và danh sách hệ thống
```

## Luồng ghép cấu hình

```text
flake.nix
└── lib/mk-host.nix
    └── hosts/<hostname>/default.nix
        ├── hardware.nix
        ├── profiles/nixos/*
        │   └── modules/nixos/*
        └── users/<username>/default.nix
            └── home.nix
                └── profiles/home/*
                    └── modules/home/*
```

## Module

Module cung cấp một capability độc lập, định nghĩa option trong namespace `my.*`, cấu hình package hoặc service thuộc capability đó và được bật bằng `lib.mkIf`.

Module không được import profile hoặc host, không chứa hostname hay user cụ thể, không tự quét thư mục và không quyết định vai trò tổng thể của máy.

## Profile

Profile import và phối hợp các module cùng lớp. Profile có thể bật capability và chọn mặc định theo vai trò, nhưng không chứa UUID, hostname, tên user hoặc cấu hình ứng dụng dài.

Chỉ tạo profile khi có vai trò thực tế hoặc một tổ hợp được dùng lặp lại.

## Host

Host chứa `hardware.nix`, hostname, profile được chọn, ngoại lệ riêng của máy và `system.stateVersion`.

Host không chứa cấu hình chi tiết Git, VS Code, trình duyệt, shell hoặc danh sách package người dùng lớn.

## User và Home

`users/<username>/default.nix` tạo tài khoản NixOS, gán nhóm, chọn shell và nối Home Manager.

`users/<username>/home.nix` chọn Home profile, khai báo thông tin cá nhân và giữ `home.stateVersion`.

## Ranh giới NixOS và Home Manager

NixOS sở hữu boot, kernel, hardware, networking, system service, firewall, daemon ảo hóa, display manager, desktop environment nền, user account, system secret và font hệ thống.

Home Manager sở hữu ứng dụng người dùng, terminal, shell, Git, trình duyệt, editor, XDG, MIME, Plasma user settings và user service.

## Chiều phụ thuộc hợp lệ

```text
flake → lib → host → NixOS profile → NixOS module
host → user → home → Home profile → Home module
```

## Chiều phụ thuộc bị cấm

```text
module → profile
module → host
profile → host
NixOS module → Home module
Home module → NixOS module
module dùng chung → user cụ thể
```

## Namespace

NixOS:

```text
my.core.*
my.hardware.*
my.desktop.*
my.services.*
my.security.*
my.virtualization.*
```

Home Manager:

```text
my.core.*
my.desktop.*
my.programs.*
my.services.*
my.shell.*
```

Không dùng lại `systemSettings.*` hoặc `userSettings.*`.

## Quy tắc import

Host và module phải được khai báo tường minh. Không dùng `builtins.readDir` để tự sinh danh sách host hoặc module. `builtins.readDir` chỉ được dùng cho dữ liệu như danh sách theme.

## Quy tắc mở rộng

- Chỉ tạo module khi có capability độc lập.
- Chỉ tạo profile khi có vai trò thực tế.
- Chỉ tạo helper trong `lib/` khi có ít nhất hai trường hợp lặp.
- Stable là mặc định; unstable là ngoại lệ nhìn thấy rõ.
- Không dùng `mkForce` để che xung đột chưa hiểu.
- `system.stateVersion` chỉ đặt trong host.
- `home.stateVersion` chỉ đặt trong user home.
