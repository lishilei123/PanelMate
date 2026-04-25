<p align="center">
  <img src="app/assets/app_icon.png" width="112" alt="PanelMate logo">
</p>

<h1 align="center">PanelMate</h1>

<p align="center">
  面向 <code>1Panel V2 API</code> 的清新毛玻璃风格移动端管理伴侣。
</p>

<p align="center">
  <strong>多服务器巡检</strong> · <strong>实时资源概览</strong> · <strong>模块化运维入口</strong> · <strong>Flutter 纯前端</strong>
</p>

---

## 项目简介

PanelMate 是一个基于 Flutter 的 1Panel 移动端客户端，目标是在手机或 Web 端快速接入多台 1Panel 服务器，完成高频巡检、资源查看、模块入口访问和轻量运维操作。

项目当前仅面向 `1Panel V2 API`，不再兼容 V1。整体信息架构采用 `概览 / AI / 我的` 三个底部导航入口，视觉上使用浅色渐变、毛玻璃卡片和可自定义主题。

## 功能特性

- 多服务器接入与本地管理
- 账号密码 / API Key 登录方式
- EntranceCode 支持
- 添加服务器前执行 V2 API 连接测试
- 概览页支持服务器搜索与 `全部 / 在线 / 离线` 筛选
- 实时展示 CPU、内存、磁盘、负载、上下行速率等数据
- 服务器详情页展示资源状态、最近操作和 V2 能力摘要
- 容器、网站、应用、数据库、文件、备份模块入口
- AI 工作台入口，用于承载后续智能巡检、日志问答和变更建议
- 前台自动轮询设置，支持 `15s / 30s / 60s / 关闭`
- 内置渐变主题与自定义调色板
- 凭证使用安全存储，业务实时数据不落地

## 技术栈

- Flutter / Dart
- Material 3
- `http`
- `shared_preferences`
- `flutter_secure_storage`
- 1Panel V2 REST API

## 目录结构

```text
PanelMate/
  app/      Flutter 应用源码
  docs/     PRD、页面说明、API 兼容记录
  V2_api.json
  logo.png
```

核心 Flutter 目录：

```text
app/lib/
  app/          应用入口、主题、全局背景
  core/         1Panel API、网络、存储、运行时服务
  features/    概览、服务器、模块、AI、设置等页面
  shared/      通用组件、格式化工具、演示数据
```

## 快速开始

进入 Flutter 应用目录：

```powershell
cd app
flutter pub get
```

运行 Web 调试：

```powershell
flutter run -d chrome
```

Windows 下如果需要绕过浏览器 CORS、自签名证书或安全入口预检问题，推荐使用内置调试代理：

```powershell
.\start-web-debug.cmd
```

或手动启动：

```powershell
dart run tool/panel_web_debug_proxy.dart
flutter run -d chrome --dart-define=PANEL_WEB_PROXY_ORIGIN=http://127.0.0.1:8787
```

## 常用命令

```powershell
cd app
dart analyze
flutter test
flutter build web
```

如果 Windows 环境未启用开发者模式，Flutter 插件符号链接可能导致 `flutter pub get` 报错。建议启用 Windows Developer Mode 后再获取依赖。

## 文档

- [产品需求文档](docs/panelmate-prd.md)
- [iOS 页面说明](docs/panelmate-ios-pages.md)
- [开发计划](docs/panelmate-development-plan.md)
- [真实 API 联调说明](docs/panelmate-real-api-notes.md)

## 当前状态

项目处于早期开发阶段，核心多服务器接入、概览、详情、模块列表和主题设置已实现。后续重点包括：

- 增补更多模块级操作
- 完善服务器连接配置编辑体验
- 补充主题调色板与设置页组件测试
- 接入真实 AI 能力模块
- 根据真实 1Panel V2 返回持续修正字段映射

## 已知限制

- 当前是纯前端直连方案，不经过自建中转后端。
- Web 环境依赖目标面板开放 CORS；否则需要使用本地调试代理。
- 自签名证书可能影响浏览器联调。
- iOS 正式打包需要 macOS / Xcode 环境。
- `flutter_secure_storage` 在部分 WebAssembly dry run 场景会提示兼容问题，但不影响当前 Chrome/JS 构建运行。

## License

当前仓库暂未声明开源许可证。
