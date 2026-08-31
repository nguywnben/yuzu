import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/app/yuzu_app.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';

void main() {
  testWidgets('Home renders catalog sections after loading', (tester) async {
    await tester.pumpWidget(
      YuzuApp(
        musicProvider: FakeMusicProvider(
          responseDelay: const Duration(milliseconds: 10),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Quick picks'), findsOneWidget);
    expect(find.text('Sunrise Drive'), findsOneWidget);
  });

  testWidgets('Home renders empty and failure states', (tester) async {
    await tester.pumpWidget(
      YuzuApp(
        musicProvider: FakeMusicProvider(scenario: FakeCatalogScenario.empty),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing to play yet'), findsOneWidget);

    await tester.pumpWidget(
      YuzuApp(
        musicProvider: FakeMusicProvider(scenario: FakeCatalogScenario.failure),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Home couldn't load"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Search returns matching tracks', (tester) async {
    await tester.pumpWidget(YuzuApp(musicProvider: FakeMusicProvider()));

    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'sunrise');
    await tester.pumpAndSettle();

    expect(find.text('Sunrise Drive'), findsOneWidget);
    expect(find.text('Yuzu Sessions'), findsOneWidget);
  });

  testWidgets('Search distinguishes tracks, albums, and artists', (
    tester,
  ) async {
    await tester.pumpWidget(YuzuApp(musicProvider: FakeMusicProvider()));

    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'yuzu sessions');
    await tester.pumpAndSettle();

    expect(find.text('Track'), findsWidgets);
    expect(find.text('Album'), findsOneWidget);
    expect(find.text('Artist'), findsOneWidget);
  });
}
