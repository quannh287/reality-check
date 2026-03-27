# SwiftLint Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tích hợp SwiftLint vào project RealityCheck qua SPM build tool plugin, chạy tự động khi build cả trong Xcode lẫn CI.

**Architecture:** Thêm `SwiftLintBuildToolPlugin` vào Xcode project như một SPM package dependency — plugin tự động chạy khi `xcodebuild build`, không cần cài tool riêng. Cả hai targets (`RealityCheck` và `RealityCheckWidgetExtension`) đều được lint. CI tận dụng cùng build step hiện có, chỉ cần thêm flag `-skipPackagePluginValidation`.

**Tech Stack:** SwiftLint 0.57+ (via SPM), Xcode 16.3, GitHub Actions (macos-15)

---

## File Map

| File | Thay đổi |
|------|----------|
| `RealityCheck.xcodeproj/project.pbxproj` | Thêm `XCRemoteSwiftPackageReference` SwiftLint, 2× `XCSwiftPackageProductDependency` (plugin), `packagePluginDependencies` vào 2 targets |
| `RealityCheck.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | Tự động cập nhật bởi xcodebuild khi resolve packages |
| `.swiftlint.yml` | Config minimal mới ở project root |
| `.github/workflows/build.yml` | Fix scheme name + thêm `-skipPackagePluginValidation` |

---

## Task 1: Create Worktree and Branch

**Files:**
- (git worktree only, không có file changes)

- [ ] **Step 1: Tạo worktree mới**

Chạy từ project root `/Users/quannh2871/Development/IOS/reality-check`:

```bash
git worktree add worktrees/feature/swiftlint-setup -b feature/swiftlint-setup
```

Expected: `Preparing worktree (new branch 'feature/swiftlint-setup')`

- [ ] **Step 2: Confirm worktree tồn tại**

```bash
git worktree list
```

Expected: thấy dòng `worktrees/feature/swiftlint-setup` với branch `feature/swiftlint-setup`

> **Tất cả các bước tiếp theo thực hiện trong `worktrees/feature/swiftlint-setup/`**

---

## Task 2: Create `.swiftlint.yml`

**Files:**
- Create: `worktrees/feature/swiftlint-setup/.swiftlint.yml`

- [ ] **Step 1: Tạo file config**

Tạo file `.swiftlint.yml` tại root của worktree với nội dung:

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

- [ ] **Step 2: Verify file tồn tại**

```bash
cat worktrees/feature/swiftlint-setup/.swiftlint.yml
```

Expected: nội dung yaml hiển thị đúng

- [ ] **Step 3: Commit**

```bash
cd worktrees/feature/swiftlint-setup && git add .swiftlint.yml && git commit -m "chore: add SwiftLint minimal config"
```

---

## Task 3: Fix CI Workflow

**Files:**
- Modify: `worktrees/feature/swiftlint-setup/.github/workflows/build.yml`

**Context:** CI dùng sai scheme `-scheme RealityCheckWidget` — shared scheme thực tế là `RealityCheckWidgetExtension`. Cần fix đồng thời thêm `-skipPackagePluginValidation` để SwiftLint plugin chạy được trong CI mà không bị block bởi trust prompt.

- [ ] **Step 1: Đọc file CI hiện tại**

```bash
cat worktrees/feature/swiftlint-setup/.github/workflows/build.yml
```

- [ ] **Step 2: Sửa scheme name và thêm plugin validation flag**

Thay toàn bộ nội dung `build.yml` bằng:

```yaml
name: Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-15

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.3.app

      - name: Build RealityCheck
        run: |
          xcodebuild build \
            -scheme RealityCheck \
            -project RealityCheck.xcodeproj \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            -skipPackagePluginValidation \
            | xcpretty || exit ${PIPESTATUS[0]}

      - name: Build RealityCheckWidget
        run: |
          xcodebuild build \
            -scheme RealityCheckWidgetExtension \
            -project RealityCheck.xcodeproj \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            -skipPackagePluginValidation \
            | xcpretty || exit ${PIPESTATUS[0]}
