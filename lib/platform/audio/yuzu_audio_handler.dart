import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/local/local_library_database.dart';
import '../../data/youtube_music/stream_resolver.dart';
import '../../domain/media/track.dart';
import '../../features/player/playback_driver.dart';
import '../../infrastructure/audio/test_tone.dart';
import 'audio_service_mappers.dart';

final class YuzuAudioHandler extends BaseAudioHandler
    implements PlaybackDriver {
  YuzuAudioHandler({StreamResolver? streamResolver})
    : _player = AudioPlayer(),
      _streamResolver = streamResolver ?? YoutubeStreamResolver() {
    _playbackSubscription = _player.playbackEventStream.listen(_broadcastState);
    _indexSubscription = _player.currentIndexStream.listen(_broadcastMediaItem);
  }

  final AudioPlayer _player;
  final StreamResolver _streamResolver;
  late final StreamSubscription<PlaybackEvent> _playbackSubscription;
  late final StreamSubscription<int?> _indexSubscription;
  List<MediaItem> _mediaItems = const [];
  List<Track> _tracks = const [];

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
    _tracks = List.unmodifiable(tracks);
    _mediaItems = List.unmodifiable(tracks.map(mediaItemFromTrack));
    queue.add(_mediaItems);
    mediaItem.add(_mediaItems[startIndex]);

    // 1. Resolve and play the selected track immediately
    final initialTrack = tracks[startIndex];
    final isInitialYoutube =
        RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(initialTrack.id);

    AudioSource initialSource;
    if (isInitialYoutube) {
      try {
        final stream = await _streamResolver.resolve(initialTrack.id);
        initialSource = AudioSource.uri(
          stream.uri,
          headers: stream.headers,
          tag: _mediaItems[startIndex],
        );
      } catch (_) {
        final toneUri = await ensureYuzuTestToneFile();
        initialSource = AudioSource.uri(
          toneUri,
          tag: _mediaItems[startIndex],
        );
      }
    } else {
      final toneUri = await ensureYuzuTestToneFile();
      initialSource = AudioSource.uri(
        toneUri,
        tag: _mediaItems[startIndex],
      );
    }

    // Set and play right away so the user hears music instantly
    await _player.setAudioSources([initialSource]);
    await _player.play();
    unawaited(_recordCurrentHistory(startIndex));
  }

  Future<void> _recordCurrentHistory(int index) async {
    if (index >= 0 && index < _tracks.length) {
      try {
        final db = await LocalLibraryDatabase.getInstance();
        await db.recordHistory(_tracks[index]);
      } catch (_) {}
    }
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
      unawaited(_recordCurrentHistory(index));
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
