import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_client.dart';
import '../../miner/models/hazard_report_model.dart';
import '../models/shift_model.dart';

// EVENTS
abstract class SupervisorEvent extends Equatable {
  const SupervisorEvent();
  @override
  List<Object?> get props => [];
}

class LoadSupervisorDashboard extends SupervisorEvent {
  final String? zone;
  const LoadSupervisorDashboard({this.zone});
  @override
  List<Object?> get props => [zone];
}

class OpenShiftWindow extends SupervisorEvent {
  final String shiftName;
  final String shiftType;
  final String zone;

  const OpenShiftWindow({
    required this.shiftName,
    required this.shiftType,
    required this.zone,
  });

  @override
  List<Object?> get props => [shiftName, shiftType, zone];
}

class CloseShiftWindow extends SupervisorEvent {
  final String shiftId;
  const CloseShiftWindow(this.shiftId);
  @override
  List<Object?> get props => [shiftId];
}

class VerifyWorkerChecklist extends SupervisorEvent {
  final String checklistId;
  const VerifyWorkerChecklist(this.checklistId);
  @override
  List<Object?> get props => [checklistId];
}

class FlagWorkerChecklist extends SupervisorEvent {
  final String checklistId;
  final String reason;
  const FlagWorkerChecklist({required this.checklistId, required this.reason});
  @override
  List<Object?> get props => [checklistId, reason];
}

class ResolveHazard extends SupervisorEvent {
  final String hazardId;
  final String notes;
  const ResolveHazard({required this.hazardId, required this.notes});
  @override
  List<Object?> get props => [hazardId, notes];
}

class HazardReceivedRealTime extends SupervisorEvent {
  final HazardReportModel hazard;
  const HazardReceivedRealTime(this.hazard);
  @override
  List<Object?> get props => [hazard];
}

// STATES
abstract class SupervisorState extends Equatable {
  const SupervisorState();
  @override
  List<Object?> get props => [];
}

class SupervisorInitial extends SupervisorState {}

class SupervisorLoading extends SupervisorState {}

class SupervisorLoaded extends SupervisorState {
  final ShiftModel? currentShift;
  final List<WorkerComplianceItem> workerCompliance;
  final List<HazardReportModel> activeHazards;
  final Map<String, dynamic> stats;

  const SupervisorLoaded({
    this.currentShift,
    required this.workerCompliance,
    required this.activeHazards,
    required this.stats,
  });

  @override
  List<Object?> get props => [currentShift, workerCompliance, activeHazards, stats];
}

