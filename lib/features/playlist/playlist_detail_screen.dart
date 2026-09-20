import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/youtube_music/youtube_playlist_service.dart';
import '../../domain/media/search_result.dart';
import '../../domain/media/track.dart';
import '../shared/track_widgets.dart';

class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.item,
    required this.onTrackSelected,
  });

  final SearchResult item;
  final TrackSelectionCallback onTrackSelected;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final _service = YoutubePlaylistService();
  List<Track> _tracks = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTracks());
  }

  Future<void> _loadTracks() async {
    try {
      final tracks = await _service.fetchPlaylistTracks(widget.item.id);
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CatalogArtwork(
                          id: widget.item.id,
                          artworkUri: widget.item.artworkUri,
                          size: 120,
                          borderRadius: 16,
                          fallbackIcon: Icons.queue_music_rounded,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_tracks.length} tracks',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_tracks.isNotEmpty)
                                FilledButton.icon(
                                  onPressed: () => widget.onTrackSelected(
                                    _tracks.first,
                                    _tracks,
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Play all'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final track = _tracks[index];
                    return TrackListTile(
                      track: track,
                      onTap: () => widget.onTrackSelected(track, _tracks),
                    );
                  }, childCount: _tracks.length),
                ),
              ],
            ),
    );
  }
}
