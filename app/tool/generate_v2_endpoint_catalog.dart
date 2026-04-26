import 'dart:convert';
import 'dart:io';

const _httpMethods = <String>{'get', 'post', 'put', 'patch', 'delete'};

void main() {
  final appDir = _resolveAppDirectory();
  final source = _resolveSourceFile(appDir);
  final output = File(
    '${appDir.path}/lib/core/panel/v2/v2_endpoint_catalog.dart',
  );

  final api = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
  final basePath = api['basePath']?.toString() ?? '/api/v2';
  final paths = api['paths'] as Map<String, dynamic>;
  final usedOperationIds = <String>{};
  final entries = <_EndpointSpec>[];

  for (final pathEntry in paths.entries) {
    final path = pathEntry.key;
    final pathSpec = pathEntry.value as Map<String, dynamic>;
    for (final method in _httpMethods) {
      final operation = pathSpec[method];
      if (operation is! Map<String, dynamic>) {
        continue;
      }

      final operationId = _uniqueOperationId(
        method: method,
        path: path,
        used: usedOperationIds,
      );
      final parameters =
          (operation['parameters'] as List?) ?? const <Object?>[];
      final pathParameters = _pathParameters(path, parameters);
      final queryParameters = _queryParameters(parameters);
      final requestBodyRef = _requestBodyRef(parameters);
      final responseBodyRef = _responseBodyRef(operation['responses']);
      final tags = ((operation['tags'] as List?) ?? const <Object?>[])
          .map((tag) => tag.toString())
          .toList(growable: false);

      entries.add(
        _EndpointSpec(
          operationId: operationId,
          method: method.toUpperCase(),
          path: _fullPath(basePath: basePath, path: path),
          summary: operation['summary']?.toString() ?? '',
          tags: tags,
          pathParameters: pathParameters,
          queryParameters: queryParameters,
          requestBodyRef: requestBodyRef,
          responseBodyRef: responseBodyRef,
        ),
      );
    }
  }

  output.writeAsStringSync(_renderCatalog(entries));
}

Directory _resolveAppDirectory() {
  final current = Directory.current;
  if (File('${current.path}/pubspec.yaml').existsSync() &&
      Directory('${current.path}/lib').existsSync()) {
    return current;
  }

  final nestedApp = Directory('${current.path}/app');
  if (File('${nestedApp.path}/pubspec.yaml').existsSync()) {
    return nestedApp;
  }

  throw StateError('Run this generator from the repo root or app directory.');
}

File _resolveSourceFile(Directory appDir) {
  final candidates = <File>[
    File('${appDir.path}/../V2_api.json'),
    File('${Directory.current.path}/V2_api.json'),
  ];

  for (final candidate in candidates) {
    if (candidate.existsSync()) {
      return candidate;
    }
  }

  throw StateError('Unable to find V2_api.json.');
}

String _renderCatalog(List<_EndpointSpec> entries) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln(
        '// Generated from V2_api.json by tool/generate_v2_endpoint_catalog.dart.')
    ..writeln()
    ..writeln("import '../contracts/panel_generic_api.dart';")
    ..writeln()
    ..writeln('class V2EndpointCatalog {')
    ..writeln('  const V2EndpointCatalog._();')
    ..writeln()
    ..writeln(
        '  static const List<PanelApiEndpoint> endpoints = <PanelApiEndpoint>[');

  for (final entry in entries) {
    buffer
      ..writeln('    PanelApiEndpoint(')
      ..writeln('      operationId: ${_dartString(entry.operationId)},')
      ..writeln('      method: ${_dartString(entry.method)},')
      ..writeln('      path: ${_dartString(entry.path)},')
      ..writeln('      summary: ${_dartString(entry.summary)},')
      ..writeln('      tags: ${_stringListLiteral(entry.tags)},')
      ..writeln(
        '      pathParameters: ${_stringListLiteral(entry.pathParameters)},',
      )
      ..writeln(
        '      queryParameters: ${_stringListLiteral(entry.queryParameters)},',
      )
      ..writeln(
        '      requestBodyRef: ${_nullableStringLiteral(entry.requestBodyRef)},',
      )
      ..writeln(
        '      responseBodyRef: ${_nullableStringLiteral(entry.responseBodyRef)},',
      )
      ..writeln('    ),');
  }

  buffer
    ..writeln('  ];')
    ..writeln('}');

  return buffer.toString();
}

