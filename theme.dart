import 'package:flutter/material.dart';

class AppColors {
  static const western = Color(0xFFD32F2F), central = Color(0xFF8B0000),
      harbour = Color(0xFF1976D2), transHarbour = Color(0xFF388E3C);
  static const fast = Color(0xFFFF5722), slow = Color(0xFF66BB6A),
      ac = Color(0xFF2979FF), ladies = Color(0xFFEC407A);
  static Color line(String l) => switch (l) {
    'WESTERN' => western, 'CENTRAL' => central,
    'HARBOUR' => harbour, _ => transHarbour };
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.western, brightness: b),
    scaffoldBackgroundColor: dark ? const Color(0xFF0F1115) : const Color(0xFFF6F7F9),
    cardTheme: CardTheme(elevation: 0, margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF1A1D23) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    inputDecorationTheme: InputDecorationTheme(filled: true, border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
  );
}

class Tag extends StatelessWidget {
  final String text; final Color color;
  const Tag(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)));
}