```

- [ ] **Step 3: Commit**

```bash
cd worktrees/feature/swiftlint-setup && git add .github/workflows/build.yml && git commit -m "ci: fix widget scheme name and add skipPackagePluginValidation"
```

---

## Task 4: Add SwiftLint SPM Plugin to Xcode Project

**Files:**
- Modify: `worktrees/feature/swiftlint-setup/RealityCheck.xcodeproj/project.pbxproj`

**Context quan trọng:** Đây là edit trực tiếp vào `project.pbxproj`. Cần thêm:
1. `XCRemoteSwiftPackageReference` cho SwiftLint package
2. 2× `XCSwiftPackageProductDependency` cho `SwiftLintBuildToolPlugin` (một cho mỗi target)
3. Đăng ký package vào `packageReferences` của project
4. Thêm `packagePluginDependencies` vào target `RealityCheck`
5. Thêm `packagePluginDependencies` vào target `RealityCheckWidgetExtension`

**KHÔNG thêm `PBXBuildFile` hay `PBXFileReference` thủ công** — project dùng `PBXFileSystemSynchronizedRootGroup`.

- [ ] **Step 1: Generate UUIDs và chạy script**

Chạy script Python sau từ project root của worktree:

```bash
cd worktrees/feature/swiftlint-setup && python3 << 'EOF'
import subprocess, re

def gen_uuid():
    r = subprocess.run(['uuidgen'], capture_output=True, text=True)
    return r.stdout.strip().replace('-', '')[:24]

PKG_UUID = gen_uuid()
PLUGIN_UUID_MAIN = gen_uuid()
PLUGIN_UUID_WIDGET = gen_uuid()

print(f"PKG_UUID={PKG_UUID}")
print(f"PLUGIN_UUID_MAIN={PLUGIN_UUID_MAIN}")
print(f"PLUGIN_UUID_WIDGET={PLUGIN_UUID_WIDGET}")

pbxproj = 'RealityCheck.xcodeproj/project.pbxproj'
with open(pbxproj, 'r') as f:
    content = f.read()

# 1. Add XCRemoteSwiftPackageReference for SwiftLint
old = '/* End XCRemoteSwiftPackageReference section */'
new = (
    f'\t\t{PKG_UUID} /* XCRemoteSwiftPackageReference "SwiftLint" */ = {{\n'
    f'\t\t\tisa = XCRemoteSwiftPackageReference;\n'
    f'\t\t\trepositoryURL = "https://github.com/realm/SwiftLint";\n'
    f'\t\t\trequirement = {{\n'
    f'\t\t\t\tkind = upToNextMajorVersion;\n'
    f'\t\t\t\tminimumVersion = 0.57.0;\n'
    f'\t\t\t}};\n'
    f'\t\t}};\n'
    f'/* End XCRemoteSwiftPackageReference section */'
)
assert old in content, "ERROR: XCRemoteSwiftPackageReference section not found"
content = content.replace(old, new)

# 2. Add XCSwiftPackageProductDependency entries for plugin (x2)
old = '/* End XCSwiftPackageProductDependency section */'
new = (
    f'\t\t{PLUGIN_UUID_MAIN} /* SwiftLintBuildToolPlugin */ = {{\n'
    f'\t\t\tisa = XCSwiftPackageProductDependency;\n'
    f'\t\t\tpackage = {PKG_UUID} /* XCRemoteSwiftPackageReference "SwiftLint" */;\n'
    f'\t\t\tproductName = SwiftLintBuildToolPlugin;\n'
    f'\t\t}};\n'
    f'\t\t{PLUGIN_UUID_WIDGET} /* SwiftLintBuildToolPlugin */ = {{\n'
    f'\t\t\tisa = XCSwiftPackageProductDependency;\n'
    f'\t\t\tpackage = {PKG_UUID} /* XCRemoteSwiftPackageReference "SwiftLint" */;\n'
    f'\t\t\tproductName = SwiftLintBuildToolPlugin;\n'
    f'\t\t}};\n'
    f'/* End XCSwiftPackageProductDependency section */'
)
assert old in content, "ERROR: XCSwiftPackageProductDependency section not found"
content = content.replace(old, new)

