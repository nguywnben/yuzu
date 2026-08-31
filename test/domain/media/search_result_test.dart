import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/domain/media/search_result.dart';
import 'package:yuzu/domain/media/track.dart';

void main() {
  group('SearchResult', () {
    test('keeps a playable track as a typed result', () {
      final track = Track(
        id: 'fixture-track',
        title: 'Citrus Signal',
        artists: const ['Yuzu Lab'],
        duration: const Duration(minutes: 3),
      );

      final result = TrackSearchResult(track);

      expect(result.id, 'fixture-track');
      expect(result.title, 'Citrus Signal');
      expect(result.track, same(track));
    });

    test('validates album and artist metadata at the domain boundary', () {
      expect(
        () => AlbumSearchResult(
          id: 'fixture-album',
          title: 'Orange Hours',
          artists: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => ArtistSearchResult(id: 'fixture-artist', name: '   '),
        throwsArgumentError,
      );
    });

    test('exposes source-neutral album and artist labels', () {
      final album = AlbumSearchResult(
        id: 'fixture-album',
        title: 'Orange Hours',
        artists: const ['Yuzu Lab', 'North Window'],
      );
      final artist = ArtistSearchResult(id: 'fixture-artist', name: 'Yuzu Lab');

      expect(album.artistLabel, 'Yuzu Lab, North Window');
      expect(artist.title, 'Yuzu Lab');
    });

    test('keeps playlist metadata source-neutral', () {
      final playlist = PlaylistSearchResult(
        id: 'fixture-playlist',
        title: 'Citrus Mix',
        subtitle: 'Yuzu Lab and more',
      );

      expect(playlist.id, 'fixture-playlist');
      expect(playlist.title, 'Citrus Mix');
      expect(playlist.subtitle, 'Yuzu Lab and more');
    });
  });
}
