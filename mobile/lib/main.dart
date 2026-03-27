import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/auth_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/procedures_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authStorage = AuthStorage();
  final apiClient = ApiClient(authStorage);

  final authProvider = AuthProvider(apiClient, authStorage);
  await authProvider.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProceduresProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ChatProvider(apiClient)),
      ],
      child: const NavBurApp(),
    ),
  );
}
