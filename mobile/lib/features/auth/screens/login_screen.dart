import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../miner/screens/miner_home_screen.dart';
import '../../supervisor/screens/supervisor_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        LoginWithPhonePin(
          phone: _phoneController.text.trim(),
          pin: _pinController.text.trim(),
        ),
      );
    }
  }

  void _fillDemo(String phone, String pin) {
    _phoneController.text = phone;
    _pinController.text = pin;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated && state.user != null) {
          if (state.user!.isSupervisor) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MinerHomeScreen()),
            );
          }
        } else if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.safetyRed,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Logo Badge
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.cardBg,
                          border: Border.all(color: AppTheme.safetyOrange, width: 2),
                        ),
                        child: const Icon(Icons.shield_outlined, size: 42, color: AppTheme.safetyOrange),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'MINE GUARDIAN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to access your safety portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Phone Number Field
                    const Text(
                      'PHONE NUMBER',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '+91 98765 43210',
                        prefixIcon: const Icon(Icons.phone_android, color: AppTheme.safetyOrange),
                        filled: true,
                        fillColor: AppTheme.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.safetyOrange, width: 1.5)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter phone number' : null,
                    ),
                    const SizedBox(height: 20),

                    // PIN Field
                    const Text(
                      '4-DIGIT SECURITY PIN',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.safetyAmber, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: _obscurePin,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 18),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.safetyOrange),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.safetyOrange, width: 1.5)),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 4) return 'Enter 4-digit PIN';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Login Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return CustomButton(
                          text: 'SECURE LOGIN',
                          icon: Icons.login,
                          isLoading: state.status == AuthStatus.loading,
                          onPressed: _onLoginPressed,
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    // Quick Demo Login helpers
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '⚡ Quick Demo Access',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _fillDemo('+919876543210', '1234'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.safetyOrange),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text('Miner Role', style: TextStyle(color: AppTheme.safetyOrange, fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _fillDemo('+919876543211', '1234'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.safetyAmber),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text('Supervisor', style: TextStyle(color: AppTheme.safetyAmber, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
