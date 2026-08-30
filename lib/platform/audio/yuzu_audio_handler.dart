import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/media/track.dart';
import '../../features/player/playback_driver.dart';
import '../../infrastructure/audio/test_tone.dart';
import 'audio_service_mappers.dart';

final class YuzuAudioHandler extends BaseAudioHandler
    implements PlaybackDriver {
  YuzuAudioHandler() : _player = AudioPlayer() {
    _playbackSubscription = _player.playbackEventStream.listen(_broadcastState);
    _indexSubscription = _player.currentIndexStream.listen(_broadcastMediaItem);
  }

  final AudioPlayer _player;
  late final StreamSubscription<PlaybackEvent> _playbackSubscription;
  late final StreamSubscription<int?> _indexSubscription;
  List<MediaItem> _mediaItems = const [];

  @override
  Stream<PlaybackDriverState> get states => playbackState
      .map(playbackDriverStateFrom)
      .distinct(
        (previous, next) =>
            previous.currentIndex == next.currentIndex &&
            previous.isPlaying == next.isPlaying,
      );

  @override
  Future<void> loadQueue(List<Track> tracks, {required int startIndex}) async {
    RangeError.checkValidIndex(startIndex, tracks, 'startIndex');
    final toneUri = await ensureYuzuTestToneFile();
    _mediaItems = List.unmodifiable(tracks.map(mediaItemFromTrack));
    queue.add(_mediaItems);
    mediaItem.add(_mediaItems[startIndex]);

    await _player.setAudioSources([
      for (var index = 0; index < tracks.length; index++)
        AudioSource.uri(toneUri),
    ], initialIndex: startIndex);
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipNext() => skipToNext();

  @override
  Future<void> skipPrevious() => skipToPrevious();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  Future<void> dispose() async {
    await _playbackSubscription.cancel();
    await _indexSubscription.cancel();
    await _player.dispose();
  }

  void _broadcastMediaItem(int? index) {
    if (index != null && index >= 0 && index < _mediaItems.length) {
      mediaItem.add(_mediaItems[index]);
    }
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackStateFromSnapshot(
        playing: _player.playing,
        processingState: _player.processingState,
        position: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        currentIndex: event.currentIndex,
      ),
    );
  }
}
