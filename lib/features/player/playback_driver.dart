import '../../domain/media/track.dart';

final class PlaybackDriverState {
  const PlaybackDriverState({
    required this.currentIndex,
    required this.isPlaying,
  });

  final int? currentIndex;
  final bool isPlaying;
}

abstract interface class PlaybackDriver {
  Stream<PlaybackDriverState> get states;

  Future<void> loadQueue(List<Track> tracks, {required int startIndex});

  Future<void> play();

  Future<void> pause();

  Future<void> skipNext();

  Future<void> skipPrevious();
}
