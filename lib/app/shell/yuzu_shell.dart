import 'package:flutter/material.dart';

import '../../domain/media/music_provider.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/search/search_screen.dart';

class YuzuShell extends StatefulWidget {
  const YuzuShell({super.key, required this.musicProvider});

  final MusicProvider musicProvider;

  @override
  State<YuzuShell> createState() => _YuzuShellState();
}

class _YuzuShellState extends State<YuzuShell> {
  static const _wideLayoutBreakpoint = 840.0;

  int _selectedIndex = 0;

  static const _navigationItems = [
    _NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavigationItem(
      label: 'Search',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search_rounded,
    ),
    _NavigationItem(
      label: 'Library',
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music_rounded,
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
      children: [
        HomeScreen(musicProvider: widget.musicProvider),
        SearchScreen(musicProvider: widget.musicProvider),
        const LibraryScreen(),
      ],
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
                for (final item in _navigationItems)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
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
          for (var index = 0; index < _navigationItems.length; index++)
            NavigationDestination(
              key: Key(
                'destination-${_navigationItems[index].label.toLowerCase()}',
              ),
              icon: Icon(_navigationItems[index].icon),
              selectedIcon: Icon(_navigationItems[index].selectedIcon),
              label: _navigationItems[index].label,
            ),
        ],
      ),
    );
  }
}

final class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
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
