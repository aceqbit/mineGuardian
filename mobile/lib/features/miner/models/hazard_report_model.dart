import 'package:equatable/equatable.dart';

class HazardReportModel extends Equatable {
  final String id;
  final String? localId;
  final String reporterId;
  final String reporterName;
  final String title;
  final String description;
  final String hazardType; // 'Gas Leak' | 'Rockfall Risk' | 'Ventilation Failure' | 'Flooding' | 'Machinery Malfunction' | 'Electrical' | 'Other'
  final String severity; // 'Low' | 'Medium' | 'High' | 'Critical'
  final String zone;
  final double? latitude;
  final double? longitude;
  final List<String> photos;
  final String? voiceNotes;
  final String status; // 'Reported' | 'Acknowledged' | 'Investigating' | 'Resolved'
  final String? supervisorNotes;
  final DateTime createdAt;
  final bool isSynced;

  const HazardReportModel({
    required this.id,
    this.localId,
    required this.reporterId,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.hazardType,
    required this.severity,
    required this.zone,
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.voiceNotes,
    this.status = 'Reported',
    this.supervisorNotes,
    required this.createdAt,
    this.isSynced = true,
  });

  factory HazardReportModel.fromJson(Map<String, dynamic> json) {
    return HazardReportModel(
      id: json['id'] ?? json['_id'] ?? '',
      localId: json['localId'],
      reporterId: json['reporter'] is Map ? json['reporter']['_id'] ?? '' : (json['reporter'] ?? ''),
      reporterName: json['reporter'] is Map ? json['reporter']['name'] ?? 'Miner' : (json['reporterName'] ?? 'Miner'),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      hazardType: json['hazardType'] ?? 'Other',
      severity: json['severity'] ?? 'Medium',
      zone: json['zone'] ?? 'Zone-A',
      latitude: json['location'] != null && json['location']['coordinates'] != null
          ? (json['location']['coordinates'][1] as num).toDouble()
          : (json['latitude'] != null ? (json['latitude'] as num).toDouble() : null),
      longitude: json['location'] != null && json['location']['coordinates'] != null
          ? (json['location']['coordinates'][0] as num).toDouble()
          : (json['longitude'] != null ? (json['longitude'] as num).toDouble() : null),
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      voiceNotes: json['voiceNotes'],
      status: json['status'] ?? 'Reported',
      supervisorNotes: json['supervisorNotes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isSynced: json['isSynced'] == 1 || json['isSynced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localId': localId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'title': title,
      'description': description,
      'hazardType': hazardType,
      'severity': severity,
      'zone': zone,
      'latitude': latitude,
      'longitude': longitude,
      'photos': photos,
      'voiceNotes': voiceNotes,
      'status': status,
      'supervisorNotes': supervisorNotes,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  @override
  List<Object?> get props => [
        id,
        localId,
        reporterId,
        reporterName,
        title,
        description,
        hazardType,
        severity,
        zone,
        latitude,
        longitude,
        photos,
        voiceNotes,
        status,
        supervisorNotes,
        createdAt,
        isSynced,
      ];
}
