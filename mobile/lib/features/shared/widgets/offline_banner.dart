import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  final int pendingCount;
  final VoidCallback? onSyncTap;

  const OfflineBanner({
    super.key,
    required this.pendingCount,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.safetyAmber.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: AppTheme.safetyAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pendingCount > 0
                  ? 'Offline Mode: $pendingCount report(s) saved locally'
                  : 'Offline Mode: Changes will sync when online',
              style: const TextStyle(
                color: AppTheme.safetyAmber,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onSyncTap != null && pendingCount > 0)
            TextButton(
              onPressed: onSyncTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Sync Now',
                style: TextStyle(
                  color: AppTheme.safetyOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
