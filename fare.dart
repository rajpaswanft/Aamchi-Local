/// Fare slabs are CONFIG, not hard-coded truth: load them from the JSON
/// (`fares` key) so they can be updated when Railways revise the chart.
/// Values below are PLACEHOLDERS (0) - fill from the official fare chart.
class FareSlab {
  final double uptoKm; final int second, first, ac;
  const FareSlab(this.uptoKm, this.second, this.first, this.ac);
}

const placeholderSlabs = [
  FareSlab(10, 0, 0, 0), FareSlab(20, 0, 0, 0), FareSlab(40, 0, 0, 0),
  FareSlab(80, 0, 0, 0), FareSlab(999, 0, 0, 0),
];

enum Cls { second, first, ac }

int singleFare(double km, Cls c, [List<FareSlab> slabs = placeholderSlabs]) {
  final s = slabs.firstWhere((s) => km <= s.uptoKm, orElse: () => slabs.last);
  return switch (c) { Cls.second => s.second, Cls.first => s.first, Cls.ac => s.ac };
}

/// Pass multipliers are config too; keep them beside the slabs.
int passFare(int single, {required bool quarterly, double monthlyMult = 15, double quarterMult = 40}) =>
    (single * (quarterly ? quarterMult : monthlyMult)).round();
