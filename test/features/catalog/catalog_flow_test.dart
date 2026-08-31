import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/app/yuzu_app.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/domain/media/home_page.dart';
import 'package:yuzu/domain/media/home_section.dart';
import 'package:yuzu/domain/media/music_provider.dart';
import 'package:yuzu/domain/media/search_result.dart';
import 'package:yuzu/domain/media/track.dart';

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

  testWidgets('Home loads another page and retries without losing content', (
    tester,
  ) async {
    final provider = _FlakyPagedHomeProvider();
    await tester.pumpWidget(YuzuApp(musicProvider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Citrus Morning'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Load more'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Load more'));
    await tester.pumpAndSettle();

    expect(find.text('Citrus Morning'), findsOneWidget);
    expect(find.text('Unable to load more music right now.'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Try loading more'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Try loading more'));
    await tester.pumpAndSettle();

    expect(find.text('Paper Horizon'), findsOneWidget);
    expect(find.text('Unable to load more music right now.'), findsNothing);
  });

  testWidgets('Search returns matching tracks', (tester) async {
    await tester.pumpWidget(YuzuApp(musicProvider: FakeMusicProvider()));

    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'sunrise');
    await tester.pump(const Duration(milliseconds: 350));
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
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Track'), findsWidgets);
    expect(find.text('Album'), findsOneWidget);
    expect(find.text('Artist'), findsOneWidget);
  });

  testWidgets('Search debounces rapid query edits before using the provider', (
    tester,
  ) async {
    final provider = _CountingSearchProvider();
    await tester.pumpWidget(YuzuApp(musicProvider: provider));
    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), 'd');
    await tester.enterText(find.byType(SearchBar), 'da');
    await tester.enterText(find.byType(SearchBar), 'daft');
    await tester.pump(const Duration(milliseconds: 349));
    expect(provider.queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(provider.queries, ['daft']);
  });

  testWidgets('Search renders loading, empty, and retry states', (
    tester,
  ) async {
    await tester.pumpWidget(
      YuzuApp(
        musicProvider: FakeMusicProvider(
          responseDelay: const Duration(milliseconds: 50),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'missing result');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.pumpWidget(YuzuApp(musicProvider: _FlakySearchProvider()));
    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'sunrise');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text("Search couldn't finish"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Sunrise Drive'), findsOneWidget);
  });
}

final class _FlakySearchProvider implements MusicProvider {
  final FakeMusicProvider _delegate = FakeMusicProvider();
  var _attempts = 0;

  @override
  Future<HomePage> fetchHome({String? continuationToken}) =>
      _delegate.fetchHome(continuationToken: continuationToken);

  @override
  Future<List<SearchResult>> search(String query) {
    _attempts++;
    if (_attempts == 1) {
      throw const MusicProviderException('Fixture failure.');
    }
    return _delegate.search(query);
  }
}

final class _CountingSearchProvider implements MusicProvider {
  final FakeMusicProvider _delegate = FakeMusicProvider();
  final List<String> queries = [];

  @override
  Future<HomePage> fetchHome({String? continuationToken}) =>
      _delegate.fetchHome(continuationToken: continuationToken);

  @override
  Future<List<SearchResult>> search(String query) {
    queries.add(query);
    return _delegate.search(query);
  }
}

final class _FlakyPagedHomeProvider implements MusicProvider {
  var _continuationAttempts = 0;

  final _firstTrack = Track(
    id: 'track-1',
    title: 'Citrus Morning',
    artists: const ['Yuzu Studio'],
    duration: const Duration(minutes: 3),
  );
  final _secondTrack = Track(
    id: 'track-2',
    title: 'Paper Horizon',
    artists: const ['North Window'],
    duration: const Duration(minutes: 4),
  );

  @override
  Future<HomePage> fetchHome({String? continuationToken}) async {
    if (continuationToken == null) {
      return HomePage(
        sections: [
          HomeSection(
            id: 'made-for-yuzu',
            title: 'Made for Yuzu',
            tracks: [_firstTrack],
          ),
        ],
        continuationToken: 'home-page-2',
      );
    }
    _continuationAttempts++;
    if (_continuationAttempts == 1) {
      throw const MusicProviderException('Fixture continuation failure.');
    }
    return HomePage(
      sections: [
        HomeSection(
          id: 'fresh-arrivals',
          title: 'Fresh arrivals',
          tracks: [_secondTrack],
        ),
      ],
    );
  }

  @override
  Future<List<SearchResult>> search(String query) async => const [];
}
