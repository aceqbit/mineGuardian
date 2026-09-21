import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/shift_model.dart';

class ComplianceTile extends StatelessWidget {
  final WorkerComplianceItem item;
  final VoidCallback onVerify;
  final VoidCallback onFlag;

  const ComplianceTile({
    super.key,
    required this.item,
    required this.onVerify,
    required this.onFlag,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return AppTheme.safetyGreen;
      case 'flagged':
        return AppTheme.safetyRed;
      case 'pending':
      default:
        return AppTheme.safetyAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Worker avatar icon
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.2),
            radius: 20,
            child: Text(
              item.workerName.isNotEmpty ? item.workerName[0].toUpperCase() : 'W',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),

          // Worker Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.workerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${item.employeeId})',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.completedItemsCount}/${item.totalItemsCount} checks',
                      style: const TextStyle(fontSize: 12, color: AppTheme.safetyCyan),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions (Verify / Flag)
          if (item.status == 'pending') ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppTheme.safetyGreen, size: 28),
              onPressed: onVerify,
              tooltip: 'Verify',
            ),
            IconButton(
              icon: const Icon(Icons.flag_rounded, color: AppTheme.safetyRed, size: 24),
              onPressed: onFlag,
              tooltip: 'Flag & Notify',
            ),
          ],
        ],
      ),
    );
  }
}
