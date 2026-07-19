# Khôi phục hệ thống

## Thứ tự ưu tiên

1. Khởi động lại sau `nixos-rebuild test`.
2. Rollback generation.
3. Chọn generation cũ khi boot.
4. Quay lại commit hoặc tag Git.
5. Khôi phục secret và dữ liệu.

Không garbage collect khi chưa phục hồi xong.

## Sau `nixos-rebuild test`

Nếu cấu hình test gây lỗi:

```bash
sudo reboot
```

Máy sẽ trở về cấu hình boot mặc định trước đó.

## Rollback

```bash
nixosctl rollback
```

Hoặc:

```bash
sudo nixos-rebuild switch --rollback
```

Xem generation:

```bash
nixosctl generations
```

## Quay lại Git

```bash
cd /etc/nixos
git log --oneline --decorate -30
git tag --list --sort=-creatordate
git switch --detach <commit-or-tag>
```

Sau đó:

```bash
sudo nixos-rebuild build --flake /etc/nixos#j4n9-hplaptop
sudo nixos-rebuild test --flake /etc/nixos#j4n9-hplaptop
sudo nixos-rebuild switch --flake /etc/nixos#j4n9-hplaptop
```

Quay lại nhánh:

```bash
git switch <branch-name>
```

## Home Manager activation lỗi

```bash
systemctl status home-manager-ntgiang.service --no-pager
journalctl -u home-manager-ntgiang.service -b --no-pager
```

Nếu file hiện có sẽ bị ghi đè, sao lưu và di chuyển file đó rồi chạy lại test. Không dùng `force = true` khi chưa hiểu nguồn gốc file.

## SOPS age key

Vị trí dự kiến:

```text
/var/lib/sops-nix/key.txt
```

Kiểm tra:

```bash
sudo test -f /var/lib/sops-nix/key.txt
sudo stat /var/lib/sops-nix/key.txt
```

Khôi phục quyền:

```bash
sudo install -d -m 0700 /var/lib/sops-nix
sudo chmod 0600 /var/lib/sops-nix/key.txt
sudo chown root:root /var/lib/sops-nix/key.txt
```

Khóa phải có bản sao ngoại tuyến an toàn.

## Khôi phục flake.lock

```bash
cd /etc/nixos
git restore flake.lock
nixosctl check
nixosctl build
```

## Mạng lỗi

```bash
systemctl status NetworkManager --no-pager
nmcli general status
nmcli device status
```

## Giao diện đồ họa lỗi

Chuyển sang TTY bằng `Ctrl + Alt + F2`, đăng nhập rồi chạy:

```bash
systemctl status display-manager --no-pager
journalctl -u display-manager -b --no-pager
sudo nixos-rebuild switch --rollback
```

## Không làm khi đang khôi phục

- Không garbage collect.
- Không xóa profile Nix.
- Không sửa `hardware.nix` tùy tiện.
- Không xóa `flake.lock`.
- Không `git reset --hard` khi còn dữ liệu cần giữ.
- Không thay nhiều thứ cùng lúc.

## Checklist

```text
[ ] Đã xác định lỗi ở build, activation hay runtime
[ ] Đã lưu log
[ ] Đã thử reboot nếu dùng test
[ ] Đã xem generation
[ ] Đã thử rollback
[ ] Đã xác định commit hoặc tag tốt
[ ] Không garbage collect
[ ] Age key còn an toàn
[ ] Dữ liệu cá nhân có backup
```
