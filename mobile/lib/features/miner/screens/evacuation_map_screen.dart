import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EvacuationMapScreen extends StatefulWidget {
  const EvacuationMapScreen({super.key});

  @override
  State<EvacuationMapScreen> createState() => _EvacuationMapScreenState();
}

class _EvacuationMapScreenState extends State<EvacuationMapScreen> {
  String _selectedLevel = 'Level -2 (Main Drift)';

  final List<String> _levels = [
    'Level -1 (Adit Entry)',
    'Level -2 (Main Drift)',
    'Level -3 (Deep Shaft)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Offline Evacuation Blueprint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.safetyGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.safetyGreen),
            ),
            child: const Row(
              children: [
                Icon(Icons.offline_pin, color: AppTheme.safetyGreen, size: 14),
                SizedBox(width: 4),
                Text('Cached', style: TextStyle(color: AppTheme.safetyGreen, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Level selector tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.cardBg,
            child: Row(
              children: _levels.map((lvl) {
                final isSelected = _selectedLevel == lvl;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLevel = lvl),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.safetyOrange : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          lvl.split('(').first.trim(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Blueprint 2D Mine Schematic Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.safetyCyan.withOpacity(0.4), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: MineBlueprintPainter(),
                      size: Size.infinite,
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You are here: Shaft 3 Crosscut', style: TextStyle(color: AppTheme.safetyCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('Nearest Refuge: 120m North-East', style: TextStyle(color: AppTheme.safetyGreen, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Map Legend
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.cardBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Evacuation Route', AppTheme.safetyGreen, Icons.arrow_forward),
                _buildLegendItem('Refuge Chamber', AppTheme.safetyCyan, Icons.shelves),
                _buildLegendItem('Fresh Air Shaft', AppTheme.safetyAmber, Icons.air),
                _buildLegendItem('Hazard Area', AppTheme.safetyRed, Icons.warning_amber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class MineBlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    // Draw grid
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Main Tunnels (Drifts)
    final tunnelPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    // Main vertical haulage shaft
    canvas.drawLine(Offset(size.width * 0.3, 40), Offset(size.width * 0.3, size.height - 50), tunnelPaint);
    // Crosscuts
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.3), Offset(size.width * 0.85, size.height * 0.3), tunnelPaint);
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.6), Offset(size.width * 0.8, size.height * 0.6), tunnelPaint);
    canvas.drawLine(Offset(size.width * 0.8, size.height * 0.3), Offset(size.width * 0.8, size.height * 0.8), tunnelPaint);

    // Evacuation Green Path
    final evacPaint = Paint()
      ..color = AppTheme.safetyGreen
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final evacPath = Path();
    evacPath.moveTo(size.width * 0.7, size.height * 0.6);
    evacPath.lineTo(size.width * 0.3, size.height * 0.6);
    evacPath.lineTo(size.width * 0.3, 40);
    canvas.drawPath(evacPath, evacPaint);

    // Current Location Marker (Pulse Blue)
    final userPos = Offset(size.width * 0.7, size.height * 0.6);
    final userPaint = Paint()..color = AppTheme.safetyCyan;
    canvas.drawCircle(userPos, 8, userPaint);

    // Refuge Chamber Marker
    final refugePos = Offset(size.width * 0.8, size.height * 0.3);
    final refugePaint = Paint()..color = AppTheme.safetyGreen;
    canvas.drawRect(Rect.fromCenter(center: refugePos, width: 22, height: 22), refugePaint);

    // Hazard Marker
    final hazardPos = Offset(size.width * 0.5, size.height * 0.3);
    final hazardPaint = Paint()..color = AppTheme.safetyRed;
    canvas.drawCircle(hazardPos, 10, hazardPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
