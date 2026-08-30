import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/app/yuzu_app.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/features/player/mini_player.dart';

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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunrise Drive'));
    await tester.pump();

    expect(find.byType(MiniPlayer), findsOneWidget);
  });
}

Widget _testApp() => YuzuApp(musicProvider: FakeMusicProvider());
