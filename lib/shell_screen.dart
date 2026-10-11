import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'extras.dart';
import 'home_screen.dart';
import 'models.dart';
import 'saved_screen.dart';
import 'store.dart';
import 'ui_kit.dart';

/// Bottom-navigation shell: Home, Explore, Saved.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showOnboarding(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedCount = context.watch<ExtrasStore>().savedIds.length;

    final behavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      },
    );

    return ScrollConfiguration(
      behavior: behavior,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeTab(onGoExplore: () => setState(() => _index = 1)),
            const HomeScreen(),
            const SavedScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: savedCount > 0,
                label: Text('$savedCount'),
                child: const Icon(Icons.favorite_border),
              ),
              selectedIcon: Badge(
                isLabelVisible: savedCount > 0,
                label: Text('$savedCount'),
                child: const Icon(Icons.favorite),
              ),
              label: 'Saved',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final VoidCallback onGoExplore;
  const HomeTab({super.key, required this.onGoExplore});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final theme = Theme.of(context);

    if (!store.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final places = store.visiblePlaces.toList();
    final profile = store.profile;
    final top =
    sortPlaces(places, SortMode.bestForMe, profile).take(3).toList();
    final barriers = places.where((p) => p.hasRecentBarrier).take(3).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
              ),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.accessible_forward,
                        color: theme.colorScheme.onPrimary, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AccessPath',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Display settings',
                      color: theme.colorScheme.onPrimary,
                      icon: const Icon(Icons.text_fields),
                      onPressed: () => showSettingsSheet(context),
                    ),
                    IconButton(
                      tooltip: 'Toggle dark mode',
                      color: theme.colorScheme.onPrimary,
                      icon: Icon(store.highContrast
                          ? Icons.light_mode
                          : Icons.dark_mode),
                      onPressed: () =>
                          store.setHighContrast(!store.highContrast),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Find places that work for you',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Community-rated access info: step-free entry, lifts, '
                      'washrooms, seating and wayfinding.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withAlpha(230),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: 'Search places',
                  child: InkWell(
                    onTap: onGoExplore,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search),
                          const SizedBox(width: 12),
                          Text('Search places or categories',
                              style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        _sectionTitle(context, 'Your needs'),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final p in Profile.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(profileIcon(p.label), size: 18),
                      label: Text(p.label),
                      selected: profile == p,
                      onSelected: (_) => store.setProfile(p),
                    ),
                  ),
              ],
            ),
          ),
        ),

        _sectionTitle(context, 'I need...'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in filterLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _NeedCard(
                      icon: criterionIcon(e.value),
                      label: e.value,
                      active: store.activeFilters.contains(e.key),
                      onTap: () {
                        if (!store.activeFilters.contains(e.key)) {
                          store.toggleFilter(e.key);
                        }
                        onGoExplore();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        _sectionTitle(context, 'Top rated for ${profile.label}'),
        if (top.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No places match your filters yet.'),
            ),
          )
        else
          SliverList.builder(
            itemCount: top.length,
            itemBuilder: (context, i) => PlaceCard(
              index: i,
              place: top[i],
              profile: profile,
              section: 'home-top',
            ),
          ),

        if (barriers.isNotEmpty) ...[
          _sectionTitle(context, 'Heads up: recent barriers reported'),
          SliverList.builder(
            itemCount: barriers.length,
            itemBuilder: (context, i) => PlaceCard(
              index: i,
              place: barriers[i],
              profile: profile,
              section: 'home-barrier',
            ),
          ),
        ],

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onGoExplore,
              icon: const Icon(Icons.explore),
              label: const Text('Explore all places'),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  SliverToBoxAdapter _sectionTitle(BuildContext context, String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NeedCard({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: active,
      label: 'Filter places: $label',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 112,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: cs.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}