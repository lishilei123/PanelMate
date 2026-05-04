import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../panel/models/panel_api_exception.dart';
import '../panel/models/server_connection_profile.dart';
import 'panel_endpoint_parser.dart';
import 'panel_http_client.dart';
import 'panel_web_debug_proxy.dart';

typedef PanelRuntimeAuthRefresher = Future<void> Function();

class PanelRestHttpClient implements PanelHttpClient {
  PanelRestHttpClient({
    required PanelServerConnectionProfile server,
    http.Client? client,
    PanelRuntimeAuthRefresher? runtimeAuthRefresher,
  })  : _server = server,
        _client = client ?? http.Client(),
        _runtimeAuthRefresher = runtimeAuthRefresher;

  final PanelServerConnectionProfile _server;
  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _panelMateCookieHeader = 'X-PanelMate-Cookie';
  static const String _panelMateSetCookieHeader = 'x-panelmate-set-cookie';

  String? _runtimeToken;
  final Map<String, String> _cookies = <String, String>{};
  PanelRuntimeAuthRefresher? _runtimeAuthRefresher;
  Future<void>? _runtimeAuthRefreshInFlight;

  void setRuntimeToken(String? token) {
    final normalizedToken = token?.trim();
    _runtimeToken = normalizedToken == null || normalizedToken.isEmpty
        ? null
        : normalizedToken;
  }

  void setRuntimeAuthRefresher(PanelRuntimeAuthRefresher refresher) {
    _runtimeAuthRefresher = refresher;
  }

  void clearRuntimeToken() {
    _runtimeToken = null;
  }

  void setRuntimeCookies(String? cookieHeader) {
    _cookies
      ..clear()
      ..addAll(_parseCookieHeader(cookieHeader));
  }

  void clearRuntimeCredentials() {
    clearRuntimeToken();
    _cookies.clear();
  }

  void close() {
    _client.close();
  }

  String? get cookieHeader {
    if (_cookies.isEmpty) {
      return null;
    }
    return _cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  String? get csrfToken => _cookies['pcsrftoken'];

  String? cookieValue(String name) {
    return _cookies[name];
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _sendWithAuthRecovery(
      () {
        final request = http.Request(
          'GET',
          _buildUri(path, queryParameters: queryParameters),
        );
        request.headers.addAll(_buildHeaders(headers: headers));
        return request;
      },
      allowAuthRecovery: !_isAuthenticationPath(path),
    );
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    return _sendWithAuthRecovery(
      () {
        final request = http.Request(
          'POST',
          _buildUri(path, queryParameters: queryParameters),
        );
        request.headers.addAll(
          _buildHeaders(
            headers: headers,
            includeJsonContentType: true,
            includeCsrfToken: true,
          ),
        );
        if (body != null) {
          request.body = jsonEncode(body);
        }
        return request;
      },
      allowAuthRecovery: !_isAuthenticationPath(path),
    );
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    return _sendWithAuthRecovery(
      () {
        final request = http.Request(
          'DELETE',
          _buildUri(path, queryParameters: queryParameters),
        );
        request.headers.addAll(
          _buildHeaders(
            headers: headers,
            includeJsonContentType: body != null,
            includeCsrfToken: true,
          ),
        );
        if (body != null) {
          request.body = jsonEncode(body);
        }
        return request;
      },
      allowAuthRecovery: !_isAuthenticationPath(path),
    );
  }

  Uri _buildUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedHost = PanelEndpointParser.normalizeHost(
      _server.baseUrl,
      defaultScheme: _server.protocol,
    );
    final targetUri = Uri(
      scheme: _server.protocol,
      host: normalizedHost,
      port: _server.port,
      path: path,
      queryParameters: _stringifyQueryParameters(queryParameters),
    );

    return PanelWebDebugProxy.buildRequestUri(targetUri);
  }

  Map<String, String> _buildHeaders({
    Map<String, String>? headers,
    bool includeJsonContentType = false,
    bool includeCsrfToken = false,
  }) {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final timestampString = timestamp.toString();
    final runtimeCookieHeader = cookieHeader;
    final runtimeCsrfToken = csrfToken;
    final entranceCode = _encodedEntranceCode(_server.entranceCode);
    final token = _resolvedToken(timestampString);
    final built = <String, String>{
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if (token != null) '1Panel-Token': token,
      if (token != null) '1Panel-Timestamp': timestampString,
      if (entranceCode != null) 'EntranceCode': entranceCode,
      if (runtimeCookieHeader != null)
        if (PanelWebDebugProxy.isEnabled)
          _panelMateCookieHeader: runtimeCookieHeader
        else
          'Cookie': runtimeCookieHeader,
      if (includeCsrfToken && runtimeCsrfToken != null)
        'X-CSRF-Token': runtimeCsrfToken,
    };

    if (headers != null) {
      built.addAll(headers);
    }

    return built;
  }

