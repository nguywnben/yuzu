import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/domain/media/home_section.dart';
import 'package:yuzu/domain/media/music_provider.dart';
import 'package:yuzu/domain/media/track.dart';

void main() {
  test(
    'MusicProvider exposes catalog behavior without UI dependencies',
    () async {
      final MusicProvider provider = _ContractProbeProvider();

      final home = await provider.fetchHome();
      final results = await provider.search('sunrise');

      expect(home.single.title, 'Made for testing');
      expect(results.single.id, 'track-1');
    },
  );
}

final class _ContractProbeProvider implements MusicProvider {
  final track = Track(
    id: 'track-1',
    title: 'Sunrise Drive',
    artists: const ['Yuzu Sessions'],
    duration: const Duration(minutes: 3),
  );

  @override
  Future<List<HomeSection>> fetchHome() async => [
    HomeSection(id: 'for-you', title: 'Made for testing', tracks: [track]),
  ];

  @override
  Future<List<Track>> search(String query) async => [track];
}
