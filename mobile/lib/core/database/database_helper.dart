import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// SQLite Database Helper — Offline-first cache with Web fallback
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  // In-memory web fallback store
  final Map<String, dynamic> _webMemoryStore = {
    'hazard_queue': <Map<String, dynamic>>[],
    'checklist_queue': <Map<String, dynamic>>[],
    'user_cache': <String, dynamic>{},
  };

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    try {
      _db ??= await _initDatabase();
      return _db;
    } catch (e) {
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hazard_queue (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        hazardType TEXT,
        severity TEXT,
        zone TEXT,
        latitude REAL,
        longitude REAL,
        photos TEXT,
        voiceNotes TEXT,
        isSynced INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklist_queue (
        id TEXT PRIMARY KEY,
        shiftId TEXT,
        shiftType TEXT,
        zone TEXT,
        items TEXT,
        latitude REAL,
        longitude REAL,
        isSynced INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_cache (
        id TEXT PRIMARY KEY,
        userData TEXT
      )
    ''');
  }

  // ─────────────────────────────────────────
  // USER CACHING
  // ─────────────────────────────────────────
  Future<void> cacheUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_cache_data', jsonEncode(user));
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final db = await database;
        await db?.insert(
          'user_cache',
          {'id': 'current_user', 'userData': jsonEncode(user)},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('user_cache_data');
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str);
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final db = await database;
        final res = await db?.query('user_cache', where: 'id = ?', whereArgs: ['current_user'], limit: 1);
        if (res != null && res.isNotEmpty) {
          return jsonDecode(res.first['userData'] as String);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_cache_data');
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final db = await database;
        await db?.delete('user_cache');
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────
  // HAZARD QUEUE
  // ─────────────────────────────────────────
  Future<void> insertHazardReport(Map<String, dynamic> report) async {
    final entry = {
      'id': report['id'],
      'title': report['title'],
      'description': report['description'],
      'hazardType': report['hazardType'],
      'severity': report['severity'],
      'zone': report['zone'],
      'latitude': report['latitude'],
      'longitude': report['longitude'],
      'photos': report['photos'] is List ? (report['photos'] as List).join(',') : (report['photos'] ?? ''),
      'voiceNotes': report['voiceNotes'],
      'isSynced': report['isSynced'] == true || report['isSynced'] == 1 ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (kIsWeb) {
      final list = _webMemoryStore['hazard_queue'] as List<Map<String, dynamic>>;
      list.removeWhere((i) => i['id'] == entry['id']);
      list.add(entry);
      return;
    }

    try {
      final db = await database;
      await db?.insert('hazard_queue', entry, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      final list = _webMemoryStore['hazard_queue'] as List<Map<String, dynamic>>;
      list.add(entry);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingHazardReports() async {
    if (kIsWeb) {
      final list = _webMemoryStore['hazard_queue'] as List<Map<String, dynamic>>;
      return list.where((i) => i['isSynced'] == 0).map((r) {
        final map = Map<String, dynamic>.from(r);
        final rawPhotos = map['photos'] as String?;
        map['photos'] = rawPhotos != null && rawPhotos.isNotEmpty ? rawPhotos.split(',') : [];
        return map;
      }).toList();
    }

    try {
      final db = await database;
      final res = await db?.query('hazard_queue', where: 'isSynced = ?', whereArgs: [0]);
      if (res != null) {
        return res.map((r) {
          final map = Map<String, dynamic>.from(r);
          final rawPhotos = map['photos'] as String?;
          map['photos'] = rawPhotos != null && rawPhotos.isNotEmpty ? rawPhotos.split(',') : [];
          return map;
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> markHazardReportSynced(String id) async {
    if (kIsWeb) {
      final list = _webMemoryStore['hazard_queue'] as List<Map<String, dynamic>>;
      for (final item in list) {
        if (item['id'] == id) item['isSynced'] = 1;
      }
      return;
    }

    try {
      final db = await database;
      await db?.update('hazard_queue', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }

  // ─────────────────────────────────────────
  // CHECKLIST QUEUE
  // ─────────────────────────────────────────
  Future<void> insertChecklist(Map<String, dynamic> checklist) async {
    final entry = {
      'id': checklist['id'],
      'shiftId': checklist['shiftId'],
      'shiftType': checklist['shiftType'],
      'zone': checklist['zone'],
      'items': checklist['items'] is String ? checklist['items'] : jsonEncode(checklist['items']),
      'latitude': checklist['latitude'],
      'longitude': checklist['longitude'],
      'isSynced': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (kIsWeb) {
      final list = _webMemoryStore['checklist_queue'] as List<Map<String, dynamic>>;
      list.removeWhere((i) => i['id'] == entry['id']);
      list.add(entry);
      return;
    }

    try {
      final db = await database;
      await db?.insert('checklist_queue', entry, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      final list = _webMemoryStore['checklist_queue'] as List<Map<String, dynamic>>;
      list.add(entry);
    }
  }

  Future<List<Map<String, dynamic>>> getPendingChecklists() async {
    if (kIsWeb) {
      final list = _webMemoryStore['checklist_queue'] as List<Map<String, dynamic>>;
      return list.where((i) => i['isSynced'] == 0).map((r) {
        final map = Map<String, dynamic>.from(r);
        if (map['items'] is String) {
          try {
            map['items'] = jsonDecode(map['items'] as String);
          } catch (_) {}
        }
        return map;
      }).toList();
    }

    try {
      final db = await database;
      final res = await db?.query('checklist_queue', where: 'isSynced = ?', whereArgs: [0]);
      if (res != null) {
        return res.map((r) {
          final map = Map<String, dynamic>.from(r);
          if (map['items'] is String) {
            try {
              map['items'] = jsonDecode(map['items'] as String);
            } catch (_) {}
          }
          return map;
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> markChecklistSynced(String id) async {
    if (kIsWeb) {
      final list = _webMemoryStore['checklist_queue'] as List<Map<String, dynamic>>;
      for (final item in list) {
        if (item['id'] == id) item['isSynced'] = 1;
      }
      return;
    }

    try {
      final db = await database;
      await db?.update('checklist_queue', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }
}
