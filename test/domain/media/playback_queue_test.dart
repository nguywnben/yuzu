import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/domain/media/playback_queue.dart';
import 'package:yuzu/domain/media/track.dart';

void main() {
  final tracks = [_track('one'), _track('two'), _track('three')];

  group('PlaybackQueue', () {
    test('empty queue has no current item or navigation', () {
      final queue = PlaybackQueue.empty();

      expect(queue.currentTrack, isNull);
      expect(queue.canMoveNext, isFalse);
      expect(queue.canMovePrevious, isFalse);
    });

    test('starts at the requested item and protects its item collection', () {
      final source = [...tracks];
      final queue = PlaybackQueue.fromTracks(source, startIndex: 1);
      source.clear();

      expect(queue.currentTrack?.id, 'two');
      expect(queue.tracks, hasLength(3));
      expect(() => queue.tracks.clear(), throwsUnsupportedError);
    });

    test('moves within bounds without wrapping', () {
      final queue = PlaybackQueue.fromTracks(tracks);

      final second = queue.moveNext();
      final third = second.moveNext();

      expect(second.currentTrack?.id, 'two');
      expect(third.currentTrack?.id, 'three');
      expect(third.canMoveNext, isFalse);
      expect(third.moveNext().currentTrack?.id, 'three');
      expect(third.movePrevious().currentTrack?.id, 'two');
    });

    test('rejects an invalid start index', () {
      expect(
        () => PlaybackQueue.fromTracks(tracks, startIndex: tracks.length),
        throwsRangeError,
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