# 3. Register package in project packageReferences list
old = '\t\t\t\tF3A5D6AD2E67424E87133DBA /* XCRemoteSwiftPackageReference "DebugSwift" */,\n\t\t\t);'
new = (
    f'\t\t\t\tF3A5D6AD2E67424E87133DBA /* XCRemoteSwiftPackageReference "DebugSwift" */,\n'
    f'\t\t\t\t{PKG_UUID} /* XCRemoteSwiftPackageReference "SwiftLint" */,\n'
    f'\t\t\t);'
)
assert old in content, "ERROR: packageReferences list not found"
content = content.replace(old, new)

# 4. Add packagePluginDependencies to RealityCheck target
old = (
    '\t\t\tpackageProductDependencies = (\n'
    '\t\t\t\t95D755F3518F4EAF8F5E7EC9 /* DebugSwift */,\n'
    '\t\t\t);\n'
    '\t\t\tproductName = RealityCheck;'
)
new = (
    f'\t\t\tpackagePluginDependencies = (\n'
    f'\t\t\t\t{PLUGIN_UUID_MAIN} /* SwiftLintBuildToolPlugin */,\n'
    f'\t\t\t);\n'
    f'\t\t\tpackageProductDependencies = (\n'
    f'\t\t\t\t95D755F3518F4EAF8F5E7EC9 /* DebugSwift */,\n'
    f'\t\t\t);\n'
    f'\t\t\tproductName = RealityCheck;'
)
assert old in content, "ERROR: RealityCheck target packageProductDependencies not found"
content = content.replace(old, new)

# 5. Add packagePluginDependencies to RealityCheckWidgetExtension target
old = (
    '\t\t\tpackageProductDependencies = (\n'
    '\t\t\t);\n'
    '\t\t\tproductName = RealityCheckWidgetExtension;'
)
new = (
    f'\t\t\tpackagePluginDependencies = (\n'
    f'\t\t\t\t{PLUGIN_UUID_WIDGET} /* SwiftLintBuildToolPlugin */,\n'
    f'\t\t\t);\n'
    f'\t\t\tpackageProductDependencies = (\n'
    f'\t\t\t);\n'
    f'\t\t\tproductName = RealityCheckWidgetExtension;'
)
assert old in content, "ERROR: RealityCheckWidgetExtension target packageProductDependencies not found"
content = content.replace(old, new)

with open(pbxproj, 'w') as f:
    f.write(content)

print("SUCCESS: project.pbxproj updated")
EOF
```

Expected output:
```
PKG_UUID=<24-char hex>
PLUGIN_UUID_MAIN=<24-char hex>
PLUGIN_UUID_WIDGET=<24-char hex>
SUCCESS: project.pbxproj updated
```

Nếu có `ERROR:` → dừng lại, kiểm tra xem string anchor trong project.pbxproj có khớp không. Đừng tiếp tục.

- [ ] **Step 2: Verify các entry mới có trong file**

```bash
cd worktrees/feature/swiftlint-setup && grep -c "SwiftLint\|SwiftLintBuildToolPlugin\|packagePluginDependencies" RealityCheck.xcodeproj/project.pbxproj
```

Expected: ít nhất `7` (1 package ref + 2 plugin deps + 2 packagePluginDependencies entries + 2 SwiftLint strings)

- [ ] **Step 3: Commit**

```bash
cd worktrees/feature/swiftlint-setup && git add RealityCheck.xcodeproj/project.pbxproj && git commit -m "chore: add SwiftLint SPM build tool plugin to Xcode project"
```

---

## Task 5: Verify Builds

**Files:**
- Read-only — chỉ verify, không sửa thêm gì

**Context:** Lần đầu build sẽ resolve và compile SwiftLint package, có thể mất 2-5 phút. `Package.resolved` sẽ tự động được tạo/cập nhật.

- [ ] **Step 1: Build RealityCheck target**

```bash
cd worktrees/feature/swiftlint-setup && xcodebuild build \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation \
  2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

