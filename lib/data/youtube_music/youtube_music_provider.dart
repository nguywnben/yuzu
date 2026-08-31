import 'dart:convert';

import '../../domain/media/home_page.dart';
import '../../domain/media/music_provider.dart';
import '../../domain/media/search_result.dart';
import 'catalog_error.dart';
import 'home_response_mapper.dart';
import 'search_response_mapper.dart';
import 'transport.dart';

/// Incremental provider: Search is live while unfinished operations keep the
/// deterministic offline implementation until their own capability lands.
final class YoutubeMusicProvider implements MusicProvider {
  factory YoutubeMusicProvider({
    required CatalogTransport transport,
    SearchResponseMapper searchMapper = const SearchResponseMapper(),
    HomeResponseMapper homeMapper = const HomeResponseMapper(),
  }) => YoutubeMusicProvider._(transport, searchMapper, homeMapper);

  YoutubeMusicProvider._(this._transport, this._searchMapper, this._homeMapper);

  final CatalogTransport _transport;
  final SearchResponseMapper _searchMapper;
  final HomeResponseMapper _homeMapper;
  final Set<String> _seenHomeContinuationTokens = {};
  final Set<String> _activeHomeContinuationTokens = {};

  @override
  Future<HomePage> fetchHome({String? continuationToken}) async {
    final normalizedToken = _normalizeContinuation(continuationToken);
    if (normalizedToken == null) {
      _seenHomeContinuationTokens.clear();
      _activeHomeContinuationTokens.clear();
    } else if (_seenHomeContinuationTokens.contains(normalizedToken) ||
        !_activeHomeContinuationTokens.add(normalizedToken)) {
      throw const MusicProviderException('Home is unavailable right now.');
    }

    try {
      final response = await _transport.send(
        CatalogTransportRequest.json(
          operation: normalizedToken == null
              ? CatalogOperation.home
              : CatalogOperation.continuation,
          payload: normalizedToken == null
              ? const {}
              : {'continuation': normalizedToken},
          maxAttempts: 2,
        ),
      );
      final seenTokens = <String>{
        ..._seenHomeContinuationTokens,
        ?normalizedToken,
      };
      final page = _homeMapper.map(
        response,
        seenContinuationTokens: seenTokens,
      );
      if (normalizedToken != null) {
        _seenHomeContinuationTokens.add(normalizedToken);
      }
      return page;
    } on CatalogFailure {
      throw const MusicProviderException('Home is unavailable right now.');
    } finally {
      if (normalizedToken != null) {
        _activeHomeContinuationTokens.remove(normalizedToken);
      }
    }
  }

  @override
  Future<List<SearchResult>> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    try {
      final response = await _transport.send(
        CatalogTransportRequest.json(
          operation: CatalogOperation.search,
          payload: {'query': normalized},
          maxAttempts: 2,
        ),
      );
      return _searchMapper.map(response);
    } on CatalogFailure {
      throw const MusicProviderException('Search is unavailable right now.');
    }
  }

  String? _normalizeContinuation(String? token) {
    if (token == null) {
      return null;
    }
    final normalized = token.trim();
    if (normalized.isEmpty ||
        utf8.encode(normalized).length >
            HomeResponseMapper.maxContinuationBytes) {
      throw const MusicProviderException('Home is unavailable right now.');
    }
    return normalized;
  }
}
