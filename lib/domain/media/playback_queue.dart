import 'track.dart';

final class PlaybackQueue {
  PlaybackQueue._(List<Track> tracks, this.currentIndex)
    : tracks = List.unmodifiable(tracks);

  factory PlaybackQueue.empty() => PlaybackQueue._(const [], null);

  factory PlaybackQueue.fromTracks(List<Track> tracks, {int startIndex = 0}) {
    if (tracks.isEmpty) {
      if (startIndex != 0) {
        throw RangeError.index(startIndex, tracks, 'startIndex');
      }
      return PlaybackQueue.empty();
    }
    RangeError.checkValidIndex(startIndex, tracks, 'startIndex');
    return PlaybackQueue._(tracks, startIndex);
  }

  final List<Track> tracks;
  final int? currentIndex;

  Track? get currentTrack {
    final index = currentIndex;
    return index == null ? null : tracks[index];
  }

  bool get canMoveNext {
    final index = currentIndex;
    return index != null && index < tracks.length - 1;
  }

  bool get canMovePrevious {
    final index = currentIndex;
    return index != null && index > 0;
  }

  PlaybackQueue moveNext() =>
      canMoveNext ? PlaybackQueue._(tracks, currentIndex! + 1) : this;

  PlaybackQueue movePrevious() =>
      canMovePrevious ? PlaybackQueue._(tracks, currentIndex! - 1) : this;
}
