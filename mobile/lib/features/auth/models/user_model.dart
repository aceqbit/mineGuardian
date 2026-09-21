import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String employeeId;
  final String name;
  final String phone;
  final String role; // 'miner' | 'supervisor' | 'safety_officer' | 'admin'
  final String zone; // e.g. 'Zone-A (Shaft 3)'
  final int safetyScore;
  final int streakDays;
  final int xp;
  final String? profilePhoto;
  final String? token;

  const UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.phone,
    required this.role,
    required this.zone,
    this.safetyScore = 100,
    this.streakDays = 0,
    this.xp = 0,
    this.profilePhoto,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'miner',
      zone: json['zone'] ?? 'Zone-A',
      safetyScore: json['safetyScore'] ?? 100,
      streakDays: json['streakDays'] ?? 0,
      xp: json['xp'] ?? 0,
      profilePhoto: json['profilePhoto'],
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'name': name,
      'phone': phone,
      'role': role,
      'zone': zone,
      'safetyScore': safetyScore,
      'streakDays': streakDays,
      'xp': xp,
      'profilePhoto': profilePhoto,
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? phone,
    String? role,
    String? zone,
    int? safetyScore,
    int? streakDays,
    int? xp,
    String? profilePhoto,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      zone: zone ?? this.zone,
      safetyScore: safetyScore ?? this.safetyScore,
      streakDays: streakDays ?? this.streakDays,
      xp: xp ?? this.xp,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      token: token ?? this.token,
    );
  }

  bool get isSupervisor => role == 'supervisor' || role == 'safety_officer' || role == 'admin';

  @override
  List<Object?> get props => [id, employeeId, name, phone, role, zone, safetyScore, streakDays, xp, profilePhoto, token];
}
