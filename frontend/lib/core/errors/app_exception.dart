sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection failed']);
}

class NotFoundError extends AppException {
  final String productId;
  const NotFoundError(this.productId) : super('Not found: $productId');
}

class RateLimitError extends AppException {
  final String service;
  const RateLimitError(this.service) : super('Rate limit exceeded for $service');
}

class UnauthorizedError extends AppException {
  const UnauthorizedError([super.message = 'Unauthorized']);
}

class PaymentError extends AppException {
  final String code;
  const PaymentError(this.code, String message) : super(message);
}

class BackendError extends AppException {
  const BackendError(super.message);
}
