import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../shared/widgets/sync_status_badge.dart';
import '../bloc/hazard_bloc.dart';
import '../widgets/hazard_card.dart';
import 'daily_checklist_screen.dart';
import 'report_hazard_screen.dart';
import 'evacuation_map_screen.dart';
import 'sos_screen.dart';

class MinerHomeScreen extends StatefulWidget {
  const MinerHomeScreen({super.key});

  @override
  State<MinerHomeScreen> createState() => _MinerHomeScreenState();
}

class _MinerHomeScreenState extends State<MinerHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HazardBloc>().add(const LoadHazards());
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final minerName = user?.name ?? 'Miner';
        final zone = user?.zone ?? 'Zone-A (Shaft 3)';
        final safetyScore = user?.safetyScore ?? 98;
        final streakDays = user?.streakDays ?? 5;
        final xp = user?.xp ?? 350;

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: AppBar(
            backgroundColor: AppTheme.cardBg,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.safetyOrange.withOpacity(0.2),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppTheme.safetyOrange, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      minerName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      zone,
                      style: const TextStyle(fontSize: 12, color: AppTheme.safetyCyan),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              BlocBuilder<HazardBloc, HazardState>(
                builder: (context, hazardState) {
                  int pendingCount = 0;
                  if (hazardState is HazardLoaded) {
                    pendingCount = hazardState.offlineCount;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SyncStatusBadge(
                      isOnline: true,
                      pendingCount: pendingCount,
                      onSyncTap: () {
                        context.read<HazardBloc>().add(SyncQueuedHazards());
                      },
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                onPressed: _handleLogout,
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppTheme.safetyOrange,
            backgroundColor: AppTheme.cardBg,
            onRefresh: () async {
              context.read<HazardBloc>().add(const LoadHazards());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gamification Safety Score & Streak Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.cardBg, AppTheme.cardBg.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.safetyOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Safety Score', '$safetyScore%', AppTheme.safetyGreen, Icons.health_and_safety_outlined),
                        Container(width: 1, height: 40, color: Colors.white12),
                        _buildStatItem('Streak', '$streakDays Days', AppTheme.safetyAmber, Icons.local_fire_department_outlined),
                        Container(width: 1, height: 40, color: Colors.white12),
                        _buildStatItem('XP Rank', '$xp XP', AppTheme.safetyCyan, Icons.bolt_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Big Action Tiles Grid (Daily Checklist, Report Hazard, Maps, SOS)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      _buildQuickActionCard(
                        title: 'Daily Checklist',
                        subtitle: '+50 XP Pre-shift',
                        icon: Icons.checklist_rtl_rounded,
                        color: AppTheme.safetyOrange,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DailyChecklistScreen()),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        title: 'Report Hazard',
                        subtitle: 'Voice & Camera',
                        icon: Icons.add_alert_rounded,
                        color: AppTheme.safetyAmber,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReportHazardScreen()),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        title: 'Evacuation Map',
                        subtitle: 'Offline 2D Blueprint',
                        icon: Icons.map_outlined,
                        color: AppTheme.safetyCyan,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EvacuationMapScreen()),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        title: 'EMERGENCY SOS',
                        subtitle: 'Direct Siren & Alert',
                        icon: Icons.sos_rounded,
                        color: AppTheme.safetyRed,
                        isEmergency: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SosScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Live Zone Hazards Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ACTIVE ZONE HAZARDS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<HazardBloc>().add(const LoadHazards());
                        },
                        child: const Text('Refresh', style: TextStyle(color: AppTheme.safetyOrange, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  BlocBuilder<HazardBloc, HazardState>(
                    builder: (context, state) {
                      if (state is HazardLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: AppTheme.safetyOrange),
                          ),
                        );
                      } else if (state is HazardLoaded) {
                        if (state.hazards.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppTheme.safetyGreen, size: 36),
                                const SizedBox(height: 8),
                                const Text('No hazards reported in this zone.', style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text('All safety standards compliant', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.hazards.length,
                          itemBuilder: (context, index) {
                            return HazardCard(hazard: state.hazards[index]);
                          },
                        );
                      } else if (state is HazardError) {
                        return Center(
                          child: Text('Error: ${state.message}', style: const TextStyle(color: AppTheme.safetyRed)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEmergency ? color.withOpacity(0.15) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(isEmergency ? 0.7 : 0.4),
            width: isEmergency ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isEmergency ? color : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
