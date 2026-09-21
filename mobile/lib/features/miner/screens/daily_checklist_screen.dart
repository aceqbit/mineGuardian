import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../shared/widgets/custom_button.dart';
import '../bloc/checklist_bloc.dart';
import '../widgets/checklist_card.dart';
import '../widgets/xp_reward_dialog.dart';

class DailyChecklistScreen extends StatefulWidget {
  const DailyChecklistScreen({super.key});

  @override
  State<DailyChecklistScreen> createState() => _DailyChecklistScreenState();
}

class _DailyChecklistScreenState extends State<DailyChecklistScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChecklistBloc>().add(const LoadChecklistQuestions());
  }

  void _handleSubmit() {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    context.read<ChecklistBloc>().add(
      SubmitDailyChecklist(
        shiftId: 'shift_morning_01',
        shiftType: 'Morning (Shift-A)',
        zone: user?.zone ?? 'Zone-A',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Daily Pre-Shift Checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<ChecklistBloc, ChecklistState>(
        listener: (context, state) {
          if (state is ChecklistSubmittedSuccess) {
            final authState = context.read<AuthBloc>().state;
            if (authState.user != null) {
              final updatedUser = authState.user!.copyWith(
                xp: authState.user!.xp + state.xpAwarded,
                streakDays: authState.user!.streakDays + 1,
              );
              context.read<AuthBloc>().add(UpdateUserProfile(updatedUser));
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => XpRewardDialog(
                xpAwarded: state.xpAwarded,
                title: state.isOfflineQueued ? 'Queued Offline (+50 XP)!' : 'Verified Compliant (+50 XP)!',
                subtitle: state.isOfflineQueued
                    ? 'Checklist saved locally. Will sync automatically when connection restores.'
                    : 'Checklist transmitted to supervisor. Your safety streak increased!',
                onDismiss: () {
                  Navigator.of(context).pop(); // pop dialog
                  Navigator.of(context).pop(); // return to home
                },
              ),
            );
          } else if (state is ChecklistError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.safetyRed),
            );
          }
        },
        builder: (context, state) {
          if (state is ChecklistLoading || state is ChecklistInitial) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.safetyOrange));
          }

          if (state is ChecklistLoaded) {
            final items = state.items;
            final completedCount = state.completedCount;
            final totalCount = items.length;
            final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

            return Column(
              children: [
                // Top Progress Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.cardBg,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mandatory Checks ($completedCount/$totalCount)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(progress * 100).toInt()}% Done',
                            style: const TextStyle(color: AppTheme.safetyOrange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.safetyOrange),
                        ),
                      ),
                    ],
                  ),
                ),

                // Questions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ChecklistCard(
                        item: item,
                        onToggle: () {
                          context.read<ChecklistBloc>().add(ToggleChecklistItem(item.id));
                        },
                      );
                    },
                  ),
                ),

                // Submit Button Bottom Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.cardBg,
                  child: CustomButton(
                    text: 'VERIFY & SUBMIT (+50 XP)',
                    icon: Icons.check_circle_outline,
                    onPressed: state.canSubmit ? _handleSubmit : null,
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
