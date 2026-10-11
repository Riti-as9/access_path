import 'detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';

Color scoreColor(double? s) {
  if (s == null) return Colors.grey.shade700;
  if (s >= 75) return const Color(0xFF2E7D32);
  if (s >= 50) return const Color(0xFFEF6C00);
  return const Color(0xFFC62828);
}

// A word next to the colour, so colour is never the only signal
String scoreWord(double? s) {
  if (s == null) return 'No data';
  if (s >= 75) return 'Good';
  if (s >= 50) return 'Fair';
  return 'Poor';
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final places = store.visiblePlaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AccessPath'),
        actions: [
          IconButton(
            tooltip: 'Toggle high contrast',
            icon: Icon(store.highContrast ? Icons.contrast : Icons.contrast_outlined),
            onPressed: () => store.setHighContrast(!store.highContrast),
          ),
        ],
      ),
      body: !store.loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              onChanged: store.setQuery,
              decoration: InputDecoration(
                hintText: 'Search places or categories',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                isDense: true,
              ),
            ),
          ),
          // Profile selector
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Score for:', style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final p in Profile.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.label),
                      selected: store.profile == p,
                      onSelected: (_) => store.setProfile(p),
                    ),
                  ),
              ],
            ),
          ),
          // Requirement filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final e in filterLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: store.activeFilters.contains(e.key),
                      onSelected: (_) => store.toggleFilter(e.key),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: places.isEmpty
                ? const Center(child: Text('No places match your filters'))
                : ListView.builder(
              itemCount: places.length,
              itemBuilder: (context, i) => PlaceCard(
                place: places[i],
                profile: store.profile,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaceDetailScreen(placeId: places[i].id),
                  ),
                ),
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
  final VoidCallback onTap;

  const PlaceCard({
    super.key,
    required this.place,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = place.score(profile);
    final scoreText = s == null ? '-' : s.round().toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Semantics(
                label: s == null
                    ? 'No accessibility score yet'
                    : 'Accessibility score $scoreText out of 100 for ${profile.label}, ${scoreWord(s)}',
                child: ExcludeSemantics(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: scoreColor(s),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(scoreText,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        Text(scoreWord(s),
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${place.category} · ${place.address}'),
                    const SizedBox(height: 4),
                    Text('${place.confidence} · ${place.reviews.length} reviews',
                        style: Theme.of(context).textTheme.bodySmall),
                    if (place.hasRecentBarrier)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 18, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text('Recent barrier reported',
                                  style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ],
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
