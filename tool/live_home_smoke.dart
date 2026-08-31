import 'dart:convert';
import 'dart:io';

import 'package:yuzu/data/youtube_music/catalog_error.dart';
import 'package:yuzu/data/youtube_music/home_response_mapper.dart';
import 'package:yuzu/data/youtube_music/live_catalog_transport.dart';
import 'package:yuzu/data/youtube_music/transport.dart';
import 'package:yuzu/domain/media/home_page.dart';

Future<void> main() async {
  final transport = YoutubeMusicCatalogTransport();
  const mapper = HomeResponseMapper();

  final firstPage = await _fetchPage(
    transport: transport,
    mapper: mapper,
    operation: CatalogOperation.home,
    payload: const {},
  );
  final firstTrackCount = firstPage.sections.fold<int>(
    0,
    (count, section) => count + section.tracks.length,
  );
  final firstItemCount = firstPage.sections.fold<int>(
    0,
    (count, section) => count + section.items.length,
  );
  if (firstPage.sections.isEmpty || firstItemCount == 0) {
    throw StateError('Live Home returned no supported catalog sections.');
  }
  stdout.writeln(
    'Home smoke passed: sections=${firstPage.sections.length}, '
    'items=$firstItemCount, tracks=$firstTrackCount, '
    'hasContinuation=${firstPage.continuationToken != null}.',
  );

  final continuationToken = firstPage.continuationToken;
  if (continuationToken == null) {
    return;
  }
  final nextPage = await _fetchPage(
    transport: transport,
    mapper: mapper,
    operation: CatalogOperation.continuation,
    payload: {'continuation': continuationToken},
    seenContinuationTokens: {continuationToken},
  );
  final nextTrackCount = nextPage.sections.fold<int>(
    0,
    (count, section) => count + section.tracks.length,
  );
  final nextItemCount = nextPage.sections.fold<int>(
    0,
    (count, section) => count + section.items.length,
  );
  stdout.writeln(
    'Home continuation smoke passed: sections=${nextPage.sections.length}, '
    'items=$nextItemCount, tracks=$nextTrackCount, '
    'hasContinuation=${nextPage.continuationToken != null}.',
  );
}

Future<HomePage> _fetchPage({
  required YoutubeMusicCatalogTransport transport,
  required HomeResponseMapper mapper,
  required CatalogOperation operation,
  required Map<String, Object?> payload,
  Set<String> seenContinuationTokens = const {},
}) async {
  try {
    final response = await transport.send(
      CatalogTransportRequest.json(
        operation: operation,
        payload: payload,
        maxAttempts: 2,
      ),
    );
    try {
      return mapper.map(
        response,
        seenContinuationTokens: seenContinuationTokens,
      );
    } on CatalogFailure {
      stdout.writeln(
        'Schema markers: ${_schemaMarkers(response.bodyBytes).join(', ')}.',
      );
      rethrow;
    }
  } on CatalogFailure catch (failure) {
    stdout.writeln(
      'Home smoke failed: operation=${operation.name}, '
      'category=${failure.kind.name}.',
    );
    rethrow;
  }
}

Set<String> _schemaMarkers(List<int> bodyBytes) {
  final decoded = jsonDecode(utf8.decode(bodyBytes));
  final markers = <String>{};
  final stack = <Object?>[decoded];
  var visited = 0;
  while (stack.isNotEmpty && visited < 12000) {
    final value = stack.removeLast();
    visited++;
    if (value is Map<String, Object?>) {
      for (final entry in value.entries) {
        if (RegExp(r'(Renderer|Action|Command|Continuation)$')
            .hasMatch(entry.key)) {
          markers.add(entry.key);
        }
        stack.add(entry.value);
      }
    } else if (value is List<Object?>) {
      stack.addAll(value);
    }
  }
  return markers;
}