Nếu build fail:
- Nếu lỗi `packagePluginDependencies` / `XCSwiftPackageProductDependency` → kiểm tra lại syntax trong project.pbxproj
- Nếu lỗi `Could not resolve package` → kiểm tra URL package đúng chưa
- Nếu SwiftLint warnings xuất hiện → đây là behavior mong đợi, không phải lỗi

- [ ] **Step 2: Build RealityCheckWidgetExtension target**

```bash
cd worktrees/feature/swiftlint-setup && xcodebuild build \
  -scheme RealityCheckWidgetExtension \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation \
  2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Verify Package.resolved được tạo**

```bash
cat "worktrees/feature/swiftlint-setup/RealityCheck.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
```

Expected: JSON file có entry cho `SwiftLint` với `identity = "swiftlint"`

- [ ] **Step 4: Stage Package.resolved và commit**

```bash
cd worktrees/feature/swiftlint-setup && git add "RealityCheck.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" && git commit -m "chore: lock SwiftLint version in Package.resolved"
```

---

## Task 6: Create Pull Request

**Files:**
- (git/GitHub operations only)

- [ ] **Step 1: Verify branch có đủ commits**

```bash
cd worktrees/feature/swiftlint-setup && git log --oneline main..HEAD
```

Expected: thấy các commits từ Task 2-5

- [ ] **Step 2: Push branch**

```bash
cd worktrees/feature/swiftlint-setup && git push -u origin feature/swiftlint-setup
```

- [ ] **Step 3: Tạo PR**

```bash
cd worktrees/feature/swiftlint-setup && gh pr create \
  --title "chore: setup SwiftLint via SPM build tool plugin" \
  --body "$(cat <<'EOF'
## Summary

- Thêm SwiftLint 0.57+ vào project qua SPM `SwiftLintBuildToolPlugin`
- Plugin chạy tự động khi build cả hai targets: `RealityCheck` và `RealityCheckWidgetExtension`
- Minimal config (`.swiftlint.yml`) tại project root: disabled trailing_whitespace/todo, opt-in empty_count
- Fix bug CI: scheme `RealityCheckWidget` → `RealityCheckWidgetExtension`
- Thêm `-skipPackagePluginValidation` cho CI để plugin chạy không bị block

## Test plan

- [ ] Build RealityCheck target thành công (`** BUILD SUCCEEDED **`)
- [ ] Build RealityCheckWidgetExtension target thành công
- [ ] SwiftLint warnings hiển thị inline trong Xcode (nếu có violations)
- [ ] CI passes trên branch này

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 4: Verify PR được tạo và in URL ra**

```bash
cd worktrees/feature/swiftlint-setup && gh pr view --json url -q .url
```

---

## Notes

- **xcpretty và SwiftLint output:** CI pipe qua xcpretty nên SwiftLint warnings không hiện trong logs, nhưng errors vẫn làm build fail. Đây là behavior chấp nhận được cho setup ban đầu.
- **force_unwrapping:** Đã bị comment out trong config. Bật sau khi kiểm tra xem có bao nhiêu violations hiện có (`grep -r "!" RealityCheck/ --include="*.swift" | wc -l`).
- **strict mode:** Không bật trong scope này. Khi codebase đã clean, thêm `strict: true` vào `.swiftlint.yml`.
