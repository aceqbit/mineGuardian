// App Constants — API URLs, route names, etc.
class AppConstants {
  // API Base URL — change to your server URL when deployed
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api'; // Android emulator localhost
  static const String wsBaseUrl = 'http://10.0.2.2:3000'; // Socket.io

  // Route names
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String minerHomeRoute = '/miner/home';
  static const String checklistRoute = '/miner/checklist';
  static const String hazardReportRoute = '/miner/hazard-report';
  static const String leaderboardRoute = '/miner/leaderboard';
  static const String sosRoute = '/sos';
  static const String supervisorHomeRoute = '/supervisor/home';
  static const String supervisorDashboardRoute = '/supervisor/dashboard';

  // SQLite DB name
  static const String dbName = 'mine_guardian.db';
  static const int dbVersion = 1;

  // XP values
  static const int checklistBaseXP = 50;
  static const int hazardReportXP = 30;
  static const int streakBonusXPPerDay = 5;
  static const int maxStreakBonusXP = 50;

  // Sync intervals
  static const Duration syncRetryInterval = Duration(seconds: 30);
  static const Duration connectivityCheckInterval = Duration(seconds: 10);

  // Checklist shift window
  static const int shiftWindowHours = 8; // 8-hour shift windows
}
