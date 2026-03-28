import 'package:dio/dio.dart';
import 'auth_storage.dart';
import 'constants.dart';

class ApiClient {
  final AuthStorage _authStorage;
  late final Dio dio;

  ApiClient(this._authStorage) {
    dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(_authStorage, dio));
  }
}

class _AuthInterceptor extends Interceptor {
  final AuthStorage _authStorage;
  final Dio _dio;

  _AuthInterceptor(this._authStorage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _authStorage.getRefreshToken();
    if (refreshToken == null) return handler.next(err);

    try {
      final response = await _dio.post(
        '/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      final newAccess = response.data['access_token'] as String;
      final newRefresh = response.data['refresh_token'] as String;
      final email = await _authStorage.getEmail() ?? '';
      await _authStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
        email: email,
      );

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retried = await _dio.fetch(retryOptions);
      handler.resolve(retried);
    } catch (_) {
      await _authStorage.clearTokens();
      handler.next(err);
    }
  }
}
