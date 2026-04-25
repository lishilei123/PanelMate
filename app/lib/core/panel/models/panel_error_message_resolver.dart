import 'panel_api_exception.dart';

class PanelErrorMessageResolver {
  const PanelErrorMessageResolver._();

  static String resolve(Object error) {
    if (error is PanelApiException) {
      return _resolvePanelApiException(error);
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

  static String _resolvePanelApiException(PanelApiException error) {
    switch (error.code) {
      case 'missing_entrance_code':
        return '当前面板登录需要 EntranceCode，请先填写后再测试。';
      case 'missing_login_token':
        return '登录成功，但面板没有返回 Token，无法继续请求。';
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
        return _resolvePanelResponseError(error);
      case 'http_error':
        return _resolveHttpError(error);
      default:
        return error.message;
    }
  }

  static String _resolvePanelResponseError(PanelApiException error) {
    final message = error.message.trim();

    if (message.contains('时间戳')) {
      return 'API Key 鉴权失败：1Panel 需要秒级时间戳，并要求把 1Panel-Token 计算为 md5("1panel" + API Key + 时间戳)。';
    }

    if (message.contains('密钥') || message.toLowerCase().contains('key')) {
      return 'API Key 无效，请检查接口密钥是否正确。';
    }

    if (message.contains('IP') || message.contains('ip')) {
      return '当前客户端 IP 不在面板接口白名单内，请先在 1Panel 后台放行。';
    }

    if (message.contains('未开启') || message.contains('disabled')) {
      return '面板接口未启用，请先在 1Panel 后台开启 API 接口。';
    }

    if (message.isNotEmpty) {
      return message;
    }

    return '面板返回了业务错误，请检查接口密钥、白名单和 API 设置。';
  }

  static String _resolveHttpError(PanelApiException error) {
    final detail = error.message.trim();
    final statusCode = error.statusCode;

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
