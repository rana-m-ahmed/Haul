import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('fromJson parses Success variant correctly', () {
      final json = {'data': {'id': 1, 'name': 'Test'}};
      final response = ApiResponse.fromJson(
        json, 
        (data) => data as Map<String, dynamic>,
      );

      expect(response, isA<ApiSuccess<Map<String, dynamic>>>());
      final successResponse = response as ApiSuccess<Map<String, dynamic>>;
      expect(successResponse.data['id'], 1);
      expect(successResponse.data['name'], 'Test');
    });

    test('fromJson parses Failure variant correctly', () {
      final json = {'error': 'Unauthorized', 'code': 401};
      final response = ApiResponse<dynamic>.fromJson(json, (data) => data);

      expect(response, isA<ApiFailure<dynamic>>());
      final failureResponse = response as ApiFailure<dynamic>;
      expect(failureResponse.message, 'Unauthorized');
      expect(failureResponse.statusCode, 401);
    });
  });
}
