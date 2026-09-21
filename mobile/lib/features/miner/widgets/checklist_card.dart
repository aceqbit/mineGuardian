import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/checklist_model.dart';

class ChecklistCard extends StatelessWidget {
  final ChecklistItemModel item;
  final VoidCallback onToggle;

  const ChecklistCard({
    super.key,
    required this.item,
    required this.onToggle,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'PPE':
        return AppTheme.safetyOrange;
      case 'Equipment':
        return AppTheme.safetyAmber;
      case 'Environment':
        return AppTheme.safetyCyan;
      case 'Health':
        return AppTheme.safetyGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(item.category);

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isCompleted ? AppTheme.safetyGreen.withOpacity(0.08) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isCompleted ? AppTheme.safetyGreen : Colors.white12,
            width: item.isCompleted ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox Icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isCompleted ? AppTheme.safetyGreen : Colors.transparent,
                border: Border.all(
                  color: item.isCompleted ? AppTheme.safetyGreen : Colors.white38,
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 14),
            // Text & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: TextStyle(
                            color: catColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.question,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: item.isCompleted ? Colors.white70 : Colors.white,
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.questionHindi.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.questionHindi,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
