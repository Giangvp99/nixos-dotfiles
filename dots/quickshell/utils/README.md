# Utils

Pure JavaScript helpers.

Utils không:

- sở hữu state;
- gọi Process;
- gọi DBus;
- biết UI.

Ví dụ:

- formatBytes();
- clamp();
- formatDuration();
- iconForPercentage().

Nếu helper cần giữ state, nó không còn là utility.

`AppSearch.js` supplies pure desktop-entry normalization, indexing and ranking.
It does not launch apps or own runtime state; AppService owns the live index.
