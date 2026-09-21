import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/screens/login_screen.dart';
import '../bloc/supervisor_bloc.dart';
import '../widgets/live_stat_card.dart';
import '../widgets/compliance_tile.dart';
import '../../miner/widgets/hazard_card.dart';
import 'shift_management_screen.dart';
import 'hazard_review_screen.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupervisorBloc>().add(const LoadSupervisorDashboard());
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppTheme.safetyAmber, size: 22),
            SizedBox(width: 8),
            Text('Supervisor Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.safetyOrange),
            onPressed: () => context.read<SupervisorBloc>().add(const LoadSupervisorDashboard()),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.safetyOrange,
        backgroundColor: AppTheme.cardBg,
        onRefresh: () async {
          context.read<SupervisorBloc>().add(const LoadSupervisorDashboard());
        },
        child: BlocConsumer<SupervisorBloc, SupervisorState>(
          listener: (context, state) {
            if (state is SupervisorError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppTheme.safetyRed),
              );
            }
          },
          builder: (context, state) {
            if (state is SupervisorLoading) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.safetyOrange));
            }

            if (state is SupervisorLoaded) {
              final shift = state.currentShift;
              final stats = state.stats;
              final complianceList = state.workerCompliance;
              final hazards = state.activeHazards;

              final totalWorkers = stats['totalWorkers'] ?? 24;
              final verifiedWorkers = stats['verifiedWorkers'] ?? 19;
              final activeHazardsCount = stats['activeHazardsCount'] ?? hazards.length;
              final complianceRate = stats['complianceRate'] ?? 79.2;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Shift Banner / Shift Controller
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.safetyAmber.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.safetyAmber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.schedule, color: AppTheme.safetyAmber, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shift?.shiftName ?? 'Morning Shift A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shift != null && shift.status == 'open'
                                      ? '🟢 Shift Window OPEN (Pre-shift checks accepted)'
                                      : '🔴 Shift Window CLOSED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: shift != null && shift.status == 'open' ? AppTheme.safetyGreen : AppTheme.safetyRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ShiftManagementScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.safetyAmber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // KPI Stat Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        LiveStatCard(
                          title: 'Compliance Rate',
                          value: '${complianceRate.toStringAsFixed(1)}%',
                          subtitle: '$verifiedWorkers of $totalWorkers verified',
                          icon: Icons.pie_chart_outline,
                          color: AppTheme.safetyGreen,
                        ),
                        LiveStatCard(
                          title: 'Pending Checks',
                          value: '${totalWorkers - verifiedWorkers}',
                          subtitle: 'Awaiting supervisor sign-off',
                          icon: Icons.hourglass_top,
                          color: AppTheme.safetyAmber,
                        ),
                        LiveStatCard(
                          title: 'Active Hazards',
                          value: '$activeHazardsCount',
                          subtitle: 'Live alerts in mine',
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.safetyRed,
                        ),
                        LiveStatCard(
                          title: 'Active Shift Roster',
                          value: '$totalWorkers',
                          subtitle: 'Miners underground',
                          icon: Icons.groups,
                          color: AppTheme.safetyCyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section: Worker Compliance Verification Queue
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'WORKER COMPLIANCE QUEUE',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1),
                        ),
                        Text(
                          '${complianceList.length} Total',
                          style: const TextStyle(fontSize: 12, color: AppTheme.safetyAmber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (complianceList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('All workers verified for current shift.', style: TextStyle(color: Colors.white54)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: complianceList.length,
                        itemBuilder: (context, index) {
                          final item = complianceList[index];
                          return ComplianceTile(
                            item: item,
                            onVerify: () {
                              context.read<SupervisorBloc>().add(VerifyWorkerChecklist(item.id));
                            },
                            onFlag: () {
                              _showFlagDialog(context, item.id);
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                    // Section: Real-time Mine Hazard Stream
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CRITICAL HAZARD STREAM',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const HazardReviewScreen()),
                            );
                          },
                          child: const Text('View All', style: TextStyle(color: AppTheme.safetyOrange, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (hazards.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('No unresolved safety hazards reported.', style: TextStyle(color: Colors.white54)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: hazards.take(3).length,
                        itemBuilder: (context, index) {
                          return HazardCard(hazard: hazards[index]);
                        },
                      ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showFlagDialog(BuildContext context, String checklistId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Flag Worker Compliance', style: TextStyle(color: AppTheme.safetyRed, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the reason for flagging (e.g. Missing SCSR apparatus, improper boots):', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Flag reason...',
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
                FlagWorkerChecklist(checklistId: checklistId, reason: reasonController.text.trim()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.safetyRed),
            child: const Text('Flag & Notify Miner'),
          ),
        ],
      ),
    );
  }
}
