import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class OtoKuRepository {
  Future<Map<String, dynamic>?> loadState();
  Future<void> saveState(Map<String, dynamic> state);
  Future<bool> hasCompletedOnboarding();
  Future<void> completeOnboarding();
}

class SqliteOtoKuRepository implements OtoKuRepository {
  SqliteOtoKuRepository._(this._database, this._preferences);

  static const _onboardingKey = 'onboarding_complete';
  final Database _database;
  final SharedPreferences _preferences;

  static Future<SqliteOtoKuRepository> open({String? databasePath}) async {
    final path =
        databasePath ?? p.join(await getDatabasesPath(), 'otoku_local.db');
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_state (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            payload TEXT NOT NULL
          )
        ''');
      },
    );
    return SqliteOtoKuRepository._(
      database,
      await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<Map<String, dynamic>?> loadState() async {
    final rows = await _database.query(
      'app_state',
      columns: ['payload'],
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(
      jsonDecode(rows.single['payload']! as String) as Map,
    );
  }

  @override
  Future<void> saveState(Map<String, dynamic> state) async {
    await _database.insert('app_state', {
      'id': 1,
      'payload': jsonEncode(state),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<bool> hasCompletedOnboarding() async =>
      _preferences.getBool(_onboardingKey) ?? false;

  @override
  Future<void> completeOnboarding() async {
    await _preferences.setBool(_onboardingKey, true);
  }

  Future<void> close() => _database.close();
}

class MemoryOtoKuRepository implements OtoKuRepository {
  MemoryOtoKuRepository({this.onboardingComplete = false});

  Map<String, dynamic>? _state;
  bool onboardingComplete;

  @override
  Future<Map<String, dynamic>?> loadState() async => _state == null
      ? null
      : Map<String, dynamic>.from(jsonDecode(jsonEncode(_state)) as Map);

  @override
  Future<void> saveState(Map<String, dynamic> state) async {
    _state = Map<String, dynamic>.from(jsonDecode(jsonEncode(state)) as Map);
  }

  @override
  Future<bool> hasCompletedOnboarding() async => onboardingComplete;

  @override
  Future<void> completeOnboarding() async {
    onboardingComplete = true;
  }
}
