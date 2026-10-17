# FlClash 自签名构建 / release

本分支（`ci`）是这个仓库的**默认分支**，只放自动化脚本，不存放应用源码。

## 为什么有它

上游 [chen08209/FlClash](https://github.com/chen08209/FlClash) 发布的 APK 用的是上游自己的数字签名，被国内部分 ROM 的风控拦截，装不上。这里做的是：**同步上游源码 → 用我们自己的 keystore 重新签名 → 发布。**

签名是上游 Gradle 原生支持的：只要 `android/app/keystore.jks` 和 `android/local.properties`（`storePassword` / `keyAlias` / `keyPassword`）存在，release 版就会用我们的证书签名，包名保持 `com.follow.clash`。不需要改动任何上游代码，所以永远不会有冲突。

## 分支结构

| 分支 | 内容 |
| --- | --- |
| `ci`（默认） | 只有这份自动化：`.github/workflows/` + 本文件 |
| `main` | 【只读镜像】`chen08209/FlClash:main`，稳定通道 |
| `dev` | 【只读镜像】`chen08209/FlClash:dev`，开发通道 |

`main` / `dev` 没有任何本地提交，每次同步都是**强制覆盖**。上游会 rebase `dev`（历史被重写），所以这里不能用 merge，只能强制同步 —— 这也正是它们不能放工作流的理由。

## 流程

```
每小时检查一次（cron '0 * * * *'）
  └─ mirror   同步 main / dev，比对上游 commit，判断哪个通道有更新
      └─ build      有更新的通道才构建，矩阵 7 个平台
          android            ubuntu-latest
          linux  amd64/arm64 ubuntu-22.04 / ubuntu-24.04-arm
          windows amd64/arm64 windows-2022 / windows-11-arm
          macos  amd64/arm64 macos-15-intel / macos-latest
          └─ release   自签名产物 + SHA256SUMS → 打 tag → GitHub Release → 推送 TG
```

- **只在有更新时才构建**，避免定时任务发一堆内容相同的 release 刷屏。
- cron 是每小时，但 **GitHub 的 `schedule` 是 best-effort、不保证准点**：实测设成 2 小时时，实际是 2h50m、3h30m 才跑一次，高负载时甚至会漏掉一班。改成每小时只是把最坏情况压到 2 小时左右 —— 这是 GitHub 侧的行为，改不掉。要准点只能走外部定时（见下）。
- android 构建后会**强制校验**包名和签名证书：一旦发现退回 debug 签名（包名带 `.dev` 后缀或证书是 `CN=Android Debug`），直接让构建失败，不发布。
- 同步时会**禁用上游自带的** `build.yaml` / `pages.yaml`。原因是推镜像用的是 PAT，会触发这两个工作流，而它们在本仓库里什么也做不了（都被 `github.repository == 'chen08209/FlClash'` 挡掉），只会刷满 Actions。
- `macos` 没有 Apple 开发者证书，产物是**未签名**的（使用前需要在「系统设置 → 隐私与安全性」里放行）。
- 单个平台构建失败**不会**阻塞其它平台的发布；全部都失败则不发布。

### Tag 命名

| 通道 | Tag | Release |
| --- | --- | --- |
| stable | `stable-<版本>-<YYMMDDHH>.<run_number>` | 标记为 Latest |
| dev | `dev-<版本>-<YYMMDDHH>.<run_number>` | 非 prerelease，但不抢占 Latest |

## 手动触发

```bash
# 只重建 dev 通道
gh workflow run ci.yaml -R aqiyoung/FlClash --ref ci -f channel=dev

# 上游没变也强制重建两个通道
gh workflow run ci.yaml -R aqiyoung/FlClash --ref ci -f force_build=true
```

## 需要的 Secrets

| Secret | 用途 | 状态 |
| --- | --- | --- |
| `KEYSTORE` | APK 签名 keystore（base64 编码的 PKCS12） | 已配置 |
| `STORE_PASSWORD` | keystore 密码 | 已配置 |
| `KEY_ALIAS` | key alias | 已配置 |
| `KEY_PASSWORD` | key 密码 | 已配置 |
| `MIRROR_TOKEN` | 推送镜像用的 PAT，需要 **`workflow`** scope | 已配置 |
| `TELEGRAM_BOT_TOKEN` | 推送用的 bot token | 未配置 |
| `TELEGRAM_CHAT_ID` | 目标会话 / 群，如 `-100xxxxxxxxxx` | 未配置 |

两个 `TELEGRAM_*` 只要有一个没配，**推送步骤会自动跳过**，其余照常发布。

### 推送长什么样

跟 `aqiyoung/datbox-android`、`aqiyoung/iptv-app-check` 里那套一样：`curl` 调 `sendMessage`，正文是几个平台的**下载直链**，直链前面挂 `https://gh-proxy.com/` 前缀（release 资产在 GitHub 上，很多人打不开）。因此：

1. **不发文件本身**。安装包动辄 60 MB+，超过云端 Bot API 的 50 MB 上传上限；发链接就没有这个问题，也不用起自建的 Bot API 服务。
2. **bot 得能往目标会话发消息**：发群要先把这个 bot 拉进群，`TELEGRAM_CHAT_ID` 用 `-100…` 那种群 id；发私聊就是你的 user id。
3. 想增减推送哪些安装包，改 `publish-release.yaml` 里那个 `for name in …` 列表。

## 关于 MIRROR_TOKEN

推镜像时如果提交里包含 `.github/workflows/` 下的文件，GitHub 会拒绝 `GITHUB_TOKEN`（它拿不到 `workflows` 权限）。上游仓库里就有这些文件，所以镜像推送必须用一个带 `workflow` scope 的 PAT。

> ⚠️ 目前填的是账号的 **classic PAT**，权限很宽（含 `delete_repo`、`admin:org` 等）。建议换成**只对这个仓库生效的 fine-grained PAT**：
> - Repository access：仅 `aqiyoung/FlClash`
> - Permissions：`Contents: Read and write`、`Workflows: Read and write`
>
> 换掉之后不需要改工作流，只要更新 `MIRROR_TOKEN` 这个 secret。

## 换签名 / 换包名

- **只换签名**（默认）：换掉 `KEYSTORE` 相关 secret 即可。
- **想同时改包名**（例如进一步脱离原 App 身份）：改 `android/app/build.gradle.kts` 的 `applicationId` —— 但那就必须改上游代码，镜像是强制覆盖的，改动会被清掉，需要额外做 patch 步骤。

## 安装注意事项

我们的证书和官方版不同，Android 不允许覆盖安装：**从官方版切过来需要先卸载一次**（同包名、不同签名）。之后我们自己的版本之间可以直接升级。

## License

上游 FlClash 是 GPL-3.0，本仓库产物同样受 GPL-3.0 约束。
