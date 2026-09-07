# Modules

Module là feature cấp sản phẩm.

Ví dụ:

bar/
launcher/
controlcenter/
notifications/
osd/

Module được phép dùng:

- config;
- services;
- components;
- utils.

Một module không nên expose chi tiết backend ra module khác.

Nếu feature lớn, tạo thư mục riêng.

Ví dụ:

launcher/
├── Launcher.qml
├── Search.qml
├── AppEntry.qml
├── README.md
└── Template.qml
