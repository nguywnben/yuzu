import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/home_response_mapper.dart';
import 'package:yuzu/data/youtube_music/transport.dart';
import 'package:yuzu/domain/media/search_result.dart';

void main() {
  const mapper = HomeResponseMapper();

  test('maps playable Home shelves and an opaque continuation', () async {
    final bytes = await File('test/fixtures/youtube_music/home_response.json')
        .readAsBytes();

    final page = mapper.map(_response(bytes));

    expect(page.sections, hasLength(3));
    expect(page.sections.first.title, 'Made for Yuzu');
    expect(page.sections.first.tracks.single.title, 'Citrus Morning');
    expect(page.sections.first.tracks.single.artistLabel, 'Yuzu Studio');
    expect(page.sections[1].title, 'Albums only');
    expect(page.sections[1].items.single, isA<AlbumSearchResult>());
    expect(page.sections[1].items.single.title, 'Invented Album');
    expect(page.sections.last.title, 'Mixes for you');
    expect(page.sections.last.items.single, isA<PlaylistSearchResult>());
    expect(page.sections.last.items.single.title, 'Citrus Mix');
    expect(
      (page.sections.last.items.single as PlaylistSearchResult).subtitle,
      'Yuzu Studio and more',
    );
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

  test('maps append-action continuation pages', () {
    final response = _jsonResponse({
      'onResponseReceivedActions': [
        {
          'appendContinuationItemsAction': {
            'continuationItems': [
              {
                'musicCarouselShelfRenderer': {
                  'header': {
                    'musicCarouselShelfBasicHeaderRenderer': {
                      'title': {
                        'runs': [
                          {'text': 'More mixes'},
                        ],
                      },
                    },
                  },
                  'contents': [
                    {
                      'musicTwoRowItemRenderer': {
                        'title': {
                          'runs': [
                            {
                              'text': 'Late Citrus Mix',
                              'navigationEndpoint': {
                                'watchPlaylistEndpoint': {
                                  'playlistId': 'fixture-late-mix',
                                },
                              },
                            },
                          ],
                        },
                        'subtitle': {
                          'runs': [
                            {'text': 'Yuzu Studio and more'},
                          ],
                        },
                      },
                    },
                  ],
                },
              },
            ],
          },
        },
      ],
    });

    final page = mapper.map(response);

    expect(page.sections.single.title, 'More mixes');
    expect(page.sections.single.items.single, isA<PlaylistSearchResult>());
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
