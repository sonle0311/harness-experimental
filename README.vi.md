# harness-experimental

## Trạng Thái Hiện Tại

Repository này đang ở Harness v0.

Chưa có phần triển khai ứng dụng và chưa có đặc tả sản phẩm cố định. Công việc
hiện tại là bộ harness có thể tái sử dụng: cấu trúc file, mô hình vận hành cho
agent, quy trình tiếp nhận tính năng, mẫu story, và kỳ vọng validation để giúp
con người cùng agent biến đặc tả được cung cấp sau này thành công việc triển
khai an toàn.

## Nguồn Sự Thật Về Sản Phẩm

Hiện chưa có hợp đồng sản phẩm nào được định nghĩa.

Khi người dùng cung cấp đặc tả dự án, hãy thêm hoặc tham chiếu đặc tả đó như
đầu vào cho lần buildout đầu tiên, sau đó tách thành các artifact nhỏ hơn:

- `docs/product/`: các file hợp đồng sản phẩm hiện hành, được tạo từ đặc tả.
- `docs/stories/`: story packet và backlog được tạo từ công việc đã chọn.
- `docs/TEST_MATRIX.md`: bảng điều khiển ánh xạ hành vi sang bằng chứng.
- `docs/decisions/`: các quyết định và tradeoff quan trọng.

Không giữ đặc tả riêng của một project hoặc bản chia nhỏ sản phẩm trong harness
này cho đến khi có một project thực sự cung cấp nội dung đó.

## Nguồn Harness

- `AGENTS.md`: điểm vào và quy tắc vận hành cho agent.
- `docs/HARNESS.md`: mô hình cộng tác giữa con người và agent.
- `docs/FEATURE_INTAKE.md`: phân loại công việc tiny, normal, high-risk.
- `docs/ARCHITECTURE.md`: quy tắc khám phá kiến trúc và ranh giới tổng quát.
- `docs/HARNESS_BACKLOG.md`: các đề xuất cải tiến harness.
- `docs/templates/`: mẫu tái sử dụng cho spec-intake, story, decision, và
  validation.

## Cấu Trúc Repository

```text
project/
  AGENTS.md
  README.md
  README.vi.md
  docs/
    HARNESS.md
    FEATURE_INTAKE.md
    ARCHITECTURE.md
    TEST_MATRIX.md
    HARNESS_BACKLOG.md
    product/
    stories/
    decisions/
    templates/
  scripts/
    README.md
```

## Quy Tắc Làm Việc

Prompt yêu cầu triển khai không đi thẳng vào code. Trước tiên, chúng phải đi
qua feature intake, được tách thành story-sized work khi cần, và luôn mang theo
kỳ vọng về product validation cùng harness maintenance.

## Cài Harness Vào Một Project

### macOS, Linux, hoặc Git Bash

Từ thư mục project đích, chạy:

```bash
curl -fsSL "https://raw.githubusercontent.com/sonle0311/harness-experimental/main/scripts/install-harness.sh?$(date +%s)" | bash -s -- --yes
```

Hoặc cài vào một đường dẫn cụ thể:

```bash
curl -fsSL "https://raw.githubusercontent.com/sonle0311/harness-experimental/main/scripts/install-harness.sh?$(date +%s)" | bash -s -- --directory /path/to/project --yes
```

### Windows PowerShell

Từ thư mục project đích, chạy:

```powershell
& ([ScriptBlock]::Create((Invoke-RestMethod "https://raw.githubusercontent.com/sonle0311/harness-experimental/main/scripts/install-harness.ps1?$(Get-Date -UFormat %s)"))) -Yes
```

Hoặc cài vào một đường dẫn cụ thể:

```powershell
& ([ScriptBlock]::Create((Invoke-RestMethod "https://raw.githubusercontent.com/sonle0311/harness-experimental/main/scripts/install-harness.ps1?$(Get-Date -UFormat %s)"))) -Directory "C:\path\to\project" -Yes
```

Nếu target đã có `AGENTS.md`, `docs/`, hoặc `scripts/`, installer sẽ cảnh báo
và dừng trước khi ghi file. Hãy dùng thư mục target trống, hoặc di chuyển các
đường dẫn đó trước khi chạy installer. Dùng `--dry-run` để xem trước thay đổi.
Installer và story của installer trong repository này sẽ không được copy vào
project đích. Trên Windows PowerShell, dùng `-DryRun`, `-Force`, và `-Yes` thay
cho các tùy chọn kiểu Bash là `--dry-run`, `--force`, và `--yes`.
