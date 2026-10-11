import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'ui_kit.dart';

class CompareScreen extends StatefulWidget {
  final String? initialAId;
  const CompareScreen({super.key, this.initialAId});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String? _a;
  String? _b;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final cs = Theme.of(context).colorScheme;
    final profile = store.profile;
    final places = store.visiblePlaces.toList();

    if (places.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare places')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
                'You need at least two places (clear your filters) to compare.',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (_a == null || !places.any((p) => p.id == _a)) {
      _a = (widget.initialAId != null &&
          places.any((p) => p.id == widget.initialAId))
          ? widget.initialAId
          : places.first.id;
    }
    if (_b == null || !places.any((p) => p.id == _b) || _b == _a) {
      _b = places.firstWhere((p) => p.id != _a).id;
    }

    final a = store.byId(_a!)!;
    final b = store.byId(_b!)!;

    var winsA = 0, winsB = 0;
    for (final k in criteria) {
      final x = a.criterionAvg(k);
      final y = b.criterionAvg(k);
      if (x != null && y != null) {
        if (x > y) winsA++;
        if (y > x) winsB++;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Compare places')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Row(
            children: [
              Expanded(child: _picker('Place A', _a!, places, (v) => setState(() => _a = v))),
              const SizedBox(width: 12),
              Expanded(child: _picker('Place B', _b!, places, (v) => setState(() => _b = v))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _header(context, a, profile)),
              Text('VS',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: cs.onSurfaceVariant)),
              Expanded(child: _header(context, b, profile)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(120),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${a.name} rates higher in $winsA of ${criteria.length} categories; '
                  '${b.name} in $winsB. Scores are weighted for ${profile.label}.',
            ),
          ),
          const SizedBox(height: 12),
          _row(context,
              icon: Icons.speed,
              label: 'Overall',
              a: a.score(profile),
              b: b.score(profile),
              fmt: (v) => '${v.round()}/100'),
          for (final k in criteria)
            _row(context,
                icon: criterionIcon(criteriaLabels[k]!),
                label: criteriaLabels[k]!,
                a: a.criterionAvg(k),
                b: b.criterionAvg(k),
                fmt: (v) => '${v.toStringAsFixed(1)}/5'),
        ],
      ),
    );
  }

  Widget _picker(String label, String value, List<Place> places,
      ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final p in places)
          DropdownMenuItem(
              value: p.id,
              child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _header(BuildContext context, Place p, Profile profile) {
    return Column(
      children: [
        ScoreRing(score: p.score(profile), size: 84, stroke: 8),
        const SizedBox(height: 8),
        Text(p.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _row(BuildContext context,
      {required IconData icon,
        required String label,
        required double? a,
        required double? b,
        required String Function(double) fmt}) {
    final cs = Theme.of(context).colorScheme;
    final aWin = a != null && b != null && a > b;
    final bWin = a != null && b != null && b > a;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: _cell(context, a == null ? 'No data' : fmt(a), aWin)),
          SizedBox(
            width: 84,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: cs.primary),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          Expanded(child: _cell(context, b == null ? 'No data' : fmt(b), bWin)),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, String text, bool win) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: win ? cs.primaryContainer : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: win ? cs.primary : cs.outlineVariant.withAlpha(120)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (win) ...[
            Icon(Icons.check_circle, size: 16, color: cs.primary),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontWeight: win ? FontWeight.w800 : FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}