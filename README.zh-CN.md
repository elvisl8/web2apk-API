# web2apk

[English](README.md) | [中文](README.zh-CN.md)

<img src="docs/icon.png" alt="" width="96" align="right">

把网站打包成可安装的 Android 应用。web2apk 是一个 Flutter 应用，在你自己的设备上构建 APK（Android、iOS、Linux、Windows、macOS 或浏览器里），使用它不需要 Android 工具链、Flutter 或 Gradle。生成的应用就是一个普通的 Android WebView（JavaScript 开启，链接留在应用内打开，返回键先回退页面历史）。界面支持中英双语，应用栏一键切换。

<!-- 截图占位：docs/screenshot.png -->

## 下载

**网页版：** 在浏览器打开 [https://elvisl8.github.io/web2apk-API/](https://elvisl8.github.io/web2apk-API/)（最新开发版：[https://elvisl8.github.io/web2apk-API/dev/](https://elvisl8.github.io/web2apk-API/dev/)）。

**应用：** 在 [Releases](https://github.com/elvisl8/web2apk-API/releases) 页面下载（`N` 是构建号）：

- `web2apk-dev-N-android.apk` - Android 7.0+
- `web2apk-dev-N-linux-x64.tar.gz` - Linux（解压后运行 `web2apk`；文件选择器需要 `zenity`）
- `web2apk-dev-N-windows-x64.zip` - Windows（解压后运行 `web2apk.exe`）
- `web2apk-dev-N-macos.zip` - macOS（未签名：首次打开请右键 -> 打开）
- `web2apk-dev-N-ios-unsigned.ipa` - iOS 15+ 侧载用（AltStore、Sideloadly……）；不在 App Store 上架。iPhone 装不了 APK，用“保存”或“分享”把它传到 Android 设备上
- `web2apk-dev-N-web.zip` - 网页版，自己部署用
- `SHA256SUMS.txt` - 上述文件的校验和

## 使用方法

填好表单，点 **生成**：

- **应用名称** — 主屏幕标签和标题栏文字
- **网址** — 要展示的网站（不写 `https://` 会自动补）
- **颜色** — 标题栏颜色
- **图标** — 从相册/文件里选一张图（居中裁成正方形）；不选就用 web2apk 的地球图标
- **全屏** — 只隐藏标题栏，Android 状态栏仍可见
- **高级设置** — 屏幕方向、网站深色模式（Android 13+）、隐藏状态栏和导航栏、保持屏幕常亮、加载时显示应用颜色、在浏览器中打开其他网站、加载进度条、离线页面（带重试）、刷新按钮、双指缩放、桌面模式、自定义 User Agent、应用版本
- **预览** — 应用界面和主屏幕图标的实时示意（宽屏时在表单旁边）
- **包名** — 显示为“包名：……——点按修改”。按域名生成（`https://example.org` -> `org.example.web2apk`）。每个应用都要有自己的 ID：两个应用包名相同会互相替换，从同一域名做多个应用时请改包名。
- **语言** — 应用栏一键切换中文/英文，默认跟随系统语言，选择会被记住

APK 生成后：

- **安装**（Android）打开系统安装器
- **保存** 把 APK 存到你选的位置（浏览器里就是下载）
- **分享**（Android、iOS、macOS）把 APK 发给其他应用

用同一个包名重新生成，安装时就是原地更新。

### 我的应用

每个生成的应用都会记在 **我的应用** 里（应用栏的网格图标），包括设置和一份小图标。点一个就能载回表单，改完再点 **生成**：包名不变，新 APK 就是一次更新。删除条目只会从列表里移除。

### 备份签名密钥

点生成器应用栏的钥匙图标，可以看到签名密钥的 SHA-256 指纹，用 **备份密钥** 保存（得到一个 `web2apk-signing-key.json` 文件），或用 **恢复密钥** 载入已保存的文件。拿到这个文件的人就能发布你应用的更新，请妥善保管。恢复会替换当前密钥；用旧密钥签名的应用之后无法再原地更新，除非你重新恢复旧密钥。网页版的密钥存在浏览器里，清除网站数据前请先备份。

### 网页版注意事项

- 网页版密钥按浏览器**和**域名分别保存。`elvisl8.github.io` 是和其他 GitHub Pages 应用共用的域名，清除该网站的数据，或同一域名下的其他应用清除存储，都会删掉密钥。请备份。
- 首次访问只开一个标签页，免得两个标签页各生成一个密钥。
- 自己部署网页版需要 HTTPS（WebCrypto 要求安全上下文）。

### 签名密钥须知

生成器首次使用会生成签名密钥，存在本机（shared preferences；网页版存在浏览器存储里）。卸载生成器或清除其数据会**丢失密钥**，除非 Android 自动备份在重装或换手机时把它恢复回来（已开启，但别依赖它）：请用 **签名密钥** 备份。之后重新生成的应用会用新密钥签名，旧版应用必须先卸载才能装新版。

## 从源码构建

要求：Flutter 3.47.5、JDK 17-21（更新的 JDK 与 Android Gradle 插件不兼容）、Android SDK（设置好 `ANDROID_HOME`）。

```bash
scripts/build_template.sh   # 把模板 APK 构建到 assets/template.apk（git 忽略）
flutter pub get
flutter test
flutter run                 # 或：flutter build apk / ios / linux / windows / macos / web
```

构建模板需要 JDK 21（`JAVA_HOME=/usr/lib/jvm/java-21-openjdk scripts/build_template.sh`）；更新的 JDK 会在 Android 构建工具里失败。

验证生成 APK 的测试要用 `$ANDROID_HOME` 下最新 build-tools 里的 `apksigner`、`aapt2` 和 `zipalign`；`flutter test --platform chrome` 跑浏览器兼容的测试。图标由 `tool/make_icons.py`（Pillow）绘制；改图标后要重跑它和 `scripts/build_template.sh`。

## 维护者：发布与 CI

每次推送到 `master` 都会跑 `.github/workflows/dev-release.yml`：测试、构建 Android、iOS、Linux、Windows、macOS 和网页版，并发布一个带全部文件和 `SHA256SUMS.txt` 的预发布 `dev-N`。最新开发版的网页应用部署在 https://elvisl8.github.io/web2apk-API/dev/。

Android versionCode 来自工作流运行号。不要重命名或重建 `dev-release.yml`：计数器会重启，新构建会被当成降级。

要发正式版，跑 **Actions -> Release -> Run workflow**（`.github/workflows/release.yml`），版本号填如 `2.1.0`。它会把最新 `dev-N` 构建（或你指定的那一个）的文件原样复制进 `v2.1.0` 发布，所以发出去的就是 CI 测过的二进制，同时把网页应用重新发布到 https://elvisl8.github.io/web2apk-API/。先改 `pubspec.yaml` 里的 `version:`，让应用报告同样的版本。请发布最新的开发版：`github.token` 无法给工作流文件与 master 不同的旧提交打标签。一次性设置：Settings -> Pages -> Source：**GitHub Actions**。

Android APK 用你自己的密钥签名，通过仓库 secrets 提供。没有这些 secrets 时 CI 用调试密钥签名（发布说明里会写），用户装正式签名版之前必须先卸载调试签名版。用 JDK 17-21 创建 keystore：

```bash
keytool -genkeypair -v -keystore release.jks -keyalg RSA -keysize 4096 -validity 36500 -alias web2apk
base64 -w0 release.jks   # -> secret ANDROID_KEYSTORE_BASE64
```

还要设置 `ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`（上面是 `web2apk`）和 `ANDROID_KEY_PASSWORD` 这几个 secrets。

**备份好 `release.jks`。** 丢了它，用户更新生成器之前必须先卸载。

本地做发布构建时，在 `android/key.properties`（git 忽略）里写 `storeFile`（相对 `android/app` 的路径）、`storePassword`、`keyAlias`、`keyPassword`，四项都要有。没有这个文件，发布构建会回退到调试密钥。macOS 应用未签名：首次打开请右键 -> 打开。iOS `.ipa` 也是未签名的（`--no-codesign`）；侧载工具会用用户自己的 Apple ID 签名。

## 致谢与 v1

Made by devilAPI with <3 - https://github.com/devilAPI/web2apk

最初的 v1（在 `main.dart` 里改三个变量，用 Gradle 构建）在 `legacy` 分支上。
