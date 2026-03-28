import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/procedure.dart';

class ProceduresProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<Procedure> _procedures = [];
  Procedure? _detail;
  bool _isLoading = false;
  bool _initialized = false;
  bool _isOffline = false;
  String? _error;

  // slug → set of completed step orders
  final Map<String, Set<int>> _completedSteps = {};

  ProceduresProvider(this._apiClient);

  List<Procedure> get procedures => _procedures;
  Procedure? get detail => _detail;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  bool get isOffline => _isOffline;
  String? get error => _error;

  Set<int> completedSteps(String slug) => _completedSteps[slug] ?? {};

  Future<void> fetchProcedures() async {
    _setLoading(true);
    try {
      final response = await _apiClient.dio.get('/v1/procedures');
      final list = (response.data as List<dynamic>)
          .map((e) => Procedure.fromJson(e as Map<String, dynamic>))
          .toList();
      _procedures = list;
      _isOffline = false;
      _error = null;
      await _cacheToLocal(list);
    } on DioException {
      final cached = await _loadFromCache();
      if (cached != null) {
        _procedures = cached;
        _isOffline = true;
        _error = null;
      } else {
        _error = 'Impossibile caricare le procedure. Controlla la connessione.';
      }
    } catch (_) {
      _error = 'Errore durante il caricamento delle procedure.';
    } finally {
      _initialized = true;
      _setLoading(false);
    }
  }

  Future<void> fetchDetail(String slug) async {
    _detail = null;
    _setLoading(true);
    try {
      final response = await _apiClient.dio.get('/v1/procedures/$slug');
      _detail = Procedure.fromJson(response.data as Map<String, dynamic>);
      _error = null;
    } on DioException {
      _error = 'Impossibile caricare i dettagli della procedura.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProgress(String slug) async {
    try {
      final response = await _apiClient.dio.get('/v1/progress/$slug');
      final steps = List<int>.from(response.data['completed_steps'] as List<dynamic>);
      _completedSteps[slug] = steps.toSet();
      notifyListeners();
    } on DioException {
      // not logged in or no progress yet — silent fail
    }
  }

  Future<void> toggleStep(String slug, int stepOrder) async {
    final current = _completedSteps[slug] ?? {};
    if (current.contains(stepOrder)) {
      current.remove(stepOrder);
    } else {
      current.add(stepOrder);
    }
    _completedSteps[slug] = current;
    notifyListeners();

    // persist to backend (fire-and-forget; no auth = silently ignored by interceptor)
    try {
      await _apiClient.dio.put(
        '/v1/progress/$slug',
        data: {'completed_steps': current.toList()},
      );
    } on DioException {
      // not logged in — progress only in-memory during session
    }
  }

  Future<void> _cacheToLocal(List<Procedure> list) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(list.map((p) => p.toJson()).toList());
    await prefs.setString('procedures_cache', json);
  }

  Future<List<Procedure>?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('procedures_cache');
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Procedure.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
