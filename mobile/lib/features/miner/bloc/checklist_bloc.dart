import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/database/database_helper.dart';
import '../models/checklist_model.dart';
import '../../shared/services/location_service.dart';

// EVENTS
abstract class ChecklistEvent extends Equatable {
  const ChecklistEvent();
  @override
  List<Object?> get props => [];
}

class LoadChecklistQuestions extends ChecklistEvent {
  final String? role;
  const LoadChecklistQuestions({this.role});
  @override
  List<Object?> get props => [role];
}

class ToggleChecklistItem extends ChecklistEvent {
  final String itemId;
  const ToggleChecklistItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class SubmitDailyChecklist extends ChecklistEvent {
  final String shiftId;
  final String shiftType;
  final String zone;

  const SubmitDailyChecklist({
    required this.shiftId,
    required this.shiftType,
    required this.zone,
  });

  @override
  List<Object?> get props => [shiftId, shiftType, zone];
}

// STATES
abstract class ChecklistState extends Equatable {
  const ChecklistState();
  @override
  List<Object?> get props => [];
}

class ChecklistInitial extends ChecklistState {}

class ChecklistLoading extends ChecklistState {}

class ChecklistLoaded extends ChecklistState {
  final List<ChecklistItemModel> items;
  final bool hasSubmittedToday;
  final DailyChecklistSubmission? lastSubmission;

  const ChecklistLoaded({
    required this.items,
    this.hasSubmittedToday = false,
    this.lastSubmission,
  });

  int get completedCount => items.where((i) => i.isCompleted).length;
  bool get canSubmit => items.isNotEmpty && completedCount == items.length && !hasSubmittedToday;

  @override
  List<Object?> get props => [items, hasSubmittedToday, lastSubmission];
}

class ChecklistSubmitting extends ChecklistState {}

class ChecklistSubmittedSuccess extends ChecklistState {
  final int xpAwarded;
  final bool isOfflineQueued;

  const ChecklistSubmittedSuccess({
    this.xpAwarded = 50,
    this.isOfflineQueued = false,
  });

  @override
  List<Object?> get props => [xpAwarded, isOfflineQueued];
}

class ChecklistError extends ChecklistState {
  final String message;
  const ChecklistError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  final ApiClient apiClient;

  ChecklistBloc({required this.apiClient}) : super(ChecklistInitial()) {
    on<LoadChecklistQuestions>(_onLoadQuestions);
    on<ToggleChecklistItem>(_onToggleItem);
    on<SubmitDailyChecklist>(_onSubmitChecklist);
  }

  Future<void> _onLoadQuestions(LoadChecklistQuestions event, Emitter<ChecklistState> emit) async {
    emit(ChecklistLoading());
    try {
      final res = await apiClient.get('/checklist/questions');
      List<ChecklistItemModel> items = [];

      if (res.success && res.data != null) {
        final rawQuestions = res.data['questions'] as List? ?? [];
        items = rawQuestions.map((q) => ChecklistItemModel(
          id: q['id'] ?? q['_id'] ?? const Uuid().v4(),
          question: q['question'] ?? '',
          questionHindi: q['questionHindi'] ?? '',
          category: q['category'] ?? 'PPE',
        )).toList();
      }

      if (items.isEmpty) {
        // Fallback default checklist questions
        items = [
          const ChecklistItemModel(
            id: '1',
            question: 'Safety Helmet & Cap Lamp functional with >80% battery?',
            questionHindi: 'सुरक्षा हेलमेट और टोपी का लैंप 80% से अधिक चार्ज है?',
            category: 'PPE',
          ),
          const ChecklistItemModel(
            id: '2',
            question: 'Steel-toe Boots and High-Visibility Reflective Vest worn?',
            questionHindi: 'स्टील-टो जूते और रिफ्लेक्टिव जैकेट पहनी है?',
            category: 'PPE',
          ),
          const ChecklistItemModel(
            id: '3',
            question: 'Self-Contained Self-Rescuer (SCSR) inspected and sealed?',
            questionHindi: 'SCSR ऑक्सीजन उपकरण चेक और सील किया गया है?',
            category: 'Equipment',
          ),
          const ChecklistItemModel(
            id: '4',
            question: 'Multi-gas detector calibrated (CO, CH4, O2 levels verified)?',
            questionHindi: 'गैस डिटेक्टर कैलिब्रेट और चेक किया गया है?',
            category: 'Environment',
          ),
          const ChecklistItemModel(
            id: '5',
            question: 'Dust mask / Respirator fitted properly?',
            questionHindi: 'डस्ट मास्क सही तरीके से पहना गया है?',
            category: 'PPE',
          ),
          const ChecklistItemModel(
            id: '6',
            question: 'Physically fit to enter underground shaft (no dizziness/fatigue)?',
            questionHindi: 'भूमिगत खदान में प्रवेश के लिए शारीरिक रूप से स्वस्थ हैं?',
            category: 'Health',
          ),
        ];
      }

      emit(ChecklistLoaded(items: items));
    } catch (e) {
      emit(ChecklistError(e.toString()));
    }
  }

  void _onToggleItem(ToggleChecklistItem event, Emitter<ChecklistState> emit) {
    if (state is ChecklistLoaded) {
      final current = state as ChecklistLoaded;
      final updated = current.items.map((item) {
        if (item.id == event.itemId) {
          return item.copyWith(isCompleted: !item.isCompleted);
        }
        return item;
      }).toList();

      emit(ChecklistLoaded(
        items: updated,
        hasSubmittedToday: current.hasSubmittedToday,
        lastSubmission: current.lastSubmission,
      ));
    }
  }

  Future<void> _onSubmitChecklist(SubmitDailyChecklist event, Emitter<ChecklistState> emit) async {
    if (state is! ChecklistLoaded) return;
    final current = state as ChecklistLoaded;

    emit(ChecklistSubmitting());

    try {
      final position = await LocationService.getCurrentLocation();
      final localId = const Uuid().v4();

      final checklistMap = {
        'id': localId,
        'shiftId': event.shiftId,
        'shiftType': event.shiftType,
        'zone': event.zone,
        'items': current.items.map((i) => i.toJson()).toList(),
        'latitude': position?.latitude,
        'longitude': position?.longitude,
      };

      final res = await apiClient.post('/checklist/submit', body: checklistMap);

      if (res.success) {
        emit(const ChecklistSubmittedSuccess(xpAwarded: 50, isOfflineQueued: false));
      } else {
        // Save to SQLite offline queue
        await DatabaseHelper.instance.insertChecklist(checklistMap);
        emit(const ChecklistSubmittedSuccess(xpAwarded: 50, isOfflineQueued: true));
      }
    } catch (e) {
      // Offline fallback: save to SQLite
      final localId = const Uuid().v4();
      final checklistMap = {
        'id': localId,
        'shiftId': event.shiftId,
        'shiftType': event.shiftType,
        'zone': event.zone,
        'items': current.items.map((i) => i.toJson()).toList(),
      };
      await DatabaseHelper.instance.insertChecklist(checklistMap);
      emit(const ChecklistSubmittedSuccess(xpAwarded: 50, isOfflineQueued: true));
    }
  }
}
