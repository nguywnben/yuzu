import '../../domain/media/home_section.dart';
import '../../domain/media/music_provider.dart';
import '../../domain/media/search_result.dart';
import 'catalog_error.dart';
import 'search_response_mapper.dart';
import 'transport.dart';

/// Incremental provider: Search is live while unfinished operations keep the
/// deterministic offline implementation until their own capability lands.
final class YoutubeMusicProvider implements MusicProvider {
  factory YoutubeMusicProvider({
    required CatalogTransport transport,
    required MusicProvider fallbackProvider,
    SearchResponseMapper searchMapper = const SearchResponseMapper(),
  }) => YoutubeMusicProvider._(transport, fallbackProvider, searchMapper);

  const YoutubeMusicProvider._(
    this._transport,
    this._fallbackProvider,
    this._searchMapper,
  );

  final CatalogTransport _transport;
  final MusicProvider _fallbackProvider;
  final SearchResponseMapper _searchMapper;

  @override
  Future<List<HomeSection>> fetchHome() => _fallbackProvider.fetchHome();

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
}
