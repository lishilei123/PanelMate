class PanelApiException implements Exception {
  const PanelApiException(
    this.message, {
    this.code,
    this.statusCode,
    this.payload,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? payload;

  factory PanelApiException.missingEntranceCode() {
    return const PanelApiException(
      '当前选择的 API 版本必须填写 EntranceCode。',
      code: 'missing_entrance_code',
    );
  }

  factory PanelApiException.unmapped(String feature) {
    return PanelApiException(
      '$feature 暂未适配当前 API 版本。',
      code: 'unmapped_feature',
    );
  }

  factory PanelApiException.http({
    required int statusCode,
    required String message,
    Object? payload,
  }) {
    return PanelApiException(
      message,
      code: 'http_error',
      statusCode: statusCode,
      payload: payload,
    );
  }

  factory PanelApiException.network({
    required String message,
    String code = 'network_error',
    Object? payload,
  }) {
    return PanelApiException(
      message,
      code: code,
      payload: payload,
    );
  }

  factory PanelApiException.timeout({
    required String message,
    Object? payload,
  }) {
    return PanelApiException(
      message,
      code: 'request_timeout',
      payload: payload,
    );
  }

  @override
  String toString() {
    return 'PanelApiException('
        'code: $code, '
        'statusCode: $statusCode, '
        'message: $message, '
        'payload: $payload'
        ')';
  }
}
