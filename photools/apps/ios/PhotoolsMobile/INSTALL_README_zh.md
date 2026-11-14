# NikonGPS for iOS 15.8.x 巨魔侧载版 — 改造与安装指南

本指南说明我为你在 `vincentchyu/photools` 项目上做的改动，以及如何在 iPhone 6s (iOS 15.8.x) 上通过巨魔 (TrollStore) 安装使用。

---

## 一、这个软件是做什么的？

是的，这个软件（iOS 端名为 **NikonGPS / PhotoolsMobile**）就是**给尼康相机写 GPS 的**：

- 通过**蓝牙 BLE** 向尼康相机（Z 系列、D 系列等）注入 **WGS-84 经纬度 + 海拔**（41 字节 `GEO` 报文）；
- 同时同步 **UTC 时间与时区**（10 字节 `TIME` 报文）；
- 相比官方 SnapBridge：更省电、支持**多台相机并发**同步、后台杀不死。

它专门解决官方 SnapBridge「后台常被杀、单相机限制、发热耗电」的痛点。

---

## 二、为什么"每连接一台新相机都要重新编译"？

原项目的配对凭据（`DeviceID` / `Nonce`）是**编译期内嵌**在 `camera_credentials.json` 里的：

1. 用 `tools/extract_pklg_credentials.py` 从蓝牙抓包 (`.pklg`) 提取每台相机的 `DeviceID` + `Nonce`；
2. 写进 `camera_credentials.json`；
3. 重新编译 App 才能认识新相机。

这确实非常不方便。而且我还发现了**一个更深层的 bug**：对于「全新配对」的相机，原代码会把广播嗅探到的 `DeviceID` 误当成"已保存凭据"，导致握手成功后**不触发相机保存回调**——所以即使用户在 App 里完成了配对，这台相机也**不会被记住**，下次还要重编译。

---

## 三、我做了哪些改动？

### 1. 支持 iOS 15.0（原为 iOS 16.0）

| 文件 | 改动 |
|---|---|
| `Package.swift` | `.iOS(.v16)` → `.iOS(.v15)` |
| `project.yml` | `deploymentTarget` 从 `16.0` 降到 `15.0`（两处） |
| `MainDashboardView.swift` | `NavigationStack` → `NavigationView` |
| `PairingGuideView.swift` | `NavigationStack` → `NavigationView` |
| `GPXTrackHistoryView.swift` | `NavigationStack` → `NavigationView` |

`NavigationStack` 是 iOS 16 专属 API，换成 `NavigationView` 后即可在 iOS 15 上运行。

### 2. 修复"全新配对相机无法保存"的核心 bug

**文件：`NikonBluetoothManager.swift`**

- `CameraPeripheralSession.init`：不再把广播嗅探到的 `discoveredDeviceID` 回退当成已保存凭据（原来 `savedDeviceID ?? discoveredDeviceID`），全新配对时正确传入 `nil`，让状态机生成随机 ID 走全新配对流程；
- `getOrCreateSession`：只有当 **DeviceID 与 Nonce 同时有效**时才走「免配对直连」；否则走「全新配对」，配对成功后通过 `onHandshakeCompleted` 自动持久化相机凭据。

**效果：现在任何新相机，只要在 App 里配对成功一次，就会被永久记住，之后开机即连，无需重新编译。**

### 3. 新增「手动添加相机凭据」功能（彻底摆脱重编译）

**新增文件：`AddCameraManuallyView.swift`**

在 App 里新增了一个「添加相机」入口（首页右上角 + 配对向导底部），可以：

- 手动输入相机名称、`DeviceID`、`Nonce`（支持十六进制 `0x...` 或十进制）；
- 一键「**自动反解 Nonce**」：输入 `DeviceID` 后，利用 `SnapBridgeIdSolver` 从尼康 SnapBridge 首次配对的时间戳种子机制逆向求解 `Nonce`（对**已连过官方 SnapBridge** 的相机成功率极高）；
- 保存后永久存入 `UserDefaults`，从此免编译直连。

**文件：`CameraSyncCoordinator.swift`** — 新增 `addCameraManually(...)` 与 `parseDeviceIDString(...)` 两个方法。

### 4. 优化配对向导的引导

**文件：`PairingGuideView.swift`** — 在配对向导中新增「无法自动配对？手动添加凭据」区块，自动反解失败时引导用户手动补录，形成完整闭环。

---

## 四、如何在 Mac 上编译出 .ipa

> ⚠️ **关键前提**：编译 iOS 应用**必须在 macOS 上**完成（需要 Xcode / iOS SDK / 代码签名工具），Windows 无法编译。你目前只有 Windows 电脑，需要先准备一台 Mac（自有、借用、或租云 Mac，见第五节）。

