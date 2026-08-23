// Define a domain-level failure (what your app uses everywhere)
class AppFailure {
  final String code;
  final String message;
  final int? httpStatus;
  final Map<String, dynamic>? details;

  AppFailure({
    required this.code,
    required this.message,
    this.httpStatus,
    this.details,
  });

  @override
  String toString() {
    return '''
AppFailure(
  code: $code,
  message: $message,
  httpStatus: $httpStatus,
  details: $details
)
''';
  }
}
