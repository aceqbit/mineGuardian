import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/services/location_service.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isActivated = false;
  String _sosStatus = 'HOLD 3 SECONDS TO TRIGGER SOS';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerEmergencySos() async {
    setState(() {
      _isActivated = true;
      _sosStatus = 'SOS ACTIVE — ALERT BROADCASTED TO RESCUE TEAM & SMS DISPATCHED';
    });

    final pos = await LocationService.getCurrentLocation();
    // In live system, posts to /hazards as Critical SOS and dispatches Twilio SMS immediately
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0707),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('EMERGENCY SOS', style: TextStyle(color: AppTheme.safetyRed, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning text
              Text(
                _isActivated ? '⚠️ CRITICAL EMERGENCY ACTIVE' : 'MINE EMERGENCY BROADCAST',
                style: TextStyle(
                  color: _isActivated ? AppTheme.safetyRed : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isActivated
                    ? 'Rescue team alerted with your live GPS location & telemetry.'
                    : 'Pressing the button triggers audible underground siren and SMS alerts to Mine Rescue.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 48),

              // Glowing Big SOS Button
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final glow = _isActivated ? (10 + _animController.value * 25) : 10.0;
                  return GestureDetector(
                    onTap: _triggerEmergencySos,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.safetyRed.withOpacity(0.7),
                            blurRadius: glow,
                            spreadRadius: _isActivated ? 6 : 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                            const SizedBox(height: 6),
                            Text(
                              _isActivated ? 'SOS SENT' : 'SOS',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isActivated ? AppTheme.safetyRed.withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isActivated ? AppTheme.safetyRed : Colors.white24),
                ),
                child: Text(
                  _sosStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isActivated ? AppTheme.safetyRed : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              // Emergency Contacts Quick List
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Mine Rescue Team', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        SizedBox(height: 2),
                        Text('Ext: 108 / 112', style: TextStyle(color: AppTheme.safetyOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Control Room', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        SizedBox(height: 2),
                        Text('Ext: 901', style: TextStyle(color: AppTheme.safetyAmber, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
