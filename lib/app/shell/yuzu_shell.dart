import 'package:flutter/material.dart';

class YuzuShell extends StatefulWidget {
  const YuzuShell({super.key});

  @override
  State<YuzuShell> createState() => _YuzuShellState();
}

class _YuzuShellState extends State<YuzuShell> {
  static const _wideLayoutBreakpoint = 840.0;

  int _selectedIndex = 0;

  static const _destinations = [
    _Destination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      child: _HomeDestination(),
    ),
    _Destination(
      label: 'Search',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search_rounded,
      child: _SearchDestination(),
    ),
    _Destination(
      label: 'Library',
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music_rounded,
      child: _LibraryDestination(),
    ),
  ];

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideLayoutBreakpoint;
    final content = IndexedStack(
      index: _selectedIndex,
      children: [for (final destination in _destinations) destination.child],
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 12),
                child: _YuzuMark(),
              ),
              destinations: [
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: [
          for (var index = 0; index < _destinations.length; index++)
            NavigationDestination(
              key: Key(
                'destination-${_destinations[index].label.toLowerCase()}',
              ),
              icon: Icon(_destinations[index].icon),
              selectedIcon: Icon(_destinations[index].selectedIcon),
              label: _destinations[index].label,
            ),
        ],
      ),
    );
  }
}

final class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
}

class _HomeDestination extends StatelessWidget {
  const _HomeDestination();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        const SliverAppBar.large(title: Text('Yuzu')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList.list(
            children: [
              Text(
                'Listen again',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.tertiaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 36,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'A fresh queue is waiting',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your first Yuzu listening session starts here.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchDestination extends StatelessWidget {
  const _SearchDestination();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('search-scroll'),
      slivers: [
        const SliverAppBar.large(title: Text('Search')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList.list(
            children: [
              const SearchBar(
                hintText: 'Songs, artists, albums',
                leading: Icon(Icons.search_rounded),
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.travel_explore_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Find your next favorite',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Search the Yuzu test catalog by song or artist.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LibraryDestination extends StatelessWidget {
  const _LibraryDestination();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('library-scroll'),
      slivers: [
        const SliverAppBar.large(title: Text('Library')),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_add_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Your library is quiet',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Saved music will live here when library support arrives.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _YuzuMark extends StatelessWidget {
  const _YuzuMark();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Yuzu',
      image: true,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.music_note_rounded,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
