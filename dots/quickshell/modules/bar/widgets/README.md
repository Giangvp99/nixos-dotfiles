# Bar Widgets

Widget là UI domain-specific của topbar.

## Widget responsibilities

Được:

- đọc service;
- sử dụng reusable component;
- format dữ liệu cho display;
- gửi action về service.

Không được:

- tự chạy polling nếu service đã cung cấp dữ liệu;
- tự sở hữu duplicate system state;
- chứa popup lớn;
- hardcode theme token.

## Template workflow

Copy:

    Template.qml

thành:

    Audio.qml

Sau đó:

1. đổi tên root;
2. import service;
3. xây visual bằng components;
4. thêm vào qmldir;
5. compose trong BarLeft/Center/Right.