  String? _resolvedToken(String timestamp) {
    if (_runtimeToken != null && _runtimeToken!.isNotEmpty) {
      return _runtimeToken;
    }
    if (_server.authMode == PanelAuthMode.apiKey &&
        _server.apiKey != null &&
        _server.apiKey!.isNotEmpty) {
      final raw = '1panel${_server.apiKey}$timestamp';
      return md5.convert(utf8.encode(raw)).toString();
    }
    return null;
  }

  String? _encodedEntranceCode(String? entranceCode) {
    final normalized = entranceCode?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return base64.encode(utf8.encode(normalized));
  }

  Map<String, String> _parseCookieHeader(String? rawHeader) {
    final normalized = rawHeader?.trim();
    if (normalized == null || normalized.isEmpty) {
      return const <String, String>{};
    }

    final parsed = <String, String>{};
    for (final part in normalized.split(';')) {
      final pair = part.trim();
      final separator = pair.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final name = pair.substring(0, separator).trim();
      final value = pair.substring(separator + 1).trim();
      if (name.isNotEmpty) {
        parsed[name] = value;
      }
    }
    return parsed;
  }

  void _storeSetCookieHeaders(http.Response response) {
    final rawSetCookie = response.headers['set-cookie'] ??
        response.headers[_panelMateSetCookieHeader];
    if (rawSetCookie == null || rawSetCookie.trim().isEmpty) {
      return;
    }

    for (final cookie in _splitSetCookieHeader(rawSetCookie)) {
      final firstPart = cookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator <= 0) {
        continue;
      }

      final name = firstPart.substring(0, separator).trim();
      final value = firstPart.substring(separator + 1).trim();
      final lowerCookie = cookie.toLowerCase();
      if (lowerCookie.contains('max-age=0')) {
        _cookies.remove(name);
      } else if (name.isNotEmpty) {
        _cookies[name] = value;
      }
    }
  }

  List<String> _splitSetCookieHeader(String rawHeader) {
    return rawHeader
        .split(RegExp(r',\s*(?=[^;,=\s]+=)'))
        .map((cookie) => cookie.trim())
        .where((cookie) => cookie.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final bodyText = response.body.trim();
    final payload = _tryDecodePayload(bodyText);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PanelApiException.http(
        statusCode: response.statusCode,
        message: _extractErrorMessage(payload) ??
            '请求失败，HTTP 状态码 ${response.statusCode}。',
        payload: payload,
      );
    }

    if (payload == null) {
      return const <String, dynamic>{};
    }

    if (payload is Map<String, dynamic>) {
      return _decodePayloadMap(payload);
    }

    if (payload is Map) {
      return _decodePayloadMap(payload.map(
        (key, value) => MapEntry(key.toString(), value),
      ));
    }

    if (_looksLikeHtml(bodyText)) {
      final previewLength = bodyText.length > 300 ? 300 : bodyText.length;
      throw PanelApiException(
        '面板返回了 HTML 页面而不是 JSON，请求可能被安全入口或上游代理拦截。',
        code: 'unexpected_html_response',
        payload: bodyText.substring(0, previewLength),
      );
    }

    return <String, dynamic>{'data': payload};
  }

  String? _extractErrorMessage(Object? payload) {
    if (payload is Map<String, dynamic>) {
      for (final key in ['message', 'msg', 'error', 'detail']) {
        final value = payload[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  Map<String, String>? _stringifyQueryParameters(
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return null;
    }

    return queryParameters.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  Object? _tryDecodePayload(String bodyText) {
    if (bodyText.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(bodyText);
    } on FormatException {
      return bodyText;
    }
  }

  Map<String, dynamic> _decodePayloadMap(Map<String, dynamic> payload) {
    if (!payload.containsKey('code')) {
      return payload;
    }

    final businessCode = _toInt(payload['code']);
    final message = payload['message']?.toString() ?? '';
    final data = payload['data'];

    if (businessCode == null || businessCode == 0 || businessCode == 200) {
      if (data == null) {
        return const <String, dynamic>{};
      }
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return data.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      return <String, dynamic>{'data': data};
    }

    throw PanelApiException(
      message.isNotEmpty ? message : '面板返回了业务状态码 $businessCode。',
      code: 'panel_response_error',
      statusCode: businessCode,
      payload: payload,
    );
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  bool _looksLikeHtml(String text) {
    final lower = text.toLowerCase();
    return lower.startsWith('<!doctype html') || lower.startsWith('<html');
  }

  Future<Map<String, dynamic>> _sendWithAuthRecovery(
    http.Request Function() buildRequest, {
    required bool allowAuthRecovery,
  }) async {
    try {
      return await _send(buildRequest());
    } on PanelApiException catch (error) {
      if (!_canRecoverAuthentication(error, allowAuthRecovery)) {
        rethrow;
      }

      await _refreshRuntimeAuth();
      return _send(buildRequest());
    }
  }

  bool _canRecoverAuthentication(
    PanelApiException error,
    bool allowAuthRecovery,
  ) {
    if (!allowAuthRecovery ||
        _server.authMode != PanelAuthMode.accountPassword ||
        _runtimeAuthRefresher == null) {
      return false;
    }

    if (error.statusCode == 401) {
      return true;
    }

    final message = error.message.trim();
    return error.code == 'panel_response_error' && message == 'ErrNotLogin';
  }

  Future<void> _refreshRuntimeAuth() {
    final inFlight = _runtimeAuthRefreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final refresher = _runtimeAuthRefresher;
    if (refresher == null) {
      throw const PanelApiException(
        'No account-password auth refresher was configured.',
        code: 'missing_auth_refresher',
      );
    }

    clearRuntimeCredentials();
    final refresh = refresher();
    _runtimeAuthRefreshInFlight = refresh;
    return refresh.whenComplete(() {
      _runtimeAuthRefreshInFlight = null;
    });
  }

  bool _isAuthenticationPath(String path) {
    return path.endsWith('/auth/login') ||
        path.endsWith('/auth/mfalogin') ||
        path.endsWith('/auth/setting') ||
        path.endsWith('/auth/captcha') ||
        path.endsWith('/auth/logout');
  }

  Future<Map<String, dynamic>> _send(http.Request request) async {
    try {
      final response = await _client.send(request).timeout(_requestTimeout);
      final decodedResponse = await http.Response.fromStream(response);
      _storeSetCookieHeaders(decodedResponse);
      return _decodeResponse(decodedResponse);
    } on TimeoutException {
      throw PanelApiException.timeout(
        message: '请求超时，请检查面板网络连通性后重试。',
        payload: <String, dynamic>{
          'uri': request.url.toString(),
        },
      );
    } on PanelApiException {
      rethrow;
    } catch (error) {
      throw _mapTransportError(error, request.url);
    }
  }

  PanelApiException _mapTransportError(Object error, Uri uri) {
    final raw = error.toString();
    final lower = raw.toLowerCase();
    final payload = <String, dynamic>{
      'uri': uri.toString(),
      'error': raw,
    };

    if (lower.contains('failed to fetch') ||
        lower.contains('xmlhttprequest error')) {
      return PanelApiException.network(
        message: '无法连接到面板。当前请求可能被浏览器拦截，请检查 CORS、HTTPS 证书、地址和端口。',
        code: 'network_fetch_failed',
        payload: payload,
      );
    }

    if (lower.contains('connection refused')) {
      return PanelApiException.network(
        message: '连接被拒绝，请确认面板地址、端口和服务是否已启动。',
        code: 'connection_refused',
        payload: payload,
      );
    }

    if (lower.contains('handshake') || lower.contains('certificate')) {
      return PanelApiException.network(
        message: 'HTTPS 证书校验失败，请检查证书配置或改用受信任证书。',
        code: 'tls_error',
        payload: payload,
      );
    }

    if (lower.contains('failed host lookup') ||
        lower.contains('name or service not known') ||
        lower.contains('dns')) {
      return PanelApiException.network(
        message: '域名解析失败，请检查面板地址是否填写正确。',
        code: 'dns_error',
        payload: payload,
      );
    }

    return PanelApiException.network(
      message: '网络请求失败，请检查面板地址、端口和网络连通性。',
      payload: payload,
    );
  }
}
