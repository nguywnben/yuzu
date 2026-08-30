import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/transport.dart';

void main() {
  group('CatalogTransportRequest', () {
    test('serializes a bounded JSON body without exposing its contents', () {
      final payload = <String, Object?>{
        'query': 'private listening mood',
        'region': 'VN',
      };

      final request = CatalogTransportRequest.json(
        operation: CatalogOperation.search,
        payload: payload,
      );
      payload['query'] = 'changed later';

      expect(jsonDecode(utf8.decode(request.bodyBytes)), {
        'query': 'private listening mood',
        'region': 'VN',
      });
      expect(request.toString(), contains('search'));
      expect(request.toString(), isNot(contains('private listening mood')));
    });

    test('rejects request bodies over the fixed size limit', () {
      expect(
        () => CatalogTransportRequest.json(
          operation: CatalogOperation.search,
          payload: {'query': 'x' * CatalogTransportRequest.maxRequestBytes},
        ),
        throwsArgumentError,
      );
    });

    test('rejects unsafe timeout and response-size settings', () {
      expect(
        () => CatalogTransportRequest.json(
          operation: CatalogOperation.home,
          payload: const {},
          timeout: Duration.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => CatalogTransportRequest.json(
          operation: CatalogOperation.home,
          payload: const {},
          maxResponseBytes: CatalogTransportRequest.maxResponseByteLimit + 1,
        ),
        throwsArgumentError,
      );
    });
  });

  test('CatalogCancellationToken completes once when cancelled', () async {
    final token = CatalogCancellationToken();
    var notifications = 0;
    final notification = token.whenCancelled.then((_) => notifications++);

    token.cancel();
    token.cancel();
    await notification;

    expect(token.isCancelled, isTrue);
    expect(notifications, 1);
  });

  test('CatalogTransportResponse owns an immutable copy of its body', () {
    final source = utf8.encode('{"ok":true}');
    final response = CatalogTransportResponse(
      statusCode: 200,
      contentType: 'application/json; charset=utf-8',
      bodyBytes: source,
    );

    source[0] = 0;
    final firstRead = response.bodyBytes;
    firstRead[0] = 0;

    expect(utf8.decode(response.bodyBytes), '{"ok":true}');
  });

  test('CatalogFailure exposes stable retry guidance without raw details', () {
    const retryable = {
      CatalogFailureKind.networkUnavailable,
      CatalogFailureKind.timeout,
      CatalogFailureKind.rateLimited,
    };

    for (final kind in CatalogFailureKind.values) {
      final failure = CatalogFailure(kind);

      expect(failure.canRetry, retryable.contains(kind), reason: kind.name);
      expect(failure.toString(), 'CatalogFailure(${kind.name})');
    }
  });
}
