import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../domain/search.dart';
import 'train_card.dart';

final repoProvider = Provider<Repo>((_) => throw UnimplementedError()); // overridden in main()
final fromProv = StateProvider<Station?>((_) => null);
final toProv = StateProvider<Station?>((_) => null);
final filterProv = StateProvider<Filters>((_) => const Filters());

int nowMin() { final n = DateTime.now(); return n.hour * 60 + n.minute; }

final resultsProv = FutureProvider.autoDispose<List<TrainResult>>((ref) async {
  final a = ref.watch(fromProv), b = ref.watch(toProv);
  if (a == null || b == null) return [];
  return ref.read(repoProvider).direct(a.id, b.id, nowMin(), f: ref.watch(filterProv));
});

class StationField extends ConsumerWidget {
  final String label; final StateProvider<Station?> prov;
  const StationField(this.label, this.prov, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(prov);
    return Autocomplete<Station>(
      key: ValueKey('$label-${sel?.id}'), // rebuild text after swap
      initialValue: TextEditingValue(text: sel?.name ?? ''),
      displayStringForOption: (s) => s.name,
      optionsBuilder: (v) => v.text.isEmpty
          ? const Iterable<Station>.empty() : ref.read(repoProvider).searchStations(v.text),
      onSelected: (s) => ref.read(prov.notifier).state = s,
      fieldViewBuilder: (c, ctrl, focus, _) => TextField(controller: ctrl, focusNode: focus,
          decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.train))),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(resultsProv);
    final f = ref.watch(filterProv);
    void setF(Filters n) => ref.read(filterProv.notifier).state = n;
    return Scaffold(
      appBar: AppBar(title: const Text('Mumbai Local', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          const Expanded(child: Column(children: [
            StationField('From', fromProv), SizedBox(height: 10), StationField('To', toProv)])),
          IconButton.filledTonal(iconSize: 28, icon: const Icon(Icons.swap_vert), onPressed: () {
            final a = ref.read(fromProv), b = ref.read(toProv);
            ref.read(fromProv.notifier).state = b; ref.read(toProv.notifier).state = a;
          }),
        ]))),
        const SizedBox(height: 12),
        SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [
          _chip('Fast only', f.fastOnly, () => setF(f.copy(fast: !f.fastOnly))),
          _chip('AC only', f.acOnly, () => setF(f.copy(ac: !f.acOnly))),
          _chip('Ladies', f.ladiesOnly, () => setF(f.copy(ladies: !f.ladiesOnly))),
          _chip('Peak', f.peakOnly, () => setF(f.copy(peak: !f.peakOnly))),
        ])),
        const SizedBox(height: 12),
        results.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Something went wrong: $e'),
          data: (list) => list.isEmpty
              ? const Padding(padding: EdgeInsets.all(32),
                  child: Center(child: Text('Pick two stations to see trains')))
              : Column(children: [for (final t in list) Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TrainCard(t, onTap: () {/* push RouteTimelineScreen(t.trainId) */}))]),
        ),
      ]),
    );
  }

  Widget _chip(String l, bool on, VoidCallback tap) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(label: Text(l), selected: on, onSelected: (_) => tap()));
}
