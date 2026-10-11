import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'ui_kit.dart';

// ====================== Sorting ======================
enum SortMode { bestForMe, mostReviewed, recentlyUpdated }

extension SortModeX on SortMode {
  String get label {
    switch (this) {
      case SortMode.bestForMe:
        return 'Best for me';
      case SortMode.mostReviewed:
        return 'Most reviewed';
      case SortMode.recentlyUpdated:
        return 'Recently updated';
    }
  }

  IconData get icon {
    switch (this) {
      case SortMode.bestForMe:
        return Icons.star_rounded;
      case SortMode.mostReviewed:
        return Icons.forum_outlined;
      case SortMode.recentlyUpdated:
        return Icons.update;
    }
  }
}

DateTime? latestReview(Place p) {
  DateTime? latest;
  for (final r in p.reviews) {
    if (latest == null || r.date.isAfter(latest)) latest = r.date;
  }
  return latest;
}

List<Place> sortPlaces(List<Place> input, SortMode mode, Profile profile) {
  final list = [...input];
  switch (mode) {
    case SortMode.bestForMe:
      list.sort((a, b) {
        final sa = a.score(profile);
        final sb = b.score(profile);
        if (sa == null && sb == null) return 0;
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sb.compareTo(sa);
      });
      break;
    case SortMode.mostReviewed:
      list.sort((a, b) => b.reviews.length.compareTo(a.reviews.length));
      break;
    case SortMode.recentlyUpdated:
      list.sort((a, b) {
        final da = latestReview(a);
        final db = latestReview(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
      break;
  }
  return list;
}

String? freshnessLabel(Place p) {
  final d = latestReview(p);
  if (d == null) return null;
  final days = DateTime.now().difference(d).inDays;
  if (days <= 0) return 'Verified today';
  if (days == 1) return 'Verified yesterday';
  if (days < 60) return 'Verified $days days ago';
  return 'Verified ${(days / 30).floor()} months ago';
}

// ====================== Extra app state ======================
// Kept separate from AppStore so store.dart does not need changes.
// In memory only: resets when the app is restarted.
class ExtrasStore extends ChangeNotifier {
  final Set<String> _saved = {};
  SortMode sortMode = SortMode.bestForMe;
  double textScale = 1.0;
  bool easyReading = false;
  bool onboardingShown = false;

  bool isSaved(String id) => _saved.contains(id);
  List<String> get savedIds => _saved.toList();

  void toggleSaved(String id) {
    if (!_saved.remove(id)) _saved.add(id);
    notifyListeners();
  }

  void setSort(SortMode m) {
    sortMode = m;
    notifyListeners();
  }

  void setTextScale(double v) {
    textScale = v;
    notifyListeners();
  }

  void setEasyReading(bool v) {
    easyReading = v;
    notifyListeners();
  }

  void markOnboardingShown() => onboardingShown = true;
}

// ====================== Read aloud ======================
class Speaker {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.45);
      await _tts.setLanguage('en-IN');
    } catch (e) {
      debugPrint('TTS init: $e');
    }
    _ready = true;
  }

  /// Returns false if speech is not available on this device.
  static Future<bool> speak(String text) async {
    try {
      await _init();
      await _tts.stop();
      await _tts.speak(text);
      return true;
    } catch (e) {
      debugPrint('TTS failed: $e');
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

// ====================== Small widgets ======================
class SavedHeart extends StatelessWidget {
  final String placeId;
  const SavedHeart({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    final ex = context.watch<ExtrasStore>();
    final saved = ex.isSaved(placeId);
    return IconButton(
      tooltip: saved ? 'Remove from saved places' : 'Save this place',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: () => ex.toggleSaved(placeId),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: Icon(
          saved ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(saved),
          color: saved ? Colors.red.shade400 : null,
        ),
      ),
    );
  }
}

class FreshnessPill extends StatelessWidget {
  final Place place;
  const FreshnessPill({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final label = freshnessLabel(place);
    if (label == null) return const SizedBox.shrink();
    return InfoPill(
      icon: Icons.update,
      text: label,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }
}

/// Bounces its child whenever [value] changes (e.g. the score after a review).
class PulseOnChange extends StatefulWidget {
  final Object? value;
  final Widget child;
  const PulseOnChange({super.key, required this.value, required this.child});

  @override
  State<PulseOnChange> createState() => _PulseOnChangeState();
}

class _PulseOnChangeState extends State<PulseOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void didUpdateWidget(PulseOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.18 * math.sin(_c.value * math.pi),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Shimmering placeholder lines shown while the AI summary loads.
class SummarySkeleton extends StatefulWidget {
  const SummarySkeleton({super.key});

  @override
  State<SummarySkeleton> createState() => _SummarySkeletonState();
}

class _SummarySkeletonState extends State<SummarySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.onSurface.withAlpha(22);
    final glow = cs.onSurface.withAlpha(60);

    Widget bar(double w) => FractionallySizedBox(
      widthFactor: w,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 13,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          gradient: LinearGradient(
            begin: Alignment(-1.6 + 3.2 * _c.value, 0),
            end: Alignment(-0.6 + 3.2 * _c.value, 0),
            colors: [base, glow, base],
          ),
        ),
      ),
    );

    return Semantics(
      label: 'Summarising community feedback',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Column(
            children: [
              bar(1),
              const SizedBox(height: 10),
              bar(0.92),
              const SizedBox(height: 10),
              bar(0.64),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== Radar chart ======================
class RadarChart extends StatelessWidget {
  final Place place;
  const RadarChart({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labels =
    criteria.map((k) => criteriaLabels[k]!.split(' ').first).toList();
    final values = criteria.map((k) => (place.criterionAvg(k) ?? 0) / 5).toList();
    final desc = criteria.map((k) {
      final a = place.criterionAvg(k);
      return '${criteriaLabels[k]} ${a == null ? "no ratings" : a.toStringAsFixed(1)}';
    }).join(', ');

    return Semantics(
      label: 'Radar chart of ratings out of 5: $desc',
      child: ExcludeSemantics(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              size: const Size(280, 260),
              painter: _RadarPainter(
                values: values,
                labels: labels,
                t: t,
                accent: cs.primary,
                grid: cs.outlineVariant,
                text: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double t;
  final Color accent, grid, text;
  _RadarPainter({
    required this.values,
    required this.labels,
    required this.t,
    required this.accent,
    required this.grid,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 3) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 34;

    Offset point(int i, double r) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      return center + Offset(math.cos(a) * r, math.sin(a) * r);
    }

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = grid;

    for (var level = 1; level <= 5; level++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = point(i, radius * level / 5);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, point(i, radius), gridPaint);
    }

    final data = Path();
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0).toDouble();
      final p = point(i, radius * v * t);
      pts.add(p);
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    data.close();
    canvas.drawPath(
        data,
        Paint()
          ..style = PaintingStyle.fill
          ..color = accent.withAlpha(70));
    canvas.drawPath(
        data,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..color = accent);
    for (final p in pts) {
      canvas.drawCircle(p, 4, Paint()..color = accent);
    }

    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: text),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final lp = point(i, radius + 20);
      tp.paint(canvas, lp - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.t != t || old.values != values;
}

// ====================== Bottom sheets ======================
void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final ex = context.watch<ExtrasStore>();
    final store = context.watch<AppStore>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display & reading',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.text_fields),
                const SizedBox(width: 8),
                Text('Text size: ${(ex.textScale * 100).round()}%'),
              ],
            ),
            Slider(
              value: ex.textScale,
              min: 0.9,
              max: 1.6,
              divisions: 7,
              label: '${(ex.textScale * 100).round()}%',
              onChanged: ex.setTextScale,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Easy-reading mode'),
              subtitle: const Text(
                  'Wider letter, word and line spacing for dyslexia and low vision'),
              value: ex.easyReading,
              onChanged: ex.setEasyReading,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark / high contrast'),
              value: store.highContrast,
              onChanged: (v) => store.setHighContrast(v),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                  'Preview: Step-free entrance on the east side. Lift reaches all floors.'),
            ),
          ],
        ),
      ),
    );
  }
}

void showFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final ex = context.watch<ExtrasStore>();
    final count = store.visiblePlaces.length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort & filter',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SectionTitle('Sort by', icon: Icons.sort),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in SortMode.values)
                  ChoiceChip(
                    avatar: Icon(m.icon, size: 18),
                    label: Text(m.label),
                    selected: ex.sortMode == m,
                    onSelected: (_) => ex.setSort(m),
                  ),
              ],
            ),
            const SectionTitle('Must have', icon: Icons.filter_alt_outlined),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in filterLabels.entries)
                  FilterChip(
                    avatar: Icon(criterionIcon(e.value), size: 18),
                    label: Text(e.value),
                    selected: store.activeFilters.contains(e.key),
                    onSelected: (_) => store.toggleFilter(e.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    for (final k in store.activeFilters.toList()) {
                      store.toggleFilter(k);
                    }
                  },
                  child: const Text('Clear filters'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Show $count ${count == 1 ? "place" : "places"}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== Onboarding ======================
Future<void> showOnboarding(BuildContext context) async {
  final ex = context.read<ExtrasStore>();
  if (ex.onboardingShown) return;
  ex.markOnboardingShown();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _OnboardingSheet(),
  );
}

class _OnboardingSheet extends StatelessWidget {
  const _OnboardingSheet();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.accessible_forward,
                  size: 34, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text('Welcome to AccessPath',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Tell us what matters to you. Every place will be scored for your needs.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final p in Profile.values)
                  ChoiceChip(
                    avatar: Icon(profileIcon(p.label), size: 18),
                    label: Text(p.label),
                    selected: store.profile == p,
                    onSelected: (_) => store.setProfile(p),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}