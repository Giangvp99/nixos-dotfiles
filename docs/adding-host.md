# Thêm host mới

## 1. Tạo thư mục

```bash
cd /etc/nixos
mkdir -p hosts/<hostname>
```

Cấu trúc tối thiểu:

```text
hosts/<hostname>/
├── default.nix
└── hardware.nix
```

## 2. Sinh hardware configuration

Thực hiện trên chính máy mới:

```bash
sudo nixos-generate-config --show-hardware-config   > /etc/nixos/hosts/<hostname>/hardware.nix
```

Không sao chép `hardware.nix` từ máy khác.

## 3. Tạo host

```nix
{
  imports = [
    ./hardware.nix
    ../../profiles/nixos/common.nix
  ];

  networking.hostName = "<hostname>";
  system.stateVersion = "<state-version-ban-đầu>";
}
```

Laptop Plasma:

```nix
{
  imports = [
    ./hardware.nix
    ../../profiles/nixos/common.nix
    ../../profiles/nixos/laptop.nix
    ../../profiles/nixos/plasma.nix
  ];

  networking.hostName = "<hostname>";
  system.stateVersion = "26.05";
}
```

## 4. Khai báo trong flake

```nix
hosts = {
  <hostname> = {
    system = "x86_64-linux";
    users = [
      ./users/ntgiang
    ];
  };
};
```

Host phải được khai báo tường minh, không tự quét `hosts/`.

## 5. Kiểm tra

```bash
nix flake show

nix eval   .#nixosConfigurations.<hostname>.config.networking.hostName

nix build   .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

Trên máy đích:

```bash
sudo nixos-rebuild test --flake /etc/nixos#<hostname>
systemctl --failed
systemctl --user --failed
journalctl -p 3 -b --no-pager
```

Sau khi ổn:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

## Checklist

```text
[ ] Có hardware.nix của đúng máy
[ ] Host chỉ import profile cần thiết
[ ] Không chứa cấu hình ứng dụng người dùng
[ ] Có system.stateVersion
[ ] Được khai báo tường minh trong flake
[ ] Xuất hiện trong flake checks
[ ] Build và test thành công
```
