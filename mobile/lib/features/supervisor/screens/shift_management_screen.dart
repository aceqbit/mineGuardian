import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';
import '../bloc/supervisor_bloc.dart';

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  final _shiftNameController = TextEditingController(text: 'Morning Shift A');
  String _selectedShiftType = 'Morning (Shift-A)';
  String _selectedZone = 'Zone-A (Shaft 3)';

  final List<String> _shiftTypes = [
    'Morning (Shift-A)',
    'Afternoon (Shift-B)',
    'Night (Shift-C)',
  ];

  final List<String> _zones = [
    'Zone-A (Shaft 3)',
    'Zone-B (Conveyor 2)',
    'Zone-C (Drill Face)',
    'Zone-D (Haulage Road)',
  ];

  @override
  void dispose() {
    _shiftNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Shift Window Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<SupervisorBloc, SupervisorState>(
        builder: (context, state) {
          final shift = (state is SupervisorLoaded) ? state.currentShift : null;
          final isOpen = shift != null && shift.status == 'open';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Shift Status Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOpen ? AppTheme.safetyGreen : AppTheme.safetyRed,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            shift?.shiftName ?? 'No Active Shift',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isOpen ? AppTheme.safetyGreen : AppTheme.safetyRed).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOpen ? 'ACTIVE / OPEN' : 'CLOSED',
                              style: TextStyle(
                                color: isOpen ? AppTheme.safetyGreen : AppTheme.safetyRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetail('Zone', shift?.zone ?? 'Zone-A'),
                          _buildDetail('Shift Type', shift?.shiftType ?? 'Morning (Shift-A)'),
                          _buildDetail('Total Roster', '${shift?.totalWorkers ?? 24} Miners'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (isOpen) ...[
                  // Close Shift Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.safetyRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.safetyRed.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End / Close Shift Window',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.safetyRed, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Closing the shift locks pre-shift checklist submissions and protects compliant workers against penalties. Non-compliant workers will be auto-flagged.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        CustomButton(
                          text: 'CLOSE SHIFT WINDOW',
                          color: AppTheme.safetyRed,
                          textColor: Colors.white,
                          icon: Icons.lock_clock,
                          onPressed: () {
                            context.read<SupervisorBloc>().add(CloseShiftWindow(shift.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Shift window closed successfully!'), backgroundColor: AppTheme.safetyGreen),
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Open New Shift Form
                  const Text('OPEN NEW SHIFT WINDOW', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1)),
                  const SizedBox(height: 12),

                  const Text('SHIFT NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _shiftNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('SHIFT TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedShiftType,
                        dropdownColor: AppTheme.cardBg,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: _shiftTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _selectedShiftType = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('MINE ZONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedZone,
                        dropdownColor: AppTheme.cardBg,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: _zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                        onChanged: (v) => setState(() => _selectedZone = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'OPEN PRE-SHIFT WINDOW',
                    icon: Icons.play_circle_outline,
                    color: AppTheme.safetyOrange,
                    onPressed: () {
                      context.read<SupervisorBloc>().add(
                        OpenShiftWindow(
                          shiftName: _shiftNameController.text.trim(),
                          shiftType: _selectedShiftType,
                          zone: _selectedZone,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New shift window opened!'), backgroundColor: AppTheme.safetyGreen),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetail(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
