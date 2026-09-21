import 'package:equatable/equatable.dart';

class ChecklistItemModel extends Equatable {
  final String id;
  final String question;
  final String questionHindi;
  final String category; // 'PPE' | 'Equipment' | 'Environment' | 'Health'
  final bool isCompleted;
  final String? note;
  final String? photoUrl;

  const ChecklistItemModel({
    required this.id,
    required this.question,
    this.questionHindi = '',
    required this.category,
    this.isCompleted = false,
    this.note,
    this.photoUrl,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] ?? json['_id'] ?? '',
      question: json['question'] ?? '',
      questionHindi: json['questionHindi'] ?? '',
      category: json['category'] ?? 'PPE',
      isCompleted: json['isCompleted'] ?? false,
      note: json['note'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'questionHindi': questionHindi,
      'category': category,
      'isCompleted': isCompleted,
      'note': note,
      'photoUrl': photoUrl,
    };
  }

  ChecklistItemModel copyWith({
    String? id,
    String? question,
    String? questionHindi,
    String? category,
    bool? isCompleted,
    String? note,
    String? photoUrl,
  }) {
    return ChecklistItemModel(
      id: id ?? this.id,
      question: question ?? this.question,
      questionHindi: questionHindi ?? this.questionHindi,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [id, question, questionHindi, category, isCompleted, note, photoUrl];
}

class DailyChecklistSubmission extends Equatable {
  final String? id;
  final String shiftId;
  final String shiftType;
  final String zone;
  final List<ChecklistItemModel> items;
  final double? latitude;
  final double? longitude;
  final String status; // 'pending' | 'verified' | 'flagged'
  final DateTime createdAt;

  const DailyChecklistSubmission({
    this.id,
    required this.shiftId,
    required this.shiftType,
    required this.zone,
    required this.items,
    this.latitude,
    this.longitude,
    this.status = 'pending',
    required this.createdAt,
  });

  factory DailyChecklistSubmission.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<ChecklistItemModel> parsedItems = rawItems.map((i) => ChecklistItemModel.fromJson(Map<String, dynamic>.from(i))).toList();

    return DailyChecklistSubmission(
      id: json['id'] ?? json['_id'],
      shiftId: json['shiftId'] ?? '',
      shiftType: json['shiftType'] ?? 'Morning (Shift-A)',
      zone: json['zone'] ?? 'Zone-A',
      items: parsedItems,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftId': shiftId,
      'shiftType': shiftType,
      'zone': zone,
      'items': items.map((e) => e.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get completedCount => items.where((i) => i.isCompleted).length;
  bool get isAllCompleted => items.isNotEmpty && completedCount == items.length;

  @override
  List<Object?> get props => [id, shiftId, shiftType, zone, items, latitude, longitude, status, createdAt];
}
