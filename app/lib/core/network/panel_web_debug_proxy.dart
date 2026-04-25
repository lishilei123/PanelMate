import 'package:flutter/foundation.dart';

class PanelWebDebugProxy {
  const PanelWebDebugProxy._();

  static const String configuredOrigin = String.fromEnvironment(
    'PANEL_WEB_PROXY_ORIGIN',
    defaultValue: '',
  );

  static const String configuredPath = String.fromEnvironment(
    'PANEL_WEB_PROXY_PATH',
    defaultValue: '/proxy',
  );

  static bool get isEnabled => kIsWeb && configuredOrigin.trim().isNotEmpty;

  static Uri buildRequestUri(
    Uri target, {
    bool? enabled,
    String? proxyOrigin,
    String? proxyPath,
  }) {
    final shouldEnable = enabled ?? isEnabled;
    if (!shouldEnable) {
      return target;
    }

    final resolvedOrigin = (proxyOrigin ?? configuredOrigin).trim();
    if (resolvedOrigin.isEmpty) {
      return target;
    }

    final baseUri = Uri.parse(resolvedOrigin);
    final basePath = _normalizeBasePath(baseUri.path);
    final requestPath = _normalizeProxyPath(proxyPath ?? configuredPath);

    return baseUri.replace(
      path: '$basePath$requestPath',
      queryParameters: <String, String>{
        'target': target.toString(),
      },
    );
  }

  static String _normalizeBasePath(String path) {
    if (path.isEmpty || path == '/') {
      return '';
    }
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  static String _normalizeProxyPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed == '/') {
      return '/proxy';
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
