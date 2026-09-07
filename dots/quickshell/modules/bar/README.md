# Bar Module

Persistent top bar.

## Structure

Bar.qml
├── BarLeft.qml
├── BarCenter.qml
└── BarRight.qml

widgets/
├── Workspaces.qml
├── ActiveWindow.qml
└── Clock.qml

## Responsibility

Bar.qml:

- tạo PanelWindow;
- reserve top screen area;
- quản lý background/layout cấp cao.

BarLeft/Center/Right:

- composition;
- không chứa system logic.

widgets:

- hiển thị feature cụ thể;
- bind vào service.

## Khi thêm widget

Ví dụ Audio:

1. tạo AudioService nếu chưa có;
2. tạo widgets/Audio.qml;
3. thêm Audio vào widgets/qmldir;
4. thêm Audio vào BarRight;
5. cập nhật README.
