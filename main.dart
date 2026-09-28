import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/importer.dart';
import 'domain/search.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDb(); // offline: imports bundled JSON once
  runApp(ProviderScope(overrides: [repoProvider.overrideWithValue(Repo(db))], child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
      title: 'Mumbai Local', debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light), darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system, home: const HomeScreen());
}
