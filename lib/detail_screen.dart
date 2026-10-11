import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'review_screen.dart';
import 'home_screen.dart' show scoreColor, scoreWord;

// Simple offline summary. Step 7 adds the Gemini AI summary on top of this.
String localSummary(Place p) {
  final avgs = <String, double>{};
  for (final k in criteria) {
    final a = p.criterionAvg(k);
    if (a != null) avgs[k] = a;
  }
  if (avgs.isEmpty) return 'No ratings yet. Be the first to review this place.';
  final sorted = avgs.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final best = sorted.first;
  final worst = sorted.last;
  final b = StringBuffer(
      'Reviewers rate ${criteriaLabels[best.key]!.toLowerCase()} highest (${best.value.toStringAsFixed(1)}/5)');
  if (sorted.length > 1) {
    b.write(
        ' and ${criteriaLabels[worst.key]!.toLowerCase()} lowest (${worst.value.toStringAsFixed(1)}/5)');
  }
  b.write('.');
  if (p.hasRecentBarrier) {
    b.write(' Warning: a lift or step-free barrier was reported recently.');
  }
  return b.toString();
}

String fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

class PlaceDetailScreen extends StatelessWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final place = store.byId(placeId);
    if (place == null) {
      return const Scaffold(body: Center(child: Text('Place not found')));
    }
    final profile = store.profile;
    final s = place.score(profile);
    final reviews = [...place.reviews]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReviewScreen(placeId: place.id)),
        ),
        icon: const Icon(Icons.rate_review),
        label: const Text('Add review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Barrier warning
          if (place.hasRecentBarrier)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recent barrier reported: a lift or step-free route was rated 1 star in the last 30 days.',
                      style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Score header
          Row(
            children: [
              Semantics(
                label: s == null
                    ? 'No accessibility score yet'
                    : 'Accessibility score ${s.round()} out of 100 for ${profile.label}, ${scoreWord(s)}',
                child: ExcludeSemantics(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: scoreColor(s),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s == null ? '-' : s.round().toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                        Text(scoreWord(s),
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score for ${profile.label}',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('${place.category} Â· ${place.address}'),
                    const SizedBox(height: 4),
                    Text('${place.confidence} Â· ${place.reviews.length} reviews',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Community summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome),
                      const SizedBox(width: 8),
                      Text('Community summary',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(localSummary(place)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Per-criterion bars
          Text('Ratings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final key in criteria) _CriterionRow(place: place, keyName: key, profile: profile),
          const SizedBox(height: 16),

          // Reviews
          Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (reviews.isEmpty) const Text('No reviews yet.'),
          for (final r in reviews)
            Card(
              child: ListTile(
                title: Text(r.comment.isEmpty ? '(no comment)' : r.comment),
                subtitle: Text(fmtDate(r.date)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final Place place;
  final String keyName;
  final Profile profile;
  const _CriterionRow(
      {required this.place, required this.keyName, required this.profile});

  @override
  Widget build(BuildContext context) {
    final avg = place.criterionAvg(keyName);
    final keyForYou = profile.weights[keyName] == 3;
    final label = criteriaLabels[keyName]!;

    return Semantics(
      label: avg == null
          ? '$label: no ratings'
          : '$label: ${avg.toStringAsFixed(1)} out of 5',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label)),
                  if (keyForYou)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Key for you', style: TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  Text(avg == null ? 'No ratings' : '${avg.toStringAsFixed(1)}/5'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: avg == null ? 0 : avg / 5,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                color: scoreColor(avg == null ? null : avg * 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