String _fullPath({
  required String basePath,
  required String path,
}) {
  if (path == basePath || path.startsWith('$basePath/')) {
    return path;
  }
  return '$basePath$path';
}

String _uniqueOperationId({
  required String method,
  required String path,
  required Set<String> used,
}) {
  final base = _operationId(method: method, path: path);
  var candidate = base;
  var suffix = 2;
  while (!used.add(candidate)) {
    candidate = '$base$suffix';
    suffix += 1;
  }
  return candidate;
}

String _operationId({
  required String method,
  required String path,
}) {
  final segments = path
      .split('/')
      .where((segment) => segment.trim().isNotEmpty)
      .map((segment) {
    final parameter = _parameterName(segment);
    if (parameter != null) {
      return 'By${_pascal(parameter)}';
    }
    return _pascal(segment);
  }).join();

  return method.toLowerCase() + segments;
}

String _pascal(String value) {
  final words = value
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  return words
      .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
      .join();
}

String? _parameterName(String segment) {
  if (segment.startsWith(':')) {
    return segment.substring(1);
  }
  if (segment.startsWith('{') && segment.endsWith('}')) {
    return segment.substring(1, segment.length - 1);
  }
  return null;
}

List<String> _pathParameters(String path, List<Object?> parameters) {
  final values = <String>[];

  void add(String value) {
    if (!values.contains(value)) {
      values.add(value);
    }
  }

  for (final match in RegExp(r'/:([A-Za-z_][A-Za-z0-9_]*)').allMatches(path)) {
    add(match.group(1)!);
  }
  for (final match in RegExp(r'\{([^}/]+)\}').allMatches(path)) {
    add(match.group(1)!);
  }
  for (final parameter in parameters.whereType<Map>()) {
    if (parameter['in'] == 'path') {
      add(parameter['name'].toString());
    }
  }

  return values;
}

List<String> _queryParameters(List<Object?> parameters) {
  return parameters
      .whereType<Map>()
      .where((parameter) => parameter['in'] == 'query')
      .map((parameter) => parameter['name'].toString())
      .toList(growable: false);
}

String? _requestBodyRef(List<Object?> parameters) {
  for (final parameter in parameters.whereType<Map>()) {
    if (parameter['in'] != 'body') {
      continue;
    }
    return _schemaRef(parameter['schema']);
  }
  return null;
}

String? _responseBodyRef(Object? responses) {
  if (responses is! Map) {
    return null;
  }

  final ok = responses['200'];
  if (ok is! Map) {
    return null;
  }

  return _schemaRef(ok['schema']);
}

String? _schemaRef(Object? schema) {
  if (schema is! Map) {
    return null;
  }

  final ref = schema[r'$ref'];
  if (ref != null) {
    return ref.toString();
  }

  final items = schema['items'];
  if (items is Map && items[r'$ref'] != null) {
    return 'array:${items[r'$ref']}';
  }

  return schema['type']?.toString();
}

String _stringListLiteral(List<String> values) {
  return '<String>[${values.map(_dartString).join(', ')}]';
}

String _nullableStringLiteral(String? value) {
  return value == null ? 'null' : _dartString(value);
}

String _dartString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\r', r'\r')
      .replaceAll('\n', r'\n');
  return "'$escaped'";
}

class _EndpointSpec {
  const _EndpointSpec({
    required this.operationId,
    required this.method,
    required this.path,
    required this.summary,
    required this.tags,
    required this.pathParameters,
    required this.queryParameters,
    required this.requestBodyRef,
    required this.responseBodyRef,
  });

  final String operationId;
  final String method;
  final String path;
  final String summary;
  final List<String> tags;
  final List<String> pathParameters;
  final List<String> queryParameters;
  final String? requestBodyRef;
  final String? responseBodyRef;
}
