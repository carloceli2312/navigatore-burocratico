import 'package:flutter/material.dart';
import '../models/procedure.dart';

class ProcedureCard extends StatelessWidget {
  final Procedure procedure;
  final VoidCallback onTap;

  const ProcedureCard({super.key, required this.procedure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle[procedure.category.toLowerCase()] ??
        (emoji: '📋', background: const Color(0xFFE8F0FE));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(style.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    procedure.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    procedure.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (procedure.tempoStimatoGiorni != null)
                        _Badge(
                          label: '${procedure.tempoStimatoGiorni} gg',
                          icon: Icons.schedule_rounded,
                          background: const Color(0xFFF0FDF4),
                          color: const Color(0xFF16A34A),
                        ),
                      if (procedure.tempoStimatoGiorni != null && procedure.costoStimatoEur != null)
                        const SizedBox(width: 6),
                      if (procedure.costoStimatoEur != null)
                        _Badge(
                          label: '€${procedure.costoStimatoEur!.toStringAsFixed(0)}',
                          icon: Icons.euro_rounded,
                          background: const Color(0xFFFFF8E6),
                          color: const Color(0xFFD97706),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}

typedef _CategoryStyle = ({String emoji, Color background});

const Map<String, _CategoryStyle> _categoryStyle = {
  'edilizia': (emoji: '🏗️', background: Color(0xFFE8F0FE)),
  'anagrafe': (emoji: '🪪', background: Color(0xFFFFF8E6)),
  'fisco': (emoji: '💰', background: Color(0xFFE6F9F0)),
  'lavoro': (emoji: '💼', background: Color(0xFFFFF8E6)),
  'ambiente': (emoji: '🌿', background: Color(0xFFE6F9F0)),
};

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color color;

  const _Badge({
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
