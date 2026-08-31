import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/home_response_mapper.dart';
import 'package:yuzu/data/youtube_music/transport.dart';

void main() {
  const mapper = HomeResponseMapper();

  test('maps playable Home shelves and an opaque continuation', () async {
    final bytes = await File('test/fixtures/youtube_music/home_response.json')
        .readAsBytes();

    final page = mapper.map(_response(bytes));

    expect(page.sections, hasLength(1));
    expect(page.sections.single.title, 'Made for Yuzu');
    expect(page.sections.single.tracks.single.title, 'Citrus Morning');
    expect(page.sections.single.tracks.single.artistLabel, 'Yuzu Studio');
    expect(page.continuationToken, 'invented-home-page-2');
    expect(page.toString(), isNot(contains('invented-home-page-2')));
  });

  test('maps a continuation page without inventing another token', () async {
    final bytes = await File(
      'test/fixtures/youtube_music/home_continuation_response.json',
    ).readAsBytes();

    final page = mapper.map(_response(bytes));

    expect(page.sections.single.title, 'Fresh arrivals');
    expect(page.sections.single.tracks.single.id, 'fixture-home-track-002');
    expect(page.continuationToken, isNull);
  });

  test('rejects a repeated continuation token', () {
    final response = _jsonResponse({
      'continuationContents': {
        'sectionListContinuation': {
          'contents': <Object?>[],
          'continuations': [
            {
              'nextContinuationData': {'continuation': 'already-seen'},
            },
          ],
        },
      },
    });

    expect(
      () =>
          mapper.map(response, seenContinuationTokens: const {'already-seen'}),
      throwsA(
        isA<CatalogFailure>().having(
          (failure) => failure.kind,
          'kind',
          CatalogFailureKind.unsupportedSchema,
        ),
      ),
    );
  });

  test('rejects malformed and unsupported Home response shapes', () {
    expect(
      () => mapper.map(_response(utf8.encode('{not json'))),
      throwsA(isA<CatalogFailure>()),
    );
    expect(
      () => mapper.map(_jsonResponse({'contents': const []})),
      throwsA(
        isA<CatalogFailure>().having(
          (failure) => failure.kind,
          'kind',
          CatalogFailureKind.unsupportedSchema,
        ),
      ),
    );
  });
}

CatalogTransportResponse _jsonResponse(Map<String, Object?> body) =>
    _response(utf8.encode(jsonEncode(body)));

CatalogTransportResponse _response(List<int> bytes) => CatalogTransportResponse(
  statusCode: 200,
  contentType: 'application/json; charset=utf-8',
  bodyBytes: bytes,
);
