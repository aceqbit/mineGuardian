import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/network/socket_client.dart';
import 'core/database/database_helper.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/miner/bloc/checklist_bloc.dart';
import 'features/miner/bloc/hazard_bloc.dart';
import 'features/supervisor/bloc/supervisor_bloc.dart';
import 'features/shared/services/sync_service.dart';
import 'features/auth/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations and system UI overlay
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.darkBg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } catch (_) {}
  }

  // Initialize SQLite local database (with web-safe fallback)
  final dbHelper = DatabaseHelper.instance;
  try {
    await dbHelper.database;
  } catch (e) {
    print('DB Init note: $e');
  }

  // Initialize API and WebSocket clients
  final apiClient = ApiClient();
  try {
    SocketClient.init();
  } catch (e) {
    print('Socket Init note: $e');
  }

  // Initialize background sync service
  final syncService = SyncService(apiClient: apiClient, dbHelper: dbHelper);
  try {
    syncService.initialize();
  } catch (e) {
    print('SyncService Init note: $e');
  }

  runApp(MineGuardianApp(apiClient: apiClient));
}

class MineGuardianApp extends StatelessWidget {
  final ApiClient apiClient;

  const MineGuardianApp({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(apiClient: apiClient),
        ),
        BlocProvider<ChecklistBloc>(
          create: (_) => ChecklistBloc(apiClient: apiClient),
        ),
        BlocProvider<HazardBloc>(
          create: (_) => HazardBloc(apiClient: apiClient),
        ),
        BlocProvider<SupervisorBloc>(
          create: (_) => SupervisorBloc(apiClient: apiClient),
        ),
      ],
      child: MaterialApp(
        title: 'MineGuardian',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
