import 'package:equatable/equatable.dart';

class ShiftModel extends Equatable {
  final String id;
  final String shiftName;
  final String shiftType; // 'Morning (Shift-A)' | 'Afternoon (Shift-B)' | 'Night (Shift-C)'
  final String zone;
  final String supervisorId;
  final String supervisorName;
  final String status; // 'open' | 'active' | 'closed'
  final DateTime startTime;
  final DateTime? endTime;
  final int totalWorkers;
  final int verifiedCount;
  final int pendingCount;
  final int flaggedCount;

  const ShiftModel({
    required this.id,
    required this.shiftName,
    required this.shiftType,
    required this.zone,
    required this.supervisorId,
    required this.supervisorName,
    this.status = 'open',
    required this.startTime,
    this.endTime,
    this.totalWorkers = 0,
    this.verifiedCount = 0,
    this.pendingCount = 0,
    this.flaggedCount = 0,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] ?? json['_id'] ?? '',
      shiftName: json['shiftName'] ?? 'Shift',
      shiftType: json['shiftType'] ?? 'Morning (Shift-A)',
      zone: json['zone'] ?? 'Zone-A',
      supervisorId: json['supervisor'] is Map ? json['supervisor']['_id'] ?? '' : (json['supervisor'] ?? ''),
      supervisorName: json['supervisor'] is Map ? json['supervisor']['name'] ?? 'Supervisor' : (json['supervisorName'] ?? 'Supervisor'),
      status: json['status'] ?? 'open',
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      totalWorkers: json['totalWorkers'] ?? 0,
      verifiedCount: json['verifiedCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      flaggedCount: json['flaggedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftName': shiftName,
      'shiftType': shiftType,
      'zone': zone,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'status': status,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalWorkers': totalWorkers,
      'verifiedCount': verifiedCount,
      'pendingCount': pendingCount,
      'flaggedCount': flaggedCount,
    };
  }

  double get complianceRate => totalWorkers > 0 ? (verifiedCount / totalWorkers) : 0.0;

  @override
  List<Object?> get props => [
        id,
        shiftName,
        shiftType,
        zone,
        supervisorId,
        supervisorName,
        status,
        startTime,
        endTime,
        totalWorkers,
        verifiedCount,
        pendingCount,
        flaggedCount,
      ];
}

class WorkerComplianceItem extends Equatable {
  final String id;
  final String workerId;
  final String workerName;
  final String employeeId;
  final String zone;
  final String status; // 'verified' | 'pending' | 'flagged' | 'absent'
  final DateTime? submittedAt;
  final double? latitude;
  final double? longitude;
  final int completedItemsCount;
  final int totalItemsCount;

  const WorkerComplianceItem({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.employeeId,
    required this.zone,
    this.status = 'pending',
    this.submittedAt,
    this.latitude,
    this.longitude,
    this.completedItemsCount = 0,
    this.totalItemsCount = 6,
  });

  factory WorkerComplianceItem.fromJson(Map<String, dynamic> json) {
    return WorkerComplianceItem(
      id: json['id'] ?? json['_id'] ?? '',
      workerId: json['user'] is Map ? json['user']['_id'] ?? '' : (json['workerId'] ?? ''),
      workerName: json['user'] is Map ? json['user']['name'] ?? 'Worker' : (json['workerName'] ?? 'Worker'),
      employeeId: json['user'] is Map ? json['user']['employeeId'] ?? 'EMP-000' : (json['employeeId'] ?? 'EMP-000'),
      zone: json['zone'] ?? 'Zone-A',
      status: json['status'] ?? 'pending',
      submittedAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      completedItemsCount: json['completedItemsCount'] ?? (json['items'] is List ? (json['items'] as List).where((i) => i['isCompleted'] == true).length : 0),
      totalItemsCount: json['totalItemsCount'] ?? 6,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workerId,
        workerName,
        employeeId,
        zone,
        status,
        submittedAt,
        latitude,
        longitude,
        completedItemsCount,
        totalItemsCount,
      ];
}
