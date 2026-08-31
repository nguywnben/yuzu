import 'dart:convert';

import '../../domain/media/home_page.dart';
import '../../domain/media/home_section.dart';
import '../../domain/media/search_result.dart';
import '../../domain/media/track.dart';
import 'catalog_error.dart';
import 'search_response_mapper.dart';
import 'transport.dart';

final class HomeResponseMapper {
  const HomeResponseMapper({
    SearchResponseMapper itemMapper = const SearchResponseMapper(),
  }) : _itemMapper = itemMapper;

  static const maxDepth = 32;
  static const maxNodes = 8000;
  static const maxSections = 40;
  static const maxContinuations = 10;
  static const maxTextBytes = 4096;
  static const maxContinuationBytes = 2048;

  final SearchResponseMapper _itemMapper;

  HomePage map(
    CatalogTransportResponse response, {
    Set<String> seenContinuationTokens = const {},
  }) {
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

    final sectionList = _findSectionList(decoded);
    final rawContents = sectionList['contents'];
    if (rawContents is! List<Object?> || rawContents.length > maxSections) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }

    final sections = <HomeSection>[];
    for (var index = 0; index < rawContents.length; index++) {
      final section = _mapSection(rawContents[index], index);
      if (section != null) {
        sections.add(section);
      }
    }

    final continuationToken = _continuationToken(sectionList, rawContents);
    if (continuationToken != null &&
        seenContinuationTokens.contains(continuationToken)) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }

    return HomePage(sections: sections, continuationToken: continuationToken);
  }

  Map<String, Object?> _findSectionList(Map<String, Object?> root) {
    final stack = <_TraversalEntry>[_TraversalEntry(root, 0)];
    var visitedNodes = 0;
    while (stack.isNotEmpty) {
      final entry = stack.removeLast();
      visitedNodes++;
      if (visitedNodes > maxNodes || entry.depth > maxDepth) {
        _fail(CatalogFailureKind.unsupportedSchema);
      }
      final value = entry.value;
      switch (value) {
        case Map<String, Object?> map:
          for (final key in const [
            'sectionListRenderer',
            'sectionListContinuation',
          ]) {
            final sectionList = map[key];
            if (sectionList is Map<String, Object?>) {
              return sectionList;
            }
          }
          for (final child in map.values) {
            stack.add(_TraversalEntry(child, entry.depth + 1));
          }
        case List<Object?> list:
          for (final child in list) {
            stack.add(_TraversalEntry(child, entry.depth + 1));
          }
        case _:
          break;
      }
    }
    _fail(CatalogFailureKind.unsupportedSchema);
  }

  HomeSection? _mapSection(Object? rawSection, int index) {
    if (rawSection is! Map<String, Object?>) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    final renderer = switch (rawSection) {
      {'musicCarouselShelfRenderer': final Map<String, Object?> value} => value,
      {'musicShelfRenderer': final Map<String, Object?> value} => value,
      _ => null,
    };
    if (renderer == null) {
      return null;
    }

    final title = _sectionTitle(renderer);
    if (title == null) {
      return null;
    }
    final tracksById = <String, Track>{};
    for (final result in _itemMapper.mapDecoded(renderer)) {
      if (result case TrackSearchResult(:final track)) {
        tracksById.putIfAbsent(track.id, () => track);
      }
    }
    if (tracksById.isEmpty) {
      return null;
    }

    return HomeSection(
      id: _sectionId(title, index),
      title: title,
      tracks: tracksById.values.toList(growable: false),
    );
  }

  String? _sectionTitle(Map<String, Object?> renderer) {
    final candidates = <Object?>[
      _at(renderer, const [
        'header',
        'musicCarouselShelfBasicHeaderRenderer',
        'title',
        'runs',
      ]),
      _at(renderer, const ['title', 'runs']),
    ];
    for (final candidate in candidates) {
      if (candidate is List<Object?> && candidate.isNotEmpty) {
        final run = candidate.first;
        final title = run is Map<String, Object?> ? _text(run['text']) : null;
        if (title != null) {
          return title;
        }
      }
    }
    return null;
  }

  String _sectionId(String title, int index) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('(^-+|-+\$)'), '');
    return 'home-${index + 1}-${slug.isEmpty ? 'section' : slug}';
  }

  String? _continuationToken(
    Map<String, Object?> sectionList,
    List<Object?> rawContents,
  ) {
    final tokens = <String>{};
    final rawContinuations = sectionList['continuations'];
    if (rawContinuations != null) {
      if (rawContinuations is! List<Object?> ||
          rawContinuations.length > maxContinuations) {
        _fail(CatalogFailureKind.unsupportedSchema);
      }
      for (final continuation in rawContinuations) {
        _addContinuationToken(
          tokens,
          _at(continuation, const ['nextContinuationData', 'continuation']),
        );
      }
    }
    for (final content in rawContents) {
      _addContinuationToken(
        tokens,
        _at(content, const [
          'continuationItemRenderer',
          'continuationEndpoint',
          'continuationCommand',
          'token',
        ]),
      );
    }
    if (tokens.length > 1) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    return tokens.firstOrNull;
  }

  void _addContinuationToken(Set<String> tokens, Object? rawToken) {
    if (rawToken == null) {
      return;
    }
    final token = _text(rawToken, maxBytes: maxContinuationBytes);
    if (token == null) {
      _fail(CatalogFailureKind.unsupportedSchema);
    }
    tokens.add(token);
  }

  Object? _at(Object? value, List<String> path) {
    var current = value;
    for (final segment in path) {
      current = current is Map<String, Object?> ? current[segment] : null;
      if (current == null) {
        return null;
      }
    }
    return current;
  }

  String? _text(Object? value, {int maxBytes = maxTextBytes}) {
    if (value is! String ||
        value.trim().isEmpty ||
        utf8.encode(value).length > maxBytes) {
      return null;
    }
    return value.trim();
  }

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
  const _TraversalEntry(this.value, this.depth);

  final Object? value;
  final int depth;
}
