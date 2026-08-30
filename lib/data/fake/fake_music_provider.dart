import '../../domain/media/home_section.dart';
import '../../domain/media/music_provider.dart';
import '../../domain/media/track.dart';

enum FakeCatalogScenario { ready, empty, failure }

final class FakeMusicProvider implements MusicProvider {
  FakeMusicProvider({
    this.scenario = FakeCatalogScenario.ready,
    this.responseDelay = Duration.zero,
  });

  final FakeCatalogScenario scenario;
  final Duration responseDelay;

  static final List<Track> _catalog = [
    Track(
      id: 'sunrise-drive',
      title: 'Sunrise Drive',
      artists: const ['Yuzu Sessions'],
      duration: const Duration(minutes: 3, seconds: 42),
    ),
    Track(
      id: 'paper-lanterns',
      title: 'Paper Lanterns',
      artists: const ['Mika Arai'],
      duration: const Duration(minutes: 4, seconds: 8),
    ),
    Track(
      id: 'after-rain',
      title: 'After the Rain',
      artists: const ['Yuzu Sessions', 'North Window'],
      duration: const Duration(minutes: 3, seconds: 18),
    ),
    Track(
      id: 'quiet-platform',
      title: 'Quiet Platform',
      artists: const ['North Window'],
      duration: const Duration(minutes: 2, seconds: 56),
    ),
    Track(
      id: 'citrus-sky',
      title: 'Citrus Sky',
      artists: const ['Aoi Fields'],
      duration: const Duration(minutes: 3, seconds: 31),
    ),
    Track(
      id: 'midnight-convenience',
      title: 'Midnight Convenience',
      artists: const ['Yuzu Sessions'],
      duration: const Duration(minutes: 4, seconds: 1),
    ),
  ];

  @override
  Future<List<HomeSection>> fetchHome() async {
    await _waitForResponse();
    switch (scenario) {
      case FakeCatalogScenario.ready:
        return [
          HomeSection(
            id: 'quick-picks',
            title: 'Quick picks',
            tracks: _catalog.take(4).toList(),
          ),
          HomeSection(
            id: 'new-for-you',
            title: 'New for you',
            tracks: _catalog.skip(2).toList(),
          ),
        ];
      case FakeCatalogScenario.empty:
        return const [];
      case FakeCatalogScenario.failure:
        throw const MusicProviderException('The test catalog is unavailable.');
    }
  }

  @override
  Future<List<Track>> search(String query) async {
    await _waitForResponse();
    switch (scenario) {
      case FakeCatalogScenario.ready:
        final normalizedQuery = query.trim().toLowerCase();
        if (normalizedQuery.isEmpty) {
          return const [];
        }
        return _catalog
            .where((track) {
              final searchableText = '${track.title} ${track.artistLabel}'
                  .toLowerCase();
              return searchableText.contains(normalizedQuery);
            })
            .toList(growable: false);
      case FakeCatalogScenario.empty:
        return const [];
      case FakeCatalogScenario.failure:
        throw const MusicProviderException('The test catalog is unavailable.');
    }
  }

  Future<void> _waitForResponse() async {
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }
  }
}
