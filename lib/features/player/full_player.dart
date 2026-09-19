import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/local/local_library_database.dart';
import '../lyrics/lyrics_provider.dart';
import '../shared/track_widgets.dart';
import 'playback_controller.dart';

class FullPlayer extends StatefulWidget {
  const FullPlayer({super.key, required this.controller});

  final PlaybackController controller;

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  bool _isFavorite = false;
  bool _showLyrics = false;
  SyncedLyrics? _lyrics;
  bool _isLoadingLyrics = false;
  String? _lastLoadedTrackId;

  @override
  void initState() {
    super.initState();
    unawaited(_checkFavorite());
  }

  @override
  void didUpdateWidget(covariant FullPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.currentTrack?.id !=
        oldWidget.controller.currentTrack?.id) {
      unawaited(_checkFavorite());
      if (_showLyrics) {
        unawaited(_loadLyrics());
      }
    }
  }

  Future<void> _checkFavorite() async {
    final track = widget.controller.currentTrack;
    if (track == null) return;
    try {
      final db = await LocalLibraryDatabase.getInstance();
      final fav = await db.isFavorite(track.id);
      if (mounted) {
        setState(() => _isFavorite = fav);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final track = widget.controller.currentTrack;
    if (track == null) return;
    try {
      final db = await LocalLibraryDatabase.getInstance();
      if (_isFavorite) {
        await db.removeFavorite(track.id);
        if (mounted) setState(() => _isFavorite = false);
      } else {
        await db.addFavorite(track);
        if (mounted) setState(() => _isFavorite = true);
      }
    } catch (_) {}
  }

  Future<void> _loadLyrics() async {
    final track = widget.controller.currentTrack;
    if (track == null || track.id == _lastLoadedTrackId) return;

    setState(() {
      _isLoadingLyrics = true;
      _lastLoadedTrackId = track.id;
    });

    final provider = LrcLibLyricsProvider();
    final res = await provider.fetchLyrics(
      trackName: track.title,
      artistName: track.artists.firstOrNull ?? '',
      duration: track.duration,
    );

    if (mounted) {
      setState(() {
        _lyrics = res;
        _isLoadingLyrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final track = widget.controller.currentTrack;
        if (track == null) {
          return const SizedBox.shrink();
        }

        final index = widget.controller.queue.currentIndex ?? 0;
        final theme = Theme.of(context);

        return FractionallySizedBox(
          heightFactor: 0.94,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close player',
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Now playing',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showLyrics = !_showLyrics;
                          if (_showLyrics && _lyrics == null) {
                            unawaited(_loadLyrics());
                          }
                        });
                      },
                      tooltip: 'Lyrics',
                      color: _showLyrics ? theme.colorScheme.primary : null,
                      icon: const Icon(Icons.lyrics_outlined),
                    ),
                  ],
                ),
                Expanded(
                  child: _showLyrics
                      ? _buildLyricsView(context)
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = math
                                    .min(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    )
                                    .clamp(0.0, 420.0)
                                    .toDouble();
                                return TrackArtwork(
                                  track: track,
                                  size: size,
                                  borderRadius: 32,
                                );
                              },
                            ),
                          ),
                        ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artistLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleFavorite,
                      tooltip: _isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      color: _isFavorite ? Colors.redAccent : null,
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${index + 1} of ${widget.controller.queue.tracks.length}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filledTonal(
                      onPressed: widget.controller.canSkipPrevious
                          ? widget.controller.skipPrevious
                          : null,
                      tooltip: 'Previous',
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    IconButton.filled(
                      onPressed: widget.controller.togglePlayPause,
                      tooltip: widget.controller.isPlaying ? 'Pause' : 'Play',
                      iconSize: 40,
                      padding: const EdgeInsets.all(18),
                      icon: Icon(
                        widget.controller.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: widget.controller.canSkipNext
                          ? widget.controller.skipNext
                          : null,
                      tooltip: 'Next',
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLyricsView(BuildContext context) {
    if (_isLoadingLyrics) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lyrics == null || _lyrics!.lines.isEmpty) {
      return Center(
        child: Text(
          'No lyrics found for this track',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: _lyrics!.lines.length,
      itemBuilder: (context, i) {
        final line = _lyrics!.lines[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            line.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w500, height: 1.4),
          ),
        );
      },
    );
  }
}