在 Mac 上，进入 `apps/ios/PhotoolsMobile` 目录，执行：

```bash
# 1. 安装 xcodegen（若尚未安装）
brew install xcodegen

# 2. 一键编译打包
chmod +x build_trollstore.sh
./build_trollstore.sh
```

脚本会自动：
1. 用 `xcodegen` 根据 `project.yml` 生成 Xcode 工程；
2. 用 `xcodebuild` 以 `Release`、**无签名**、`iOS 15.0` 目标编译；
3. 打包成 `dist/NikonGPS-iOS15.0.ipa`。

产物路径：`dist/NikonGPS-iOS15.0.ipa`

---

## 五、如何获得 Mac 编译环境（你当前没有 Mac）

按省事程度排序：

1. **借用一台 Mac**（朋友/同事/公司）— 最快，跑上面两条命令即可；
2. **云 Mac 租用** — 按小时计费：
   - MacinCloud（https://www.macincloud.com）
   - MacStadium（https://www.macstadium.com）
   - AWS EC2 Mac 实例（mac1.metal，按需，较贵但稳定）
3. **本地黑苹果 / 虚拟机** — 不推荐：Xcode + iOS SDK 编译在 Hackintosh/VM 上问题多、易翻车，且性能差。

> 若你告诉我你更倾向哪种方式，我可以进一步帮你准备对应的远程编译步骤。

---

## 六、如何用巨魔 (TrollStore) 安装到 iPhone 6s

1. **确认你的 iPhone 6s 已装好巨魔**：iOS 15.8.x 属于巨魔支持的版本（iOS 14.0 – 16.6.1 均支持，15.8.x 在列），你说已经装好，直接进行下一步；
2. 把 `NikonGPS-iOS15.0.ipa` 传到 iPhone（AirDrop / 微信文件 / 网盘 / 数据线）；
3. 在 iPhone「文件」App 中找到该 `.ipa`；
4. 点分享 → 选择 **TrollStore** → 安装；
5. 安装完成后，桌面出现 **NikonGPS** 图标。

> 注意：巨魔安装的 App 由于是侧载签名，**首次打开可能提示"未受信任的开发者"**，需到 设置 → 通用 → VPN与设备管理 中信任对应的证书（如果 TrollStore 用 ldid 自动重签，通常无需此步）。

---

## 七、首次使用的相机配对步骤

1. 打开相机，`MENU` → 网络菜单 → **连接至智能设备** → **配对 (Bluetooth)** → **开始配对**；
2. 打开 NikonGPS App，点右上角「**配对新相机**」；
3. 在列表找到相机，点「**免配对直连**」（已连过 SnapBridge）或「**发起配对**」（全新相机）；
4. App 自动完成 Blowfish 握手，相机显示「已连接到智能设备」，配对记录永久保存；
5. 之后开启「**摄影巡航模式**」，相机开机/唤醒即自动连接注入 GPS。

**对于之前需要重新编译的新相机**，现在有两种免编译方式：
- **自动反解**：在「手动添加相机」里只填 `DeviceID`，点「自动反解 Nonce」；
- **直接配对**：全新相机直接在配对向导里「发起配对」，成功后自动记住。

---

## 八、注意事项

- 本项目仅供**个人学习与摄影交流**，凭据逆向基于公开资料（hurui200320/nsg、天空 Blond、HowenXu/snapbridge-id-extractor）；
- 使用前请在系统设置中允许「始终定位」「精确位置」「蓝牙」「后台刷新」，否则锁屏后 GPS 注入会受限；
- iPhone 6s 的 iOS 15.8.x 完全支持 CoreBluetooth 后台模式（`bluetooth-central` + `location`），功能不受影响。

---

## 九、改动文件清单

| 文件 | 状态 | 说明 |
|---|---|---|
| `Package.swift` | 修改 | 部署目标降级 iOS 15 |
| `project.yml` | 修改 | 部署目标降级 iOS 15 |
| `Sources/.../Views/MainDashboardView.swift` | 修改 | NavigationView + 添加入口 |
| `Sources/.../Views/PairingGuideView.swift` | 修改 | NavigationView + 手动添加入口 |
| `Sources/.../Views/GPXTrackHistoryView.swift` | 修改 | NavigationView |
| `Sources/.../Views/AddCameraManuallyView.swift` | **新增** | 手动添加相机凭据视图 |
| `Sources/.../Services/NikonBluetoothManager.swift` | 修改 | 修复全新配对保存 bug |
| `Sources/.../Services/CameraSyncCoordinator.swift` | 修改 | 新增手动添加/解析方法 |
| `build_trollstore.sh` | **新增** | 一键编译打包脚本 |
