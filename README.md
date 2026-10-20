# Neon Orbit

**A cinematic point of departure for your workspace.**

为 Mac 打造的未来科技风启动动画：青蓝与紫色光轨、立体粒子球、全息遥测面板，以及最后的光圈展开转场。

![Neon Orbit preview](assets/preview.png)

## 下载与使用

**[下载 Mac 版 v2.0.0 · Apple Silicon](downloads/NeonOrbit-2.0.0-macOS-arm64.zip)**

1. 完整解压，将 `Neon Orbit.app` 放进“应用程序”或个人应用目录。
2. 先安装 Codex 或 ChatGPT 客户端。
3. 双击 **Neon Orbit**，动画结束后会打开或切回已有客户端。

全程约 **14 秒**，可点击右下角 **Skip Sequence**、按 **Esc** 或 **⌘Q** 跳过。启动器会优先寻找 Codex，其次寻找 ChatGPT；已打开的客户端会直接复用。

预编译下载适用于 **Apple Silicon / macOS 13+**。应用为本地临时签名，未做 Apple 公证，因此其他电脑首次打开时可能受到系统验证限制。也可以使用下面的源码构建方式。SHA-256 校验值见 [`downloads/SHA256SUMS`](downloads/SHA256SUMS)。

## 视觉设计

- 原创轨道与晶体标志、原创应用图标。
- 带经纬网格与粒子节点的立体能量核心。
- 青蓝 / 紫色轨道、低亮度星场、波形和拓扑连线。
- 初始化 → 同步 → 交接三个阶段，最终以光圈展开露出真实客户端。
- 本地 Canvas 绘制，适配不同屏幕比例，不加载网络字体或远程素材。

![Ready screen](assets/ready.png)

## 从源码构建

需要 macOS 13+ 和 Apple Command Line Tools。无第三方依赖。

```sh
git clone https://github.com/nwang123/neon-orbit-launcher.git
cd neon-orbit-launcher
chmod +x build.sh
./build.sh
open "build/Neon Orbit.app"
```

构建脚本针对当前 Mac 的架构生成应用，因此也可以在 Intel Mac 上构建对应版本；本次仅对 Apple Silicon 实机做了验证。

指定输出位置：

```sh
./build.sh "$HOME/Applications/Neon Orbit.app"
```

## 工作方式

原生 Swift / AppKit 窗口加载本地 WebKit Canvas。动画第 4 秒开始在后台打开客户端，约第 14.2 秒激活客户端并退出。支持单实例，异常情况下会撤下动画；不检测客户端内部页面是否已经加载完成。

不会修改官方客户端、账号、模型或登录项，不要求 API Key，不执行画面里的视觉遥测，不采集或发送数据。直接启动原客户端时不会播放动画。

[`src/animation.html`](src/animation.html) 也可直接在现代浏览器里打开观看一次动画；浏览器预览不会启动桌面客户端。

## 致谢与许可

衍生自 Artemis 制作的 [codex-startup-animation](https://github.com/yshuang722-spec/codex-startup-animation)，原项目采用 **MIT License，© 2026 Tom**。保留原版权声明和完整许可证。Mac 启动器使用 AppKit / WebKit 适配，新版动画与图标为重新绘制，未打包原项目的 OpenAI 标志素材。

这是独立的非官方社区作品，与 OpenAI 或 Apple 无隶属、赞助或认可关系。Codex、ChatGPT 等名称仅用于说明兼容性。画面中的进度、频率、节点和状态是艺术效果，不代表实际模型加载、网络或安全检查。详见 [`NOTICE.md`](NOTICE.md) 和 [`LICENSE`](LICENSE)。

## English

Neon Orbit is a standalone macOS animation launcher for an already installed Codex or ChatGPT client. It combines an original orbital identity, a wireframe particle core, cyan and violet trajectories, holographic telemetry and an iris handoff. The sequence lasts approximately 14 seconds; click Skip Sequence or press Escape to skip.

The downloadable build is for Apple Silicon on macOS 13+. It is ad-hoc signed and not Apple-notarized. Build locally with `./build.sh` if preferred. There are no third-party dependencies, API calls, remote assets, account changes or login items. All telemetry is decorative. This is an independent, unofficial project. MIT license and upstream attribution are preserved.
