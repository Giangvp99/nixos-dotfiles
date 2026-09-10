# Adding a New Feature

Ví dụ feature: Bluetooth.

## Step 1 — xác định dữ liệu

Cần:

- Bluetooth enabled?
- connected device?
- battery?
- device list?

## Step 2 — tạo service

services/BluetoothService.qml

Service sở hữu toàn bộ state Bluetooth.

## Step 3 — thêm UI primitive nếu cần

Nếu cần toggle dùng chung:

components/Toggle.qml

Nếu chỉ Bluetooth sử dụng thì không tạo reusable component.

## Step 4 — tạo widget

modules/bar/widgets/Bluetooth.qml

Widget chỉ bind:

    Services.BluetoothService.enabled

## Step 5 — tích hợp

Thêm widget vào:

    modules/bar/BarRight.qml

## Step 6 — popup

Nếu click cần panel lớn:

    modules/bluetooth/

hoặc:

    modules/controlcenter/

Không nhét popup lớn vào Bluetooth.qml.

## Step 7 — test

Test:

- adapter off;
- adapter on;
- no devices;
- connecting;
- connected;
- disconnect;
- service unavailable.

## Step 8 — docs

Cập nhật README của service/module liên quan.
