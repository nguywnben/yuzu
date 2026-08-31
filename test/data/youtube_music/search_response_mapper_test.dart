import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/search_response_mapper.dart';
import 'package:yuzu/data/youtube_music/transport.dart';
import 'package:yuzu/domain/media/search_result.dart';

void main() {
  group('SearchResponseMapper', () {
    const mapper = SearchResponseMapper();

    test('maps invented track, album, and artist fixtures', () {
      final response = CatalogTransportResponse(
        statusCode: 200,
        contentType: 'application/json; charset=UTF-8',
        bodyBytes: File('test/fixtures/youtube_music/search_response.json')
            .readAsBytesSync(),
      );

      final results = mapper.map(response);

      expect(results, hasLength(3));
      final track = (results[0] as TrackSearchResult).track;
      expect(track.id, 'fixture-track-001');
      expect(track.title, 'Citrus Signal');
      expect(track.artists, ['Yuzu Lab']);
      expect(track.duration, const Duration(minutes: 3, seconds: 42));
      final album = results[1] as AlbumSearchResult;
      expect(album.id, 'fixture-album-001');
      expect(album.artistLabel, 'Yuzu Lab');
      expect(results[2], isA<ArtistSearchResult>());
    });

    test('maps typed failures without exposing response content', () {
      final response = CatalogTransportResponse(
        statusCode: 429,
        contentType: 'application/json',
        bodyBytes: utf8.encode('{"private":"do not expose"}'),
      );

      expect(
        () => mapper.map(response),
        throwsA(
          isA<CatalogFailure>().having(
            (failure) => failure.kind,
            'kind',
            CatalogFailureKind.rateLimited,
          ),
        ),
      );
    });

    test('rejects malformed and deeply nested responses', () {
      final malformed = CatalogTransportResponse(
        statusCode: 200,
        contentType: 'application/json',
        bodyBytes: utf8.encode('{not-json'),
      );
      Object? nested = <String, Object?>{};
      for (var index = 0; index < 60; index++) {
        nested = <String, Object?>{'child': nested};
      }
      final deep = CatalogTransportResponse(
        statusCode: 200,
        contentType: 'application/json',
        bodyBytes: utf8.encode(jsonEncode(nested)),
      );

      expect(
        () => mapper.map(malformed),
        throwsA(
          isA<CatalogFailure>().having(
            (failure) => failure.kind,
            'kind',
            CatalogFailureKind.malformedResponse,
          ),
        ),
      );
      expect(
        () => mapper.map(deep),
        throwsA(
          isA<CatalogFailure>().having(
            (failure) => failure.kind,
            'kind',
            CatalogFailureKind.unsupportedSchema,
          ),
        ),
      );
    });
  });
}
