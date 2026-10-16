# FlClash 自签名构建 / release

本分支（`ci`）是这个仓库的**默认分支**，只放自动化脚本，不存放应用源码。

## 为什么有它

上游 [chen08209/FlClash](https://github.com/chen08209/FlClash) 发布的 APK 用的是上游自己的数字签名，被国内部分 ROM 的风控拦截，装不上。这里做的是：**同步上游源码 → 用我们自己的 keystore 重新签名 → 发布。**

签名是上游 Gradle 原生支持的：只要 `android/app/keystore.jks` 和 `android/local.properties`（`storePassword` / `keyAlias` / `keyPassword`）存在，release 版就会用我们的证书签名，包名保持 `com.follow.clash`。不需要改动任何上游代码，所以永远不会有冲突。

## 分支结构

| 分支 | 内容 |
| --- | --- |
| `ci`（默认） | 只有这份自动化：`.github/workflows/`、`.ci/telegram.py` |
| `main` | 【只读镜像】`chen08209/FlClash:main`，稳定通道 |
| `dev` | 【只读镜像】`chen08209/FlClash:dev`，开发通道 |

`main` / `dev` 没有任何本地提交，每次同步都是**强制覆盖**。上游会 rebase `dev`（历史被重写），所以这里不能用 merge，只能强制同步 —— 这也正是它们不能放工作流的理由。

## 流程

```
每 2 小时（cron '0 */2 * * *'）
  └─ mirror   同步 main / dev，比对上游 commit，判断哪个通道有更新
      └─ build      有更新的通道才构建，矩阵 7 个平台
          android            ubuntu-latest
          linux  amd64/arm64 ubuntu-22.04 / ubuntu-24.04-arm
          windows amd64/arm64 windows-2022 / windows-11-arm
          macos  amd64/arm64 macos-15-intel / macos-latest
          └─ release   自签名产物 + SHA256SUMS → 打 tag → GitHub Release → 推送 TG
```

- **只在有更新时才构建**，避免每 2 小时发一个内容相同的 release 刷屏。
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
| `TELEGRAM_BOT_TOKEN` | 推送频道用的 bot | 未配置 |
| `TELEGRAM_CHAT_ID` | 目标频道，如 `@yourchannel` 或 `-100xxxxxxxxxx` | 未配置 |
| `TELEGRAM_API_ID` | <https://my.telegram.org> 申请的 API ID | 未配置 |
| `TELEGRAM_API_HASH` | 同上，API hash | 未配置 |

四个 `TELEGRAM_*` 只要有一个没配，**推送步骤会自动跳过**，其余照常发布。配置要求：

1. bot 需要是目标频道的**管理员**；
2. `TELEGRAM_API_ID` / `TELEGRAM_API_HASH` 必填，因为安装包超过 Telegram 云端 Bot API 的 50 MB 上传上限，构建里会起一个自建的 `aiogram/telegram-bot-api` 容器把文件发出去；
3. 想发哪些平台的安装包，改 `.ci/telegram.py` 里的 `KEYWORDS`。

## 换签名 / 换包名

- **只换签名**（默认）：换掉 `KEYSTORE` 相关 secret 即可。
- **想同时改包名**（例如进一步脱离原 App 身份）：改 `android/app/build.gradle.kts` 的 `applicationId` —— 但那就必须改上游代码，镜像是强制覆盖的，改动会被清掉，需要额外做 patch 步骤。

## 安装注意事项

我们的证书和官方版不同，Android 不允许覆盖安装：**从官方版切过来需要先卸载一次**（同包名、不同签名）。之后我们自己的版本之间可以直接升级。

## License

上游 FlClash 是 GPL-3.0，本仓库产物同样受 GPL-3.0 约束。
