import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/procedure.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/procedures_provider.dart';
import '../widgets/step_card.dart';

// ── Palette Direction B ───────────────────────────────────────────────────────
const _cobalt = Color(0xFF1A47B8);
const _cobaltDark = Color(0xFF1538A0);
const _cobaltLight = Color(0xFFEEF2FF);
const _warmGrey = Color(0xFFF5F4F2);
const _textPrimary = Color(0xFF0F1A2E);
const _textSecondary = Color(0xFF64748B);
const _textMuted = Color(0xFF94A3B8);
const _cardBorder = Color(0xFFE8EDF4);
const _successGreen = Color(0xFF16A34A);
const _warningOrange = Color(0xFFD97706);
const _warningLight = Color(0xFFFFF8E6);

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
    final procs = context.watch<ProceduresProvider>();
    final detail = procs.detail;

    if (procs.isLoading || detail == null) {
      return Scaffold(
        backgroundColor: _warmGrey,
        body: Column(
          children: [
            _buildGradientTop(context, null, null, 0.0),
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: _cobalt)),
            ),
          ],
        ),
      );
    }

    final completed = procs.completedSteps(widget.slug);
    final progress = detail.steps.isEmpty
        ? 0.0
        : completed.length / detail.steps.length;

    return Scaffold(
      backgroundColor: _warmGrey,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildGradientTop(context, detail, completed, progress),
          ),
          _buildDescriptionCard(detail),
          _buildStepsList(procs, detail, completed),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── Gradient header ─────────────────────────────────────────────────────────

  Widget _buildGradientTop(
    BuildContext context,
    Procedure? detail,
    Set<int>? completed,
    double progress,
  ) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cobalt, _cobaltDark],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + chat row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GhostButton(
                onTap: () => context.pop(),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              if (detail != null)
                GestureDetector(
                  onTap: () {
                    context
                        .read<ChatProvider>()
                        .setProcedureContext(widget.slug);
                    context.push('/chat');
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withAlpha(60)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Chiedi all'AI",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          if (detail == null) const SizedBox(height: 8),

          if (detail != null) ...[
            const SizedBox(height: 20),
            // Procedure title
            Text(
              detail.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // Ente pill
            _HeaderPill(
              icon: Icons.location_on_rounded,
              label: detail.enteCompetente,
            ),
            const SizedBox(height: 8),
            // Time + cost badges
            Row(
              children: [
                if (detail.tempoStimatoGiorni != null)
                  _HeaderBadge(
                    icon: Icons.schedule_rounded,
                    label: '~${detail.tempoStimatoGiorni} giorni',
                  ),
                if (detail.costoStimatoEur != null) ...[
                  const SizedBox(width: 8),
                  _HeaderBadge(
                    icon: Icons.euro_rounded,
                    label:
                        '~${detail.costoStimatoEur!.toStringAsFixed(0)} €',
                  ),
                ],
              ],
            ),

            if (detail.steps.isNotEmpty) ...[
              const SizedBox(height: 22),
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${completed!.length} di ${detail.steps.length} step completati',
                    style: TextStyle(
                      color: Colors.white.withAlpha(190),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (progress > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withAlpha(35),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              if (!isLoggedIn) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 11,
                          color: Colors.white.withAlpha(140)),
                      const SizedBox(width: 4),
                      Text(
                        'Accedi per salvare il progresso',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(170),
                          decoration: TextDecoration.underline,
                          decorationColor:
                              Colors.white.withAlpha(100),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  // ── Description card ────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildDescriptionCard(Procedure detail) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          detail.description,
          style: const TextStyle(
            fontSize: 13,
            color: _textSecondary,
            height: 1.55,
          ),
        ),
      ),
    );
  }

  // ── Steps list ──────────────────────────────────────────────────────────────

  SliverPadding _buildStepsList(
    ProceduresProvider procs,
    Procedure detail,
    Set<int> completed,
  ) {
    if (detail.steps.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: Text(
              'Nessuno step disponibile.',
              style: const TextStyle(color: _textMuted, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 12),
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
    );
  }
}

// ── Ghost button ───────────────────────────────────────────────────────────────

class _GhostButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GhostButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Header pill ────────────────────────────────────────────────────────────────

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withAlpha(190)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(210),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header badge ───────────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withAlpha(190)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
