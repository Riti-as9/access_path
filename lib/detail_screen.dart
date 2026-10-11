import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'ai_summary.dart';
import 'review_screen.dart';
import 'compare_screen.dart';
import 'extras.dart';
import 'ui_kit.dart';

// Simple offline summary, used when the Gemini call is unavailable.
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

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;
  final Color? borderColor;
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? cs.outlineVariant.withAlpha(120)),
      ),
      child: child,
    );
  }
}

class PlaceDetailScreen extends StatelessWidget {
  final String placeId;
  final String? heroTag;
  const PlaceDetailScreen({super.key, required this.placeId, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final place = store.byId(placeId);
    if (place == null) {
      return const Scaffold(body: Center(child: Text('Place not found')));
    }
    final profile = store.profile;
    final s = place.score(profile);
    final sc = scoreColor(s);
    final cs = Theme.of(context).colorScheme;
    final reviews = [...place.reviews]
      ..sort((a, b) => b.date.compareTo(a.date));

    Widget ring = PulseOnChange(
      value: s?.round(),
      child: ScoreRing(score: s, size: 104, stroke: 10),
    );
    if (heroTag != null) {
      ring = Hero(
        tag: heroTag!,
        child: Material(type: MaterialType.transparency, child: ring),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        actions: [SavedHeart(placeId: place.id)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReviewScreen(placeId: place.id)),
        ),
        icon: const Icon(Icons.rate_review),
        label: const Text('Add review'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          // ---- Score header ----
          FadeSlideIn(
            child: _Panel(
              padding: const EdgeInsets.all(18),
              borderColor: sc.withAlpha(90),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [sc.withAlpha(46), cs.surface],
              ),
              child: Row(
                children: [
                  ring,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(categoryIcon(place.category),
                                size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${place.category} \u00B7 ${place.address}',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            InfoPill(
                                icon: profileIcon(profile.label),
                                text: 'For ${profile.label}'),
                            InfoPill(
                                icon: Icons.verified_outlined,
                                text:
                                '${place.confidence} \u00B7 ${place.reviews.length} reviews',
                                color: cs.secondary),
                            FreshnessPill(place: place),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Barrier warning ----
          if (place.hasRecentBarrier)
            FadeSlideIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _Panel(
                  padding: const EdgeInsets.all(14),
                  borderColor: Colors.red.shade300,
                  gradient: LinearGradient(
                    colors: [Colors.red.withAlpha(30), cs.surface],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red.shade700, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Recent barrier reported: a lift or step-free route was rated 1 star in the last 30 days.',
                          style: TextStyle(
                              color: cs.onSurface, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ---- Community summary (AI) ----
          const SectionTitle('Community summary', icon: Icons.auto_awesome),
          FadeSlideIn(
            index: 2,
            child: _Panel(
              borderColor: cs.primary.withAlpha(90),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primaryContainer.withAlpha(110), cs.surface],
              ),
              child: SummaryBody(
                  place: place, fallback: localSummary(place), profile: profile),
            ),
          ),

          // ---- Why this score ----
          const SizedBox(height: 12),
          FadeSlideIn(index: 3, child: _WhyScore(profile: profile)),

          // ---- Radar chart ----
          const SectionTitle('At a glance', icon: Icons.radar),
          FadeSlideIn(
            index: 4,
            child: _Panel(child: RadarChart(place: place)),
          ),

          // ---- Ratings ----
          const SectionTitle('Ratings', icon: Icons.bar_chart_rounded),
          FadeSlideIn(
            index: 5,
            child: _Panel(
              child: Column(
                children: [
                  for (final key in criteria)
                    _CriterionRow(
                        place: place, keyName: key, profile: profile),
                ],
              ),
            ),
          ),

          // ---- Compare ----
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CompareScreen(initialAId: place.id)),
            ),
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Compare with another place'),
          ),

          // ---- Reviews ----
          const SectionTitle('Reviews', icon: Icons.forum_outlined),
          if (reviews.isEmpty)
            const _Panel(child: Text('No reviews yet. Be the first!')),
          for (var j = 0; j < reviews.length; j++)
            FadeSlideIn(
              index: j,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Panel(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.person_outline,
                            size: 20, color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reviews[j].comment.isEmpty
                                ? '(no comment)'
                                : reviews[j].comment),
                            const SizedBox(height: 4),
                            Text(fmtDate(reviews[j].date),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WhyScore extends StatelessWidget {
  final Profile profile;
  const _WhyScore({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ordered = [...criteria]
      ..sort((a, b) =>
          (profile.weights[b] ?? 0).compareTo(profile.weights[a] ?? 0));
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withAlpha(120)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(Icons.help_outline, color: cs.primary),
          title: Text('Why this score for ${profile.label}?',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Each category counts more or less depending on what '
                '${profile.label.toLowerCase()} users need most. '
                'The multiplier shows its weight:'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final k in ordered)
                  InfoPill(
                    icon: criterionIcon(criteriaLabels[k]!),
                    text: '${criteriaLabels[k]} x${profile.weights[k] ?? 0}',
                  ),
              ],
            ),
          ],
        ),
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
    final c = scoreColor(avg == null ? null : avg * 20);
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: avg == null
          ? '$label: no ratings'
          : '$label: ${avg.toStringAsFixed(1)} out of 5',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.withAlpha(36),
                  shape: BoxShape.circle,
                ),
                child: Icon(criterionIcon(label), color: c, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (keyForYou)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InfoPill(
                                icon: Icons.star_rounded,
                                text: 'Key for you',
                                color: cs.tertiary),
                          ),
                        Text(
                          avg == null ? 'No ratings' : '${avg.toStringAsFixed(1)}/5',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: c),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: avg == null ? 0 : avg / 5),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: c.withAlpha(36),
                          color: c,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}