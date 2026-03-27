import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/procedures_provider.dart';
import '../widgets/step_card.dart';

class ProcedureDetailScreen extends StatefulWidget {
  final String slug;
  const ProcedureDetailScreen({super.key, required this.slug});

  @override
  State<ProcedureDetailScreen> createState() => _ProcedureDetailScreenState();
}

class _ProcedureDetailScreenState extends State<ProcedureDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final procs = context.read<ProceduresProvider>();
      await procs.fetchDetail(widget.slug);
      if (!mounted) return;
      if (context.read<AuthProvider>().isLoggedIn) {
        await procs.loadProgress(widget.slug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final procs = context.watch<ProceduresProvider>();
    final detail = procs.detail;

    if (procs.isLoading || detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final completed = procs.completedSteps(widget.slug);
    final progress = detail.steps.isEmpty
        ? 0.0
        : completed.length / detail.steps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.name),
        actions: [
          IconButton(
            tooltip: 'Chiedi all\'assistente',
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              context.read<ChatProvider>().setProcedureContext(widget.slug);
              context.push('/chat');
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header card
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detail.enteCompetente,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (detail.tempoStimatoGiorni != null)
                          _Pill(
                            icon: Icons.schedule,
                            label: '~${detail.tempoStimatoGiorni} giorni',
                          ),
                        if (detail.costoStimatoEur != null) ...[
                          const SizedBox(width: 8),
                          _Pill(
                            icon: Icons.euro,
                            label: '~${detail.costoStimatoEur!.toStringAsFixed(0)} €',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Progress bar
          if (detail.steps.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Avanzamento',
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          '${completed.length}/${detail.steps.length} step',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    if (!context.watch<AuthProvider>().isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          onTap: () => context.push('/login'),
                          child: Text(
                            'Accedi per salvare il progresso',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Steps
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final step = detail.steps[index];
                  return StepCard(
                    step: step,
                    isCompleted: completed.contains(step.order),
                    completedDocIndexes: const {},
                    onStepToggle: () =>
                        procs.toggleStep(widget.slug, step.order),
                  );
                },
                childCount: detail.steps.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
