# XCFramework Generator Script
Scripts to generate the Xcode Framework.

A simple, portable shell script to build Swift-compatible `.xcframework` bundles from any Xcode **project** or **workspace** — without cloning the repository.

Supports both iOS device (`iphoneos`) and iOS simulator (`iphonesimulator`) builds, with module stability enabled and no signing required.

---

## 🚀 Quick Start (via `curl`)

You can run the script directly from GitHub — no clone needed.

### For Workspace Projects (.xcworkspace)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nyan-lin-tun/xcframework-generator/v1.0.0/main.sh) \
  -w YourProject.xcworkspace \
  -s YourFramework \
  -n YourFramework
```

### For Xcode Projects (.xcodeproj)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nyan-lin-tun/xcframework-generator/v1.0.0/main.sh) \
  -p YourProject.xcodeproj \
  -s YourFramework \
  -n YourFramework
  ```

  # 🧮 XCFramework Build Usage Guide

This section explains all available parameters and provides ready-to-copy example commands  
for using the **build-xcframework.sh** script with both `.xcworkspace` and `.xcodeproj` setups.

---

## ⚙️ Parameters Reference

| Short | Long | Required | Description | Default |
|-------|------|-----------|-------------|----------|
| `-w` | `--workspace` | ✅ (if using workspace) | Path to `.xcworkspace` file | — |
| `-p` | `--project` | ✅ (if using project) | Path to `.xcodeproj` file | — |
| `-s` | `--scheme` | ✅ | The Xcode **scheme name** to build | — |
| `-n` | `--name` | ❌ | Framework name inside archive (defaults to scheme) | same as `--scheme` |
| — | `--config` | ❌ | Build configuration (`Release` or `Debug`) | `Release` |
| — | `--platforms` | ❌ | Comma-separated list of platforms (`ios`, `sim`) | `ios,sim` |
| — | `--out` | ❌ | Output directory path for final `.xcframework` | `./XCFramework` |
| `-h` | `--help` | ❌ | Show help and usage info | — |

---

## 🧩 Common Command Examples

Below are ready-to-copy commands for different use cases.  
Replace `<your-username>` and `<your-repo>` with your GitHub details, and update `v1.0.0` to your release tag or branch name.

---

### Build for Workspace (default iOS + Simulator)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nyan-lin-tun/xcframework-generator/v1.0.0/main.sh) \
  -w YourProject.xcworkspace \
  -s YourFramework \
  -n YourFramework
```

## Build for Project (Release Mode)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nyan-lin-tun/xcframework-generator/v1.0.0/main.sh) \
  -p YourProject.xcodeproj \
  -s YourFramework \
  -n YourFramework
  --config Release
```

## Build Debug version for simulator only
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nyan-lin-tun/xcframework-generator/v1.0.0/main.sh) \
  -w YourProject.xcworkspace \
  -s YourFramework \
  --config Debug \
  --platforms sim
```

## Specify Custom Output Directory
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nyan-lin-tun/xcframework-generator/v1.0.0/main.sh) \
  -p MyProject.xcodeproj \
  -s YourFramework \
  --out ./Builds/Frameworks
```

## Full Command Example (All Parameters)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nyan-lin-tun/xcframework-generator/v1.0.0/main.sh) \
  -p MyProject.xcodeproj \
  -s YourFramework \
  -n YourFramework \
  --config Release \
  --platforms ios,sim \
  --out ./XCFramework
```