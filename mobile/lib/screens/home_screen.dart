import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/procedure.dart';
import '../providers/auth_provider.dart';
import '../providers/procedures_provider.dart';

// ── Palette Direction B ───────────────────────────────────────────────────────
const _cobalt = Color(0xFF1A47B8);
const _cobaltDark = Color(0xFF1538A0);
const _cobaltLight = Color(0xFFEEF2FF);
const _warmGrey = Color(0xFFF5F4F2);
const _textPrimary = Color(0xFF0F1A2E);
const _textSecondary = Color(0xFF64748B);
const _textMuted = Color(0xFF94A3B8);
const _cardBorder = Color(0xFFE8EDF4);

// ── Mappa categorie ───────────────────────────────────────────────────────────
const _categoryLabels = {
  'anagrafe': 'Anagrafe',
  'stato-civile': 'Stato Civile',
  'tributi': 'Tributi',
  'edilizia': 'Edilizia',
  'mobilita': 'Mobilità',
  'attivita-produttive': 'Attività Produttive',
  'lavoro': 'Lavoro',
  'sociale': 'Sociale',
};

const _categoryIcons = {
  'anagrafe': Icons.badge_rounded,
  'stato-civile': Icons.family_restroom_rounded,
  'tributi': Icons.receipt_long_rounded,
  'edilizia': Icons.home_work_rounded,
  'mobilita': Icons.directions_car_rounded,
  'attivita-produttive': Icons.storefront_rounded,
  'lavoro': Icons.work_rounded,
  'sociale': Icons.volunteer_activism_rounded,
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProceduresProvider>().fetchProcedures();
    });
  }

  List<Procedure> _filtered(List<Procedure> all) {
    if (_selectedCategory == null) return all;
    return all.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final procs = context.watch<ProceduresProvider>();

    return Scaffold(
      backgroundColor: _warmGrey,
      body: IndexedStack(
        index: _navIndex,
        children: [
          // ── Tab 0: Home ──────────────────────────────────────────────────
          CustomScrollView(
            slivers: [
              _buildHeader(auth),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildCategoryChips(procs),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildSectionLabel(procs),
              _buildProceduresList(procs),
              _buildAiBanner(),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
          // ── Tab 1: Procedure ─────────────────────────────────────────────
          CustomScrollView(
            slivers: [
              _buildProcedureTabHeader(),
              _buildCategoryChips(procs),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildSectionLabel(procs),
              _buildProceduresList(procs),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(AuthProvider auth) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cobalt, _cobaltDark],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: 20,
          right: 20,
          bottom: 26,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REGIONE CALABRIA',
                  style: TextStyle(
                    color: Colors.white.withAlpha(153),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                _buildUserAction(auth),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Navigatore\nBurocratico',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            _buildLocationPill(),
          ],
        ),
      ),
    );
  }

  Widget _buildProcedureTabHeader() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          bottom: 18,
        ),
        child: const Text(
          'Procedure',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  // ── Category chips ───────────────────────────────────────────────────────────

  Widget _buildCategoryChips(ProceduresProvider procs) {
    if (!procs.initialized || procs.procedures.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Estrai le categorie presenti nelle procedure caricate, in ordine
    final categories = _categoryLabels.keys
        .where((c) => procs.procedures.any((p) => p.category == c))
        .toList();

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _CategoryChip(
              label: 'Tutte',
              icon: Icons.apps_rounded,
              selected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            ),
            const SizedBox(width: 8),
            ...categories.map((cat) {
              final count = procs.procedures.where((p) => p.category == cat).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  label: '${_categoryLabels[cat]} ($count)',
                  icon: _categoryIcons[cat] ?? Icons.folder_rounded,
                  selected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(ProceduresProvider procs) {
    final filtered = _filtered(procs.procedures);
    final label = _selectedCategory != null
        ? '${_categoryLabels[_selectedCategory]} — ${filtered.length} procedur${filtered.length == 1 ? 'a' : 'e'}'
        : 'Tutte le procedure (${filtered.length})';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (procs.isOffline) ...[
              const SizedBox(width: 8),
              const Icon(Icons.wifi_off_rounded, size: 14, color: Colors.orange),
              const SizedBox(width: 3),
              const Text('offline', style: TextStyle(fontSize: 11, color: Colors.orange)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Procedures list ──────────────────────────────────────────────────────────

  Widget _buildProceduresList(ProceduresProvider procs) {
    if (procs.isLoading || !procs.initialized) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator(color: _cobalt)),
        ),
      );
    }
    if (procs.error != null && procs.procedures.isEmpty) {
      return SliverToBoxAdapter(child: _buildErrorState(procs));
    }

    final filtered = _filtered(procs.procedures);

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              _selectedCategory != null
                  ? 'Nessuna procedura in questa categoria.'
                  : 'Nessuna procedura disponibile.',
              style: const TextStyle(color: _textMuted),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final proc = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProcedureListCard(
                procedure: proc,
                onTap: () => context.push('/procedures/${proc.slug}'),
              ),
            );
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildErrorState(ProceduresProvider procs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: _textMuted),
          const SizedBox(height: 12),
          Text(
            procs.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<ProceduresProvider>().fetchProcedures(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Riprova'),
            style: FilledButton.styleFrom(backgroundColor: _cobalt),
          ),
        ],
      ),
    );
  }

  // ── AI banner ────────────────────────────────────────────────────────────────

  Widget _buildAiBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: GestureDetector(
          onTap: () => context.push('/chat'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: _cobalt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🤖', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hai dubbi? Chiedi all'AI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Il tuo assistente burocratico sempre disponibile',
                        style: TextStyle(color: Color(0xFFB3C3EF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _cardBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0),
              ),
              _NavItem(
                icon: Icons.list_alt_rounded,
                label: 'Procedure',
                active: _navIndex == 1,
                onTap: () => setState(() => _navIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAction(AuthProvider auth) {
    if (auth.isLoggedIn) {
      return GestureDetector(
        onTap: () => _showUserMenu(auth),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(30),
            border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
          ),
          child: Center(
            child: Text(
              auth.email![0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => context.push('/login'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: const Text(
          'Accedi',
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildLocationPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 11, color: Colors.white.withAlpha(180)),
          const SizedBox(width: 4),
          Text(
            'Provincia di Cosenza',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(auth.email!),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Esci'),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category chip ──────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _cobalt : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _cobalt : _cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? Colors.white : _textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Procedure list card ────────────────────────────────────────────────────────

class _ProcedureListCard extends StatelessWidget {
  final Procedure procedure;
  final VoidCallback onTap;

  const _ProcedureListCard({required this.procedure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _cobaltLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Icon(
                  _categoryIcons[procedure.category] ?? Icons.folder_rounded,
                  color: _cobalt,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          procedure.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _categoryLabels[procedure.category] ?? procedure.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _cobalt,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    procedure.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildBadges(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: _textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges() {
    final badges = <Widget>[];

    if (procedure.tempoStimatoGiorni != null) {
      badges.add(_InfoBadge(
        label: '${procedure.tempoStimatoGiorni} gg',
        icon: Icons.schedule_rounded,
        background: const Color(0xFFF0FDF4),
        color: const Color(0xFF16A34A),
      ));
    }
    if (procedure.costoStimatoEur != null) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 6));
      badges.add(_InfoBadge(
        label: procedure.costoStimatoEur == 0
            ? 'Gratuito'
            : '€${procedure.costoStimatoEur!.toStringAsFixed(0)}',
        icon: Icons.euro_rounded,
        background: procedure.costoStimatoEur == 0
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFF8E6),
        color: procedure.costoStimatoEur == 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFD97706),
      ));
    }
    if (procedure.steps.isNotEmpty) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 6));
      badges.add(_InfoBadge(
        label: '${procedure.steps.length} step',
        icon: Icons.checklist_rounded,
        background: _cobaltLight,
        color: _cobalt,
      ));
    }

    return Row(children: badges);
  }
}

// ── Info badge ─────────────────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color color;

  const _InfoBadge({
    required this.label,
    required this.icon,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav item ───────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: active ? 32 : 0,
              decoration: BoxDecoration(
                color: _cobalt,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            Icon(icon, color: active ? _cobalt : _textMuted, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? _cobalt : _textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
