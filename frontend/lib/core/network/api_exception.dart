class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  factory ApiException.fromJson(Map<String, dynamic> json, int statusCode) {
    final error = json['error'] as Map<String, dynamic>? ?? {};
    return ApiException(
      code: error['code'] as String? ?? 'UNKNOWN_ERROR',
      message: error['message'] as String? ?? 'An unexpected error occurred.',
      statusCode: statusCode,
    );
  }

  factory ApiException.network(String message) {
    return ApiException(code: 'NETWORK_ERROR', message: message, statusCode: 0);
  }

  factory ApiException.unauthorized() {
    return const ApiException(
      code: 'UNAUTHORIZED',
      message: 'Please log in to continue.',
      statusCode: 401,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
