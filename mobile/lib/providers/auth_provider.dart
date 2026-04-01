import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/auth_storage.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  String? _email;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiClient, this._authStorage);

  String? get email => _email;
  bool get isLoggedIn => _email != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> tryAutoLogin() async {
    final token = await _authStorage.getAccessToken();
    final email = await _authStorage.getEmail();
    if (token != null && email != null) {
      _email = email;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiClient.dio.post(
        '/v1/auth/token',
        data: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      await _authStorage.saveTokens(
        accessToken: response.data['access_token'] as String,
        refreshToken: response.data['refresh_token'] as String,
        email: email,
      );
      _email = email;
      _error = null;
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _error = e.response?.statusCode == 401
          ? 'Email o password non validi.'
          : 'Errore di connessione. Riprova.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _setLoading(true);
    try {
      await _apiClient.dio.post(
        '/v1/auth/register',
        data: {'email': email, 'password': password},
      );
      _error = null;
      _setLoading(false);
      return await login(email, password);
    } on DioException catch (e) {
      _error = e.response?.statusCode == 409
          ? 'Email già registrata.'
          : 'Errore durante la registrazione.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authStorage.clearTokens();
    _email = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
