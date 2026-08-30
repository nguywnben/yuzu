import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/media/playback_queue.dart';
import '../../domain/media/track.dart';
import 'playback_driver.dart';

final class PlaybackController extends ChangeNotifier {
  PlaybackController(this._driver) {
    _stateSubscription = _driver.states.listen(_applyDriverState);
  }

  final PlaybackDriver _driver;
  late final StreamSubscription<PlaybackDriverState> _stateSubscription;
  PlaybackQueue _queue = PlaybackQueue.empty();
  bool _isPlaying = false;

  PlaybackQueue get queue => _queue;
  Track? get currentTrack => _queue.currentTrack;
  bool get isPlaying => _isPlaying;
  bool get canSkipNext => _queue.canMoveNext;
  bool get canSkipPrevious => _queue.canMovePrevious;

  void playTrack(Track track, {List<Track>? queue}) {
    final nextQueue = queue ?? [track];
    final startIndex = nextQueue.indexWhere((item) => item.id == track.id);
    if (startIndex < 0) {
      throw ArgumentError.value(
        queue,
        'queue',
        'must contain the selected track',
      );
    }

    _queue = PlaybackQueue.fromTracks(nextQueue, startIndex: startIndex);
    notifyListeners();
    unawaited(_driver.loadQueue(nextQueue, startIndex: startIndex));
  }

  void togglePlayPause() {
    if (currentTrack == null) {
      return;
    }
    unawaited(_isPlaying ? _driver.pause() : _driver.play());
  }

  void skipNext() {
    if (!canSkipNext) {
      return;
    }
    unawaited(_driver.skipNext());
  }

  void skipPrevious() {
    if (!canSkipPrevious) {
      return;
    }
    unawaited(_driver.skipPrevious());
  }

  void _applyDriverState(PlaybackDriverState state) {
    final index = state.currentIndex;
    if (index != null && index >= 0 && index < _queue.tracks.length) {
      _queue = PlaybackQueue.fromTracks(_queue.tracks, startIndex: index);
    }
    _isPlaying = state.isPlaying;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_stateSubscription.cancel());
    super.dispose();
  }
}
