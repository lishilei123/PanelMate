import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../panel/models/panel_api_exception.dart';
import '../panel/models/server_connection_profile.dart';
import 'panel_endpoint_parser.dart';
import 'panel_http_client.dart';
import 'panel_web_debug_proxy.dart';

class PanelRestHttpClient implements PanelHttpClient {
  PanelRestHttpClient({
    required PanelServerConnectionProfile server,
    http.Client? client,
  })  : _server = server,
        _client = client ?? http.Client();

  final PanelServerConnectionProfile _server;
  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 15);

  String? _runtimeToken;

  void setRuntimeToken(String token) {
    _runtimeToken = token;
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final request =
        http.Request('GET', _buildUri(path, queryParameters: queryParameters));
    request.headers.addAll(_buildHeaders(headers: headers));
    return _send(request);
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    final request =
        http.Request('POST', _buildUri(path, queryParameters: queryParameters));
    request.headers.addAll(
      _buildHeaders(
        headers: headers,
        includeJsonContentType: true,
      ),
    );
    if (body != null) {
      request.body = jsonEncode(body);
    }
    return _send(request);
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    final request = http.Request(
      'DELETE',
      _buildUri(path, queryParameters: queryParameters),
    );
    request.headers.addAll(
      _buildHeaders(
        headers: headers,
        includeJsonContentType: body != null,
      ),
    );
    if (body != null) {
      request.body = jsonEncode(body);
    }
    return _send(request);
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
  }) {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final timestampString = timestamp.toString();
    final built = <String, String>{
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if (_resolvedToken(timestampString) case final token?)
        '1Panel-Token': token,
      '1Panel-Timestamp': timestampString,
      if (_server.entranceCode != null && _server.entranceCode!.isNotEmpty)
        'EntranceCode': _server.entranceCode!,
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

  Future<Map<String, dynamic>> _send(http.Request request) async {
    try {
      final response = await _client.send(request).timeout(_requestTimeout);
      return _decodeResponse(await http.Response.fromStream(response));
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
