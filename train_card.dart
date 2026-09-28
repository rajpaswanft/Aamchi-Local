import 'package:flutter/material.dart';
import '../data/models.dart';
import '../domain/search.dart';
import 'theme.dart';

class TrainCard extends StatelessWidget {
  final TrainResult t; final VoidCallback onTap;
  const TrainCard(this.t, {required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final rush = estimateRush(t.dep);
    final rc = {Rush.low: Colors.green, Rush.moderate: Colors.orange, Rush.high: Colors.red}[rush]!;
    return Card(child: InkWell(
      borderRadius: BorderRadius.circular(20), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtTime(t.dep), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Expanded(child: Column(children: [
            Text('${t.durationMin} min', style: Theme.of(context).textTheme.labelMedium),
            const Divider(height: 8)])),
          const SizedBox(width: 10),
          Text(fmtTime(t.arr), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          t.isFast ? const Tag('F · FAST', AppColors.fast) : const Tag('S · SLOW', AppColors.slow),
          if (t.ac) const Tag('AC', AppColors.ac),
          if (t.ladies) const Tag('LADIES', AppColors.ladies),
          Tag('${t.cars}-CAR', Colors.blueGrey),
          if (t.platform != null) Tag('PF ${t.platform}', Colors.blueGrey),
          Tag('${rush.name.toUpperCase()} RUSH', rc),
        ]),
      ])),
    ));
  }
}
