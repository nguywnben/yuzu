import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/transport.dart';
import 'package:yuzu/data/youtube_music/youtube_music_provider.dart';
import 'package:yuzu/domain/media/music_provider.dart';
import 'package:yuzu/domain/media/search_result.dart';

void main() {
  test(
    'maps guest Search while delegating Home to the offline provider',
    () async {
      final provider = YoutubeMusicProvider(
        transport: _FixtureTransport(),
        fallbackProvider: FakeMusicProvider(),
      );

      final results = await provider.search(' citrus ');
      final home = await provider.fetchHome();

      expect(results.whereType<TrackSearchResult>(), hasLength(1));
      expect(results.whereType<AlbumSearchResult>(), hasLength(1));
      expect(results.whereType<ArtistSearchResult>(), hasLength(1));
      expect(home.first.title, 'Quick picks');
    },
  );

  test(
    'does not expose transport failures through the feature boundary',
    () async {
      final provider = YoutubeMusicProvider(
        transport: _FailingTransport(),
        fallbackProvider: FakeMusicProvider(),
      );

      await expectLater(
        provider.search('citrus'),
        throwsA(
          isA<MusicProviderException>().having(
            (failure) => failure.message,
            'message',
            isNot(contains('CatalogFailure')),
          ),
        ),
      );
    },
  );
}

final class _FixtureTransport implements CatalogTransport {
  @override
  Future<CatalogTransportResponse> send(CatalogTransportRequest request) async {
    return CatalogTransportResponse(
      statusCode: 200,
      contentType: 'application/json',
      bodyBytes: File('test/fixtures/youtube_music/search_response.json')
          .readAsBytesSync(),
    );
  }
}

final class _FailingTransport implements CatalogTransport {
  @override
  Future<CatalogTransportResponse> send(CatalogTransportRequest request) {
    throw const CatalogFailure(CatalogFailureKind.timeout);
  }
}
