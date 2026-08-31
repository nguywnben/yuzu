import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/app/yuzu_app.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/domain/media/track.dart';
import 'package:yuzu/features/player/mini_player.dart';
import 'package:yuzu/features/player/playback_driver.dart';

void main() {
  testWidgets('selecting a Home track opens a controllable mini-player', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunrise Drive'));
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.byTooltip('Play'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mini-player-details')));
    await tester.pumpAndSettle();
    expect(find.text('Now playing'), findsOneWidget);
  });

  testWidgets('mini-player next control advances through the Home section', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunrise Drive'));
    await tester.pump();
    await tester.tap(find.byTooltip('Next'));
    await tester.pump();

    final miniPlayer = find.byType(MiniPlayer);
    expect(
      find.descendant(of: miniPlayer, matching: find.text('Paper Lanterns')),
      findsOneWidget,
    );
  });

  testWidgets('selecting a Search result sends a playback command', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'sunrise');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunrise Drive'));
    await tester.pump();

    expect(find.byType(MiniPlayer), findsOneWidget);
  });

  testWidgets('shows a Material error when the audio driver fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      YuzuApp(
        musicProvider: FakeMusicProvider(),
        playbackDriver: _FailingPlaybackDriver(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunrise Drive'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to play audio. Please try again.'),
      findsOneWidget,
    );
  });
}

Widget _testApp() => YuzuApp(musicProvider: FakeMusicProvider());

final class _FailingPlaybackDriver implements PlaybackDriver {
  @override
  Stream<PlaybackDriverState> get states =>
      const Stream<PlaybackDriverState>.empty();

  @override
  Future<void> loadQueue(List<Track> tracks, {required int startIndex}) async {
    throw StateError('decoder failed');
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> skipNext() async {}

  @override
  Future<void> skipPrevious() async {}
}
