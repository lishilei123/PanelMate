# PanelMate App

PanelMate 是一个纯前端 Flutter 客户端，用来接入多个 `1Panel` 面板，当前仅支持 `1Panel V2 API`。

## 当前状态

- 已支持多服务器接入，新增服务器时按 `V2 API` 进行连接测试
- 已接通真实登录、概览、告警、操作日志等主链路；账号密码登录按 1Panel V2 前端加密与 session cookie 流程处理
- 容器、网站、应用、数据库、文件、备份页面已切到真实接口数据流
- 首页与详情页会持续轮询实时数据，网速与 Top 进程展示为动态数据
- 基础配置使用普通持久化保存，凭证信息使用安全存储
- 业务数据不做本地落地，页面刷新后会重新从面板拉取

## 存储策略

- 普通持久化
  - 服务器名称
  - 面板地址
  - 端口
  - 协议
  - API 版本
  - V2 能力标记
- 安全存储
  - API Key
  - 账号
  - 密码
  - EntranceCode
  - 登录 session cookie
  - CSRF token

## 已接通的真实能力

- 登录与连接测试
  - `V2 /core/auth/setting`
  - `V2 /core/auth/captcha`
  - `V2 /core/auth/login`
  - 登录前读取 `panel_public_key`，密码使用 `RSA(AES key):IV:AES-CBC-PKCS7(password)` 格式提交
  - 面板要求验证码时弹窗显示验证码，输入后带 `captcha` / `captchaID` 继续登录；验证码错误会重新加载并重试
  - 登录成功后缓存 `psession` / `pcsrftoken`，后续请求自动携带 `Cookie` 与 `X-CSRF-Token`
- 概览
  - `V2 /dashboard/current/:ioOption/:netOption`
- 告警
  - 基于真实概览数据生成移动端告警流
- 操作日志
  - `V2 /api/v2/core/logs/operation`
- 模块页面
  - 容器
  - 网站
  - 应用
  - 数据库
  - 文件
  - 备份

## Web 调试

浏览器不能稳定直连 1Panel 的常见原因：

- 面板没有放开 `CORS`
- 面板使用了自签名证书
- 安全入口或反向代理拦截了浏览器预检请求

当前项目带有本地调试代理，推荐直接使用一键启动脚本。

### 一键启动

Windows 下推荐：

- 双击 `start-web-debug.cmd`
- 或在 `app` 目录执行：

```powershell
.\scripts\start-web-debug.ps1
```

脚本会自动完成：

- 检查 `dart` / `flutter`
- 清理旧代理进程
- 清理 `8787` 端口占用
- 启动本地代理窗口
- 启动 `flutter run -d chrome`

注意：

- UI 中仍然填写真实的 1Panel 地址
- Web 调试时请求会自动走本地代理
- 本地代理会把 `Set-Cookie` 镜像为 Web 端可读取的 `X-PanelMate-Set-Cookie`，并把 `X-PanelMate-Cookie` 转回真实 `Cookie`，用于账号密码登录的 `panel_public_key`、session cookie 与 CSRF token 流程
- 如果启动失败，先看 `1Panel Proxy` 窗口日志

### 手动启动

```powershell
dart run tool/panel_web_debug_proxy.dart
flutter run -d chrome --dart-define=PANEL_WEB_PROXY_ORIGIN=http://127.0.0.1:8787
```

## 本地开发

```powershell
flutter pub get
dart analyze
flutter test
flutter build web --dart-define=PANEL_WEB_PROXY_ORIGIN=http://127.0.0.1:8787
```

## 已知限制

- 当前是纯前端直连方案，不经过自建中转后端
- 浏览器环境下的安全存储依赖浏览器安全上下文，建议本地用 `localhost`，生产用 `HTTPS`
- `flutter_secure_storage` 在部分 WebAssembly dry run 场景会有兼容提示，但当前 `Chrome/JS` 调试与构建不受影响
- 账号密码登录已支持验证码弹窗输入；MFA 暂不处理，遇到 MFA 时会提示改用其他接入方式或后续补齐验证流程
- 没有苹果机器时，可以先在 Windows 上完成 Web 联调和 Flutter 前端开发；真正打包 iOS 时再接入 Mac 或云端 macOS CI
