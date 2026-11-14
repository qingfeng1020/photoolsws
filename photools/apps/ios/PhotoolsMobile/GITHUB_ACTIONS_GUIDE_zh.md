# 用 GitHub Actions 自己编译 NikonGPS（无需 Mac）

> 你已经把代码改动都做好了，剩下的编译可以**完全靠 GitHub 免费云端完成**，全程点鼠标，不用 Mac、不用命令行。

---

## 总流程一览（约 15 分钟）

```
1. 注册/登录 GitHub
        ↓
2. Fork 仓库到你自己账号（复制一份，变成你的）
        ↓
3. 上传我改好的代码（或直接编辑）
        ↓
4. 打开 Actions 页，点一次「运行」按钮
        ↓
5. 等 5~8 分钟，下载编译好的 .ipa
        ↓
6. 传到 iPhone，用巨魔安装
```

---

## 第 1 步：注册 GitHub 账号

1. 打开 https://github.com
2. 右上角 **Sign up**，用邮箱注册（免费即可）；
3. 注册后登录。

> 如果你已有 GitHub 账号，跳过这一步。

---

## 第 2 步：Fork（复制）仓库

1. 打开原仓库：https://github.com/vincentchyu/photools
2. 点右上角 **Fork** 按钮；
3. 弹出窗口里，**Owner 选择你自己的账号**，点 **Create fork**；
4. 等几秒，你会进入 `github.com/你的用户名/photools` —— 这就是你自己的副本了。

---

## 第 3 步：把改好的代码传上去

这一步把你电脑上已经改好的代码，上传到你的 fork 仓库。有**两种方式**，任选其一：

### 方式 A（推荐，最省事）：直接用网页上传改过的文件

我在你本地改了这些文件（都在 `apps/ios/PhotoolsMobile/` 目录下）：

| 文件 | 类型 |
|---|---|
| `Package.swift` | 修改 |
| `project.yml` | 修改 |
| `Sources/PhotoolsMobileCore/Views/MainDashboardView.swift` | 修改 |
| `Sources/PhotoolsMobileCore/Views/PairingGuideView.swift` | 修改 |
| `Sources/PhotoolsMobileCore/Views/GPXTrackHistoryView.swift` | 修改 |
| `Sources/PhotoolsMobileCore/Views/AddCameraManuallyView.swift` | **新增** |
| `Sources/PhotoolsMobileCore/Services/NikonBluetoothManager.swift` | 修改 |
| `Sources/PhotoolsMobileCore/Services/CameraSyncCoordinator.swift` | 修改 |
| `.github/workflows/build-ios.yml` | **新增** |

在 GitHub 网页上逐个文件替换/新增即可（文件内容都在你本地，可以用我提供的方式拿到）。

### 方式 B：用 Git 命令一键上传（如果你会用命令行）

在你本地的 `photools` 目录下（已经 clone 好了），执行：

```bash
cd /c/Users/15699/WorkBuddy/2026-11-14-08-48-46/photools

# 把原仓库地址改成你自己的 fork
git remote set-url origin https://github.com/你的用户名/photools.git

# 添加所有改动
git add -A
git commit -m "支持 iOS 15 巨魔侧载 + 手动添加相机凭据"

# 推送
git push origin main
```

> 替换「你的用户名」为你实际的 GitHub 用户名。

---

## 第 4 步：触发编译（重点！）

1. 打开你的 fork 仓库页面：`github.com/你的用户名/photools`
2. 点顶部菜单的 **Actions**；
3. 如果页面提示「I understand my workflows, go ahead and enable them」，点绿色按钮启用；
4. 左侧找到工作流 **「Build NikonGPS IPA (iOS 15 / TrollStore)」**；
5. 点右侧 **Run workflow** 按钮，再点绿色 **Run workflow** 确认；
6. 会出现一个转圈的黄色圆点，表示编译开始。

---

## 第 5 步：下载 .ipa

1. 等 **5~8 分钟**（macOS 编译 + 打包），页面会自动刷新；
2. 当黄色圆点变成**绿色对勾**，说明编译成功；
3. 点进去这个任务，滑到页面底部，找到 **Artifacts** 区的 `NikonGPS-iOS15.0-ipa`；
4. 点它下载，解压后就是 `NikonGPS-iOS15.0.ipa`。

> 如果圆点变**红色叉叉**，说明编译失败，把报错日志发给我，我帮你修。

---

## 第 6 步：装到 iPhone 6s

1. 把 `.ipa` 传到 iPhone（AirDrop / 微信 / 网盘 / 数据线）；
2. 在「文件」App 里找到它；
3. 点分享 → 选 **TrollStore** → 安装；
4. 桌面出现 **NikonGPS** 图标，即可使用。

---

## 常见问题

**Q：GitHub Actions 免费吗？**
A：公共仓库（fork 出来默认是 public）**完全免费且不限时**。私有仓库每月有免费额度，macOS 编译一次约消耗 5~8 分钟，一个月编译几次足够用。

**Q：我不小心把 fork 设成私有仓库了怎么办？**
A：在仓库 Settings → General → Danger Zone 底部可改回 public，或用免费额度也行。

**Q：编译出来的 ipa 没签名能装吗？**
A：能。巨魔（TrollStore）会自动给 ipa 重新签名（fakesign / ldid），这正是巨魔的核心能力，所以无签名 ipa 完全没问题。

**Q：为什么不用我自己电脑编译？**
A：编译 iOS 必须要 macOS + Xcode，Windows 做不到。GitHub Actions 的 macOS 云主机是免费替代方案。

**Q：以后更新代码要重新来一遍吗？**
A：不用。以后你只要改了代码，push 到 fork 仓库，再到 Actions 点一次 Run workflow 即可，其余自动化。

---

## 需要我帮忙的地方

如果哪一步卡住了（比如 fork 报错、Actions 红色失败、artifact 找不到），**把截图或报错文字发给我**，我帮你排查。
