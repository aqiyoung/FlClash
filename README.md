# FlClash 重建版（自签名 release）

本分支（`ci`）是这个仓库的**默认分支**，只放自动化脚本，不存放应用源码。安装包发布在本仓库的 Releases。

## 为什么有它

上游 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的官方 APK 在国内部分 ROM 上装不上：小米安全中心（腾讯引擎）把它判成风险应用。

排查出来的结论是：**这个判定跟着"签名证书"走，而不是跟着代码走**。同一份代码，换个签名，判定就变了。我们做过的对照实验：

| 实验包 | 代码 | 证书 | 结果 |
| --- | --- | --- | --- |
| `diag-resign-v0.9.0` | 同一份 | 旧：`O=FlClash, CN=FlClash` | **报毒** |
| `diag-resign-newcert` | 同一份 | 新：`O=aqiyoung` | 不报 |
| `diag-renamed` | 同一份 | 新 | 不报 |

所以我们只做一件事：**换一张中性证书重新签名**。不加固、不夹带、不绕过检测——让检测"看不见"的那种做法不属于这个项目。

代价：签名变了，Android 不允许跨签名覆盖安装。**从任何其它版本（官方版、以及本仓库在 2026-10-17 之前发的包）切过来，都要先卸载一次**；这之后，本仓库自己的版本之间可以直接覆盖升级。

包名保持 `com.follow.clash`（与官方一致）。正式版与测试版**同包名**，互相可以覆盖安装。

APK 签名证书（SHA-256）：`04:89:68:C1:72:8E:0E:2E:27:E7:04:D6:B3:01:74:27:65:79:BA:A2:FA:28:8F:4F:1B:A3:75:B7:02:C7:E4:31`

## 分支结构

| 分支 | 内容 |
| --- | --- |
| `ci`（默认） | 只有自动化：`.github/workflows/` + 本文件 |
| `stable` | 上游 `main` + 我们自己的提交 |
| `beta` | 上游 `dev` + 我们自己的提交 |

这里**不是**覆盖式镜像：`stable` / `beta` 上带着我们自己的提交，同步时用 **rebase** 把我们的提交重放到上游最新代码上。

为什么必须 rebase：上游会改写 `dev` 的历史（force-push），merge 无从谈起。rebase 的代价是遇到冲突要人处理，所以**冲突就停下**——同步任务会中止、推 TG 告警、并且**不构建**，不会静默地用上游代码盖掉我们的改动。

### 我们自己的提交

| 提交 | 说明 |
| --- | --- |
| 免责声明 | 保留全部条款文案，把"照着把声明敲一遍"改成勾选确认 |
| 测试 | 跟着改掉两条只会打字才能过的用例 |
| 更新检查（两个渠道） | 指向本仓库的 Releases，而不是上游 |

`stable` 上还多一条：0.9.0 还没有上游为遥控器写的勾选路径，所以把上游那三条文案（连同上游自己的译文）从 `dev` 回移到 0.9.0 的 l10n 里。

## 版本号

```
<上游版本>+<YYYYMMDD><当天序号>
例如：0.9.1+2026101702
```

- 前半段（`0.9.1`）取自上游 `pubspec.yaml`，**App 内的更新检查比较的就是这一段**；后半段只是给 APK 一个当天递增的 `versionCode`。
- 版本号在构建时注入，**不提交**，所以上游改版本号永远不会和我们的改动冲突。
- Tag 与版本一一对应：`v0.9.1+2026101702`。
- 同一天发第二次，序号递增（`…03`）。`+` 在链接里必须写成 `%2B`。

| 渠道 | 分支 | Release |
| --- | --- | --- |
| 正式版 | `stable` | 标记为 Latest |
| 测试版 | `beta` | prerelease，**不抢占 Latest** |

App 内更新检查读的是 `/releases/latest`（只挑正式版），所以测试版不会推给正式版用户。

## 流程

```
每小时（cron '17 * * * *'）
  └─ sync    上游 main/dev → rebase 进 stable/beta；我们的提交原样重放
      ├─ 上游没动 → 到此为止，什么都不做（不会凭空重发）
      └─ 冲突     → 中止 + 推 TG，不构建
  └─ test    该渠道跑完整 flutter 测试
  └─ build   矩阵 7 个平台
      android            ubuntu-latest
      linux  amd64/arm64 ubuntu-22.04 / ubuntu-24.04-arm
      windows amd64/arm64 windows-2022 / windows-11-arm
      macos  amd64/arm64 macos-15-intel / macos-latest
  └─ release 打 tag → GitHub Release → 推送 TG
```

