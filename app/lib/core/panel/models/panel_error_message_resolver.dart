import 'panel_api_exception.dart';
import 'server_connection_profile.dart';

class PanelErrorMessageResolver {
  const PanelErrorMessageResolver._();

  static String resolve(Object error, {PanelAuthMode? authMode}) {
    if (error is PanelApiException) {
      return _resolvePanelApiException(error, authMode: authMode);
    }

    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (_looksLikeFetchFailure(lower)) {
      return '浏览器无法直接连接到面板。请检查地址、端口、CORS 配置以及 HTTPS 证书；如在 Web 调试，请启用本地开发代理。';
    }

    if (lower.contains('formatexception')) {
      return '地址格式无效，请检查协议、域名和端口。';
    }

    return '请求失败，请检查面板地址、网络连通性和登录凭证。';
  }

  static String _resolvePanelApiException(
    PanelApiException error, {
    PanelAuthMode? authMode,
  }) {
    switch (error.code) {
      case 'missing_entrance_code':
        return '当前面板登录需要 EntranceCode，请先填写后再测试。';
      case 'missing_login_token':
        return '登录成功，但面板没有返回 Token，无法继续请求。';
      case 'missing_account_password_credentials':
        return '账号密码登录需要填写用户名和密码。';
      case 'missing_panel_public_key':
        return _loginCookieMessage(
          '登录设置接口没有返回 panel_public_key Cookie',
        );
      case 'missing_login_session':
        return _loginCookieMessage(
          '登录成功但没有返回 session Cookie 或 Token',
        );
      case 'captcha_required':
        return '当前面板要求验证码校验，请在弹窗中输入验证码后继续登录。';
      case 'captcha_load_failed':
        return '验证码加载失败：面板没有返回 captchaID 或验证码图片。请重新测试，或检查 /api/v2/core/auth/captcha 是否正常。';
      case 'captcha_cancelled':
        return '已取消验证码输入，登录测试未继续。';
      case 'mfa_required':
        return '当前账号开启了 MFA，账号密码自动登录暂不支持二次验证码，请改用 API Key 接入。';
      case 'unmapped_feature':
        return error.message;
      case 'request_timeout':
      case 'network_error':
      case 'network_fetch_failed':
      case 'tls_error':
      case 'dns_error':
      case 'connection_refused':
        return error.message;
      case 'unexpected_html_response':
        return '面板返回了 HTML 页面而不是 API JSON。通常是安全入口拦截、反向代理改写，或当前面板未按 V2 API 正常暴露接口。';
      case 'panel_response_error':
        return _resolvePanelResponseError(error, authMode: authMode);
      case 'http_error':
        return _resolveHttpError(error, authMode: authMode);
      default:
        return error.message;
    }
  }

  static String _resolvePanelResponseError(
    PanelApiException error, {
    PanelAuthMode? authMode,
  }) {
    final message = error.message.trim();
    final lower = message.toLowerCase();

    if (_looksLikeLoginCookieIssue(message, lower)) {
      return _loginCookieMessage(message);
    }

    switch (message) {
      case 'ErrCaptchaCode':
        return '验证码不正确或已过期，请重新执行连接测试并输入新的验证码。';
      case 'ErrAuth':
        return '账号或密码不正确，或当前 1Panel 要求加密登录参数。请检查登录凭证；移动端建议优先使用 API Key 接入。';
      case 'ErrEntrance':
        return '安全入口不正确，请检查 EntranceCode 是否与 1Panel 登录入口一致。';
      case 'ErrLoginLocked':
        return '失败次数过多，1Panel 已临时锁定登录，请等待 5 分钟后再试。';
      case 'ErrMFA':
        return '当前账号开启了 MFA，账号密码自动同步暂不支持二次验证码，请改用 API Key 接入。';
      case 'ErrNotLogin':
        return '登录状态已失效，请重新同步；如果使用账号密码接入，建议改用 API Key。';
    }

    if (message.contains('时间戳')) {
      return 'API Key 鉴权失败：1Panel 需要秒级时间戳，并要求把 1Panel-Token 计算为 md5("1panel" + API Key + 时间戳)。';
    }

    if (message.contains('密钥') || lower.contains('key')) {
      if (authMode == PanelAuthMode.accountPassword) {
        return _loginCookieMessage(
          '账号密码模式下接口返回密钥鉴权错误：$message',
        );
      }
      return 'API Key 无效，请检查接口密钥是否正确。';
    }

    if (message.contains('IP') || message.contains('ip')) {
      return '当前客户端 IP 不在面板接口白名单内，请先在 1Panel 后台放行。';
    }

    if (message.contains('未开启') || lower.contains('disabled')) {
      return '面板接口未启用，请先在 1Panel 后台开启 API 接口。';
    }

    if (message.isNotEmpty) {
      return message;
    }

    return '面板返回了业务错误，请检查接口密钥、白名单和 API 设置。';
  }

  static bool _looksLikeLoginCookieIssue(String message, String lower) {
    return message.contains('panel_public_key') ||
        message.contains('公钥') ||
        message.contains('登录 Cookie') ||
        lower.contains('public_key') ||
        lower.contains('public key') ||
        lower.contains('set-cookie') ||
        lower.contains('cookie');
  }

  static String _loginCookieMessage(String detail) {
    return '账号密码登录 Cookie 异常：$detail。请确认已使用本地 Web 调试代理并重启代理；如果不是 Web 调试，请检查 /api/v2/core/auth/setting 和 /api/v2/core/auth/login 是否返回 Set-Cookie。';
  }

  static String _resolveHttpError(
    PanelApiException error, {
    PanelAuthMode? authMode,
  }) {
    final detail = error.message.trim();
    final statusCode = error.statusCode;
    final lower = detail.toLowerCase();

    if (_looksLikeLoginCookieIssue(detail, lower)) {
      return _loginCookieMessage(detail);
    }

    if (statusCode == 401 && authMode == PanelAuthMode.accountPassword) {
      return _loginCookieMessage(
        detail.isEmpty ? '登录后的 session 未被面板接受' : detail,
      );
    }

    final base = switch (statusCode) {
      400 => '请求参数不正确，请检查地址、端口、登录参数和 EntranceCode。',
      401 => '认证失败，请检查账号密码、API Key 或登录状态。',
      403 => '请求被拒绝，请检查权限、面板安全入口或鉴权配置。',
      404 => '接口不存在。请确认当前面板提供的是 1Panel V2 API，并且该接口已启用。',
      408 => '请求超时，请稍后重试。',
      422 => '请求格式不符合面板要求，请检查必填字段。',
      _ when statusCode != null && statusCode >= 500 => '面板服务异常，请稍后重试。',
      _ => detail.isNotEmpty ? detail : '请求失败，请检查面板配置。',
    };

    if (detail.isEmpty || detail == base) {
      return base;
    }

    return '$base\n服务器返回：$detail';
  }

  static bool _looksLikeFetchFailure(String lower) {
    return lower.contains('failed to fetch') ||
        lower.contains('xmlhttprequest error');
  }
}
