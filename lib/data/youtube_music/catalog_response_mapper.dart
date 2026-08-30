import 'dart:convert';

import 'catalog_dto.dart';
import 'catalog_error.dart';
import 'transport.dart';

final class CatalogResponseMapper {
  const CatalogResponseMapper();

  static const maxItemsPerPage = 200;
  static const maxArtistsPerItem = 20;
  static const maxTextBytes = 4096;
  static const maxContinuationBytes = 2048;
  static const maxTrackDurationSeconds = 24 * 60 * 60;

  CatalogPageDto mapPage(
    CatalogTransportResponse response, {
    int maxResponseBytes = CatalogTransportRequest.defaultMaxResponseBytes,
    Set<String> seenContinuationTokens = const {},
  }) {
    _validateResponse(response, maxResponseBytes);

    late final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      _fail(CatalogFailureKind.malformedResponse);
    }

    if (decoded is! Map<String, Object?>) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    if (decoded['schemaVersion'] != 1) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }

    final rawItems = decoded['items'];
    if (rawItems is! List<Object?> || rawItems.length > maxItemsPerPage) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }

    final items = <CatalogItemDto>[];
    var ignoredItemCount = 0;
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, Object?>) {
        _fail(CatalogFailureKind.unsupportedSchema);
      }
      final rawKind = rawItem['kind'];
      if (rawKind is! String) {
        _fail(CatalogFailureKind.unsupportedSchema);
      }
      final kind = _parseKind(rawKind);
      if (kind == null) {
        ignoredItemCount++;
        continue;
      }
      items.add(_mapItem(rawItem, kind));
    }

    final continuationToken = _parseContinuation(decoded['continuation']);
    if (continuationToken != null &&
        seenContinuationTokens.contains(continuationToken)) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }

    return CatalogPageDto(
      items: items,
      continuationToken: continuationToken,
      ignoredItemCount: ignoredItemCount,
    );
  }

  void _validateResponse(
    CatalogTransportResponse response,
    int maxResponseBytes,
  ) {
    if (maxResponseBytes <= 0 ||
        maxResponseBytes > CatalogTransportRequest.maxResponseByteLimit) {
      throw ArgumentError.value(
        maxResponseBytes,
        'maxResponseBytes',
        'must be within the transport response limit',
      );
    }

    final statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 300) {
      _fail(switch (statusCode) {
        404 => CatalogFailureKind.notFound,
        408 || 504 => CatalogFailureKind.timeout,
        429 => CatalogFailureKind.rateLimited,
        >= 500 && <= 599 => CatalogFailureKind.unavailable,
        _ => CatalogFailureKind.upstreamRejected,
      });
    }
    final mediaType = response.contentType.split(';').first.trim();
    if (mediaType != 'application/json') {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    if (response.bodyBytes.length > maxResponseBytes) {
      _fail(CatalogFailureKind.malformedResponse);
    }
  }

  CatalogItemDto _mapItem(Map<String, Object?> rawItem, CatalogItemKind kind) {
    final artists = _parseArtists(rawItem['artists']);
    if (kind == CatalogItemKind.track && artists.isEmpty) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }

    return CatalogItemDto(
      kind: kind,
      id: _requiredText(rawItem['id']),
      title: _requiredText(rawItem['title']),
      artists: artists,
      duration: _parseDuration(
        rawItem['durationSeconds'],
        required: kind == CatalogItemKind.track,
      ),
      artworkUri: _parseArtworkUri(rawItem['artworkUrl']),
    );
  }

  CatalogItemKind? _parseKind(String value) => switch (value) {
    'track' => CatalogItemKind.track,
    'album' => CatalogItemKind.album,
    'artist' => CatalogItemKind.artist,
    'playlist' => CatalogItemKind.playlist,
    _ => null,
  };

  String _requiredText(Object? value) {
    if (value is! String ||
        value.trim().isEmpty ||
        utf8.encode(value).length > maxTextBytes) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    return value;
  }

  List<String> _parseArtists(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List<Object?> || value.length > maxArtistsPerItem) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    return [for (final artist in value) _requiredText(artist)];
  }

  Duration? _parseDuration(Object? value, {required bool required}) {
    if (value == null && !required) {
      return null;
    }
    if (value is! int || value <= 0 || value > maxTrackDurationSeconds) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    return Duration(seconds: value);
  }

  Uri? _parseArtworkUri(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String || utf8.encode(value).length > maxTextBytes) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    return uri;
  }

  String? _parseContinuation(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String ||
        value.trim().isEmpty ||
        utf8.encode(value).length > maxContinuationBytes) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    return value;
  }

  Never _fail(CatalogFailureKind kind) => throw CatalogFailure(kind);
}
