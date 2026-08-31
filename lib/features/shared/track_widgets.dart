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
    return CatalogArtwork(
      id: track.id,
      artworkUri: track.artworkUri,
      size: size,
      borderRadius: borderRadius,
      fallbackIcon: Icons.music_note_rounded,
    );
  }
}

class CatalogArtwork extends StatelessWidget {
  const CatalogArtwork({
    super.key,
    required this.id,
    required this.size,
    required this.fallbackIcon,
    this.artworkUri,
    this.borderRadius = 20,
  });

  final String id;
  final Uri? artworkUri;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alternate = id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final colors = alternate.isEven
        ? [colorScheme.primaryContainer, colorScheme.tertiaryContainer]
        : [colorScheme.secondaryContainer, colorScheme.primaryContainer];
    final fallback = _ArtworkFallback(
      colors: colors,
      size: size,
      icon: fallbackIcon,
    );

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox.square(
          dimension: size,
          child: artworkUri == null
              ? fallback
              : Image.network(
                  artworkUri.toString(),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({
    required this.colors,
    required this.size,
    required this.icon,
  });

  final List<Color> colors;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.34,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
