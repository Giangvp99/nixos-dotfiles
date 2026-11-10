
# Desktop Design System

## Direction
Modern, minimal, cohesive Linux desktop.
Dark-first, responsive and performance-conscious.

## Colors
- Base palette: existing Gruvbox theme.
- Reuse existing Stylix colors when available.
- Do not hardcode independent palettes per widget.
- Keep sufficient text/background contrast.

## Typography
- Reuse installed UI fonts.
- Use Nerd Fonts or icon fonts only where appropriate.
- Prefer consistent font sizes and weights.

## Layout
- Shared spacing scale: 4, 8, 12, 16, 24, 32 px.
- Consistent corner radius and component heights.
- Responsive to changing VM display dimensions.
- Avoid oversized controls at 1920x1080, scale 1.

## Motion
- Prefer subtle, purposeful animations.
- Keep animation durations consistent.
- Avoid unnecessary blur and GPU-heavy effects.

## Components
- Reuse existing QML components.
- Keep shared styling centralized.
- Do not introduce a new framework.
- Prefer simple implementations over abstraction.

## Compatibility
- Support the existing Hyprland and Quickshell setup.
- Preserve all existing functionality.
- Optimize for Proxmox SPICE graphics.
```

Đây là bản khởi đầu. Sau khi bạn chọn phong cách giao diện, chúng ta có thể chốt các thông số thiết kế cụ thể.

## 4. Plugins, Skills, MCP: dùng cái nào?

Tôi đề xuất theo bảng sau:

| Công cụ | Có nên dùng? | Lý do |
|---|---|---|
| Codex CLI | <icon name="check" color="success" inline/> Có | Công cụ chính |
| `AGENTS.md` | <icon name="check" color="success" inline/> Có | Quản lý quy tắc lâu dài |
| Git | <icon name="check" color="success" inline/> Có | Kiểm soát mọi thay đổi |
| GitHub plugin | Tùy chọn | Có ích khi review PR, issues, CI; không cần cho sửa file local |
| Custom skill | Để sau | Chỉ cần khi có quy trình lặp lại |
| Playwright MCP | Chưa cần | Chủ yếu dành cho UI web, không trực tiếp kiểm thử QML desktop |
| Figma MCP | Chưa cần | Chỉ hữu ích nếu thiết kế được quản lý trên Figma |
| Desktop screenshot/computer control | Cân nhắc sau | Hữu ích để Codex thực sự quan sát giao diện VM |
| Multi-agent | Không | Chưa cần thiết cho quy mô hiện tại |

### Khi nào nên tạo skill?

Skill khác `AGENTS.md` ở chỗ: `AGENTS.md` chứa các quy tắc luôn áp dụng, còn skill đóng gói một quy trình chuyên biệt mà Codex có thể sử dụng khi phù hợp. <Cite ref="turn828448search0"/>

Khi phát triển ổn định, bạn có thể tạo **một skill duy nhất tên `desktop-ui-check`** với nhiệm vụ:

1. Kiểm tra file QML/Lua đã sửa.
2. Xem sự khác biệt qua Git.
3. Kiểm tra lỗi Quickshell/Hyprland.
4. Hướng dẫn reload phù hợp.
5. Đưa ra kết luận có cần `nixosctl` hay không.

Đường dẫn custom skill theo cấu trúc Codex hiện nay:

```text
/etc/nixos/.agents/skills/desktop-ui-check/
└── SKILL.md
```

Bạn có thể dùng `$skill-creator` trong Codex để tạo skill khi cần. <Cite ref="turn828777search3"/>

Tuy nhiên, tôi sẽ **chưa tạo skill này ngay**. Trước tiên nên phát triển và kiểm chứng 3–5 thay đổi thực tế; khi các bước kiểm thử đã ổn định mới đóng gói thành skill.

### Có nên cài GitHub plugin?

Hiện tại không cần. Git CLI đã đủ để quản lý branch, commit, diff và push. GitHub plugin chỉ thực sự đáng dùng nếu sau này bạn muốn Codex xử lý pull request và review code trực tiếp trên GitHub.

## 5. Cấu hình quy trình Git để Codex không làm hỏng dự án

Điểm quan trọng nhất là **tách việc phát triển giao diện khỏi việc chỉnh sửa cấu hình hệ thống**.

Bạn đã có branch `feat/proxmox-vm`. Tôi đề xuất tạo một branch con:

```bash
cd /etc/nixos
git status
```

Sau khi đã commit hoặc sao lưu mọi chỉnh sửa hiện có:

```bash
git switch -c feat/proxmox-ui
```

Trong quá trình phát triển:

```text
feat/proxmox-vm
       │
       └── feat/proxmox-ui
               ├── status bar
               ├── launcher
               ├── notifications
               └── dashboard
