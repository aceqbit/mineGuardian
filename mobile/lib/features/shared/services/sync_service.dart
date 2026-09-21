import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_client.dart';

class SyncService {
  final ApiClient apiClient;
  final DatabaseHelper dbHelper;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required this.apiClient,
    required this.dbHelper,
  });

  void initialize({Function(int syncedCount)? onSyncCompleted}) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        syncQueuedData(onSyncCompleted: onSyncCompleted);
      }
    });
  }

  Future<int> syncQueuedData({Function(int syncedCount)? onSyncCompleted}) async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    int syncedCount = 0;

    try {
      // 1. Sync offline hazard reports
      final pendingHazards = await dbHelper.getPendingHazardReports();
      for (final hazard in pendingHazards) {
        final res = await apiClient.post('/hazards', body: {
          'title': hazard['title'],
          'description': hazard['description'],
          'hazardType': hazard['hazardType'],
          'severity': hazard['severity'],
          'zone': hazard['zone'],
          'latitude': hazard['latitude'],
          'longitude': hazard['longitude'],
          'voiceNotes': hazard['voiceNotes'],
          'localId': hazard['id'],
        });

        if (res.success) {
          await dbHelper.markHazardReportSynced(hazard['id'] as String);
          syncedCount++;
        }
      }

      // 2. Sync offline checklist submissions
      final pendingChecklists = await dbHelper.getPendingChecklists();
      for (final cl in pendingChecklists) {
        final res = await apiClient.post('/checklist/submit', body: {
          'items': cl['items'],
          'shiftId': cl['shiftId'],
          'shiftType': cl['shiftType'],
          'zone': cl['zone'],
          'latitude': cl['latitude'],
          'longitude': cl['longitude'],
        });

        if (res.success) {
          await dbHelper.markChecklistSynced(cl['id'] as String);
          syncedCount++;
        }
      }

      if (onSyncCompleted != null) {
        onSyncCompleted(syncedCount);
      }
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
