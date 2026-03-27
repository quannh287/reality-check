# SwiftLint Setup — Design Spec

**Date:** 2026-03-27
**Status:** Approved

## Overview

Tích hợp SwiftLint vào project RealityCheck để enforce code style tự động, cả trong Xcode (inline warnings) lẫn CI (GitHub Actions).

## Approach

Dùng SwiftLint SPM plugin — thêm package dependency vào Xcode project, không cần cài tool riêng. Version được lock trong `Package.resolved`, đảm bảo nhất quán giữa dev và CI.

## Components

### 1. SPM Package Dependency

- **URL:** `https://github.com/realm/SwiftLint`
- **Version:** up-to-next-major từ `0.57.0`
- **Plugin:** `SwiftLintBuildToolPlugin` attached vào 2 targets: `RealityCheck` và `RealityCheckWidgetExtension` (tên Xcode target, không phải folder `RealityCheckWidget`)
- SwiftLint chạy tự động mỗi khi build, warnings hiện inline trong Xcode editor

### 2. `.swiftlint.yml` (project root)

Minimal ruleset — ít noise, chỉ enforce những thứ quan trọng:

```yaml
disabled_rules:
  - trailing_whitespace
  - todo

opt_in_rules:
  - empty_count
  # - force_unwrapping  # bật sau khi kiểm tra số violations hiện có

excluded:
  - RealityCheckTests
  - RealityCheckUITests
  - worktrees

line_length: 120
```

### 3. CI Integration

SwiftLint chạy tự động trong bước `xcodebuild build` hiện có (qua SPM plugin) — không cần job riêng hay bước install thêm.

**Lưu ý xcpretty:** CI hiện pipe qua `xcpretty`, vốn có thể suppress một số output của SwiftLint plugin. Warnings sẽ không hiện trong CI logs, nhưng errors (violations configured as errors) vẫn làm build fail qua exit code. Để thấy đầy đủ SwiftLint output trong CI, bỏ `| xcpretty` trong build step hoặc dùng `xcpretty --report junit`.

## Data Flow

```
xcodebuild build
  └── SwiftLintBuildToolPlugin (SPM)
        └── swiftlint lint (dùng .swiftlint.yml)
              └── warnings/errors → Xcode editor / CI logs
```

## Files Changed

| File | Thay đổi |
|------|----------|
| `RealityCheck.xcodeproj/project.pbxproj` | Thêm SPM package + plugin reference cho targets `RealityCheck` và `RealityCheckWidgetExtension` |
| `RealityCheck.xcodeproj/.../Package.resolved` | Lock SwiftLint version |
| `.swiftlint.yml` | Config mới ở project root |

## Implementation Strategy

- Tạo worktree tại `worktrees/feature/swiftlint-setup` từ branch `feature/swiftlint-setup`
- Sub-agent thực hiện toàn bộ implementation trong worktree đó
- Verify bằng `xcodebuild build` trước khi tạo PR
- Tạo PR từ `feature/swiftlint-setup` → `main`

## Out of Scope

- `strict: true` (có thể bật sau khi codebase đã clean)
- Auto-fix (`swiftlint --fix`) — để dev tự quyết định
- Pre-commit hooks
