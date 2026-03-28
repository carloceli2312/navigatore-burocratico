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
    final auth = context.watch<AuthProvider>();
    final procs = context.watch<ProceduresProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          _buildHeader(auth),
          _buildSearchBar(),
          _buildCategoryChips(),
          _buildProceduresSection(procs),
          _buildQuickActions(),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    final username = auth.isLoggedIn ? auth.email!.split('@').first : null;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A6B), Color(0xFF0D2347)],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8B84B), Color(0xFFF0D070)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('🧭', style: TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navigatore Burocratico',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'CALABRIA · MVP',
                          style: TextStyle(
                            color: Colors.white.withAlpha(128),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (auth.isLoggedIn)
                  GestureDetector(
                    onTap: () => _showUserMenu(auth),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(38),
                        border: Border.all(color: Colors.white.withAlpha(51), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          username![0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => context.push('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: Colors.white.withAlpha(38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Accedi', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              username != null ? 'Ciao, $username 👋' : 'Benvenuto 👋',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cosa devi fare oggi?',
              style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                border: Border.all(color: Colors.white.withAlpha(38)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📍', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 5),
                  Text(
                    'Provincia di Cosenza',
                    style: TextStyle(color: Colors.white.withAlpha(191), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFFF4F6FB),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
              SizedBox(width: 10),
              Text(
                'Cerca una pratica o procedura…',
                style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CATEGORIE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(label: 'Tutti', active: true),
                  const SizedBox(width: 8),
                  _CategoryChip(label: 'Edilizia'),
                  const SizedBox(width: 8),
                  _CategoryChip(label: 'Anagrafe'),
                  const SizedBox(width: 8),
                  _CategoryChip(label: 'Fisco'),
                  const SizedBox(width: 8),
                  _CategoryChip(label: 'Lavoro'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceduresSection(ProceduresProvider procs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'PROCEDURE DISPONIBILI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.5,
                  ),
                ),
                if (procs.isOffline) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.wifi_off, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  const Text(
                    'offline',
                    style: TextStyle(fontSize: 10, color: Colors.orange),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildProceduresList(procs),
          ],
        ),
      ),
    );
  }

  Widget _buildProceduresList(ProceduresProvider procs) {
    if (procs.isLoading || !procs.initialized) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
      );
    }
    if (procs.error != null && procs.procedures.isEmpty) {
      return _buildErrorState(procs);
    }
    if (procs.procedures.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('Nessuna procedura disponibile.',
              style: TextStyle(color: Color(0xFF94A3B8))),
        ),
      );
    }
    return Column(
      children: procs.procedures
          .map((proc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProcedureCard(
                  procedure: proc,
                  onTap: () => context.push('/procedures/${proc.slug}'),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildErrorState(ProceduresProvider procs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            procs.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<ProceduresProvider>().fetchProcedures(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACCESSO RAPIDO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.7,
              children: [
                _QuickActionCard(
                  icon: '🤖',
                  title: "Chiedi all'AI",
                  subtitle: 'Assistente virtuale',
                  onTap: () => context.push('/chat'),
                ),
                const _QuickActionCard(
                  icon: '📁',
                  title: 'Le mie pratiche',
                  subtitle: 'Prossimamente',
                  enabled: false,
                ),
                const _QuickActionCard(
                  icon: '📍',
                  title: 'Sportelli vicini',
                  subtitle: 'Cosenza, CS',
                  enabled: false,
                ),
                const _QuickActionCard(
                  icon: '📰',
                  title: 'Novità normative',
                  subtitle: 'Prossimamente',
                  enabled: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F4F8))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: const [
              _NavItem(icon: Icons.home_rounded, label: 'Home', active: true),
              _NavItem(icon: Icons.explore_outlined, label: 'Esplora', enabled: false),
              _NavItem(icon: Icons.folder_outlined, label: 'Pratiche', enabled: false),
              _NavItem(icon: Icons.person_outline, label: 'Profilo', enabled: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool active;

  const _CategoryChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1A3A6B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFF1A3A6B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: active ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F4F8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 20,
                color: enabled ? null : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF1A3A6B)
        : enabled
            ? const Color(0xFF64748B)
            : const Color(0xFFCBD5E1);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (active)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A3A6B),
              ),
            ),
        ],
      ),
    );
  }
}
