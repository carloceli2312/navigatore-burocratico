import 'package:flutter/material.dart';
import '../models/procedure.dart';

class StepCard extends StatelessWidget {
  final ProcedureStep step;
  final bool isCompleted;
  final Set<int> completedDocIndexes;
  final VoidCallback onStepToggle;

  const StepCard({
    super.key,
    required this.step,
    required this.isCompleted,
    required this.completedDocIndexes,
    required this.onStepToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: GestureDetector(
          onTap: onStepToggle,
          child: CircleAvatar(
            backgroundColor:
                isCompleted ? theme.colorScheme.primary : Colors.grey[200],
            foregroundColor:
                isCompleted ? theme.colorScheme.onPrimary : Colors.grey[600],
            child: isCompleted
                ? const Icon(Icons.check, size: 18)
                : Text(
                    '${step.order}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
        ),
        title: Text(
          step.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: step.tempoStimatoGiorni != null
            ? Text(
                '~${step.tempoStimatoGiorni} giorni',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.description, style: theme.textTheme.bodyMedium),
                if (step.ufficio != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          step.ufficio!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
                if (step.costoStimatoEur != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.euro, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '~${step.costoStimatoEur!.toStringAsFixed(0)} €',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                if (step.documents.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Documenti necessari',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...step.documents.asMap().entries.map((entry) {
                    final doc = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            doc.required
                                ? Icons.description
                                : Icons.description_outlined,
                            size: 16,
                            color: doc.required
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: doc.required
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (doc.notes != null)
                                  Text(
                                    doc.notes!,
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          if (!doc.required)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'opz.',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
