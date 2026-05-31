sealed class ApiResponse<T> {
  const ApiResponse();

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    if (json.containsKey('data')) {
      return ApiSuccess<T>(fromJsonT(json['data']));
    } else if (json.containsKey('error')) {
      return ApiFailure<T>(
        message: json['error'] as String,
        statusCode: json['code'] as int?,
      );
    }
    return ApiFailure<T>(message: 'Invalid response format');
  }
}

class ApiSuccess<T> extends ApiResponse<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResponse<T> {
  final String message;
  final int? statusCode;
  const ApiFailure({required this.message, this.statusCode});
}
