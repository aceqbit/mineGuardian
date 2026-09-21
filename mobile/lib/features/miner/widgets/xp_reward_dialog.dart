import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class XpRewardDialog extends StatelessWidget {
  final int xpAwarded;
  final String title;
  final String subtitle;
  final VoidCallback onDismiss;

  const XpRewardDialog({
    super.key,
    required this.xpAwarded,
    this.title = 'Safety Compliance Verified!',
    this.subtitle = 'Daily pre-shift checklist completed successfully.',
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.safetyOrange, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.safetyOrange.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing XP badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.safetyOrange, AppTheme.safetyAmber],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.safetyOrange.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.bolt, size: 48, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '+$xpAwarded XP',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.safetyAmber,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.safetyOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'CONTINUE SHIFT',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
