import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/domain/media/track.dart';
import 'package:yuzu/features/player/playback_controller.dart';

void main() {
  final tracks = [_track('one'), _track('two'), _track('three')];

  group('PlaybackController', () {
    test('starts stopped with an empty queue', () {
      final controller = PlaybackController();

      expect(controller.currentTrack, isNull);
      expect(controller.isPlaying, isFalse);
      expect(controller.canSkipNext, isFalse);
    });

    test('selecting a track loads its context and starts playback', () {
      final controller = PlaybackController();

      controller.playTrack(tracks[1], queue: tracks);

      expect(controller.currentTrack?.id, 'two');
      expect(controller.isPlaying, isTrue);
      expect(controller.canSkipNext, isTrue);
      expect(controller.canSkipPrevious, isTrue);
    });

    test('toggles play and pause only when a track is loaded', () {
      final controller = PlaybackController();

      controller.togglePlayPause();
      expect(controller.isPlaying, isFalse);

      controller.playTrack(tracks.first);
      controller.togglePlayPause();
      expect(controller.isPlaying, isFalse);
      controller.togglePlayPause();
      expect(controller.isPlaying, isTrue);
    });

    test('skips within queue bounds without wrapping', () {
      final controller = PlaybackController()
        ..playTrack(tracks.first, queue: tracks);

      controller.skipPrevious();
      expect(controller.currentTrack?.id, 'one');

      controller.skipNext();
      expect(controller.currentTrack?.id, 'two');
      controller.skipNext();
      controller.skipNext();
      expect(controller.currentTrack?.id, 'three');
    });

    test('rejects context that does not contain the selected track', () {
      final controller = PlaybackController();

      expect(
        () => controller.playTrack(_track('missing'), queue: tracks),
        throwsArgumentError,
      );
    });
  });
}

Track _track(String id) => Track(
  id: id,
  title: 'Track $id',
  artists: const ['Yuzu Sessions'],
  duration: const Duration(minutes: 3),
);