class SupervisorError extends SupervisorState {
  final String message;
  const SupervisorError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class SupervisorBloc extends Bloc<SupervisorEvent, SupervisorState> {
  final ApiClient apiClient;

  SupervisorBloc({required this.apiClient}) : super(SupervisorInitial()) {
    on<LoadSupervisorDashboard>(_onLoadDashboard);
    on<OpenShiftWindow>(_onOpenShift);
    on<CloseShiftWindow>(_onCloseShift);
    on<VerifyWorkerChecklist>(_onVerifyWorker);
    on<FlagWorkerChecklist>(_onFlagWorker);
    on<ResolveHazard>(_onResolveHazard);
    on<HazardReceivedRealTime>(_onHazardRealTime);

    // Subscribe to real-time hazards via WebSocket
    SocketClient.on('hazard:new', (data) {
      if (data is Map<String, dynamic>) {
        final hazard = HazardReportModel.fromJson(data);
        add(HazardReceivedRealTime(hazard));
      }
    });
  }

  Future<void> _onLoadDashboard(LoadSupervisorDashboard event, Emitter<SupervisorState> emit) async {
    emit(SupervisorLoading());
    try {
      final res = await apiClient.get('/supervisor/dashboard', queryParams: event.zone != null ? {'zone': event.zone!} : null);

      if (res.success && res.data != null) {
        final d = res.data;
        ShiftModel? shift;
        if (d['activeShift'] != null) {
          shift = ShiftModel.fromJson(d['activeShift']);
        }

        final complianceList = (d['complianceList'] as List? ?? [])
            .map((c) => WorkerComplianceItem.fromJson(c))
            .toList();

        final hazardsList = (d['activeHazards'] as List? ?? [])
            .map((h) => HazardReportModel.fromJson(h))
            .toList();

        final stats = d['stats'] as Map<String, dynamic>? ?? {
          'totalWorkers': 24,
          'verifiedWorkers': 18,
          'complianceRate': 75.0,
          'activeHazardsCount': hazardsList.length,
        };

        emit(SupervisorLoaded(
          currentShift: shift,
          workerCompliance: complianceList,
          activeHazards: hazardsList,
          stats: stats,
        ));
      } else {
        // Fallback demo state
        emit(SupervisorLoaded(
          currentShift: ShiftModel(
            id: 'demo_shift_1',
            shiftName: 'Morning Shift A',
            shiftType: 'Morning (Shift-A)',
            zone: event.zone ?? 'Zone-A (Shaft 3)',
            supervisorId: 'sup_1',
            supervisorName: 'Supervisor Singh',
            status: 'open',
            startTime: DateTime.now().subtract(const Duration(hours: 2)),
            totalWorkers: 24,
            verifiedCount: 19,
            pendingCount: 4,
            flaggedCount: 1,
          ),
          workerCompliance: const [
            WorkerComplianceItem(
              id: 'c1',
              workerId: 'w1',
              workerName: 'Rajesh Kumar',
              employeeId: 'EMP-1042',
              zone: 'Zone-A',
              status: 'verified',
              completedItemsCount: 6,
              totalItemsCount: 6,
            ),
            WorkerComplianceItem(
              id: 'c2',
              workerId: 'w2',
              workerName: 'Amit Sharma',
              employeeId: 'EMP-1088',
              zone: 'Zone-A',
              status: 'pending',
              completedItemsCount: 6,
              totalItemsCount: 6,
            ),
            WorkerComplianceItem(
              id: 'c3',
              workerId: 'w3',
              workerName: 'Suresh Patel',
              employeeId: 'EMP-1102',
              zone: 'Zone-A',
              status: 'flagged',
              completedItemsCount: 4,
              totalItemsCount: 6,
            ),
          ],
          activeHazards: [
            HazardReportModel(
              id: 'h1',
              reporterId: 'w2',
              reporterName: 'Amit Sharma',
              title: 'Elevated Methane Sensor Reading',
              description: 'Chute #4 detector shows 1.4% CH4 concentration. Vent booster recommended.',
              hazardType: 'Gas Leak',
              severity: 'High',
              zone: 'Zone-A (Shaft 3)',
              createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
            ),
          ],
          stats: const {
            'totalWorkers': 24,
            'verifiedWorkers': 19,
            'complianceRate': 79.2,
            'activeHazardsCount': 1,
          },
        ));
      }
    } catch (e) {
      emit(SupervisorError(e.toString()));
    }
  }

  Future<void> _onOpenShift(OpenShiftWindow event, Emitter<SupervisorState> emit) async {
    try {
      final res = await apiClient.post('/shifts/open', body: {
        'shiftName': event.shiftName,
        'shiftType': event.shiftType,
        'zone': event.zone,
      });

      if (res.success) {
        add(LoadSupervisorDashboard(zone: event.zone));
      }
    } catch (e) {
      emit(SupervisorError(e.toString()));
    }
  }

  Future<void> _onCloseShift(CloseShiftWindow event, Emitter<SupervisorState> emit) async {
    try {
      final res = await apiClient.post('/shifts/close/${event.shiftId}', body: {});
      if (res.success) {
        add(const LoadSupervisorDashboard());
      }
    } catch (e) {
      emit(SupervisorError(e.toString()));
    }
  }

  Future<void> _onVerifyWorker(VerifyWorkerChecklist event, Emitter<SupervisorState> emit) async {
    try {
      final res = await apiClient.patch('/checklist/verify/${event.checklistId}', body: {});
      if (res.success) {
        add(const LoadSupervisorDashboard());
      }
    } catch (e) {
      emit(SupervisorError(e.toString()));
    }
  }

  Future<void> _onFlagWorker(FlagWorkerChecklist event, Emitter<SupervisorState> emit) async {
    try {
      final res = await apiClient.patch('/checklist/flag/${event.checklistId}', body: {
        'reason': event.reason,
      });
      if (res.success) {
        add(const LoadSupervisorDashboard());
      }
    } catch (e) {
      emit(SupervisorError(e.toString()));
    }
  }

  Future<void> _onResolveHazard(ResolveHazard event, Emitter<SupervisorState> emit) async {
    try {
      final res = await apiClient.patch('/hazards/resolve/${event.hazardId}', body: {
        'notes': event.notes,
      });
      if (res.success) {
        add(const LoadSupervisorDashboard());
      }
    } catch (e) {
      emit(SupervisorError(e.toString()));
    }
  }

  void _onHazardRealTime(HazardReceivedRealTime event, Emitter<SupervisorState> emit) {
    if (state is SupervisorLoaded) {
      final current = state as SupervisorLoaded;
      final updatedHazards = [event.hazard, ...current.activeHazards];
      emit(SupervisorLoaded(
        currentShift: current.currentShift,
        workerCompliance: current.workerCompliance,
        activeHazards: updatedHazards,
        stats: {
          ...current.stats,
          'activeHazardsCount': updatedHazards.length,
        },
      ));
    }
  }
}
