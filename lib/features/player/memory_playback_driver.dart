import 'dart:async';

import '../../domain/media/track.dart';
import 'playback_driver.dart';

final class MemoryPlaybackDriver implements PlaybackDriver {
  final _states = StreamController<PlaybackDriverState>.broadcast(sync: true);

  var _trackCount = 0;
  int? _currentIndex;
  var _isPlaying = false;

  @override
  Stream<PlaybackDriverState> get states => _states.stream;

  @override
  Future<void> loadQueue(List<Track> tracks, {required int startIndex}) async {
    RangeError.checkValidIndex(startIndex, tracks, 'startIndex');
    _trackCount = tracks.length;
    _currentIndex = startIndex;
    _isPlaying = true;
    _emit();
  }

  @override
  Future<void> pause() async {
    if (_currentIndex == null) {
      return;
    }
    _isPlaying = false;
    _emit();
  }

  @override
  Future<void> play() async {
    if (_currentIndex == null) {
      return;
    }
    _isPlaying = true;
    _emit();
  }

  @override
  Future<void> skipNext() async {
    final index = _currentIndex;
    if (index == null || index >= _trackCount - 1) {
      return;
    }
    _currentIndex = index + 1;
    _emit();
  }

  @override
  Future<void> skipPrevious() async {
    final index = _currentIndex;
    if (index == null || index == 0) {
      return;
    }
    _currentIndex = index - 1;
    _emit();
  }

  void _emit() {
    _states.add(
      PlaybackDriverState(currentIndex: _currentIndex, isPlaying: _isPlaying),
    );
  }
}
