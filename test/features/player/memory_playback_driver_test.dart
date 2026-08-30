import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/domain/media/track.dart';
import 'package:yuzu/features/player/memory_playback_driver.dart';
import 'package:yuzu/features/player/playback_driver.dart';

void main() {
  final tracks = [_track('one'), _track('two')];

  test('ignores transport commands until a queue is loaded', () async {
    final driver = MemoryPlaybackDriver();
    final states = <PlaybackDriverState>[];
    driver.states.listen(states.add);

    await driver.play();
    await driver.pause();
    await driver.skipNext();
    await driver.skipPrevious();

    expect(states, isEmpty);
  });

  test('emits play, pause, and bounded queue movement', () async {
    final driver = MemoryPlaybackDriver();
    final states = <PlaybackDriverState>[];
    driver.states.listen(states.add);

    await driver.loadQueue(tracks, startIndex: 0);
    await driver.skipPrevious();
    await driver.pause();
    await driver.play();
    await driver.skipNext();
    await driver.skipNext();

    expect(states, hasLength(4));
    expect(states[0].currentIndex, 0);
    expect(states[1].isPlaying, isFalse);
    expect(states[2].isPlaying, isTrue);
    expect(states[3].currentIndex, 1);
  });

  test('rejects an invalid start index', () async {
    final driver = MemoryPlaybackDriver();

    await expectLater(
      driver.loadQueue(tracks, startIndex: 2),
      throwsRangeError,
    );
  });
}

Track _track(String id) => Track(
  id: id,
  title: 'Track $id',
  artists: const ['Yuzu Sessions'],
  duration: const Duration(minutes: 3),
);
