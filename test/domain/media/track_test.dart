import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/domain/media/track.dart';

void main() {
  group('Track', () {
    test('stores provider-independent metadata', () {
      final track = Track(
        id: 'track-1',
        title: 'Sunrise Drive',
        artists: const ['Yuzu Sessions', 'Mika'],
        duration: const Duration(minutes: 3, seconds: 42),
        artworkUri: Uri.parse('https://example.test/artwork/track-1'),
      );

      expect(track.id, 'track-1');
      expect(track.title, 'Sunrise Drive');
      expect(track.artistLabel, 'Yuzu Sessions, Mika');
      expect(track.duration, const Duration(minutes: 3, seconds: 42));
      expect(track.artworkUri?.host, 'example.test');
    });

    test('protects its artist collection from mutation', () {
      final artists = ['Yuzu Sessions'];
      final track = Track(
        id: 'track-1',
        title: 'Sunrise Drive',
        artists: artists,
        duration: const Duration(minutes: 3),
      );

      artists.add('Unexpected artist');

      expect(track.artists, const ['Yuzu Sessions']);
      expect(() => track.artists.add('Another artist'), throwsUnsupportedError);
    });

    test('rejects metadata that cannot identify a playable track', () {
      expect(
        () => Track(
          id: ' ',
          title: 'Sunrise Drive',
          artists: const ['Yuzu Sessions'],
          duration: const Duration(minutes: 3),
        ),
        throwsArgumentError,
      );
      expect(
        () => Track(
          id: 'track-1',
          title: '',
          artists: const ['Yuzu Sessions'],
          duration: const Duration(minutes: 3),
        ),
        throwsArgumentError,
      );
      expect(
        () => Track(
          id: 'track-1',
          title: 'Sunrise Drive',
          artists: const [],
          duration: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });
}
