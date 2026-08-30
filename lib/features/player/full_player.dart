import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shared/track_widgets.dart';
import 'playback_controller.dart';

class FullPlayer extends StatelessWidget {
  const FullPlayer({super.key, required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final track = controller.currentTrack;
        if (track == null) {
          return const SizedBox.shrink();
        }

        final index = controller.queue.currentIndex ?? 0;
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
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
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = math
                              .min(constraints.maxWidth, constraints.maxHeight)
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    track.artistLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${index + 1} of ${controller.queue.tracks.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton.filledTonal(
                      onPressed: controller.canSkipPrevious
                          ? controller.skipPrevious
                          : null,
                      tooltip: 'Previous',
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    IconButton.filled(
                      onPressed: controller.togglePlayPause,
                      tooltip: controller.isPlaying ? 'Pause' : 'Play',
                      iconSize: 40,
                      padding: const EdgeInsets.all(18),
                      icon: Icon(
                        controller.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: controller.canSkipNext
                          ? controller.skipNext
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
}
