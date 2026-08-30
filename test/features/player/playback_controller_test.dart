import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/domain/media/track.dart';
import 'package:yuzu/features/player/playback_controller.dart';
import 'package:yuzu/features/player/playback_driver.dart';

void main() {
  final tracks = [_track('one'), _track('two'), _track('three')];

  group('PlaybackController', () {
    test('starts stopped with an empty queue', () {
      final controller = PlaybackController(_RecordingPlaybackDriver());

      expect(controller.currentTrack, isNull);
      expect(controller.isPlaying, isFalse);
      expect(controller.canSkipNext, isFalse);
    });

    test(
      'selecting a track delegates its context and follows driver state',
      () {
        final driver = _RecordingPlaybackDriver();
        final controller = PlaybackController(driver);

        controller.playTrack(tracks[1], queue: tracks);

        expect(driver.loadedTracks, tracks);
        expect(driver.loadedIndex, 1);
        expect(controller.currentTrack?.id, 'two');
        expect(controller.isPlaying, isTrue);
        expect(controller.canSkipNext, isTrue);
        expect(controller.canSkipPrevious, isTrue);
      },
    );

    test('toggles play and pause only when a track is loaded', () {
      final controller = PlaybackController(_RecordingPlaybackDriver());

      controller.togglePlayPause();
      expect(controller.isPlaying, isFalse);

      controller.playTrack(tracks.first);
      controller.togglePlayPause();
      expect(controller.isPlaying, isFalse);
      controller.togglePlayPause();
      expect(controller.isPlaying, isTrue);
    });

    test('skips within queue bounds without wrapping', () {
      final controller = PlaybackController(_RecordingPlaybackDriver())
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
      final controller = PlaybackController(_RecordingPlaybackDriver());

      expect(
        () => controller.playTrack(_track('missing'), queue: tracks),
        throwsArgumentError,
      );
    });

    test('reflects commands coming from the platform media session', () {
      final driver = _RecordingPlaybackDriver();
      final controller = PlaybackController(driver);

      controller.playTrack(tracks.first, queue: tracks);
      driver.emit(const PlaybackDriverState(currentIndex: 2, isPlaying: false));

      expect(controller.currentTrack?.id, 'three');
      expect(controller.isPlaying, isFalse);
    });

    test('turns driver failures into a consumable playback error', () async {
      final controller = PlaybackController(
        _RecordingPlaybackDriver(loadError: StateError('decoder failed')),
      );

      controller.playTrack(tracks.first);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPlaying, isFalse);
      expect(
        controller.takeErrorMessage(),
        'Unable to play audio. Please try again.',
      );
      expect(controller.takeErrorMessage(), isNull);
    });
  });
}

final class _RecordingPlaybackDriver implements PlaybackDriver {
  _RecordingPlaybackDriver({this.loadError});

  final Object? loadError;
  final _states = StreamController<PlaybackDriverState>.broadcast(sync: true);

  List<Track>? loadedTracks;
  int? loadedIndex;
  var _currentIndex = 0;
  var _isPlaying = false;

  @override
  Stream<PlaybackDriverState> get states => _states.stream;

  @override
  Future<void> loadQueue(List<Track> tracks, {required int startIndex}) async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    loadedTracks = tracks;
    loadedIndex = startIndex;
    _currentIndex = startIndex;
    _isPlaying = true;
    emit(PlaybackDriverState(currentIndex: startIndex, isPlaying: true));
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    emit(PlaybackDriverState(currentIndex: _currentIndex, isPlaying: false));
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    emit(PlaybackDriverState(currentIndex: _currentIndex, isPlaying: true));
  }

  @override
  Future<void> skipNext() async {
    _currentIndex += 1;
    emit(
      PlaybackDriverState(currentIndex: _currentIndex, isPlaying: _isPlaying),
    );
  }

  @override
  Future<void> skipPrevious() async {
    _currentIndex -= 1;
    emit(
      PlaybackDriverState(currentIndex: _currentIndex, isPlaying: _isPlaying),
    );
  }

  void emit(PlaybackDriverState state) => _states.add(state);
}

Track _track(String id) => Track(
  id: id,
  title: 'Track $id',
  artists: const ['Yuzu Sessions'],
  duration: const Duration(minutes: 3),
);
