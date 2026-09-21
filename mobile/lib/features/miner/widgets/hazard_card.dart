import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/hazard_report_model.dart';

class HazardCard extends StatelessWidget {
  final HazardReportModel hazard;
  final VoidCallback? onTap;

  const HazardCard({
    super.key,
    required this.hazard,
    this.onTap,
  });

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppTheme.safetyRed;
      case 'high':
        return AppTheme.safetyOrange;
      case 'medium':
        return AppTheme.safetyAmber;
      case 'low':
      default:
        return AppTheme.safetyGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sevColor = _getSeverityColor(hazard.severity);
    final timeFormatted = DateFormat('hh:mm a, dd MMM').format(hazard.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hazard.severity.toLowerCase() == 'critical' ? AppTheme.safetyRed.withOpacity(0.5) : Colors.white10,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Type + Severity Badge + Sync indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: sevColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hazard.hazardType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sevColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!hazard.isSynced)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.safetyAmber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 12, color: AppTheme.safetyAmber),
                            SizedBox(width: 4),
                            Text('Queued', style: TextStyle(fontSize: 10, color: AppTheme.safetyAmber, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sevColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: sevColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        hazard.severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: sevColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title & Description
            Text(
              hazard.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hazard.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),

            // Footer info: Zone, Reporter, Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.safetyCyan),
                    const SizedBox(width: 4),
                    Text(
                      hazard.zone,
                      style: const TextStyle(fontSize: 12, color: AppTheme.safetyCyan, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  timeFormatted,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
