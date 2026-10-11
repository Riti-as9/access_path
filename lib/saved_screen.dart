import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'extras.dart';
import 'home_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final ex = context.watch<ExtrasStore>();
    final cs = Theme.of(context).colorScheme;
    final places = ex.savedIds
        .map((id) => store.byId(id))
        .whereType<Place>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      body: places.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border,
                  size: 64, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              const Text(
                'No saved places yet.\nTap the heart on any place to keep it here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: places.length,
        itemBuilder: (context, i) => PlaceCard(
          index: i,
          place: places[i],
          profile: store.profile,
          section: 'saved',
        ),
      ),
    );
  }
}
