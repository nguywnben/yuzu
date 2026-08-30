import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/domain/media/music_provider.dart';

void main() {
  group('FakeMusicProvider', () {
    test('returns deterministic home sections', () async {
      final provider = FakeMusicProvider();

      final first = await provider.fetchHome();
      final second = await provider.fetchHome();

      expect(first.map((section) => section.id), [
        'quick-picks',
        'new-for-you',
      ]);
      expect(first.first.tracks, isNotEmpty);
      expect(
        second.first.tracks.map((track) => track.id),
        first.first.tracks.map((track) => track.id),
      );
    });

    test('searches title and artist without case sensitivity', () async {
      final provider = FakeMusicProvider();

      final byTitle = await provider.search('  SUNRISE  ');
      final byArtist = await provider.search('yuzu sessions');
      final blank = await provider.search('   ');

      expect(byTitle.single.title, 'Sunrise Drive');
      expect(byArtist, isNotEmpty);
      expect(blank, isEmpty);
    });

    test('can simulate an empty catalog', () async {
      final provider = FakeMusicProvider(scenario: FakeCatalogScenario.empty);

      expect(await provider.fetchHome(), isEmpty);
      expect(await provider.search('sunrise'), isEmpty);
    });

    test('can simulate a provider failure', () async {
      final provider = FakeMusicProvider(scenario: FakeCatalogScenario.failure);

      await expectLater(
        provider.fetchHome(),
        throwsA(isA<MusicProviderException>()),
      );
      await expectLater(
        provider.search('sunrise'),
        throwsA(isA<MusicProviderException>()),
      );
    });

    test('can delay a response so loading state is observable', () async {
      final provider = FakeMusicProvider(
        responseDelay: const Duration(milliseconds: 10),
      );
      var completed = false;

      final request = provider.fetchHome().then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      await request;
      expect(completed, isTrue);
    });
  });
}
