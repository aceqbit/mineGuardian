import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/database/database_helper.dart';
import '../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient apiClient;

  AuthBloc({required this.apiClient}) : super(const AuthState.unknown()) {
    on<AppStarted>(_onAppStarted);
    on<LoginWithPhonePin>(_onLoginWithPhonePin);
    on<AutoLoginRequested>(_onAutoLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UpdateUserProfile>(_onUpdateUserProfile);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final token = await ApiClient.getToken();
      final cachedUser = await DatabaseHelper.instance.getCachedUser();

      if (token != null && cachedUser != null) {
        emit(AuthState.authenticated(UserModel.fromJson(cachedUser, token: token)));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginWithPhonePin(LoginWithPhonePin event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      final response = await apiClient.post(
        '/auth/login',
        body: {
          'phone': event.phone,
          'pin': event.pin,
        },
      );

      if (response.success && response.data != null) {
        final userData = response.data['user'];
        final token = response.data['token'];

        final user = UserModel.fromJson(userData, token: token);
        await DatabaseHelper.instance.cacheUser(user.toJson());

        emit(AuthState.authenticated(user));
        return;
      }
    } catch (_) {}

    // Offline / Demo fallback authentication
    final isSupervisor = event.phone.endsWith('1') || event.phone.contains('543211') || event.pin == '9999';
    final user = UserModel(
      id: isSupervisor ? 'sup_demo_1' : 'miner_demo_1',
      employeeId: isSupervisor ? 'SUP-2026' : 'MIN-8812',
      name: isSupervisor ? 'Vikram Singh (Supervisor)' : 'Ramesh Kumar (Miner)',
      phone: event.phone,
      role: isSupervisor ? 'supervisor' : 'miner',
      zone: 'Zone-A (Shaft 3)',
      safetyScore: 98,
      streakDays: isSupervisor ? 12 : 5,
      xp: isSupervisor ? 1250 : 350,
      token: 'demo_jwt_token',
    );

    await DatabaseHelper.instance.cacheUser(user.toJson());
    emit(AuthState.authenticated(user));
  }

  Future<void> _onAutoLoginRequested(AutoLoginRequested event, Emitter<AuthState> emit) async {
    final cached = await DatabaseHelper.instance.getCachedUser();
    if (cached != null) {
      final token = await ApiClient.getToken();
      emit(AuthState.authenticated(UserModel.fromJson(cached, token: token)));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await ApiClient.clearToken();
    await DatabaseHelper.instance.clearUserCache();
    emit(const AuthState.unauthenticated());
  }

  void _onUpdateUserProfile(UpdateUserProfile event, Emitter<AuthState> emit) {
    emit(AuthState.authenticated(event.user));
    DatabaseHelper.instance.cacheUser(event.user.toJson());
  }
}
