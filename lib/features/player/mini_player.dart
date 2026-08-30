import 'package:flutter/material.dart';

import '../shared/track_widgets.dart';
import 'playback_controller.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.controller, required this.onOpen});

  final PlaybackController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final track = controller.currentTrack;
    if (track == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const Key('mini-player-details'),
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Row(
                      children: [
                        TrackArtwork(track: track, size: 56, borderRadius: 14),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                track.artistLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.togglePlayPause,
                tooltip: controller.isPlaying ? 'Pause' : 'Play',
                icon: Icon(
                  controller.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              IconButton(
                onPressed: controller.canSkipNext ? controller.skipNext : null,
                tooltip: 'Next',
                icon: const Icon(Icons.skip_next_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
