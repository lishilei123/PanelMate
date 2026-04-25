class PanelEndpointInput {
  const PanelEndpointInput({
    required this.host,
    this.port,
    this.scheme,
    this.pathSegments = const <String>[],
  });

  final String host;
  final int? port;
  final String? scheme;
  final List<String> pathSegments;
}

class PanelEndpointParser {
  const PanelEndpointParser._();

  static PanelEndpointInput parse(
    String input, {
    String defaultScheme = 'https',
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Endpoint is empty.');
    }

    final uri = Uri.parse(_toUriCandidate(trimmed, defaultScheme));
    if (uri.host.isEmpty) {
      throw FormatException('Invalid endpoint: $input');
    }

    return PanelEndpointInput(
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      scheme: uri.scheme.isEmpty ? null : uri.scheme,
      pathSegments: uri.pathSegments
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false),
    );
  }

  static String normalizeHost(
    String input, {
    String defaultScheme = 'https',
  }) {
    return parse(input, defaultScheme: defaultScheme).host;
  }

  static String _toUriCandidate(String input, String defaultScheme) {
    if (_hasScheme(input)) {
      return input;
    }

    if (_looksLikeBareIpv6(input)) {
      return '$defaultScheme://[$input]';
    }

    return '$defaultScheme://$input';
  }

  static bool _hasScheme(String input) {
    return RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://').hasMatch(input);
  }

  static bool _looksLikeBareIpv6(String input) {
    return !input.startsWith('[') && ':'.allMatches(input).length > 1;
  }
}
