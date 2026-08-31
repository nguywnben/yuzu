import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/domain/media/home_page.dart';
import 'package:yuzu/domain/media/home_section.dart';
import 'package:yuzu/domain/media/music_provider.dart';
import 'package:yuzu/domain/media/search_result.dart';
import 'package:yuzu/domain/media/track.dart';
import 'package:yuzu/features/home/home_view_model.dart';

void main() {
  group('HomeViewModel', () {
    test('moves from loading to ready with home sections', () async {
      final viewModel = HomeViewModel(
        FakeMusicProvider(responseDelay: const Duration(milliseconds: 1)),
      );

      final request = viewModel.load();
      expect(viewModel.status, HomeStatus.loading);

      await request;
      expect(viewModel.status, HomeStatus.ready);
      expect(viewModel.sections.first.id, 'quick-picks');
      expect(viewModel.hasMore, isFalse);
    });

    test('exposes an empty state', () async {
      final viewModel = HomeViewModel(
        FakeMusicProvider(scenario: FakeCatalogScenario.empty),
      );

      await viewModel.load();

      expect(viewModel.status, HomeStatus.empty);
      expect(viewModel.sections, isEmpty);
    });

    test('exposes a retryable error state', () async {
      final viewModel = HomeViewModel(
        FakeMusicProvider(scenario: FakeCatalogScenario.failure),
      );

      await viewModel.load();

      expect(viewModel.status, HomeStatus.failure);
      expect(viewModel.errorMessage, isNotEmpty);
    });

    test('merges continuation sections and removes duplicate tracks', () async {
      final provider = _PagedHomeProvider();
      final viewModel = HomeViewModel(provider);

      await viewModel.load();
      expect(viewModel.hasMore, isTrue);

      await viewModel.loadMore();

      expect(provider.requestedContinuations, ['home-page-2']);
      expect(viewModel.sections, hasLength(2));
      expect(viewModel.sections.first.tracks.map((track) => track.id), [
        'track-1',
        'track-2',
      ]);
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.loadMoreErrorMessage, isEmpty);
    });

    test('keeps loaded sections when a continuation retry is needed', () async {
      final provider = _PagedHomeProvider(failContinuationOnce: true);
      final viewModel = HomeViewModel(provider);

      await viewModel.load();
      await viewModel.loadMore();

      expect(viewModel.status, HomeStatus.ready);
      expect(viewModel.sections.first.tracks, hasLength(1));
      expect(viewModel.hasMore, isTrue);
      expect(viewModel.loadMoreErrorMessage, isNotEmpty);

      await viewModel.loadMore();

      expect(viewModel.sections.first.tracks, hasLength(2));
      expect(viewModel.loadMoreErrorMessage, isEmpty);
    });

    test('does not request the same continuation twice', () async {
      final provider = _PagedHomeProvider(repeatContinuation: true);
      final viewModel = HomeViewModel(provider);

      await viewModel.load();
      await viewModel.loadMore();
      await viewModel.loadMore();

      expect(provider.requestedContinuations, ['home-page-2']);
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.loadMoreErrorMessage, isNotEmpty);
    });

    test(
      'merges non-track discovery items without losing their types',
      () async {
        final viewModel = HomeViewModel(_MixedPagedHomeProvider());

        await viewModel.load();
        await viewModel.loadMore();

        expect(viewModel.sections.single.items, hasLength(2));
        expect(viewModel.sections.single.items.first, isA<AlbumSearchResult>());
        expect(
          viewModel.sections.single.items.last,
          isA<PlaylistSearchResult>(),
        );
        expect(viewModel.sections.single.tracks, isEmpty);
      },
    );
  });
}

final class _MixedPagedHomeProvider implements MusicProvider {
  @override
  Future<HomePage> fetchHome({String? continuationToken}) async {
    return HomePage(
      sections: [
        HomeSection.items(
          id: 'guest-discovery',
          title: 'Guest discovery',
          items: continuationToken == null
              ? [
                  AlbumSearchResult(
                    id: 'orange-hours',
                    title: 'Orange Hours',
                    artists: const ['Yuzu Studio'],
                  ),
                ]
              : [
                  PlaylistSearchResult(
                    id: 'citrus-mix',
                    title: 'Citrus Mix',
                    subtitle: 'Yuzu Studio and more',
                  ),
                ],
        ),
      ],
      continuationToken: continuationToken == null ? 'mixed-page-2' : null,
    );
  }

  @override
  Future<List<SearchResult>> search(String query) async => const [];
}

final class _PagedHomeProvider implements MusicProvider {
  _PagedHomeProvider({
    this.failContinuationOnce = false,
    this.repeatContinuation = false,
  });

  final bool failContinuationOnce;
  final bool repeatContinuation;
  final List<String> requestedContinuations = [];
  var _hasFailed = false;

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
    requestedContinuations.add(continuationToken);
    if (failContinuationOnce && !_hasFailed) {
      _hasFailed = true;
      throw const MusicProviderException('Fixture continuation failure.');
    }
    return HomePage(
      sections: [
        HomeSection(
          id: 'made-for-yuzu',
          title: 'Made for Yuzu',
          tracks: [_firstTrack, _secondTrack],
        ),
        HomeSection(
          id: 'fresh-arrivals',
          title: 'Fresh arrivals',
          tracks: [_secondTrack],
        ),
      ],
      continuationToken: repeatContinuation ? 'home-page-2' : null,
    );
  }

  @override
  Future<List<SearchResult>> search(String query) async => const [];
}
