# FlClash（本仓库版）

这是 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的一个个人 fork。上游代码原样保留，我们在上面做了少量定制，并用 GitHub Actions 全平台构建、自签名，发布到本仓库的 Releases（同时推送到 TG 频道 [@sanyeinfo](https://t.me/sanyeinfo)）。

**装哪个**

- **正式版**（推荐）：[最新 Release](../../releases/latest) 里 `FlClash` 开头的安装包。`/releases/latest` 永远指向正式版。
- **测试版**：在 [Releases 列表](../../releases) 里标着 *Pre-release* 的那个，跟上游 `dev` 走，比正式版新，也可能有问题。

Android 一般下 `-arm64-v8a.apk`（绝大多数手机）或 `-armeabi-v7a.apk`（老机器），模拟器下 `-x86_64.apk`。

## 版本号

```
<上游版本>.<我们自己的迭代号>
例如        0.9.1.13
```

- 前三段跟上游一致（取自上游 `pubspec.yaml`）。
- 第四位是我们自己的迭代号：**一路往上数、不随上游版本重置**。每次发版（正式版或测试版）都 +1，把 beta 晋升成正式版时也拿一个新号——这样 beta 用户也会收到正式版的更新提示。
- **Release tag 就是这四段版本**（如 `v0.9.1.13`）：App 拿自己的版本名去比 tag，相等就不提示，第四位变大了才提示。所以"上游没动、只是我们重建"现在也能推送给用户。（2026-10-18 之前发的包版本名只有三段，它们不会因为第四位提示更新，需要手动来下载页看一眼。）
- 桌面端（Linux / Windows / macOS）显示的也是四段：pub 不接受四段版本号，`pubspec.yaml` 里只能写三段，所以四段版本名在构建时以 `APP_VERSION` 注入（`setup.dart` 读 CI 的 `APP_VERSION_NAME`，写进 `env.json` 的 dart-define）。`PackageInfo.displayVersion` 优先用它，为空时回落到 `package_info_plus` 的三段。桌面端的「检查更新」也走这条，所以第四位变大同样能提示。
- 每次构建另外带一个 `<YYYYMMDD><当天序号>` 的**构建号**，写进 `pubspec.yaml`（构建时注入、不提交），它就是 APK 的 `versionCode`，保证新包一定比手机里那个"更新"，否则 Android 会拒绝覆盖安装。构建号记在 Release 说明里。

## 两个渠道

| 渠道 | 分支 | 内容 | Release |
| --- | --- | --- | --- |
| 正式版 | [`main`](../../tree/main) | 已经跑过 beta、被晋升进来的代码 | 标为 Latest |
| 测试版 | [`beta`](../../tree/beta) | 上游 `dev` 的最新代码 + 我们自己的改动 | prerelease，不抢占 Latest |

两个渠道**同包名**（`com.threely.clash`）、**同签名**，可以互相覆盖安装，`versionCode` 保证单调递增。

## 与上游的差异

改动都在 `main` / `beta` 上，以提交的形式存在。`beta` 每次同步时用 rebase 重放到上游最新代码上，`main` 则从 `beta` 晋升而来：

| 改动 | 说明 |
| --- | --- |
| 免责声明 | 保留全部条款文案，把手机上"照着把声明敲一遍"改成勾选确认 |
| 关于页 | 去掉上游的 Telegram 频道入口（那个频道不是本仓库运营的） |
| 更新检查 | 指向本仓库的 Releases，而不是上游；版本比较额外认我们自己的第四位 |
| 版本名 | 四段版本号由构建注入：Android 走 `versionName`，桌面端走 `APP_VERSION` dart-define（`pubspec.yaml` 仍是三段） |
| 包名 | Android 的 `applicationId` 改成 `com.threely.clash`（2026-10-18 起）：国内手机管家把上游那个包名标成了灰产误报，换一个不在名单里的 |
| 服务图标 | 仪表盘「服务状态」的 13 个服务图标由单色改为品牌色，图标底板固定浅色 |
| 仪表盘 | 「状态」卡片里的出口国家由两个大写字母改成国旗；国旗底下原来的四叶草去掉、只留国旗，检查出口时由旋转改为渐隐 |
| 用量进度 | 仪表盘「配置」卡片的用量进度由上游的 M3 波浪线改成直线（改 `lib/views/dashboard/widgets/profiles.dart`） |
| README | 下载徽章、下载按钮、官网链接、F-Droid 仓库、Homebrew tap、TG 频道都换成本仓库 / [@sanyeinfo](https://t.me/sanyeinfo)——上游那些入口装出来的是另一套签名的包 |
| dock 玻璃 | 主题设置里开「液态玻璃」后，dock 的观感更贴 iOS 27：tint 不再被 `contrast` 加厚（更透）、镜片折射与色散加深、顶底高光与两侧暗线更明显、选中底板由副色改成中性色（在 `lib/ui/liquid_glass.dart` 与 `lib/ui/navigation_dock.dart`，每次同步上游时留意这两处冲突） |

另外两件不在代码里的事：

- **重新签名**：上游官方 APK 在国内部分 ROM 上会被小米安全中心（腾讯引擎）判为风险应用，而这个判定跟着签名证书走。本仓库用一张中性证书重新签名——**不加固、不夹带、不绕过检测**。
- **构建**：本目录不含构建产物，全部由 GitHub Actions 构建。

### 签名变了、包名也换了，第一次要卸载

本仓库的签名与上游官方版、以及 2026-10-17 之前本仓库发的包都不同，装不上；包名又和 2026-10-18 之前本仓库发的包不同（那时沿用上游的 `com.follow.clash`），也不会覆盖安装，而是并排装成两个 App。**先卸载旧版（配置先在 App 里备份出来），再安装**。之后本仓库自己的版本之间（同一个 `com.threely.clash`）可以直接覆盖升级。

证书 SHA-256：

```
04:89:68:C1:72:8E:0E:2E:27:E7:04:D6:B3:01:74:27:65:79:BA:A2:FA:28:8F:4F:1B:A3:75:B7:02:C7:E4:31
```

## 构建流程

默认分支 `main` 上带着工作流。它只跟上游的**预览分支 `dev`**（不再跟上游的正式分支），每小时检查一次：

- 上游动了 → rebase `beta`、跑完整测试、构建 7 个平台（Android / Linux / Windows / macOS，含 arm64）、打 tag、发 beta Release、推 TG。**冲突则中止并推 TG 告警，不会静默地用上游代码盖掉我们的改动。**
- `main` 不自动更新：**稳定之后手动"晋升"**（`promote`）——把 `beta` 的代码合进 `main`，再构建并发布正式版。所以正式版发出去的代码一定先在 beta 上跑过。

macOS 产物没有 Apple 开发者证书，是**未签名**的，首次打开要在「系统设置 → 隐私与安全性」里放行。

维护细节（分支结构、版本号规则、晋升、冲突处理、需要的 Secrets）写在 [`ci` 分支的 README](../../blob/ci/README.md)。

## License

上游 FlClash 是 GPL-3.0，本仓库产物同样受 GPL-3.0 约束。
