import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SyncStatusBadge extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final VoidCallback? onSyncTap;

  const SyncStatusBadge({
    super.key,
    required this.isOnline,
    required this.pendingCount,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSyncTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isOnline
              ? (pendingCount > 0 ? AppTheme.safetyAmber.withOpacity(0.15) : AppTheme.safetyGreen.withOpacity(0.15))
              : AppTheme.safetyRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline
                ? (pendingCount > 0 ? AppTheme.safetyAmber : AppTheme.safetyGreen)
                : AppTheme.safetyRed,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? (pendingCount > 0 ? AppTheme.safetyAmber : AppTheme.safetyGreen)
                    : AppTheme.safetyRed,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline
                  ? (pendingCount > 0 ? 'Syncing ($pendingCount)' : 'Live')
                  : 'Offline ($pendingCount)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOnline
                    ? (pendingCount > 0 ? AppTheme.safetyAmber : AppTheme.safetyGreen)
                    : AppTheme.safetyRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
