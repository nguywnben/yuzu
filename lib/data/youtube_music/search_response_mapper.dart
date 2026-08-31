import 'dart:convert';

import '../../domain/media/search_result.dart';
import '../../domain/media/track.dart';
import 'catalog_error.dart';
import 'transport.dart';

final class SearchResponseMapper {
  const SearchResponseMapper();

  static const maxDepth = 48;
  static const maxNodes = 12000;
  static const maxResults = 100;
  static const maxTextBytes = 4096;
  static const maxDuration = Duration(hours: 24);

  List<SearchResult> map(CatalogTransportResponse response) {
    _validateResponse(response);

    late final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      _fail(CatalogFailureKind.malformedResponse);
    }
    if (decoded is! Map<String, Object?>) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }

    final results = <SearchResult>[];
    final stack = <_TraversalEntry>[_TraversalEntry(value: decoded, depth: 0)];
    var visitedNodes = 0;

    while (stack.isNotEmpty) {
      final entry = stack.removeLast();
      visitedNodes++;
      if (visitedNodes > maxNodes || entry.depth > maxDepth) {
        _fail(CatalogFailureKind.unsupportedSchema);
      }

      switch (entry.value) {
        case Map<String, Object?> map:
          final renderer = map['musicResponsiveListItemRenderer'];
          if (renderer is Map<String, Object?>) {
            final result = _mapRenderer(renderer);
            if (result != null) {
              results.add(result);
              if (results.length > maxResults) {
                _fail(CatalogFailureKind.unsupportedSchema);
              }
            }
          }
          for (final child in map.values) {
            stack.add(_TraversalEntry(value: child, depth: entry.depth + 1));
          }
        case List<Object?> list:
          for (final child in list) {
            stack.add(_TraversalEntry(value: child, depth: entry.depth + 1));
          }
        case _:
          break;
      }
    }

    return List.unmodifiable(results.reversed);
  }

  SearchResult? _mapRenderer(Map<String, Object?> renderer) {
    final columns = _asList(renderer['flexColumns']);
    if (columns == null || columns.length < 2) {
      return null;
    }
    final titleRuns = _columnRuns(columns.first);
    final metadataRuns = _columnRuns(columns[1]);
    if (titleRuns.isEmpty || metadataRuns.isEmpty) {
      return null;
    }
    final titleRun = titleRuns.first;
    final title = _text(titleRun['text']);
    final kind = _text(metadataRuns.first['text']);
    if (title == null || kind == null) {
      return null;
    }
    final artworkUri = _artworkUri(renderer);

    return switch (kind) {
      'Song' => _mapTrack(
        renderer: renderer,
        titleRun: titleRun,
        title: title,
        metadataRuns: metadataRuns,
        artworkUri: artworkUri,
      ),
      'Album' => _mapAlbum(
        titleRun: titleRun,
        title: title,
        metadataRuns: metadataRuns,
        artworkUri: artworkUri,
      ),
      'Artist' => _mapArtist(
        titleRun: titleRun,
        name: title,
        artworkUri: artworkUri,
      ),
      _ => null,
    };
  }

  TrackSearchResult? _mapTrack({
    required Map<String, Object?> renderer,
    required Map<String, Object?> titleRun,
    required String title,
    required List<Map<String, Object?>> metadataRuns,
    required Uri? artworkUri,
  }) {
    final videoId = _text(
      _at(titleRun, const ['navigationEndpoint', 'watchEndpoint', 'videoId']),
    );
    final duration = _duration(metadataRuns);
    final artists = _artistNames(metadataRuns);
    if (artists.isEmpty) {
      final fallback = _artistFromPlayLabel(renderer, title);
      if (fallback != null) {
        artists.add(fallback);
      }
    }
    if (videoId == null || duration == null || artists.isEmpty) {
      return null;
    }
    return TrackSearchResult(
      Track(
        id: videoId,
        title: title,
        artists: artists,
        duration: duration,
        artworkUri: artworkUri,
      ),
    );
  }

  AlbumSearchResult? _mapAlbum({
    required Map<String, Object?> titleRun,
    required String title,
    required List<Map<String, Object?>> metadataRuns,
    required Uri? artworkUri,
  }) {
    final browseEndpoint = _asMap(
      _at(titleRun, const ['navigationEndpoint', 'browseEndpoint']),
    );
    final id = _text(browseEndpoint?['browseId']);
    if (id == null || _pageType(browseEndpoint) != 'MUSIC_PAGE_TYPE_ALBUM') {
      return null;
    }
    final artists = _artistNames(metadataRuns);
    if (artists.isEmpty) {
      return null;
    }
    return AlbumSearchResult(
      id: id,
      title: title,
      artists: artists,
      artworkUri: artworkUri,
    );
  }

  ArtistSearchResult? _mapArtist({
    required Map<String, Object?> titleRun,
    required String name,
    required Uri? artworkUri,
  }) {
    final browseEndpoint = _asMap(
      _at(titleRun, const ['navigationEndpoint', 'browseEndpoint']),
    );
    final id = _text(browseEndpoint?['browseId']);
    if (id == null || _pageType(browseEndpoint) != 'MUSIC_PAGE_TYPE_ARTIST') {
      return null;
    }
    return ArtistSearchResult(id: id, name: name, artworkUri: artworkUri);
  }

  List<Map<String, Object?>> _columnRuns(Object? column) {
    final runs = _asList(
      _at(column, const [
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
      ]),
    );
    if (runs == null) {
      return const [];
    }
    return [
      for (final run in runs)
        if (run is Map<String, Object?>) run,
    ];
  }

  List<String> _artistNames(List<Map<String, Object?>> runs) => [
    for (final run in runs)
      if (_pageType(
            _asMap(_at(run, const ['navigationEndpoint', 'browseEndpoint'])),
          ) ==
          'MUSIC_PAGE_TYPE_ARTIST')
        ?_text(run['text']),
  ];

  String? _artistFromPlayLabel(Map<String, Object?> renderer, String title) {
    final label = _text(
      _at(renderer, const [
        'overlay',
        'musicItemThumbnailOverlayRenderer',
        'content',
        'musicPlayButtonRenderer',
        'accessibilityPlayData',
        'accessibilityData',
        'label',
      ]),
    );
    final prefix = 'Play $title - ';
    if (label == null || !label.startsWith(prefix)) {
      return null;
    }
    return _text(label.substring(prefix.length));
  }

  Duration? _duration(List<Map<String, Object?>> runs) {
    for (final run in runs) {
      final value = _text(run['text']);
      if (value == null ||
          !RegExp(r'^\d{1,2}:\d{2}(?::\d{2})?$').hasMatch(value)) {
        continue;
      }
      final parts = value.split(':').map(int.parse).toList(growable: false);
      final seconds = parts.length == 2
          ? parts[0] * 60 + parts[1]
          : parts[0] * 3600 + parts[1] * 60 + parts[2];
      final duration = Duration(seconds: seconds);
      if (duration > Duration.zero && duration <= maxDuration) {
        return duration;
      }
    }
    return null;
  }

  Uri? _artworkUri(Map<String, Object?> renderer) {
    final thumbnails = _asList(
      _at(renderer, const [
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]),
    );
    if (thumbnails == null) {
      return null;
    }
    for (final thumbnail in thumbnails.reversed) {
      final rawUri = _text(_asMap(thumbnail)?['url']);
      final uri = rawUri == null ? null : Uri.tryParse(rawUri);
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.hasAuthority &&
          uri.userInfo.isEmpty) {
        return uri;
      }
    }
    return null;
  }

  String? _pageType(Map<String, Object?>? browseEndpoint) => _text(
    _at(browseEndpoint, const [
      'browseEndpointContextSupportedConfigs',
      'browseEndpointContextMusicConfig',
      'pageType',
    ]),
  );

  Object? _at(Object? value, List<String> path) {
    var current = value;
    for (final segment in path) {
      current = _asMap(current)?[segment];
      if (current == null) {
        return null;
      }
    }
    return current;
  }

  String? _text(Object? value) {
    if (value is! String ||
        value.trim().isEmpty ||
        utf8.encode(value).length > maxTextBytes) {
      return null;
    }
    return value.trim();
  }

  Map<String, Object?>? _asMap(Object? value) =>
      value is Map<String, Object?> ? value : null;

  List<Object?>? _asList(Object? value) =>
      value is List<Object?> ? value : null;

  void _validateResponse(CatalogTransportResponse response) {
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
    if (response.contentType.split(';').first.trim() != 'application/json') {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    if (response.bodyBytes.length >
        CatalogTransportRequest.defaultMaxResponseBytes) {
      _fail(CatalogFailureKind.malformedResponse);
    }
  }

  Never _fail(CatalogFailureKind kind) => throw CatalogFailure(kind);
}

final class _TraversalEntry {
  const _TraversalEntry({required this.value, required this.depth});

  final Object? value;
  final int depth;
}