- **测试不过就不发布**：发布挂在"该渠道的测试通过"这个条件上。
- 单个平台构建失败**不阻塞**其它平台的发布；该渠道整体失败则不发布。
- `macos` 没有 Apple 开发者证书，产物是**未签名**的（首次打开要在「系统设置 → 隐私与安全性」里放行）。
- GitHub 的 `schedule` 是 best-effort、不保证准点：高负载时会延后甚至漏掉一班。这是 GitHub 侧的行为，改不掉；要准点只能走外部定时。
- 推 `stable`/`beta` 会触发这两个分支上**上游自带**的工作流。`build.yaml` 已手动禁用；`pages.yaml` 有 `github.repository` 守卫，跑起来什么也不做。纯属噪音，无害。

## 手动触发

```bash
# 两个渠道都同步 + 构建 + 发布
gh workflow run ci.yaml -R aqiyoung/FlClash --ref ci

# 上游没动也强制重建
gh workflow run ci.yaml -R aqiyoung/FlClash --ref ci -f force_build=true

# 只构建验证、不发布（不会创建 Release、不会推 TG）
gh workflow run ci.yaml -R aqiyoung/FlClash --ref ci -f force_build=true -f publish=false

# 只跑一个渠道
gh workflow run ci.yaml -R aqiyoung/FlClash --ref ci -f channel=beta
```

## 需要修改代码时

不要直接往 `stable` / `beta` 上提交 —— 下次同步时它们会被 rebase，你的提交会成为"我们自己的提交"的一部分（这没问题），但**未推送**的本地提交会被丢掉。

改法：在 `stable` / `beta` 上正常提交并推送，然后让同步任务把它 rebase 到上游最新。改完先用 `publish=false` 跑一次确认测试是绿的。

## 需要的 Secrets

| Secret | 用途 | 状态 |
| --- | --- | --- |
| `KEYSTORE` | APK 签名 keystore（base64 编码的 PKCS12） | 已配置（2026-10-17 换成中性证书） |
| `STORE_PASSWORD` | keystore 密码 | 已配置 |
| `KEY_ALIAS` | key alias（`flclash`） | 已配置 |
| `KEY_PASSWORD` | key 密码 | 已配置 |
| `MIRROR_TOKEN` | 推送 `stable`/`beta` 用的 PAT，需要 **`workflow`** scope | 已配置 |
| `TELEGRAM_BOT_TOKEN` | 推送用的 bot token | 已配置 |
| `TELEGRAM_CHAT_ID` | 目标会话 / 群，如 `-100xxxxxxxxxx` | 已配置 |

两个 `TELEGRAM_*` 只要有一个没配，**推送步骤会自动跳过**，其余照常发布。

### 推送长什么样

跟 `aqiyoung/datbox-android`、`aqiyoung/iptv-app-check` 里那套一样：`curl` 调 `sendMessage`，正文是几个平台的**下载直链**，直链前面挂 `https://gh-proxy.com/` 前缀（release 资产在 GitHub 上，很多人打不开）。因此：

1. **不发文件本身**。安装包动辄 60 MB+，超过云端 Bot API 的 50 MB 上传上限；发链接就没有这个问题，也不用起自建的 Bot API 服务。
2. **bot 得能往目标会话发消息**：发群要先把这个 bot 拉进群，`TELEGRAM_CHAT_ID` 用 `-100…` 那种群 id。
3. 想增减推送哪些安装包，改 `publish-release.yaml` 里遍历 `dist/*` 的那段。

## 关于 MIRROR_TOKEN

推送分支时如果提交里包含 `.github/workflows/` 下的文件，GitHub 会拒绝 `GITHUB_TOKEN`（它拿不到 `workflows` 权限）。同步任务会把上游的提交 rebase 过来，其中就有这些文件，所以推送必须用一个带 `workflow` scope 的 PAT。

> ⚠️ 目前填的是账号的 **classic PAT**，权限很宽（含 `delete_repo`、`admin:org` 等）。建议换成**只对这个仓库生效的 fine-grained PAT**：
> - Repository access：仅 `aqiyoung/FlClash`
> - Permissions：`Contents: Read and write`、`Workflows: Read and write`
>
> 换掉之后不需要改工作流，只要更新 `MIRROR_TOKEN` 这个 secret。

## 安装注意事项

- **跨签名必须卸载**：官方版、以及 2026-10-17 之前本仓库发的包，都和我们现在的签名不同，装不上；先卸载，再安装。
- 此后本仓库自己的版本之间可以直接覆盖升级。
- 小米/红米上如果弹出"风险应用"提示：这在换证书之前是常态；如果新版仍被拦，可以在 `安全中心 → 病毒查杀 → 信任名单` 里放开，或用 `adb install -r <apk>` 兜底。

## License

上游 FlClash 是 GPL-3.0，本仓库产物同样受 GPL-3.0 约束。
