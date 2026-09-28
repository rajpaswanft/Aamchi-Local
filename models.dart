class Station {
  final int id; final String name, line, code;
  Station(this.id, this.name, this.line, this.code);
  factory Station.fromRow(Map<String, Object?> r) => Station(
      r['station_id'] as int, r['station_name'] as String,
      r['line_type'] as String, r['station_code'] as String);
}

/// One search hit: a train covering from->to, with the times at those stops.
class TrainResult {
  final int trainId, dep, arr, cars; final int? platform;
  final String number, name, type; final bool ac, ladies;
  TrainResult(this.trainId, this.number, this.name, this.type, this.ac,
      this.ladies, this.cars, this.dep, this.arr, this.platform);
  int get durationMin => arr - dep;
  bool get isFast => type == 'FAST';
  factory TrainResult.fromRow(Map<String, Object?> r) => TrainResult(
      r['train_id'] as int, r['train_number'] as String, r['train_name'] as String,
      r['train_type'] as String, r['is_ac'] == 1, r['is_ladies_special'] == 1,
      r['cars'] as int, r['dep'] as int, r['arr'] as int, r['platform_number'] as int?);
}

String fmtTime(int m) {
  final h = (m ~/ 60) % 24, mm = m % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${mm.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}
