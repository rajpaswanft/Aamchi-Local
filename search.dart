import 'package:sqflite/sqflite.dart';
import '../data/models.dart';

class Filters {
  final bool fastOnly, acOnly, ladiesOnly, peakOnly;
  const Filters({this.fastOnly = false, this.acOnly = false,
      this.ladiesOnly = false, this.peakOnly = false});
  Filters copy({bool? fast, bool? ac, bool? ladies, bool? peak}) => Filters(
      fastOnly: fast ?? fastOnly, acOnly: ac ?? acOnly,
      ladiesOnly: ladies ?? ladiesOnly, peakOnly: peak ?? peakOnly);
}

class Repo {
  final Database db; Repo(this.db);

  Future<List<Station>> searchStations(String q) async =>
      (await db.query('stations', where: 'station_name LIKE ? OR station_code LIKE ?',
          whereArgs: ['%$q%', '$q%'], limit: 8)).map(Station.fromRow).toList();

  /// Direct trains from->to departing at/after [after], soonest first.
  /// "from stops before to" on the same train = halt_sequence ordering.
  Future<List<TrainResult>> direct(int from, int to, int after,
      {Filters f = const Filters(), int limit = 50}) async {
    final w = <String>[];
    if (f.fastOnly) w.add("t.train_type='FAST'");
    if (f.acOnly) w.add('t.is_ac=1');
    if (f.ladiesOnly) w.add('t.is_ladies_special=1');
    if (f.peakOnly) w.add('((a.departure_time BETWEEN 480 AND 660) OR (a.departure_time BETWEEN 1020 AND 1260))');
    final rows = await db.rawQuery('''
      SELECT t.*, a.departure_time AS dep, b.arrival_time AS arr, a.platform_number
      FROM schedules a JOIN schedules b
        ON a.train_id=b.train_id AND a.halt_sequence<b.halt_sequence
      JOIN trains t ON t.train_id=a.train_id
      WHERE a.station_id=? AND b.station_id=? AND a.departure_time>=?
        ${w.isEmpty ? '' : 'AND ${w.join(' AND ')}'}
      ORDER BY a.departure_time LIMIT ?''', [from, to, after, limit]);
    return rows.map(TrainResult.fromRow).toList();
  }

  /// First / last train of the day for a pair (quick-lookup chips).
  Future<TrainResult?> firstLast(int from, int to, {required bool last}) async {
    final r = await direct(from, to, 0, limit: 500);
    if (r.isEmpty) return null;
    return last ? r.last : r.first;
  }

  /// One-change suggestions when direct() is empty: from->X, then X->to
  /// with a >=3 min buffer. Candidate X = stations reachable from `from`
  /// that also reach `to` on another train.
  Future<List<(TrainResult, Station, TrainResult)>> connecting(
      int from, int to, int after) async {
    final rows = await db.rawQuery('''
      SELECT DISTINCT x1.station_id AS x FROM schedules s1
      JOIN schedules x1 ON x1.train_id=s1.train_id AND x1.halt_sequence>s1.halt_sequence
      JOIN schedules x2 ON x2.station_id=x1.station_id
      JOIN schedules s2 ON s2.train_id=x2.train_id AND s2.halt_sequence>x2.halt_sequence
      WHERE s1.station_id=? AND s2.station_id=? LIMIT 6''', [from, to]);
    final out = <(TrainResult, Station, TrainResult)>[];
    for (final r in rows) {
      final x = r['x'] as int;
      final st = Station.fromRow((await db.query('stations', where: 'station_id=?', whereArgs: [x])).first);
      for (final a in await direct(from, x, after, limit: 2)) {
        final b = await direct(x, to, a.arr + 3, limit: 1);
        if (b.isNotEmpty) out.add((a, st, b.first));
      }
    }
    out.sort((p, q) => p.$3.arr.compareTo(q.$3.arr));
    return out.take(3).toList();
  }

  /// Live board: next departures through a station. Direction (Up/Down)
  /// can be derived by comparing the train's halt_sequence order to the
  /// line's canonical direction, or stored as `direction` in the JSON.
  Future<List<Map<String, Object?>>> board(int station, int now, {int limit = 10}) =>
      db.rawQuery('''
        SELECT t.train_number, t.train_type, t.is_ac, t.cars, s.departure_time AS dep,
               s.platform_number, d.station_name AS toward
        FROM schedules s JOIN trains t ON t.train_id=s.train_id
        JOIN stations d ON d.station_id=t.destination
        WHERE s.station_id=? AND s.departure_time>=? ORDER BY s.departure_time LIMIT ?''',
          [station, now, limit]);
}

enum Rush { low, moderate, high }

/// Time-of-day baseline until crowdsourced votes exist; blend votes in later.
Rush estimateRush(int depMin) {
  final m = depMin % 1440;
  if ((m >= 480 && m <= 660) || (m >= 1050 && m <= 1230)) return Rush.high;
  if ((m >= 420 && m < 480) || (m > 660 && m <= 720) || (m > 1230 && m <= 1290)) return Rush.moderate;
  return Rush.low;
}

/// "Arriving in 3 mins" style label for the live board.
String eta(int dep, int now) {
  final d = dep - now;
  return d <= 1 ? 'Arriving now' : d <= 5 ? 'Arriving in $d mins' : 'Next in $d mins';
}
