import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/procedures_provider.dart';
import '../widgets/procedure_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProceduresProvider>().fetchProcedures();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final procs = context.watch<ProceduresProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigatore Burocratico'),
        centerTitle: false,
        actions: [
          if (auth.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    auth.email![0].toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                onSelected: (val) {
                  if (val == 'logout') auth.logout();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(auth.email!, style: const TextStyle(fontSize: 12)),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Esci'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.person_outline),
              label: const Text('Accedi'),
            ),
        ],
      ),
      body: _buildBody(procs, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/chat'),
        icon: const Icon(Icons.chat_outlined),
        label: const Text('Assistente AI'),
      ),
    );
  }

  Widget _buildBody(ProceduresProvider procs, ThemeData theme) {
    if (procs.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (procs.error != null && procs.procedures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(procs.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    context.read<ProceduresProvider>().fetchProcedures(),
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (procs.isOffline)
          SliverToBoxAdapter(
            child: MaterialBanner(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: const Text('Dati non aggiornati — sei offline.'),
              leading: const Icon(Icons.wifi_off, color: Colors.orange),
              actions: [
                TextButton(
                  onPressed: () =>
                      context.read<ProceduresProvider>().fetchProcedures(),
                  child: const Text('Aggiorna'),
                ),
              ],
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final proc = procs.procedures[index];
                return ProcedureCard(
                  procedure: proc,
                  onTap: () => context.push('/procedures/${proc.slug}'),
                );
              },
              childCount: procs.procedures.length,
            ),
          ),
        ),
      ],
    );
  }
}
