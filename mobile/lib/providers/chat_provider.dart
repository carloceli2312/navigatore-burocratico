import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _procedureSlug;

  ChatProvider(this._apiClient);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get procedureSlug => _procedureSlug;

  void setProcedureContext(String? slug) {
    _procedureSlug = slug;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _procedureSlug = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Snapshot della history PRIMA di aggiungere il nuovo messaggio
    final history = _messages
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.content})
        .toList();

    _messages.add(ChatMessage(content: text.trim(), isUser: true));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/v1/chat',
        data: {
          'message': text.trim(),
          if (history.isNotEmpty) 'history': history,
          if (_procedureSlug != null) 'procedure_slug': _procedureSlug,
        },
      );
      final reply = response.data['reply'] as String;
      _messages.add(ChatMessage(content: reply, isUser: false));
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 429
          ? 'Troppe richieste. Attendi un minuto.'
          : e.response?.statusCode == 503
              ? 'L\'assistente AI non è disponibile al momento.'
              : 'Errore di connessione. Riprova.';
      _messages.add(ChatMessage(content: msg, isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
