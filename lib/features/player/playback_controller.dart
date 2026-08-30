import 'package:flutter/foundation.dart';

import '../../domain/media/playback_queue.dart';
import '../../domain/media/track.dart';

final class PlaybackController extends ChangeNotifier {
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
    _isPlaying = true;
    notifyListeners();
  }

  void togglePlayPause() {
    if (currentTrack == null) {
      return;
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void skipNext() {
    if (!canSkipNext) {
      return;
    }
    _queue = _queue.moveNext();
    notifyListeners();
  }

  void skipPrevious() {
    if (!canSkipPrevious) {
      return;
    }
    _queue = _queue.movePrevious();
    notifyListeners();
  }
}
