import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/youtube_music/catalog_dto.dart';
import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/catalog_response_mapper.dart';
import 'package:yuzu/data/youtube_music/transport.dart';

void main() {
  const mapper = CatalogResponseMapper();

  test(
    'maps the sanitized fixture and preserves supported item order',
    () async {
      final bytes = await File('test/fixtures/youtube_music/catalog_page.json')
          .readAsBytes();

      final page = mapper.mapPage(_response(bodyBytes: bytes));

      expect(page.items.map((item) => item.kind), [
        CatalogItemKind.track,
        CatalogItemKind.album,
      ]);
      expect(page.items.first.id, 'track-citrus-dawn');
      expect(page.items.first.artists, ['Aiko Vale']);
      expect(page.items.first.duration, const Duration(seconds: 214));
      expect(page.continuationToken, 'invented-search-page-2');
      expect(page.ignoredItemCount, 1);
      expect(page.toString(), isNot(contains('invented-search-page-2')));
    },
  );

  test('maps an empty page without inventing a continuation', () {
    final page = mapper.mapPage(
      _jsonResponse({'schemaVersion': 1, 'items': <Object?>[]}),
    );

    expect(page.items, isEmpty);
    expect(page.continuationToken, isNull);
    expect(page.ignoredItemCount, 0);
  });

  test('rejects a repeated continuation token', () {
    final response = _jsonResponse({
      'schemaVersion': 1,
      'items': <Object?>[],
      'continuation': 'already-seen',
    });

    expect(
      () => mapper.mapPage(
        response,
        seenContinuationTokens: const {'already-seen'},
      ),
      _throwsFailure(CatalogFailureKind.unsupportedSchema),
    );
  });

  test('rejects invalid JSON as a malformed response', () {
    expect(
      () => mapper.mapPage(_response(bodyBytes: utf8.encode('{not json'))),
      _throwsFailure(CatalogFailureKind.malformedResponse),
    );
  });

  test('rejects valid JSON with an unsupported schema', () {
    expect(
      () => mapper.mapPage(
        _jsonResponse({'schemaVersion': 2, 'items': <Object?>[]}),
      ),
      _throwsFailure(CatalogFailureKind.unsupportedSchema),
    );
    expect(
      () => mapper.mapPage(
        _jsonResponse({
          'schemaVersion': 1,
          'items': [
            {'kind': 'track', 'id': 'broken-track', 'title': 'No artist'},
          ],
        }),
      ),
      _throwsFailure(CatalogFailureKind.unsupportedSchema),
    );
  });

  test('rejects non-JSON and oversized responses before decoding', () {
    final validBody = utf8.encode('{"schemaVersion":1,"items":[]}');
    expect(
      () => mapper.mapPage(
        _response(contentType: 'text/html', bodyBytes: validBody),
      ),
      _throwsFailure(CatalogFailureKind.unsupportedSchema),
    );
    expect(
      () => mapper.mapPage(
        _response(contentType: 'application/jsonp', bodyBytes: validBody),
      ),
      _throwsFailure(CatalogFailureKind.unsupportedSchema),
    );
    expect(
      () => mapper.mapPage(
        _jsonResponse({'schemaVersion': 1, 'items': <Object?>[]}),
        maxResponseBytes: 10,
      ),
      _throwsFailure(CatalogFailureKind.malformedResponse),
    );
  });

  test('maps rejected HTTP statuses to stable failure categories', () {
    const expected = {
      302: CatalogFailureKind.upstreamRejected,
      403: CatalogFailureKind.upstreamRejected,
      404: CatalogFailureKind.notFound,
      408: CatalogFailureKind.timeout,
      429: CatalogFailureKind.rateLimited,
      503: CatalogFailureKind.unavailable,
    };

    for (final entry in expected.entries) {
      expect(
        () => mapper.mapPage(_jsonResponse(const {}, statusCode: entry.key)),
        _throwsFailure(entry.value),
        reason: 'HTTP ${entry.key}',
      );
    }
  });
}

CatalogTransportResponse _jsonResponse(
  Map<String, Object?> body, {
  int statusCode = 200,
}) =>
    _response(statusCode: statusCode, bodyBytes: utf8.encode(jsonEncode(body)));

CatalogTransportResponse _response({
  int statusCode = 200,
  String contentType = 'application/json; charset=utf-8',
  required List<int> bodyBytes,
}) => CatalogTransportResponse(
  statusCode: statusCode,
  contentType: contentType,
  bodyBytes: bodyBytes,
);

Matcher _throwsFailure(CatalogFailureKind kind) => throwsA(
  isA<CatalogFailure>().having((failure) => failure.kind, 'kind', kind),
);
