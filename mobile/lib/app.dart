import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/procedure_detail_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => const HomeScreen(),
    ),
    GoRoute(
      path: '/procedures/:slug',
      builder: (context, state) =>
          ProcedureDetailScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, _) => const ChatScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, _) => const LoginScreen(),
    ),
  ],
);

class NavBurApp extends StatelessWidget {
  const NavBurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Navigatore Burocratico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A47B8), // cobalt Direction B
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      routerConfig: _router,
    );
  }
}
