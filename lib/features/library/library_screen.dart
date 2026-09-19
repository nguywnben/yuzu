import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/local/local_library_database.dart';
import '../../domain/media/track.dart';
import '../shared/track_widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.onTrackSelected});

  final TrackSelectionCallback? onTrackSelected;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Track> _favorites = const [];
  List<Track> _history = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_loadLibraryData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibraryData() async {
    try {
      final db = await LocalLibraryDatabase.getInstance();
      final favs = await db.getFavorites();
      final hist = await db.getHistory();
      if (mounted) {
        setState(() {
          _favorites = favs;
          _history = hist;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Favorites (${_favorites.length})'),
            Tab(text: 'History (${_history.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrackList(
                  context,
                  tracks: _favorites,
                  emptyIcon: Icons.favorite_border,
                  emptyTitle: 'Your library is quiet',
                  emptyMessage:
                      'No favorites yet.\nHeart a track to add it here.',
                ),
                _buildTrackList(
                  context,
                  tracks: _history,
                  emptyIcon: Icons.history,
                  emptyTitle: 'No listening history',
                  emptyMessage: 'Play a track to get started.',
                ),
              ],
            ),
    );
  }

  Widget _buildTrackList(
    BuildContext context, {
    required List<Track> tracks,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLibraryData,
      child: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return TrackListTile(
            track: track,
            onTap: () => widget.onTrackSelected?.call(track, tracks),
          );
        },
      ),
    );
  }
}
