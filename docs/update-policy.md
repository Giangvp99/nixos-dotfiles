# Chính sách cập nhật

## Mục tiêu

Cập nhật phải được kiểm tra trước khi áp dụng, không tự động `switch`, không trộn dependency update với refactor lớn và luôn có đường quay lại.

## Tần suất

Khuyến nghị một đến hai tuần một lần.

## Điều kiện trước cập nhật

- Git sạch.
- Cấu hình hiện tại đã commit.
- Không đang thực hiện refactor lớn.
- Có thời gian kiểm tra.
- Có thể khởi động lại máy nếu cần.

```bash
cd /etc/nixos
git status
```

## Quy trình thông thường

```bash
nixosctl update
```

Lệnh chỉ nên:

1. Kiểm tra Git sạch.
2. Cập nhật `flake.lock`.
3. Chạy `nix flake check`.
4. Build host.
5. Hiển thị `nvd diff`.
6. Dừng lại, không tự động switch.

Sau đó:

```bash
nixosctl test
systemctl --failed
systemctl --user --failed
journalctl -p 3 -b --no-pager
```

Nếu ổn:

```bash
nixosctl switch
git add flake.lock
git commit -m "chore: update flake inputs"
```

## Khi cập nhật lỗi

```bash
git restore flake.lock
nixosctl check
nixosctl build
```

Không switch khi check hoặc build chưa thành công.

## Nâng phiên bản NixOS

```bash
git switch -c upgrade/nixos-<version>
```

Cập nhật đồng bộ nixpkgs, Home Manager, Stylix và các input theo release.

Không đồng thời nâng NixOS, đổi desktop, đổi kernel, thay filesystem và tái cấu trúc lớn.

## Stable và unstable

Stable là mặc định. Unstable chỉ dùng cho package cụ thể và phải nhìn thấy rõ ở module sử dụng.

## State version

Không tự động thay đổi:

```nix
system.stateVersion
home.stateVersion
```

## Checklist

```text
[ ] Git sạch
[ ] Có commit ổn định
[ ] Update thành công
[ ] Đã xem diff
[ ] Test thành công
[ ] Không có unit lỗi
[ ] Switch thành công
[ ] flake.lock đã commit
```
