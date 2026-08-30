import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/media/track.dart';
import '../../features/player/playback_driver.dart';

PlaybackDriverState playbackDriverStateFrom(PlaybackState state) {
  return PlaybackDriverState(
    currentIndex: state.queueIndex,
    isPlaying: state.playing,
  );
}

MediaItem mediaItemFromTrack(Track track) {
  return MediaItem(
    id: track.id,
    album: 'Yuzu Test Audio',
    title: track.title,
    artist: track.artistLabel,
    duration: track.duration,
    artUri: track.artworkUri,
  );
}

PlaybackState playbackStateFromSnapshot({
  required bool playing,
  required ProcessingState processingState,
  required Duration position,
  required Duration bufferedPosition,
  required double speed,
  required int? currentIndex,
}) {
  return PlaybackState(
    controls: [
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
      MediaControl.skipToNext,
    ],
    systemActions: const {MediaAction.seek},
    androidCompactActionIndices: const [0, 1, 3],
    processingState: audioProcessingStateFrom(processingState),
    playing: playing,
    updatePosition: position,
    bufferedPosition: bufferedPosition,
    speed: speed,
    queueIndex: currentIndex,
  );
}

AudioProcessingState audioProcessingStateFrom(ProcessingState state) {
  return switch (state) {
    ProcessingState.idle => AudioProcessingState.idle,
    ProcessingState.loading => AudioProcessingState.loading,
    ProcessingState.buffering => AudioProcessingState.buffering,
    ProcessingState.ready => AudioProcessingState.ready,
    ProcessingState.completed => AudioProcessingState.completed,
  };
}
