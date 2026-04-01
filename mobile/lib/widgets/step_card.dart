import 'package:flutter/material.dart';
import '../models/procedure.dart';

// ── Palette Direction B ───────────────────────────────────────────────────────
const _cobalt = Color(0xFF1A47B8);
const _cobaltLight = Color(0xFFEEF2FF);
const _warmGrey = Color(0xFFF5F4F2);
const _textPrimary = Color(0xFF0F1A2E);
const _textSecondary = Color(0xFF64748B);
const _textMuted = Color(0xFF94A3B8);
const _cardBorder = Color(0xFFE8EDF4);
const _successGreen = Color(0xFF16A34A);
const _successLight = Color(0xFFF0FDF4);
const _warningOrange = Color(0xFFD97706);
const _warningLight = Color(0xFFFFF8E6);

class StepCard extends StatefulWidget {
  final ProcedureStep step;
  final bool isCompleted;
  final Set<int> completedDocIndexes;
  final VoidCallback onStepToggle;
  final bool initiallyExpanded;

  const StepCard({
    super.key,
    required this.step,
    required this.isCompleted,
    required this.completedDocIndexes,
    required this.onStepToggle,
    this.initiallyExpanded = false,
  });

  @override
  State<StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<StepCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _controller;
  late final Animation<double> _expandAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _rotateAnim = Tween(begin: 0.0, end: 0.5).animate(_expandAnim);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? _successGreen.withAlpha(55) : _cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step badge – tap to toggle completion
                  GestureDetector(
                    onTap: widget.onStepToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: done ? _successGreen : _cobaltLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: done
                              ? _successGreen
                              : _cobalt.withAlpha(40),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: done
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${widget.step.order}',
                                style: const TextStyle(
                                  color: _cobalt,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + time pill
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.step.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: done ? _textMuted : _textPrimary,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: _textMuted,
                          ),
                        ),
                        if (widget.step.tempoStimatoGiorni != null) ...[
                          const SizedBox(height: 4),
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label:
                                '~${widget.step.tempoStimatoGiorni} giorni',
                            color: _successGreen,
                            background: _successLight,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _rotateAnim,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Expandable body ─────────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(height: 1, color: _cardBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        widget.step.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          height: 1.5,
                        ),
                      ),
                      // Meta pills
                      if (widget.step.ufficio != null ||
                          widget.step.costoStimatoEur != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (widget.step.ufficio != null)
                              _InfoChip(
                                icon: Icons.location_on_rounded,
                                label: widget.step.ufficio!,
                                color: _cobalt,
                                background: _cobaltLight,
                              ),
                            if (widget.step.costoStimatoEur != null)
                              _InfoChip(
                                icon: Icons.euro_rounded,
                                label:
                                    '~${widget.step.costoStimatoEur!.toStringAsFixed(0)} €',
                                color: _warningOrange,
                                background: _warningLight,
                              ),
                          ],
                        ),
                      ],
                      // Documents
                      if (widget.step.documents.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'DOCUMENTI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.step.documents
                            .map((doc) => _DocumentRow(doc: doc)),
                      ],
                      // Mark done / undo button
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: widget.onStepToggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: done ? _successLight : _cobaltLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                done
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 15,
                                color: done ? _successGreen : _cobalt,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                done
                                    ? 'Step completato'
                                    : 'Segna come fatto',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      done ? _successGreen : _cobalt,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
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
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
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

// ── Document row ───────────────────────────────────────────────────────────────

class _DocumentRow extends StatelessWidget {
  final ProcedureDocument doc;
  const _DocumentRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: doc.required ? _cobaltLight : _warmGrey,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              doc.required
                  ? Icons.description_rounded
                  : Icons.description_outlined,
              size: 14,
              color: doc.required ? _cobalt : _textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        doc.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: doc.required
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    if (!doc.required)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _warmGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'opz.',
                          style: TextStyle(
                            fontSize: 9,
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                if (doc.notes != null)
                  Text(
                    doc.notes!,
                    style: const TextStyle(
                        fontSize: 11, color: _textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
