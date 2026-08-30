import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yuzu/domain/media/track.dart';
import 'package:yuzu/platform/audio/audio_service_mappers.dart';

void main() {
  test('maps audio service state to the platform-neutral driver state', () {
    final state = playbackDriverStateFrom(
      PlaybackState(
        playing: true,
        processingState: AudioProcessingState.ready,
        queueIndex: 2,
      ),
    );

    expect(state.currentIndex, 2);
    expect(state.isPlaying, isTrue);
  });

  test('maps track metadata for Android media controls', () {
    final item = mediaItemFromTrack(
      Track(
        id: 'track-1',
        title: 'Yuzu Sunrise',
        artists: const ['Yuzu Sessions', 'Open Studio'],
        duration: const Duration(minutes: 3),
      ),
    );

    expect(item.id, 'track-1');
    expect(item.title, 'Yuzu Sunrise');
    expect(item.artist, 'Yuzu Sessions, Open Studio');
    expect(item.album, 'Yuzu Test Audio');
    expect(item.duration, const Duration(minutes: 3));
  });

  test('builds notification controls and processing state from a snapshot', () {
    final playing = playbackStateFromSnapshot(
      playing: true,
      processingState: ProcessingState.ready,
      position: const Duration(seconds: 4),
      bufferedPosition: const Duration(seconds: 30),
      speed: 1,
      currentIndex: 1,
    );
    final paused = playbackStateFromSnapshot(
      playing: false,
      processingState: ProcessingState.buffering,
      position: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1,
      currentIndex: null,
    );

    expect(playing.controls, contains(MediaControl.pause));
    expect(playing.controls, isNot(contains(MediaControl.play)));
    expect(playing.processingState, AudioProcessingState.ready);
    expect(playing.queueIndex, 1);
    expect(paused.controls, contains(MediaControl.play));
    expect(paused.processingState, AudioProcessingState.buffering);
  });

  test('maps every just_audio processing state', () {
    expect(
      audioProcessingStateFrom(ProcessingState.idle),
      AudioProcessingState.idle,
    );
    expect(
      audioProcessingStateFrom(ProcessingState.loading),
      AudioProcessingState.loading,
    );
    expect(
      audioProcessingStateFrom(ProcessingState.buffering),
      AudioProcessingState.buffering,
    );
    expect(
      audioProcessingStateFrom(ProcessingState.ready),
      AudioProcessingState.ready,
    );
    expect(
      audioProcessingStateFrom(ProcessingState.completed),
      AudioProcessingState.completed,
    );
  });
}
