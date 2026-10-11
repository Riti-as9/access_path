import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'detail_screen.dart';
import 'models.dart';
import 'store.dart';
import 'add_place_screen.dart';
import 'compare_screen.dart';
import 'extras.dart';
import 'ui_kit.dart';

// other files import these from here
export 'ui_kit.dart' show scoreColor, scoreWord;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final ex = context.watch<ExtrasStore>();
    final cs = Theme.of(context).colorScheme;
    final places =
    sortPlaces(store.visiblePlaces.toList(), ex.sortMode, store.profile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            tooltip: 'Compare two places',
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompareScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Sort and filter',
            icon: Badge(
              isLabelVisible: store.activeFilters.isNotEmpty,
              label: Text('${store.activeFilters.length}'),
              child: const Icon(Icons.tune),
            ),
            onPressed: () => showFilterSheet(context),
          ),
          IconButton(
            tooltip: 'Display settings',
            icon: const Icon(Icons.text_fields),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
        ),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add place'),
      ),
      body: !store.loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: store.setQuery,
              decoration: const InputDecoration(
                hintText: 'Search places or categories',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Score for',
                  style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final p in Profile.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(profileIcon(p.label), size: 18),
                      label: Text(p.label),
                      selected: store.profile == p,
                      onSelected: (_) => store.setProfile(p),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in filterLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(criterionIcon(e.value), size: 18),
                      label: Text(e.value),
                      selected: store.activeFilters.contains(e.key),
                      onSelected: (_) => store.toggleFilter(e.key),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${places.length} ${places.length == 1 ? "place" : "places"} \u00B7 ${ex.sortMode.label}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          Expanded(
            child: places.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off,
                      size: 56, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('No places match your filters'),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: places.length,
              itemBuilder: (context, i) => PlaceCard(
                index: i,
                place: places[i],
                profile: store.profile,
                section: 'explore',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  final Place place;
  final Profile profile;
  final int index;

  /// Which list the card is in; used to make the Hero tag unique.
  final String section;

  const PlaceCard({
    super.key,
    required this.place,
    required this.profile,
    required this.section,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final s = place.score(profile);
    final cs = Theme.of(context).colorScheme;
    final tag = '$section-${place.id}';

    return FadeSlideIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: cs.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: cs.outlineVariant.withAlpha(120)),
            ),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PlaceDetailScreen(placeId: place.id, heroTag: tag),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: tag,
                      child: Material(
                        type: MaterialType.transparency,
                        child: ScoreRing(score: s, size: 72, stroke: 7),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(categoryIcon(place.category),
                                  size: 15, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${place.category} \u00B7 ${place.address}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13, color: cs.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              InfoPill(
                                  icon: Icons.verified_outlined,
                                  text: place.confidence),
                              InfoPill(
                                  icon: Icons.chat_bubble_outline,
                                  text: '${place.reviews.length} reviews',
                                  color: cs.secondary),
                              FreshnessPill(place: place),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _CriteriaStrip(place: place),
                          if (place.hasRecentBarrier)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: InfoPill(
                                icon: Icons.warning_amber_rounded,
                                text: 'Recent barrier reported',
                                color: Color(0xFFC62828),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SavedHeart(placeId: place.id),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Five small icon badges, one per criterion, coloured by that rating.
class _CriteriaStrip extends StatelessWidget {
  final Place place;
  const _CriteriaStrip({required this.place});

  @override
  Widget build(BuildContext context) {
    final desc = criteria.map((k) {
      final a = place.criterionAvg(k);
      return '${criteriaLabels[k]} ${a == null ? "no ratings" : a.toStringAsFixed(1)}';
    }).join(', ');

    return Semantics(
      label: 'Ratings: $desc',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (final k in criteria)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Builder(builder: (context) {
                  final a = place.criterionAvg(k);
                  final c = scoreColor(a == null ? null : a * 20);
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.withAlpha(36),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(criterionIcon(criteriaLabels[k]!),
                        size: 17, color: c),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}