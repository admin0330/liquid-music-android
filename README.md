# Real Liquid Glass Android Demo

一个专门用于 Android 实机测试 [`real_liquid_glass`](https://pub.dev/packages/real_liquid_glass) 的 Flutter 应用。

## 功能

- 展示 `LiquidGlassContainer`、胶囊容器和 `LiquidGlassBottomBar`。
- Apple Music 风格的柔白模糊背景、浅色玻璃和红色交互强调。
- 实时调节 Android fallback 的 `fallbackIntensity`。
- 从本仓库的 GitHub Releases 检查新版 APK。
- 在应用内下载更新并唤起 Android 系统安装器。
- Release APK 使用固定密钥签名，支持覆盖升级。

> Android 无法显示 Apple 的原生 `UIGlassEffect`。本应用测试的是该包在 Android 上由 Flutter 绘制的毛玻璃降级效果。

## 测试应用内更新

1. 从 Releases 安装 `v1.0.0` 的 APK。
2. 打开首页，点击“检查 GitHub 更新”。
3. 首次使用时，按照系统提示允许本应用“安装未知应用”。
4. 返回应用，再次点击更新；下载完成后系统安装器会自动打开。
5. 安装 `v1.0.1`，应用数据会保留。

## 本地构建

```bash
flutter pub get
flutter test
flutter build apk --release
```

没有 `android/key.properties` 时，本地 Release 会临时使用 debug 签名。正式发布由 GitHub Actions 从仓库 Secrets 恢复固定的 Release 密钥。

## 发布

推送 `v*` 标签会触发 [release.yml](.github/workflows/release.yml)，构建签名 APK 并创建对应的 GitHub Release。

测试项目使用 MIT 许可证；`real_liquid_glass` 本身也采用 MIT 许可证。
