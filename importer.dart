import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'schema.dart';

int _mins(String hhmm) { // "23:45" -> 1425 ; "00:10+1" -> 1450
  final next = hhmm.endsWith('+1');
  final t = hhmm.replaceAll('+1', '').split(':');
  return int.parse(t[0]) * 60 + int.parse(t[1]) + (next ? 1440 : 0);
}

/// Opens the DB, importing the bundled JSON on first run / version change.
Future<Database> openAppDb() async {
  final path = p.join(await getDatabasesPath(), 'mumbai_local.db');
  final db = await openDatabase(path, version: 1, onCreate: (d, _) async {
    for (final s in schemaSql) { await d.execute(s); }
  });
  final json = jsonDecode(await rootBundle.loadString('assets/mumbai_local.json'));
  final ver = '${json['data_version'] ?? 1}';
  final cur = await db.query('meta', where: "k='data_version'");
  if (cur.isNotEmpty && cur.first['v'] == ver) return db;

  await db.transaction((tx) async {
    for (final t in ['schedules', 'trains', 'stations']) { await tx.delete(t); }
    final b = tx.batch();
    for (final s in json['stations']) {
      b.insert('stations', {
        'station_id': s['station_id'], 'station_name': s['station_name'],
        'line_type': s['line_type'], 'station_code': s['station_code'],
        'platform_count': s['platform_count'] ?? 2});
    }
    for (final t in json['trains']) {
      b.insert('trains', {
        'train_id': t['train_id'], 'train_number': t['train_number'],
        'train_name': t['train_name'], 'source': t['source'],
        'destination': t['destination'], 'train_type': t['train_type'],
        'is_ac': t['is_ac'] == true ? 1 : 0,
        'is_ladies_special': t['is_ladies_special'] == true ? 1 : 0,
        'cars': t['cars']});
    }
    for (final s in json['schedules']) {
      b.insert('schedules', {
        'train_id': s['train_id'], 'station_id': s['station_id'],
        'arrival_time': _mins(s['arrival_time']), 'departure_time': _mins(s['departure_time']),
        'platform_number': s['platform_number'], 'halt_sequence': s['halt_sequence'],
        'distance_km': s['distance_km']});
    }
    b.insert('meta', {'k': 'data_version', 'v': ver},
        conflictAlgorithm: ConflictAlgorithm.replace);
    await b.commit(noResult: true);
  });
  return db;
}
