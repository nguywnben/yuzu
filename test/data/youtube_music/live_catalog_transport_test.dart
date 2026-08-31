import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/live_catalog_transport.dart';
import 'package:yuzu/data/youtube_music/transport.dart';

void main() {
  group('YoutubeMusicCatalogTransport', () {
    test('bootstraps and sends a bounded guest Home request', () async {
      final requests = <http.Request>[];
      final transport = YoutubeMusicCatalogTransport(
        clientFactory: () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return _bootstrapResponse();
          }
          return http.Response(
            '{"contents":{}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await transport.send(
        CatalogTransportRequest.json(
          operation: CatalogOperation.home,
          payload: const {},
          maxAttempts: 1,
        ),
      );

      expect(requests, hasLength(2));
      final homeRequest = requests.last;
      expect(homeRequest.method, 'POST');
      expect(homeRequest.url.host, 'music.youtube.com');
      expect(homeRequest.url.path, '/youtubei/v1/browse');
      expect(homeRequest.headers, isNot(contains('cookie')));
      final body = jsonDecode(homeRequest.body) as Map<String, Object?>;
      expect(body['browseId'], 'FEmusic_home');
      expect(body, isNot(contains('continuation')));
    });

    test('sends an opaque Home continuation without persisting it', () async {
      final requests = <http.Request>[];
      final transport = YoutubeMusicCatalogTransport(
        clientFactory: () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return _bootstrapResponse();
          }
          return http.Response(
            '{"continuationContents":{}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await transport.send(
        CatalogTransportRequest.json(
          operation: CatalogOperation.continuation,
          payload: const {'continuation': 'invented-home-page-2'},
          maxAttempts: 1,
        ),
      );

      expect(requests, hasLength(2));
      final continuationRequest = requests.last;
      expect(continuationRequest.url.path, '/youtubei/v1/browse');
      final body = jsonDecode(continuationRequest.body) as Map<String, Object?>;
      expect(body['continuation'], 'invented-home-page-2');
      expect(body, isNot(contains('browseId')));
      expect(transport.toString(), isNot(contains('invented-home-page-2')));
    });

    test(
      'rejects malformed Home continuation input before networking',
      () async {
        var requestCount = 0;
        final transport = YoutubeMusicCatalogTransport(
          clientFactory: () => MockClient((request) async {
            requestCount++;
            return _bootstrapResponse();
          }),
        );

        await expectLater(
          transport.send(
            CatalogTransportRequest.json(
              operation: CatalogOperation.continuation,
              payload: const {'continuation': '   '},
            ),
          ),
          throwsA(
            isA<CatalogFailure>().having(
              (failure) => failure.kind,
              'kind',
              CatalogFailureKind.malformedResponse,
            ),
          ),
        );
        expect(requestCount, 0);
      },
    );

    test('bootstraps and sends a bounded guest Search request', () async {
      final requests = <http.Request>[];
      final transport = YoutubeMusicCatalogTransport(
        clientFactory: () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return _bootstrapResponse();
          }
          return http.Response.bytes(
            File('test/fixtures/youtube_music/search_response.json')
                .readAsBytesSync(),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final response = await transport.send(
        CatalogTransportRequest.json(
          operation: CatalogOperation.search,
          payload: const {'query': 'citrus signal'},
          maxAttempts: 1,
        ),
      );

      expect(response.statusCode, 200);
      expect(requests, hasLength(2));
      expect(requests.first.url, Uri.https('music.youtube.com', '/'));
      final searchRequest = requests.last;
      expect(searchRequest.method, 'POST');
      expect(searchRequest.url.host, 'music.youtube.com');
      expect(searchRequest.url.path, '/youtubei/v1/search');
      expect(searchRequest.headers, isNot(contains('cookie')));
      final body = jsonDecode(searchRequest.body) as Map<String, Object?>;
      expect(body['query'], 'citrus signal');
      final context = body['context'] as Map<String, Object?>;
      final client = context['client'] as Map<String, Object?>;
      expect(client['platform'], 'DESKTOP');
      expect(client['clientFormFactor'], 'UNKNOWN_FORM_FACTOR');
      expect(searchRequest.headers['x-goog-api-format-version'], '1');
      expect(jsonEncode(body), isNot(contains('visitorData')));
    });

    test('retries a rate limit only up to the request bound', () async {
      var searchAttempts = 0;
      final transport = YoutubeMusicCatalogTransport(
        clientFactory: () => MockClient((request) async {
          if (request.method == 'GET') {
            return _bootstrapResponse();
          }
          searchAttempts++;
          if (searchAttempts == 1) {
            return http.Response(
              '{}',
              429,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            '{"contents":{}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await transport.send(
        CatalogTransportRequest.json(
          operation: CatalogOperation.search,
          payload: const {'query': 'orange'},
          maxAttempts: 2,
        ),
      );

      expect(response.statusCode, 200);
      expect(searchAttempts, 2);
    });

    test('rejects oversized responses before mapping JSON', () async {
      final transport = YoutubeMusicCatalogTransport(
        clientFactory: () => MockClient((request) async {
          if (request.method == 'GET') {
            return _bootstrapResponse();
          }
          return http.Response.bytes(
            utf8.encode('x' * 128),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(
        transport.send(
          CatalogTransportRequest.json(
            operation: CatalogOperation.search,
            payload: const {'query': 'orange'},
            maxResponseBytes: 64,
            maxAttempts: 1,
          ),
        ),
        throwsA(
          isA<CatalogFailure>().having(
            (failure) => failure.kind,
            'kind',
            CatalogFailureKind.malformedResponse,
          ),
        ),
      );
    });

    test('honors cancellation before opening a connection', () async {
      var requestCount = 0;
      final token = CatalogCancellationToken()..cancel();
      final transport = YoutubeMusicCatalogTransport(
        clientFactory: () => MockClient((request) async {
          requestCount++;
          return _bootstrapResponse();
        }),
      );

      await expectLater(
        transport.send(
          CatalogTransportRequest.json(
            operation: CatalogOperation.search,
            payload: const {'query': 'orange'},
            cancellationToken: token,
          ),
        ),
        throwsA(
          isA<CatalogFailure>().having(
            (failure) => failure.kind,
            'kind',
            CatalogFailureKind.cancelled,
          ),
        ),
      );
      expect(requestCount, 0);
    });
  });
}

http.Response _bootstrapResponse() => http.Response(
  '<html><script>ytcfg.set({'
  '"INNERTUBE_API_KEY":"fixture-public-key",'
  '"INNERTUBE_CLIENT_VERSION":"1.20260825.00.00",'
  '"INNERTUBE_CONTEXT_CLIENT_NAME":67'
  '});</script></html>',
  200,
  headers: {'content-type': 'text/html; charset=utf-8'},
);