```

Không bắt buộc tạo một branch cho mỗi widget. Một branch phát triển giao diện là đủ trong giai đoạn đầu; mỗi chức năng hoàn chỉnh được lưu thành một commit riêng.

### Quy trình phát triển một thay đổi

<box border radius="lg" padding={3} gap={2}>
  <list marker="number" gap={2}>
    <list-item>
      **Đưa yêu cầu cho Codex**

      Ví dụ: “Cải thiện status bar, giữ nguyên mọi chức năng đang chạy.”
    </list-item>
    <list-item>
      **Codex đọc và lập kế hoạch**

      Chỉ liên quan đến những QML component cần thiết.
    </list-item>
    <list-item>
      **Codex chỉnh sửa**

      Giữ nguyên live symlink. Không sửa NixOS modules.
    </list-item>
    <list-item>
      **Kiểm thử trên VM**

      Quan sát Quickshell, kiểm tra lỗi runtime và các thao tác.
    </list-item>
    <list-item>
      **Review Git diff**

      ```bash
      git diff --check
      git diff -- dots/
      ```
    </list-item>
    <list-item>
      **Commit khi đã hài lòng**

      Ví dụ: `feat(quickshell): refine status bar layout`
    </list-item>
  </list>
</box>

Không cần dùng `nixosctl build` hay `switch` khi chỉ thay đổi QML/Lua live. Chỉ dùng `nixosctl` khi sửa các module NixOS, Home Manager, dependency hoặc service.

Lưu ý quan trọng: **Git không thể rollback giao diện một cách an toàn nếu trong cùng một commit có cả thay đổi NixOS system và nhiều widget khác nhau.** Đây là lý do nên giữ commit nhỏ và theo chức năng.

## 6. Cách khởi chạy Codex tôi khuyến nghị

Trước tiên kiểm tra:

```bash
cd /etc/nixos/dots
codex --help
```

Sau đó chạy:

```bash
codex --sandbox workspace-write \
  --ask-for-approval on-request
