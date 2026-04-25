import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _hopByHopHeaders = <String>{
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
  'host',
  'origin',
  'content-length',
};

Future<void> main() async {
  final host = Platform.environment['PANEL_PROXY_HOST'] ?? '127.0.0.1';
  final port = int.tryParse(Platform.environment['PANEL_PROXY_PORT'] ?? '8787') ??
      8787;
  final allowBadCerts =
      (Platform.environment['PANEL_PROXY_ALLOW_BAD_CERTS'] ?? 'false')
              .toLowerCase() ==
          'true';

  final server = await HttpServer.bind(host, port);
  stdout.writeln(
    '[panel-web-proxy] Listening on http://$host:$port/proxy',
  );
  if (allowBadCerts) {
    stdout.writeln(
      '[panel-web-proxy] TLS certificate validation is disabled for upstream requests.',
    );
  }

  await for (final request in server) {
    unawaited(_handleRequest(request, allowBadCerts: allowBadCerts));
  }
}

Future<void> _handleRequest(
  HttpRequest request, {
  required bool allowBadCerts,
}) async {
  _applyCors(request);

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  final target = request.uri.queryParameters['target'];
  if (target == null || target.isEmpty) {
    await _writeJson(
      request.response,
      HttpStatus.badRequest,
      <String, Object?>{
        'code': HttpStatus.badRequest,
        'message': 'Missing target query parameter.',
      },
    );
    return;
  }

  final targetUri = Uri.tryParse(target);
  if (targetUri == null ||
      targetUri.scheme.isEmpty ||
      (targetUri.scheme != 'http' && targetUri.scheme != 'https')) {
    await _writeJson(
      request.response,
      HttpStatus.badRequest,
      <String, Object?>{
        'code': HttpStatus.badRequest,
        'message': 'Invalid target URI.',
      },
    );
    return;
  }

  stdout.writeln(
    '[panel-web-proxy] ${request.method} ${request.uri.path} -> $targetUri',
  );

  final client = HttpClient();
  if (allowBadCerts) {
    client.badCertificateCallback = (_, __, ___) => true;
  }

  try {
    final upstreamRequest = await client.openUrl(request.method, targetUri);
    _copyRequestHeaders(request.headers, upstreamRequest.headers);

    if (!_canSkipRequestBody(request.method)) {
      await upstreamRequest.addStream(request);
    }

    final upstreamResponse = await upstreamRequest.close();
    request.response.statusCode = upstreamResponse.statusCode;
    _copyResponseHeaders(upstreamResponse.headers, request.response.headers);
    _applyCors(request);

    await upstreamResponse.pipe(request.response);
  } catch (error, stackTrace) {
    stderr.writeln('[panel-web-proxy] Forward failed: $error');
    stderr.writeln(stackTrace);
    try {
      await _writeJson(
        request.response,
        HttpStatus.badGateway,
        <String, Object?>{
          'code': HttpStatus.badGateway,
          'message': error.toString(),
        },
      );
    } catch (_) {
      await request.response.close();
    }
  } finally {
    client.close(force: true);
  }
}

void _applyCors(HttpRequest request) {
  final response = request.response;
  final origin = request.headers.value('origin') ?? '*';
  final requestHeaders =
      request.headers.value('access-control-request-headers') ??
          'Accept, Content-Type, EntranceCode, 1Panel-Timestamp, 1Panel-Token';
  final requestMethod =
      request.headers.value('access-control-request-method') ??
          'GET, POST, PUT, PATCH, DELETE, OPTIONS';

  response.headers
    ..set(HttpHeaders.accessControlAllowOriginHeader, origin)
    ..set(HttpHeaders.accessControlAllowMethodsHeader, requestMethod)
    ..set(HttpHeaders.accessControlAllowHeadersHeader, requestHeaders)
    ..set(HttpHeaders.accessControlExposeHeadersHeader, '*')
    ..set(HttpHeaders.accessControlAllowCredentialsHeader, 'false')
    ..set(HttpHeaders.varyHeader, 'Origin');
}

void _copyRequestHeaders(HttpHeaders source, HttpHeaders destination) {
  source.forEach((name, values) {
    final lowerName = name.toLowerCase();
    if (_hopByHopHeaders.contains(lowerName)) {
      return;
    }
    for (final value in values) {
      destination.add(name, value);
    }
  });
}

void _copyResponseHeaders(HttpHeaders source, HttpHeaders destination) {
  source.forEach((name, values) {
    final lowerName = name.toLowerCase();
    if (_hopByHopHeaders.contains(lowerName) ||
        lowerName.startsWith('access-control-')) {
      return;
    }
    for (final value in values) {
      destination.add(name, value);
    }
  });
}

bool _canSkipRequestBody(String method) {
  return method == 'GET' ||
      method == 'HEAD' ||
      method == 'DELETE' ||
      method == 'OPTIONS';
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, Object?> payload,
) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(payload));
  await response.close();
}
