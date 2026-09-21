import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/database/database_helper.dart';
import '../models/hazard_report_model.dart';
import '../../shared/services/location_service.dart';

// EVENTS
abstract class HazardEvent extends Equatable {
  const HazardEvent();
  @override
  List<Object?> get props => [];
}

class LoadHazards extends HazardEvent {
  final String? zone;
  const LoadHazards({this.zone});
  @override
  List<Object?> get props => [zone];
}

class SubmitHazardReport extends HazardEvent {
  final String title;
  final String description;
  final String hazardType;
  final String severity;
  final String zone;
  final List<String> photos;
  final String? voiceNotes;

  const SubmitHazardReport({
    required this.title,
    required this.description,
    required this.hazardType,
    required this.severity,
    required this.zone,
    this.photos = const [],
    this.voiceNotes,
  });

  @override
  List<Object?> get props => [title, description, hazardType, severity, zone, photos, voiceNotes];
}

class SyncQueuedHazards extends HazardEvent {}

// STATES
abstract class HazardState extends Equatable {
  const HazardState();
  @override
  List<Object?> get props => [];
}

class HazardInitial extends HazardState {}

class HazardLoading extends HazardState {}

class HazardLoaded extends HazardState {
  final List<HazardReportModel> hazards;
  final int offlineCount;

  const HazardLoaded({required this.hazards, this.offlineCount = 0});

  @override
  List<Object?> get props => [hazards, offlineCount];
}

class HazardSubmitting extends HazardState {}

class HazardSubmittedSuccess extends HazardState {
  final HazardReportModel report;
  final bool isOfflineQueued;

  const HazardSubmittedSuccess({required this.report, this.isOfflineQueued = false});

  @override
  List<Object?> get props => [report, isOfflineQueued];
}

class HazardError extends HazardState {
  final String message;
  const HazardError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class HazardBloc extends Bloc<HazardEvent, HazardState> {
  final ApiClient apiClient;

  HazardBloc({required this.apiClient}) : super(HazardInitial()) {
    on<LoadHazards>(_onLoadHazards);
    on<SubmitHazardReport>(_onSubmitHazard);
    on<SyncQueuedHazards>(_onSyncQueued);
  }

  Future<void> _onLoadHazards(LoadHazards event, Emitter<HazardState> emit) async {
    emit(HazardLoading());
    try {
      final offlineHazardsRaw = await DatabaseHelper.instance.getPendingHazardReports();
      final offlineHazards = offlineHazardsRaw.map((h) => HazardReportModel.fromJson({
        ...h,
        'isSynced': false,
        'reporterName': 'You (Local)',
      })).toList();

      final res = await apiClient.get('/hazards', queryParams: event.zone != null ? {'zone': event.zone!} : null);
      List<HazardReportModel> serverHazards = [];

      if (res.success && res.data != null) {
        final rawList = res.data['hazards'] as List? ?? [];
        serverHazards = rawList.map((h) => HazardReportModel.fromJson(h)).toList();
      }

      emit(HazardLoaded(
        hazards: [...offlineHazards, ...serverHazards],
        offlineCount: offlineHazards.length,
      ));
    } catch (e) {
      emit(HazardError(e.toString()));
    }
  }

  Future<void> _onSubmitHazard(SubmitHazardReport event, Emitter<HazardState> emit) async {
    emit(HazardSubmitting());
    try {
      final position = await LocationService.getCurrentLocation();
      final localId = const Uuid().v4();

      final reportData = {
        'id': localId,
        'title': event.title,
        'description': event.description,
        'hazardType': event.hazardType,
        'severity': event.severity,
        'zone': event.zone,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'photos': event.photos,
        'voiceNotes': event.voiceNotes,
      };

      final res = await apiClient.post('/hazards', body: reportData);

      if (res.success && res.data != null) {
        final serverReport = HazardReportModel.fromJson(res.data['report']);
        emit(HazardSubmittedSuccess(report: serverReport, isOfflineQueued: false));
      } else {
        // Queue in SQLite
        await DatabaseHelper.instance.insertHazardReport({
          ...reportData,
          'isSynced': 0,
        });
        final localReport = HazardReportModel(
          id: localId,
          localId: localId,
          reporterId: 'current_miner',
          reporterName: 'You',
          title: event.title,
          description: event.description,
          hazardType: event.hazardType,
          severity: event.severity,
          zone: event.zone,
          latitude: position?.latitude,
          longitude: position?.longitude,
          photos: event.photos,
          voiceNotes: event.voiceNotes,
          status: 'Reported',
          createdAt: DateTime.now(),
          isSynced: false,
        );
        emit(HazardSubmittedSuccess(report: localReport, isOfflineQueued: true));
      }
    } catch (e) {
      final localId = const Uuid().v4();
      final reportData = {
        'id': localId,
        'title': event.title,
        'description': event.description,
        'hazardType': event.hazardType,
        'severity': event.severity,
        'zone': event.zone,
        'photos': event.photos.join(','),
        'voiceNotes': event.voiceNotes,
        'isSynced': 0,
      };
      await DatabaseHelper.instance.insertHazardReport(reportData);

      final localReport = HazardReportModel(
        id: localId,
        reporterId: 'current_miner',
        reporterName: 'You',
        title: event.title,
        description: event.description,
        hazardType: event.hazardType,
        severity: event.severity,
        zone: event.zone,
        photos: event.photos,
        voiceNotes: event.voiceNotes,
        createdAt: DateTime.now(),
        isSynced: false,
      );
      emit(HazardSubmittedSuccess(report: localReport, isOfflineQueued: true));
    }
  }

  Future<void> _onSyncQueued(SyncQueuedHazards event, Emitter<HazardState> emit) async {
    add(const LoadHazards());
  }
}
