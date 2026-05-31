import 'package:dio/dio.dart';
import 'app_exception.dart';

AppException mapDioErrorToAppException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      
      if (statusCode == 401 || statusCode == 403) {
        return const UnauthorizedError();
      } else if (statusCode == 404) {
        return NotFoundError(data is Map ? (data['productId']?.toString() ?? 'unknown') : 'unknown');
      } else if (statusCode == 429) {
        return RateLimitError(data is Map ? (data['service']?.toString() ?? 'unknown') : 'unknown');
      } else if (statusCode == 402) {
        return PaymentError(
          data is Map ? (data['code']?.toString() ?? 'unknown') : 'unknown', 
          data is Map ? (data['message']?.toString() ?? 'Payment failed') : 'Payment failed',
        );
      }
      
      return BackendError(data is Map ? (data['message']?.toString() ?? error.message ?? 'Server error') : 'Server error');
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return BackendError(error.message ?? 'Unknown error');
  }
}