```

Khởi chạy tại `dots` giúp đặt thư mục làm việc vào phần giao diện, thay vì toàn bộ repository.

Đây là một giới hạn thao tác hữu ích, nhưng có hai lưu ý:

- Codex vẫn có thể đọc những file ngoài thư mục này nếu quyền truy cập cho phép.
- Nếu Codex được cấp thêm quyền ghi hoặc bạn chấp thuận thao tác vượt sandbox, nó có thể sửa cả file ngoài `dots`.

Nếu `/etc/nixos/dots` đang khóa quyền ghi, bạn cần mở chế độ chỉnh sửa phù hợp. **Không nên chạy `sudo codex` hoặc cấp quyền `777` cho repository.**

Bên cạnh đó, để đảm bảo Codex nhìn được giao diện thực tế, ở giai đoạn đầu bạn nên tự chụp ảnh màn hình VM và gửi cho Codex sau mỗi lần sửa lớn. Có thể dùng công cụ Wayland screenshot đã được cài trên hệ thống; không cần vội cài một MCP có quyền điều khiển toàn desktop.

## 7. Prompt đầu tiên nên giao cho Codex

Tôi khuyên bắt đầu bằng nhiệm vụ **audit giao diện hiện tại**, chưa yêu cầu nó viết lại bất cứ thứ gì.

<WritingBlock id="73184" variant="standard">Bạn là Senior Linux Desktop Engineer, chuyên sâu về NixOS, Hyprland Lua, Quickshell QML và QtQuick.

Hãy đọc `AGENTS.md`, `DESIGN.md` và khảo sát toàn bộ mã nguồn hiện có trong `dots/hypr` và `dots/quickshell`.

**Mục tiêu:** Từng bước phát triển một giao diện Linux hiện đại, đẹp, đồng bộ, cá nhân hóa cao và tối ưu hiệu năng trên NixOS Proxmox.

Trong nhiệm vụ đầu tiên, chỉ phân tích, chưa sửa code.

Hãy thực hiện:

1. Phân tích kiến trúc QML, Lua, các component, service, dependency và cơ chế live reload.
2. Xác định các thành phần đang hoạt động tốt cần giữ nguyên.
3. Phát hiện trùng lặp, logic khó bảo trì, cấu hình thừa, điểm yếu về bố cục và hiệu năng.
4. Đánh giá sự nhất quán của màu sắc, typography, icon, spacing, animation và responsive layout.
5. Đề xuất tối đa 5 ưu tiên cải thiện có tác động rõ ràng nhất đến trải nghiệm giao diện.
6. Với mỗi đề xuất, nêu các file dự kiến sửa, rủi ro, cách kiểm thử và khả năng ảnh hưởng đến laptop.
7. Không tự ý cài package, thay đổi module NixOS, sửa Flake hay tạo framework mới.

**Nguyên tắc:** Ưu tiên cải tiến mã nguồn hiện có. Không refactor chỉ để làm code có vẻ hiện đại hơn. Không tạo file, thư mục hoặc lớp trừu tượng mới nếu chưa có nhu cầu thực tế.

Trả lời bằng tiếng Việt, ngắn gọn nhưng rõ ràng, có dẫn chiếu đến các file thực tế. Chờ tôi chọn hạng mục trước khi chỉnh sửa.</WritingBlock>

Sau lần audit, mỗi lần bạn chỉ nên giao một mục tiêu cụ thể, chẳng hạn: “Thiết kế lại status bar theo phong cách tối giản, giữ nguyên toàn bộ chức năng đang hoạt động, chỉ sửa QML cần thiết và kiểm thử ở độ phân giải 1920×1080 scale 1.”

## 8. Lộ trình phát triển phù hợp nhất

Tôi đề xuất tiến hành theo thứ tự:

| Giai đoạn | Công việc | Tiêu chí hoàn thành |
|---|---|---|
| 1 | Audit cấu hình Hyprland và Quickshell | Hiểu kiến trúc, không thay đổi code |
| 2 | Design system và icon/font | Không còn icon lỗi, giao diện thống nhất |
| 3 | Status bar và workspaces | Đẹp, responsive, hoạt động ổn định |
| 4 | Launcher và control center | Thao tác nhanh, nhất quán với status bar |
| 5 | Notifications, dashboard, animations | Hoàn thiện trải nghiệm, không gây lag |

Đặc biệt, lỗi Hyprland Lua không nhận thay đổi sau reload mà bạn từng gặp cần được xử lý hoặc có quy trình kiểm thử riêng trước khi để Codex sửa nhiều module Lua cùng lúc.

---

## 9. Checklist thiết lập

{@body const items = ["Giữ nguyên nhánh Proxmox ổn định làm điểm khôi phục","Tạo branch feat/proxmox-ui","Tạo dots/AGENTS.md","Tạo dots/DESIGN.md","Kiểm tra quyền ghi trong dots và sandbox Codex","Chạy Codex audit ở chế độ chỉ phân tích","Chọn một widget đầu tiên để phát triển"]}
{@body const [done,setDone] = DIL.useState([])}
<box border radius="lg" padding={3} gap={2}>
  <row justify="between" align="center">
    **Các bước cần hoàn thành**
    <text color="secondary" size="xs" tabularNums>{done.length}/{items.length}</text>
  </row>
  <box height="5px" background="surface-tertiary" radius="full" clip>
    <box height="100%" width={`${done.length/items.length*100}%`} background="rgba(30,150,110,0.8)" radius="full"/>
  </box>
  {#each items as item,i}
    <checkbox key={i} checked={done.includes(i)} onChange={v=>setDone(old=>v?[...old,i]:old.filter(x=>x!==i))}>{item}</checkbox>
  {/each}
</box>

**Kết luận:** Đối với dự án của bạn, tôi chọn **Codex CLI + AGENTS.md + DESIGN.md + Git + nixosctl** làm bộ công cụ chính. Chưa cần plugins, MCP hay nhiều skills. Sau khi phát triển một số widget và quy trình kiểm thử đã lặp lại ổn định, mới tạo một custom skill để tự động hóa.

Đây là cách giữ Codex đủ mạnh để giúp bạn xây dựng giao diện Hyprland và Quickshell theo ý muốn, nhưng dự án vẫn nhỏ gọn, dễ kiểm soát, dễ rollback và có thể tái sử dụng cho laptop.
