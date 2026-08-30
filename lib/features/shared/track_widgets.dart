import 'package:flutter/material.dart';

import '../../domain/media/track.dart';

typedef TrackSelectionCallback = void Function(Track track, List<Track> queue);

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    super.key,
    required this.track,
    required this.size,
    this.borderRadius = 20,
  });

  final Track track;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alternate = track.id.codeUnits.fold<int>(
      0,
      (sum, unit) => sum + unit,
    );
    final colors = alternate.isEven
        ? [colorScheme.primaryContainer, colorScheme.tertiaryContainer]
        : [colorScheme.secondaryContainer, colorScheme.primaryContainer];

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.34,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class TrackListTile extends StatelessWidget {
  const TrackListTile({super.key, required this.track, this.onTap});

  final Track track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: TrackArtwork(track: track, size: 56, borderRadius: 14),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        track.artistLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(_formatDuration(track.duration)),
      onTap: onTap,
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
