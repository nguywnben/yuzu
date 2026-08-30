import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yuzu/app/yuzu_app.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/features/player/full_player.dart';
import 'package:yuzu/features/player/mini_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search to player queue works end to end', (tester) async {
    await tester.pumpWidget(YuzuApp(musicProvider: FakeMusicProvider()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Yuzu Sessions');
    await tester.pumpAndSettle();

    expect(find.text('Sunrise Drive'), findsOneWidget);
    expect(find.text('After the Rain'), findsOneWidget);

    await tester.tap(find.text('Sunrise Drive'));
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mini-player-details')));
    await tester.pumpAndSettle();

    expect(find.text('Now playing'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);

    final fullPlayer = find.byType(FullPlayer);
    await tester.tap(
      find.descendant(of: fullPlayer, matching: find.byTooltip('Next')),
    );
    await tester.pump();

    expect(
      find.descendant(of: fullPlayer, matching: find.text('After the Rain')),
      findsOneWidget,
    );
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.byTooltip('Previous'), findsOneWidget);

    await tester.tap(find.byTooltip('Close player'));
    await tester.pumpAndSettle();

    final miniPlayer = find.byType(MiniPlayer);
    expect(
      find.descendant(of: miniPlayer, matching: find.text('After the Rain')),
      findsOneWidget,
    );
  });
}
