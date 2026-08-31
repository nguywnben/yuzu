import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/transport.dart';
import 'package:yuzu/data/youtube_music/youtube_music_provider.dart';
import 'package:yuzu/domain/media/music_provider.dart';
import 'package:yuzu/domain/media/search_result.dart';

void main() {
  test('maps guest Search and paged guest Home', () async {
    final provider = YoutubeMusicProvider(transport: _FixtureTransport());

    final results = await provider.search(' citrus ');
    final firstHomePage = await provider.fetchHome();
    final secondHomePage = await provider.fetchHome(
      continuationToken: firstHomePage.continuationToken,
    );

    expect(results.whereType<TrackSearchResult>(), hasLength(1));
    expect(results.whereType<AlbumSearchResult>(), hasLength(1));
    expect(results.whereType<ArtistSearchResult>(), hasLength(1));
    expect(firstHomePage.sections.single.title, 'Made for Yuzu');
    expect(firstHomePage.continuationToken, 'invented-home-page-2');
    expect(secondHomePage.sections.single.title, 'Fresh arrivals');
    expect(secondHomePage.continuationToken, isNull);
  });

  test('rejects a replayed Home continuation before transport', () async {
    final transport = _FixtureTransport();
    final provider = YoutubeMusicProvider(transport: transport);
    final firstPage = await provider.fetchHome();

    await provider.fetchHome(continuationToken: firstPage.continuationToken);
    await expectLater(
      provider.fetchHome(continuationToken: firstPage.continuationToken),
      throwsA(isA<MusicProviderException>()),
    );

    expect(transport.homeRequestCount, 2);
  });

  test(
    'does not expose transport failures through the feature boundary',
    () async {
      final provider = YoutubeMusicProvider(transport: _FailingTransport());

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
  var homeRequestCount = 0;

  @override
  Future<CatalogTransportResponse> send(CatalogTransportRequest request) async {
    if (request.operation == CatalogOperation.home ||
        request.operation == CatalogOperation.continuation) {
      homeRequestCount++;
      final fixture = request.operation == CatalogOperation.home
          ? 'test/fixtures/youtube_music/home_response.json'
          : 'test/fixtures/youtube_music/home_continuation_response.json';
      return CatalogTransportResponse(
        statusCode: 200,
        contentType: 'application/json',
        bodyBytes: File(fixture).readAsBytesSync(),
      );
    }
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
