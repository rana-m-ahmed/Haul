import 'package:dio/dio.dart';
import '../errors/error_handler.dart';
import 'api_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late Dio dio;

  ApiClient._internal() {
    const baseUrl = String.fromEnvironment('HAUL_API_BASE_URL', defaultValue: 'https://api.haul.com/v1');
    const apiKey = String.fromEnvironment('HAUL_API_KEY', defaultValue: '');

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (apiKey.isNotEmpty) {
          options.headers['X-API-Key'] = apiKey;
        }
        return handler.next(options);
      },
    ));
  }

  Future<ApiResponse<T>> request<T>({
    required String path,
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
      
      final parsedData = parser(response.data);
      return ApiSuccess<T>(parsedData);
    } on DioException catch (e) {
      final appException = mapDioErrorToAppException(e);
      return ApiFailure<T>(
        message: appException.message, 
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiFailure<T>(message: e.toString());
    }
  }
}
