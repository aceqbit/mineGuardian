import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../miner/models/hazard_report_model.dart';
import '../../miner/widgets/hazard_card.dart';
import '../bloc/supervisor_bloc.dart';

class HazardReviewScreen extends StatefulWidget {
  const HazardReviewScreen({super.key});

  @override
  State<HazardReviewScreen> createState() => _HazardReviewScreenState();
}

class _HazardReviewScreenState extends State<HazardReviewScreen> {
  String _filterSeverity = 'All';

  final List<String> _severities = ['All', 'Critical', 'High', 'Medium', 'Low'];

  void _showResolveDialog(HazardReportModel hazard) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Resolve: ${hazard.title}', style: const TextStyle(color: AppTheme.safetyGreen, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hazard Type: ${hazard.hazardType} | Zone: ${hazard.zone}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            const Text('Action Taken / Corrective Notes:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. Vent fan restarted, methane concentration stabilized to 0.2%...',
                filled: true,
                fillColor: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SupervisorBloc>().add(
                ResolveHazard(hazardId: hazard.id, notes: noteController.text.trim()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hazard marked as resolved!'), backgroundColor: AppTheme.safetyGreen),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.safetyGreen, foregroundColor: Colors.black),
            child: const Text('Mark Resolved', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Hazard Review & Dispatch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<SupervisorBloc, SupervisorState>(
        builder: (context, state) {
          if (state is! SupervisorLoaded) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.safetyOrange));
          }

          var hazards = state.activeHazards;
          if (_filterSeverity != 'All') {
            hazards = hazards.where((h) => h.severity.toLowerCase() == _filterSeverity.toLowerCase()).toList();
          }

          return Column(
            children: [
              // Severity Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppTheme.cardBg,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _severities.map((sev) {
                      final isSelected = _filterSeverity == sev;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(sev),
                          selected: isSelected,
                          selectedColor: AppTheme.safetyOrange,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _filterSeverity = sev);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Hazard List
              Expanded(
                child: hazards.isEmpty
                    ? Center(
                        child: Text(
                          'No active $_filterSeverity hazards found.',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: hazards.length,
                        itemBuilder: (context, index) {
                          final hazard = hazards[index];
                          return HazardCard(
                            hazard: hazard,
                            onTap: () => _showResolveDialog(hazard),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
